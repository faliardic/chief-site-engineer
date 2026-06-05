from typing import TypeVar


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
