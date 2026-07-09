# Adim 162 - Export Helper Result Contract Wrapper Test Matrix Finalization

Bu adimda ileride eklenecek result contract wrapper fonksiyonlari icin test matrisi documentation-only olarak netlestirildi.

Planlanan wrapper fonksiyonlari:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut helper davranisi degistirilmedi.

Result contract wrapper implementasyonu yapilmadi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Podcast 027 olusturulmadi.

Commit alinmadi.

Push yapilmadi.

## Ana amac

Bu adimin amaci, `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapperlari ileride eklendiginde test edilecek davranislari kesinlestirmektir.

Mevcut `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlarinin exception tabanli davranisi korunacaktir.

Wrapper testleri mevcut helper testlerinden ayri olacaktir.

Bu adimda implementasyon yapilmadi.

Test matrisi, wrapperlarin basarili yazim, input hata, path safety, overwrite, error mapping, result schema, regression boundary ve handover QC davranislarini kapsamalidir.

## A. Wrapper basari testleri

Basari testleri wrapperlarin dosya yazimi basarili oldugunda standart result contract dondurdugunu kanitlamalidir.

Testlenmesi gerekenler:

- JSON wrapper basarili yazimda `success=True` dondurur.
- Markdown wrapper basarili yazimda `success=True` dondurur.
- `output_path` dogru doner.
- `attempted_path` dogru doner.
- `allowed_root` kullanildiysa dogru raporlanir.
- `file_type` JSON icin `json` doner.
- `file_type` Markdown icin `markdown` doner.
- `error_code` `None` olur.
- `error_message` `None` olur.
- `skipped_reason` `None` olur.
- Yeni dosya yaziminda `overwritten=False` olur.
- `overwrite=True` ile mevcut dosya guncellenirse `overwritten=True` olur.

Basari testleri result contract'in kullaniciya ve handover QC katmanina okunur sonuc tasidigini gostermelidir.

## B. JSON wrapper input testleri

JSON wrapper input testleri JSON-ready dict sinirinin korundugunu ve hata durumlarinin result contract ile gorunur oldugunu kanitlamalidir.

Testlenmesi gerekenler:

- JSON-ready dict basarili olur.
- Bos dict politikasi netlesir.
- Non-dict input `success=False` dondurur.
- Serialize edilemeyen object `success=False` dondurur.
- Input dict mutate edilmez.
- Diagnostic report yeniden hesaplanmaz.
- Soft validation sonucu yeniden hesaplanmaz.
- Format helper ciktisi degistirilmez.

Olasil hata kodlari:

- `input_type_error`
- `serialization_error`
- `invalid_json_input`
- `empty_content`

Bos dict kabul edilecekse basari sonucu beklenmelidir.

Bos dict reddedilecekse `success=False` ve net bir `error_code` beklenmelidir.

Bu politika implementation oncesi testlerde acik olmalidir.

## C. Markdown wrapper input testleri

Markdown wrapper input testleri string input sinirinin korundugunu ve Markdown iceriginin degistirilmedigini kanitlamalidir.

Testlenmesi gerekenler:

- String input basarili olur.
- Bos string politikasi netlesir.
- Non-string input `success=False` dondurur.
- Markdown icerik yeniden formatlanmaz.
- Input string degistirilmez.

Olasil hata kodlari:

- `input_type_error`
- `invalid_markdown_input`
- `empty_content`

Bos string kabul edilecekse basari sonucu beklenmelidir.

Bos string reddedilecekse `success=False` ve net bir `error_code` beklenmelidir.

## D. Path safety wrapper testleri

Path safety testleri wrapperlarin file-writing guvenlik sinirlarini result contract ile gorunur hale getirdigini kanitlamalidir.

Testlenmesi gerekenler:

- Bos `output_path` `success=False` dondurur.
- Klasor path `success=False` dondurur.
- Yanlis uzanti `success=False` dondurur.
- JSON wrapper yalniz `.json` kabul eder.
- Markdown wrapper yalniz `.md` kabul eder.
- Path traversal `success=False` dondurur.
- `allowed_root` disi path `success=False` dondurur.
- `allowed_root` ici path basarili olur.
- Parent directory yoksa `success=False` dondurur.
- `.git` alanina yazma reddedilir.
- `.env` alanina yazma reddedilir.
- Cache alanlarina yazma reddedilir.
- Pycache alanlarina yazma reddedilir.
- ZIP/yedek alanlarina yazma reddedilir.
- Mixed separator davranisi net testlenir.

Olasil hata kodlari:

- `empty_output_path`
- `directory_path`
- `wrong_extension`
- `path_traversal`
- `outside_allowed_root`
- `parent_missing`
- `path_or_extension_error`

Bu testler wrapperin path safety hatalarini hard validation'a donusturmeden gorunur kilmasini saglar.

## E. Overwrite wrapper testleri

Overwrite testleri `overwrite=False` guvenlik freninin wrapper contract icinde de korundugunu kanitlamalidir.

Testlenmesi gerekenler:

- Hedef dosya yok ve `overwrite=False` ise yazim basarili olur.
- Hedef dosya var ve `overwrite=False` ise `success=False` dondurur.
- `overwrite=False` iken mevcut icerik korunur.
- `skipped_reason` `file_exists` veya esdeger net deger olur.
- `error_code` `file_exists` veya esdeger net deger olur.
- Hedef dosya var ve `overwrite=True` ise yazim basarili olur.
- `overwrite=True` sadece hedef dosyayi degistirir.

Olasil result beklentisi:

```text
success=False
error_code="file_exists"
skipped_reason="file_exists"
overwritten=False
```

Basarili overwrite durumunda:

```text
success=True
error_code=None
skipped_reason=None
overwritten=True
```

## F. Error mapping testleri

Error mapping testleri exception tabanli dusuk seviye helper davranisinin wrapper result contract'a tutarli cevrildigini kanitlamalidir.

Genel mapping testleri:

- `TypeError` -> `input_type_error`
- `ValueError` -> `path_or_extension_error` veya daha ozel kod
- `FileExistsError` -> `file_exists`
- `PermissionError` -> `permission_error`
- `OSError` -> `io_error`
- Beklenmeyen exception -> `unexpected_error`

Daha ozel `error_code` testleri:

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

Genel mapping ve ozel mapping arasindaki oncelik implementation oncesi net olmalidir.

Ornegin yanlis uzanti `ValueError` olarak geliyorsa wrapper bunu genel `path_or_extension_error` yerine `wrong_extension` olarak raporlayabilir.

## G. Result contract schema testleri

Schema testleri tum wrapper sonuclarinin ayni anahtar setini tasidigini kanitlamalidir.

Beklenen ortak anahtarlar:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Testlenmesi gerekenler:

- Her result dict ayni anahtar setini tasir.
- `success` her zaman bool olur.
- `output_path` basarili durumda dolu olur.
- `output_path` hata durumunda `None` veya sozlesmede belirlenen guvenli deger olur.
- `attempted_path` mumkun oldugunca dolu olur.
- `allowed_root` verildiyse raporlanir.
- `file_type` JSON icin `json`, Markdown icin `markdown` olur.
- `error_code` basarili durumda `None` olur.
- `error_message` basarili durumda `None` olur.
- `skipped_reason` yalniz gercekten skip varsa dolar.
- `overwritten` her zaman bool olur.

Schema sabitligi, handover QC ve gelecekteki raporlama katmanlarinin result dict'i guvenle okumasini saglar.

## H. Regression boundary testleri

Regression boundary testleri wrapper implementasyonu geldiginde mevcut veri omurgasinin bozulmadigini kanitlamalidir.

Testlenmesi gerekenler:

- `write_json_ready_dict_to_file(...)` mevcut exception davranisini korur.
- `write_markdown_text_to_file(...)` mevcut exception davranisini korur.
- Mevcut formatter helper davranislari degismez.
- Mevcut diagnostic report helper davranislari degismez.
- Mevcut soft validation report helper davranislari degismez.
- `AuditEventRecord.__post_init__` daraltilmaz.
- `FileAttachmentRecord` davranisi degismez.
- Hard validation eklenmez.
- `blocked` status uretilmez.
- Backup / restore davranisi eklenmez.
- API / GUI / CLI eklenmez.
- Audit event uretimi eklenmez.

Bu testler wrapperin yalniz file-writing sonucunu raporlayan gorunurluk katmani olarak kalmasini saglar.

## I. Handover QC testleri

Handover QC testleri wrapper sonucunun kullaniciya okunur bilgi tasidigini, fakat devir paketini otomatik bloke etmedigini kanitlamalidir.

Testlenmesi gerekenler:

- `success=False` sonucu otomatik blokaj anlami tasimaz.
- `blocked` status uretilmez.
- Hata bilgisi insan incelemesine uygun tasinir.
- `output_path` ve `attempted_path` ayrimi anlasilir kalir.
- `allowed_root` disi deneme acikca raporlanir.
- `overwrite=False` nedeniyle yazilmayan dosya acikca skipped olarak yorumlanabilir.
- Export basarisizligi database veya repository kaydi degistirmez.

Handover QC wrapper sonucunu "gozden gecirilecek export" olarak yorumlayabilir.

Bu, hard validation veya record rejection degildir.

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
- Commit alinmadi.
- Push yapilmadi.

## Sonuc

Adim 162'nin karari sudur:

Future `try_write_*` wrapper implementasyonu oncesinde basari, input, path safety, overwrite, error mapping, schema, regression boundary ve handover QC testleri netlesmelidir.

Bu test matrisi, wrapperlarin sessiz basarisizlik uretmemesini, mevcut `write_*` helper davranisini bozmamasini ve handover QC gorunurlugunu hard validation'a donusturmemesini garanti etmeye hazirliktir.
