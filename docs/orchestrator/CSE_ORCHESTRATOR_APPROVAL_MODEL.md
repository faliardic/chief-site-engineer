# CSE Development Orchestrator Approval Modeli

## 1. Amaç

Approval modeli, bir Orchestrator action'ının kim tarafından, hangi source ve
scope için, kaç kez ve ne zamana kadar yetkilendirildiğini deterministik olarak
kanıtlar. Approval; genel güven, sohbet niyeti veya önceki PASS değildir.

Orchestrator approval oluşturamaz, genişletemez veya Fatih adına onay veremez.

## 2. Geçiş dönemi

Issue #285 O0 docs run'ı, machine-readable schema henüz uygulanmadığı için exact
insan-okur execution comment `5152282818` ile yetkilidir. Bu istisna yalnız O0
geçişidir. O1 ve sonraki fazlar canonical payload ve fingerprint contract'ını
uygulamalıdır.

## 3. Approval seviyeleri

| Seviye | Yetkilendirdiği sınır |
| --- | --- |
| `SAFE_READ` | Exact repo/Git/GitHub metadata ve yetkili tracked source okuması |
| `CODE_CHANGE` | Exact allowlist içinde docs/source edit ve bounded Codex action'ı |
| `CORRECTION` | Kayıtlı tek failure için exact düzeltme ve bounded retry |
| `FULL_VALIDATION` | Issue'nun açıkça istediği geniş gate |
| `CHECKPOINT_COMMIT` | Exact validated tree için ordinary local commit |
| `BUILD` | Exact checkpoint'ten belirtilen artifact invocation'ı |
| `DEVICE` | Exact artifact, serial, package ve sentetik smoke |
| `PUBLISH` | Exact branch/commit için bounded push veya Draft PR action'ı |
| `MERGE` | Exact PR/head/base için mekanik merge action'ı |
| `RELEASE` | Exact artifact/version/channel için release action'ı |

Alt seviye approval üst seviye action'ı kapsamaz. Örneğin `CODE_CHANGE`, commit
veya build izni değildir; `PUBLISH`, merge veya release kararı değildir.

## 4. Fatih onayı zorunlu action'lar

- Source veya docs değişikliği.
- Codex invocation.
- Correction ve retry.
- Full validation.
- Checkpoint commit.
- Artifact build.
- Cihaz seçimi, install veya smoke.
- Push, PR veya başka publish işlemi.
- Merge ve release.
- Scope, allowlist, target, base, capability veya budget genişlemesi.
- Fail-closed duruştan continuation.

Salt-okunur deterministic observer dahi current Issue'da `SAFE_READ` sınırı
olmadan protected veya geniş kaynak okuyamaz.

## 5. Canonical authorization payload

O1/O2 için önerilen asgari payload:

```json
{
  "schema_version": 1,
  "repository": "faliardic/chief-site-engineer",
  "issue": 285,
  "comment_id": 5152282818,
  "scope_version": 1,
  "approval_level": "CODE_CHANGE",
  "capability": "Code",
  "branch": "docs/issue-285-cse-orchestrator-o0-foundation",
  "base_sha": "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f",
  "head_sha": "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f",
  "tree_sha": "sha1:example",
  "action": "prepare-o0-docs",
  "read_allowlist": ["tracked:authorized-sources"],
  "write_allowlist": ["issue:exact-paths"],
  "budgets": {
    "primary_max": 1,
    "correction_max": 1,
    "hard_stop_seconds": 2700
  },
  "expires_at": "example-timestamp",
  "nonce": "example-nonce",
  "previous_state": "SCOPE_VALIDATED"
}
```

Örnek şema açıklamasıdır; Issue #285 comment'ini sonradan machine-readable
approval'a dönüştürmez.

## 6. One-time fingerprint

Fingerprint canonical payload'ın aşağıdaki bağlarını kapsar:

- repository ve Issue;
- stable comment ID ve canonical comment-content hash;
- scope version;
- approval level ve capability;
- branch, base, HEAD ve tree;
- exact action veya command fingerprint;
- read/write/action allowlist;
- target cihaz veya remote;
- invocation, retry ve time budget;
- expiry, nonce ve previous state.

Canonicalization:

1. Schema-valid alanlar normalize edilir.
2. Alan sırası ve encoding sabitlenir.
3. Bilinmeyen veya duplicate alan fail-closed reddedilir.
4. Canonical bytes üzerinden SHA-256 üretilir.
5. Fingerprint event store'a yazılır; raw secret payload'a girmez.

## 7. Latest-valid authorization

“En yeni yorum” tek başına yeterli değildir. Seçilen authorization:

- current Issue'a aittir;
- tanınan schema/version taşır;
- repository, branch, source ve action ile eşleşir;
- süresi dolmamıştır;
- consumption durumu uygun ve nonce benzersizdir;
- daha yeni geçerli yorum tarafından supersede edilmemiştir;
- Fatih'in açık yetki niyetini taşır.

Parse edilemeyen daha yeni yorum eski yetkiyi otomatik genişletmez. Açık iptal
veya supersession yorumu run'ı `CANCELLED` ya da `AWAITING_APPROVAL` durumuna
alabilir.

## 8. Consumption

- Approval action admission'ında tüketilir; sonuç beklenirken ikinci action
  başlatılamaz.
- Admission event'i ve budget artışı aynı logical transition'da tutulur.
- Tool wrapper action'ı gerçekten başlatmadıysa consumption kararı provenance
  ile verilir, tahmin edilmez.
- Tek approval aynı command için kör retry izni vermez.
- Correction yeni `CORRECTION` approval'ı ve yeni fingerprint gerektirir.

## 9. Expiry ve drift

Aşağıdaki değişikliklerden biri approval'ı `APPROVAL_EXPIRED` yapar:

- branch, base, HEAD veya tree drift'i;
- scope/allowlist değişikliği;
- action/command fingerprint değişikliği;
- capability veya target değişikliği;
- budget veya timeout genişlemesi;
- prerequisite evidence kaybı;
- expiry zamanının geçmesi;
- nonce consumption;
- superseding yorum.

Expiry otomatik rebase, fetch, retry veya scope normalization başlatmaz. Yeni
observation ve yeni Fatih approval'ı gerekir.

## 10. Approval ve evidence reuse ayrımı

Geçerli evidence reuse:

- değişmeyen contract için önceki PASS'i taşır;
- aynı source/blob/tree bağı ister;
- neden tekrar gate gerekmediğini açıklar.

Evidence reuse yeni action approval'ı değildir. Önceki test PASS'i commit,
build, device veya publish izni vermez.

## 11. Approval storage

Approval metadata önerilen runtime root altında tutulur:

```text
%LOCALAPPDATA%\CSE-Orchestrator\approvals\
```

Tutulabilecekler:

- fingerprint;
- comment ID ve canonical payload hash;
- state/source/action bağları;
- consumption/expiry eventleri;
- sanitized verifier sonucu.

Tutulamayacaklar:

- GitHub token;
- API key;
- signing secret;
- credential plaintext;
- gerçek kullanıcı içeriği.

Credential backend seçimi ayrı karardır; approval metadata bir credential
store değildir.

## 12. Capability transition approval'ı

Profile geçişleri implicit değildir:

```text
Code → CHECKPOINT_COMMIT → Build → Device → Publish → Merge → Release
```

Her ok yeni approval, source fingerprint ve budget admission gerektirir. Bir
profile'ın ambient credentials'ı sonraki profile taşınmaz.

## 13. Kalıcı insan kontrolü

Orchestrator hiçbir approval seviyesi altında şunları kendi kendine yapamaz:

- approval üretmek veya yorumlamak için scope uydurmak;
- ürün önceliği seçmek;
- gerçek kullanıcı verisi riskini kabul etmek;
- security gate bypass etmek;
- force-push/hard reset/clean kararı vermek;
- Fatih adına merge veya release'i kabul etmek.

Mekanik action gelecekte otomatikleştirilebilse bile kararın kaynağı Fatih'in
exact, current ve tek kullanımlık approval'ı olarak kalır.
