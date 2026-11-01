"""A game's patch: the new build's export of Blizzard's interface against the one before it, written as our own
patch notes, with every change in tables, what of it reaches Sane UI, and the brief of the session that makes Sane
UI comply (Doc/guides/blizzard-updates.md, *After a patch*).

  notes.md          the patch notes: what Blizzard changed in the interface, kind by kind, in words
  symbols.tsv, files.tsv, addons.tsv, art.tsv, art-folders.tsv
                    every change, as games.py writes them (the sides old and new)
  todo.md, todo.json  what of it reaches Sane UI: broken, deprecated, changed, review, housekeeping (compare.py)
  session.md        the brief of the session that fixes Sane UI: its steps and the todo list's head
"""
import datetime
from collections import Counter, defaultdict
from pathlib import Path

import compare
import games
import report

SIDES = ("old", "new")
WORDS = {"new-only": "new", "old-only": "gone", "calls-differ": "called differently", "code-differs": "code changed",
         "deprecated-in-new": "now deprecated", "deprecated-in-old": "no longer deprecated"}
TITLE = {"forever": "Forever", "retail": "Retail"}
LISTED = 150  # at most this many names in one list of the notes; the rest are in symbols.tsv


def shown(export):
    """An export's build, or its label where its build is not known."""
    return export.build or export.label


def name_of(id_):
    return id_.partition(":")[2]


def listing(names):
    """A list of names in backticks, cut at LISTED."""
    names = sorted(names)
    shown = ", ".join(f"`{name}`" for name in names[:LISTED])
    return shown + (f", and {len(names) - LISTED} more (`symbols.tsv`)" if len(names) > LISTED else "")


def kind_section(title, rows, with_notes=True):
    """A section of the notes for one kind of symbol: what is new, gone and changed."""
    by = defaultdict(list)
    for id_, _, how, _, _, notes in rows:
        by[how].append((name_of(id_), notes))
    if not by:
        return []
    lines = ["", f"## {title}", ""]
    for how in ("new-only", "old-only", "deprecated-in-new", "deprecated-in-old"):
        if by[how]:
            lines.append(f"- **{WORDS[how].capitalize()}** ({len(by[how])}): " + listing(n for n, _ in by[how]))
    changed = by["calls-differ"]
    if changed:
        lines.append(f"- **Called differently** ({len(changed)}):")
        for name, notes in sorted(changed)[:LISTED]:
            lines.append(f"  - `{name}`: {notes}" if with_notes and notes else f"  - `{name}`")
        if len(changed) > LISTED:
            lines.append(f"  - and {len(changed) - LISTED} more (`symbols.tsv`)")
    if by["code-differs"]:
        lines.append(f"- **Code changed, called the same** ({len(by['code-differs'])}): "
                     + listing(n for n, _ in by["code-differs"]))
    return lines


def notes(game, old, new, symbol_rows, file_rows, addon_rows, art_rows, folders, analysis):
    """The patch notes' lines."""
    by_kind = defaultdict(list)
    for row in symbol_rows:
        by_kind[row[1]].append(row)
    count = Counter((row[1], row[2]) for row in symbol_rows)
    api = by_kind["api"]
    lines = [f"# Patch notes: {TITLE.get(game, game)} {shown(old)} → {shown(new)}", "",
             f"Blizzard's interface code and art of {TITLE.get(game, game)}, build {shown(old)} against {shown(new)}, "
             f"each read as its client loads it. Made {datetime.date.today().isoformat()} by "
             "`dev/tools/blizzard patch`. Every change is in the tables beside this file; what of it reaches Sane UI "
             "is in `todo.md`.", "",
             f"**In short:** {count['api', 'new-only']} new API functions, {count['api', 'old-only']} gone, "
             f"{count['api', 'calls-differ']} called differently; {count['event', 'new-only']} new events, "
             f"{count['event', 'old-only']} gone; {sum(1 for r in addon_rows if r[1] == 'absent')} new Blizzard addons, "
             f"{sum(1 for r in addon_rows if r[2] == 'absent')} gone; "
             f"{sum(1 for r in file_rows if r[1] != 'same')} code files changed, new or gone; "
             f"{len(art_rows)} pictures changed, new or gone."]

    changed_addons = [(name, a, b) for name, a, b, _, _ in addon_rows if a != b]
    if changed_addons:
        lines += ["", "## Blizzard's addons", ""]
        for name, a, b in changed_addons:
            what = "new" if a == "absent" else "gone" if b == "absent" else f"{a} → {b}"
            lines.append(f"- `{name}`: {what}")

    spaces = defaultdict(list)
    for row in api:
        spaces[games.namespace(row[0])].append(row)
    if api:
        lines += ["", "## API functions", ""]
        for space, rows in sorted(spaces.items(), key=lambda item: -len(item[1])):
            parts = Counter(WORDS[row[2]] for row in rows)
            lines.append(f"### {space} ({', '.join(f'{n} {w}' for w, n in parts.most_common())})")
            lines += kind_section("", rows)[3:]
            lines.append("")
    for kind, title in (("event", "Events"), ("widget", "Widgets' methods"), ("enum", "Enums"),
                        ("const", "Constants"), ("struct", "Structures"), ("cvar", "CVars"),
                        ("frame", "Frames made by Lua"), ("xml", "Templates and frames (XML)"),
                        ("lua", "Blizzard's Lua: functions, mixins and tables")):
        lines += kind_section(title, by_kind[kind])

    per_addon = defaultdict(Counter)
    for path, how, _ in file_rows:
        if how != "same":
            per_addon[games.addon_of(path) or path.split("/")[0]][WORDS.get(how, how)] += 1
    if per_addon:
        lines += ["", "## Code files", "", "Per Blizzard addon: files changed, new and gone (`files.tsv`).", ""]
        lines += games.table(("addon", "changed", "new", "gone"),
                             [(name, c["differs"], c["new"], c["gone"])
                              for name, c in sorted(per_addon.items(), key=lambda item: -sum(item[1].values()))])

    if folders:
        totals = Counter()
        for counts in folders.values():
            totals.update(counts)
        lines += ["", "## Art", "",
                  f"{totals['differs']} pictures changed, {totals['new-only']} new, {totals['old-only']} gone "
                  f"(`art.tsv`); the folders with the most:", ""]
        ranked = sorted(folders.items(), key=lambda item: -(sum(item[1].values()) - item[1]["same"]))
        lines += games.table(("folder", "changed", "new", "gone"),
                             [(name, c["differs"], c["new-only"], c["old-only"]) for name, c in ranked[:40]
                              if sum(c.values()) > c["same"]])

    sections = analysis.by_section()
    lines += ["", "## What it means for Sane UI", "",
              ", ".join(f"{len(sections[s])} {s}" for s in compare.SECTIONS) + ": `todo.md`, and the session that "
              "fixes it: `session.md`."]
    return lines


def session(game, old, new, analysis, folder, card, lookup):
    """The brief of the session that makes Sane UI comply with the new build. It names no folder of this computer
    (the reports' folder is private, and no file of Sane UI names it): the patch's folder and the lookup by their
    names under the reports' folder, the exports by the tools that read them."""
    title = TITLE.get(game, game)
    other = "Retail" if game == "forever" else "Forever"
    sections = analysis.by_section()
    show = ("`dev/tools/blizzard show <name>` shows one name's change with its diff (the newest export against the one "
            "before it)." if game == "forever" else
            "`dev/tools/blizzard show <name> <new> --old <old>` shows one name's change with its diff, given Retail's "
            "two newest exports' code folders (`dev/tools/blizzard where` prints the newest; the one before it stands "
            "beside it).")
    where = (f"`{Path(lookup).name}` in the reports' folder, `symbols.tsv`; " if lookup else "")
    lines = [f"# Make Sane UI comply with {title} {shown(new)}", "",
             f"{title} was patched from {shown(old)} to {shown(new)}. Blizzard's interface code and art of the new build "
             "are exported, the build before it beside them (`dev/tools/blizzard where` prints the folders, the reports' "
             f"folder among them). What changed: `notes.md` in the patch's folder, `patches/{Path(folder).name}` in the reports' "
             "folder; what of it reaches Sane UI: `todo.md` there.", "",
             f"**Your task:** make Sane UI work with {title} {shown(new)}, and keep it working in {other}.", "",
             "1. Read `CLAUDE.md`, `.claude/rules/code.md`, `Doc/guides/blizzard-updates.md` (*After a patch*) and "
             "`Doc/guides/addon-standards.md` (*Forever and Retail*).",
             f"2. The board's card #{card} is this task: `saneui board start {card}`." if card else
             "2. Make a card for it on the board and start it.",
             "3. Work `todo.md` from the top: Broken, Deprecated, Changed, Review, Housekeeping, ticking each. " + show,
             f"4. Every fix serves both games: look the name up in the Forever–Retail lookup ({where}"
             "`dev/tools/blizzard show <name> --retail`) and use what both have; where they differ, an override, as the "
             "guide says.",
             "5. " + ("`dev/tools/blizzard adopt` makes the files made from Blizzard's code anew (CVarLabels, Pages); "
                      "commit them with the fixes." if game == "forever" else
                      "The files made from Blizzard's code (CVarLabels, Pages) are Forever's: nothing to adopt."),
             "6. `saneui installdev` (the tests run each module as Retail too: `W.Play`, with `dev/tests/games.lua` "
             "made anew by the patch), an entry in `Doc/Changed.md`, a commit; then "
             + (f"`saneui board review {card}`." if card else "the card to Review."), "",
             "## The todo list's head", ""]
    count = 0
    for section in ("broken", "deprecated", "changed"):
        for finding in sections[section]:
            if count >= 40:
                break
            where = ", ".join(u.where() for u in finding.uses[:3]) + (" ..." if len(finding.uses) > 3 else "")
            lines.append(f"- {section}: {finding.title()}: {'; '.join(finding.notes)[:200]} ({where})")
            count += 1
    total = sum(len(sections[s]) for s in compare.SECTIONS)
    if not count:
        lines.append("Nothing Sane UI uses broke or is called differently: work the review and housekeeping in "
                     "`todo.md`." if total else "Nothing of the patch reaches Sane UI.")
    return lines


def write(game, old, new, old_art, new_art, uses, tocs, generated, out, card_fn=None, lookup=""):
    """The patch's folder out: the tables, notes.md, todo.md and .json, session.md. card_fn(analysis) makes the
    board's card and returns its number (or None). Returns (analysis, card)."""
    rows = games.tables(old, new, old_art, new_art, out, SIDES)
    analysis = compare.Analysis(old, new, uses, tocs, generated)
    report.markdown(analysis, out / "todo.md", uses.root, None)
    report.as_json(analysis, out / "todo.json")
    (out / "notes.md").write_text("\n".join(notes(game, old, new, *rows, analysis)) + "\n", encoding="utf-8")
    card = card_fn(analysis) if card_fn else None
    (out / "session.md").write_text("\n".join(session(game, old, new, analysis, out, card, lookup)) + "\n",
                                    encoding="utf-8")
    return analysis, card
