"""Build the deterministic rolling NotebookLM podcast source."""

from __future__ import annotations

import argparse
from collections import Counter
import json
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path


NOTE_PATTERN = re.compile(
    r"^(?P<podcast>\d{3})_adim_(?P<start>\d{3})_(?P<end>\d{3})_"
    r"notebooklm_podcast_notu\.md$"
)
STEP_HEADING_PATTERN = re.compile(
    r"^##[ \t]+(?:(?:Step|Adim)[ \t]+)?(?P<step>\d{3})(?![-\d])"
    r"(?:[ \t]+-?[ \t]*(?P<title>[^\r\n]+))?[ \t]*$",
    re.MULTILINE,
)
ROADMAP_HEADING_PATTERN = re.compile(
    r"^##\s+Step\s+(?P<step>\d{3})\s+-\s+(?P<title>.+)$",
    re.MULTILINE,
)
SECTION_HEADING_PATTERN = re.compile(
    r"^##(?!#)[ \t]+(?P<title>[^\r\n]+)[ \t]*$",
    re.MULTILINE,
)
PRIOR_STEP_HEADING_PATTERN = re.compile(
    r"^###[ \t]+Ad[ıi]m[ \t]+(?P<step>\d{3})(?!\d)"
    r"[ \t]+(?:—|-)[ \t]+[^\r\n]+$",
    re.IGNORECASE | re.MULTILINE,
)
STRICT_REQUIRED_SECTIONS = (
    "notebooklm kullanim talimati",
    "notun kapsami",
    "donemin ana temasi",
    "guncel adimlarin ayrintili anlatimi",
    "guncel donem ozeti",
    "onceki adimlarin ayri ayri ozeti",
    "birikimli urun ve teknik durum",
    "test ve guvenli nokta kaniti",
    "bilerek ertelenenler",
    "sonraki dogal yon",
    "notebooklm kisa direktifi",
    "kapanis sorusu ve kisa cevap",
)
LEGACY_REQUIRED_SECTIONS = (
    "donemin ana temasi",
    "kisa ozet",
    "adim adim gelisim",
    "test gelisimi",
    "bilerek ertelenenler",
    "sonraki gelistirme yonu",
    "notebooklm'e verilecek kisa direktif",
    "kapanis sorusu ve kisa cevap",
)
STABLE_PUBLIC_URL = (
    "https://raw.githubusercontent.com/faliardic/chief-site-engineer/"
    "master/docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md"
)


class PodcastSourceError(ValueError):
    """Raised when canonical podcast source input is incomplete or malformed."""


@dataclass(frozen=True)
class PodcastNote:
    number: int
    step_start: int
    step_end: int
    path: Path
    text: str

    @property
    def step_range(self) -> str:
        return f"{self.step_start:03d}-{self.step_end:03d}"


@dataclass(frozen=True)
class StepSummary:
    step: int
    title: str
    kind: str
    summary: str


def _normalized_heading(value: str) -> str:
    turkish_i_normalized = value.casefold().replace("ı", "i")
    decomposed = unicodedata.normalize("NFKD", turkish_i_normalized)
    without_marks = "".join(
        character
        for character in decomposed
        if not unicodedata.combining(character)
    )
    return re.sub(r"[^a-z0-9']+", " ", without_marks).strip()


def _find_section_body(text: str, normalized_title: str) -> str:
    headings = list(SECTION_HEADING_PATTERN.finditer(text))
    matching_indexes = [
        index
        for index, heading in enumerate(headings)
        if normalized_title in _normalized_heading(heading.group("title"))
    ]
    if not matching_indexes:
        raise PodcastSourceError(
            f"Strict podcast note is missing section: {normalized_title}"
        )
    if len(matching_indexes) > 1:
        raise PodcastSourceError(
            f"Strict podcast note has duplicate sections: {normalized_title}"
        )

    index = matching_indexes[0]
    start = headings[index].end()
    end = headings[index + 1].start() if index + 1 < len(headings) else len(text)
    return text[start:end]


def _validate_strict_prior_step_summaries(note: PodcastNote) -> None:
    section = _find_section_body(
        note.text,
        "onceki adimlarin ayri ayri ozeti",
    )
    section_steps = [
        int(match.group("step"))
        for match in PRIOR_STEP_HEADING_PATTERN.finditer(section)
    ]
    expected_steps = list(range(1, note.step_start))
    expected_set = set(expected_steps)
    expected_occurrences = [step for step in section_steps if step in expected_set]
    counts = Counter(expected_occurrences)

    duplicates = [step for step in expected_steps if counts[step] > 1]
    if duplicates:
        formatted = ", ".join(f"Adım {step:03d}" for step in duplicates)
        raise PodcastSourceError(
            f"Podcast {note.number:03d} has duplicate prior-step headings: {formatted}"
        )

    missing = [step for step in expected_steps if counts[step] == 0]
    if missing:
        formatted = ", ".join(f"Adım {step:03d}" for step in missing)
        raise PodcastSourceError(
            f"Podcast {note.number:03d} is missing prior-step headings: {formatted}"
        )

    if expected_occurrences != expected_steps:
        raise PodcastSourceError(
            f"Podcast {note.number:03d} prior-step headings are out of ascending order"
        )


def _validate_note_sections(note: PodcastNote) -> None:
    headings = [
        _normalized_heading(match.group(1))
        for match in re.finditer(r"^#{2,6}\s+(.+)$", note.text, re.MULTILINE)
    ]
    required = (
        STRICT_REQUIRED_SECTIONS if note.number >= 35 else LEGACY_REQUIRED_SECTIONS
    )
    missing = [
        section
        for section in required
        if not any(section in heading for heading in headings)
    ]
    if missing:
        missing_text = ", ".join(missing)
        raise PodcastSourceError(
            f"Podcast {note.number:03d} is missing required sections: {missing_text}"
        )
    if note.number >= 35:
        _validate_strict_prior_step_summaries(note)


def find_latest_podcast_note(notes_dir: Path) -> PodcastNote:
    if not notes_dir.is_dir():
        raise PodcastSourceError(f"Podcast notes directory is missing: {notes_dir}")

    notes: list[PodcastNote] = []
    numbers: dict[int, Path] = {}
    for path in sorted(notes_dir.glob("*.md")):
        if not path.name.endswith("_notebooklm_podcast_notu.md"):
            continue
        match = NOTE_PATTERN.fullmatch(path.name)
        if match is None:
            raise PodcastSourceError(f"Malformed podcast filename or range: {path.name}")

        number = int(match.group("podcast"))
        step_start = int(match.group("start"))
        step_end = int(match.group("end"))
        if step_start > step_end:
            raise PodcastSourceError(f"Malformed podcast step range: {path.name}")
        if number in numbers:
            raise PodcastSourceError(
                "Duplicate podcast number "
                f"{number:03d}: {numbers[number].name}, {path.name}"
            )
        numbers[number] = path
        notes.append(
            PodcastNote(
                number=number,
                step_start=step_start,
                step_end=step_end,
                path=path,
                text=path.read_text(encoding="utf-8"),
            )
        )

    if not notes:
        raise PodcastSourceError(f"No numbered podcast note found in: {notes_dir}")

    latest = max(notes, key=lambda note: note.number)
    _validate_note_sections(latest)
    return latest


def _parse_sections(text: str) -> dict[int, tuple[str, str]]:
    matches = list(STEP_HEADING_PATTERN.finditer(text))
    sections: dict[int, tuple[str, str]] = {}
    for index, match in enumerate(matches):
        step = int(match.group("step"))
        if step in sections:
            continue
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        sections[step] = ((match.group("title") or "").strip(), text[match.end() : end])
    return sections


def _first_substantive_line(section: str, step: int) -> str:
    for raw_line in section.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        line = re.sub(r"^-\s*(?:\[x\]\s*)?", "", line, flags=re.IGNORECASE)
        line = re.sub(
            rf"^(?:Step|Adim)\s+{step:03d}\s*-\s*",
            "",
            line,
            flags=re.IGNORECASE,
        )
        if line and not line.startswith("#"):
            return re.sub(r"\s+", " ", line)
    raise PodcastSourceError(f"Step {step:03d} has no factual summary in CHANGELOG.md")


def _title_from_doc(repo_root: Path, step: int) -> str | None:
    matches = sorted((repo_root / "docs").glob(f"{step:03d}_*.md"))
    if not matches:
        return None
    title = matches[0].stem[4:].replace("_", " ").strip()
    return title[:1].upper() + title[1:]


def _short_title(summary: str) -> str:
    plain = summary.replace("`", "")
    first_clause = re.split(r"[.;]", plain, maxsplit=1)[0].strip()
    words = first_clause.split()
    if len(words) > 10:
        first_clause = " ".join(words[:10])
    return first_clause or "Canonical proje adimi"


def _classify_step(title: str, summary: str, section: str) -> str:
    normalized = _normalized_heading(f"{title} {summary} {section}")
    title_normalized = _normalized_heading(title)
    documentation_signals = (
        "documentation only",
        "dokumantasyon",
        "plan",
        "protocol",
        "boundary",
        "standardization",
        "usage",
        "podcast",
    )
    implementation_signals = (
        " eklendi",
        " uygulandi",
        " implemented",
        " model eklendi",
        " repository eklendi",
        " helper eklendi",
    )
    if "podcast" in title_normalized or "podcast" in _normalized_heading(summary):
        return "podcast ve dokumantasyon"
    if any(signal in normalized for signal in implementation_signals):
        return "uretim kodu ve test"
    if any(signal in normalized for signal in documentation_signals):
        return "dokumantasyon veya protokol"
    return "proje kaydi veya kalite dogrulamasi"


def collect_step_summaries(repo_root: Path, max_step: int) -> list[StepSummary]:
    changelog_path = repo_root / "CHANGELOG.md"
    if not changelog_path.is_file():
        raise PodcastSourceError(f"Canonical step history is missing: {changelog_path}")

    changelog_sections = _parse_sections(changelog_path.read_text(encoding="utf-8"))
    roadmap_path = repo_root / "ROADMAP.md"
    roadmap_titles: dict[int, str] = {}
    if roadmap_path.is_file():
        roadmap_text = roadmap_path.read_text(encoding="utf-8")
        roadmap_titles = {
            int(match.group("step")): match.group("title").strip()
            for match in ROADMAP_HEADING_PATTERN.finditer(roadmap_text)
        }

    missing = [step for step in range(1, max_step + 1) if step not in changelog_sections]
    if missing:
        formatted = ", ".join(f"{step:03d}" for step in missing)
        raise PodcastSourceError(f"Canonical step summaries are missing: {formatted}")

    summaries: list[StepSummary] = []
    for step in range(1, max_step + 1):
        changelog_title, section = changelog_sections[step]
        summary = _first_substantive_line(section, step)
        title = (
            _title_from_doc(repo_root, step)
            or roadmap_titles.get(step)
            or changelog_title
            or _short_title(summary)
        )
        summaries.append(
            StepSummary(
                step=step,
                title=title,
                kind=_classify_step(title, summary, section),
                summary=summary,
            )
        )
    return summaries


def _load_project_state(state_path: Path) -> dict[str, object]:
    if not state_path.is_file():
        raise PodcastSourceError(f"Project state is missing: {state_path}")
    try:
        state = json.loads(state_path.read_text(encoding="utf-8"))
        safe_point = state["current_safe_point"]
        safe_step = safe_point["step"]
        safe_commit = safe_point["merge_commit"]
        test_summary = safe_point["local_test_summary"]
    except (json.JSONDecodeError, KeyError, TypeError) as exc:
        raise PodcastSourceError(
            "Project state lacks current safe-point/test evidence"
        ) from exc
    if not isinstance(safe_step, int) or not isinstance(safe_commit, str):
        raise PodcastSourceError("Project safe-point fields have invalid types")
    if not isinstance(test_summary, str):
        raise PodcastSourceError("Project test evidence has an invalid type")
    return state


def _render_summaries(summaries: list[StepSummary]) -> str:
    blocks = []
    for item in summaries:
        blocks.append(
            f"### Adım {item.step:03d} — {item.title}\n"
            f"Tür: {item.kind}. Tamamlanmış adımdır. {item.summary}"
        )
    return "\n\n".join(blocks)


def _render_source(
    instruction_text: str,
    note: PodcastNote,
    summaries: list[StepSummary],
    state: dict[str, object],
) -> str:
    safe_point = state["current_safe_point"]
    maturity = state.get("product_maturity", {})
    maturity_state = maturity.get("state", "canonical project state")
    field_ready = maturity.get("field_ready_application", False)
    field_ready_text = "evet" if field_ready else "hayir"
    note_path = note.path.as_posix()
    if "docs/" in note_path:
        note_path = "docs/" + note_path.split("docs/", 1)[1]

    sections = [
        instruction_text.rstrip(),
        "---\n\n# CSE Podcast Güncel Rolling Kaynağı",
        (
            "## Güncel Proje Kimliği ve Ürün Sınırı\n\n"
            "CHIEF SITE ENGINEER (CSE), şantiye şefinin dağınık saha bilgisini "
            "hızlı kayıt, kanıt, takip, arşiv ve devir düzenine taşıyan Python "
            "tabanlı saha hafızası projesidir. Güvenilir veri omurgası önce, "
            "otomasyon sonra, AI en son gelir.\n\n"
            f"Canonical olgunluk durumu: `{maturity_state}`. "
            f"Field-ready uygulama: `{field_ready_text}`."
        ),
        (
            "## En Güncel Podcast Kimliği\n\n"
            f"- Podcast numarası: `{note.number:03d}`\n"
            f"- Kapsanan adım aralığı: `{note.step_range}`\n"
            f"- Canonical not: `{note_path}`"
        ),
        "## En Güncel Podcast Notu - Tam Metin\n\n" + note.text.rstrip(),
        (
            "## Önceki Adımların Ayrı Ayrı Özeti\n\n"
            "Bu özetler tamamlanmış canonical adımları tarihsel bağlam olarak "
            "taşır. Güncel durum için yukarıdaki kimlik ile aşağıdaki safe point "
            "kanıtı üstündür.\n\n"
            + _render_summaries(summaries)
        ),
        (
            "## Güncel Güvenli Nokta ve Test Kanıtı\n\n"
            f"- Son merged/finalized adım: `{safe_point['step']}`\n"
            f"- Issue: `#{safe_point['issue']}`\n"
            f"- PR: `#{safe_point['pull_request']}`\n"
            f"- Merge commit: `{safe_point['merge_commit']}`\n"
            f"- Son doğrulanan yerel test sonucu: `{safe_point['local_test_summary']}`\n\n"
            "Test başarısı mevcut davranışın regresyon testlerinden geçtiğini "
            "gösterir; tek başına field-ready veya production-ready ürün kanıtı değildir."
        ),
        (
            "## Bilerek Ertelenenler\n\n"
            "- Ana ürün için database/SQLite/JSON persistence\n"
            "- Fiziksel dosya upload/download/copy/move/delete ve integrity işlemleri\n"
            "- Ana ürün API, GUI, CLI, PWA ve offline sync\n"
            "- Otomatik lifecycle, audit ve generated `blocked` davranışı\n"
            "- NotebookLM API, credential, browser automation, otomatik upload ve Audio Overview üretimi"
        ),
        (
            "## Üretim Metadata'sı ve Manifest Referansı\n\n"
            "- Generator: `scripts/build_notebooklm_podcast_source.py`\n"
            "- Manifest: `docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json`\n"
            f"- Stable public URL: {STABLE_PUBLIC_URL}\n"
            "- Üretim biçimi: ağ erişimsiz, UTF-8 ve deterministik\n"
            f"- Birikimli ayrı adım özeti sayısı: `{len(summaries)}`\n\n"
            "Repository bu URL'nin yolunu sabit ve içeriğini her generator çalışmasında "
            "güncel tutar. NotebookLM'in kaydedilmiş website source'u kendiliğinden "
            "yenilediği doğrulanmamıştır; gerekirse NotebookLM arayüzünde refresh durumu "
            "kullanıcı tarafından kontrol edilir."
        ),
    ]
    return "\n\n".join(sections).rstrip() + "\n"


def build_source(repo_root: Path) -> tuple[Path, Path]:
    repo_root = repo_root.resolve()
    instruction_path = repo_root / "docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md"
    if not instruction_path.is_file():
        raise PodcastSourceError(f"NotebookLM instruction file is missing: {instruction_path}")

    instruction_text = instruction_path.read_text(encoding="utf-8")
    note = find_latest_podcast_note(repo_root / "docs/podcast_notes")
    state = _load_project_state(repo_root / ".cse/state/project_state.json")
    safe_step = state["current_safe_point"]["step"]
    summaries = collect_step_summaries(repo_root, safe_step)

    output_path = repo_root / "docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md"
    manifest_path = repo_root / "docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    source_text = _render_source(instruction_text, note, summaries, state)
    output_path.write_text(source_text, encoding="utf-8", newline="\n")

    note_relative = note.path.relative_to(repo_root).as_posix()
    manifest = {
        "instruction_path": "docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md",
        "latest_note_path": note_relative,
        "latest_podcast": note.number,
        "latest_safe_point_commit": state["current_safe_point"]["merge_commit"],
        "latest_safe_point_step": safe_step,
        "latest_step_range": note.step_range,
        "previous_step_summary_count": len(summaries),
        "rolling_source_path": "docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md",
        "stable_public_url": STABLE_PUBLIC_URL,
    }
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    return output_path, manifest_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build the deterministic CSE NotebookLM rolling podcast source."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="CSE repository root (defaults to the script's repository).",
    )
    args = parser.parse_args()
    try:
        output_path, manifest_path = build_source(args.repo_root)
    except PodcastSourceError as exc:
        parser.error(str(exc))
    print(output_path)
    print(manifest_path)


if __name__ == "__main__":
    main()
