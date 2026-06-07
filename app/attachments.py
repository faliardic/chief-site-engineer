from datetime import date, datetime


def build_attachment_path(
    project_id: str,
    record_type: str,
    record_id: str,
    uploaded_at: str | date | datetime,
    file_name: str,
) -> str:
    attachment_date = _parse_attachment_date(uploaded_at)
    safe_file_name = _normalize_file_name(file_name)
    normalized_record_type = _require_non_empty(record_type, "record_type").lower()

    return "/".join(
        [
            "attachments",
            _require_non_empty(project_id, "project_id"),
            normalized_record_type,
            f"{attachment_date.year:04d}",
            f"{attachment_date.month:02d}",
            f"{attachment_date.day:02d}",
            _require_non_empty(record_id, "record_id"),
            safe_file_name,
        ]
    )


def _parse_attachment_date(value: str | date | datetime) -> date:
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    if isinstance(value, str):
        try:
            return date.fromisoformat(value[:10])
        except ValueError as exc:
            raise ValueError("uploaded_at must use YYYY-MM-DD format") from exc
    raise ValueError("uploaded_at must be a string, date, or datetime")


def _normalize_file_name(file_name: str) -> str:
    cleaned = _require_non_empty(file_name, "file_name")
    safe = cleaned.replace("\\", "_").replace("/", "_")
    if not safe.strip("_"):
        raise ValueError("file_name cannot be empty")
    return safe


def _require_non_empty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise ValueError(f"{field_name} cannot be empty")
    return cleaned
