"""Validated runtime entry point for the local CSE OpenAI bridge.

The bridge implementation predates the Responses API requirement that strict
function schemas include a ``required`` array, including the empty array for a
function with no arguments.  This module normalizes that contract before the
worker imports the bridge and adds data-minimal OpenAI HTTP diagnostics.
"""

from __future__ import annotations

import json
import re
import time
import urllib.error
import urllib.request
from typing import Any, Mapping, MutableMapping, Sequence

from tools import cse_api_bridge

_SAFE_ERROR_PART = re.compile(r"[^a-z0-9_.-]+")
_INSTALLED = False


def _safe_error_part(value: object) -> str:
    if not isinstance(value, str):
        return ""
    normalized = _SAFE_ERROR_PART.sub("_", value.strip().lower()).strip("_")
    return normalized[:96]


def openai_error_reason(error: urllib.error.HTTPError) -> str:
    """Return an error reason without retaining messages, prompts, or secrets."""

    base = f"openai_http_{error.code}"
    try:
        raw = error.read(65_536)
        payload = json.loads(raw.decode("utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError, AttributeError):
        return base
    if not isinstance(payload, Mapping):
        return base
    detail = payload.get("error")
    if not isinstance(detail, Mapping):
        return base
    parts = [
        _safe_error_part(detail.get("type")),
        _safe_error_part(detail.get("code")),
        _safe_error_part(detail.get("param")),
    ]
    safe_parts = [part for part in parts if part]
    return base if not safe_parts else base + "__" + "__".join(safe_parts)


def normalize_strict_function_schemas(
    tools: Sequence[MutableMapping[str, Any]],
) -> None:
    """Make every strict object schema explicit and internally consistent."""

    for tool in tools:
        if tool.get("type") != "function" or tool.get("strict") is not True:
            continue
        parameters = tool.get("parameters")
        if not isinstance(parameters, MutableMapping):
            raise cse_api_bridge.BridgeError("openai_tool_schema_invalid")
        if parameters.get("type") != "object":
            raise cse_api_bridge.BridgeError("openai_tool_schema_invalid")
        properties = parameters.get("properties")
        if not isinstance(properties, Mapping):
            raise cse_api_bridge.BridgeError("openai_tool_schema_invalid")
        parameters["required"] = list(properties.keys())
        parameters["additionalProperties"] = False


def responses_create(
    self: cse_api_bridge.ResponsesClient,
    payload: Mapping[str, Any],
) -> Mapping[str, Any]:
    """Responses API transport with bounded retries and safe diagnostics."""

    delay = 2.0
    for attempt in range(3):
        request = urllib.request.Request(
            "https://api.openai.com/v1/responses",
            data=json.dumps(payload).encode("utf-8"),
            method="POST",
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "User-Agent": "cse-api-bridge",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=180) as response:
                value = json.loads(response.read().decode("utf-8"))
                if not isinstance(value, Mapping):
                    raise cse_api_bridge.BridgeError("openai_response_invalid")
                return value
        except urllib.error.HTTPError as exc:
            retryable = exc.code in {408, 409, 429, 500, 502, 503, 504}
            if not retryable or attempt == 2:
                raise cse_api_bridge.BridgeError(openai_error_reason(exc)) from exc
        except (OSError, TimeoutError) as exc:
            if attempt == 2:
                raise cse_api_bridge.BridgeError("openai_unavailable") from exc
        time.sleep(delay)
        delay *= 2
    raise cse_api_bridge.BridgeError("openai_unavailable")


def install() -> None:
    """Install the compatibility contract once for this worker process."""

    global _INSTALLED
    if _INSTALLED:
        return
    normalize_strict_function_schemas(cse_api_bridge.TOOLS)
    cse_api_bridge.ResponsesClient.create = responses_create
    _INSTALLED = True


def main(argv: Sequence[str] | None = None) -> int:
    install()
    from tools.cse_bridge_local import main as local_main

    return local_main(argv)


if __name__ == "__main__":
    raise SystemExit(main())
