# Issue #291 Öğrenme — Frozen Command Output Nasıl Güvenli Evidence Oldu?

## Problem

O2 bir action'ın admit edilip edilemeyeceğini söylüyordu; fakat bir runner'ın
sonradan getireceği stdout, stderr ve exit code'u state kararına uygun,
data-minimal bir biçime çevirmiyordu. Raw output'u saklamak determinism,
secret/user-data ve log hacmi riski doğurur. O3 bu boşluğu runner olmadan
doldurur.

## Gerçek kod akışı

Parser akışı şu sıradadır:

1. Top-level exact alan setini ve scalar tiplerini doğrula.
2. Schema, supported family ve action-start/wrapper/timeout/exit bağını doğrula.
3. Raw stdout/stderr'i değiştirmeden SHA-256 ile hashle.
4. Family parser'ıyla yalnız kanıtlanmış summary token'larını çıkar.
5. Wrapper, timeout, exit/output contradiction ve family failure precedence'ını
   uygula.
6. Secret, e-posta ve Windows kullanıcı yolunu maskelenmiş bounded excerpt'a
   dönüştür.
7. Frozen `ParsedCommandResult` üret ve gerekirse canonical JSON'a çevir.

Örnek kullanım:

```python
parsed = parse_command_result(
    {
        "schema_version": 1,
        "command_family": "pytest",
        "action_started": True,
        "wrapper_failed": False,
        "exit_code": 0,
        "duration_ms": 250,
        "stdout": "10 passed, 1 skipped in 0.20s\n",
        "stderr": "",
        "truncated": False,
        "timed_out": False,
        "failed_stage": None,
    }
)
```

Sonuçta raw output yoktur. `counts.total == 11`, budget evidence `true` ve iki
stream için hash vardır.

## Testlerin amacı

- Her command family için PASS/FAIL fixture'ı parser kapsamının explicit
  kalmasını sağlar.
- Pytest test-count, no-tests, collection-error ve interrupt fixture'ları
  tahmin yerine proven summary token kullanılmasını doğrular.
- Exit `0` ile failure özeti veya non-zero exit ile success özeti provenance
  çelişkisidir; sıradan test/build failure diye kabul edilmez.
- Action başlamadan wrapper failure budget tüketmez; başlamış timeout tüketir.
- Sanitization testi token, bearer credential, e-posta, Windows kullanıcı yolu
  ve çok uzun satırların raw output'a sızmadığını doğrular.
- I/O guard testi `open`, `subprocess.run` ve `socket.socket` fail ederken
  parser'ın yine çalıştığını kanıtlar.
- Input deep-copy ve canonical JSON testleri source mapping'in değişmediğini ve
  key order farkının byte output'u değiştirmediğini gösterir.

## Teknik kararlar

- Raw stream hash'i sanitization öncesi UTF-8 byte'lardan alınır; böylece kanıt
  exact source output'a bağlı kalırken içerik result'a kopyalanmaz.
- Unknown count `0` değildir. Kanıt yoksa `null`, explicit “no tests ran” varsa
  `0` kullanılır.
- `budget_consumed`, invocation'ın başlayıp başlamamasından türetilen evidence
  alanıdır; O3 sayaç yazmaz veya admission vermez.
- `generic_command`, family-specific sayı üretmez. Non-zero exit unknown;
  yalnız executable yokluğu gibi explicit token toolchain sınıfıdır.
- Excerpt limiti parser sabitidir. Output'un caller tarafından truncate
  edilmesi ayrı `truncated` provenance alanında korunur.

## Şunu şöyle yaptık ki...

- Input alanlarını exact yaptık ki yeni wrapper verisi sessizce yok sayılmasın.
- Failure precedence'ını explicit yaptık ki timeout, harness veya provenance
  problemi yanlışlıkla test failure'a indirgenmesin.
- Kanıtlanmayan sayıları `null` bıraktık ki dashboard veya policy sahte başarı
  toplamı üretmesin.
- Raw output yerine hash + sanitized excerpt kullandık ki replay eşitliği
  korunurken secret ve kullanıcı yolu yüzeyi daralsın.
- Parser'ı saf fonksiyon yaptık ki aynı fixture her makinede aynı canonical
  result byte'ını üretsin ve O2 policy/gelecek runner sınırı karışmasın.
