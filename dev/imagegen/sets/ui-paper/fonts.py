#!/usr/bin/env python3
"""A page of handwritten fonts for the paper look (Saneroki, 2026-10-21): simple, readable hand-printed letters
(not cursive) set on parchment in pencil grey, with the kind of text the windows hold (names and levels, stats,
a chat bubble, numbers), numbered F1, F2, ... so they can be named in a chat. The fonts are loaded from Google
Fonts by the browser; "grain" lays a paper grain over the writing, as a paper texture over the text would in the
game (a font string itself takes only a colour and a shadow).
  python3 dev/imagegen/sets/ui-paper/fonts.py   ->  assets/generated/ui-paper/fonts.html
"""
import html, os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../../assets/generated/ui-paper/fonts.html")

# name on Google Fonts, its weights, a word on its hand
FONTS = [
    ("Patrick Hand", "400", "even, upright print; very clear at small sizes"),
    ("Kalam", "300;400;700", "a pencil-like print, three weights"),
    ("Architects Daughter", "400", "a draughtsman's capitals and small letters"),
    ("Gaegu", "300;400;700", "soft, round, light"),
    ("Handlee", "400", "relaxed upright print"),
    ("Gochi Hand", "400", "bold marker-like print"),
    ("Coming Soon", "400", "wide, plain, airy"),
    ("Schoolbell", "400", "loose school print"),
    ("Short Stack", "400", "chunky, very legible"),
    ("Delius", "400;700", "neat, almost a book face"),
    ("Neucha", "400", "narrow, slightly rough"),
    ("Annie Use Your Telescope", "400", "thin, quick, light"),
    ("Itim", "400", "smooth, round print"),
    ("Mali", "300;400;600", "rounded, several weights"),
    ("Indie Flower", "400", "loose and round"),
    ("Covered By Your Grace", "400", "narrow, pencil-quick"),
    ("Just Another Hand", "400", "tall and narrow; fits much in a line"),
    ("Nanum Pen Script", "400", "narrow pen print"),
    ("Shadows Into Light Two", "400", "slanted but not joined"),
    ("Amatic SC", "400;700", "tall narrow capitals, for headings"),
    ("Cabin Sketch", "400;700", "sketched, hatched letters, for headings"),
]

SAMPLE = """<div class="rows">
<div><span class="dot"></span>Elowen Ashgrove <i>Lvl 58</i><b>Raid leader</b></div>
<div><span class="dot off"></span>Brannoc Steelhand <i>Lvl 60</i><b>Officer</b></div>
<div><span class="dot"></span>Mira Thistlewood <i>Lvl 37</i><b>Alchemy 285</b></div>
</div>
<div class="stats"><span>Strength</span><b>142</b><span>Agility</span><b>87</b><span>Stamina</span><b>215</b>
<span>Armor</span><b>3,412</b><span>Crit chance</span><b>6.48 %</b><span>Item level</span><b>63</b></div>
<div class="bubble"><small>[Guild] Brannoc Steelhand · 20:41</small>Anyone up for Blackrock Depths? Need a healer, leaving in ten minutes.</div>
<div class="nums">0 1 2 3 4 5 6 7 8 9 · 12 g 45 s 3 c · 1/4 · 58% · Il1 O0 rn m</div>"""


def main():
    families = "&".join("family=" + n.replace(" ", "+") + (":wght@" + w if ";" in w else "") for n, w, _ in FONTS)
    cards = []
    for i, (name, weights, about) in enumerate(FONTS, 1):
        cards.append(f'<section class="card" style="--f:\'{html.escape(name)}\'"><h2><b>F{i}</b> {html.escape(name)}'
                     f'<span>{html.escape(about)}; weights {weights.replace(";", ", ")}</span></h2>'
                     f'<div class="paper"><div class="title">Guild Roster · Character · Spellbook</div>{SAMPLE}</div></section>')
    page = PAGE.replace("{FAMILIES}", families).replace("{CARDS}", "\n".join(cards))
    open(OUT, "w").write(page)
    print(f"{len(FONTS)} fonts: {os.path.relpath(OUT, os.path.join(os.path.dirname(OUT), '../../..'))}")


PAGE = """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pencil fonts</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?{FAMILIES}&display=swap">
<style>
:root { --bg: #16130f; --text: #e8dcc6; --dim: #a5967d; --accent: #d8b878; --lead: #3b3631; --size: 20px; }
body { margin: 0; background: var(--bg); color: var(--text); font: 15px/1.4 system-ui, sans-serif; }
header { padding: 18px 16px 8px; position: sticky; top: 0; background: var(--bg); z-index: 2; border-bottom: 1px solid #2c261f; }
h1 { margin: 0 0 6px; font-size: 22px; } header p { margin: 0 0 8px; color: var(--dim); }
label { margin-right: 18px; color: var(--dim); white-space: nowrap; } input[type=range] { vertical-align: middle; }
main { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 420px), 1fr)); gap: 14px; padding: 14px 16px 30px; }
.card h2 { font-size: 16px; margin: 0 0 6px; font-weight: 500; } .card h2 b { color: var(--accent); font-size: 20px; margin-right: 4px; }
.card h2 span { display: block; color: var(--dim); font-size: 13px; }
.paper { position: relative; padding: 14px 16px; border-radius: 3px; color: var(--lead); font-family: var(--f), cursive;
  font-size: var(--size); line-height: 1.25; background-color: #e8dabd;
  background-image: radial-gradient(ellipse at 30% 20%, rgba(255,250,235,.55), transparent 60%),
    radial-gradient(ellipse at 80% 90%, rgba(150,120,80,.25), transparent 55%),
    url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='240' height='240'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='3'/%3E%3CfeColorMatrix values='0 0 0 0 .35 0 0 0 0 .28 0 0 0 0 .18 0 0 0 .22 0'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  box-shadow: inset 0 0 30px rgba(110,80,40,.35); }
.grain .paper > * { -webkit-mask-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='g'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='1.6' numOctaves='2'/%3E%3CfeColorMatrix values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1.6 1.55'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23g)'/%3E%3C/svg%3E");
  mask-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='g'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='1.6' numOctaves='2'/%3E%3CfeColorMatrix values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1.6 1.55'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23g)'/%3E%3C/svg%3E"); }
.title { font-size: 1.25em; border-bottom: 1px solid rgba(59,54,49,.45); margin-bottom: 8px; padding-bottom: 2px; }
.rows div { display: grid; grid-template-columns: 14px 1fr auto auto; gap: 8px; align-items: baseline; border-bottom: 1px solid rgba(59,54,49,.18); }
.rows i { font-style: normal; opacity: .8; } .rows b, .stats b { font-weight: inherit; }
.dot { width: 7px; height: 7px; border-radius: 50%; background: #5e7a4a; display: inline-block; } .dot.off { background: #8c8173; }
.stats { display: grid; grid-template-columns: 1fr auto 1fr auto; gap: 0 12px; margin: 10px 0; } .stats b { text-align: right; }
.bubble { position: relative; border: 1.5px solid rgba(59,54,49,.6); border-radius: 14px 16px 14px 4px; padding: 6px 10px; margin: 8px 0 10px; }
.bubble small { display: block; font-size: .72em; opacity: .75; }
.nums { font-size: .9em; opacity: .9; }
</style></head><body>
<header><h1>Pencil fonts</h1><p>Simple hand-printed fonts on parchment in pencil grey. Name them by number.</p>
<label>Size <input id="size" type="range" min="11" max="30" value="20"> <span id="sv">20</span> px</label>
<label>Pencil <input id="lead" type="range" min="20" max="80" value="23"></label>
<label><input id="grain" type="checkbox" checked> Paper grain over the writing</label></header>
<main class="grain">{CARDS}</main>
<script>
const r = document.documentElement.style, main = document.querySelector("main");
size.oninput = () => { r.setProperty("--size", size.value + "px"); sv.textContent = size.value; };
lead.oninput = () => { const v = +lead.value; r.setProperty("--lead", `rgb(${v * 1.6 + 22},${v * 1.5 + 19},${v * 1.4 + 15})`); };
grain.onchange = () => main.classList.toggle("grain", grain.checked);
</script></body></html>
"""

if __name__ == "__main__":
    main()
