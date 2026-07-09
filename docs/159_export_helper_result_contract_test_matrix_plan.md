# Adim 159 - Export Helper Result Contract Test Matrix Plan

Bu adimda Adim 157-158'de planlanan export helper result contract yaklasimi ileride uygulanacaksa hangi testlerin yazilacagi documentation-only olarak netlestirildi.

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut helper davranisi degistirilmedi.

Result contract implementasyonu yapilmadi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 027 olusturulmadi.

## Ana hedef

Bu test matrix'in hedefi, ileride result contract implementasyonu yapilirsa test edilecek davranislari onceden netlestirmektir.

Mevcut `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper davranislari bu adimda degismeyecektir.

Bu adim yalniz plan adimidir.

Test matrix, future wrapper/helper katmaninin basari, hata, path safety, overwrite, IO ve regression davranislarini kapsamalidir.

## A. Basari result contract testleri

Basari testleri, future result contract'in yazma basarili oldugunda tutarli alanlar dondurdugunu kanitlamalidir.

Testlenmesi gerekenler:

- JSON export basarili olursa `success=True`.
- Markdown export basarili olursa `success=True`.
- `output_path` dogru hedef dosyayi gosterir.
- `file_type` JSON icin `json` dondurur.
- `file_type` Markdown icin `markdown` dondurur.
- Yeni dosya yaziminda `overwritten=False` olur.
- `overwrite=True` ile mevcut dosya guncellendiginde `overwritten=True` olur.
- Basarili durumda `error_code` bos veya `None` olur.
- Basarili durumda `error_message` bos veya `None` olur.
- Basarili durumda `skipped_reason` bos veya `None` olur.
- `attempted_path` hedef path'i dogru ve normalize edilmis bicimde tasir.
- `allowed_root` kullanildiysa result icinde dogru raporlanir.

Bu testler, basari sonucunun kullaniciya ve handover QC'ye okunur bicimde tasinabildigini gosterir.

## B. JSON input testleri

JSON input testleri, JSON result wrapper'in yalniz JSON-ready dict sinirini korudugunu ve hata durumlarini sessizce yutmadigini kanitlamalidir.

Testlenmesi gerekenler:

- JSON-ready dict basarili olur.
- Bos dict politikasi net testlenir.
- Non-dict input result contract ile guvenli hata verir.
- Serialize edilemeyen object hata contract'i uretir.
- Input dict mutate edilmez.
- Diagnostic report yeniden hesaplanmaz.
- Soft validation report yeniden hesaplanmaz.

Olasil hata kodlari:

- `invalid_json_input`
- `json_not_serializable`
- `empty_content`

Bos dict kabul edilecekse result `success=True` olabilir. Bos dict reddedilecekse `success=False` ve net bir `error_code` beklenmelidir.

Bu karar implementation oncesi netlestirilmelidir.

## C. Markdown input testleri

Markdown input testleri, Markdown result wrapper'in string input sinirini korudugunu ve formatter ciktisini degistirmedigini kanitlamalidir.

Testlenmesi gerekenler:

- String input basarili olur.
- Bos string politikasi net testlenir.
- Non-string input result contract ile guvenli hata verir.
- Markdown icerik yeniden formatlanmaz.
- Input string mutate edilmez.

Olasil hata kodlari:

- `invalid_markdown_input`
- `empty_content`

Bos string kabul edilecekse result `success=True` olabilir. Bos string reddedilecekse `success=False` ve net bir `error_code` beklenmelidir.

## D. Path safety testleri

Path safety testleri result contract'in en kritik test grubudur.

Testlenmesi gerekenler:

- Bos `output_path` hata contract'i uretir.
- Klasor path dosya hedefi gibi verilirse hata contract'i uretir.
- Yanlis uzanti hata contract'i uretir.
- JSON helper yalniz `.json` kabul eder.
- Markdown helper yalniz `.md` kabul eder.
- `..` traversal hata contract'i uretir.
- `allowed_root` disi path hata contract'i uretir.
- `allowed_root` ici path basarili olur.
- Mixed separator davranisi testlenir.
- Parent directory yoksa hata contract'i uretir.
- `.git` altina yazma reddedilir.
- `.env` veya environment dosyalarina yazma reddedilir.
- Cache alanlarina yazma reddedilir.
- `__pycache__` alanlarina yazma reddedilir.
- ZIP/yedek alanlarina yazma reddedilir.

Olasil hata kodlari:

- `empty_path`
- `directory_target`
- `wrong_extension`
- `path_traversal`
- `outside_allowed_root`
- `missing_parent`
- `non_export_area`

Bu testler, result contract'in guvenlik hatalarini okunur ve standart bicimde tasidigini kanitlar.

## E. Overwrite policy testleri

Overwrite testleri, `overwrite=False` guvenlik freninin result contract icinde de gorunur kaldigini kanitlamalidir.

Testlenmesi gerekenler:

- Hedef dosya yok ve `overwrite=False` ise yazim basarili olur.
- Hedef dosya var ve `overwrite=False` ise yazma yapilmaz.
- Hedef dosya var ve `overwrite=False` icin `success=False` olur.
- Hedef dosya var ve `overwrite=False` icin `skipped_reason` net olur.
- Hedef dosya var ve `overwrite=True` ise hedef guncellenir.
- `overwrite=True` sadece hedef dosyayi degistirir.
- `overwrite=False` iken mevcut icerik korunur.

Olasil result beklentileri:

```text
success=False
error_code="file_exists"
skipped_reason="overwrite_false"
overwritten=False
```

`overwrite=True` basariliysa:

```text
success=True
overwritten=True
error_code=None
skipped_reason=None
```

## F. IO / permission testleri

IO ve permission testleri environment kaynakli hatalarin sessiz kalmadigini kanitlamalidir.

Testlenmesi gerekenler:

- Permission error result contract'a tasinir.
- File locked veya erisilemez dosya davranisi planlanir.
- Disk veya genel IO error davranisi planlanir.
- Sessiz basarisizlik olmaz.

Olasil hata kodlari:

- `permission_error`
- `io_error`
- `file_locked`

Bu testler platform farkliliklari nedeniyle dikkatli tasarlanmalidir. Windows ve diger ortamlarda file lock/permission davranisi farkli olabilir.

## G. Boundary regression testleri

Boundary regression testleri, result contract implementasyonu geldiginde mevcut veri omurgasinin bozulmadigini kanitlamalidir.

Testlenmesi gerekenler:

- `write_json_ready_dict_to_file(...)` mevcut exception davranisi gerekiyorsa korunur veya wrapper ile ayrilir.
- `write_markdown_text_to_file(...)` mevcut exception davranisi gerekiyorsa korunur veya wrapper ile ayrilir.
- Format helper davranislari degismez.
- Diagnostic report helper davranislari degismez.
- Soft validation report helper davranislari degismez.
- `AuditEventRecord.__post_init__` daraltilmaz.
- `FileAttachmentRecord` davranisi degismez.
- Hard validation eklenmez.
- `blocked` status uretilmez.

Bu testler, result contract'in dosya yazma sonucunu raporlayan bir gorunurluk katmani olarak kaldigini ve kayit reddi mekanizmasina donusmedigini garanti eder.

## H. Handover QC kullanimi testleri

Handover QC testleri future result contract'in kullaniciya okunur veri tasidigini, fakat devir paketini otomatik bloke etmedigini kanitlamalidir.

Testlenmesi gerekenler:

- Hata contract'i kullaniciya gosterilebilir veri tasir.
- `output_path` ve `attempted_path` ayrimi net olur.
- `allowed_root` disina yazma net hata uretir.
- `overwrite=False` sonucu `skipped` olarak raporlanabilir.
- Export basarisizligi devir paketini otomatik bloke etmez.
- Audit event uretmez.

Bu testler handover QC'nin manuel inceleme ve gorunurluk katmani olarak kalmasini saglar.

## Result contract alanlari icin test anlamlari

### `success`

Basarili durumda:

- `True` olmalidir.

Hata durumunda:

- `False` olmalidir.

Dolacagi senaryolar:

- Tum result contract senaryolarinda bulunmalidir.

### `output_path`

Basarili durumda:

- Yazilan dosya path'ini tasimalidir.

Hata durumunda:

- Bos veya `None` olabilir.

Dolacagi senaryolar:

- Basarili JSON ve Markdown yazimlari.

### `attempted_path`

Basarili durumda:

- Denenen hedef path'i tasiyabilir.

Hata durumunda:

- Hata veren hedef path'i tasimalidir.

Dolacagi senaryolar:

- Path safety hatalari.
- Overwrite engeli.
- IO/permission hatalari.
- Basarili yazimlarda da traceability icin dolabilir.

### `allowed_root`

Basarili durumda:

- `allowed_root` kullanildiysa raporlanmalidir.

Hata durumunda:

- `outside_allowed_root` gibi hatalarda raporlanmalidir.

Dolacagi senaryolar:

- Allowed-root ic/dis path testleri.
- Handover QC traceability senaryolari.

### `file_type`

Basarili durumda:

- JSON icin `json`.
- Markdown icin `markdown`.

Hata durumunda:

- Hangi wrapper/helper denendiyse onu gostermelidir.

Dolacagi senaryolar:

- Tum JSON ve Markdown result contract testleri.

### `error_code`

Basarili durumda:

- Bos veya `None` olmalidir.

Hata durumunda:

- Makine tarafindan okunabilir hata kategorisi tasimalidir.

Dolacagi senaryolar:

- Path safety hatalari.
- Input validation hatalari.
- Overwrite engeli.
- IO/permission hatalari.

### `error_message`

Basarili durumda:

- Bos veya `None` olmalidir.

Hata durumunda:

- Insan tarafindan okunabilir, guvenli hata mesaji tasimalidir.

Dolacagi senaryolar:

- Kullaniciya gosterilebilir hata gereken tum basarisiz result'lar.

### `skipped_reason`

Basarili durumda:

- Bos veya `None` olmalidir.

Hata durumunda:

- Yazma bilincli olarak atlandiysa net neden tasimalidir.

Dolacagi senaryolar:

- `overwrite=False` ve hedef dosya mevcut.
- Parent directory yoklugu nedeniyle yazma yapilmadi.
- Policy kaynakli path reddi.

### `overwritten`

Basarili durumda:

- Yeni dosya yaziminda `False`.
- `overwrite=True` ile mevcut dosya guncellendiginde `True`.

Hata durumunda:

- Genellikle `False` olmalidir.

Dolacagi senaryolar:

- Basarili overwrite.
- Basarili yeni dosya yazimi.
- Overwrite engeli.

## Bu adimda yapilmayanlar

Bu adimda:

- Result contract implementasyonu yapilmadi.
- Yeni test eklenmedi.
- Mevcut helper davranisi degistirilmedi.
- JSON veya Markdown export dosyasi uretilmedi.
- Audit event uretimi eklenmedi.
- Backup / restore baslatilmadi.
- Database / repository / API / GUI / CLI eklenmedi.
- Hard validation eklenmedi.
- `blocked` status uretilmedi.
- Diagnostic veya soft validation sonucu yeniden hesaplanmadi.
- Format helper ile file-writing helper ayrimi bozulmadi.

## Sonuc

Adim 159'un karari sudur:

Future result contract implementation'a gecilmeden once basari, input, path safety, overwrite, IO, boundary regression ve handover QC testleri netlestirilmelidir.

Bu test matrix, result contract'in sessiz basarisizlik uretmemesini, mevcut helperlari kirmamasini ve handover QC gorunurlugunu hard validation'a donusturmemesini garanti etmeye hazirliktir.
