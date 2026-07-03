# Adim 114 - AuditEventRecord Validation Testleri

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord` modeline dar kapsamli validation ekledik.

Validation, model olusturulurken zorunlu alanlarin bos, sadece bosluklardan olusan veya `None` olmasini engeller.

## Neden yaptik?

Audit event kaydi ileride kanit degeri tasiyan olaylari anlatacak.

Bir audit event icin en az su bilgiler anlamli olmalidir:

- hangi event?
- hangi proje?
- hangi olay turu?
- kim veya hangi kaynak?
- ne zaman?

Bu alanlardan biri bos kalirsa audit event kaydi izlenebilirlik acisindan zayif olur. Bu nedenle ilk validation sadece temel zorunlu alanlari korur.

## Dokunulan dosyalar

```text
app/models.py
tests/test_models.py
docs/114_audit_event_record_validation_testleri.md
learning/114_audit_event_record_validation_testleri.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
learning/GLOSSARY.md
```

`app/models.py`: `AuditEventRecord` modeline `__post_init__` validation eklendi.

`tests/test_models.py`: Bos, whitespace ve `None` zorunlu alanlar icin validation testleri eklendi.

`docs/114_audit_event_record_validation_testleri.md`: Teknik kapsam ve bilincli ertelenen validationlar dokumante edildi.

`learning/114_audit_event_record_validation_testleri.md`: Kod ve testler ogrenme amaciyla aciklandi.

`CHANGELOG.md`, `ROADMAP.md`, `docs/project_decisions.md`, `learning/GLOSSARY.md`: Proje kayitlari guncellendi.

## Gercek `__post_init__` kod blogu

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
```

Bu kodun amaci:
`AuditEventRecord` nesnesi olustuktan hemen sonra zorunlu alanlari kontrol etmek.

Satir satir aciklama:

- `def __post_init__(self) -> None:` Dataclass nesnesi olustuktan sonra calisacak metodu tanimlar.
- `required_fields = (...)` Kontrol edilecek zorunlu alan adlarini tek tuple icinde toplar.
- `for field_name in required_fields:` Her zorunlu alan icin ayni kontrolu calistirir.
- `value = getattr(self, field_name)` Nesnedeki alan degerini alan adiyla okur.
- `if value is None or not value.strip():` Deger `None`, bos string veya sadece whitespace ise gecersiz kabul eder.
- `raise ValueError(...)` Alan adini iceren sade bir hata yukseltir.

Sunu soyle yaptik ki:
Zorunlu audit event alanlarini tek tek tekrar kod yazmadan ayni kural ile kontrol edebilelim.

## Validation akisi

1. Kod `AuditEventRecord(...)` ile yeni nesne olusturmaya calisir.
2. Dataclass once verilen alanlari nesneye yerlestirir.
3. Dataclass otomatik olarak `__post_init__` metodunu cagirir.
4. `required_fields` icindeki alanlar sirayla okunur.
5. Alan `None`, `""` veya `"   "` gibi sadece bosluklardan olusuyorsa `ValueError` yukseltir.
6. Tum zorunlu alanlar gecerse nesne normal sekilde olusur.

## Ikinci gercek kod blogu: gecersiz deger kontrolu

```python
value = getattr(self, field_name)
if value is None or not value.strip():
    raise ValueError(f"{field_name} is required")
```

Bu kucuk blok validation davranisinin merkezidir.

`value is None` kontrolu, runtime'da `None` verilmesini yakalar.

`not value.strip()` kontrolu, hem bos string degerini hem de sadece bosluklardan olusan metinleri yakalar. `strip()` metnin basindaki ve sonundaki bosluklari temizler. Temizlenmis sonuc bos kalirsa bu alan gercek bir bilgi tasimiyor demektir.

## Gercek test kodu blogu

```python
@pytest.mark.parametrize("empty_value", [""])
def test_audit_event_record_rejects_empty_required_fields(
    empty_value: str,
) -> None:
    for field_name in _REQUIRED_AUDIT_EVENT_FIELDS:
        values = _valid_audit_event_kwargs()
        values[field_name] = empty_value

        with pytest.raises(ValueError, match=f"{field_name} is required"):
            AuditEventRecord(**values)
```

Bu testin amaci:
Her zorunlu audit event alanina bos string verildiginde modelin `ValueError` yukseltmesini kontrol etmek.

## Testlerin satir satir aciklamasi

- `@pytest.mark.parametrize("empty_value", [""])`: Teste bos string degerini parametre olarak verir.
- `def test_audit_event_record_rejects_empty_required_fields(...)`: Bos zorunlu alan davranisini test eden fonksiyonu tanimlar.
- `for field_name in _REQUIRED_AUDIT_EVENT_FIELDS:` Zorunlu alanlarin hepsini tek tek dener.
- `values = _valid_audit_event_kwargs()`: Baslangicta gecerli bir audit event veri sozlugu olusturur.
- `values[field_name] = empty_value`: O turda yalnizca test edilen alani gecersiz hale getirir.
- `with pytest.raises(...)`: Bu nesne olusturma denemesinin hata vermesi gerektigini soyler.
- `AuditEventRecord(**values)`: Sozlukteki degerlerle modeli olusturmaya calisir.

Whitespace ve `None` testleri ayni mantigi kullanir. Tek fark gecersiz degerin `"   "` veya `None` olmasidir.

Opsiyonel alan testleri ise tersini kanitlar: `target_record_type`, `target_record_id`, `reason`, `old_value`, `new_value`, `source` ve `notes` alanlari bu adimda esnek kalir.

## Parametrize neden kullanildi?

Parametrize, ayni test mantigini farkli veriyle calistirmayi kolaylastirir.

Bu adimda test sayisinin hedefi `231 passed` oldugu icin her validation basligi ayri test fonksiyonu olarak tutuldu. Her test fonksiyonu icinde zorunlu alanlar donguyle denenerek tum alanlar kapsandi.

Sunu yaptik:
Bos, whitespace ve `None` kontrollerini ayri test fonksiyonlariyla yazdik.

Boyle yaptik:
Her testte gecersiz degeri parametrize edip zorunlu alan listesini donguyle gezdik.

Cunku:
Hem test sonucu beklenen sayida kalmali hem de her zorunlu alan ayni davranisla korunmaliydi.

Boylece:
Testler okunur kaldi ve final test sayisi `231 passed` oldu.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Zorunlu alan validation ekledik | `__post_init__` icinde alanlari kontrol ettik | Dataclass olusurken hatali veri yakalansin | Eksik audit event kaydi daha basta reddedilir |
| Bos metni reddettik | `not value.strip()` kullandik | `""` ve `"   "` anlamli veri degildir | Sadece gorunmez karakterlerle kayit acilamaz |
| `None` degerini reddettik | `value is None` kontrolu ekledik | Runtime'da tip ipucu tek basina koruma saglamaz | Model daha guvenli davranir |
| Opsiyonel alanlari esnek tuttuk | Bu alanlara ek validation eklemedik | Bu adim dar kapsamli tutuldu | Ileri kurallar sonraki adimlara kalir |
| Audit otomasyonu eklemedik | Sadece model validation yazdik | Persistence ve otomasyon ayri karar ister | Kapsam kucuk ve test edilebilir kalir |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`AuditEventRecord` icine `__post_init__` ekledik.

Soyle yaptik:
Zorunlu alan adlarini bir tuple icinde topladik ve her alan icin `None` veya bos metin kontrolu yaptik.

Ki:
Audit event kaydi kimliksiz, projesiz, actorsuz, olay tursuz veya zamansiz olusturulamasin.

Sunu yaptik:
`old_value` ve `new_value` alanlarini opsiyonel ve esnek biraktik.

Soyle yaptik:
Bu alanlar icin bos string veya JSON format kontrolu eklemedik.

Ki:
Bu alanlarin nasil temsil edilecegi ileride event type sozlesmesiyle birlikte daha bilincli kararlastirilabilsin.

## Bilincli olarak yapilmayanlar

Bu adimda UUID kontrolu yapilmadi.

Bu adimda ISO tarih/zaman kontrolu yapilmadi.

Bu adimda event type enum kontrolu yapilmadi.

Bu adimda target record pair tutarliligi kontrol edilmedi.

Bu adimda actor rol veya kullanici dogrulamasi yapilmadi.

Bu adimda project existence kontrolu yapilmadi.

Bu adimda `old_value` ve `new_value` icin JSON kontrolu yapilmadi.

Bu adimda otomatik `event_id` veya `occurred_at` uretimi yapilmadi.

Bu adimda database, repository, JSON audit export, scanner baglantisi, auth, API, GUI veya CLI eklenmedi.

## Mini sozluk

`Validation`: Verinin belirlenen temel kurallara uyup uymadigini kontrol etme davranisi.

`__post_init__`: Dataclass nesnesi olustuktan hemen sonra calisan ozel metot.

`Required Field`: Model olusturulurken bos birakilmamasi gereken alan.

`Optional Field`: Model olusturulurken verilmese de kabul edilen alan.

`Whitespace`: Bosluk, tab veya satir sonu gibi gorunur bilgi tasimayan karakterler.

`ValueError`: Bir deger kabul edilen kurala uymadiginda yukseltilebilen Python hata turu.

## Adim 115'e baglanti

Bu adim `AuditEventRecord` icin temel zorunlu alan guvenligini sagladi.

Adim 115 icin uygun sonraki konu, audit event target record iliski kurallari veya event type sozlesmesi dokumantasyonudur. Bu sonraki adimda hangi event type degerlerinin kabul edilecegi ya da target kayit bilgilerinin birlikte nasil kullanilacagi karar seviyesinde netlestirilebilir.
