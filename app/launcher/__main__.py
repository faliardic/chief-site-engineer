"""Command entrypoint used by the Windows double-click file."""

import argparse
import sys
from collections.abc import Sequence
from pathlib import Path

from .windows import (
    DEFAULT_PORT,
    DEFAULT_PORT_COUNT,
    DEFAULT_STARTUP_TIMEOUT,
    LauncherError,
    launch,
    resolve_default_paths,
)


def parse_args(arguments: Sequence[str] | None = None) -> argparse.Namespace:
    defaults = resolve_default_paths()
    parser = argparse.ArgumentParser(description="Chief Site Engineer başlatıcı")
    parser.add_argument("--data-root", type=Path, default=defaults.data_root)
    parser.add_argument("--logs-root", type=Path, default=defaults.logs_root)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--port-count", type=int, default=DEFAULT_PORT_COUNT)
    parser.add_argument(
        "--startup-timeout", type=float, default=DEFAULT_STARTUP_TIMEOUT
    )
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args(arguments)
    if args.port_count < 1:
        parser.error("--port-count pozitif olmalıdır")
    if args.startup_timeout <= 0:
        parser.error("--startup-timeout pozitif olmalıdır")
    return args


def main(arguments: Sequence[str] | None = None) -> int:
    try:
        args = parse_args(arguments)
        result = launch(
            args.data_root,
            args.logs_root,
            preferred_port=args.port,
            port_count=args.port_count,
            startup_timeout=args.startup_timeout,
            open_browser=not args.no_browser,
            block=False,
        )
    except (LauncherError, OSError) as exc:
        print(f"HATA: {exc}", file=sys.stderr)
        return 1

    if result.already_running:
        if args.no_browser:
            print(f"CSE zaten çalışıyor: {result.url}")
        elif result.browser_opened:
            print(f"CSE zaten çalışıyor; mevcut uygulama açıldı: {result.url}")
        else:
            print(f"CSE zaten çalışıyor. Bu adresi açın: {result.url}")
        return 0
    if not result.browser_opened and not args.no_browser:
        print(f"Tarayıcı otomatik açılamadı. Bu adresi açın: {result.url}")
    else:
        print(f"CSE hazır: {result.url}")
    try:
        result.wait()
    except KeyboardInterrupt:
        pass
    finally:
        result.shutdown()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
