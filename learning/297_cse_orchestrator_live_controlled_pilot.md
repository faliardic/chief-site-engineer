# Issue #297 — Gerçek adapter ile güvenli tek invocation

## Amaç

Bu adım, deterministic Orchestrator sözleşmesinin gerçek bir subprocess ile
çalışırken de plan, budget ve provenance sınırlarını koruduğunu gösterir.
Komut düşük risklidir: yalnız O5–O8 MVP test dosyasını çalıştırır ve source
değiştirmez.

## Kod akışı

Gerçek adapter shell string çalıştırmaz. Planner'ın dondurduğu argv listesi,
exact cwd ve allowlisted environment mapping'i subprocess'e verilir:

```python
completed = subprocess.run(
    list(argv),
    cwd=cwd,
    env=environment,
    shell=False,
    stdin=subprocess.DEVNULL,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    timeout=timeout_seconds,
    check=False,
)
```

Bu tasarımda kullanıcı girdisinin shell tarafından yeniden yorumlanacağı ikinci
bir parse katmanı yoktur. `shell=False`, wildcard veya zincirlenmiş komutların
sessizce genişlemesini önler.

Environment aktarımı da bütün process ortamını kopyalamaz:

```python
return {
    name: values[name]
    for name in plan.environment_allowlist
    if name in values
}
```

Pilot sekiz gerekli environment adını admit etti; değerleri plan, ledger,
result veya dokümantasyona yazmadı.

## Neden explicit pytest özeti gerekliydi?

O3 parser exit code'u tek başına başarı kanıtı saymaz. Pytest sonucu ancak
tanınan summary token'ı count'ları doğruladığında PASS olur:

```text
30 passed in 0.21s
```

Bu nedenle action şu biçimde donduruldu:

```text
python -m pytest -o addopts= --color=no tests/test_cse_orchestrator_mvp.py
```

- `-o addopts=` yalnız bu invocation'da repository addopts değerini temizler.
- `--color=no` summary metnini ANSI escape kodlarından arındırır.
- O3 `exit_code = 0`, `failure_class = null`, `passed = 30` ve `failed = 0`
  değerlerini birlikte doğrular.

## Admission neden subprocess'ten önce yazılır?

Runner önce append-only admission event'ini yazar, sonra adapter'ı çağırır. Bu
sıra, action başladıktan sonra geriye dönük yetki üretme riskini kaldırır:

```text
approval consumption
+ budget admission
+ invocation-start provenance
→ one append-only admission event
→ subprocess start
```

Result event'i yalnız O3'ün veri-minimal public output'unu taşır. Raw stream
kalıcı ledger'a girmez.

## Duplicate execute neyi kanıtladı?

Aynı action fingerprint'i ikinci kez admit edilmek istendiğinde ledger
`duplicate_action` ile fail-closed oldu. Kontrol adapter çağrısından önce
gerçekleştiği için ikinci subprocess invocation sayısı `0`, toplam gerçek
invocation sayısı `1` kaldı.

## Testin amacı

Odaklı test aşağıdaki O5–O8 sözleşmelerini gerçek runner üzerinden birlikte
doğruladı:

- canonical dry-run ve execute planları;
- exact argv/cwd ve allowlisted environment;
- O3 deterministic pytest parsing;
- admission/result ledger hash-chain'i;
- invocation budget consumption;
- duplicate action rejection.

Sonuç `30 passed`, `0 failed` ve `FULL_PASS` oldu. Ledger iki event ile PASS
verdi.

## Şunu şöyle yaptık ki...

Exact komutu immutable execute planına bağladık ki terminalde çalışan komut ile
approval verilen komut arasında drift oluşmasın. Environment'ın yalnız adlarını
allowlist'e aldık ki process için gerekli Windows bağlamı korunsun fakat secret
ve kullanıcı değerleri evidence'a sızmasın. Admission'ı subprocess'ten önce
yazdık ki tek invocation bütçesi sonradan değiştirilemesin. Duplicate planı
yeniden sunduk ki korumanın test subprocess'ini gerçekten ikinci kez
başlatmadan çalıştığını kanıtlayalım.

## Bilinçli sınırlar

- Orchestrator production/mobile davranışı çalıştırmadı.
- Build, ADB/device, OpenAI API ve GitHub mutation adapter'ı kullanılmadı.
- Bu pilot O9 API planner veya O10 service/tray implementation'ı değildir.
- Ready, merge, close, delete ve release insan kararı ve ayrı authorization
  gerektirir.
