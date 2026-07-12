import hashlib
import json
import socket
from pathlib import Path

import pytest

from scripts.build_notebooklm_podcast_source import (
    PRIOR_STEP_HEADING_PATTERN,
    PodcastSourceError,
    _find_section_body,
    build_source,
    find_latest_podcast_note,
)


INSTRUCTION = "# Kalıcı Talimat\n\nTürkçe anlat; kaynakta olmayan davranışı uydurma.\n"
REPO_ROOT = Path(__file__).resolve().parents[1]


def _prior_step_summaries(*steps: int) -> str:
    return "\n\n".join(
        f"### Adım {step:03d} — Canonical adım {step:03d}\n"
        f"Tür: test özeti. Tamamlanmış adımdır. Adım {step:03d} doğrulandı."
        for step in steps
    )


def _strict_note(
    podcast: int,
    start: int,
    end: int,
    marker: str = "güncel",
    *,
    prior_steps: tuple[int, ...] = (),
    outside_prior_steps: tuple[int, ...] = (),
) -> str:
    prior_summaries = (
        _prior_step_summaries(*prior_steps)
        if prior_steps
        else "Bu aralık öncesinde canonical adım yoktur."
    )
    outside_summaries = _prior_step_summaries(*outside_prior_steps)
    return f"""# Podcast {podcast:03d} - Adım {start:03d}-{end:03d}

## 1. NotebookLM Kullanım Talimatı / Instruction Reference
Kalıcı talimatı uygula.

## 2. Notun Kapsamı
{marker} kapsam ve Türkçe karakterler: şantiye, güvenli, ölçüm.

## 3. Dönemin Ana Teması
Tema.

## 4. Güncel Adımların Ayrıntılı Anlatımı
Ayrıntı.
{outside_summaries}

## 5. Güncel Dönem Özeti
Özet.

## 6. Önceki Adımların Ayrı Ayrı Özeti
{prior_summaries}

## 7. Birikimli Ürün ve Teknik Durum
Durum.

## 8. Test ve Güvenli Nokta Kanıtı
3 passed.

## 9. Bilerek Ertelenenler
Database ertelendi.

## 10. Sonraki Doğal Yön
Sonraki yön.

## 11. NotebookLM Kısa Direktifi
Türkçe anlat.

## 12. Kapanış Sorusu ve Kısa Cevap
Soru ve cevap.
"""


def _legacy_note() -> str:
    return """# Podcast 034 - Adim 001-003 NotebookLM Podcast Notu

## 1. Donemin Ana Temasi
Tema.

## 2. Kisa Ozet
Ozet.

## 3. Adim Adim Gelisim
Gelisim.

## 4. Test Gelisimi
Test.

## 5. Bilerek Ertelenenler
Ertelenenler.

## 6. Sonraki Gelistirme Yonu
Yon.

## 7. NotebookLM'e Verilecek Kisa Direktif
Direktif.

## 8. Kapanis Sorusu ve Kisa Cevap
Cevap.
"""


def _write_repo(
    root: Path,
    *,
    notes: dict[str, str] | None = None,
    instruction: str | None = INSTRUCTION,
) -> Path:
    notebooklm_dir = root / "docs/notebooklm"
    notes_dir = root / "docs/podcast_notes"
    state_dir = root / ".cse/state"
    notebooklm_dir.mkdir(parents=True)
    notes_dir.mkdir(parents=True)
    state_dir.mkdir(parents=True)

    if instruction is not None:
        (notebooklm_dir / "NOTEBOOKLM_INSTRUCTIONS.md").write_text(
            instruction, encoding="utf-8"
        )
    if notes is None:
        notes = {
            "035_adim_001_003_notebooklm_podcast_notu.md": _strict_note(
                35, 1, 3
            )
        }
    for name, text in notes.items():
        (notes_dir / name).write_text(text, encoding="utf-8")

    changelog = "# Changelog\n\n" + "\n\n".join(
        f"## Step {step:03d}\n\n- Step {step:03d} canonical davranışı eklendi."
        for step in range(3, 0, -1)
    )
    (root / "CHANGELOG.md").write_text(changelog + "\n", encoding="utf-8")
    (root / "ROADMAP.md").write_text(
        "# Roadmap\n\n"
        "## Step 003 - UTF-8 Kaynak Doğrulaması\n\n"
        "- [x] Adım 003 tamamlandı.\n",
        encoding="utf-8",
    )
    state = {
        "current_safe_point": {
            "step": 3,
            "issue": 3,
            "pull_request": 4,
            "merge_commit": "abc123",
            "local_test_summary": "3 passed",
        },
        "product_maturity": {
            "state": "tested_domain_data_documentation_core",
            "field_ready_application": False,
        },
    }
    (state_dir / "project_state.json").write_text(
        json.dumps(state, ensure_ascii=False), encoding="utf-8"
    )
    return root


def test_instruction_file_is_included_at_top(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    output_path, _ = build_source(root)
    assert output_path.read_text(encoding="utf-8").startswith(INSTRUCTION.rstrip())


def test_latest_numbered_podcast_note_is_selected(tmp_path: Path) -> None:
    notes = {
        "035_adim_001_002_notebooklm_podcast_notu.md": _strict_note(
            35, 1, 2, "eski"
        ),
        "036_adim_001_003_notebooklm_podcast_notu.md": _strict_note(
            36, 1, 3, "en yeni"
        ),
    }
    root = _write_repo(tmp_path, notes=notes)
    note = find_latest_podcast_note(root / "docs/podcast_notes")
    assert note.number == 36
    assert "en yeni" in note.text


def test_older_podcast_note_is_not_used_as_latest(tmp_path: Path) -> None:
    notes = {
        "035_adim_001_002_notebooklm_podcast_notu.md": _strict_note(
            35, 1, 2, "ESKI_ISARET"
        ),
        "036_adim_001_003_notebooklm_podcast_notu.md": _strict_note(
            36, 1, 3, "YENI_ISARET"
        ),
    }
    root = _write_repo(tmp_path, notes=notes)
    output_path, _ = build_source(root)
    output = output_path.read_text(encoding="utf-8")
    assert "YENI_ISARET" in output
    assert "ESKI_ISARET" not in output


def test_latest_note_full_content_is_included(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    note_path = next((root / "docs/podcast_notes").glob("035_*.md"))
    note_text = note_path.read_text(encoding="utf-8")
    output_path, _ = build_source(root)
    assert note_text.rstrip() in output_path.read_text(encoding="utf-8")


def test_every_prior_step_summary_has_own_heading(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    output_path, _ = build_source(root)
    output = output_path.read_text(encoding="utf-8")
    for step in range(1, 4):
        assert f"### Adım {step:03d} —" in output


def test_summary_count_matches_manifest(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    output_path, manifest_path = build_source(root)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    output = output_path.read_text(encoding="utf-8")
    assert manifest["previous_step_summary_count"] == 3
    assert output.count("### Adım ") == 3


def test_output_and_manifest_are_deterministic(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    output_path, manifest_path = build_source(root)
    first = (output_path.read_bytes(), manifest_path.read_bytes())
    build_source(root)
    assert (output_path.read_bytes(), manifest_path.read_bytes()) == first


@pytest.mark.parametrize(
    "name",
    [
        "035_adim_bad_notebooklm_podcast_notu.md",
        "035_adim_003_001_notebooklm_podcast_notu.md",
    ],
)
def test_malformed_podcast_filename_or_range_fails_clearly(
    tmp_path: Path, name: str
) -> None:
    root = _write_repo(tmp_path, notes={name: _strict_note(35, 1, 3)})
    with pytest.raises(PodcastSourceError, match="Malformed podcast"):
        build_source(root)


def test_duplicate_latest_podcast_number_fails_clearly(tmp_path: Path) -> None:
    notes = {
        "035_adim_001_002_notebooklm_podcast_notu.md": _strict_note(35, 1, 2),
        "035_adim_001_003_notebooklm_podcast_notu.md": _strict_note(35, 1, 3),
    }
    root = _write_repo(tmp_path, notes=notes)
    with pytest.raises(PodcastSourceError, match="Duplicate podcast number 035"):
        build_source(root)


def test_missing_instruction_file_fails_clearly(tmp_path: Path) -> None:
    root = _write_repo(tmp_path, instruction=None)
    with pytest.raises(PodcastSourceError, match="instruction file is missing"):
        build_source(root)


def test_missing_required_note_section_fails_clearly(tmp_path: Path) -> None:
    note = _strict_note(35, 1, 3).replace(
        "## 12. Kapanış Sorusu ve Kısa Cevap", "## Eksik Son Bölüm"
    )
    root = _write_repo(
        tmp_path,
        notes={"035_adim_001_003_notebooklm_podcast_notu.md": note},
    )
    with pytest.raises(PodcastSourceError, match="missing required sections"):
        build_source(root)


def test_strict_note_with_complete_prior_step_headings_passes(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=(1, 2, 3))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    latest = find_latest_podcast_note(root / "docs/podcast_notes")
    assert latest.step_range == "004-006"


def test_strict_note_missing_prior_step_heading_fails_clearly(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=(1, 3))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    with pytest.raises(PodcastSourceError, match="missing prior-step headings: Adım 002"):
        find_latest_podcast_note(root / "docs/podcast_notes")


def test_strict_note_duplicate_prior_step_heading_fails_clearly(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=(1, 2, 2, 3))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    with pytest.raises(PodcastSourceError, match="duplicate prior-step headings: Adım 002"):
        find_latest_podcast_note(root / "docs/podcast_notes")


def test_strict_note_out_of_order_prior_step_headings_fail_clearly(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=(1, 3, 2))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    with pytest.raises(PodcastSourceError, match="out of ascending order"):
        find_latest_podcast_note(root / "docs/podcast_notes")


def test_matching_headings_outside_prior_section_do_not_satisfy_contract(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, outside_prior_steps=(1, 2, 3))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    with pytest.raises(PodcastSourceError, match="missing prior-step headings"):
        find_latest_podcast_note(root / "docs/podcast_notes")


def test_current_range_steps_are_not_required_in_prior_section(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=(1, 2, 3))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    latest = find_latest_podcast_note(root / "docs/podcast_notes")
    assert "### Adım 004" not in latest.text
    assert "### Adım 005" not in latest.text
    assert "### Adım 006" not in latest.text


def test_podcast_034_legacy_compatibility_remains_unchanged(
    tmp_path: Path,
) -> None:
    root = _write_repo(
        tmp_path,
        notes={"034_adim_001_003_notebooklm_podcast_notu.md": _legacy_note()},
    )
    latest = find_latest_podcast_note(root / "docs/podcast_notes")
    assert latest.number == 34
    assert latest.step_range == "001-003"


def test_historical_notes_are_not_modified(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    note_path = next((root / "docs/podcast_notes").glob("*.md"))
    before = note_path.read_bytes()
    build_source(root)
    assert note_path.read_bytes() == before


def test_no_network_or_filesystem_side_effects_outside_outputs(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    root = _write_repo(tmp_path)
    sentinel = root / "outside-sentinel.txt"
    sentinel.write_text("dokunma", encoding="utf-8")

    def fail_network(*args: object, **kwargs: object) -> None:
        raise AssertionError("network access attempted")

    monkeypatch.setattr(socket, "socket", fail_network)
    before = sentinel.read_bytes()
    build_source(root)
    assert sentinel.read_bytes() == before
    assert not list(root.glob("*.zip"))
    assert not (root / "exports").exists()


def test_utf8_turkish_characters_are_preserved(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    output_path, manifest_path = build_source(root)
    output = output_path.read_text(encoding="utf-8")
    assert "şantiye, güvenli, ölçüm" in output
    assert "Kalıcı Talimat" in output
    assert "UTF-8 Kaynak Doğrulaması" in output
    assert "ensure_ascii" not in manifest_path.read_text(encoding="utf-8")


def test_tracked_podcast_035_is_latest_and_included_in_rolling_source() -> None:
    note = find_latest_podcast_note(REPO_ROOT / "docs/podcast_notes")
    manifest = json.loads(
        (REPO_ROOT / "docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json").read_text(
            encoding="utf-8"
        )
    )
    rolling_source = (
        REPO_ROOT / "docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md"
    ).read_text(encoding="utf-8")
    note_prior_section = _find_section_body(
        note.text,
        "onceki adimlarin ayri ayri ozeti",
    )
    rolling_summary_start = rolling_source.rindex(
        "\n## Önceki Adımların Ayrı Ayrı Özeti"
    )
    rolling_summary_end = rolling_source.index(
        "\n## Güncel Güvenli Nokta ve Test Kanıtı",
        rolling_summary_start,
    )
    rolling_summary_section = rolling_source[
        rolling_summary_start:rolling_summary_end
    ]

    assert note.number == 35
    assert note.step_range == "221-225"
    assert note.text.rstrip() in rolling_source
    assert manifest["latest_podcast"] == 35
    assert manifest["latest_step_range"] == "221-225"
    assert manifest["previous_step_summary_count"] == 224
    assert len(PRIOR_STEP_HEADING_PATTERN.findall(note_prior_section)) == 220
    assert rolling_summary_section.count("### Adım ") == 224


def test_tracked_historical_podcast_034_hash_is_unchanged() -> None:
    podcast_034 = (
        REPO_ROOT
        / "docs/podcast_notes/034_adim_216_220_notebooklm_podcast_notu.md"
    )
    assert hashlib.sha256(podcast_034.read_bytes()).hexdigest().upper() == (
        "AB96737D29F58333FD5FA4AE5687F979D4B8527236F4515FA89CBB8D07DD30C3"
    )
