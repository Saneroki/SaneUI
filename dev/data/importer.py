"""Staging into the master (Doc/guides/data.md, *Staging and the import*).

Every staged line is compared with its own game version's view and written only into that game version's
files. Live's lines are taken in first, so another game version stands on what the import made of live.
The report comes first; the master changes only when the caller writes it (`apply`).
"""
import itertools
import json

import master as masters
import schema as schemas

STAGING_WORDS = ("set", "key", "game", "build", "day", "src", "fields", "gone", "replaces")
CASES = ("new", "agreeing", "changed", "older", "gone", "conflict", "taken", "refused")
LISTED = ("conflict", "taken", "refused")
UNTAKEN = " (--take does not mend this: mend it by hand)"


class Report:
    """What an import found, per set and game version: counts, and the lines it listed."""

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
            words = ", ".join(f"{counts[case]} {case}" for case in CASES if counts.get(case))
            out.append(f"{set_name} ({game}): {words}")
        for case in LISTED:
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
    if data.get("gone", False) not in (True, False) or (data.get("gone") and (fields or data.get("replaces") is not None)):
        return "gone is true, with no fields and no replaces"
    if data.get("gone") and info["kind"] == "batch":
        return "a batch cannot say an entry is gone (missing from a source is no proof)"
    replaces = data.get("replaces")
    if replaces is not None and type(replaces) is not schema.key_type():
        return f"replaces is a key of {schema.set}"
    if replaces is not None and replaces == key:
        return "an entry cannot replace itself"
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


class Entry:
    """One entry of a set in one game version while it is taken in: the version it stands on (another game
    version's base: live's newest), the replaces live's first line names, and its own lines."""

    def __init__(self, base=None, base_replaces=None, lines=()):
        self.base, self.base_replaces = base, base_replaces
        self.lines = sorted(lines, key=masters.Line.order)

    def versions(self):
        out = [self.base] if self.base is not None else []
        for line in self.lines:
            masters.apply(out, line)
        return out

    def replaces(self):
        if self.lines and self.lines[0].replaces is not None:
            return self.lines[0].replaces
        return self.base_replaces

    def add(self, line):
        self.lines.append(line)
        self.lines.sort(key=masters.Line.order)


def _entries(master, set_name, game):
    """{key: Entry} of a set in a game version, as the master holds it now."""
    base, base_replaces = {}, {}
    if masters.base_of(game) != game:
        for key, versions in master.view(set_name, masters.base_of(game), fixes=False).items():
            if not versions[-1].gone:
                base[key] = masters.Version(0, None, False, dict(versions[-1].fields), None)
                base_replaces[key] = versions[0].line.replaces if versions[0].line else None
    own = {}
    for line in master.lines.get((set_name, game), []):
        own.setdefault(line.key, []).append(line)
    return {key: Entry(base.get(key), base_replaces.get(key), own.get(key, [])) for key in set(base) | set(own)}


def _agrees(name, value, fields):
    """Whether a staged value says what a version has (None: the field is empty)."""
    if value is None:
        return name not in fields
    return name in fields and schemas.same(value, fields[name])


def _laid(fields, changes):
    """A version's fields with changes laid on (None clears)."""
    out = dict(fields)
    for name, value in changes.items():
        if value is None:
            out.pop(name, None)
        else:
            out[name] = value
    return out


def _add_source(line, src):
    """Adds a source to a line's; True when it was not there yet."""
    if line is None or masters.source_name(src) in map(masters.source_name, line.src):
        return False
    line.src.append(src)
    return True


def _tidy(entry):
    """After a line was put in or mended: every later line holds only what it changes, and one that changes
    nothing any more is dropped, its sources going to the version before it."""
    kept, versions = [], [entry.base] if entry.base is not None else []
    for line in entry.lines:
        last = versions[-1] if versions else None
        if not line.gone and last is not None and not last.gone:
            line.fields = {name: value for name, value in line.fields.items() if not _agrees(name, value, last.fields)}
            if not line.fields and line.replaces is None:
                for src in line.src:
                    _add_source(last.line, src)
                continue
        kept.append(line)
        masters.apply(versions, line)
    entry.lines = kept


def _shown(value):
    return "empty" if value is None else json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def _when(version):
    return f"{version.since}" + (f" on {version.day}" if version.day else "")


def _whole(entry, versions, index):
    """Whether the line of versions[index] holds every fact (an entry's first, or the first after gone)."""
    if index == 0:
        return entry.base is None or versions[0].line is None
    return versions[index - 1].gone


def _take(master, report, entry, known, where, data, take):
    """Takes one staged line into its entry; True when a line of the master changed."""
    set_name, game, key = data["set"], data["game"], data["key"]
    build, day, src = data.get("build", 0), data.get("day"), data["src"]
    clock = (build, day or "")
    kind = master.sources[masters.source_name(src)]["kind"]
    fields, gone, replaces = data.get("fields", {}), data.get("gone", False), data.get("replaces")
    if replaces is not None and replaces not in known:
        report.list("refused", where, set_name, game, f"replaces {replaces!r}, which {game} does not have")
        return False
    versions = entry.versions()

    if not versions:  # new
        if gone:
            report.list("refused", where, set_name, game, "an entry that is not there cannot be gone")
            return False
        facts = {name: value for name, value in fields.items() if value is not None}
        if not facts:
            report.list("refused", where, set_name, game, "a new entry needs at least one fact")
            return False
        entry.add(masters.Line(key, build, day, [src], False, replaces, facts, where))
        report.count(set_name, game, "new")
        return True

    touched = False
    if replaces is not None and replaces != entry.replaces():
        said = entry.replaces()
        text = f"replaces {replaces!r}; the master names {said!r}" if said is not None else f"replaces {replaces!r}; the master names none"
        if not (take and entry.lines and entry.base is None):
            report.list("conflict", where, set_name, game, text + ("" if not take else UNTAKEN))
            return False
        entry.lines[0].replaces = replaces
        report.list("taken", where, set_name, game, text)
        touched = True

    version = masters.current(versions, build, day)
    if version is None:  # older than the entry's first version
        first = versions[0]
        if gone:
            report.list("refused", where, set_name, game, f"gone before its first version ({_when(first)})")
            return touched
        if all(_agrees(name, value, first.fields) for name, value in fields.items()):
            report.count(set_name, game, "agreeing")
            return _add_source(first.line, src) or touched
        whole = _laid(first.fields, fields)
        if not whole:
            report.list("refused", where, set_name, game, "leaves the entry with no value")
            return touched
        old = first.line
        old.fields = {name: value for name, value in first.fields.items() if not _agrees(name, value, whole)}
        old.fields.update({name: None for name in whole if name not in first.fields})
        entry.add(masters.Line(key, build, day, [src], False, old.replaces, whole, where))
        old.replaces = None
        report.count(set_name, game, "older")
        return True

    newest = version is versions[-1]
    if version.gone:
        if gone:
            report.count(set_name, game, "agreeing")
            return _add_source(version.line, src) or touched
        facts = {name: value for name, value in fields.items() if value is not None}
        if kind == "game" and clock > version.clock() and newest and facts:
            entry.add(masters.Line(key, build, day, [src], False, None, facts, where))  # it came back
            report.count(set_name, game, "changed")
            return True
        report.list("conflict", where, set_name, game, f"the master has it gone from {_when(version)}" + (UNTAKEN if take else ""))
        return touched

    if gone:
        if clock > version.clock() and newest:
            entry.add(masters.Line(key, build, day, [src], True, None, {}, where))
            report.count(set_name, game, "gone")
            return True
        later = "a later version" if not newest else f"a version at {_when(version)}"
        report.list("conflict", where, set_name, game, f"gone at {build}, but the master has {later}" + (UNTAKEN if take else ""))
        return touched

    differs = {name: value for name, value in fields.items() if not _agrees(name, value, version.fields)}
    if not differs:
        report.count(set_name, game, "agreeing")
        return _add_source(version.line, src) or touched
    if not _laid(version.fields, differs):
        report.list("refused", where, set_name, game, "leaves the entry with no value (stage gone instead)")
        return touched
    if kind == "game" and clock > version.clock():
        entry.add(masters.Line(key, build, day, [src], False, None, differs, where))
        _tidy(entry)
        report.count(set_name, game, "changed")
        return True
    text = "; ".join(f"{name}: {_shown(version.fields.get(name))} in the master ({_when(version)}), {_shown(value)} staged"
                     for name, value in differs.items())
    if not take:
        report.list("conflict", where, set_name, game, text)
        return touched
    index = versions.index(version)
    if version.line is None:  # another game version's base: the correction is its own line over it
        entry.add(masters.Line(key, 0, None, [src], False, None, differs, where))
    else:
        line, whole = version.line, _whole(entry, versions, index)
        for name, value in differs.items():
            if value is None and whole:
                line.fields.pop(name, None)
            else:
                line.fields[name] = value
        _add_source(line, src)
    _tidy(entry)
    report.list("taken", where, set_name, game, text)
    return True


def run(master, staged, take=False):
    """Takes staged lines [(where, data)] into the loaded master's lines (not written yet). Returns a Report.
    take: a conflict is written into its version as a correction."""
    report = Report()
    work = []
    for where, data in staged:
        problem = _refusal(master, data)
        if problem:
            set_name = data.get("set", "?") if isinstance(data, dict) else "?"
            game = data.get("game", "?") if isinstance(data, dict) else "?"
            report.list("refused", where, set_name, game, problem)
            continue
        if isinstance(data["src"], str) and data["src"].isdigit():
            data = {**data, "src": int(data["src"])}  # a batch's number, as the master writes it
        work.append((where, data))
    # Live first, then the game versions that stand on it; one entry's lines in order of build and day, each
    # against what the ones before made.
    work.sort(key=lambda item: (masters.base_of(item[1]["game"]) != item[1]["game"], item[1]["set"], item[1]["game"],
                                item[1]["key"], item[1].get("build", 0), item[1].get("day", "")))
    for (set_name, game), items in itertools.groupby(work, key=lambda item: (item[1]["set"], item[1]["game"])):
        items = list(items)
        entries = _entries(master, set_name, game)
        known = set(entries) | {data["key"] for _, data in items if not data.get("gone")}
        touched = False
        for where, data in items:
            entry = entries.setdefault(data["key"], Entry())
            touched = _take(master, report, entry, known, where, data, take) or touched
        if touched:
            master.lines[(set_name, game)] = sorted((line for entry in entries.values() for line in entry.lines),
                                                    key=masters.Line.order)
            report.changed.add((set_name, game))
    return report


def apply(master, report):
    """Writes every set and game version the import changed."""
    for set_name, game in sorted(report.changed):
        masters.write(master, set_name, game, master.lines[(set_name, game)])
