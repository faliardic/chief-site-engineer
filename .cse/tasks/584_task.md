# Issue 584 — Ajanda icon-first

- Process lane: STANDARD; validation class: narrow-ui; review floor: independent R4.
- Authority: https://github.com/faliardic/chief-site-engineer/issues/584#issuecomment-5504767715
- Repository: V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
- Exact base: 187e6f66d5ae6753afa2080c78b340ffba188eee
- Branch: codex/issue-584-agenda-icon-first
- Stacked PR base: codex/issue-581-dashboard-project-create
- Preflight: exact HEAD, clean worktree/index, upstream 0 0, correct origin; parents #579/#582/#583 unchanged.
- Invariants: schema 22 / backup 1 / version 0.1.0+1.
- CSE-MRP-1.0: owner suggested high reasoning; actual model/effort not exposed (unknown/unverified); no fallback or downgrade; independent R4 retained.
- Execution: single local implementation, no delegation; fail closed on visible routing mismatch.
- Production allowlist: mobile/lib/features/agenda/{agenda_page,log_form_page,log_detail_page}.dart.
- Primary test: mobile/test/mobile_agenda_widget_test.dart.
- Conditional tests only for affected existing assertions: agenda_page_test.dart, agenda_stable_location_widget_test.dart, global_active_project_context_widget_test.dart, project_location_catalog_widget_test.dart, widget_test.dart.
- Evidence allowlist: this file and .cse/results/584_result.md.
- Preserve every key/callback/command/route, project defaults, date/time/filter values, content, attachments, reminders and Concrete behavior.
- Change action surfaces only: explicit tooltip/button semantics and real 40x40 targets; light/dark 320 px at text scale 1.6; destructive confirmation text stays visible.
- Protected: all other files, domain/application/storage/platform/schema/version, #556/#564/#565 and parent branches.
- Format all changed Dart and review exact diff BEFORE the single focused flutter test --no-pub invocation.
- Focused invocation always includes mobile_agenda_widget_test.dart and any touched conditional tests.
- FAIL: no post-test correction, second invocation, commit or push; retain local work and report exact failure.
- PASS: diff --check, allowlist/protected/invariant checks, finalize result, commit/push this branch and create one Draft stacked PR.
- No broad suite/analyze, builds, device commands, owner-data access, Ready or merge. No parent/post-merge synchronization writes.
- Manual acceptance remains owner-led and PENDING; no field-acceptance claim.

## Legacy transition — 2026-09-03

- Authority: https://github.com/faliardic/chief-site-engineer/issues/584#issuecomment-5522033988 and owner continuation; execution time budget: 30 minutes.
- Resume the existing merge of master e349ae2250b643153bff482db26791e4a659bdf0 into head 438c51dd7e7d3700f0b32557ea81bd9c6a3c74d2; no abort/restart or history rewrite.
- Resolve app.dart, global_active_project_context_widget_test.dart and widget_test.dart using master content, with zero final diff in those paths. Another conflict or remaining diff is a STOP condition.
- Final net scope against master is the original six #584 paths only; earlier conditional test scope does not apply to this transition.
- Run mobile_agenda_widget_test.dart once with --no-pub; PASS plus format/diff/scope checks authorizes a normal merge commit and push. Keep PR #585 Draft and its existing base; no Ready/merge.
- Preserve Agenda commands/domain/storage/attachment/reminder/Concrete behavior and master #580/#581 behavior. No analyzer, full suite, build or device work is planned.
- Current owner manual disposition is MT-584-001..006 DEFERRED (2026-09-02), not PASS or field acceptance. Earlier PENDING entries above describe the original execution.
