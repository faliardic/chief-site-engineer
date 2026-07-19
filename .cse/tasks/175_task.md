# Issue 175 Task - Geriye Donuk Observation Create Contract

## Yerel yurutme baglami

- Resmi yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen base branch: `master`
- Beklenen base commit: `45dc4a6d473792d39b0cf1cfea7a5baa47c51c18`
- Calisma branch'i: `codex/issue-175-p1-02-backdated-observation-create-contract`
- GitHub Issue: `#175`
- Parent phase Epic: `#129`
- Parent execution Epic: `#127`
- Release Epic: `#176`

## Codex secimi

- Model: current selector'daki standart full Codex model
- Reasoning: High
- Secim nedeni: Issue #175'in acik yurutme sozlesmesi; dar application contract,
  deterministic zaman, attachment/event transaction guvenligi ve geriye uyumlu
  regresyon matrisi.

## Yetkili dosyalar

- `app/application/observations.py`
- `app/application/__init__.py`
- Mevcut cagri uyumlulugu gerekiyorsa `app/web/app.py` ve
  `app/acceptance/__main__.py`
- Observation create kullanan ilgili test dosyalari
- `tests/test_observation_application_service.py`
- `docs/175_backdated_observation_create_contract.md`
- `learning/175_backdated_observation_create_contract.md`
- Yeni kalici terim gerekiyorsa `learning/GLOSSARY.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/tasks/175_task.md`
- `.cse/results/175_result.md`
- `.cse/state/project_state.json`

## Yapilacak is

1. Observation create akisini immutable bir command value object ile calistir.
2. Command'a optional explicit `observed_at` ekle.
3. Omitted `observed_at` icin tek service clock degerini kullan.
4. Explicit `observed_at` degerini strict canonical UTC ve
   `TimestampRole.EVENT_TIME` future policy ile entry time'a gore dogrula.
5. Tek clock okumasini `created_at`, `updated_at`, created event `occurred_at`
   ve attachment metadata `created_at` icin kullan.
6. `FieldObservationRecord.observed_at` icinde gercek olay zamanini koru.
7. `observation_created` payload'inda `observed_at` ile `created_at` ayrimini;
   revision, status ve attachment ID'leriyle birlikte sakla.
8. Command/temporal validation'i attachment staging ve database mutation'dan
   once fail-closed tamamla.
9. Mevcut finalize, rollback ve reconciliation davranisini koru.
10. Mevcut web, acceptance ve CLI akislarini explicit olay zamani vermeden ayni
    kullanici davranisiyla calisir halde tut.

## Yasak kapsam

- Yeni web form alani, route, Ajanda UI veya `datetime-local` alani
- Schema version degisikligi, migration veya mevcut row rewrite
- Repository/database contract genisletmesi
- Archive/unarchive, scope veya MemoryIndex
- Mobile/offline, notification veya security implementation
- Backup/Gunluk Cikti wire format degisikligi
- Gercek `CSE_DATA_ROOT`, gercek Backup, attachment, log veya saha kaydi okuma
- Amend, rebase, force-push, PR acma veya merge

## Zorunlu executable test kapisi

- Explicit gecmis `observed_at` korunur.
- Omitted `observed_at` canonical now olur.
- `created_at == updated_at ==` tek clock okumasi.
- Event `occurred_at` entry time; payload olay/entry zamanini ayirir.
- Attachment `created_at` entry time olur.
- Future, naive, invalid ve noncanonical UTC reddedilir.
- Invalid command'da staging/database/event mutation olmaz.
- Event add ve commit failure rollback/reconciliation davranisi korunur.
- Restart sonrasinda olay ve entry zamanlari degismez.
- Observation, web, acceptance, Backup/Restore ve Gunluk Cikti regresyonlari.
- Full suite, compileall, state JSON ve `git diff --check`.

## Git izinleri

- Tek ordinary commit: `Add backdated observation create contract`
- Normal push: izinli
- PR acma: yasak; ChatGPT/GitHub inceleme akisi yapar
- Amend/rebase/force-push: yasak

## Post-merge sync

Issue #175 squash merge edildikten sonra, sonraki Codex gerektiren yerel isin
basinda `master` yeniden `--ff-only` ile senkronlanir. Bu task merge iddiasi
tasimaz.
