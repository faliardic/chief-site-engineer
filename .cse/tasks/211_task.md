# Step 211 Task

## Objective

Create Podcast 032 as the NotebookLM source note for Steps 206-210 and update repository truth after the Step 210 merge.

This is documentation/state/podcast work only. It must not add product behavior, code changes, executable tests, or begin Step 212.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `c7dbd94076f9e23c928f27ea377a97debad6636b`
- Latest merged safe point: Step 210 / PR #37 / Issue #36
- Working branch: `step-211-podcast-032-steps-206-210`
- Codex reasoning: High
- ChatGPT review: High

## Required Pre-Read

Before edits, read in order:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #38
4. `.cse/tasks/211_task.md`

Also read before writing the podcast note:

- `docs/podcast_notes/README.md`
- `docs/podcast_notes/031_adim_201_205_notebooklm_podcast_notu.md`
- `docs/206_step_205_merged_truth_podcast_031_and_instruction_authority_closure.md`
- `docs/207_codex_invocation_and_batched_execution_policy.md`
- `docs/208_first_field_mvp_observation_record_contract.md`
- `docs/209_field_observation_record_model_implementation.md`
- `docs/210_field_observation_repository_baseline.md`
- `.cse/results/206_result.md`
- `.cse/results/207_result.md`
- `.cse/results/208_result.md`
- `.cse/results/209_result.md`
- `.cse/results/210_result.md`

If a required tracked source is missing or an unresolved permanent-rule conflict is found, stop before edits.

## First Action - Post-Merge Synchronization

Work only in the official `V:` repository. Inspect the worktree without reset, clean, stash, delete, move, rename, or overwrite. Then:

```powershell
git fetch origin --prune
git checkout master
git pull --ff-only origin master
```

Required before branch creation:

```text
master = origin/master = c7dbd94076f9e23c928f27ea377a97debad6636b
divergence = 0 0
```

Verify `C:\Users\Fatih\Documents\chieh-site-engineer` remains absent. Do not touch `C:\Users\Fatih\Desktop\fatih\chief-site-engineer`. Then create `step-211-podcast-032-steps-206-210` locally.

## Podcast File

Create:

```text
docs/podcast_notes/032_adim_206_210_notebooklm_podcast_notu.md
```

Use the established Podcast 031 structure and produce a complete Turkish NotebookLM source note.

The note must cover only Steps 206-210:

### Step 206

- Step 205 merged-truth closure;
- Podcast 031 creation for Steps 201-205;
- canonical tracked instruction authority;
- official `V:` workspace hardening;
- root instruction file becoming only an optional ignored mirror;
- no product behavior added.

### Step 207

- creation of `CSE_UNIFIED_PROJECT_SOURCE.md`;
- source register and accessible reference-source copies;
- unavailable sources not fabricated;
- GitHub-native new-chat bootstrap;
- ChatGPT deciding when Codex is required;
- `1 technical step = 1 primary Codex run`;
- safe batching of post-merge synchronization;
- metadata-churn avoidance;
- no field-MVP implementation yet.

### Step 208

- documentation-level `FieldObservationRecord` contract;
- six required fast-capture fields;
- `open`, `tracking`, `closed` lifecycle vocabulary;
- optional reporting/creator/closure/archive context;
- attachments remaining separate `FileAttachmentRecord` rows;
- private notes not silently copied into official records;
- no implementation or persistence.

### Step 209

- minimal `FieldObservationRecord` dataclass implementation;
- required values and defaults;
- optional/lifecycle value holding;
- three focused tests;
- total tests rising from `413 passed` to `416 passed`;
- no validation, repository, attachment integration, export, or interface behavior.

### Step 210

- minimal in-memory `FieldObservationRepository` baseline;
- `add`, `list_all`, `count`, `find_by_id`;
- duplicate `observation_id` rejection;
- `list_all()` returning a collection copy;
- four focused repository tests;
- total tests rising to `420 passed`;
- no filters, lifecycle mutation, persistence, attachment linking, daily export, or weekly summary.

## Required Narrative

The central story must be the transition from protocol/source/workflow consolidation to the first real, test-backed Field MVP production slice:

```text
source authority and execution discipline
-> reviewed observation contract
-> minimal observation model
-> minimal in-memory repository
```

Explain why the project deliberately stops before persistence, upload, filtering, lifecycle services, reporting, API, GUI, and AI.

Keep the site-chief perspective: a rapid official field observation can now be represented and held in memory, but the system is still not a field-ready application.

## Stable Boundaries To Preserve

The podcast must explicitly preserve:

- reliable data backbone first, automation later, AI last;
- small, controlled, tested, documented steps;
- GitHub as coordination/review surface and official `V:` repository as execution surface;
- official project record versus private/non-transferable note separation;
- no automatic acceptance, rejection, approval, task/NCR conversion, official decision, or generated `blocked`;
- no persistence/database/JSON/SQLite storage;
- no attachment upload/linking service;
- no API/GUI/CLI;
- no daily export or weekly summary implementation;
- GitHub Actions remaining manually disabled because of account billing / runner-start constraints;
- local verification baseline `420 passed` after Step 210.

## NotebookLM Sections

Follow the established structure, including at minimum:

1. main topic;
2. short summary;
3. step-by-step development;
4. stable decisions;
5. risks and boundary reminders;
6. official-transfer/private-data separation;
7. architectural meaning;
8. meaning for the site chief;
9. NotebookLM narration instructions;
10. short directive to NotebookLM;
11. closing question and concise answer.

The final question should be:

```text
Bu 5 adim, CHIEF SITE ENGINEER projesini protokol ve kaynak disiplininden ilk Field MVP urun cekirdegine nasil tasidi?
```

## Step 210 Merged-Truth Update

Update repository truth so:

- Step 210 / PR #37 / Issue #36 / merge `c7dbd94076f9e23c928f27ea377a97debad6636b` is the latest merged safe point.
- Step 211 is active unmerged documentation/podcast work.
- Podcast 032 is the current active artifact until merge.
- After merge, Podcast 032 becomes latest completed and covers Steps 206-210.
- The next five-step podcast range becomes Steps 211-215.
- Current local test baseline remains `420 passed`.
- `FieldObservationRecord` and the in-memory baseline repository are implemented.
- Persistence, filters, lifecycle updates, attachment integration, reporting/export, API/GUI/CLI remain unimplemented.

## Authorized Files

Create:

- `.cse/tasks/211_task.md`
- `.cse/results/211_result.md`
- `docs/podcast_notes/032_adim_206_210_notebooklm_podcast_notu.md`

Update:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/podcast_notes/README.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

No other project file is authorized.

## Verification

Run and record:

- full `python -m pytest` - expected `420 passed` unless the factual count differs;
- `git diff --check`;
- `python -m json.tool .cse/state/project_state.json`;
- changed-file scope check;
- exact podcast file review for Steps 206-210 only;
- protected-path diff for `app/models.py`, `app/records.py`, `tests/test_models.py`, `tests/test_records.py`, and `.github/workflows/pytest.yml` - must be empty;
- `exports/` check - only `.gitkeep`;
- ignored ZIP status/hash/time evidence - untouched;
- raw handoff ZIP and duplicate `(1)` source remain untracked;
- final local/remote branch SHA and divergence evidence;
- final worktree status.

## Publication And Boundaries

Commit and ordinary push are allowed. Force push, PR creation by Codex, merge, and branch deletion are forbidden.

Use one consolidated Codex execution. Do not start Step 212.

Do not change production code, tests, workflow behavior, Actions settings, persistence, attachment handling, filters, lifecycle behavior, export/reporting, API/GUI/CLI, audit, backup/restore, migration, validation, generated `blocked`, ZIP files, or Desktop archive content.
