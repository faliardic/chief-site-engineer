# CSE Minimum Yeterli Doğrulama Protokolü — Codex Execution / Owner Acceptance v3

**Belge türü:** Bağlayıcı validation ve evidence protokolü
**Geçerlilik tarihi:** 2026-09-02

Doğru hedef maksimum test değil, değişen sözleşmenin riskini karşılayan minimum yeterli doğrulamadır.

## 1. Execution ve kabul sahipliği

Repository-local terminal, automated test, analyzer ve build/APK hazırlığı Codex tarafından, yetkili görevin minimum yeterli kapsamıyla yürütülür. Fatih PowerShell/terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; kendisine bu komutlar hazırlanmaz veya verilmez. Fatih yalnız manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir. Emulator/ADB/device execution yalnız exact package, cihaz ve veri-koruma sınırıyla açık owner delegasyonunda yapılabilir; MAIN/Acceptance/Debug ve mevcut veri güvenliği sınırları korunur.

Codex format, diff, `git diff --check` ve protected drift kontrolünü de yapar. Açık device delegasyonunda yalnız exact komutu çalıştırır; kapsam genişletmez ve retry yapmaz.

## 2. Validation sınıfları

### docs

Minimum:

- exact changed paths;
- Markdown/JSON yapısı gerekiyorsa statik kontrol;
- `git diff --check`;
- production/test path drift yokluğu.

Test/analyzer/build/device gerekmez.

### narrow-ui

Minimum doğrulama (automated execution Codex, manuel kabul Fatih):

- değişen behavior için focused test veya kısa manuel senaryo;
- Dart değiştiyse uygun analyzer komutu;
- runtime görünürlüğü gerekiyorsa yalnız değişen yolun APK/device kontrolü.

Full suite her mikro adımda çalıştırılmaz.

### domain

Minimum doğrulama (automated execution Codex, manuel kabul Fatih):

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
Codex execution / result:
Manual check:
Expected result:
```

Codex automated sonuçları ve exact hatayı raporlar. Fatih yalnız manuel ürün/device kabulü için `PASS` veya `FAIL` bildirir; kendisine terminal komutu verilmez.

- PASS: commit/push kapısını açar.
- FAIL: commit/push yapılmaz; exact hata için yeni mikro correction hazırlanır.
- PENDING/PARTIAL: FAST commit/push kapalı kalır.

## 6. Süre bütçesi

Tek Codex işlemi için hard stop: **5 dakika**.

Repository-local terminal, automated test, analyzer ve build dahil bütün Codex execution bu 5 dakikalık hard-stop içindedir. Açıkça devredilen emulator/ADB/device execution da aynı sınıra tabidir; owner manuel kabulü ayrı değerlendirilir.

5 dakika dolunca Codex:

- yeni yaklaşım veya geniş gate başlatmaz;
- kapsamı genişletmez;
- tamamlanan işi ve kalan tek adımı raporlar.

STANDARD/CRITICAL görev birden fazla mikro adıma bölünebilir.

## 7. Test tekrarları ve ortam hatası

- Aynı failed operation exact düzeltme olmadan tekrarlanmaz.
- Ortam/toolchain hatası feature kapsamına sessizce alınmaz.
- Codex exact hata çıktısını kaydeder ve yalnız current scope içindeki dar source correction'ı hazırlar.
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

> Codex kaynak değişikliğini ve minimum yeterli automated execution'ı yapar; Fatih manuel ürün/device kabulünü verir. Device execution için exact owner delegasyonu ve veri güvenliği sınırları korunur. Aynı kanıt tekrar üretilmez, full gate yalnız risk veya milestone gerektirdiğinde çalışır.
