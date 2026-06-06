from dataclasses import dataclass


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


@dataclass
class AttachmentRecord:
    """Represents a file attachment reference."""

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
