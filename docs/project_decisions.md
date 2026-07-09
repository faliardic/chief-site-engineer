# Proje Kararlari

## 001 Repo ve Calisma Anlasmalari

- Ilk adimda framework eklenmeyecek.
- Baslangic Python uygulamasi sade bir `main()` fonksiyonu ile kurulacak.
- Test araci olarak `pytest` kullanilacak.
- Proje dokumantasyonu Turkce tutulacak.
- Kod isimlendirmelerinde sade Ingilizce tercih edilecek.
- `data/` ve `exports/` klasorleri simdilik bos tutulacak, icerikleri genel olarak git disinda birakilacak.

## 002 Cekirdek Veri Modeli

- Cekirdek veri modelleri `dataclass` ile kurulacak.
- Veritabani bu asamada eklenmeyecek.
- JSON kayit sistemi bu asamada eklenmeyecek.
- Once veri sekli netlesecek.

## 003 Gunluk Saha Kaydi

- Gunluk saha kaydi `DailySiteLog` modeliyle temsil edilecek.
- Gunluk kayit once sadece veri modeli olarak kurulacak.
- Kalici kayit sistemi daha sonra ele alinacak.

## 004 Bellek Ici Basit Kayit Listeleme

- Listeleme ve filtreleme once bellek ici Python listeleriyle yapilacak.
- Veritabani, JSON ve dosya kayit sistemi eklenmeyecek.
- Ana fonksiyon isimleri:
  - `list_records`
  - `count_records`
  - `filter_records_by_project_id`
  - `filter_records_by_status`
- `list_records_by_project` fonksiyonu geriye uyumluluk icin gecici olarak birakildi.
- Ana dokumantasyon ve testlerde tercih edilen isim `filter_records_by_project_id` olacak.
- Ileride sade API yuzeyi icin `list_records_by_project` kaldirilabilir veya deprecated olarak isaretlenebilir.

## Learning Standardi

- `learning/` klasoru sadece kisa not degil, yazilim ogrenim arsividir.
- Learning dosyalari gercek kod bloklari uzerinden aciklanir.
- Test kodlari da aciklanir.
- Yeni terimler learning dosyasinda ve `learning/GLOSSARY.md` icinde tanimlanir.
- "Sunu yaptik / Boyle yaptik / Cunku / Boylece" anlatim yapisi korunur.

## Git Karari

- Git commit islemi bu gorevde yapilmayacak.
- Ancak repo ilk uygun stabil noktada commitlenmelidir.
- Su an Adim 001-004 tamamlandigi icin ilk commit icin uygun aday olusmustur.

## 005 Beton Dokum ve Numune Takip Baslangici

- Beton dokum ve beton numune takibi once veri modeli olarak kurulacak.
- EBIS entegrasyonu bu asamada yapilmayacak.
- Veritabani ve JSON kayit sistemi bu asamada yapilmayacak.
- `ConcretePour` ve `ConcreteSample` modelleri ileride beton takip modulunun temelini olusturacak.
- 7 gunluk ve 28 gunluk test sonuclari simdilik opsiyonel alan olarak tutulacak.

## 006 Yapi Denetim Kontrol Cagrilari

- Yapi denetim kontrol cagrilari once veri modeli olarak kurulacak.
- EBIS entegrasyonu bu asamada yapilmayacak.
- Bildirim veya takvim sistemi bu asamada yapilmayacak.
- `InspectionRequest` modeli, yapi denetim sureclerinin takip edilmesi icin temel model olacak.
- `related_pour_id` alani, ileride beton dokum kaydiyla kontrol cagrisi arasinda baglanti kurmak icin opsiyonel tutulacak.

## 007 Uygunsuzluk Kayitlari

- Uygunsuzluk kayitlari once veri modeli olarak kurulacak.
- Fotograf/dosya yukleme bu asamada yapilmayacak.
- Tutanak, PDF veya resmi yazisma uretimi bu asamada yapilmayacak.
- Veritabani ve JSON kayit sistemi bu asamada yapilmayacak.
- `NonconformityRecord` modeli, uygunsuzluklarin takip edilmesi icin temel model olacak.
- `related_inspection_request_id` alani ileride yapi denetim kontrol cagrisiyla iliski kurmak icin opsiyonel tutulacak.
- `related_pour_id` alani ileride beton dokum kaydiyla iliski kurmak icin opsiyonel tutulacak.
- `severity` ve `status` alanlari bu asamada serbest metin olarak tutulacak; enum sistemi ileride degerlendirilecek.

## 008 Dosya/Ek Arsivleme Baslangici

- Dosya/ek arsivleme once referans modeli olarak kurulacak.
- Gercek dosya kopyalama, tasima, silme veya yukleme bu asamada yapilmayacak.
- Veritabani ve JSON kayit sistemi bu asamada yapilmayacak.
- `AttachmentRecord` modeli, ileride dosya arsivleme modulunun temelini olusturacak.
- `related_model` ve `related_id` alanlari, dosya eklerinin farkli kayit tipleriyle iliskilendirilmesi icin opsiyonel tutulacak.
- `file_path` alani simdilik sadece metinsel yol referansi olarak tutulacak.

## 009 Malzeme Giris/Kullanim Kaydi Baslangici

- Malzeme takibi once veri modeli olarak baslatildi.
- Gercek stok hareketi sistemi kurulmadi.
- Malzeme giris/kullanim ayrimi simdilik `received_date`, `used_date` ve `status` alanlariyla temsil edildi.
- Irsaliye/fotograf gibi kanitlar ileride `AttachmentRecord` ile baglanabilir.
- Veritabani, JSON, API ve GUI daha sonraki adimlara birakildi.

## 010 Toplanti Tutanagi ve Aksiyon Kaydi Baslangici

- Toplanti ve aksiyon takibi once veri modeli olarak baslatildi.
- Tutanaktan otomatik gorev uretme bu adimda yapilmadi.
- Toplanti ile aksiyon arasinda kod seviyesinde iliski kurulmadi.
- Katilimcilar, gundem ve kararlar simdilik metinsel alan olarak tutuldu.
- Veritabani, JSON, API, GUI, takvim ve bildirim sistemi sonraya birakildi.
- Aksiyonlarin ileride issue/task/punch list moduluyla baglanabilecegi kaydedildi.

## 011 RFI / Submittal Lite Kaydi Baslangici

- RFI/Submittal takibi once veri modeli olarak baslatildi.
- Gercek onay akisi, retur/revizyon ve e-posta/bildirim sureci bu adimda kurulmadi.
- RFI ve Submittal kayitlari baska modellere kod seviyesinde baglanmadi.
- Teknik soru/cevap ve teknik gonderim/onay kavramlari ayri modeller olarak tutuldu.
- Veritabani, JSON, API, GUI, dosya eki ve raporlama daha sonraki adimlara birakildi.
- Ileride `AttachmentRecord` ve `MaterialRecord` ile baglanti kurulabilecegi kaydedildi.

## 012 Gunluk Rapor Ozet Modeli Baslangici

- Gunluk rapor takibi once veri modeli olarak baslatildi.
- Gercek PDF/Excel rapor uretimi bu adimda yapilmadi.
- Hava durumu yalnizca metinsel alan olarak tutuldu; API entegrasyonu yapilmadi.
- Gunluk is, iscilik, ekipman, malzeme, sorun ve is guvenligi ozetleri ayri metinsel alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadı.
- Veritabani, JSON, API, GUI, dosya eki ve raporlama daha sonraki adimlara birakildi.

## 013 Proje Tarafi ve Kisi Kaydi Baslangici

- Proje tarafi ve iletisim kisisi takibi once veri modeli olarak baslatildi.
- Gercek rehber/CRM sistemi kurulmadi.
- Firma/kurum tarafi ile kisi kaydi ayri modeller olarak tutuldu.
- Bu iki model arasinda kod seviyesinde iliski kurulmadı.
- Telefon, e-posta ve vergi/kimlik numarasi dogrulamasi yapilmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.
- Ileride bu kayitlarin toplanti, aksiyon, RFI, submittal, malzeme ve gunluk rapor kayitlariyla baglanabilecegi kaydedildi.

## 014 Santiye Lokasyon / Mahal Kaydi Baslangici

- Santiye lokasyon/mahal takibi once veri modeli olarak baslatildi.
- Gercek lokasyon yonetim sistemi kurulmadı.
- Kat plani, harita, mahal hiyerarsisi ve arama/filtreleme bu adimda yapilmadi.
- Blok, kat, bolge, aks ve disiplin bilgileri ayri metinsel alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadı.
- Veritabani, JSON, API, GUI ve raporlama sonraya birakildi.
- Ileride bu modelin kontrol, uygunsuzluk, gunluk rapor, malzeme ve ek/fotograf kayitlariyla baglanabilecegi kaydedildi.

## 015 Ekip / Iscilik Kaydi Baslangici

- Ekip/iscilik takibi once veri modeli olarak baslatildi.
- Gercek puantaj, bordro, vardiya ve performans sistemi kurulmadi.
- Ekip adi, ekip turu, firma, kisi sayisi, calisma alani ve calisma tarihi ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.
- Ileride bu modelin gunluk rapor, lokasyon, taseron/proje tarafi ve saha ilerleme kayitlariyla baglanabilecegi kaydedildi.

## 016 Ekipman / Makine Kaydi Baslangici

- Ekipman/makine takibi once veri modeli olarak baslatildi.
- Gercek bakim, yakit, zimmet, gunluk calisma saati, operator performansi ve makine verimlilik sistemi kurulmadi.
- Ekipman adi, ekipman turu, sahip firma, seri/plaka bilgisi, calisma alani ve sorumlu kisi/ekip ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.
- Ileride bu modelin gunluk rapor, lokasyon, ekip/iscilik, bakim ve saha ilerleme kayitlariyla baglanabilecegi kaydedildi.

## 017 Tedarikci Kaydi Baslangici

- Onceki malzeme kaydi onerisi, `MaterialRecord` zaten mevcut oldugu icin tedarikci/firma kaydi olarak revize edildi.
- Tedarikci, hizmet saglayici, ekipman kiralama firmasi ve taseron gibi firmalar once veri modeli olarak baslatildi.
- Gercek satin alma, sozlesme, fatura, irsaliye, odeme, cari hesap ve tedarikci performans sistemi kurulmadi.
- Tedarikci adi, tedarikci turu, iletisim kisisi, telefon, e-posta ve hizmet alani ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 018 Saha Notu Kaydi Baslangici

- Onceki iletisim kisisi onerisi, `ContactPersonRecord` zaten mevcut oldugu icin saha notu kaydi olarak revize edildi.
- Saha notlari, gozlemler, uyarilar, hatirlatmalar ve serbest aciklamalar once veri modeli olarak baslatildi.
- Gercek gorev yonetimi, hatirlatici, bildirim, gunluk rapor, denetim, uygunsuzluk, fotograf/dosya eki, takvim, kisi atama ve oncelik sistemi kurulmadi.
- Not basligi, not turu, konum, ilgili konu ve not tarihi ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 019 Gorev Adayi Kaydi Baslangici

- Goreve donusebilecek kucuk aksiyon adaylari once veri modeli olarak baslatildi.
- Gercek gorev yonetimi, hatirlatici, bildirim, takvim, kisi atama, oncelik, is emri ve tamamlandi/ertelendi is akisi kurulmadi.
- Gorev basligi, gorev turu, ilgili alan, kaynak ve hedef tarih ayri alanlar olarak tutuldu.
- Saha notu veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 020 Kontrol Maddesi Kaydi Baslangici

- `ChecklistItem` mevcut oldugu icin `ChecklistItemRecord` ayri ve daha spesifik kayit modeli olarak baslatildi.
- Tekil kontrol maddeleri once veri modeli olarak baslatildi.
- Gercek checklist sistemi, denetim formu, uygunsuzluk kaydi, puanlama, onay is akisi, fotograf/dosya eki ve raporlama sistemi kurulmadi.
- Kontrol maddesi basligi, kategori, ilgili alan ve kontrol referansi ayri alanlar olarak tutuldu.
- Saha notu, gorev veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 021 Kontrol Sonucu Kaydi Baslangici

- Yapilan kontrollerin basit sonuc bilgisi once veri modeli olarak baslatildi.
- Gercek checklist sistemi, denetim formu, uygunsuzluk kaydi, puanlama, onay is akisi, fotograf/dosya eki ve raporlama sistemi kurulmadi.
- Kontrol basligi, kontrol alani, sonuc, kontrol eden kisi ve kontrol tarihi ayri alanlar olarak tutuldu.
- Kontrol maddesi, saha notu, gorev veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 022 Uygunsuzluk Adayi Kaydi Baslangici

- Uygunsuzluk kaydina donusebilecek gozlem, eksik, hata, risk veya kontrol sonucu notlari once veri modeli olarak baslatildi.
- Gercek uygunsuzluk yonetimi, NCR sureci, duzeltici faaliyet, sorumlu atama, termin takibi, onay/kapatma is akisi, fotograf/dosya eki ve raporlama sistemi kurulmadi.
- Aday basligi, aday turu, konum, gozlenen sorun, tespit eden kisi ve tespit tarihi ayri alanlar olarak tutuldu.
- Kontrol sonucu, saha notu, gorev veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 023 Uygunsuzluk Adayi Degerlendirme Kaydi Baslangici

- Uygunsuzluk adayi dogrudan kesin uygunsuzluk olarak kabul edilmeyecek.
- Once degerlendirme kaydi ile incelenecek.
- Bu sayede sahada gorulen her sorun ile resmi uygunsuzluk ayrimi korunacak.
- Degerlendiren kisi, degerlendirme tarihi, sonuc, karar gerekcesi ve sonraki aksiyon ayri alanlar olarak tutuldu.
- Kesin uygunsuzluk kaydi olusturulmadi.
- Duzeltici faaliyet sistemi kurulmadı.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 024 Uygunsuzluk Adayi Aksiyon Kaydi Baslangici

- Uygunsuzluk adayi degerlendirildikten sonra alinan ilk aksiyon karari ayri bir veri modeliyle tutulacak.
- Bu aksiyon kaydi, kesin uygunsuzluk veya duzeltici faaliyet sistemi degildir.
- Amac, sahada fark edilen aday sorunlarin degerlendirme sonrasi ne yapilacagina dair ilk karar bilgisini guvenli ve kucuk bir modelle temsil etmektir.
- Aday basligi, degerlendirme sonucu, aksiyon karari, aksiyon sorumlusu, hedef tarih ve aksiyon aciklamasi ayri alanlar olarak tutuldu.
- Kesin uygunsuzluk kaydi olusturulmadi.
- Duzeltici faaliyet sistemi kurulmadı.
- Gorev atama / sorumluluk takip akisi kurulmadı.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 025 Uygunsuzluk Adayi Takip Durumu Ozeti Baslangici

- Uygunsuzluk adayi surecinin mevcut durumu ayri bir takip ozeti modeliyle temsil edilecek.
- Bu model gercek bir is akisi motoru degildir.
- Amac; aday kayit, degerlendirme ve aksiyon kararindan sonra surecin sahada hangi durumda oldugunu veri seviyesinde ozetlemektir.
- Aday basligi, degerlendirme sonucu, aksiyon karari, aksiyon sorumlusu, takip durumu, son guncelleme tarihi ve ozet not ayri alanlar olarak tutuldu.
- Kesin uygunsuzluk kaydi olusturulmadi.
- Duzeltici faaliyet sistemi kurulmadı.
- Gorev atama / sorumluluk takip akisi kurulmadı.
- Otomatik durum guncelleme sistemi kurulmadı.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 026 AttachmentRecord ile Uygunsuzluk Adayi Ek Dosya Baglantisi

- Uygunsuzluk adayi icin ayri `NonconformityCandidateAttachment` modeli olusturulmadi.
- Bunun yerine mevcut genel `AttachmentRecord` kullanilacak.
- Gerekce: Ek dosya mantigi bircok kayit tipiyle ortak oldugu icin tekrar eden ozel modellerden kacinildi.
- Uygunsuzluk adayi ekleri icin `related_model` degeri `NonconformityCandidateRecord` olarak tutulacak.
- Ilgili aday kayit kodu `related_id` alaninda tutulacak.
- Gercek dosya yukleme, kopyalama, silme veya tasima islemi bu adimda eklenmedi.
- Veritabani, JSON, API ve GUI eklenmedi.

## 027 Uygunsuzluk Adayi Surec Zinciri Gorunum Modeli Baslangici

- Uygunsuzluk adayi surec parcalari tek ozet gorunum modelinde temsil edilecek.
- `NonconformityCandidateProcessViewRecord`, kontrol sonucu, aday kaydi, degerlendirme, aksiyon, takip ozeti ve ek dosya sayisini bir arada okuma amaciyla eklendi.
- Bu model veritabani sorgusu veya otomatik join mekanizmasi degildir.
- Baglanti alanlari simdilik metinsel ID alanlari olarak tutulacak.
- `attachment_count` ek dosya sayisini temsil edecek, gercek dosya sayma islemi yapmayacak.
- Veritabani, JSON, API, GUI ve otomatik raporlama eklenmedi.

## 028 Uygunsuzluk Adayi Durum Gecmisi Modeli Baslangici

- Uygunsuzluk adayi durum degisiklikleri ayri bir gecmis kaydi modeliyle temsil edilecek.
- `NonconformityCandidateStatusHistoryRecord`, eski durum, yeni durum, degisiklik sebebi, degistiren kisi ve degisiklik tarihini tutacak.
- `source_record` alani durum degisikliginin hangi kayit veya surec parcasindan kaynaklandigini metinsel olarak gosterecek.
- Bu model otomatik durum guncelleme sistemi veya is akisi motoru degildir.
- Veritabani, JSON, API, GUI, otomatik raporlama ve dosya islemi eklenmedi.

## 029 Uygunsuzluk Adayi Sorumluluk / Atama Modeli Baslangici

- Uygunsuzluk adayi sorumluluk ve atama bilgisi ayri bir veri modeliyle temsil edilecek.
- `NonconformityCandidateAssignmentRecord`, aday kaydin kime atandigini, kim tarafindan atandigini, atama tarihini, hedef tarihi, sorumluluk notunu ve onceligi tutacak.
- Bu model otomatik gorev atama, bildirim veya is emri sistemi degildir.
- `priority` alani bu adimda serbest metin olarak tutulacak ve varsayilan degeri `normal` olacak.
- `status` alani varsayilan olarak `assigned` olacak.
- Veritabani, JSON, API, GUI, otomatik bildirim ve dosya islemi eklenmedi.

## 030 Uygunsuzluk Adayi Kapanis / Sonuc Modeli Baslangici

- Uygunsuzluk adayi kapanis ve sonuc bilgisi ayri bir veri modeliyle temsil edilecek.
- `NonconformityCandidateClosureRecord`, kapanis karari, kapanis gerekcesi, kapatan kisi, kapanis tarihi, nihai durum, sonuc notu ve takip gerekliligi bilgisini tutacak.
- Bu model otomatik kapatma, otomatik durum guncelleme veya kesin uygunsuzluk/NCR olusturma sistemi degildir.
- `requires_follow_up` alani varsayilan olarak `False` olacak.
- Veritabani, JSON, API, GUI, otomatik raporlama ve dosya islemi eklenmedi.

## 031 NotebookLM Podcast Notu - Adim 026-030

- Adim 026-030 araligi icin final NotebookLM podcast notu hazirlandi.
- Podcast notu, uygunsuzluk adayinin kanit baglantisi, surec gorunumu, durum gecmisi, sorumluluk atamasi ve kapanis sonucuyla takip edilebilir bir saha surecine donusmesini ozetler.
- Bu adimda yeni model, test modeli, veritabani, JSON, API, GUI veya dosya islemi eklenmedi.

## 032 Uygunsuzluk Adayindan Kesin Uygunsuzluga Donusum Modeli Baslangici

- `NonconformityRecord` modeli zaten Adim 007'de mevcut oldugu icin Adim 032'de yeniden olusturulmadi.
- Aday kayit ile kesin uygunsuzluk kaydi arasindaki donusum ayri `NonconformityCandidateConversionRecord` modeliyle temsil edilecek.
- Bu model aday kaydin hangi NCR kaydina, kim tarafindan, ne zaman ve hangi gerekceyle donusturuldugunu tutacak.
- Bu adim otomatik NCR olusturma, otomatik donusum, duzeltici faaliyet sistemi veya onay akisi degildir.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 033 NonconformityRecord Model Degerlendirme Raporu

- Bu adim sadece degerlendirme ve revizyon karar hazirligi olarak yapildi.
- `NonconformityRecord` modeli degistirilmedi.
- Yeni model veya test modeli eklenmedi.
- Mevcut modelin Adim 021-032 uygunsuzluk adayi ve donusum zinciriyle iliskisi raporlandi.
- Olası revizyon alanlari karar raporunda listelendi; revizyon daha sonraki ayri bir adima birakildi.

## 034 NonconformityRecord Alan Revizyonu

- Mevcut `NonconformityRecord` modeli kontrollu sekilde revize edildi.
- `nonconformity_type`, `detected_by`, `detection_date` ve `final_status` alanlari eklendi.
- `source_candidate_id` ve `conversion_record_id` alanlari bilincli olarak eklenmedi.
- Gerekce: Aday kayit ile kesin uygunsuzluk kaydi arasindaki baglanti `NonconformityCandidateConversionRecord` ile temsil ediliyor.
- Bu adimda yeni model, veritabani, JSON, API, GUI, otomatik NCR olusturma, otomatik donusum, duzeltici faaliyet sistemi, onay akisi veya dosya islemi eklenmedi.

## 035 Kesin Uygunsuzluk Surec Gorunum Modeli Baslangici

- Kesin uygunsuzluk / NCR surecini tek bakista gostermek icin `NonconformityProcessViewRecord` modeli eklendi.
- `source_candidate_id` ve `conversion_record_id` alanlari bu modelde sadece gorunum ve ozet amaciyla kullanilacak.
- Asil adaydan NCR'a donusum iliskisi `NonconformityCandidateConversionRecord` ile temsil edilmeye devam edecek.
- Bu model veritabani sorgusu, API cevabi, GUI tablosu, otomatik NCR olusturma veya duzeltici faaliyet sistemi degildir.
- Veritabani, JSON, API, GUI, otomatik donusum, onay akisi ve dosya islemi eklenmedi.

## 036 Kesin Uygunsuzluk Durum Gecmisi Modeli Baslangici

- Kesin uygunsuzluk / NCR durum degisiklikleri ayri bir gecmis kaydi modeliyle temsil edilecek.
- `NonconformityStatusHistoryRecord`, eski durum, yeni durum, degisiklik sebebi, degistiren kisi ve degisiklik tarihini tutacak.
- `source_record` alani durum degisikliginin hangi NCR kaydi veya surec parcasindan kaynaklandigini metinsel olarak gosterecek.
- Bu model otomatik durum guncelleme sistemi, is akisi motoru veya duzeltici faaliyet sistemi degildir.
- Veritabani, JSON, API, GUI, otomatik NCR olusturma, onay akisi ve dosya islemi eklenmedi.

## 037 Kesin Uygunsuzluk Sorumluluk / Atama Modeli Baslangici

- Kesin uygunsuzluk / NCR sorumluluk atamasi ayri bir veri modeliyle temsil edilecek.
- `NonconformityAssignmentRecord`, NCR kaydinin hangi kisi, ekip, firma veya sorumlu birime atandigini tutacak.
- Aday uygunsuzluk atama modeli olan `NonconformityCandidateAssignmentRecord` degistirilmedi; bu adim kesin uygunsuzluk kapsamindadir.
- `status` alani varsayilan olarak `assigned`, `notes` alani varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik atama, bildirim, onay akisi veya dosya islemi degildir.

## 038 Kesin Uygunsuzluk Duzeltici Faaliyet Modeli Baslangici

- Kesin uygunsuzluk / NCR icin planlanan duzeltici faaliyet ayri bir veri modeliyle temsil edilecek.
- `NonconformityCorrectiveActionRecord`, faaliyet basligi, aciklamasi, sorumlusu, planlanan baslangic tarihi, hedef tarihi ve tamamlanma tarihini tutacak.
- Mevcut `NonconformityRecord.corrective_action` alani degistirilmedi; bu adim daha ayrintili ve izole faaliyet kaydi seklini baslatir.
- `verification_required` varsayilan olarak `True`, `status` varsayilan olarak `planned`, `completion_date` ve `notes` varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik kapatma, onay akisi, bildirim veya dosya islemi degildir.

## 039 Kesin Uygunsuzluk Duzeltici Faaliyet Dogrulama Modeli Baslangici

- Kesin uygunsuzluk / NCR duzeltici faaliyetinin kontrol ve dogrulama sonucu ayri bir veri modeliyle temsil edilecek.
- `NonconformityCorrectiveActionVerificationRecord`, faaliyetin kim tarafindan, hangi tarihte, hangi sonuc ve notla dogrulandigini tutacak.
- `NonconformityCorrectiveActionRecord` faaliyetin kendisini; bu yeni model ise faaliyetin kontrol sonucunu temsil eder.
- `requires_rework` varsayilan olarak `False`, `next_action` varsayilan olarak `None`, `status` varsayilan olarak `verified`, `notes` varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik kapatma, otomatik onay, bildirim veya dosya islemi degildir.

## 040 Kesin Uygunsuzluk Kapatma Modeli Baslangici

- Kesin uygunsuzluk / NCR kapanis karari ayri bir veri modeliyle temsil edilecek.
- `NonconformityClosureRecord`, kapanis tarihini, kapatan kisiyi, kapanis sonucunu, kapanis gerekcesini ve dogrulanmis faaliyet baglantisini tutacak.
- `NonconformityCorrectiveActionVerificationRecord` duzeltici faaliyetin sahada uygun bulunup bulunmadigini; bu yeni model ise NCR kaydinin kapanis kararini temsil eder.
- `final_status` varsayilan olarak `closed`, `requires_follow_up` varsayilan olarak `False`, `follow_up_note` ve `notes` varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik kapatma, otomatik onay, bildirim veya dosya islemi degildir.

## 041 Kesin Uygunsuzluk Kayit Deposu Baslangici

- `NonconformityRecord` kayitlarini bellek icinde yonetmek icin `NonconformityRepository` sinifi eklendi.
- Repository sadece `NonconformityRecord` icin calisacak; genel kayit deposu veya kalici saklama katmani degildir.
- `add`, `list_all` ve `find_by_id` davranislari baslangic kapsaminda tutuldu.
- Var olmayan `nonconformity_id` aramalarinda `None` dondurulecek.
- JSON, SQLite, API, GUI, CLI, dosya islemi ve otomatik is akisi eklenmedi.

## 042 NonconformityRepository Duplicate Id Kontrolu

- `NonconformityRepository.add` davranisina ayni `nonconformity_id` degerine sahip ikinci kaydi engelleyen kontrol eklendi.
- Ayni kimlik tekrar eklenirse acik mesajli `ValueError` yukseltilecek.
- Farkli `nonconformity_id` degerlerine sahip kayitlar normal sekilde eklenmeye devam edecek.
- Bu karar veritabani unique constraint degil, bellek ici Python kontroludur.
- JSON, SQLite, API, GUI, CLI, dosya islemi ve otomatik is akisi eklenmedi.

## 043 NonconformityRepository Durum Filtreleme

- `NonconformityRepository` icine `list_by_status(status)` davranisi eklendi.
- Bu davranis sadece bellek icindeki `NonconformityRecord.status` alanina gore filtreleme yapacak.
- Eslesen kayitlar mevcut eklenme sirasini koruyarak liste olarak dondurulecek.
- Eslesen kayit yoksa bos liste dondurulecek.
- JSON, SQLite, API, GUI, CLI, dosya islemi, dashboard ve otomatik is akisi eklenmedi.

## 044 NonconformityRepository Sorumlu Filtreleme

- `NonconformityRepository` icine `list_by_responsible_party(responsible_party)` davranisi eklendi.
- Bu davranis sadece bellek icindeki `NonconformityRecord.responsible_party` alanina gore filtreleme yapacak.
- Eslesen kayitlar mevcut eklenme sirasini koruyarak liste olarak dondurulecek.
- Eslesen kayit yoksa bos liste dondurulecek.
- JSON, SQLite, API, GUI, CLI, dosya islemi, dashboard ve otomatik is akisi eklenmedi.

## 045 NonconformityRepository Durum Ozeti

- `NonconformityRepository` icine `get_status_summary()` davranisi eklendi.
- Bu davranis repository icindeki `NonconformityRecord.status` degerlerini bellek icinde sayacak.
- Sonuc `dict[str, int]` olarak dondurulecek; ornegin `{"open": 2, "closed": 1}`.
- Repository bos ise bos dict dondurulecek.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 046 NonconformityRepository Sorumlu Taraf Ozeti

- `NonconformityRepository` icine `get_responsible_party_summary()` davranisi eklendi.
- Bu davranis repository icindeki `NonconformityRecord.responsible_party` degerlerini bellek icinde sayacak.
- `responsible_party` degeri `None` olan kayitlar `unassigned` anahtari altinda sayilacak.
- Repository bos ise bos dict dondurulecek.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 047 NonconformityRepository Genel Ozet

- `NonconformityRepository` icine `get_overview_summary()` davranisi eklendi.
- Bu davranis toplam, acik, kapali, atanmis ve atanmamis kayit sayilarini bellek icinde hesaplayacak.
- Bos repository icin tum sayaclar `0` olacak sekilde sabit anahtarli dict dondurulecek.
- Bu davranis dashboard degil, dashboard/rapor/AI soru-cevap icin veri hazirlayan bellek ici Python metodudur.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 048 NonconformityRepository Status Guncelleme

- `NonconformityRepository` icine `update_status(nonconformity_id, new_status)` davranisi eklendi.
- Mevcut kayit bulunursa `status` alani bellek icinde guncellenecek ve guncellenen kayit dondurulecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis otomatik `NonconformityStatusHistoryRecord` olusturmayacak.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 049 NonconformityRepository Sorumlu Taraf Guncelleme

- `NonconformityRepository` icine `update_responsible_party(nonconformity_id, responsible_party)` davranisi eklendi.
- Mevcut kayit bulunursa `responsible_party` alani bellek icinde guncellenecek ve guncellenen kayit dondurulecek.
- `responsible_party` degeri `str` veya `None` olabilir; `None` degeri ozetlerde `unassigned` olarak yorumlanmaya devam edecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis otomatik `NonconformityAssignmentRecord` olusturmayacak.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 050 NonconformityRepository Kayit Var Mi Kontrolu

- `NonconformityRepository` icine `exists(nonconformity_id)` davranisi eklendi.
- Bu davranis verilen `nonconformity_id` degerine sahip kayit varsa `True`, yoksa `False` dondurecek.
- Varlik kontrolu `find_by_id` davranisini bozmayacak ve mevcut kayitlari degistirmeyecek.
- Bu davranis JSON veya SQLite sorgusu degil, bellek ici Python kontroludur.
- Silme, arsivleme, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 051 NonconformityRepository Kayit Sayisi

- `NonconformityRepository` icine `count()` davranisi eklendi.
- `count()` repository icindeki toplam `NonconformityRecord` sayisini int olarak dondurecek.
- `NonconformityRepository` icine `count_by_status(status)` davranisi eklendi.
- `count_by_status(status)` verilen durum degerine sahip kayit sayisini int olarak dondurecek; eslesme yoksa `0` dondurecek.
- Bu davranislar mevcut kayitlari degistirmeyecek ve `list_by_status` davranisini bozmayacak.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi, silme, arsivleme ve otomatik is akisi eklenmedi.

## 052 NonconformityRecord Arsiv Alani

- `NonconformityRecord` icine `is_archived: bool = False` alani eklendi.
- Varsayilan deger `False` olarak belirlendi; yeni NCR kayitlari aktif/arsivlenmemis kabul edilecek.
- `is_archived=True` verilerek kaydin arsivlenmis olarak temsil edilebilmesi saglandi.
- Bu adimda repository archive/restore davranisi, otomatik arsivleme, silme veya filtreleme eklenmedi.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 053 NonconformityRepository Aktif / Arsiv Filtreleme

- `NonconformityRepository` icine `list_active()` davranisi eklendi.
- `list_active()` `is_archived == False` olan kayitlari mevcut eklenme sirasiyla liste olarak dondurecek.
- `NonconformityRepository` icine `list_archived()` davranisi eklendi.
- `list_archived()` `is_archived == True` olan kayitlari mevcut eklenme sirasiyla liste olarak dondurecek.
- Eslesen kayit yoksa bos liste dondurulecek ve mevcut kayitlar degistirilmeyecek.
- NonconformityRecord modeli, JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi, silme, otomatik arsivleme, restore ve otomatik is akisi eklenmedi.

## 054 NonconformityRepository Arsivleme

- `NonconformityRepository` icine `archive(nonconformity_id)` davranisi eklendi.
- Mevcut kayit bulunursa `is_archived` alani bellek icinde `True` yapilacak ve guncellenen kayit dondurulecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis kaydi silmeyecek, mevcut kayit sirasini degistirmeyecek ve `status` alanina dokunmayacak.
- Restore, otomatik kapanis, otomatik durum gecmisi, JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 055 NonconformityRepository Restore

- `NonconformityRepository` icine `restore(nonconformity_id)` davranisi eklendi.
- Mevcut kayit bulunursa `is_archived` alani bellek icinde `False` yapilacak ve guncellenen kayit dondurulecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis kaydi silmeyecek, mevcut kayit sirasini degistirmeyecek ve `status` alanina dokunmayacak.
- NonconformityRecord modeli, otomatik arsivleme, otomatik kapanis, otomatik durum gecmisi, JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 056 NonconformityRepository Arsiv Ozeti

- `NonconformityRepository` icine `get_archive_summary()` davranisi eklendi.
- Bu davranis aktif, arsivlenmis ve toplam NCR kayit sayilarini `dict[str, int]` olarak dondurecek.
- Bos repository icin `{"active": 0, "archived": 0, "total": 0}` dondurulecek.
- `archive` ve `restore` davranislari sonrasi ozet degerleri guncel `is_archived` alanina gore hesaplanacak.
- Kayit silme, otomatik history, workflow, status degisimi, JSON, SQLite, API, GUI, CLI, dashboard ve dosya islemi eklenmedi.

## 057 NonconformityRepository Arsivlenmis Kayitlari Listeleme

- Mevcut `NonconformityRepository.list_archived()` davranisi Adim 057 kapsami icin netlestirildi.
- Bu davranis sadece `is_archived == True` olan NCR kayitlarini dondurecek.
- Bos repository veya arsivlenmis kayit olmayan repository icin bos liste dondurulecek.
- `restore` sonrasi aktif hale gelen kayitlar artik arsiv listesinde gorunmeyecek.
- Kayit silme, status degisimi, otomatik history, workflow, JSON, SQLite, API, GUI, CLI ve buyuk refactor eklenmedi.

## 058 NonconformityRepository Aktif Kayitlari Listeleme

- Mevcut `NonconformityRepository.list_active()` davranisi Adim 058 kapsami icin netlestirildi.
- Bu davranis sadece `is_archived == False` olan NCR kayitlarini dondurecek.
- Bos repository veya tum kayitlari arsivlenmis repository icin bos liste dondurulecek.
- `restore` sonrasi tekrar aktif hale gelen kayitlar aktif listede yeniden gorunecek.
- Kayit silme, status degisimi, otomatik history, workflow, JSON, SQLite, API, GUI, CLI ve buyuk refactor eklenmedi.

## 059 NonconformityRepository Tum Kayitlari Listeleme

- Mevcut `NonconformityRepository.list_all()` davranisi Adim 059 kapsami icin netlestirildi.
- Bu davranis aktif ve arsivlenmis tum NCR kayitlarini mevcut eklenme sirasiyla dondurecek.
- Bos repository icin bos liste dondurulecek.
- Arsivlenmis kayitlar veya aktif kayitlar dislanmayacak.
- `archive` ve `restore` islemleri kaydin tum liste icinde kalmasini saglayacak; toplam liste silme davranisi gibi calismayacak.
- Kayit silme, status degisimi, `is_archived` degisimi, otomatik history, workflow, JSON, SQLite, API, GUI, CLI ve buyuk refactor eklenmedi.

## 060 NonconformityRepository Arsiv / Listeleme Butunluk Kontrolu

- Bu adimda yeni repository methodu eklenmedi.
- Mevcut `archive`, `restore`, `list_active`, `list_archived`, `list_all` ve `get_archive_summary` davranislarinin birlikte tutarli calismasi testle sabitlendi.
- Arsivleme ve restore islemlerinin kayit silmedigi, toplam listeyi korudugu ve `status` alanini otomatik degistirmedigi dogrulandi.
- Aktif, arsivlenmis ve toplam kayit sayilarinin `get_archive_summary()` ile listeleme davranislariyla uyumlu kalmasi proje karari olarak netlestirildi.
- JSON, SQLite, API, GUI, CLI, otomatik history, workflow, silme mantigi ve buyuk refactor eklenmedi.

## 061 NotebookLM Podcast Notu Adim 056-060

- Adim 056-060 araligi icin final NotebookLM podcast notu hazirlandi.
- Bu not NCR arsiv ozeti, arsivlenmis kayit listesi, aktif kayit listesi, tum kayit listesi ve arsiv/listeleme butunluk kontrolunu tek anlatimda toplar.
- Bu adim sadece dokumantasyon ve podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, JSON, SQLite, API, GUI, CLI ve workflow davranisi degistirilmedi.

## 062 NCR Arsiv / Listeleme Kullanim Ozeti

- Adim 056-060 arasinda netlesen NCR arsivleme ve listeleme davranislari icin kisa kullanim ozeti hazirlandi.
- `archive`, `restore`, `list_active`, `list_archived`, `list_all` ve `get_archive_summary` davranislarinin nasil birlikte kullanilacagi dokumante edildi.
- `is_archived` alaninin gorunurluk/arsiv durumunu, `status` alaninin ise is sureci durumunu temsil ettigi ayrim vurgulandi.
- Bu adim sadece dokumantasyon / kullanim ozeti adimidir.
- Uygulama kodu, test dosyalari, JSON, SQLite, API, GUI, CLI ve workflow davranisi degistirilmedi.

## 063 NCR Kayit Arama Plani

- NCR kayit arama ve filtreleme davranislari icin plan dokumani hazirlandi.
- Bu adimda yeni repository methodu eklenmedi.
- Mevcut arama/filtreleme davranislari varsa tekrar yazilmadan, sonraki adimlarda test ve dokumantasyonla netlestirilmesi kararlastirildi.
- Arama davranislarinin read-only kalmasi, kayit silmemesi ve arsiv gorunurlugunu acik method adi veya parametreyle ifade etmesi ilke olarak belirlendi.
- Uygulama kodu, test dosyalari, JSON, SQLite, API, GUI, CLI, query engine ve workflow davranisi degistirilmedi.

## 064 NonconformityRepository Id Ile Kayit Bulma

- Mevcut `NonconformityRepository.find_by_id()` davranisi Adim 064 kapsami icin netlestirildi.
- Bu davranis aktif, arsivlenmis ve restore edilmis NCR kayitlarini id ile bulacak.
- Eslesen kayit yoksa `None` dondurulmesi karari korundu.
- Id ile arama tum kayit hafizasi uzerinde calisacak; arsivlenmis kayitlar dislanmayacak.
- Bu davranis read-only kalacak; kayit silme, `status` degisimi, `is_archived` degisimi, otomatik history ve workflow olusturmayacak.
- Uygulama kodu, JSON, SQLite, API, GUI, CLI, query engine ve buyuk refactor eklenmedi.

## 065 NonconformityRepository Duruma Gore Filtreleme

- Mevcut `NonconformityRepository.list_by_status(status)` davranisi Adim 065 kapsami icin netlestirildi.
- `filter_by_status(status)` adinda ikinci bir method eklenmedi; mevcut adlandirma korundu.
- Status filtresinin tum kayit hafizasi uzerinde calisacagi ve arsivlenmis kayitlari varsayilan olarak dislamayacagi netlestirildi.
- Eslesen kayit yoksa veya repository bos ise bos liste dondurulmesi karari korundu.
- Bu davranis read-only kalacak; kayit silme, `status` degisimi, `is_archived` degisimi, otomatik history ve workflow olusturmayacak.
- Uygulama kodu, JSON, SQLite, API, GUI, CLI, query engine ve buyuk refactor eklenmedi.

## 066 NonconformityRepository Konuma Gore Filtreleme

- `NonconformityRepository.list_by_location(location)` davranisi eklendi.
- Konum filtresinin tum kayit hafizasi uzerinde calisacagi ve arsivlenmis kayitlari varsayilan olarak dislamayacagi netlestirildi.
- Eslesen kayit yoksa veya repository bos ise bos liste dondurulmesi karari belirlendi.
- Bu davranis read-only kalacak; kayit silme, `location` degisimi, `status` degisimi, `is_archived` degisimi, otomatik history ve workflow olusturmayacak.
- JSON, SQLite, API, GUI, CLI, query engine ve buyuk refactor eklenmedi.

## 067 Dosya ve Video Eki Plani

- Fotoğraf, video, PDF, belge, ses notu ve diger dosya ekleri icin ortak attachment yaklasimi planlandi.
- Video dosyalarinin veritabanina gomulmemesi; dosya yolu / referansi ve metadata bilgisinin tutulmasi karar olarak netlestirildi.
- Mevcut `AttachmentRecord` yaklasiminin ileride `FileAttachmentRecord` veya genisletilmis attachment modeli olarak surdurulebilecegi belirtildi.
- Ilk asamada video oynatma, sikistirma, thumbnail uretme, streaming, medya isleme, dosya yukleme, JSON, SQLite, API, GUI ve CLI eklenmeyecek.
- Bu adim sadece plan dokumantasyonu adimidir; uygulama kodu ve test dosyalari degistirilmedi.

## 068 FileAttachmentRecord Veri Modeli

- `FileAttachmentRecord` veri modeli eklendi.
- Model fotograf, video, PDF, belge, ses notu ve diger dosya ekleri icin dosya metadata ve referans bilgisini temsil edecek.
- Video dosyasi icerigi modele gomulmeyecek; `file_name`, `file_path`, `file_type`, `mime_type`, `file_size` gibi bilgiler tutulacak.
- Iliskili kayit baglantisi `related_record_type` ve `related_record_id` alanlariyla temsil edilecek.
- Repository, dosya yukleme, fiziksel dosya kopyalama, video oynatma, thumbnail uretme, JSON, SQLite, API, GUI, CLI ve persistence davranisi eklenmedi.

## 069 FileAttachmentRecord Dosya Tipi Siniflandirmasi

- `FileAttachmentRecord.file_type` icin temel kullanim siniflari `image`, `video`, `pdf`, `document`, `audio` ve `other` olarak dokumante edildi.
- Bu adimda enum, validation veya hata firlatma davranisi eklenmedi.
- Dosya tipi siniflandirmasinin model icinde metadata olarak tutulacagi netlestirildi.
- `mime_type` alaninin teknik dosya turunu, `file_type` alaninin ise proje icindeki sade sinifi temsil ettigi ayrim vurgulandi.
- Model alani degistirilmedi; repository, dosya yukleme, video oynatma, thumbnail uretme, JSON, SQLite, API, GUI ve CLI eklenmedi.

## 070 FileAttachmentRecord Iliskili Kayit Baglantisi

- `FileAttachmentRecord.related_record_type` ve `related_record_id` alanlarinin kullanim mantigi dokumante edildi.
- Dosya eklerinin ana kaydi degistirmeden veya silmeden, string tabanli basit iliski bilgisiyle ana kayda baglanacagi netlestirildi.
- Bir ana kayda birden fazla dosya eki baglanabilecegi ve ayni dosya tipinin birden fazla kez kullanilabilecegi belirtildi.
- Bu adimda foreign key, ORM relation, SQLite, JSON persistence, API, GUI, CLI, repository ve dosya yukleme davranisi eklenmedi.
- Uygulama kodu ve test dosyalari degistirilmedi.

## 071 NotebookLM Podcast Notu Adim 061-070

- Adim 061-070 araligi icin final NotebookLM podcast notu hazirlandi.
- Bu not NCR arsiv/listeleme kullanim ozetinden arama/filtreleme davranislarina ve dosya/video eki metadata altyapisina gecisi tek anlatimda toplar.
- Video dosyalarinin veritabanina gomulmeyecegi; dosya yolu/referansi ve metadata tutulacagi karar anlatimi icinde vurgulandi.
- Bu adim sadece dokumantasyon ve podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, video oynatma, thumbnail, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 072 FileAttachmentRecord Kullanim Akisi

- `FileAttachmentRecord` icin dosya eki kullanim akisi dokumante edildi.
- Dosya eklerinin ana kayitla `related_record_type` ve `related_record_id` alanlari uzerinden iliskilendirilecegi tekrar netlestirildi.
- Modelin dosya icerigini degil, dosya yolu/referansi ve metadata bilgisini tutacagi karar olarak korundu.
- Fotograf, video, PDF, belge, ses notu, malzeme teslim irsaliyesi ve is guvenligi gozlemi gibi kullanim senaryolari aciklandi.
- Bu adim sadece dokumantasyon / kullanim akisi adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, fiziksel dosya kopyalama, video oynatma, thumbnail, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 073 FileAttachmentRecord Ornek Kullanim Senaryolari

- `FileAttachmentRecord` icin santiye kayit turlerine gore ornek kullanim senaryolari dokumante edildi.
- Beton dokumu, uygunsuzluk / NCR, malzeme teslimi, gunluk saha kaydi, iscilik / ekip kaydi, santiye sefi ozel notu ve denetim / kontrol kaydi senaryolari aciklandi.
- Dosyalarin veritabanina gomulmeyecegi; dosya referansi ve metadata bilgisinin tutulacagi karar tekrar korundu.
- Buyuk video dosyalarinin sistem icinde blob olarak saklanmayacagi vurgulandi.
- Bu adim sadece dokumantasyon ve ornek kullanim senaryosu adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, thumbnail, video oynatma, streaming, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 074 FileAttachmentRecord Saklama ve Adlandirma Standardi

- `FileAttachmentRecord` ile temsil edilen dosya ekleri icin saklama klasor yapisi ve dosya adlandirma standardi dokumante edildi.
- Dosyanin veritabanina gomulmeyecegi; klasor, sunucu veya bulut ortaminda tutulacagi karar tekrar korundu.
- Dosya yolunun proje, kayit turu, tarih ve kayit id bilgisiyle okunabilir olmasi hedeflendi.
- Dosya adi icin once `YYYYMMDD_HHMMSS__record_type__record_id__file_type__sequence.ext` sablonu onerildi; Adim 085 ile yeni canonical path standardi `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}` olarak kilitlendi.
- Orijinal dosya adinin ileride metadata olarak saklanabilecegi, fakat sistem kimligi olarak kullanilmayacagi belirtildi.
- Video dosyalari icin thumbnail, duration, resolution ve codec gibi bilgilerin ileride ayri metadata olarak degerlendirilebilecegi; bu adimda medya isleme eklenmeyecegi netlestirildi.
- Bu adim sadece dokumantasyon standardi adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, thumbnail, video oynatma, preview, streaming, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 075 FileAttachmentRecord Arsiv Guvenligi ve Silme / Tasima Kararlari

- `FileAttachmentRecord` ekleri icin silme, tasima, kayip dosya, arsiv guvenligi ve denetim izi karar dokumantasyonu hazirlandi.
- Kalici silme yerine ileride kontrollu arsiv disi birakma / soft-delete yaklasiminin degerlendirilmesi kararlastirildi.
- Fiziksel dosya bulunamazsa bunun `missing file reference` olarak arşiv bütünlüğü uyarısı seklinde ele alinabilecegi belirtildi.
- Dosya tasinmasi halinde `file_path` veya `storage_reference` bilgisinin guncellenmesi ve tasima gecmisinin ileride loglanmasi gerektigi netlestirildi.
- Arsiv dosyalarinin uzerine yazilmasi yerine yeni versiyonun yeni dosya eki olarak tutulmasi daha guvenli yaklasim olarak belirlendi.
- Dosya ekleme, tasima, pasife alma ve silme olaylari icin ileride `AttachmentEventRecord` benzeri denetim izi modeli degerlendirilebilir.
- Bu adim sadece karar dokumantasyonu adimidir.
- Uygulama kodu, test dosyalari, yeni model, repository, dosya yukleme/silme/tasima/kopyalama, SQLite, JSON persistence, API, GUI, CLI, thumbnail, preview, streaming ve video oynatma degistirilmedi.

## 076 FileAttachmentRecord original_file_name Alani

- `FileAttachmentRecord` modeline opsiyonel `original_file_name` alani eklendi.
- Bu alan sistem tarafindan standartlastirilmis `file_name` degerinden ayri olarak, kullanicinin yukledigi dosyanin orijinal adini metadata olarak saklamak icin kullanilacak.
- `original_file_name` verilmezse varsayilan deger `None` olacak.
- Bu adimda dosya adi standartlastirma fonksiyonu, dosya yukleme sistemi, fiziksel dosya kopyalama/silme/tasima, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 077 FileAttachmentRecord uploaded_by Alani

- `FileAttachmentRecord.uploaded_by` alani opsiyonel string metadata olarak netlestirildi.
- Bu alan dosya ekinin kim tarafindan sisteme eklendigini saklamak icin kullanilacak.
- Kullanici modeli, rol sistemi veya yetkilendirme kurulmadan once `uploaded_by` sade bir metin alani olarak tutulacak.
- `uploaded_by` verilmezse varsayilan deger `None` olacak.
- Bu adimda kullanici modeli, rol/yetki sistemi, authentication, authorization, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 078 FileAttachmentRecord uploaded_at Alani

- `FileAttachmentRecord.uploaded_at` alani opsiyonel string metadata olarak netlestirildi.
- Bu alan dosya ekinin sisteme ne zaman eklendigini saklamak icin kullanilacak.
- Otomatik tarih uretimi, datetime parsing veya tarih formatlama davranisi bu adimda eklenmeyecek.
- `uploaded_by` ve `uploaded_at` birlikte dosya eki icin basit denetim izi baslangici saglayacak.
- `uploaded_at` verilmezse varsayilan deger `None` olacak.
- Bu adimda kullanici modeli, rol/yetki sistemi, authentication, authorization, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 079 FileAttachmentRecord notes Alani

- `FileAttachmentRecord.notes` alaninin dosya eki ozelindeki kullanim amaci netlestirildi.
- `notes` alaninin fotograf, video, PDF, belge veya ses ekleri icin kisa aciklama, saha baglami, uyari veya ek bilgi tutmak icin kullanilacagi belirtildi.
- `notes` alaninin dosya adi, dosya yolu, dosya tipi veya iliskili kayit bilgisi yerine gecmeyecegi kararlastirildi.
- `notes` verilmezse varsayilan deger `None` olarak kalacak.
- Bu adimda model alani degistirilmedi; dosya yukleme, fiziksel dosya kopyalama/silme/tasima, not arama/filtreleme, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 080 FileAttachmentRecord Metadata Butunluk Ozeti

- Adim 072-079 arasindaki `FileAttachmentRecord` / dosya eki hatti derin analiz oncesi kapanis dokumaniyla ozetlendi.
- Kullanim akisi, ornek kullanim senaryolari, saklama ve adlandirma standardi, arsiv guvenligi kararları ve metadata alanlari tek dokumanda toplandi.
- Gercek modelde bulunan `file_name`, `file_path`, `file_type`, `mime_type`, `file_size`, `related_record_type`, `related_record_id`, `uploaded_by`, `uploaded_at`, `original_file_name`, `description` ve `notes` alanlarinin anlamlari aciklandi.
- `storage_reference` gibi gercek modelde bulunmayan kavramlar ileride degerlendirilecek metadata olarak ayrildi.
- Video dosyalarinin veritabanina gomulmeyecegi; dosya yolu / referans ve metadata ile izlenecegi karar tekrar vurgulandi.
- Bu adim sadece kapanis dokumantasyonu adimidir.
- Uygulama kodu, test dosyalari, yeni model alani, repository, persistence, SQLite, JSON, API, GUI, CLI, dosya yukleme/kopyalama/silme/tasima, thumbnail, preview, video oynatma ve streaming degistirilmedi.

## 081 README Guncellik Karari

- `README.md` dosyasinin Adim 080 guvenli noktasindaki gercek repo durumunu yansitacak sekilde guncellenmesine karar verildi.
- README icinde projenin domain model, bellek ici repository, test, dokumantasyon, learning ve podcast notlari cekirdegi seviyesinde oldugu aciklandi.
- Guncel test sonucu `125 passed` olarak yazildi.
- Database, gercek upload servisi, API, GUI, auth, deployment ve CI gibi ozelliklerin henuz bulunmadigi acikca belirtildi.
- Bu adimda uygulama kodu ve test dosyalari degistirilmedi.

## 082 ROADMAP Guncellik Karari

- `ROADMAP.md` dosyasinin Adim 080 guvenli noktasi ve Adim 081 README duzeltmesi sonrasindaki gercek proje durumuna gore guncellenmesine karar verildi.
- Adim 001-080 arasindaki ana fazlar uzun ayrinti yerine okunabilir ozetler halinde duzenlendi.
- Adim 081 README duzeltmesi ve Adim 082 ROADMAP guncellemesi tamamlanmis duzeltme adimlari olarak islendi.
- Adim 083-090 araligi duzeltme, standart kilitleme ve dokumantasyon esitleme fazi olarak belirlendi.
- Adim 091-100 araligi persistence, upload, integrity, audit ve CI omurgasi fazi olarak planlandi.
- Database, gercek upload servisi, API, GUI, auth, CI ve deployment ozelliklerinin henuz bulunmadigi roadmap icinde acikca belirtildi.
- Bu adimda uygulama kodu ve test dosyalari degistirilmedi.

## 083 Attachment Model Karari

- Yeni dosya eki hatti icin ana metadata modelinin `FileAttachmentRecord` olmasina karar verildi.
- `AttachmentRecord`, onceki genel ek dosya referans modeli olarak korunacak ve legacy / onceki model olarak degerlendirilecek.
- `AttachmentRecord` bu adimda silinmedi; cunku mevcut testler, Adim 008 ve Adim 026 dokumantasyonu bu modeli referans almaya devam ediyor.
- Yeni upload servisi, integrity scanner, dosya tipi standardi ve iliskili kayit baglantisi calismalari `FileAttachmentRecord` uzerinden ilerleyecek.
- Bu adimda model alanlari degistirilmedi, veri migrasyonu yapilmadi ve kirici refactor uygulanmadi.
- Gercek upload servisi, database, API, GUI, auth, CI ve deployment henuz eklenmedi.

## 084 FileAttachmentRecord Alan Sozlesmesi

- `FileAttachmentRecord.uploaded_by` ve `uploaded_at` alanlarinin model seviyesinde opsiyonel kalmasina karar verildi.
- Bu karar, henuz auth / kullanici sistemi ve gercek upload servisi bulunmadigi icin alindi.
- Ileride upload servisi eklendiginde `uploaded_by` servis seviyesinde zorunlu tutulabilir.
- Ileride upload servisi eklendiginde `uploaded_at` servis tarafindan otomatik uretilebilir.
- Model, servis tarafindan saglanan upload metadata gecmisini tasimaya devam edecek.
- Model-level optional ile service-level required ayrimi bilincli olarak dokumante edildi.
- Bu adimda model alani eklenmedi veya silinmedi; test dosyalari degistirilmedi.

## 085 Canonical Attachment Path Standardi

- Yeni dosya eki metadata ve ilerideki upload hatti icin canonical path standardi `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}` olarak belirlendi.
- `record_type` degerinin kucuk harfli, makine-dostu ve tutarli olmasina karar verildi.
- Tarih klasorleri `yyyy/mm/dd` formatinda tutulacak.
- `safe_file_name`, sanitize edilmis ve dosya sistemi icin guvenli hale getirilmis dosya adi anlamina gelecek.
- Physical file storage ile `FileAttachmentRecord.file_path` metadata alani ayni path standardini referans alacak.
- Bu adimda path helper fonksiyonu, gercek upload servisi, fiziksel dosya tasima/kopyalama/silme, database, API veya GUI eklenmedi.

## 086 File Type / Attachment Status Enum Hazirligi

- `FileAttachmentRecord.file_type` icin canonical deger sozlugu olarak `FileType` enumu eklendi.
- Ileride attachment yasam dongusu ve integrity kontrolleri icin `AttachmentStatus` enumu eklendi.
- `FileAttachmentRecord.file_type` alani string olarak kalmaya devam edecek; bu adimda zorunlu enum donusumu yapilmadi.
- `FileAttachmentRecord` icine yeni `status` alani eklenmedi; `AttachmentStatus` ilerideki attachment lifecycle davranislari icin hazirliktir.
- Gecersiz deger validation davranisi bu adimda eklenmedi; Adim 087 ve sonrasi icin zemin hazirlandi.
- Upload service ve integrity scanner ileride bu enumlari canonical vocabulary olarak kullanabilir.

## 087 FileAttachmentRecord Validation Karari

- `FileAttachmentRecord` icin minimal `__post_init__` validation davranisi eklendi.
- `attachment_id`, `related_record_type`, `related_record_id`, `file_name` ve `file_path` bos string olamayacak.
- `file_type` degeri `FileType` enumundaki canonical degerlerden biri olmak zorunda olacak.
- `file_size` negatif olamayacak.
- `uploaded_by` ve `uploaded_at` alanlari opsiyonel kalmaya devam edecek.
- `FileAttachmentRecord` icine `status` alani eklenmedi.
- Bu adimda path helper, upload service, fiziksel dosya islemi, database, API, GUI, auth, CI veya deployment eklenmedi.

## 088 Attachment Path Helper Karari

- Canonical attachment path standardini koda baglamak icin `build_attachment_path` helper fonksiyonu eklendi.
- Helper `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}` formatinda path string uretir.
- `uploaded_at` degeri string, `date` veya `datetime` olarak kabul edilir.
- `file_name` bas/son bosluklardan temizlenir ve klasor ayiricilar guvenli hale getirilir.
- Helper fiziksel dosya olusturmaz, dosya kopyalamaz, metadata kaydi olusturmaz.
- Bu adimda upload service, database, API, GUI, auth, CI veya deployment eklenmedi.

## 089 Attachment Metadata Integrity Kurallari

- Ileride gelistirilecek missing/orphan scanner icin attachment metadata butunluk durumlari dokumante edildi.
- Scanner tasarimi icin `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` durum kodlari belirlendi.
- Scanner raporunda `status_code`, attachment reference, beklenen path, mevcut path, dosya/metadata varligi, severity, onerilen aksiyon ve kontrol zamani gibi alanlar yer alacak.
- Backup restore, upload service ve audit event hatlariyla iliski karar duzeyinde aciklandi.
- Bu adimda uygulama kodu, test dosyalari, scanner implementasyonu, dosya sistemi taramasi, upload service, database, API, GUI, auth, CI veya deployment eklenmedi.

## 090 Attachment Integrity Status Sabitleri

- Adim 089'da dokumante edilen attachment metadata butunluk durumlari kod tarafinda merkezi sabitlere donusturuldu.
- `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` status kodlari ortak sozluk olarak tanimlandi.
- Tum status kodlari, hata status kodlari ve uyari status kodlari icin immutable `frozenset` koleksiyonlari kullanilacak.
- `MISSING_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` hata; `ORPHAN_FILE` uyari; `OK` sorun yok durumu olarak ayrildi.
- Bu adimda scanner, dosya sistemi taramasi, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 091 Attachment Integrity Result Modeli

- Ileride scanner tarafindan uretilecek tekil attachment butunluk kontrol sonucu icin `AttachmentIntegrityResult` modeli eklendi.
- Result modeli `status_code`, `severity`, attachment reference, path bilgileri, metadata/dosya varligi, onerilen aksiyon, kontrol zamani ve not alanlarini tasir.
- `status_code` degeri merkezi attachment integrity status sabitlerinden biri olmak zorundadir.
- `severity` degeri `OK`, `WARNING` veya `ERROR` olmak zorundadir.
- `checked_at` verilmezse UTC zaman atanir.
- Bu adimda scanner, dosya sistemi taramasi, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 092 Attachment Integrity Single Record Helper

- Tekil metadata ve dosya varligi bilgilerinden `AttachmentIntegrityResult` ureten `build_attachment_integrity_result` helper fonksiyonu eklendi.
- Helper toplu scanner degildir; yalnizca kendisine verilen boolean ve path bilgileri uzerinden karar verir.
- Karar sirasi `DUPLICATE_METADATA`, `INVALID_PATH`, `MISSING_FILE` / `ORPHAN_FILE`, `UNREADABLE_FILE`, `OK` olarak belirlendi.
- Her hata veya uyari durumu icin makine-dostu `recommended_action` degeri uretilecek.
- Metadata ve dosya birlikte yoksa anlamli scanner sonucu olmadigi icin `ValueError` ile reddedilecek.
- Bu adimda dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 093 Attachment Integrity Report Summary Modeli

- Tekil `AttachmentIntegrityResult` listesinden ust rapor ozeti uretmek icin `AttachmentIntegrityReportSummary` modeli eklendi.
- `build_attachment_integrity_report_summary` helper fonksiyonu eldeki result listesini status ve severity alanlarina gore sayar.
- Bos result listesi tum sayaclari 0 olan ve UTC `generated_at` alanina sahip bir summary uretir.
- Summary sayaclari negatif olamaz; `total_checked` status ve severity sayimlariyla uyumlu olmak zorundadir.
- Bu adimda toplu scanner, dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 094 Attachment Integrity Report Modeli

- Tekil result listesi ile summary bilgisini birlikte tasimak icin `AttachmentIntegrityReport` modeli eklendi.
- Report modeli `results`, `summary`, `generated_at`, `source` ve `notes` alanlarini tasir.
- `results` disaridan liste olarak verilse bile model icinde tuple olarak saklanir.
- `summary.total_checked`, `len(results)` ile uyumlu olmak zorundadir.
- `generated_at` verilmezse UTC zaman atanir; report ve summary zamanlari timezone-aware UTC olmak zorundadir.
- `build_attachment_integrity_report` helper fonksiyonu result listesinden summary uretip report dondurur.
- Bu adimda toplu scanner, dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 095 Attachment Integrity Report Serializer

- `AttachmentIntegrityResult`, `AttachmentIntegrityReportSummary` ve `AttachmentIntegrityReport` modellerini dictionary formatina cevirmek icin serializer helper fonksiyonlari eklendi.
- `checked_at` ve `generated_at` gibi datetime alanlari ISO 8601 string olarak serialize edilecek.
- `None` alanlari dict icinde korunacak; bu adimda bos alanlar ciktidan atilmayacak.
- Report serializer nested result listesini result dict listesine ve summary bilgisini summary dict yapisina cevirir.
- Serializer fonksiyonlari orijinal dataclass/model nesnelerini degistirmez.
- Bu adimda JSON dosyasi yazma, `json.dump`, scanner, dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 096 Ana Proje Ilkeleri ve Veri Politikasi Kararlari

- CSE icin ana proje ilkeleri dokumante edildi: once veri omurgasi, sonra otomasyon, en son AI; kucuk ve guvenilir saha hafizasi; resmi kayit ve ozel alan ayrimi.
- Resmi proje kayitlarinin fiziksel olarak silinmemesi karar olarak netlestirildi.
- NCR, tutanak, kalite kontrol, attachment metadata, audit event, fotograf/video metadata ve proje kararlari gibi kanit niteligindeki resmi kayitlarda hard delete yerine arsivleme, hukumden dusurme, revizyon veya superseded yaklasimi kullanilacak.
- Santiye Sefi Ozel Alani kisisel calisma alani olarak tanimlandi ve resmi proje kayitlarindan izole tutulmasina karar verildi.
- Yeni santiye sefinin eski santiye sefinin private workspace alanina erisemeyecegi; devir icin gerekli bilgilerin explicit handover package veya official record olarak hazirlanmasi gerektigi dokumante edildi.
- Ozel alan verileri icin ileride kullanici bazli encryption key ve crypto-shredding yaklasimi degerlendirilecek.
- Bu adimda uygulama kodu, test dosyalari, database migration, encryption, auth/permission, scanner, upload service, backup/restore implementasyonu, push veya ZIP staging yapilmadi.

## 097 NotebookLM Podcast Notu 071-080

- Adim 071-080 arasindaki `FileAttachmentRecord` metadata hatti icin final NotebookLM podcast notu olusturuldu.
- Podcast notu kullanim akisi, ornek saha senaryolari, saklama/adlandirma standardi, arsiv guvenligi, metadata alanlari ve Adim 080 guvenli kapanis noktasini birlikte ozetler.
- Bu adim sadece dokumantasyon/podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, upload service, scanner, JSON dosyasi yazma, API, GUI, auth, CI veya deployment degistirilmedi.

## 098 NotebookLM Podcast Notu 081-090

- Adim 081-090 arasindaki duzeltme, standart kilitleme ve attachment integrity hazirlik hatti icin final NotebookLM podcast notu olusturuldu.
- Podcast notu README/ROADMAP guncellemesi, canonical attachment model karari, field contract, path standardi, enum hazirligi, validation, path helper, metadata integrity kurallari ve status sabitlerini birlikte ozetler.
- Bu adim sadece dokumantasyon/podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 099 NotebookLM Podcast Notu 091-096

- Adim 091-096 arasindaki attachment integrity raporlama omurgasi ve CSE veri koruma / ozel alan politikasi icin final NotebookLM podcast notu olusturuldu.
- Podcast notu `AttachmentIntegrityResult`, single-record helper, report summary, report modeli, serializer fonksiyonlari, resmi kayit silmeme karari, Santiye Sefi Ozel Alani izolasyonu ve explicit handover package yaklasimini birlikte ozetler.
- Bu adim sadece dokumantasyon/podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 100 Guvenli Nokta Final Kalite Kontrol

- Adim 081-099 arasindaki calismalar icin push oncesi final kalite kontrol dokumani olusturuldu.
- Branch durumu, son commit, `origin/master` farki, kritik podcast/politika/integrity dosyalarinin varligi ve pytest sonucu dokumante edildi.
- `chief-site-engineer_adim_080_guvenli_nokta.zip` dosyasinin untracked ve kapsam disi kalmasi karari korundu.
- Bu adim yeni ozellik gelistirme degildir; yalnizca dogrulama, guvenli nokta dokumantasyonu ve push hazirligi adimidir.
- Uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 101 Genel Proje Denetimi ve Mimari Saglik Raporu

- Adim 100 guvenli noktasindan sonra tum proje genel kalite, mimari tutarlilik, dokumantasyon butunlugu, test kapsami, roadmap uyumu ve sonraki gelistirme yonu acisindan denetlendi.
- Denetim sonucunda attachment integrity hattinin scanner oncesi iyi hazirlandigi, veri koruma / resmi kayit / ozel alan politikasinin guclu dokumante edildigi ve testlerin temiz calistigi kaydedildi.
- README dosyasinin Adim 080 / `125 passed` bilgisinde kaldigi ve Adim 100 / `191 passed` durumuna gore guncellenmesi gerektigi tespit edildi.
- `app/models.py`, `tests/test_models.py` ve `tests/test_records.py` icin buyume riski; attachment scanner icin erken karmasiklik riski; private workspace / official record ayrimi icin model ve test ihtiyaci takip maddesi olarak belirlendi.
- Bu adim yeni ozellik gelistirme degildir; uygulama kodu ve test dosyalari degistirilmeden yalnizca denetim raporu ve gerekli dokumantasyon kayitlari olusturuldu.

## 102 README Guncellik Duzeltmesi

- `README.md` dosyasinin Adim 100 guvenli noktasi, `191 passed` test sonucu ve Adim 101 genel denetim bulgularina gore guncellenmesine karar verildi.
- Eski Adim 080 / `125 passed` bilgileri README'den kaldirildi.
- README icinde attachment integrity hatti, CSE politika dokumanlari, podcast notlari, Adim 101 denetim takip maddeleri ve sonraki teknik yonler ozetlendi.
- Bu adim sadece dokumantasyon guncelligi adimidir; uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 103 Attachment Integrity JSON Export Baslangici

- `AttachmentIntegrityReport` nesnesini dosyaya yazmadan JSON string formatina donusturen `export_attachment_integrity_report_to_json` helper fonksiyonu eklendi.
- Helper mevcut `serialize_attachment_integrity_report` ciktisini kullanir ve `json.dumps` ile JSON string uretir.
- `ensure_ascii=False` kullanilarak Turkce karakterlerin okunabilir kalmasi kararlastirildi.
- `indent` varsayilan olarak `2` olacak; `indent=None` kompakt JSON uretmek icin kullanilabilecek.
- Bu adimda JSON dosyasi yazma, path alma, klasor olusturma, scanner, dosya sistemi taramasi, upload service, backup/restore veya audit event implementasyonu eklenmedi.

## 104 Attachment Integrity JSON File Export Tasarimi

- Adim 103'te eklenen JSON string export helper'dan sonra ileride guvenli JSON file export davranisi icin tasarim kurallari dokumante edildi.
- File export icin UTF-8 encoding, `ensure_ascii=False`, varsayilan `indent=2`, UTC timestamp'li dosya adi, acik export path, overwrite politikasi, atomic write ve JSON dogrulama beklentileri belirlendi.
- Varsayilan overwrite davranisinin `False` olmasi; ayni dosya varsa hata verilmesi; `overwrite=True` kullaniminin acik karar ve ileride audit event ile iliskilendirilmesi kararlastirildi.
- Export dosyasinin resmi kayit yerine gecmeyecegi, resmi kayitlarin snapshot ciktisi olarak degerlendirilecegi belirtildi.
- Bu adimda uygulama kodu, test dosyalari, JSON dosyasi yazma, scanner, backup/restore, audit event, private workspace exportu, API, GUI veya CLI eklenmedi.

## 105 Attachment Integrity JSON File Export Helper

- `AttachmentIntegrityReport` nesnesini verilen JSON dosya yoluna yazan `export_attachment_integrity_report_to_json_file` helper fonksiyonu eklendi.
- Helper mevcut `export_attachment_integrity_report_to_json` fonksiyonunu kullanir ve dosyayi UTF-8 encoding ile yazar.
- Varsayilan `overwrite=False` olarak belirlendi; hedef dosya varsa `FileExistsError` verilecek.
- `overwrite=True` acikca verilirse mevcut dosyanin uzerine yazilabilecek.
- Parent klasor yoksa otomatik klasor olusturulmayacak ve `FileNotFoundError` verilecek.
- Testlerde yalnizca pytest `tmp_path` kullanildi; gercek proje klasorune test dosyasi yazilmadi.
- Bu adimda scanner, klasor taramasi, backup/restore, audit event, upload service, API, GUI veya CLI eklenmedi.

## 106 CSE Urun Vizyonu ve Saha Hafizasi Stratejisi

- CSE'nin ilk rakibi buyuk insaat yonetim platformlari degil; WhatsApp gruplari, telefon galerisi, Excel listeleri, klasor karmasasi, defter notlari, mail ekleri ve "ben bunu bir yere yazmistim" duzenidir.
- CSE'nin amaci daha fazla modul eklemek degil; santiye sefinin kayit, takip, kanit, arsiv ve hatirlama problemini sade sekilde cozmektir.
- CSE once tarih, konum, kategori, fotograf/dosya, sorumlu kisi, durum, kapanis kaniti, audit/gecmis ve iliskilerden olusan guvenilir veri omurgasini kurar.
- AI ilk katman degildir; dogru kayit, guvenilir arsiv, iliskili veri ve aranabilir saha hafizasi uzerine daha sonra gelecek deger artirici katmandir.
- Gercek santiye kullanimi urun kararlarini yonlendirecek; her yeni ozellik gercek problem, kucuk arac, sahada test, duzeltme ve tekrar test dongusunden gecmelidir.
- Sahada kayit acma suresi 20-30 saniyeyi gecmemelidir.
- Yeni ozellik filtresi: Bu ozellik santiye sefinin sahada unutmamasini, kanitlamasini, takip etmesini, raporlamasini veya daha sonra geri cagirmasini kolaylastiriyor mu?

## 107 Attachment Integrity Scanner Scope Plani

- Attachment integrity scanner once dry-run ve raporlama mantiginda tasarlanacak.
- Ilk asamada dosya silme, dosya tasima, otomatik duzeltme, orphan dosya karantinaya alma veya metadata guncelleme yapilmayacak.
- Scanner yalnizca acikca verilen attachment root siniri icinde calismali; root disina cikan relative path degerleri kabul edilmemelidir.
- Absolute path davranisi ve path traversal riski ayri tasarlanacak; ilk scanner kontrolsuz proje disi path'lere cikmayacak.
- Scanner ciktisi mevcut `AttachmentIntegrityResult` ve `AttachmentIntegrityReport` hatti ile uyumlu olmali.
- Ilk kapsam `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` durumlarini tespit etmeye odaklanir.
- Bu adimda scanner implementasyonu, dosya sistemi taramasi, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 108 Attachment Integrity Scanner Input Modeli Plani

- Scanner input modeli, scanner'a verilecek `FileAttachmentRecord` metadata kayitlarini ve attachment root sinirini tarif edecek.
- Ilk asamada input modeli dosya taramasi, dosya okuma, scanner davranisi veya metadata guncellemesi uretmeyecek.
- `attachment_records` ve `attachment_root` ilk zorunlu aday alanlar olarak dusunulur.
- `include_orphan_check`, `allowed_record_types`, `checked_by`, `source`, `notes` ve `created_at` / `requested_at` opsiyonel aday alanlar olarak degerlendirilecek.
- Orphan check ayri ve riskli bir secenek olarak ele alinacak; acilirsa yalnizca attachment root altinda ve raporlama amaciyla calismalidir.
- Path traversal ve root disi erisim riski ileride test edilmelidir.
- Bu adimda dataclass, scanner helper, dosya sistemi taramasi, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 109 Attachment Scanner Dry-run Helper Baslangici

- Ilk dry-run helper gercek dosya sistemi taramasi yapmayacak.
- File existence bilgisi disaridan kontrollu path -> exists map ile verilecek.
- Helper mevcut `build_attachment_integrity_result` hattini kullanarak her `FileAttachmentRecord` icin `AttachmentIntegrityResult` uretecek.
- Map icinde path bulunmazsa kayit guvenli sekilde missing file olarak degerlendirilecek.
- Orphan, duplicate metadata, unreadable file, invalid path ve root disi path kontrolleri bu adimda yapilmayacak.
- Bu ayrim ileride scanner input modeli, root/path guvenligi ve orphan scan adimlarini daha guvenli ele almak icin korunacak.
- Bu adimda klasor traversal, dosya silme/tasima/kopyalama, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 110 Scanner Dry-run Testleri ve Kullanim Netlestirmesi

- Dry-run helper map tabanli ve gercek dosya sistemi kullanmayan yapi olarak kalacak.
- Duplicate path bu adimda hata sayilmayacak; duplicate metadata tespiti ayri adim konusudur.
- Map icinde fazla path bulunmasi orphan scan anlamina gelmez ve helper tarafindan yok sayilir.
- Path eslesmesi birebir map lookup uzerinden yapilir; benzer path degerleri eslesmis sayilmaz.
- Sonuc sirasi input record sirasi ile ayni kalmalidir.
- Root/path security ve orphan scan daha sonra ayri kapsamda ele alinacaktir.
- Bu adimda helper kapsam genisletilmedi; gercek dosya sistemi taramasi, klasor traversal, dosya silme/tasima/kopyalama, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 111 Attachment Integrity Rapor Kullanim Ozeti

- Attachment integrity hatti metadata -> dry-run result -> report -> serializer -> JSON export akisi olarak okunacak.
- `AttachmentIntegrityReport` resmi kayit yerine gecmez; mevcut attachment kayitlari icin butunluk kontrol ciktisidir.
- JSON export kalici veri deposu degil, rapor/snapshot ciktisidir.
- Dry-run helper dosya sistemi islemi yapmadan guvenli raporlama hatti saglar.
- Audit, backup, root/path security ve orphan scan ayri adimlarda ele alinacaktir.
- Bu adimda uygulama kodu, test dosyalari, scanner davranisi, serializer, JSON export kodu, audit event, backup/restore, database, API, GUI veya CLI degistirilmedi.

## 112 Audit Event Model Plani

- Audit event, kanit degeri tasiyan olaylarin izini tutmak icin planlanir.
- Audit event resmi kayit, JSON export, backup dosyasi veya scanner sonucu degildir.
- Ilk asamada yalnizca model plani yapilir; otomatik audit yazimi, repository veya database yoktur.
- Attachment integrity raporu ve JSON export ileride audit event uretebilecek olaylar olarak degerlendirilebilir.
- Audit event modeli ileride veri silme onleme, backup/restore ve handover package hattina zemin hazirlayacaktir.
- Bu adimda `AuditEventRecord`, audit helper, audit repository, scanner degisikligi, JSON persistence, backup/restore implementasyonu, API, GUI veya CLI eklenmedi.

## 113 AuditEventRecord Baslangic Modeli

- `AuditEventRecord`, izlenebilir audit olaylari icin sade bir dataclass baslangic modeli olarak eklendi.
- Zorunlu alanlar `event_id`, `project_id`, `event_type`, `actor` ve `occurred_at` olarak belirlendi.
- Hedef kayit, gerekce, onceki/yeni deger, kaynak ve not bilgileri opsiyonel metadata alanlari olarak tutuldu.
- Bu model resmi kayit, scanner sonucu, JSON export dosyasi, repository veya otomatik audit mekanizmasi degildir.
- Bu adimda persistence, audit helper, otomatik audit yazimi, database, API, GUI, CLI, scanner entegrasyonu, backup/restore davranisi, commit, push veya ZIP staging eklenmedi.

## 114 AuditEventRecord Validation Testleri

- `AuditEventRecord` zorunlu alanlari runtime validation ile korunur.
- Validation su asamada yalnizca bos string, whitespace-only string ve `None` degerleri engeller.
- Tarih formati, event type enum, target pair tutarliligi ve ozel alan guvenligi sonraki adimlara birakildi.
- Opsiyonel alanlar bu adimda esnek birakildi; bos string veya `None` degerleri reddedilmez.
- Audit event hala persistence veya otomatik audit sistemi degildir.

## 115 Audit Event Type Sozlesmesi

- Audit event type degerleri domain/action biciminde planlandi.
- `event_type` alani serbest aciklama alani degildir.
- Insan tarafindan okunabilir aciklamalar `reason` veya `notes` alaninda tutulacak.
- `old_value` ve `new_value` event type yerine kullanilmayacak.
- Ilk event type listesi dokumantasyon sozlesmesi olarak belirlendi.
- Event type validation ve kod sabitleri sonraki adima birakildi.
- Bu adim documentation-only tutuldu.

## 116 Audit Event Type Sabitleri ve Validation

- Event type sozlesmesi ilk asamada `AUDIT_EVENT_TYPES` tuple degeriyle tutuldu.
- Hizli membership kontrolu icin `AUDIT_EVENT_TYPE_SET` kullanildi.
- Enum tercih edilmedi; bu asamada sade ve geri alinabilir sabit yapi yeterli goruldu.
- `AuditEventRecord.event_type` artik yalnizca desteklenen event type degerlerini kabul eder.
- `event_type is required` ile `event_type is not supported` hata ayrimi korundu.
- Persistence, repository ve otomatik audit uretimi eklenmedi.

## 117 Audit Event Target Record Iliski Kurallari

- Target record iliskisi `target_record_type` ve `target_record_id` ciftiyle temsil edilecek.
- Iki alan birlikte doluysa olay belirli bir kayda baglanir.
- Iki alan birlikte bossa olay genel proje, sistem veya surec olayi olabilir.
- Tek tarafli doluluk ileride validation riski olarak ele alinacak.
- Target record alanlari aciklama, gerekce veya snapshot alani degildir.
- Event type yalnizca olay turunu, target record alanlari ise olayin iliskili oldugu kaydi belirtir.
- Pair validation ve target type sabitleri sonraki adima birakildi.
- Bu adim documentation-only tutuldu.

## 118 Audit Event Target Record Pair Validation

- `target_record_type` ve `target_record_id` alanlari pair olarak ele alinir.
- Iki alan birlikte `None` olabilir.
- Iki alan birlikte dolu olabilir.
- Tek tarafli target record referansi runtime validation ile reddedilir.
- Validation bu adimda yalnizca `None` bazlidir.
- Bos string / whitespace validation ve target type allowed-list sonraki adimlara birakildi.
- Persistence, repository ve otomatik audit uretimi eklenmedi.

## 119 Audit Event Target Record Type Sozlesmesi

- `target_record_type` icin ilk type sozlesmesi dokumante edildi.
- Target type degerleri kucuk harfli, makine tarafindan okunabilir ve sabit sozlesmeye uygun olacak sekilde planlandi.
- Ilk adaylar `project`, `project_record`, `attachment`, `attachment_metadata`, `attachment_integrity_report`, `json_export`, `backup_package`, `restore_operation`, `handover_package`, `audit_event` olarak belirlendi.
- Target record type aciklama, gerekce, snapshot veya ozel alan verisi tasimayacak.
- Allowed-list validation ve sabitlerin implementasyonu sonraki adima birakildi.
- Bu adim documentation-only tutuldu.

## 120 Audit Event Target Record Type Sabitleri ve Validation

- Target record type sozlesmesi `AUDIT_TARGET_RECORD_TYPES` tuple degeriyle koda baglandi.
- Hizli membership kontrolu icin `AUDIT_TARGET_RECORD_TYPE_SET` kullanildi.
- Enum tercih edilmedi; sade ve geri alinabilir sabit yapi yeterli goruldu.
- `AuditEventRecord.target_record_type` artik yalnizca desteklenen degerleri kabul eder.
- Pair validation ile allowed-list validation ayrimi korundu.
- `target_record_id` format validation sonraki adimlara birakildi.
- Persistence, repository ve otomatik audit uretimi eklenmedi.

## 121 Audit Event Target Record ID Format Tasarimi

- `target_record_id` icin ilk format yaklasimi dokumante edildi.
- Onerilen genel bicim `<TYPE_PREFIX>-<YEAR>-<SEQUENCE>` olarak belirlendi.
- Prefix adaylari target record type degerlerine gore tasarlandi.
- Format tasarimi bu adimda koda baglanmadi.
- Prefix validation, gercek model id alanlariyla uyum kontrolunden sonra ele alinacak.
- `target_record_id` aciklama, gerekce, snapshot veya ozel alan verisi tasimayacak.
- Bu adim documentation-only tutuldu.

## 122 Audit Event Target Record ID Validation Tasarimi

- `target_record_id` validation tasarimi iki asamali planlandi.
- Ilk asama genel format validation olabilir.
- Ikinci asama prefix / target type uyumu olabilir.
- Prefix validation gercek model id alanlariyla uyum kontrolunden once kodlanmayacak.
- Geriye donuk uyumluluk riski nedeniyle bu adim documentation-only tutuldu.
- Regex validation ve prefix validation sonraki adimlara birakildi.

## 123 Podcast 017 - Adim 097-102 NotebookLM Podcast Notu

- Podcast notlari hattinin Adim 097-102 araligindan itibaren geriden tamamlanmasina karar verildi.
- Podcast 017, eksik podcast zincirini tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 124 Podcast 018 - Adim 103-108 NotebookLM Podcast Notu

- Podcast notlari hattinda Podcast 018 ile Adim 103-108 araligi tamamlandi.
- Podcast 018, eksik podcast zincirini sirali tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 125 Podcast 019 - Adim 109-114 NotebookLM Podcast Notu

- Podcast notlari hattinda Podcast 019 ile Adim 109-114 araligi tamamlandi.
- Podcast 019, eksik podcast zincirini sirali tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 126 Podcast 020 - Adim 115-120 NotebookLM Podcast Notu

- Podcast notlari hattinda Podcast 020 ile Adim 115-120 araligi tamamlandi.
- Podcast 020, eksik podcast zincirini sirali tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 127 Guvenli Nokta Kalite Kontrol ve Dokumantasyon Temizligi

- Yeni ozellik eklenmeden once README, ROADMAP, CHANGELOG ve kalite kontrol ciktilari guncel tutulacak.
- ZIP dosyalari repo kapsami disinda kalacak; guvenli nokta arsivleri commit/stage kapsaminda olmayacak ve `.gitignore` ile dislanacak.
- Satir sonu ve whitespace gurultusunu azaltmak icin Python, Markdown ve text dosyalarinda LF satir sonu tercih edilecek.
- Guvenli nokta oncesi `python -m pytest` ve `git diff --check` kontrolleri yapilacak.
- Bu adim documentation / cleanup / quality-control adimidir; uygulama kodu, test dosyalari, yeni model, validation, business logic, API, GUI, CLI, commit, push veya ZIP staging eklenmedi.

## 128 FileAttachmentRecord Validation Bosluklari

- `FileAttachmentRecord` icin zorunlu metadata alanlari `None`, bos string ve whitespace durumlarinda kontrollu `ValueError` uretmelidir.
- `mime_type` bos birakilamaz; bu alan dosyanin kanonik metadata sozlesmesinin parcasidir.
- `file_type` once bos/None kontrolunden gecmeli, sonra desteklenen `FileType` degerleriyle karsilastirilmalidir.
- Bu adim yalnizca `FileAttachmentRecord` validation bosluklarini kapatir; `AuditEventRecord`, audit target id format validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## 129 Record ID Envanteri ve Audit Target ID Risk Analizi

- Audit target_record_id format validation, mevcut record ID envanteri ve merkezi ID sozlesmesi netlesmeden uygulanmayacak.
- Mevcut modellerde explicit ID alani olan ve olmayan kayit aileleri birlikte bulunuyor.
- Testlerde lower-case, upper-case, cok parcali prefix, path icine gomulu ID ve opsiyonel `None` baglanti ornekleri birlikte kullaniliyor.
- `target_record_type` ile `target_record_id` prefix eslestirmesi once merkezi bir karar tablosuna baglanmali.
- Bu adim documentation-only / architecture-decision-prep adimidir; uygulama kodu, test dosyalari, `AuditEventRecord`, target id regex validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## 130 Central Record ID Contract Plan

- Merkezi record ID sozlesmesi planlanmadan ve `target_record_type` / ID ailesi mapping'i netlesmeden `AuditEventRecord.target_record_id` hard validation uygulanmayacak.
- ID sozlesmesi once documentation-only olarak tutulacak; sonra constants/mapping helper, test ornek standardizasyonu, soft validation ve en son hard validation sirasi izlenecek.
- `project_record` gibi genis target type degerleri tek prefixe zorlanmayacak; coklu ID ailesi mapping'i ile ele alinacak.
- Explicit ID alani olmayan modeller icin ID stratejisi ayri karar gerektirir.
- Bu adim architecture planning adimidir; uygulama kodu, test dosyalari, helper implementasyonu, regex validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## 131 Record ID Constants and Mapping Helper Plan

- Record ID constants ve `target_record_type` / ID ailesi mapping helper tasarlanmadan `AuditEventRecord.target_record_id` hard validation uygulanmayacak.
- Ilk helper katmani sadece bilgi dondurmeli; model davranisini veya mevcut test orneklerini degistirmemeli.
- Soft validation helper ayri, hard validation helper ayri tasarlanacak; hard validation migration ve test standardizasyonu sonrasi degerlendirilecek.
- `project_record` gibi genis target type degerleri coklu ID ailesi mapping'i ile desteklenecek.
- Bu adim documentation-only / helper-design-planning adimidir; uygulama kodu, test dosyalari, constants implementasyonu, helper implementasyonu, regex validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## Podcast 021 - Adim 127-131 NotebookLM Podcast Notu

- Podcast 021, Adim 127-131 araligini guvenli nokta disiplini, attachment validation ve record ID sozlesmesi planlari ekseninde ozetler.
- Podcast notlari kod davranisini degistirmez; proje hafizasini, karar aktarimini ve NotebookLM hazirligini guclendirir.
- Bu podcastte `target_record_id` hard validation'in bilincli olarak ertelendigi ve once ID envanteri, central contract, mapping helper plani yaklasiminin secildigi acik tutulur.
- Podcast 021 documentation-only olarak tutuldu; uygulama kodu, test dosyalari, Adim 132 implementasyonu, audit validation, commit, push veya ZIP staging eklenmedi.

## 132 Record ID Constants and Mapping Helper Implementation

- Record ID constants ve `target_record_type` / ID ailesi mapping helper ilk dar kod katmani olarak eklendi.
- `RECORD_ID_PREFIXES`, `TARGET_RECORD_TYPE_TO_ID_FAMILY` ve `TARGET_RECORD_TYPE_TO_ID_PREFIXES` sozlesme bilgisini merkezi ve okunur hale getirir.
- `get_record_id_family_for_target_type` ve `get_allowed_record_id_prefixes_for_target_type` sadece bilgi dondurur; `AuditEventRecord.target_record_id` formatini zorlamaz.
- Bilinmeyen target type degerleri helper seviyesinde temiz `ValueError` alir, fakat mevcut `AuditEventRecord` constructor davranisi daraltilmaz.
- Legacy ID ornekleri korunur; hard validation ancak ID sozlesmesi, mapping, test standardizasyonu ve migration kararlari netlestikten sonra degerlendirilecek.
- Bu adimda persistence, repository, API, GUI, CLI, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 133 Record ID Helper API Boundary and Test Standardization Plan

- Record ID helper API'si validation fonksiyonu gibi kullanilmayacak.
- `get_record_id_family_for_target_type` ve `get_allowed_record_id_prefixes_for_target_type` sadece mapping bilgisi dondurur; `AuditEventRecord.target_record_id` kabul/red karari vermez.
- Legacy ID ornekleri backward compatibility sinyali olarak korunacak; yeni testlerde canonical prefix ornekleri ayri ve kontrollu bicimde kullanilacak.
- Helper mapping testleri ile model validation testleri ayri tutulacak.
- Test ornek standardizasyonu ve soft validation ayri adimlarda ele alinmadan hard validation uygulanmayacak.
- Bu adim documentation-only / API-boundary-planning adimidir; uygulama kodu, test dosyalari, soft validation implementasyonu, hard validation, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 134 Record ID Soft Validation Plan

- Record ID soft validation once diagnostic / uyari katmani olarak planlanacak.
- Soft validation bilgi, uyari veya rapor sonucu uretebilir; `AuditEventRecord.target_record_id` degerini reddetmek icin kullanilmayacak.
- `AuditEventRecord.__post_init__` davranisi daraltilmayacak ve legacy target id ornekleri korunacak.
- Soft validation ciktisi ileride audit raporlama, kalite kontrol ciktisi, CLI/export on kontrolu, handover package on kontrolu veya diagnostic helper icin kullanilabilir.
- `AuditEventRecord.target_record_id` hard validation, test standardizasyonu ve diagnostic cikti olgunlasmadan uygulanmayacak.
- Bu adim documentation-only / soft-validation-planning adimidir; uygulama kodu, test dosyalari, soft validation implementasyonu, hard validation, `FileAttachmentRecord` degisikligi, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 135 Record ID Soft Validation Diagnostic Helper Implementation Plan

- Record ID diagnostic helper once dis kalite kontrol / raporlama katmani icin planlanacak.
- Diagnostic helper veri reddetmeyecek; `info`, `warning` veya helper giris hatasi icin `error` seviyesinde sonuc uretmeyi hedefleyecek.
- Diagnostic helper `AuditEventRecord.__post_init__` icine baglanmayacak ve hard validation olarak kullanilmayacak.
- Legacy ID ornekleri korunacak; diagnostic sonuc sadece gorunurluk ve kalite sinyali saglayacak.
- Diagnostic helper ileride audit report, QC report, CLI/export on kontrolu veya handover package on kontrolu icin kullanilabilir.
- Bu adim documentation-only / diagnostic-helper-planning adimidir; uygulama kodu, test dosyalari, diagnostic helper implementasyonu, soft validation implementasyonu, hard validation, `FileAttachmentRecord` degisikligi, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 136 Record ID Diagnostic Helper Implementation

- `diagnose_record_id_for_target_type` helper'i dis kalite kontrol / raporlama / handover on kontrol katmani icin bilgi ureten kucuk bir fonksiyon olarak eklendi.
- Helper mevcut record ID mapping katmanini kullanir ve `target_record_type`, `target_record_id`, `expected_family`, `allowed_prefixes`, `observed_prefix`, `is_compatible`, `severity` ve `message` alanlarini dondurur.
- Prefix okuma uzun prefixleri once dener; `NCR-CAND`, `NCR-CA`, `MAT-DEL`, `CHK-RES`, `JSON-EXP` ve `file-att` gibi cok parcali prefixler yanlis bolunmez.
- Diagnostic helper veri reddetmez; `AuditEventRecord.__post_init__` icine baglanmadi ve `AuditEventRecord.target_record_id` hard validation eklenmedi.
- Legacy ID ornekleri korunur; `file-att-001` gibi legacy prefixler warning olarak raporlanir ama constructor tarafinda reddedilmez.
- `FileAttachmentRecord` davranisina dokunulmadi; Podcast 022 olusturulmadi, commit, push veya ZIP staging yapilmadi.

## Podcast 022 - Adim 132-136 NotebookLM Podcast Notu

- Podcast 022, record ID constants/mapping helper implementation, helper API boundary, soft validation plan, diagnostic helper plan ve diagnostic helper implementation adimlarini ozetler.
- Podcast notu, hard validation'a dogrudan gecilmeme nedenini merkezi sozlesme, mapping, test standardizasyonu, diagnostic gorunurluk ve legacy ID korunmasi ekseninde anlatir.
- `AuditEventRecord.__post_init__` icine diagnostic helper baglanmadigi ve `AuditEventRecord.target_record_id` hard validation'in hala ertelendigi acik tutulur.
- Diagnostic helper'in dis kalite kontrol, raporlama ve handover on kontrol katmani icin bilgi urettigi; veri reddetmedigi vurgulanir.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, hard validation, commit, push veya ZIP staging eklenmedi.

## 137 Record ID Diagnostic Helper Usage Boundary Plan

- `diagnose_record_id_for_target_type` helper'i saf diagnostic fonksiyon olarak kalacak; bilgi uretir, karar verme sorumlulugu cagiran katmandadir.
- Helper handover on kontrol raporlari, audit kalite kontrol raporlari, migration oncesi envanter taramalari, admin/debug diagnostic ciktilari, test example standardization kontrolleri ve ileride export/backup/restore oncesi uyari uretimi icin kullanilabilir.
- Helper `AuditEventRecord.__post_init__` icinde, constructor validation katmani olarak, hard validation olarak, legacy kayitlari reddetmek icin, `FileAttachmentRecord` davranisini degistirmek icin veya otomatik data correction/migration icin kullanilmayacak.
- `warning` veri hatasi degil kalite kontrol uyarisi; `error` otomatik silme veya duzeltme sebebi degil helper seviyesinde diagnostic uretilemeyen giris olarak ele alinacak.
- `target_record_id` hard validation hala eklenmeyecek; `AuditEventRecord.__post_init__` degistirilmeyecek ve legacy ID ornekleri korunacak.
- Bu adim documentation-only usage-boundary adimidir; uygulama kodu, test dosyalari, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 138 Record ID Diagnostic Report Helper Plan

- Ilerideki read-only `build_record_id_diagnostic_report(...)` benzeri helper, birden fazla audit/event/record referansini tarayip her item icin `diagnose_record_id_for_target_type(...)` benzeri diagnostic sonuc uretmek uzere planlandi.
- Olası rapor alanlari `total_count`, `compatible_count`, `warning_count`, `error_count`, `items`, `summary` ve gerekirse ileride `generated_at` olarak belirlendi.
- Her item icin `index`, `target_record_type`, `target_record_id`, `expected_family`, `allowed_prefixes`, `observed_prefix`, `is_compatible`, `severity` ve `message` alanlari planlandi.
- Helper handover on kontrol, audit QC, migration oncesi envanter, backup/export oncesi uyari, admin/debug gorunurlugu ve test example standardization kontrolu icin read-only rapor uretebilir.
- Helper `AuditEventRecord.__post_init__`, constructor validation, hard validation, legacy kayit reddi, otomatik duzeltme, migration uygulamasi, `FileAttachmentRecord` davranisi, database/repository yazimi veya audit event olusturma icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek; `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve diagnostic report helper ileride bile once read-only kalacak.
- Bu adim documentation-only plan adimidir; uygulama kodu, test dosyalari, diagnostic report helper implementasyonu, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 139 Record ID Diagnostic Report API Boundary and Test Matrix Plan

- Olası `build_record_id_diagnostic_report(...)` helper'i icin API boundary, input/output sozlesmesi ve test example matrix planlandi; implementasyon yapilmadi.
- Ilk implementasyonun saf Python input listesiyle baslamasi, dict item (`target_record_type` / `target_record_id`) veya tuple item (`target_record_type`, `target_record_id`) bicimlerini destekleyebilmesi ve model/repository/database bagimliligi eklememesi onerildi.
- Output sozlesmesi `total_count`, `compatible_count`, `warning_count`, `error_count`, `items` ve `summary`; item sozlesmesi `index`, `target_record_type`, `target_record_id`, `expected_family`, `allowed_prefixes`, `observed_prefix`, `is_compatible`, `severity` ve `message` olarak planlandi.
- Test matrix bos input, canonical, legacy, prefix disi, bilinmeyen target type, bos `target_record_id`, karisik severity listesi, index korunumu, summary count dogrulugu, input degismezligi, exception yerine diagnostic item ve cok parcali prefix orneklerini kapsayacak.
- Helper read-only kalacak; kayit reddetmeyecek, veri degistirmeyecek, database/repository yazmayacak, audit event olusturmayacak, migration/otomatik duzeltme yapmayacak, dosya sistemi/backup/restore/export uretmeyecek, `AuditEventRecord.__post_init__` icine baglanmayacak, constructor validation veya hard validation olmayacak.
- `target_record_id` hard validation hala eklenmeyecek; `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `FileAttachmentRecord` davranisina dokunulmayacak.
- Bu adim documentation-only API-boundary/test-matrix adimidir; uygulama kodu, test dosyalari, helper implementasyonu, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 140 Read-only Record ID Diagnostic Report Helper Implementation

- `build_record_id_diagnostic_report(records)` helper'i read-only toplu diagnostic rapor helper'i olarak eklendi.
- Helper saf Python dict itemlari (`target_record_type` / `target_record_id`) ve tuple/list itemlari destekler; her gecerli item icin `diagnose_record_id_for_target_type(...)` sonucunu kullanir.
- Rapor `total_count`, `compatible_count`, `warning_count`, `error_count`, `items` ve `summary` alanlarini dondurur; itemlar input sirasini `index` ile korur.
- Eksik veya uygunsuz itemlar exception firlatmak yerine `error` severity diagnostic item uretir; helper input listesini veya dictlerini mutate etmez.
- Helper kayit reddetmez, veri degistirmez, database/repository yazmaz, audit event olusturmaz, migration/otomatik duzeltme yapmaz, dosya sistemi/backup/restore/export uretmez.
- `AuditEventRecord.__post_init__` icine baglanmadi, constructor validation veya hard validation eklenmedi, legacy ID ornekleri korunur ve `FileAttachmentRecord` davranisina dokunulmadi.
- Podcast 023 olusturulmadi; commit, push veya ZIP staging yapilmadi.

## 141 Record ID Diagnostic Report Usage and Edge Case Standardization

- `build_record_id_diagnostic_report(records)` helper'i handover on kontrol, audit QC, migration oncesi envanter, backup/export oncesi uyari listesi, admin/debug gorunurlugu, test example standardization ve veri kalitesi gozden gecirme dokumantasyonu icin read-only gorunurluk saglar.
- Helper `AuditEventRecord.__post_init__` icinde, constructor validation olarak, hard validation olarak, legacy kayitlari reddetmek icin, otomatik data correction icin, migration uygulama adimi olarak, database/repository yazmak icin, audit event olusturmak icin veya `FileAttachmentRecord` davranisini degistirmek icin kullanilmayacak.
- Bos input hata degildir; canonical ID `info` ve compatible, legacy ID `warning` ve compatible, prefix disi ID `warning` ve incompatible, bilinmeyen target type veya bos `target_record_id` ise helper seviyesinde `error` diagnostic item olarak yorumlanir.
- Uygunsuz input item raporu kesmez; exception yerine `error` diagnostic item uretir. Tuple/list inputta ilk iki eleman, dict inputta `target_record_type` ve `target_record_id` anahtarlari okunur.
- `warning_count` ve `error_count` hard validation tetiklemez; summary/count alanlari karar vermez, rapor gorunurlugu saglar.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve diagnostic report helper read-only kalacak.
- Bu adim documentation-only usage/edge-case standardization adimidir; uygulama kodu, test dosyalari, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 142 Diagnostic Report Export / Format Boundary Plan

- `build_record_id_diagnostic_report(...)` ciktisinin ileride JSON-ready dict, Markdown summary, handover QC summary ve admin/debug gorunumu olarak sunulabilmesi icin format/export siniri documentation-only olarak planlandi.
- Diagnostic helper veri uretir; format layer diagnostic report dict alir ve sunum ciktisi uretir. Format layer diagnostic sonucu yeniden hesaplamaz, veriyi degistirmez, kayit olusturmaz ve audit event uretmez.
- Olası format helper adlari `format_record_id_diagnostic_report_as_markdown(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)` ve `build_handover_record_id_qc_summary(...)` olarak yalnizca planlandi; bu adimda implementasyon yapilmadi.
- Format layer dosya sistemine yazmayacak, database/repository yazmayacak, backup/export/restore islemini dogrudan yapmayacak, CLI/API/GUI eklemeyecek ve hard validation tetiklemeyecek.
- Handover QC sunumunda `total_count`, `warning_count`, `error_count` ve warning/error itemlari gorunur olabilir; warning/error degerleri devri otomatik engellemez, "gozden gecirilecek kayit" olarak yorumlanir.
- `warning` veri reddi degildir; `error` otomatik silme veya duzeltme sebebi degildir. Format layer severity anlamlarini degistirmeyecek.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Bu adim documentation-only export/format boundary plan adimidir; uygulama kodu, test dosyalari, export helper, format helper, JSON/Markdown dosya uretimi, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 143 Soft Validation Report Layer Plan

- `build_record_id_diagnostic_report(...)` ciktisinin ileride kayit reddetmeyen soft validation report layer icin nasil yorumlanabilecegi documentation-only olarak planlandi.
- Diagnostic katman ham `info` / `warning` / `error` bilgisi uretir; soft validation report bu sonuclari "gozden gecir", "devir oncesi kontrol et" veya "legacy uyumlu ama izlenmeli" gibi kalite kontrol yorumlarina cevirir.
- Soft validation report layer handover on kontrol, audit QC raporu, export/backup oncesi risk gorunurlugu, admin/debug kalite raporu, migration oncesi veri sagligi incelemesi ve test example standardization gozden gecirme icin kullanilabilir.
- Soft validation report `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit olusturmayi engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma veya `FileAttachmentRecord` davranisi degistirme icin kullanilmayacak.
- Olası `build_record_id_soft_validation_report(...)` helper adi yalnizca planlandi; bu adimda implementasyon yapilmadi.
- Olası soft validation seviyeleri `pass`, `review` ve `attention` olarak planlandi; `blocked` seviyesi hard validation veya engelleme anlami dogurabilecegi icin bu asamada kullanilmayacak.
- Handover ve export/backup yorumlari warning/error kayitlarini gorunur yapar, fakat devir paketini veya exportu otomatik bloke etmez ve backup/restore davranisini degistirmez.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Bu adim documentation-only soft-validation-report-layer plan adimidir; uygulama kodu, test dosyalari, soft validation helper, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## Podcast 023 - Adim 137-141 NotebookLM Podcast Notu

- Podcast 023, Adim 137-141 araligini diagnostic helper usage boundary, diagnostic report helper plani, API boundary/test matrix, read-only report helper implementasyonu ve edge case standardization ekseninde ozetler.
- Podcast notu, `build_record_id_diagnostic_report(...)` helper'inin neden read-only kaldigini, warning/error seviyelerinin neden kayit reddi olmadigini ve hard validation'in neden hala ertelendigini acik tutar.
- `AuditEventRecord.__post_init__` degistirilmedigi, `target_record_id` hard validation eklenmedigi, legacy ID orneklerinin korundugu ve `FileAttachmentRecord` davranisina dokunulmadigi yinelendi.
- Podcast kapsami yalniz Adim 137-141 ile sinirli tutuldu; sonraki adimlar bu podcast kapsaminda anlatilmadi ve Podcast 024 olusturulmadi.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, hard validation, commit, push veya ZIP staging eklenmedi.

## 144 Soft Validation Report API Boundary and Test Matrix Plan

- Olasi `build_record_id_soft_validation_report(...)` helper'i icin API boundary, input/output sozlesmesi, status/severity yorumlama kurali ve test matrix documentation-only olarak planlandi.
- Ilk guvenli input sozlesmesi diagnostic report dict olarak belirlendi; helper `build_record_id_diagnostic_report(...)` ciktisini yorumlayabilir, fakat record listesi, repository veya database sorgusu almayacak sekilde planlandi.
- Olasi output sozlesmesi `status`, `total_count`, `compatible_count`, `warning_count`, `error_count`, `review_required`, `attention_required`, `messages`, `items` ve `summary` alanlarini icerebilir.
- Status seviyeleri `pass`, `review` ve `attention` olarak planlandi; `blocked` seviyesi hard validation veya engelleme anlami dogurabilecegi icin bu asamada uretilmeyecek.
- Test matrix bos diagnostic report, info-only pass, warning review, error attention, mixed warning/error attention, status onceligi, required flag mantigi, summary/count korunumu, items korunumu, input immutability, eksik alanlar, uygunsuz input tipi, unknown severity, warning'in kayit reddi olmamasi, error'in otomatik duzeltme olmamasi ve `blocked` uretilmemesini kapsayacak.
- Soft validation report helper `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma veya `FileAttachmentRecord` davranisi degistirme icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Bu adim documentation-only API-boundary/test-matrix plan adimidir; uygulama kodu, test dosyalari, soft validation helper implementasyonu, hard validation, Podcast 024, commit, push veya ZIP staging eklenmedi.

## 145 Read-only Soft Validation Report Implementation

- `build_record_id_soft_validation_report(diagnostic_report)` helper'i read-only soft validation report katmani olarak eklendi.
- Helper input olarak `build_record_id_diagnostic_report(...)` ciktisi olan diagnostic report dict alir; record listesi, repository veya database sorgusu almaz.
- Output sozlesmesi `status`, `total_count`, `compatible_count`, `warning_count`, `error_count`, `review_required`, `attention_required`, `messages`, `items` ve `summary` alanlarini icerir.
- Status kurallari `pass`, `review` ve `attention` olarak uygulandi; `blocked` status'u uretilmez.
- `pass` warning/error olmadigini, `review` warning goruldugunu, `attention` error veya helper input sorunu goruldugunu anlatir. Bu seviyeler kayit reddi, otomatik silme, otomatik duzeltme veya migration sebebi degildir.
- Helper diagnostic report dict'ini mutate etmez; count degerlerini diagnostic report'tan okur, item ve summary bilgisini korur.
- Unknown severity exception firlatmaz; messages alaninda gorunur olur ve kayit reddi yaratmaz.
- Uygunsuz input veya eksik alanlar exception yerine `attention` seviyesinde okunur soft validation report dondurur.
- `AuditEventRecord.__post_init__` icine baglanmadi, constructor validation veya hard validation eklenmedi, legacy ID ornekleri korunur.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmedi ve `FileAttachmentRecord` davranisina dokunulmadi.
- Database/repository/API/GUI/CLI, audit event olusturma, migration, otomatik duzeltme, Podcast 024, commit, push veya ZIP staging eklenmedi.

## 146 Soft Validation Report Usage and Handover QC Interpretation

- `build_record_id_soft_validation_report(...)` helper'inin usage boundary ve handover QC yorumlama standardi documentation-only olarak belgelendi.
- Helper diagnostic report dict alir, read-only soft validation report dict dondurur, `pass` / `review` / `attention` status degerlerini uretir ve `blocked` status uretmez.
- `pass`, warning veya error gorunmedigini anlatir; ek aksiyon gerekmeyen normal gorunum olarak yorumlanir.
- `review`, warning goruldugunu anlatir; legacy veya prefix disi ama reddedilmeyen kayitlar icin manuel gozden gecirme sinyalidir ve kayit reddi degildir.
- `attention`, error veya eksik/uygunsuz diagnostic input goruldugunu anlatir; manuel inceleme sinyalidir, otomatik silme, otomatik duzeltme, migration veya kayit reddi sebebi degildir.
- Handover QC icinde soft validation report yeni santiye sefine veri sagligi gorunurlugu saglar, warning/error kayitlarini gorunur yapar ve checklist icin gozden gecirilecek kayitlar uretir; devir paketini otomatik bloke etmez.
- Audit QC icinde target record type / id uyum riskini gorunur yapar; legacy kayitlari reddetmez, `AuditEventRecord.__post_init__` icine baglanmaz ve audit event olusturmaz.
- Export/backup oncesi kullanim veri kalitesi risklerini gorunur yapabilir; exportu durdurmaz, backup/restore davranisini degistirmez ve dosya sistemi islemi yapmaz.
- `messages`, `summary`, `warning_count`, `error_count`, `review_required` ve `attention_required` alanlari gorunurluk saglar; hard validation, kayit reddi veya otomatik duzeltme tetiklemez.
- Helper `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit olusturmayi engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi veya API/GUI/CLI entegrasyonu icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmeyecek.
- Bu adim documentation-only usage/handover-QC interpretation adimidir; uygulama kodu, test dosyalari, helper davranisi, `blocked` status, hard validation, Podcast 024, commit, push veya ZIP staging eklenmedi.

## Podcast 024 - Adim 142-146 NotebookLM Podcast Notu

- Podcast 024, Adim 142-146 araligini diagnostic report export/format boundary, soft validation report layer, API boundary/test matrix, read-only soft validation report implementation ve handover QC yorumlama ekseninde ozetler.
- Podcast notu, diagnostic report ciktisinin neden dogrudan export/helper koduna baglanmadigini ve export/format boundary'nin neden once documentation-only planlandigini acik tutar.
- Soft validation report layer'in hard validation'dan farki, `pass` / `review` / `attention` seviyelerinin pratik anlami ve `blocked` status'un neden uretilmedigi anlatilir.
- `build_record_id_soft_validation_report(...)` helper'inin raw diagnostic ciktisini read-only soft validation report'a cevirerek handover ve audit QC gorunurlugu sagladigi, fakat kayit reddetmedigi vurgulanir.
- Warning ve error sinyallerinin otomatik silme, otomatik duzeltme, migration veya kayit reddi degil manuel inceleme anlami tasidigi acik tutulur.
- `AuditEventRecord.__post_init__` degistirilmedi, hard validation eklenmedi, legacy ID ornekleri korundu ve `FileAttachmentRecord` davranisina dokunulmadi.
- Podcast kapsami yalniz Adim 142-146 ile sinirli tutuldu; Adim 147 dahil edilmedi ve Podcast 025 olusturulmadi.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, hard validation, `blocked` status, commit, push veya ZIP staging eklenmedi.

## 147 Diagnostic / Soft Validation Format Helper Plan

- Diagnostic report ve soft validation report ciktilarinin ileride Markdown, JSON-ready dict ve handover QC summary gibi sunum formatlarina nasil donusturulecegi documentation-only olarak planlandi.
- Format layer mevcut diagnostic report dict veya soft validation report dict alacak; diagnostic sonucu yeniden hesaplamayacak, soft validation status yeniden hesaplamayacak, veriyi degistirmeyecek ve kayit reddetmeyecek.
- Olası helper adlari `format_record_id_diagnostic_report_as_markdown(...)`, `format_record_id_soft_validation_report_as_markdown(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)` ve `build_handover_record_id_qc_summary(...)` olarak yalnizca planlandi; implementasyon yapilmadi.
- Markdown format planinda baslik, summary, status/count alanlari, warning/error item listesi, "kayit reddi degildir" ve "hard validation degildir" notlari yer alabilir.
- JSON-ready dict Python dict olarak kalacak; dosyaya yazma, export etme, backup/restore islemi veya ozel object/datetime uretimi bu katmanda yapilmayacak.
- Handover QC summary yeni santiye sefine veri sagligi gorunurlugu saglayacak; warning/error kayitlarini "gozden gecirilecek kayitlar" olarak gosterecek, devir paketini otomatik bloke etmeyecek ve hard validation tetiklemeyecek.
- Severity/status sunum standardi `info`, `warning`, `error`, `pass`, `review` ve `attention` icin belgelendi; `blocked` status uretilmeyecek ve format layer tarafindan eklenmeyecek.
- Format layer `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi veya API/GUI/CLI entegrasyonu icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmeyecek.
- Bu adim documentation-only format-helper-plan adimidir; uygulama kodu, test dosyalari, format helper implementasyonu, JSON/Markdown dosya uretimi, `blocked` status, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 148 Diagnostic / Soft Validation Format Helper API Boundary and Test Matrix Plan

- Diagnostic / soft validation format helper katmani icin API boundary, input/output sozlesmesi ve test matrix documentation-only olarak planlandi.
- Olası helper adlari `format_record_id_diagnostic_report_as_markdown(...)`, `format_record_id_soft_validation_report_as_markdown(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)` ve `build_handover_record_id_qc_summary(...)` olarak yalnizca planlandi; implementasyon yapilmadi.
- Diagnostic Markdown formatter input'u `build_record_id_diagnostic_report(...)` ciktisi, soft validation Markdown formatter input'u `build_record_id_soft_validation_report(...)` ciktisi, JSON-ready formatter input'u diagnostic veya soft validation report dict, handover QC summary input'u tercihen soft validation report dict olarak planlandi.
- Markdown output string dondurecek ve dosya yazmayacak; JSON-ready dict output primitive/list/dict degerlerle kalacak, serialize edilemeyen object icermeyecek ve dosya yazmayacak.
- Handover QC summary `status`, `review_required`, `attention_required`, `total_count`, `warning_count`, `error_count`, `review_items`, `attention_items` ve `message` gibi alanlar icerebilir; devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek ve hard validation tetiklemeyecek.
- Test matrix Markdown formatter icin pass/review/attention ciktilari, warning/error item gorunurlugu, hard validation degildir notu ve `blocked` status uretilmemesini kapsayacak.
- Test matrix JSON-ready formatter icin output dict olmasi, input immutability, item count/items korunumu, serialize edilemeyen object eklenmemesi ve diagnostic/soft status yeniden hesaplanmamasini kapsayacak.
- Test matrix handover QC summary icin pass, review, attention davranisi, warning/error item listesi korunumu, devir paketinin otomatik bloke edilmemesi ve `blocked` status uretilmemesini kapsayacak.
- Unsupported input icin exception yerine okunur format/summary hatasi planlanabilir; bu davranis kayit reddi anlami dogurmayacak.
- Format layer `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi veya API/GUI/CLI entegrasyonu icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmeyecek.
- Bu adim documentation-only API-boundary/test-matrix plan adimidir; uygulama kodu, test dosyalari, format helper implementasyonu, JSON/Markdown dosya uretimi, `blocked` status, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 149 Read-only Diagnostic / Soft Validation Format Helper Implementation

- Diagnostic / soft validation format helper katmani read-only olarak implemente edildi.
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)`, `format_record_id_diagnostic_report_as_markdown(...)` ve `format_record_id_soft_validation_report_as_markdown(...)` helperlari eklendi.
- JSON-ready helperlar Python dict dondurur, input report verisini mutate etmeden kopyalar, count/status/items/messages/summary icerigini sunar ve yeni serialize edilemeyen object eklemez.
- Markdown helperlar string dondurur; baslik, count/status alanlari, warning/error veya review/attention itemlari ve "kayit reddi degildir" / "Hard validation degildir" notlarini icerir.
- Unsupported inputlarda exception yerine okunur minimal dict veya Markdown string dondurulur; bu kayit reddi anlami tasimaz.
- Formatterlar diagnostic sonucu veya soft validation status'u yeniden hesaplamaz; inputta gelen count/status degerlerini sunar.
- `blocked` output status olarak uretilmez; soft validation Markdown ciktisi `blocked` status uretilmedigini acikca belirtir.
- Testler JSON-ready output, Markdown output, input immutability, unsupported input, no recomputation, no blocked output status ve `AuditEventRecord` constructor davranisinin daralmamasini kapsar.
- `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmedi; `AuditEventRecord.__post_init__` degistirilmedi ve `FileAttachmentRecord` davranisina dokunulmadi.
- Bu adimda JSON/Markdown dosyasi, export helper, backup/restore, database/repository/API/GUI/CLI, migration, otomatik duzeltme, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 150 Handover QC Summary Usage and Format Helper Boundary

- Adim 149 format helper'larinin handover QC icinde nasil okunacagi ve nerelerde kullanilmayacagi documentation-only olarak belgelendi.
- Format helperlar mevcut report dict'lerini sunuma hazirlar; JSON-ready dict veya Markdown string dondurur, dosya uretmez, export yapmaz, veri degistirmez, diagnostic sonucu veya soft validation status yeniden hesaplamaz, kayit reddetmez ve hard validation degildir.
- Handover QC icinde format helper ciktilari yeni santiye sefine veri sagligi gorunurlugu saglar, warning/error veya review/attention kayitlarini gorunur yapar ve "gozden gecirilecek kayitlar" mantigiyla kullanilir.
- Handover QC ciktisi devir paketini otomatik bloke etmez, kayit reddetmez, hard validation tetiklemez ve `blocked` status uretmez.
- Markdown ciktilari handover notu, QC ozeti, admin/debug gorunumu veya proje ici dokumantasyon icin kullanilabilir; "Bu rapor kayit reddi degildir", "Hard validation degildir" ve "`blocked` status uretilmez" notlarini korumalidir.
- JSON-ready dict ciktilari makine tarafindan okunabilir ara temsil olabilir; bu adimda dosyaya yazilmaz, export helper degildir, backup/restore davranisi degildir, database/repository yazmaz ve input report davranisini degistirmez.
- Handover QC status yorumlari `pass` icin gorunur risk yok, `review` icin manuel gozden gecirme, `attention` icin manuel inceleme ve `blocked` icin kullanilmaz/uretilmez seklinde sabitlendi.
- Format helperlar `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi, API/GUI/CLI entegrasyonu veya JSON/Markdown dosya exportu icin kullanilmayacak.
- `build_record_id_diagnostic_report(...)`, `build_record_id_soft_validation_report(...)` ve tum format helper davranislari degistirilmedi.
- Bu adim documentation-only usage-boundary adimidir; uygulama kodu, test dosyalari, format helper davranisi, JSON/Markdown dosya uretimi, export helper, `blocked` status, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 151 Export File Writing Boundary Plan

- Adim 149 JSON-ready dict ve Markdown string formatter helper'larindan sonra olasi JSON/Markdown dosya yazimi, export ve handover package uretimi icin guvenli sinir documentation-only olarak belgelendi.
- Format helper ile file writing helper'in ayni sorumluluk olmadigi netlestirildi; mevcut format helperlar Python dict veya Markdown string dondurur, dosya uretmez, export yapmaz, backup/restore yapmaz, database/repository yazmaz, kayit reddetmez ve hard validation tetiklemez.
- `build_record_id_diagnostic_report(...)`, `build_record_id_soft_validation_report(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)`, `format_record_id_diagnostic_report_as_markdown(...)` ve `format_record_id_soft_validation_report_as_markdown(...)` davranislari degistirilmeyecek olarak korundu.
- Olasi `write_record_id_diagnostic_report_json(...)`, `write_record_id_soft_validation_report_json(...)`, `write_record_id_diagnostic_report_markdown(...)`, `write_record_id_soft_validation_report_markdown(...)` ve `build_handover_qc_export_package(...)` helper adlari yalnizca gelecek plan olarak not edildi; implementasyon yapilmadi.
- Gelecekte export/file writing layer eklenirse yalniz onceden uretilmis JSON-ready dict veya Markdown string alacak; diagnostic sonucu yeniden hesaplamayacak, soft validation status yeniden hesaplamayacak, veri degistirmeyecek, kayit reddetmeyecek, audit event olusturmayacak, backup/restore davranisi ustlenmeyecek, hard validation tetiklemeyecek ve `blocked` status uretmeyecek.
- Dosya yazimi icin acik output path, proje disina yazma siniri, path traversal korumasi, overwrite politikasi, deterministik dosya adi, UTF-8 encoding, JSON serialize edilebilirlik ve Markdown insan-okurlugu gibi guvenlik prensipleri ayri planlanacak.
- Handover package ileride yeni santiye sefine veri sagligi gorunurlugu saglayabilir ve warning/error veya review/attention kayitlarini gorunur yapabilir; fakat devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek, hard validation tetiklemeyecek ve eski santiye sefinin ozel alanini devretmeyecek.
- Export/file writing layer `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit olusturmayi engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi, API/GUI/CLI entegrasyonu veya backup/restore motoru icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, format helper davranislari degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only export/file-writing-boundary plan adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown dosya uretimi, backup/restore davranisi, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## Podcast 025 - Adim 147-151 NotebookLM Podcast Notu

- Podcast 025, Adim 147-151 araligini diagnostic / soft validation format helper plani, API boundary/test matrix, read-only JSON-ready dict ve Markdown formatter implementasyonu, handover QC usage boundary ve export/file writing boundary ekseninde ozetler.
- Podcast notu, diagnostic ve soft validation report ciktilarinin neden ayri format katmanina tasindigini, format helper planinin neden once documentation-only yapildigini ve API boundary/test matrix'in neden implementation'dan once belgelendigini acik tutar.
- Adim 149'da gelen JSON-ready dict ve Markdown helper'larin raporlari okunur hale getirdigi, fakat dosya uretmedigi, export yapmadigi, backup/restore davranisi eklemedigi, diagnostic sonucu veya soft validation status'u yeniden hesaplamadigi vurgulandi.
- Handover QC summary'nin yeni santiye sefine gorunurluk sagladigi, warning/error veya review/attention kayitlarini manuel inceleme icin gorunur yaptigi, fakat kayit reddi veya otomatik devir bloklama olmadigi anlatildi.
- Export/file writing boundary'nin ayri risk katmani oldugu; output path, overwrite politikasi, path traversal, UTF-8 encoding, JSON serialize edilebilirlik, Markdown insan-okurlugu ve handover package siniri gibi konular cozulmeden JSON/Markdown dosya uretimine gecilmeyecegi belgelendi.
- Hard validation ve `blocked` status'un hala kapsam disinda oldugu, `AuditEventRecord.__post_init__` ve `FileAttachmentRecord` davranislarinin degistirilmedigi yinelendi.
- Podcast kapsami yalniz Adim 147-151 ile sinirli tutuldu; Adim 152 dahil edilmedi ve Podcast 026 olusturulmadi.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, JSON/Markdown dosya uretimi, export/file writing helper implementasyonu, hard validation, `blocked` status, commit, push veya ZIP staging eklenmedi.

## 152 Export Helper API Boundary and File Writing Safety Plan

- Adim 151 export/file writing boundary sonrasinda olasi JSON/Markdown export helper'lari icin API boundary, path safety, overwrite policy, encoding/format beklentileri ve test matrix documentation-only olarak planlandi.
- Format helper ile export helper'in ayri katmanlar oldugu yinelendi; format helper Python dict veya Markdown string dondurur, export helper ise ileride kalici dosya ciktisi uretebilir ve bu nedenle ayri path/overwrite/encoding siniri ister.
- Olasi `write_record_id_diagnostic_report_json(...)`, `write_record_id_soft_validation_report_json(...)`, `write_record_id_diagnostic_report_markdown(...)`, `write_record_id_soft_validation_report_markdown(...)` ve `write_handover_qc_summary_markdown(...)` helper adlari yalnizca gelecek plan olarak not edildi; implementasyon yapilmadi.
- JSON export helper'in input olarak JSON-ready Python dict, Markdown export helper'in input olarak Markdown string almasi ve output path'in acikca verilen guvenli path olmasi planlandi; output ileride yazilan dosya yolu veya write result dict olabilir.
- Gelecekte export helper diagnostic report veya soft validation report'u yeniden hesaplamayacak, format helper davranisini degistirmeyecek, kayit reddetmeyecek, hard validation yapmayacak, `blocked` status uretmeyecek, database/repository yazmayacak, audit event olusturmayacak, backup/restore motoru gibi davranmayacak ve API/GUI/CLI entegrasyonu eklemeyecek.
- Path safety planinda output path'in acik verilmesi, path traversal'in engellenmesi, proje koku veya izinli export klasoru disina yazimin engellenmesi, absolute/relative path davranislarinin test edilmesi, parent directory davranisinin planlanmasi, deterministik dosya adi, Windows path karakterleri ve ZIP/yedek dosyalarin export kapsamina alinmamasi belgelendi.
- Overwrite policy icin guvenli varsayilan `overwrite=False` olarak planlandi; `overwrite=True` explicit parametre ve ayri test gerektiren davranis olarak belirlendi.
- Encoding ve format planinda Markdown ve JSON icin UTF-8, JSON icin olasi deterministic indentation, JSON primitive/list/dict serialize edilebilirligi, Markdown insan-okurlugu ve format helper'dan gelen icerigin dosya yaziminda degistirilmemesi belgelendi.
- Test matrix JSON/Markdown export path safety, relative/absolute path davranisi, path traversal reddi, izinli klasor disina cikmama, overwrite davranisi, parent directory davranisi, UTF-8, JSON serialize edilebilirlik, Markdown icerik korunumu, input immutability, format helper'in yeniden hesaplanmamasi, hard validation tetiklenmemesi, `blocked` status uretilmemesi ve ZIP/yedek dosyalarin stage/export kapsamina alinmamasini kapsayacak.
- Handover export ileride yalniz explicit handover icerigi uretebilir; warning/error veya review/attention kayitlarini gorunur yapabilir, fakat eski santiye sefinin ozel alanini devretmeyecek, devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek ve hard validation tetiklemeyecek.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)`, `build_record_id_soft_validation_report(...)` ve format helper davranislari degistirilmeyecek.
- Bu adim documentation-only export-helper-boundary/file-writing-safety plan adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown dosya uretimi, backup/restore davranisi, hard validation, `blocked` status, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 153 Path Safety and Overwrite Policy Detailed Documentation

- Adim 153 path safety ve overwrite policy konusunu documentation-only olarak detaylandirdi.
- Gelecekteki export helper'in output path'i implicit secmemesi, explicit output path istemesi ve yazma hedefini izinli export kokunun icinde tutmasi kararlastirildi.
- Relative path davranisi izinli export kokune gore cozumlenmeli; cozumlenmis hedef allowed output root disina cikiyorsa yazma yapilmamalidir.
- Absolute path davranisi ya tamamen reddedilmeli ya da cozumlenmis hedef allowed output root altinda kalacak sekilde sinirlanmalidir; Windows drive/UNC varyasyonlari test matrix'te dikkate alinmalidir.
- Parent directory davranisi belirsiz birakilmayacak; guvenli varsayilan eksik parent icin hata olabilir, otomatik olusturma ancak explicit ve allowed output root altinda planlanabilir.
- Path traversal riskleri `..`, mixed separator, encoded traversal benzeri inputlar ve dosya adi icinde separator kullanimi icin prensip duzeyinde belgelendi; yalniz string prefix kontrolu yeterli karar sayilmadi.
- `.git`, `.env`, cache, pycache, database, backup, ZIP/yedek ve source-code alanlari future export yazim kapsamindan disarida tutulacak.
- Dosya uzantisi siniri JSON export icin `.json`, Markdown export icin `.md` olarak planlandi; bos dosya adi, separator iceren ad, cok uzun ad, ozel karakterler ve Windows reserved names riski ayri ele alinacak.
- Overwrite policy icin guvenli varsayilan `overwrite=False` olarak netlestirildi; mevcut dosya explicit `overwrite=True` olmadikca ezilmeyecek ve overwrite davranisi ileride audit/log gorunurluguyle ele alinabilir.
- Atomic write icin temporary file + replace prensibi ileride degerlendirilebilir; bu adimda temporary file, replace veya file-writing kodu eklenmedi.
- Hata davranisi exception veya diagnostic result olarak ileride tasarlanabilir; hangi model secilirse secilsin kayit reddi, hard validation veya `blocked` status anlami tasimayacak.
- Read-only format helper ile file-writing export helper ayrimi korundu; format helper Python dict/Markdown string dondurur, file-writing helper ise ileride yalniz hazir ciktinin guvenli dosyaya yazilmasindan sorumlu olabilir.
- Handover QC export yalniz gorunurluk ve manuel inceleme amacli kullanilabilir; devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek, eski santiye sefinin ozel alanini devretmeyecek ve backup/restore motoru olmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only detailed-policy adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 154 Export Helper Test Matrix Finalization

- Adim 154, Adim 155'te ele alinabilecek read-only file writing helper implementation oncesinde export helper test matrix'ini documentation-only olarak netlestirdi.
- Format helper ile file-writing export helper ayri test edilecek; format helper JSON-ready dict veya Markdown string uretir, export helper ise ileride yalniz hazir ciktinin guvenli dosya yazimindan sorumlu olabilir.
- JSON export helper testleri JSON-ready dict input, `.json` uzantisi, UTF-8 output, pretty/indent davranisi, dosya iceriginin tekrar okunup dogrulanmasi, input immutability, diagnostic/soft validation recomputation olmamasi ve dataclass/object/unserializable input icin guvenli hata davranisini kapsayacak.
- Markdown export helper testleri Markdown string input, `.md` uzantisi, UTF-8 output, Markdown iceriginin yeniden formatlanmamasi, formatter ciktisinin degistirilmemesi ve non-string input icin guvenli hata davranisini kapsayacak.
- Path safety testleri explicit output path zorunlulugu, bos path, traversal reddi, `..`, allowed output root disina cikmama, absolute/relative path davranisi, mixed separator, Windows reserved names riski ve `.git`, `.env`, cache, pycache, database, backup, ZIP/yedek alanlarina yazmama senaryolarini kapsayacak.
- Overwrite policy testleri `overwrite=False` varsayilanini, hedef dosya varken yazmama davranisini, icerigin korunmasini, explicit `overwrite=True` ile uzerine yazmayi ve yalniz hedef dosyanin degistigini dogrulamayi kapsayacak.
- Parent directory testleri parent mevcutken yazmayi, parent yokken net hata/olusturma davranisini, otomatik klasor olusturma varsa bunun yalniz allowed output root altinda olmasini ve root disinda parent olusturulmamasi kararini kapsayacak.
- Unsupported input ve hata davranisi testleri bos filename, klasor path'i, yanlis uzanti, cok uzun filename, separator iceren filename, `None` input, bos dict/string, izin hatasi, kilitli/erisilemez hedef dosya, yarim dosya birakmama ve input mutate etmeme beklentilerini kapsayacak.
- ZIP/yedek/cache dislama testleri ignored ZIP'in export girdisi/hedefi gibi kullanilmamasini, ZIP/yedek/cache dosyalarinin stage edilmemesini ve `.pytest_cache` / `__pycache__` alanlarinin export hedefi olmamasini kapsayacak.
- Atomic write temporary file + replace prensibi ileride degerlendirilebilir; bu adimda atomic write, temporary file veya replace implementasyonu yapilmadi.
- Handover QC export testleri explicit path, allowed output root, overwrite=False ile mevcut dosya koruma, warning/error veya review/attention bilgisinin yalniz gorunurluk olarak tasinmasi ve devir paketinin otomatik bloke edilmemesini kapsayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only test-matrix-finalization adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 155 Read-only File Writing Helper Implementation

- Adim 155'te hazir JSON-ready dict ve Markdown string ciktilarini explicit output path'e yazan iki kucuk helper eklendi: `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)`.
- Helperlar read-only boundary icinde tutuldu; database/repository yazmaz, audit event uretmez, backup/restore baslatmaz, kayit degistirmez, diagnostic/soft validation sonucunu yeniden hesaplamaz ve format helper davranisini degistirmez.
- JSON helper yalniz dict input kabul eder, `.json` uzantili dosyaya UTF-8 yazar, `indent=2`, `ensure_ascii=False`, `sort_keys=True` ile deterministic cikti uretir, input dict'i mutate etmez ve unserializable object icin standart `TypeError` verir.
- Markdown helper yalniz string input kabul eder, `.md` uzantili dosyaya UTF-8 yazar, Markdown icerigini yeniden formatlamaz ve non-string input icin `TypeError` verir.
- Her iki helper icin `output_path` zorunludur, varsayilan `overwrite=False` olarak uygulandi; hedef dosya varsa explicit `overwrite=True` olmadikca yazma yapilmaz ve `FileExistsError` verilir.
- Minimum path safety policy uygulandi: bos path, `..` traversal, yanlis uzanti, existing directory target, missing parent directory, optional `allowed_root` disina cikma ve `.git`, `.env`, cache, pycache, database, backup, restore, ZIP/yedek gibi non-export alanlara yazma reddedilir.
- Parent directory otomatik olusturulmadi; parent yoksa `FileNotFoundError` verilir. Gelecekte parent olusturma istenirse explicit parametre ve ayri testlerle ele alinmalidir.
- Testler JSON/Markdown yazimi, UTF-8 korunumu, deterministic JSON, input immutability, unsupported input, overwrite davranisi, allowed_root ic/dis senaryolari, traversal reddi, missing parent, non-export area reddi, helper boundary korunumu ve `blocked` status uretilmemesini kapsar.
- Test sonucu bu adimda `319 passed` seviyesine cikti.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` daraltilmayacak, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim sinirli implementation adimidir; JSON/Markdown ornek export dosyasi repo icinde uretilmedi, backup/restore davranisi, database/repository/API/GUI/CLI, audit event uretimi, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 156 Export Helper Usage Documentation

- Adim 156, Adim 155'te eklenen `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper'larinin kullanim sinirini documentation-only olarak belgelendi.
- JSON-ready dict akisi report helper -> JSON-ready formatter -> file writing helper olarak sabitlendi; file-writing helper diagnostic veya soft validation sonucunu yeniden hesaplamayacak ve input dict'i mutate etmeyecek.
- Markdown akisi report helper -> Markdown formatter -> file writing helper olarak sabitlendi; file-writing helper Markdown icerigini yeniden formatlamayacak ve input string'i degistirmeyecek.
- `allowed_root`, explicit output path, `overwrite=False` varsayilani, explicit `overwrite=True`, parent directory otomatik olusturmama, yanlis uzanti reddi, path traversal reddi ve non-export alanlara yazmama prensipleri usage dokumantasyonunda aciklandi.
- `.git`, `.env`, cache, pycache, ZIP/yedek, database, backup ve restore alanlari export hedefi olarak kullanilmayacak; `exports/` klasoru ancak explicit path ve allowed-root siniriyle guvenli aday olarak ele alinacak.
- Handover QC export senaryosu yalniz yeni santiye sefine gorunurluk ve manuel inceleme destegi olarak belgelendi; devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek, audit event uretmeyecek ve backup/restore motoru olmayacak.
- Export helper usage hard validation degildir; `AuditEventRecord.__post_init__` daraltilmayacak, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only usage adimidir; uygulama kodu, test dosyalari, yeni helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, audit event uretimi, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## Podcast 026 - Adim 152-156 NotebookLM Podcast Notu

- Podcast 026, Adim 152-156 araligini export helper API boundary, path safety / overwrite policy, test matrix finalization, read-only file writing helper implementation ve usage documentation ekseninde ozetler.
- Podcast notu, formatter helper ile file-writing helper ayrimini, JSON-ready dict ve Markdown string akislarini, explicit output path yaklasimini, `allowed_root` guvenlik sinirini, path traversal reddini ve `overwrite=False` varsayilanini sade anlatimla aciklar.
- Podcast 026, Adim 155'te eklenen `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper'larini tanitir; helperlarin diagnostic/soft validation sonucunu yeniden hesaplamadigini ve input mutate etmedigini vurgular.
- Test sayisinin 294 passed seviyesinden 319 passed seviyesine ciktigi, fakat `exports/` icinde repo'ya kalici JSON/Markdown export cikti dosyasi eklenmedigi not edildi.
- Handover QC export senaryosu gorunurluk ve manuel inceleme destegi olarak anlatildi; devir paketini otomatik bloke etme, kayit reddi, hard validation, `blocked` status veya backup/restore davranisi olarak sunulmadi.
- Podcast kapsami yalniz Adim 152-156 ile sinirli tutuldu; Adim 157 veya sonrasi dahil edilmedi ve Podcast 027 olusturulmadi.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` daraltilmayacak, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, yeni helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, audit event uretimi, hard validation, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 157 Export Helper Error / Result Contract Plan

- Adim 157, Adim 155'te eklenen `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper'larinin hata ve basari sozlesmesini documentation-only olarak netlestirdi.
- Mevcut dusuk seviyeli helper davranisinin korunmasina karar verildi: basarili yazim `Path` nesnesi dondurur, basarisiz yazim standart Python exception ile gorunur olur.
- String path donusu ve result dict donusu degerlendirildi; string path'in Python path islemleri icin daha zayif oldugu, result dict'in ise kullaniciya donuk katmanlarda faydali ama mevcut helper icin daha karmasik oldugu kaydedildi.
- Gelecekte result contract gerekiyorsa bunun mevcut helper return type'ini degistirmek yerine ayri wrapper/helper olarak planlanmasi daha guvenli karar olarak not edildi.
- Olasil future result contract alanlari `success`, `output_path`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` olarak belgelendi; bu adimda result object implementasyonu yapilmadi.
- Path safety hata kategorileri bos path, klasor path, yanlis uzanti, traversal, `allowed_root` disina cikma ve missing parent olarak ayrildi; bu durumlarin sessizce yutulmamasi gerektigi kararlastirildi.
- Input hata kategorileri non-dict JSON input, serialize edilemeyen JSON input, non-string Markdown input ve bos icerik politikasi olarak belgelendi.
- Overwrite hata davranisi `overwrite=False` ile hedef dosya varken yazmama ve gorunur hata, `overwrite=True` ile explicit basarili yazim olarak aciklandi.
- File system hata kategorileri izin hatasi, kilitli dosya ve disk/IO hatalari olarak belgelendi; mevcut asamada bu hatalar standart Python exception olarak yukari tasinabilir.
- Handover QC veya kullaniciya donuk gelecek katmanlar exception'lari okunur mesajlara cevirebilir; bu gorunurluk manuel inceleme icindir, devir paketini otomatik bloke etmez ve kayit reddi anlami tasimaz.
- File-writing helperlar diagnostic/soft validation sonucunu yeniden hesaplamayacak, format helper davranisini degistirmeyecek ve format helper ile file-writing helper ayrimi korunacak.
- Bu adim documentation-only error/result-contract plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 158 Export Helper Result Contract Implementation Plan

- Adim 158, Adim 157'de planlanan export helper error/result contract yaklasiminin ileride nasil uygulanabilecegini documentation-only olarak netlestirdi.
- Mevcut exception tabanli helper davranisi geriye uyumluluk icin korunacak; `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` basarida `Path` dondurmeye, hatada standart Python exception vermeye devam eden dusuk seviyeli helperlar olarak kalacak.
- Result contract icin mevcut helper return type'ini dogrudan degistirmek yerine ayri wrapper/helper katmani daha guvenli yaklasim olarak belgelendi.
- Olasil future wrapper/helper adlari `try_write_json_ready_dict_to_file(...)`, `try_write_markdown_text_to_file(...)` ve `build_export_write_result(...)` olarak yalnizca plan ornegi seviyesinde not edildi; implementasyon yapilmadi.
- Onerilen result contract alanlari `success`, `output_path`, `error_code`, `error_message`, `skipped_reason`, `overwritten`, `attempted_path`, `allowed_root` ve `file_type` olarak genisletildi.
- JSON ve Markdown file-writing sonuclari icin ortak result contract kullanilabilecegi, `file_type` ve `error_code` alanlariyla JSON'a ozel ve Markdown'a ozel hatalarin ayrilabilecegi kararlastirildi.
- Path safety hata kategorileri `empty_path`, `directory_target`, `wrong_extension`, `path_traversal`, `outside_allowed_root`, `missing_parent` ve `non_export_area` gibi future `error_code` degerleriyle temsil edilebilir.
- Input validation hatalari non-dict JSON input icin `invalid_json_input`, serialize edilemeyen JSON input icin `json_not_serializable`, non-string Markdown input icin `invalid_markdown_input` gibi future `error_code` degerleriyle temsil edilebilir.
- `overwrite=False` ve hedef dosya mevcutken future wrapper'in `success=False`, `error_code="file_exists"`, `skipped_reason="overwrite_false"` ve `overwritten=False` gibi bir result dondurmesi planlandi; mevcut dusuk seviyeli helper ise `FileExistsError` davranisini koruyabilir.
- Explicit `overwrite=True` basarili yazimda `success=True`, `output_path`, `overwritten` ve bos hata alanlariyla gorunur kilinabilir; hedef dosyanin yeni mi guncellenmis mi oldugu result icinde ayrilabilir.
- Parent directory yoklugu, allowed-root disi path, wrong extension, unserializable JSON input, non-string Markdown input, permission ve IO hatalari future result contract icinde sessizce yutulmadan temsil edilmelidir.
- Handover QC ekran veya raporu ileride result contract'i export denemesi, hedef path, basari/hata, overwrite engeli, allowed-root hatasi ve kullanici aksiyonu gorunurlugu icin kullanabilir; bu kullanim manuel inceleme amaclidir.
- Result contract audit event uretmeyecek, backup/restore baslatmayacak, database/repository/API/GUI/CLI eklemeyecek, hard validation yapmayacak, `blocked` status uretmeyecek, diagnostic/soft validation report'u yeniden hesaplamayacak ve format helper ile file-writing helper ayrimini bozmayacak.
- Bu adim documentation-only implementation-plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 159 Export Helper Result Contract Test Matrix Plan

- Adim 159, Adim 157-158'de planlanan export helper result contract yaklasimi ileride uygulanacaksa yazilacak testleri documentation-only olarak netlestirdi.
- Basari result contract testleri JSON ve Markdown export basarilarinda `success=True`, dogru `output_path`, dogru `file_type`, yeni dosyada `overwritten=False`, explicit overwrite senaryosunda `overwritten=True`, bos hata alanlari, normalize `attempted_path` ve dogru `allowed_root` beklentilerini kapsayacak.
- JSON input testleri JSON-ready dict basarisi, bos dict politikasi, non-dict input icin guvenli hata, serialize edilemeyen object icin hata contract'i, input immutability ve diagnostic/soft validation sonucunun yeniden hesaplanmamasini kapsayacak.
- Markdown input testleri string input basarisi, bos string politikasi, non-string input icin guvenli hata, Markdown iceriginin yeniden formatlanmamasi ve input immutability beklentilerini kapsayacak.
- Path safety testleri bos output path, klasor path, yanlis uzanti, `.json` / `.md` uzanti siniri, `..` traversal, allowed-root disi path, allowed-root ici basari, mixed separator, missing parent ve `.git`, `.env`, cache, pycache, ZIP/yedek alanlarina yazma reddi senaryolarini kapsayacak.
- Overwrite policy testleri hedef yokken `overwrite=False` basarisi, hedef varken `overwrite=False` yazmama, `success=False`, net `skipped_reason`, mevcut icerik korunumu, explicit `overwrite=True` guncellemesi ve yalniz hedef dosyanin degismesi beklentilerini kapsayacak.
- IO/permission testleri permission error, locked/erisilemez dosya ve disk/IO hata davranislarinin result contract'a sessiz basarisizlik olmadan tasinmasini planlayacak.
- Boundary regression testleri mevcut file-writing helper exception davranisinin korunmasini veya wrapper ile ayrilmasini, format helper davranislarinin degismemesini, diagnostic/soft validation report helper davranislarinin degismemesini, `AuditEventRecord.__post_init__` daraltilmamasini, `FileAttachmentRecord` davranisinin degismemesini, hard validation eklenmemesini ve `blocked` status uretilmemesini kapsayacak.
- Handover QC testleri hata contract'inin kullaniciya gosterilebilir veri tasimasini, `output_path` / `attempted_path` ayrimini, outside-allowed-root hatasini, `overwrite=False` skipped sonucunu, export basarisizliginin devir paketini otomatik bloke etmemesini ve audit event uretmemesini kapsayacak.
- Result contract alanlari icin `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` alanlarinin basari/hata durumlarindaki test anlamlari belgelendi.
- Bu adim documentation-only test-matrix-plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 160 Export Helper Result Contract API Boundary / Wrapper Plan

- Adim 160, mevcut exception tabanli file-writing helper davranisini bozmadan future result contract wrapper katmaninin nasil eklenebilecegini documentation-only olarak planladi.
- Mevcut `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlarinin dusuk seviyeli, exception tabanli ve basarida `Path` donduren davranisinin korunmasina karar verildi.
- Result contract icin mevcut helper return type'ini dogrudan degistirmek yerine ayri wrapper fonksiyonlar eklemek daha guvenli API boundary olarak belgelendi.
- Olasil future wrapper isimleri `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` olarak planlandi; bu adimda implementasyon yapilmadi.
- Wrapper result contract alanlari `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` olarak belirlendi.
- Wrapper inputlarinin mevcut helper inputlariyla uyumlu olmasi, diagnostic/soft validation sonucunu yeniden hesaplamamasi, format helper ciktisini degistirmemesi ve yalniz dosya yazma sonucunu raporlamasi kararlastirildi.
- Wrapper database/repository/API/GUI/CLI katmanina baglanmayacak, audit event uretmeyecek, backup/restore baslatmayacak, hard validation tetiklemeyecek ve `blocked` status uretmeyecek.
- Error mapping plani `TypeError -> input_type_error`, `ValueError -> path_or_extension_error`, `FileExistsError -> file_exists`, `PermissionError -> permission_error`, `OSError -> io_error` ve beklenmeyen exception icin `unexpected_error` olarak belgelendi.
- Ozel durumlar icin `overwrite=False` ve dosya mevcutken `success=False`, file-exists/skipped sonucu ve mevcut dosyanin korunmasi; `overwrite=True` basariliysa `success=True` ve `overwritten=True`; outside allowed root, path traversal, wrong extension ve parent missing icin net `error_code` beklentileri planlandi.
- Geriye uyumluluk icin mevcut `write_*` helperlar exception davranisini koruyacak, yeni `try_write_*` wrapperlar result contract dondurecek, eski testler kirilmayacak ve wrapper testleri ileride ayri eklenecek.
- Handover QC kullanimi wrapper sonucunu devir raporunda gorunur kilabilir; export basarisizligi otomatik blokaj, audit event, backup/restore veya hard validation anlami tasimayacak ve `blocked` status uretilmeyecek.
- Bu adim documentation-only API-boundary/wrapper-plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract wrapper implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.
