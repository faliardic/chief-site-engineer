# Adim 146 - Soft Validation Report Usage and Handover QC Interpretation

Bu adimda `build_record_id_soft_validation_report(...)` helper'inin kullanim siniri, handover QC yorumlama standardi ve status alanlarinin pratik anlami belgelendi.

Bu adim documentation-only adimidir.

Kod veya test davranisi degistirilmedi.

## Helper ne ise yarar?

`build_record_id_soft_validation_report(...)` diagnostic report dict alir.

Beklenen input:

```text
build_record_id_diagnostic_report(records)
```

Helper read-only soft validation report dict dondurur.

Helper su status degerlerini uretir:

- `pass`
- `review`
- `attention`

`blocked` status'u uretmez.

Helper kayit reddetmez, veri degistirmez, hard validation yapmaz ve constructor davranisini daraltmaz.

## Status yorumlama standardi

### pass

`pass`, diagnostic report icinde warning veya error gorunmedigini anlatir.

Pratik anlam:

- Kayitlar canonical veya normal gorunur.
- Ek aksiyon gerekmez.
- Handover checklist icin bilgilendirici basarili sonuc olarak okunabilir.

`pass`, otomatik onay veya kalici uygunluk garantisi degildir.

### review

`review`, diagnostic report icinde warning oldugunu ve error olmadigini anlatir.

Pratik anlam:

- Legacy ID veya prefix disi ama reddedilmeyen kayit gorunur olabilir.
- Manuel gozden gecirme gerekir.
- Handover checklist icin "gozden gecirilecek kayit" sinyali uretir.

`review`, kayit reddi degildir.

### attention

`attention`, diagnostic report icinde error oldugunu veya soft validation input yapisinin eksik/uygunsuz oldugunu anlatir.

Pratik anlam:

- Manuel inceleme gerekir.
- Eksik veya supheli ID baglantilari gorunur hale gelir.
- Handover veya audit QC icin oncelikli inceleme sinyali verir.

`attention`, otomatik silme, otomatik duzeltme, migration veya kayit reddi sebebi degildir.

### blocked

`blocked` uretilmez.

Bu status hard validation veya islem engelleme anlami dogurabilecegi icin soft validation report hattinda bu asamada disarida tutulur.

## Handover QC yorumlama standardi

Soft validation report devir teslim oncesinde veri sagligi gorunurlugu saglar.

Handover QC icinde:

- Yeni santiye sefine record ID baglanti sagligi hakkinda ozet gorunurluk saglar.
- Warning ve error kayitlarini gorunur yapar.
- Eksik veya supheli ID baglantilarini listelemeye yardim eder.
- Handover checklist icin "gozden gecirilecek kayitlar" uretir.
- Devir paketini otomatik bloke etmez.
- Hard validation tetiklemez.

Bu rapor karar kapisi degildir.

Handover sorumlusu raporu okur, yorumlar ve gerekirse manuel kontrol yapar.

## Audit QC yorumlama standardi

Audit QC icinde soft validation report, `target_record_type` ve `target_record_id` uyum riskini gorunur yapar.

Audit QC kullaniminda:

- Legacy kayitlar reddedilmez.
- Prefix disi kayitlar warning veya attention baglaminda yorumlanir.
- `AuditEventRecord.__post_init__` icine baglanmaz.
- Audit event olusturmaz.
- Audit log veya model davranisi degistirmez.

Bu cikti denetim gorunurlugu saglar; otomatik audit aksiyonu uretmez.

## Export / backup oncesi yorumlama

Export veya backup oncesinde soft validation report veri kalitesi risklerini gorunur yapabilir.

Bu kullanimda:

- Export otomatik durdurulmaz.
- Backup veya restore davranisi degistirilmez.
- Dosya sistemi islemi yapilmaz.
- Kullaniciya veya gelistiriciye risk gorunurlugu saglanir.

Soft validation report, export/backup surecinin teknik kapisi degildir.

## Kullanilabilecegi alanlar

- Handover on kontrol.
- Audit QC.
- Export/backup oncesi risk gorunurlugu.
- Admin/debug raporu.
- Migration oncesi veri sagligi incelemesi.
- Test example standardization.

## Kullanilmayacagi alanlar

- `AuditEventRecord.__post_init__`.
- Constructor validation.
- Hard validation.
- Kayit olusturmayi engelleme.
- Legacy kayitlari reddetme.
- Otomatik data correction.
- Migration uygulama adimi.
- Database/repository yazimi.
- Audit event olusturma.
- `FileAttachmentRecord` davranisini degistirme.
- API/GUI/CLI entegrasyonu.

## Message ve summary yorumlama

`messages` alani kisa okunur aciklama saglar.

`summary` alani karar vermez; yalnizca gorunurluk saglar.

`warning_count` ve `error_count` hard validation tetiklemez.

`review_required` ve `attention_required` kullanici veya gelistirici uyarisi olarak okunur.

Bu alanlar kayit reddi, otomatik duzeltme, otomatik silme veya migration anlami tasimaz.

## Gelecek guvenli sira

1. Adim 146: usage documentation / handover QC interpretation.
2. Podcast 024: Adim 142-146 araligi icin NotebookLM podcast notu.
3. Adim 147: diagnostic/soft validation format helper plan.
4. Adim 148: format helper implementation.
5. Adim 149: handover QC summary layer plan.
6. Hard validation en sona birakilir.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- `build_record_id_soft_validation_report(...)` davranisi degistirilmeyecek.
- `blocked` status uretilmeyecek.
- Soft validation read-only/reporting katmani olarak kalacak.
- Podcast 024 bu adimda olusturulmadi.

## Sonuc

Adim 146, soft validation report helper'in nasil okunacagini ve hangi is kararlarina donusturulmeyecegini netlestirdi.

Bu sinir, handover ve audit QC gorunurlugunu arttirirken hard validation'a erken gecisi engeller.

