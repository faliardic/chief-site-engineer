# Adim 155 - Read-only File Writing Helper Implementation

Bu adimda hazir JSON-ready dict ve Markdown string ciktilarini guvenli explicit path'e yazan iki kucuk helper eklendi.

Bu adim implementation adimidir, fakat kapsam read-only file writing ile sinirlidir.

Database / repository yazimi eklenmedi.

Audit event uretimi eklenmedi.

Backup / restore davranisi eklenmedi.

API / GUI / CLI eklenmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 026 bu adimda olusturulmadi.

## Eklenen helper fonksiyonlar

Eklenen helperlar:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu helperlar `app/models.py` icinde, mevcut record ID diagnostic / soft validation formatter hattinin sonrasina eklendi.

Mevcut helperlar tasinmadi, yeniden adlandirilmadi veya davranislari degistirilmedi.

## JSON helper davranisi

`write_json_ready_dict_to_file(...)` davranisi:

- Input olarak JSON-ready dict alir.
- `output_path` zorunludur.
- Sadece `.json` uzantili hedefe yazar.
- UTF-8 encoding kullanir.
- JSON ciktisi deterministic yazilir:
  - `indent=2`
  - `ensure_ascii=False`
  - `sort_keys=True`
- Input dict'i mutate etmez.
- Non-dict input icin `TypeError` verir.
- JSON serialize edilemeyen object icin standart `TypeError` verir.
- Varsayilan `overwrite=False` davranisi vardir.
- Hedef dosya varsa ve `overwrite=False` ise `FileExistsError` verir.
- `overwrite=True` ise yalniz hedef dosyayi gunceller.
- Basarili yazimda `Path` dondurur.

Helper diagnostic report veya soft validation report'u yeniden hesaplamaz.

Helper format helper davranisini degistirmez.

## Markdown helper davranisi

`write_markdown_text_to_file(...)` davranisi:

- Input olarak Markdown string alir.
- `output_path` zorunludur.
- Sadece `.md` uzantili hedefe yazar.
- UTF-8 encoding kullanir.
- Markdown icerigini yeniden formatlamaz.
- Input string'i degistirmez.
- Non-string input icin `TypeError` verir.
- Varsayilan `overwrite=False` davranisi vardir.
- Hedef dosya varsa ve `overwrite=False` ise `FileExistsError` verir.
- `overwrite=True` ise yalniz hedef dosyayi gunceller.
- Basarili yazimda `Path` dondurur.

Helper mevcut formatter ciktilarini oldugu gibi dosyaya tasir.

## Path safety davranisi

Bu adimda minimum guvenli path policy uygulandi.

Uygulanan sinirlar:

- `output_path` bos olamaz.
- `output_path` dosya yolu olmalidir.
- Path traversal reddedilir.
- `..` path part olarak reddedilir.
- Yanlis uzanti reddedilir.
- Parent directory yoksa otomatik olusturulmaz; `FileNotFoundError` verilir.
- Existing directory hedef olarak kullanilamaz.
- Optional `allowed_root` desteklenir.
- `allowed_root` verilirse hedef path resolved olarak allowed root icinde kalmalidir.
- Allowed root disina yazma reddedilir.

Minimum non-export area korumasi:

- `.git`
- `.env`
- `.pytest_cache`
- `__pycache__`
- `cache`
- `database`
- `backup`
- `backups`
- `restore`
- `zip`
- `yedek`

Bu alanlara yazma reddedilir.

## Parent directory karari

Bu adimda parent directory otomatik olusturulmadi.

Gerekce:

- Klasor olusturma file-writing riskini genisletir.
- Allowed root disinda yanlis klasor olusturma riski dogurabilir.
- Adim 155 hedefi kucuk ve testli file-writing helper ile sinirlidir.

Gelecekte parent olusturma eklenecekse explicit parametre ve ayri testlerle ele alinmalidir.

## Overwrite policy

Guvenli varsayilan `overwrite=False` olarak uygulandi.

Bu davranis mevcut dosyayi korur.

Uzerine yazma gerekiyorsa cagirici explicit `overwrite=True` vermelidir.

Testlerde:

- `overwrite=False` iken mevcut icerigin degismedigi kanitlandi.
- `overwrite=True` iken yalniz hedef dosyanin degistigi kanitlandi.

## Test kapsami

`tests/test_models.py` icinde odakli testler eklendi.

Testler su gruplari kapsar:

- JSON-ready dict yazimi.
- JSON dosyasinin tekrar okunup dogrulanmasi.
- UTF-8 karakter korunumu.
- Deterministic JSON format.
- Input dict immutability.
- Wrong extension reddi.
- Non-dict input reddi.
- Unserializable object reddi.
- Existing file + `overwrite=False`.
- Existing file + `overwrite=True`.
- `allowed_root` icinde yazma.
- `allowed_root` disina yazma reddi.
- `..` traversal reddi.
- Missing parent directory reddi.
- Non-export area reddi.
- Markdown string yazimi.
- Markdown iceriginin yeniden formatlanmamasi.
- Non-string input reddi.
- Boundary korumasi: diagnostic / soft validation / formatter helper davranislari yeniden hesaplanmadi.
- `blocked` status uretilmedi.

Test sonucu:

```text
319 passed
```

## Handover QC siniri

Bu helperlar ileride handover QC Markdown veya JSON-ready ciktisini dosyaya yazmak icin kullanilabilir.

Ancak helperlar:

- Handover paketini otomatik bloke etmez.
- Kayit reddetmez.
- Eski santiye sefinin ozel alanini devretmez.
- Backup / restore motoru gibi davranmaz.
- Audit event olusturmaz.

Handover QC export ciktisi yalniz gorunurluk aracidir.

## Hard validation degildir

Bu adim hard validation degildir.

`target_record_id` hard validation eklenmedi.

`AuditEventRecord.__post_init__` davranisi daraltilmadi.

`FileAttachmentRecord` davranisi degistirilmedi.

Path, extension veya overwrite hatasi yalniz file-writing hatasidir; domain kaydi reddi anlami tasimaz.

## `blocked` status siniri

Bu adimda `blocked` status eklenmedi.

File-writing helper basarisiz olursa standart Python exception verir.

Bu durum:

- Soft validation status sozlesmesini degistirmez.
- Handover paketini otomatik bloke etmez.
- Hard validation tetiklemez.

## Mutlak kararlar

- Database / repository yazimi eklenmedi.
- API / GUI / CLI eklenmedi.
- Backup / restore davranisi eklenmedi.
- Audit event uretimi eklenmedi.
- Hard validation eklenmedi.
- `AuditEventRecord.__post_init__` daraltilmadi.
- `FileAttachmentRecord` davranisi degistirilmedi.
- `blocked` status eklenmedi.
- JSON / Markdown ornek export dosyasi repo icinde uretilmedi.
- Podcast 026 olusturulmadi.
- ZIP, yedek veya cache dosyalari stage edilmemelidir.

## Sonuc

Adim 155, mevcut read-only format helper ciktilarindan sonra gelen en kucuk guvenli file-writing katmanini ekledi.

Helperlar yalniz hazir JSON-ready dict ve Markdown string ciktisini explicit path'e yazar; veri hesaplama, kayit reddi, hard validation, backup/restore veya entegrasyon davranisi tasimaz.
