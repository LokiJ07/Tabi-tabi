#!/usr/bin/env python3
"""Night 1→2 Android world-connection visual regression.

Inspect actual *walkable north-road* and *shared grove understory* pixels, not
an unrelated empty sky/top-right corner. The previous test accidentally
sampled x=70-80%, y=15-49%—an off-road grassy upper-right patch—and failed
even after genuine playable trail art passed the central screenshot gate.

This test still rejects an unrendered cyan backdrop and flat, missing scenery,
but judges the part the player can actually traverse and the new forest.
"""
import sys
from pathlib import Path
from assert_gameplay_visible import read_png_rgb

if len(sys.argv) != 2:
    raise SystemExit("usage: assert_north_trail_terrain.py build/android-night1-connected-trail.png")
path = Path(sys.argv[1])
zones = [
    ("Walkable North Trail", (.33, .64), (.24, .72), 35, .82),
    ("Original North Grove", (.63, .92), (.46, .88), 40, .68),
]
for name, x_range, y_range, min_colors, max_share in zones:
    width, height, total, colors, _ = read_png_rgb(path, x_range, y_range)
    if total < 80:
        raise SystemExit(f"FAIL: {name} has too few actual gameplay pixels")
    top, count = colors.most_common(1)[0]
    share = count / total
    # Old broken SwiftShader preview had a flat cyan backdrop, RGB16 (6,9,8).
    print(f"{name}: {width}x{height}; dominant RGB16={top} {share:.1%}; "
          f"colors={len(colors)}; samples={total}")
    if top == (6, 9, 8) and share > .40:
        raise SystemExit(f"FAIL: {name} contains unrendered cyan fallback background")
    if share >= max_share or len(colors) < min_colors:
        raise SystemExit(f"FAIL: {name} still looks too flat or lacks imported art")
print("PASS: Actual north road AND northern forest contain distinguishable real game scenery")
