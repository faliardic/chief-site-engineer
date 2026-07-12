# Adim 226 - Embedded DWG and Document Viewer Final Product Target

## Belge Durumu

- Canonical product target: `Embedded DWG and Document Viewer`
- Turkce ad: `Gomulu DWG ve Dokuman Viewer`
- Step tipi: documentation/state/learning-only
- Viewer implementation: `not_started`
- Vendor/library/technology selection: `not_started`
- File-format support implementation: `not_started`

Bu belge final product target'ini tanimlar. Mevcut CSE kodunda viewer, renderer, converter, preview, upload, offline cache veya mobile/desktop application eklendigi anlamina gelmez.

## 1. Kalici Urun Karari

CSE'nin uzun vadeli urun kapsami, project drawings ve documents icin embedded in-app viewing katmani icerir.

Hedef deneyim:

```text
CSE icindeki project file'a click
-> CSE icinde render/open
-> current revision ve metadata'yi anla
-> supported navigation, search, measurement ve markup yap
-> exact drawing point veya document section'i site record'a bagla
-> evidence ve follow-up'i ayni sistemde koru
```

Normal viewing ve site-review calismasi AutoCAD, Word, Excel, ayri PDF viewer veya baska external application'a gecmeyi gerektirmemelidir.

Advanced editing veya unsupported technical case icin ileride optional external-open command bulunabilir. Bu command ana deneyim degil, escape hatch'tir.

## 2. Launcher Degil Embedded Viewer

Bu product target bir file launcher degildir.

Launcher yaklasimi:

```text
CSE file link'i gosterir
-> operating system external application acar
-> user CSE context'inden cikar
```

Kabul edilen embedded hedef:

```text
CSE canonical file/revision/metadata'yi bilir
-> file CSE application surface icinde render edilir
-> user CSE record links, notes, measurements ve revision context'i ile calisir
```

External application yalniz advanced authoring, unsupported content veya teknik limit gerektirdiginde optional kalir.

## 3. Supported Content Long-Term Target

Asagidaki formatlar staged long-term support target'idir. Hicbiri Step 226'da implemented sayilmaz. Platform, renderer, licensing, fidelity, security ve performance feasibility her implementation phase'inde ayrica dogrulanir.

| Content family | Long-term target | Caveat |
| --- | --- | --- |
| DWG | Embedded read/review target | Rendering technology, licensing, fidelity ve large-file performance ayrica degerlendirilir |
| DXF | Embedded read/review target | Entity/version compatibility ayrica degerlendirilir |
| PDF | Embedded multipage read/review target | Text/search/measurement capability PDF content'ine baglidir |
| DOCX | Read-only document target | Full Word authoring hedef degildir; layout fidelity platforma gore degisebilir |
| XLSX | Read-only workbook/sheet target | Formula editing veya full Excel authoring hedef degildir |
| CSV | Structured tabular read target | Delimiter, encoding ve large-file behavior ayrica ele alinir |
| TXT / Markdown | In-app text read/search target | Encoding ve safe rendering kurallari gerekir |
| PNG/JPG/JPEG/WEBP/TIFF | In-app image target | Very large image, multipage TIFF ve metadata support ayrica ele alinir |
| Geotechnical investigation reports | Report viewing and record-linking target | Source format PDF/DOCX/XLSX olabilir |
| Structural calculation reports | Report viewing and record-linking target | Professional calculation re-run veya authoring hedef degildir |
| Architectural/structural/mechanical/electrical projects | Drawing/document viewing target | Discipline-specific metadata ve revision context gerekir |
| Permits/minutes/delivery notes/lab/test reports | Document evidence viewing target | Permissions, retention ve revision rules gerekir |
| Later approved types | Explicit future approval | Silent format expansion yoktur |

“Supported content target” ifadesi formatin bugun acilabildigi veya mobile/PC'de ayni fidelity ile calistigi anlamina gelmez.

## 4. Capability Layers

Viewer target asagidaki capability layers'a ayrilir. Bir katmanin belgelenmesi digerinin implemented oldugu anlamina gelmez.

### 4.1 File Storage and Metadata

Sorumluluk:

- physical file/storage reference;
- project, discipline, location ve related record metadata;
- MIME/file type ve size;
- checksum/integrity;
- permissions;
- revision/version identity;
- current/superseded state;
- retention ve archive rules.

Bu temel olmadan viewer guvenilir source'u belirleyemez.

### 4.2 Embedded Rendering and Viewing

Sorumluluk:

- file'i CSE icinde render etmek;
- zoom/pan;
- page/sheet navigation;
- technically supported text/content search;
- drawing layer visibility;
- safe read-only presentation.

Renderer file'in canonical identity veya revision kararini tek basina vermez.

### 4.3 Annotations and Measurements

Sorumluluk:

- distance, area, angle;
- feasible ise elevation/coordinate;
- note, arrow, box, highlight;
- revision cloud;
- author, timestamp ve later audit context.

Measurement reliability format, unit, scale, coordinate system ve renderer fidelity'ye baglidir. Guvenilir olmayan platform/format combination'inda measurement enabled gibi sunulmaz.

### 4.4 CSE Record Linking

Sorumluluk:

- exact drawing point, region, page, sheet veya document section anchor'i;
- anchor'i canonical file revision ile birlikte saklamak;
- anchor'dan CSE record'a gitmek;
- CSE record'dan drawing/document context'e donmek.

Hedef link adaylari:

- Field Observation;
- task;
- nonconformity/NCR;
- punch item;
- safety observation;
- QC/inspection record;
- concrete pour/sample record;
- meeting decision/action;
- RFI/submittal;
- photo/video/attachment;
- person/contact;
- location;
- trade/discipline;
- revision.

### 4.5 Revision Comparison

Sorumluluk:

- revision metadata;
- current-revision warning;
- superseded history;
- later side-by-side/overlay/difference capability;
- old anchor'in hangi revision'a ait oldugunu korumak.

Automatic engineering acceptance veya rejection karari verilmez.

### 4.6 Offline Caching

Sorumluluk:

- explicitly selected/downloaded file cache;
- cached revision identity;
- downloaded-at/synced-at bilgisi;
- freshness/version warning;
- connectivity geri geldiginde controlled refresh.

Offline copy canonical file'in yerine gecmez. Stale cache visible warning olmadan current gibi sunulmaz.

### 4.7 Advanced External Editing

Sorumluluk:

- full CAD/BIM/Office/calculation authoring gerektiğinde optional external-open;
- unsupported technical case icin kontrollu handoff;
- geri donuste yeni revision/import workflow'unu ileride ayri tasarlamak.

Normal review bu layer'a bagimli olmamalidir.

## 5. Intended Viewer Functions

File type ve platform caveat'leriyle long-term hedefler:

- in-app open;
- zoom ve pan;
- page/sheet navigation;
- text, sheet, axis, space veya content search where technically supported;
- DWG/DXF layer visibility controls;
- distance, area ve angle measurement;
- feasible ise elevation/coordinate reading;
- notes, arrows, boxes, highlights ve revision clouds;
- drawing point/document section anchors;
- CSE record create/connect actions;
- revision metadata ve current/superseded warning;
- later revision comparison;
- authorized selected page/region sharing/export;
- explicitly cached files icin offline viewing ve freshness warning;
- notes/markups/links/revision actions icin later auditability.

Her capability her format ve platformda esit desteklenmek zorunda degildir. UI capability availability'yi acikca gostermelidir.

## 6. Mobile Product Target

Mobile priorities:

1. Fast open.
2. Touch zoom/pan.
3. Simple search ve navigation.
4. Reliable oldugu formatlarda field measurement.
5. Markup ve note.
6. Photo, Field Observation ve task linking.
7. Selected files icin offline access.
8. Visible revision/cache freshness.

Mobile user'in temel sorusu:

```text
Sahada baktigim drawing/document current mi ve gordugum noktayi hemen kayda baglayabilir miyim?
```

Small screen, memory, battery, storage ve large-file performance constraints capability design'ini etkiler.

## 7. PC Product Target

PC priorities:

1. Large drawing ve report review.
2. Layer management.
3. Precise measurement.
4. Revision comparison.
5. Multi-document review.
6. Bulk metadata/archive workflows.
7. Reporting ve handover use.
8. Optional advanced external editing handoff.

PC client daha genis review surface saglasa da ayri canonical copy olusturmaz.

## 8. Shared Canonical Data Rule

Mobile ve PC clients ayni canonical data'yi kullanir:

```text
same file identity
same revision identity
same current/superseded state
same metadata
same notes and markups
same anchors and record relationships
same permissions and later audit history
```

Disconnected copies, birbirinden habersiz revision state veya client-specific hidden relationships final product target'iyle uyumlu degildir.

Offline cache ayri copy gibi gorunebilir; fakat canonical identity ve freshness status tasimak zorundadir.

## 9. CSE Ne Degildir?

CSE su urunlerin full authoring replacement'i olarak tanimlanmaz:

- AutoCAD veya equivalent full DWG authoring;
- Revit veya full BIM authoring;
- Microsoft Word full document editing;
- Microsoft Excel full spreadsheet authoring;
- professional engineering calculation software.

Ana urun degeri:

```text
view inside CSE
-> understand current revision
-> measure and mark up
-> connect exact context to site records
-> preserve evidence and follow-up
```

## 10. Long-Term Development Sequence

Bu sequence final capability dependency siralamasidir; immediate Step order degildir ve Field MVP onceligini override etmez.

1. Trustworthy attachment upload/storage foundation.
2. File metadata, integrity, permissions ve revision model.
3. Embedded PDF ve image preview.
4. Embedded DOCX/XLSX read-only viewing.
5. DWG/DXF rendering boundary ve technology evaluation.
6. Layer, search ve measurement tools.
7. Annotations ve markups.
8. Drawing/document anchor model linked to CSE records.
9. Revision comparison ve stale-revision warnings.
10. Mobile/PC offline viewing ve cache freshness.
11. Audit, backup/restore, authorization ve enterprise hardening.

Near-term higher priorities:

- Field MVP;
- attachment metadata maturity;
- persistence;
- reliable physical storage;
- integrity;
- permissions;
- revision foundations.

Viewer, core data-integrity work'ünü atlamak icin kullanilmaz.

## 11. Final Product Acceptance Target

Final target asagidaki user outcomes ile kabul edilir:

1. User CSE icindeki supported project file'a click eder.
2. File CSE'den ayrilmadan in-app goruntulenir.
3. User project, discipline, location, version ve current/superseded state'i gorur.
4. Supported navigation, measurement veya markup yapabilir.
5. Exact drawing point veya document section'i bir CSE site record'a baglayabilir.
6. Ayni relationship mobile ve PC'den gorulur.
7. Cached copy ile calisirken offline freshness/version warning gorulur.
8. External open yalniz advanced editing veya technical limitation gerektiginde optional kullanilir.

Acceptance format-specific capability matrix ile uygulanir; her formatta her tool zorunluymus gibi yorumlanmaz.

## 12. Product Risk and Decision Gates

Implementation oncesi ayri karar gerektiren konular:

- DWG/DXF renderer licensing ve deployment model;
- local/server conversion siniri;
- proprietary format security;
- fidelity ve unsupported entity behavior;
- scale/unit/coordinate reliability;
- large-file performance;
- mobile memory/storage/battery;
- malicious file isolation;
- document macro/external link handling;
- permission ve sharing rules;
- anchor stability across revisions;
- offline cache encryption ve freshness;
- audit/retention/legal evidence requirements;
- vendor lock-in ve exportability.

Step 226 bu gates icin teknoloji veya vendor secmez.

## 13. Current Implementation Truth

Step 226 sonunda:

- final product target documented: `true`;
- viewer implementation: `not_started`;
- renderer/vendor/library selected: `false`;
- supported file formats implemented: `none claimed`;
- annotations/measurements implemented: `false`;
- record anchors implemented: `false`;
- revision comparison implemented: `false`;
- offline viewer/cache implemented: `false`;
- external-open command implemented: `false`.

Current codebase test-backed domain/data/documentation core seviyesindedir.

## 14. Explicit Non-Scope

Bu adimda sunlar eklenmedi veya degistirilmedi:

- main product model/repository;
- executable test behavior;
- dependency veya rendering package;
- DWG/DXF parser/converter;
- upload/download/copy/move/delete;
- thumbnail/preview/file write;
- physical attachment storage;
- product persistence/database/SQLite/JSON;
- API/GUI/CLI/PWA/mobile/desktop application;
- offline sync/cache implementation;
- auth/role/tenant/audit/backup/encryption/deployment;
- automatic revision decision veya generated `blocked`;
- workflow/GitHub Actions;
- historical podcast;
- ZIP/Desktop archive/exports;
- Step 227;
- Podcast 036.
