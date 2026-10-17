"""The master of Core's data framework, assets/data: reading it, working out an entry's versions, writing it.

Doc/guides/data.md, *The master*, is the reference. Reading never stops at a problem: every one is noted
(Master.problems), so the check can list them all at once.
"""
import datetime
import json
import re
import tomllib
from pathlib import Path

import schema as schemas

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "assets" / "data"
LIVE = "forever"  # the game version of a set's plain files (<Set>.jsonl)
GAME = re.compile(r"^[a-z]+(?:-(?:ptr|beta))?$")
DAY = re.compile(r"^\d{4}-\d{2}-\d{2}$")
LINES = re.compile(r"^(?P<set>[A-Za-z][A-Za-z0-9]*)(?:\.(?P<game>[a-z]+(?:-(?:ptr|beta))?))?(?:\.(?P<start>\d+))?\.jsonl$")
FIXES = re.compile(r"^fixes(?:\.(?P<game>[a-z]+(?:-(?:ptr|beta))?))?\.jsonl$")
KINDS = ("game", "hand", "batch")
TOP = ("builds.toml", "sources.toml", "packs.toml")
EPOCH = datetime.date(1970, 1, 1)


def base_of(game):
    """The game version another stands on: forever-beta stands on forever; a live one on itself."""
    return re.sub(r"-(?:ptr|beta)$", "", game)


def is_day(day):
    """Whether a value is a day of the master: a real date written YYYY-MM-DD."""
    if not isinstance(day, str) or not DAY.match(day):
        return False
    try:
        datetime.date.fromisoformat(day)
    except ValueError:
        return False
    return True


def day_number(day):
    """A day of the master (2026-11-03) as days since 1970, as packs and saved files keep it."""
    return (datetime.date.fromisoformat(day) - EPOCH).days


def source_name(src):
    """A source as sources.toml names it: a batch's number as text."""
    return str(src)


class Line:
    """One line of the master: one version of an entry as written (the first one whole, later ones only what
    changed). fields maps a field's name to its value, None for a field the version clears."""
    __slots__ = ("key", "since", "day", "src", "gone", "replaces", "fields", "where")

    def __init__(self, key, since=0, day=None, src=None, gone=False, replaces=None, fields=None, where=""):
        self.key, self.since, self.day = key, since, day
        self.src = list(src or [])
        self.gone, self.replaces = gone, replaces
        self.fields = dict(fields or {})
        self.where = where

    def clock(self):
        """When the version holds from: its build, then its day (none before any)."""
        return (self.since, self.day or "")

    def order(self):
        return (self.key, self.since, self.day or "")


class Version:
    """An entry's version worked out whole: every field it has, or gone. line: the line it came from (None
    for the base another game version stands on)."""
    __slots__ = ("since", "day", "gone", "fields", "line")

    def __init__(self, since, day, gone, fields, line):
        self.since, self.day, self.gone, self.fields, self.line = since, day, gone, fields, line

    def clock(self):
        return (self.since, self.day or "")


class Master:
    def __init__(self, root=MASTER):
        self.root = Path(root)
        self.problems = []   # (level, text): level "error" or "warning"
        self.builds = {}     # game version -> {build: {"patch": ..., "day": ...}}
        self.sources = {}    # name -> {"kind": ..., "game": ..., ...}
        self.packs = {}      # name -> {"title": ..., "notes": ...}
        self.schemas = {}    # set -> Schema
        self.lines = {}      # (set, game) -> [Line], every file of that game version, in file order
        self.files = {}      # (set, game) -> [(start or None, Path)], sorted by start
        self.fixes = {}      # (set, game) -> [Line]
        self.fix_files = {}  # (set, game) -> Path
        self.refs = []       # (where, game, set it points into, key): every ref and replaces read
        self._key_types = {}

    def error(self, text):
        self.problems.append(("error", text))

    def warning(self, text):
        self.problems.append(("warning", text))

    @property
    def errors(self):
        return [text for level, text in self.problems if level == "error"]

    @property
    def warnings(self):
        return [text for level, text in self.problems if level == "warning"]

    @property
    def games(self):
        return list(self.builds)

    def where(self, path):
        try:
            return str(Path(path).relative_to(ROOT))
        except ValueError:
            return str(path)

    # Reading ------------------------------------------------------------------------------------------

    def _toml(self, name):
        path = self.root / name
        if not path.exists():
            self.error(f"{self.where(path)} is missing")
            return {}
        try:
            return tomllib.loads(path.read_text(encoding="utf-8"))
        except (tomllib.TOMLDecodeError, UnicodeDecodeError) as error:
            self.error(f"{self.where(path)} does not parse: {error}")
            return {}

    def load(self):
        """Reads everything: the three tables, every schema, then every set's lines. Returns self."""
        self._load_builds()
        self._load_sources()
        self._load_packs()
        if not self.root.is_dir():
            self.error(f"{self.where(self.root)} is not there")
            return self
        folders = []
        for path in sorted(self.root.iterdir()):
            if path.is_dir():
                if self._load_schema(path):
                    folders.append(path)
            elif path.name not in TOP:
                self.error(f"{self.where(path)}: no file of the master (only {', '.join(TOP)} and a folder per set)")
        self._key_types = {name: schema.key_type() for name, schema in self.schemas.items()}
        for name, schema in self.schemas.items():
            if schema.pack not in self.packs:
                self.error(f"{self.where(self.root / name / 'schema.toml')}: its pack '{schema.pack}' is not in packs.toml")
            for field in schema.fields:
                for inner in [field] + (field.parts or []):
                    if inner.element == "ref" and inner.set not in self.schemas:
                        self.error(f"{self.where(self.root / name / 'schema.toml')}, field {field.name}: points into '{inner.set}', which is no set")
        for folder in folders:
            self._load_lines(folder)
        return self

    def _load_builds(self):
        where = self.where(self.root / "builds.toml")
        for game, builds in self._toml("builds.toml").items():
            if not GAME.match(game):
                self.error(f"{where}: '{game}' is no game version's name (forever, forever-ptr, forever-beta)")
                continue
            if not isinstance(builds, dict):
                self.error(f"{where}: [{game}] holds its builds")
                continue
            self.builds[game] = {}
            for build, info in builds.items():
                if not build.isdigit() or int(build) <= 0:
                    self.error(f"{where}: [{game}] '{build}' is no build number")
                    continue
                if not isinstance(info, dict) or not isinstance(info.get("patch"), str) or not info["patch"]:
                    self.error(f"{where}: [{game}] {build} needs its patch ({{ patch = \"1.60.1\" }})")
                    continue
                for word in info:
                    if word not in ("patch", "day"):
                        self.error(f"{where}: [{game}] {build}: '{word}' is not part of a build")
                if "day" in info and not is_day(info["day"]):
                    self.error(f"{where}: [{game}] {build}: day '{info['day']}' is no date (YYYY-MM-DD)")
                self.builds[game][int(build)] = dict(info)
        if LIVE not in self.builds:
            self.error(f"{where}: [{LIVE}] is missing")
        for game in self.builds:
            if base_of(game) not in self.builds:
                self.error(f"{where}: [{game}] stands on [{base_of(game)}], which is missing")

    def _load_sources(self):
        where = self.where(self.root / "sources.toml")
        for name, info in self._toml("sources.toml").items():
            if not isinstance(info, dict):
                self.error(f"{where}: [{name}] describes a source")
                continue
            kind = info.get("kind")
            if kind not in KINDS:
                self.error(f"{where}: [{name}] 'kind' is one of {', '.join(KINDS)}")
                continue
            if name in ("game", "hand") and kind != name:
                self.error(f"{where}: [{name}] is of the kind {name}")
            if not (isinstance(info.get("about"), str) and info["about"].strip()):
                self.error(f"{where}: [{name}] needs 'about', what the source is")
            for word in info:
                if word not in ("kind", "about", "game", "seen", "build"):
                    self.error(f"{where}: [{name}] '{word}' is not part of a source")
            if kind == "batch":
                if not (name.isdigit() or re.match(r"^[a-z][a-z0-9-]*$", name)):
                    self.error(f"{where}: [{name}] a batch is named by a number or a word")
                game, seen, build = info.get("game"), info.get("seen"), info.get("build")
                if game not in self.builds:
                    self.error(f"{where}: [{name}] 'game' names the game version its lines go to, one of builds.toml's")
                if seen is not None and seen not in self.builds:
                    self.error(f"{where}: [{name}] 'seen' names a game version of builds.toml")
                if build is not None and (not schemas._whole(build) or build not in self.builds.get(seen or game, {})):
                    self.error(f"{where}: [{name}] 'build' is a build of {seen or game} in builds.toml")
            elif any(word in info for word in ("game", "seen", "build")):
                self.error(f"{where}: [{name}] only a batch names a game version and build")
            self.sources[name] = info
        for name in ("game", "hand"):
            if name not in self.sources:
                self.error(f"{where}: [{name}] is missing")

    def _load_packs(self):
        where = self.where(self.root / "packs.toml")
        for name, info in self._toml("packs.toml").items():
            if not schemas.NAME.match(name):
                self.error(f"{where}: '{name}' is no pack's name (letters and digits, a capital first)")
                continue
            if not isinstance(info, dict) or not all(isinstance(info.get(word), str) and info[word].strip() for word in ("title", "notes")):
                self.error(f"{where}: [{name}] needs 'title' and 'notes'")
                continue
            for word in info:
                if word not in ("title", "notes", "saved"):
                    self.error(f"{where}: [{name}] '{word}' is not part of a pack")
            if "saved" in info and info["saved"] is not True:
                self.error(f"{where}: [{name}] 'saved' is true or left out")
            self.packs[name] = info

    def _load_schema(self, folder):
        name, path = folder.name, folder / "schema.toml"
        if not path.exists():
            self.error(f"{self.where(folder)}: a set's folder has its schema.toml")
            return False
        schema, problems = schemas.load(path, self.where(path))
        for problem in problems:
            self.error(problem)
        if schema is None or problems:
            return False
        if schema.set != name:
            self.error(f"{self.where(path)}: 'set' is '{schema.set}', the folder '{name}'")
            return False
        self.schemas[name] = schema
        return True

    def _load_lines(self, folder):
        name = folder.name
        schema = self.schemas[name]
        files = {}
        for path in sorted(folder.iterdir()):
            if path.name == "schema.toml":
                continue
            match, fix = LINES.match(path.name), FIXES.match(path.name)
            if fix:
                game = fix.group("game") or LIVE
                if fix.group("game") == LIVE:
                    self.error(f"{self.where(path)}: live's fixes are fixes.jsonl")
                elif game not in self.builds:
                    self.error(f"{self.where(path)}: '{game}' is no game version of builds.toml")
                else:
                    self.fix_files[(name, game)] = path
                continue
            if not match or match.group("set") != name:
                self.error(f"{self.where(path)}: no file of the set {name} ({name}.jsonl, {name}.<game version>.jsonl, fixes.jsonl)")
                continue
            game, start = match.group("game") or LIVE, match.group("start")
            if match.group("game") == LIVE:
                self.error(f"{self.where(path)}: live's lines are in {name}.jsonl")
            elif game not in self.builds:
                self.error(f"{self.where(path)}: '{game}' is no game version of builds.toml")
            elif start is not None and schema.key != "int":
                self.error(f"{self.where(path)}: only a set with whole-number keys is split by key range")
            else:
                files.setdefault(game, []).append((int(start) if start else None, path))
        for game, found in files.items():
            found.sort(key=lambda item: -1 if item[0] is None else item[0])
            self.files[(name, game)] = found
            lines = []
            for number, (start, path) in enumerate(found):
                end = found[number + 1][0] if number + 1 < len(found) else None
                for line in self.read_lines(schema, path, game, tool=True):
                    if (start is not None and line.key < start) or (end is not None and line.key >= end):
                        self.error(f"{line.where}: key {line.key} is outside the file's keys ({start or 0} to {end - 1 if end else 'the end'})")
                    lines.append(line)
            self.lines[(name, game)] = lines
        for (set_name, game), path in self.fix_files.items():
            if set_name == name:
                self.fixes[(name, game)] = self.read_lines(schema, path, game, tool=False)

    def read_lines(self, schema, path, game, tool):
        """The lines of one file, each checked on its own (Doc/guides/data.md, *A line of the master*).
        tool: a file the tools write, whose keys must be in their order."""
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            self.error(f"{self.where(path)}: is not UTF-8")
            return []
        if text and not text.endswith("\n"):
            self.error(f"{self.where(path)}: the last line has no line end")
        lines = []
        for number, raw in enumerate(text.splitlines(), 1):
            line = self.parse_line(schema, raw, game, f"{self.where(path)}:{number}", tool)
            if line is not None:
                lines.append(line)
        return lines

    def parse_line(self, schema, raw, game, where, tool):
        twice = []

        def objects(pairs):  # a dict keeps the document's order; a name given twice is noted
            out = dict(pairs)
            if len(out) != len(pairs):
                twice.append(True)
            return out
        try:
            data = json.loads(raw, object_pairs_hook=objects)
        except json.JSONDecodeError as error:
            self.error(f"{where}: does not parse: {error.msg}")
            return None
        if not isinstance(data, dict):
            self.error(f"{where}: is no object")
            return None
        if twice:
            self.error(f"{where}: names a key twice")
            return None
        names = list(data)
        order = list(schemas.LINE_WORDS) + schema.names
        unknown = [name for name in names if name not in order]
        if unknown:
            self.error(f"{where}: {', '.join(unknown)}: not in the schema of {schema.set}")
            return None
        if tool and names != sorted(names, key=order.index):
            self.error(f"{where}: keys out of order (key, since, day, src, gone, replaces, then the fields in schema order)")
        key = data.get("key")
        problem = "is no whole number" if schema.key == "int" and not schemas._whole(key) else \
            schemas._text_problem(key) if schema.key == "text" else None
        if problem:
            self.error(f"{where}: key {problem}")
            return None
        since = data.get("since")
        if not schemas._whole(since) or since < 0:
            self.error(f"{where}: since is a build number (0: from the start)")
            return None
        if since and since not in self.builds.get(game, {}):
            other = [name for name, builds in self.builds.items() if since in builds and name != game]
            if other:
                self.error(f"{where}: build {since} is {other[0]}'s, not {game}'s: the line is in the wrong file")
            else:
                self.error(f"{where}: build {since} is not in builds.toml for {game}")
        day = data.get("day")
        if "day" in data and not is_day(day):
            self.error(f"{where}: day '{day}' is no date (YYYY-MM-DD)")
        src = data.get("src")
        if not isinstance(src, list) or not src:
            self.error(f"{where}: src is a list of its sources")
            src = []
        for each in src:
            if isinstance(each, bool) or not isinstance(each, (int, str)):
                self.error(f"{where}: src holds a source's name or number, not {each!r}")
                continue
            info = self.sources.get(source_name(each))
            if info is None:
                self.error(f"{where}: source {each!r} is not in sources.toml")
            elif isinstance(each, str) and each.isdigit():
                self.error(f"{where}: source {each} is a number, written without quotes")
            elif info.get("kind") == "batch" and info.get("game") != game:
                self.error(f"{where}: source {each} is {info.get('game')}'s batch: the line is in the wrong file")
        if len(set(map(source_name, src))) != len(src):
            self.error(f"{where}: src names a source twice")
        if "gone" in data and data["gone"] is not True:
            self.error(f"{where}: gone is true or left out")
        gone = data.get("gone") is True
        replaces = data.get("replaces")
        if "replaces" in data and type(replaces) is not schema.key_type():
            self.error(f"{where}: replaces is a key of {schema.set}")
            replaces = None
        fields = {name: data[name] for name in schema.names if name in data}
        if gone and (fields or replaces is not None):
            self.error(f"{where}: a gone version holds nothing else")
        refs = set()
        for name, value in fields.items():
            if value is not None:
                problem = schemas.value_problem(schema.byname[name], value, self._key_types, refs)
                if problem:
                    self.error(f"{where}: {name} {problem}")
        for target_set, target_key in refs:
            self.refs.append((where, game, target_set, target_key))
        if replaces is not None:
            self.refs.append((where, game, schema.set, replaces))
        return Line(key, since, day, src, gone, replaces, fields, where)

    # Versions -----------------------------------------------------------------------------------------

    def fixed(self, set_name, game):
        """The lines of a game version with its fixes laid on (each fix's fields over its version's line)."""
        fixes = {fix.order(): fix for fix in self.fixes.get((set_name, game), [])}
        out = []
        for line in self.lines.get((set_name, game), []):
            fix = fixes.get(line.order())
            if fix:
                line = Line(line.key, line.since, line.day, line.src + [s for s in fix.src if s not in line.src],
                            line.gone, line.replaces, {**line.fields, **fix.fields}, line.where)
            out.append(line)
        return out

    def view(self, set_name, game, fixes=True):
        """{key: [Version, ...]}: every entry of a set as the game version sees it, oldest version first.
        Another game version stands on live's newest version of each entry (since 0)."""
        out = {}
        if base_of(game) != game:
            for key, versions in self.view(set_name, base_of(game), fixes).items():
                if not versions[-1].gone:
                    out[key] = [Version(0, None, False, dict(versions[-1].fields), None)]
        own = self.fixed(set_name, game) if fixes else self.lines.get((set_name, game), [])
        for line in sorted(own, key=Line.order):
            apply(out.setdefault(line.key, []), line)
        return out


def apply(versions, line):
    """Adds a line to an entry's versions, worked out whole. A line at the same build and day as the version
    before it (another game version's line at since 0 over live's base) makes one version of both."""
    if line.gone:
        version = Version(line.since, line.day, True, {}, line)
    else:
        last = versions[-1] if versions else None
        fields = {} if last is None or last.gone else dict(last.fields)
        for name, value in line.fields.items():
            if value is None:
                fields.pop(name, None)
            else:
                fields[name] = value
        version = Version(line.since, line.day, False, fields, line)
    if versions and versions[-1].clock() == version.clock():
        versions[-1] = version
    else:
        versions.append(version)


def current(versions, since, day=None):
    """The version current at a build and day: the newest one that starts at or before it. Without a day,
    any day of that build: the build's newest version."""
    found = None
    for version in versions:
        if (version.clock() <= (since, day) if day else version.since <= since):
            found = version
    return found


def line_text(schema, line):
    """A line as the tools write it."""
    data = {"key": line.key, "since": line.since}
    if line.day:
        data["day"] = line.day
    data["src"] = line.src
    if line.gone:
        data["gone"] = True
    if line.replaces is not None:
        data["replaces"] = line.replaces
    for field in schema.fields:
        if field.name in line.fields:
            data[field.name] = schemas.canonical(field, line.fields[field.name])
    return json.dumps(data, ensure_ascii=False, separators=(",", ":"))


def write(master, set_name, game, lines):
    """Writes a game version's lines of a set into its files, sorted: into the files it has (split by key
    range), else into one new file."""
    schema = master.schemas[set_name]
    files = master.files.get((set_name, game))
    if not files:
        name = f"{set_name}.jsonl" if game == LIVE else f"{set_name}.{game}.jsonl"
        files = [(None, master.root / set_name / name)]
        master.files[(set_name, game)] = files
    ordered = sorted(lines, key=Line.order)
    for number, (start, path) in enumerate(files):
        end = files[number + 1][0] if number + 1 < len(files) else None
        mine = [line for line in ordered if (start is None or line.key >= start) and (end is None or line.key < end)]
        path.write_text("".join(line_text(schema, line) + "\n" for line in mine), encoding="utf-8")
    master.lines[(set_name, game)] = ordered
