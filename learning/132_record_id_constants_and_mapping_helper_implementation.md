# Adim 132 - Record ID Constants and Mapping Helper Implementation

## Bu adimda ne yaptik?

Bu adimda Adim 129-131 kararlarina uygun olarak record ID constants ve `target_record_type` -> ID ailesi mapping helper katmaninin ilk dar implementasyonunu ekledik.

Eklenen temel yapi:

- `RECORD_ID_PREFIXES`
- `TARGET_RECORD_TYPE_TO_ID_FAMILY`
- `TARGET_RECORD_TYPE_TO_ID_PREFIXES`
- `get_record_id_family_for_target_type`
- `get_allowed_record_id_prefixes_for_target_type`

Bu helperlar sadece bilgi dondurur. `AuditEventRecord.target_record_id` icin hard format validation eklemez.

## Neden boyle yaptik?

Adim 129'da projedeki ID orneklerinin tek formatta olmadigi goruldu. Adim 130, merkezi ID sozlesmesi icin asamali gecis planini yazdi. Adim 131 ise constants ve mapping helper katmaninin hard validation'dan once gelmesi gerektigini netlestirdi.

Bu adim, o planin ilk kod karsiligidir.

Santiye benzetmesiyle:

Bir arama-kurtarma veya kalite denetimi yapmadan once, sahadaki tum evrak klasorlerinin hangi isim ailesine ait oldugunu bilen bir indeks hazirlarsin. Bu indeks tek basina kimseyi durdurmaz; sadece hangi kaydin hangi aileye ait olabilecegini daha okunur hale getirir.

## Eklenen constants ne anlatir?

`RECORD_ID_PREFIXES`, record ID aileleri icin canonical prefix adaylarini tutar.

Ornek:

```python
RECORD_ID_PREFIXES = {
    "PROJECT": "PRJ",
    "FILE_ATTACHMENT": "ATT",
    "AUDIT_EVENT": "AUD",
    "NONCONFORMITY": "NCR",
}
```

`TARGET_RECORD_TYPE_TO_ID_FAMILY`, audit `target_record_type` degerinin hangi ID ailesi veya aileleriyle iliskili olabilecegini anlatir.

Ornek:

```python
TARGET_RECORD_TYPE_TO_ID_FAMILY = {
    "project": ("PROJECT",),
    "attachment": ("FILE_ATTACHMENT",),
    "project_record": ("NONCONFORMITY", "MATERIAL_DELIVERY", "GENERIC_RECORD"),
}
```

`TARGET_RECORD_TYPE_TO_ID_PREFIXES`, target type icin kabul edilebilir prefix adaylarini bilgi olarak dondurur. Bu liste canonical ve legacy ornekleri birlikte tasiyabilir.

## Helperlar nasil calisir?

`get_record_id_family_for_target_type(target_record_type)` desteklenen target type icin ID family tuple'i dondurur.

`get_allowed_record_id_prefixes_for_target_type(target_record_type)` desteklenen target type icin prefix tuple'i dondurur.

Bilinmeyen target type icin temiz `ValueError("target_record_type is not supported")` uretilir.

Bu helperlar `target_record_id` stringinin formatini kontrol etmez. Yani `NCR-001`, `REC-1`, `file-att-001` veya `audit-001` gibi legacy ornekleri model olusturmayi engellemez.

## Neyi bilerek yapmadik?

- `AuditEventRecord.__post_init__` icine prefix kontrolu eklemedik.
- `target_record_id` regex validation eklemedik.
- `target_record_type` ile `target_record_id` prefix uyumu icin hard hata uretmedik.
- Legacy ID orneklerini kirmadik.
- Persistence, repository, API, GUI, CLI veya podcast eklemedik.

## Testlerle neyi sabitledik?

Yeni testler sunlari sabitledi:

- Supported `target_record_type` icin ID family bilgisi doner.
- Supported `target_record_type` icin allowed prefix bilgisi doner.
- Bilinmeyen target type temiz `ValueError` verir.
- Helperlar `AuditEventRecord` olusturmayi zorlastirmaz.
- Legacy `target_record_id` ornekleri hala kabul edilir.

Bu testler, helper katmaninin bilgi verici kalmasini ve hard validation'a donusmemesini korur.

## Sonraki guvenli teknik adim

Sonraki guvenli adim, bu helper katmanini buyutmeden once test ornek standardizasyonu veya soft validation planini dokumante etmektir.

Hard validation ancak merkezi ID sozlesmesi, mapping, legacy veri stratejisi ve test standardizasyonu netlestikten sonra ele alinmalidir.
