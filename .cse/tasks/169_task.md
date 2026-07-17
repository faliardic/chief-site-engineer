# Issue #169 Görev Kaydı — Owner-only Güvenlik ve Veri Sahipliği Tehdit Modeli

## Yerel ve Git başlangıcı

- Resmî yerel repo:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen ve doğrulanan base:
  `9036cee5524aa91ff1e9df92b538c4a7068c87ee`
- Branch: `codex/issue-169-owner-security-threat-model`
- Başlangıçta `master = origin/master`, divergence `0 0`.
- Kullanıcıya ait untracked `reports/` dosyaları korunur; okunmaz, değiştirilmez
  ve stage edilmez.

## Codex seçimi

- Model: selector'da görünen `standart full Codex`
- Reasoning: `High`
- Neden: mevcut local-first MVP'nin gerçek güvenlik sınırını, veri sahipliğini,
  loopback/LAN/public erişim risklerini ve Faz 12 implementation kapılarını
  production davranışı değiştirmeden bağlayan çok dosyalı documentation-only
  tehdit modeli çalışması.

## Amaç

CSE'nin tek sahibi olan şantiye şefi için mevcut varlıkları, trust boundary'leri,
aktörleri, tehdit senaryolarını, mevcut kontrolleri, açık gap'leri, detection ve
incident response yollarını bağlayıcı ADR ile tanımlamak. Veri sahipliği,
output confidentiality ve pilot/ürün stop kriterlerini açıklaştırmak; gelecek
security implementation işlerini executable acceptance kapılarıyla ayırmak.

Bu Issue güvenlik özelliği uygulamaz. Auth, app lock, encryption, secure session,
device trust, malware scanning, signed update veya cloud security varmış gibi
gösterilmez.

## Yetkili dosyalar

- `docs/adr/ADR-0004-owner-only-security-and-data-ownership-threat-model.md`
- `learning/169_owner_only_security_and_data_ownership_threat_model.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/169_task.md`
- `.cse/results/169_result.md`

## Yapılacak iş

1. Current MVP security posture'u abartısız ve kısa beyanla sabitle.
2. Asset inventory'de owner, confidentiality, integrity, availability,
   source-of-truth ve recovery yolunu tanımla.
3. En az on bir trust boundary ile actor/threat source sınıflarını çiz.
4. Zorunlu tehditlerin her birini on yedi alanlı scenario sözleşmesiyle yaz.
5. `low | medium | high | critical` risk sözlüğünü ve scoring yöntemini bağla.
6. Critical/high riskleri current control, gap, detection, immediate response,
   future mitigation, owner, target phase ve acceptance evidence ile eşle.
7. Veri sahipliği, scope/output leakage, artifact confidentiality, local web ve
   loopback/LAN/public sınırlarını bağlayıcı kıl.
8. Incident response, pilot/ürün stop kriterleri ve Faz 12 implementation
   haritasını executable kapılarla yaz.
9. Öğrenme, roadmap, changelog, decisions, state ve result aynalarını güncelle.

## Yasak kapsam

- Production Python, test, schema, migration, persistence, UI, route, CLI,
  session, app lock, firewall, Backup/Günlük Çıktı formatı değiştirilmez.
- ADR-0001/0002/0003 değiştirilmez.
- Public/LAN penetration veya exposure testi yapılmaz; server public interface
  üzerinde açılmaz.
- Gerçek kullanıcı data root'una, gerçek backup'a veya gerçek saha içeriğine
  erişilmez.
- Auth, encryption, signed update, malware scan, telemetry, cloud veya sync
  implementation'ı eklenmez.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` değiştirilmez.
- Reset, clean, stash, amend, rebase, force-push ve branch deletion yapılmaz.

## Zorunlu doğrulamalar

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml
git diff --name-status 9036cee5..HEAD
git status --short --branch
git status --ignored --short --untracked-files=all
```

Ayrıca yalnız sekiz yetkili dosyanın değiştiği, delete/rename olmadığı,
network/public exposure testi yapılmadığı, `exports/` içinde yalnız `.gitkeep`
bulunduğu, `CSE_DATA_ROOT` değerinin unset kaldığı ve kullanıcı dosyalarının
korunduğu doğrulanır.

## Git ve yayın izinleri

- Tek ordinary commit: yetkili.
- Commit mesajı:
  `Define owner-only security and data ownership threat model`
- Normal push: yetkili.
- Amend/rebase/force-push: yasak.
- PR oluşturma: Codex için yasak.
- Merge ve branch silme: yasak.
- Completion evidence: push sonrasında GitHub Issue #169 yorumuna eklenir.
- Post-merge sync: Bu çalışma içinde yapılmaz; sonraki yetkili Codex görevine
  bırakılır.
