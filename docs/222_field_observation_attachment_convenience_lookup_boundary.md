# Adim 222 - Field Observation Attachment Convenience Lookup Boundary

Bu adimda gelecekte eklenebilecek dar kapsamli bir Field Observation attachment
lookup helper'i icin API siniri ve test matrisi planlandi.

Bu bir implementasyon adimi degildir. Production code, executable test,
repository method'u, model alani, validation, persistence veya dosya islemi
eklenmedi.

## Amac

Step 220 ile `FileAttachmentRepository.list_by_related_record(...)` exact
combined related-record filtresi uygulanmisti.

Field Observation icin daha okunur bir convenience helper ileride dusunulebilir:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Step 222 bu helper'i yazmaz. Yalniz helper'in gelecekte yazilirsa hangi davranis
sozlesmesine uymasi gerektigini belgeler.

## Intended Semantic Equivalence

Gelecekte `list_for_field_observation(observation_id)` eklenirse davranis olarak
su cagrinin dar ve okunur karsiligi olmalidir:

```python
list_by_related_record("field_observation", observation_id)
```

Yani helper yeni bir iliski mantigi icat etmez. Var olan combined helper'in
Field Observation icin sabit `related_record_type` degeriyle kullanilmis hali
olarak dusunulur.

## Tercih Edilen Implementation Boundary

Gelecekte implementation adimi acilirsa tercih edilen yapi sudur:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    return self.list_by_related_record("field_observation", observation_id)
```

Bu, filtering logic'in tek yerde kalmasini saglar.

Tekrarlanmamasi gereken yapi:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    return [
        record
        for record in self._records
        if record.related_record_type == "field_observation"
        and record.related_record_id == observation_id
    ]
```

Bu ikinci ornek davranis olarak benzer gorunse de filtering logic'i kopyalar.
Step 222, future implementation icin delegation yaklasimini daha sade ve bakimi
kolay sinir olarak kaydeder.

## Davranis Sozlesmesi

Future `list_for_field_observation(...)` helper'i:

- yalniz convenience read boundary olmalidir;
- `list_by_related_record("field_observation", observation_id)` davranisina denk
  sonuc dondurmelidir;
- `"field_observation"` literal degerini kullanmalidir;
- `observation_id` icin exact string equality kullanmalidir;
- case-sensitive davranmalidir;
- trim, normalize, parse, map, alias veya prefix inference yapmamalidir;
- validation yapmamalidir;
- insertion order'i korumalidir;
- her cagri yeni liste dondurmelidir;
- liste icinde ayni stored `FileAttachmentRecord` nesnelerini dondurmelidir;
- attachment metadata alanlarini kopyalamamali veya mutate etmemelidir;
- `FieldObservationRecord` nesnesini mutate etmemelidir;
- `FieldObservationRepository` gerektirmemeli veya sorgulamamalidir;
- referenced observation gercekten var mi diye kontrol etmemelidir;
- existing independent `list_by_related_record_type(...)` ve
  `list_by_related_record_id(...)` filtrelerini degistirmemelidir;
- existing combined `list_by_related_record(...)` davranisini degistirmemelidir.

## Neden Bu Helper Sadece Convenience Olmali?

`list_by_related_record("field_observation", observation_id)` zaten exact ve
case-sensitive combined lookup davranisini saglar.

Ancak caller tarafinda su metni tekrar tekrar yazmak gerekebilir:

```python
repository.list_by_related_record("field_observation", observation_id)
```

Future convenience helper bu cagrinin okunabilir kisaltmasi olabilir:

```python
repository.list_for_field_observation(observation_id)
```

Bu helper yeni veri kurali, yeni validation veya yeni repository bagimliligi
eklememelidir. Sadece ayni davranisi daha niyet belirten bir isimle sunmalidir.

## FieldObservationRepository Lookup Neden Yok?

Bu helper attachment metadata repository icinde yasayacak bir read helper olarak
planlanir.

Bu nedenle future implementation:

- `FieldObservationRepository` nesnesi almamalidir;
- observation id gercekten var mi diye arama yapmamalidir;
- missing observation icin hata uretmemelidir;
- orphan metadata kaydini otomatik silmemeli, onarmamali veya bloklamamalidir.

Referenced observation existence kontrolu ileride service, integrity scanner,
quality-control report veya persistence katmaninda ayri olarak tasarlanabilir.
Repository helper'in sorumlulugu sadece metadata listesini okumaktir.

## Exact Matching Ornekleri

Match olan ornek:

```text
related_record_type = "field_observation"
related_record_id = "obs-001"
observation_id = "obs-001"
```

Match olmayan ornekler:

```text
related_record_type = "nonconformity"
related_record_id = "obs-001"
observation_id = "obs-001"
```

```text
related_record_type = "field_observation"
related_record_id = "OBS-001"
observation_id = "obs-001"
```

```text
related_record_type = "field_observation"
related_record_id = " obs-001 "
observation_id = "obs-001"
```

Bu davranis Step 219 ve Step 220'deki exact, case-sensitive ve non-normalizing
kararlarla uyumludur.

## Future Test Matrix

Gelecekte helper implement edilirse en az su testler yazilmalidir:

1. Exact matching Field Observation attachment kayitlari insertion order ile
   doner.
2. Ayni ID baska record type altindaysa sonuc disinda kalir.
3. Ayni record type baska ID ile kayitliysa sonuc disinda kalir.
4. Case-different observation ID degerleri eslesmez.
5. Whitespace-different observation ID degerleri eslesmez.
6. Empty repository `[]` dondurur.
7. Unknown observation ID `[]` dondurur.
8. Her cagri yeni liste dondurur.
9. Donen elemanlar ayni stored `FileAttachmentRecord` nesneleridir.
10. Donen liste disaridan mutate edilirse repository contents bozulmaz.
11. Attachment metadata alanlari mutate edilmez.
12. Repository count ve `list_all()` order davranisi degismez.
13. Missing observation existence repository tarafindan validate edilmez.
14. Convenience helper output'u
    `list_by_related_record("field_observation", observation_id)` sonucu ile
    aynidir.
15. Existing independent ve combined filtreler degismeden kalir.

## Explicit Non-Scope

Bu adimda sunlar eklenmedi:

- production code;
- executable test;
- `list_for_field_observation(...)` implementation;
- `FileAttachmentRepository` method degisikligi;
- `FieldObservationRepository` method degisikligi;
- `FieldObservationRecord` veya `FileAttachmentRecord` alan degisikligi;
- constants, enums, constructor validation, hard validation veya migration;
- automatic attachment creation veya linking;
- observation uzerinde reverse attachment collection;
- relationship existence validation;
- physical file operation;
- filesystem integrity check;
- persistence/database/JSON/SQLite;
- API, GUI, CLI, PWA veya offline sync;
- export/report consumer;
- audit/history/task/NCR/notification/decision generation;
- generated `blocked`;
- workflow veya GitHub Actions degisikligi;
- Podcast 035;
- Step 223 implementation.

## Saha Acisindan Anlam

Santiye sefi ileride bir saha gozlemi detayinda o gozleme bagli fotograf, video,
PDF veya belge metadata kayitlarini gormek isteyebilir.

Bu future helper, teknik olarak su soruyu daha okunur hale getirebilir:

```text
Bu observation_id icin field_observation attachment metadata kayitlari hangileri?
```

Fakat Step 222 bu davranisi uygulamaz. Yalniz ileride uygulanirsa helper'in
mevcut combined filter ile ayni sonucu vermesi gerektigini kaydeder.

Bu karar CSE'nin kucuk, testli ve izlenebilir ilerleme ilkesini korur.
