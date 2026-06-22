# Roadmap

## Guncel Guvenli Nokta

```text
Adim 100 - Guvenli nokta final kalite kontrol
```

Adim 081-100 arasindaki duzeltme, standart kilitleme, attachment integrity, veri politikasi, podcast notu ve final kalite kontrol hatti GitHub'a pushlandi.

Adim 101'de proje genel kalite, mimari tutarlilik, dokumantasyon butunlugu, test kapsami, roadmap uyumu ve sonraki 20 adim stratejisi acisindan denetlendi.

Guncel test durumu:

```text
208 passed
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
- [x] Adim 085 - Canonical attachment path standardi: `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}`.
- [x] Adim 086 - `FileType` ve `AttachmentStatus` hafif enum hazirligi.
- [x] Adim 087 - `FileAttachmentRecord` temel validation testleri ve minimal `ValueError` davranisi.
- [x] Adim 088 - Canonical attachment path helper fonksiyonu.
- [x] Adim 089 - Attachment metadata integrity kurallari ve missing/orphan scanner tasarim zemini.
- [x] Adim 090 - Attachment integrity status sabitleri baslangici.

Bu fazda hedef yeni urun ozelligi eklemek degil; mevcut dokumantasyon ve proje standartlarini kilitlemektir.

## Faz 091-100 - Persistence, Upload, Integrity ve Operasyon Omurgasi

- [x] Adim 091 - Attachment integrity result modeli baslangici.
- [x] Adim 092 - Attachment integrity single-record check helper baslangici.
- [x] Adim 093 - Attachment integrity report summary modeli.
- [x] Adim 094 - Attachment integrity report modeli.
- [x] Adim 095 - Attachment integrity report serializer baslangici.
- [x] Adim 096 - Ana proje ilkeleri, veri silme onleme ve ozel alan izolasyon politika dokumanlari.
- [x] Adim 097 - Adim 071-080 NotebookLM podcast notu.
- [x] Adim 098 - Adim 081-090 NotebookLM podcast notu.
- [x] Adim 099 - Adim 091-096 NotebookLM podcast notu.
- [x] Adim 100 - Guvenli nokta final kalite kontrol ve push hazirligi.

Bu fazda hedef, domain model ve dokumantasyon cekirdeginden kontrollu persistence, upload, integrity, audit ve CI omurgasina gecis icin kucuk ve testli adimlar atmaktir.

## Faz 101-121 - Denetim, Attachment Integrity Export, Scanner ve Audit Hazirligi

- [x] Adim 101 - Genel proje denetimi ve mimari saglik raporu.
- [x] Adim 102 - README guncellik duzeltmesi: Adim 100 / 191 test ve yeni kapsam bilgisi.
- [x] Adim 103 - Attachment integrity JSON string export helper.
- [x] Adim 104 - Attachment integrity JSON file export tasarim dokumani.
- [x] Adim 105 - Attachment integrity JSON file export helper ve testleri.
- [x] Adim 106 - CSE urun vizyonu ve saha hafizasi stratejisi.
- [x] Adim 107 - Scanner scope plani.
- [x] Adim 108 - Scanner input modeli / plani.
- [x] Adim 109 - Attachment scanner dry-run helper baslangici.
- [x] Adim 110 - Scanner dry-run testleri / kullanim netlestirmesi.
- [ ] Adim 111 - Attachment integrity rapor kullanim ozeti.
- [ ] Adim 112 - Audit event model plani.
- [ ] Adim 113 - AuditEventRecord baslangic modeli.
- [ ] Adim 114 - Audit event validation testleri.
- [ ] Adim 115 - Official record / private workspace model plani.
- [ ] Adim 116 - PrivateWorkspaceRecord baslangic modeli.
- [ ] Adim 117 - HandoverPackageRecord plani.
- [ ] Adim 118 - HandoverPackageRecord baslangic modeli.
- [ ] Adim 119 - Hard delete prevention model contract dokumantasyonu.
- [ ] Adim 120 - Test dosyasi bolme plani.
- [ ] Adim 121 - 101-121 guvenli nokta kalite kontrol ve podcast kapanisi.

Bu fazda hedef, Adim 101 denetim bulgularini kucuk ve test edilebilir parcalara bolerek once dokumantasyon guncelligini, sonra attachment integrity export/scanner hattini, ardindan audit ve private workspace modelleme zeminini guclendirmektir.

## Sonraki Calisma Onerisi

Adim 111 ile attachment integrity rapor kullanim ozeti ele alinabilir.
