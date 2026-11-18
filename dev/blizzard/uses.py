"""What SaneUI takes from Blizzard: every name in src/ that may be Blizzard's, and where it stands.

  global   a global the code reads, with what it reaches through it (C_Spell.GetSpellInfo, GameTooltip:AddLine,
           Enum.SpellBookSpellBank.Player); luac tells a global from a local
  string   a string (an event, a template, a font, an addon, a CVar, a menu's tag, a callback's name), with the
           call it is given to
  hook     a function or method hooked with hooksecurefunc (its body matters, not only its name)
  method   a method called by its name (frame:SetPoint): the game's widgets or a Blizzard mixin
  field    a key read by its name (frame.ScrollBox, starting with a capital): a template's parentKey or a value
  xml      an attribute of SaneUI's XML (inherits, mixin, font, atlas, file)
  cite     a note in src/ or Doc/ that cites a Blizzard file (Blizzard_ChatFrame/Shared/ChatFrame.lua 120-140)

own holds the names SaneUI defines itself (function A:Name, A.Name = ..., { Name = ... }): a method or field
of that name may be SaneUI's own, so its name alone is not taken as Blizzard's.
"""
import re
import subprocess
from pathlib import Path

import lua

OWN = re.compile(r"(SaneUI|SLASH_SANEUI|BINDING_(HEADER|NAME)_SANEUI)")
LISTING_HEAD = re.compile(r"^(?:main|function) <(.+?):\d+,\d+>")
GETGLOBAL = re.compile(r"\[(\d+)\]\s+GETGLOBAL\s.*;\s+(\S+)\s*$")
CITE = re.compile(r"(Blizzard_\w+(?:/[\w.\-]+)+\.(?:lua|xml|toc))[`'\"]?(?:,? (?:lines? )?(\d+)(?:\s*-\s*(\d+))?|:(\d+))?")
XML_ATTRIBUTE = re.compile(r'\b(inherits|mixin|secureMixin|font|atlas|file|parentKey|parentArray|name)\s*=\s*"([^"]*)"')
# Notes that only record history: what they cite was true then.
HISTORY = ("Changed.md", "changelog.txt")


class Use:
    __slots__ = ("kind", "name", "file", "line", "how")

    def __init__(self, kind, name, file, line, how=None):
        self.kind, self.name, self.file, self.line, self.how = kind, name, file, line, how

    def where(self):
        return f"{self.file}:{self.line}"

    def __repr__(self):
        return f"Use({self.kind}, {self.name!r}, {self.where()}{', ' + repr(self.how) if self.how else ''})"


class Uses:
    """Everything SaneUI's source takes by name, read from a source folder (src/) and its notes (Doc/)."""

    def __init__(self, src, notes=(), root=None):
        self.src = Path(src)
        self.root = Path(root) if root else self.src.parent
        self.items = []
        self.own = set()
        self.problems = []
        files = sorted(self.src.rglob("*.lua"))
        reads = self._globals(files)
        for path in files:
            self._lua(path, reads.get(path.resolve(), []))
        for path in sorted(self.src.rglob("*.xml")):
            self._xml(path)
        for folder in (self.src, *map(Path, notes)):
            for path in sorted(folder.rglob("*")):
                if path.suffix in (".lua", ".xml", ".md", ".txt", ".toc") and path.name not in HISTORY:
                    self._cites(path)

    def rel(self, path):
        try:
            return Path(path).resolve().relative_to(self.root.resolve()).as_posix()
        except ValueError:
            return str(path)

    def add(self, kind, name, path, line, how=None):
        self.items.append(Use(kind, name, self.rel(path), line, how))

    def _globals(self, files):
        """[file] = [(line, name)] of every global each file reads, by the compiler's own listing."""
        found = {}
        if not files:
            return found
        result = subprocess.run(["luac5.1", "-p", "-l", *map(str, files)], capture_output=True, text=True)
        if result.returncode:
            self.problems.append(result.stderr.strip())
        current = None
        for line in result.stdout.splitlines():
            head = LISTING_HEAD.match(line)
            if head:
                current = Path(head.group(1)).resolve()
                continue
            read = GETGLOBAL.search(line)
            if read and current is not None:
                found.setdefault(current, []).append((int(read.group(1)), read.group(2)))
        return found

    def _lua(self, path, reads):
        source = lua.Source(path.read_text(encoding="utf-8"))
        toks, n = source.toks, len(source.toks)
        by_line = {}
        for i in range(n):
            by_line.setdefault(source.line(i), []).append(i)
        taken = set()  # tokens that are part of a global's chain
        for line, name in set(reads):
            for i in by_line.get(line, []):
                kind, value, _ = toks[i]
                if kind != "name" or value != name or (i and toks[i - 1][1] in (".", ":")) or i in taken:
                    continue
                parts, j, method = [value], i, None
                while j + 2 < n and toks[j + 1][1] == "." and toks[j + 1][0] == "op" and toks[j + 2][0] == "name":
                    parts.append(toks[j + 2][1])
                    j += 2
                if j + 2 < n and toks[j + 1][1] == ":" and toks[j + 2][0] == "name":
                    method = toks[j + 2][1]
                    j += 2
                taken.update(range(i, j + 1))
                if parts[0] == "_G" and len(parts) > 1:
                    parts = parts[1:]
                elif parts[0] == "_G":
                    continue
                if OWN.match(parts[0]):
                    continue
                self.add("global", ".".join(parts) + (f":{method}" if method else ""), path, line)

        stack = []  # per open ( or {: [the call's name or None, which argument]
        for i, (kind, value, _) in enumerate(toks):
            if kind == "op":
                if value == "(":
                    k, parts = i - 1, []
                    while k >= 0 and toks[k][0] == "name":
                        parts.append(toks[k][1])
                        if k >= 2 and toks[k - 1][1] in (".", ":") and toks[k - 1][0] == "op":
                            parts.append(toks[k - 1][1])
                            k -= 2
                            continue
                        break
                    stack.append(["".join(reversed(parts)) or None, 0])
                elif value in "{[":
                    stack.append([None, 0])
                elif value in ")}]":
                    if stack:
                        stack.pop()
                elif value == "," and stack:
                    stack[-1][1] += 1
                elif value in (":", ".") and i + 1 < n and toks[i + 1][0] == "name":
                    name = toks[i + 1][1]
                    if i + 2 < n and toks[i + 2][1] == "=" and toks[i + 2][0] == "op" and value == ".":
                        self.own.add(name)
                    elif value == ":":
                        self.add("method", name, path, source.line(i))
                    elif i + 1 not in taken and name[:1].isupper():
                        self.add("field", name, path, source.line(i))
            elif kind == "key" and value == "function" and i + 1 < n and toks[i + 1][0] == "name":
                j = i + 1
                while j + 2 < n and toks[j + 1][1] in (".", ":") and toks[j + 2][0] == "name":
                    j += 2
                self.own.add(toks[j][1])
            elif kind == "name" and i and toks[i - 1][1] in ("{", ",", ";") and i + 1 < n \
                    and toks[i + 1][1] == "=" and toks[i + 1][0] == "op" and stack and stack[-1][0] is None:
                self.own.add(value)
            elif kind == "string":
                call, argument = stack[-1] if stack else (None, 0)
                self.add("string", value, path, source.line(i), f"{call} #{argument + 1}" if call else None)
                if call and call.rpartition(".")[2].rpartition(":")[2] == "hooksecurefunc":
                    self.add("hook", value, path, source.line(i), "function" if argument == 0 else "method")

    def _xml(self, path):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for attribute, value in XML_ATTRIBUTE.findall(line):
                words = [w for w in re.split(r"[\s,]+", value) if w]
                if attribute in ("parentKey", "parentArray", "name"):
                    self.own.update(words)
                    continue
                for word in words:
                    if not OWN.match(word):
                        self.add("xml", word, path, number, attribute)

    def _cites(self, path):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            return
        for number, line in enumerate(text.splitlines(), 1):
            for match in CITE.finditer(line):
                first = match.group(2) or match.group(4)
                last = match.group(3) or first
                span = (int(first), int(last)) if first else None
                self.add("cite", match.group(1), path, number, span)

    def of(self, *kinds):
        return [use for use in self.items if use.kind in kinds]
