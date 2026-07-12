# Step 224 Task - Rolling NotebookLM Podcast Source Protocol

## Yetkili kaynaklar

- GitHub Issue: `#64`
- Yetkili execution baseline yorumu: `Step 224 execution baseline - resolved after Step 223 merge`
- Resmi yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `932dbf3ffd076ddc124825adce78226d2ce8fb57`
- Calisma branch'i: `step-224-notebooklm-rolling-podcast-source`

## Model ve reasoning secimi

- Codex model: Kullanici Codex secicisinde bulunan en guclu tam Codex modeli; Spark, fast veya lightweight varyant kullanilmaz.
- Reasoning seviyesi: `extra high`
- Secim nedeni: Bu adim deterministik generator, birikimli adim gecmisi, manifest tutarliligi, UTF-8 korumasi, hata sozlesmeleri ve cok dosyali regression testleri tanimlar.

## Amac

NotebookLM icin her podcastte yeniden kaynak ve talimat ekleme ihtiyacini kaldiran iki kalici sozlesme kur:

1. Degismeyen yoldaki permanent NotebookLM instruction dosyasi.
2. En guncel podcast notunu ve canonical proje gercegini deterministik olarak birlestiren rolling website source.

## Yetkili dosyalar

Olustur:

- `docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md`
- `docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md`
- `docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json`
- `scripts/build_notebooklm_podcast_source.py`
- `tests/test_notebooklm_podcast_source.py`
- `.cse/tasks/224_task.md`
- `.cse/results/224_result.md`
- `learning/224_notebooklm_rolling_podcast_source_protocol.md`

Gerektigi kadar guncelle:

- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `docs/podcast_notes/README.md`
- `.cse/state/project_state.json`
- `learning/GLOSSARY.md`

## Uygulama sozlesmesi

- Generator en yuksek numarali podcast notunu bulur, podcast numarasini ve adim araligini dosya adindan dogrular.
- Permanent instruction metnini rolling source'un en ustune ekler.
- Latest podcast notunu tam olarak ekler.
- Canonical tracked kaynaklardan mevcut her teknik adim icin ayri ve kisa bir ozet uretir.
- Safe point, test kaniti, deferred kapsam ve generation metadata bolumlerini ekler.
- Manifesti repository truth ile uyumlu ve deterministik olarak gunceller.
- UTF-8 Turkce karakterleri korur; network kullanmaz.
- Eksik instruction/not, hatali dosya adi veya aralik, duplicate latest numara ve eksik required note section durumlarinda acik hata verir.
- Tarihsel podcast notlarini, `exports/` klasorunu, ZIP'i veya repository disi dosyalari degistirmez.
- Stable public URL olarak GitHub `master` raw URL'si belgelenir; NotebookLM'in saved website source'u otomatik yeniledigi iddia edilmez.
- Model secimi politikasi canonical proje talimatlarina ve state'e eklenir.

## Test ve kalite dogrulamalari

- `python -m pytest tests/test_notebooklm_podcast_source.py`
- `python -m pytest`
- `python -m json.tool docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json`
- `python -m json.tool .cse/state/project_state.json`
- Generator ikinci kez calistirildiginda rolling source ve manifest degismemeli.
- `git diff --check`
- Protected path diff kontrolu
- `exports/` yalniz `.gitkeep`
- Ignored ZIP mevcut, ayni hash'te ve degistirilmemis
- Podcast 035 olusturulmamali

## Yasak kapsam

- NotebookLM API, browser automation, credential veya Google account secret eklenmez.
- Audio Overview otomasyonu veya NotebookLM upload islemi eklenmez.
- Hidden network call, database, ana urune UI/API/CLI veya ilgisiz persistence eklenmez.
- GitHub Actions workflow degistirilmez.
- Historical podcast notlari degistirilmez.
- ZIP, Desktop archive veya `exports/` mutation yapilmaz.
- PR acilmaz ve merge yapilmaz.

## Git yetkisi

- Tek kapsamli commit: `Add rolling NotebookLM podcast source protocol`
- Branch origin'e push edilir.
- Issue #64'e factual completion evidence yorumu eklenir.
- PR ve merge yetkisi yoktur.

## Post-merge notu

Bu branch daha sonra merge edilirse resmi yerel `master`, sonraki Codex-required calismanin basinda `--ff-only` ile yeniden senkronlanir.
