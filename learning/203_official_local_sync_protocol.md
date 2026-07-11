# Step 203 Learning - Official Local Sync Protocol

Step 203 makes the working rule explicit: the official local repository is the source of truth for project file creation and verification. GitHub is the remote and review surface, but GitHub-only file changes do not count as complete project work.

The key safety habit is to inspect the working tree before branch changes or pulls. If tracked, staged, or untracked project changes are present, Codex should stop and report them instead of resetting, cleaning, stashing, deleting, or overwriting.

The sync rule is deliberately conservative: fetch, fast-forward `master`, verify the expected SHA and `0 0` divergence, then create the work branch from that synchronized point. This protects the local project history from drifting away from GitHub while still keeping local files authoritative.

The existing ignored ZIP is treated as an offline/emergency artifact. It may be reported, but it should not be touched during normal Step work.

The narrow next habit after this step is to use this protocol for every future issue before editing files: local safety check first, fast-forward sync second, branch work third, verification and push last.

The reusable protocol files matter as much as the step-specific docs. If `.cse/README.md` or the task/result templates still describe GitHub-first handoff, future steps will drift back into remote-only behavior. Step 203 therefore updates those canonical files so every future task starts with local sync evidence and ends with local verification, divergence, push, and post-merge sync reporting.
