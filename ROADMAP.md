# CSE V2 — Kanonik Ürün Yol Haritası

**Durum:** Güncel yürütme sırası ve ilk genel yayın öncesi tek kanonik kuyruk  
**Güncelleme:** 6 Eylül 2026  
**V2 kapsam kaynağı:** `docs/v2/CSE_V2_SCOPE.md`  
**Değişken repository gerçeği:** Güncel SHA, açık Issue/PR, merge ve gate durumu her görevde GitHub `master` üzerinden doğrulanır.

## 1. Bu dosyanın görevi

Bu `ROADMAP.md`, CSE için **güncel yürütme sırasının tek kanonik dosyasıdır**.

- Ürün kapsamının ayrıntısı `docs/v2/CSE_V2_SCOPE.md` içindedir.
- Kalıcı ürün/veri ilkeleri `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` içindedir.
- Çalışma, test, güvenlik ve publication kuralları `AGENTS.md` ve `docs/protocols/` altındaki bağlayıcı protokollerdedir.
- **Sıradaki ürün/release işi bu dosyadaki `İlk genel yayın öncesi tek kanonik yürütme kuyruğu`ndan seçilir.**
- Aynı anda açık bir production Issue/PR varsa önce onun required gate'leri tamamlanır; sonraki queue maddesine geçilmez.
- Queue sırası ancak Fatih'in yeni owner kararıyla değişir. Sıra değişikliği production işe başlamadan önce GitHub'da bu dosyaya yansıtılır.
- Queue üzerindeki durum notları yön gösterir; gerçek `OPEN/CLOSED`, PR head, test ve Acceptance durumu her zaman current GitHub gerçeğinden okunur.
- Eski Issue/PR, sohbet özeti, handoff, ZIP veya tarihsel roadmap metni bu sırayı override edemez.

## 2. Güncel ürün durumu — kısa özet

CSE owner-only, local-first ve mobile-first kişisel saha asistanıdır. V1 sahada kullanılmış; V2'nin kimlik, attachment, Ajanda, schedule/Living Plan, Günlük Log, İş Zinciri, Malzemeler, telefon görüşmesi sonucu, Proje Albümü, recovery ve Inventory omurgaları merged temeldir.

Frictionless Release Readiness programı Issue #617 ile yürür. UI/UX sözleşmesi, adaptive shell, ortak aktif proje, 48×48 erişilebilirlik tabanı, form/primary-action standardı, temel search/filter/error state altyapısı ve visual-first dönüşümün ana dilimleri merged durumdadır.

Son Inventory refinement zinciri #709/#710 → #711/#712 → #713/#714 ile tamamlanmış ve owner manuel kabulünden geçmiştir. DWG Viewer / Issue #523 ilk genel yayın için blocker değildir ve `POST-RELEASE / DEFERRED` kalır.

Değişmeyen teknik baseline değerleri ilgili source/protokol ve current master'dan okunur; bu dosya sabit master SHA tutmaz.

## 3. Tamamlanmış yayın-hazırlık temeli

Aşağıdaki alanlar yeni queue maddesi olarak tekrar açılmaz; yalnız release QA sırasında regresyon bulunursa dar bug Issue'su açılır:

- #616 sanitize full-product evidence baseline.
- #618 kanonik frictionless UI/UX sözleşmesi + V2/roadmap truth-sync.
- #617 Phase 1 adaptive/accessibility foundation.
- #617 Phase 2 ortak form/action, search/filter, loading/error/retry ve insan-okunur event dili temel işleri.
- Reminder/Unutma, Ajanda ve Living Plan günlük akış sadeleştirmelerinin mevcut merged dalgaları.
- Daily Log + Work Chain targeted Acceptance evidence closure (#698).
- Saha Rehberi/Sicil temel bilgi mimarisi ve Puantaj prerequisite/quick-result sadeleştirmeleri.
- İSG model audit + 20A aktif checklist/tracking temeli.
- Inventory compact top tools + D-pad + iki sıralı sketch-editor toolbar (#709–#714).

Bu tamamlanmış temel, ilerideki queue maddelerinde sessizce geri alınmaz.

## 4. İlk genel yayın öncesi tek kanonik yürütme kuyruğu

### Durum etiketleri

- `ACTIVE` — current production child; önce bunun gate'leri kapanır.
- `NEXT` — active child tamamlanınca başlanacak ilk iş.
- `QUEUED` — sırayla bekleyen pre-release işi.
- `DECISION GATE` — uygulama öncesi owner V1/post-release kararı gerekir.
- `RELEASE GATE` — yeni ürün özelliği değil, yayın yeterliliği kapısıdır.
- `DONE / RELEASE QA ONLY` — production refinement tamamlandı; yalnız entegre regresyon/Acceptance kontrolü kalır.

### Q01 — İSG Geçmiş / Arşiv ve lifecycle event görünürlüğü

**Kaynak:** #617 Phase 4 / item 20B, Issue #708, current PR #715  
**Durum:** `ACTIVE` — source/test/independent review PASS; exact Acceptance manual gate tamamlanmadan Ready/merge yok.

Bitiş tanımı:

- arşiv kayıtları aktif İSG özeti/checklist'inden ayrı;
- existing event sequence insan-okunur Türkçe görünür;
- edit/restore/backfill yok;
- exact kişi/proje isolation ve zero-mutation read davranışı korunur;
- Fatih exact Acceptance build'de PASS verir ve PR merge edilir.

### Q02 — KKD hızlı seçim

**Kaynak:** #617 Phase 4 / item 21  
**Durum:** `NEXT`

Amaç: günlük saha kullanımında mevcut canonical KKD semantiğini değiştirmeden hızlı, erişilebilir ve minimum dokunuşlu seçim/atama akışı.

### Q03 — Otomatik personel kodu release kararı

**Kaynak:** #617 Phase 4 / item 22  
**Durum:** `DECISION GATE`

- Fatih V1 için tutarsa ayrı CRITICAL child açılır; identity/revision/compatibility sınırları açıkça test edilir.
- Fatih ilk genel yayın için gerekli görmezse açıkça `POST-RELEASE / DEFERRED` olarak işaretlenir.
- Karar verilmeden sessiz implementation yapılmaz.

### Q04 — Beton tamamlanma / sonuç / detay / düzenleme akışı

**Kaynak:** #617 Phase 5 / item 23  
**Durum:** `QUEUED`

Amaç: Beton Paketi'nin gerçek saha kullanımında create → sonuç → detail → edit/completion zincirini tamamlamak ve mevcut identity/attachment davranışını korumak.

### Q05 — Malzemeler ortak UI/UX sistem uyumu

**Kaynak:** #617 Phase 5 / item 24  
**Durum:** `QUEUED`

Amaç: İstenecek Malzemeler ekranını shared project context, action, state, accessibility ve compact/adaptive görsel dile oturtmak; lifecycle source-of-truth'u değiştirmemek.

### Q06 — Albüm + Dosyalar + Yedekleme + Ayarlar yerleşimi

**Kaynak:** #617 Phase 5 / item 25  
**Durum:** `QUEUED`

Amaç: supporting tools'ın final first-release information architecture ve erişim yerini netleştirmek; attachment/recovery güvenlik sınırlarını korumak.

### Q07 — Inventory release-level entegre doğrulama

**Kaynak:** #617 Phase 5 / item 26; #709–#714  
**Durum:** `DONE / RELEASE QA ONLY`

- yeni Inventory redesign açılmaz;
- Kroki/Katlar/Liste, compact top tools, D-pad ve 7+7 iki sıralı toolbar release QA'da korunur;
- yalnız entegre test/device turunda gerçek regresyon çıkarsa dar bug child açılır.

### Q08 — Bildirim panelinde `Ertele` aksiyonu

**Kaynak:** #617 owner decision `Notification panel snooze action`  
**Durum:** `QUEUED`

- collapsed notification sade;
- expanded notification'da görünür `Ertele` action'ı;
- süre seçenekleri ayrı child'ta netleşir;
- background scheduling/exact-alarm/persistence semantics sessizce değiştirilmez.

### Q09 — Puantaj tamamlanınca Ajanda'ya otomatik kayıt

**Kaynak:** #617 owner decision `Puantaj → Ajanda automatic completion record`  
**Durum:** `QUEUED — CRITICAL`

- yalnız kullanıcı Puantaj gününü açıkça tamamladığında;
- generated Ajanda kaydı exact proje/gün/Puantaj source'una traceable;
- retry/reopen duplicate üretmez;
- identity, transaction, failure, event/history ve rollback sözleşmeleri ayrı CRITICAL Issue'da kilitlenir.

### Q10 — Şefim otomatik yedek klasörü

**Kaynak:** #617 owner decision `Backup destination folder`  
**Durum:** `QUEUED — CRITICAL`

- uygulama gerektiğinde dedicated local Şefim backup folder oluşturur ve default backup destination/source olarak kullanır;
- silent backup generation, overwrite, rotation/delete veya `.csebackup` format değişikliği bu kapsamın parçası değildir;
- exact path/data-root, compatibility ve restore validation zorunludur.

### Q11 — Global hızlı cetvel

**Kaynak:** #617 owner decision `Quick Ruler global tool`  
**Durum:** `QUEUED`

- ekranın sol-alt köşesinden tek dokunuşla geçici tam ekran cetvel;
- tekrar dokunuşla exact önceki ekran/context geri gelir;
- source/form/session mutation yok;
- gerçek ölçü iddiasından önce device-aware physical calibration veya açık calibration fallback zorunludur.

### Q12 — Metraj V1 release kapsam kararı

**Kaynak:** #617 owner decision `Metraj scope expansion`  
**Durum:** `DECISION GATE`

Nihai ürün yönü: Metraj birkaç örnek kalemle sınırlı olmayacak; ana metraj kalemlerini kategori/iş grubu + arama/filtre ile kapsayacak.

Yayın öncesi yapılacak karar:

- **A — V1 blocker:** exact kalem kataloğu çıkarılır, persistence/schema etkisi incelenir ve ayrı implementation zinciri bu noktada tamamlanır.
- **B — Post-release expansion:** mevcut V1 metraj güvenli/işlevsel bırakılır; kapsamlı katalog açıkça post-release backlog'a alınır ve ilk genel yayını bloke etmez.

Fatih karar vermeden ChatGPT bu maddeyi sessizce atlamaz veya kapsamlı Metraj geliştirmesini başlatmaz.

### Q13 — Minimum proje-geneli ortak arama

**Kaynak:** #617 Phase 6 / item 27  
**Durum:** `QUEUED`

İlk release için supported existing record families üzerinde basit, hızlı, project-safe ortak arama; enterprise/global index motoru değil.

### Q14 — Kısa guided onboarding

**Kaynak:** #617 Phase 6 / item 28  
**Durum:** `QUEUED`

Kısa, skip edilebilir ve değer odaklı: CSE nedir → ilk proje → ana günlük akış. Uzun tutorial yok.

### Q15 — Minimum crash / ANR / fatal telemetry

**Kaynak:** #617 Phase 6 / item 29  
**Durum:** `QUEUED`

Release kalitesinde crash/ANR/fatal görünürlüğü; privacy/local-first ve store beyanlarıyla uyumlu minimum kapsam.

### Q16 — Privacy / KVKK / store declarations

**Kaynak:** #617 Phase 6 / item 30  
**Durum:** `QUEUED`

Gerçek uygulama davranışı, izinler, local data, backup, medya ve telemetry ile birebir uyumlu privacy/KVKK/store açıklamaları. Uygulamada olmayan claim yok.

### Q17 — Recovery / backup owner acceptance

**Kaynak:** #617 Phase 6 / item 31  
**Durum:** `RELEASE GATE`

- locked Restore Model A doğrulanır: exact backup state full replacement, restore öncesi safety backup, backup verification, etkilenen kayıt açıklaması, restore sonrası geri alma ve safety backup retention;
- backup folder işi Q10 pre-release yapıldıysa bu tur onun gerçek cihaz davranışını da kapsar;
- gerçek kritik data/destructive operasyon yalnız açık owner authority ile yürür.

### Q18 — Compact / medium / expanded window matrisi

**Kaynak:** #617 Phase 7 / item 32  
**Durum:** `RELEASE GATE`

Breakpoint ve adaptive shell/content davranışının sistematik regresyon matrisi.

### Q19 — Telefon / tablet / portrait / landscape / split-screen

**Kaynak:** #617 Phase 7 / item 33  
**Durum:** `RELEASE GATE`

Gerçek hedef cihaz sınıfları ve kullanılabilir pencere boyutlarında kritik akışların kontrolü.

### Q20 — TalkBack / yüksek yazı / focus / grayscale

**Kaynak:** #617 Phase 7 / item 34  
**Durum:** `RELEASE GATE`

Primary navigation ve kritik create/edit/confirm akışlarında erişilebilirlik kapanışı.

### Q21 — Eksik #616 evidence kapanışı

**Kaynak:** #617 Phase 7 / item 35  
**Durum:** `RELEASE GATE`

Baseline'da eksik kalan populated Puantaj, Beton result/detail/edit, attachment viewer, kayıtlı İSG/KKD ve gerekli motion/Back kanıtları current release candidate davranışıyla tamamlanır. Daily Log + Work Chain targeted evidence #698 ile kapanmıştır ve yeniden yapılmaz.

### Q22 — Manuel kabul borçlarının kapanışı

**Kaynak:** #617 Phase 7 / item 36 + Issue #479  
**Durum:** `RELEASE GATE`

Release'e gerçekten dahil olan user-visible özelliklerde gerekli `PENDING/DEFERRED` manual test borcu çözülür. Tarihsel gereksiz testler sırf sayı kapatmak için çalıştırılmaz; current release behavior'a göre PASS / N/A / superseded disposition verilir.

### Q23 — Entegre “bir şantiye şefi günü” senaryosu

**Kaynak:** #617 Phase 7 / item 37  
**Durum:** `RELEASE GATE`

Tek projede gerçek günlük akışı temsil eden bütünleşik senaryo: proje bağlamı → hatırlatma/ajanda → plan → puantaj → saha rehberi/İSG/KKD → beton/malzeme → envanter/medya → backup/recovery; tekrar veri girişi, context drift, dead end ve mutation sürprizi olmamalı.

### Q24 — Otomatik milestone gate + analyze/build + artifact provenance

**Kaynak:** #617 Phase 8 / item 38  
**Durum:** `RELEASE GATE`

Release candidate exact revision için gerekli birleşik test/analyze/build, package/signing/entrypoint ve artifact SHA/provenance kanıtı.

### Q25 — Owner telefon + tablet Release Candidate kabulü

**Kaynak:** #617 Phase 8 / item 39  
**Durum:** `RELEASE GATE`

Fatih exact RC artifact'ını en az telefon + tablet sınıfında kritik günlük akış ve görsel/ergonomi açısından kabul eder.

### Q26 — Açık genel yayın kararı

**Kaynak:** #617 Phase 8 / item 40  
**Durum:** `FINAL OWNER GATE`

Tüm zorunlu gate'ler geçtikten sonra public/store release ancak Fatih'in ayrı ve açık genel yayın kararıyla başlar. Release/store standing auto-merge yetkisinin dışındadır.

## 5. Queue çalışma kuralı

ChatGPT her yeni görevde veya `devam` talebinde:

1. current GitHub `master`, `AGENTS.md`, açık production Issue/PR ve bu queue'yu okur;
2. açık production Issue/PR varsa önce onu required gate'lerine kadar tamamlar;
3. aksi halde Q01→Q26 içinde current GitHub'a göre tamamlanmamış ilk uygulanabilir maddeyi seçer;
4. `DECISION GATE` maddesinde Fatih kararı yoksa implementation başlatmaz;
5. CRITICAL etiketi taşıyan maddede exact Issue/allowlist/compatibility/manual gate olmadan değişiklik yaptırmaz;
6. Fatih yeni sıra kararı verirse önce ROADMAP truth-sync yapılır, sonra production iş başlar;
7. aynı anda ikinci production implementation child açmaz;
8. tamamlanmış bir queue maddesini tekrar geliştirme işi gibi açmaz; yalnız kanıtlanmış regresyonda dar bug Issue açar.

Bu kural, ChatGPT'nin sohbet hafızasından veya eski SHA'lardan “sıradaki işi” tahmin etmesini engeller.

## 6. İlk genel yayın sonrası / deferred backlog

Aşağıdakiler Q01–Q26 release kuyruğunu bloke etmez, ancak owner kararıyla daha sonra aktive edilebilir:

- **DWG Viewer v1 / Issue #523:** `POST-RELEASE / DEFERRED`. DWG ve doküman viewer uzun vadeli ana ürün hedefidir; ilk genel yayın bağımlılığı değildir.
- Q03'te V1 dışına alınırsa otomatik personel kodu.
- Q12'de B seçilirse kapsamlı Metraj katalog/çalışma merkezi.
- V2.12 Günlük Log v2 ve V2.13 Mini Hesap Makinesi: mevcut owner pause kararı sürer.
- Ayrı ürün toplantısı/brainstorm kayıtları, owner tarafından pre-release queue'ya taşınmadıkça yayın blocker'ı değildir.
- Büyük AI/semantic search, SaaS/multi-user, Primavera replacement ve geniş CAD/GIS hedefleri ilk genel yayın dışında kalır.

## 7. Korunan ürün ve güvenlik ilkeleri

- CSE modül koleksiyonu değil, local-first/mobile-first kişisel saha asistanıdır.
- Aynı bilgi ikinci kez girdirilmez; project context mümkün olduğunca korunur.
- Sürtünme azaltılırken stable identity, optimistic revision, append-only event/history, attachment ve backup bütünlüğü zayıflatılmaz.
- UI kendiliğinden hukuki uygunluk, resmî kabul/ret veya `blocked` kararı üretmez.
- Gerçek kullanıcı data root'u ve destructive restore/release işlemleri ayrı owner authority ister.
- Force-push, destructive reset/clean/stash ve beklenmeyen kullanıcı değişikliğini silme yoktur.
- Public/store release Q26'dan önce yapılmaz.

## 8. Tarihsel kaynaklar

Daha ayrıntılı V2 tarihçesi Git geçmişinde, `docs/v2/CSE_V2_SCOPE.md`, Issue #617 yorumları ve ilgili child Issue/PR'larda korunur. Eski roadmap fazları, Epic #97/#105/#127–#140, Orchestrator O0–O10, Bridge/Work Mode ve superseded UI programları current queue değildir.

Tarihsel kayıtlar silinmiş sayılmaz; yalnız yürütme otoritesi bu dosyadaki Q01–Q26 kuyruğuna merkezileştirilmiştir.
