# Issue #439 Task — V2.4 final karakterizasyon ve kapanış

## Yürütme bağlamı

- Resmî repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- İzole linked worktree: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\CSE-Worktrees\\issue-439`
- Exact base/master: `3b4bc86cd407c6417f9c6cb67ffd33d660ca5fcd`
- Branch: `codex/issue-439-v2-4-final-closure`
- Scope normalizasyonu: `#issuecomment-5271010434`
- Linked-worktree ve yayın yetkisi: `#issuecomment-5271040618`
- Model: current session-selected full Codex model
- Reasoning: `Extra High`
- Seçim nedeni: 15 kapanış ölçütünün üç V2.4 Slice'ı, V2.3 attachment
  temeli ve mevcut executable kanıtlarla fail-closed eşlenmesi gerekir.

Resmî checkout kullanıcıya ait dört tracked değişiklik, tüm untracked içerik,
`device-backups/`, `reports/` ve ZIP dahil korunur. Bu checkout üzerinde branch
switch, stash, reset, clean, checkout, restore, overwrite, delete veya edit
yapılmaz.

## Validation sözleşmesi

- Validation class: `domain`
- Changed contracts: yeni runtime/production sözleşmesi yoktur; bu görev yalnız
  mevcut V2.4 davranışını karakterize eder ve kapanış kanıtını kaydeder.
- Evidence-first: her kapanış ölçütü önce mevcut test adı/assertionı ve birleşmiş
  Slice kanıtıyla eşlenir. Yalnız gerçek bir executable boşluk bulunursa izinli
  test dosyasında dar karakterizasyon testi değerlendirilebilir.
- Production guard: `mobile/lib/**` değişmez. Gerçek production boşluğu
  bulunursa edit yapılmadan stop-and-report uygulanır ve ayrı correction Issue
  istenir.
- Focused validation:
  - `mobile/test/agenda_application_test.dart`
  - `mobile/test/mobile_agenda_widget_test.dart`
  - `mobile/test/reminder_widget_test.dart`
  - `mobile/test/app_database_test.dart`
- Final broad gates, final revision üzerinde bir kez:
  - full `flutter test --no-pub`;
  - `flutter analyze --no-pub`;
  - `git diff --check`;
  - exact allowlist/protected-path kontrolü;
  - schema/dependency/Backup-format/permission/platform diff sınıflandırması.
- Minimum physical-device acceptance: yeni runtime davranışı olmadığı için yok;
  Slice 1 ve Slice 3 birleşmiş cihaz/manual kanıtları yeniden kullanılır.
- Retry budget: 1 primary run, en fazla 1 blocking correction; exact fix
  sonrasında aynı başarısız işlem için en fazla 1 retry.
- Time budget: hedef 30–45 dakika, hard stop 75 dakikadır.

## Yetkili dosyalar

Evidence/docs:

- `.cse/tasks/439_task.md`
- `.cse/results/439_result.md`
- `docs/project_decisions.md`
- `ROADMAP.md`
- repository convention gerçekten gerektirirse `CHANGELOG.md`
- uygun ise dar `learning/439_*`

Yalnız gerçek test boşluğu kanıtlanırsa:

- `mobile/test/agenda_application_test.dart`
- `mobile/test/mobile_agenda_widget_test.dart`
- `mobile/test/reminder_widget_test.dart`
- `mobile/test/app_database_test.dart`

Başka hiçbir production, test, dependency, platform, permission, schema,
migration, backup-format veya release dosyası yetkili değildir.

## Yeniden kullanılacak birleşmiş kanıtlar

- Slice 1: Issue `#432` / PR `#433` / merge
  `f7eb942b6ac40665cf137b2fc23627f5feec5533`.
- Slice 2: Issue `#434` / PR `#435` / merge
  `e9cadce44ffcf27c73ce616dfde1f870168d8044`.
- Slice 3: Issue `#437` / PR `#438` / merge
  `3b4bc86cd407c6417f9c6cb67ffd33d660ca5fcd`.
- V2.3 attachment/schema/backup temeli: Issue `#420` / PR `#430` / merge
  `d80d24462b700ccc06af02889f6fe429b8d7fb5f`.

Schema 13, Backup format 1, attachment restore, signing, notification,
permission ve platform sözleşmeleri ilgili alanlar değişmediği sürece yeniden
çalıştırılmaz; mevcut merged kanıt ve final diff sınıflandırması kullanılır.

## Uygulanacak iş

1. On beş kapanış ölçütünü mevcut executable test ve merged evidence ile eşle.
2. Gerçek boşluk yoksa production/test dosyası değiştirmeden factual result
   artifactını oluştur.
3. Teknik kapanış kararını `docs/project_decisions.md` içinde kaydet.
4. `ROADMAP.md` üzerinde kapanış PR'ının durumunu gerçeğe uygun göster; PR merge
   edilmeden Epic `#385` V2.4 checkboxını kapatma ve V2.5 yönünü başlatma.
5. Focused gate ile final broad gate'leri bütçe içinde tamamla.
6. Intentional commit, normal push ve Draft PR ile yayınla.

## Stop ve yayın kuralları

Production davranış boşluğu, allowlist dışı edit ihtiyacı, schema/dependency/
backup-format/permission/platform değişikliği, kapanış ölçütü kanıtlanamaması,
final gate failure veya gerçek kullanıcı/device verisine erişim ihtiyacı halinde
fail-closed dur.

Intentional commit, normal push ve `Closes #439` içeren Draft PR yetkilidir. PR
Ready yalnız source/evidence review sonrasında; merge yalnız proje sahibinin açık
talimatıyla mümkündür. Closure PR merge edilmeden Epic `#385` V2.4 tamamlandı
olarak işaretlenmez ve V2.5 current direction yapılmaz. Force push ve branch
deletion yasaktır.
