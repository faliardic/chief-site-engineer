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
-> güvenli ve sınırlı worktree cleanup
-> READY_FOR_FATIH + approved
```

Hata halinde terminal sonuç `FAILED` veya `NEEDS_HUMAN` olur ve worktree tanı
için yerinde kalır. Ancak implementasyon, validation, review, commit, normal
push ve Draft PR zaten tamamlandıysa cleanup problemi yayımlanmış işi geriye
dönük başarısız yapmaz:

```text
cleanup tamamlanamadı
-> worktree manuel cleanup için korunur
-> READY_FOR_FATIH + Draft PR URL
-> PASS / approved_cleanup_pending
```

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

Cleanup da aynı exact-argv sınırını kullanır. Dosya silme kapısı, yalnız status,
branch ve commit birlikte doğrulanırsa açılır:

```python
status = ("status", "--porcelain=v1", "--untracked-files=all")
branch = ("symbolic-ref", "--quiet", "HEAD")
head = ("rev-parse", "--verify", "HEAD")
remove = ("worktree", "remove", "--force", str(worktree))
registration = ("worktree", "list", "--porcelain", "-z")
```

Remove tekrar sayısı sabittir. Registration çıktısı NUL ayrımlı porcelain kayıtlar
olarak parse edilir ve yalnız kesin Issue worktree yolu karşılaştırılır. Otomatik
cleanup hiçbir zaman repository-wide `git worktree prune` çalıştırmaz. Dizin
yoksa veya başarısız remove sonrasında kesin yol artık kayıtlı değilse cleanup
tamamdır. Kesin yol kayıtlı kalıyorsa worktree/metadata korunur ve sonuç pending
olur. Dosya sistemi fallback’i ancak kayıt kaldırılmışsa ve aynı
clean/branch/commit kapısı yeniden geçerse kullanılabilir; dirty veya başka
branch/commit gösteren worktree silinmez.

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

Cleanup odaklı testler normal başarıyı, ilk remove hatasından sonraki başarıyı,
zaten bulunmayan ve kayıtlı olmayan path’in tamamlanmasını, kayıtlı kalan path’in
korunmasını, başarısız remove sonrası kaydı kalkmış path’i, dirty worktree’nin
korunmasını ve yayın sonrası kalıcı cleanup hatasının `FAILED` yerine
`READY_FOR_FATIH + approved_cleanup_pending` üretmesini ayrı ayrı kanıtlar.
Issue worktree ile ilgisiz stale worktree kaydını aynı fixture’da taşıyan
regresyon testi, hiçbir prune argv’si çağrılmadığını ve ilgisiz metadata’nın
değişmeden kaldığını ayrıca kanıtlar.

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
- Draft PR oluşturulduktan sonraki cleanup bir publication sonucu değil, host
  housekeeping sonucudur; bu yüzden cleanup uyarısı PASS semantiğini bozmaz.

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
- Cleanup öncesinde clean/branch/commit üçlüsünü doğruladık ki `--force` veya
  dosya sistemi fallback’i yayınlanan commit dışındaki yerel emeği silemesin.
- Worktree kayıtlarını `--porcelain -z` ile salt-okunur ve kesin Issue yolu
  üzerinden inceledik ki otomatik cleanup ilgisiz stale metadata’yı değiştirmesin.
- Repository-wide prune’u otomatik cleanup’tan tamamen çıkardık ki tarihsel veya
  başka Issue’lara ait worktree kayıtlarına dokunulmasın.
- Yayın sonrası kalıcı cleanup hatasını `approved_cleanup_pending` yaptık ki
  hazır Draft PR sırf Windows dosya kilidi yüzünden sıradan `FAILED` görünmesin.

## Bilinçli sınırlar

Bu MVP scheduler’ı otomatik etkinleştirmez, merge etmez, force-push yapmaz,
başarısız branch/worktree silmez ve product/mobile, release, cihaz, backup veya
kullanıcı verisi alanlarına girmez. İlk smoke yalnız read-only CLI bağlantı
kanıtıdır.
