"""The interface lab (dev/tools/ui-lab, Doc/guides/ui-lab.md): every scene runs without an error for two seconds and
draws something, and a few of the lab's rules hold: anchors resolve as the game resolves them, an unknown event is an
error, a script the kind does not have is an error, what the game has but the lab does not do is told. The XML reader
on a file of the test's own (dev/tests/uilab/), Blizzard's templates, and SaneUI's Core from its TOC with its window.
The page's calls: a font only from the fonts' places, a texture with its mark and 304 to it; a host that answers nothing
killed after its time, and started anew by the next call.
Needs the newest export of Blizzard's interface (dev/tools/blizzard where); without it, it says so and passes."""
import importlib.machinery
import importlib.util
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "dev/blizzard"))
import export as exports  # noqa: E402
CODE = exports.newest("code")
if not (CODE and (CODE / "Interface/AddOns/Blizzard_APIDocumentationGenerated").is_dir()):
    print("uilab.py: no export of Blizzard's interface on this computer (dev/tools/blizzard where), the lab is not tested")
    sys.exit(0)

loader = importlib.machinery.SourceFileLoader("uilab", str(ROOT / "dev/tools/ui-lab"))
spec = importlib.util.spec_from_loader("uilab", loader)
lab = importlib.util.module_from_spec(spec)
loader.exec_module(lab)
failed = []


def expect(ok, what):
    if not ok:
        failed.append(what)


def errors(messages):
    return [m for m in messages if m.get("kind") == "error"]


# Every scene: no error, something drawn.
for scene in sorted((ROOT / "dev/uilab/scenes").glob("*.lua")):
    host = lab.Host()
    host.scene = str(scene.relative_to(ROOT))
    host.saved_file = lambda: Path("/nonexistent/none.json")
    r = host.start()
    told, drawn = list(r.get("messages") or []), sum(1 for v in r["changes"].values() if v is not None)
    for _ in range(60):
        r = host.call({"op": "frame", "dt": 1 / 30, "input": []})
        told += r.get("messages") or []
        drawn += sum(1 for v in r["changes"].values() if v is not None)
    host.stop(keep=False)
    for e in errors(told):
        failed.append(f"{scene.name}: {e['text']}")
    expect(drawn > 0, f"{scene.name}: nothing drawn")

# The lab's rules, through its console.
def started(scene):
    h = lab.Host()
    h.scene = scene
    h.saved_file = lambda: Path("/nonexistent/none.json")
    r = h.start()
    for _ in range(10):
        r = h.call({"op": "frame", "dt": 1 / 30, "input": []})
    return h


host = started(None)


def run(code):
    r = host.call({"op": "run", "code": code})
    return r.get("messages") or []


def result(code):
    told = run(code)
    out = [m["text"] for m in told if m.get("kind") == "result"]
    expect(not errors(told), f"{code}: {[e['text'] for e in errors(told)]}")
    return out[0] if out else None


run('f = CreateFrame("Frame", nil, UIParent); f:SetSize(100, 50); f:SetPoint("TOPLEFT", 10, -20)')
run('g = CreateFrame("Frame", nil, f); g:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 5, 0); g:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT")')
expect(result("f:GetWidth()") == "100", "a size set is the size")
expect(result("g:GetLeft()") == "15", "an anchor's offset counts from the point it is anchored to")
expect(result("g:GetWidth() == GetScreenWidth() - 15") == "true", "two anchors on a side give the width")
run('fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal"); fs:SetPoint("LEFT"); fs:SetText("Sane")')
expect(float(result("fs:GetStringWidth()") or 0) > 0, "a text is measured")
told = run('f:RegisterEvent("NO_SUCH_EVENT")')
expect(any("unknown event" in m["text"] for m in errors(told)), "an unknown event is an error")
told = run('f:SetScript("OnClick", print)')
expect(any("doesn't have" in m["text"] for m in errors(told)), "a script a frame does not have is an error")
told = run('f:SetWindow(nil); f:CreateVectorGraphics()')
expect(any(m.get("kind") == "missing" for m in told), "what the game has but the lab does not do is told")
expect(result('(GetItemInfo(19019))') is not None, "items come from the data master")
told = run('f:SetScript("ONENTER", print); f:SetScript("OnEnter", nil)')
expect(not errors(told), "a script's name in any case, as the game takes it")
expect(result('#C_EditMode.GetLayouts().layouts') == "0", "Edit Mode's layouts as the client keeps them")
told = run('C_DoesNotExist.Anything()')
expect(any("C_DoesNotExist" in e["text"] for e in errors(told)), "a namespace the game has not is nil")
told = run('C_PetJournal.GetSearchFilter()')
expect(any(m.get("kind") == "missing" and "C_PetJournal.GetSearchFilter" in m["text"] for m in told),
       "a documented function the lab does not do is there and told")

# Blizzard's templates, from its own XML.
expect(result('local b = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate"); b:SetText("Go"); '
              'return b.Left ~= nil and b:GetFontString() == b.Text and b:GetText()') == '"Go"',
       "UIPanelButtonTemplate: its parts by their keys, its text in its font string")
expect(result('local t = CreateFrame("Frame", nil, UIParent, "TabSystemTemplate"); t:AddTab("One"); '
              't:AddTab("Two"); return #t.tabs, t:GetTabButton(2):GetText()') == '2, "Two"', "TabSystemTemplate makes tabs")
expect(result('local d = CreateFrame("DropdownButton", nil, UIParent, "WowStyle1DropdownTemplate"); '
              'return d:GetObjectType(), type(d.SetupMenu)') == '"Button", "function"', "an intrinsic kind (DropdownButton)")
expect(result('C_XMLUtil.GetTemplateInfo("UIPanelButtonTemplate").type') == '"Button"', "C_XMLUtil tells a template")
host.stop(keep=False)

# The XML reader on the test's own file (dev/tests/uilab/xml.xml): Include, Script file, templates, keys, anchors.
host = started("dev/tests/uilab/xml.lua")
expect(result('table.concat(LabTestOrder, " ")') == '"first second parent"', "OnLoad: children first, in order")
expect(result('#LabTestParent.Things, LabTestParent.bag, LabTestParentSecond == LabTestParent.Second') == "2, 4, true",
       "parentArray from a template, a dotted global KeyValue, $parent in a name")
expect(result('LabTestParent.First:GetLeft() - LabTestParent:GetLeft(), '
              'LabTestParent:GetTop() - LabTestParent.First:GetTop()') == "5, 30",
       "an anchor to a part made after it (relativeKey), and the template's size")
expect(result('LabTestParent.Words:GetText(), LabTestParent.Words:GetDrawLayer()') == '"Close", "OVERLAY", 2',
       "a text attribute as a global string, the layer and its sublevel")
expect(result('CreateFrame("LabTestIntrinsic", nil, UIParent, "LabTestBaseTemplate"); '
              'return LabTestIntrinsicRan, LabTestOrder[#LabTestOrder]') == '1, "?"',
       "an intrinsic's OnLoad runs with a template's")
host.stop(keep=False)

# Scenes' windows: the XML one, and Core's own from its TOC.
host = started("dev/uilab/scenes/xml-templates.lua")
expect(result('LabXMLWindow.Tabs:GetTabButton(1):GetText(), #LabXMLWindow.Pages, LabXMLWindow.Pages[2].Bar:GetValue()')
       == '"Buttons", 2, 20', "the XML window's tabs, pages and bar")
told = run('LabXMLWindow.Pages[1].Okay:Click()')
expect(any(m.get("kind") == "print" and "Okay was clicked" in m["text"] for m in told), "an inline script runs")
host.stop(keep=False)
host = started("dev/uilab/scenes/core.lua")
expect(result('SaneUI.Core.VERSION ~= nil and SaneUI.Core.Window ~= nil') == "true", "Core loads from its TOC")
expect(result('C_XMLUtil.GetTemplateInfo("SaneUISettingsCVarRowTemplate").height') == "34", "Core's own XML templates")
told = run('/sane options')
expect(not errors(told), f"Core's options open: {[e['text'] for e in errors(told)]}")
expect(result('SettingsPanel:IsShown()') == "true", "the game's settings panel shows Core's options")
host.stop(keep=False)

# A host that answers nothing (an endless loop from the console) is killed after its time, the page told, and the
# next call starts it anew.
host = started(None)
lab.TIMEOUT, patience = 2, lab.TIMEOUT
t0 = lab.time.time()
told = run("while true do end")
lab.TIMEOUT = patience
expect(any("the lab's host stopped" in e["text"] and "no answer in 2 s" in e["text"] for e in errors(told)),
       f"an endless loop ends the host, with the reason: {[e['text'] for e in errors(told)]}")
expect(lab.time.time() - t0 < 10, "the page waits no longer than the limit")
expect(host.proc is None, "the host is gone")
r = host.call({"op": "frame", "dt": 1 / 30, "input": []})
expect(host.proc is not None and r.get("reset"), "the next call starts the host anew")
host.stop(keep=False)


# The page's calls, without the server: /font sends only fonts from their places, /tex marks a picture and answers
# 304 to its mark.
class Ask:
    def __init__(self, path, query=None, headers=None):
        self.method, self.path, self.query, self.headers, self.body = "GET", path, query or {}, headers or {}, b""


lab.HOST.watched = True   # these calls start no watch thread
code = lambda *a: lab.web(Ask(*a))[0]  # noqa: E731
expect(code("/font", {"p": ["/etc/hostname"]}) == 404, "a file by its path alone is no font")
expect(code("/font", {"p": [str(ROOT / "dev/tools/ui-lab")]}) == 404, "nor a file of the project")
stray = Path(tempfile.mkdtemp(prefix="uilab-")) / "stray.ttf"
stray.write_bytes(b"not a font")
expect(code("/font", {"p": [str(stray)]}) == 404, "a .ttf outside the fonts' places is not sent")
system = next((f for f in lab.FALLBACK_FONT if Path(f).is_file()), None)
if system:
    expect(code("/font", {"p": [system]}) == 200, "a system font is sent")
ours = next(iter(sorted((ROOT / "assets/optimized").glob("*/Fonts/*.ttf"))), None)
if ours:
    expect(code("/font", {"p": [str(ours)]}) == 200, "a module's font is sent")
tex = "Interface\\AddOns\\SaneUI\\Art\\corner-tl"
status, kind, body, held = lab.web(Ask("/tex", {"p": [tex]}))
expect(status == 200 and body[:4] == b"\x89PNG" and held.get("ETag") and held.get("Cache-Control") == "no-cache",
       f"a texture comes with its mark: {status} {held}")
expect(lab.web(Ask("/tex", {"p": [tex]}, {"If-None-Match": held.get("ETag")}))[0] == 304, "the same mark: 304, nothing sent")
expect(lab.web(Ask("/tex", {"p": [tex]}, {"If-None-Match": '"other"'}))[0] == 200, "another mark: the picture")

# The server runs all the time: a game no page asks for goes (web(), watch()).
class Quiet:
    def kill(self):
        Quiet.killed = True


class Stop(Exception):
    pass


rests = []


def rest(_):
    rests.append(1)
    if len(rests) > 1:
        raise Stop


lab.HOST.proc, lab.HOST.asked, sleep = Quiet(), 0, lab.time.sleep
lab.time.sleep = rest
try:
    lab.watch()
except Stop:
    pass
lab.time.sleep = sleep
if lab.HOST.proc is not None or not getattr(Quiet, "killed", False):
    failed.append("a game no page asks for stops")

if failed:
    print("uilab.py failed:\n  " + "\n  ".join(failed))
    sys.exit(1)
print("uilab.py: every scene runs, the lab's rules hold, XML and Core load")
