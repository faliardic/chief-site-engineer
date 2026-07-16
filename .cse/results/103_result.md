# Issue 103 Result - Kanonik Proje Talimatları v2 ve Repository Truth

> Bu dosyanın “İlk commit kanıtı” bölümleri `2dd38cff15bd428f0075724848d779f0e4970184` commit’inin tarihsel evidence kaydıdır. Geniş kullanıcı geleceği, geç mobil öncelik ve hesap/günlük sıralamasıyla ilgili çelişen kararlar Issue #103’ün nihai yorumu ve Epic #105 tarafından geçersiz kılınmıştır; ilk kanıt silinmemiştir.

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

---

## Nihai Epic #105 düzeltmesi

### Çalıştırma ve Git ön kontrolü

Nihai düzeltme aynı branch üzerinde, ilk commit değiştirilmeden başlatıldı:

```text
branch = codex/issue-103-canonical-instructions-v2
previous_head = 2dd38cff15bd428f0075724848d779f0e4970184
remote_branch_divergence = 0 0
origin_master...previous_head = 0 1
tracked_changes_before_correction = none
```

Önceden bulunan `reports/` kullanıcı dosyaları ve ignored ZIP/cache korundu. Yeni branch açılmadı; amend, rebase, reset, stash, clean veya force-push yapılmadı.

### Epic #105 ile hizalanan nihai kararlar

- CSE’nin tek gerçek kullanıcısı yalnız şantiye şefidir.
- Ürün local-first ve mobile-first kişisel saha asistanıdır: araç bakımından geniş, kullanıcı modeli bakımından tek sahipli.
- Diğer kişi ve firmalar kullanıcı hesabı değil kişi/kurum veya ilgili taraf kayıt referansıdır.
- Multi-user, role/tenant, firma portalı, kurumsal workflow, şirket portföyü, SaaS/billing ve çok taraflı cloud collaboration kalıcı ürün kapsamından çıkarıldı.
- Single-owner security; uygulama kilidi/biometri, güvenilen cihaz, şifreli backup, owner-only telefon-PC sync, güvenli yerel ağ ve açık export/devir olarak ayrıldı.
- Kişisel/resmî ayrımın erişim rolü değil export/devir kapsamı olduğu korundu.
- `local-first != Windows-first` kararıyla mobil runtime, offline ve bildirim gerçek saha pilotlarının önüne alındı.
- Minimum hızlı hesap şeridi ile günlük zaman çizelgesi/düzenlenebilir taslak ilk mobil Kâğıdı Bırakma Sürümü’ne dahil edildi.
- Gelişmiş hesap defteri, immutable günlük yayın/revizyon zinciri ve Canlı Proje Haritası sonraki ayrı fazlarda bırakıldı.
- Legacy model envanteri/deprecation yönü gerçek sınıf adlarıyla yazıldı; production kod silinmedi.
- Öğrenme/podcast tarihçesi korundu, fakat current-state veya ürün otoritesi ve production engeli olmaktan çıkarıldı.

### Bağlayıcı ürün sırası

```text
0. Issue #103 tek kullanıcılı yön düzeltmesi
1. Transactional application service ve 7 günlük lazy backfill
2. Backup/restore compatibility ve resmî export izolasyonu
3. Mobil runtime ve veri sahipliği ADR
4. Mobil-first Kâğıdı Bırakma Sürümü
5. Offline ve bildirim güvenilirliği
6. 7 günlük gerçek saha pilotu
7. 30 günlük ana uygulama pilotu
8. Gelişmiş mühendislik hesap defteri
9. Günlük log yayınlama/revizyon zinciri
10. Canlı Proje Haritası
11. Kanıtlanmış kişisel yardımcı araçlar
12. Kişisel AI asistanı
```

### Kapsam koruması

Bu correction yalnız Issue #103 allowlist’indeki kanonik dokümantasyon, state, task, result ve öğrenme dosyalarını değiştirir. `app/`, `tests/`, templates, CSS, JavaScript, schema, migration, dependency, workflow ve gerçek kullanıcı data root’u kapsam dışı kalmıştır.

### Correction doğrulama kanıtı

```text
python -m pytest -rs
788 passed, 7 skipped in 16.66s
```

Yedi skip, önceki çalışmayla aynı Windows symlink oluşturma ayrıcalığı sınırıdır. Production test davranışı değiştirilmemiştir.

Diğer correction kontrolleri:

```text
python -m compileall -q app scripts: passed
python -m json.tool .cse/state/project_state.json: passed
git diff --check: passed
git diff -- app tests .github/workflows requirements.txt: empty
allowed working diff: 11 Issue #103 allowlist file
origin branch...HEAD before correction commit: 0 0
origin/master...HEAD before correction commit: 0 1
exports/: only .gitkeep
CSE_DATA_ROOT: unset
```

Korunan artifact kanıtı correction öncesi ve sonrasında aynıdır:

- `claude_CSE_Degerlendirme_Raporu.docx`: `3B2DB82D556D7D4591B049BCD95B03A7E2973EA43822CE2C60DC660B38899A13`
- `CSE_BAGIMSIZ_TEKNIK_URUN_DENETIM_RAPORU_2026-07-12.md`: `F8D3CBB2111EC7BBD12EEF673720EA3E54B2558E7545817D3E72DF18C083A1A9`
- `chief-site-engineer_adim_080_guvenli_nokta.zip`: `E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653`

Gerçek kullanıcı data root’una erişilmedi; migration, launcher, backup, restore veya export artifact üretimi yapılmadı.
