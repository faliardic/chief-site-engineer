# Adim 139 - Record ID Diagnostic Report API Boundary and Test Matrix Plan

## Amac

Bu adimda Adim 138'de planlanan olasi `build_record_id_diagnostic_report(...)` helper'i icin API boundary, input/output sozlesmesi ve test example matrix plani hazirlandi.

Bu adim documentation-only adimidir. Kod, test, diagnostic report helper implementasyonu, hard validation, runtime davranisi, repository davranisi veya data migration eklenmedi.

## Olası helper adi

Ilerideki helper adi su olabilir:

```python
build_record_id_diagnostic_report(...)
```

Bu adimda bu helper implemente edilmedi. Sadece API boundary, input/output sozlesmesi ve test matrix planlandi.

## API boundary

Helper ileride yalnizca input listesini okuyacak ve diagnostic rapor dondurecek.

Yapmayacaklari:

- Kayit reddetmeyecek.
- Veri degistirmeyecek.
- Database veya repository yazmayacak.
- Audit event olusturmayacak.
- Migration yapmayacak.
- Otomatik duzeltme yapmayacak.
- Dosya sistemi, backup, restore veya export uretmeyecek.
- `AuditEventRecord.__post_init__` icine baglanmayacak.
- Constructor validation olmayacak.
- Hard validation olmayacak.

Bu sinir, helper'in kalite kontrol gorunurlugu araci olarak kalmasini saglar.

## Olası input sozlesmesi

Plan seviyesinde iki basit input bicimi degerlendirilebilir.

### Plain dict input

```python
{"target_record_type": "...", "target_record_id": "..."}
```

Bu bicim okunur ve ileride JSON benzeri raporlama kaynaklariyla uyumlu olabilir.

### Tuple input

```python
("project_record", "PRJ-001")
```

Bu bicim testlerde ve kucuk diagnostic listelerinde sade olabilir.

### Model veya repository bagimliligi

Ileride audit event objesinden `target_record_type` ve `target_record_id` extract edilebilir.

Ancak ilk implementasyonda model, repository veya database bagimliligi artirilmamalidir.

Onerilen guvenli yaklasim:

- Ilk implementasyon saf Python input listesiyle baslamali.
- Model, repository veya database bagimliligi eklenmemeli.
- Input normalization helper gerekiyorsa ayri planlanmali.
- Input nesneleri mutate edilmemeli.

## Olası output sozlesmesi

Rapor dict olarak tasarlanabilir:

- `total_count`
- `compatible_count`
- `warning_count`
- `error_count`
- `items`
- `summary`

Her item su alanlari tasiyabilir:

- `index`
- `target_record_type`
- `target_record_id`
- `expected_family`
- `allowed_prefixes`
- `observed_prefix`
- `is_compatible`
- `severity`
- `message`

Item alanlari tekil `diagnose_record_id_for_target_type(...)` sonucuyla uyumlu kalmalidir.

## Test example matrix plani

Ilerideki implementasyon icin en az su test kategorileri planlanmalidir:

| Kategori | Amac |
| --- | --- |
| Bos input listesi | `total_count` ve summary sayaclarinin sifir davranisini dogrulamak. |
| Tek canonical kayit | `info` item ve compatible count davranisini dogrulamak. |
| Tek legacy kayit | `warning` item uretildigini ve kaydin reddedilmedigini dogrulamak. |
| Tek prefix disi kayit | `warning` + `is_compatible=False` sonucunu dogrulamak. |
| Bilinmeyen target type | Exception yerine `error` diagnostic item uretme yaklasimini dogrulamak. |
| Bos `target_record_id` | Helper seviyesinde `error` item uretildigini dogrulamak. |
| Karisik liste | `info`, `warning` ve `error` itemlarinin ayni raporda korunmasini dogrulamak. |
| Sira/index korunumu | Her item icin input sirasinin `index` ile korunmasini dogrulamak. |
| Summary count dogrulugu | `compatible_count`, `warning_count` ve `error_count` sayaclarini dogrulamak. |
| Input degismezligi | Helper'in input listesini veya itemlarini mutate etmedigini dogrulamak. |
| Exception yerine diagnostic item | Hatali girdilerin toplu raporu kesmedigini dogrulamak. |
| Cok parcali prefixler | Prefix okumanin `NCR-CAND`, `NCR-CA`, `MAT-DEL`, `CHK-RES`, `JSON-EXP` ve `file-att` icin bozulmadigini dogrulamak. |

## Cok parcali prefix ornekleri

Test matrix icinde su prefix ornekleri ayrica korunmalidir:

- `NCR-CAND`
- `NCR-CA`
- `MAT-DEL`
- `CHK-RES`
- `JSON-EXP`
- `file-att`

Bu ornekler ilk tireden yanlis bolunmemelidir.

## Severity aggregation plani

Toplu rapor severity anlamini degistirmemelidir.

Plan:

- Her item kendi severity degerini korur.
- Report level summary count uretir.
- `warning_count` veri reddi anlamina gelmez.
- `error_count` otomatik silme veya duzeltme sebebi degildir.
- Report level en kotu severity degeri ileride istenirse ayrica planlanabilir.

Bu adimda report level en kotu severity zorunlu alan olarak belirlenmedi.

## Gelecek guvenli sira

Record ID diagnostic report hattinda guvenli ilerleme sirasi su sekilde korunmalidir:

1. Adim 139: API boundary ve test matrix plani.
2. Adim 140: Read-only diagnostic report helper implementation.
3. Adim 141: Test example standardization / edge cases.
4. Adim 142: Diagnostic report usage documentation.
5. Adim 143 veya sonrasi: Soft validation report layer plani.
6. En son: Hard validation degerlendirmesi.

Hard validation en sona birakilir.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- Diagnostic report helper ileride bile once read-only kalacak.
- `FileAttachmentRecord` davranisina dokunulmayacak.
- Podcast 023 bu adimda olusturulmayacak.

## Sonuc

Adim 139, olasi diagnostic report helper icin API boundary ve test matrix zeminini hazirladi.

Bu plan, Adim 140'ta olasi read-only implementasyon yapilsa bile helper'in veri reddetmeyen, veri degistirmeyen, repository/database yazmayan ve hard validation'a donusmeyen bir raporlama yardimcisi olarak kalmasini hedefler.
