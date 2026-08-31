# Issue #545 Task — Wave 2A Core Route Project Context

## Authority and scope

- Issue: `#545 — UI/UX Wave 2A — Dashboard project-context propagation to core daily routes`
- Parent: Epic `#539`; predecessor: Issue `#542` / merged PR `#544`.
- Execution authority: Issue #545 comment `5473383256`.
- Official repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`.
- Expected base: `6371464e497929e4ffaa572cfeee4a4f8c781f54`.
- Branch: `codex/issue-545-project-context-core-routes`.
- Execution class: `UI_WAVE_2A_CORE_ROUTE_CONTEXT_ONE_SHOT`.
- Validation class: `narrow-ui`, elevated to task risk `R4` because a wrong
  project fallback can expose cross-project reads.

## Model routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  orchestrator:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  selection_reason: Cross-project read safety and multi-route UI initialization contract.
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/545#issuecomment-5473383256
  allowed_fallback: null
  review_floor:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  fail_closed_if_mismatch: true
```

Invocation/runtime model metadata is not exposed by the current surface and
will be recorded as `unknown / null / unverified`; no downgrade is inferred.

## Canonical source hash manifest

| Source | SHA-256 |
| --- | --- |
| `AGENTS.md` | `BB00551CAECBD2C19AF6CCFF0FE9C93ACFA71AADE05288B303F6006BE0BE616D` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899A8FE03E8AB7CA8CE204DDF7A271686BDA0668B08A828645649495539E333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `F2C00B649CD1DCEB19DC0BD1D284713138DBFBD8EE3332B9581AFD107A0C20D5` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `E6585E4A217D63D6717973121512338A3EDFD24091C3EB0DF6EA573EC8A797C6` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `E1F55336657ECD79CB68CBAE458341A811F0BB33867AC06B71163A5A8C8C320B` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `C12A57885F31144DC15CBBD3A07AB59527489A533CE5D8B444664ECF7710440D` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765BCEBFB7B25B12E60FB44767D49C9D537393786FA0026561E1593073D297D` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `B1685CE1610593195282B3B7C9038009EF8CD365D7C1314CB2356FC425BB383A` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `F96FC9B1EF8BD12A6A4515A707726D84EE9A86A1A28BF6F20C5217E2954212CB` |
| `docs/v2/CSE_V2_SCOPE.md` | `09972DF385CFC5A91303521FC7CC3232413C0189EFF46D69D438F66F5581B190` |
| `ROADMAP.md` | `7CBE3BF9B496A621C1F2CCF07A639B09235FA25F3D6669FB7056837AB08384FC` |

The hash manifest is bound to the pre-read files present at task start.

## Changed contracts

- Dashboard-provided `projectId` becomes the optional initial project context
  for Living Plan, Daily Log and Material Requests routes.
- A valid explicit initial project is selected before the first project-bound
  read.
- A stale explicit initial project fails closed with no read against the first
  or another project until deliberate local selector recovery.
- Callers without `initialProjectId` retain legacy first-project behavior.
- Route-local selector overrides do not update `ActiveProjectSession` in Wave
  2A.
- No source data mutation, schema, storage, application or platform behavior is
  added.

## Exact writable paths

1. `.cse/tasks/545_task.md`
2. `.cse/results/545_result.md`
3. `mobile/lib/app.dart`
4. `mobile/lib/features/living_plan/living_plan_page.dart`
5. `mobile/lib/features/daily_log/daily_log_page.dart`
6. `mobile/lib/features/material_requests/material_requests_page.dart`
7. `mobile/test/project_context_core_routes_widget_test.dart`
8. `mobile/test/living_plan_widget_test.dart`
9. `mobile/test/widget_test.dart`

Everything else is read-only. Application/domain/storage/schema/migration/
bootstrap/platform/pubspec/lock/Inventory paths are protected.

## Required implementation and evidence

- Bind the exact Dashboard callback project ID into all three destination
  constructors from `MobileShell._buildDashboard()`.
- Add backward-compatible nullable `initialProjectId` inputs.
- Prove positive first-call evidence for project B with project order `[A, B]`.
- Prove stale explicit context yields zero project-bound reads until explicit
  recovery, then reads only the chosen project.
- Preserve legacy no-initial behavior and route-local override behavior.
- Prove back/cancel causes no source mutation and no framework/navigation error
  is ignored.

## Validation authority

The owner explicitly opts in to these automated application gates for this
Issue only:

1. one focused four-file `flutter test --no-pub` invocation;
2. after PASS, one regression four-file `flutter test --no-pub` invocation;
3. one `flutter analyze --no-pub` invocation;
4. changed writable Dart format check;
5. full and staged `git diff --check`;
6. allowlist/protected/schema/backup/version invariants.

Use only
`C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`.
No APK/build/device/ADB/install/manual acceptance is authorized.

Stabilization budget: one bounded same-scope round for the full execution.
Infrastructure-only retry: one, only before Flutter/analyzer work loads and
with identical command plus zero source/test edits.

## Manual test and artifact status

- Manual Test Register: Issue `#479`.
- Existing `MT-545-*` entries at task start: none.
- Required final IDs: to be registered after implementation with status
  `PENDING`; automated tests do not substitute owner manual verification.
- Build/artifact authority: none.
- Initial manual test status: `PENDING`.

## Preserved invariants and escalation

- SQLite schema / backup format / mobile version must remain `22 / 1 / 0.1.0+1`.
- No persistence, migration, backup, version, permission, signing, stable
  identity, transaction, event/history or Inventory contract change.
- STOP before editing if another path, new design decision, destructive Git,
  data access or protected-contract change is required.
- STOP after any deterministic final-cycle failure; no second stabilization.
- Inventory PR #536 remains deferred and untouched.

## Publication authority

On a fully green final cycle: create one minimal commit, push this exact branch,
open exactly one Draft PR to `master`, and publish Issue/PR evidence. Ready,
merge, Issue/Epic closure, Wave 2B/Wave 3, Inventory, DWG and release/store are
not authorized. Success stop: `FRESH_INDEPENDENT_R4`.

## Initial repository evidence

- GitHub `master`: `6371464e497929e4ffaa572cfeee4a4f8c781f54`.
- Local `master == origin/master`: exact; divergence `0 0`.
- Branch created from exact base.
- Pre-write staged/tracked/untracked sets: empty.
- Active merge/rebase/cherry-pick/revert: none.
- Open PRs: none; Issue #545 branch did not previously exist remotely.
- Manual Test Register contained no `MT-545-*` entry.

## One-shot execution outcome

- Production implementation and focused tests were prepared only inside the
  exact allowlist.
- Initial format check command failed before Dart loaded because `dart` was
  absent from `PATH`; the authorized infrastructure-only retry used the
  repository-recorded absolute SDK path.
- Changed-Dart format check found five files requiring format; the single
  authorized deterministic format write was applied.
- Focused gate attempt 1: exit `1`, `36 PASS / 2 FAIL`. Exact causes were
  non-constant expressions in the new test and the predecessor-era
  `open-living-plan` test key.
- The single stabilization round corrected those exact test defects and made
  the Living Plan selector state key project-sensitive while preserving its
  public test key.
- Focused gate stabilization retry: exit `1`, `41 PASS / 1 FAIL`. All new
  Issue #545 tests passed. The remaining predecessor Living Plan navigation
  test found `dashboard-open-plan` but its tap missed because the button was
  behind the bottom navigation region.
- Stabilization budget remaining: `0`.
- Fail-closed stop applied. Regression, analyzer, final diff checks,
  commit/push/Draft PR, Manual Test Register publication and independent R4
  were not run.

## Final test-harness correction authority

- Authority comment:
  `https://github.com/faliardic/chief-site-engineer/issues/545#issuecomment-5473557040`
- Classification: `TEST_HARNESS_MIGRATION_545`.
- This correction does not reopen production implementation scope.
- Exact correction write boundary:
  - `mobile/test/living_plan_widget_test.dart`
  - `.cse/tasks/545_task.md`
  - `.cse/results/545_result.md`
- Branch/base preflight:
  `codex/issue-545-project-context-core-routes` at
  `6371464e497929e4ffaa572cfeee4a4f8c781f54`.
- Staged set empty; merge/rebase/cherry-pick/revert absent.
- Aggregate changed/untracked set before correction contained eight paths,
  all inside the original nine-path Issue #545 allowlist.
- Canonical ruleset SHA-256 manifest matches the task-start manifest exactly.
- Issue #479 still contains no `MT-545-*` entry.
- Production byte-preservation baseline:
  - `mobile/lib/app.dart`:
    `D7153463A63502E62AF53D46BFBC2B76B08BB23899DF6F042B09D4C2CD118011`
  - `mobile/lib/features/living_plan/living_plan_page.dart`:
    `92FDF6DB013DC2F33A1C3D9D384BB327D25DD4B57598CAF21C2E5A3E1E4AE5E8`
  - `mobile/lib/features/daily_log/daily_log_page.dart`:
    `CDBBC0669EDDEB19AFB83DA92538B139403F2CF5D098292AB44937568F89FD2C`
  - `mobile/lib/features/material_requests/material_requests_page.dart`:
    `6A6ADDD72440E4F5C3BAD10E344435633FA7FB2E3E75870A7F7A58669D337381`
- Authorized closure sequence: one harness edit, focused once; on PASS,
  regression once, analyzer once, format/diff/invariant gates, then one
  minimal commit/push/Draft PR and STOP for `FRESH_INDEPENDENT_R4`.

## Final test-harness correction outcome

- Harness correction changed only the migrated
  `dashboard-open-plan` interaction in
  `mobile/test/living_plan_widget_test.dart`.
- Exact focused gate: exit `0`, `42/42 PASS`.
- Exact regression gate: exit `0`, `49/49 PASS`.
- Exact `flutter analyze --no-pub`: exit `0`,
  `No issues found`.
- Aggregate changed-Dart format check: exit `1`.
  - `mobile/test/living_plan_widget_test.dart` requires formatting.
  - Preserved original implementation file
    `mobile/lib/features/living_plan/living_plan_page.dart` also requires
    formatting.
- Comment `5473557040` authorizes a mechanical format write only when the
  test file is the sole format delta and forbids all production correction
  writes. Therefore no format write was performed.
- Production SHA-256 values remained byte-identical to the correction
  preflight baseline.
- Fail-closed stop applied before diff/invariant publication gates,
  commit/push/Draft PR and Issue #479 registration.
- Correction recommendation:
  `STOP — FRESH OWNER AUTHORITY REQUIRED`.

## Final format-only owner authority and closure

- Owner authority source:
  `C:\Users\Fatih\.codex\attachments\12c7e320-25fb-43fa-b659-10f6c444ebae\pasted-text.txt`
- Reported boundary comment: `5480938897`.
- Authority type: `FINAL_FORMAT_ONLY_OWNER_CORRECTION`.
- Classification: `DETERMINISTIC_FORMAT_ONLY_545`.
- Preflight PASS:
  - branch `codex/issue-545-project-context-core-routes`;
  - HEAD and `origin/master` both
    `6371464e497929e4ffaa572cfeee4a4f8c781f54`;
  - no merge/rebase/cherry-pick/revert;
  - staged set empty;
  - eight changed/untracked paths, all within the original nine-path
    allowlist;
  - production SHA-256 values matched the previous correction ledger.
- One deterministic formatter write targeted exactly:
  - `mobile/lib/features/living_plan/living_plan_page.dart`;
  - `mobile/test/living_plan_widget_test.dart`.
- Formatter exit `0`; both files changed. Pre/post normalized line comparison
  found zero content-line differences, proving format/newline-only output.
- Format-write SHA-256:
  - Living Plan production:
    `92FDF6DB013DC2F33A1C3D9D384BB327D25DD4B57598CAF21C2E5A3E1E4AE5E8`
    -> `6968F75A670427E105242F03C709116A2209039AB380F46CAE3F66E7BC87D229`;
  - Living Plan test:
    `BDCBD8660998A74F628DD3D74FD9087B6D11DD3DDF86FF20113974B9511F6B73`
    -> `AFD75E8A2C98399D61C091D249CCF1A9B6DBC8240ED24482B5BEA88486634072`.
- Immediate complete changed-Dart format check: exit `0`,
  `6 files / 0 changed`.
- Invalidated final validation chain:
  - focused: exit `0`, `42/42 PASS`;
  - regression: exit `0`, `49/49 PASS`;
  - analyzer: exit `0`, `No issues found`;
  - final format: exit `0`, `6 files / 0 changed`;
  - full `git diff --check`: exit `0`;
  - staged `git diff --cached --check`: exit `0`;
  - pre-publication staged set: empty.
- Final aggregate changed/untracked paths: eight, all within the original
  nine-path allowlist; `mobile/test/widget_test.dart` remained unchanged.
- Fresh format authority itself wrote only its exact four-path boundary:
  Living Plan production/test plus task/result ledgers.
- Protected/application/domain/storage/schema/migration/bootstrap/platform/
  Inventory/DWG drift: `0`; Inventory PR #536 untouched.
- Invariants: schema `22`, backup format `1`, mobile version
  `0.1.0+1`.
- Build/device/ADB/install/manual acceptance: not run.
- Manual verification remains `PENDING`; stable proposed IDs:
  `MT-545-001` through `MT-545-006`.
- Publication is authorized only as one minimal commit, push and one Draft PR;
  Ready/merge/close remain forbidden. Success stop:
  `FRESH_INDEPENDENT_R4`.

## R4 fail-closed correction authority

- Owner authority: exact current
  `R4_FAIL_CLOSED_VALIDATION_CORRECTION` block supplied in chat.
- Independent disposition: `BLOCKED — R4_CORRECTION_REQUIRED`.
- Reviewed branch/head/PR:
  `codex/issue-545-project-context-core-routes` /
  `3db1363a7e7ed4a1519d9cedda6be0a0a29606d6` / Draft PR `#546`.
- Preflight PASS: local branch, local HEAD and origin branch matched the
  reviewed identity; staged and unstaged tracked sets were empty; no Git
  operation was active.
- Issue #479 comment `5481152018` confirms stable manual tests
  `MT-545-001..006` remain `PENDING`.
- Proven root cause: Daily Log and Materials assigned the supplied
  `initialProjectId` directly to operational selection during `initState`.
  Therefore a failed `listProjects()` left an unvalidated project usable by
  retry or project-bound create UI.
- Exact correction write boundary:
  - `mobile/lib/features/daily_log/daily_log_page.dart`
  - `mobile/lib/features/material_requests/material_requests_page.dart`
  - `mobile/test/project_context_core_routes_widget_test.dart`
  - `.cse/tasks/545_task.md`
  - `.cse/results/545_result.md`
- `mobile/lib/app.dart`, Living Plan production, schema, application, storage,
  platform, Inventory, DWG and all unrelated work remain read-only.
- Correction design: keep operational selection null until successful project
  discovery validates the explicit initial ID; retry discovery after discovery
  failure; retain fail-closed stale-ID behavior, deliberate local recovery and
  legacy first-active fallback.
- Required closure chain: focused gate, regression gate,
  `flutter analyze --no-pub`, changed-Dart format check, full/staged
  `git diff --check`, allowlist/protected-drift and invariant
  `22 / 1 / 0.1.0+1`.
- Publication on all-PASS only: one correction commit, push to existing Draft
  PR #546, exact evidence publication; no Ready, merge or manual-test status
  change. Success stop: `FRESH_INDEPENDENT_R4`.

## R4 fail-closed correction outcome

- Corrected only the two authorized production pages and the focused route
  test:
  - supplied/remembered project ID is now a non-operational validation
    candidate;
  - operational selection is cleared before project discovery and becomes
    non-null only after the returned active options prove the candidate exists;
  - discovery failure leaves project reads and project-bound create UI
    unavailable;
  - retry repeats discovery before any scoped call;
  - valid explicit B, stale explicit recovery, deliberate local override and
    legacy no-initial fallback are preserved.
- A deterministic formatter write targeted exactly the three authorized
  changed Dart files before the final validation cycle.
- Final invalidated closure chain:
  - focused gate: exit `0`, `44/44 PASS`;
  - regression gate: exit `0`, `49/49 PASS`;
  - `flutter analyze --no-pub`: exit `0`, `No issues found`;
  - aggregate changed-Dart format check: exit `0`,
    `6 files / 0 changed`;
  - full and empty-staged `git diff --check`: exit `0`;
  - correction protected drift: `0`;
  - aggregate PR paths: `8/9` original Issue #545 allowlist paths;
  - invariants: schema `22`, backup format `1`, mobile
    `0.1.0+1`.
- `mobile/lib/app.dart` and Living Plan production remained byte-untouched by
  this correction. No schema/application/storage/platform/Inventory/DWG path
  changed.
- APK/AAB/build/device/ADB/install/manual acceptance: not run.
- Issue #479 `MT-545-001..006`: `PENDING`; no PASS was inferred.
- Remaining authorized closure: append result ledger, stage exact five
  correction paths, rerun staged/full diff and drift checks, create one
  correction commit, push existing Draft PR #546, publish exact evidence and
  stop for `FRESH_INDEPENDENT_R4`.
