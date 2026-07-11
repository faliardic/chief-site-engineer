# Step NNN Result

## Outcome

- Status: `<completed|partial|blocked>`
- Branch: `<branch>`
- Base commit: `<sha>`
- Result commit: `<sha or not committed>`
- Pull request: `<number or not created>`

## Changes

### Created

- `<path>`

### Updated

- `<path>`

### Deleted

- `None`

## Scope Verification

- Production code changed: `<yes|no>`
- Tests changed: `<yes|no>`
- Unrelated files changed: `<yes|no>`
- Export output created: `<yes|no>`
- Ignored ZIP touched: `<yes|no>`
- Forbidden scope added: `<yes|no>`

## Quality Checks

- `python -m pytest`: `<result>`
- `git diff --check`: `<result>`
- Staged files: `<result>`
- `exports/`: `<result>`
- Working tree: `<result>`

## Boundary Confirmation

State explicitly whether hard validation, generated `blocked` status, API/GUI/CLI behavior, database/repository access, audit behavior, backup/restore, migration, or unrelated persistence behavior was added.

## Remaining Work

- `<none or exact remaining work>`

## Recommended Next Action

- `<ChatGPT review|fix requested items|user merge approval|other>`
