# Issue #490 — Deterministic person/company suggestions

## Authority and execution

- Repository: `faliardic/chief-site-engineer`
- Issue: `#490 — CSE V2.9 Slice 1: deterministic person/company suggestions + reusable suggestion boundary`
- Owner authority: `https://github.com/faliardic/chief-site-engineer/issues/490#issuecomment-5424638045`
- Official repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Isolated linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-490-context-suggestions-v1`
- Expected base/master: `ffff4010499bb8c31cbe4679cd2e0e4c5f2816fc`
- Branch: `codex/issue-490-context-suggestions-v1`
- Parent Epic: `#385`
- V2 item: `V2.9 Slice 1`
- Validation class: `domain`, constrained by owner-led manual testing
- Policy version: `CSE-MRP-1.0`
- Task risk: `R4`

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R4"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "max"
  assistant_reasoning_recommendation: "xhigh"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "Cross-module deterministic read boundary with strict project isolation and no-mutation requirements."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/490#issuecomment-5424638045"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Runtime model/effort metadata is not exposed. Actual values will not be
inferred.

## Canonical source manifest

| Source | SHA-256 | Lines |
| --- | --- | ---: |
| `AGENTS.md` | `BB00551CAECBD2C19AF6CCFF0FE9C93ACFA71AADE05288B303F6006BE0BE616D` | 306 |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899A8FE03E8AB7CA8CE204DDF7A271686BDA0668B08A828645649495539E333` | 1365 |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `F2C00B649CD1DCEB19DC0BD1D284713138DBFBD8EE3332B9581AFD107A0C20D5` | 638 |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `E1F55336657ECD79CB68CBAE458341A811F0BB33867AC06B71163A5A8C8C320B` | 185 |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `C12A57885F31144DC15CBBD3A07AB59527489A533CE5D8B444664ECF7710440D` | 328 |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765BCEBFB7B25B12E60FB44767D49C9D537393786FA0026561E1593073D297D` | 334 |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `ACF77C5088BE704519230D087D9426772FE62C0DFD4A6BA6FE33A4626FAC5041` | 201 |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `F96FC9B1EF8BD12A6A4515A707726D84EE9A86A1A28BF6F20C5217E2954212CB` | 96 |
| `docs/v2/CSE_V2_SCOPE.md` | `94252C456618452B075E10DE7BF27758C9E8FEFFA878BDF1D264FA2C8AC14053` | 522 |
| `ROADMAP.md` | `D7533E0DC4463517CA370DB244ECCEABF11F87DE339FB30D19199A4F8101F9F7` | 412 |

Current Issue/authority and GitHub repository state override stale factual
snapshots inside canonical documents.

## Preflight

- Official master fast-forwarded to exact `origin/master`: PASS.
- Exact isolated worktree root: PASS.
- Exact branch: PASS.
- HEAD/base/origin master: `ffff4010499bb8c31cbe4679cd2e0e4c5f2816fc`.
- Clean worktree before first edit: PASS.
- Staged paths: `0`.
- Open PRs before implementation: `0`.
- Existing `MT-490-*` register entries: `0`.
- Phone connection required: no.

## Changed contract

Add a reusable, read-only deterministic suggestion boundary and its first
consumer in `ReminderFormPage`:

- active `workforce_members` people from the exact selected project;
- active `subcontractors` companies from the exact selected project;
- optional exact-string `follow_up_items.related_person` history with explicit
  historical provenance only;
- bounded, deterministic query/ranking;
- exact stored display text;
- source kind, source identity/project and explainable reason signals;
- suggestion selection changes only the existing form controller;
- existing Reminder Save remains the only mutation boundary;
- read failures/empty results do not block capture.

No project means no project-scoped directory suggestion. No canonical reusable
tag source has been established; `tag_source_unavailable` is the normal Slice 1
result.

## Initial exact allowlist

1. `mobile/lib/domain/context_suggestion_models.dart`
2. `mobile/lib/application/context_suggestion_application.dart`
3. `mobile/lib/bootstrap/app_bootstrap.dart`
4. `mobile/lib/features/reminders/reminder_form_page.dart`
5. `mobile/lib/app.dart` — only if wiring requires it
6. `ROADMAP.md`
7. `docs/v2/CSE_V2_SCOPE.md`
8. `docs/project_decisions.md`
9. `CHANGELOG.md`
10. `.cse/tasks/490_task.md`
11. `.cse/results/490_result.md`

Read-only reference inspection is allowed for database, workforce and
Agenda/Reminder source. If a further production wiring path is concretely
required, the exact compile/wiring reason must be written to Issue evidence
before editing it. Schema/backup/version/platform/pubspec edits require owner
escalation.

## Prohibited scope

- No schema/migration or persistent suggestion state.
- No backup/restore, dependency, platform or notification semantic change.
- No person/company/tag invention or automatic creation.
- No cross-project/private leakage, cloud/AI/LLM, embeddings or telemetry.
- No role/team/specialty/category reinterpretation as tags.
- No Reminder lifecycle, Save or notification mutation change.
- No Flutter unit/widget/integration/full tests.
- No APK/AAB build, emulator, ADB/device or scripted acceptance.
- No Ready, merge, Issue close, V2.9 Slice 2 or V2.10 work.

## Source-level gates

1. Format touched Dart files only.
2. Exactly one final `flutter analyze --no-pub`.
3. Exact changed-path allowlist and source-diff review.
4. `git diff --check`.
5. Schema exactly `18`.
6. Backup format exactly `1`.
7. Version exactly `0.1.0+1`.
8. `pubspec.yaml`/`pubspec.lock` drift `0`.
9. Android/iOS/platform-production drift `0`.
10. No unexpected persistent write/mutation path.

Analyzer or scope failure is fail-closed; no self-authorized retry or allowlist
expansion.

## Manual verification and publication

- Manual Test Register: `https://github.com/faliardic/chief-site-engineer/issues/479`
- Stable `MT-490-*` items will cover person/company sources, deterministic
  ordering, project isolation, select-versus-save boundary, empty/failure
  fallback and relaunch/no-persistence behavior.
- Manual test status: `PENDING`.
- Automated application tests: disabled by exact owner authority.
- Build/artifact authority: none.
- Implementation status target: `IMPLEMENTED — MANUAL TEST PENDING`.
- PASS publication authority: one intentional commit, normal push and one Draft
  PR against master.
- Stop for independent ChatGPT source/diff review; no Ready or merge.

## Pre-edit wiring consequence

Read-only inspection proved that the primary Reminder capture constructs
`ReminderFormPage` inside
`mobile/lib/features/reminders/reminders_page.dart`; `app.dart` only constructs
`RemindersPage`. Passing the authorized suggestion dependency from bootstrap to
the first consumer therefore requires this one additional wiring path.

- Issue evidence: `https://github.com/faliardic/chief-site-engineer/issues/490#issuecomment-5424770963`
- Added wiring-only path:
  `mobile/lib/features/reminders/reminders_page.dart`
- Effective maximum allowlist: original `11` paths plus this path = `12`.
- No schema/backup/version/platform/pubspec or Reminder mutation authority is
  added.

## Implementation and source-gate record

- Implemented a reusable `ContextSuggestionApplication` with a read-only
  SQLite operation on the shared `MobileOperationCoordinator`.
- Canonical candidates are active exact-project `workforce_members` people and
  active exact-project `subcontractors` companies. Exact-project nonblank
  `follow_up_items.related_person` history is secondary only and retains
  historical provenance.
- Ranking is bounded and deterministic: match quality, canonical-source
  priority, safe project-local usage/recency, normalized display, source kind
  and stable source identity/value.
- Reminder first-consumer wiring reaches the main Reminder capture route.
  Selection updates only the existing related-person controller; existing Save
  remains the only mutation boundary. Empty/read-failure results remain silent
  and non-blocking.
- Canonical reusable tag identity was not found. Slice 1 records
  `tag_source_unavailable` as the normal product boundary and does not invent a
  tag system.

Source-gate execution:

- Initial PATH did not expose `dart`; that formatting attempt made no write.
  Repository-recorded bundled Dart SDK then formatted exactly the six touched
  Dart files.
- Fresh-worktree metadata prep: `flutter pub get --offline` PASS;
  `pubspec.yaml` SHA-256 remained
  `704EE4A64B534D14264984F68B8275570B8F87C06190EE48340830D971EABFA7` and
  `pubspec.lock` SHA-256 remained
  `2B75E59A051A8CFCFEC3D6883B04779205C63678B0F4814A4535E50DB77DC441`.
- Exactly one final `flutter analyze --no-pub`: PASS, `No issues found`.
- Pre-evidence `git diff --check`: PASS.
- Exact base: `ffff4010499bb8c31cbe4679cd2e0e4c5f2816fc`.
- Schema `18`, backup format `1`, version `0.1.0+1`: PASS.
- Pubspec/lock drift `0`; Android/iOS platform-production drift `0`.
- Unexpected/protected changed path `0`; staged path `0`.
- New suggestion application write-SQL/mutation token audit: `0`.
- Flutter unit/widget/integration/full tests: not run by owner authority.
- APK/AAB build, emulator, ADB/device and scripted acceptance: not run.

Manual Test Register plan for Issue #479:

- `MT-490-001..010`: `PENDING`.
- Coverage: active person; active company; historical provenance; deterministic
  bounded ordering; project/no-project isolation; select-versus-Save boundary;
  free text; empty/read-failure fallback; archived exclusion; relaunch/no
  suggestion persistence.

Publication classification: `IMPLEMENTED — MANUAL TEST PENDING`.
Publication target is one intentional commit, normal push and one Draft PR;
commit SHA and PR URL are necessarily recorded on GitHub after this
self-containing evidence commit is created.
