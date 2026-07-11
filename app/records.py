from typing import TypeVar

from app.models import FieldObservationRecord, NonconformityRecord


RecordT = TypeVar("RecordT")


def list_records(records: list[RecordT]) -> list[RecordT]:
    return records


def count_records(records: list[RecordT]) -> int:
    return len(records)


def filter_records_by_project_id(
    records: list[RecordT],
    project_id: str,
) -> list[RecordT]:
    return [
        record
        for record in records
        if hasattr(record, "project_id") and record.project_id == project_id
    ]


def filter_records_by_status(records: list[RecordT], status: str) -> list[RecordT]:
    return [
        record
        for record in records
        if hasattr(record, "status") and record.status == status
    ]


def list_records_by_project(records: list[RecordT], project_id: str) -> list[RecordT]:
    return filter_records_by_project_id(records, project_id)


class FieldObservationRepository:
    """Stores field observation records in memory."""

    def __init__(self) -> None:
        self._records: list[FieldObservationRecord] = []

    def add(self, record: FieldObservationRecord) -> None:
        if self.find_by_id(record.observation_id) is not None:
            raise ValueError(
                f"FieldObservationRecord with id '{record.observation_id}' already exists."
            )
        self._records.append(record)

    def list_all(self) -> list[FieldObservationRecord]:
        return list(self._records)

    def list_by_project_id(self, project_id: str) -> list[FieldObservationRecord]:
        return [record for record in self._records if record.project_id == project_id]

    def list_by_status(self, status: str) -> list[FieldObservationRecord]:
        return [record for record in self._records if record.status == status]

    def count(self) -> int:
        return len(self._records)

    def find_by_id(self, observation_id: str) -> FieldObservationRecord | None:
        for record in self._records:
            if record.observation_id == observation_id:
                return record
        return None

    def update_status(
        self,
        observation_id: str,
        new_status: str,
    ) -> FieldObservationRecord | None:
        record = self.find_by_id(observation_id)
        if record is None:
            return None
        record.status = new_status
        return record

    def update_reporting(
        self,
        observation_id: str,
        reported_to: str,
        reported_at: str,
    ) -> FieldObservationRecord | None:
        record = self.find_by_id(observation_id)
        if record is None:
            return None
        record.reported_to = reported_to
        record.reported_at = reported_at
        return record


class NonconformityRepository:
    """Stores nonconformity records in memory."""

    def __init__(self) -> None:
        self._records: list[NonconformityRecord] = []

    def add(self, record: NonconformityRecord) -> None:
        if self.find_by_id(record.nonconformity_id) is not None:
            raise ValueError(
                f"NonconformityRecord with id '{record.nonconformity_id}' already exists."
            )
        self._records.append(record)

    def list_all(self) -> list[NonconformityRecord]:
        return list(self._records)

    def count(self) -> int:
        return len(self._records)

    def find_by_id(self, nonconformity_id: str) -> NonconformityRecord | None:
        for record in self._records:
            if record.nonconformity_id == nonconformity_id:
                return record
        return None

    def exists(self, nonconformity_id: str) -> bool:
        return self.find_by_id(nonconformity_id) is not None

    def update_status(
        self,
        nonconformity_id: str,
        new_status: str,
    ) -> NonconformityRecord | None:
        record = self.find_by_id(nonconformity_id)
        if record is None:
            return None
        record.status = new_status
        return record

    def update_responsible_party(
        self,
        nonconformity_id: str,
        responsible_party: str | None,
    ) -> NonconformityRecord | None:
        record = self.find_by_id(nonconformity_id)
        if record is None:
            return None
        record.responsible_party = responsible_party
        return record

    def archive(self, nonconformity_id: str) -> NonconformityRecord | None:
        record = self.find_by_id(nonconformity_id)
        if record is None:
            return None
        record.is_archived = True
        return record

    def restore(self, nonconformity_id: str) -> NonconformityRecord | None:
        record = self.find_by_id(nonconformity_id)
        if record is None:
            return None
        record.is_archived = False
        return record

    def list_by_status(self, status: str) -> list[NonconformityRecord]:
        return [record for record in self._records if record.status == status]

    def list_by_location(self, location: str) -> list[NonconformityRecord]:
        return [record for record in self._records if record.location == location]

    def count_by_status(self, status: str) -> int:
        return len(self.list_by_status(status))

    def list_active(self) -> list[NonconformityRecord]:
        return [record for record in self._records if not record.is_archived]

    def list_archived(self) -> list[NonconformityRecord]:
        return [record for record in self._records if record.is_archived]

    def get_archive_summary(self) -> dict[str, int]:
        return {
            "active": len(self.list_active()),
            "archived": len(self.list_archived()),
            "total": self.count(),
        }

    def list_by_responsible_party(
        self,
        responsible_party: str,
    ) -> list[NonconformityRecord]:
        return [
            record
            for record in self._records
            if record.responsible_party == responsible_party
        ]

    def get_status_summary(self) -> dict[str, int]:
        summary: dict[str, int] = {}
        for record in self._records:
            summary[record.status] = summary.get(record.status, 0) + 1
        return summary

    def get_responsible_party_summary(self) -> dict[str, int]:
        summary: dict[str, int] = {}
        for record in self._records:
            responsible_party = record.responsible_party or "unassigned"
            summary[responsible_party] = summary.get(responsible_party, 0) + 1
        return summary

    def get_overview_summary(self) -> dict[str, int]:
        summary = {
            "total": 0,
            "open": 0,
            "closed": 0,
            "assigned": 0,
            "unassigned": 0,
        }
        for record in self._records:
            summary["total"] += 1
            if record.status == "open":
                summary["open"] += 1
            if record.status == "closed":
                summary["closed"] += 1
            if record.responsible_party is None:
                summary["unassigned"] += 1
            else:
                summary["assigned"] += 1
        return summary
