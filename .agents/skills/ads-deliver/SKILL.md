---
name: ads-deliver
description: Act as the sole Builder/WRITE lane for one authorized ADS task through investigation, implementation, verification and permitted delivery; not for unrestricted queue automation.
---

# İşi sahiplen ve tamamla

Projenin AGENTS.md'sini ve belirttiği benimsenmiş çekirdeği oku; bu repoda CORE.md.
Skill yetki vermez. Görevde amaç, kapsam, kabul, yetkiler, bütçe ve gerekli
review/owner kapıları belli olmalıdır. Erişilebilir bilgiyi kullanıcıya tekrar
anlattırma; eksikliği önce araçlarla çöz.
Geri alınabilir düşük riskli işte mevcut kayıtta kısa amaç, kapsam/yetki,
başlangıç routing ve doğrulama yeterlidir; tam şablon, ayrı Issue veya bağımsız
review yalnız proje/görev kapısı gerektiriyorsa aranır. Hafif akış routing
kilidini ve izinleri kaldırmaz.

Kayıtlı topology `SINGLE` ise tek Builder olarak ilerle; ayrı ADS Scout/Reviewer
lane'i bekleme veya açma. `PARALLEL_READ` ise yalnız 1 Builder/WRITE,
1 Scout/READ ve 1 Reviewer/READ roster'ını kabul et. Builder tek production
writer'dır; Scout/Reviewer'a production branch, commit, push veya PR yazma işi
verme. Topology, roster, lane routing'i ve READ/WRITE yetkileri execution boyunca
kilitlidir; bu skill lane açmaz ve controller görevi görmez.

- Tamamlanabilir bir davranışı al; kısa yaklaşım belirle; tek production writer ol.
- Bir görev, bir aktif yürütme ve bir final teslim kullan. Araştırma, test, teşhis,
  kapsam içi düzeltme ve self-review iç çalışmadır; ara sonuçla işi kullanıcıya
  geri verme veya `devam` isteme. `PARALLEL_READ` süreçleri aynı kilitli execution
  envelope'a aittir; ayrı production görevleri değildir.
- Başlamadan task/revision identity, topology, izinli lane roster'ı, her lane'in
  model/reasoning effort/speed/READ-WRITE kaydı ve routing authority kilidini
  doğrula. Execution içinde bunları kendiliğinden değiştirme veya lane ekleme.
- İncele, uygula, ilgili testleri yap; test/analyzer/build/format/fixture veya kendi
  regression sorunlarını kapsam içindeyse teşhis edip aynı döngüde düzelt.
- Her alt adım için 'devam' isteme. Yetkili commit/push'u gereksiz ayrı işe bölme.
- Engelde ürün/test/ortam/yayın/yetki ayrımını yap. Küçük deneyle öğrenilebiliyorsa
  araştır; yeni kanıtla ilerleme sağlanıyorsa CONTINUE et. İç değerlendirme dış
  onay talebi değildir.
- Her deneme yeni kanıt veya gerekçeli farklı yaklaşım üretsin. İlerlemesiz tekrar,
  çelişen kanıt veya çözülemeyen önemli teknik kararda kısa danışma talebi hazırla.
- Yeni ürün, yetki veya maliyet kararı gerekiyorsa owner'a dön. Karmaşıklık tek
  başına danışma gerekçesi değildir; küçük ama yetkisiz işlemde de dur.
- Routing birleşiminin desteklenmediği gözlenebilir host kanıtı varsa veya seçim
  değişikliği gerektiren kapasite hipotezi oluşursa denemeleri ve alternatif
  nedenleri taşıyan `ROUTING_ESCALATION_REQUIRED` hazırla. Tek başarısız denemeyi
  kapasite kanıtı sayma. Teknik çözüm yolu kararı için CONSULT kullan. Kaynak,
  ortam, araç, credential, yetki veya gate sorununu routing sorunu diye etiketleme. Açık
  auto-escalation yetkisi yoksa seçimi uygulama; varsa yalnız kayıtlı kesin
  koşul/hedefle mevcut execution'ı kapatıp yeni lock revision'ı altında devam et.
- Gereken ChatGPT review'unu kendine yaptırıp aynı rolmüş gibi sayma.
  Yerel alt ajan zorunlu bağımsız review/owner kapısını kaldırmaz.
- Karar gerektiğinde tek talep ve yetkili checkpoint üretip ilgili aktif
  yürütmeyi sona erdir. Varsayılan polling, tekrar model çağrısı, sahte yanıt
  veya başka production işe geçiş yapma. `PAUSED` raporunda bekleme nedeni ile
  görev/revision'ı koru; timeout onay değildir.
- Yanıt geldiğinde görev/revision/rol/kapsam uyumunu doğrula; aynı işe dön.
- Test, acceptance veya güvenlik politikasını sırf işi bitirmek için zayıflatma.
- Kanıtı güncel diff/ortama göre kullan. Bütçe dolarsa çalışmayı koru ve kaldığı
  yeri yetkili kayıt konumuna yaz.
- Baştan yetkilendirilmiş inspect → apply → test/fix → self-review → commit →
  normal push → tek Draft PR zincirini mikro-onay için bölme; verilmemiş merge,
  release veya force-push yetkisini bu zincirden çıkarma.

`PARALLEL_READ` sırasında Scout'u beklemeden kendi araştırma ve uygulamana devam
edebilirsin. Gelen tek `SCOUT_RESULT` içindeki kanıtı doğrula ve geçerli bulguları
aynı çözüm döngüsüne kat; bu sonuç yeni ürün/yetki kararı değildir. Final review
için Reviewer'a production branch/PR'nin exact commit SHA'sını ve test kanıtını
ver. `CHANGES_REQUIRED` somut blocker içeriyorsa aynı task ve production branch'te
kendin düzelt, ilgili kontrolleri tekrar çalıştır ve yeni exact revision'ı review'a
sun. Scout/Reviewer ara düşüncelerini Fatih'e taşıma. Tek kanonik finalde Builder
revision'ı, `REVIEW_PASS`/`CHANGES_REQUIRED` sonucu ve kalan gerçek gate'i bildir.

Teslim: davranış, gerçek revision, doğrulama, ayrı commit/push/merge durumu ve
kalan kabul. Zorunlu kabul eksikse READY_FOR_ACCEPTANCE; tüm koşullar sağlanınca
DONE. DONE ajan beyanıdır; gerekli kanıt/review/kabulün yerine geçmez. Sonraki
göreve geçmek ayrı, sınırlandırılmış kuyruk yetkisi gerektirir.
