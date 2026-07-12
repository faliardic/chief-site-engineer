from pathlib import Path

import pytest

from app.web.__main__ import parse_args


def test_launcher_defaults_to_loopback_and_requires_network_opt_in(tmp_path: Path) -> None:
    args = parse_args(["--data-root", str(tmp_path)])
    assert args.host == "127.0.0.1"
    assert args.port == 5000

    with pytest.raises(SystemExit):
        parse_args(["--data-root", str(tmp_path), "--host", "0.0.0.0"])

    allowed = parse_args(
        ["--data-root", str(tmp_path), "--host", "0.0.0.0", "--allow-network"]
    )
    assert allowed.host == "0.0.0.0"
