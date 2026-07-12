"""Small persistence-facing records with no SQLite details."""

import json
from collections.abc import Mapping
from dataclasses import dataclass
from typing import cast


OBSERVATION_EVENT_TYPES: tuple[str, ...] = (
    "observation_created",
    "observation_status_changed",
    "observation_reporting_updated",
    "observation_archived",
)


@dataclass(frozen=True)
class ProjectRecord:
    """Minimal persistent project record."""

    project_id: str
    name: str
    created_at: str


@dataclass(frozen=True)
class AttachmentMetadataRecord:
    """Persistent metadata for one managed attachment binary."""

    attachment_id: str
    observation_id: str
    original_name: str
    stored_relative_path: str
    sha256: str
    size_bytes: int
    mime_type: str | None
    status: str
    created_at: str
    created_by: str | None


@dataclass(frozen=True)
class ObservationEventRecord:
    """Append-only observation event record."""

    event_id: str
    observation_id: str
    event_type: str
    actor: str | None
    occurred_at: str
    payload_json: str

    @property
    def payload(self) -> dict[str, object]:
        """Return the JSON object as a new Python dictionary."""

        return cast(dict[str, object], json.loads(self.payload_json))


def serialize_event_payload(payload: Mapping[str, object]) -> str:
    """Serialize an event payload as deterministic JSON object text."""

    if not isinstance(payload, Mapping):
        raise ValueError("event payload must be a JSON object")
    try:
        return json.dumps(
            dict(payload),
            ensure_ascii=False,
            allow_nan=False,
            sort_keys=True,
            separators=(",", ":"),
        )
    except (TypeError, ValueError) as exc:
        raise ValueError("event payload must be a JSON object") from exc


def canonicalize_event_payload_json(payload_json: str) -> str:
    """Validate JSON object text and return deterministic serialization."""

    if not isinstance(payload_json, str):
        raise ValueError("event payload_json must be a valid JSON object")
    try:
        payload = json.loads(payload_json, parse_constant=_reject_json_constant)
    except (TypeError, ValueError) as exc:
        raise ValueError("event payload_json must be a valid JSON object") from exc
    if not isinstance(payload, dict):
        raise ValueError("event payload_json must be a valid JSON object")
    return serialize_event_payload(payload)


def _reject_json_constant(value: str) -> None:
    raise ValueError(f"unsupported JSON constant: {value}")
