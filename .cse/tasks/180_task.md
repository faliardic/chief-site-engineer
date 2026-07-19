# Issue 180 Görev Kaydı

## Yürütme kimliği

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen base commit: `fef480dc32ec5dabf4dca9394c46c519b7097886`
- Branch: `codex/issue-180-release-01-mobile-foundation`
- Codex modeli: standart full model
- Reasoning: Extra High
- Seçim nedeni: Flutter/Android/iOS proje temeli, cihaz-içi SQLite migration sınırı, zaman ve dosya sözleşmeleri, platform permission davranışları ve iki test ekosisteminin regresyon riski birlikte ele alınıyor.

## Bağlayıcı kaynaklar

- GitHub Issue #180 gövdesi ve bütün yorumları
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- Repository kökündeki `AGENTS.md`

## Yetkili dosyalar

- `mobile/**`
- `.gitignore`
- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/180_release_01_mobile_foundation.md`
- `docs/project_decisions.md`
- `learning/180_release_01_mobile_foundation.md`
- `learning/GLOSSARY.md`
- `.cse/tasks/180_task.md`
- `.cse/results/180_result.md`
- `.cse/state/project_state.json`

## Yapılacak iş

1. `mobile/` altında tek Dart codebase kullanan Flutter uygulama iskeleti ile Android ve iOS platform projelerini kur.
2. Başlangıç ekranını ve Hatırlatıcı, Ajanda, Puantaj, Beton Paketi navigasyon girişlerini ekle; tamamlanmayan alanları açık `hazırlanıyor` durumunda tut.
3. Cihaz-içi SQLite konumu, schema version tablosu, atomic migration ve restart kalıcılığı için fail-closed bootstrap oluştur.
4. Canonical aware UTC seconds storage ve `Europe/Istanbul` sunum sözleşmesini uygula; naive/invalid zamanı reddet.
5. Database, attachment, export/backup ve temp/staging dizinlerini platform path sağlayıcısı arkasında doğrula.
6. Notification, camera/photo/file ve backup/export sınırları için permission-denied durumunda crash üretmeyen güvenli abstraction kur.
7. Debug/release veri ayrımını; uygulama adı, package/bundle identifier, version/build ve environment kimliğini sabitle.
8. Dart unit/widget/integration smoke testleri, Android build doğrulaması ve iOS project/config doğrulaması ekle.
9. Python regresyonlarını, compileall, state JSON ve Git kalite kapılarını çalıştır.
10. Teknik belge, ayrıntılı öğrenme notu, karar kaydı, changelog/roadmap ve olgusal sonuç/state kayıtlarını güncelle.

## Yasak kapsam

- Cloud backend, cloud sync, çoklu cihaz eşitleme veya auth server
- Ajanda, Hatırlatıcı, Puantaj veya Beton Paketi tam özellik implementasyonu
- Gerçek App Store veya Play Store submission
- Gerçek kullanıcı verisi veya gerçek `CSE_DATA_ROOT` erişimi
- Masaüstü verisini sessiz/otomatik mobil migration
- Signing key, keystore, provisioning profile veya secret ekleme
- `reports/` içeriğini okuma ya da değiştirme
- Ignored ZIP/cache dosyalarını veya `exports/.gitkeep` dosyasını değiştirme

## Yerel doğrulamalar

- Flutter analyze ve test
- Android debug ve release build
- iOS project/config doğrulaması; macOS/Xcode/signing gereksinimini açık blocker olarak kayıt
- Restart/offline SQLite smoke kalıcılığı
- UTC/Europe-Istanbul contract fixture eşliği
- Permission-denied güvenli fallback testleri
- Debug/release veri ayrımı
- `python -m pytest -rs`
- `python -m compileall -q app scripts`
- `python -m json.tool .cse/state/project_state.json`
- `git diff --check`
- Exact changed-file allowlist, protected-path, export ve ignored ZIP kontrolü

## Git ve yayınlama izinleri

- Tek ordinary commit: `Add Flutter mobile foundation`
- Normal push: izinli ve zorunlu
- Amend, rebase, force-push: yasak
- PR açma veya merge: yasak
- Completion evidence yorumunu Issue #180'a ekleme: izinli ve zorunlu
- Post-merge sync: bu görevde merge yapılmadığı için uygulanmaz
