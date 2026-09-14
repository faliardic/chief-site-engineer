---
name: ads-resume
description: Resume an authorized ADS task from current repository evidence. Use for continue, handover or interrupted work; not for inventing tasks or clearing approval gates.
---

# Kaldığın doğru işi bul

Projenin AGENTS.md'sini ve orada belirtilen benimsenmiş ADS çekirdeğini oku.
Bu repoda çekirdek CORE.md'dir. System Manager sözleşmesi için bu repoda
`SYSTEM_MANAGERS.md`, benimsenmiş projede `.agents/ads/SYSTEM_MANAGERS.md`
kullanılır. Başka repoda benimseme yoksa salt okunur durum raporundan öte ADS
yetkisi varsayma.

1. Repo/root, branch, head, staged/unstaged diff ve görev kimliğini doğrula.
2. Aktif Issue/PR ve son yetkili kararı bul; eski özetle production işi seçme.
3. Kayıtlı `LOCAL_SYSTEM_MANAGER` veya `GITHUB_SYSTEM_MANAGER` seçimini, resolved
   provider'ı, local capability gereksinimini, manual acceptance owner'ını ve
   manager lock kaydını bul. Bekleyen `LOCAL_CAPABILITY_REQUIRED` handoff'unu koru.
4. Kayıtlı task/revision identity, `SINGLE`/`PARALLEL_READ` topology, lane roster,
   her lane'in model/effort/speed/READ-WRITE kilidini, lock revision'ını ve routing
   authority'yi bul; bekleyen `ROUTING_ESCALATION_REQUIRED` kararını koru.
5. Bekleyen danışma, owner kabulü veya STOP olup olmadığını belirle.
6. Kayıp/çelişkili kapıyı açık sayma. Genel 'devam' veya restart onay değildir;
   manager/routing kaydı kayıpsa yeni seçim uydurma.
7. Mevcut kanıtın güncel diff, System Manager ve ortam için geçerli olup olmadığını
   belirle. `GITHUB_HOSTED`, `HUMAN_MANUAL` ve `LOCAL_ONLY` kanıtlarını birbirine
   dönüştürme.
8. Engeller yoksa kendi kayıtlı lane rolü, System Manager ve yetkisiyle aynı işe
   devam et. Yalnız Builder ads-deliver ile production yazma ve teslim yapar; Scout
   tek `SCOUT_RESULT`, Reviewer exact revision için `REVIEW_PASS` veya
   `CHANGES_REQUIRED` üretir. Read-only lane'i writer'a çevirme, eksik lane'i
   kendiliğinden açma veya topology/roster/manager değiştirme. Builder olarak devam
   ediyorsan kalan araştırma, uygulama, test/fix, self-review ve baştan yetkili
   teslimi tek yürütmede tamamla; yalnız durum raporu istendiyse uygulama başlatma.

`GITHUB_SYSTEM_MANAGER` altında zorunlu local capability hâlâ eksikse source
revision'ı ve tamamlanmış GitHub işini koru; handoff'taki exact local operation
dışında işi yeniden açma. `LOCAL_CAPABILITY_REQUIRED` yeni scope, WRITE veya risk
authority değildir. Local clone'a dönmeden önce remote truth + local status/drift
kontrolü yapılır; dirty local work sessizce overwrite/reset/clean edilmez.

Yetkili kayıtta `MULTI_FEATURE_PARALLEL` seçilmişse ayrıca parent task/lock
revision'ını, exact target-main revision'ı, `MAX_OPEN_FEATURES = 3` sayımını
(owner/review/authority wait dahil), feature roster ve ilişki sınıflarını,
her feature'ın System Manager seçimini, `SHARED_INTEGRATION_SURFACE` tek
sorumlusunu ve ortak runtime kaynak sırasını doğrula. Her feature'ın kendi
task/Issue, branch/worktree, Draft PR, authority, `SINGLE`/`PARALLEL_READ` lock
revision, System Manager ve tek writer sınırını koru. Parent kayıt feature
yetkilerini birleştirmez; resume yeni/dördüncü feature, cross-feature WRITE,
manager/routing değişikliği veya otomatik merge yetkisi değildir.

Son `FEATURE_STATUS`, conflict/dependency ve integration handoff'larının source,
freshness time, exact feature revision ve exact target-main revision'ını canlı
kaynakla karşılaştır. Revision veya görev durumu değişmişse ya da freshness
doğrulanamıyorsa kaydı stale say; readiness/completion/review kanıtı yerine
kullanma. ADS kaynak reposundaki `TEMPLATES.md` ya da benimsenmiş projedeki
`.agents/ads/TEMPLATES.md` içindeki `MULTI_FEATURE_RESUME` ile lock/gate'leri,
stale/invalidated kanıtı ve sıradaki tek yetkili işlemi kaydet. Bir feature
beklerken yalnız zaten roster'da bulunan bağımsız ve yetkili feature ilerleyebilir.

Bekleyen owner/consultation/routing/local-capability kararı aktif sonsuz yürütme
değildir. Tek talep ve yetkili checkpoint'i koruyup yürütmeyi sona erdir;
varsayılan polling, tekrar model çağrısı veya başka production iş yoktur. `PAUSED`
nedenini, System Manager'ı ve görev/revision'ı koru; timeout/restart onay değildir.
Geçerli yetkili yanıtla aynı işe dön. Yanıt yalnız görünürlük eksikliğini
açıklıyorsa kayıtlı manager/routing'i değiştirme; mevcut kanıt ve tamamlanan
kontrolleri gereksiz yere yeniden üretme.

Kısa çıktı: aktif iş, geçerli revision, System Manager/provider, topology/lane ve
routing lock revision, tamamlanan davranış, doğrulama sınıfı, eksik kapı ve
sıradaki tek yetkili işlem. Değişmeyen uzun rehberi tekrar yükleme.
Güvenli iş yoksa yeni iş üretme. Başka projede değişiklik yapma.
