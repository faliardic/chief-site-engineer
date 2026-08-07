# CSE Codex Loop

`CSE Codex Loop`, ChatGPT Work Mode tarafından açıkça yerel yürütmeye devredilen
tek bir `cse-bridge-task:v1` Issue’yu mevcut ChatGPT/Codex oturumuyla işleyen
Windows-yerel yürütücüdür. Genel GitHub/product geliştirme yöneticisi değildir;
OpenAI API anahtarı, özel Responses istemcisi veya GitHub Actions kullanmaz.

## Güvenlik sınırı

- Operatörün kanonik checkout’u bootstrap kaynağıdır; Scheduled Task bu
  checkout’ta branch/HEAD değiştirmez, checkout/switch/reset/clean/stash
  çalıştırmaz, index veya dosyalara dokunmaz ve Git yapılandırmasını değiştirmez.
  Installer `-RepoRoot` değerini yalnız kabul edilmiş installer’ı doğrulamak ve
  Git ile tam `origin` URL’sini okumak için kullanır. Yalnız
  `faliardic/chief-site-engineer` origin’i kabul edilir.
- Scheduler’ın kontrol düzlemi ayrı
  `%LOCALAPPDATA%\CSE-Codex-Loop\control-repo` clone’udur. Her görev
  `%LOCALAPPDATA%\CSE-Codex-Loop\worktrees\issue-N` altında dış worktree’de
  çalışır.
- GitHub triage, uzaktan uygulanabilen kod/test, commit, normal push ve kanıt
  yönetiminin birincil koordinatörü Work Mode’dur. Yerel loop yalnız en son
  trusted-owner approval yorumunda `CSE_LOCAL_GATE_REQUEST` satırı da varsa
  görevi kabul eder. Yalnız `CSE_BRIDGE_APPROVED` yerel scheduler için yeterli
  değildir; `-IssueNumber` bu sınırı atlayamaz.
- Runtime yapılandırmasında `repository_role` tam olarak
  `dedicated_control_clone_v1` olmalı ve çözümlenmiş `repo_root`, çözümlenmiş
  `control-repo` yoluyla aynı olmalıdır. Eski veya elle değiştirilmiş config bu
  kapıyı geçemez ve Git/Python çağrısından önce
  `runtime_control_clone_unconfigured` ile kapanır.
- Her scheduler çevriminde control clone’un yalnız tracked index/worktree
  temizliği kontrol edilir; untracked ve ignored yollar listelenmez veya
  değiştirilmez. Host yalnız `origin master` ref’ini tagsiz ve prune olmadan
  fetch eder. HEAD ilerideyse veya ayrışmışsa kapanır; yalnız doğrulanmış
  fast-forward durumunda `refs/remotes/origin/master` commit’ine force olmadan
  detached switch yapılır. HEAD zaten eşitse switch yapılmaz.
- Güncelleme sonrasında HEAD ve tracked temizlik yeniden doğrulanmadan Python
  modülü başlatılmaz. Çalışan PowerShell süreci diskteki runner’ı güncellemiş
  olsa da script’i dot-source etmez, yeniden başlatmaz veya aynı invocation’da
  tekrar çalıştırmaz. Yeni Python süreci seçilen control commit’inden yüklenir;
  yeni runner doğal olarak sonraki Scheduled Task çevriminde çalışır.
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
çözer. Kanonik checkout’un kabul edilen origin’inden yalnız `master`, tagsiz ve
submodule çalıştırmadan dedicated control clone’a alınır. Mevcut control yolu
varsa beklenen origin, rol ve tracked temizlik doğrulanır; doğrulama hatasında
silinmez, resetlenmez veya yeniden kurulmaz. Yapılandırma
`%LOCALAPPDATA%\CSE-Codex-Loop\config.json` içine control clone yolu ve
`dedicated_control_clone_v1` rolüyle yazılır.
`CSE Codex Loop` Scheduled Task’ı mevcut interaktif kullanıcı ve `Limited` run
level ile control clone’daki runner ve working directory kullanılarak kaydedilir
ve hemen **Disabled** yapılır. Mevcut `CSE Bridge` görevi okunmaz, değiştirilmez
veya etkinleştirilmez.

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
değiştirmez. Smoke, kanonik checkout’tan değil dedicated control clone’daki
runner’dan çalışır ve başarıda tam olarak şunu yazar:

```text
CSE_CODEX_EXEC_PASS
```

Belirli bir onaylı Issue foreground çalıştırması:

```powershell
& "$env:LOCALAPPDATA\CSE-Codex-Loop\control-repo\scripts\run_cse_codex_loop.ps1" `
  -IssueNumber 345
```

Issue numarası verilmezse en küçük numaralı, hazır/onaylı ve en son trusted-owner
approval yorumunda `CSE_LOCAL_GATE_REQUEST` bulunan görev seçilir. Genel onaylı
Issue’lar yerel loop için görünmezdir. Görev yoksa invocation `IDLE` biter.

## Scheduler aktivasyonu

### Merge sonrası tek gerekli bootstrap

Bu mimari merge edildikten sonra operatör yalnız bir kez şu sırayı uygular:

1. Kanonik checkout’u `master`ın kabul edilmiş merge commit’ine günceller.
2. O checkout içindeki kabul edilmiş installer’ı aynı kanonik `-RepoRoot` ve
   `-Smoke` ile çalıştırır.
3. Smoke kabulünden sonra `CSE Codex Loop` görevini açıkça etkinleştirir.

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'
git pull --ff-only origin master
& .\scripts\install_cse_codex_loop.ps1 `
  -RepoRoot 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer' `
  -Smoke
Enable-ScheduledTask -TaskName 'CSE Codex Loop'
```

Bu bootstrap’tan sonra kabul edilmiş host güncellemeleri dedicated control
clone’u güvenli fast-forward ile seçebilir; kanonik checkout değişmeden kalır.
Aktivasyon yine kod kabulünden ve manuel smoke’dan ayrı operatör adımıdır.
Yalnız aktivasyon gerekiyorsa:

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
  review-round-1.json
  review-round-2.json  # yalnız correction sonrası ikinci review çalıştıysa
```

Son status ayrıca `worker-status.json` içinde atomik olarak tutulur. Status her
zaman `run_id` ve `issue_number` alanlarını taşır. Varsayılan rotation son 20
run’ı korur. Tam prompt, GitHub tokenı, ChatGPT auth malzemesi ve secret’lar
loglanmaz; Codex aşamaları yalnız veri-minimal exit kaydı bırakır.

Başarıyla parse edilen her structured review turu, ham Codex çıktısı yerine
atomik bir `review-round-<n>.json` kanıtı bırakır. Bu dosya yalnız `round`,
`verdict`, `summary`, `findings` ve `recorded_at` alanlarını taşır. Summary 1200
karakter, her finding 500 karakter ve finding sayısı 8 ile sınırlıdır; mevcut
secret redaction uygulanır ve bilinen yerel çalışma/tool yollarının büyük-küçük
harf ile Windows ayraç varyantları gizlenir.
Transient `review-result.json` parse sonrasında silinmeye devam eder. Sanitized
kanıt dosya sistemi, serialization veya UTF-8 encoding nedeniyle atomik
yazılamazsa yayın başlamadan `review_evidence_write_failed` ile fail closed
olunur.

Yalnız `review_needs_human` ve `review_unresolved` terminal yorumları aynı
immutable yorumda ilgili turun verdict, sanitized summary ve en fazla 5
finding’ini gösterir. Reviewer bölümü toplam 1800 karakteri aşmaz; ilk neden
birinci review’u, unresolved correction ise ikinci ve son review’u kullanır.
Diğer failure yorumlarının veri-minimal biçimi değişmez.

Başlıca terminal nedenler sabit ve veri-minimaldir: `scope_violation`,
`validation_failed`, `codex_implementer_failed`, `codex_review_failed`,
`review_evidence_write_failed`, `review_needs_human`, `review_unresolved`,
`branch_conflict` ve `worktree_conflict`. Yayın sonrası cleanup sorunu terminal
failure nedeni değil, PASS durumuna eşlik eden `approved_cleanup_pending`
uyarısıdır.
