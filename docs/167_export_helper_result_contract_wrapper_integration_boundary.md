# Adim 167 - Export Helper Result Contract Wrapper Integration Boundary

Bu adimda Adim 166'da test kapsaminda sabitlenen export helper result contract wrapper davranisinin kullanim ve entegrasyon siniri belgelendi.

Odak wrapper fonksiyonlari:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Korunan dusuk seviye helper fonksiyonlari:

- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`

Bu adim documentation-only adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut testler degistirilmedi.

Export helper davranisi degistirilmedi.

JSON veya Markdown export cikti dosyasi repo icine birakilmadi.

Commit alinmadi.

Push yapilmadi.

## Testlerden sonra sabitlenen davranis

Adim 166 ile wrapper result contract davranisi testlerle daha gorunur hale geldi.

Testlerle sabitlenen ana davranislar sunlardir:

- JSON wrapper basarili yazma sonucunda `success=True` result contract dondurur.
- Markdown wrapper basarili yazma sonucunda `success=True` result contract dondurur.
- Basarisiz dosya yazma/path senaryolari wrapper seviyesinde okunabilir failure contract'a cevrilir.
- Wrapper helperlar basarisiz path senaryosunda exception'i ust katmana firlatmaz.
- Input immutability korunur.
- Dusuk seviye `write_*` helperlarin exception tabanli davranisi korunur.

Bu davranislar yeni sema anlamina gelmez.

Mevcut result contract alanlari korunur:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

## Entegrasyon siniri

Wrapper result contract ileride su katmanlarda okunabilir:

- Handover QC gorunumu.
- Admin/debug gorunumu.
- Guvenli export ozeti.
- Kullaniciya gosterilecek kisa sonuc mesajlari.
- Manuel inceleme raporu.

Bu adimda herhangi bir GUI/API/CLI entegrasyonu yapilmaz.

Result contract yorumlama isi ayri katman olarak kalir.

Wrapper helper dogrudan backup/restore sistemi degildir.

Wrapper helper dogrudan audit event sistemi degildir.

Wrapper helper database veya repository yazimi yapmaz.

Wrapper helper karar mekanizmasi degildir.

Wrapper helper yalniz dosya yazma sonucunu okunabilir contract olarak tasir.

## Basarili contract nasil yorumlanir?

Basarili contract export yazma isleminin kontrollu sekilde tamamlandigini belirtir.

Ornek yorum:

```text
success=True
file_type="json"
output_path="<written path>"
error_code=None
```

veya:

```text
success=True
file_type="markdown"
output_path="<written path>"
error_code=None
```

Ust katman bunu kullaniciya su sekilde cevirebilir:

```text
Export dosyasi yazildi.
```

Bu yorum yalniz dosya yazma sonucudur.

Bu yorum record onayi, devir onayi, backup olusumu veya audit event anlamina gelmez.

## Failure/error contract nasil yorumlanir?

Failure contract, ust katmanin kullaniciya veya log/rapor katmanina guvenli aciklama sunabilmesi icin kullanilir.

Ornek yorum:

```text
success=False
error_code="parent_missing"
error_message="<readable message>"
output_path=None
```

Ust katman bunu kullaniciya su sekilde cevirebilir:

```text
Export yazilmadi; hedef klasor hazir degil.
```

`file_exists` icin:

```text
Export yazilmadi; hedef dosya zaten var.
```

`outside_allowed_root` icin:

```text
Export yazilmadi; hedef path izin verilen kok disinda.
```

Failure contract otomatik duzeltme anlamina gelmez.

Failure contract hard validation anlamina gelmez.

Failure contract devir paketini otomatik bloke etmez.

Failure contract `blocked` status uretmez.

## Handover QC yorumu

Handover QC wrapper sonucunu gorunurluk sinyali olarak okuyabilir.

`success=True`:

```text
Export dosyasi hazir.
```

`success=False`:

```text
Export yazimi gozden gecirilmeli.
```

Bu yorum insan incelemesini destekler.

Bu yorum otomatik karar vermez.

Bu yorum database veya repository kaydi degistirmez.

Bu yorum audit event uretmez.

## Admin/debug gorunumu

Admin/debug gorunumu result contract alanlarini teknik ama okunabilir sekilde gosterebilir.

Faydali alanlar:

- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Bu alanlar hatanin nerede ve neden olustugunu gosterir.

Bu alanlar kullaniciya stack trace gostermeden inceleme yapmayi kolaylastirir.

Yine de bu gorunum bu adimda implement edilmez.

Bu adim yalniz entegrasyon sinirini belgeler.

## Korunacak sinirlar

Hard validation eklenmeyecek.

`blocked` status eklenmeyecek.

Backup/restore/API/GUI/CLI eklenmeyecek.

Audit event uretimi eklenmeyecek.

Database/repository davranisi eklenmeyecek.

Export cikti dosyalari repo icine birakilmayacak.

ZIP/cache stage edilmeyecek.

Mevcut dusuk seviye helper davranisi degistirilmeyecek.

`write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` exception tabanli helperlar olarak kalacak.

`try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapper helperlar result contract donduren gorunurluk katmani olarak kalacak.

## Ileri adim onerisi

Sonraki olasi adimlardan biri su olabilir:

```text
Adim 168 - Export helper result contract summary/report layer plan
```

veya:

```text
Adim 168 - Handover QC export result interpretation plan
```

Bu adimda Adim 168 baslatilmaz.

Bu adim yalniz Adim 166 testleri sonrasi kullanim ve entegrasyon sinirini belgeler.
