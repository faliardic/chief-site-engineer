from app.attachment_integrity import (
    ATTACHMENT_INTEGRITY_ERROR_STATUSES,
    ATTACHMENT_INTEGRITY_SEVERITIES,
    ATTACHMENT_INTEGRITY_STATUSES,
    ATTACHMENT_INTEGRITY_WARNING_STATUSES,
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
