#!/usr/bin/env python3
"""UI exploration: does a model's frame stretch? Each stretchable frame of the model lists
(assets/generated/ui-explore/<model>/*-frame-*.png) is cut out of its grey ground, cut into nine pieces at a
quarter of its shorter side, and drawn at four sizes the way the game stretches a texture with slice
margins (texture:SetTextureSliceMargins: the corners kept, the edges and the middle stretched), wide, tall,
small and square, beside the picture itself. A frame whose edges are even holds at every size; one whose
ornament runs along its edges smears. Written to assets/generated/ui-explore/stretched/<model>/, which the
gallery shows as the view "stretched".
  python3 dev/imagegen/sets/ui-explore/slice.py
"""
import os
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
OUT = os.path.join(ROOT, "assets/generated/ui-explore")
MODELS = ["klein", "zimage", "qwen", "sdxl", "flux2dev"]
SIZES = [(760, 250), (250, 520), (230, 170), (420, 420)]  # wide, tall, small, square
MARGIN = 0.25  # the corners: this much of the frame's shorter side


def cut(img):
    """The frame without its ground: flooded from the edges of the picture. If the ground is no plain colour
    (the flood takes too little), the picture as it is."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    flood = rgb.copy()
    for c in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
        if flood.getpixel(c) != (255, 0, 255):
            ImageDraw.floodfill(flood, c, (255, 0, 255), thresh=24)
    ground = ImageChops.difference(flood, Image.new("RGB", (w, h), (255, 0, 255))).convert("L").point(lambda v: 255 if v < 4 else 0)
    if ground.histogram()[255] < w * h * 0.08:
        return rgb.convert("RGBA")
    alpha = ImageChops.invert(ground).filter(ImageFilter.MinFilter(3))
    part = rgb.convert("RGBA")
    part.putalpha(alpha)
    return part.crop(alpha.getbbox() or (0, 0, w, h))


def nine(src, size, m):
    """src drawn at size with its corners m wide kept and the rest stretched."""
    w, h = src.size
    W, H = size
    m = min(m, W // 2 - 1, H // 2 - 1)
    xs, Xs = [0, m, w - m, w], [0, m, W - m, W]
    ys, Ys = [0, m, h - m, h], [0, m, H - m, H]
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    for i in range(3):
        for j in range(3):
            box = (xs[i], ys[j], xs[i + 1], ys[j + 1])
            dst = (Xs[i + 1] - Xs[i], Ys[j + 1] - Ys[j])
            if min(dst) > 0 and box[2] > box[0] and box[3] > box[1]:
                out.paste(src.crop(box).resize(dst, Image.LANCZOS), (Xs[i], Ys[j]))
    return out


def sheet(path):
    frame = cut(Image.open(path))
    k = 300 / min(frame.size)
    frame = frame.resize((max(1, int(frame.width * k)), max(1, int(frame.height * k))), Image.LANCZOS)
    m = int(min(frame.size) * MARGIN * 0.55)  # drawn smaller than the source: the corners at about 40 units
    small = frame.resize((int(frame.width * 0.55), int(frame.height * 0.55)), Image.LANCZOS)
    canvas = Image.new("RGBA", (1240, 820), (46, 42, 36, 255))
    canvas.alpha_composite(frame.resize((int(frame.width * 300 / frame.height), 300)) if frame.height > frame.width else frame.resize((300, int(frame.height * 300 / frame.width))), (20, 20))
    spots = [(360, 20), (20, 340), (300, 340), (560, 340)]
    for (x, y), size in zip(spots, SIZES):
        canvas.alpha_composite(nine(small, size, m), (x, y))
    return canvas.convert("RGB")


if __name__ == "__main__":
    n = 0
    for model in MODELS:
        folder = os.path.join(OUT, model)
        if not os.path.isdir(folder):
            continue
        os.makedirs(os.path.join(OUT, "stretched", model), exist_ok=True)
        for name in sorted(os.listdir(folder)):
            if "-frame-" in name and name.endswith(".png"):
                sheet(os.path.join(folder, name)).save(os.path.join(OUT, "stretched", model, name.replace("-frame-", "-stretched-")))
                n += 1
    print(f"{n} frames stretched")
