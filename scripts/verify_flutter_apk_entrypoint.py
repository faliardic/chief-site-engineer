from __future__ import annotations

import argparse
import zipfile
from pathlib import Path


KERNEL_BLOB = "assets/flutter_assets/kernel_blob.bin"


def verify_entrypoint(
    apk: Path,
    *,
    expected_marker: str,
    forbidden_markers: tuple[str, ...] = (),
) -> None:
    if not apk.is_file():
        raise ValueError("APK was not produced")
    try:
        with zipfile.ZipFile(apk) as archive:
            kernel = archive.read(KERNEL_BLOB)
    except (KeyError, zipfile.BadZipFile) as error:
        raise ValueError("APK does not contain a readable Flutter kernel blob") from error

    expected = expected_marker.encode("utf-8")
    if expected not in kernel:
        raise ValueError("expected Flutter entrypoint marker is missing")
    for marker in forbidden_markers:
        if marker.encode("utf-8") in kernel:
            raise ValueError("forbidden Flutter entrypoint marker is present")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fail closed unless a debug APK contains the expected Dart entrypoint."
    )
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--expected-marker", required=True)
    parser.add_argument("--forbidden-marker", action="append", default=[])
    arguments = parser.parse_args()
    try:
        verify_entrypoint(
            arguments.apk,
            expected_marker=arguments.expected_marker,
            forbidden_markers=tuple(arguments.forbidden_marker),
        )
    except ValueError as error:
        parser.error(str(error))
    print(
        "PASS: Flutter APK entrypoint marker "
        f"{arguments.expected_marker} ({arguments.apk.name})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
