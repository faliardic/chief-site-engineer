# Roadmap

## Guncel Guvenli Nokta

```text
Adim 140 - Read-only record ID diagnostic report helper implementation
```

Adim 127'de README, ROADMAP, CHANGELOG, proje kararlari, ZIP repo politikasi, satir sonu tercihi, test sonucu ve diff kontrolu guvenli nokta icin guncellendi.

Adim 128'de `FileAttachmentRecord` required metadata validation guclendirildi.

Adim 129-131 araliginda audit `target_record_id` hard validation eklenmeden once record ID envanteri, central record ID contract ve mapping helper planlari hazirlandi.

Adim 132'de hard validation eklenmeden record ID constants ve bilgi donen target type mapping helperlari eklendi.

Adim 133'te bu helper API'sinin validation fonksiyonu gibi kullanilmayacagi ve test ornek standardizasyonunun ayri adimlarla ilerleyecegi dokumante edildi.

Adim 134'te record ID soft validation'in yalnizca diagnostic / uyari katmani olarak planlanacagi ve hard validation'a henuz gecilmeyecegi belgelendi.

Adim 135'te record ID diagnostic helper'in dis kalite kontrol / raporlama katmani icin nasil tasarlanacagi planlandi; constructor veya hard validation kapisi olarak kullanilmayacagi netlestirildi.

Adim 136'da `diagnose_record_id_for_target_type` helper'i eklendi; helper canonical, legacy, prefix disi ve helper giris hatasi durumlari icin diagnostic dict dondurur, fakat veri reddetmez.

Podcast 022'de Adim 132-136 araligi NotebookLM icin ozetlendi; record ID mapping, helper API siniri, soft validation, diagnostic helper ve hard validation ertelemesi dokumante edildi.

Adim 137'de `diagnose_record_id_for_target_type` helper'inin nerede kullanilabilecegi ve nerede kullanilmamasi gerektigi belgelendi; helper'in saf diagnostic fonksiyon olarak kalacagi ve hard validation'a baglanmayacagi netlestirildi.

Adim 138'de tekil diagnostic helper'in ileride read-only toplu `build_record_id_diagnostic_report(...)` benzeri rapor helper'ina nasil donusebilecegi planlandi; kayit reddi, veri degisikligi, migration ve hard validation yine kapsam disinda tutuldu.

Adim 139'da olasi diagnostic report helper icin API boundary, saf Python input yaklasimi, output sozlesmesi ve test example matrix planlandi; helper'in read-only ve hard validation disi kalacagi yinelendi.

Adim 140'da `build_record_id_diagnostic_report(records)` helper'i read-only olarak eklendi; toplu diagnostic summary uretir, kayit reddetmez, veri degistirmez ve hard validation'a baglanmaz.

Adim 101'de proje genel kalite, mimari tutarlilik, dokumantasyon butunlugu, test kapsami, roadmap uyumu ve sonraki 20 adim stratejisi acisindan denetlendi.

Guncel test durumu:

```text
262 passed
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

## Faz 101-140 - Denetim, Attachment Integrity Export, Scanner, Audit Hazirligi ve ID Kararlari

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
- [x] Adim 111 - Attachment integrity rapor kullanim ozeti.
- [x] Adim 112 - Audit event model plani.
- [x] Adim 113 - AuditEventRecord baslangic modeli.
- [x] Adim 114 - Audit event validation testleri.
- [x] Adim 115 - Audit event type sozlesmesi dokumantasyonu.
- [x] Adim 116 - Audit event type validation veya sabit sozlesme implementasyonu.
- [x] Adim 117 - Audit event target record iliski kurallari dokumantasyonu.
- [x] Adim 118 - Audit event target record pair validation.
- [x] Adim 119 - Audit event target record type sozlesmesi dokumantasyonu.
- [x] Adim 120 - Audit event target record type sabitleri ve validation.
- [x] Adim 121 - Audit event target record id format tasarimi.
- [x] Adim 122 - Audit event target record id validation tasarimi.
- [x] Adim 123 - Podcast 017: Adim 097-102 NotebookLM podcast notu.
- [x] Podcast 018 - Adim 103-108 NotebookLM podcast notu.
- [x] Podcast 019 - Adim 109-114 NotebookLM podcast notu.
- [x] Podcast 020 - Adim 115-120 NotebookLM podcast notu.
- [x] Adim 127 - Guvenli nokta kalite kontrol, dokumantasyon temizligi, ZIP repo politikasi ve LF satir sonu tercihi.
- [x] Adim 128 - FileAttachmentRecord validation bosluklarini kapatma.
- [x] Adim 129 - Record ID envanteri ve audit target_record_id validation risk analizi; dogrudan validation uygulanmadi.
- [x] Adim 130 - Central record ID contract plan; dogrudan validation uygulanmadi.
- [x] Adim 131 - Record ID constants and mapping helper plan; hard validation uygulanmadi.
- [x] Podcast 021 - Adim 127-131 NotebookLM podcast notu.
- [x] Adim 132 - Record ID constants and mapping helper implementation; hard validation uygulanmadi.
- [x] Adim 133 - Record ID helper API boundary and test example standardization plan; hard validation uygulanmadi.
- [x] Adim 134 - Record ID soft validation plan; hard validation uygulanmadi.
- [x] Adim 135 - Record ID soft validation diagnostic helper implementation plan; hard validation uygulanmadi.
- [x] Adim 136 - Record ID diagnostic helper implementation; veri reddetmeyen diagnostic katmani eklendi, hard validation uygulanmadi.
- [x] Podcast 022 - Adim 132-136 NotebookLM podcast notu; record ID diagnostic hattinin neden hard validation'a baglanmadigi ozetlendi.
- [x] Adim 137 - Record ID diagnostic helper usage boundary plan; helper'in dis QC/raporlama kullanimi ve constructor/hard validation disi siniri belgelendi.
- [x] Adim 138 - Record ID diagnostic report helper plan; ilerideki read-only toplu diagnostic rapor helper'i planlandi, implementasyon yapilmadi.
- [x] Adim 139 - Record ID diagnostic report API boundary and test matrix plan; input/output sozlesmesi ve test kategorileri belgelendi.
- [x] Adim 140 - Read-only record ID diagnostic report helper implementation; toplu diagnostic rapor helper'i eklendi, hard validation uygulanmadi.

Bu fazda hedef, Adim 101 denetim bulgularini kucuk ve test edilebilir parcalara bolerek once dokumantasyon guncelligini, sonra attachment integrity export/scanner hattini, ardindan audit ve private workspace modelleme zeminini guclendirmektir.

## Sonraki Calisma Onerisi

Adim 141 icin record ID diagnostic report edge case standardization veya test example standardization ele alinabilir. Hard validation henuz eklenmemelidir.
