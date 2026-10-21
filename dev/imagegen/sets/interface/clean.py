#!/usr/bin/env python3
"""The decided pictures cleaned of what Saneroki does not want, by masked inpainting
(dev/imagegen/workflows/qwen21-inpaint.json: the model repaints only inside a mask, every other pixel stays):
  frame   edges-and-buttons.png (#12): the leather strap and patches over the paper at the bottom cut out (the page
          meets its own page stack), the writing in its title label covered by the label's own paper (code writes
          the title); both in code, #12's pixels only
  doll    doll.png (#3): the pencil rectangle behind the hero taken out, then a stony ground sketch across the whole
          bottom of the hero's place
Each pass is a mask (white is repainted, its edge feathered) and the words for what goes there; a pass works on
the last one's result. Where the model kept or redrew what it should take out (at this workflow's guidance the
words cannot forbid), a pass in code does it (CODE): plain paper of the part's own tone, or a line bridged from the
paper on both sides of it.
  python3 dev/imagegen/sets/interface/clean.py [frame|doll ...]   ->  assets/generated/interface/clean/<name>.png
"""
import os, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
REFS = "assets/Concept art/UI style"
OUT = "assets/generated/interface/clean"
FEATHER = 3
# guidance above 1 makes the negative words count (at 1 the workflow ignores them): what must not come back
CFG = 3.0
NEGATIVE = ("frame, border, line, lines, rectangle, outline, box, panel edge, strap, leather, buckle, button, "
            "letters, text, writing")

# picture: (decided source, [(pass, boxes to repaint, what goes there)])
PASSES = {
    "frame": (f"{REFS}/edges-and-buttons.png", []),           # all in code (CODE): #12's own pixels only
    "doll": (f"{REFS}/doll.png", [
        ("no-rectangle", [(406, 84, 430, 690), (594, 84, 618, 690), (406, 82, 618, 108)],
         "Seamless, continuous plain aged parchment, the same paper and light as on both sides, nothing drawn on it."),
        ("ground", [(408, 676, 616, 766)],
         "A loose, light graphite pencil sketch of stony ground: flat stones, pebbles and small tufts of grass spread "
         "across the whole width, drawn on the parchment like the pencil sketches around it, the hero's boots standing "
         "on it."),
    ]),
}


# passes in code, after the model's: (kind, box) - "plain": the box's marks covered by the paper's own tone;
# "bridge-x" / "bridge-y": a vertical / horizontal line in the box replaced by the paper either side of it (only
# where nothing else stands beside the line)
CODE = {
    # the strap's rows cut out, so the page above meets #12's own page stack below (a repaint invented other
    # pages); then the label's own empty stretch copied over its writing
    "frame": [("cut-rows", (826, 880)), ("copy", ((334, 170, 556, 192), (562, 170, 700, 192)))],
    "doll": [],
}


def bridge(img, box, across):
    """Each row (across x) or column (across y) of the box blended from the paper just outside it, with a little grain."""
    import numpy as np
    a = np.asarray(img.convert("RGB"), dtype=np.float32).copy()
    x0, y0, x1, y1 = box
    rng = np.random.default_rng(3)
    if across == "x":
        left, right = a[y0:y1, x0 - 4:x0].mean(axis=1), a[y0:y1, x1:x1 + 4].mean(axis=1)
        t = np.linspace(0, 1, x1 - x0)[None, :, None]
        a[y0:y1, x0:x1] = left[:, None] * (1 - t) + right[:, None] * t + rng.normal(0, 3, (y1 - y0, x1 - x0, 1))
    else:
        top, bottom = a[y0 - 4:y0, x0:x1].mean(axis=0), a[y1:y1 + 4, x0:x1].mean(axis=0)
        t = np.linspace(0, 1, y1 - y0)[:, None, None]
        a[y0:y1, x0:x1] = top[None] * (1 - t) + bottom[None] * t + rng.normal(0, 3, (y1 - y0, x1 - x0, 1))
    out = Image.fromarray(a.clip(0, 255).astype("uint8"))
    m = Image.new("L", img.size)
    ImageDraw.Draw(m).rectangle(box, fill=255)
    return Image.composite(out, img.convert("RGB"), m.filter(ImageFilter.GaussianBlur(1.5)))


def mask(size, boxes):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    for b in boxes:
        d.rectangle(b, fill=255)
    return m.filter(ImageFilter.GaussianBlur(FEATHER)).convert("RGB")


def run(name):
    src, passes = PASSES[name]
    os.makedirs(os.path.join(ROOT, OUT, "steps"), exist_ok=True)
    current = src
    for i, (step, boxes, words) in enumerate(passes, 1):
        size = Image.open(os.path.join(ROOT, current)).size
        mpath = f"{OUT}/steps/{name}-{i}-{step}-mask.png"
        mask(size, boxes).save(os.path.join(ROOT, mpath))
        lst = os.path.join(ROOT, OUT, "steps", f"{name}-{i}.txt")
        open(lst, "w").write(f"workflow: dev/imagegen/workflows/qwen21-inpaint.json\ncount: 1\nout: {OUT}/steps\n"

                             f"ref: {current}, {mpath}\n{name}-{i}-{step}: {words}\n")
        subprocess.run(["dev/tools/imagegen", os.path.relpath(lst, ROOT), "--set", f"cfg={CFG}",
                        "--set", f"negative_prompt={NEGATIVE}"], cwd=ROOT, check=True)
        current = f"{OUT}/steps/{name}-{i}-{step}-1.png"
    img = Image.open(os.path.join(ROOT, current)).convert("RGB")
    sys.path.insert(0, HERE)
    import refs
    for kind, box in CODE.get(name, []):
        if kind == "cut-rows":
            y0, y1 = box
            w, h = img.size
            out = Image.new("RGB", (w, h), img.getpixel((2, h - 2)))
            out.paste(img.crop((0, 0, w, y0)), (0, 0))
            below = img.crop((0, y1, w, h))
            m = Image.new("L", below.size, 255)
            m.paste(Image.linear_gradient("L").resize((w, 8)), (0, 0))       # a soft join
            out.paste(below, (0, y0), m)
            img = out
        elif kind == "copy":
            dst, src = box
            piece = img.crop(src)
            fill = Image.new("RGB", (dst[2] - dst[0], dst[3] - dst[1]))
            for x in range(0, fill.width, piece.width - 20):
                m = Image.new("L", piece.size, 255)
                if x:
                    ramp = Image.linear_gradient("L").rotate(90, expand=True).transpose(Image.FLIP_LEFT_RIGHT).resize((20, piece.height))
                    m.paste(ramp, (0, 0))
                fill.paste(piece, (x, 0), m)
            m = Image.new("L", fill.size)
            ImageDraw.Draw(m).rectangle((2, 2, fill.width - 3, fill.height - 3), fill=255)
            img.paste(fill, dst[:2], m.filter(ImageFilter.GaussianBlur(1.5)))
        elif kind == "plain":
            w, h = img.size
            img = refs.clean(img, (box[0] / w, box[1] / h, box[2] / w, box[3] / h))
        else:
            img = bridge(img, box, kind[-1])
    img.save(os.path.join(ROOT, OUT, name + ".png"))
    print(name, "->", f"{OUT}/{name}.png")


if __name__ == "__main__":
    for n in sys.argv[1:] or PASSES:
        run(n)
