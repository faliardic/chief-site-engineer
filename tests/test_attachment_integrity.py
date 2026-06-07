from app.attachment_integrity import (
    ATTACHMENT_INTEGRITY_ERROR_STATUSES,
    ATTACHMENT_INTEGRITY_STATUSES,
    ATTACHMENT_INTEGRITY_WARNING_STATUSES,
    DUPLICATE_METADATA,
    INVALID_PATH,
    MISSING_FILE,
    OK,
    ORPHAN_FILE,
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
