#!/usr/bin/env python3
"""The interface's whole render (Doc/guides/interface-style.md, *The harness* and *Pieces*): run by the GPU runner as
its job "interface" (dev/imagegen/jobs.toml). Every element is rendered once (Saneroki, 2026-10-22: one render
each, no varieties); each step skips what it has made, so a stopped run goes on where it stopped; --rebuild starts
anew from the decided references (after a decision changed).

  clean     the decided pictures cleaned (clean.py: #12 and #3)  ->  assets/generated/interface/clean/
  hires     every decided part at twice its size, the scale of a 4K screen, one render each: upscaled in code
            (Lanczos), then one gentle pass of Qwen over the whole picture (qwen21-inpaint.json with a full mask, low
            denoise), which sharpens its detail and keeps everything where it is; transparency put back from the
            upscaled source. Before it, a cut-out's holes (light metal its cut took for the background) are made
            solid and a label's painted letters covered  ->  assets/generated/interface/hires/<part>.png
  masks     the outside of the two whole picks (#12, #3) found by the background removal (birefnet-mask.json)
            ->  .../hires/<part>-mask.png
  pencil    the pencil lines of #14 (pencil.py)  ->  .../pencil/
  pieces    every element cut into its final pieces at 4K, transparent (pieces.py)  ->  .../pieces/, pieces.json
  views     the views laid out in code from the pieces (compose.py), all at 4K, the full screen among them  ->  .../views/, then
            the gallery (gallery.py)

  python3 dev/imagegen/sets/interface/catalog.py [clean|hires|masks|pencil|pieces|views ...]
  python3 dev/imagegen/sets/interface/catalog.py --status     how far it is (the runner's status line)
  python3 dev/imagegen/sets/interface/catalog.py --rebuild    forget what was made, so the next run makes it anew
"""
import os, subprocess, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
REFS = "assets/Concept art/UI style"
GEN = "assets/generated/interface"
SCALE = 2           # 4K: twice the size the picks were painted at (a window of about 600 px at 1080p)
DENOISE = 0.3       # how much the hires pass may repaint: detail, never shapes
FLAT = (118, 110, 100)

# part: its decided picture (a whole cleaned pick, or a cut-out with transparency)
HIRES = {
    "window": f"{GEN}/clean/frame.png",                  # #12, cleaned: every frame piece is cut from this
    "doll": f"{GEN}/clean/doll.png",                     # #3, cleaned
    "paper": f"{REFS}/paper.png",                        # #140
    "patch": f"{REFS}/patch.png",                        # #183: every button
    "top-tab-arrow": f"{REFS}/elements/top-tab-arrow-3.png",
    "top-tab-arrow-b": f"{REFS}/elements/top-tab-arrow-4.png",
    "top-tab-patch": f"{REFS}/elements/top-tab-patch-3.png",
    "edge-left": f"{REFS}/elements/edge-left-3.png",
    "edge-right": f"{REFS}/elements/edge-right-1.png",
    "pencil-box": f"{REFS}/elements/top-tab-drawn-1.png",   # #14 (pencil.py takes its lines from the hires one)
}
HIRES.update({f"kit{k}-{i:02}": f"{REFS}/kit/kit{k}-{i:02}.png" for k, n in ((3, 11), (4, 11)) for i in range(1, n + 1)})
LABELS = {"top-tab-patch": (0.12, 0.18, 0.88, 0.82)}     # parts whose painted label is covered (the box inside them)
MASKS = ["window", "doll"]                               # whole picks whose outside the background removal finds
HIRES_WORDS = ("Exactly the same picture in higher resolution: every shape, line, colour, texture and stitch where it "
               "is, only sharper and finer, clean and crisp. Nothing added, nothing removed, no text.")
NEGATIVE = "blurry, smeared, noise, artifacts, extra objects, text, letters, watermark, changed shape"


def path(rel):
    return os.path.join(ROOT, rel)


def run(lst, *extra):
    subprocess.run(["dev/tools/imagegen", lst, *extra], cwd=ROOT, check=True)


def label_off(img, inner):
    """A part's painted label taken off: inside the box inner (fractions of its shape's box), the letters (much
    darker or lighter than the leather round them, with their pressed lip) covered by the part's own leather from
    beside them on the same rows, so its grain and light run on."""
    import numpy as np
    from PIL import ImageDraw, ImageFilter
    box = img.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    w, h = box[2] - box[0], box[3] - box[1]
    x0, y0 = box[0] + round(inner[0] * w), box[1] + round(inner[1] * h)
    x1, y1 = box[0] + round(inner[2] * w), box[1] + round(inner[3] * h)
    region = img.crop((x0, y0, x1, y1)).convert("L")
    lum = np.asarray(region, dtype=np.float32)
    med = float(np.median(lum))
    letters = Image.fromarray(((lum < med - 28) | (lum > med + 22)).astype(np.uint8) * 255)
    lb = letters.filter(ImageFilter.MedianFilter(5)).filter(ImageFilter.MaxFilter(max(3, h // 10) | 1)).getbbox()
    if not lb:
        return img
    soft = max(3, h // 16)
    dst = (max(x0, x0 + lb[0] - 2 * soft), max(y0, y0 + lb[1] - soft), min(x1, x0 + lb[2] + 2 * soft), min(y1, y0 + lb[3] + soft))
    room_right, room_left = x1 - dst[2], dst[0] - x0
    sw = min(dst[2] - dst[0], max(room_right, room_left) - 8)
    src = ((dst[2] + 8, dst[1], dst[2] + 8 + sw, dst[3]) if room_right >= room_left
           else (dst[0] - 8 - sw, dst[1], dst[0] - 8, dst[3]))
    # the leather beside the letters, tiled over them with long cross-fades, laid in with a soft edge
    piece = img.convert("RGB").crop(src)
    ramp = max(8, piece.width // 3)
    fill = Image.new("RGB", (dst[2] - dst[0], dst[3] - dst[1]))
    x = 0
    while x < fill.width:
        m = Image.new("L", piece.size, 255)
        if x:
            m.paste(Image.linear_gradient("L").rotate(90, expand=True).transpose(Image.FLIP_LEFT_RIGHT).resize((ramp, piece.height)), (0, 0))
        fill.paste(piece if (x // (piece.width - ramp)) % 2 == 0 else piece.transpose(Image.FLIP_LEFT_RIGHT), (x, 0), m)
        x += piece.width - ramp
    m = Image.new("L", fill.size)
    ImageDraw.Draw(m).rectangle((soft, soft, fill.width - soft - 1, fill.height - soft - 1), fill=255)
    out = img.copy()
    rgb = out.convert("RGB")
    rgb.paste(fill, dst[:2], m.filter(ImageFilter.GaussianBlur(soft / 2)))
    rgb = rgb.convert("RGBA")
    rgb.putalpha(img.getchannel("A"))
    return rgb


def hires():
    import pieces
    work = f"{GEN}/hires/in"
    os.makedirs(path(work), exist_ok=True)
    lines = ["# Written by catalog.py: the hires pass, one render of each part.",
             "workflow: dev/imagegen/workflows/qwen21-inpaint.json", "count: 1", f"out: {GEN}/hires/raw"]
    todo = []
    for name, src in HIRES.items():
        if os.path.exists(path(f"{GEN}/hires/{name}.png")):
            continue
        img = Image.open(path(src)).convert("RGBA")
        if src.startswith(REFS):
            img = pieces.fill_holes(img)[0]
        if name in LABELS:
            img = label_off(img, LABELS[name])
        w, h = img.size
        W, H = (w * SCALE + 15) // 16 * 16, (h * SCALE + 15) // 16 * 16      # the model's latent wants 16s
        big = img.resize((W, H), Image.LANCZOS)
        flat = Image.new("RGBA", big.size, FLAT + (255,))
        flat.alpha_composite(big)
        flat.convert("RGB").save(path(f"{work}/{name}.png"))
        big.getchannel("A").save(path(f"{work}/{name}-alpha.png"))
        Image.new("RGB", big.size, (255, 255, 255)).save(path(f"{work}/{name}-mask.png"))
        lines += [f"ref: {work}/{name}.png, {work}/{name}-mask.png", f"{name}: {HIRES_WORDS}"]
        todo.append(name)
    if not todo:
        return
    lst = f"{work}/hires.txt"
    open(path(lst), "w").write("\n".join(lines) + "\n")
    run(lst, "--set", f"denoise={DENOISE}", "--set", "cfg=2.5", "--set", f"negative_prompt={NEGATIVE}")
    for name in todo:
        raw = Image.open(path(f"{GEN}/hires/raw/{name}-1.png")).convert("RGBA")
        alpha = Image.open(path(f"{work}/{name}-alpha.png"))
        raw.putalpha(alpha.resize(raw.size, Image.LANCZOS))
        if name == "window":   # the pass can bring back faint letters in #12's title label: its own paper again
            import clean
            dst, src = (334, 170, 556, 192), (562, 170, 700, 192)
            rgb = clean.apply(raw.convert("RGB"), "copy", (tuple(v * SCALE for v in dst), tuple(v * SCALE for v in src)))
            rgb.putalpha(raw.getchannel("A"))
            raw = rgb
        raw.save(path(f"{GEN}/hires/{name}.png"))


def masks():
    """The outside of the whole picks: the background removal's mask of each, once."""
    todo = [n for n in MASKS if not os.path.exists(path(f"{GEN}/hires/{n}-mask.png"))]
    if not todo:
        return
    lines = ["# Written by catalog.py: the outside of the whole picks.", "workflow: dev/imagegen/workflows/birefnet-mask.json",
             "count: 1", f"out: {GEN}/hires/raw"]
    for name in todo:
        lines += [f"ref: {GEN}/hires/{name}.png", f"{name}-mask: {name}"]
    lst = f"{GEN}/hires/in/masks.txt"
    open(path(lst), "w").write("\n".join(lines) + "\n")
    run(lst)
    for name in todo:
        Image.open(path(f"{GEN}/hires/raw/{name}-mask-1.png")).convert("L").save(path(f"{GEN}/hires/{name}-mask.png"))


def clean():
    for name in ("frame", "doll"):
        if not os.path.exists(path(f"{GEN}/clean/{name}.png")):
            subprocess.run(["python3", "dev/imagegen/sets/interface/clean.py", name], cwd=ROOT, check=True)


def pencil():
    subprocess.run(["python3", "dev/imagegen/sets/interface/pencil.py"], cwd=ROOT, check=True)


def pieces():
    subprocess.run(["python3", "dev/imagegen/sets/interface/pieces.py"], cwd=ROOT, check=True)


def views():
    subprocess.run(["python3", "dev/imagegen/sets/interface/compose.py", "--scale", "2"], cwd=ROOT, check=True)   # 4K
    subprocess.run(["python3", "dev/imagegen/sets/interface/gallery.py"], cwd=ROOT, check=True)


def status():
    """One line: parts made of all, masks, pieces, the full screen; "complete" when everything is there."""
    have = sum(os.path.exists(path(f"{GEN}/hires/{n}.png")) for n in HIRES)
    mask = sum(os.path.exists(path(f"{GEN}/hires/{n}-mask.png")) for n in MASKS)
    cut = os.path.exists(path(f"{GEN}/pieces/pieces.json"))
    full = os.path.exists(path(f"{GEN}/views/fullscreen.png"))
    done = have == len(HIRES) and mask == len(MASKS) and cut and full
    print(f"{'complete: ' if done else ''}{have} of {len(HIRES)} parts at 4K, {mask} of {len(MASKS)} masks, "
          f"pieces {'cut' if cut else 'not yet'}, full screen {'laid out' if full else 'not yet'}")


def rebuild():
    import shutil
    for d in ("clean", "hires", "pencil", "pieces", "views"):
        shutil.rmtree(path(f"{GEN}/{d}"), ignore_errors=True)
    print("forgotten: the next run makes everything anew")


STEPS = {"clean": clean, "hires": hires, "masks": masks, "pencil": pencil, "pieces": pieces, "views": views}

if __name__ == "__main__":
    sys.path.insert(0, HERE)
    if sys.argv[1:] == ["--status"]:
        status()
    elif sys.argv[1:] == ["--rebuild"]:
        rebuild()
    else:
        for step in sys.argv[1:] or STEPS:
            STEPS[step]()
