#!/usr/bin/env python3
"""Regression for the screenshot bug where the north trail ended in cyan void.

Inspect actual Android ADB screencap pixels beyond the village north crossing,
not a static design illustration. The broad northeast world area must include
rendered textured terrain rather than a single background/sky color.
"""
import sys
from pathlib import Path
from assert_gameplay_visible import read_png_rgb

if len(sys.argv) != 2:
    raise SystemExit("usage: assert_north_trail_terrain.py build/android-night1-connected-trail.png")
width, height, total, colors, _white = read_png_rgb(
    Path(sys.argv[1]), x_range=(.70, .80), y_range=(.15, .49)
)
if total < 80:
    raise SystemExit("FAIL: north forest screenshot missing sampling area")
dominant, count = colors.most_common(1)[0]
share = count / total
print(f"Barrio north corridor screenshot: {width}x{height}, most common RGB16={dominant}, share={share:.1%}, unique={len(colors)}")
if share > .90 or dominant == (6, 9, 8) and share > .40:
    raise SystemExit("FAIL: Old Mango Trail still terminates in flat cyan unrendered world")
if len(colors) < 6:
    raise SystemExit("FAIL: North trail lacks any substantial terrain detail")
print("PASS: North trail area includes actual rendered world instead of cyan void")
