# Adim 158 - Export Helper Result Contract Implementation Plan

Bu adimda Adim 157'de planlanan export helper error/result contract yaklasiminin ileride nasil uygulanabilecegi documentation-only olarak netlestirildi.

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut helper davranisi degistirilmedi.

Result contract implementasyonu yapilmadi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 027 olusturulmadi.

## Result contract implementation amaci

Result contract implementation'in amaci, dosya yazma sonucunu kullaniciya donuk katmanlarda standart, okunur ve sessiz basarisizliga izin vermeyen bir bicimde temsil etmektir.

Mevcut helperlar dusuk seviyeli Python file-writing helperlari olarak kalir.

Gelecekte daha yuksek seviyeli bir katman, bu helperlari cagirip basari veya hata sonucunu sozlesmeli bir result dict'e cevirebilir.

Bu plan, result contract'in nasil uygulanabilecegini tarif eder; bu adimda uygulama yapmaz.

## Mevcut exception davranisi neden hemen degistirilmiyor?

Adim 155 helperlari basarili yazimda `Path` dondurur ve hata durumunda standart Python exception kullanir.

Bu davranis:

- Python icin dogaldir.
- Testlerde nettir.
- Dusuk seviyeli helperlari kucuk tutar.
- Geriye uyumludur.
- Sessiz basarisizlik uretmez.

Bu nedenle mevcut helper return type'i hemen degistirilmemelidir.

Mevcut helperlari dogrudan result dict dondurecek sekilde degistirmek, cagiricilarin `Path` bekleyen kullanimini bozabilir ve helperlari hem dosya yazan hem de kullaniciya donuk rapor ureten katmana donusturebilir.

## Helperlar mi degisecek, wrapper/helper katmani mi eklenecek?

Onerilen yaklasim wrapper/helper katmanidir.

Dusuk seviyeli helperlar:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu helperlar mevcut davranisini korur:

- Basarida `Path` dondurur.
- Hatada exception firlatir.

Gelecekte result contract icin ayri helperlar planlanabilir.

Olasil isimler:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`
- `build_export_write_result(...)`

Bu isimler yalniz plan ornegidir. Bu adimda eklenmedi.

Wrapper katmani exception'lari yakalayabilir, basari durumunu standart alanlara cevirebilir ve kullaniciya donuk katmanlara result dict verebilir.

## Geriye uyumluluk yaklasimi

Geriye uyumluluk icin mevcut helper imzalari ve return type'i korunmalidir.

Mevcut helperlari kullanan kod:

```text
Path return bekler.
Exception ile hata alir.
```

Future result helper kullanan kod:

```text
Result dict bekler.
success alanini okur.
error_code ve error_message ile kullaniciya bilgi tasir.
```

Bu ayrim, iki kullanim biciminin birbirini bozmasini engeller.

## Onerilen result contract alanlari

Gelecekteki result dict en az su alanlari dusunebilir:

- `success`
- `output_path`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`
- `attempted_path`
- `allowed_root`
- `file_type`

Alan anlamlari:

- `success`: Yazma basarili mi?
- `output_path`: Basarili yazilan dosya yolu.
- `error_code`: Makine tarafindan okunabilir hata kategorisi.
- `error_message`: Insan tarafindan okunabilir hata mesaji.
- `skipped_reason`: Yazma bilincli olarak atlandiysa nedeni.
- `overwritten`: Mevcut dosya uzerine yazildi mi?
- `attempted_path`: Denenen hedef path.
- `allowed_root`: Kullanilan izinli kok path.
- `file_type`: `json` veya `markdown`.

Bu alanlar plan seviyesindedir. Bu adimda dict uretilmedi.

## JSON ve Markdown icin ortak contract

JSON export ve Markdown export icin ortak result contract kullanilabilir.

Ortak alanlar:

- `success`
- `output_path`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`
- `attempted_path`
- `allowed_root`
- `file_type`

`file_type` alani JSON ve Markdown ayrimini tasir.

JSON'a ozel hatalar `error_code` ile temsil edilebilir:

- `invalid_json_input`
- `json_not_serializable`

Markdown'a ozel hatalar:

- `invalid_markdown_input`

Ortak contract, handover QC ekran veya raporunun JSON ve Markdown sonucunu ayni sekilde okumasini kolaylastirir.

## Path safety hatalarinin temsili

Path safety hatalari result contract icinde `success=False` ile temsil edilebilir.

Olasil `error_code` degerleri:

- `empty_path`
- `directory_target`
- `wrong_extension`
- `path_traversal`
- `outside_allowed_root`
- `missing_parent`
- `non_export_area`

Bu hatalarda `output_path` bos kalabilir.

`attempted_path` kullaniciya hangi hedefin denendigini gosterebilir.

`allowed_root`, allowed-root disina cikma hatasinin anlasilmasini kolaylastirabilir.

## Input validation hatalarinin temsili

Input validation hatalari dosya yazma denenmeden once result contract'a cevrilebilir.

JSON helper wrapper'i icin:

- Non-dict input: `error_code="invalid_json_input"`
- Serialize edilemeyen input: `error_code="json_not_serializable"`

Markdown helper wrapper'i icin:

- Non-string input: `error_code="invalid_markdown_input"`

Bos icerik politikasi gelecekte ayrica tasarlanabilir.

Bos dict veya bos string kabul edilecekse `success=True` olabilir. Reddedilecekse `success=False` ve `error_code="empty_content"` gibi bir alan planlanabilir.

Bu karar kod degisikligi olmadan, ayri test matrix ile verilmelidir.

## `overwrite=False` ve mevcut dosya davranisi

Mevcut dusuk seviyeli helper davranisi:

```text
overwrite=False + hedef dosya var -> FileExistsError
```

Future result wrapper icin olasi davranis:

```text
success=False
error_code="file_exists"
skipped_reason="overwrite_false"
overwritten=False
```

Bu durumda yazma yapilmaz.

Bu bir sessiz basarisizlik degildir. Result dict, dosyanin neden yazilmadigini acikca tasir.

Mevcut helper davranisi exception olarak kalabilir; wrapper bu exception'i result dict'e cevirebilir.

## `overwrite=True` basari davranisi

`overwrite=True` explicit verildiginde ve yazma basarili oldugunda result contract su bilgiyi tasiyabilir:

```text
success=True
output_path="<resolved or display path>"
overwritten=True
skipped_reason=None
error_code=None
error_message=None
```

Eger hedef dosya daha once yoksa `overwritten=False` kalabilir.

Bu ayrim, kullaniciya yeni dosya mi uretildi yoksa mevcut dosya mi guncellendi bilgisini verebilir.

## Parent directory yoksa davranis

Mevcut helper parent directory otomatik olusturmaz.

Parent directory yoksa hata verir.

Future result wrapper bu durumu su sekilde temsil edebilir:

```text
success=False
error_code="missing_parent"
skipped_reason="parent_directory_missing"
```

Bu davranis klasor olusturma anlamina gelmez.

Parent olusturma gelecekte istenirse ayri parametre, ayri test ve allowed-root siniriyle planlanmalidir.

## `allowed_root` disi path davranisi

`allowed_root` disina yazma kritik guvenlik bariyeridir.

Future result contract:

```text
success=False
error_code="outside_allowed_root"
attempted_path="<target>"
allowed_root="<root>"
```

Bu durumda yazma yapilmaz.

Bu hata kayit reddi veya hard validation degildir; dosya yazma guvenlik sinirinin calistigini gosterir.

## Wrong extension davranisi

JSON helper yalniz `.json` hedefe yazmalidir.

Markdown helper yalniz `.md` hedefe yazmalidir.

Future result contract:

```text
success=False
error_code="wrong_extension"
file_type="json" veya "markdown"
```

Bu davranis, format helper ile file-writing helper ayrimini korur ve yanlis dosya turune yazmayi engeller.

## Serialize edilemeyen JSON input davranisi

JSON-ready dict icinde serialize edilemeyen object varsa mevcut helper standart Python exception verir.

Future result wrapper bu durumu su sekilde temsil edebilir:

```text
success=False
error_code="json_not_serializable"
file_type="json"
```

Bu hata JSON formatter davranisini degistirmez.

Wrapper diagnostic veya soft validation report'u yeniden hesaplamaz.

## Non-string Markdown input davranisi

Markdown helper string input bekler.

Non-string input icin future result wrapper:

```text
success=False
error_code="invalid_markdown_input"
file_type="markdown"
```

Bu hata Markdown icerigini otomatik stringify etmez.

Input'u sessizce cevirmek yanlis kullanimi gizleyebilir.

## IO ve permission error davranisi

Izin, kilitli dosya, disk veya genel IO hatalari environment kaynakli olabilir.

Future result wrapper bu hatalari su sekilde temsil edebilir:

```text
success=False
error_code="io_error" veya "permission_error"
error_message="<safe message>"
```

Mesaj kullaniciya yardimci olmali, fakat gereksiz hassas sistem bilgisini tasimamali.

Bu adimda ozel hata yakalama veya message sanitization implementasyonu yapilmadi.

## Sessiz basarisizlik yapilmamasi

Result contract'in en kritik prensibi sessiz basarisizliga izin vermemesidir.

Hata varsa:

- Exception dusuk seviyede gorunur olur.
- Future wrapper'da `success=False` gorunur olur.
- `error_code` veya `skipped_reason` bos birakilmaz.

Yazma yapilmadiysa sistem bunu basarili gibi sunmamalidir.

## Handover QC kullanimi

Gelecekte handover QC ekran veya raporu result contract'i su amaclarla kullanabilir:

- Export denendi mi?
- Hangi path hedeflendi?
- Yazma basarili oldu mu?
- Mevcut dosya overwrite edilmedi mi?
- Hedef allowed root icinde mi?
- JSON veya Markdown cikti hangi dosyaya yazildi?
- Kullanici manuel olarak neyi duzeltmeli?

Bu kullanim gorunurluk ve manuel inceleme icindir.

Handover QC result contract'i devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek ve hard validation baslatmayacaktir.

## Korunan sinirlar

Bu plan kapsaminda:

- Audit event uretimi hala yapilmayacak.
- Backup / restore baslatilmayacak.
- Database / repository / API / GUI / CLI eklenmeyecek.
- Hard validation yoktur.
- `blocked` status uretilmeyecektir.
- Format helper ile file-writing helper ayrimi korunacaktir.
- Mevcut diagnostic report yeniden hesaplanmayacaktir.
- Mevcut soft validation report yeniden hesaplanmayacaktir.

## Sonuc

Adim 158'in karari sudur:

Mevcut exception tabanli file-writing helperlar korunur.

Gelecekte result contract gerekiyorsa, bunu mevcut helperlari kirmadan ayri bir wrapper/helper katmani saglamalidir.

Bu result contract JSON ve Markdown icin ortak alanlar kullanabilir, path safety/input/overwrite/IO hatalarini standart `error_code` ve `skipped_reason` alanlariyla gorunur kilabilir ve handover QC icin sessiz basarisizligi engelleyebilir.
