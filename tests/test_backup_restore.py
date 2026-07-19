import hashlib
import io
import json
import sqlite3
import stat
import zipfile
from pathlib import Path
from uuid import UUID

import pytest

import app.operations.backups as backups_module
from app.application import (
    CloseRoutineOccurrence,
    CreateFollowUp,
    CreateObservation,
    CreateRoutineTemplate,
    FollowUpApplicationService,
    ObservationApplicationService,
    RoutineApplicationService,
    RoutineOccurrenceQuery,
    UpdateFollowUp,
    UploadStream,
)
from app.field_tracking import (
    FollowUpItemType,
    RoutineOccurrenceOutcome,
    RoutineRecurrenceType,
)
from app.operations import BackupService, BackupValidationError
from app.operations.backups import RESTORABLE_SCHEMA_VERSIONS
from app.operations.common import digest_file
from app.persistence import (
    Migration,
    SCHEMA_MIGRATIONS,
    SCHEMA_VERSION,
    SQLiteUnitOfWork,
    connect_database,
    migrate_database,
)
from app.storage import ManagedAttachmentStore
from app.web import create_app


IDS = iter(
    [
        "11111111-1111-4111-8111-111111111111",
        "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
        "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
    ]
)

PROJECT_ID = "10000000-0000-4000-8000-000000000001"
OBSERVATION_ID = "20000000-0000-4000-8000-000000000002"
ATTACHMENT_ID = "30000000-0000-4000-8000-000000000003"
OBSERVATION_EVENT_ID = "40000000-0000-4000-8000-000000000004"
FOLLOW_UP_ID = "50000000-0000-4000-8000-000000000005"
FOLLOW_UP_EVENT_ID = "60000000-0000-4000-8000-000000000006"
TEMPLATE_ID = "70000000-0000-4000-8000-000000000007"
TEMPLATE_EVENT_ID = "80000000-0000-4000-8000-000000000008"
OCCURRENCE_ID = "90000000-0000-4000-8000-000000000009"
OCCURRENCE_EVENT_ONE_ID = "a0000000-0000-4000-8000-00000000000a"
OCCURRENCE_EVENT_TWO_ID = "b0000000-0000-4000-8000-00000000000b"
LEGACY_TIMESTAMP = "2026-07-15T06:00:00Z"
LEGACY_FOLLOW_UP_PAYLOAD = '{ "title": "Kalıp", "revision": 1 }'

BACKUP_MANIFEST_KEYS = {
    "backup_format_version",
    "created_at",
    "schema_version",
    "attachment_count",
    "observation_count",
    "event_count",
    "files",
    "attachments",
}
TRACKING_TABLES = (
    "follow_up_items",
    "follow_up_events",
    "routine_templates",
    "routine_template_weekdays",
    "routine_occurrences",
    "routine_template_events",
    "routine_occurrence_events",
)


def deterministic_uuid(number: int) -> str:
    return str(UUID(int=number, version=4))


def uuid_values(start: int):
    number = start
    while True:
        yield deterministic_uuid(number)
        number += 1


def create_legacy_root(root: Path, schema_version: int) -> None:
    assert schema_version in (2, 3)
    database = root / "cse.sqlite3"
    root.mkdir(parents=True)
    connection = connect_database(database)
    try:
        migrate_database(
            connection,
            migrations=SCHEMA_MIGRATIONS[:schema_version],
        )
        connection.execute(
            "INSERT INTO projects (id, name, created_at) VALUES (?, ?, ?)",
            (PROJECT_ID, "Legacy Şantiye", LEGACY_TIMESTAMP),
        )
        connection.execute(
            """
            INSERT INTO field_observations (
                id, project_id, observed_at, location, category, description,
                status, created_at, updated_at, revision, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                OBSERVATION_ID,
                PROJECT_ID,
                LEGACY_TIMESTAMP,
                "A Blok",
                "quality",
                "Legacy gözlem metni",
                "open",
                LEGACY_TIMESTAMP,
                LEGACY_TIMESTAMP,
                1,
                "Legacy not",
            ),
        )
        attachment_content = b"legacy-schema-attachment"
        stored_relative_path = (
            f"attachments/{OBSERVATION_ID}/{ATTACHMENT_ID}.jpg"
        )
        attachment_file = root / "attachments" / Path(
            *stored_relative_path.split("/")
        )
        attachment_file.parent.mkdir(parents=True)
        attachment_file.write_bytes(attachment_content)
        connection.execute(
            """
            INSERT INTO attachments (
                id, observation_id, original_name, stored_relative_path,
                sha256, size_bytes, mime_type, status, created_at, created_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                ATTACHMENT_ID,
                OBSERVATION_ID,
                "legacy.jpg",
                stored_relative_path,
                hashlib.sha256(attachment_content).hexdigest(),
                len(attachment_content),
                "image/jpeg",
                "active",
                LEGACY_TIMESTAMP,
                "legacy-user",
            ),
        )
        connection.execute(
            """
            INSERT INTO observation_events (
                id, observation_id, event_type, actor, occurred_at, payload_json
            ) VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                OBSERVATION_EVENT_ID,
                OBSERVATION_ID,
                "observation_created",
                "legacy-user",
                LEGACY_TIMESTAMP,
                '{ "description": "aynen koru", "revision": 1 }',
            ),
        )
        if schema_version == 3:
            _insert_schema_three_tracking(connection)
    finally:
        connection.close()


def _insert_schema_three_tracking(connection: sqlite3.Connection) -> None:
    connection.execute(
        """
        INSERT INTO follow_up_items (
            id, capture_text, title, description, item_type, status,
            project_id, observation_id, is_important, next_attention_at,
            revision, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            FOLLOW_UP_ID,
            "Legacy takibi unutma",
            "Legacy takip",
            "Schema 3 ayrıntısı",
            "recheck",
            "active",
            PROJECT_ID,
            OBSERVATION_ID,
            1,
            "2026-07-16T06:00:00Z",
            1,
            LEGACY_TIMESTAMP,
            LEGACY_TIMESTAMP,
        ),
    )
    connection.execute(
        """
        INSERT INTO follow_up_events (
            id, follow_up_id, sequence, event_type, actor, occurred_at,
            payload_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            FOLLOW_UP_EVENT_ID,
            FOLLOW_UP_ID,
            1,
            "follow_up.created",
            "legacy-user",
            LEGACY_TIMESTAMP,
            LEGACY_FOLLOW_UP_PAYLOAD,
        ),
    )
    connection.execute(
        """
        INSERT INTO routine_templates (
            id, title, description, project_id, recurrence_type, local_time,
            timezone, month_day, start_date, end_date, status, is_important,
            revision, created_at, updated_at, deactivated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            TEMPLATE_ID,
            "Legacy günlük rutin",
            "Schema 3 rutin ayrıntısı",
            PROJECT_ID,
            "daily",
            "09:00",
            "Europe/Istanbul",
            None,
            "2026-07-15",
            None,
            "active",
            1,
            1,
            LEGACY_TIMESTAMP,
            LEGACY_TIMESTAMP,
            None,
        ),
    )
    connection.execute(
        """
        INSERT INTO routine_template_events (
            id, routine_template_id, sequence, event_type, actor, occurred_at,
            payload_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            TEMPLATE_EVENT_ID,
            TEMPLATE_ID,
            1,
            "routine_template.created",
            "legacy-user",
            LEGACY_TIMESTAMP,
            '{ "revision": 1, "status": "active" }',
        ),
    )
    connection.execute(
        """
        INSERT INTO routine_occurrences (
            id, routine_template_id, occurrence_local_date,
            scheduled_local_time, scheduled_at_utc, status,
            next_attention_at, outcome_type, outcome_note, revision,
            created_at, completed_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            OCCURRENCE_ID,
            TEMPLATE_ID,
            "2026-07-15",
            "09:00",
            "2026-07-15T06:00:00Z",
            "closed",
            "2026-07-15T06:00:00Z",
            "missed",
            None,
            2,
            LEGACY_TIMESTAMP,
            "2026-07-16T06:00:00Z",
        ),
    )
    for values in (
        (
            OCCURRENCE_EVENT_ONE_ID,
            1,
            "routine_occurrence.created",
            '{ "revision": 1, "status": "open" }',
        ),
        (
            OCCURRENCE_EVENT_TWO_ID,
            2,
            "routine_occurrence.missed",
            '{ "outcome_type": "missed", "revision": 2 }',
        ),
    ):
        connection.execute(
            """
            INSERT INTO routine_occurrence_events (
                id, routine_occurrence_id, sequence, event_type, actor,
                occurred_at, payload_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                values[0],
                OCCURRENCE_ID,
                values[1],
                values[2],
                "legacy-user",
                LEGACY_TIMESTAMP,
                values[3],
            ),
        )


def build_backup_fixture(
    root: Path,
    archive: Path,
    *,
    schema_version: int,
) -> dict[str, object]:
    database = root / "cse.sqlite3"
    connection = sqlite3.connect(database)
    try:
        attachment_rows = list(
            connection.execute(
                "SELECT stored_relative_path FROM attachments ORDER BY id"
            )
        )
        observation_count = connection.execute(
            "SELECT COUNT(*) FROM field_observations"
        ).fetchone()[0]
        event_count = connection.execute(
            "SELECT COUNT(*) FROM observation_events"
        ).fetchone()[0]
    finally:
        connection.close()
    attachments = []
    files = {"cse.sqlite3": digest_file(database)}
    for (relative_path,) in attachment_rows:
        source = root / "attachments" / Path(*relative_path.split("/"))
        digest = digest_file(source)
        attachments.append((relative_path, source, digest))
        files[relative_path] = digest
    manifest = {
        "backup_format_version": 1,
        "created_at": "2026-07-16T10:00:00Z",
        "schema_version": schema_version,
        "attachment_count": len(attachments),
        "observation_count": observation_count,
        "event_count": event_count,
        "files": files,
        "attachments": [
            {"path": relative_path, **digest}
            for relative_path, _source, digest in attachments
        ],
    }
    BackupService(root)._write_backup_archive(
        archive,
        database,
        attachments,
        manifest,
    )
    return manifest


def rewrite_manifest(source: Path, target: Path, update) -> None:
    def mutate(info: zipfile.ZipInfo, data: bytes):
        if info.filename == "manifest.json":
            manifest = json.loads(data)
            update(manifest)
            data = json.dumps(
                manifest,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8") + b"\n"
        return info.filename, data, info

    rewrite_zip(source, target, mutate)


def table_rows(database: Path, tables: tuple[str, ...]) -> dict[str, list[tuple]]:
    connection = sqlite3.connect(database)
    try:
        return {
            table: list(connection.execute(f"SELECT * FROM {table} ORDER BY rowid"))
            for table in tables
        }
    finally:
        connection.close()


def seed(root: Path) -> tuple[str, str]:
    ids = iter(
        [
            "11111111-1111-4111-8111-111111111111",
            "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
            "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        ]
    )
    service = ObservationApplicationService(
        root / "cse.sqlite3",
        ManagedAttachmentStore(root / "attachments"),
        clock=lambda: "2026-07-13T09:00:00Z",
        uuid_factory=lambda: next(ids),
    )
    project = service.create_project("Ornek")
    observation = service.create_observation(
        CreateObservation(
            project_id=project.project_id,
            location="A",
            category="quality",
            description="Kontrol",
            upload=UploadStream(io.BytesIO(b"backup-photo"), "photo.jpg"),
        )
    )
    detail = service.get_observation_detail(observation.observation_id)
    return observation.observation_id, detail.attachments[0].metadata.attachment_id


def rewrite_zip(source: Path, target: Path, mutate) -> None:
    with zipfile.ZipFile(source) as incoming, zipfile.ZipFile(target, "w") as outgoing:
        for info in incoming.infolist():
            name, data, changed_info = mutate(info, incoming.read(info.filename))
            outgoing.writestr(changed_info or name, data)


def test_backup_online_snapshot_verify_restore_and_reopen(tmp_path: Path) -> None:
    source = tmp_path / "source"
    observation_id, attachment_id = seed(source)
    source_files = sorted(path for path in source.rglob("*") if path.is_file())
    before = {
        path.relative_to(source).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in source_files
    }
    archive = tmp_path / "field.csebackup.zip"
    backup = BackupService(source, clock=lambda: "2026-07-13T10:00:00Z")

    result = backup.create_backup(archive)
    manifest = backup.verify_backup(archive)
    target = tmp_path / "restored"
    restored = backup.restore_backup(archive, target)

    assert result.attachment_count == 1
    assert manifest["schema_version"] == SCHEMA_VERSION
    assert restored.target_created is True
    service = ObservationApplicationService(
        target / "cse.sqlite3", ManagedAttachmentStore(target / "attachments")
    )
    detail = service.get_observation_detail(observation_id)
    assert detail.attachments[0].verification.status == "valid"
    with service.open_attachment(attachment_id) as file_handle:
        assert file_handle.read() == b"backup-photo"
    client = create_app(target).test_client()
    assert client.get(f"/observations/{observation_id}").status_code == 200
    assert client.get(f"/attachments/{attachment_id}").data == b"backup-photo"
    after = {
        path.relative_to(source).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(path for path in source.rglob("*") if path.is_file())
    }
    assert after == before


def test_backup_restore_preserves_edited_revision_and_event(tmp_path: Path) -> None:
    source = tmp_path / "edited-source"
    ids = iter(
        [
            "11111111-1111-4111-8111-111111111111",
            "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
            "ffffffff-ffff-4fff-8fff-ffffffffffff",
            "00000000-0000-4000-8000-000000000000",
        ]
    )
    service = ObservationApplicationService(
        source / "cse.sqlite3",
        ManagedAttachmentStore(source / "attachments"),
        clock=lambda: "2026-07-13T09:00:00Z",
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

    archive = tmp_path / "edited.csebackup.zip"
    backup = BackupService(source, clock=lambda: "2026-07-13T10:00:00Z")
    result = backup.create_backup(archive)
    target = tmp_path / "edited-restored"
    backup.restore_backup(archive, target)
    restored = ObservationApplicationService(
        target / "cse.sqlite3", ManagedAttachmentStore(target / "attachments")
    ).get_observation_detail(observation.observation_id)

    assert result.observation_count == 1
    assert result.event_count == 2
    assert restored.observation.location == "B"
    assert restored.observation.category == "safety"
    assert restored.observation.description == "Yeni açıklama"
    assert restored.observation.notes == "Yeni not"
    assert restored.observation.revision == 2
    assert [event.event_type for event in restored.events] == [
        "observation_created",
        "observation_details_updated",
    ]
    assert restored.events[-1].event_type == "observation_details_updated"
    assert restored.events[-1].payload == {
        "changed_fields": ["location", "category", "description", "notes"],
        "revision": 2,
    }


def test_restorable_schema_allowlist_and_manifest_contract_stay_version_one(
    tmp_path: Path,
) -> None:
    source = tmp_path / "source"
    seed(source)
    archive = tmp_path / "current.zip"
    manifest = BackupService(source).create_backup(archive)
    verified = BackupService(source).verify_backup(archive)

    assert RESTORABLE_SCHEMA_VERSIONS == (2, 3, 4)
    assert verified["backup_format_version"] == 1
    assert verified["schema_version"] == 4
    assert set(verified) == BACKUP_MANIFEST_KEYS
    assert manifest.observation_count == 1
    assert "follow_up_count" not in verified
    assert "routine_count" not in verified


def test_schema_two_backup_restores_to_schema_four_without_changing_source(
    tmp_path: Path,
) -> None:
    source = tmp_path / "schema-two-source"
    create_legacy_root(source, 2)
    archive = tmp_path / "schema-two.zip"
    expected_manifest = build_backup_fixture(source, archive, schema_version=2)
    official_tables = (
        "projects",
        "field_observations",
        "attachments",
        "observation_events",
    )
    rows_before = table_rows(source / "cse.sqlite3", official_tables)
    source_hash_before = digest_file(source / "cse.sqlite3")
    archive_hash_before = digest_file(archive)
    backup = BackupService(source)

    assert backup.verify_backup(archive) == expected_manifest
    target = tmp_path / "schema-two-restored"
    backup.restore_backup(archive, target)

    connection = sqlite3.connect(target / "cse.sqlite3")
    try:
        versions = [
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        ]
        tracking_counts = {
            table: connection.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            for table in TRACKING_TABLES
        }
    finally:
        connection.close()
    assert versions == [1, 2, 3, 4]
    assert set(tracking_counts.values()) == {0}
    assert table_rows(target / "cse.sqlite3", official_tables) == rows_before
    assert digest_file(source / "cse.sqlite3") == source_hash_before
    assert digest_file(archive) == archive_hash_before

    observation_service = ObservationApplicationService(
        target / "cse.sqlite3",
        ManagedAttachmentStore(target / "attachments"),
    )
    detail = observation_service.get_observation_detail(OBSERVATION_ID)
    assert detail.observation.notes == "Legacy not"
    assert detail.events[0].payload_json == (
        '{ "description": "aynen koru", "revision": 1 }'
    )
    assert detail.attachments[0].verification.status == "valid"
    with observation_service.open_attachment(ATTACHMENT_ID) as file_handle:
        assert file_handle.read() == b"legacy-schema-attachment"
    client = create_app(target).test_client()
    assert client.get(f"/observations/{OBSERVATION_ID}").status_code == 200


def test_new_backup_creation_still_requires_current_schema(tmp_path: Path) -> None:
    source = tmp_path / "schema-three-source"
    create_legacy_root(source, 3)
    output = tmp_path / "must-not-be-created.zip"

    with pytest.raises(BackupValidationError, match="schema version"):
        BackupService(source).create_backup(output)

    assert not output.exists()


def test_schema_three_backup_migrates_only_v4_and_preserves_tracking_payloads(
    tmp_path: Path,
) -> None:
    source = tmp_path / "schema-three-source"
    create_legacy_root(source, 3)
    archive = tmp_path / "schema-three.zip"
    build_backup_fixture(source, archive, schema_version=3)
    tracking_before = table_rows(source / "cse.sqlite3", TRACKING_TABLES)
    archive_hash_before = digest_file(archive)
    target = tmp_path / "schema-three-restored"

    BackupService(source).restore_backup(archive, target)

    connection = sqlite3.connect(target / "cse.sqlite3")
    try:
        versions = [
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        ]
        payload_after = connection.execute(
            "SELECT payload_json FROM follow_up_events WHERE id = ?",
            (FOLLOW_UP_EVENT_ID,),
        ).fetchone()[0]
    finally:
        connection.close()
    assert versions == [1, 2, 3, 4]
    assert table_rows(target / "cse.sqlite3", TRACKING_TABLES) == tracking_before
    assert payload_after == LEGACY_FOLLOW_UP_PAYLOAD
    assert digest_file(archive) == archive_hash_before

    with SQLiteUnitOfWork(target / "cse.sqlite3") as unit_of_work:
        assert unit_of_work.follow_ups.get(FOLLOW_UP_ID).title == "Legacy takip"
        assert [
            event.event_type.value
            for event in unit_of_work.follow_up_events.list_for_follow_up(
                FOLLOW_UP_ID
            )
        ] == ["follow_up.created"]
        assert unit_of_work.routine_templates.get(TEMPLATE_ID).title == (
            "Legacy günlük rutin"
        )
        occurrence = unit_of_work.routine_occurrences.get(OCCURRENCE_ID)
        assert occurrence.outcome_type == RoutineOccurrenceOutcome.MISSED
        assert [
            event.sequence
            for event in unit_of_work.routine_occurrence_events.list_for_occurrence(
                OCCURRENCE_ID
            )
        ] == [1, 2]


def test_schema_four_tracking_round_trip_preserves_aggregates_and_histories(
    tmp_path: Path,
) -> None:
    source = tmp_path / "schema-four-source"
    observation_id, _attachment_id = seed(source)
    follow_ids = uuid_values(1000)
    follow_service = FollowUpApplicationService(
        source / "cse.sqlite3",
        clock=lambda: "2026-07-16T10:00:00Z",
        uuid_factory=lambda: next(follow_ids),
    )
    follow_up = follow_service.create_follow_up(
        CreateFollowUp("Özel takip metni 117")
    )
    follow_up = follow_service.update_details(
        follow_up.follow_up_id,
        follow_up.revision,
        UpdateFollowUp(
            title="Özel takip başlığı 117",
            description="Backup ile korunacak takip ayrıntısı",
            item_type=FollowUpItemType.RECHECK,
            location="B Blok",
            related_person="Ahmet",
            is_important=True,
            condition_text="Beton öncesi",
            deadline_at="2026-07-17T06:00:00Z",
        ),
    )
    follow_up = follow_service.convert_to_observation(
        follow_up.follow_up_id,
        follow_up.revision,
        observation_id,
    )

    routine_ids = uuid_values(2000)
    routine_service = RoutineApplicationService(
        source / "cse.sqlite3",
        clock=lambda: "2026-07-16T10:00:00Z",
        uuid_factory=lambda: next(routine_ids),
    )
    template = routine_service.create_template(
        CreateRoutineTemplate(
            title="Özel rutin başlığı 117",
            recurrence_type=RoutineRecurrenceType.DAILY,
            local_time="09:00",
            start_date="2026-07-15",
            description="Backup rutin ayrıntısı",
            is_important=True,
        )
    )
    occurrences = routine_service.ensure_occurrences("2026-07-16T10:00:00Z")
    missed = next(
        item for item in occurrences if item.occurrence_local_date == "2026-07-15"
    )
    today = next(
        item for item in occurrences if item.occurrence_local_date == "2026-07-16"
    )
    today = routine_service.snooze_occurrence(
        today.routine_occurrence_id,
        today.revision,
        "2026-07-16T15:00:00Z",
    )
    today = routine_service.close_occurrence(
        today.routine_occurrence_id,
        today.revision,
        CloseRoutineOccurrence(
            RoutineOccurrenceOutcome.COMPLETED,
            "Kullanıcı kapattı",
        ),
    )
    today = routine_service.reopen_occurrence(
        today.routine_occurrence_id,
        today.revision,
        "2026-07-16T16:00:00Z",
    )
    tracking_before = table_rows(source / "cse.sqlite3", TRACKING_TABLES)
    archive = tmp_path / "schema-four.zip"
    backup = BackupService(source, clock=lambda: "2026-07-16T11:00:00Z")
    first_manifest = backup.verify_backup(backup.create_backup(archive).path)
    target = tmp_path / "schema-four-restored"

    backup.restore_backup(archive, target)

    assert table_rows(target / "cse.sqlite3", TRACKING_TABLES) == tracking_before
    restored_follow_service = FollowUpApplicationService(target / "cse.sqlite3")
    assert restored_follow_service.get_follow_up(follow_up.follow_up_id) == follow_up
    assert [
        event.sequence
        for event in restored_follow_service.list_history(follow_up.follow_up_id)
    ] == [1, 2, 3]
    restored_routine_service = RoutineApplicationService(target / "cse.sqlite3")
    assert restored_routine_service.get_template(template.routine_template_id) == template
    assert restored_routine_service.list_occurrence_history(
        missed.routine_occurrence_id
    ) == routine_service.list_occurrence_history(missed.routine_occurrence_id)
    assert restored_routine_service.list_occurrence_history(
        today.routine_occurrence_id
    ) == routine_service.list_occurrence_history(today.routine_occurrence_id)
    occurrence_query = RoutineOccurrenceQuery(
        routine_template_id=template.routine_template_id
    )
    assert restored_routine_service.list_occurrences(
        occurrence_query
    ) == routine_service.list_occurrences(occurrence_query)

    second_archive = tmp_path / "schema-four-second.zip"
    second_backup = BackupService(
        target,
        clock=lambda: "2026-07-16T11:00:00Z",
    )
    second_backup.create_backup(second_archive)
    second_manifest = second_backup.verify_backup(second_archive)
    assert first_manifest["backup_format_version"] == 1
    assert second_manifest["backup_format_version"] == 1
    assert set(first_manifest) == set(second_manifest) == BACKUP_MANIFEST_KEYS
    assert first_manifest["observation_count"] == second_manifest["observation_count"]
    assert first_manifest["event_count"] == second_manifest["event_count"]


@pytest.mark.parametrize("schema_version", [1, 0, -1, True, 5])
def test_non_restorable_or_boolean_manifest_schema_is_rejected(
    tmp_path: Path,
    schema_version: object,
) -> None:
    source = tmp_path / "source"
    seed(source)
    valid = tmp_path / "valid.zip"
    BackupService(source).create_backup(valid)
    invalid = tmp_path / f"invalid-{schema_version!s}.zip"
    rewrite_manifest(
        valid,
        invalid,
        lambda manifest: manifest.__setitem__("schema_version", schema_version),
    )

    with pytest.raises(BackupValidationError, match="schema version"):
        BackupService(source).verify_backup(invalid)


def test_manifest_and_embedded_database_schema_must_match(tmp_path: Path) -> None:
    source = tmp_path / "schema-two-source"
    create_legacy_root(source, 2)
    valid = tmp_path / "schema-two.zip"
    build_backup_fixture(source, valid, schema_version=2)
    mismatch = tmp_path / "schema-mismatch.zip"
    rewrite_manifest(
        valid,
        mismatch,
        lambda manifest: manifest.__setitem__("schema_version", 3),
    )

    with pytest.raises(BackupValidationError, match="migration version"):
        BackupService(source).verify_backup(mismatch)


def test_gap_in_embedded_migration_versions_is_rejected(tmp_path: Path) -> None:
    source = tmp_path / "gap-source"
    seed(source)
    connection = sqlite3.connect(source / "cse.sqlite3")
    try:
        connection.execute("DELETE FROM schema_migrations WHERE version = 2")
        connection.commit()
    finally:
        connection.close()
    archive = tmp_path / "gap.zip"
    build_backup_fixture(source, archive, schema_version=4)

    with pytest.raises(BackupValidationError, match="migration version"):
        BackupService(source).verify_backup(archive)


def test_embedded_database_is_validated_after_archive_digest(tmp_path: Path) -> None:
    database_bytes = b"not-a-sqlite-database"
    database_digest = {
        "sha256": hashlib.sha256(database_bytes).hexdigest(),
        "size_bytes": len(database_bytes),
    }
    manifest = {
        "backup_format_version": 1,
        "created_at": "2026-07-16T10:00:00Z",
        "schema_version": 4,
        "attachment_count": 0,
        "observation_count": 0,
        "event_count": 0,
        "files": {"cse.sqlite3": database_digest},
        "attachments": [],
    }
    archive = tmp_path / "invalid-embedded-database.zip"
    with zipfile.ZipFile(archive, "w") as bundle:
        bundle.writestr("manifest.json", json.dumps(manifest))
        bundle.writestr("cse.sqlite3", database_bytes)

    with pytest.raises(BackupValidationError, match="database"):
        BackupService(tmp_path).verify_backup(archive)


def test_verify_uses_and_cleans_private_temporary_root(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "source"
    seed(source)
    archive = tmp_path / "valid.zip"
    backup = BackupService(source)
    backup.create_backup(archive)
    original = backup._validate_restored_database
    temporary_roots: list[Path] = []

    def remember_root(*args):
        temporary_roots.append(args[0])
        return original(*args)

    monkeypatch.setattr(backup, "_validate_restored_database", remember_root)
    backup.verify_backup(archive)

    assert temporary_roots
    assert all(not root.exists() for root in temporary_roots)


def test_pre_migration_count_mismatch_leaves_no_target(tmp_path: Path) -> None:
    source = tmp_path / "schema-two-source"
    create_legacy_root(source, 2)
    valid = tmp_path / "schema-two.zip"
    build_backup_fixture(source, valid, schema_version=2)
    mismatch = tmp_path / "count-mismatch.zip"
    rewrite_manifest(
        valid,
        mismatch,
        lambda manifest: manifest.__setitem__(
            "observation_count", manifest["observation_count"] + 1
        ),
    )
    target = tmp_path / "must-not-exist"

    with pytest.raises(BackupValidationError, match="observation count"):
        BackupService(source).restore_backup(mismatch, target)

    assert not target.exists()


def test_migration_statement_failure_cleans_temporary_root_and_preserves_archive(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "schema-two-source"
    create_legacy_root(source, 2)
    archive = tmp_path / "schema-two.zip"
    build_backup_fixture(source, archive, schema_version=2)
    archive_hash_before = digest_file(archive)
    target = tmp_path / "migration-failure-target"
    failing_v3 = Migration(
        version=3,
        statements=(
            "CREATE TABLE partial_restore_table (id TEXT PRIMARY KEY)",
            "CREATE TABLE broken_restore_table (",
        ),
    )

    def fail_migration(connection: sqlite3.Connection) -> int:
        return migrate_database(
            connection,
            migrations=(*SCHEMA_MIGRATIONS[:2], failing_v3),
        )

    monkeypatch.setattr(backups_module, "migrate_database", fail_migration)
    with pytest.raises(BackupValidationError, match="migration failed"):
        BackupService(source).restore_backup(archive, target)

    assert not target.exists()
    assert list(tmp_path.glob(f".{target.name}.restore-*")) == []
    assert digest_file(archive) == archive_hash_before


def test_post_migration_repository_validation_failure_is_atomic(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "schema-three-source"
    create_legacy_root(source, 3)
    archive = tmp_path / "schema-three.zip"
    build_backup_fixture(source, archive, schema_version=3)
    target = tmp_path / "post-validation-target"
    backup = BackupService(source)
    monkeypatch.setattr(
        backup,
        "_validate_current_repositories",
        lambda *_: (_ for _ in ()).throw(
            BackupValidationError("injected repository validation failure")
        ),
    )

    with pytest.raises(BackupValidationError, match="repository validation"):
        backup.restore_backup(archive, target)

    assert not target.exists()
    assert list(tmp_path.glob(f".{target.name}.restore-*")) == []


def test_missing_or_tampered_attachment_fails_closed(tmp_path: Path) -> None:
    source = tmp_path / "source"
    observation_id, attachment_id = seed(source)
    service = ObservationApplicationService(
        source / "cse.sqlite3", ManagedAttachmentStore(source / "attachments")
    )
    metadata, _ = service.get_attachment(attachment_id)
    (source / "attachments" / metadata.stored_relative_path).write_bytes(b"tampered")
    archive = tmp_path / "invalid.zip"

    with pytest.raises(BackupValidationError):
        BackupService(source).create_backup(archive)

    assert not archive.exists()


def test_corrupt_archive_hash_and_extra_entry_are_rejected(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    valid = tmp_path / "valid.zip"
    BackupService(source).create_backup(valid)
    corrupt = tmp_path / "corrupt.zip"
    rewrite_zip(
        valid,
        corrupt,
        lambda info, data: (
            info.filename,
            b"corrupt" if info.filename == "cse.sqlite3" else data,
            None,
        ),
    )
    extra = tmp_path / "extra.zip"
    with zipfile.ZipFile(valid) as incoming, zipfile.ZipFile(extra, "w") as outgoing:
        for info in incoming.infolist():
            outgoing.writestr(info, incoming.read(info.filename))
        outgoing.writestr("extra.txt", b"unexpected")

    for archive in (corrupt, extra):
        with pytest.raises(BackupValidationError):
            BackupService(source).verify_backup(archive)


def test_corrupt_attachment_archive_hash_is_rejected(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    valid = tmp_path / "valid.zip"
    BackupService(source).create_backup(valid)
    corrupt = tmp_path / "corrupt-attachment.zip"
    rewrite_zip(
        valid,
        corrupt,
        lambda info, data: (
            info.filename,
            b"tampered" if info.filename.startswith("attachments/") else data,
            None,
        ),
    )

    with pytest.raises(BackupValidationError):
        BackupService(source).verify_backup(corrupt)


def test_missing_manifested_archive_entry_is_rejected(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    valid = tmp_path / "valid.zip"
    BackupService(source).create_backup(valid)
    missing = tmp_path / "missing-entry.zip"
    with zipfile.ZipFile(valid) as incoming, zipfile.ZipFile(missing, "w") as outgoing:
        for info in incoming.infolist():
            if info.filename.startswith("attachments/"):
                continue
            outgoing.writestr(info, incoming.read(info.filename))

    with pytest.raises(BackupValidationError):
        BackupService(source).verify_backup(missing)


@pytest.mark.parametrize("unsafe_name", ["../evil", "/absolute", "bad\\name"])
def test_unsafe_archive_names_are_rejected(tmp_path: Path, unsafe_name: str) -> None:
    archive = tmp_path / "unsafe.zip"
    with zipfile.ZipFile(archive, "w") as bundle:
        bundle.writestr("manifest.json", b"{}")
        bundle.writestr(unsafe_name, b"evil")

    with pytest.raises(BackupValidationError):
        BackupService(tmp_path).verify_backup(archive)


@pytest.mark.parametrize(
    "unsafe_attachment_path",
    [
        (
            "attachments/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/"
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg:stream"
        ),
        (
            "attachments/C:/"
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg"
        ),
        (
            "attachments/not-a-canonical-uuid/"
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg"
        ),
        (
            "attachments/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/"
            "not-a-canonical-uuid.jpg"
        ),
    ],
)
def test_attachment_archive_path_is_rejected_before_restore_extraction(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    unsafe_attachment_path: str,
) -> None:
    archive = tmp_path / "unsafe-attachment-path.zip"
    database_bytes = b"database-placeholder"
    attachment_bytes = b"attachment-placeholder"
    database_digest = {
        "sha256": hashlib.sha256(database_bytes).hexdigest(),
        "size_bytes": len(database_bytes),
    }
    attachment_digest = {
        "sha256": hashlib.sha256(attachment_bytes).hexdigest(),
        "size_bytes": len(attachment_bytes),
    }
    manifest = {
        "backup_format_version": 1,
        "created_at": "2026-07-13T10:00:00Z",
        "schema_version": SCHEMA_VERSION,
        "attachment_count": 1,
        "observation_count": 1,
        "event_count": 1,
        "files": {
            "cse.sqlite3": database_digest,
            unsafe_attachment_path: attachment_digest,
        },
        "attachments": [
            {"path": unsafe_attachment_path, **attachment_digest}
        ],
    }
    with zipfile.ZipFile(archive, "w") as bundle:
        bundle.writestr("manifest.json", json.dumps(manifest))
        bundle.writestr("cse.sqlite3", database_bytes)
        bundle.writestr(unsafe_attachment_path, attachment_bytes)

    backup = BackupService(tmp_path)
    extraction_called = False

    def fail_if_extracted(*_args: object) -> None:
        nonlocal extraction_called
        extraction_called = True

    monkeypatch.setattr(backup, "_extract_entry", fail_if_extracted)
    with pytest.raises(BackupValidationError):
        backup.verify_backup(archive)
    target = tmp_path / "must-not-exist"
    with pytest.raises(BackupValidationError):
        backup.restore_backup(archive, target)

    assert extraction_called is False
    assert not target.exists()


def test_symlink_and_duplicate_entries_are_rejected(tmp_path: Path) -> None:
    symlink_archive = tmp_path / "symlink.zip"
    info = zipfile.ZipInfo("attachments/link")
    info.create_system = 3
    info.external_attr = (stat.S_IFLNK | 0o777) << 16
    with zipfile.ZipFile(symlink_archive, "w") as bundle:
        bundle.writestr("manifest.json", b"{}")
        bundle.writestr(info, b"target")
    duplicate_archive = tmp_path / "duplicate.zip"
    with pytest.warns(UserWarning, match="Duplicate name"):
        with zipfile.ZipFile(duplicate_archive, "w") as bundle:
            bundle.writestr("manifest.json", b"{}")
            bundle.writestr("manifest.json", b"{}")

    for archive in (symlink_archive, duplicate_archive):
        with pytest.raises(BackupValidationError):
            BackupService(tmp_path).verify_backup(archive)


def test_existing_target_and_restore_failure_leave_target_unchanged(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    source = tmp_path / "source"
    seed(source)
    archive = tmp_path / "valid.zip"
    backup = BackupService(source)
    backup.create_backup(archive)
    existing = tmp_path / "existing"
    existing.mkdir()
    marker = existing / "keep.txt"
    marker.write_text("keep")

    with pytest.raises(BackupValidationError):
        backup.restore_backup(archive, existing)
    assert marker.read_text() == "keep"

    target = tmp_path / "new-target"
    monkeypatch.setattr(
        backup,
        "_validate_restored_database",
        lambda *_: (_ for _ in ()).throw(BackupValidationError("injected")),
    )
    with pytest.raises(BackupValidationError):
        backup.restore_backup(archive, target)
    assert not target.exists()


def test_snapshot_and_archive_rename_failure_leave_no_final(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    source = tmp_path / "source"
    seed(source)
    snapshot_output = tmp_path / "snapshot-failed.zip"
    snapshot_backup = BackupService(source)
    monkeypatch.setattr(
        snapshot_backup,
        "_snapshot_database",
        lambda *_: (_ for _ in ()).throw(OSError("snapshot failed")),
    )
    with pytest.raises(BackupValidationError):
        snapshot_backup.create_backup(snapshot_output)
    assert not snapshot_output.exists()

    rename_output = tmp_path / "rename-failed.zip"
    rename_backup = BackupService(source)
    monkeypatch.setattr(
        rename_backup,
        "_atomic_move",
        lambda *_: (_ for _ in ()).throw(OSError("rename failed")),
    )
    with pytest.raises(BackupValidationError):
        rename_backup.create_backup(rename_output)
    assert not rename_output.exists()

    write_output = tmp_path / "write-failed.zip"
    write_backup = BackupService(source)
    monkeypatch.setattr(
        write_backup,
        "_write_backup_archive",
        lambda *_: (_ for _ in ()).throw(OSError("archive write failed")),
    )
    with pytest.raises(BackupValidationError):
        write_backup.create_backup(write_output)
    assert not write_output.exists()


def test_existing_backup_output_is_not_overwritten(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    output = tmp_path / "existing.zip"
    output.write_bytes(b"keep")

    with pytest.raises(FileExistsError):
        BackupService(source).create_backup(output)

    assert output.read_bytes() == b"keep"
