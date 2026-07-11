# Step 193 - Bootstrap GitHub-Based ChatGPT-Codex Handoff Protocol

## Identity
- Issue: #1
- Branch: `step-193-github-handoff-protocol`
- Base commit: `12e042850515005ed7baa55d9eb273dad8d201e3`
- Reasoning level: High

## Goal
Create the documentation/configuration foundation that removes routine manual copy/paste between ChatGPT and Codex.

## Allowed Changes
- `.cse/**`

## Required Deliverables
- Protocol README.
- Reusable task template.
- Reusable result template.
- Machine-readable project state foundation.
- Step 193 task and result records.

## Forbidden Scope
- No production code changes.
- No test changes.
- No hard validation.
- No API/GUI/CLI behavior.
- No database/repository application behavior.
- No audit event behavior.
- No backup/restore or migration behavior.
- No ZIP or export output.

## Verification Boundary
GitHub connector operations can verify repository content and PR diff, but cannot prove local working-tree cleanliness, ignored files, `exports/`, or pytest execution. Those checks must remain explicitly marked as requiring local/Codex verification.

## Commit / Push Permission
GitHub commits on this dedicated branch and a draft PR are authorized. Merge into `master` is not authorized without explicit user approval.
