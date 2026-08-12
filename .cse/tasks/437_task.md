# Issue #437 Task — Ajanda’dan güncelle diff / confirmation UI

## Yürütme bağlamı

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-437`
- Exact base/master: `e9cadce44ffcf27c73ce616dfde1f870168d8044`
- Branch: `codex/issue-437-agenda-reminder-sync-ui`
- Model: current session-selected full Codex model
- Reasoning: `Extra High`
- Seçim nedeni: görünür cross-record diff önizlemesi, açık alan seçimi, çift revision, busy guard ve fail-closed mutation davranışı birlikte korunmalıdır.

## Validation sözleşmesi

- Validation class: `narrow-ui`
- Changed contracts:
  - exact açık Hatırlatıcı için Ajanda source snapshotı read-only yüklenir;
  - yalnız gerçek `title | description | location` farkları kullanıcıya before/after değerleriyle gösterilir;
  - kullanıcı alanları açıkça seçer ve yalnız confirmation sonrasında mevcut Slice 2 mutationı çağrılır;
  - stale/failure durumunda optimistic rewrite yapılmaz, güvenli reload uygulanır;
  - başarı sonrasında source ve target yeniden yüklenir, diff kalmadığında action kaybolur;
  - domain/application/schema/backup/notification/platform sözleşmeleri değişmez.
- Focused tests:
  - title, description ve location tekil diff görünürlüğü;
  - üç diff satırının before/after değeri, default seçim ve tekil deselection;
  - tüm alanlar kapalıyken confirmation disabled, cancel çağrı üretmez;
  - exact IDs/revision/selected fields ve üç bağımsız geçerli UUID ile tek mutation;
  - no-diff, archived source, trashed/completed/cancelled target ve source-load failure fail-closed görünürlük;
  - double tap/busy guard, success reload/action kaybı ve stale/failure güvenli reload;
  - seçilmeyen/sync dışı alanlar, source navigation/media ve archived banner regresyonları;
  - Slice 2 `agenda_application_test.dart` regresyonu.
- Allowed broad gates:
  - final source revision üzerinde bir kez full `flutter test --no-pub`;
  - `flutter analyze --no-pub`;
  - `git diff --check`, exact allowlist/protected-path ve schema/dependency/Backup-format/permission/platform diff kontrolleri;
  - clean linked-worktree debug APK build;
  - APK SHA-256 ve plugin/native inventory sanity check;
  - tam olarak bir authorized cihaz varsa data-preserving `adb install -r` ve cold-launch smoke.
- Reused evidence:
  - Slice 2 atomicity/idempotency: Issue #434 / PR #435 / merge `e9cadce44ffcf27c73ce616dfde1f870168d8044`;
  - Schema 13 / Backup format 1 closure: Issue #420 / PR #430 / merge `d80d24462b700ccc06af02889f6fe429b8d7fb5f`;
  - schema, backup, attachment, signing, permission ve release sözleşmeleri değişmezse tam backup/restore ve release/AAB gate tekrarlanmaz.
- Minimum physical-device acceptance: yalnız Issue gövdesindeki altı görünür sync yolu; uninstall, clear-data, restore veya gerçek kullanıcı verisini okuma/değiştirme yok.
- Retry budget: 1 primary run, en fazla 1 blocking correction; exact fix sonrası aynı başarısız işlem için en fazla 1 retry.
- Time budget: hedef 20–30 dakika, hard stop 45 dakikadır.

## Yetkili dosyalar

Production:

- `mobile/lib/features/reminders/reminder_detail_page.dart`

Test/support:

- `mobile/test/reminder_widget_test.dart`
- `mobile/test/support/fake_agenda_application.dart` — yalnız Slice 3 recording/result davranışı için dar biçimde gerekirse

Evidence/docs:

- `.cse/tasks/437_task.md`
- `.cse/results/437_result.md`
- `docs/project_decisions.md`
- uygun ise `learning/437_*`

## Uygulanacak iş

1. `sourceLogId` bulunan Reminder detayında Agenda source detailini read-only yükle.
2. Slice 2 mapping’iyle gerçek title/description/location difflerini hesapla ve eligibility koşullarını uygula.
3. Farklı alanları mevcut/yeni değer, kullanıcı dostu etiket ve checkbox ile confirmation yüzeyinde göster.
4. Yalnız seçili alanlarla fresh operation/source/target event UUID’leri ve mevcut snapshot revision’ları kullanarak `syncAgendaToReminder(...)` çağır.
5. Busy/double-tap guard, success/no-op/stale/failure ve güvenli reload davranışını uygula.
6. Source navigation/media/banner ve reminder’ın sync dışı alanlarını koru.
7. Issue’daki focused matris ile izinli geniş kapıları tamamla.

## Kapsam dışı ve stop koşulları

- Reminder → Agenda, toplu sync, source tarafında target seçimi veya `reminders.first` yok.
- Lifecycle mapping, re-link/reparent, semantic duplicate advisory, notification redesign veya attachment lifecycle değişikliği yok.
- Domain/application production dosyaları, schema/migration, dependency/lockfile, permission/platform veya release scripti değişmez.
- Slice 2 atomik sync contractını bypass eden UI workaround yapılmaz.
- Source/target revision olmadan mutation yapılmaz.
- Yeni sync alanı, lifecycle mapping veya allowlist dışı production edit gerekirse edit durur ve Issue’ya exact gerekçe yazılır.
- Açık docs-only PR #436 kapsam dışıdır ve değiştirilmez; Draft PR açılmadan önce repository coordination durumu yeniden kontrol edilir.

## Yayın yetkisi

- Intentional commit, normal push ve Draft PR: Issue tarafından yetkili.
- PR Ready: ChatGPT source review ve dar manuel cihaz acceptance PASS öncesinde yetkisiz.
- Merge: yalnız proje sahibinin açık talimatıyla.
- Force push/branch deletion: yasak.
- Post-merge local master sync: bu Issue içinde yapılmaz; merge sonrasında sonraki yetkili Codex çalışmasına bırakılır.
