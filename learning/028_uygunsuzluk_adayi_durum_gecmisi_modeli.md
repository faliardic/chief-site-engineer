# Adim 028 - NonconformityCandidateStatusHistoryRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, bir kaydin durum degisikliklerini ayri bir veri modeliyle temsil etmeyi ogreniyoruz.

Uygunsuzluk adayi surecinde sadece guncel durumu bilmek bazen yetmez. Kaydin hangi tarihte hangi durumdan hangi duruma gectigi, bu degisikligi kimin yaptigi ve degisikligin neden yapildigi de takip edilmelidir.

## 2. Modelin Amaci

`NonconformityCandidateStatusHistoryRecord`, uygunsuzluk adayi durum gecmisini tutar.

Bu model, "bu aday ne zaman acildi, ne zaman incelemeye alindi, ne zaman aksiyon karari verildi, ne zaman kapandi" sorulari icin baslangic kayit altyapisini temsil eder.

Sunu yaptik: Durum degisikligini ayri bir veri modeli olarak tanimladik.

Boyle yaptik: Eski durum, yeni durum, degisiklik sebebi, degistiren kisi, tarih ve kaynak kayit alanlarini kullandik.

Cunku: Sadece guncel durum, surecin nasil ilerledigini anlatmak icin yeterli degildir.

Boylece: Uygunsuzluk adayi sureci ileride denetim izi veya zaman cizelgesi olarak okunabilir.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateStatusHistoryRecord:
    """Represents a simple nonconformity candidate status history record."""

    candidate_id: str
    old_status: str
    new_status: str
    change_reason: str
    changed_by: str
    change_date: str
    source_record: str | None = None
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateStatusHistoryRecord:` uygunsuzluk adayi durum gecmisi icin yeni model tanimlar.
- `candidate_id: str`: Durumu degisen uygunsuzluk adayi kaydinin kodunu zorunlu alan olarak tutar.
- `old_status: str`: Degisiklikten onceki durumu zorunlu alan olarak tutar.
- `new_status: str`: Degisiklikten sonraki durumu zorunlu alan olarak tutar.
- `change_reason: str`: Durum degisikliginin sebebini zorunlu alan olarak tutar.
- `changed_by: str`: Degisikligi yapan kisiyi zorunlu alan olarak tutar.
- `change_date: str`: Degisikligin tarihini zorunlu alan olarak tutar.
- `source_record: str | None = None`: Degisikligin kaynaklandigi kaydi opsiyonel tutar.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

## 5. Test Kodu

```python
def test_nonconformity_candidate_status_history_record_holds_values_and_defaults() -> None:
    history = NonconformityCandidateStatusHistoryRecord(
        candidate_id="NCR-CAND-001",
        old_status="open",
        new_status="under_review",
        change_reason="Aday uygunsuzluk degerlendirmeye alindi.",
        changed_by="Santiye sefi",
        change_date="2026-06-13",
        source_record="NonconformityCandidateReviewRecord",
    )

    assert history.candidate_id == "NCR-CAND-001"
    assert history.old_status == "open"
    assert history.new_status == "under_review"
    assert history.change_reason == "Aday uygunsuzluk degerlendirmeye alindi."
    assert history.changed_by == "Santiye sefi"
    assert history.change_date == "2026-06-13"
    assert history.source_record == "NonconformityCandidateReviewRecord"
    assert history.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_status_history_record_holds_values_and_defaults() -> None:` modelin verilen degerleri sakladigini ve not alaninin varsayilanini test eder.
- `history = NonconformityCandidateStatusHistoryRecord(...)` test icin bir durum gecmisi kaydi olusturur.
- `candidate_id="NCR-CAND-001"` durum degisikligi yapilan aday kaydi belirtir.
- `old_status="open"` onceki durumu belirtir.
- `new_status="under_review"` yeni durumu belirtir.
- `change_reason=...` degisiklik sebebini belirtir.
- `changed_by="Santiye sefi"` degisikligi yapan kisiyi belirtir.
- `change_date="2026-06-13"` degisikligin tarihini belirtir.
- `source_record="NonconformityCandidateReviewRecord"` degisikligin degerlendirme kaydindan kaynaklandigini belirtir.
- `assert history.candidate_id == ...` aday kodunun saklandigini kontrol eder.
- `assert history.old_status == ...` eski durumun saklandigini kontrol eder.
- `assert history.new_status == ...` yeni durumun saklandigini kontrol eder.
- `assert history.change_reason == ...` degisiklik sebebinin saklandigini kontrol eder.
- `assert history.changed_by == ...` degisikligi yapan kisinin saklandigini kontrol eder.
- `assert history.change_date == ...` degisiklik tarihinin saklandigini kontrol eder.
- `assert history.source_record == ...` kaynak kaydin saklandigini kontrol eder.
- `assert history.notes is None` not verilmediginde `None` kaldigini kontrol eder.

## 7. Varsayilan Deger Testi

```python
def test_nonconformity_candidate_status_history_record_optional_fields_default_to_none() -> None:
    history = NonconformityCandidateStatusHistoryRecord(
        candidate_id="NCR-CAND-002",
        old_status="under_review",
        new_status="action_planned",
        change_reason="Aksiyon karari verildi.",
        changed_by="Saha muhendisi",
        change_date="2026-06-14",
    )

    assert history.source_record is None
    assert history.notes is None
```

Bu test, kaynak kayit ve not verilmediginde opsiyonel alanlarin guvenli sekilde `None` kaldigini gosterir.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Durum degisikligi ayri model yapildi | `NonconformityCandidateStatusHistoryRecord` eklendi | Guncel durum tek basina surec gecmisini anlatmaz | Geriye donuk takip mumkun olur |
| Eski ve yeni durum birlikte tutuldu | `old_status` ve `new_status` kullanildi | Gecisin yonu bilinmelidir | Surec izi okunabilir olur |
| Sebep ve kisi tutuldu | `change_reason` ve `changed_by` kullanildi | Degisikligin neden ve kim tarafindan yapildigi onemlidir | Sorumluluk ve denetim izi guclenir |
| Kaynak kayit opsiyonel tutuldu | `source_record: str | None = None` kullanildi | Her degisiklik belirli bir kayittan gelmeyebilir | Model esnek kalir |

## 9. Mini Sozluk

`NonconformityCandidateStatusHistoryRecord`: Uygunsuzluk adayi durum degisikliklerini temsil eden veri modeli.

`Durum gecmisi`: Bir kaydin zaman icinde hangi durumlara gectigini gosteren kayit dizisi.

`old_status`: Durum degisikliginden onceki durumu tutan alan.

`new_status`: Durum degisikliginden sonraki durumu tutan alan.

`change_reason`: Durum degisikliginin neden yapildigini aciklayan alan.

`changed_by`: Durum degisikligini yapan kisi bilgisini tutan alan.

`change_date`: Durum degisikliginin yapildigi tarihi tutan alan.

`source_record`: Durum degisikliginin hangi kayit veya surec parcasindan kaynaklandigini tutan alan.

## 10. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik raporlama eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.

Bu adimda otomatik durum guncelleme veya is akisi motoru kurulmadi.
