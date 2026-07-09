# Adim 163 - Export Helper Result Contract Wrapper Implementation

Bu adimda mevcut exception tabanli file-writing helperlari bozulmadan result contract donduren wrapper fonksiyonlari eklendi.

Eklenen wrapper fonksiyonlari:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Korunan mevcut helper fonksiyonlari:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu adim kod, test ve dokumantasyon adimidir.

JSON veya Markdown export cikti dosyasi repo icine uretilmedi.

Podcast 027 olusturulmadi.

Commit alinmadi.

Push yapilmadi.

## Ana amac

Bu adimin amaci, dusuk seviye file-writing helper davranisini geriye uyumlu tutarken ust katmanlar icin okunabilir ve sabit bir result contract saglamaktir.

Mevcut `write_*` helperlari basarili durumda `Path` dondurmeye, hata durumunda ise standart Python exception firlatmaya devam eder.

Yeni `try_write_*` wrapperlari bu helperlari cagirir, exception yakalar ve her durumda dict result dondurur.

Boylece dusuk seviye helper ile ust seviye raporlama/handover QC ihtiyaci ayrilir.

## Result contract alanlari

Her wrapper sonucu ayni anahtar setini tasir:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Basarili JSON yaziminda `file_type` degeri `json` olur.

Basarili Markdown yaziminda `file_type` degeri `markdown` olur.

Basarili durumda:

- `success=True`
- `output_path` yazilan path olur.
- `attempted_path` hedeflenen path olur.
- `allowed_root` verilen degeri korur.
- `error_code=None`
- `error_message=None`
- `skipped_reason=None`
- yeni dosya icin `overwritten=False`
- `overwrite=True` ile mevcut dosya guncellendiyse `overwritten=True`

Hata durumunda:

- `success=False`
- `output_path=None`
- `attempted_path` bilinen hedef path olur.
- `allowed_root` verilen degeri korur.
- `error_code` dolu olur.
- `error_message` dolu olur.
- `overwritten=False`

## Error mapping

Wrapperlar mevcut helperlardan gelen exceptionlari result contract icinde gorunur hale getirir.

Uygulanan temel mapping:

- `TypeError` -> `input_type_error`
- JSON serialization `TypeError` -> `serialization_error`
- `FileExistsError` -> `file_exists`
- `PermissionError` -> `permission_error`
- `FileNotFoundError` -> `parent_missing`
- genel `OSError` -> `io_error`
- beklenmeyen exception -> `unexpected_error`

`ValueError` mesajlari icin basit ve test edilebilir ozel mapping kullanilir:

- yanlis uzanti -> `wrong_extension`
- path traversal -> `path_traversal`
- `allowed_root` disi path -> `outside_allowed_root`
- directory target -> `directory_path`
- bos output path -> `empty_output_path`
- diger path/extension hatalari -> `path_or_extension_error`

Bu mapping mevcut helper exception mesajlarini degistirmez.

## Overwrite davranisi

`overwrite=False` varsayilan davranis olarak korundu.

Hedef dosya varsa ve `overwrite=False` kullaniliyorsa wrapper exception firlatmaz.

Bunun yerine:

```text
success=False
error_code="file_exists"
skipped_reason="file_exists"
overwritten=False
```

Mevcut dosya icerigi korunur.

`overwrite=True` ile yazim basariliysa yalniz hedef dosya degisir ve result icinde `overwritten=True` doner.

## Path safety ve allowed_root

Wrapperlar path safety kararlarini yeniden hesaplamaz.

Path safety, extension, traversal, missing parent, non-export area ve `allowed_root` davranislari mevcut `write_*` helperlari tarafindan uygulanir.

Wrapperlar bu sonucu sadece result contract'a cevirir.

Bu ayrim onemlidir:

- Guvenlik karari tek yerde kalir.
- Wrapper policy tekrar etmez.
- Mevcut helper testleri geriye uyumluluk siniri olarak kalir.

## Yapilmayanlar

Bu adimda su davranislar eklenmedi:

- hard validation
- `blocked` status
- audit event uretimi
- database/repository yazimi
- backup/restore davranisi
- API/GUI/CLI
- JSON veya Markdown export cikti dosyasi
- Podcast 027

Export basarisizligi `blocked` anlamina gelmez.

Wrapper sonucundaki `success=False`, yalnizca file-writing sonucunun gorunur hale getirilmesidir.

## Test kapsami

`tests/test_models.py` icinde JSON ve Markdown wrapper testleri eklendi.

Testlenen ana basliklar:

- basarili JSON result
- basarili Markdown result
- sabit result key seti
- non-dict JSON input
- serialize edilemeyen JSON input
- non-string Markdown input
- yanlis uzanti
- `allowed_root` disi path
- path traversal
- missing parent
- `overwrite=False` ile mevcut dosyayi koruma
- `overwrite=True` ile hedef dosyayi guncelleme
- mevcut exception tabanli `write_*` helper davranisinin korunmasi

Bu testler wrapper katmaninin gorunurluk sagladigini, fakat mevcut helper davranisini degistirmedigini kanitlar.
