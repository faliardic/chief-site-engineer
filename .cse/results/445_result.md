# Issue #445 Result — Typed Project Profile + Dependency Catalog Runtime

## Sonuç

Serbest profile Map sözleşmesi canonical enum, topology, applicability ve calendar doğrulamalarıyla typed/fail-closed hâle getirildi. Kanonik 362 satırlı dependency asseti byte-for-byte eklendi; loader merged 316 activity corpusunu referans otoritesi olarak kullanıyor ve dependency filtrelemesi shared Issue #443 tri-state applicability motoruyla deterministic çalışıyor.

## Kanonik kaynak ve içerik kanıtı

- Input ZIP SHA-256: `6d5cf112af3ce6e0bee377bac032e6a9de8204fb5a11efd71b2a4bcf3c3d77dd`;
- committed dependency asset SHA-256: `07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86`;
- decoded dependency JSON SHA-256: `145f52622b3badf72e9f43107157a67f154056077aeb35d8f531661999ab68a1`;
- physical contract: `316` active activity authority, `362` dependency template, `29` applicability field;
- dependency metadata: `0.3-yfk-resource-seed`, `RESEARCH_RESOURCE_SEED`, `NOT_FOR_PRODUCTION`, `DEPENDENCY_CATALOG_READ_ONLY_NO_SCHEDULE_INSTANTIATION`;
- bütün predecessor/successor endpoint'leri merged activity authority kümesinde çözülür; 316 authority ID'nin dependency endpoint union'ında yer almayan üç geçerli activity'si veri sapması değildir;
- input ZIP, manifest/schema yardımcı girdileri, YFK raw içerik, fiyat ve resource coefficient repository'ye eklenmedi.

## Uygulanan sözleşmeler

- `ConstructionProjectProfile.fromJson` top-level, block ve calendar alanlarında unknown/missing property, exact enum, ID, cardinality, range, uniqueness, basement consistency ve canonical date kontrollerini fail-closed uygular.
- `toApplicabilityMap()` exact ve deterministic 29 field üretir; identity/topology/calendar alanı sızdırmaz.
- Dependency enumları yalnız `FS/SS`, `WORKING_DAY`, 20 canonical scope rule, `C_SUPPORTED_INFERENCE` ve `REVIEW_REQUIRED` değerlerini kabul eder.
- Loader exact root/metadata/row shape, declared/physical count, duplicate ID, self-loop, activity endpoint, lag/floor range ve recursive condition field/op sözleşmelerini doğrular.
- `dependenciesForSelectedActivities` yalnız iki endpoint de seçili ve shared applicability condition kesin match ise kayıt döndürür; scope/floor instance çözümü ve schedule hesabı yapmaz.

## Çalıştırılan doğrulamalar

- Read-only ZIP/entry/asset/decoded JSON hash, count ve activity-reference probe'ları: exit `0`; ilk iki keşif probe'u root'ta ayrı activity-ID listesi ve endpoint union'ın 316 olması varsayımlarını ölçtü, targeted authority probe'u canonical sözleşmeyi `316 authority / 313 endpoint union / 0 unknown endpoint` olarak doğruladı.
- `Get-FileHash -Algorithm SHA256 mobile/assets/corpus/cse_construction_dependency_catalog_v0_3.b64`: exit `0`, exact asset hash PASS.
- `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat pub get --offline`: exit `0`; dependency ve lockfile değişmedi.
- `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\dart.bat format lib/domain/construction_corpus_models.dart lib/application/construction_dependency_repository.dart test/construction_corpus_repository_test.dart test/construction_dependency_repository_test.dart test/support/construction_profile_fixtures.dart`: exit `0`, yalnız `5` changed Dart dosyası formatlandı.
- İlk focused komut asset-list indentation hatası nedeniyle bundle öncesi exit `1`; yalnız `pubspec.yaml` asset girintisi düzeltildi.
- Focused corpus + profile/dependency komutu: `57 PASS / 1 FAIL`; tek kalan assertion değişmeyen Issue #443 activity assetinin Windows checkout'ta `LF -> CRLF` çevrilmiş byte hash'iydi. Indexteki exact blob byte-for-byte çalışma kopyasına alındı; source/index drift oluşmadı.
- Yalnız kalan hash testi ilk hedefli çağrıda generated `build/unit_test_assets` read-only kilidi nedeniyle test başlamadan exit `1`; doğrulanmış isolated generated klasör temizlendikten sonra aynı hedefli test exit `0`, `1/1 PASS`. Benzersiz focused toplam: `58/58 PASS`.
- `flutter.bat analyze --no-pub`: exit `0`, `No issues found`.
- `git diff --check`: exit `0`.
- exact allowlist/protected-path sınıflandırması: exit `0`, allowlist ihlali `0`, protected drift `0`.
- final source revision `flutter.bat test --no-pub`: exit `0`, `565/565 PASS`; yalnız bir full suite çalıştırıldı.

## Minimum yeterli doğrulama ve drift

- Validation class: `domain / read-only graph contract`.
- `AppDatabase.schemaVersion = 13` ve `CseBackupCodec.formatVersion = 1` değişmedi.
- `mobile/pubspec.lock`, dependency declarations, Android/iOS platform/config, SQLite/migration, backup, UI ve schedule engine drift'i `0`; `pubspec.yaml` farkı yalnız dependency asset kaydıdır.
- APK/AAB, signing, ARM64/16 KiB, fiziksel cihaz, backup/restore ve reboot/notification gate'leri çalıştırılmadı; değişen sözleşme read-only asset/domain/application sınırındadır.
- Exact base'teki merged schema/Backup/platform kanıtı yeniden kullanıldı; final full Flutter suite aynı revision'da regresyon vermedi.
- `75 dakika` hard stop aşılmadı. Kod correction bütçesi asset-list girinti düzeltmesinde kullanıldı; sonraki iki müdahale source correction değil, base asset CRLF ve generated test klasörü için dar environment normalization'dı.
- Kapsam dışı altyapı sorunu: Git `core.autocrlf` tracked one-line base corpus assetinin trailing LF byte'ını CRLF'ye çevirmişti; repository blobu veya commit içeriği değiştirilmeden test öncesi exact blob çalışma kopyasında kullanıldı.

## Teknik karar ve learning notu

Profil, storage stringlerini enumların `jsonValue` alanında canonical tutar; applicability değerlendirmesine yalnız `toApplicabilityMap()` üzerinden girer. Şunu böyle yaptık ki identity, topology veya calendar alanları corpus condition diline istemeden açılmasın ve 29-field sözleşmesi tek bir typed sınırdan beslensin. Dependency condition parser ayrı evaluator içermez: Issue #443'ün `matches / doesNotMatch / missingField` semantiğini ve recursive field validation'ını doğrudan reuse eder. Böylece nested `not/any/all` eksik bilgiyi positive match'e çeviremez.

## PR #446 Windows EOL correction kanıtı — 15 Ağustos 2026

- Root cause: canonical corpus `.b64` dosyalarının repository `.gitattributes` dosyasında no-EOL kuralı yoktu; global Windows `core.autocrlf=true` normal checkout sırasında tracked activity assetinin trailing LF byte'ını CRLF'ye dönüştürebiliyordu.
- Correction: başka attribute kuralı değiştirilmeden yalnız `mobile/assets/corpus/*.b64 -text` eklendi. `git check-attr` iki asset için `text: unset`, `git ls-files --eol` ise `attr/-text` gösterdi.
- Tamamen yeni detached Windows linked worktree normal `git worktree add --detach ... HEAD` checkout'u ile oluşturuldu; ilk status temizdi.
- Fresh checkout activity asset SHA-256: `a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca` — doğrudan fiziksel dosyadan PASS.
- Fresh checkout dependency asset SHA-256: `07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86` — doğrudan fiziksel dosyadan PASS.
- Fresh worktree'te `git show`, `git checkout-index`, index/blob copy, asset üzerine byte restore veya başka manuel normalization workaround'u kullanılmadı.
- Fresh worktree environment prep `flutter.bat pub get --offline`: exit `0`; `mobile/pubspec.lock` drift `0`.
- Fresh focused `flutter.bat test --no-pub test/construction_corpus_repository_test.dart test/construction_dependency_repository_test.dart`: exit `0`, `58/58 PASS`; asset dosyalarına müdahale edilmedi.
- Fresh `flutter.bat analyze --no-pub`: exit `0`, `No issues found`.
- Correction `git diff --check`: exit `0`; correction changed-file seti yalnız `.gitattributes`, toplam PR allowlist ihlali `0`, protected drift `0`.
- `AppDatabase.schemaVersion = 13`, `CseBackupCodec.formatVersion = 1`; dependency declarations, `mobile/pubspec.lock`, Android/iOS platform/config drift'i `0`.
- Final source correction revision `flutter.bat test --no-pub`: exit `0`, `565/565 PASS`; source correction üzerinde yalnız bir full suite çalıştırıldı.

## Publication durumu

- Draft PR #446 mevcut branch üzerindedir; correction evidence sonrası intentional amend, normal push ve Issue #445 completion güncellemesi yapılacaktır.
- PR Ready yapılmayacak, merge edilmeyecek ve sonraki Schedule/Instantiation Issue'ına geçilmeyecektir.
