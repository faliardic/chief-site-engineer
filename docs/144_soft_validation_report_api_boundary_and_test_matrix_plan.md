# Adim 144 - Soft Validation Report API Boundary and Test Matrix Plan

## Amac

Bu adimda Adim 143'te planlanan soft validation report layer icin API boundary, input/output sozlesmesi, status/severity yorumlama kurali ve test matrix plani olusturuldu.

Bu adim documentation-only adimidir. Soft validation helper implementasyonu yapilmadi.

## Olasi helper adi

Ileride su helper adi degerlendirilebilir:

- `build_record_id_soft_validation_report(...)`

Bu adimda bu fonksiyon eklenmedi.

Bu adim yalnizca API boundary ve test matrix planidir.

## API boundary

Soft validation report helper ileride diagnostic report ciktisini yorumlayan read-only raporlama katmani olarak kalmalidir.

Helper ileride:

- Diagnostic report dict alabilir.
- `build_record_id_diagnostic_report(...)` ciktisini yorumlayabilir.
- Read-only soft validation report dict dondurebilir.
- Kayit reddetmez.
- Veri degistirmez.
- Hard validation yapmaz.
- Constructor davranisini daraltmaz.
- Database/repository yazmaz.
- Audit event olusturmaz.
- Migration veya otomatik duzeltme yapmaz.
- Dosya sistemi, backup, restore veya export uretmez.

Bu sinir, helper'in validation kapisina veya otomatik islem katmanina donusmesini engeller.

## Olasi input sozlesmesi

Ilk guvenli yaklasim, helper'in diagnostic report dict almasidir.

Diagnostic report dict, `build_record_id_diagnostic_report(records)` ciktisi olabilir.

Bu yaklasimda helper:

- Record listesi almaz.
- Repository veya database sorgusu almaz.
- Model bagimliligi eklemez.
- Diagnostic sonucu yeniden hesaplamaz.
- Input validation'i hard validation'a donusturmez.

Alternatif olarak ileride records input alip iceride diagnostic report olusturma planlanabilir. Ancak bu ilk implementasyon icin daha genis bir sorumluluk olur ve ayri planlanmalidir.

## Olasi output sozlesmesi

Soft validation report dict su alanlari tasiyabilir:

- `status`
- `total_count`
- `compatible_count`
- `warning_count`
- `error_count`
- `review_required`
- `attention_required`
- `messages`
- `items`
- `summary`

Output, diagnostic report count ve item bilgisini yorumlar; input verisini degistirmez.

## Status seviyeleri

### pass

`pass` status'u su durumda uretilebilir:

- `error_count` degeri `0`.
- `warning_count` degeri `0`.
- Sadece `info` / canonical uyumlu kayitlar var.

Bu status normal rapor gorunurlugudur.

### review

`review` status'u su durumda uretilebilir:

- `warning_count > 0`.
- `error_count == 0`.
- Gozden gecirme gerekir.

Bu kayit reddi degildir.

### attention

`attention` status'u su durumda uretilebilir:

- `error_count > 0`.
- Manuel inceleme gerekir.

Bu otomatik silme veya duzeltme sebebi degildir. Kayit reddi degildir.

### blocked

`blocked` bu asamada uretilmeyecek.

Bu seviye engelleme veya hard validation anlami dogurabilecegi icin soft validation report layer icinde bu asamada disarida kalir.

## Status onceligi

Status onceligi soyle planlanir:

1. `attention`
2. `review`
3. `pass`

Yani error varsa status `attention` olur. Error yok ama warning varsa status `review` olur. Error ve warning yoksa status `pass` olur.

## Test matrix plani

Ilerideki implementasyon icin en az su test kategorileri planlanmalidir:

| Kategori | Amac |
| --- | --- |
| Bos diagnostic report | Bos raporun guvenli ve read-only yorumlandigini dogrulamak. |
| Sadece info itemlari | `pass` status'unu dogrulamak. |
| Warning itemi var, error yok | `review` status'unu dogrulamak. |
| Error itemi var | `attention` status'unu dogrulamak. |
| Warning + error birlikte | `attention` onceligini dogrulamak. |
| Status onceligi | `attention > review > pass` siralamasini dogrulamak. |
| `review_required` mantigi | Warning durumunda `True`, sadece pass durumunda `False` davranisini dogrulamak. |
| `attention_required` mantigi | Error durumunda `True`, error yokken `False` davranisini dogrulamak. |
| Summary count korunumu | Diagnostic report count degerlerinin soft validation report icinde korunmasini dogrulamak. |
| Items listesi korunumu | Item listesinin karar icin okunup mutate edilmedigini dogrulamak. |
| Input immutability | Diagnostic report dict ve nested itemlarin degismedigini dogrulamak. |
| Eksik diagnostic report alanlari | Eksik alanlarin kontrollu diagnostic/report sinyaliyle ele alinmasini planlamak. |
| Uygunsuz input tipi | Exception yerine guvenli hata raporu veya kontrollu davranis planlamak. |
| Unknown severity degeri | Bilinmeyen severity degerinin hard validation'a donusmeden ele alinmasini planlamak. |
| Warning veri reddi degildir | Warning itemlarinin kayit reddine yol acmadigini dogrulamak. |
| Error otomatik duzeltme degildir | Error itemlarinin otomatik silme/duzeltme baslatmadigini dogrulamak. |
| `blocked` uretilmez | Status'un hicbir senaryoda `blocked` olmadigini dogrulamak. |

Bu test matrix implementasyon oncesi siniri sabitler.

## Severity/status yorumlama standardi

### info

`info`, `pass` icinde normal kayit olarak gorunur.

### warning

`warning`, `review` sebebidir.

`warning` kayit reddi degildir.

### error

`error`, `attention` sebebidir.

`error` otomatik duzeltme veya silme sebebi degildir.

### blocked

`blocked` uretilmez.

Bu status hard validation cagrisimi nedeniyle bu asamada disarida kalir.

## Kullanim alanlari

Soft validation report helper ileride su alanlarda kullanilabilir:

- Handover on kontrol.
- Audit QC raporu.
- Export/backup oncesi risk gorunurlugu.
- Admin/debug kalite raporu.
- Migration oncesi veri sagligi incelemesi.
- Test example standardization.

Bu kullanimlar gorunurluk saglar; otomatik engelleme yapmaz.

## Kullanilmayacagi alanlar

Soft validation report helper su alanlarda kullanilmayacak:

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

## Gelecek guvenli sira

Guvenli sira soyle korunur:

- Adim 144: soft validation report API boundary / test matrix plan.
- Adim 145: read-only soft validation report implementation.
- Adim 146: soft validation usage documentation / handover QC interpretation.
- Adim 147: format/export helper plan.
- Adim 148: format helper implementation.
- Adim 149 veya sonrasi: handover QC summary layer.
- Podcast 024: Adim 142-146 tamamlandiktan sonra planlanmali.
- Hard validation en sona birakilir.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Soft validation bu adimda implement edilmeyecek.
- Soft validation ileride bile read-only/reporting katmani olarak kalacak.
- `FileAttachmentRecord` davranisina dokunulmayacak.
- Podcast 024 bu adimda olusturulmadi.

## Sonuc

Adim 144, soft validation report layer icin ilk API ve test zemini planini olusturdu.

Bu plan kayit reddi, veri degisikligi, constructor validation, database/repository yazimi, migration, otomatik duzeltme veya hard validation baslatmaz.
