# Adim 156 - Ogrenme Notu

Bu adimda export helper usage documentation hazirlandi.

Bu adim kod yazmadi.

Yeni test eklemedi.

JSON veya Markdown export dosyasi uretmedi.

Hard validation eklemedi.

`blocked` status eklemedi.

Podcast 026 olusturulmadi.

## Usage documentation neden implementasyondan sonra gelir?

Implementasyon once helper'in gercek davranisini belirler.

Usage documentation ise bu davranisin nasil kullanilacagini ve nerelerde kullanilmayacagini aciklar.

Adim 155'te helperlar eklendi:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Adim 156'da bu helperlarin kullanim siniri belgelendi.

Bu sira onemlidir, cunku dokumantasyon artik hayali bir API'yi degil, mevcut helper davranisini anlatir.

## Formatter ile file writer neden ayri kalmalidir?

Formatter'in isi ciktinin seklini hazirlamaktir.

Ornek:

- JSON-ready dict.
- Markdown string.

File writer'in isi bu hazir ciktinin dosyaya yazilmasidir.

Bu iki sorumluluk birlesirse helper fazla guclu hale gelir:

- Rapor hesaplar.
- Formatlar.
- Dosya yazar.
- Belki karar verir.

Bu CSE icin istenmeyen bir karisimdir.

Dogru ayrim:

```text
report helper -> format helper -> file writing helper
```

Bu ayrim hem test etmeyi hem de guvenlik sinirlarini kolaylastirir.

## `allowed_root` neden guvenlik bariyeridir?

`allowed_root`, dosya yaziminin izinli kok klasor icinde kalmasini saglar.

Ornek:

```python
exports_root = Path("exports")
output_path = exports_root / "handover_qc.md"
write_markdown_text_to_file(
    markdown,
    output_path,
    allowed_root=exports_root,
)
```

Bu kullanimda helper hedef path'in `exports/` disina cikmamasini bekler.

Bu, yanlislikla `.env`, `.git` veya baska hassas alanlara yazmayi engellemek icin onemli bir bariyerdir.

## `overwrite=False` neden guvenli varsayilandir?

Saha ve handover arsivinde eski dosyalar onemlidir.

Bir rapor daha once uretilmisse, helper onu sessizce ezmemelidir.

Varsayilan:

```text
overwrite=False
```

Bu sayede:

- Onceki handover raporu korunur.
- Audit QC ciktisi kaybolmaz.
- Hangi dosyanin ne zaman uretildigi daha kolay izlenir.
- Yanlis hedefe yazma riski azalir.

Uzerine yazma gerekiyorsa cagirici bunu explicit `overwrite=True` ile soylemelidir.

## Handover QC ornegi

Handover QC, yeni santiye sefine proje hafizasini devrederken gorunurluk saglar.

Guvenli akisin mantigi:

1. Record ID diagnostic report uretilir.
2. Soft validation report uretilir.
3. Markdown veya JSON-ready cikti uretilir.
4. File writing helper explicit path'e yazar.
5. Yeni santiye sefi ciktida review/attention kayitlarini inceler.

Bu akista export helper:

- Devir paketini otomatik bloke etmez.
- Kayit reddetmez.
- Hard validation yapmaz.
- `blocked` status uretmez.
- Audit event olusturmaz.
- Backup / restore motoru olmaz.

Helper sadece hazir ciktinin guvenli dosyaya yazilmasindan sorumludur.

## Path safety dersi

Dosya yaziminda path guvenligi temel konudur.

Helperlar:

- Explicit output path ister.
- Yanlis uzantiyi reddeder.
- `..` traversal denemesini reddeder.
- Parent directory yoksa otomatik olusturmaz.
- Non-export alanlara yazmayi reddeder.
- `allowed_root` disina cikilmasini engeller.

Bu sinirlar, dosya yazimini kucuk ve tahmin edilebilir tutar.

## Bu adim ne yapmadi?

Bu adim:

- Kod yazmadi.
- Test yazmadi.
- Export dosyasi uretmedi.
- `exports/` icine `.json` veya `.md` dosyasi yazmadi.
- Hard validation eklemedi.
- `AuditEventRecord.__post_init__` degistirmedi.
- `FileAttachmentRecord` davranisini degistirmedi.
- `blocked` status eklemedi.
- Backup / restore davranisi eklemedi.
- Database / repository / API / GUI / CLI eklemedi.
- Audit event uretmedi.
- Podcast 026 olusturmadi.

## Sonuc

Adim 156'nin dersi sudur:

Bir helper implemente edildikten sonra usage documentation, o helper'in guvenli kullanim alanini sabitler.

Bu sayede export helperlar format helperlarla karismaz, handover QC akisi karar motoruna donusmez ve dosya yazimi path safety / overwrite policy sinirlari icinde kalir.
