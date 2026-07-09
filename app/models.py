import json
from dataclasses import dataclass
from enum import Enum
from pathlib import Path


class FileType(str, Enum):
    """Canonical file type values for file attachment metadata."""

    IMAGE = "image"
    VIDEO = "video"
    PDF = "pdf"
    DOCUMENT = "document"
    AUDIO = "audio"
    OTHER = "other"


class AttachmentStatus(str, Enum):
    """Canonical attachment lifecycle status values."""

    ACTIVE = "active"
    ARCHIVED = "archived"
    MISSING = "missing"
    DELETED = "deleted"


@dataclass
class SiteProject:
    """Represents a construction site project."""

    project_id: str
    name: str
    location: str
    employer: str | None = None
    contractor: str | None = None
    building_inspection_company: str | None = None
    start_date: str | None = None
    status: str = "active"


@dataclass
class ChecklistItem:
    """Represents a checklist item for site controls."""

    item_id: str
    title: str
    category: str
    description: str | None = None
    required: bool = True
    status: str = "pending"


@dataclass
class TrackingRecord:
    """Represents a field tracking record."""

    record_id: str
    project_id: str
    title: str
    description: str
    date: str
    responsible_party: str | None = None
    status: str = "open"


@dataclass
class ArchiveDocument:
    """Represents an archived project document."""

    document_id: str
    project_id: str
    title: str
    document_type: str
    file_path: str | None = None
    date: str | None = None
    notes: str | None = None


@dataclass
class DailySiteLog:
    """Represents a daily field note for a construction site."""

    log_id: str
    project_id: str
    date: str
    weather: str | None = None
    workforce_summary: str | None = None
    work_performed: str | None = None
    inspections: str | None = None
    issues: str | None = None
    notes: str | None = None
    created_by: str | None = None
    status: str = "draft"


@dataclass
class ConcretePour:
    """Represents a concrete pour planned or performed on site."""

    pour_id: str
    project_id: str
    date: str
    location: str
    concrete_class: str
    volume_m3: float | None = None
    supplier: str | None = None
    truck_count: int | None = None
    weather: str | None = None
    notes: str | None = None
    status: str = "planned"


@dataclass
class ConcreteSample:
    """Represents a concrete sample group taken from a pour."""

    sample_id: str
    pour_id: str
    project_id: str
    sample_date: str
    sample_count: int
    seven_day_test_date: str | None = None
    twenty_eight_day_test_date: str | None = None
    seven_day_result_mpa: float | None = None
    twenty_eight_day_result_mpa: float | None = None
    laboratory: str | None = None
    status: str = "waiting"


@dataclass
class InspectionRequest:
    """Represents an inspection request sent to a building inspection company."""

    request_id: str
    project_id: str
    requested_date: str
    inspection_type: str
    requested_by: str | None = None
    inspection_company: str | None = None
    related_pour_id: str | None = None
    planned_inspection_date: str | None = None
    completed_date: str | None = None
    result: str | None = None
    notes: str | None = None
    status: str = "requested"


@dataclass
class NonconformityRecord:
    """Represents a nonconformity found on site."""

    nonconformity_id: str
    project_id: str
    date: str
    title: str
    description: str
    nonconformity_type: str | None = None
    location: str | None = None
    category: str | None = None
    severity: str = "medium"
    detected_by: str | None = None
    detection_date: str | None = None
    responsible_party: str | None = None
    corrective_action: str | None = None
    due_date: str | None = None
    closed_date: str | None = None
    related_inspection_request_id: str | None = None
    related_pour_id: str | None = None
    final_status: str | None = None
    notes: str | None = None
    status: str = "open"
    is_archived: bool = False


@dataclass
class AttachmentRecord:
    """Represents the legacy generic attachment reference model."""

    attachment_id: str
    project_id: str
    title: str
    file_name: str
    file_type: str | None = None
    file_path: str | None = None
    related_model: str | None = None
    related_id: str | None = None
    uploaded_by: str | None = None
    uploaded_date: str | None = None
    notes: str | None = None
    status: str = "active"


@dataclass
class FileAttachmentRecord:
    """Represents the canonical file attachment metadata model.

    `file_type` should use `FileType` values as the canonical vocabulary.
    `AttachmentStatus` prepares canonical status values for future attachment
    lifecycle behavior without adding validation in this step.
    `uploaded_by` and `uploaded_at` stay optional at model level until
    upload/auth services can enforce and populate them at service level.
    """

    attachment_id: str
    related_record_type: str
    related_record_id: str
    file_name: str
    file_path: str
    file_type: str
    mime_type: str
    uploaded_at: str | None = None
    uploaded_by: str | None = None
    original_file_name: str | None = None
    description: str | None = None
    notes: str | None = None
    file_size: int | None = None

    def __post_init__(self) -> None:
        required_fields = (
            "attachment_id",
            "related_record_type",
            "related_record_id",
            "file_name",
            "file_path",
            "file_type",
            "mime_type",
        )
        for field_name in required_fields:
            value = getattr(self, field_name)
            if value is None or not value.strip():
                raise ValueError(f"{field_name} cannot be empty")

        valid_file_types = {file_type.value for file_type in FileType}
        if self.file_type not in valid_file_types:
            raise ValueError(f"file_type must be one of {sorted(valid_file_types)}")

        if self.file_size is not None and self.file_size < 0:
            raise ValueError("file_size cannot be negative")


@dataclass
class MaterialRecord:
    """Represents a material entry or usage record."""

    material_name: str
    supplier: str | None = None
    delivery_note_no: str | None = None
    quantity: float | None = None
    unit: str | None = None
    area: str | None = None
    received_date: str | None = None
    used_date: str | None = None
    status: str = "received"
    notes: str | None = None


@dataclass
class MeetingRecord:
    """Represents a meeting minutes record."""

    meeting_title: str
    meeting_date: str | None = None
    location: str | None = None
    organizer: str | None = None
    participants: str | None = None
    agenda: str | None = None
    decisions: str | None = None
    notes: str | None = None
    status: str = "draft"


@dataclass
class MeetingActionRecord:
    """Represents an action item from a meeting."""

    action_title: str
    meeting_title: str | None = None
    responsible: str | None = None
    due_date: str | None = None
    status: str = "open"
    notes: str | None = None


@dataclass
class RFIRecord:
    """Represents a request for information record."""

    subject: str
    question: str | None = None
    requested_by: str | None = None
    assigned_to: str | None = None
    request_date: str | None = None
    due_date: str | None = None
    answer: str | None = None
    status: str = "open"
    notes: str | None = None


@dataclass
class SubmittalRecord:
    """Represents a technical submission record."""

    subject: str
    submitted_by: str | None = None
    submitted_to: str | None = None
    submit_date: str | None = None
    review_due_date: str | None = None
    response: str | None = None
    status: str = "submitted"
    notes: str | None = None


@dataclass
class DailyReportRecord:
    """Represents a daily site report summary."""

    report_date: str
    weather: str | None = None
    work_summary: str | None = None
    manpower_summary: str | None = None
    equipment_summary: str | None = None
    material_summary: str | None = None
    issue_summary: str | None = None
    safety_summary: str | None = None
    prepared_by: str | None = None
    status: str = "draft"
    notes: str | None = None


@dataclass
class ProjectPartyRecord:
    """Represents a project party such as an employer or contractor."""

    party_name: str
    party_type: str | None = None
    role: str | None = None
    tax_or_id_no: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    status: str = "active"
    notes: str | None = None


@dataclass
class ContactPersonRecord:
    """Represents a contact person for project communication."""

    full_name: str
    organization: str | None = None
    role: str | None = None
    phone: str | None = None
    email: str | None = None
    responsibility_area: str | None = None
    status: str = "active"
    notes: str | None = None


@dataclass
class SiteLocationRecord:
    """Represents a site location or work area."""

    location_name: str
    block: str | None = None
    floor: str | None = None
    zone: str | None = None
    axis: str | None = None
    discipline: str | None = None
    description: str | None = None
    status: str = "active"
    notes: str | None = None


@dataclass
class WorkforceRecord:
    """Represents a crew or workforce record."""

    crew_name: str
    crew_type: str | None = None
    company: str | None = None
    worker_count: int | None = None
    work_area: str | None = None
    work_date: str | None = None
    task_description: str | None = None
    status: str = "active"
    notes: str | None = None


@dataclass
class EquipmentRecord:
    """Represents a site equipment or machine record."""

    equipment_name: str
    equipment_type: str | None = None
    owner_company: str | None = None
    serial_or_plate: str | None = None
    work_area: str | None = None
    assigned_to: str | None = None
    status: str = "available"
    notes: str | None = None


@dataclass
class SupplierRecord:
    """Represents a supplier or service provider record."""

    supplier_name: str
    supplier_type: str | None = None
    contact_person: str | None = None
    phone: str | None = None
    email: str | None = None
    service_area: str | None = None
    status: str = "active"
    notes: str | None = None


@dataclass
class SiteNoteRecord:
    """Represents a simple site note record."""

    note_title: str
    note_type: str | None = None
    location: str | None = None
    related_subject: str | None = None
    note_date: str | None = None
    status: str = "open"
    notes: str | None = None


@dataclass
class TaskCandidateRecord:
    """Represents a simple task candidate record."""

    task_title: str
    task_type: str | None = None
    related_area: str | None = None
    source: str | None = None
    target_date: str | None = None
    status: str = "open"
    notes: str | None = None


@dataclass
class ChecklistItemRecord:
    """Represents a simple checklist item record."""

    item_title: str
    item_category: str | None = None
    related_area: str | None = None
    check_reference: str | None = None
    status: str = "pending"
    notes: str | None = None


@dataclass
class CheckResultRecord:
    """Represents a simple check result record."""

    check_title: str
    check_area: str | None = None
    result: str | None = None
    checked_by: str | None = None
    check_date: str | None = None
    status: str = "recorded"
    notes: str | None = None


@dataclass
class NonconformityCandidateRecord:
    """Represents a simple nonconformity candidate record."""

    candidate_title: str
    candidate_type: str | None = None
    location: str | None = None
    observed_issue: str | None = None
    detected_by: str | None = None
    detection_date: str | None = None
    status: str = "open"
    notes: str | None = None


@dataclass
class NonconformityCandidateReviewRecord:
    """Represents a simple nonconformity candidate review record."""

    candidate_title: str
    reviewed_by: str
    review_date: str
    review_result: str
    decision_reason: str
    next_action: str
    status: str = "reviewed"
    notes: str | None = None


@dataclass
class NonconformityCandidateActionRecord:
    """Represents a simple nonconformity candidate action record."""

    candidate_title: str
    review_result: str
    action_decision: str
    action_owner: str
    target_date: str
    action_description: str
    status: str = "planned"
    notes: str | None = None


@dataclass
class NonconformityCandidateTrackingSummaryRecord:
    """Represents a simple nonconformity candidate tracking summary record."""

    candidate_title: str
    review_result: str
    action_decision: str
    action_owner: str
    tracking_status: str
    last_update_date: str
    summary_note: str
    status: str = "active"
    notes: str | None = None


@dataclass
class NonconformityCandidateProcessViewRecord:
    """Represents a simple nonconformity candidate process view record."""

    candidate_id: str
    check_result_id: str | None = None
    review_id: str | None = None
    action_id: str | None = None
    tracking_summary_id: str | None = None
    attachment_count: int = 0
    current_status: str = "open"
    last_update_date: str | None = None
    process_summary: str | None = None
    notes: str | None = None


@dataclass
class NonconformityCandidateStatusHistoryRecord:
    """Represents a simple nonconformity candidate status history record."""

    candidate_id: str
    old_status: str
    new_status: str
    change_reason: str
    changed_by: str
    change_date: str
    source_record: str | None = None
    notes: str | None = None


@dataclass
class NonconformityCandidateAssignmentRecord:
    """Represents a simple nonconformity candidate assignment record."""

    candidate_id: str
    assigned_to: str
    assigned_by: str
    assignment_date: str
    due_date: str | None = None
    responsibility_note: str | None = None
    priority: str = "normal"
    status: str = "assigned"
    notes: str | None = None


@dataclass
class NonconformityCandidateClosureRecord:
    """Represents a simple nonconformity candidate closure record."""

    candidate_id: str
    closure_decision: str
    closure_reason: str
    closed_by: str
    closure_date: str
    final_status: str
    result_note: str | None = None
    requires_follow_up: bool = False
    notes: str | None = None


@dataclass
class NonconformityCandidateConversionRecord:
    """Represents a simple nonconformity candidate conversion record."""

    candidate_id: str
    nonconformity_id: str
    conversion_decision: str
    conversion_reason: str
    converted_by: str
    conversion_date: str
    source_closure_id: str | None = None
    status: str = "converted"
    notes: str | None = None


@dataclass
class NonconformityProcessViewRecord:
    """Represents a simple nonconformity process view record."""

    nonconformity_id: str
    source_candidate_id: str | None = None
    conversion_record_id: str | None = None
    title: str | None = None
    nonconformity_type: str | None = None
    severity: str = "medium"
    responsible_party: str | None = None
    current_status: str = "open"
    final_status: str | None = None
    last_update_date: str | None = None
    process_summary: str | None = None
    notes: str | None = None


@dataclass
class NonconformityStatusHistoryRecord:
    """Represents a simple nonconformity status history record."""

    nonconformity_id: str
    old_status: str
    new_status: str
    change_reason: str
    changed_by: str
    change_date: str
    source_record: str | None = None
    notes: str | None = None


@dataclass
class NonconformityAssignmentRecord:
    """Represents a simple nonconformity assignment record."""

    nonconformity_id: str
    assigned_to: str
    assigned_role: str
    assigned_by: str
    assigned_date: str
    responsibility_scope: str
    due_date: str | None = None
    status: str = "assigned"
    notes: str | None = None


@dataclass
class NonconformityCorrectiveActionRecord:
    """Represents a simple nonconformity corrective action record."""

    nonconformity_id: str
    action_title: str
    action_description: str
    responsible_party: str
    planned_start_date: str
    due_date: str
    completion_date: str | None = None
    verification_required: bool = True
    status: str = "planned"
    notes: str | None = None


@dataclass
class NonconformityCorrectiveActionVerificationRecord:
    """Represents a simple nonconformity corrective action verification record."""

    corrective_action_id: str
    nonconformity_id: str
    verified_by: str
    verification_date: str
    verification_result: str
    verification_notes: str
    requires_rework: bool = False
    next_action: str | None = None
    status: str = "verified"
    notes: str | None = None


@dataclass
class NonconformityClosureRecord:
    """Represents a simple nonconformity closure record."""

    nonconformity_id: str
    closure_date: str
    closed_by: str
    closure_result: str
    closure_reason: str
    verified_action_id: str
    final_status: str = "closed"
    requires_follow_up: bool = False
    follow_up_note: str | None = None
    notes: str | None = None


AUDIT_EVENT_TYPES: tuple[str, ...] = (
    "record.created",
    "record.updated",
    "record.archived",
    "record.restored",
    "attachment.linked",
    "attachment.unlinked",
    "attachment.metadata_updated",
    "integrity.checked",
    "integrity.report_generated",
    "integrity.issue_detected",
    "json.exported",
    "json.export_failed",
    "backup.generated",
    "backup.validated",
    "restore.started",
    "restore.completed",
    "restore.failed",
    "handover.package_generated",
    "handover.package_validated",
    "audit.event_created",
    "audit.validation_failed",
)

AUDIT_EVENT_TYPE_SET: frozenset[str] = frozenset(AUDIT_EVENT_TYPES)


AUDIT_TARGET_RECORD_TYPES: tuple[str, ...] = (
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
)

AUDIT_TARGET_RECORD_TYPE_SET: frozenset[str] = frozenset(AUDIT_TARGET_RECORD_TYPES)


RECORD_ID_PREFIXES: dict[str, str] = {
    "PROJECT": "PRJ",
    "FILE_ATTACHMENT": "ATT",
    "AUDIT_EVENT": "AUD",
    "NONCONFORMITY": "NCR",
    "NONCONFORMITY_CANDIDATE": "NCR-CAND",
    "CORRECTIVE_ACTION": "NCR-CA",
    "MATERIAL_DELIVERY": "MAT-DEL",
    "DAILY_LOG": "LOG",
    "SITE_NOTE": "NOTE",
    "GENERIC_RECORD": "REC",
    "CHECK_RESULT": "CHK-RES",
    "ATTACHMENT_INTEGRITY_REPORT": "AIR",
    "JSON_EXPORT": "JSON-EXP",
    "BACKUP_PACKAGE": "BCK",
    "RESTORE_OPERATION": "RST",
    "HANDOVER_PACKAGE": "HND",
}

TARGET_RECORD_TYPE_TO_ID_FAMILY: dict[str, tuple[str, ...]] = {
    "project": ("PROJECT",),
    "project_record": (
        "NONCONFORMITY",
        "NONCONFORMITY_CANDIDATE",
        "DAILY_LOG",
        "SITE_NOTE",
        "MATERIAL_DELIVERY",
        "GENERIC_RECORD",
        "CHECK_RESULT",
        "CORRECTIVE_ACTION",
    ),
    "attachment": ("FILE_ATTACHMENT",),
    "attachment_metadata": ("FILE_ATTACHMENT", "RELATED_RECORD"),
    "attachment_integrity_report": ("ATTACHMENT_INTEGRITY_REPORT",),
    "json_export": ("JSON_EXPORT",),
    "backup_package": ("BACKUP_PACKAGE",),
    "restore_operation": ("RESTORE_OPERATION",),
    "handover_package": ("HANDOVER_PACKAGE",),
    "audit_event": ("AUDIT_EVENT",),
}

TARGET_RECORD_TYPE_TO_ID_PREFIXES: dict[str, tuple[str, ...]] = {
    "project": ("PRJ", "prj"),
    "project_record": (
        "NCR",
        "NCR-CAND",
        "LOG",
        "NOTE",
        "MAT-DEL",
        "REC",
        "CHK-RES",
        "NCR-CA",
    ),
    "attachment": ("ATT", "file-att", "att"),
    "attachment_metadata": (
        "ATT",
        "file-att",
        "att",
        "NCR",
        "NCR-CAND",
        "LOG",
        "NOTE",
        "MAT-DEL",
        "REC",
        "CHK-RES",
    ),
    "attachment_integrity_report": ("AIR", "ATT-INT-RPT"),
    "json_export": ("JSON-EXP",),
    "backup_package": ("BCK",),
    "restore_operation": ("RST",),
    "handover_package": ("HND",),
    "audit_event": ("AUD", "EVT", "audit"),
}


def get_record_id_family_for_target_type(target_record_type: str) -> tuple[str, ...]:
    """Return planned record ID families for a supported audit target type."""

    if target_record_type not in AUDIT_TARGET_RECORD_TYPE_SET:
        raise ValueError("target_record_type is not supported")

    return TARGET_RECORD_TYPE_TO_ID_FAMILY[target_record_type]


def get_allowed_record_id_prefixes_for_target_type(
    target_record_type: str,
) -> tuple[str, ...]:
    """Return planned record ID prefixes without validating target_record_id."""

    if target_record_type not in AUDIT_TARGET_RECORD_TYPE_SET:
        raise ValueError("target_record_type is not supported")

    return TARGET_RECORD_TYPE_TO_ID_PREFIXES[target_record_type]


def diagnose_record_id_for_target_type(
    target_record_type: str,
    target_record_id: str,
) -> dict[str, object]:
    """Return record ID prefix diagnostics without rejecting the record."""

    if not isinstance(target_record_id, str) or not target_record_id.strip():
        return {
            "target_record_type": target_record_type,
            "target_record_id": target_record_id,
            "expected_family": (),
            "allowed_prefixes": (),
            "observed_prefix": "",
            "is_compatible": False,
            "severity": "error",
            "message": "target_record_id is required for record ID diagnostics",
        }

    record_id = target_record_id.strip()

    try:
        expected_family = get_record_id_family_for_target_type(target_record_type)
        allowed_prefixes = get_allowed_record_id_prefixes_for_target_type(
            target_record_type
        )
    except ValueError:
        return {
            "target_record_type": target_record_type,
            "target_record_id": target_record_id,
            "expected_family": (),
            "allowed_prefixes": (),
            "observed_prefix": record_id.split("-", 1)[0],
            "is_compatible": False,
            "severity": "error",
            "message": "target_record_type is not supported for record ID diagnostics",
        }

    observed_prefix = ""
    for prefix in sorted(allowed_prefixes, key=len, reverse=True):
        if record_id == prefix or record_id.startswith(f"{prefix}-"):
            observed_prefix = prefix
            break

    if not observed_prefix:
        observed_prefix = record_id.split("-", 1)[0]
        return {
            "target_record_type": target_record_type,
            "target_record_id": target_record_id,
            "expected_family": expected_family,
            "allowed_prefixes": allowed_prefixes,
            "observed_prefix": observed_prefix,
            "is_compatible": False,
            "severity": "warning",
            "message": "record ID prefix is outside the allowed diagnostic prefixes",
        }

    canonical_prefixes = tuple(
        RECORD_ID_PREFIXES[family]
        for family in expected_family
        if family in RECORD_ID_PREFIXES
    )
    severity = "info" if observed_prefix in canonical_prefixes else "warning"
    message = (
        "record ID prefix matches a canonical diagnostic prefix"
        if severity == "info"
        else "record ID prefix matches a legacy diagnostic prefix"
    )

    return {
        "target_record_type": target_record_type,
        "target_record_id": target_record_id,
        "expected_family": expected_family,
        "allowed_prefixes": allowed_prefixes,
        "observed_prefix": observed_prefix,
        "is_compatible": True,
        "severity": severity,
        "message": message,
    }


def build_record_id_diagnostic_report(records: object) -> dict[str, object]:
    """Return a read-only diagnostic report for record ID references."""

    items: list[dict[str, object]] = []

    for index, record in enumerate(records if isinstance(records, (list, tuple)) else ()):
        try:
            if isinstance(record, dict):
                target_record_type = record["target_record_type"]
                target_record_id = record["target_record_id"]
            elif isinstance(record, (list, tuple)) and len(record) >= 2:
                target_record_type = record[0]
                target_record_id = record[1]
            else:
                raise ValueError("record item is not supported for diagnostics")

            diagnostic = diagnose_record_id_for_target_type(
                target_record_type,
                target_record_id,
            )
        except (KeyError, ValueError, TypeError, IndexError):
            diagnostic = {
                "target_record_type": "",
                "target_record_id": "",
                "expected_family": (),
                "allowed_prefixes": (),
                "observed_prefix": "",
                "is_compatible": False,
                "severity": "error",
                "message": "record item is not supported for record ID diagnostics",
            }

        items.append({"index": index, **diagnostic})

    compatible_count = sum(1 for item in items if item["is_compatible"] is True)
    warning_count = sum(1 for item in items if item["severity"] == "warning")
    error_count = sum(1 for item in items if item["severity"] == "error")
    total_count = len(items)
    summary = {
        "total": total_count,
        "compatible": compatible_count,
        "warnings": warning_count,
        "errors": error_count,
    }

    return {
        "total_count": total_count,
        "compatible_count": compatible_count,
        "warning_count": warning_count,
        "error_count": error_count,
        "items": items,
        "summary": summary,
    }


def build_record_id_soft_validation_report(
    diagnostic_report: object,
) -> dict[str, object]:
    """Return a read-only soft validation report for record ID diagnostics."""

    def attention_report(message: str) -> dict[str, object]:
        return {
            "status": "attention",
            "total_count": 0,
            "compatible_count": 0,
            "warning_count": 0,
            "error_count": 1,
            "review_required": True,
            "attention_required": True,
            "messages": [message],
            "items": [],
            "summary": {
                "total": 0,
                "compatible": 0,
                "warnings": 0,
                "errors": 1,
            },
        }

    if not isinstance(diagnostic_report, dict):
        return attention_report(
            "diagnostic_report must be a dict for soft validation"
        )

    required_count_fields = (
        "total_count",
        "compatible_count",
        "warning_count",
        "error_count",
    )
    counts: dict[str, int] = {}
    for field_name in required_count_fields:
        value = diagnostic_report.get(field_name)
        if not isinstance(value, int) or value < 0:
            return attention_report(
                "diagnostic_report is missing required count fields"
            )
        counts[field_name] = value

    items = diagnostic_report.get("items", [])
    if not isinstance(items, list):
        return attention_report("diagnostic_report items must be a list")

    summary = diagnostic_report.get(
        "summary",
        {
            "total": counts["total_count"],
            "compatible": counts["compatible_count"],
            "warnings": counts["warning_count"],
            "errors": counts["error_count"],
        },
    )
    if not isinstance(summary, dict):
        return attention_report("diagnostic_report summary must be a dict")

    error_count = counts["error_count"]
    warning_count = counts["warning_count"]
    if error_count > 0:
        status = "attention"
        messages = [
            "record ID diagnostics include errors requiring manual attention"
        ]
    elif warning_count > 0:
        status = "review"
        messages = ["record ID diagnostics include warnings for review"]
    else:
        status = "pass"
        messages = ["record ID diagnostics passed without warnings or errors"]

    has_unknown_severity = any(
        isinstance(item, dict)
        and item.get("severity") not in {"info", "warning", "error"}
        for item in items
    )
    if has_unknown_severity:
        messages.append(
            "record ID diagnostics include unknown severity values for review"
        )

    review_required = status in {"review", "attention"}
    attention_required = status == "attention"

    return {
        "status": status,
        "total_count": counts["total_count"],
        "compatible_count": counts["compatible_count"],
        "warning_count": warning_count,
        "error_count": error_count,
        "review_required": review_required,
        "attention_required": attention_required,
        "messages": messages,
        "items": list(items),
        "summary": dict(summary),
    }


def _record_id_format_json_ready_value(value: object) -> object:
    """Return a simple JSON-ready copy without mutating the input."""

    if isinstance(value, dict):
        return {
            str(key): _record_id_format_json_ready_value(item)
            for key, item in value.items()
        }
    if isinstance(value, (list, tuple)):
        return [_record_id_format_json_ready_value(item) for item in value]
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    return str(value)


def _unsupported_record_id_format_report(report_type: str) -> dict[str, object]:
    """Return a non-blocking formatter response for unsupported input."""

    return {
        "report_type": report_type,
        "is_supported_input": False,
        "message": "report must be a dict for record ID formatting",
        "items": [],
        "summary": {},
        "notes": [
            "Bu rapor kayit reddi degildir.",
            "Hard validation degildir.",
            "`blocked` status uretilmez.",
        ],
    }


def format_record_id_diagnostic_report_as_json_ready_dict(
    report: object,
) -> dict[str, object]:
    """Return a read-only JSON-ready diagnostic report presentation dict."""

    if not isinstance(report, dict):
        return _unsupported_record_id_format_report("record_id_diagnostic")

    formatted = _record_id_format_json_ready_value(report)
    assert isinstance(formatted, dict)
    return {
        "report_type": "record_id_diagnostic",
        "is_supported_input": True,
        **formatted,
    }


def format_record_id_soft_validation_report_as_json_ready_dict(
    report: object,
) -> dict[str, object]:
    """Return a read-only JSON-ready soft validation presentation dict."""

    if not isinstance(report, dict):
        return _unsupported_record_id_format_report("record_id_soft_validation")

    formatted = _record_id_format_json_ready_value(report)
    assert isinstance(formatted, dict)
    if formatted.get("status") == "blocked":
        formatted["status"] = "unsupported"
        messages = formatted.get("messages", [])
        if not isinstance(messages, list):
            messages = [str(messages)]
        messages.append("`blocked` status uretilmez.")
        formatted["messages"] = messages

    return {
        "report_type": "record_id_soft_validation",
        "is_supported_input": True,
        **formatted,
    }


def _record_id_format_count_lines(report: dict[str, object]) -> list[str]:
    count_fields = (
        "total_count",
        "compatible_count",
        "warning_count",
        "error_count",
    )
    return [f"- {field}: {report.get(field, 0)}" for field in count_fields]


def _record_id_format_item_line(item: dict[str, object]) -> str:
    index = item.get("index", "")
    target_type = item.get("target_record_type", "")
    target_id = item.get("target_record_id", "")
    severity = item.get("severity", "")
    message = item.get("message", "")
    return f"- [{index}] {severity} {target_type} {target_id}: {message}".strip()


def _record_id_format_warning_error_items(report: dict[str, object]) -> list[str]:
    items = report.get("items", [])
    if not isinstance(items, list):
        return ["- Items are not available in a readable list."]

    visible_items = [
        item
        for item in items
        if isinstance(item, dict)
        and item.get("severity") in {"warning", "error"}
    ]
    if not visible_items:
        return ["- No warning/error items."]

    return [_record_id_format_item_line(item) for item in visible_items]


def _unsupported_record_id_markdown(title: str) -> str:
    return "\n".join(
        [
            f"# {title}",
            "",
            "Unsupported report input.",
            "",
            "Bu rapor kayit reddi degildir.",
            "Hard validation degildir.",
            "`blocked` status uretilmez.",
        ]
    )


def format_record_id_diagnostic_report_as_markdown(report: object) -> str:
    """Return a read-only Markdown diagnostic report presentation."""

    title = "Record ID Diagnostic Report"
    if not isinstance(report, dict):
        return _unsupported_record_id_markdown(title)

    lines = [
        f"# {title}",
        "",
        "## Summary",
        *_record_id_format_count_lines(report),
        "",
        "## Warning/Error Items",
        *_record_id_format_warning_error_items(report),
        "",
        "Bu rapor kayit reddi degildir.",
        "Hard validation degildir.",
    ]
    return "\n".join(lines)


def format_record_id_soft_validation_report_as_markdown(report: object) -> str:
    """Return a read-only Markdown soft validation report presentation."""

    title = "Record ID Soft Validation Report"
    if not isinstance(report, dict):
        return _unsupported_record_id_markdown(title)

    status = report.get("status", "unknown")
    if status == "blocked":
        status = "unsupported"

    messages = report.get("messages", [])
    if not isinstance(messages, list):
        messages = [messages]
    message_lines = [f"- {message}" for message in messages] or ["- No messages."]

    lines = [
        f"# {title}",
        "",
        "## Summary",
        f"- status: {status}",
        *_record_id_format_count_lines(report),
        f"- review_required: {report.get('review_required', False)}",
        f"- attention_required: {report.get('attention_required', False)}",
        "",
        "## Messages",
        *message_lines,
        "",
        "## Review/Attention Items",
        *_record_id_format_warning_error_items(report),
        "",
        "Bu rapor kayit reddi degildir.",
        "Hard validation degildir.",
        "`blocked` status uretilmez.",
    ]
    return "\n".join(lines)


_EXPORT_FORBIDDEN_PATH_PARTS: frozenset[str] = frozenset(
    {
        ".git",
        ".env",
        ".pytest_cache",
        "__pycache__",
        "cache",
        "database",
        "backup",
        "backups",
        "restore",
        "zip",
        "yedek",
    }
)


def _prepare_export_output_path(
    output_path: str | Path,
    expected_suffix: str,
    allowed_root: str | Path | None,
) -> Path:
    if isinstance(output_path, str) and not output_path.strip():
        raise ValueError("output_path cannot be empty")

    path = Path(output_path)
    if path == Path():
        raise ValueError("output_path cannot be empty")

    if ".." in path.parts:
        raise ValueError("output_path cannot include path traversal")

    lowered_parts = {part.lower() for part in path.parts}
    if lowered_parts.intersection(_EXPORT_FORBIDDEN_PATH_PARTS):
        raise ValueError("output_path points to a non-export area")

    if path.suffix.lower() != expected_suffix:
        raise ValueError(f"output_path must use the {expected_suffix} extension")

    if path.exists() and path.is_dir():
        raise ValueError("output_path must be a file path")

    if allowed_root is not None:
        if isinstance(allowed_root, str) and not allowed_root.strip():
            raise ValueError("allowed_root cannot be empty")
        root = Path(allowed_root).resolve(strict=False)
        resolved_path = path.resolve(strict=False)
        try:
            resolved_path.relative_to(root)
        except ValueError as exc:
            raise ValueError("output_path must stay inside allowed_root") from exc

    if not path.parent.exists():
        raise FileNotFoundError("output_path parent directory does not exist")

    return path


def write_json_ready_dict_to_file(
    data: dict[str, object],
    output_path: str | Path,
    *,
    overwrite: bool = False,
    allowed_root: str | Path | None = None,
) -> Path:
    """Write a JSON-ready dict to an explicit safe .json path."""

    if not isinstance(data, dict):
        raise TypeError("data must be a JSON-ready dict")

    path = _prepare_export_output_path(output_path, ".json", allowed_root)
    if path.exists() and not overwrite:
        raise FileExistsError("output_path already exists")

    json_text = json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True)
    path.write_text(f"{json_text}\n", encoding="utf-8")
    return path


def write_markdown_text_to_file(
    markdown_text: str,
    output_path: str | Path,
    *,
    overwrite: bool = False,
    allowed_root: str | Path | None = None,
) -> Path:
    """Write Markdown text to an explicit safe .md path without reformatting."""

    if not isinstance(markdown_text, str):
        raise TypeError("markdown_text must be a string")

    path = _prepare_export_output_path(output_path, ".md", allowed_root)
    if path.exists() and not overwrite:
        raise FileExistsError("output_path already exists")

    path.write_text(markdown_text, encoding="utf-8")
    return path


_EXPORT_WRITE_RESULT_KEYS: tuple[str, ...] = (
    "success",
    "output_path",
    "attempted_path",
    "allowed_root",
    "file_type",
    "error_code",
    "error_message",
    "skipped_reason",
    "overwritten",
)


def _safe_export_attempted_path(output_path: object) -> Path | None:
    try:
        if isinstance(output_path, str) and not output_path.strip():
            return None
        return Path(output_path)  # type: ignore[arg-type]
    except TypeError:
        return None


def _export_path_existed_before(output_path: object) -> bool:
    attempted_path = _safe_export_attempted_path(output_path)
    return attempted_path.exists() if attempted_path is not None else False


def _export_result(
    *,
    success: bool,
    output_path: Path | None,
    attempted_path: Path | None,
    allowed_root: str | Path | None,
    file_type: str,
    error_code: str | None,
    error_message: str | None,
    skipped_reason: str | None,
    overwritten: bool,
) -> dict[str, object]:
    return {
        "success": success,
        "output_path": output_path,
        "attempted_path": attempted_path,
        "allowed_root": allowed_root,
        "file_type": file_type,
        "error_code": error_code,
        "error_message": error_message,
        "skipped_reason": skipped_reason,
        "overwritten": overwritten,
    }


def _export_error_code(exc: Exception) -> str:
    message = str(exc).lower()

    if isinstance(exc, FileExistsError):
        return "file_exists"
    if isinstance(exc, PermissionError):
        return "permission_error"
    if isinstance(exc, TypeError):
        if "json-ready dict" in message or "string" in message:
            return "input_type_error"
        return "serialization_error"
    if isinstance(exc, ValueError):
        if "extension" in message:
            return "wrong_extension"
        if "path traversal" in message:
            return "path_traversal"
        if "allowed_root" in message:
            return "outside_allowed_root"
        if "file path" in message:
            return "directory_path"
        if "cannot be empty" in message:
            return "empty_output_path"
        if "non-export area" in message:
            return "path_or_extension_error"
        return "path_or_extension_error"
    if isinstance(exc, FileNotFoundError):
        return "parent_missing"
    if isinstance(exc, OSError):
        return "io_error"
    return "unexpected_error"


def _export_skipped_reason(error_code: str) -> str | None:
    if error_code == "file_exists":
        return "file_exists"
    return None


def try_write_json_ready_dict_to_file(
    data: object,
    output_path: str | Path,
    *,
    overwrite: bool = False,
    allowed_root: str | Path | None = None,
) -> dict[str, object]:
    """Return a result contract for JSON file writing without raising."""

    attempted_path = _safe_export_attempted_path(output_path)
    existed_before = _export_path_existed_before(output_path)
    try:
        written_path = write_json_ready_dict_to_file(
            data,  # type: ignore[arg-type]
            output_path,
            overwrite=overwrite,
            allowed_root=allowed_root,
        )
    except Exception as exc:  # noqa: BLE001 - wrapper intentionally converts errors.
        error_code = _export_error_code(exc)
        return _export_result(
            success=False,
            output_path=None,
            attempted_path=attempted_path,
            allowed_root=allowed_root,
            file_type="json",
            error_code=error_code,
            error_message=str(exc),
            skipped_reason=_export_skipped_reason(error_code),
            overwritten=False,
        )

    return _export_result(
        success=True,
        output_path=written_path,
        attempted_path=attempted_path,
        allowed_root=allowed_root,
        file_type="json",
        error_code=None,
        error_message=None,
        skipped_reason=None,
        overwritten=bool(overwrite and existed_before),
    )


def try_write_markdown_text_to_file(
    markdown_text: object,
    output_path: str | Path,
    *,
    overwrite: bool = False,
    allowed_root: str | Path | None = None,
) -> dict[str, object]:
    """Return a result contract for Markdown file writing without raising."""

    attempted_path = _safe_export_attempted_path(output_path)
    existed_before = _export_path_existed_before(output_path)
    try:
        written_path = write_markdown_text_to_file(
            markdown_text,  # type: ignore[arg-type]
            output_path,
            overwrite=overwrite,
            allowed_root=allowed_root,
        )
    except Exception as exc:  # noqa: BLE001 - wrapper intentionally converts errors.
        error_code = _export_error_code(exc)
        return _export_result(
            success=False,
            output_path=None,
            attempted_path=attempted_path,
            allowed_root=allowed_root,
            file_type="markdown",
            error_code=error_code,
            error_message=str(exc),
            skipped_reason=_export_skipped_reason(error_code),
            overwritten=False,
        )

    return _export_result(
        success=True,
        output_path=written_path,
        attempted_path=attempted_path,
        allowed_root=allowed_root,
        file_type="markdown",
        error_code=None,
        error_message=None,
        skipped_reason=None,
        overwritten=bool(overwrite and existed_before),
    )


@dataclass
class AuditEventRecord:
    """Represents a traceable audit event without persistence or automation."""

    event_id: str
    project_id: str
    event_type: str
    actor: str
    occurred_at: str
    target_record_type: str | None = None
    target_record_id: str | None = None
    reason: str | None = None
    old_value: str | None = None
    new_value: str | None = None
    source: str | None = None
    notes: str | None = None

    def __post_init__(self) -> None:
        required_fields = (
            "event_id",
            "project_id",
            "event_type",
            "actor",
            "occurred_at",
        )
        for field_name in required_fields:
            value = getattr(self, field_name)
            if value is None or not value.strip():
                raise ValueError(f"{field_name} is required")

        if self.event_type not in AUDIT_EVENT_TYPE_SET:
            raise ValueError("event_type is not supported")

        target_type_is_set = self.target_record_type is not None
        target_id_is_set = self.target_record_id is not None
        if target_type_is_set != target_id_is_set:
            raise ValueError(
                "target_record_type and target_record_id must be provided together"
            )

        if self.target_record_type is None and self.target_record_id is None:
            return

        if not self.target_record_type.strip():
            raise ValueError("target_record_type is required")

        if not self.target_record_id.strip():
            raise ValueError("target_record_id is required")

        if self.target_record_type not in AUDIT_TARGET_RECORD_TYPE_SET:
            raise ValueError("target_record_type is not supported")
