"""A set's schema (assets/data/<Set>/schema.toml) and the values its fields take.

The schema says a set's key, its pack and its fields in the order a pack's rows carry them; this file reads
it, checks it, and checks a value against a field. Doc/guides/data.md, *schema.toml*, is the reference.
"""
import math
import re
import tomllib

# Characters a pack's row is cut by: a tab between fields, 30 between a list's elements, 31 between an
# element's parts, 28 between the versions of an entry's history. No text may hold them.
CUTS = re.compile("[\t\x1c\x1e\x1f]")

SCALARS = ("int", "number", "text", "bool", "enum", "flags", "money", "ref")
ELEMENTS = SCALARS + ("point", "tuple")
TYPES = ELEMENTS + ("list", "map")
INDEXABLE = ("int", "text", "enum", "ref", "flags", "money")
RESERVED_INDEXES = ("replaces", "replacedBy")
NAME = re.compile(r"^[A-Za-z][A-Za-z0-9]*$")
FIELD_NAME = re.compile(r"^[a-z][A-Za-z0-9]*$")
LINE_WORDS = ("key", "since", "day", "src", "gone", "replaces")


class Field:
    """One field of a set, or one part of a tuple. For a list or map, `of` is its elements' type and the
    elements' parameters (values, set, min, max, parts) are the field's own."""

    def __init__(self, name, spec):
        self.name = name
        self.type = spec.get("type")
        self.of = spec.get("of")
        self.keys = spec.get("keys", "text")
        self.values = spec.get("values")
        self.set = spec.get("set")
        self.min = spec.get("min")
        self.max = spec.get("max")
        self.parts = None
        self.spec = spec

    @property
    def element(self):
        """The type of one value: the field's own, or its elements' for a list or map."""
        return self.of if self.type in ("list", "map") else self.type


class Schema:
    def __init__(self):
        self.set = None
        self.key = None
        self.pack = None
        self.learn = False
        self.about = None
        self.fields = []
        self.byname = {}
        self.index = {}

    @property
    def names(self):
        return [field.name for field in self.fields]

    def key_type(self):
        return int if self.key == "int" else str


def _field_problems(field, where, inside_tuple=False):
    """What is wrong with a field's description (or a tuple part's)."""
    problems = []
    allowed = SCALARS if inside_tuple else TYPES
    known = {"type", "of", "keys", "values", "set", "min", "max", "parts"}
    for word in field.spec:
        if word not in known:
            problems.append(f"{where}: '{word}' is not a field's parameter")
    if field.type not in allowed:
        what = "a tuple's part" if inside_tuple else "a field"
        problems.append(f"{where}: '{field.type}' is no type for {what} (one of {', '.join(allowed)})")
        return problems
    element = field.element
    if field.type in ("list", "map"):
        if field.of not in ELEMENTS:
            problems.append(f"{where}: a {field.type}'s 'of' is one of {', '.join(ELEMENTS)}, not '{field.of}'")
            return problems
        if field.type == "map" and field.keys not in ("text", "int"):
            problems.append(f"{where}: a map's 'keys' are 'text' or 'int'")
    elif field.of is not None:
        problems.append(f"{where}: 'of' is only for a list or map")
    if element == "enum":
        values = field.values
        if not (isinstance(values, list) and values and all(isinstance(v, str) and v and not CUTS.search(v) for v in values)):
            problems.append(f"{where}: an enum needs 'values', a list of words")
        elif len(set(values)) != len(values):
            problems.append(f"{where}: an enum's values are each named once")
    elif field.values is not None:
        problems.append(f"{where}: 'values' is only for an enum")
    if element == "ref":
        if not (isinstance(field.set, str) and NAME.match(field.set)):
            problems.append(f"{where}: a ref needs 'set', the name of the set it points into")
    elif field.set is not None:
        problems.append(f"{where}: 'set' is only for a ref")
    for end in ("min", "max"):
        value = getattr(field, end)
        if value is not None and (element not in ("int", "number", "money") or isinstance(value, bool)
                                  or not isinstance(value, (int, float))):
            problems.append(f"{where}: '{end}' is a number, for an int, number or money")
    if element == "tuple":
        parts = field.spec.get("parts")
        if not (isinstance(parts, list) and parts):
            problems.append(f"{where}: a tuple needs 'parts', a list of named parts")
            return problems
        field.parts, seen = [], set()
        for number, part in enumerate(parts, 1):
            if not isinstance(part, dict) or not isinstance(part.get("name"), str) or not FIELD_NAME.match(part["name"]):
                problems.append(f"{where}: part {number} needs a 'name' (a word starting in lower case)")
                continue
            if part["name"] in seen:
                problems.append(f"{where}: two parts are called '{part['name']}'")
            seen.add(part["name"])
            spec = {k: v for k, v in part.items() if k != "name"}
            inner = Field(part["name"], spec)
            problems += _field_problems(inner, f"{where}, part {part['name']}", inside_tuple=True)
            field.parts.append(inner)
    elif field.spec.get("parts") is not None:
        problems.append(f"{where}: 'parts' is only for a tuple")
    return problems


def load(path, where=None):
    """(Schema or None, problems) from a schema.toml; where: how problems name the file."""
    where = where or str(path)
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError, UnicodeDecodeError) as error:
        return None, [f"{where}: does not parse: {error}"]
    problems, schema = [], Schema()
    for word in data:
        if word not in ("set", "key", "pack", "learn", "about", "fields", "index"):
            problems.append(f"{where}: '{word}' is not part of a schema")
    schema.set, schema.key, schema.pack = data.get("set"), data.get("key"), data.get("pack")
    schema.learn, schema.about = data.get("learn", False), data.get("about")
    if not (isinstance(schema.set, str) and NAME.match(schema.set)):
        problems.append(f"{where}: 'set' is the set's name (letters and digits, a capital first)")
    if schema.key not in ("int", "text"):
        problems.append(f"{where}: 'key' is \"int\" or \"text\"")
    if not (isinstance(schema.pack, str) and NAME.match(schema.pack)):
        problems.append(f"{where}: 'pack' names the pack the set goes into")
    if not isinstance(schema.learn, bool):
        problems.append(f"{where}: 'learn' is true or false")
    if not (isinstance(schema.about, str) and schema.about.strip()):
        problems.append(f"{where}: 'about' says in a sentence what the set holds")
    fields = data.get("fields", {})
    if not isinstance(fields, dict) or not fields:
        problems.append(f"{where}: [fields] holds at least one field")
        fields = {}
    for name, spec in fields.items():
        if not FIELD_NAME.match(name) or name in LINE_WORDS:
            problems.append(f"{where}: '{name}' is no name for a field (a word starting in lower case, not one of {', '.join(LINE_WORDS)})")
            continue
        if not isinstance(spec, dict):
            problems.append(f"{where}: field '{name}' is described as {{ type = ... }}")
            continue
        field = Field(name, spec)
        problems += _field_problems(field, f"{where}, field {name}")
        schema.fields.append(field)
        schema.byname[name] = field
    index = data.get("index", {})
    if not isinstance(index, dict):
        problems.append(f"{where}: [index] maps an index's name to a field")
        index = {}
    for name, target in index.items():
        if name in RESERVED_INDEXES or not FIELD_NAME.match(name):
            problems.append(f"{where}: '{name}' is no name for an index ({' and '.join(RESERVED_INDEXES)} are the compiler's)")
        elif target not in schema.byname:
            problems.append(f"{where}: index '{name}' names no field ('{target}')")
        elif schema.byname[target].element not in INDEXABLE or schema.byname[target].type == "map":
            problems.append(f"{where}: index '{name}': a field of type {schema.byname[target].type} cannot be indexed")
        else:
            schema.index[name] = schema.byname[target]
    return schema, problems


def _text_problem(value):
    if not isinstance(value, str):
        return "is no text"
    if value == "":
        return "is empty (leave it out instead)"
    if CUTS.search(value):
        return "holds a tab or the character 28, 30 or 31"
    return None


def _number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _whole(value):
    return isinstance(value, int) and not isinstance(value, bool)


def value_problem(field, value, key_types, refs, kind=None):
    """What is wrong with a value of a field, or None. kind: the type to check (a list's or map's element).
    key_types maps a set's name to its key's type (int or str), for refs; every ref found is added to refs
    as (set, key), so their entries can be looked for afterwards."""
    kind = kind or field.type
    if kind == "list":
        if not isinstance(value, list) or not value:
            return "is no list (or an empty one: leave it out instead)"
        for number, element in enumerate(value, 1):
            if element is None:
                return f"element {number} is null"
            problem = value_problem(field, element, key_types, refs, field.of)
            if problem:
                return f"element {number} {problem}"
        return None
    if kind == "map":
        if not isinstance(value, dict) or not value:
            return "is no map (or an empty one: leave it out instead)"
        for key, element in value.items():
            if field.keys == "int" and not re.match(r"^-?\d+$", key):
                return f"key '{key}' is no whole number"
            problem = _text_problem(key)
            if problem:
                return f"key '{key}' {problem}"
            if element is None:
                return f"'{key}' is null"
            problem = value_problem(field, element, key_types, refs, field.of)
            if problem:
                return f"'{key}' {problem}"
        return None
    if kind == "int":
        if not _whole(value):
            return "is no whole number"
    elif kind == "number":
        if not _number(value):
            return "is no number"
    elif kind == "text":
        return _text_problem(value)
    elif kind == "bool":
        return None if value is True else "is not true (false is no value: leave it out)"
    elif kind == "enum":
        return None if value in field.values else f"is not one of {', '.join(field.values)}"
    elif kind in ("flags", "money"):
        return None if _whole(value) and value >= 0 else "is no whole number from 0"
    elif kind == "point":
        if not (isinstance(value, list) and len(value) == 3 and _whole(value[0]) and value[0] >= 0
                and all(_number(v) and 0 <= v <= 100 for v in value[1:])):
            return "is no point [map, x, y] (x and y from 0 to 100)"
        if any(abs(v * 10 - round(v * 10)) > 1e-9 for v in value[1:]):
            return "has x or y with more than one decimal"
        return None
    elif kind == "ref":
        want = key_types.get(field.set)
        if want is None:
            return f"points into '{field.set}', which is no set"
        if want is int and not _whole(value):
            return f"is no key of {field.set} (a whole number)"
        if want is str:
            problem = _text_problem(value)
            if problem:
                return f"is no key of {field.set}: it {problem}"
        refs.add((field.set, value))
        return None
    elif kind == "tuple":
        if not isinstance(value, dict) or not value:
            return "is no tuple (an object of its parts)"
        names = {part.name: part for part in field.parts or ()}
        for name, part_value in value.items():
            if name not in names:
                return f"has no part '{name}'"
            if part_value is None:
                return f"part '{name}' is null"
            problem = value_problem(names[name], part_value, key_types, refs)
            if problem:
                return f"part '{name}' {problem}"
        return None
    else:
        return f"has an unknown type '{kind}'"
    for end, compare in (("min", lambda v, e: v < e), ("max", lambda v, e: v > e)):
        limit = getattr(field, end)
        if limit is not None and compare(value, limit):
            return f"is {'under' if end == 'min' else 'over'} its {end} {limit}"
    return None


def canonical(field, value):
    """The value as the tools write it: a map's keys sorted (numbers by value), everything else as it is."""
    if value is None:
        return None
    if field.type == "map":
        if field.keys == "int":
            order = sorted(value, key=int)
        else:
            order = sorted(value)
        return {key: value[key] for key in order}
    return value


def same(a, b):
    """Whether two values are the same fact (1 and 1.0 alike; maps whatever their order)."""
    if isinstance(a, bool) or isinstance(b, bool):
        return a is b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return a == b
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b
