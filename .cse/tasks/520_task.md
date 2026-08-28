# Issue 520 — Inventory destination / Kroki + Liste

## Authority and baseline

- Parent / V2 item: Epic #506, Inventory V1 Slice 4
- Canonical authority: Issue #520 comment 5455488954
- Expected base: exact master 1f92da6e330d69f9554db9e07d260919e77c20ea
- Working branch: codex/issue-520-inventory-destination-kroki-list
- Risk / routing: CSE-MRP 1.0, R4, requested gpt-5.6-sol / max
- Execution mode: STANDARD_IMPLEMENTATION, standard / single-agent
- Runtime model / effort visibility: unknown / null / unverified
- Review floor: gpt-5.6-sol / max independent R4 review
- Fallback: null; fail closed on unavailable authority, scope expansion, or integrity risk

## Changed contracts

- Mobile shell has six exact top-level destinations: Başlangıç, Hatırlatıcı, Ajanda, Envanter, Puantaj, Daha.
- Daha preserves the existing Beton Paketi and Sicil entry behavior.
- Envanter provides one selected active-project session with sibling Kroki / Liste surfaces sharing one canonical inventory snapshot, query, and filters.
- Zero / one / many active-project behavior and project-unavailable fail-closed handling follow the canonical authority.
- List-to-map focus is presentation-only, centers the exact active placement, and uses a two-second non-color highlight.
- Existing inventory mutations, identity, history, sketch editor, detail, quantity, move, archive, and unarchive contracts remain unchanged.

## Writable path allowlist

1. .cse/tasks/520_task.md — mandatory first write
2. mobile/lib/features/inventory/inventory_page.dart — new primary implementation
3. mobile/lib/app.dart — shell wiring and Daha hub
4. mobile/lib/features/inventory/inventory_map_view.dart — conditional shared snapshot / focus presentation only
5. mobile/lib/bootstrap/app_bootstrap.dart — conditional; prefer zero
6. mobile/lib/application/inventory_application.dart — conditional; prefer zero
7. mobile/test/inventory_page_test.dart — new focused proof
8. mobile/test/widget_test.dart — shell-only proof
9. mobile/test/inventory_asset_core_test.dart — conditional map focus/shared-source proof
10. mobile/test/inventory_application_test.dart — conditional only if application path changes
11. .cse/results/520_result.md — execution evidence

No twelfth path is authorized. Database/schema/migration/backup, attachments,
pubspec/lock, Android/iOS/platform/permission/signing/package, and unrelated
module production behavior are protected.

## Implementation scope

- Use AgendaApplication.listProjects / projectChanges as the canonical active-project source and the existing InventoryApplicationPort as the canonical inventory source.
- Do not perform inventory I/O with zero active projects.
- Auto-select exactly one active project; require explicit selection for many.
- Clear project-scoped session, focus, search, filters, sketch, assets, and pending targets before an explicit project switch.
- If the selected project disappears, clear unsafe state, show a typed diagnostic, and do not silently select another project.
- Preserve the exact no-sketch copy “Bu projede henüz şematik kroki yok.” and action “Kroki ekle”; reuse InventorySketchEditorPage create/recover and reload only after successful finalization.
- Derive Kroki markers and Liste rows from the same page-owned canonical snapshot. Apply normalized-name, category, status, and active/archive filters consistently; archived rows never become markers.
- Preserve distinct empty-inventory, empty-search, and load-failure states.
- Marker opens the existing exact asset detail. A valid list row switches to Kroki, centers its exact active placement, and highlights it for two seconds without color-only meaning. Invalid placement/geometry stays in Liste with a typed diagnostic.
- Notification routing uses destination indexes Envanter=3, Puantaj=4, Daha=5; concrete detail opens without highlighting an unrelated destination.

## Source-level checks and automated-test authority

- Format touched Dart files only.
- One focused Flutter test invocation containing inventory_page_test.dart,
  affected widget_test.dart, and inventory_asset_core_test.dart if touched.
- One retry is allowed only for a proven mechanical test defect.
- After focused PASS, exactly one flutter analyze --no-pub invocation; one retry only for a proven mechanical analyzer defect.
- Run git diff --check, exact path audit, schema/additive-migration audit,
  backup/version/pubspec/platform/permission drift checks, and branch/head/tree checks.
- Full suite, build, APK/AAB, emulator, ADB, device, and scripted acceptance are forbidden.

## Manual test and publication

- Issue #479 stable IDs: MT-520-001..005, initial status PENDING.
- Automated application tests are authorized only in the focused invocation above.
- Build / artifact authority: none.
- Stabilization budget: primary implementation 1; same-scope narrow corrections at most 3; environment-only recovery at most 1 after exact root cause.
- Immediate escalation: allowlist expansion; schema/migration/backup/version/permission/signing/platform change; production/debug/real-data risk; identity/transaction/event/history/integrity change; new product decision; unproven root cause; exhausted correction budget.
- Publication after all gates PASS: one minimal commit, normal push, one Draft PR, Issue/PR evidence, and MT-520 registration. Ready=false, merge=false, Issue closure=false, Slice 5 start=false.

## Canonical source hash manifest (SHA-256)

- docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md: 5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333
- docs/protocols/CSE_PROJECT_INSTRUCTIONS.md: f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5
- docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md: e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6
- docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md: e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b
- docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md: c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d
- docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md: 7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d
- docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md: b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a
- docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md: f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb
- docs/v2/CSE_V2_SCOPE.md: 3fb70a0c80c293b17a38214f4b717c1bafe539526289eaf86a0be1d4683aee51
- ROADMAP.md: 5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166
- docs/contracts/CSE_INVENTORY_MAP_V1_CONTRACT.md: 6ed6285a565d5cc032116b5643f5565757d97acb7acc8325188f19dc8cd0bbca

## Initial state

- Branch/base/HEAD verified at exact authority master.
- Tracked and staged worktree clean before the first write.
- No existing remote Issue #520 branch or PR was found.
- Implementation status: IN_PROGRESS
- Manual test status: PENDING
