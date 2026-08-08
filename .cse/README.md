# CSE Repository Handoff Protocol

Bu dizin ChatGPT, GitHub, Codex ve proje sahibi arasındaki repository-native iş aktarım katmanıdır.

## Aktif ürün yürütmesi

- Kalıcı ürün ilkeleri: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- Aktif V2 kapsamı: `docs/v2/CSE_V2_SCOPE.md`
- Aktif sıra: `ROADMAP.md`
- Parent ürün Epic'i: GitHub Issue `#385`
- Machine state: `.cse/state/project_state.json`

Tarihsel Step/Adım dosyaları yeniden adlandırılmaz. Yeni işler Issue numarasıyla yürür.

## Standart akış

1. GitHub Issue kullanıcı problemini, V2 maddesini ve kabul sınırını tanımlar.
2. Aynı anda yalnız bir production implementation Issue aktiftir.
3. Yerel execution gerekiyorsa resmî repository kullanılır:

   `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

4. Editten önce `AGENTS.md` içindeki pre-read sırası uygulanır.
5. Local `master`, `origin/master` ile fast-forward ve divergence `0 0` olacak şekilde doğrulanır.
6. Branch yeni iş için `codex/issue-<issue_no>-<slug>`, docs-only iş için `docs/issue-<issue_no>-<slug>` biçimindedir.
7. `.cse/tasks/<issue_no>_task.md` yalnız current Issue yetkisini yansıtır.
8. Scope dışı kullanıcı değişikliği varsa reset/clean/stash/silme yapılmadan durulur.
9. Değişen sözleşmeye uygun minimum yeterli doğrulama uygulanır.
10. `.cse/results/<issue_no>_result.md` factual execution kanıtını yazar.
11. Commit/push/Draft PR yalnız Issue yetkisiyle yapılır.
12. Merge proje sahibinin kararındadır.
13. Merge sonrası sonraki işe başlamadan local `master` yeniden fast-forward edilir.

## Kaynak rolleri

- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`: kalıcı ürün amacı ve veri ilkeleri
- `docs/v2/CSE_V2_SCOPE.md`: current V2 ürün kapsamı
- `ROADMAP.md`: current V2 yürütme sırası
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`: Git/GitHub/Codex güvenliği
- `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`: doğrulama genişliği ve bütçesi
- current GitHub Issue: aktif teknik kapsam
- `.cse/tasks/`: yetkili execution sözleşmesi
- `.cse/results/`: factual execution sonucu
- `.cse/state/project_state.json`: son merged/finalized küçük machine-readable durum

README, stale state, eski Epic, Orchestrator/Bridge/Work Mode kayıtları, ZIP veya sohbet hafızası current GitHub + V2 kapsam gerçeğini override edemez.

## V2 görev minimumu

Her production Issue en az şunları belirtir:

- Parent Epic `#385`
- V2 item ve wave
- Depends on
- validation class
- changed contracts
- exact allowed paths
- schema impact
- migration impact
- backup compatibility impact
- attachment impact
- notification impact
- focused tests
- allowed broad gates
- physical-device / field acceptance
- retry budget
- time budget
- out of scope
- stop conditions

## Güvenlik

- Gerçek kullanıcı data root'u açık Issue yetkisi olmadan okunmaz/değiştirilmez.
- Ignored ZIP, `device-backups/`, `reports/` ve kullanıcı artifact'ları otomatik temizlenmez veya stage edilmez.
- Migration eski kaydı sessizce kaybedemez.
- Attachment kimliği ve source linkleri korunur.
- Kullanıcı onayı olmadan resmî karar, otomatik kapanış veya kapsam dönüşümü yapılmaz.
- Feature Issue içinde toolchain/release sorunu sessizce kapsam genişletilerek çözülmez.

## Adlandırma

Yeni dönem:

- Issue: `#NNN — <purpose>`
- Branch: `codex/issue-NNN-<slug>` veya docs için `docs/issue-NNN-<slug>`
- Task: `.cse/tasks/NNN_task.md`
- Result: `.cse/results/NNN_result.md`
- Draft PR: Issue amacını özetleyen kısa başlık

Legacy `Step NNN` / `step-NNN-*` kayıtları tarihsel kanıt olarak korunur.

## İnsan kontrolü

Bu protokol transport ve doğrulama disiplinini standardize eder; ürün kapsamı, merge, release ve kullanıcı verisi üzerinde nihai karar proje sahibindedir.
