"""Pure path contracts shared by attachment persistence and file storage."""

import re
from pathlib import PurePosixPath
from uuid import UUID


SAFE_SUFFIX_PATTERN = re.compile(r"^\.[a-z0-9]{1,10}$")


def validate_canonical_uuid(value: str, field_name: str) -> str:
    """Return a canonical UUID string or raise ``ValueError``."""

    try:
        parsed = UUID(value)
    except (AttributeError, TypeError, ValueError) as exc:
        raise ValueError(f"{field_name} must be a canonical UUID string") from exc
    if str(parsed) != value:
        raise ValueError(f"{field_name} must be a canonical UUID string")
    return value


def safe_attachment_suffix(original_name: str) -> str:
    """Return a short lowercase safe suffix or the ``.bin`` fallback."""

    name = PurePosixPath(original_name.replace("\\", "/")).name
    suffix = PurePosixPath(name).suffix.lower()
    if SAFE_SUFFIX_PATTERN.fullmatch(suffix):
        return suffix
    return ".bin"


def build_staging_relative_path(attachment_id: str) -> str:
    validate_canonical_uuid(attachment_id, "attachment_id")
    return f"staging/{attachment_id}.part"


def build_attachment_relative_path(
    observation_id: str,
    attachment_id: str,
    original_name: str,
) -> str:
    validate_canonical_uuid(observation_id, "observation_id")
    validate_canonical_uuid(attachment_id, "attachment_id")
    suffix = safe_attachment_suffix(original_name)
    return f"attachments/{observation_id}/{attachment_id}{suffix}"


def validate_posix_relative_path(value: str) -> PurePosixPath:
    """Reject absolute, mixed-separator and traversal-style relative paths."""

    if not isinstance(value, str) or not value:
        raise ValueError("path must be a non-empty POSIX relative path")
    if "\\" in value:
        raise ValueError("path must use POSIX separators only")
    raw_parts = value.split("/")
    if any(part in {"", ".", ".."} for part in raw_parts):
        raise ValueError("path cannot contain empty, dot or traversal segments")
    path = PurePosixPath(value)
    if path.is_absolute():
        raise ValueError("path must be relative")
    return path


def validate_staging_relative_path(value: str, attachment_id: str) -> PurePosixPath:
    path = validate_posix_relative_path(value)
    expected = build_staging_relative_path(attachment_id)
    if path.as_posix() != expected:
        raise ValueError("staging path does not match attachment_id")
    return path


def validate_attachment_relative_path(
    value: str,
    observation_id: str,
    attachment_id: str,
) -> PurePosixPath:
    """Validate the canonical managed attachment layout and identifiers."""

    validate_canonical_uuid(observation_id, "observation_id")
    validate_canonical_uuid(attachment_id, "attachment_id")
    path = validate_posix_relative_path(value)
    if len(path.parts) != 3 or path.parts[:2] != (
        "attachments",
        observation_id,
    ):
        raise ValueError("attachment path does not match the managed layout")
    filename = path.parts[2]
    if not filename.startswith(attachment_id):
        raise ValueError("attachment filename does not match attachment_id")
    suffix = filename[len(attachment_id) :]
    if not SAFE_SUFFIX_PATTERN.fullmatch(suffix):
        raise ValueError("attachment filename suffix is unsafe")
    return path
