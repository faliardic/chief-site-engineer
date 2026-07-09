# Adim 161 - Export Helper Result Contract Wrapper Implementation Plan

Bu adimda Adim 160'ta cizilen API boundary'ye bagli kalarak, ileride eklenecek result contract wrapper implementasyonunun sinirlari documentation-only olarak netlestirildi.

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut helper davranisi degistirilmedi.

Result contract wrapper implementasyonu yapilmadi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 027 olusturulmadi.

## Ana amac

Mevcut helper davranislari korunacaktir:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu helperlar basarida `Path` donduren ve hatada exception firlatan dusuk seviyeli file-writing helperlar olarak kalir.

Yeni wrapper fonksiyonlar ileride ayri katman olarak eklenebilir.

Wrapper fonksiyonlar exception yakalayip guvenli result contract dondurur.

Mevcut helperlarin exception tabanli davranisi bu adimda ve planlanan geciste bozulmayacaktir.

## Planlanan wrapper fonksiyon isimleri

Ileride eklenecek wrapperlar icin planlanan isimler:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Bu isimler result contract donen wrapper davranisini mevcut `write_*` helperlardan ayirir.

`write_*` helperlar exception tabanli kalir.

`try_write_*` wrapperlar result contract dondurur.

Bu adimda bu fonksiyonlar eklenmedi.

## Wrapperlarin temel davranisi

Wrapperlar mevcut helperlarla ayni temel inputlari alabilir:

- JSON-ready dict.
- Markdown string.
- `output_path`.
- `allowed_root`.
- `overwrite`.

Wrapperlar mevcut `write_*` helperlari cagirir.

Basarili durumda result contract dondurur.

Hata durumunda exception firlatmak yerine result contract dondurur.

Wrapper sessiz basarisizlik yapmaz.

Dosya yazilmadiysa bunu acikca bildirir.

Wrapper diagnostic veya soft validation sonucunu yeniden hesaplamaz.

Wrapper format helper ciktisini degistirmez.

Wrapper input mutate etmez.

## Onerilen result contract alanlari

Wrapper result contract icin onerilen alanlar:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Bu alanlar JSON ve Markdown wrapperlari icin ortak tutulabilir.

`file_type` alani hangi wrapper'in kullanildigini gorunur kilar:

- `json`
- `markdown`

## Basari sozlesmesi

Basarili wrapper sonucu su beklentileri tasimalidir:

- `success=True`
- `output_path` dolu.
- `attempted_path` dolu.
- `file_type="json"` veya `file_type="markdown"`.
- `error_code=None`
- `error_message=None`
- `skipped_reason=None`
- `overwritten=False` veya `overwritten=True`

Yeni dosya yazildiysa `overwritten=False` olmalidir.

Mevcut dosya explicit `overwrite=True` ile guncellendiyse `overwritten=True` olabilir.

Basarili result, dosya yazildigini acikca gosterir.

## Hata sozlesmesi

Hata durumunda wrapper sonucu su beklentileri tasimalidir:

- `success=False`
- `attempted_path` dolu olabilir.
- `output_path=None` olabilir.
- `output_path`, yazilmayan hedef path bilgisini kontrollu sekilde de tasiyabilir.
- `error_code` dolu olur.
- `error_message` kullaniciya gosterilebilir ama teknik detayi abartmayan metin olur.
- `skipped_reason`, ozellikle `overwrite=False` ve dosya zaten var senaryosunda dolabilir.
- Dosya sistemi degismediyse bu durum result alanlarindan anlasilabilir olur.

Hata result'i sessiz basarisizlik degildir.

Yazma yapilmadiysa result bunu basari gibi sunmamalidir.

## Error mapping plani

Ilk genel error mapping plani:

- `TypeError` -> `input_type_error`
- `ValueError` -> `path_or_extension_error`
- `FileExistsError` -> `file_exists`
- `PermissionError` -> `permission_error`
- `OSError` -> `io_error`
- Beklenmeyen exception -> `unexpected_error`

Daha ozel error code ihtimalleri:

- `wrong_extension`
- `path_traversal`
- `outside_allowed_root`
- `parent_missing`
- `directory_path`
- `empty_output_path`
- `serialization_error`
- `file_exists`
- `permission_error`
- `io_error`
- `unexpected_error`

Genel mapping ilk wrapper implementasyonu icin yeterli olmayabilir.

Implementation asamasinda mevcut helper exception tipleri ve mesajlari incelenerek daha spesifik mapping tasarlanmalidir.

Bu adimda mapping uygulanmadi.

## Overwrite davranisi

`overwrite=False` varsayilan olarak kalir.

Hedef dosya varsa wrapper:

- `success=False` dondurur.
- Mevcut dosyayi degistirmez.
- `error_code="file_exists"` kullanabilir.
- `skipped_reason="file_exists"` veya benzeri net alan kullanabilir.
- `overwritten=False` dondurur.

Bu davranis kullaniciya dosyanin neden yazilmadigini aciklar.

`overwrite=True` ve yazim basariliysa wrapper:

- `success=True` dondurur.
- `overwritten=True` dondurabilir.
- `error_code=None` dondurur.
- `skipped_reason=None` dondurur.

`overwrite=True` sadece hedef dosyayi degistirmelidir.

## Path safety davranisi

Wrapper path safety hatalarini result contract ile guvenli hata olarak tasimalidir.

Planlanan davranislar:

- `allowed_root` disi yazma `success=False` ve `error_code="outside_allowed_root"` uretir.
- Path traversal `success=False` ve `error_code="path_traversal"` uretir.
- Parent directory yoksa `success=False` ve `error_code="parent_missing"` uretir.
- Yanlis uzanti `success=False` ve `error_code="wrong_extension"` uretir.
- Klasor path `success=False` ve `error_code="directory_path"` uretir.
- Bos output path `success=False` ve `error_code="empty_output_path"` uretir.

`.git`, `.env`, cache, pycache, ZIP/yedek alanlari kapsam disi kalir.

Bu alanlara yazma denemesi result contract icinde guvenli hata olarak gorunur olmalidir.

## Boundary

Wrapper yalniz export yazma sonucunu raporlar.

Wrapper yapmayacaklari:

- Database veya repository yazmaz.
- Audit event uretmez.
- Backup / restore baslatmaz.
- API / GUI / CLI eklemez.
- Hard validation tetiklemez.
- `blocked` status uretmez.
- Devir paketini otomatik bloke etmez.
- Diagnostic report yeniden hesaplamaz.
- Soft validation report yeniden hesaplamaz.
- Format helper ciktisini degistirmez.
- Input mutate etmez.

Bu boundary, wrapper'in gorunurluk katmani olarak kalmasini saglar.

## Geriye uyumluluk

Geriye uyumluluk kararlari:

- Mevcut `write_*` helper testleri kirilmamalidir.
- Yeni `try_write_*` wrapper testleri ayri yazilmalidir.
- Mevcut exception tabanli helperlari kullanan kodlar ayni davranisi gormelidir.
- Result contract isteyen ust katman wrapperlari kullanmalidir.
- `Path` return bekleyen mevcut kullanimlar etkilenmemelidir.

Bu ayrim, kademeli gecis icin daha guvenlidir.

## Handover QC kullanimi

Wrapper result contract handover QC icin gorunurluk saglayabilir.

Planlanan kullanim:

- Export basarisizligi kullaniciya acik gosterilir.
- Hata bilgisi insan incelemesine tasinir.
- `success=False` otomatik blokaj anlami tasimaz.
- `blocked` status uretilmez.
- Handover QC sonucu "gozden gecirilecek export" olarak yorumlayabilir.

Ornek gorunurluk:

- Hangi path denendi?
- Hangi allowed root kullanildi?
- Yazma basarili oldu mu?
- Yazma neden atlandi?
- Mevcut dosya overwrite edilmedi mi?
- Kullanici hangi path veya overwrite kararini duzeltmeli?

## Sessiz basarisizlik yok

Wrapper implementasyonu ileride yapilirsa ana ilke sessiz basarisizligi engellemek olmalidir.

Yazma yapilmadiysa:

- `success=False` olmalidir.
- `error_code` dolu olmalidir.
- `error_message` veya `skipped_reason` acik olmalidir.
- Mevcut dosya degismediyse bu korunma gorunur olmalidir.

Bu ilke saha/handover hafizasi icin kritiktir.

## Bu adimda yapilmayanlar

Bu adimda:

- `app/models.py` degistirilmedi.
- `tests/test_models.py` degistirilmedi.
- Yeni helper implementasyonu yapilmadi.
- Mevcut helper davranisi degistirilmedi.
- Result contract wrapper implementasyonu yapilmadi.
- Yeni test eklenmedi.
- JSON veya Markdown export cikti dosyasi uretilmedi.
- `exports/` icine `.json` veya `.md` dosyasi yazilmadi.
- Hard validation eklenmedi.
- `AuditEventRecord.__post_init__` degistirilmedi.
- `FileAttachmentRecord` davranisi degistirilmedi.
- `blocked` status eklenmedi.
- Backup / restore davranisi eklenmedi.
- Database / repository / API / GUI / CLI eklenmedi.
- Audit event uretimi eklenmedi.
- Podcast 027 olusturulmadi.

## Sonuc

Adim 161'in karari sudur:

Future result contract wrapper implementasyonu mevcut `write_*` helperlari bozmadan ayri `try_write_*` fonksiyonlar olarak ele alinmalidir.

Wrapperlar mevcut helperlari cagirir, basari veya hata sonucunu standart result contract alanlariyla dondurur, sessiz basarisizlik yapmaz ve handover QC icin gorunurluk saglar.

Bu plan implementation degildir; gelecekteki kod ve test adimlari icin sinir cizer.
