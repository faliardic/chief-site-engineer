# Adim 226 - Embedded DWG and Document Viewer Urun Hedefini Ogrenmek

## Bu adimda ne yaptik?

CSE final product target'ina `Embedded DWG and Document Viewer` katmanini ekledik.

Bu bir implementation adimi degildir. Kod, dependency, renderer, mobile screen veya file conversion eklemedik. Once kullanici deneyimini, capability layers'i, riskleri ve acceptance target'ini netlestirdik.

Temel hedef:

```text
project file CSE icinde
-> view
-> revision'i anla
-> measure/markup
-> exact context'i site record'a bagla
-> evidence/follow-up'i koru
```

## Neden sadece "dosyayi ac" demedik?

“Dosyayi ac” iki farkli urun davranisi olabilir.

### Launcher

```text
CSE -> operating system -> AutoCAD/PDF viewer/Word/Excel
```

User CSE context'inden cikar. CSE record relationship'i, current revision warning ve markup context'i external application'da kaybolabilir.

### Embedded viewer

```text
CSE file identity + revision + permissions
-> CSE icinde render
-> CSE note/anchor/record links ile review
```

Kabul edilen hedef embedded viewer'dir. External-open yalniz advanced editing veya unsupported case icin optional escape hatch'tir.

## Yeni teknik terimler

### Embedded viewer

File content'ini baska application'a gecmeden mevcut product surface icinde render eden read/review layer'dir.

### Rendering

Binary veya structured file content'ini insanin gorebilecegi page, sheet, drawing, text, table veya image presentation'a donusturme isidir.

Rendering, file storage ile ayni sey degildir.

### Markup

Original file'i full authoring ile degistirmek yerine review amacli note, arrow, box, highlight veya revision cloud eklemektir.

### Document/drawing anchor

Bir file icindeki exact point, region, page, sheet veya section'i stable identity ile isaretleyen referanstir.

### Revision freshness

User'in gordugu file/cached copy'nin current revision ile ayni olup olmadigini anlatan durumdur.

### Escape hatch

Normal flow'u degistirmeyen, yalniz advanced veya unsupported case icin kullanilan optional alternatif command'dir.

## Capability layers neden ayrildi?

Bir viewer tek parca gibi gorunebilir. Gercekte en az yedi ayri responsibility vardir:

```text
1. storage + metadata
2. rendering + viewing
3. annotations + measurements
4. CSE record linking
5. revision comparison
6. offline caching
7. advanced external editing
```

Bu ayrimi yapmazsak su yanlis varsayimlar olusabilir:

- File metadata modeli var diye renderer var sanmak.
- PDF preview var diye DWG measurement guvenilir sanmak.
- Offline download var diye cached copy current sanmak.
- External-open command var diye embedded viewer tamamlandi sanmak.

## Kavramsal veri akisi

Asagidaki blok future conceptual flow'dur; mevcut Python implementation degildir:

```text
FileAttachmentRecord / future file entity
  -> storage reference
  -> integrity/checksum
  -> revision identity
  -> permission
  -> renderer capability selection
  -> in-app viewer session
  -> annotation/measurement
  -> anchor
  -> FieldObservation/Task/NCR/QC/RFI/etc.
```

## Future data contract ornegi

Asagidaki Python benzeri kod yalniz gelecekteki sorumluluklari anlatan ornektir; Step 226'da repo koduna eklenmemistir:

```python
@dataclass
class FutureDocumentAnchor:
    anchor_id: str
    file_id: str
    revision_id: str
    anchor_type: str
    page_or_sheet: str | None
    position_payload: dict[str, object]
    related_record_type: str
    related_record_id: str
```

Satir satir kavramsal anlam:

1. `anchor_id`, link kaydinin kimligidir.
2. `file_id`, hangi canonical file'a bakildigini soyler.
3. `revision_id`, point/section'in hangi revision'a ait oldugunu korur.
4. `anchor_type`, point, region, page veya sheet gibi anchor turunu anlatir.
5. `page_or_sheet`, multipage/multisheet content location'ini belirtir.
6. `position_payload`, format-specific coordinate/region verisini temsil edebilir.
7. `related_record_type`, Field Observation, task veya NCR gibi target turudur.
8. `related_record_id`, exact CSE record kimligidir.

Bu alanlar final model karari degildir. Ayrica issue ve validation tasarimi gerekir.

## Storage ile viewer arasindaki fark

Storage su soruya cevap verir:

```text
File nerede, hangi project'e ait, checksum ne, revision ne?
```

Viewer su soruya cevap verir:

```text
Bu file'i user'a guvenli ve dogru bicimde nasil gosterecegiz?
```

Annotation layer:

```text
User bu content uzerinde ne isaretledi?
```

Record-link layer:

```text
Bu exact point/section hangi saha kaydiyla ilgili?
```

Revision layer:

```text
User current revision'a mi bakiyor, old anchor yeni revision'da ne anlama geliyor?
```

## Format support neden staged?

DWG, PDF, DOCX, XLSX ve image ayni teknik yapi degildir.

| Format | Temel fark | Hedef caveat |
| --- | --- | --- |
| DWG/DXF | CAD entity/layer/coordinate | Renderer, licensing, fidelity, unit/scale |
| PDF | Page ve opsiyonel text/vector | Scanned PDF search/measurement sinirli olabilir |
| DOCX | Flow/layout document | Full Word fidelity ve editing hedef degil |
| XLSX | Workbook/sheet/formula | Read-only view, full authoring degil |
| CSV | Delimited text table | Encoding/delimiter/large file |
| Image/TIFF | Raster pixels | Scale yoksa engineering measurement guvenilmez olabilir |

Bu nedenle “format supported” tek boolean olmamalidir. Future capability matrix format + platform + tool bazinda dusunulmelidir.

Kavramsal ornek:

```text
PDF / PC / view = available
PDF / PC / text search = content-dependent
TIFF / mobile / measurement = unavailable unless reliable scale exists
DWG / mobile / layer control = future evaluation
```

## Mobile ve PC neden ayni canonical data'yi kullanmali?

Sahadaki mobile user ile ofisteki PC user farkli copy/revision kullanirsa kanit zinciri bozulur.

Dogru hedef:

```text
same file_id
same revision_id
same current/superseded state
same anchor relationships
same notes/markups
```

Client presentation farkli olabilir:

- mobile hiz ve touch interaction'a odaklanir;
- PC large review, precise measurement ve comparison'a odaklanir.

Data truth farkli olamaz.

## Mobile kullanim senaryosu

```text
Santiye sefi Field Observation aciyor
-> ilgili current structural drawing'i CSE icinde aciyor
-> touch zoom ile bolgeye gidiyor
-> revision freshness warning'i kontrol ediyor
-> noktaya markup/note ekliyor
-> photo ve observation'i anchor'a bagliyor
-> selected file offline cache ise freshness bilgisi korunuyor
```

Bu senaryo final target'tir; current implementation degildir.

## PC kullanim senaryosu

```text
Ofis muhendisi current ve superseded revisions'i inceliyor
-> layer visibility yonetiyor
-> supported precise measurement yapiyor
-> revision difference'i inceliyor
-> exact region'i NCR ve meeting decision'a bagliyor
-> handover/report workflow'unda relationship'i kullaniyor
```

Bu da final target'tir; current implementation degildir.

## Offline freshness neden gorunur olmali?

Offline file cache kullanisli ama risklidir.

Risk:

```text
user eski drawing'i offline goruyor
-> current sandigi icin sahada yanlis karar veriyor
```

Future cache metadata conceptual olarak sunlari tasiyabilir:

```json
{
  "file_id": "FILE-001",
  "cached_revision_id": "REV-003",
  "current_known_revision_id": "REV-004",
  "downloaded_at": "...",
  "last_checked_at": "...",
  "freshness": "stale"
}
```

Bu JSON current implementation degildir. Freshness warning acceptance target'ini anlatir.

## Revision comparison siniri

Revision comparison su anlama gelebilir:

- metadata seviyesinde version listesi;
- current/superseded warning;
- side-by-side view;
- overlay;
- visual/entity difference.

Her seviye ayni zorlukta degildir. Step 226 “later comparison capability” hedefini kaydeder, algorithm veya vendor secmez.

Automatic decision verilmez:

```text
difference found != engineering rejection
```

Human review ve resmi karar ayrica korunur.

## Development sequence'i nasil okuduk?

Sequence:

```text
trustworthy storage
-> metadata/integrity/permissions/revision
-> PDF/image preview
-> DOCX/XLSX read-only
-> DWG/DXF technology boundary
-> layer/search/measurement
-> annotation
-> anchor
-> revision comparison
-> offline freshness
-> enterprise hardening
```

Bu dependency mantigidir. “Bir sonraki 11 step aynen bunlar olacak” demek degildir.

Field MVP ve reliable data foundations near-term priority olarak kalir.

## Acceptance criteria nasil yazildi?

Final target user outcome ile tanimlandi:

```text
Given supported canonical project file
When user clicks file inside CSE
Then file remains inside CSE for normal review
And metadata/revision state is visible
And supported navigation/measurement/markup works
And exact context can link to CSE record
And mobile/PC share same relationship
And cached copy shows freshness warning
And external-open is optional only when required
```

Bu, teknoloji secmeden urun degerini test edilebilir dilde korur.

## Teknik karar tablosu

| Karar | Secilen hedef | Bilerek secilmeyen |
| --- | --- | --- |
| Open experience | Embedded in-app viewer | Launcher-only flow |
| CAD scope | Read/review/measure/markup/link | Full AutoCAD replacement |
| Office scope | Read-only review | Full Word/Excel authoring |
| Data | Shared canonical mobile/PC truth | Disconnected client copies |
| Revision | Visible current/superseded/freshness | Hidden automatic assumptions |
| Offline | Explicit cache + warning | Silent stale copy |
| External app | Optional escape hatch | Normal review dependency |
| Technology | Future evaluation | Step 226 vendor/library selection |
| Priority | Storage/data integrity first | Viewer icin foundations'i atlamak |

## Bu adimda hangi dosyalari neden guncelledik?

- `docs/226_embedded_dwg_document_viewer_final_product_target.md`: full product target ve acceptance contract.
- `learning/226_embedded_dwg_document_viewer_final_product_target.md`: kavramlar, katmanlar, scenarios ve future examples.
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`: kalici product architecture decision.
- `docs/project_decisions.md`: kisa canonical decision.
- `ROADMAP.md`: long-term staged checklist.
- `CHANGELOG.md`: Unreleased Step 226 kaydi.
- `README.md`: urun hedefi gorunurlugu.
- `.cse/state/project_state.json`: target documented ama implementation not_started gercegi.
- `learning/GLOSSARY.md`: kalici terimler.

## Testler neyi dogruluyor?

Bu adim executable behavior eklemedigi icin yeni test yazilmadi.

Mevcut full suite calistirilir:

```powershell
python -m pytest
```

Beklenti:

- en az `503 passed`;
- app code diff yok;
- normal product tests diff yok;
- dependency/lock diff yok;
- viewer package/code yok;
- JSON state valid;
- `git diff --check` passed.

Testlerin gecmesi viewer'in implemented oldugunu gostermez. Yalniz documentation-only degisikligin mevcut behavior'i bozmadigini gosterir.

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki, kullanicinin “dosyaya tiklayinca CSE icinde acilsin” karari launcher gibi daraltilmasin.

Sunu soyle yaptik ki, DWG/PDF/DOCX/XLSX gibi farkli formatlar tek “supported” etiketiyle gercek disi bicimde ayni capability seviyesinde gosterilmesin.

Sunu soyle yaptik ki, storage, rendering, markup, anchor, revision ve offline responsibilities birbirine karismasin.

Sunu soyle yaptik ki, mobile ve PC farkli UI kullansa bile ayni file/revision/relationship truth'u korusun.

Sunu soyle yaptik ki, viewer buyuk bir long-term differentiator olsun ama Field MVP, persistence ve reliable storage foundations'i atlatmasin.

Sunu soyle yaptik ki, final acceptance teknoloji adiyla degil user outcome ile tanimlansin.

## Sonuc

Step 226 sonunda `Embedded DWG and Document Viewer` CSE'nin kalici final product target'idir.

Fakat implementation state acikca `not_started` kalir. Hicbir format, renderer, measurement, markup, anchor, revision comparison veya offline cache implemented olarak isaretlenmez.
