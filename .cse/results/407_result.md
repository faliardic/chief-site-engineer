# Issue #407 — Canonical Sicil/Puantaj identity and migration preflight result

## Verdict

The repository already has the canonical identity required by the V2.2 closure
gate: one `workforce_members.id` is the Sicil person identity and
`attendance_entries.workforce_member_id` points directly to it. There is no
parallel Puantaj person/name identity to migrate or merge.

Schema 12 is nevertheless required for the first production child, but only as
an additive profile-schema change. The current schema cannot store all V2.2
firm/person fields (firm address, specialty, start/end dates; person address and
start date). Schema 12 must not replace, regenerate, or merge any existing
identity. No data backfill is required for the new optional fields.

There is no repository evidence that real user rows are duplicates. User data
was not inspected. Because `workforce_members` permits the same real person to
be entered under different IDs when `personnel_code` is null or different, a
duplicate is possible, but no fuzzy/heuristic merge is safe or authorized.

## Authority and inspection boundary

- Issue: `#407`
- Parent V2.2: `#204`, especially
  `#issuecomment-5226951643` and `#issuecomment-5230801536`
- Parent epic: `#385`
- Product sources: `docs/v2/CSE_V2_SCOPE.md` and `ROADMAP.md`
- Base: `dcf25ba29aa4443785cabd5f8bdd29d825008759`
- Branch: `codex/issue-407-v2-2a-identity-migration-preflight`
- Validation class: domain/data identity + migration preflight
- Production source changes: none
- Real user data roots, backup/report areas and original dirty worktree contents:
  not inspected or mutated

## Current repository map

| Concern | Current source of truth | Stable/link key | Lifecycle/history behavior |
| --- | --- | --- | --- |
| Project | `projects` | `projects.id` | Parent of the whole registry |
| Subcontractor/company | `subcontractors` | `subcontractors.id` | Project-scoped active/archive record; revision + `workforce_events` |
| Team | `workforce_teams` | `workforce_teams.id` | Belongs to one subcontractor and project; revision + events |
| Sicil person | `workforce_members` | `workforce_members.id` | Belongs to project/subcontractor/team; active/archive, revision + events |
| Puantaj day | `attendance_days` | `attendance_days.id` | Project/date aggregate; revision + append-only events |
| Puantaj person row | `attendance_entries` | `workforce_member_id` | Direct FK to the Sicil person ID; no copied person identity |
| SGK/İSG/compliance | `workforce_compliance_records` | `workforce_member_id` | Direct FK to the same person; archived rows retained |
| KKD | `workforce_ppe_assignments` | `workforce_member_id` | Direct FK to the same person; lifecycle retained |
| Workforce audit | `workforce_events` | aggregate type + aggregate ID | Append-only subcontractor/team/person/compliance/PPE events |
| Attachments | `concrete_attachments`, `agenda_log_attachments` | Module-specific owner IDs | No Sicil/compliance/KKD attachment relation exists yet |

Canonical graph:

```text
projects.id
  └─ subcontractors.id
       └─ workforce_teams.id
            └─ workforce_members.id  ← canonical Sicil person identity
                 ├─ attendance_entries.workforce_member_id
                 ├─ workforce_compliance_records.workforce_member_id
                 └─ workforce_ppe_assignments.workforce_member_id
```

The composite project/registry constraints and application validation prevent a
member from being assigned across projects. Attendance days are project-scoped;
roster writes validate that every selected member belongs to that same project.

## Existing identity and lifecycle evidence

### Schema

- Schema version is 11.
- `workforce_members.id` is the person primary key. The `(id, project_id)` key,
  project FK, registry-required triggers and same-project validation preserve the
  hierarchy.
- `attendance_entries` stores `workforce_member_id` as a non-null FK and has a
  unique `(attendance_day_id, workforce_member_id)` constraint.
- Compliance and PPE records both store the same non-null person FK.
- Physical-delete guards protect workforce, attendance and event history.
- Active/archive records retain IDs and use revision/timestamp/event state.

### Application

- `SqliteAttendanceApplication.createMember` creates the canonical Sicil ID.
- `saveRoster` accepts member IDs, validates project ownership, rejects a new
  entry for an inactive member and retains existing entry/person links.
- `markFullDay` draws only from the active member list.
- Person, team and subcontractor updates preserve their IDs and append events.
- Restore is fail-closed until the parent subcontractor and team are active.
- Historical day reads join attendance entries to the current Sicil row without
  filtering inactive members. An archived person therefore stays visible in an
  existing day while being excluded from new active rosters.
- Current names/team/company labels are live read-model values. Attendance does
  not store historical label snapshots; renaming a Sicil row changes the label
  shown for old days without rewriting the stable link.

### UI

- The current first-level destination is `Puantaj`; Sicil is nested under
  `Puantaj → İş gücü → Taşeronlar ve ekipler/person detail`.
- Active/inactive member filtering, create/edit, archive/restore, registry
  management and person detail already exist.
- Person detail exposes `Genel / Puantaj`, `İSG belgeleri` and `KKD zimmetleri`,
  but the first tab currently explains the stable-link contract rather than
  presenting the requested attendance aggregates/history.
- There is no first-level `Sicil`/`Taşeronlar`/`Saha Rehberi` destination and no
  cross-field field-guide search/filter surface yet.
- Puantaj currently opens a roster from active people; the requested
  subcontractor-first selection and inline `+ Yeni eleman` flow are not present.

## Existing migration evidence

Schema 5→6 already performs the only legacy identity adoption found in the
repository:

1. It groups legacy `workforce_members.team_name` values within a project using
   deterministic normalized exact values.
2. It creates stable subcontractor/team IDs for those groups.
3. It fills each existing member's registry FKs without changing the member ID.
4. Existing `attendance_entries.workforce_member_id`, day state, overtime and
   attendance events therefore remain untouched.
5. The migration is atomic; the existing database test proves rollback to
   schema 5 on an intentional failure and exact successful preservation on the
   next open.

This migration does not deduplicate people and must not be repeated in schema
12. Its exact-normalized team grouping is historical compatibility evidence,
not permission for fuzzy person matching.

## Migration classification

| V2.2 requirement | Classification | Decision |
| --- | --- | --- |
| Sicil and Puantaj use one person ID | No migration | Already true through `workforce_members.id` and the attendance FK |
| Preserve existing person/Puantaj/İSG/SGK/KKD links | No identity rewrite | Keep every current primary/foreign key byte-for-byte |
| Firm address, specialty, start/end dates | Schema migration | Add nullable columns to `subcontractors` in schema 12 |
| Person address and start date | Schema migration | Add nullable columns to `workforce_members` in schema 12 |
| Existing rows for new profile fields | No data backfill | `NULL` means not recorded; do not invent values |
| First-level Sicil/Saha Rehberi, search and filters | Read-model/UI adoption | Use existing stable IDs; no new identity table |
| Person attendance summary/history | Read-model/UI adoption | Query existing attendance FK graph; no copied ledger |
| Subcontractor-first roster and `+ Yeni eleman` | Application/UI adoption | Create/select the same canonical member ID |
| Duplicate real-person cleanup | Explicitly deferred/unsafe | No fuzzy match, auto-merge or silent ID replacement |
| Compliance/KKD file attachments | V2.3 boundary | Do not add a one-off attachment design in V2.2 |
| Future Ajanda/Work person links | Future module adoption | Add explicit FKs when those contracts are scoped; reuse the member ID |

## Why schema 12 is required, and what it must not do

The parent #204 acceptance requires fields not present in schema 11:

- subcontractor address;
- subcontractor work item/specialty;
- subcontractor start and optional end date;
- person address;
- person employment/start date.

The current compliance model already represents SGK employment-entry status,
date and optional document number through the `employment_entry` document type;
a second SGK identity or ledger is unnecessary. Existing phone, role, note,
archive state, compliance and PPE fields should be reused.

Schema 12 must therefore be additive and nullable. It must not:

- introduce a second person/contact primary key for Puantaj;
- split or rewrite existing `full_name` values as a migration prerequisite;
- regenerate subcontractor, team or member IDs;
- relink attendance, compliance or PPE rows;
- infer profile dates/addresses from notes;
- normalize or merge people by name, phone or approximate similarity;
- add attachment tables before the V2.3 common attachment contract.

## Canonical identity contract for production children

1. `workforce_members.id` remains the canonical, immutable, project-scoped
   person identity for Sicil, Puantaj, compliance and PPE.
2. A member always belongs to exactly one project, one subcontractor and one
   team at a time. Moves update the registry relation and append an event; they
   never create a replacement person ID.
3. `attendance_entries.workforce_member_id` remains the only attendance-person
   source of truth. Display labels are resolved from Sicil.
4. New Puantaj selections accept active, same-project members only. Existing
   historical entries remain readable after person/team/company archive.
5. Restore follows parent-first order: subcontractor, team, then member.
6. Compliance and PPE retain their current person FKs and histories.
7. Future module adoption must store an explicit stable FK; it must not copy a
   name and later attempt fuzzy matching.
8. Duplicate prevention may use exact, user-visible identifiers (for example an
   existing non-null personnel code) as a validation/warning, but must not merge
   two established IDs automatically.

## Backward compatibility and backup

- Schema 11 databases upgrade atomically to schema 12 by adding nullable
  columns; old rows stay valid without a value backfill.
- Fresh installs create the same final constraints as upgrades.
- Existing schema 5→6 identity adoption remains the sole legacy registry
  mapping; schema 12 must not rerun or reinterpret it.
- Backup format remains 1. The backup is a SQLite snapshot plus manifest and
  already includes registry, member, compliance, PPE, workforce-event,
  attendance-day/entry/event tables. The restore path accepts an older schema
  and migrates it to the active schema.
- A backup-format bump is not justified by additive database columns. Focused
  backup tests must prove schema 11 backup → schema 12 restore and schema 12
  round-trip while keeping IDs/FKs and archive state.
- Attachments remain unchanged; no existing attachment link is rewritten.

## Risk matrix

| Risk | Impact | Evidence/condition | Required control |
| --- | --- | --- | --- |
| Creating a new global person table and copying rows | Critical: duplicate identities and relink loss | Existing canonical member FK graph already satisfies the core gate | Do not introduce or populate a replacement identity table |
| Fuzzy person deduplication | Critical: two people can be merged, or history assigned incorrectly | Name/phone are not safe unique identifiers; real data was not inspected | Never auto-merge; require an explicitly scoped, user-reviewed workflow if ever needed |
| Regenerating member IDs during schema 12 | Critical: Puantaj/compliance/PPE links break | Three dependent tables use the member PK | Preserve all PK/FK values exactly; assert them in migration tests |
| Archiving a parent with active children | High: hidden active people or inconsistent selection | Current application blocks this transition | Keep fail-closed behavior or add an explicitly accepted transactional cascade; no silent cascade |
| Filtering inactive members from historical joins | High: past Puantaj disappears | Current historical query intentionally has no active filter | Regression-test archived member remains in old day and cannot be added to a new one |
| Assuming label snapshots exist | Medium: historical display semantics misunderstood | Old days resolve current Sicil labels | Document live-label semantics; do not add snapshots without a separate contract |
| Adding required non-null profile columns | High: upgrade failure or invented backfill | Existing rows have no reliable source values | Add nullable columns and user-entered updates only |
| One-off workforce attachment tables | High: conflicts with V2.3 common attachment graph | No workforce attachment relation exists; V2.3 owns it | Defer file-link implementation, keep document metadata only |
| Backup manifest/format bump | Medium: unnecessary compatibility break | Format 1 already carries the SQLite schema and migrates older snapshots | Keep format 1; add focused migration/round-trip evidence |
| Broad all-person roster | Medium: crowding/repeated-name selection errors | Parent requires subcontractor-first choice | Later UI child filters by project → subcontractor → active member ID |

## Proposed V2.2 child sequence

1. **V2.2b — additive registry profile schema and canonical application
   contract.** Add schema 12 optional profile fields, preserve all IDs/links,
   expose application/domain values, and prove migration/restart/backup behavior.
   No navigation or attachment work.
2. **V2.2c — first-level Sicil/Saha Rehberi.** Add the main destination,
   firm/team/person hierarchy, search/filters, archive bin and profile editing on
   the existing IDs. Add person Puantaj read-model summary/history. No new
   identity schema.
3. **V2.2d — Puantaj selection adoption.** Add subcontractor-first active-person
   selection, inline `+ Yeni eleman`, same-project validation and useful card
   summaries while retaining historical inactive rows.
4. **V2.2e — end-to-end closure.** Focused backup/restart, archive/restore,
   field-guide and Puantaj acceptance plus authorized device/release gates.
   Attachment binaries/viewer/reminders remain V2.3 unless separately scoped.

This sequence can be split further by the child issue owner, but identity/schema
work must land before UI adoption and no child may create a parallel person list.

## Exact first production child boundary (V2.2b)

### Authorized production/test allowlist

- `mobile/lib/storage/app_database.dart`
- `mobile/lib/domain/attendance_models.dart`
- `mobile/lib/application/attendance_application.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/attendance_application_test.dart`
- `mobile/test/mobile_backup_application_test.dart`
- `.cse/tasks/<v2.2b_issue>_task.md`
- `.cse/results/<v2.2b_issue>_result.md`
- `docs/project_decisions.md`
- one focused V2.2 Sicil/Puantaj learning document, only if the child issue
  explicitly names it

### Exact production changes

- bump mobile schema 11→12;
- add nullable firm `address`, `specialty`, `started_on`, `ended_on` fields;
- add nullable member `address`, `started_on` fields;
- expose those fields in domain commands/models and application CRUD;
- retain current SGK/compliance/PPE structures and stable IDs;
- leave backup format at 1.

### Required focused tests

- schema 11→12 upgrade preserves every subcontractor/team/member PK and all
  attendance/compliance/PPE FKs, events, archive state and revisions;
- intentional schema 12 failure rolls back to intact schema 11;
- fresh schema and upgraded schema have equivalent columns/constraints;
- nullable new fields keep legacy rows readable; CRUD/restart retains entered
  values without rewriting unrelated rows;
- existing member ID is the ID used by a new attendance entry;
- member update/registry move keeps existing attendance links;
- archived member remains in an existing Puantaj day and is rejected for a new
  roster entry; restore makes it selectable only after active parents;
- schema 11 backup restores/migrates on schema 12 and schema 12 format-1
  round-trip retains new fields plus all IDs/FKs.

### Explicitly out of scope for V2.2b

- first-level navigation, Saha Rehberi UI, search/filter and forms;
- Puantaj selector redesign and inline new-person UI;
- person duplicate merge or real-data cleanup;
- attendance label snapshots;
- compliance/KKD attachment files or linked reminders;
- Ajanda/Work identity adoption;
- backup-format bump or release/device acceptance.

### Stop conditions

Stop without publication if implementation requires any identity replacement,
automatic duplicate merge, real-data inspection, non-null invented backfill,
attachment redesign, or a path outside the child allowlist. A newly discovered
production-data ambiguity must be recorded as a separate user-reviewed decision;
it must not be resolved heuristically inside migration code.

## Preflight validation evidence

Read-only inspection covered:

- schema tables, columns, FKs, unique constraints, indexes, triggers and
  migrations in `mobile/lib/storage/app_database.dart`;
- identity/lifecycle commands and read models in
  `mobile/lib/application/attendance_application.dart`;
- domain models in `mobile/lib/domain/attendance_models.dart`;
- current Sicil/Puantaj UI routes and person detail surfaces under
  `mobile/lib/features/attendance/`;
- focused database, attendance application and widget tests;
- backup format/table inventory in
  `mobile/lib/application/mobile_backup_application.dart` and its focused tests.

Existing executable evidence includes the schema 5→6 atomic migration test,
registry archive/restore and stale/no-op tests, person-linked compliance/KKD
tests, stable-member roster tests, physical-delete guards, restart persistence
and narrow widget navigation/layout tests. No new production behavior was added,
so full Flutter tests, analyze, APK build, release/static gates and device smoke
are not applicable to this evidence-only issue.
