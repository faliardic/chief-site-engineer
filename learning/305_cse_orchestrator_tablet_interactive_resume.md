# Issue #305 Öğrenme — Power sinyali birleştirme ve state-preserving handoff

## Birden çok power sinyali neden tek parser'da birleşir?

Android üreticileri aynı interactive durumu farklı `dumpsys power` alanlarıyla
gösterebilir. Dağınık substring kontrolleri yeni cihaz şeklini kaçırabilir ve
çelişen satırlardan birini görüp yanlış PASS verebilir. Merkezi parser her
supported satırı boolean sinyale çevirir:

```python
signals = [wakefulness == "Awake", interactive == "true", display == "ON"]
if any(signals) and not all(signals):
    return PowerInteractiveState.CONFLICTING
if all(signals):
    return PowerInteractiveState.INTERACTIVE
```

Gerçek uygulama yalnız output'ta bulunan exact line-level sinyalleri listeye
alır. Tanınan anahtar malformed ise diğer positive satır onu örtemez. Hiç sinyal
yoksa da PASS varsayılmaz.

Şunu şöyle yaptık ki: Samsung'un `mWakefulness=Awake` çıktısı geçerli kabul
edilsin; buna karşılık Asleep/Dozing/Dreaming/OFF/false, çelişki veya parser'ın
anlamadığı şekil data-minimal `screen_not_interactive` blocker'ı üretsin.

## Keyguard neden ayrı kalır?

Ekranın interactive olması kilidin açık olduğunu kanıtlamaz. Bu nedenle power
parser yalnız ekran durumunu sınıflandırır; mevcut `dumpsys window policy`
keyguard kontrolü sonraki bağımsız gate olarak çalışır. Fixture regresyonu Awake
PASS sonrasında locked window için exact `keyguard_locked` sonucunu doğrular.

## Paused workflow yeni identity'ye nasıl taşınır?

Controller revision authorization fingerprint'inin parçasıdır; bu alan değişince
workflow identity de değişir. Yeni identity boş ledger ile başlatılırsa stage `0`
ve attempt `0` görünür, daha önce PASS olan test/build/artifact aşamaları tekrar
çalışabilir. Eski manifesti düzenlemek ise immutable provenance'ı bozar.

Çözüm iki immutable history'dir:

```python
staged.start(successor_contract)
for event in predecessor.events[1:]:
    staged.append(event["event_type"], event["payload"])
assert same_semantic_projection(predecessor, staged.verify())
os.replace(staged.root, successor.root)
```

İlk `workflow_started` yeni contract kimliğiyle üretilir. Sonraki event payload'ları
aynı sırada yeni hash-chain'e eklenir. Identity ve tail hash alanları doğal olarak
farklıdır; stage index, passed evidence, artifact, attempt/admission sayaçları,
blocker ve effect alanları exact aynı kalmak zorundadır.

Şunu şöyle yaptık ki: predecessor authorization/manifest/ledger byte-for-byte
korunurken successor `tablet_preflight` aşamasından attempt `4` ile devam etsin;
artifact veya önceki validation stage'leri sıfırlanmasın.

## Testlerin amacı

- Production adapter fixture'ları Awake/true/ON şekillerini ayrı ayrı PASS eder.
- Asleep/Dozing/Dreaming/false/OFF, conflict ve malformed şekiller FAIL eder.
- Keyguard gate'inin power parser'dan bağımsız kaldığı doğrulanır.
- Exact paused successor state, predecessor byte immutability, semantic history,
  idempotency ve ikinci successor reddi kanıtlanır.
- Projection fingerprint, tail ve effect alanlarının her drift'i fail-closed
  predicate üretir.

Testler yalnız temp fake repository/runtime ve subprocess fixture kullanır;
gerçek Issue #284 runtime, APK, ADB veya cihaz çağrısı yapmaz.
