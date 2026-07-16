# Issue 103 Task - Kanonik Proje Talimatları v2 ve Repository Truth

## Yetkili kaynaklar

- GitHub Issue: `#103`
- Bağlayıcı üst yol haritası: Epic `#105`
- Saha Takibi alt sözleşmesi: Epic `#97` ve `docs/field_tracking_v0_1_contract.md`
- Önceki tamamlanan görev: Issue `#102`, squash-merge PR `#104`
- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `9b25152ae38b72470e332929cb3a30ff955b75f1`
- Çalışma branch'i: `codex/issue-103-canonical-instructions-v2`

## Model ve reasoning seçimi

- Codex modeli: current selector'daki en güçlü full Codex modeli (bu çalışma: GPT-5)
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Kalıcı ürün politikası, değişken GitHub durumu, büyük tarihsel belgeler ve çoklu repository truth yüzeyleri birbirinden ayrılırken çelişkili veya kanıtsız güncel durum yazma riski yüksektir.

## Amaç

CSE'yi yalnız şantiye şefinin kullandığı local-first ve mobile-first **kişisel saha asistanı** olarak kanonik kaynaklarda tanımlamak; `Yakala -> İşle -> Takip et -> Doğrula -> Günlüğe al` döngüsünü, Epic #105 fazlarını ve ürünün gerçek Local Field MVP kabiliyetlerini README, ROADMAP, proje kararları ve `.cse` state ile aynı doğrulanmış repository gerçeğine bağlamak.

## Yetkili dosyalar

- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/103_task.md`
- `.cse/results/103_result.md`
- `learning/issue_103_kanonik_talimatlar_v2_ve_repository_truth.md`

## Yapılacak iş

1. Kalıcı ürün yönü ile değişken repository durumunu ayrı otorite yüzeyleri olarak tanımla.
2. Eski Step 224/225 current-state iddialarını kaldır veya açıkça tarihsel bağlama çek.
3. Local Field MVP'nin merge edilmiş SQLite, managed attachment, Flask web, export, backup/restore ve Windows launcher kabiliyetlerini kanıtlandığı ölçüde yaz.
4. Saha Takibi domain/recurrence ile schema v3 persistence aşamalarını tamamlandı; application service, backup compatibility, export isolation ve UI aşamalarını bekliyor göster.
5. Kayıtlı mühendislik hesap defteri, kontrollü günlük log ve Canlı Proje Haritası sınırlarını doğru sıraya yerleştir.
6. `.cse/state` içinde son merge edilmiş güvenli noktayı Issue #102 / PR #104 / `9b25152...` olarak kaydet; Issue #103'ü ayrı aktif dokümantasyon işi olarak göster.
7. Öğrenme notunda gerçek belge/JSON/PowerShell örnekleriyle kararları öğretici biçimde açıkla.

## Nihai düzeltme kapsamı — Epic #105

İlk branch commit’i `2dd38cff15bd428f0075724848d779f0e4970184` tarihsel kanıttır; amend/rebase veya force-push yapılmaz. Aynı branch üzerinde tek normal correction commit hedeflenir.

1. Uygulamanın tek gerçek kullanıcısını şantiye şefi olarak kanonikleştir; diğer kişi/firmaları kayıt referansı yap.
2. Multi-user, role/tenant, firma portalı, kurumsal workflow, SaaS/billing ve çok taraflı cloud collaboration hedeflerini aktif ve uzun vadeli kapsamdan çıkar.
3. Role-based hedef yerine uygulama kilidi, güvenilen cihaz, şifreli backup, owner-only sync, güvenli yerel ağ ve açık export/devirden oluşan single-owner security sınırını yaz.
4. Kişisel/resmî ayrımı erişim rolü değil export/devir kapsamı olarak açıkla; kişisel→resmî dönüşümü açık kullanıcı işlemi olarak koru.
5. Epic #105’in 0-12 faz sırasını README, ROADMAP, unified source, decisions ve state içinde aynılaştır.
6. Mobil runtime/veri sahipliği ADR, offline ve bildirimi gerçek saha pilotlarının önüne al; `local-first != Windows-first` kararını yaz.
7. Minimum hesap şeridi ile günlük zaman çizelgesi/düzenlenebilir taslağı ilk mobil Kâğıdı Bırakma Sürümü’ne dahil et.
8. Legacy model adaylarını gerçek sınıf adlarıyla envanter/deprecation yönüne bağla; production kodu silme veya değiştirme.
9. Öğrenme/podcast tarihçesini koru fakat product/current-state otoritesi veya production engeli yapma.

## Yasak kapsam

- Production Python, schema, migration, repository veya application service değişikliği yok.
- Test, fixture, template, CSS, JavaScript veya web route değişikliği yok.
- Dependency ve GitHub Actions değişikliği yok.
- Gerçek kullanıcı data root'una erişim veya migration yok.
- Backup/export/ZIP artifact üretimi yok.
- `reports/`, `exports/.gitkeep`, ignored ZIP/cache ve kullanıcı dosyaları değişmez.
- Reset, clean, stash, force-push, branch silme veya PR açma yok.

## Doğrulama

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status master...HEAD
git diff -- app tests .github/workflows requirements.txt
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
```

Ayrıca README, ROADMAP, iki kanonik kaynak ve state aynı güncel gerçeği taşımalı; üretim kodu/test/workflow/dependency diff'i boş olmalı; protected kullanıcı dosyaları korunmalıdır.

## Git ve teslim yetkisi

- Mümkünse tek güvenli commit oluşturulur.
- Branch normal push ile `origin` üzerine gönderilir.
- Factual completion evidence Issue #103'e eklenir.
- Codex PR açmaz, merge yapmaz ve branch silmez.
