"""Reading Lua as the game's Lua 5.1 reads it, as far as the Blizzard tools need: the tokens (comments dropped,
strings kept), what a file defines at its top level, and the plain tables of Blizzard's API documentation.
"""
import bisect
import re

KEYWORDS = frozenset("and break do else elseif end false for function if in local nil not or repeat return then "
                     "true until while".split())
OPENERS = frozenset(("function", "do", "if", "repeat"))  # each one closes with an end or (repeat) an until
CLOSERS = frozenset(("end", "until"))
# Tokens after which an expression goes on to the next line, so a value does not end there.
GOES_ON = frozenset(("=", ",", "..", "+", "-", "*", "/", "%", "^", "#", "==", "~=", "<", ">", "<=", ">=", "(", "[",
                     "{", "and", "or", "not"))

TOKEN = re.compile(r"""
    (?P<space>\s+)
  | (?P<comment>--(?:\[(?P<ceq>=*)\[.*?\](?P=ceq)\]|[^\n]*))
  | (?P<long>\[(?P<leq>=*)\[.*?\](?P=leq)\])
  | (?P<string>"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*')
  | (?P<number>0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)
  | (?P<name>[A-Za-z_]\w*)
  | (?P<op>\.\.\.|\.\.|==|~=|<=|>=|::|[-+*/%^\#<>=(){}\[\];:,.])
  | (?P<other>.)
""", re.S | re.X | re.A)
LONG_OPEN = re.compile(r"\[=*\[\n?")
# A string worth comparing as a name: a global, a template, an event, a callback, an atlas.
NAMEISH = re.compile(r"[A-Za-z_][\w.\-]*\Z", re.A)


class Source:
    """A file's tokens, each (kind, value, offset): kind is name, key (a keyword), string, number or op.
    Strings carry their text without the quotes, escapes as written."""

    def __init__(self, text):
        self.text = text
        self.toks = []
        self._lines = None
        append = self.toks.append
        for match in TOKEN.finditer(text):
            kind = match.lastgroup
            if kind in ("space", "comment"):
                continue
            value = match.group()
            if kind == "name":
                if value in KEYWORDS:
                    kind = "key"
            elif kind == "string":
                value = value[1:-1]
            elif kind == "long":
                kind, value = "string", value[LONG_OPEN.match(value).end():-(value.index("[", 1) + 1)]
            append((kind, value, match.start()))

    def line(self, index):
        """The line (from 1) of the token at index."""
        if self._lines is None:
            self._lines = [m.start() for m in re.finditer("\n", self.text)]
        return bisect.bisect_right(self._lines, self.toks[index][2]) + 1

    def values(self, first, last):
        return [tok[1] for tok in self.toks[first:last + 1]]


def chain_back(toks, end):
    """The names of a plain chain A.B.C that ends at the token end, and the index of its first token; no names
    when the chain hangs on something else (f().x, t[k].x)."""
    if end < 0 or toks[end][0] != "name":
        return [], end
    parts, i = [toks[end][1]], end
    while i >= 2 and toks[i - 1][1] == "." and toks[i - 1][0] == "op":
        if toks[i - 2][0] != "name":
            return [], i
        parts.append(toks[i - 2][1])
        i -= 2
    return parts[::-1], i


def params(toks, open_index):
    """The parameter names of a function whose ( is at open_index, and the index of its )."""
    names, i = [], open_index + 1
    while i < len(toks) and toks[i][1] != ")":
        if toks[i][0] == "name" or toks[i][1] == "...":
            names.append(toks[i][1])
        i += 1
    return names, i


def definitions(source):
    """What a file defines for every other file: its global functions, tables and values (Name, A.B), methods
    (A:B), the keys of the tables it makes at its top level (A = { B = ... }), and the frames and fonts it makes
    with a global name (CreateFrame("Frame", "Name")). Each is a dict: chain (A.B or A:B), what (function,
    table, value, frame), params (functions), first and last (token indices). A top-level local and what
    hangs on it are not given."""
    toks, found, local = source.toks, [], set()
    block = nest = 0
    open_ = []  # [definition, how it closes, at which depth]
    ctor = []  # tables being made at the top level: [chain, nest inside]
    n = len(toks)

    def define(chain, what, first, last=None, args=None):
        item = {"chain": chain, "what": what, "first": first, "last": last if last is not None else first}
        if args is not None:
            item["params"] = args
        found.append(item)
        return item

    def right_side(item_chain, at, close_nest):
        """The definition of item_chain whose value starts at the token at; how it closes is pushed."""
        kind, value = toks[at][0], toks[at][1]
        if kind == "key" and value == "function" and at + 1 < n and toks[at + 1][1] == "(":
            args, _ = params(toks, at + 1)
            if args and args[0] == "self" and "." in item_chain:
                head, _, tail = item_chain.rpartition(".")
                item_chain = f"{head}:{tail}"
            open_.append([define(item_chain, "function", at, args=args), "block", block])
        elif kind == "op" and value == "{":
            open_.append([define(item_chain, "table", at), "nest", close_nest])
            if item_chain.count(".") < 2:
                ctor.append([item_chain, close_nest + 1])
        else:
            open_.append([define(item_chain, "value", at), "value", close_nest])

    i = 0
    while i < n:
        kind, value, _ = toks[i]
        prev = toks[i - 1][1] if i else None
        if block == 0:
            if nest == 0:
                if kind == "key" and value == "local":
                    j = i + 1
                    if j < n and toks[j][1] == "function":
                        j += 1
                    while j < n and toks[j][0] == "name":
                        local.add(toks[j][1])
                        if j + 1 < n and toks[j + 1][1] == ",":
                            j += 2
                            continue
                        break
                elif kind == "key" and value == "function" and prev != "local" and i + 1 < n and toks[i + 1][0] == "name":
                    j, parts, method = i + 1, [toks[i + 1][1]], None
                    while j + 2 < n and toks[j + 1][1] in (".", ":") and toks[j + 2][0] == "name":
                        if toks[j + 1][1] == ":":
                            method = toks[j + 2][1]
                            j += 2
                            break
                        parts.append(toks[j + 2][1])
                        j += 2
                    if j + 1 < n and toks[j + 1][1] == "(" and parts[0] not in local:
                        args, _ = params(toks, j + 1)
                        chain = ".".join(parts) + (f":{method}" if method else "")
                        open_.append([define(chain, "function", i, args=args), "block", 0])
                elif kind == "op" and value == "=":
                    targets, j = [], i - 1
                    while j >= 0:
                        parts, start = chain_back(toks, j)
                        if not parts:
                            break
                        targets.append((parts, start))
                        if start >= 1 and toks[start - 1][1] == ",":
                            j = start - 2
                            continue
                        break
                    before = toks[targets[-1][1] - 1][1] if targets and targets[-1][1] > 0 else None
                    if targets and before not in ("local", "for", ".", ":"):
                        targets.reverse()
                        for parts, _ in targets:
                            if parts[0] in local:
                                continue
                            if len(targets) == 1 and i + 1 < n:
                                right_side(".".join(parts), i + 1, 0)
                            else:
                                define(".".join(parts), "value", i)
            elif ctor and nest == ctor[-1][1] and kind == "name" and prev in ("{", ",", ";") \
                    and i + 2 < n and toks[i + 1][1] == "=" and toks[i + 1][0] == "op":
                right_side(f"{ctor[-1][0]}.{value}", i + 2, nest)
        if kind == "name" and value in ("CreateFrame", "CreateFont") and i + 3 < n and toks[i + 1][1] == "(":
            at = i + 2 if value == "CreateFont" else i + 4
            if at < n and toks[at][0] == "string" and (value == "CreateFont" or toks[i + 3][1] == ","):
                name = toks[at][1]
                if NAMEISH.match(name) and "$" not in name:
                    define(name, "frame", i)

        # The depth after this token, then whatever it closes.
        if kind == "key":
            if value in OPENERS:
                block += 1
            elif value in CLOSERS:
                block -= 1
        elif kind == "op":
            if value in "([{":
                nest += 1
            elif value in ")]}":
                nest -= 1
                while ctor and nest < ctor[-1][1]:
                    ctor.pop()
        while open_:
            item, how, depth = open_[-1]
            if how == "block" and kind == "key" and value in CLOSERS and block == depth:
                item["last"] = i
            elif how == "nest" and kind == "op" and value in ")]}" and nest == depth:
                item["last"] = i
            elif how == "value" and i >= item["first"]:
                ends = None
                if depth > 0:  # a key's value in a table: up to its , or ; or the table's }
                    if nest == depth and kind == "op" and value in (",", ";"):
                        ends = i - 1
                    elif nest < depth:
                        ends = i - 1
                elif nest == 0 and kind == "op" and value == ";":
                    ends = i - 1
                elif nest == 0 and i + 1 < n and toks[i + 1][1] not in GOES_ON and value not in GOES_ON \
                        and source.line(i + 1) > source.line(i):
                    ends = i
                if ends is None:
                    break
                item["last"] = ends
            else:
                break
            open_.pop()
        i += 1
    for item, _, _ in open_:
        item["last"] = n - 1
    return found


def calls_with(source, word):
    """The strings given to calls whose name holds word (CVar: GetCVar, SetCVar, Settings.SetupCVarCheckbox)."""
    toks, stack, found = source.toks, [], []
    for i, (kind, value, _) in enumerate(toks):
        if kind == "op" and value == "(":
            stack.append(i > 0 and toks[i - 1][0] == "name" and word in toks[i - 1][1])
        elif kind == "op" and value == ")":
            if stack:
                stack.pop()
        elif kind == "string" and stack and stack[-1]:
            found.append(value)
    return found


def literal(toks, i):
    """The plain Lua value at token i (a table, string, number, true, false, nil) and the index after it.
    A table with keys is a dict; one without is a list."""
    kind, value, _ = toks[i]
    if kind == "string":
        return value, i + 1
    if kind == "number":
        try:
            return (int(value, 0) if value.lower().startswith("0x") or value.isdigit() else float(value)), i + 1
        except ValueError:
            return value, i + 1
    if kind == "key" and value in ("true", "false", "nil"):
        return {"true": True, "false": False, "nil": None}[value], i + 1
    if kind == "op" and value == "-" and toks[i + 1][0] == "number":
        number, after = literal(toks, i + 1)
        return -number if isinstance(number, (int, float)) else number, after
    if kind == "op" and value == "{":
        keyed, listed, i = {}, [], i + 1
        while toks[i][1] != "}":
            if toks[i][0] == "name" and toks[i + 1][1] == "=":
                keyed[toks[i][1]], i = literal(toks, i + 2)
            elif toks[i][1] == "[":
                key, i = literal(toks, i + 1)
                keyed[key], i = literal(toks, i + 2)  # past ] =
            else:
                item, i = literal(toks, i)
                listed.append(item)
            if toks[i][1] in (",", ";"):
                i += 1
        return (keyed if keyed or not listed else listed), i + 1
    # A name or an expression: kept as the words written (the documentation names types this way at most).
    return value, i + 1


def documentation(source):
    """The tables a file of Blizzard_APIDocumentationGenerated gives: each local Name = { ... } at its top."""
    toks, found = source.toks, []
    for i in range(len(toks) - 3):
        if toks[i][1] == "local" and toks[i + 1][0] == "name" and toks[i + 2][1] == "=" and toks[i + 3][1] == "{":
            try:
                table, _ = literal(toks, i + 3)
            except IndexError:
                continue
            if isinstance(table, dict):
                found.append(table)
    return found
