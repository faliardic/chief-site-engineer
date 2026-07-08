# Adim 138 - Record ID Diagnostic Report Helper Plan

## Amac

Bu adimda Adim 136'da eklenen `diagnose_record_id_for_target_type(...)` tekil diagnostic helper'inin ileride read-only toplu rapor helper'ina nasil donusturulebilecegi planlandi.

Bu adim documentation-only adimidir. Kod, test, diagnostic report helper implementasyonu, hard validation, runtime davranisi, repository davranisi veya data migration eklenmedi.

## Diagnostic report helper ne ise yarayacak?

Ileride eklenecek diagnostic report helper, birden fazla audit/event/record referansini read-only tarayabilir.

Her kayit icin `diagnose_record_id_for_target_type(...)` benzeri tekil diagnostic sonucu uretebilir ve bunlari toplu bir rapor halinde dondurebilir.

Temel sinir:

- Kayit reddetmez.
- Veri degistirmez.
- Migration yapmaz.
- Otomatik duzeltme yapmaz.
- Sadece diagnostic rapor dondurur.

## Olası helper adi

Ilerideki helper adi su olabilir:

```python
build_record_id_diagnostic_report(...)
```

Bu adimda bu helper implemente edilmedi. Sadece API ve davranis siniri planlandi.

## Olası rapor cikti alanlari

Toplu rapor ileride su alanlari dondurebilir:

- `total_count`
- `compatible_count`
- `warning_count`
- `error_count`
- `items`
- `summary`
- `generated_at`

`generated_at` ileride gerekirse eklenebilir; bu adimda zorunlu alan olarak kilitlenmedi.

## Her item icin olasi alanlar

Raporun `items` listesinde her kayit icin su alanlar bulunabilir:

- `index`
- `target_record_type`
- `target_record_id`
- `expected_family`
- `allowed_prefixes`
- `observed_prefix`
- `is_compatible`
- `severity`
- `message`

Bu item alanlari tekil diagnostic helper cikti yapisiyla uyumlu kalmalidir.

## Kullanim alanlari

Diagnostic report helper ileride su read-only gorunurluk katmanlarinda kullanilabilir:

- Handover on kontrol raporu.
- Audit QC raporu.
- Migration oncesi envanter taramasi.
- Backup veya export oncesi uyari listesi.
- Admin/debug gorunurlugu.
- Test example standardization kontrolu.

Bu kullanimlar kayit reddetme veya veri degistirme amaci tasimaz.

## Kullanilmayacagi alanlar

Diagnostic report helper su yerlerde kullanilmamalidir:

- `AuditEventRecord.__post_init__`.
- Constructor validation.
- Hard validation.
- Legacy kayit reddi.
- Otomatik duzeltme.
- Migration uygulama adimi.
- `FileAttachmentRecord` davranisi.
- Database veya repository yazma islemi.
- Audit event olusturma.

Bu helper'in rapor uretebilmesi, runtime validation veya data migration icin hazir oldugu anlamina gelmez.

## Read-only sinir

Diagnostic report helper read-only kalmalidir.

Sinirlar:

- Helper yalniz input listesini okur.
- Kayitlari degistirmez.
- Dosya sistemiyle islem yapmaz.
- Veritabanina yazmaz.
- Commit, backup veya export uretmez.
- Audit event olusturmaz.
- Sadece diagnostic rapor dondurur.

Bu sinir, helper'in kalite kontrol gorunurlugunden otomatik islem katmanina kaymasini engeller.

## Severity yaklasimi

Report helper tekil diagnostic helper ile ayni severity anlamlarini korumalidir:

- `info`: Canonical prefix ile uyumlu gorunen kayitlar.
- `warning`: Legacy veya prefix disi ama reddedilmeyen kayitlar.
- `error`: Helper'in anlamli diagnostic uretemedigi kayitlar.

`warning` veri reddi degildir.

`error` otomatik silme, duzeltme veya migration sebebi degildir.

Toplu rapor bu seviyeleri sayabilir, gruplayabilir ve ozetleyebilir; fakat kayit davranisini degistirmez.

## Gelecek guvenli sira

Record ID diagnostic rapor hattinda guvenli ilerleme sirasi su sekilde korunmalidir:

1. Adim 138: Diagnostic report helper plani.
2. Adim 139: Diagnostic report helper API boundary dokumantasyonu veya test example matrix plani.
3. Adim 140: Read-only diagnostic report helper implementation.
4. Adim 141: Test standardization / examples.
5. Adim 142 veya sonrasi: Soft validation report layer.
6. En son: Hard validation degerlendirmesi.

Hard validation en sona birakilir. Bu noktaya gelmeden once diagnostic raporlar, test ornekleri, legacy ID'ler ve migration riski yeterince gorunur olmalidir.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- Diagnostic report helper ileride bile once read-only kalacak.
- `FileAttachmentRecord` davranisina dokunulmayacak.
- Podcast 023 bu adimda olusturulmayacak.

## Sonuc

Adim 138, tekil record ID diagnostic helper'in ileride toplu rapora nasil donusebilecegini planladi.

Bu plan, CSE'nin record ID kalitesini toplu olarak gorunur hale getirmesini hedefler; ancak veri reddetme, veri degistirme, migration veya hard validation davranisi baslatmaz.
