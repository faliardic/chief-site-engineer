# Adim 112 - Audit Event Model Plani

## Amac

Bu dokuman gelecekte eklenecek audit event modelinin sinirlarini ve alan adaylarini planlar.

Audit event hatti; resmi kayitlar, attachment integrity raporlari, JSON snapshot ciktisi, backup/restore ve ilerideki duzeltme aksiyonlariyla karismadan, olay izini ayri bir veri sozlesmesi olarak ele alir.

## Audit Event Nedir

Audit event, sistemde kanit degeri tasiyan bir olayin izlenebilir kaydidir.

Audit event su sorulara cevap verecek yapi olarak planlanir:

- Kim yapti?
- Ne yapti?
- Ne zaman yapti?
- Hangi kayit uzerinde yapti?
- Neden yapti?
- Onceki durum neydi?
- Yeni durum ne oldu?
- Bu islem hangi kaynak islemden geldi?
- Bu islem resmi kayit mi, rapor ciktisi mi, bakim/arac islemi mi?

## Ilk Modelin Rolu

Ilk audit event modelinin amaci, CSE'de ileride olusacak kritik olaylari izlenebilir hale getirmek icin veri sozlesmesini planlamaktir.

Model su hatlara zemin hazirlamalidir:

- resmi kayit olusturma / guncelleme / arsivleme
- attachment integrity dry-run raporu
- JSON export snapshot uretimi
- scanner sonucundan gelen problem gorunurlugu
- ileride backup / restore
- ileride hard delete prevention
- ileride handover package

## Olasi Alanlar

Gelecekteki audit event modelinde su alanlar dusunulebilir:

- `event_id`: Audit event kaydinin benzersiz kimligi.
- `event_type`: Olayin turu.
- `target_record_type`: Olayin iliskili oldugu kayit turu.
- `target_record_id`: Olayin iliskili oldugu kayit kimligi.
- `actor`: Islemi yapan kisi, rol veya sistem kaynagi.
- `event_time`: Olayin gerceklestigi zaman.
- `reason`: Islemin nedeni veya aciklamasi.
- `old_value`: Olaydan onceki deger veya durum ozeti.
- `new_value`: Olaydan sonraki deger veya durum ozeti.
- `source`: Olayin hangi islemden veya arac hattindan geldigi.
- `related_report_id`: Iliskili rapor kimligi varsa referansi.
- `related_attachment_id`: Iliskili attachment kimligi varsa referansi.
- `severity`: Olayin onem seviyesi.
- `notes`: Ek aciklama veya sinirlama notlari.

Bu liste implementasyon karari degildir; model/test adiminda daraltilabilir.

## Event Type Adaylari

Ilk event type adaylari:

- `record_created`
- `record_updated`
- `record_archived`
- `record_restored`
- `record_voided`
- `record_superseded`
- `attachment_integrity_checked`
- `attachment_integrity_report_exported`
- `json_report_exported`
- `handover_package_created`
- `backup_created`
- `restore_started`
- `restore_completed`

Bu liste implementasyon degildir. Ilerideki model ve test adiminda daraltilabilir.

## Audit Event Ne Degildir

Audit event resmi kaydin kendisi degildir.

Audit event:

- JSON export dosyasinin kendisi degildir
- backup dosyasinin kendisi degildir
- scanner sonucu yerine gecmez
- AI analizi degildir
- kullanici yetki sistemi degildir

Audit event, bu olaylarin izini tutmak icin kullanilacak ayri bir olay kaydidir.

## Attachment Integrity Hattiyla Iliski

Adim 111'deki attachment integrity akisi sudur:

```text
FileAttachmentRecord metadata
-> dry-run helper
-> AttachmentIntegrityResult
-> AttachmentIntegrityReport
-> serializer
-> JSON export
```

Audit event ileride su olaylari kaydedebilir:

- integrity kontrolu baslatildi
- integrity raporu uretildi
- JSON snapshot export edildi
- `overwrite=True` ile rapor tekrar yazildi
- scanner sonucu bir resmi aksiyona donustu

Bu adimda bu eventler uretilmez. Yalnizca ileride nasil ele alinabilecekleri planlanir.

## Resmi Kayit ve Snapshot Ayrimi

Resmi kayitlar CSE ana veri hafizasidir.

JSON export yalnizca rapor/snapshot ciktisidir.

Audit event resmi kayit veya JSON dosyasi degildir; olay izidir.

Bu ayrim veri silme onleme, backup/restore ve handover package adimlari icin onemlidir.

## Ilk Implementasyon Siniri

Gelecekteki ilk kod adimi icin onerilen sinir:

- sadece `AuditEventRecord` dataclass baslangici
- database yok
- repository yok
- otomatik audit yazimi yok
- decorator/middleware yok
- auth/user sistemi yok
- scanner ile otomatik baglanti yok
- JSON dosyaya audit yazma yok

Ilk model davranisi, otomasyon veya persistence eklemeden veri sozlesmesini netlestirmelidir.

## Bu Adimin Siniri

Bu adim sadece dokumantasyon adimidir.

Bu adimda uygulama kodu, test dosyalari, `AuditEventRecord` dataclass, audit helper, audit repository, audit log yazma, database, migration, JSON persistence, scanner davranisi degisikligi, JSON export kodu degisikligi, backup/restore implementasyonu, upload service, API, GUI, CLI, AI entegrasyonu, automation veya refactor yapilmadi.

Commit atilmadi, push yapilmadi ve `chief-site-engineer_adim_080_guvenli_nokta.zip` dosyasi stage edilmedi.
