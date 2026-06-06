# Adim 033 - NonconformityRecord Model Degerlendirme Raporu Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda kod yazmadan model degerlendirmesi yapmayi ogreniyoruz.

Bir projede bazen yeni alan eklemek veya modeli hemen degistirmek cazip gelir. Ancak CHIEF SITE ENGINEER projesinde once mevcut modelin ne tuttugunu, testin neyi dogruladigini ve yeni surec zinciriyle nasil iliskilendigini anlamak daha guvenli bir yaklasimdir.

## 2. Incelenen Model

Mevcut model:

```python
@dataclass
class NonconformityRecord:
    """Represents a nonconformity found on site."""

    nonconformity_id: str
    project_id: str
    date: str
    title: str
    description: str
    location: str | None = None
    category: str | None = None
    severity: str = "medium"
    responsible_party: str | None = None
    corrective_action: str | None = None
    due_date: str | None = None
    closed_date: str | None = None
    related_inspection_request_id: str | None = None
    related_pour_id: str | None = None
    notes: str | None = None
    status: str = "open"
```

Bu model Adim 007'de sahadaki kesin uygunsuzluk kayitlari icin baslangic modeli olarak eklenmisti.

## 3. Mevcut Test Ne Yapiyor?

Mevcut test:

```python
def test_nonconformity_record_holds_values_and_defaults() -> None:
    record = NonconformityRecord(
        nonconformity_id="ncr-001",
        project_id="prj-001",
        date="2026-06-05",
        title="Eksik donati",
        description="Temel bolgesinde ek donati eksik goruldu.",
    )

    assert record.severity == "medium"
    assert record.status == "open"
```

Test, modelin zorunlu alanlarla olustugunu ve varsayilan alanlarin dogru basladigini kontrol eder.

Sunu yaptik: Modeli degistirmeden once mevcut davranisini okuduk.

Boyle yaptik: Model alanlarini, test beklentilerini ve proje kararlarini karsilastirdik.

Cunku: Model degisikligi yapmadan once hangi ihtiyacin gercekten eksik oldugu bilinmelidir.

Boylece: Revizyon karari aceleyle degil, raporlanmis bir teknik degerlendirmeyle hazirlanir.

## 4. Adim 032 ile Iliski

Adim 032'de `NonconformityCandidateConversionRecord` eklendi.

Bu model, aday kayit ile mevcut kesin uygunsuzluk kaydi arasindaki donusum baglantisini tutar:

```python
@dataclass
class NonconformityCandidateConversionRecord:
    """Represents a simple nonconformity candidate conversion record."""

    candidate_id: str
    nonconformity_id: str
    conversion_decision: str
    conversion_reason: str
    converted_by: str
    conversion_date: str
    source_closure_id: str | None = None
    status: str = "converted"
    notes: str | None = None
```

Bu yapi sayesinde `NonconformityRecord` icine hemen `source_candidate_id` eklemek zorunlu degildir. Donusum baglantisi ayri modelle izlenebilir.

## 5. Alan Degerlendirme Tablosu

| Alan | Mevcut Modelde Var mi? | Ogrenme Notu |
| --- | --- | --- |
| `source_candidate_id` | Hayir | Aday baglantisi simdilik Adim 032 donusum modeliyle temsil ediliyor. |
| `severity` | Evet | Varsayilan degeri `medium`. |
| `responsible_party` | Evet | Sorumlu taraf opsiyonel tutuluyor. |
| `final_status` | Hayir | Mevcut modelde `status` var; kapanis modelinde `final_status` kullaniliyor. |
| `nonconformity_type` | Hayir | Mevcut modelde benzer amacla `category` var. |
| `location` | Evet | Opsiyonel tutuluyor. |
| `description` | Evet | Zorunlu alan. |
| `detected_by` | Hayir | Tespit eden kisi bilgisi henuz yok. |
| `detection_date` | Hayir | `date` var; tespit tarihi ile kayit tarihi ayrismiyor. |
| `status` | Evet | Varsayilan degeri `open`. |

## 6. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Model degistirilmedi | `app/models.py` aynen birakildi | Bu adim degerlendirme adimidir | Mevcut davranis korunur |
| Yeni test eklenmedi | `tests/test_models.py` degistirilmedi | Model davranisi degismedi | Test sayisi sabit kalabilir |
| Eksik alanlar raporlandi | Degerlendirme dosyasi olusturuldu | Revizyon ihtiyaci once yazili hale gelmelidir | Sonraki karar daha guvenli olur |
| Donusum modeli dikkate alindi | Adim 032 iliskisi incelendi | Aday baglantisi ayri modelle tutuluyor | Tek model fazla yuklenmez |

## 7. Santiye Benzetmesi

Bir santiyede eski bir formu hemen degistirmek yerine once formun hangi bilgileri tuttuguna bakarsin. Sonra yeni surecte hangi bilgilerin eksik kaldigini yazarsin.

`NonconformityRecord` bugun kesin uygunsuzluk formu gibidir. Adaydan kesin kayda gecis ise Adim 032'de ayri bir donusum kaydiyla tutulur. Bu nedenle formu hemen degistirmek yerine once degerlendirme raporu hazirlamak daha dogru bir yazilim disiplinidir.

## 8. Mini Sozluk

`Model degerlendirme raporu`: Mevcut bir veri modelinin yeni ihtiyaclara gore yeterli olup olmadigini inceleyen karar hazirligi dokumani.

`Revizyon karar hazirligi`: Model degisikligi yapmadan once eksiklerin ve gerekcelerin yazili hale getirilmesi.

`source_candidate_id`: Kesin uygunsuzluk kaydinin hangi aday kayittan geldigini dogrudan gosterebilecek olasi alan.

`nonconformity_type`: Kesin uygunsuzlugun turunu ifade edebilecek olasi alan.

`detected_by`: Kesin uygunsuzlugu tespit eden kisi bilgisini tutabilecek olasi alan.

`detection_date`: Kesin uygunsuzlugun tespit tarihini tutabilecek olasi alan.

`final_status`: Bir kaydin kapanis sonrasi nihai durumunu tutabilecek alan.

## 9. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda model degistirilmedi.

Bu adimda yeni model eklenmedi.

Bu adimda test modeli eklenmedi.

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda otomatik NCR olusturma veya duzeltici faaliyet sistemi eklenmedi.
