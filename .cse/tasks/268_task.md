# Issue #268 — Ajanda deterministik sıralama seçimi

## Kaynak ve branch

- Resmî repo:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen base: `master` /
  `1179870a7c69d1e3f090e5fc61da9c7bbfc42879`
- Başlangıç master divergence: `0 0`
- Branch: `codex/issue-268-agenda-sort-order`
- Draft PR #259 merge/cherry-pick edilmeyecek, kaynak veya test kodu bu
  branch'e taşınmayacaktır.

## Çalışma modeli

- Model: current full Codex modeli
- Reasoning: High
- Gerekçe: değişiklik dar bir Ajanda query/UI sözleşmesidir; deterministik SQL
  sırası, route-local state, disposable-worktree testleri ve tek fiziksel
  cihaz kabulü birlikte ve fail-closed yürütülecektir.

## Validation class

`narrow-ui`

Sort seçimi presentation ve typed read-model/query davranışını değiştirir.
Schema, migration, backup, notification veya kalıcı preference sözleşmesi
değişmeyecektir.

## Değişen sözleşmeler

- `AgendaSortOrder.newestFirst` ve `AgendaSortOrder.oldestFirst` iki değerli
  typed contract olur.
- Kullanıcı etiketleri sırasıyla `En yeni üstte` ve `En eski üstte` olur.
- `AgendaQuery.sortOrder` varsayılan olarak
  `AgendaSortOrder.newestFirst` taşır.
- `newestFirst` SQL sırası:
  `observed_at DESC, created_at DESC, id DESC`.
- `oldestFirst` SQL sırası:
  `observed_at ASC, created_at ASC, id ASC`.
- `updated_at` sıralamaya girmez; UI client-side `reverse()` kullanmaz.
- `AgendaPage` route-local `_sortOrder` state'i taşır ve
  `agenda-sort-order` semantic key'li kontrolü gösterir.
- Sort değişimi mevcut gün/aktif-arşiv/proje/kategori/literal arama
  filtrelerini korur, listeyi yeniden yükler ve scroll'u güvenle başa alır.
- Issue #264 detail dönüşü, async reload, offset clamp ve duplicate navigation
  koruması seçili sort içinde korunur.
- Fake application production ile aynı üç alanlı deterministik sıralamayı
  uygular.

## Production öncesi kök neden kapısı

İlk snapshot yalnız şu üç tracked path'ten oluşacaktır:

1. `.cse/tasks/268_task.md`
2. `mobile/test/agenda_application_test.dart`
3. `mobile/test/mobile_agenda_widget_test.dart`

Baseline beklentileri yeni enum'a doğrudan bağımlı olmadan mevcut source ile
compile olacaktır:

1. Default `AgendaQuery` aynı gün içindeki en yeni kaydı önce döndürür.
2. `AgendaPage`, `agenda-sort-order` kontrolünü ve exact
   `En yeni üstte` başlangıç etiketini gösterir.

Baseline, exact base SHA'dan oluşturulan unique detached
`%TEMP%\cse268-baseline-<unique-run-id>` worktree'sinde çalıştırılacaktır. Ana
worktree'den yalnız exact üç dosya relative path korunarak kopyalanacak; kaynak
ve hedef SHA-256 değerleri byte-identical olacaktır. Disposable `mobile`
dizininde bir kez `flutter pub get`, ardından yalnız iki focused test dosyası
çalıştırılacaktır.

Beklenen kök neden sonucu:

- default newest-first expectation: davranış nedeniyle FAIL;
- sort control/initial label expectation: davranış nedeniyle FAIL;
- unrelated failure: `0`.

Exact baseline sonucu, production editinden önce bu bölüme eklenecektir.
Baseline worktree değiştirilmeyecek, reuse edilmeyecek veya silinmeyecektir.

### Baseline sonucu

- Worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse268-baseline-453c4ef45d1d4b748825424ac02eaadb`
- Base SHA: `1179870a7c69d1e3f090e5fc61da9c7bbfc42879`
- Kaynak/hedef SHA-256 eşitliği: `3/3 PASS`
- Exact changed path: `3/3`; beklenmeyen path: `0`
- `git diff --check`: `PASS`
- `flutter pub get`: `PASS`
- Focused sonuç: `34 PASS / 2 expected FAIL`
- Default query failure:
  beklenen `[log2, log1]` iken mevcut SQL
  `observed_at ASC, created_at ASC, id ASC` nedeniyle actual
  `[log1, log2]` döndü.
- Widget failure:
  `agenda-sort-order` key'i için expected `findsOneWidget`, actual
  `0 widgets`; ilk expectation burada durduğu için başlangıç etiketi de mevcut
  UI'da üretilemedi.
- Unrelated test failure: `0`

Bu iki failure production sözleşmesinin exact kök nedenidir. Baseline kapısı
beklenen biçimde geçildi ve production editine izin verir.

### Ek correction yetkisi

- Issue #268 yorumuyla kalan tek focused widget blocker'ı için ek correction
  run açıkça yetkilendirildi.
- Blocker production davranışı değil; Issue #264 state-retention fixture'ında
  hedef kartın lazy `ListView` içinde henüz oluşturulmadan dereference
  edilmesiydi.
- Production source, domain/application/UI davranışı, application testi ve
  fake application değiştirilmedi.
- Çözüm yalnız `agenda-day-list` altındaki exact `Scrollable` üzerinde en
  fazla 12 bounded semantic drag ile hedef key oluşana kadar ilerler; hedef
  oluştuktan sonra `ensureVisible` ve semantic tap kullanır.

## Source/test implementation allowlist

Source/test kapısına kadar cumulative snapshot yalnız şu exact yedi path'ten
oluşabilir:

1. `.cse/tasks/268_task.md`
2. `mobile/lib/domain/agenda_models.dart`
3. `mobile/lib/application/agenda_application.dart`
4. `mobile/lib/features/agenda/agenda_page.dart`
5. `mobile/test/agenda_application_test.dart`
6. `mobile/test/mobile_agenda_widget_test.dart`
7. `mobile/test/support/fake_agenda_application.dart`

## Final cumulative changed-file allowlist

Fiziksel smoke PASS sonrasında cumulative diff yalnız şu 13 tracked path'i
içerebilir:

1. `.cse/tasks/268_task.md`
2. `.cse/results/268_result.md`
3. `CHANGELOG.md`
4. `ROADMAP.md`
5. `docs/268_agenda_sort_order.md`
6. `docs/project_decisions.md`
7. `learning/268_agenda_sort_order.md`
8. `mobile/lib/domain/agenda_models.dart`
9. `mobile/lib/application/agenda_application.dart`
10. `mobile/lib/features/agenda/agenda_page.dart`
11. `mobile/test/agenda_application_test.dart`
12. `mobile/test/mobile_agenda_widget_test.dart`
13. `mobile/test/support/fake_agenda_application.dart`

## Source/test doğrulaması

- Exact yedi dosyanın SHA-256 manifesti ana worktree'de alınır.
- Exact base SHA'dan yeni unique detached
  `%TEMP%\cse268-source-validation-<unique-run-id>` worktree oluşturulur.
- Baseline veya önceki herhangi bir disposable worktree reuse edilmez.
- Yalnız exact yedi dosya relative path korunarak kopyalanır.
- Kaynak/hedef hash eşitliği, exact `7/7`, beklenmeyen path `0` ve
  `git diff --check` doğrulanır.
- Disposable `mobile` içinde bir kez `flutter pub get` çalıştırılır;
  `pubspec.yaml` ve `pubspec.lock` tracked diff'i `0` olmalıdır.
- Focused:
  `flutter test --no-pub test/agenda_application_test.dart
  test/mobile_agenda_widget_test.dart`
- Full Flutter: `flutter test --no-pub`
- Analyze: `flutter analyze --no-pub`
- Schema `10`, backup formatı `1`, migration `0`, protected-path mutation `0`.

Ana worktree içinde `flutter pub get`, test, analyze, build veya clean
çalıştırılmayacaktır.

## Checkpoint ve build

Source/test kapıları PASS olursa doğrulanmış exact yedi dosya stage edilir ve
ordinary `Add Agenda sort order` checkpoint commit'i oluşturulur; henüz push
yapılmaz.

Checkpoint SHA'dan yeni unique detached
`%TEMP%\cse268-build-validation-<unique-run-id>` worktree oluşturulur.
Detached HEAD exact checkpoint, tracked status temiz ve PR #259 ancestry dışı
olmalıdır. Disposable `mobile` içinde `flutter pub get` sonrasında tracked
değişiklik `0` olmalıdır.

Tek build invocation:

```text
flutter build apk --debug --target lib\main.dart --no-pub
```

Retry, clean, build-root rotation, process kill, ikinci build ve ana worktree
APK kullanımı yoktur. Artifact exact path/length/last-write UTC/SHA-256,
current invocation provenance, applicationId
`com.faliardic.chiefsiteengineer.debug`, launchable MainActivity, installed
field signing SHA-256 uyumu ve version-code compatibility ile doğrulanır.

## Minimum fiziksel cihaz kabulü

- ADB preflight serial: `R5CY21WKZFX`, exact state: `device`.
- Yalnız `adb install -r -g <exact-disposable-apk>` kullanılır.
- Aynı sentetik proje/yerel gün içinde en az dört benzersiz `CSE268SMOKE`
  Ajanda logu oluşturulur; olay zamanları erken/orta/daha geç/en geç ve gelecek
  olmayan değerlerdir.
- Yeni route defaultunda en geç kayıt üstte ve `En yeni üstte` etiketi görünür.
- `En eski üstte` seçilince erken kayıt üstte görünür.
- Proje/kategori/literal arama filtrelerinde seçili sort korunur.
- Bir sentetik detay mutation'ı sonrasında fresh açıklama görünür, sort
  korunur ve kayıt `observed_at` konumunda kalır.
- App bar back ve system back güvenlidir.
- Yalnız bu run'ın sentetik Ajanda logları güvenli archive akışıyla
  arşivlenir; sentetik proje archive UI yoksa izole kap olarak bırakılır.
- Gerçek kullanıcı kaydı açma/değiştirme `0`.
- Uninstall/clear-data/downgrade/hard-delete: `0 / 0 / 0 / 0`.

## Yeniden kullanılacak kanıt

- Base committe schema `10` ve backup formatı `1` merged kanıttır.
- Değişmeyen notification, background/reboot, backup/restore, AAB ve release
  sözleşmeleri yeniden test edilmeyecektir.
- Tek normal field artifact için yalnız Issue'nun istediği provenance,
  applicationId/signing/version uyumu doğrulanacaktır.

## Retry ve süre bütçesi

- Tek primary implementation run.
- Yalnız doğrulanmış source/test blocker için en fazla bir correction run.
- Correction ana branch'te exact allowlist içinde yapılır; eski validation
  worktree'si değiştirilmez/reuse edilmez ve bütün focused/full/analyze kapıları
  yeni unique worktree'de yeniden çalıştırılır.
- Build tek invocation'dır; retry yoktur.
- `narrow-ui` hedefi 30 dakika, hard stop 45 dakikadır.

## Stop koşulları

- Baseline'da beklenen exact iki davranış failure'ı dışında failure görülmesi.
- Schema, migration, preference veya release scripti ihtiyacı.
- Allowlist dışı source/test dosyası gereksinimi.
- Source/test, build veya fiziksel smoke kapısının başarısızlığı.
- Cihazın `device` olmaması veya signing/version uyumsuzluğu.
- Gerçek kullanıcı verisine yeni risk.

Bu durumlarda kapsam genişletilmez; bütçe dışında retry, push veya Draft PR
yapılmaz. Exact blocker, worktree path'i ve geçilen son kapı raporlanır.

## Kapsam dışı

- Sort tercihini database'e veya preference tablosuna yazmak
- Cold restart/process-death restoration
- Genel liste sort framework'ü
- Günler arası birleşik feed veya AI/relevance sort
- `updated_at` sıralaması
- Ajanda–Hatırlatıcı metin senkronu ve günlük log export
- Draft PR #259 kodu
- Gerçek kullanıcı verisini fixture yapmak
- Protected/ignored/generated kullanıcı alanları

## GitHub yetkisi

Bütün kapılar PASS olursa completion evidence için exact altı belge eklenir,
ordinary `Complete Agenda sort validation` commit'i oluşturulur, iki commit
normal push edilir ve `Related to #268` ile başlayan `Add deterministic Agenda
sorting` başlıklı tek Draft PR açılır. Force push, amend, Ready, merge, issue
close, branch delete ve yeni production Issue yoktur.

## Son test-harness correction yetkisi

- Issue #268 için final correction run yetkisi verildi.
- Kalan widget failure'ının nedeni lazy-list komşu kart geometrisinin fixture
  içinde materialize edilmeden okunmasıdır.
- Lazy komşulara uygulanan `getTopLeft` geometri assertion'ları kaldırıldı.
- Route-local scroll offset yakınlığı ve hedef kaydın semantic key kanıtı
  korunmuştur.
- Production source değişikliği yapılmamıştır.

## İstisnai cross-platform test normalization yetkisi

- Full suite blocker'ının disposable Windows worktree'deki CRLF ile testin
  LF-only beklentisi arasındaki false-negative olduğu doğrulandı.
- Failure, Ajanda production sıralama davranışıyla ilgili değildir.
- Static configuration testi satır sonlarını platform bağımsız biçimde
  normalize edecek şekilde güncellendi.
- Localization dependency adı, exact indent ve `sdk: flutter` sözleşmesi
  korunmuştur.
- Production source değişikliği yapılmamıştır.
