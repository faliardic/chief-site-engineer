# Issue #305 Öğrenme — Metin taşıma farkı ile içerik drift'i nasıl ayrılır?

## Aynı Markdown neden farklı hash üretebilir?

Bir Markdown gövdesi ekranda aynı görünse de byte düzeyinde farklı taşınabilir:
Windows satır sonu `CRLF`, Unix satır sonu `LF` kullanır; bazı producer'lar
UTF-8 BOM ekler; bazı adapter'lar son newline'ı korur veya kaldırır. Doğrudan
`text.encode("utf-8")` hash'i bu taşıma ayrıntılarını içerik kabul eder.

## Dar canonicalization

Correction, yalnız açıkça izin verilen transport farklarını tek byte
sözleşmesine dönüştürür:

```python
def canonical_markdown_bytes(value: str) -> bytes:
    if value.startswith("\ufeff"):
        value = value[1:]
    normalized = value.replace("\r\n", "\n").replace("\r", "\n")
    return (normalized.rstrip("\n") + "\n").encode("utf-8")
```

Şunu şöyle yaptık ki: GitHub/terminal newline taşıması false-positive blocker
üretmesin; fakat metindeki iki kelime arasına eklenen boşluk, değişen sayı, link,
başlık veya tek karakter sessizce kabul edilmesin.

Windows'ta subprocess text decode'unu locale'e bırakmak `gh api` JSON'undaki
Unicode içeriği hash aşamasından önce bozabilir. Bootstrap evidence runner bu
nedenle `encoding="utf-8"`, `errors="strict"`, `shell=False` ve yalnız GET argv
allowlist'i kullanır.

## Hash-only diagnostic

Canlı tanıda body veya comment metni yazdırılmadı. Her source için yalnız source
ID, raw/canonical byte length ve SHA-256 karşılaştırıldı. Current raw hashlerin
frozen değerlerle eşit olması semantik drift olmadığını; canonical değerlerin
BOM/EOL/terminal-newline varyantlarında sabit kalması correction'ın doğru
sınırda olduğunu gösterdi.

## Source-specific reason neden önemli?

Generic `evidence_issue_body_drift` hangi Issue'nun değiştiğini söylemiyordu.
Source ID reason'a eklenince operator raw içeriği loglamadan exact kaynağı
yeniden doğrulayabilir. Bu hem veri minimizasyonunu hem fail-closed tanıyı
korur.

## Testlerin amacı

- LF/CRLF/CR, BOM ve terminal-newline eşdeğerliği PASS olmalıdır.
- Tek karakter ve iç-whitespace değişikliği FAIL olmalıdır.
- Issue #284/#305 body ve seçili yorum drift'i exact source ID reason vermelidir.
- Canlı evidence GET'i Windows locale'inden bağımsız strict UTF-8 olmalıdır.
- Mevcut target, artifact ve comment tamper testleri değişmeden PASS kalmalıdır.

Bu testler gerçek build/install/device smoke yapmaz; yalnız fake repository ve
evidence adapter'larıyla orchestrator sınırını doğrular.
