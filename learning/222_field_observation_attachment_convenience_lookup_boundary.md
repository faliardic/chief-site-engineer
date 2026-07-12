# Adim 222 - Field Observation Attachment Convenience Lookup Boundary Ogrenme Notu

Bu adimda yeni production code yazmadik. Bunun yerine gelecekte yazilabilecek
bir helper icin API sinirini ve test matrisini planladik:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Bu helper henuz yoktur. Step 222'nin amaci, ileride bu helper yazilirsa ne
yapmasi ve ne yapmamasi gerektigini onceden netlestirmektir.

## Hangi Dosyada Ne Yaptik?

| Dosya | Ne yapildi? | Neden yapildi? |
| --- | --- | --- |
| `docs/222_field_observation_attachment_convenience_lookup_boundary.md` | Future helper API boundary ve test matrix yazildi. | Helper implement edilmeden once davranis sozlesmesi netlessin diye. |
| `learning/222_field_observation_attachment_convenience_lookup_boundary.md` | Python ogrenimi icin helper, delegation, exact match ve test matrix aciklandi. | Kullanici future kodun neden boyle tasarlanacagini ogrensin diye. |
| `.cse/tasks/222_task.md` | Step 222 is tanimi kaydedildi. | Issue kapsamindaki yerel gorev izi repo icinde dursun diye. |
| `.cse/results/222_result.md` | Step 222 sonuc ve verification alani hazirlandi. | Commit oncesi/sonrasi kanitlar izlenebilir olsun diye. |
| `.cse/state/project_state.json`, `README.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/project_decisions.md`, `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | Repo truth Step 222 aktif calismasina gore guncellendi. | Insan ve makine tarafindan okunan proje hafizasi ayni gercegi soylesin diye. |

## Bu Adimda Kod Eklenmedi

Onemli nokta sudur:

```python
def list_for_field_observation(...):
    ...
```

Bu kod bu adimda `app/records.py` icine eklenmedi.

Step 222 documentation/state/learning-only bir adimdir. Yani bugun davranis
degistirmiyoruz; gelecekteki davranisin sinirini yaziyoruz.

## Future Helper Neyi Temsil Eder?

Step 220'de su generic combined helper zaten var:

```python
repository.list_by_related_record("field_observation", observation_id)
```

Bu cagri, attachment metadata kayitlari icinde su exact pair'i arar:

```text
related_record_type == "field_observation"
related_record_id == observation_id
```

Future convenience helper ayni davranisi daha okunur bir isimle sunabilir:

```python
repository.list_for_field_observation(observation_id)
```

## Future Kod Nasil Gorunmeli?

Tercih edilen future implementation su sekilde olabilir:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    return self.list_by_related_record("field_observation", observation_id)
```

## Satir Satir Aciklama

```python
def list_for_field_observation(
```

Yeni method baslar. Method adi, "Field Observation icin attachment listele"
niyetini anlatir.

```python
    self,
```

`self`, `FileAttachmentRepository` nesnesinin kendisidir. Method repository
icindeki mevcut method'lara erisebilir.

```python
    observation_id: str,
```

Caller bu methoda sadece observation id verir. Ornek:

```python
"obs-001"
```

```python
) -> list[FileAttachmentRecord]:
```

Methodun `FileAttachmentRecord` nesnelerinden olusan bir liste dondurecegini
anlatan type hint'tir.

```python
    return self.list_by_related_record("field_observation", observation_id)
```

Burada method isi kendisi tekrar yazmaz. Var olan combined helper'i cagirir.
Sabit type degeri olarak `"field_observation"` verir, id olarak da
`observation_id` kullanir.

## Delegation Nedir?

Delegation, bir methodun isi kendi icinde tekrar yazmak yerine baska bir methoda
devretmesidir.

Bu ornekte:

```python
list_for_field_observation(...)
```

filtreleme kosullarini kendisi yazmak yerine:

```python
list_by_related_record(...)
```

methoduna devreder.

Bu yaklasim su nedenle iyidir:

- filtering logic tek yerde kalir;
- future bug fix tek yerde yapilir;
- iki methodun davranisi ayrisma riski azalir;
- testlerde semantic equivalence daha kolay dogrulanir.

## Neden Filtering Logic'i Kopyalamiyoruz?

Kopyalanmis future kod su sekilde gorunebilir:

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

Bu kod ilk bakista dogru gibi gorunur. Fakat Step 220'de ayni combined matching
mantigi zaten vardir:

```python
def list_by_related_record(
    self,
    related_record_type: str,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    return [
        record
        for record in self._records
        if record.related_record_type == related_record_type
        and record.related_record_id == related_record_id
    ]
```

Ayni filtreyi iki yerde tutarsak ileride biri degisir, digeri unutulabilir.
Bu yuzden future helper icin delegation daha sade karardir.

## Sunu Soyle Yaptik Ki...

Sunu soyle yaptik ki bugun davranis degismesin:

```text
Step 222 production code eklemez.
```

Yani `app/records.py` dosyasina yeni method yazmadik.

Sunu soyle yaptik ki future helper mevcut combined helper ile ayni kalsin:

```python
list_for_field_observation(observation_id)
```

davranisini su cagrinin karsiligi olarak tanimladik:

```python
list_by_related_record("field_observation", observation_id)
```

Sunu soyle yaptik ki id eslesmesi gizli sekilde degismesin:

```text
exact ve case-sensitive matching
```

Yani `"obs-001"` ile `"OBS-001"` ayni sayilmaz.

Sunu soyle yaptik ki repository sorumlulugu buyumesin:

```text
FieldObservationRepository lookup yok.
Referenced observation existence validation yok.
```

Attachment repository sadece attachment metadata listesini okur. Observation
gercekten var mi sorusu baska bir katmanin future sorumlulugudur.

## Davranis Sozlesmesi

Future helper yazilirsa su kurallara uymali:

| Kural | Anlami |
| --- | --- |
| Semantic equivalence | Sonuc `list_by_related_record("field_observation", observation_id)` ile ayni olmali. |
| Delegation | Tercihen existing combined helper cagrilmali. |
| Exact matching | ID birebir ayni olursa match olur. |
| Case-sensitive | Buyuk/kucuk harf farki korunur. |
| No normalization | Trim, parse, map, alias veya prefix inference yoktur. |
| New list | Her cagri yeni liste dondurur. |
| Same objects | Listedeki record'lar stored `FileAttachmentRecord` nesneleridir. |
| No mutation | Attachment metadata veya FieldObservationRecord degismez. |
| No existence validation | Observation var mi diye kontrol edilmez. |

## Future Testler Neyi Dogrulamali?

Gelecekte helper implement edilirse testler su davranislari kilitlemeli:

| Test | Neyi kanitlar? |
| --- | --- |
| Exact field observation match | Dogru type ve id birlikte eslesirse kayitlar doner. |
| Same ID, different type | Sadece id eslesmesi yeterli degildir. |
| Same type, different ID | Sadece type eslesmesi yeterli degildir. |
| Case-different ID | Buyuk/kucuk harf farki match sayilmaz. |
| Whitespace-different ID | Bosluklu degerler otomatik trim edilmez. |
| Empty repository | Kayit yoksa `[]` doner. |
| Unknown observation ID | Eslesme yoksa `[]` doner. |
| New list | Disaridan liste mutate edilse repository bozulmaz. |
| Same stored objects | Donen elemanlar kopya degil ayni object referanslaridir. |
| Metadata non-mutation | Filtreleme metadata alanlarini degistirmez. |
| Count/order stable | Repository sayisi ve `list_all()` sirasi degismez. |
| Missing existence | Observation var mi diye validate edilmez. |
| Equivalence | Convenience helper sonucu combined helper sonucu ile aynidir. |
| Regression | Independent ve combined filtreler bozulmaz. |

## Ornek Future Test Dusuncesi

Bu test Step 222'de yazilmadi. Ama gelecekte implementasyon geldiginde su
mantik beklenir:

```python
def test_file_attachment_repository_list_for_field_observation_matches_combined_helper() -> None:
    repository = FileAttachmentRepository()
    attachment = _file_attachment(
        attachment_id="att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    repository.add(attachment)

    assert repository.list_for_field_observation("obs-001") == (
        repository.list_by_related_record("field_observation", "obs-001")
    )
```

Bu testin ana fikri sudur:

```text
convenience helper == combined helper with fixed type
```

## Teknik Karar Tablosu

| Karar | Secilen sinir | Neden |
| --- | --- | --- |
| Bu adim tipi | Documentation/state/learning-only | Helper davranisi koddan once netlessin diye. |
| Future helper adi | `list_for_field_observation` | Caller niyetini daha okunur yapar. |
| Semantic source | `list_by_related_record("field_observation", observation_id)` | Existing combined behavior yeniden kullanilir. |
| Type literal | `"field_observation"` | Step 219 contract ile ayni literal korunur. |
| Validation | Yok | Repository metadata read helper olarak kalir. |
| FieldObservationRepository lookup | Yok | Repositoryler erken baglanmasin diye. |
| Physical file behavior | Yok | Upload/path/scanner/persistence ayri katmandir. |
| Tests | Future matrix olarak planlandi | Implementation gelmeden beklenti netlessin diye. |

## Kod Calisma Akisi

Future implementation gelirse beklenen akis:

```text
Caller observation_id verir
-> list_for_field_observation(observation_id) cagrilir
-> method list_by_related_record("field_observation", observation_id) cagrilir
-> combined helper type ve id kosullarini ayni attachment metadata kaydinda arar
-> eslesen FileAttachmentRecord nesneleri yeni listede doner
-> repository count/order/metadata degismez
-> FieldObservationRepository sorgulanmaz
```

## Yeni Terimler

**Convenience helper**: Zaten yapilabilen bir islemi daha okunur ve niyet
belirten bir method adi altinda sunan yardimci method. Bu adimda
`list_for_field_observation(...)` future convenience helper olarak planlandi.

**Delegation**: Bir methodun asil isi kendi icinde tekrar yazmak yerine baska
bir methoda devretmesi. Bu adimda future helper'in `list_by_related_record(...)`
methoduna delegasyon yapmasi tercih edildi.

**Semantic equivalence**: Iki farkli cagri biciminin ayni anlam ve ayni sonucu
vermesi. Burada `list_for_field_observation("obs-001")` ile
`list_by_related_record("field_observation", "obs-001")` ayni sonucu vermelidir.

**API boundary**: Bir methodun hangi girdileri alacagini, ne dondurecegini,
hangi yan etkileri yapmayacagini ve hangi sorumluluklari ustlenmeyecegini
tanımlayan sinir.

**Future test matrix**: Kod henuz yazilmadan once, ileride yazilacak testlerin
hangi davranislari kontrol edecegini gosteren plan.

## Bu Adimdan Sonra Ne Henuz Yok?

- `list_for_field_observation(...)` henuz yok.
- Production code degismedi.
- Executable test eklenmedi.
- `FileAttachmentRepository` method listesi degismedi.
- `FieldObservationRepository` lookup yok.
- Observation existence validation yok.
- Automatic attachment linking yok.
- Physical file operation yok.
- Persistence yok.
- API, GUI, CLI yok.
- Podcast 035 yok.
- Step 223 baslatilmadi.

Bu sinirlar korundugu icin Step 222, future implementation icin net bir harita
olur ama bugunku calisan sistemi degistirmez.
