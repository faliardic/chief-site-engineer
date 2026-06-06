# Adim 025 - NonconformityCandidateTrackingSummaryRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, uygunsuzluk adayi surecinin guncel takip durumunu sade bir Python veri modeliyle ozetlemeyi ogreniyoruz.

Amac, gercek takip akisi, gorev atama sistemi veya otomatik durum guncelleme kurmak degil, aday kayit, degerlendirme ve aksiyon kararindan sonra surecin hangi durumda oldugunu veri seviyesinde gostermektir.

## 2. Modelin Amaci

Bir uygunsuzluk adayi once kayda alinabilir, sonra degerlendirilebilir, sonra bir aksiyon karari alabilir. Santiye sefi bu zincirin o anki durumunu hizli okumak ister.

`NonconformityCandidateTrackingSummaryRecord`, bu zincirin guncel takip durumunu tek kayitta ozetler.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateTrackingSummaryRecord:
    """Represents a simple nonconformity candidate tracking summary record."""

    candidate_title: str
    review_result: str
    action_decision: str
    action_owner: str
    tracking_status: str
    last_update_date: str
    summary_note: str
    status: str = "active"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateTrackingSummaryRecord:` uygunsuzluk adayi takip ozeti icin yeni model tanimlar.
- `"""Represents a simple nonconformity candidate tracking summary record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `candidate_title: str`: Takip ozeti yapilan uygunsuzluk adayinin basligini zorunlu alan olarak tutar.
- `review_result: str`: Aday icin verilen degerlendirme sonucunu zorunlu alan olarak tutar.
- `action_decision: str`: Aday icin alinan aksiyon kararini zorunlu alan olarak tutar.
- `action_owner: str`: Aksiyonla iliskili kisi veya ekip bilgisini zorunlu alan olarak tutar.
- `tracking_status: str`: Guncel takip durumunu zorunlu alan olarak tutar.
- `last_update_date: str`: Son takip guncelleme tarihini zorunlu alan olarak tutar.
- `summary_note: str`: Surecin kisa ozetini zorunlu alan olarak tutar.
- `status: str = "active"` kaydi varsayilan olarak aktif durumda baslatir.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

Sunu yaptik: Uygunsuzluk adayi surecinin takip durumunu `NonconformityCandidateTrackingSummaryRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Aday basligi, degerlendirme sonucu, aksiyon karari, aksiyon sorumlusu, takip durumu, son guncelleme tarihi ve ozet notu zorunlu tuttuk.

Cunku: Takip ozeti, surecin nerede kaldigini ve son bilginin ne zaman guncellendigini gostermelidir.

Boylece: Santiye sefi aday uygunsuzluk surecinin guncel durumunu hizli okuyabilir.

## 5. Test Kodu

```python
def test_nonconformity_candidate_tracking_summary_record_holds_values_and_defaults() -> None:
    summary = NonconformityCandidateTrackingSummaryRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        review_result="takip gerekli",
        action_decision="gorev adayi ac",
        action_owner="Saha ekibi",
        tracking_status="aksiyon bekliyor",
        last_update_date="2026-06-11",
        summary_note="Korkuluk eksigi icin saha ekibi aksiyonu bekleniyor",
    )

    assert summary.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert summary.review_result == "takip gerekli"
    assert summary.action_decision == "gorev adayi ac"
    assert summary.action_owner == "Saha ekibi"
    assert summary.tracking_status == "aksiyon bekliyor"
    assert summary.last_update_date == "2026-06-11"
    assert summary.summary_note == "Korkuluk eksigi icin saha ekibi aksiyonu bekleniyor"
    assert summary.status == "active"
    assert summary.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_tracking_summary_record_holds_values_and_defaults() -> None:` yeni test fonksiyonunu tanimlar.
- `summary = NonconformityCandidateTrackingSummaryRecord(...)` test icin bir uygunsuzluk adayi takip ozeti kaydi olusturur.
- `candidate_title="Kuzey cephe korkuluk eksigi"` takip ozeti yapilan aday kaydi verir.
- `review_result="takip gerekli"` onceki degerlendirme sonucunu verir.
- `action_decision="gorev adayi ac"` alinan aksiyon kararini verir.
- `action_owner="Saha ekibi"` aksiyonla iliskili kisi veya ekibi verir.
- `tracking_status="aksiyon bekliyor"` guncel takip durumunu verir.
- `last_update_date="2026-06-11"` son guncelleme tarihini verir.
- `summary_note="Korkuluk eksigi icin saha ekibi aksiyonu bekleniyor"` surecin kisa ozetini verir.
- `assert summary.candidate_title == ...` aday basliginin modelde tutuldugunu dogrular.
- `assert summary.review_result == ...` degerlendirme sonucunun tutuldugunu dogrular.
- `assert summary.action_decision == ...` aksiyon kararinin tutuldugunu dogrular.
- `assert summary.action_owner == ...` aksiyon sorumlusunun tutuldugunu dogrular.
- `assert summary.tracking_status == ...` guncel takip durumunun tutuldugunu dogrular.
- `assert summary.last_update_date == ...` son guncelleme tarihinin tutuldugunu dogrular.
- `assert summary.summary_note == ...` surec ozetinin tutuldugunu dogrular.
- `assert summary.status == "active"` durum alaninin varsayilan olarak `active` geldigini kontrol eder.
- `assert summary.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Takip ozeti ayri model yapildi | `NonconformityCandidateTrackingSummaryRecord` eklendi | Surec ozeti, aday kayit ve aksiyon kaydindan farkli bir okuma bilgisidir | Kapsam net kalir |
| Degerlendirme sonucu tutuldu | `review_result: str` kullanildi | Takip durumunun hangi degerlendirme sonucuna dayandigi bilinmelidir | Surec zinciri okunabilir olur |
| Aksiyon karari tutuldu | `action_decision: str` kullanildi | Takip ozeti, alinan aksiyon kararini gostermelidir | Sonraki okuma kolaylasir |
| Guncel takip durumu tutuldu | `tracking_status: str` kullanildi | Ozet kaydin ana amaci guncel durumu gostermektir | Santiye sefi sureci hizli okuyabilir |
| Son guncelleme tarihi tutuldu | `last_update_date: str` kullanildi | Ozet bilginin ne kadar guncel oldugu bilinmelidir | Eski bilgi ile yeni bilgi ayrilir |
| Durum sade tutuldu | `status: str = "active"` kullanildi | Bu adimda otomatik takip akisi kurulmaz | Model basit kalir |

## 8. Mini Sozluk

`NonconformityCandidateTrackingSummaryRecord`: Uygunsuzluk adayi surecinin guncel takip durumunu ozetleyen Python veri modeli.

`tracking_status`: Uygunsuzluk adayi surecinin guncel takip durumunu tutan alan.

`last_update_date`: Takip ozeti kaydinin son guncelleme tarihini tutan alan.

`summary_note`: Uygunsuzluk adayi surecinin kisa ozet notunu tutan alan.

`active`: Takip ozeti kaydinin aktif durumda oldugunu anlatan varsayilan durum degeri.

`candidate_title`: Takip ozeti yapilan uygunsuzluk adayinin kisa basligini tutan alan.

`review_result`: Onceki degerlendirme sonucunu tutan alan.

`action_decision`: Alinan karar veya aksiyon turunu tutan alan.

`action_owner`: Aksiyonla iliskili kisi veya ekip bilgisini tutan alan.

## 9. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda dosya/fotograf eki eklenmedi.

Bu adimda kesin uygunsuzluk yonetimi baslatilmadi.

Bu adimda duzeltici faaliyet sistemi kurulmadı.

Bu adimda gorev atama veya otomatik takip akisi kurulmadı.

Bu adim yalnizca uygunsuzluk adayi surecinin takip durumunu ozetleyen veri modelini ekler.

## 10. Adim 021-025 Zincirinin Ogrenme Ozeti

Adim 021-025 araliginda uygunsuzluk adayi surecine giden kalite takip zinciri kucuk veri modelleriyle kuruldu.

Adim 021 `CheckResultRecord` ile kontrol sonucunu tuttu.

Adim 022 `NonconformityCandidateRecord` ile uygunsuzluk adayini tuttu.

Adim 023 `NonconformityCandidateReviewRecord` ile aday kaydin degerlendirmesini tuttu.

Adim 024 `NonconformityCandidateActionRecord` ile degerlendirme sonrasi ilk aksiyon kararini tuttu.

Adim 025 `NonconformityCandidateTrackingSummaryRecord` ile bu zincirin guncel takip durumunu ozetledi.

Bu zincirde henuz veritabani, API, GUI, otomatik takip veya resmi uygunsuzluk yonetimi yoktur. Once kavramlarin veri seviyesinde nasil temsil edilecegi ogrenildi.
