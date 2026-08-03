# Issue #305 — Display Power header ve immutable resume düzeltmesi

## Problem

SM-X610 üzerindeki gerçek `dumpsys power` çıktısı aynı anda şu satırları
üretebilir:

```text
mWakefulness=Awake
Display Power: com.android.server.power.PowerManagerService$3@3786411
mWakefulness=1
```

`Awake` ve `1` aynı interactive durumu bildirir. Ortadaki satır bir display
state sinyali değil, servis nesnesi/header bilgisidir. Önceki parser eşleşmeyen
her `Display Power:` satırını malformed saydığı için geçerli çıktı fail-closed
blocker'a dönüşüyordu.

## Dar parser sözleşmesi

Parser yalnız exact supported display state satırlarını boolean sinyale çevirir:

- `Display Power: state=ON` interactive;
- `Display Power: state=OFF` non-interactive.

`Display Power: state...` anahtarına benzeyen fakat exact supported şekle
uymayan adaylar malformed kalır. Örneğin boş değer, `UNKNOWN`, yanlış eşittir
boşluğu veya trailing metin PASS olamaz. Buna karşılık `Display Power:` ile
başlayıp state anahtarı taşımayan nesne, callback veya bilgi satırları sinyal
sayılmadan ignore edilir.

Wakefulness mapping'i değişmez: `Awake/1` interactive; `Asleep/0`,
`Dreaming/2`, `Dozing/3` non-interactive'dir. `mInteractive=true|false`,
cross-signal conflict, no-signal ve unknown/malformed wakefulness davranışları
korunur. Keyguard ayrı gate'tir. Raw `dumpsys` içeriği diagnostic, exception,
log veya kalıcı evidence'a taşınmaz.

## Exact beşinci-pause successor

Authorization `5170082561`, controller `d83efc2e...` altındaki
`wf-284-22b98a6db3d0` predecessor'ını yalnız exact fifth-pause sınırında
devredebilir: stage index `6`, `artifact_verify=1`, `tablet_preflight=5`, beş
external pause, altı admitted attempt, command budget `6`, GitHub-comment
budget `9`, event count `32`, exact projection fingerprint/tail, artifact PASS
ve sıfır device/publish effect.

Root ile önceki üç successor authorization/metadata ve runtime
manifest/ledger zinciri byte-for-byte immutable kalır. Yeni authorization yalnız
descendant controller revision ve deterministic nonce ile ayrılır. Event
payload'ları yeni workflow identity altında replay edilir; semantic continuation
exact eşit değilse işlem atomik publish öncesi durur.

Current stage, attempts, pauses, admitted attempt ID'leri, budgets, passed
evidence ve artifact state korunur. Test/analyze/build/artifact tekrar edilmez;
install/smoke/completion/publish effect üretilmez. Dördüncü successor aynı
controller'da idempotenttir; projection/tail/contract/effect drift, rollback,
corrupt history, duplicate veya daha ileri successor
`controller_handoff_not_safe` üretir.

## Kapsam sınırı

Bu run yalnız orchestrator source/test/docs değişikliğidir. Product/mobile
source, Issue #284 target/ref/checkpoint, canlı runtime, APK, build, install,
ADB, tablet ve gerçek kullanıcı verisi okunmadı, değiştirilmedi veya
çalıştırılmadı.
