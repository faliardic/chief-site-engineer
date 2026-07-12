import io
from pathlib import Path

import pytest

from app.application import (
    ApplicationServiceError,
    ObservationApplicationService,
    UploadStream,
)
from app.persistence import InvalidRecordError, RevisionConflict, SQLiteUnitOfWork
from app.persistence.repositories import (
    SQLiteAttachmentMetadataRepository,
    SQLiteObservationEventRepository,
)
from app.storage import AttachmentIOError, ManagedAttachmentStore


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
ATTACHMENT_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
EVENT_IDS = [
    "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
    "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
    "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",
    "ffffffff-ffff-4fff-8fff-ffffffffffff",
]
def make_service(tmp_path: Path, ids: list[str]) -> ObservationApplicationService:
    values = iter(ids)
    return ObservationApplicationService(
        tmp_path / "cse.sqlite3",
        ManagedAttachmentStore(tmp_path / "attachments"),
        clock=lambda: "2026-07-13T09:00:00Z",
        uuid_factory=lambda: next(values),
        local_actor="Santiye sefi",
    )


def test_project_and_observation_persist_with_created_event(tmp_path: Path) -> None:
    service = make_service(tmp_path, [PROJECT_ID, OBSERVATION_ID, EVENT_IDS[0]])
    project = service.create_project("Ornek Santiye")
    observation = service.create_observation(
        project.project_id, "A Blok", "quality", "Kalip kontrolu", "Not", None
    )

    reopened = ObservationApplicationService(
        tmp_path / "cse.sqlite3",
        ManagedAttachmentStore(tmp_path / "attachments"),
    )
    detail = reopened.get_observation_detail(observation.observation_id)

    assert reopened.list_projects() == [project]
    assert detail.observation.description == "Kalip kontrolu"
    assert detail.events[0].event_type == "observation_created"
    assert detail.events[0].payload == {
        "attachment_ids": [], "revision": 1, "status": "open"
    }


def test_stream_upload_finalize_metadata_and_reopen_verify_valid(tmp_path: Path) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]]
    )
    service.create_project("Ornek Santiye")
    observation = service.create_observation(
        PROJECT_ID,
        "A Blok",
        "quality",
        "Fotografli kontrol",
        None,
        UploadStream(io.BytesIO(b"real-photo-bytes"), "../../saha.JPG"),
    )

    reopened = ObservationApplicationService(
        tmp_path / "cse.sqlite3",
        ManagedAttachmentStore(tmp_path / "attachments"),
    )
    detail = reopened.get_observation_detail(observation.observation_id)

    assert len(detail.attachments) == 1
    assert detail.attachments[0].verification.status == "valid"
    assert detail.events[0].payload["attachment_ids"] == [ATTACHMENT_ID]
    with reopened.open_attachment(ATTACHMENT_ID) as file_handle:
        assert file_handle.read() == b"real-photo-bytes"


def test_status_reporting_archive_create_atomic_events_and_no_op(tmp_path: Path) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, *EVENT_IDS]
    )
    service.create_project("Ornek Santiye")
    service.create_observation(PROJECT_ID, "A", "safety", "Kontrol", None, None)
    tracking = service.update_status(OBSERVATION_ID, 1, "tracking")
    same = service.update_status(OBSERVATION_ID, 2, "tracking")
    reported = service.update_reporting(
        OBSERVATION_ID, 2, "Saha formeni", "2026-07-13T10:00:00Z"
    )
    archived = service.archive_observation(OBSERVATION_ID, 3)
    detail = service.get_observation_detail(OBSERVATION_ID)

    assert tracking.revision == same.revision == 2
    assert reported.revision == 3
    assert archived.revision == 4
    assert [event.event_type for event in detail.events] == [
        "observation_created",
        "observation_status_changed",
        "observation_reporting_updated",
        "observation_archived",
    ]
    assert detail.events[1].payload == {
        "from": "open", "revision": 2, "to": "tracking"
    }


def test_stale_revision_leaves_record_and_events_unchanged(tmp_path: Path) -> None:
    service = make_service(tmp_path, [PROJECT_ID, OBSERVATION_ID, EVENT_IDS[0]])
    service.create_project("Ornek")
    service.create_observation(PROJECT_ID, "A", "quality", "Kontrol", None, None)

    with pytest.raises(RevisionConflict):
        service.update_status(OBSERVATION_ID, 99, "tracking")

    detail = service.get_observation_detail(OBSERVATION_ID)
    assert detail.observation.revision == 1
    assert len(detail.events) == 1


def test_finalize_failure_rolls_back_db_and_leaves_stale_staging(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]]
    )
    service.create_project("Ornek")
    monkeypatch.setattr(
        service.attachment_store,
        "_atomic_move",
        lambda *_: (_ for _ in ()).throw(OSError("rename failed")),
    )

    with pytest.raises(Exception) as error:
        service.create_observation(
            PROJECT_ID, "A", "quality", "Kontrol", None,
            UploadStream(io.BytesIO(b"data"), "photo.jpg"),
        )

    assert error.value.reconciliation_required is True
    with SQLiteUnitOfWork(tmp_path / "cse.sqlite3") as unit_of_work:
        assert unit_of_work.observations.list_all() == []
        report = service.attachment_store.reconcile(unit_of_work.attachments.list_all())
    assert report.stale_staging_files


def test_stage_failure_starts_no_database_mutation(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]]
    )
    service.create_project("Ornek")
    monkeypatch.setattr(
        service.attachment_store,
        "_read_chunk",
        lambda *_: (_ for _ in ()).throw(OSError("read failed")),
    )

    with pytest.raises(AttachmentIOError):
        service.create_observation(
            PROJECT_ID, "A", "quality", "Kontrol", None,
            UploadStream(io.BytesIO(b"data"), "photo.jpg"),
        )

    with SQLiteUnitOfWork(tmp_path / "cse.sqlite3") as unit_of_work:
        assert unit_of_work.observations.list_all() == []
        assert unit_of_work.attachments.list_all() == []


def test_metadata_failure_rolls_back_and_discards_staging(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]]
    )
    service.create_project("Ornek")
    monkeypatch.setattr(
        SQLiteAttachmentMetadataRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("injected")),
    )

    with pytest.raises(ApplicationServiceError) as error:
        service.create_observation(
            PROJECT_ID, "A", "quality", "Kontrol", None,
            UploadStream(io.BytesIO(b"data"), "photo.jpg"),
        )

    assert error.value.reconciliation_required is False
    assert service.attachment_store.reconcile([]).stale_staging_files == ()
    with SQLiteUnitOfWork(tmp_path / "cse.sqlite3") as unit_of_work:
        assert unit_of_work.observations.list_all() == []


def test_cleanup_failure_is_explicit_and_staging_remains(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]]
    )
    service.create_project("Ornek")
    monkeypatch.setattr(
        SQLiteAttachmentMetadataRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("injected")),
    )
    monkeypatch.setattr(
        service.attachment_store,
        "discard_staged",
        lambda *_: (_ for _ in ()).throw(AttachmentIOError("cleanup failed")),
    )

    with pytest.raises(ApplicationServiceError) as error:
        service.create_observation(
            PROJECT_ID, "A", "quality", "Kontrol", None,
            UploadStream(io.BytesIO(b"data"), "photo.jpg"),
        )

    assert error.value.reconciliation_required is True
    assert error.value.staging_relative_path is not None
    assert service.attachment_store.reconcile([]).stale_staging_files


def test_created_event_failure_rolls_back_metadata_and_discards_staging(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]]
    )
    service.create_project("Ornek")
    monkeypatch.setattr(
        SQLiteObservationEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )

    with pytest.raises(ApplicationServiceError):
        service.create_observation(
            PROJECT_ID, "A", "quality", "Kontrol", None,
            UploadStream(io.BytesIO(b"data"), "photo.jpg"),
        )

    assert service.attachment_store.reconcile([]).stale_staging_files == ()
    with SQLiteUnitOfWork(tmp_path / "cse.sqlite3") as unit_of_work:
        assert unit_of_work.observations.list_all() == []
        assert unit_of_work.attachments.list_all() == []


def test_commit_failure_after_finalize_reports_orphan(tmp_path: Path) -> None:
    normal = make_service(tmp_path, [PROJECT_ID])
    normal.create_project("Ornek")

    class CommitFailingUnitOfWork(SQLiteUnitOfWork):
        def commit(self) -> None:
            raise OSError("commit failed")

    ids = iter([OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]])
    store = ManagedAttachmentStore(tmp_path / "attachments")
    service = ObservationApplicationService(
        tmp_path / "cse.sqlite3",
        store,
        uow_factory=lambda: CommitFailingUnitOfWork(tmp_path / "cse.sqlite3"),
        clock=lambda: "2026-07-13T09:00:00Z",
        uuid_factory=lambda: next(ids),
    )

    with pytest.raises(ApplicationServiceError) as error:
        service.create_observation(
            PROJECT_ID, "A", "quality", "Kontrol", None,
            UploadStream(io.BytesIO(b"data"), "photo.jpg"),
        )

    assert error.value.reconciliation_required is True
    assert error.value.final_relative_path is not None
    with SQLiteUnitOfWork(tmp_path / "cse.sqlite3") as unit_of_work:
        assert unit_of_work.observations.list_all() == []
        report = store.reconcile(unit_of_work.attachments.list_all())
    assert report.orphan_finalized_files == (error.value.final_relative_path,)


def test_stream_fsync_failure_leaves_no_staging_or_database_rows(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    service = make_service(
        tmp_path, [PROJECT_ID, OBSERVATION_ID, ATTACHMENT_ID, EVENT_IDS[0]]
    )
    service.create_project("Ornek")
    monkeypatch.setattr(
        service.attachment_store,
        "_flush_and_sync",
        lambda *_: (_ for _ in ()).throw(OSError("fsync failed")),
    )

    with pytest.raises(AttachmentIOError):
        service.create_observation(
            PROJECT_ID, "A", "quality", "Kontrol", None,
            UploadStream(io.BytesIO(b"data"), "photo.jpg"),
        )

    assert service.attachment_store.reconcile([]).stale_staging_files == ()
