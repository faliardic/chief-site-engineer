# Step 207 - Codex Invocation and Batched Execution Policy

## Purpose

Step 207 adds the unified project source, source register, GitHub-native new-chat bootstrap, and permanent Codex invocation / batched execution policy.

This is documentation/state/protocol work only. It does not start field-MVP implementation.

## Latest Safe Point and Active Work

Latest merged/finalized safe point:

```text
Step 206
PR #29
Issue #28
Merge commit: 3b05fae76766cedc8840eea6c0fc2f51440354e4
```

Active unmerged work:

```text
Step 207
Issue #30
Branch: step-207-codex-invocation-policy
```

## Unified Project Source

Step 207 creates:

```text
docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md
```

It is created from the approved local project source:

```text
V:\1_PROJECTS\2_ACTIVE\Python\CHIEF_SITE_ENGINEER_EXE_BIRLESTIRILMIS_PROJE_KAYNAGI.md
```

The approved source content is preserved. It is not reconstructed from memory, shortened, or silently rewritten.

This unified source is authoritative for:

- product purpose,
- strategy,
- data principles,
- product layers,
- roadmap,
- source-conflict resolutions,
- long-term architecture.

## Operational Instructions

The operational source remains:

```text
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
```

It is authoritative for:

- Git and GitHub rules,
- Codex execution rules,
- safety,
- verification,
- local repository workflow,
- commit/push protocol.

## Source Register

Step 207 creates:

```text
docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md
```

The register records the approved source set, copied reference files, unavailable originals, and source handling rules.

Only genuinely accessible sources are copied into:

```text
docs/reference_sources/
```

Accessible sources copied in Step 207:

```text
docs/reference_sources/chief_site_engineer_exe_birlestirilmis_proje_kaynagi.md
docs/reference_sources/cse_once_guvenilir_veri_omurgasi.txt
```

Unavailable sources are recorded as unavailable. Their content is not fabricated.

Raw handoff ZIP packages are not committed.

## New-Chat GitHub Bootstrap

Step 207 creates:

```text
docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md
```

New chats must bootstrap from GitHub, not from uploaded ZIP or handoff packages.

Fresh-chat read order:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. `.cse/state/project_state.json`
4. latest open GitHub Issue and relevant recent PR/merge state
5. active `.cse/tasks/<step>_task.md` and relevant `.cse/results/<step>_result.md`

The user can normally say:

```text
devam
```

or:

```text
GitHub'dan devam et
```

ChatGPT must inspect GitHub repository truth before proposing the next action.

## Codex Invocation Policy

ChatGPT decides whether Codex is required.

When local execution is needed, ChatGPT explicitly says:

```text
Codex çalışmalı
```

and briefly explains why.

Codex is required for:

- local project-file creation or editing,
- local tests, scripts, validation, hashes, ignored-file, ZIP, export, path, or worktree inspection,
- local branch creation or switching,
- stage, commit, push,
- local error resolution,
- local `master` synchronization before the next local change,
- operations GitHub cannot safely perform.

Codex is normally not required for:

- planning, reasoning, architecture, prioritization, summaries, or recommendations,
- GitHub Issue/PR/diff/comment/review/merge-state inspection,
- GitHub Issue/comment creation,
- Draft PR creation after a branch is already pushed,
- ready transition, review, or squash merge,
- web research or conceptual analysis,
- reporting GitHub state when no local evidence is needed.

## Batched Execution

Default model:

```text
1 technical step = 1 primary Codex run
blocking correction = at most 1 correction run
post-merge sync = batch into the next Codex-required run when safe
```

Non-blocking wording issues, metadata observations, or small comments should not produce fragmented Codex runs. They are accumulated into the next relevant consolidated local execution unless PR review, merge safety, tests, or repository truth are blocked.

## Metadata Churn Avoidance

Do not create an extra Codex run or commit solely so a result/state file can contain the SHA of the commit that contains that same record.

Final branch-head SHA and divergence may be recorded in:

- GitHub Issue completion comments,
- PR metadata,
- review notes.

A second metadata commit is required only for a real contradiction, unsafe state, or blocking omission.

## Mandatory Codex Pre-Read

Every Codex execution must begin by reading:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. current GitHub Issue
4. `.cse/tasks/<step>_task.md`

Workflow, handoff, bootstrap, or source-authority tasks also require reading:

```text
docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md
```

Codex must stop before edits when a required tracked source is missing or the current task contradicts an unresolved permanent rule.

## Boundaries

Step 207 does not add production code, executable tests/fixtures, workflow behavior, Actions enablement, required checks, API/GUI/CLI implementation, persistence, audit, backup/restore, migration, hard validation, generated `blocked`, export output, ZIP mutation, Desktop archive mutation, raw ZIP package commit, replacement handoff ZIP, Step 208, or field-MVP implementation.
