"""dev/tools/auction-database: the addon of links to every account's auction data, and that they stay good."""
import importlib.machinery
import importlib.util
import os
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader("auction_database", str(ROOT / "dev/tools/auction-database"))
tool = importlib.util.module_from_spec(importlib.util.spec_from_loader("auction_database", loader))
loader.exec_module(tool)
failed, passed = [], 0


def check(ok, what):
    global passed
    if ok:
        passed += 1
    else:
        failed.append(what)


with tempfile.TemporaryDirectory() as temporary:
    folder = Path(temporary) / "_forever_"
    (folder / "Interface/AddOns/SaneUI").mkdir(parents=True)
    (folder / "Interface/AddOns/SaneUI/SaneUI.toc").write_text("## Interface: 16001, 120105\n## Version: 0.3.0\n", encoding="utf-8")
    saved = [folder / f"WTF/Account/1#{each}/SavedVariables" for each in (1, 2, 3)]
    for each in saved:
        each.mkdir(parents=True)
    (folder / "WTF/Account/SavedVariables").mkdir()
    (saved[0] / tool.SAVED).write_text("-- one\n", encoding="utf-8")
    check(tool.accounts(folder) == ["1#1", "1#2", "1#3"], "the accounts, not the game's own folder beside them")
    check(tool.link(folder) == 3, "a link per account")
    addon = folder / "Interface/AddOns" / tool.ADDON
    toc = (addon / f"{tool.ADDON}.toc").read_text(encoding="utf-8")
    check("## Interface: 16001, 120105" in toc and "## X-SaneUI-Made: 1" in toc and "## Dependencies: SaneUI" in toc, "its TOC: the game's number as Core's, made here")
    check(toc.index("Account1.lua") < toc.index("Take1.lua") < toc.index("Account2.lua"), "each link read, then handed to Core, before the next")
    check((addon / "Account1.lua").read_text(encoding="utf-8") == "-- one\n", "a link reads the account's own file")
    check((addon / "Take3.lua").read_text(encoding="utf-8") == tool.TAKE, "what hands it to Core")
    # The game's way of saving: a new file in the old one's place. The link follows the name.
    fresh = saved[0] / "new"
    fresh.write_text("-- one, later\n", encoding="utf-8")
    os.replace(fresh, saved[0] / tool.SAVED)
    check((addon / "Account1.lua").read_text(encoding="utf-8") == "-- one, later\n", "a new save of the account: the link reads it")
    (saved[2] / tool.SAVED).write_text("-- three\n", encoding="utf-8")
    check((addon / "Account3.lua").read_text(encoding="utf-8") == "-- three\n", "an account's first save: its link, made before, reads it")
    check(os.readlink(addon / "Account1.lua").startswith("../../../WTF/"), "by a path within the game folder: all the game can see")
    (saved[1] / tool.SAVED).write_text("-- two\n", encoding="utf-8")
    check(tool.link(folder) == 3 and (saved[1] / tool.SAVED).read_text(encoding="utf-8") == "-- two\n", "made again: the accounts' own files never touched")
    check(tool.link(Path(temporary) / "_nothing_") is None, "a game folder without Sane UI: nothing")

if failed:
    print("Auction database, FAILED:", *failed, sep="\n  ")
    sys.exit(1)
print(f"Auction database: all {passed} checks passed.")
