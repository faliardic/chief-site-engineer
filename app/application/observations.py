"""Transaction-aware observation use cases for the local Field MVP."""

import unicodedata
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO
from uuid import uuid4

from app.models import FieldObservationRecord
from app.persistence import (
    AttachmentMetadataRecord,
    ObservationEventRecord,
    ProjectRecord,
    SQLiteUnitOfWork,
    serialize_event_payload,
)
from app.storage import (
    AttachmentStoreError,
    AttachmentVerification,
    ManagedAttachmentStore,
    StagedAttachment,
)
from app.time_contracts import utc_now


MAX_SEARCH_QUERY_LENGTH = 200
EDITABLE_DETAIL_FIELDS = ("location", "category", "description", "notes")


@dataclass(frozen=True)
class UploadStream:
    binary_stream: BinaryIO
    original_name: str


@dataclass(frozen=True)
class AttachmentDetail:
    metadata: AttachmentMetadataRecord
    verification: AttachmentVerification


@dataclass(frozen=True)
class ObservationDetail:
    observation: FieldObservationRecord
    project: ProjectRecord
    attachments: tuple[AttachmentDetail, ...]
    events: tuple[ObservationEventRecord, ...]


class ApplicationServiceError(Exception):
    """Expose cross-resource failure state without claiming atomicity."""

    def __init__(
        self,
        operation: str,
        message: str,
        *,
        reconciliation_required: bool = False,
        staging_relative_path: str | None = None,
        final_relative_path: str | None = None,
    ) -> None:
        self.operation = operation
        self.reconciliation_required = reconciliation_required
        self.staging_relative_path = staging_relative_path
        self.final_relative_path = final_relative_path
        super().__init__(message)


def _utc_now() -> str:
    return utc_now()


class ObservationApplicationService:
    """Coordinate persistence, events and managed attachment files."""

    def __init__(
        self,
        database_path: str | Path,
        attachment_store: ManagedAttachmentStore,
        *,
        uow_factory: Callable[[], SQLiteUnitOfWork] | None = None,
        clock: Callable[[], str] = _utc_now,
        uuid_factory: Callable[[], str] = lambda: str(uuid4()),
        local_actor: str = "local-user",
    ) -> None:
        self.database_path = Path(database_path)
        self.attachment_store = attachment_store
        self._uow_factory = uow_factory or (
            lambda: SQLiteUnitOfWork(self.database_path)
        )
        self._clock = clock
        self._uuid_factory = uuid_factory
        self._local_actor = local_actor

    def create_project(self, name: str) -> ProjectRecord:
        record = ProjectRecord(self._new_id(), name, self._clock())
        with self._uow_factory() as unit_of_work:
            unit_of_work.projects.add(record)
            unit_of_work.commit()
        return record

    def list_projects(self) -> list[ProjectRecord]:
        with self._uow_factory() as unit_of_work:
            return unit_of_work.projects.list_all()

    def create_observation(
        self,
        project_id: str,
        location: str,
        category: str,
        description: str,
        notes: str | None,
        upload: UploadStream | None,
    ) -> FieldObservationRecord:
        observation_id = self._new_id()
        staged: StagedAttachment | None = None
        if upload is not None:
            attachment_id = self._new_id()
            staged = self.attachment_store.stage_stream(
                upload.binary_stream,
                upload.original_name,
                observation_id,
                attachment_id,
            )

        occurred_at = self._clock()
        observation = FieldObservationRecord(
            observation_id=observation_id,
            project_id=project_id,
            observed_at=occurred_at,
            location=location,
            category=category,
            description=description,
            notes=notes or None,
            created_by=self._local_actor,
            created_at=occurred_at,
            updated_at=occurred_at,
        )
        finalized = False
        try:
            with self._uow_factory() as unit_of_work:
                unit_of_work.observations.add(observation)
                attachment_ids: list[str] = []
                if staged is not None:
                    attachment_ids.append(staged.attachment_id)
                    unit_of_work.attachments.add(
                        self._attachment_record(staged, occurred_at)
                    )
                unit_of_work.events.add(
                    self._event(
                        observation_id,
                        "observation_created",
                        occurred_at,
                        {
                            "attachment_ids": attachment_ids,
                            "revision": observation.revision,
                            "status": observation.status,
                        },
                    )
                )
                if staged is not None:
                    self.attachment_store.finalize(staged)
                    finalized = True
                unit_of_work.commit()
        except Exception as exc:
            if staged is None:
                raise
            if finalized:
                raise ApplicationServiceError(
                    "create_observation",
                    f"database commit failed after attachment finalize: {exc}",
                    reconciliation_required=True,
                    final_relative_path=staged.final_relative_path,
                ) from exc
            if self._is_staging_present(staged):
                if isinstance(exc, AttachmentStoreError):
                    raise ApplicationServiceError(
                        "create_observation",
                        f"attachment finalize failed: {exc}",
                        reconciliation_required=True,
                        staging_relative_path=staged.staging_relative_path,
                    ) from exc
                try:
                    self.attachment_store.discard_staged(staged)
                except Exception as cleanup_error:
                    raise ApplicationServiceError(
                        "create_observation",
                        f"database operation failed and staging cleanup failed: {cleanup_error}",
                        reconciliation_required=True,
                        staging_relative_path=staged.staging_relative_path,
                    ) from cleanup_error
            raise ApplicationServiceError(
                "create_observation", f"database operation failed: {exc}"
            ) from exc
        return observation

    def list_observations(
        self,
        project_id: str | None = None,
        status: str | None = None,
        q: str | None = None,
    ) -> list[FieldObservationRecord]:
        query = (q or "").strip()
        if len(query) > MAX_SEARCH_QUERY_LENGTH:
            raise ValueError(
                f"search query cannot exceed {MAX_SEARCH_QUERY_LENGTH} characters"
            )
        with self._uow_factory() as unit_of_work:
            projects = {
                project.project_id: project.name
                for project in unit_of_work.projects.list_all()
            }
            if project_id is not None:
                records = unit_of_work.observations.list_by_project_id(project_id)
            elif status is not None:
                records = unit_of_work.observations.list_by_status(status)
            else:
                records = unit_of_work.observations.list_all()
        if project_id is not None and status is not None:
            records = [record for record in records if record.status == status]
        if query:
            query_key = _search_key(query)
            records = [
                record
                for record in records
                if any(
                    query_key in _search_key(value)
                    for value in (
                        projects.get(record.project_id, ""),
                        record.location,
                        record.category,
                        record.description,
                        record.notes or "",
                        record.reported_to or "",
                    )
                )
            ]
        return records

    def get_observation_detail(self, observation_id: str) -> ObservationDetail:
        with self._uow_factory() as unit_of_work:
            observation = unit_of_work.observations.get(observation_id)
            project = unit_of_work.projects.get(observation.project_id)
            metadata = unit_of_work.attachments.list_for_observation(observation_id)
            events = unit_of_work.events.list_for_observation(observation_id)
        attachments = tuple(
            AttachmentDetail(item, self.attachment_store.verify(item))
            for item in metadata
        )
        return ObservationDetail(observation, project, attachments, tuple(events))

    def update_status(
        self, observation_id: str, expected_revision: int, new_status: str
    ) -> FieldObservationRecord:
        occurred_at = self._clock()
        with self._uow_factory() as unit_of_work:
            before = unit_of_work.observations.get(observation_id)
            updated = unit_of_work.observations.update_status(
                observation_id, expected_revision, new_status, occurred_at
            )
            if updated.revision != before.revision:
                unit_of_work.events.add(
                    self._event(
                        observation_id,
                        "observation_status_changed",
                        occurred_at,
                        {"from": before.status, "to": updated.status,
                         "revision": updated.revision},
                    )
                )
            unit_of_work.commit()
        return updated

    def update_observation_details(
        self,
        observation_id: str,
        expected_revision: int,
        location: str,
        category: str,
        description: str,
        notes: str | None,
    ) -> FieldObservationRecord:
        """Update the editable detail allowlist and append one audit event."""

        occurred_at = self._clock()
        normalized_notes = notes if notes is not None and notes.strip() else None
        with self._uow_factory() as unit_of_work:
            before = unit_of_work.observations.get(observation_id)
            updated = unit_of_work.observations.update_details(
                observation_id,
                expected_revision,
                location,
                category,
                description,
                normalized_notes,
                occurred_at,
            )
            changed_fields = [
                field_name
                for field_name in EDITABLE_DETAIL_FIELDS
                if getattr(before, field_name) != getattr(updated, field_name)
            ]
            if changed_fields:
                unit_of_work.events.add(
                    self._event(
                        observation_id,
                        "observation_details_updated",
                        occurred_at,
                        {
                            "changed_fields": changed_fields,
                            "revision": updated.revision,
                        },
                    )
                )
            unit_of_work.commit()
        return updated

    def update_reporting(
        self,
        observation_id: str,
        expected_revision: int,
        reported_to: str,
        reported_at: str,
    ) -> FieldObservationRecord:
        occurred_at = self._clock()
        with self._uow_factory() as unit_of_work:
            updated = unit_of_work.observations.update_reporting(
                observation_id, expected_revision, reported_to, reported_at,
                occurred_at,
            )
            unit_of_work.events.add(
                self._event(
                    observation_id,
                    "observation_reporting_updated",
                    occurred_at,
                    {"reported_at": reported_at, "reported_to": reported_to,
                     "revision": updated.revision},
                )
            )
            unit_of_work.commit()
        return updated

    def archive_observation(
        self, observation_id: str, expected_revision: int
    ) -> FieldObservationRecord:
        occurred_at = self._clock()
        with self._uow_factory() as unit_of_work:
            updated = unit_of_work.observations.archive(
                observation_id, expected_revision, occurred_at
            )
            unit_of_work.events.add(
                self._event(
                    observation_id, "observation_archived", occurred_at,
                    {"revision": updated.revision},
                )
            )
            unit_of_work.commit()
        return updated

    def get_attachment(
        self, attachment_id: str
    ) -> tuple[AttachmentMetadataRecord, AttachmentVerification]:
        with self._uow_factory() as unit_of_work:
            metadata = unit_of_work.attachments.get(attachment_id)
        return metadata, self.attachment_store.verify(metadata)

    @contextmanager
    def open_attachment(self, attachment_id: str) -> Iterator[BinaryIO]:
        metadata, verification = self.get_attachment(attachment_id)
        if not verification.valid:
            raise ApplicationServiceError(
                "open_attachment", f"attachment is {verification.status}"
            )
        with self.attachment_store.open_read(metadata) as file_handle:
            yield file_handle

    def _event(
        self,
        observation_id: str,
        event_type: str,
        occurred_at: str,
        payload: dict[str, object],
    ) -> ObservationEventRecord:
        return ObservationEventRecord(
            self._new_id(), observation_id, event_type, self._local_actor,
            occurred_at, serialize_event_payload(payload)
        )

    def _attachment_record(
        self, staged: StagedAttachment, created_at: str
    ) -> AttachmentMetadataRecord:
        return AttachmentMetadataRecord(
            staged.attachment_id, staged.observation_id, staged.original_name,
            staged.final_relative_path, staged.sha256, staged.size_bytes,
            staged.mime_type, "active", created_at, self._local_actor,
        )

    def _new_id(self) -> str:
        return str(self._uuid_factory())

    def _is_staging_present(self, staged: StagedAttachment) -> bool:
        report = self.attachment_store.reconcile([])
        return staged.staging_relative_path in report.stale_staging_files


def _search_key(value: str) -> str:
    """Return a Unicode-aware, Turkish-friendly key for literal searching."""

    decomposed = unicodedata.normalize("NFKD", value).casefold()
    return decomposed.replace("\u0307", "").replace("ı", "i")
