"""dev/tools/auction-database: the accounts' files read as the game writes them, what they hold together, the addon."""
import importlib.machinery
import importlib.util
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


def saved(index, days, kept, whole="ZZZ", recent=None):
    """An account's saved file as the game writes it: a table on its own lines, tabs and all."""
    lines = ["", "SaneUIData_Market = {", '["forever"] = {', '["format"] = 1,', '["houses"] = {', '["eu/1234/alliance"] = {',
             '["days"] = {'] + [f'[{day}] = "{text}",' for day, text in days.items()] + ["},",
             '["recent"] = {'] + [f'[{at}] = "{text}",' for at, text in (recent or {}).items()] + ["},", '["scans"] = {', "},",
             '["whole"] = {', f'[{kept}] = "70532\\n{whole}",', "},", f'["index"] = "{index}",', f'["kept"] = {kept},', "},",
             "},", "},", '["retail"] = {', '["houses"] = {', '["eu/1234/alliance"] = {', '["index"] = "9=1,1,1,1,1,1;",',
             '["days"] = {', "},", '["scans"] = {', "},", "},", "},", "},", "}", ""]
    return "\n\t".join(lines)


with tempfile.TemporaryDirectory() as temporary:
    folder = Path(temporary) / "_forever_"
    (folder / "Interface/AddOns/SaneUI").mkdir(parents=True)
    (folder / "Interface/AddOns/SaneUI/SaneUI.toc").write_text("## Interface: 16001, 120105\n## Version: 0.3.0\n", encoding="utf-8")
    one, two = (folder / f"WTF/Account/1#{each}/SavedVariables" for each in (1, 2))
    one.mkdir(parents=True)
    two.mkdir(parents=True)
    (one / "SaneUI_AuctionData.lua").write_text(saved("10=100,50,60,5,2,1;20=100,70,70,1,1,1;", {20000: "10=50,60,5,2,1;20=70,70,1,1,1;"}, 100,
                                                      recent={20000 * tool.DAY + 5: "10=50,60;", 19999 * tool.DAY: "10=7,7;"}), encoding="utf-8")
    (two / "SaneUI_AuctionData.lua").write_text(saved("10=200,80,90,3,1,1;30=200,9,9,1,1,1;", {20000: "10=80,90,3,1,1;30=9,9,1,1,1;",
                                                                                               19999: "10=7,7,1,1,1;"}, 200,
                                                      recent={20000 * tool.DAY + 9: "10=80,90;", 19998 * tool.DAY: "10=1,1;"}), encoding="utf-8")
    houses = tool.read_houses(one / "SaneUI_AuctionData.lua", "forever")
    check(list(houses) == ["eu/1234/alliance"] and houses["eu/1234/alliance"]["kept"] == 100
          and houses["eu/1234/alliance"]["days"] == {20000: "10=50,60,5,2,1;20=70,70,1,1,1;"}, f"a file read: {houses}")
    check("ZZZ" not in str(houses), "the whole scans passed over")
    check(houses["eu/1234/alliance"]["recent"][20000 * tool.DAY + 5] == "10=50,60;", "the scans as a line per item read")
    check(tool.read_houses(one / "SaneUI_AuctionData.lua", "retail")["eu/1234/alliance"]["index"] == "9=1,1,1,1,1,1;", "another game version's part stays its own")
    done = tool.make(folder, "forever")
    check(done == (2, 1, True), f"two accounts, one house: {done}")
    made = folder / "Interface/AddOns" / tool.ADDON
    lua = (made / "Prices.lua").read_text(encoding="utf-8")
    toc = (made / f"{tool.ADDON}.toc").read_text(encoding="utf-8")
    check('.Database("forever", {' in lua and '["eu/1234/alliance"]' in lua, "handed to Core for its game")
    check('index = "10=200,80,90,3,1,1;20=100,70,70,1,1,1;30=200,9,9,1,1,1;"' in lua, f"each item's newest point of any account: {lua}")
    check('[20000] = "10=50,90,3,1,1;20=70,70,1,1,1;30=9,9,1,1,1;"' in lua, "a day: the lowest of any account, the rest of the last to scan")
    check('[19999] = "10=7,7,1,1,1;"' in lua, "a day only one account has")
    check(f'[{20000 * tool.DAY + 5}] = "10=50,60;"' in lua and f'[{20000 * tool.DAY + 9}] = "10=80,90;"' in lua
          and f'[{19999 * tool.DAY}] = "10=7,7;"' in lua, "every account's scans of the last two days, for a graph of a day")
    check(f'[{19998 * tool.DAY}]' not in lua, "older scans not: the day of the newest scan counts, not the computer's clock")
    check("ZZZ" not in lua and "whole" not in lua, "daily only: the whole scans stay in each account's file")
    check("## Interface: 16001, 120105" in toc and "## X-SaneUI-Made: 1" in toc and "Prices.lua" in toc and "## Dependencies: SaneUI" in toc,
          "its TOC: the game's number as Core's, made here, its one file from the start")
    check(tool.make(folder, "forever")[2] is False, "nothing new: nothing written")
    before = (one / "SaneUI_AuctionData.lua").read_bytes()
    check((one / "SaneUI_AuctionData.lua").read_bytes() == before, "the accounts' own files are only read")
    (one / "SaneUI_AuctionData.lua").write_text(saved('10=300,40,60,5,2,1;', {20000: "10=40,60,5,2,1;"}, 300), encoding="utf-8")
    check(tool.make(folder, "forever")[2] is True and 'index = "10=300,40,60,5,2,1;' in (made / "Prices.lua").read_text(encoding="utf-8"),
          "a new scan on one account: made anew, the other account sees it")
    (one / "SaneUI_AuctionData.lua").write_text(saved("", {}, 0)[:60], encoding="utf-8")
    check(tool.make(folder, "forever") is not None, "a file cut off while the game writes it does no harm")
    check(tool.make(Path(temporary) / "_nothing_", "forever") is None, "a game folder without Sane UI: nothing")

if failed:
    print("Auction database, FAILED:", *failed, sep="\n  ")
    sys.exit(1)
print(f"Auction database: all {passed} checks passed.")
