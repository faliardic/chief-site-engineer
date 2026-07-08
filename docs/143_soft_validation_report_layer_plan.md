# Adim 143 - Soft Validation Report Layer Plan

## Amac

Bu adimda `build_record_id_diagnostic_report(...)` ciktilarinin ileride kayit reddetmeyen soft validation report layer olarak nasil kullanilabilecegi planlandi.

Bu adim documentation-only adimidir. Soft validation helper implementasyonu yapilmadi.

## Soft validation report layer nedir?

Soft validation report layer, diagnostic report ciktisini kalite kontrol yorumu olarak kullanir.

Bu katman:

- Kayit reddetmez.
- Veri degistirmez.
- Constructor davranisini daraltmaz.
- Hard validation degildir.
- Kullaniciya veya gelistiriciye gorunur uyari saglar.

Soft validation report layer karar kapisi degil, gorunurluk ve yorum katmanidir.

## Diagnostic ile soft validation farki

### Diagnostic

Diagnostic katman ham diagnostic bilgi uretir.

Ornek:

- `info` itemlari.
- `warning` itemlari.
- `error` itemlari.
- Summary/count bilgisi.

Diagnostic katman karar vermez.

### Soft validation report

Soft validation report diagnostic sonuclari yorumlar.

Ornek yorumlar:

- Gozden gecir.
- Devir oncesi kontrol et.
- Legacy uyumlu ama izlenmeli.
- Veri kalitesi manuel incelenmeli.

Soft validation report yine kayit reddetmez.

## Kullanim alanlari

Soft validation report layer su alanlarda kullanilabilir:

- Handover on kontrol.
- Audit QC raporu.
- Export/backup oncesi risk gorunurlugu.
- Admin/debug kalite raporu.
- Migration oncesi veri sagligi incelemesi.
- Test example standardization gozden gecirme.

Bu alanlarda soft validation raporu uyarilari gorunur yapar, otomatik karar vermez.

## Kullanilmayacagi alanlar

Soft validation report layer su alanlarda kullanilmayacak:

- `AuditEventRecord.__post_init__`.
- Constructor validation.
- Hard validation.
- Kayit olusturmayi engelleme.
- Legacy kayitlari reddetme.
- Otomatik data correction.
- Migration uygulama adimi.
- Database/repository yazimi.
- Audit event olusturma.
- `FileAttachmentRecord` davranisi degistirme.

## Olası ilerideki helper adi

Ileride su helper adi degerlendirilebilir:

- `build_record_id_soft_validation_report(...)`

Bu adimda bu fonksiyon eklenmedi.

Bu adim yalnizca soft validation report layer sinirini planlar.

## Olası soft validation cikti seviyeleri

### pass

`pass`, sadece `info` / canonical uyumlu kayitlar oldugunda kullanilabilecek plan seviyesidir.

Bu durum normal gorunurluk anlamina gelir.

### review

`review`, `warning` itemlari oldugunda kullanilabilecek plan seviyesidir.

Bu kayit reddi degildir. Gozden gecirme gerektigini anlatir.

### attention

`attention`, `error` itemlari oldugunda kullanilabilecek plan seviyesidir.

Rapor uretilmistir fakat veri kalitesi manuel incelenmelidir. Otomatik silme, duzeltme veya migration sebebi degildir.

### blocked

`blocked` bu asamada kullanilmayacak seviyedir.

Bu kelime hard validation veya engelleme anlamina kayabilecegi icin soft validation report layer icinde kullanilmamalidir.

## Severity yorumlama standardi

Soft validation report layer severity anlamlarini degistirmemelidir:

- `info`: normal/canonical uyumlu kayit.
- `warning`: legacy veya prefix disi ama reddedilmeyen kayit.
- `error`: helper seviyesinde diagnostic sorunu.

`warning`, soft validation icinde `review` sebebi olabilir.

`warning` kayit reddi degildir.

`error`, soft validation icinde `attention` sebebi olabilir.

`error` otomatik silme veya duzeltme sebebi degildir.

## Handover yorumlama standardi

Soft validation raporu devir teslimde:

- Eksikleri gorunur yapar.
- Warning/error kayitlarini listeler.
- Yeni santiye sefine risk notu saglar.
- Devir paketini otomatik bloke etmez.
- Hard validation tetiklemez.

Handover yorumunda uyarilar "devre engel" degil, "gozden gecirilecek kayit" olarak ele alinmalidir.

## Export/backup yorumlama standardi

Soft validation raporu export/backup oncesinde:

- Veri kalitesi risklerini gosterir.
- Exportu otomatik durdurmaz.
- Backup/restore davranisini degistirmez.
- Sadece "once gozden gecir" uyarisi saglar.

Export/backup yorumlamasi veri davranisini degistirmez.

## Gelecek guvenli sira

Guvenli sira soyle korunur:

- Adim 143: soft validation report layer plan.
- Adim 144: soft validation report API boundary / test matrix plan.
- Adim 145: read-only soft validation report implementation.
- Adim 146: usage documentation / handover QC interpretation.
- Adim 147: format/export helper plan.
- Podcast 023: Adim 137-142 veya uygun aralik kararina gore ayrica planlanmali.
- Hard validation en sona birakilir.

Podcast kurali her 5 adimda bir uygulanacaksa mevcut seri icin Podcast 023 kapsami ayrica kontrol edilmelidir. Bu adimda Podcast 023 olusturulmadi.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Soft validation bu adimda implement edilmeyecek.
- Soft validation ileride bile once read-only/reporting katmani olarak kalacak.
- `FileAttachmentRecord` davranisina dokunulmayacak.
- Podcast 023 bu adimda olusturulmadi.

## Sonuc

Adim 143, diagnostic report ciktisinin ileride soft validation report olarak nasil yorumlanabilecegini planladi.

Bu plan kayit reddi, veri degisikligi, constructor validation, migration, otomatik duzeltme veya hard validation baslatmaz.
