# Issue #301 Öğrenme — Bilinmeyen SHA'yı ertelemek

## Amaç

Bir işlem sonunda üretilecek değeri işlem başlamadan istemek döngüsel bir
sözleşmedir. Final commit SHA child editlerinden sonra oluşacağı için API-run
girdisi SHA değil immutable publish template taşır.

## Gerçek kod akışı

```python
child = codex.execute(request, execute=True)
if child.status == "PASS":
    resolved = host.publish(host_request, execute=True)
    github.create_draft_pull_request(resolved, execute=True)
```

`HostPublisher`, child'ın Git yapmadığını HEAD/index kontrolleriyle doğrular;
final testleri çalıştırır, exact allowlist'i stage eder ve yalnız tek normal push
sonrasında local/remote SHA eşitliğini çözer.

## Test amacı

- Windows npm kurulumundaki `codex.cmd` shell açmadan kabul edilir.
- Repository içindeki sahte executable reddedilir.
- Host yalnız exact staging, tek commit ve tek push argv'si üretir.
- Host girdisinin yerel allowlist, doğrulama ve yayın metadatasından sapması API
  çağrısından önce reddedilir.
- Dry-run hiçbir process çağrısı yapmaz.
- Provenance drift Draft PR ağ çağrısından önce bloke edilir.

## Teknik karar

Şunu şöyle yaptık ki: child'a Git yetkisi vermek yerine Git sahipliğini host'ta
tuttuk; böylece model çıktısı yayın yetkisini genişletemez ve final provenance
yalnız gerçek push'tan sonra üretilebilir.
