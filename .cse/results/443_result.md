# Issue #443 Result — Construction Activity Corpus Runtime Foundation

## Sonuç

Kanonik runtime asseti byte-for-byte yerleştirildi. Read-only corpus loader; exact metadata/count, exact WBS/package çifti ve recursive applicability sözleşmelerinde fail-closed çalışıyor. Focused ve full Flutter testleri ile analyze temiz geçti.

## Kanonik kaynak ve içerik kanıtı

- source v0.3 ZIP SHA-256: `de2bf1a542a331ea79fadddb81e315120e46c2e3b8204ea239e30fb4aaa616cd`;
- committed runtime asset SHA-256: `a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca`;
- decoded runtime JSON SHA-256: `5636d6286b09c09182cd7b96af2276fba2eedf8cd0b0607c8bab0060a9f57688`;
- physical contract: `34` WBS/package, `316` activity, `29` profile field;
- exact metadata: `0.3-yfk-resource-seed`, `RESEARCH_RESOURCE_SEED`, `NOT_FOR_PRODUCTION`, `ACTIVITY_CATALOG_READ_ONLY_NO_YFK_RESOURCE_COEFFICIENTS`;
- runtime activity satırlarında fiyat, YFK tam/ham analiz alanı veya malzeme/işçilik/makine resource coefficient alanı yoktur;
- çalışma girdisi ZIP'leri repository'ye eklenmedi.

## Düzeltilen blocker'lar

- Loader version/publication/production/runtime-scope ile canonical WBS/activity/profile-field count sözleşmelerini exact doğruluyor.
- Activity referansı ayrı WBS ve package kümeleri yerine exact `(wbs_code, package_id)` çiftiyle doğrulanıyor.
- Applicability AST; nested op, operand/group biçimi ve bütün field referansları için corpus load sırasında recursive doğrulanıyor.
- Eksik profile field, `eq/neq/in` ve bunları saran `any/all/not` ağaçlarında fail-closed kalıyor; `not` eksik bilgiyi `true` yapmıyor.
- RADYE/TEKIL branch ayrımı ile search/filter ID sıralaması deterministic testlerle sabitlendi.

## Çalıştırılan doğrulamalar

- Read-only ZIP/entry/runtime JSON hash ve içerik probe'u: exit `0`.
- `Get-FileHash -Algorithm SHA256 mobile/assets/corpus/cse_construction_activity_catalog_v0_3.b64`: exit `0`, exact asset hash PASS.
- İlk kısa `flutter pub get --offline` çağrısı PowerShell `PATH` içinde executable olmadığı için uygulamayı başlatmadı (`CommandNotFound`, process exit code üretmedi); dosya veya paket durumu değişmedi.
- `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat pub get --offline`: exit `0`.
- `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\dart.bat format lib/domain/construction_corpus_models.dart lib/application/construction_corpus_repository.dart test/construction_corpus_repository_test.dart`: exit `0`, `3` dosya formatlandı.
- `flutter.bat test --no-pub test/construction_corpus_repository_test.dart`: exit `0`, `22/22 PASS`.
- `flutter.bat analyze --no-pub`: exit `0`, `No issues found`.
- `git diff --check`: exit `0`.
- exact base-to-worktree allowlist/protected-path sınıflandırması: exit `0`, beklenmeyen dosya `0`, protected drift `0`.
- final source revision `flutter.bat test --no-pub`: exit `0`, `529/529 PASS`.

## Minimum yeterli doğrulama ve drift

- Validation class: `domain`.
- Full Flutter suite final source revision üzerinde yalnız bir kez çalıştırıldı; source değişmeden tekrar edilmedi.
- APK/AAB, signing, ARM64/16 KiB, fiziksel cihaz, backup/restore ve reboot/notification gate'leri çalıştırılmadı; değişen sözleşme read-only asset/domain/application sınırında kaldı.
- Base `496e5bd0100a55d42e0320b932e510d34453f2dd` karşılaştırmasında dependency block ve `mobile/pubspec.lock` drift'i `0`; tek `pubspec.yaml` farkı asset kaydıdır.
- Platform file drift'i `0`; SQLite/migration, schedule engine ve UI drift'i `0`.
- `AppDatabase.schemaVersion = 13` ve `CseBackupCodec.formatVersion = 1` değişmedi.
- Mevcut merged schema/Backup/dependency/platform kanıtı değişmeyen sözleşmeler için yeniden kullanıldı; full suite ayrıca bu revision'da regresyon vermedi.
- Süre bütçesi: Issue yorumunda yetkilendirilen `75 dakika` hard stop aşılmadı.
- Retry bütçesi: tek primary doğrulama zinciri; yalnız başlamayan PATH çağrısı için bir correction kullanıldı, test/build gate tekrarı yapılmadı.
- Kapsam dışı altyapı sorunu: yok. PATH eksikliği kurulu ve repository'de daha önce kaydedilmiş mutlak Flutter SDK yoluyla giderildi; toolchain/repository değişikliği yapılmadı.

## Teknik karar ve learning notu

Applicability değerlendirmesi içte `matches / doesNotMatch / missingField` ayrımını korur ve public API'de yalnız kesin eşleşmeyi `true` döndürür. Şunu böyle yaptık ki nested `not` veya kısmi `any/all` ağacı eksik profil bilgisini istemeden olumlu eşleşmeye çevirmesin. Corpus load akışı parse → exact metadata/count → uniqueness/reference → recursive declared-field validation sırasını izler; testler her güven sınırını kanonik root'un bağımsız kopyalarını bozarak doğrular.

## Publication durumu

- Correction commit/push ve Draft PR #444 / Issue #443 completion güncellemesi bu kanıt dosyasından sonra yapılacaktır.
- PR Ready yapılmayacak, merge edilmeyecek ve Issue #445 başlatılmayacaktır.
