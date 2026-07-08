# Changelog

## Podcast 021

- Added Podcast 021 / Step 127-131 NotebookLM podcast note.
- Covered the Step 127 safe-point quality-control pass, Step 128 `FileAttachmentRecord` required metadata validation, Step 129 record ID inventory, Step 130 central record ID contract plan, and Step 131 record ID constants and mapping helper plan.
- Documented that `AuditEventRecord.target_record_id` hard validation remains intentionally deferred until ID inventory, central contract, mapping helper, and test standardization are clear.
- Kept this as a documentation-only podcast step; no application code, tests, validation behavior, audit hard validation, Step 132 work, commit, push, or ZIP staging was added.
- Verified `python -m pytest`: `251 passed`.

## Step 131

- Added a documentation-only record ID constants and target record type mapping helper plan.
- Planned `RECORD_ID_PREFIXES`, `RECORD_ID_FIELD_NAMES`, target type to ID family mappings, information-only helpers, soft validation helpers, hard validation helpers, and future test scenarios.
- Kept hard validation out of scope; `AuditEventRecord.target_record_id` behavior was not changed.
- Kept this as helper-design-planning; no application code, tests, constants implementation, helper implementation, audit validation, target id regex, persistence, repository behavior, API, GUI, CLI, podcast, commit, push, or ZIP staging was added.
- Verified `python -m pytest`: `251 passed`.

## Step 130

- Added a documentation-only central record ID contract plan based on the Step 129 inventory.
- Planned ID families, prefix candidates, target record type / ID family mapping, backward compatibility risks, and a phased path from documentation to helper mapping, test standardization, soft validation, and eventual hard validation.
- Documented that `AuditEventRecord.target_record_id` hard format validation will not be added until the central record ID contract and target type / ID family mapping are clear.
- Kept this as architecture planning; no application code, tests, audit validation, target id regex, helper implementation, persistence, repository behavior, API, GUI, CLI, podcast, commit, push, or ZIP staging was added.
- Verified `python -m pytest`: `251 passed`.

## Step 129

- Added a documentation-only record ID inventory and audit target id validation risk analysis.
- Documented model-level ID fields, representative test ID formats, current inconsistency risks, and why `AuditEventRecord.target_record_id` format validation should wait for a central record ID contract.
- Kept this as architecture-decision-prep; no application code, tests, audit validation, target id regex, persistence, repository behavior, API, GUI, CLI, podcast, commit, push, or ZIP staging was added.
- Verified `python -m pytest`: `251 passed`.

## Step 128

- Closed small validation gaps in `FileAttachmentRecord` required metadata fields.
- `attachment_id`, `related_record_type`, `related_record_id`, `file_name`, `file_path`, and `file_type` now reject `None` with controlled `ValueError` messages instead of uncontrolled attribute errors.
- `file_type` and `mime_type` are now part of the same empty-string required field validation path.
- Added focused model tests for `None` required fields and empty `mime_type`.
- No audit event model, audit target id validation, persistence, repository behavior, API, GUI, CLI, commit, push, or ZIP staging was added.

## Step 127

- Updated README, ROADMAP, changelog, and project decision documentation for the Step 127 safe-point quality-control pass.
- Added repository hygiene policy for ZIP files and LF line endings through `.gitignore` / `.gitattributes`.
- Kept this as a documentation / cleanup / quality-control step.
- No application behavior, model, validation, business logic, or test file behavior was changed.
- Verified `python -m pytest`: `243 passed`.
- Verified `git diff --check`: clean.
- No commit, push, or ZIP staging was added.

## Step 126

- Added Podcast 020 / Step 115-120 NotebookLM podcast note.
- Kept this as a documentation-only step.
- No application code or test files were changed.
- No commit, push, or ZIP staging was added.

## Step 125

- Added Podcast 019 / Step 109-114 NotebookLM podcast note.
- Kept this as a documentation-only step.
- No application code or test files were changed.
- No commit, push, or ZIP staging was added.

## Step 124

- Added Podcast 018 / Step 103-108 NotebookLM podcast note.
- Kept this as a documentation-only step.
- No application code or test files were changed.
- No commit, push, or ZIP staging was added.

## Step 123

- Added Podcast 017 / Step 097-102 NotebookLM podcast note.
- Kept this as a documentation-only step.
- No application code or test files were changed.
- No commit, push, or ZIP staging was added.

## Step 122

- Documented the validation design for `AuditEventRecord.target_record_id`.
- Defined general format validation and prefix/type matching as two separate stages.
- Documented the future error message design and validation order.
- Explained the backward compatibility risk.
- No code, tests, regex validation, prefix validation, repository, persistence, commit, push, or ZIP staging was added.

## Step 121

- Documented the first format design for `AuditEventRecord.target_record_id`.
- Added the target type / prefix candidate table.
- Clarified the separation between target_record_id and event_type, target_record_type, reason, notes, old_value, and new_value.
- Documented future validation options.
- No code, tests, validation, regex, repository, persistence, commit, push, or ZIP staging was added.

## Step 120

- Added the initial audit target record type constants.
- Added supported-list validation for `AuditEventRecord.target_record_type`.
- Empty or whitespace-only target record reference values are now rejected.
- No target record id format validation, repository, persistence, automatic audit writing, commit, push, or ZIP staging was added.

## Step 119

- Documented the first type contract for `AuditEventRecord.target_record_type`.
- Listed the initial target record type candidates.
- Clarified the separation between target record type and event type, reason, notes, old_value, and new_value.
- Documented the future allowed-list validation design.
- No code, tests, validation, enum, repository, persistence, commit, push, or ZIP staging was added.

## Step 118

- Added pair validation for `AuditEventRecord.target_record_type` and `target_record_id`.
- Single-sided target record references are now rejected with `ValueError`.
- Kept validation None-based in this step.
- No target type constants, enum, allowed-list, repository, database, persistence, automatic audit writing, commit, push, or ZIP staging was added.

## Step 117

- Documented relationship rules for `AuditEventRecord.target_record_type` and `target_record_id`.
- Listed initial target record type candidates.
- Clarified the separation between event type, target record, reason, notes, old_value, and new_value.
- No code, tests, validation, enum, constants, repository, persistence, automatic audit writing, commit, push, or ZIP staging was added.

## Step 116

- Added the initial audit event type constants.
- Added supported-list validation for `AuditEventRecord.event_type`.
- Unsupported event type values are now rejected with `ValueError`.
- No database, repository, persistence, JSON audit export, automatic audit writing, scanner integration, commit, push, or ZIP staging was added.

## Step 115

- Documented the first `AuditEventRecord.event_type` contract.
- Defined the domain/action naming format for audit event type values.
- Listed initial event type candidates for record, attachment, integrity, JSON export, backup/restore, handover, and audit system events.
- No code, tests, validation, enum, constants, repository, persistence, automatic audit writing, commit, push, or ZIP staging was added.

## Step 114

- Added required field validation for `AuditEventRecord`.
- Empty, whitespace-only, and `None` values are rejected for `event_id`, `project_id`, `event_type`, `actor`, and `occurred_at`.
- Kept optional audit metadata fields flexible; no format, enum, target pair, JSON, or length validation was added.
- No repository, persistence, JSON audit export, automatic audit writing, database, API, GUI, CLI, scanner integration, backup/restore behavior, commit, push, or ZIP staging was added.

## Step 113

- Added the `AuditEventRecord` dataclass as a plain starting model for traceable audit events.
- Added focused model tests for required audit event fields, optional defaults, target record references, and change context metadata.
- Documented that this step adds no persistence, audit helper, automatic audit writing, database, API, GUI, CLI, scanner integration, backup/restore behavior, commit, push, or ZIP staging.

## Step 112

- Documented the audit event model plan.
- Clarified that an audit event is an event trail, not an official record, JSON export file, backup file, or scanner result.
- Recorded future field candidates and event type candidates for an eventual audit event model.
- Explained its relation to attachment integrity reports, JSON export snapshots, backup/restore, and official record separation.
- No application code, test files, `AuditEventRecord`, audit helper, database, API, GUI, CLI, AI integration, scanner change, backup/restore implementation, commit, push, or ZIP staging was added.

## Step 111

- Documented the attachment integrity report usage summary.
- Explained how the dry-run helper, `AttachmentIntegrityResult`, `AttachmentIntegrityReport`, serializer helpers, and JSON export line fit together.
- Clarified that the report is not an official record and JSON export is only a report/snapshot output, not a permanent data store.
- No application code, test files, scanner implementation, file system scan, orphan scan, root/path security helper, audit, backup, database, API, GUI, CLI, AI integration, commit, push, or ZIP staging was added.

## Step 110

- Added edge-case tests and usage clarification for the scanner dry-run helper.
- Verified extra map paths are ignored, duplicate paths are not treated as duplicate metadata, exact path matching is required, input order is preserved, the path map is not mutated, and map `True` can produce `OK` without creating real files.
- Confirmed the helper still does not perform real file system scanning, orphan scan, folder traversal, root/path security checks, file delete/move/copy, upload, backup, audit, database, API, GUI, CLI, or AI integration.
- No commit, push, or ZIP staging was added.

## Step 109

- Added the attachment integrity dry-run helper start.
- The helper produces `AttachmentIntegrityResult` values from provided `FileAttachmentRecord` metadata records and a path-to-exists map without scanning the real file system.
- Added tests for existing files, missing files, missing map entries, multiple records, shared `checked_at`, map-only behavior without creating files, non-mutating input behavior, and empty input.
- No folder traversal, orphan scan, root/path security check, file delete/move/copy, upload, backup, audit, database, API, GUI, CLI, AI integration, commit, push, or ZIP staging was added.

## Step 108

- Documented the attachment integrity scanner input model plan.
- Clarified that the future input model may carry `attachment_records`, `attachment_root`, orphan-check options, source/notes metadata, and safety boundaries.
- Defined that the input model is not scanner implementation and does not scan files, read files, delete, move, update metadata, or integrate upload, backup, audit, database, API, GUI, CLI, or AI behavior.
- No application code, test files, dataclass, scanner helper, commit, push, or ZIP staging was added.

## Step 107

- Documented the attachment integrity scanner scope plan.
- Clarified that the future scanner will check consistency between `FileAttachmentRecord` metadata and the physical file system in dry-run mode.
- Defined the first scanner scope as reporting/detection only, without deleting, moving, fixing, upload service integration, backup, audit, database, API, GUI, CLI, or AI integration.
- Recorded path traversal protection and explicit attachment root boundaries as scanner safety principles.
- No application code, test files, scanner implementation, file system scan, commit, push, or ZIP staging was added.

## Step 106

- Documented the CSE product vision and site memory strategy.
- Clarified that the first real competitors are not large construction management platforms, but scattered field habits such as WhatsApp groups, phone galleries, Excel lists, notebook notes, folder disorder, mail attachments, and "I wrote this somewhere" workflows.
- Positioned CSE as the site chief's smart agenda, field memory, photo/file evidence archive, and reliable data ground for a future AI-assisted field helper.
- Clarified that AI is not the first layer; it is a later value-increasing layer built on top of a reliable data backbone and searchable site memory.
- No application code, test files, database, API, GUI, CLI, scanner, upload service, AI integration, automation, commit, push, or ZIP staging was added.

## Step 105

- Added `export_attachment_integrity_report_to_json_file` to write an `AttachmentIntegrityReport` JSON string to an explicitly provided file path.
- Used the existing JSON string export helper, UTF-8 encoding, `overwrite=False` by default, `FileExistsError` for existing files, and `FileNotFoundError` for missing parent folders.
- Added `tmp_path` tests for file creation, loadable JSON, summary/results fields, Turkish text preservation, overwrite behavior, missing parent handling, returned path, and non-mutating export behavior without adding scanner, traversal, backup, audit, upload service, push, or ZIP staging.

## Step 104

- Documented the future attachment integrity JSON file export design after the Step 103 JSON string export helper.
- Defined UTF-8, `ensure_ascii=False`, default indentation, file naming, export path, overwrite, atomic write, validation, audit/backup relation, and security-risk expectations.
- No application code, tests, JSON file writing, scanner, backup/restore implementation, audit event implementation, README update, push, or ZIP staging was added.

## Step 103

- Added `export_attachment_integrity_report_to_json` to convert an `AttachmentIntegrityReport` into a JSON string using the existing report serializer.
- Added tests for JSON string export, `json.loads` compatibility, summary/results fields, ISO datetime preservation, Turkish character preservation with `ensure_ascii=False`, compact output with `indent=None`, and non-mutating export behavior.
- No JSON file writing, path handling, scanner, folder traversal, upload service, backup/restore implementation, audit event implementation, README update, push, or ZIP staging was added.

## Step 102

- Updated `README.md` to reflect the Step 100 safe point, `191 passed` test status, current attachment integrity line, policy documents, podcast notes, and Step 101 audit findings.
- Replaced stale Step 080 / `125 passed` README information with the current Step 100 / `191 passed` project state.
- No application code, tests, scanner, upload service, database, API, GUI, auth, CI, deployment, commit, push, or ZIP staging was added.

## Step 101

- Added a general project audit and architecture health report after the Step 100 safe point.
- Reviewed project structure, application modules, tests, documentation, learning notes, attachment integrity, data protection policy, roadmap alignment, risks, strengths, and the recommended Step 102-120 path.
- Identified README freshness, `app/models.py` growth, large test files, scanner complexity, and private workspace / official record separation as key follow-up areas without changing application code or tests.

## Step 100

- Added the final Step 100 safe point quality-control document for the Step 081-099 work line.
- Verified the current branch, latest commits, branch distance from `origin/master`, required podcast/policy/integrity files, and the pytest result.
- Documented that no application code, tests, new feature behavior, scanner, upload service, database, API, GUI, auth, CI, deployment, push, or ZIP staging was added.

## Step 099

- Added the final NotebookLM podcast note for Step 091-096.
- Summarized the attachment integrity result, single-record helper, report summary, report model, serializer helpers, and CSE data protection/private workspace policy decisions.
- No application code, tests, scanner, upload service, database, API, GUI, auth, CI, deployment, push, or ZIP staging was added.

## Step 098

- Added the final NotebookLM podcast note for Step 081-090.
- Summarized README/ROADMAP correction, canonical attachment model decisions, field contract, canonical path standard, enum preparation, validation, path helper, metadata integrity rules, and status constants.
- No application code, tests, scanner, upload service, database, API, GUI, auth, CI, deployment, push, or ZIP staging was added.

## Step 097

- Added the final NotebookLM podcast note for Step 071-080.
- Summarized the `FileAttachmentRecord` usage flow, usage scenarios, storage/naming decisions, archive safety decisions, metadata field clarifications, and Step 080 safe point.
- No application code, tests, upload service, scanner, JSON file writing, API, GUI, auth, CI, deployment, push, or ZIP staging was added.

## Step 096

- Added core CSE policy documents for long-term project principles, official-record deletion prevention, private workspace isolation, and site chief handover scenarios.
- Documented that official project records should not be physically deleted and that private site chief workspace data must stay separate from official project records.
- Added glossary terms for official records, private workspace, handover packages, soft/hard delete, archive, void, superseded records, crypto-shredding, data isolation, and owner user id without adding code, migrations, auth, encryption, scanner, upload service, push, or ZIP staging.

## Step 095

- Added serializer helpers for `AttachmentIntegrityResult`, `AttachmentIntegrityReportSummary`, and `AttachmentIntegrityReport`.
- Serialized datetime fields with ISO 8601 strings and kept `None` fields in the output dictionaries.
- Added tests for result, summary, report, nested results, nested summary, datetime serialization, `None` preservation, and non-mutating serializer behavior without writing JSON files or adding scanner/file export behavior.

## Step 094

- Added `AttachmentIntegrityReport` to carry attachment integrity results together with their report summary.
- Added `build_attachment_integrity_report` to build a report and summary from existing `AttachmentIntegrityResult` records.
- Added tests for empty reports, tuple storage, source/notes, generated time behavior, summary mismatch validation, and helper summary generation without adding scanner or file system traversal behavior.

## Step 093

- Added `AttachmentIntegrityReportSummary` to represent the top-level summary of future attachment integrity reports.
- Added `build_attachment_integrity_report_summary` to count status and severity values from existing `AttachmentIntegrityResult` records.
- Added tests for empty, OK-only, error, warning, mixed, generated time, negative counter, and inconsistent total cases without adding scanner or file system traversal behavior.

## Step 092

- Added `build_attachment_integrity_result` to produce a single `AttachmentIntegrityResult` from provided metadata and file existence flags.
- Added recommended action constants and tests for OK, missing file, orphan file, invalid path, duplicate metadata, unreadable file, rejected empty metadata/file cases, checked time, and notes.
- No bulk scanner, folder traversal, file system scan, upload service, backup logic, audit event implementation, push, or ZIP staging was added.

## Step 091

- Added `AttachmentIntegrityResult` as the single-result model for future attachment integrity scanner output.
- Added severity constants for `OK`, `WARNING`, and `ERROR`, plus validation for known status and severity values.
- Added focused tests for default UTC `checked_at`, result field storage, invalid values, and `MISSING_FILE` / `ORPHAN_FILE` / `OK` examples without adding scanner or file system behavior.

## Step 090

- Added centralized attachment integrity status constants for `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA`, and `UNREADABLE_FILE`.
- Added immutable all-status, error-status, and warning-status collections with focused tests.
- No scanner implementation, file system scan, upload service, backup logic, audit event implementation, database, API, GUI, auth, CI, deployment, push, or ZIP staging was added.

## Step 089

- Documented attachment metadata integrity rules for a future missing/orphan scanner.
- Defined `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA`, and `UNREADABLE_FILE` states with severity and recommended action guidance.
- No application code, tests, scanner implementation, file system scan, upload service, database, API, GUI, auth, CI, deployment, or push was added.

## Step 088

- Added `build_attachment_path` to generate canonical attachment metadata paths.
- Added tests for string/date/datetime dates, safe file name normalization, empty required values, invalid date strings, and record type lowercasing.
- No upload service, physical file operation, database, API, GUI, auth, CI, deployment, or `FileAttachmentRecord` field change was added.

## Step 087

- Added minimal `FileAttachmentRecord` validation for empty required metadata, invalid `file_type`, and negative `file_size`.
- Kept `uploaded_by` and `uploaded_at` optional and did not add an attachment `status` field.
- Added focused validation tests without adding path helper, upload service, database, API, GUI, auth, CI, deployment, or physical file operations.

## Step 086

- Added lightweight `FileType` and `AttachmentStatus` enum preparation for canonical file attachment vocabulary.
- Kept `FileAttachmentRecord.file_type` as a string field and avoided validation or breaking model changes.
- Added a focused enum value test and documented that stricter validation is deferred to a later step.

## Step 085

- Locked the canonical attachment path standard as `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}`.
- Updated file attachment documentation examples to align with the canonical path structure where appropriate.
- No upload service, path helper, physical file operation, database, API, GUI, auth, CI, deployment, test change, or breaking refactor was added.

## Step 084

- Clarified the `FileAttachmentRecord` field contract for optional model-level upload metadata.
- Documented that `uploaded_by` and `uploaded_at` remain optional in the dataclass until upload/auth services can enforce or populate them at service level.
- No model field, test change, repository behavior, upload service, database, API, GUI, auth, CI, deployment, or breaking refactor was added.

## Step 083

- Clarified the model decision between legacy `AttachmentRecord` and canonical `FileAttachmentRecord`.
- Documented that new file attachment development should continue through `FileAttachmentRecord` while `AttachmentRecord` remains for compatibility with earlier tests and documentation.
- No model field, repository behavior, upload service, database, API, GUI, auth, CI, deployment, or breaking refactor was added.

## Step 082

- Updated `ROADMAP.md` to reflect the real Step 080 safe-point state after the Step 081 README correction.
- Summarized completed Step 001-080 phases and planned Step 081-090 as documentation/standard locking and Step 091-100 as persistence/upload/integrity/operation backbone work.
- Explicitly documented that database, real upload service, API, GUI, auth, CI, and deployment are not present yet.

## Step 081

- Updated `README.md` to reflect the real Step 080 safe-point repository state.
- Clarified that the project is currently a domain model, in-memory repository, test, documentation, learning, and podcast-note core rather than a deployed product.
- Documented the current `125 passed` test result and explicitly listed missing production features such as database, upload service, API, GUI, auth, deployment, and CI.

## Step 080

- Added a closing metadata summary for the `FileAttachmentRecord` attachment line from Step 072-079.
- Summarized usage flow, example scenarios, storage/naming standards, archive safety decisions, and metadata fields such as `original_file_name`, `uploaded_by`, `uploaded_at`, and `notes`.
- No application code, tests, new model field, repository, persistence, SQLite, JSON, API, GUI, CLI, file upload/copy/delete/move, thumbnail, preview, video playback, or streaming behavior was changed in this step.

## Step 079

- Clarified the `FileAttachmentRecord.notes` field for attachment-specific context, warnings, and short site explanations.
- Added tests confirming that attachment notes are stored when provided and default to `None` when omitted.
- No model field change, file upload, physical file copy/delete/move, notes search/filtering, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, streaming, user/role/permission system, or large service was added in this step.

## Step 078

- Updated `FileAttachmentRecord.uploaded_at` to be optional string metadata with a default value of `None`.
- Added tests confirming that `uploaded_at` is stored when provided and defaults to `None` when omitted.
- No automatic timestamp generation, datetime parsing/formatting, user model, role/permission system, authentication, authorization, file upload, physical file copy/delete/move, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, or streaming behavior was added in this step.

## Step 077

- Updated `FileAttachmentRecord.uploaded_by` to be optional string metadata with a default value of `None`.
- Added tests confirming that `uploaded_by` is stored when provided and defaults to `None` when omitted.
- No user model, role/permission system, authentication, authorization, file upload, physical file copy/delete/move, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, or streaming behavior was added in this step.

## Step 076

- Added `original_file_name` as an optional metadata field on `FileAttachmentRecord`.
- Added tests confirming that the original uploaded filename is stored when provided and defaults to `None` when omitted.
- No file upload, physical file copy/delete/move, filename standardization function, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, or streaming behavior was added in this step.

## Step 075

- Added archive safety and delete/move decision documentation for `FileAttachmentRecord` attachments.
- Documented soft-delete preference, missing file references, move history, no-overwrite guidance, audit trail planning, backup expectations, and video-specific safety notes.
- No application code, tests, new model, repository, file upload/delete/move/copy, SQLite, JSON persistence, API, GUI, CLI, thumbnail, preview, streaming, or video playback behavior was changed in this step.

## Step 074

- Added a storage folder and file naming standard document for `FileAttachmentRecord` attachments.
- Documented proposed attachment folder structure, date-based subfolders, naming template, original filename handling, metadata notes, video-specific rules, and backup/archive considerations.
- No application code, tests, repository, file upload, physical file copy/delete/move, thumbnail, video playback, preview, streaming, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 073

- Added example usage scenarios for `FileAttachmentRecord` across concrete pours, NCR records, material deliveries, daily site records, workforce records, chief private notes, and inspection records.
- Reiterated that attachments store file references and metadata, not embedded file contents or video blobs.
- No application code, tests, repository, file upload, physical file copy, file delete/move, thumbnail, video playback, streaming, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 072

- Added a usage flow document for `FileAttachmentRecord`.
- Documented how photo, video, PDF, document, and audio attachments can be linked to main records through file references and metadata.
- No application code, tests, repository, file upload, physical file copy, video playback, thumbnail generation, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 071

- Added the final NotebookLM podcast note for Step 061-070.
- Summarized the transition from NCR archive/listing documentation to search/filtering behavior and file attachment metadata/reference modeling.
- No application code, tests, repository, file upload, video playback, thumbnail generation, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 070

- Added a usage summary for `FileAttachmentRecord.related_record_type` and `related_record_id`.
- Documented how file attachments can link to NCR, site note, daily log, material delivery, inspection, safety observation, concrete pour, and chief private note records.
- No application code, tests, repository, file upload, foreign key, ORM relation, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 069

- Documented and tested the basic `FileAttachmentRecord.file_type` classification values: `image`, `video`, `pdf`, `document`, `audio`, and `other`.
- Added model tests showing each file type as metadata/reference, including MIME type and filename examples.
- No model field change, enum, validation, repository, file upload, video playback, thumbnail generation, JSON, SQLite, API, GUI, or CLI behavior was added in this step.

## Step 068

- Added `FileAttachmentRecord` as a dataclass model for photo, video, PDF, document, audio, and other file attachment metadata references.
- Added tests for required values, optional defaults, video metadata representation, and related record linking.
- No repository, file upload, physical file copy, video playback, thumbnail generation, JSON, SQLite, API, GUI, CLI, or persistence behavior was added in this step.

## Step 067

- Added a plan document for file, photo, video, PDF, document, and audio attachments.
- Clarified that video files should not be embedded in the database; only file references and metadata should be stored.
- No application code, tests, JSON, SQLite, API, GUI, CLI, file upload, video playback, thumbnail generation, streaming, or media processing was added in this step.

## Step 066

- Added `NonconformityRepository.list_by_location` for in-memory NCR filtering by `location`.
- Added focused tests for empty repositories, matching locations, missing locations, archived records, and restored records.
- No JSON, SQLite, API, GUI, CLI, query engine, delete behavior, automatic history, or workflow behavior was added in this step.

## Step 065

- Confirmed the existing `NonconformityRepository.list_by_status` behavior as the NCR status filtering behavior.
- Added focused tests for empty repositories, matching statuses, missing statuses, archived records, and restored records.
- No application code, JSON, SQLite, API, GUI, CLI, query engine, delete behavior, automatic history, or workflow behavior was changed in this step.

## Step 064

- Confirmed the existing `NonconformityRepository.find_by_id` behavior as the NCR id lookup behavior.
- Added focused tests for empty repositories, active records, missing ids, archived records, and restored records.
- No application code, JSON, SQLite, API, GUI, CLI, query engine, delete behavior, automatic history, or workflow behavior was changed in this step.

## Step 063

- Added a plan document for future NCR search and filtering behavior in `NonconformityRepository`.
- Outlined possible small steps for id lookup, status filtering, location filtering, text search, archive filtering, date range filtering, and responsible party filtering.
- No application code, tests, JSON, SQLite, API, GUI, CLI, query engine, or workflow behavior was changed in this step.

## Step 062

- Added a concise usage summary for NCR archive and listing behavior from Step 056-060.
- Documented `archive`, `restore`, `list_active`, `list_archived`, `list_all`, and `get_archive_summary` as the core repository usage flow.
- No application code, tests, JSON, SQLite, API, GUI, CLI, or workflow behavior was changed in this step.

## Step 061

- Added the final NotebookLM podcast note for Step 056-060.
- Summarized NCR archive summary, archived listing, active listing, full listing, and archive/listing consistency behavior for podcast production.
- No application code, tests, JSON, SQLite, API, GUI, CLI, or workflow behavior was changed in this step.

## Step 060

- Added an integrated consistency test for `NonconformityRepository` archive, restore, active listing, archived listing, full listing, and archive summary behavior.
- Confirmed that archive and restore keep the full record list intact and do not change `status` values automatically.
- No application code change, delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, or workflow was added in this step.

## Step 059

- Confirmed the existing `NonconformityRepository.list_all` behavior as the full NCR listing behavior.
- Added focused tests for empty repositories, active-only repositories, mixed active/archived records, and restore updates preserving the full record list.
- No delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, workflow, status change, or archive flag change was added in this step.

## Step 058

- Confirmed the existing `NonconformityRepository.list_active` behavior as the active NCR listing behavior.
- Added focused tests for empty repositories, active-only repositories, mixed active/archived records, and restore updates returning records to active listings.
- No delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, workflow, or status change was added in this step.

## Step 057

- Confirmed the existing `NonconformityRepository.list_archived` behavior as the archived NCR listing behavior.
- Added focused tests for empty repositories, active-only repositories, and restore updates removing records from archived listings.
- No delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, workflow, or status change was added in this step.

## Step 056

- Added `NonconformityRepository.get_archive_summary` for in-memory active, archived, and total NCR counts.
- Added tests for empty archive summaries, mixed active/archived record counts, and restore updates without changing totals.
- No delete behavior, JSON, SQLite, API, GUI, CLI, dashboard, automatic history, workflow, or status change was added in this step.

## Step 055

- Added `NonconformityRepository.restore` for in-memory restore by setting `is_archived=False`.
- Added tests proving restore returns the updated record, moves it from archived to active filters, preserves status and insert order, and returns `None` for missing ids.
- No model change, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, automatic archive, automatic closure, or automatic workflow was added in this step.

## Step 054

- Added `NonconformityRepository.archive` for in-memory archiving by setting `is_archived=True`.
- Added tests proving archiving returns the updated record, moves it from active to archived filters, preserves status and insert order, and returns `None` for missing ids.
- No model change, restore behavior, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, automatic closure, or automatic workflow was added in this step.

## Step 053

- Added `NonconformityRepository.list_active` and `NonconformityRepository.list_archived` for in-memory filtering by `is_archived`.
- Added tests proving active and archived records are returned separately, insert order is preserved, and missing archived records return an empty list.
- No model change, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, automatic archive, restore, or automatic workflow was added in this step.

## Step 052

- Added `is_archived: bool = False` to `NonconformityRecord` as a small archive marker field.
- Added tests proving the default archive state is `False` and records can be created with `is_archived=True`.
- No repository archive/restore behavior, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, or automatic workflow was added in this step.

## Step 051

- Added `NonconformityRepository.count` and `NonconformityRepository.count_by_status` for in-memory record counting.
- Added tests for total record counts, empty repository counts, status-specific counts, and missing status counts returning `0`.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, archive, or automatic workflow was added in this step.

## Step 050

- Added `NonconformityRepository.exists` for in-memory boolean presence checks by `nonconformity_id`.
- Added a test proving existing ids return `True`, missing ids return `False`, and existing repository data remains unchanged.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, archive, or automatic workflow was added in this step.

## Step 049

- Added `NonconformityRepository.update_responsible_party` for in-memory responsible party updates of existing NCR records.
- Added tests for updating an existing record, reflecting the new responsible party in filters and summaries, setting the responsible party to `None`, and returning `None` for a missing id.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, automatic workflow, or automatic assignment history record was added in this step.

## Step 048

- Added `NonconformityRepository.update_status` for in-memory status updates of existing NCR records.
- Added tests for updating an existing record, reflecting the new status in filters and summaries, and returning `None` for a missing id.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, automatic workflow, or automatic status history record was added in this step.

## Step 047

- Added `NonconformityRepository.get_overview_summary` for in-memory total, open, closed, assigned, and unassigned counts.
- Added tests for populated and empty overview summary results.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, or automatic workflow was added in this step.

## Step 046

- Added `NonconformityRepository.get_responsible_party_summary` for in-memory responsible party count summaries.
- Added tests for counting responsible parties, grouping missing responsible parties as `unassigned`, and returning an empty dict for an empty repository.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, or automatic workflow was added in this step.

## Step 045

- Added `NonconformityRepository.get_status_summary` for in-memory status count summaries.
- Added tests for counting multiple status values and returning an empty dict for an empty repository.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, or automatic workflow was added in this step.

## Step 044

- Added `NonconformityRepository.list_by_responsible_party` for in-memory responsible party filtering.
- Added a test proving records can be filtered separately for Ahmet and Mehmet, with missing responsible parties returning an empty list.
- No JSON, SQLite, API, GUI, CLI, file operation, dashboard, or automatic workflow was added in this step.

## Step 043

- Added `NonconformityRepository.list_by_status` for in-memory status filtering of `NonconformityRecord` records.
- Added a test proving open and closed records are filtered separately and missing statuses return an empty list.
- No JSON, SQLite, API, GUI, CLI, file operation, dashboard, or automatic workflow was added in this step.

## Step 042

- Added duplicate `nonconformity_id` protection to `NonconformityRepository.add`.
- Added a test proving duplicate ids raise `ValueError` while different ids can still be added.
- No JSON, SQLite, API, GUI, CLI, file operation, or automatic workflow was added in this step.

## Step 041

- Added `NonconformityRepository` as a small in-memory repository for `NonconformityRecord` records.
- Added tests for adding, listing, finding by id, and returning `None` for a missing nonconformity id.
- No JSON, SQLite, API, GUI, CLI, file operation, or automatic workflow was added in this step.

## Step 040

- Added `NonconformityClosureRecord` as the starting closure model for definite nonconformity / NCR records.
- Added a test for closure values and default final status, follow-up, follow-up note, and notes behavior.
- No API, GUI, database query, JSON record system, automatic closure, automatic approval, notification, or file operation was added in this step.

## Step 039

- Added `NonconformityCorrectiveActionVerificationRecord` as the starting verification model for NCR corrective action checks.
- Added a test for verification values and default rework, next action, status, and notes behavior.
- No API, GUI, database query, JSON record system, automatic closure, automatic approval, notification, or file operation was added in this step.

## Step 038

- Added `NonconformityCorrectiveActionRecord` as the starting corrective action model for definite nonconformity / NCR records.
- Added a test for corrective action values and default verification, status, completion date, and notes behavior.
- No API, GUI, database query, JSON record system, automatic closure, approval workflow, notification, or file operation was added in this step.

## Step 037

- Added `NonconformityAssignmentRecord` as the starting responsibility assignment model for definite nonconformity / NCR records.
- Added a test for assignment values and default `status` / `notes` behavior.
- No API, GUI, database query, JSON record system, automatic assignment, notification, approval workflow, or file operation was added in this step.

## Step 036

- Added `NonconformityStatusHistoryRecord` as the starting model for definite nonconformity / NCR status change history.
- Added tests for NCR status history values and optional field defaults.
- No database query, API, GUI, automatic status update, automatic NCR creation, corrective action system, approval workflow, JSON record system, or file operation was added in this step.

## Step 035

- Added `NonconformityProcessViewRecord` as the starting view model for definite nonconformity / NCR process summaries.
- Added tests for NCR process view values and optional field defaults.
- No database query, API, GUI, automatic NCR creation, automatic conversion, corrective action system, approval workflow, JSON record system, or file operation was added in this step.

## Step 034

- Revised the existing `NonconformityRecord` model with additional optional fields for type, detection actor, detection date, and final status.
- Updated the existing `NonconformityRecord` test to verify the new default values.
- Did not add `source_candidate_id` or `conversion_record_id`; candidate-to-NCR links remain represented by `NonconformityCandidateConversionRecord`.

## Step 033

- Added a decision preparation report evaluating the existing `NonconformityRecord` model after the candidate-to-NCR process chain.
- Documented existing fields, potentially missing fields, and the relationship with `NonconformityCandidateConversionRecord`.
- No model, test model, database query, API, GUI, JSON record system, automatic NCR creation, or corrective action system was added in this step.

## Step 032

- Added `NonconformityCandidateConversionRecord` as the starting conversion link model between candidate records and existing `NonconformityRecord` NCR records.
- Kept the existing `NonconformityRecord` model from Step 007 unchanged.
- No database query, API, GUI, automatic NCR creation, automatic conversion, corrective action system, approval workflow, JSON record system, or file operation was added in this step.

## Step 031

- Added final NotebookLM podcast notes for Steps 026-030.
- Summarized attachment evidence, process view, status history, assignment, and closure records as one nonconformity candidate tracking narrative.
- No new model, test model, database query, API, GUI, JSON record system, or file operation was added in this step.

## Step 030

- Added `NonconformityCandidateClosureRecord` as the starting closure and result model for nonconformity candidates.
- Added tests for closure values and optional field defaults.
- No database query, API, GUI, automatic closure, automatic status update, NCR creation, JSON record system, or file operation was added in this step.

## Step 029

- Added `NonconformityCandidateAssignmentRecord` as the starting responsibility and assignment model for nonconformity candidates.
- Added tests for assignment values and optional field defaults.
- No database query, API, GUI, automatic notification, automatic task assignment, JSON record system, or file operation was added in this step.

## Step 028

- Added `NonconformityCandidateStatusHistoryRecord` as the starting model for nonconformity candidate status change history.
- Added tests for status history values and optional field defaults.
- No database query, API, GUI, automatic reporting, JSON record system, or file operation was added in this step.

## Step 027

- Added `NonconformityCandidateProcessViewRecord` as the starting view model for nonconformity candidate process chains.
- Added tests for process view values and default empty-link state.
- No database query, API, GUI, automatic reporting, JSON record system, or file operation was added in this step.

## Step 026

- Documented the use of the existing `AttachmentRecord` model for nonconformity candidate evidence files.
- Added a test showing `AttachmentRecord.related_model` and `related_id` linking to `NonconformityCandidateRecord`.
- No new `NonconformityCandidateAttachment` model, database, API, GUI, JSON record system, or file operation was added in this step.

## Step 025

- Added `NonconformityCandidateTrackingSummaryRecord` model for Step 025.
- The model summarizes the current tracking status of nonconformity candidate processes at the data level.
- No database, API, GUI, JSON record system, file operation, final nonconformity management, corrective action system, or task tracking workflow was added in this step.

## Step 024

- Added `NonconformityCandidateActionRecord` model for Step 024.
- The model keeps simple action decisions for reviewed nonconformity candidates at the data level.
- No database, API, GUI, JSON record system, file operation, final nonconformity management, or corrective action system was added in this step.

## Step 023

- Added `NonconformityCandidateReviewRecord` model for Step 023.
- The model keeps nonconformity candidate review results at the data level.
- No database, API, GUI, JSON record system, or file operation was added in this step.

## Step 022

- Added `NonconformityCandidateRecord` model as the starting point for simple nonconformity candidate records.
- Added tests for nonconformity candidate values and default open status.
- Added documentation and learning material for the nonconformity candidate record model.

## Step 021

- Added `CheckResultRecord` model as the starting point for simple check result records.
- Added tests for check result values and default recorded status.
- Added documentation and learning material for the check result record model.

## Step 020

- Added `ChecklistItemRecord` model as the starting point for simple checklist item records.
- Added tests for checklist item record values and default pending status.
- Added documentation and learning material for the checklist item record model.

## Step 019

- Added `TaskCandidateRecord` model as the starting point for simple task candidate tracking.
- Added tests for task candidate values and default open status.
- Added documentation and learning material for the task candidate record model.

## Step 018

- Added `SiteNoteRecord` model as the starting point for simple site note tracking.
- Added tests for site note values and default open status.
- Added documentation and learning material for the revised site note record step.

## Step 017

- Added `SupplierRecord` model as the starting point for supplier and service provider tracking.
- Added tests for supplier values and default active status.
- Added documentation and learning material for the revised supplier record step.

## Step 016

- Added `EquipmentRecord` model as the starting point for equipment and machine tracking.
- Added tests for equipment values and default available status.
- Added documentation and learning material for the equipment record model.

## Step 015

- Added `WorkforceRecord` model as the starting point for crew and workforce tracking.
- Added tests for workforce values and default active status.
- Added documentation and learning material for the workforce record model.

## Step 014

- Added `SiteLocationRecord` model as the starting point for site location and work area tracking.
- Added tests for site location values and default active status.
- Added documentation and learning material for the site location record model.

## Step 013

- Added `ProjectPartyRecord` model as the starting point for project party tracking.
- Added `ContactPersonRecord` model as the starting point for contact person tracking.
- Added tests, documentation, and learning material for project party/contact records.

## Step 012

- Added `DailyReportRecord` model as the starting point for daily site report summaries.
- Added tests for daily report values and default draft status.
- Added documentation and learning material for the daily report summary model.

## Step 011

- Added `RFIRecord` model as the starting point for technical question tracking.
- Added `SubmittalRecord` model as the starting point for technical submission tracking.
- Added tests, documentation, and learning material for RFI/Submittal lite records.

## Step 010

- Added `MeetingRecord` model as the starting point for meeting minutes.
- Added `MeetingActionRecord` model as the starting point for meeting action tracking.
- Added tests, documentation, and learning material for meeting/action record models.

## Step 009

- Added `MaterialRecord` model as the starting point for material entry and usage tracking.
- Added tests for material record values and default status.
- Added documentation and learning material for the material record model.

## 008 Dosya/Ek Arsivleme Baslangici

- `AttachmentRecord` modeli eklendi.
- Dosya/ek arsiv referansi model testi eklendi.
- Adim 008 docs dosyasi olusturuldu.
- Adim 008 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## 007 Uygunsuzluk Kayitlari

- `NonconformityRecord` modeli eklendi.
- Uygunsuzluk kaydi model testi eklendi.
- Adim 007 docs dosyasi olusturuldu.
- Adim 007 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## 006 Yapi Denetim Kontrol Cagrilari

- `InspectionRequest` modeli eklendi.
- Yapi denetim kontrol cagrisi model testi eklendi.
- Adim 006 docs dosyasi olusturuldu.
- Adim 006 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## 005 Beton Dokum ve Numune Takip Baslangici

- `ConcretePour` modeli eklendi.
- `ConcreteSample` modeli eklendi.
- Beton dokum ve numune takip model testleri eklendi.
- Adim 005 docs dosyasi olusturuldu.
- Adim 005 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## Adim 004 Sonrasi Dokumantasyon ve Repo Sagligi Duzeltmesi

- README guncellendi.
- ROADMAP durumlari tutarli hale getirildi.
- `docs/project_decisions.md` Adim 002-004 ve learning kararlariyla genisletildi.
- `list_records_by_project` geriye uyumluluk karari dokumante edildi.
- CHANGELOG okunabilir sira ile duzenlendi.

## 001 Repo ve Calisma Anlasmalari Duzeltmesi

- Learning dosyasina mini sozluk eklendi.
- `learning/GLOSSARY.md` olusturuldu.
- Yeni teknik terimlerin tanimlanmasi proje kurali haline getirildi.

## 001 Tamamlayici Repo Duzeltmesi

- `ROADMAP.md` eklendi.
- `archive/` klasoru ve `.gitkeep` eklendi.
- Roadmap ve archive terimleri learning sozlugune eklendi.

## 002 Cekirdek Veri Modeli

- Cekirdek veri modelleri olusturuldu.
- Model testleri eklendi.
- Adim 002 dokumantasyonu olusturuldu.
- Learning dosyasi ve sozluk guncellendi.

## 003 Gunluk Saha Kaydi

- `DailySiteLog` modeli eklendi.
- Gunluk saha kaydi model testleri eklendi.
- Adim 003 dokumantasyonu olusturuldu.
- Learning dosyasi ve sozluk guncellendi.

## Learning Standardi

- Learning standardi olusturuldu.
- Learning dosyalarinin yazilim ogretme amaci netlestirildi.
- Yeni terimlerin tanimlanmasi ve `learning/GLOSSARY.md` guncellemesi guclendirildi.

## Learning Standardi Kod Bloklari Duzeltmesi

- Learning standardi kod bloklari uzerinden aciklama yapacak sekilde guclendirildi.
- Learning dosyalarinda test kodu aciklamasi zorunlu hale getirildi.
- Teknik karar tablosu ve kod calisma akisi bolumleri standarda eklendi.

## 004 Listeleme ve Filtreleme Fonksiyonlari

- `app/records.py` icinde basit listeleme ve filtreleme fonksiyonlari eklendi.
- `tests/test_records.py` icinde fonksiyon testleri eklendi.
- `learning/004_listeleme_filtreleme_fonksiyonlari.md` gercek kod bloklari uzerinden yazildi.

## 004 Hizalama Duzeltmesi

- Adim 004 fonksiyon isimleri standartlastirildi.
- `filter_records_by_project_id`, `list_records`, `count_records` ve `filter_records_by_status` yapisi netlestirildi.
- Learning dosyasi yeni kod bloklu standarda gore hizalandi.

## 001-003 Learning Standardi Genisletmesi

- Adim 001, 002 ve 003 learning dosyalari yeni kod bloklu CSE Learning Standardi'na gore genisletildi.
- Eski kisa learning notlari detayli yazilim ogretim dosyalarina donusturuldu.
- `learning/GLOSSARY.md` eksik terimlerle guclendirildi.
