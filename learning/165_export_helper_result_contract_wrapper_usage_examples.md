# Adim 165 - Ogrenme Notu

Bu adimda export helper result contract wrapper usage examples konusu ogrenme notu olarak aciklandi.

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Export cikti dosyasi uretilmedi.

Commit alinmadi.

Push yapilmadi.

## Neden kullanim ornekleri gerekir?

Adim 163'te `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapperlari eklendi.

Adim 164'te bu wrapperlarin genel usage boundary'si belgelendi.

Adim 165 ise daha pratik soruya cevap verir:

```text
Bu wrapper sonucunu hangi senaryoda nasil okumaliyim?
```

Bu soru onemlidir, cunku result contract dogru okunmazsa `success=False` yanlislikla hard validation veya `blocked` status gibi algilanabilir.

Oysa wrapper sadece export dosya yazma sonucunu gorunur hale getirir.

## Dusuk seviye helper nasil dusunulmeli?

`write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` dusuk seviye helperlardir.

Bu helperlar basarili olursa `Path` dondurur.

Hata olursa exception firlatir.

Bu davranis Python kodu icin dogaldir.

Cagiran kod exception'i kendisi yakalayabilir.

Basarida yalniz dosya path'i gerekiyorsa bu helperlar yeterlidir.

## Wrapper helper nasil dusunulmeli?

`try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapper katmanidir.

Bu wrapperlar sonucu dict olarak dondurur.

Basari veya hata bilgisi sabit alanlarda gorulur:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Bu model kullanici mesajlari, handover QC veya admin/debug gorunumu icin daha okunabilirdir.

## Basarili JSON sonucu nasil okunur?

Basarili JSON wrapper sonucu su anlama gelir:

```text
success=True
file_type="json"
output_path dolu
error_code=None
```

Yani JSON-ready dict `.json` dosyasina yazilmistir.

Bu sonuc yeni bir database kaydi olusturmaz.

Bu sonuc audit event uretmez.

Bu sonuc backup dosyasi degildir.

## Basarili Markdown sonucu nasil okunur?

Basarili Markdown wrapper sonucu su anlama gelir:

```text
success=True
file_type="markdown"
output_path dolu
error_code=None
```

Markdown string `.md` dosyasina yazilmistir.

Wrapper Markdown icerigini yeniden formatlamaz.

Wrapper rapor metni uretmez.

Wrapper yalniz dosya yazma sonucunu raporlar.

## Gecersiz path sonucu nasil okunur?

`path_traversal` veya `outside_allowed_root` gibi hata kodlari, hedef path'in guvenli sinir disinda oldugunu anlatir.

Dogru yorum:

```text
Export yazilmadi; hedef path guvenli degil.
```

Yanlis yorum:

```text
Kayit reddedildi.
```

Path hatasi dosya yazma sonucudur.

Record validation karari degildir.

## Overwrite sonucu nasil okunur?

`overwrite=False` varsayilan olarak mevcut dosyayi korur.

Hedef dosya zaten varsa beklenen yorum sudur:

```text
success=False
error_code="file_exists"
skipped_reason="file_exists"
overwritten=False
```

Bu sonuc problemli olmak zorunda degildir.

Bu sonuc "dosya vardi, yazim atlandi" bilgisidir.

`overwrite=True` kullanildiysa ve yazim basariliysa `overwritten=True` gorulebilir.

Bu alan handover QC icin degerlidir, cunku mevcut dosyanin degisip degismedigini anlatir.

## Parent directory sonucu nasil okunur?

Parent directory yoksa wrapper bunu hata olarak raporlar.

Bu davranis guvenlidir.

Helper yanlis bir path nedeniyle yeni klasor agaci olusturmaz.

Dogru yorum:

```text
Export hedef klasoru hazir degil.
```

Bu otomatik backup/restore veya klasor kurulum mekanizmasi degildir.

## JSON serialization sonucu nasil okunur?

JSON-ready dict icinde serialize edilemeyen deger varsa `serialization_error` gorulebilir.

Bu sonuc input'un JSON export icin hazir olmadigini anlatir.

Wrapper input'u duzeltmez.

Wrapper input'u mutate etmez.

Ust katman input uretim akisini gozden gecirmelidir.

## Markdown input sonucu nasil okunur?

Markdown wrapper string bekler.

String olmayan input icin `input_type_error` beklenebilir.

Bos string davranisi mevcut helper sozlesmesine gore okunmalidir.

Wrapper Markdown metni uretmez.

Wrapper Markdown metnini yeniden formatlamaz.

## Kullanici mesaji nasil uretilir?

Wrapper result contract'i dogrudan teknik alanlar tasir.

Ust katman bu alanlari kisa kullanici mesajina cevirebilir.

Ornek:

```text
success=True -> Export dosyasi yazildi.
file_exists -> Export yazilmadi; hedef dosya zaten var.
outside_allowed_root -> Export yazilmadi; hedef path izin verilen kok disinda.
serialization_error -> Export yazilmadi; JSON icerigi hazir degil.
```

Bu mesajlar kullanici bilgilendirmesidir.

Bu mesajlar otomatik karar veya blokaj mekanizmasi degildir.

## Handover QC nasil okumali?

Handover QC wrapper sonucunu dosya yazma gorunurlugu olarak okumali.

`success=True` export dosyasinin yazildigini gosterir.

`success=False` export yaziminin basarisiz veya skipped oldugunu gosterir.

Dogru yorum:

```text
Export yazimi gozden gecirilmeli.
```

Yanlis yorum:

```text
Handover blocked oldu.
```

Karar insanda kalir.

Wrapper gorunurluk saglar.

## Test example standardization neden documentation-only?

Bu adimda test yazilmaz.

Ancak ileride test yazilacaksa isimlerin ne anlatmasi gerektigi simdiden belgelenebilir.

Ornek test isimleri:

- `test_try_write_json_ready_dict_to_file_returns_success_contract`
- `test_try_write_markdown_text_to_file_returns_success_contract`
- `test_try_write_json_ready_dict_to_file_returns_error_contract_for_invalid_path`
- `test_try_write_markdown_text_to_file_does_not_mutate_input`
- `test_low_level_write_helpers_keep_exception_behavior`

Bu isimler test dosyasina eklenmedi.

Bu isimler yalniz ilerideki test okunabilirligi icin ornek standarttir.

## Bu adimda ne yapilmadi?

Bu adimda su davranislar bilincli olarak eklenmedi:

- `app/models.py` degistirilmedi.
- `tests/test_models.py` degistirilmedi.
- Kod yazilmadi.
- Yeni test yazilmadi.
- Existing test matrix degistirilmedi.
- Export helper davranisi degistirilmedi.
- JSON veya Markdown export cikti dosyasi uretilmedi.
- `exports/` icine dosya birakilmadi.
- Hard validation eklenmedi.
- `blocked` status eklenmedi.
- Audit event uretilmedi.
- Backup/restore/API/GUI/CLI eklenmedi.
- Database/repository davranisi eklenmedi.
- ZIP stage edilmedi.

Adim 165, mevcut wrapper sonucunun nasil okunacagini orneklerle sabitleyen documentation-only adimidir.
