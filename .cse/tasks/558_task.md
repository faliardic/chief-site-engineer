# Issue #558 Task — Global active-project context

- Parent / V2 item: #554 / #539; predecessor #547 / merged PR #557.
- Standing authority: Issue #558 body; process lane `STANDARD`.
- Expected base: `df55d742a9bba887bb78ef62115e68969c4ca4ea`.
- Branch: `codex/issue-558-global-active-project-context`.
- Risk / routing: R3; requested `gpt-5.6-sol / xhigh`; standard, single-agent; review floor `gpt-5.6-sol / xhigh`.
- Runtime routing evidence: `unknown / unknown / unverified`; mismatch `null`.
- Routing request: Issue #558 comment 5483307684.
- Changed contracts: shell-visible active-project name on Reminder, Agenda and More; active project is only a new-capture default.
- Reminder contract: optional preferred project reaches only `ReminderFormPage` creation.
- Agenda contract: local explicit filter wins; otherwise shared active project is the new-log default; mixed/global listing stays unchanged.
- Session contract: form-local project changes do not retarget `ActiveProjectSession`.
- Allowed production: `mobile/lib/app.dart`, `mobile/lib/features/reminders/reminders_page.dart`, `mobile/lib/features/agenda/agenda_page.dart`.
- Allowed tests: `global_active_project_context_widget_test.dart`, `reminder_widget_test.dart`, `mobile_agenda_widget_test.dart`, `widget_test.dart`.
- Allowed ledgers: this file and `.cse/results/558_result.md`.
- Protected: ActiveProjectSession implementation, Puantaj, Envanter, schema/migration, backup/restore, version, platform, pubspec/lock.
- Source checks: exact allowlist, changed-Dart format, deterministic syntax/static check as useful, `git diff --check`, protected/invariant drift.
- Automated application tests: at most one materially useful targeted widget check; broad Flutter validation belongs to PR CI.
- Manual register: #479, planned `MT-558-001..005`, initial status `PENDING`.
- Build/artifact authority: none; no APK/AAB.
- Stabilization budget: 2/2 same-scope correction rounds used.
- Correction 1: targeted test harness replaced unsupported `pageBack()` lookup
  with the current route Navigator; production behavior was unchanged.
- Correction 2: targeted Reminder submit helper adopted the repository's
  existing bounded hit-testable scroll pattern; production was unchanged.
- Immediate escalation: scope/allowlist expansion; schema/backup/version/platform/security/data-integrity change; unproven root cause.
- Publication: commit, push, Draft PR; no Ready, merge, release or next implementation.

## Canonical source manifest

- `AGENTS.md`: `1c432b740654d6ce0d876ceaaf6db8be5bd14ba3`
- `CSE_UNIFIED_PROJECT_SOURCE.md`: `d2f31def8ee392aab74990766e0a4822be489710`
- `CSE_PROJECT_INSTRUCTIONS.md`: `f83164280277cc1f811448a559ddbfcc78d56040`
- `CSE_MODEL_REASONING_ROUTING_POLICY.md`: `7d099ed4e5a1205320350c663fe659e36f2c4d6a`
- `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`: `e90612f5ca5bb3f4997110142e24112e246f3b6d`
- `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`: `473308a212213450ea44d669109b0cc3b82d9e68`
- `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`: `af1974ecd2c53ceb67245c8eb1242b03fb1a82ef`
- `CSE_PROJECT_SOURCE_REGISTER.md`: `583663cf0016d5060ed90ec44d1fce8aa16f74a5`
- `CSE_V2_SCOPE.md`: `12bf27e27dde086a396aa063d16c148410906ea7`
- `ROADMAP.md`: `61037f291f18b3434d740fdb096bdce6a0f9b885`
