"""One export of Blizzard's interface code (as the game's exportInterfaceFiles code writes it), read as this client
loads it: what it gives every addon, as symbols with an id, a signature and a hash. SaneUI is built on the newest
export (newest(): Forever's highest build of the exports' folder this computer's settings name), never on references/.

  lua:<chain>        what the Lua files define at their top level: Name, A.B (functions, tables, values), A:B
  xml:<name>         named XML objects: templates (virtual), frames, fonts
  frame:<name>       frames and fonts the Lua makes with a global name (CreateFrame("Frame", "Name"))
  api:<chain>        the client's functions (C_Spell.GetSpellInfo, UnitName), from Blizzard_APIDocumentationGenerated
  widget:<object>:<method>  methods of the widgets (SimpleFrameAPI:SetPoint), from the same
  event:<NAME>       events, with their payload
  enum:Enum.<name>[.<value>], const:Constants.<name>.<value>, struct:<name>  the documentation's tables
  addon:<name>       Blizzard's addons: whether this client loads them, on demand or not, their dependencies
  cvar:<name>        CVars the code names (lower case)

A signature (sig) is what a caller depends on (parameters, arguments and returns with the API's flags, a
template's parents, mixins and keys, a payload, an enum's values); the hash covers the whole definition, so a
symbol whose hash changed and whose signature did not is the same to call but works differently inside.
Only the files its client loads count (Forever's TOCs read for game type camelot, which also counts the group
mainline, [Family] as Mainline and [Game] as Camelot; Retail's for standard and mainline, [Game] as Standard); the
documentation counts whole.
"""
import hashlib
import json
import re
import subprocess
import tarfile
import tempfile
import xml.parsers.expat
from pathlib import Path

import lua

# How each game's client reads the TOCs: the load groups it is in, what [Family] and [Game] stand for, and the
# suffixes of the TOC it takes first. Forever is Retail's code (the family Mainline) with a layer of its own.
CLIENTS = {
    "forever": {"types": {"camelot", "mainline"}, "family": "Mainline", "game": "Camelot",
                "suffixes": ("_Camelot", "_Mainline", "")},
    "retail": {"types": {"standard", "mainline"}, "family": "Mainline", "game": "Standard",
               "suffixes": ("_Standard", "_Mainline", "")},
}
GAME_TYPES = CLIENTS["forever"]["types"]
DOCS = "Blizzard_APIDocumentationGenerated"
DEPRECATED = "Blizzard_Deprecated"  # addons whose names start so keep old names alive a while
CONDITION = re.compile(r"\[\s*([A-Za-z]+)\s*:?\s*([^\]]*)\]")
DEPENDENCIES = ("Dependencies", "Dep", "RequiredDep", "RequiredDeps")
PATH = re.compile(r"interface[\\/]", re.I)


def digest(value):
    return hashlib.sha1(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:16]


def path_name(text):
    """A texture's or file's path as a name: interface/buttons/ui-panel-button-up (no extension)."""
    return "path:" + re.sub(r"\.(blp|tga|png|jpg|m2|ogg|mp3|ttf|xml|lua)$", "", text.replace("\\", "/").lower())


def names_of(value):
    """The words of a string worth comparing as names: an identifier, an atlas, a path."""
    if PATH.match(value):
        return [path_name(value)]
    return [value] if len(value) <= 80 and lua.NAMEISH.match(value) else []


# Where this computer keeps the exports: ~/.config/saneui/blizzard.json {"exports": "<folder>"}, or $BLIZZARD_EXPORTS.
# The folder holds one <product>-<version> folder a build, with interface/BlizzardInterfaceCode and
# interface/BlizzardInterfaceArt in it, the export of that build's code and art.
CONFIG = Path.home() / ".config" / "saneui" / "blizzard.json"
# The games, by their clients' products (.build.info): Forever is the one the tools build on unless told otherwise;
# Retail's version numbers (12.x) are higher than Forever's and must never count as Forever's newest.
GAMES = {"forever": ("wowf", "wow_classic_beta"), "retail": ("wow", "wowt", "wow_beta")}


def setting(key):
    """One of this computer's settings for Blizzard's exports (CONFIG): exports (their folder), install (the game's
    World of Warcraft folder), extract (the command that exports a product's build: `<command> <product>`),
    reports (where a patch's notes and the Forever-Retail lookup go); None when not set."""
    if CONFIG.is_file():
        value = json.loads(CONFIG.read_text(encoding="utf-8")).get(key)
        return str(Path(value).expanduser()) if value else None
    return None


def exports_folder():
    import os
    folder = os.environ.get("BLIZZARD_EXPORTS") or setting("exports")
    return Path(folder).expanduser() if folder else None


def version_key(version):
    return tuple(int(part) if part.isdigit() else 0 for part in version.split("."))


def all_exports(game="forever"):
    """Every export of one game in the exports' folder that has its code, newest last: (version, product, interface
    folder)."""
    folder = exports_folder()
    found = []
    if folder and folder.is_dir():
        for build in folder.iterdir():
            product, _, version = build.name.rpartition("-")
            interface = build / "interface"
            if product in GAMES[game] and version and \
                    (interface / "BlizzardInterfaceCode" / "Interface" / "AddOns").is_dir():
                found.append((version, product, interface))
    return sorted(found, key=lambda e: version_key(e[0]))


def newest(kind="code", game="forever"):
    """The newest export's code (BlizzardInterfaceCode) or art (BlizzardInterfaceArt) folder, the game's one with the
    highest version number; None where this computer has none (its settings name no exports' folder, or it is empty)."""
    found = all_exports(game)
    if not found:
        return None
    return found[-1][2] / ("BlizzardInterfaceCode" if kind == "code" else "BlizzardInterfaceArt")


def required(kind="code", game="forever"):
    """newest(kind, game), or the reason there is none, and an exit."""
    folder = newest(kind, game)
    if folder is None or not folder.is_dir():
        raise SystemExit(f"No export of Blizzard's interface {kind}: name the exports' folder in {CONFIG} "
                         '({"exports": "<folder>"}) or $BLIZZARD_EXPORTS (Doc/guides/blizzard-updates.md).')
    return folder


def locate(path):
    """The folder an export's Interface folder is in: given that folder, its Interface folder, or a game folder
    the game exported into (<game>/BlizzardInterfaceCode)."""
    path = Path(path).expanduser()
    for root in (path, path.parent, path / "BlizzardInterfaceCode"):
        if (root / "Interface" / "AddOns").is_dir():
            return root
    return None


def from_git(revision, root, into):
    """references/BlizzardInterfaceCode as the commit revision holds it (the in-game export SaneUI was first built
    on), unpacked into the folder into: only to compare with."""
    archive = subprocess.run(["git", "-C", str(root), "archive", revision, "references/BlizzardInterfaceCode"],
                             capture_output=True, check=True).stdout
    with tempfile.TemporaryFile() as file:
        file.write(archive)
        file.seek(0)
        with tarfile.open(fileobj=file) as tar:
            tar.extractall(into, filter="data")
    return Path(into) / "references" / "BlizzardInterfaceCode"


def product_of(root):
    """The product an export is of (wowf, wow): its note (.build), or the game folder's .flavor.info."""
    note = root / ".build"
    if note.is_file():
        return json.loads(note.read_text(encoding="utf-8")).get("product")
    flavor = root.parent / ".flavor.info"
    return flavor.read_text(encoding="utf-8").split()[-1] if flavor.is_file() else None


def game_of(root):
    """The game an export is of: Retail by its product, else Forever."""
    return "retail" if product_of(root) in GAMES["retail"] else "forever"


def build_of(root):
    """The game's build an export is of, where it can be known: its note (.build), or the game
    folder it was exported into (.flavor.info names the product, .build.info one folder up its version)."""
    note = root / ".build"
    if note.is_file():
        return json.loads(note.read_text(encoding="utf-8")).get("version")
    game = root.parent
    flavor = game / ".flavor.info"
    info = game.parent / ".build.info"
    if not (flavor.is_file() and info.is_file()):
        return None
    product = product_of(root)
    rows = [line.split("|") for line in info.read_text(encoding="utf-8").splitlines()]
    head = [field.split("!")[0] for field in rows[0]] if rows else []
    for row in rows[1:]:
        fields = dict(zip(head, row))
        if fields.get("Product") == product:
            return fields.get("Version") or None
    return None


def interface_of(version):
    """The TOC's Interface number of a game version: 1.60.1.70450 is 16001."""
    parts = (version or "").split(".")
    if len(parts) < 3 or not all(part.isdigit() for part in parts[:3]):
        return None
    return int(parts[0]) * 10000 + int(parts[1]) * 100 + int(parts[2])


def allowed(conditions, types=GAME_TYPES):
    """Whether a TOC line or field with these [conditions] counts for the client of these load groups, in the game
    (not the login screen) and in English."""
    for key, argument in CONDITION.findall(conditions):
        words = {word for word in re.split(r"[\s,]+", argument.strip().lower()) if word}
        if key == "AllowLoadGameType" and not words & types:
            return False
        if key == "ExcludeLoadGameType" and words & types:
            return False
        if key == "AllowLoad" and words and not words & {"game", "both"}:
            return False
        if key == "AllowLoadTextLocale" and words and "enus" not in words:
            return False
    return True


class Node:
    __slots__ = ("tag", "attrs", "line", "end", "children", "text")

    def __init__(self, tag, attrs, line):
        self.tag, self.attrs, self.line, self.end, self.children, self.text = tag, attrs, line, line, [], []


def parse_xml(data):
    """An XML file as a tree of Nodes with their lines; None when it does not parse."""
    root = Node("", {}, 0)
    stack = [root]
    parser = xml.parsers.expat.ParserCreate()

    def start(tag, attrs):
        node = Node(tag.rpartition(":")[2], attrs, parser.CurrentLineNumber)
        stack[-1].children.append(node)
        stack.append(node)

    def end(_):
        stack[-1].end = parser.CurrentLineNumber
        stack.pop()

    parser.StartElementHandler, parser.EndElementHandler = start, end
    parser.CharacterDataHandler = lambda data: stack[-1].text.append(data)
    try:
        parser.Parse(data, True)
    except xml.parsers.expat.ExpatError:
        return None
    return root


def canonical(node):
    """A node and all below it as plain data, the same however the file is laid out."""
    text = " ".join(" ".join(node.text).split())
    return [node.tag, sorted(node.attrs.items()), text, [canonical(child) for child in node.children]]


def xml_signature(node):
    """What a template, frame or font gives those who use it: tag, parents, mixins, size, keys, scripts."""
    keys, scripts, values = [], [], {}

    def walk(item, path):
        for child in item.children:
            if item.tag == "Scripts":  # a handler: its Lua is in the hash, its name and function here
                scripts.append(child.tag + "".join(f" {k}={v}" for k, v in sorted(child.attrs.items())))
                continue
            key = child.attrs.get("parentKey") or child.attrs.get("parentArray")
            here = f"{path}.{key}" if key and path else (key or path)
            if key:
                keys.append(f"{here} ({child.tag})")
            if child.tag == "KeyValue" and "key" in child.attrs:
                values[child.attrs["key"]] = child.attrs.get("value")
            walk(child, here)

    walk(node, "")
    size = next((child.attrs for child in node.children if child.tag == "Size"), {})
    sig = {"tag": node.tag, "inherits": node.attrs.get("inherits", ""), "mixin": node.attrs.get("mixin", ""),
           "secureMixin": node.attrs.get("secureMixin", ""), "virtual": node.attrs.get("virtual") == "true",
           "intrinsic": node.attrs.get("intrinsic") == "true", "size": dict(sorted(size.items())),
           "keys": sorted(set(keys)), "scripts": sorted(scripts), "values": values}
    return {key: value for key, value in sig.items() if value not in ("", {}, [], False)}


class Export:
    """An export read whole: its symbols, the names it mentions anywhere, its addons and files."""

    def __init__(self, root, label=None, build=None, game=None, addons=None):
        """addons: the names of the addon folders to read, for a tool that wants a few of them (their loaded files
        and symbols; no file hashes, no documentation): a whole export takes seconds, two addons a moment."""
        self.root = Path(root)
        self.only = set(addons) if addons else None
        self.interface = self.root / "Interface"
        self.build = build or build_of(self.root)
        self.game = game or game_of(self.root)
        self.client = CLIENTS[self.game]
        game = self.root.parent.name if self.root.name == "BlizzardInterfaceCode" else self.root.name
        self.label = label or self.build or game
        self.symbols = {}  # id -> record
        self.names = set()  # every name and name-like string the loaded code and the documentation hold
        self.files = {}  # path under Interface -> hash, every file
        self.loaded = []  # paths of the files this client loads, in order
        self.warnings = []
        self._defs = {}  # id -> [definitions in load order]
        self._read()

    # -- reading -------------------------------------------------------------------------------------

    def rel(self, path):
        return path.relative_to(self.interface).as_posix()

    def _read(self):
        if self.only is None:
            for path in sorted(self.interface.rglob("*")):
                if path.is_file():
                    # The same text with other line ends is the same file (the game writes CRLF).
                    self.files[self.rel(path)] = hashlib.sha1(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()[:16]
        addons = self.interface / "AddOns"
        for folder in sorted(p for p in addons.iterdir() if p.is_dir()):
            if self.only is not None and folder.name not in self.only:
                continue
            if folder.name == DOCS:
                self._documentation(folder)
                continue
            record = self._addon(folder)
            if record is None:
                continue
            files = record.pop("files")
            self._add(f"addon:{folder.name}", "addon", record.pop("toc"), 1, record)
            if record["loads"]:
                for path in files:
                    self._file(path)
        for id_, defs in self._defs.items():
            self._settle(id_, defs)
        del self._defs

    def _toc(self, folder):
        tocs = {p.stem.lower(): p for p in folder.glob("*.toc")}  # without regard to capitals, as the game
        for suffix in self.client["suffixes"]:
            if (folder.name + suffix).lower() in tocs:
                return tocs[(folder.name + suffix).lower()]
        return next(iter(tocs.values())) if len(tocs) == 1 else None

    def _addon(self, folder):
        """An addon's TOC as this client reads it: whether it loads, on demand or not, its dependencies, and the
        files it loads in their order (XML files with what they include)."""
        toc = self._toc(folder)
        if toc is None:
            return None
        fields, lines = {}, []
        for raw in toc.read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw.strip()
            field = re.match(r"##\s*([A-Za-z]+)\s*:\s*(.*)$", line)
            if field:
                value, _, conditions = field.group(2).partition("[")
                if allowed("[" + conditions if conditions else "", self.client["types"]):
                    fields.setdefault(field.group(1), []).append(value.strip())
                continue
            if line and not line.startswith("#"):
                path, *rest = line.split(None, 1)
                if allowed(rest[0] if rest else "", self.client["types"]):
                    lines.append(path.replace("[Family]", self.client["family"]).replace("[Game]", self.client["game"])
                                 .replace("\\", "/"))

        def words(name):
            return {w for value in fields.get(name, []) for w in re.split(r"[\s,]+", value.lower()) if w}

        types = self.client["types"]
        loads = True
        if "AllowLoadGameType" in fields and not words("AllowLoadGameType") & types:
            loads = False
        if words("ExcludeLoadGameType") & types:
            loads = False
        if "AllowLoad" in fields and not words("AllowLoad") & {"game", "both"}:
            loads = False
        deps = sorted({w for name in DEPENDENCIES for value in fields.get(name, [])
                       for w in re.split(r"[\s,]+", value) if w})
        files, seen = [], set()
        for line in lines:
            self._collect(folder, folder / line, files, seen)
        return {"toc": self.rel(toc), "loads": loads, "lod": fields.get("LoadOnDemand", ["0"])[-1] == "1",
                "deps": deps, "files": files}

    def _find(self, path):
        """A file by its path, without regard to capitals (the game runs on Windows)."""
        if path.exists():
            return path
        parent = path.parent if path.parent.exists() else self._find(path.parent) if path.parent != path else None
        if parent is None or not parent.is_dir():
            return None
        lower = path.name.lower()
        return next((p for p in parent.iterdir() if p.name.lower() == lower), None)

    def _collect(self, folder, path, files, seen):
        found = self._find(path)
        if found is None or found in seen:
            return
        seen.add(found)
        if found.suffix.lower() == ".xml":
            for include in re.findall(rb'<(?:Script|Include)\s[^>]*file\s*=\s*"([^"]+)"', found.read_bytes()):
                name = include.decode("utf-8", "replace").replace("\\", "/")
                inner = found.parent / name
                self._collect(folder, inner if self._find(inner) else folder / name, files, seen)
        files.append(found)

    def _add(self, id_, kind, file, line, sig, end=None, hash_=None, what=None):
        self._defs.setdefault(id_, []).append({
            "kind": kind, "what": what or kind, "file": file, "line": line, "end": end or line, "sig": sig,
            "hash": hash_ or digest(sig)})

    def _settle(self, id_, defs):
        """The definition that counts (the last loaded one outside the deprecated addons, if any)."""
        alive = [d for d in defs if not d["file"].startswith(f"AddOns/{DEPRECATED}")]
        record = dict((alive or defs)[-1])
        record["deprecated"] = not alive
        if len(defs) > 1:
            record["files"] = sorted({d["file"] for d in defs})
        self.symbols[id_] = record

    def _file(self, path):
        rel = self.rel(path)
        self.loaded.append(rel)
        data = path.read_bytes()
        if path.suffix.lower() == ".lua":
            self._lua(rel, data.decode("utf-8", "replace"))
        elif path.suffix.lower() == ".xml":
            self._xml(rel, data)

    def _lua(self, rel, text):
        source = lua.Source(text)
        names = self.names
        for kind, value, _ in source.toks:
            if kind == "name":
                names.add(value)
            elif kind == "string":
                names.update(names_of(value))
        for item in lua.definitions(source):
            first, last = item["first"], item["last"]
            if item["what"] == "frame":
                self._add(f"frame:{item['chain']}", "frame", rel, source.line(first), {})
                continue
            sig = {"what": item["what"]}
            if "params" in item:
                sig["params"] = item["params"]
            body = digest(source.values(first, last)) if item["what"] != "table" or last - first < 2000 else None
            self._add(f"lua:{item['chain']}", "lua", rel, source.line(first), sig, source.line(last),
                      body, item["what"])
        for name in lua.calls_with(source, "CVar"):
            if lua.NAMEISH.match(name) and "." not in name:
                self._add(f"cvar:{name.lower()}", "cvar", rel, 1, {})

    def _xml(self, rel, data):
        root = parse_xml(data)
        if root is None:
            self.warnings.append(f"{rel}: not well-formed XML, read for its names only")
            for value in re.findall(rb'="([^"]*)"', data):
                for word in re.split(r"[\s,]+", value.decode("utf-8", "replace")):
                    self.names.update(names_of(word))
            return
        self._xml_walk(rel, root, None, False)

    def _xml_walk(self, rel, node, parent_name, in_template):
        for child in node.children:
            attrs = child.attrs
            for key, value in attrs.items():
                for word in re.split(r"[\s,]+", value):
                    self.names.update(names_of(word))
            if child.text:
                text = "".join(child.text).strip()
                if text:
                    self.names.update(t[1] for t in lua.Source(text).toks if t[0] == "name")
            name = attrs.get("name")
            template = in_template or attrs.get("virtual") == "true" or attrs.get("intrinsic") == "true"
            own = None
            if name:
                if "$parent" in name or "$Parent" in name:
                    name = None if in_template or not parent_name else re.sub(r"\$[pP]arent", parent_name, name)
                if name and (not in_template):
                    own = name
                    self._add(f"xml:{name}", "xml", rel, child.line, xml_signature(child), child.end,
                              digest(canonical(child)), "font" if child.tag in ("Font", "FontFamily") else
                              "template" if template else "frame")
            self._xml_walk(rel, child, own or parent_name, template)

    def _documentation(self, folder):
        for path in sorted(folder.glob("*.lua")):
            rel = self.rel(path)
            for table in lua.documentation(lua.Source(path.read_text(encoding="utf-8", errors="replace"))):
                self._system(rel, table)

    def _system(self, rel, table):
        space, kind = table.get("Namespace"), table.get("Type")
        system = table.get("Name", "")
        for item in table.get("Functions", []) or []:
            if not isinstance(item, dict) or "Name" not in item:
                continue
            name = item["Name"]
            id_ = f"widget:{system}:{name}" if kind == "ScriptObject" else f"api:{space}.{name}" if space else f"api:{name}"
            self.names.add(name)
            self._add(id_, "widget" if kind == "ScriptObject" else "api", rel, None, {
                "args": [plain(arg) for arg in item.get("Arguments") or []],
                "returns": [plain(ret) for ret in item.get("Returns") or []], "flags": flags(item)})
        if space:
            self.names.add(space)
        for item in table.get("Events", []) or []:
            if isinstance(item, dict) and item.get("LiteralName"):
                self.names.add(item["LiteralName"])
                self._add(f"event:{item['LiteralName']}", "event", rel, None, {
                    "payload": [plain(arg) for arg in item.get("Payload") or []], "flags": flags(item)})
        for item in table.get("Tables", []) or []:
            if not isinstance(item, dict) or "Name" not in item:
                continue
            name, type_ = item["Name"], item.get("Type")
            self.names.add(name)
            fields = [f for f in item.get("Fields") or item.get("Values") or [] if isinstance(f, dict)]
            if type_ == "Enumeration":
                values = {f.get("Name"): f.get("EnumValue") for f in fields}
                self._add(f"enum:Enum.{name}", "enum", rel, None, {"values": values})
                for key, value in values.items():
                    self.names.add(key)
                    self._add(f"enum:Enum.{name}.{key}", "enum", rel, None, {"value": value})
            elif type_ == "Structure":
                self._add(f"struct:{name}", "struct", rel, None, {"fields": [plain(f) for f in fields]})
                self.names.update(f.get("Name") for f in fields if f.get("Name"))
            elif type_ == "Constants":
                for f in fields:
                    self.names.add(f.get("Name"))
                    self._add(f"const:Constants.{name}.{f.get('Name')}", "const", rel, None, {
                        "value": f.get("Value"), "type": f.get("Type")})

    # -- asking ----------------------------------------------------------------------------------------

    def lines(self, file, first, last):
        """Lines first to last of a file of the export (empty when it is not there)."""
        path = self.interface / file
        if not path.is_file() or first is None:
            return []
        return path.read_text(encoding="utf-8", errors="replace").splitlines()[first - 1:last]


def plain(item):
    """A documented argument, return, payload or field without its words for people."""
    return {key: value for key, value in item.items() if key != "Documentation"} if isinstance(item, dict) else item


def flags(item):
    """What the documentation says of a function or event besides its name, arguments and returns: whether it
    is protected, its secret values, its restrictions."""
    return {key: value for key, value in item.items()
            if key not in ("Name", "Type", "Arguments", "Returns", "Payload", "Documentation", "LiteralName")}
