# Adim 026 - AttachmentRecord ile Uygunsuzluk Adayi Ek Dosya Baglantisi

## Amac

Bu adimin amaci, uygunsuzluk adayi kayitlarina fotograf, belge veya ek dosya referansi baglamak icin yeni ve ozel bir model eklemek yerine mevcut `AttachmentRecord` modelinin nasil kullanilacagini netlestirmektir.

On kontrolde `AttachmentRecord` modelinin zaten genel dosya eki referansi icin tasarlandigi goruldu. Bu nedenle `NonconformityCandidateAttachment` adinda ayri bir model olusturulmadi.

## Kullanilan Model

Bu adimda yeni model eklenmedi.

Mevcut `AttachmentRecord` modeli kullanilir:

- `file_name`: Ekin dosya adi.
- `file_type`: Ekin fotograf, PDF veya benzeri tur bilgisi.
- `file_path`: Dosyanin metinsel yol referansi.
- `related_model`: Ekin hangi model turune baglandigi.
- `related_id`: Ekin hangi kayit koduna baglandigi.
- `uploaded_by`: Eki yukleyen kisi.
- `uploaded_date`: Ekin yuklendigi tarih.
- `status`: Ek kaydinin durumu.
- `notes`: Ek aciklamasi veya kanit notu.

## Uygunsuzluk Adayina Baglama Mantigi

Bir ek dosya uygunsuzluk adayi kaydina baglanacaksa `related_model` degeri `NonconformityCandidateRecord` olarak yazilir.

`related_id` alanina ise ilgili aday kaydin acik kodu yazilir. Ornek:

```python
AttachmentRecord(
    attachment_id="att-ncr-cand-001",
    project_id="prj-001",
    title="Korkuluk eksigi fotografi",
    file_name="korkuluk-eksigi.jpg",
    file_type="image/jpeg",
    file_path="archive/nonconformity-candidates/korkuluk-eksigi.jpg",
    related_model="NonconformityCandidateRecord",
    related_id="NCR-CAND-001",
    uploaded_by="Santiye sefi",
    uploaded_date="2026-06-12",
    notes="Aday uygunsuzluk icin kanit fotografi.",
    status="active",
)
```

## Santiye Pratigindeki Karsiligi

Santiye sefi sahada bir korkuluk eksigi, imalat hatasi veya kalite riski gordugunde bunu once uygunsuzluk adayi olarak kaydedebilir.

Bu aday kayda bir fotograf, tutanak, kontrol formu veya saha belgesi baglanmak istenirse ayni genel `AttachmentRecord` modeli kullanilir. Boylece sistem dosyanin kendisini tasimadan, dosyanin hangi aday kayda ait oldugunu veri seviyesinde bilir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda yeni `NonconformityCandidateAttachment` modeli eklenmedi.

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda gercek dosya yukleme, kopyalama, silme veya tasima islemi eklenmedi.

Bu adimda kesin uygunsuzluk, duzeltici faaliyet veya gorev takip sistemi kurulmadi.

## Sonraki Adimlara Hazirlik

Bu karar, ileride farkli kayit tiplerine ayni dosya eki modeliyle kanit baglanabilmesini saglar.

Uygunsuzluk adayi, kontrol sonucu, malzeme kaydi, gunluk rapor veya saha notu gibi farkli kayitlar icin tekrar eden ozel ek modelleri yerine ortak `AttachmentRecord` kullanimi tercih edilir.
