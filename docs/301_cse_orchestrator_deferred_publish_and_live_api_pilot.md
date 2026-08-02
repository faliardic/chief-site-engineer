# Issue #301 — Deferred publish ve host-owned provenance

Issue #301, API önerisi ile final Git SHA arasındaki sıralama hatasını giderir.
Child başlamadan bilinmesi mümkün olmayan commit SHA artık giriş sözleşmesinde
istenmez. Girdi yalnız immutable Draft PR şablonunu ve exact base'i taşır.

## Düzeltilmiş akış

```text
host clean-base preflight
-> tek Responses API önerisi
-> nested Codex: yalnız allowlist editleri ve testler
-> host: branch/base/index/scope doğrulaması
-> host: final validation argv'leri (shell=false)
-> exact 13-path staging
-> tek commit
-> tek normal push
-> local/remote provenance
-> tek existing-PR GET ve en fazla tek Draft-PR POST
```

Nested child branch oluşturmaz, stage/commit/push/PR yapmaz ve `.git` yazmaz.
Host, child sonrası HEAD'in exact base'de ve index'in boş olduğunu doğrulayarak
bu sınırı fail-closed uygular.
Host isteğindeki execution ve Draft PR alanları API çağrısından önce immutable
yerel sözleşmeyle eşleştirilir; drift ağ veya child işlemi başlamadan bloke olur.

## Executable çözümleme

Codex executable bir kez injected resolver veya `shutil.which("codex")` ile
çözülür. Yalnız `codex`, `codex.exe` veya `codex.cmd` basename'i, mevcut normal
dosya ve repository/runtime writable root'larının dışındaki path kabul edilir.
Çağrı exact argv, stdin prompt, bounded timeout/output ve `shell=false` kalır.

## Pre-live sınırı

Bu teslimat yalnız implementation, fake-adapter testleri ve repository-dışı
contract hazırlığıdır. Gerçek API, nested child, Git write, push veya REST PR
bu outer oturumda çalıştırılmaz.
