"""Machine-readable local export and recovery commands."""

import argparse
import json
import sys
from collections.abc import Sequence
from pathlib import Path

from app.operations import BackupService, DailyExportService


def parse_args(arguments: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Local Field MVP operations")
    commands = parser.add_subparsers(dest="command", required=True)

    export = commands.add_parser("export-daily")
    export.add_argument("--data-root", required=True)
    export.add_argument("--date", required=True)
    export.add_argument("--output", required=True)

    backup = commands.add_parser("backup")
    backup.add_argument("--data-root", required=True)
    backup.add_argument("--output", required=True)

    verify = commands.add_parser("verify-backup")
    verify.add_argument("--archive", required=True)

    restore = commands.add_parser("restore")
    restore.add_argument("--archive", required=True)
    restore.add_argument("--target-root", required=True)
    return parser.parse_args(arguments)


def main(arguments: Sequence[str] | None = None) -> int:
    args = parse_args(arguments)
    try:
        if args.command == "export-daily":
            result = DailyExportService(args.data_root).build_daily_export(
                args.date, args.output
            )
            payload = {
                "ok": True,
                "operation": "export-daily",
                "artifact": result.path.name,
                "record_count": result.record_count,
                "warning_count": result.warning_count,
            }
        elif args.command == "backup":
            result = BackupService(args.data_root).create_backup(args.output)
            payload = {
                "ok": True,
                "operation": "backup",
                "artifact": result.path.name,
                "attachment_count": result.attachment_count,
            }
        elif args.command == "verify-backup":
            manifest = BackupService(Path(args.archive).parent).verify_backup(
                args.archive
            )
            payload = {
                "ok": True,
                "operation": "verify-backup",
                "attachment_count": manifest["attachment_count"],
            }
        else:
            result = BackupService(Path(args.archive).parent).restore_backup(
                args.archive, args.target_root
            )
            payload = {
                "ok": True,
                "operation": "restore",
                "attachment_count": result.attachment_count,
            }
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
        return 0
    except Exception as exc:
        error = {
            "ok": False,
            "operation": args.command,
            "error": exc.__class__.__name__,
        }
        print(json.dumps(error, sort_keys=True, separators=(",", ":")), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
