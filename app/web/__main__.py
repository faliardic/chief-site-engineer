"""Local development launcher for the Field MVP."""

import argparse
from collections.abc import Sequence

from .app import create_app


LOOPBACK_HOSTS = frozenset({"127.0.0.1", "localhost", "::1"})


def parse_args(arguments: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Chief Site Engineer local Field MVP")
    parser.add_argument("--data-root", required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=5000)
    parser.add_argument("--allow-network", action="store_true")
    args = parser.parse_args(arguments)
    if args.host not in LOOPBACK_HOSTS and not args.allow_network:
        parser.error("loopback disi host icin --allow-network zorunludur")
    return args


def main() -> None:
    args = parse_args()
    if args.host not in LOOPBACK_HOSTS:
        print("UYARI: Bu local MVP auth/TLS icermez; public internet icin uygun degildir.")
    print("Flask development server production kullanimi icin uygun degildir.")
    create_app(args.data_root).run(host=args.host, port=args.port, debug=False)


if __name__ == "__main__":
    main()
