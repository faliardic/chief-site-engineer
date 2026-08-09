# Issue #420 — V2.3 Managed Attachment Store sonucu

## Sonuç

- Validation class: `persistence / managed attachment store`
- Base: `c1b531c565ebacde9878809dfe2f50be1ec1bad6`
- Branch: `codex/issue-420-v2-3-managed-store`
- Mobile schema: `13` (değişmedi)
- Mobile backup formatı: `1` (değişmedi)
- Fiziksel cihaz kabulü: kullanıcıya görünür UX içermeyen bu dilimde bağlayıcı
  sözleşme gereği `N/A`
- Gerçek kullanıcı database/backup/attachment içeriğine erişim veya mutation:
  yapılmadı

Agenda ve Beton yeni attachment yazımları tek ortak
`DeviceManagedAttachmentStore` sözleşmesine delege edilir. Bootstrap iki
adapter'a aynı store örneğini verir. Yeni path yalnız
`managed/<attachmentId>.<ext>` olur; legacy `agenda/...` ve `concrete/...`
path'leri yerinde kalır ve common store tarafından okunur.

Ortak store:

- safe basename ve 20 MiB varsayılan limit uygular;
- JPEG, PNG, HEIC ve PDF byte signature'larını sniff eder;
- private attachment root containment ile absolute/traversal path'i reddeder;
- symlink ve non-regular component'i fail-closed reddeder;
- `managed-<attachmentId>.part` staging dosyasını flush sonrasında yeniden
  okuyup size/hash/MIME doğrular ve atomik rename ile finalize eder;
- failure compensation sırasında yalnız current operation staging/finalized
  artifact'ını temizler; mevcut/çakışan dosyayı silmez.

Salt-okunur reconciliation schema-13 metadata ve private root üzerinde şu
sonuçları ayrı raporlar: `healthy`, `missing_file`, `size_mismatch`,
`hash_mismatch`, `mime_mismatch`, `unsafe_path`, `broken_target`,
`cross_project_target`, `orphan_finalized_file`, `stale_staging_file` ve
`duplicate_legacy_candidate`. Yalnız exact managed staging pattern'i taranır;
`incoming_backups` ve unrelated staging ignore edilir. Reconciliation hiçbir
DB/file mutation, delete, adopt, relink, dedupe, rewrite veya move yapmaz ve
bootstrap sırasında otomatik çalışmaz.

## Focused doğrulama

- `flutter test --no-pub test/managed_attachment_store_test.dart
  test/attachment_reconciliation_application_test.dart`
  - **PASS — 6 test**
  - canonical path, dört MIME, legacy read, reread verification,
    operation-local cleanup, ayrı integrity sınıfları, traversal/absolute,
    symlink/non-regular ve tam reconciliation matrisi doğrulandı.
- `flutter test --no-pub test/managed_attachment_store_test.dart
  test/attachment_reconciliation_application_test.dart
  test/concrete_attachment_gateway_test.dart test/agenda_application_test.dart
  test/concrete_application_test.dart test/app_bootstrap_test.dart`
  - PR #422 source-review correction revision: **PASS — 58 test**
  - Agenda/Reminder, Beton, adapter ve shared bootstrap regressions PASS.

Yeni linked worktree ilk focused komutta ignore edilen `.dart_tool` metadata'sı
olmadığı için test kaynağına ulaşmadan durdu. Tracked source/lock değiştirilmeden
önceki yayımlanmış #420 worktree'sindeki aynı dependency metadata'sı ignore
edilen alana kopyalandı. İlk compile denemesinde iki `FileSystemEntityType` API
uyumsuzluğu bulundu; exact Dart API düzeltmesinden sonra focused suite PASS
oldu.

## Final geniş kapılar

- Final source `flutter test --no-pub`: **PASS — 459 test**
- Final source `flutter analyze --no-pub`: **PASS — No issues found**
- `git diff --check`: **PASS**
- Exact 14-file allowlist/protected path: **PASS**

İlk full-suite invocation yanlış kısa command timeout'u nedeniyle test sonucu
üretmeden kesildi; exact linked-worktree `flutter_tester` orphan process'i
doğrulanıp sonlandırıldı ve aynı source doğru timeout ile PASS oldu. Sonraki
tek satırlık partial-write compensation düzeltmesi source revision'ı
değiştirdiği için affected focused suite ve final-source full/analyze kapıları
yeniden çalıştırıldı.

## PR #422 source-review correction

`#issuecomment-5232544923` review blocker'ı için mevcut Concrete opsiyonel-MIME
inspect sözleşmesi korundu. Shared `inspect` API'si nullable MIME beklentisini
kabul eder ve MIME karşılaştırmasını yalnız beklenti non-null olduğunda yapar.
Concrete adapter null değeri değiştirmeden forward eder; JPEG fallback
kaldırıldı. MIME argümanı verilmeden inspect edilen PDF attachment'ın
`ConcreteAttachmentIntegrity.ok` kaldığını doğrulayan focused regression eklendi.

- Dar Concrete gateway suite: **PASS — 3 test**
- Etkilenen aggregate suite: **PASS — 58 test**
- Final full suite: **PASS — 459 test**
- Final analyze: **PASS — No issues found**

Correction commit/push SHA'sı, final diff/allowlist durumu ve PR state'i GitHub
Issue #420 correction evidence yorumunda publication sonrasında kaydedilir.

## Yeniden kullanılan merged kanıt

- PR #421 / merge `c1b531c565ebacde9878809dfe2f50be1ec1bad6`:
  schema-13 physical/link/event source-of-truth, Agenda/Beton canonical cutover
  ve backup format-1 compatibility.
- PR #418 / merge `50e97eedab9f77236e31051784d59045cbdb0d9b`:
  V2.3 attachment envanteri ve lifecycle/reconciliation sınırı.

## Çalıştırılmayan geniş kapılar

- APK/AAB/signing/store submission ve fiziksel cihaz çalıştırılmadı; bağlayıcı
  Issue yorumu bu görünür-UX içermeyen persistence diliminde bunları `N/A`
  tanımlar.
- Video/audio, multi-select, viewer/player ve kullanıcıya görünür
  reconciliation UX'i başlatılmadı.

## Güvenlik, kapsam ve bütçe

- Bütün source/test/doc değişiklikleri `#issuecomment-5232402995` exact
  allowlist'i içindedir.
- `app_database.dart`, backup/recovery production dosyaları, pubspec/lock,
  Android/release ve diğer protected path'ler değiştirilmedi.
- Legacy byte/path move, rename, dedupe veya metadata rewrite yapılmadı.
- Original dirty worktree yalnız salt-okunur Git kanıtıyla korunur; original
  untracked içerik enumerate/read edilmez.
- `device-backups/`, `reports/`, gerçek kullanıcı alanları ve eski #419
  worktree'si kullanılmadı.
- Elapsed-time ve retry/run-count budget bağlayıcı yetki uyarınca `N/A`dır.

## Publication durumu

Bu dosya final local gate kanıtını kaydeder. Commit SHA, push divergence ve
Draft PR bağlantısı Issue #420 completion yorumunda publication sonrasında
raporlanacaktır. Draft PR `Part of #420` içerir; Issue #420 kapanmaz.
