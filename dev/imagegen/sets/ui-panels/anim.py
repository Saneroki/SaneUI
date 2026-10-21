#!/usr/bin/env python3
"""Small panels appearing and disappearing as a whole: each chosen panel of panels.txt is taken out of its
picture in code (clear(): the panel found by its edges, its place filled from the blurred background round it;
Qwen's edit, asked to remove the panel, kept it and replaced the background with noise), and Wan 2.2 paints the
panel coming in, from the empty picture to the panel (dev/imagegen/workflows/wan22-14b-flf-2ref.json, 33
frames, quick). The disappearing is
the same clip backwards, as code would play it: each clip's preview, <name>-in-out.gif, shows both, the panel
held between them, the motion cut out of the clip and squeezed into a few hundred milliseconds (quick()).
  python3 dev/imagegen/sets/ui-panels/anim.py [seed]
  python3 dev/imagegen/sets/ui-panels/anim.py --previews     only the previews again, from the clips there are
"""
import os, subprocess, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageStat

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
SET = "dev/imagegen/sets/ui-panels"
OUT = "assets/generated/ui-panels"
SEED = sys.argv[1] if len(sys.argv) > 1 else "1"
FPS = 30     # the previews' speed
STEPS = 8    # frames of the opening (and the closing): 8 at 30 fps, about 270 ms, as quick as a window should be

# panel: how it comes in
MOTION = {
    "doll-hug": "it unfolds from a thin bright vertical seam in the middle, its sides opening outwards to its full outline",
    "doll-shield": "it drops in from just above and lands with a small puff of dust",
    "doll-ring": "it grows out of a small bright point in the middle, spinning once into place",
    "doll-wings": "its two wings fold out from the middle arch like opening wings",
    "book-fan": "its spell icons fan out from a closed stack into the curve, the panel growing with them",
    "bags-categories": "it slides up a short way from below while fading in, its category blocks snapping open one after another",
}


def run(path):
    subprocess.run(["dev/tools/imagegen", path], cwd=ROOT, check=False)


def clear(src, dst):
    """The picture without its panel: the panel is where the picture has edges (the background is blurred), with
    everything those edges enclose; that place starts at the background's mean colour, and the background round
    it flows in by blurring."""
    img = Image.open(src).convert("RGB")
    small = img.resize((256, 256), Image.LANCZOS)
    edges = small.convert("L").filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(1.5))
    for level in (14, 24, 36, 50, 70):  # a busier background needs a higher one, till a quarter of it is kept
        mask = edges.point(lambda v: 255 if v > level else 0).filter(ImageFilter.MaxFilter(9))
        flood = mask.convert("RGB")
        for corner in [(0, 0), (255, 0), (0, 255), (255, 255)]:
            if flood.getpixel(corner) == (0, 0, 0):
                ImageDraw.floodfill(flood, corner, (128, 128, 128))
        mask = flood.convert("L").point(lambda v: 0 if v == 128 else 255).filter(ImageFilter.MaxFilter(7))
        keep = ImageChops.invert(mask)
        if ImageStat.Stat(keep).mean[0] > 64:
            break
    mean = tuple(int(v) for v in ImageStat.Stat(small, keep).mean)
    fill = Image.composite(small, Image.new("RGB", small.size, mean), keep)
    for radius in (24, 16, 12, 8, 6, 4):
        fill = Image.composite(small, fill.filter(ImageFilter.GaussianBlur(radius)), keep)
    out = Image.composite(img, fill.resize(img.size, Image.LANCZOS),
                          keep.resize(img.size, Image.LANCZOS).filter(ImageFilter.GaussianBlur(6)))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    out.save(dst)


def lists():
    lines = ["# Written by anim.py: each panel coming in, from the empty picture to the panel.",
             "workflow: dev/imagegen/workflows/wan22-14b-flf-2ref.json", "set: width=640, height=640, length=33",
             "count: 1", "fps: 16", f"out: {OUT}/anim",
             "style: Quick and snappy: the motion is done within the first half of the clip, then everything holds "
             "still on the finished panel. The camera and the background never move."]
    for name, motion in MOTION.items():
        lines += [f"ref: {OUT}/empty/{name}-1.png, {OUT}/panels/{name}-{SEED}.png",
                  f"{name}: A small fantasy game panel appears out of nothing: {motion}."]
    open(os.path.join(ROOT, SET, "appear.txt"), "w").write("\n".join(lines) + "\n")


def quick(frames):
    """Only the clip's motion, in STEPS frames: Wan's clip moves for a part of its length and then holds; the
    motion ends at the last frame that still changes noticeably."""
    small = [f.convert("L").resize((96, 96)) for f in frames]
    change = [sum(ImageChops.difference(a, b).histogram()[k] * k for k in range(256)) for a, b in zip(small, small[1:])]
    end = max(i + 1 for i, c in enumerate(change) if c >= 0.15 * max(change)) if any(change) else len(frames) - 1
    return [frames[round(k * end / (STEPS - 1))] for k in range(STEPS)]


def in_out(name):
    """Opening, the panel held a second, closing (the opening backwards), the empty picture held half a second."""
    folder = os.path.join(ROOT, OUT, "anim", f"{name}-1")
    if not os.path.isdir(folder):
        return
    frames = quick([Image.open(os.path.join(folder, f)).convert("RGB") for f in sorted(os.listdir(folder)) if f.endswith(".png")])
    step = int(1000 / FPS)
    seq = frames + frames[-2::-1]
    times = [step] * (STEPS - 1) + [1000] + [step] * (STEPS - 2) + [500]
    seq[0].save(os.path.join(ROOT, OUT, "anim", f"{name}-in-out.gif"), save_all=True, append_images=seq[1:],
                duration=times, loop=0)


if __name__ == "__main__":
    if SEED == "--previews":
        for name in MOTION:
            in_out(name)
        sys.exit()
    for name in MOTION:
        clear(os.path.join(ROOT, OUT, "panels", f"{name}-{SEED}.png"), os.path.join(ROOT, OUT, "empty", f"{name}-1.png"))
    lists()
    run(f"{SET}/appear.txt")
    for name in MOTION:
        in_out(name)
