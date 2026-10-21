#!/usr/bin/env python3
"""Qwen against FLUX.2 [dev]: a page with the same windows from both side by side (qwen.txt, flux.txt), the
closed windows and the openings (anim.py) and the notes in notes.html beside this script.
  python3 dev/imagegen/sets/ui-compare/compare.py   ->  assets/generated/ui-compare/index.html
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "../../../../assets/generated/ui-compare")
MODELS = [("qwen", "Qwen-Image 2.1"), ("flux", "FLUX.2 [dev]")]


def thumb(rel):
    """A smaller copy for the page (the full picture opens on a click)."""
    src = os.path.join(OUT, rel)
    dst = os.path.join(OUT, "thumbs", rel.replace(".png", ".jpg"))
    if not os.path.exists(src):
        return None
    if not os.path.exists(dst) or os.path.getmtime(dst) < os.path.getmtime(src):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        im = Image.open(src).convert("RGB")
        im.thumbnail((900, 900))
        im.save(dst, quality=86)
    return os.path.relpath(dst, OUT)


def cell(rel, label):
    t = thumb(rel)
    if not t:
        return f'<figure class="none"><figcaption>{label}: not made</figcaption></figure>'
    return f'<figure><a href="{rel}" target="_blank"><img loading="lazy" src="{t}"></a><figcaption>{label}</figcaption></figure>'


def clip(rel, label):
    if not os.path.exists(os.path.join(OUT, rel)):
        return f'<figure class="none"><figcaption>{label}: not made</figcaption></figure>'
    return f'<figure><img loading="lazy" src="{rel}"><figcaption>{label}</figcaption></figure>'


def main():
    names = []
    for line in open(os.path.join(HERE, "prompts.txt")):
        if line[:1].isalpha() and ":" in line and not line.startswith("before:"):
            names.append(line.split(":", 1)[0])
    parts = []
    for name in names:
        row = "".join(cell(f"{m}/{name}-{s}.png", f"{label} · seed {s}") for m, label in MODELS for s in (1, 2))
        parts.append(f'<h3>{name}</h3><div class="row">{row}</div>')
    anims = []
    for d in sorted({n.split("-")[0] for n in names}):
        row = ""
        for m, label in MODELS:
            row += cell(f"closed-{m}/{d}-1.png", f"{label}: closed")
            row += clip(f"anim-{m}/{d}-1.gif", f"{label}: opening")
        anims.append(f'<h3>{d}</h3><div class="row">{row}</div>')
    notes_path = os.path.join(HERE, "notes.html")
    notes = open(notes_path).read() if os.path.exists(notes_path) else ""
    page = f"""<!doctype html><html><head><meta charset="utf-8"><title>Qwen or FLUX</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
:root{{--bg:#16140f;--fg:#e8e2d4;--dim:#9a917e;--card:#211e17;--line:#3a352b;--a:#d9b36a}}
body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,sans-serif}}
main{{max-width:1500px;margin:0 auto;padding:16px}}
h1{{font-weight:600}} h2{{margin-top:40px;border-bottom:1px solid var(--line);padding-bottom:6px}} h3{{color:var(--a);margin:22px 0 6px}}
.row{{display:grid;grid-template-columns:repeat(4,1fr);gap:8px}}
@media (max-width:900px){{.row{{grid-template-columns:repeat(2,1fr)}}}}
figure{{margin:0;background:var(--card);border-radius:6px;overflow:hidden}}
figure img{{width:100%;display:block}} figcaption{{padding:4px 8px;color:var(--dim);font-size:13px}}
figure.none{{display:flex;align-items:center;justify-content:center;min-height:80px}}
table{{border-collapse:collapse;width:100%;margin:8px 0}} td,th{{border:1px solid var(--line);padding:6px 8px;vertical-align:top;text-align:left}}
th{{color:var(--a);font-weight:600}} .notes{{max-width:1100px}}
</style></head><body><main>
<h1>Qwen-Image 2.1 or FLUX.2 [dev]</h1>
<div class="notes">{notes}</div>
<h2>The same windows from both</h2>
<p>Columns: Qwen seed 1 and 2, FLUX seed 1 and 2. A click opens the full picture.</p>
{''.join(parts)}
<h2>Opening, closed by each model's own edit, animated by Wan 2.2</h2>
<p>Each row: Qwen closed, Qwen opening, FLUX closed, FLUX opening. The motion is Wan's for both; what differs is
the art it starts and ends on, and how well each model keeps a window the same while closing it.</p>
{''.join(anims)}
</main></body></html>"""
    open(os.path.join(OUT, "index.html"), "w").write(page)
    print(os.path.abspath(os.path.join(OUT, "index.html")))


if __name__ == "__main__":
    main()
