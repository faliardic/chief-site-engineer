# Issue #198 — Kalıcı Mobil Yedek İçe Aktarma

## Problem

Android sistem dosya seçicisinin verdiği `PlatformFile.path`, sağlayıcının geçici
cache kopyasını gösterebilir. Ön kontrol picker çağrısından sonra çalıştığı için
bu yol kaybolabiliyor ve geçerli `.csebackup` paketi `package_not_found` ile
reddediliyordu.

Mobil runtime artık dış sağlayıcının yolunu state olarak saklamaz. Picker
dönerken paket uygulamanın private
`temp_staging/incoming_backups/` alanına tamamen alınır; UI, preflight ve restore
yalnız bu stable kopyanın typed metadata'sını taşır.

## Stable package sözleşmesi

`PickedBackupPackage` şu değişmez alanları taşır:

- app-private stable package path;
- path içermeyen güvenli original file name;
- byte size;
- lowercase SHA-256;
- collision-safe import operation ID.

Ham picker path'i, parola, backup içeriği veya cihaz absolute path'i loglanmaz.
Backup format version `1`, mobil schema `7`, schema `1`–`7` restore uyumluluğu,
process-death journal ve cryptographic doğrulama değişmez.

## Atomik stream import

`file_picker` `withReadStream: true` ile çağrılır. Platform stream sağlanmazsa
picker cache path fallback'i yalnız aynı `pickPackage()` çağrısı içinde açılır.
Akış:

1. `.csebackup` uzantısı ve path/control karakteri içermeyen ad doğrulanır.
2. Incoming root uygulamanın environment-specific support root'u altında açılır.
3. Collision-safe operation ID ile `<id>.part` exclusive oluşturulur.
4. Stream parça parça yazılır ve aynı anda SHA-256 hesaplanır.
5. Kopyalama sırasında `512 MiB` sınırı fail-closed uygulanır.
6. Sink flush/close edilir; final dosya tekrar stream ile size/SHA kontrolünden
   geçer.
7. `.part`, aynı directory içindeki `<id>.csebackup` adına atomik rename edilir.
8. Final dosya tekrar doğrulandıktan sonra typed package döndürülür.

Copy, size, hash veya rename hatası yalnız doğrulanmış incoming root içindeki
exact `.part`/oluşturulmuş final dosyayı temizler. Root dışı, link veya belirsiz
dosya cleanup hedefi olamaz.

## Preflight ve restore

Application service yalnız iki package kaynağını kabul eder:

- exact operation ID ile eşleşen app-private incoming package;
- uygulamanın kendi `exports_backups` kökündeki güvenli internal backup.

Her preflight öncesinde ve her restore öncesinde file type, gerçek resolved root,
boyut ve SHA-256 tekrar kontrol edilir. Preflight sonucu aynı
`PickedBackupPackage` nesnesini taşır; restore ayrıca preflight SHA token'ını
karşılaştırır. Böylece dış provider yolu ve TOCTOU değişimi aktivasyon zincirine
giremez.

Wrong password paketi silmez; kullanıcı aynı stable kopya ile parolayı düzeltip
yeniden deneyebilir. Unsupported schema, corrupt database, foreign-key veya
cryptographic hata da aktif SQLite'ı değiştirmez. Restore başarısızsa stable
paket retry için kalır; başarıdan sonra temizlenir.

## Lifecycle ve bootstrap reconciliation

- Başka paket başarıyla seçilirse önceki stable selection temizlenir.
- Picker cancel mevcut seçimi değiştirmez ve yeni dosya oluşturmaz.
- Ekran kapanırsa terk edilen seçim best-effort temizlenir.
- Restore success incoming paketi temizler; cleanup hatası restore sonucunu
  geri çeviremez ve sonraki bootstrap retry eder.
- Bootstrap, incoming root varsa orphan `.part` dosyalarını ve 24 saati aşmış
  final paketleri temizler.
- Reconciliation yalnız incoming root'un doğrudan, regular-file çocuklarına
  dokunur; unknown ad, symlink, alt directory ve root dışı dosya korunur.

## Güvenli kullanıcı geçiş artifact'ları

Release gate iki ignored Android artifact üretir:

1. `chief-site-engineer-0.1.0-issue198-sidecar-debug.apk` —
   `com.faliardic.chiefsiteengineer.debug`; production RC ile yan yana kurulup
   dışa alınmış pakette yalnız preflight yapmak içindir.
2. `chief-site-engineer-0.1.0-rc-ephemeral.apk` — repository dışında anlık
   oluşturulup gate sonunda silinen test anahtarıyla imzalı production RC.

Sidecar ve RC için ARM64 inventory, 16 KiB alignment, signer ve hash kanıtları
release gate'te üretilir. Sidecar geniş storage/media izni taşıyamaz. Uygulama
kullanıcı adına restore veya uninstall yapmaz; production RC geçiş kararı gerçek
cihaz kabulünde kullanıcıya aittir.

## Korunan sınırlar

- Telefon device-of-truth ve offline-first kalır.
- Broad storage/media veya exact-alarm izni eklenmez.
- Gerçek kullanıcı backup'ı testlerde okunmaz; testler temp sentetik paketlerdir.
- Signing secret repository'ye girmez.
- `reports/`, repository dışı `device-backups/`, ZIP, Flutter build/cache ve
  `exports/.gitkeep` korunur.
- Store submission ve PR oluşturma bu dilimin parçası değildir.
