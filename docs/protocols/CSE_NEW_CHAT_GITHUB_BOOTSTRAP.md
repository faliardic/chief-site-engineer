# CSE New Chat GitHub Bootstrap

**Repository:** `faliardic/chief-site-engineer`
**Default branch:** `master`
**Official local execution repository:** `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

This document defines how a new CHIEF SITE ENGINEER chat resumes the project from GitHub without requiring uploaded ZIP or handoff packages.

## Fresh-Chat Read Order

For a fresh ChatGPT conversation, read current GitHub repository truth in this order:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. `.cse/state/project_state.json`
4. the latest open GitHub Issue and relevant recent PR/merge state
5. the active `.cse/tasks/<step>_task.md` and relevant `.cse/results/<step>_result.md`

## Continuation Behavior

The user should normally be able to open a new chat and say only:

```text
devam
```

or:

```text
GitHub'dan devam et
```

ChatGPT must inspect the GitHub repository and current Issue/PR state before proposing or taking the next action.

## No ZIP or Handoff Upload Required

No handoff ZIP, source ZIP, copied prompt block, or manually pasted status report is required for normal continuation.

`chat_handoff/` remains optional and historical. It is never required to resume the project.

Existing ignored ZIP files remain emergency/offline backup artifacts only. They are not new-chat dependencies.

If GitHub is temporarily unavailable, ChatGPT must not silently fall back to stale ZIPs, stale memory, or old handoff text. It must state that current repository truth cannot be verified and wait or request an explicit alternative source.

Uploaded or local source files may be used to establish or update tracked canonical sources in an authorized step. Once tracked and merged, future chats read the GitHub versions.

## GitHub and Local Execution Surfaces

GitHub is the current coordination and repository-truth surface for:

- Issues
- PRs
- branch state
- merge state
- source review
- continuation decisions

The official local `V:` repository is the local execution surface when Codex is required for:

- local file edits,
- tests and validation,
- ignored-file or ZIP inspection,
- path/hash/worktree checks,
- branch checkout,
- commit and push.

## Codex Invocation Rule

ChatGPT decides whether Codex is needed.

When local execution is needed, ChatGPT explicitly tells the user:

```text
Codex çalışmalı
```

and briefly states why.

When the next action is GitHub-native inspection, planning, issue/PR/comment/review/merge-state work, web research, or conceptual analysis, Codex is normally not required.

## Codex Pre-Read Alignment

Codex's required pre-read remains:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. the current GitHub Issue
4. `.cse/tasks/<step>_task.md`

Codex should also read this bootstrap document when the current task concerns workflow, handoff, bootstrap, source authority, or new-chat recovery.
