# Issue 287 — CSE Orchestrator O1 Read-Only Observer Öğrenme Notu

## Amaç

O1 ile ilk executable Orchestrator katmanını kurduk. Bu katmanın görevi bir işi
çalıştırmak değil; local Git, live GitHub, machine authorization ve exact CSE
kayıtlarının güvenilir bir fotoğrafını veri-minimal JSON olarak üretmektir.

## Gerçek implementation yaklaşımı

Implementation üç parçaya ayrıldı:

- `authorization.py`: strict authorization envelope, JSON schema, canonical
  hash, expiry ve supersession;
- `observer.py`: tracked-only Git, GET-only GitHub, exact record metadata,
  sanitizer, blocker/exit code ve atomic runtime writer;
- `cli.py`: yalnız `observe` alt komutu ve strict giriş doğrulaması.

Bağımlılık eklenmedi. GitHub GET işlemleri mevcut `gh` executable'ı üzerinden,
geri kalan bütün davranış Python standard library ile kuruldu.

## Neden mevcut `cse_status` doğrudan kullanılmadı?

`scripts/cse_status.py` tarihsel status/finalize aracıdır. Default gözleminde
ignored/untracked, ZIP ve `exports/` alanlarını geniş tarar; ayrıca explicit
finalize write davranışı taşır. O1'in capability sınırı ise yalnız tracked Git
metadata ve exact task/result/state yollarına izin verir.

Bu nedenle mevcut dosyayı refactor etmedik. Yeni observer, mutating command
ailelerini subprocess katmanından önce reddeden daha dar bir command guard ile
ayrı tutuldu.

## Strict JSON ve duplicate-field savunması

Normal `json.loads` aynı key ikinci kez gelirse son değeri sessizce kabul eder.
Authorization payload'ında bu davranış scope veya budget alanının görünmez
biçimde değiştirilmesine izin verebilir. Parser bu yüzden `object_pairs_hook`
kullanır ve ilk duplicate key'de fail-closed durur.

Unknown/missing alanlar da reddedilir. Payload hash'i parsed objenin sorted,
whitespace'siz UTF-8 JSON byte'larından SHA-256 ile üretilir. Böylece farklı
görsel indentation aynı semantik payload için aynı fingerprint'i verir.

## Test doubles ve command injection

Observer, command runner ve GitHub client'ı dışarıdan alabilir. Unit testlerde
gerçek Git/GitHub çağrısı yerine exact command-result tabloları kullanılır.
Testler hem beklenen ref/SHA parse'ını hem de çağrılan komut ailelerini görür.

Bu injection tasarımı iki güvenlik sonucu verir:

1. failure ve drift yolları gerçek repository'yi değiştirmeden test edilir;
2. `fetch`, `commit`, `push` veya GitHub mutation çağrısının hiç oluşmadığı
   command seviyesinde kanıtlanır.

## Neden ignored/untracked tarama yapılmadı?

Ignored ve untracked alanlar gerçek backup, cihaz çıktısı, ZIP/cache veya başka
kullanıcı verisi taşıyabilir. O1'in sorusu bu alanlarda ne olduğu değil; tracked
source ve index'in authorized fingerprint ile eşleşip eşleşmediğidir.

Bu nedenle yalnız `git diff --name-status` staged/tracked listeleri kullanılır.
Exact üç CSE kaydı `git ls-files` ve `git hash-object` ile tek tek gözlenir;
repository-wide directory walk yapılmaz.

## Runtime ve sanitizer

Runtime root repository'nin içinde verilirse observer dosya yazmadan
`USER_DATA_RISK` üretir. Güvenli dış root'ta unique run klasörü, temporary file
ve `os.replace` zinciri kullanılır. Observation içine raw stdout/stderr, Issue
body veya comment body girmez; yalnız status, ref, hash ve reason kalır.

## Testlerin amacı

Focused test matrisi şu kontratları birlikte kapsar:

- root/branch/HEAD/parent/tree ve master drift;
- ignored/untracked enumeration yasağı;
- GET-only paginated GitHub adapter;
- strict authorization, duplicate key, expiry ve supersession;
- exact record paths ve content exclusion;
- runtime-root guard ve atomik write;
- deterministic blocker precedence ve exit code;
- parseable/sorted CLI JSON output.

Full Python suite ve live integration smoke primary CODE_CHANGE run'ında
çalıştırılmaz; bunlar ayrı `FULL_VALIDATION` approval kapısıdır.

## Şunu şöyle yaptık ki...

- Git komutlarını exact shape allowlist'iyle sınırlandırdık ki yeni kod bile
  yanlışlıkla mutating bir aileyi çalıştıramasın.
- Comment body'yi yalnız parser'ın iç girdisi yaptık ki observation evidence
  içine yetki metni, secret veya serbest kullanıcı içeriği sızmasın.
- Bütün blocker'ları tutup exit code'u sabit precedence ile seçtik ki aynı
  gerçek her çalışmada aynı fail-closed sonucu üretsin.
- Runtime JSON'u repository dışında atomik yazdık ki yarım evidence dosyası
  veya tracked worktree drift'i oluşmasın.
- O1'i O2 policy kararından ayırdık ki observer'ın güvenilirliği action
  otomasyonundan bağımsız kanıtlanabilsin.

## Açık sınırlar

- Approval consumption ve nonce kullanımı yoktur.
- Action admission veya policy engine yoktur.
- SQLite event store yoktur.
- Codex child execution, commit, publish, build ve device runner yoktur.
- Live integration smoke bu koşuda yoktur.
- OpenAI API ve API anahtarı kullanılmamıştır.
