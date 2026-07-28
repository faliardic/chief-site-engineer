# Issue #264 — Liste gezinme bağlamını koruma

## Kaynak ve branch

- Resmî repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base: `master` / `5212ff97e80e8c6bc5daa95e97b37841f9f17edf`
- Branch: `codex/issue-264-list-navigation-state-retention`
- Draft PR #259 kodu merge, cherry-pick veya kopyalama yoluyla taşınmayacaktır.

## Çalışma modeli

- Model: mevcut tam Codex modeli
- Reasoning: Extra High
- Gerekçe: dört ayrı route üzerindeki async reload, scroll extent clamp,
  navigation guard ve fiziksel cihaz doğrulamasını tek dar sözleşmede tutmak.

## Validation class

`narrow-ui`

Issue gövdesindeki `ui` sınıfı, repository protokolündeki karşılığı olan
`narrow-ui` olarak uygulanacaktır. Schema, persistence, backup veya domain
mutation sözleşmesi değişmeyecektir.

## Değişen sözleşmeler

- Aynı canlı Ajanda, Hatırlatıcı, Beton ve Puantaj route instance'ında detay
  push/pop sonrasında mevcut scroll bölgesi korunur.
- Async reload güncel veriyi getirirken seçili gün, proje, kategori, ana/alt
  görünüm ve mevcut arama metni korunur.
- Liste küçülürse eski offset geçerli scroll extent içine güvenli biçimde
  clamp edilir.
- Hızlı çift dokunma aynı detay route'unu iki kez açmaz.
- Her liste instance'ı kendi route-local controller/state ömrüne sahiptir.
- Direct notification/deep-link geçmişi değiştirilmez.

## Kök neden fixture planı

Production editinden önce dört sentetik widget fixture'ı eklenecek ve mevcut
davranış kaydedilecektir:

1. uzun liste ve anlamlı scroll offset;
2. mevcut filtre/gün/sekme/arama seçimi;
3. sentetik detay push/pop;
4. detay dönüşündeki async reload;
5. resetlenen ve zaten korunan state'in ayrı kaydı.

Gerçek kullanıcı verisi okunmayacaktır.

## Exact changed-file allowlist

Yalnız aşağıdaki 15 tracked path değiştirilebilir:

1. `.cse/tasks/264_task.md`
2. `.cse/results/264_result.md`
3. `CHANGELOG.md`
4. `ROADMAP.md`
5. `docs/264_list_navigation_state_retention.md`
6. `docs/project_decisions.md`
7. `learning/264_list_navigation_state_retention.md`
8. `mobile/lib/features/agenda/agenda_page.dart`
9. `mobile/lib/features/reminders/reminders_page.dart`
10. `mobile/lib/features/concrete/concrete_page.dart`
11. `mobile/lib/features/attendance/attendance_page.dart`
12. `mobile/test/mobile_agenda_widget_test.dart`
13. `mobile/test/reminder_widget_test.dart`
14. `mobile/test/concrete_widget_test.dart`
15. `mobile/test/attendance_widget_test.dart`

Preflight ile var olmadığı doğrulanan `agenda_list_page.dart`,
`concrete_pour_list_page.dart`, `agenda_widget_test.dart` ve
`fake_concrete_application.dart` oluşturulmayacaktır. Mevcut support fake'ler
değiştirilmeden test dosyası içindeki sentetik fixture sınıfları kullanılacaktır.

## Doğrulama

### Çalıştırılacak

- Dört ekranın focused widget testleri.
- Davranış yalnız UI navigation state'i olduğundan application/domain testi
  ancak fixture bir application sözleşmesi değişikliği kanıtlarsa.
- `flutter test --no-pub`
- `flutter analyze --no-pub`
- `git diff --check`
- exact allowlist ve protected-path mutation kontrolü
- source/test PASS sonrasında checkpoint commit:
  `Implement list navigation state retention`
- exact checkpoint SHA için unique disposable detached worktree'de tek normal
  field APK build
- artifact provenance, applicationId ve signing uyumluluğu
- `adb install -r -g` ile veri koruyan replace-install
- yalnız `CSE264SMOKE` sentetik kayıtlarıyla dört liste fiziksel smoke
- PASS sonrasında completion evidence ve commit:
  `Complete list navigation state validation`

### Yeniden kullanılacak kanıt

- Base committe schema `10` ve backup format `1`.
- Değişmeyen persistence, notification, occurrence, backup ve release
  sözleşmelerinin merged kanıtları.

### Fiziksel cihaz minimum kapsamı

- Dört listede uzun sentetik liste, anlamlı scroll, mevcut bağlam seçimi,
  detail aç/kapat ve aynı görünür bölge.
- En az bir sentetik detail mutation sonrası güncel kart + eski bağlam.
- En az bir sentetik kaydın gruptan çıkışı sonrası güvenli offset clamp.
- Gerçek Ajanda, Hatırlatıcı, Beton veya Puantaj kaydı açma/değiştirme `0`.
- Uninstall, clear-data, downgrade ve hard-delete `0`.

## Bütçe ve stop kuralları

- Tek primary implementation run.
- Doğrulanmış source/test blocker için en fazla bir correction run.
- Fiziksel validation için tek build invocation; retry, clean, rotation ve
  process kill yok.
- Disposable build veya smoke başarısızsa push/PR yok; exact blocker ve
  disposable worktree path'i raporlanır.
- Source/test checkpoint sonrasında production/test source değiştirilmez.
- Bütün kapılar PASS olursa iki ordinary commit normal push edilir ve Issue
  #264'e bağlı tek Draft PR açılır; merge yapılmaz.

## Kapsam dışı ve korunan alanlar

- Cold restart/process-death pixel offset restoration
- Yeni filtre, sıralama, preference, schema veya migration
- Genel router rewrite veya global mutable state
- Draft PR #259 acceptance harness kodu
- `device-backups/`, `reports/`, Issue #255 stale generated alanları,
  Issue #262 disposable worktree ve diğer ignored/generated kullanıcı alanları

Korunan alanlar listelenmeyecek, okunmayacak, değiştirilmeyecek, taşınmayacak,
stage veya commit edilmeyecektir.
