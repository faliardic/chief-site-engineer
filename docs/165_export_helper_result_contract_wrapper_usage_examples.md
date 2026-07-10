# Adim 165 - Export Helper Result Contract Wrapper Usage Examples

Bu adimda Adim 163'te eklenen export helper result contract wrapper fonksiyonlari icin kullanim ornekleri ve boundary/example standardi belgelendi.

Odak wrapper fonksiyonlari:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Mevcut dusuk seviye helper fonksiyonlari:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Existing test matrix degistirilmedi.

Export helper davranisi degistirilmedi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Commit alinmadi.

Push yapilmadi.

## Kullanim amaci

Wrapper helperlar, export dosya yazma sonucunu standart ve okunabilir result contract ile ust katmana tasir.

Bu katman kullaniciya, handover QC'ye, ilerideki admin/debug ekranlarina veya guvenli raporlama akisina daha anlasilir sonuc verebilmek icin hazirlanmistir.

Wrapper sonucu exception stack trace yerine sabit alanlarla okunabilir:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Bu helperlar backup/restore sistemi degildir.

Bu helperlar GUI/API/CLI degildir.

Bu helperlar audit event uretmez.

Bu helperlar hard validation degildir.

Bu helperlar `blocked` status uretmez.

## Dusuk seviye helper / wrapper helper ayrimi

`write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` dusuk seviye, exception tabanli dosya yazma helperlaridir.

Bu helperlar basarili durumda `Path` dondurur.

Hata durumunda standart Python exception firlatir.

Bu davranis Python icinde dogrudan dosya yazma yapan kod icin uygundur.

`try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` result contract donduren guvenli wrapper katmanidir.

Wrapper helperlar mevcut dusuk seviye helper davranisini daraltmaz.

Mevcut helperlar korunur.

Legacy kullanim kirilmaz.

Result contract isteyen ust katman wrapper helperlari kullanir.

Exception tabanli akisi bilincli olarak yonetmek isteyen alt seviye kod `write_*` helperlari dogrudan kullanabilir.

## Ne zaman wrapper tercih edilmeli?

Wrapper helperlar su durumlarda tercih edilmelidir:

- Kullaniciya kisa ve okunabilir export sonucu gosterilecekse.
- Handover QC export sonucunu rapor icinde yorumlayacaksa.
- Admin/debug gorunumunde hata kategorisi standart alanlarla gosterilecekse.
- Export yazma basarisizligi uygulamayi durdurmadan raporlanacaksa.
- `success=False`, `error_code` ve `skipped_reason` gibi alanlar ust katmanda okunacaksa.

Wrapper kullanimi otomatik basari karari degildir.

Wrapper sadece dosya yazma sonucunu gorunur hale getirir.

## Ne zaman dusuk seviye helper kullanilabilir?

Dusuk seviye `write_*` helperlar su durumlarda kullanilabilir:

- Cagiran kod exception'i kendisi yakalayacaksa.
- Basarida yalniz `Path` donusu yeterliyse.
- Hata durumunda Python exception semantigi isteniyorsa.
- Wrapper result contract alanlari gerekmiyorsa.

Bu tercih mevcut helper davranisini korur.

Wrapper katmani bu helperlari ortadan kaldirmaz.

## Ornek 1 - Basarili JSON-ready dict export sonucu

JSON-ready dict hazir oldugunda wrapper ile `.json` dosyasina yazma sonucu okunabilir hale gelir.

Beklenen basari contract'i:

```text
success=True
file_type="json"
output_path="<written .json path>"
attempted_path="<requested .json path>"
error_code=None
error_message=None
skipped_reason=None
overwritten=False
```

Bu sonuc, export dosyasinin yazildigini ve hata alanlarinin bos oldugunu gosterir.

Handover QC bu sonucu "JSON export yazildi" olarak yorumlayabilir.

Bu sonuc database veya repository kaydi degistirmez.

## Ornek 2 - Basarili Markdown export sonucu

Markdown string hazir oldugunda wrapper ile `.md` dosyasina yazma sonucu standart alanlarla okunur.

Beklenen basari contract'i:

```text
success=True
file_type="markdown"
output_path="<written .md path>"
attempted_path="<requested .md path>"
error_code=None
error_message=None
skipped_reason=None
overwritten=False
```

Wrapper Markdown icerigini yeniden formatlamaz.

Wrapper yalniz dosya yazma sonucunu raporlar.

## Ornek 3 - Gecersiz veya izin verilmeyen path

Path traversal veya allowed-root disi hedefler guvenli hata contract'i ile gorunur hale gelir.

Beklenen yorum:

```text
success=False
output_path=None
attempted_path="<requested unsafe path>"
error_code="path_traversal" veya "outside_allowed_root"
skipped_reason=None
overwritten=False
```

Bu sonuc otomatik hard validation degildir.

Bu sonuc export yaziminin reddedildigini ve insan tarafindan incelenebilecegini gosterir.

## Ornek 4 - Var olan dosyada overwrite policy

`overwrite=False` guvenli varsayilandir.

Hedef dosya zaten varsa wrapper mevcut dosyayi korur ve skipped/hata contract'i dondurur.

Beklenen yorum:

```text
success=False
output_path=None
attempted_path="<existing target path>"
error_code="file_exists"
skipped_reason="file_exists"
overwritten=False
```

`overwrite=True` bilincli ve explicit tercih olmalidir.

Basarili explicit overwrite sonucunda:

```text
success=True
overwritten=True
```

Handover QC bu alanla mevcut export dosyasinin guncellenip guncellenmedigini anlayabilir.

## Ornek 5 - Parent directory yok veya uygun degil

Parent directory otomatik olusturulmaz.

Hedef path'in parent klasoru yoksa wrapper bunu hata contract'i olarak raporlar.

Beklenen yorum:

```text
success=False
output_path=None
attempted_path="<target path with missing parent>"
error_code="parent_missing"
overwritten=False
```

Bu davranis yanlis path ile yeni klasorlerin sessizce olusmasini engeller.

Klasor olusturma gerekiyorsa ayri ve explicit bir is akisinda ele alinmalidir.

## Ornek 6 - Serialize edilemeyen JSON input

JSON wrapper JSON-ready dict bekler.

Dict icinde JSON serialize edilemeyen object varsa yazma basarisiz olur ve result contract bunu gorunur hale getirir.

Beklenen yorum:

```text
success=False
file_type="json"
output_path=None
error_code="serialization_error"
overwritten=False
```

Bu sonuc input'un export icin hazir olmadigini gosterir.

Wrapper input'u mutate etmez.

Wrapper JSON-ready dict'i yeniden uretmez.

## Ornek 7 - Bos Markdown metni veya gecersiz metin

Markdown wrapper string input bekler.

Bos string politikasi helper davranisi ve test sozlesmesiyle uyumlu okunmalidir.

Gecerli bos string kabul ediliyorsa basari contract'i doner.

String olmayan input ise hata contract'i dondurur.

Beklenen gecersiz input yorumu:

```text
success=False
file_type="markdown"
output_path=None
error_code="input_type_error"
overwritten=False
```

Wrapper Markdown icerigini yeniden formatlamaz.

Wrapper Markdown icerigini olusturmaz.

## Ornek 8 - Ust katmanda kullaniciya gosterilecek kisa sonuc mesaji

Ust katman wrapper sonucunu kullaniciya kisa mesaj olarak cevirebilir.

Basarili sonuc icin:

```text
Export dosyasi yazildi.
```

`file_exists` icin:

```text
Export yazilmadi; hedef dosya zaten var.
```

`outside_allowed_root` icin:

```text
Export yazilmadi; hedef path izin verilen kok disinda.
```

Bu mesajlar karar mekanizmasi degildir.

Bu mesajlar kullaniciya dosya yazma sonucunu anlatir.

## Ornek 9 - Handover QC summary icin guvenli yorum

Handover QC result contract'i su sekilde yorumlayabilir:

```text
success=True -> Export dosyasi hazir.
success=False -> Export yazimi gozden gecirilmeli.
```

`success=False` devir paketini otomatik bloke etmez.

`blocked` status uretilmez.

Audit event uretilmez.

Database veya repository kaydi degismez.

Karar insanda kalir.

Wrapper sadece gorunurluk saglar.

## Boundary / yapilmayacaklar

Bu adimda kod yazilmayacak.

Yeni test yazilmayacak.

Existing test matrix degistirilmeyecek.

Export cikti dosyasi uretilmeyecek.

`exports/` icine dosya birakilmayacak.

Hard validation eklenmeyecek.

`blocked` status eklenmeyecek.

Backup/restore/API/GUI/CLI eklenmeyecek.

Audit event uretimi eklenmeyecek.

Database/repository davranisi eklenmeyecek.

ZIP stage edilmeyecek.

Commit yapilmayacak.

Push yapilmayacak.

## Test example standardization

Bu adimda test yazilmayacak.

Ancak ileride yazilabilecek testler icin ornek senaryo basliklari su sekilde standartlastirilabilir:

- `test_try_write_json_ready_dict_to_file_returns_success_contract`
- `test_try_write_markdown_text_to_file_returns_success_contract`
- `test_try_write_json_ready_dict_to_file_returns_error_contract_for_invalid_path`
- `test_try_write_markdown_text_to_file_returns_error_contract_for_invalid_path`
- `test_try_write_json_ready_dict_to_file_returns_file_exists_contract_when_overwrite_false`
- `test_try_write_markdown_text_to_file_returns_file_exists_contract_when_overwrite_false`
- `test_try_write_json_ready_dict_to_file_reports_parent_missing`
- `test_try_write_markdown_text_to_file_reports_parent_missing`
- `test_try_write_json_ready_dict_to_file_reports_serialization_error`
- `test_try_write_markdown_text_to_file_rejects_non_string_input`
- `test_try_write_markdown_text_to_file_does_not_mutate_input`
- `test_low_level_write_helpers_keep_exception_behavior`

Bu isimler ornek standardizasyon icindir.

Test dosyasi olusturulmaz.

Mevcut test dosyalari degistirilmez.

## Sonuc

Adim 165, wrapper helperlarin kullanim orneklerini ve boundary/example standardini belgeledi.

Bu adim result contract'i uygulamaya yeni davranis olarak eklemez.

Bu adim mevcut wrapper davranisini degistirmez.

Bu adim kullanici, handover QC ve ilerideki admin/debug gorunumleri icin result contract'in nasil okunacagini netlestirir.
