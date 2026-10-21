#!/usr/bin/env python3
"""The harness's page (Doc/guides/interface-style.md): every element, view and polished view it made, numbered
from #1 so they can be named in a chat, small previews that open full screen on a click (arrow keys step,
Escape closes). Pictures with transparency are shown on grey. The numbers follow the order below and the
pictures' names; a new kind of output is added at the end, so the numbers already named stay.
  python3 dev/imagegen/sets/interface/gallery.py   ->  assets/generated/interface/index.html
"""
import glob, html, os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
OUT = os.path.join(ROOT, "assets/generated/interface")
# folder: title, what it shows
SECTIONS = [   # folder, the pictures in it, title, what it shows
    ("elements", "edge-*.png patch-wide-*.png top-tab-drawn-*.png top-tab-patch-*.png", "Elements in use",
     "approved by Saneroki: the edges, the patch for every button, the drawn tab's lines, the patch tab"),
    ("elements", "dropdown-band-*.png top-tab-arrow-*.png", "New elements to pick",
     "dropdown bands with an empty inside for code inlays; the patch tab as an arrow with worn, stitched ends"),
    ("views", "*.png", "Views laid out in code",
     "compose.py: the elements sliced and repeated, the paper, pencil lines, Kalam, pressed leather titles, game icons"),
    ("polished", "*.png", "Views polished", "polish.txt: one light pass by Qwen's edit over each laid-out view"),
]


def thumb(path):
    """A small JPEG beside the gallery for the grid (a clip's first frame would be empty: its last is taken)."""
    rel = os.path.relpath(path, OUT)
    small = os.path.join(OUT, "thumbs", os.path.splitext(rel)[0] + ".jpg")
    if not os.path.exists(small) or os.path.getmtime(small) < os.path.getmtime(path):
        img = Image.open(path)
        if getattr(img, "n_frames", 1) > 1:
            img.seek(img.n_frames - 1)
        if img.mode in ("RGBA", "LA", "P"):
            img = img.convert("RGBA")
            grey = Image.new("RGBA", img.size, (118, 110, 100, 255))
            grey.alpha_composite(img)
            img = grey
        img = img.convert("RGB")
        img.thumbnail((640, 640))
        os.makedirs(os.path.dirname(small), exist_ok=True)
        img.save(small, quality=85)
    return os.path.relpath(small, OUT)


def main():
    number, body, items = 0, [], []
    for folder, patterns, title, about in SECTIONS:
        files = sorted(f for p in patterns.split() for f in glob.glob(os.path.join(OUT, folder, p)) if not f.endswith("contact.png"))
        if not files:
            continue
        cards = []
        for f in files:
            number += 1
            rel = os.path.relpath(f, OUT)
            label = f"#{number} {rel}"
            items.append((rel, label))
            cards.append(f'<figure data-i="{number - 1}"><img loading="lazy" src="{html.escape(thumb(f))}" alt="">'
                         f'<figcaption><b>#{number}</b> {html.escape(rel)}</figcaption></figure>')
        body.append(f'<section><h2>{html.escape(title)}</h2><p>{html.escape(about)}</p><div class="grid">{"".join(cards)}</div></section>')
    data = ",".join(f'["{html.escape(r)}","{html.escape(l)}"]' for r, l in items)
    page = PAGE.replace("{BODY}", "\n".join(body)).replace("{DATA}", data)
    open(os.path.join(OUT, "index.html"), "w").write(page)
    print(f"{number} pictures: {os.path.relpath(os.path.join(OUT, 'index.html'), ROOT)}")


PAGE = """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Interface harness</title><style>
:root { --bg: #16130f; --card: #221d17; --text: #e8dcc6; --dim: #a5967d; --accent: #d8b878; }
body { margin: 0; background: var(--bg); color: var(--text); font: 15px/1.4 system-ui, sans-serif; }
header { padding: 20px 16px 4px; } h1 { margin: 0; font-size: 22px; } header p { margin: 4px 0 0; color: var(--dim); }
section { padding: 8px 16px 16px; } h2 { font-size: 18px; margin: 18px 0 2px; } section > p { margin: 0 0 10px; color: var(--dim); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 12px; }
figure { margin: 0; background: var(--card); border-radius: 8px; overflow: hidden; cursor: zoom-in; }
figure img { display: block; width: 100%; aspect-ratio: 1; object-fit: contain; background: #76706a; }
figure:hover { outline: 2px solid var(--accent); }
figcaption { padding: 6px 8px; font-size: 13px; color: var(--dim); overflow-wrap: anywhere; } figcaption b { color: var(--accent); font-size: 16px; } a { color: var(--accent); }
#view { position: fixed; inset: 0; background: rgba(0,0,0,.94); display: none; align-items: center; justify-content: center; }
#view.on { display: flex; } #view img { background: #76706a; max-width: 100vw; max-height: calc(100vh - 44px); object-fit: contain; }
#view .label { position: fixed; top: 0; left: 0; right: 0; padding: 10px 16px; color: var(--accent); font-size: 18px; font-weight: 600; }
#view button { position: fixed; top: 50%; transform: translateY(-50%); background: rgba(255,255,255,.08); color: #fff; border: 0;
  font-size: 32px; width: 52px; height: 80px; cursor: pointer; border-radius: 6px; }
#prev { left: 8px; } #next { right: 8px; } #close { top: 26px !important; right: 8px; height: 44px !important; font-size: 24px !important; }
</style></head><body>
<header><h1>Interface harness</h1><p>Click a picture for full screen; arrow keys step, Escape closes. Name them by number.</p></header>
{BODY}
<div id="view"><div class="label"></div><img alt=""><button id="prev">&#8249;</button><button id="next">&#8250;</button><button id="close">&#10005;</button></div>
<script>
const items = [{DATA}], view = document.getElementById("view"), img = view.querySelector("img"), label = view.querySelector(".label");
let at = 0;
function show(i) { at = (i + items.length) % items.length; img.src = items[at][0]; label.textContent = items[at][1]; view.classList.add("on"); }
document.querySelectorAll("figure").forEach(f => f.onclick = () => show(+f.dataset.i));
document.getElementById("prev").onclick = e => { e.stopPropagation(); show(at - 1); };
document.getElementById("next").onclick = e => { e.stopPropagation(); show(at + 1); };
document.getElementById("close").onclick = () => view.classList.remove("on");
view.onclick = e => { if (e.target === view) view.classList.remove("on"); };
document.onkeydown = e => { if (!view.classList.contains("on")) return;
  if (e.key === "Escape") view.classList.remove("on"); else if (e.key === "ArrowLeft") show(at - 1); else if (e.key === "ArrowRight") show(at + 1); };
</script></body></html>
"""

if __name__ == "__main__":
    main()
