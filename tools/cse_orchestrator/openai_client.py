"""Bounded, one-shot OpenAI Responses API client for CSE O9."""

from __future__ import annotations

import json
import socket
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Mapping, Protocol

from .api_planner import PROPOSAL_JSON_SCHEMA


RESPONSES_ENDPOINT = "https://api.openai.com/v1/responses"


class OpenAIClientError(RuntimeError):
    """A request could not be admitted or its response could not be trusted."""


@dataclass(frozen=True)
class HttpResponse:
    status_code: int
    headers: Mapping[str, str]
    body: bytes


class HttpTransport(Protocol):
    def post(
        self,
        url: str,
        *,
        headers: Mapping[str, str],
        body: bytes,
        timeout_seconds: int,
    ) -> HttpResponse: ...


class UrlLibHttpTransport:
    """Standard-library transport with no retry layer."""

    def post(
        self,
        url: str,
        *,
        headers: Mapping[str, str],
        body: bytes,
        timeout_seconds: int,
    ) -> HttpResponse:
        request = urllib.request.Request(
            url,
            data=body,
            headers=dict(headers),
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
                return HttpResponse(
                    int(response.status),
                    {str(key).lower(): str(value) for key, value in response.headers.items()},
                    response.read(),
                )
        except urllib.error.HTTPError as exc:
            return HttpResponse(
                int(exc.code),
                {str(key).lower(): str(value) for key, value in exc.headers.items()},
                exc.read(),
            )


@dataclass(frozen=True)
class OpenAIResponseMetadata:
    status_code: int | None
    request_id: str | None
    response_id: str | None
    model: str | None
    input_tokens: int | None
    output_tokens: int | None
    total_tokens: int | None

    def public_dict(self) -> dict[str, object]:
        return {
            "status_code": self.status_code,
            "request_id": self.request_id,
            "response_id": self.response_id,
            "model": self.model,
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "total_tokens": self.total_tokens,
        }


@dataclass(frozen=True)
class OpenAIProposalEnvelope:
    executed: bool
    proposal: Mapping[str, object] | None
    metadata: OpenAIResponseMetadata

    def public_dict(self) -> dict[str, object]:
        return {
            "executed": self.executed,
            "proposal_available": self.proposal is not None,
            "metadata": self.metadata.public_dict(),
        }


def _optional_count(value: object) -> int | None:
    return value if isinstance(value, int) and not isinstance(value, bool) and value >= 0 else None


def _response_text(value: Mapping[str, object]) -> str:
    output = value.get("output")
    if not isinstance(output, list):
        raise OpenAIClientError("response_output_invalid")
    texts: list[str] = []
    for item in output:
        if not isinstance(item, Mapping):
            raise OpenAIClientError("response_output_invalid")
        content = item.get("content")
        if not isinstance(content, list):
            raise OpenAIClientError("response_output_invalid")
        for part in content:
            if not isinstance(part, Mapping):
                raise OpenAIClientError("response_output_invalid")
            if part.get("type") == "refusal":
                raise OpenAIClientError("refusal")
            if part.get("type") == "output_text":
                text = part.get("text")
                if not isinstance(text, str):
                    raise OpenAIClientError("response_text_invalid")
                texts.append(text)
    if len(texts) != 1:
        raise OpenAIClientError("response_text_count_invalid")
    return texts[0]


class OpenAIResponsesClient:
    """Create at most one strict proposal; dry-run is the default."""

    def __init__(
        self,
        api_key: str | None,
        model: str | None,
        *,
        transport: HttpTransport | None = None,
        timeout_seconds: int = 60,
        max_input_chars: int = 16000,
        max_output_tokens: int = 4096,
    ) -> None:
        self._api_key = api_key
        self._model = model
        self._transport = transport or UrlLibHttpTransport()
        self._timeout_seconds = timeout_seconds
        self._max_input_chars = max_input_chars
        self._max_output_tokens = max_output_tokens
        self._request_used = False
        if timeout_seconds < 1 or max_input_chars < 1 or max_output_tokens < 1:
            raise OpenAIClientError("request_bounds_invalid")

    @classmethod
    def from_environment(
        cls,
        environment: Mapping[str, str],
        *,
        transport: HttpTransport | None = None,
        timeout_seconds: int = 60,
        max_input_chars: int = 16000,
        max_output_tokens: int = 4096,
    ) -> "OpenAIResponsesClient":
        api_key = environment.get("OPENAI_API_KEY")
        model = environment.get("OPENAI_MODEL")
        if not api_key:
            raise OpenAIClientError("credentials_missing:OPENAI_API_KEY")
        if not model:
            raise OpenAIClientError("credentials_missing:OPENAI_MODEL")
        return cls(
            api_key,
            model,
            transport=transport,
            timeout_seconds=timeout_seconds,
            max_input_chars=max_input_chars,
            max_output_tokens=max_output_tokens,
        )

    def request_proposal(
        self,
        prompt: str,
        *,
        execute: bool = False,
    ) -> OpenAIProposalEnvelope:
        if not isinstance(prompt, str) or not prompt or "\x00" in prompt:
            raise OpenAIClientError("prompt_invalid")
        if len(prompt) > self._max_input_chars:
            raise OpenAIClientError("prompt_too_large")
        if not execute:
            return OpenAIProposalEnvelope(
                executed=False,
                proposal=None,
                metadata=OpenAIResponseMetadata(
                    None, None, None, self._model, None, None, None
                ),
            )
        if self._request_used:
            raise OpenAIClientError("duplicate_api_request")
        if not self._api_key:
            raise OpenAIClientError("credentials_missing:OPENAI_API_KEY")
        if not self._model:
            raise OpenAIClientError("credentials_missing:OPENAI_MODEL")
        self._request_used = True
        payload = {
            "model": self._model,
            "input": prompt,
            "store": False,
            "max_output_tokens": self._max_output_tokens,
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "cse_orchestrator_proposal",
                    "schema": PROPOSAL_JSON_SCHEMA,
                    "strict": True,
                }
            },
        }
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }
        try:
            response = self._transport.post(
                RESPONSES_ENDPOINT,
                headers=headers,
                body=json.dumps(payload, separators=(",", ":")).encode("utf-8"),
                timeout_seconds=self._timeout_seconds,
            )
        except (TimeoutError, socket.timeout, urllib.error.URLError) as exc:
            raise OpenAIClientError("api_timeout") from exc
        except OSError as exc:
            raise OpenAIClientError("api_transport_error") from exc
        if response.status_code == 429:
            raise OpenAIClientError("rate_limited")
        if response.status_code < 200 or response.status_code >= 300:
            raise OpenAIClientError(f"api_error:{response.status_code}")
        try:
            value = json.loads(response.body)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise OpenAIClientError("response_json_invalid") from exc
        if not isinstance(value, dict):
            raise OpenAIClientError("response_object_required")
        if value.get("status") != "completed":
            raise OpenAIClientError("incomplete_response")
        text = _response_text(value)
        try:
            proposal = json.loads(text)
        except json.JSONDecodeError as exc:
            raise OpenAIClientError("proposal_json_invalid") from exc
        if not isinstance(proposal, dict):
            raise OpenAIClientError("proposal_object_required")
        usage = value.get("usage") if isinstance(value.get("usage"), Mapping) else {}
        normalized_headers = {str(key).lower(): str(item) for key, item in response.headers.items()}
        metadata = OpenAIResponseMetadata(
            response.status_code,
            normalized_headers.get("x-request-id"),
            value.get("id") if isinstance(value.get("id"), str) else None,
            value.get("model") if isinstance(value.get("model"), str) else self._model,
            _optional_count(usage.get("input_tokens")),
            _optional_count(usage.get("output_tokens")),
            _optional_count(usage.get("total_tokens")),
        )
        return OpenAIProposalEnvelope(True, proposal, metadata)
