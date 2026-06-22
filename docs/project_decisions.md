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
