"""The harvest (Doc/guides/data.md, *The harvest*): what Core learned and confirmed in play, read from the game's saved
files into staging for the import.

Core keeps in SaneUIData_Learned[game] (in WTF/Account/<account>/SavedVariables/SaneUI.lua):
  learned[set][key]    a whole row of the set, as the game showed it (Data.Learn, or taken from a guild or group
                       member's Sane UI): staged as the game's facts at the row's build and day
  confirmed[set][key]  "day\\031build\\031parts": the game agreed with the entry ("*" the whole entry) or with parts of
                       it (a boss's item "l17076", its ability "a8269", a spawn point "p..."; a field the game told,
                       "name", or a member of one, "startNPCs=69": Check.lua): the whole entry staged as confirmed
                       (the import writes its verified mark); a boss whose every item and ability, a spawn whose
                       every point, an entry whose every field of the play list (the schema's) was confirmed counts
                       as whole, the fields over all saved files taken (the ledger); other parts are counted
  tally[build]         what play counted (Tally.lua): added up in the ledger (play.py), staged once enough agree

The file is read as data, never run: a small reader of the Lua the game writes. Only the part of the folder's own game
version is taken (its product in .flavor.info), and only game facts: nothing else of the saved file is looked at.
"""
import collections
import datetime
import json
import math
import os
import re

import compile as compiler
import master as masters
import play as plays

LIST, PART = "\x1e", "\x1f"
STAGING = masters.MASTER.parent.parent / "dev" / "data" / "staging"
EPOCH = datetime.date(1970, 1, 1)
# A set whose entries are confirmed in parts: the fields a part's letter names.
PARTS = {"Bosses": {"l": "loot", "a": "abilities"}}


# The Lua the game writes -----------------------------------------------------------------------------------

TOKEN = re.compile(r'\s*(?:(--\[\[.*?\]\])|(--[^\n]*)|("(?:\\.|[^"\\])*")|(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)|'
                   r'([A-Za-z_][A-Za-z0-9_]*)|(\[\[.*?\]\])|(.))', re.S)
ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'", "a": "\a", "b": "\b", "f": "\f", "v": "\v",
           "\n": "\n"}


def _string(text):
    out, index = [], 1
    while index < len(text) - 1:
        char = text[index]
        if char != "\\":
            out.append(char)
            index += 1
            continue
        after = text[index + 1]
        if after.isdigit():
            digits = re.match(r"\d{1,3}", text[index + 1:]).group(0)
            out.append(chr(int(digits)))
            index += 1 + len(digits)
        else:
            out.append(ESCAPES.get(after, after))
            index += 2
    return "".join(out)


def _tokens(text):
    for match in TOKEN.finditer(text):
        long_comment, comment, string, number, word, long_string, other = match.groups()
        if long_comment or comment:
            continue
        if string is not None:
            yield ("str", _string(string))
        elif number is not None:
            yield ("num", float(number) if any(c in number for c in ".eE") else int(number))
        elif word is not None:
            yield ("word", word)
        elif long_string is not None:
            yield ("str", long_string[2:-2])
        elif other is not None and other.strip():
            yield ("sym", other)


class _Reader:
    def __init__(self, text):
        self.tokens = list(_tokens(text))
        self.at = 0

    def peek(self):
        return self.tokens[self.at] if self.at < len(self.tokens) else (None, None)

    def take(self):
        token = self.peek()
        self.at += 1
        return token

    def value(self):
        kind, value = self.take()
        if kind in ("str", "num"):
            return value
        if kind == "word":
            return {"true": True, "false": False, "nil": None}.get(value)
        if kind == "sym" and value == "{":
            return self.table()
        if kind == "sym" and value == "-":  # a negative number written apart
            return -self.value()
        raise ValueError(f"unexpected {value!r}")

    def table(self):
        out, index = {}, 1
        while True:
            kind, value = self.peek()
            if kind == "sym" and value == "}":
                self.take()
                return out
            if kind == "sym" and value == "[":
                self.take()
                key = self.value()
                self.take()  # ]
                self.take()  # =
                out[key] = self.value()
            elif kind == "word" and self.tokens[self.at + 1] == ("sym", "="):
                self.take()
                self.take()
                out[value] = self.value()
            else:
                out[index] = self.value()
                index += 1
            if self.peek() in (("sym", ","), ("sym", ";")):
                self.take()


def read_saved(text):
    """{global name: value} of a saved file the game wrote, read as data: tables are dicts."""
    reader, out = _Reader(text), {}
    while reader.peek()[0] is not None:
        kind, name = reader.take()
        if kind != "word" or reader.take() != ("sym", "="):
            raise ValueError(f"no assignment at {name!r}")
        out[name] = reader.value()
    return out


# Rows ------------------------------------------------------------------------------------------------------

def _scalar(kind, text):
    if text == "":
        return None
    if kind in ("int", "flags", "money"):
        return int(text)
    if kind == "number":
        number = float(text)
        return int(number) if number.is_integer() and "." not in text else number
    if kind == "bool":
        return True if text == "1" else None
    if kind == "ref":
        return text
    return text  # text, enum


def _element(master, field, kind, text):
    if text == "":
        return None
    if kind == "point":
        parts = text.split(PART)
        return [int(parts[0]), _number(parts[1]), _number(parts[2])]
    if kind == "tuple":
        parts = text.split(PART)
        out = {}
        for index, part in enumerate(field.parts):
            value = _scalar(part.type, parts[index]) if index < len(parts) else None
            if value is not None:
                out[part.name] = _ref(master, part, value)
        return out
    return _ref(master, field, _scalar(kind, text))


def _number(text):
    number = float(text)
    return int(number) if number.is_integer() else number


def _ref(master, field, value):
    """A ref's value as its set's key: a number for a set keyed by numbers."""
    if field.type == "ref" or (field.type in ("list", "map") and field.of == "ref"):
        target = master.schemas.get(field.set)
        if target is not None and target.key == "int" and value is not None:
            return int(value)
    return value


def decode(master, schema, row):
    """A row of a set (build \\t day \\t fields...) as (build, day as YYYY-MM-DD or None, {field: value})."""
    parts = row.split("\t")
    build = int(parts[0])
    day = (EPOCH + datetime.timedelta(days=int(parts[1]))).isoformat() if len(parts) > 1 and parts[1] else None
    fields = {}
    for index, field in enumerate(schema.fields):
        text = parts[index + 2] if index + 2 < len(parts) else ""
        if text == "":
            continue
        if field.type == "list":
            fields[field.name] = [_element(master, field, field.of, item) for item in text.split(LIST)]
        elif field.type == "map":
            value = {}
            for item in text.split(LIST):
                key, _, inner = item.partition(PART)
                value[key] = _element(master, field, field.of, inner)
            fields[field.name] = value
        else:
            fields[field.name] = _element(master, field, field.type, text)
    return build, day, fields


# The harvest -----------------------------------------------------------------------------------------------

def saved_files(wow):
    """[(game version, path)] of the saved files of Sane UI under a WoW folder (each of its game folders _*_)."""
    out = []
    for folder in sorted(wow.glob("_*_")):
        game = compiler.product_game(folder)
        if not game:
            continue
        for path in sorted(folder.glob("WTF/Account/*/SavedVariables/SaneUI.lua")):
            out.append((game, path))
    return out


def sent_files(path):
    """[(None, path)] of the saved files of Sane UI in a WTF folder, a game folder or one file a player sent: each
    game version the file holds is taken (a file sent has no game folder to tell it)."""
    if path.is_file():
        return [(None, path)]
    return [(None, found) for found in sorted(path.glob("**/SavedVariables/SaneUI.lua"))]


def _key(schema, key):
    if schema.key == "int":
        return int(key)
    return str(key)


def code(point):
    """A spawn point as the game names it among an entry's parts (Watchers.lua's Code): "p" and its map and place."""
    map_id, x, y = point[0], point[1], point[2]
    return f"p{(map_id * 1001 + math.floor(x * 10 + 0.5)) * 1001 + math.floor(y * 10 + 0.5)}"


def _whole_by_parts(master, schema, game, key, parts):
    """Whether a set confirmed in parts (PARTS, a spawn's points) had every part of its entry's newest version
    confirmed."""
    versions = master.view(schema.set, game).get(key)
    if not versions or versions[-1].gone:
        return False
    if schema.set == "Spawns":
        points = versions[-1].fields.get("points") or []
        return bool(points) and all(code(point) in parts for point in points)
    names = PARTS.get(schema.set)
    if not names:
        return False
    for letter, field in names.items():
        for value in versions[-1].fields.get(field, []) or []:
            if f"{letter}{value}" not in parts:
                return False
    return True


FIELD_PART = re.compile(r"^([a-z][A-Za-z0-9]*)(=.*)?$")


def _fields_told(parts):
    """The fields a confirmation's parts name (Check.lua's: "name", "startNPCs=69"), not a boss's or a spawn's."""
    out = set()
    for part in parts:
        match = FIELD_PART.match(part)
        if match and not re.match(r"^[a-z]\d+$", part):
            out.add(match.group(1))
    return out


def _told_fields(schema, fields, parts):
    """Of a learned row's fields, those the game told (a list's every member, a map's every key): the rest is the
    set's own carried along, unverified, and not staged. A field told empty is staged empty (null)."""
    how = {told.field.name: told for told in (schema.play or [])}
    named = _fields_told(parts)
    out = {}
    for name in named:
        told = how.get(name)
        value = fields.get(name)
        if value is None:
            if name in parts:
                out[name] = None
        elif told is None or told.how == "whole":
            if name in parts:
                out[name] = value
        elif told.how == "member":
            if all(told.part(element) in parts for element in value):
                out[name] = value
        elif all(told.part(inner) in parts for inner in value):
            out[name] = value
    return out


def _parts(packed):
    """(day, build, parts) of a confirmation as the game packs it; None when it cannot be read."""
    if not isinstance(packed, str):
        return None
    pieces = packed.split(PART)
    try:
        day = (EPOCH + datetime.timedelta(days=int(pieces[0]))).isoformat()
        build = int(pieces[1])
    except (ValueError, IndexError):
        return None
    return day, build, set(pieces[2].split(LIST)) if len(pieces) > 2 else set()


def harvest(master, files, ledger=None):
    """(staging lines, report) of saved files [(game version or None for each it holds, path)]: learned rows,
    confirmations, and what play counted (the ledger, play.py; a ledger without a file when none is given)."""
    ledger = ledger or plays.Ledger(None)
    lines = []
    report = {"learned": 0, "confirmed": 0, "parts": 0, "skipped": 0, "broken": 0, "builds": {}, "counted": 0,
              "staged": collections.Counter(), "waiting": collections.Counter(), "changes": [], "dropped": 0}
    newest = {}  # game -> the newest build its saved files were of
    for wanted, path in files:
        try:
            saved = read_saved(path.read_text(encoding="utf-8", errors="replace"))
        except (ValueError, IndexError) as problem:
            report["broken"] += 1
            print(f"{path}: cannot be read ({problem})")
            continue
        learned_all = saved.get("SaneUIData_Learned") or {}
        games = [wanted] if wanted else [game for game in learned_all if game in master.games]
        for game in games:
            part = learned_all.get(game)
            if isinstance(part, dict):
                lines += _harvest_part(master, game, part, ledger, report, newest)
    day = plays.today()
    for game, build in sorted(newest.items()):
        for stage in (plays.drops, plays.spawns, plays.areas):
            lines += stage(master, ledger, game, build, day, report)
    return lines, report


def _harvest_part(master, game, part, ledger, report, newest):
    lines = []
    patches = part.get("builds") if isinstance(part.get("builds"), dict) else {}

    def seen(build, day):
        """Notes a build of this game version, its patch (as the game said it) and the first day it was seen."""
        newest[game] = max(newest.get(game, 0), build or 0)
        if build in master.builds.get(game, {}) or not is_patch(patches.get(build)):
            return
        known = report["builds"].setdefault(game, {})
        patch, first = known.get(build, (patches[build], day))
        known[build] = (patch, min(first, day) if first and day else first or day)

    told = {}  # (set, key) -> the parts the game told of it in this file
    for set_name, entries in (part.get("confirmed") or {}).items():
        schema = master.schemas.get(set_name)
        if schema is None or not isinstance(entries, dict):
            continue
        for key, packed in entries.items():
            found = _parts(packed)
            if found:
                told[(set_name, _key(schema, key))] = found
    for set_name, rows in (part.get("learned") or {}).items():
        schema = master.schemas.get(set_name)
        if schema is None or not isinstance(rows, dict):
            report["skipped"] += 1
            continue
        for key, row in rows.items():
            try:
                build, day, fields = decode(master, schema, row)
            except (ValueError, IndexError, TypeError):
                report["broken"] += 1
                continue
            key = _key(schema, key)
            parts = (told.get((set_name, key)) or (None, None, set()))[2]
            if _fields_told(parts):
                union = ledger.take_told(game, set_name, key, parts, day, build)
                fields = _told_fields(schema, fields, union)
                if not fields:
                    report["parts"] += 1
                    continue
            line = {"set": set_name, "key": key, "game": game, "build": build, "src": "game", "fields": fields}
            if day:
                line["day"] = day
            seen(build, day)
            lines.append(line)
            report["learned"] += 1
    for set_name, entries in (part.get("confirmed") or {}).items():
        schema = master.schemas.get(set_name)
        if schema is None or not isinstance(entries, dict):
            report["skipped"] += 1
            continue
        for key in entries:
            key = _key(schema, key)
            found = told.get((set_name, key))
            if not found:
                report["broken"] += 1
                continue
            day, build, parts = found
            seen(build, day)
            if (set_name in (part.get("learned") or {}) and key in {_key(schema, k) for k in part["learned"][set_name]}):
                continue  # its row staged above, with what the game told of it
            whole = "*" in parts or _whole_by_parts(master, schema, game, key, parts)
            if not whole and _fields_told(parts):
                union = ledger.take_told(game, set_name, key, parts, day, build)
                versions = master.view(set_name, game).get(key)
                whole = bool(versions) and not versions[-1].gone and plays.covered(schema, versions[-1].fields, union)
            if whole:
                lines.append({"set": set_name, "key": key, "game": game, "build": build, "src": "game", "confirmed": day})
                report["confirmed"] += 1
            else:
                report["parts"] += 1
    ledger.take_maps(game, part.get("maps"))
    for build, block in (part.get("tally") or {}).items():
        if isinstance(block, dict) and isinstance(build, int):
            seen(build, None)
            ledger.take_block(game, build, block, report)
    return lines


PATCH = re.compile(r"^\d+\.\d+\.\d+$")


def is_patch(value):
    """Whether a saved file's patch is a patch number as builds.toml names one (1.60.1): the game writes it, but
    the file is anyone's, and nothing else goes into the master."""
    return isinstance(value, str) and bool(PATCH.match(value))


def add_builds(master, builds):
    """Adds builds the master does not know yet to builds.toml, each at the end of its game version's table:
    {game: {build: (patch, first day)}}; one whose patch is no patch number (is_patch) is left out. The file is
    written whole beside itself, then moved over (never half of it). Returns how many were added."""
    path = master.root / "builds.toml"
    text = path.read_text(encoding="utf-8").splitlines()
    added = 0
    for game, found in sorted(builds.items()):
        header = f"[{game}]"
        if header not in text:
            continue
        end = text.index(header) + 1
        while end < len(text) and not text[end].startswith("["):
            end += 1
        while end > 0 and not text[end - 1].strip():
            end -= 1
        for build in sorted(found):
            patch, day = found[build]
            if not is_patch(patch):
                continue
            words = f'{build} = {{ patch = "{patch}"' + (f', day = "{day}"' if day else "") + " }"
            text.insert(end, words)
            end += 1
            added += 1
    if added:
        temp = path.with_name(path.name + ".tmp")
        temp.write_text("\n".join(text) + "\n", encoding="utf-8")
        os.replace(temp, path)
    return added


def write(lines, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(line, ensure_ascii=False, separators=(",", ":")) + "\n" for line in lines),
                    encoding="utf-8")
