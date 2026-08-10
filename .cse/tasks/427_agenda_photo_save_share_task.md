# Issue #427 — Ajanda fotoğrafını cihaza kaydetme ve paylaşma

## Yürütme kimliği

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Yetkili temiz linked worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-427-agenda-photo-save-share`
- Expected base/master SHA: `56e5781816a106642a02d3a9a0630c7bd7195dbc`
- Branch: `codex/issue-427-agenda-photo-save-share`
- Codex modeli: `Codex / GPT-5` full model
- Reasoning: `Extra High`
- Seçim nedeni: Kullanıcıya ait dış dosya üretimi, sistem paylaşım akışı, managed attachment integrity kapısı ve non-destructive lifecycle birlikte değişmektedir.

## Validation class

`domain`

## Amaç

Ajanda Log içindeki tek bir JPEG/PNG fotoğrafın tam ekran görüntüleyicisinde:

- integrity doğrulanmış byte'ları kalıcı kullanıcı kopyası olarak cihaza kaydetmek;
- integrity doğrulanmış byte'ları güvenli dosya adı ve doğru MIME ile sistem share sheet üzerinden paylaşmak.

## Değişen sözleşmeler

- Full-screen Ajanda fotoğraf viewer'ı `Cihaza kaydet / İndir` ve `Paylaş` eylemleri kazanır.
- Save yalnız doğrulanmış byte'lardan uygulama dışı kullanıcı kopyası üretir.
- Share yalnız doğrulanmış byte'ları doğru MIME ve güvenli/orijinal dosya adıyla paylaşır.
- Cancel normal no-op'tur; kaynak kayıt değişmez ve hata gibi gösterilmez.
- Missing/hash/MIME/path/unsafe/tampered fotoğraf platform save/share çağrısından önce fail-closed olur.

## Korunan sözleşmeler

- Mobile schema `13` ve Backup format `1` değişmez.
- `pubspec.yaml`, lockfile, Android/iOS manifest, permission ve platform config değişmez.
- Yeni storage/media permission veya dependency eklenmez.
- Managed attachment path/byte/hash, attachment/link/revision/event/database state değişmez.
- Gerçek kullanıcı DB, backup, report veya attachment root'u inspect/mutate edilmez.

## Yetkili dosyalar

Production:

- `mobile/lib/platform/agenda_photo_export_gateway.dart` (new)
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/bootstrap/app_bootstrap.dart`
- `mobile/lib/features/agenda/agenda_photo_viewer_page.dart`
- yalnız wiring gerekirse `mobile/lib/features/agenda/log_detail_page.dart`

Tests:

- `mobile/test/agenda_photo_export_gateway_test.dart` (new)
- `mobile/test/agenda_application_test.dart`
- `mobile/test/app_bootstrap_test.dart`
- `mobile/test/mobile_agenda_widget_test.dart` veya dar yeni viewer widget testi

Evidence/docs:

- `.cse/tasks/427_agenda_photo_save_share_task.md`
- `.cse/results/427_agenda_photo_save_share_result.md`
- `docs/project_decisions.md`

Allowlist dışı production edit başlamadan Issue #427'ye exact gerekçe yazılmalıdır.

## Focused validation

- Gateway: exact byte, MIME/filename, unsafe basename sanitize, cancel/no-op ve platform-error mapping.
- Application: sağlıklı JPEG/PNG başarı; missing/tampered/unsafe fail-closed; source state no-mutation.
- Bootstrap wiring.
- Viewer/widget: iki eylem, progress/success/error/cancel dili ve mevcut zoom/viewer regresyonu.

## İzin verilen broad gates

- Final source revision üzerinde bir kez `flutter test --no-pub`.
- `flutter analyze --no-pub`.
- `git diff --check` ve exact allowlist/protected-path kontrolü.
- Bir kez `flutter build apk --debug --no-pub`.
- Tam olarak bir authorized cihaz bağlıysa yalnız data-preserving `adb install -r` + launch smoke.

Release/AAB, signing, ARM64/16 KiB, background/reboot, backup/restore tatbikatı ve full Python repository suite çalıştırılmaz.

## Yeniden kullanılan kanıt

- PR #425 / merge `56e5781816a106642a02d3a9a0630c7bd7195dbc`: schema 13, Backup format 1, dependency/manifest/permission baseline ve V2.3 managed attachment integrity/read davranışı.
- Geçerlilik nedeni: Issue #427 bu sözleşmeleri değiştirmez.

## Minimum fiziksel cihaz kabulü

- Codex yalnız authorized install/launch smoke yapabilir.
- Source review sonrasında sağlıklı JPEG/PNG save/share, cancel, fail-closed hata ve no-mutation davranışı owner tarafından ChatGPT adımlarıyla manuel doğrulanır.

## Bütçeler

- Primary run: `1`
- Blocking correction: en fazla `1`
- Aynı başarısız operasyon: exact fix sonrası en fazla `1` retry
- Hedef süre: `30–45 dakika`
- Hard stop: `75 dakika`

## Açık kapsam dışı

- Issue #420 closure işi ve V2.3 acceptance değişikliği.
- Beton veya Dosya Kataloğu export/share.
- Çoklu fotoğraf, ZIP, edit/crop/compress/watermark.
- Issue #424 ve #426 backlog davranışları.
- AI/Bridge/Orchestrator/API.
- Dependency, permission, manifest, schema veya Backup format değişikliği.

## Stop conditions

- Mevcut dependency/system flow ile kalıcı dış kopya üretilemezse.
- Dependency, permission, manifest/platform config, schema veya Backup format değişikliği gerekirse.
- Managed source veya attachment/link/revision/event state mutation gerekirse.
- Allowlist dışı production edit gerekirse ve Issue'ya önceden exact gerekçe yazılmamışsa.
- Gerçek kullanıcı verisi inspection/mutation, uninstall, clear-data veya destructive cihaz işlemi gerekirse.
- Retry veya 75 dakika hard-stop bütçesi dolarsa.

## GitHub yetkileri

- Intentional commit ve normal push: yetkili.
- Completion evidence'i Issue #427'ye yazmak: yetkili.
- Draft PR: bu yürütmede Codex tarafından açılmayacak; source review sonrası ChatGPT yönetir.
- Ready/merge/branch delete/force-push: yetkisiz.
- Post-merge sync: bu yürütmenin kapsamında değil.
