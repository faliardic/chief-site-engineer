# Adim 219 - Field Observation Attachment Linking Contract Ogrenme Notu

Bu adimda kod yazmadik. Bunun yerine `FieldObservationRecord` ile
`FileAttachmentRecord` arasindaki attachment relationship sozlesmesini
dokumante ettik.

Bu tur adimlar yazilimda cok degerlidir. Cunku hangi iki alanin birlikte link
sayilacagini netlestirmeden kod yazarsak, ileride yanlis eslesme, gizli
normalization veya yanlis ownership problemi cikabilir.

## Hangi Dosyada Ne Yaptik?

| Dosya | Ne yapildi? | Neden yapildi? |
| --- | --- | --- |
| `docs/219_field_observation_attachment_linking_contract.md` | Field Observation attachment linking contract yazildi. | Gelecekte combined query veya convenience lookup eklenmeden once relationship semantics net olsun diye. |
| `learning/219_field_observation_attachment_linking_contract.md` | Bu sozlesme Python ve veri modelleme acisindan aciklandi. | Kullanici Python ve repository dusuncesini adim adim ogrensin diye. |
| `.cse/state/project_state.json` | Step 219 active documentation-only state bilgisi eklendi. | Repo truth makine okunabilir kalsin diye. |
| `README.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/project_decisions.md`, `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | Guncel safe point ve active work bilgileri Step 219'a gore guncellendi. | Insan tarafindan okunan proje hafizasi ayni gercegi soylesin diye. |

## Temel Iliski Cumlesi

Bir attachment metadata kaydi, yalniz su iki kosul ayni anda dogruysa bir field
observation'a bagli sayilir:

```text
related_record_type == "field_observation"
related_record_id == FieldObservationRecord.observation_id
```

Bu iki kosuldan sadece biri dogruysa, link tamamlanmis sayilmaz.

## Bunu Python Mantigiyle Dusunelim

Elimizde bir attachment record oldugunu varsayalim:

```python
attachment.related_record_type == "field_observation"
attachment.related_record_id == "obs-001"
```

Elimizde bir observation record olsun:

```python
observation.observation_id == "obs-001"
```

Bu attachment, bu observation ile iliskili sayilabilir. Cunku:

```python
attachment.related_record_type == "field_observation"
```

ve:

```python
attachment.related_record_id == observation.observation_id
```

ikisi de dogrudur.

## Neden Sadece ID Yetmez?

Step 218'de su filtre eklendi:

```python
repository.list_by_related_record_id("shared-001")
```

Bu filtre sadece id alanina bakar. Diyelim ki repository icinde iki attachment
var:

```python
field_attachment = FileAttachmentRecord(
    attachment_id="att-001",
    related_record_type="field_observation",
    related_record_id="shared-001",
    file_name="field-photo.jpg",
    file_path="attachments/PRJ-001/field_observation/shared-001/field-photo.jpg",
    file_type="image",
    mime_type="image/jpeg",
)
```

```python
ncr_attachment = FileAttachmentRecord(
    attachment_id="att-002",
    related_record_type="nonconformity",
    related_record_id="shared-001",
    file_name="ncr-photo.jpg",
    file_path="attachments/PRJ-001/nonconformity/shared-001/ncr-photo.jpg",
    file_type="image",
    mime_type="image/jpeg",
)
```

`list_by_related_record_id("shared-001")` ikisini de dondurebilir. Cunku ikisinin
de id alani aynidir.

Ama field observation attachment link'i icin ikinci kayit yanlistir. Cunku:

```python
ncr_attachment.related_record_type == "field_observation"
```

sonucu `False` olur.

Bu nedenle gelecekte guvenli combined query iki kosulu ayni record uzerinde
birlikte kontrol etmelidir.

## Future Combined Filter Nasil Dusunulmeli?

Step 219 kod yazmaz, ama gelecekteki method sinirini dokumante eder:

```python
def list_by_related_record(
    self,
    related_record_type: str,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Bu method ileride uygulanirsa ic mantigi su fikre dayanmalidir:

```python
return [
    record
    for record in self._records
    if record.related_record_type == related_record_type
    and record.related_record_id == related_record_id
]
```

Satir satir aciklayalim:

```python
return [
```

Yeni bir liste dondurulur. Repository'nin ic listesi dogrudan disari verilmez.

```python
    record
    for record in self._records
```

Repository icindeki her attachment metadata kaydi sirayla gezilir.

```python
    if record.related_record_type == related_record_type
```

Kaydin type alani verilen type ile exact olarak karsilastirilir.

```python
    and record.related_record_id == related_record_id
```

Ayni kaydin id alani verilen id ile exact olarak karsilastirilir.

Buradaki `and` cok onemlidir. `and`, iki kosulun da ayni anda dogru olmasini
ister. Iliski guvenligi buradan gelir.

## Field Observation Convenience Helper Fikri

Gelecekte su kolaylastirici method eklenebilir:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Bu method, kavramsal olarak sunun kisaltmasi olmalidir:

```python
list_by_related_record("field_observation", observation_id)
```

Yani method kendi basina yeni bir iliski kurali icat etmemelidir. Sadece
Field Observation icin sabit type degerini kullanarak combined query'ye
delegation yapmalidir.

## Sunu Soyle Yaptik Ki...

Sunu soyle yaptik ki observation modeli sisip yavaslamasin:

```text
FieldObservationRecord icine attachment_ids listesi eklemedik.
```

Attachment bilgisi, `FileAttachmentRecord` metadata kaydinin kendi
`related_record_type` ve `related_record_id` alanlarinda kalir.

Sunu soyle yaptik ki yanlis kayit tipiyle eslesme olmasin:

```text
related_record_type == "field_observation"
```

Bu kosul olmadan sadece id'ye bakmak, ayni id degerini kullanan baska record
tiplerinin attachment'larini yanlislikla field observation sonucu gibi
gosterebilir.

Sunu soyle yaptik ki veri oldugu gibi gorunsun:

```text
Exact string equality, case-sensitive, no trim.
```

`"field_observation"`, `"Field_Observation"` ve `" field_observation "` farkli
degerlerdir. Sistem bu farklari sessizce duzeltmez.

Sunu soyle yaptik ki bu adim implementation'a donmesin:

```text
Future method signatures documented, but not implemented.
```

Bu sayede once sozlesme review edilebilir. Kod ve test davranisi bir sonraki
ayri issue ile eklenebilir.

## Gelecek Test Matrix'ini Neden Simdiden Yazdik?

Test matrix, gelecekte kod yazacak kisiye "hangi davranislar kilitlenmeli?"
sorusunun cevabini verir.

Ornek future test:

```python
def test_file_attachment_repository_related_record_pair_excludes_same_id_different_type() -> None:
    repository = FileAttachmentRepository()
    field_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="shared-001",
    )
    ncr_attachment = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="shared-001",
    )

    repository.add(field_attachment)
    repository.add(ncr_attachment)

    assert repository.list_by_related_record(
        "field_observation",
        "shared-001",
    ) == [field_attachment]
```

Bu test, same ID / different type riskini yakalar.

## Teknik Karar Tablosu

| Karar | Secilen davranis | Neden |
| --- | --- | --- |
| Iliski sahibi | `FileAttachmentRecord` | Attachment metadata relationship fields zaten bu modelde. |
| Observation modeli | Reverse attachment list yok | Field observation hizli ve sade kalsin. |
| Match kurali | Type + id birlikte | Sadece id farkli record type'larda carpisabilir. |
| String davranisi | Exact, case-sensitive | Step 218 repository sozlesmesiyle uyumlu. |
| Normalization | Yok | Gizli veri degistirme veya alias davranisi eklenmesin. |
| Existence check | Yok | Repository metadata okur; service/integrity layer ayri konu. |
| Combined helper | Future boundary only | Step 219 documentation-only. |
| Field convenience helper | Future boundary only | Once combined query davranisi netlesmeli. |

## Kod Calisma Akisi: Bugun Ve Gelecek

Bugunku durum:

```text
FileAttachmentRepository
-> list_by_related_record_type(...)
-> list_by_related_record_id(...)
```

Bu iki filtre bagimsizdir.

Gelecekte olasi combined durum:

```text
FileAttachmentRepository
-> list_by_related_record("field_observation", "obs-001")
-> ayni kayitta type ve id birlikte eslesir
-> yeni liste dondurulur
-> stored FileAttachmentRecord nesneleri aynen dondurulur
-> repository count/order degismez
```

Gelecekte olasi Field Observation convenience durum:

```text
list_for_field_observation("obs-001")
-> list_by_related_record("field_observation", "obs-001")
-> sonuc field observation attachment metadata listesi olur
```

## Yeni Terimler

**Relationship identity**: Iki kaydin birbirine hangi alanlarla bagli
sayilacagini tanimlayan kimlik kurali.

**Cardinality**: Bir kaydin kac iliskili kayda sahip olabilecegini anlatan
kural. Bu adimda bir observation sifir, bir veya cok attachment metadata
kaydina sahip olabilir.

**Ownership**: Iliski bilgisinin hangi modelde tutuldugunu anlatir. Bu adimda
ownership `FileAttachmentRecord` metadata alanlarindadir.

**Orphan metadata**: Metadata kaydinin isaret ettigi ana kaydin su anda
bulunmamasi durumu. Bu adimda otomatik red veya silme sebebi degildir.

**Combined query**: Birden fazla kosulu ayni sorguda birlikte uygulayan query.
Burada type ve id ayni record uzerinde birlikte kontrol edilmelidir.

**Convenience helper**: Daha genel bir davranisi belirli bir kullanim icin daha
kolay cagirmayi saglayan method. `list_for_field_observation(...)` ileride boyle
bir helper olabilir.

**Delegation**: Bir methodun isi kendisi tekrar yazmak yerine daha genel bir
methoda devretmesi.

## Bu Adimda Neden Test Yazmadik?

Cunku Step 219 production behavior eklemiyor. Test, calisan kod davranisini
dogrulamak icindir. Bu adimda calisan yeni method yok.

Buna ragmen future test matrix yazdik. Boylece ileride implementasyon adimi
gelirse, hangi testlerin yazilacagi simdiden net oldu.

## Bu Adimdan Sonra Ne Henuz Yok?

- `list_by_related_record(...)` yok.
- `list_for_field_observation(...)` yok.
- Observation icinde attachment id listesi yok.
- Related observation var mi kontrolu yok.
- Dosya upload/download yok.
- Dosya sistemi kontrolu yok.
- Persistence yok.
- API, GUI veya CLI yok.
- Audit, task, NCR veya decision generation yok.

Bu sinirlar, CSE'nin kucuk, test edilebilir ve geri alinabilir adimlarla
buyumesini saglar.
