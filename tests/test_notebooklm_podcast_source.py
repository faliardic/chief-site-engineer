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
    collect_issue_summaries,
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
    range_kind: str = "adim",
    prior_steps: tuple[int, ...] = (),
    outside_prior_steps: tuple[int, ...] = (),
) -> str:
    prior_summaries = (
        _prior_step_summaries(*prior_steps)
        if prior_steps
        else "Bu aralık öncesinde canonical adım yoktur."
    )
    outside_summaries = _prior_step_summaries(*outside_prior_steps)
    range_label = "Issue" if range_kind == "issue" else "Adım"
    return f"""# Podcast {podcast:03d} - {range_label} {start:03d}-{end:03d}

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
Ertelenenler.

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

    step_sections = "\n\n".join(
        f"## Step {step:03d}\n\n- Step {step:03d} canonical davranışı eklendi."
        for step in range(3, 0, -1)
    )
    issue_sections = """

## Issue #12 - Son Gerçek Issue

- Issue 12 davranışı eklendi.

## Issue #10 - İlk Gerçek Issue

- Issue 10 davranışı eklendi.
""".rstrip()
    (root / "CHANGELOG.md").write_text(
        f"# Changelog\n\n{issue_sections}\n\n{step_sections}\n",
        encoding="utf-8",
    )
    (root / "ROADMAP.md").write_text(
        "# Roadmap\n\n"
        "## Step 003 - UTF-8 Kaynak Doğrulaması\n\n"
        "- [x] Adım 003 tamamlandı.\n",
        encoding="utf-8",
    )
    state = {
        "state_version": 3,
        "legacy_last_numbered_step": 3,
        "current_safe_point": {
            "issue": 12,
            "pull_request": 13,
            "merge_commit": "abc123",
            "local_test_summary": "3 passed",
        },
        "product_maturity": {
            "state": "tested_mobile_core",
            "field_ready_application": False,
            "production_ready_application": False,
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


def test_latest_numbered_note_can_transition_from_adim_to_issue(
    tmp_path: Path,
) -> None:
    notes = {
        "035_adim_001_003_notebooklm_podcast_notu.md": _strict_note(
            35, 1, 3, "eski"
        ),
        "036_issue_010_012_notebooklm_podcast_notu.md": _strict_note(
            36, 10, 12, "en yeni", range_kind="issue"
        ),
    }
    root = _write_repo(tmp_path, notes=notes)
    note = find_latest_podcast_note(root / "docs/podcast_notes")
    assert note.number == 36
    assert note.range_kind == "issue"
    assert note.range_value == "010-012"
    assert "en yeni" in note.text


def test_duplicate_podcast_number_across_range_kinds_fails(
    tmp_path: Path,
) -> None:
    notes = {
        "036_adim_001_003_notebooklm_podcast_notu.md": _strict_note(36, 1, 3),
        "036_issue_010_012_notebooklm_podcast_notu.md": _strict_note(
            36, 10, 12, range_kind="issue"
        ),
    }
    root = _write_repo(tmp_path, notes=notes)
    with pytest.raises(PodcastSourceError, match="Duplicate podcast number 036"):
        build_source(root)


def test_issue_range_uses_only_real_changelog_sections_and_allows_gaps(
    tmp_path: Path,
) -> None:
    root = _write_repo(
        tmp_path,
        notes={
            "036_issue_010_012_notebooklm_podcast_notu.md": _strict_note(
                36, 10, 12, range_kind="issue"
            )
        },
    )
    summaries = collect_issue_summaries(root, 10, 12)
    assert [item.issue for item in summaries] == [10, 12]
    output_path, manifest_path = build_source(root)
    output = output_path.read_text(encoding="utf-8")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert "### Issue #10" in output
    assert "### Issue #11" not in output
    assert "### Issue #12" in output
    assert manifest["issue_summary_count"] == 2
    assert manifest["latest_range_kind"] == "issue"
    assert manifest["latest_issue_range"] == "010-012"
    assert manifest["latest_step_range"] is None


def test_legacy_adim_output_and_manifest_remain_compatible(
    tmp_path: Path,
) -> None:
    root = _write_repo(tmp_path)
    output_path, manifest_path = build_source(root)
    output = output_path.read_text(encoding="utf-8")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert output.count("### Adım ") == 3
    assert manifest["latest_range_kind"] == "adim"
    assert manifest["latest_step_range"] == "001-003"
    assert manifest["latest_issue_range"] is None
    assert manifest["previous_step_summary_count"] == 3
    assert manifest["legacy_step_summary_count"] == 3


def test_latest_note_full_content_is_included(tmp_path: Path) -> None:
    root = _write_repo(tmp_path)
    note_path = next((root / "docs/podcast_notes").glob("035_*.md"))
    note_text = note_path.read_text(encoding="utf-8")
    output_path, _ = build_source(root)
    assert note_text.rstrip() in output_path.read_text(encoding="utf-8")


def test_output_and_manifest_are_byte_deterministic(tmp_path: Path) -> None:
    root = _write_repo(
        tmp_path,
        notes={
            "036_issue_010_012_notebooklm_podcast_notu.md": _strict_note(
                36, 10, 12, range_kind="issue"
            )
        },
    )
    output_path, manifest_path = build_source(root)
    first = (output_path.read_bytes(), manifest_path.read_bytes())
    build_source(root)
    assert (output_path.read_bytes(), manifest_path.read_bytes()) == first


@pytest.mark.parametrize(
    "name",
    [
        "035_adim_bad_notebooklm_podcast_notu.md",
        "035_issue_012_010_notebooklm_podcast_notu.md",
        "035_ticket_010_012_notebooklm_podcast_notu.md",
    ],
)
def test_malformed_filename_or_range_fails_clearly(
    tmp_path: Path, name: str
) -> None:
    root = _write_repo(tmp_path, notes={name: _strict_note(35, 1, 3)})
    with pytest.raises(PodcastSourceError, match="Malformed podcast"):
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


def test_strict_legacy_note_requires_complete_ordered_prior_steps(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=(1, 2, 3))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    latest = find_latest_podcast_note(root / "docs/podcast_notes")
    assert latest.step_range == "004-006"


@pytest.mark.parametrize(
    ("prior_steps", "message"),
    [
        ((1, 3), "missing prior-step headings: Adım 002"),
        ((1, 2, 2, 3), "duplicate prior-step headings: Adım 002"),
        ((1, 3, 2), "out of ascending order"),
    ],
)
def test_strict_legacy_prior_step_errors_remain_clear(
    tmp_path: Path,
    prior_steps: tuple[int, ...],
    message: str,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=prior_steps)
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    with pytest.raises(PodcastSourceError, match=message):
        find_latest_podcast_note(root / "docs/podcast_notes")


def test_issue_note_does_not_require_fabricated_prior_step_headings(
    tmp_path: Path,
) -> None:
    root = _write_repo(
        tmp_path,
        notes={
            "036_issue_010_012_notebooklm_podcast_notu.md": _strict_note(
                36, 10, 12, range_kind="issue"
            )
        },
    )
    latest = find_latest_podcast_note(root / "docs/podcast_notes")
    assert latest.range_kind == "issue"


def test_podcast_034_legacy_compatibility_remains_unchanged(
    tmp_path: Path,
) -> None:
    root = _write_repo(
        tmp_path,
        notes={"034_adim_001_003_notebooklm_podcast_notu.md": _legacy_note()},
    )
    latest = find_latest_podcast_note(root / "docs/podcast_notes")
    assert latest.number == 34
    assert latest.range_kind == "adim"
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
    assert "\\u015f" not in manifest_path.read_text(encoding="utf-8")


def test_tracked_podcast_036_issue_range_is_latest_and_generated() -> None:
    note = find_latest_podcast_note(REPO_ROOT / "docs/podcast_notes")
    manifest = json.loads(
        (REPO_ROOT / "docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json").read_text(
            encoding="utf-8"
        )
    )
    rolling_source = (
        REPO_ROOT / "docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md"
    ).read_text(encoding="utf-8")

    assert note.number == 36
    assert note.range_kind == "issue"
    assert note.range_value == "227-277"
    assert note.text.rstrip() in rolling_source
    assert manifest["latest_podcast"] == 36
    assert manifest["latest_range_kind"] == "issue"
    assert manifest["latest_issue_range"] == "227-277"
    assert manifest["legacy_last_numbered_step"] == 225
    assert manifest["legacy_step_summary_count"] == 225
    assert manifest["issue_summary_count"] == 13
    issue_summary_section = rolling_source.split(
        "## Canonical Issue Dönemi Özeti", maxsplit=1
    )[1].split("## Güncel Güvenli Nokta ve Test Kanıtı", maxsplit=1)[0]
    assert issue_summary_section.count("### Issue #") == 13


def test_tracked_historical_podcast_034_hash_is_unchanged() -> None:
    podcast_034 = (
        REPO_ROOT
        / "docs/podcast_notes/034_adim_216_220_notebooklm_podcast_notu.md"
    )
    assert hashlib.sha256(podcast_034.read_bytes()).hexdigest().upper() == (
        "AB96737D29F58333FD5FA4AE5687F979D4B8527236F4515FA89CBB8D07DD30C3"
    )


def test_tracked_podcast_035_prior_step_contract_remains_parseable() -> None:
    note_path = (
        REPO_ROOT
        / "docs/podcast_notes/035_adim_221_225_notebooklm_podcast_notu.md"
    )
    note_text = note_path.read_text(encoding="utf-8")
    prior_section = _find_section_body(
        note_text,
        "onceki adimlarin ayri ayri ozeti",
    )
    assert len(PRIOR_STEP_HEADING_PATTERN.findall(prior_section)) == 220
