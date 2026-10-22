"""The interface lab (dev/tools/ui-lab, Doc/guides/ui-lab.md): every scene runs without an error for two seconds and
draws something, and a few of the lab's rules hold: anchors resolve as the game resolves them, an unknown event is an
error, a script the kind does not have is an error, what the game has but the lab does not do is told.
Needs Blizzard's interface export in references/ (the API documentation); without it, it says so and passes."""
import importlib.machinery
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if not (ROOT / "references/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated").is_dir():
    print("uilab.py: no Blizzard interface export in references/, the lab is not tested")
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
host = lab.Host()
host.scene = None
host.saved_file = lambda: Path("/nonexistent/none.json")
host.start()


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
host.stop(keep=False)

if failed:
    print("uilab.py failed:\n  " + "\n  ".join(failed))
    sys.exit(1)
print("uilab.py: every scene runs, the lab's rules hold")
