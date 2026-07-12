"""Small deterministic file helpers shared by local operations."""

import hashlib
import json
import os
import stat
import zipfile
from pathlib import Path, PurePosixPath
from typing import BinaryIO


ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)


def canonical_json_bytes(value: object) -> bytes:
    return (
        json.dumps(
            value,
            ensure_ascii=False,
            allow_nan=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def digest_bytes(data: bytes) -> dict[str, object]:
    return {"sha256": hashlib.sha256(data).hexdigest(), "size_bytes": len(data)}


def digest_file(path: Path, chunk_size: int = 1024 * 1024) -> dict[str, object]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as file_handle:
        while chunk := file_handle.read(chunk_size):
            digest.update(chunk)
            size += len(chunk)
    return {"sha256": digest.hexdigest(), "size_bytes": size}


def digest_stream(file_handle: BinaryIO, chunk_size: int = 1024 * 1024) -> dict[str, object]:
    digest = hashlib.sha256()
    size = 0
    while chunk := file_handle.read(chunk_size):
        digest.update(chunk)
        size += len(chunk)
    return {"sha256": digest.hexdigest(), "size_bytes": size}


def deterministic_zip_info(name: str) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, ZIP_TIMESTAMP)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | 0o600) << 16
    return info


def write_zip_bytes(bundle: zipfile.ZipFile, name: str, data: bytes) -> None:
    bundle.writestr(deterministic_zip_info(name), data)


def validate_safe_archive_name(name: str) -> PurePosixPath:
    if not isinstance(name, str) or not name or "\\" in name:
        raise ValueError("archive entry must use a non-empty POSIX path")
    if name.startswith("/") or ":" in name.split("/", 1)[0]:
        raise ValueError("archive entry cannot be absolute")
    parts = name.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        raise ValueError("archive entry contains an unsafe segment")
    return PurePosixPath(name)


def zip_info_is_symlink(info: zipfile.ZipInfo) -> bool:
    return stat.S_ISLNK((info.external_attr >> 16) & 0o177777)


def exclusive_output_path(path: str | Path) -> Path:
    output = Path(path).resolve()
    if output.exists():
        raise FileExistsError(f"output already exists: {output.name}")
    output.parent.mkdir(parents=True, exist_ok=True)
    return output


def cleanup_file(path: Path) -> None:
    try:
        path.unlink(missing_ok=True)
    except OSError:
        pass


def atomic_rename(source: Path, destination: Path) -> None:
    os.rename(source, destination)
