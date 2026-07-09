# Adim 164 - Ogrenme Notu

Bu adimda export helper result contract wrapper usage documentation konusu ogrenme notu olarak aciklandi.

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test eklenmedi.

Export cikti dosyasi uretilmedi.

Podcast 027 olusturulmadi.

Commit alinmadi.

Push yapilmadi.

## Usage documentation neden implementation'dan sonra gelir?

Implementation adimi wrapper fonksiyonlarini ekler.

Usage documentation adimi ise bu fonksiyonlarin nasil okunacagini ve nerede kullanilacagini netlestirir.

Kod eklendikten sonra kullanici ve gelistirici su sorulara cevap arar:

- Bu wrapper ne zaman kullanilir?
- Dusuk seviye helperdan farki nedir?
- `success=False` ne anlama gelir?
- Handover QC bu sonucu nasil yorumlamalidir?
- Hangi sinirlar hala korunuyor?

Bu nedenle usage documentation, implementation sonrasinda guvenli kullanim dilini sabitler.

## Dusuk seviye exception helper ile result contract wrapper farki

`write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` dusuk seviye helperlardir.

Bu helperlar basarili olursa `Path` dondurur.

Hata olursa exception firlatir.

Bu model Python kodu icin nettir.

`try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` ise wrapper katmanidir.

Bu wrapperlar exception'i kullaniciya firlatmak yerine result dict'e cevirir.

Ornek:

```text
success=False
error_code="file_exists"
skipped_reason="file_exists"
overwritten=False
```

Bu sonuc handover QC veya admin/debug raporu icin daha okunabilirdir.

## `success=False` neden otomatik exception veya blocked degildir?

`success=False`, export yaziminin basarili olmadigini anlatir.

Bu durumun sebepleri farkli olabilir:

- hedef dosya zaten vardir
- `overwrite=False` mevcut dosyayi korumustur
- path allowed-root disindadir
- parent klasor yoktur
- input tipi yanlistir

Bu durumlar devir paketinin otomatik `blocked` olmasi anlamina gelmez.

Bu durumlar kaydin reddedildigi anlamina da gelmez.

Dogru yorum:

```text
Export yazimi incelenmeli.
```

Yanlis yorum:

```text
Handover blocked oldu.
```

CSE cizgisinde wrapper gorunurluk saglar; hard validation veya otomatik blokaj uretmez.

## Handover QC'de okunabilir hata contract'i neden onemlidir?

Handover QC'de dosya yazma sonucu kullaniciya acik olmalidir.

Sadece exception stack trace gormek yeterli degildir.

Okunabilir result contract su faydalari saglar:

- Hangi path denenmis gorulur.
- Hangi allowed-root kullanilmis gorulur.
- Hata tipi standart `error_code` ile okunur.
- Mevcut dosyanin overwrite edilip edilmedigi gorulur.
- Skipped davranisi sessiz kalmaz.

Bu bilgiler insan incelemesini hizlandirir.

Ama bu bilgiler kayit reddi veya database degisikligi baslatmaz.

## `overwrite=False` neden saha/handover arsivinde guvenli varsayilandir?

Saha ve handover arsivlerinde mevcut dosyanin kazara ezilmesi risklidir.

`overwrite=False` bu riski azaltir.

Hedef dosya varsa wrapper bunu basarisiz/skipped olarak raporlar.

Mevcut icerik korunur.

Bu davranis su acikligi saglar:

```text
Dosya zaten vardi, yazim atlandi.
```

`overwrite=True` ise bilincli ve explicit tercih olmalidir.

Basarili overwrite sonucunda `overwritten=True` bilgisi gorunur olur.

## `allowed_root` neden guvenlik bariyeridir?

`allowed_root`, export yaziminin izin verilen kok dizin icinde kalmasini saglar.

Bu bariyer olmadan yanlis path kullanimi repo, cache, ZIP/yedek veya hassas alanlara yazmaya calisabilir.

Wrapper allowed-root kararini yeniden hesaplamaz.

Mevcut file-writing helper bu guvenlik kararini verir.

Wrapper ise sonucu okunabilir hale getirir:

```text
success=False
error_code="outside_allowed_root"
```

Bu ayrim onemlidir.

Guvenlik karari tek yerde kalir.

Raporlama katmani yalniz sonucu yorumlar.

## Bu adimda ne yapilmadi?

Bu adimda su davranislar bilincli olarak eklenmedi:

- `app/models.py` degistirilmedi.
- `tests/test_models.py` degistirilmedi.
- Yeni helper implementasyonu yapilmadi.
- Mevcut helper davranisi degistirilmedi.
- Yeni test eklenmedi.
- JSON veya Markdown export cikti dosyasi uretilmedi.
- `exports/` icine `.json` veya `.md` dosyasi yazilmadi.
- Hard validation eklenmedi.
- `blocked` status eklenmedi.
- Audit event uretilmedi.
- Backup/restore davranisi eklenmedi.
- Database/repository/API/GUI/CLI eklenmedi.
- Podcast 027 olusturulmadi.

Adim 164, yalnizca kullanim sinirini ve result contract yorumunu belgelendirir.
