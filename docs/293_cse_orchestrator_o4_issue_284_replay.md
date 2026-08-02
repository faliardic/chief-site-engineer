# Issue #293 — CSE Orchestrator O4 Issue #284 Sanitized Replay

## 1. Amaç ve güvenlik sınırı

O4, Issue #284'ün 19 yorumluk gerçek yürütme dizisini action çalıştırmadan
deterministic oracle fixture'ına dönüştürür. Fixture GitHub yorum gövdelerini
kopyalamaz; yalnız karar ve provenance için gereken metadata'yı taşır.

`tools/cse_orchestrator/replay.py` caller tarafından yüklenmiş mapping'i okur.
Filesystem, subprocess, network, GitHub, OpenAI API, test/build runner veya
device erişimi yapmaz. Replay sonucu yeni yürütme yetkisi değildir.

## 2. Sanitize fixture

Fixture'ın top-level yüzeyi:

- Issue numarası, açık state, exact base ve branch;
- sembolik `tablet_primary` target;
- exact comment count ve source precedence;
- checkpoint commit/parent/tree/subject/count/publication metadata'sı;
- 19 sıralı event;
- frozen expected-final gate.

Her event yalnız şu sınıfları taşır:

- event/comment identity ve sequence;
- event/action kind, source authority ve scope version;
- superseded authorization ile result'ın bağlı olduğu authorization;
- approval/capability ve source/branch/checkpoint/action fingerprint'leri;
- exact allowlist ve sparse positive budget delta;
- action-start, result class, expected state, blocker ve next gate;
- varsa data-minimal reused-evidence identity.

Raw body/stream, gerçek kullanıcı kaydı veya başlığı, cihaz serial/model,
app-private data, backup, UI hierarchy, screenshot, log, credential, e-posta ve
Windows kullanıcı yolu fixture'da bulunmaz.

## 3. 19-comment zinciri

Sanitize sıra şu karar dönemlerini korur:

1. İlk code-change authorization ve test-first source failure.
2. Widget harness correction/result döngüleri.
3. Invocation başlangıcı kanıtlanmayan tool timeout ve tek same-operation retry.
4. Dar responsive correction scope/budget genişletmeleri.
5. Reused lifecycle evidence ile full validation authorization'ı.
6. Exact checkpoint commit authorization ve doğrulanmış checkpoint evidence'ı.
7. Build/device authorization ile bounded tablet continuation'ları.
8. Son yorumda frozen checkpoint üzerinde açık `DEVICE` gate'i.

Result yorumları ordinary evidence'dır; latest-valid authorization'ı tek başına
değiştirmez. Her yeni GitHub authorization exact önceki valid comment ID'yi
supersede eder. Task/result veya `.cse_state` daha yeni görünse bile GitHub
authorization genişletemez.

## 4. O1–O3 oracle bağı

### O1 — authorization ve source precedence

Replay yalnız `github_authorization` kaynağını approval authority kabul eder.
Latest-valid seçiminde explicit supersession ve artan scope version zorunludur.
Ordinary result ile lower-authority task/state kaydı current approval'ı
değiştiremez.

### O2 — action admission invariants

Her action exact approval, capability, authorized state, source/branch,
checkpoint ve action fingerprint bağını taşır. Sparse budget yalnız GitHub
authorization event'inde artabilir. Aynı authorization ikinci başlamış result
üretirse blind retry olarak reddedilir.

`CHECKPOINT_COMMIT`, `BUILD_DEVICE`, `DEVICE` ve `PUBLISH` ayrı action
sınıflarıdır. Fixture build/device budget'ı taşır; publish authorization veya
budget taşımaz. Lower-authority sahte publish kaydı admit edilmez.

### O3 — frozen result semantics

Result event'i source, harness, timeout veya test failure class'ını ve
`action_started` bilgisini taşır. Yalnız explicit `true` invocation count'a
girer. Timeout event'inde action başlangıcı kanıtlanamadığı için bütçe
tüketilmiş varsayılmaz.

O4 raw output'u yeniden parse etmez; O3 tarafından üretilmiş data-minimal
failure-class semantics'ini replay eder.

## 5. Replay ve fail-closed davranışı

`replay_issue_284(mapping)` şu sırayı uygular:

1. Exact fixture/checkpoint/final/event şemalarını doğrula.
2. Issue/base/branch/device/source-precedence sabitlerini doğrula.
3. Event-ID replay'ini idempotent, collision'ı failure yap.
4. Unique sequence'i monoton doğrula.
5. GitHub authorization supersession, scope, action/approval/capability ve
   fingerprint bağlarını doğrula.
6. Explicit budget deltasını topla; ordinary result budget'ını reddet.
7. Result–authorization provenance ve blind retry kontrolünü uygula.
8. Reused evidence identity'sini aynı action için exact koru.
9. Checkpoint commit/parent/tree evidence'ını doğrula.
10. Frozen final özetin completion/publication iddiası üretmediğini doğrula.

Exact duplicate event no-op'tur. Aynı event ID farklı payload, sequence drift,
unknown/missing alan, source/action/capability drift, evidence farkı, sahte
completion veya yetkisiz action `ReplayInputError` ile fail-closed durur.

## 6. Canonical sonuç

`ReplaySummary`; unique event/authorization/result sayıları, latest-valid
comment/scope, checkpoint, toplu budget, kanıtlanmış invocation/result sınıfı,
reused evidence kimlikleri, unauthorized action count ve final gate taşır.

`canonical_replay_json` sorted-key ve whitespace'siz UTF-8 uyumlu JSON üretir.
Input key sırası output byte'ını değiştirmez; caller mapping'i mutate edilmez.

Final Issue #284 özeti özellikle:

- checkpoint verified ve frozen;
- remote publication false;
- unauthorized action `0`;
- state `ACTION_AUTHORIZED`;
- blocker `DEVICE_ACCEPTANCE_PENDING`;
- next gate `DEVICE`;
- issue completed false

değerlerini korur. Bu özet Fatih adına completion veya publish kararı değildir.

## 7. Validation yaklaşımı

Focused suite strict schema, exact 19 ID, monotonic sequence, duplicate replay,
latest-valid supersession, lower authority, budget/retry, unproven start,
fingerprint drift, evidence reuse, checkpoint tree, action gate, fake
completion, sanitization, immutability, canonical bytes ve external-I/O guard
testlerini kapsar.

Full Python suite O1 observer, O2 policy ve O3 parser regressionlarını birlikte
korur. Flutter, build, ADB, device ve API bu Issue'da çalıştırılmaz.
