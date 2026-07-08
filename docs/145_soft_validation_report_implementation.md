# Adim 145 - Soft Validation Report Implementation

Bu adimda `build_record_id_soft_validation_report(...)` helper'i read-only soft validation report katmani olarak eklendi.

Helper, `build_record_id_diagnostic_report(records)` ciktisi olan diagnostic report dict'i alir ve kayit reddetmeyen soft validation report dict dondurur.

Bu adim hard validation degildir.

## Helper amaci

`build_record_id_soft_validation_report(...)` diagnostic report sonucunu daha okunur bir kalite kontrol kararina cevirir.

Diagnostic report ham `info`, `warning` ve `error` severity bilgilerini uretir.

Soft validation report ise bu bilgiyi su status degerleriyle yorumlar:

- `pass`
- `review`
- `attention`

`blocked` status'u uretilmez.

## Input sozlesmesi

Helper input olarak diagnostic report dict bekler.

Ilk guvenli input:

```text
build_record_id_diagnostic_report(records)
```

Helper record listesi, repository, database sorgusu, model instance listesi veya dosya sistemi inputu almaz.

Uygunsuz input geldiginde exception firlatmak yerine `attention` status'lu okunur soft validation report dondurur.

## Output sozlesmesi

Helper su alanlari iceren dict dondurur:

- `status`
- `total_count`
- `compatible_count`
- `warning_count`
- `error_count`
- `review_required`
- `attention_required`
- `messages`
- `items`
- `summary`

Count degerleri diagnostic report dict uzerinden okunur.

`items` listesi ve `summary` bilgisi korunur.

Helper input diagnostic report dict'ini mutate etmez.

## Status kurallari

### pass

`pass` su durumda uretilir:

- `warning_count == 0`
- `error_count == 0`

Bu durum kaydin otomatik onaylandigi anlamina gelmez; sadece diagnostic report seviyesinde warning/error gorunmedigini anlatir.

### review

`review` su durumda uretilir:

- `warning_count > 0`
- `error_count == 0`

Bu status gozden gecirme sinyalidir.

Kayit reddi degildir.

### attention

`attention` su durumda uretilir:

- `error_count > 0`

Uygunsuz veya eksik helper inputu da exception yerine `attention` raporu uretir.

Bu status manuel inceleme sinyalidir.

Otomatik silme, otomatik duzeltme veya migration sebebi degildir.

Kayit reddi degildir.

### blocked

`blocked` uretilmez.

Bu seviye hard validation veya engelleme anlami dogurabilecegi icin bu helper'in kapsaminda yoktur.

## Boolean alanlar

`review_required`:

- `review` veya `attention` status'unda `True`
- `pass` status'unda `False`

`attention_required`:

- sadece `attention` status'unda `True`
- diger status degerlerinde `False`

## Unknown severity davranisi

Unknown severity degeri exception sebebi degildir.

Helper bu durumu `messages` alaninda gorunur yapar, fakat kayit reddetmez ve `blocked` uretmez.

## Degismeyen sinirlar

- Kayit reddetme yok.
- Veri degistirme yok.
- `blocked` status yok.
- `AuditEventRecord.__post_init__` icine baglanti yok.
- Constructor validation yok.
- Hard validation yok.
- Legacy ID reddi yok.
- Database/repository/API/GUI/CLI yok.
- Migration veya otomatik duzeltme yok.
- `FileAttachmentRecord` davranisi degismedi.
- `build_record_id_diagnostic_report(...)` davranisi degismedi.
- Podcast 024 bu adimda olusturulmadi.

## Test kapsami

Eklenen testler sunlari dogrular:

- Bos diagnostic report `pass` uretir.
- Sadece `info` itemlari `pass` uretir.
- Warning var ve error yoksa `review` uretir.
- Error varsa `attention` uretir.
- Warning ve error birlikteyse `attention` onceliklidir.
- Count degerleri diagnostic report'tan korunur.
- Items listesi icerik olarak korunur.
- Input diagnostic report mutate edilmez.
- Unknown severity exception firlatmaz.
- Unsupported input exception yerine `attention` raporu uretir.
- Eksik alanlar exception yerine `attention` raporu uretir.
- Hicbir senaryoda `blocked` status'u uretilmez.
- `AuditEventRecord` prefix disi `target_record_id` degerini kabul etmeye devam eder.

## Sonuc

Adim 145, diagnostic report hattina read-only soft validation yorum katmani ekledi.

Bu helper karar kapisi degil, kalite kontrol gorunurlugu saglayan bilgi katmanidir.

