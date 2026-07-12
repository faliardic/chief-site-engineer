import json
import os
import socket
import subprocess
import sys
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest
from werkzeug.serving import make_server

from app.application import ObservationApplicationService
from app.launcher import (
    APPLICATION_ID,
    LauncherError,
    find_existing_instance,
    launch,
    resolve_default_paths,
)
from app.storage import ManagedAttachmentStore
from app.web import create_app


REPOSITORY_ROOT = Path(__file__).parents[1]


def free_port() -> int:
    with socket.socket() as candidate:
        candidate.bind(("127.0.0.1", 0))
        return candidate.getsockname()[1]


def wait_for_health(port: int, timeout: float = 5.0) -> dict[str, object]:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(
                f"http://127.0.0.1:{port}/health", timeout=0.2
            ) as response:
                return json.load(response)
        except OSError:
            time.sleep(0.05)
    raise AssertionError("health endpoint did not become ready")


def test_default_data_and_log_roots_use_local_appdata(tmp_path: Path) -> None:
    paths = resolve_default_paths({"LOCALAPPDATA": str(tmp_path)})

    assert paths.data_root == tmp_path / "ChiefSiteEngineer" / "data"
    assert paths.logs_root == tmp_path / "ChiefSiteEngineer" / "logs"
    assert REPOSITORY_ROOT not in paths.data_root.parents
    assert REPOSITORY_ROOT not in paths.logs_root.parents


def test_missing_local_appdata_and_file_data_root_have_clear_errors(
    tmp_path: Path,
) -> None:
    with pytest.raises(LauncherError, match="LOCALAPPDATA"):
        resolve_default_paths({})

    not_a_directory = tmp_path / "data-file"
    not_a_directory.write_text("not a directory", encoding="utf-8")
    with pytest.raises(LauncherError, match="klasör değil"):
        launch(not_a_directory, tmp_path / "logs", open_browser=False)


def test_health_endpoint_is_minimal_identity_and_readiness(tmp_path: Path) -> None:
    response = create_app(tmp_path / "data").test_client().get("/health")

    assert response.status_code == 200
    assert response.get_json() == {
        "application": APPLICATION_ID,
        "ready": True,
        "version": "0.2",
    }
    assert str(tmp_path).encode() not in response.data


def test_double_click_command_checks_python_dependencies_and_starts_launcher() -> None:
    command = (REPOSITORY_ROOT / "CSE_Baslat.cmd").read_text(encoding="utf-8")

    assert "where python" in command.lower()
    assert 'python -c "import flask, werkzeug"' in command
    assert "python -m app.launcher %*" in command
    assert "pause" in command.lower()


def test_existing_cse_instance_opens_browser_without_new_server(tmp_path: Path) -> None:
    port = free_port()
    server = make_server("127.0.0.1", port, create_app(tmp_path / "data"))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    opened: list[str] = []

    try:
        assert find_existing_instance([port]) == f"http://127.0.0.1:{port}"
        result = launch(
            tmp_path / "data",
            tmp_path / "logs",
            preferred_port=port,
            port_count=1,
            browser_open=lambda url: opened.append(url) or True,
            server_factory=lambda *_: pytest.fail("second server must not start"),
            block=False,
        )
    finally:
        server.shutdown()
        thread.join(timeout=2)

    assert result.already_running is True
    assert result.server is None
    assert opened == [f"http://127.0.0.1:{port}"]


class ForeignHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        body = b'{"application":"not-cse","ready":true}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args: object) -> None:
        return


def test_foreign_service_is_not_cse_and_next_port_starts_after_ready(
    tmp_path: Path,
) -> None:
    occupied_port = free_port()
    next_port = free_port()
    foreign = ThreadingHTTPServer(("127.0.0.1", occupied_port), ForeignHandler)
    foreign_thread = threading.Thread(target=foreign.serve_forever, daemon=True)
    foreign_thread.start()
    opened: list[str] = []
    health_at_browser_open: list[dict[str, object]] = []

    def open_after_ready(url: str) -> bool:
        opened.append(url)
        health_at_browser_open.append(wait_for_health(next_port))
        return True

    try:
        assert find_existing_instance([occupied_port]) is None
        result = launch(
            tmp_path / "data",
            tmp_path / "logs",
            candidate_ports=[occupied_port, next_port],
            browser_open=open_after_ready,
            block=False,
        )
        assert wait_for_health(next_port)["ready"] is True
    finally:
        foreign.shutdown()
        foreign_thread.join(timeout=2)
        if "result" in locals():
            result.shutdown()

    assert result.port == next_port
    assert opened == [f"http://127.0.0.1:{next_port}"]
    assert health_at_browser_open == [
        {"application": APPLICATION_ID, "ready": True, "version": "0.2"}
    ]


def test_browser_failure_keeps_server_and_writes_clear_log(tmp_path: Path) -> None:
    port = free_port()
    result = launch(
        tmp_path / "data",
        tmp_path / "logs",
        preferred_port=port,
        port_count=1,
        browser_open=lambda _url: False,
        block=False,
    )
    try:
        assert wait_for_health(port)["application"] == APPLICATION_ID
        assert result.browser_opened is False
        log = (tmp_path / "logs" / "launcher.log").read_text(encoding="utf-8")
        assert "Tarayıcı otomatik açılamadı" in log
    finally:
        result.shutdown()


def test_startup_timeout_is_controlled_and_logged(tmp_path: Path) -> None:
    class NonStartingServer:
        def serve_forever(self) -> None:
            return

        def shutdown(self) -> None:
            return

        def server_close(self) -> None:
            return

    with pytest.raises(LauncherError, match="hazır olmadı"):
        launch(
            tmp_path / "data",
            tmp_path / "logs",
            preferred_port=free_port(),
            port_count=1,
            startup_timeout=0.1,
            server_factory=lambda *_: NonStartingServer(),
            open_browser=False,
            block=False,
        )

    log = (tmp_path / "logs" / "launcher.log").read_text(encoding="utf-8")
    assert "hazır olmadı" in log


def test_same_default_data_root_persists_across_new_app_instance(tmp_path: Path) -> None:
    paths = resolve_default_paths({"LOCALAPPDATA": str(tmp_path)})
    service = ObservationApplicationService(
        paths.data_root / "cse.sqlite3",
        ManagedAttachmentStore(paths.data_root / "attachments"),
    )
    project = service.create_project("Kalıcı Proje")

    reopened = create_app(paths.data_root)
    projects = reopened.config["CSE_SERVICE"].list_projects()

    assert projects == [project]
    assert not (REPOSITORY_ROOT / "cse.sqlite3").exists()


@pytest.mark.skipif(os.name != "nt", reason="Windows launcher smoke test")
def test_real_subprocess_starts_localhost_and_second_launch_reuses_it(
    tmp_path: Path,
) -> None:
    port = free_port()
    data_root = tmp_path / "data"
    logs_root = tmp_path / "logs"
    command = [
        sys.executable,
        "-m",
        "app.launcher",
        "--data-root",
        str(data_root),
        "--logs-root",
        str(logs_root),
        "--port",
        str(port),
        "--port-count",
        "1",
        "--no-browser",
    ]
    first = subprocess.Popen(
        command,
        cwd=REPOSITORY_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    try:
        health = wait_for_health(port)
        second = subprocess.run(
            command,
            cwd=REPOSITORY_ROOT,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        assert second.returncode == 0, second.stderr
        assert "zaten çalışıyor" in second.stdout
    finally:
        first.terminate()
        first.wait(timeout=10)

    assert health == {
        "application": APPLICATION_ID,
        "ready": True,
        "version": "0.2",
    }
    assert data_root.is_dir() and logs_root.is_dir()
    assert REPOSITORY_ROOT not in data_root.parents
