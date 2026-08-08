# CSE Project Source Register

**Belge türü:** Proje kaynak kaydı
**Güncelleme Issue:** #383
**Güncelleme tarihi:** 8 Ağustos 2026

Bu dosya CSE için kalıcı ürün kaynaklarını, güncel V2 yürütme kaynaklarını,
destekleyici tarihsel kaynakları ve otorite sınırlarını kaydeder.

## 1. Kanonik aktif kaynaklar

| Source | Repository path | Yetkili rol | Durum |
| --- | --- | --- | --- |
| Birleştirilmiş Proje Kaynağı | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | Kalıcı ürün amacı, tek kullanıcı modeli, veri ilkeleri ve uzun vadeli mimari | Aktif kalıcı kaynak |
| CSE V2 Kanonik Kapsamı | `docs/v2/CSE_V2_SCOPE.md` | Güncel 13 maddelik V2 kapsamı, bağımlılıklar, V2 dışı alanlar ve DoD | Aktif güncel yürütme kaynağı |
| CSE V2 Roadmap | `ROADMAP.md` | Güncel dalga, sıra, geçiş kapısı ve ilk production yönü | Aktif güncel sıra |
| Proje Talimatları | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | Git/GitHub/execution güvenliği ve operasyon protokolü | Aktif operasyon kaynağı |
| Minimum Yeterli Doğrulama | `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | Validation class, evidence reuse, retry/time budget ve gate genişliği | Aktif doğrulama kaynağı |
| Repository giriş talimatı | `AGENTS.md` | Zorunlu pre-read ve kısa enforcement | Aktif |
| New Chat Bootstrap | `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | Yeni sohbetin GitHub'dan güncel V2 bağlamıyla devamı | Aktif |
| Machine-readable state | `.cse/state/project_state.json` | Son yayımlanmış/finalized checkpoint ve aktif Issue snapshot'ı | İkincil factual mirror |

## 2. Otorite ve çakışma kuralları

1. Kalıcı ürün amacı ve veri ilkelerinde Unified Project Source üst kaynaktır.
2. Güncel ürün paketi ve bağımlılıklarında `docs/v2/CSE_V2_SCOPE.md` üst
   kaynaktır.
3. Güncel sıra ve dalga durumunda `ROADMAP.md` esas alınır.
4. Aktif teknik kapsam current GitHub Issue tarafından daraltılır.
5. Current Issue V2 kapsamını sessizce genişletemez ve safety kurallarını
   zayıflatamaz.
6. `.cse/state`, README, podcast, handoff, ZIP veya sohbet hafızası current Git
   ve GitHub gerçeğini override edemez.
7. Geçmiş Issue/PR/test/podcast kaydı geriye dönük yeniden yazılmaz.
8. V1 saha kullanımı, store/public release iddiası değildir.

## 3. V1 kapanış kaynağı

V1 baseline:

```text
commit: 7c9f65a811c9f4bca561adab6bd1f8e64e6908cc
pull request: #382
mobile version: 0.1.0+1
schema: 10
backup format: 1
```

Proje sahibi V1'in yaklaşık bir ay gerçek sahada kullanıldığını ve V1 ürün
fazının tamamlandığını bildirmiştir. Bu karar, geriye dönük günlük test kanıtı
veya store release kaydı üretmez.

## 4. Tarihsel geliştirici otomasyonu kaynakları

Aşağıdaki belgeler korunur; fakat aktif V2 ürün roadmap'i değildir:

| Source | Path | Tarihsel rol |
| --- | --- | --- |
| Orchestrator Architecture | `docs/orchestrator/CSE_ORCHESTRATOR_ARCHITECTURE.md` | Geliştirici otomasyon mimarisi |
| Orchestrator State Machine | `docs/orchestrator/CSE_ORCHESTRATOR_STATE_MACHINE.md` | Yürütme state modeli |
| Orchestrator Security Boundary | `docs/orchestrator/CSE_ORCHESTRATOR_SECURITY_BOUNDARY.md` | Tooling güvenlik araştırması |
| Orchestrator Approval Model | `docs/orchestrator/CSE_ORCHESTRATOR_APPROVAL_MODEL.md` | Tooling approval modeli |
| Orchestrator MVP Plan | `docs/orchestrator/CSE_ORCHESTRATOR_MVP_PLAN.md` | O0–O10 tarihsel program |

Bridge ve Work Mode Issue/branch/PR kayıtları da tarihsel developer-tooling
kanıtıdır. V2 product item'larını bloke etmez ve V2 milestone'una alınmaz.

## 5. Tarihsel ürün ve araştırma kaynakları

| Original title | Repository copy | Durum |
| --- | --- | --- |
| `Şantiye Şefi İçin Dünya Örneklerine Dayalı Kontrol, Takip ve Arşivleme Sistemi Yol Haritası.pdf` | None | Bu ortamda yok; içerik uydurulmaz |
| `CHIEF_SITE_ENGINEER_Guncel_Yol_Haritasi_Ozel_Alan_Ekli.pdf` | None | Bu ortamda yok; içerik uydurulmaz |
| `CSE_CHAT_HANDOFF_PROTOCOL_SOURCE_PACKAGE.zip` | None | Raw ZIP commitlenmez |
| `1. CSE önce güvenilir veri omurgası.txt` | `docs/reference_sources/cse_once_guvenilir_veri_omurgasi.txt` | Tracked supporting source |
| `CSE_STRATEGIC_PRODUCT_DIRECTION.md` | None | Bu ortamda yok; içerik uydurulmaz |
| Birleştirilmiş proje kaynağının repository kopyası | `docs/reference_sources/chief_site_engineer_exe_birlestirilmis_proje_kaynagi.md` | Tarihsel provenance |

## 6. Source handling rules

- Duplicate `(1)` kopyaları commitlenmez.
- Raw handoff ZIP paketleri commitlenmez.
- Erişilemeyen PDF/TXT/Markdown/ZIP içeriği uydurulmaz.
- Original title bilgisi register içinde korunur.
- Yeni kalıcı ürün kararı yetkili Issue ve tracked canonical kaynakla
  kaydedilir.
- Yeni V2 production işi başlamadan V2 scope, roadmap, current Issue ve
  validation protocol okunur.
- V2 dışında kalan fikirler silinmez; post-V2 backlog veya tarihsel kaynak olarak
  sınıflandırılır.
- Store release, field acceptance ve production readiness birbirinin yerine
  kullanılmaz.
