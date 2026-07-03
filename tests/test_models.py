import pytest

from app.models import (
    AUDIT_EVENT_TYPE_SET,
    AUDIT_EVENT_TYPES,
    ArchiveDocument,
    AttachmentRecord,
    AuditEventRecord,
    CheckResultRecord,
    ChecklistItem,
    ChecklistItemRecord,
    ConcretePour,
    ConcreteSample,
    ContactPersonRecord,
    DailyReportRecord,
    DailySiteLog,
    EquipmentRecord,
    AttachmentStatus,
    FileAttachmentRecord,
    FileType,
    InspectionRequest,
    MaterialRecord,
    MeetingActionRecord,
    MeetingRecord,
    NonconformityCandidateActionRecord,
    NonconformityCandidateAssignmentRecord,
    NonconformityCandidateClosureRecord,
    NonconformityCandidateConversionRecord,
    NonconformityCandidateProcessViewRecord,
    NonconformityCandidateRecord,
    NonconformityCandidateReviewRecord,
    NonconformityCandidateStatusHistoryRecord,
    NonconformityCandidateTrackingSummaryRecord,
    NonconformityAssignmentRecord,
    NonconformityClosureRecord,
    NonconformityCorrectiveActionRecord,
    NonconformityCorrectiveActionVerificationRecord,
    NonconformityProcessViewRecord,
    NonconformityRecord,
    NonconformityStatusHistoryRecord,
    ProjectPartyRecord,
    RFIRecord,
    SiteLocationRecord,
    SiteNoteRecord,
    SiteProject,
    SubmittalRecord,
    SupplierRecord,
    TaskCandidateRecord,
    TrackingRecord,
    WorkforceRecord,
)


def test_file_attachment_enum_values_define_canonical_vocabulary() -> None:
    assert FileType.IMAGE.value == "image"
    assert FileType.VIDEO.value == "video"
    assert FileType.PDF.value == "pdf"
    assert FileType.DOCUMENT.value == "document"
    assert FileType.AUDIO.value == "audio"
    assert FileType.OTHER.value == "other"
    assert AttachmentStatus.ACTIVE.value == "active"
    assert AttachmentStatus.ARCHIVED.value == "archived"
    assert AttachmentStatus.MISSING.value == "missing"
    assert AttachmentStatus.DELETED.value == "deleted"


def test_audit_event_record_holds_values_and_optional_defaults() -> None:
    event = AuditEventRecord(
        event_id="audit-001",
        project_id="prj-001",
        event_type="record.updated",
        actor="Santiye sefi",
        occurred_at="2026-06-23T10:30:00",
    )

    assert event.event_id == "audit-001"
    assert event.project_id == "prj-001"
    assert event.event_type == "record.updated"
    assert event.actor == "Santiye sefi"
    assert event.occurred_at == "2026-06-23T10:30:00"
    assert event.target_record_type is None
    assert event.target_record_id is None
    assert event.reason is None
    assert event.old_value is None
    assert event.new_value is None
    assert event.source is None
    assert event.notes is None


def test_audit_event_record_can_reference_target_and_change_context() -> None:
    event = AuditEventRecord(
        event_id="audit-002",
        project_id="prj-001",
        event_type="record.archived",
        actor="Kalite sorumlusu",
        occurred_at="2026-06-23T11:00:00",
        target_record_type="NonconformityRecord",
        target_record_id="NCR-001",
        reason="Kayit kapatma sonrasi arsivlendi.",
        old_value="open",
        new_value="archived",
        source="manual_review",
        notes="Sadece olay izi; otomatik arsivleme davranisi yok.",
    )

    assert event.target_record_type == "NonconformityRecord"
    assert event.target_record_id == "NCR-001"
    assert event.reason == "Kayit kapatma sonrasi arsivlendi."
    assert event.old_value == "open"
    assert event.new_value == "archived"
    assert event.source == "manual_review"
    assert event.notes == "Sadece olay izi; otomatik arsivleme davranisi yok."


_REQUIRED_AUDIT_EVENT_FIELDS = (
    "event_id",
    "project_id",
    "event_type",
    "actor",
    "occurred_at",
)


def _valid_audit_event_kwargs() -> dict[str, str | None]:
    return {
        "event_id": "audit-valid-001",
        "project_id": "prj-001",
        "event_type": "record.updated",
        "actor": "Santiye sefi",
        "occurred_at": "2026-06-23T10:30:00",
    }


@pytest.mark.parametrize("empty_value", [""])
def test_audit_event_record_rejects_empty_required_fields(
    empty_value: str,
) -> None:
    for field_name in _REQUIRED_AUDIT_EVENT_FIELDS:
        values = _valid_audit_event_kwargs()
        values[field_name] = empty_value

        with pytest.raises(ValueError, match=f"{field_name} is required"):
            AuditEventRecord(**values)


@pytest.mark.parametrize("whitespace_value", ["   "])
def test_audit_event_record_rejects_whitespace_required_fields(
    whitespace_value: str,
) -> None:
    for field_name in _REQUIRED_AUDIT_EVENT_FIELDS:
        values = _valid_audit_event_kwargs()
        values[field_name] = whitespace_value

        with pytest.raises(ValueError, match=f"{field_name} is required"):
            AuditEventRecord(**values)


@pytest.mark.parametrize("none_value", [None])
def test_audit_event_record_rejects_none_required_fields(
    none_value: None,
) -> None:
    for field_name in _REQUIRED_AUDIT_EVENT_FIELDS:
        values = _valid_audit_event_kwargs()
        values[field_name] = none_value

        with pytest.raises(ValueError, match=f"{field_name} is required"):
            AuditEventRecord(**values)


def test_audit_event_record_allows_none_optional_fields() -> None:
    event = AuditEventRecord(**_valid_audit_event_kwargs())

    assert event.target_record_type is None
    assert event.target_record_id is None
    assert event.reason is None
    assert event.old_value is None
    assert event.new_value is None
    assert event.source is None
    assert event.notes is None


def test_audit_event_record_does_not_validate_optional_empty_strings_yet() -> None:
    event = AuditEventRecord(
        **_valid_audit_event_kwargs(),
        target_record_type="",
        target_record_id="",
        reason="",
        old_value="",
        new_value="",
        source="",
        notes="",
    )

    assert event.target_record_type == ""
    assert event.target_record_id == ""
    assert event.reason == ""
    assert event.old_value == ""
    assert event.new_value == ""
    assert event.source == ""
    assert event.notes == ""


def test_audit_event_types_include_initial_contract_values() -> None:
    expected_values = {
        "record.created",
        "record.updated",
        "attachment.linked",
        "integrity.checked",
        "json.exported",
        "backup.generated",
        "restore.completed",
        "handover.package_generated",
        "audit.event_created",
    }

    assert expected_values.issubset(AUDIT_EVENT_TYPES)


def test_audit_event_type_set_matches_tuple_without_duplicates() -> None:
    assert AUDIT_EVENT_TYPE_SET == frozenset(AUDIT_EVENT_TYPES)
    assert len(AUDIT_EVENT_TYPES) == len(AUDIT_EVENT_TYPE_SET)


def test_audit_event_record_accepts_supported_event_type() -> None:
    event = AuditEventRecord(
        event_id="audit-supported-001",
        project_id="prj-001",
        event_type="record.created",
        actor="Santiye sefi",
        occurred_at="2026-06-23T12:00:00",
    )

    assert event.event_type == "record.created"


def test_audit_event_record_rejects_unsupported_event_type() -> None:
    values = _valid_audit_event_kwargs()
    values["event_type"] = "record.deleted"

    with pytest.raises(ValueError, match="event_type is not supported"):
        AuditEventRecord(**values)


def test_audit_event_record_rejects_target_record_type_without_id() -> None:
    values = _valid_audit_event_kwargs()
    values["target_record_type"] = "project_record"

    with pytest.raises(
        ValueError,
        match="target_record_type and target_record_id must be provided together",
    ):
        AuditEventRecord(**values)


def test_audit_event_record_rejects_target_record_id_without_type() -> None:
    values = _valid_audit_event_kwargs()
    values["target_record_id"] = "REC-2026-0007"

    with pytest.raises(
        ValueError,
        match="target_record_type and target_record_id must be provided together",
    ):
        AuditEventRecord(**values)


def _valid_file_attachment_kwargs() -> dict[str, str | int]:
    return {
        "attachment_id": "file-att-valid-001",
        "related_record_type": "nonconformity",
        "related_record_id": "NCR-001",
        "file_name": "photo_001.jpg",
        "file_path": (
            "attachments/PRJ-001/nonconformity/2026/06/07/"
            "NCR-001/photo_001.jpg"
        ),
        "file_type": "image",
        "mime_type": "image/jpeg",
        "file_size": 2048,
    }


def test_file_attachment_record_validation_accepts_valid_metadata() -> None:
    attachment = FileAttachmentRecord(**_valid_file_attachment_kwargs())

    assert attachment.attachment_id == "file-att-valid-001"
    assert attachment.file_type == "image"
    assert attachment.file_size == 2048


@pytest.mark.parametrize(
    "field_name",
    [
        "attachment_id",
        "related_record_type",
        "related_record_id",
        "file_name",
        "file_path",
    ],
)
def test_file_attachment_record_validation_rejects_empty_required_fields(
    field_name: str,
) -> None:
    values = _valid_file_attachment_kwargs()
    values[field_name] = ""

    with pytest.raises(ValueError, match=f"{field_name} cannot be empty"):
        FileAttachmentRecord(**values)


def test_file_attachment_record_validation_rejects_invalid_file_type() -> None:
    values = _valid_file_attachment_kwargs()
    values["file_type"] = "photo"

    with pytest.raises(ValueError, match="file_type must be one of"):
        FileAttachmentRecord(**values)


def test_file_attachment_record_validation_rejects_negative_file_size() -> None:
    values = _valid_file_attachment_kwargs()
    values["file_size"] = -1

    with pytest.raises(ValueError, match="file_size cannot be negative"):
        FileAttachmentRecord(**values)


def test_file_attachment_record_validation_keeps_uploader_metadata_optional() -> None:
    values = _valid_file_attachment_kwargs()

    attachment = FileAttachmentRecord(**values)

    assert attachment.uploaded_by is None
    assert attachment.uploaded_at is None


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


def test_concrete_pour_holds_values_and_defaults() -> None:
    pour = ConcretePour(
        pour_id="pour-001",
        project_id="prj-001",
        date="2026-06-05",
        location="Temel",
        concrete_class="C30/37",
    )

    assert pour.pour_id == "pour-001"
    assert pour.project_id == "prj-001"
    assert pour.date == "2026-06-05"
    assert pour.location == "Temel"
    assert pour.concrete_class == "C30/37"
    assert pour.volume_m3 is None
    assert pour.supplier is None
    assert pour.truck_count is None
    assert pour.weather is None
    assert pour.notes is None
    assert pour.status == "planned"


def test_concrete_sample_holds_values_and_defaults() -> None:
    sample = ConcreteSample(
        sample_id="sample-001",
        pour_id="pour-001",
        project_id="prj-001",
        sample_date="2026-06-05",
        sample_count=6,
    )

    assert sample.sample_id == "sample-001"
    assert sample.pour_id == "pour-001"
    assert sample.project_id == "prj-001"
    assert sample.sample_date == "2026-06-05"
    assert sample.sample_count == 6
    assert sample.seven_day_test_date is None
    assert sample.twenty_eight_day_test_date is None
    assert sample.seven_day_result_mpa is None
    assert sample.twenty_eight_day_result_mpa is None
    assert sample.laboratory is None
    assert sample.status == "waiting"


def test_inspection_request_holds_values_and_defaults() -> None:
    request = InspectionRequest(
        request_id="insp-001",
        project_id="prj-001",
        requested_date="2026-06-05",
        inspection_type="Temel demir kontrolu",
    )

    assert request.request_id == "insp-001"
    assert request.project_id == "prj-001"
    assert request.requested_date == "2026-06-05"
    assert request.inspection_type == "Temel demir kontrolu"
    assert request.requested_by is None
    assert request.inspection_company is None
    assert request.related_pour_id is None
    assert request.planned_inspection_date is None
    assert request.completed_date is None
    assert request.result is None
    assert request.notes is None
    assert request.status == "requested"


def test_nonconformity_record_holds_values_and_defaults() -> None:
    record = NonconformityRecord(
        nonconformity_id="ncr-001",
        project_id="prj-001",
        date="2026-06-05",
        title="Eksik donati",
        description="Temel bolgesinde ek donati eksik goruldu.",
    )

    assert record.nonconformity_id == "ncr-001"
    assert record.project_id == "prj-001"
    assert record.date == "2026-06-05"
    assert record.title == "Eksik donati"
    assert record.description == "Temel bolgesinde ek donati eksik goruldu."
    assert record.nonconformity_type is None
    assert record.location is None
    assert record.category is None
    assert record.severity == "medium"
    assert record.detected_by is None
    assert record.detection_date is None
    assert record.responsible_party is None
    assert record.corrective_action is None
    assert record.due_date is None
    assert record.closed_date is None
    assert record.related_inspection_request_id is None
    assert record.related_pour_id is None
    assert record.final_status is None
    assert record.notes is None
    assert record.status == "open"
    assert record.is_archived is False


def test_nonconformity_record_can_be_created_as_archived() -> None:
    record = NonconformityRecord(
        nonconformity_id="ncr-archived-001",
        project_id="prj-001",
        date="2026-08-10",
        title="Arsivlenmis NCR",
        description="Bu kayit arsiv alani testi icin olusturuldu.",
        is_archived=True,
    )

    assert record.nonconformity_id == "ncr-archived-001"
    assert record.project_id == "prj-001"
    assert record.date == "2026-08-10"
    assert record.title == "Arsivlenmis NCR"
    assert record.description == "Bu kayit arsiv alani testi icin olusturuldu."
    assert record.status == "open"
    assert record.is_archived is True


def test_attachment_record_holds_values_and_defaults() -> None:
    attachment = AttachmentRecord(
        attachment_id="att-001",
        project_id="prj-001",
        title="Temel fotografi",
        file_name="temel-fotografi.jpg",
    )

    assert attachment.attachment_id == "att-001"
    assert attachment.project_id == "prj-001"
    assert attachment.title == "Temel fotografi"
    assert attachment.file_name == "temel-fotografi.jpg"
    assert attachment.file_type is None
    assert attachment.file_path is None
    assert attachment.related_model is None
    assert attachment.related_id is None
    assert attachment.uploaded_by is None
    assert attachment.uploaded_date is None
    assert attachment.notes is None
    assert attachment.status == "active"


def test_attachment_record_can_reference_nonconformity_candidate_record() -> None:
    attachment = AttachmentRecord(
        attachment_id="att-ncr-cand-001",
        project_id="prj-001",
        title="Korkuluk eksigi fotografi",
        file_name="korkuluk-eksigi.jpg",
        file_type="image/jpeg",
        file_path="archive/nonconformity-candidates/korkuluk-eksigi.jpg",
        related_model="NonconformityCandidateRecord",
        related_id="NCR-CAND-001",
        uploaded_by="Santiye sefi",
        uploaded_date="2026-06-12",
        notes="Aday uygunsuzluk icin kanit fotografi.",
        status="active",
    )

    assert attachment.attachment_id == "att-ncr-cand-001"
    assert attachment.project_id == "prj-001"
    assert attachment.title == "Korkuluk eksigi fotografi"
    assert attachment.file_name == "korkuluk-eksigi.jpg"
    assert attachment.file_type == "image/jpeg"
    assert attachment.file_path == "archive/nonconformity-candidates/korkuluk-eksigi.jpg"
    assert attachment.related_model == "NonconformityCandidateRecord"
    assert attachment.related_id == "NCR-CAND-001"
    assert attachment.uploaded_by == "Santiye sefi"
    assert attachment.uploaded_date == "2026-06-12"
    assert attachment.notes == "Aday uygunsuzluk icin kanit fotografi."
    assert attachment.status == "active"


def test_file_attachment_record_holds_values_and_optional_defaults() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-001",
        related_record_type="nonconformity",
        related_record_id="NCR-001",
        file_name="korkuluk-eksigi.jpg",
        file_path="attachments/ncr/NCR-001/korkuluk-eksigi.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_by="Santiye sefi",
        uploaded_at="2026-10-02T09:30:00",
    )

    assert attachment.attachment_id == "file-att-001"
    assert attachment.related_record_type == "nonconformity"
    assert attachment.related_record_id == "NCR-001"
    assert attachment.file_name == "korkuluk-eksigi.jpg"
    assert attachment.file_path == "attachments/ncr/NCR-001/korkuluk-eksigi.jpg"
    assert attachment.file_type == "image"
    assert attachment.mime_type == "image/jpeg"
    assert attachment.uploaded_by == "Santiye sefi"
    assert attachment.uploaded_at == "2026-10-02T09:30:00"
    assert attachment.original_file_name is None
    assert attachment.description is None
    assert attachment.notes is None
    assert attachment.file_size is None


def test_file_attachment_record_stores_original_file_name() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-original-001",
        related_record_type="concrete_pour",
        related_record_id="CP-000123",
        file_name="20260607_143210__concrete_pour__CP-000123__image__001.jpg",
        file_path=(
            "attachments/project-001/concrete/2026/06/07/CP-000123/"
            "20260607_143210__concrete_pour__CP-000123__image__001.jpg"
        ),
        file_type="image",
        mime_type="image/jpeg",
        uploaded_by="Santiye sefi",
        uploaded_at="2026-06-07T14:32:10",
        original_file_name="WhatsApp Image 2026-06-07 at 14.32.10.jpeg",
    )

    assert (
        attachment.file_name
        == "20260607_143210__concrete_pour__CP-000123__image__001.jpg"
    )
    assert (
        attachment.original_file_name
        == "WhatsApp Image 2026-06-07 at 14.32.10.jpeg"
    )


def test_file_attachment_record_uploaded_by_is_optional_metadata() -> None:
    attachment_with_uploader = FileAttachmentRecord(
        attachment_id="file-att-uploader-001",
        related_record_type="nonconformity",
        related_record_id="NCR-004",
        file_name="ncr-004-fotograf.jpg",
        file_path="attachments/nonconformity/NCR-004/ncr-004-fotograf.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_at="2026-10-02T12:00:00",
        uploaded_by="santiye_sefi",
    )
    attachment_without_uploader = FileAttachmentRecord(
        attachment_id="file-att-uploader-002",
        related_record_type="nonconformity",
        related_record_id="NCR-005",
        file_name="ncr-005-fotograf.jpg",
        file_path="attachments/nonconformity/NCR-005/ncr-005-fotograf.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_at="2026-10-02T12:10:00",
    )

    assert attachment_with_uploader.uploaded_by == "santiye_sefi"
    assert attachment_without_uploader.uploaded_by is None


def test_file_attachment_record_uploaded_at_is_optional_metadata() -> None:
    attachment_with_timestamp = FileAttachmentRecord(
        attachment_id="file-att-uploaded-at-001",
        related_record_type="nonconformity",
        related_record_id="NCR-006",
        file_name="ncr-006-fotograf.jpg",
        file_path="attachments/nonconformity/NCR-006/ncr-006-fotograf.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_at="2026-06-07T14:32:10",
    )
    attachment_without_timestamp = FileAttachmentRecord(
        attachment_id="file-att-uploaded-at-002",
        related_record_type="nonconformity",
        related_record_id="NCR-007",
        file_name="ncr-007-fotograf.jpg",
        file_path="attachments/nonconformity/NCR-007/ncr-007-fotograf.jpg",
        file_type="image",
        mime_type="image/jpeg",
    )

    assert attachment_with_timestamp.uploaded_at == "2026-06-07T14:32:10"
    assert attachment_without_timestamp.uploaded_at is None


def test_file_attachment_record_notes_describe_attachment_context() -> None:
    attachment_with_notes = FileAttachmentRecord(
        attachment_id="file-att-notes-001",
        related_record_type="concrete_pour",
        related_record_id="CP-000123",
        file_name="beton-oncesi-donati.jpg",
        file_path="attachments/concrete/CP-000123/beton-oncesi-donati.jpg",
        file_type="image",
        mime_type="image/jpeg",
        notes="Beton oncesi donati kontrol fotografi.",
    )
    attachment_without_notes = FileAttachmentRecord(
        attachment_id="file-att-notes-002",
        related_record_type="nonconformity",
        related_record_id="NCR-008",
        file_name="uygunsuzluk-saha-videosu.mp4",
        file_path="attachments/nonconformity/NCR-008/uygunsuzluk-saha-videosu.mp4",
        file_type="video",
        mime_type="video/mp4",
    )

    assert attachment_with_notes.notes == "Beton oncesi donati kontrol fotografi."
    assert attachment_without_notes.notes is None


def test_file_attachment_record_can_represent_video_metadata_reference() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-video-001",
        related_record_type="nonconformity",
        related_record_id="NCR-002",
        file_name="beton-dokum-oncesi.mp4",
        file_path="attachments/ncr/NCR-002/beton-dokum-oncesi.mp4",
        file_type="video",
        mime_type="video/mp4",
        uploaded_by="Kalite muhendisi",
        uploaded_at="2026-10-02T10:15:00",
        description="Beton dokum oncesi saha videosu.",
        file_size=52428800,
    )

    assert attachment.file_type == "video"
    assert attachment.mime_type == "video/mp4"
    assert attachment.file_name.endswith(".mp4")
    assert attachment.file_path == "attachments/ncr/NCR-002/beton-dokum-oncesi.mp4"
    assert attachment.description == "Beton dokum oncesi saha videosu."
    assert attachment.file_size == 52428800
    assert attachment.notes is None


def test_file_attachment_record_links_to_related_record_by_type_and_id() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-ncr-001",
        related_record_type="nonconformity",
        related_record_id="NCR-003",
        file_name="ncr-003-kanit.pdf",
        file_path="attachments/ncr/NCR-003/ncr-003-kanit.pdf",
        file_type="pdf",
        mime_type="application/pdf",
        uploaded_by="Santiye sefi",
        uploaded_at="2026-10-02T11:00:00",
        notes="NCR kaydina bagli kanit PDF'i.",
    )

    assert attachment.related_record_type == "nonconformity"
    assert attachment.related_record_id == "NCR-003"
    assert attachment.file_type == "pdf"
    assert attachment.mime_type == "application/pdf"
    assert attachment.notes == "NCR kaydina bagli kanit PDF'i."


def test_file_attachment_record_can_represent_image_type() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-image-001",
        related_record_type="site_note",
        related_record_id="NOTE-001",
        file_name="saha-duzeni.jpg",
        file_path="attachments/site-notes/NOTE-001/saha-duzeni.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_by="Santiye sefi",
        uploaded_at="2026-10-03T09:00:00",
    )

    assert attachment.file_type == "image"
    assert attachment.mime_type == "image/jpeg"
    assert attachment.file_name.endswith(".jpg")
    assert attachment.file_path == "attachments/site-notes/NOTE-001/saha-duzeni.jpg"


def test_file_attachment_record_can_represent_video_type() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-video-002",
        related_record_type="daily_log",
        related_record_id="LOG-001",
        file_name="ilerleme-videosu.mp4",
        file_path="attachments/daily-logs/LOG-001/ilerleme-videosu.mp4",
        file_type="video",
        mime_type="video/mp4",
        uploaded_by="Santiye sefi",
        uploaded_at="2026-10-03T09:30:00",
        description="Gunluk ilerleme videosu metadata referansi.",
    )

    assert attachment.file_type == "video"
    assert attachment.mime_type == "video/mp4"
    assert attachment.file_name.endswith(".mp4")
    assert attachment.description == "Gunluk ilerleme videosu metadata referansi."


def test_file_attachment_record_can_represent_pdf_type() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-pdf-001",
        related_record_type="nonconformity",
        related_record_id="NCR-004",
        file_name="ncr-tutanagi.pdf",
        file_path="attachments/ncr/NCR-004/ncr-tutanagi.pdf",
        file_type="pdf",
        mime_type="application/pdf",
        uploaded_by="Kalite muhendisi",
        uploaded_at="2026-10-03T10:00:00",
    )

    assert attachment.file_type == "pdf"
    assert attachment.mime_type == "application/pdf"
    assert attachment.file_name.endswith(".pdf")


def test_file_attachment_record_can_represent_document_type() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-document-001",
        related_record_type="material_delivery",
        related_record_id="MAT-DEL-001",
        file_name="malzeme-teslim-formu.docx",
        file_path="attachments/materials/MAT-DEL-001/malzeme-teslim-formu.docx",
        file_type="document",
        mime_type=(
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        ),
        uploaded_by="Depo sorumlusu",
        uploaded_at="2026-10-03T10:30:00",
    )

    assert attachment.file_type == "document"
    assert attachment.mime_type == (
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    )
    assert attachment.file_name.endswith(".docx")


def test_file_attachment_record_can_represent_audio_type() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-audio-001",
        related_record_type="site_note",
        related_record_id="NOTE-002",
        file_name="saha-notu-ses.mp3",
        file_path="attachments/site-notes/NOTE-002/saha-notu-ses.mp3",
        file_type="audio",
        mime_type="audio/mpeg",
        uploaded_by="Santiye sefi",
        uploaded_at="2026-10-03T11:00:00",
        description="Saha notu ses kaydi metadata referansi.",
    )

    assert attachment.file_type == "audio"
    assert attachment.mime_type == "audio/mpeg"
    assert attachment.file_name.endswith(".mp3")
    assert attachment.description == "Saha notu ses kaydi metadata referansi."


def test_file_attachment_record_can_represent_other_type() -> None:
    attachment = FileAttachmentRecord(
        attachment_id="file-att-other-001",
        related_record_type="daily_log",
        related_record_id="LOG-002",
        file_name="saha-verisi.bin",
        file_path="attachments/daily-logs/LOG-002/saha-verisi.bin",
        file_type="other",
        mime_type="application/octet-stream",
        uploaded_by="Santiye sefi",
        uploaded_at="2026-10-03T11:30:00",
        notes="Siniflandirilamayan dosya referansi.",
    )

    assert attachment.file_type == "other"
    assert attachment.mime_type == "application/octet-stream"
    assert attachment.file_name.endswith(".bin")
    assert attachment.notes == "Siniflandirilamayan dosya referansi."


def test_material_record_holds_values_and_defaults() -> None:
    material = MaterialRecord(
        material_name="C30 beton",
        supplier="ABC Beton",
        delivery_note_no="IRS-001",
        quantity=24.5,
        unit="m3",
        area="Temel",
        received_date="2026-06-05",
    )

    assert material.material_name == "C30 beton"
    assert material.supplier == "ABC Beton"
    assert material.delivery_note_no == "IRS-001"
    assert material.quantity == 24.5
    assert material.unit == "m3"
    assert material.area == "Temel"
    assert material.received_date == "2026-06-05"
    assert material.used_date is None
    assert material.notes is None
    assert material.status == "received"


def test_meeting_record_holds_values_and_defaults() -> None:
    meeting = MeetingRecord(
        meeting_title="Haftalik santiye koordinasyon toplantisi",
        meeting_date="2026-06-05",
        location="Santiye ofisi",
        organizer="Santiye sefi",
        participants="Isveren, yuklenici, taseron temsilcileri",
        agenda="Imalat ilerlemesi ve kalite kontrolleri",
    )

    assert meeting.meeting_title == "Haftalik santiye koordinasyon toplantisi"
    assert meeting.meeting_date == "2026-06-05"
    assert meeting.location == "Santiye ofisi"
    assert meeting.organizer == "Santiye sefi"
    assert meeting.participants == "Isveren, yuklenici, taseron temsilcileri"
    assert meeting.agenda == "Imalat ilerlemesi ve kalite kontrolleri"
    assert meeting.decisions is None
    assert meeting.notes is None
    assert meeting.status == "draft"


def test_meeting_action_record_holds_values_and_defaults() -> None:
    action = MeetingActionRecord(
        action_title="Temel izolasyon detayini kontrol et",
        meeting_title="Haftalik santiye koordinasyon toplantisi",
        responsible="Saha muhendisi",
        due_date="2026-06-12",
    )

    assert action.action_title == "Temel izolasyon detayini kontrol et"
    assert action.meeting_title == "Haftalik santiye koordinasyon toplantisi"
    assert action.responsible == "Saha muhendisi"
    assert action.due_date == "2026-06-12"
    assert action.notes is None
    assert action.status == "open"


def test_rfi_record_holds_values_and_defaults() -> None:
    rfi = RFIRecord(
        subject="Temel drenaj detayi",
        question="Drenaj borusu kotu nasil uygulanacak?",
        requested_by="Santiye sefi",
        assigned_to="Proje muellifi",
        request_date="2026-06-05",
        due_date="2026-06-12",
    )

    assert rfi.subject == "Temel drenaj detayi"
    assert rfi.question == "Drenaj borusu kotu nasil uygulanacak?"
    assert rfi.requested_by == "Santiye sefi"
    assert rfi.assigned_to == "Proje muellifi"
    assert rfi.request_date == "2026-06-05"
    assert rfi.due_date == "2026-06-12"
    assert rfi.answer is None
    assert rfi.notes is None
    assert rfi.status == "open"


def test_submittal_record_holds_values_and_defaults() -> None:
    submittal = SubmittalRecord(
        subject="Seramik teknik foyi",
        submitted_by="Yuklenici",
        submitted_to="Isveren temsilcisi",
        submit_date="2026-06-05",
        review_due_date="2026-06-12",
    )

    assert submittal.subject == "Seramik teknik foyi"
    assert submittal.submitted_by == "Yuklenici"
    assert submittal.submitted_to == "Isveren temsilcisi"
    assert submittal.submit_date == "2026-06-05"
    assert submittal.review_due_date == "2026-06-12"
    assert submittal.response is None
    assert submittal.notes is None
    assert submittal.status == "submitted"


def test_daily_report_record_holds_values_and_defaults() -> None:
    report = DailyReportRecord(
        report_date="2026-06-05",
        weather="Gunesli",
        work_summary="Temel izolasyon imalati tamamlandi.",
        manpower_summary="12 isci, 1 formen sahada calisti.",
        equipment_summary="1 ekskavator ve 1 vinc kullanildi.",
        material_summary="Izolasyon membrani sahaya alindi.",
        issue_summary="Kuzey cephede drenaj detayi netlestirilecek.",
        safety_summary="Is guvenligi uygunsuzlugu gorulmedi.",
        prepared_by="Santiye sefi",
    )

    assert report.report_date == "2026-06-05"
    assert report.weather == "Gunesli"
    assert report.work_summary == "Temel izolasyon imalati tamamlandi."
    assert report.manpower_summary == "12 isci, 1 formen sahada calisti."
    assert report.equipment_summary == "1 ekskavator ve 1 vinc kullanildi."
    assert report.material_summary == "Izolasyon membrani sahaya alindi."
    assert report.issue_summary == "Kuzey cephede drenaj detayi netlestirilecek."
    assert report.safety_summary == "Is guvenligi uygunsuzlugu gorulmedi."
    assert report.prepared_by == "Santiye sefi"
    assert report.notes is None
    assert report.status == "draft"


def test_project_party_record_holds_values_and_defaults() -> None:
    party = ProjectPartyRecord(
        party_name="ABC Insaat A.S.",
        party_type="Yuklenici",
        role="Ana yuklenici",
        tax_or_id_no="1234567890",
        phone="+90 212 000 00 00",
        email="info@example.com",
        address="Istanbul",
    )

    assert party.party_name == "ABC Insaat A.S."
    assert party.party_type == "Yuklenici"
    assert party.role == "Ana yuklenici"
    assert party.tax_or_id_no == "1234567890"
    assert party.phone == "+90 212 000 00 00"
    assert party.email == "info@example.com"
    assert party.address == "Istanbul"
    assert party.notes is None
    assert party.status == "active"


def test_contact_person_record_holds_values_and_defaults() -> None:
    person = ContactPersonRecord(
        full_name="Ali Yilmaz",
        organization="ABC Insaat A.S.",
        role="Saha muhendisi",
        phone="+90 532 000 00 00",
        email="ali.yilmaz@example.com",
        responsibility_area="Betonarme imalat",
    )

    assert person.full_name == "Ali Yilmaz"
    assert person.organization == "ABC Insaat A.S."
    assert person.role == "Saha muhendisi"
    assert person.phone == "+90 532 000 00 00"
    assert person.email == "ali.yilmaz@example.com"
    assert person.responsibility_area == "Betonarme imalat"
    assert person.notes is None
    assert person.status == "active"


def test_site_location_record_holds_values_and_defaults() -> None:
    location = SiteLocationRecord(
        location_name="A Blok 3. Kat Kuzey Cephe",
        block="A Blok",
        floor="3. Kat",
        zone="Kuzey cephe",
        axis="A-B / 1-4",
        discipline="Mimari",
        description="Cephe kaplama calisma alani",
    )

    assert location.location_name == "A Blok 3. Kat Kuzey Cephe"
    assert location.block == "A Blok"
    assert location.floor == "3. Kat"
    assert location.zone == "Kuzey cephe"
    assert location.axis == "A-B / 1-4"
    assert location.discipline == "Mimari"
    assert location.description == "Cephe kaplama calisma alani"
    assert location.notes is None
    assert location.status == "active"


def test_workforce_record_holds_values_and_defaults() -> None:
    workforce = WorkforceRecord(
        crew_name="Kalip ekibi",
        crew_type="kalip",
        company="ABC Kalip Tas.",
        worker_count=12,
        work_area="A Blok 2. Kat",
        work_date="2026-06-05",
        task_description="Doseme kalip imalati",
    )

    assert workforce.crew_name == "Kalip ekibi"
    assert workforce.crew_type == "kalip"
    assert workforce.company == "ABC Kalip Tas."
    assert workforce.worker_count == 12
    assert workforce.work_area == "A Blok 2. Kat"
    assert workforce.work_date == "2026-06-05"
    assert workforce.task_description == "Doseme kalip imalati"
    assert workforce.notes is None
    assert workforce.status == "active"


def test_equipment_record_holds_values_and_defaults() -> None:
    equipment = EquipmentRecord(
        equipment_name="Kule vinc",
        equipment_type="vinc",
        owner_company="ABC Makine Kiralama",
        serial_or_plate="KV-34-001",
        work_area="A Blok saha geneli",
        assigned_to="Kalip ekibi",
    )

    assert equipment.equipment_name == "Kule vinc"
    assert equipment.equipment_type == "vinc"
    assert equipment.owner_company == "ABC Makine Kiralama"
    assert equipment.serial_or_plate == "KV-34-001"
    assert equipment.work_area == "A Blok saha geneli"
    assert equipment.assigned_to == "Kalip ekibi"
    assert equipment.notes is None
    assert equipment.status == "available"


def test_supplier_record_holds_values_and_defaults() -> None:
    supplier = SupplierRecord(
        supplier_name="ABC Beton",
        supplier_type="malzeme tedarikcisi",
        contact_person="Ayse Demir",
        phone="+90 212 111 22 33",
        email="ayse.demir@example.com",
        service_area="Hazir beton tedariki",
    )

    assert supplier.supplier_name == "ABC Beton"
    assert supplier.supplier_type == "malzeme tedarikcisi"
    assert supplier.contact_person == "Ayse Demir"
    assert supplier.phone == "+90 212 111 22 33"
    assert supplier.email == "ayse.demir@example.com"
    assert supplier.service_area == "Hazir beton tedariki"
    assert supplier.notes is None
    assert supplier.status == "active"


def test_site_note_record_holds_values_and_defaults() -> None:
    site_note = SiteNoteRecord(
        note_title="Kuzey cephe iskele kontrolu",
        note_type="uyari",
        location="A Blok kuzey cephe",
        related_subject="Iskele guvenligi",
        note_date="2026-06-05",
    )

    assert site_note.note_title == "Kuzey cephe iskele kontrolu"
    assert site_note.note_type == "uyari"
    assert site_note.location == "A Blok kuzey cephe"
    assert site_note.related_subject == "Iskele guvenligi"
    assert site_note.note_date == "2026-06-05"
    assert site_note.notes is None
    assert site_note.status == "open"


def test_task_candidate_record_holds_values_and_defaults() -> None:
    task_candidate = TaskCandidateRecord(
        task_title="Kuzey cephe iskele kontrolu takip et",
        task_type="takip",
        related_area="A Blok kuzey cephe",
        source="Saha notu",
        target_date="2026-06-12",
    )

    assert task_candidate.task_title == "Kuzey cephe iskele kontrolu takip et"
    assert task_candidate.task_type == "takip"
    assert task_candidate.related_area == "A Blok kuzey cephe"
    assert task_candidate.source == "Saha notu"
    assert task_candidate.target_date == "2026-06-12"
    assert task_candidate.notes is None
    assert task_candidate.status == "open"


def test_checklist_item_record_holds_values_and_defaults() -> None:
    checklist_item = ChecklistItemRecord(
        item_title="Kuzey cephe iskele kontrolu",
        item_category="is guvenligi",
        related_area="A Blok kuzey cephe",
        check_reference="Saha gozlemi",
    )

    assert checklist_item.item_title == "Kuzey cephe iskele kontrolu"
    assert checklist_item.item_category == "is guvenligi"
    assert checklist_item.related_area == "A Blok kuzey cephe"
    assert checklist_item.check_reference == "Saha gozlemi"
    assert checklist_item.notes is None
    assert checklist_item.status == "pending"


def test_check_result_record_holds_values_and_defaults() -> None:
    check_result = CheckResultRecord(
        check_title="Kuzey cephe iskele kontrol sonucu",
        check_area="A Blok kuzey cephe",
        result="Uygun",
        checked_by="Santiye sefi",
        check_date="2026-06-05",
    )

    assert check_result.check_title == "Kuzey cephe iskele kontrol sonucu"
    assert check_result.check_area == "A Blok kuzey cephe"
    assert check_result.result == "Uygun"
    assert check_result.checked_by == "Santiye sefi"
    assert check_result.check_date == "2026-06-05"
    assert check_result.notes is None
    assert check_result.status == "recorded"


def test_nonconformity_candidate_record_holds_values_and_defaults() -> None:
    candidate = NonconformityCandidateRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        candidate_type="eksik",
        location="A Blok kuzey cephe",
        observed_issue="Korkuluk ara elemani eksik goruldu",
        detected_by="Santiye sefi",
        detection_date="2026-06-05",
    )

    assert candidate.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert candidate.candidate_type == "eksik"
    assert candidate.location == "A Blok kuzey cephe"
    assert candidate.observed_issue == "Korkuluk ara elemani eksik goruldu"
    assert candidate.detected_by == "Santiye sefi"
    assert candidate.detection_date == "2026-06-05"
    assert candidate.notes is None
    assert candidate.status == "open"


def test_nonconformity_candidate_review_record_holds_values_and_defaults() -> None:
    review = NonconformityCandidateReviewRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        reviewed_by="Santiye sefi",
        review_date="2026-06-06",
        review_result="takip gerekli",
        decision_reason="Eksik parca guvenlik riski olusturuyor",
        next_action="Korkuluk eksigi icin gorev adayi ac",
    )

    assert review.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert review.reviewed_by == "Santiye sefi"
    assert review.review_date == "2026-06-06"
    assert review.review_result == "takip gerekli"
    assert review.decision_reason == "Eksik parca guvenlik riski olusturuyor"
    assert review.next_action == "Korkuluk eksigi icin gorev adayi ac"
    assert review.status == "reviewed"
    assert review.notes is None


def test_nonconformity_candidate_action_record_holds_values_and_defaults() -> None:
    action = NonconformityCandidateActionRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        review_result="takip gerekli",
        action_decision="gorev adayi ac",
        action_owner="Saha ekibi",
        target_date="2026-06-10",
        action_description="Korkuluk ara elemani tamamlanacak",
    )

    assert action.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert action.review_result == "takip gerekli"
    assert action.action_decision == "gorev adayi ac"
    assert action.action_owner == "Saha ekibi"
    assert action.target_date == "2026-06-10"
    assert action.action_description == "Korkuluk ara elemani tamamlanacak"
    assert action.status == "planned"
    assert action.notes is None


def test_nonconformity_candidate_tracking_summary_record_holds_values_and_defaults() -> None:
    summary = NonconformityCandidateTrackingSummaryRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        review_result="takip gerekli",
        action_decision="gorev adayi ac",
        action_owner="Saha ekibi",
        tracking_status="aksiyon bekliyor",
        last_update_date="2026-06-11",
        summary_note="Korkuluk eksigi icin saha ekibi aksiyonu bekleniyor",
    )

    assert summary.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert summary.review_result == "takip gerekli"
    assert summary.action_decision == "gorev adayi ac"
    assert summary.action_owner == "Saha ekibi"
    assert summary.tracking_status == "aksiyon bekliyor"
    assert summary.last_update_date == "2026-06-11"
    assert summary.summary_note == "Korkuluk eksigi icin saha ekibi aksiyonu bekleniyor"
    assert summary.status == "active"
    assert summary.notes is None


def test_nonconformity_candidate_process_view_record_holds_values_and_defaults() -> None:
    process_view = NonconformityCandidateProcessViewRecord(
        candidate_id="NCR-CAND-001",
        check_result_id="CHK-RES-001",
        review_id="NCR-CAND-REV-001",
        action_id="NCR-CAND-ACT-001",
        tracking_summary_id="NCR-CAND-TRK-001",
        attachment_count=2,
        current_status="aksiyon bekliyor",
        last_update_date="2026-06-12",
        process_summary="Korkuluk eksigi degerlendirildi ve saha aksiyonu bekleniyor.",
    )

    assert process_view.candidate_id == "NCR-CAND-001"
    assert process_view.check_result_id == "CHK-RES-001"
    assert process_view.review_id == "NCR-CAND-REV-001"
    assert process_view.action_id == "NCR-CAND-ACT-001"
    assert process_view.tracking_summary_id == "NCR-CAND-TRK-001"
    assert process_view.attachment_count == 2
    assert process_view.current_status == "aksiyon bekliyor"
    assert process_view.last_update_date == "2026-06-12"
    assert (
        process_view.process_summary
        == "Korkuluk eksigi degerlendirildi ve saha aksiyonu bekleniyor."
    )
    assert process_view.notes is None


def test_nonconformity_candidate_process_view_record_defaults() -> None:
    process_view = NonconformityCandidateProcessViewRecord(
        candidate_id="NCR-CAND-002",
    )

    assert process_view.candidate_id == "NCR-CAND-002"
    assert process_view.check_result_id is None
    assert process_view.review_id is None
    assert process_view.action_id is None
    assert process_view.tracking_summary_id is None
    assert process_view.attachment_count == 0
    assert process_view.current_status == "open"
    assert process_view.last_update_date is None
    assert process_view.process_summary is None
    assert process_view.notes is None


def test_nonconformity_candidate_status_history_record_holds_values_and_defaults() -> None:
    history = NonconformityCandidateStatusHistoryRecord(
        candidate_id="NCR-CAND-001",
        old_status="open",
        new_status="under_review",
        change_reason="Aday uygunsuzluk degerlendirmeye alindi.",
        changed_by="Santiye sefi",
        change_date="2026-06-13",
        source_record="NonconformityCandidateReviewRecord",
    )

    assert history.candidate_id == "NCR-CAND-001"
    assert history.old_status == "open"
    assert history.new_status == "under_review"
    assert history.change_reason == "Aday uygunsuzluk degerlendirmeye alindi."
    assert history.changed_by == "Santiye sefi"
    assert history.change_date == "2026-06-13"
    assert history.source_record == "NonconformityCandidateReviewRecord"
    assert history.notes is None


def test_nonconformity_candidate_status_history_record_optional_fields_default_to_none() -> None:
    history = NonconformityCandidateStatusHistoryRecord(
        candidate_id="NCR-CAND-002",
        old_status="under_review",
        new_status="action_planned",
        change_reason="Aksiyon karari verildi.",
        changed_by="Saha muhendisi",
        change_date="2026-06-14",
    )

    assert history.candidate_id == "NCR-CAND-002"
    assert history.old_status == "under_review"
    assert history.new_status == "action_planned"
    assert history.change_reason == "Aksiyon karari verildi."
    assert history.changed_by == "Saha muhendisi"
    assert history.change_date == "2026-06-14"
    assert history.source_record is None
    assert history.notes is None


def test_nonconformity_candidate_assignment_record_holds_values_and_defaults() -> None:
    assignment = NonconformityCandidateAssignmentRecord(
        candidate_id="NCR-CAND-001",
        assigned_to="Saha muhendisi",
        assigned_by="Santiye sefi",
        assignment_date="2026-06-15",
        due_date="2026-06-18",
        responsibility_note="Korkuluk eksigi sahada takip edilecek.",
        priority="high",
    )

    assert assignment.candidate_id == "NCR-CAND-001"
    assert assignment.assigned_to == "Saha muhendisi"
    assert assignment.assigned_by == "Santiye sefi"
    assert assignment.assignment_date == "2026-06-15"
    assert assignment.due_date == "2026-06-18"
    assert assignment.responsibility_note == "Korkuluk eksigi sahada takip edilecek."
    assert assignment.priority == "high"
    assert assignment.status == "assigned"
    assert assignment.notes is None


def test_nonconformity_candidate_assignment_record_optional_fields_default() -> None:
    assignment = NonconformityCandidateAssignmentRecord(
        candidate_id="NCR-CAND-002",
        assigned_to="Kalite sorumlusu",
        assigned_by="Santiye sefi",
        assignment_date="2026-06-16",
    )

    assert assignment.candidate_id == "NCR-CAND-002"
    assert assignment.assigned_to == "Kalite sorumlusu"
    assert assignment.assigned_by == "Santiye sefi"
    assert assignment.assignment_date == "2026-06-16"
    assert assignment.due_date is None
    assert assignment.responsibility_note is None
    assert assignment.priority == "normal"
    assert assignment.status == "assigned"
    assert assignment.notes is None


def test_nonconformity_candidate_closure_record_holds_values_and_defaults() -> None:
    closure = NonconformityCandidateClosureRecord(
        candidate_id="NCR-CAND-001",
        closure_decision="takip tamamlandi",
        closure_reason="Korkuluk eksigi sahada giderildi.",
        closed_by="Santiye sefi",
        closure_date="2026-06-19",
        final_status="closed",
        result_note="Yerinde kontrol sonrasi aday kayit kapatildi.",
        requires_follow_up=True,
    )

    assert closure.candidate_id == "NCR-CAND-001"
    assert closure.closure_decision == "takip tamamlandi"
    assert closure.closure_reason == "Korkuluk eksigi sahada giderildi."
    assert closure.closed_by == "Santiye sefi"
    assert closure.closure_date == "2026-06-19"
    assert closure.final_status == "closed"
    assert closure.result_note == "Yerinde kontrol sonrasi aday kayit kapatildi."
    assert closure.requires_follow_up is True
    assert closure.notes is None


def test_nonconformity_candidate_closure_record_optional_fields_default() -> None:
    closure = NonconformityCandidateClosureRecord(
        candidate_id="NCR-CAND-002",
        closure_decision="kesin uygunsuzluga donustur",
        closure_reason="Eksik giderilmedigi icin resmi kayit gerekli.",
        closed_by="Kalite sorumlusu",
        closure_date="2026-06-20",
        final_status="converted_to_ncr",
    )

    assert closure.candidate_id == "NCR-CAND-002"
    assert closure.closure_decision == "kesin uygunsuzluga donustur"
    assert closure.closure_reason == "Eksik giderilmedigi icin resmi kayit gerekli."
    assert closure.closed_by == "Kalite sorumlusu"
    assert closure.closure_date == "2026-06-20"
    assert closure.final_status == "converted_to_ncr"
    assert closure.result_note is None
    assert closure.requires_follow_up is False
    assert closure.notes is None


def test_nonconformity_candidate_conversion_record_holds_values_and_defaults() -> None:
    conversion = NonconformityCandidateConversionRecord(
        candidate_id="NCR-CAND-001",
        nonconformity_id="NCR-001",
        conversion_decision="kesin uygunsuzluga donustur",
        conversion_reason="Eksik giderilmedigi icin resmi NCR kaydi acildi.",
        converted_by="Kalite sorumlusu",
        conversion_date="2026-06-21",
        source_closure_id="NCR-CAND-CLOS-001",
    )

    assert conversion.candidate_id == "NCR-CAND-001"
    assert conversion.nonconformity_id == "NCR-001"
    assert conversion.conversion_decision == "kesin uygunsuzluga donustur"
    assert conversion.conversion_reason == "Eksik giderilmedigi icin resmi NCR kaydi acildi."
    assert conversion.converted_by == "Kalite sorumlusu"
    assert conversion.conversion_date == "2026-06-21"
    assert conversion.source_closure_id == "NCR-CAND-CLOS-001"
    assert conversion.status == "converted"
    assert conversion.notes is None


def test_nonconformity_candidate_conversion_record_optional_fields_default() -> None:
    conversion = NonconformityCandidateConversionRecord(
        candidate_id="NCR-CAND-002",
        nonconformity_id="NCR-002",
        conversion_decision="resmi NCR ac",
        conversion_reason="Aday bulgu kesin uygunsuzluk olarak degerlendirildi.",
        converted_by="Santiye sefi",
        conversion_date="2026-06-22",
    )

    assert conversion.candidate_id == "NCR-CAND-002"
    assert conversion.nonconformity_id == "NCR-002"
    assert conversion.conversion_decision == "resmi NCR ac"
    assert conversion.conversion_reason == "Aday bulgu kesin uygunsuzluk olarak degerlendirildi."
    assert conversion.converted_by == "Santiye sefi"
    assert conversion.conversion_date == "2026-06-22"
    assert conversion.source_closure_id is None
    assert conversion.status == "converted"
    assert conversion.notes is None


def test_nonconformity_process_view_record_holds_values_and_defaults() -> None:
    process_view = NonconformityProcessViewRecord(
        nonconformity_id="NCR-001",
        source_candidate_id="NCR-CAND-001",
        conversion_record_id="NCR-CAND-CONV-001",
        title="Kuzey cephe korkuluk eksigi",
        nonconformity_type="is guvenligi",
        severity="high",
        responsible_party="Saha ekibi",
        current_status="in_progress",
        final_status="open",
        last_update_date="2026-06-23",
        process_summary="Aday kayittan kesin uygunsuzluga donustu ve saha ekibi takibinde.",
    )

    assert process_view.nonconformity_id == "NCR-001"
    assert process_view.source_candidate_id == "NCR-CAND-001"
    assert process_view.conversion_record_id == "NCR-CAND-CONV-001"
    assert process_view.title == "Kuzey cephe korkuluk eksigi"
    assert process_view.nonconformity_type == "is guvenligi"
    assert process_view.severity == "high"
    assert process_view.responsible_party == "Saha ekibi"
    assert process_view.current_status == "in_progress"
    assert process_view.final_status == "open"
    assert process_view.last_update_date == "2026-06-23"
    assert (
        process_view.process_summary
        == "Aday kayittan kesin uygunsuzluga donustu ve saha ekibi takibinde."
    )
    assert process_view.notes is None


def test_nonconformity_process_view_record_optional_fields_default() -> None:
    process_view = NonconformityProcessViewRecord(
        nonconformity_id="NCR-002",
    )

    assert process_view.nonconformity_id == "NCR-002"
    assert process_view.source_candidate_id is None
    assert process_view.conversion_record_id is None
    assert process_view.title is None
    assert process_view.nonconformity_type is None
    assert process_view.severity == "medium"
    assert process_view.responsible_party is None
    assert process_view.current_status == "open"
    assert process_view.final_status is None
    assert process_view.last_update_date is None
    assert process_view.process_summary is None
    assert process_view.notes is None


def test_nonconformity_status_history_record_holds_values_and_defaults() -> None:
    history = NonconformityStatusHistoryRecord(
        nonconformity_id="NCR-001",
        old_status="open",
        new_status="in_review",
        change_reason="Kesin uygunsuzluk kalite incelemesine alindi.",
        changed_by="Kalite sorumlusu",
        change_date="2026-06-24",
        source_record="NonconformityProcessViewRecord",
    )

    assert history.nonconformity_id == "NCR-001"
    assert history.old_status == "open"
    assert history.new_status == "in_review"
    assert history.change_reason == "Kesin uygunsuzluk kalite incelemesine alindi."
    assert history.changed_by == "Kalite sorumlusu"
    assert history.change_date == "2026-06-24"
    assert history.source_record == "NonconformityProcessViewRecord"
    assert history.notes is None


def test_nonconformity_status_history_record_optional_fields_default() -> None:
    history = NonconformityStatusHistoryRecord(
        nonconformity_id="NCR-002",
        old_status="in_review",
        new_status="action_waiting",
        change_reason="Saha aksiyonu bekleniyor.",
        changed_by="Santiye sefi",
        change_date="2026-06-25",
    )

    assert history.nonconformity_id == "NCR-002"
    assert history.old_status == "in_review"
    assert history.new_status == "action_waiting"
    assert history.change_reason == "Saha aksiyonu bekleniyor."
    assert history.changed_by == "Santiye sefi"
    assert history.change_date == "2026-06-25"
    assert history.source_record is None
    assert history.notes is None


def test_nonconformity_assignment_record_holds_values_and_defaults() -> None:
    assignment = NonconformityAssignmentRecord(
        nonconformity_id="NCR-001",
        assigned_to="Saha kalite ekibi",
        assigned_role="quality_team",
        assigned_by="Santiye sefi",
        assigned_date="2026-06-26",
        responsibility_scope="Korkuluk eksiginin saha aksiyonunu takip et.",
        due_date="2026-06-30",
    )

    assert assignment.nonconformity_id == "NCR-001"
    assert assignment.assigned_to == "Saha kalite ekibi"
    assert assignment.assigned_role == "quality_team"
    assert assignment.assigned_by == "Santiye sefi"
    assert assignment.assigned_date == "2026-06-26"
    assert assignment.responsibility_scope == "Korkuluk eksiginin saha aksiyonunu takip et."
    assert assignment.due_date == "2026-06-30"
    assert assignment.status == "assigned"
    assert assignment.notes is None


def test_nonconformity_corrective_action_record_holds_values_and_defaults() -> None:
    action = NonconformityCorrectiveActionRecord(
        nonconformity_id="NCR-001",
        action_title="Korkuluk eksigini tamamla",
        action_description="Kuzey cephede eksik korkuluk imalati tamamlanacak.",
        responsible_party="Alt yuklenici saha ekibi",
        planned_start_date="2026-06-27",
        due_date="2026-07-02",
    )

    assert action.nonconformity_id == "NCR-001"
    assert action.action_title == "Korkuluk eksigini tamamla"
    assert action.action_description == "Kuzey cephede eksik korkuluk imalati tamamlanacak."
    assert action.responsible_party == "Alt yuklenici saha ekibi"
    assert action.planned_start_date == "2026-06-27"
    assert action.due_date == "2026-07-02"
    assert action.completion_date is None
    assert action.verification_required is True
    assert action.status == "planned"
    assert action.notes is None


def test_nonconformity_corrective_action_verification_record_holds_values_and_defaults() -> None:
    verification = NonconformityCorrectiveActionVerificationRecord(
        corrective_action_id="NCR-CA-001",
        nonconformity_id="NCR-001",
        verified_by="Kalite kontrol sorumlusu",
        verification_date="2026-07-03",
        verification_result="accepted",
        verification_notes="Korkuluk imalati yerinde kontrol edildi ve uygun bulundu.",
    )

    assert verification.corrective_action_id == "NCR-CA-001"
    assert verification.nonconformity_id == "NCR-001"
    assert verification.verified_by == "Kalite kontrol sorumlusu"
    assert verification.verification_date == "2026-07-03"
    assert verification.verification_result == "accepted"
    assert (
        verification.verification_notes
        == "Korkuluk imalati yerinde kontrol edildi ve uygun bulundu."
    )
    assert verification.requires_rework is False
    assert verification.next_action is None
    assert verification.status == "verified"
    assert verification.notes is None


def test_nonconformity_closure_record_holds_values_and_defaults() -> None:
    closure = NonconformityClosureRecord(
        nonconformity_id="NCR-001",
        closure_date="2026-07-04",
        closed_by="Kalite muduru",
        closure_result="accepted_and_closed",
        closure_reason="Duzeltici faaliyet dogrulandi ve NCR kapatildi.",
        verified_action_id="NCR-CAV-001",
    )

    assert closure.nonconformity_id == "NCR-001"
    assert closure.closure_date == "2026-07-04"
    assert closure.closed_by == "Kalite muduru"
    assert closure.closure_result == "accepted_and_closed"
    assert closure.closure_reason == "Duzeltici faaliyet dogrulandi ve NCR kapatildi."
    assert closure.verified_action_id == "NCR-CAV-001"
    assert closure.final_status == "closed"
    assert closure.requires_follow_up is False
    assert closure.follow_up_note is None
    assert closure.notes is None
