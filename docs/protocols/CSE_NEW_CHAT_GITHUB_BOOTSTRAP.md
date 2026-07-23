# CSE New Chat GitHub Bootstrap

**Repository:** `faliardic/chief-site-engineer`

**Default branch:** `master`

**Official local execution repository:** `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

Bu belge, yeni bir CHIEF SITE ENGINEER sohbetinin ZIP veya handoff paketi istemeden GitHub repository gerçeğinden devam etme yöntemini tanımlar.

## Kaynak rolleri

| Bilgi | Yetkili yüzey |
| --- | --- |
| Kalıcı ürün yönü | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` |
| Operasyon ve Git/Codex güvenliği | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` |
| Doğrulama genişliği, süre/retry bütçesi ve kanıt yeniden kullanımı | `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` |
| Repository-level Codex kısa talimatı | `AGENTS.md` |
| Aktif görev kapsamı | current GitHub Issue |
| Değişken repository durumu | GitHub `master`, PR, Issue, branch ve commit kanıtı |
| İkincil factual mirror | `.cse/state/project_state.json` |

Stale state, README, ROADMAP, ZIP, handoff veya sohbet hafızası güncel GitHub kanıtını override edemez.

Tek kullanıcılı kişisel saha asistanı dönüşümünün bağlayıcı üst yol haritası GitHub Epic #105’tir. Yeni sohbet, kullanıcı modelini multi-user/role/tenant/SaaS yönüne genişleten veya mobil/offline/bildirimi saha pilotu sonrasına atan eski metinleri current product direction olarak kullanmaz.

## Fresh-chat okuma sırası

1. `AGENTS.md`
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. Bu bootstrap belgesi
6. `origin/master` HEAD ve son merge durumu
7. açık GitHub Issue ve PR'lar
8. aktif işin bağlı olduğu üst Epic veya bağlayıcı yol haritası
9. ilgili branch/commit diff'i ve current Issue completion evidence'i
10. `.cse/state/project_state.json`
11. aktif `.cse/tasks/<issue_no>_task.md` ve ilgili `.cse/results/<issue_no>_result.md`

Bu sıra kalıcı politika ile değişken repository durumunu birbirine karıştırmaz.

## Minimum yeterli doğrulama zorunluluğu

Yeni sohbet her teknik işi başlatmadan önce current Issue içinde şu alanları doğrular veya ekler:

```text
Validation class:
Changed contracts:
Focused tests:
Allowed broad gates:
Reused evidence:
Minimum physical-device acceptance:
Retry budget:
Time budget:
Out of scope:
Stop conditions:
```

Varsayılan davranış:

- dar UI/read-model işi için odaklı test;
- değişmeyen schema, backup, signing, background/reboot ve release kanıtının yeniden kullanımı;
- aynı source revision üzerinde full gate'in en fazla bir kez çalışması;
- ortam hatasında yalnız başarısız aşamanın tekrarı;
- bir primary Codex run + en fazla bir correction run;
- dar görevde 45 dakika hard stop;
- toolchain/release sorununun feature branch'e sessizce alınmaması.

Yeni sohbet, “daha fazla kanıt daha güvenlidir” varsayımıyla Issue kapsamını genişletemez. Risk sınıfı ve değişen sözleşme ne gerektiriyorsa yalnız o kadar doğrulama ister.

## Continuation davranışı

Kullanıcı yeni sohbette yalnız şunu yazabilmelidir:

```text
devam
```

veya:

```text
GitHub'dan devam et
```

ChatGPT yeni işlem öncesinde GitHub Issue, PR, branch, diff, yorum, merge state ve beklenen base SHA'yı doğrular. Kullanıcının uzun instruction veya completion bloklarını ChatGPT ile Codex arasında taşıması beklenmez.

## ZIP veya handoff gerekmez

Normal devam için handoff ZIP, source ZIP, kopyalanmış prompt veya manuel durum raporu gerekmez. `chat_handoff/` yardımcı ve tarihseldir; Git, GitHub veya current Issue yerine geçmez.

Mevcut ignored ZIP yalnız emergency/offline backup artifact'ıdır. GitHub geçici olarak erişilemiyorsa stale ZIP, memory veya handoff'a sessizce düşülmez; current repository truth'un doğrulanamadığı açıkça söylenir.

## GitHub ve yerel execution yüzeyleri

GitHub şu işler için koordinasyon ve repository-truth yüzeyidir:

- Issue ve PR;
- branch ve merge durumu;
- diff ve review;
- continuation kararı;
- validation class ve execution budget kaydı.

Resmî `V:` repository şu işler için execution yüzeyidir:

- local dosya düzenleme;
- test ve validation;
- path, hash, ZIP, export ve worktree kontrolü;
- branch oluşturma veya checkout;
- commit ve push.

GitHub connector üzerinden proje dosyası üretmek yerel uygulama tamamlandı anlamına gelmez.

## Codex çağırma kuralı

ChatGPT local execution gerekiyorsa kullanıcıya açıkça şunu söyler:

```text
Codex çalışmalı
```

Yalnız GitHub-native inceleme, planlama, Issue/PR/comment/review/merge-state veya kavramsal analiz için Codex normalde gerekmez.

## Issue merkezli branch standardı

Yeni branch adları:

```text
codex/issue-<issue_no>-<slug>
```

Eski `step-NNN-*` branch'ler tarihsel olarak korunur ve yeniden adlandırılmaz. Aynı anda yalnız bir aktif production implementation görevi ve en fazla bir incelemede PR bulunur.

## Codex pre-read hizalaması

Her Codex görevi şu sırayı uygular:

1. root `AGENTS.md`;
2. unified product source;
3. operational instructions;
4. minimum sufficient validation protocol;
5. current GitHub Issue ve scope/izin yorumları;
6. `.cse/tasks/<issue_no>_task.md`.

Source-authority veya bootstrap görevinde ayrıca bu bootstrap belgesi ve source register okunur.

Sonra resmî `V:` root, `origin/master` SHA, expected base SHA ve divergence doğrulanır; koşullar sağlanmadan edit yapılmaz.
