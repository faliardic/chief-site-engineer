# ADR-0001: Tek Hafıza ve Kayıt Kapsamı

- Durum: Kabul edildi
- Tarih: 2026-07-17
- İlgili iş: GitHub Issue #145
- Üst program: Issue #127
- Faz: Issue #128 — Faz 0

## 1. Bağlam ve çözülen ürün çelişkisi

CSE'nin tek gerçek kullanıcısı şantiye şefidir. Kullanıcı sahada notu, takibi,
rutini, gözlemi ve gelecekte eklenecek doküman, plan, iş paketi ve hesabı aynı
günlük çalışma içinde üretir. Bunları ana navigasyonda “kişisel uygulama” ve
“resmî uygulama” olarak iki ayrı dünyaya bölmek, aynı kullanıcının aynı olaya
ait bilgisini iki kez aramasına ve iki kez işlemesine yol açar.

Buna karşılık her kayıt aynı paylaşım anlamını taşımaz. Bir follow-up veya hızlı
hesap yalnız şefin çalışma hafızasında kalabilir; saha gözlemi ya da yayımlanmış
rapor ise proje çıktısına adaydır. Bu fark kullanıcı rolü değildir. Kayıtların
resmî/proje çıktısına girip giremeyeceğini belirleyen paylaşım ve çıktı
sınırıdır.

Mevcut sistemde bu iki konu kısmen farklı işaretlerle temsil edilir:

- `FieldObservationRecord.project_id` zorunludur ve daily export observation
  kayıtlarını okur.
- `FollowUpItem.project_id` ile `RoutineTemplate.project_id` nullable'dır;
  projeye bağlı olsalar bile mevcut daily export'a girmezler.
- `convert_to_observation`, follow-up'ı var olan observation'a bağlayıp kapatır;
  follow-up kaydını daily export girdisine dönüştürmez.
- Backup, SQLite snapshot'ın tamamını taşıdığı için observation, follow-up,
  routine ve event geçmişini birlikte korur.

Bu ADR, tek kullanıcı deneyimi ile güvenli çıktı ayrımını çelişkisiz bir ürün ve
veri sözleşmesine bağlar. Bu karar production kodunda `scope` alanını uygulamaz.

## 2. Karar

### 2.1 Tek Hafıza kullanıcı deneyimi

Kullanıcıya tek ana ürün yüzeyi sunulur: **Hafıza**.

- Observation, follow-up, routine occurrence ve gelecekteki note, document,
  plan, work package ve calculation kayıtları aynı Hafıza arama, filtre ve
  timeline yüzeylerinde bulunabilir.
- Ana navigasyonda ayrı kişisel uygulama, resmî uygulama veya ikinci kullanıcı
  alanı kurulmaz.
- Kaynak domain tabloları, repository'leri ve yaşam döngüleri birleştirilmez.
- Her sonuçta **Kayıt türü** anlaşılır bir badge/etiket olarak gösterilir.
- Kayıt türü, kaydın ne olduğunu; **Kapsam**, kaydın hangi çıktılara aday
  olabileceğini anlatır. Bu iki kavram birbirinin yerine kullanılmaz.
- Ortak Hafıza görünümü gelecekte `MemoryIndex` / `RecordRef` gibi yeniden
  üretilebilir bir read-model kullanabilir; bu ADR o yapının şemasını seçmez.

Tek Hafıza, tek tablo demek değildir:

```text
Observation kaynak tablosu ---------\
Follow-up kaynak tablosu ------------> Hafıza / arama / timeline
Routine occurrence kaynak tablosu ---/
```

### 2.2 Kapsam sözlüğü

Her kapsam taşıyan kaynak kayıt için yalnız iki canonical değer vardır:

```text
private | project
```

- `private`: Şantiye şefinin kişisel çalışma hafızasıdır. Varsayılan olarak
  resmî/proje çıktısına giremez.
- `project`: Belirli bir projeye bağlıdır ve ilgili resmî/proje çıktısına
  seçilebilmek için uygundur.

`project` kapsamı “yayımlandı”, “onaylandı” veya “resmî rapora girdi” demek
değildir. Yalnız çıktı için **uygunluk** verir. Gerçek çıktı üretimi ayrıca proje,
tarih, kayıt durumu ve kullanıcı seçimi gibi kendi sözleşmesini uygular.

Kapsam:

- erişim rolü değildir;
- tenant veya firma ayrımı değildir;
- başka bir kullanıcıya ait alan değildir;
- işletim sistemi, uygulama kilidi veya encryption garantisi değildir;
- record type veya lifecycle status değildir.

## 3. Kapsam alanının semantiği

Kapsam, kaynağın kendisinde veya kaynağa ait bağlayıcı metadata'da kalıcı ve
makinece okunabilir olmalıdır. Kesin şema sahipliği sonraki implementation
Issue'sunda seçilecektir; semantik ise bu ADR ile bağlayıcıdır.

Değişmezler:

1. `private` kayıt project bağlantısı taşımayabilir veya taşıyabilir.
2. `project` kayıt mutlaka tek bir project bağlantısı taşır.
3. Kayıt türü, `project_id`, observation bağlantısı, AI sınıflandırması veya
   çıktı seçimi kapsam yerine geçmez.
4. Attachment ve append-only event için bağımsız bir paylaşım kapsamı
   uydurulmaz; bunlar sahibi olan kaynak kaydın kapsamını izler.
5. Türetilmiş read-model satırı source of truth değildir; kapsamını kaynak
   kayıttan alır ve kaynağı sessizce değiştiremez.

UI, canonical değerleri aşağıdaki gibi sunabilir:

| Canonical değer | Kullanıcı etiketi | Anlam |
| --- | --- | --- |
| `private` | Kişisel | Şefin çalışma hafızası; proje çıktısına doğrudan giremez |
| `project` | Proje | Bağlı proje çıktısına seçilmeye uygun |

## 4. Proje bağlantısı ile kapsam farkı

**Proje bağlantısı**, kaydın hangi şantiye/proje bağlamında aranacağını ve
ilişkilendirileceğini söyler. **Kapsam**, kaydın paylaşılabilir proje çıktısına
aday olup olmadığını söyler.

```text
project_id atandı
-> kayıt projeye göre bulunabilir
-> kapsam değişmez

private -> project açık işlemi
-> project_id zorunlu
-> revision artar
-> append-only kapsam olayı yazılır
-> kayıt proje çıktısına aday olabilir
```

- Projesiz `private` kayıt geçerlidir.
- Projeye bağlı `private` kayıt da geçerlidir.
- `project_id` atamak veya observation link'i kurmak otomatik kapsam dönüşümü
  yapmaz.
- Aynı kullanıcı komutunda project bağlantısı ile kapsam dönüşümü birlikte
  istenebilir; fakat UI iki niyeti açıkça gösterir ve kullanıcıdan kapsam
  dönüşümü için ayrı onay alır.
- `project` kaydın project bağlantısı tek başına temizlenemez. Yalnız izinli bir
  `project -> private` dönüşümüyle aynı atomik işlem içinde kaldırılabilir veya
  değiştirilebilir.

Mevcut `convert_to_observation` davranışı ayrı bir domain dönüşümüdür:

```text
private follow-up
-> var olan observation'a açık kullanıcı işlemiyle bağlanır ve kapanır
-> kaynak follow-up private kalır
-> hedef observation project kapsamındadır
```

Bu nedenle mevcut follow-up metni daily export'a sızmaz ve geriye uyumluluk
korunur.

## 5. Kayıt türleri için başlangıç mapping tablosu

Bu tablo gelecekte kapsam alanı eklendiğinde uygulanacak başlangıç/backfill
anlamını tanımlar; bu Issue migration çalıştırmaz.

| Kayıt türü | Mevcut kayıtların başlangıç kapsamı | Project bağlantısı | Dönüşüm yönü |
| --- | --- | --- | --- |
| `FieldObservationRecord` | `project` | Zorunlu | `project -> private` yasak |
| `FollowUpItem` | `private` | Nullable; dolu olması kapsamı değiştirmez | Açık işlemle `private -> project`; koşullu geri dönüş |
| `RoutineTemplate` | `private` | Nullable; dolu olması kapsamı değiştirmez | Açık işlemle `private -> project`; koşullu geri dönüş |
| `RoutineOccurrence` | `private` | Bugün template üzerinden bağlam alır | Gelecekte üretim anındaki template kapsamını snapshot eder; geçmiş occurrence sonradan değişmez |
| Observation attachment/event | Sahibi observation'dan `project` | Sahibi üzerinden | Bağımsız dönüşüm yok |
| Follow-up/routine event | Sahibi kayıttan `private` veya `project` | Sahibi üzerinden | Bağımsız dönüşüm yok |
| Gelecekteki genel note/calculation | Yeni kayıtta `private` | Nullable | Açık işlemle `private -> project`; koşullu geri dönüş |
| Gelecekteki project document/plan/work package | Domain sözleşmesi gereği `project` | Zorunlu | `project -> private` yasak |
| Yayımlanmış günlük/rapor/Proje Paketi snapshot'ı | `project` | Zorunlu | `project -> private` yasak |

Routine için snapshot kuralı şudur:

- Yeni occurrence, oluşturulduğu anda template'in kapsam ve proje bağlamını
  snapshot olarak alır.
- Template kapsamını değiştirmek mevcut occurrence'ları topluca yeniden yazmaz.
- Eski occurrence'lar ancak kendi kayıtları üzerinde açık, denetlenebilir ve
  izinli bir dönüşümle değişebilir.

Bu kural, mevcut “template değişikliği geçmiş occurrence'ı değiştirmez” domain
sözleşmesiyle uyumludur.

## 6. Kapsam dönüşüm kuralları

### 6.1 `private -> project`

Yalnız açık kullanıcı işlemiyle yapılır.

Zorunlu koşullar:

1. Kullanıcı hedef project bağlantısını görür veya seçer.
2. UI, kaydın bundan sonra proje çıktısına seçilebilir olacağını açıkça söyler.
3. Güncel revision doğrulanır.
4. Kapsam ve gerekirse project bağlantısı tek transaction içinde değişir.
5. Revision tam bir artar.
6. Append-only event en az `from_scope`, `to_scope`, `project_id`, actor ve
   zaman bilgisini taşır.
7. Gerçek no-op yeni revision veya event üretmez; stale revision no-op'tan önce
   reddedilir.

Aşağıdakiler kapsamı değiştiremez:

- AI önerisi veya sınıflandırması;
- project atama;
- observation link'i;
- routine occurrence üretimi dışında template güncellemesi;
- arama indeksleme veya read-model rebuild;
- bir çıktıda kaydı işaretlemeye çalışmak;
- background job veya otomatik migration tahmini.

### 6.2 `project -> private`

Geri dönüş bütün kayıt türleri için serbest değildir.

**Daima yasak:**

- observation ve kanıt niteliğindeki proje kayıtları;
- project document/revision, plan ve work package kayıtları;
- yayımlanmış günlük, rapor ve Proje Paketi snapshot'ları;
- resmî/proje çıktısına daha önce dahil edildiği veya project-scope bağımlı
  kayıtlarca referanslandığı bilinen kayıtlar.

**Koşullu olarak izinli:**

- follow-up, routine template/occurrence, genel note ve calculation gibi
  kullanıcı çalışma kayıtları;
- yalnız kayıt daha önce hiçbir resmî/proje çıktısına dahil edilmediyse;
- project-scope bağımlı child/reference yoksa;
- kullanıcı geçmiş çıktının geri çağrılamayacağını belirten uyarıyı gördükten
  sonra açıkça onay verdiyse;
- revision ve append-only event aynı atomik işlemde yazıldıysa.

Bir implementation, “daha önce çıktıya girdi mi?” ve bağımlı reference
koşullarını güvenilir biçimde kanıtlayamıyorsa fail-closed davranır ve
`project -> private` işlemini reddeder. İlk kapsam implementation'ı bu izleme
omurgası olmadan geri dönüş butonu sunmaz.

## 7. Çıktı varsayımları

### 7.1 Backup

Backup felaket kurtarma içindir.

- `private` ve `project` bütün kayıtları, event geçmişlerini, arşiv durumlarını
  ve yönetilen attachment'ları kapsar.
- Kapsama göre eksik backup üretme seçeneği sunulmaz.
- Backup paylaşılabilir proje çıktısı değildir.
- Mevcut backup format `1`, SQLite snapshot ve restore davranışı bu Issue'da
  değişmez.
- Mevcut backup şifreli değildir; dosyanın güvenli saklanması ayrı güvenlik
  sorumluluğudur.

### 7.2 Hafızayı İndir

Hafızayı İndir, şefin insan ve makine tarafından okunabilir kişisel arşividir.

- Bütün `private` ve `project` kapsamlarını içerir.
- Her kaydın kayıt türünü, kapsamını ve project bağlantısını açıkça beyan eder.
- Arşivli kayıtlar, event geçmişi ve attachment envanteri çıktı sözleşmesinde
  görünür olmalıdır.
- “Paylaşılabilir Proje Paketi” gibi sunulmaz ve restore garantisi vermez.
- Format, manifest ve checksum ayrıntıları ayrı çıktı ADR/Issue'sunda belirlenir.

### 7.3 Proje Paketi, günlük ve rapor

Resmî/proje çıktısı paylaşılabilir bir çıktı sınırıdır.

- Yalnız seçilen project bağlantısına sahip `project` kapsamlı kayıtlar adaydır.
- `private` kayıt, seçim kutusunda işaretlense bile doğrudan çıktıya alınmaz.
- Kullanıcı private kaydı dahil etmek istiyorsa önce ayrı ve açık
  `private -> project` dönüşümünü tamamlar; sonra çıktı seçiminde kaydı seçer.
- Çıktı üretmek source kaydın kapsamını değiştirmez.
- Geçmiş bir snapshot, sonraki kapsam değişikliğiyle sessizce yeniden yazılmaz.

Mevcut daily export yalnız observation/project/attachment/event hattını okumaya
devam eder. Follow-up ve routine verisinin mevcut byte-identical izolasyonu bu
ADR ile değişmez. Gelecekte project kapsamlı yeni kayıt türlerinin günlük veya
Proje Paketi'ne nasıl ekleneceği ayrı executable sözleşme gerektirir.

## 8. UI ve terminoloji sonuçları

Bağlayıcı sözlük:

| Terim | Kesin anlam |
| --- | --- |
| **Hafıza** | Bütün kayıt türlerinin ortak bulunabilirlik, arama ve timeline yüzeyi |
| **Kayıt türü** | Observation, follow-up, routine occurrence, document gibi domain kimliği |
| **Kapsam: `private \| project`** | Çıktı/paylaşım uygunluğu; rol veya tenant değil |
| **Proje bağlantısı** | Kaydın ait olduğu veya bağlam aldığı project referansı |
| **Resmî/proje çıktısı** | Günlük, rapor veya Proje Paketi gibi paylaşılabilir çıktı |
| **Kapsam dönüşümü** | Açık kullanıcı işlemiyle revision ve event üreten kapsam değişikliği |
| **Backup** | Bütün hafızayı taşıyan felaket kurtarma paketi |
| **Hafızayı İndir** | Şefin bütün hafızasının okunabilir kişisel arşivi |
| **Proje Paketi** | Tek projeye ait paylaşılabilir, seçilmiş `project` kapsamlı çıktı |

UI sonuçları:

- Ana navigasyonda tek **Hafıza** girişi bulunur.
- Kart ve arama sonuçları en az kayıt türü badge'i, kapsam etiketi ve varsa
  proje bağlantısını birbirinden ayrı gösterir.
- Filtreler kayıt türü, kapsam ve proje için ayrı çalışır.
- Dönüşüm eylemi “Projeye bağla” değil, “Proje kapsamına geçir” olarak
  adlandırılır.
- Proje Paketi seçiminde private kayıtlar seçilemez; kullanıcı kapsam dönüşümü
  akışına yönlendirilir.

Aşağıdaki eski ifadeler current ürün kavramı değildir:

- “Şefin özel alanı”;
- “ikinci kullanıcı alanı”;
- “rol bazlı özel alan”;
- “yeni şantiye şefine devredilen kullanıcı alanı”.

Tarihsel belgelerde bulunabilirler; yeni UI, ADR, Issue ve kabul kriterlerinde
tek Hafıza ve kapsam sözlüğü kullanılır.

## 9. Migration ve geriye uyumluluk etkileri

Bu Issue schema veya migration uygulamaz. Gelecekteki migration aşağıdaki
backfill'i açık testlerle yapmak zorundadır:

| Mevcut kaynak | Backfill kapsamı | Gerekçe |
| --- | --- | --- |
| Bütün observation kayıtları | `project` | Mevcut project zorunluluğu ve daily export davranışı |
| Bütün follow-up kayıtları | `private` | Mevcut kişisel/export dışı sözleşme; project/link inference yok |
| Bütün routine template kayıtları | `private` | Mevcut kişisel/export dışı sözleşme |
| Bütün routine occurrence kayıtları | `private` | Geçmiş template değişikliklerinden bağımsız snapshot davranışı |

Özellikle observation'a bağlı veya `converted_to_observation` sonucu taşıyan
eski follow-up da `private` backfill edilir. Hedef observation ayrı `project`
kaydıdır.

Gelecekteki implementation:

- mevcut project/observation/follow-up/routine değerlerini değiştiremez;
- `project_id IS NOT NULL` üzerinden otomatik `project` kapsamı üretemez;
- eski daily export ZIP'inin kapsam ve formatını değiştiremez;
- backup format `1` manifest alanlarını bu ADR gerekçesiyle değiştiremez;
- fresh ve upgrade veritabanlarında aynı kapsam sonucunu kanıtlamalıdır.

## 10. Güvenlik ve gizlilik sonuçları

- `private`, mevcut auth/encryption eksikliğini gideren bir güvenlik sınırı
  değildir; yanlış paylaşımı önleyen ürün ve çıktı sınırıdır.
- En büyük gizlilik riski private kaydın paylaşılabilir çıktıya sızmasıdır. Bu
  nedenle private kaydı uyarıyla doğrudan Proje Paketi'ne alma alternatifi
  reddedilmiştir.
- Backup ve Hafızayı İndir bütün kapsamları taşıdığı için private veri içerir;
  UI bunu dosya oluşturulmadan önce açıkça belirtmelidir.
- AI yalnız öneri sunabilir; kapsamı, project bağlantısını veya resmî çıktı
  seçimini kullanıcı onayı olmadan değiştiremez.
- Read-model ve arama indeksi kapsam bilgisini kaynakla tutarlı taşır; eksik
  kapsamı tahmin etmez.
- Scope event geçmişi, kimin ve ne zaman paylaşım sınırını değiştirdiğini
  açıklayabilmelidir.

## 11. Reddedilen alternatifler

### Ayrı kişisel ve resmî uygulama/navigasyon

Reddedildi. Tek kullanıcı aynı olayı iki ürün dünyasında aramak zorunda kalır ve
kayıt tekrarı oluşur.

### Bütün kayıt türlerini tek tabloya taşımak

Reddedildi. Domain yaşam döngülerini zayıflatır ve riskli büyük migration
gerektirir. Tek Hafıza, kaynak tabloları birleştirmeden kurulacaktır.

### `project_id` doluysa kapsamı otomatik `project` yapmak

Reddedildi. Mevcut project bağlantılı follow-up ve routine kayıtlarını resmî
çıktıya sızdırır; Epic #97 sözleşmesini kırar.

### Kayıt türünü kapsam yerine kullanmak

Reddedildi. Follow-up, note veya calculation gelecekte açık kullanıcı işlemiyle
project kapsamına geçebilir; yine aynı kayıt türü olarak kalır.

### Private kaydı yalnız uyarıyla doğrudan Proje Paketi'ne almak

Reddedildi. Uyarı, kalıcı ve denetlenebilir kapsam dönüşümünün yerini tutmaz.

### AI veya link kurma ile sessiz kapsam dönüşümü

Reddedildi. Paylaşım sınırı kullanıcı intent'i, revision ve event gerektirir.

### Kapsamı rol, tenant veya yeni şantiye şefi hesabı olarak modellemek

Reddedildi. CSE tek sahipli üründür; başka kişi ve firmalar kullanıcı hesabı
değil kayıt referansıdır.

### Bütün `project -> private` geri dönüşlerini koşulsuz açmak

Reddedildi. Yayımlanmış kanıtın veya bağımlı proje kaydının görünmez biçimde
daraltılması yanıltıcı olur. Yalnız kanıtlanmış, yayımlanmamış çalışma kayıtları
için fail-closed koşullu geri dönüş kabul edilmiştir.

## 12. Bu ADR'nin uygulamadığı alanlar ve sonraki işler

Bu karar aşağıdakileri uygulamaz:

- domain enum veya `scope` alanı;
- SQLite schema, migration veya backfill;
- repository/application service mutation'ı;
- kapsam event vocabulary'si ve payload sınıfları;
- Hafıza ekranı, filtre, badge, template veya CSS;
- `MemoryIndex` / `RecordRef` şeması ve rebuild algoritması;
- Backup, Hafızayı İndir veya Proje Paketi format değişikliği;
- daily export'a yeni kayıt türü ekleme;
- auth, role, tenant, encryption veya app lock;
- AI mutation'ı;
- gerçek kullanıcı verisi migration'ı.

Sonraki dar işler sırasıyla:

1. `MemoryIndex` / `RecordRef` read-model ADR'si;
2. Backup / Hafızayı İndir / Proje Paketi ayrım ADR'si;
3. kapsam alanı sahipliği, migration ve backfill implementation planı;
4. revision/event kullanan kapsam conversion service'i;
5. Tek Hafıza UI ve kapsam/proje/kayıt türü filtreleri;
6. çıktı ve gizlilik için executable regresyon testleri.

## 13. Executable acceptance karar matrisi

Sonraki testler en az şu kararları çalıştırılabilir hale getirmelidir:

| Senaryo | Beklenen kapsam / sonuç |
| --- | --- |
| Projesiz follow-up oluştur | `private` |
| Follow-up'a project ata | `private`; yalnız proje bağlantısı değişir |
| Private follow-up'ı observation'a link et | Follow-up `private`, observation `project` |
| Follow-up'ı observation'a dönüştür | Kaynak follow-up `private`; hedef observation `project`; mevcut daily export izolasyonu sürer |
| Observation oluştur | `project`; project bağlantısı zorunlu |
| Kullanıcı private çalışma kaydını proje kapsamına geçirir | `project`; revision +1 ve tek append-only event |
| Aynı kapsam dönüşümünü güncel revision ile tekrarla | No-op; revision/event artmaz |
| Stale revision ile aynı dönüşümü tekrarla | Conflict; no-op sayılmaz |
| Project atama veya AI önerisi çalışır | Scope değişmez |
| Private kayıt Proje Paketi için seçilir | Reddedilir; önce açık kapsam dönüşümü gerekir |
| Private kayıt daily/rapor üretimi sırasında bulunur | Çıktı dışında kalır |
| Backup oluştur | `private` + `project`, event ve attachment birlikte korunur |
| Hafızayı İndir oluştur | İki kapsam da yer alır ve her kayıt kapsam etiketi taşır |
| Observation için `project -> private` istenir | Reddedilir |
| Yayımlanmamış çalışma kaydı için `project -> private` istenir | Yalnız publication/reference guard kanıtlıysa, açık onay + revision + event ile kabul |
| Publication/reference guard yokken geri dönüş istenir | Fail-closed reddedilir |
| Template scope değişir | Geçmiş occurrence scope'u değişmez |
| Read-model rebuild çalışır | Kaynak kapsamı aynen yansıtır; source kayıt mutation'ı yapmaz |
