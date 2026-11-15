"""dev/tools/release: the modules' stages, a channel's package (the newest version at that stage or higher, Core from
main's newest commit, Forever's interface alone) and its upload to CurseForge, on a small repository of its own."""
import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader("release_tool", str(ROOT / "dev/tools/release"))
tool = importlib.util.module_from_spec(importlib.util.spec_from_loader("release_tool", loader))
loader.exec_module(tool)
failed, passed = [], 0
quiet = lambda *_: None


def check(ok, what):
    global passed
    if ok:
        passed += 1
    else:
        failed.append(what)


def refused(step):
    try:
        step()
    except tool.Refused as why:
        return str(why)
    return None


TOC = """## Interface: 16001, 120105
## Title: {title}
## Version: 0.3.0
{extra}
{title}.lua
"""

# Every module of the real project has its tests named, and they are there.
real = tool.staged(tool.main_commit())
check(set(real) <= set(tool.TESTS), f"every module's tests are named in TESTS: {sorted(set(real) - set(tool.TESTS))}")
check(all((ROOT / f"dev/tests/{t}.lua").is_file() for m in real for t in tool.TESTS.get(m, [])), "each named test is there")
check("Core" not in real and "AuctionData" not in real and "AuctionScans" not in real, "Core's parts have no stage")

for name in ("GIT_AUTHOR_NAME", "GIT_COMMITTER_NAME"):
    os.environ[name] = "Saneroki"
for name in ("GIT_AUTHOR_EMAIL", "GIT_COMMITTER_EMAIL"):
    os.environ[name] = "saneroki@example.invalid"

with tempfile.TemporaryDirectory() as temporary:
    repo = Path(temporary) / "repo"
    repo.mkdir()

    def write(path, text):
        file = repo / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(text, encoding="utf-8")

    def commit(message):
        subprocess.run(["git", "-C", str(repo), "add", "-A"], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", message], check=True)

    subprocess.run(["git", "init", "-q", "-b", "main", str(repo)], check=True)
    subprocess.run(["git", "-C", str(repo), "config", "core.hooksPath", "/dev/null"], check=True)
    write("LICENSE", "the licence\n")
    write("Doc/changelog.txt", "Sane UI: what is new\n\n0.3.1 (2026-11-15)\n------------------\n- New.\n\n"
          "0.3.0 (2026-10-14)\n------------------\n- Old.\n")
    write("src/Core/SaneUI.toc", TOC.format(title="SaneUI", extra=""))
    write("src/Core/SaneUI.lua", "-- core 1\n")
    write("src/Core/README.md", "only for development\n")
    write("src/AuctionData/SaneUI_AuctionData.toc", TOC.format(title="SaneUI_AuctionData", extra=""))
    write("src/AuctionData/SaneUI_AuctionData.lua", "\n")
    write("src/Navigation/SaneUI_Navigation.toc", TOC.format(title="SaneUI_Navigation", extra=""))
    write("src/Navigation/SaneUI_Navigation.lua", "-- navigation 1\n")
    write("assets/optimized/Navigation/Art/map.blp", "art 1\n")
    write("src/SpeedLeveling/SaneUI_SpeedLeveling.toc", TOC.format(title="SaneUI_SpeedLeveling", extra=""))
    write("src/SpeedLeveling/SaneUI_SpeedLeveling.lua", "-- leveling\n")
    write("src/RetailOnly/SaneUI_RetailOnly.toc", TOC.format(title="SaneUI_RetailOnly", extra="## X-SaneUI-Games: retail"))
    write("src/RetailOnly/SaneUI_RetailOnly.lua", "\n")
    # A stand-in for the data compiler: one set into the folder named.
    write("dev/tools/data", '#!/bin/sh\nmkdir -p "$2/Sets" && echo "-- a set" > "$2/Sets/Test.lua"\n')
    os.chmod(repo / "dev/tools/data", 0o755)
    commit("first")

    check(tool.staged("main", repo) == ["Navigation", "RetailOnly", "SpeedLeveling"], "the staged modules: all but Core's")
    first = tool.plan("alpha", root=repo)
    check(first["modules"] == {} and first["left"] == ["Navigation", "RetailOnly", "SpeedLeveling"],
          "nothing promoted: every module left out, all are dev")
    check(first["core"] == ["Core"], "Core's project: Sane UI alone, its data holders not in it")
    check(tool.CARRIED == {"Economy": ("AuctionData", "AuctionScans")}, "the auction data's files go with Economy alone")
    check(refused(lambda: tool.plan("dev", root=repo)) is not None, "dev is no channel")

    # Promoting.
    check(tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet) == "Navigation/0.3.1-alpha",
          "a first promotion: one above the TOC's version")
    check("alpha already" in (refused(lambda: tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet)) or ""),
          "the same code twice at one stage: refused")
    check(tool.promote("Navigation", "beta", test=False, root=repo, say=quiet) == "Navigation/0.3.1-beta",
          "the same code up a stage keeps its version")
    check("no stage" in (refused(lambda: tool.promote("Core", "alpha", test=False, root=repo, say=quiet)) or ""),
          "Core has no stage")
    check("no module" in (refused(lambda: tool.promote("Nowhere", "alpha", test=False, root=repo, say=quiet)) or ""),
          "an unknown module: refused")
    check(tool.stage_of("Navigation", tool.stage_tags(repo)) == "beta" and tool.stage_of("SpeedLeveling", tool.stage_tags(repo)) == "dev",
          "a module's stage: the highest its versions reached")
    check(tool.promote("Navigation", "release", "0.4.0", dry=True, test=False, root=repo, say=quiet) == "Navigation/0.4.0-release"
          and not any(t["tag"] == "Navigation/0.4.0-release" for t in tool.stage_tags(repo)), "--dry tags nothing")

    # Newer code: a newer alpha; beta keeps the older version.
    write("src/Navigation/SaneUI_Navigation.lua", "-- navigation 2\n")
    write("src/Core/SaneUI.lua", "-- core 2\n")
    commit("second")
    check(tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet) == "Navigation/0.3.2-alpha",
          "newer code: a version above every one before")
    check("not newer" in (refused(lambda: tool.promote("Navigation", "alpha", "0.3.1", test=False, root=repo, say=quiet)) or ""),
          "an older number for new code: refused")
    beta = tool.plan("beta", root=repo)
    check(beta["modules"]["Navigation"]["tag"] == "Navigation/0.3.1-beta", "beta: the newest at beta or higher, the newer alpha ignored")
    check(tool.plan("alpha", root=repo)["modules"]["Navigation"]["tag"] == "Navigation/0.3.2-alpha", "alpha: the newest at alpha or higher")
    check("Navigation" in tool.plan("release", root=repo)["left"], "release: a module never released stays out")

    # The packages of a channel: Core's zip, a zip per module.
    out = Path(temporary) / "out"
    made = tool.package("beta", test=False, root=repo, out_dir=out, say=quiet)
    core_zip, nav_zip = made["core_release"]["zip"], made["modules"]["Navigation"]["zip"]
    check(core_zip.name == "SaneUI-0.3.1-beta.zip" and nav_zip.name == "SaneUI_Navigation-0.3.1-beta.zip",
          f"a zip per addon, named by its folder, version and channel: {core_zip.name}, {nav_zip.name}")
    check(made["core_release"] == {"version": "0.3.1", "new": True, "zip": core_zip}, "Core's first: one above its TOC")
    with zipfile.ZipFile(core_zip) as box:
        names = set(box.namelist())
        check({n.split("/")[0] for n in names} == {"SaneUI"}, "Core's zip: Sane UI alone (no auction data: no scans)")
        check(box.read("SaneUI/SaneUI.lua").decode() == "-- core 2\n", "Core from main's newest commit")
        check("SaneUI/README.md" not in names and "SaneUI/LICENSE.txt" in names, "no READMEs; the licence in each folder")
        check("SaneUI/Sets/Test.lua" in names, "Core's sets compiled into it")
        core_toc = box.read("SaneUI/SaneUI.toc").decode()
        check("## Version: 0.3.1\n" in core_toc and "## X-SaneUI-Build: beta 0.3.1" in core_toc
              and "X-SaneUI-Core" not in core_toc, "Core carries its version and which package it is")
    with zipfile.ZipFile(nav_zip) as box:
        names = set(box.namelist())
        check({n.split("/")[0] for n in names} == {"SaneUI_Navigation"}, "a module's zip: that module alone")
        check(box.read("SaneUI_Navigation/SaneUI_Navigation.lua").decode() == "-- navigation 1\n",
              "the older beta version's code, not main's newer alpha")
        check("SaneUI_Navigation/Art/map.blp" in names, "a module's art beside its code")
        toc = box.read("SaneUI_Navigation/SaneUI_Navigation.toc").decode()
        check("## Interface: 16001\n" in toc, "Forever's interface number alone")
        check("## Version: 0.3.1\n" in toc and "## X-SaneUI-Stage: beta" in toc, "the module's version and stage")
        check("## X-SaneUI-Core: 0.3.1" in toc, "the Core it was tested with, which Core checks in the game")
    check(made["modules"]["Navigation"]["title"] == "SaneUI_Navigation" and made["modules"]["Navigation"]["addon"]
          == "SaneUI_Navigation", "a module's title from its TOC")
    real_carried, tool.CARRIED = tool.CARRIED, {"Navigation": ("AuctionData",)}
    try:
        carrying = tool.package("beta", ["Navigation"], test=False, root=repo, out_dir=Path(temporary) / "carried",
                                say=quiet, core=False)
        with zipfile.ZipFile(carrying["modules"]["Navigation"]["zip"]) as box:
            check({n.split("/")[0] for n in box.namelist()} == {"SaneUI_Navigation", "SaneUI_AuctionData"},
                  "a module that carries addons: they stand beside it in its zip")
            data_toc = box.read("SaneUI_AuctionData/SaneUI_AuctionData.toc").decode()
            check("## Version: 0.3.1\n" in data_toc and "## X-SaneUI-Core: 0.3.1" in data_toc and "## Interface: 16001\n" in data_toc,
                  "a carried addon: the module's version, the Core it was tested with, Forever's interface alone")
    finally:
        tool.CARRIED = real_carried
    dry = tool.package("beta", dry=True, root=repo, out_dir=out, say=quiet)
    check(dry["core_release"]["zip"] == core_zip and dry["modules"]["Navigation"]["zip"] == nav_zip,
          "--dry names the zips, makes nothing new")
    only = tool.package("alpha", ["Navigation"], dry=True, root=repo, out_dir=out, say=quiet)
    check(list(only["modules"]) == ["Navigation"] and only["left"] == [], "modules named: those alone")
    check("never reached" in (refused(lambda: tool.package("alpha", ["SpeedLeveling"], dry=True, root=repo, say=quiet)) or ""),
          "a module named that never reached the channel: refused")
    check("Core's" in (refused(lambda: tool.package("alpha", ["Core"], dry=True, root=repo, say=quiet)) or ""),
          "Core is no module to name")

    # Retail-only modules and Git LFS pointers never go in.
    tool.promote("RetailOnly", "alpha", test=False, root=repo, say=quiet)
    alpha = tool.package("alpha", test=False, root=repo, out_dir=out, say=quiet, core=False)
    check(alpha["modules"]["RetailOnly"]["zip"] is None and alpha["core_release"]["zip"] is None,
          "a module made for Retail only gets no zip; core=False: no Core zip")
    with zipfile.ZipFile(alpha["modules"]["Navigation"]["zip"]) as box:
        check(box.read("SaneUI_Navigation/SaneUI_Navigation.lua").decode() == "-- navigation 2\n", "alpha: the newer version")
    write("assets/optimized/Navigation/Art/map.blp", "version https://git-lfs.github.com/spec/v1\noid sha256:00\nsize 9\n")
    commit("pointer")
    tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet)
    check("LFS pointer" in (refused(lambda: tool.package("alpha", ["Navigation"], test=False, root=repo, out_dir=out, say=quiet)) or ""),
          "a Git LFS pointer in place of art: no package")

    # The changelogs: each project's own on CurseForge, a part per version; never the suite's Doc/changelog.txt.
    write("Doc/changelog.txt", "Sane UI: what is new\n\nNavigation 0.3.1 (2026-11-16)\n---\n- The suite's words.\n")
    write("Doc/curseforge/changelogs/Navigation.md", "# Sane UI Maps: changelog\n\nIntro.\n\n## 0.3.1 (2026-11-16)\n\n- The map.\n\n## 0.3.0 (2026-10-14)\n\n- Older.\n")
    write("Doc/curseforge/changelogs/Core.md", "# Sane UI Core: changelog\n\n## 0.4.0 (2026-11-20)\n\n## 0.3.1 (2026-11-16)\n\n- Core.\n"
          "- Ends at 1.2.3 (not a heading).\n")
    check(tool.changelog("Navigation", "0.3.1", repo) == "- The map.",
          "a project's words for a version: its part of its own changelog, up to the next; not the suite's")
    check("Core." in tool.changelog("Core", "0.3.1", repo) and "1.2.3" in tool.changelog("Core", "0.3.1", repo),
          "Core's from its own file, a version inside a line no heading")
    check(tool.changelog("Navigation", "9.9.9", repo) is None and tool.changelog("Core", "0.3.0", repo) is None
          and tool.changelog("Loot", "0.3.1", repo) is None, "a version not written yet, or another project's: no words")
    check(tool.changelog("Core", "0.4.0", repo) is None,
          "a heading without a line of changes counts as no changelog (CurseForge wants one with every file)")
    meta = tool.metadata("Sane UI Maps", "0.3.1", "beta", [7], "words", "sane-ui")
    check(meta == {"changelog": "words", "changelogType": "markdown", "displayName": "Sane UI Maps 0.3.1 (beta)", "gameVersions": [7],
                   "releaseType": "beta", "relations": {"projects": [{"slug": "sane-ui", "type": "requiredDependency"}]}},
          "a module's upload: the channel its release type, Core's project its required dependency")
    check("relations" not in tool.metadata("Sane UI", "0.3.1", "release", [7], "w") and
          tool.metadata("Sane UI", "0.3.1", "release", [7], "w")["displayName"] == "Sane UI 0.3.1", "Core's upload names none")
    check(tool.project_name("Navigation", "Navigation", {"Navigation": {"id": 2, "name": "Sane UI Maps"}}) == "Sane UI Maps"
          and tool.project_name("Loot", "Loot", {}) == "Sane UI Loot" and tool.project_name("Core", "Sane UI", {}) == "Sane UI Core",
          "a project's name: the config's, else Sane UI and the title")
    check(tool.game_version_ids(["1.60.1", 12], [{"id": 5, "name": "1.60.1"}, {"id": 12, "name": "x"}]) == [5, 12],
          "game versions by name or id")
    check("no game version" in (refused(lambda: tool.game_version_ids(["2.0"], [{"id": 5, "name": "1.60.1"}])) or ""),
          "a game version CurseForge lacks: refused")
    body, kind = tool.multipart({"metadata": json.dumps(meta)}, "file", nav_zip)
    check(kind.startswith("multipart/form-data; boundary=") and b'name="metadata"' in body and b'name="file"' in body,
          "the upload's body: metadata and file")
    cf = Path(temporary) / "cf.json"
    for text, why in (('{"projects": {"Core": {"id": 1, "slug": "s"}}, "gameVersions": [1]}', "lacks token"),
                      ('{"token": "t", "gameVersions": [1], "projects": {"Core": {"id": 1}}}', "slug"),
                      ('{"token": "t", "gameVersions": [1], "projects": {"Core": {"id": 1, "slug": "s"}, "Loot": {}}}', "Loot lacks")):
        cf.write_text(text)
        check(why in (refused(lambda: tool.config(cf)) or ""), f"a config that {why}: refused")

    # Publishing: Core first, then each module, each tagged; what is up already never again.
    write("src/Navigation/SaneUI_Navigation.lua", "-- navigation 3\n")
    write("assets/optimized/Navigation/Art/map.blp", "art 3\n")
    commit("third")
    tool.promote("Navigation", "alpha", "0.4.0", test=False, root=repo, say=quiet)
    asked = []
    real_ask = tool.ask
    tool.ask = lambda url, token, data=None, headers=None: (
        asked.append((url, token, data)) or ([{"id": 3, "name": "1.60.1"}] if url.endswith("/versions") else {"id": 90 + len(asked)}))
    real_package = tool.package
    tool.package = lambda channel, only, core_wanted, dry, root, say, core: real_package(
        channel, only, core_wanted, dry, root, out_dir=out, say=say, test=False, core=core)
    try:
        settings = {"token": "secret", "gameVersions": ["1.60.1"],
                    "projects": {"Core": {"id": 41, "slug": "sane-ui"}, "Navigation": {"id": 42, "name": "Sane UI Maps"}}}
        check(tool.publish("alpha", dry=True, root=repo, say=quiet, settings=settings) == [] and asked == [],
              "--dry: nothing sent, nothing tagged")
        check("0.4.0 (<date>)\" in Doc/curseforge/changelogs/Navigation.md" in (refused(lambda: tool.publish("alpha", yes=True, root=repo, say=quiet, settings=settings)) or "")
              and asked == [], "no players' words for a version in its own changelog: nothing sent")
        write("Doc/curseforge/changelogs/Navigation.md", "# Sane UI Maps: changelog\n\n## 0.4.0 (2026-11-17)\n\n- Newer.\n")
        write("Doc/curseforge/changelogs/Core.md", "# Sane UI Core: changelog\n\n## 0.3.1 (2026-11-16)\n\n- Core.\n")
        commit("words")
        check(tool.publish("alpha", ["Navigation"], yes=True, root=repo, say=quiet, settings=settings) == [92, 93],
              "uploaded: CurseForge's file ids, Core's and the module's")
        check([a[0] for a in asked] == ["https://wow.curseforge.com/api/game/versions",
                                        "https://wow.curseforge.com/api/projects/41/upload-file",
                                        "https://wow.curseforge.com/api/projects/42/upload-file"],
              "the game versions asked, then Core sent to its project, then the module to its")
        check(b'"requiredDependency"' in asked[2][2] and b'"slug": "sane-ui"' in asked[2][2] and b"requiredDependency" not in asked[1][2]
              and b'"displayName": "Sane UI Maps 0.4.0 (alpha)"' in asked[2][2] and b"- Newer." in asked[2][2],
              "the module's upload names Core's project its required dependency, under the project's name, with its words")
        tags = {t["tag"] for t in tool.published_tags(repo)}
        check(tags == {"published/Core/0.3.1-alpha", "published/Navigation/0.4.0-alpha"}, f"each upload tagged: {tags}")
        asked.clear()
        check(tool.publish("alpha", yes=True, root=repo, say=quiet, settings=settings) == [] and asked == [],
              "again: nothing new, nothing sent")
        check(tool.core_version("beta", "main", None, repo) == {"version": "0.3.1", "new": True},
              "the same Core in a higher channel: its number kept, new there")
        write("src/Core/SaneUI.lua", "-- core 3\n")
        commit("core 3")
        check(tool.core_version("alpha", "main", None, repo) == {"version": "0.3.2", "new": True}, "new Core code: one above")
        check("not newer" in (refused(lambda: tool.core_version("alpha", "main", "0.3.1", repo)) or ""),
              "an older number for Core's new code: refused")
        write("Doc/curseforge/changelogs/Core.md", "# Sane UI Core: changelog\n\n## 0.3.2 (2026-11-18)\n\n- Fixed.\n\n## 0.3.1 (2026-11-16)\n\n- Core.\n")
        commit("words 2")
        check(tool.publish("alpha", yes=True, root=repo, say=quiet, settings=settings) == [92]
              and [a[0] for a in asked][1:] == ["https://wow.curseforge.com/api/projects/41/upload-file"],
              "Core changed, the modules not: Core alone uploaded")
        # The same code up a channel: uploaded again, its words saying so first.
        tool.promote("Navigation", "beta", test=False, root=repo, say=quiet)
        asked.clear()
        check(len(tool.publish("beta", yes=True, root=repo, say=quiet, settings=settings)) == 2
              and b"Unchanged since 0.3.2 (alpha), now beta." in asked[1][2]
              and b"Unchanged since 0.4.0 (alpha), now beta." in asked[2][2] and b'"releaseType": "beta"' in asked[2][2],
              "an alpha made beta comes again as beta, its changelog saying it is unchanged")
        # Drafts: a part for each upload without one, from the commits since its last; publish refuses them.
        write("src/Navigation/SaneUI_Navigation.lua", "-- navigation 3b\n")
        commit("Navigation: the map drawn faster")
        tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet)
        core_before = (repo / "Doc/curseforge/changelogs/Core.md").read_text()
        drafted = tool.draft_changelog("alpha", root=repo, say=quiet, today="2026-11-19", projects={})
        text = (repo / "Doc/curseforge/changelogs/Navigation.md").read_text()
        check(drafted == ["Doc/curseforge/changelogs/Navigation.md 0.4.1"], f"a draft in the module's own changelog, its new version only (Core is up): {drafted}")
        check(text.index("## 0.4.1 (2026-11-19)") < text.index("## 0.4.0") and
              "DRAFT: rewrite" in text and "- Navigation: the map drawn faster" in text and "- words" not in text
              and "core 3" not in text, "above its newest part: the DRAFT line, then only the commits that changed this module")
        check((repo / "Doc/curseforge/changelogs/Core.md").read_text() == core_before, "another project's changelog untouched")
        write("src/Loot/SaneUI_Loot.toc", "## Interface: 16001\n## Title: Loot\n## Version: 0.3.0\nLoot.lua\n")
        write("src/Loot/Loot.lua", "\n")
        commit("Loot: a module of its own")
        tool.promote("Loot", "alpha", test=False, root=repo, say=quiet)
        check(tool.draft_changelog("alpha", ["Loot"], root=repo, say=quiet, today="2026-11-19", projects={}) ==
              ["Doc/curseforge/changelogs/Loot.md 0.3.1"] and "# Sane UI Loot: changelog" in (repo / "Doc/curseforge/changelogs/Loot.md").read_text()
              and "- The first release of Sane UI Loot." in (repo / "Doc/curseforge/changelogs/Loot.md").read_text(),
              "a project's first changelog made with its heading, its first part saying so")
        check(tool.draft_changelog("alpha", root=repo, say=quiet, today="2026-11-20") == [], "a part there already: left alone")
        commit("draft")
        asked.clear()
        check("still a draft" in (refused(lambda: tool.publish("alpha", yes=True, root=repo, say=quiet, settings=settings)) or "")
              and asked == [], "publish refuses a part while its DRAFT line stands")
        write("Doc/curseforge/changelogs/Navigation.md", text.replace("DRAFT: rewrite these lines for players (short, the bigger changes), then delete this line.\n", ""))
        commit("words for players")
        check(len(tool.publish("alpha", ["Navigation"], yes=True, root=repo, say=quiet, settings=settings)) == 1
              and b'"changelogType": "markdown"' in asked[-1][2], "rewritten: uploaded, as Markdown")
        check(tool.due("alpha", ["Navigation"], root=repo) == [], "nothing due once uploaded")
        # The check: the token tried, the game versions listed, what the config lacks said; the token never shown.
        lines = []
        tool.ask = lambda url, token, data=None, headers=None: (
            [{"id": 9, "name": "WoW Forever", "slug": "wow-forever"}] if url.endswith("/version-types") else
            [{"id": 3, "name": "1.60.1", "gameVersionTypeID": 9}, {"id": 4, "name": "1.60.2", "gameVersionTypeID": 9}])
        ready = tool.check(settings={"token": "secret", "gameVersions": ["1.60.1"], "projects": {}}, say=lines.append)
        said = "\n".join(lines)
        check(not ready and "token works" in said and "WoW Forever (type 9): 1.60.2 (id 4), 1.60.1 (id 3)" in said
              and "'1.60.1': id 3, WoW Forever" in said and "lacks projects" in said and "secret" not in said,
              f"check: the token tried, the versions listed, what is missing said:\n{said}")
        check(tool.check(settings=settings, say=lines.append), "check: a whole config is ready")
        check("lacks token" in (refused(lambda: tool.check(settings={"projects": {}}, say=quiet)) or ""),
              "check: no token, nothing asked")
        settings["projects"].pop("Navigation")
        write("src/Navigation/SaneUI_Navigation.lua", "-- navigation 4\n")
        commit("fourth")
        tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet)
        check("no CurseForge project" in (refused(lambda: tool.publish("alpha", ["Navigation"], yes=True, root=repo, say=quiet,
                                                                         settings=settings)) or ""),
              "a module named without a project: refused")
    finally:
        tool.ask, tool.package = real_ask, real_package

print(f"release: {passed} checks passed" + (f", {len(failed)} failed:" if failed else ""))
for what in failed:
    print("  FAILED:", what)
sys.exit(1 if failed else 0)
