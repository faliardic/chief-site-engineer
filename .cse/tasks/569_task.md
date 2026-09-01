# Issue #569 — Dashboard compact field UI

- Parent: #566 / #539
- Foundation: #567 / Draft PR #568
- Owner authority: Issue #569 comment 5490409439
- Exact base: `28b7378531601f625a2a2e347268ae2eaba9a273`
- Branch: `codex/issue-569-dashboard-compact-ui`
- Process lane: accelerated STANDARD

## Goal and unchanged behavior

- Make the Dashboard visibly denser on a normal phone.
- Keep `+ Unutma` and `+ Ajanda kaydı` side-by-side at normal text scale with
  compact 40–42 px actions and an accessibility-safe responsive fallback.
- Tighten project header, summary cards, section rhythm, state surfaces, and
  tool ListTiles.
- Preserve every callback, widget key, project context, loading/error/empty
  state, route, capture, and persistence behavior.

## Exact allowlist

1. `.cse/tasks/569_task.md`
2. `.cse/results/569_result.md`
3. `mobile/lib/features/dashboard/project_dashboard_page.dart`
4. `mobile/test/project_dashboard_widget_test.dart`
5. `mobile/test/compact_ui_theme_test.dart` — conditional only for a genuine
   cross-theme regression.

Everything else is read-only. Feature behavior, #556, #564/#565,
`ActiveProjectSession`, application/domain/storage, schema/migration/backup,
version, platform, pubspec/lock, routes, wording, and persistence are protected.

## Validation and publication

- Format touched Dart.
- One focused Dashboard widget invocation only.
- Exact allowlist/protected drift, `git diff --check`, and invariants
  `schema 22 / backup 1 / app 0.1.0+1`.
- No full suite, broad analyze, APK, emulator, or device.
- Publish one stacked Draft PR with base
  `codex/issue-567-compact-ui-theme`; no Ready/merge.
- Owner-led Dashboard visual Acceptance remains pending after source PASS.
