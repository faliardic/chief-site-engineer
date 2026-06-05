from app.models import (
    ArchiveDocument,
    ChecklistItem,
    DailySiteLog,
    SiteProject,
    TrackingRecord,
)


def test_site_project_holds_values_and_defaults() -> None:
    project = SiteProject(
        project_id="prj-001",
        name="Merkez Santiye",
        location="Istanbul",
    )

    assert project.project_id == "prj-001"
    assert project.name == "Merkez Santiye"
    assert project.location == "Istanbul"
    assert project.employer is None
    assert project.contractor is None
    assert project.building_inspection_company is None
    assert project.start_date is None
    assert project.status == "active"


def test_checklist_item_holds_values_and_defaults() -> None:
    item = ChecklistItem(
        item_id="chk-001",
        title="Kalip kontrolu",
        category="Betonarme",
    )

    assert item.item_id == "chk-001"
    assert item.title == "Kalip kontrolu"
    assert item.category == "Betonarme"
    assert item.description is None
    assert item.required is True
    assert item.status == "pending"


def test_tracking_record_holds_values_and_defaults() -> None:
    record = TrackingRecord(
        record_id="trk-001",
        project_id="prj-001",
        title="Demir teslim takibi",
        description="Teslim edilen donati miktari kontrol edildi.",
        date="2026-06-05",
    )

    assert record.record_id == "trk-001"
    assert record.project_id == "prj-001"
    assert record.title == "Demir teslim takibi"
    assert record.description == "Teslim edilen donati miktari kontrol edildi."
    assert record.date == "2026-06-05"
    assert record.responsible_party is None
    assert record.status == "open"


def test_archive_document_holds_values_and_defaults() -> None:
    document = ArchiveDocument(
        document_id="doc-001",
        project_id="prj-001",
        title="Ruhsat",
        document_type="permit",
    )

    assert document.document_id == "doc-001"
    assert document.project_id == "prj-001"
    assert document.title == "Ruhsat"
    assert document.document_type == "permit"
    assert document.file_path is None
    assert document.date is None
    assert document.notes is None


def test_daily_site_log_holds_values_and_defaults() -> None:
    log = DailySiteLog(
        log_id="log-001",
        project_id="prj-001",
        date="2026-06-05",
    )

    assert log.log_id == "log-001"
    assert log.project_id == "prj-001"
    assert log.date == "2026-06-05"
    assert log.weather is None
    assert log.workforce_summary is None
    assert log.work_performed is None
    assert log.inspections is None
    assert log.issues is None
    assert log.notes is None
    assert log.created_by is None
    assert log.status == "draft"
