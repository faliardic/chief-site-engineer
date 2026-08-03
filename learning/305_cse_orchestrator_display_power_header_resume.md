# Issue #305 Öğrenme — Sinyal adayı ile bilgi satırını ayırmak

## Neden bütün `Display Power:` satırları state değildir?

`dumpsys` insan ve diagnostic tüketimi için birden çok bilgi şekli taşır. Aynı
başlık altında exact state alanı yanında servis nesnesi, callback veya özet
satırı bulunabilir. Prefix'i tek başına authority saymak benign metni güvenlik
sinyaline dönüştürür.

Parser iki aşamalı davranır:

```python
supported = fullmatch(r"Display Power: state=(ON|OFF)")
candidate = match(r"Display Power:\s*state(?:\s*=|$)")

if supported:
    signals.append(value == "ON")
elif candidate:
    malformed = True
else:
    ignore_non_state_information()
```

Supported regex exact değeri kabul eder. Candidate regex state anahtarına
benzeyen fakat bozuk şekilleri fail-closed tutar. Nesne/header satırı candidate
değildir ve karar listesine girmez. Header tek başına bulunursa supported sinyal
yokluğu nedeniyle sonuç yine `MALFORMED` olur.

Şunu şöyle yaptık ki: gerçek `Awake + object header + 1` çıktısı INTERACTIVE
olsun; buna karşılık `state=`, `state=UNKNOWN` veya bozuk state syntax'ı başka
bir positive satır tarafından örtülmesin.

## Mevcut güvenlik sinyalleri neden değişmedi?

Bu düzeltme yalnız bir satırın state adayı olup olmadığını belirler.
Wakefulness alias mapping'i, `mInteractive`, exact display ON/OFF ve bütün
positive/negative signal birleştirmesi aynı kalır. Power sonucu PASS olsa bile
keyguard ayrıca doğrulanır. Exact serial/model/package ve shell-free/destructive/
real-user guard'ları parser'ın dışında olduğu için değişmez.

## Beşinci pause neden yeni exact boundary'dir?

Önceki successor dördüncü pause'u koruyarak başladı; canlı preflight bir kez
daha denendi ve aynı blocker ile beşinci pause'a geldi. Bu state command budget
`6`, altı admission ve `32` event taşır. Eski fourth-pause predicate'ini
genişletmek iki farklı runtime state'ini aynı authorization altında kabul
ederdi. Yeni boundary kendi controller/workflow/authorization, projection, tail,
budget ve effect değerlerini exact doğrular.

```python
verify_exact_fifth_pause(third_predecessor)
fourth = replace_controller_and_nonce(third_authorization)
replay_payloads_into_new_identity(fourth)
assert same_semantic_continuation(third_predecessor, fourth)
```

Şunu şöyle yaptık ki: bütün predecessor zinciri immutable kalırken yeni
controller yalnız current tablet-preflight state'inden devam etsin; geçmiş test,
analyze, build, artifact veya preflight attempt'leri tekrar çalışmasın.

## Testlerin amacı

- Exact live üç-satır fixture ve farklı benign header'lar INTERACTIVE olur.
- Malformed state adayları fail closed kalır; header-only no-signal PASS olamaz.
- Alias, conflict, display, interactive ve bağımsız keyguard regresyonları
  korunur.
- Exact fifth-pause successor state/budget/evidence/artifact değerlerini korur.
- Root ve önceki üç successor authorization/metadata/manifest/ledger byte
  snapshot'ları değişmez.
- Projection, tail, effect, contract, rollback ve duplicate/later successor
  reddedilir; aynı successor idempotenttir.

Bütün kabul fixture'ları geçici fake repository/runtime ve fake adapter
kullanır; gerçek APK, ADB, tablet veya Issue #284 runtime çağrısı yoktur.
