# Issue #148 Görev Kaydı — Çıktı Aileleri Ayrım ADR'si

## Çalışma bağlamı

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan base commit: `8fb95811a2e55375081217470e90d7e8d385e8b2`
- Başlangıç `master` / `origin/master`: `8fb95811a2e55375081217470e90d7e8d385e8b2`
- Başlangıç divergence: `0 0`
- Branch: `codex/issue-148-output-family-separation-adr`
- Bağlayıcı execution Epic: Issue #127
- Bağlayıcı phase Epic: Issue #128
- Ürün Epic'i: Issue #105
- Saha Takibi Epic'i: Issue #97
- Ön koşullar: ADR-0001 ve ADR-0002; Issue #147 / PR #159 merge edildi
- Codex modeli: `standart full Codex`
- Reasoning: `High`
- Seçim gerekçesi: Değişiklik yalnız dokümantasyon, karar kaydı ve factual
  state senkronizasyonudur. High reasoning; kapsam, manifest, verifier,
  backward compatibility ve gizlilik kararlarını üç farklı çıktı ailesi için
  çelişkisiz tanımlamak amacıyla seçildi.

## Amaç

`Backup`, `Hafızayı İndir` ve `Proje Paketi` çıktılarını amaç, veri kapsamı,
format/version namespace'i, manifest, checksum, doğrulama, gizlilik ve kullanıcı
beklentisi bakımından birbirinden kesin biçimde ayıran ADR'yi oluşturmak;
mevcut `Günlük Çıktı` sözleşmesinin bu üç aileden farkını kaydetmek.

## Yetkili dosyalar

- `docs/adr/ADR-0003-backup-memory-download-project-package.md`
- `learning/148_backup_memory_download_project_package_adr.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/148_task.md`
- `.cse/results/148_result.md`

## Karar kapsamı

1. Backup'ın eksiksiz felaket kurtarma ve desteklenen sürümlerde birebir restore
   amacı; filtreli/kısmi backup yasağı.
2. Hafızayı İndir'in bütün owner hafızasını insan ve makine tarafından
   okunabilir kişisel arşiv olarak taşıması; restore formatı olmaması.
3. Proje Paketi'nin yalnız seçili proje ve `scope=project` kayıtlar için
   paylaşılabilir teslim/rapor çıktısı olması.
4. Mevcut kısa dönemli, tarih/proje odaklı Günlük Çıktı ile daha geniş Proje
   Paketi ayrımı.
5. Dört bağımsız format/version namespace'i ve manifest minimum alanları.
6. Deterministic entry sırası, checksum kapsamı ve paket üretim/verification
   sınırı.
7. Backup, Hafızayı İndir ve Proje Paketi verifier sorumluluklarının ayrılması;
   source mutation/sessiz repair yasağı.
8. Backward compatibility ve bilinmeyen/eksik kanıtta fail-closed davranış.
9. ADR-0001 scope ve ADR-0002 read-model tüketici sınırlarıyla private leakage
   koruması.
10. Encryption/key recovery'nin mevcut ve gelecekteki sınırı; kesin kullanıcı
    sözlüğü, reddedilen alternatifler ve executable acceptance matrisi.

## Yasak kapsam

- Production Python, test, schema, migration, persistence, template, CSS,
  requirements, workflow, backup veya export formatı değiştirilmez.
- Yeni format, manifest, verifier, CLI, web route veya UI uygulanmaz.
- ADR-0001 ve ADR-0002 kararları değiştirilmez.
- MemoryIndex implementation, scope migration/backfill, encryption, auth, role,
  tenant veya cloud sync eklenmez.
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
- Commit mesajı: `Define backup memory download and project package ADR`
- Normal push: yetkili.
- Amend/rebase/force-push: yasak.
- PR oluşturma: Codex için yasak.
- Merge ve branch silme: yasak.
- Completion evidence: push sonrasında GitHub Issue #148 yorumuna eklenir.
- Post-merge sync: bu görevde yapılmaz; merge sonrasında sonraki gerekli Codex
  çalışmasının başında `master` fast-forward edilir.
