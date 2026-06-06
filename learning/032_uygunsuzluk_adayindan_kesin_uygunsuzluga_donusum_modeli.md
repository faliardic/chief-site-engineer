# Adim 032 - NonconformityCandidateConversionRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, mevcut bir modeli yeniden olusturmadan yeni bir iliski / donusum modeli eklemeyi ogreniyoruz.

On kontrolde `NonconformityRecord` modelinin Adim 007'de zaten mevcut oldugu goruldu. Bu nedenle yeni bir kesin uygunsuzluk modeli eklemek yerine, aday kaydin mevcut kesin uygunsuzluk kaydina nasil baglandigini temsil eden `NonconformityCandidateConversionRecord` modeli eklendi.

## 2. Modelin Amaci

`NonconformityCandidateConversionRecord`, bir `NonconformityCandidateRecord` kaydinin degerlendirme ve kapanis sonucunda mevcut `NonconformityRecord` kaydina donusmesini temsil eder.

Bu model, "hangi aday kayit, hangi kesin uygunsuzluk kaydina, kim tarafindan, ne zaman ve hangi gerekceyle donusturuldu" sorularina baslangic veri modeliyle cevap verir.

Sunu yaptik: Kesin uygunsuzluk modelini yeniden yazmadik; donusum baglantisini ayri model yaptik.

Boyle yaptik: `candidate_id` ve `nonconformity_id` alanlarini birlikte kullandik.

Cunku: Aday kayit ile kesin uygunsuzluk kaydi farkli kavramlardir; aralarindaki gecis de ayri bir karar izidir.

Boylece: Adaydan NCR'a gecis, veri seviyesinde izlenebilir hale geldi.

## 3. Model Kodu

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

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateConversionRecord:` adaydan kesin uygunsuzluga donusum baglantisi icin yeni model tanimlar.
- `candidate_id: str`: Donusume konu olan aday kaydin kodunu zorunlu alan olarak tutar.
- `nonconformity_id: str`: Baglanan kesin uygunsuzluk / NCR kaydinin kodunu zorunlu alan olarak tutar.
- `conversion_decision: str`: Donusum kararini zorunlu alan olarak tutar.
- `conversion_reason: str`: Donusum gerekcesini zorunlu alan olarak tutar.
- `converted_by: str`: Donusum kararini veren kisiyi zorunlu alan olarak tutar.
- `conversion_date: str`: Donusum tarihini zorunlu alan olarak tutar.
- `source_closure_id: str | None = None`: Donusumun kaynaklandigi kapanis kaydini opsiyonel tutar.
- `status: str = "converted"` donusum kaydini varsayilan olarak `converted` durumda baslatir.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

## 5. Test Kodu

```python
def test_nonconformity_candidate_conversion_record_holds_values_and_defaults() -> None:
    conversion = NonconformityCandidateConversionRecord(
        candidate_id="NCR-CAND-001",
        nonconformity_id="NCR-001",
        conversion_decision="kesin uygunsuzluga donustur",
        conversion_reason="Eksik giderilmedigi icin resmi NCR kaydi acildi.",
        converted_by="Kalite sorumlusu",
        conversion_date="2026-06-21",
        source_closure_id="NCR-CAND-CLOS-001",
    )

    assert conversion.candidate_id == "NCR-CAND-001"
    assert conversion.nonconformity_id == "NCR-001"
    assert conversion.conversion_decision == "kesin uygunsuzluga donustur"
    assert conversion.status == "converted"
    assert conversion.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_conversion_record_holds_values_and_defaults() -> None:` modelin verilen degerleri sakladigini ve varsayilanlari kullandigini test eder.
- `conversion = NonconformityCandidateConversionRecord(...)` test icin bir donusum kaydi olusturur.
- `candidate_id="NCR-CAND-001"` donusume konu olan aday kaydi belirtir.
- `nonconformity_id="NCR-001"` baglanan kesin uygunsuzluk kaydini belirtir.
- `conversion_decision="kesin uygunsuzluga donustur"` donusum kararini belirtir.
- `conversion_reason=...` donusum gerekcesini belirtir.
- `converted_by="Kalite sorumlusu"` donusumu yapan kisiyi belirtir.
- `conversion_date="2026-06-21"` donusum tarihini belirtir.
- `source_closure_id="NCR-CAND-CLOS-001"` donusumun kapanis kaydina dayandigini belirtir.
- `assert conversion.status == "converted"` durumun varsayilan olarak `converted` geldigini kontrol eder.
- `assert conversion.notes is None` not verilmediginde `None` kaldigini kontrol eder.

## 7. Varsayilan Deger Testi

```python
def test_nonconformity_candidate_conversion_record_optional_fields_default() -> None:
    conversion = NonconformityCandidateConversionRecord(
        candidate_id="NCR-CAND-002",
        nonconformity_id="NCR-002",
        conversion_decision="resmi NCR ac",
        conversion_reason="Aday bulgu kesin uygunsuzluk olarak degerlendirildi.",
        converted_by="Santiye sefi",
        conversion_date="2026-06-22",
    )

    assert conversion.source_closure_id is None
    assert conversion.status == "converted"
    assert conversion.notes is None
```

Bu test, kaynak kapanis kaydi verilmediginde `source_closure_id` alaninin `None`, durumun `converted`, not alaninin ise `None` kaldigini gosterir.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| `NonconformityRecord` yeniden eklenmedi | Mevcut Adim 007 modeli korundu | Ayni modelin yeniden yazilmasi cakisma olusturur | Repo tutarliligi korunur |
| Donusum ayri model yapildi | `NonconformityCandidateConversionRecord` eklendi | Adaydan NCR'a gecis ayri bir karar izidir | Surec denetlenebilir olur |
| Aday ve kesin kayit birlikte tutuldu | `candidate_id` ve `nonconformity_id` kullanildi | Donusum iki kayit arasinda bag kurar | Iliski acik okunur |
| Otomatik NCR olusturma eklenmedi | Sadece donusum bilgisi tutuldu | Bu adim veri modelidir, is akisi degildir | Kapsam kontrollu kalir |

## 9. Mini Sozluk

`NonconformityCandidateConversionRecord`: Uygunsuzluk adayinin mevcut kesin uygunsuzluk kaydina donusum baglantisini temsil eden veri modeli.

`Donusum kaydi`: Bir aday kaydin kesin kayda hangi karar ve gerekceyle baglandigini gosteren kayit.

`conversion_decision`: Aday kaydin kesin uygunsuzluga donusturulmesine dair karari tutan alan.

`conversion_reason`: Donusum kararinin gerekcesini tutan alan.

`converted_by`: Donusum kararini veren veya kaydi olusturan kisi bilgisini tutan alan.

`conversion_date`: Aday kaydin kesin uygunsuzluk kaydina donusturuldugu tarihi tutan alan.

`source_closure_id`: Donusum kararinin kaynaklandigi kapanis kaydinin kodunu tutan alan.

`converted`: Kaydin donusum islemiyle iliskilendirildigini anlatan status degeri.

## 10. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda yeni `NonconformityRecord` modeli eklenmedi.

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik NCR olusturma eklenmedi.

Bu adimda otomatik donusum eklenmedi.

Bu adimda duzeltici faaliyet sistemi eklenmedi.

Bu adimda onay akisi eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.
