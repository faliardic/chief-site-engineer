# Adim 164 - Export Helper Result Contract Wrapper Usage Documentation

Bu adimda Adim 163'te eklenen export helper result contract wrapper fonksiyonlarinin kullanim siniri belgelendi.

Mevcut wrapper fonksiyonlari:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Mevcut dusuk seviye helper fonksiyonlari:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut helper davranisi degistirilmedi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Podcast 027 olusturulmadi.

Commit alinmadi.

Push yapilmadi.

## Ana amac

`try_write_*` wrapperlari, dosya yazma sonucunu exception firlatmadan okunabilir result contract olarak raporlamak icin eklendi.

Bu wrapperlar veri uretmez.

Diagnostic veya soft validation sonucunu yeniden hesaplamaz.

Format helper ciktisini degistirmez.

Yalnizca mevcut `write_*` helperlarinin dosya yazma sonucunu gorunur hale getirir.

`write_*` helperlari dusuk seviye fonksiyonlar olarak kalir.

Bu helperlar basarili durumda `Path` dondurur.

Hata durumunda standart Python exception firlatir.

`try_*` wrapperlari ise mevcut helperlari cagirir, hatalari yakalar ve result dict dondurur.

## Kullanim akisi

Tipik akis su sekildedir:

1. Diagnostic veya soft validation report uretilir.
2. Format helper JSON-ready dict veya Markdown string uretir.
3. Dusuk seviye yazim isteniyorsa `write_*` helper dogrudan kullanilir.
4. Okunabilir result contract isteniyorsa `try_write_*` wrapper kullanilir.
5. Wrapper sonucu handover QC, admin/debug raporu veya manuel inceleme notu icinde yorumlanir.

Bu akista wrapper rapor olusturmaz.

Wrapper formatlama yapmaz.

Wrapper database veya repository kaydi degistirmez.

## JSON wrapper kullanimi

`try_write_json_ready_dict_to_file(...)` JSON-ready dict input alir.

Hedef path `.json` uzantili olmalidir.

`allowed_root` verilirse hedef path bu kok dizinin icinde kalmalidir.

`overwrite` varsayilani `False` kalir.

Basarili durumda:

- `success=True`
- `file_type="json"`
- `output_path` yazilan dosyayi gosterir.
- `attempted_path` hedeflenen dosyayi gosterir.
- `error_code=None`
- `error_message=None`
- `skipped_reason=None`

Hata durumunda:

- `success=False`
- `output_path=None`
- `attempted_path` mumkunse hedeflenen path olur.
- `error_code` hata turunu gosterir.
- `error_message` insan tarafindan okunabilir hata bilgisini tasir.
- `skipped_reason` yazim bilincli olarak atlandiysa dolar.

## Markdown wrapper kullanimi

`try_write_markdown_text_to_file(...)` Markdown string input alir.

Hedef path `.md` uzantili olmalidir.

`allowed_root` verilirse hedef path bu kok dizinin icinde kalmalidir.

`overwrite` varsayilani `False` kalir.

Wrapper Markdown icerigini yeniden formatlamaz.

Basarili durumda:

- `success=True`
- `file_type="markdown"`
- `output_path` yazilan dosyayi gosterir.
- `attempted_path` hedeflenen dosyayi gosterir.
- hata alanlari `None` olur.

Hata durumunda `success=False` doner.

Bu sonuc otomatik blokaj anlamina gelmez.

Bu sonuc yalnizca Markdown export yaziminin basarisiz veya skipped oldugunu gosterir.

## Result contract alanlari

Her wrapper sonucu ayni alanlari tasir:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

### success

Basarili durumda `True` olur.

Hata veya skipped durumda `False` olur.

Handover QC icin `False`, export yaziminin incelenmesi gerektigini gosterir.

`False` degerinin kendisi `blocked` status degildir.

### output_path

Basarili durumda yazilan dosya path'ini tasir.

Hata durumunda `None` olur.

Handover QC bu alan doluysa export dosyasinin nerede olustugunu gosterebilir.

### attempted_path

Basarili durumda hedeflenen path'i tasir.

Hata durumunda path biliniyorsa yine hedeflenen path'i tasir.

Handover QC bu alanla kullanicinin hangi hedefe yazmaya calistigini gorebilir.

### allowed_root

Basarili durumda verilen `allowed_root` degerini korur.

Hata durumunda da ayni deger raporlanir.

Handover QC allowed-root disi denemeleri bu alanla yorumlayabilir.

### file_type

JSON wrapper icin `json` olur.

Markdown wrapper icin `markdown` olur.

Handover QC ayni result schema icinde JSON ve Markdown sonucunu ayirt eder.

### error_code

Basarili durumda `None` olur.

Hata durumunda makine tarafindan okunabilir hata kodu olur.

Handover QC bu alanla hata kategorisini kisa ve standart bicimde gosterir.

### error_message

Basarili durumda `None` olur.

Hata durumunda insan tarafindan okunabilir hata mesajini tasir.

Bu alan hata ayiklama ve manuel inceleme icindir.

### skipped_reason

Basarili durumda `None` olur.

Yazim bilincli olarak atlandiysa sebep tasir.

Ornegin hedef dosya varken `overwrite=False` kullanildiginda `file_exists` gorulebilir.

### overwritten

Yeni dosya basarili yazildiysa `False` olur.

Mevcut hedef dosya `overwrite=True` ile basarili guncellendiyse `True` olur.

Hata durumunda `False` olur.

Handover QC bu alanla mevcut export dosyasinin guncellenip guncellenmedigini anlayabilir.

## Error code yorumlari

Wrapperlar hata durumlarini result contract icinde standart kodlarla raporlar.

- `input_type_error`: JSON icin dict olmayan input veya Markdown icin string olmayan input.
- `path_or_extension_error`: Genel path veya extension hatasi.
- `file_exists`: Hedef dosya var ve `overwrite=False`.
- `permission_error`: Dosya sistemi izin hatasi.
- `io_error`: Genel dosya sistemi / IO hatasi.
- `unexpected_error`: Beklenmeyen hata.
- `wrong_extension`: JSON icin `.json`, Markdown icin `.md` disi uzanti.
- `path_traversal`: Hedef path `..` traversal iceriyor.
- `outside_allowed_root`: Hedef path verilen `allowed_root` disinda.
- `parent_missing`: Hedef path'in parent klasoru yok.
- `directory_path`: Hedef path dosya yerine klasor.
- `empty_output_path`: Bos output path.
- `serialization_error`: JSON input serialize edilemiyor.

Bu hata kodlari otomatik hard validation degildir.

Bu hata kodlari export yazma sonucunu gorunur hale getirir.

## Overwrite kullanimi

`overwrite=False` guvenli varsayilandir.

Hedef dosya varsa wrapper `success=False` dondurebilir.

Bu durumda mevcut dosya korunur.

Beklenen yorum:

```text
success=False
error_code="file_exists"
skipped_reason="file_exists"
overwritten=False
```

`overwrite=True` bilincli ve explicit bir tercih olmalidir.

`overwrite=True` ile yazim basariliysa `overwritten=True` olarak yorumlanir.

Bu alan, mevcut export dosyasinin degisip degismedigini handover QC icin gorunur kilar.

## Path safety kullanimi

Export yaziminda explicit `output_path` kullanilmalidir.

Mumkunse `allowed_root` verilmelidir.

`allowed_root` disina yazma denemesi `success=False` olarak yorumlanir.

Path traversal denemesi `success=False` olarak yorumlanir.

Parent directory otomatik olusturulmadigi icin `parent_missing` gorulebilir.

`.git`, `.env`, cache, pycache, ZIP/yedek gibi alanlara yazma kapsam disidir.

Bu sinirlar repo sagligi ve saha/handover arsivi guvenligi icin korunur.

## Handover QC yorumu

`success=True`, export dosyasinin yazildigini gosterir.

`success=False`, export yaziminin basarisiz veya skipped oldugunu gosterir.

`success=False` devir paketini otomatik bloke etmez.

`blocked` status uretilmez.

Hata nedeni insan incelemesi icin gorunur hale gelir.

Export basarisizligi database veya repository kaydi degistirmez.

Wrapper audit event uretmez.

Handover QC bu sonucu su sekilde yorumlamalidir:

```text
Export yazimi gozden gecirilmeli.
```

Su sekilde yorumlamamalidir:

```text
Kayit reddedildi veya paket blocked oldu.
```

## Sinirlar

Wrapperlar diagnostic veya soft validation sonucunu yeniden hesaplamaz.

Wrapperlar format helper ciktisini degistirmez.

Wrapperlar input mutate etmez.

Wrapperlar database veya repository yazmaz.

Wrapperlar backup/restore baslatmaz.

Wrapperlar API/GUI/CLI eklemez.

Wrapperlar audit event uretmez.

Wrapperlar hard validation tetiklemez.

Wrapperlar `blocked` status uretmez.

Bu adim bu sinirlari kullanici ve gelistirici icin okunabilir hale getirir.
