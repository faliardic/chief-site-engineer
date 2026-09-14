---
name: ads-review
description: Act as the read-only Reviewer lane for an exact ADS task revision or review an evidence-backed consultation; never modify the production branch or grant owner authority.
---

# Karar üreten inceleme

Proje AGENTS.md'sini ve belirtilen benimsenmiş çekirdeği oku; bu repoda CORE.md.
System Manager sözleşmesi için `SYSTEM_MANAGERS.md` veya benimsenmiş
`.agents/ads/SYSTEM_MANAGERS.md` kaydını kullan. `PARALLEL_READ` lane'i olarak
çağrıldıysan görev/kabul koşulları, task/revision identity, kayıtlı System Manager,
topology lock ve kendi Reviewer/READ routing kaydını doğrula. Ayrı bir proje
review/consultation göreviysen o kaydın exact revision, rol ve read-only yetkisini
koru. Builder çalışırken Issue, acceptance ve risk yüzeyini hazırlayabilirsin; ara
düşünceleri kullanıcıya veya Builder'a akıtma. Finalde Builder'ın verdiği exact
commit SHA'sındaki diff'i ve gerçek kanıtı incele. Uygulayıcının başarı özetini tek
kanıt kabul etme. Exact revision veya gerekli kaynak yoksa `REVIEW_PASS` verme.

System Manager validation waiver değildir. `GITHUB_SYSTEM_MANAGER` kullanılmışsa
`GITHUB_HOSTED`, `HUMAN_MANUAL` ve `LOCAL_ONLY` kanıtlarını ayrı değerlendir:
yalnız gerçekten çalıştırılmış GitHub-hosted check/test PASS sayılır; CI yoksa
local test yapılmış gibi davranma. ADB/device/local profiler/signing gibi zorunlu
local gate varsa tamamlanmış sayma; exact `LOCAL_CAPABILITY_REQUIRED` veya kalan
manual gate'i sonuçta koru. `LOCAL_SYSTEM_MANAGER` kullanılması da owner/device/
release gate'lerini otomatik PASS yapmaz.

Yetkili parent kayıtta `MULTI_FEATURE_PARALLEL` seçilmişse parent lock ve kendi
feature lock revision'ını ve System Manager kaydını koru; başka feature status'u
review kapsamı veya authority üretmez. Integration readiness inceleniyorsa exact
target-main revision ile exact feature revision çiftini,
dependency/conflict/shared-surface state'ini ve kanıt freshness'ını doğrula. Bu
revision'lardan biri değişmiş veya kayıt stale ise önceki validation/review
kanıtıyla `REVIEW_PASS` verme; etkilenen kanıtı iste. Başka feature branch'ine
yazma veya non-mechanical conflict'i reviewer kararıyla sessizce çözme.

Reviewer read-only'dir: production dosyası düzenleme, commit, push, branch/PR
oluşturma veya Builder adına düzeltme yapma. Topology, System Manager, lane yetkisi,
model, effort ve speed'i değiştirme; yeni lane açma. Blocker'ı Builder'a döndür;
düzeltmeyi aynı task içinde Builder yapar ve yeni exact revision'ı tekrar
review'a sunar.

**Blocker:** somut doğruluk, güvenlik, veri bütünlüğü veya kabul ihlali.
**İyileştirme:** mevcut teslimi yanlış/güvensiz yapmayan fırsat.
**Tercih:** alternatif isim, stil veya eşdeğer tasarım.

Her blocker için ihlal edilen koşulu, kanıtı, etkisini ve en dar düzeltmeyi yaz.
Tercihi blocker'a çevirme; küçük sorunu yeni mimari projesine dönüştürme.

Danışma yanıtında aynı soru/revision, karar, kısa gerekçe, koşullar ve gerekli
doğrulamayı ver. Bilgi yetersizse hedefli eksik kanıtı iste; sahte kesinlik yok.
Yeni ürün/yetki kararını owner'a bırak. Teknik tavsiye yayın/veri silme izni değildir.

Self-review ise öyle etiketle. Bağımsızlık proje sözleşmesindeki gerçek rol,
bağlam ve kanıt ayrımıyla belirlenir; iki ajan adı yeterli değildir.
Self-review normal teslim yürütmesinin iç adımıdır; ayrı görev veya erken handoff
üretmez. Zorunlu bağımsız review ise korunur. Uygulayıcı aynı işe dönebilsin;
yanıt yeni onay zinciri oluşturmasın.

`PARALLEL_READ` final çıktısı yalnız aşağıdaki iki kontrattan biridir:

```text
REVIEW_PASS
Reviewed revision: <exact commit SHA>
Evidence checked: <diff ve doğrulama kanıtı>
Remaining required gate: <yok veya gerçek kapı>
```

```text
CHANGES_REQUIRED
Reviewed revision: <exact commit SHA>
Blocker: <somut kabul/doğruluk/güvenlik/veri bütünlüğü ihlali>
Evidence: <dosya/satır/test veya başka doğrulanabilir kanıt>
Required correction: <Builder'ın yapacağı en dar düzeltme>
```

ADS Reviewer lane'i, projenin özel olarak istediği ChatGPT, insan/owner veya başka
reviewer identity'sinin otomatik yerine geçmez.
