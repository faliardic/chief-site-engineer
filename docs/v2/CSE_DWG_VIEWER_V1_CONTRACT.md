# CSE DWG Viewer V1 Sözleşmesi

**Belge türü:** Kanonik ürün ve mimari sözleşmesi
**Kapsam:** DWG-001 / Issue #607
**Durum:** Tasarım sözleşmesi; production implementation veya gerçek DWG doğrulama kanıtı değildir

## 1. Amaç ve otorite

Bu belge, CSE'nin ilk genel yayındaki DWG Viewer sınırını ve sonraki ölçüm
fazının güvenilir kurulabilmesi için korunacak veri ilkelerini kilitler. Daha
eski planlarda güvenilir iki nokta ölçümünün ilk yayın kapısı olduğu yönündeki
ifadeler yerine 30 Ağustos 2026 tarihli kilitli ürün kararı uygulanır:

- ilk genel yayın kapısı **Minimal Güvenilir Viewer + ölçüme hazır mimari**dir;
- gerçek iki nokta ölçümü ikinci fazdır ve ilk genel yayını bloklamaz.

Bu sözleşme bir converter, vendor, çalışma ortamı, depolama yolu, schema veya PDF
renderer seçmez. Buradaki kuralların yazılmış olması bunların uygulandığı ya da
gerçek dosyalarla doğrulandığı anlamına gelmez.

## 2. Değişmez source-of-truth sınırı

### 2.1 Original DWG

Original DWG, dayanıklı ve immutable source-of-truth'tur.

- Conversion, görüntüleme, cache açma, cache yenileme veya hata kurtarma source
  byte'larının üzerine yazamaz ve onları dönüştürülmüş çıktı ile değiştiremez.
- Yeni bir DWG revizyonu, önceki source'u sessizce değiştirmek yerine kendi
  source/revision kimliğiyle temsil edilir.
- Source identity kavramsal olarak en az DWG byte'larının `SHA-256` değeri ile
  stable proje, doküman ve revizyon bağlamını birlikte taşır. Exact alanlar ve
  persistence modeli bu dilimde seçilmez.
- Original DWG binary'si SQLite BLOB olarak saklanmaz.
- Conversion veya viewer hatası original DWG'yi silemez, değiştiremez ya da
  bağlantısını koparamaz.

### 2.2 Derived viewer artefact

Normal başarılı viewer artefact'ı gerçek bir **vector PDF**'dir. Bu PDF:

- source-of-truth değil, original DWG'den yeniden üretilebilir ve gerektiğinde
  atılabilir bir cache'tir;
- original DWG'nin yerine durable source olarak kullanılamaz;
- silinmiş, bozulmuş veya geçersiz olduğunda geçerli original source'tan yeniden
  üretilebilir;
- raster screenshot'ın PDF içine konmasıyla elde edilen bir çıktıyı sessizce
  normal vector başarı gibi gösteremez.

Cache geçerliliği kavramsal olarak source identity, converter identity/version
ve conversion-format version birlikteliğine bağlıdır. İlgili identity/version
uyuşmazlığı cache'i geçersiz kılar; eski çıktı yeni source revizyonuna aitmiş
gibi açılamaz. Exact key, metadata alanları ve storage uygulaması sonraki
dilimlere aittir.

## 3. Conversion metadata ve güven sınırı

Her conversion sonucu, implementasyon biçiminden bağımsız olarak şu bilgilerin
izlenebilir kalmasına izin vermelidir:

- converter identity ve version;
- conversion-format version;
- source ve source revision bağı;
- üretilen artefact'ın ilgili source'a ait olduğunu doğrulayacak identity bağı;
- warning ve error sonuçları;
- mevcutsa sayfa/layout, coordinate, unit, scale ve transform metadata'sı ile
  bunların güven durumu.

Eksik font, eksik XREF, unsupported object, çözümlenemeyen layout veya belirsiz
scale/unit koşulları sessizce gizlenemez. Çizimin eksik ya da güvenilmez olma
riski görünür warning üretir veya güvenli biçimde başarısız olur; kısmi sonuç
tam ve güvenilir başarı gibi sunulamaz. Hiçbir başarısızlık original DWG'yi
mutate edemez veya silemez.

## 4. İlk genel yayın viewer kapsamı

Geçerli erişim hakkı ve güvenli bir source bulunduğunda ilk genel yayın viewer'ı
yalnız şu zorunlu kabiliyetleri hedefler:

1. DWG'yi açma;
2. pan;
3. pinch zoom;
4. fit-to-screen;
5. geçerli cache'i güvenli yeniden açma;
6. original source filename ve revision bilgisini görünür tutma;
7. eksik font ve XREF warning'lerini görünür sunma;
8. bozuk veya unsupported source/artefact için güvenli hata verme.

Güvenli cache reopen, yalnız cache'in beklenen source/conversion identity'siyle
uyumlu olduğu durumda cache'i kullanır. Cache yoksa, bozuksa veya geçersizse
original source korunur; sistem doğrulanmamış cache'i açmak yerine güvenli
biçimde yeniden üretim yoluna gider ya da başarısız olur. Yeniden üretimin exact
mekanizması bu sözleşmenin dışındadır.

## 5. Ölçüme hazır mimari ve ikinci faz

İlk release gerçek mesafe ölçmez; ancak sonraki güvenilir ölçümü engelleyecek
bir viewer veya conversion sınırı da kuramaz. Mimari aşağıdaki dönüşüm zincirini
kurmaya yetecek metadata'yı koruyabilmelidir:

```text
screen point
→ PDF page coordinate
→ source drawing/model coordinate
→ doğrulanmış gerçek birim ve mesafe
```

Bu nedenle page/layout identity, PDF page geometry, source coordinate ilişkisi,
unit, model-to-paper/viewport/plot-scale ilişkisi ve gerekli transform bilgileri
mevcut ve güvenilir oldukları ölçüde kaybolmadan taşınabilmelidir.

Değişmez ölçüm güvenliği kuralları:

- Gerçek mesafe screen pixel uzaklığından hesaplanmaz.
- Doğrulanmamış scale veya unit'ten metre ya da başka bir gerçek dünya birimi
  uydurulmaz.
- Ölçüm kabiliyeti kavramsal olarak `TRUSTED`, `CALIBRATION_REQUIRED` veya
  `UNAVAILABLE` durumlarından biriyle temsil edilebilir.
- `TRUSTED`, PDF ile source/model coordinate ilişkisinin doğrulandığını;
  `CALIBRATION_REQUIRED`, güvenilir sonuçtan önce kullanıcı referansıyla
  kalibrasyon gerektiğini; `UNAVAILABLE`, güvenilir ölçüm üretilemeyeceğini
  ifade eder.
- Trust state doğrulanamıyorsa ölçüm fail-closed kalır.

Gerçek two-point measurement, calibration UI, unit formatting ve measurement
overlay davranışı **phase 2** işidir. Bunlar bu dilimde uygulanmaz, doğrulanmaz ve
ilk genel yayın için release blocker değildir.

## 6. Entitlement ve veri güvenliği

Trial veya aboneliğin başlamaması, bitmesi ya da viewer erişiminin kilitlenmesi
kullanıcının durable verisinin yaşam döngüsü değildir. Entitlement değişikliği:

- original DWG byte'larını;
- proje, doküman veya revision metadata'sını;
- original dosyaya ait file link/reference'ları

silemez, mutate edemez veya geçersizleştiremez. Viewer erişimi ürün kararına
göre kilitlenebilir; veri sahipliği ve source bütünlüğü korunur. Derived cache
ise source-data loss oluşturmadan kaldırılabilir ve erişim/üretim koşulları
yeniden sağlandığında geçerli original source'tan yeniden üretilebilir.

## 7. Açıkça kapsam dışı

İlk genel yayın Viewer kapsamına şunlar dahil değildir:

- CAD editing veya DWG write-back;
- drawing ya da markup;
- layer management;
- area measurement veya quantity takeoff;
- revision compare;
- AI;
- field/photo links;
- persistent measurement annotations;
- custom full DWG renderer;
- gerçek two-point measurement ve calibration UI.

Bu başlıklar viewer sözleşmesine sessizce eklenemez.

## 8. DWG-002/003/004'e ertelenen kararlar

Aşağıdaki konularda bu belge tercih veya mevcut uygulama iddiası oluşturmaz;
kararlar ilgili sonraki kontrollü DWG dilimlerine aittir:

- mevcut CSE file/attachment storage ve schema yapısının exact adoption biçimi;
- original ve cache için exact filesystem/storage root'ları;
- schema veya migration gerekip gerekmediği;
- converter/provider/vendor seçimi;
- conversion'ın cloud ya da local çalışması;
- PDF renderer seçimi;
- gerçek DWG corpus'unda conversion fidelity ve performance yeterliliği.

Bu kararlar verilmeden production dependency, schema, platform veya dosya
yerleşimi bu sözleşmeden türetilmiş kabul edilemez.

## 9. DWG-001 kabul sınırı

Bu dilimin tamamlanması yalnız kanonik sözleşmenin oluşturulduğunu gösterir.
Production kodu, converter, dependency, schema/migration, storage root, build,
APK, device davranışı veya gerçek DWG conversion/viewer sonucu uygulanmış ya da
doğrulanmış sayılmaz. Sonraki çalışma, ayrı Issue ve exact owner authority ile
yürütülür.
