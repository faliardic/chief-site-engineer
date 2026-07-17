# Issue #165 Sonuç Kaydı — Legacy Model Envanteri ve Deprecation Planı

## Sonuç

Issue #165'in read-only repository envanteri tamamlandı. Production model,
helper, repository, application, persistence, operation, web/CLI, script, test,
schema/format ve dokümantasyon yüzeyleri dört exact sınıfta kaydedildi:

```text
Aktif çekirdek
Dönüştürülecek
Legacy / arşivlenecek
Silme adayı
```

Doğrulanmış `Silme adayı` sayısı **0**'dır. İncelenen bütün legacy gruplarda en
az bir direct test/fixture, compatibility/provenance bağı veya eksik executable
replacement vardır. Hiçbir production/test/schema/migration/UI/route/CLI,
Backup/export formatı veya gerçek kullanıcı verisi değiştirilmedi; fiziksel
delete, rename veya move yapılmadı.

## Üretilen karar yüzeyleri

- Ana envanter ve kaldırma kapıları:
  `docs/165_legacy_model_inventory_and_deprecation_plan.md`
- Ayrıntılı öğrenme notu:
  `learning/165_legacy_model_inventory_and_deprecation_plan.md`
- Güncel roadmap/changelog/teknik karar/state aynaları yalnız Issue #165
  sonucu için senkronlandı.
- `app/models.py` dosyasındaki çalışan `FieldObservationRecord`, legacy
  prototip/helper zincirlerinden symbol/section seviyesinde ayrıldı.
- Migration/restore, Backup v1, Günlük Çıktı v1 ve managed attachment zinciri
  backward compatibility nedeniyle aktif çekirdek olarak korundu.
- Legacy handover helper'ının Proje Paketi verifier'ına rename edilemeyeceği;
  ADR-0003'e özgü yeni executable implementation gerektiği kaydedildi.

## Doğrulama kanıtı

| Kontrol | Sonuç |
|---|---|
| `python -m pytest -rs` | `983 passed, 7 skipped in 18.78s` |
| Skip açıklaması | Windows ortamında symlink oluşturma ayrıcalığı bulunmayan yedi güvenlik testi; beklenen skip |
| `python -m compileall -q app scripts` | Başarılı |
| `python -m json.tool .cse/state/project_state.json > $null` | Başarılı |
| `git diff --check` | Başarılı |
| `git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml` | Boş |
| `CSE_DATA_ROOT` | Unset; gerçek kullanıcı data root'una erişilmedi |
| `exports/` | Yalnız `.gitkeep` |
| `reports/` | Kullanıcıya ait iki untracked dosya korundu, okunmadı/değiştirilmedi/stage edilmedi |
| Ignored ZIP/cache | Korundu; stage edilmedi |

## Yayın durumu

- Branch: `codex/issue-165-legacy-inventory-deprecation-plan`
- Base/master safe point:
  `4d31200753d8c24cefbce949849be67d1683b887` (Issue #148 / PR #164)
- Commit mesajı: `Inventory legacy models and define deprecation gates`
- Ordinary commit ve normal push: yetkili; bu kayıt oluşturulurken henüz
  yapılmadı.
- PR oluşturma: Codex için yasak.
- Push sonrası remote SHA ve kontrol özeti GitHub Issue #165 completion
  yorumuna eklenecek.
