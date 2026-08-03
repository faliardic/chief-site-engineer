# Issue #305 Result — Live evidence verification correction

## Diagnostic

Hash-only live diagnostic selected Issue #284/#305 bodies and comment IDs
`5159802594`, `5159834136`, `5159861939`, `5159903268`, `5159955414` and
`5160233470`. Current raw content hashes matched the frozen records; raw bodies
were not printed or persisted. The blocker was classified as transport
representation, not semantic drift.

## Implementation

- Leading BOM removal, CRLF/CR to LF normalization and deterministic terminal
  newline are centralized in `canonical_markdown_bytes(...)`.
- Character and inner-whitespace changes remain significant.
- Body/comment blockers now include exact source IDs.
- Live frozen values are canonical SHA-256 hashes.
- The bootstrap-only read-only GitHub runner uses explicit strict UTF-8 and
  shell-free GET argv.

## Validation evidence

| Gate | Result | Duration |
| --- | --- | ---: |
| Focused bootstrap | 21 PASS, 0 FAIL | 42.933 sec |
| Workflow + device-smoke | 41 PASS, 0 FAIL | 132.521 sec |
| All orchestrator | 313 PASS, 0 FAIL | 178.492 sec |
| Full Python | 1,318 PASS, 0 FAIL, 7 SKIP | 204.644 sec |
| Compileall (`app scripts tools`) | exit 0 | 0.123 sec |
| Live canonical hash diagnostic | 8/8 source MATCH | 2.7 sec |

## Scope

- Exact write allowlist: 9 paths.
- Product/mobile source change: `0`.
- Issue #284 target/runtime mutation: `0`.
- Build/install/ADB/device/smoke/real-user operation: `0`.
- Force-push/amend/rebase/merge/release: `0`.
