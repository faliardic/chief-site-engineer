# Adim 156 - Export Helper Usage Documentation

Bu adimda Adim 155'te eklenen read-only file writing helper fonksiyonlarinin kullanim siniri belgelendi.

Bu adim documentation-only adimidir.

Yeni kod yazilmadi.

Yeni test yazilmadi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 026 bu adimda olusturulmadi.

## Export helperlarin amaci

Export helperlarin amaci, onceden hazirlanmis JSON-ready dict veya Markdown string ciktisini explicit output path'e guvenli sekilde yazmaktir.

Bu helperlar:

- Diagnostic report hesaplamaz.
- Soft validation report hesaplamaz.
- Formatter ciktilarini yeniden uretmez.
- Kayit degistirmez.
- Database veya repository yazmaz.
- Backup / restore baslatmaz.
- API / GUI / CLI entegrasyonu eklemez.
- Audit event uretmez.

Bu sinir, formatlama ile kalici dosya yazimini birbirinden ayri tutar.

## `write_json_ready_dict_to_file(...)` kullanim siniri

`write_json_ready_dict_to_file(...)` yalniz JSON-ready dict input icindir.

Kullanim sinirlari:

- Input dict olmalidir.
- Output path explicit verilmelidir.
- Hedef dosya `.json` uzantili olmalidir.
- UTF-8 ile yazar.
- Deterministic JSON format kullanir.
- Input dict'i mutate etmez.
- JSON serialize edilemeyen object'i kabul etmez.
- Varsayilan `overwrite=False` davranisini korur.
- `allowed_root` verilirse hedef dosya bu root icinde kalmalidir.

Bu helper, diagnostic veya soft validation sonucunu yeniden hesaplamaz.

## `write_markdown_text_to_file(...)` kullanim siniri

`write_markdown_text_to_file(...)` yalniz Markdown string input icindir.

Kullanim sinirlari:

- Input string olmalidir.
- Output path explicit verilmelidir.
- Hedef dosya `.md` uzantili olmalidir.
- UTF-8 ile yazar.
- Markdown icerigini yeniden formatlamaz.
- Input string'i degistirmez.
- Varsayilan `overwrite=False` davranisini korur.
- `allowed_root` verilirse hedef dosya bu root icinde kalmalidir.

Bu helper, formatter ciktisini oldugu gibi dosyaya tasir.

## Format helper ile file-writing helper ayrimi

Format helper:

- Report dict alir.
- JSON-ready dict veya Markdown string dondurur.
- Dosya yazmaz.
- Output path bilmez.
- Overwrite karari vermez.

File-writing helper:

- Hazir JSON-ready dict veya Markdown string alir.
- Explicit output path ister.
- Path safety ve overwrite policy uygular.
- Dosya yazar.
- Report veya status yeniden hesaplamaz.

Bu ayrim korunmalidir. Aksi halde bir helper hem rapor hesaplayan hem formatlayan hem dosya yazan hem de karar veren karmasik bir katmana donusebilir.

## JSON-ready dict akisi

Guvenli JSON export akisi su sekildedir:

1. Diagnostic veya soft validation report uretilir.
2. Format helper JSON-ready dict uretir.
3. File writing helper bu hazir dict'i `.json` dosyasina yazar.

Ornek akisi gosteren kod:

```python
diagnostic_report = build_record_id_diagnostic_report(records)
soft_report = build_record_id_soft_validation_report(diagnostic_report)
json_ready = format_record_id_soft_validation_report_as_json_ready_dict(soft_report)
write_json_ready_dict_to_file(
    json_ready,
    output_path,
    allowed_root=exports_root,
)
```

Bu ornek bir akisi anlatir. Bu adimda repo icinde gercek export dosyasi uretilmedi.

## Markdown akisi

Guvenli Markdown export akisi su sekildedir:

1. Diagnostic veya soft validation report uretilir.
2. Markdown formatter string uretir.
3. File writing helper bu hazir string'i `.md` dosyasina yazar.

Ornek akisi gosteren kod:

```python
diagnostic_report = build_record_id_diagnostic_report(records)
soft_report = build_record_id_soft_validation_report(diagnostic_report)
markdown = format_record_id_soft_validation_report_as_markdown(soft_report)
write_markdown_text_to_file(
    markdown,
    output_path,
    allowed_root=exports_root,
)
```

Bu ornek bir akisi anlatir. Bu adimda `exports/` icine `.md` dosyasi yazilmadi.

## Yeniden hesaplama yok

File-writing helperlar:

- Diagnostic report'u yeniden hesaplamaz.
- Soft validation report'u yeniden hesaplamaz.
- Formatter helper'lari cagirmak zorunda degildir.
- Verilen hazir ciktinin anlamini degistirmez.

Bu nedenle yazilan dosyanin iceriginden cagirici sorumludur. File-writing helper yalniz guvenli yazma sinirini uygular.

## Input mutate edilmez

JSON helper input dict'i mutate etmez.

Markdown helper input string'i degistirmez.

Bu davranis, format helper ciktisinin aynen korunmasi icin onemlidir.

## `allowed_root` kullanimi

`allowed_root`, export yazim hedefinin izinli kok klasor icinde kalmasini saglayan guvenlik bariyeridir.

Onerilen kullanim:

```python
exports_root = Path("exports")
output_path = exports_root / "handover_qc_summary.json"
write_json_ready_dict_to_file(
    json_ready,
    output_path,
    allowed_root=exports_root,
)
```

`allowed_root` verilirse hedef dosya resolved olarak bu root icinde kalmalidir.

Allowed root disina yazma reddedilir.

## Explicit output path zorunlulugu

Helperlar implicit dosya adi secmez.

Cagirici `output_path` vermelidir.

Bu karar:

- Yazma hedefini gorunur yapar.
- Test etmeyi kolaylastirir.
- Yanlis klasore dosya yazma riskini azaltir.
- Handover ve audit ciktilarinda izlenebilirlik saglar.

## Overwrite davranisi

Guvenli varsayilan:

```text
overwrite=False
```

Bu durumda hedef dosya zaten varsa helper yazmaz ve hata verir.

Uzerine yazma gerekiyorsa cagirici explicit `overwrite=True` vermelidir.

Bu davranis:

- Eski handover raporunun sessizce ezilmesini engeller.
- Audit QC ciktilarinin korunmasina yardim eder.
- Yanlislikla saha hafizasini kaybetme riskini azaltir.

## Parent directory otomatik olusturulmaz

Bu helperlar parent directory olusturmaz.

Parent directory yoksa hata verir.

Bu karar, klasor olusturma davranisinin file-writing sinirini genisletmesini engeller. Gelecekte otomatik parent olusturma istenirse explicit parametre ve ayri testlerle ele alinmalidir.

## Yanlis uzantilar reddedilir

Uzanti siniri:

- JSON helper yalniz `.json` yazar.
- Markdown helper yalniz `.md` yazar.

Bu sinir helper'in script, config, database veya baska riskli dosya tiplerine yazma ihtimalini azaltir.

## Path traversal reddi

`..` path part olarak reddedilir.

Bu, allowed export kokunden cikmaya calisan path'leri engeller.

Ornek risk:

```text
exports/../../.env
```

Bu tur path'ler file-writing helper icin uygun hedef degildir.

## Non-export alanlara yazmama prensibi

Helperlar su alanlara yazmamalidir:

- `.git`
- `.env`
- `.pytest_cache`
- `__pycache__`
- Cache klasorleri
- Database alanlari
- Backup / restore alanlari
- ZIP / yedek alanlari

Bu alanlar export hedefi degildir.

## `exports/` klasorunun guvenli kullanimi

Proje icindeki `exports/` klasoru, ileride export ciktilari icin dogal aday klasordur.

Guvenli kullanim:

- `allowed_root=Path("exports")` ile kullanilir.
- Output path explicit verilir.
- Parent directory onceden hazir olmalidir.
- `overwrite=False` varsayilan olarak korunur.
- Repo icine gereksiz ornek export dosyalari eklenmez.

Bu adimda `exports/` icinde yalniz `.gitkeep` kalmistir.

## Handover QC export senaryosu

Handover QC akisi su amacla kullanilabilir:

- Yeni santiye sefine veri sagligi gorunurlugu vermek.
- Review/attention gerektiren kayitlari gostermek.
- Warning/error sinyallerini manuel inceleme icin gorunur yapmak.

Guvenli handover QC export akisi:

1. Diagnostic report uretilir.
2. Soft validation report uretilir.
3. JSON-ready dict veya Markdown string formatlanir.
4. File-writing helper explicit path'e yazar.
5. Cikti insan tarafindan incelenir.

Bu akista helper:

- Devir paketini otomatik bloke etmez.
- Kayit reddetmez.
- Eski santiye sefinin ozel alanini devretmez.
- Audit event olusturmaz.
- Backup / restore motoru gibi davranmaz.

## Hard validation degildir

Export helper usage hard validation degildir.

Path, extension veya overwrite hatasi file-writing hatasidir.

Bu hata:

- Domain kaydini reddetmez.
- `AuditEventRecord.__post_init__` davranisini daraltmaz.
- `FileAttachmentRecord` davranisini degistirmez.
- Legacy kayitlari reddetmez.

## `blocked` status uretilmez

File-writing helperlar `blocked` status uretmez.

Hata durumunda standart Python exception kullanilir.

Soft validation status dili korunur:

- `pass`
- `review`
- `attention`

`blocked` otomatik engelleme anlami dogurabilecegi icin bu hatta uretilmez.

## Kapsam disi davranislar

Bu helperlar sunlari yapmaz:

- Backup / restore.
- API / GUI / CLI entegrasyonu.
- Database / repository yazimi.
- Audit event uretimi.
- Hard validation.
- Otomatik klasor olusturma.
- Otomatik handover bloklama.

## Mutlak kararlar

- Yeni kod yazilmadi.
- Yeni test yazilmadi.
- JSON veya Markdown export cikti dosyasi uretilmedi.
- `app/models.py` degistirilmedi.
- `tests/test_models.py` degistirilmedi.
- Hard validation eklenmedi.
- `blocked` status eklenmedi.
- Backup / restore / API / GUI / CLI eklenmedi.
- Audit event uretimi eklenmedi.
- Podcast 026 olusturulmadi.
- ZIP, yedek veya cache dosyalari stage edilmemelidir.

## Sonuc

Adim 156, Adim 155'te eklenen read-only file writing helperlarin nasil kullanilacagini ve nerede kullanilmayacagini belgelendi.

Bu belge, gelecekte JSON-ready dict veya Markdown string ciktilari dosyaya yazilirken format helper, file writer, path safety, overwrite policy ve handover QC sinirlarinin karismamasini saglar.
