"""dev/tools/fresh-install: a new player's first Sane UI in both games, the real WTF and Interface set aside whole and
put back as they were; nothing deleted that is not the test's; nothing done while a game runs.
Run by dev/tests/run."""
import hashlib
import importlib.machinery
import importlib.util
import io
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader("fresh_install", str(ROOT / "dev/tools/fresh-install"))
tool = importlib.util.module_from_spec(importlib.util.spec_from_loader("fresh_install", loader))
loader.exec_module(tool)
failed, passed = [], 0


def check(ok, what):
    global passed
    if ok:
        passed += 1
    else:
        failed.append(what)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8") if isinstance(text, str) else text)


def tree(folder):
    """Every file of a folder with its bytes' hash: the same before and after means put back as it was."""
    return {str(p.relative_to(folder)): hashlib.sha1(p.read_bytes()).hexdigest() for p in sorted(folder.rglob("*")) if p.is_file()}


def game(root, name, product):
    folder = root / name
    write(folder / ".flavor.info", f"Product Flavor!STRING:0\r\n{product}\r\n")
    wtf = folder / "WTF"
    write(wtf / "Config.wtf", 'SET Sound_MasterVolume "0.05"\r\nSET synchronizeConfig "1"\r\nSET portal "EU"\r\n')
    write(wtf / "SavedVariables/Blizzard_Console.lua", "-- the game's\r\n")
    account = wtf / "Account/1#1"
    write(account / "config-cache.wtf", 'SET nameplateStyle "4"\r\n')
    write(account / "bindings-cache.wtf", "bind Q MOVEFORWARD\r\nbind E CLICK SaneUISpeedLevelingFind:LeftButton\r\n"
                                          "bind F SANEUI_MAP_FIND\r\nbind W STRAFELEFT\r\n")
    write(account / "macros-cache.txt", 'VER 3 0000000000000001 "Hi" "1"\r\n/wave\r\nEND\r\n')
    write(account / "SavedVariables/SaneUI.lua", "SaneUIDB = { mine = true }\r\n")
    write(account / "SavedVariables/OtherAddon.lua", "OtherDB = {}\r\n")
    write(account / "SavedVariables/Blizzard_ClassTalentUI.lua", "-- the game's\r\n")
    character = account / "93/Sane-Lunatic"
    write(character / "AddOns.txt", "SaneUI: enabled\r\nOtherAddon: enabled\r\n")
    write(character / "layout-local.txt", "Version: 1\r\n")
    write(character / "edit-mode-cache-character.txt", "2 2 2 2 2 2\r\n")
    write(character / "SavedVariables/SaneUI.lua", "SaneUICharDB = {}\r\n")
    addons = folder / "Interface/AddOns"
    write(addons / "SaneUI/SaneUI.toc", "## Interface: 11506\n## Version: 0.3.1\n")
    write(addons / "SaneUI/Core.lua", "-- core\n")
    write(addons / "SaneUI_Navigation/SaneUI_Navigation.toc", "## Interface: 11506\n")
    write(addons / "OtherAddon/OtherAddon.toc", "## Interface: 11506\n")
    write(addons / "SaneUI_AuctionDatabase/SaneUI_AuctionDatabase.toc", "## X-SaneUI-Made: 1\n")
    return folder


def quiet(fn, *args, **kwargs):
    said = []
    fn(*args, say=said.append, **kwargs)
    return "\n".join(said)


def refused(fn, *args, **kwargs):
    try:
        quiet(fn, *args, **kwargs)
    except tool.Refused as error:
        return str(error)
    return None


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    forever, retail = game(root, "_forever_", "wowf"), game(root, "_retail_", "wow")
    tool.FOREVER, tool.RETAIL = forever, retail
    runs = set()
    tool.running = lambda folder: folder.name in runs
    before = {folder: (tree(folder / "WTF"), tree(folder / "Interface")) for folder in (forever, retail)}

    # A game running: nothing happens in either game.
    runs.add("_retail_")
    why = refused(tool.start, [], False)
    check(why and "Retail's game runs" in why, "a running Retail stops the start")
    check(not (forever / tool.HOLD).exists() and (forever / "WTF/Account").is_dir(), "  and Forever is left as it is too")
    runs.clear()

    # A dry run changes nothing.
    said = quiet(tool.start, [], True)
    check("would set WTF and Interface aside" in said and "2 Sane UI keys taken off" in said, "dry: says what it would do")
    check(not (forever / tool.HOLD).exists() and tree(forever / "WTF") == before[forever][0], "  and does nothing")

    # The start.
    said = quiet(tool.start, [], False)
    for folder in (forever, retail):
        hold, wtf, addons = folder / tool.HOLD, folder / "WTF", folder / "Interface/AddOns"
        check(tree(hold / "WTF") == before[folder][0] and tree(hold / "Interface") == before[folder][1],
              f"{folder.name}: the real WTF and Interface set aside whole, unchanged")
        check((wtf / tool.MARK).is_file() and (folder / "Interface" / tool.MARK).is_file(), f"{folder.name}: the test's folders marked")
        config = (wtf / "Config.wtf").read_bytes()
        check(config.count(b'SET synchronizeConfig "0"\r\n') == 1 and b'synchronizeConfig "1"' not in config
              and b'SET synchronizeBindings "0"\r\n' in config and b'SET synchronizeChatFrames "0"\r\n' in config
              and b'SET portal "EU"\r\n' in config, f"{folder.name}: Config.wtf kept, the game's syncing off, CRLF")
        keys = (wtf / "Account/1#1/bindings-cache.wtf").read_bytes()
        check(keys == b"bind Q MOVEFORWARD\r\nbind W STRAFELEFT\r\n", f"{folder.name}: the player's keys kept, Sane UI's taken off")
        saved = sorted(str(p.relative_to(wtf)) for p in wtf.rglob("SavedVariables/*"))
        check(saved == ["Account/1#1/SavedVariables/Blizzard_ClassTalentUI.lua", "SavedVariables/Blizzard_Console.lua"],
              f"{folder.name}: no addon's saved files, Blizzard's kept: {saved}")
        check(not list(wtf.rglob("AddOns.txt")), f"{folder.name}: no addon list, so the game turns Sane UI on")
        check((wtf / "Account/1#1/93/Sane-Lunatic/layout-local.txt").is_file()
              and (wtf / "Account/1#1/macros-cache.txt").read_bytes() == (hold / "WTF/Account/1#1/macros-cache.txt").read_bytes(),
              f"{folder.name}: the characters and the game's own files kept")
        check(sorted(p.name for p in addons.iterdir()) == ["SaneUI", "SaneUI_Navigation"],
              f"{folder.name}: AddOns holds Sane UI's alone, no tool-made one")
        check((addons / "SaneUI/Core.lua").read_text() == "-- core\n", f"{folder.name}: Sane UI as the game had it installed")
    check("SaneUI, SaneUI_Navigation" in said and "saneui myinstall" in said, "the start says what went in and the way back")
    check("a fresh-install test since" in quiet(tool.status), "status: a test is on")

    why = refused(tool.start, [], False)
    check(why and "test is on" in why, "a second start is refused while a test is on")

    # The game plays the test: Sane UI saves, a key is bound, the test's own files change.
    write(forever / "WTF/Account/1#1/SavedVariables/SaneUI.lua", "SaneUIDB = { fresh = true }\r\n")
    write(forever / "WTF/Account/1#1/bindings-cache.wtf", "bind Q MOVEFORWARD\r\nbind E CLICK SaneUISpeedLevelingFind:LeftButton\r\n")
    write(forever / "Interface/AddOns/SaneUI/New.lua", "-- installdev into the test\n")

    # A running game stops the restore; so does a folder that is not the test's, and nothing is deleted.
    runs.add("_forever_")
    check("Forever's game runs" in (refused(tool.restore, False) or ""), "a running Forever stops the restore")
    runs.clear()
    (retail / "WTF" / tool.MARK).unlink()
    why = refused(tool.restore, False)
    check(why and "no mark of the test" in why, "a WTF without the test's mark stops the restore")
    check((forever / "WTF" / tool.MARK).is_file() and (forever / tool.HOLD / "WTF").is_dir(), "  and nothing was deleted or moved")
    write(retail / "WTF" / tool.MARK, "back\n")

    said = quiet(tool.restore, True)
    check("would delete the test's WTF, put your WTF back" in said and (forever / "WTF" / tool.MARK).is_file(), "dry restore: says, does nothing")

    said = quiet(tool.restore, False)
    for folder in (forever, retail):
        check(tree(folder / "WTF") == before[folder][0] and tree(folder / "Interface") == before[folder][1],
              f"{folder.name}: the real WTF and Interface back, byte for byte")
        check(not (folder / tool.HOLD).exists(), f"{folder.name}: the holding folder gone")
    check("Account/1#1/bindings-cache.wtf (key bindings)" in said and "Retail: the test changed" not in said,
          "the restore names the game's own files the test changed")
    check("your own setup (no fresh-install test)" in quiet(tool.status), "status: no test")
    check("no fresh-install test here" in quiet(tool.restore, False), "a restore without a test changes nothing")
    tool.RETAIL = root / "_gone_"
    check("Retail: no fresh-install test here" in quiet(tool.restore, False), "a game folder gone does not stop the way back")
    tool.RETAIL = retail

    # The zips of a channel instead of the installed build; a zip reaching outside AddOns is refused first.
    package = root / "SaneUI-0.3.1-alpha.zip"
    with zipfile.ZipFile(package, "w") as archive:
        archive.writestr("SaneUI/SaneUI.toc", "## Interface: 11506\n## Version: 0.3.1\n")
        archive.writestr("SaneUI_Navigation/SaneUI_Navigation.toc", "## Interface: 11506\n")
    evil = root / "evil.zip"
    with zipfile.ZipFile(evil, "w") as archive:
        archive.writestr("../../WTF/Config.wtf", "x")
    why = refused(tool.start, [str(package), str(evil)], False)
    check(why and "would land outside AddOns" in why and not (forever / tool.HOLD).exists(), "a zip reaching outside: refused, nothing done")
    said = quiet(tool.start, [str(package)], False)
    check(sorted(p.name for p in (forever / "Interface/AddOns").iterdir()) == ["SaneUI", "SaneUI_Navigation"]
          and not (forever / "Interface/AddOns/SaneUI/Core.lua").exists(), "--zip: the zips' addons, not the installed build")
    check("out of date" in said, "--zip: says Retail sees Forever's interface number")
    quiet(tool.restore, False)
    check(tree(forever / "Interface") == before[forever][1], "  and the restore brings the real Interface back")

    # A failure half way puts back what was set aside, in both games.
    made = tool.fresh_interface

    def breaks(real, test, zips):
        if test.parent.name == "_retail_":
            raise OSError("disk full")
        return made(real, test, zips)
    tool.fresh_interface = breaks
    try:
        quiet(tool.start, [], False)
        check(False, "a failure half way is raised")
    except OSError:
        pass
    tool.fresh_interface = made
    for folder in (forever, retail):
        check(tree(folder / "WTF") == before[folder][0] and tree(folder / "Interface") == before[folder][1]
              and not (folder / tool.HOLD).exists(), f"{folder.name}: after a failure half way, all put back")

    # The game's process seen by its folder's name, under Wine a Windows path.
    check(tool.running(root / "_no_such_game_") is False, "no client of an unknown folder runs")

if failed:
    print("Fresh install, FAILED:", *failed, sep="\n  ")
    sys.exit(1)
print(f"Fresh install: all {passed} checks passed.")
