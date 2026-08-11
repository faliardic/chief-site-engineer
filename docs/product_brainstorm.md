# CSE Ürün Brainstorm Havuzu

> Durum: V2 sonrası / olgunlaşmamış fikirler
> Son güncelleme: 2026-08-11

## Amaç

Bu belge, CHIEF SITE ENGINEER için değerli görünen ancak henüz yeterince olgunlaşmamış ürün fikirlerini kaybetmeden toplamak için kullanılır.

Buraya eklenen maddeler:

- V2 kapsamına otomatik olarak girmez.
- V3, V4+ veya başka bir sürüm için taahhüt sayılmaz.
- Doğrudan geliştirme issue'suna dönüştürülmez.
- Toplantılarda kullanım senaryosu, saha değeri, sürtünme, veri modeli, bağımlılıklar ve geliştirme maliyeti açısından olgunlaştırılır.
- Yeterince olgunlaşan fikirler daha sonra roadmap / issue sürecine taşınır.

Yeni ama henüz tam şekillenmemiş iyi fikirler bundan sonra öncelikle bu havuza eklenir.

---

## BRAIN-001 — Organizasyon ağacından açılan operasyonel kişi profili

**Durum:** Brainstorm / olgunlaştırılacak

### Fikir

Projedeki operasyonel organizasyon ağacında bir kişinin adına dokunulduğunda o kişinin CSE içindeki operasyonel profili açılır.

Bu profil klasik ve ağır bir özlük dosyası olmamalıdır. İlk birkaç saniyede şu sorulara cevap vermelidir:

- Bu kişi kim?
- Şantiyede ne yapıyor?
- Hangi işveren / ekip içinde?
- Kime bağlı, kimler ona bağlı?
- Şu anda dikkat edilmesi gereken operasyonel bir durum var mı?

### Olası profil bileşenleri

- Fotoğraf, ad-soyad, görev / meslek ve temel iletişim bilgileri.
- İşveren, ekip, ekip şefi / sorumlu ve organizasyon ağacındaki konumu.
- Kime bağlı olduğu ve varsa bağlı personeller.
- Personel için güncel puantaj / sahada olma durumu.
- İSG durumu: sade biçimde `İSG TAM` veya `İSG EKSİĞİ VAR`; eksikse ilgili İSG ekranına hızlı geçiş.
- Görev ve sorumlulukların kısa özeti.
- Açık görev / hatırlatıcı sayısı ve ilgili kayıtlara hızlı geçiş.
- Telefon arama, mesajlaşma veya benzeri hızlı iletişim işlemleri.
- İşe giriş/çıkış, ekip veya işveren değişikliği gibi operasyonel açıdan anlamlı kısa geçmiş.
- Kısa saha notları.
- Puantaj, İSG, KKD ve diğer ilgili CSE kayıtlarına bağlamsal hızlı geçişler.

### Tasarım fikri

Profil bütün kişiler için aynı ağır formu göstermemelidir. Aynı sade profil kabuğu korunurken kartlar kişinin rolüne göre değişebilir.

Örnek:

- Saha personelinde puantaj, İSG, KKD ve ekip bilgisi daha önde olabilir.
- Ekip şefi / mühendis profilinde sorumluluklar ve açık işler öne çıkabilir.
- Laboratuvar veya dış paydaş profilinde puantaj/KKD yerine firma, iletişim ve ilişkili operasyon kayıtları gösterilebilir.

Üst bölümde tek bakışta operasyonel özet veren küçük bir `Şu anda` kartı düşünülebilir:

> Ahmet Yılmaz — Kalıp Ekip Şefi  
> ABC Kalıp · 8 kişilik ekip  
> Bugün sahada · İSG TAM · 2 açık iş

### Ürün ilkesi

Profil kişinin özgeçmişini göstermekten çok **şantiyedeki mevcut operasyonel durumunu** göstermelidir.

### Henüz karara bağlanmayan sorular

- Profil üstünden doğrudan görev / hatırlatıcı oluşturulacak mı?
- Kişiler birden fazla operasyonel ilişkiye sahip olabilecek mi?
- Personel olmayan dış paydaşların profil veri modeli nasıl ayrılacak?
- Hangi bilgiler varsayılan görünür, hangileri ikinci seviyede kalacak?
- Gizlilik / erişim seviyeleri gerekecek mi?

---

## Yeni fikir ekleme şablonu

### BRAIN-XXX — Fikir adı

**Durum:** Brainstorm / olgunlaştırılacak

**Fikir:**  
Kısa açıklama.

**Neden değerli olabilir:**  
Saha problemini veya fırsatı açıkla.

**Olası kullanım:**  
Henüz kesinleşmemiş kullanım senaryoları.

**Açık sorular:**
- ...
- ...
