# CSE mobil uygulaması

`mobile/`, Chief Site Engineer `0.1.0+1` için tek Dart codebase kullanan
Flutter Android/iOS uygulamasıdır. Runtime Python/Flask sunucusuna bağlanmaz;
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
| Mobil schema version | `10` |
| Backup format version | `1` |
| Canonical timezone | `Europe/Istanbul` |
| Android compile/target SDK | `36 / 36` |

Debug ve release farklı platform kimlikleri ve `debug` / `release` veri
kökleri kullanır; geliştirme kaydı yayın verisine karışmaz.

## Yerel veri düzeni

Platform application-support dizini altında:

```text
cse_mobile/<debug|release>/
├── database/cse_mobile.sqlite3
├── attachments/
├── exports_backups/
├── temp_staging/
└── restore_journal.json  # yalnız yarım restore varken
```

Child yollar environment kökü altında doğrulanır. Relative traversal, absolute
kullanıcı yolu ve kök dışına kaçış fail-closed reddedilir. Repository
`exports/` klasörü mobil runtime tarafından kullanılmaz.

Kalıcı anlar aware UTC exact `YYYY-MM-DDTHH:MM:SSZ` biçimindedir. Kullanıcı
gün/saat sunumu ve local-date kararları `Europe/Istanbul` kullanır. Naive,
invalid veya canonical olmayan storage değeri reddedilir.

## SQLite schema geçmişi

Bütün migration'lar atomiktir; hata yarım tablo veya yarım event bırakmadan
rollback olur.

| Schema | Birleşmiş veri sözleşmesi |
| --- | --- |
| `1` | Bootstrap, schema kaydı ve `mobile-foundation-v1` smoke kaydı |
| `2` | Projects, Ajanda observations, append-only observation events, linked follow-up/reminder ve events |
| `3` | Tam reminder lifecycle, aggregate event sequence ve notification bindings |
| `4` | Proje personeli, Puantaj gün/entry/event, çalışma günü ayarı ve exact day/reminder bağları |
| `5` | Beton paketi, built-in checklist, mikser/irsaliye, numune, takip, kanıt ve append-only events |
| `6` | Taşeronlar, iş gücü ekipleri, workforce events ve deterministic legacy workforce normalizasyonu |
| `7` | Ajanda fotoğraf attachments; source photo/PDF akışları ve nullable irsaliye için Beton truck graph rebuild |
| `8` | Reminder aggregate rebuild; all-day local date, sade lifecycle vocabulary ve source constraints |
| `9` | Reminder `trashed_at`, çöp/geri yükleme event vocabulary'si ve index |
| `10` | Proje Beton sınıfı kataloğu, append-only class events, paket–Ajanda bağlamı ve deterministic legacy class migration |

Physical delete ana aggregate'lerde kullanılmaz. Event tabloları append-only,
mutation'lar expected revision ve idempotent event ID kullanır. Schema `10`
restore hedefidir; desteklenen eski backup schema'ları yalnız staging'de
güncele migrate edilir, downgrade yapılmaz.

## Ajanda

Ajanda seçili İstanbul gününü gösterir; proje, tür, aktif/arşiv ve wildcard
yorumlamayan literal arama filtreleri vardır. Sıralama typed application query
ile `observed_at`, `created_at`, `id` alanlarında deterministik en yeni veya en
eski üstte çalışır; `updated_at` sıralamaya katılmaz.

Route-local gün, filtre, arama ve scroll bağlamı detail push/pop sonrasında
korunur. Arama metni ile focus/caret/IME ayrı sözleşmedir: detail dönüşü
klavyeyi kendiliğinden açmaz, gerçek drag klavyeyi kapatır ve odaksız scroll
arama focus'u üretmez.

Ajanda kaydına JPEG/PNG/HEIC/PDF kanıt eklenebilir. MIME içerikten sniff edilir;
boyut, SHA-256, atomik staging/finalize ve DB failure orphan cleanup uygulanır.
Beton/betonaj sinyali yalnız kullanıcıya öneri verir; otomatik saha kararı,
paket veya reminder üretmez.

## Hatırlatıcı

Reminder; bağımsız veya Ajanda, Puantaj ve Beton kaynaklı olabilir. Creation ve
her lifecycle mutation row ile append-only event'i tek transaction'da yazar.
Schedule/reschedule, waiting, inbox, complete/cancel, reopen, trash/restore ve
revision conflict görünümü desteklenir.

Hızlı eylemler arasında:

- 15 dakika ve 1 saat;
- 2 saat ve 3 saat;
- bugün çıkmadan;
- `Yarına ertele`;
- timed `Yarın 08:00`;
- sonraki pazartesi `08:00`;
- özel tarih/saat ve Unutma Kutusu

bulunur. Ertesi gün ve hafta başı değerleri exact Europe/Istanbul wall-clock
resolver ile üretilir. UI preview ile application sonucu gün sınırında
uyuşmazsa mutation fail-closed reddedilir. All-day local date ayrı korunur.

Kaynak Ajanda fotoğrafları reminder detayında salt-okunur gösterilir. Byte ve
metadata reminder aggregate'ine kopyalanmaz; mevcut attachment integrity yolu
kullanılır.

## Yerel bildirimler

`flutter_local_notifications`, canonical UTC reminder anını timezone-aware
native schedule'a çevirir. Android manifestte:

- `POST_NOTIFICATIONS`;
- `RECEIVE_BOOT_COMPLETED`;
- kullanıcıya görünür reminder alarmı için `SCHEDULE_EXACT_ALARM`;
- kanıt çekimi için `CAMERA`

bulunur. Android 12+ exact alarm özel erişimi yalnız explicit reminder
eyleminden istenir. İzin reddi veya plugin hatası SQLite reminder'ını geri
almaz; sync state kullanıcıya görünür.

Broad media/storage ve `INTERNET` izinleri final manifestten çıkarılır;
cleartext kapalıdır. Notification payload reminder UUID'sini taşır. Bootstrap
reconciliation SQLite source-of-truth ile OS pending listesini uzlaştırır;
schedulable, korunacak delivered one-time, terminal, stale, duplicate ve orphan
durumlarını ayırır. Bir reminder mutation'ı ilgisiz reminder bildirimini
silmez.

## Puantaj

Puantaj proje ve İstanbul yerel günüyle çalışır. Personel, ekip/taşeron, rol ve
optional proje-içi kodla yönetilir. Tam gün, yarım gün, gelmedi, izin, fazla
mesai ve not tutulur.

Gün taslak, tamamlandı veya çalışma yok durumundadır. Geçmiş gün yalnız
explicit reopen ile düzeltilir. Gün/ekip toplamları entry'lerden türetilir.
Çalışma günü reminder'ı exact proje/gün bağını taşır. Gün CSV'si UTF-8 BOM,
CRLF, deterministic sıra ve formula-injection korumasıyla atomik hazırlanır.

## Beton paketi

Proje bazlı sınıf kataloğu aktif seçimleri ve tarihsel paket snapshot'larını
ayırır. Paket proje, mahal, İstanbul zamanı, sınıf ve pozitif plan metrajını
doğrular.

Detayda:

- Planlandı → Devam ediyor → Tamamlandı zaman çizgisi;
- required checklist ve system-owned laboratuvar/yapı denetim kalemleri;
- mikser/irsaliye, received/held/returned/partial sonuçları;
- türetilen gerçek metraj, numune, takip ve linked reminder'lar;
- kanıt ve rapor/export

bulunur. Required pending kalem, eksik truck kanıtı, açık numune/takip veya
açıklamasız metraj farkı kapanışı engeller. Uygulama kullanıcı yerine beton
kabul/red kararı üretmez.

İlk başarılı döküm başlangıcı Beton event'i ve yönetilen Ajanda kaydını aynı
transaction'da oluşturur; bitiş aynı kaydı günceller. Yönetilen Ajanda kaydı
bağımsız ana metin edit/archive mutation'ını reddeder ve kaynak Beton paketine
döner.

## Backup ve restore

`.csebackup` format `1`, mobil SQLite ile aktif kanıtları tek şifreli pakette
taşır. PBKDF2-HMAC-SHA256 ile 256-bit anahtar türetilir; AES-256-GCM
authenticated encryption kullanılır. Parola, absolute path, secret ve signing
materyali manifest/state içine yazılmaz.

Backup; SQLite `VACUUM INTO`, integrity/FK/read-model smoke, attachment
size/hash audit ve atomik rename uygular. Restore, aktif state'e dokunmadan
magic/format/KDF/schema/parola, traversal, duplicate, symlink, extra entry,
boyut/hash, SQLite integrity/FK ve DB row–attachment eşliğini doğrular.

Tam replace iki ayrı kullanıcı onayı ister. Önce safety backup alınır; database
ve attachments çifti rollback alanına taşınır. Journal
`prepared → old_state_moved → new_state_activated → validated` aşamalarını
bootstrap recovery için tutar. Belirsiz durumda normal mutation açılmaz ve
kanıt recovery dizini silinmez.

## Güncel kabul sınırı

Son merged safe point Issue #277 / PR #278 /
`c72f6bc55fc658996a546d9833b85a2614b99327`dir. Bu revision için:

- focused lifecycle `48/48`;
- focused widget `46/46`;
- Beton regression `1/1`;
- full Flutter `333/333`;
- analyze `0`;
- Samsung `SM-X610` tablet wide smoke PASS

kanıtı vardır. Kullanıcı tablet PASS'i bu dar Issue'nun fiziksel tamamlanma
kapısı seçti; telefon promotion yapılmadı. Bu sonuç field-ready,
production-ready veya store release kanıtı değildir.

Issue #279 duraklatılmış ve birleşmemiştir. PR #259 açık, Draft ve conflicting
acceptance altyapısıdır; ikisi de bu README'deki birleşmiş mobil capability
olarak yorumlanmamalıdır.

## Geliştirici komutları

Flutter `3.44.6 stable` ve Dart `3.12.2` ile son safe point doğrulanmıştır:

```powershell
cd mobile
flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Current Issue yalnız değişen sözleşmeyle orantılı kapıları çalıştırır; her dar
değişiklik full release/device zincirini tekrar etmez.

## Signing ve platform sınırı

Release build debug signing kullanmaz. Gerçek Android signing yalnız
repository dışındaki `CSE_KEY_PROPERTIES_FILE` ile açılır; eksik alan
fail-closed durur. Keystore, certificate, provisioning profile ve secret
commitlenmez.

iOS project/scheme tracked durumdadır. Gerçek archive/TestFlight yalnız macOS,
Xcode, Apple Developer hesabı ve repository dışı signing materyaliyle
üretilebilir.

Ayrıntılar:
[`docs/release/mobile_identity_signing_and_rc.md`](../docs/release/mobile_identity_signing_and_rc.md).
