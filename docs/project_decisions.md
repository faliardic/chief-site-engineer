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
