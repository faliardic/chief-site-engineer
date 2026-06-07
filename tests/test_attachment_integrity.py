import json
from datetime import datetime, timezone

import pytest

from app.attachment_integrity import (
    ACTION_CHECK_PERMISSIONS_DISK_OR_FILE_CORRUPTION,
    ACTION_CREATE_METADATA_OR_QUARANTINE_FILE,
    ACTION_MERGE_OR_DEACTIVATE_DUPLICATE_METADATA,
    ACTION_REBUILD_PATH_WITH_CANONICAL_HELPER,
    ACTION_RESTORE_FROM_BACKUP_OR_REVIEW_AUDIT_TRAIL,
    ATTACHMENT_INTEGRITY_ERROR_STATUSES,
    ATTACHMENT_INTEGRITY_SEVERITIES,
    ATTACHMENT_INTEGRITY_STATUSES,
    ATTACHMENT_INTEGRITY_WARNING_STATUSES,
    AttachmentIntegrityReport,
    AttachmentIntegrityReportSummary,
    AttachmentIntegrityResult,
    DUPLICATE_METADATA,
    INVALID_PATH,
    MISSING_FILE,
    OK,
    ORPHAN_FILE,
    SEVERITY_ERROR,
    SEVERITY_OK,
    SEVERITY_WARNING,
    UNREADABLE_FILE,
    build_attachment_integrity_result,
    build_attachment_integrity_report,
    build_attachment_integrity_report_summary,
    export_attachment_integrity_report_to_json,
    serialize_attachment_integrity_report,
    serialize_attachment_integrity_report_summary,
    serialize_attachment_integrity_result,
)


def test_attachment_integrity_status_constants_have_expected_values() -> None:
    assert OK == "OK"
    assert MISSING_FILE == "MISSING_FILE"
    assert ORPHAN_FILE == "ORPHAN_FILE"
    assert INVALID_PATH == "INVALID_PATH"
    assert DUPLICATE_METADATA == "DUPLICATE_METADATA"
    assert UNREADABLE_FILE == "UNREADABLE_FILE"


def test_attachment_integrity_status_collection_contains_all_statuses() -> None:
    assert ATTACHMENT_INTEGRITY_STATUSES == frozenset(
        {
            OK,
            MISSING_FILE,
            ORPHAN_FILE,
            INVALID_PATH,
            DUPLICATE_METADATA,
            UNREADABLE_FILE,
        }
    )


def test_attachment_integrity_error_statuses_are_classified() -> None:
    assert ATTACHMENT_INTEGRITY_ERROR_STATUSES == frozenset(
        {
            MISSING_FILE,
            INVALID_PATH,
            DUPLICATE_METADATA,
            UNREADABLE_FILE,
        }
    )


def test_attachment_integrity_warning_statuses_are_classified() -> None:
    assert ATTACHMENT_INTEGRITY_WARNING_STATUSES == frozenset({ORPHAN_FILE})


def test_attachment_integrity_ok_is_not_error_or_warning() -> None:
    assert OK not in ATTACHMENT_INTEGRITY_ERROR_STATUSES
    assert OK not in ATTACHMENT_INTEGRITY_WARNING_STATUSES


def test_attachment_integrity_status_collections_are_immutable() -> None:
    assert isinstance(ATTACHMENT_INTEGRITY_STATUSES, frozenset)
    assert isinstance(ATTACHMENT_INTEGRITY_ERROR_STATUSES, frozenset)
    assert isinstance(ATTACHMENT_INTEGRITY_WARNING_STATUSES, frozenset)


def test_attachment_integrity_severity_constants_are_available() -> None:
    assert SEVERITY_OK == "OK"
    assert SEVERITY_WARNING == "WARNING"
    assert SEVERITY_ERROR == "ERROR"
    assert ATTACHMENT_INTEGRITY_SEVERITIES == frozenset(
        {SEVERITY_OK, SEVERITY_WARNING, SEVERITY_ERROR}
    )


def test_attachment_integrity_result_can_be_created() -> None:
    result = AttachmentIntegrityResult(
        status_code=OK,
        severity=SEVERITY_OK,
        metadata_exists=True,
        file_exists=True,
    )

    assert result.status_code == OK
    assert result.severity == SEVERITY_OK
    assert result.metadata_exists is True
    assert result.file_exists is True


def test_attachment_integrity_result_sets_checked_at_when_missing() -> None:
    result = AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)

    assert result.checked_at.tzinfo is not None
    assert result.checked_at.utcoffset() is not None
    assert result.checked_at.utcoffset().total_seconds() == 0


def test_attachment_integrity_result_keeps_reference_fields() -> None:
    result = AttachmentIntegrityResult(
        status_code=INVALID_PATH,
        severity=SEVERITY_ERROR,
        attachment_id="ATT-001",
        expected_path="attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg",
        actual_path="legacy/photo.jpg",
        recommended_action="Regenerate path with canonical helper.",
        notes="Legacy path detected.",
    )

    assert result.attachment_id == "ATT-001"
    assert (
        result.expected_path
        == "attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg"
    )
    assert result.actual_path == "legacy/photo.jpg"
    assert result.recommended_action == "Regenerate path with canonical helper."
    assert result.notes == "Legacy path detected."


def test_attachment_integrity_result_rejects_invalid_status_code() -> None:
    try:
        AttachmentIntegrityResult(status_code="BROKEN", severity=SEVERITY_ERROR)
    except ValueError as exc:
        assert "status_code must be a known attachment integrity status" in str(exc)
    else:
        raise AssertionError("AttachmentIntegrityResult accepted invalid status_code")


def test_attachment_integrity_result_rejects_invalid_severity() -> None:
    try:
        AttachmentIntegrityResult(status_code=OK, severity="CRITICAL")
    except ValueError as exc:
        assert "severity must be OK, WARNING, or ERROR" in str(exc)
    else:
        raise AssertionError("AttachmentIntegrityResult accepted invalid severity")


def test_attachment_integrity_result_can_represent_missing_file() -> None:
    result = AttachmentIntegrityResult(
        status_code=MISSING_FILE,
        severity=SEVERITY_ERROR,
        metadata_exists=True,
        file_exists=False,
    )

    assert result.status_code == MISSING_FILE
    assert result.metadata_exists is True
    assert result.file_exists is False


def test_attachment_integrity_result_can_represent_orphan_file() -> None:
    result = AttachmentIntegrityResult(
        status_code=ORPHAN_FILE,
        severity=SEVERITY_WARNING,
        metadata_exists=False,
        file_exists=True,
    )

    assert result.status_code == ORPHAN_FILE
    assert result.metadata_exists is False
    assert result.file_exists is True


def test_attachment_integrity_result_can_represent_ok_file() -> None:
    result = AttachmentIntegrityResult(
        status_code=OK,
        severity=SEVERITY_OK,
        metadata_exists=True,
        file_exists=True,
    )

    assert result.status_code == OK
    assert result.metadata_exists is True
    assert result.file_exists is True


def test_build_attachment_integrity_result_returns_ok_for_matching_metadata_and_file() -> None:
    result = build_attachment_integrity_result(
        attachment_id="ATT-001",
        expected_path="attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg",
        metadata_exists=True,
        file_exists=True,
    )

    assert result.status_code == OK
    assert result.severity == SEVERITY_OK
    assert result.recommended_action is None


def test_build_attachment_integrity_result_returns_missing_file() -> None:
    result = build_attachment_integrity_result(
        attachment_id="ATT-001",
        expected_path="attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg",
        metadata_exists=True,
        file_exists=False,
    )

    assert result.status_code == MISSING_FILE
    assert result.severity == SEVERITY_ERROR
    assert (
        result.recommended_action
        == ACTION_RESTORE_FROM_BACKUP_OR_REVIEW_AUDIT_TRAIL
    )


def test_build_attachment_integrity_result_returns_orphan_file() -> None:
    result = build_attachment_integrity_result(
        attachment_id=None,
        expected_path=None,
        actual_path="attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg",
        metadata_exists=False,
        file_exists=True,
    )

    assert result.status_code == ORPHAN_FILE
    assert result.severity == SEVERITY_WARNING
    assert result.recommended_action == ACTION_CREATE_METADATA_OR_QUARANTINE_FILE


def test_build_attachment_integrity_result_returns_invalid_path() -> None:
    result = build_attachment_integrity_result(
        attachment_id="ATT-001",
        expected_path="legacy/photo.jpg",
        metadata_exists=True,
        file_exists=True,
        path_is_valid=False,
    )

    assert result.status_code == INVALID_PATH
    assert result.severity == SEVERITY_ERROR
    assert result.recommended_action == ACTION_REBUILD_PATH_WITH_CANONICAL_HELPER


def test_build_attachment_integrity_result_returns_duplicate_metadata_first() -> None:
    result = build_attachment_integrity_result(
        attachment_id="ATT-001",
        expected_path="legacy/photo.jpg",
        metadata_exists=True,
        file_exists=True,
        path_is_valid=False,
        duplicate_metadata=True,
    )

    assert result.status_code == DUPLICATE_METADATA
    assert result.severity == SEVERITY_ERROR
    assert (
        result.recommended_action
        == ACTION_MERGE_OR_DEACTIVATE_DUPLICATE_METADATA
    )


def test_build_attachment_integrity_result_returns_unreadable_file() -> None:
    result = build_attachment_integrity_result(
        attachment_id="ATT-001",
        expected_path="attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg",
        metadata_exists=True,
        file_exists=True,
        file_is_readable=False,
    )

    assert result.status_code == UNREADABLE_FILE
    assert result.severity == SEVERITY_ERROR
    assert (
        result.recommended_action
        == ACTION_CHECK_PERMISSIONS_DISK_OR_FILE_CORRUPTION
    )


def test_build_attachment_integrity_result_rejects_missing_metadata_and_file() -> None:
    with pytest.raises(ValueError, match="metadata and file cannot both be missing"):
        build_attachment_integrity_result(
            attachment_id=None,
            expected_path=None,
            metadata_exists=False,
            file_exists=False,
        )


def test_build_attachment_integrity_result_keeps_checked_at_and_notes() -> None:
    checked_at = datetime(2026, 6, 7, 14, 32, 10, tzinfo=timezone.utc)

    result = build_attachment_integrity_result(
        attachment_id="ATT-001",
        expected_path="attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg",
        metadata_exists=True,
        file_exists=True,
        checked_at=checked_at,
        notes="Manual recheck completed.",
    )

    assert result.checked_at == checked_at
    assert result.notes == "Manual recheck completed."


def test_attachment_integrity_report_summary_empty_results() -> None:
    summary = build_attachment_integrity_report_summary([])

    assert summary.total_checked == 0
    assert summary.ok_count == 0
    assert summary.error_count == 0
    assert summary.warning_count == 0
    assert summary.missing_file_count == 0
    assert summary.orphan_file_count == 0
    assert summary.invalid_path_count == 0
    assert summary.duplicate_metadata_count == 0
    assert summary.unreadable_file_count == 0
    assert summary.generated_at.tzinfo is not None
    assert summary.generated_at.utcoffset() is not None
    assert summary.generated_at.utcoffset().total_seconds() == 0


def test_attachment_integrity_report_summary_counts_ok_results() -> None:
    results = [
        AttachmentIntegrityResult(
            status_code=OK,
            severity=SEVERITY_OK,
            metadata_exists=True,
            file_exists=True,
        ),
        AttachmentIntegrityResult(
            status_code=OK,
            severity=SEVERITY_OK,
            metadata_exists=True,
            file_exists=True,
        ),
    ]

    summary = build_attachment_integrity_report_summary(results)

    assert summary.total_checked == 2
    assert summary.ok_count == 2
    assert summary.error_count == 0
    assert summary.warning_count == 0


def test_attachment_integrity_report_summary_counts_error_statuses() -> None:
    results = [
        AttachmentIntegrityResult(status_code=MISSING_FILE, severity=SEVERITY_ERROR),
        AttachmentIntegrityResult(status_code=INVALID_PATH, severity=SEVERITY_ERROR),
        AttachmentIntegrityResult(
            status_code=DUPLICATE_METADATA,
            severity=SEVERITY_ERROR,
        ),
        AttachmentIntegrityResult(
            status_code=UNREADABLE_FILE,
            severity=SEVERITY_ERROR,
        ),
    ]

    summary = build_attachment_integrity_report_summary(results)

    assert summary.total_checked == 4
    assert summary.error_count == 4
    assert summary.missing_file_count == 1
    assert summary.invalid_path_count == 1
    assert summary.duplicate_metadata_count == 1
    assert summary.unreadable_file_count == 1


def test_attachment_integrity_report_summary_counts_warning_statuses() -> None:
    summary = build_attachment_integrity_report_summary(
        [
            AttachmentIntegrityResult(
                status_code=ORPHAN_FILE,
                severity=SEVERITY_WARNING,
            )
        ]
    )

    assert summary.total_checked == 1
    assert summary.warning_count == 1
    assert summary.orphan_file_count == 1


def test_attachment_integrity_report_summary_counts_mixed_results() -> None:
    results = [
        AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK),
        AttachmentIntegrityResult(status_code=MISSING_FILE, severity=SEVERITY_ERROR),
        AttachmentIntegrityResult(status_code=ORPHAN_FILE, severity=SEVERITY_WARNING),
        AttachmentIntegrityResult(status_code=INVALID_PATH, severity=SEVERITY_ERROR),
    ]

    summary = build_attachment_integrity_report_summary(results)

    assert summary.total_checked == 4
    assert summary.ok_count == 1
    assert summary.error_count == 2
    assert summary.warning_count == 1
    assert summary.missing_file_count == 1
    assert summary.orphan_file_count == 1
    assert summary.invalid_path_count == 1


def test_attachment_integrity_report_summary_rejects_negative_counter() -> None:
    with pytest.raises(ValueError, match="total_checked cannot be negative"):
        AttachmentIntegrityReportSummary(
            total_checked=-1,
            ok_count=0,
            error_count=0,
            warning_count=0,
            missing_file_count=0,
            orphan_file_count=0,
            invalid_path_count=0,
            duplicate_metadata_count=0,
            unreadable_file_count=0,
        )


def test_attachment_integrity_report_summary_rejects_status_total_mismatch() -> None:
    with pytest.raises(ValueError, match="total_checked must match status counts"):
        AttachmentIntegrityReportSummary(
            total_checked=2,
            ok_count=1,
            error_count=1,
            warning_count=0,
            missing_file_count=0,
            orphan_file_count=0,
            invalid_path_count=0,
            duplicate_metadata_count=0,
            unreadable_file_count=0,
        )


def test_attachment_integrity_report_summary_rejects_severity_total_mismatch() -> None:
    with pytest.raises(ValueError, match="total_checked must match severity counts"):
        AttachmentIntegrityReportSummary(
            total_checked=1,
            ok_count=0,
            error_count=0,
            warning_count=0,
            missing_file_count=1,
            orphan_file_count=0,
            invalid_path_count=0,
            duplicate_metadata_count=0,
            unreadable_file_count=0,
        )


def test_attachment_integrity_report_can_be_created_with_empty_results() -> None:
    report = build_attachment_integrity_report([])

    assert report.results == ()
    assert report.summary.total_checked == 0


def test_attachment_integrity_report_summary_matches_multiple_results() -> None:
    results = [
        AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK),
        AttachmentIntegrityResult(status_code=MISSING_FILE, severity=SEVERITY_ERROR),
    ]

    report = build_attachment_integrity_report(results)

    assert report.summary.total_checked == 2
    assert report.summary.ok_count == 1
    assert report.summary.error_count == 1


def test_attachment_integrity_report_stores_results_as_tuple() -> None:
    results = [AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)]

    report = build_attachment_integrity_report(results)

    assert isinstance(report.results, tuple)
    assert report.results == tuple(results)


def test_attachment_integrity_report_keeps_source_and_notes() -> None:
    report = build_attachment_integrity_report(
        [],
        source="manual-check",
        notes="No attachments in scope.",
    )

    assert report.source == "manual-check"
    assert report.notes == "No attachments in scope."


def test_attachment_integrity_report_sets_generated_at_when_missing() -> None:
    report = build_attachment_integrity_report([])

    assert report.generated_at.tzinfo is not None
    assert report.generated_at.utcoffset() is not None
    assert report.generated_at.utcoffset().total_seconds() == 0


def test_attachment_integrity_report_keeps_provided_generated_at() -> None:
    generated_at = datetime(2026, 6, 7, 14, 32, 10, tzinfo=timezone.utc)

    report = build_attachment_integrity_report([], generated_at=generated_at)

    assert report.generated_at == generated_at


def test_attachment_integrity_report_rejects_summary_count_mismatch() -> None:
    summary = AttachmentIntegrityReportSummary(
        total_checked=1,
        ok_count=1,
        error_count=0,
        warning_count=0,
        missing_file_count=0,
        orphan_file_count=0,
        invalid_path_count=0,
        duplicate_metadata_count=0,
        unreadable_file_count=0,
    )

    with pytest.raises(ValueError, match="summary.total_checked must match result count"):
        AttachmentIntegrityReport(results=(), summary=summary)


def test_build_attachment_integrity_report_builds_summary() -> None:
    results = (
        AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK),
        AttachmentIntegrityResult(status_code=ORPHAN_FILE, severity=SEVERITY_WARNING),
    )

    report = build_attachment_integrity_report(results)

    assert report.results == results
    assert report.summary.total_checked == 2
    assert report.summary.ok_count == 1
    assert report.summary.warning_count == 1
    assert report.summary.orphan_file_count == 1


def test_serialize_attachment_integrity_result_contains_expected_fields() -> None:
    checked_at = datetime(2026, 6, 7, 14, 32, 10, tzinfo=timezone.utc)
    result = AttachmentIntegrityResult(
        status_code=MISSING_FILE,
        severity=SEVERITY_ERROR,
        attachment_id="ATT-001",
        expected_path="attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg",
        actual_path=None,
        metadata_exists=True,
        file_exists=False,
        recommended_action=ACTION_RESTORE_FROM_BACKUP_OR_REVIEW_AUDIT_TRAIL,
        checked_at=checked_at,
        notes=None,
    )

    serialized = serialize_attachment_integrity_result(result)

    assert serialized == {
        "status_code": MISSING_FILE,
        "severity": SEVERITY_ERROR,
        "attachment_id": "ATT-001",
        "expected_path": (
            "attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg"
        ),
        "actual_path": None,
        "metadata_exists": True,
        "file_exists": False,
        "recommended_action": ACTION_RESTORE_FROM_BACKUP_OR_REVIEW_AUDIT_TRAIL,
        "checked_at": "2026-06-07T14:32:10+00:00",
        "notes": None,
    }


def test_serialize_attachment_integrity_report_summary_contains_expected_fields() -> None:
    generated_at = datetime(2026, 6, 7, 14, 32, 10, tzinfo=timezone.utc)
    summary = AttachmentIntegrityReportSummary(
        total_checked=2,
        ok_count=1,
        error_count=1,
        warning_count=0,
        missing_file_count=1,
        orphan_file_count=0,
        invalid_path_count=0,
        duplicate_metadata_count=0,
        unreadable_file_count=0,
        generated_at=generated_at,
    )

    serialized = serialize_attachment_integrity_report_summary(summary)

    assert serialized == {
        "total_checked": 2,
        "ok_count": 1,
        "error_count": 1,
        "warning_count": 0,
        "missing_file_count": 1,
        "orphan_file_count": 0,
        "invalid_path_count": 0,
        "duplicate_metadata_count": 0,
        "unreadable_file_count": 0,
        "generated_at": "2026-06-07T14:32:10+00:00",
    }


def test_serialize_attachment_integrity_report_contains_expected_fields() -> None:
    generated_at = datetime(2026, 6, 7, 14, 32, 10, tzinfo=timezone.utc)
    report = build_attachment_integrity_report(
        [AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)],
        source="manual-check",
        notes="Ready for audit.",
        generated_at=generated_at,
    )

    serialized = serialize_attachment_integrity_report(report)

    assert set(serialized) == {"results", "summary", "generated_at", "source", "notes"}
    assert serialized["generated_at"] == "2026-06-07T14:32:10+00:00"
    assert serialized["source"] == "manual-check"
    assert serialized["notes"] == "Ready for audit."


def test_serialize_attachment_integrity_report_keeps_none_fields() -> None:
    report = build_attachment_integrity_report(
        [AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)]
    )

    serialized = serialize_attachment_integrity_report(report)

    assert "source" in serialized
    assert "notes" in serialized
    assert serialized["source"] is None
    assert serialized["notes"] is None
    assert "attachment_id" in serialized["results"][0]
    assert serialized["results"][0]["attachment_id"] is None


def test_serialize_attachment_integrity_report_serializes_nested_results() -> None:
    report = build_attachment_integrity_report(
        [
            AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK),
            AttachmentIntegrityResult(
                status_code=ORPHAN_FILE,
                severity=SEVERITY_WARNING,
            ),
        ]
    )

    serialized = serialize_attachment_integrity_report(report)

    assert isinstance(serialized["results"], list)
    assert serialized["results"][0]["status_code"] == OK
    assert serialized["results"][1]["status_code"] == ORPHAN_FILE


def test_serialize_attachment_integrity_report_serializes_nested_summary() -> None:
    report = build_attachment_integrity_report(
        [
            AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK),
            AttachmentIntegrityResult(status_code=MISSING_FILE, severity=SEVERITY_ERROR),
        ]
    )

    serialized = serialize_attachment_integrity_report(report)

    assert serialized["summary"]["total_checked"] == 2
    assert serialized["summary"]["ok_count"] == 1
    assert serialized["summary"]["error_count"] == 1
    assert serialized["summary"]["missing_file_count"] == 1


def test_serialize_attachment_integrity_helpers_do_not_mutate_models() -> None:
    result = AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)
    report = build_attachment_integrity_report([result], source="manual-check")
    original_results = report.results
    original_summary_total = report.summary.total_checked
    original_source = report.source

    serialize_attachment_integrity_result(result)
    serialize_attachment_integrity_report_summary(report.summary)
    serialize_attachment_integrity_report(report)

    assert report.results == original_results
    assert report.summary.total_checked == original_summary_total
    assert report.source == original_source


def test_export_attachment_integrity_report_to_json_returns_string() -> None:
    report = build_attachment_integrity_report([])

    exported = export_attachment_integrity_report_to_json(report)

    assert isinstance(exported, str)


def test_export_attachment_integrity_report_to_json_can_be_loaded() -> None:
    report = build_attachment_integrity_report(
        [AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)]
    )

    exported = export_attachment_integrity_report_to_json(report)

    assert json.loads(exported)["summary"]["total_checked"] == 1


def test_export_attachment_integrity_report_to_json_includes_summary_and_results() -> None:
    report = build_attachment_integrity_report(
        [AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)]
    )

    loaded = json.loads(export_attachment_integrity_report_to_json(report))

    assert "summary" in loaded
    assert "results" in loaded
    assert isinstance(loaded["results"], list)


def test_export_attachment_integrity_report_to_json_keeps_iso_datetime_strings() -> None:
    generated_at = datetime(2026, 6, 7, 14, 32, 10, tzinfo=timezone.utc)
    checked_at = datetime(2026, 6, 7, 14, 33, 10, tzinfo=timezone.utc)
    result = AttachmentIntegrityResult(
        status_code=OK,
        severity=SEVERITY_OK,
        checked_at=checked_at,
    )
    report = build_attachment_integrity_report([result], generated_at=generated_at)

    loaded = json.loads(export_attachment_integrity_report_to_json(report))

    assert loaded["generated_at"] == "2026-06-07T14:32:10+00:00"
    assert loaded["results"][0]["checked_at"] == "2026-06-07T14:33:10+00:00"


def test_export_attachment_integrity_report_to_json_preserves_turkish_characters() -> None:
    report = build_attachment_integrity_report(
        [AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)],
        notes="Şantiye eki doğrulandı.",
    )

    exported = export_attachment_integrity_report_to_json(report)

    assert "Şantiye eki doğrulandı." in exported


def test_export_attachment_integrity_report_to_json_supports_compact_output() -> None:
    report = build_attachment_integrity_report([])

    exported = export_attachment_integrity_report_to_json(report, indent=None)

    assert "\n" not in exported
    assert json.loads(exported)["summary"]["total_checked"] == 0


def test_export_attachment_integrity_report_to_json_does_not_mutate_report() -> None:
    result = AttachmentIntegrityResult(status_code=OK, severity=SEVERITY_OK)
    report = build_attachment_integrity_report([result], source="manual-check")
    original_results = report.results
    original_summary_total = report.summary.total_checked
    original_source = report.source

    export_attachment_integrity_report_to_json(report)

    assert report.results == original_results
    assert report.summary.total_checked == original_summary_total
    assert report.source == original_source
