"""A build's patch notes as one file, patchnotes.json in the patch's folder, written by the session that works the
patch, with Blizzard's layout: sections, under them groups (a class, an instance) and subgroups (a specialization, a
boss), the points as lists, "(was X)" after what changed (Doc/guides/blizzard-updates.md, *Patch day*).

  {"game": "forever", "build": 70801, "from": 70707, "patch": "1.60.2", "day": "2026-11-12", "crosschecked": true,
   "official": [{"title": "...", "url": "..."}],            Blizzard's pages this was compared with; [] when it has none
   "sections": [{"name": "Classes", "points": [...],
                 "groups": [{"name": "Mage", "points": [...], "groups": [{"name": "Frost", "points": [...]}]}]}],
   "sane": ["what changed in Sane UI for this build", ...]}

  a point   {"text": "...", "was": "25", "origin": "both", "extra": ["what we found beyond Blizzard's line"],
             "note": "our remark", "link": "the section of Blizzard's page"}
            origin: both (Blizzard says it and the client shows it), client (the client alone), blizzard (Blizzard's
            word alone: what the server holds, which the client cannot show)

The words stay our own: where Blizzard lists a change, the point takes its names, numbers and scope, and links to it.
From it come patchnotes.md, Patchnotes/<Game>-<version>.html (a plain file that needs nothing but itself: document()) and
the database's entry (fields()): the points by section, class and race, and every entry the game changed, each tied to
the point that tells of it, so that a view in the game can show them.
"""
import html
import json
import re
from datetime import date

GAMES = {"forever": "Forever", "retail": "Retail"}
ORIGINS = {"both": "Blizzard and client", "client": "Client only", "blizzard": "Blizzard only"}
# Blizzard's own names and its order: General first, then by the alphabet; bug fixes last.
SECTIONS = ("General", "Achievements", "Characters", "Classes", "Dungeons and Raids", "Enemies and NPCs", "Items and Rewards",
            "Player versus Player", "Professions", "Quests", "Reputation", "User Interface", "World", "Bug Fixes")
BAD_TEXT = re.compile("[\t\x1c\x1e\x1f]")
LISTED = 200   # at most this many entries of a set in the page's list of every change
CLASSES = {1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest", 6: "Death Knight", 7: "Shaman", 8: "Mage",
           9: "Warlock", 10: "Monk", 11: "Druid", 12: "Demon Hunter", 13: "Evoker"}
CLASS_IDS = {name: key for key, name in CLASSES.items()}
RACE_IDS = {"Human": 1, "Orc": 2, "Dwarf": 3, "Night Elf": 4, "Undead": 5, "Tauren": 6, "Gnome": 7, "Troll": 8,
            "High Order Skyborne": 95, "Windshaper Skyborne": 96}
# Where a section's points find the entries they tell of.
SEARCHED = {"Characters": ("Racials", "Races", "Spells"), "Classes": ("Spells", "Talents"), "Dungeons and Raids": ("Encounters",),
            "Items and Rewards": ("Items", "Auras", "Enchantments"), "Items": ("Items", "Auras", "Enchantments"),
            "Legacy System": ("Legacy",), "Professions": ("Spells", "Items"), "Reputation": ("Factions",),
            "World": ("Areas", "Maps", "Zones")}


def skeleton(game, build, old, patch, day):
    """A new patchnotes.json: Blizzard's sections, empty."""
    return {"game": game, "build": build, "from": old, "patch": patch, "day": day, "crosschecked": False, "official": [],
            "sections": [{"name": name, "points": [], "groups": []} for name in SECTIONS], "sane": []}


def points_of(notes):
    """Every point with where it stands: (section, group, sub, point)."""
    for section in notes.get("sections", ()):
        for point in section.get("points", ()):
            yield section["name"], None, None, point
        for group in section.get("groups", ()):
            for point in group.get("points", ()):
                yield section["name"], group["name"], None, point
            for sub in group.get("groups", ()):
                for point in sub.get("points", ()):
                    yield section["name"], group["name"], sub["name"], point


def problems(notes):
    """What is wrong with a patchnotes.json."""
    found = []
    for key in ("game", "build", "from", "patch", "day"):
        if key not in notes:
            found.append(f"'{key}' is missing")
    if notes.get("game") not in GAMES:
        found.append(f"game '{notes.get('game')}' is neither of {', '.join(GAMES)}")
    for name, group, sub, point in points_of(notes):
        where = " / ".join(part for part in (name, group, sub) if part)
        text = point.get("text")
        if not isinstance(text, str) or not text.strip():
            found.append(f"{where}: a point without text")
            continue
        if point.get("origin") not in ORIGINS:
            found.append(f"{where}: '{text[:40]}': origin must be one of {', '.join(ORIGINS)}")
        for word in (text, point.get("was"), point.get("note"), *point.get("extra", ())):
            if isinstance(word, str) and BAD_TEXT.search(word):
                found.append(f"{where}: '{text[:40]}' holds a tab or a control character")
    if not any(True for _ in points_of(notes)):
        found.append("no point written yet")
    return found


def rows(notes):
    """The notes as the set PatchNotes' list of tuples (a list holds no list): a point's extras and note follow it."""
    out = []

    def add(section, group, sub, kind, text, origin, was=None, link=None):
        row = {"section": section, "kind": kind, "text": text, "origin": origin}
        for part, value in (("group", group), ("sub", sub), ("was", was), ("link", link), ("class", CLASS_IDS.get(group)),
                            ("race", RACE_IDS.get(group))):
            if value:
                row[part] = value
        out.append(row)

    for section, group, sub, point in points_of(notes):
        add(section, group, sub, "point", point["text"], point["origin"], point.get("was"), point.get("link"))
        for extra in point.get("extra", ()):
            add(section, group, sub, "extra", extra, "client")
        if point.get("note"):
            add(section, group, sub, "note", point["note"], point["origin"])
    return out


def numbered(notes):
    """Every point with its place in rows(), counted from 1."""
    place = 1
    for section, group, _, point in points_of(notes):
        yield place, section, group, point
        place += 1 + len(point.get("extra", ())) + bool(point.get("note"))


def said_in(name, text):
    """Whether a text names an entry: a whole name, and one long enough to mean it."""
    return len(name) > 3 and bool(re.search(rf"(?<!\w){re.escape(name)}(?!\w)", text))


def changes(notes, facts):
    """Every entry the game changed at this build, a line each (facts' sets; those of counts alone are in counts), the
    first point that names it tied to it: of its section's sets, of its own class and race."""
    entries = []
    for set_name, found in sorted((facts or {}).get("sets", {}).items()):
        for how in ("new", "changed", "gone"):
            for row in found.get(how, ()):
                entry = {"set": set_name, "key": str(row["key"]), "how": how}
                moved = ",".join(change["field"] for change in row.get("changes", ()))
                if moved:
                    entry["fields"] = moved
                entry.update({part: row[part] for part in ("class", "race") if row.get(part)})
                entries.append((entry, row.get("name")))
    for place, section, group, point in numbered(notes):
        text = " ".join((point["text"], *point.get("extra", ())))
        wanted, klass, race = SEARCHED.get(section, ()), CLASS_IDS.get(group), RACE_IDS.get(group)
        for entry, name in entries:
            if name and "point" not in entry and entry["set"] in wanted and entry.get("class", klass) == klass \
                    and entry.get("race", race) == race and said_in(name, text):
                entry["point"] = place
    return [entry for entry, _ in entries]


def fields(notes, facts=None):
    """The database entry's fields."""
    found = {"patch": notes["patch"], "from": notes["from"], "points": rows(notes)}
    tied = changes(notes, facts)
    if tied:
        found["changes"] = tied
    counts = {name: sum(part["counts"].values()) for name, part in (facts or {}).get("sets", {}).items()}
    if counts:
        found["counts"] = counts
    if notes.get("official"):
        found["official"] = [page["url"] for page in notes["official"]]
    if notes.get("sane"):
        found["sane"] = notes["sane"]
    return found


def spelled(day):
    """A day as Blizzard writes it: November 12, 2026."""
    when = date.fromisoformat(day)
    return f"{when.strftime('%B')} {when.day}, {when.year}"


def title_of(notes):
    return f"{GAMES[notes['game']]} {notes['patch']}.{notes['build']} Patch Notes"


# --- Markdown -----------------------------------------------------------------------------------

def point_lines(point, indent=""):
    was = f" (was {point['was']})" if point.get("was") else ""
    lines = [f"{indent}- {point['text']}{was} [{ORIGINS[point['origin']]}]"]
    lines += [f"{indent}  - Also found: {extra}" for extra in point.get("extra", ())]
    if point.get("note"):
        lines.append(f"{indent}  - *Our note: {point['note']}*")
    return lines


def block_lines(block, depth):
    lines = []
    for point in block.get("points", ()):
        lines += point_lines(point)
    for group in block.get("groups", ()):
        if has_points(group):
            lines += ["", f"{'#' * depth} {group['name']}", ""] + block_lines(group, depth + 1)
    return lines


def has_points(block):
    return bool(block.get("points") or any(has_points(g) for g in block.get("groups", ())))


def markdown(notes):
    """patchnotes.md: the same notes as text."""
    lines = [f"# {title_of(notes)}", "", f"Build {notes['from']} to {notes['build']}, {spelled(notes['day'])}.",
             "Sane UI's own notes, read from the game client and compared with Blizzard's published notes.", ""]
    if notes.get("official"):
        lines += ["Blizzard's pages:"] + [f"- [{p['title']}]({p['url']})" for p in notes["official"]] + [""]
    elif notes.get("crosschecked"):
        lines += ["Blizzard published no notes for this build when these were written.", ""]
    for section in notes["sections"]:
        if has_points(section):
            lines += [f"## {section['name']}", ""] + block_lines(section, 3) + [""]
    if notes.get("sane"):
        lines += ["## Sane UI", ""] + [f"- {line}" for line in notes["sane"]] + [""]
    return "\n".join(lines)


# --- The page -----------------------------------------------------------------------------------

STYLE = """
/* A record of one build, read like Blizzard's notes: one column of nested lists, each level folded until opened. One dark
   theme, whatever the computer's is. Slate and beaten metal: gold for what Blizzard confirms, silver for what only the
   client shows. */
:root { --bg: #11161e; --panel: #19212c; --ink: #dfe5ec; --soft: #9aa8b8; --line: #303c4b; --gold: #dcb868;
        --gold-fill: #3a2f17; --silver: #b5c3d2; --silver-fill: #27323f; --plain-fill: #2e2736; --plain: #c9b8d8;
        --display: "Palatino Linotype", "Book Antiqua", Palatino, Georgia, serif;
        --body: "Segoe UI", system-ui, "Noto Sans", sans-serif;
        --data: ui-monospace, "Cascadia Code", "DejaVu Sans Mono", monospace;
        color-scheme: dark; overflow-anchor: none; }  /* a section opened above the screen must not shift a link's scroll */
body { background: var(--bg); color: var(--ink); font: 400 1.05rem/1.55 var(--body); }
.page { max-width: 54rem; margin: 0 auto; padding: 2.5rem 16px 4rem; }
.eyebrow { margin: 0; font-size: .8rem; letter-spacing: .12em; text-transform: uppercase; color: var(--gold); font-weight: 600; }
h1, h2, h3, h4 { font-family: var(--display); font-weight: 400; margin: 0; text-wrap: balance; }
h1 { font-size: clamp(2rem, 6vw, 3rem); line-height: 1.1; margin-top: .3rem; }
.builds { margin: .6rem 0 0; color: var(--soft); font-family: var(--data); font-size: .85rem; font-variant-numeric: tabular-nums; }
.official { margin: 1rem 0 0; padding: 0; list-style: none; display: grid; gap: .2rem; }
a { color: var(--gold); text-underline-offset: .15em; }
.legend { display: flex; flex-wrap: wrap; gap: .5rem; margin: 1.2rem 0 0; padding: 0; list-style: none; }
.tag { display: inline-block; padding: 0 .45em; border-radius: 3px; font-size: .72rem; font-weight: 600; white-space: nowrap;
       letter-spacing: .02em; vertical-align: .08em; }
.tag-both { background: var(--gold-fill); color: var(--gold); }
.tag-client { background: var(--silver-fill); color: var(--silver); }
.tag-blizzard { background: var(--plain-fill); color: var(--plain); }
.bar { position: sticky; top: 0; z-index: 5; display: flex; flex-wrap: wrap; gap: .3rem .9rem; align-items: center;
       margin-top: 1.6rem; padding-block: .55rem; background: var(--bg); border-bottom: 1px solid var(--line); font-size: .9rem; }
.bar a { color: var(--soft); text-decoration: none; }
.bar a:hover { color: var(--gold); }
.bar button { margin-left: auto; font: inherit; font-size: .85rem; color: var(--ink); background: var(--panel); border: 1px solid var(--line);
              border-radius: 4px; padding: .1rem .6rem; cursor: pointer; }
button:focus-visible, summary:focus-visible, a:focus-visible { outline: 2px solid var(--gold); outline-offset: 2px; }
main { display: grid; gap: 1.4rem; margin-top: 1.6rem; min-width: 0; }
.section { scroll-margin-top: 6rem; }
details > summary { cursor: pointer; list-style: none; display: flex; gap: .55rem; align-items: baseline; }
details > summary::-webkit-details-marker { display: none; }
details > summary::before { content: "\\25B8"; color: var(--gold); font-size: .8em; transition: transform .1s; }
details[open] > summary::before { transform: rotate(90deg); }
.section > summary h2 { font-size: 1.6rem; }
.section > summary { border-bottom: 1px solid var(--line); padding-bottom: .25rem; }
.group { margin-top: .9rem; margin-left: .2rem; }
.group > summary h3 { font-size: 1.2rem; color: var(--gold); }
.sub { margin-top: .5rem; margin-left: 1rem; }
.sub > summary h4 { font-size: 1.02rem; font-family: var(--body); font-weight: 600; }
.count { color: var(--soft); font-family: var(--data); font-size: .78rem; }
ul.points { margin: .5rem 0 0; padding-left: 1.3rem; display: grid; gap: .3rem; }
ul.points ul { margin: .15rem 0 0; padding-left: 1.1rem; color: var(--soft); font-size: .96rem; }
.note { font-style: italic; color: var(--soft); }
.was { color: var(--soft); }
.sane { background: var(--panel); border: 1px solid var(--line); border-radius: 6px; padding: .9rem 1rem; }
.every { font-size: .92rem; }
.every .scroll { overflow-x: auto; }
.every table { border-collapse: collapse; width: 100%; margin-top: .4rem; font-size: .84rem; }
.every th, .every td { text-align: left; padding: .15rem .6rem .15rem 0; border-bottom: 1px solid var(--line); vertical-align: top; }
.every td.key { font-family: var(--data); font-variant-numeric: tabular-nums; white-space: nowrap; }
.foot { margin-top: 2.5rem; color: var(--soft); font-size: .85rem; }
@media (prefers-reduced-motion: reduce) { details > summary::before { transition: none; } }
"""

SCRIPT = """
(function () {
  var button = document.getElementById("toggle-all"), page = document.querySelector(".page"), bar = document.querySelector(".bar");
  var all = document.querySelectorAll("main > details:not(.every), main > details:not(.every) details");
  var room = 0, foot = parseFloat(getComputedStyle(page).paddingBottom);
  button.addEventListener("click", function () {
    var open = button.getAttribute("aria-pressed") !== "true";
    all.forEach(function (item) { item.open = open; });
    button.setAttribute("aria-pressed", open ? "true" : "false");
    button.textContent = open ? "Collapse all" : "Expand all";
    room = 0;
    page.style.paddingBottom = "";
  });
  // A section's link opens it and brings it up under the bar; with the rest folded the page is too short for that, so
  // the page gets the room it lacks. It jumps at once: a smooth scroll skipped clicks when tried, and a link must arrive.
  document.querySelectorAll(".bar a").forEach(function (link) {
    link.addEventListener("click", function (event) {
      var target = document.getElementById(link.getAttribute("href").slice(1));
      if (!target) { return; }
      event.preventDefault();
      target.open = true;
      var top = target.getBoundingClientRect().top + window.scrollY - bar.offsetHeight - 8;
      var short = top + window.innerHeight - document.documentElement.scrollHeight;
      if (short > 0) {
        room += short;
        page.style.paddingBottom = foot + room + "px";
      }
      window.scrollTo(0, top);
    });
  });
})();
"""


def e(text):
    return html.escape(str(text), quote=True)


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def point_html(point):
    was = f' <span class="was">(was {e(point["was"])})</span>' if point.get("was") else ""
    tag = f'<span class="tag tag-{point["origin"]}">{e(ORIGINS[point["origin"]])}</span>'
    if point.get("link"):
        tag = f'<a href="{e(point["link"])}" target="_blank" rel="noopener">{tag}</a>'
    under = [f"<li>Also found: {e(extra)}</li>" for extra in point.get("extra", ())]
    if point.get("note"):
        under.append(f'<li class="note">Our note: {e(point["note"])}</li>')
    below = f"<ul>{''.join(under)}</ul>" if under else ""
    return f"<li>{e(point['text'])}{was} {tag}{below}</li>"


def counted(block):
    return len(block.get("points", ())) + sum(counted(g) for g in block.get("groups", ()))


def block_html(block, level):
    parts = []
    if block.get("points"):
        parts.append(f'<ul class="points">{"".join(point_html(p) for p in block["points"])}</ul>')
    for group in block.get("groups", ()):
        if has_points(group):
            kind, tag = ("group", "h3") if level == 0 else ("sub", "h4")
            parts.append(f'<details class="{kind}"><summary><{tag}>{e(group["name"])}</{tag}>'
                         f'<span class="count">{counted(group)}</span></summary>{block_html(group, level + 1)}</details>')
    return "".join(parts)


def every_change(facts):
    """The closed list at the foot: every change the client showed, set by set."""
    if not facts:
        return ""
    parts = []
    for name, found in sorted(facts.get("sets", {}).items()):
        total = sum(found["counts"].values())
        if not total:
            continue
        rows_ = []
        for how in ("new", "changed", "gone"):
            for row in found.get(how, ())[:LISTED]:
                what = "; ".join(f"{c['field']}: {c['to']} (was {c['from']})" for c in row.get("changes", ()))
                rows_.append(f'<tr><td class="key">{e(row["key"])}</td><td>{e(row.get("name", ""))}</td><td>{how}</td>'
                             f"<td>{e(what)}</td></tr>")
        more = total - len(rows_)
        words = ", ".join(f"{n} {how}" for how, n in found["counts"].items() if n)
        table = (f'<div class="scroll"><table><thead><tr><th>ID</th><th>Name</th><th>How</th><th>What</th></tr></thead>'
                 f"<tbody>{''.join(rows_)}</tbody></table></div>" if rows_ else "")
        rest = f"<p>And {more} more.</p>" if more > 0 else ""
        parts.append(f'<details class="group"><summary><h3>{e(name)}</h3><span class="count">{e(words)}</span></summary>'
                     f"{table}{rest}</details>")
    if not parts:
        return ""
    return (f'<details class="section every" id="every"><summary><h2>Every change in the client</h2></summary>'
            f"{''.join(parts)}</details>")


def head_html(notes):
    return f"<title>{e(title_of(notes))}</title>\n<style>{STYLE}</style>\n"


def body_html(notes, facts=None):
    origin = {key: 0 for key in ORIGINS}
    for _, _, _, point in points_of(notes):
        origin[point["origin"]] += 1
    legend = "".join(f'<li><span class="tag tag-{key}">{e(ORIGINS[key])}</span> <span class="count">{origin[key]}</span></li>'
                     for key in ORIGINS)
    official = ""
    if notes.get("official"):
        official = ('<ul class="official">' + "".join(
            f'<li><a href="{e(p["url"])}" target="_blank" rel="noopener">{e(p["title"])}</a></li>'
            for p in notes["official"]) + "</ul>")
    elif notes.get("crosschecked"):
        official = '<p class="builds">Blizzard had published no notes for this build when these were written.</p>'
    sections = [s for s in notes["sections"] if has_points(s)]
    links = [(s["name"], slug(s["name"])) for s in sections]
    if notes.get("sane"):
        links.append(("Sane UI", "sane-ui"))
    bar = "".join(f'<a href="#{anchor}">{e(name)}</a>' for name, anchor in links)
    body = "".join(f'<details class="section" id="{slug(s["name"])}"><summary><h2>{e(s["name"])}</h2>'
                   f'<span class="count">{counted(s)}</span></summary>{block_html(s, 0)}</details>' for s in sections)
    sane = ""
    if notes.get("sane"):
        lines = "".join(f"<li>{e(line)}</li>" for line in notes["sane"])
        sane = (f'<details class="section sane" id="sane-ui"><summary><h2>Sane UI</h2>'
                f'<span class="count">{len(notes["sane"])}</span></summary><ul class="points">{lines}</ul></details>')
    return (f'<div class="page"><header><p class="eyebrow">Sane UI patch notes</p><h1>{e(GAMES[notes["game"]])} {e(notes["patch"])}</h1>'
            f'<p class="builds">Build {e(notes["from"])} to {e(notes["build"])} &middot; {e(spelled(notes["day"]))}</p>'
            f'{official}<ul class="legend">{legend}</ul></header>'
            f'<nav class="bar" aria-label="Sections">{bar}<button id="toggle-all" type="button" aria-pressed="false">Expand all</button></nav>'
            f"<main>{body}{sane}{every_change(facts)}</main>"
            '<p class="foot">Made by Sane UI from the game client. Not an official Blizzard page.</p></div>'
            f"<script>{SCRIPT}</script>")


def file_name(game, version):
    """A build's file in Patchnotes/."""
    return f"{GAMES[game]}-{version}.html"


def document(notes, facts=None):
    """A build's page as a whole file, opened as it is: nothing it needs lies outside it."""
    return ('<!doctype html><html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1">'
            f"{head_html(notes)}</head><body>{body_html(notes, facts)}</body></html>\n")


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))
