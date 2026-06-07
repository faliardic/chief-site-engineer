# Roadmap

## Guncel Guvenli Nokta

```text
Adim 080 - FileAttachmentRecord metadata butunluk ozeti
```

Adim 081'de `README.md`, Adim 080 guvenli noktasindaki gercek repo durumuna gore guncellendi.

Guncel test durumu:

```text
125 passed
```

Proje su anda domain model, bellek ici repository, test, dokumantasyon, learning ve NotebookLM podcast notlari cekirdegi seviyesindedir.

## Henuz Olmayan Uretim Ozellikleri

Asagidaki ozellikler henuz eklenmedi:

- Database yok.
- Gercek upload servisi yok.
- API yok.
- GUI yok.
- Auth / kullanici / rol / yetki sistemi yok.
- CI yok.
- Deployment yok.
- JSON veya SQLite persistence yok.
- Gercek dosya kopyalama, silme veya tasima yok.
- Thumbnail, preview, video oynatma veya streaming yok.

Bu sinir bilincli olarak korunuyor. Once model, test, dokumantasyon ve karar hatti netlestiriliyor.

## Tamamlanan Ana Fazlar - Adim 001-080

### Faz 001-020 - Temel Santiye Model Cekirdegi

- [x] Adim 001-004 - Repo disiplini, cekirdek modeller, gunluk saha kaydi ve basit bellek ici listeleme.
- [x] Adim 005-010 - Beton dokum, yapi denetim, uygunsuzluk, ek dosya, malzeme ve toplanti/aksiyon modelleri.
- [x] Adim 011-020 - RFI/submittal, gunluk rapor, proje tarafi, lokasyon, ekip, ekipman, tedarikci, saha notu, gorev adayi ve kontrol maddesi modelleri.

### Faz 021-030 - Uygunsuzluk Adayi Sureci

- [x] Adim 021-025 - Kontrol sonucu, uygunsuzluk adayi, degerlendirme, aksiyon ve takip ozeti modelleri.
- [x] Adim 026 - Mevcut `AttachmentRecord` ile uygunsuzluk adayi ek dosya baglantisi.
- [x] Adim 027-030 - Uygunsuzluk adayi surec gorunumu, durum gecmisi, sorumluluk/atama ve kapanis/sonuc modelleri.

### Faz 031-040 - Kesin Uygunsuzluk / NCR Model Hatti

- [x] Adim 031 - Adim 026-030 NotebookLM podcast notu.
- [x] Adim 032 - Aday kayittan kesin uygunsuzluga donusum modeli.
- [x] Adim 033-034 - `NonconformityRecord` degerlendirme ve alan revizyonu.
- [x] Adim 035-040 - NCR surec gorunumu, durum gecmisi, sorumluluk, duzeltici faaliyet, dogrulama ve kapatma modelleri.

### Faz 041-055 - NonconformityRepository Bellek Ici Davranislari

- [x] Adim 041-045 - NCR repository baslangici, duplicate id kontrolu, status/sorumlu filtreleme ve durum ozeti.
- [x] Adim 046-050 - Sorumlu ozeti, genel ozet, status/sorumlu guncelleme ve kayit var mi kontrolu.
- [x] Adim 051-055 - Kayit sayisi, arsiv alani, aktif/arsiv filtreleri, archive ve restore davranislari.

### Faz 056-060 - NCR Arsiv / Listeleme Tutarliligi

- [x] Adim 056 - NCR arsiv ozeti.
- [x] Adim 057-059 - Arsivlenmis, aktif ve tum kayit listeleme davranislari.
- [x] Adim 060 - Arsiv, restore, listeleme ve ozet butunluk kontrolu.

### Faz 061-070 - Arama / Filtreleme ve Dosya Eki Temeli

- [x] Adim 061-063 - Podcast notu, NCR arsiv/listeleme kullanim ozeti ve arama plani.
- [x] Adim 064-066 - Id, durum ve konuma gore NCR kayit bulma/filtreleme davranislari.
- [x] Adim 067-070 - Dosya/video eki plani, `FileAttachmentRecord`, dosya tipi siniflandirmasi ve iliskili kayit baglantisi.

### Faz 071-080 - FileAttachmentRecord Metadata ve Kapanis

- [x] Adim 071 - Adim 061-070 NotebookLM podcast notu.
- [x] Adim 072-075 - Dosya eki kullanim akisi, ornek senaryolar, saklama/adlandirma standardi ve arsiv guvenligi kararları.
- [x] Adim 076-079 - `original_file_name`, `uploaded_by`, `uploaded_at` ve `notes` metadata netlestirmeleri.
- [x] Adim 080 - File attachment metadata butunluk ozeti ve derin analiz oncesi kapanis.

## Faz 081-090 - Duzeltme, Standart Kilitleme ve Dokumantasyon Esitleme

- [x] Adim 081 - README guncellemesi: Adim 080 guvenli noktasi, 125 test, mevcut kapsam ve olmayan ozellikler.
- [x] Adim 082 - ROADMAP guncellemesi: Adim 080 sonrasi gercek durum ve 081-100 faz plani.
- [x] Adim 083 - Attachment model karari: `FileAttachmentRecord` ana model, `AttachmentRecord` legacy model.
- [x] Adim 084 - `FileAttachmentRecord` alan sozlesmesi: model-level optional, service-level required ayrimi.
- [ ] Adim 085 - Learning dosyalari kapsami ve glossary esitleme kontrolu.
- [ ] Adim 086 - README / ROADMAP / CHANGELOG tutarlilik testi veya kontrol dokumani.
- [ ] Adim 087 - NotebookLM podcast notlari 071-080 final dosyasi.
- [ ] Adim 088 - Paketleme ve derin analiz girdi listesi standardi.
- [ ] Adim 089 - Derin analiz bulgulari icin karar taslagi.
- [ ] Adim 090 - Duzeltme fazi kapanis ozeti.

Bu fazda hedef yeni urun ozelligi eklemek degil; mevcut dokumantasyon ve proje standartlarini kilitlemektir.

## Faz 091-100 - Persistence, Upload, Integrity ve Operasyon Omurgasi

- [ ] Adim 091 - Persistence strateji karari: JSON mu SQLite mi, hangi sirayla?
- [ ] Adim 092 - Repository persistence arayuzu veya plan dokumani.
- [ ] Adim 093 - FileAttachmentRepository baslangic plani veya bellek ici baslangic.
- [ ] Adim 094 - Dosya upload servisi tasarim karari.
- [ ] Adim 095 - Dosya varlik / integrity scanner plan veya baslangic davranisi.
- [ ] Adim 096 - Attachment audit trail modeli veya karar dokumani.
- [ ] Adim 097 - NCR + attachment iliskisi icin integrity kontrolu.
- [ ] Adim 098 - Test kapsami genisletme ve regresyon stratejisi.
- [ ] Adim 099 - CI stratejisi: pytest otomasyonu ve kalite kapisi.
- [ ] Adim 100 - Operasyon omurgasi kapanis ozeti ve sonraki faz karari.

Bu fazda hedef, domain model ve dokumantasyon cekirdeginden kontrollu persistence, upload, integrity, audit ve CI omurgasina gecis icin kucuk ve testli adimlar atmaktir.

## Sonraki Calisma Onerisi

Adim 085 ile learning dosyalari kapsami ve glossary esitleme kontrolu baslatilabilir.
