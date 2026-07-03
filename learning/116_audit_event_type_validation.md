# Adim 116 - Audit Event Type Sabitleri ve Validation

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord.event_type` sozlesmesini koda bagladik.

Adim 115'te event type degerlerini dokumantasyon sozlesmesi olarak yazmistik. Bu adimda ayni listeyi `AUDIT_EVENT_TYPES` tuple'i ve `AUDIT_EVENT_TYPE_SET` frozenset'i ile model katmanina ekledik.

Ayrica `AuditEventRecord.__post_init__` icine desteklenmeyen event type degerlerini reddeden validation ekledik.

## Neden yaptik?

`event_type` alani audit event kaydinin olay turunu anlatir.

Bu alan serbest metin olarak kalirsa ayni olay farkli metinlerle yazilabilir. Ornegin `record.created`, `record_created`, `Kayit olusturuldu` gibi farkli degerler sistem icinde ayni olayi temsil etmeye calisir.

Bu durum ileride filtreleme, raporlama ve audit trail incelemesini zorlastirir.

Bu nedenle desteklenen ilk event type listesi merkezi hale getirildi ve model bu liste disindaki degerleri reddedecek hale geldi.

## Dokunulan dosyalar

```text
app/models.py
tests/test_models.py
docs/116_audit_event_type_validation.md
learning/116_audit_event_type_validation.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
docs/115_audit_event_type_sozlesmesi.md
learning/GLOSSARY.md
```

`app/models.py`: Event type sabitleri ve validation eklendi.

`tests/test_models.py`: Sabit liste, set uyumu, desteklenen event type ve desteklenmeyen event type testleri eklendi.

Dokumantasyon ve learning dosyalari karar ve ogrenme kaydi icin guncellendi.

## `AUDIT_EVENT_TYPES` kod blogu

```python
AUDIT_EVENT_TYPES: tuple[str, ...] = (
    "record.created",
    "record.updated",
    "record.archived",
    "record.restored",
    "attachment.linked",
    "attachment.unlinked",
    "attachment.metadata_updated",
    "integrity.checked",
    "integrity.report_generated",
    "integrity.issue_detected",
    "json.exported",
    "json.export_failed",
    "backup.generated",
    "backup.validated",
    "restore.started",
    "restore.completed",
    "restore.failed",
    "handover.package_generated",
    "handover.package_validated",
    "audit.event_created",
    "audit.validation_failed",
)
```

Bu kodun amaci:
Desteklenen event type degerlerini tek yerde, sirali ve okunabilir bicimde tutmak.

## `AUDIT_EVENT_TYPE_SET` kod blogu

```python
AUDIT_EVENT_TYPE_SET: frozenset[str] = frozenset(AUDIT_EVENT_TYPES)
```

Bu kodun amaci:
Tuple icindeki degerlerden degistirilemeyen bir set uretmek.

Set yapisi membership kontrolu icin uygundur. Yani `event_type bu listede var mi?` sorusu bu yapiyla sade sekilde sorulur.

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
```

Bu kodda once zorunlu alanlar kontrol edilir.

Sonra `event_type` degeri allowed list icinde mi diye bakilir.

Bu sira onemlidir. `event_type` bos veya `None` ise hata `event_type is required` olarak kalir. Dolu ama desteklenmeyen bir deger ise hata `event_type is not supported` olur.

## Validation akisi

1. `AuditEventRecord(...)` cagrilir.
2. Dataclass alanlari nesneye yerlestirir.
3. `__post_init__` calisir.
4. `event_id`, `project_id`, `event_type`, `actor`, `occurred_at` alanlari bos/whitespace/None icin kontrol edilir.
5. Bu kontroller gecerliyse `event_type` allowed list icinde mi diye bakilir.
6. Deger `AUDIT_EVENT_TYPE_SET` icindeyse nesne olusur.
7. Deger set icinde degilse `ValueError("event_type is not supported")` yukseltir.

## Gercek test kodu blogu

```python
def test_audit_event_record_rejects_unsupported_event_type() -> None:
    values = _valid_audit_event_kwargs()
    values["event_type"] = "record.deleted"

    with pytest.raises(ValueError, match="event_type is not supported"):
        AuditEventRecord(**values)
```

Bu testin amaci:
Dolu ama sozlesme disi bir event type degerinin reddedildigini kanitlamak.

## Testlerin satir satir aciklamasi

- `values = _valid_audit_event_kwargs()` gecerli bir audit event veri sozlugu olusturur.
- `values["event_type"] = "record.deleted"` sadece event type alanini gecersiz ama bos olmayan bir degere cevirir.
- `with pytest.raises(...)` bu nesne olusturma denemesinden `ValueError` bekler.
- `match="event_type is not supported"` hata mesajinin dogru ayrimi korudugunu kontrol eder.
- `AuditEventRecord(**values)` modeli bu verilerle olusturmaya calisir.

Diger yeni testler sabit listenin beklenen temel degerleri icerdigini, set'in tuple ile ayni icerikten olustugunu, duplicate deger olmadigini ve desteklenen event type degerinin kabul edildigini kontrol eder.

## Tuple/frozenset tercihinin nedeni

Tuple sozlesme listesini okunabilir tutar.

Frozenset membership kontrolunu sade ve hizli hale getirir.

Enum bu adimda tercih edilmedi. Cunku event type sozlesmesi henuz ilk kod baglantisini aliyor. Daha sonra event type sozlesmesi olgunlasirsa enum veya baska bir yapi ayrica degerlendirilebilir.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Event type listesini koda aldik | `AUDIT_EVENT_TYPES` tuple'i ekledik | Sozlesme tek yerde okunabilir olmali | Desteklenen degerler netlesti |
| Membership kontrolu ekledik | `AUDIT_EVENT_TYPE_SET` frozenset'i kullandik | Event type listede mi sorusu hizli ve sade sorulmali | Validation okunur kaldi |
| Unsupported degeri reddettik | `event_type not in AUDIT_EVENT_TYPE_SET` kontrolu yazdik | Serbest metin event type audit hattini bozar | Model sozlesme disi degeri kabul etmez |
| Required/unsupported ayrimini koruduk | Required kontrolunu once calistirdik | Bos event type ile gecersiz event type farkli sorunlardir | Hata mesajlari daha anlamli kaldi |
| Enum eklemedik | Tuple/frozenset ile ilerledik | Bu asama icin sade yapi yeterli | Geri alinabilir ve kucuk degisiklik yapildi |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
Event type sozlesmesini `AUDIT_EVENT_TYPES` icinde topladik.

Soyle yaptik:
Adim 115'te belgelenen degerleri tuple olarak yazdik.

Ki:
Kod ve dokumantasyon ayni event type dilini kullansin.

Sunu yaptik:
`AUDIT_EVENT_TYPE_SET` ile allowed-list validation ekledik.

Soyle yaptik:
`event_type` degerinin bu set icinde olup olmadigini kontrol ettik.

Ki:
`record.deleted` gibi henuz desteklenmeyen event type degerleri yanlislikla modele girmesin.

## Bilincli olarak yapilmayanlar

Bu adimda database, repository, migration, JSON import/export, audit event persistence veya otomatik audit event uretimi eklenmedi.

Bu adimda decorator, middleware, auth/user/role sistemi, scanner baglantisi, attachment integrity kodu degisikligi, backup/restore davranisi, handover package implementasyonu, API, GUI, CLI veya yeni dependency eklenmedi.

Bu adimda event type enum, event type class yapisi, alias sistemi, config tasima, target record pair validation, UUID validation, tarih format validation, `old_value` / `new_value` validation veya opsiyonel alan validation eklenmedi.

## Mini sozluk

`Allowed List`: Sadece onceden izin verilmis degerlerin kabul edildigi liste.

`Tuple`: Python'da sirali ve degistirilemeyen deger koleksiyonu.

`Frozenset`: Python'da benzersiz degerlerden olusan ve degistirilemeyen set yapisi.

`Unsupported Event Type`: Desteklenen event type listesinde olmayan ve reddedilen event type degeri.

`Membership kontrolu`: Bir degerin belirli bir koleksiyonun icinde olup olmadigini kontrol etme islemi.

## Adim 117'ye baglanti

Bu adim event type sozlesmesini koda bagladi.

Adim 117 icin uygun sonraki konu, audit event target record iliski kurallari dokumantasyonu veya validation tasarimidir. Event type artik sabit listeyle korundugu icin, siradaki karar hangi eventlerin hedef kayit bilgisi tasimasi gerektigi olabilir.
