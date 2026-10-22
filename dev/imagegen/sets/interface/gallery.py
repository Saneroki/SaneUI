#!/usr/bin/env python3
"""The harness's page (Doc/guides/interface-style.md): every element, view and polished view it made, numbered
from #1 so they can be named in a chat, small previews that open full screen on a click (arrow keys step,
Escape closes). Pictures with transparency are shown on grey. The numbers follow the order below and the
pictures' names; a new kind of output is added at the end, so the numbers already named stay.
  python3 dev/imagegen/sets/interface/gallery.py   ->  assets/generated/interface/index.html
It also writes pieces.html: only the final pieces code builds the interface from, at full quality, grouped, with
what pieces.json says of each, on a backdrop to choose (checks, the page's paper, dark, light), and the views built
from them.
"""
import glob, html, json, os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
OUT = os.path.join(ROOT, "assets/generated/interface")
# folder: title, what it shows
DECIDED = os.path.join(ROOT, "assets/Concept art/UI style")   # reached through the link OUT/decided
SECTIONS = [   # folder (in OUT, or DECIDED for "decided:"), the pictures in it, title, what it shows
    ("decided:", "*.png kit/*.png sketches/*.png elements/*.png", "Decided references",
     "only the sections Saneroki liked, cut out of their picks: the only pictures the harness may use"),
    ("clean", "*.png", "Picks cleaned",
     "clean.py: #12 without the strap over its paper and its label's writing; #3 without the rectangle, with stony ground"),
    ("views", "*.png", "Views laid out in code",
     "compose.py: from the final pieces: #12 as the window, the paper, pencil, Kalam, game icons; fullscreen.png at 4K"),
    ("hires", "*.png", "Parts in high resolution (4K)", "catalog.py hires: every decided part at twice its size"),
    ("variants", "*.png", "Variants to pick", "catalog.py variants: #14's pencil pieces, kit #17, #18, #24, #27, #28"),
    ("pencil", "*.png", "Pencil pieces", "pencil.py: the pencil lines alone, on transparency"),
    ("pieces", "*.png", "Final pieces (4K, transparent)",
     "pieces.py: every decided element at 4K, alone on transparency, for code to build any window from; how each is "
     "laid is in pieces.json; the full screen in Views is built from these alone"),
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
    link = os.path.join(OUT, "decided")
    if not os.path.islink(link):
        os.symlink(os.path.relpath(DECIDED, OUT), link)
    number, body, items = 0, [], []
    for folder, patterns, title, about in SECTIONS:
        base = os.path.join(OUT, "decided" if folder == "decided:" else folder)
        files = sorted(f for p in patterns.split() for f in glob.glob(os.path.join(base, p)) if not f.endswith("contact.png"))
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
    pieces_page()


GROUPS = [   # title, what it is, the pieces' name prefixes
    ("The window's frame", "one image round each window: the left edge, mirrored for the right and turned for the bottom, "
     "mitred corners with #12's metal caps, the top in three, the clasp", ("frame-",)),
    ("The character window", "#3 whole; code fills its slots and bends its columns along the arc", ("doll",)),
    ("Buttons and tabs", "#183's leather patch for every button and side tab, the arrow tabs and the patch tab, sliced in three",
     ("patch", "tab-")),
    ("Kit", "the cut-out metal and leather parts, kept whole or sliced as code needs", ("edge-", "kit")),
    ("Pencil", "the pencil box (nine slices) and its rule", ("pencil-",)),
    ("Paper", "the parchment, scaled to cover a page and cut, never stretched", ("paper",)),
    ("Sketches", "decorations laid faintly over the paper", ("sketch-",)),
    ("Stains", "coffee stains, faint, over the paper", ("stain",)),
]


def small(path, size=560):
    """A WebP preview that keeps the transparency, so the chosen backdrop shows through."""
    rel = os.path.relpath(path, OUT)
    out = os.path.join(OUT, "thumbs", "alpha", os.path.splitext(rel)[0] + ".webp")
    if not os.path.exists(out) or os.path.getmtime(out) < os.path.getmtime(path):
        img = Image.open(path).convert("RGBA")
        img.thumbnail((size, size), Image.LANCZOS)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        img.save(out, quality=92)
    return os.path.relpath(out, OUT)


def pieces_page():
    info = json.load(open(os.path.join(OUT, "pieces", "pieces.json")))["pieces"]
    left, body, items = dict(info), [], []

    def card(rel, name, w, h, how):
        i = len(items)
        items.append({"src": rel, "name": name, "w": w, "h": h, "how": how})
        return (f'<figure data-i="{i}"><div class="pic"><img loading="lazy" src="{html.escape(small(os.path.join(OUT, rel)))}" alt=""></div>'
                f'<figcaption><b>{html.escape(name)}</b> <span>{w} × {h}</span><br>{html.escape(how)}</figcaption></figure>')

    for title, about, prefixes in GROUPS:
        names = [n for n in info if n.startswith(prefixes) and n in left]
        cards = []
        for n in names:
            p = left.pop(n)
            cards.append(card("pieces/" + p["file"], n, p["size"][0], p["size"][1], p["how"]))
        if cards:
            body.append(f'<section><h2>{html.escape(title)} <small>{len(cards)}</small></h2><p>{html.escape(about)}</p>'
                        f'<div class="grid">{"".join(cards)}</div></section>')
    if left:
        body.append('<section><h2>Other</h2><div class="grid">' + "".join(
            card("pieces/" + p["file"], n, p["size"][0], p["size"][1], p["how"]) for n, p in left.items()) + '</div></section>')
    views = sorted(glob.glob(os.path.join(OUT, "views", "*.png")), key=lambda f: (not f.endswith("fullscreen.png"), f))
    if views:
        cards = []
        for f in views:
            w, h = Image.open(f).size
            cards.append(card(os.path.relpath(f, OUT), os.path.basename(f)[:-4], w, h, "laid out in code from the pieces above"))
        body.append('<section><h2>Built from them <small>4K</small></h2><p>compose.py: the views made from these pieces alone</p>'
                    f'<div class="grid">{"".join(cards)}</div></section>')
    page = PIECES.replace("{BODY}", "\n".join(body)).replace("{DATA}", json.dumps(items)).replace("{COUNT}", str(len(info)))
    open(os.path.join(OUT, "pieces.html"), "w").write(page)
    print(f"{len(info)} pieces: {os.path.relpath(os.path.join(OUT, 'pieces.html'), ROOT)}")


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

PIECES = """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Interface pieces</title><style>
:root { --bg: #16130f; --card: #221d17; --text: #e8dcc6; --dim: #a5967d; --accent: #d8b878;
  --back: repeating-conic-gradient(#8a8580 0 25%, #6e6964 0 50%) 0 0 / 24px 24px; }
body.paper { --back: #dccbb2; } body.dark { --back: #1d1915; } body.light { --back: #f4f1ec; }
body { margin: 0; background: var(--bg); color: var(--text); font: 15px/1.4 system-ui, sans-serif; }
header { position: sticky; top: 0; z-index: 2; background: var(--bg); padding: 14px 16px 10px; border-bottom: 1px solid #2e271f;
  display: flex; flex-wrap: wrap; gap: 8px 20px; align-items: center; }
h1 { margin: 0; font-size: 21px; } header p { margin: 0; color: var(--dim); flex: 1 1 320px; }
.backs button { background: var(--card); color: var(--text); border: 1px solid #3a3128; border-radius: 6px; padding: 5px 10px; cursor: pointer; font: inherit; }
.backs button.on { border-color: var(--accent); color: var(--accent); }
section { padding: 8px 16px 16px; } h2 { font-size: 18px; margin: 16px 0 2px; } h2 small { color: var(--dim); font-weight: 400; }
section > p { margin: 0 0 10px; color: var(--dim); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 12px; }
figure { margin: 0; background: var(--card); border-radius: 8px; overflow: hidden; cursor: zoom-in; }
figure:hover { outline: 2px solid var(--accent); }
.pic { background: var(--back); aspect-ratio: 4 / 3; display: flex; align-items: center; justify-content: center; padding: 10px; box-sizing: border-box; }
.pic img { max-width: 100%; max-height: 100%; display: block; }
figcaption { padding: 7px 9px 9px; font-size: 13px; color: var(--dim); overflow-wrap: anywhere; }
figcaption b { color: var(--accent); font-size: 15px; } figcaption span { color: var(--text); }
#view { position: fixed; inset: 0; z-index: 5; background: rgba(0,0,0,.95); display: none; flex-direction: column; }
#view.on { display: flex; }
#bar { padding: 10px 70px 8px 16px; } #bar b { color: var(--accent); font-size: 18px; } #bar span { color: var(--dim); }
#stage { flex: 1; overflow: auto; display: flex; } #stage img { margin: auto; background: var(--back); display: block; cursor: zoom-in; }
#stage.fit img { max-width: calc(100vw - 130px); max-height: calc(100vh - 90px); }
#stage:not(.fit) img { cursor: zoom-out; }
#view > button { position: fixed; background: rgba(255,255,255,.08); color: #fff; border: 0; cursor: pointer; border-radius: 6px; }
#prev, #next { top: 50%; transform: translateY(-50%); font-size: 32px; width: 52px; height: 80px; }
#prev { left: 8px; } #next { right: 8px; } #close { top: 8px; right: 8px; width: 48px; height: 44px; font-size: 22px; }
</style></head><body>
<header><h1>Interface pieces</h1>
<p>The {COUNT} final pieces code builds the interface from, at 4K, on transparency. Click one for full quality; click again for its true pixels; arrows step, Escape closes.</p>
<div class="backs">Backdrop: <button data-b="">checks</button><button data-b="paper">page paper</button><button data-b="dark">dark</button><button data-b="light">light</button></div></header>
{BODY}
<div id="view"><div id="bar"></div><div id="stage" class="fit"><img alt=""></div>
<button id="prev">&#8249;</button><button id="next">&#8250;</button><button id="close">&#10005;</button></div>
<script>
const items = {DATA}, view = document.getElementById("view"), stage = document.getElementById("stage"), img = stage.querySelector("img"),
  bar = document.getElementById("bar"), esc = t => t.replace(/[&<>]/g, c => ({"&": "&amp;", "<": "&lt;", ">": "&gt;"})[c]);
let at = 0;
function show(i) { at = (i + items.length) % items.length; const it = items[at]; stage.classList.add("fit"); img.src = it.src;
  bar.innerHTML = `<b>${esc(it.name)}</b> <span>${it.w} × ${it.h} px at 4K (${Math.round(it.w / 2)} × ${Math.round(it.h / 2)} at 1080p) · ${esc(it.how)}</span>`;
  view.classList.add("on"); }
document.querySelectorAll("figure").forEach(f => f.onclick = () => show(+f.dataset.i));
img.onclick = () => stage.classList.toggle("fit");
document.getElementById("prev").onclick = () => show(at - 1);
document.getElementById("next").onclick = () => show(at + 1);
document.getElementById("close").onclick = () => view.classList.remove("on");
stage.onclick = e => { if (e.target === stage) view.classList.remove("on"); };
document.onkeydown = e => { if (!view.classList.contains("on")) return;
  if (e.key === "Escape") view.classList.remove("on"); else if (e.key === "ArrowLeft") show(at - 1); else if (e.key === "ArrowRight") show(at + 1); };
function back(b) { document.body.className = b; document.querySelectorAll(".backs button").forEach(x => x.classList.toggle("on", x.dataset.b === b));
  try { localStorage.setItem("back", b); } catch (e) {} }
document.querySelectorAll(".backs button").forEach(x => x.onclick = () => back(x.dataset.b));
let saved = ""; try { saved = localStorage.getItem("back") || ""; } catch (e) {} back(saved);
</script></body></html>
"""

if __name__ == "__main__":
    main()
