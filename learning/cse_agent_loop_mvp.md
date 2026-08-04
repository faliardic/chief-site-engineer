# CSE Agent Loop MVP — öğrenme notu

## Problem

Yerel CSE Bridge, Codex'in zaten sağladığı ajan çalışma döngüsünü özel Responses
API araçlarıyla yeniden kurmaya çalıştı. Bu yaklaşım; yerel scheduler, özel HTTP
istemcisi, tool şemaları, worktree yönetimi ve hata protokollerini tek seferde
kritik yolun parçası yaptı.

## Karar

İlk çalışan sürüm GitHub-hosted olacaktır:

- Codex uygulamayı `openai/codex-action@v1` ile yapar.
- Host, Issue allowlist'ini ve validation komutlarını deterministik olarak uygular.
- Ayrı bir ChatGPT API çağrısı diff ve test kanıtını inceler.
- ChatGPT değişiklik isterse aynı Draft PR üzerinde bir Codex düzeltme turu çalışır.
- Otomatik merge yapılmaz; son terminal çıktı `READY_FOR_FATIH`, `NEEDS_HUMAN` veya `FAILED` olur.

## Neden

Bu tasarım yerel Kaspersky, Windows Schannel ve Scheduled Task yolunu kritik akıştan
çıkarır. GitHub Issue ortak mesaj kuyruğu; Draft PR ortak çalışma artefaktı olur.
Kullanıcı tek onay verir ve ancak terminal sonuçta tekrar devreye girer.

## Sınır

MVP bir ilk uygulama ve en fazla bir düzeltme turu içerir. Daha fazla tur,
resume/reconciliation ve maliyet telemetrisi ilk gerçek kabul çalışmasından sonra
eklenir.
