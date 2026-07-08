# Adim 149 - Diagnostic / Soft Validation Format Helper Implementation

Bu adimda diagnostic report ve soft validation report ciktilari icin read-only format helper katmani eklendi.

Bu adim kucuk, test edilebilir ve geri alinabilir implementasyon adimidir.

JSON veya Markdown dosyasi uretilmedi.

Export, backup, restore, database, repository, API, GUI veya CLI davranisi eklenmedi.

## Eklenen helperlar

`app/models.py` icine su helperlar eklendi:

- `format_record_id_diagnostic_report_as_json_ready_dict(report)`
- `format_record_id_soft_validation_report_as_json_ready_dict(report)`
- `format_record_id_diagnostic_report_as_markdown(report)`
- `format_record_id_soft_validation_report_as_markdown(report)`

Bu helperlar mevcut report dict'lerini sunuma hazirlar.

Yeni diagnostic veya soft validation sonucu hesaplamaz.

## JSON-ready dict helper davranisi

JSON-ready helperlar:

- Input report dict alir.
- Python dict dondurur.
- Input'u mutate etmez.
- Mevcut count, status, items, messages ve summary alanlarini sunuma tasir.
- Tuple gibi JSON icin daha az uygun container degerlerini list olarak kopyalar.
- Serialize edilemeyen ozel object eklemez.
- Dosyaya yazmaz.
- Export yapmaz.
- Backup/restore davranisi eklemez.

Unsupported input durumunda exception firlatmak yerine okunur minimal dict dondurur.

Bu durum kayit reddi anlamina gelmez.

## Markdown helper davranisi

Markdown helperlar:

- Input report dict alir.
- Markdown string dondurur.
- Dosyaya yazmaz.
- Baslik, summary ve count/status alanlarini okunabilir hale getirir.
- Warning/error veya review/attention itemlarini gorunur yapar.
- "Bu rapor kayit reddi degildir." notunu icerir.
- "Hard validation degildir." notunu icerir.
- Soft validation Markdown ciktisi "`blocked` status uretilmez." notunu icerir.
- Diagnostic sonucu yeniden hesaplamaz.
- Soft validation status yeniden hesaplamaz.
- Input'u mutate etmez.

Unsupported input durumunda exception firlatmak yerine okunur minimal Markdown string dondurur.

## Diagnostic Markdown minimum icerik

Diagnostic Markdown ciktisi:

- `Record ID Diagnostic Report` basligini icerir.
- `total_count`, `compatible_count`, `warning_count` ve `error_count` alanlarini gosterir.
- Warning/error itemlarini gorunur yapar.
- Kayit reddi olmadigini belirtir.
- Hard validation olmadigini belirtir.

## Soft validation Markdown minimum icerik

Soft validation Markdown ciktisi:

- `Record ID Soft Validation Report` basligini icerir.
- `status` alanini gosterir.
- `total_count`, `warning_count` ve `error_count` alanlarini gosterir.
- `review_required` ve `attention_required` alanlarini gosterir.
- `messages` alanini gosterir.
- Review/attention itemlarini gorunur yapar.
- Kayit reddi olmadigini belirtir.
- Hard validation olmadigini belirtir.
- `blocked` status uretilmedigini belirtir.

## No recomputation karari

Formatterlar diagnostic severity veya soft validation status hesaplamaz.

Input report icindeki count ve status degerleri sunulur.

Bu helperlar `build_record_id_diagnostic_report(...)` veya `build_record_id_soft_validation_report(...)` yerine gecmez.

## No blocked karari

Formatterlar `blocked` status uretmez.

Soft validation Markdown ciktisi `blocked` status uretilmedigini not olarak belirtir.

Eger upstream input desteklenmeyen `blocked` status tasirsa formatter bunu cikti status'u olarak yaymak yerine desteklenmeyen durum olarak sunar.

## Degismeyen davranislar

- `build_record_id_diagnostic_report(...)` davranisi degismedi.
- `build_record_id_soft_validation_report(...)` davranisi degismedi.
- `AuditEventRecord.__post_init__` degismedi.
- `AuditEventRecord` prefix disi `target_record_id` degerlerini kabul etmeye devam eder.
- `FileAttachmentRecord` davranisina dokunulmadi.
- Hard validation eklenmedi.
- Constructor validation eklenmedi.
- Legacy ID reddi eklenmedi.
- Migration veya otomatik duzeltme eklenmedi.
- Podcast 025 bu adimda olusturulmadi.

## Test kapsami

`tests/test_models.py` icine odakli testler eklendi.

Testler sunlari dogrular:

- Diagnostic JSON-ready formatter dict dondurur.
- Diagnostic count ve item icerigi korunur.
- Soft validation JSON-ready formatter status, count, items, messages ve summary alanlarini sunar.
- Formatterlar input'u mutate etmez.
- Diagnostic Markdown baslik, count, warning/error itemlari ve guvenlik notlarini icerir.
- Soft validation Markdown status, review/attention flagleri, messages ve itemlari icerir.
- Unsupported inputlar exception firlatmaz.
- Formatterlar count veya status degerlerini yeniden hesaplamaz.
- `blocked` output status olarak uretilmez.
- Mevcut diagnostic/soft validation helper testleri gecmeye devam eder.
- `AuditEventRecord` constructor davranisi daralmadi.

## Sonuc

Adim 149, CSE record ID diagnostic hattina read-only sunum katmani ekledi.

Bu katman raporlari okunabilir hale getirir; ancak kayit reddetmez, hard validation yapmaz, dosya uretmez ve mevcut diagnostic / soft validation helper davranislarini degistirmez.

