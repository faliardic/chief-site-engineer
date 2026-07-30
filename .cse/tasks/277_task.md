# Issue #277 — Hatırlatıcı Yarın 08:00 ve Hafta Başı Kısayolları

## Yürütme kimliği

- Resmî repository:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Issue:
  `#277`
- Exact base/master:
  `d510a2eac0ed75d2390da103363956101114aff5`
- Branch:
  `codex/issue-277-reminder-exact-schedule-times`
- Model:
  current full Codex modeli
- Reasoning:
  Extra High
- Gerekçe:
  Europe/Istanbul takvim çözümleme, application mutation/idempotency,
  notification binding, widget preview ve fiziksel tablet kabulü birlikte
  korunacaktır.
- Validation class:
  `domain + narrow UI / P2`
- GitHub Issue:
  `https://github.com/faliardic/chief-site-engineer/issues/277`

## Başlangıç kanıtı

- Başlangıç branch:
  `master`
- `master`, `origin/master` ve HEAD:
  `d510a2eac0ed75d2390da103363956101114aff5`
- `master...origin/master`:
  `0 0`
- Tracked tree:
  temiz
- Staging:
  boş
- Yeni branch exact base üzerinde oluşturuldu.
- Önceden mevcut ignored/protected backup ve stale build kalıntıları
  okunmadı, değiştirilmedi veya stage edilmedi.
- Açık diğer PR:
  yalnız Draft PR #259; dokunulmayacaktır.

## Değişen sözleşmeler

- `Yarın sabah`, saatli kayıt için ertesi Europe/Istanbul günü exact `08:00`
  üretir.
- Timed `snoozeTomorrowMorning` mevcut kayıt saatini korumaz; ertesi yerel gün
  exact `08:00` üretir.
- All-day `Yarına ertele`, ertesi yerel günü all-day olarak korur.
- Yeni typed `ReminderScheduleKind.nextWeekStart`, bugünden strictly sonraki
  pazartesi Europe/Istanbul `08:00` üretir.
- Create ve reschedule aynı saf domain resolver'ları kullanır.
- Oluşturma formu ve detail schedule sheet'i işlem öncesi exact yerel
  tarih/saat preview gösterir.
- Timed liste/detail hızlı eylemi `Yarın 08:00` sözleşmesini görünür kılar.
- Mutation event tipi, optimistic revision, idempotency, rollback ve exact
  notification binding korunur.

## Exact allowlist

Baseline öncesi:

1. `.cse/tasks/277_task.md`
2. `mobile/test/reminder_lifecycle_test.dart`
3. `mobile/test/reminder_widget_test.dart`

Production + source/test cumulative:

4. `mobile/lib/domain/agenda_models.dart`
5. `mobile/lib/application/agenda_application.dart`
6. `mobile/lib/features/reminders/reminder_form_page.dart`
7. `mobile/lib/features/reminders/reminder_detail_page.dart`
8. `mobile/lib/features/reminders/reminders_page.dart`
9. `mobile/test/support/fake_agenda_application.dart`

PASS sonrası completion:

10. `.cse/results/277_result.md`
11. `CHANGELOG.md`
12. `ROADMAP.md`
13. `docs/277_reminder_exact_quick_schedule_times.md`
14. `docs/project_decisions.md`
15. `learning/277_reminder_exact_quick_schedule_times.md`

## Baseline sözleşmesi

- Exact merged base üzerinde unique detached worktree.
- Ana worktree'den yalnız task + iki test dosyası relative path korunarak
  kopyalanır.
- SHA-256 equality:
  `3/3`.
- Unexpected tracked path:
  `0`.
- Disposable `mobile` içinde gerçek `flutter pub get`:
  `1`.
- Lockfile diff:
  `0`.
- Yalnız:
  `flutter test --no-pub test/reminder_lifecycle_test.dart
  test/reminder_widget_test.dart`.
- Beklenen hedef failure'lar:
  create tomorrowMorning `09:00` yerine expected `08:00`;
  timed snooze mevcut saati korumak yerine expected `08:00`;
  detail sheet'te eksik `Hafta başına ertele`.
- Compile/load/harness/unrelated failure:
  `0`.

## Production tasarım sınırı

- Saf resolver'lar domain katmanında ve yalnız `CseTimeCodec` kullanır.
- `tomorrowMorning` ve `nextWeekStart` application create/reschedule akışında
  aynı resolver üzerinden çözülür.
- UI preview aynı resolver sonucunu gösterir ve fixed `clock` ile test edilir.
- Preview ile mutation operation günü uyuşmazsa silent fallback yerine
  fail-closed validation uygulanır.
- `snoozeTomorrowMorning`, timed kayıt için exact tomorrow `08:00`; all-day
  kayıt için mevcut all-day tomorrow davranışıdır.
- Notification gateway/native, schema, storage DDL, migration ve backup
  değişmez.

## Doğrulama

- Pure resolver takvim sınırları.
- Reminder lifecycle create/reschedule/snooze/all-day/idempotency/rollback/
  notification/event matrisi.
- Reminder widget form/sheet/quick action/overflow/async guard matrisi.
- Focused lifecycle ve widget suite.
- Full Flutter:
  tek invocation.
- Flutter analyze:
  tek invocation.
- `git diff --check`, exact allowlist, schema `10`, backup `1`, migration `0`,
  protected-path mutation `0`.

## Checkpoint, build ve tablet

- Source/test PASS sonrası checkpoint:
  `Add exact reminder quick schedule times`
- Exact checkpoint'ten unique detached worktree'de debug APK build:
  invocation/retry `1/0`.
- Tablet:
  `R52W90JFN1M / Samsung SM-X610 / sw853dp`.
- Her cihaz komutu exact serial taşır.
- Veri koruyan replace-install; uninstall/data clear/downgrade/hard-delete
  yasaktır.
- Yalnız benzersiz sentetik kayıtlar açılır ve geri alınabilir archive/trash
  akışıyla temizlenir.
- Telefon promotion yapılmaz.
- Tablet PASS olmadan completion commit/push/Draft PR yoktur.

## Bütçe ve kapsam dışı

- Primary implementation run:
  `1`
- Yalnız doğrulanmış harness blocker correction:
  en fazla `1`
- Build invocation/retry:
  `1/0`
- Hedef:
  `40 dakika + cihaz otomasyonu`
- Hard stop:
  `60 dakika + cihaz otomasyonu`
- Kapsam dışı:
  erkene alma, edit ekranında tam gün, tam gün liste sırası, proje filtresi,
  recurring weekly, genel recurrence, notification sound, schema/migration/
  backup, telefon promotion, Draft PR #259 ve D29.3'ün diğer maddeleri.

## Yayın sınırı

- Tablet PASS sonrası completion commit:
  `Complete exact reminder schedule validation`
- Normal push.
- Tek Draft PR:
  `Set exact reminder quick schedule times`
- PR body:
  `Related to #277` ile başlar.
- Ready, merge, Issue close, branch delete ve yeni D29.3 child Issue yoktur.

## Baseline gerçekleşmesi — 2026-07-30

- Worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse277-baseline-20260730054102116-1d33990b`
- Detached HEAD:
  `d510a2eac0ed75d2390da103363956101114aff5`
- Task + lifecycle test + widget test SHA equality:
  `3/3`.
- Unexpected tracked path:
  `0`.
- Production diff:
  `0`.
- `flutter pub get`:
  invocation `1`, PASS.
- Lockfile diff:
  `0`.
- Focused baseline invocation:
  `1`, expected non-zero.
- Existing/other test sonucu:
  `82 PASS`.
- Exact hedef failure `3/3`:
  1. create `tomorrowMorning`: expected
     `2026-07-31T05:00:00Z` / actual
     `2026-07-31T06:00:00Z` (`08:00` yerine `09:00`);
  2. timed tomorrow snooze: expected
     `2026-07-31T05:00:00Z` / actual
     `2026-07-31T11:30:00Z` (eski `14:30` local saat korundu);
  3. detail planning sheet:
     `Hafta başına ertele` expected `1` / actual `0`.
- Compile/load/harness/`Bad state`/unrelated failure:
  `0`.
- Clean baseline matrix:
  PASS.
- Production editine izin:
  **EVET**; yalnız Issue #277 production allowlist'i kullanılacaktır.

## Source doğrulama ve fail-closed stop — 2026-07-30

- Source worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse277-source-20260730054809222`
- Detached HEAD:
  `d510a2eac0ed75d2390da103363956101114aff5`
- `flutter pub get`:
  invocation `1`, PASS; lockfile diff `0`.
- Focused lifecycle:
  - primary: production davranışı PASS; iş olayı yerine son notification olayını
    okuyan `2` harness assertion tespit edildi;
  - correction: `48/48 PASS`.
- Focused reminder widget:
  - primary: production davranışı PASS; küçük test viewport'unda lazy sheet
    satırını kaydırmadan arayan `2` harness assertion tespit edildi;
  - correction: `46/46 PASS`.
- Full Flutter primary:
  `332 PASS / 1 FAIL`.
- Full Flutter diagnostic correction:
  `332 PASS / 1 FAIL`.
- Exact blocker:
  `mobile/test/concrete_application_test.dart:657`, timed
  `snoozeTomorrowMorning` için eski `2026-07-20T08:00:00Z`
  (`Europe/Istanbul 11:00`) beklentisini taşımaktadır; yeni ve Issue tarafından
  zorunlu sonuç `2026-07-20T05:00:00Z`
  (`Europe/Istanbul 08:00`) olmuştur.
- Blocker sınıfı:
  full Flutter failure + cumulative allowlist dışı test düzeltmesi gereksinimi.
- Stop kararı:
  Issue #277 stop koşulu uyarınca fail-closed.
- Başlatılmayan adımlar:
  analyze, checkpoint commit, APK build, tablet kabulü, completion docs,
  completion commit, push ve Draft PR.
- Build invocation/retry:
  `0/0`.
- Cihaz/telefon işlemi:
  `0/0`.

## Yetkili test-only correction — 2026-07-30

- GitHub Issue yorumu:
  `5125888588`.
- Yetkili ek allowlist:
  yalnız `mobile/test/concrete_application_test.dart`.
- Production kapsam genişlemesi:
  `0`.
- Exact düzeltme:
  timed `snoozeTomorrowMorning` sonucu
  `2026-07-20T08:00:00Z` yerine `2026-07-20T05:00:00Z`;
  saatlik tekrar örnekleri `08:00Z/09:00Z/10:00Z` yerine
  `05:00Z/06:00Z/07:00Z`.
- Fixed clock, fixture, mutation akışı ve production resolver kullanmadan açık
  canonical beklentiler korunmuştur.

## Resumed source kapıları — 2026-07-30

- Exact concrete regression:
  `1/1 PASS`.
- Yeniden kullanılan source-aynı kanıt:
  focused lifecycle `48/48 PASS`, focused widget `46/46 PASS`.
- Full Flutter:
  - ilk resumed çağrı tool stdout timeout nedeniyle sonuç üretmedi;
  - kullanıcı mesajıyla abort edilen çağrı sonuç olarak kullanılmadı;
  - temiz background invocation:
    `333/333 PASS`, `0 FAIL`, exit `0`.
- Flutter analyze:
  `No issues found`, exit `0`.
- `git diff --check`:
  PASS.
- Source/test cumulative scope:
  `9` tracked dosya + task kaydı; unexpected tracked path `0`.
- Protected/native/notification-gateway diff:
  `0/0/0`.
- Schema / backup format / migration diff:
  `10 / 1 / 0`.
- Staging:
  source kapıları sonunda boş.
- Build invocation:
  henüz `0`.

## Checkpoint ve tek APK — 2026-07-30

- Checkpoint commit:
  `952c81acc52712f4f24315576db2bbe9201d2040`
  (`Add exact reminder quick schedule times`).
- Checkpoint staged scope:
  exact `10` dosya.
- Build worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse277-build-20260730085859450`.
- Build worktree HEAD:
  `952c81acc52712f4f24315576db2bbe9201d2040`; tracked dirty path `0`.
- Build invocation/retry:
  `1/0`.
- Build sonucu:
  PASS, `flutter build apk --debug`, exit `0`.
- APK:
  `C:\Users\Fatih\AppData\Local\Temp\cse277-build-20260730085859450\mobile\build\app\outputs\flutter-apk\app-debug.apk`.
- APK length / last-write UTC:
  `170518446` /
  `2026-07-30T06:02:05.2434855Z`.
- APK SHA-256:
  `3395fbb73b7f36593bb5045be0a265cb759507ddc88d779f9a8049f9bfd9c4ce`.
- Package / version:
  `com.faliardic.chiefsiteengineer.debug` /
  `versionCode 1`, `versionName 0.1.0-debug`, min/target `24/36`.
- Signer:
  Android Debug, certificate SHA-256
  `329f42b542af8576367279b59fb2802dfd545253b2906f7ba2ac12c7c6d5c869`;
  APK Signature Scheme v2 doğrulandı.
- Toolchain notu:
  mevcut `file_picker` / `share_plus` Built-in Kotlin future-warning'i;
  build exit `0`, bu Issue'da kapsam genişletilmedi.

## Tablet preflight ve fail-closed keyguard — 2026-07-30

- Exact serial/model:
  `R52W90JFN1M` / Samsung `SM-X610`.
- Device state:
  `device`; physical tablet, `ro.kernel.qemu=0`, Android/API `16/36`.
- Physical size/density:
  `1600x2560`, physical `340 dpi`, effective `300 dpi`;
  hesaplanan smallest width `853dp`.
- Reconnect:
  exact serial ile PASS.
- Veri koruyan replace-install:
  `adb -s R52W90JFN1M install -r -g <exact-apk>` / `Success`.
- Installed package/version:
  exact artifact ile uyumlu.
- Uninstall / clear-data / downgrade / hard-delete:
  `0 / 0 / 0 / 0`.
- Keyguard:
  Samsung secure keyguard `showing=true`, `mIsShowing=true`.
  `KEYCODE_WAKEUP`, `wm dismiss-keyguard`, system back, status-bar collapse ve
  tek güvenli unlock swipe kilidi kapatmadı.
- Bounded automatic monitor:
  `6 x 5 saniye`; `KEYGUARD_UNLOCKED=False`.
- Sentetik kayıt oluşturma/değiştirme:
  `0`.
- Gerçek kullanıcı kaydı açma/değiştirme:
  `0`.
- Tablet wide smoke:
  **NOT RUN / FAIL-CLOSED — SECURE_KEYGUARD_ACTIVE**.
- Stop:
  Güvenli kilidi aşma, parola/PIN isteme veya manuel kabul talep etme yok.
  Tablet PASS olmadığı için completion docs/commit, push ve Draft PR yok.

## Unlocked tablet smoke resume ve PASS — 2026-07-30

- Yetki yorumu:
  `5127927747`.
- Frozen checkpoint / APK SHA-256:
  `952c81acc52712f4f24315576db2bbe9201d2040` /
  `3395fbb73b7f36593bb5045be0a265cb759507ddc88d779f9a8049f9bfd9c4ce`.
- Yeniden build / ikinci install / artifact mutation:
  `0 / 0 / 0`.
- Exact device:
  `R52W90JFN1M device` / Samsung `SM-X610` / `sw853dp`.
- Keyguard:
  `KEYGUARD_SHOWING=False`; app window foreground ve etkileşime hazır.
- Kurulu package:
  `com.faliardic.chiefsiteengineer.debug`,
  versionCode `1`, versionName `0.1.0-debug`, min/target `24/36`.
- Synthetic prefix:
  `CSE277TAB-20260730T103117`.

### Otomatik smoke matrisi

1. Yeni timed kayıt / tomorrow:
   - formda seçimden önce
     `Yarın sabah — 31.07.2026 08:00` exact preview görünür;
   - listede `Yarın • 08:00`, detail'de `31.07.2026 08:00:00`;
   - canonical `next_attention_at` ve binding `scheduled_for`:
     `2026-07-31T05:00:00Z`;
   - binding sync state `scheduled`, UI `Bildirim planlandı`,
     native diagnostic `Native plan: var`.
2. Detail reschedule / next week:
   - seçimden önce tomorrow `31.07.2026 08:00` ve
     `Hafta başına ertele / 03.08.2026 08:00` subtitle'ları görünür;
   - mutation sonrası canonical `next_attention_at` ve `scheduled_for`:
     `2026-08-03T05:00:00Z`;
   - append-only `rescheduled` payload `next_attention_at` exact;
   - sonraki `notification_scheduled` payload `scheduled_for` exact;
   - pazartesi `+7 gün` sözleşmesi source-aynı fixed-clock resolver/widget
     test kanıtından yeniden kullanıldı.
3. Timed hızlı eylem:
   - başlangıç local zamanı `30.07.2026 10:50`
     (`2026-07-30T07:50:20Z`);
   - `Yarın 08:00` eylemi görünür;
   - mutation sonrası eski saat korunmadı:
     `next_attention_at = scheduled_for = 2026-07-31T05:00:00Z`;
   - `snoozed` ve `notification_scheduled` payload'ları exact.
4. All-day korunumu:
   - `30.07.2026` all-day kayıt `Yarına ertele` ile `31.07.2026` oldu;
   - `next_attention_at = null`, `scheduled_for = null`,
     `all_day_local_date = 2026-07-31`;
   - UI `31.07.2026 • Tam gün`, saatli native bildirim yok;
   - `snoozed` payload all-day tarihi exact.
5. Kalıcılık:
   - system back ile normal kapanış ve warm reopen gözlendi;
   - Android Recents'tan yalnız exact app kartı kullanıcı-seviyesi swipe ile
     kapatıldı; package PID kalmadı;
   - exact activity relaunch `LaunchState: COLD`;
   - üç sentetik kaydın exact zaman/türleri cold relaunch sonrası korundu.
6. Canonical persistence kanıtı:
   - yalnız synthetic prefix'e filtrelenmiş salt-okunur debug DB snapshot;
   - `3` sentetik row ve `10` sentetik event doğrulandı;
   - gerçek kayıt içeriği çıktıya alınmadı;
   - geçici DB snapshot doğrulama sonrası kaldırıldı.
7. Geri alınabilir cleanup:
   - üç kaydın her birinde dialog
     `Geri Dönüşüm Kutusu’ndan geri getirilebilir` ve detail
     `Geri yükle` eylemi doğrulandı;
   - active Tomorrow sentetik `0`;
   - active Upcoming sentetik `0`;
   - Geri Dönüşüm Kutusu sentetik `3/3`;
   - görünür `Geri yükle` eylemi `3/3`.

### Güvenlik ve sonuç

- Gerçek kullanıcı kaydı açma/değiştirme:
  `0`.
- Uninstall / clear-data / downgrade / hard-delete:
  `0 / 0 / 0 / 0`.
- Telefon promotion / D29.3 child:
  `0 / 0`.
- Tablet wide smoke:
  **PASS**.
- Completion commit / push / Draft PR:
  yetkili olmadığı için `0 / 0 / 0`.

## Completion publication authority — 2026-07-30

- GitHub Issue yorumu:
  `5128105234`.
- Kabul:
  tablet-only wide smoke PASS ve kanıt yorumu `5128081170`, Issue #277
  completion kapısı olarak kabul edildi.
- Yetki:
  yalnız mevcut doğrulanmış working tree'den completion belgeleri, exact
  completion commit, normal push ve `master` hedefli tek Draft PR.
- Yeni product/test değişikliği:
  `0`.
- Tekrar çalıştırılmayan kapılar:
  Flutter test/analyze, build, install, tablet smoke ve telefon.
- Reused evidence:
  focused lifecycle `48/48 PASS`, focused widget `46/46 PASS`, concrete
  regression `1/1 PASS`, full Flutter `333/333 PASS`, analyze clean, tek
  checkpoint APK build/install ve tablet-only wide smoke/cold relaunch PASS.
- Completion cumulative allowlist:
  exact `16/16`; unexpected tracked path `0`, missing approved path `0`.
- Source/test working-tree mutation after checkpoint:
  `0`.
- `origin/master`:
  exact `d510a2eac0ed75d2390da103363956101114aff5`.
- Pre-completion divergence:
  `origin/master...HEAD = 0 behind / 1 ahead`.
- Pre-stage `git diff --check`:
  PASS.
- Completion Markdown conflict marker:
  `0`; code-fence sayıları çift.
- İzlenmeyen ve stage edilmeyen mevcut artefaktlar:
  `device-backups/`, `reports/`, `mobile/build.*-stale/` ve
  `mobile/ios/Flutter/ephemeral.issue255-stale/`.
- Completion commit mesajı:
  `Complete exact reminder schedule validation`.
- Draft PR başlığı:
  `Set exact reminder quick schedule times`; gövde `Related to #277` ile
  başlar.
- Hard boundaries:
  Ready/merge/rebase/force-push/master mutation/Issue close/phone promotion/
  D29.3 expansion/second build-install/data clear/uninstall/downgrade/
  hard-delete/PR #259 mutation yapılmaz.
