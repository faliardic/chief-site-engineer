# Issue #145 Görev Kaydı — Tek Hafıza ve Kayıt Kapsamı ADR'si

## Çalışma bağlamı

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan base commit: `c449762cbcc5685017d3b2f2d0292a2b039cae53`
- Başlangıç `master` / `origin/master`: `c449762cbcc5685017d3b2f2d0292a2b039cae53`
- Başlangıç divergence: `0 0`
- Branch: `codex/issue-145-single-memory-scope-adr`
- Bağlayıcı execution Epic: Issue #127
- Bağlayıcı phase Epic: Issue #128
- Ürün Epic'i: Issue #105
- Saha Takibi Epic'i: Issue #97
- Codex modeli: selector'da görünen güncel standart full Codex modeli
- Reasoning: `High`

## Amaç

Şantiye şefine ayrı kişisel ve resmî uygulama dünyaları göstermeden bütün kayıt
türlerini tek **Hafıza** deneyiminde buluşturan; buna karşılık paylaşım ve çıktı
güvenliği için `private | project` kapsamını proje bağlantısından, kayıt türünden
ve kullanıcı rolünden ayıran bağlayıcı ADR'yi oluşturmak.

## Yetkili dosyalar

- `docs/adr/ADR-0001-single-memory-and-record-scope.md`
- `learning/145_single_memory_and_record_scope_adr.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/145_task.md`
- `.cse/results/145_result.md`

## Karar kapsamı

1. Tek Hafıza UX ve kayıt türü badge/etiket sınırı.
2. `private | project` kapsamının erişim rolü değil çıktı/paylaşım kapsamı
   olduğu.
3. Project bağlantısının tek başına kapsam değiştirmediği.
4. Mevcut observation'ın `project`; follow-up ve routine kayıtlarının `private`
   başlangıç/backfill anlamı.
5. `private -> project` için açık kullanıcı işlemi, revision ve append-only event
   gerekliliği.
6. `project -> private` için kayıt türü ve publication/reference durumuna bağlı
   fail-closed kurallar.
7. Backup, Hafızayı İndir ve Proje Paketi çıktı sınırları.
8. Mevcut daily export takip/rutin izolasyonunun aynen korunması.
9. Terminoloji, migration/compatibility, güvenlik, reddedilen alternatifler ve
   sonraki Issue sınırları.
10. Sonraki implementation görevleri için executable acceptance matrisi.

## Yasak kapsam

- Production Python, test, template, CSS, schema, migration, requirements,
  workflow, backup veya export formatı değiştirilmez.
- Scope uygulanmış veya migrate edilmiş gibi gösterilmez.
- Tek-tablo migration, hard validation, AI mutation, auth, role, tenant veya
  otomatik kapsam dönüşümü eklenmez.
- Mevcut observation/follow-up/routine davranışı değiştirilmez.
- Gerçek kullanıcı `CSE_DATA_ROOT` yoluna erişilmez.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` değiştirilmez.
- Reset, clean, stash, amend, rebase, force-push, branch deletion ve kullanıcı
  dosyası silme/taşıma/üzerine yazma yapılmaz.

## Zorunlu doğrulamalar

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml
```

Ayrıca yalnız yetkili dosyaların değiştiği, `exports/` içinde yalnız
`.gitkeep` bulunduğu, `reports/` ve ignored ZIP/cache'in korunduğu ve gerçek
`CSE_DATA_ROOT` kullanılmadığı doğrulanır.

## Git ve yayın izinleri

- Tek ordinary commit: yetkili.
- Commit mesajı: `Define single memory and record scope ADR`
- Normal push: yetkili.
- Amend/rebase/force-push: yasak.
- PR oluşturma: Codex için yasak.
- Merge ve branch silme: yasak.
- Completion evidence: push sonrasında GitHub Issue #145 yorumuna eklenir.
