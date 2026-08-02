# CSE Orchestrator O9 API kontrollü otomasyon

## Amaç

Issue #299, O1–O8 güvenlik oracle'ını kaldırmadan API ile plan üretme,
Codex child çalıştırma ve tek Draft PR oluşturma adapter'larını ekler. Model
çıktısı hiçbir zaman yetki değildir. Yerel policy kararı, exact allowlist,
capability, budget ve fingerprint'ler her dış eylemden önce yeniden doğrulanır.

```text
Issue sözleşmesi
→ O1–O8 observation/policy/provenance
→ Responses API structured proposal
→ strict local proposal validation
→ explicit Codex child gate
→ mevcut validation/checkpoint/publish gate'leri
→ explicit Draft PR gate
```

## OpenAI Responses API sınırı

`OpenAIResponsesClient` yalnız şu sözleşmeyle çalışır:

- endpoint `POST https://api.openai.com/v1/responses`;
- API key yalnız `OPENAI_API_KEY` environment değişkeninden;
- model yalnız `OPENAI_MODEL` environment değişkeninden;
- `store=false`;
- `text.format.type=json_schema`, `strict=true` ve
  `additionalProperties=false`;
- bounded prompt, timeout ve `max_output_tokens`;
- process başına tek request; retry katmanı yoktur.

Response evidence yalnız HTTP status, request/response ID, model ve token
count metadata'sıdır. Raw prompt, raw response ve authorization header public
result'a veya ledger'a girmez. Missing credential, refusal, incomplete output,
rate limit, timeout, HTTP error, malformed JSON veya schema uyumsuzluğu
fail-closed sonuçtur.

## Untrusted proposal doğrulaması

Structured proposal exact on alan taşır: `decision`, `risk`, `summary`,
`codex_prompt`, `write_allowlist`, `validation_commands`, `commit_message`,
`pr_title`, `pr_body_prefix` ve `required_approval_level`.

Yerel `ProposalContract` şu sınırları API çıktısından bağımsız tutar:

- capability: `Code + Network + Publish`;
- exact write allowlist ve validation command listesi;
- commit/PR metin sözleşmesi ve approval seviyesi;
- API request, Codex child ve Draft PR için `1/1/1` budget;
- source, contract ve action fingerprint'leri.

Unknown/missing alan, farklı sıralı allowlist, yeni komut, approval veya metin
drift'i reddedilir. Policy `allowed` değilse, state
`ACTION_AUTHORIZED` değilse veya budget delta exact değilse proposal child'a
ulaşmaz.

## Codex child adapter

Child yalnız read-only `codex exec --help` envanterinde stdin prompt biçimi
kanıtlanırsa exact `("codex", "exec", "-")` argv'sini kullanır. Cwd exact
repository root'tur; `shell=false`, timeout ve output limiti zorunludur.
Environment'ın yalnız allowlisted adları aktarılır.

Prompt repository dışındaki runtime root'ta permission-bounded geçici dosyada
tutulur, subprocess stdin'ine verilir ve invocation sonunda silinir. Prompt
secret pattern'i taşıyamaz. Aynı action fingerprint ikinci kez adapter'a
ulaşmadan reddedilir. Missing CLI, auth failure, timeout ve non-zero exit ayrı
veri-minimal status üretir.

Bu koşuda `codex exec --help` tek read-only denemede WindowsApps erişim hatası
verdiği için desteklenen argv canlı doğrulanamadı; child pilotu
`CLI_UNAVAILABLE` olarak kaldı ve retry yapılmadı.

## GitHub REST adapter

`GitHubRestClient` token'ı yalnız `GITHUB_TOKEN` environment değişkeninden
okur. Exact repository, branch, `master` base, local/remote head SHA,
divergence, Issue bağı ve `draft=true` doğrulanır. Adapter önce açık PR
varlığını GET ile kontrol eder ve yalnız bir `POST /repos/{owner}/{repo}/pulls`
mutasyonunu admit edebilir.

Head drift, remote divergence, existing PR veya duplicate invocation POST
öncesi fail-closed olur. Force-push, Ready, merge, Issue close, branch delete,
tag ve release bu adapter'ın action setinde yoktur. Normal push mevcut O8
controlled runner sözleşmesinde kalır.

## `api-run` CLI

Yeni top-level komut, exact JSON contract ile çalışır:

```text
python -m tools.cse_orchestrator.cli api-run \
  --contract <external-contract.json> \
  --repo-root <repository> \
  --runtime-root <external-runtime>
```

Flag verilmezse yalnız dry-run sonucu üretir. Dış sınırlar ayrı kapılardır:

- `--execute-api` tek Responses API request'ini;
- `--execute-codex` validated proposal için tek child'ı;
- `--execute-publish` exact Draft PR REST mutation'ını açar.

Sonraki kapı önceki kapı olmadan açılamaz. Production kullanımında focused ve
full validation, checkpoint commit ve normal push mevcut O5–O8 gate
sözleşmeleriyle ayrıca admit edilmelidir.

## Bu koşunun canlı pilot durumu

`OPENAI_API_KEY`, `OPENAI_MODEL` ve `GITHUB_TOKEN` adlarının değerleri
okunmadan yalnız presence kontrolü yapıldı ve üçü de mevcut değildi. Bu nedenle
gerçek API request, Codex child ve GitHub REST Draft PR mutation sayıları
`0/0/0` kaldı. Durum `CREDENTIALS_MISSING`; secret istenmedi veya üretilmedi.

## Bilinçli kapsam dışı

- Model tarafından authority, scope, capability, command veya budget üretimi;
- dependency, production/mobile, workflow, `.cse/state` veya
  `scripts/cse_status.py` değişikliği;
- build, ADB/device veya OpenAI/GitHub retry;
- Ready, merge, Issue close, branch delete, tag ve release.
