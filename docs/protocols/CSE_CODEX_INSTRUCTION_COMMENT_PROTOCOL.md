# CSE Codex Instruction Comment Protocol — Risk-Based v2

**Geçerlilik tarihi:** 2026-09-02

GitHub comment bir amaç değil, kalıcı ve kritik handoff gerektiğinde kullanılan araçtır.

## 1. FAST

FAST işte GitHub instruction comment oluşturulmaz.

Chat içindeki kısa görev yeterlidir:

```text
Goal:
Allowed paths:
Do not change:
Execution time budget: <ChatGPT'nin bu görev için verdiği açık süre; her Codex handoff'unda zorunlu>
Fatih validation:
Commit/push boundary:
```

Issue, comment ID, authority zinciri, routing YAML veya uzun evidence beklenmez.

## 2. STANDARD

STANDARD işte:

- tek Issue veya kısa self-contained task kullanılabilir;
- resume/correction için mevcut Issue yeterliyse yeni comment yazılmaz;
- kalıcı handoff gerekiyorsa 10–20 satırlık kısa comment kullanılır;
- aynı scope correction için yeni owner authority/comment turu açılmaz.

Minimum comment:

```text
Base/branch:
Goal:
Allowed paths:
Protected contracts:
Execution time budget: <ChatGPT'nin bu görev için verdiği açık süre; her Codex handoff'unda zorunlu>
Fatih validation:
Stop conditions:
Publication boundary:
```

## 3. CRITICAL

CRITICAL execution/correction/review handoff'u GitHub Issue veya PR üzerinde self-contained comment olarak yayımlanır.

Comment gerektiği kadar şunları taşır:

- owner authority;
- expected base/branch/head;
- okunacak kritik kaynaklar;
- exact allowlist;
- required behavior;
- identity/schema/backup/security gibi korunacak contractlar;
- validation ve compatibility gate;
- destructive/user-data sınırı;
- stop conditions;
- commit/push/Ready/merge/release sınırı;
- final provenance beklentisi.

## 4. Kullanıcıya cevap

Comment oluşturulduysa kullanıcıya:

- Issue/PR;
- comment ID/link;
- tek cümlelik pratik amaç

verilir. Uzun comment tekrar chat'e yapıştırılmaz; kullanıcı isterse gösterilir.

## 5. GitHub yazma erişimi yoksa

Comment oluşturulduğu iddia edilmez. CRITICAL iş başlamaz; geçici chat taslağı canonical handoff sayılmaz.

FAST/uygun STANDARD iş, owner'ın current chat talimatıyla ve diğer güvenlik sınırları uygunsa devam edebilir.

## 6. Ana karar

> GitHub instruction comment FAST için yasak gereksiz törendir, STANDARD için koşullu araçtır, CRITICAL için kalıcı güvenlik sözleşmesidir.
