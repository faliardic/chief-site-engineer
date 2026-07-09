# Adim 160 - Export Helper Result Contract API Boundary / Wrapper Plan

Bu adimda mevcut exception tabanli file-writing helper davranisini bozmadan, ileride result contract wrapper katmaninin nasil eklenebilecegi documentation-only olarak planlandi.

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

Adim 155'te eklenen mevcut helperlar:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu helperlar exception tabanli dusuk seviyeli file-writing helperlar olarak kalmalidir.

Result contract ihtiyaci ileride dogarsa mevcut helperlarin return type'i dogrudan degistirilmemelidir.

Onerilen yaklasim, mevcut helperlari bozmayan ayri wrapper fonksiyonlar eklemektir.

Bu plan, wrapper API boundary'sini tarif eder; bu adimda wrapper implementasyonu yapmaz.

## Mevcut helperlar exception tabanli kalacak mi?

Evet.

Mevcut `write_*` helperlarin sorumlulugu kucuk ve nettir:

- Hazir JSON-ready dict veya Markdown string alir.
- Explicit output path'e yazar.
- Basarida `Path` dondurur.
- Hatada standart Python exception firlatir.

Bu davranis geriye uyumluluk icin korunmalidir.

Mevcut helperlari result dict dondurecek sekilde degistirmek eski testleri ve `Path` bekleyen cagirilari bozabilir.

## Result contract icin mevcut helperlar mi degisecek?

Hayir.

Planlanan karar sudur:

- Mevcut `write_*` helperlar degismez.
- Yeni `try_write_*` wrapper helperlar ileride eklenebilir.
- Wrapper helperlar mevcut helperlari cagirir.
- Wrapper helperlar exception yakalar.
- Wrapper helperlar result contract dict dondurur.

Bu sayede dusuk seviyeli dosya yazma davranisi ile kullaniciya donuk sonuc raporlama davranisi ayrilir.

## Onerilen wrapper yaklasimi

Wrapper katmani mevcut helper davranisini koruyarak daha okunur sonuc uretir.

Wrapper helperlar:

- Mevcut helper inputlariyla uyumlu olur.
- Mevcut helperlari cagirir.
- Basarida result dict dondurur.
- Hatada exception'i yakalayip result dict'e cevirir.
- Handover QC, export UI veya raporlama katmani icin daha guvenli cikti saglar.

Mevcut helperlar ise dusuk seviyeli, net ve testli kalir.

## Olasil wrapper fonksiyon isimleri

Gelecekte dusunulebilecek wrapper isimleri:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Bu isimler plan ornegidir.

Bu adimda bu fonksiyonlar eklenmedi.

## Wrapper result contract alanlari

Wrapper helperlar ileride ortak result contract dondurebilir.

Onerilen alanlar:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Alan anlamlari:

- `success`: Yazma basarili mi?
- `output_path`: Basarili yazilan dosya yolu.
- `attempted_path`: Denenen hedef path.
- `allowed_root`: Kullanilan allowed-root siniri.
- `file_type`: `json` veya `markdown`.
- `error_code`: Makine tarafindan okunabilir hata kategorisi.
- `error_message`: Insan tarafindan okunabilir hata mesaji.
- `skipped_reason`: Yazma yapilmadiysa net nedeni.
- `overwritten`: Mevcut dosya uzerine yazildi mi?

Bu contract, JSON ve Markdown wrapperlar icin ortak tutulabilir.

## API boundary

Wrapper inputlari mevcut helper inputlariyla uyumlu olmalidir.

JSON wrapper:

- JSON-ready dict input alir.
- Explicit output path alir.
- `overwrite` parametresini mevcut helper gibi yorumlar.
- `allowed_root` parametresini mevcut helper gibi kullanir.

Markdown wrapper:

- Markdown string input alir.
- Explicit output path alir.
- `overwrite` parametresini mevcut helper gibi yorumlar.
- `allowed_root` parametresini mevcut helper gibi kullanir.

Wrapper yapmayacaklari:

- Diagnostic report'u yeniden hesaplamaz.
- Soft validation report'u yeniden hesaplamaz.
- Format helper ciktisini degistirmez.
- Dosya yazma sonucundan baska karar uretmez.
- Database veya repository katmanina baglanmaz.
- API / GUI / CLI katmanina dogrudan baglanmaz.
- Audit event uretmez.
- Backup / restore baslatmaz.
- Hard validation tetiklemez.
- `blocked` status uretmez.

Wrapper yalniz dosya yazma sonucunu raporlar.

## Error mapping plani

Wrapper helperlar mevcut exception'lari result contract alanlarina cevirebilir.

Olasil genel mapping:

- `TypeError` -> `input_type_error`
- `ValueError` -> `path_or_extension_error`
- `FileExistsError` -> `file_exists`
- `PermissionError` -> `permission_error`
- `OSError` -> `io_error`
- Beklenmeyen exception -> `unexpected_error`

Bu mapping plan seviyesindedir.

Implementation sirasinda daha spesifik path safety kodlari gerekirse mevcut helper exception mesajlari veya ozel hata siniflari degerlendirilmelidir.

## Ozel durumlar

### `overwrite=False` ve dosya varsa

Beklenen wrapper sonucu:

```text
success=False
error_code="file_exists"
skipped_reason="file_exists" veya "overwrite_false"
overwritten=False
```

Mevcut dosya degismemelidir.

Bu davranis sessiz basarisizlik degildir. Result contract yazmanin neden yapilmadigini acikca tasir.

### `overwrite=True` ve yazim basariliysa

Beklenen wrapper sonucu:

```text
success=True
overwritten=True
error_code=None
error_message=None
skipped_reason=None
```

Eger hedef dosya daha once yoksa `overwritten=False` olabilir.

Wrapper bu ayrimi test edilebilir bicimde tasimalidir.

### `allowed_root` disi path

Beklenen wrapper sonucu:

```text
success=False
error_code="outside_allowed_root"
```

Bu durumda yazma yapilmaz.

`attempted_path` ve `allowed_root` alanlari hata incelemesini kolaylastirabilir.

### Path traversal

Beklenen wrapper sonucu:

```text
success=False
error_code="path_traversal"
```

Bu durumda yazma yapilmaz.

Traversal hatasi hard validation degil, file-writing safety hatasidir.

### Yanlis uzanti

Beklenen wrapper sonucu:

```text
success=False
error_code="wrong_extension"
```

JSON wrapper yalniz `.json`, Markdown wrapper yalniz `.md` hedefleri kabul etmelidir.

### Parent directory yok

Beklenen wrapper sonucu:

```text
success=False
error_code="parent_missing"
```

Wrapper parent directory olusturmamalidir.

Parent olusturma gelecekte istenirse ayri parametre, ayri test ve allowed-root siniriyle planlanmalidir.

## Geriye uyumluluk

Geriye uyumluluk karari:

- Mevcut `write_*` helperlar exception tabanli davranisini korur.
- Yeni `try_write_*` wrapperlar result contract dondurur.
- Eski testler kirilmaz.
- Yeni wrapper testleri ileride ayri eklenir.
- Mevcut `Path` return bekleyen cagiricilar etkilenmez.

Bu ayrim, dusuk seviyeli file writer ile kullaniciya donuk sonuc raporlama katmanini birlikte ama karismadan yasatir.

## Handover QC kullanimi

Wrapper sonucu ileride devir raporunda veya handover QC gorunumunde kullanilabilir.

Gosterilebilecek bilgiler:

- Export denendi mi?
- Hangi path hedeflendi?
- Yazma basarili oldu mu?
- Yazma neden yapilmadi?
- `overwrite=False` guvenlik freni mi devreye girdi?
- Hedef allowed-root disinda mi kaldi?
- Kullanici hangi aksiyonu almali?

Bu kullanim manuel inceleme ve gorunurluk icindir.

Export basarisizligi otomatik blokaj anlami tasimaz.

`blocked` status uretilmez.

Audit event uretilmez.

Backup / restore davranisi baslatilmaz.

## Sessiz basarisizlik yok

Wrapper katmaninin ana faydasi sessiz basarisizligi engellemektir.

Basarisiz yazimda:

- `success=False` olmalidir.
- `error_code` bos kalmamalidir.
- `error_message` veya `skipped_reason` kullaniciya yeterli sinyal tasimalidir.
- Yazma yapilmadiysa basari gibi raporlanmamalidir.

Bu prensip handover QC ve export raporlama icin kritiktir.

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

Adim 160'in karari sudur:

Result contract icin en guvenli yol, mevcut exception tabanli `write_*` helperlari koruyup ileride ayri `try_write_*` wrapper helperlar planlamaktir.

Bu yaklasim geriye uyumlulugu korur, mevcut testleri bozmaz, handover QC icin daha okunur sonuc saglar ve dosya yazma sonucunu hard validation veya `blocked` status'a donusturmeden gorunur kilar.
