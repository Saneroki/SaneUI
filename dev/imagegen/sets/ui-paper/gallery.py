#!/usr/bin/env python3
"""A page of this set's pictures, numbered so they can be named in a chat ("#12"): the stills and the appearing
clips by list, small previews that open full screen on a click (arrow keys step, Escape closes). The numbers
follow the order below and the pictures' names, so they stay the same while nothing new is rendered.
  python3 dev/imagegen/sets/ui-paper/gallery.py   ->  assets/generated/ui-paper/index.html
"""
import glob, html, os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
OUT = os.path.join(ROOT, "assets/generated/ui-paper")
# folder: title, what it shows
SECTIONS = [
    ("quick", "Doll with quick stats", "the picked doll (dolls/doll-hug-2) with a strip of quick stats outside each slot"),
    ("windows", "Windows", "leather and metal outside, pencil borders on the paper, leather patch buttons"),
    ("appear", "Appearing", "from nothing to the open window in about 0.2 s, then the still; appear = Wan, drawn = made in code"),
    ("dolls", "Dolls", "the three 20-slot layouts, first round of the look"),
    ("dolls-ref", "Dolls with a material reference", "the same, with the journal screen for the materials"),
    ("panels", "Panels", "first round of the look"),
    ("screens", "Full screens", "first round of the look, through the prompt enhancer"),
    # new rounds go after the others, so the numbers already named stay
    ("doll2", "Doll with header and tabs", "#3 with a leather header, tabs down the left, fainter sketches"),
    ("windows2-ref", "Windows in #57's look", "Qwen's edit with #57 as the reference for the look"),
    ("windows2", "Windows from words", "the look of #57 described in words"),
    ("views", "Doll, stats, spellbook, chat", "from words: #57's pages bound in the stitched leather"),
    ("views-ref", "Doll, stats, spellbook, chat (references)", "Qwen's edit with #57 and the leather window as references"),
    ("guild", "Guild window", "from words: board with podium, members, armory, race, crafting"),
    ("guild-ref", "Guild window (references)", "Qwen's edit with #57 and the leather window as references"),
    ("doll-final", "Doll, final layout", "the decided layout drawn in code; look from views-ref/doll-1 (leather) or #3 (liked)"),
    ("chat-compact", "Compact chat bubbles", "two lines each, paper and pencil only"),
    ("paper", "Paper", "tileable grain, clouds, coffee stains with transparency"),
    ("doll-final-words", "Doll, final layout (guide only)", "the decided layout, the look in words, no second picture"),
    ("paper-test", "Paper laid out", "the seamless grain tile, 2 x 2, and windows of three sizes"),
]


def thumb(path):
    """A small JPEG beside the gallery for the grid (a clip's first frame would be empty: its last is taken)."""
    rel = os.path.relpath(path, OUT)
    small = os.path.join(OUT, "thumbs", os.path.splitext(rel)[0] + ".jpg")
    if not os.path.exists(small) or os.path.getmtime(small) < os.path.getmtime(path):
        img = Image.open(path)
        if getattr(img, "n_frames", 1) > 1:
            img.seek(img.n_frames - 1)
        img = img.convert("RGB")
        img.thumbnail((640, 640))
        os.makedirs(os.path.dirname(small), exist_ok=True)
        img.save(small, quality=85)
    return os.path.relpath(small, OUT)


def main():
    number, body, items = 0, [], []
    for folder, title, about in SECTIONS:
        if folder == "appear":
            files = sorted(glob.glob(os.path.join(OUT, folder, "*-appear.gif")) + glob.glob(os.path.join(OUT, folder, "*-drawn.gif")))
        else:
            files = sorted(f for f in glob.glob(os.path.join(OUT, folder, "*.png")) if not f.endswith("contact.png"))
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
<title>Paper look</title><style>
:root { --bg: #16130f; --card: #221d17; --text: #e8dcc6; --dim: #a5967d; --accent: #d8b878; }
body { margin: 0; background: var(--bg); color: var(--text); font: 15px/1.4 system-ui, sans-serif; }
header { padding: 20px 16px 4px; } h1 { margin: 0; font-size: 22px; } header p { margin: 4px 0 0; color: var(--dim); }
section { padding: 8px 16px 16px; } h2 { font-size: 18px; margin: 18px 0 2px; } section > p { margin: 0 0 10px; color: var(--dim); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 12px; }
figure { margin: 0; background: var(--card); border-radius: 8px; overflow: hidden; cursor: zoom-in; }
figure img { display: block; width: 100%; aspect-ratio: 1; object-fit: contain; background: #000; }
figure:hover { outline: 2px solid var(--accent); }
figcaption { padding: 6px 8px; font-size: 13px; color: var(--dim); overflow-wrap: anywhere; } figcaption b { color: var(--accent); font-size: 16px; } a { color: var(--accent); }
#view { position: fixed; inset: 0; background: rgba(0,0,0,.94); display: none; align-items: center; justify-content: center; }
#view.on { display: flex; } #view img { max-width: 100vw; max-height: calc(100vh - 44px); object-fit: contain; }
#view .label { position: fixed; top: 0; left: 0; right: 0; padding: 10px 16px; color: var(--accent); font-size: 18px; font-weight: 600; }
#view button { position: fixed; top: 50%; transform: translateY(-50%); background: rgba(255,255,255,.08); color: #fff; border: 0;
  font-size: 32px; width: 52px; height: 80px; cursor: pointer; border-radius: 6px; }
#prev { left: 8px; } #next { right: 8px; } #close { top: 26px !important; right: 8px; height: 44px !important; font-size: 24px !important; }
</style></head><body>
<header><h1>Paper look</h1><p>Click a picture for full screen; arrow keys step, Escape closes. Name them by number. <a href="fonts.html">Pencil fonts</a></p></header>
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
