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
    location: str | None = None
    category: str | None = None
    severity: str = "medium"
    responsible_party: str | None = None
    corrective_action: str | None = None
    due_date: str | None = None
    closed_date: str | None = None
    related_inspection_request_id: str | None = None
    related_pour_id: str | None = None
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
