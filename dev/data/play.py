"""What play teaches, added up over every saved file the harvest reads (Doc/guides/data.md, *The harvest*, *Counted in
play*): the ledger, and what it stages once enough players agree.

The game keeps per build a block of counts with a random id (Core's Tally.lua): loots and what they gave, places seen
from up close, cells where things were looted or objectives counted. The ledger keeps what it took of each block
(so a saved file read twice, or copied, counts once: only what grew since is added) and the sums of all of them, and
what the game told of entries field by field (Check.lua's parts), until enough is known:

  Drops       a key's chances, once every way it is looted that matters (our data's and play's) has Play.LOOTS loots
              or more: per item how often it came; its chance per loot from Play.SURE drops on. An item our data lists
              that play never saw stays where it is rare enough not to have shown yet, else it goes. A chance that
              changed with a build (a clear difference over enough loots both sides) counts from that build on only.
              Staged again only once the loots grew by half.
  Spawns      the places seen on more than one visit: where each of our data's points was seen, the point narrowed to
              where play saw it; one our data lacks, a new point. Staged once every point of our data's was seen (a
              point never seen is not proven wrong, and a field is the game's whole or not at all).
  areas       cells where a creature was looted, or an objective's count went up, twice or more: the area of a
              creature (Spawns or CreatureSpawns) or of a quest's objective (QuestAreas) where our data has none.
  confirmed   an entry whose every field the play list names (the schema's play) the game told, over all files.

The ledger holds game facts only: random ids, counts, places. Nothing of who played, nor when finer than the day.
"""
import datetime
import json
import math
from pathlib import Path

LIST, PART = "\x1e", "\x1f"
FORMAT = 1


class Play:
    LOOTS = 50        # loots of a way (and a quest) before its chances count
    SURE = 3          # drops of an item before it gets a chance
    GROW = 1.5        # a chance staged again once its loots grew so much
    CHANGE = 100      # loots on both sides before a change between builds is looked for
    Z = 3.0           # how clear the difference (two-proportion z) ...
    SHARE = 0.2       # ... and how large (a fifth of the higher chance)
    MERGE = 8         # yards within which two sightings are one place (Tally.MERGE)
    NEAR = 30         # yards within which a place is one of our data's points (Watchers.NEAR)
    VISITS = 2        # visits before a place counts
    CELLS = 2         # loots or counts in a cell before it is part of an area


def number(text):
    try:
        value = float(text)
    except (TypeError, ValueError):
        return text
    return int(value) if value.is_integer() else value


def records(row):
    """A packed row of the game's tally: its records, each a list of parts (numbers where they are)."""
    if not isinstance(row, str) or not row:
        return []
    return [[number(part) for part in record.split(PART)] for record in row.split(LIST) if record]


class Ledger:
    """The ledger in its file: what was taken of each block, and the sums."""

    def __init__(self, path):
        self.path = Path(path) if path else None
        data = {}
        if self.path and self.path.is_file():
            data = json.loads(self.path.read_text(encoding="utf-8"))
        if data.get("format", FORMAT) != FORMAT:
            raise ValueError(f"{self.path}: a ledger of format {data.get('format')}")
        self.taken = data.get("taken", {})      # game -> block id -> {"build", "drops", "points", "cells"}: rows taken
        self.drops = data.get("drops", {})      # game -> key -> build -> {"c": {"how|quest": n}, "d": {"how|item|quest": [times, units]}}
        self.points = data.get("points", {})    # game -> key -> [[map, x, y, visits]]
        self.cells = data.get("cells", {})      # game -> key -> {"map|cell": n}
        self.maps = data.get("maps", {})        # game -> map -> [width, height] in yards
        self.told = data.get("told", {})        # game -> set -> key -> {"parts": [...], "day", "build"}
        self.staged = data.get("staged", {})    # game -> key -> loots when its chances were last staged

    def save(self):
        if not self.path:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        data = {"format": FORMAT, "taken": self.taken, "drops": self.drops, "points": self.points, "cells": self.cells,
                "maps": self.maps, "told": self.told, "staged": self.staged}
        self.path.write_text(json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n",
                             encoding="utf-8")

    # Taking in -----------------------------------------------------------------------------------------

    def take_maps(self, game, maps):
        mine = self.maps.setdefault(game, {})
        for map_id, size in (maps or {}).items():
            parts = records(size)
            if parts and len(parts[0]) == 2 and all(isinstance(v, (int, float)) and v > 0 for v in parts[0]):
                mine.setdefault(str(map_id), parts[0])

    def take_block(self, game, build, block, report):
        """A block of a saved file: what grew since it was last taken added to the sums."""
        block_id = block.get("id")
        if not isinstance(block_id, str) or not block_id:
            report["broken"] += 1
            return
        before = self.taken.setdefault(game, {}).get(block_id, {})
        kept = {"build": build}
        for kind in ("drops", "points", "cells"):
            rows = block.get(kind) if isinstance(block.get(kind), dict) else {}
            old = before.get(kind, {})
            for key, row in rows.items():
                if not isinstance(row, str):
                    report["broken"] += 1
                    continue
                if row != old.get(key):
                    getattr(self, "_" + kind)(game, str(build), str(key), records(row), records(old.get(key)))
                    report["counted"] += 1
            kept[kind] = {str(key): row for key, row in rows.items() if isinstance(row, str)}
        self.taken[game][block_id] = kept

    def _drops(self, game, build, key, now, old):
        period = self.drops.setdefault(game, {}).setdefault(key, {}).setdefault(build, {"c": {}, "d": {}})

        def counted(list_):
            out = {}
            for record in list_:
                if record[0] == "c" and len(record) >= 4:
                    out[("c", f"{record[1]}|{record[2]}")] = (record[3], 0)
                elif record[0] == "d" and len(record) >= 6:
                    out[("d", f"{record[1]}|{record[2]}|{record[3]}")] = (record[4], record[5])
            return out
        was = counted(old)
        for (kind, name), (a, b) in counted(now).items():
            pa, pb = was.get((kind, name), (0, 0))
            da, db = max(0, a - pa), max(0, b - pb)
            if not (da or db):
                continue
            if kind == "c":
                period["c"][name] = period["c"].get(name, 0) + da
            else:
                times, units = period["d"].get(name, [0, 0])
                period["d"][name] = [times + da, units + db]

    def _points(self, game, build, key, now, old):
        for index, record in enumerate(now):
            if len(record) < 4:
                continue
            seen_before = old[index][3] if index < len(old) and len(old[index]) >= 4 and old[index][0] == record[0] else 0
            visits = max(0, record[3] - seen_before)
            if visits:
                self.add_place(game, key, record[0], record[1], record[2], visits)

    def add_place(self, game, key, map_id, x, y, visits):
        places = self.points.setdefault(game, {}).setdefault(key, [])
        best, near = None, None
        for place in places:
            far = self.yards(game, map_id, x, y, place)
            if far is not None and far <= Play.MERGE and (near is None or far < near):
                best, near = place, far
        if best:
            total = best[3] + visits
            best[1] = round((best[1] * best[3] + x * visits) / total, 2)
            best[2] = round((best[2] * best[3] + y * visits) / total, 2)
            best[3] = total
        else:
            places.append([map_id, round(x, 2), round(y, 2), visits])

    def _cells(self, game, build, key, now, old):
        mine = self.cells.setdefault(game, {}).setdefault(key, {})
        was = {(r[0], r[1]): r[2] for r in old if len(r) >= 3}
        for record in now:
            if len(record) < 3:
                continue
            grew = max(0, record[2] - was.get((record[0], record[1]), 0))
            if grew:
                name = f"{record[0]}|{record[1]}"
                mine[name] = mine.get(name, 0) + grew

    def take_told(self, game, set_name, key, parts, day, build):
        entry = self.told.setdefault(game, {}).setdefault(set_name, {}).setdefault(str(key), {"parts": [], "day": day, "build": build})
        entry["parts"] = sorted(set(entry["parts"]) | set(parts))
        if day and (not entry.get("day") or day > entry["day"]):
            entry["day"] = day
        entry["build"] = max(entry.get("build") or 0, build or 0)
        return set(entry["parts"])

    # Measuring ------------------------------------------------------------------------------------------

    def yards(self, game, map_id, x, y, point):
        """Yards between a place and a point ([map, x, y, ...]) on the same map; None on another or an unknown map."""
        if point[0] != map_id:
            return None
        size = self.maps.get(game, {}).get(str(map_id))
        if not size:
            return None
        return math.hypot((point[1] - x) / 100 * size[0], (point[2] - y) / 100 * size[1])


# Staging ---------------------------------------------------------------------------------------------------

def _merged(periods):
    out = {"c": {}, "d": {}}
    for period in periods:
        for name, n in period["c"].items():
            out["c"][name] = out["c"].get(name, 0) + n
        for name, (times, units) in period["d"].items():
            had = out["d"].get(name, [0, 0])
            out["d"][name] = [had[0] + times, had[1] + units]
    return out


def changed(newest, earlier):
    """The items whose chance differs clearly between the newest build period and those before it."""
    found = []
    for name, (times, _) in newest["d"].items():
        how, item, quest = name.split("|")
        context = f"{how}|{quest}"
        n1, n0 = newest["c"].get(context, 0), earlier["c"].get(context, 0)
        if n1 < Play.CHANGE or n0 < Play.CHANGE:
            continue
        t0 = earlier["d"].get(name, [0, 0])[0]
        p1, p0 = times / n1, t0 / n0
        pooled = (times + t0) / (n1 + n0)
        spread = math.sqrt(pooled * (1 - pooled) * (1 / n0 + 1 / n1))
        if spread > 0 and abs(p1 - p0) / spread > Play.Z and abs(p1 - p0) >= Play.SHARE * max(p0, p1):
            found.append((int(item), round(100 * p0, 2), round(100 * p1, 2)))
    return found


def _main_how(key, counts):
    if key.startswith("zone:"):
        return "fish"
    if key.startswith("object:"):
        gathers, loots = counts.get("gather|0", 0), counts.get("loot|0", 0)
        return "gather" if gathers >= loots else "loot"
    return "loot"


def drops(master, ledger, game, build, day, report):
    """Staging lines of the set Drops from the sums: see the module's words."""
    lines = []
    if "Drops" not in master.schemas:
        return lines
    view = master.view("Drops", game)
    for key, periods in sorted(ledger.drops.get(game, {}).items()):
        builds = sorted(periods, key=int)
        use = builds
        if len(builds) > 1:
            moved = changed(periods[builds[-1]], _merged(periods[b] for b in builds[:-1]))
            if moved:
                use = builds[-1:]
                report["changes"].extend((key, int(builds[-1]), *each) for each in moved)
        totals = _merged(periods[b] for b in use)
        counts = totals["c"]
        versions = view.get(key)
        own = versions[-1].fields.get("items", []) if versions and not versions[-1].gone else []
        needed = {f"{item.get('how') or 'loot'}|{item.get('quest') or 0}" for item in own}
        needed |= {name.rsplit("|", 2)[0] + "|" + name.rsplit("|", 1)[1] for name, (times, _) in totals["d"].items() if times}
        main = _main_how(key, counts)
        needed.add(f"{main}|0")
        if any(counts.get(context, 0) < Play.LOOTS for context in needed):
            report["waiting"]["Drops"] += 1
            continue
        loots = counts.get(f"{main}|0", 0)
        if loots < Play.GROW * ledger.staged.get(game, {}).get(key, 0):
            continue
        items, seen = [], set()
        for name, (times, units) in totals["d"].items():
            how, item, quest = name.split("|")
            item, quest = int(item), int(quest)
            entry = {"item": item, "how": how, "drops": times}
            if quest:
                entry["quest"] = quest
            if times >= Play.SURE:
                entry["chance"] = round(100 * times / counts[f"{how}|{quest}"], 2)
            items.append(entry)
            seen.add((item, how, quest))
        for item in own:
            how, quest = item.get("how") or "loot", item.get("quest") or 0
            if (item["item"], how, quest) in seen:
                continue
            chance = item.get("chance")
            if chance is not None and chance / 100 * counts.get(f"{how}|{quest}", 0) >= Play.SURE:
                report["dropped"] += 1  # it would have shown by now: our data is wrong
                continue
            items.append(dict(item))
        items.sort(key=lambda each: (each["how"] if "how" in each else "loot", -(each.get("drops") or 0), each["item"]))
        lines.append({"set": "Drops", "key": key, "game": game, "build": int(use[-1]), "day": day, "src": "game",
                      "fields": {"loots": loots, "items": items}})
        ledger.staged.setdefault(game, {})[key] = loots
        report["staged"]["Drops"] += 1
    return lines


def spawns(master, ledger, game, build, day, report):
    """Staging lines of the set Spawns from the places seen: see the module's words."""
    lines = []
    if "Spawns" not in master.schemas:
        return lines
    view = master.view("Spawns", game)
    for key, places in sorted(ledger.points.get(game, {}).items()):
        sure = [place for place in places if place[3] >= Play.VISITS]
        if not sure:
            continue
        versions = view.get(key)
        own = versions[-1].fields.get("points", []) if versions and not versions[-1].gone else []
        chosen, matched = [], set()
        for point in own:
            best = None
            for place in sure:
                far = ledger.yards(game, place[0], place[1], place[2], point)
                if far is not None and far <= Play.NEAR and (best is None or place[3] > best[3]):
                    best = place
            if best is None:
                break
            matched.add(id(best))
            chosen.append((point, best))
        if len(chosen) < len(own):
            report["waiting"]["Spawns"] += 1
            continue
        points, taken = [], set()
        for _, place in chosen:  # two of our points one place: the same thing twice, one point
            if id(place) not in taken:
                taken.add(id(place))
                points.append([place[0], round(place[1], 2), round(place[2], 2)])
        for place in sorted(sure, key=lambda each: -each[3]):
            if id(place) in matched:
                continue
            if any((ledger.yards(game, place[0], place[1], place[2], [p[0], p[1], p[2]]) or math.inf) <= Play.NEAR for p in points):
                continue  # the same thing wandering about a place already taken
            points.append([place[0], round(place[1], 2), round(place[2], 2)])
        unchanged = len(points) == len(own) and all(
            (ledger.yards(game, place[0], place[1], place[2], point) or math.inf) <= 1 for point, place in chosen)
        if unchanged:
            lines.append({"set": "Spawns", "key": key, "game": game, "build": build, "src": "game", "confirmed": day})
        else:
            lines.append({"set": "Spawns", "key": key, "game": game, "build": build, "day": day, "src": "game",
                          "fields": {"points": points}})
        report["staged"]["Spawns"] += 1
    return lines


def _area(cells):
    """(runs per map, middles) of a set of (map, row, column) cells."""
    runs, middles = [], []
    for map_id in sorted({cell[0] for cell in cells}):
        mine = sorted((row, column) for m, row, column in cells if m == map_id)
        mine_runs = []
        for row, column in mine:
            if mine_runs and mine_runs[-1]["row"] == row and mine_runs[-1]["last"] == column - 1:
                mine_runs[-1]["last"] = column
            else:
                mine_runs.append({"map": map_id, "row": row, "first": column, "last": column})
        runs.extend(mine_runs)
        middles.append({"map": map_id, "x": round(sum(c + 0.5 for _, c in mine) / len(mine), 1),
                        "y": round(sum(r + 0.5 for r, _ in mine) / len(mine), 1),
                        "size": round(math.sqrt(len(mine) / math.pi), 1)})
    return runs, middles


def areas(master, ledger, game, build, day, report):
    """Staging lines of areas from the cells: creatures (Spawns, else CreatureSpawns) and quests' objectives
    (QuestAreas), where our data has none."""
    lines = []
    views = {name: master.view(name, game) for name in ("Spawns", "CreatureSpawns", "QuestAreas", "Quests")
             if name in master.schemas}
    held = {}  # (quest, objective, map) our data has an area of
    for area_key, versions in views.get("QuestAreas", {}).items():
        quest, objective, _, map_id = (int(part) for part in str(area_key).split("/"))
        held[(quest, objective, map_id)] = True
    for key, counted in sorted(ledger.cells.get(game, {}).items()):
        cells = {(int(m), int(cell) // 100, int(cell) % 100) for name, n in counted.items() if n >= Play.CELLS
                 for m, cell in [name.split("|")]}
        if not cells:
            continue
        if key.startswith("quest:"):
            if "QuestAreas" not in views:
                continue
            quest, objective = (int(part) for part in key[6:].split("/"))
            stage = 1
            record = views.get("Quests", {}).get(quest)
            for each in (record[-1].fields.get("objectives", []) if record and not record[-1].gone else []):
                if each.get("index") == objective and each.get("stage"):
                    stage = each["stage"]
            for map_id in sorted({cell[0] for cell in cells}):
                if held.get((quest, objective, map_id)):
                    continue
                runs, middles = _area({cell for cell in cells if cell[0] == map_id})
                lines.append({"set": "QuestAreas", "key": f"{quest}/{objective}/{stage}/{map_id}", "game": game,
                              "build": build, "day": day, "src": "game",
                              "fields": {"quest": quest, "objective": objective, "stage": stage, "map": map_id,
                                         "runs": [{k: r[k] for k in ("row", "first", "last")} for r in runs],
                                         "x": middles[0]["x"], "y": middles[0]["y"], "size": middles[0]["size"],
                                         "from": "play"}})
                report["staged"]["QuestAreas"] += 1
        elif key.startswith("npc:"):
            spawn = views.get("Spawns", {}).get(key)
            name, entry_key = ("Spawns", key) if spawn else ("CreatureSpawns", int(key[4:]))
            if name not in views:
                continue
            versions = views.get(name, {}).get(entry_key)
            if versions and not versions[-1].gone and versions[-1].fields.get("areas"):
                continue
            runs, middles = _area(cells)
            lines.append({"set": name, "key": entry_key, "game": game, "build": build, "day": day, "src": "game",
                          "fields": {"areas": runs, "middles": middles}})
            report["staged"][name] += 1
    return lines


def covered(schema, fields, parts):
    """Whether the game told every field of the play list (not the optional ones) that an entry's fields hold."""
    any_held = False
    for told in schema.play or []:
        if told.optional:
            continue
        value = fields.get(told.field.name)
        if value in (None, [], {}):
            continue
        any_held = True
        if told.how == "whole":
            if told.field.name not in parts:
                return False
        elif told.how == "member":
            if any(told.part(element) not in parts for element in value):
                return False
        elif any(told.part(inner) not in parts for inner in value):
            return False
    return any_held


def today():
    return datetime.date.today().isoformat()
