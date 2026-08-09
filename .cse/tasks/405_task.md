# Issue #405 — V2.1g migration / backup-restore / field acceptance closure

- Issue: `#405`
- Parent Epic: `#385`
- Previous child: `#402` / PR `#404`
- Official repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Linked worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-405`
- Exact base: `origin/master` / `7d7e824a1c351f81338ba9c437940920c20a3542`
- Branch: `codex/issue-405-v2-1g-migration-backup-field-acceptance`
- Codex model: current strongest full Codex model
- Reasoning: `Extra High`; migration, restore, data-integrity ve backward-compatibility kapanışı yüksek veri kaybı/regresyon riski taşıyor.
- Validation class: `persistence + backup/restore + field acceptance`.

## Changed contracts

- Yeni ürün davranışı eklenmez; V2.1 schema 10→11 migration, schema-11 invariants, backup/restore round-trip, legacy text preservation ve stable Mahal link preservation executable kanıtla kapatılır.
- Gap yoksa production source değişmez.
- Gap kanıtlanırsa production edit öncesinde exact gap Issue #405 yorumuna yazılır ve yalnız Issue allowlist'indeki dar düzeltme uygulanır.

## Authorized paths

- `.cse/tasks/405_task.md`
- `.cse/results/405_result.md`
- mevcut/yeni migration, backup/restore ve schema invariant testleri
- representative Project lifecycle / ProjectLocation / Agenda / Reminder / Concrete stable-location regression testleri
- Kanıtlanmış dar gap halinde yalnız:
  - `mobile/lib/storage/app_database.dart`
  - `mobile/lib/application/mobile_backup_application.dart`
  - `mobile/lib/application/restore_recovery_application.dart`
  - doğrudan ilgili testler

## Validation contract

- Focused migration + backup/restore testleri.
- Representative V2.1 stable-location regressions.
- `git diff --check`.
- Production source değişirse ayrıca bir kez full `flutter test --no-pub`, `flutter analyze --no-pub` ve gerekirse `flutter build apk --debug`.
- Değişmeyen signing/AAB/ARM64/16 KiB/release/background/reboot kanıtları yeniden kullanılır.

## Physical-device acceptance

- Exactly one authorized physical Android device.
- Replace-install only; uninstall, clear-data veya destructive restore yok.
- Mevcut data ile uygulama açılışı, Proje/Mahal Kataloğu ve mevcut Agenda/Reminder/Concrete kayıtlarında crash-free read/navigation.
- Stable-linked veya legacy text-only kayıt cihazda yoksa ilgili alt senaryo `N/A`.
- Test verisi kaydı veya gerçek kullanıcı datası mutation'ı yok.
- Manuel kabul gerekirse adımlar kullanıcıya sohbette verilir; sonuç GitHub Issue'ya yazılır.

## Reused evidence

- V2.1a-f merged Project identity, schema-11 cross-project triggers, ProjectLocation lifecycle/catalog ve stable-location application/UI contracts.
- Backup format 1, application/package ID, signing, ARM64/16 KiB, permission/privacy, background/reboot ve release contracts; bu görev ilgili source'u değiştirmedikçe tekrar gate çalıştırılmaz.

## Retry / time budget

- Primary run: 1.
- Blocking correction: en fazla 1.
- Exact fix sonrası aynı başarısız işlem: en fazla 1 retry.
- Hedef: 45 dakika.
- Hard stop: 75 dakika.

## Explicit out of scope / stop

- Schema 12, backup format bump, downgrade, automatic/fuzzy legacy backfill/canonicalization.
- Agenda/Reminder/Concrete UI redesign, Puantaj adoption, V2.2, Attachment V2, map/spatial model.
- Release/signing/workflow/toolchain işi ve permanent delete.
- Destructive restore, uninstall, clear-data veya kullanıcı verisi mutation'ı.
- Bu ihtiyaçlardan biri çıkarsa scope genişletmeden dur ve Issue #405'e exact blocker yaz.

## Publication

- Bütün authorized local ve field gates PASS olmadan commit/push yok.
- PASS sonrasında normal push + Draft PR yetkili.
- Ready/merge yapılmaz; V2.2 production implementation başlatılmaz.
- Ayrıntılı blocker/completion evidence GitHub Issue #405 yorumuna yazılır; sohbet yalnız yorum referansı taşır.
- Post-merge sync bu görevde yapılmaz.
