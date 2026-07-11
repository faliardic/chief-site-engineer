# CSE Güncel Proje Talimatları

**Belge türü:** Ana proje talimatı / proje kaynağı
**Geçerlilik tarihi:** 2026-07-11
**Canonical proje yolu:** `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
**Durum:** Bu tracked belge, proje talimatlari icin tek yetkili kaynaktir.

---

## 1. Projenin Amacı

CSE, aktif şantiye şeflerinin WhatsApp, telefon galerisi, Excel, klasör, defter ve e-posta arasında dağılan saha bilgisini; hızlı kayıt, fotoğraf/dosya kanıtı, durum takibi, arşiv, devir ve ileride AI destekli soru-cevap düzenine dönüştüren sade ve güvenilir bir saha hafızası uygulamasıdır.

CSE’nin amacı büyük inşaat yönetim platformlarının küçük bir kopyasını yapmak değildir. İlk gerçek rakipleri şunlardır:

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
8. Özel alan verileri kullanıcıya aittir ve proje devrinde yeni şantiye şefine aktarılmaz.
9. Yeni şantiye şefinin özel alanı sıfırdan açılır.
10. Devir için gerekli bilgi özel alanda bırakılmaz; resmî kayda veya açıkça seçilmiş handover package içine dönüştürülür.
11. Hard validation, otomatik blocking, migration, persistence, audit, backup/restore, API, GUI ve CLI çalışmaları ayrı ve açık görev kapsamı gerektirir.
12. `requires_human_review` yalnız insan inceleme sinyalidir; otomatik kabul, ret, onay veya paket engelleme kararı değildir.
13. Sistem kendiliğinden `blocked` durumu üretmez.
14. Resmî-devredilebilir veri ile özel-devredilemez veri bütün ekran, export ve devir örneklerinde ayrı tutulur.

---

## 3. Saha Kullanım İlkesi ve İlk MVP

Sahada ilk kayıt açma süresi hedefi **20–30 saniyeyi geçmemelidir**.

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

Bu çekirdek değer kanıtlanmadan karmaşık dashboard, çok kullanıcı, bulut, ağır AI, büyük raporlama ekranları veya geniş platform modülleri önceliklendirilmez.

---

## 4. Kaynak ve Karar Önceliği

Bir çelişki olduğunda aşağıdaki sıra uygulanır:

1. Tracked canonical proje talimatlari: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
2. Güncel GitHub Issue ve yerelde oluşturulan `.cse/tasks/<step>_task.md`
3. `.cse/state/project_state.json`
4. İlgili `.cse/results/<step>_result.md`
5. Sırasıyla `ROADMAP.md`, `docs/project_decisions.md`, `CHANGELOG.md`, güvenilir veri omurgası ilkeleri, `chat_handoff/` özetleri ve eski ZIP/arşiv paketleri.

Kök dizindeki `CSE_GUNCEL_PROJE_TALIMATLARI.md` dosyasi artik higher-priority override degildir. Bu dosya, yalniz resmi yerel çalışma kopyasinda kolay okuma icin tutulabilecek optional local mirror'dir.

Local mirror mevcutsa tracked canonical dosya ile byte-for-byte ayni metni tasimalidir. Mirror `.git/info/exclude` uzerinden ignored kalir, stage edilmez ve commitlenmez. Mirror ile canonical arasinda fark varsa yetkili kaynak yine tracked canonical dosyadir ve mirror duzeltilmelidir.

`chat_handoff/` dosyaları sohbet aktarımı içindir; Git durumu, yerel çalışma ağacı veya güncel Issue/PR kayıtlarının yerine geçmez.

---

## 5. Resmî Yerel Çalışma Kopyası

Bütün proje dosyası üretimi ve düzenlemesi şu resmî yerel repoda yapılır:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

### Zorunlu kural

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
4. Codex yerel `master`ı senkronlar ve step branch’ini yerelde oluşturur:

   ```text
   step-NNN-kisa-amac
   ```

5. Codex `.cse/tasks/NNN_task.md` ve bütün yetkili project files’ı fiziksel yerel çalışma ağacında oluşturur veya düzenler.
6. Codex test ve kalite kontrollerini yerelde çalıştırır.
7. Görev izin veriyorsa Codex yerelden commit/push yapar ve branch/remote farkını `0 0` doğrular.
8. Codex factual completion evidence’i güncel GitHub Issue’a ekler.
9. ChatGPT GitHub branch diff’ini, comment/evidence’i ve review state’i inceler; güvenliyse Draft PR’ı doğrudan oluşturur.
10. Eksik veya çelişkili kayıt varsa ChatGPT Issue üzerinden local correction instruction verir; merge yapılmaz.
11. İnceleme geçerse ChatGPT PR’ı ready yapar ve kullanıcı onayıyla squash merge eder.
12. ChatGPT gerektiğinde sonraki Issue’yu doğrudan oluşturur.
13. Merge sonrası Codex yalnız gerektiğinde yerel `master`ı yeni merge commit’ine fast-forward eder.

ChatGPT GitHub-native Issue creation/update, review comment, Draft PR creation, ready transition, merge ve next Issue creation işlemlerini doğrudan yapar. Branch/task/project files GitHub connector üzerinden üretilmez; GitHub-only project-file creation completion değildir.

---

## 9. Zorunlu Yerel Doğrulama

Her adımın sonunda en az şu kontroller yapılır:

```powershell
python -m pytest
git diff --check
git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml
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
.cse/tasks/NNN_task.md
.cse/results/NNN_result.md
.cse/state/project_state.json
```

### Task dosyası en az şunları içermelidir

- Resmî yerel repo yolu
- Beklenen base commit
- Branch adı
- Reasoning seviyesi
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
- Yalnız local project-file edit, local test, commit/push veya post-merge local synchronization gerektiğinde çağrılır.
- Branch/task/dosya/test/commit/push işlemlerini yerelden yapar ve completion evidence’i güncel GitHub Issue’a ekler.
- Görev kapsamını genişletmez.
- Kanıtlanmamış durum yazmaz.
- PR veya merge işlemi yalnız görev açıkça yetki verirse yapılır; varsayılan olarak PR’ı ChatGPT açar.

### ChatGPT

- Kullanıcının `devam` veya eşdeğer komutundan sonra her işlem öncesinde GitHub Issue, PR, branch, diff, comments, checks ve merge state’i doğrular.
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
- Ürün kapsamı ve merge için nihai karar sahibidir.
- Yerel çalışma kopyasının ve özel verilerin sahibidir.

Resmî yerel repository project-file changes için execution source, GitHub ise synchronized coordination/review surface olarak kalır. ChatGPT her sonraki action öncesinde GitHub state’i doğrular.

---

## 14. Reasoning Seviyesi

- **High:** dokümantasyon-only adımlar, rutin Git/GitHub durumu, protokol/state güncellemeleri.
- **Extra High:** Python mantığı, veri sözleşmeleri, parser/formatter, test matrisi, CLI, migration sınırları, regresyon riski ve karmaşık CI tanısı.

Her Issue ve task dosyasında Codex ve ChatGPT review seviyesi açıkça yazılır.

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

### Podcast kuralı

Her beş adımlık teknik blok tamamlandığında NotebookLM podcast notu oluşturulur. Podcast 030, Steps 196-200 araligini kapsar. Podcast 031, Steps 201-205 araligini kapsar. Dogal sonraki besli aralik Step 206 ile baslar.

---

## 16. ZIP ve Handoff Kuralı

Eski “her iteration sonunda ZIP oluştur” kuralı artık geçerli değildir.

Güncel kural:

- Mevcut ignored ZIP yalnız acil/offline yedektir.
- Her adımda yeni ZIP üretilmez.
- ZIP stage edilmez, silinmez, taşınmaz, yeniden adlandırılmaz veya commitlenmez.
- Yeni handoff ZIP yalnız kullanıcı açıkça isterse oluşturulur.
- Sohbet aktarımı gerektiğinde `chat_handoff/` dosyaları güncellenebilir; bu işlem normal teknik adımların zorunlu parçası değildir.

---

## 17. Güncel Güvenli Nokta ve Aktif İş

### Son güvenli GitHub noktası

- Tamamlanan adım: **Step 205**
- Merge edilen PR: **#26**
- Tamamlanan Issue: **#25**
- `master` commit:

```text
92a15f2a55e6bfda42d50b8ef7dea651ff496f62
```

- Son doğrulanan yerel test sonucu: **413 passed**
- GitHub Actions: workflow mevcut, otomatik execution manuel olarak devre dışı

### Aktif iş

- Issue: **#28**
- Adım: **Step 206 — Step 205 merged truth, Podcast 031, and instruction authority closure**
- Branch:

```text
step-206-podcast-031-and-authority-closure
```

- Kapsam: **documentation/state-only**
- Reasoning: **High**
- Bu adim Step 205 merge gercegini final hale getirir, Podcast 031'i olusturur, podcast protocol'unu tazeler ve instruction authority'yi tracked canonical dosyada birlestirir.
- Step 206 merge iddiasi, PR creation, merge veya product implementation bu aktif is kapsaminda yazilmaz.

Bu bölüm proje ilerledikçe güncellenir; yukarıdaki kalıcı kurallar değişmez.

---

## 18. İletişim ve Raporlama Stili

- Operasyonel yanıtlar kısa, doğrudan ve numaralı durum özeti şeklinde verilir.
- Kullanıcı uzun analiz istemedikçe gereksiz uzun açıklama yapılmaz.
- Başarı iddiası yalnız doğrulanmış GitHub veya yerel Codex raporuna dayanır.
- Eksik, çelişkili veya doğrulanamayan nokta açıkça belirtilir.
- “Güvenli nokta” yalnız test, diff, kapsam, yerel dosya, branch senkronizasyonu ve çalışma ağacı kanıtları uygunsa kullanılır.

---

## 19. Ana Karar Cümlesi

> CSE; yerel resmî çalışma kopyasını yürütme kaynağı, GitHub’ı senkronize inceleme yüzeyi olarak kullanan; küçük, testli, belgeli ve geri alınabilir adımlarla geliştirilen; resmî kayıt ile özel alanı ayıran; hızlı saha kaydı, güvenilir arşiv ve kanıt zinciri üzerine kurulu bir şantiye hafızasıdır.
