# CSE Inventory Map v1 Canonical Contract

- **Belge türü:** Normative product, UX and persistence contract
- **Owner authority:** [Feature Epic #506](https://github.com/faliardic/chief-site-engineer/issues/506), [Issue #507](https://github.com/faliardic/chief-site-engineer/issues/507), revised spatial foundation [Issue #527](https://github.com/faliardic/chief-site-engineer/issues/527), floor navigation [Issue #531](https://github.com/faliardic/chief-site-engineer/issues/531), block lifecycle [Issue #533](https://github.com/faliardic/chief-site-engineer/issues/533), and integrated closure [Issue #535](https://github.com/faliardic/chief-site-engineer/issues/535)
- **Contract version:** `1.4`
- **Contract status:** Slices 1–5 and revised Slices 6.1–6.3 are merged; Slice 6.4 Phase A integrated automation is PASS while owner acceptance remains `PENDING / NOT RUN`
- **Task-start baseline:** `baa7beff186e3fee95f1fb439d92045d7ba1af4e`
- **Current persisted facts:** SQLite schema `22`, backup format `1`, mobile version `0.1.0+1`, MAIN package `com.faliardic.sefim`

## 1. Normative language and product boundary

`MUST`, `MUST NOT`, `SHOULD` and `SHOULD NOT` are normative. Turkish UI copy
is normative where it is shown in backticks. This document fixes the product
decisions required for Slices 1–7. Merged implementation, automated closure,
owner acceptance and final backup/restore closure remain separate states.

Inventory Map v1 is the local-first spatial record of durable site assets. It
MUST let the owner draw a schematic site sketch, place durable assets on that
sketch and manage the same records through map, list and append-only history.
The drawing MUST be called a `şematik kroki` in user-visible copy. It MUST NOT be
presented as surveyed, scaled, contractual, CAD or real-world-coordinate truth.

V1 MUST include:

- direct top-level `Envanter` access;
- one active schematic sketch in the v1 UI, with a persistence model that can
  represent multiple sketches later;
- durable draft recovery and immutable finalized sketch revisions;
- durable asset/lot records with category, positive integer quantity, status,
  optional note and optional photo boundary;
- history-preserving placement, move, status and archive behavior;
- two projections, `Kroki` and `Liste`, over the same canonical records;
- offline persistence and format-1 backup/restore adoption.

V1 MUST NOT implement:

- consumable-stock or material movement ledger;
- procurement/ERP behavior;
- QR generation or scanning;
- count mode;
- maintenance or calibration automation;
- full assignment/zimmet workflow;
- PDF or DWG backgrounds;
- scale, area, measured distance or real-world coordinates;
- AI or automatic placement;
- multi-user, roles, tenants or shared editing.

The schema MAY reserve only the explicit extension points in this contract. It
MUST NOT introduce a generic workflow, GIS, CAD, stock or assignment framework.

## 2. Product destination and project binding

### 2.1 Bounded six-destination shell

`Envanter` MUST be a direct `NavigationBar` destination. It MUST NOT be only a
Home card or a child of another product module.

Slice 4 MUST retain six shell destinations in this exact order:

1. `Başlangıç`
2. `Hatırlatıcı`
3. `Ajanda`
4. `Envanter`
5. `Puantaj`
6. `Daha`

`Daha` MUST be a bounded route hub containing the existing `Beton Paketi` and
`Sicil` entry points. Their content and data contracts MUST remain unchanged;
only one extra navigation tap is introduced. No drawer, configurable navigation,
seventh bottom item or broad shell redesign is part of v1.

The Home quick-entry cards MAY remain, but they MUST NOT replace the direct
`Envanter` destination.

### 2.2 Exact active-project isolation

Inventory MUST operate under one explicit active `project_id` at a time.

- The project list MUST contain only non-archived canonical `projects` rows.
- If exactly one active project exists, Envanter SHOULD select it.
- If more than one active project exists, no project MUST be inferred; the
  owner MUST select one before any Inventory read or mutation.
- If no active project exists, the page MUST show a safe project-required
  empty state and MUST NOT create an Inventory row.
- The selected project is route-local UI state. It MUST NOT be persisted as a
  new global preference in v1 and MUST NOT be copied from another module by
  name matching.
- Project switching MUST clear map/list selection, search focus, cached sketch,
  marker focus and pending quick-capture coordinates before loading the new
  exact ID.
- Every application command MUST carry `project_id`; every related table MUST
  carry `project_id`; SQLite and application validation MUST reject cross-project
  sketch, revision, asset, placement and photo relations.
- A project archived while Envanter is open MUST make subsequent mutation fail
  with `inventory_project_unavailable`. The UI MUST reload; it MUST NOT silently
  switch to another project.

### 2.3 Empty and normal view states

For an active project with no non-archived primary sketch, the exact primary
copy MUST be `Bu projede henüz şematik kroki yok.` and the primary action MUST
be `Kroki ekle`.

Normal Inventory viewing MUST remain portrait-capable. Only the drawing editor
route is landscape-scoped. `Kroki` and `Liste` MUST be sibling projections in
the same Envanter destination and MUST share the same selected project,
filters and canonical asset/placement query result.

## 3. Virtual geometry contract

### 3.1 Coordinate space

Geometry version `1` MUST use these exact constants:

| Property | Value |
| --- | ---: |
| Virtual canvas width | `4096` |
| Virtual canvas height | `3072` |
| Aspect ratio | `4:3` |
| Coordinate type | signed integer stored only after range validation |
| Valid x range | `0..4096`, inclusive |
| Valid y range | `0..3072`, inclusive |
| Sketch-vertex grid step | `64` virtual units |
| Placement quantization | `4` virtual units |
| Geometry version | `1` |

Screen pixels, device pixel ratio, physical size and zoom MUST NOT be stored as
source geometry.

A pointer position MUST first be inverse-transformed from the current viewport
into virtual coordinates. A raw position outside the inclusive canvas MUST be
ignored. An in-bounds sketch vertex MUST then snap to the nearest multiple of
`64`; an in-bounds placement MUST snap to the nearest multiple of `4`. An exact
half-step tie MUST choose the lower multiple; the inclusive edge is a valid
snapped result. Persisted coordinates outside the inclusive bounds or not
divisible by their required step MUST be rejected; a reader MUST NOT repair
them by clamping.

The dotted grid MUST render the `65 x 49` points from `(0,0)` through
`(4096,3072)` at step `64`.

### 3.2 Canonical representation and fingerprint

Each `inventory_sketch_revisions.geometry_json` value MUST be one canonical
UTF-8 JSON document with this exact shape and key order:

```json
{"canvas_height":3072,"canvas_width":4096,"geometry_version":1,"polylines":[{"closed":false,"points":[[0,0],[64,64]]}]}
```

Canonical encoding MUST use:

- no insignificant whitespace;
- the fixed top-level and polyline key order shown above;
- decimal integers without a plus sign or leading zeroes, except `0`;
- lowercase JSON booleans;
- polyline array order as user-created/current editor order;
- point array order as traversal order within each polyline;
- no sorting or deduplication that changes drawing order.

`geometry_sha256` MUST be the lowercase 64-character SHA-256 hex digest of the
exact canonical UTF-8 bytes. The application MUST recompute and compare it on
every draft load, finalize and active-revision read.

Canonical JSON is selected instead of mutable normalized child rows because
the editor saves one bounded geometry document atomically, optimistic draft
autosave becomes a single guarded row update, finalized bytes become immutable,
SQLite backup includes the whole revision without a partial child-row state,
and `geometry_version` provides an explicit future evolution boundary. No v1
query requires SQL-level segment or point lookup.

### 3.3 Valid polylines and limits

V1 MUST allow open and closed polylines.

- An open finalized polyline MUST contain at least `2` points.
- A closed finalized polyline MUST contain at least `3` distinct points.
- Closure MUST be represented only by `closed: true`; the first point MUST NOT
  be repeated as the final point.
- Consecutive duplicate points and zero-length segments MUST be rejected.
- A closed polyline whose final point equals its first point MUST be rejected.
- Preserved schema20/general sketch geometry MAY contain non-consecutive
  repeated points, shared endpoints, crossings or self-intersections because
  those historical bytes remain schematic and immutable. A polyline linked as
  a schema21 block boundary is subject to the stricter section 4.5 contract.
- A draft MAY contain zero polylines or one incomplete one-point polyline.
- Finalization MUST require at least one valid polyline and at least one
  non-zero-length segment.

One revision MUST satisfy all exact safety limits:

| Limit | Maximum |
| --- | ---: |
| Polylines | `64` |
| Points in one polyline | `1024` |
| Total points | `4096` |
| Total segments | `4096` |

An open polyline contributes `point_count - 1` segments; a closed polyline
contributes `point_count`. An edit that would exceed a limit MUST be rejected
before persistent mutation and MUST leave the last valid draft intact.

### 3.4 Fail-closed read behavior and revision compatibility

Invalid JSON, wrong key/type, unknown geometry version, wrong canvas constants,
out-of-bounds or unsnapped point, limit violation, zero-length segment or
checksum mismatch MUST produce `inventory_geometry_corrupt`. A missing pointed
revision MUST produce `inventory_geometry_unavailable`.

The map MUST NOT render partial geometry or silently bind to another revision.
The same-project `Liste` projection MAY remain available because asset metadata
is independent, but create/move/finalize actions that depend on the map MUST be
disabled until the exact revision is valid.

All revisions of one sketch MUST retain geometry version `1`, canvas
`4096 x 3072` and the same coordinate interpretation. A revision with different
geometry constants MUST be rejected. A future incompatible geometry version
MUST use a new sketch identity and an explicit migration/product decision; it
MUST NOT reinterpret existing placement coordinates.

Pan, zoom, viewport center, marker expansion and selection are presentation
state only and MUST NOT be persisted as source geometry. Reopen MUST initially
fit the full canvas, unless a list-to-map focus action explicitly centers a
selected placement for that session.

## 4. Sketch identity and lifecycle

### 4.1 Identity model

`inventory_sketches.id` is the stable sketch identity.
`inventory_sketch_revisions.id` is one version identity. Revision numbers MUST
be monotonic per sketch and MUST never be reused, including after abandonment.

The schema supports multiple sketches per project. V1 UI MUST expose at most
one non-archived `is_primary = 1` sketch. A partial unique index MUST enforce
that primary selection. Additional non-primary rows are a bounded extension
point and MUST NOT be surfaced by v1.

### 4.2 Exact revision states

`inventory_sketch_revisions.state` MUST be one of:

- `DRAFT`: mutable only through expected-content-revision autosave;
- `ACTIVE`: finalized and immutable; pointed to by the sketch;
- `SUPERSEDED`: previously active, immutable and historical;
- `ABANDONED`: never active or explicitly discarded draft, immutable.

Allowed transitions are exact:

```text
new DRAFT -> ACTIVE
new DRAFT -> ABANDONED
ACTIVE -> SUPERSEDED only while its successor DRAFT -> ACTIVE
```

No other transition is allowed. A finalized revision MUST never return to
`DRAFT`. A sketch or revision MUST never be physically deleted.

### 4.3 Create, autosave, recover and finalize

`Kroki ekle` MUST atomically create a primary sketch plus revision-number `1`
in `DRAFT` state, with canonical empty geometry. If a primary sketch already
exists, the command MUST fail with `inventory_primary_sketch_exists`.

Draft edits MUST autosave after `500 ms` without a new geometry command. The
editor MUST also force an awaited save on:

- route back/pop;
- `Oluştur`;
- application `inactive`, `paused` or `detached` lifecycle notification;
- editor error handling before it leaves the route.

Except for the immutable-mapping successor case defined in section 8.7, each
real autosave MUST compare expected `content_revision`, replace only the draft's
canonical JSON/checksum, increment `content_revision` and sketch `revision` by
exactly one, and append `inventory.sketch_draft_autosaved` in the same
transaction. Identical geometry and spatial metadata MUST create an
idempotent/no-op receipt without revision or event.

After relaunch, a sketch `draft_revision_id` MUST reopen the exact last durable
draft and identify whether it is a first sketch or an edit of an active base.
Undo/redo history is session-only and MUST start empty after recovery; durable
geometry MUST not be lost merely because the in-memory undo stack is absent.

Back navigation with a pending edit MUST await autosave. If save fails, pop
MUST be blocked and the UI MUST offer `Tekrar dene` or
`Kaydedilmemiş değişiklikleri bırak`. The latter discards only the current
in-memory delta and restores the last acknowledged durable draft; it MUST NOT
delete or abandon that draft.

`Oluştur` MUST:

1. validate the exact in-memory geometry and limits;
2. force and verify the latest draft save;
3. re-read the expected sketch and draft revisions inside one transaction;
4. verify canonical bytes and SHA-256;
5. change any current `ACTIVE` revision to `SUPERSEDED`;
6. change the exact `DRAFT` to `ACTIVE` and set `finalized_at`;
7. update `active_revision_id`, clear `draft_revision_id`, increment sketch
   revision and append `inventory.sketch_finalized` plus the receipt;
8. roll back every step if any check/write fails.

`Oluştur` MUST remain disabled while minimum geometry is unmet, an autosave is
pending/failed or the expected revision is stale.

### 4.4 Edit, abandon and archive

Editing an active sketch MUST atomically create a new `DRAFT` revision seeded
with the exact active canonical geometry and `base_revision_id`. It MUST NOT
modify the active revision. Only one DRAFT per sketch is permitted.

Abandoning an edit MUST mark that exact DRAFT `ABANDONED`, clear the draft
pointer and append `inventory.sketch_draft_abandoned`; the current active
revision remains unchanged. No row is deleted.

A sketch archive MUST be blocked while any active placement points to it. When
allowed, archive MUST set `archived_at`, clear `is_primary`, preserve all
revisions and append `inventory.sketch_archived`. Unarchive MUST fail if another
primary sketch exists; otherwise it restores the sketch as primary and appends
`inventory.sketch_unarchived`.

When a compatible new revision becomes active, existing placements MUST retain
their integer coordinates and original `provenance_revision_id`. They render on
the new active revision at the same virtual coordinate. Finalize SHOULD warn
that existing markers will stay fixed while lines may change; it MUST NOT move
or rewrite placements.

Every sketch mutation MUST use optimistic revision and durable command receipt
semantics from section 7. Missing, corrupt or wrong-project revision state MUST
return a typed diagnostic and MUST NOT be repaired implicitly.

### 4.5 Revised schema21 foundation and final schema22 compatibility

Revised schema21 adds normalized spatial ownership without rewriting geometry
v1; schema22 is the durable final schema for this contract:

- `inventory_blocks` is a stable project-owned identity with immutable project
  and ordinal, a bounded display name plus Turkish-aware normalized name, and
  lifecycle state `ACTIVE | DETACHED | ARCHIVED`;
- active block names MUST be unique per project by normalized name;
- `inventory_floors` is a stable block-owned identity with immutable positive
  ordinal and bounded display name; generated floor order is exactly
  `1. Kat .. N. Kat`;
- `inventory_sketch_revision_block_polygons` immutably maps one exact revision
  polygon index to one stable block, without cloning geometry per floor;
- `inventory_sketch_revision_spatial_drafts` append-only binds each durable
  draft content revision to its canonical new-block metadata;
- every placement version carries `floor_id`; block ownership is derived only
  through that floor.

A new block boundary MUST be closed, have at least three distinct vertices and
non-zero area, and MUST NOT self-intersect, overlap, touch or contain/be
contained by another active mapped block boundary. Every normally drawn new
edge MUST be horizontal or vertical. The first edge selects its axis from the
dominant snapped pointer delta; each following edge MUST use the axis
perpendicular to the preceding edge. Default smart alignment MUST choose a
deterministic relevant prior vertex coordinate in the intended direction and
MUST expose a visible proposed edge plus light alignment guide. `Serbest
uzunluk` disables only this prior-vertex length alignment for the next committed
edge; that edge remains orthogonal and smart alignment then restores
automatically. Preserved legacy/finalized geometry MAY remain diagonal and MUST
remain readable; this drawing rule MUST NOT become a schema/domain-wide legacy
rejection. The editor MUST also provide bounded snap-to-first closure plus
explicit `Alanı kapat`, and request the block name and positive bounded floor
count before closing the polygon. Validation MUST fail before draft/final source
mutation.

Schema20 migration MUST first validate source relationships, then create one
deterministic `Varsayılan Alan` / `1. Kat` pair for every project with Inventory
sketch data. The default block begins `DETACHED`. Every active and historical
placement receives that exact floor while placement ID/key/sequence, sketch,
provenance revision, x/y, quantity, predecessor and terminal truth remain
unchanged. Geometry JSON/checksum and event/photo history MUST remain unchanged.
Any corruption or incomplete backfill rolls the entire schema21 migration back.

Schema22 MUST classify the exact schema21 shape before mutation. A revised
block-owned schema21 advances through a structural no-op plus foreign-key and
integrity validation. The superseded PR #526 project-owned-floor schema21 MUST
transactionally retain every floor identity/name/order/revision/timestamp and
every placement version including its existing `floor_id`, create one
deterministic `DETACHED` default block per represented project, bind the old
floors to it, and create empty mapping plus exact legacy-draft metadata. It MUST
NOT invent an active polygon mapping for legacy geometry. The final floor schema
MUST use block-local ordinal uniqueness, so separate blocks may each own an
ordinal `1` floor. Mixed or unknown signatures and corrupt floor/placement
relationships MUST fail closed. The two supported chains are exactly
`20 -> revised 21 -> 22` and `superseded 21 -> 22`; same-version repair is
forbidden. Backup format remains `1`.

## 5. Inventory source model

### 5.1 Durable asset/lot

`inventory_assets` is the source record. A marker is not an asset; it is the
projection of an active placement joined to that source record.

Required asset fields and invariants:

- `id`: stable UUID;
- `project_id`: exact immutable project identity;
- `display_name`: trimmed `1..120` characters;
- `normalized_name`: search key created by trim, internal whitespace collapse
  and Turkish-aware lowercase; it MUST NOT replace display text;
- `category_code`: one exact v1 code below;
- `other_category_label`: exact `1..80` trimmed characters only when category is
  `OTHER`, otherwise `NULL`;
- `total_quantity`: stored integer `1..1000000`;
- `status`: one exact v1 operational code below;
- `note`: optional trimmed `1..1000` characters;
- optimistic `revision`, canonical UTC timestamps and nullable `archived_at`.

Exact category codes and labels:

| Code | UI label |
| --- | --- |
| `EQUIPMENT` | `Makine / ekipman` |
| `POWER_TOOL` | `Elektrikli el aleti` |
| `HAND_TOOL` | `El aleti` |
| `MEASUREMENT_DEVICE` | `Ölçüm cihazı` |
| `SAFETY_EQUIPMENT` | `İSG ekipmanı` |
| `TEMPORARY_WORKS` | `Geçici imalat` |
| `SITE_FACILITY` | `Şantiye tesisi` |
| `OTHER` | `Diğer` |

Exact status codes and labels:

| Code | UI label |
| --- | --- |
| `AVAILABLE` | `Kullanılabilir` |
| `IN_USE` | `Kullanımda` |
| `OUT_OF_SERVICE` | `Kullanım dışı` |
| `MISSING` | `Kayıp` |

Archive is not an operational status. Archiving MUST preserve the last status
and MUST be separately represented by `archived_at`.

### 5.2 Stored quantity invariant

Total quantity MUST be stored on the asset. For an unarchived asset:

```text
sum(quantity of active placements) <= total_quantity
unplaced_quantity = total_quantity - that sum
```

V1 UI MUST create exactly one active placement whose quantity equals
`total_quantity`, and MUST treat more than one active placement as the typed
unsupported state `inventory_multiple_placements_not_supported_in_v1` rather
than choosing one. The persistence model and sum invariant permit multiple
placement keys later without a destructive redesign.

A v1 quantity edit MUST update `total_quantity` and replace the sole active
placement with a history-preserving successor at the same coordinate and new
quantity in one transaction. It MUST append both the asset and placement events.
The transaction MUST fail before commit if the resulting active-placement sum
would exceed total quantity.

### 5.3 Placement identity and history

`placement_key` is the stable logical placement identity;
`inventory_asset_placements.id` identifies one immutable placement version.

Each placement version MUST carry exact `project_id`, `asset_id`, `sketch_id`,
stable same-project `floor_id`, `provenance_revision_id`, integer `x`, integer
`y`, positive integer `quantity`, monotonic `sequence`, `created_at`, nullable
`ended_at`, nullable `end_reason` and nullable predecessor
`supersedes_placement_id`.

An active placement has `ended_at IS NULL`. A move MUST atomically:

1. validate project, asset, sketch, active revision and expected placement
   sequence;
2. quantize the confirmed target to step `4`;
3. set the predecessor's terminal fields once with reason `MOVED`;
4. insert a successor row with the same `placement_key`, sequence plus one,
   exact active revision provenance and new coordinates;
5. append `inventory.placement_moved` and its receipt.

Coordinates MUST NOT be overwritten in place. Same-coordinate move is a no-op
receipt without row/event/revision change. A predecessor MUST have at most one
successor, so history cannot branch.

Archiving an asset MUST end every active placement with reason
`ASSET_ARCHIVED` and append the corresponding placement retirement event(s) in
the same transaction as `inventory.asset_archived`. Unarchive MUST require an
explicit placement on the current valid primary sketch and insert the next
version; it MUST NOT silently reuse a stale sketch or coordinate.

### 5.4 Create, edit, archive and shared projections

The first usable quick form MUST require only:

- `Ad`
- `Kategori`
- positive integer `Adet`

`Durum` is optional and defaults to `AVAILABLE`; `Not` is optional. The optional
photo boundary is implemented in Slice 5 and MUST be explicitly initiated by
the owner. A photo is not required for asset creation. After Slice 5, the quick
form MAY stage one optional photo. If selected, its managed-attachment metadata,
asset link and photo event MUST join the asset/placement create transaction;
failure MUST NOT silently create the requested asset without its selected photo.
Only the operation-owned new staged/final byte may be compensated after DB
failure. Additional photos are separate explicit detail commands.

Create MUST atomically insert one asset, one active placement, their append-only
events and one durable receipt. Edit MUST support name, category/other label,
quantity, status and note with exact expected revision. Status changes MUST use
`inventory.asset_status_changed`; other metadata uses
`inventory.asset_updated`. No-op edits MUST not create revisions/events.

Archive/unarchive MUST be recoverable; physical asset or placement deletion is
forbidden. `Kroki` markers and `Liste` rows MUST be built from the same canonical
project query over `inventory_assets` and active
`inventory_asset_placements`. A list cache or marker model MUST NOT become a
second source of truth.

## 6. Event and command-receipt contract

### 6.1 Exact event vocabulary

The only v1 event types are:

```text
inventory.sketch_created
inventory.sketch_draft_autosaved
inventory.sketch_edit_started
inventory.sketch_finalized
inventory.sketch_draft_abandoned
inventory.sketch_archived
inventory.sketch_unarchived
inventory.asset_created
inventory.asset_updated
inventory.asset_status_changed
inventory.asset_archived
inventory.asset_unarchived
inventory.placement_created
inventory.placement_moved
inventory.placement_quantity_changed
inventory.placement_retired
inventory.photo_linked
inventory.photo_archived
inventory.photo_restored
```

Event aggregate types are exactly `sketch`, `asset`, `placement` and
`attachment_link`. Placement events use `placement_key` as aggregate identity.
Every aggregate sequence MUST start at `1` and be contiguous. Events MUST be
append-only and ordered by `(aggregate_type, aggregate_id, sequence, id)`.

Payload JSON MUST be a bounded canonical object containing only stable IDs,
relevant before/after values, checksums/counts, reason codes and canonical UTC
timestamps. It MUST NOT contain attachment bytes, absolute paths, screen pixels,
viewport state or the full geometry document. A sketch event MAY include
geometry version, checksum, polyline/point/segment counts and revision IDs.

### 6.2 Idempotency and no-op receipts

Every public mutation command MUST carry a caller-generated UUID `operation_id`
and a canonical intent SHA-256. The receipt key is global `operation_id`.

- Exact retry with the same command type, project, primary aggregate and intent
  fingerprint MUST return the stored canonical result without mutation.
- Reuse of an operation ID with any differing field MUST fail
  `inventory_operation_id_conflict` before persistent mutation.
- A valid command whose requested state already equals current state MUST write
  an append-only receipt with `is_no_op = 1`, `event_count = 0`; it MUST NOT
  increment a source revision or append an event.
- Validation, stale revision, cross-project, corrupt geometry and invariant
  failures MUST write neither receipt nor partial mutation.
- A real mutation receipt MUST record the exact result JSON/hash and event
  count. All source rows, event rows and receipt MUST commit in one transaction.
- Replays MUST be checked before stale-revision rejection only after the stored
  receipt fingerprint and result integrity are verified.

Draft autosave is a real mutation when geometry changes and therefore creates
one sketch event. Debounce prevents per-pointer event spam; technical autosave
events MAY be hidden from the normal asset-history UI but remain queryable.

## 7. Proposed SQLite schema 20

This section is a plan for Slice 1. Issue #507 MUST NOT edit schema code.
The next Inventory migration MUST be exactly additive `19 -> 20` and create the
seven tables below. Existing tables MUST NOT be rebuilt, renamed or rewritten.

### 7.1 Exact table set

#### `inventory_sketches`

| Column | Contract |
| --- | --- |
| `id` | `TEXT PRIMARY KEY`, trimmed non-empty UUID |
| `project_id` | `TEXT NOT NULL REFERENCES projects(id)` |
| `display_name` | `TEXT NOT NULL`, trimmed length `1..80`; v1 default `Saha krokisi` |
| `is_primary` | `INTEGER NOT NULL CHECK IN (0,1)` |
| `active_revision_id` | nullable `TEXT`; same sketch/project ACTIVE target enforced by trigger |
| `draft_revision_id` | nullable `TEXT`; same sketch/project DRAFT target enforced by trigger |
| `revision` | `INTEGER NOT NULL CHECK >= 1` |
| `created_at`, `updated_at` | canonical UTC text; monotonic |
| `archived_at` | nullable canonical UTC text |

It MUST have `UNIQUE(id, project_id)`, pointer inequality, immutable identity,
guarded revision/timestamp updates and no-delete triggers.

#### `inventory_sketch_revisions`

| Column | Contract |
| --- | --- |
| `id` | `TEXT PRIMARY KEY` |
| `sketch_id`, `project_id` | composite FK to `inventory_sketches(id, project_id)` |
| `revision_number` | positive monotonic integer per sketch |
| `base_revision_id` | nullable same-sketch/project self-reference |
| `state` | `DRAFT`, `ACTIVE`, `SUPERSEDED` or `ABANDONED` |
| `geometry_version` | integer, exact v1 value `1` |
| `canvas_width`, `canvas_height` | exact values `4096`, `3072` |
| `geometry_json` | non-empty valid JSON object in canonical application form |
| `geometry_sha256` | lowercase 64-char hex |
| `content_revision` | positive optimistic draft revision |
| `created_at`, `updated_at` | canonical UTC text |
| `finalized_at`, `superseded_at`, `abandoned_at` | state-consistent nullable canonical UTC text |

It MUST have `UNIQUE(id, project_id, sketch_id)` and
`UNIQUE(sketch_id, revision_number)`. State/timestamp checks, draft-only guarded
geometry update, finalized immutability and no-delete triggers are mandatory.

#### `inventory_assets`

| Column | Contract |
| --- | --- |
| `id` | `TEXT PRIMARY KEY` |
| `project_id` | `TEXT NOT NULL REFERENCES projects(id)` |
| `display_name`, `normalized_name` | required bounded text described in section 5 |
| `category_code` | exact category check from section 5 |
| `other_category_label` | category-consistent nullable bounded text |
| `total_quantity` | integer `1..1000000` |
| `status` | exact status check from section 5 |
| `note` | nullable trimmed length `1..1000` |
| `revision` | positive optimistic revision |
| `created_at`, `updated_at`, `status_changed_at` | canonical UTC text |
| `archived_at` | nullable canonical UTC text |

It MUST have `UNIQUE(id, project_id)`, immutable identity, guarded revision,
status timestamp consistency and no-delete triggers. Duplicate display names are
allowed; IDs are the identity.

#### `inventory_asset_placements`

| Column | Contract |
| --- | --- |
| `id` | `TEXT PRIMARY KEY`, placement-version identity |
| `placement_key` | stable logical placement UUID |
| `project_id` | exact project ID |
| `asset_id` | composite FK with project to `inventory_assets` |
| `sketch_id` | composite FK with project to `inventory_sketches` |
| `provenance_revision_id` | composite FK with project/sketch to revision |
| `sequence` | positive monotonic version within `placement_key` |
| `x`, `y` | integers in inclusive bounds and divisible by `4` |
| `quantity` | integer `1..1000000` |
| `created_at` | canonical UTC effective time |
| `ended_at` | nullable canonical UTC terminal time |
| `end_reason` | nullable; exact terminal values `MOVED`, `QUANTITY_CHANGED`, `ASSET_ARCHIVED` |
| `supersedes_placement_id` | nullable unique predecessor row reference |

It MUST have `UNIQUE(id, project_id)`,
`UNIQUE(placement_key, sequence)`, a partial unique active index per
`placement_key`, a unique predecessor relation, immutable source coordinates,
one-time terminal update and no-delete triggers. V1's one-placement-per-asset
limit is application-enforced; the DB sum invariant remains future-multiple
compatible.

#### `inventory_command_receipts`

| Column | Contract |
| --- | --- |
| `id` | operation UUID primary key |
| `project_id` | `TEXT NOT NULL REFERENCES projects(id)` |
| `command_type` | exact v1 mutation command code listed below |
| `primary_aggregate_type`, `primary_aggregate_id` | stable replay target |
| `intent_sha256` | lowercase 64-char canonical intent hash |
| `result_json`, `result_sha256` | canonical result object and hash |
| `is_no_op` | integer boolean |
| `event_count` | non-negative integer; zero exactly for no-op |
| `created_at` | canonical UTC text |

It MUST be append-only. Exact v1 command codes are:

```text
sketch_create
sketch_draft_autosave
sketch_edit_start
sketch_finalize
sketch_draft_abandon
sketch_archive
sketch_unarchive
asset_create_with_placement
asset_update
asset_status_change
asset_quantity_change
asset_archive
asset_unarchive_with_placement
placement_move
photo_link
photo_archive
photo_restore
```

One command MAY emit events for multiple affected aggregates, as specified in
sections 5 and 6. Application validation MUST verify result JSON/hash and event
count before returning a replay.

#### `inventory_events`

| Column | Contract |
| --- | --- |
| `id` | event UUID primary key |
| `operation_id` | deferred FK to `inventory_command_receipts(id)` |
| `project_id` | exact project ID |
| `aggregate_type`, `aggregate_id` | exact type and stable aggregate identity |
| `sequence` | positive contiguous aggregate sequence |
| `event_type` | exact section 6 vocabulary |
| `occurred_at` | canonical UTC text |
| `payload_json`, `payload_sha256` | canonical bounded object and lowercase hash |

It MUST have `UNIQUE(aggregate_type, aggregate_id, sequence)` and
`UNIQUE(operation_id, aggregate_type, aggregate_id)`, append-only triggers and
polymorphic aggregate/project existence triggers. One operation may emit one
event for each affected aggregate, but not two events for the same aggregate.

#### `inventory_asset_attachment_links`

| Column | Contract |
| --- | --- |
| `id` | stable link UUID primary key |
| `attachment_id` | FK to existing `managed_attachments(id)` |
| `asset_id`, `project_id` | composite FK to exact Inventory asset |
| `role` | exact value `inventory_photo` in v1 |
| `original_file_name` | safe non-empty display name |
| `description` | nullable bounded text |
| `revision` | positive optimistic revision |
| `created_at`, `updated_at` | canonical UTC text |
| `archived_at` | nullable canonical UTC text |

It MUST have `UNIQUE(id, project_id)`, a partial unique active relation on
`(attachment_id, asset_id, role)`, immutable identity, guarded archive revision
and no-delete triggers. Photo lifecycle uses `inventory_events`; no duplicate
photo-event table is created.

### 7.2 Exact index plan

Slice 1 MUST add these indices, with equivalent SQLite-safe names allowed only
if a platform length constraint is proven:

```text
uq_inventory_sketches_primary
ix_inventory_sketches_project
uq_inventory_sketch_revisions_draft
uq_inventory_sketch_revisions_active
ix_inventory_sketch_revisions_history
ix_inventory_assets_project_name
ix_inventory_assets_project_filter
uq_inventory_asset_placements_active_key
ix_inventory_asset_placements_map
ix_inventory_asset_placements_asset
ix_inventory_command_receipts_aggregate
ix_inventory_events_history
ix_inventory_events_operation
uq_inventory_asset_attachment_links_active
ix_inventory_asset_attachment_links_asset
ix_inventory_asset_attachment_links_attachment
```

The primary-sketch, DRAFT, ACTIVE, active-placement and active-photo uniqueness
indices MUST be partial indices over their active state.

### 7.3 DB versus application responsibility

SQLite MUST enforce:

- primary/composite foreign keys and exact project equality;
- enum/check/range/quantization constraints expressible without app code;
- active uniqueness and immutable identities;
- guarded optimistic revision shape;
- no physical delete and append-only event/receipt behavior;
- same-project pointer/aggregate relations through exact triggers;
- active-placement quantity sum not exceeding asset total through triggers;
- event sequence matching the committed aggregate state where directly
  expressible.

The application MUST additionally enforce:

- full canonical geometry parsing, limits, semantic validity and SHA-256;
- canonical intent/result/payload JSON and hashes;
- project active state at mutation time;
- v1 one-active-placement behavior;
- exact lifecycle transition matrix;
- receipt replay integrity and event-count matching;
- minimum final geometry and editor state-machine behavior;
- same-coordinate/no-field-change no-op decisions.

Application checks MUST run before mutation, then critical project/FK/revision
facts MUST be re-read inside the shared transaction. DB constraints are the
last fail-closed boundary, not a substitute for typed application failures.

### 7.4 Migration and legacy behavior

The schema-20 migration MUST run in one SQLite transaction. It MUST create only
the seven tables, their indices and triggers, then set `user_version = 20` only
after success. Failure MUST roll back the complete migration and leave schema
`19` usable.

The migration MUST NOT:

- invent a sketch, asset, placement, event, receipt or photo link;
- backfill geometry from another module;
- update/delete an existing user row;
- rebuild, rename or drop an existing table/index/trigger;
- read, copy, move, deduplicate or delete attachment bytes.

A legacy schema-19 database therefore opens with empty Inventory tables and the
normal no-sketch state. Schema `1..19` upgrade fixtures MUST prove the existing
migration chain still reaches schema 20 atomically.

### 7.5 Backup format and attachment adoption

Backup format MUST remain `1`: the format already packages a SQLite snapshot
plus managed attachment files, and schema version identifies DB evolution.

Slice 1 MUST add all seven table names to the current database smoke/table
adoption check and add focused round-trip assertions for empty and populated
Inventory state. Restore migration from schema 19 MUST yield empty valid
Inventory tables without fabricated rows.

Slice 5 MUST adopt photos without duplicating a binary:

- new/imported bytes MUST use the existing `ManagedAttachmentStore` and one
  `managed_attachments` physical identity;
- linking an existing physical attachment MUST reuse its ID and MUST NOT copy
  its file;
- SHA equality alone MUST NOT silently merge two pre-existing physical IDs;
- the existing `attachment_links` table MUST NOT be rebuilt to add a new
  `source_type`; Inventory uses the additive
  `inventory_asset_attachment_links` relation;
- attachment catalog, media album and reconciliation queries MUST explicitly
  union this relation while preserving exact project/source provenance;
- backup `_activeAttachmentRows` and `_manifestAttachmentRows` equivalents MUST
  union both link tables and `DISTINCT` physical IDs so one binary is packaged
  once even if linked multiple times;
- archived/historical Inventory photo links MUST retain the physical byte in
  format-1 backup, matching existing history-preservation behavior;
- stage/DB failure MUST compensate only the new operation-owned staged/final
  artifact and MUST NOT touch a pre-existing managed attachment.

Round-trip validation MUST compare sketch/revision JSON and checksum, assets,
placement chains, receipts, events, photo relations and each referenced byte's
path/size/SHA-256/MIME. `PRAGMA integrity_check` and `foreign_key_check` MUST
pass before activation.

## 8. Editor and Inventory UI behavior

### 8.1 Route-scoped orientation

The drawing editor MUST request only `landscapeLeft` and `landscapeRight` after
route entry. Every exit path—normal pop, system back, handled error, finalize,
route replacement and lifecycle interruption—MUST restore the standard shell
set `portraitUp`, `landscapeLeft`, `landscapeRight` in an awaited `finally`
guard. On resume, a mounted editor MUST reassert landscape; a non-editor shell
MUST reassert the standard set. Orientation calls MUST NOT change Android/iOS
manifest or permission files unless a later Issue separately proves necessity.

The ready editor MUST use the landscape route as a full-screen canvas without a
large AppBar or horizontal text toolbar. A compact icon-only toolbar MUST stay
on the right; every control MUST expose both a tooltip and an accessibility
label. Selected modes and one-shot state MUST include a non-color-only
indicator. Draft acknowledgement MAY appear as a compact overlay and MUST NOT
reduce the canonical canvas work area.

### 8.2 Tap-to-connect editor state machine

The editor has exact modes `DRAW`, `SELECT` and `PAN`.

In `DRAW`:

1. a single tap on a valid grid point while idle starts a one-point working
   polyline;
2. the second tap projects to the horizontal or vertical axis whose absolute
   pointer delta from the first point is greater; an exact tie is horizontal;
3. every later distinct tap projects onto the axis perpendicular to the
   preceding segment;
4. smart alignment defaults on and, when a prior vertex coordinate exists in
   the intended direction, chooses the deterministic closest pointer target,
   then closest start target, then lowest coordinate; a guide identifies the
   selected coordinate;
5. `Serbest uzunluk` is a one-shot override for the next segment only, bypasses
   step 4 but not steps 2–3, and resets only after a valid segment commits;
6. tapping the first point after at least three distinct points closes and ends
   the polyline only when the required orthogonal axis can reach it;
7. `Çizgiyi bitir` ends an open polyline with at least two points;
8. ending a one-point polyline removes that incomplete point as one undoable
   editor command;
9. a duplicate consecutive point, invalid point or limit-exceeding point is
   rejected without changing the draft.

In `SELECT`, tapping the nearest segment within a `24` logical-pixel hit radius
selects that segment; tapping its stroke again selects its whole polyline. A
selection MUST have visible non-color-only emphasis and a semantic label.

`Seçileni sil` MUST behave deterministically:

- deleting a polyline removes that whole polyline;
- deleting an interior segment of an open polyline keeps any prefix/suffix with
  at least two points as ordered open polylines and discards one-point fragments;
- deleting the implicit closing segment opens the same ordered closed polyline;
- deleting any other segment of a closed polyline rotates point order to the
  point after the deleted segment and produces one open polyline containing all
  remaining segments.

Undo/redo applies only to geometry commands since this editor route opened.
It MUST include start/add/end/close, segment/polyline delete and undoable
incomplete-point removal. It MUST NOT include pan, zoom, selection, marker focus
or already committed asset mutations. The stack MUST retain at most `100`
commands; a new command after undo clears redo. Relaunch recovers durable draft
geometry with an empty undo/redo stack.

During `Krokiyi güncelle` / `editActive`, unmapped legacy base geometry remains
immutable. A mapped active block MAY be changed only through the bounded Slice
6.3 whole-block nudge, orthogonal edge reshape or explicit detach/archive
lifecycle actions in section 8.7. Candidate geometry MUST pass local bounds,
polygon and non-overlap checks before editor history or autosave changes. The
same draft MAY still append new orthogonal blocks; they MUST autosave, reload
and finalize normally.

### 8.3 Gesture separation and viewport

- One-finger taps draw only in `DRAW`.
- One-finger drag pans only in `PAN`.
- Two-finger pan/pinch MAY navigate in every mode but MUST never add/delete a
  point.
- Zoom MUST be presentation-only and bounded to `0.5x..4.0x` relative to
  fit-to-canvas.
- Panning SHOULD keep at least `15%` of the canvas visible.
- Switching mode MUST end no polyline implicitly; the owner must use
  `Çizgiyi bitir`, close it or undo it.

The dotted grid, polylines and placement markers MUST share one virtual-to-view
transform, while source values remain integer virtual coordinates.

### 8.4 Autosave, finalize and error states

The editor MUST show `Kaydediliyor…`, `Kaydedildi` or `Kaydedilemedi` from the
actual last acknowledgement. It MUST NOT claim a save before the transaction
returns.

A complete, finalizable draft MUST keep its prominent check/save action enabled
while the latest autosave debounce or acknowledgement is pending. That action
MUST drain/force-save the latest draft, run the section 4 finalize transaction,
verify the canonical active successor, and only then return route result
`true`. Inventory MUST canonical-reload that result so create and edit-active
successors are visible on the map in the same session.

A stale or failed autosave/finalize MUST leave the durable prior draft intact.
Finalize failure MUST keep the editor open and show explicit draft-preserved
feedback with retry; it MUST restore standard orientation only if the route
exits and MUST NOT expose a partially active revision.

Closing a new polygon MUST request local block/floor metadata with the action
`Alanı ekle`. Metadata acceptance adds that block to the current draft and
MUST NOT finalize the sketch; one draft MAY collect multiple new blocks before
the global check/save action.

Loading MUST be explicit. Missing sketch, recoverable draft, corrupt geometry,
unavailable revision, stale command and database-read failure MUST have distinct
states. A generic safe error MAY offer `Tekrar dene`; it MUST NOT create a new
sketch or choose another revision automatically.

### 8.5 Map capture, markers, list and detail

On a valid active sketch, tapping empty map space in normal `Kroki` view MUST
quantize one placement coordinate and open the quick form. Tapping a marker or
cluster MUST NOT open create.

Create success MUST add the same canonical asset/placement result to both map
and list. Marker semantics MUST include asset name, quantity and status text;
status MUST NOT be encoded by color alone. Each tappable marker/cluster MUST
have at least a `48 x 48` logical-pixel target.

Basic overlap MUST use viewport presentation buckets of `48 x 48` logical
pixels anchored to the current viewport origin. Two or more marker centers in
one bucket render as a count cluster, ordered internally by normalized asset
name then stable asset ID. Cluster tap zooms one step and centers the bucket; at
`4.0x`, it opens the deterministic item list. Bucketing MUST NOT mutate source
coordinates.

Marker tap MUST open exact asset detail with status, quantity, note, category,
photo boundary and ordered event history. `Taşı` MUST show a target preview and
require explicit `Konumu güncelle` confirmation before the section 5 move
transaction. Cancel or same coordinate is a no-op.

Asset detail history MUST combine the asset's own events, every placement-key
event belonging to that asset and every Inventory photo-link event belonging to
that asset. It MUST sort by `occurred_at DESC`, then stable event ID ascending,
show event type plus relevant before/after summary, and retain exact source IDs.
It MUST NOT synthesize a history row from current state or hide archived
placement/link history.

List item tap MUST switch to `Kroki`, center the exact active placement and show
a `2`-second non-color-only highlight. If an active placement or valid geometry
is unavailable, the app MUST remain in `Liste` and show the typed diagnostic;
it MUST NOT focus another item.

The list MUST support project-local normalized-name search and exact category,
status and active/archive filters. Archive entries MUST remain in history/list
surfaces but MUST not render as active markers. Empty search and empty Inventory
states MUST be distinguished from load failure.

All controls MUST expose semantic labels, selected/disabled state, logical
reading order and scalable text. Color MUST NOT be the sole carrier for mode,
selection, status, archive, corrupt state or save state.

### 8.6 Kat Görünümü and canonical block/floor navigation

Inventory navigation MUST derive its route-local spatial selection from the
canonical active relation `asset -> active placement -> floor -> block ->
project`. A nullable selected block means all active blocks; a nullable selected
floor means all floors of the selected block. A selected floor is legal only
under its selected active block. Project, block and same-project reload changes
MUST clear or revalidate incompatible IDs deterministically. This UI state MUST
NOT be persisted.

`Katlar` MUST present active blocks side by side in stable block-ordinal order.
Each block MUST present its unarchived floors as a vertical stack with higher
floor ordinals visually above lower ordinals. Floor, block and project counts
MUST count distinct non-archived assets with one valid active placement in the
exact canonical floor; ended placement history and archived assets MUST NOT be
counted or double-counted. Detached/archived block lifecycle MUST NOT be
represented by invented active polygons.

Map and List MUST share compact block/floor selectors. Spatial filtering MUST
compose with existing search, category, status and archive filters. Valid active
rows MUST show the exact asset, block and floor names. Archived or currently
unplaced rows MUST NOT receive an invented current spatial label. List focus
MUST select the exact owning block and floor before switching to Map, then reuse
the existing exact-coordinate center and two-second non-color-only focus
indicator. Floor and block changes MUST NOT leak markers from another floor.

A floor-row `+` action MUST reuse the normal asset quick-create flow with an
optional exact floor intent. The application boundary MUST accept that intent
only when the floor belongs to the selected project and to the active block
whose current-revision polygon strictly contains the target. Wrong-project,
wrong-block, detached, missing or stale floor context MUST fail before mutation.
Map-tap create without an explicit floor MUST retain its existing canonical
fallback behavior and receipt compatibility.

Floor quick-create coordinates MUST be integer grid-quantized, deterministic,
distinct from occupied active coordinates and strictly inside the shared active
block polygon; boundary points are not safe create targets. Repeated creates
MUST use a deterministic compact spread. If no provably safe point exists, the
operation MUST report `inventory_safe_interior_unavailable`, open no create
form and write nothing.

Slice 6.2 changes no database table, migration or stored filter contract.
SQLite schema remains `22`, backup format remains `1`, and mobile version
remains `0.1.0+1`.

### 8.7 Block reshape, placement reconciliation and lifecycle

In `SELECT`, selecting the same segment again MUST promote the selection to its
whole mapped polygon. Four icon actions with tooltips and semantic labels MUST
nudge a whole polygon exactly one sketch-grid step left, right, up or down. A
selected horizontal or vertical edge MUST move parallel exactly one sketch-grid
step in its perpendicular direction while its adjacent edges remain connected.
A persisted legacy diagonal polygon MAY be whole-translated, but an individual
diagonal edge reshape MUST fail safely. A self-intersecting, overlapping or
out-of-canvas candidate MUST change neither editor history nor autosave state.

A finalized revision MUST use an explicit typed intent for every existing block
whose geometry or lifecycle changes. Retained blocks bind to an exact target
polygon; removed active blocks require the owner to choose exactly one of
`Bloğu ve envanter kayıtlarını sil` or
`Bloğu krokiden kaldır, kayıtları koru`; a detached block may be reattached only
after explicit confirmation. Draft geometry and revision mappings MAY autosave,
but destructive lifecycle intent MUST remain current-session state. A recovered
draft missing an existing active mapping MUST ask for detach/archive again and
MUST NOT silently select either outcome. Undo/redo MUST keep geometry, stable
mapping identity, new-block metadata and pending reattach state in one logical
frame.

Schema `22` revision→block polygon rows are immutable. An autosave whose mapping
set is unchanged MUST update the current mutable draft without rewriting those
rows. An autosave whose mapping set changes MUST atomically abandon the old
draft, create one successor draft on the same active base, insert the successor
mapping set once, and move `draft_revision_id` to that successor. The old draft
and its mappings remain append-only evidence; a receipt replay MUST return the
same successor identity.

Finalization MUST reconcile the new immutable revision, mappings, block/floor
state, placements, events and command receipt in one transaction. A rigid
whole-polygon translation MUST append a placement successor at exact old
coordinates plus the common `dx/dy`. A non-rigid reshape MUST leave an active
placement unchanged only when it remains safely inside the new polygon with a
deterministic inward clearance of one placement-grid step (`4`). Otherwise it
MUST append the nearest deterministic safe-interior successor; squared
distance, then `y`, then `x` ascending is the stable tie-break. The predecessor
MUST end as `MOVED`;
placement key, floor, quantity and sequence continuity MUST be preserved.
`inventory.placement_moved` MUST carry `reason: geometry_reconciliation`, exact
before/after coordinates, predecessor/successor IDs, floor ID and old/new
revision provenance.

Detach MUST set the stable block to `DETACHED`, omit it from the new active
revision mapping and preserve its floor IDs, active assets, placement history,
events and photos without coordinate rewrite solely due to detach. The List
MUST show its retained active records with exact text
`Krokisi kaldırılmış blok`; Map, Katlar and active selectors MUST show no fake
polygon/marker, and List-to-Map focus MUST fail safely.

Archive MUST tombstone the stable block and floors and canonically archive every
owned non-archived asset while physically deleting no placement, event, receipt
or photo history. Reattach MUST reuse the exact detached block and floor IDs,
names and ordinals, create a new active-revision mapping, and append a
deterministic safe-interior placement cluster. Exactly one normalized detached
name match MAY be offered for reuse; an active/detached duplicate or ambiguous
match MUST fail closed. Any stale sketch/content/block/asset/placement revision,
invalid relationship, write-boundary failure or receipt conflict MUST roll the
whole transaction back. Replaying the exact operation ID and intent MUST remain
idempotent.

Slice 6.3 changes no database table, migration or backup contract. SQLite
schema remains `22`, backup format remains `1`, and mobile version remains
`0.1.0+1`.

## 9. Slice-by-slice implementation ownership

Each child Slice MUST have its own Issue/authority and may narrow file splits,
but MUST preserve the component ownership and changed contracts below. A child
Issue MUST use stable manual-test IDs `MT-<child-issue>-<NNN>` in Issue #479;
this contract does not pre-mark any test PASS.

### Slice 1 — Inventory persistence foundation

- Intended production paths: create
  `mobile/lib/domain/inventory_models.dart` and
  `mobile/lib/application/inventory_application.dart`; modify
  `mobile/lib/storage/app_database.dart`,
  `mobile/lib/application/mobile_backup_application.dart` and
  `mobile/lib/bootstrap/app_bootstrap.dart`.
- Changed contracts: schema `19 -> 20`, seven-table source model, project
  isolation, revision, receipts/events, backup DB smoke adoption.
- Validation class: `persistence`.
- Focused gates: migration fixtures from schema 19 and supported legacy chain,
  rollback/fail-closed, FK/trigger/check/index tests, exact replay/no-op,
  cross-project rejection, geometry validator/fingerprint, empty/populated
  format-1 DB round-trip and affected analyze/tests authorized by that Issue.
- Impact: schema additive; backup format remains `1`; attachment bytes and
  platform/orientation unchanged.
- Stop: any existing-row mutation/rebuild, format change, data-root access,
  unsafe project link or inability to verify round-trip.
- Owner manual-test family: none on owner phone; later UI/device Slices cover
  visible behavior. Persistence acceptance remains automated/synthetic.

### Slice 2 — Landscape schematic-sketch editor

- Intended production paths: create
  `mobile/lib/features/inventory/inventory_sketch_editor_page.dart` and
  `mobile/lib/features/inventory/inventory_sketch_canvas.dart`; modify the
  Inventory domain/application port only where editor commands require it.
- Changed contracts: geometry state machine, 500 ms autosave/recovery,
  finalize/edit/abandon, route-scoped orientation.
- Validation class: `domain` because durable draft/revision behavior is changed;
  focused widget coverage accompanies it.
- Focused gates: pure normalization/fingerprint/limits, editor state machine,
  undo/redo, stale autosave, relaunch recovery, finalize rollback and orientation
  restoration on every route/error/lifecycle path.
- Impact: no new schema beyond 20; backup format/attachment unchanged;
  application orientation calls only, with platform-file drift `0` unless a new
  owner authority proves otherwise.
- Stop: float/pixel source truth, lost draft, active revision rewrite,
  orientation leak or partial finalize.
- Owner manual-test family: draw/open/closed line, undo/redo/delete, autosave,
  relaunch recovery, create/finalize and portrait restoration.

### Slice 3 — Asset and placement core

- Intended production paths: create
  `mobile/lib/features/inventory/inventory_map_view.dart`,
  `mobile/lib/features/inventory/inventory_asset_quick_form.dart` and
  `mobile/lib/features/inventory/inventory_asset_detail_sheet.dart`; modify
  Inventory domain/application components.
- Changed contracts: quick create, shared asset/placement projection,
  marker/detail, metadata/status/quantity edit, move and archive/unarchive.
- Validation class: `domain`.
- Focused gates: required fields/category/status, quantity/sum invariant,
  create atomicity, same-coordinate no-op, placement chain, stale/cross-project
  rejection, archive/unarchive and deterministic history.
- Impact: schema stays 20; backup/attachment/platform/orientation unchanged.
- Stop: coordinate overwrite, duplicate map/list source, quantity overflow,
  hard delete or partial multi-aggregate mutation.
- Owner manual-test family: quick create, marker detail, edit/status/quantity,
  confirmed move, archive/history and reopen persistence.

### Slice 4 — Envanter destination and Kroki/List experience

- Intended production paths: create
  `mobile/lib/features/inventory/inventory_page.dart`; modify
  `mobile/lib/app.dart` and, only for already-created typed port exposure,
  `mobile/lib/bootstrap/app_bootstrap.dart`.
- Changed contracts: exact six-item shell, `Daha` hub, project selection,
  no-sketch state, Kroki/List/search/filter/focus flow.
- Validation class: `narrow-ui` plus focused domain query coverage.
- Focused gates: destination order/count, existing Beton/Sicil reachability,
  one/many/no-project states, project-switch cache clearing, empty/error states,
  same-source list/map and list-to-marker focus.
- Impact: schema/backup/attachment/platform unchanged; normal Inventory remains
  portrait-capable.
- Stop: seventh destination, Home-only access, broken existing destinations,
  inferred cross-project selection or second source cache.
- Owner manual-test family: direct navigation, active-project isolation,
  no-sketch entry, portrait Kroki/List, search/filter and bidirectional focus.
- First internally usable flow: **Slice 4**, after Slices 1–3 are integrated.

### Slice 5 — Attachment and usability hardening

- Intended production paths: create
  `mobile/lib/application/inventory_attachment_application.dart`; modify
  Inventory domain/application/UI components,
  `mobile/lib/application/attachment_catalog_application.dart`,
  `mobile/lib/features/attachments/project_media_album_page.dart`,
  `mobile/lib/application/attachment_reconciliation_application.dart`,
  `mobile/lib/application/mobile_backup_application.dart` and bootstrap wiring.
- Changed contracts: optional Inventory photo link through shared physical
  attachment, catalog/album/reconciliation union, overlap clusters, safe errors,
  accessibility and hardened relaunch recovery.
- Validation class: `persistence` because attachment lifecycle and packaged
  bytes are affected.
- Focused gates: stage/compensation, existing-byte reuse, no link-time copy,
  link lifecycle/events, project isolation, physical-ID deduped backup query,
  integrity-gated read/open, cluster determinism, semantics and recovery.
- Impact: schema stays 20 because the additive relation already exists; backup
  format stays `1`; no new permission/dependency/platform capability unless a
  later owner Issue explicitly authorizes it.
- Stop: duplicate link binary, existing table rebuild, orphan artifact,
  cross-project photo, unsafe path/hash/MIME, inaccessible critical action or
  source mutation from catalog/album.
- Owner manual-test family: optional photo add/view/archive/restore, catalog and
  album visibility, overlapping markers, accessibility, offline relaunch and
  safe failures.

### Slice 6.2 — Kat Görünümü and block/floor navigation

- Intended production paths: Inventory domain/application command boundary,
  `inventory_page.dart`, `inventory_map_view.dart`,
  `inventory_asset_quick_form.dart` and the dedicated
  `inventory_floor_view.dart` presentation surface.
- Changed contracts: route-local block/floor selection, stable active-floor
  stacks and counts, Map/List spatial filtering and labels, exact-floor
  list-to-map focus, exact-floor quick create and deterministic strict-interior
  targets.
- Validation class: `domain` plus focused real widget coverage.
- Focused gates: `AT-531-001..013`, including stable ordering/counts,
  cross-block selection isolation, exact-floor persistence, safe-target
  determinism, wrong-floor no-write and the prior create/move/archive/editor/
  migration regressions selected by Issue #531.
- Impact: schema stays `22`; backup format stays `1`; mobile version stays
  `0.1.0+1`; storage/migration, package, permission and platform behavior do not
  change.
- Stop: required storage/migration work, fake active geometry, cross-floor
  marker leakage, non-exact floor ownership, unsafe coordinate fallback or any
  write outside the Issue #531 allowlist.
- Owner manual-test family: Kat stacks/counts, exact Map/List navigation,
  selector/label behavior and floor-row quick create. Automated results do not
  imply owner/manual PASS.

### Slice 6.3 — Block reshape, placement reconciliation and lifecycle

- Intended production paths: Inventory domain/application command boundary,
  sketch canvas/editor and Inventory page detached presentation only.
- Changed contracts: bounded whole-polygon/orthogonal-edge transforms, typed
  finalize lifecycle intent, atomic placement reconciliation, detach/archive,
  same-identity reattach and detached List behavior.
- Validation class: `persistence` plus focused real editor/page widget coverage
  because one finalization transaction changes immutable revision mappings,
  append-only placement history and asset lifecycle together.
- Focused gates: `AT-533-001..016`, including exact rigid delta, safe-margin
  non-rigid relocation, rollback/idempotency, detach/archive/reattach identity,
  undo/redo mapping integrity and all selected Slice 6.2 regressions.
- Impact: schema stays `22`; backup format stays `1`; mobile version stays
  `0.1.0+1`; storage/migration, package, permission and platform behavior do not
  change.
- Stop: hidden destructive recovery choice, in-place placement rewrite,
  physical history/photo deletion, unstable block/floor identity, partial
  revision activation or any write outside the Issue #533 allowlist.
- Owner manual-test family: bounded reshape, deterministic placement response,
  detach/archive consequences, detached List behavior and same-ID reattach.
  Automated results do not imply owner/manual PASS.

Slice 6.3 is merged through PR #534. Its merged state is source availability,
not owner acceptance.

### Slice 6.4 — Integrated regression and owner acceptance closure

- Intended paths: task/result evidence and the three authorized Inventory v1
  documentation surfaces only. Production Dart and test sources are read-only.
- Phase A exact nine-file integrated Flutter gate passed `187/187` at source
  head `baa7beff186e3fee95f1fb439d92045d7ba1af4e`; analyzer also passed.
- Phase A changes no product behavior, schema, storage, migration, backup,
  version, package, permission or platform contract.
- `MT-535-001..007` remain `PENDING / NOT RUN`; automated evidence does not
  imply owner/manual PASS.
- Phase B requires separate explicit owner authority and isolated Acceptance
  package handling. Slice 7 remains unstarted.

### Slice 7 — Backup/restore, migration and field acceptance

- Intended production paths: modify only proven gaps in
  `mobile/lib/application/mobile_backup_application.dart` and Inventory
  application diagnostics; production code MAY remain unchanged if prior
  adoption is complete. Focused migration/backup/integration/manual-register
  tests and evidence are primary.
- Changed contracts: no new product behavior by default; executable proof of
  schema upgrade, complete format-1 round-trip and safe in-place update.
- Validation class: `persistence`; any MAIN package/signing/install work becomes
  separately authorized `release-critical` scope.
- Focused gates: schema-19 fixture migration, populated geometry/assets/
  placement chains/events/receipts/photos round-trip, checksums/FKs/integrity,
  rollback, newer-live-data protection, external backup verification and
  owner-led numbered acceptance.
- Impact: target remains schema 22, backup format 1, version unchanged unless a
  separate release Issue authorizes versioning; no device command under Epic
  #506 or Issue #507 alone.
- Stop: Issue #501 recovery unverified for recovery claims, #502 external backup
  gate incomplete, #503 unsafe restore path, wrong signer/package, uninstall,
  clear-data, debug/acceptance identity or absent separate owner authority.
- Owner manual-test family: migration/reopen, draft and active sketch survival,
  asset/placement/history/photo restore, historical data preservation and
  representative post-update verification.
- First owner-phone MAIN eligibility: **Slice 7 only**, after #502 PASS for the
  exact current dataset/candidate and separate explicit install authority.

## 10. Cumulative P0 data-safety gates

Inventory work MUST preserve these cumulative rules:

- Issue #501 remains an unresolved recovery incident until the owner verifies
  recovered history. Source/PR work does not resolve it.
- Issue #502 requires a fresh, verified, owner-controlled backup outside the app
  sandbox before every owner-phone MAIN update. Package, signer, version path,
  integrity and recovery compatibility MUST be proven before install.
- Issue #503 forbids routine restore from making newer live records unavailable.
  Full replacement is exceptional disaster recovery; current live data MUST
  have a verified external recovery path, and unsafe merge/reconciliation MUST
  fail closed.
- Issue #499 forbids debug and acceptance/test packages on the owner's phone.
  Only the canonical MAIN package `com.faliardic.sefim` can ever become eligible,
  subject to all stronger backup/recovery gates.
- Inventory source development, synthetic persistence tests, Draft PRs and
  independent review MAY continue without owner-phone installation.
- Epic #506 and Issue #507 grant no MAIN install, device, build, Ready or merge
  authority.
- Inventory v1 MUST NOT be declared complete until geometry, assets, placement
  history, events/receipts and attachment links/bytes pass verified backup/
  restore plus safe in-place update evidence, and owner manual tests are
  explicitly statused.

No schedule, Reminder, notification, phone integration, Work Chain, Living Plan,
material request or existing attachment source record may be mutated as a side
effect of Inventory.

## 11. Completion boundary

Inventory Map v1 is implemented only after Slices 1–6 meet their own authority,
review and evidence gates. This Slice 0 contract alone changes no production
behavior and authorizes no future edit implicitly.

The first internally usable integrated flow is after Slice 4. Optional photos
and usability hardening arrive in Slice 5. Owner-phone MAIN installation can
first be considered in Slice 6, but only after the cumulative P0 gates and a
separate explicit owner command. Ready, merge, release and V2 completion remain
independent owner decisions.
