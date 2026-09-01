# Issue #572 — Icon-First Wave I1

- Parent: #571 / #566 / #539
- Foundations: #567 / Draft PR #568 and #569 / Draft PR #570
- Owner authority: Issue #572 comment 5490681877
- Exact base: `2f6b3febbd2c70f8b0a07320283b5108ae0bd52a`
- Branch: `codex/issue-572-icon-first-shell-dashboard`
- Process lane: accelerated STANDARD

## Goal and unchanged behavior

- Hide visible labels in the six-destination NavigationBar while retaining the
  exact destinations, order, indexes, label identity, and semantics.
- Convert Dashboard quick, project-switch, summary open, and retry actions to
  icon-only controls with explicit tooltips and accessible labels.
- Preserve the 40 px compact action baseline, every existing key/callback,
  project context, loading/error/empty state, route, capture, and data behavior.
- Keep Dashboard content/tool titles and subtitles visible.

## Exact allowlist

1. `.cse/tasks/572_task.md`
2. `.cse/results/572_result.md`
3. `mobile/lib/app.dart`
4. `mobile/lib/features/dashboard/project_dashboard_page.dart`
5. `mobile/test/widget_test.dart`
6. `mobile/test/project_dashboard_widget_test.dart`

Everything else is read-only. Other feature production files, Inventory,
#564/#565, application/domain/storage/persistence, `ActiveProjectSession`,
schema/migration/backup/version/platform/pubspec/lock, and navigation behavior
are protected.

## Validation and publication

- Format touched Dart.
- One combined focused widget invocation covering exactly `widget_test.dart`
  and `project_dashboard_widget_test.dart`.
- Exact allowlist/protected drift, `git diff --check`, and invariants
  `schema 22 / backup 1 / app 0.1.0+1`.
- No full suite, broad analyze, APK, emulator, or device.
- Publish one stacked Draft PR with base
  `codex/issue-569-dashboard-compact-ui`; no Ready/merge.
- Owner shell + Dashboard visual Acceptance remains pending after source PASS.
