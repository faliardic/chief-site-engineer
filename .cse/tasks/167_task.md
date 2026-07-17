# Issue #167 Görev Kaydı — Saha Kabul Metrikleri ve Pilot Protokolü

## Çalışma bağlamı

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan base commit: `cb344aded8d0b0d4f5ff340f08393f6dca06971a`
- Başlangıç `master` / `origin/master`: `cb344aded8d0b0d4f5ff340f08393f6dca06971a`
- Başlangıç divergence: `0 0`
- Branch: `codex/issue-167-field-acceptance-pilot-protocol`
- Bağlayıcı execution Epic: Issue #127
- Bağlayıcı phase Epic: Issue #128
- Ürün Epic'i: Issue #105
- Saha Takibi Epic'i: Issue #97
- Ön koşul: Issue #165 / PR #166 merge edildi
- Codex modeli: `standart full Codex`
- Reasoning: `High`
- Seçim gerekçesi: Gerçek saha kullanımını ölçülebilir kabul kapılarına
  bağlayan, 7 ve 30 günlük pilotlarda yanlış veri, muğlak başarı ölçütü ve
  private/project sızıntısı riskini önleyen çok dosyalı documentation-only
  protokol çalışmasıdır.

## Amaç

CSE'nin gerçek şantiye kullanımında değer ve güvenilirlik üretip üretmediğini
ölçmek için zorunlu metrik sözlüğünü, veri minimizasyonunu, Gün 0 preflight'ı,
7 günlük ilk pilotu, 30 günlük doğrulama pilotunu, stop/escalation kurallarını
ve Faz 1 geçiş kapılarını bağlayıcı ve tekrarlanabilir biçimde tanımlamak.

Bu Issue gerçek pilotu yürütmez ve gerçek saha ölçümü kaydetmez.

## Yetkili dosyalar

- `docs/167_field_acceptance_metrics_and_pilot_protocol.md`
- `docs/pilot/field_pilot_daily_log_template.md`
- `docs/pilot/field_pilot_summary_template.md`
- `learning/167_field_acceptance_metrics_and_pilot_protocol.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/167_task.md`
- `.cse/results/167_result.md`

## Yapılacak iş

1. Kayıt açma ve geri bulma sürelerini median/p90 ve failure'larla tanımla.
2. Veri kaybı, kaçırılan takip, attachment/hash bütünlüğü, Backup verify/clean
   restore ve haricî araca dönüş metriklerini exact alan sözleşmesiyle yaz.
3. Her metrik için numerator, denominator, source, collection, sampling,
   target, warning, blocker, privacy, owner ve cadence belirle.
4. Gün 0, 7 günlük ve 30 günlük protokolü tekrarlanabilir adımlara bağla.
5. Günlük ve summary şablonlarını gerçek kayıt gövdesi toplamadan kullanılabilir
   hazırla.
6. Stop/blocker, incident escalation, başarısız/eksik ölçüm ve Faz 1 geçiş
   kapılarını açıklaştır.
7. Pilotun yürütülmediğini ve hedeflerin ilk kabul eşikleri olduğunu kaydet.

## Yasak kapsam

- Production Python, test, schema, migration, persistence, template, static,
  route, CLI, Backup/Günlük Çıktı formatı değiştirilmez.
- Telemetry, analytics, otomatik timer, background job, notification, cloud
  gönderimi veya yeni runtime davranışı eklenmez.
- ADR-0001/0002/0003 değiştirilmez.
- Gerçek pilot yürütülmez; gerçek kayıt gövdesi, fotoğraf, dosya, kişi/proje
  hassas bilgisi veya gerçek saha ölçümü commit edilmez.
- Gerçek kullanıcı `CSE_DATA_ROOT` yoluna erişilmez.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` değiştirilmez.
- Reset, clean, stash, amend, rebase, force-push ve branch deletion yapılmaz.

## Zorunlu doğrulamalar

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml
git diff --name-status cb344ade..HEAD
git status --short --branch
git status --ignored --short --untracked-files=all
```

Ayrıca yalnız on yetkili dosyanın değiştiği, delete/rename olmadığı, pilot
şablonlarında gerçek ölçüm bulunmadığı, `exports/` içinde yalnız `.gitkeep`
bulunduğu, `reports/` ve ignored ZIP/cache'in korunduğu ve `CSE_DATA_ROOT`
değerinin unset kaldığı doğrulanır.

## Git ve yayın izinleri

- Tek ordinary commit: yetkili.
- Commit mesajı: `Define field acceptance metrics and pilot protocol`
- Normal push: yetkili.
- Amend/rebase/force-push: yasak.
- PR oluşturma: Codex için yasak.
- Merge ve branch silme: yasak.
- Completion evidence: push sonrasında GitHub Issue #167 yorumuna eklenir.
- Post-merge sync: Bu çalışma içinde yapılmaz; sonraki yetkili Codex görevine
  bırakılır.
