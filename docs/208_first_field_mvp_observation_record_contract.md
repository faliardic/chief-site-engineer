# Step 208 - First Field MVP Observation Record Contract

## Amac

Bu belge, ilk Field MVP icin gelecekte eklenecek `FieldObservationRecord` modelinin dokumantasyon seviyesindeki veri sozlesmesini tanimlar.

Bu adimda model implementasyonu, hard validation, persistence, repository, API, GUI, CLI, migration, audit, backup/restore veya dosya yazma davranisi eklenmez. Belge yalniz gelecekteki dar implementasyon adimi icin review edilebilir contract uretir.

## Product Fit

`FieldObservationRecord`, santiyede 20-30 saniyede ilk resmi saha gozlem kaydini acmayi hedefler.

Kayit su isleri kolaylastirmalidir:

- sahada hizli resmi gozlem yakalamak;
- gozlemi proje, zaman, konum, kategori ve kisa aciklama ile baglamak;
- attachment ve bildirim bilgisini ilk kayit icin zorunlu yapmadan sonradan eklemeye izin vermek;
- `open`, `tracking`, `closed` yasam dongusunu basit tutmak;
- ileride gunluk export ve haftalik ozetin tuketebilecegi temiz veri uretmek.

Bu record resmi/proje kaydidir; Santiye Sefi Ozel Alani kaydi degildir.

## Future Model Name

```text
FieldObservationRecord
```

## Recommended Required Fields

| Field | Required at initial capture | Meaning | V1 contract note |
| --- | --- | --- | --- |
| `observation_id` | Yes | Observation record identity | Future implementation should keep this stable for attachment/report links. |
| `project_id` | Yes | Related project identity | Relates to `SiteProject.project_id`. |
| `observed_at` | Yes | Observation date/time | Capture time or user-entered observation time. |
| `location` | Yes | Fast field location snapshot | V1 text/snapshot; structured normalization is deferred. |
| `category` | Yes | Observation category | Short human-readable category such as quality, safety, progress, coordination, material, or other. |
| `description` | Yes | Short field description | Should be fast to type and enough for later recall. |

## Status Contract

Recommended future field:

```text
status
```

Default:

```text
open
```

First vocabulary:

| Status | Meaning |
| --- | --- |
| `open` | Observation has been captured and still needs attention or later review. |
| `tracking` | Observation is being followed, reported, or watched until resolution. |
| `closed` | Observation lifecycle is complete. This is not physical deletion. |

`closed` and archive must remain separate. A closed observation can still be visible, reportable, and auditable in future implementations. Archive is a separate visibility/retention concern.

## Optional / Deferred-At-Capture Fields

| Field | Required at initial capture | Meaning |
| --- | --- | --- |
| `reported_to` | No | Fast text/snapshot of person or group informed. |
| `reported_at` | No | Date/time when the observation was reported. |
| `created_by` | No | User/person who created the record. |
| `closed_at` | No | Date/time when lifecycle moved to `closed`. |
| `notes` | No | Additional non-private official notes about the observation. |
| `is_archived` | No | Separate archive flag for future visibility/retention behavior. |

These fields are optional because the first capture must stay fast. A site engineer should be able to record the observation first and enrich it later.

## Relationship Boundaries

| Relationship | Step 208 contract |
| --- | --- |
| `project_id` -> `SiteProject` | `project_id` relates to `SiteProject.project_id`. |
| `location` -> `SiteLocationRecord` | `location` is a V1 fast-capture text/snapshot field. Future structured normalization may use `SiteLocationRecord` in a separate step. |
| `reported_to` -> `ContactPersonRecord` | `reported_to` is a V1 fast-capture text/snapshot field. Future identity/contact normalization may use `ContactPersonRecord` in a separate step. |
| Attachments -> `FileAttachmentRecord` | Attachments remain separate rows with `related_record_type = "field_observation"` and `related_record_id = observation_id`. |
| Daily export / weekly summary | Later consumers may read observation records. No export or summary behavior is implemented here. |

The observation record must not embed attachment lists, binary data, or copied file content.

## Behavioral Boundaries

Future implementation must preserve these boundaries unless a later authorized step changes the contract:

- Initial record creation must not require an attachment.
- Initial record creation must not require `reported_to`.
- Adding an attachment may occur after initial capture.
- Reporting to a person may occur after initial capture.
- `closed` is a lifecycle state, not physical deletion.
- Archive is separate from closed.
- No automatic `blocked` status is generated.
- No automatic acceptance, rejection, official decision, task creation, NCR conversion, or audit event is generated.
- Private notes are not silently copied into this official record.
- Future conversion from a private note requires explicit user action.
- No hard validation, persistence, repository, API, GUI, CLI, migration, audit, backup/restore, or file-writing behavior is added in Step 208.

## Existing-Model Mapping And Gap Analysis

| Existing concept | Reuse / relationship | Future gap |
| --- | --- | --- |
| `SiteProject` | `FieldObservationRecord.project_id` should relate to `SiteProject.project_id`. | No implemented observation model yet. No repository relation or lookup is added in this step. |
| `SiteLocationRecord` | Can later normalize `location` into structured block/floor/zone/axis/discipline data. | V1 contract keeps `location` as fast text/snapshot to avoid slowing capture. |
| `ContactPersonRecord` | Can later normalize `reported_to` into a real contact/person relationship. | V1 contract keeps `reported_to` optional text/snapshot. |
| `SiteNoteRecord` | Similar simple note shape exists, but it is not the official observation contract. | Need separate `FieldObservationRecord` because observations require project/time/location/category/status/reporting boundaries. |
| `TrackingRecord` | Existing `status = "open"` idea and responsible-party tracking concept are relevant. | Tracking records are not the fast observation model and should not be overloaded silently. |
| `FileAttachmentRecord` | Attachment metadata can link using `related_record_type = "field_observation"` and `related_record_id = observation_id`. | No attachment list, binary data, file copying, or upload flow is added here. |
| `DailySiteLog` | Future daily logs may consume observations for daily reporting. | No daily export or aggregation is implemented in Step 208. |
| `DailyReportRecord` | Future report summaries may use observation data for issue/safety/work summaries. | No weekly summary, report generation, or exporter is implemented in Step 208. |

## Recommended Step 209

Step 209 is the recommended implementation step only after this contract is reviewed and merged.

Recommended Step 209 scope:

- add a minimal `FieldObservationRecord` dataclass;
- keep constructor behavior simple and consistent with existing model style;
- add focused tests for defaults and value holding;
- keep attachment, persistence, API, GUI, CLI, export, audit, and hard validation outside Step 209 unless explicitly authorized.

Step 208 does not start Step 209.

## Non-Implementation Confirmation

This step is documentation/state/contract only.

It does not add:

- production code;
- executable tests or fixtures;
- workflow changes;
- persistence/database/repository behavior;
- hard validation;
- generated `blocked`;
- automatic task/NCR/audit/decision behavior;
- API, GUI, or CLI;
- export output;
- file upload, copy, move, delete, or ZIP mutation.
