# Adim 026 - AttachmentRecord ile Uygunsuzluk Adayi Ek Dosya Kullanimi Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda yeni bir model eklemek yerine mevcut genel bir modeli belirli bir is senaryosunda kullanmayi ogreniyoruz.

`AttachmentRecord`, dosya eki referansi icin daha once eklenmis genel bir modeldir. Adim 026'da bu modelin `NonconformityCandidateRecord` ile nasil iliskilendirilecegi test ve dokumantasyonla netlestirilir.

Not: Adim 083 sonrasi `AttachmentRecord` legacy / onceki genel ek modeli olarak korunur. Yeni dosya eki hatti icin canonical model `FileAttachmentRecord`, canonical path standardi ise `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}` olarak belirlenmistir.

## 2. Neden Yeni Model Eklenmedi?

On kontrolde `AttachmentRecord` modelinin zaten fotograf, belge veya ek dosya referansi tutabildigi goruldu.

Ayrica modelde `related_model` ve `related_id` alanlari vardir. Bu iki alan, ek dosyanin hangi kayit turune ve hangi kayda baglandigini gostermek icin yeterlidir.

Bu nedenle `NonconformityCandidateAttachment` adinda ayri bir model olusturulmadi.

Sunu yaptik: Yeni model eklemek yerine mevcut genel modelin kullanimini netlestirdik.

Boyle yaptik: `related_model` alanina `"NonconformityCandidateRecord"`, `related_id` alanina ise `"NCR-CAND-001"` gibi aday kayit kodu verdik.

Cunku: Ek dosya mantigi sadece uygunsuzluk adaylari icin degil, baska kayit tipleri icin de ortaktir.

Boylece: Tekrar eden ozel modellerden kacinildi ve ortak dosya eki modeli korunmus oldu.

## 3. Kullanilan Model Kodu

```python
@dataclass
class AttachmentRecord:
    """Represents a file attachment reference."""

    attachment_id: str
    project_id: str
    title: str
    file_name: str
    file_type: str | None = None
    file_path: str | None = None
    related_model: str | None = None
    related_id: str | None = None
    uploaded_by: str | None = None
    uploaded_date: str | None = None
    notes: str | None = None
    status: str = "active"
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class AttachmentRecord:` dosya eki referansi icin genel model tanimlar.
- `attachment_id: str`: Ek kaydinin kimligini zorunlu alan olarak tutar.
- `project_id: str`: Ek dosyanin ait oldugu proje bilgisini tutar.
- `title: str`: Ek dosyanin okunabilir basligini tutar.
- `file_name: str`: Dosyanin adini tutar.
- `file_type: str | None = None`: Dosya turunu opsiyonel tutar.
- `file_path: str | None = None`: Dosya yolunu metinsel referans olarak opsiyonel tutar.
- `related_model: str | None = None`: Ekin hangi model turune baglandigini tutar.
- `related_id: str | None = None`: Ekin hangi kayda baglandigini tutar.
- `uploaded_by: str | None = None`: Eki yukleyen kisi bilgisini opsiyonel tutar.
- `uploaded_date: str | None = None`: Yukleme tarihini opsiyonel tutar.
- `notes: str | None = None`: Ek aciklamasini veya kanit notunu opsiyonel tutar.
- `status: str = "active"` ek kaydini varsayilan olarak aktif baslatir.

## 5. Test Kodu

```python
def test_attachment_record_can_reference_nonconformity_candidate_record() -> None:
    attachment = AttachmentRecord(
        attachment_id="att-ncr-cand-001",
        project_id="prj-001",
        title="Korkuluk eksigi fotografi",
        file_name="korkuluk-eksigi.jpg",
        file_type="image/jpeg",
        file_path="archive/nonconformity-candidates/korkuluk-eksigi.jpg",  # legacy example
        related_model="NonconformityCandidateRecord",
        related_id="NCR-CAND-001",
        uploaded_by="Santiye sefi",
        uploaded_date="2026-06-12",
        notes="Aday uygunsuzluk icin kanit fotografi.",
        status="active",
    )

    assert attachment.related_model == "NonconformityCandidateRecord"
    assert attachment.related_id == "NCR-CAND-001"
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_attachment_record_can_reference_nonconformity_candidate_record() -> None:` ek dosya modelinin uygunsuzluk adayi kaydina baglanmasini test eder.
- `attachment = AttachmentRecord(...)` test icin bir dosya eki referansi olusturur.
- `file_name="korkuluk-eksigi.jpg"` ek dosyanin adini verir.
- `file_type="image/jpeg"` dosyanin fotograf oldugunu belirtir.
- `file_path="archive/nonconformity-candidates/korkuluk-eksigi.jpg"` eski `AttachmentRecord` baglaminda legacy yol ornegidir.
- `related_model="NonconformityCandidateRecord"` ekin uygunsuzluk adayi modeline baglandigini belirtir.
- `related_id="NCR-CAND-001"` ekin hangi aday kayda ait oldugunu belirtir.
- `uploaded_by="Santiye sefi"` eki yukleyen kisiyi belirtir.
- `uploaded_date="2026-06-12"` yukleme tarihini belirtir.
- `notes="Aday uygunsuzluk icin kanit fotografi."` dosyanin kanit amacini aciklar.
- `assert attachment.related_model == ...` model baglantisinin dogru tutuldugunu kontrol eder.
- `assert attachment.related_id == ...` kayit baglantisinin dogru tutuldugunu kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Yeni ozel ek modeli eklenmedi | `NonconformityCandidateAttachment` olusturulmadi | `AttachmentRecord` zaten genel ek dosya modelidir | Tekrar eden model azalir |
| Baglanti metinle temsil edildi | `related_model` ve `related_id` kullanildi | Bu adimda veritabani iliskisi yoktur | Model sade kalir |
| Kanit dosyasi ayni modelle tutuldu | Fotograf ve belge bilgisi `AttachmentRecord` alanlarina yazildi | Ek dosya mantigi kayit tipleri arasinda ortaktir | Ortak kullanim guclenir |
| Gercek dosya islemi eklenmedi | Sadece `file_path` metinsel referans oldu | Bu adimda dosya sistemi yonetimi hedef degildir | Kapsam kontrollu kalir |

## 8. Mini Sozluk

`Ek dosya baglantisi`: Bir fotograf, belge veya dosya referansinin belirli bir kayitla iliskilendirilmesi.

`Generic attachment model`: Farkli kayit tiplerine baglanabilecek ortak dosya eki modeli.

`related_model`: Ek dosyanin hangi model turuyle iliskili oldugunu belirten alan.

`related_id`: Ek dosyanin iliskili oldugu kaydin kodunu veya kimligini belirten alan.

`Kanit dosyasi`: Sahadaki bir gozlem, sorun veya kontrol sonucunu destekleyen fotograf, belge veya dosya.

## 9. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda yeni model eklenmedi.

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda dosya yukleme veya dosya kopyalama islemi eklenmedi.

Bu adimda kesin uygunsuzluk, duzeltici faaliyet veya gorev takip sistemi kurulmadi.
