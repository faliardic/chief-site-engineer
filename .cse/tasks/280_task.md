# Issue #280 — README ve NotebookLM Güncel Durum Senkronizasyonu

## Yürütme kimliği

- Resmî repository:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse280-2e698b73b6`
- Issue:
  `#280`
- Yürütme yorumu:
  `5129897546`
- Exact base / remote master:
  `c72f6bc55fc658996a546d9833b85a2614b99327`
- Branch:
  `docs/issue-280-readme-notebooklm-current-state-sync`
- Model:
  current full Codex
- Reasoning:
  Extra High
- Gerekçe:
  README ve state repository truth senkronizasyonu ile legacy-step ve
  issue-era podcast kaynaklarının deterministik/geriye uyumlu üretimi birlikte
  doğrulanacaktır.
- Validation class:
  `documentation + deterministic developer tooling`

## İzolasyon kanıtı

- Ana worktree branch'i:
  `codex/issue-279-reminder-quick-earlier-time`.
- Ana worktree HEAD:
  `c72f6bc55fc658996a546d9833b85a2614b99327`.
- Ana worktree tracked değişiklik taşıyor; staging boş.
- Ana worktree'de branch switch, stash, reset, checkout, clean, commit veya
  Issue #279 dosya incelemesi yapılmayacaktır.
- Remote `master`, Issue #280 exact base ile eşittir.
- Unique temporary worktree exact base üzerinden oluşturuldu.
- Yeni worktree başlangıç tracked tree:
  temiz.
- Issue #279, PR #259, telefon/tablet, backup/report/stale-build dizinleri ve
  production source dosyaları dokunulmazdır.

## Değişen sözleşmeler

- Root ve mobile README yalnız merged ürün gerçeğini anlatır.
- Project state, legacy son numbered step ile current merged Issue safe point'i
  birbirinden ayırır.
- Podcast 001–035 değişmeden legacy `adim` kaynağı olarak kalır.
- Podcast 036, gerçek merged Issue #227–#277 dönemini ayrı `issue` range
  kimliğiyle başlatır.
- Generator hem `adim` hem `issue` notlarını deterministic ve geriye uyumlu
  üretir.
- Issue aralığı contiguous history sayılmaz; yalnız mevcut canonical
  `## Issue #NNN` CHANGELOG bölümleri kullanılır.
- Rolling source ve manifest metadata'sı yalnız generator tarafından üretilir.

## Exact allowlist

1. `.cse/tasks/280_task.md`
2. `README.md`
3. `mobile/README.md`
4. `.cse/state/project_state.json`
5. `docs/podcast_notes/README.md`
6. `docs/podcast_notes/036_issue_227_277_notebooklm_podcast_notu.md`
7. `docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md`
8. `docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md`
9. `docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json`
10. `scripts/build_notebooklm_podcast_source.py`
11. `tests/test_notebooklm_podcast_source.py`
12. `CHANGELOG.md`
13. `ROADMAP.md`
14. `docs/project_decisions.md`
15. `docs/280_readme_notebooklm_current_state_sync.md`
16. `learning/280_readme_notebooklm_current_state_sync.md`
17. `.cse/results/280_result.md`

Allowlist dışı ihtiyaçta edit yapılmadan fail-closed durulur.

## Factual inventory planı

- Mobil version, schema, backup formatı, Android API/application ID ve
  timezone değerleri source/config/migration dosyalarından salt okunur
  doğrulanır.
- Merged Issue/PR/safe-point gerçekleri CHANGELOG, result kayıtları, GitHub ve
  exact base commit'iyle çapraz doğrulanır.
- Mevcut generator, test, podcast protokolü ve project-state consumer'ları
  edit öncesi envanterlenir.

## Doğrulama sırası

1. Focused NotebookLM tests.
2. Generator run 1.
3. Rolling source + manifest snapshot.
4. Generator run 2 ve byte-for-byte determinism.
5. Manifest/project-state JSON parse ve consistency.
6. README factual assertions ve stale-token taraması.
7. Full Python suite.
8. `git diff --check`, exact allowlist ve production-path diff boşluğu.

## Geniş kapılar ve yeniden kullanılan kanıt

- Full Python suite:
  generator/test değişikliği nedeniyle yetkilidir.
- Flutter test/analyze, APK/AAB build, install, ADB ve cihaz smoke:
  çalıştırılmaz.
- Schema `10`, backup formatı `1`, mobil release/package ve cihaz kabulü:
  Issue #277 / PR #278 / merge
  `c72f6bc55fc658996a546d9833b85a2614b99327` kanıtından yeniden kullanılır;
  production davranışı değişmez.

## Retry ve süre bütçesi

- Primary technical run:
  `1`.
- Blocking correction:
  en fazla `1`.
- Aynı başarısız operasyon:
  exact düzeltme sonrası en fazla `1` retry.
- Hedef:
  `10–15 dakika`.
- Hard stop:
  `25 dakika`.

## Kapsam dışı ve stop koşulları

- Production Python/Flutter source veya executable product behavior.
- Podcast 001–035 içerik değişikliği.
- Issue #279 resume/değişiklikleri.
- PR #259 mutation.
- Telefon/tablet/build/install/ADB.
- Backup/report/stale-build kullanıcı dizinleri.
- Ready, merge, Issue closure veya branch deletion.
- Allowlist dışı ihtiyaç, test/determinism/JSON/full-suite failure veya
  repository truth çelişkisinde fail-closed durulur.

## Yayın yetkisi

Bütün kapılar PASS ise:

- tek ordinary completion commit;
- normal push;
- `master` hedefli Draft PR;
- Issue ve PR'a factual kanıt yorumu;
- ardından dur.
