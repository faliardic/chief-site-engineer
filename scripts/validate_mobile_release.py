"""Fail-closed static and artifact gates for the CSE 0.1 mobile release."""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import struct
import subprocess
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree


ANDROID_NAMESPACE = "{http://schemas.android.com/apk/res/android}"
TOOLS_NAMESPACE = "{http://schemas.android.com/tools}"
ANDROID_PERMISSION_ALLOWLIST = {
    "android.permission.CAMERA",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.SCHEDULE_EXACT_ALARM",
}
FORBIDDEN_PRODUCTION_PERMISSIONS = {
    "android.permission.INTERNET",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.READ_MEDIA_VIDEO",
    "android.permission.READ_MEDIA_AUDIO",
    "android.permission.USE_EXACT_ALARM",
    "android.permission.FOREGROUND_SERVICE",
}
REQUIRED_TRANSITIVE_PERMISSION_REMOVALS = {
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.READ_MEDIA_VIDEO",
    "android.permission.READ_MEDIA_AUDIO",
}
FORBIDDEN_TRACKED_SECRET_SUFFIXES = {
    ".jks",
    ".keystore",
    ".p12",
    ".p8",
    ".mobileprovision",
}
FORBIDDEN_DIRECT_PACKAGES = {
    "firebase_analytics",
    "firebase_core",
    "firebase_crashlytics",
    "sentry_flutter",
    "amplitude_flutter",
    "appsflyer_sdk",
    "facebook_app_events",
    "google_mobile_ads",
    "mixpanel_flutter",
}


class GateFailure(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise GateFailure(message)


def _permissions(manifest: Path) -> tuple[set[str], ElementTree.Element]:
    root = ElementTree.parse(manifest).getroot()
    permissions = {
        item.attrib[f"{ANDROID_NAMESPACE}name"]
        for item in root.findall("uses-permission")
        if item.attrib.get(f"{TOOLS_NAMESPACE}node") != "remove"
    }
    return permissions, root


def _png_header(path: Path) -> tuple[int, int, int]:
    data = path.read_bytes()
    require(data.startswith(b"\x89PNG\r\n\x1a\n"), f"not a PNG: {path}")
    require(data[12:16] == b"IHDR", f"PNG has no IHDR: {path}")
    width, height, _, color_type = struct.unpack(">IIBB", data[16:26])
    return width, height, color_type


def _direct_pub_dependencies(pubspec: Path) -> set[str]:
    dependencies: set[str] = set()
    in_dependencies = False
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if line == "dependencies:":
            in_dependencies = True
            continue
        if in_dependencies and line and not line.startswith(" "):
            break
        match = re.match(r"^  ([a-zA-Z0-9_]+):", line)
        if in_dependencies and match:
            dependencies.add(match.group(1))
    return dependencies


def validate_static(repository: Path) -> list[str]:
    mobile = repository / "mobile"
    manifest = mobile / "android/app/src/main/AndroidManifest.xml"
    permissions, manifest_root = _permissions(manifest)
    removed_permissions = {
        item.attrib[f"{ANDROID_NAMESPACE}name"]
        for item in manifest_root.findall("uses-permission")
        if item.attrib.get(f"{TOOLS_NAMESPACE}node") == "remove"
    }
    require(
        permissions == ANDROID_PERMISSION_ALLOWLIST,
        f"main manifest permission allowlist mismatch: {sorted(permissions)}",
    )
    require(
        not permissions.intersection(FORBIDDEN_PRODUCTION_PERMISSIONS),
        "main manifest contains a forbidden production permission",
    )
    require(
        REQUIRED_TRANSITIVE_PERMISSION_REMOVALS <= removed_permissions,
        "main manifest does not remove every transitive broad media permission",
    )
    application = manifest_root.find("application")
    require(application is not None, "Android application element is missing")
    require(
        application.attrib.get(f"{ANDROID_NAMESPACE}allowBackup") == "false",
        "android:allowBackup must be false",
    )
    require(
        application.attrib.get(f"{ANDROID_NAMESPACE}usesCleartextTraffic")
        == "false",
        "cleartext traffic must be disabled",
    )

    gradle = (mobile / "android/app/build.gradle.kts").read_text(
        encoding="utf-8"
    )
    for contract in [
        'compileSdk = 36',
        'targetSdk = 36',
        'ndkVersion = "28.2.13676358"',
        'applicationId = "com.faliardic.chiefsiteengineer"',
        'applicationIdSuffix = ".debug"',
        'JavaVersion.VERSION_17',
        'CSE_KEY_PROPERTIES_FILE',
        'CSE_REQUIRE_SIGNING',
        'signingConfig = if (hasCompleteReleaseSigning)',
    ]:
        require(contract in gradle, f"Android Gradle contract missing: {contract}")
    notification_source = (mobile / "lib/platform/notification_gateway.dart").read_text(
        encoding="utf-8"
    )
    require(
        "AndroidScheduleMode.inexactAllowWhileIdle" in notification_source,
        "denied exact access must retain an explicit inexact fallback",
    )
    require(
        "AndroidScheduleMode.exactAllowWhileIdle" in notification_source,
        "user-scheduled reminders must use exact allow-while-idle delivery",
    )
    require(
        "startForegroundService" not in notification_source,
        "foreground reminder delivery is forbidden",
    )

    privacy_path = mobile / "ios/Runner/PrivacyInfo.xcprivacy"
    with privacy_path.open("rb") as stream:
        privacy = plistlib.load(stream)
    require(privacy.get("NSPrivacyTracking") is False, "iOS tracking must be false")
    require(
        privacy.get("NSPrivacyCollectedDataTypes") == [],
        "app privacy manifest must declare no developer collection",
    )
    require(
        privacy.get("NSPrivacyTrackingDomains") == [],
        "tracking domains must be empty",
    )
    project = (mobile / "ios/Runner.xcodeproj/project.pbxproj").read_text(
        encoding="utf-8"
    )
    require(
        "PrivacyInfo.xcprivacy in Resources" in project,
        "PrivacyInfo.xcprivacy is not in Runner resources",
    )
    require(
        'TARGETED_DEVICE_FAMILY = "1,2"' not in project
        and project.count("TARGETED_DEVICE_FAMILY = 1;") == 3,
        "first release must be iPhone-only",
    )
    require(
        "com.faliardic.chiefsiteengineer.debug" in project
        and "com.faliardic.chiefsiteengineer;" in project,
        "iOS debug and production bundle identifiers are not distinct",
    )

    app_icon = mobile / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((app_icon / "Contents.json").read_text(encoding="utf-8"))
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        scale = int(item["scale"].removesuffix("x"))
        expected = round(float(item["size"].split("x", maxsplit=1)[0]) * scale)
        width, height, color_type = _png_header(app_icon / filename)
        require((width, height) == (expected, expected), f"wrong icon size: {filename}")
        require(color_type == 2, f"iOS AppIcon must not contain alpha: {filename}")
    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        for name in ["ic_launcher.png", "ic_launcher_round.png"]:
            icon = mobile / f"android/app/src/main/res/mipmap-{density}/{name}"
            width, height, _ = _png_header(icon)
            require((width, height) == (size, size), f"wrong Android icon size: {icon}")
    require(
        (mobile / "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml").is_file(),
        "Android adaptive icon is missing",
    )

    direct_dependencies = _direct_pub_dependencies(mobile / "pubspec.yaml")
    require(
        not direct_dependencies.intersection(FORBIDDEN_DIRECT_PACKAGES),
        "analytics, ads or telemetry dependency detected",
    )
    source_text = "\n".join(
        file.read_text(encoding="utf-8")
        for file in sorted((mobile / "lib").rglob("*.dart"))
    )
    require(
        re.search(r"https?://", source_text) is None,
        "off-device network endpoint detected in mobile runtime",
    )

    tracked = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=repository,
        check=True,
        capture_output=True,
    ).stdout.decode("utf-8").split("\0")
    for relative in filter(None, tracked):
        candidate = Path(relative)
        require(
            candidate.name != "key.properties"
            and candidate.suffix.lower() not in FORBIDDEN_TRACKED_SECRET_SUFFIXES,
            f"tracked signing secret candidate: {relative}",
        )

    required_store_docs = [
        "docs/privacy/privacy_policy_tr.md",
        "docs/privacy/privacy_policy_en.md",
        "docs/privacy/privacy_policy.html",
        "docs/privacy/google_play_data_safety.md",
        "docs/privacy/apple_app_privacy.md",
        "docs/privacy/permission_purpose_matrix.md",
        "docs/privacy/third_party_sdk_inventory.md",
        "docs/release/mobile_identity_signing_and_rc.md",
        "docs/release/mobile_rc_field_acceptance_checklist.md",
    ]
    for relative in required_store_docs:
        require((repository / relative).is_file(), f"release evidence missing: {relative}")

    return [
        "Android source permission and API 36 contract",
        "external-only release signing contract",
        "iOS privacy manifest and iPhone target contract",
        "launcher/splash dimensions and iOS no-alpha contract",
        "no analytics/ads/runtime network endpoint audit",
        "tracked signing-secret absence",
        "privacy and release declaration evidence",
    ]


def validate_plugin_privacy_inventory(repository: Path) -> str:
    inventory_path = repository / "mobile/.flutter-plugins-dependencies"
    require(inventory_path.is_file(), "Flutter plugin inventory was not generated")
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    ios_plugins = {
        item["name"]: Path(item["path"])
        for item in inventory["plugins"]["ios"]
    }
    required_manifests = {
        "file_picker",
        "flutter_local_notifications",
        "image_picker_ios",
        "permission_handler_apple",
        "share_plus",
        "sqflite_darwin",
    }
    require(
        required_manifests.issubset(ios_plugins),
        "locked iOS plugin inventory is incomplete",
    )
    for name in sorted(required_manifests):
        manifests = list(ios_plugins[name].rglob("PrivacyInfo.xcprivacy"))
        require(manifests, f"iOS plugin privacy manifest missing: {name}")
        ios_manifests = [
            item
            for item in manifests
            if "ios" in {part.lower() for part in item.parts}
            or "darwin" in {part.lower() for part in item.parts}
        ]
        require(ios_manifests, f"iOS privacy manifest path missing: {name}")
        with ios_manifests[0].open("rb") as stream:
            privacy = plistlib.load(stream)
        require(privacy.get("NSPrivacyTracking") is False, f"tracking in {name}")
        require(
            privacy.get("NSPrivacyCollectedDataTypes") == [],
            f"unexpected collection declaration in {name}",
        )
    require(
        "path_provider_foundation" in ios_plugins,
        "path_provider_foundation lock entry is missing",
    )
    return "locked iOS plugin privacy manifest inventory"


def validate_merged_manifest(manifest: Path) -> str:
    permissions, root = _permissions(manifest)
    package_name = root.attrib.get("package", "com.faliardic.chiefsiteengineer")
    private_receiver_permission = (
        f"{package_name}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
    )
    require(
        permissions
        == ANDROID_PERMISSION_ALLOWLIST | {private_receiver_permission},
        f"merged release permission allowlist mismatch: {sorted(permissions)}",
    )
    require(
        not permissions.intersection(FORBIDDEN_PRODUCTION_PERMISSIONS),
        "merged release manifest contains forbidden permissions",
    )
    application = root.find("application")
    require(application is not None, "merged application element is missing")
    require(
        application.attrib.get(f"{ANDROID_NAMESPACE}allowBackup") == "false",
        "merged release enables OS backup",
    )
    require(
        application.attrib.get(f"{ANDROID_NAMESPACE}usesCleartextTraffic")
        == "false",
        "merged release enables cleartext traffic",
    )
    private_declaration = next(
        (
            item
            for item in root.findall("permission")
            if item.attrib.get(f"{ANDROID_NAMESPACE}name")
            == private_receiver_permission
        ),
        None,
    )
    require(
        private_declaration is not None
        and private_declaration.attrib.get(f"{ANDROID_NAMESPACE}protectionLevel")
        == "signature",
        "AndroidX private receiver permission is not signature protected",
    )
    return "merged release manifest permission/network/backup allowlist"


def validate_native_artifact(artifact: Path, *, aab: bool) -> str:
    with zipfile.ZipFile(artifact) as archive:
        names = archive.namelist()
    prefix = "base/lib/arm64-v8a/" if aab else "lib/arm64-v8a/"
    arm64 = [name for name in names if name.startswith(prefix) and name.endswith(".so")]
    require(arm64, f"ARM64 native libraries missing from {artifact.name}")
    require(
        any(name.endswith("libflutter.so") for name in arm64),
        f"ARM64 Flutter engine missing from {artifact.name}",
    )
    return f"{artifact.name} ARM64 native library inventory"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repository-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
    )
    parser.add_argument("--merged-manifest", type=Path)
    parser.add_argument("--aab", type=Path)
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--require-plugin-privacy-inventory", action="store_true")
    arguments = parser.parse_args(argv)
    try:
        results = validate_static(arguments.repository_root.resolve())
        if arguments.require_plugin_privacy_inventory:
            results.append(
                validate_plugin_privacy_inventory(arguments.repository_root.resolve())
            )
        if arguments.merged_manifest:
            results.append(validate_merged_manifest(arguments.merged_manifest.resolve()))
        if arguments.aab:
            results.append(validate_native_artifact(arguments.aab.resolve(), aab=True))
        if arguments.apk:
            results.append(validate_native_artifact(arguments.apk.resolve(), aab=False))
    except (GateFailure, OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"MOBILE RELEASE GATE FAILED: {error}", file=sys.stderr)
        return 1
    for result in results:
        print(f"PASS: {result}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
