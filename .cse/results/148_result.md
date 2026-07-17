# Issue #148 Sonuç Kaydı — Çıktı Aileleri Ayrım ADR'si

## Sonuç özeti

Backup, Hafızayı İndir, Proje Paketi ve mevcut Günlük Çıktı; amaç, kapsam,
format/version namespace'i, manifest, checksum, verifier, backward
compatibility, privacy ve kullanıcı beklentisi bakımından dört ayrı artifact
ailesi olarak kesinleştirildi.

Çalışma yalnız yetkili documentation/state/task/result dosyalarını değiştirdi.
Production Python, test, schema, migration, persistence, UI, route, CLI,
backup/export wire formatı ve gerçek kullanıcı verisi değiştirilmedi.

## Başlangıç repository kanıtı

- Resmî yerel yol: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan repository root:
  `V:/1_PROJECTS/2_ACTIVE/Python/chief-site-engineer`
- `origin/master` fetch sonrasında local `master` fast-forward-only kontrolüyle
  doğrulandı.
- Senkronize local `master`:
  `8fb95811a2e55375081217470e90d7e8d385e8b2`
- Senkronize `origin/master`:
  `8fb95811a2e55375081217470e90d7e8d385e8b2`
- Master divergence: `0 0`
- Base commit, Issue #147 / PR #159 merge commit'idir.
- Issue branch'i: `codex/issue-148-output-family-separation-adr`
- Branch tam olarak belirtilen base commit'ten oluşturuldu.
- Başlangıçta yalnız Issue tarafından korunması istenen untracked `reports/`
  vardı; beklenmeyen tracked veya staged proje değişikliği yoktu.

## Değişen yetkili dosyalar

- `docs/adr/ADR-0003-backup-memory-download-project-package.md`
- `learning/148_backup_memory_download_project_package_adr.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/148_task.md`
- `.cse/results/148_result.md`

Yetki listesi dışında proje dosyası değiştirilmedi.

## Kabul edilen bağlayıcı kararlar

### Backup

- Backup'ın tek amacı eksiksiz felaket kurtarma ve desteklenen sürümlerde
  doğrulanmış Restore'dur.
- Bütün `private` ve `project` source kayıtları, append-only event geçmişi,
  archive durumu ve managed attachment'lar alınır.
- Tarih, proje, tür veya scope filtresiyle kısmi Backup üretilemez.
- Attachment eksik/tampered/unsafe ise uyarılı eksik artifact yerine fail-closed
  hata verilir.
- Restore yalnız Backup'ı Doğrula; manifest/entry/checksum, SQLite integrity,
  migration/count, attachment reconciliation ve repository kontrollerini
  geçtikten sonra yeni hedefte uygulanabilir.
- Mevcut Backup format v1, exact manifest, restore allowlist `(2, 3, 4)` ve
  production davranışı değiştirilmedi.

### Hafızayı İndir

- Bütün owner hafızasının insan ve makine tarafından okunabilir kişisel
  arşividir.
- Bütün desteklenen kayıt türleri, iki scope, project/status/revision/archive,
  source içerik, event geçmişi, attachment inventory ve doğrulanmış managed
  attachment byte'ları zorunludur.
- `MemoryIndex` yalnız inventory adayıdır; içerik source'tan yeniden okunur.
- Restore veya import garantisi yoktur.
- İlk implementation kendi namespace'inde
  `memory_download_format_version=1` ile başlar; bu görevde uygulanmadı.

### Proje Paketi

- Yalnız seçilen tek proje için paylaşılabilir teslim/rapor artifact'ıdır.
- Project ID tek başına yeterli değildir. Her kayıt source'tan yeniden okunup
  `scope=project`, aynı project, revision/fingerprint, bilinen status/archive,
  allowlist reference, attachment ve publication guard'larından geçer.
- Private, başka projeye ait veya bilinmeyen bağımlılık warning/redaction ile
  dahil edilmez; gerekli kanıt eksikse bütün paket fail-closed durur.
- Terminal status archive sayılmaz. Archive kayıt varsayılan dışıdır; yalnız
  açık `include_archived=true` ile “Tarihsel Ek” inventory'sinde taşınabilir.
- Offline verifier live source'un sonradan değişmediğini iddia etmez; yeniden
  üretim live preflight'i tekrar çalıştırır.
- İlk implementation kendi namespace'inde
  `project_package_format_version=1` ile başlar; bu görevde uygulanmadı.

### Günlük Çıktı ve sürüm ayrımı

- Günlük Çıktı mevcut date/observation/attachment-inventory hattında kalır;
  Proje Paketi'nin küçük adı veya filtreli Backup değildir.
- Follow-up/routine private tracking byte-identical izolasyonu ve mevcut beş
  ZIP entry'si değişmedi.
- Dört bağımsız namespace kabul edildi:
  `backup_format_version`, `memory_download_format_version`,
  `project_package_format_version`, `daily_export_format_version`.
- Mevcut Günlük Çıktı v1'in tarihsel wire anahtarı `format_version` olarak
  korundu; rename ancak ayrı v2 implementation işidir.

### Manifest, verifier, compatibility ve privacy

- Payload checksum'ı uncompressed entry byte'ları üzerinde lowercase SHA-256
  ve `size_bytes` olarak tanımlandı; manifest kendisini checksum listesine
  almaz.
- Exact entry kümesi, safe relative POSIX path, duplicate/case-collision,
  symlink, missing/extra entry ve deterministic sıra kuralları bağlandı.
- Backup Restore güvenliği, Hafızayı İndir artifact bütünlüğü ve Proje Paketi
  source eligibility/privacy kontrolleri ayrı verifier sorumluluklarıdır.
- Verifier source veya artifact repair etmez; revision/event/scope/archive/
  publication mutation'ı yapmaz.
- Bilinmeyen family/version ve eksik eligibility kanıtı fail-closed reddedilir;
  fallback parser veya alan tahmini yoktur.
- Bugünkü şifresiz Backup/Günlük Çıktı davranışı değişmedi. Future encryption
  yönü Backup ve Hafızayı İndir için zorunlu; Proje Paketi ve Günlük Çıktı için
  ayrı/opsiyonel envelope olarak kaydedildi. Key recovery implementation'ı
  ayrı Issue'da bırakıldı.

## Yerel doğrulama

- `CSE_DATA_ROOT`: `UNSET`
- `python -m pytest -rs`: `983 passed, 7 skipped in 28.84s`
- Yedi skip: Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut
  attachment güvenlik testleri
- `python -m compileall -q app scripts`: `PASS`
- `python -m json.tool .cse/state/project_state.json > $null`: `PASS`
- `git diff --check`: `PASS`
- `git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml`:
  boş
- Schema sürümü: `4` (değişmedi)
- Backup format sürümü: `1` (değişmedi)
- Günlük Çıktı format sürümü: `1` (değişmedi)
- Hafızayı İndir / Proje Paketi production formatı: uygulanmadı
- Bütün zorunlu Issue #148 dosyaları fiziksel olarak yerelde mevcut.

## Korunan yollar ve çıktılar

- `reports/`: untracked kullanıcı dosyaları olarak korundu; değiştirilmedi ve
  stage edilmedi.
- Ignored ZIP/cache alanları stage edilmedi.
- `python -m compileall` tarafından kullanılan ignored `__pycache__` alanları
  source veya commit kapsamına alınmadı.
- `exports/`: yalnız `.gitkeep` içeriyor.
- Gerçek kullanıcı data root'una erişilmedi.

## Uygulanmayan alanlar

- Backup/Günlük Çıktı production formatı veya manifest'i değiştirilmedi.
- Hafızayı İndir / Proje Paketi model, builder, verifier, CLI, web route veya UI
  implementation'ı eklenmedi.
- Scope field/event/migration/backfill veya `MemoryIndex` uygulanmadı.
- Schema, migration, repository, Unit of Work, persistence veya test
  değiştirilmedi.
- Encryption, key generation, recovery, import, sync, auth, role veya tenant
  eklenmedi.

## Git ve yayın durumu

Bu result dosyası commit öncesinde olgusal olarak hazırlandı:

- Commit: henüz oluşturulmadı.
- Push: henüz yapılmadı.
- Remote branch divergence: push sonrasında Issue #148 completion comment'inde
  kaydedilecek.
- Pull request: oluşturulmadı; Codex PR açmayacak.
- Merge: yapılmadı ve merge iddiası yok.

Final branch SHA, normal push sonucu ve remote divergence; metadata churn
oluşturmamak için Issue #148 completion evidence yorumunda tutulacaktır.

## Sonraki dar adım

Branch normal push ile yayımlandıktan ve GitHub incelemesi tamamlandıktan sonra
PR akışı ChatGPT/GitHub sorumluluğunda ilerler. Her çıktı ailesinin production
builder/verifier/encryption implementation'ı ayrıca yetkili Issue ve executable
privacy/backward-compatibility testleri ister.
