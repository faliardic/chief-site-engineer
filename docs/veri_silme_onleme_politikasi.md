# Veri Silme Onleme Politikasi

## Temel Karar

CSE'de kanit niteligindeki resmi kayitlar fiziksel olarak silinmez.

Yanlis, gecersiz, tamamlanmis veya artik aktif olmayan resmi kayitlar hard delete ile yok edilmez. Bunun yerine arsivleme, hukumden dusurme, revizyon, superseded kayit veya soft-delete anlaminda status degisikligi kullanilir.

## Silinmeyecek Resmi Kayit Ornekleri

Asagidaki kayitlar resmi proje hafizasi veya kanit zinciri parcasi kabul edilir:

- NCR / uygunsuzluk kayitlari
- Gorevler
- Tutanaklar
- Revizyon kayitlari
- Attachment metadata
- Audit event kayitlari
- Fotograf / video metadata kayitlari
- Proje kararlari
- Kalite kontrol kayitlari

Bu kayitlarin fiziksel olarak silinmesi kalite, denetim, hukuki izlenebilirlik ve saha hafizasi acisindan risklidir.

## Kullanilacak Yontemler

Resmi kayitlarda silme yerine su yaklasimlar kullanilir:

- `is_archived`
- `is_active`
- `voided_at`
- `void_reason`
- `superseded_by`
- `deleted_at` sadece soft-delete anlaminda
- `archive_reason`
- Audit event
- Immutable `created_at` / `created_by`
- `updated_at` / `updated_by`
- Physical delete yerine status degisikligi
- Yanlis kayit icin "hukumden dusuruldu" veya "revize edildi" yaklasimi

## Soft Delete ve Hard Delete Ayrimi

Soft delete, kaydin uygulama akisi icinde gorunurlugunu azaltir ama kaydi sistem hafizasindan silmez.

Hard delete, kaydin fiziksel olarak yok edilmesidir. Resmi kayitlarda hard delete varsayilan davranis olmayacak ve riskli kabul edilecektir.

## Yanlis Kayitlar Icin Yaklasim

Yanlis bir resmi kayit olusturuldugunda kayit silinmez.

Uygun yaklasimlar:

- Kaydi hukumden dusurmek
- Kaydi arsivlemek
- Revize kayit olusturmak
- Yeni kaydi eski kaydin yerine `superseded_by` ile baglamak
- Gerekceyi `void_reason` veya audit event ile saklamak

## Onleyici Teknik Kararlar

Hard delete fonksiyonlari resmi kayitlarda kullanilmayacak.

Cascade delete riskli kabul edilecek. Bir ana kayit silindiginde ona bagli resmi kayit veya attachment metadata'nin izsiz silinmesi engellenecek.

Dosya silme yerine quarantine veya archive yaklasimi kullanilacak.

Attachment dosyalari metadata'dan koparilmayacak. Fiziksel dosya tasinir, kaybolur veya karantinaya alinirsa metadata bu durumu izlemeye devam etmelidir.

Resmi kayit silme talebi audit event uretmelidir.

Silme yerine arsivleme varsayilan davranis olmalidir.

Testlerde ileride hard delete engelleme senaryolari dogrulanmalidir.

## Attachment ve Medya Dosyalari

Fotograf, video, PDF, belge ve ses dosyalari kanit degeri tasiyabilir.

Dosyanin fiziksel kopyasi tasinsa veya karantinaya alinsa bile attachment metadata izlenebilir kalmalidir.

Dosya eki kayip hale gelirse bu durum silinerek gizlenmez; missing file veya unreadable file gibi integrity durumlariyla raporlanir.

## Audit Event Beklentisi

Ileride asagidaki olaylar audit event uretmelidir:

- Kayit arsivleme
- Kaydi hukumden dusurme
- Kaydi revize etme
- Kaydi superseded hale getirme
- Soft delete istegi
- Attachment karantinaya alma
- Fiziksel dosya kaybi veya erisim hatasi

## Bu Dokumanin Siniri

Bu dokuman kod yazmaz.

Database trigger, migration, auth, permission veya audit event implementasyonu eklemez.

Bu dokuman resmi kayitlarda veri silmeyi onleme politikasini tanimlar.
