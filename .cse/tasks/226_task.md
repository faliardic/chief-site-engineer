# Step 226 Task - Embedded DWG and Document Viewer Final Product Target

## Yetkili kaynaklar

- GitHub Issue: `#69`
- Resmi yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `022da791fe098e815ee026ec175dd9d3ec673474`
- Calisma branch'i: `step-226-embedded-dwg-document-viewer-target`

## Model ve reasoning secimi

- Codex model: `GPT-5.6 Sol`
- Reasoning seviyesi: `High`
- Secim nedeni: Coklu canonical kaynak ve state kaydi guncelleyen documentation-only product/architecture karari; production code veya executable contract degisikligi yetkisi yoktur.

## Amac

CSE final product target'ina `Embedded DWG and Document Viewer` katmanini kalici olarak ekle. Normal proje dosyasi review akisi mobile ve PC CSE uygulamasi icinde kalir; external application yalniz advanced editing veya unsupported technical cases icin optional escape hatch'tir.

## Yetkili dosyalar

Olustur:

- `docs/226_embedded_dwg_document_viewer_final_product_target.md`
- `learning/226_embedded_dwg_document_viewer_final_product_target.md`
- `.cse/tasks/226_task.md`
- `.cse/results/226_result.md`

Gerektigi kadar guncelle:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `learning/GLOSSARY.md`

## Product target contract'i

- Canonical ad: `Embedded DWG and Document Viewer`.
- Turkce ad: `Gomulu DWG ve Dokuman Viewer`.
- Hedef launcher degil, embedded in-app viewing'dir.
- DWG, DXF, PDF, DOCX, XLSX, CSV, text/Markdown, approved images ve engineering/project reports staged long-term targets'tir.
- Storage/metadata, rendering, annotation/measurement, record linking, revision comparison, offline cache ve advanced external editing ayrik capability layers olarak belgelenir.
- Mobile ve PC ayni canonical file/revision/metadata/relationship data'sini kullanir.
- CSE full CAD/BIM/Office/calculation authoring replacement olarak tanimlanmaz.
- Field MVP, reliable attachment storage, persistence, metadata/integrity/permissions/revision foundations near-term priority olarak kalir.

## Final acceptance target

Final product'ta user supported project file'i CSE icinde click/open eder; project/discipline/location/version/current-state gorur; supported navigation/measurement/markup yapar; exact point/section'i CSE record'a baglar; mobile/PC ayni relationship'i kullanir; offline freshness warning gorur; external open yalniz gerektiginde optional kalir.

## Yasak kapsam

- Main product model/repository veya normal product tests degismez.
- Viewer/rendering dependency, vendor/library secimi veya implementation yok.
- DWG parsing/conversion ve file processing yok.
- Physical attachment storage veya product persistence yok.
- API/GUI/CLI/PWA/mobile/desktop/offline implementation yok.
- Auth/audit/backup/encryption/deployment behavior yok.
- Workflow, historical podcast, ZIP/Desktop archive/exports mutation yok.
- Step 227 baslatilmaz; Podcast 036 olusturulmaz.

## Dogrulama

- `python -m pytest`
- `python -m json.tool .cse/state/project_state.json`
- `git diff --check`
- Full tests en az `503 passed`.
- Main product code ve normal product tests diff empty.
- Dependency/lock files diff empty.
- Viewer code/rendering package/file conversion artifact yok.
- `exports/` yalniz `.gitkeep`.
- Ignored ZIP untouched.

## Git yetkisi

- Tek commit: `Define embedded DWG document viewer target`
- Branch origin'e push edilir.
- Issue #69'a factual completion evidence eklenir.
- Force push, PR, merge veya branch deletion yoktur.

## Post-merge notu

Bu branch daha sonra merge edilirse resmi yerel `master`, sonraki Codex-required calismanin basinda `--ff-only` ile senkronlanir.
