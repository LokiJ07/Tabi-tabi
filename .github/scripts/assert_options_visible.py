#!/usr/bin/env python3
"""Verify screenshots show the ACTUAL two-column Options panel, not gameplay.

The previous Android QA screenshot mislabeled an ordinary gameplay frame
"android-night1-options.png". This comparison tests the source screenshots,
using the existing stdlib PNG decoder; no OCR or visual cloud models required.
"""
import sys
from pathlib import Path
from assert_gameplay_visible import read_png_rgb

def check(before: Path, after: Path) -> bool:
    wa,ha,na,hista,_ = read_png_rgb(before, x_range=(.20,.82), y_range=(.15,.85))
    wb,hb,nb,histb,_ = read_png_rgb(after, x_range=(.20,.82), y_range=(.15,.85))
    if (wa,ha)!=(wb,hb) or min(na,nb)<100:
        raise AssertionError("Screenshot dimensions/samples do not match")
    total_variation = sum(abs(hista[k]/na-histb[k]/nb) for k in (hista.keys()|histb.keys()))/2.0
    print(f"Real Options screenshot QA: {before.name} -> {after.name}; "
          f"center palette change={total_variation:.1%}")
    if total_variation < .24:
        print("FAIL: expected real full-screen settings panel, got virtually unchanged gameplay screenshot")
        return False
    return True

if __name__ == "__main__":
    sys.exit(0 if check(Path(sys.argv[1]),Path(sys.argv[2])) else 1)
