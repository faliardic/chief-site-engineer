# Issue #567 — Compact UI Wave A root-theme foundation

- Parent: #566 / #539
- Owner authority: Issue #567 comment 5490081903
- Exact base: `236e76e1d053e801e2103bce3e6cb7415d7b22c2`
- Branch: `codex/issue-567-compact-ui-theme`
- Process lane: accelerated STANDARD

## Goal and changed contract

- Build one shared light/dark compact Material theme from `mobile/lib/app.dart`.
- Scale the Material 3 typography baseline to approximately `0.92` while
  preserving hierarchy, weights, and platform MediaQuery text scaling.
- Give standard buttons an explicit safe minimum near 40 px with tighter
  padding; make inputs dense; compact AppBar and NavigationBar sizing.
- Apply only modest compact visual density and no feature behavior changes.

## Exact allowlist

1. `.cse/tasks/567_task.md`
2. `.cse/results/567_result.md`
3. `mobile/lib/app.dart`
4. `mobile/test/compact_ui_theme_test.dart`
5. `mobile/test/widget_test.dart` — conditional only if an existing root-shell
   assertion must change.

All feature production files, application/domain/storage code, Inventory,
Living Plan fixes, `ActiveProjectSession`, schema/migration/backup/restore,
version, platform, pubspec/lock, routes, wording, and persistence are protected.

## Validation and publication

- Touched Dart format.
- Exactly one focused widget invocation covering the compact theme and normal
  phone root-shell regression.
- Exact allowlist/protected-drift audit, `git diff --check`, and invariants
  `schema 22 / backup 1 / app 0.1.0+1`.
- No full suite, broad analyze, APK, emulator, device, Ready, or merge.
- Manual tests: `MT-567-001..005`, owner-led and initially `PENDING`.
- Publication: one commit, push, and Draft PR; stop for independent review.
