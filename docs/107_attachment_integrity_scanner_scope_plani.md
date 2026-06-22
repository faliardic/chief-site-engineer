# Adim 107 - Attachment Integrity Scanner Scope Plani

## Amac

Bu dokuman gelecekte yazilacak attachment integrity scanner icin ilk kapsam sinirlarini belirler.

Scanner'in amaci, `FileAttachmentRecord` metadata kayitlari ile fiziksel dosya sistemi arasindaki tutarliligi ileride kontrol edilebilir hale getirmektir. Bu adimda scanner yazilmaz; yalnizca neyi kontrol edecegi, neyi kontrol etmeyecegi ve hangi guvenlik sinirlari icinde tasarlanacagi netlestirilir.

## Scanner'in Cevaplayacagi Sorular

Gelecekteki scanner su sorulara cevap verebilmelidir:

- Metadata dosyanin var oldugunu soyluyor mu?
- Dosya gercekten var mi?
- Metadata path standardina uyuyor mu?
- Metadata ayni fiziksel dosyaya birden fazla kez mi isaret ediyor?
- Klasorde metadata karsiligi olmayan orphan dosya var mi?
- Dosya okunabilir mi?
- Dosya yanlis yerde mi?
- Ilgili ana kayitla baglanti kurulabiliyor mu?

## Kontrol Edilecek Durumlar

Ilk scanner kapsami mevcut attachment integrity status hatti ile uyumlu olmalidir.

Kapsanacak durumlar:

- `OK`
- `MISSING_FILE`
- `ORPHAN_FILE`
- `INVALID_PATH`
- `DUPLICATE_METADATA`
- `UNREADABLE_FILE`

Bu liste scanner'in ilk davranis sozlesmesini dar tutar. Yeni durumlar ancak ihtiyac netlesirse ayri adimlarda eklenmelidir.

## Ilk Scanner Kapsami

Ilk gercek scanner minimal ve dry-run calismalidir.

Ilk scanner su sinirlarla tasarlanmalidir:

- metadata kayitlarini girdi olarak alir
- base attachment root path parametresi alir
- dosya sisteminde sadece izin verilen attachment root altinda kontrol yapar
- hicbir dosyayi silmez
- hicbir dosyayi tasimaz
- hicbir klasor olusturmaz
- hicbir metadata kaydini degistirmez
- sadece `AttachmentIntegrityResult` listesi veya `AttachmentIntegrityReport` uretir

## Scope Disi Davranislar

Ilk scanner kapsaminda su davranislar yoktur:

- otomatik duzeltme
- dosya silme
- dosya tasima
- orphan dosya karantinaya alma
- metadata guncelleme
- database update
- upload service entegrasyonu
- backup alma
- restore yapma
- audit event yazma
- AI analizi
- GUI/CLI komutu
- scheduled scan / automation

Bu davranislar erken eklenirse scanner gereksiz risk tasir. Once tespit, raporlama ve test edilebilir dry-run davranisi netlesmelidir.

## Attachment Root ve Path Guvenligi

Scanner hicbir zaman proje disi path'lere kontrolsuz cikmamalidir.

Guvenlik ilkeleri:

- scanner yalnizca acikca verilen attachment root altinda calisir
- root disina cikan relative path kabul edilmez
- absolute path davranisi ayrica tasarlanmadan kabul edilmez
- path normalize etme ve root icinde kalma kontrolu scanner sozlesmesinin parcasi olmalidir
- silme veya tasima gibi duzeltici aksiyonlar scanner'in ilk surumunde yoktur

Path traversal riski ayri ve acik bir tasarim konusu olarak ele alinmalidir.

## Dry-run Ilkesi

Scanner ilk asamada sadece dry-run mantiginda olmalidir.

Dry-run davranisi:

- dosya sistemi ve metadata durumunu okur
- problem varsa raporlar
- dosya, klasor veya metadata uzerinde degisiklik yapmaz
- sonuc nesneleri uretir
- onerilen aksiyonu metinsel ve makine-dostu sekilde belirtir

Dry-run ciktisi ileride audit, backup veya guvenli duzeltme adimlari icin temel veri saglar; ancak bu adimlar ilk scanner kapsaminda uygulanmaz.

## Beklenen Cikti

Dry-run ciktisi su bilgileri tasimalidir:

- bulunan problem
- ilgili metadata id
- ilgili file path
- status
- severity
- recommended_action
- notes
- checked_at

Cikti mevcut `AttachmentIntegrityResult` ve `AttachmentIntegrityReport` hatti ile uyumlu olmalidir. JSON export daha sonra raporun disari alinmasi icin kullanilabilir.

## Gelistirme Sirasi

Onerilen gelistirme sirasi:

1. Scanner input modeli / scope dokumani
2. Dry-run scanner helper
3. Dry-run scanner testleri
4. Report uretimi
5. JSON export ile baglanti
6. Audit event plani
7. Backup / restore plani
8. Guvenli duzeltme aksiyonlari

Otomatik duzeltme, audit ve backup erken implement edilmemelidir. Once scope, dry-run ve raporlama netlesmelidir.

## Bu Adimin Siniri

Bu adim sadece dokumantasyon adimidir.

Bu adimda scanner implementasyonu, dosya sistemi taramasi, klasor traversal, gercek dosya okuma, dosya silme, dosya tasima, upload service, backup/restore, audit event implementasyonu, database, API, GUI, CLI, AI entegrasyonu, automation, refactor, test dosyasi degisikligi veya uygulama kodu degisikligi yapilmadi.

Commit atilmadi, push yapilmadi ve `chief-site-engineer_adim_080_guvenli_nokta.zip` dosyasi stage edilmedi.
