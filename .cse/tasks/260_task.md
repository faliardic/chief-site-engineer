# Issue #260 — Beton checklist source-of-truth ve döküm başlatma hotfix

## Güvenli başlangıç

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Başlangıç dalı: `master`
- Beklenen ve doğrulanan base SHA: `7a90a201a31dec06d94df763bac18760a4c0d69c`
- Çalışma dalı: `codex/issue-260-concrete-checklist-start-hotfix`
- Validation class: `domain`
- Codex modeli: bu çalışmadaki mevcut tam Codex modeli
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Checklist read-model, transaction, optimistic revision, event idempotency, alan-türetilmiş durum ve fiziksel veri koruma sözleşmelerini birlikte etkileyen P1 hotfix.
- Paralel alt ajan: yok.

## Değişen sözleşmeler

- Beton detay başlığındaki açık zorunlu kalem sayısı, checklist satırlarının current durumundan deterministik hesaplanır; ayrı mutable sayaç tutulmaz.
- UI başlığı ve `Dökümü başlat` validation’ı aynı required-pending helper/read-model kuralını kullanır ve aynı blocker kümesini gösterir.
- `inspection_notified` ve `laboratory_appointment` manuel bulk completion dışında kalır; yalnız ilgili Beton alanları gerçekten dolduğunda tamamlanır ve alan yeniden boşaltıldığında tekrar açılır.
- Bulk completion tek transaction olarak kalır; stale revision veya event insert hatası tüm işlemi rollback eder, aynı event ID retry duplicate event üretmez ve mutation fresh `ConcretePourDetail` döndürür.
- Kullanıcı dili manuel kapsamı açıkça belirtir; sistem-owned blocker’lar exact alan güncelleme eylemlerine yönlendirir.
- Alan güncellemesi sonrası aynı mutation/reload zincirinde `0 açık` görünür; ayrıca refresh gerekmeden `Dökümü başlat`, ardından mevcut kapanış validation’ları korunarak `Dökümü bitir` çalışır.
- Schema `10`, backup formatı `1` ve mevcut migration seti değişmez.

## Sentetik kök neden kanıtı

Gerçek kullanıcı Beton kayıtları okunmaz.

- Durum A: Manuel required kalemler tamam, laboratuvar randevusu ve yapı denetim bildirimi eksik. Exact iki blocker görünür ve döküm başlamaz.
- Durum B: Manuel required kalemler ile iki kaynak alan gerçekten tamam. Açık required sayı `0` olur ve döküm başlayabilir.

## Exact changed-file allowlist

Yalnız aşağıdaki dosyalar değiştirilebilir:

1. `.cse/tasks/260_task.md`
2. `.cse/results/260_result.md`
3. `CHANGELOG.md`
4. `ROADMAP.md`
5. `docs/260_concrete_checklist_source_of_truth_hotfix.md`
6. `docs/project_decisions.md`
7. `learning/260_concrete_checklist_source_of_truth_hotfix.md`
8. `mobile/lib/application/concrete_application.dart`
9. `mobile/lib/domain/concrete_models.dart`
10. `mobile/lib/features/concrete/concrete_pour_detail_page.dart`
11. `mobile/test/concrete_application_test.dart`
12. `mobile/test/concrete_widget_test.dart`

Issue üst sınırındaki `mobile/test/support/fake_concrete_application.dart`, mevcut widget fake’i aynı test dosyasında bulunduğundan başlangıç allowlist’ine alınmadı. Allowlist dışında gerçek bir ihtiyaç çıkarsa edit durur; kapsam kendiliğinden genişletilmez.

## Zorunlu uygulama

- Manual/system-owned ayrımını domain helper’ında tek yerde tanımla.
- Required pending kümesini current checklist item durumlarından deterministik üret.
- Liste metriği, detay metriği, başlık ve transition validation’ını aynı kuralla hizala.
- Alan set/clear işlemlerini ilgili system-owned checklist ve mevcut follow-up/reminder akışıyla aynı transaction içinde senkronla.
- Exact blocker eylemleri olarak `Laboratuvar randevusunu güncelle` ve `Yapı denetime bildirimi güncelle` göster; mevcut ortak alan güncelleme akışını yeniden kullan.
- Manuel bulk action ve onay metninde kapsamı açıkça belirt.
- Mutation sonrasında fresh detail ve double-tap guard davranışını koru.
- Güvenlik, laboratuvar, yapı denetim ve döküm bitirme validation’larını azaltma.

## İzin verilen doğrulama

- Odaklı sentetik Beton domain/application testleri: manual/system ayrımı, count, field set/clear, transition, stale/event rollback, retry idempotency ve restart persistence.
- Odaklı Beton widget testleri: doğru açık sayı ve dil, exact blocker eylemleri, otomatik `0 açık`, refresh gerektirmeyen start/finish, 320 px, büyük metin, dark theme, double-tap guard ve optimistic partial-state yokluğu.
- `flutter test --no-pub`.
- `flutter analyze --no-pub`.
- `git diff --check`.
- Exact allowlist ve protected-path kontrolleri.
- Bütün kaynak kapıları PASS olursa imza uyumlu, veri koruyan normal field APK build’i ve yalnız sentetik Beton paketiyle dar fiziksel cihaz smoke.

Flutter yalnız:

`C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`

## Fiziksel cihaz minimum kapsamı

- Normal field APK; uninstall, clear-data veya downgrade yok.
- Sentetik Beton paketi oluşturma.
- Manuel maddeleri tamamlama.
- Laboratuvar/yapı denetim blocker görünürlüğü.
- İki kaynak alanı gerçekten tamamlama.
- `0 açık`, `Dökümü başlat`, `Dökümü bitir`.
- Normal kapat/aç sonrası sentetik kaydın kalıcılığı.
- Gerçek kullanıcı kaydını okuma, değiştirme veya içeriğini raporlama yok.
- Issue #259 acceptance harness koduna bağımlılık yok.

## Yeniden kullanılacak kanıt ve kapsam dışı

- Issue #259 BLOCKED acceptance harness kodu merge, cherry-pick, copy veya hotfix branch’ine taşıma yoluyla kullanılmaz.
- Schema/migration ve backup formatı değişmez; ihtiyaç ortaya çıkarsa production editinden önce durulur ve açık yetki istenir.
- Beton dışı production Flutter, Android, persistence schema, backup ve reminder kaynakları kapsam dışıdır.
- `device-backups/`, `reports/`, Issue #255 stale generated dizinleri ve diğer kullanıcı ignored/untracked alanları listelenmez, okunmaz, değiştirilmez, silinmez, taşınmaz, stage veya commit edilmez.

## Bütçe ve stop koşulları

- Tek primary implementation run.
- Yalnız doğrulanmış blocker için en fazla bir correction run; aynı başarısız adım exact düzeltmeden sonra yalnız bir kez tekrarlanır.
- Yeni schema/migration, allowlist dışı production dosyası, gerçek kullanıcı verisi, downgrade/uninstall/clear-data veya ikinci correction ihtiyacı çıkarsa dur ve raporla.
- Bütün kapılar PASS olmadan commit, push veya PR yok.

## GitHub yetkileri

- Commit mesajı: `Fix concrete checklist start flow`
- Ordinary commit ve normal push: yalnız bütün kapılar PASS ise izinli.
- Draft PR: yalnız bütün kapılar PASS ise izinli.
- Ready/merge, force push, branch silme, reset, clean, stash ve kullanıcı dosyalarını etkileyen checkout: izinli değil.
