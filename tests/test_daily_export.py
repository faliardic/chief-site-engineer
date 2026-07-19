import hashlib
import io
import json
import zipfile
from pathlib import Path
from uuid import UUID

import pytest

from app.application import (
    CloseRoutineOccurrence,
    CreateFollowUp,
    CreateObservation,
    CreateRoutineTemplate,
    FollowUpApplicationService,
    ObservationApplicationService,
    RoutineApplicationService,
    UpdateFollowUp,
    UploadStream,
)
from app.field_tracking import (
    FollowUpItemType,
    RoutineOccurrenceOutcome,
    RoutineRecurrenceType,
)
from app.operations import DailyExportService
from app.storage import ManagedAttachmentStore


IDS = [
    "11111111-1111-4111-8111-111111111111",
    "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
    "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
    "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
]


def seed_observation(root: Path, observed_at: str = "2026-07-12T21:30:00Z") -> str:
    ids = iter(IDS)
    times = iter(["2026-07-12T08:00:00Z", observed_at])
    service = ObservationApplicationService(
        root / "cse.sqlite3",
        ManagedAttachmentStore(root / "attachments"),
        clock=lambda: next(times),
        uuid_factory=lambda: next(ids),
        local_actor="Santiye sefi",
    )
    project = service.create_project("Ornek | Santiye")
    observation = service.create_observation(
        CreateObservation(
            project_id=project.project_id,
            location="A Blok",
            category="quality",
            description="Kalip | kontrolu\nikinci satir",
            notes="Not",
            upload=UploadStream(io.BytesIO(b"photo-bytes"), "saha.jpg"),
        )
    )
    return observation.observation_id


def read_zip_json(archive: Path, name: str) -> object:
    with zipfile.ZipFile(archive) as bundle:
        return json.loads(bundle.read(name))


def tracking_uuid_values(start: int):
    number = start
    while True:
        yield str(UUID(int=number, version=4))
        number += 1


def seed_private_tracking(root: Path, observation_id: str) -> tuple[str, ...]:
    follow_ids = tracking_uuid_values(5000)
    follow_service = FollowUpApplicationService(
        root / "cse.sqlite3",
        clock=lambda: "2026-07-13T09:30:00Z",
        uuid_factory=lambda: next(follow_ids),
    )
    follow_up = follow_service.create_follow_up(
        CreateFollowUp("EXPORT-SIZINTI-TAKIP-METNI-117")
    )
    follow_up = follow_service.update_details(
        follow_up.follow_up_id,
        follow_up.revision,
        UpdateFollowUp(
            title="EXPORT-SIZINTI-TAKIP-BASLIGI-117",
            description="Kişisel takip ayrıntısı",
            item_type=FollowUpItemType.RECHECK,
            location="Özel mahal",
            related_person="Özel kişi",
            is_important=True,
            condition_text="Özel koşul",
            deadline_at="2026-07-14T06:00:00Z",
        ),
    )
    follow_up = follow_service.convert_to_observation(
        follow_up.follow_up_id,
        follow_up.revision,
        observation_id,
    )

    routine_ids = tracking_uuid_values(6000)
    routine_service = RoutineApplicationService(
        root / "cse.sqlite3",
        clock=lambda: "2026-07-13T09:30:00Z",
        uuid_factory=lambda: next(routine_ids),
    )
    template = routine_service.create_template(
        CreateRoutineTemplate(
            title="EXPORT-SIZINTI-RUTIN-BASLIGI-117",
            recurrence_type=RoutineRecurrenceType.DAILY,
            local_time="09:00",
            start_date="2026-07-12",
            description="Kişisel rutin ayrıntısı",
            is_important=True,
        )
    )
    occurrences = routine_service.ensure_occurrences("2026-07-13T09:30:00Z")
    today = next(
        occurrence
        for occurrence in occurrences
        if occurrence.occurrence_local_date == "2026-07-13"
    )
    today = routine_service.snooze_occurrence(
        today.routine_occurrence_id,
        today.revision,
        "2026-07-13T12:00:00Z",
    )
    today = routine_service.close_occurrence(
        today.routine_occurrence_id,
        today.revision,
        CloseRoutineOccurrence(
            RoutineOccurrenceOutcome.COMPLETED,
            "EXPORT-SIZINTI-OUTCOME-117",
        ),
    )
    today = routine_service.reopen_occurrence(
        today.routine_occurrence_id,
        today.revision,
        "2026-07-13T13:00:00Z",
    )
    return (
        follow_up.follow_up_id,
        template.routine_template_id,
        today.routine_occurrence_id,
    )


def test_daily_export_filters_utc_by_istanbul_date_and_manifests_hashes(
    tmp_path: Path,
) -> None:
    observation_id = seed_observation(tmp_path)
    exporter = DailyExportService(
        tmp_path,
        clock=lambda: "2026-07-13T10:00:00Z",
        uuid_factory=lambda: "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
    )
    artifact = exporter.build_daily_export("2026-07-13")

    assert artifact.record_count == 1
    with zipfile.ZipFile(artifact.path) as bundle:
        assert bundle.namelist() == [
            "observations.md",
            "observations.csv",
            "observations.json",
            "attachment_manifest.json",
            "export_manifest.json",
        ]
        markdown = bundle.read("observations.md").decode()
        csv_text = bundle.read("observations.csv").decode()
        records = json.loads(bundle.read("observations.json"))
        attachment_manifest = json.loads(bundle.read("attachment_manifest.json"))
        manifest = json.loads(bundle.read("export_manifest.json"))
        assert "Ornek \\| Santiye" in markdown
        assert observation_id in csv_text
        assert records[0]["observation_id"] == observation_id
        assert records[0]["observed_at_local"] == "2026-07-13T00:30:00+03:00"
        assert attachment_manifest[0]["verification_status"] == "valid"
        for name, expected in manifest["files"].items():
            data = bundle.read(name)
            assert hashlib.sha256(data).hexdigest() == expected["sha256"]
            assert len(data) == expected["size_bytes"]


def test_official_daily_export_is_byte_identical_with_private_tracking_data(
    tmp_path: Path,
) -> None:
    root_a = tmp_path / "official-only"
    root_b = tmp_path / "official-plus-tracking"
    observation_a = seed_observation(root_a)
    observation_b = seed_observation(root_b)
    assert observation_a == observation_b
    tracking_ids = seed_private_tracking(root_b, observation_b)
    output_a = tmp_path / "official-a.zip"
    output_b = tmp_path / "official-b.zip"
    deterministic_export = {
        "clock": lambda: "2026-07-13T10:00:00Z",
        "uuid_factory": lambda: "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
    }

    DailyExportService(root_a, **deterministic_export).build_daily_export(
        "2026-07-13", output_a
    )
    DailyExportService(root_b, **deterministic_export).build_daily_export(
        "2026-07-13", output_b
    )

    assert output_a.read_bytes() == output_b.read_bytes()
    expected_entries = [
        "observations.md",
        "observations.csv",
        "observations.json",
        "attachment_manifest.json",
        "export_manifest.json",
    ]
    with zipfile.ZipFile(output_a) as bundle_a, zipfile.ZipFile(output_b) as bundle_b:
        assert bundle_a.namelist() == bundle_b.namelist() == expected_entries
        manifest_a = json.loads(bundle_a.read("export_manifest.json"))
        manifest_b = json.loads(bundle_b.read("export_manifest.json"))
        assert manifest_a == manifest_b
        assert set(manifest_a) == {
            "format_version",
            "generated_at",
            "local_date",
            "record_count",
            "warning_count",
            "files",
        }
        assert manifest_a["format_version"] == 1
        assert manifest_a["record_count"] == 1
        assert manifest_a["warning_count"] == 0
        assert set(manifest_a["files"]) == set(expected_entries[:-1])
        combined_text = "\n".join(
            bundle_b.read(name).decode("utf-8", errors="ignore")
            for name in expected_entries
        )

    forbidden_tokens = (
        "EXPORT-SIZINTI-TAKIP-METNI-117",
        "EXPORT-SIZINTI-TAKIP-BASLIGI-117",
        "EXPORT-SIZINTI-RUTIN-BASLIGI-117",
        "EXPORT-SIZINTI-OUTCOME-117",
        "converted_to_observation",
        "follow_up.details_updated",
        "routine_occurrence.reopened",
        "follow_up_count",
        "routine_count",
        *tracking_ids,
    )
    assert all(token not in combined_text for token in forbidden_tokens)


def test_empty_day_export_is_valid_and_deterministic(tmp_path: Path) -> None:
    seed_observation(tmp_path)
    output_one = tmp_path / "one.zip"
    output_two = tmp_path / "two.zip"
    first = DailyExportService(
        tmp_path,
        clock=lambda: "2026-07-13T10:00:00Z",
        uuid_factory=lambda: "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
    )
    second = DailyExportService(
        tmp_path,
        clock=lambda: "2026-07-13T10:00:00Z",
        uuid_factory=lambda: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",
    )

    first.build_daily_export("2026-07-14", output_one)
    second.build_daily_export("2026-07-14", output_two)

    assert output_one.read_bytes() == output_two.read_bytes()
    assert read_zip_json(output_one, "observations.json") == []
    assert read_zip_json(output_one, "export_manifest.json")["record_count"] == 0


def test_daily_export_includes_edited_details_revision_and_event(tmp_path: Path) -> None:
    ids = iter(
        [
            "11111111-1111-4111-8111-111111111111",
            "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
            "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        ]
    )
    times = iter(
        [
            "2026-07-13T08:00:00Z",
            "2026-07-13T09:00:00Z",
            "2026-07-13T10:00:00Z",
        ]
    )
    service = ObservationApplicationService(
        tmp_path / "cse.sqlite3",
        ManagedAttachmentStore(tmp_path / "attachments"),
        clock=lambda: next(times),
        uuid_factory=lambda: next(ids),
    )
    project = service.create_project("Örnek")
    observation = service.create_observation(
        CreateObservation(
            project_id=project.project_id,
            location="A",
            category="quality",
            description="Eski açıklama",
        )
    )
    service.update_observation_details(
        observation.observation_id,
        1,
        "B",
        "safety",
        "Yeni açıklama",
        "Yeni not",
    )

    artifact = DailyExportService(
        tmp_path,
        clock=lambda: "2026-07-13T11:00:00Z",
        uuid_factory=lambda: "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
    ).build_daily_export("2026-07-13")
    records = read_zip_json(artifact.path, "observations.json")

    assert records[0]["location"] == "B"
    assert records[0]["category"] == "safety"
    assert records[0]["description"] == "Yeni açıklama"
    assert records[0]["notes"] == "Yeni not"
    assert records[0]["revision"] == 2
    assert records[0]["event_types"] == [
        "observation_created",
        "observation_details_updated",
    ]


def test_export_write_or_rename_failure_leaves_no_final(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    seed_observation(tmp_path)
    output = tmp_path / "daily.zip"
    exporter = DailyExportService(tmp_path)
    monkeypatch.setattr(
        exporter,
        "_atomic_move",
        lambda *_: (_ for _ in ()).throw(OSError("rename failed")),
    )

    with pytest.raises(Exception):
        exporter.build_daily_export("2026-07-13", output)

    assert not output.exists()

    write_output = tmp_path / "write-failed.zip"
    write_exporter = DailyExportService(tmp_path)
    monkeypatch.setattr(
        write_exporter,
        "_write_archive",
        lambda *_: (_ for _ in ()).throw(OSError("write failed")),
    )
    with pytest.raises(Exception):
        write_exporter.build_daily_export("2026-07-13", write_output)
    assert not write_output.exists()

    hash_output = tmp_path / "hash-failed.zip"
    hash_exporter = DailyExportService(tmp_path)
    monkeypatch.setattr(
        hash_exporter,
        "_verify_archive",
        lambda *_: (_ for _ in ()).throw(ValueError("hash failed")),
    )
    with pytest.raises(Exception):
        hash_exporter.build_daily_export("2026-07-13", hash_output)
    assert not hash_output.exists()
