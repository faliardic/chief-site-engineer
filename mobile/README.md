# CSE mobil uygulama temeli

Bu klasör Chief Site Engineer 0.1.0 için tek Dart codebase kullanan Flutter
Android/iOS uygulamasıdır. Mobil runtime Python/Flask sunucusuna bağlanmaz;
cihaz-içi SQLite ve uygulamaya özel yerel dosya dizinleriyle offline çalışır.

## Sabit kimlikler

| Alan | Değer |
| --- | --- |
| Flutter proje adı | `chief_site_engineer` |
| Uygulama adı | `Chief Site Engineer` |
| Sürüm/build | `0.1.0+1` |
| Android release application ID | `com.faliardic.chiefsiteengineer` |
| Android debug application ID | `com.faliardic.chiefsiteengineer.debug` |
| iOS release bundle ID | `com.faliardic.chiefsiteengineer` |
| iOS debug bundle ID | `com.faliardic.chiefsiteengineer.debug` |
| Mobil schema version | `5` |
| Sunum timezone | `Europe/Istanbul` |

Debug ve release farklı platform kimlikleri ve farklı `debug` / `release` veri
kökleri kullanır. Böylece geliştirme kaydı yayın verisine karışmaz.

## Yerel veri dizinleri

Platformun application-support dizini altında şu uygulama içi yapı kurulur:

```text
cse_mobile/<debug|release>/
├── database/cse_mobile.sqlite3
├── attachments/
├── exports_backups/
└── temp_staging/
```

Bütün child yollar ortak environment kökü altında doğrulanır. Relative path ve
root dışına kaçış fail-closed reddedilir. Repository `exports/` klasörü mobil
runtime tarafından kullanılmaz.

## SQLite bootstrap ve Ajanda migration'ı

İlk açılışta tek transaction içinde:

1. `schema_versions` tablosu oluşturulur.
2. `smoke_records` tablosu oluşturulur.
3. Migration sürümü ve canonical UTC uygulama zamanı yazılır.
4. SQLite `user_version` aynı sürüme alınır.

Herhangi bir adım başarısız olursa transaction rollback olur. Bootstrap hata
detayını veya path'i kullanıcıya sızdırmaz ve kayıt yazıldığı iddiasında
bulunmaz. Başarılı açılışta `mobile-foundation-v1` smoke kaydı bir kez eklenir;
restart aynı `created_at` değerini okur.

Schema `2`, schema `1` verisini koruyan tek atomik migration ile şunları ekler:

- `projects`;
- günlük log source-of-truth'u `field_observations`;
- append-only `observation_events`;
- loga project + observation foreign key'iyle bağlı `follow_up_items`;
- append-only `follow_up_events`.

Event tabloları update/delete trigger'larıyla salt eklemelidir. Project, log ve
reminder fiziksel silinemez. Log/reminder kayıtlarında UUID, revision,
`created_at`, `updated_at` ve gelecekte archive/lifecycle uyumlu alanlar bulunur.
Migration veya transaction hatasında yarım tablo, reminder veya event kalmaz.

Schema `3`, schema `2` Ajanda logları, linked reminder'lar ve event geçmişini
koruyan atomik table rebuild ile reminder aggregate'ini tam yaşam döngüsüne
genişletir. `follow_up_events.sequence` aggregate içi kesin sırayı verir.
`reminder_notification_bindings`, collision-safe platform integer ID ile safe
operational sync state tutar. v3 migration'ın herhangi bir adımı hata verirse
schema ve veri v2 olarak eksiksiz rollback olur.

Schema `4`, schema `3` Ajanda, reminder, append-only event ve notification
binding verilerini koruyan atomik migration ile proje personeli, günlük Puantaj
aggregate'i, entry/event tabloları, reminder setting ve exact day/reminder link
tablolarını ekler. Personel ve Puantaj kayıtlarında physical delete yoktur;
completed/no-work gün explicit reopen olmadan düzenlenemez.

Schema `5`, schema `4` Ajanda, reminder, notification, Puantaj ve event
kayıtlarını koruyan atomik migration ile Beton döküm paketi, on bir built-in
kontrol, mikser/irsaliye, numune, takip, kanıt ve append-only event tablolarını
ekler. Beton kaynağı taşıyan reminder aynı anda observation veya Puantaj kaynağı
taşıyamaz; project composite foreign key ile eşleşir.

## Mobil Ajanda ve Hatırlatıcı

Ajanda, seçili `Europe/Istanbul` gününü `observed_at`, `created_at`, ID sırasıyla
gösterir. Bugün/önceki/sonraki/tarih seçimi; proje/tür filtresi ve wildcard
yorumlamayan literal arama vardır. Log formu geçmiş zamanı kabul eder, gelecek
ve invalid zamanı mutation öncesi reddeder; hata halinde form state'i korunur.

Her kart ve log detayından reminder oluşturulabilir. Önerilen metin açıklamadan
gelir ve değiştirilebilir. `action | waiting | recheck`; 15 dakika, 1 saat,
bugün çıkmadan, yarın sabah, Unutma Kutusu ve özel tarih/saat desteklenir.
Linked reminder ilk insert'ten itibaren source log ve project ID taşır;
standalone reminder ise project/source olmadan oluşturulabilir. Creation ve her
lifecycle mutation row + append-only event'i tek transaction'da yazar.

Hatırlatıcı ekranı `+ Unutma`, Şimdi ilgilen, Gecikenler, Bugün, Bekliyorum,
Tekrar kontrol, Yaklaşanlar, Unutma Kutusu ve terminal geçmişi sunar. Detay
ekranı update, schedule/reschedule, üç snooze, waiting, inbox, complete/cancel
outcome ve reopen işlemleriyle revision conflict'i görünür kılar.

## Yerel bildirimler

`flutter_local_notifications` Android/iOS adapter'ı canonical UTC reminder
anını `Europe/Istanbul` timezone-aware schedule'a çevirir. Android
`inexactAllowWhileIdle` kullanır; exact-alarm izinleri manifest'te yoktur.
Notification payload reminder UUID'sini taşır ve tap/cold launch ilgili detayı
açar.

Permission reddi veya plugin hatası SQLite reminder'ını geri almaz. Safe sync
state detay ekranında görünür. Bootstrap reconciliation SQLite source-of-truth
ile OS pending listesini uzlaştırır: eksikleri kurar, stale/duplicate/orphan ve
terminal/inbox pending kayıtlarını iptal eder. Platform kapasitesini aşan uzak
reminder kaybolmaz; `platform_capacity` state'iyle uygulamada kalır.

## Mobil Puantaj

Puantaj ekranı proje ve İstanbul yerel tarihiyle çalışır. Personel; ad, ekip/
taşeron, rol ve optional proje-içi unique kodla eklenir, düzenlenir veya
pasifleştirilir. Günlük sonuçlar tam gün, yarım gün, gelmedi ve izinlidir; tam/
yarım gün için fazla mesai dakikası ve her satır için kısa not girilebilir.

Gün taslak, tamamlandı veya çalışma yok durumundadır. Geçmiş bir gün yalnız
explicit reopen sonrasında düzeltilir. Bütün değişiklikler expected revision ve
append-only event geçmişi kullanır. Günlük/ekip toplamları, kişi-gün ve fazla
mesai entry'lerden türetilir.

Proje bazlı Puantaj reminder ayarı seçili çalışma günlerini ve İstanbul yerel
saatini tutar. Önümüzdeki 14 gün idempotent ensure edilir. Reminder ilk andan
itibaren exact Puantaj günü/proje linkini taşır; gün tamamlanınca veya çalışma
yok olunca kapanır, reopen sonrasında aynı due anıyla yeniden etkinleşir.
Reminder detayından kaynak Puantaj gününe dönülebilir.

Gün CSV'si UTF-8 BOM, CRLF, deterministic sıra ve formula injection koruması
kullanır. Uygulama içi staging atomiktir; başarısızlık yarım dosya veya yanlış
success event'i bırakmaz. Günün insan-okunabilir özeti panoya kopyalanabilir;
CSV platform share sheet ile paylaşılabilir.

## Mobil Beton Paketi

Beton Paketi ekranı Bugün, Yaklaşan, Devam Eden, Takipte ve Kapalı gruplarını;
proje/tarih/literal filtreleri ve açık checklist/kanıt/takip sayaçlarıyla gösterir.
Oluşturma komutu proje, mahal, İstanbul yerel zamanı, beton sınıfı ve pozitif
plan metrajını doğrular; sabit UUID retry ve çift dokunma kilidi kullanır.

Döküm detayında on bir hazırlık kontrolü, hazır/başlat/bitir/takibe al/kapat/
iptal/reopen geçişleri, mikser ve irsaliye zamanları, received/held/returned/
partial sonuçları, türetilen gerçek metraj, numune setleri ve linked reminder'lar
aynı aggregate revision sınırındadır. Required pending kontrol, eksik truck
kanıtı, açık numune/takip veya açıklamasız metraj farkı kapanışı fail-closed
engeller; uygulama kullanıcı yerine beton kabul/red kararı üretmez.

Kamera, galeri ve dosya seçici `SafeAttachmentPicker` arkasındadır. JPEG, PNG,
HEIC ve PDF içerikten MIME sniff edilir; 20 MiB sınırı, SHA-256, staging → atomic
finalize, package-relative path, duplicate hash uyarısı ve DB failure orphan
cleanup uygulanır. Permission/plugin failure Beton kaydını silmez; eksik kanıt
görünür kalır. Reminder ve notification source-of-truth'u SQLite'tır.

Paket raporu UTF-8 BOM'lu insan-okunabilir Markdown, CSV/JSON-ready özet,
formula injection koruması ve relative attachment manifest/hash bilgisi taşır.
Dosya atomik stage edilir; `report.exported` event'i yalnız başarıdan sonra
yazılır ve paylaşım kullanıcı işlemiyle başlar.

## Mobil Hafıza ve Yedekleme

Başlangıç ekranındaki Hafıza ve Yedekleme yüzeyi, bütün mobil SQLite kayıtlarını
ve aktif Beton kanıtlarını tek `.csebackup` format `1` paketinde taşır. Paket
PBKDF2-HMAC-SHA256 ile paroladan türetilen 256-bit anahtar ve AES-256-GCM ile
authenticated şifrelenir. Random salt/nonce paket başlığındadır; parola, absolute
path, kullanıcı secret'ı veya signing materyali manifest/state içine yazılmaz.

Backup; tek shared application coordinator altında SQLite `VACUUM INTO`
snapshot, integrity/FK/read-model smoke ve attachment size/SHA-256 audit'i
uygular. Staging `.part` yalnız self-check başarılıysa backup dizinine atomik
rename edilir. Share sheet yalnız kullanıcı düğmesiyle açılır.

Restore preflight aktif state'e dokunmadan magic/format/KDF/schema/parola,
manifest hash/size, package/entry boyut sınırı, traversal, absolute/backslash,
duplicate, symlink/directory/extra entry, SQLite integrity/FK ve DB row ↔
attachment manifest eşliğini doğrular. Desteklenen eski mobil schema yalnız
staging'de güncel schema'ya migrate edilir; downgrade yoktur.

Kullanıcı checkbox ve ayrı modal ile tam replace'i iki kez onaylar. Service önce
otomatik safety backup alır, database ve attachments çiftini rollback alanına
taşır, incoming çifti etkinleştirir, smoke/hash kontrolü ve notification
reconciliation çalıştırır. Her hata eski çifti geri getirir; merge/partial
restore veya OS pending notification backup'ı yoktur.

## Zaman sözleşmesi

- Kalıcı an: aware UTC, exact `YYYY-MM-DDTHH:MM:SSZ`.
- Precision: seconds; microsecond yeni mobile storage değeri değildir.
- Kullanıcı sunumu: `Europe/Istanbul`.
- Naive, invalid veya canonical olmayan read değeri reddedilir.
- Explicit offset girdisi önce UTC'ye normalize edilebilir.
- Datetime-local girdisi yalnız açık İstanbul wall-clock decoder'ıyla canonical
  UTC'ye çevrilir; storage katmanı naive değeri kabul etmez.

Python fixture eşliği:

```text
2026-07-12T21:30:00+03:00
-> 2026-07-12T18:30:00Z
-> 12.07.2026 21:30:00 Europe/Istanbul
```

## Geliştirici komutları

Flutter `3.44.6 stable` ve Dart `3.12.2` ile doğrulanmıştır:

```powershell
cd mobile
flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Android emülatör integration smoke testi:

```powershell
flutter test integration_test/app_smoke_test.dart -d <android-device-id>
```

## iOS sınırı

Tracked iOS project, scheme, `Info.plist`, iOS 13 deployment target, bundle
kimlikleri, sürüm/build değişkenleri ve camera/photo açıklamaları mevcuttur.
Native iOS archive/TestFlight/App Store build'i yalnız macOS + Xcode üzerinde
çalışır. Gerçek signing için ayrıca Apple Developer hesabı, takım seçimi ve
repository dışında tutulan provisioning/certificate gerekir.

## Secret ve signing

- Keystore, signing key, provisioning profile ve certificate commitlenmez.
- Android release build'e debug signing bağlanmaz.
- Üretilen release AAB doğrulamada unsigned'dır; mağaza signing ayrı release
  hardening adımında güvenli dış konfigürasyonla sağlanır.
- Build çıktıları ve yerel Flutter/Gradle cache'leri ignored kalır.

## Bilinçli olarak eklenmeyenler

- Cloud backend veya sync
- Kullanıcı hesabı/auth server
- Masaüstü verisinin otomatik migration'ı
- Ajanda loguna genel attachment/fotoğraf bağlama
- Ücret/bordro/SGK/hakediş
- Genel PackageTemplate motoru veya otomatik beton kabul/red
- Recurring reminder/routine template
- Store submission
- Exact-alarm permission, push/server notification
