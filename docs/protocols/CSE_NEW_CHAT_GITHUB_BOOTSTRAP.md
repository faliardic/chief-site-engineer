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
| Aktif görev kapsamı | current GitHub Issue |
| Değişken repository durumu | GitHub `master`, PR, Issue, branch ve commit kanıtı |
| İkincil factual mirror | `.cse/state/project_state.json` |

Stale state, README, ROADMAP, ZIP, handoff veya sohbet hafızası güncel GitHub kanıtını override edemez.

## Fresh-chat okuma sırası

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. Bu bootstrap belgesi
4. `origin/master` HEAD ve son merge durumu
5. açık GitHub Issue ve PR'lar
6. ilgili branch/commit diff'i ve current Issue completion evidence'i
7. `.cse/state/project_state.json`
8. aktif `.cse/tasks/<issue_no>_task.md` ve ilgili `.cse/results/<issue_no>_result.md`

Bu sıra kalıcı politika ile değişken repository durumunu birbirine karıştırmaz.

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
- continuation kararı.

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

Source-authority veya bootstrap görevi yapan Codex şu sırayı uygular:

1. unified product source;
2. operational instructions;
3. bu bootstrap belgesi;
4. current GitHub Issue ve scope/izin yorumları;
5. `.cse/tasks/<issue_no>_task.md`.

Sonra resmî `V:` root, `origin/master` SHA, expected base SHA ve divergence doğrulanır; koşullar sağlanmadan edit yapılmaz.
