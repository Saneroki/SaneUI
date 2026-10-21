#!/usr/bin/env python3
"""UI exploration: a page to look through what the model lists made (assets/generated/ui-explore/<model>/),
in the browser, with the stretch test of slice.py, the single elements and the silhouettes: every picture small, filtered by direction, view and model, a click shows it large, a heart
marks the liked ones (kept in the browser) and "Copy liked" puts their names on the clipboard, to name them
in the chat. Run it again after more pictures came in.
  python3 dev/imagegen/sets/ui-explore/gallery.py   ->  assets/generated/ui-explore/index.html
Another set's pictures: give its folder; each folder in it is a model (names <view>-<seed>.png or
<direction>-<view>-<seed>.png).
  python3 dev/imagegen/sets/ui-explore/gallery.py assets/generated/ui-fullscreen
"""
import html, json, os, sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(ROOT, "assets/generated/ui-explore")
MODELS = ["klein", "zimage", "qwen", "sdxl", "flux2dev"]
if len(sys.argv) > 1:
    MODELS = sorted(d for d in os.listdir(OUT) if os.path.isdir(os.path.join(OUT, d)) and d not in ("thumbs", "stretched"))


def pictures():
    # the model lists, their stretch tests, the single elements (elements.txt, Qwen) and the silhouettes
    # (shapes.txt, Z-Image: the shape as the direction, the material as the view)
    sources = [(m, m) for m in MODELS] + [(m, "stretched/" + m) for m in MODELS]
    if len(sys.argv) == 1:
        sources += [("qwen", "elements"), ("zimage", "shapes")]
    for model, sub in sources:
        folder = os.path.join(OUT, sub)
        if not os.path.isdir(folder):
            continue
        os.makedirs(os.path.join(OUT, "thumbs", sub), exist_ok=True)
        for name in sorted(os.listdir(folder)):
            if not name.endswith(".png") or name == "contact.png":
                continue
            stem = name[:-4]
            parts = stem.rsplit("-", 2)
            if len(parts) == 3 and not parts[1].isdigit():
                direction, view, seed = parts
            else:  # <view>-<seed>
                (direction, seed), view = stem.rsplit("-", 1), ""
            thumb = os.path.join("thumbs", sub, stem + ".jpg")
            path = os.path.join(OUT, thumb)
            if not os.path.exists(path) or os.path.getmtime(path) < os.path.getmtime(os.path.join(folder, name)):
                im = Image.open(os.path.join(folder, name)).convert("RGBA")
                ground = Image.new("RGBA", im.size, (92, 88, 80, 255))  # clear parts on a mid grey
                im = Image.alpha_composite(ground, im).convert("RGB")
                im.thumbnail((560, 560))
                im.save(path, quality=84)
            yield {"id": f"{model}/{stem}", "model": model, "direction": direction, "view": view, "seed": seed,
                   "full": f"{sub}/{name}", "thumb": thumb}


PAGE = """<!doctype html><html><head><meta charset="utf-8"><title>UI exploration</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
:root{--bg:#17150f;--card:#221f18;--fg:#e8e2d4;--dim:#9a917e;--on:#d9b36a}
body{margin:0;background:var(--bg);color:var(--fg);font:14px system-ui,sans-serif}
header{position:sticky;top:0;z-index:2;background:#100e0add;backdrop-filter:blur(6px);padding:10px 16px;border-bottom:1px solid #333}
.row{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin:4px 0}
.row b{width:76px;color:var(--dim);font-weight:500}
button{background:var(--card);color:var(--fg);border:1px solid #3a352b;border-radius:14px;padding:3px 10px;cursor:pointer;font:inherit}
button.on{border-color:var(--on);color:var(--on)}
main{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:10px;padding:12px 16px}
.c{background:var(--card);border-radius:8px;overflow:hidden;position:relative}
.c img{width:100%;display:block;cursor:zoom-in;aspect-ratio:4/3;object-fit:contain;background:#0c0b08}
.c div{padding:4px 8px;color:var(--dim);font-size:12px;display:flex;justify-content:space-between}
.h{position:absolute;top:6px;right:6px;font-size:20px;background:#0008;border:0;border-radius:50%;width:34px;height:34px;padding:0}
.h.on{color:#e0605a}
#big{position:fixed;inset:0;background:#000e;display:none;align-items:center;justify-content:center;z-index:5;flex-direction:column}
#big img{max-width:96vw;max-height:90vh}
#big p{color:var(--dim)}
</style></head><body>
<header><div class="row"><b>Direction</b><span id="direction"></span></div>
<div class="row"><b>View</b><span id="view"></span></div>
<div class="row"><b>Model</b><span id="model"></span></div>
<div class="row"><b></b><button id="liked">Only liked</button><button id="copy">Copy liked</button><span id="count"></span></div></header>
<main id="grid"></main><div id="big"><img><p></p></div>
<script>
const P = __DATA__;
const pick = {direction: new Set(), view: new Set(), model: new Set()};
let onlyLiked = false, liked = new Set();
try { liked = new Set(JSON.parse(localStorage.getItem("liked") || "[]")); } catch (e) {}
function save() { try { localStorage.setItem("liked", JSON.stringify([...liked])); } catch (e) {} }
for (const k of Object.keys(pick)) {
  const box = document.getElementById(k);
  for (const v of [...new Set(P.map(p => p[k]))]) {
    const b = document.createElement("button"); b.textContent = v;
    b.onclick = () => { pick[k].has(v) ? pick[k].delete(v) : pick[k].add(v); b.classList.toggle("on"); draw(); };
    box.append(b);
  }
}
document.getElementById("liked").onclick = e => { onlyLiked = !onlyLiked; e.target.classList.toggle("on"); draw(); };
document.getElementById("copy").onclick = () => navigator.clipboard.writeText([...liked].join("\\n"));
const big = document.getElementById("big"); big.onclick = () => big.style.display = "none";
function draw() {
  const g = document.getElementById("grid"); g.innerHTML = "";
  const shown = P.filter(p => Object.keys(pick).every(k => !pick[k].size || pick[k].has(p[k])) && (!onlyLiked || liked.has(p.id)));
  document.getElementById("count").textContent = shown.length + " shown, " + liked.size + " liked";
  for (const p of shown) {
    const c = document.createElement("div"); c.className = "c";
    c.innerHTML = `<img loading="lazy" src="${p.thumb}"><button class="h">&#9829;</button><div><span>${p.direction} · ${p.view}</span><span>${p.model} ${p.seed}</span></div>`;
    const h = c.querySelector(".h"); if (liked.has(p.id)) h.classList.add("on");
    h.onclick = () => { liked.has(p.id) ? liked.delete(p.id) : liked.add(p.id); h.classList.toggle("on"); save(); draw(); };
    c.querySelector("img").onclick = () => { big.querySelector("img").src = p.full; big.querySelector("p").textContent = p.id; big.style.display = "flex"; };
    g.append(c);
  }
}
draw();
</script></body></html>"""

if __name__ == "__main__":
    data = list(pictures())
    with open(os.path.join(OUT, "index.html"), "w") as f:
        f.write(PAGE.replace("__DATA__", json.dumps(data)))
    print(f"{len(data)} pictures: {os.path.join(os.path.abspath(OUT), 'index.html')}")
