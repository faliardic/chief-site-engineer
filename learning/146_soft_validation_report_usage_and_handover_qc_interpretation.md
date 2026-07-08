# Adim 146 - Soft Validation Report Usage and Handover QC Interpretation

Bu adimda kod yazmadik.

Amacimiz, Adim 145'te eklenen `build_record_id_soft_validation_report(...)` helper'inin nasil okunacagini ve nerelerde kullanilmamasi gerektigini netlestirmekti.

## Ana fikir

Soft validation report karar kapisi degildir.

Bir kaydi reddetmez.

Veriyi degistirmez.

Hard validation degildir.

Sadece kalite kontrol gorunurlugu saglar.

## Status anlamlari

`pass`:

- Warning yok.
- Error yok.
- Ek aksiyon gerekmez.

`review`:

- Warning var.
- Genellikle legacy veya prefix disi ama reddedilmeyen kayitlari isaret eder.
- Manuel gozden gecirme gerekir.
- Kayit reddi degildir.

`attention`:

- Error var veya input/diagnostic yapi eksik.
- Manuel inceleme gerekir.
- Otomatik silme veya duzeltme sebebi degildir.
- Kayit reddi degildir.

`blocked`:

- Uretilmez.
- Hard validation veya engelleme anlami dogurabilecegi icin disarida kalir.

## Handover QC icin ders

Handover surecinde rapor yeni santiye sefine veri sagligi gorunurlugu verir.

Rapor warning/error kayitlarini gorunur yapar.

Ama devir paketini otomatik bloke etmez.

Bu, insan denetimini koruyan guvenli bir ara katmandir.

## Audit QC icin ders

Audit QC icinde soft validation report, `target_record_type` ve `target_record_id` uyum riskini gosterir.

Legacy kayitlari reddetmez.

Audit event olusturmaz.

`AuditEventRecord.__post_init__` icine baglanmaz.

## Export ve backup icin ders

Export veya backup oncesi rapor risk gorunurlugu saglayabilir.

Fakat exportu durdurmaz.

Backup/restore davranisini degistirmez.

Dosya sistemi islemi yapmaz.

## Summary ve message alanlari

`messages`, kisa okunur aciklama saglar.

`summary`, sadece sayisal gorunurluk saglar.

`warning_count` ve `error_count`, hard validation tetiklemez.

`review_required` ve `attention_required`, kullanici/geliştirici uyarisi olarak okunur.

Bu alanlar otomatik duzeltme veya kayit reddi anlamina gelmez.

## Kullanilmamasi gereken yerler

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

## Degismeyen kararlar

- Hard validation eklenmedi.
- `AuditEventRecord.__post_init__` degismedi.
- `build_record_id_diagnostic_report(...)` davranisi degismedi.
- `build_record_id_soft_validation_report(...)` davranisi degismedi.
- `blocked` status eklenmedi.
- `FileAttachmentRecord` davranisi degismedi.
- Podcast 024 olusturulmadi.

## Kapanis

Adim 146, soft validation report helper'in isletme yorumunu netlestirdi.

Bu adimdan sonra Podcast 024, Adim 142-146 araligini NotebookLM icin ozetleyebilir.

