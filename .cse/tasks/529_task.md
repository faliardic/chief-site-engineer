# Issue #529 — Transient project diagnostic correction

## Authority and repository truth

- Issue: `#529 — Transient safe diagnostic screen after creating a project`
- Owner authority: `https://github.com/faliardic/chief-site-engineer/issues/529#issuecomment-5463279175`
- Parent / V2 item: Agenda V2 correctness; independent narrow correction while Inventory Slice 6.2 remains out of scope
- Expected and verified base: `30c45d702a90c90a910e0eee39656c452a232b1c`
- Canonical branch: `codex/issue-529-transient-project-diagnostic`
- Starting master/origin divergence: `0/0`
- Starting tracked worktree: clean
- Publication authority: one OPEN/DRAFT PR only
- Ready / merge / Issue close / Slice 6.2: not authorized

## Risk and execution routing

- Risk: `R4`
- Requested model: `gpt-5.6-sol`
- Requested reasoning effort: `max`
- Assistant recommendation: `Extra High`
- Runtime model / effort visibility: `unknown / null / unverified`
- Execution topology: single-agent
- Stabilization window: one Phase A reproduction, one narrow Phase B correction, no scope expansion

## Changed contract

Successful Agenda project creation must never publish a selected project ID
before that ID exists in the freshly loaded project items. Create-triggered and
`projectChanges`-triggered reloads must not let an older reload overwrite the
newer coherent selection/query state. Genuine global fatal/error handling is
unchanged.

## Exact write allowlist

1. `.cse/tasks/529_task.md`
2. `.cse/results/529_result.md`
3. `mobile/lib/features/agenda/agenda_page.dart`
4. `mobile/test/agenda_page_test.dart`
5. `mobile/test/support/fake_agenda_application.dart`

Read-only protected paths include `mobile/lib/main.dart` and
`mobile/lib/app.dart`. Schema, migration, backup, package, pubspec/dependencies,
platform, manifest, signing, permission, version and unrelated production paths
must have drift `0`.

## Canonical source manifest

| Source | SHA-256 |
| --- | --- |
| `AGENTS.md` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `4bbbdac92cc716c321701358f701ec284f1dfab1dc2461b334ac6e288d6f10cc` |
| `ROADMAP.md` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |

GitHub source truth at task start:

- Issue #529: OPEN
- authority comment author association: OWNER
- open PRs: none
- Manual Test Register #479: no existing `MT-529` entry

## Phase A — deterministic reproduction before production correction

- Add only the minimum fake gate/delay and widget harness.
- Do not edit `agenda_page.dart` before the reproduction result.
- Run exactly one reproduction invocation:
  `flutter test --no-pub test/agenda_page_test.dart --plain-name "project creation exposes transient invalid dropdown before delayed reload"`
- Capture exact Flutter exception type/message and relevant stack/source frame.
- Prove whether this is a framework/widget-render failure caused by the project
  dropdown state; record that no global fatal notifier clearing is used.
- If the current unfixed source does not reproduce deterministically, stop with
  evidence and make no production correction.

## Phase B — narrow correction

- Resolve a preferred/requested project ID only against a freshly loaded project list.
- Reject stale overlapping reload publication deterministically.
- Keep Agenda query and selected project coherent.
- Do not suppress ErrorWidget/framework failures or modify global fatal handling.
- Preserve all unrelated Agenda behavior.

## Authorized validation budget

After Phase B formatting of touched Dart paths:

1. Exactly one final focused invocation:
   `flutter test --no-pub test/agenda_page_test.dart test/widget_test.dart`
2. If focused PASS, exactly one `flutter analyze --no-pub` invocation.
3. Full and staged `git diff --check`.
4. Exact allowlist and protected drift audit.
5. Verify schema `22`, backup format `1`, version `0.1.0+1`.
6. Verify package/pubspec/dependency/platform/permission drift `0`.

No other Flutter tests, retry, full suite, build, APK, device, emulator, ADB or
MAIN operation is authorized.

## Manual acceptance

- Proposed stable register item: `MT-529-001 — Project create transient diagnostic regression`
- Owner action: create and name a project; observe the full transition and refresh.
- Expected: no safe diagnostic surface; the new project appears once and remains selected with coherent Agenda data.
- Status at task start: `PENDING / NOT RUN`
- Automated evidence must not be reported as owner/manual PASS.

## Immediate stop conditions

- Phase A does not reproduce the exact exception.
- Required path falls outside the allowlist.
- Root cause requires `main.dart`, `app.dart`, global fatal suppression, schema,
  migration, dependency, package, permission or platform change.
- Any authorized no-retry test/analyzer invocation fails after its allowed use.
- Destructive Git/data operation or owner-phone access becomes necessary.

## Publication boundary

If all gates pass: append result evidence, stage the exact allowlist, create one
minimal commit, push the canonical branch, open one Draft PR referencing #529,
publish Issue/PR evidence and stop for fresh independent R4 review. Do not mark
Ready, merge, close the Issue, declare field acceptance or start Slice 6.2.
