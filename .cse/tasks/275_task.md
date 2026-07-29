# Issue #275 — Ajanda Arama Odağı ve Klavye İzolasyonu

## Yürütme kimliği

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Issue: `#275`
- Exact base/master: `52d610ce7e8ff28905b52f10b75626885070a0e9`
- Branch: `codex/issue-275-agenda-search-focus-isolation`
- Model: current full Codex modeli
- Reasoning: Extra High
- Gerekçe: Flutter focus lifecycle, route push/pop, test keyboard, scroll
  gesture ayrımı, Issue #264/#268 regresyonları ve ilk çift-cihaz artifact
  promotion zinciri birlikte korunacaktır.
- Validation class: `narrow-ui / P2 reliability`
- GitHub execution comment:
  `https://github.com/faliardic/chief-site-engineer/issues/275#issuecomment-5119843253`

## Başlangıç kanıtı

- Başlangıç branch: `master`
- HEAD: `52d610ce7e8ff28905b52f10b75626885070a0e9`
- `origin/master...master`: `0 0`
- Tracked diff: `0`
- Staged diff: `0`
- Önceden mevcut protected/stale untracked dizinler okunmadı, değiştirilmedi
  veya stage edilmedi.

## Değişen sözleşmeler

- Literal search text ve query route-local korunur.
- Search focus, caret ve sistem klavyesi detail dönüşünde restore edilmez.
- Detail push başlamadan önce yalnız route'a ait search focus bırakılır.
- Gerçek kullanıcı drag'i açık search focus'unu bırakır; text/query korunur ve
  reload üretmez.
- Search odaksızken drag/fling/momentum/yön değiştirme istemsiz focus üretmez.
- Programatik offset restore focus side effect üretmez.
- Issue #264 scroll/gün/proje/tür/aktif-arşiv/search state ve duplicate
  navigation guard sözleşmeleri korunur.
- Issue #268 route-local sort ve application query sırası korunur.

## Exact allowlist

Source/test checkpoint cumulative allowlist:

1. `.cse/tasks/275_task.md`
2. `mobile/lib/features/agenda/agenda_page.dart`
3. `mobile/test/mobile_agenda_widget_test.dart`

Production editinden önce yalnız task ve widget test dosyası değişebilir.

Tablet ve telefon PASS sonrasında completion cumulative allowlist:

4. `.cse/results/275_result.md`
5. `CHANGELOG.md`
6. `ROADMAP.md`
7. `docs/275_agenda_search_focus_keyboard_isolation.md`
8. `docs/project_decisions.md`
9. `learning/275_agenda_search_focus_keyboard_isolation.md`

## Baseline sözleşmesi

- Unique detached worktree:
  `%TEMP%\cse275-baseline-<unique-run-id>`
- Base: exact merged master.
- Ana worktree'den yalnız task + widget test relative path korunarak kopyalanır.
- SHA-256 eşliği: `2/2`.
- Disposable `mobile` içinde `flutter pub get`: `1`.
- Ardından yalnız
  `flutter test --no-pub test/mobile_agenda_widget_test.dart`.
- En az bir detail-return focus/keyboard expected failure zorunludur.
- Search text veya route-state kaybı unrelated failure'dır.
- Scroll saha davranışı harness'te deterministik üretilemiyorsa bu sonuç
  kaydedilir; test uydurulmaz.
- Baseline worktree değiştirilmez, reuse edilmez veya silinmez.

## Production çözüm sınırı

Yalnız `mobile/lib/features/agenda/agenda_page.dart`:

- route-local explicit `FocusNode`;
- `dispose`;
- detail push öncesi route search unfocus;
- `TextField.focusNode`;
- dar `onTapOutside`;
- `ListView.keyboardDismissBehavior =
  ScrollViewKeyboardDismissBehavior.onDrag`;
- yalnız test gerektirirse user-drag kanıtlı, notification'ı tüketmeyen
  `NotificationListener`.

Search controller, `_search`, debounce/query, application/domain/storage/router
ve başka ekranların focus yapısı değiştirilmez.

## Focused test matrisi

- Explicit search tap: focus true, test keyboard visible, text/controller/query.
- App bar back ve system back: text korunur, focus/keyboard false.
- Detail mutation + return: fresh content, text korunumu, focus/keyboard false.
- Duplicate tap guard ve tek detail route push.
- Odaksız hızlı drag/fling/yön değiştirme istemsiz focus üretmez.
- Search odaklı gerçek drag focus/keyboard kapatır, text/query korunur, reload
  üretmez.
- Search alanı üzerinden scroll gesture güvenli kalır.
- Programatik offset restore focus side effect üretmez.
- Scroll offset, gün, proje, tür, aktif/arşiv, sort ve literal search korunur.
- Sort/gün/filtre değişimi focus vermez.
- İki AgendaPage instance'ı FocusNode paylaşmaz; dispose exception üretmez.
- 320 px + 1.6 text scale + dark theme overflow/exception `0`.
- RefreshIndicator davranışı korunur.

## Source/test doğrulaması

- Unique detached worktree:
  `%TEMP%\cse275-source-validation-<unique-run-id>`
- Exact üç dosya SHA-256 eşliği: `3/3`.
- Unexpected tracked path: `0`.
- `git diff --check`: PASS.
- `flutter pub get`: `1`; pubspec/lock diff: `0`.
- Focused widget:
  `flutter test --no-pub test/mobile_agenda_widget_test.dart`.
- Agenda application:
  `flutter test --no-pub test/agenda_application_test.dart`.
- Combined Agenda kanıtı focused + application sonuçlarından kaydedilir.
- Full Flutter: `flutter test --no-pub`.
- Analyze: `flutter analyze --no-pub`.
- Schema `10`, backup formatı `1`, migration `0`.
- Application/domain/storage/router/notification diff `0`.

## Checkpoint ve build

- Exact üç source/test dosyası ordinary checkpoint:
  `Fix Agenda search focus isolation`.
- Checkpoint öncesi push yok.
- Unique detached checkpoint build worktree.
- `flutter pub get`: `1`; lockfile diff `0`.
- Tek build:
  `flutter build apk --debug --target lib\main.dart --no-pub`.
- Build invocation/retry: `1/0`.
- `flutter clean`, build-root rotation, process kill, ikinci build ve ana
  worktree artifact'ı yasaktır.
- Artifact path/time/length/last-write UTC/SHA-256/applicationId/activity/
  version/signer/checkpoint provenance kaydedilir.

## Çift cihaz kabulü

- Telefon:
  `PHONE_SERIAL=R5CY21WKZFX`, `PHONE_MODEL=SM-S938B`.
- Tablet physical gate'te `adb devices -l` ile bulunur; her sonraki ADB komutu
  exact `-s <SERIAL>` kullanır.
- Tablet serial/model/manufacturer/size/density/form-factor task ve result'a
  kaydedilir.
- Tablet yok/belirsiz/çoklu aday ise `TABLET_REGISTRATION_PENDING`; checkpoint
  ve tek artifact korunur, telefon/push/PR yapılmaz.
- Aynı exact APK önce tablette geniş smoke, sonra telefonda dar promotion smoke
  için kullanılır.
- Tablet PASS olmadan telefon kullanılmaz.
- Tablet PASS sonrası telefon bağlı değilse `PHONE_PROMOTION_PENDING`;
  completion commit/push/PR yapılmaz.
- Gerçek kullanıcı kaydı açma/değiştirme: `0`.
- Uninstall / clear-data / downgrade / hard-delete: `0 / 0 / 0 / 0`.
- Sentetik kayıtlar yalnız geri alınabilir arşiv/çöp akışıyla temizlenir.

## İzin verilen geniş kapılar ve yeniden kullanılan kanıt

- Tek full Flutter suite, full analyze, tek debug build ve Issue'a özel
  çift-cihaz kabulü açıkça yetkilidir.
- Schema `10`, backup formatı `1`, migration `0`, application/package/signing
  ve değişmeyen notification/background/reboot sözleşmeleri Issue #272 / PR
  #274 merged master kanıtından yeniden kullanılır; exact debug artifact
  compatibility ayrıca doğrulanır.
- Release AAB, ARM64/16 KiB, backup/restore ve Python full suite çalıştırılmaz.

## Bütçe

- Primary implementation run: `1`.
- Exact test-harness blocker correction: en fazla `1`.
- Build invocation/retry: `1/0`.
- Source/test hedefi: `35 dakika`.
- Source/test hard stop: `50 dakika`.
- Cihaz bağlantısı bekleme bütçeye dahil değildir.

## Kapsam dışı ve stop

- D29.3 ve diğer roadmap başlıkları; yeni Issue oluşturma.
- Application/domain/storage/router/notification/schema/migration/backup.
- Draft PR #259 ve PR #271/#273, Issue #272/#268 branch kodu/ancestry'si.
- Allowlist dışı source/test, unrelated failure, baseline detail-return failure
  yokluğu, full/analyze failure, ikinci build ihtiyacı, tablet belirsizliği,
  artifact/signing/version uyuşmazlığı, tablet smoke failure veya veri riski
  fail-closed stop nedenidir.

## Yayınlama

Tablet ve telefon PASS sonrasında exact dokuz dosya, ordinary completion commit
`Complete Agenda search focus validation`, normal push ve `Related to #275` ile
başlayan `Prevent unintended Agenda search focus` başlıklı tek Draft PR
yetkilidir.

Force-push, amend, rebase-push, Ready, merge, Issue close, branch delete ve
D29.3 Issue oluşturma yetkili değildir.

## Baseline gerçekleşmesi ve fail-closed stop

### İlk baseline

- Worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse275-baseline-20260729182226718-1fc0e6c4`
- Detached HEAD:
  `52d610ce7e8ff28905b52f10b75626885070a0e9`
- Task + widget test SHA-256 eşliği: `2/2`.
- `flutter pub get` invocation: `1`; PASS.
- Focused widget sonucu: mevcut 20 test PASS; yeni dört test davranış
  assertion'ına ulaşmadan lazy `ListView` içinde henüz oluşturulmamış/offstage
  widget'ı `single` beklediği için `Bad state: No element` verdi.
- Production hipotezi bu denemede ölçülmedi. Worktree değiştirilmedi, reuse
  edilmedi ve silinmedi.

### İzinli tek harness correction

- Düzeltme: detail test görünüm/target seçimi daraltıldı; scroll ölçümünde drag
  mesafesi azaltıldı ve programatik geri dönüş eklendi. Production source
  değişmedi.
- Worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse275-baseline-20260729182426501-f3d903c2`
- Detached HEAD:
  `52d610ce7e8ff28905b52f10b75626885070a0e9`
- Task + widget test SHA-256 eşliği: `2/2`.
- `flutter pub get` invocation: `1`; PASS.
- Focused widget sonucu: mevcut 20 test PASS.
- Exact expected product failure:
  `Agenda search system back preserves text without restoring focus` testinde
  text/query korunurken `hasFocus` için `Expected: false`, `Actual: true`.
- Kalan blocker: app-bar/iki scroll testi search child offstage olduğunda üç
  `Bad state: No element` harness error'ı üretmeye devam etti; baseline yalnız
  focus/keyboard failure'ı koşulunu temiz biçimde karşılamadı.
- Correction budget: `1/1` tüketildi. Aynı baseline operation için üçüncü
  worktree/test invocation başlatılmadı.
- Worktree değiştirilmedi, reuse edilmedi ve silinmedi.

### Stop durumu

- Son geçen kapı: system-back detail-return kök nedeninin expected focus
  failure ile doğrulanması.
- Stop nedeni: izinli tek test-harness correction sonrasında baseline'da üç
  harness error kalması.
- Current cumulative changed files: task + widget test; production diff `0`.
- Source-validation/checkpoint/build/tablet discovery/telefon/commit/push/Draft
  PR çalıştırılmadı.
- Gerekli kalan tek adım: yeni açık yetki verilirse offstage-safe focus
  ölçümünü kuran bir harness correction ve yeni unique baseline worktree.

## Yetkili ikinci ve son harness correction

- GitHub yetki yorumu:
  `https://github.com/faliardic/chief-site-engineer/issues/275#issuecomment-5120423878`
- Bu çalışma yalnız `.cse/tasks/275_task.md` ile
  `mobile/test/mobile_agenda_widget_test.dart` dosyalarını değiştirebilir;
  production diff `0` kalır.
- Exact search `EditableText` materialize değilse focus ölçümü `false` kabul
  edilir. Birden fazla exact eşleşme harness failure'dır; boş finder üzerinde
  `.single` kullanılmaz.
- Search text korunumu focus ölçümünden ayrıdır. Query, scroll offset ve test
  keyboard önce ölçülür; search alanı daha sonra tap olmadan programatik olarak
  viewport'a getirilir ve controller text ayrıca doğrulanır.
- Önceki iki baseline worktree değiştirilmez, reuse edilmez veya silinmez.
- Yeni unique detached baseline worktree exact merged master üzerinde kurulur.
- Correction budget bu çalışmayla `2/2` olur; üçüncü baseline correction
  yetkisi yoktur.
- Temiz baseline kabulü: mevcut 20 test PASS; en az system-back detail-return
  exact expected focus failure; `Bad state: No element`, compile/load,
  unrelated failure, text/query kaybı ve scroll-state regresyonu `0`.
- Temiz baseline geçerse Issue'nun dar `agenda_page.dart` implementation ve
  sonraki source-validation/build/çift-cihaz zinciri devam eder. Temiz baseline
  yine harness veya unrelated failure üretirse production editinden önce
  fail-closed durulur.

## İkinci ve son harness correction sonucu

- Worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse275-baseline-20260729192057226-95e7c629`
- Detached HEAD:
  `52d610ce7e8ff28905b52f10b75626885070a0e9`
- Task + widget test SHA-256 eşliği: `2/2`.
- Production diff: `0`.
- İlk başlatma denemesinde `flutter` PATH'te olmadığı için executable
  bulunamadı; `pub get` veya test prosesi başlamadı. Repository'de kayıtlı exact
  SDK yolu
  `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`
  doğrulandı ve yalnız başlamayan aşama aynı değiştirilmemiş worktree'de
  çalıştırıldı.
- Gerçek `flutter pub get` invocation: `1`; PASS.
- Focused widget invocation: `1`; expected non-zero.
- Mevcut 20 widget testi: PASS.
- `Bad state: No element`: `0`.
- Compile/load error: `0`.
- Exact expected product failure:
  `Agenda search system back preserves text without restoring focus` içinde
  text/query ve offset korunurken focus `Expected: false`, `Actual: true`.
- İkinci expected product failure:
  `Agenda user scroll dismisses search focus without text or query churn`
  içinde gerçek drag sonrasında focus `Expected: false`, `Actual: true`.
- Kalan harness blocker:
  `Agenda search app bar detail return preserves text without focus` testinin
  detail push öncesi precondition'ı, search `EditableText` scroll nedeniyle
  offstage/materialize değilken focus için `Expected: true`, `Actual: false`
  üretti. Offstage-safe helper doğru olarak `false` döndürdü; precondition
  current correction içinde buna hizalanmadığı için app-bar text/return
  assertion zincirine ulaşılmadı.
- Scroll failure'ında focus assertion query/controller text kontrollerinden önce
  durduğu için clean baseline'ın ayrı text/query/scroll-state kanıtı o testte
  tamamlanmadı.
- Correction budget: `2/2` tüketildi. Üçüncü harness edit veya baseline
  invocation yapılmadı.
- Final stop: clean baseline kabulü sağlanmadı; production/source-validation/
  checkpoint/build/ADB/tablet/telefon/commit/push/Draft PR çalıştırılmadı.
- Kalan tek adım, ancak yeni açık GitHub yetkisi verilirse app-bar offstage
  precondition'ını düzeltmek ve scroll ölçümlerini failure assertion'ından önce
  tamamlayan üçüncü unique baseline correction'dır.

## Açık istisna — üçüncü ve son harness correction

- GitHub yetki yorumu:
  `https://github.com/faliardic/chief-site-engineer/issues/275#issuecomment-5120620752`
- Önceki `2/2` correction sınırı yalnız bu açık istisna için `3/3` olarak
  genişletildi; dördüncü harness correction yetkisi yoktur.
- Production diff correction sırasında `0` kalır. Yalnız
  `.cse/tasks/275_task.md` ve
  `mobile/test/mobile_agenda_widget_test.dart` değişebilir.
- App-bar testinde search görünürken exact `EditableText` üzerinden
  `FocusNode` ve `TextEditingController` referansları yakalanır. Kart için
  scroll sonrasında offstage finder focus precondition'ı olarak kullanılmaz.
- App-bar dönüşünde captured controller text, fake query, scroll offset,
  keyboard ve captured FocusNode ayrı doğrulanır. Current source hatayı
  üretmiyorsa app-bar PASS kabul edilir.
- User-drag testinde query, controller text, call count ve scroll offset
  doğrulamaları expected focus assertion'ından önce tamamlanır.
- Önceki üç baseline worktree değiştirilmez, reuse edilmez veya silinmez.
- Exact merged master üzerinde yeni unique detached worktree kurulur; task ve
  widget test SHA eşliği `2/2`, unexpected tracked path `0`, gerçek
  `flutter pub get` invocation `1`, lockfile diff `0` ve tek focused widget
  invocation zorunludur.
- Temiz baseline matrisi: mevcut 20 test PASS; system-back ve user-drag exact
  expected focus failure; app-bar exact focus failure veya PASS; harness/
  precondition, `Bad state`, compile/load, unrelated, text/query kaybı ve
  scroll-state regresyonu `0`.
- Matris geçerse yalnız `agenda_page.dart` production implementation ve mevcut
  source-validation/build/çift-cihaz zinciri devam eder. Matris yine harness
  veya unrelated failure üretirse production editinden önce fail-closed
  durulur ve yeni correction istenmez.

## Baseline harness correction 3/3 sonucu

- Worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse275-baseline-20260729192923231-98fd10a3`
- Detached HEAD:
  `52d610ce7e8ff28905b52f10b75626885070a0e9`
- Task + widget test SHA-256 eşliği: `2/2`.
- Unexpected tracked path: `0`.
- Production diff: `0`.
- `git diff --check`: PASS.
- Gerçek `flutter pub get` invocation: `1`; PASS.
- `mobile/pubspec.lock` diff: `0`.
- Focused widget invocation: `1`; expected non-zero.
- Mevcut 20 widget testi: PASS.
- App-bar detail return:
  captured controller text, fake query, restored offset ve keyboard
  beklentileri geçti; captured FocusNode için exact product failure
  `Expected: false`, `Actual: true`.
- System-back detail return:
  text/query, restored offset ve keyboard beklentileri geçti; exact product
  failure `Expected: false`, `Actual: true`.
- User drag:
  query, controller text, application call count ve non-zero scroll offset
  beklentileri geçti; exact product failure
  `Expected: false`, `Actual: true`.
- Odaksız drag/fling/yön değiştirme testi: PASS.
- `Bad state: No element`, harness/precondition, compile/load, unrelated,
  text/query kaybı ve scroll-state regresyonu: `0`.
- Correction budget: `3/3`; dördüncü correction veya baseline invocation
  yapılmayacaktır.
- Clean baseline matrisi: PASS.
- Production editine izin: **EVET**. Bundan sonraki dar source değişikliği
  yalnız `mobile/lib/features/agenda/agenda_page.dart` içinde yürütülecektir.

## Production implementation ve source-validation sonucu

- Production implementation yalnız
  `mobile/lib/features/agenda/agenda_page.dart` içindedir:
  route-local explicit `FocusNode`, lifecycle `dispose`, detail push öncesi
  `unfocus`, `TextField.focusNode`, dar `onTapOutside` ve
  `ScrollViewKeyboardDismissBehavior.onDrag`.
- Search controller, `_search`, query/reload, application, domain, storage,
  router, platform, notification, Android ve iOS sözleşmeleri değiştirilmedi.
- Source-validation worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse275-source-validation-20260729193123549-c823163d`
- Detached HEAD:
  `52d610ce7e8ff28905b52f10b75626885070a0e9`
- Task + production + widget test SHA-256 eşliği: `3/3`.
- Unexpected tracked path: `0`.
- `git diff --check`: PASS.
- Gerçek `flutter pub get` invocation: `1`; PASS.
- `mobile/pubspec.lock` diff: `0`.
- Focused `mobile_agenda_widget_test.dart`: `24/24` PASS.
- Focused `agenda_application_test.dart`: `22/22` PASS.
- Full Flutter suite: `324/324` PASS; aynı source revision üzerinde invocation
  `1`.
- `flutter analyze --no-pub`: PASS, issue `0`.
- Protected application/domain/storage/router/platform/notification ve native
  path mutation: `0`.
- Reused evidence:
  schema `10`, backup formatı `1`, migration `0`, application/package/signing
  ve değişmeyen notification/background/reboot sözleşmeleri Issue #272 / PR
  #274 merged master
  `52d610ce7e8ff28905b52f10b75626885070a0e9` kanıtından yeniden kullanılır;
  bu task bu sözleşmelere dokunmamıştır.
- Release AAB, ARM64/16 KiB, backup/restore ve Python suite bilinçli olarak
  çalıştırılmadı; `narrow-ui` değişen sözleşmesi bunları etkilememektedir.
