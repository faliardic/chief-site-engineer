# Issue #572 — Icon-First Wave I1 result

## Product result

- The six NavigationBar destinations retain their exact labels, order, indexes,
  selected indicator, and navigation behavior while visible labels are hidden.
- Dashboard quick actions are icon-only `add_alert` / `note_add` controls;
  project switch uses `swap_horiz`; summary open actions use a consistent open
  icon; retry uses `refresh`.
- Dashboard state actions are icon-only where surrounding explanation keeps the
  action clear. Tool-card titles/subtitles remain visible.
- One shared Dashboard icon-action component enforces an exact 40x40 baseline,
  tooltip, explicit semantics label, button role, and enabled state.
- All existing keys, callbacks, project context, loading/error/empty behavior,
  routes, capture semantics, and data behavior remain unchanged.

## Changed paths

- `.cse/tasks/572_task.md`
- `.cse/results/572_result.md`
- `mobile/lib/app.dart`
- `mobile/lib/features/dashboard/project_dashboard_page.dart`
- `mobile/test/widget_test.dart`
- `mobile/test/project_dashboard_widget_test.dart`

## Validation

- Touched Dart format: PASS.
- One combined focused target covering only the two directly affected files:
  `flutter test --no-pub test/widget_test.dart test/project_dashboard_widget_test.dart`:
  PASS, 22/22.
- The first focused run exposed two test-only assumptions: hidden NavigationBar
  labels remain in Flutter's widget tree at opacity zero for semantics, and
  merged card semantics may add layout line breaks. The authorized mechanical
  correction now proves zero opacity and explicit `Semantics.label` properties.
- Final proof covers destination identity/order/navigation, icon/key/tooltip/
  semantics contracts, 40 px normal-phone geometry, preserved callbacks and
  state behavior, visible content titles, and 1.6 scaling without overflow.
- Full suite, broad analyze, APK, emulator, and device were not run.
- Owner shell + Dashboard visual Acceptance: PENDING.

## Execution record

```yaml
issue: 572
process_lane: STANDARD
authority_comment: 5490681877
base: 2f6b3febbd2c70f8b0a07320283b5108ae0bd52a
branch: codex/issue-572-icon-first-shell-dashboard
stacked_pr_base: codex/issue-569-dashboard-compact-ui
changed_paths: 6_of_6_allowlisted
focused_gate: PASS
corrections_used: 1
ci: PENDING
manual_tests: PENDING
ready: false
merged: false
```
