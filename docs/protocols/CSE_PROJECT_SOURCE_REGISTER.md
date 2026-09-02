# CSE Project Source Register — Dynamic Authority v2

**Güncelleme tarihi:** 2026-09-02

Bu register kaynakların rolünü tanımlar; değişken repository durumunu kopyalamaz.

## 1. Aktif kaynaklar

| Kaynak | Yetkili rol | Okuma |
|---|---|---|
| `AGENTS.md` | Günlük execution, lane, süre ve test sahipliği | Her yeni görev/resume |
| `CSE_UNIFIED_PROJECT_SOURCE.md` | Kalıcı ürün amacı ve veri ilkeleri | Ürün/veri kararı gerektiğinde |
| `CSE_V2_SCOPE.md` | Güncel ürün kapsamı ve bağımlılıkları | Kapsam kararı gerektiğinde |
| `ROADMAP.md` | Güncel sıra | Sonraki ürün işi seçilirken |
| `CSE_PROJECT_INSTRUCTIONS.md` | Kritik Git ve kullanıcı verisi güvenliği | İlgili riskte |
| `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | Lane, correction, evidence, publication | STANDARD/CRITICAL veya belirsiz lane |
| `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | Owner test merdiveni ve evidence reuse | Test/gate kararı gerektiğinde |
| `CSE_MODEL_REASONING_ROUTING_POLICY.md` | Reasoning ve kritik review floor | Gerektiğinde |
| `CSE_OWNER_COMMUNICATION_STANDARD.md` | Owner'a anlaşılır sonuç | Önemli durumlarda |
| `CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | Kalıcı STANDARD/CRITICAL handoff | Gerektiğinde |
| `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | Dynamic fresh-chat davranışı | Yeni sohbet/resume |
| current GitHub Issue/PR/commit | Aktif scope ve repository gerçeği | Her görevde |

## 2. Otorite sırası

1. Kalıcı ürün/veri ilkelerinde Unified Project Source.
2. Güncel ürün kapsamında V2 Scope.
3. Güncel sırada Roadmap.
4. Günlük execution/test sahipliğinde `AGENTS.md` ve yeni workflow/validation protokolleri.
5. Aktif teknik kapsamda current owner kararı ve Issue.
6. Değişken repository durumunda GitHub master/branch/PR/commit.
7. `.cse` ve tarihsel kayıtlar yalnız ikincil evidence.

Current Issue safety'yi sessizce zayıflatamaz. Kalıcı politika owner-approved tracked değişiklikle güncellenir.

## 3. Kalıcı belgelerde yasak current-state snapshot'ları

Şunlar kalıcı protokole yazılmaz:

- master SHA;
- schema/backup/app version current değeri;
- aktif Issue/PR;
- açık PR sayısı;
- güncel test sayısı;
- roadmap completion snapshot'ı.

Bu bilgiler current GitHub/repository üzerinden okunur.

## 4. `.cse` rolü

- FAST: kullanılmaz.
- STANDARD: yalnız material izlenebilirlik gerekiyorsa kısa kayıt.
- CRITICAL: provenance/compatibility için kullanılabilir veya zorunlu tutulabilir.
- `.cse/state` current GitHub'ı override edemez.

## 5. Tarihsel kaynaklar

Eski Step/Adım, podcast, handoff, ZIP, Orchestrator, Bridge ve Work Mode kayıtları tarihsel kanıttır; aktif workflow veya roadmap değildir.

Geçmiş Issue/PR/test kaydı geriye dönük yeniden yazılmaz.

## 6. Ana karar

> Kaynak register'ın görevi current state'i kopyalamak değil, hangi soruda hangi kaynağın yetkili olduğunu göstermektir.
