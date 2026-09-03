# CSE Minimum Yeterli Doğrulama Protokolü — One-Pass Validation v4

**Belge türü:** Bağlayıcı validation ve evidence protokolü
**Geçerlilik tarihi:** 2026-09-03

Doğru hedef maksimum test değil, değişen sözleşmenin riskini karşılayan minimum yeterli doğrulamadır.

## 1. Execution ve kabul sahipliği

Repository-local terminal, automated test, analyzer ve build/APK hazırlığı Codex tarafından, yetkili görevin minimum yeterli kapsamıyla yürütülür. Fatih PowerShell/terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; kendisine bu komutlar hazırlanmaz veya verilmez. Fatih yalnız manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir. Emulator/ADB/device execution yalnız exact package, cihaz ve veri-koruma sınırıyla açık owner delegasyonunda yapılabilir; MAIN/Acceptance/Debug ve mevcut veri güvenliği sınırları korunur.

Codex format, diff, `git diff --check` ve protected drift kontrolünü de yapar. Açık device delegasyonunda yalnız exact komutu çalıştırır; kapsam genişletmez ve retry yapmaz.

## 2. Validation sınıfları

Non-CRITICAL varsayılanı `reproduce once -> fix -> one focused validation -> only-needed manual/device check -> owner merge gate` akışıdır. Aşağıdaki sınıf, tek focused automated validation'ın kapsamını belirler; docs işinde statik docs kontrolleri yeterlidir. Analyzer yalnız material ihtiyaçta eklenir. CRITICAL sınıfların zorunlu test, compatibility, device ve release kapıları bu sadeleştirmeyle atlanmaz.

Doğrudan, tekrarlanabilir owner/device repro kanıtı varsa ilk adım karşılanmıştır. Source root cause yeterince belirlenmişse düzeltme öncesi deterministic automated FAIL aranmaz. Owner/device kanıtı, davranışı temsil edemeyen yapay harness'ten üstündür; widget/fake PASS, cihaz FAIL'ini geçersiz kılmaz. Bir başarısız repro denemesinden sonra source/runtime diagnosis veya mevcut en güçlü kanıta geçilir.

### docs

Minimum:

- exact changed paths;
- Markdown/JSON yapısı gerekiyorsa statik kontrol;
- `git diff --check`;
- production/test path drift yokluğu.

Test/analyzer/build/device gerekmez.

### narrow-ui

Minimum doğrulama (automated execution Codex, manuel kabul Fatih):

- değişen behavior için tek focused automated doğrulama;
- analyzer yalnız değişen Dart sözleşmesi veya statik risk için material ihtiyaç varsa;
- manuel/device kabul yalnız runtime'a özgü davranışta veya owner açıkça istediğinde; yalnız değişen yolun kontrolü.

Full suite her mikro adımda çalıştırılmaz.

### domain

Minimum doğrulama (automated execution Codex, manuel kabul Fatih):

- ilgili domain/application testleri;
- etkilenen adapter/persistence testleri;
- material cross-module analyzer;
- milestone sonunda gerekli etkilenen/full suite;
- yalnız runtime'a özgü davranışta veya owner açıkça istediğinde değişen kullanıcı yolunun manuel/device kabulü.

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

Sınıfın zorunlu minimumunu karşılayan stop-on-success sırası:

1. diff/scope kontrolü;
2. tek focused automated validation (docs sınıfında statik kontrol);
3. analyzer/etkilenen suite — gerekiyorsa;
4. full suite — milestone veya risk gerektiriyorsa;
5. manuel/device ve gerekiyorsa build — runtime'a özgü davranış veya açık owner talebi varsa;
6. release gate — yalnız CRITICAL/release.

Sınıfın minimumu karşılandıysa sırf daha fazla güven hissi için sonraki basamak çalıştırılmaz. Gereken manuel/device kabul Fatih'in PASS/FAIL kapısıdır; Codex automated PASS bu kararı vermez. Non-CRITICAL işte bu kabul gerekmiyorsa gerekçesiyle `GEREKMİYOR` kaydedilir ve Codex automated PASS sonrası yetkili commit/push manuel PASS beklemez.

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
Manual check: GEREKMİYOR (<gerekçe>) | PENDING | PASS | FAIL
Expected result: <yalnız gereken manuel kontrol için>
```

Codex automated sonuçları ve exact hatayı raporlar. Fatih yalnız manuel ürün/device kabulü için `PASS` veya `FAIL` bildirir; kendisine terminal komutu verilmez.

Non-CRITICAL publication:

- Codex automated PASS ve manuel/device kabul GEREKMİYOR: yetkili commit/push yapılabilir.
- Manuel/device kabul gerekiyorsa Codex automated PASS yanında Fatih PASS gerekir.
- Gerekli doğrulama/kabul FAIL veya PENDING/PARTIAL: commit/push kapalı kalır; exact hata için same-scope correction kuralı uygulanır.
- STANDARD işte normalde ilk teslimden sonra en fazla bir same-scope correction turu; sorun sürüyorsa escalation.

CRITICAL publication ve owner Ready/merge/release kapıları değişmez.

## 6. Süre bütçesi

Her Codex handoff'unda ChatGPT açık `Execution time budget: <süre>` verir. Süre; kapsam, risk, beklenen validation/build/device işi ve mevcut blocker'a göre atanır; global sabit süre varsayılanı yoktur.

Repository-local terminal, automated test, analyzer, build ve açıkça devredilen emulator/ADB/device execution bu göreve özel bütçeye dahildir; owner manuel kabulü ayrı değerlendirilir. İnceleme, edit/fix, focused validation ve yetkili commit/push bütçeye sığıyorsa tek adımda birleştirilir.

Bütçe dolunca Codex durur:

- yeni yaklaşım veya geniş gate başlatmaz;
- kapsamı genişletmez;
- çalışmayı güvenle korur; tamamlanan işi, exact blocker'ı ve kalan tek adımı raporlar.

Gerekli yeni handoff'un bütçesini ChatGPT belirler. Süre bütçesi CRITICAL validation veya veri güvenliği kapılarını kaldırmaz.

## 7. Test tekrarları ve ortam hatası

- Non-CRITICAL işte kararı değiştirmeyen diagnostic/test/harness döngüleri yasaktır; tek başarısız repro denemesinden sonra source/runtime diagnosis veya mevcut en güçlü kanıta geçilir.
- Aynı failed operation exact düzeltme olmadan tekrarlanmaz.
- Ortam/toolchain hatası feature kapsamına sessizce alınmaz.
- Codex exact hata çıktısını kaydeder ve yalnız current scope içindeki dar source correction'ı hazırlar.
- Toolchain, SDK, Gradle, signing veya device setup değişikliği ayrı karar ister.

## 8. Fiziksel cihaz kabulü

Non-CRITICAL manuel/device kontrolü yalnız runtime'a özgü davranışta veya owner açıkça istediğinde, değişen kullanıcı yolunu bir kez doğrular. Gerekli kontrolün PASS/FAIL kararı Fatih'tedir. CRITICAL Issue'ya özel cihaz ve release kapıları aynen uygulanır.

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
owner validation: GEREKMİYOR (<gerekçe>)|PENDING|PASS|FAIL
commit/push: NOT_DONE|<sha>
```

STANDARD kısa test özeti kullanır. CRITICAL detailed compatibility/provenance taşıyabilir.

Test edilmemiş behavior `VERIFIED`, `FIELD_ACCEPTED` veya `RELEASE_READY` diye sunulmaz.

## 10. Stop kriterleri

Codex şu durumlarda durur:

- handoff'taki açık execution time budget doldu;
- yeni CRITICAL trigger bulundu;
- allowlist/scope genişlemesi gerekiyor;
- kullanıcı verisi/destructive risk oluştu;
- beklenmeyen dosya değişikliği var;
- validation için yeni platform/signing/toolchain işi gerekiyor.

## 11. Ana karar

> Non-CRITICAL işte Codex tek focused validation ile ilerler; Fatih yalnız gereken manuel/device kabulünü verir. Göreve özel süre bütçesi, exact device delegasyonu ve veri güvenliği sınırları korunur. Aynı kanıt tekrar üretilmez; CRITICAL ve owner Ready/merge/release kapıları değişmez.
