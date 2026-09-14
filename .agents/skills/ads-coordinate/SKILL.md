---
name: ads-coordinate
description: Coordinate an explicitly authorized MULTI_FEATURE_PARALLEL parent across up to three separate ADS feature envelopes; not for creating authority or runtime automation.
---

# Yetkili multi-feature parent'ı koordine et

Projenin AGENTS.md'sini ve orada belirtilen benimsenmiş ADS çekirdeğini oku; bu
repoda CORE.md. System Manager sözleşmesi için `SYSTEM_MANAGERS.md` veya
benimsenmiş `.agents/ads/SYSTEM_MANAGERS.md` kaydını kullan. Bu skill parent mode,
feature, System Manager veya lane yetkisi üretmez. Yalnız yetkili kayıtta açıkça
`MULTI_FEATURE_PARALLEL` seçilmişse kullan; seçilmemişse mevcut tek-feature
`SINGLE` / `PARALLEL_READ` davranışını koru.

Başlamadan parent task ve lock revision'ını, exact target-main revision'ı ve
`MAX_OPEN_FEATURES = 3` sınırını doğrula. Owner/review/authority bekleyenleri de
açık feature sayısına kat. Her feature için ayrı task/Issue, branch/worktree,
Draft PR, kapsam/Git yetkisi, `SINGLE` veya `PARALLEL_READ` feature lock revision'ı,
kayıtlı `LOCAL_SYSTEM_MANAGER` veya `GITHUB_SYSTEM_MANAGER`, resolved provider,
lane routing'i ve tek production writer bulunmalıdır. Eksik kayıt için yeni
manager, provider, feature veya dördüncü slot uydurma.

Farklı feature'lar farklı System Manager kullanabilir; bu cross-feature WRITE veya
authority inheritance sağlamaz. Manager seçimi topology değildir ve parent
koordinatör bir feature'ın manager'ını sessizce değiştiremez. Ortak physical
device, SDK, local filesystem, signing veya build resource'ları için gerekli
sorumluluk/sıra ayrıca kaydedilir. `GITHUB_SYSTEM_MANAGER` local capability varmış
gibi değerlendirilmez.

Başlangıç kaydında ilişkileri `INDEPENDENT`, `COORDINATION_REQUIRED` veya
`DEPENDENCY_BLOCKED` olarak sınıflandır. Varsa shared contract/dependency'yi,
dar `SHARED_INTEGRATION_SURFACE` kapsamını ve tek sorumlusunu, ayrıca ortak
runtime kaynaklarının sorumluluk/sırasını kaydet. Aynı path'e temas tek başına
global serialization değildir; bu da başka feature branch'ine WRITE yetkisi
vermez.

Koordinasyonu event/state handoff'larıyla sınırla. ADS kaynak reposunda
`TEMPLATES.md`, benimsenmiş projede `.agents/ads/TEMPLATES.md` içindeki
`FEATURE_STATUS`, `CROSS_FEATURE_CONFLICT`, `DEPENDENCY_SIGNAL`,
`SHARED_INTEGRATION_HANDOFF`, `INTEGRATION_HANDOFF`,
`OWNER_ATTENTION_REQUIRED` ve `MULTI_FEATURE_RESUME` kontratlarını kullan.
Gerçek transport veya agent başlatma otomatik varsayılmaz; handoff'u görevde
yetkilendirilmiş kayıt/kanala yaz. Rutin teknik ilerlemeyi owner mesaj taşıma
işine çevirme ve değişmeyen durum için tekrar sinyal üretme.

Her status/handoff task/feature kimliği, System Manager, branch, exact feature
revision, exact target-main revision ve freshness source/time taşır. Kullanımdan
önce kaynağı ve revision'ları yeniden doğrula. Stale kayıt
active/readiness/completion, review veya integration kanıtı değildir; scope,
routing, manager, READ/WRITE, ürün ya da Git authority üretmez.

Bağımlılık yalnız gerçek dependent bölümü bekletir; aynı feature'ın bağımsız ve
yetkili kısmı ilerleyebilir. Bir feature beklerken başka kayıtlı ve bağımsız
feature ilerleyebilir, fakat yeni/dördüncü feature açılmaz. Conflict mekanik
değilse veya ürün davranışı seçimi gerekiyorsa ilgili feature sahibine geri
döndür; entegratör sessiz çözüm uydurmaz.

Bir feature ancak gerekli kapıları geçmiş exact feature revision + exact
target-main revision çifti için `INTEGRATION_HANDOFF` üretir. Target main veya
feature revision değişirse etkilenen validation/review kanıtını geçerli sayma;
etkiyi yeniden değerlendir ve gerekli kontrolleri tekrarla. Shared yüzey handoff'u
yalnız kayıtlı dar yüzey ve tek sorumlu için geçerlidir; otomatik merge/release,
cross-feature WRITE veya authority inheritance sağlamaz.

Owner'a yalnız gerçek product, acceptance veya authority sorusunu tek
`OWNER_ATTENTION_REQUIRED` handoff'uyla taşı. Teknik iç ilerleme, rutin status,
mekanik conflict veya çözülebilir dependency owner kapısı değildir. Parent
restart/resume'da parent ve feature lock'larını, System Manager kayıtlarını, exact
revision'ları, WIP sayımını ve bekleyen gate'leri koru; freshness
doğrulanamıyorsa `MULTI_FEATURE_RESUME` çıktısında stale olarak işaretle ve kanıt
yerine kullanma.

Bu workflow controller, daemon, dashboard, scheduler, automatic provider failover,
otomatik agent spawning, otomatik merge/release veya ürün adoption'ı değildir.
Parent kayıt feature authority'lerini birleştirmez; her feature'ın kendi
Builder/WRITE lane'i dışında production yazarı yoktur.
