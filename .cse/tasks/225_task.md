# Step 225 Task - Podcast 035 Note Summary Contract

## Yetkili kaynaklar

- GitHub Issue: `#67`
- Resmi yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `68c00edab667bbfd0467f4684921c0f6b453d4a7`
- Calisma branch'i: `step-225-podcast-035-note-summary-contract`

## Model ve reasoning secimi

- Codex model: `GPT-5.6 Sol`
- Reasoning seviyesi: `Extra High`
- Secim nedeni: Strict podcast-note validation contract degisiyor; executable regressions, cok buyuk self-contained historical note, deterministic generated outputs ve multi-file canonical state guncellemesi gerekiyor.

## Amac

Podcast 035'i Steps 221-225 icin olustur ve yeni podcast notunun kendi icinde Steps 001-220 icin ayri historical summary bulundurmasini executable contract ile zorunlu kil.

## Yetkili dosyalar

Olustur:

- `docs/podcast_notes/035_adim_221_225_notebooklm_podcast_notu.md`
- `.cse/tasks/225_task.md`
- `.cse/results/225_result.md`
- `learning/225_podcast_035_note_summary_contract.md`

Degistir:

- `scripts/build_notebooklm_podcast_source.py`
- `tests/test_notebooklm_podcast_source.py`
- `docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md`
- `docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json`

Gerektigi kadar guncelle:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/podcast_notes/README.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `learning/GLOSSARY.md`

## Podcast 035 contract'i

- Dosya `035_adim_221_225_notebooklm_podcast_notu.md` olur.
- Yeni 12 bolumlu strict note structure eksiksiz kullanilir.
- Guncel donem Step 221, 222, 223, 224 ve active Step 225'i factual olarak anlatir.
- Section 6 icinde Steps 001-220 her biri tam bir kez, ascending order ve ayri `### Adim NNN - ...` basligi ile yer alir.
- Documentation-only, production-code/test, podcast ve protocol adimlari ayirt edilir.
- Completed historical adimlar active work gibi yazilmaz; invented content eklenmez.

## Validation contract'i

- Podcast 035 ve sonrasi icin previous-summary section siniri bulunur.
- `001` ile `note.step_start - 1` arasindaki heading'ler exactly once ve ascending order zorunludur.
- Missing, duplicate, out-of-order veya section-disindaki heading clear `PodcastSourceError` verir.
- Current-range heading'leri previous-summary section icinde zorunlu degildir.
- Podcast 034 ve onceki legacy compatibility korunur.
- UTF-8, determinism ve historical note immutability korunur.

## Dogrulama

- `python -m pytest tests/test_notebooklm_podcast_source.py`
- `python -m pytest`
- `python -m json.tool docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json`
- `python -m json.tool .cse/state/project_state.json`
- `git diff --check`
- Podcast 035 previous-summary section: 220 unique ascending heading.
- Rolling source: 224 cumulative canonical heading.
- Manifest summary count: 224.
- Generator rerun: byte-identical source ve manifest.
- Podcast 034 hash unchanged.
- Protected production/workflow diff empty.
- `exports/` yalniz `.gitkeep`; ignored ZIP untouched.

## Yasak kapsam

- Main CSE production model/repository degisikligi yok.
- Physical attachment operation veya product persistence/database yok.
- Product API/GUI/CLI/PWA/offline sync yok.
- NotebookLM API/browser/credential/upload/Audio Overview automation yok.
- Workflow/GitHub Actions degisikligi yok.
- Generated `blocked`, ZIP/Desktop archive/historical podcast mutation yok.
- Step 226 baslatilmaz.

## Git yetkisi

- Tek commit: `Add podcast 035 and enforce note summary contract`
- Branch origin'e push edilir.
- Issue #67'ye factual completion evidence eklenir.
- Force push, PR, merge veya branch deletion yoktur.

## Post-merge notu

Bu branch daha sonra merge edilirse resmi yerel `master`, sonraki Codex-required calismanin basinda `--ff-only` ile senkronlanir.
