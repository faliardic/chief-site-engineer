# Adim 135 - Record ID Soft Validation Diagnostic Helper Implementation Plan

## Amac

Bu adimin amaci, Adim 134 soft validation planina dayanarak ileride eklenecek record ID soft validation diagnostic helper icin implementation plan dokumantasyonu hazirlamaktir.

Bu adim documentation-only / diagnostic-helper-planning adimidir. Kod, model, test, diagnostic helper, soft validation implementasyonu, hard validation veya runtime davranisi degistirilmedi.

## Arka plan: Adim 129-134 zinciri

Adim 129, mevcut record ID alanlarini ve test orneklerini envanterledi. Bu envanter, projede tek bir ID formatinin henuz olmadigini ve lower-case, upper-case, cok parcali prefix, path icine gomulu ID ve opsiyonel baglanti orneklerinin birlikte yasadigini gosterdi.

Adim 130, central record ID contract planini yazdi ve hard validation icin once sozlesme, mapping, test standardizasyonu ve migration dusuncesi gerektigini belirtti.

Adim 131, record ID constants ve mapping helper katmanini planladi.

Adim 132, bilgi donen constants ve helper katmanini ekledi.

Adim 133, helper API sinirini netlestirdi: helperlar validation fonksiyonu gibi kullanilmayacak ve constructor davranisi daraltilmayacak.

Adim 134, soft validation'i diagnostic / uyari katmani olarak planladi. Adim 135 ise bu diagnostic helper'in nasil tasarlanabilecegini, hangi alanlari dondurebilecegini ve hangi sinirlari koruyacagini dokumante eder.

## Diagnostic helper'in rolu

Diagnostic helper, record ID degerini reddetmeden yorumlayan bilgi katmanidir.

Rolu:

- Veri reddetmez.
- Uyari veya diagnostic sonucu uretir.
- `AuditEventRecord.__post_init__` icine baglanmaz.
- `target_record_id` hard validation yapmaz.
- Legacy ID orneklerini kirmadan kalite sinyali uretir.
- Audit export, kalite kontrol raporu veya handover on kontrolu gibi dis katmanlara veri saglar.

Diagnostic helper bir validation kapisi degildir. Bir raporlama ve gorunurluk aracidir.

## Onerilen helper fonksiyonlari

Ileride eklenecek helper fonksiyonlari su adaylardan baslayabilir:

- `diagnose_record_id_for_target_type(target_record_type, target_record_id)`
- `get_record_id_prefix_diagnostic(target_record_type, target_record_id)`
- `is_record_id_prefix_compatible(target_record_type, target_record_id)`

Onerilen ana helper:

```python
diagnose_record_id_for_target_type(target_record_type, target_record_id)
```

Bu helper, tek bir diagnostic sonucu dondurabilir.

Onerilen yardimci helperlar:

```python
get_record_id_prefix_diagnostic(target_record_type, target_record_id)
is_record_id_prefix_compatible(target_record_type, target_record_id)
```

Bu helperlar ana diagnostic fonksiyonun icinde kullanilabilir veya testlerde daha kucuk parcalari dogrulamak icin tasarlanabilir.

## Onerilen diagnostic cikti yapisi

Diagnostic sonucunun sozluk veya kucuk bir dataclass olarak tasarlanmasi dusunulebilir.

Onerilen alanlar:

```text
target_record_type
target_record_id
expected_family
allowed_prefixes
observed_prefix
is_compatible
severity
message
```

Alan anlamlari:

- `target_record_type`: Audit event hedef kayit turu.
- `target_record_id`: Degerlendirilen hedef kayit kimligi.
- `expected_family`: Helper mapping'e gore beklenen ID aileleri.
- `allowed_prefixes`: Target type icin bilinen canonical ve legacy prefix adaylari.
- `observed_prefix`: `target_record_id` icinden gozlenen prefix.
- `is_compatible`: Diagnostic seviyesinde uyumlu gorunup gorunmedigi.
- `severity`: `info`, `warning` veya helper giris hatasi icin `error`.
- `message`: Insan tarafindan okunabilir kisa diagnostic aciklamasi.

## Severity yaklasimi

Onerilen severity degerleri:

- `info`: Canonical veya uyumlu gorunen ID.
- `warning`: Legacy veya prefix disi ama reddedilmeyecek ID.
- `error`: Sadece helper giris hatasi veya diagnostic uretilemeyen durumlar icin.

`error`, model constructor davranisina tasinmamalidir. Bu seviye sadece diagnostic helper'in kendi cagrisi icin anlamlidir.

Ornek yorum:

- `ATT-2026-0001` ve `attachment`: `info`.
- `file-att-001` ve `attachment`: `warning`, fakat reddedilmez.
- `unknown_record` ve `REC-1`: helper seviyesinde temiz hata veya diagnostic `error`.

## Kullanilacagi yerler

Diagnostic helper ileride su dis kalite kontrol katmanlarinda kullanilabilir:

- Audit raporlama.
- Quality-control report.
- CLI veya export on kontrolu.
- Handover package on kontrolu.
- Developer diagnostic komutu.
- Test helper veya fixture kalite kontrolu.

Bu yerlerde helper, kaydi reddetmeden kalite sinyali uretir.

## Kullanilmayacagi yerler

Diagnostic helper su yerlerde kullanilmamalidir:

- `AuditEventRecord.__post_init__` icinde hard validation gibi.
- `AuditEventRecord.target_record_id` formatini reddetmek icin.
- `FileAttachmentRecord` validation davranisini degistirmek icin.
- Legacy ID orneklerini kirmak icin.
- API, repository veya persistence davranisini sessizce daraltmak icin.
- Hard validation'a dogrudan kapı olarak.

Diagnostic helper dis katmanlar icin bilgi uretir; model constructor icin gatekeeper degildir.

## Test plani

Bu adimda test yazilmadi. Ileride diagnostic helper implementasyonu yapilirsa su test kategorileri kullanilabilir:

- Canonical ID compatible diagnostic doner.
- Legacy ID warning diagnostic doner ama reddedilmez.
- Bos `target_record_id` diagnostic yaklasimi ayri ve okunur sonuc verir.
- Bilinmeyen `target_record_type` temiz hata veya diagnostic `error` uretir.
- Helper `AuditEventRecord` constructor davranisini degistirmez.
- Hard validation davranisi olusmaz.
- `project_record` gibi genis target type degeri coklu prefix ailesini destekler.
- `attachment` icin canonical `ATT` ve legacy `file-att` / `att` ornekleri ayri mesajlarla raporlanabilir.

## Geriye uyumluluk yaklasimi

Geriye uyumluluk bu helper icin temel sinirdir.

Korunacak yaklasim:

- Legacy ID ornekleri diagnostic olarak gorunur olabilir, fakat reddedilmez.
- Mevcut `AuditEventRecord` testleri kirilmaz.
- Mevcut helper API hard validation'a cevrilmez.
- `target_record_type` / ID family mapping'i raporlama icin kullanilir, constructor davranisini daraltmak icin kullanilmaz.

## Bu adimda bilincli olarak yapilmayanlar

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- Diagnostic helper implementasyonu yapilmadi.
- Soft validation implementasyonu yapilmadi.
- `AuditEventRecord.target_record_id` hard validation eklenmedi.
- `AuditEventRecord.__post_init__` davranisi degistirilmedi.
- `FileAttachmentRecord` degistirilmedi.
- Podcast 022 olusturulmadi.
- Commit veya push yapilmadi.
- ZIP dosyasi stage edilmedi.

## Sonraki guvenli teknik adim

Adim 136 icin en guvenli teknik adim, record ID diagnostic helper implementation veya record ID test example categories dokumantasyonudur.

Diagnostic helper implementasyonu yapilsa bile `AuditEventRecord.__post_init__` icine baglanmamali ve hard validation olarak kullanilmamalidir.
