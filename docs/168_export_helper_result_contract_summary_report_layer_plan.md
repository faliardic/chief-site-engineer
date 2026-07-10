# Adim 168 - Export Helper Result Contract Summary Report Layer Plan

Bu adimda Adim 163-167 araliginda olusturulan ve testlerle sabitlenen export helper result contract wrapper davranisinin ileride nasil ozetlenebilecegi ve raporlanabilecegi planlandi.

Odak mevcut helperlar:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`
- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Bu adim documentation-only plan adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut testler degistirilmedi.

Export helper davranisi degistirilmedi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Commit alinmadi.

Push yapilmadi.

## Planlanan summary/report layer amaci

Planlanan summary/report layer, wrapper result contract ciktilarindan okunabilir ozet uretmek icin dusunulur.

Bu layer basari ve hata durumlarini ust katmana kisa, standart ve yorumlanabilir sekilde tasiyabilir.

Olasil kullanim alanlari:

- Handover QC export sonucu ozeti.
- Admin/debug gorunumu.
- Kullaniciya gosterilecek kisa export sonucu mesaji.
- Guvenli raporlama akisi.
- Manuel inceleme notu.

Bu katman dosya yazma helperlarinin yerine gecmez.

`write_*` helperlar dosya yazma isini yapar.

`try_*` wrapperlar dosya yazma sonucunu result contract olarak tasir.

Summary/report layer ise mevcut result contract'i yorumlayarak daha okunabilir ozet uretebilir.

## Sorumluluk ayrimi

Dusuk seviye helper:

```text
hazir JSON-ready dict veya Markdown string -> dosya yazma
```

Wrapper helper:

```text
dosya yazma girisimi -> success/failure result contract
```

Planlanan summary/report layer:

```text
result contract -> okunabilir ozet / rapor yorumu
```

Bu ayrim korunmalidir.

Summary/report layer dosya yazmamalidir.

Summary/report layer result contract'i yeniden hesaplamamalidir.

Summary/report layer `try_*` wrapper davranisini degistirmemelidir.

## Bu adimdaki sinir

Bu adimda summary/report helper implementasyonu yapilmayacak.

JSON/Markdown export dosyasi uretilmeyecek.

Backup/restore sistemi kurulmayacak.

GUI/API/CLI entegrasyonu yapilmayacak.

Audit event uretimi eklenmeyecek.

Database/repository davranisi eklenmeyecek.

Hard validation eklenmeyecek.

`blocked` status eklenmeyecek.

Mevcut dusuk seviye helper davranisi degistirilmeyecek.

Mevcut wrapper result contract davranisi degistirilmeyecek.

## Olasil ilerideki helper fikirleri

Ileride yalniz plan duzeyinde su helper fikirleri degerlendirilebilir:

- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_summary_as_markdown(...)`

Bu adimda bu helperlar implement edilmez.

Bu adimda helper imzasi kilitlenmez.

Bu adimda result summary semasi zorunlu hale getirilmez.

Bu isimler yalniz tartisma ve planlama icindir.

## Onerilen result summary alanlari

Plan duzeyinde su alanlar tartisilabilir:

- `operation`
- `status`
- `path`
- `message`
- `error_type`
- `safe_for_user_message`
- `technical_detail`
- `next_action_hint`

Bu alanlar zorunlu sema olarak kilitlenmemelidir.

Bu alanlar su an yalniz plan ve tartisma seviyesindedir.

Ileride implementasyon dusunulurse once API boundary ve test matrix ayrica yazilmalidir.

## Basarili contract summary yorumu

Basarili wrapper contract ornegi:

```text
success=True
file_type="json"
output_path="<written path>"
error_code=None
```

Olasil summary yorumu:

```text
operation="export_write"
status="success"
message="Export dosyasi yazildi."
path="<written path>"
next_action_hint=None
```

Bu yorum export yazma isleminin kontrollu tamamlandigini belirtir.

Bu yorum backup olustugu anlamina gelmez.

Bu yorum audit event uretildigi anlamina gelmez.

Bu yorum devir paketinin otomatik onaylandigi anlamina gelmez.

## Failure contract summary yorumu

Failure wrapper contract ornegi:

```text
success=False
error_code="parent_missing"
output_path=None
attempted_path="<target path>"
```

Olasil summary yorumu:

```text
operation="export_write"
status="review"
message="Export yazimi gozden gecirilmeli."
error_type="parent_missing"
safe_for_user_message="Export yazilmadi; hedef klasor hazir degil."
next_action_hint="Hedef klasor ve path ayarini kontrol et."
```

Failure contract kayitlari gecersiz yapmaz.

Failure contract devir paketini otomatik bloke etmez.

Failure contract hard validation anlamina gelmez.

Failure contract `blocked` status uretmez.

## Handover QC yorumu

Handover QC icin summary/report layer ileride su kontrollu dili uretebilir:

```text
Export uretildi.
```

veya:

```text
Export sonucu gozden gecirilmeli.
```

Basarili export icin handover QC'ye "export uretildi" seklinde kontrollu bilgi verilebilir.

Basarisiz export icin "gozden gecirilecek export sonucu" olarak raporlanabilir.

Bu yorum karar mekanizmasi degildir.

Bu yorum otomatik bloke etmez.

Bu yorum hard validation degildir.

Bu yorum audit event uretmez.

## Admin/debug yorumu

Admin/debug gorunumu daha teknik alanlari gosterebilir.

Olasil teknik detaylar:

- attempted path
- allowed root
- file type
- error code
- skipped reason
- overwritten
- raw error message

Bu detaylar kullaniciya stack trace gostermeden sorunu anlamayi kolaylastirabilir.

Ancak admin/debug gorunumu bu adimda implement edilmez.

## Test matrix plan

Bu adimda test yazilmayacak.

Ileride summary/report layer implementasyonu dusunulurse su test basliklari planlanabilir:

- success contract summary
- failure contract summary
- mixed result list summary
- missing optional fields
- unsupported input
- input immutability
- no blocked status
- no recomputation of low-level result

Bu test basliklari su an yalniz plan seviyesindedir.

Test dosyasi olusturulmaz.

Mevcut testler degistirilmez.

## Yapilmayacaklar

Kod yazilmayacak.

Test yazilmayacak.

Existing helper davranisi degistirilmeyecek.

Export cikti dosyasi uretilmeyecek.

Hard validation eklenmeyecek.

`blocked` status eklenmeyecek.

Backup/restore/API/GUI/CLI eklenmeyecek.

Audit event uretimi eklenmeyecek.

Database/repository davranisi eklenmeyecek.

ZIP/cache stage edilmeyecek.

Commit yapilmayacak.

Push yapilmayacak.

## Sonuc

Adim 168, export helper wrapper result contract ciktisindan ileride okunabilir summary/report uretme fikrini plan seviyesinde belgeler.

Bu adim implementasyon degildir.

Bu adim dosya yazma davranisini degistirmez.

Bu adim result contract'i karar mekanizmasina cevirmeden, gelecekteki yorumlama katmani icin guvenli sinir cizer.
