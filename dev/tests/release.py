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
    first = tool.plan("alpha", repo)
    check(first["modules"] == {} and first["left"] == ["Navigation", "RetailOnly", "SpeedLeveling"],
          "nothing promoted: every module left out, all are dev")
    check(first["core"] == ["Core", "AuctionData"], "Core and its data holder are always in")
    check(refused(lambda: tool.plan("dev", repo)) is not None, "dev is no channel")

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
    beta = tool.plan("beta", repo)
    check(beta["modules"]["Navigation"]["tag"] == "Navigation/0.3.1-beta", "beta: the newest at beta or higher, the newer alpha ignored")
    check(tool.plan("alpha", repo)["modules"]["Navigation"]["tag"] == "Navigation/0.3.2-alpha", "alpha: the newest at alpha or higher")
    check("Navigation" in tool.plan("release", repo)["left"], "release: a module never released stays out")

    # The package of a channel.
    out = Path(temporary) / "out"
    made = tool.package("beta", test=False, root=repo, out_dir=out, say=quiet)
    with zipfile.ZipFile(made["zip"]) as box:
        names = set(box.namelist())
        tops = {n.split("/")[0] for n in names}
        check(tops == {"SaneUI", "SaneUI_AuctionData", "SaneUI_Navigation"}, f"beta's package: Core, its data, Navigation: {tops}")
        check(box.read("SaneUI_Navigation/SaneUI_Navigation.lua").decode() == "-- navigation 1\n",
              "the older beta version's code, not main's newer alpha")
        check(box.read("SaneUI/SaneUI.lua").decode() == "-- core 2\n", "Core from main's newest commit")
        check("SaneUI_Navigation/Art/map.blp" in names, "a module's art beside its code")
        check("SaneUI/README.md" not in names and "SaneUI/LICENSE.txt" in names, "no READMEs; the licence in each folder")
        check("SaneUI/Sets/Test.lua" in names, "Core's sets compiled into it")
        toc = box.read("SaneUI_Navigation/SaneUI_Navigation.toc").decode()
        check("## Interface: 16001\n" in toc, "Forever's interface number alone")
        check("## Version: 0.3.1\n" in toc and "## X-SaneUI-Stage: beta" in toc, "the module's version and stage")
        core_toc = box.read("SaneUI/SaneUI.toc").decode()
        check(f"## Version: {made['version']}\n" in core_toc and f"## X-SaneUI-Build: beta {made['version']}" in core_toc,
              "Core carries the package's version and which package it is")
    check(made["version"] == "0.3.1", "the first package: one above Core's version")
    check(tool.package("beta", dry=True, root=repo, out_dir=out, say=quiet)["zip"] == made["zip"], "--dry names the zip, makes nothing new")

    # Retail-only modules and Git LFS pointers never go in.
    tool.promote("RetailOnly", "alpha", test=False, root=repo, say=quiet)
    alpha = tool.package("alpha", "0.5.0", test=False, root=repo, out_dir=out, say=quiet)
    with zipfile.ZipFile(alpha["zip"]) as box:
        tops = {n.split("/")[0] for n in box.namelist()}
        check("SaneUI_RetailOnly" not in tops and "SaneUI_Navigation" in tops, "a module made for Retail only stays out")
        check(box.read("SaneUI_Navigation/SaneUI_Navigation.lua").decode() == "-- navigation 2\n", "alpha: the newer version")
    write("assets/optimized/Navigation/Art/map.blp", "version https://git-lfs.github.com/spec/v1\noid sha256:00\nsize 9\n")
    commit("pointer")
    tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet)
    check("LFS pointer" in (refused(lambda: tool.package("alpha", "0.6.0", test=False, root=repo, out_dir=out, say=quiet)) or ""),
          "a Git LFS pointer in place of art: no package")

    # Versions of packages, the changelog, CurseForge's metadata and upload.
    subprocess.run(["git", "-C", str(repo), "tag", "-a", "v0.5.0-alpha", "-m", "a package", "main"], check=True)
    check("not newer" in (refused(lambda: tool.package_version("main", "0.4.0", repo)) or ""), "a package never older than one before")
    check(tool.package_version("main", None, repo) == "0.5.1", "the next package: one above the newest")
    check(tool.changelog("0.3.1", repo / "Doc/changelog.txt").startswith("0.3.1 (2026-11-15)") and
          "Old" not in tool.changelog("0.3.1", repo / "Doc/changelog.txt"), "the changelog: this version's part")
    check(tool.changelog("9.9.9", repo / "Doc/changelog.txt") is None, "a version not written yet: no words of another's")
    meta = tool.metadata({"version": "0.3.1", "channel": "beta"}, [7], "words")
    check(meta == {"changelog": "words", "changelogType": "text", "displayName": "Sane UI 0.3.1 (beta)", "gameVersions": [7],
                   "releaseType": "beta"}, "the upload's metadata: the channel is its release type")
    check(tool.game_version_ids(["1.60.1", 12], [{"id": 5, "name": "1.60.1"}, {"id": 12, "name": "x"}]) == [5, 12],
          "game versions by name or id")
    check("no game version" in (refused(lambda: tool.game_version_ids(["2.0"], [{"id": 5, "name": "1.60.1"}])) or ""),
          "a game version CurseForge lacks: refused")
    body, kind = tool.multipart({"metadata": json.dumps(meta)}, "file", made["zip"])
    check(kind.startswith("multipart/form-data; boundary=") and b'name="metadata"' in body and b'name="file"' in body,
          "the upload's body: metadata and file")
    (Path(temporary) / "cf.json").write_text('{"project": 1, "gameVersions": [1]}')
    check("lacks token" in (refused(lambda: tool.config(Path(temporary) / "cf.json")) or ""), "a config without its token: refused")

    write("src/Navigation/SaneUI_Navigation.lua", "-- navigation 3\n")
    write("assets/optimized/Navigation/Art/map.blp", "art 3\n")
    commit("third")
    tool.promote("Navigation", "alpha", test=False, root=repo, say=quiet)
    asked = []
    real_ask = tool.ask
    tool.ask = lambda url, token, data=None, headers=None: (
        asked.append((url, token, data is not None)) or ([{"id": 3, "name": "1.60.1"}] if url.endswith("/versions") else {"id": 99}))
    real_package = tool.package
    tool.package = lambda channel, wanted, dry, root, say: real_package(channel, wanted, dry, root, out_dir=out, say=say, test=False)
    try:
        settings = {"project": 42, "token": "secret", "gameVersions": ["1.60.1"]}
        check(tool.publish("alpha", None, dry=True, root=repo, say=quiet, settings=settings) is None and asked == [],
              "--dry: nothing sent, nothing tagged")
        check("no part for 0.5.1" in (refused(lambda: tool.publish("alpha", None, yes=True, root=repo, say=quiet, settings=settings)) or "")
              and asked == [], "no players' words for the version: nothing sent")
        write("Doc/changelog.txt", "Sane UI: what is new\n\n0.5.1 (2026-11-16)\n------------------\n- Newer.\n")
        commit("words")
        check(tool.publish("alpha", None, yes=True, root=repo, say=quiet, settings=settings) == 99, "uploaded: CurseForge's file id")
        check([a[0] for a in asked] == ["https://wow.curseforge.com/api/game/versions",
                                        "https://wow.curseforge.com/api/projects/42/upload-file"] and asked[1][2],
              "the game versions asked, then the file sent to the project")
        check(any(t["version"] == "0.5.1" and t["channel"] == "alpha" for t in tool.package_tags(repo)),
              "a published package is tagged v<version>-<channel>")
    finally:
        tool.ask, tool.package = real_ask, real_package

print(f"release: {passed} checks passed" + (f", {len(failed)} failed:" if failed else ""))
for what in failed:
    print("  FAILED:", what)
sys.exit(1 if failed else 0)
