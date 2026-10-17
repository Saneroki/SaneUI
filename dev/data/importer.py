"""Staging into the master (Doc/guides/data.md, *Staging and the import*).

Every staged line is compared with its own game version's view and written only into that game version's
files. The report comes first; the master changes only when the caller writes it (`apply`).
"""
import json

import master as masters
import schema as schemas

STAGING_WORDS = ("set", "key", "game", "build", "day", "src", "fields", "gone", "replaces")
NOT_YET = "not taken in yet: changes, conflicts, gone and replaces come with step 1a.6"


class Report:
    """What an import found, per set and game version: counts, and the lines it could not take in."""

    def __init__(self):
        self.counts = {}   # (set, game) -> {"new": n, "agreeing": n, ...}
        self.listed = []   # (case, where, set, game, text)
        self.changed = set()  # (set, game) whose lines changed

    def count(self, set_name, game, case):
        counts = self.counts.setdefault((set_name, game), {})
        counts[case] = counts.get(case, 0) + 1

    def list(self, case, where, set_name, game, text):
        self.count(set_name, game, case)
        self.listed.append((case, where, set_name, game, text))

    def lines(self, most=20):
        out = []
        for (set_name, game), counts in sorted(self.counts.items(), key=lambda item: (str(item[0][0]), item[0][1])):
            words = ", ".join(f"{counts[case]} {case}" for case in ("new", "agreeing", "changed", "older", "gone",
                                                                     "conflict", "later", "refused") if counts.get(case))
            out.append(f"{set_name} ({game}): {words}")
        for case in ("conflict", "later", "refused"):
            listed = [item for item in self.listed if item[0] == case]
            for _, where, set_name, game, text in listed[:most]:
                out.append(f"  {case}: {where}: {set_name} ({game}): {text}")
            if len(listed) > most:
                out.append(f"  ... and {len(listed) - most} more {case}")
        return out


def read_staging(path):
    """[(where, data)] of a staging file; a line that is no JSON object is given as (where, None)."""
    out = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            data = None
        out.append((f"{path.name}:{number}", data if isinstance(data, dict) else None))
    return out


def _refusal(master, data):
    """Why a staged line cannot be taken in, or None."""
    if data is None:
        return "is no JSON object"
    unknown = [word for word in data if word not in STAGING_WORDS]
    if unknown:
        return f"{', '.join(unknown)}: not part of a staging line"
    for word in ("set", "key", "game", "src"):
        if word not in data:
            return f"has no {word}" + (" (every staging line names its game version)" if word == "game" else "")
    schema = master.schemas.get(data["set"])
    if schema is None:
        return f"'{data['set']}' is no set"
    game = data["game"]
    if game not in master.builds:
        return f"'{game}' is no game version of builds.toml"
    key = data["key"]
    if (schema.key == "int" and not schemas._whole(key)) or (schema.key == "text" and schemas._text_problem(key)):
        return f"key {key!r} is no key of {schema.set}"
    build = data.get("build", 0)
    if not schemas._whole(build) or build < 0:
        return "build is a build number (0: not known)"
    if build and build not in master.builds[game]:
        return f"build {build} is not in builds.toml for {game}"
    if "day" in data and not masters.is_day(data["day"]):
        return f"day {data['day']!r} is no date (YYYY-MM-DD)"
    src = data["src"]
    info = master.sources.get(masters.source_name(src)) if isinstance(src, (int, str)) and not isinstance(src, bool) else None
    if info is None:
        return f"source {src!r} is not in sources.toml"
    if info["kind"] == "batch" and info.get("game") != game:
        return f"source {src} is {info.get('game')}'s batch, the line is {game}'s"
    fields = data.get("fields", {})
    if not isinstance(fields, dict):
        return "fields is an object"
    if data.get("gone", False) not in (True, False) or (data.get("gone") and fields):
        return "gone is true, with no fields"
    if not fields and not data.get("gone"):
        return "says nothing (no fields)"
    refs = set()
    for name, value in fields.items():
        if name not in schema.byname:
            return f"field '{name}' is not in the schema of {schema.set}"
        if value is not None:
            problem = schemas.value_problem(schema.byname[name], value, {n: s.key_type() for n, s in master.schemas.items()}, refs)
            if problem:
                return f"{name} {problem}"
    return None


def run(master, staged, take=False):
    """Takes staged lines [(where, data)] into the loaded master's lines (not written yet). Returns a Report."""
    report = Report()
    work = []
    for where, data in staged:
        problem = _refusal(master, data)
        if problem:
            set_name = data.get("set", "?") if isinstance(data, dict) else "?"
            game = data.get("game", "?") if isinstance(data, dict) else "?"
            report.list("refused", where, set_name, game, problem)
            continue
        work.append((where, data))
    # One entry's lines in order of build and day, each against what the ones before made.
    work.sort(key=lambda item: (item[1]["set"], item[1]["game"], item[1]["key"], item[1].get("build", 0), item[1].get("day", "")))
    views = {}
    for where, data in work:
        set_name, game, key = data["set"], data["game"], data["key"]
        if (set_name, game) not in views:
            views[(set_name, game)] = master.view(set_name, game, fixes=False)
        view = views[(set_name, game)]
        build, day = data.get("build", 0), data.get("day")
        fields = {name: value for name, value in data.get("fields", {}).items()}
        src = data["src"]
        lines = master.lines.setdefault((set_name, game), [])
        versions = view.get(key)
        if not versions:
            if data.get("gone"):
                report.list("refused", where, set_name, game, "an entry that is not there cannot be gone")
                continue
            line = masters.Line(key, build, day, [src], False, data.get("replaces"),
                                {name: value for name, value in fields.items() if value is not None}, where)
            if not line.fields:
                report.list("refused", where, set_name, game, "a new entry needs at least one fact")
                continue
            lines.append(line)
            masters.apply(view.setdefault(key, []), line)
            report.count(set_name, game, "new")
            report.changed.add((set_name, game))
            continue
        version = masters.current(versions, build, day)
        agrees = version is not None and not version.gone and not data.get("gone") and all(
            (value is None and name not in version.fields) or
            (value is not None and name in version.fields and schemas.same(value, version.fields[name]))
            for name, value in fields.items())
        if agrees and data.get("replaces") is None:
            line = version.line
            if line is not None and masters.source_name(src) not in map(masters.source_name, line.src):
                line.src.append(src)
                report.changed.add((set_name, game))
            report.count(set_name, game, "agreeing")
            continue
        report.list("later", where, set_name, game, NOT_YET)
    return report


def apply(master, report):
    """Writes every set and game version the import changed."""
    for set_name, game in sorted(report.changed):
        masters.write(master, set_name, game, master.lines[(set_name, game)])
