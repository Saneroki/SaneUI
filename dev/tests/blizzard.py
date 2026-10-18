#!/usr/bin/env python3
"""Tests of dev/tools/blizzard (dev/blizzard; Doc/guides/blizzard-updates.md): its reading of Lua, TOCs, XML and
the API documentation, and the whole comparison on a small export (dev/tests/blizzard/old) and a new build made
from it here with one change of each kind, against a small module that uses each (dev/tests/blizzard/src).
Run by dev/tests/run."""
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
FIXTURE = HERE / "blizzard"
sys.path.insert(0, str(ROOT / "dev" / "blizzard"))

import compare  # noqa: E402
import export as exports  # noqa: E402
import lua  # noqa: E402
import report  # noqa: E402
import uses as sane  # noqa: E402

checks_run = failed = 0


def check(name, got, want):
    global checks_run, failed
    checks_run += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


# -- Lua --------------------------------------------------------------------------------------------------

source = lua.Source('local a = "x\\"y" -- note\n--[[ long\ncomment ]] b = [==[ s ]] ]==] c = 0x1F d = .5e2\n')
check("tokens", [(k, v) for k, v, _ in source.toks],
      [("key", "local"), ("name", "a"), ("op", "="), ("string", 'x\\"y'), ("name", "b"), ("op", "="),
       ("string", " s ]] "), ("name", "c"), ("op", "="), ("number", "0x1F"), ("name", "d"), ("op", "="),
       ("number", ".5e2")])
check("token lines", [source.line(i) for i in (0, 4, 7)], [1, 3, 3])

test_lua = lua.Source((FIXTURE / "old/Interface/AddOns/Blizzard_Test/Shared/Test.lua").read_text())
defined = {d["chain"]: d for d in lua.definitions(test_lua)}
check("definitions", sorted(defined), [
    "OldFunction", "Settings", "Settings.Open", "TEST_CONSTANT", "TestMixin", "TestMixin:OnLoad",
    "TestMixin:Refresh", "Test_Comment", "Test_Hooked", "Test_Params", "Test_Table", "Test_Table.Value",
    "Test_Table:Inner"])
check("parameters", defined["TestMixin:Refresh"]["params"], ["force"])
check("a table's method takes self", defined["Test_Table:Inner"]["params"], ["self", "x"])
check("a function's end", test_lua.line(defined["Test_Hooked"]["last"]), 14)
check("a value's end", test_lua.values(defined["TEST_CONSTANT"]["first"], defined["TEST_CONSTANT"]["last"]), ["5"])
frames = lua.definitions(lua.Source('CreateFrame("Frame", "NamedFrame", UIParent)\nCreateFrame("Frame", "$parentX")\n'))
check("named frames", [d["chain"] for d in frames], ["NamedFrame"])
check("cvars", lua.calls_with(lua.Source('SetCVar("autoLoot", 1) print("no") Settings.SetupCVarCheckbox(c, "x", L)'),
                              "CVar"), ["autoLoot", "x"])
check("literal", lua.literal(lua.Source('{ A = 1, B = { "x", -2 }, C = true, [3] = "y" }').toks, 0)[0],
      {"A": 1, "B": ["x", -2], "C": True, 3: "y"})

# -- TOCs, builds -----------------------------------------------------------------------------------------

check("allowed: none", exports.allowed(""), True)
check("allowed: camelot", exports.allowed("[AllowLoadGameType camelot]"), True)
check("allowed: mainline counts this client", exports.allowed("[AllowLoadGameType mainline]"), True)
check("allowed: excluded", exports.allowed("[AllowLoadGameType mainline] [ExcludeLoadGameType camelot]"), False)
check("allowed: another game", exports.allowed("[AllowLoadGameType vanilla, tbc]"), False)
check("allowed: the login screen", exports.allowed("[AllowLoad glue]"), False)
check("allowed: another language", exports.allowed("[AllowLoadTextLocale: zhCN]"), False)
check("interface number", [exports.interface_of(v) for v in ("1.60.1.70450", "1.61.12.1", "x", None)],
      [16001, 16112, None, None])

with tempfile.TemporaryDirectory() as scratch:
    game = Path(scratch) / "World of Warcraft" / "_forever_"
    shutil.copytree(FIXTURE / "old", game / "BlizzardInterfaceCode")
    (game / ".flavor.info").write_text("Product Flavor!STRING:0\nwowf\n")
    (game.parent / ".build.info").write_text("Branch!STRING:0|Version!STRING:0|Product!STRING:0\n"
                                             "eu|1.60.1.70450|wow_classic_beta\neu|1.60.1.70245|wowf\n")
    check("locate: the game folder", exports.locate(game), game / "BlizzardInterfaceCode")
    check("locate: Interface", exports.locate(game / "BlizzardInterfaceCode" / "Interface"),
          game / "BlizzardInterfaceCode")
    check("locate: nothing", exports.locate(scratch), None)
    check("build of a game folder's export", exports.build_of(game / "BlizzardInterfaceCode"), "1.60.1.70245")

# -- one export -------------------------------------------------------------------------------------------

old = exports.Export(FIXTURE / "old")
check("files loaded", sorted(old.loaded), [
    "AddOns/Blizzard_Gone/Gone.lua", "AddOns/Blizzard_Test/Camelot/Game.lua", "AddOns/Blizzard_Test/Mainline/Family.lua",
    "AddOns/Blizzard_Test/Shared/Test.lua", "AddOns/Blizzard_Test/Shared/Test.xml"])
check("an addon of the main game only", old.symbols["addon:Blizzard_Retail"]["sig"]["loads"], False)
check("an addon's dependencies", old.symbols["addon:Blizzard_Test"]["sig"]["deps"], ["Blizzard_SharedXML"])
check("template", old.symbols["xml:TestButtonTemplate"]["sig"], {
    "tag": "Button", "mixin": "TestMixin", "virtual": True, "size": {"x": "10", "y": "20"},
    "keys": ["Box (Frame)", "Text (FontString)"], "scripts": ["OnLoad method=OnLoad"]})
check("a child's $parent name", "xml:TestFrameClose" in old.symbols, True)
check("font", old.symbols["xml:TestFont"]["what"], "font")
check("API", old.symbols["api:C_Test.GetThing"]["sig"], {
    "args": [{"Name": "thingID", "Type": "number", "Nilable": False}],
    "returns": [{"Name": "thing", "Type": "string", "Nilable": False}], "flags": {}})
check("enum value", old.symbols["enum:Enum.TestKind.Second"]["sig"], {"value": 2})
check("widget method", "widget:SimpleTestAPI:SetThing" in old.symbols, True)
check("names: strings and atlases", {"MENU_TEST_TAG", "test-atlas-old"} <= old.names, True)
check("names: not from what does not load", "VanillaOnly" in old.names or "RetailFunc" in old.names, False)

# -- a new build, one change of each kind -----------------------------------------------------------------


def edit(root, rel, before, after):
    path = root / "Interface" / "AddOns" / rel
    text = path.read_text()
    if before not in text:
        raise SystemExit(f"fixture edit: {before!r} is not in {rel}")
    path.write_text(text.replace(before, after, 1))


scratch = tempfile.TemporaryDirectory()
new_root = Path(scratch.name) / "BlizzardInterfaceCode"
shutil.copytree(FIXTURE / "old", new_root)
test = "Blizzard_Test/Shared/Test.lua"
edit(new_root, test, "\tframe:Show();\n", "\tframe:Show();\n\tframe:Raise();\n")  # a hooked function's insides
edit(new_root, test, "Test_Params(a, b)", "Test_Params(a, b, c)")  # parameters
edit(new_root, test, "Test_Comment()\n\treturn 1;", "Test_Comment()\n\t-- Only words.\n\treturn  1;")  # nothing
edit(new_root, test, "function OldFunction()\n\treturn C_Test.NewFunction();\nend\n", "")  # to the deprecated
edit(new_root, test, "TEST_CONSTANT = 5;", "TEST_CONSTANT = 6;")  # a value
edit(new_root, test, '"MENU_TEST_TAG"', '"MENU_TEST_TAG_NEW"')  # a name no longer mentioned
edit(new_root, test, "Refresh(force)", "Refresh(force, again)")  # a hooked method's parameters
edit(new_root, test, "Settings.Open(category)", "Settings.Open(category, page)")  # Sane UI's local has that name
edit(new_root, "Blizzard_Test/Shared/Test.xml", '\t\t<Frames>\n\t\t\t<Frame parentKey="Box"/>\n\t\t</Frames>\n', "")
edit(new_root, "Blizzard_Test/Shared/Test.xml", "test-atlas-old", "test-atlas-new")
edit(new_root, "Blizzard_Test/Mainline/Family.lua", "return 1;", "return 2;")
edit(new_root, "Blizzard_Test/Vanilla/Only.lua", "return 1;", "return 2;")  # not loaded: nothing
edit(new_root, "Blizzard_Test/Mainline/Excluded.lua", "return 1;", "return 2;")  # not loaded: nothing
shutil.rmtree(new_root / "Interface/AddOns/Blizzard_Gone")
deprecated = new_root / "Interface/AddOns/Blizzard_DeprecatedTest"
deprecated.mkdir()
(deprecated / "Blizzard_DeprecatedTest.toc").write_text("## Title: Blizzard_DeprecatedTest\nDeprecated.lua\n")
(deprecated / "Deprecated.lua").write_text("function OldFunction()\n\treturn C_Test.NewFunction();\nend\n")
docs = "Blizzard_APIDocumentationGenerated/TestDocumentation.lua"
edit(new_root, docs, '{ Name = "thingID", Type = "number", Nilable = false },',
     '{ Name = "thingID", Type = "number", Nilable = false },\n\t\t\t\t{ Name = "flags", Type = "number", Nilable = true },')
edit(new_root, docs, 'Name = "Secretive",\n\t\t\tType = "Function",', 'Name = "Secretive",\n\t\t\tType = "Function",\n\t\t\tSecretReturns = true,')
edit(new_root, docs, '\t\t{\n\t\t\tName = "Removed",\n\t\t\tType = "Function",\n\t\t},\n',
     '\t\t{\n\t\t\tName = "NewFunction",\n\t\t\tType = "Function",\n\t\t},\n')
edit(new_root, docs, '{ Name = "unit", Type = "string", Nilable = false },',
     '{ Name = "unit", Type = "string", Nilable = false },\n\t\t\t\t{ Name = "guid", Type = "WOWGUID", Nilable = true },')
edit(new_root, docs, '\t\t{\n\t\t\tName = "TestGone",\n\t\t\tType = "Event",\n\t\t\tLiteralName = "TEST_GONE",\n\t\t},\n', "")
edit(new_root, docs, '{ Name = "Second", Type = "TestKind", EnumValue = 2 },', '{ Name = "Second", Type = "TestKind", EnumValue = 3 },')
edit(new_root, docs, '\t\t\t\t{ Name = "size", Type = "number", Nilable = false },\n', "")
edit(new_root, "Blizzard_APIDocumentationGenerated/SimpleTestAPIDocumentation.lua", '"thing", Type = "number"', '"thing", Type = "string"')
edit(new_root, docs, 'Documentation = { "Words for people, never compared." },', 'Documentation = { "Other words." },')

new = exports.Export(new_root, build="1.60.2.70000")
check("labels", (old.label, new.label), ("old", "1.60.2.70000"))
changes = compare.changes(old, new)
check("changes: parameters", changes["lua:Test_Params"].notes, ["parameters (a, b) → (a, b, c)"])
check("changes: words only", "lua:Test_Comment" in changes, False)
check("changes: the documentation's words", "api:C_Test.GetThing" in changes and changes["api:C_Test.GetThing"].notes,
      ["argument new: `flags` number"])
check("changes: deprecated", changes["lua:OldFunction"].status, "deprecated")
check("changes: not loaded", [i for i in changes if "Vanilla" in i or "Excluded" in i], [])

# -- what reaches the module ------------------------------------------------------------------------------

module = sane.Uses(FIXTURE / "src", notes=[FIXTURE / "Doc"], root=FIXTURE)
check("uses: no problems", module.problems, [])
check("uses: the local is not a global", [u.name for u in module.of("global") if u.name.startswith("Settings")], [])
check("uses: hooks", sorted((u.name, u.how) for u in module.of("hook")), [("Refresh", "method"), ("Test_Hooked", "function")])
check("uses: own names", {"Mine", "Refresh", "Open"} <= module.own, True)
check("uses: a string's call", next(u.how for u in module.of("string") if u.name == "TEST_EVENT"), "frame:RegisterEvent #1")
check("uses: cites", sorted((u.name, u.how) for u in module.of("cite")), [
    ("Blizzard_Test/Camelot/Game.lua", None), ("Blizzard_Test/Shared/Test.lua", (12, 14)),
    ("Blizzard_Test/Shared/Test.lua", (20, 22)), ("Blizzard_Test/Shared/Test.xml", None)])

analysis = compare.Analysis(old, new, module, [FIXTURE / "src/Test/SaneUI_Test.toc"])
found = {(section, f.id) for section, findings in analysis.by_section().items() for f in findings}
check("findings", sorted(found), sorted({
    ("broken", "api:C_Test.Removed"), ("broken", "event:TEST_GONE"), ("broken", "addon:Blizzard_Gone"),
    ("broken", "name:MENU_TEST_TAG"), ("broken", "name:Box"),
    ("deprecated", "lua:OldFunction"),
    ("changed", "api:C_Test.GetThing"), ("changed", "api:C_Test.Secretive"), ("changed", "api:C_Test.GetInfo"),
    ("changed", "event:TEST_EVENT"), ("changed", "enum:Enum.TestKind.Second"), ("changed", "lua:Test_Params"),
    ("changed", "xml:TestButtonTemplate"), ("changed", "lua:TestMixin:Refresh"),
    ("changed", "widget:SimpleTestAPI:SetThing"),
    ("review", "lua:Test_Hooked"), ("review", "lua:FamilyFunc"), ("review", "lua:TEST_CONSTANT"),
    ("review", "name:test-atlas-old"),
    ("housekeeping", "interface"), ("housekeeping", "cite:Blizzard_Test/Shared/Test.lua:(12, 14)"),
    ("housekeeping", "cite:Blizzard_Test/Shared/Test.lua:(20, 22)"),
    ("housekeeping", "cite:Blizzard_Test/Shared/Test.xml:None")}))
by_id = {f.id: f for findings in analysis.by_section().values() for f in findings}
check("a name gone: a close new one", by_id["name:MENU_TEST_TAG"].hints, ["`MENU_TEST_TAG_NEW`"])
check("an atlas gone: a close new one", by_id["name:test-atlas-old"].hints, ["`test-atlas-new`"])
check("deprecated: what stands in", by_id["lua:OldFunction"].hints, ["`C_Test.NewFunction`"])
check("deprecated: where", by_id["lua:OldFunction"].notes[0], "now only in AddOns/Blizzard_DeprecatedTest/Deprecated.lua")
check("hooked: its diff", "+\tframe:Raise();" in (by_id["lua:Test_Hooked"].diff or []), True)
check("hooked: said so", by_id["lua:Test_Hooked"].notes[0], "hooked by Sane UI")
check("hooked method: its diff", any(line.startswith("+function TestMixin:Refresh(force, again)")
                                     for line in by_id["lua:TestMixin:Refresh"].diff or []), True)
check("secret values", by_id["api:C_Test.Secretive"].notes, ["flag SecretReturns: (none) → True"])
check("a structure an API returns", by_id["api:C_Test.GetInfo"].notes, ["TestInfo changed: field gone: `size`"])
check("an event's payload", by_id["event:TEST_EVENT"].notes, ["payload new: `guid` WOWGUID"])
check("an enum's value", by_id["enum:Enum.TestKind.Second"].notes, ["value: 2 → 3"])
check("a template's keys", by_id["xml:TestButtonTemplate"].notes, ["keys gone: Box (Frame)"])
check("a template: every use", sorted(u.where() for u in by_id["xml:TestButtonTemplate"].uses),
      ["src/Test/Test.lua:6", "src/Test/Test.xml:2"])
check("a removed API's uses", [u.where() for u in by_id["api:C_Test.Removed"].uses], ["src/Test/Test.lua:13"])
check("the Interface number", by_id["interface"].notes,
      ["`## Interface: 16002` for build 1.60.2.70000", "src/Test/SaneUI_Test.toc has 16001"])
check("a cite: changed lines", by_id["cite:Blizzard_Test/Shared/Test.lua:(12, 14)"].notes, ["lines 12-14 changed"])
check("new API", analysis.new_api(), ["C_Test.NewFunction"])

# A cited block that only moved down says where it is now.
moved = compare.find_block(["a", "b"], ["x", "a", "b", "y"])
check("a moved block", moved, 2)
check("a block that is twice there", compare.find_block(["a"], ["a", "a"]), None)

# -- the todo list ----------------------------------------------------------------------------------------

with tempfile.TemporaryDirectory() as out:
    path = Path(out) / "reports" / "todo.md"
    report.markdown(analysis, path, FIXTURE, "the-game-folder")
    report.as_json(analysis, path.with_suffix(".json"))
    text = path.read_text()
    check("todo: a box per finding", text.count("- [ ] "), len(found) + 1)
    check("todo: broken first", text.index("## Broken") < text.index("## Deprecated") < text.index("## Changed")
          < text.index("## Review") < text.index("## Housekeeping"), True)
    check("todo: an item", "- [ ] `C_Test.Removed` (API function): gone from the new export." in text, True)
    check("todo: links to the source", "(" in text and "src/Test/Test.lua#L13)" in text, True)
    adopt = "- [ ] Take the new export in: `dev/tools/blizzard adopt the-game-folder`"
    check("todo: adopt last", text.index(adopt) > text.index("Notes citing") and "- [ ]" not in text[text.index(adopt) + 5:], True)
    data = json.loads(path.with_suffix(".json").read_text())
    check("json: findings", len(data["findings"]), len(found))
    check("json: a finding", next(f for f in data["findings"] if f["id"] == "event:TEST_GONE")["uses"],
          ["src/Test/Test.lua:8 (frame:RegisterEvent #1)"])

scratch.cleanup()

# -- Sane UI's own source reads without problems ------------------------------------------------------------

real = sane.Uses(ROOT / "src", notes=[ROOT / "Doc"], root=ROOT)
check("Sane UI's source: luac reads it", real.problems, [])
check("Sane UI's source: globals found", len(real.of("global")) > 100, True)

print(f"blizzard: {checks_run} checks, {failed} failed")
sys.exit(1 if failed else 0)
