# Issue #305 Öğrenme — UTF-8 subprocess ve immutable workflow devri

## `text=True` neden yeterli değildir?

Python'da `subprocess.run(text=True)` encoding verilmezse platform locale'ini
kullanır. GitHub API cevabı UTF-8 olsa bile Windows `cp1254`, UTF-8 `Ş`
karakterinin ikinci byte'ı `0x9e` için decode hatası verebilir. Güvenli sınır,
önce exact byte'ı yakalayıp sonra tek yerde strict UTF-8 çözmektir:

```python
completed = subprocess.run(
    args,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    stdin=subprocess.DEVNULL,
    shell=False,
    check=False,
)
stdout = bytes(completed.stdout or b"").decode("utf-8", errors="strict")
```

Şunu şöyle yaptık ki: subprocess reader thread'i locale ile metni yorumlamasın;
geçerli GitHub UTF-8'i caller thread doğrulasın ve invalid byte hiçbir raw
içerik sızdırmadan stable reason'a dönüşsün.

## Adapter hatası neden domain hatasına çevrilir?

`GhIssueEvidenceSink`, ortak client'ın sanitize edilmiş hatasını aynı reason ile
`WorkflowError` yapar:

```python
try:
    comments = self._client.get_issue_comments(self.issue)
except GitHubClientError as exc:
    raise WorkflowError(str(exc)) from None
```

`from None` adapter exception chain'ini kullanıcı çıktısına taşımaz. CLI'nin
mevcut workflow error gate'i hatayı yakalayıp `UNSAFE_BLOCKED` JSON üretir.
Raw GitHub body, stderr veya traceback kanıt yüzeyine girmez.

## Controller değişince eski ledger neden devam ettirilmez?

Workflow contract controller revision ve authorization fingerprint'ini içerir.
Eski manifesti yeni SHA ile değiştirmek hash-chain otoritesini bozar. Bunun
yerine old authorization/ledger byte'ları immutable kalır; yalnız exact
pre-stage state doğrulanır ve yeni authorization fingerprint'inden yeni workflow
identity türetilir.

```python
safe = (
    projection.status == "RUNNING"
    and len(events) == 1
    and events[0]["event_type"] == "workflow_started"
    and projection.current_stage_index == 0
    and not projection.admitted_attempt_ids
    and not projection.consumed_budgets
)
```

Gerçek predicate ayrıca attempt, evidence, target observation, artifact, device,
publish, pause ve blocker alanlarının tamamını sıfır/boş ister. Böylece action
admission'dan sonra controller değiştirilerek bir stage'in iki kez çalıştırılması
mümkün olmaz.

## Successor neden ayrı ve deterministic olmalıdır?

Successor authorization yalnız controller SHA ve predecessor+controller'dan
türetilen nonce ile farklıdır. Target, evidence, APK/tool, reused PASS, device,
publish ve stage sözleşmeleri exact eşit kalır. Controller SHA dizini altında
exclusive yazım aynı handoff'un ikinci kez yeni identity üretmesini engeller.
Başka bir successor dizini varsa yeni handoff reddedilir; zincirleme controller
devirleri bu dar correction'ın yetkisini genişletemez.

## Testlerin amacı

- Gerçek subprocess UTF-8 byte'ı strict çözerken aynı byte'ın `cp1254` ile
  çözülemediğini kanıtlar.
- Invalid UTF-8, executable, JSON ve pagination hataları stable/content-free
  reason verir.
- Sink ve CLI no-traceback structured blocker üretir.
- Exact tek-event pre-stage successor PASS; her admission/effect alanı, advanced
  state ve tampered ledger FAIL olmalıdır.
- Old authorization/ledger byte eşitliği ve successor idempotency korunmalıdır.

Bu testler temp fake Git repository/runtime kullanır; gerçek Issue #284 runtime,
product/mobile, APK, build veya cihaz akışı çalıştırılmaz.
