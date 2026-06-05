from app.models import DailySiteLog, TrackingRecord
from app.records import (
    count_records,
    filter_records_by_project_id,
    filter_records_by_status,
    list_records,
)


class DummyRecord:
    pass


def test_list_records_returns_given_list() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = list_records(records)

    assert result == records


def test_count_records_returns_record_count() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(log_id="log-002", project_id="prj-001", date="2026-06-06"),
    ]

    result = count_records(records)

    assert result == 2


def test_filter_records_by_project_id_returns_matching_records() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(log_id="log-002", project_id="prj-002", date="2026-06-05"),
        TrackingRecord(
            record_id="trk-001",
            project_id="prj-001",
            title="Demir kontrolu",
            description="Donati kontrol edildi.",
            date="2026-06-05",
        ),
    ]

    result = filter_records_by_project_id(records, "prj-001")

    assert len(result) == 2
    assert result[0].project_id == "prj-001"
    assert result[1].project_id == "prj-001"


def test_filter_records_by_project_id_ignores_records_without_project_id() -> None:
    records = [
        DummyRecord(),
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = filter_records_by_project_id(records, "prj-001")

    assert len(result) == 1
    assert result[0].project_id == "prj-001"


def test_filter_records_by_status_returns_matching_records() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(
            log_id="log-002",
            project_id="prj-001",
            date="2026-06-06",
            status="approved",
        ),
        TrackingRecord(
            record_id="trk-001",
            project_id="prj-001",
            title="Beton dokum takibi",
            description="Dokum basladi.",
            date="2026-06-05",
            status="closed",
        ),
    ]

    result = filter_records_by_status(records, "draft")

    assert len(result) == 1
    assert result[0].status == "draft"


def test_filter_records_by_status_ignores_records_without_status() -> None:
    records = [
        DummyRecord(),
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = filter_records_by_status(records, "draft")

    assert len(result) == 1
    assert result[0].status == "draft"


def test_record_helpers_handle_empty_lists() -> None:
    records = []

    assert list_records(records) == []
    assert count_records(records) == 0
    assert filter_records_by_project_id(records, "prj-001") == []
    assert filter_records_by_status(records, "draft") == []
