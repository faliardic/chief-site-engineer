# Adim 141 - Record ID Diagnostic Report Usage and Edge Case Standardization

## Sunu yaptik

`build_record_id_diagnostic_report(records)` helper'inin nasil kullanilacagini ve rapor sonucunun nasil yorumlanacagini belgeledik.

Bu adimda kod yazmadik ve test davranisini degistirmedik.

## Boyle yaptik

Helper icin uc siniri netlestirdik:

- Nerede kullanilabilir?
- Nerede kullanilmamalidir?
- Edge case'ler nasil raporlanmalidir?

Helper birden fazla record ID referansini tarar, item bazli diagnostic sonuc ve summary/count uretir.

Ama helper karar vermez.

## Cunku

Adim 140'ta toplu rapor helper'i eklendi. Bir helper eklendiginde en buyuk risk, onu yanlis yerde validation kapisi gibi kullanmaktir.

Bu nedenle Adim 141, helper'in raporlama araci oldugunu tekrar sabitledi.

## Kullanilabilecek yerler

Helper su durumlarda faydali olabilir:

- Handover on kontrol raporu.
- Audit QC raporu.
- Migration oncesi veri envanteri.
- Backup/export oncesi uyari listesi.
- Admin/debug gorunurlugu.
- Test example standardization.
- Veri kalitesi gozden gecirme dokumantasyonu.

Bu alanlarda helper yalnizca gorunurluk saglar.

## Kullanilmamasi gereken yerler

Helper su isler icin kullanilmaz:

- `AuditEventRecord.__post_init__` icinde validation yapmak.
- Constructor validation katmani olmak.
- Hard validation yapmak.
- Legacy kayitlari reddetmek.
- Otomatik data correction yapmak.
- Migration uygulamak.
- Database/repository yazmak.
- Audit event olusturmak.
- `FileAttachmentRecord` davranisini degistirmek.

## Edge case dersleri

Bos input hata degildir. Sadece `total_count` degeri `0`, `items` listesi bos olur.

Canonical ID normal durumdur:

- `severity`: `info`
- `is_compatible`: `True`

Legacy ID uyumlu ama uyarili durumdur:

- `severity`: `warning`
- `is_compatible`: `True`

Prefix disi ID reddedilmez:

- `severity`: `warning`
- `is_compatible`: `False`

Bilinmeyen target type, bos `target_record_id` veya uygunsuz item raporu kesmez:

- `severity`: `error`
- Diagnostic item uretilir.
- Otomatik silme veya duzeltme yapilmaz.

## Tuple ve dict input

Tuple/list inputta ilk iki eleman okunur:

```python
("attachment", "ATT-2026-0001")
```

Dict inputta iki anahtar beklenir:

```python
{
    "target_record_type": "attachment",
    "target_record_id": "ATT-2026-0001",
}
```

Eksik bilgi varsa helper exception firlatmak yerine error diagnostic item uretir.

## Summary nasil okunur?

Summary karar vermez, sayi verir.

- `total_count`: input item sayisi.
- `compatible_count`: uyumlu item sayisi.
- `warning_count`: uyarili item sayisi.
- `error_count`: helper seviyesinde sorunlu item sayisi.

`warning_count` veya `error_count` hard validation anlamina gelmez.

## Ana ders

Diagnostic report helper kalite gorunurlugu saglar, veri davranisini degistirmez.

Hard validation hala eklenmedi. `AuditEventRecord.__post_init__` degismedi. Legacy ID ornekleri korunur. `FileAttachmentRecord` davranisina dokunulmaz.

Guvenli ilerleme sirasi sudur: once usage ve edge case standardi, sonra rapor format siniri, sonra soft validation rapor katmani; hard validation en sonda ve ayri karar olarak kalir.
