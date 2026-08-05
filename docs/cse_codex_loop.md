# CSE Codex Loop

`CSE Codex Loop`, onaylanmış tek bir `cse-bridge-task:v1` Issue’yu mevcut
ChatGPT/Codex oturumuyla işleyen Windows-yerel geliştirme aracıdır. OpenAI API
anahtarı, özel Responses istemcisi veya GitHub Actions kullanmaz.

## Güvenlik sınırı

- Kanonik checkout branch değiştirmez. Her görev
  `%LOCALAPPDATA%\CSE-Codex-Loop\worktrees\issue-N` altında dış worktree’de
  çalışır.
- Implementer `workspace-write`, bağımsız reviewer `read-only` sandbox kullanır.
- Allowed path ve Issue validation komutları Codex’e bırakılmaz; host bunları
  `shell=False` subprocess’leriyle uygular.
- Python ve Git validation komutları Issue worktree kökünde çalışır. Flutter
  validation için host önce `<worktree>/pubspec.yaml`, sonra yalnız
  `<worktree>/mobile/pubspec.yaml` konumunu kontrol eder. İlki varsa worktree
  kökünü, yalnız ikincisi varsa `mobile/` paket kökünü seçer; ikisi de yoksa
  Flutter’ı çağırmadan `validation_working_directory_unavailable` ile kapanır.
- Validation, Git, GitHub publication, Draft PR ve terminal Issue yorumu host
  kontrolündedir.
- Review yalnız `approved`, `changes_requested` veya `needs_human` verdict’i ile
  yapılandırılmış JSON döndürür. `changes_requested` için en fazla bir correction
  çalışır; ikinci review onaylamazsa sonuç `NEEDS_HUMAN` olur.
- Başarılı worktree cleanup’ı host tarafından sınırlı tekrarlarla yapılır.
  Kaldırmadan önce worktree’nin temiz olduğu, beklenen görev branch’inde kaldığı
  ve push edilen commit’i gösterdiği doğrulanır. Windows’ta `git worktree remove
  --force` geçici olarak hata verirse yeniden denenir. Kayıt durumu yalnız
  `git worktree list --porcelain -z` ile salt-okunur incelenir ve yalnız kesin
  Issue worktree yolu değerlendirilir. Otomatik cleanup repository-wide
  `git worktree prune` çalıştırmaz veya ilgisiz worktree metadata’sına dokunmaz.
  Dizin zaten yoksa ve kesin yol kayıtlı değilse cleanup tamamdır. Başarısız
  remove sonrasında kesin yol kayıtlı değilse de cleanup tamamdır; yol kayıtlı
  kalıyorsa worktree/metadata korunur ve cleanup pending sonucu üretilir. Dosya
  sistemi fallback’i ancak aynı clean/branch/push edilmiş commit güvenlik kapısı
  yeniden geçildikten ve kesin kaydın kaldırıldığı doğrulandıktan sonra
  kullanılabilir.
- Scope, validation, Codex veya review hatasındaki worktree tanı için korunur.
  Yayın ve Draft PR tamamlandıktan sonra cleanup yine mümkün olmazsa worktree
  manuel cleanup için korunur; sonuç `FAILED` olmaz. Draft PR URL’siyle
  `READY_FOR_FATIH`, PASS exit semantics ve veri-minimal
  `approved_cleanup_pending` uyarısı üretilir. Force-push, merge, branch silme,
  release, cihaz, ADB, backup/restore ve kullanıcı verisi işlemi yoktur.

## Kurulum

PowerShell’i mevcut interaktif Windows kullanıcısıyla açın:

```powershell
& .\scripts\install_cse_codex_loop.ps1 `
  -RepoRoot 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'
```

Installer `python`, `codex`, `git` ve `gh` executable yollarını kesin olarak
çözer; yapılandırmayı `%LOCALAPPDATA%\CSE-Codex-Loop\config.json` içine yazar.
`CSE Codex Loop` Scheduled Task’ı mevcut interaktif kullanıcı ve `Limited` run
level ile kaydedilir ve hemen **Disabled** yapılır. Mevcut `CSE Bridge` görevi
okunmaz, değiştirilmez veya etkinleştirilmez.

Bu repository’de Flutter paketi `mobile/` altında olduğundan Issue validation
komutları seçilen paket köküne göre package-local yol kullanmalıdır:

```text
flutter test test/widget_test.dart
flutter analyze
```

Host `mobile/` kökünü seçtiğinde `mobile/test/widget_test.dart` gibi worktree
köküne göre yazılmış yollar kullanılmaz.

## İlk manuel smoke

İlk smoke yalnız bağlantı/dokümantasyon kabulüdür. Installer kendiliğinden smoke
veya scheduler başlatmaz. Operatör açıkça şu komutu verir:

```powershell
& .\scripts\install_cse_codex_loop.ps1 `
  -RepoRoot 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer' `
  -Smoke
```

Bu komut `codex exec --ephemeral --sandbox read-only` çalıştırır, dosya
değiştirmez ve başarıda tam olarak şunu yazar:

```text
CSE_CODEX_EXEC_PASS
```

Belirli bir onaylı Issue foreground çalıştırması:

```powershell
& .\scripts\run_cse_codex_loop.ps1 -IssueNumber 345
```

Issue numarası verilmezse en küçük numaralı hazır/onaylı görev seçilir; görev
yoksa invocation `IDLE` biter.

## Scheduler aktivasyonu

Aktivasyon, kod kabulünden ve manuel smoke’dan ayrı bir operatör adımıdır:

```powershell
Enable-ScheduledTask -TaskName 'CSE Codex Loop'
```

Tekrar durdurmak için:

```powershell
Disable-ScheduledTask -TaskName 'CSE Codex Loop'
```

Otomatik merge yoktur. Başarı terminal yorumu `READY_FOR_FATIH` ve bir Draft PR
üretir; sonraki yayın kararı insandadır. Normal cleanup başarısı `approved`
olarak kalır. Yalnız cleanup bekliyorsa aynı PASS yorumunda
`approved_cleanup_pending` uyarısı bulunur.

## Kayıtlar ve tanı

Her invocation tek run ID kullanır:

```text
%LOCALAPPDATA%\CSE-Codex-Loop\runs\<run-id>\
  stdout.log
  stderr.log
  status.json
```

Son status ayrıca `worker-status.json` içinde atomik olarak tutulur. Status her
zaman `run_id` ve `issue_number` alanlarını taşır. Varsayılan rotation son 20
run’ı korur. Tam prompt, GitHub tokenı, ChatGPT auth malzemesi ve secret’lar
loglanmaz; Codex aşamaları yalnız veri-minimal exit kaydı bırakır.

Başlıca terminal nedenler sabit ve veri-minimaldir: `scope_violation`,
`validation_failed`, `codex_implementer_failed`, `codex_review_failed`,
`review_needs_human`, `review_unresolved`, `branch_conflict` ve
`worktree_conflict`. Yayın sonrası cleanup sorunu terminal failure nedeni değil,
PASS durumuna eşlik eden `approved_cleanup_pending` uyarısıdır.
