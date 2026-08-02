# Issue #295 Öğrenme — Plan ile Eylem Arasına Neden Ledger Koyduk?

## Problem

Bir komutun güvenli görünmesi onun çalıştırılabilir olduğu anlamına gelmez.
Repository doğru branch'te olabilir fakat approval başka action'a, source başka
tree'ye veya budget önceki invocation'a ait olabilir. Shell kullanmadan exact
argv çalıştırmak da tek başına bu provenance sorunlarını çözmez.

O5–O8'de komutu doğrudan runner'a vermek yerine üç ayrı kanıt katmanı kurduk:

```text
immutable ActionPlan
→ append-only admission
→ frozen parsed result
```

## Gerçek kod akışı

Caller önce O1 ve O2 çıktısını exact request ile birleştirir:

```python
plan = build_action_plan(observation, policy_decision, action_request)
```

Bu fonksiyon action çalıştırmaz. Exact argv, cwd, source ve approval farklıysa
`PlanError` üretir. Plan hash'i action identity'sinin canonical JSON'undan gelir;
input key sırası sonucu değiştirmez.

Execution için repository dışı ledger ve injected adapter gerekir:

```python
store = RuntimeLedger(
    runtime_root=runtime_root,
    repo_root=repo_root,
    run_id=plan.run_id,
)
controlled = ControlledRunner(process_adapter=fake_process, ledger=store)
result = controlled.execute(
    plan,
    policy_decision,
    execute=True,
    current_source_fingerprint=source_fingerprint,
    current_action_fingerprint=plan.action_fingerprint,
)
```

Runner sırası değiştirilemez:

1. Plan hash'ini ve policy bağını yeniden doğrula.
2. Current source/action fingerprint'i exact karşılaştır.
3. Approval consumption, budget admission ve invocation provenance'ını tek
   admission event'ine append et.
4. Yalnız allowlist environment ile injected adapter'ı çağır.
5. Adapter sonucunu O3 parser'a ver.
6. Raw stream yerine data-minimal parsed result'ı ledger'a append et.

Fake adapter test sırasında admission dosyasının kendisinden önce oluştuğunu
kontrol eder. Böylece “önce action başladı, sonra kayıt yazmaya çalıştık” yarışı
testte görünür hâle gelir.

## Hash-chain nasıl çalışır?

Her ledger event'i önceki event hash'ini taşır:

```text
GENESIS
→ admission(previous=GENESIS, hash=A)
→ result(previous=A, hash=B)
```

Bir kişi admission payload'ındaki success state'i veya result evidence'ını
değiştirirse canonical event hash'i artık eşleşmez. Satır silinirse sequence veya
previous hash kırılır. Aynı action fingerprint ikinci kez admit edilirse duplicate
consumption olarak reddedilir.

Bu bir secret store değildir. Hash-chain değişikliği görünür kılar; runtime
dosyasına gizli veri yazma yetkisi vermez.

## Gate neden tek büyük action değil?

Checkpoint, build, device ve publish farklı risk ve capability taşır:

- checkpoint Git tree/index/parent sözleşmesidir;
- build source'tan artifact üretir;
- device exact artifact'ı sembolik hedefe uygular;
- publish remote branch ve Draft PR oluşturur.

Bir build PASS'inin cihaz onayı sayılması veya checkpoint approval'ının publish'e
taşınması ambient authority üretirdi. Bu yüzden her builder ayrı action,
approval, fingerprint ve budget alanı üretir.

Örnek device planı gerçek serial içermez:

```python
contract = {
    "artifact_sha256": "sha256:...",
    "device_target": "tablet_primary",
    "adb_argv": ["adb", "install", "app.apk"],
    "retry_budget": 1,
}
```

`-s <serial>`, uninstall ve data-clear aileleri fail-closed kalır.

## Publish neden iki adapter içerir?

Normal push bir process action'ıdır; Draft PR oluşturma GitHub client action'ıdır.
İkisini aynı belirsiz shell command'a çevirmek yerine:

1. push exact `git push origin <branch>` planıyla controlled runner'dan geçer;
2. push O3 result'ı success ise injected GitHub client tek Draft PR oluşturur;
3. GitHub response frozen generic result olarak sınıflanır.

Duplicate open PR push'tan önce kontrol edilir. Force-push, Ready, merge, Issue
close, branch delete ve release bu yüzeyde kabul edilmez.

## Testlerin amacı

- Canonical test aynı input'un aynı plan byte'ını üretmesini doğrular.
- Frozen test dataclass ve nested budget mapping'in mutate edilemediğini gösterir.
- Shell/wildcard/path testleri kolaylık uğruna scope genişlemesini engeller.
- Admission-before-execution testi append sırasını executable yapar.
- Tamper testi ledger'ın kendi dosyasındaki tek byte değişimini reddeder.
- Harness/timeout/non-zero testleri “action başladı mı?” ile sonucu ayırır.
- Gate testleri checkpoint/build/device fingerprint'lerinin birbirinden farklı
  olduğunu gösterir.
- Device testi gerçek serial ve destructive ADB ailelerini reddeder.
- Publish testleri normal push, Draft body, duplicate PR ve forbidden lifecycle
  action'larını yalnız fake client ile doğrular.
- Full suite O1–O4 observer/policy/parser/replay API'lerinin gerilemediğini
  gösterir.

## Teknik kararlar

- Plan ve gate builder saf/deterministic kalır; runtime mutation runner/ledger'a
  aittir.
- Real subprocess adapter vardır fakat yalnız explicit execute planında ve
  `shell=False` ile kullanılabilir.
- Ledger repository dışıdır; raw stream ve comment body tutmaz.
- Budget planlanan admission delta'sıdır; O3 `action_started` gerçek consumption
  evidence'ını ayrıca verir.
- Publish adapter blind retry yapmaz; belirsiz response yeni action authority
  üretmez.
- CLI default dry-run'dır ve execute flag'i plan mode'un yerine geçmez; ikisi de
  gerekir.

## Şunu şöyle yaptık ki...

- Action fingerprint'i argv/cwd/source/allowlist ile bağladık ki aynı approval
  sessizce farklı komuta taşınamasın.
- Admission'ı adapter'dan önce append ettik ki action provenance'sız başlamasın.
- Result'a raw stream yerine hash ve sanitized excerpt koyduk ki debugging kanıtı
  secret veya kullanıcı verisi aynasına dönüşmesin.
- Gate'leri ayırdık ki checkpoint PASS'i build/device/publish onayı olmasın.
- GitHub client'ı inject ettik ki gerçek remote mutation olmadan publish
  sözleşmesini tam test edebilelim.
