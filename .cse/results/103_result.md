# Issue 103 Result - Kanonik Proje Talimatları v2 ve Repository Truth

## Özet

Issue #103, CSE'nin ürün kimliğini local-first **Saha Komuta Sistemi** ve `Yakala -> İşle -> Takip et -> Doğrula -> Günlüğe al` döngüsüyle kanonikleştirdi. Kalıcı ürün politikası, operasyon güvenliği, aktif Issue kapsamı ve değişken GitHub repository durumu ayrı otorite yüzeylerine ayrıldı.

README, ROADMAP ve `.cse/state`; Issue #102 / PR #104 / merge commit `9b25152ae38b72470e332929cb3a30ff955b75f1` sonrasındaki gerçek Local Field MVP ve Saha Takibi durumuyla hizalandı. Production Python, test davranışı, schema, UI, workflow ve dependency değiştirilmedi.

## Başlangıç ve senkronizasyon kanıtı

Resmî repository:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Başlangıçta:

```text
master = origin/master = 9b25152ae38b72470e332929cb3a30ff955b75f1
origin/master...master = 0 0
EXPECTED_ISSUE_102_PR = 104
```

Branch:

```text
codex/issue-103-canonical-instructions-v2
```

Önceden var olan untracked `reports/` kullanıcı dosyaları kapsam dışı bırakıldı ve değiştirilmedi.

## Model ve reasoning

- Codex modeli: current selector'daki en güçlü full Codex modeli (bu çalışma: GPT-5)
- Reasoning: `Extra High`
- Neden: Kalıcı source authority, çoklu belge tutarlılığı, tarihsel kayıtların korunması ve repository truth drift temizliği yüksek çelişki riski taşır.

## Kanonik ürün kararları

- CSE, büyük platformların küçültülmüş kopyası değil local-first Saha Komuta Sistemi olarak tanımlandı.
- Gerçek kullanıcı problemi; kâğıt not, hızlı saha hesabı, zihinde taşınan dönüş bekleme, hatırlatıcı ve gün sonunda tekrar yazma olarak kaydedildi.
- Saha Takibi v0.1 birinci production önceliği olarak korundu.
- Domain/recurrence ile SQLite schema v3 persistence tamamlandı; application service/backfill, backup compatibility, resmî export izolasyonu ve UI bekliyor olarak işaretlendi.
- Kayıtlı mühendislik hesap defteri minimum UI ve saha pilotundan sonraya yerleştirildi; kişisel hesap otomatik resmî metraj sayılmadı.
- Günlük, kaynak kayıtlardan oluşturulan ve akşam kontrol edilip yayımlanan değişmez snapshot olarak tanımlandı.
- Canlı Proje Haritası source record değil read-model/projeksiyon olarak tanımlandı; dokunarak odaklanma ve wheel/pinch/pan/serbest zoom yasağı kaydedildi.
- `Bugün`, `Harita`, kayıt çalışma alanı ve `Günlük` soruları birbirinden ayrıldı.
- Auth olmayan local MVP'de “kişisel” kavramının cryptographic privacy iddiası taşımadığı açıklandı.

## Operasyon ve repository truth kararları

- Kalıcı ürün yönü, operasyon talimatı, aktif görev ve değişken repository durumu ayrı yetkili yüzeylere ayrıldı.
- `.cse/state`, README, ROADMAP, handoff ve ZIP ikincil kaynaklardır; GitHub current truth'u override edemez.
- `CSE_PROJECT_INSTRUCTIONS.md` içindeki sabit Step 224/225, commit ve test snapshot'ları kaldırıldı; yerlerine current-state doğrulama prosedürü yazıldı.
- Yeni branch standardı `codex/issue-<issue_no>-<slug>` oldu; eski `step-NNN-*` branch'ler tarihsel bırakıldı.
- Aynı anda yalnız bir aktif production implementation görevi ve en fazla bir incelemede PR kuralı korundu.
- Ignored root instruction mirror bu görevde değiştirilmedi ve current sync'i kanıtlanmış sayılmadı.

## README current-capability özeti

README artık şunları gerçek merge edilmiş kabiliyetler olarak açıklar:

- SQLite persistence ve migration runner;
- managed attachment store ve integrity;
- local Flask web;
- proje/gözlem create-list-detail-update, arama ve revision conflict koruması;
- günlük export;
- backup/verify/izole restore;
- Windows tek tık launcher;
- Saha Takibi domain/recurrence;
- schema v3 tracking repository/event persistence.

README aynı zamanda auth/TLS/cloud/PWA/background notification/application service/UI ve field-ready kabulünün bulunmadığını açıkça korur.

## Değişen dosyalar

```text
.cse/tasks/103_task.md
.cse/results/103_result.md
.cse/state/project_state.json
README.md
ROADMAP.md
CHANGELOG.md
docs/project_decisions.md
docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md
learning/issue_103_kanonik_talimatlar_v2_ve_repository_truth.md
```

## Test ve kalite kanıtı

Full suite:

```text
python -m pytest -rs
788 passed, 7 skipped in 14.84s
```

Yedi skip, Windows symlink oluşturma ayrıcalığı bulunmayan mevcut güvenlik testleridir.

Python compile:

```text
python -m compileall -q app scripts
passed
```

Diğer kontroller:

```text
python -m json.tool .cse/state/project_state.json: passed
git diff --check: passed
git diff -- app tests .github/workflows requirements.txt: empty
exports/: only .gitkeep
CSE_DATA_ROOT environment variable: unset
```

## Protected path ve artifact kanıtı

- Production `app/`, `tests/`, `.github/workflows/` ve `requirements.txt` diff'i boştur.
- `reports/` dosyaları untracked ve unstaged kalmıştır:
  - `claude_CSE_Degerlendirme_Raporu.docx`: SHA-256 `3B2DB82D556D7D4591B049BCD95B03A7E2973EA43822CE2C60DC660B38899A13`
  - `CSE_BAGIMSIZ_TEKNIK_URUN_DENETIM_RAPORU_2026-07-12.md`: SHA-256 `F8D3CBB2111EC7BBD12EEF673720EA3E54B2558E7545817D3E72DF18C083A1A9`
- Ignored güvenlik ZIP'i korunmuştur: SHA-256 `E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653`.
- Gerçek kullanıcı data root'una erişilmedi; migration veya uygulama launcher'ı çalıştırılmadı.
- Backup, restore veya export artifact'ı üretilmedi.

## Kapsam sınırı

- Production Python davranışı değişmedi.
- Schema/migration/repository/application service değişmedi.
- Test/fixture ve web UI değişmedi.
- Dependency ve GitHub Actions değişmedi.
- `reports/`, `exports/.gitkeep`, ignored ZIP/cache ve kullanıcı verisi korunmuştur.
- PR açılmadı, merge veya branch deletion yapılmadı.

## Publication durumu

Bu dosya pre-publication evidence'i içerir. Final commit SHA, local/remote branch eşitliği, upstream divergence ve final status metadata churn oluşturmamak için Issue #103 completion yorumunda kaydedilir.

## Sonraki dar production adımı

Saha Takibi `FollowUpApplicationService` ve `RoutineApplicationService` ile yedi günlük idempotent lazy backfill orchestration ayrı GitHub Issue kapsamında uygulanmalıdır. Backup compatibility, resmî export izolasyonu ve minimum UI bundan sonra sırayla gelir.
