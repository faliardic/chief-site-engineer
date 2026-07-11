# Step 203 - Official Local Sync Protocol

## Objective

Document and record the local-first synchronization protocol required by Issue #21. The official local repository working copy is the primary source for project file creation, edits, verification, commit, and push.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: #21
- Base branch: `master`
- Expected synchronized master commit: `a5fcadf1108dce409d7a1ddd9928b6a9cbb730c9`
- Working branch: `step-203-official-local-sync-protocol`
- Official local path: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Reasoning Level

- Codex: High

## Authoritative Instruction

Issue #21 requires all Step 203 work to be executed from the official local repository path. GitHub-only file creation or editing is not sufficient completion.

## Authorized Changes

- `.cse/tasks/203_task.md`
- `docs/203_official_local_sync_protocol.md`
- `learning/203_official_local_sync_protocol.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `.cse/results/203_result.md`
- `.cse/state/project_state.json`
- directly required documentation/state/result text

## Required Work

1. Verify the official local repository has no unexpected tracked, staged, or untracked changes before branch or pull operations.
2. Leave the existing ignored ZIP untouched.
3. Fetch and fast-forward local `master` to `origin/master`.
4. Verify local `master` and `origin/master` both equal `a5fcadf1108dce409d7a1ddd9928b6a9cbb730c9`; divergence must be `0 0`.
5. Create local branch `step-203-official-local-sync-protocol` from synchronized `master`.
6. Document the local-first sync protocol, safety rule, required checks, branch/push reporting, and GitHub connector boundary.
7. Update project docs, learning, result, and state factually.
8. Run local verification from the official local repository.
9. Commit and push the local branch.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty
- changed-file scope matches authorization
- `exports/` remains clean
- existing ignored ZIP remains untouched
- final branch divergence against remote branch is reported after push
- final working tree status is reported

## Forbidden Scope

- no production code changes
- no test behavior changes
- no GitHub Actions workflow modification
- no required status checks
- no API/GUI/CLI implementation
- no database/repository persistence
- no audit, backup/restore, migration, or hard validation
- no generated `blocked` status
- no file/export output generation
- no ZIP mutation
- no automatic merge
- no draft PR creation by Codex for this issue

## Commit and Push Permission

- Commit: allowed on `step-203-official-local-sync-protocol`
- Push: allowed to the same branch
- Pull request: do not open from Codex for Issue #21; ChatGPT will inspect the pushed branch and open the draft PR.
- Merge: not allowed

## Completion Criteria

- Step 203 files exist physically in the official local working tree.
- Local-first protocol is documented.
- Project state records Step 203 branch work and Step 202 as the synchronized safe point.
- Full local tests pass.
- Protected production/test/workflow files are unchanged.
- `exports/` is clean.
- Existing ignored ZIP remains untouched.
- Branch is pushed for ChatGPT inspection.
