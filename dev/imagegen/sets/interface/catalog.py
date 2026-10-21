#!/usr/bin/env python3
"""The interface's whole render (Doc/guides/interface-style.md, *The harness* and *High resolution*): run by the GPU
runner as its job "interface" (dev/imagegen/jobs.toml). Each step skips what it has made, so a stopped run goes on
where it stopped; --rebuild starts anew from the decided references (after a decision changed).

  clean     the decided pictures cleaned (clean.py: #12 and #3)  ->  assets/generated/interface/clean/

  hires     every decided part at twice its size, the scale of a 4K screen: upscaled in code (Lanczos), then one
            gentle pass of Qwen over the whole picture (qwen21-inpaint.json with a full mask, low denoise), which
            sharpens its detail and keeps everything where it is; transparency put back from the upscaled source
            ->  assets/generated/interface/hires/<part>.png
  variants  new variants of decided parts, from their cut-out alone (qwen21-edit-1ref), transparent:
            #14's pencil box (sections, rules and corners on the paper), and kit parts #17, #18, #24, #27 and #28
            with their light inset lines  ->  assets/generated/interface/variants/<name>-<seed>.png, then pencil.py
            turns the pencil ones into graphite lines

  pencil    the pencil lines of #14 and of the pencil variants (pencil.py)  ->  .../pencil/
  views     the views laid out in code (compose.py)  ->  .../views/, then the gallery (gallery.py)

  python3 dev/imagegen/sets/interface/catalog.py [clean|hires|variants|pencil|views ...]
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
    "band": f"{REFS}/kit/kit3-09.png",
    "panel-framed": f"{REFS}/kit/kit3-01.png",           # #17
    "banner": f"{REFS}/kit/kit3-02.png",                 # #18
    "slider": f"{REFS}/kit/kit3-08.png",                 # #24
    "slider-blade": f"{REFS}/kit/kit3-11.png",           # #27
    "banners": f"{REFS}/kit/kit4-01.png",                # #28
}
HIRES_WORDS = ("Exactly the same picture in higher resolution: every shape, line, colour, texture and stitch where it "
               "is, only sharper and finer, clean and crisp. Nothing added, nothing removed, no text.")
NEGATIVE = "blurry, smeared, noise, artifacts, extra objects, text, letters, watermark, changed shape"

# name: (decided cut-out, what to vary, seeds)
VARIANTS = {
    "pencil-box": (f"{REFS}/elements/top-tab-drawn-1.png",
                   "a different box drawn the same way: the same clean double pencil line and rounded corners, as a "
                   "wide section frame; plain paper inside, nothing written", 3),
    "pencil-rule": (f"{REFS}/elements/top-tab-drawn-1.png",
                    "only a long straight double pencil line drawn the same way, with a small flourish at each end, "
                    "as a divider between sections; plain paper", 3),
    "pencil-corner": (f"{REFS}/elements/top-tab-drawn-1.png",
                      "only one corner drawn the same way: the double pencil line turning a rounded corner, as the "
                      "corner piece of a large frame; plain paper", 3),
    "panel-framed": (f"{REFS}/kit/kit3-01.png",
                     "a variation of this framed paper panel with the same leather, metal corners and light inset "
                     "lines, in another proportion", 3),
    "banner": (f"{REFS}/kit/kit3-02.png",
               "a variation of this hanging leather banner with the same light inset lines and stitching, its tail "
               "cut differently", 3),
    "slider": (f"{REFS}/kit/kit3-08.png",
               "a variation of this slider bar with the same metal, leather and light inset line, its knob shaped "
               "differently", 3),
    "slider-blade": (f"{REFS}/kit/kit3-11.png",
                     "a variation of this blade-shaped bar with the same metal, leather and light inset line", 3),
    "banners": (f"{REFS}/kit/kit4-01.png",
                "a variation of these hanging leather banners with the same light inset lines and stitching", 3),
}
VARIANT_BEFORE = ("This is an RGBA format image with transparency. It has an alpha channel and a transparent background. "
                  "Image 1 is a cut-out of one part of a game interface. Make, alone on the transparent background, "
                  "seen straight from the front, in exactly its material, colours, line weight and finish:")


def path(rel):
    return os.path.join(ROOT, rel)


def run(lst, *extra):
    subprocess.run(["dev/tools/imagegen", lst, *extra], cwd=ROOT, check=True)


def hires():
    work = f"{GEN}/hires/in"
    os.makedirs(path(work), exist_ok=True)
    lines = ["# Written by catalog.py: the hires pass.", "workflow: dev/imagegen/workflows/qwen21-inpaint.json",
             "count: 1", f"out: {GEN}/hires/raw"]
    todo = []
    for name, src in HIRES.items():
        if os.path.exists(path(f"{GEN}/hires/{name}.png")):
            continue
        img = Image.open(path(src)).convert("RGBA")
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
            sys.path.insert(0, HERE)
            import clean
            dst, src = (334, 170, 556, 192), (562, 170, 700, 192)
            rgb = clean.apply(raw.convert("RGB"), "copy", (tuple(v * SCALE for v in dst), tuple(v * SCALE for v in src)))
            rgb.putalpha(raw.getchannel("A"))
            raw = rgb
        raw.save(path(f"{GEN}/hires/{name}.png"))


def variants():
    out = f"{GEN}/variants"
    lines = ["# Written by catalog.py: variants of decided parts to pick from.",
             "workflow: qwen21-edit-1ref", "set: width=1536, height=1024", f"out: {out}", "count: 3",
             "flatten: #76706a", f"before: {VARIANT_BEFORE}"]
    todo = [n for n in VARIANTS if not os.path.exists(path(f"{out}/{n}-3.png"))]
    if not todo:
        return
    for name in todo:
        src, words, _ = VARIANTS[name]
        lines += [f"ref: {src}", f"{name}: {words}"]
    os.makedirs(path(out), exist_ok=True)
    lst = f"{GEN}/hires/variants.txt"
    os.makedirs(os.path.dirname(path(lst)), exist_ok=True)
    open(path(lst), "w").write("\n".join(lines) + "\n")
    run(lst)


def clean():
    for name in ("frame", "doll"):
        if not os.path.exists(path(f"{GEN}/clean/{name}.png")):
            subprocess.run(["python3", "dev/imagegen/sets/interface/clean.py", name], cwd=ROOT, check=True)


def pencil():
    subprocess.run(["python3", "dev/imagegen/sets/interface/pencil.py"], cwd=ROOT, check=True)


def views():
    subprocess.run(["python3", "dev/imagegen/sets/interface/compose.py"], cwd=ROOT, check=True)
    subprocess.run(["python3", "dev/imagegen/sets/interface/gallery.py"], cwd=ROOT, check=True)


def status():
    """One line: parts and variants made of all; "complete" when everything is there."""
    have = sum(os.path.exists(path(f"{GEN}/hires/{n}.png")) for n in HIRES)
    var = sum(os.path.exists(path(f"{GEN}/variants/{n}-{seeds}.png")) for n, (_, _, seeds) in VARIANTS.items())
    views_ = os.path.exists(path(f"{GEN}/views/guild.png"))
    done = have == len(HIRES) and var == len(VARIANTS) and views_
    print(f"{'complete: ' if done else ''}{have} of {len(HIRES)} parts at 4K, {var} of {len(VARIANTS)} variants, "
          f"views {'laid out' if views_ else 'not yet'}")


def rebuild():
    import shutil
    for d in ("clean", "hires", "variants", "pencil"):
        shutil.rmtree(path(f"{GEN}/{d}"), ignore_errors=True)
    print("forgotten: the next run makes everything anew")


STEPS = {"clean": clean, "hires": hires, "variants": variants, "pencil": pencil, "views": views}

if __name__ == "__main__":
    if sys.argv[1:] == ["--status"]:
        status()
    elif sys.argv[1:] == ["--rebuild"]:
        rebuild()
    else:
        for step in sys.argv[1:] or STEPS:
            STEPS[step]()
