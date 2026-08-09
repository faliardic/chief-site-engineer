# Issue #405 — Completion evidence

- Linked worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-405`
- Branch: `codex/issue-405-v2-1g-migration-backup-field-acceptance`
- Exact base: `7d7e824a1c351f81338ba9c437940920c20a3542`
- Validation class: persistence + backup/restore + field acceptance.
- Production source change: yok; validation/evidence-only kapanış.

## Executable acceptance

- Schema 10→11 legacy row/ID/text/revision/event/attachment snapshot korunumu doğrulandı.
- Fresh ve upgraded schema 11 için ilgili table/index/trigger ve `location_id` kolon tanımları eşdeğer doğrulandı.
- Upgrade sonrasında Agenda/Reminder/Concrete cross-project stable Mahal trigger'ları fail-closed doğrulandı.
- Format-1 backup/restore round-trip; archived project, parent/child/archived/renamed ProjectLocation, stable-linked ve legacy NULL-location Agenda/Reminder/Concrete kayıtları, historical snapshot textleri, Concrete block/floor/axis alanları, attachment byte'ları ve FK integrity ile doğrulandı.
- Schema bump, backup format bump, downgrade veya legacy canonicalization eklenmedi.

## Local validation

- Focused migration + backup/restore suites: PASS, 35/35.
- Representative Project lifecycle / ProjectLocation / Agenda / Reminder / Concrete stable-location regressions: PASS, 31/31.
- Managed Agenda/Reminder propagation representative testleri: PASS.
- `git diff --check`: PASS.
- Debug APK build: PASS.
- APK SHA-256: `109AF14F3E0AAB4FA9330AEF7C43D2707DC3477C0FE168E0262F5D012223EFE1`.
- Production source değişmediği için full Flutter suite ve full analyze çalıştırılmadı; minimum-sufficient validation uygulandı.

## Physical-device acceptance

- Exactly one authorized physical device: `R5CY21WKZFX` / `SM-S938B`; `ro.kernel.qemu=0`.
- Yalnız `adb install -r`: Success.
- Uygulama mevcut data ile açıldı; uninstall, clear-data veya restore yapılmadı.
- Kullanıcının read-only manual Proje/Mahal Kataloğu ve mevcut Agenda/Reminder/Concrete navigation kabulü `issuecomment-5230768028` ile PASS.
- Kullanıcı verisi okunmadı; kayıt veya Mahal mutation'ı yapılmadı.

## Safety / evidence reuse

- Schema 11 ve backup format 1 korunuyor.
- Production, release/signing/workflow, Puantaj, V2.2 ve Attachment V2 dosyaları değişmedi.
- Signing, AAB, ARM64/16 KiB, permission/privacy, background/reboot ve release kanıtları değişmeyen source sözleşmeleri nedeniyle yeniden kullanıldı.
- Original dirty worktree ve kullanıcı backup/report/device-backups alanlarına mutation yapılmadı.
- İlk focused test çağrısı eksik ignored package config nedeniyle test başlamadan durdu; cached/offline dependency metadata kurulumundan sonra aynı operation tek retry'da PASS oldu. Tracked lockfile değişmedi.
- PATH'te `dart` bulunmayan ilk format çağrısı, mevcut Flutter SDK içindeki exact Dart executable ile tek retry'da PASS oldu.

Final commit SHA, remote divergence ve Draft PR bağlantısı publication sonrasında Issue #405 yorumunda kaydedilir.
