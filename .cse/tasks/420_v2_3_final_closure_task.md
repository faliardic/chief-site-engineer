# Issue #420 — V2.3 final closure: attachment backup/restore + restart

## Yürütme kimliği

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Yetkili clean linked worktree:
  `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-420-v2-3-final-closure`
- Exact base / `origin/master`:
  `2308c3497f35ce52734131de36f4002934002958`
- Branch: `codex/issue-420-v2-3-final-closure`
- Codex modeli: `Codex / GPT-5` full model
- Reasoning: `Extra High`
- Seçim nedeni: schema-13 canonical attachment graph, Backup format-1,
  sentetik restore, restart persistence ve final mobile artifact kabulü birlikte
  veri bütünlüğü ve regresyon riski taşır.

## Bağlayıcı GitHub yetkisi

- Issue: `#420`
- Owner comment: `#issuecomment-5245458232`
- Bu task yalnız V2.3 final closure dilimidir; yeni ürün davranışı eklemez.

## Validation class

`data-integrity / backup-restore / restart-persistence / V2.3 closure`

## Changed contracts

İlk tercih production diff `0` ile şu mevcut sözleşmeleri executable kanıtla
kapatmaktır:

1. Bir canonical physical attachment ve birden çok contextual link Backup
   format-1 round-trip sonrasında identity/graph kaybı olmadan korunur.
2. Restored byte content, size, SHA-256, MIME ve güvenli relative path birebir
   korunur; duplicate physical veya SHA-only auto-merge oluşmaz.
3. Managed ve legacy-readable attachment path/provenance round-trip sonrasında
   korunur.
4. Ayrı temiz temp target restore sonrasında DB/application kapatılıp yeniden
   açıldığında physical/link graph, Agenda/Concrete ilişkileri ve integrity PASS
   kalır.
5. Mevcut restore recovery/fail-closed ve shared-physical archive semantics
   regresyonsuz kalır.

## Yetkili dosyalar

Tests — öncelikli mevcut:

- `mobile/test/mobile_backup_application_test.dart`
- `mobile/test/restore_recovery_application_test.dart`
- `mobile/test/managed_attachment_store_test.dart`
- `mobile/test/attachment_catalog_application_test.dart`
- gerekirse `mobile/test/agenda_application_test.dart`
- gerekirse `mobile/test/concrete_application_test.dart`
- gerekirse `mobile/test/app_database_test.dart`

Tests — dar yeni dosya:

- `mobile/test/attachment_backup_restore_test.dart`

Production — yalnız exact test gap kanıtlanırsa:

- `mobile/lib/application/mobile_backup_application.dart`
- `mobile/lib/application/restore_recovery_application.dart`
- `mobile/lib/platform/mobile_backup_gateway.dart`
- `mobile/lib/platform/managed_attachment_store.dart`
- zorunluysa attachment persistence ile doğrudan ilgili minimum
  storage/application dosyası; allowlist dışı production edit öncesinde
  Issue #420'ye exact gerekçe yazılır.

Evidence/docs:

- `.cse/tasks/420_v2_3_final_closure_task.md`
- `.cse/results/420_v2_3_final_closure_result.md`
- gerekirse `docs/project_decisions.md`
- V2.3 gerçekten closure-ready olduğunda owner-controlled scope durumuna göre
  `docs/v2/CSE_V2_SCOPE.md`.

## Test fixture ve restore güvenliği

- Round-trip yalnız synthetic/temp application root üzerinde çalışır.
- Temp source'ta physical + multi-link graph oluşturulur, backup alınır, ayrı
  temiz temp target'a restore edilir ve restored truth yeniden açılarak okunur.
- Gerçek kullanıcı DB/attachment/backup/report içeriği okunmaz veya değiştirilmez.
- Telefonda restore, uninstall, clear-data veya destructive cleanup yapılmaz.
- Original dirty V: checkout'ta reset/clean/stash/delete/overwrite yoktur.

## Focused acceptance

- schema 13 / Backup format 1;
- one physical + multi-link graph round-trip;
- exact restored bytes/hash/MIME/path/identity;
- no duplicate physical / no SHA auto-merge;
- restart/reopen persistence;
- managed + legacy-readable path coverage;
- restore recovery/fail-closed regressions;
- Agenda/Concrete shared-physical archive semantics regressions.

## Broad gates

Final source revision üzerinde:

- focused affected backup/restore/restart/attachment tests;
- `flutter test --no-pub` bir kez;
- `flutter analyze --no-pub` bir kez;
- `git diff --check` + exact allowlist/protected-path kontrolü;
- `flutter build apk --debug --no-pub`;
- schema 13 / Backup format 1 / dependency / permission / platform-config
  invariant kontrolleri;
- exactly one authorized device bağlıysa data-preserving `adb install -r` +
  cold launch/restart smoke;
- final APK içinde generated plugin registrant/runtime artifact completeness.

## Reused evidence

- PR #425 manual acceptance: explicit multi-link, shared physical retention,
  catalog/health ve restart davranışı.
- Issue #427 / merged `2308c3497f35ce52734131de36f4002934002958`:
  final Agenda photo save/share source.
- Issue #429: clean build ile generated plugin registrant provenance ve Android
  16 startup PASS; final closure APK'sında yeniden artifact completeness kontrolü
  yapılır.
- Değişmeyen schema 13, Backup format 1, permissions, dependency ve platform
  config kanıtları önceki V2.3 merged dilimlerinden yeniden kullanılabilir;
  bu task exact invariants ile drift olmadığını ayrıca kontrol eder.

## Minimum physical-device acceptance

Codex yalnız non-destructive artifact smoke çalıştırır:

- exactly one authorized device;
- data-preserving `adb install -r`;
- exact launcher cold start ve process-alive;
- force-stop/cold reopen ve yeniden process-alive;
- yeni startup crash/Samsung App Error yok.

PR source review PASS sonrası final kullanıcı kabulü ChatGPT kapısıdır: mevcut
Agenda/Concrete attachment, reused/shared link, cold reopen, Dosya Kataloğu ve
Dosya Sağlığı davranışı. Gerçek cihazda restore yapılmaz.

## Out of scope / stop conditions

- V2.4 veya sonraki V2 maddeleri;
- yeni media davranışı;
- #424 M4A / >20 MiB;
- #426 link öncesi preview;
- #427 save/share genişletmesi;
- Beton V2;
- AI / Bridge / Orchestrator / API;
- backup UI redesign;
- gerçek kullanıcı verisinde restore/cleanup;
- yeni dependency, permission, schema, Backup format veya platform değişikliği.

Schema/format/dependency/permission/platform değişikliği, gerçek kullanıcı data
inspection, destructive restore veya allowlist dışı production edit gerekirse
edit başlamadan stop-and-report yapılır.

## Budget

- Time budget: `N/A`.
- Run/retry budget: `N/A`.
- Kör tekrar yapılmaz; exact root-cause düzeltmesinden sonra yalnız ilgili gate
  tekrar edilir.

## Publication

- Completion evidence Issue #420'ye yazılır.
- Intentional commit + normal push + Draft PR yetkilidir.
- Ready yalnız ChatGPT source review + gerekli final physical restart acceptance
  PASS sonrası.
- Merge yalnız proje sahibinin açık onayıyla.
- Final PR merge + acceptance sonrası Issue #420 ve Epic #385 closure
  GitHub-native owner-controlled adımdır; bu task merge/closure yapmaz.
