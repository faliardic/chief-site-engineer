# ADS System Managers

ADS iki kalıcı sistem yöneticisini birlikte destekler. Bunlar feature topolojisi
değil, yetkili production writer'ın hangi execution surface üzerinde çalıştığını
tanımlayan yönetim katmanlarıdır.

Canonical adlar:

- `LOCAL_SYSTEM_MANAGER`
- `GITHUB_SYSTEM_MANAGER`

Geçiş dönemindeki `LOCAL_AGENT` ve `GITHUB_NATIVE` ifadeleri yalnız eski adların
eş anlamlılarıdır; yeni kayıt ve kickoff'larda canonical System Manager adları
kullanılır.

## 1. Ortak invariantlar

Her iki System Manager aynı ADS authority, risk, topology ve review kurallarına
tabidir. Manager seçimi:

- yeni product scope üretmez;
- risk seviyesini düşürmez;
- yeni WRITE veya Git authority vermez;
- owner/manual/release gate'ini kaldırmaz;
- aynı feature içinde ikinci production writer açmaz.

`SINGLE`, `PARALLEL_READ` ve `MULTI_FEATURE_PARALLEL` manager seçiminin dışında
kalan topology/orchestration kavramlarıdır.

Temel ayrım:

```text
TOPOLOGY -> kaç execution lane'i olduğunu belirler.
SYSTEM_MANAGER -> yetkili writer'ın hangi execution surface'te çalıştığını belirler.
PROVIDER -> seçilen manager altında işi yapan somut araç/ajanı belirtir.
```

## 2. LOCAL_SYSTEM_MANAGER

`LOCAL_SYSTEM_MANAGER`, yerel repository ve host yetenekleri üzerinden execution
yürüten sistem yöneticisidir.

Somut provider örnekleri:

```text
Codex
Claude Code
future compatible local repository execution agent
```

Provider değişimi manager değişimi değildir. Codex'ten Claude Code'a veya tersine
geçiş, aynı local execution surface korunuyorsa `LOCAL_SYSTEM_MANAGER` altında
kalır.

Tipik capability'ler:

- local repository/worktree ve terminal;
- project-local test/analyzer/build;
- emulator;
- ADB;
- host izin veriyorsa physical device;
- local-only profiler;
- local filesystem;
- ayrıca yetkilendirilmiş local signing/credential kullanımı;
- task authority kapsamında branch/commit/push/PR işlemleri.

Bu capability listesi otomatik yetki değildir. Host, sandbox, credential ve proje
kuralları ayrıca geçerlidir.

## 3. GITHUB_SYSTEM_MANAGER

`GITHUB_SYSTEM_MANAGER`, ChatGPT'nin bağlı GitHub yetenekleri üzerinden
repository execution yürüttüğü sistem yöneticisidir.

Tipik akış:

```text
repo truth / Issue authority
-> branch
-> source edit
-> commit
-> remote branch
-> GitHub-hosted validation when available
-> exact diff/review
-> Draft PR
-> required human/manual gate
-> merge according to project authority
```

Yetki verildiğinde aşağıdakileri yapabilir:

- repository, branch, commit, Issue ve PR okumak;
- yetkili branch üzerinde source değiştirmek;
- branch ve commit üretmek;
- Issue/PR evidence veya comment yazmak;
- Draft PR oluşturmak/güncellemek;
- PR diff/review/check durumunu incelemek;
- mevcut GitHub Actions sonuçlarını ve artifact'larını değerlendirmek;
- aynı task scope'unda correction commit'leri üretmek;
- project/task authority açıkça izin veriyorsa Ready/merge gibi Git işlemlerini
  yürütmek.

Aşağıdaki capability'lere sahip olduğunu varsayamaz:

- physical Android device;
- ADB;
- kullanıcının Windows/local filesystem'i;
- local-only profiler;
- local emulator;
- local signing material veya secret;
- GitHub/CI üzerinde bulunmayan project tooling.

Bu alanlardan biri task acceptance için gerçekten zorunluysa
`LOCAL_CAPABILITY_REQUIRED` handoff'u üretilir.

## 4. Manager seçimi

Seçim provider öncelik listesine göre değil, gerekli capability'ye göre yapılır.

```text
Can the task be completed with repository/GitHub capabilities
plus explicitly allowed human acceptance?

YES -> GITHUB_SYSTEM_MANAGER eligible
NO  -> LOCAL_SYSTEM_MANAGER required
```

Her technical kickoff en az şunları kaydeder:

```text
SYSTEM_MANAGER
Mode: LOCAL_SYSTEM_MANAGER | GITHUB_SYSTEM_MANAGER
Resolved provider: <Codex | Claude Code | ChatGPT GitHub | other authorized provider>
Reason: <short capability-based reason>
Local capability required: YES | NO
Manual acceptance owner: <none | Fatih | project-specific>
```

Manager seçimi execution başında kilitlenir. Sessiz manager değişimi yapılmaz.

## 5. Topology uyumu

### SINGLE

Tek Builder/WRITE seçilen System Manager üzerinde çalışır.

### PARALLEL_READ

Feature başına tek production writer invariant'ı korunur:

- Builder seçilen System Manager üzerinde WRITE sahibidir;
- Scout ve Reviewer READ kalır;
- manager seçimi ikinci writer açmaz.

Scout/Reviewer güvenli read surfaces kullanabilir; bu durum onlara WRITE authority
vermez.

### MULTI_FEATURE_PARALLEL

Her feature kendi System Manager seçimini taşıyabilir.

Örnek:

```text
Q06 -> GITHUB_SYSTEM_MANAGER
Q07 -> LOCAL_SYSTEM_MANAGER
Q09 -> GITHUB_SYSTEM_MANAGER
```

Her feature'ın kendi authority/topology lock'ı ve tek writer'ı korunur.

## 6. Validation sınıfları

`LOCAL_SYSTEM_MANAGER`, proje-local validation araçlarını host capability
elverdiği ölçüde çalıştırabilir.

`GITHUB_SYSTEM_MANAGER` validation kanıtını üç sınıfta taşır:

```text
GITHUB_HOSTED
HUMAN_MANUAL
LOCAL_ONLY
```

`GITHUB_HOSTED` yalnız gerçekten çalıştırılmış GitHub Actions/check/tooling
kanıtı varsa PASS sayılır. CI yoksa test PASS uydurulmaz.

`HUMAN_MANUAL`, Fatih veya project-specific acceptance owner'ın yürüttüğü gerçek
manuel kabulü ifade eder.

`LOCAL_ONLY`, acceptance için gerçekten zorunlu olup GitHub surface'te
çalıştırılamayan kontrolü ifade eder.

Manager seçimi validation waiver değildir.

## 7. Fatih manual acceptance

Emulator veya gerçek cihaz kabulünün Fatih tarafından yapılması desteklenen
normal çalışma biçimidir.

Bu nedenle GITHUB_SYSTEM_MANAGER'ın emulator, physical device, ADB, local-only
profiling veya local filesystem erişimi olmaması normal source development'ı
otomatik olarak bloke etmez.

Kaynak/otomatik bölüm tamamlanıp yalnız manuel gate kaldığında uygun disposition:

```text
READY_FOR_MANUAL_ACCEPTANCE
Source: complete
Automated validation: complete | unavailable with exact reason
Remaining gate: Fatih manual acceptance
```

Manuel gate gerekmeyen işe sırf GITHUB_SYSTEM_MANAGER kullanıldığı için yeni
manual acceptance eklenmez.

## 8. LOCAL_CAPABILITY_REQUIRED handoff

Execution sırasında gerçek local capability ihtiyacı ortaya çıkarsa:

```text
LOCAL_CAPABILITY_REQUIRED
Task/revision:
Current System Manager: GITHUB_SYSTEM_MANAGER
Completed GitHub work:
Exact remaining local operation:
Source change required before handoff: YES | NO
Recommended System Manager: LOCAL_SYSTEM_MANAGER
Preserved scope/risk/topology/WRITE authority:
```

Bu handoff yeni scope, risk downgrade, topology, lane veya WRITE authority
üretmez.

Tersi yöndeki geçiş de yalnız yetkili bounded migration ile yapılır. Local
provider quota/host problemi tek başına yeni product authority sağlamaz.

## 9. Local clone senkronizasyonu

GitHub kanonik repository truth olmaya devam eder.

GITHUB_SYSTEM_MANAGER execution sırasında local clone'un anlık güncel olması
zorunlu değildir. Daha sonra LOCAL_SYSTEM_MANAGER ile yazmaya dönmeden önce:

```text
fetch/current remote truth
-> local status/drift check
-> uncommitted local work'i koru
-> project Git kurallarına göre safe sync
-> local execution'a devam et
```

Dirty local work sessizce overwrite/reset/clean edilmez. Local clone'un stale
olması GitHub'da tamamlanmış ve doğrulanmış source revision'ını geçersiz yapmaz.

## 10. Authority ve risk

Persistence/data integrity, schema/migration, backup/restore, security,
release/signing ve destructive operation gibi project-specific güçlü kapılar
manager seçiminden bağımsız korunur.

GitHub API üzerinden yazılabilmesi bir mutasyonu düşük riskli yapmaz.

Buna karşılık mevcut task authority source implementation, commit/push ve Draft
PR'yi zaten kapsıyorsa, sırf writer `GITHUB_SYSTEM_MANAGER` olduğu için her
dosya mutasyonunda tekrar owner onayı istenmez. Manager katmanı gereksiz
mikro-onay üretmemelidir.

## 11. İlk CSE çalışma modeli

CSE için hedef default değerlendirme:

```text
Normal source / Git / Issue / PR work:
  GITHUB_SYSTEM_MANAGER eligible

GitHub-hosted automated validation/build:
  GITHUB_SYSTEM_MANAGER

Manual emulator/device acceptance:
  Fatih

ADB / local profiler / local filesystem / signing / CI'da olmayan tooling:
  LOCAL_SYSTEM_MANAGER only when actually required
```

Bu model Codex veya Claude Code kota/host availability probleminin GitHub ile
tamamlanabilir development işini durdurmasını önler.

## 12. Non-goals

Bu contract:

- LOCAL_SYSTEM_MANAGER'ı kaldırmaz;
- automatic provider failover daemon kurmaz;
- background controller eklemez;
- CI olmayan projede test PASS uydurmaz;
- secret/signing material'ı GitHub'a taşımaz;
- manual/device gate'ini waive etmez;
- aynı feature'a ikinci production writer eklemez;
- manager migration üzerinden scope genişletmez;
- child product repo'larına otomatik adoption yetkisi vermez.
