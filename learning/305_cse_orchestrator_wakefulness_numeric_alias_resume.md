# Issue #305 Öğrenme — Alias semantiği ve zincirlenmiş immutable handoff

## Alias neden regex içinde değil, mapping içinde çözülür?

Regex yalnız exact `mWakefulness=<token>` satırını ayırır. Token'ın anlamını tek
mapping verir:

```python
WAKEFULNESS_INTERACTIVE = {
    "Awake": True,
    "1": True,
    "Asleep": False,
    "0": False,
    "Dreaming": False,
    "2": False,
    "Dozing": False,
    "3": False,
}
```

Bu ayrım, iki farklı yazımın aynı semantik durumu taşımasını görünür yapar.
Parser `Awake` ve `1` için iki `True` sinyali görür ve PASS eder. `Awake` ile
`0` ise `True/False` olur ve `CONFLICTING` döner. Değer regex'e uyduğu halde
mapping'de yoksa positive başka bir satır tarafından örtülmeden `MALFORMED`
kalır.

Şunu şöyle yaptık ki: Android'in sembolik ve sayısal taşıma şekilleri eşdeğer
olsun; bilinmeyen `4`, unsupported metin, bozuk satır ve cross-signal çelişkisi
fail-closed güvenlik kapısını gevşetmesin.

## Raw power çıktısı neden taşınmaz?

Preflight'ın karar vermesi için bütün cihaz metnini saklamak gerekmez. Parser
yalnız `interactive`, `non_interactive`, `conflicting` veya `malformed` enum'u
üretir. Adapter yalnız PASS halinde `interactive=true` ve enum değerini verir;
FAIL aynı stable `screen_not_interactive / screen_is_interactive` blocker'ıdır.
Keyguard farklı güvenlik sorusudur ve bağımsız sorgu/predicate olarak kalır.

## Üçüncü successor neden ayrı exact predicate ister?

Önceki correction'daki predecessor üç tablet-preflight attempt'inde duruyordu.
Canlı workflow yeni controller altında bir kez daha denendiği için yeni sınır
dört attempt/pause ve toplam 29 event taşır. Eski predicate'i genişletmek iki
farklı state'i aynı authorization ile kabul ederdi. Bunun yerine yeni edge kendi
authorization/workflow/controller, projection fingerprint, tail, budget ve
effect değerlerini exact doğrular.

```python
verify(second_predecessor_exact_boundary)
successor = replace_controller_and_nonce(second_authorization)
replay_payloads_into_new_identity(successor)
assert same_semantic_continuation(second_predecessor, successor)
```

Şunu şöyle yaptık ki: root ve ilk iki successor kaydı hiç yeniden yazılmadan
yalnız current pause state'i yeni controller'a geçsin; test, analyze, build,
artifact ve ilk dört preflight attempt'i sıfırlanmasın veya tekrarlanmasın.

## Testlerin amacı

- Production-shaped `Awake + 1` fixture'ı PASS eder; üç negative alias çifti
  non-interactive kalır.
- Symbolic/numeric mismatch, unknown numeric, malformed ve cross-signal conflict
  fail closed olur; interactive/display/keyguard regresyonları korunur.
- Exact 29-event predecessor state'i semantic-equal successor üretir.
- Authorization/metadata/manifest/ledger byte snapshot'ları predecessor zinciri
  immutability'sini kanıtlar.
- Projection, tail, effect ve contract drift; rollback ve duplicate successor
  reddedilir; exact successor tekrarında byte'lar değişmez.

Bütün fixture'lar geçici fake repository/runtime ve fake adapter kullanır;
gerçek APK, ADB, tablet veya Issue #284 runtime çağrısı yoktur.
