# Adim 034 - NonconformityRecord Alan Revizyonu Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda mevcut bir dataclass modelini kontrollu sekilde revize etmeyi ogreniyoruz.

Yeni model olusturmak yerine mevcut `NonconformityRecord` modeline opsiyonel alanlar ekledik. Boylece model daha zengin hale geldi ama eski kullanimlar bozulmadi.

## 2. Neden Yeni Model Eklenmedi?

`NonconformityRecord` zaten Adim 007'de eklenmisti. Bu nedenle Adim 034'te yeni bir `NonconformityRecord` yazmak dogru olmazdi.

Sunu yaptik: Mevcut modeli bulduk ve ayni model uzerinde alan revizyonu yaptik.

Boyle yaptik: Yeni alanlari opsiyonel varsayilanlarla ekledik.

Cunku: Mevcut testler ve eski kullanimlar yeni zorunlu alanlardan etkilenmemelidir.

Boylece: Model genisledi ama geriye uyumluluk korundu.

## 3. Revize Edilen Model Kodu

```python
@dataclass
class NonconformityRecord:
    """Represents a nonconformity found on site."""

    nonconformity_id: str
    project_id: str
    date: str
    title: str
    description: str
    nonconformity_type: str | None = None
    location: str | None = None
    category: str | None = None
    severity: str = "medium"
    detected_by: str | None = None
    detection_date: str | None = None
    responsible_party: str | None = None
    corrective_action: str | None = None
    due_date: str | None = None
    closed_date: str | None = None
    related_inspection_request_id: str | None = None
    related_pour_id: str | None = None
    final_status: str | None = None
    notes: str | None = None
    status: str = "open"
```

## 4. Yeni Alanlarin Anlami

- `nonconformity_type`: Kesin uygunsuzlugun turunu temsil eder.
- `detected_by`: Kesin uygunsuzlugu kimin tespit ettigini temsil eder.
- `detection_date`: Kesin uygunsuzlugun tespit tarihini temsil eder.
- `final_status`: Kapanis sonrasi nihai durum bilgisini temsil eder.

Bu alanlar `None` varsayilaniyla baslar. Bu, yeni alanlarin ilk anda bilinmeyebilecegi anlamina gelir.

## 5. Bilincli Olarak Eklenmeyen Alanlar

`source_candidate_id` eklenmedi.

`conversion_record_id` eklenmedi.

Bu iki bilginin gerekcesi aynidir: Aday kayit ile kesin uygunsuzluk kaydi arasindaki baglanti zaten `NonconformityCandidateConversionRecord` modeliyle temsil edilir. Ayni baglantiyi `NonconformityRecord` icinde tekrar etmek gereksiz tekrar olusturur.

## 6. Guncellenen Test Kodu

```python
assert record.nonconformity_type is None
assert record.detected_by is None
assert record.detection_date is None
assert record.final_status is None
```

Bu kontroller, yeni alanlarin modelde bulundugunu ve deger verilmediginde guvenli sekilde `None` kaldigini dogrular.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Mevcut model revize edildi | `NonconformityRecord` icine alan eklendi | Model zaten projede var | Model kimligi korunur |
| Yeni alanlar opsiyonel yapildi | `str | None = None` kullanildi | Eski kullanimlar bozulmamalidir | Geriye uyumluluk korunur |
| Aday baglantisi tekrar edilmedi | `source_candidate_id` eklenmedi | Donusum modeli zaten bu baglantiyi tutar | Model sorumlulugu net kalir |
| Mevcut test genisletildi | Yeni varsayilanlar ayni testte dogrulandi | Model davranisi ayni test konusu icinde kalir | Test sayisi gereksiz artmaz |

## 8. Santiye Benzetmesi

Bu adim, mevcut bir saha formuna yeni kutucuklar eklemek gibidir. Formu yeniden basmiyoruz; ayni formun uzerine "uygunsuzluk turu", "tespit eden", "tespit tarihi" ve "nihai durum" alanlarini ekliyoruz.

Ama aday kayittan gelip gelmedigi bilgisini bu formda tekrar yazmiyoruz. Bunun icin ayri bir donusum kaydi var. Bu, santiyede dosya duzenini sade tutmaya benzer: ayni bilgi iki farkli yerde tekrarlanmaz.

## 9. Mini Sozluk

`NonconformityRecord alan revizyonu`: Mevcut kesin uygunsuzluk modeline yeni alanlar eklenirken modelin kimligini ve mevcut davranisini koruma islemi.

`nonconformity_type`: Kesin uygunsuzlugun turunu belirten alan.

`detected_by`: Kesin uygunsuzlugu tespit eden kisi bilgisini tutan alan.

`detection_date`: Kesin uygunsuzlugun tespit tarihini tutan alan.

`final_status`: Kapanis sonrasi nihai durum bilgisini tutan alan.

`source_candidate_id tekrarindan kacinma`: Aday kaynak bilgisini `NonconformityRecord` icinde tekrarlamak yerine donusum kaydinda tutma karari.

`conversion_record_id tekrarindan kacinma`: Donusum baglantisini `NonconformityRecord` icinde ters referansla tekrar etmemeyi anlatan karar.

## 10. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda yeni model olusturulmadi.

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik NCR olusturma eklenmedi.

Bu adimda otomatik donusum eklenmedi.

Bu adimda duzeltici faaliyet sistemi eklenmedi.

Bu adimda onay akisi eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.
