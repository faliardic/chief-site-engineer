# Adim 137 - Record ID Diagnostic Helper Usage Boundary Plan

## Amac

Bu adimda Adim 136'da eklenen `diagnose_record_id_for_target_type(...)` helper'inin kullanim sinirlari belgelendi.

Bu adim documentation-only adimidir. Kod, test, runtime validation, constructor davranisi, hard validation veya repository davranisi degistirilmedi.

## Helper ne ise yarar?

`diagnose_record_id_for_target_type(...)`, bir `target_record_type` ve `target_record_id` ciftini diagnostic amacli yorumlar.

Helper su bilgileri uretir:

- Beklenen ID ailesi.
- Izin verilen canonical ve legacy prefixler.
- Gozlenen prefix.
- Diagnostic seviyesinde uyumlu gorunup gorunmedigi.
- `info`, `warning` veya helper giris hatasi icin `error` severity degeri.
- Okunabilir kisa mesaj.

Helper veri reddetmez. Constructor davranisini daraltmaz. Hard validation degildir.

## Kullanilabilecegi yerler

Helper asagidaki dis kalite kontrol ve gorunurluk katmanlarinda kullanilabilir:

- Handover on kontrol raporlari.
- Audit kayit kalite kontrol raporlari.
- Migration oncesi veri envanteri taramalari.
- Admin veya debug amacli diagnostic ciktilar.
- Test example standardization kontrolleri.
- Ileride export, backup veya restore oncesi uyari uretimi.

Bu kullanimlarda helper kaydi durdurmaz; sadece karar verecek katmana bilgi tasir.

## Kullanilmamasi gereken yerler

Helper asagidaki yerlerde kullanilmamalidir:

- `AuditEventRecord.__post_init__` icinde.
- Constructor validation katmani olarak.
- Kayit olusturmayi engelleyen hard validation olarak.
- Legacy kayitlari reddetmek icin.
- `FileAttachmentRecord` davranisini degistirmek icin.
- Otomatik data correction veya migration yapmak icin.

Diagnostic helper'in varligi, hard validation'in hazir oldugu anlamina gelmez.

## Severity siniri

Severity degerleri raporlama sinyalidir:

- `info`: Canonical prefix ile uyumlu gorunen kayit.
- `warning`: Legacy prefix kullanan veya allowed prefix disinda kalan ama reddedilmeyecek kayit.
- `error`: Helper seviyesinde diagnostic uretilemeyen giris.

`warning` veri hatasi degildir; kalite kontrol uyarisi olarak ele alinmalidir.

`error` otomatik silme, duzeltme veya migration sebebi degildir. Sadece helper cagrisi seviyesinde "bu girisle saglikli diagnostic uretilemedi" bilgisidir.

## API boundary

Helper saf diagnostic fonksiyon olarak kalmalidir.

API siniri:

- Helper bilgi uretir.
- Cagiran katman karar verir.
- Helper repository veya database bilmez.
- Helper dosya sistemi islemi yapmaz.
- Helper upload, backup veya restore islemi yapmaz.
- Helper audit event olusturmaz.
- Helper otomatik veri duzeltmez.

Bu sinir, helper'in raporlama araci olmaktan cikarak runtime davranis kapisina donusmesini engeller.

## Gelecek adimlar icin guvenli sira

Record ID hattinda guvenli ilerleme sirasi su sekilde korunmalidir:

1. Usage documentation.
2. Diagnostic report helper plan.
3. Read-only diagnostic report implementation.
4. Test example standardization.
5. Soft validation raporlari.
6. Hard validation degerlendirmesi.

Hard validation en sona birakilir. Bu noktaya gelmeden once legacy ornekler, test standardizasyonu ve migration riski netlestirilmelidir.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- `FileAttachmentRecord` davranisina dokunulmayacak.
- Diagnostic helper dis kalite kontrol / raporlama / handover on kontrol katmani icin bilgi ureten bir yardimci olarak kalacak.

## Sonuc

Adim 137, Adim 136 helper'inin kullanim alanini ve sinirlarini netlestirdi.

Bu sinir sayesinde CSE, record ID kalitesini gorunur hale getirirken mevcut kayit olusturma davranisini, legacy ID orneklerini ve audit constructor uyumlulugunu korur.
