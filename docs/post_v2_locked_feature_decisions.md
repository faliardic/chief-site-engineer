# CSE — V2 Sonrası Kilitli Ürün Kararları

**Tarih:** 11 Ağustos 2026  
**Durum:** Toplantıda kilitlenmiş ürün kararları  
**Kapsam:** V2 sonrası değerlendirme; bu belge tek başına V3/V4+ sürüm taahhüdü değildir.

## Amaç

Bu belge, V2 tamamlandıktan sonra değerlendirilecek ve toplantıda davranışı netleştirilmiş ürün kararlarını tek yerde tutar. Buradaki maddeler brainstorm değildir; ürün davranışı açısından kilitlenmiştir. Hangi sürümde uygulanacakları daha sonra roadmap/issue planlamasında belirlenecektir.

Olgunlaşmamış fikirler ayrı `docs/product_brainstorm.md` havuzunda tutulur.

## Genel ürün ilkeleri

- CSE sürtünmesiz, kolay öğrenilebilir ve sezgisel kullanılmalıdır.
- Arayüz kendini açıklamalıdır; ipuçları "nasıl kullanılır" eğitimi vermek yerine özelliğin işi neden kolaylaştırdığını anlatmalıdır.
- Kullanıcı bir ayarı veya ilgili işlemi gerektiği bağlamda bulabilmelidir; "bu ayar neredeydi?" diye menülerde dolaşmaya zorlanmamalıdır.
- Görsel dil gösterişli "premium" hissi vermeye çalışmamalı; sade, kontrollü, modern ve "akıllıca tasarlanmış" izlenimi vermelidir.
- Hızlı işlemler kısa akışlarla tamamlanmalıdır; gereksiz form, zorunlu alan ve onay adımlarından kaçınılmalıdır.

## Kilitli kararlar

### 1. Mahal adları her zaman büyük harf

- Kullanıcı mahal adını küçük veya karma harfle girse bile CSE otomatik olarak **BÜYÜK HARFE** çevirecek.
- Büyük harf kullanımı yalnız görüntüleme tercihi değil, veri saklama standardı olacak.

### 2. Personel sicilinde İSG uyarısı

- Personelin İSG eksiği varsa sicil ekranında **“İSG EKSİĞİ VAR”** uyarısı gösterilecek.
- Aynı alanda **“İSG ekranına git”** eylemi bulunacak.
- Eksik belge detayları sicil ekranında listelenmeyecek.

### 3. Puantajda güçlü İSG / sigorta uyarısı

- İSG eksiği olan personel puantaja eklendiğinde önemli bir uyarı penceresi açılacak.
- Uyarı, İSG belgesiz veya sigortasız çalıştırmanın ciddi risk ve sorumluluk doğurduğunu etkili biçimde vurgulayacak.
- Uyarı kayıt işlemini otomatik olarak engellemeyecek.

### 4. Bağlama duyarlı ipuçları

- İpuçları kullanıcının bulunduğu ekrana göre değişecek.
- Ekranın köşe/kenar gibi ana işi engellemeyen bir alanında gösterilecek.
- Rastgele genel mesajlar yerine o ekranın sağladığı faydayı anlatacak.

### 5. İpuçları kullanım kılavuzu olmayacak

- İpuçları butonların nasıl kullanılacağını öğretmeyecek.
- Arayüz zaten kendini açıklamalı olacak.
- İpuçları yalnızca özelliğin şantiye şefinin işini nasıl kolaylaştırdığını / neden faydalı olduğunu kısa biçimde anlatacak.

### 6. Akıllı mikro animasyon dili

- Yumuşak ekran geçişleri, küçük ikon animasyonları, hafif vurgu ve durum geri bildirimleri kullanılacak.
- Animasyonlar dekorasyon için değil, akıcılık ve geri bildirim için kullanılacak.
- Sürekli parlayan veya dikkat dağıtan gösterişli efektlerden kaçınılacak.

### 7. Fotoğraf işaretleme ve düzenleme

- Orijinal saha fotoğrafı kesinlikle korunacak ve değiştirilmeden saklanacak.
- Düzenlenmiş / işaretlenmiş sürüm ayrı oluşturulacak.
- Araç seti saha odaklı, basit ve hızlı olacak: ok, şekil, serbest çizim, numaralı işaret, kısa metin/not vb.

### 8. DWG/PDF proje dosyaları ve “Projeden kesit al”

- Seçili projeye ait DWG/PDF proje dosyaları proje içinde her zaman sonradan eklenebilir olacak.
- Belge görüntüleyicisinde **“Projeden kesit al”** hızlı işlemi bulunacak.
- Kullanıcı DWG/PDF içinden bir alan seçerek görsel kesit oluşturabilecek.
- Kesit, fotoğraflarla aynı saha odaklı işaretleme/düzenleme araçlarıyla düzenlenebilecek.
- Orijinal DWG/PDF dosyası değiştirilmeyecek.
- Kesit, oluşturulduğu kaynak proje dosyası ve revizyonuna kalıcı olarak bağlı kalacak.
- Kaynak proje dosyasının adı kesitte görünür olacak.
- Kesitten kaynak projeye geri dönülebilecek.
- Yeni revizyon geldiğinde eski kesit yeni revizyona otomatik taşınmayacak.
- Bunun yerine **“Bu projenin daha yeni sürümü mevcut”** benzeri bir bilgilendirme gösterilecek.

### 9. Hesaplamalar Merkezi

- CSE içinde ayrı ve kapsamlı bir **Hesaplamalar** merkezi olacak.
- Bu merkez ürünün en değerli ana özelliklerinden biri olarak konumlanacak.
- Araçlar karmaşık mühendislik yazılımı gibi değil; basit, hızlı ve etkili saha araçları olacak.
- Donatı tahvili ve farklı metraj hesapları temel örnekler arasında olacak; kapsam zamanla genişletilecek.
- Hesaplama anlık ve serbest olacak; kayıt zorunlu olmayacak.
- Kayıt isteğe bağlı olacak ve **kaydet → gerekli değeri gir → kapat** akışı çok kısa sürecek.
- Gereksiz form, zorunlu alan veya çok adımlı kayıt akışı eklenmeyecek.

### 10. Hızlı fiziksel cetvel

- Uygulamanın ekran kenarında gerçek fiziksel ölçüye karşılık gelen cetvel özelliği olacak.
- Cetvel sürekli görünmeyecek; köşe/kenardaki **cetvel aç/kapa** kontrolüyle anında açılıp kapanacak.
- İlk açılışta kısa bir kalibrasyon penceresi gösterilecek.
- Kalibrasyon cihaz bazında hatırlanacak.
- Kullanıcı daha sonra Ayarlar üzerinden yeniden kalibrasyon yapabilecek.

### 11. Puantaj terminolojisi: “İşveren seç”

- Puantaj ekranındaki personel seçim akışında **“Taşeron seç”** ifadesi kullanılmayacak.
- Bunun yerine doğrudan **“İşveren seç”** yazacak.
- Bu madde yeni filtreleme davranışı tanımlamaz; terminoloji değişikliğidir.

### 12. Fotoğraf filigranı

- CSE içindeki orijinal fotoğraf filigransız ve değişmeden korunacak.
- Filigran yalnızca paylaşma, dışa aktarma veya galeriye kaydetme aşamasında isteğe bağlı üretilecek.
- Filigran küçük, okunabilir ve fotoğrafın alt köşesinde yer alacak.
- Proje adı, mahal ve tarih-saat gibi bağlam bilgilerini taşıyabilecek.
- Fotoğrafın kritik alanını kapatmayacak.
- Kullanıcı isterse sonradan crop yaparak filigranı kolayca kaldırabilecek.

### 13. Dosya Sağlığı yeniden konumlandırılacak

- **Dosya Sağlığı** ana ekrandan çıkarılacak.
- **Ayarlar → Dosya ve Veri Sağlığı** altında yer alacak.
- Sorun yoksa kullanıcıya sade biçimde **“Her şey yolunda”** bilgisi verilecek.
- Sorun varsa anlaşılır bir özet gösterilecek.
- Hash, orphan, staging, unsafe path gibi teknik ifadeler normal kullanıcıya doğrudan gösterilmeyecek.
- Dosya bütünlüğü / teşhis altyapısı korunacak.

### 14. Unutma Kutusu bildirimleri

- Unutma Kutusu boşsa bildirim gönderilmeyecek.
- Sabah, öğlen ve akşam hatırlatma zamanları desteklenecek.
- Kullanıcı Ayarlar üzerinden bildirimleri açıp kapatabilecek ve zamanlarını değiştirebilecek.
- Bildirime dokunulduğunda doğrudan Unutma Kutusu açılacak.
- Bildirim üzerinden gelindiyse ekranın üstünde küçük bir bildirim tercihleri kartı gösterilebilecek.
- Karta dokunulduğunda doğrudan ilgili bildirim ayarına gidilecek.

### 15. KKD hızlı seçim listesi

- KKD’yi elle yazma özelliği korunacak.
- Kullanıcıya önce temel hazır KKD listesi sunulacak.
- İlk temel sıra: **Baret → Yelek → İş ayakkabısı**.
- Liste zamanla diğer KKD’lerle genişletilebilecek.
- Hazır listede olmayan bir KKD elle eklenebilecek.

### 16. İSG modülü belge deposu değil takip sistemi olacak

- İSG ekranının ana amacı belge dosyalarını depolamak değil, **İSG belgeleri tam mı; değilse ne eksik?** sorusunu cevaplamak olacak.
- Gerekli belgeler kontrol listesi mantığıyla takip edilecek.
- Kullanıcı belgeleri tam / eksik olarak hızlıca işaretleyebilecek.
- **“Hepsini tamamla”** gibi hızlı toplu işlem desteklenebilecek.
- Belge PDF/fotoğrafı yüklemek bu özelliğin ana amacı olmayacak.

### 17. Operasyonel organizasyon ağacı

- Seçili projede işin içinde olan herkesin organizasyonel ilişkisini gösteren bir ağaç olacak.
- İşverenler, şantiye yönetimi, ekipler, ekip şefleri, personeller ve gerekli diğer operasyonel paydaşlar hiyerarşik biçimde gösterilebilecek.
- Kimin kime bağlı olduğu tek bakışta anlaşılacak.
- Organizasyon ağacındaki isme dokunulduğunda açılabilecek operasyonel kişi profili fikri henüz olgunlaşmadığı için `BRAIN-001` olarak brainstorm havuzunda tutuluyor.

### 18. Otomatik personel kodları ve sıralama

- Personel kodları CSE tarafından otomatik oluşturulacak.
- Kodlar kalıcı ve benzersiz olacak.
- İsim değişikliği personel kodunu değiştirmeyecek.
- Personel listeleri varsayılan olarak personel koduna göre sıralanacak.

### 19. Ekip şefi / meslek konusu

- Mevcut yapı kontrol edildi.
- Sorun görülmedi ve yeni geliştirme kararı alınmadı.
- Bu madde yalnız toplantı kaydı olarak tutulur; uygulanacak yeni özellik değildir.

### 20. Unutma Kutusuna hızlı erişim ve Hatırlatıcı dili

- Unutma Kutusu `Hatırlatıcı → Diğer → liste` gibi derin bir akışta saklanmayacak.
- Hatırlatıcı ekranında ayrı bir **Unutma Kutusu** butonu/ikonu olacak.
- Tek dokunuşla açılacak.
- Kutuda kayıt varsa ikon üzerinde kayıt sayısı rozeti gösterilebilecek.
- Unutma Kutusunun üstünde toplam kayıt sayısı, uzun süredir bekleyen kayıt sayısı ve en eski kaydın yaşı özetlenebilecek.
- Bugün eklenenlere özel vurgu yerine unutulma riski taşıyan eski kayıtlar öne çıkarılacak.
- Mevcut **“Unutma +”** ifadesi kaldırılacak.
- Yeni hatırlatıcı oluşturma eylemi **“+ Hatırlat”** olarak adlandırılacak.
- Unutma Kutusu ve yeni hatırlatıcı oluşturma eylemi görsel/anlamsal olarak net ayrılacak.

### 21. Global Proje Seçici

- Proje bağlamının anlamlı olduğu ekranlarda üst bölümde kolay erişilen global proje seçici bulunacak.
- Kullanıcı aktif projeyi değiştirdiğinde tüm proje-bağımlı ekranlar aynı proje bağlamına geçecek.
- Ajanda, Hatırlatıcılar, Puantaj, Personel, Beton, Fotoğraflar, proje dosyaları ve diğer proje-bağımlı ekranlar seçili projeye göre veri gösterecek.
- Kullanıcı her ekranda yeniden proje seçmek zorunda kalmayacak.
- Aktif proje uygulama boyunca korunacak.
- Ayarlar, Hakkında ve benzeri proje bağlamına ihtiyaç duymayan ekranlarda global proje seçici gösterilmeyecek.

## Sonraki süreç

1. Bu kararlar V2 kapsamına eklenmez.
2. V2 tamamlandıktan sonra kararlar değer / maliyet / bağımlılık açısından gruplanır.
3. Uygun maddeler V3 veya daha sonraki sürümlere atanır.
4. Uygulamaya alınacak her madde roadmap ve GitHub issue seviyesinde ayrıca kapsamlandırılır.
5. Henüz olgunlaşmamış fikirler `docs/product_brainstorm.md` içinde tutulmaya devam eder.
