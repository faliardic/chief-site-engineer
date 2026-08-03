# Issue #305 — Wakefulness numeric alias ve immutable resume düzeltmesi

## Problem

Android `dumpsys power`, aynı wakefulness durumunu üretici ve sürüme göre
sembolik (`Awake`) veya sayısal (`1`) gösterebilir. Önceki fail-closed parser
yalnız sembolik değerleri desteklediği için `mWakefulness=1` satırı malformed
sayılıyor ve gerçek interactive tablet preflight'ı ilerleyemiyordu.

## Tek semantik mapping

`parse_power_interactive_state(...)` bütün supported `mWakefulness` değerlerini
tek mapping üzerinden boolean semantiğe indirger:

- `Awake` ve `1`: interactive;
- `Asleep` ve `0`: non-interactive;
- `Dreaming` ve `2`: non-interactive;
- `Dozing` ve `3`: non-interactive.

Aynı semantiği bildiren tekrarlar tutarlıdır; `Awake` ile `1` birlikte
interactive olur. Sembolik-sayısal veya wakefulness/interactive/display
sinyalleri farklı semantik bildirirse sonuç `conflicting` olur. Bilinmeyen sayı,
desteklenmeyen metin, malformed değer ve supported sinyal bulunmaması
`malformed` kalır. Yalnız `interactive` sonucu preflight'ı geçirir.

Mevcut exact `mInteractive=true|false` ve `Display Power: state=ON|OFF`
destekleri korunur. Keyguard sonraki bağımsız gate'tir. Raw `dumpsys` metni
exception, diagnostic veya kalıcı evidence içine taşınmaz.

## Exact dördüncü-pause successor

Authorization `5169514740`, controller `ce70484b...` altındaki
`wf-284-74cb312bf0d3` predecessor'ını yalnız şu exact sınırda devredebilir:
`PAUSED_EXTERNAL / tablet_preflight / 6`, `artifact_verify=1`,
`tablet_preflight=4`, dört external pause, beş admitted attempt, command budget
`5`, GitHub-comment budget `9`, event count `29`, exact projection fingerprint
ve tail hash, artifact PASS ve sıfır device/publish effect.

Yeni authorization yalnız descendant controller revision ve deterministic nonce
ile değişir. Predecessor history yeni workflow identity altında replay edilir ve
semantic continuation exact eşitliği doğrulanır. Current stage, attempt/pause ve
admission sayaçları, budgets, passed evidence ve artifact korunur. Daha önceki
test/analyze/build/artifact aşamaları ile install/smoke/completion/publish effect
yeniden çalışmaz.

Root ve önceki iki successor authorization/metadata kaydı ile predecessor
manifest/ledger'ları byte-for-byte immutable kalır. Aynı üçüncü successor
idempotent yüklenir; projection/tail/contract/effect drift, rollback, bozuk kayıt,
duplicate ya da dördüncü successor `controller_handoff_not_safe` üretir.

## Kapsam sınırı

Bu run yalnız orchestrator source/test/docs değişikliğidir. Product/mobile
source, Issue #284 target/ref/checkpoint, canlı runtime, APK, build, install, ADB,
tablet ve gerçek kullanıcı verisi okunmadı, değiştirilmedi veya çalıştırılmadı.
