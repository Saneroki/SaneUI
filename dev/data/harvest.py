"""The harvest (Doc/guides/data.md, *The harvest*): what Core learned and confirmed in play, read from the game's saved
files into staging for the import.

Core keeps in SaneUIData_Learned[game] (in WTF/Account/<account>/SavedVariables/SaneUI.lua):
  learned[set][key]    a whole row of the set, as the game showed it (Data.Learn, or taken from a guild or group
                       member's Sane UI): staged as the game's facts at the row's build and day
  confirmed[set][key]  "day\\031build\\031parts": the game agreed with the entry ("*" the whole entry) or with parts of
                       it (a boss's item "l17076", its ability "a8269"): the whole entry staged as confirmed (the
                       import writes its verified mark); a boss whose every item and ability the set names was
                       confirmed counts as whole; other parts stay in the game, counted in the report

The file is read as data, never run: a small reader of the Lua the game writes. Only the part of the folder's own game
version is taken (its product in .flavor.info), and only game facts: nothing else of the saved file is looked at.
"""
import datetime
import json
import re

import compile as compiler
import master as masters

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


def _key(schema, key):
    if schema.key == "int":
        return int(key)
    return str(key)


def _whole_by_parts(master, schema, game, key, parts):
    """Whether a set confirmed in parts (PARTS) had every part of its entry's newest version confirmed."""
    names = PARTS.get(schema.set)
    if not names:
        return False
    versions = master.view(schema.set, game).get(key)
    if not versions or versions[-1].gone:
        return False
    for letter, field in names.items():
        for value in versions[-1].fields.get(field, []) or []:
            if f"{letter}{value}" not in parts:
                return False
    return True


def harvest(master, files):
    """(staging lines, report) of saved files [(game version, path)]: learned rows and whole confirmations."""
    lines, report = [], {"learned": 0, "confirmed": 0, "parts": 0, "skipped": 0, "broken": 0, "builds": {}}
    for game, path in files:
        try:
            saved = read_saved(path.read_text(encoding="utf-8", errors="replace"))
        except (ValueError, IndexError) as problem:
            report["broken"] += 1
            print(f"{path}: cannot be read ({problem})")
            continue
        part = (saved.get("SaneUIData_Learned") or {}).get(game)
        if not isinstance(part, dict):
            continue
        patches = part.get("builds") if isinstance(part.get("builds"), dict) else {}

        def seen(build, day):
            """Notes a build of this game version, its patch (as the game said it) and the first day it was seen."""
            if build in master.builds.get(game, {}) or not isinstance(patches.get(build), str):
                return
            known = report["builds"].setdefault(game, {})
            patch, first = known.get(build, (patches[build], day))
            known[build] = (patch, min(first, day) if first and day else first or day)
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
                line = {"set": set_name, "key": _key(schema, key), "game": game, "build": build, "src": "game",
                        "fields": fields}
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
            for key, packed in entries.items():
                if not isinstance(packed, str):
                    report["broken"] += 1
                    continue
                pieces = packed.split(PART)
                try:
                    day = (EPOCH + datetime.timedelta(days=int(pieces[0]))).isoformat()
                    build = int(pieces[1])
                except (ValueError, IndexError):
                    report["broken"] += 1
                    continue
                parts = set(pieces[2].split(LIST)) if len(pieces) > 2 else set()
                seen(build, day)
                key = _key(schema, key)
                if "*" in parts or _whole_by_parts(master, schema, game, key, parts):
                    lines.append({"set": set_name, "key": key, "game": game, "build": build, "src": "game",
                                  "confirmed": day})
                    report["confirmed"] += 1
                else:
                    report["parts"] += 1
    return lines, report


def add_builds(master, builds):
    """Adds builds the master does not know yet to builds.toml, each at the end of its game version's table:
    {game: {build: (patch, first day)}}. Returns how many."""
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
            words = f'{build} = {{ patch = "{patch}"' + (f', day = "{day}"' if day else "") + " }"
            text.insert(end, words)
            end += 1
            added += 1
    path.write_text("\n".join(text) + "\n", encoding="utf-8")
    return added


def write(lines, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(line, ensure_ascii=False, separators=(",", ":")) + "\n" for line in lines),
                    encoding="utf-8")
