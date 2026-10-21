#!/usr/bin/env python3
"""Windows of this set appearing out of nothing (Saneroki, 2026-10-21): not a closed book opening, but the open
window coming in from fully transparent like a magical book, as the full screens appear; the disappearing is the
same clip backwards, in code. Each picked still is taken out of its picture (ui-panels/anim.py's clear()), Wan
2.2 paints the way from the empty picture to the still, and the preview, <name>-appear.gif, plays only the
motion in a few hundred milliseconds (anim.py's quick()) and then holds the still: the final open stage. Wan
often still makes a closed book that opens (the stills look like books), so drawn() makes each one in code too,
as the game could: the window's lines draw in as glowing pencil strokes, then the window fades in solid
(<name>-drawn.gif; two layers and their alpha).
  python3 dev/imagegen/sets/ui-paper/appear.py [name ...]    the clips and the previews (all, or these)
  python3 dev/imagegen/sets/ui-paper/appear.py --previews    only the previews again
"""
import importlib.util, os, subprocess, sys
from PIL import Image, ImageChops, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
OUT = "assets/generated/ui-paper"
spec = importlib.util.spec_from_file_location("panels_anim", os.path.join(HERE, "../ui-panels/anim.py"))
panels = importlib.util.module_from_spec(spec)
spec.loader.exec_module(panels)

# the stills that appear: name -> picture
PICKS = {
    "doll-quick": "quick/doll-quick-1.png",
    "window": "windows/window-1.png",
    "bags": "windows/bags-1.png",
    "chat": "windows/chat-1.png",
    "character": "windows/character-1.png",
}
MOTION = ("The open window appears out of nothing, in place and all at once, like magic: it fades in from fully "
          "transparent while faint glowing pencil strokes draw its outline and its lines, then the leather edges, the "
          "paper and the content become solid and settle. It is already open and flat from the first frame: no book "
          "cover, no closed book, no pages turning, no hinge or door swinging, nothing rotating, folding or moving "
          "into the picture; only its opacity and the drawing of its lines change.")


def lists():
    lines = ["# Written by appear.py: each window coming in from nothing, from the empty picture to the still.",
             "workflow: dev/imagegen/workflows/wan22-14b-flf-2ref.json", "set: width=640, height=640, length=33",
             "count: 1", "fps: 16", f"out: {OUT}/appear",
             "style: Quick: the motion is done within the first half of the clip, then everything holds still on "
             "the finished window. The camera and the background never move."]
    for name, still in PICKS.items():
        lines += [f"ref: {OUT}/empty/{name}.png, {OUT}/{still}", f"{name}: {MOTION}"]
    open(os.path.join(HERE, "appear.txt"), "w").write("\n".join(lines) + "\n")


def preview(name):
    """The empty picture a moment, the motion in panels.STEPS frames, then the clip's last frame (the still) held."""
    folder = os.path.join(ROOT, OUT, "appear", f"{name}-1")
    if not os.path.isdir(folder):
        return
    clip = [Image.open(os.path.join(folder, f)).convert("RGB") for f in sorted(os.listdir(folder)) if f.endswith(".png")]
    frames = panels.quick(clip)[:-1] + [clip[-1]]
    save(frames, os.path.join(ROOT, OUT, "appear", f"{name}-appear.gif"))


def drawn(name, still):
    """The appearing made in code: the still's lines as glowing pencil strokes come first, the still fades in over
    them, the strokes going as it settles."""
    full = Image.open(os.path.join(ROOT, OUT, still)).convert("RGB").resize((640, 640), Image.LANCZOS)
    empty = Image.open(os.path.join(ROOT, OUT, "empty", f"{name}.png")).convert("RGB").resize((640, 640), Image.LANCZOS)
    edges = full.convert("L").filter(ImageFilter.FIND_EDGES).point(lambda v: 0 if v < 28 else min(255, v * 3))
    glow = ImageChops.add(edges, edges.filter(ImageFilter.GaussianBlur(3)))
    tint = Image.merge("RGB", [glow.point(lambda v: v * c // 255) for c in (255, 226, 170)])
    frames = []
    for k in range(panels.STEPS):
        t = k / (panels.STEPS - 1)
        lines, body = min(1, t * 2.2), max(0.0, (t - 0.3) / 0.7) ** 1.5
        frame = Image.blend(empty, full, body)
        frames.append(ImageChops.add(frame, tint.point(lambda v: int(v * lines * (1 - body)))))
    save(frames, os.path.join(ROOT, OUT, "appear", f"{name}-drawn.gif"))


def save(frames, path):
    step = int(1000 / panels.FPS)
    frames[0].save(path, save_all=True, append_images=frames[1:], loop=0,
                   duration=[400] + [step] * (len(frames) - 2) + [2000])


if __name__ == "__main__":
    args = sys.argv[1:]
    if args != ["--previews"]:
        for name, still in PICKS.items():
            panels.clear(os.path.join(ROOT, OUT, still), os.path.join(ROOT, OUT, "empty", f"{name}.png"))
        lists()
        subprocess.run(["dev/tools/imagegen", "dev/imagegen/sets/ui-paper/appear.txt"] + (["--only", ",".join(args)] if args else []),
                       cwd=ROOT, check=False)
    for name, still in PICKS.items():
        preview(name)
        drawn(name, still)
