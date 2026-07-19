# Issue #189 Görev Kaydı

## Yürütme

- Resmî repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Güvenli base: `ac929a7968543df3b756158826eed4959370431e`
- Branch: `codex/issue-189-mobile-backup-restore`
- Model: Codex standart full model
- Reasoning: Extra High
- Seçim nedeni: authenticated encryption, application-wide concurrency,
  fail-closed archive preflight, atomik file swap/rollback, schema migration ve
  notification reconciliation aynı veri güvenliği sınırında ele alınmaktadır.

## Yetkili kapsam

- `mobile/` altında shared operation coordinator, `.csebackup` format v1,
  encrypted backup, preflight, atomik restore/rollback ve Hafıza UI.
- Flutter unit/widget/integration testleri ve gerekli paket bağımlılıkları.
- Issue #189 dokümantasyonu, learning notu, changelog/roadmap/kararlar ve
  `.cse` factual kayıtları.

## Kabul kapıları

- Boş ve dolu fixture round-trip; bütün SQLite/event/attachment byte-hash
  eşitliği; farklı cihaz kökünde relative-path taşınabilirliği.
- Concurrent mutation exclusion, yanlış parola/tamper/path traversal/
  duplicate/unsupported/oversize/corrupt SQLite/foreign-key fail-closed reddi.
- Migration, swap ve bootstrap hata noktalarında eski verinin rollback ile
  korunması; notification reconciliation; restart/offline kalıcılık.
- 320–430 px UI, iki aşamalı restore onayı, input preservation ve double-tap
  engeli.
- Flutter analyze/unit/widget/integration, Android emülatör, debug APK,
  unsigned release AAB, iOS static, Python full suite, compileall, state JSON,
  `git diff --check` ve exact changed-file allowlist.

## Korunan sınırlar

- Gerçek kullanıcı verisi, `CSE_DATA_ROOT`, signing key veya secret kullanılmaz.
- `reports/`, `exports/.gitkeep`, mevcut ZIP ve ignored Flutter build/cache
  değiştirilmez veya stage edilmez.
- Cloud/Drive/iCloud, backup merge, masaüstü import, release hardening ve store
  submission başlatılmaz.
- Tek ordinary commit `Add mobile backup restore`; normal push; amend, rebase,
  force-push ve PR yoktur.
