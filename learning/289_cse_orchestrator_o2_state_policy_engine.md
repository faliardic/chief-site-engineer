# Issue #289 Öğrenme — Saf Policy Engine Nasıl Kuruldu?

## Problem

O1 repository ve GitHub gerçeğini salt okunur gözlemliyordu; fakat “şimdi hangi
state'e geçilebilir?” ve “bu action gerçekten admit edilebilir mi?” sorularına
karar vermiyordu. O2 bu iki soruyu action çalıştırmadan cevaplayan güvenlik
oracle'ıdır.

## Gerçek kod akışı

State katmanı stringleri serbestçe zincirlemek yerine executable tablo kullanır:

```python
if not can_transition(current_state, proposed_state):
    return deny("STATE_DRIFT")
```

Append-only event oluşturulurken event ID; run, sequence, source fingerprint ve
transition'ın canonical JSON SHA-256 değeridir. Projection aynı event'i yeniden
görürse no-op yapar. Aynı ID farklı payload taşıyorsa history rewrite riski
sayılır ve fail-closed durur.

Policy akışı şu sırayı izler:

1. Exact schema ve scalar alanları doğrula.
2. State/action/resume/expected-success bağını doğrula.
3. Fingerprint, budget, retry, blocker ve evidence alt şemalarını doğrula.
4. Existing blocker precedence'ını uygula.
5. Transition tablosunu uygula.
6. Approval gereken yerde expiry, action, capability ve drift kontrolü yap.
7. Invocation başlamadan hard stop ve action counter'ını admit et.
8. Optional gate/reused evidence gerekçesini doğrula.
9. Immutable `PolicyDecision` üret ve canonical JSON'a çevir.

Örnek bir invocation admission sonucu:

```json
{
  "allowed": true,
  "budget_delta": {"full_gate_used": 1},
  "state_from": "ACTION_AUTHORIZED",
  "state_to": "ACTION_RUNNING"
}
```

Bu delta persistence değildir. Gelecek runner/admission event katmanı, approval
consumption ve invocation-start provenance ile aynı append-only event içinde
uygulamadıkça sayaç tüketilmiş sayılmaz.

## Testlerin amacı

- Transition matrisi dokümandaki exact edge setini karşılaştırır; birkaç happy
  path testiyle yetinmez.
- Terminal ve replay testleri geçmişin sessizce devam ettirilememesini doğrular.
- Approval testleri yüksek seviyenin farklı action fingerprint'ini kapsamadığını
  ve capability drift'inin fail-closed olduğunu gösterir.
- Budget testleri code, correction, full gate, checkpoint, build, device ve
  publish invocation'larının başlamadan önce sınırlandığını kanıtlar.
- Reused evidence testi yalnız exact source + contract eşleşmesini kabul eder.
- I/O guard testi policy çalışırken filesystem, subprocess veya socket
  çağrısının bulunmadığını executable olarak doğrular.
- Canonical output testi input blocker sırası değişse bile aynı byte dizisini
  bekler.

## Teknik kararlar

- Policy input'unda `evaluated_at` caller tarafından taşınır; karar içinde
  sistem saati okunmaz.
- Unknown alan normalize edilmez. Tanınmayan state, action, approval,
  capability, budget veya blocker fail-closed olur.
- Approval level sırası ayrı bir yardımcıdır; action admission yine exact
  required level, capability ve fingerprint eşleşmesi ister.
- Optional gate için sessiz skip yerine `not_required` veya exact `reused`
  disposition zorunludur.
- O2 eventleri in-memory immutable modeldir; SQLite ve consumption persistence
  sonraki fazlara bırakılmıştır.

## Şunu şöyle yaptık ki...

- State tablosunu enum + exact edge seti yaptık ki typo veya doğrudan
  `ACTION_AUTHORIZED → success` geçişi mümkün olmasın.
- Policy'yi yalnız mapping alan saf fonksiyon yaptık ki test doubles olmadan
  aynı input her ortamda aynı kararı üretsin.
- Fingerprint'leri source, contract, scope, action, capability ve budget olarak
  ayrı tuttuk ki drift'in hangi bağda oluştuğu veri-minimal gerekçeyle görülsün.
- Budget sonucunu mutation değil delta yaptık ki policy approval tüketen veya
  action çalıştıran gizli bir runner'a dönüşmesin.
- Exact replay'i idempotent, event-ID collision'ı failure yaptık ki ilerideki
  append-only store projection'ı güvenli temelden başlasın.
