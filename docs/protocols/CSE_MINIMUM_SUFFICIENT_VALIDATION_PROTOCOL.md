# CSE Minimum Yeterli Doğrulama Protokolü

**Belge türü:** Bağlayıcı Codex execution/validation addendum  
**Geçerlilik tarihi:** 2026-07-23  
**Kapsam:** Bütün CSE Issue, task, Codex run, test, build, cihaz kabulü ve completion evidence işlemleri

Bu belge, `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` içindeki yürütme ve doğrulama kurallarını güvenlikten ödün vermeden risk-temelli hâle getirir. Çelişki halinde test/gate genişliği, retry bütçesi, süre bütçesi ve kanıt yeniden kullanımı konusunda bu protokol uygulanır.

## 1. Temel ilke

> Doğru hedef, maksimum mümkün kanıt değil; değişen sözleşmenin riskini karşılayan minimum yeterli kanıttır.

Minimum yeterli doğrulama:

- güvenlik kapılarını kaldırmaz;
- veri kaybı riskini küçümsemez;
- yalnız değişmeyen sözleşmelerin tekrar tekrar kanıtlanmasını engeller;
- ortam arızasını feature kapsamına dönüştürmez;
- kullanıcıya görünür işin süresini kontrol altında tutar.

## 2. Validation class

Her Issue ve `.cse/tasks/<issue_no>_task.md` aşağıdaki sınıflardan birini açıkça seçer.

### `docs`

Örnek:

- yalnız dokümantasyon;
- roadmap, ADR, protocol, learning veya Issue kanıtı;
- production davranışı yok.

Minimum doğrulama:

- değişen dosya kapsamı;
- Markdown/JSON sözdizimi gerekiyorsa ilgili kontrol;
- `git diff --check`;
- protected production path diff'inin boşluğu.

Yapılmaz:

- full Python/Flutter suite;
- APK/AAB build;
- release gate;
- emülatör/fiziksel cihaz kabulü.

### `narrow-ui`

Örnek:

- yeni filtre veya buton;
- label, layout, empty state;
- presentation-only read-model;
- mevcut application mutation'ının yeni yüzeyde kullanımı.

Minimum doğrulama:

1. ilgili unit/application testleri;
2. ilgili widget testleri;
3. static analyze/lint;
4. gerekiyorsa tek debug build;
5. yalnız değişen kullanıcı yolunun minimum cihaz doğrulaması.

Varsayılan olarak yapılmaz:

- full release gate;
- signed/unsigned AAB;
- ARM64/16 KiB/signing tekrar kanıtı;
- background/reboot acceptance;
- backup/restore tatbikatı;
- bütün Python repository suite.

### `domain`

Örnek:

- reminder lifecycle;
- iş paketi geçişi;
- optimistic revision;
- append-only event;
- notification reschedule davranışı.

Minimum doğrulama:

1. odaklı domain/application testleri;
2. ilgili persistence veya platform adapter testleri;
3. etkilenen mobil/Python suite;
4. bir kez full suite, yalnız risk matrisi gerektiriyorsa;
5. ilgili minimum cihaz senaryosu.

### `persistence`

Örnek:

- schema/migration;
- backup/restore formatı;
- attachment lifecycle;
- atomik replace/rollback;
- source-of-truth veri modeli.

Minimum doğrulama:

- migration fixture ve rollback;
- integrity/FK/hash;
- restore/round-trip;
- full etkilenen suite;
- veri koruyan gerçek cihaz veya gerçekçi integration kapısı;
- Issue'da açıkça listelenen compatibility gate'leri.

### `release-critical`

Örnek:

- application ID/entrypoint;
- signing;
- Android API/NDK/16 KiB;
- izinler/privacy;
- release scripti;
- background/reboot delivery motoru;
- store artifact üretimi.

Minimum doğrulama bu sınıfta tam release gate ve ilgili acceptance zincirini içerebilir. Bu sınıf dar UI işi için kullanılamaz.

## 3. Issue talimat sözleşmesi

Her yeni teknik Issue aşağıdaki bloğu içerir:

```text
Validation class:
Changed contracts:
Focused tests:
Allowed broad gates:
Reused evidence:
Minimum physical-device acceptance:
Retry budget:
Time budget:
Out of scope:
Stop conditions:
```

Bu blok yoksa ChatGPT/Codex görevi geniş yorumlamaz. Önce bu alanları current Issue yorumunda netleştirir.

## 4. Doğrulama merdiveni

Doğrulama sırayla ve stop-on-success çalışır:

1. **Diff/scope kontrolü**
2. **Odaklı test**
3. **Etkilenen suite**
4. **Tek geniş suite** — yalnız gerekliyse
5. **Tek build** — yalnız runtime/artifact gerekiyorsa
6. **Release gate** — yalnız `release-critical` veya açık Issue izniyle
7. **Minimum cihaz kabulü** — yalnız kullanıcıya görünür değişen yol

Bir basamak yeterli kanıt verdiyse sırf daha fazla güven hissi için sonraki basamağa geçilmez.

## 5. Kanıt yeniden kullanımı

Aşağıdaki sözleşmeler değişmediyse son merged ve doğrulanmış kanıt yeniden kullanılır:

- schema ve migration;
- backup formatı;
- application/package ID;
- signing;
- ARM64 ve 16 KiB;
- permission/privacy matrisi;
- background delivery;
- reboot reconciliation;
- restore/rollback;
- entrypoint provenance.

Kanıt yeniden kullanımı completion evidence içinde şu formatta yazılır:

```text
Reused evidence:
- Contract:
- Source Issue/PR/commit:
- Why still valid:
```

“Tekrar çalıştırılmadı” eksiklik değil, bilinçli risk-temelli karardır.

## 6. Full gate kuralları

- Aynı source revision üzerinde aynı full gate en fazla bir kez çalıştırılır.
- Gate başarıyla geçtiyse, yalnız dokümantasyon veya cihaz kabul komutu değişti diye tekrar çalıştırılmaz.
- Gate kullanıcı mesajıyla kesildiyse süreç/artifact durumu incelenir; geçerli kalan aşamalar yeniden çalıştırılmaz.
- Ortam arızasında yalnız başarısız aşama tekrarlanır.
- Source code gate sonrasında değiştiyse yalnız değişikliğin etkilediği aşama ve gerekli üst kapılar yeniden çalıştırılır.
- Gate scriptinin kendisi feature branch içinde değiştirilirse bu artık `release-critical` kapsamdır; ayrı Issue gerekir.

## 7. Retry ve süre bütçesi

### Varsayılan bütçe

```text
1 technical step = 1 primary Codex run
blocking correction = at most 1 correction run
same failed operation = at most 1 retry after exact fix
```

### Süre hedefleri

| Validation class | Hedef | Hard stop |
| --- | ---: | ---: |
| docs | 10–15 dk | 25 dk |
| narrow-ui | 20–30 dk | 45 dk |
| domain | 30–45 dk | 75 dk |
| persistence | Issue'a özel | Issue'a özel |
| release-critical | Issue'a özel | Issue'a özel |

Hard stop geldiğinde:

- yeni yaklaşım zinciri başlatılmaz;
- yeni full gate çalıştırılmaz;
- kapsam genişletilmez;
- tamamlanan kanıt, exact blocker ve kalan tek adım raporlanır;
- gerekiyorsa ayrı blocker Issue açılır.

## 8. Ortam ve toolchain arızaları

Feature sırasında bulunan şu tür sorunlar feature kapsamına sessizce alınmaz:

- Gradle daemon/file lock;
- Flutter cache bozulması;
- bundletool/apksigner stderr davranışı;
- emulator disconnect;
- PowerShell parser/regex/coordinate automation hatası;
- release scripti eksikliği;
- JDK/SDK/toolchain problemi.

Yapılacaklar:

1. Feature kodu ile ortam hatasını ayır.
2. Bir kez dar düzeltme/yeniden deneme yap.
3. Devam ederse ayrı Issue aç.
4. Mevcut feature branch'ine toolchain düzeltmesi ekleme.
5. Kullanıcı açıkça scope genişletmedikçe feature acceptance'ı minimum manuel veya alternatif kanıtla tamamla.

## 9. Fiziksel cihaz kabulü

Fiziksel cihaz kontrolü yalnız değişen kullanıcı yolunu doğrular.

### `narrow-ui` için örnek yeterli kabul

- yeni filtre/buton görünür;
- doğru kayıtlar görünür;
- yanlış kayıtlar görünmez;
- kart detayı açılır;
- ilgili mutasyon varsa tek dokunuşla çalışır;
- uygulama açılır ve mevcut veri görünür.

Değişmeyen alanlar için yeniden yapılmaz:

- reboot;
- background notification delivery;
- full backup/restore;
- DB hash envanteri;
- signing/permission matrisi;
- production package temizliği.

ADB UI otomasyonu:

- minimum komut kullanır;
- kullanıcı verisi içeriğini okumaz;
- koordinat/regex hatasında en fazla bir düzeltme yapılır;
- ikinci otomasyon hatasında kullanıcıdan tek ekran doğrulaması istenir;
- otomasyon kanıtı uğruna 45 dakika sınırı aşılmaz.

## 10. Kapsam kontrolü

Her 10–15 dakikada bir Codex şu kontrolü yapar:

```text
Current goal:
Current changed files:
Current validation class:
Still inside Issue scope: yes/no
Broad gate already run: yes/no
Elapsed time:
Remaining single acceptance step:
```

`Still inside Issue scope = no` ise edit durur. Yeni iş ayrı Issue olur.

## 11. ChatGPT sorumluluğu

ChatGPT:

- Issue'yu gereğinden geniş yazmaz;
- risk sınıfını açıkça seçer;
- izin verilen gate'leri listeler;
- eski geçerli kanıtları Issue'ya bağlar;
- kullanıcıya terminal/ADB adımlarını gereksiz yere yaptırmaz;
- Codex'in 45 dakikayı aşan dar görevini normalleştirmez;
- completion sonrası branch/PR/merge işini GitHub üzerinden yönetir.

## 12. Codex completion formatı

```text
Validation class:
Elapsed time:
Primary run count:
Correction run count:
Changed contracts:
Focused tests run:
Broad gates run:
Broad gates intentionally not run:
Reused evidence:
Physical-device checks:
Out-of-scope findings / new Issues:
Commit / push:
Remaining blocker:
```

## 13. Stop kriterleri

Aşağıdakilerden biri oluşursa Codex kendi kendine genişlemeyi durdurur:

- dar görev 45 dakikayı geçti;
- aynı full gate ikinci kez isteniyor ve source revision değişmedi;
- ikinci ortam/otomasyon hatası oluştu;
- release scripti değişikliği gerekiyor fakat Issue `release-critical` değil;
- kullanıcı verisine yeni risk oluştu;
- kapsam dışı dosya değişikliği gerekiyor;
- acceptance için yeni sertifika/uninstall/data clear gerekiyor fakat açık izin yok.

Bu stop, başarısızlık değil; kontrollü yürütme sonucudur.
