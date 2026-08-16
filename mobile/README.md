# CSE mobil uygulaması

`mobile/`, Chief Site Engineer'ın Flutter Android/iOS ürünüdür. Uygulama
offline-first çalışır; cihaz-içi SQLite ve uygulamaya özel yerel dosya alanını
kullanır. Mobil runtime Python/Flask sunucusuna bağlanmaz.

## Güncel durum

| Alan | Değer |
| --- | --- |
| Ürün fazı | V1 tamamlandı; V2 Items 1–4 complete; Living Plan Item 5 current |
| V1 baseline | `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc` |
| Son baseline PR | `#382` |
| Güncel güvenli merge | `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd` |
| Son schedule foundation PR | `#459` |
| Flutter proje adı | `chief_site_engineer` |
| Uygulama sürümü | `0.1.0+1` |
| Android release ID | `com.faliardic.chiefsiteengineer` |
| Android debug ID | `com.faliardic.chiefsiteengineer.debug` |
| iOS release ID | `com.faliardic.chiefsiteengineer` |
| iOS debug ID | `com.faliardic.chiefsiteengineer.debug` |
| Mobil schema | `14` |
| Backup formatı | `1` |
| Canonical timezone | `Europe/Istanbul` |
| Android compile/target SDK | `36 / 36` |
| Owner saha kullanımı | Yaklaşık bir ay |
| Store release | İlan edilmedi |

V1'in tamamlanması mobil modüllerin dondurulduğu anlamına gelmez. V2 aynı
uygulama ve veri omurgası üzerinde ilerler.

## Yerel veri düzeni

Platform application-support dizini altında:

```text
cse_mobile/<debug|release>/
├── database/cse_mobile.sqlite3
├── attachments/
├── exports_backups/
├── temp_staging/
└── restore_journal.json
```

Debug ve release farklı uygulama kimlikleri ve veri kökleri kullanır. Child
yollar environment kökü altında doğrulanır; relative traversal, absolute
kullanıcı yolu ve kök dışına kaçış fail-closed reddedilir.

Kalıcı anlar aware UTC `YYYY-MM-DDTHH:MM:SSZ` biçimindedir. Kullanıcı gün/saat
sunumu ve local-date kararları `Europe/Istanbul` kullanır.

## SQLite schema geçmişi

| Schema | Birleşmiş veri sözleşmesi |
| --- | --- |
| `1` | Mobil bootstrap |
| `2` | Projects, Ajanda, observation events ve linked reminder |
| `3` | Reminder lifecycle ve notification bindings |
| `4` | Puantaj gün/entry/event ve çalışma günü bağları |
| `5` | Beton paketi, checklist, mikser/irsaliye, numune ve kanıt |
| `6` | Taşeronlar, ekipler, workforce events ve legacy normalizasyon |
| `7` | Ajanda attachments ve Beton truck graph rebuild |
| `8` | All-day reminder, sade lifecycle vocabulary ve source constraints |
| `9` | Reminder çöp/geri yükleme yaşam döngüsü |
| `10` | Proje Beton sınıfı kataloğu ve paket–Ajanda bağı |
| `11` | Stable Proje/Mahal kimliği ve adoption migration'ları |
| `12` | Canonical sicil/kişi/firma kimlik grafiği |
| `13` | Ortak managed attachment ve entity-link omurgası |
| `14` | Immutable persistent reference-schedule snapshots ve window-read bütünlüğü |

Migration'lar atomiktir. Hata yarım tablo veya yarım event bırakmadan rollback
olur. Physical delete ana aggregate'lerde kullanılmaz; event tabloları
append-only, mutation'lar expected revision ve idempotent event ID kullanır.

## Ajanda

- Seçili İstanbul günü
- Proje, tür, aktif/arşiv ve literal arama
- `observed_at`, `created_at`, `id` ile deterministik sıra
- Route-local gün, filtre, arama, focus ve scroll korunumu
- JPEG/PNG/HEIC/PDF attachment
- MIME sniff, boyut, SHA-256, atomik staging/finalize
- Beton/betonaj sinyali için kullanıcı kontrollü öneri
- Salt-okunur alan değişikliği geçmişi

## Hatırlatıcı

- Standalone veya Ajanda, Puantaj ve Beton kaynaklı kayıt
- Schedule/reschedule, inbox, complete/cancel, reopen, trash/restore
- Saatli ve tam gün planlama
- Hızlı bugün/yarın/iki-üç saat/hafta başı eylemleri
- Canonical UTC ve Europe/Istanbul wall-clock resolver
- Append-only event ve optimistic revision
- Native notification binding/reconciliation
- Kaynak Ajanda fotoğraflarının salt-okunur görünümü

## Puantaj ve Sicil

- Proje, taşeron, ekip ve personel
- Tam gün, yarım gün, gelmedi, izin, fazla mesai ve not
- Taslak, tamamlandı, çalışma yok ve explicit reopen
- Gün/ekip toplamları
- UTF-8 BOM ve formula-injection korumalı CSV
- Kaynağa bağlı çalışma günü reminder'ı

V2 içinde aynı kişi ve firma kimlikleri ortak Saha Rehberi omurgasına
taşınmıştır. Items 1–4 complete'tir; geçmiş Puantaj ve Sicil bağları canonical
kimliklerle korunur.

## Beton paketi

- Proje bazlı sınıf kataloğu
- Planlandı → Devam ediyor → Tamamlandı
- Required checklist ve system-owned kalemler
- Mikser/irsaliye, numune, takip ve attachment
- Türetilen gerçek metraj ve açıklanabilir kapanış kontrolleri
- Yönetilen Ajanda projeksiyonu
- İnsan okunabilir rapor ve manifest

Uygulama kullanıcı adına otomatik beton kabul/red kararı üretmez.

## Backup ve restore

`.csebackup` format `1`, SQLite ile etkin attachment dosyalarını tek şifreli
pakette taşır.

- PBKDF2-HMAC-SHA256
- AES-256-GCM authenticated encryption
- SQLite integrity/FK/read-model smoke
- Attachment size/hash audit
- Atomik finalize
- Restore preflight
- Safety backup ve rollback
- Crash-safe restore journal
- Gerçek hazırlama, paketleme, doğrulama ve kaydetme aşamaları

Parola, secret, absolute kullanıcı yolu ve signing materyali state veya
manifest içine yazılmaz.

## CSE V2 veri yönü

V2'nin güncel temel zinciri:

```text
Stable Proje/Mahal ID — complete
→ Ortak kişi/firma ID — complete
→ Ortak attachment/link — complete
→ Ajanda ve Hatırlatıcı kaynak ilişkisi — complete
→ schedule runtime + persistent reference snapshots — merged
→ Living 7-Day Plan MVP Core — ready
→ 7-day UI + APK/device acceptance — next
```

Kanonik kapsam:

[`../docs/v2/CSE_V2_SCOPE.md`](../docs/v2/CSE_V2_SCOPE.md)

Reference schedule immutable suggestion/history olarak kalır. Living Plan
kullanıcı kararları stable project/activity-instance/snapshot kimliklerine
referans veren ayrı mutable/evented katmanda tutulacaktır; user action reference
schedule'ı sessizce yeniden yazmayacaktır. UI'dan önce yalnız tek dar core slice
açılabilir ve immediate successor 7-day UI + APK/device acceptance olmalıdır.

Item 5 henüz complete değildir; Living Plan UI/APK/device acceptance,
actual/progress/reforecast ve productivity learning uygulanmış sayılmaz.

## Geliştirici komutları

Flutter `3.44.6 stable` ve Dart `3.12.2` baseline'ı:

```powershell
cd mobile
flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
```

Dar Issue yalnız değişen sözleşmeyle orantılı kapıları çalıştırır. Her UI
değişikliği full release, AAB, signing, backup ve cihaz zincirini tekrar etmez.

## Signing ve platform sınırı

Gerçek Android signing yalnız repository dışındaki
`CSE_KEY_PROPERTIES_FILE` ile açılır. Eksik signing materyali fail-closed
durur; release debug key'e sessizce düşmez.

Gerçek iOS archive/TestFlight yalnız macOS, Xcode, Apple Developer hesabı ve
repository dışı signing materyaliyle üretilebilir.

Ayrıntılar:

[`../docs/release/mobile_identity_signing_and_rc.md`](../docs/release/mobile_identity_signing_and_rc.md)

## Olgunluk sınırı

- V1 owner saha kullanımı vardır.
- Kamuya açık production/store release ilan edilmemiştir.
- V2 Items 1–4 complete'tir; Item 5 Living 7-Day Plan current direction'dır.
- Schedule runtime ve persistent immutable snapshot foundation merged'dür.
- Living Plan UI/APK/device kabulü ve production readiness ilan edilmemiştir.
- Eski #279, PR #259, Orchestrator, Bridge ve Work Mode kayıtları güncel mobil
  capability veya V2 blocker'ı değildir.
