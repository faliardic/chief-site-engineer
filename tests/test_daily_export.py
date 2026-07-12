import hashlib
import io
import json
import zipfile
from pathlib import Path

import pytest

from app.application import ObservationApplicationService, UploadStream
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
        project.project_id,
        "A Blok",
        "quality",
        "Kalip | kontrolu\nikinci satir",
        "Not",
        UploadStream(io.BytesIO(b"photo-bytes"), "saha.jpg"),
    )
    return observation.observation_id


def read_zip_json(archive: Path, name: str) -> object:
    with zipfile.ZipFile(archive) as bundle:
        return json.loads(bundle.read(name))


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
