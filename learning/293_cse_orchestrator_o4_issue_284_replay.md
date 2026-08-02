# Issue #293 Öğrenme — İnsan Yürütme Geçmişi Nasıl Güvenli Replay Oldu?

## Problem

Issue #284, tek bir doğrusal “kod yaz–test et–bitir” çalışması değildi. İlk
authorization'dan sonra source failure, widget harness sorunları, tool timeout,
dar corrections, reused validation evidence, checkpoint ve cihaz continuation
yorumları geldi. Raw yorumları fixture'a kopyalamak hem gereksiz hem de kullanıcı
ve cihaz verisi riskiydi.

O4'te amaç geçmişi yeniden çalıştırmak değil; hangi yetkinin ne zaman geçerli
olduğunu ve hangi action'ın neden başlayabildiğini sanitize metadata ile tekrar
hesaplamaktır.

## Gerçek kod akışı

Test fixture'ı Python dışında düz JSON'dur. Test onu yükledikten sonra engine'e
mapping olarak verir:

```python
value = json.loads(fixture_path.read_text(encoding="utf-8"))
summary = replay_issue_284(value)
```

Engine dosya yolunu bilmez. İç akış şöyledir:

1. Exact top-level ve nested alan setini doğrula.
2. Base/branch/checkpoint/final sabitlerini doğrula.
3. Event'i canonical bytes'a çevir; exact replay ise no-op, collision ise fail.
4. Sequence ve source authority'yi doğrula.
5. GitHub authorization ise exact supersession + scope + approval + capability
   + fingerprint zincirini uygula.
6. Result ise bağlı authorization/action fingerprint'ini doğrula; yalnız
   `action_started is True` olduğunda invocation say.
7. Budget'ı yalnız authorization delta'sından topla.
8. Checkpoint/evidence/final gate'i doğrulayıp frozen summary üret.

Canonical çıktı:

```python
text = canonical_replay_json(summary)
```

sorted key ve compact separators kullandığı için aynı fixture aynı byte
dizisini üretir.

## O1–O3'ten alınan dersler

- O1: Daha yeni olmak tek başına authority değildir. Explicit supersession ve
  GitHub source precedence gerekir.
- O2: Approval seviyesi ambient yetki değildir; action, capability, scope,
  source ve fingerprint birlikte eşleşir. Budget authorization event'inde
  görünür artar.
- O3: Wrapper/tool timeout her zaman invocation başlamış demek değildir.
  `action_started` kanıtlanmadığında consumed varsayılmaz; failure class ayrı
  kalır.

O4 bu katmanların hiçbirini runner'a dönüştürmez. Replay sonucu action
başlatabilecek token veya yeni approval değildir.

## Testlerin amacı

- Exact 19 comment ID testi fixture'ın eksik veya başka Issue verisiyle
  karışmadığını gösterir.
- Duplicate testi aynı event replay'ini no-op, aynı ID farklı payload'ı history
  collision sayar.
- Supersession testi eski comment'in daha yeni valid authority'yi override
  edemediğini kanıtlar.
- Task/state precedence testi lower-authority sahte publish kaydının budget veya
  latest-valid approval üretemediğini gösterir.
- Blind retry testi aynı authorization'ın ikinci started result'ını reddeder.
- Drift parametrizasyonu source, branch, action ve capability bağlarının ayrı
  ayrı fail-closed olduğunu gösterir.
- Checkpoint parent/tree testi build/device continuation'ın exact committed
  source'a bağlı olduğunu korur.
- Forbidden-pattern testi fixture'da raw body/stream, gerçek cihaz ve yerel
  kullanıcı yolu sınıflarının bulunmadığını executable yapar.
- I/O guard testi `open`, `subprocess.run` ve `socket.socket` kapalıyken replay'in
  yine aynı summary'yi verdiğini doğrular.

## Teknik kararlar

- Fixture bir transcript değildir; yalnız karar/provenance metadata'sıdır.
- Sparse budget delta yalnız pozitif counter taşır. Result event'inde delta
  bulunması schema-valid görünse bile reddedilir.
- Lower-authority record strict event şemasından geçebilir fakat GitHub
  authorization chain'ine, budget'a veya action admission'a katılmaz.
- Reused evidence raw test output'u değil data-minimal identity'dir. Aynı action
  zincirinde identity farkı drift'tir.
- `DEVICE_ACCEPTANCE_PENDING` ürün blocker'ı değildir; replay'in açık kalan
  teknik gate işaretidir.
- Final summary Issue #284'ü kapatmaz, checkpoint'i pushlamaz ve completion
  kararı üretmez.

## Şunu şöyle yaptık ki...

- 19 yorumun gövdesini değil ID ve karar alanlarını tuttuk ki gerçek akış
  korunurken gereksiz veri fixture'a girmesin.
- Device'i `tablet_primary` yaptık ki fiziksel serial replay source'una
  dönüşmesin.
- Exact checkpoint tree'yi doğruladık ki build/device evidence başka source'a
  taşınamasın.
- Action-start'ı nullable tuttuk ki tool timeout'ta bilinmeyen provenance sahte
  budget consumption üretmesin.
- Final state'i frozen gate yaptık ki replay başarıyla geçse bile tarihsel
  Issue sahte biçimde `COMPLETED` olmasın.
