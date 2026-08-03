# Issue #305 — Ortak GitHub UTF-8 okuma ve controller handoff düzeltmesi

## Problem

Canlı Issue #284 workflow bootstrap'ı authorization ve ilk
`workflow_started` event'ini immutable runtime'a yazdıktan sonra GitHub evidence
yorumlarını okurken durdu. Ortak `GhGitHubClient`, `subprocess.run(text=True)`
kullandığı için Windows `cp1254` locale'i geçerli UTF-8 JSON içindeki Türkçe
karakteri çözemedi. Reader-thread hatası sonrasında `stdout=None` değeri de JSON
parser'a taşınarak structured blocker yerine process traceback'i üretti.

## Ortak GitHub GET sözleşmesi

`gh api --method GET` adapter'ı stdout/stderr'i binary yakalar. Byte dizileri
subprocess tamamlandıktan sonra çağıran thread'de `errors="strict"` ile UTF-8
çözülür. Locale'e bağlı `text=True` kullanılmaz. GET allowlist'i, `shell=False`,
kapalı stdin, bounded timeout ve comment pagination üst sınırı korunur.

Executable, timeout, invalid UTF-8, non-zero GET, invalid JSON ve pagination
limit hataları raw stderr/body taşımayan stable reason üretir. Evidence sink bu
hataları `WorkflowError` yapar; CLI yalnız structured `UNSAFE_BLOCKED` JSON
yazar.

## Immutable controller handoff

Handoff yalnız authorization `5167123792` ile tanımlanan eski controller
revision'ından ve aşağıdaki exact projection sınırından mümkündür:

- status `RUNNING`, event count `1` ve tek event `workflow_started`;
- stage index `0`; attempt, admission, active attempt ve consumed budget yok;
- passed evidence, target observation, artifact, device ve publish effect yok;
- blocker, pause veya command sonucu yok.

Eski authorization, metadata, manifest ve ledger yeniden yazılmaz. Yeni temiz
`origin/master` revision eski controller'ın descendant'ıysa; target checkpoint,
tree/blob, frozen Issue evidence, APK/tool, reused evidence, device, publish ve
stage contract'ları yeniden doğrulanır. Sonra yalnız controller SHA ve
deterministic handoff nonce'u farklı yeni authorization, controller SHA altında
exclusive successor kaydı olarak oluşturulur. Authorization fingerprint'i yeni
workflow identity üretir ve workflow aynı external runtime içinde bu identity
ile devam eder.

Successor aynı controller için idempotent yüklenir. Başka bir successor zaten
varsa, eski controller'a dönülürse veya eski ledger exact pre-stage sınırından
ileride/tampered ise `controller_handoff_not_safe` ile fail-closed durulur.

## Kapsam sınırı

Bu implementation yalnız orchestrator source/test/docs değişikliğidir. Issue
#284 target/ref/checkpoint, APK, external live runtime, product/mobile source,
build, install, ADB, tablet ve gerçek kullanıcı verisi okunmadı veya
değiştirilmedi.
