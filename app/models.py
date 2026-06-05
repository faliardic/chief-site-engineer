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
