from __future__ import annotations

import copy
import io
import json
import unittest
import urllib.error
from pathlib import Path

from tools import cse_api_bridge
from tools.cse_bridge_entrypoint import (
    normalize_strict_function_schemas,
    openai_error_reason,
)


class StrictToolSchemaTests(unittest.TestCase):
    def test_every_strict_function_requires_every_property(self) -> None:
        tools = copy.deepcopy(cse_api_bridge.TOOLS)
        normalize_strict_function_schemas(tools)
        for tool in tools:
            if tool.get("type") != "function" or tool.get("strict") is not True:
                continue
            parameters = tool["parameters"]
            self.assertEqual(
                parameters["required"],
                list(parameters["properties"].keys()),
            )
            self.assertIs(parameters["additionalProperties"], False)

    def test_zero_argument_tool_has_explicit_empty_required(self) -> None:
        tools = copy.deepcopy(cse_api_bridge.TOOLS)
        normalize_strict_function_schemas(tools)
        target = next(tool for tool in tools if tool["name"] == "list_changed_paths")
        self.assertEqual(target["parameters"]["properties"], {})
        self.assertEqual(target["parameters"]["required"], [])


class OpenAIErrorReasonTests(unittest.TestCase):
    def error(self, payload: object) -> urllib.error.HTTPError:
        return urllib.error.HTTPError(
            "https://api.openai.com/v1/responses",
            400,
            "Bad Request",
            {},
            io.BytesIO(json.dumps(payload).encode("utf-8")),
        )

    def test_only_safe_structured_fields_are_retained(self) -> None:
        reason = openai_error_reason(
            self.error(
                {
                    "error": {
                        "message": "secret sk-abcdefghijklmnopqrstuvwxyz",
                        "type": "invalid_request_error",
                        "code": "invalid_function_parameters",
                        "param": "tools[4].parameters",
                    }
                }
            )
        )
        self.assertEqual(
            reason,
            "openai_http_400__invalid_request_error__invalid_function_parameters__tools_4_.parameters",
        )
        self.assertNotIn("secret", reason)
        self.assertNotIn("sk-", reason)

    def test_malformed_body_falls_back_to_http_status(self) -> None:
        error = urllib.error.HTTPError(
            "https://api.openai.com/v1/responses",
            400,
            "Bad Request",
            {},
            io.BytesIO(b"not-json"),
        )
        self.assertEqual(openai_error_reason(error), "openai_http_400")


class LauncherContractTests(unittest.TestCase):
    def test_launcher_uses_compatibility_entrypoint(self) -> None:
        launcher = Path("scripts/run_cse_bridge.ps1").read_text(encoding="utf-8")
        self.assertIn("-m tools.cse_bridge_entrypoint", launcher)
        self.assertNotIn("-m tools.cse_bridge_local", launcher)


if __name__ == "__main__":
    unittest.main()
