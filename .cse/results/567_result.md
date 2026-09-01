# Issue #567 — Compact UI Wave A result

## Product result

- One shared light/dark root theme now supplies the compact UI baseline.
- Material 3 typography is scaled to `0.92` without overriding platform
  MediaQuery text scaling or changing text hierarchy and weights.
- Standard buttons retain an explicit 40 px minimum, icon buttons retain a
  40x40 minimum, inputs are dense, AppBar is 52 px, and NavigationBar is 64 px.
- No feature production, route, wording, persistence, schema, backup, version,
  package, or platform behavior changed.

## Changed paths

- `.cse/tasks/567_task.md`
- `.cse/results/567_result.md`
- `mobile/lib/app.dart`
- `mobile/test/compact_ui_theme_test.dart`

`mobile/test/widget_test.dart` remained unchanged.

## Validation

- Touched Dart format: PASS.
- Focused widget gate:
  `flutter test --no-pub test/compact_ui_theme_test.dart`: PASS, 1/1.
- The first focused attempt exposed a null-font-size assertion in raw
  `ThemeData.textTheme`; the same-scope correction merged Material 3 text
  geometry before scaling, then the same focused gate passed.
- The regression proves light/dark parity, compact component sizes, safe button
  minimums, normal-phone root layout, and preserved 1.6 platform text scaling.
- Full suite, broad analyze, APK, emulator, and device checks were not run by
  authority.
- Owner-led `MT-567-001..005`: PENDING.

## Execution record

```yaml
issue: 567
process_lane: STANDARD
authority_comment: 5490081903
base: 236e76e1d053e801e2103bce3e6cb7415d7b22c2
branch: codex/issue-567-compact-ui-theme
changed_paths: 4_of_5_allowlisted
focused_gate: PASS
corrections_used: 1
ci: PENDING
manual_tests: PENDING
ready: false
merged: false
```
