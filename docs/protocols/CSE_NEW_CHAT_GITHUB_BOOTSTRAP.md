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
| Kaynak rolleri ve tarihsel otorite kaydı | `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` |
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
- V1 tarihsel baseline metadata'sı mobil schema `10`, backup formatı `1` ve
  mobil sürüm `0.1.0+1`dir.
- Store/public production release ilan edilmemiştir.
- Güncel V2 teknik zemini safe merge
  `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd`, mobil schema `14`, backup
  formatı `1` ve mobil sürüm `0.1.0+1`dir.
- Revised V2 paketi 13 maddelidir; yalnız Items `1..4` complete, Item `5`
  current ve not complete'tir.
- Living Plan UI/APK/device acceptance henüz yoktur.
- Issue #383 eski repository truth-sync bağlamıdır; current production gate'i
  değildir.

## Fresh-chat okuma sırası

1. `AGENTS.md`
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md`
5. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
6. Bu bootstrap belgesi
7. `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
8. `docs/v2/CSE_V2_SCOPE.md`
9. `ROADMAP.md`
10. current GitHub Issue ve bütün scope/izin yorumları
11. aktif `.cse/tasks/<issue_no>_task.md`
12. current `origin/master` HEAD, son merge durumu ve açık PR'lar
13. ilgili branch/commit diff'i ve completion evidence
14. `.cse/state/project_state.json`
15. aktif `.cse/results/<issue_no>_result.md`

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

Güncel revised 13 maddelik paket:

1. Proje ve Mahal omurgası — complete
2. Sicil / Puantaj V2 / Saha Rehberi — complete
3. Attachment / Fotoğraf / Medya V2 — complete
4. Ajanda V2 + Ajanda–Hatırlatıcı kontrollü senkron — complete
5. 7 Günlük Yaşayan İş Programı / İş ve Gün Planı — current, not complete
6. Günlük Log Çıktısı v1
7. İş Zinciri / Bağlı Log v1
8. İstenecek Malzemeler
9. Deterministik kişi/firma/etiket önerileri
10. Telefon görüşmesi sonucu → Ajanda
11. Proje fotoğraf/video albümü
12. Günlük Log Çıktısı v2
13. Mini hesap makinesi

Scoped yedi günlük look-ahead/WBS davranışı revised Item 5'in parçasıdır.
Actual quantity/progress/reforecast ve project-specific productivity learning,
ilk usable UI/device pilotundan sonraki Living Plan evolution'ıdır; MVP Core
veya ilk UI kapsamında değildir, fakat current direction'dan çıkarılmamıştır.
İlk UI tek başına Item 5'i complete yapmaz; final completion sınırı sonraki
owner kararı ve executable evidence'a bağlıdır. Items 6–13'ün sırası değişmez.

Orchestrator, Bridge, Work Mode, Universal Capture, AI, Beton V2, Kroki, full
Gantt/Primavera replacement, approved baseline, critical path/float, resource
optimization ve PC sync ilk UI öncesi veya broader V2 paketi dışındadır.

## Güvenlik sınırı

- Gerçek kullanıcı data root'u current Issue açıkça izin vermedikçe okunmaz.
- Uninstall, clear-data, hard-delete ve force-push varsayılan yasaktır.
- Backup, schema, migration ve signing çalışması ayrı kapsam ister.
- Merge, release ve store publication kullanıcı onayı gerektirir.
- Geçmiş kanıt geriye dönük uydurulmaz veya yeniden yazılmaz.
