# Adim 158 - Ogrenme Notu

Bu adimda export helper result contract implementation plan konusu ogrenme notu olarak aciklandi.

Bu adim kod yazmadi.

Yeni test eklemedi.

Mevcut helper davranisini degistirmedi.

Result contract implementasyonu yapmadi.

JSON veya Markdown export dosyasi uretmedi.

Hard validation eklemedi.

`blocked` status eklemedi.

Podcast 027 olusturulmadi.

## Result contract exception'dan neden farklidir?

Exception modelinde hata oldugunda fonksiyon normal sonuc dondurmez.

Bu dusuk seviyeli Python helper icin sade bir modeldir:

```text
Basari -> Path
Hata -> exception
```

Result contract modelinde ise fonksiyon veya wrapper her durumda okunur bir sonuc dondurebilir:

```text
success=True veya success=False
error_code
error_message
output_path
```

Bu model kullaniciya donuk katmanlarda faydalidir.

Fakat dusuk seviyeli helper'in icine dogrudan eklenirse helper'in sorumlulugu buyur.

Bu yuzden Adim 158, result contract'in ileride ayri wrapper/helper olarak planlanmasini daha guvenli gorur.

## Kullaniciya guvenli hata gostermek neden onemlidir?

Dosya yazma hatasi teknik olabilir, fakat etkisi kullaniciyi ilgilendirir.

Kullanici sunlari bilmelidir:

- Dosya yazildi mi?
- Yazilmadiysa neden yazilmadi?
- Path yanlis mi?
- Dosya zaten var mi?
- Allowed root disina mi cikildi?
- JSON input serialize edilemedi mi?

Bu bilgiler gorunur olmazsa kullanici export basarili sanabilir.

Guvenli hata gosterimi, hem gereksiz teknik detaylari azaltir hem de kullaniciya duzeltilebilir neden verir.

## "Dosya yazilmadi ama sistem sessiz kaldi" riski

Saha ve handover export surecinde sessiz basarisizlik ciddi risktir.

Bir handover QC raporu yazilmadiysa ama sistem bunu acikca gostermediyse, yeni santiye sefi eksik bilgiyle hareket edebilir.

Bir JSON export uretilmediyse, daha sonra yapilacak kontrol yanlis veri yokmus gibi gorunebilir.

Bir Markdown raporu mevcut dosya nedeniyle yazilmadiysa, kullanici eski raporu yeni rapor sanabilir.

Bu nedenle result contract'in ana gorevi "yazilmadi" durumunu gorunur kilmaktir.

## `overwrite=False` neden guvenlik freni olarak kalmalidir?

`overwrite=False`, mevcut dosyayi koruyan bilincli bir guvenlik frenidir.

Bu fren sayesinde onceki export ciktilari sessizce ezilmez.

Hedef dosya varsa iki secenek vardir:

- Dusuk seviyeli helper exception verir.
- Future wrapper `success=False` ve `skipped_reason="overwrite_false"` dondurur.

Iki durumda da sonuc gorunurdur.

Kullanici gercekten uzerine yazmak istiyorsa `overwrite=True` kararini explicit vermelidir.

## Plan adimi ile implementation adimi neden ayrilir?

Result contract kucuk bir dict gibi gorunebilir, fakat gercekte API sozlesmesidir.

Alan adlari, hata kodlari, success/skip mantigi, overwrite yorumu ve path gosterimi bir kez kullanilmaya baslayinca geriye uyumluluk konusu olur.

Bu nedenle once plan yapilir:

- Hangi alanlar olacak?
- JSON ve Markdown ortak contract mi kullanacak?
- Hata kodlari nasil adlandirilacak?
- Existing helperlar degisecek mi?
- Handover QC bunu nasil okuyacak?

Implementation daha sonra, test matrix ile birlikte yapilmalidir.

Bu sira hem helper davranisini korur hem de aceleyle yanlis bir sozlesme kilitleme riskini azaltir.

## Wrapper yaklasimi neden temizdir?

Wrapper yaklasiminda iki katman ayrilir.

Dusuk seviyeli helper:

- Dosyayi yazar.
- Basarida `Path` dondurur.
- Hatada exception verir.

Wrapper/result helper:

- Dusuk seviyeli helper'i cagirir.
- Exception'i yakalar.
- Basari veya hata bilgisini result dict'e cevirir.
- Kullaniciya donuk katmana okunur sonuc verir.

Bu ayrim format helper ile file-writing helper ayrimina benzer.

Her katman tek bir isi yapar.

## Hata kodlari neden standart olmalidir?

Standart `error_code` alanlari, handover QC veya ilerideki rapor ekranlarinin hatalari ayni dille gostermesini saglar.

Ornek:

- `file_exists`
- `outside_allowed_root`
- `wrong_extension`
- `missing_parent`
- `invalid_json_input`
- `json_not_serializable`
- `invalid_markdown_input`
- `permission_error`
- `io_error`

Bu kodlar kullanici mesajindan ayridir.

`error_message` insan icindir.

`error_code` sistem ve testler icindir.

## Bu adim ne yapmadi?

Bu adim:

- Kod yazmadi.
- Test yazmadi.
- Yeni helper implementasyonu yapmadi.
- Mevcut helper davranisini degistirmedi.
- Result contract implementasyonu yapmadi.
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

Adim 158'in dersi sudur:

Result contract, kullaniciya guvenli ve standart sonuc gostermek icin yararlidir; fakat mevcut helperlari kirmadan, ayri wrapper/helper katmani olarak planlanmalidir.

Bu sayede dusuk seviyeli helperlar sade kalir, handover QC ileride sessiz basarisizliklari gorunur kilabilir ve `overwrite=False` guvenlik freni korunur.
