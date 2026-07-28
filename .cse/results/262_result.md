# Issue #262 — Hatırlatıcı `Yarına ertele` uygunluğu sonucu

## Durum

`BLOCKED` — production source, focused testler, full Flutter, analyze ve static
scope kapıları PASS; fiziksel cihaz `device` durumunda doğrulandı, ancak normal
field APK build'i Windows dosya kilidi nedeniyle tamamlanamadı. Bu nedenle
install ve sentetik cihaz smoke'u başlatılmadı. Bütün kapılar PASS olmadığı için
commit, push ve Draft PR oluşturulmadı.

## Repository

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base `master`: `6b64ed29e15d0f839e10fb4ff0b7bbe739a0fd8a`
- `origin/master`: `6b64ed29e15d0f839e10fb4ff0b7bbe739a0fd8a`
- Master divergence: `0 0`
- Branch: `codex/issue-262-reminder-tomorrow-action-eligibility`
- Branch başlangıç SHA: `6b64ed29e15d0f839e10fb4ff0b7bbe739a0fd8a`
- Draft PR #259 head SHA `7cce5de803ce4ea6b043b49499988c615ce923e8`
  branch ancestry'sinde değildir (`merge-base --is-ancestor` exit `1`).

## Validation sınıfı ve bütçe

- Validation class: `domain`
- Primary run: `1`
- Correction phase: `1`
- Correction kapsamı: sentetik Puantaj fixture'ına zorunlu `project_id` eklemek ve
  widget deep-link testini page-type yerine gerçek Navigator push üzerinden
  doğrulamak.
- Aynı full Flutter ve analyze kapısı source revision üzerinde yalnız birer kez
  çalıştırıldı.

## Kök neden kanıtı

Production editinden önce yarın tarihli bağımsız sentetik reminder için yeni
fail-closed beklenti çalıştırıldı:

```text
Expected: throws AgendaValidationFailure
Actual: Future<MobileReminder> emitted MobileReminder
```

Eski application davranışı yarın tarihli kaydı reddetmek yerine sessiz no-op
döndürüyordu. Aynı görünürlük yalnız ekran grubuna bağlı olduğundan gelecekteki
ve Puantaj kaynaklı kartlar generic eylemi gösterebiliyordu.

## Uygulanan sözleşme

- Kart, detay ve `snoozeTomorrowMorning` direct mutation
  `isReminderEligibleForTomorrowSnooze` domain helper'ını kullanır.
- Timed due UTC değeri Europe/Istanbul yerel gününe çevrilir; all-day yerel gün
  alanını kullanır.
- Gecikmiş/bugün tarihli bağımsız aktif reminder uygundur.
- Yarın/gelecek, Puantaj kaynaklı, terminal, trash ve plansız reminder uygun
  değildir.
- Uygun olmayan mutation row, revision, event ve notification binding'i
  değiştirmeden fail-closed reddedilir.
- Uygun timed reminder yerel saatini; all-day reminder yerel yarın gününü korur.
- Aynı event ID retry duplicate event üretmez; farklı stale event mevcut
  optimistic revision hatasını korur.
- Puantaj kaynak deep-link'i korunur.

## Test kanıtı

- Root-cause sentetik pre-implementation testi: beklenen FAIL.
- Focused reminder domain/application:
  `flutter test --no-pub test\reminder_lifecycle_test.dart` — `32 PASS`.
- Focused reminder widget:
  `flutter test --no-pub test\reminder_widget_test.dart` — `39 PASS`.
- Full Flutter:
  `flutter test --no-pub` — `281 PASS`.
- Flutter analyze:
  `flutter analyze --no-pub` — `PASS`, `No issues found!`.
- `git diff --check`: `PASS`.
- Exact allowlist: `PASS`, unexpected path `0`.
- Protected-path diff: `PASS`, changed protected path `0`.
- Schema diff: `0`; `AppDatabase.schemaVersion = 10`.
- Backup codec diff: `0`; `CseBackupCodec.formatVersion = 1`.
- Migration eklenmedi.

## Fiziksel cihaz ve build blocker'ı

İlk cihaz kontrolü:

```text
adb devices -l
```

Sonuç:

```text
List of devices attached
R5CY21WKZFX  device  product:pa3qxxx model:SM_S938B device:pa3q transport_id:2
```

`R5CY21WKZFX` fiziksel cihazı `device` durumunda doğrulandı.

İlk build komutu Flutter/Gradle aşamasına ulaşmadan komut taşıyıcısının stdout
borusunu kapatması nedeniyle sonlandı. Aktif build süreci bulunmadığı ve mevcut
`app-debug.apk` dosyasının eski `2026-07-28T13:39:21.0269661Z` last-write
değerini koruduğu doğrulandı.

Aynı source revision üzerindeki kontrollü `--no-pub` build çağrısı Gradle
`assembleDebug` içinde şu doğrulanmış Windows dosya kilidinde durdu:

```text
Execution failed for task ':app:cleanMergeDebugAssets'.
Unable to delete directory:
mobile/build/app/intermediates/assets/debug/mergeDebugAssets
```

Yeni APK üretilmedi. Retry bütçesi gereği yeni build-root, clean, rotation veya
ikinci build correction başlatılmadı.

Bu nedenle:

- normal field APK build'i PASS olmadı;
- ADB install yapılmadı;
- uninstall, clear-data veya downgrade yapılmadı;
- sentetik bugün/yarın/Puantaj reminder cihaz smoke'u yapılmadı;
- gerçek kullanıcı reminder veya Puantaj kaydı açılmadı, okunmadı ya da
  değiştirilmedi.

Kalan tek adım: Windows `mobile/build/.../mergeDebugAssets` kilidi güvenilir
biçimde dış ortamda giderildikten ve yeni build correction için açık yetki
verildikten sonra source diff'i değiştirmeden normal field APK build, veri
koruyan install ve yalnız sentetik reminder smoke'unu tamamlamak.

## Değişen exact dosyalar

1. `.cse/tasks/262_task.md`
2. `.cse/results/262_result.md`
3. `CHANGELOG.md`
4. `ROADMAP.md`
5. `docs/262_reminder_tomorrow_action_eligibility.md`
6. `docs/project_decisions.md`
7. `learning/262_reminder_tomorrow_action_eligibility.md`
8. `mobile/lib/domain/agenda_models.dart`
9. `mobile/lib/application/agenda_application.dart`
10. `mobile/lib/features/reminders/reminders_page.dart`
11. `mobile/lib/features/reminders/reminder_detail_page.dart`
12. `mobile/test/reminder_lifecycle_test.dart`
13. `mobile/test/reminder_widget_test.dart`
14. `mobile/test/support/fake_agenda_application.dart`

## Safety notu

İlk allowlist PowerShell komutunda path argümanları yanlış satır ayrıldığı için
Git ignored generated dizinler üzerinde filename-too-long uyarıları yazdı.
Dosya içeriği okunmadı; hiçbir protected/ignored dosya değiştirilmedi,
silinmedi, taşınmadı, stage edilmedi veya commitlenmedi. Kontrol explicit path
listesiyle yeniden çalıştırıldı ve protected changed-path sayısı `0` bulundu.

## GitHub durumu

- Commit: oluşturulmadı.
- Push: yapılmadı.
- Draft PR: açılmadı.
- Merge: yapılmadı.
- Remaining blocker: Windows
  `mobile/build/app/intermediates/assets/debug/mergeDebugAssets` dosya kilidi ve
  build retry bütçesinin tükenmiş olması.
