"""A game build's client tables against the build before it, every table, as CSV with the hotfixes laid on where a
build has them (Doc/guides/blizzard-updates.md, *Patch day*). The master holds only part of what the client says;
this says what else moved, so nothing of a patch is left unseen: a race's stats, a class's rules, a table no tool of
ours reads yet.

  tables.tsv            one line per table that changed: its topic, rows new, gone and changed, the columns that moved
  tables/<Table>.tsv    its changes, a line per field, at most LIMIT lines: the row's ID and name, how, column, old, new
"""
import csv
import filecmp
from collections import Counter
from pathlib import Path

csv.field_size_limit(1 << 30)
LIMIT = 2000                # lines of a table's own file
NOISE = {"VerifiedBuild"}   # columns that change with every build
RENUMBERED = 0.9            # of a large table's rows changed: its own numbering moved, its contents are compared
LARGE = 1000                # rows
NAMES = ("Name_lang", "AreaName_lang", "Display_lang", "Description_lang", "Name", "Title_lang", "QuestTitle_lang")
# The first topic whose words start the table's name; a table of none is Other.
TOPICS = (
    ("Characters", ("ChrRace", "ChrClass", "ChrSpecial", "ChrCustom", "ChrModel", "CharBase", "CharStart", "Faction",
                    "BarberShop", "XP", "GameTable", "GtCombat", "GtChance", "GtOct")),
    ("Talents", ("Talent", "Trait", "NodeSpec", "Glyph", "Spec")),
    ("Spells", ("Spell", "Aura", "Totem", "OverrideSpell", "PowerType", "RuneType", "Rune")),
    ("Items and Rewards", ("Item", "Enchant", "Gem", "Socket", "Scaling", "Transmog", "Mount", "Toy", "Currency", "Heirloom",
                           "Reward", "Loot", "Treasure")),
    ("Professions", ("Skill", "TradeSkill", "Profession", "Crafting", "Lock", "Trainer")),
    ("Quests", ("Quest", "Campaign")),
    ("Enemies and NPCs", ("Creature", "GameObject", "Gossip", "Vehicle", "NPC", "Npc", "Pet", "BattlePet")),
    ("World", ("Map", "Area", "UiMap", "WorldMap", "Taxi", "Light", "Liquid", "Weather", "Zone", "Terrain", "Transport",
               "Phase", "WMO", "AltMinimap", "Destructible")),
    ("Dungeons and Raids", ("Journal", "Encounter", "LFG", "Difficulty", "Dungeon", "Instance", "Boss")),
    ("Housing", ("Decor", "House", "Room", "Exterior", "Neighborhood")),
    ("Player versus Player", ("PVP", "Pvp", "Battlemaster", "Honor", "Arena")),
    ("Achievements", ("Achievement", "Criteria", "ModifierTree", "PlayerCondition", "Holidays", "Calendar")),
    ("User Interface", ("UI", "Ui", "Global", "Binding", "Chat", "Tutorial", "Help", "Interface", "Emotes", "Language", "Cvar")),
    ("Sound and art", ("Sound", "Music", "Model", "Texture", "Anim", "Cinematic", "Movie", "Particle", "Screen", "Shader",
                       "Vignette", "Camera", "Art", "Component", "Creature")),
)


def topic(table):
    return next((name for name, words in TOPICS if table.startswith(words)), "Other")


def id_columns(folder):
    """{table: its ID column}, from the conversion's list where the folder has one."""
    path = Path(folder) / "convert.tsv"
    if not path.is_file():
        return {}
    with open(path, encoding="utf-8", newline="") as file:
        return {row["table"]: row["id_column"] for row in csv.DictReader(file, delimiter="\t")}


def rows_of(path, id_column):
    with open(path, encoding="utf-8", newline="") as file:
        reader = csv.reader(file)
        head = next(reader, [])
        at = head.index(id_column) if id_column in head else 0
        return head, {row[at]: row for row in reader if row}


def compare_table(name, old_path, new_path, id_column):
    """One table: (counts, lines of its changes)."""
    old_head, old = rows_of(old_path, id_column)
    new_head, new = rows_of(new_path, id_column)
    naming = next((column for column in NAMES if column in new_head), None)
    at = new_head.index(naming) if naming else None
    lines, columns = [], Counter()

    def label(row):
        return row[at] if at is not None and at < len(row) else ""

    for key in sorted(new.keys() - old.keys(), key=_order):
        lines.append((key, label(new[key]), "new", "", "", ""))
    for key in sorted(old.keys() - new.keys(), key=_order):
        lines.append((key, "", "gone", "", "", ""))
    changed = 0
    common = old.keys() & new.keys()
    if len(common) >= LARGE and _numbering_moved(old_head, old, new_head, new, common):
        return renumbered(name, old_head, old, new_head, new, id_column, label)
    for key in sorted(common, key=_order):
        before, after = dict(zip(old_head, old[key])), dict(zip(new_head, new[key]))
        moved = [c for c in sorted(before.keys() | after.keys(), key=_column_order(new_head))
                 if before.get(c) != after.get(c) and c not in NOISE]
        if moved:
            changed += 1
            columns.update(moved)
            lines += [(key, label(new[key]), "changed", c, before.get(c, ""), after.get(c, "")) for c in moved]
    counts = dict(table=name, topic=topic(name), rows=len(new), new=len(new.keys() - old.keys()),
                  gone=len(old.keys() - new.keys()), changed=changed, columns=[c for c, _ in columns.most_common(8)])
    return counts, lines


def _numbering_moved(old_head, old, new_head, new, common):
    """Whether nearly every row of a table differs under its ID: a table the client numbers by place in the file."""
    sample = sorted(common, key=_order)[::max(1, len(common) // 500)]
    moved = sum(1 for key in sample if dict(zip(old_head, old[key])) != dict(zip(new_head, new[key])))
    return moved >= RENUMBERED * len(sample)


def renumbered(name, old_head, old, new_head, new, id_column, label):
    """A renumbered table: its rows as what they hold, without their ID."""
    def held(head, rows):
        kept = [index for index, column in enumerate(head) if column != id_column and column not in NOISE]
        return Counter(tuple(row[i] for i in kept if i < len(row)) for row in rows.values())
    before, after = held(old_head, old), held(new_head, new)
    added, lost = after - before, before - after
    lines = [("", "", "new", "", "", " ".join(row)) for row in sorted(added)] + \
            [("", "", "gone", "", " ".join(row), "") for row in sorted(lost)]
    return dict(table=name, topic=topic(name), rows=len(new), new=sum(added.values()), gone=sum(lost.values()), changed=0,
                columns=["(numbered anew)"]), lines


def _order(key):
    return (0, int(key), "") if key.lstrip("-").isdigit() else (1, 0, key)


def _column_order(head):
    place = {name: index for index, name in enumerate(head)}
    return lambda name: place.get(name, len(place))


def compare(old_folder, new_folder, out):
    """Every table of two builds' CSV folders; writes tables.tsv and tables/, returns its rows, the busiest first."""
    old_folder, new_folder, out = Path(old_folder), Path(new_folder), Path(out)
    ids = {**id_columns(old_folder.parent / old_folder.name.removesuffix("-laid")),
           **id_columns(new_folder.parent / new_folder.name.removesuffix("-laid"))}
    detail = out / "tables"
    detail.mkdir(parents=True, exist_ok=True)
    for old_file in detail.glob("*.tsv"):
        old_file.unlink()
    names = {p.stem for p in new_folder.glob("*.csv")} | {p.stem for p in old_folder.glob("*.csv")}
    found = []
    for name in sorted(names):
        old_path, new_path = old_folder / f"{name}.csv", new_folder / f"{name}.csv"
        if not old_path.is_file() or not new_path.is_file():
            found.append(dict(table=name, topic=topic(name), rows=0, new=int(new_path.is_file()),
                              gone=int(old_path.is_file()), changed=0, columns=["(the whole table)"]))
            continue
        if filecmp.cmp(old_path, new_path, shallow=False):
            continue
        counts, lines = compare_table(name, old_path, new_path, ids.get(name, "ID"))
        if not (counts["new"] or counts["gone"] or counts["changed"]):
            continue
        found.append(counts)
        with open(detail / f"{name}.tsv", "w", encoding="utf-8", newline="") as file:
            writer = csv.writer(file, delimiter="\t", lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
            writer.writerow(("id", "name", "how", "column", "old", "new"))
            writer.writerows(lines[:LIMIT])
            if len(lines) > LIMIT:
                writer.writerow(("", "", f"{len(lines) - LIMIT} more lines left out", "", "", ""))
    found.sort(key=lambda row: (row["topic"], -(row["new"] + row["gone"] + row["changed"]), row["table"]))
    with open(out / "tables.tsv", "w", encoding="utf-8", newline="") as file:
        writer = csv.writer(file, delimiter="\t", lineterminator="\n")
        writer.writerow(("topic", "table", "rows", "new", "gone", "changed", "columns"))
        writer.writerows((r["topic"], r["table"], r["rows"], r["new"], r["gone"], r["changed"], " ".join(r["columns"]))
                         for r in found)
    return found
