# Issue #187 Görev Kaydı

- Issue: `#187 Release 0.1 Mobil Beton Paketi`
- Base: `2ee2faf4c02889b35a6392f9359e11b5cc8b4b55`
- Branch: `codex/issue-187-mobile-concrete-pour-package`
- Model: standart full Codex
- Reasoning: Extra High
- Commit: `Add mobile concrete pour package`

## Bağlayıcı kapsam

- Mobil schema `4 → 5` ve eski mobil verinin atomik korunumu.
- Beton planı, checklist, mikser/irsaliye, numune, takip ve kapanış aggregate'i.
- Optimistic revision, no-op, explicit exception ve append-only event geçmişi.
- Beton kaynağına exact project/source ile bağlı reminder ve çift yönlü deep-link.
- Kamera/galeri/dosya, MIME/boyut/SHA-256, atomik finalize ve failure cleanup.
- 320–430 px mobil liste/detay/form, derived metraj/sayaç ve güvenli export.
- Flutter/iOS/Android/Python kalite kapıları, tek ordinary commit ve normal push.

## Korunan sınırlar

- Gerçek kullanıcı verisi, `CSE_DATA_ROOT`, signing key veya secret kullanılmaz.
- `reports/`, `exports/.gitkeep`, ZIP ve ignored Flutter build/cache korunur.
- Python production/schema/Backup/Günlük Çıktı formatları değiştirilmez.
- Release hardening, store submission ve genel PackageTemplate başlatılmaz.
