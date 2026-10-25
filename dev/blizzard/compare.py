"""Two exports side by side, and what of their difference reaches Sane UI: the findings of the todo list.

  broken      Sane UI uses what the new export no longer has (a symbol gone, or a name its code no longer
              mentions anywhere: a parentKey, a menu's tag, a callback)
  deprecated  what Sane UI uses lives on only in Blizzard's deprecated addons, which go away later
  changed     what Sane UI uses is called differently now: parameters, arguments, returns, the API's flags
              (protected, secret values, restrictions), a payload, a template's parents or keys, an enum
  review      Sane UI hooks it or builds on it and its code changed; or an atlas or file Blizzard's code no
              longer names (it may still be in the game)
  housekeeping  the TOCs' Interface number, files made from Blizzard's code, notes citing changed files
"""
import difflib
import re
from collections import defaultdict

from export import interface_of

SECTIONS = ("broken", "deprecated", "changed", "review", "housekeeping")
KIND = {"lua": "Lua", "api": "API", "widget": "widget method", "event": "event", "enum": "enum", "const": "constant",
        "struct": "structure", "addon": "Blizzard addon", "cvar": "CVar", "frame": "frame", "name": "name"}
FIELD_KEYS = ("Type", "Nilable", "Default", "InnerType", "Mixin", "StrideIndex", "EnumValue")
DIFF_LINES = 80  # at most this many lines of a diff in the report


class Change:
    __slots__ = ("status", "old", "new", "notes")

    def __init__(self, status, old, new, notes=()):
        self.status, self.old, self.new, self.notes = status, old, new, list(notes)


class Finding:
    def __init__(self, section, id_, notes, uses=(), hints=(), diff=None, label=None):
        self.section, self.id, self.notes = section, id_, list(notes)
        self.uses, self.hints, self.diff = list(uses), list(hints), diff
        self.label = label

    def title(self):
        if self.label:
            return self.label
        kind, _, name = self.id.partition(":")
        return f"`{name}` ({KIND.get(kind, kind)})"

    def as_dict(self):
        return {"section": self.section, "id": self.id, "title": self.title(), "notes": self.notes,
                "uses": [use.where() + (f" ({use.how})" if use.how else "") for use in self.uses],
                "hints": self.hints, "diff": self.diff}


def tail(id_):
    return re.split(r"[.:]", id_.partition(":")[2])[-1]


def label_of(record):
    """What a symbol is, in a word or two: Lua function, template, API function, event."""
    if record is None:
        return "?"
    kind, what = record["kind"], record["what"]
    if kind == "lua":
        return f"Lua {what}"
    if kind == "xml":
        return what
    if kind == "api":
        return "API function"
    return KIND.get(kind, kind)


# -- what changed between the exports ----------------------------------------------------------------------

def fields_changed(old, new, what):
    """Lines for people on a list of documented fields (arguments, returns, payload, a structure's fields)."""
    notes = []
    names_old = [f.get("Name") for f in old]
    names_new = [f.get("Name") for f in new]
    by_old = {f.get("Name"): f for f in old}
    by_new = {f.get("Name"): f for f in new}
    gone = [n for n in names_old if n not in by_new]
    added = [n for n in names_new if n not in by_old]
    if gone:
        notes.append(f"{what} gone: " + ", ".join(f"`{n}`" for n in gone))
    if added:
        notes.append(f"{what} new: " + ", ".join(f"`{n}` {by_new[n].get('Type', '')}".rstrip() for n in added))
    for name in names_old:
        if name in by_new:
            a, b = by_old[name], by_new[name]
            for key in FIELD_KEYS:
                if a.get(key) != b.get(key):
                    notes.append(f"{what} `{name}`: {key} {a.get(key)!r} → {b.get(key)!r}")
    kept_old = [n for n in names_old if n in by_new]
    kept_new = [n for n in names_new if n in by_old]
    if kept_old != kept_new:
        notes.append(f"{what} in a new order: " + ", ".join(kept_new))
    return notes


def dict_changed(old, new, what):
    notes = []
    for key in sorted(set(old) | set(new), key=str):
        if old.get(key) != new.get(key):
            notes.append(f"{what} {key}".strip() + f": {shown(old.get(key))} → {shown(new.get(key))}")
    return notes


def shown(value):
    if value is None:
        return "(none)"
    if isinstance(value, (list, tuple)):
        return "(" + ", ".join(map(str, value)) + ")"
    return str(value)


def describe(a, b):
    """What changed between two records of one symbol, in words."""
    sa, sb, kind = a["sig"], b["sig"], b["kind"]
    notes = []
    if kind == "lua":
        if sa.get("what") != sb.get("what"):
            notes.append(f"was a {sa.get('what')}, now a {sb.get('what')}")
        if sa.get("params") != sb.get("params"):
            notes.append(f"parameters {shown(sa.get('params'))} → {shown(sb.get('params'))}")
    elif kind in ("api", "widget"):
        notes += fields_changed(sa.get("args", []), sb.get("args", []), "argument")
        notes += fields_changed(sa.get("returns", []), sb.get("returns", []), "return")
        notes += dict_changed(sa.get("flags", {}), sb.get("flags", {}), "flag")
    elif kind == "event":
        notes += fields_changed(sa.get("payload", []), sb.get("payload", []), "payload")
        notes += dict_changed(sa.get("flags", {}), sb.get("flags", {}), "flag")
    elif kind == "struct":
        notes += fields_changed(sa.get("fields", []), sb.get("fields", []), "field")
    elif kind == "enum" and "values" in sa:
        va, vb = sa["values"], sb.get("values", {})
        gone = [k for k in va if k not in vb]
        moved = [f"{k} {va[k]} → {vb[k]}" for k in va if k in vb and va[k] != vb[k]]
        added = [k for k in vb if k not in va]
        if gone:
            notes.append("values gone: " + ", ".join(gone))
        if moved:
            notes.append("values renumbered: " + ", ".join(moved))
        if added:
            notes.append("values new: " + ", ".join(added))
    elif kind == "xml":
        for key in ("tag", "inherits", "mixin", "secureMixin", "virtual", "intrinsic", "size"):
            if sa.get(key) != sb.get(key):
                notes.append(f"{key} {shown(sa.get(key))} → {shown(sb.get(key))}")
        ka, kb = set(sa.get("keys", [])), set(sb.get("keys", []))
        if ka - kb:
            notes.append("keys gone: " + ", ".join(sorted(ka - kb)))
        if kb - ka:
            notes.append("keys new: " + ", ".join(sorted(kb - ka)))
        if sa.get("scripts") != sb.get("scripts"):
            notes.append(f"scripts {shown(sa.get('scripts'))} → {shown(sb.get('scripts'))}")
        notes += dict_changed(sa.get("values", {}), sb.get("values", {}), "key value")
    elif kind == "addon":
        notes += dict_changed(sa, sb, "")
    else:
        notes += dict_changed(sa, sb, "")
    if not notes and a["hash"] != b["hash"]:
        notes.append("its code changed")
    if a["file"] != b["file"]:
        notes.append(f"now in {b['file']}")
    return [note.replace("  ", " ") for note in notes]


def changes(old, new):
    """[id] = Change for every symbol the exports do not have alike."""
    found = {}
    for id_ in old.symbols.keys() | new.symbols.keys():
        a, b = old.symbols.get(id_), new.symbols.get(id_)
        if a is None:
            found[id_] = Change("added", None, b)
        elif b is None:
            found[id_] = Change("removed", a, None)
        elif b["deprecated"] and not a["deprecated"]:
            found[id_] = Change("deprecated", a, b, describe(a, b))
        elif a["sig"] != b["sig"]:
            found[id_] = Change("changed", a, b, describe(a, b))
        elif a["hash"] != b["hash"]:
            found[id_] = Change("body", a, b, describe(a, b))
    return found


# -- what Sane UI meets of it ------------------------------------------------------------------------------

class Analysis:
    def __init__(self, old, new, uses, tocs=(), generated=None):
        """old and new are Exports, uses Sane UI's Uses; tocs the paths of Sane UI's TOCs; generated a function
        that gives (tool, made file) pairs out of date against the new export, or None to skip that."""
        self.old, self.new, self.uses = old, new, uses
        self.changes = changes(old, new)
        self.findings = {}  # (section, key) -> Finding
        self.resolved = defaultdict(list)  # [id] = the uses of each symbol Sane UI takes by its name
        self._reported = set()  # (use id, name) pairs a finding already covers
        self._tails = defaultdict(list)
        for id_ in new.symbols:
            self._tails[tail(id_)].append(id_)
        self._methods_old = self._methods(old)
        self._methods_new = self._methods(new)
        self._globals()
        self._strings()
        self._hooks()
        self._methods_called()
        self._vanished()
        self._housekeeping(tocs, generated)

    # -- helpers --

    @staticmethod
    def _methods(export):
        """[method name] = ids of every Lua method (A:Name) and widget method of an export."""
        found = defaultdict(list)
        for id_ in export.symbols:
            if id_.startswith("widget:") or (id_.startswith("lua:") and ":" in id_[4:]):
                found[id_.rpartition(":")[2]].append(id_)
        return found

    def add(self, section, key, notes, uses=(), hints=(), diff=None, label=None):
        finding = self.findings.get((section, key))
        if label is None and ":" in key:
            record = self.new.symbols.get(key) or self.old.symbols.get(key)
            if record:
                label = f"`{key.partition(':')[2]}` ({label_of(record)})"
        if finding is None:
            finding = self.findings[(section, key)] = Finding(section, key, notes, uses, hints, diff, label)
        else:  # met again (hooked after being called): what the second time adds is kept too
            known = {(u.file, u.line) for u in finding.uses}
            finding.uses += [u for u in uses if (u.file, u.line) not in known]
            finding.notes = [n for n in notes if n not in finding.notes] + finding.notes
            finding.diff = finding.diff or diff
        for use in uses:
            self._reported.add((id(use), tail(key) if ":" in key else key))
        return finding

    def exists(self, id_):
        return id_ in self.old.symbols or id_ in self.new.symbols

    def hints(self, id_):
        """Where a symbol that is gone may have gone: the same name elsewhere, a close name new in the export,
        and what a deprecated stand-in calls."""
        name, kind = tail(id_), id_.partition(":")[0]
        found = [i for i in self._tails.get(name, []) if i != id_ and i not in self.old.symbols]
        found += [i for i in self._tails.get(name, []) if i != id_ and i not in found]
        added = {tail(i): i for i, c in self.changes.items()
                 if c.status == "added" and (kind == "name" or i.startswith(kind + ":"))}
        for close in difflib.get_close_matches(name, list(added), n=3, cutoff=0.8):
            if added[close] not in found:
                found.append(added[close])
        return [f"`{i.partition(':')[2]}` ({KIND.get(i.partition(':')[0], i.partition(':')[0])})" for i in found[:4]]

    def calls_in(self, id_, record):
        """What a deprecated stand-in calls or stands for that the new export has: its replacement, as a rule."""
        text = "\n".join(self.new.lines(record["file"], record["line"], record["end"]))
        own, found = id_.partition(":")[2], []
        for name in re.findall(r"\b([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?)\s*\(|=\s*([A-Za-z_]\w*\.[A-Za-z_]\w*)", text):
            name = name[0] or name[1]
            for other in (f"api:{name}", f"lua:{name}"):
                if name != own and other in self.new.symbols and not self.new.symbols[other]["deprecated"] \
                        and f"`{name}`" not in found:
                    found.append(f"`{name}`")
        return found[:3]

    def diff(self, change):
        a, b = change.old, change.new
        if not a or not b or a.get("line") is None or b.get("line") is None:
            return None
        lines = list(difflib.unified_diff(self.old.lines(a["file"], a["line"], a["end"]),
                                          self.new.lines(b["file"], b["line"], b["end"]),
                                          f"{self.old.label}/{a['file']}:{a['line']}",
                                          f"{self.new.label}/{b['file']}:{b['line']}", lineterm="", n=2))
        if len(lines) > DIFF_LINES:
            lines = lines[:DIFF_LINES] + [f"... {len(lines) - DIFF_LINES} more lines: dev/tools/blizzard show"]
        return lines or None

    def related(self, record):
        """The structures and enums an API's or event's arguments, returns or payload name, as ids."""
        found = []
        sig = record["sig"]
        for item in sig.get("args", []) + sig.get("returns", []) + sig.get("payload", []):
            for type_ in (item.get("Type"), item.get("InnerType")):
                if type_:
                    found += [f"struct:{type_}", f"enum:Enum.{type_}"]
        return found

    def report(self, id_, uses, hook=False):
        """The findings one symbol Sane UI uses makes, if it changed."""
        self.resolved[id_].extend(uses)
        change = self.changes.get(id_)
        record = self.new.symbols.get(id_) or self.old.symbols.get(id_)
        extra = []
        if record and record["kind"] in ("api", "event"):
            for other in self.related(record):
                c = self.changes.get(other)
                if c and c.status in ("changed", "removed"):
                    extra.append(f"{other.partition(':')[2]} changed: " + "; ".join(c.notes or ["gone"]))
        if change is None or change.status == "added":
            if extra:
                self.add("changed", id_, extra, uses)
            return
        if change.status == "removed":
            moved = [i for i in self._tails.get(tail(id_), []) if i.partition(":")[2] == id_.partition(":")[2]]
            if moved:  # the same name, now of another kind (a Lua function the client now gives itself)
                self.add("changed", id_, [f"now {KIND.get(moved[0].partition(':')[0])}: {moved[0]}"], uses)
            else:
                self.add("broken", id_, ["gone from the new export"], uses, self.hints(id_))
        elif change.status == "deprecated":
            self.add("deprecated", id_, [f"now only in {change.new['file']}"] + change.notes, uses,
                     self.calls_in(id_, change.new))
        elif change.status == "changed":
            self.add("changed", id_, change.notes + extra, uses, diff=self.diff(change) if hook else None)
        elif change.status == "body":
            if hook or change.new["kind"] in ("lua", "xml") and change.new["what"] != "table":
                self.add("review", id_, (["hooked by Sane UI"] if hook else []) + change.notes + extra, uses,
                         diff=self.diff(change) if hook else None)

    # -- the kinds of use --

    def _globals(self):
        groups = defaultdict(list)
        for use in self.uses.of("global"):
            base, _, method = use.name.partition(":")
            parts = base.split(".")
            ids = [f"lua:{base}:{method}"] if method else []
            ids.append(f"lua:{base}")
            if len(parts) >= 3:
                ids += [f"enum:{'.'.join(parts[:3])}", f"const:{'.'.join(parts[:3])}"]
            if len(parts) >= 2:
                ids += [f"api:{parts[0]}.{parts[1]}", f"enum:{parts[0]}.{parts[1]}"]
            ids += [f"lua:{'.'.join(parts[:k])}" for k in range(len(parts) - 1, 0, -1)]
            ids += [f"api:{parts[0]}", f"xml:{parts[0]}", f"frame:{parts[0]}"]
            found = next((i for i in ids if self.exists(i)), None)
            if found:
                groups[found].append(use)
        for id_, uses in groups.items():
            self.report(id_, uses)

    def _strings(self):
        groups = defaultdict(list)
        for use in self.uses.of("string", "xml"):
            if not lua_name(use.name):
                continue
            for id_ in (f"event:{use.name}", f"xml:{use.name}", f"addon:{use.name}", f"cvar:{use.name.lower()}",
                        f"lua:{use.name}", f"frame:{use.name}", f"api:{use.name}"):
                if id_ in self.old.symbols:
                    groups[id_].append(use)
                    break
        for id_, uses in groups.items():
            kind = id_.partition(":")[0]
            change = self.changes.get(id_)
            if kind in ("lua", "api", "frame") and change and change.status == "body":
                continue  # named, not called: its insides matter to the hooks only
            self.report(id_, uses)

    def _hooks(self):
        for use in self.uses.of("hook"):
            if use.how == "function":
                for id_ in (f"lua:{use.name}", f"api:{use.name}"):
                    if self.exists(id_):
                        self.report(id_, [use], hook=True)
                        break
                continue
            ids_old, ids_new = self._methods_old.get(use.name, []), self._methods_new.get(use.name, [])
            if ids_old and not ids_new:
                self.add("broken", f"method:{use.name}", ["no Blizzard object has a method of this name now"],
                         [use], label=f"`:{use.name}` (hooked method)")
                continue
            ids = sorted(set(ids_old) | set(ids_new))
            for id_ in ids:  # the widgets' methods are the client's: their documentation, not their code
                change = self.changes.get(id_)
                if id_.startswith("widget:") and change and change.status in ("changed", "removed"):
                    self.report(id_, [use])
            # Which object a method is hooked on is not known here: with few methods of the name, each that
            # changed is shown with its code; with many (Show, OnLoad), one line names those that changed.
            changed = [i for i in ids if i.startswith("lua:") and self.changes.get(i)
                       and self.changes[i].status not in ("added",)]
            if len(changed) <= 3:
                for id_ in changed:
                    self.report(id_, [use], hook=True)
            else:
                self.add("review", f"method:{use.name}", [
                    f"hooked by Sane UI; {len(changed)} of the {len(ids)} Blizzard methods of this name changed: "
                    + ", ".join(i.partition(":")[2] for i in changed[:12]) + (" ..." if len(changed) > 12 else "")],
                    [use], label=f"`:{use.name}` (hooked method)")

    def _methods_called(self):
        groups = defaultdict(list)
        for use in self.uses.of("method"):
            groups[use.name].append(use)
        for name, uses in groups.items():
            ids_old, ids_new = self._methods_old.get(name, []), self._methods_new.get(name, [])
            for id_ in sorted(set(ids_old) | set(ids_new)):
                change = self.changes.get(id_)
                if change is None or change.status == "added":
                    continue
                widget = id_.startswith("widget:")
                if not widget and name in self.uses.own:
                    continue  # Sane UI has a method of this name itself
                if change.status == "removed" and (widget or not ids_new):
                    if not [i for i in ids_new if i.startswith("widget:") == widget]:
                        self.add("broken", id_, ["gone from the new export"], uses, self.hints(id_))
                elif change.status in ("changed", "deprecated"):
                    notes = change.notes + ([] if widget else ["a method of this name; Sane UI may call another's"])
                    self.add("changed" if change.status == "changed" else "deprecated", id_, notes, uses)

    def _vanished(self):
        """Names Sane UI uses that the old export mentioned and the new one mentions nowhere."""
        gone = self.old.names - self.new.names
        groups = defaultdict(list)
        for use in self.uses.items:
            if use.kind == "global":
                words = re.split(r"[.:]", use.name)
            elif use.kind in ("method", "field"):
                words = [] if use.name in self.uses.own else [use.name]
            elif use.kind in ("string", "xml"):
                path = use.name.lower().replace("\\", "/")
                words = ["path:" + re.sub(r"\.(blp|tga|png)$", "", path)] if path.startswith("interface/") else [use.name]
            else:
                continue
            for word in words:
                if word in gone and (id(use), word) not in self._reported:
                    groups[word].append(use)
        fresh = sorted(self.new.names - self.old.names)  # names only the new export has: where some went
        for word, uses in groups.items():
            weak = word.startswith("path:") or "-" in word
            where = sorted({f"{r['file']}" for i, r in self.old.symbols.items() if tail(i) == word})[:3]
            notes = ["the new export no longer mentions it anywhere"] + ([f"was in {', '.join(where)}"] if where else [])
            if weak:
                notes[0] = "Blizzard's code no longer names this atlas or file; it may still be in the game"
            hints = [f"`{name}`" for name in difflib.get_close_matches(word, fresh, n=3, cutoff=0.75)]
            self.add("review" if weak else "broken", f"name:{word}", notes, uses, hints or self.hints(f"name:{word}"),
                     label=f"`{word}` ({'atlas or file' if weak else 'name'})")

    def _housekeeping(self, tocs, generated):
        wanted = interface_of(self.new.build)
        if wanted:
            stale = []
            for toc in tocs:
                # One number per game (16001, 120105): the one of this export's game (its major version) is checked.
                found = re.search(r"^## Interface:\s*([\d,\s]+)$", toc.read_text(encoding="utf-8"), re.M)
                numbers = [int(n) for n in re.findall(r"\d+", found.group(1))] if found else []
                if found and wanted not in numbers:
                    same = [str(n) for n in numbers if n // 10000 == wanted // 10000]
                    stale.append((toc, ", ".join(same) or "none of this game's"))
            if stale:
                self.add("housekeeping", "interface", [f"`## Interface: {wanted}` for build {self.new.build}"] +
                         [f"{self.uses.rel(toc)} has {number}" for toc, number in stale], label="TOC Interface number")
        for tool, made in (generated() if generated else []):
            self.add("housekeeping", f"tool:{tool}", [f"{made} would change: run `{tool}` after adopting the export"],
                     label=f"`{tool}`")
        cited = defaultdict(list)
        for use in self.uses.of("cite"):
            cited[(use.name, use.how)].append(use)
        for (name, span), uses in sorted(cited.items(), key=lambda item: (item[0][0], item[0][1] or (0, 0))):
            path = f"AddOns/{name}"
            if path not in self.old.files or self.old.files.get(path) == self.new.files.get(path):
                continue
            if path not in self.new.files:
                note = "the file is gone"
            elif span:
                before = self.old.lines(path, span[0], span[1])
                after = self.new.lines(path, span[0], span[1])
                if before == after:
                    continue
                note = f"lines {span[0]}-{span[1]} changed"
                moved = find_block(before, self.new.lines(path, 1, None))
                if moved:
                    note = f"lines {span[0]}-{span[1]} moved, now {moved}-{moved + span[1] - span[0]}"
            else:
                note = "the file changed"
            self.add("housekeeping", f"cite:{name}:{span}", [note], uses,
                     label=f"Notes citing `{name}`" + (f" {span[0]}-{span[1]}" if span else ""))

    # -- for people --

    def by_section(self):
        out = {section: [] for section in SECTIONS}
        for (section, _), finding in self.findings.items():
            finding.uses.sort(key=lambda u: (u.file, u.line))
            out[section].append(finding)
        for section in out:
            out[section].sort(key=lambda f: (f.id.startswith("cite:"), f.id))
        return out

    def counts(self):
        statuses = defaultdict(int)
        for change in self.changes.values():
            statuses[change.status] += 1
        return dict(statuses)

    def new_api(self):
        """API new in the namespaces Sane UI calls."""
        spaces = {use.name.split(".")[0] for use in self.uses.of("global") if use.name.startswith("C_")}
        return sorted(id_.partition(":")[2] for id_, c in self.changes.items()
                      if c.status == "added" and id_.startswith("api:") and id_[4:].split(".")[0] in spaces)


def lua_name(text):
    return bool(re.fullmatch(r"[A-Za-z_][\w.\-]*", text, re.A)) and len(text) <= 80


def find_block(block, lines):
    """The line (from 1) where block starts in lines, if it is there once."""
    block = [line.strip() for line in block]
    stripped = [line.strip() for line in lines]
    if not block or not any(block):
        return None
    hits = [i + 1 for i in range(len(stripped) - len(block) + 1) if stripped[i:i + len(block)] == block]
    return hits[0] if len(hits) == 1 else None
