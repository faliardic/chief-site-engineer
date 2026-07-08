# Adim 122 - Audit Event Target Record ID Validation Tasarimi

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord.target_record_id` icin validation tasarimini dokumante ettik.

Kod yazmadik. Test eklemedik. Regex veya prefix validation eklemedik.

Yaptigimiz is, Adim 121'deki format onerisini ileride nasil kontrol edebilecegimizi tasarlamaktir.

## Neden yaptik?

Bir id formati onermek ile o formati runtime validation olarak zorlamak ayni sey degildir.

Format onerisi dokumantasyon seviyesinde guvenlidir. Ancak validation eklendiginde mevcut veriler veya mevcut model id alanlari etkilenebilir.

Bu nedenle once validation tasarimi yapildi.

## Dokunulan dosyalar

```text
docs/122_audit_event_target_record_id_validation_tasarimi.md
learning/122_audit_event_target_record_id_validation_tasarimi.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
docs/121_audit_event_target_record_id_format_tasarimi.md
learning/GLOSSARY.md
```

Bu adimda uygulama kodu veya test dosyasi degistirilmedi.

## Target record id validation nedir?

Target record id validation, `target_record_id` degerinin anlamli ve beklenen kimlik biciminde olup olmadigini kontrol etme davranisidir.

Ornek hedef bicim:

```text
REC-2026-0007
```

Bu deger:

- `REC` prefix'ini tasir.
- `2026` yil bilgisini tasir.
- `0007` sira numarasini tasir.

## Neden hemen kodlamadik?

Sistemde tum kayit tipleri icin nihai id generator yoktur.

Mevcut model id alanlari onerilen formatla birebir uyumlu olmayabilir.

Bu nedenle regex veya prefix validation hemen kodlanirsa eski veya mevcut kayitlarla uyumsuzluk riski dogabilir.

Sunu soyle yaptik ki:
Validation davranisi aceleyle mevcut veri sozlesmelerini kiracak hale gelmesin.

Boyle yaptik:
Bu adimi documentation-only tuttuk.

Cunku:
Once gercek model id alanlari ve ornek kayitlar incelenmelidir.

Boylece:
Kodlama adimi daha bilincli ve geri alinabilir olur.

## Genel regex yaklasimi

Ilk asamada genel bicim kontrolu dusunulebilir.

Onerilen regex:

```regex
^[A-Z]{3}-[0-9]{4}-[0-9]{4}$
```

Bu regex sunu anlatir:

- `^[A-Z]{3}`: Metin uc buyuk harfle baslar.
- `-`: Ardindan tire gelir.
- `[0-9]{4}`: Dort haneli yil bilgisi gelir.
- `-`: Ardindan tekrar tire gelir.
- `[0-9]{4}$`: Dort haneli sira numarasi ile biter.

## Prefix / target type uyumu

Genel format dogru olsa bile prefix, target type ile uyumsuz olabilir.

Dogru olabilecek ornek:

```text
target_record_type = attachment
target_record_id = ATT-2026-0001
```

Yanlis olabilecek ornek:

```text
target_record_type = attachment
target_record_id = REC-2026-0001
```

Ikinci ornekte id genel formata uyar, ama `REC` prefix'i attachment icin beklenen `ATT` prefix'iyle uyumlu degildir.

## Target type / prefix esleme tablosu

| target_record_type | Onerilen prefix |
| --- | --- |
| `project` | `PRJ` |
| `project_record` | `REC` |
| `attachment` | `ATT` |
| `attachment_metadata` | `AMD` |
| `attachment_integrity_report` | `AIR` |
| `json_export` | `JEX` |
| `backup_package` | `BCK` |
| `restore_operation` | `RST` |
| `handover_package` | `HND` |
| `audit_event` | `AUD` |

Bu tablo ileride validation map olarak dusunulebilir, ama bu adimda koda eklenmedi.

## Kabul / red ornekleri

Kabul edilebilir degerler:

```text
PRJ-2026-0001
REC-2026-0007
ATT-2026-0001
AIR-2026-0001
BCK-2026-0001
```

Reddedilebilecek degerler:

```text
record-2026-0001
REC-26-001
REC-2026-1
REC_2026_0001
Kalip kontrol notu guncellendi
```

## Hata mesaji tasarimi

Onerilen gelecek hata mesajlari:

```text
target_record_id is required
target_record_id format is not supported
target_record_id prefix does not match target_record_type
```

Bu mesajlar farkli hata turlerini ayirir:

- Bos deger.
- Genel format hatasi.
- Prefix/type uyum hatasi.

## Validation sirasi

Onerilen gelecek validation sirasi:

```text
1. Required field validation
2. Event type allowed-list validation
3. Target record pair validation
4. Target record type allowed-list validation
5. target_record_type bos/whitespace kontrolu
6. target_record_id bos/whitespace kontrolu
7. target_record_id genel format kontrolu
8. Prefix / target type uyumu kontrolu
```

Bu sira once temel eksiklikleri, sonra format problemlerini, en son da prefix/type uyumunu kontrol eder.

## Geriye donuk uyumluluk riski

Geriye donuk uyumluluk, yeni kurallar eklenirken eski veri veya eski kullanimlarin bozulmamasidir.

Bu projede risk sudur:

- Eski veya mevcut model id degerleri onerilen formata uymayabilir.
- Tum kayit tipleri icin merkezi id generator henuz yoktur.
- Prefix validation, gercek model id kararlarindan once eklenirse yanlis redlere neden olabilir.

Bu nedenle bu adim yalnizca tasarimdir.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Validation'i iki asamali tasarladik | Genel format ve prefix/type uyumunu ayirdik | Her hata turu ayni problem degil | Kodlama sirasi daha net olur |
| Regex onerisi yazdik | `^[A-Z]{3}-[0-9]{4}-[0-9]{4}$` pattern'ini dokumante ettik | Ilk format kontrolu sade olmali | Gelecek testler daha net tasarlanabilir |
| Prefix eslemesini belgeledik | Target type / prefix tablosu ekledik | Prefix validation icin harita gerekir | Uyum kontrolu ileride guvenli ele alinabilir |
| Kodlamayi erteledik | Documentation-only kaldik | Geriye uyumluluk riski var | Mevcut davranislar bozulmadi |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`target_record_id` validation'i iki asamali dusunduk.

Boyle yaptik:
Once genel regex formatini, sonra prefix/type uyumunu ayri karar olarak yazdik.

Cunku:
Genel bicim hatasi ile yanlis prefix hatasi farkli problemlerdir.

Boylece:
Ileride hata mesajlari ve testler daha anlasilir olur.

Sunu yaptik:
Prefix validation'i hemen kodlamadik.

Boyle yaptik:
Geriye donuk uyumluluk riskini ayrica belgeledik.

Cunku:
Mevcut model id alanlari henuz bu formata gore standartlasmadi.

Boylece:
Sistem erken ve sert bir validation karariyla kirilmadi.

## Bilincli olarak yapilmayanlar

Bu adimda uygulama kodu degistirilmedi.

Bu adimda test dosyasi degistirilmedi.

Bu adimda regex validation, prefix validation, ID generator, ID normalizer veya existing id migration eklenmedi.

Bu adimda target type constants, event type constants, database, repository, migration, JSON export/import, audit event persistence, otomatik audit event uretimi, API, GUI veya CLI davranisi degistirilmedi.

## Mini sozluk

`Regex Validation`: Bir metnin belirli bir regex pattern'ine uyup uymadigini kontrol etme davranisi.

`Format Validation`: Bir degerin beklenen genel bicime uyup uymadigini kontrol etme davranisi.

`Prefix Match`: ID prefix'i ile target record type icin beklenen prefix'in uyumlu olmasi.

`Backward Compatibility`: Yeni kurallar eklendiginde eski verinin bozulmadan calismaya devam etmesi.

`ID Normalizer`: Farkli yazilmis id degerlerini tek standart bicime donusturen mekanizma.

## Adim 123'e baglanti

Onerilen sonraki adim:

```text
Adim 123 - Audit event serialization tasarimi veya target record id format validation
```

Adim 123'te audit event serialization tasarimi yapilabilir veya bu validation tasariminin ilk kod adimi olan genel format validation ele alinabilir.
