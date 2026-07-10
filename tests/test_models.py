import json
from copy import deepcopy

import pytest

from app.models import (
    AUDIT_EVENT_TYPE_SET,
    AUDIT_EVENT_TYPES,
    AUDIT_TARGET_RECORD_TYPE_SET,
    AUDIT_TARGET_RECORD_TYPES,
    RECORD_ID_PREFIXES,
    TARGET_RECORD_TYPE_TO_ID_FAMILY,
    TARGET_RECORD_TYPE_TO_ID_PREFIXES,
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
    build_export_handover_qc_review_checklist,
    build_export_result_report,
    build_export_result_summary,
    build_record_id_diagnostic_report,
    build_record_id_soft_validation_report,
    diagnose_record_id_for_target_type,
    format_export_handover_qc_review_checklist_as_markdown,
    format_export_result_report_as_markdown,
    format_export_result_summary_as_markdown,
    format_record_id_diagnostic_report_as_json_ready_dict,
    format_record_id_diagnostic_report_as_markdown,
    format_record_id_soft_validation_report_as_json_ready_dict,
    format_record_id_soft_validation_report_as_markdown,
    get_allowed_record_id_prefixes_for_target_type,
    get_record_id_family_for_target_type,
    try_write_json_ready_dict_to_file,
    try_write_markdown_text_to_file,
    write_json_ready_dict_to_file,
    write_markdown_text_to_file,
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
        target_record_type="project_record",
        target_record_id="NCR-001",
        reason="Kayit kapatma sonrasi arsivlendi.",
        old_value="open",
        new_value="archived",
        source="manual_review",
        notes="Sadece olay izi; otomatik arsivleme davranisi yok.",
    )

    assert event.target_record_type == "project_record"
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


def test_audit_event_record_does_not_validate_optional_metadata_empty_strings_yet() -> None:
    event = AuditEventRecord(
        **_valid_audit_event_kwargs(),
        reason="",
        old_value="",
        new_value="",
        source="",
        notes="",
    )

    assert event.target_record_type is None
    assert event.target_record_id is None
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


def test_audit_target_record_types_include_initial_contract_values() -> None:
    expected_values = {
        "project",
        "project_record",
        "attachment",
        "attachment_metadata",
        "attachment_integrity_report",
        "json_export",
        "backup_package",
        "restore_operation",
        "handover_package",
        "audit_event",
    }

    assert expected_values.issubset(AUDIT_TARGET_RECORD_TYPES)


def test_audit_target_record_type_set_matches_tuple_without_duplicates() -> None:
    assert AUDIT_TARGET_RECORD_TYPE_SET == frozenset(AUDIT_TARGET_RECORD_TYPES)
    assert len(AUDIT_TARGET_RECORD_TYPES) == len(AUDIT_TARGET_RECORD_TYPE_SET)


def test_audit_event_record_accepts_supported_target_record_type() -> None:
    values = _valid_audit_event_kwargs()
    values["event_type"] = "attachment.linked"
    values["target_record_type"] = "attachment"
    values["target_record_id"] = "ATT-2026-0001"

    event = AuditEventRecord(
        **values,
    )

    assert event.target_record_type == "attachment"
    assert event.target_record_id == "ATT-2026-0001"


def test_audit_event_record_rejects_unsupported_target_record_type() -> None:
    values = _valid_audit_event_kwargs()
    values["target_record_type"] = "unknown_record"
    values["target_record_id"] = "REC-1"

    with pytest.raises(ValueError, match="target_record_type is not supported"):
        AuditEventRecord(**values)


def test_audit_event_record_rejects_empty_target_record_type() -> None:
    for empty_value in ("", "   "):
        values = _valid_audit_event_kwargs()
        values["target_record_type"] = empty_value
        values["target_record_id"] = "REC-1"

        with pytest.raises(ValueError, match="target_record_type is required"):
            AuditEventRecord(**values)


def test_audit_event_record_rejects_empty_target_record_id() -> None:
    for empty_value in ("", "   "):
        values = _valid_audit_event_kwargs()
        values["target_record_type"] = "project_record"
        values["target_record_id"] = empty_value

        with pytest.raises(ValueError, match="target_record_id is required"):
            AuditEventRecord(**values)


def test_record_id_mapping_returns_family_for_supported_target_record_type() -> None:
    assert RECORD_ID_PREFIXES["PROJECT"] == "PRJ"
    assert get_record_id_family_for_target_type("project") == ("PROJECT",)
    assert get_record_id_family_for_target_type("attachment") == (
        "FILE_ATTACHMENT",
    )
    assert "NONCONFORMITY" in TARGET_RECORD_TYPE_TO_ID_FAMILY["project_record"]
    assert "MATERIAL_DELIVERY" in get_record_id_family_for_target_type(
        "project_record"
    )


def test_record_id_mapping_returns_allowed_prefixes_for_supported_target_type() -> None:
    assert get_allowed_record_id_prefixes_for_target_type("project") == (
        "PRJ",
        "prj",
    )
    assert get_allowed_record_id_prefixes_for_target_type("attachment") == (
        "ATT",
        "file-att",
        "att",
    )
    assert "NCR" in TARGET_RECORD_TYPE_TO_ID_PREFIXES["project_record"]
    assert "REC" in get_allowed_record_id_prefixes_for_target_type(
        "project_record"
    )


def test_record_id_mapping_helpers_reject_unknown_target_record_type() -> None:
    with pytest.raises(ValueError, match="target_record_type is not supported"):
        get_record_id_family_for_target_type("unknown_record")

    with pytest.raises(ValueError, match="target_record_type is not supported"):
        get_allowed_record_id_prefixes_for_target_type("unknown_record")


def test_record_id_diagnostic_returns_info_for_canonical_id() -> None:
    diagnostic = diagnose_record_id_for_target_type(
        "attachment",
        "ATT-2026-0001",
    )

    assert diagnostic["target_record_type"] == "attachment"
    assert diagnostic["target_record_id"] == "ATT-2026-0001"
    assert diagnostic["expected_family"] == ("FILE_ATTACHMENT",)
    assert diagnostic["allowed_prefixes"] == ("ATT", "file-att", "att")
    assert diagnostic["observed_prefix"] == "ATT"
    assert diagnostic["is_compatible"] is True
    assert diagnostic["severity"] == "info"
    assert diagnostic["message"]


def test_record_id_diagnostic_returns_warning_for_legacy_id() -> None:
    diagnostic = diagnose_record_id_for_target_type(
        "attachment",
        "file-att-001",
    )

    assert diagnostic["observed_prefix"] == "file-att"
    assert diagnostic["is_compatible"] is True
    assert diagnostic["severity"] == "warning"

    event = AuditEventRecord(
        **_valid_audit_event_kwargs(),
        target_record_type="attachment",
        target_record_id="file-att-001",
    )
    assert event.target_record_id == "file-att-001"


def test_record_id_diagnostic_returns_warning_for_unmatched_prefix() -> None:
    diagnostic = diagnose_record_id_for_target_type(
        "project_record",
        "XYZ-001",
    )

    assert diagnostic["observed_prefix"] == "XYZ"
    assert diagnostic["is_compatible"] is False
    assert diagnostic["severity"] == "warning"


def test_record_id_diagnostic_returns_error_for_unknown_target_type() -> None:
    diagnostic = diagnose_record_id_for_target_type(
        "unknown_record",
        "REC-001",
    )

    assert diagnostic["expected_family"] == ()
    assert diagnostic["allowed_prefixes"] == ()
    assert diagnostic["observed_prefix"] == "REC"
    assert diagnostic["is_compatible"] is False
    assert diagnostic["severity"] == "error"
    assert diagnostic["message"]


def test_record_id_diagnostic_returns_error_for_empty_target_record_id() -> None:
    diagnostic = diagnose_record_id_for_target_type(
        "project_record",
        "",
    )

    assert diagnostic["observed_prefix"] == ""
    assert diagnostic["is_compatible"] is False
    assert diagnostic["severity"] == "error"
    assert diagnostic["message"]


def test_record_id_diagnostic_does_not_make_audit_event_creation_stricter() -> None:
    event = AuditEventRecord(
        **_valid_audit_event_kwargs(),
        target_record_type="project_record",
        target_record_id="XYZ-001",
    )

    assert event.target_record_type == "project_record"
    assert event.target_record_id == "XYZ-001"


def test_record_id_diagnostic_report_returns_empty_summary_for_empty_input() -> None:
    report = build_record_id_diagnostic_report([])

    assert report["total_count"] == 0
    assert report["compatible_count"] == 0
    assert report["warning_count"] == 0
    assert report["error_count"] == 0
    assert report["items"] == []
    assert report["summary"] == {
        "total": 0,
        "compatible": 0,
        "warnings": 0,
        "errors": 0,
    }


def test_record_id_diagnostic_report_counts_single_canonical_record() -> None:
    report = build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"}]
    )

    assert report["total_count"] == 1
    assert report["compatible_count"] == 1
    assert report["warning_count"] == 0
    assert report["error_count"] == 0
    assert report["items"][0]["severity"] == "info"
    assert report["items"][0]["index"] == 0


def test_record_id_diagnostic_report_counts_single_legacy_record() -> None:
    report = build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "file-att-001"}]
    )

    assert report["compatible_count"] == 1
    assert report["warning_count"] == 1
    assert report["error_count"] == 0
    assert report["items"][0]["severity"] == "warning"


def test_record_id_diagnostic_report_counts_unmatched_prefix_without_exception() -> None:
    report = build_record_id_diagnostic_report(
        [
            {
                "target_record_type": "project_record",
                "target_record_id": "XYZ-001",
            }
        ]
    )

    assert report["compatible_count"] == 0
    assert report["warning_count"] == 1
    assert report["error_count"] == 0
    assert report["items"][0]["severity"] == "warning"


def test_record_id_diagnostic_report_counts_unknown_target_type_as_error() -> None:
    report = build_record_id_diagnostic_report(
        [{"target_record_type": "unknown_record", "target_record_id": "REC-001"}]
    )

    assert report["error_count"] == 1
    assert report["items"][0]["severity"] == "error"


def test_record_id_diagnostic_report_counts_empty_target_record_id_as_error() -> None:
    report = build_record_id_diagnostic_report(
        [{"target_record_type": "project_record", "target_record_id": ""}]
    )

    assert report["error_count"] == 1
    assert report["items"][0]["severity"] == "error"


def test_record_id_diagnostic_report_summarizes_mixed_severity_list() -> None:
    report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"},
            {"target_record_type": "attachment", "target_record_id": "file-att-001"},
            {"target_record_type": "unknown_record", "target_record_id": "REC-001"},
        ]
    )

    assert report["total_count"] == 3
    assert report["compatible_count"] == 2
    assert report["warning_count"] == 1
    assert report["error_count"] == 1
    assert report["summary"] == {
        "total": 3,
        "compatible": 2,
        "warnings": 1,
        "errors": 1,
    }


def test_record_id_diagnostic_report_preserves_input_order_in_index() -> None:
    report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"},
            {"target_record_type": "project_record", "target_record_id": "XYZ-001"},
            {"target_record_type": "unknown_record", "target_record_id": "REC-001"},
        ]
    )

    assert [item["index"] for item in report["items"]] == [0, 1, 2]


def test_record_id_diagnostic_report_does_not_mutate_input_records() -> None:
    records = [
        {"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"},
        {"target_record_type": "attachment", "target_record_id": "file-att-001"},
    ]
    original_records = [record.copy() for record in records]

    build_record_id_diagnostic_report(records)

    assert records == original_records


def test_record_id_diagnostic_report_accepts_tuple_input() -> None:
    report = build_record_id_diagnostic_report(
        [("attachment", "ATT-2026-0001")]
    )

    assert report["total_count"] == 1
    assert report["compatible_count"] == 1
    assert report["items"][0]["severity"] == "info"


def test_record_id_diagnostic_report_returns_error_items_for_unsupported_items() -> None:
    report = build_record_id_diagnostic_report(
        [
            object(),
            {},
            ("project_record",),
        ]
    )

    assert report["total_count"] == 3
    assert report["compatible_count"] == 0
    assert report["warning_count"] == 0
    assert report["error_count"] == 3
    assert [item["severity"] for item in report["items"]] == [
        "error",
        "error",
        "error",
    ]


def test_record_id_diagnostic_report_does_not_make_audit_event_creation_stricter() -> None:
    event = AuditEventRecord(
        **_valid_audit_event_kwargs(),
        target_record_type="project_record",
        target_record_id="XYZ-001",
    )

    assert event.target_record_type == "project_record"
    assert event.target_record_id == "XYZ-001"


def test_record_id_soft_validation_report_returns_pass_for_empty_diagnostics() -> None:
    diagnostic_report = build_record_id_diagnostic_report([])

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["status"] == "pass"
    assert report["review_required"] is False
    assert report["attention_required"] is False
    assert report["total_count"] == 0
    assert report["items"] == []


def test_record_id_soft_validation_report_returns_pass_for_info_only_items() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"}]
    )

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["status"] == "pass"
    assert report["compatible_count"] == 1
    assert report["warning_count"] == 0
    assert report["error_count"] == 0


def test_record_id_soft_validation_report_returns_review_for_warnings_only() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "file-att-001"}]
    )

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["status"] == "review"
    assert report["review_required"] is True
    assert report["attention_required"] is False


def test_record_id_soft_validation_report_returns_attention_for_errors() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [{"target_record_type": "unknown_record", "target_record_id": "REC-001"}]
    )

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["status"] == "attention"
    assert report["review_required"] is True
    assert report["attention_required"] is True


def test_record_id_soft_validation_report_prioritizes_attention_over_review() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "file-att-001"},
            {"target_record_type": "unknown_record", "target_record_id": "REC-001"},
        ]
    )

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["status"] == "attention"
    assert report["warning_count"] == 1
    assert report["error_count"] == 1


def test_record_id_soft_validation_report_preserves_counts_from_diagnostics() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"},
            {"target_record_type": "attachment", "target_record_id": "file-att-001"},
            {"target_record_type": "unknown_record", "target_record_id": "REC-001"},
        ]
    )

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["total_count"] == diagnostic_report["total_count"]
    assert report["compatible_count"] == diagnostic_report["compatible_count"]
    assert report["warning_count"] == diagnostic_report["warning_count"]
    assert report["error_count"] == diagnostic_report["error_count"]
    assert report["summary"] == diagnostic_report["summary"]


def test_record_id_soft_validation_report_preserves_items_content() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"},
            {"target_record_type": "project_record", "target_record_id": "XYZ-001"},
        ]
    )

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["items"] == diagnostic_report["items"]


def test_record_id_soft_validation_report_does_not_mutate_input_report() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "file-att-001"}]
    )
    original_report = {
        key: (value.copy() if isinstance(value, dict) else list(value))
        if isinstance(value, (dict, list))
        else value
        for key, value in diagnostic_report.items()
    }

    build_record_id_soft_validation_report(diagnostic_report)

    assert diagnostic_report == original_report


def test_record_id_soft_validation_report_handles_unknown_severity_without_exception() -> None:
    diagnostic_report = {
        "total_count": 1,
        "compatible_count": 0,
        "warning_count": 0,
        "error_count": 0,
        "items": [{"index": 0, "severity": "notice", "is_compatible": False}],
        "summary": {"total": 1, "compatible": 0, "warnings": 0, "errors": 0},
    }

    report = build_record_id_soft_validation_report(diagnostic_report)

    assert report["status"] == "pass"
    assert report["items"] == diagnostic_report["items"]
    assert report["messages"]


def test_record_id_soft_validation_report_returns_attention_for_unsupported_input() -> None:
    report = build_record_id_soft_validation_report(object())

    assert report["status"] == "attention"
    assert report["error_count"] == 1
    assert report["review_required"] is True
    assert report["attention_required"] is True


def test_record_id_soft_validation_report_returns_attention_for_missing_fields() -> None:
    report = build_record_id_soft_validation_report({"items": []})

    assert report["status"] == "attention"
    assert report["messages"]


def test_record_id_soft_validation_report_never_returns_blocked_status() -> None:
    reports = [
        build_record_id_soft_validation_report(build_record_id_diagnostic_report([])),
        build_record_id_soft_validation_report(
            build_record_id_diagnostic_report(
                [
                    {
                        "target_record_type": "attachment",
                        "target_record_id": "file-att-001",
                    }
                ]
            )
        ),
        build_record_id_soft_validation_report(
            build_record_id_diagnostic_report(
                [{"target_record_type": "unknown_record", "target_record_id": ""}]
            )
        ),
        build_record_id_soft_validation_report(object()),
    ]

    assert {report["status"] for report in reports}.isdisjoint({"blocked"})


def test_record_id_soft_validation_report_does_not_make_audit_event_creation_stricter() -> None:
    event = AuditEventRecord(
        **_valid_audit_event_kwargs(),
        target_record_type="project_record",
        target_record_id="XYZ-001",
    )

    assert event.target_record_type == "project_record"
    assert event.target_record_id == "XYZ-001"


def test_record_id_diagnostic_json_ready_formatter_preserves_counts_and_items() -> None:
    report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"},
            {"target_record_type": "attachment", "target_record_id": "file-att-001"},
        ]
    )
    original_report = deepcopy(report)

    formatted = format_record_id_diagnostic_report_as_json_ready_dict(report)

    assert isinstance(formatted, dict)
    assert formatted["report_type"] == "record_id_diagnostic"
    assert formatted["total_count"] == report["total_count"]
    assert formatted["compatible_count"] == report["compatible_count"]
    assert formatted["warning_count"] == report["warning_count"]
    assert formatted["error_count"] == report["error_count"]
    assert formatted["items"][0]["target_record_id"] == "ATT-2026-0001"
    assert formatted["items"][1]["target_record_id"] == "file-att-001"
    assert report == original_report


def test_record_id_soft_validation_json_ready_formatter_preserves_report_fields() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "file-att-001"}]
    )
    report = build_record_id_soft_validation_report(diagnostic_report)
    original_report = deepcopy(report)

    formatted = format_record_id_soft_validation_report_as_json_ready_dict(report)

    assert isinstance(formatted, dict)
    assert formatted["report_type"] == "record_id_soft_validation"
    assert formatted["status"] == report["status"]
    assert formatted["total_count"] == report["total_count"]
    assert formatted["warning_count"] == report["warning_count"]
    assert formatted["error_count"] == report["error_count"]
    assert formatted["items"][0]["target_record_id"] == "file-att-001"
    assert formatted["items"][0]["allowed_prefixes"] == ["ATT", "file-att", "att"]
    assert formatted["messages"] == report["messages"]
    assert formatted["summary"] == report["summary"]
    assert report == original_report


def test_record_id_diagnostic_markdown_formatter_shows_counts_and_items() -> None:
    report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "file-att-001"},
            {"target_record_type": "unknown_record", "target_record_id": "REC-001"},
        ]
    )
    original_report = deepcopy(report)

    markdown = format_record_id_diagnostic_report_as_markdown(report)

    assert isinstance(markdown, str)
    assert "# Record ID Diagnostic Report" in markdown
    assert "total_count: 2" in markdown
    assert "warning_count: 1" in markdown
    assert "error_count: 1" in markdown
    assert "file-att-001" in markdown
    assert "REC-001" in markdown
    assert "Bu rapor kayit reddi degildir." in markdown
    assert "Hard validation degildir." in markdown
    assert report == original_report


def test_record_id_soft_validation_markdown_formatter_shows_status_messages_and_items() -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [
            {"target_record_type": "attachment", "target_record_id": "file-att-001"},
            {"target_record_type": "unknown_record", "target_record_id": "REC-001"},
        ]
    )
    report = build_record_id_soft_validation_report(diagnostic_report)
    original_report = deepcopy(report)

    markdown = format_record_id_soft_validation_report_as_markdown(report)

    assert isinstance(markdown, str)
    assert "# Record ID Soft Validation Report" in markdown
    assert "status: attention" in markdown
    assert "review_required: True" in markdown
    assert "attention_required: True" in markdown
    assert report["messages"][0] in markdown
    assert "file-att-001" in markdown
    assert "REC-001" in markdown
    assert "`blocked` status uretilmez." in markdown
    assert report == original_report


def test_record_id_formatters_return_readable_outputs_for_unsupported_input() -> None:
    unsupported_inputs = (None, [], "not-a-report")

    for value in unsupported_inputs:
        diagnostic_json = format_record_id_diagnostic_report_as_json_ready_dict(value)
        soft_json = format_record_id_soft_validation_report_as_json_ready_dict(value)
        diagnostic_markdown = format_record_id_diagnostic_report_as_markdown(value)
        soft_markdown = format_record_id_soft_validation_report_as_markdown(value)

        assert isinstance(diagnostic_json, dict)
        assert isinstance(soft_json, dict)
        assert diagnostic_json["is_supported_input"] is False
        assert soft_json["is_supported_input"] is False
        assert isinstance(diagnostic_markdown, str)
        assert isinstance(soft_markdown, str)
        assert "Unsupported report input." in diagnostic_markdown
        assert "Unsupported report input." in soft_markdown


def test_record_id_formatters_do_not_recompute_counts_or_status() -> None:
    diagnostic_report = {
        "total_count": 99,
        "compatible_count": 88,
        "warning_count": 7,
        "error_count": 4,
        "items": [{"index": 0, "severity": "info", "target_record_id": "ATT-1"}],
        "summary": {"total": 99, "compatible": 88, "warnings": 7, "errors": 4},
    }
    soft_report = {
        "status": "review",
        "total_count": 99,
        "compatible_count": 88,
        "warning_count": 7,
        "error_count": 4,
        "review_required": False,
        "attention_required": False,
        "messages": ["precomputed status must be displayed as-is"],
        "items": [],
        "summary": {"total": 99, "compatible": 88, "warnings": 7, "errors": 4},
    }

    diagnostic_json = format_record_id_diagnostic_report_as_json_ready_dict(
        diagnostic_report
    )
    soft_json = format_record_id_soft_validation_report_as_json_ready_dict(
        soft_report
    )
    diagnostic_markdown = format_record_id_diagnostic_report_as_markdown(
        diagnostic_report
    )
    soft_markdown = format_record_id_soft_validation_report_as_markdown(soft_report)

    assert diagnostic_json["total_count"] == 99
    assert diagnostic_json["warning_count"] == 7
    assert diagnostic_json["error_count"] == 4
    assert soft_json["status"] == "review"
    assert soft_json["review_required"] is False
    assert "total_count: 99" in diagnostic_markdown
    assert "warning_count: 7" in diagnostic_markdown
    assert "status: review" in soft_markdown
    assert "review_required: False" in soft_markdown


def test_record_id_formatters_do_not_emit_blocked_as_output_status() -> None:
    report = {
        "status": "blocked",
        "total_count": 1,
        "compatible_count": 0,
        "warning_count": 0,
        "error_count": 1,
        "review_required": True,
        "attention_required": True,
        "messages": ["upstream input used unsupported status"],
        "items": [],
        "summary": {"total": 1, "compatible": 0, "warnings": 0, "errors": 1},
    }

    formatted = format_record_id_soft_validation_report_as_json_ready_dict(report)
    markdown = format_record_id_soft_validation_report_as_markdown(report)

    assert formatted["status"] != "blocked"
    assert "status: blocked" not in markdown
    assert "`blocked` status uretilmez." in markdown


def test_record_id_helpers_do_not_make_audit_event_creation_stricter() -> None:
    event = AuditEventRecord(
        **_valid_audit_event_kwargs(),
        target_record_type="project_record",
        target_record_id="REC-1",
    )

    assert event.target_record_type == "project_record"
    assert event.target_record_id == "REC-1"


def test_write_json_ready_dict_to_file_writes_readable_utf8_json(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.json"
    data = {"title": "Şantiye raporu", "count": 2, "items": ["A", "B"]}

    written_path = write_json_ready_dict_to_file(data, output_path)

    assert written_path == output_path
    assert json.loads(output_path.read_text(encoding="utf-8")) == data
    assert "Şantiye raporu" in output_path.read_text(encoding="utf-8")


def test_write_json_ready_dict_to_file_uses_deterministic_format(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.json"

    write_json_ready_dict_to_file({"b": 2, "a": 1}, output_path)

    assert output_path.read_text(encoding="utf-8") == '{\n  "a": 1,\n  "b": 2\n}\n'


def test_write_json_ready_dict_to_file_does_not_mutate_input(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.json"
    data = {"items": [{"id": "ATT-1"}], "summary": {"total": 1}}
    original_data = deepcopy(data)

    write_json_ready_dict_to_file(data, output_path)

    assert data == original_data


def test_write_json_ready_dict_to_file_rejects_wrong_extension(tmp_path) -> None:
    with pytest.raises(ValueError, match=".json"):
        write_json_ready_dict_to_file({"ok": True}, tmp_path / "diagnostic.md")


def test_write_json_ready_dict_to_file_rejects_non_dict_input(tmp_path) -> None:
    with pytest.raises(TypeError, match="JSON-ready dict"):
        write_json_ready_dict_to_file(["not", "a", "dict"], tmp_path / "out.json")


def test_write_json_ready_dict_to_file_rejects_unserializable_object(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.json"

    with pytest.raises(TypeError):
        write_json_ready_dict_to_file({"bad": object()}, output_path)

    assert not output_path.exists()


def test_write_json_ready_dict_to_file_preserves_existing_file_without_overwrite(
    tmp_path,
) -> None:
    output_path = tmp_path / "diagnostic.json"
    output_path.write_text('{"old": true}', encoding="utf-8")

    with pytest.raises(FileExistsError):
        write_json_ready_dict_to_file({"old": False}, output_path)

    assert output_path.read_text(encoding="utf-8") == '{"old": true}'


def test_write_json_ready_dict_to_file_overwrites_explicit_target_only(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.json"
    sibling_path = tmp_path / "sibling.json"
    output_path.write_text('{"old": true}', encoding="utf-8")
    sibling_path.write_text('{"keep": true}', encoding="utf-8")

    write_json_ready_dict_to_file({"new": True}, output_path, overwrite=True)

    assert json.loads(output_path.read_text(encoding="utf-8")) == {"new": True}
    assert sibling_path.read_text(encoding="utf-8") == '{"keep": true}'


def test_write_json_ready_dict_to_file_allows_path_inside_allowed_root(tmp_path) -> None:
    allowed_root = tmp_path / "exports"
    allowed_root.mkdir()
    output_path = allowed_root / "diagnostic.json"

    written_path = write_json_ready_dict_to_file(
        {"ok": True},
        output_path,
        allowed_root=allowed_root,
    )

    assert written_path == output_path
    assert json.loads(output_path.read_text(encoding="utf-8")) == {"ok": True}


def test_write_json_ready_dict_to_file_rejects_path_outside_allowed_root(
    tmp_path,
) -> None:
    allowed_root = tmp_path / "exports"
    outside_root = tmp_path / "outside"
    allowed_root.mkdir()
    outside_root.mkdir()

    with pytest.raises(ValueError, match="allowed_root"):
        write_json_ready_dict_to_file(
            {"ok": True},
            outside_root / "diagnostic.json",
            allowed_root=allowed_root,
        )


def test_write_json_ready_dict_to_file_rejects_path_traversal(tmp_path) -> None:
    with pytest.raises(ValueError, match="path traversal"):
        write_json_ready_dict_to_file(
            {"ok": True},
            tmp_path / "exports" / ".." / "diagnostic.json",
        )


def test_write_json_ready_dict_to_file_rejects_missing_parent(tmp_path) -> None:
    with pytest.raises(FileNotFoundError, match="parent directory"):
        write_json_ready_dict_to_file(
            {"ok": True},
            tmp_path / "missing" / "diagnostic.json",
        )


def test_write_json_ready_dict_to_file_rejects_non_export_area(tmp_path) -> None:
    git_dir = tmp_path / ".git"
    git_dir.mkdir()

    with pytest.raises(ValueError, match="non-export area"):
        write_json_ready_dict_to_file({"ok": True}, git_dir / "diagnostic.json")


def test_write_markdown_text_to_file_writes_utf8_without_reformatting(tmp_path) -> None:
    output_path = tmp_path / "summary.md"
    markdown = "# Başlık\n\n- item\n```text\nraw\n```\n"

    written_path = write_markdown_text_to_file(markdown, output_path)

    assert written_path == output_path
    assert output_path.read_text(encoding="utf-8") == markdown


def test_write_markdown_text_to_file_rejects_non_string_input(tmp_path) -> None:
    with pytest.raises(TypeError, match="string"):
        write_markdown_text_to_file({"not": "markdown"}, tmp_path / "summary.md")


def test_write_markdown_text_to_file_rejects_wrong_extension(tmp_path) -> None:
    with pytest.raises(ValueError, match=".md"):
        write_markdown_text_to_file("# Summary", tmp_path / "summary.json")


def test_write_markdown_text_to_file_preserves_existing_file_without_overwrite(
    tmp_path,
) -> None:
    output_path = tmp_path / "summary.md"
    output_path.write_text("old content", encoding="utf-8")

    with pytest.raises(FileExistsError):
        write_markdown_text_to_file("new content", output_path)

    assert output_path.read_text(encoding="utf-8") == "old content"


def test_write_markdown_text_to_file_overwrites_explicit_target_only(tmp_path) -> None:
    output_path = tmp_path / "summary.md"
    sibling_path = tmp_path / "sibling.md"
    output_path.write_text("old content", encoding="utf-8")
    sibling_path.write_text("keep content", encoding="utf-8")

    write_markdown_text_to_file("new content", output_path, overwrite=True)

    assert output_path.read_text(encoding="utf-8") == "new content"
    assert sibling_path.read_text(encoding="utf-8") == "keep content"


def test_write_markdown_text_to_file_allows_path_inside_allowed_root(tmp_path) -> None:
    allowed_root = tmp_path / "exports"
    allowed_root.mkdir()
    output_path = allowed_root / "summary.md"

    written_path = write_markdown_text_to_file(
        "# Summary",
        output_path,
        allowed_root=allowed_root,
    )

    assert written_path == output_path
    assert output_path.read_text(encoding="utf-8") == "# Summary"


def test_write_markdown_text_to_file_rejects_path_outside_allowed_root(
    tmp_path,
) -> None:
    allowed_root = tmp_path / "exports"
    outside_root = tmp_path / "outside"
    allowed_root.mkdir()
    outside_root.mkdir()

    with pytest.raises(ValueError, match="allowed_root"):
        write_markdown_text_to_file(
            "# Summary",
            outside_root / "summary.md",
            allowed_root=allowed_root,
        )


def test_write_markdown_text_to_file_rejects_path_traversal(tmp_path) -> None:
    with pytest.raises(ValueError, match="path traversal"):
        write_markdown_text_to_file(
            "# Summary",
            tmp_path / "exports" / ".." / "summary.md",
        )


def test_write_markdown_text_to_file_rejects_missing_parent(tmp_path) -> None:
    with pytest.raises(FileNotFoundError, match="parent directory"):
        write_markdown_text_to_file(
            "# Summary",
            tmp_path / "missing" / "summary.md",
        )


def test_write_markdown_text_to_file_rejects_non_export_area(tmp_path) -> None:
    cache_dir = tmp_path / "__pycache__"
    cache_dir.mkdir()

    with pytest.raises(ValueError, match="non-export area"):
        write_markdown_text_to_file("# Summary", cache_dir / "summary.md")


EXPORT_WRITE_RESULT_KEYS = {
    "success",
    "output_path",
    "attempted_path",
    "allowed_root",
    "file_type",
    "error_code",
    "error_message",
    "skipped_reason",
    "overwritten",
}


def test_try_write_json_ready_dict_to_file_returns_success_result(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.json"
    data = {"title": "Şantiye raporu", "items": [{"id": "ATT-1"}]}
    original_data = deepcopy(data)

    result = try_write_json_ready_dict_to_file(data, output_path)

    assert set(result) == EXPORT_WRITE_RESULT_KEYS
    assert result["success"] is True
    assert result["output_path"] == output_path
    assert result["attempted_path"] == output_path
    assert result["allowed_root"] is None
    assert result["file_type"] == "json"
    assert result["error_code"] is None
    assert result["error_message"] is None
    assert result["skipped_reason"] is None
    assert result["overwritten"] is False
    assert json.loads(output_path.read_text(encoding="utf-8")) == data
    assert data == original_data


def test_try_write_json_ready_dict_to_file_reports_non_dict_input(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.json"

    result = try_write_json_ready_dict_to_file(["not", "dict"], output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] == "input_type_error"
    assert result["error_message"]
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_json_ready_dict_to_file_reports_serialization_error(
    tmp_path,
) -> None:
    output_path = tmp_path / "diagnostic.json"

    result = try_write_json_ready_dict_to_file({"bad": object()}, output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] == "serialization_error"
    assert result["error_message"]
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_json_ready_dict_to_file_reports_wrong_extension(tmp_path) -> None:
    output_path = tmp_path / "diagnostic.md"

    result = try_write_json_ready_dict_to_file({"ok": True}, output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] == "wrong_extension"
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_json_ready_dict_to_file_reports_outside_allowed_root(
    tmp_path,
) -> None:
    allowed_root = tmp_path / "exports"
    outside_root = tmp_path / "outside"
    allowed_root.mkdir()
    outside_root.mkdir()
    output_path = outside_root / "diagnostic.json"

    result = try_write_json_ready_dict_to_file(
        {"ok": True},
        output_path,
        allowed_root=allowed_root,
    )

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["allowed_root"] == allowed_root
    assert result["file_type"] == "json"
    assert result["error_code"] == "outside_allowed_root"
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_json_ready_dict_to_file_reports_path_traversal(tmp_path) -> None:
    output_path = tmp_path / "exports" / ".." / "diagnostic.json"

    result = try_write_json_ready_dict_to_file({"ok": True}, output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] == "path_traversal"
    assert result["overwritten"] is False


def test_try_write_json_ready_dict_to_file_reports_missing_parent(tmp_path) -> None:
    output_path = tmp_path / "missing" / "diagnostic.json"

    result = try_write_json_ready_dict_to_file({"ok": True}, output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] == "parent_missing"
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_json_ready_dict_to_file_reports_existing_file_without_overwrite(
    tmp_path,
) -> None:
    output_path = tmp_path / "diagnostic.json"
    output_path.write_text('{"old": true}', encoding="utf-8")

    result = try_write_json_ready_dict_to_file({"old": False}, output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] == "file_exists"
    assert result["skipped_reason"] == "file_exists"
    assert result["overwritten"] is False
    assert output_path.read_text(encoding="utf-8") == '{"old": true}'


def test_try_write_json_ready_dict_to_file_reports_explicit_overwrite(
    tmp_path,
) -> None:
    output_path = tmp_path / "diagnostic.json"
    sibling_path = tmp_path / "sibling.json"
    output_path.write_text('{"old": true}', encoding="utf-8")
    sibling_path.write_text('{"keep": true}', encoding="utf-8")

    result = try_write_json_ready_dict_to_file(
        {"new": True},
        output_path,
        overwrite=True,
    )

    assert result["success"] is True
    assert result["output_path"] == output_path
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] is None
    assert result["skipped_reason"] is None
    assert result["overwritten"] is True
    assert json.loads(output_path.read_text(encoding="utf-8")) == {"new": True}
    assert sibling_path.read_text(encoding="utf-8") == '{"keep": true}'


def test_try_write_markdown_text_to_file_returns_success_result(tmp_path) -> None:
    output_path = tmp_path / "summary.md"
    markdown = "# Başlık\n\n- item\n```text\nraw\n```\n"

    result = try_write_markdown_text_to_file(markdown, output_path)

    assert set(result) == EXPORT_WRITE_RESULT_KEYS
    assert result["success"] is True
    assert result["output_path"] == output_path
    assert result["attempted_path"] == output_path
    assert result["allowed_root"] is None
    assert result["file_type"] == "markdown"
    assert result["error_code"] is None
    assert result["error_message"] is None
    assert result["skipped_reason"] is None
    assert result["overwritten"] is False
    assert output_path.read_text(encoding="utf-8") == markdown


def test_try_write_markdown_text_to_file_reports_non_string_input(
    tmp_path,
) -> None:
    output_path = tmp_path / "summary.md"

    result = try_write_markdown_text_to_file({"not": "markdown"}, output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "markdown"
    assert result["error_code"] == "input_type_error"
    assert result["error_message"]
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_markdown_text_to_file_reports_wrong_extension(tmp_path) -> None:
    output_path = tmp_path / "summary.json"

    result = try_write_markdown_text_to_file("# Summary", output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "markdown"
    assert result["error_code"] == "wrong_extension"
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_markdown_text_to_file_reports_outside_allowed_root(
    tmp_path,
) -> None:
    allowed_root = tmp_path / "exports"
    outside_root = tmp_path / "outside"
    allowed_root.mkdir()
    outside_root.mkdir()
    output_path = outside_root / "summary.md"

    result = try_write_markdown_text_to_file(
        "# Summary",
        output_path,
        allowed_root=allowed_root,
    )

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["allowed_root"] == allowed_root
    assert result["file_type"] == "markdown"
    assert result["error_code"] == "outside_allowed_root"
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_markdown_text_to_file_reports_path_traversal(tmp_path) -> None:
    output_path = tmp_path / "exports" / ".." / "summary.md"

    result = try_write_markdown_text_to_file("# Summary", output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "markdown"
    assert result["error_code"] == "path_traversal"
    assert result["overwritten"] is False


def test_try_write_markdown_text_to_file_reports_missing_parent(tmp_path) -> None:
    output_path = tmp_path / "missing" / "summary.md"

    result = try_write_markdown_text_to_file("# Summary", output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "markdown"
    assert result["error_code"] == "parent_missing"
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_markdown_text_to_file_reports_existing_file_without_overwrite(
    tmp_path,
) -> None:
    output_path = tmp_path / "summary.md"
    output_path.write_text("old content", encoding="utf-8")

    result = try_write_markdown_text_to_file("new content", output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "markdown"
    assert result["error_code"] == "file_exists"
    assert result["skipped_reason"] == "file_exists"
    assert result["overwritten"] is False
    assert output_path.read_text(encoding="utf-8") == "old content"


def test_try_write_markdown_text_to_file_reports_explicit_overwrite(
    tmp_path,
) -> None:
    output_path = tmp_path / "summary.md"
    sibling_path = tmp_path / "sibling.md"
    output_path.write_text("old content", encoding="utf-8")
    sibling_path.write_text("keep content", encoding="utf-8")

    result = try_write_markdown_text_to_file(
        "new content",
        output_path,
        overwrite=True,
    )

    assert result["success"] is True
    assert result["output_path"] == output_path
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "markdown"
    assert result["error_code"] is None
    assert result["skipped_reason"] is None
    assert result["overwritten"] is True
    assert output_path.read_text(encoding="utf-8") == "new content"
    assert sibling_path.read_text(encoding="utf-8") == "keep content"


def test_try_write_json_ready_dict_to_file_returns_success_contract(
    tmp_path,
) -> None:
    output_path = tmp_path / "handover_summary.json"

    result = try_write_json_ready_dict_to_file(
        {"status": "review", "warnings": ["manual check"]},
        output_path,
    )

    assert set(result) == EXPORT_WRITE_RESULT_KEYS
    assert result == {
        "success": True,
        "output_path": output_path,
        "attempted_path": output_path,
        "allowed_root": None,
        "file_type": "json",
        "error_code": None,
        "error_message": None,
        "skipped_reason": None,
        "overwritten": False,
    }


def test_try_write_markdown_text_to_file_returns_success_contract(
    tmp_path,
) -> None:
    output_path = tmp_path / "handover_summary.md"

    result = try_write_markdown_text_to_file(
        "# Handover QC\n\nExport yazimi hazir.",
        output_path,
    )

    assert set(result) == EXPORT_WRITE_RESULT_KEYS
    assert result == {
        "success": True,
        "output_path": output_path,
        "attempted_path": output_path,
        "allowed_root": None,
        "file_type": "markdown",
        "error_code": None,
        "error_message": None,
        "skipped_reason": None,
        "overwritten": False,
    }


def test_try_write_json_ready_dict_to_file_returns_error_contract_for_invalid_path(
    tmp_path,
) -> None:
    output_path = tmp_path / "missing" / "handover_summary.json"

    result = try_write_json_ready_dict_to_file({"status": "review"}, output_path)

    assert result["success"] is False
    assert result["output_path"] is None
    assert result["attempted_path"] == output_path
    assert result["file_type"] == "json"
    assert result["error_code"] == "parent_missing"
    assert result["error_message"]
    assert result["overwritten"] is False
    assert not output_path.exists()


def test_try_write_helpers_do_not_mutate_inputs(tmp_path) -> None:
    json_ready = {"status": "review", "items": [{"id": "NCR-001"}]}
    original_json_ready = deepcopy(json_ready)
    markdown = "# Handover QC\n\n- NCR-001 review"

    json_result = try_write_json_ready_dict_to_file(
        json_ready,
        tmp_path / "handover_summary.json",
    )
    markdown_result = try_write_markdown_text_to_file(
        markdown,
        tmp_path / "handover_summary.md",
    )

    assert json_result["success"] is True
    assert markdown_result["success"] is True
    assert json_ready == original_json_ready
    assert markdown == "# Handover QC\n\n- NCR-001 review"


def test_low_level_write_helpers_keep_exception_behavior(tmp_path) -> None:
    json_path = tmp_path / "handover_summary.json"
    markdown_path = tmp_path / "handover_summary.md"
    json_path.write_text('{"old": true}', encoding="utf-8")
    markdown_path.write_text("old content", encoding="utf-8")

    json_result = try_write_json_ready_dict_to_file({"new": True}, json_path)
    markdown_result = try_write_markdown_text_to_file("new content", markdown_path)

    assert json_result["success"] is False
    assert json_result["error_code"] == "file_exists"
    assert markdown_result["success"] is False
    assert markdown_result["error_code"] == "file_exists"

    with pytest.raises(FileExistsError):
        write_json_ready_dict_to_file({"new": True}, json_path)

    with pytest.raises(FileExistsError):
        write_markdown_text_to_file("new content", markdown_path)


def test_try_write_helpers_keep_existing_exception_helpers_unchanged(tmp_path) -> None:
    with pytest.raises(TypeError, match="JSON-ready dict"):
        write_json_ready_dict_to_file(["not", "dict"], tmp_path / "out.json")

    with pytest.raises(TypeError, match="string"):
        write_markdown_text_to_file({"not": "markdown"}, tmp_path / "out.md")

    with pytest.raises(ValueError, match=".json"):
        write_json_ready_dict_to_file({"ok": True}, tmp_path / "out.md")

    with pytest.raises(ValueError, match=".md"):
        write_markdown_text_to_file("# Summary", tmp_path / "out.json")


def test_build_export_result_summary_returns_success_summary(tmp_path) -> None:
    output_path = tmp_path / "summary.json"
    contract = {
        "success": True,
        "output_path": output_path,
        "attempted_path": output_path,
        "allowed_root": tmp_path,
        "file_type": "json",
        "error_code": None,
        "error_message": None,
        "skipped_reason": None,
        "overwritten": False,
    }

    summary = build_export_result_summary(contract)

    assert summary["operation"] == "export_result_summary"
    assert summary["status"] == "success"
    assert summary["success"] is True
    assert summary["file_type"] == "json"
    assert summary["path"] == str(output_path)
    assert summary["allowed_root"] == str(tmp_path)
    assert summary["error_type"] is None
    assert summary["safe_for_user_message"] == "json export completed."
    assert summary["technical_detail"] is None
    assert summary["next_action_hint"] is None


def test_build_export_result_summary_returns_failure_summary(tmp_path) -> None:
    output_path = tmp_path / "summary.md"
    contract = {
        "success": False,
        "output_path": None,
        "attempted_path": output_path,
        "allowed_root": None,
        "file_type": "markdown",
        "error_code": "file_exists",
        "error_message": "output_path already exists",
        "skipped_reason": "file_exists",
        "overwritten": False,
    }

    summary = build_export_result_summary(contract)

    assert summary["status"] == "review"
    assert summary["success"] is False
    assert summary["path"] == str(output_path)
    assert summary["error_type"] == "file_exists"
    assert (
        summary["safe_for_user_message"]
        == "Export was not written because the target file exists."
    )
    assert summary["technical_detail"] == "output_path already exists"
    assert summary["next_action_hint"] == (
        "Review the export result before using the output."
    )


def test_build_export_result_summary_handles_unknown_status(tmp_path) -> None:
    contract = {
        "output_path": None,
        "attempted_path": tmp_path / "maybe.json",
        "file_type": "json",
    }

    summary = build_export_result_summary(contract)

    assert summary["status"] == "unknown"
    assert summary["success"] is None
    assert summary["path"] == str(tmp_path / "maybe.json")
    assert summary["error_type"] == "unknown_status"
    assert summary["safe_for_user_message"] == "Export result could not be interpreted."
    assert summary["next_action_hint"] == "Review the raw export result contract."


def test_build_export_result_summary_handles_missing_optional_fields() -> None:
    summary = build_export_result_summary({"success": True})

    assert summary["status"] == "success"
    assert summary["success"] is True
    assert summary["file_type"] is None
    assert summary["path"] is None
    assert summary["output_path"] is None
    assert summary["attempted_path"] is None
    assert summary["allowed_root"] is None
    assert summary["overwritten"] is False


def test_build_export_result_report_counts_mixed_result_list_in_order(tmp_path) -> None:
    success_contract = {
        "success": True,
        "output_path": tmp_path / "ok.json",
        "attempted_path": tmp_path / "ok.json",
        "file_type": "json",
        "overwritten": False,
    }
    failure_contract = {
        "success": False,
        "output_path": None,
        "attempted_path": tmp_path / "missing.md",
        "file_type": "markdown",
        "error_code": "parent_missing",
        "error_message": "output_path parent directory does not exist",
        "overwritten": False,
    }
    unknown_contract = {"file_type": "json"}

    report = build_export_result_report(
        [success_contract, failure_contract, unknown_contract]
    )

    assert report["operation"] == "export_result_report"
    assert report["status"] == "review"
    assert report["total_count"] == 3
    assert report["success_count"] == 1
    assert report["review_count"] == 1
    assert report["unknown_count"] == 1
    assert [item["status"] for item in report["items"]] == [
        "success",
        "review",
        "unknown",
    ]
    assert report["safe_for_user_message"] == "One or more export results need review."


def test_build_export_result_report_handles_unsupported_input() -> None:
    report = build_export_result_report("not a result contract")

    assert report["status"] == "review"
    assert report["total_count"] == 1
    assert report["success_count"] == 0
    assert report["review_count"] == 0
    assert report["unknown_count"] == 1
    assert report["items"][0]["error_type"] == "unsupported_input"


def test_export_result_summary_helpers_do_not_mutate_input(tmp_path) -> None:
    contract = {
        "success": False,
        "output_path": None,
        "attempted_path": tmp_path / "summary.json",
        "file_type": "json",
        "error_code": "wrong_extension",
        "error_message": "output_path must use .json extension",
        "details": {"keep": ["same"]},
    }
    original_contract = deepcopy(contract)

    build_export_result_summary(contract)
    build_export_result_report([contract])

    assert contract == original_contract


def test_format_export_result_summary_as_markdown_contains_safe_message(
    tmp_path,
) -> None:
    summary = build_export_result_summary(
        {
            "success": False,
            "output_path": None,
            "attempted_path": tmp_path / "summary.md",
            "file_type": "markdown",
            "error_code": "parent_missing",
            "error_message": "output_path parent directory does not exist",
            "overwritten": False,
        }
    )

    markdown = format_export_result_summary_as_markdown(summary)

    assert markdown.startswith("# Export Result Summary\n")
    assert "- Status: review" in markdown
    assert "Export was not written because the parent folder is missing." in markdown
    assert "- Error type: parent_missing" in markdown
    assert "- Technical detail: output_path parent directory does not exist" in markdown


def test_format_export_result_report_as_markdown_formats_success_report(
    tmp_path,
) -> None:
    output_path = tmp_path / "report.json"
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "allowed_root": tmp_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_result_report_as_markdown(report)

    assert isinstance(markdown, str)
    assert markdown.startswith("# Export Result Report\n")
    assert "- Status: success" in markdown
    assert "- Total: 1" in markdown
    assert "- Success: 1" in markdown
    assert "- Failure/review: 0" in markdown
    assert "1. success - json export completed." in markdown
    assert f"   - Path: {output_path}" in markdown
    assert "Read-only presentation formatter." in markdown


def test_format_export_result_report_as_markdown_formats_failure_report(
    tmp_path,
) -> None:
    attempted_path = tmp_path / "missing" / "report.md"
    report = build_export_result_report(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": attempted_path,
                "file_type": "markdown",
                "error_code": "parent_missing",
                "error_message": "output_path parent directory does not exist",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_result_report_as_markdown(report)

    assert "- Status: review" in markdown
    assert "- Success: 0" in markdown
    assert "- Failure/review: 1" in markdown
    assert "1. review - Export was not written because the parent folder is missing." in markdown
    assert f"   - Path: {attempted_path}" in markdown
    assert "   - Error type: parent_missing" in markdown
    assert "   - Technical detail: output_path parent directory does not exist" in markdown


def test_format_export_result_report_as_markdown_keeps_mixed_visibility(
    tmp_path,
) -> None:
    success_path = tmp_path / "ok.json"
    failure_path = tmp_path / "exists.md"
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": success_path,
                "attempted_path": success_path,
                "file_type": "json",
                "overwritten": False,
            },
            {
                "success": False,
                "output_path": None,
                "attempted_path": failure_path,
                "file_type": "markdown",
                "error_code": "file_exists",
                "error_message": "output_path already exists",
                "overwritten": False,
            },
        ]
    )

    markdown = format_export_result_report_as_markdown(report)

    assert "- Status: review" in markdown
    assert "- Total: 2" in markdown
    assert "- Success: 1" in markdown
    assert "- Failure/review: 1" in markdown
    assert f"   - Path: {success_path}" in markdown
    assert f"   - Path: {failure_path}" in markdown
    assert "json export completed." in markdown
    assert "Export was not written because the target file exists." in markdown


def test_format_export_result_report_as_markdown_success_example_is_stable() -> None:
    report = {
        "operation": "export_result_report",
        "status": "success",
        "total_count": 1,
        "success_count": 1,
        "review_count": 0,
        "unknown_count": 0,
        "safe_for_user_message": "All export results completed.",
        "items": [
            {
                "status": "success",
                "safe_for_user_message": "json export completed.",
                "file_type": "json",
                "path": "exports/report.json",
                "output_path": "exports/report.json",
                "attempted_path": "exports/report.json",
                "overwritten": False,
            }
        ],
    }

    markdown = format_export_result_report_as_markdown(report)

    assert markdown == (
        "# Export Result Report\n"
        "\n"
        "## Summary\n"
        "- Status: success\n"
        "- Total: 1\n"
        "- Success: 1\n"
        "- Failure/review: 0\n"
        "- Unknown: 0\n"
        "- Message: All export results completed.\n"
        "\n"
        "## Items\n"
        "1. success - json export completed.\n"
        "   - File type: json\n"
        "   - Path: exports/report.json\n"
        "   - Output path: exports/report.json\n"
        "   - Attempted path: exports/report.json\n"
        "   - Overwritten: no\n"
        "\n"
        "## Notes\n"
        "- Read-only presentation formatter.\n"
        "- No files are written and no export output is created.\n"
        "- Report data is not recalculated and hard validation is not performed.\n"
    )


def test_format_export_result_report_as_markdown_failure_example_is_stable() -> None:
    report = {
        "operation": "export_result_report",
        "status": "review",
        "total_count": 1,
        "success_count": 0,
        "review_count": 1,
        "unknown_count": 0,
        "safe_for_user_message": "One or more export results need review.",
        "items": [
            {
                "status": "review",
                "safe_for_user_message": (
                    "Export was not written because the parent folder is missing."
                ),
                "file_type": "markdown",
                "path": "exports/missing/report.md",
                "attempted_path": "exports/missing/report.md",
                "error_type": "parent_missing",
                "technical_detail": "output_path parent directory does not exist",
                "next_action_hint": "Review the export result before using the output.",
                "overwritten": False,
            }
        ],
    }

    markdown = format_export_result_report_as_markdown(report)

    assert markdown == (
        "# Export Result Report\n"
        "\n"
        "## Summary\n"
        "- Status: review\n"
        "- Total: 1\n"
        "- Success: 0\n"
        "- Failure/review: 1\n"
        "- Unknown: 0\n"
        "- Message: One or more export results need review.\n"
        "\n"
        "## Items\n"
        "1. review - Export was not written because the parent folder is missing.\n"
        "   - File type: markdown\n"
        "   - Path: exports/missing/report.md\n"
        "   - Attempted path: exports/missing/report.md\n"
        "   - Error type: parent_missing\n"
        "   - Technical detail: output_path parent directory does not exist\n"
        "   - Next action: Review the export result before using the output.\n"
        "   - Overwritten: no\n"
        "\n"
        "## Notes\n"
        "- Read-only presentation formatter.\n"
        "- No files are written and no export output is created.\n"
        "- Report data is not recalculated and hard validation is not performed.\n"
    )


def test_format_export_result_report_as_markdown_empty_report_example_is_stable() -> None:
    report = {
        "operation": "export_result_report",
        "status": "unknown",
        "total_count": 0,
        "success_count": 0,
        "review_count": 0,
        "unknown_count": 0,
        "safe_for_user_message": "No export results were provided.",
        "items": [],
    }

    markdown = format_export_result_report_as_markdown(report)

    assert markdown == (
        "# Export Result Report\n"
        "\n"
        "## Summary\n"
        "- Status: unknown\n"
        "- Total: 0\n"
        "- Success: 0\n"
        "- Failure/review: 0\n"
        "- Unknown: 0\n"
        "- Message: No export results were provided.\n"
        "\n"
        "## Items\n"
        "- No export result items.\n"
        "\n"
        "## Notes\n"
        "- Read-only presentation formatter.\n"
        "- No files are written and no export output is created.\n"
        "- Report data is not recalculated and hard validation is not performed.\n"
    )


def test_format_export_result_report_as_markdown_missing_optional_fields_fallback() -> None:
    report = {
        "operation": "export_result_report",
        "status": "review",
        "items": [{"status": "review"}],
    }

    markdown = format_export_result_report_as_markdown(report)

    assert "- Total: not available" in markdown
    assert "- Success: not available" in markdown
    assert "- Failure/review: not available" in markdown
    assert "- Message: not available" in markdown
    assert "1. review - Export result item has no message." in markdown
    assert "   - File type: not available" in markdown
    assert "   - Path: not available" in markdown


def test_format_export_result_report_as_markdown_ignores_additional_fields() -> None:
    report = {
        "operation": "export_result_report",
        "status": "review",
        "total_count": 1,
        "success_count": 0,
        "review_count": 1,
        "unknown_count": 0,
        "safe_for_user_message": "Existing report message.",
        "unexpected_report_field": "do not render",
        "items": [
            {
                "status": "review",
                "safe_for_user_message": "Prebuilt review message.",
                "path": "exports/review.md",
                "unexpected_item_field": "do not render",
                "error_code": "raw_contract_field_not_rendered",
            }
        ],
    }

    markdown = format_export_result_report_as_markdown(report)

    assert "Prebuilt review message." in markdown
    assert "exports/review.md" in markdown
    assert "do not render" not in markdown
    assert "raw_contract_field_not_rendered" not in markdown


def test_format_export_result_report_as_markdown_does_not_mutate_input(
    tmp_path,
) -> None:
    report = build_export_result_report(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": tmp_path / "wrong.txt",
                "file_type": "markdown",
                "error_code": "wrong_extension",
                "error_message": "output_path must use the .md extension",
                "overwritten": False,
            }
        ]
    )
    original_report = deepcopy(report)

    format_export_result_report_as_markdown(report)

    assert report == original_report


def test_format_export_result_report_as_markdown_does_not_write_files(
    tmp_path,
) -> None:
    output_path = tmp_path / "export.json"
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_result_report_as_markdown(report)

    assert markdown
    assert not output_path.exists()
    assert list(tmp_path.iterdir()) == []


def test_format_export_result_report_as_markdown_does_not_recompute_report() -> None:
    report = {
        "operation": "export_result_report",
        "status": "review",
        "total_count": 1,
        "success_count": 0,
        "review_count": 1,
        "unknown_count": 0,
        "safe_for_user_message": "Existing report message.",
        "items": [
            {
                "status": "review",
                "safe_for_user_message": "Prebuilt item message.",
                "path": "exports/prebuilt.md",
                "technical_detail": "Prebuilt technical detail.",
                "overwritten": False,
                "success": True,
                "error_code": "would_be_recomputed_if_treated_as_contract",
            }
        ],
    }

    markdown = format_export_result_report_as_markdown(report)

    assert "Prebuilt item message." in markdown
    assert "Prebuilt technical detail." in markdown
    assert "would_be_recomputed_if_treated_as_contract" not in markdown
    assert "json export completed." not in markdown


def test_format_export_result_report_as_markdown_handles_unsupported_input() -> None:
    markdown = format_export_result_report_as_markdown("not a report")

    assert isinstance(markdown, str)
    assert markdown.startswith("# Export Result Report\n")
    assert "- Status: unknown" in markdown
    assert "Export result report could not be interpreted." in markdown


def test_format_export_result_report_as_markdown_does_not_emit_blocked_status() -> None:
    report = {
        "operation": "export_result_report",
        "status": "blocked",
        "total_count": 1,
        "success_count": 0,
        "review_count": 1,
        "unknown_count": 0,
        "safe_for_user_message": "Manual review required.",
        "items": [
            {
                "status": "blocked",
                "safe_for_user_message": "Manual review item.",
                "path": "exports/review.md",
            }
        ],
    }

    markdown = format_export_result_report_as_markdown(report)

    assert "- Status: review" in markdown
    assert "1. review - Manual review item." in markdown
    assert "blocked" not in markdown.lower()


def test_format_export_result_summary_as_markdown_report_regression(
    tmp_path,
) -> None:
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": tmp_path / "summary.json",
                "attempted_path": tmp_path / "summary.json",
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_result_summary_as_markdown(report)

    assert markdown.startswith("# Export Result Report\n")
    assert "- Status: success" in markdown
    assert "1. success - json export completed." in markdown


def test_build_export_result_report_contract_regression(tmp_path) -> None:
    output_path = tmp_path / "regression.json"

    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    assert report["operation"] == "export_result_report"
    assert report["status"] == "success"
    assert report["total_count"] == 1
    assert report["success_count"] == 1
    assert report["review_count"] == 0
    assert report["unknown_count"] == 0
    assert report["safe_for_user_message"] == "All export results completed."
    assert report["items"][0]["operation"] == "export_result_summary"
    assert report["items"][0]["status"] == "success"
    assert report["items"][0]["path"] == str(output_path)


def test_export_result_summary_helpers_do_not_write_files(tmp_path) -> None:
    output_path = tmp_path / "summary.json"

    summary = build_export_result_summary(
        {
            "success": True,
            "output_path": output_path,
            "attempted_path": output_path,
            "file_type": "json",
            "overwritten": False,
        }
    )
    markdown = format_export_result_summary_as_markdown(summary)

    assert summary["path"] == str(output_path)
    assert markdown
    assert not output_path.exists()
    assert list(tmp_path.iterdir()) == []


def test_export_result_summary_helpers_do_not_emit_blocked_status(tmp_path) -> None:
    report = build_export_result_report(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": tmp_path / "summary.md",
                "file_type": "markdown",
                "error_code": "outside_allowed_root",
                "error_message": "output_path must stay inside allowed_root",
                "overwritten": False,
            }
        ]
    )
    markdown = format_export_result_summary_as_markdown(report)

    assert report["status"] == "review"
    assert "blocked" not in {item["status"] for item in report["items"]}
    assert "blocked" not in markdown.lower()


def test_build_export_handover_qc_review_checklist_success_only(
    tmp_path,
) -> None:
    output_path = tmp_path / "handover.json"
    summary = build_export_result_summary(
        {
            "success": True,
            "output_path": output_path,
            "attempted_path": output_path,
            "file_type": "json",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert checklist["checklist_type"] == "export_handover_qc_review"
    assert checklist["status"] == "success"
    assert checklist["summary"]["success_count"] == 1
    assert checklist["items"][0]["status"] == "success"
    assert checklist["items"][0]["priority"] == "info"
    assert checklist["items"][0]["path"] == str(output_path)
    assert checklist["is_read_only"] is True
    assert checklist["is_blocking"] is False
    assert checklist["requires_human_review"] is False


def test_build_export_handover_qc_review_checklist_failure_only(
    tmp_path,
) -> None:
    attempted_path = tmp_path / "missing" / "handover.md"
    summary = build_export_result_summary(
        {
            "success": False,
            "output_path": None,
            "attempted_path": attempted_path,
            "file_type": "markdown",
            "error_code": "parent_missing",
            "error_message": "output_path parent directory does not exist",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": attempted_path,
                "file_type": "markdown",
                "error_code": "parent_missing",
                "error_message": "output_path parent directory does not exist",
                "overwritten": False,
            }
        ]
    )

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert checklist["status"] == "review"
    assert checklist["summary"]["review_count"] == 1
    assert checklist["items"][0]["status"] == "review"
    assert checklist["items"][0]["priority"] == "review"
    assert checklist["items"][0]["path"] == str(attempted_path)
    assert checklist["items"][0]["error_type"] == "parent_missing"
    assert (
        checklist["items"][0]["technical_detail"]
        == "output_path parent directory does not exist"
    )
    assert checklist["is_blocking"] is False
    assert checklist["requires_human_review"] is True


def test_build_export_handover_qc_review_checklist_mixed_report(
    tmp_path,
) -> None:
    success_path = tmp_path / "ok.json"
    failure_path = tmp_path / "exists.md"
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": success_path,
                "attempted_path": success_path,
                "file_type": "json",
                "overwritten": False,
            },
            {
                "success": False,
                "output_path": None,
                "attempted_path": failure_path,
                "file_type": "markdown",
                "error_code": "file_exists",
                "error_message": "output_path already exists",
                "overwritten": False,
            },
        ]
    )

    checklist = build_export_handover_qc_review_checklist(
        report["items"][0],
        report,
    )

    assert checklist["status"] == "review"
    assert checklist["summary"]["total_count"] == 2
    assert checklist["summary"]["success_count"] == 1
    assert checklist["summary"]["review_count"] == 1
    assert [item["status"] for item in checklist["items"]] == ["success", "review"]
    assert checklist["items"][0]["path"] == str(success_path)
    assert checklist["items"][1]["path"] == str(failure_path)
    assert checklist["is_blocking"] is False


def test_build_export_handover_qc_review_checklist_empty_report() -> None:
    report = build_export_result_report([])

    checklist = build_export_handover_qc_review_checklist({}, report)

    assert checklist["status"] == "unknown"
    assert checklist["summary"]["total_count"] == 0
    assert checklist["summary"]["success_count"] == 0
    assert checklist["summary"]["review_count"] == 0
    assert checklist["summary"]["unknown_count"] == 0
    assert checklist["items"] == []
    assert checklist["requires_human_review"] is True
    assert checklist["is_blocking"] is False


def test_build_export_handover_qc_review_checklist_missing_optional_fields() -> None:
    summary = {"operation": "export_result_summary", "status": "review"}
    report = {
        "operation": "export_result_report",
        "status": "review",
        "total_count": 1,
        "success_count": 0,
        "review_count": 1,
        "unknown_count": 0,
        "items": [{"status": "review"}],
    }

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert checklist["status"] == "review"
    assert checklist["summary"]["message"] == (
        "Export handover QC checklist needs review."
    )
    assert checklist["items"][0]["message"] == "Export checklist item has no message."
    assert checklist["items"][0]["file_type"] is None
    assert checklist["items"][0]["path"] is None


def test_build_export_handover_qc_review_checklist_unknown_additional_fields() -> None:
    summary = {
        "operation": "export_result_summary",
        "status": "blocked",
        "safe_for_user_message": "Manual review required.",
        "unexpected_summary_field": "do not copy",
    }
    report = {
        "operation": "export_result_report",
        "status": "blocked",
        "total_count": 1,
        "success_count": 0,
        "review_count": 1,
        "unknown_count": 0,
        "safe_for_user_message": "Manual review required.",
        "unexpected_report_field": "do not copy",
        "items": [
            {
                "status": "blocked",
                "safe_for_user_message": "Manual review item.",
                "path": "exports/review.md",
                "unexpected_item_field": "do not copy",
            }
        ],
    }

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert checklist["status"] == "review"
    assert checklist["summary"]["source_summary_status"] == "review"
    assert checklist["items"][0]["status"] == "review"
    assert "unexpected_summary_field" not in checklist["summary"]
    assert "unexpected_item_field" not in checklist["items"][0]
    assert "blocked" not in json.dumps(checklist).lower()


def test_build_export_handover_qc_review_checklist_output_is_json_ready(
    tmp_path,
) -> None:
    output_path = tmp_path / "json-ready.json"
    summary = build_export_result_summary(
        {
            "success": True,
            "output_path": output_path,
            "attempted_path": output_path,
            "file_type": "json",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert isinstance(checklist, dict)
    assert isinstance(checklist["items"], list)
    assert json.loads(json.dumps(checklist)) == checklist


def test_build_export_handover_qc_review_checklist_top_level_contract_example(
    tmp_path,
) -> None:
    output_path = tmp_path / "contract-example.json"
    summary = build_export_result_summary(
        {
            "success": True,
            "output_path": output_path,
            "attempted_path": output_path,
            "file_type": "json",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert set(checklist) == {
        "checklist_type",
        "status",
        "summary",
        "items",
        "review_notes",
        "is_read_only",
        "is_blocking",
        "requires_human_review",
    }
    assert set(checklist["summary"]) == {
        "status",
        "total_count",
        "success_count",
        "review_count",
        "unknown_count",
        "source_summary_status",
        "message",
    }
    assert set(checklist["items"][0]) == {
        "status",
        "priority",
        "file_type",
        "path",
        "message",
        "error_type",
        "technical_detail",
        "next_action_hint",
        "overwritten",
    }


def test_build_export_handover_qc_review_checklist_review_notes_are_explanatory(
    tmp_path,
) -> None:
    attempted_path = tmp_path / "review.md"
    summary = build_export_result_summary(
        {
            "success": False,
            "output_path": None,
            "attempted_path": attempted_path,
            "file_type": "markdown",
            "error_code": "file_exists",
            "error_message": "output_path already exists",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": attempted_path,
                "file_type": "markdown",
                "error_code": "file_exists",
                "error_message": "output_path already exists",
                "overwritten": False,
            }
        ]
    )

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert checklist["review_notes"] == [
        "Read-only QC checklist for human review.",
        "This checklist does not approve or reject a handover package.",
        "Hard validation is not performed and no audit event is created.",
    ]
    assert "approved" not in checklist
    assert "rejected" not in checklist
    assert "official_decision" not in checklist
    assert "audit_event_id" not in checklist


def test_build_export_handover_qc_review_checklist_human_review_is_not_blocking(
    tmp_path,
) -> None:
    attempted_path = tmp_path / "needs-review.md"
    report = build_export_result_report(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": attempted_path,
                "file_type": "markdown",
                "error_code": "wrong_extension",
                "error_message": "output_path must use the .md extension",
                "overwritten": False,
            }
        ]
    )

    checklist = build_export_handover_qc_review_checklist(
        report["items"][0],
        report,
    )

    assert checklist["status"] == "review"
    assert checklist["requires_human_review"] is True
    assert checklist["is_blocking"] is False
    assert "blocked" not in json.dumps(checklist).lower()


def test_build_export_handover_qc_review_checklist_does_not_mutate_input(
    tmp_path,
) -> None:
    output_path = tmp_path / "immutable.json"
    summary = build_export_result_summary(
        {
            "success": True,
            "output_path": output_path,
            "attempted_path": output_path,
            "file_type": "json",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": tmp_path / "review.md",
                "file_type": "markdown",
                "error_code": "wrong_extension",
                "error_message": "output_path must use the .md extension",
                "overwritten": False,
            }
        ]
    )
    original_summary = deepcopy(summary)
    original_report = deepcopy(report)

    build_export_handover_qc_review_checklist(summary, report)

    assert summary == original_summary
    assert report == original_report


def test_build_export_handover_qc_review_checklist_does_not_write_files(
    tmp_path,
) -> None:
    output_path = tmp_path / "exports" / "handover.json"
    summary = build_export_result_summary(
        {
            "success": True,
            "output_path": output_path,
            "attempted_path": output_path,
            "file_type": "json",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    checklist = build_export_handover_qc_review_checklist(summary, report)

    assert checklist["items"][0]["path"] == str(output_path)
    assert not output_path.exists()
    assert not (tmp_path / "exports").exists()


def test_build_export_handover_qc_review_checklist_no_hard_validation() -> None:
    checklist = build_export_handover_qc_review_checklist(
        "not a summary",
        "not a report",
    )

    assert checklist["status"] == "unknown"
    assert checklist["summary"]["total_count"] == 0
    assert checklist["items"] == []
    assert checklist["is_read_only"] is True
    assert checklist["is_blocking"] is False
    assert checklist["requires_human_review"] is True


def test_build_export_handover_qc_review_checklist_preserves_summary_behavior(
    tmp_path,
) -> None:
    output_path = tmp_path / "summary-regression.json"
    contract = {
        "success": True,
        "output_path": output_path,
        "attempted_path": output_path,
        "file_type": "json",
        "overwritten": False,
    }
    expected_summary = build_export_result_summary(contract)
    report = build_export_result_report([contract])

    build_export_handover_qc_review_checklist(expected_summary, report)

    assert build_export_result_summary(contract) == expected_summary


def test_build_export_handover_qc_review_checklist_preserves_report_behavior(
    tmp_path,
) -> None:
    contract = {
        "success": False,
        "output_path": None,
        "attempted_path": tmp_path / "report-regression.md",
        "file_type": "markdown",
        "error_code": "parent_missing",
        "error_message": "output_path parent directory does not exist",
        "overwritten": False,
    }
    expected_report = build_export_result_report([contract])
    summary = expected_report["items"][0]

    build_export_handover_qc_review_checklist(summary, expected_report)

    assert build_export_result_report([contract]) == expected_report


def test_build_export_handover_qc_review_checklist_preserves_formatter_behavior(
    tmp_path,
) -> None:
    output_path = tmp_path / "formatter-regression.json"
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )
    expected_markdown = format_export_result_report_as_markdown(report)

    build_export_handover_qc_review_checklist(report["items"][0], report)

    assert format_export_result_report_as_markdown(report) == expected_markdown


def test_build_export_handover_qc_review_checklist_preserves_summary_formatter_behavior(
    tmp_path,
) -> None:
    output_path = tmp_path / "summary-formatter-regression.json"
    summary = build_export_result_summary(
        {
            "success": True,
            "output_path": output_path,
            "attempted_path": output_path,
            "file_type": "json",
            "overwritten": False,
        }
    )
    report = build_export_result_report(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )
    expected_markdown = format_export_result_summary_as_markdown(summary)

    build_export_handover_qc_review_checklist(summary, report)

    assert format_export_result_summary_as_markdown(summary) == expected_markdown


def test_build_export_handover_qc_review_checklist_preserves_write_helpers(
    tmp_path,
) -> None:
    existing_json = tmp_path / "existing.json"
    existing_markdown = tmp_path / "existing.md"
    existing_json.write_text('{"old": true}', encoding="utf-8")
    existing_markdown.write_text("old", encoding="utf-8")
    report = build_export_result_report([])

    build_export_handover_qc_review_checklist({}, report)

    with pytest.raises(FileExistsError):
        write_json_ready_dict_to_file({"new": True}, existing_json)

    with pytest.raises(FileExistsError):
        write_markdown_text_to_file("new", existing_markdown)

    json_result = try_write_json_ready_dict_to_file({"new": True}, existing_json)
    markdown_result = try_write_markdown_text_to_file("new", existing_markdown)

    assert json_result["success"] is False
    assert json_result["error_code"] == "file_exists"
    assert markdown_result["success"] is False
    assert markdown_result["error_code"] == "file_exists"


def _format_checklist_from_contracts(
    contracts: list[dict[str, object]],
) -> dict[str, object]:
    report = build_export_result_report(contracts)
    summary = report["items"][0] if report["items"] else {}
    return build_export_handover_qc_review_checklist(summary, report)


def test_format_export_handover_qc_review_checklist_success_only(tmp_path) -> None:
    output_path = tmp_path / "handover.json"
    checklist = _format_checklist_from_contracts(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert isinstance(markdown, str)
    assert "# Export Handover QC Review Checklist" in markdown
    assert "checklist_type: export_handover_qc_review" in markdown
    assert "- status: success" in markdown
    assert "- is_read_only: true" in markdown
    assert "- is_blocking: false" in markdown
    assert "- requires_human_review: false" in markdown
    assert str(output_path) in markdown
    assert "official acceptance" not in markdown.lower()


def test_format_export_handover_qc_review_checklist_failure_only(tmp_path) -> None:
    attempted_path = tmp_path / "missing" / "handover.md"
    checklist = _format_checklist_from_contracts(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": attempted_path,
                "file_type": "markdown",
                "error_code": "parent_missing",
                "error_message": "output_path parent directory does not exist",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert "- status: review" in markdown
    assert "- requires_human_review: true (human review visibility only; not a package block)" in markdown
    assert "- is_blocking: false" in markdown
    assert "parent_missing" in markdown
    assert "output_path parent directory does not exist" in markdown
    assert str(attempted_path) in markdown
    assert "automatic rejection" not in markdown.lower()


def test_format_export_handover_qc_review_checklist_mixed(tmp_path) -> None:
    success_path = tmp_path / "ok.json"
    review_path = tmp_path / "exists.md"
    checklist = _format_checklist_from_contracts(
        [
            {
                "success": True,
                "output_path": success_path,
                "attempted_path": success_path,
                "file_type": "json",
                "overwritten": False,
            },
            {
                "success": False,
                "output_path": None,
                "attempted_path": review_path,
                "file_type": "markdown",
                "error_code": "file_exists",
                "error_message": "output_path already exists",
                "overwritten": False,
            },
        ]
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert "- total_count: 2" in markdown
    assert "- success_count: 1" in markdown
    assert "- review_count: 1" in markdown
    assert "1. status: success" in markdown
    assert "2. status: review" in markdown
    assert str(success_path) in markdown
    assert str(review_path) in markdown


def test_format_export_handover_qc_review_checklist_empty_zero_count() -> None:
    report = build_export_result_report([])
    checklist = build_export_handover_qc_review_checklist({}, report)

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert "- status: unknown" in markdown
    assert "- total_count: 0" in markdown
    assert "- success_count: 0" in markdown
    assert "- review_count: 0" in markdown
    assert "- unknown_count: 0" in markdown
    assert "- No checklist items." in markdown


def test_format_export_handover_qc_review_checklist_missing_optional_fields() -> None:
    checklist = build_export_handover_qc_review_checklist(
        {"operation": "export_result_summary", "status": "review"},
        {
            "operation": "export_result_report",
            "status": "review",
            "total_count": 1,
            "success_count": 0,
            "review_count": 1,
            "unknown_count": 0,
            "items": [{"status": "review"}],
        },
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert "Export handover QC checklist needs review." in markdown
    assert "Export checklist item has no message." in markdown
    assert "- file_type: not available" in markdown
    assert "- path: not available" in markdown


def test_format_export_handover_qc_review_checklist_unknown_additional_boundary() -> None:
    checklist = build_export_handover_qc_review_checklist(
        {
            "operation": "export_result_summary",
            "status": "blocked",
            "safe_for_user_message": "Manual review required.",
            "unexpected_summary_field": "do not copy",
        },
        {
            "operation": "export_result_report",
            "status": "blocked",
            "total_count": 1,
            "success_count": 0,
            "review_count": 1,
            "unknown_count": 0,
            "safe_for_user_message": "Manual review required.",
            "unexpected_report_field": "do not copy",
            "items": [
                {
                    "status": "blocked",
                    "safe_for_user_message": "Manual review item.",
                    "path": "exports/review.md",
                    "unexpected_item_field": "do not copy",
                }
            ],
        },
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert "unexpected_summary_field" not in markdown
    assert "unexpected_report_field" not in markdown
    assert "unexpected_item_field" not in markdown
    assert "blocked" not in markdown.lower()


def test_format_export_handover_qc_review_checklist_review_notes_are_explanatory(
    tmp_path,
) -> None:
    checklist = _format_checklist_from_contracts(
        [
            {
                "success": False,
                "output_path": None,
                "attempted_path": tmp_path / "review.md",
                "file_type": "markdown",
                "error_code": "file_exists",
                "error_message": "output_path already exists",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert "## Review Notes" in markdown
    assert "Read-only QC checklist for human review." in markdown
    assert "This checklist does not approve or reject a handover package." in markdown
    assert "Hard validation is not performed and no audit event is created." in markdown
    assert "official_decision" not in markdown
    assert "audit_event_id" not in markdown


def test_format_export_handover_qc_review_checklist_items_are_readable(
    tmp_path,
) -> None:
    checklist = _format_checklist_from_contracts(
        [
            {
                "success": True,
                "output_path": tmp_path / "readable.json",
                "attempted_path": tmp_path / "readable.json",
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert "## Items" in markdown
    assert "1. status: success" in markdown
    assert "   - priority: info" in markdown
    assert "   - file_type: json" in markdown
    assert "   - overwritten: false" in markdown


def test_format_export_handover_qc_review_checklist_does_not_mutate_input(
    tmp_path,
) -> None:
    checklist = _format_checklist_from_contracts(
        [
            {
                "success": True,
                "output_path": tmp_path / "immutable.json",
                "attempted_path": tmp_path / "immutable.json",
                "file_type": "json",
                "overwritten": False,
            }
        ]
    )
    original_checklist = deepcopy(checklist)

    format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert checklist == original_checklist


def test_format_export_handover_qc_review_checklist_does_not_write_or_export(
    tmp_path,
) -> None:
    output_path = tmp_path / "exports" / "handover.md"
    checklist = _format_checklist_from_contracts(
        [
            {
                "success": True,
                "output_path": output_path,
                "attempted_path": output_path,
                "file_type": "markdown",
                "overwritten": False,
            }
        ]
    )

    markdown = format_export_handover_qc_review_checklist_as_markdown(checklist)

    assert isinstance(markdown, str)
    assert not output_path.exists()
    assert not (tmp_path / "exports").exists()


def test_format_export_handover_qc_review_checklist_unsupported_input_is_safe() -> None:
    markdown = format_export_handover_qc_review_checklist_as_markdown(
        "not a checklist"
    )

    assert isinstance(markdown, str)
    assert "- status: unknown" in markdown
    assert "- is_read_only: true" in markdown
    assert "- is_blocking: false" in markdown
    assert "- requires_human_review: true" in markdown
    assert "- No checklist items." in markdown
    assert "blocked" not in markdown.lower()


def test_format_export_handover_qc_review_checklist_no_hard_validation() -> None:
    markdown = format_export_handover_qc_review_checklist_as_markdown(
        {"status": "not-a-known-status", "items": ["raw item"]}
    )

    assert "- status: unknown" in markdown
    assert "Export checklist item could not be interpreted." in markdown
    assert "unsupported_item" in markdown
    assert "Hard validation is not performed" in markdown
    assert "blocked" not in markdown.lower()


def test_format_export_handover_qc_review_checklist_preserves_existing_helpers(
    tmp_path,
) -> None:
    output_path = tmp_path / "regression.json"
    contract = {
        "success": True,
        "output_path": output_path,
        "attempted_path": output_path,
        "file_type": "json",
        "overwritten": False,
    }
    expected_summary = build_export_result_summary(contract)
    expected_report = build_export_result_report([contract])
    expected_checklist = build_export_handover_qc_review_checklist(
        expected_summary,
        expected_report,
    )
    expected_report_markdown = format_export_result_report_as_markdown(
        expected_report
    )
    expected_summary_markdown = format_export_result_summary_as_markdown(
        expected_summary
    )
    existing_json = tmp_path / "existing.json"
    existing_markdown = tmp_path / "existing.md"
    existing_json.write_text('{"old": true}', encoding="utf-8")
    existing_markdown.write_text("old", encoding="utf-8")

    format_export_handover_qc_review_checklist_as_markdown(expected_checklist)

    assert build_export_result_summary(contract) == expected_summary
    assert build_export_result_report([contract]) == expected_report
    assert (
        build_export_handover_qc_review_checklist(expected_summary, expected_report)
        == expected_checklist
    )
    assert (
        format_export_result_report_as_markdown(expected_report)
        == expected_report_markdown
    )
    assert (
        format_export_result_summary_as_markdown(expected_summary)
        == expected_summary_markdown
    )
    with pytest.raises(FileExistsError):
        write_json_ready_dict_to_file({"new": True}, existing_json)
    with pytest.raises(FileExistsError):
        write_markdown_text_to_file("new", existing_markdown)
    assert try_write_json_ready_dict_to_file({"new": True}, existing_json)[
        "error_code"
    ] == "file_exists"
    assert try_write_markdown_text_to_file("new", existing_markdown)[
        "error_code"
    ] == "file_exists"


def test_file_writing_helpers_do_not_recompute_reports_or_formatters(tmp_path) -> None:
    diagnostic_report = build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"}]
    )
    soft_report = build_record_id_soft_validation_report(diagnostic_report)
    json_ready = format_record_id_soft_validation_report_as_json_ready_dict(
        soft_report
    )
    markdown = format_record_id_soft_validation_report_as_markdown(soft_report)

    write_json_ready_dict_to_file(json_ready, tmp_path / "soft.json")
    write_markdown_text_to_file(markdown, tmp_path / "soft.md")

    assert json_ready["status"] == "pass"
    assert "status: pass" in markdown
    assert build_record_id_diagnostic_report(
        [{"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"}]
    ) == diagnostic_report
    assert build_record_id_soft_validation_report(diagnostic_report) == soft_report


def test_file_writing_helpers_do_not_emit_blocked_status(tmp_path) -> None:
    report = {"status": "attention", "messages": ["manual review"]}
    markdown = "status: attention\n`blocked` status uretilmez."

    write_json_ready_dict_to_file(report, tmp_path / "report.json")
    write_markdown_text_to_file(markdown, tmp_path / "report.md")

    assert json.loads((tmp_path / "report.json").read_text(encoding="utf-8"))[
        "status"
    ] == "attention"
    assert "status: blocked" not in (tmp_path / "report.md").read_text(
        encoding="utf-8"
    )


def test_audit_event_record_still_accepts_legacy_target_record_id_examples() -> None:
    examples = (
        ("project_record", "NCR-001"),
        ("project_record", "REC-2026-0007"),
        ("attachment", "file-att-001"),
        ("attachment", "ATT-2026-0001"),
        ("audit_event", "audit-001"),
    )

    for target_record_type, target_record_id in examples:
        event = AuditEventRecord(
            **_valid_audit_event_kwargs(),
            target_record_type=target_record_type,
            target_record_id=target_record_id,
        )

        assert event.target_record_type == target_record_type
        assert event.target_record_id == target_record_id


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
        "file_type",
        "mime_type",
    ],
)
def test_file_attachment_record_validation_rejects_empty_required_fields(
    field_name: str,
) -> None:
    values = _valid_file_attachment_kwargs()
    values[field_name] = ""

    with pytest.raises(ValueError, match=f"{field_name} cannot be empty"):
        FileAttachmentRecord(**values)


@pytest.mark.parametrize(
    "field_name",
    [
        "attachment_id",
        "related_record_type",
        "related_record_id",
        "file_name",
        "file_path",
        "file_type",
    ],
)
def test_file_attachment_record_validation_rejects_none_required_fields(
    field_name: str,
) -> None:
    values = _valid_file_attachment_kwargs()
    values[field_name] = None

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
