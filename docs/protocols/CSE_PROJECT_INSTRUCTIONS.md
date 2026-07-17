# CSE Güncel Proje Talimatları

**Belge türü:** Operasyonel proje talimatı / execution protocol
**Geçerlilik tarihi:** 2026-07-16
**Canonical proje yolu:** `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
**Durum:** Bu tracked belge, Git/GitHub/Codex calisma kurallari, guvenlik, verification ve execution protocol icin yetkili kaynaktir. Urun amaci, strateji, veri ilkeleri, urun katmanlari ve uzun vadeli mimari icin `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` ust kaynaktir.

---

## 1. Projenin Amacı

CSE, yalnız şantiye şefi tarafından kullanılan; not, takip, hatırlatıcı, hesap, fotoğraf, belge, günlük, arama ve proje hafızasını tek güvenilir akışta birleştiren local-first ve mobile-first **kişisel saha asistanı**dır.

```text
Araç bakımından geniş
Kullanıcı modeli bakımından tek sahipli
```

Ana ürün döngüsü:

```text
Yakala -> İşle -> Takip et -> Doğrula -> Günlüğe al
```

CSE’nin amacı büyük inşaat yönetim platformlarının küçük bir kopyasını veya kurumsal ortak çalışma sistemi yapmak değildir. Uygulamaya yalnız şantiye şefi girer; diğer kişi ve firmalar sistem kullanıcısı değil kayıt referansıdır. İlk gerçek rakipleri şunlardır:

- WhatsApp grupları
- Telefon galerisi
- Excel listeleri
- Klasör karmaşası
- Defter notları
- E-posta ekleri
- Hatırlamaya dayalı kişisel düzen

Her özellik şu sorudan geçmelidir:

> Bu özellik şantiye şefinin sahada unutmamasını, kanıtlamasını, takip etmesini, raporlamasını veya daha sonra geri çağırmasını kolaylaştırıyor mu?

Cevap hayırsa özellik ertelenir veya kapsam dışı bırakılır.

---

## 2. Değişmez Ürün ve Veri İlkeleri

1. CSE önce güvenilir veri omurgasını kurar; otomasyon ve AI daha sonra gelir.
2. Proje küçük, test edilebilir, geri alınabilir ve commitlenebilir adımlarla büyür.
3. Resmî kayıtlar ile kişisel/özel alan kesin olarak ayrılır.
4. Resmî kayıtlar fiziksel olarak silinmez; arşivlenir, pasifleştirilir, hükümsüz kılınır veya yeni revizyonla değiştirilir.
5. Kanıt niteliği taşıyan işlemler audit izi bırakacak şekilde tasarlanır; audit davranışı yalnız açık görev kapsamında uygulanır.
6. Medya dosyaları veritabanına gömülmez; dosya yolu, metadata ve bütünlük kontrolleriyle yönetilir.
7. Attachment metadata kaydı fiziksel dosya ile bütünlük içinde olmalıdır.
8. `private` çalışma verisi tek sahibine aittir ve resmî/proje output kapsamına otomatik girmez.
9. Şirketler, ekipler ve diğer kişiler kullanıcı hesabı değil; kişi/kurum ve ilgili taraf kayıt referanslarıdır.
10. Paylaşım için gerekli bilgi private durumda bırakılmaz; açık kullanıcı işlemiyle project kapsama geçirilir ve source uygunluğu doğrulanmış Proje Paketi veya ilgili çıktıya seçilir.
11. Hard validation, otomatik blocking, migration, persistence, audit, backup/restore, API, GUI ve CLI çalışmaları ayrı ve açık görev kapsamı gerektirir.
12. `requires_human_review` yalnız insan inceleme sinyalidir; otomatik kabul, ret, onay veya paket engelleme kararı değildir.
13. Sistem kendiliğinden `blocked` durumu üretmez.
14. Resmî-devredilebilir veri ile özel-devredilemez veri bütün ekran, export ve devir örneklerinde ayrı tutulur.
15. Multi-user, role, tenant, firma portalı, kurumsal workflow ve SaaS aktif veya uzun vadeli ürün hedefi değildir.
16. Tek kullanıcı kararı güvenliği kaldırmaz; uygulama kilidi, güvenilen cihaz, şifreli backup, owner-only senkronizasyon ve güvenli yerel ağ ayrı güvenlik sınırıdır.

---

## 3. Saha Kullanım İlkesi ve İlk MVP

`+ Unutma` hızlı takip kaydında tek zorunlu içerik `Ne unutulmamalı?` metnidir ve hedef ortanca yakalama süresi 8 saniyenin altıdır. Daha ayrıntılı resmî saha gözlemi de kısa ve sahada kullanılabilir kalmalıdır.

İlk kayıt mümkün olduğunca kısa tutulur:

- Tarih
- Blok / kat / mahal / alan
- Kategori
- Kısa açıklama
- Fotoğraf veya dosya eki
- Durum
- Kime bildirildi

İlk saha MVP öncelikleri:

1. Hızlı saha gözlem kaydı
2. Fotoğraf/dosya eki bağlama
3. Konum bilgisi
4. Açık / takipte / kapandı durum takibi
5. Kime bildirildi bilgisi
6. Günlük export
7. Haftalık özet

Merge edilmiş Local Field MVP; SQLite persistence, managed attachment store, local Flask web akışı, proje/gözlem create-list-detail-update, revision conflict koruması, arama, günlük export, backup/verify/izole restore ve Windows launcher içerir.

Saha Takibi domain/recurrence, schema v4 repository/event persistence,
transactional application service, yedi günlük lazy backfill, Backup/Restore
compatibility, resmî export izolasyonu ve ilk PC kullanıcı yüzeyi tamamlanmıştır.
Scope field/conversion, archive/unarchive, MemoryIndex/Hafıza UI,
Hafızayı İndir, Proje Paketi, mobile/offline ve owner-only security
implementation'ları henüz tamamlanmamıştır.

Epic #105 bağlayıcı üst yol haritasıdır:

```text
0. Issue #103 tek kullanıcılı yön düzeltmesi
1. Transactional application service ve 7 günlük lazy backfill
2. Backup/restore compatibility ve resmî export izolasyonu
3. Mobil runtime ve veri sahipliği ADR
4. Mobil-first Kâğıdı Bırakma Sürümü
5. Offline ve bildirim güvenilirliği
6. 7 günlük gerçek saha pilotu
7. 30 günlük ana uygulama pilotu
8. Gelişmiş mühendislik hesap defteri
9. Günlük log yayınlama/revizyon zinciri
10. Canlı Proje Haritası
11. Kanıtlanmış kişisel yardımcı araçlar
12. Kişisel AI asistanı
```

Kâğıdı Bırakma Sürümü takip görünümleri, rutin, attachment, arama ve backup görünürlüğüne ek olarak minimum hızlı hesap şeridi ile günlük zaman çizelgesi/düzenlenebilir taslağı da ilk pilot öncesinde içerir.

Multi-user/role/tenant/SaaS/kurumsal portal hedefleri “daha sonra” listesine alınmaz. `local-first`, `Windows-first` değildir; mobil, offline, notification ve owner-only sync gerçek saha pilotlarından önce ele alınır.

### Faz 0 kanonik karar belgeleri

- `docs/adr/ADR-0001-single-memory-and-record-scope.md`
- `docs/adr/ADR-0002-memory-index-record-ref-read-model.md`
- `docs/adr/ADR-0003-backup-memory-download-project-package.md`
- `docs/adr/ADR-0004-owner-only-security-and-data-ownership-threat-model.md`

Bu dört ADR sırasıyla kapsam, projection, artifact ailesi ve owner-only güvenlik
kararlarını taşır. ADR kararı production implementation kanıtı değildir;
uygulama durumu current repository kodu, test ve merged commit üzerinden ayrıca
doğrulanır.

---

## 4. Kaynak ve Karar Önceliği

Kaynak otoritesi bilgi türüne göre ayrılır:

| Bilgi türü | Yetkili kaynak |
| --- | --- |
| Kalıcı ürün amacı, strateji ve veri ilkeleri | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` |
| Operasyon, Git/GitHub/Codex güvenliği | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` |
| Aktif görev kapsamı | current GitHub Issue ve `.cse/tasks/<issue_no>_task.md` |
| Değişken repository durumu | GitHub `master`, PR, Issue, branch ve commit kanıtı |
| İkincil factual mirror/evidence | `.cse/state/project_state.json` ve `.cse/results/<issue_no>_result.md` |

Güncel Issue mevcut işi daraltabilir; fakat kalıcı ürün/veri ilkelerini veya safety kurallarını sessizce override edemez. Kalıcı policy değişikliği gerekiyorsa yetkili görev içinde tracked unified source ve/veya canonical instructions güncellenir.

Current state her yeni iş öncesinde şu sırayla doğrulanır:

1. `origin/master` HEAD;
2. açık Issue ve PR'lar;
3. ilgili branch/commit diff'i;
4. current Issue completion evidence'i;
5. resmî `V:` kopyasında yerel Codex doğrulaması;
6. `.cse/state` ikincil factual mirror.

Stale `.cse/state`, README, ROADMAP, handoff, ZIP veya sohbet hafızası güncel GitHub gerçeğini override edemez.

Kök dizindeki `CSE_GUNCEL_PROJE_TALIMATLARI.md` dosyasi artik higher-priority override degildir. Bu dosya, yalniz resmi yerel çalışma kopyasinda kolay okuma icin tutulabilecek optional local mirror'dir.

Local mirror `.git/info/exclude` üzerinden ignored kalır, stage edilmez ve commitlenmez. Tracked canonical dosyayla eşitliği ayrıca kanıtlanmadıkça mirror güncel sayılmaz; normal görevler ignored mirror'ı otomatik değiştirmez.

`chat_handoff/` dosyaları sohbet aktarımı içindir; Git durumu, yerel çalışma ağacı veya güncel Issue/PR kayıtlarının yerine geçmez.

Project source register:

```text
docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md
```

New-chat GitHub bootstrap source:

```text
docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md
```

---

## 5. Resmî Yerel Çalışma Kopyası

Bütün proje dosyası üretimi ve düzenlemesi şu resmî yerel repoda yapılır:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

### Zorunlu kural

- Her Codex execution, edit veya Git write öncesinde şu kaynakları sırayla okur:

  1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
  2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
  3. workflow, handoff, bootstrap veya source-authority işinde `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
  4. current GitHub Issue ve bütün scope/izin yorumları
  5. `.cse/tasks/<issue_no>_task.md` (yeni görevde ilk yetkili yerel dosya olarak oluşturulur)

- Required tracked source eksikse veya current task cozulmemis kalici rule ile celisiyorsa Codex edit yapmadan durur ve raporlar.
- Her Codex execution once resmi `V:` yoluna gecmelidir:

  ```powershell
  Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'
  ```

- `git rev-parse --show-toplevel` sonucu tam olarak resmi `V:` yolu ile ayni root'a cozumlenmelidir.
- Yol farkliysa herhangi bir Git islemi veya file write yapmadan durulur.
- CSE icin otomatik `C:` clone/workspace olusturulmaz ve kullanilmaz.
- Instruction ve evidence alisverisi guncel GitHub Issue uzerinden yapilir; local execution resmi `V:` reposunda kalir.
- Proje dosyalarını yalnız GitHub web arayüzü, connector veya API üzerinden oluşturmak tamamlanmış iş sayılmaz.
- GitHub senkronize remote ve inceleme yüzeyidir.
- Yerel repo; dosya oluşturma, düzenleme, test, kalite kontrol, commit ve push için yürütme kaynağıdır.

ChatGPT GitHub üzerinde Issue, yorum, Draft PR, inceleme durumu ve merge işlemlerini yönetebilir. Proje dosyalarını doğrudan GitHub üzerinden üretmez veya düzeltmez; bunu Codex resmî yerel repoda yapar.

---

## 6. Her Adım Öncesi Zorunlu Yerel Kontrol

Codex herhangi bir branch değişikliği, pull, düzenleme, commit veya push öncesinde yerel durumu kontrol eder:

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'

$expected = (Resolve-Path 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer').Path
$actual = (git rev-parse --show-toplevel)

if ((Resolve-Path $actual).Path -ne $expected) {
    throw 'Wrong repository root. Stop without changing anything.'
}

git status --short --branch
git status --ignored --short --untracked-files=all
git remote -v
```

Beklenmeyen tracked, staged veya untracked proje değişikliği varsa:

- İş durdurulur.
- Değişiklikler raporlanır.
- Otomatik `reset`, `clean`, `stash`, silme, taşıma veya üzerine yazma yapılmaz.

Mevcut ignored ZIP dosyasına dokunulmaz:

```text
chief-site-engineer_adim_080_guvenli_nokta.zip
```

---

## 7. Master Senkronizasyon Protokolü

Yeni bir adım başlamadan önce:

```powershell
git fetch origin --prune
git checkout master
git pull --ff-only origin master

git rev-parse master
git rev-parse origin/master
git rev-list --left-right --count origin/master...master
```

Beklenen sonuçlar:

- Yerel `master` SHA = `origin/master` SHA
- Divergence = `0 0`
- Pull yalnız `--ff-only` ile yapılır

Merge sonrasında yeni adıma geçmeden önce aynı senkronizasyon tekrar yapılır.

---

## 8. Issue → Branch → Task → PR Akışı

Kullanıcı normalde yalnız `devam` veya eşdeğer bir devam komutu yazar. ChatGPT her sonraki işlemden önce GitHub Issue, PR, branch, diff, comments, checks ve merge state’i kontrol eder. Uzun talimat veya sonuç bloklarının kullanıcı tarafından ChatGPT ile Codex arasında kopyalanması beklenmez; Codex instruction ve completion evidence güncel GitHub Issue üzerinden paylaşılır.

Her adım aşağıdaki sırayla yürütülür:

1. ChatGPT GitHub durumunu doğrular ve küçük, sınırları net bir GitHub Issue açar veya günceller.
2. Issue, resmî yerel repo yolunu, beklenen base commit’i ve Codex execution instruction’ını içerir.
3. Codex yalnız local project-file edit, local test, commit/push veya post-merge local synchronization gerektiğinde devreye girer.
4. Codex yerel `master`ı senkronlar ve Issue branch'ini yerelde oluşturur:

   ```text
   codex/issue-<issue_no>-<slug>
   ```

5. Codex `.cse/tasks/<issue_no>_task.md` ve bütün yetkili project files’ı fiziksel yerel çalışma ağacında oluşturur veya düzenler.
6. Codex test ve kalite kontrollerini yerelde çalıştırır.
7. Görev izin veriyorsa Codex yerelden commit/push yapar ve branch/remote farkını `0 0` doğrular.
8. Codex factual completion evidence’i güncel GitHub Issue’a ekler.
9. ChatGPT GitHub branch diff’ini, comment/evidence’i ve review state’i inceler; güvenliyse Draft PR’ı doğrudan oluşturur.
10. Eksik veya çelişkili kayıt varsa ChatGPT Issue üzerinden local correction instruction verir; merge yapılmaz.
11. İnceleme geçerse ChatGPT PR’ı ready yapar ve kullanıcı onayıyla squash merge eder.
12. ChatGPT gerektiğinde sonraki Issue’yu doğrudan oluşturur.
13. Merge sonrası Codex yalnız gerektiğinde yerel `master`ı yeni merge commit’ine fast-forward eder.

ChatGPT GitHub-native Issue creation/update, review comment, Draft PR creation, ready transition, merge ve next Issue creation işlemlerini doğrudan yapar. Branch/task/project files GitHub connector üzerinden üretilmez; GitHub-only project-file creation completion değildir.

Eski `step-NNN-*` branch'ler tarihsel olarak korunur ve yeniden adlandırılmaz. Aynı anda yalnız bir aktif production implementation görevi ve en fazla bir incelemede PR bulunur. Dokümantasyon görevi aktif production branch'ini sessizce geçmez veya onun kapsamına girmez.

### Codex invocation policy

ChatGPT, Codex'i cagirmadan once local execution gerekip gerekmedigini degerlendirir.

Codex gerekiyorsa ChatGPT kullaniciya acikca sunu soyler:

```text
Codex çalışmalı
```

ve kisaca nedenini belirtir. Kullanici, Codex'in calisip calismamasi gerektigini tahmin etmek zorunda degildir.

Issue, comment, PR review veya merge-state inspection tek basina hemen Codex calismasi gerektirmez.

### Codex gereken durumlar

Codex su durumlarda gereklidir:

- local project-file creation veya editing;
- local tests, scripts, validation, hashes, ignored-file, ZIP, export, path veya worktree inspection;
- local branch creation veya switching;
- stage, commit, push;
- local error resolution;
- sonraki local degisiklik oncesi local `master` synchronization;
- GitHub'in guvenle yapamayacagi spesifik local operation.

### Codex normalde gerekmeyen durumlar

Codex su durumlarda normalde gerekmez:

- planning, reasoning, architecture, prioritization, summaries veya recommendations;
- GitHub Issue/PR/diff/comment/review/merge-state inspection;
- GitHub Issue/comment creation;
- branch zaten push edildikten sonra Draft PR creation;
- ready transition, review veya squash merge;
- web research veya conceptual analysis;
- local evidence gerekmeyen GitHub state raporlama.

### Batched execution policy

Default model:

```text
1 technical step = 1 primary Codex run
blocking correction = at most 1 correction run
post-merge sync = batch into the next Codex-required run when safe
```

- Her kucuk comment, metadata observation veya non-blocking wording issue icin ayri Codex calistirilmaz.
- Non-blocking local corrections, sonraki ilgili consolidated run icinde biriktirilir.
- Correction run yalniz PR review, merge safety, tests veya repository truth blocked ise kullanilir.
- Post-merge local sync her merge sonrasi hemen kosmak zorunda degildir.
- Guvenliyse post-merge sync, sonraki Codex-required task'in ilk aksiyonu olarak yapilir.
- O zamana kadar local repository synchronized diye iddia edilmez.
- Immediate post-merge sync yalniz immediate local follow-up, uncertain local state veya explicit user request durumunda ayrica yapilir.

### Metadata churn avoidance

- Bir result/state dosyasi kendi icindeki commit'in SHA'sini yazabilsin diye ekstra Codex run veya commit uretilmez.
- Final branch-head SHA ve divergence Issue completion comment ve PR metadata icinde kaydedilebilir.
- Ikinci metadata commit yalniz real contradiction, unsafe state veya blocking omission varsa gerekir.

---

## 9. Zorunlu Yerel Doğrulama

Her adımın sonunda en az şu kontroller yapılır:

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json
git diff --check
git diff -- app tests .github/workflows requirements.txt
```

Ayrıca doğrulanır:

- Değişen dosyalar görev kapsamıyla aynı mı?
- Gerekli dosyaların tamamı yerelde fiziksel olarak mevcut mu?
- `exports/` temiz mi ve yalnız `.gitkeep` içeriyor mu?
- Ignored ZIP aynı yerde ve dokunulmamış mı?
- Local branch SHA ile remote branch SHA aynı mı?
- Branch divergence `0 0` mı?
- Final `git status --short --branch` temiz mi?
- Commit ve push sonucu raporlandı mı?

Üretim kodu değiştiyse ilgili test eklenir veya güncellenir. Dokümantasyon-only adımlarda üretim kodu ve test davranışı değiştirilmez.

---

## 10. GitHub Actions ve CI Durumu

GitHub Actions workflow dosyası repoda korunur:

```text
.github/workflows/pytest.yml
```

Ancak otomatik workflow şu anda **manuel olarak devre dışıdır**.

Neden:

- GitHub hesabındaki billing kilidi runner’ın başlamasını engelliyordu.
- İşler test adımları başlamadan başarısız oluyor ve gereksiz e-posta üretiyordu.
- Kullanıcı bu borcu/ücreti ödemeyeceğini belirtti.

Bu nedenle:

- GitHub Actions yeniden etkinleştirilmez.
- Workflow dosyası silinmez veya gereksiz yere değiştirilmez.
- Required status checks etkinleştirilmez.
- Yeni push sonrasında CI run oluşmaması beklenen davranıştır.
- Güvenlik doğrulaması yerel test ve yerel Git kanıtlarıyla yapılır.

CI ancak kullanıcı açıkça isterse ve hesap kilidi çözülmüşse ayrı bir adımla yeniden değerlendirilir.

---

## 11. `.cse` Kayıt Disiplini

Her adımda aşağıdaki dosyalar kullanılır:

```text
.cse/tasks/<issue_no>_task.md
.cse/results/<issue_no>_result.md
.cse/state/project_state.json
```

### Task dosyası en az şunları içermelidir

- Resmî yerel repo yolu
- Beklenen base commit
- Branch adı
- Codex model secimi
- Reasoning seviyesi
- Model/reasoning secim nedeni
- Yetkili dosyalar
- Yapılacak iş
- Yasak kapsam
- Yerel doğrulamalar
- Commit/push/PR/merge izinleri
- Post-merge sync zorunluluğu

### Result dosyası en az şunları içermelidir

- Resmî yerel yol
- Senkronize `master` ve `origin/master` SHA
- Master divergence
- Yerel/uzak branch SHA
- Branch divergence
- Değişen dosyalar
- Fiziksel yerel dosya doğrulaması
- Test sonucu
- `git diff --check`
- Protected path diff
- `exports/` durumu
- ZIP durumu
- Final Git status
- Push sonucu
- PR durumu
- Sonraki dar adım

State/result dosyalarına henüz gerçekleşmemiş “push tamamlandı”, “çalışma ağacı temiz” veya “branch farkı 0 0” gibi ifadeler yazılmaz. Her kayıt gerçek komut çıktısına dayanır.

---

## 12. GitHub ve Merge Kuralları

- Varsayılan branch: `master`
- Yeni teknik iş doğrudan `master` üzerinde yapılmaz.
- PR’lar önce Draft açılır.
- Merge yöntemi: **Squash merge**
- Force push yapılmaz.
- Branch deletion veya destructive Git işlemi otomatik yapılmaz.
- Merge, kapsam/test/state incelemesi geçmeden yapılmaz.
- Kullanıcının `devam`, `işlem tamam` veya benzeri açık devam talimatı; mevcut işi inceleme ve güvenliyse akışı ilerletme yetkisidir. Açık eksik veya çelişki varsa merge yerine düzeltme istenir.

---

## 13. Codex ve ChatGPT Sorumlulukları

### Codex

- Resmî yerel repoda çalışır.
- Yerel değişiklikleri korur; beklenmeyen durumda durur.
- Her execution basinda required source pre-read sirasini uygular.
- Yalnız local project-file edit, local test, commit/push veya post-merge local synchronization gerektiğinde çağrılır.
- Branch/task/dosya/test/commit/push işlemlerini yerelden yapar ve completion evidence’i güncel GitHub Issue’a ekler.
- Görev kapsamını genişletmez.
- Kanıtlanmamış durum yazmaz.
- PR veya merge işlemi yalnız görev açıkça yetki verirse yapılır; varsayılan olarak PR’ı ChatGPT açar.

### ChatGPT

- Kullanıcının `devam` veya eşdeğer komutundan sonra her işlem öncesinde GitHub Issue, PR, branch, diff, comments, checks ve merge state’i doğrular.
- Codex gerekip gerekmedigine ChatGPT karar verir.
- Codex gerekiyorsa kullaniciya `Codex çalışmalı` der ve kisaca nedenini aciklar.
- Codex gerekmiyorsa GitHub-native inspection, planning, Issue/PR/comment/review/merge-state ve conceptual work'u kendisi yurutur.
- Gereksiz immediate veya fragmented Codex run uretmez; non-blocking local corrections'i sonraki consolidated run'a biriktirir.
- Son güvenli commit’i ve aktif adımı takip eder.
- GitHub-native Issue creation/update, review comments, Draft PR creation, ready transition, merge ve next Issue creation işlemlerini doğrudan yapar.
- Küçük ve açık Issue tanımlar; Codex instruction ve completion evidence’in güncel Issue üzerinden paylaşılmasını sağlar.
- Codex reasoning seviyesini belirtir.
- GitHub branch diff’ini, dosya kapsamını, result/state kayıtlarını ve test kanıtını inceler.
- Proje dosyalarını GitHub üzerinden üretmez.
- Eksik durumda düzeltme talimatı verir.
- Güvenli durumda Draft PR’ı ready yapar ve kullanıcı onayıyla squash merge eder.
- Merge sonrası Codex’e yerel `master` senkronizasyonunu ilk işlem olarak verir.

### Kullanıcı

- Normalde yalnız `devam` veya eşdeğer bir continuation command yazar; büyük instruction/result bloklarını ChatGPT ve Codex arasında kopyalamak zorunda değildir.
- Yeni chat'te normal devam icin `devam` veya `GitHub'dan devam et` demesi yeterlidir; ChatGPT GitHub repository truth'u okur.
- Ürün kapsamı ve merge için nihai karar sahibidir.
- Yerel çalışma kopyasının ve özel verilerin sahibidir.

Resmî yerel repository project-file changes için execution source, GitHub ise synchronized coordination/review surface olarak kalır. ChatGPT her sonraki action öncesinde GitHub state’i doğrular.

---

## 14. Codex Modeli ve Reasoning Seviyesi

Her yeni Codex instruction ve `.cse/tasks/<step>_task.md` kaydi acikca su uc bilgiyi tasir:

1. Codex model secimi
2. Reasoning seviyesi
3. Model ve seviyenin neden secildigi

Model isimleri UI'da degisebilecegi icin obsolete hard-coded model adi korunmaz; kullanicinin current Codex selector'unda gorunen tam etiket kullanilir.

- **High:** dar dokümantasyon-only adımlar, rutin Git/GitHub durumu ve düşük riskli state güncellemeleri.
- **Extra High:** Python mantığı, veri sözleşmeleri, parser/formatter, test matrisi, CLI, migration sınırları, regresyon riski ve karmaşık CI tanısı.

Çoklu kanonik kaynak, source authority, repository truth drift veya kalıcı ürün politikası değişikliği de kod değiştirmese bile çelişki riski nedeniyle **Extra High** kullanır.

- Documentation-only, routine verification, commit/push ve low-risk state sync icin selector'daki standard full Codex model ve `high` reasoning kullanilir.
- Production code, executable tests, generator scripts, contracts, regressions, migrations veya multi-file behavior changes icin selector'daki en guclu full Codex model ve `extra high` reasoning kullanilir.
- Contract-defining veya regression-sensitive CSE islerinde Spark, fast veya lightweight varyant secilmez.

Her Issue ve task dosyasında model, reasoning ve secim gerekcesi acikca yazilir.

---

## 15. Dokümantasyon ve Öğrenim Disiplini

Her teknik adımda uygun olduğunda:

- `docs/NNN_*.md`
- `learning/NNN_*.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/results/NNN_result.md`
- `.cse/state/project_state.json`

güncellenir.

Dokümantasyon üretmek, gerçek kod/test/yerel dosya kanıtının yerine geçmez.
Öğrenme, podcast ve tarihsel çıktı korunur; fakat current-state veya ürün otoritesi değildir ve gerçek saha değeri üreten production zincirini bloke etmez.

### Podcast kuralı

Beş adımlık podcast cadence'i tarihsel öğrenme protokolüdür; production fazları için giriş kapısı değildir. Podcast üretildiğinde Podcast 035 ve sonraki strict notes, kendi previous-summary section'i içinde `001..note.step_start-1` canonical step headings'ini exactly once ve ascending order ile taşır.

---

## 16. ZIP ve Handoff Kuralı

Eski “her iteration sonunda ZIP oluştur” kuralı artık geçerli değildir.

Güncel kural:

- Mevcut ignored ZIP yalnız acil/offline yedektir.
- Her adımda yeni ZIP üretilmez.
- ZIP stage edilmez, silinmez, taşınmaz, yeniden adlandırılmaz veya commitlenmez.
- Yeni chat veya continuation icin ZIP/handoff upload gerekmez.
- Yeni chat GitHub'dan bootstrap eder: `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`.
- `chat_handoff/` optional ve tarihsel kalir; projeyi resume etmek icin zorunlu degildir.
- GitHub gecici olarak erisilemiyorsa stale ZIP, stale memory veya eski handoff metnine sessizce dusulmez; current repository truth dogrulanamadigi acikca soylenir.
- Sohbet aktarımı gerektiğinde `chat_handoff/` dosyaları guncellenebilir; bu işlem normal teknik adımların zorunlu parçası değildir.

---

## 17. Güncel Güvenli Nokta ve Aktif İş Doğrulama Prosedürü

Bu kalıcı operasyon belgesine sabit commit, test sayısı, aktif Issue, PR veya Step snapshot'ı gömülmez.

Her yeni görevde:

1. `git fetch origin --prune` ile remote bilgi yenilenir.
2. `origin/master` HEAD ile current Issue'daki `EXPECTED_BASE_SHA` karşılaştırılır.
3. Açık Issue/PR ve ilgili branch diff'i GitHub üzerinden doğrulanır.
4. Önceki görevin completion evidence'i okunur.
5. Resmî `V:` kopyasında master SHA ve divergence `0 0` doğrulanır.
6. `.cse/state/project_state.json` yalnız bu kanıtların ikincil factual mirror'ı olarak okunur.

Güncel durum iddiası README, ROADMAP, handoff, ZIP, eski task/result veya sohbet hafızasından tek başına çıkarılmaz. Çelişki varsa production davranışına dokunmadan factual drift ayrı yetkili görevde düzeltilir.

---

## 18. İletişim ve Raporlama Stili

- Operasyonel yanıtlar kısa, doğrudan ve numaralı durum özeti şeklinde verilir.
- Kullanıcı uzun analiz istemedikçe gereksiz uzun açıklama yapılmaz.
- Başarı iddiası yalnız doğrulanmış GitHub veya yerel Codex raporuna dayanır.
- Eksik, çelişkili veya doğrulanamayan nokta açıkça belirtilir.
- “Güvenli nokta” yalnız test, diff, kapsam, yerel dosya, branch senkronizasyonu ve çalışma ağacı kanıtları uygunsa kullanılır.

---

## 19. Ana Karar Cümlesi

> CSE, yalnız şantiye şefinin kullandığı; `Yakala -> İşle -> Takip et -> Doğrula -> Günlüğe al` döngüsüyle çalışan local-first ve mobile-first kişisel saha asistanıdır. Araç bakımından geniş, kullanıcı modeli bakımından tek sahipli kalır; kayıt kapsamını erişim rolüyle değil `private | project` output/paylaşım uygunluğuyla ayırır.
