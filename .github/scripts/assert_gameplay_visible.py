#!/usr/bin/env python3
"""Android visual regression: fail if active Night 1 world stays one flat color.

Uses only Python's stdlib (PNG RGB/RGBA decoder); no network or image packages.
The emulator's GLES3 shader-link failure previously produced a ~85% cyan world
while the app process stayed alive. This checks real adb screenshot pixels.
"""
import collections
import struct
import sys
import zlib
from pathlib import Path

def read_png_rgb(path: Path):
    payload = path.read_bytes()
    assert payload.startswith(b"\x89PNG\r\n\x1a\n"), "Screenshot is not a PNG"
    pos = 8
    compressed = []
    width = height = color_type = None
    while pos + 12 <= len(payload):
        length = int.from_bytes(payload[pos:pos + 4], "big")
        tag = payload[pos + 4:pos + 8]
        body = payload[pos + 8:pos + 8 + length]
        pos += 12 + length
        if tag == b"IHDR":
            width, height, depth, color_type, compression, filt, interlace = struct.unpack(">IIBBBBB", body)
            assert depth == 8 and color_type in (2, 6) and interlace == 0, "Expected noninterlaced RGB/RGBA8 screencap"
        elif tag == b"IDAT":
            compressed.append(body)
        elif tag == b"IEND":
            break
    channels = 3 if color_type == 2 else 4
    scan = zlib.decompress(b"".join(compressed))
    stride = width * channels
    previous = bytearray(stride)
    cursor = 0
    samples = collections.Counter()
    total = 0
    white_popup_pixels = 0
    for y in range(height):
        kind = scan[cursor]
        cursor += 1
        row = bytearray(scan[cursor:cursor + stride])
        cursor += stride
        # PNG scanline filters: None, Sub, Up, Average and Paeth.
        if kind == 1:
            for i in range(channels, stride):
                row[i] = (row[i] + row[i - channels]) & 255
        elif kind == 2:
            for i in range(stride):
                row[i] = (row[i] + previous[i]) & 255
        elif kind == 3:
            for i in range(stride):
                row[i] = (row[i] + ((row[i - channels] if i >= channels else 0) + previous[i]) // 2) & 255
        elif kind == 4:
            for i in range(stride):
                a = row[i - channels] if i >= channels else 0
                b = previous[i]
                c = previous[i - channels] if i >= channels else 0
                p = a + b - c
                da, db, dc = abs(p - a), abs(p - b), abs(p - c)
                predictor = a if da <= db and da <= dc else b if db <= dc else c
                row[i] = (row[i] + predictor) & 255
        elif kind != 0:
            raise ValueError(f"Unsupported PNG filter {kind}")
        # Deliberately inspect only the central playfield, excluding title/HUD
        # and button columns. World texture/characters/terrain must be visible.
        if int(height * .28) <= y <= int(height * .80) and y % 16 == 0:
            for x in range(int(width * .28), int(width * .65), 16):
                i = x * channels
                # Bucket near-identical colors to detect flat blank backdrops.
                rgb = (row[i] // 16, row[i + 1] // 16, row[i + 2] // 16)
                samples[rgb] += 1
                total += 1
                if row[i] > 195 and row[i + 1] > 195 and row[i + 2] > 195:
                    white_popup_pixels += 1
        previous = row
    return width, height, total, samples, white_popup_pixels

if __name__ == "__main__":
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/android-night1-launch.png")
    width, height, total, histogram, white_popup_pixels = read_png_rgb(path)
    top, count = histogram.most_common(1)[0]
    dominant = count / total
    white_popup_share = white_popup_pixels / total
    print(f"Android gameplay visual check: {width}x{height}; samples={total}; dominant RGB/16={top}; portion={dominant:.1%}; colors={len(histogram)}")
    if white_popup_share > .15:
        print(f"FAIL: Android immersive onboarding / white system popup obscures {white_popup_share:.1%} of gameplay.", file=sys.stderr)
        sys.exit(1)
    if dominant > .67:
        print("FAIL: World is mostly a flat color, likely GLES3 shader failure / cyan background.", file=sys.stderr)
        sys.exit(1)
    if len(histogram) < 24:
        print("FAIL: World is not visually varied enough to show the actual environment.", file=sys.stderr)
        sys.exit(1)
    print("PASS: Visible, varied rendered game world; not just title or HUD.")
