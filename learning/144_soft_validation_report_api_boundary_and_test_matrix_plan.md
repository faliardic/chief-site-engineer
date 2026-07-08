# Adim 144 - Soft Validation Report API Boundary and Test Matrix Plan

## Sunu yaptik

Soft validation report layer icin API boundary ve test matrix planladik.

Bu adimda kod yazmadik, test eklemedik ve `build_record_id_soft_validation_report(...)` helper'ini implement etmedik.

## Boyle yaptik

Ilk guvenli input yaklasimini diagnostic report dict olarak belirledik.

Yani ilerideki helper once sunu alabilir:

```python
build_record_id_diagnostic_report(records)
```

Bu ciktinin uzerine yorum katmani kurulur.

Helper record listesi, repository veya database sorgusu almaz. Boylece sorumluluk kucuk kalir.

## Cunku

Soft validation report katmani diagnostic veriyi yorumlar.

Eger helper hem kayitlari toplar, hem diagnostic rapor uretir, hem de soft validation sonucu hesaplarsa sorumluluk buyur.

Ilk guvenli yaklasim su ayrimi korur:

- Diagnostic report helper bilgi uretir.
- Soft validation report helper bu bilgiyi yorumlar.
- Cagiran katman karar verir.

## Olasi output

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

Bu output kayit reddetmez ve input verisini degistirmez.

## Status dersleri

`pass`:

- Error yok.
- Warning yok.
- Sadece info/canonical kayitlar var.

`review`:

- Warning var.
- Error yok.
- Gozden gecirme gerekir.
- Kayit reddi degildir.

`attention`:

- Error var.
- Manuel inceleme gerekir.
- Otomatik silme veya duzeltme sebebi degildir.
- Kayit reddi degildir.

`blocked`:

- Bu asamada uretilmez.
- Hard validation veya engelleme anlami dogurabilir.

Status onceligi `attention > review > pass` olarak planlandi.

## Test matrix dersleri

Ileride implementasyon yapilirsa testler su davranislari dogrulamalidir:

- Bos diagnostic report.
- Sadece info itemlari ile `pass`.
- Warning itemi ve error yokken `review`.
- Error itemi varken `attention`.
- Warning + error birlikteyken `attention`.
- Status onceligi.
- `review_required` mantigi.
- `attention_required` mantigi.
- Summary count korunumu.
- Items listesi korunumu.
- Input immutability.
- Eksik diagnostic report alanlari.
- Uygunsuz input tipi.
- Unknown severity degeri.
- Warning'in kayit reddi olmadigi.
- Error'in otomatik duzeltme olmadigi.
- `blocked` status'unun uretilmedigi.

## Kullanilabilecek alanlar

Soft validation report helper ileride su alanlarda kullanilabilir:

- Handover on kontrol.
- Audit QC raporu.
- Export/backup oncesi risk gorunurlugu.
- Admin/debug kalite raporu.
- Migration oncesi veri sagligi incelemesi.
- Test example standardization.

## Kullanilmamasi gereken alanlar

Soft validation report helper su isler icin kullanilmaz:

- `AuditEventRecord.__post_init__` icinde validation yapmak.
- Constructor validation olmak.
- Hard validation yapmak.
- Kayit olusturmayi engellemek.
- Legacy kayitlari reddetmek.
- Otomatik data correction yapmak.
- Migration uygulamak.
- Database/repository yazmak.
- Audit event olusturmak.
- `FileAttachmentRecord` davranisini degistirmek.

## Ana ders

Soft validation report, diagnostic report uzerine kurulmus read-only yorum katmanidir.

`blocked` uretilmez. Hard validation hala eklenmedi. `AuditEventRecord.__post_init__` degismedi. `build_record_id_diagnostic_report(...)` davranisi degismedi. Podcast 024 olusturulmadi.
