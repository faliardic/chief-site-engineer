"""Public identity contract shared by the web app and Windows launcher."""

import hashlib
import os
from pathlib import Path


APPLICATION_ID = "chief-site-engineer"
APPLICATION_VERSION = "0.2"
LOOPBACK_HOST = "127.0.0.1"


def instance_id_for_data_root(data_root: str | Path) -> str:
    """Return a stable opaque identity for one canonical data root."""

    resolved = Path(data_root).resolve()
    canonical = os.path.normcase(os.path.normpath(os.fspath(resolved)))
    payload = f"{APPLICATION_ID}:data-root:v1\0{canonical}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()
