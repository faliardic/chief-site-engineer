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
    r"^(?P<podcast>\d{3})_(?P<range_kind>adim|issue)_"
    r"(?P<start>\d{3})_(?P<end>\d{3})_notebooklm_podcast_notu\.md$"
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
ISSUE_HEADING_PATTERN = re.compile(
    r"^##[ \t]+Issue[ \t]+#(?P<issue>\d+)[ \t]+(?:-|—)[ \t]+"
    r"(?P<title>[^\r\n]+)[ \t]*$",
    re.MULTILINE,
)
LEVEL_TWO_HEADING_PATTERN = re.compile(r"^##(?!#)[ \t]+.+$", re.MULTILINE)
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
    range_kind: str
    range_start: int
    range_end: int
    path: Path
    text: str

    @property
    def range_value(self) -> str:
        return f"{self.range_start:03d}-{self.range_end:03d}"

    @property
    def step_range(self) -> str:
        """Backward-compatible alias used by legacy callers and tests."""
        return self.range_value


@dataclass(frozen=True)
class StepSummary:
    step: int
    title: str
    kind: str
    summary: str


@dataclass(frozen=True)
class IssueSummary:
    issue: int
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
    expected_steps = list(range(1, note.range_start))
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
    if note.number >= 35 and note.range_kind == "adim":
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
        range_start = int(match.group("start"))
        range_end = int(match.group("end"))
        if range_start > range_end:
            raise PodcastSourceError(f"Malformed podcast range: {path.name}")
        if number in numbers:
            raise PodcastSourceError(
                "Duplicate podcast number "
                f"{number:03d}: {numbers[number].name}, {path.name}"
            )
        numbers[number] = path
        notes.append(
            PodcastNote(
                number=number,
                range_kind=match.group("range_kind"),
                range_start=range_start,
                range_end=range_end,
                path=path,
                text=path.read_text(encoding="utf-8"),
            )
        )

    if not notes:
        raise PodcastSourceError(f"No numbered podcast note found in: {notes_dir}")

    latest = max(notes, key=lambda note: note.number)
    _validate_note_sections(latest)
    return latest


def _parse_step_sections(text: str) -> dict[int, tuple[str, str]]:
    matches = list(STEP_HEADING_PATTERN.finditer(text))
    sections: dict[int, tuple[str, str]] = {}
    for index, match in enumerate(matches):
        step = int(match.group("step"))
        if step in sections:
            continue
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        sections[step] = ((match.group("title") or "").strip(), text[match.end() : end])
    return sections


def _first_substantive_line(section: str, label: str) -> str:
    for raw_line in section.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        line = re.sub(r"^-\s*(?:\[x\]\s*)?", "", line, flags=re.IGNORECASE)
        if line and not line.startswith("#"):
            return re.sub(r"\s+", " ", line)
    raise PodcastSourceError(f"{label} has no factual summary in CHANGELOG.md")


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
    return first_clause or "Canonical proje kaydı"


def _classify_summary(title: str, summary: str, section: str) -> str:
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
        return "podcast ve dokümantasyon"
    if any(signal in normalized for signal in implementation_signals):
        return "üretim kodu ve test"
    if any(signal in normalized for signal in documentation_signals):
        return "dokümantasyon veya protokol"
    return "proje kaydı veya kalite doğrulaması"


def collect_step_summaries(repo_root: Path, max_step: int) -> list[StepSummary]:
    changelog_path = repo_root / "CHANGELOG.md"
    if not changelog_path.is_file():
        raise PodcastSourceError(f"Canonical step history is missing: {changelog_path}")

    changelog_sections = _parse_step_sections(
        changelog_path.read_text(encoding="utf-8")
    )
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
        summary = _first_substantive_line(section, f"Step {step:03d}")
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
                kind=_classify_summary(title, summary, section),
                summary=summary,
            )
        )
    return summaries


def collect_issue_summaries(
    repo_root: Path, issue_start: int, issue_end: int
) -> list[IssueSummary]:
    """Return only real canonical CHANGELOG issue sections in the range."""
    changelog_path = repo_root / "CHANGELOG.md"
    if not changelog_path.is_file():
        raise PodcastSourceError(f"Canonical issue history is missing: {changelog_path}")

    text = changelog_path.read_text(encoding="utf-8")
    all_level_two = list(LEVEL_TWO_HEADING_PATTERN.finditer(text))
    issue_matches = list(ISSUE_HEADING_PATTERN.finditer(text))
    seen: set[int] = set()
    summaries: list[IssueSummary] = []
    for match in issue_matches:
        issue = int(match.group("issue"))
        if issue in seen:
            raise PodcastSourceError(
                f"Canonical CHANGELOG has duplicate Issue #{issue} sections"
            )
        seen.add(issue)
        if not issue_start <= issue <= issue_end:
            continue
        next_heading = next(
            (
                heading
                for heading in all_level_two
                if heading.start() > match.start()
            ),
            None,
        )
        end = next_heading.start() if next_heading is not None else len(text)
        section = text[match.end() : end]
        title = match.group("title").strip()
        summary = _first_substantive_line(section, f"Issue #{issue}")
        summaries.append(
            IssueSummary(
                issue=issue,
                title=title,
                kind=_classify_summary(title, summary, section),
                summary=summary,
            )
        )

    summaries.sort(key=lambda item: item.issue)
    if not summaries:
        raise PodcastSourceError(
            f"No canonical Issue sections found in range {issue_start}-{issue_end}"
        )
    return summaries


def _load_project_state(state_path: Path) -> dict[str, object]:
    if not state_path.is_file():
        raise PodcastSourceError(f"Project state is missing: {state_path}")
    try:
        state = json.loads(state_path.read_text(encoding="utf-8"))
        legacy_last_step = state["legacy_last_numbered_step"]
        safe_point = state["current_safe_point"]
        safe_issue = safe_point["issue"]
        safe_pull_request = safe_point["pull_request"]
        safe_commit = safe_point["merge_commit"]
        test_summary = safe_point["local_test_summary"]
    except (json.JSONDecodeError, KeyError, TypeError) as exc:
        raise PodcastSourceError(
            "Project state lacks current safe-point/test evidence"
        ) from exc
    if not isinstance(legacy_last_step, int) or legacy_last_step < 1:
        raise PodcastSourceError("Legacy last numbered step has an invalid type")
    if not isinstance(safe_issue, int) or not isinstance(safe_pull_request, int):
        raise PodcastSourceError("Project safe-point issue fields have invalid types")
    if not isinstance(safe_commit, str) or not safe_commit:
        raise PodcastSourceError("Project safe-point commit has an invalid type")
    if not isinstance(test_summary, str) or not test_summary:
        raise PodcastSourceError("Project test evidence has an invalid type")
    return state


def _render_step_summaries(summaries: list[StepSummary]) -> str:
    return "\n\n".join(
        f"### Adım {item.step:03d} — {item.title}\n"
        f"Tür: {item.kind}. Tamamlanmış adımdır. {item.summary}"
        for item in summaries
    )


def _render_issue_summaries(summaries: list[IssueSummary]) -> str:
    return "\n\n".join(
        f"### Issue #{item.issue} — {item.title}\n"
        f"Tür: {item.kind}. Birleşmiş canonical kayıttır. {item.summary}"
        for item in summaries
    )


def _render_source(
    instruction_text: str,
    note: PodcastNote,
    legacy_summaries: list[StepSummary],
    issue_summaries: list[IssueSummary],
    state: dict[str, object],
) -> str:
    safe_point = state["current_safe_point"]
    maturity = state.get("product_maturity", {})
    maturity_state = maturity.get("state", "canonical project state")
    field_ready = maturity.get("field_ready_application", False)
    production_ready = maturity.get("production_ready_application", False)
    note_path = note.path.as_posix()
    if "docs/" in note_path:
        note_path = "docs/" + note_path.split("docs/", 1)[1]
    range_label = "Issue aralığı" if note.range_kind == "issue" else "Adım aralığı"

    sections = [
        instruction_text.rstrip(),
        "---\n\n# CSE Podcast Güncel Rolling Kaynağı",
        (
            "## Güncel Proje Kimliği ve Ürün Sınırı\n\n"
            "CHIEF SITE ENGINEER (CSE), şantiye şefinin saha kaydı, kanıtı, "
            "takibi, arşivi ve devri için geliştirilen offline-first bir mobil "
            "uygulamadır. Flutter mobil ürün cihaz-içi SQLite ve uygulama özel "
            "dosya alanını kullanır; Python araçları repository doğrulaması ve "
            "tarihsel destek için korunur.\n\n"
            f"Canonical olgunluk durumu: `{maturity_state}`. "
            f"Field-ready: `{'evet' if field_ready else 'hayır'}`. "
            f"Production-ready: `{'evet' if production_ready else 'hayır'}`."
        ),
        (
            "## En Güncel Podcast Kimliği\n\n"
            f"- Podcast numarası: `{note.number:03d}`\n"
            f"- Aralık türü: `{note.range_kind}`\n"
            f"- {range_label}: `{note.range_value}`\n"
            f"- Canonical not: `{note_path}`"
        ),
        "## En Güncel Podcast Notu - Tam Metin\n\n" + note.text.rstrip(),
        (
            "## Legacy Numaralı Adımların Tarihsel Özeti\n\n"
            "Adım 001–225 tamamlanmış tarihsel bağlamdır. Yeni çalışma "
            "takibi Issue numarasıyla sürer; bu adımlar güncel Issue durumunun "
            "yerine geçmez.\n\n"
            + _render_step_summaries(legacy_summaries)
        ),
    ]
    if issue_summaries:
        sections.append(
            "## Canonical Issue Dönemi Özeti\n\n"
            "Aralıktaki eksik numaralar uydurulmaz. Yalnız CHANGELOG.md içinde "
            "gerçek bir `## Issue #NNN` bölümü bulunan birleşmiş işler listelenir.\n\n"
            + _render_issue_summaries(issue_summaries)
        )
    sections.extend(
        [
            (
                "## Güncel Güvenli Nokta ve Test Kanıtı\n\n"
                f"- Son merged/finalized Issue: `#{safe_point['issue']}`\n"
                f"- PR: `#{safe_point['pull_request']}`\n"
                f"- Merge commit: `{safe_point['merge_commit']}`\n"
                f"- Son doğrulanan kanıt: `{safe_point['local_test_summary']}`\n\n"
                "Test başarısı mevcut davranışın doğrulandığını gösterir; tek "
                "başına field-ready veya production-ready ürün kanıtı değildir."
            ),
            (
                "## Aktif ve Birleşmemiş İşlerin Sınırı\n\n"
                "Issue #279 README/NotebookLM senkronizasyonu için duraklatılmış "
                "aktif iştir; davranışı bu safe point'e uygulanmış sayılmaz. "
                "PR #259 açık, Draft ve conflicting durumdaki ayrı acceptance "
                "altyapısıdır; birleşmiş ürün davranışı değildir."
            ),
            (
                "## Bilerek Ertelenenler\n\n"
                "- Issue #279'un hızlı daha-erken-zaman davranışı\n"
                "- PR #259 içindeki fiziksel smoke acceptance altyapısı\n"
                "- Telefon promotion ve store/release yayını\n"
                "- Field-ready ve production-ready ilanı\n"
                "- NotebookLM API, credential, browser automation ve otomatik Audio Overview üretimi"
            ),
            (
                "## Üretim Metadata'sı ve Manifest Referansı\n\n"
                "- Generator: `scripts/build_notebooklm_podcast_source.py`\n"
                "- Manifest: `docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json`\n"
                f"- Stable public URL: {STABLE_PUBLIC_URL}\n"
                "- Üretim biçimi: ağ erişimsiz, UTF-8 ve deterministik\n"
                f"- Legacy adım özeti sayısı: `{len(legacy_summaries)}`\n"
                f"- Canonical Issue özeti sayısı: `{len(issue_summaries)}`\n\n"
                "NotebookLM'in kaydedilmiş website source'u kendiliğinden "
                "yenilediği doğrulanmamıştır; gerekirse refresh durumu kullanıcı "
                "tarafından kontrol edilir."
            ),
        ]
    )
    return "\n\n".join(sections).rstrip() + "\n"


def build_source(repo_root: Path) -> tuple[Path, Path]:
    repo_root = repo_root.resolve()
    instruction_path = repo_root / "docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md"
    if not instruction_path.is_file():
        raise PodcastSourceError(
            f"NotebookLM instruction file is missing: {instruction_path}"
        )

    instruction_text = instruction_path.read_text(encoding="utf-8")
    note = find_latest_podcast_note(repo_root / "docs/podcast_notes")
    state = _load_project_state(repo_root / ".cse/state/project_state.json")
    legacy_last_step = state["legacy_last_numbered_step"]
    legacy_summaries = collect_step_summaries(repo_root, legacy_last_step)
    issue_summaries = (
        collect_issue_summaries(repo_root, note.range_start, note.range_end)
        if note.range_kind == "issue"
        else []
    )

    output_path = repo_root / "docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md"
    manifest_path = repo_root / "docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    source_text = _render_source(
        instruction_text,
        note,
        legacy_summaries,
        issue_summaries,
        state,
    )
    output_path.write_text(source_text, encoding="utf-8", newline="\n")

    note_relative = note.path.relative_to(repo_root).as_posix()
    safe_point = state["current_safe_point"]
    manifest = {
        "instruction_path": "docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md",
        "issue_summary_count": len(issue_summaries),
        "latest_issue_range": (
            note.range_value if note.range_kind == "issue" else None
        ),
        "latest_note_path": note_relative,
        "latest_podcast": note.number,
        "latest_range": note.range_value,
        "latest_range_kind": note.range_kind,
        "latest_safe_point_commit": safe_point["merge_commit"],
        "latest_safe_point_issue": safe_point["issue"],
        "latest_safe_point_pull_request": safe_point["pull_request"],
        "latest_safe_point_step": safe_point.get("step"),
        "latest_step_range": (
            note.range_value if note.range_kind == "adim" else None
        ),
        "legacy_last_numbered_step": legacy_last_step,
        "legacy_step_summary_count": len(legacy_summaries),
        "previous_step_summary_count": len(legacy_summaries),
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
