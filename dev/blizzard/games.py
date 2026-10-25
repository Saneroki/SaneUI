"""Forever's and Retail's interface side by side: lookup tables of where the two games differ, for making Sane UI
work in both (Doc/guides/blizzard-updates.md, *Forever and Retail*). Each export is read as its own client loads it.

  symbols.tsv      every symbol the two exports do not have alike: id, kind, how it differs, where each has it, notes;
                   a symbol not listed is the same in both
  files.tsv        every code file of either export: the same, different or only in one, and which client loads it
  addons.tsv       every Blizzard addon: whether each client loads it (or on demand), its files and symbols that differ
  art.tsv          every picture that differs or only one export has (by content key: the export's files.tsv, else
                   the bytes)
  art-folders.tsv  the pictures counted per folder
  README.md        the counts, the API namespaces that differ, and how to look things up
"""
import hashlib
import os
from collections import Counter, defaultdict
from pathlib import Path

import compare

GAMES = ("forever", "retail")  # the names of the two sides: the games here, ("old", "new") for a patch (patch.py)
OK = ("ok", "decrypted")  # the statuses of a file the export holds, in its files.tsv


def status(a, b, names=GAMES):
    """How one symbol differs between the first side (a, Forever) and the second (b, Retail), or None where it is
    the same."""
    if a is None:
        return f"{names[1]}-only"
    if b is None:
        return f"{names[0]}-only"
    if a["deprecated"] != b["deprecated"]:
        return "deprecated-in-" + (names[1] if b["deprecated"] else names[0])
    if a["sig"] != b["sig"]:
        return "calls-differ"
    if a["hash"] != b["hash"]:
        return "code-differs"
    return None


def where(record):
    if record is None:
        return ""
    return record["file"] + (f":{record['line']}" if record.get("line") else "")


def cell(text):
    return str(text).replace("\t", " ").replace("\n", " ")


def write_tsv(path, head, rows):
    with open(path, "w", encoding="utf-8", newline="\n") as file:
        file.write("\t".join(head) + "\n")
        for row in rows:
            file.write("\t".join(cell(value) for value in row) + "\n")


def addon_of(file):
    parts = file.split("/")
    return parts[1] if len(parts) > 2 and parts[0] == "AddOns" else ""


def symbols(forever, retail, names=GAMES):
    """[(id, kind, status, forever's place, retail's place, notes)] of every symbol that differs."""
    rows = []
    for id_ in sorted(forever.symbols.keys() | retail.symbols.keys()):
        a, b = forever.symbols.get(id_), retail.symbols.get(id_)
        how = status(a, b, names)
        if how:
            notes = compare.describe(a, b) if a and b else []
            rows.append((id_, (a or b)["kind"], how, where(a), where(b), "; ".join(notes)))
    return rows


def files(forever, retail, names=GAMES):
    """[(path, status, loaded by)] of every code file, matched without regard to capitals."""
    exports = dict(zip(names, (forever, retail)))
    by_name = {game: {path.lower(): path for path in export.files} for game, export in exports.items()}
    loaded = {game: {path.lower() for path in export.loaded} for game, export in exports.items()}
    rows = []
    first, second = by_name[names[0]], by_name[names[1]]
    for low in sorted(first.keys() | second.keys()):
        f, r = first.get(low), second.get(low)
        if f and r:
            how = "same" if forever.files[f] == retail.files[r] else "differs"
        else:
            how = f"{names[0]}-only" if f else f"{names[1]}-only"
        loads = [game for game in names if low in loaded[game]]
        rows.append((f or r, how, "both" if len(loads) == 2 else loads[0] if loads else "neither"))
    return rows


def addons(forever, retail, symbol_rows, file_rows):
    def state(export, name):
        record = export.symbols.get(f"addon:{name}")
        if record is None:
            return "absent"
        sig = record["sig"]
        return ("on-demand" if sig.get("lod") else "loads") if sig.get("loads") else "not-loaded"

    names = {id_[6:] for export in (forever, retail) for id_ in export.symbols if id_.startswith("addon:")}
    by_lower = {}
    for name in sorted(names):
        by_lower.setdefault(name.lower(), name)
    files_differ, symbols_differ = Counter(), Counter()
    for path, how, _ in file_rows:
        if how != "same":
            files_differ[addon_of(path).lower()] += 1
    for _, _, _, place_f, place_r, _ in symbol_rows:
        symbols_differ[addon_of(place_f or place_r).lower()] += 1
    return [(name, state(forever, name), state(retail, name), files_differ[low], symbols_differ[low])
            for low, name in sorted(by_lower.items())]


def art_index(root):
    """{path in small letters: (path, content key, bytes)} of the pictures an art export holds."""
    index = {}
    listing = root / "files.tsv"
    if listing.is_file():
        for line in listing.read_text(encoding="utf-8").splitlines()[1:]:
            cols = line.split("\t")
            if cols[4].split(":")[0] in OK and (root / cols[0]).is_file():
                index[cols[0].lower()] = (cols[0], cols[2], int(cols[3]))
        return index
    for base, _, names in os.walk(root):
        for name in names:
            path = Path(base) / name
            rel = path.relative_to(root).as_posix()
            if rel.startswith("Interface/"):
                data = path.read_bytes()
                index[rel.lower()] = (rel, hashlib.md5(data).hexdigest(), len(data))
    return index


def art(forever_root, retail_root, names=GAMES):
    """[(path, status, forever's bytes, retail's bytes)] of the pictures that differ, and the counts per folder."""
    f, r = art_index(forever_root), art_index(retail_root)
    rows, folders = [], defaultdict(Counter)
    for low in sorted(f.keys() | r.keys()):
        a, b = f.get(low), r.get(low)
        if a and b:
            how = "same" if a[1] == b[1] else "differs"
        else:
            how = f"{names[0]}-only" if a else f"{names[1]}-only"
        path = (a or b)[0]
        folders["/".join(path.split("/")[:3]) if path.count("/") > 2 else path.rsplit("/", 1)[0]][how] += 1
        if how != "same":
            rows.append((path, how, a[2] if a else "", b[2] if b else ""))
    return rows, folders


def namespace(id_):
    """The API namespace of a symbol (C_Housing), or the kind's word for the rest."""
    kind, _, name = id_.partition(":")
    if kind == "api":
        return name.split(".")[0] if "." in name else "(global functions)"
    if kind == "widget":
        return "widget " + name.split(":")[0]
    return kind


def tables(a, b, art_a, art_b, out, names=GAMES):
    """The tables of two exports side by side into the folder out: (symbol rows, file rows, addon rows, art rows,
    art folders)."""
    out.mkdir(parents=True, exist_ok=True)
    symbol_rows = symbols(a, b, names)
    write_tsv(out / "symbols.tsv", ("id", "kind", "status") + names + ("notes",), symbol_rows)
    file_rows = files(a, b, names)
    write_tsv(out / "files.tsv", ("path", "status", "loads"), file_rows)
    addon_rows = addons(a, b, symbol_rows, file_rows)
    write_tsv(out / "addons.tsv", ("addon",) + names + ("files-differ", "symbols-differ"), addon_rows)
    art_rows, folders = [], {}
    if art_a and art_b and art_a.is_dir() and art_b.is_dir():
        art_rows, folders = art(art_a, art_b, names)
        write_tsv(out / "art.tsv", ("path", "status", f"{names[0]}-bytes", f"{names[1]}-bytes"), art_rows)
        statuses = ("same", "differs", f"{names[0]}-only", f"{names[1]}-only")
        write_tsv(out / "art-folders.tsv", ("folder",) + statuses,
                  [(folder, *(folders[folder][s] for s in statuses)) for folder in sorted(folders)])
    return symbol_rows, file_rows, addon_rows, art_rows, folders


def write(forever, retail, forever_art, retail_art, out):
    """The lookup tables of Forever and Retail into the folder out; returns the README's lines."""
    return readme(forever, retail, *tables(forever, retail, forever_art, retail_art, out))


def table(head, rows):
    lines = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    lines += ["| " + " | ".join(str(value) for value in row) + " |" for row in rows]
    return lines


def readme(forever, retail, symbol_rows, file_rows, addon_rows, art_rows, folders):
    statuses = ("forever-only", "retail-only", "calls-differ", "code-differs", "deprecated-in-retail",
                "deprecated-in-forever")
    by_kind = defaultdict(Counter)
    for _, kind, how, *_ in symbol_rows:
        by_kind[kind][how] += 1
    same = Counter()
    for id_ in forever.symbols.keys() & retail.symbols.keys():
        if status(forever.symbols[id_], retail.symbols[id_]) is None:
            same[forever.symbols[id_]["kind"]] += 1
    lines = [f"# Forever {forever.build} and Retail {retail.build}", "",
             "Blizzard's interface code and art of the two games side by side, each read as its own client loads it",
             "(Forever: load groups camelot and mainline; Retail: standard and mainline). Made by",
             "`dev/tools/blizzard games`.", "", "## Symbols", "",
             "A symbol not in `symbols.tsv` is the same in both. *calls-differ*: parameters, arguments, returns,",
             "flags (secret values, restrictions), payload, a template's parents or keys, an enum's values;",
             "*code-differs*: called the same, its code differs.", ""]
    kinds = sorted(by_kind.keys() | same.keys(), key=lambda k: -(sum(by_kind[k].values()) + same[k]))
    lines += table(("kind", "same") + statuses,
                   [(compare.KIND.get(k, k), same[k], *(by_kind[k][s] for s in statuses)) for k in kinds])

    spaces = defaultdict(Counter)
    for id_, kind, how, *_ in symbol_rows:
        if kind in ("api", "widget", "event"):
            spaces[namespace(id_)][how] += 1
    lines += ["", "## API namespaces that differ", "",
              "The client's functions, widgets' methods and events, from the documentation, by namespace.", ""]
    ranked = sorted(spaces.items(), key=lambda item: -sum(item[1].values()))
    lines += table(("namespace", "forever-only", "retail-only", "calls-differ", "code-differs"),
                   [(name, c["forever-only"], c["retail-only"], c["calls-differ"], c["code-differs"])
                    for name, c in ranked[:60]])
    if len(ranked) > 60:
        lines.append(f"\n... and {len(ranked) - 60} more namespaces in `symbols.tsv`.")

    loads = Counter((f != "absent" and f != "not-loaded", r != "absent" and r != "not-loaded")
                    for _, f, r, _, _ in addon_rows)
    lines += ["", "## Blizzard's addons", "",
              f"{loads[True, True]} load in both, {loads[True, False]} only in Forever, {loads[False, True]} only "
              f"in Retail, {loads[False, False]} in neither (the code of other games the clients carry).", ""]
    only = [(name, f, r) for name, f, r, _, _ in addon_rows
            if (f in ("loads", "on-demand")) != (r in ("loads", "on-demand"))]
    lines += table(("addon", "forever", "retail"), only)
    loaded_both = [row for row in addon_rows if row[1] in ("loads", "on-demand") and row[2] in ("loads", "on-demand")]
    lines += ["", "The addons both load with the most symbols that differ:", ""]
    lines += table(("addon", "files-differ", "symbols-differ"),
                   [(name, fd, sd) for name, _, _, fd, sd in sorted(loaded_both, key=lambda r: -r[4])[:40] if sd])

    file_counts = Counter((how, loads_) for _, how, loads_ in file_rows)
    lines += ["", "## Code files", ""]
    lines += table(("status", "loaded by both", "only Forever", "only Retail", "neither"),
                   [(how, file_counts[how, "both"], file_counts[how, "forever"], file_counts[how, "retail"],
                     file_counts[how, "neither"]) for how in ("same", "differs", "forever-only", "retail-only")])

    if folders:
        totals = Counter()
        for counts in folders.values():
            totals.update(counts)
        lines += ["", "## Art", "",
                  f"{totals['same']} pictures the same, {totals['differs']} differ, {totals['forever-only']} only "
                  f"in Forever, {totals['retail-only']} only in Retail (`art.tsv`; per folder `art-folders.tsv`).",
                  "", "The folders with the most differences:", ""]
        ranked = sorted(folders.items(), key=lambda item: -(sum(item[1].values()) - item[1]["same"]))
        lines += table(("folder", "same", "differs", "forever-only", "retail-only"),
                       [(name, c["same"], c["differs"], c["forever-only"], c["retail-only"])
                        for name, c in ranked[:40] if sum(c.values()) > c["same"]])

    lines += ["", "## Looking things up", "",
              "- `grep -i 'GetSpellInfo' symbols.tsv`: how a function, event, template or global differs.",
              "- `dev/tools/blizzard show <name> --retail`: one symbol in both games, with the diff of its code.",
              "- `grep '^AddOns/Blizzard_WorldMap/' files.tsv`, `grep -i 'Blizzard_WorldMap' addons.tsv`.",
              "- `grep -i 'interface/worldmap/' art.tsv`: pictures; a picture not listed is the same in both.",
              "- `uses.md`: what of Sane UI's own uses differs in Retail (`dev/tools/blizzard check --retail`).", ""]
    return lines
