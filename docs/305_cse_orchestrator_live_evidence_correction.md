# Issue #305 — Canlı workflow evidence taşıma düzeltmesi

## Problem

O10.1 bootstrap, GitHub Issue gövdesi ve seçili yorumları doğrudan UTF-8 metin
hash'iyle doğruluyordu. Aynı Markdown; GitHub, terminal veya JSON adapter'ı
arasında BOM, `LF`/`CRLF`/`CR` ya da terminal newline temsili değiştiğinde
semantik içerik aynı olsa bile farklı byte dizisi üretebiliyordu.

Canlı hash-only diagnostic, Issue #284 ve #305 gövdeleri ile seçili altı yorumun
current içerik hashlerinin frozen kayıtlarla eşit olduğunu kanıtladı. Raw içerik
loglanmadı. Bu nedenle blocker gerçek semantik drift değil, transport temsil
farkıdır.

## Canonical Markdown sözleşmesi

`canonical_markdown_bytes(value)` yalnız şu transport farklarını canonicalize
eder:

1. metnin başındaki tek UTF-8 BOM kaldırılır;
2. `CRLF` ve tek `CR`, `LF` olur;
3. terminal newline tam bir `LF` olarak temsil edilir.

İç whitespace, kelime, sayı, link, başlık veya karakter değiştirilmez. Tek
karakter ve iç-whitespace değişiklikleri farklı SHA-256 üretir ve bootstrap
action başlamadan fail-closed durur.

Bootstrap'ın evidence GET adapter'ı `gh api` stdout/stderr'ini explicit strict
UTF-8 ile ve yalnız allowlisted GET argv'siyle okur. Böylece Windows locale'i
Türkçe Markdown byte'larını içerik doğrulamasından önce bozamaz.

## Kaynak-belirgin blocker

Drift reason artık hangi source'un eşleşmediğini taşır:

```text
evidence_issue_body_drift_284
evidence_issue_body_drift_305
evidence_comment_drift_<issue>_<comment>
```

Raw Issue/comment içeriği authorization, diagnostic veya completion evidence'a
yazılmaz. Fingerprint yalnız canonical SHA-256 değerlerini taşır.

## Kapsam sınırı

Bu correction yalnız orchestrator evidence doğrulamasıdır. Issue #284 target ve
runtime state'i, product/mobile source, APK, build, install, ADB ve cihaz smoke
akışı değiştirilmez veya çalıştırılmaz.
