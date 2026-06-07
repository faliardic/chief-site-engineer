from dataclasses import dataclass, field
from datetime import datetime, timezone


OK = "OK"
MISSING_FILE = "MISSING_FILE"
ORPHAN_FILE = "ORPHAN_FILE"
INVALID_PATH = "INVALID_PATH"
DUPLICATE_METADATA = "DUPLICATE_METADATA"
UNREADABLE_FILE = "UNREADABLE_FILE"

SEVERITY_OK = "OK"
SEVERITY_WARNING = "WARNING"
SEVERITY_ERROR = "ERROR"

ACTION_RESTORE_FROM_BACKUP_OR_REVIEW_AUDIT_TRAIL = (
    "restore_from_backup_or_review_audit_trail"
)
ACTION_CREATE_METADATA_OR_QUARANTINE_FILE = "create_metadata_or_quarantine_file"
ACTION_REBUILD_PATH_WITH_CANONICAL_HELPER = "rebuild_path_with_canonical_helper"
ACTION_MERGE_OR_DEACTIVATE_DUPLICATE_METADATA = (
    "merge_or_deactivate_duplicate_metadata"
)
ACTION_CHECK_PERMISSIONS_DISK_OR_FILE_CORRUPTION = (
    "check_permissions_disk_or_file_corruption"
)

ATTACHMENT_INTEGRITY_STATUSES = frozenset(
    {
        OK,
        MISSING_FILE,
        ORPHAN_FILE,
        INVALID_PATH,
        DUPLICATE_METADATA,
        UNREADABLE_FILE,
    }
)

ATTACHMENT_INTEGRITY_ERROR_STATUSES = frozenset(
    {
        MISSING_FILE,
        INVALID_PATH,
        DUPLICATE_METADATA,
        UNREADABLE_FILE,
    }
)

ATTACHMENT_INTEGRITY_WARNING_STATUSES = frozenset({ORPHAN_FILE})

ATTACHMENT_INTEGRITY_SEVERITIES = frozenset(
    {
        SEVERITY_OK,
        SEVERITY_WARNING,
        SEVERITY_ERROR,
    }
)


@dataclass
class AttachmentIntegrityResult:
    status_code: str
    severity: str
    attachment_id: str | None = None
    expected_path: str | None = None
    actual_path: str | None = None
    metadata_exists: bool = False
    file_exists: bool = False
    recommended_action: str | None = None
    checked_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    notes: str | None = None

    def __post_init__(self) -> None:
        if self.status_code not in ATTACHMENT_INTEGRITY_STATUSES:
            raise ValueError("status_code must be a known attachment integrity status")
        if self.severity not in ATTACHMENT_INTEGRITY_SEVERITIES:
            raise ValueError("severity must be OK, WARNING, or ERROR")


def build_attachment_integrity_result(
    attachment_id: str | None,
    expected_path: str | None,
    metadata_exists: bool,
    file_exists: bool,
    actual_path: str | None = None,
    path_is_valid: bool = True,
    duplicate_metadata: bool = False,
    file_is_readable: bool = True,
    checked_at: datetime | None = None,
    notes: str | None = None,
) -> AttachmentIntegrityResult:
    if not metadata_exists and not file_exists:
        raise ValueError("metadata and file cannot both be missing")

    status_code, severity, recommended_action = _classify_integrity_status(
        metadata_exists=metadata_exists,
        file_exists=file_exists,
        path_is_valid=path_is_valid,
        duplicate_metadata=duplicate_metadata,
        file_is_readable=file_is_readable,
    )
    result_values = {
        "status_code": status_code,
        "severity": severity,
        "attachment_id": attachment_id,
        "expected_path": expected_path,
        "actual_path": actual_path,
        "metadata_exists": metadata_exists,
        "file_exists": file_exists,
        "recommended_action": recommended_action,
        "notes": notes,
    }
    if checked_at is not None:
        result_values["checked_at"] = checked_at
    return AttachmentIntegrityResult(**result_values)


def _classify_integrity_status(
    metadata_exists: bool,
    file_exists: bool,
    path_is_valid: bool,
    duplicate_metadata: bool,
    file_is_readable: bool,
) -> tuple[str, str, str | None]:
    if duplicate_metadata:
        return (
            DUPLICATE_METADATA,
            SEVERITY_ERROR,
            ACTION_MERGE_OR_DEACTIVATE_DUPLICATE_METADATA,
        )
    if not path_is_valid:
        return (
            INVALID_PATH,
            SEVERITY_ERROR,
            ACTION_REBUILD_PATH_WITH_CANONICAL_HELPER,
        )
    if metadata_exists and not file_exists:
        return (
            MISSING_FILE,
            SEVERITY_ERROR,
            ACTION_RESTORE_FROM_BACKUP_OR_REVIEW_AUDIT_TRAIL,
        )
    if not metadata_exists and file_exists:
        return (
            ORPHAN_FILE,
            SEVERITY_WARNING,
            ACTION_CREATE_METADATA_OR_QUARANTINE_FILE,
        )
    if file_exists and not file_is_readable:
        return (
            UNREADABLE_FILE,
            SEVERITY_ERROR,
            ACTION_CHECK_PERMISSIONS_DISK_OR_FILE_CORRUPTION,
        )
    return OK, SEVERITY_OK, None
