"""Generate deterministic, repository-owned CSE launcher and splash PNGs."""

from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
MOBILE_ROOT = REPOSITORY_ROOT / "mobile"
BACKGROUND = (18, 60, 51)
FOREGROUND = (255, 249, 232)
ACCENT = (242, 193, 78)
TRANSPARENT = (0, 0, 0, 0)


def _chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


class Canvas:
    def __init__(
        self,
        width: int,
        height: int,
        *,
        alpha: bool,
        background: tuple[int, ...],
    ) -> None:
        self.width = width
        self.height = height
        self.alpha = alpha
        self.channels = 4 if alpha else 3
        self.pixels = bytearray(background * (width * height))

    def rectangle(
        self,
        left: int,
        top: int,
        right: int,
        bottom: int,
        color: tuple[int, ...],
    ) -> None:
        for y in range(max(0, top), min(self.height, bottom)):
            for x in range(max(0, left), min(self.width, right)):
                offset = (y * self.width + x) * self.channels
                self.pixels[offset : offset + self.channels] = bytes(color)

    def polygon(
        self,
        points: list[tuple[int, int]],
        color: tuple[int, ...],
    ) -> None:
        minimum_y = max(0, min(point[1] for point in points))
        maximum_y = min(self.height - 1, max(point[1] for point in points))
        for y in range(minimum_y, maximum_y + 1):
            intersections: list[float] = []
            previous = points[-1]
            for current in points:
                if (current[1] > y) != (previous[1] > y):
                    ratio = (y - current[1]) / (previous[1] - current[1])
                    intersections.append(
                        current[0] + ratio * (previous[0] - current[0])
                    )
                previous = current
            intersections.sort()
            for index in range(0, len(intersections), 2):
                if index + 1 >= len(intersections):
                    break
                self.rectangle(
                    round(intersections[index]),
                    y,
                    round(intersections[index + 1]) + 1,
                    y + 1,
                    color,
                )

    def write_png(self, destination: Path) -> None:
        destination.parent.mkdir(parents=True, exist_ok=True)
        scanlines = bytearray()
        row_size = self.width * self.channels
        for y in range(self.height):
            scanlines.append(0)
            start = y * row_size
            scanlines.extend(self.pixels[start : start + row_size])
        color_type = 6 if self.alpha else 2
        header = struct.pack(">IIBBBBB", self.width, self.height, 8, color_type, 0, 0, 0)
        destination.write_bytes(
            b"\x89PNG\r\n\x1a\n"
            + _chunk(b"IHDR", header)
            + _chunk(b"IDAT", zlib.compress(bytes(scanlines), level=9))
            + _chunk(b"IEND", b"")
        )


def _draw_mark(canvas: Canvas, box: tuple[int, int, int, int]) -> None:
    left, top, right, bottom = box
    width = right - left
    height = bottom - top
    color = FOREGROUND + ((255,) if canvas.alpha else ())
    dark = BACKGROUND + ((255,) if canvas.alpha else ())
    accent = ACCENT + ((255,) if canvas.alpha else ())

    def x(value: float) -> int:
        return round(left + width * value)

    def y(value: float) -> int:
        return round(top + height * value)

    canvas.polygon(
        [
            (x(0.18), y(0.72)),
            (x(0.18), y(0.35)),
            (x(0.42), y(0.18)),
            (x(0.66), y(0.35)),
            (x(0.66), y(0.46)),
            (x(0.84), y(0.46)),
            (x(0.84), y(0.72)),
        ],
        color,
    )
    window = max(1, round(width * 0.08))
    for window_x, window_y in [
        (0.30, 0.40),
        (0.48, 0.40),
        (0.30, 0.56),
        (0.48, 0.56),
        (0.71, 0.57),
    ]:
        canvas.rectangle(
            x(window_x),
            y(window_y),
            x(window_x) + window,
            y(window_y) + window,
            dark,
        )
    canvas.rectangle(x(0.14), y(0.75), x(0.88), y(0.84), accent)


def _write_icon(destination: Path, size: int) -> None:
    canvas = Canvas(size, size, alpha=False, background=BACKGROUND)
    margin = round(size * 0.13)
    _draw_mark(canvas, (margin, margin, size - margin, size - margin))
    canvas.write_png(destination)


def _write_launch(destination: Path, width: int, height: int) -> None:
    canvas = Canvas(width, height, alpha=True, background=TRANSPARENT)
    mark_size = round(min(width, height) * 0.78)
    left = (width - mark_size) // 2
    top = (height - mark_size) // 2
    _draw_mark(canvas, (left, top, left + mark_size, top + mark_size))
    canvas.write_png(destination)


def generate() -> None:
    android_res = MOBILE_ROOT / "android" / "app" / "src" / "main" / "res"
    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        directory = android_res / f"mipmap-{density}"
        _write_icon(directory / "ic_launcher.png", size)
        _write_icon(directory / "ic_launcher_round.png", size)

    app_icon = (
        MOBILE_ROOT
        / "ios"
        / "Runner"
        / "Assets.xcassets"
        / "AppIcon.appiconset"
    )
    contents = json.loads((app_icon / "Contents.json").read_text(encoding="utf-8"))
    generated: dict[str, int] = {}
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        scale = int(item["scale"].removesuffix("x"))
        points = float(item["size"].split("x", maxsplit=1)[0])
        generated[filename] = round(points * scale)
    for filename, size in generated.items():
        _write_icon(app_icon / filename, size)

    launch = (
        MOBILE_ROOT
        / "ios"
        / "Runner"
        / "Assets.xcassets"
        / "LaunchImage.imageset"
    )
    for filename, scale in {
        "LaunchImage.png": 1,
        "LaunchImage@2x.png": 2,
        "LaunchImage@3x.png": 3,
    }.items():
        _write_launch(launch / filename, 168 * scale, 185 * scale)


if __name__ == "__main__":
    generate()
