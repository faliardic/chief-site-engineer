# Issue #432 Task — Ajanda–Hatırlatıcı kardinalitesi ve lifecycle görünürlüğü

## Yürütme bağlamı

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-432`
- Git common dir: resmî repository `.git`
- Exact base: `d80d24462b700ccc06af02889f6fe429b8d7fb5f`
- Branch: `codex/issue-432-agenda-reminder-lifecycle-visibility`
- Model: current session-selected full Codex model
- Reasoning: `Extra High`
- Seçim nedeni: 0..N cross-record read-model, trash/archive lifecycle görünürlüğü ve mevcut saha UI regresyonları birlikte korunmalıdır.

## Validation sözleşmesi

- Validation class: `narrow-ui`
- Changed contracts:
  - Ajanda app-bar Hatırlatıcı eylemi bağlı kayıt sayısından bağımsız olarak create akışını açar.
  - Ajanda detay read-model’i non-trash ve trash bağlı Hatırlatıcıları ayrı, deterministik koleksiyonlarda taşır.
  - Reminder detail kaynak Ajanda arşiv durumunu görünür kılar; media ve source navigation korunur.
- Focused tests:
  - application 0..N partition/order/trash regressions;
  - Agenda widget create/exact-card/trash/archive regressions;
  - Reminder widget archived-source/media/navigation regressions.
- Allowed broad gates:
  - final revision üzerinde full `flutter test --no-pub`;
  - `flutter analyze --no-pub`;
  - `git diff --check` ve allowlist/protected-path kontrolleri;
  - clean linked-worktree debug APK build, SHA-256 ve native/plugin inventory sanity;
  - tam bir authorized cihaz varsa data-preserving `adb install -r` + cold launch smoke.
- Reused evidence:
  - Schema 13 / Backup format 1 / V2.3 attachment closure: Issue #420, PR #430, base commit `d80d24462b700ccc06af02889f6fe429b8d7fb5f`.
  - Bu sözleşmeler ve ilgili dosya alanları değişmediği sürece backup/restore ve release/AAB/signing gate’leri tekrarlanmaz.
- Minimum physical-device acceptance: data-preserving install + cold launch; görünür dar yol Ready öncesi kullanıcı/ChatGPT kabulüne bırakılır. Uninstall, clear-data, restore ve gerçek kullanıcı kaydı mutation’ı yasaktır.
- Retry budget: Issue `N/A`; repository protokolü varsayılanı uygulanır: 1 primary run, en fazla 1 blocking correction ve exact fix sonrası aynı başarısız işlem için en fazla 1 retry.
- Time budget: Issue `N/A`; `narrow-ui` protokol hard stop’u 45 dakikadır.

## Yetkili dosyalar

Production:

- `mobile/lib/domain/agenda_models.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/features/agenda/log_detail_page.dart`
- `mobile/lib/features/reminders/reminder_detail_page.dart`

Test/support:

- `mobile/test/support/fake_agenda_application.dart` — yalnız yeni read-model alanı gerekiyorsa
- `mobile/test/agenda_application_test.dart`
- `mobile/test/mobile_agenda_widget_test.dart`
- `mobile/test/reminder_widget_test.dart`

Evidence/docs:

- `.cse/tasks/432_task.md`
- `.cse/results/432_result.md`
- `docs/project_decisions.md`
- gerekirse dar `learning/432_*`

## Uygulanacak iş

1. `AgendaLogDetail` içine ayrı `trashedReminders` koleksiyonu ekle.
2. `_loadAgendaDetail` bütün source-linked Reminder satırlarını `created_at ASC, id ASC` okuyup non-trash/trash olarak partition etsin.
3. Ajanda app-bar Hatırlatıcı eylemi yalnız create formunu açsın; arşivli/managed source için kapalı kalsın.
4. Aktif ve çöpteki bağlı Hatırlatıcıları ayrı bölümlerde exact kimlikleriyle aç.
5. Reminder detail’de kaynak Ajanda archived banner/state göster; media ve navigation davranışını değiştirme.
6. Odaklı ve izinli geniş doğrulamaları tamamla; factual result/evidence üret.

## Kapsam dışı ve stop koşulları

- Explicit sync mutation/diff/field copy, reverse rewrite ve toplu sync yok.
- Archive↔trash veya complete↔archive mapping yok.
- Semantic duplicate UX, notification redesign, schema/migration/backup-format, V2.3 attachment lifecycle, V2.5+, AI/Bridge/Orchestrator/API yok.
- Schema değişikliği, source re-link, hard 0..1 constraint veya allowlist dışı production edit gerekirse edit durur ve Issue’ya gerekçe yazılır.

## Yayın yetkisi

- Intentional commit, normal push ve Draft PR: yetkili.
- PR Ready: bu çalışmada yetkisiz; ChatGPT source review + manuel cihaz kabulü gerekir.
- Merge: yalnız proje sahibinin açık talimatıyla.
- Branch deletion/force push: yasak.
