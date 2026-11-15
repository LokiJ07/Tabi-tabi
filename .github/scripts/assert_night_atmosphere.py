#!/usr/bin/env python3
"""QA: verify the real Night 1 river is visually distinguishable from daylight.

This reuses the pixel scanner that already excludes mobile HUD columns. A
functional Night toggle must darken the world, not merely change a label.
"""
import sys
from pathlib import Path
from assert_gameplay_visible import read_png_rgb

def luma(path: str) -> float:
    _w, _h, total, colors, _white = read_png_rgb(Path(path))
    if total == 0:
        raise AssertionError("Empty game-world screenshot")
    return sum((r * .2126 + g * .7152 + b * .0722) * 16.0 * n
               for (r, g, b), n in colors.items()) / total

day = luma(sys.argv[1])
night = luma(sys.argv[2])
print(f"Night 1 river luminance: daylight={day:.1f}, night={night:.1f}, ratio={night/max(day, .01):.3f}")
if night > day * .93:
    print("FAIL: Night 1 world does not visibly darken; atmospheric night grade missing.",file=sys.stderr)
    sys.exit(1)
print("PASS: Actual night river is meaningfully darker than daytime shore.")
