---
name: ads-resume
description: Resume an authorized ADS task from current repository evidence. Use for continue, handover or interrupted work; not for inventing tasks or clearing approval gates.
---

# Kaldığın doğru işi bul

Projenin AGENTS.md'sini ve orada belirtilen benimsenmiş ADS çekirdeğini oku.
Bu repoda çekirdek CORE.md'dir. Başka repoda benimseme yoksa salt okunur
durum raporundan öte ADS yetkisi varsayma.

1. Repo/root, branch, head, staged/unstaged diff ve görev kimliğini doğrula.
2. Aktif Issue/PR ve son yetkili kararı bul; eski özetle production işi seçme.
3. Kayıtlı task/revision identity, `SINGLE`/`PARALLEL_READ` topology, lane roster,
   her lane'in model/effort/speed/READ-WRITE kilidini, lock revision'ını ve routing
   authority'yi bul; bekleyen `ROUTING_ESCALATION_REQUIRED` kararını koru.
4. Bekleyen danışma, owner kabulü veya STOP olup olmadığını belirle.
5. Kayıp/çelişkili kapıyı açık sayma. Genel 'devam' veya restart onay değildir;
   routing kaydı kayıpsa yeni seçim uydurma.
6. Mevcut kanıtın güncel diff ve ortam için geçerli olup olmadığını belirle.
7. Engeller yoksa kendi kayıtlı lane rolü ve yetkisiyle aynı işe devam et.
   Yalnız Builder ads-deliver ile production yazma ve teslim yapar; Scout tek
   `SCOUT_RESULT`, Reviewer exact revision için `REVIEW_PASS` veya
   `CHANGES_REQUIRED` üretir. Read-only lane'i writer'a çevirme, eksik lane'i
   kendiliğinden açma veya topology/roster değiştirme. Builder olarak devam ediyorsan
   kalan araştırma, uygulama, test/fix, self-review ve baştan yetkili teslimi tek
   yürütmede tamamla; yalnız durum raporu istendiyse uygulama başlatma.

Bekleyen owner/consultation/routing kararı aktif sonsuz yürütme değildir. Tek
talep ve yetkili checkpoint'i koruyup yürütmeyi sona erdir; varsayılan polling,
tekrar model çağrısı veya başka production iş yoktur. `PAUSED` nedenini ve
görev/revision'ı koru; timeout/restart onay değildir. Geçerli yetkili yanıtla
aynı işe dön. Yanıt yalnız görünürlük eksikliğini açıklıyorsa kayıtlı routing'i
değiştirme; mevcut kanıt ve tamamlanan kontrolleri gereksiz yere yeniden üretme.

Kısa çıktı: aktif iş, geçerli revision, topology/lane ve routing lock revision,
tamamlanan davranış, eksik kapı, sıradaki tek yetkili işlem. Değişmeyen uzun
rehberi tekrar yükleme.
Güvenli iş yoksa yeni iş üretme. Başka projede değişiklik yapma.
