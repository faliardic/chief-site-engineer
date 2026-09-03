# Issue #569 — Dashboard compact field UI result

## Product result

- At a normal 390 px phone width, `+ Unutma` and `+ Ajanda kaydı` render
  side-by-side at 40 px with 18 px icons and tighter padding.
- At 1.6 accessibility text scale, the actions use a full-width stacked
  fallback without clamping text scaling or producing overflow.
- Dashboard outer rhythm, section gaps, project header, summary cards, state
  surfaces, and tool ListTiles are materially denser.
- The old local 56 px quick-action and 52 px state-action overrides are gone.
- All callbacks, keys, project selection/context, read ordering, loading,
  error/empty behavior, routes, capture semantics, and persistence remain
  unchanged.

## Changed paths

- `.cse/tasks/569_task.md`
- `.cse/results/569_result.md`
- `mobile/lib/features/dashboard/project_dashboard_page.dart`
- `mobile/test/project_dashboard_widget_test.dart`

`mobile/test/compact_ui_theme_test.dart` remained unchanged.

## Validation

- Touched Dart format: PASS.
- Focused Dashboard target only:
  `flutter test --no-pub test/project_dashboard_widget_test.dart`: PASS, 10/10.
- The focused proof first exposed the long Agenda label wrapping at normal
  width. The authorized UI correction tightened horizontal padding and made
  both labels single-line; subsequent test-only selector calibration removed
  assumptions about Material Card's internal margin layer.
- Final proof covers normal-phone placement/height, compact header/summary/tool
  contracts, preserved callbacks/keys and project/error/empty/read behavior,
  plus 1.6 accessibility scaling without overflow.
- Full suite, broad analyze, APK, emulator, and device were not run.
- Owner Dashboard visual Acceptance: PENDING.

## Execution record

```yaml
issue: 569
process_lane: STANDARD
authority_comment: 5490409439
base: 28b7378531601f625a2a2e347268ae2eaba9a273
branch: codex/issue-569-dashboard-compact-ui
stacked_pr_base: codex/issue-567-compact-ui-theme
changed_paths: 4_of_5_allowlisted
focused_gate: PASS
corrections_used: 1
ci: PENDING
manual_tests: PENDING
ready: false
merged: false
```
