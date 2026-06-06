# Adim 035 - NonconformityProcessViewRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, kesin uygunsuzluk / NCR surecini tek bakista okunacak bir gorunum modeliyle temsil etmeyi ogreniyoruz.

Bu model islem yapmaz. Veritabani sorgusu calistirmaz. Otomatik donusum veya otomatik NCR olusturma yapmaz. Sadece bir rapor, liste veya ekran icin okunabilecek ozet veri seklini tanimlar.

## 2. Modelin Amaci

`NonconformityProcessViewRecord`, bir kesin uygunsuzluk kaydinin temel bilgilerini, adaydan donusum baglantisini ve guncel takip ozetini tek kayitta temsil eder.

Sunu yaptik: Kesin uygunsuzluk sureci icin baslangic gorunum modeli ekledik.

Boyle yaptik: `nonconformity_id`, `source_candidate_id`, `conversion_record_id`, durum alanlari ve ozet alanlarini bir araya getirdik.

Cunku: Santiye sefi bir NCR kaydinin nereden geldigini ve hangi durumda oldugunu tek bakista gormek ister.

Boylece: Sistem ileride rapor veya arayuz hazirlayacaksa hangi NCR bilgilerini yan yana okuyacagini bilir.

## 3. Model Kodu

```python
@dataclass
class NonconformityProcessViewRecord:
    """Represents a simple nonconformity process view record."""

    nonconformity_id: str
    source_candidate_id: str | None = None
    conversion_record_id: str | None = None
    title: str | None = None
    nonconformity_type: str | None = None
    severity: str = "medium"
    responsible_party: str | None = None
    current_status: str = "open"
    final_status: str | None = None
    last_update_date: str | None = None
    process_summary: str | None = None
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityProcessViewRecord:` kesin uygunsuzluk surec gorunumu icin yeni model tanimlar.
- `nonconformity_id: str`: Kesin uygunsuzluk kaydinin kodunu zorunlu alan olarak tutar.
- `source_candidate_id: str | None = None`: Kaynak aday kaydi ozet referansini opsiyonel tutar.
- `conversion_record_id: str | None = None`: Donusum kaydi ozet referansini opsiyonel tutar.
- `title: str | None = None`: NCR basligini opsiyonel tutar.
- `nonconformity_type: str | None = None`: Uygunsuzluk turunu opsiyonel tutar.
- `severity: str = "medium"` onem seviyesini varsayilan olarak `medium` tutar.
- `responsible_party: str | None = None`: Sorumlu tarafi opsiyonel tutar.
- `current_status: str = "open"` guncel durumu varsayilan olarak `open` tutar.
- `final_status: str | None = None`: Nihai durumu opsiyonel tutar.
- `last_update_date: str | None = None`: Son guncelleme tarihini opsiyonel tutar.
- `process_summary: str | None = None`: Surec ozetini opsiyonel tutar.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

## 5. Test Kodu

```python
def test_nonconformity_process_view_record_holds_values_and_defaults() -> None:
    process_view = NonconformityProcessViewRecord(
        nonconformity_id="NCR-001",
        source_candidate_id="NCR-CAND-001",
        conversion_record_id="NCR-CAND-CONV-001",
        title="Kuzey cephe korkuluk eksigi",
        nonconformity_type="is guvenligi",
        severity="high",
        responsible_party="Saha ekibi",
        current_status="in_progress",
        final_status="open",
        last_update_date="2026-06-23",
        process_summary="Aday kayittan kesin uygunsuzluga donustu ve saha ekibi takibinde.",
    )

    assert process_view.nonconformity_id == "NCR-001"
    assert process_view.source_candidate_id == "NCR-CAND-001"
    assert process_view.conversion_record_id == "NCR-CAND-CONV-001"
    assert process_view.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_process_view_record_holds_values_and_defaults() -> None:` modelin verilen degerleri sakladigini ve not alaninin varsayilanini test eder.
- `process_view = NonconformityProcessViewRecord(...)` test icin bir NCR surec gorunum kaydi olusturur.
- `nonconformity_id="NCR-001"` kesin uygunsuzluk kaydini belirtir.
- `source_candidate_id="NCR-CAND-001"` gorunumde kaynak aday kaydi gosterir.
- `conversion_record_id="NCR-CAND-CONV-001"` gorunumde donusum kaydini gosterir.
- `title="Kuzey cephe korkuluk eksigi"` kaydin basligini belirtir.
- `severity="high"` onem seviyesini belirtir.
- `current_status="in_progress"` guncel takip durumunu belirtir.
- `process_summary=...` surecin kisa ozetini belirtir.
- `assert process_view.notes is None` not verilmediginde `None` kaldigini kontrol eder.

## 7. Varsayilan Deger Testi

```python
def test_nonconformity_process_view_record_optional_fields_default() -> None:
    process_view = NonconformityProcessViewRecord(
        nonconformity_id="NCR-002",
    )

    assert process_view.source_candidate_id is None
    assert process_view.conversion_record_id is None
    assert process_view.severity == "medium"
    assert process_view.current_status == "open"
    assert process_view.final_status is None
    assert process_view.process_summary is None
```

Bu test, gorunum modeli yalnizca NCR koduyla olustugunda diger alanlarin guvenli varsayilanlarla basladigini gosterir.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Gorunum modeli ayri tutuldu | `NonconformityProcessViewRecord` eklendi | Rapor/ekran ozeti islem kaydindan farklidir | Model sorumlulugu net kalir |
| Donusum referanslari gorunum alani oldu | `source_candidate_id` ve `conversion_record_id` kullanildi | Bunlar sadece ozet okumada lazimdir | Asil donusum modeli tekrar edilmez |
| Varsayilan durumlar verildi | `severity = "medium"`, `current_status = "open"` | Bos gorunum kaydi guvenli baslamalidir | Test edilebilirlik artar |
| Otomatik is akisi eklenmedi | Sadece veri modeli yazildi | Bu adim rapor/gorunum hazirligidir | Kapsam kontrollu kalir |

## 9. Mini Sozluk

`NonconformityProcessViewRecord`: Kesin uygunsuzluk / NCR surecinin temel bilgilerini tek ozet kayitta gosteren veri modeli.

`NCR surec gorunum modeli`: Kesin uygunsuzluk kaydinin durumunu, donusum baglantisini ve takip ozetini tek bakista temsil eden model.

`source_candidate_id`: Gorunum modeli icinde kesin uygunsuzlugun kaynak aday kaydini gosteren ozet alan.

`conversion_record_id`: Gorunum modeli icinde adaydan NCR'a donusum kaydini gosteren ozet alan.

`NCR process summary`: Kesin uygunsuzluk surecinin mevcut durumunu kisa metinle ozetleyen bilgi.

## 10. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik NCR olusturma eklenmedi.

Bu adimda otomatik donusum eklenmedi.

Bu adimda duzeltici faaliyet sistemi eklenmedi.

Bu adimda onay akisi eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.
