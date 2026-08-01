# CSE Project Source Register

**Belge turu:** Proje kaynak kaydi
**Guncelleme adimi:** Issue #285
**Guncelleme tarihi:** 2026-08-01

Bu dosya, CHIEF SITE ENGINEER icin kalici proje kaynaklarini, destekleyici kaynaklari ve erisim durumunu kaydeder. Kaynak dosya yoksa veya bu Codex ortaminda erisilebilir degilse icerik uydurulmaz.

## Canonical Tracked Sources

| Source | Repository path | Role | Status |
| --- | --- | --- | --- |
| `CHIEF_SITE_ENGINEER_EXE_BIRLESTIRILMIS_PROJE_KAYNAGI.md` | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | Approved merged source for product purpose, strategy, data principles, product layers, roadmap, source-conflict resolutions, and long-term architecture | Available; copied with trailing-space normalization and Step 207 bootstrap addendum |
| `CSE_PROJECT_INSTRUCTIONS.md` | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | Operational workflow, Git/GitHub/Codex rules, safety, verification, and execution protocol | Tracked canonical operational instructions |
| `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | Binding addendum for validation class, evidence reuse, retry/time budgets, gate breadth, scope control and stop rules | Available; created by Issue #215 |
| `AGENTS.md` | `AGENTS.md` | Repository-root Codex pre-read and concise enforcement of minimum sufficient validation | Available; expanded by Issue #215 |
| `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | GitHub-native fresh-chat bootstrap, continuation rule and mandatory validation-protocol pre-read | Updated by Issue #215 |
| `CSE_ORCHESTRATOR_ARCHITECTURE.md` | `docs/orchestrator/CSE_ORCHESTRATOR_ARCHITECTURE.md` | Orchestrator component boundaries, operational truth, runtime-state and local/CI responsibility contract | O0 canonical design source; no runtime implementation |
| `CSE_ORCHESTRATOR_STATE_MACHINE.md` | `docs/orchestrator/CSE_ORCHESTRATOR_STATE_MACHINE.md` | Run states, transitions, invariants, blockers, budgets and append-only event contract | O0 canonical design source; executable engine deferred |
| `CSE_ORCHESTRATOR_SECURITY_BOUNDARY.md` | `docs/orchestrator/CSE_ORCHESTRATOR_SECURITY_BOUNDARY.md` | User-data, secret, capability, network and fail-closed security boundaries | O0 canonical design source; security implementation deferred |
| `CSE_ORCHESTRATOR_APPROVAL_MODEL.md` | `docs/orchestrator/CSE_ORCHESTRATOR_APPROVAL_MODEL.md` | Approval levels, latest-valid authorization and one-time fingerprint contract | O0 canonical design source; machine-readable verifier deferred |
| `CSE_ORCHESTRATOR_MVP_PLAN.md` | `docs/orchestrator/CSE_ORCHESTRATOR_MVP_PLAN.md` | O0-O10 delivery sequence and per-phase admission boundaries | O0 canonical program source; does not replace product roadmap |

## Authority and conflict rules

- Product purpose, user model and long-term direction: `CSE_UNIFIED_PROJECT_SOURCE.md`.
- General Git/GitHub/Codex safety and execution: `CSE_PROJECT_INSTRUCTIONS.md`.
- Validation breadth, evidence reuse, retry/time budget, environment-error handling and stop rules: `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`.
- `AGENTS.md` is the repository-level automatic Codex entry point and requires reading the full canonical documents.
- A current Issue may narrow the validation plan but cannot silently weaken data-safety rules.
- A current Issue cannot expand a narrow feature into release/toolchain work without explicit scope and validation-class change.
- Orchestrator sources govern development-run observation, approval, state and capability contracts; they do not override permanent product purpose, Git/Codex safety or minimum-validation protocols.
- `.cse/state/project_state.json` remains a published/finalized snapshot and cannot override current Git/GitHub/Issue evidence.

## Original Project Sources

| Original title | Role | Repository copy | Status |
| --- | --- | --- | --- |
| `Şantiye Şefi İçin Dünya Örneklerine Dayalı Kontrol, Takip ve Arşivleme Sistemi Yol Haritası.pdf` | Supporting research source | None | Not available in this Codex environment; not fabricated |
| `CHIEF_SITE_ENGINEER_Guncel_Yol_Haritasi_Ozel_Alan_Ekli.pdf` | Supporting product/module roadmap source | None | Not available in this Codex environment; not fabricated |
| `CSE_CHAT_HANDOFF_PROTOCOL_SOURCE_PACKAGE.zip` | Historical handoff package provenance | None | Raw ZIP not available in this Codex environment and must not be committed |
| `1. CSE önce güvenilir veri omurgası.txt` | Active data-principles source | `docs/reference_sources/cse_once_guvenilir_veri_omurgasi.txt` | Available and copied with ASCII-safe filename |
| `CSE_STRATEGIC_PRODUCT_DIRECTION.md` | Active strategy source | None | Not available in this Codex environment; not fabricated |
| `CHIEF_SITE_ENGINEER_EXE_BIRLESTIRILMIS_PROJE_KAYNAGI.md` | Approved merged source used to create tracked unified source | `docs/reference_sources/chief_site_engineer_exe_birlestirilmis_proje_kaynagi.md` and `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | Available; repository copies normalize trailing line spaces and do not reconstruct source content |

## Source Handling Rules

- Do not commit duplicate `(1)` source copies.
- Do not commit raw handoff ZIP packages.
- Do not fabricate unavailable PDF, TXT, Markdown, or ZIP content.
- Preserve original source titles in this register even when repository filenames use ASCII-safe names.
- Future chats read tracked GitHub versions after the source has been added to the repository.
- Uploaded or local source files may establish or update tracked canonical sources only in an authorized step.
- Every new chat and Codex run must read the minimum sufficient validation protocol before choosing tests, builds or physical-device gates.

## Historical Step 207 Access Evidence

Accessible local source files found during Step 207:

```text
V:\1_PROJECTS\2_ACTIVE\Python\CHIEF_SITE_ENGINEER_EXE_BIRLESTIRILMIS_PROJE_KAYNAGI.md
V:\1_PROJECTS\2_ACTIVE\Python\cse-notes\1. CSE önce güvenilir veri omurgası.txt
```

Unavailable original source files in that environment:

```text
Şantiye Şefi İçin Dünya Örneklerine Dayalı Kontrol, Takip ve Arşivleme Sistemi Yol Haritası.pdf
CHIEF_SITE_ENGINEER_Guncel_Yol_Haritasi_Ozel_Alan_Ekli.pdf
CSE_CHAT_HANDOFF_PROTOCOL_SOURCE_PACKAGE.zip
CSE_STRATEGIC_PRODUCT_DIRECTION.md
```
