# CSE Minimum Yeterli Doğrulama Protokolü — Owner-Tested v2

**Belge türü:** Bağlayıcı validation ve evidence protokolü
**Geçerlilik tarihi:** 2026-09-02

Doğru hedef maksimum test değil, değişen sözleşmenin riskini karşılayan minimum yeterli doğrulamadır.

## 1. Test sahibi

Bütün test, analyzer ve manuel ürün kabulünün sahibi Fatih'tir. Build/APK/ADB/device execution'ı da varsayılan olarak Fatih'tedir.

Fatih exact package, cihaz ve data-safety sınırıyla açıkça devrederse Codex yalnız belirtilen build/APK/ADB/device execution'ını tek bir 5 dakikalık hard-stop görevi olarak çalıştırabilir. Bu istisna test/analyzer veya PASS/FAIL ve ürün kabulü kararını Codex'e devretmez.

Codex:

- test çalıştırmaz;
- analyzer çalıştırmaz;
- varsayılan olarak APK/AAB üretmez ve emulator/ADB/device işlemi yapmaz;
- açık delegasyonda yalnız exact build/APK/ADB/device komutunu çalıştırır; kapsam genişletmez ve retry yapmaz;
- changed contract'a göre exact komut ve manuel kontrol listesi verir;
- kaynak tarafında format, diff, `git diff --check` ve protected drift kontrolü yapar.

## 2. Validation sınıfları

### docs

Minimum:

- exact changed paths;
- Markdown/JSON yapısı gerekiyorsa statik kontrol;
- `git diff --check`;
- production/test path drift yokluğu.

Test/analyzer/build/device gerekmez.

### narrow-ui

Minimum owner doğrulaması:

- değişen behavior için focused test veya kısa manuel senaryo;
- Dart değiştiyse uygun analyzer komutu;
- runtime görünürlüğü gerekiyorsa yalnız değişen yolun APK/device kontrolü.

Full suite her mikro adımda çalıştırılmaz.

### domain

Minimum owner doğrulaması:

- ilgili domain/application testleri;
- etkilenen adapter/persistence testleri;
- material cross-module analyzer;
- milestone sonunda gerekli etkilenen/full suite;
- yalnız değişen kullanıcı yolunun cihaz kabulü.

### persistence

CRITICAL lane gerektirir:

- migration fixture ve rollback;
- integrity/FK/hash;
- restore/round-trip;
- full etkilenen suite;
- veri koruyan integration/device gate;
- explicit compatibility contract.

### release-critical

CRITICAL lane gerektirir. Signing, permission, application ID, platform/runtime, background/reboot veya store artifact'i için Issue'ya özel release gate uygulanır.

## 3. Doğrulama merdiveni

Stop-on-success sırası:

1. diff/scope kontrolü;
2. focused test veya manuel değişen-yol kontrolü;
3. analyzer/etkilenen suite — gerekiyorsa;
4. full suite — milestone veya risk gerektiriyorsa;
5. build/device — runtime davranışı gerekiyorsa;
6. release gate — yalnız CRITICAL/release.

Bir basamak yeterli kanıt verdiyse sırf daha fazla güven hissi için sonraki basamak çalıştırılmaz.

## 4. Kanıt yeniden kullanımı

Aşağıdaki contract değişmediyse son merged/validated kanıt yeniden kullanılabilir:

- schema/migration;
- backup formatı;
- package/application ID;
- signing/permission;
- background/reboot;
- restore/rollback;
- entrypoint/artifact provenance.

Aynı source revision üzerinde geçen test tekrar çalıştırılmaz. Kaynak değiştiğinde yalnız etkilenen test ve gerekli üst kapı yeniden çalıştırılır.

## 5. Mikro adım doğrulaması

Codex her mikro adım sonunda şunu teslim eder:

```text
Changed behavior:
Changed paths:
Static checks:
Run this command:
Manual check:
Expected result:
```

Fatih sonucu `PASS`, `FAIL` veya exact hata ile bildirir.

- PASS: commit/push kapısını açar.
- FAIL: commit/push yapılmaz; exact hata için yeni mikro correction hazırlanır.
- PENDING/PARTIAL: FAST commit/push kapalı kalır.

## 6. Süre bütçesi

Tek Codex işlemi için hard stop: **5 dakika**.

Bu sınır test süresine değil Codex execution süresine uygulanır. Codex'e açıkça devredilen build/APK/ADB/device execution'ı da 5 dakikalık hard-stop içindedir. Fatih'in çalıştırdığı test/build süresi ayrı kaydedilebilir.

5 dakika dolunca Codex:

- yeni yaklaşım veya geniş gate başlatmaz;
- kapsamı genişletmez;
- tamamlanan işi ve kalan tek adımı raporlar.

STANDARD/CRITICAL görev birden fazla mikro adıma bölünebilir.

## 7. Test tekrarları ve ortam hatası

- Aynı failed operation exact düzeltme olmadan tekrarlanmaz.
- Ortam/toolchain hatası feature kapsamına sessizce alınmaz.
- Fatih exact hata çıktısını paylaşır; Codex yalnız current scope içindeki dar source correction'ı hazırlar.
- Toolchain, SDK, Gradle, signing veya device setup değişikliği ayrı karar ister.

## 8. Fiziksel cihaz kabulü

Cihaz kontrolü yalnız değişen kullanıcı yolunu doğrular.

Tekrarlanmaz:

- değişmeyen reboot/background davranışı;
- full backup/restore;
- signing/permission matrisi;
- production package temizliği;
- kullanıcı verisi envanteri.

MAIN/production ve gerçek kullanıcı verisine açık CRITICAL authority olmadan dokunulmaz.

## 9. Completion

FAST:

```text
static checks: PASS|FAIL
owner validation: PENDING|PASS|FAIL
commit/push: NOT_DONE|<sha>
```

STANDARD kısa test özeti kullanır. CRITICAL detailed compatibility/provenance taşıyabilir.

Test edilmemiş behavior `VERIFIED`, `FIELD_ACCEPTED` veya `RELEASE_READY` diye sunulmaz.

## 10. Stop kriterleri

Codex şu durumlarda durur:

- 5 dakika doldu;
- yeni CRITICAL trigger bulundu;
- allowlist/scope genişlemesi gerekiyor;
- kullanıcı verisi/destructive risk oluştu;
- beklenmeyen dosya değişikliği var;
- validation için yeni platform/signing/toolchain işi gerekiyor.

## 11. Ana karar

> Codex kaynak değişikliğini kısa ve kontrollü yapar; test/analyzer ve kabulü Fatih yürütür. Exact owner delegasyonunda Codex yalnız build/APK/ADB/device execution'ını yapabilir. Aynı kanıt tekrar üretilmez, full gate yalnız risk veya milestone gerektirdiğinde çalışır.
