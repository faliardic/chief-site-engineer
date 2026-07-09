# Adim 157 - Export Helper Error / Result Contract Plan

Bu adimda Adim 155'te eklenen read-only file writing helper fonksiyonlarinin hata ve basari sozlesmesi documentation-only olarak netlestirildi.

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut helper davranisi degistirilmedi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 027 olusturulmadi.

## Error / result contract amaci

Export helper error/result contract'in amaci, dosya yazma sonucunun cagirici tarafindan nasil okunacagini netlestirmektir.

File-writing helper basarili oldugunda hedef dosyanin nerede olustugunu acikca bildirmelidir.

File-writing helper basarisiz oldugunda hata sessiz kalmamalidir.

Bu sozlesme ozellikle handover QC ve saha devri ciktilari icin onemlidir. Yanlis path, mevcut dosyanin uzerine yazma riski, allowed root disina cikma veya serialize edilemeyen JSON gibi durumlar gorunur olmalidir.

## Mevcut helper basari davranisi

Adim 155'te eklenen helperlar basarili yazimda `Path` nesnesi dondurur.

Bu mevcut davranis korunur.

Bu adimda return type degistirilmedi.

Bu adimda result object implementasyonu yapilmadi.

## `write_json_ready_dict_to_file(...)` basari davranisi

`write_json_ready_dict_to_file(...)` basarili oldugunda:

- JSON-ready dict input'u `.json` uzantili hedef dosyaya UTF-8 ile yazar.
- JSON ciktisini deterministic bicimde uretir.
- Input dict'i mutate etmez.
- Diagnostic report'u yeniden hesaplamaz.
- Soft validation report'u yeniden hesaplamaz.
- Formatter helper davranisini degistirmez.
- Basarili yazilan hedefi `Path` nesnesi olarak dondurur.

Basarili yazim kayit reddi, hard validation, audit event veya backup/restore anlami tasimaz.

## `write_markdown_text_to_file(...)` basari davranisi

`write_markdown_text_to_file(...)` basarili oldugunda:

- Markdown string input'u `.md` uzantili hedef dosyaya UTF-8 ile yazar.
- Markdown icerigini yeniden formatlamaz.
- Input string'i degistirmez.
- Diagnostic report'u yeniden hesaplamaz.
- Soft validation report'u yeniden hesaplamaz.
- Formatter helper davranisini degistirmez.
- Basarili yazilan hedefi `Path` nesnesi olarak dondurur.

Basarili yazim yalniz hazir Markdown metninin guvenli dosyaya tasindigini anlatir.

## Return value secenekleri

Export helper sozlesmesi icin uc olasi donus bicimi vardir:

- `Path` nesnesi.
- String path.
- Gelecekte result dict.

Mevcut helper davranisi `Path` nesnesidir.

Bu tercih Python tarafinda dogal ve test edilebilir bir donus saglar. Cagirici isterse `str(returned_path)` ile string'e cevirebilir.

String path dondurmek, CLI veya JSON response gibi sinirlerde okunabilir olabilir; fakat Python icinde path islemlerini zayiflatabilir.

Result dict ise daha zengin hata ve basari bilgisi tasiyabilir; fakat mevcut helperlari daha karmasik hale getirir.

Bu nedenle mevcut asamada `Path` donusu korunur. Gelecekte gerekiyorsa ayri bir result helper veya wrapper planlanabilir.

## Mevcut davranis mi, gelecekte result helper mi?

Mevcut davranis korunmalidir:

- Basarili yazim `Path` dondurur.
- Basarisiz yazim standart Python exception ile gorunur olur.

Gelecekte handover QC, CLI veya API gibi kullaniciya donuk sinirlar eklenirse ayri bir result contract helper planlanabilir.

Bu ayri helper, mevcut dusuk seviyeli file-writing helperlari sarmalayabilir ve exception'lari okunur result dict'e cevirebilir.

Bu yaklasim, kucuk file-writing helper ile kullaniciya donuk result modelini birbirine karistirmadan ilerlemeyi saglar.

## Exception tabanli hata davranisi

Exception tabanli modelde hata oldugunda fonksiyon normal return yapmaz.

Ornek hata siniflari:

- `TypeError`
- `ValueError`
- `FileExistsError`
- `FileNotFoundError`
- `PermissionError`
- `OSError`

Bu model, Python helper seviyesinde acik ve dogrudan bir davranistir. Testlerde belirli hata turleri beklenebilir ve sessiz basarisizlik riski azalir.

Mevcut asamada standart Python exception kullanimi uygundur, cunku helperlar API/GUI/CLI degil dusuk seviyeli dosya yazma yardimcilaridir.

## Result-object tabanli hata davranisi

Result-object modelinde fonksiyon exception firlatmak yerine sozlesmeli bir dict dondurebilir.

Olasil alanlar:

- `success`
- `output_path`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Bu model kullaniciya donuk katmanlarda faydali olabilir. Handover QC raporu, CLI ciktisi veya ileride API response icin hata mesajini standart bir sekilde tasiyabilir.

Fakat bu adimda result object implementasyonu yapilmadi.

Result object planlanacaksa ayri adimda, test matrix ve geri uyumluluk karariyla ele alinmalidir.

## Path safety hatalari

Path safety hatalari dosya yaziminin en kritik bolumudur.

Net gorunmesi gereken durumlar:

- Bos path.
- Klasor path'in dosya hedefi gibi verilmesi.
- Yanlis uzanti.
- Path traversal.
- `..` path parcalari.
- `allowed_root` disina cikma.
- Parent directory'nin olmamasi.

Bu hatalar sessizce yutulmamalidir.

Bos path veya klasor path gibi durumlarda helper yazma yapmamalidir.

Yanlis uzanti JSON helper icin `.json`, Markdown helper icin `.md` sinirini korumak icin hata olmalidir.

Traversal ve `allowed_root` disina cikma, guvenlik bariyeri olarak gorunur hata vermelidir.

Parent directory yoksa mevcut davranis otomatik klasor olusturmak yerine hata vermektir.

## Input hatalari

Input hatalari helper sozlesmesinin dosya yazmadan once durmasi gereken durumlardir.

JSON helper icin:

- Non-dict JSON input hata olmalidir.
- Serialize edilemeyen JSON input hata olmalidir.

Markdown helper icin:

- Non-string Markdown input hata olmalidir.

Bos icerik politikasi ayrica acik tutulmalidir.

Bos dict veya bos string, proje ihtiyacina gore gelecekte ayri politika isteyebilir. Bu politika kayit reddi, hard validation veya `blocked` status anlami tasimamalidir.

## Overwrite hatalari

Overwrite sozlesmesi guvenli varsayilan uzerine kuruludur:

```text
overwrite=False
```

Hedef dosya zaten varsa ve `overwrite=False` ise helper yazma yapmamalidir.

Bu durumda hata gorunur olmalidir.

`overwrite=True` explicit verildiginde yazma basarili olabilir ve sadece hedef dosya guncellenmelidir.

Gelecekte result dict kullanilirsa `overwritten` alani bu davranisi kullaniciya gorunur kilabilir.

## File system hatalari

File system hatalari helperin kontrol ettigi policy disinda kalan ortam kaynakli sorunlardir.

Ornekler:

- Izin hatasi.
- Dosyanin kilitli olmasi.
- Disk veya IO hatalari.
- Isletim sistemi tarafindan reddedilen dosya islemleri.

Bu hatalar standart Python exception olarak yukari tasinabilir.

Bu adimda bu hatalari ozel error code'a ceviren result layer eklenmedi.

## Hata mesajlarinin kullaniciya ve handover QC'ye tasinmasi

Mevcut dusuk seviyeli helper exception verir.

Gelecekte kullaniciya donuk bir katman eklenirse bu exception'lari okuyabilir ve daha sade mesajlara cevirebilir.

Olasil handover QC gorunurlugu:

- Hangi output path hedeflendi?
- Yazma basarili oldu mu?
- Basarisizsa hata kategorisi nedir?
- Mevcut dosya uzerine yazma engellendi mi?
- Hedef allowed root disinda mi kaldi?
- Parent directory eksik mi?

Bu gorunurluk manuel inceleme icindir. Devir paketini otomatik bloke etmez, kayit reddetmez ve hard validation baslatmaz.

## Yapilmayacaklar

Bu adimda:

- Result object implementasyonu yapilmadi.
- Mevcut helper return type'i degistirilmedi.
- Mevcut helper exception davranisi degistirilmedi.
- Audit event uretimi eklenmedi.
- Backup / restore baslatilmadi.
- Database / repository / API / GUI / CLI eklenmedi.
- Hard validation eklenmedi.
- `blocked` status uretilmedi.
- Diagnostic veya soft validation sonucu yeniden hesaplanmadi.
- Format helper ile file-writing helper ayrimi bozulmadi.

## Sonuc

Adim 157'nin karari sudur:

Mevcut file-writing helperlar dusuk seviyeli ve Pythonic kalir; basarida `Path` dondurur, hatada standart Python exception verir.

Gelecekte daha zengin kullaniciya donuk sonuc gerekiyorsa, result dict sozlesmesi ayri bir wrapper veya helper olarak planlanabilir.

Bu ayrim helperlari kucuk tutar, sessiz basarisizligi engeller ve handover QC gorunurlugunu ileride kontrollu sekilde genisletmeye imkan verir.
