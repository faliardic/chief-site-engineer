# Issue #291 — CSE Orchestrator O3 Deterministic Result Parser

## 1. Amaç ve süreç sınırı

O3, daha önce çalıştırılmış bir command'ın caller tarafından dondurulmuş
sonucunu deterministic evidence'a çevirir. Command başlatmaz, invocation admit
etmez, approval veya budget tüketmez ve success-state kararı vermez. O2 policy
kararı ile gelecekteki runner/persistence katmanı ayrı kalır.

`tools/cse_orchestrator/results.py` yalnız in-memory mapping okur. Subprocess,
network, filesystem, GitHub, OpenAI API, build veya device erişimi yoktur.

## 2. Frozen input sözleşmesi

`parse_command_result(mapping)` exact şu alanları kabul eder:

| Alan | Anlam |
| --- | --- |
| `schema_version` | Yalnız `1` |
| `command_family` | Supported yedi aileden biri |
| `action_started` | Gerçek invocation'ın başlayıp başlamadığı |
| `wrapper_failed` | Harness/wrapper katmanının failure bilgisi |
| `exit_code` | Başlayan ve dönen process'in integer exit code'u |
| `duration_ms` | Caller tarafından ölçülen non-negative süre |
| `stdout`, `stderr` | Parser'a verilen frozen text stream'leri |
| `truncated` | Caller'ın output'u kısalttığını bildiren flag |
| `timed_out` | Başlamış action'ın timeout sonucu |
| `failed_stage` | Varsa caller'ın explicit stage etiketi |

Unknown/missing alan, schema/family farkı, yanlış scalar tipi ve uyumsuz
action-start/wrapper/timeout/exit bağı `ResultInputError` ile fail-closed
reddedilir. Caller mapping'i değiştirilmez.

## 3. Supported family ve kanıt yüzeyi

Supported families:

- `pytest`
- `compileall`
- `git_diff_check`
- `flutter_test`
- `flutter_analyze`
- `build`
- `generic_command`

Sonuç şeması action/wrapper/exit/duration alanlarına ek olarak şunları taşır:

- proven-only `passed`, `failed`, `skipped`, `errors`, `warnings`, `total`;
- `failure_class`, `failed_stage` ve sorted unique `reasons`;
- `budget_consumed`;
- raw stream yerine `stdout_hash` ve `stderr_hash`;
- bounded `sanitized_excerpt`;
- `truncated` ve `timed_out`.

Sayım token'ı yoksa sayı tahmin edilmez ve alan `null` kalır. Pytest ile
Flutter test summary'leri explicit token sağladığında `total`, pass/fail/skip
ve error toplamıdır; warning test adedi değildir. Flutter analyze toplamı
yalnız explicit `N issues found` token'ından alınır.

## 4. Failure sınıflandırması

Asgari sınıflar:

| Failure class | Örnek |
| --- | --- |
| `source` | compile error veya `git diff --check` whitespace failure |
| `test` | pytest/Flutter test failure, no-tests veya interrupt |
| `analyze` | Flutter analyze issue sonucu |
| `build` | explicit build failure |
| `toolchain` | generic command executable bulunamadı |
| `harness` | wrapper failure; action başlamadan olabilir |
| `timeout` | action başladıktan sonra timeout |
| `provenance` | malformed/unrecognized veya exit/output çelişkisi |
| `unknown` | sınıflandırılamayan generic non-zero exit |

Precedence; action başlamadı/wrapper failure, timeout, provenance validation ve
family failure sırasıdır. `action_started=false` invocation budget tüketmez;
başlamış action timeout veya failure ile bitse de budget tüketir. Bu alan
yalnız result evidence'dır, sayaç mutation'ı değildir.

## 5. Data-minimal evidence

Raw stdout/stderr canonical result içine kopyalanmaz. Her stream'in UTF-8
byte'ları SHA-256 ile hashlenir. Excerpt yalnız ilk sekiz dolu satırı ve satır
başına en fazla 200 karakteri taşır; credential assignment, bearer/token
şekilleri, e-posta ve `C:\Users\<name>` yolu maskelenir.

Bu sanitization genel secret kasası veya DLP iddiası değildir. Caller gerçek
kullanıcı verisini parser'a vermemeli; O0/O1 data-minimal source sınırı önce
uygulanmalıdır.

## 6. Canonical output ve O2 ilişkisi

`canonical_result_json` sorted-key, whitespace'siz, UTF-8 uyumlu JSON üretir.
Aynı frozen input aynı byte dizisini verir; clock, random ID veya I/O sonucu
eklenmez.

O3 yalnız evidence parser'dır. `failure_class`, exit ve count alanları O2
policy'ye girdi olabilir fakat O3 `FULL_PASS`, `FAILED` veya `BLOCKED` state'i
seçmez. Action admission, append-only invocation event'i, approval consumption
ve runner sonraki ayrı fazlarda kalır.

## 7. Validation yaklaşımı

Focused matrix bütün family PASS/FAIL örneklerini; pytest varyantlarını; no
tests, collection ve interrupt durumlarını; compile/diff/Flutter/build
özetlerini; wrapper-before-start, timeout, truncation, malformed ve
contradiction yollarını; hashing/sanitization, unknown count, immutability,
canonical bytes ve I/O guard'ını doğrular.

Full Python suite O1 observer ile O2 state/policy davranışlarını regression
olarak korur. Gerçek test/build runner, Flutter gate, API, ADB ve device bu
Issue'da çalıştırılmaz.
