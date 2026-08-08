# CSE New Chat GitHub Bootstrap

**Repository:** `faliardic/chief-site-engineer`
**Default branch:** `master`
**Güncel ürün fazı:** CSE V2
**Kanonik V2 kapsamı:** `docs/v2/CSE_V2_SCOPE.md`

Bu belge, yeni bir CSE sohbetinin ZIP veya manuel handoff istemeden GitHub
repository gerçeğinden devam etme yöntemini tanımlar.

## Kaynak rolleri

| Bilgi | Yetkili yüzey |
| --- | --- |
| Kalıcı ürün amacı ve veri ilkeleri | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` |
| Güncel V2 kapsamı ve bağımlılıkları | `docs/v2/CSE_V2_SCOPE.md` |
| Güncel yürütme sırası | `ROADMAP.md` |
| Operasyon ve Git/Codex güvenliği | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` |
| Doğrulama genişliği ve bütçesi | `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` |
| Repository-level kısa talimat | `AGENTS.md` |
| Aktif görev kapsamı | current GitHub Issue |
| Değişken repository durumu | GitHub `master`, PR, Issue, branch ve commit |
| İkincil factual mirror | `.cse/state/project_state.json` |

Stale state, README, eski roadmap, Epic, ZIP, handoff, Orchestrator, Bridge,
Work Mode veya sohbet hafızası güncel GitHub ve V2 kapsam gerçeğini override
edemez.

## V1 ve V2 başlangıç gerçeği

- V1 tamamlanmıştır.
- Proje sahibi V1'i yaklaşık bir ay gerçek sahada kullanmıştır.
- V1 baseline commit'i:
  `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc`
- Mobil schema `10`, backup formatı `1`, mobil sürüm `0.1.0+1`dir.
- Store/public production release ilan edilmemiştir.
- V2 13 maddelik paketle başlar.
- İlk production yönü Proje ve Mahal omurgasıdır.
- Issue #383 yalnız repository truth-sync işidir.

## Fresh-chat okuma sırası

1. `AGENTS.md`
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. `docs/v2/CSE_V2_SCOPE.md`
6. `ROADMAP.md`
7. Bu bootstrap belgesi
8. `origin/master` HEAD ve son merge durumu
9. açık GitHub Issue ve PR'lar
10. aktif V2 parent Epic ve child Issue
11. ilgili branch/commit diff'i ve completion evidence
12. `.cse/state/project_state.json`
13. aktif `.cse/tasks/<issue_no>_task.md` ve result dosyası

Bu sıra kalıcı politika, güncel ürün kapsamı ve değişken repository durumunu
birbirine karıştırmaz.

## Devam davranışı

Kullanıcı yeni sohbette yalnız:

```text
devam
```

veya:

```text
GitHub'dan devam et
```

yazabilmelidir.

Yeni işlem öncesinde şu bilgiler doğrulanır:

- güncel `master` SHA
- açık PR'lar
- aktif V2 Issue
- parent V2 item
- branch ve expected base
- değişen sözleşme
- izinli dosya/test/gate listesi
- merge veya publication durumu

Kullanıcının uzun instruction veya completion bloklarını tekrar taşıması
beklenmez.

## Minimum yeterli doğrulama

Her teknik Issue şu alanları taşır:

```text
V2 item:
Parent Epic:
Validation class:
Changed contracts:
Allowed paths:
Focused tests:
Allowed broad gates:
Reused evidence:
Schema impact:
Migration impact:
Backup impact:
Attachment impact:
Notification impact:
Minimum field/device acceptance:
Retry budget:
Time budget:
Out of scope:
Stop conditions:
```

Varsayılan:

- dar UI/read-model işi için focused test
- değişmeyen schema/backup/signing/background/reboot kanıtını yeniden kullanma
- aynı source revision üzerinde full gate'i en fazla bir kez çalıştırma
- ortam hatasında yalnız başarısız aşamayı tekrar etme
- bir primary execution ve en fazla bir correction
- dar görevde 45 dakika hard stop
- toolchain sorununu feature scope'una sessizce almama

## GitHub ve execution yüzeyleri

GitHub:

- Issue ve PR
- branch ve merge durumu
- scope ve authorization
- review ve completion kanıtı
- current repository truth

Execution yüzeyi:

- dosya düzenleme
- test ve validation
- commit ve push
- build ve cihaz işlemleri

hangi çalışma ortamı kullanılırsa kullanılsın current Issue allowlist'i,
data-safety sınırı ve Draft PR review kapısı korunur. GitHub üzerinde doğrudan
yapılan documentation/state güncellemesi dahi production kodu veya merge
yetkisini genişletmez.

## Branch standardı

- Production:
  `codex/issue-<issue_no>-<slug>`
- Documentation/state:
  `docs/issue-<issue_no>-<slug>`

Eski `step-*`, Orchestrator, Bridge ve Work Mode branch'leri tarihsel olabilir;
yeni V2 işi bu adlandırmaları kullanmaz.

## Aktif ürün yönü

Güncel 13 maddelik paket:

1. Proje ve Mahal
2. Sicil/Puantaj/Saha Rehberi
3. Attachment/Medya V2
4. Ajanda V2
5. Günlük Log v1
6. İş/Gün Planı
7. İş Zinciri
8. İstenecek Malzemeler
9. Deterministik öneriler
10. Telefon görüşmesi → Ajanda
11. Proje albümü
12. Günlük Log v2
13. Mini hesap makinesi

Orchestrator, Bridge, Work Mode, Universal Capture, AI, Beton V2, Kroki,
Look-ahead ve PC sync güncel V2 production sırasının parçası değildir.

## Güvenlik sınırı

- Gerçek kullanıcı data root'u current Issue açıkça izin vermedikçe okunmaz.
- Uninstall, clear-data, hard-delete ve force-push varsayılan yasaktır.
- Backup, schema, migration ve signing çalışması ayrı kapsam ister.
- Merge, release ve store publication kullanıcı onayı gerektirir.
- Geçmiş kanıt geriye dönük uydurulmaz veya yeniden yazılmaz.
