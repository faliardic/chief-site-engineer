# Adim 036 - NonconformityStatusHistoryRecord Modeli Ogrenim Notu

## Bu Adimda Ne Ogrenildi?

Bu adimda kesin uygunsuzluk / NCR kayitlarinin durum degisim gecmisini ayri bir modelle temsil etme yaklasimi ogrenildi.

Bir kaydin guncel durumu ile durum gecmisi ayni sey degildir. Guncel durum, kaydin su an nerede oldugunu soyler. Durum gecmisi ise kaydin bugune kadar hangi asamalardan gectigini anlatir.

## Modelin Amaci

`NonconformityStatusHistoryRecord`, kesin uygunsuzluk durum gecmisini tutar.

Bu model su sorulara cevap vermek icin hazirlandi:

- NCR hangi durumdan hangi duruma gecti?
- Durum degisikligi neden yapildi?
- Degisikligi kim yapti?
- Degisiklik hangi tarihte yapildi?
- Degisiklik hangi kayit veya surec parcasindan kaynaklandi?

## Model Yapisi

```python
@dataclass
class NonconformityStatusHistoryRecord:
    """Represents a simple nonconformity status history record."""

    nonconformity_id: str
    old_status: str
    new_status: str
    change_reason: str
    changed_by: str
    change_date: str
    source_record: str | None = None
    notes: str | None = None
```

## Alanlarin Anlami

- `nonconformity_id: str`: Durum degisikligi yapilan kesin uygunsuzluk kaydini belirtir.
- `old_status: str`: Degisiklikten onceki durumu tutar.
- `new_status: str`: Degisiklikten sonraki durumu tutar.
- `change_reason: str`: Degisikligin neden yapildigini aciklar.
- `changed_by: str`: Degisikligi yapan kisiyi belirtir.
- `change_date: str`: Degisikligin yapildigi tarihi tutar.
- `source_record: str | None = None`: Degisikligin kaynaklandigi kaydi opsiyonel tutar.
- `notes: str | None = None`: Ek aciklama icin opsiyonel not alanidir.

## Testte Ne Kontrol Edildi?

Testte once tum temel degerlerin saklandigi kontrol edildi:

```python
history = NonconformityStatusHistoryRecord(
    nonconformity_id="NCR-001",
    old_status="open",
    new_status="in_review",
    change_reason="Kesin uygunsuzluk kalite incelemesine alindi.",
    changed_by="Kalite sorumlusu",
    change_date="2026-06-24",
    source_record="NonconformityProcessViewRecord",
)
```

Bu test, modelin NCR durum gecmisini anlamli alanlarla tutabildigini dogrular.

Ikinci testte opsiyonel alanlarin varsayilan davranisi kontrol edildi:

```python
history = NonconformityStatusHistoryRecord(
    nonconformity_id="NCR-002",
    old_status="in_review",
    new_status="action_waiting",
    change_reason="Saha aksiyonu bekleniyor.",
    changed_by="Santiye sefi",
    change_date="2026-06-25",
)
```

Bu durumda `source_record` ve `notes` alanlari `None` kalir.

## Neden Ayri Model?

Durum gecmisi, kaydin uzerindeki tek bir `status` alanindan farklidir.

`NonconformityRecord.status`, kaydin bugunku durumunu tutar. `NonconformityStatusHistoryRecord` ise durum degisikliklerinin gecmisini tutar.

Bu ayrim ileride raporlama, denetim izi ve surec analizi icin daha temiz bir temel hazirlar.

## Bu Adimda Bilincli Olarak Eklenmeyenler

- Veritabani sorgusu
- API
- GUI
- Otomatik durum guncelleme
- Otomatik NCR olusturma
- Duzeltici faaliyet sistemi
- Onay akisi
- JSON kayit sistemi
- Dosya islemi

## Python Acisindan Kazanim

Bu adim, `dataclass` ile olay gecmisi veya denetim izi kaydi tutmanin temelini gosterir.

Bir model yalnizca nesnenin kendisini temsil etmek zorunda degildir. Bazen nesnenin gecirdigi degisiklikleri temsil eden ayri bir model kurmak daha dogrudur.

## Kisa Ozet

Adim 036 ile kesin uygunsuzluk / NCR kayitlari icin durum degisim gecmisi modeli eklendi.

Bu model, "Bu kesin uygunsuzluk ne zaman acildi, ne zaman incelemeye alindi, ne zaman aksiyon beklemeye gecti, ne zaman kapandi?" sorularinin veri seviyesindeki baslangic altyapisini hazirlar.
