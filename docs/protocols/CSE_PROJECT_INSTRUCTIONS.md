# CSE Güncel Proje Talimatları

**Belge türü:** Ana proje talimatı / proje kaynağı
**Geçerlilik tarihi:** 2026-07-11
**Önerilen proje yolu:** `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
**Durum:** Önceki proje talimatlarıyla çelişen maddelerde bu belge geçerlidir.

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

1. Bu belge: `CSE_GUNCEL_PROJE_TALIMATLARI.md`
2. Güncel GitHub Issue ve yerelde oluşturulan `.cse/tasks/<step>_task.md`
3. `.cse/state/project_state.json`
4. İlgili `.cse/results/<step>_result.md`
5. `ROADMAP.md`
6. `docs/project_decisions.md`
7. `CHANGELOG.md`
8. `CSE_STRATEGIC_PRODUCT_DIRECTION.md`
9. Güvenilir veri omurgası ilkeleri
10. `chat_handoff/` özet dosyaları
11. Eski ZIP ve arşiv paketleri

`chat_handoff/` dosyaları sohbet aktarımı içindir; Git durumu, yerel çalışma ağacı veya güncel Issue/PR kayıtlarının yerine geçmez.

---

## 5. Resmî Yerel Çalışma Kopyası

Bütün proje dosyası üretimi ve düzenlemesi şu resmî yerel repoda yapılır:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

### Zorunlu kural

- Proje dosyalarını yalnız GitHub web arayüzü, connector veya API üzerinden oluşturmak tamamlanmış iş sayılmaz.
- GitHub senkronize remote ve inceleme yüzeyidir.
- Yerel repo; dosya oluşturma, düzenleme, test, kalite kontrol, commit ve push için yürütme kaynağıdır.

ChatGPT GitHub üzerinde Issue, yorum, Draft PR, inceleme durumu ve merge işlemlerini yönetebilir. Proje dosyalarını doğrudan GitHub üzerinden üretmez veya düzeltmez; bunu Codex resmî yerel repoda yapar.

---

## 6. Her Adım Öncesi Zorunlu Yerel Kontrol

Codex herhangi bir branch değişikliği, pull, düzenleme, commit veya push öncesinde yerel durumu kontrol eder:

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'

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

Her adım aşağıdaki sırayla yürütülür:

1. ChatGPT küçük ve sınırları net bir GitHub Issue açar.
2. Issue, resmî yerel repo yolunu ve beklenen base commit’i içerir.
3. Codex yerel `master`ı senkronlar.
4. Codex step branch’ini yerelde oluşturur:

   ```text
   step-NNN-kisa-amac
   ```

5. Codex `.cse/tasks/NNN_task.md` dosyasını yerelde oluşturur.
6. Bütün yetkili dosyalar fiziksel olarak yerel çalışma ağacında oluşturulur.
7. Codex test ve kalite kontrollerini yerelde çalıştırır.
8. Görev izin veriyorsa Codex yerelden commit ve push yapar.
9. Codex branch/remote farkını `0 0` olarak doğrular.
10. ChatGPT pushlanmış branch’i GitHub’dan inceler ve Draft PR açar.
11. Eksik veya çelişkili kayıt varsa merge edilmez; düzeltme yerelde yapılır.
12. İnceleme geçerse PR ready yapılır ve kullanıcı onayıyla squash merge edilir.
13. Merge sonrası yerel `master` yeni merge commit’ine fast-forward edilir.

Branch ve task dosyası GitHub connector üzerinden önceden oluşturulmaz.

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
- Branch/task/dosya/test/commit/push işlemlerini yerelden yapar.
- Görev kapsamını genişletmez.
- Kanıtlanmamış durum yazmaz.
- PR veya merge işlemi yalnız görev açıkça yetki verirse yapılır; varsayılan olarak PR’ı ChatGPT açar.

### ChatGPT

- Son güvenli commit’i ve aktif adımı takip eder.
- Küçük ve açık Issue tanımlar.
- Codex reasoning seviyesini belirtir.
- GitHub branch diff’ini, dosya kapsamını, result/state kayıtlarını ve test kanıtını inceler.
- Proje dosyalarını GitHub üzerinden üretmez.
- Eksik durumda düzeltme talimatı verir.
- Güvenli durumda Draft PR’ı ready yapar ve kullanıcı onayıyla squash merge eder.
- Merge sonrası Codex’e yerel `master` senkronizasyonunu ilk işlem olarak verir.

### Kullanıcı

- Ürün kapsamı ve merge için nihai karar sahibidir.
- Yerel çalışma kopyasının ve özel verilerin sahibidir.

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

Her beş adımlık teknik blok tamamlandığında NotebookLM podcast notu oluşturulur. Son tamamlanan podcast, Steps 196–200 kapsamındaki Podcast 030’dur. Doğal sonraki podcast aralığı Steps 201–205’tir ve Step 205 tamamlandıktan sonra oluşturulmalıdır.

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

- Tamamlanan adım: **Step 203**
- Merge edilen PR: **#22**
- `master` commit:

```text
583f8539d9522027f1578a91b0298a8bdf21a1c9
```

- Son bilinen yerel test sonucu: **413 passed**
- GitHub Actions: **devre dışı**

### Aktif iş

- Issue: **#23**
- Adım: **Step 204 — Handover QC view-model için kanonik fixture adları ve assertion checklist planı**
- Beklenen branch:

```text
step-204-handover-qc-fixture-assertion-plan
```

- İlk işlem: yerel `master`ı `583f8539d9522027f1578a91b0298a8bdf21a1c9` commit’ine fast-forward etmek.
- Bu adım documentation/state-only olmalıdır.
- Executable fixture, üretim kodu veya test eklenmemelidir.
- Reasoning: **Extra High**

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
