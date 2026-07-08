# Adim 131 - Record ID Constants and Mapping Helper Plan

## Amac

Bu adimin amaci, Adim 129 record ID envanteri ve Adim 130 central record ID contract plan uzerine, ileride eklenecek record ID constants ve `target_record_type` / ID ailesi mapping helper icin plan hazirlamaktir.

Bu adim documentation-only / helper-design-planning adimidir. Kod, model, test, helper, validation veya runtime davranisi degistirilmedi.

## Arka plan: Adim 129 ve 130 bulgulari

Adim 129, projede tek bir ID formatinin bulunmadigini ve testlerde lower-case, upper-case, cok parcali prefix, path icine gomulu ID ve opsiyonel baglanti orneklerinin birlikte kullanildigini belgeledi.

Adim 130, merkezi record ID sozlesmesi icin ilk plan kararlarini verdi:

- Hard validation en son adim olmali.
- `target_record_type` ile ID ailesi mapping'i once netlesmeli.
- `project_record` gibi genis target type degerleri tek prefixe zorlanmamali.
- Explicit ID alani olmayan modeller icin ayri ID stratejisi gerekmeli.

Adim 131, bu kararlarin kodlanacak helper yapisina nasil donusebilecegini planlar.

## Onerilen constants yapisi

Ileride eklenecek constants yapisi davranis degistirmeden baslamalidir. Ilk hedef, daginik string kullanimini azaltmak ve mapping kararlarini tek yerde okunur hale getirmektir.

Onerilen constants adaylari:

| Constant | Amac | Ornek icerik | Ilk asama davranisi |
| --- | --- | --- | --- |
| `RECORD_ID_PREFIXES` | Canonical prefix adaylarini tutar | `{"PROJECT": "PRJ", "NONCONFORMITY": "NCR", "FILE_ATTACHMENT": "ATT"}` | Bilgi/dokumantasyon |
| `RECORD_ID_FIELD_NAMES` | ID ailesinin model alan adini tutar | `{"PROJECT": "project_id", "AUDIT_EVENT": "event_id"}` | Bilgi/dokumantasyon |
| `LEGACY_RECORD_ID_PREFIXES` | Mevcut lower-case veya eski prefixleri korur | `{"FILE_ATTACHMENT": ("att", "file-att")}` | Backward compatibility bilgisi |
| `TARGET_RECORD_TYPE_TO_ID_FAMILY` | `target_record_type` degerini ID ailesine veya ailelerine baglar | `{"project": ("PROJECT",), "project_record": ("NONCONFORMITY", "DAILY_LOG")}` | Bilgi/dokumantasyon |
| `TARGET_RECORD_TYPE_TO_PREFIXES` | `target_record_type` icin izinli prefix adaylarini verir | `{"attachment": ("ATT", "file-att", "att")}` | Soft validation zemini |
| `ID_FAMILY_EXAMPLE_FORMATS` | Dokumantasyon ve test ornegi icin format verir | `{"NONCONFORMITY": "NCR-2026-0001"}` | Test standardizasyon rehberi |

Bu constants ilk asamada `AuditEventRecord` validation icin kullanilmamalidir. Once sozlesme ve helper davranisi netlesmelidir.

## target_record_type / ID ailesi mapping taslagi

Mevcut `AUDIT_TARGET_RECORD_TYPES` lower-case degerler kullanir. Mapping helper bu degerleri bozmadan calismalidir.

| target_record_type | ID ailesi adaylari | Prefix adaylari | Not |
| --- | --- | --- | --- |
| `project` | `PROJECT` | `PRJ`, legacy `prj` | Proje kimligi. |
| `project_record` | `NONCONFORMITY`, `NONCONFORMITY_CANDIDATE`, `DAILY_LOG`, `SITE_NOTE`, `MATERIAL_DELIVERY`, `GENERIC_RECORD`, `CHECK_RESULT` | `NCR`, `NCR-CAND`, `LOG`, `NOTE`, `MAT-DEL`, `REC`, `CHK-RES` | Genis aile; hard validation icin riskli. |
| `attachment` | `FILE_ATTACHMENT` | `ATT`, legacy `file-att`, `att` | Canonical ve legacy ornekler birlikte var. |
| `attachment_metadata` | `FILE_ATTACHMENT`, `RELATED_RECORD` | `ATT`, `file-att`, `att`, hedef record prefixleri | Baglam bazli yorum gerekir. |
| `attachment_integrity_report` | `ATTACHMENT_INTEGRITY_REPORT` | `AIR`, `ATT-INT-RPT` | Henuz uygulama ID'si yok. |
| `json_export` | `JSON_EXPORT` | `JSON-EXP` | Henuz uygulama ID'si yok. |
| `backup_package` | `BACKUP_PACKAGE` | `BCK` | Henuz uygulama ID'si yok. |
| `restore_operation` | `RESTORE_OPERATION` | `RST` | Henuz uygulama ID'si yok. |
| `handover_package` | `HANDOVER_PACKAGE` | `HND` | Henuz uygulama ID'si yok. |
| `audit_event` | `AUDIT_EVENT` | `AUD`, `EVT`, legacy `audit` | Event id ailesi. |

Bu tablo helper planidir; hard validation degildir.

## Helper fonksiyon taslaklari

Ileride helper fonksiyonlari uc seviyede dusunulebilir.

### Sadece bilgi donen helper

Bu helperlar validation yapmaz; sadece sozlesme bilgisini dondurur.

Olası adlar:

- `get_id_families_for_target_record_type(target_record_type: str) -> tuple[str, ...]`
- `get_prefixes_for_target_record_type(target_record_type: str) -> tuple[str, ...]`
- `get_id_field_name_for_family(id_family: str) -> str | None`
- `get_example_id_format_for_family(id_family: str) -> str | None`

Bu fonksiyonlar ilk implementasyon icin en guvenli adaydir.

### Soft validation helper

Soft validation helper, sonucu raporlar ama model olusturmayi engellemez.

Olası adlar:

- `check_target_record_id_family(target_record_type: str, target_record_id: str) -> dict[str, object]`
- `is_target_record_id_prefix_known(target_record_type: str, target_record_id: str) -> bool`
- `get_target_record_id_prefix_warnings(target_record_type: str, target_record_id: str) -> tuple[str, ...]`

Bu helperlar uyumsuzlugu gorunur hale getirir, fakat `ValueError` uretmez.

### Hard validation helper

Hard validation helper sadece migration ve test standardizasyonu tamamlandiktan sonra dusunulmelidir.

Olası adlar:

- `validate_target_record_id_family(target_record_type: str, target_record_id: str) -> None`
- `validate_record_id_format(id_family: str, record_id: str) -> None`

Bu helperlar erken asamada eklenmemelidir.

## Soft validation ve hard validation ayrimi

Soft validation:

- Bilgi veya uyari dondurur.
- Eski ID orneklerini kirmaz.
- Test standardizasyonu oncesi kullanilabilir.
- Audit event model davranisini degistirmez.

Hard validation:

- Uyumsuz ID icin hata uretir.
- Mevcut testleri veya eski veri orneklerini kirabilir.
- Merkezi sozlesme, mapping ve migration tamamlandiktan sonra uygulanmalidir.

Bu adimda karar sudur: `AuditEventRecord.target_record_id` icin hard validation eklenmeyecek.

## Geriye uyumluluk yaklasimi

Geriye uyumluluk icin su yaklasim korunmalidir:

- Legacy lower-case ID ornekleri dokumante edilmeli.
- Canonical prefix onerileri yeni test orneklerinde kullanilmali.
- `project_record` gibi genis target type degerleri coklu ID ailesini desteklemeli.
- Explicit ID alani olmayan modeller hard validation disinda tutulmali.
- Helper mapping once bilgi dondurmeli; model davranisini degistirmemeli.

## Planlanan test senaryolari

Bu adimda test yazilmadi. Ileride helper implementasyonu yapilirsa su test basliklari eklenebilir:

- Supported target record type icin ID family listesi doner.
- `project` icin `PROJECT` ailesi doner.
- `attachment` icin `FILE_ATTACHMENT` ailesi ve `ATT` prefix onerisi doner.
- `project_record` icin birden fazla ID ailesi doner.
- Bilinmeyen target record type icin bos tuple, `None` veya kontrollu hata davranisi planlandigi gibi doner.
- Prefix onerisi canonical ve legacy prefixleri ayri gosterebilir.
- Soft validation helper bilinmeyen prefix icin uyari dondurur ama hard hata uretmez.
- Hard validation helper henuz `AuditEventRecord` tarafindan kullanilmaz.
- Legacy ID ornekleri (`prj-001`, `file-att-001`, `audit-001`) bozulmaz.
- Mevcut `target_record_id` ornekleri (`NCR-001`, `ATT-2026-0001`, `REC-1`) korunur.

## Bu adimda bilincli olarak yapilmayanlar

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- Constants veya helper implementasyonu eklenmedi.
- `AuditEventRecord.target_record_id` hard validation eklenmedi.
- Regex validation veya prefix validation eklenmedi.
- `FileAttachmentRecord` degistirilmedi.
- Podcast 021 olusturulmadi.
- Commit veya push yapilmadi.

## Sonraki guvenli teknik adim

Adim 132 icin en guvenli teknik adim, `record ID constants and mapping helper implementation` olabilir.

Bu implementasyon hard validation eklemeden baslamalidir:

- Constants eklenir.
- Bilgi donen helper fonksiyonlari eklenir.
- Mevcut `AuditEventRecord` validation davranisi degistirilmez.
- Testler helper davranisini dogrular, eski ID orneklerini kirmaz.
