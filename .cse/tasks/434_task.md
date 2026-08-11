# Issue #434 Task — Kontrollü Ajanda → Hatırlatıcı sync domain işlemi

## Yürütme bağlamı

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-434`
- Exact base/master: `f7eb942b6ac40665cf137b2fc23627f5feec5533`
- Branch: `codex/issue-434-agenda-reminder-sync`
- Model: current session-selected full Codex model
- Reasoning: `Extra High`
- Seçim nedeni: iki aggregate revision kontrolü, tek SQLite transaction, çift append-only event, 0..N izolasyonu ve retry idempotency birlikte korunmalıdır.

## Validation sözleşmesi

- Validation class: `domain`
- Changed contracts:
  - açıkça seçilen `title | description | location` alanları Ajanda source satırından exact bağlı Hatırlatıcıya atomik olarak kopyalanır;
  - source ve target optimistic revision birlikte doğrulanır, yalnız target revision gerçek diffte bir artar;
  - gerçek diffte Reminder ve Ajanda eventleri aynı operation kimliğiyle tek transaction içinde yazılır;
  - exact başarılı retry idempotent sonuç döndürür, kimlik/fingerprint collision fail-closed olur;
  - no-op ve 0..N izolasyonu revision/event yan etkisi üretmez.
- Focused tests:
  - title/description/location tekil ve birleşik happy path;
  - trim/null, deterministic field order ve iki event payloadı;
  - no-op, seçilmeyen alanlar, immutable `captureText`, notification/lifecycle izolasyonu;
  - stale/link/project/archive/trash/terminal/invalid-input/event/operation collision fail-closed durumları;
  - update ve event insert aşamalarındaki transaction rollback;
  - exact retry, changed-payload retry ve no-op retry.
- Allowed broad gates:
  - final source revision üzerinde bir kez full `flutter test --no-pub`;
  - `flutter analyze --no-pub`;
  - `git diff --check`, exact allowlist/protected-path ve schema/dependency/Backup-format/permission/platform diff kontrolleri;
  - yalnız runtime wiring build-time kanıt gerektirirse debug APK build.
- Reused evidence:
  - Slice 1 source/cardinality closure: Issue #432 / PR #433 / merge `f7eb942b6ac40665cf137b2fc23627f5feec5533`;
  - Schema 13 / Backup format 1 / V2.3 attachment-restore closure: Issue #420 / PR #430 / merge `d80d24462b700ccc06af02889f6fe429b8d7fb5f`;
  - schema, backup, attachment, package/signing, permission ve platform sözleşmeleri değişmezse bu kapılar tekrarlanmaz.
- Minimum physical-device acceptance: görünür UI değişmediği için yok; APK kurulumu/cihaz kabulü yapılmaz.
- Retry budget: Issue `N/A`; repository varsayılanı: 1 primary run, en fazla 1 blocking correction, exact fix sonrası aynı başarısız işlem için en fazla 1 retry.
- Time budget: Issue `N/A`; `domain` hedefi 30–45 dakika, hard stop 75 dakikadır.

## Yetkili dosyalar

Production:

- `mobile/lib/domain/agenda_models.dart`
- `mobile/lib/application/agenda_application.dart`

Test/support:

- `mobile/test/agenda_application_test.dart`
- `mobile/test/support/fake_agenda_application.dart` — yalnız interface değişirse
- `mobile/test/app_database_test.dart` — yalnız rollback/invariant kanıtı gerekirse

Evidence/docs:

- `.cse/tasks/434_task.md`
- `.cse/results/434_result.md`
- `docs/project_decisions.md`
- uygun ise `learning/434_*`

## Uygulanacak iş

1. İzinli logical alanları ve command/result contractını domain katmanında tanımla.
2. Source/target/link/project/lifecycle/revision validasyonlarını tek transaction içinde uygula.
3. Değerleri command payloadından değil transaction içindeki source satırından türet.
4. Yalnız gerçek ve seçilmiş diffleri target Reminder’a uygula; source satırını değiştirme.
5. Reminder `details_updated` ve Ajanda `agenda_log.reminder_sync_applied` eventlerini aynı operation kimliğiyle atomik yaz.
6. Schema eklemeden mevcut event tablolarıyla exact retry/fingerprint idempotency ve collision korumasını kur.
7. Zorunlu focused matrisi ve izinli geniş doğrulamaları tamamla.

## Kapsam dışı ve stop koşulları

- UI diff/confirmation, buton veya checkbox yok.
- Reverse/toplu sync, lifecycle eşleme, re-link/reparent, attachment veya notification redesign yok.
- `captureText`, project/source link, schedule/deadline/status/kind/person/condition/outcome alanları değişmez.
- Schema 14, migration, yeni ledger/index, CHECK genişletmesi, dependency/lockfile/permission/platform değişikliği yok.
- `mobile/lib/storage/app_database.dart` veya herhangi bir UI production dosyası gerekirse edit etmeden stop-and-report.
- Location semantiği current source ile çelişirse veya allowlist dışı production edit gerekirse stop-and-report.

## Yayın yetkisi

- Intentional commit, normal push ve Draft PR: yetkili.
- PR Ready: ChatGPT source review öncesinde yetkisiz.
- Merge: yalnız proje sahibinin açık talimatıyla.
- Force push/branch deletion: yasak.
- Post-merge local master sync: bu Issue içinde yapılmaz; merge sonrasında sonraki yetkili Codex çalışmasına bırakılır.
