"""Loopback-only Windows launcher with existing-instance detection."""

import json
import logging
import os
import socket
import threading
import time
import urllib.error
import urllib.request
import webbrowser
from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

from flask import Flask
from werkzeug.serving import BaseWSGIServer, WSGIRequestHandler, make_server

from app.web import create_app

from .contracts import APPLICATION_ID, LOOPBACK_HOST, instance_id_for_data_root


DEFAULT_PORT = 5000
DEFAULT_PORT_COUNT = 11
DEFAULT_STARTUP_TIMEOUT = 10.0


class LauncherError(Exception):
    """A launcher failure that can be shown without a traceback."""


class ServerLike(Protocol):
    def serve_forever(self) -> None: ...

    def shutdown(self) -> None: ...

    def server_close(self) -> None: ...


@dataclass(frozen=True)
class LauncherPaths:
    data_root: Path
    logs_root: Path


@dataclass
class LaunchResult:
    url: str
    port: int
    already_running: bool
    browser_opened: bool
    server: ServerLike | None = None
    thread: threading.Thread | None = None

    def shutdown(self) -> None:
        if self.server is None:
            return
        self.server.shutdown()
        self.server.server_close()
        if self.thread is not None:
            self.thread.join(timeout=3)

    def wait(self) -> None:
        if self.thread is not None:
            self.thread.join()


def resolve_default_paths(environment: Mapping[str, str] | None = None) -> LauncherPaths:
    values = os.environ if environment is None else environment
    local_appdata = values.get("LOCALAPPDATA")
    if not local_appdata:
        raise LauncherError("LOCALAPPDATA bulunamadı; veri klasörü belirlenemedi.")
    application_root = Path(local_appdata).resolve() / "ChiefSiteEngineer"
    return LauncherPaths(
        data_root=application_root / "data",
        logs_root=application_root / "logs",
    )


def find_existing_instance(
    ports: Iterable[int], expected_instance_id: str
) -> str | None:
    for port in ports:
        if _is_cse_ready(port, expected_instance_id):
            return _url(port)
    return None


def launch(
    data_root: str | Path,
    logs_root: str | Path,
    *,
    preferred_port: int = DEFAULT_PORT,
    port_count: int = DEFAULT_PORT_COUNT,
    candidate_ports: Iterable[int] | None = None,
    startup_timeout: float = DEFAULT_STARTUP_TIMEOUT,
    browser_open: Callable[[str], bool] = lambda url: webbrowser.open(url, new=2),
    server_factory: Callable[[str, int, Flask], ServerLike] | None = None,
    open_browser: bool = True,
    block: bool = False,
) -> LaunchResult:
    data = _ensure_directory(data_root, "Veri")
    logs = _ensure_directory(logs_root, "Log")
    logger = _configure_logger(logs / "launcher.log")
    expected_instance_id = instance_id_for_data_root(data)
    ports = list(
        candidate_ports
        if candidate_ports is not None
        else range(preferred_port, preferred_port + port_count)
    )
    if not ports or any(port < 1 or port > 65535 for port in ports):
        raise LauncherError("Port aralığı geçersiz.")

    existing_url = find_existing_instance(ports, expected_instance_id)
    if existing_url is not None:
        browser_opened = _open_browser(
            existing_url, browser_open, open_browser, logger
        )
        logger.info("Çalışan CSE instance yeniden kullanıldı: %s", existing_url)
        return LaunchResult(
            url=existing_url,
            port=int(existing_url.rsplit(":", 1)[1]),
            already_running=True,
            browser_opened=browser_opened,
        )

    factory = server_factory or _make_server
    try:
        application = create_app(data)
    except Exception as exc:
        logger.error("CSE veri alanı açılamadı: %s", exc.__class__.__name__)
        raise LauncherError("CSE veri alanı açılamadı.") from exc
    server: ServerLike | None = None
    selected_port: int | None = None
    for port in ports:
        if not _port_is_available(port):
            logger.info("Port %s başka bir uygulama tarafından kullanılıyor.", port)
            continue
        try:
            server = factory(LOOPBACK_HOST, port, application)
        except OSError:
            logger.info("Port %s başlatma sırasında kullanılamadı.", port)
            continue
        selected_port = port
        break
    if server is None or selected_port is None:
        message = "Kullanılabilir localhost portu bulunamadı."
        logger.error(message)
        raise LauncherError(message)

    thread = threading.Thread(
        target=server.serve_forever,
        name="cse-local-server",
        daemon=True,
    )
    thread.start()
    url = _url(selected_port)
    deadline = time.monotonic() + startup_timeout
    while time.monotonic() < deadline:
        if _is_cse_ready(selected_port, expected_instance_id):
            break
        time.sleep(0.05)
    else:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)
        message = "CSE sunucusu başlangıç süresinde hazır olmadı."
        logger.error(message)
        raise LauncherError(message)

    browser_opened = _open_browser(url, browser_open, open_browser, logger)
    logger.info("CSE hazır: %s", url)
    result = LaunchResult(
        url=url,
        port=selected_port,
        already_running=False,
        browser_opened=browser_opened,
        server=server,
        thread=thread,
    )
    if block:
        result.wait()
    return result


def _make_server(host: str, port: int, application: Flask) -> BaseWSGIServer:
    return make_server(
        host,
        port,
        application,
        threaded=True,
        request_handler=_QuietRequestHandler,
    )


class _QuietRequestHandler(WSGIRequestHandler):
    def log_request(self, *_args: object) -> None:
        return


def _ensure_directory(value: str | Path, label: str) -> Path:
    path = Path(value).resolve()
    if path.exists() and not path.is_dir():
        raise LauncherError(f"{label} yolu bir klasör değil.")
    try:
        path.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise LauncherError(f"{label} klasörü oluşturulamadı.") from exc
    if not path.is_dir():
        raise LauncherError(f"{label} yolu bir klasör değil.")
    return path


def _configure_logger(path: Path) -> logging.Logger:
    logger = logging.getLogger(f"cse.launcher.{path}")
    logger.setLevel(logging.INFO)
    logger.propagate = False
    if not logger.handlers:
        handler = logging.FileHandler(path, encoding="utf-8")
        handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
        logger.addHandler(handler)
    return logger


def _open_browser(
    url: str,
    browser_open: Callable[[str], bool],
    enabled: bool,
    logger: logging.Logger,
) -> bool:
    if not enabled:
        return False
    try:
        opened = bool(browser_open(url))
    except Exception as exc:
        logger.error("Tarayıcı otomatik açılamadı: %s", exc.__class__.__name__)
        return False
    if not opened:
        logger.error("Tarayıcı otomatik açılamadı; adres elle açılabilir: %s", url)
    return opened


def _is_cse_ready(port: int, expected_instance_id: str) -> bool:
    try:
        request = urllib.request.Request(
            f"{_url(port)}/health",
            headers={"Accept": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=0.25) as response:
            if response.status != 200:
                return False
            payload = json.load(response)
    except (OSError, ValueError, json.JSONDecodeError, urllib.error.URLError):
        return False
    return (
        payload.get("application") == APPLICATION_ID
        and payload.get("instance_id") == expected_instance_id
        and payload.get("ready") is True
    )


def _port_is_available(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as candidate:
        try:
            if hasattr(socket, "SO_EXCLUSIVEADDRUSE"):
                candidate.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
            candidate.bind((LOOPBACK_HOST, port))
        except OSError:
            return False
    return True


def _url(port: int) -> str:
    return f"http://{LOOPBACK_HOST}:{port}"
