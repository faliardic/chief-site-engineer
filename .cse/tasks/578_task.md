# Issue #578 — Reminder Icon-First I2A

- Process lane: `STANDARD` (accelerated)
- Validation class: `narrow-ui`
- Authority: Issue #578 and owner comment `5491473598`
- Exact base: `89dffbe2b7caa44f50fb4426b5ebf9d1b5157dda`
- Exact base tree: `9bc0228a562076fea3ab5d7a39f0cc12a706b06c`
- Branch: `codex/issue-578-reminder-icon-first`
- Repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Goal

Convert the existing Reminder list, create form, and detail action surfaces to
the locked icon-first language. Every icon-only control remains 40x40 and keeps
its exact key, callback, enabled/loading state, tooltip, and explicit semantics
label. Dates, times, deadlines, counts, content, diagnostics, and important
confirmation text remain visible.

## Allowed paths

1. `.cse/tasks/578_task.md`
2. `.cse/results/578_result.md`
3. `mobile/lib/features/reminders/reminders_page.dart`
4. `mobile/lib/features/reminders/reminder_form_page.dart`
5. `mobile/lib/features/reminders/reminder_detail_page.dart`
6. `mobile/test/reminder_widget_test.dart`

Conditional reminder test paths from Issue #578 are allowed only if genuinely
required by an exact existing assertion. All other paths are read-only.

## Protected contracts and validation

- No reminder domain/application/storage/scheduling/notification/project-context
  changes; no schema, migration, backup, version, platform, pubspec, or lock drift.
- Preserve destructive and cognitively important dialog text actions.
- Format touched Dart, run one focused `reminder_widget_test.dart` invocation,
  review exact changed paths/protected drift, run `git diff --check`, and confirm
  invariants `22 / 1 / 0.1.0+1`.
- Do not run full suite, broad analyze, APK, emulator, or device checks.
- Correction budget: up to two same-scope rounds.
- Commit/push and open one Draft PR to `master`; do not mark Ready or merge.

## Routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R3
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: xhigh
  execution_mode: standard
  orchestration: single-agent
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/578#issuecomment-5491473598
  invocation_evidence: null
  review_floor: R3
  fail_closed_if_visible_mismatch: true
```
