# Adim 157 - Ogrenme Notu

Bu adimda export helper error/result contract konusu ogrenme notu olarak aciklandi.

Bu adim kod yazmadi.

Yeni test eklemedi.

Mevcut helper davranisini degistirmedi.

JSON veya Markdown export dosyasi uretmedi.

Hard validation eklemedi.

`blocked` status eklemedi.

Podcast 027 olusturulmadi.

## Hata sozlesmesi neden erken netlesmelidir?

Dosya yazma helper'i kucuk gorunebilir, fakat hata davranisi belirsizse zamanla tehlikeli hale gelir.

Bir helper bazen exception firlatip bazen sessizce `None` dondururse, cagirici gercek sonucu anlayamaz.

Bu nedenle implementasyon buyumeden once su sorular netlesmelidir:

- Basarili yazimda ne dondurulur?
- Basarisiz yazimda exception mi firlatilir?
- Yoksa result dict mi dondurulur?
- Overwrite engellendiyse bu nasil gorunur?
- Path safety hatasi kullaniciya nasil tasinir?

Adim 157 bu sorulari documentation-only olarak netlestirir.

## Exception ile result contract farki

Exception modelinde hata oldugunda fonksiyon normal sonuc dondurmez.

Bu Python helper seviyesinde sade bir davranistir.

Ornek:

```text
Basari -> Path
Hata -> exception
```

Result contract modelinde fonksiyon her durumda bir result dict dondurebilir.

Ornek:

```text
{
  "success": false,
  "output_path": null,
  "error_code": "file_exists",
  "error_message": "Target file already exists.",
  "skipped_reason": "overwrite_false",
  "overwritten": false
}
```

Result dict kullaniciya donuk katmanlarda okunabilirlik saglar.

Fakat dusuk seviyeli helper icin daha fazla karar ve daha fazla test yuku getirir.

Bu nedenle mevcut helperlar exception modelini korur. Result contract gelecekte ayri helper veya wrapper olarak planlanabilir.

## Sessiz basarisizlik neden tehlikelidir?

Saha ve handover export surecinde sessiz basarisizlik ozellikle tehlikelidir.

Bir rapor uretilmedi halde uretilmis gibi kabul edilirse yeni santiye sefi eksik bilgiyle devralabilir.

Bir JSON dosyasi yanlis yere yazilirsa kalite kontrol ciktilari bulunamayabilir.

Bir Markdown raporu mevcut dosyayi sessizce ezdiyse onceki devir hafizasi kaybolabilir.

Bu nedenle hata ya exception ile ya da gelecekte result contract ile gorunur olmalidir.

## Overwrite hatasi neden acik gorunmelidir?

`overwrite=False` guvenli varsayilandir.

Bu varsayilan mevcut dosyanin sessizce ezilmesini engeller.

Hedef dosya zaten varsa ve helper yazmazsa bu durum cagiriciya acikca gorunmelidir.

Aksi halde cagirici yeni raporun yazildigini sanabilir, fakat disk uzerinde eski dosya kalir.

Overwrite hatasi acik gorunurse kullanici bilincli olarak `overwrite=True` kararini verebilir.

## `allowed_root` disina yazma neden kritik bariyerdir?

`allowed_root`, yazma hedefinin izinli kok klasor icinde kalmasini saglar.

Bu bariyer olmadan yanlis path veya traversal denemesi proje disindaki dosyalara yazma riski dogurabilir.

Riskli hedefler:

- `.env`
- `.git`
- cache alanlari
- database dosyalari
- backup / restore alanlari
- ZIP veya yedek dosyalari
- kaynak kod dosyalari

Bu nedenle `allowed_root` disina cikma sadece kullanim hatasi degil, guvenlik bariyerinin calistigi kritik bir sinyaldir.

## Path, input ve filesystem hatalari farkli okunur

Path hatalari, hedefin guvenli veya uygun olmamasidir.

Input hatalari, helper'a verilen icerigin beklenen tip veya serialize edilebilirlikte olmamasidir.

Filesystem hatalari ise izin, kilitli dosya, disk veya isletim sistemi kaynakli sorunlardir.

Bu ayrim ileride result contract tasarlanacaksa `error_code` alanlarina donusebilir.

Bu adimda bu alanlar uygulanmadi; sadece planlandi.

## Bu adim ne yapmadi?

Bu adim:

- Kod yazmadi.
- Test yazmadi.
- Helper return type'ini degistirmedi.
- Exception davranisini degistirmedi.
- Result dict implementasyonu yapmadi.
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

Adim 157'nin dersi sudur:

Dosya yazma helper'i kadar hata sozlesmesi de tasarimin parcasidir.

Basarida `Path`, hatada standart Python exception mevcut asama icin sade ve guvenlidir.

Gelecekte kullaniciya donuk bir result dict gerekiyorsa bu davranis dusuk seviyeli helper'a karistirilmadan ayri bir katmanda planlanmalidir.
