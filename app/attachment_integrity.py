import json
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path


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


@dataclass
class AttachmentIntegrityReportSummary:
    total_checked: int
    ok_count: int
    error_count: int
    warning_count: int
    missing_file_count: int
    orphan_file_count: int
    invalid_path_count: int
    duplicate_metadata_count: int
    unreadable_file_count: int
    generated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def __post_init__(self) -> None:
        counters = {
            "total_checked": self.total_checked,
            "ok_count": self.ok_count,
            "error_count": self.error_count,
            "warning_count": self.warning_count,
            "missing_file_count": self.missing_file_count,
            "orphan_file_count": self.orphan_file_count,
            "invalid_path_count": self.invalid_path_count,
            "duplicate_metadata_count": self.duplicate_metadata_count,
            "unreadable_file_count": self.unreadable_file_count,
        }
        for field_name, value in counters.items():
            if value < 0:
                raise ValueError(f"{field_name} cannot be negative")

        status_total = (
            self.ok_count
            + self.missing_file_count
            + self.orphan_file_count
            + self.invalid_path_count
            + self.duplicate_metadata_count
            + self.unreadable_file_count
        )
        if self.total_checked != status_total:
            raise ValueError("total_checked must match status counts")

        severity_total = self.ok_count + self.error_count + self.warning_count
        if self.total_checked != severity_total:
            raise ValueError("total_checked must match severity counts")


@dataclass
class AttachmentIntegrityReport:
    results: tuple[AttachmentIntegrityResult, ...]
    summary: AttachmentIntegrityReportSummary
    generated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    source: str | None = None
    notes: str | None = None

    def __post_init__(self) -> None:
        self.results = tuple(self.results)
        if self.summary.total_checked != len(self.results):
            raise ValueError("summary.total_checked must match result count")
        if not _is_utc_datetime(self.generated_at):
            raise ValueError("generated_at must be a timezone-aware UTC datetime")
        if not _is_utc_datetime(self.summary.generated_at):
            raise ValueError(
                "summary.generated_at must be a timezone-aware UTC datetime"
            )


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


def build_attachment_integrity_report_summary(
    results: list[AttachmentIntegrityResult],
) -> AttachmentIntegrityReportSummary:
    return AttachmentIntegrityReportSummary(
        total_checked=len(results),
        ok_count=sum(1 for result in results if result.status_code == OK),
        error_count=sum(
            1 for result in results if result.severity == SEVERITY_ERROR
        ),
        warning_count=sum(
            1 for result in results if result.severity == SEVERITY_WARNING
        ),
        missing_file_count=sum(
            1 for result in results if result.status_code == MISSING_FILE
        ),
        orphan_file_count=sum(
            1 for result in results if result.status_code == ORPHAN_FILE
        ),
        invalid_path_count=sum(
            1 for result in results if result.status_code == INVALID_PATH
        ),
        duplicate_metadata_count=sum(
            1 for result in results if result.status_code == DUPLICATE_METADATA
        ),
        unreadable_file_count=sum(
            1 for result in results if result.status_code == UNREADABLE_FILE
        ),
    )


def build_attachment_integrity_report(
    results: list[AttachmentIntegrityResult] | tuple[AttachmentIntegrityResult, ...],
    source: str | None = None,
    notes: str | None = None,
    generated_at: datetime | None = None,
) -> AttachmentIntegrityReport:
    result_tuple = tuple(results)
    summary = build_attachment_integrity_report_summary(list(result_tuple))
    report_values = {
        "results": result_tuple,
        "summary": summary,
        "source": source,
        "notes": notes,
    }
    if generated_at is not None:
        report_values["generated_at"] = generated_at
    return AttachmentIntegrityReport(**report_values)


def serialize_attachment_integrity_result(
    result: AttachmentIntegrityResult,
) -> dict:
    return {
        "status_code": result.status_code,
        "severity": result.severity,
        "attachment_id": result.attachment_id,
        "expected_path": result.expected_path,
        "actual_path": result.actual_path,
        "metadata_exists": result.metadata_exists,
        "file_exists": result.file_exists,
        "recommended_action": result.recommended_action,
        "checked_at": result.checked_at.isoformat(),
        "notes": result.notes,
    }


def serialize_attachment_integrity_report_summary(
    summary: AttachmentIntegrityReportSummary,
) -> dict:
    return {
        "total_checked": summary.total_checked,
        "ok_count": summary.ok_count,
        "error_count": summary.error_count,
        "warning_count": summary.warning_count,
        "missing_file_count": summary.missing_file_count,
        "orphan_file_count": summary.orphan_file_count,
        "invalid_path_count": summary.invalid_path_count,
        "duplicate_metadata_count": summary.duplicate_metadata_count,
        "unreadable_file_count": summary.unreadable_file_count,
        "generated_at": summary.generated_at.isoformat(),
    }


def serialize_attachment_integrity_report(
    report: AttachmentIntegrityReport,
) -> dict:
    return {
        "results": [
            serialize_attachment_integrity_result(result)
            for result in report.results
        ],
        "summary": serialize_attachment_integrity_report_summary(report.summary),
        "generated_at": report.generated_at.isoformat(),
        "source": report.source,
        "notes": report.notes,
    }


def export_attachment_integrity_report_to_json(
    report: AttachmentIntegrityReport,
    *,
    indent: int | None = 2,
) -> str:
    return json.dumps(
        serialize_attachment_integrity_report(report),
        ensure_ascii=False,
        indent=indent,
    )


def export_attachment_integrity_report_to_json_file(
    report: AttachmentIntegrityReport,
    output_path: str,
    *,
    indent: int | None = 2,
    overwrite: bool = False,
) -> str:
    output = Path(output_path)
    if not output.parent.exists():
        raise FileNotFoundError(f"Parent folder does not exist: {output.parent}")
    if output.exists() and not overwrite:
        raise FileExistsError(f"Output file already exists: {output_path}")

    output.write_text(
        export_attachment_integrity_report_to_json(report, indent=indent),
        encoding="utf-8",
    )
    return output_path


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


def _is_utc_datetime(value: datetime) -> bool:
    return (
        value.tzinfo is not None
        and value.utcoffset() is not None
        and value.utcoffset().total_seconds() == 0
    )
