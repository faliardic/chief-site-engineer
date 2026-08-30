# Issue #540 Task — UI/UX Release Readiness Wave 0

## Authority and starting status

- Parent / V2 program: Epic #539 — CSE UI/UX Release Readiness.
- Current Issue: #540.
- Owner execution authority: Issue #540 comment `5469733323`.
- Authority URL:
  <https://github.com/faliardic/chief-site-engineer/issues/540#issuecomment-5469733323>
- Execution class: `DOCS_READ_ONLY_SOURCE_AUDIT`.
- Implementation status: `IN_PROGRESS`.
- Manual test status: `N/A — documentation/read-only source audit`.
- Official local repository:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`.
- Exact expected base: `a6413025f07cbd48838e2b78a7d2135afa16df69`.
- Local `master`, `origin/master`, and task branch start HEAD:
  `a6413025f07cbd48838e2b78a7d2135afa16df69`.
- Master divergence after fast-forward: `0/0`.
- Branch: `codex/issue-540-ui-ux-release-readiness-wave0`.
- First repository file write: this task record.
- PR #536 / branch `codex/issue-535-inventory-spatial-closure` is deferred,
  is not the execution base, and is not an ancestor of this branch.

## Risk and model routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  orchestrator:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  assistant_reasoning_recommendation: Extra High
  execution_mode: standard
  orchestration: single-agent
  selection_reason: >-
    Broad current-source UI audit plus canonical product-direction truth-sync;
    the task is docs-only but carries R4 source-authority and release-planning
    consistency risk.
  routing_request_evidence: >-
    https://github.com/faliardic/chief-site-engineer/issues/540#issuecomment-5469733323
  allowed_fallback: null
  review_floor:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  runtime_actual_model: unknown
  runtime_actual_reasoning_effort: unknown
  invocation_evidence: null
  invocation_verification_status: unverified
  runtime_verification_status: unverified
  mismatch_detected: null
  fail_closed_if_visible_mismatch: true
```

The execution surface does not expose independently verifiable actual model or
reasoning-effort metadata. Requested values are recorded without inferring
runtime actuals; the next gate remains a fresh independent R4 review.

## Exact-base canonical source manifest

All sources below were read from exact base `a6413025...df69` before this first
file write. The earlier checked-out Inventory branch was not accepted as source
truth: after local `master` was fast-forwarded, exact-base hashes were recomputed
and the changed V2 scope plus the new release-decision record were reread.

| Source | Git blob | SHA-256 |
| --- | --- | --- |
| `AGENTS.md` | `75e218af5813422a08aae08dc9df7d07507169be` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `d2f31def8ee392aab74990766e0a4822be489710` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f83164280277cc1f811448a559ddbfcc78d56040` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `23eb5c4d72ce3858f097292f7fa1d3fb713d3b7e` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `7d099ed4e5a1205320350c663fe659e36f2c4d6a` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `e90612f5ca5bb3f4997110142e24112e246f3b6d` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `b8ce5dd678935e472e1e5351db6c60b6c87238d7` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `af1974ecd2c53ceb67245c8eb1242b03fb1a82ef` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `583663cf0016d5060ed90ec44d1fce8aa16f74a5` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `56c94a2ac509a4af4fbfdf1a6bada57d04ce8c3d` | `7e988d10ce55e147a6e6a197597a458d5e1ac57078ce7d1dcba3a58f294e12bb` |
| `ROADMAP.md` | `c0398a334e966b2eafca8cfe7b0dbe93e455af6b` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |
| `docs/v2/CSE_PRODUCT_RELEASE_DECISIONS_2026-08-30.md` | `2d9f0e57f202e7f8e6e2303d76b27ccff3bac45f` | `7b72b69301f4962b9e944861dd3ec6c1a7fc6d0a803cdfb7d7dbec7ab32b0a0c` |

GitHub/repository truth read before this file write:

- Issue #540 body and its only comment, owner authority `5469733323`;
- parent Epic #539 body and empty comment list;
- open Draft PR #536 at Inventory head
  `7f113fdd111bc0b668b29e2a62ca688cbe1f4590`;
- Issue #479 body and absence of existing `MT-540-*` entries;
- previous Issue #535 task/result as historical evidence only;
- secondary `.cse/state/project_state.json`, confirmed stale and not used to
  override GitHub or exact-master truth.

## Locked baseline and changed contracts

- SQLite schema: exact `22` from `AppDatabase.schemaVersion`.
- Backup format: exact `1` from the mobile backup/recovery codecs.
- Mobile version: exact `0.1.0+1` from `mobile/pubspec.yaml`.
- Changed contract: documentation-only UI/source audit and planning
  truth-sync. No application behavior, source-of-truth, schema, migration,
  backup, version, package, permission, signing, platform, test, or artifact
  contract may change.
- Product direction to reflect:
  `Inventory deferred / device acceptance incomplete -> UI/UX Release
  Readiness current -> Project Dashboard and context/navigation slices next ->
  DWG Viewer later high-priority -> release-readiness closure`.
- Inventory remains a locked eventual release gate under the 30 August owner
  release decisions; deferral of its current development line is neither
  completion nor rejection.

## Exact write allowlist

1. `.cse/tasks/540_task.md`
2. `.cse/results/540_result.md`
3. `docs/v2/CSE_UI_UX_RELEASE_READINESS_AUDIT.md`
4. `ROADMAP.md`
5. `docs/v2/CSE_V2_SCOPE.md`
6. `docs/project_decisions.md`

All other paths are protected and read-only. In particular, every Dart/test,
schema/migration, pubspec/lock, Android/iOS/platform, package/signing,
workflow, asset, generated output, artifact, export, and state path is outside
the write authority.

## Authorized work and required outputs

1. Inspect relevant current-master Flutter production and test source
   read-only to map observed UI behavior.
2. Create `docs/v2/CSE_UI_UX_RELEASE_READINESS_AUDIT.md` with:
   executive summary; shell/navigation map; screen inventory; project-context
   matrix; click-depth findings; component/visual consistency findings;
   state-quality audit; prioritized P0/P1/P2/P3 register; narrow slices; an
   implementation-ready Wave 1 Project Dashboard boundary; deferred/later
   work; and release implications.
3. Distinguish observed current source behavior, locked owner/product
   direction, review recommendations, and future/deferred ideas.
4. Give every P0/P1 finding reproducible source anchors and every finding
   severity, frequency, release impact, implementation risk, recommended wave,
   and predecessor/dependency.
5. Truth-sync `ROADMAP.md`, `docs/v2/CSE_V2_SCOPE.md`, and
   `docs/project_decisions.md` without erasing Inventory history or claiming it
   complete/rejected.
6. Create factual result evidence, validate, make one docs-only commit, push,
   open one Draft PR, and publish Issue/PR evidence.

Wave 1 Dashboard source implementation, Inventory continuation, DWG work,
release work, production data inspection, screenshots/assets, or any
production/test edit is forbidden.

## Validation, test, and build authority

- Validation class: `docs` / `DOCS_READ_ONLY_SOURCE_AUDIT`.
- Source-level checks:
  - exact six-path allowlist;
  - full and staged `git diff --check`;
  - production Dart/test/schema/migration/pubspec/platform diff exactly `0`;
  - schema `22`, backup `1`, version `0.1.0+1` read-only drift audit;
  - exact-base ancestry and absence of Inventory PR commit ancestry;
  - branch/head/staged/worktree/remote divergence evidence.
- Automated application tests: `NOT AUTHORIZED`.
- Flutter analyze: `NOT AUTHORIZED`.
- Flutter formatter: `NOT AUTHORIZED`.
- APK/AAB/build: `NOT AUTHORIZED`.
- Emulator/device/ADB/install/launch: `NOT AUTHORIZED`.
- User production data: must not be inspected or mutated.
- Reused evidence: no runtime behavior claim is needed for this docs-only
  audit; unchanged schema/backup/version/platform contracts are verified only
  for drift.

## Manual tests and artifact authority

- Manual Test Register: Issue #479.
- Manual test IDs: none for this docs/read-only audit.
- Manual test status: `N/A`; no application behavior is implemented.
- Build/artifact authority: none.
- No `PASS` behavior claim may be inferred from this audit.

## Stabilization and immediate escalation conditions

- Primary implementation window: `1`.
- Same-scope narrow documentation corrections: at most `3` under the current
  acceleration protocol, without widening the allowlist or product decision.
- Environment-only recovery: at most `1` after an exact root cause.
- Automated application-test invocations: `0`.
- Stop immediately on exact-base/ancestry uncertainty, unexpected tracked or
  untracked drift, allowlist expansion, required production/test edit, schema/
  migration/backup/version/permission/signing/platform change, destructive
  operation need, source-truth ambiguity, or a new product decision.

## Publication authority

- One minimal docs-only commit: authorized after all source-level gates pass.
- Normal push to `codex/issue-540-ui-ux-release-readiness-wave0`: authorized.
- One Draft PR to `master`, referencing #540 and #539: authorized.
- Concise Issue and PR evidence comments: authorized.
- Manual Test Register write: not required for `N/A` documentation audit.
- Ready: not authorized.
- Merge: not authorized.
- Issue/Epic closure: not authorized.
- Wave 1 / Inventory / DWG / release start: not authorized.
- Next gate: `FRESH_INDEPENDENT_R4`.

## Required completion evidence

The result and final report must separately state exact base/head and changed
paths; audit/truth-sync status; source-level gates; application tests not run;
manual tests `N/A`; artifact absence; schema/backup/version/platform drift;
commit/push/Draft PR state; Ready/merge/closure state; `execution_record`; and
`review_recommendation`.
