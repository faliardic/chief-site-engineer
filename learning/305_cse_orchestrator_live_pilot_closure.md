# Issue #305 Öğrenme — Kayıtlı PASS kanıtından canlı workflow nasıl üretilir?

## Boşluk neydi?

O10 coordinator bir authorization verildiğinde güvenli biçimde ilerliyor,
pause ediyor ve resume oluyordu. Fakat Issue #284'ün checkpoint, test, build,
APK ve cihaz gerçeklerinden bu authorization'ı üreten tek giriş noktası yoktu.
Ayrıca tablet kullanıcı yolunu semantic adımlara bölen reusable bir adapter
bulunmadığı için operator hâlâ prompt ve ADB sırası taşıyordu.

## Authorization'ı veriden türetmek

Bootstrap önce current Git target'ı gözlemler, sonra frozen Issue kanıtlarını ve
artifact'i doğrular. Kanıt kümesi ayrı bir fingerprint olarak schema v2
payload'a girer:

```python
seed = _hash_mapping(
    {
        "controller": controller,
        "target": profile.target_checkpoint,
        "evidence": evidence_source,
        "artifact": profile.artifact_sha256,
    }
)
synthetic_title = "CSE284_O10_" + seed.split(":")[-1][:12].upper()
```

Şunu şöyle yaptık ki: sentetik kayıt adı rastgele operator girdisi olmasın;
aynı controller/target/evidence/artifact sözleşmesi aynı exact adı üretsin ve
resume sırasında başka kullanıcı kaydıyla karışmasın.

## PASS reuse yalnız yorum metnine dayanmaz

Recorded comment, bir testin geçmişte PASS olduğunu söyler. Coordinator'ın
güvenli reuse yapması için current source, executable, exact argv/cwd ve APK da
aynı olmalıdır:

```python
identity = {
    "stage": stage.name,
    "source_fingerprint": observe_target(target_root).source_fingerprint,
    "tool_fingerprint": _tool_fingerprint(stage),
    "command_fingerprint": _command_fingerprint(stage),
    "artifact_fingerprint": _artifact_fingerprint(auth, target_root),
}
identity["evidence_fingerprint"] = _hash_mapping(identity)
```

Şunu şöyle yaptık ki: `357 PASS` yazısının varlığı tek başına build'i atlatmasın;
o PASS'in ait olduğu checkpoint/tool/command/artifact tuple'ı değiştiyse
workflow action başlamadan dursun.

## Neden authorization repository dışında saklanıyor?

Device pause sonrasında target temiz kalır, ancak smoke PASS sonrası completion
docs worktree'yi yetkili biçimde değiştirir. Her komutta authorization yeniden
üretilse bu beklenen değişiklik yeni source fingerprint ve yeni workflow ID
üretirdi. Bootstrap bu nedenle ilk execute'ta authorization ve metadata'yı
external runtime'a exclusive yazar; resume her zaman aynı payload'ı yükler.

Şunu şöyle yaptık ki: runtime state repository commit'inin parçası olmasın,
ama authorization dosyası değiştirilirse metadata/contract fingerprint
karşılaştırması tamper'ı sessizce kabul etmesin.

## Smoke neden stage'lere bölündü?

Tek büyük `tablet-smoke` subprocess'i hangi kullanıcı adımından sonra
çöktüğünü ayırt edemezdi. O10.1 şu semantic stage'leri ayrı ledger olayları
olarak tutar:

```text
timed_to_all_day → all_day_date_change → same_day_noop
→ all_day_to_timed → notification_binding
→ cold_relaunch → recoverable_cleanup
```

Her stage PASS event'i append edildikten sonra sonraki stage'e geçilir. Process
evidence yayınında çökse bile yeni coordinator ledger replay ile PASS stage'i
yeniden çağırmaz. Fake-adapter testleri bu crash noktasını yedi smoke adımının
ve iki tablet gate'inin her birinde ayrı doğrular.

## Shell-free gerçek adapter sınırı

Runner arbitrary string command kabul etmez. Coordinator authorization'ındaki
semantic action, adapter'ın typed metoduna dispatch edilir. Alt seviye ADB her
zaman argv listesi ve `shell=False` kullanır:

```python
completed = subprocess.run(
    list(argv),
    stdin=subprocess.DEVNULL,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    shell=False,
    timeout=timeout,
)
```

`validate_adb_argv` exact tek tablet serial'ini zorunlu tutar ve destructive
verb'leri reddeder. UI adapter hierarchy'nin raw içeriğini döndürmez veya
saklamaz; yalnız allowlisted control ya da exact synthetic title için match
count ve bounded koordinat üretir.

Şunu şöyle yaptık ki: test adapter'ı gerçek cihazı hiç görmeden bütün state
machine'i doğrulayabilsin; production adapter ise telefon, gerçek kayıt ve
hard-delete gibi kapsam dışı yolları temsil edecek generic API'ye sahip olmasın.

## Testlerin amacı

- bootstrap tests: Git/Issue/artifact/tool tamper ve immutable authorization;
- smoke tests: bütün synthetic matrix, idempotency ve exact negative guards;
- workflow tests: artifact sonrası external pause/resume ve her smoke stage'i
  sonrası process crash;
- mevcut O10 tests: ledger/projection/artifact tamper ve duplicate-safe
  commit/push/Draft PR davranışı.

Canlı tablet kabulü bu implementation testlerinin parçası değildir. Bu kod
merged olduktan sonra aynı bootstrap entry point'i explicit `--execute` ile
Issue #284 target worktree'sine karşı çalıştırılır.
