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
