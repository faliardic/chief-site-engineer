# Issue #305 — Tablet interactive preflight ve immutable resume düzeltmesi

## Problem

Issue #284 canlı workflow'u tablet preflight aşamasında üç kez
`screen_not_interactive` ile pause oldu. Samsung SM-X610 üzerindeki gerçek
`dumpsys power` çıktısı ekranı `mWakefulness=Awake` satırıyla bildiriyordu;
production adapter yalnız `mInteractive=true` veya `Display Power: state=ON`
aradığından geçerli interactive durumu fail-closed blocker'a dönüşüyordu.

## Merkezi power parser sözleşmesi

`parse_power_interactive_state(...)` yalnız exact line-level sinyalleri okur:

- `mWakefulness=Awake`, `mInteractive=true`, `Display Power: state=ON` positive;
- `Asleep`, `Dozing`, `Dreaming`, `false` ve `OFF` negative;
- positive/negative birlikteliği `conflicting`;
- tanınan anahtarın bozuk değeri/şekli veya hiç sinyal olmaması `malformed`.

Yalnız bütün bulunan sinyaller positive olduğunda preflight ilerler. Parser raw
`dumpsys` metnini diagnostic'e taşımaz; sonuç yalnız data-minimal enum ve PASS
durumunda `interactive=true` değeridir. Keyguard sorgusu ve predicate'i parser'dan
bağımsız, önceki haliyle korunur.

## Immutable paused successor

İkinci controller handoff yalnız authorization `5168941496` ile tanımlanan exact
predecessor ve projection için açılır. Authorization/workflow/controller,
projection fingerprint ve ledger tail değerleri bağlayıcı sabitlerle doğrulanır.
Projection ayrıca stage index `6`, `artifact_verify=1`, `tablet_preflight=3`,
üç external pause, `screen_not_interactive / screen_is_interactive`, artifact
PASS ve sıfır device/publish effect koşullarını taşır.

Predecessor authorization, metadata, manifest ve ledger yeniden yazılmaz.
Successor authorization yalnız controller revision ve deterministic nonce ile
farklıdır. Yeni workflow identity'nin runtime'ı geçici external dizinde kurulur;
predecessor event payload'ları yeni manifest/hash-chain altında replay edilir ve
semantic projection exact eşitliği doğrulandıktan sonra atomik taşınır. Böylece
current stage, evidence, artifact, admission ve attempt sayaçları korunur;
focused/full test, analyze, build ve artifact gate'leri yeniden çalışmaz.

Aynı successor idempotent yüklenir. Projection/tail drift, authorization veya
contract drift, install/device/smoke/completion/publish effect, eksik/bozuk
successor history, controller rollback ya da üçüncü controller revision
`controller_handoff_not_safe` ile durur.

## Kapsam sınırı

Bu implementation yalnız orchestrator source/test/docs değişikliğidir. Issue
#284 target/ref/checkpoint, APK, canlı runtime, build, install, ADB, tablet,
product/mobile source ve gerçek kullanıcı verisi okunmadı veya değiştirilmedi.
