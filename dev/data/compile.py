"""The master into packs (Doc/guides/data.md, *Compiling: the packs*).

A pack is a load-on-demand addon, SaneUI_Data_<Pack>: its TOC, one Lua file per set and the project's
licence. Compiling is a pure function of the master: no date, no clock, entries sorted by key, so the same
master always gives the same bytes.
"""
import hashlib
import re
import shutil

import master as masters

FORMAT = 1
CHUNK = 50_000  # statements per Fill function: Lua 5.1 stops at 262,143 constants in one function
PREFIX = "SaneUI_Data_"
CORE_TOC = masters.ROOT / "src" / "Core" / "SaneUI.toc"
LICENSE = masters.ROOT / "LICENSE"
PLACEHOLDER = "00000000"
LIST, PART, VERSION = "\x1e", "\x1f", "\x1c"  # characters 30, 31 and 28
KEYWORDS = set("and break do else elseif end false for function if in local nil not or repeat return then true until while".split())
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
# The products a game folder's .flavor.info names, and the game version each serves today. A beta or PTR
# product serves whichever game is tested in it (Doc/ideas/SaneSync.md, *Finding the game*).
PRODUCTS = {"wowf": "forever", "wow_classic_beta": "forever-beta"}


def core_toc():
    """Core's Interface and Version, which every pack carries."""
    fields = {}
    for line in CORE_TOC.read_text(encoding="utf-8").splitlines():
        match = re.match(r"##\s*([^:]+?)\s*:\s*(.*)$", line)
        if match:
            fields[match.group(1)] = match.group(2).strip()
    return fields.get("Interface", ""), fields.get("Version", "")


def product_game(folder):
    """The game version a game folder holds, by the product its .flavor.info names; None if not known."""
    path = folder / ".flavor.info"
    if not path.exists():
        return None
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        word = line.strip()
        if word in PRODUCTS:
            return PRODUCTS[word]
    return None


# Rows ---------------------------------------------------------------------------------------------------

def number(value):
    """A number as Lua writes it (%.14g); a whole number as it is."""
    if isinstance(value, int):
        return str(value)
    text = "%.14g" % value
    return text


def scalar(kind, value):
    if value is None:
        return ""
    if kind in ("int", "flags", "money"):
        return str(value)
    if kind == "number":
        return number(value)
    if kind == "bool":
        return "1" if value is True else ""
    return str(value)  # text, enum, ref


def element(field, kind, value):
    if kind == "point":
        return PART.join((str(value[0]), number(value[1]), number(value[2])))
    if kind == "tuple":
        return PART.join(scalar(part.element, value.get(part.name)) for part in field.parts)
    return scalar(kind, value)


def encode(field, value):
    """A field's value as it stands in a row."""
    if value is None:
        return ""
    if field.type == "list":
        return LIST.join(element(field, field.of, item) for item in value)
    if field.type == "map":
        keys = sorted(value, key=int) if field.keys == "int" else sorted(value)
        return LIST.join(key + PART + element(field, field.of, value[key]) for key in keys)
    return element(field, field.type, value)


def row(schema, version):
    """One version as a row: build, day, then the fields, empty ones at the end left out."""
    head = [str(version.since), str(masters.day_number(version.day)) if version.day else ""]
    if version.gone:
        return "\t".join(head)
    fields = [encode(field, version.fields.get(field.name)) for field in schema.fields]
    while fields and fields[-1] == "":
        fields.pop()
    return "\t".join(head + fields)


def decoder_type(master, field, kind=None):
    """A field's type as the game's codec reads it (Doc/guides/data.md, *A set's file*)."""
    kind = kind or field.type
    if kind == "list":
        return "list " + decoder_type(master, field, field.of)
    if kind == "map":
        return f"map {field.keys} " + decoder_type(master, field, field.of)
    if kind == "tuple":
        return "tuple(" + ",".join(f"{part.name}:{decoder_type(master, part, part.type)}" for part in field.parts) + ")"
    if kind in ("int", "flags", "money"):
        return "int"
    if kind in ("text", "enum"):
        return "text"
    if kind == "ref":
        return "int" if master.schemas[field.set].key == "int" else "text"
    return kind  # number, bool, point


# Lua ----------------------------------------------------------------------------------------------------

def lua_string(text):
    out = ['"']
    for char in text:
        code = ord(char)
        if char == "\\":
            out.append("\\\\")
        elif char == '"':
            out.append('\\"')
        elif char == "\n":
            out.append("\\n")
        elif char == "\t":
            out.append("\\t")
        elif code < 32 or code == 127:
            out.append(f"\\{code:03d}")
        else:
            out.append(char)
    out.append('"')
    return "".join(out)


def lua_key(key):
    """A table key: [16801], .name, or ["with space"]."""
    if isinstance(key, int):
        return f"[{key}]"
    if IDENTIFIER.match(key) and key not in KEYWORDS:
        return "." + key
    return f"[{lua_string(key)}]"


def lua_value(value):
    if isinstance(value, int):
        return str(value)
    return lua_string(value)


def chunks(statements):
    """Statements in Fill functions of at most CHUNK each."""
    out = []
    for start in range(0, len(statements), CHUNK):
        out.append("Fill(function()")
        out += statements[start:start + CHUNK]
        out.append("end)")
    return out


def index_key(field, value, master):
    """An index value as a Lua table key: a number for whole-number kinds, else text."""
    kind = field.element
    if kind == "ref":
        return value if master.schemas[field.set].key == "int" else str(value)
    return value if kind in ("int", "flags", "money") else str(value)


def set_file(master, schema, game):
    """(text, entries) of a set's Lua file for a game version."""
    view = master.view(schema.set, game)
    keys = sorted(view)
    rows, history, patches = [], [], {}
    for key in keys:
        versions = view[key]
        for version in versions:
            if version.since:
                patches[version.since] = master.builds[game][version.since]["patch"]
        rows.append(f"R{lua_key(key)} = {lua_string(row(schema, versions[-1]))}")
        if len(versions) > 1:
            history.append(f"H{lua_key(key)} = {lua_string(VERSION.join(row(schema, v) for v in versions[:-1]))}")
    indexes = {}
    for name, field in schema.index.items():
        table = {}
        for key in keys:
            newest = view[key][-1]
            if newest.gone or field.name not in newest.fields:
                continue
            value = newest.fields[field.name]
            for each in (value if field.type == "list" else [value]):
                table.setdefault(index_key(field, each, master), []).append(key)
        indexes[name] = table
    replaces, replaced_by = {}, {}
    for line in master.fixed(schema.set, masters.base_of(game)) + (master.fixed(schema.set, game) if masters.base_of(game) != game else []):
        if line.replaces is not None and line.key in view and line.replaces in view:
            replaces[line.key] = [line.replaces]
            replaced_by.setdefault(line.replaces, []).append(line.key)
    if replaces:
        indexes["replaces"] = replaces
        indexes["replacedBy"] = replaced_by
    build = 0
    for line in master.fixed(schema.set, game):
        build = max(build, line.since)
        for src in line.src:
            info = master.sources.get(masters.source_name(src), {})
            if info.get("kind") == "batch" and info.get("game") == game and info.get("build"):
                build = max(build, info["build"])
    fields = ", ".join(lua_string(field.name) for field in schema.fields)
    types = ", ".join(lua_string(decoder_type(master, field)) for field in schema.fields)
    patch_text = ", ".join(f"[{since}] = {lua_string(patches[since])}" for since in sorted(patches))
    lines = [
        f"-- Made by dev/tools/data from assets/data/{schema.set}; change the master, not this file.",
        f"local S = SaneUI.Core.Data.Add({FORMAT}, {lua_string(schema.set)}, {{",
        f"    game = {lua_string(game)}, hash = {lua_string(PLACEHOLDER)}, build = {build}, key = {lua_string(schema.key)},",
        f"    fields = {{ {fields} }},",
        f"    types = {{ {types} }},",
        f"    patches = {{ {patch_text} }},",
        "})",
        "if not S then return end",
        "local R, H, I = S.rows, S.history, S.index",
        "local function Fill(f) f() end",
    ]
    lines += chunks(rows) + chunks(history)
    for name in sorted(indexes):
        table = indexes[name]
        if not table:
            continue
        lines.append(f"I{lua_key(name)} = {{}}")
        order = sorted(table, key=lambda value: (isinstance(value, str), value))
        lines += chunks([f"I{lua_key(name)}[{lua_value(value)}] = {lua_string(LIST.join(str(k) for k in sorted(table[value], key=lambda k: (isinstance(k, str), k))))}"
                         for value in order])
    text = "\n".join(lines) + "\n"
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()[:8]
    return text.replace(f"hash = {lua_string(PLACEHOLDER)}", f"hash = {lua_string(digest)}", 1), len(keys)


def toc(master, pack, sets, game, interface, version):
    info = master.packs[pack]
    lines = [
        f"## Interface: {interface}",
        f"## Title: {info['title']}",
        f"## Notes: {info['notes']}",
        "## Author: Saneroki",
        f"## Version: {version}",
        "## Category: Sane UI",
        "## Group: SaneUI",
        "## Dependencies: SaneUI",
        "## LoadOnDemand: 1",
        f"## SavedVariables: SaneUIData_{pack}",
        f"## X-SaneUI-Sets: {', '.join(sets)}",
        f"## X-SaneUI-Format: {FORMAT}",
        f"## X-SaneUI-Game: {game}",
        "## X-License: MIT",
        "",
        "# Made by dev/tools/data from the master in assets/data; change the master, not this folder.",
    ] + [f"{name}.lua" for name in sets]
    return "\n".join(lines) + "\n"


def compile_packs(master, folder, game):
    """Writes the packs of a game version into folder; removes the SaneUI_Data_* folders there it no longer
    makes. Returns [(pack, sets, entries)] of the packs made."""
    interface, version = core_toc()
    made = []
    for pack in sorted(master.packs):
        sets = sorted(name for name, schema in master.schemas.items() if schema.pack == pack)
        files, entries = {}, 0
        for name in sets:
            text, count = set_file(master, master.schemas[name], game)
            files[f"{name}.lua"] = text
            entries += count
        if not entries:
            continue
        target = folder / f"{PREFIX}{pack}"
        if target.exists():
            shutil.rmtree(target)
        target.mkdir(parents=True)
        (target / f"{PREFIX}{pack}.toc").write_text(toc(master, pack, sets, game, interface, version), encoding="utf-8")
        for name, text in files.items():
            (target / name).write_text(text, encoding="utf-8")
        shutil.copyfile(LICENSE, target / "LICENSE.txt")
        made.append((pack, sets, entries))
    names = {f"{PREFIX}{pack}" for pack, _, _ in made}
    for old in sorted(folder.glob(f"{PREFIX}*")):
        if old.is_dir() and old.name not in names:
            shutil.rmtree(old)
    return made
