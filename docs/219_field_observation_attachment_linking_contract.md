# Adim 219 - Field Observation Attachment Linking Contract

Bu adim, `FieldObservationRecord` ile mevcut `FileAttachmentRecord` metadata
nesneleri arasindaki dar iliski sozlesmesini tanimlar.

Bu bir implementasyon adimi degildir. Production code, executable test,
repository davranisi, model validation, fiziksel dosya islemi veya persistence
eklenmedi.

## Amac

Field MVP icinde bir saha gozlemi, ileride fotograf, video, PDF veya belge gibi
dosya eki metadata kayitlariyla iliskilendirilebilir. Bu iliskiyi kodla
uygulamadan once, hangi metadata alanlarinin birlikte okunacagini ve hangi
durumlarin link sayilacagini netlestirmek gerekir.

Bu contract, ileride eklenecek combined repository filtresi veya
Field Observation convenience lookup icin sinir cizer.

## Relationship Identity

Bir `FileAttachmentRecord`, yalniz su iki kosul ayni record uzerinde birlikte
dogruysa bir `FieldObservationRecord` ile iliskili attachment metadata sayilir:

```text
related_record_type == "field_observation"
related_record_id == FieldObservationRecord.observation_id
```

Bu iki kosuldan sadece biri dogruysa, field observation attachment link'i
kurulmus sayilmaz.

## Exact Matching Semantics

- Iki karsilastirma da exact string equality ile yapilir.
- Karsilastirmalar case-sensitive davranir.
- Trim yapilmaz.
- Normalization yapilmaz.
- Parsing yapilmaz.
- Mapping veya aliasing yapilmaz.
- Prefix inference yapilmaz.
- `"field_observation"` literal degeri, bu contract icin Field MVP attachment
  relationship type degeridir.
- Bu adim global enum, constant set, model validation veya migration eklemez.

Ornek:

```text
related_record_type = "field_observation"
related_record_id = "obs-001"
```

Bu metadata kaydi, `FieldObservationRecord.observation_id == "obs-001"` olan
gozlemle iliskili sayilabilir.

Su ornekler exact match degildir:

```text
related_record_type = "Field_Observation"
related_record_id = "obs-001"
```

```text
related_record_type = " field_observation "
related_record_id = "obs-001"
```

```text
related_record_type = "field_observation"
related_record_id = "OBS-001"
```

## Cardinality And Ownership

- Bir field observation sifir attachment metadata kaydina sahip olabilir.
- Bir field observation bir attachment metadata kaydina sahip olabilir.
- Bir field observation birden cok attachment metadata kaydina sahip olabilir.
- Her `FileAttachmentRecord`, tek bir `related_record_type` /
  `related_record_id` ciftini tasir.
- Farkli attachment kayitlari ayni `FieldObservationRecord.observation_id`
  degerini isaret edebilir.
- `attachment_id`, attachment repository icindeki identity alanidir ve mevcut
  duplicate rejection kurallariyla unique kalir.
- Link kurmak `FieldObservationRecord` nesnesini mutate etmez.
- `FieldObservationRecord` icine attachment id listesi eklenmez.
- Iliski alanlarinin sahibi `FileAttachmentRecord` metadata kaydidir.

Bu karar, field observation kaydini hizli ve sade tutar. Attachment bilgisi
observation kaydina gomulmez; attachment metadata kayitlari kendi alanlariyla
baglanti bilgisini tasir.

## Existence And Orphan Behavior

Model ve repository katmani, `related_record_id` ile isaret edilen observation
kaydinin su anda var olup olmadigini dogrulamaz.

Bu nedenle bir `FileAttachmentRecord`, gecici olarak eksik veya henuz yuklenmemis
bir observation id'sini isaret edebilir. Bu otomatik hata veya otomatik red
degildir; gorunur metadata durumudur.

Bu adimda su davranislar uretilmez:

- automatic deletion;
- automatic repair;
- automatic relinking;
- automatic blocking;
- NCR generation;
- task generation;
- audit event generation;
- warning object generation.

Gelecekte service, integrity scanner veya quality-control katmani relationship
existence kontrolu yapabilir. Bu davranis Step 219 kapsaminda uygulanmaz.

## Read Boundary

Step 218 ile gelen mevcut filtreler bagimsizdir:

```python
list_by_related_record_type("field_observation")
list_by_related_record_id("obs-001")
```

Bu iki filtre bir caller tarafindan ard arda kullanilabilir. Ancak bu davranis
repository seviyesinde guvenli combined relationship query olarak sunulmaz.

Neden: Ayni id farkli record type altinda kullanilabilir.

Ornek:

```text
FileAttachmentRecord A:
  related_record_type = "field_observation"
  related_record_id = "shared-001"

FileAttachmentRecord B:
  related_record_type = "nonconformity"
  related_record_id = "shared-001"
```

Sadece id filtresi `shared-001` icin iki kaydi da dondurebilir. Field observation
attachment link'i icin type ve id ayni metadata kaydinda birlikte
eslesmelidir.

## Future Repository Boundary

Ileride ayri bir implementasyon adimi gelirse, repository icinde su combined
filter boundary dusunulebilir:

```python
def list_by_related_record(
    self,
    related_record_type: str,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Bu future helper, ayni `FileAttachmentRecord` nesnesinde iki kosulu birlikte
aramalidir:

```text
record.related_record_type == related_record_type
record.related_record_id == related_record_id
```

Step 219 bu methodu implement etmez.

## Future Field Observation Convenience Boundary

Daha sonra Field Observation'a ozel convenience helper gerekirse, su sinir
dokumante edilir:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Bu future helper, concept olarak su exact pair'e denk olmalidir:

```python
list_by_related_record("field_observation", observation_id)
```

Step 219 bu methodu implement etmez.

## Future Test Matrix

Ileride combined repository helper veya Field Observation convenience helper
uygulanirsa, en az su testler yazilmalidir:

1. Exact type+ID pair eslesen attachment metadata kayitlari insertion order ile
   doner.
2. Ayni id, farkli type altinda ise field observation sonucu disinda kalir.
3. Ayni type, farkli id altinda ise sonuc disinda kalir.
4. Case variant degerler eslesmez.
5. Whitespace variant degerler eslesmez.
6. Bos repository icin `[]` doner.
7. Unknown type/id query icin `[]` doner.
8. Her cagri yeni liste dondurur.
9. Donen elemanlar ayni stored `FileAttachmentRecord` nesneleridir.
10. Metadata alanlari mutate edilmez.
11. Repository count ve insertion order filtreleme nedeniyle degismez.
12. Missing observation existence repository tarafindan validate edilmez.
13. `list_for_field_observation(observation_id)` eklenirse,
    `("field_observation", observation_id)` exact pair davranisina denk olur.

## Explicit Non-Scope

Bu adimda sunlar eklenmedi:

- production code;
- executable tests;
- `list_by_related_record(...)` implementation;
- `list_for_field_observation(...)` implementation;
- model fields;
- constructor degisikligi;
- `__post_init__` degisikligi;
- enum, constant set veya hard validation;
- automatic relationship existence check;
- `FieldObservationRecord` icinde reverse attachment collection;
- physical file upload/download/copy/move/rename/delete/preview/thumbnail/ZIP;
- filesystem existence/readability/integrity check;
- path generation, normalization, allowed-root enforcement veya file writing;
- persistence/database/JSON/SQLite;
- status/archive/lifecycle behavior;
- API/GUI/CLI;
- audit/history/task/NCR/notification/decision generation;
- generated `blocked`;
- Step 220;
- Podcast 034.

## Saha Acisindan Anlam

Santiye sefi acisindan bu contract sunu soyler: Bir saha gozlemine bagli
fotograflar veya belgeler, observation kaydinin icine gomulu bir liste olarak
degil, ayri attachment metadata kayitlari olarak dusunulur.

Bu yaklasim ileride:

- observation kaydini hizli ve sade tutar;
- attachment metadata'yi dosya kaniti baglamiyla birlikte saklar;
- ayni observation'a birden cok dosya eklenmesine izin verir;
- fiziksel dosya ve persistence davranislarini daha sonra ayri ve kontrollu
  adimlarda tasarlamayi mumkun kilar.

Bu adim yalniz sozlesmeyi netlestirir; sistemi henuz otomatik attachment
linking yapan field-ready bir uygulamaya donusturmez.
