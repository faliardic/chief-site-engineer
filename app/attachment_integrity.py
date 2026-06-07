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
