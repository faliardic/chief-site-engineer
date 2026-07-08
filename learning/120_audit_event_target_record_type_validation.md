# Adim 120 - Audit Event Target Record Type Validation

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord.target_record_type` sozlesmesini ilk kez koda bagladik.

Uc temel sey yaptik:

1. Desteklenen target record type degerlerini tuple sabiti olarak ekledik.
2. Hizli kontrol icin bu tuple'dan `frozenset` urettik.
3. `AuditEventRecord.__post_init__` icinde target reference validation davranisini genislettik.

Bu adimdan sonra `target_record_type` artik herhangi bir metin olamaz. Sadece desteklenen target record type listesinde yer alan degerleri kabul eder.

## Neden yaptik?

Adim 119'da `target_record_type` alaninin serbest aciklama alani olmadigini dokumante etmistik.

Bu adimda o sozlesmeyi runtime davranisina tasidik.

Santiye karsiligi sudur: Bir klasor etiket sozlesmesi yazmak tek basina yetmez. Sistemin de sadece izinli etiketleri kabul etmesi gerekir. Boylece herkes "ek dosya", "attachment", "dosya kaydi" gibi farkli kelimeler kullanmak yerine tek sozlesmeye uyar.

## Dokunulan dosyalar

```text
app/models.py
tests/test_models.py
docs/120_audit_event_target_record_type_validation.md
learning/120_audit_event_target_record_type_validation.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
docs/119_audit_event_target_record_type_sozlesmesi.md
learning/GLOSSARY.md
```

`app/models.py`: Sabitler ve validation davranisi eklendi.

`tests/test_models.py`: 6 yeni model testi eklendi ve eski audit target testleri yeni sozlesmeye hizalandi.

Dokumantasyon dosyalari: Karar, roadmap, changelog ve learning kayitlari guncellendi.

## `AUDIT_TARGET_RECORD_TYPES` kod blogu

```python
AUDIT_TARGET_RECORD_TYPES: tuple[str, ...] = (
    "project",
    "project_record",
    "attachment",
    "attachment_metadata",
    "attachment_integrity_report",
    "json_export",
    "backup_package",
    "restore_operation",
    "handover_package",
    "audit_event",
)
```

Satir satir aciklama:

- `AUDIT_TARGET_RECORD_TYPES`: Desteklenen target record type degerlerini tutan sabitin adidir.
- `tuple[str, ...]`: Bu koleksiyonun string degerlerden olusan tuple oldugunu anlatir.
- `"project"`: Genel proje kaydini temsil eder.
- `"project_record"`: Genel proje/saha/takip kayitlarini temsil eder.
- `"attachment"`: Dosya eki metadata kaydini temsil eder.
- `"attachment_integrity_report"`: Attachment integrity raporu ciktisini temsil eder.
- `"audit_event"`: Audit sisteminin baska bir audit event ile iliskisini temsil eder.

Sunu soyle yaptik ki:
Target type degerleri daginik stringler olarak kalmasin.

Boyle yaptik:
Tum izinli degerleri tek tuple icinde topladik.

Cunku:
Validation, test ve dokumantasyon ayni sozlesmeye bakmali.

Boylece:
Yeni bir target type eklenecegi zaman tek sozlesme noktasi gorulur.

## `AUDIT_TARGET_RECORD_TYPE_SET` kod blogu

```python
AUDIT_TARGET_RECORD_TYPE_SET: frozenset[str] = frozenset(AUDIT_TARGET_RECORD_TYPES)
```

Satir satir aciklama:

- `AUDIT_TARGET_RECORD_TYPE_SET`: Membership kontrolu icin kullanilan sabitin adidir.
- `frozenset[str]`: Benzersiz string degerlerden olusan degistirilemez set tipini anlatir.
- `frozenset(AUDIT_TARGET_RECORD_TYPES)`: Tuple icindeki degerleri set yapisina cevirir.

Sunu soyle yaptik ki:
`target_record_type` destekleniyor mu kontrolu sade olsun.

Boyle yaptik:
Tuple sozlesmesinden bir `frozenset` olusturduk.

Cunku:
`value in set` kontrolu hem okunur hem de membership mantigi icin uygundur.

Boylece:
Validation kodu kisa ve niyeti belli hale gelir.

## Guncellenmis `__post_init__` kod blogu

```python
def __post_init__(self) -> None:
    required_fields = (
        "event_id",
        "project_id",
        "event_type",
        "actor",
        "occurred_at",
    )
    for field_name in required_fields:
        value = getattr(self, field_name)
        if value is None or not value.strip():
            raise ValueError(f"{field_name} is required")

    if self.event_type not in AUDIT_EVENT_TYPE_SET:
        raise ValueError("event_type is not supported")

    target_type_is_set = self.target_record_type is not None
    target_id_is_set = self.target_record_id is not None
    if target_type_is_set != target_id_is_set:
        raise ValueError(
            "target_record_type and target_record_id must be provided together"
        )

    if self.target_record_type is None and self.target_record_id is None:
        return

    if not self.target_record_type.strip():
        raise ValueError("target_record_type is required")

    if not self.target_record_id.strip():
        raise ValueError("target_record_id is required")

    if self.target_record_type not in AUDIT_TARGET_RECORD_TYPE_SET:
        raise ValueError("target_record_type is not supported")
```

Bu kodun amaci:
Audit event kaydinin zorunlu alanlarini, event type sozlesmesini ve target reference sozlesmesini model olusturulurken kontrol etmek.

Satir satir aciklama:

- `required_fields`: Bos birakilamayacak ana audit alanlarini toplar.
- `getattr(self, field_name)`: Alan degerini ismiyle okur.
- `value is None or not value.strip()`: `None`, bos string veya whitespace degeri yakalar.
- `self.event_type not in AUDIT_EVENT_TYPE_SET`: Event type desteklenen listede mi kontrol eder.
- `target_type_is_set`: `target_record_type` alaninin `None` olup olmadigini boolean olarak tutar.
- `target_id_is_set`: `target_record_id` alaninin `None` olup olmadigini boolean olarak tutar.
- `target_type_is_set != target_id_is_set`: Alanlardan sadece biri doluysa pair validation hatasi verir.
- `return`: Iki target alan da `None` ise target reference validation'i burada biter.
- `not self.target_record_type.strip()`: Bos veya whitespace target type degerini reddeder.
- `not self.target_record_id.strip()`: Bos veya whitespace target id degerini reddeder.
- `self.target_record_type not in AUDIT_TARGET_RECORD_TYPE_SET`: Desteklenmeyen target type degerini reddeder.

## Validation akisi

Validation sirasi su sekildedir:

```text
1. Required audit event fields kontrol edilir.
2. event_type allowed-list kontrol edilir.
3. target_record_type / target_record_id pair validation calisir.
4. Iki target alan da None ise validation biter.
5. target_record_type bos veya whitespace ise hata verilir.
6. target_record_id bos veya whitespace ise hata verilir.
7. target_record_type desteklenen listede degilse hata verilir.
```

Bu siralama onemlidir. Cunku tek tarafli target reference hatasi ile desteklenmeyen target type hatasi farkli problemlerdir.

## Gercek test kodu blogu

```python
def test_audit_event_record_rejects_unsupported_target_record_type() -> None:
    values = _valid_audit_event_kwargs()
    values["target_record_type"] = "unknown_record"
    values["target_record_id"] = "REC-1"

    with pytest.raises(ValueError, match="target_record_type is not supported"):
        AuditEventRecord(**values)
```

## Testlerin satir satir aciklamasi

- `def test_audit_event_record_rejects_unsupported_target_record_type() -> None:` yeni test fonksiyonunu tanimlar.
- `values = _valid_audit_event_kwargs()` gecerli temel audit event alanlarini hazirlar.
- `values["target_record_type"] = "unknown_record"` desteklenmeyen bir target type verir.
- `values["target_record_id"] = "REC-1"` pair validation'a takilmamak icin target id degerini de verir.
- `with pytest.raises(...)` model olusturulurken hata bekledigimizi soyler.
- `match="target_record_type is not supported"` hata mesajinin dogru alan ve nedeni gosterdigini kontrol eder.
- `AuditEventRecord(**values)` modeli olusturmayi dener ve validation calisir.

Bu test, allowed-list validation'in pair validation'dan sonra calistigini da dolayli olarak dogrular.

## Pair validation ile allowed-list validation farki

Pair validation su soruyu sorar:

```text
target_record_type ve target_record_id birlikte mi kullaniliyor?
```

Allowed-list validation su soruyu sorar:

```text
target_record_type desteklenen target type listesinde mi?
```

Ornek:

```text
target_record_type = project_record
target_record_id = None
```

Bu pair validation hatasidir.

```text
target_record_type = unknown_record
target_record_id = REC-1
```

Bu allowed-list validation hatasidir.

## Tuple/frozenset tercihinin nedeni

Tuple/frozenset tercih edildi cunku bu projede audit event type sabitleri de ayni sade yaklasimla tutuluyor.

Tuple:

- Degerleri sirali ve okunur tutar.
- Dokumantasyon ve test icin uygundur.
- Degistirilemez sozlesme hissi verir.

Frozenset:

- Membership kontrolu icin uygundur.
- Duplicate degerleri dogal olarak tekillestirir.
- Validation kodunu sade tutar.

Enum bu adimda eklenmedi. Cunku enum daha fazla yapi getirir ve su anda string tabanli sade sozlesme yeterlidir.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Target type sabitlerini ekledik | `AUDIT_TARGET_RECORD_TYPES` tuple kullandik | Izinli degerler tek yerde durmali | Validation ve testler ayni sozlesmeye bakar |
| Membership kontrolu ekledik | `AUDIT_TARGET_RECORD_TYPE_SET` frozenset kullandik | `in` kontrolu sade ve hizli olmali | Desteklenmeyen target type reddedilir |
| Bos target reference degerlerini reddettik | `.strip()` ile bos/whitespace kontrolu yaptik | Bos string gercek target reference degildir | Kayitlar daha temiz kalir |
| Pair validation'i koruduk | Once iki alan birlikte mi kontrol ettik | Eksik alan hatasi ayri bir problemdir | Hata mesajlari daha anlasilir olur |
| ID formatini erteledik | Sadece bos olmayan id kontrolu yaptik | Format sozlesmesi ayri karar ister | Scope kucuk ve testli kalir |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`target_record_type` icin desteklenen deger listesini koda ekledik.

Boyle yaptik:
`AUDIT_TARGET_RECORD_TYPES` tuple'i ve `AUDIT_TARGET_RECORD_TYPE_SET` frozenset'i kullandik.

Cunku:
Target type degerleri serbest metin gibi kalirsa audit event kayitlari filtrelenemez ve raporlanamaz hale gelir.

Boylece:
Model yalnizca sozlesmede yer alan target type degerlerini kabul eder.

Sunu yaptik:
Bos veya whitespace target reference degerlerini reddettik.

Boyle yaptik:
`target_record_type.strip()` ve `target_record_id.strip()` kontrolleri ekledik.

Cunku:
`""` veya `"   "` degeri teknik olarak string olsa da anlamli target reference degildir.

Boylece:
Target record iliskisi ya tamamen yoktur ya da anlamli tur/kimlik ciftiyle vardir.

## Bilincli olarak yapilmayanlar

Bu adimda target record id format validation eklenmedi.

Bu adimda target record id prefix validation, target record existence kontrolu, foreign key implementasyonu, database, repository, migration, JSON export/import, audit event persistence veya otomatik audit event uretimi eklenmedi.

Bu adimda enum class, alias sistemi, config dosyasi, event type validation degisikligi, UUID validation, ISO tarih validation, `old_value` / `new_value` validation veya opsiyonel alanlarin genel validation'i eklenmedi.

## Mini sozluk

`Audit Target Record Type`: Audit event olayinin iliskili oldugu hedef kayit turunu anlatan destekli deger.

`Target Type Set`: Target type degerlerinin hizli kontrolu icin kullanilan `frozenset`.

`Target Reference Validation`: `target_record_type` ve `target_record_id` alanlarinin birlikte ve anlamli kullanildigini kontrol eden validation.

`Allowed-list validation`: Bir alanin yalnizca onceden izin verilmis degerlerden birini kabul etmesi.

`Membership kontrolu`: Bir degerin bir koleksiyon icinde bulunup bulunmadigini kontrol etme islemi.

## Adim 121'e baglanti

Bu adimda target record type sozlesmesi koda baglandi.

Onerilen sonraki adim:

```text
Adim 121 - Audit event target record id format tasarimi veya audit event serialization tasarimi
```

Bir sonraki adimda `target_record_id` degerlerinin nasil adlandirilacagi veya audit event kayitlarinin nasil serialize edilecegi tasarlanabilir.
