# Adim 027 - NonconformityCandidateProcessViewRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, bir surecin farkli parcalarini tek bir ozet veri modeliyle temsil etmeyi ogreniyoruz.

Uygunsuzluk adayi sureci artik sadece tek kayittan olusmuyor. Kontrol sonucu, aday kayit, degerlendirme, aksiyon, takip ozeti ve ek dosya baglantisi gibi parcalar var. `NonconformityCandidateProcessViewRecord`, bu parcalari tek bakista okunacak bir ozet kayit olarak temsil eder.

## 2. Modelin Amaci

Bu modelin amaci veriyi otomatik toplamak degildir.

Bu modelin amaci, ileride bir rapor, liste veya ekranda gosterilecek surec ozetinin hangi alanlardan olusacagini netlestirmektir.

Sunu yaptik: Uygunsuzluk adayi surec zinciri icin baslangic gorunum modeli ekledik.

Boyle yaptik: Surecin parcalarini ID alanlariyla, ek dosya durumunu `attachment_count` ile, genel durumu da `current_status` ve `process_summary` ile tuttuk.

Cunku: Santiye sefi surecin tamamini tek bakista okumak ister.

Boylece: Sistem ileride raporlama veya ekran gelistirmeden once veri seviyesinde hangi ozet bilgileri gosterecegini bilir.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateProcessViewRecord:
    """Represents a simple nonconformity candidate process view record."""

    candidate_id: str
    check_result_id: str | None = None
    review_id: str | None = None
    action_id: str | None = None
    tracking_summary_id: str | None = None
    attachment_count: int = 0
    current_status: str = "open"
    last_update_date: str | None = None
    process_summary: str | None = None
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateProcessViewRecord:` uygunsuzluk adayi surec gorunumu icin yeni model tanimlar.
- `candidate_id: str`: Uygunsuzluk adayi kaydinin kodunu zorunlu alan olarak tutar.
- `check_result_id: str | None = None`: Iliskili kontrol sonucu kaydini opsiyonel tutar.
- `review_id: str | None = None`: Iliskili degerlendirme kaydini opsiyonel tutar.
- `action_id: str | None = None`: Iliskili aksiyon kaydini opsiyonel tutar.
- `tracking_summary_id: str | None = None`: Iliskili takip ozeti kaydini opsiyonel tutar.
- `attachment_count: int = 0`: Bagli ek dosya sayisini varsayilan olarak `0` tutar.
- `current_status: str = "open"` sureci varsayilan olarak acik durumda baslatir.
- `last_update_date: str | None = None`: Son guncelleme tarihini opsiyonel tutar.
- `process_summary: str | None = None`: Surec ozet metnini opsiyonel tutar.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

## 5. Test Kodu

```python
def test_nonconformity_candidate_process_view_record_holds_values_and_defaults() -> None:
    process_view = NonconformityCandidateProcessViewRecord(
        candidate_id="NCR-CAND-001",
        check_result_id="CHK-RES-001",
        review_id="NCR-CAND-REV-001",
        action_id="NCR-CAND-ACT-001",
        tracking_summary_id="NCR-CAND-TRK-001",
        attachment_count=2,
        current_status="aksiyon bekliyor",
        last_update_date="2026-06-12",
        process_summary="Korkuluk eksigi degerlendirildi ve saha aksiyonu bekleniyor.",
    )

    assert process_view.candidate_id == "NCR-CAND-001"
    assert process_view.attachment_count == 2
    assert process_view.current_status == "aksiyon bekliyor"
    assert process_view.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_process_view_record_holds_values_and_defaults() -> None:` modelin verilen degerleri sakladigini ve not alaninin varsayilanini kontrol eden testtir.
- `process_view = NonconformityCandidateProcessViewRecord(...)` test icin bir surec gorunum kaydi olusturur.
- `candidate_id="NCR-CAND-001"` ana uygunsuzluk adayi kaydini temsil eder.
- `check_result_id="CHK-RES-001"` surecin kaynak kontrol sonucunu temsil eder.
- `review_id="NCR-CAND-REV-001"` degerlendirme kaydini temsil eder.
- `action_id="NCR-CAND-ACT-001"` aksiyon kaydini temsil eder.
- `tracking_summary_id="NCR-CAND-TRK-001"` takip ozeti kaydini temsil eder.
- `attachment_count=2` iki adet ek dosya baglantisi oldugunu temsil eder.
- `current_status="aksiyon bekliyor"` surecin guncel durumunu temsil eder.
- `last_update_date="2026-06-12"` son guncelleme tarihini temsil eder.
- `process_summary=...` surecin kisa ozetini temsil eder.
- `assert process_view.candidate_id == ...` aday kayit kodunun saklandigini kontrol eder.
- `assert process_view.attachment_count == 2` ek dosya sayisinin saklandigini kontrol eder.
- `assert process_view.current_status == ...` guncel durumun saklandigini kontrol eder.
- `assert process_view.notes is None` not verilmediginde `None` kaldigini kontrol eder.

## 7. Varsayilan Deger Testi

```python
def test_nonconformity_candidate_process_view_record_defaults() -> None:
    process_view = NonconformityCandidateProcessViewRecord(
        candidate_id="NCR-CAND-002",
    )

    assert process_view.check_result_id is None
    assert process_view.review_id is None
    assert process_view.action_id is None
    assert process_view.tracking_summary_id is None
    assert process_view.attachment_count == 0
    assert process_view.current_status == "open"
    assert process_view.last_update_date is None
    assert process_view.process_summary is None
    assert process_view.notes is None
```

Bu test, surec henuz tam olusmamisken modelin guvenli baslangic degerleriyle calistigini gosterir.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Surec parcalari tek ozet modelde toplandi | `NonconformityCandidateProcessViewRecord` eklendi | Surec tek bakista okunabilmelidir | Rapor ve ekran hazirligi guclenir |
| Iliskiler ID alanlariyla tutuldu | `check_result_id`, `review_id`, `action_id` kullanildi | Veritabani iliskisi bu adimda yoktur | Model sade kalir |
| Ek dosya durumu sayi ile temsil edildi | `attachment_count: int = 0` kullanildi | Gercek dosya sayma bu adimda yoktur | Kanit dosyasi varligi okunabilir olur |
| Durum alani eklendi | `current_status: str = "open"` kullanildi | Surecin guncel durumu tek alanda okunmalidir | Santiye sefi hizli karar verir |

## 9. Mini Sozluk

`NonconformityCandidateProcessViewRecord`: Uygunsuzluk adayi surecinin parcalarini tek ozet kayitta gosteren veri modeli.

`Surec gorunum modeli`: Birden fazla surec parcasini tek bakista okunacak ozet kayit olarak temsil eden model.

`Surec zinciri`: Bir kaydin kontrol sonucu, aday kayit, degerlendirme, aksiyon, takip ozeti ve ek dosya gibi ard arda gelen parcalari.

`attachment_count`: Bir kayda bagli ek dosya sayisini temsil eden alan.

`current_status`: Surecin guncel durumunu temsil eden alan.

`process_summary`: Surecin genel durumunu kisa metin olarak ozetleyen alan.

## 10. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik raporlama eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.

Bu adimda kesin uygunsuzluk veya duzeltici faaliyet sistemi kurulmadi.
