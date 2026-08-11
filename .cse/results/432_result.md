# Issue #432 Result — Ajanda–Hatırlatıcı kardinalitesi ve lifecycle görünürlüğü

## Yürütme özeti

- Validation class: `narrow-ui`
- Yaklaşık süre: 25 dakika; 45 dakikalık hard stop aşılmadı.
- Primary run: 1
- Blocking correction: 1 — iki yeni Ajanda widget testindeki yalnız test-scroll/assertion sırası düzeltildi.
- Exact-operation retry:
  - PATH’te olmayan `dart` için pinned SDK yolu ile formatter bir kez tekrarlandı ve PASS oldu.
  - İlk clean build Windows generated-file handle’ında, derleme başlamadan durdu; yalnız başarısız build aşaması yeni detached validation worktree’de bir kez tekrarlandı ve PASS oldu.
- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole feature worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-432`
- İzole build worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-432-build`
- Base/master ve origin/master: `d80d24462b700ccc06af02889f6fe429b8d7fb5f`
- Branch: `codex/issue-432-agenda-reminder-lifecycle-visibility`
- Doğrulama source commit’i: `40c198f7ca12f81490c4ea5b02fb262ff9bcf4db`; final publication SHA result kaydını aynı intentional commit’e ekleyen amend sonrası Issue yorumunda tutulur.

## Değişen sözleşmeler

- `AgendaLogDetail.reminders` yalnız non-trash source-linked Hatırlatıcıları taşımaya devam eder.
- Yeni `AgendaLogDetail.trashedReminders`, aynı deterministic `created_at ASC, id ASC` sorgusundan ayrılan trash kayıtlarını taşır.
- Ajanda app-bar Hatırlatıcı eylemi bağlı kayıt sayısından bağımsız olarak yalnız create formunu açar; herhangi bir `first` kayıt seçmez.
- Arşivli veya Beton tarafından yönetilen Ajanda’dan yeni Hatırlatıcı oluşturulmaz; bağlı kartlar exact kimlikleriyle görünür ve açılır.
- Reminder detail kaynak Ajanda arşivliyse görünür banner gösterir; source media/navigation ve Hatırlatıcı lifecycle’ı değişmez.
- Source link, Agenda/Reminder revision/event, notification, attachment, schema ve backup formatı değişmedi.

## Değişen dosyalar

- `.cse/tasks/432_task.md`
- `.cse/results/432_result.md`
- `docs/project_decisions.md`
- `mobile/lib/domain/agenda_models.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/features/agenda/log_detail_page.dart`
- `mobile/lib/features/reminders/reminder_detail_page.dart`
- `mobile/test/support/fake_agenda_application.dart`
- `mobile/test/agenda_application_test.dart`
- `mobile/test/mobile_agenda_widget_test.dart`
- `mobile/test/reminder_widget_test.dart`

Allowlist dışı production dosyası değişmedi. Learning belgesi eklenmedi; yeni kalıcı teknik terim yok ve gerçek kod/test/karar akışı task, result ve `docs/project_decisions.md` içinde yeterince açıklanıyor.

## Focused test kanıtı

- `flutter test --no-pub test/agenda_application_test.dart test/mobile_agenda_widget_test.dart test/reminder_widget_test.dart`:
  - application suite: PASS, 25 test;
  - Reminder widget suite: PASS;
  - iki yeni Ajanda widget testi test-scroll/assertion sırası nedeniyle FAIL oldu; production exception veya davranış hatası yoktu.
- Correction sonrası `flutter test --no-pub test/mobile_agenda_widget_test.dart`: **PASS, 30 test**.
- Zorunlu regresyonlar 0..N partition/order, exact card navigation, create-action independence, trash section, archived source no-create ve source archive/media/navigation davranışını kapsıyor.

## Broad gate kanıtı

- Final production source revision üzerinde `flutter test --no-pub`: **PASS, 494 test**; bir kez çalıştırıldı.
- `flutter analyze --no-pub`: **PASS, No issues found**.
- `git diff --check`: **PASS**; publication preflight’inde tekrar doğrulanır.
- Exact allowlist/protected-path diff: **PASS**.
- Dependency/schema/Backup format/permission/platform diff: **0**.
- Mevcut sabitler: mobile schema `13`, Backup format `1`.
- Clean detached worktree debug APK build: **PASS**.

## APK ve runtime inventory

- Artifact: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-432-build\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- Boyut: `170768778` byte
- SHA-256: `0C11342A4683B9EC7171CAF541B4691D2C93FF0D03BC97E2519AE43EDD43E000`
- Application ID: `com.faliardic.chiefsiteengineer.debug`
- DEX sanity PASS:
  - `GeneratedPluginRegistrant`
  - `FilePickerPlugin`
  - `SharePlusPlugin`
  - `ImagePickerPlugin`
  - `OpenFilePlugin`
  - `FlutterLocalNotificationsPlugin`
- APK native inventory PASS: ARM64 `libflutter.so`, `libsqlite3.so`, `libdartjni.so` mevcut; desteklenen diğer ABI girdileri de üretildi.

## Fiziksel cihaz

- ADB daemon hazırlandıktan sonra authorized device count: `0`.
- Issue koşulu “tam olarak bir authorized cihaz” sağlanmadığı için `adb install -r` ve cold launch **çalıştırılmadı**.
- Uninstall, clear-data, restore, reboot/background acceptance veya gerçek kullanıcı kaydı mutation/inspection yapılmadı.
- PR Ready öncesi dar manuel cihaz kabulü açık kalır.

## Yeniden kullanılan kanıt ve çalıştırılmayan kapılar

Reused evidence:

- Contract: schema 13, Backup format 1, V2.3 attachment/source-media ve restore bütünlüğü.
- Source: Issue #420 / PR #430 / merge `d80d24462b700ccc06af02889f6fe429b8d7fb5f`.
- Why still valid: schema, backup, attachment store/link, dependency, permission ve platform dosyalarında diff `0`; bu Issue yalnız read-model/presentation sözleşmesini değiştiriyor.

Bilinçli olarak çalıştırılmadı:

- yeni full backup/restore zinciri;
- release APK/AAB, signing, store ve 16 KiB gate’i;
- background notification/reboot acceptance;
- Python/web/desktop full repository suite.

## Güvenlik ve repository durumu

- Ana resmî checkout’taki önceki dört tracked backup değişikliği ve untracked artifact/task kayıtları aynen korundu; stash/reset/clean/checkout uygulanmadı.
- Feature worktree source commit sonrasında temizdi.
- Detached build worktree `40c198f7...` üzerinde temizdi.
- Resmî `exports/` yalnız `.gitkeep` içeriyor.
- Ignored `chief-site-engineer_adim_080_guvenli_nokta.zip` yerinde ve dokunulmadı.
- Gerçek kullanıcı data root’u okunmadı veya değiştirilmedi.

## Publication

- Intentional commit: yerel kaynak commit’i üretildi; result aynı commit’e amend edilecek.
- Push: result/final diff doğrulamasından sonra normal push yetkili.
- Draft PR: push sonrasında yetkili.
- PR Ready: cihaz kabulü ve ChatGPT source review öncesinde yapılmayacak.
- Merge: yalnız proje sahibinin açık talimatıyla.

Remaining blocker: implementation için blocker yok; **PR Ready için tek kalan kabul adımı bağlı cihazda data-preserving install/cold-launch ve görünür dar yolun manuel doğrulanmasıdır.**
