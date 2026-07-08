# Adim 131 - Record ID Constants and Mapping Helper Plan

## Bu adimda ne yaptik?

Bu adimda kod yazmadik. Record ID sozlesmesini ileride koda tasirken hangi constants ve helper yapilarinin kullanilabilecegini planladik.

Ama hedefimiz hala ayni: `AuditEventRecord.target_record_id` icin acele hard validation eklememek.

## Constants neden daginik string kullanimini azaltir?

Bir projede ayni metin degeri cok yerde kullaniliyorsa hata riski artar.

Ornek:

```text
project_record
attachment
audit_event
NCR
ATT
PRJ
```

Bu degerler kodun farkli yerlerinde daginik yazilirsa bir yerde `project-record`, baska yerde `project_record` yazilabilir.

Constants bu riski azaltir:

```python
TARGET_RECORD_TYPE_PROJECT_RECORD = "project_record"
ID_FAMILY_NONCONFORMITY = "NONCONFORMITY"
```

Boylece bir deger tek yerde tanimlanir, diger yerler o tanima bakar.

Bu adimda constants yazmadik; sadece hangi constants yapilarina ihtiyac olabilecegini planladik.

## Mapping helper neden dogrudan validation'dan once gelir?

Validation bir degeri kabul eder veya reddeder.

Mapping helper ise once su soruyu cevaplar:

```text
Bu target_record_type hangi ID aileleriyle iliskili olabilir?
```

Ornek:

```text
project_record -> NCR, LOG, NOTE, MAT-DEL, REC
attachment -> ATT, file-att, att
audit_event -> AUD, audit
```

Bu bilgi olmadan validation yazmak tahminle kural koymak olur.

Bu yuzden once mapping helper planlanir. Helper bilgi dondurur. Daha sonra soft validation veya hard validation bu bilgiye dayanabilir.

## Soft validation ile hard validation farki nedir?

Soft validation uyari verir ama sistemi durdurmaz.

Ornek:

```text
target_record_type = project_record
target_record_id = UNKNOWN-001
sonuc = "Bu prefix taninmiyor, ama kaydi simdilik reddetmiyorum."
```

Hard validation ise hata verir ve islemi durdurur.

Ornek:

```text
ValueError: target_record_id prefix is not supported
```

Hard validation gucludur, ama mevcut eski ornekleri kirabilir.

Bu projede once soft validation dusunulur, hard validation en sona birakilir.

## AuditEventRecord icin target_record_type + target_record_id iliskisi nasil guvenli hale getirilir?

Ilk guvenlik zaten vardir:

```python
target_record_type ve target_record_id birlikte dolu veya birlikte bos olmali
```

Sonraki guvenlik katmanlari soyle ilerlemelidir:

1. `target_record_type` desteklenen degerlerden biri mi?
2. Bu `target_record_type` icin hangi ID aileleri beklenir?
3. `target_record_id` bu ailelerden birinin prefixine benziyor mu?
4. Bu sadece uyari mi olacak, yoksa hard hata mi olacak?

Adim 131, ikinci soruya hazirlik yapar: target type ile ID ailesi arasindaki mapping nasil tasarlanacak?

## Neden once plan, sonra helper, sonra test standardizasyonu?

CSE projesinde ID'ler sahadaki kayit hafizasinin temelidir.

Bir anda hard validation eklemek kolaydir, ama erken olursa su riskler dogar:

- Eski test ornekleri kirilir.
- Lower-case ID ornekleri gecersiz olur.
- Explicit ID alani olmayan modellerin audit hedefi belirsiz kalir.
- `project_record` gibi genis target type degerleri gereksiz daralir.

Bu nedenle guvenli sira sudur:

1. Plan: Hangi ID aileleri var?
2. Helper: Hangi target type hangi ID ailelerine bakar?
3. Test standardizasyonu: Yeni ornekler canonical hale gelir.
4. Soft validation: Uyumsuzluklar gorunur olur.
5. Hard validation: Ancak migration sonrasi uygulanir.

## Bu adimda ne yapmadik?

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- Constants veya helper kodu eklenmedi.
- `AuditEventRecord` validation davranisi degistirilmedi.
- `target_record_id` hard validation eklenmedi.
- `FileAttachmentRecord` degistirilmedi.
- Podcast 021 olusturulmadi.
- Commit veya push yapilmadi.

## Sonraki guvenli teknik adim

Bir sonraki guvenli adim, constants ve sadece bilgi donduren mapping helper implementasyonudur.

Ilk helperlar hard validation yapmamalidir.

Ornek hedef:

```text
get_id_families_for_target_record_type("project_record")
```

Bu helper sadece hangi ailelerin ilgili oldugunu soyler. Model davranisini degistirmez.
