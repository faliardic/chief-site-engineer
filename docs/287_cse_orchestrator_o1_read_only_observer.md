# CSE Orchestrator O1 Read-Only Observer

## 1. Amaç ve sınır

O1, CSE geliştirme gerçeğini değiştirmeden gözleyen ilk executable
Orchestrator katmanıdır. Local Git, live GitHub ve exact CSE kayıt yollarından
deterministik, veri-minimal bir Observation v1 üretir.

O1 policy engine değildir. Approval tüketmez, action admission yapmaz, Codex
çalıştırmaz, fetch/commit/push yapmaz ve GitHub mutation endpoint'i içermez.
O2 state/policy engine ancak O1'in gözlem sözleşmesi ayrı bir Issue ile
doğrulandıktan sonra başlayabilir.

## 2. Observation v1

Minimum çıktı yapısı:

```json
{
  "schema_version": 1,
  "run_id": "opaque-run-id",
  "observed_at_utc": "2026-08-02T00:00:00Z",
  "repository": "faliardic/chief-site-engineer",
  "repo_root": "canonical-path",
  "issue": 287,
  "git": {
    "branch": "...",
    "head_sha": "...",
    "parent_sha": "...",
    "tree_sha": "...",
    "local_master_sha": "...",
    "origin_master_sha": "...",
    "remote_master_sha": "...",
    "staged": [],
    "tracked_worktree": [],
    "tracked_fingerprint": "sha256:..."
  },
  "github": {
    "issue_state": "open",
    "issue_updated_at": "...",
    "comment_count": 0,
    "comments_metadata_hash": "sha256:..."
  },
  "authorization": {
    "status": "valid|missing|invalid|expired",
    "comment_id": null,
    "payload_hash": null,
    "approval_level": null,
    "capability": null,
    "action": null,
    "reasons": []
  },
  "records": {
    "task": {},
    "result": {},
    "project_state": {}
  },
  "state": "OBSERVING|SCOPE_VALIDATED|PREFLIGHT_BLOCKED",
  "blockers": [],
  "exit_code": 0,
  "runtime_output_path": "..."
}
```

Raw command stdout/stderr, Issue body ve comment body bu yapıya girmez.

## 3. Canonicalization ve fingerprint girdileri

Canonical JSON:

- UTF-8 encode edilir;
- object key'leri lexicographic olarak sıralanır;
- fingerprint için ayırıcılar `,` ve `:` olup ek whitespace kullanılmaz;
- SHA-256 lowercase hex üretilir.

Authorization payload hash'i strict parsed payload'ın canonical JSON
byte'larından gelir. `tracked_fingerprint` şu exact girdilerin canonical
hash'idir:

```text
HEAD SHA
tree SHA
sorted staged name-status listesi
sorted tracked-worktree name-status listesi
```

GitHub comment metadata hash'i yalnız sorted `id`, `created_at` ve
`updated_at` alanlarını kapsar; body fingerprint girdisi değildir.

## 4. Git command sınırı

İzinli exact aileler:

- `git rev-parse` — root, HEAD, parent, tree, local/cached master;
- `git branch --show-current`;
- `git diff --name-status --cached`;
- `git diff --name-status`;
- `git remote get-url origin`;
- `git ls-remote --heads origin refs/heads/master`;
- `git ls-files --error-unmatch -- <exact-record-path>`;
- `git hash-object -- <exact-record-path>`.

Command guard; `fetch`, `pull`, `checkout`, `switch`, `reset`, `stash`,
`clean`, `add`, `commit`, `merge`, `rebase`, `cherry-pick`, `push`, `gc` ve
`prune` ailelerini subprocess başlamadan reddeder.

`git status --ignored --untracked-files=all`, repository-wide `rglob`, ZIP,
export veya cache taraması yoktur.

## 5. GitHub GET sınırı

Standard-library/subprocess adapter yalnız şu `gh api --method GET` yollarını
kullanır:

- repository metadata;
- exact current Issue;
- `per_page=100&page=N` ile paginated exact Issue comments.

Adapter'da POST/PATCH/DELETE veya Issue/PR comment/edit/close metodu yoktur.
Issue ve yorum body'leri yalnız authorization parser'ın iç girdisidir; output
assembler bunları atar.

## 6. Authorization v1 parser

Parser exact marker'ı arar:

```text
<!-- cse-orchestrator-authorization:v1 -->
```

Marker sonrasında tam bir `json` fence bulunmalıdır. Parser:

- `schema_version = 1` ister;
- unknown ve missing top-level/budget alanlarını reddeder;
- `object_pairs_hook` ile duplicate key'i parse anında reddeder;
- transport comment ID ile payload `comment_id` eşitliğini doğrular;
- branch/base/head/tree, capability, approval, action, allowlist ve budget
  alanlarının tür ve şekillerini doğrular;
- yalnız `Z` ile biten strict UTC expiry kabul eder;
- daha yeni authorization'ı yalnız schema-valid ve active comment'e açık
  `supersedes_comment_id` bağı taşıyorsa seçer;
- ordinary veya invalid daha yeni yorumla yetki genişletmez.

Observation authorization bölümü body yerine yalnız status, comment ID,
payload hash, approval level, capability, action ve veri-minimal reason taşır.

## 7. Exact record gözlemi

Yalnız şu üç yol oluşturulur ve tek tek gözlenir:

```text
.cse/tasks/<issue>_task.md
.cse/results/<issue>_result.md
.cse/state/project_state.json
```

Her kayıt için exact path, `exists`, `tracked`, `blob_hash` ve
`content_included: false` üretilir. Başka `.cse` klasörü listelenmez ve dosya
içeriği output'a alınmaz.

## 8. Blocker ve exit-code önceliği

| Öncelik | Blocker | Exit |
| ---: | --- | ---: |
| 1 | `USER_DATA_RISK` | `14` |
| 2 | `PROVENANCE_MISMATCH` | `13` |
| 3 | `APPROVAL_EXPIRED` veya invalid authorization | `12` |
| 4 | `SOURCE_FAILURE` | `11` |
| 5 | `STATE_DRIFT` | `10` |
| 6 | Temiz `OBSERVING` / `SCOPE_VALIDATED` | `0` |
| 7 | CLI usage error | `2` |

Bütün blocker'lar listede kalır; en yüksek öncelik exit code'u belirler.
Valid authorization ve uyumlu source `SCOPE_VALIDATED`; authorization yokluğu
temiz `OBSERVING`; blocker varlığı `PREFLIGHT_BLOCKED` üretir.

## 9. Runtime root ve atomik write

Runtime root canonical repository ile aynı veya onun altında olamaz; bu durum
`USER_DATA_RISK` ve exit `14` üretir. Güvenli root örneği:

```text
%LOCALAPPDATA%\CSE-Orchestrator\runs\<run-id>\observation.json
```

Writer unique run klasörü oluşturur, JSON'u aynı klasörde temporary file'a
yazar, flush/fsync yapar ve `os.replace` ile atomik olarak görünür kılar.
Runtime write repository dosyası oluşturmaz veya değiştirmez.

## 10. Sanitization

Output yalnız ref, SHA/hash, exact path, durum, sayaç ve blocker reason gibi
veri-minimal alanları taşır. Aşağıdakiler tutulmaz:

- raw comment veya Issue body;
- raw subprocess stdout/stderr;
- secret, token veya credential;
- gerçek kullanıcı kaydı;
- ignored/untracked path listesi;
- `reports/`, `device-backups/`, `exports/`, ZIP/cache veya app-private data.

## 11. Kullanım

```powershell
python -m tools.cse_orchestrator.cli observe `
  --repo-root V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer `
  --repository faliardic/chief-site-engineer `
  --issue 287 `
  --runtime-root "$env:LOCALAPPDATA\CSE-Orchestrator"
```

Bu komutun gerçek Issue ile integration smoke'u, O1 primary CODE_CHANGE
yetkisinin parçası değildir. Live çalıştırma ayrı `FULL_VALIDATION` approval'ı
gerektirir.

## 12. O1/O2 ayrımı

O1 gerçekleri gözler ve authorization'ı sınıflandırır. O2 bu gözlemi policy
invariant'larıyla değerlendirip geçiş önerisi üretebilir. O1 approval tüketimi,
budget admission, action runner, append-only runtime event store veya otomatik
continuation eklemez.
