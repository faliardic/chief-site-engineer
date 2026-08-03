# Issue #305 — O10.1 canlı pilot bootstrap ve tablet smoke

## Amaç

O10.1, checkpoint'te bekleyen Issue #284 işini kullanıcıdan gate bazlı JSON,
prompt veya ADB komutu istemeden tek başlangıç komutuna bağlar. Bu teslimat ürün
davranışını değiştirmez; mevcut O10 coordinator'a target-specific fakat strict
ve yeniden kullanılabilir bir bootstrap ile tablet smoke adapter'ı ekler.

```powershell
python -m tools.cse_orchestrator.cli workflow-bootstrap `
  --issue 284 `
  --target-root V:\path\to\issue-284-worktree `
  --runtime-root C:\external\cse-runtime
```

Komut varsayılan olarak dry-run'dır ve üretilen machine authorization'ı
gösterir. Gerçek workflow ancak aynı komuta `--execute` eklendiğinde başlar.

## Strict bootstrap

Bootstrap aşağıdaki canlı girdilerin tümünü action başlamadan doğrular:

- controller revision, merged O10.1 ancestry ve clean controller checkout;
- Issue #284 branch/checkpoint/tree/parent, exact commit dosyaları ve blob OID'leri;
- Issue #284 ve #305 gövde/kanıt yorumlarının frozen SHA-256 değerleri;
- focused lifecycle `55/55`, widget `63/63`, full Flutter `357/357`, analyze
  `0` ve build/artifact kanıtı;
- mevcut APK path/SHA/package/version/signer/checkpoint sözleşmesi;
- exact Flutter ve ADB executable provenance'i;
- exact 10-path Issue #284 cumulative completion allowlist'i;
- tablet, synthetic smoke ve Draft PR publish sözleşmesi.

Schema v2 authorization, bu Issue kanıt kümesini
`evidence_source_fingerprint` ile canonical payload'a bağlar. Reused test,
analyze ve build stage'leri ayrıca current source/tool/command/artifact
fingerprint'leriyle eşleşmeden atlanamaz.

İlk `--execute`, authorization'ı repository dışındaki runtime root'a exclusive
ve immutable olarak yazar. Sonraki aynı komut yeni authorization üretmez;
stored authorization fingerprint'ini ve workflow ledger'ını yükler. Böylece
completion docs veya publish sırasında worktree'nin beklenen biçimde değişmesi
bootstrap'ı yeni bir workflow sanmaz.

## Stage sırası

```text
reused lifecycle/widget/full/analyze/build
→ artifact verify
→ tablet preflight
→ data-preserving install
→ timed → all-day
→ all-day gün değişimi
→ same-day no-op
→ all-day → timed
→ notification/binding visibility
→ cold relaunch persistence
→ recoverable cleanup
→ completion docs
→ ordinary commit
→ normal push
→ Draft PR
```

Tablet yoksa preflight `PAUSED_EXTERNAL(device_not_connected)` olur. Artifact
PASS'i projection'da korunur. Aynı komutla resume, başarılı test/build/artifact
stage'lerini tekrar çalıştırmadan current device stage'inden devam eder.

## Tablet ve veri guard'ları

Runner yalnız şu üçlüye izin verir:

- serial `R52W90JFN1M`;
- model `SM-X610`;
- package `com.faliardic.chiefsiteengineer.debug`.

Her target ADB argv'si exact tek `-s R52W90JFN1M` taşır ve `shell=False`
çalışır. Telefon, farklı model/package, shell composition, uninstall,
clear-data, downgrade, dosya silme ve hard-delete action öncesi reddedilir.

Sentetik başlık authorization fingerprint'inden deterministic
`CSE284_O10_<12-hex>` olarak üretilir. Adapter yalnız bu exact başlığı açar;
match count `1` değilse başka karta geçmez. Cleanup yalnız detail'deki
`Sil → Sil` recoverable yolunu ve sonrasında `Geri yükle` görünürlüğünü kabul
eder. UI hierarchy raw metni, stdout, ledger veya Issue evidence'a yazılmaz.

## Test ve canlı yürütme ayrımı

Issue #305 implementation kabulünde production adapter çağrılmaz. Focused
testler in-memory fake adapter ile bütün smoke state machine'ini, device
yokluğu pause'unu, her smoke stage'i sonrası crash/resume'u ve negatif guard'ları
doğrular. Gerçek build/install/ADB/tablet smoke, yalnız bu PR merged olduktan
sonra yeni bootstrap komutuyla Issue #284 workflow'unda yürütülür.
