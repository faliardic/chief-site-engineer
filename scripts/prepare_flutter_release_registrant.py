"""Remove the dev-only integration_test plugin from an ignored registrant."""

from __future__ import annotations

import re
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
REGISTRANT = (
    REPOSITORY_ROOT
    / "mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
)
INTEGRATION_BLOCK = re.compile(
    r"\n    try \{\n"
    r"      flutterEngine\.getPlugins\(\)\.add\(new "
    r"dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);\n"
    r"    \} catch \(Exception e\) \{\n"
    r"      Log\.e\(TAG, \"Error registering plugin integration_test, "
    r"dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\", e\);\n"
    r"    \}"
)
REQUIRED_PRODUCTION_PLUGINS = {
    "FilePickerPlugin",
    "FlutterLocalNotificationsPlugin",
    "ImagePickerPlugin",
    "PermissionHandlerPlugin",
    "SharePlusPlugin",
    "SqflitePlugin",
}


def prepare(registrant: Path = REGISTRANT) -> None:
    if not registrant.is_file():
        raise RuntimeError("Flutter generated plugin registrant was not produced")
    source = registrant.read_text(encoding="utf-8")
    missing = sorted(
        plugin for plugin in REQUIRED_PRODUCTION_PLUGINS if plugin not in source
    )
    if missing:
        raise RuntimeError(f"production plugin registration missing: {missing}")
    sanitized, replacements = INTEGRATION_BLOCK.subn("", source)
    if replacements not in {0, 1}:
        raise RuntimeError("unexpected integration_test registrant shape")
    if "integration_test" in sanitized or "IntegrationTestPlugin" in sanitized:
        raise RuntimeError("dev-only integration_test registration remains")
    registrant.write_text(sanitized, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    prepare()
