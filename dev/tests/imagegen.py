#!/usr/bin/env python3
"""Tests of the image pipeline's tools without ComfyUI: dev/tools/imagegen reads its lists (include, the
run's settings, before, style, ref) as Doc/guides/image-generation.md says, every recipe and set in
dev/imagegen/ reads, and dev/tools/flipbook's grid, sizes and loops come out right. The workflows the
recipes name are checked only where the ComfyUI folder is on this computer. Run by dev/tests/run."""
import contextlib
import importlib.machinery
import io
import importlib.util
import os
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)


def tool(name):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / "dev" / "tools" / name))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(name, loader))
    loader.exec_module(module)
    return module


ig, fb = tool("imagegen"), tool("flipbook")
ig.CHECK_FILES = False  # the anchors and chosen parts are local pictures, not in the repository
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


# Sentences
check("sentence", ig.sentence("Before:", "a star", "Style."), "Before: a star. Style.")
check("sentence empty parts", ig.sentence("", "a star.", ""), "a star.")
check("sentence only style", ig.sentence("", "", "Style."), "Style.")

# A list with an include, the run's settings and the prompts' before, style and ref
with tempfile.TemporaryDirectory() as folder:
    folder = Path(folder)
    (folder / "recipe.txt").write_text(
        "workflow: qwen21-edit-1ref\nset: width=1536, height=1024\ncount: 8\nflatten: #102030\n"
        "before: Make:\nstyle: House.\n")
    (folder / "list.txt").write_text(
        f"# a set\ninclude: {folder / 'recipe.txt'}\ncount: 4\nset: width=1024\nout: out/here\n"
        "ref: a.png, b.png\none: a star\nstyle:\nref:\ntwo: a ring.\nbefore:\nthree:\n")
    run, jobs = ig.read_list(folder / "list.txt")
    check("workflow from include", run["workflow"], "qwen21-edit-1ref")
    check("set adds up, last wins", run["set"], {"width": 1024, "height": 1024})
    check("count: last wins", run["count"], 4)
    check("out", run["out"], "out/here")
    check("flatten colour", run["flatten"], (16, 32, 48))
    check("names in order", [j["name"] for j in jobs], ["one", "two", "three"])
    check("before, prompt, style", jobs[0]["prompt"], "Make: a star. House.")
    check("refs", [str(r) for r in jobs[0]["refs"]], ["a.png", "b.png"])
    check("empty style ends it", jobs[1]["prompt"], "Make: a ring.")
    check("empty ref ends it", jobs[1]["refs"], [])
    check("empty prompt", jobs[2]["prompt"], "")
    (folder / "loop.txt").write_text(f"include: {folder / 'loop.txt'}\n")
    try:
        with contextlib.redirect_stderr(io.StringIO()):
            ig.read_list(folder / "loop.txt")
        check("include of itself fails", "read", "failed")
    except SystemExit:
        check("include of itself fails", "failed", "failed")

# Every recipe and set reads, names a workflow, and has a house style where it makes interface art
lists = sorted((ROOT / "dev" / "imagegen").rglob("*.txt"))
check("recipes and sets found", len(lists) > 8, True)
home = ig.WORKFLOWS[-1]
for path in lists:
    if path.name == "style.txt":
        continue
    rel = path.relative_to(ROOT)
    run, jobs = ig.read_list(rel)
    check(f"{rel} names a workflow", bool(run["workflow"]), True)
    if "/sets/" in str(rel):
        check(f"{rel} has prompts", bool(jobs) and all(j["prompt"] for j in jobs), True)
        check(f"{rel} has out", bool(run["out"]), True)
    if home.is_dir():
        graph = ig.json.loads(ig.find_workflow(run["workflow"]).read_text())
        refs = max((len(j["refs"]) for j in jobs), default=0)
        check(f"{rel}: the workflow takes its references", len(ig.ref_nodes(graph)) >= refs, True)
_, jobs = ig.read_list("dev/imagegen/sets/example/parts.txt")
check("a part has the transparency sentence first", jobs[0]["prompt"].startswith("This is an RGBA format image"), True)
check("a part has no house style", "Polished fantasy" in jobs[0]["prompt"], False)
check("a part ends with its framing", jobs[0]["prompt"].endswith("fills most of the picture."), True)
_, jobs = ig.read_list("dev/imagegen/sets/example/parts-new.txt")
check("a new part has the house style", jobs[0]["prompt"].endswith("no watermark."), True)

# Flipbook: frame sides as dev/tools/art sizes, power-of-two grids, loops
check("side of 40 units", fb.side(40), 128)
check("side of 24 units", fb.side(24), 64)
check("side of 96 units", fb.side(96), 256)
check("grid 30", fb.grid(30), (8, 4))
check("grid 16", fb.grid(16), (4, 4))
check("grid 20", fb.grid(20), (8, 4))
check("grid 64", fb.grid(64), (8, 8))
check("grid 2", fb.grid(2), (2, 1))
frames = [fb.np.full((2, 2, 4), i, dtype=fb.np.float32) for i in range(48)]
check("drop-last", len(fb.loop(frames, "drop-last")), 47)
faded = fb.loop(frames, "fade:8")
check("fade:8 length", len(faded), 40)
check("fade:8 starts near the end", round(float(faded[0][0, 0, 0]), 3), round(40 * 8 / 9 + 0 * 1 / 9, 3))
check("fade:8 meets the middle", round(float(faded[7][0, 0, 0]), 3), round(47 / 9 + 7 * 8 / 9, 3))
check("fade:8 middle untouched", float(faded[8][0, 0, 0]), 8.0)
check("pick evenly", [float(f[0, 0, 0]) for f in fb.pick(frames, 4)], [0.0, 12.0, 24.0, 36.0])
check("pick no more than there are", len(fb.pick(frames[:5], 32)), 5)

print(f"Images: all {checks} checks passed." if not failed else f"Images: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
