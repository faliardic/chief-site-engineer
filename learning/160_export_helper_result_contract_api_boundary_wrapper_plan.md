# Adim 160 - Ogrenme Notu

Bu adimda export helper result contract API boundary / wrapper plan konusu ogrenme notu olarak aciklandi.

Bu adim kod yazmadi.

Yeni test eklemedi.

Mevcut helper davranisini degistirmedi.

Result contract wrapper implementasyonu yapmadi.

JSON veya Markdown export dosyasi uretmedi.

Hard validation eklemedi.

`blocked` status eklemedi.

Podcast 027 olusturulmadi.

## API boundary neden implementasyondan once cizilir?

API boundary, bir helper'in neyi yapacagini ve neyi yapmayacagini belirler.

Bu sinir implementasyondan once cizilmezse helper zamanla fazla sorumluluk alabilir.

Ornek riskler:

- Dosya yazan helper ayni zamanda diagnostic report hesaplamaya baslar.
- Result wrapper hard validation gibi yorumlanir.
- Export hatasi devir paketini otomatik bloke eder.
- Mevcut `Path` return bekleyen kodlar bozulur.

Bu nedenle Step 160 once wrapper sinirini cizer, implementasyon yapmaz.

## Exception helper ile result wrapper farki

Exception helper dusuk seviyeli ve Pythonic davranir.

Mevcut file-writing helperlar:

```text
Basari -> Path
Hata -> exception
```

Result wrapper ise kullaniciya donuk katmanlar icin okunur sonuc dondurur.

Olasil wrapper davranisi:

```text
Basari -> {"success": true, "output_path": "..."}
Hata -> {"success": false, "error_code": "..."}
```

Bu iki yaklasim birbirinin yerine gecmek zorunda degildir.

Dusuk seviyeli helper exception davranisini koruyabilir.

Wrapper bu davranisi kullaniciya donuk result contract'a cevirebilir.

## Mevcut helperlari hemen degistirmek neden risklidir?

Mevcut `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlari basarida `Path` dondurur.

Bunlari birden result dict dondurecek sekilde degistirmek risklidir.

Riskler:

- Eski testler kirilabilir.
- Mevcut cagiricilar `Path` yerine dict alir.
- Helper hem dosya yazma hem de sonuc raporlama sorumlulugunu tasir.
- Geriye uyumluluk zayiflar.

Bu nedenle mevcut helperlar kucuk ve net kalmalidir.

## Wrapper yaklasimi neden daha guvenli gecis saglar?

Wrapper yaklasimi iki katmani ayirir.

Mevcut helper:

- Dosyayi yazar.
- Basarida `Path` dondurur.
- Hatada exception verir.

Wrapper helper:

- Mevcut helper'i cagirir.
- Exception'i yakalar.
- Result contract dondurur.
- Handover QC veya raporlama katmanina okunur sonuc verir.

Bu gecis daha guvenlidir, cunku eski davranis korunur ve yeni davranis ayri API olarak eklenebilir.

## Handover QC icin result contract neden faydalidir?

Handover QC icin asil ihtiyac gorunurluktur.

Kullanici sunlari bilmelidir:

- Export denendi mi?
- Hangi path hedeflendi?
- Yazma basarili oldu mu?
- Yazma neden atlandi?
- Allowed-root disina mi cikildi?
- `overwrite=False` mevcut dosyayi korudu mu?

Result contract bu bilgileri duzenli alanlarla tasiyabilir.

Bu bilgiler devir paketini otomatik bloke etmek icin degil, insan incelemesini desteklemek icindir.

## Error mapping neden dikkat ister?

Exception'dan result contract'a gecis sadece hata mesajini string yapmak degildir.

Her hata kategorisi okunabilir ve test edilebilir hale gelmelidir.

Ornek mapping:

- `TypeError` -> `input_type_error`
- `ValueError` -> `path_or_extension_error`
- `FileExistsError` -> `file_exists`
- `PermissionError` -> `permission_error`
- `OSError` -> `io_error`

Bu mapping cok genel kalirsa path traversal ile wrong extension ayni gorunebilir.

Bu yuzden implementation asamasinda daha spesifik error code'lar da gerekebilir.

Step 160 bu konuyu planlar, kodlamaz.

## Sessiz basarisizlik neden kabul edilmez?

Dosya yazilmadiysa bunu sistem acikca gostermelidir.

Sessiz basarisizlikta kullanici export basarili sanabilir.

Bu ozellikle saha devri ve handover QC icin risklidir.

Wrapper result contract basarisiz durumda en az sunlari tasimalidir:

- `success=False`
- `error_code`
- `error_message` veya `skipped_reason`
- `attempted_path`

Boylece kullanici neyin duzeltilmesi gerektigini gorebilir.

## Bu adim ne yapmadi?

Bu adim:

- Kod yazmadi.
- Test yazmadi.
- Yeni helper implementasyonu yapmadi.
- Mevcut helper davranisini degistirmedi.
- Result contract wrapper implementasyonu yapmadi.
- Export dosyasi uretmedi.
- `exports/` icine `.json` veya `.md` dosyasi yazmadi.
- Hard validation eklemedi.
- `AuditEventRecord.__post_init__` degistirmedi.
- `FileAttachmentRecord` davranisini degistirmedi.
- `blocked` status eklemedi.
- Backup / restore davranisi eklemedi.
- Database / repository / API / GUI / CLI eklemedi.
- Audit event uretmedi.
- Podcast 027 olusturmadi.

## Sonuc

Adim 160'in dersi sudur:

Yeni result contract ihtiyaci, mevcut helperlari bozarak degil, ayri wrapper API boundary ile karsilanmalidir.

Bu sayede exception tabanli helperlar sade kalir, future result wrapper handover QC icin okunur sonuc saglar ve proje hard validation veya `blocked` status'a gecmeden guvenli gorunurluk uretir.
