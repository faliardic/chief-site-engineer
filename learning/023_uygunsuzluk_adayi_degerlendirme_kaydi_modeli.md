# Adim 023 - NonconformityCandidateReviewRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, uygunsuzluk adayi kaydinin degerlendirme bilgisini sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, kesin uygunsuzluk yonetimi veya duzeltici faaliyet sureci kurmak degil, bir uygunsuzluk adayinin kim tarafindan, ne zaman ve hangi kararla degerlendirildigini kayda alacak veri seklini netlestirmektir.

## 2. Modelin Amaci

Sahada fark edilen bir eksik, hata veya risk once uygunsuzluk adayi olarak tutulabilir. Daha sonra bu aday incelenir. Inceleme sonucunda bunun takip edilmesi, resmi uygunsuzluga donusmesi, sadece not olarak kalmasi veya baska bir aksiyon gerektirmesi kararlastirilabilir.

`NonconformityCandidateReviewRecord`, bu degerlendirme kararini veri modeli olarak temsil eder.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateReviewRecord:
    """Represents a simple nonconformity candidate review record."""

    candidate_title: str
    reviewed_by: str
    review_date: str
    review_result: str
    decision_reason: str
    next_action: str
    status: str = "reviewed"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateReviewRecord:` uygunsuzluk adayi degerlendirmesi icin yeni model tanimlar.
- `"""Represents a simple nonconformity candidate review record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `candidate_title: str`: Degerlendirilen uygunsuzluk adayinin basligini zorunlu alan olarak tutar.
- `reviewed_by: str`: Degerlendirmeyi yapan kisi bilgisini zorunlu alan olarak tutar.
- `review_date: str`: Degerlendirme tarihini zorunlu alan olarak tutar.
- `review_result: str`: Degerlendirme sonucunu zorunlu alan olarak tutar.
- `decision_reason: str`: Kararin gerekcesini zorunlu alan olarak tutar.
- `next_action: str`: Degerlendirme sonrasinda yapilacak islemi zorunlu alan olarak tutar.
- `status: str = "reviewed"` kaydi varsayilan olarak degerlendirilmis durumda baslatir.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

Sunu yaptik: Uygunsuzluk adayi degerlendirmesini `NonconformityCandidateReviewRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Degerlendirme icin gereken kisi, tarih, sonuc, gerekce ve sonraki aksiyon alanlarini zorunlu tuttuk.

Cunku: Bir degerlendirme kaydi, karar bilgisi olmadan anlamli olmaz.

Boylece: Santiye sefi aday uygunsuzluk bilgisinin nasil ele alindigini kayda alabilir.

## 5. Test Kodu

```python
def test_nonconformity_candidate_review_record_holds_values_and_defaults() -> None:
    review = NonconformityCandidateReviewRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        reviewed_by="Santiye sefi",
        review_date="2026-06-06",
        review_result="takip gerekli",
        decision_reason="Eksik parca guvenlik riski olusturuyor",
        next_action="Korkuluk eksigi icin gorev adayi ac",
    )

    assert review.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert review.reviewed_by == "Santiye sefi"
    assert review.review_date == "2026-06-06"
    assert review.review_result == "takip gerekli"
    assert review.decision_reason == "Eksik parca guvenlik riski olusturuyor"
    assert review.next_action == "Korkuluk eksigi icin gorev adayi ac"
    assert review.status == "reviewed"
    assert review.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_review_record_holds_values_and_defaults() -> None:` yeni test fonksiyonunu tanimlar.
- `review = NonconformityCandidateReviewRecord(...)` test icin bir uygunsuzluk adayi degerlendirme kaydi olusturur.
- `candidate_title="Kuzey cephe korkuluk eksigi"` hangi aday kaydin degerlendirildigini gosterir.
- `reviewed_by="Santiye sefi"` degerlendirmeyi yapan kisiyi verir.
- `review_date="2026-06-06"` degerlendirme tarihini verir.
- `review_result="takip gerekli"` degerlendirme sonucunu verir.
- `decision_reason="Eksik parca guvenlik riski olusturuyor"` karar gerekcesini verir.
- `next_action="Korkuluk eksigi icin gorev adayi ac"` sonraki aksiyonu verir.
- `assert review.candidate_title == ...` aday basliginin modelde tutuldugunu dogrular.
- `assert review.reviewed_by == ...` degerlendiren kisi bilgisinin tutuldugunu dogrular.
- `assert review.review_date == ...` degerlendirme tarihinin tutuldugunu dogrular.
- `assert review.review_result == ...` degerlendirme sonucunun tutuldugunu dogrular.
- `assert review.decision_reason == ...` karar gerekcesinin tutuldugunu dogrular.
- `assert review.next_action == ...` sonraki aksiyon bilgisinin tutuldugunu dogrular.
- `assert review.status == "reviewed"` durum alaninin varsayilan olarak `reviewed` geldigini kontrol eder.
- `assert review.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Degerlendirme kaydi ayri model yapildi | `NonconformityCandidateReviewRecord` eklendi | Aday kayit ile degerlendirme karari farkli bilgilerdir | Kapsam net kalir |
| Degerlendiren kisi zorunlu tutuldu | `reviewed_by: str` kullanildi | Kararin kim tarafindan verildigi bilinmelidir | Sorumluluk bilgisi kaybolmaz |
| Degerlendirme sonucu zorunlu tutuldu | `review_result: str` kullanildi | Sonucsuz degerlendirme kaydi anlamli olmaz | Kaydin karari okunabilir olur |
| Karar gerekcesi zorunlu tutuldu | `decision_reason: str` kullanildi | Sahadaki kararlar nedenleriyle izlenmelidir | Sonradan bakildiginda karar anlasilir |
| Sonraki aksiyon zorunlu tutuldu | `next_action: str` kullanildi | Degerlendirme sonrasi ne yapilacagi net olmalidir | Takip davranisi icin zemin olusur |
| Durum sade tutuldu | `status: str = "reviewed"` kullanildi | Bu adimda onay/kapatma akisi kurulmaz | Model basit kalir |

## 8. Mini Sozluk

`NonconformityCandidateReviewRecord`: Uygunsuzluk adayinin degerlendirme bilgisini temsil eden Python veri modeli.

`candidate_title`: Degerlendirilen uygunsuzluk adayinin kisa basligini tutan alan.

`reviewed_by`: Degerlendirmeyi yapan kisi bilgisini tutan alan.

`review_date`: Degerlendirmenin yapildigi tarihi tutan alan.

`review_result`: Degerlendirme sonucunu tutan alan.

`decision_reason`: Kararin neden verildigini aciklayan alan.

`next_action`: Degerlendirme sonrasinda yapilacak islemi tutan alan.

`reviewed`: Degerlendirme kaydinin tamamlanmis/degerlendirilmis durumda oldugunu anlatan varsayilan durum degeri.

## 9. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda dosya/fotograf eki eklenmedi.

Bu adimda kesin uygunsuzluk yonetimi baslatilmadi.

Bu adimda duzeltici faaliyet sistemi kurulmadı.

Bu adim yalnizca uygunsuzluk adayinin degerlendirme bilgisini tutan veri modelini ekler.
