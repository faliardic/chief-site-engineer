# Issue #305 Result — Shared GitHub UTF-8 workflow recovery

## Implementation

- Common GitHub GET adapter now captures bytes and decodes strict UTF-8 on the
  caller thread; locale-dependent `text=True` was removed.
- Stable, content-free executable/timeout/UTF-8/GET/JSON/pagination reasons are
  translated by the evidence sink into workflow-safe blockers.
- The Issue #284 controller handoff accepts only the exact immutable
  `workflow_started` pre-stage boundary.
- Old authorization/ledger are preserved byte-for-byte. A deterministic,
  correction-authorized successor gets a new authorization fingerprint and
  workflow identity in the same external runtime.
- Advanced/tampered state, contract drift, multiple successors and controller
  rollback fail closed with `controller_handoff_not_safe`.

## Validation evidence

| Gate | Result | Pytest / wall duration |
| --- | --- | ---: |
| Shared GET + bootstrap + workflow + device-smoke | 153 PASS, 0 FAIL | 286.77 / 293.313 sec |
| All orchestrator (9 files) | 340 PASS, 0 FAIL | 292.61 / 299.200 sec |
| Full Python | 1,345 PASS, 0 FAIL, 7 SKIP | 309.43 / 316.939 sec |
| Compileall (`app scripts tools`) | exit 0 | 0.123 sec |

İlk geliştirme-içi üç dosyalık toplu pytest çağrısı 124 saniyelik shell wrapper
timeout'unda summary üretmeden sonlandı. Bu bir test assertion sonucu değildi;
dosyalar ayrıştırıldığında observer/bootstrap `109/109`, workflow `32/32` PASS
oldu. Final bağlayıcı gate'ler daha geniş timeout ile yukarıdaki exact sayımları
tek invocation başına üretti.

Regression kapsamı gerçek subprocess UTF-8/cp1254, invalid UTF-8, executable,
JSON, pagination, sink/CLI no-traceback, exact pre-stage successor, her
admission/effect field rejection, advanced/tampered ledger, old byte
immutability, idempotency ve chained-handoff rejection testlerini içerir.

## Scope

- Exact write allowlist: 13 paths.
- Product/mobile source change: `0`.
- Issue #284 target/ref/checkpoint/APK/live-runtime mutation: `0`.
- Build/install/ADB/device/smoke/real-user operation: `0`.
- Force-push/amend/rebase/merge/release: `0`.
