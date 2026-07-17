# Issue #167 Sonuç Kaydı — Saha Kabul Metrikleri ve Pilot Protokolü

## Sonuç

Issue #167 için gerçek şantiye kullanımındaki değer ve güvenilirliği ölçmeye
yarayan bağlayıcı saha kabul protokolü tamamlandı. Çalışma pilotu yürütmedi ve
gerçek saha ölçümü üretmedi; yalnız ölçüm sözleşmesini, boş kayıt şablonlarını,
stop/escalation kurallarını ve Faz 1 geçiş kapılarını tanımladı.

On metrik tanımlandı. Her metrik şu on beş zorunlu alanı içeriyor:

```text
metric_id, name, purpose, unit, numerator, denominator, data_source,
collection_method, sampling_rule, target, warning_threshold,
blocker_threshold, privacy_rule, owner, review_cadence
```

Metrikler; kayıt açma ve geri bulma süresi, doğrulanmış veri kaybı, kaçırılan
takip, attachment/hash bütünlüğü, Backup verify, clean restore, haricî araca
dönüş, scope/privacy ihlali ve ölçüm yeterliliğini kapsıyor. Süre metriklerinde
median ve nearest-rank p90 ile başarısızlık oranı ayrı tutuluyor.

## Üretilen karar ve kayıt yüzeyleri

- Ana sözleşme:
  `docs/167_field_acceptance_metrics_and_pilot_protocol.md`
- Günlük boş kayıt şablonu:
  `docs/pilot/field_pilot_daily_log_template.md`
- 7/30 günlük boş özet şablonu:
  `docs/pilot/field_pilot_summary_template.md`
- Ayrıntılı öğrenme notu:
  `learning/167_field_acceptance_metrics_and_pilot_protocol.md`
- Gün 0 preflight, 7 günlük ilk pilot ve 30 günlük doğrulama pilotu için exact
  örnekleme, eşik, sahiplik, inceleme sıklığı ve stop koşulları tanımlandı.
- Veri kaybı/corruption, privacy leak, yanlış scope çıktısı, verify/restore
  başarısızlığı, tekrarlayan attachment/hash sorunu, kritik kaçırılan takip,
  güvensiz workaround ve güvenilmez/eksik ölçüm blocker olarak bağlandı.
- Pilot ölçümü; süre, sayı, kategori, anonim olay kimliği ve sonuçla sınırlandı.
  Kayıt gövdesi, fotoğraf, kişi/telefon, proje hassas bilgisi ve attachment
  içeriği yasaklandı; telemetry/cloud eklenmedi.

## Doğrulama kanıtı

| Kontrol | Sonuç |
|---|---|
| `python -m pytest -rs` | `983 passed, 7 skipped in 20.37s` |
| Skip açıklaması | Windows ortamında symlink oluşturma ayrıcalığı bulunmayan yedi güvenlik testi; beklenen skip |
| `python -m compileall -q app scripts` | Başarılı |
| `python -m json.tool .cse/state/project_state.json > $null` | Başarılı |
| `git diff --check` | Başarılı |
| `git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml` | Boş |
| Metrik sözleşmesi | 10 metrikte 15 zorunlu alanın her biri tam |
| Pilot şablonları | Yalnız placeholder ve boş kayıt tabloları; gerçek saha ölçümü yok |
| `CSE_DATA_ROOT` | Unset; gerçek kullanıcı data root'una erişilmedi |
| `exports/` | Yalnız `.gitkeep` |
| `reports/` | Kullanıcıya ait iki untracked dosya korundu; içerikleri okunmadı, değiştirilmedi ve stage edilmedi |
| Ignored ZIP/cache | Korundu; stage edilmedi |

## Yayın durumu

- Branch: `codex/issue-167-field-acceptance-pilot-protocol`
- Base/master safe point:
  `cb344aded8d0b0d4f5ff340f08393f6dca06971a` (Issue #165 / PR #166)
- Commit mesajı: `Define field acceptance metrics and pilot protocol`
- Ordinary commit ve normal push: yetkili; bu kayıt oluşturulurken henüz
  yapılmadı.
- PR oluşturma: Codex için yasak.
- Push sonrası remote SHA ve kontrol özeti GitHub Issue #167 completion
  yorumuna eklenecek.
