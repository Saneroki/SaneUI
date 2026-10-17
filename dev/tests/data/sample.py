#!/usr/bin/env python3
"""The sample master (dev/tests/data/sample) compiled for the game's tests (dev/tests/data.lua): the packs of
each game version into <folder>/<game version>/, and next to them expected-<game version>.lua, every
version of every entry as the Python side means it, for Lua to compare with what its codec reads. The one
place the two languages are held in step.

Usage: python3 -I dev/tests/data/sample.py <folder>"""
import sys
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[2] / "dev" / "data"))

import check as checks  # noqa: E402
import compile as compiler  # noqa: E402
import master as masters  # noqa: E402

GAMES = ("forever", "forever-beta")


def lua(value, field=None, kind=None):
    """A field's value as a Lua table, as Codec.lua gives it."""
    kind = kind or field.type
    if kind == "list":
        return "{ " + ", ".join(lua(item, field, field.of) for item in value) + " }"
    if kind == "map":
        return "{ " + ", ".join(f"[{key if field.keys == 'int' else compiler.lua_string(key)}] = {lua(item, field, field.of)}"
                                for key, item in sorted(value.items())) + " }"
    if kind == "point":
        return f"{{ map = {value[0]}, x = {compiler.number(value[1])}, y = {compiler.number(value[2])} }}"
    if kind == "tuple":
        return "{ " + ", ".join(f"{part.name} = {lua(value[part.name], part, part.type)}" for part in field.parts
                                if value.get(part.name) not in (None, False)) + " }"
    if kind == "bool":
        return "true"
    if kind == "number":
        return compiler.number(value)
    if isinstance(value, int):
        return str(value)
    return compiler.lua_string(str(value))


def version_lua(schema, version):
    parts = [f"since = {version.since}"]
    if version.day:
        parts.append(f"day = {masters.day_number(version.day)}")
    if version.gone:
        parts.append("gone = true")
    for field in schema.fields:
        value = version.fields.get(field.name)
        # false is no value: the codec leaves it out, as it does an empty part
        if value is not None and value is not False and not version.gone:
            parts.append(f"{field.name} = {lua(value, field)}")
    return "{ " + ", ".join(parts) + " }"


def expected(master, game):
    """return { [set] = { [key] = { version, ... } } }, oldest version first."""
    lines = ["-- Made by dev/tests/data/sample.py: every version of the sample master's entries, as Lua reads them.",
             "return {"]
    for name in sorted(master.schemas):
        schema = master.schemas[name]
        view = master.view(name, game)
        lines.append(f"    [{compiler.lua_string(name)}] = {{")
        for key in sorted(view, key=lambda k: (isinstance(k, str), k)):
            versions = ", ".join(version_lua(schema, version) for version in view[key])
            lines.append(f"        [{compiler.lua_value(key)}] = {{ {versions} }},")
        lines.append("    },")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main(folder):
    master = masters.Master(HERE / "sample").load()
    checks.check(master)
    if master.errors:
        print("\n".join(master.errors), file=sys.stderr)
        return 1
    for game in GAMES:
        target = folder / game
        target.mkdir(parents=True, exist_ok=True)
        compiler.compile_packs(master, target, game)
        (folder / f"expected-{game}.lua").write_text(expected(master, game), encoding="utf-8")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__.split("Usage: ")[1], file=sys.stderr)
        sys.exit(2)
    sys.exit(main(Path(sys.argv[1])))
