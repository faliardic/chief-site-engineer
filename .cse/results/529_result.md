# Issue #529 — Execution evidence

## Starting state

- Exact base: `30c45d702a90c90a910e0eee39656c452a232b1c`
- Branch: `codex/issue-529-transient-project-diagnostic`
- Starting master/origin divergence: `0/0`
- Starting tracked worktree: clean
- First repository content write: `.cse/tasks/529_task.md`
- Risk/model request: `R4 / gpt-5.6-sol / max`
- Runtime model/effort visibility: `unknown / null / unverified`
- Production source before Phase A: untouched

## Phase A — deterministic unfixed-source reproduction

Invocation budget used: `1/1`.

```text
flutter test --no-pub test/agenda_page_test.dart --plain-name "project creation exposes transient invalid dropdown before delayed reload"
```

Owner symptom reproduction: `PASS` — the delayed post-create project-list
refresh rendered the same `SafeDiagnosticPanel(code: widget_render_error)`
path and exposed the exact Flutter framework failure.

Exact exception:

```text
_AssertionError
There should be exactly one item with [DropdownButton]'s value: f1cec986-fab1-4c7e-b02d-be809fb452a3.
Either zero or 2 or more [DropdownMenuItem]s were detected with the same value
'package:flutter/src/material/dropdown.dart':
Failed assertion: line 1852 pos 10: 'items == null ||
             items.isEmpty ||
             (initialValue == null && value == null) ||
             items
                     .where((DropdownMenuItem<T> item) => item.value == (initialValue ?? value))
                     .length ==
                 1'
```

Relevant stack:

```text
#2 new DropdownButtonFormField (package:flutter/src/material/dropdown.dart:1852:10)
#3 _AgendaPageState.build (package:chief_site_engineer/features/agenda/agenda_page.dart:405:13)
#25 main.<anonymous closure> (mobile/test/agenda_page_test.dart:40:22)
```

Classification: transient Flutter widget-render/framework assertion caused by
publishing the newly created project ID while the project dropdown still owns
the pre-create item list. The harness used the same
`SafeDiagnosticPanel(code: widget_render_error)` builder behavior as
`main.dart`; neither `main.dart`, `app.dart` nor a global `fatalErrors` notifier
was mutated or cleared.

The reproduction process exited `1` only because its temporary
`ErrorWidget.builder` was restored in `addTearDown`, after the Flutter test
binding's own builder-integrity check. The target owner exception and stack had
already been captured exactly. No reproduction retry was run. The final
regression restores the builder synchronously with `try/finally`.

## Remaining authorized gates

- Final focused invocation: `0/1`
- Analyzer invocation: `0/1`
- Build/APK/device/ADB/MAIN: `NOT AUTHORIZED / NOT RUN`
- Manual `MT-529-001`: `PENDING / NOT RUN`

## Phase B — narrow correction

- `AgendaPage._createProject()` no longer publishes the new project ID into
  widget state before refreshing the project list.
- `_reload(preferredProjectId: ...)` keeps the create preference outside the
  rendered selection, resolves it only against the returned fresh project
  items, and uses that same resolved ID for `AgendaQuery`.
- A monotonic reload generation is checked after each async boundary. An older
  overlapping `projectChanges` refresh cannot issue a later stale query or
  overwrite the newer project/items/log state.
- A preferred ID absent from a returned list resolves to `null`, so every
  rendered dropdown value remains a member of its current items.
- Global ErrorWidget/fatal handling was neither changed nor suppressed.

## Final focused validation

Authorized final invocation used: `1/1`.

```text
flutter test --no-pub test/agenda_page_test.dart test/widget_test.dart
```

Result: `PASS — 13/13`.

The real project-create dialog regression proved:

- both create and `projectChanges` reloads were pending while the dropdown
  remained valid with a `null` value;
- no `SafeDiagnosticPanel` and no Flutter exception appeared;
- the new project became selected only after the fresh response contained
  exactly one matching item;
- the final Agenda query used the new project ID;
- completing the older stale pre-create response afterward did not change the
  selected project, project items or final Agenda query.

Existing `widget_test.dart` safe bootstrap/fatal diagnostic coverage remained
PASS. No additional Flutter test invocation was run.

## Static and scope validation

- Touched Dart formatting: `PASS`
- `flutter analyze --no-pub`: `1/1`, `PASS — No issues found!` (`36.1s`)
- Full `git diff --check`: `PASS`
- Exact changed-path allowlist: `5/5`
- Outside-allowlist drift: `0`
- `mobile/lib/main.dart` / `mobile/lib/app.dart` drift: `0`
- Schema: `22`, unchanged
- Backup format: `1`, unchanged
- Mobile version: `0.1.0+1`, unchanged
- `pubspec.yaml` / `pubspec.lock` / dependency drift: `0`
- Android/iOS/package/platform/permission/signing/manifest drift: `0`
- Starting/current pre-commit base divergence from `origin/master`: `0/0`
- Build/APK/device/emulator/ADB/MAIN: `NOT RUN`
- Ready/merge/Issue close/Slice 6.2: `NOT PERFORMED`
- `MT-529-001`: `PENDING / NOT RUN`

## Execution record

```yaml
execution_record:
  issue: 529
  authority_comment: 5463279175
  exact_base: 30c45d702a90c90a910e0eee39656c452a232b1c
  branch: codex/issue-529-transient-project-diagnostic
  risk: R4
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: max
  runtime_model: unknown
  runtime_reasoning_effort: null
  runtime_verification: unverified
  implementation_status: IMPLEMENTED
  reproduction:
    invocation_count: 1
    owner_symptom_reproduced: true
    exception_type: _AssertionError
    source: agenda_page.dart:405 -> dropdown.dart:1852
  final_focused:
    invocation_count: 1
    result: PASS
    tests: 13/13
  analyzer:
    invocation_count: 1
    result: PASS
  schema: 22
  backup_format: 1
  mobile_version: 0.1.0+1
  build_or_device_operation: false
  manual_test_status: PENDING
  publication_authority: DRAFT_PR_ONLY
  ready: false
  merge: false
review_recommendation: FRESH_INDEPENDENT_R4_REVIEW
```
