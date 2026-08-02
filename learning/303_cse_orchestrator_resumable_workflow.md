# Issue #303 Öğrenme — Kesintiden sonra aynı workflow nasıl sürer?

## Problem

O1-O9 doğru parçaları sağlıyordu; fakat parçaların arasındaki sıra hâlâ insanın
taşıdığı prompt'lara bağlıydı. Test PASS olduktan sonra build, device veya
publish kapısına geçmek için yeni talimat gerekiyordu. Bir device blocker'ında
hangi build'in korunacağı ve yeniden çağrıda nereden başlanacağı kalıcı tek bir
workflow gerçeğine bağlı değildi.

## Kurduğumuz akış

```text
Issue authorization
  → immutable WorkflowContract
  → workflow_started
  → target_observed
  → stage_admitted(attempt_id)
  → stage_passed | stage_reused | stage_paused | stage_failed
  → replayed projection/current_stage
  → workflow_completed
```

Manifest değişmez; JSONL event ledger append-only ve hash-chain'dir. Projection
bir karar kaynağı değil, eventlerin deterministic replay sonucudur. Bu ayrım
crash sonrası recovery'nin temelidir.

## Gerçek kod örneği

Coordinator bir stage'i çalıştırmadan önce attempt kimliğini source ve stage
contract'ına bağlar:

```python
attempt_id = _hash_mapping(
    {
        "workflow_id": self.contract.workflow_id,
        "stage": stage.name,
        "attempt": attempt,
        "source_fingerprint": live.source_fingerprint,
        "stage_fingerprint": stage_contract.stage_fingerprint,
    }
)
self.store.append(
    "stage_admitted",
    {
        "stage_index": projection.current_stage_index,
        "stage": stage.name,
        "attempt": attempt,
        "attempt_id": attempt_id,
        "stage_fingerprint": stage_contract.stage_fingerprint,
        "budget_counter": counter,
    },
)
```

Replay, aktif attempt kapanmadan yeni admission'ı ve geçmişte görülmüş attempt
ID'sini reddeder. Authorized retry aynı stage'i kullanır ama attempt sayısı,
kimliği ve budget tüketimi yenidir.

## Crash recovery neden güvenli?

Event append fsync edildikten sonra process, projection cache replace edilmeden
çökebilir. Sonraki `workflow-run`, immutable manifest ile ledger hash-chain'ini
doğrular ve cache'i ledger'dan yeniden üretir. Read-only `workflow-verify` ise
cache eksik/farklıysa bunu bildirir; kullanıcı salt-okunur komutla state'i
değiştirmez.

Şunu şöyle yaptık ki: projection cache'i otorite yapmadık ki cache silme veya
elle `COMPLETED` yazma workflow'u ileri taşımasın; fakat normal crash de güvenli
resume'u kalıcı olarak bloke etmesin.

## Artifact reuse

Artifact stage PASS sonucu projection'a path, SHA-256, package, version, signer
ve checkpoint bağını yazar. Device stage external blocker üretirse stage index
device'ta kalır. Resume başlangıcında projected artifact tekrar hashlenir.

Şunu şöyle yaptık ki: tablet bağlı değilken başarılı APK build'i yeniden
çalışmasın; fakat dosya değişmiş veya kaybolmuşsa eski PASS kanıtı da sessizce
kullanılmasın.

## Duplicate-safe publish

- Commit: HEAD beklenen base'ten ilerlemişse subject ve parent exact contract ile
  eşleştiğinde reuse edilir; farklı commit blocker'dır.
- Push: remote branch local HEAD'e eşitse reuse; farklı remote head blocker;
  branch yoksa tek normal push.
- Draft PR: exact head/base/title ile tek açık Draft PR varsa reuse; farklı veya
  birden fazla PR blocker; yoksa tek create.
- Issue evidence: workflow/stage marker'ı varsa ikinci comment yazılmaz.

Şunu şöyle yaptık ki: network cevabı kaybolduktan sonraki resume aynı mutation'ı
körlemesine tekrarlamasın.

## Testlerin amacı

`tests/test_cse_orchestrator_workflow.py` yalnız happy path'i doğrulamaz:

- üç farklı gate sonrasında evidence sink crash'i yaratır ve önceki gate'in
  yeniden çalışmadığını kanıtlar;
- device pause sonrası artifact'in korunduğunu, build'in çağrılmadığını ve
  artifact tamper'ında resume'un action öncesi durduğunu gösterir;
- ledger/projection/authorization tamper ve raw content redaction'ı sınar;
- commit/push/PR ikinci çağrılarının reuse olduğunu doğrular;
- disposable Git depolarıyla CLI run/status/verify zincirini uçtan uca yürütür.

## Teknik kararlar

- Workflow projection, mevcut action `State` modelinden ayrıdır; O1-O9
  davranışını kırmadan birden çok action'ı sıralar.
- Controller source root, target ve runtime aynı olamaz; import edilen package
  ile controller Git revision aynı checkout'a aittir.
- Environment variable değerleri kaydedilmez. Authorization yalnız aktarılmasına
  izin verilen adları taşır.
- Output kanıtı raw text değil hash + stable diagnostic alanlarıdır.
- Product/mobile, gerçek cihaz, merge ve release Issue #303 implementation
  run'ında çalıştırılmamıştır.
