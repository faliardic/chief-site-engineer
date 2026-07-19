# Issue #189 — Release 0.1 Mobil Tam Yedek ve Geri Yükleme

## Amaç ve sınır

Bu dilim, telefondaki bütün mobil SQLite kayıtlarını ve aktif Beton kanıt
dosyalarını tek parola korumalı `.csebackup` paketine alır. Geri yükleme merge
yapmaz; mevcut mobil hafızayı doğrulanmış paketle tamamen değiştirir. Telefon
device-of-truth, SQLite business source-of-truth olmaya devam eder.

Cloud, Google Drive/iCloud entegrasyonu, masaüstü backup import'u, zamanlanmış
otomatik yedek, mağaza release hardening ve store submission bu kapsamda
değildir. Kullanıcı parolası, absolute cihaz yolu, signing materyali veya secret
manifestte, state özetinde, event'te ya da logda tutulmaz.

## `.csebackup` formatı v1

Paket iki katmandır:

```text
CSEBKP1\n + sınırlı JSON şifreleme başlığı
  └─ PBKDF2-HMAC-SHA256 ile türetilen 256-bit anahtar
     └─ AES-256-GCM authenticated ciphertext
        └─ ZIP
           ├─ manifest.json
           ├─ database.sqlite3
           └─ attachments/<package-relative-path>
```

Şifreleme başlığı format, cipher, KDF, iteration, random salt, nonce ve payload
boyutunu taşır. Başlık AES-GCM additional authenticated data içine dahil edilir;
bu nedenle başlık veya ciphertext değişikliği aynı güvenli
`wrong_password_or_tampered` sonucu verir. Production iteration değeri
`210000`'dir. Parola en az 8, en fazla 256 karakterdir ve yalnız işlem belleğinde
kalır.

Manifest şu alanları taşır:

- backup format sürümü, uygulama sürümü/build numarası ve mobil schema sürümü;
- canonical UTC seconds oluşturma zamanı;
- SQLite logical adı, byte boyutu ve SHA-256 değeri;
- her aktif attachment için POSIX-relative logical path, byte boyutu ve SHA-256.

OS pending notification listesi pakete girmez. SQLite'taki reminder ve binding
kayıtları source-of-truth olarak yedeklenir; restore aktivasyonundan sonra
platform pending listesi yeniden uzlaştırılır.

## Uygulama genelinde işlem koordinasyonu

Bootstrap tek bir `MobileOperationCoordinator` örneğini Ajanda/Reminder,
Puantaj, Beton ve backup/restore application service'lerine verir. Her işlem
aynı seri kuyruğa girer. Backup kendisinden önce başlamış mutation'ı bekler;
backup sürerken gönderilen yeni mutation snapshot tamamlanana kadar başlamaz.

Beton kanıt ekleme özel olarak validation → fiziksel staging/finalize → SQLite
row/event akışının tamamını bu kilitte tutar. Böylece backup, dosyanın hazır
olduğu fakat row'un henüz yazılmadığı çok-adımlı mutation'ın ortasına giremez.
Başarısız bir kuyruk işi sonraki işleri zehirlemez.

## Backup oluşturma akışı

1. Parola ve doğrulaması mutation başlamadan kontrol edilir.
2. Ortak exclusive coordinator alınır ve uygulama dizin sözleşmesi doğrulanır.
3. Aktif SQLite üzerinde `integrity_check` ve `foreign_key_check` çalışır.
4. Aktif Beton attachment row'ları deterministic relative path sırasıyla okunur.
5. SQLite `VACUUM INTO` ile staging altında tutarlı snapshot üretir.
6. Her attachment'ın varlığı, boyutu ve SHA-256 değeri row ile eşleştirilir.
7. Manifest ve ZIP üretilir, AES-GCM ile şifrelenir.
8. Üretilen paket yeniden decrypt/decode/hash doğrulamasından geçirilir.
9. `.part` dosyası uygulama backup dizinine atomik rename edilir.
10. Yalnız dosya adı ve sayısal özetler state dosyasına atomik yazılır.

Her hata staging'i ve partial çıktıyı temizler. Aktif attachment eksik veya
değişmişse backup başarı sayılmaz. Share sheet yalnız kullanıcının açık
`Yedeği paylaş / kaydet` işlemiyle açılır.

## Salt-okunur preflight

Restore'dan önce paket aktif veriye dokunmadan staging'e hazırlanır:

- magic/header/format/KDF sınırı ve authenticated parola doğrulanır;
- package, entry ve expanded byte üst sınırları uygulanır;
- malformed, absolute, drive-qualified, backslash, `.`/`..`, traversal,
  symbolic/directory, duplicate ve manifest dışı ZIP entry reddedilir;
- raw ZIP central directory ayrıca okunur; kütüphane görünümünde tekilleşebilen
  duplicate adlar da fail-closed yakalanır;
- manifest boyut/hash değerleri gerçek byte'larla eşleştirilir;
- gelecekteki schema downgrade reddedilir;
- desteklenen eski schema staging SQLite üzerinde güncel schema'ya migrate olur;
- SQLite integrity/FK, smoke/read-model ve DB attachment row ↔ manifest ↔ dosya
  üçlü eşliği doğrulanır.

Başarılı preflight paket SHA-256 token'ı verir. Restore paketi yeniden okur ve bu
token'la eşleştirir; dosya iki adım arasında değişmişse aktif mutation başlamaz.

## Atomik restore ve rollback

Kullanıcı önce “mevcut mobil hafıza tamamen değişecek” kutusunu işaretler,
sonra ayrı modalda ikinci kez `Tamamen değiştir` der. Service şu sırayı izler:

1. Paket yeniden tam preflight'tan geçer.
2. Mevcut aktif durum aynı parola ile `safety_before_restore_*.csebackup`
   güvenlik yedeğine alınır.
3. Incoming SQLite ve attachments staging'de hazır tutulur.
4. Aktif SQLite ve attachments rollback alanına atomik rename edilir.
5. Incoming çift aktif konuma rename edilir.
6. Schema/integrity/FK/smoke/read-model/attachment kontrolleri tekrarlanır.
7. SQLite source-of-truth'tan pending notification reconciliation çalışır.
8. Bütün kapılar geçerse eski rollback alanı temizlenir; safety backup korunur.

Swap, smoke, attachment veya notification uzlaştırma adımlarından biri hata
verirse yeni çift ayrı alana çekilir ve eski database + attachments birlikte geri
getirilir. Rollback doğrulaması da başarısız olursa safety backup ve rollback
alanı korunur; sessiz partial başarı verilmez. Merge veya tablo bazlı kısmi
restore yoktur.

## Mobil yüzey

Başlangıç ekranındaki `Hafıza ve Yedekleme` kartı şu akışları sunar:

- parola + parola doğrulamasıyla tam yedek oluşturma;
- başarıdan sonra kullanıcı kontrollü paylaş/kaydet;
- son başarılı yedeğin UTC zamanı, paket boyutu, attachment sayısı ve schema'sı;
- `.csebackup` seçme, parola girme ve salt-okunur ön kontrol;
- oluşturma zamanı, attachment sayısı, boyut ve migrate edilecek schema özeti;
- checkbox + ikinci modal ile iki aşamalı tam değiştirme onayı;
- güvenli başarı/hata sonucu.

Butonlar en az 48 px'tir; 320 px yüzey kaydırılabilir. Busy state çift dokunmayı
engeller. Validation hatası parola/form girdisini korur; başarılı işlem parola
controller'larını temizler. Absolute dosya yolu kullanıcıya gösterilmez.

## Doğrulama kapsamı

- boş ve Ajanda/reminder/notification/Puantaj/Beton/event/attachment dolu fixture;
- exact row, append-only geçmiş, source link ve binary byte/hash round-trip;
- restart kalıcılığı ve schema 4 paketinin staging'de schema 5'e migration'ı;
- gerçek Ajanda mutation'ıyla backup exclusive yarış testi;
- yanlış parola, authenticated tamper, preflight sonrası paket değişimi;
- traversal, absolute, backslash, duplicate, extra, oversized entry/paket;
- manifest hash, duplicate logical attachment, bozuk SQLite ve FK ihlali;
- eksik aktif attachment'ta partial çıktı bırakmama;
- swap ve notification reconciliation failure rollback enjeksiyonları;
- bildirim uzlaştırmasının restore sonrası tek kez çalışması;
- 320 px input preservation, double tap ve iki aşamalı confirmation widget testi;
- Android emülatörde gerçek plugin/SQLite/dosya backup→restore→restart akışı;
- mevcut Flutter/Python regresyonları, Android APK/AAB ve iOS statik kapıları.

Mobil schema `5`, Python schema `4`, masaüstü Backup format `1`, restore
allowlist `(2, 3, 4)` ve Günlük Çıktı format `1` değiştirilmemiştir.
