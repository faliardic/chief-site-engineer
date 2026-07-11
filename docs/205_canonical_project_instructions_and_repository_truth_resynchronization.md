# Step 205 - Canonical Project Instructions and Repository Truth Resynchronization

## Purpose

Step 205 makes the current CSE operating instructions available as a tracked repository document and aligns the repository's principal truth-bearing records with the Step 204 squash merge. This is documentation/state-only work; it does not change production, test, workflow, or product behavior.

## Why a Tracked Canonical Instruction File Is Required

The official local working copy may contain a high-priority local-only execution source needed to coordinate safe work. That source is intentionally excluded from commits, so a fresh clone or handoff cannot rely on its presence. A tracked canonical copy at `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` preserves the current operating contract for future clones, reviewers, and handoffs while the root source remains private to the official local environment.

The canonical file was initially derived from `CSE_GUNCEL_PROJE_TALIMATLARI.md`, with persistent product/protocol meaning and section order preserved. It is now intentionally adapted so Section 4 provides tracked fallback authority for fresh clones/handoffs, Section 17 records the current Step 204/Step 205 state, and the ChatGPT/GitHub/Codex operating rule is explicit. Because of those reviewable adaptations, the repository does not claim equal SHA, equal line count, or complete normalized-text equivalence. The local-only source remains byte/hash unchanged, ignored through `.git/info/exclude`, unstaged, and uncommitted.

## Local Execution Source and GitHub Review Surface

Execution happens in `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`. Branch creation, project-file edits, verification, commit, and push occur in that official local repository. GitHub Issue #25 defines scope and accepts completion evidence; GitHub remains the synchronized coordination/review surface. The user normally sends a short continuation command, ChatGPT verifies GitHub state and performs GitHub-native actions, and Codex is invoked only for required local execution. GitHub-only project-file creation is not completion.

## Corrected Repository Truth

Step 205 corrects stale current-state records that still described Step 127, `243 passed`, or the pre-merge Step 203/Step 204 branch state. The synchronized facts are:

- Latest merged/finalized safe point: Step 204.
- Step 204 squash-merge commit: `7e5a06ed3cb62399219f9ad66b6b2b8e6eca77a3`.
- PR #24: merged.
- Issue #23: completed.
- Current local tests: `413 passed` or the factual Step 205 verification result.
- Step 205: active documentation/state synchronization branch until merged.

## CI and Actions State

The repository contains `.github/workflows/pytest.yml`. Automatic GitHub Actions execution is manually disabled because of the account billing/runner-start constraint. The workflow is not re-enabled or changed by this step, and required status checks remain disabled. Local pytest, diff checks, protected-path checks, scope checks, and Git divergence provide the completion evidence.

## Current Product Maturity

CSE is a tested domain/data/documentation core, not a field-ready application. It still lacks production persistence/database behavior, real file upload, API, GUI, authentication/authorization, deployment, and a complete backup/restore flow. Existing in-memory/domain helpers and documentation should not be presented as those missing production capabilities.

## Next Field-MVP Direction

After repository truth synchronization, the next product direction is the first narrow field MVP:

- fast observation record,
- attachment,
- location,
- status tracking,
- reported-to,
- daily export,
- weekly summary.

The governing product rule remains: reliable data backbone first, automation later, AI last. Podcast 031 is the natural documentation follow-up for Steps 201-205 after Step 205 merges.

## Boundaries and Exclusions

Step 205 does not add production code, executable tests/fixtures, workflow changes, Actions enablement, required checks, API/GUI/CLI behavior, persistence/database/repository behavior, audit behavior, backup/restore or migration behavior, hard validation, generated `blocked`, export output, ZIP mutation, automatic decisions, official transfer decisions, or package blocking. It does not open or merge a PR and does not begin Step 206 or product implementation.
