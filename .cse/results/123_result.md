# Issue #123 Sonucu — Restart Kabulü ve Resmî Sınır Stabilizasyonu

## Özet

Issue #123'ün izin verdiği tek acceptance testi exact Issue #122 sonrası SHA üzerinde çalıştırıldı. Test ilk çalıştırmada geçtiği için production Python, template, CSS veya test davranışında düzeltme gerekmedi. Bu sonuç restart kalıcılığı ve resmî backup/export sınırının dar kabul kanıtıdır; Issue #119'un tamamlandığı veya branch'in merge-ready olduğu anlamına gelmez.

## Başlangıç durumu

```text
branch = codex/issue-119-first-testable-pc-field-tracking-ui
starting HEAD = 79a6cd7e77b598c593c246356a910e5df25ee795
starting origin branch = 79a6cd7e77b598c593c246356a910e5df25ee795
starting remote divergence = 0 0
tracked/staged worktree = clean
```

Untracked `reports/` kullanıcı dosyaları korunmuş ve kapsam dışında bırakılmıştır.

## Acceptance test kanıtı

Çalıştırılan tek pytest komutu:

```powershell
python -m pytest -rs `
  tests/test_field_tracking_web.py::test_first_pc_acceptance_flow_survives_restart_and_keeps_export_scope
```

Sonuç:

```text
1 passed in 0.70s
```

## Doğrulanan dar kabul akışı

- proje oluşturma;
- hızlı follow-up yakalama, düzenleme, proje atama ve planlama;
- waiting, complete ve reopen yaşam döngüsü;
- rutin oluşturma ve `/today` ile idempotent occurrence üretimi;
- occurrence sonuçlandırma;
- uygulama nesnesini aynı data root ile yeniden oluşturma;
- follow-up revision ve event history'nin aynı SQLite dosyasından okunması;
- routine occurrence status, outcome ve history'nin korunması;
- observation oluşturma ve detail route'unun çalışması;
- backup oluşturma ve indirme;
- resmî günlük export'un çalışması;
- observation metninin export'ta bulunması;
- follow-up capture text'i ile routine başlığının export'a sızmaması.

## Uygulama kararı

Acceptance testi ilk çalıştırmada geçti. Bu nedenle izin verilen production veya test yüzeylerinde kod değişikliği yapılmadı; çalışan WIP davranışı yeniden yazılmadı. Yalnız Issue #123 task ve result kanıt dosyaları eklendi.

## Kapsam sınırı

- Full pytest çalıştırılmadı.
- Yeni feature veya geniş refactor yapılmadı.
- Domain, application, persistence, operations, requirements ve workflow dosyalarına dokunulmadı.
- Gerçek kullanıcı data root'una erişilmedi; test yalnız pytest temporary data root kullandı.
- PR açılmadı; merge veya branch silme işlemi yapılmadı.

## Yayın durumu

Final commit SHA, son doğrulama sonuçları ve remote divergence bilgisi metadata churn oluşturmamak için Issue #119 ve Issue #123 factual evidence yorumlarında kaydedilir.
