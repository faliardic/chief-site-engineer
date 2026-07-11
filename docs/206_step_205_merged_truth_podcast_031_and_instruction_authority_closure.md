# Step 206 - Step 205 Merged Truth, Podcast 031, and Instruction Authority Closure

## Purpose

Step 206 closes documentation, state, podcast, and instruction-authority gaps after the Step 205 squash merge. It does not add product behavior.

The updated safe point is:

```text
Step 205
PR #26 merged
Issue #25 completed
Merge commit: 92a15f2a55e6bfda42d50b8ef7dea651ff496f62
Local verification baseline: 413 passed
```

The active work during this branch is:

```text
Issue #28
Step 206
Branch: step-206-podcast-031-and-authority-closure
Scope: documentation/state/protocol only
```

Step 206 must not claim that Step 206 itself is merged.

## Instruction Authority Closure

Before this step, the root local-only instruction file and the tracked canonical instruction file created a dual-authority risk. Step 206 resolves that risk by making the tracked canonical file the single authoritative project instruction source:

```text
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
```

The root file is no longer a higher-priority override:

```text
CSE_GUNCEL_PROJE_TALIMATLARI.md
```

It is only an optional local convenience mirror. When present, it must match the tracked canonical file exactly. It remains ignored through `.git/info/exclude`, unstaged, and uncommitted.

This preserves a readable local mirror without making fresh clones, handoffs, or future agents depend on an ignored root file.

## Hardened Official Workspace Rule

Step 206 strengthens the official local repository rule. Every Codex execution must start in the official local path:

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'
```

It must also verify the actual Git root:

```powershell
$expected = (Resolve-Path 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer').Path
$actual = (git rev-parse --show-toplevel)

if ((Resolve-Path $actual).Path -ne $expected) {
    throw 'Wrong repository root. Stop without changing anything.'
}
```

If the path differs, Codex must stop before any Git operation or file write.

The project must not create or use an automatic `C:` clone/workspace for CSE. Instructions and completion evidence are exchanged through the current GitHub Issue while execution remains in the official `V:` repository.

## Podcast 031

Step 206 adds:

```text
docs/podcast_notes/031_adim_201_205_notebooklm_podcast_notu.md
```

Podcast 031 covers only Steps 201-205:

- Step 201: Podcast 030 for Steps 196-200.
- Step 202: canonical handover QC view-model examples and wording.
- Step 203: mandatory official local working copy and synchronization protocol.
- Step 204: canonical fixture naming and assertion checklist plan.
- Step 205: canonical tracked instructions, repository-truth resynchronization, GitHub-centered continuation workflow, and first field-MVP direction.

It preserves the established boundaries:

- read-only / non-blocking handover semantics,
- no generated `blocked`,
- no automatic acceptance, rejection, approval, or package decision,
- official-transferable versus private/non-transferable separation,
- Actions disabled because of the account billing / runner-start constraint,
- CSE is still not field-ready.

## Podcast Protocol Refresh

`docs/podcast_notes/README.md` no longer contains obsolete Step 022-era current-state text.

It now records durable cadence plus factual podcast state:

- Podcast 030 covers Steps 196-200.
- Podcast 031 covers Steps 201-205.
- The next five-step range begins with Step 206.

Current active work should be read from `README.md`, `.cse/state/project_state.json`, `ROADMAP.md`, and the current GitHub Issue rather than from stale examples inside the podcast protocol.

## Repository Truth Updates

Step 206 updates these truth-bearing records so they no longer present Step 204 as the current safe point or Step 205 as active work:

- `README.md`
- `.cse/state/project_state.json`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`

During the branch, they present Step 206 as active work without claiming a Step 206 merge.

## Local Archive Risk

The misspelled workspace path is treated as user-reported removed and locally verified absent during preflight:

```text
C:\Users\Fatih\Documents\chieh-site-engineer
```

This is not Git history; it is local execution evidence.

The following separate repository remains an unresolved, non-blocking local archive item:

```text
C:\Users\Fatih\Desktop\fatih\chief-site-engineer
```

Known prior state:

- no canonical origin remote,
- deleted interim podcast note path,
- untracked final `005_adim_021_025_notebooklm_podcast_notu.md`.

The canonical GitHub repository already contains:

```text
docs/podcast_notes/005_adim_021_025_notebooklm_podcast_notu.md
```

However, exact local-content identity for the Desktop repository has not been proven. Step 206 does not delete, overwrite, commit, move, or otherwise mutate that Desktop repository.

## Boundaries

Step 206 does not add production code, executable tests/fixtures, workflow behavior, Actions enablement, required checks, API/GUI/CLI, persistence/database/repository behavior, audit, backup/restore, migration, hard validation, generated `blocked`, export output, ZIP mutation, Desktop archive mutation, Step 207, or field-MVP implementation.
