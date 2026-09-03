# Issue #556 — shared Inventory project context

- Process lane: STANDARD (UI/session integration; no persistence changes).
- Base: `8793f48dff881db69f63b94400f5b7746d7f012d`.
- Branch: `codex/issue-556-inventory-active-project-context`; target: `master`.
- Authority: issue comments 5505907861, 5507779648 and clarification 5508092381.
- Contract: remove Inventory dropdown/space; interactive, textual, bounded shared AppBar chooser; validate exact project before Inventory I/O; adopt deliberate selection only after successful load; latest context wins; cancel pending target flows.
- Exact allowed paths:
  - `.cse/tasks/556_task.md`
  - `.cse/results/556_result.md`
  - `mobile/lib/app.dart`
  - `mobile/lib/features/inventory/inventory_page.dart`
  - `mobile/test/inventory_page_test.dart`
  - `mobile/test/global_active_project_context_widget_test.dart`
  - `mobile/test/project_context_bidirectional_widget_test.dart`
- Protected: domain/application/storage/schema/migrations/backup/autosave/block-floor identity; #586 UI/orientation/gestures; other paths.
- Preflight: exact base/branch, tracked worktree and index clean; canonical ruleset hashes unchanged.
- Format changed Dart and review candidate before validation.
- One-shot gates, in order from `mobile`:
  1. `flutter test --no-pub test/inventory_page_test.dart test/global_active_project_context_widget_test.dart test/project_context_bidirectional_widget_test.dart`
  2. `flutter test --no-pub test/active_project_session_test.dart test/global_active_project_context_widget_test.dart test/project_context_bidirectional_widget_test.dart test/inventory_page_test.dart test/widget_test.dart`
  3. `flutter analyze --no-pub`
- Any gate failure: stop, no retry/post-failure correction/publication under this authority.
- Publication only after all gates PASS: one implementation/evidence commit, push, Draft PR, independent review stop.
- No Ready/merge, builds, device commands or manual acceptance. Manual register: #479, PENDING only.
