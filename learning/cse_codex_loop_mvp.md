# CSE Codex Loop MVP Öğrenme Notu

## Amaç

Bu adımda eski API-key tabanlı kod üretim köprüsünün yerine, kullanıcının zaten
kimlik doğruladığı yerel Codex CLI oturumunu kullanan küçük bir orchestrator
kurduk. Ürün/mobile koduna dokunmadan Issue’dan implementasyon, bağımsız review,
tek correction ve Draft PR sınırını yürütülebilir hâle getirdik.

## Gerçek çalışma akışı

```text
trusted Issue onayı
-> origin/base dış worktree
-> Codex workspace-write implementer
-> host allowed-path kontrolü
-> host validation komutları
-> Codex read-only yapılandırılmış review
-> gerekirse tek workspace-write correction
-> aynı scope + validation + review
-> commit + normal push + Draft PR
-> READY_FOR_FATIH + başarılı worktree cleanup
```

Hata halinde terminal sonuç `FAILED` veya `NEEDS_HUMAN` olur ve worktree tanı
için yerinde kalır.

## Gerçek koddan önemli parçalar

Implementer prompt’u process argümanında veya logda taşınmaz; stdin üzerinden
gönderilir:

```python
result = command(
    (
        str(config.codex_path),
        "exec",
        "--ephemeral",
        "--sandbox",
        "workspace-write",
        "-C",
        str(worktree),
        "-",
    ),
    worktree,
    3600,
    prompt,
)
```

Reviewer ayrı process ve salt-okunur sandbox’tır:

```python
(
    str(config.codex_path),
    "exec",
    "--ephemeral",
    "--sandbox",
    "read-only",
    "-C",
    str(worktree),
    "--output-schema",
    str(schema_path),
    "--output-last-message",
    str(result_path),
    "review",
    "--uncommitted",
)
```

Issue validation metni doğrudan shell’e verilmez. Önce mevcut
`validate_command` allowlist’i parse eder; `python` ve `git` adları installer’ın
çözdüğü kesin executable yollarıyla değiştirilir. `subprocess.run(...,
shell=False)` bu argv listesini çalıştırır.

## Kullanılan teknik kavramlar

- **External Git worktree:** Kanonik checkout’u branch değiştirmeden aynı
  repository’nin ayrı çalışma ağacını üretir.
- **Deterministic host gate:** Modelin sonucunu modelin kendi iddiasıyla değil,
  sabit host komutları ve return code’larıyla doğrular.
- **Independent review:** Implementer bağlamından ayrı ephemeral process’in
  uncommitted diff’i read-only incelemesidir.
- **Fail closed:** Belirsiz JSON, ikinci review reddi, scope ihlali veya subprocess
  hatası publication’a devam etmez.
- **Bounded rotation:** Run kayıtları sınırsız büyümez; en yeni yapılandırılmış
  sayı korunur.

## Testlerin amacı

Unit testler no-task idle, trusted approval, dış worktree, implementer argv’si,
scope ihlali, validation failure, review approval, tek correction, çözülemeyen
ikinci review, terminal yorumlar, cleanup, hata worktree’sinin korunması ve
secret-free log sözleşmelerini mock eder.

Windows integration testi gerçek `shell=False` subprocess sınırında stub
`codex/git/python/gh` executable’ları kullanır. Ağ veya cihaz olmadan şu sırayı
kanıtlar:

```text
Issue -> implement -> review changes_requested
-> correction -> review approved -> commit -> push -> Draft PR
```

Eski bridge testleri de aynı validation komutunda tekrar çalıştırılır; böylece
mevcut parser, approval, local bridge ve API bridge davranışlarının kırılmadığı
görülür.

## Teknik kararlar

- Yeni orchestrator eski `parse_task`, `validate_command`, `path_allowed`,
  trusted approval ve `GitHubClient` davranışını yeniden kullanır.
- Responses yürütücüsü, OpenAI SDK, API key dosyası ve Actions kullanılmaz.
- Review bulgusu düzeltmeye girdi olur ama GitHub yorumuna veya ham loga
  kopyalanmaz.
- Scheduled Task kurulum sonunda Disabled’dır; ilk smoke ve aktivasyon iki ayrı
  manuel karardır.

## “Şunu şöyle yaptık ki...”

- Worktree’yi repository dışına koyduk ki kanonik checkout hiçbir görevde branch
  değiştirmesin.
- Codex prompt’unu stdin’den verdik ki tam Issue-derived prompt process listesi
  veya run loguna yazılmasın.
- Validation komutunu argv’ye ayırıp `shell=False` çalıştırdık ki Issue metni
  shell metakarakterleriyle yeni yetki kazanamasın.
- Reviewer’ı read-only ve ephemeral çalıştırdık ki review implementasyonu
  sessizce değiştiremesin.
- Correction sayısını kod akışında bire sabitledik ki tekrar bütçesi model
  davranışına bağlı olmasın.
- Başarısız worktree’yi koruduk ki hata kanıtı kaybolmadan insan incelemesi
  yapılabilsin.

## Bilinçli sınırlar

Bu MVP scheduler’ı otomatik etkinleştirmez, merge etmez, force-push yapmaz,
başarısız branch/worktree silmez ve product/mobile, release, cihaz, backup veya
kullanıcı verisi alanlarına girmez. İlk smoke yalnız read-only CLI bağlantı
kanıtıdır.
