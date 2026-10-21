#!/usr/bin/env python3
"""polish.txt for every view of compose.py, each at its own size (a multiple of 16 near it, about a megapixel
and a half at most), so the edit never squeezes a view.
  python3 dev/imagegen/sets/interface/polish.py [view ...]
"""
import os, subprocess, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
VIEWS = os.path.join(ROOT, "assets/generated/interface/views")
MAX = 1.6e6

for name in sys.argv[1:] or sorted(f[:-4] for f in os.listdir(VIEWS) if f.endswith(".png")):
    w, h = Image.open(os.path.join(VIEWS, name + ".png")).size
    k = min(1, (MAX / (w * h)) ** 0.5)
    w, h = round(w * k / 16) * 16, round(h * k / 16) * 16
    subprocess.run(["dev/tools/imagegen", "dev/imagegen/sets/interface/polish.txt", "--only", name,
                    "--set", f"width={w}", "--set", f"height={h}"], cwd=ROOT, check=False)
