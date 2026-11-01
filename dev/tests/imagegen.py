#!/usr/bin/env python3
"""Tests of the image pipeline's tools without ComfyUI: dev/tools/imagegen reads its lists (include, the
run's settings, before, style, ref) as Doc/guides/image-generation.md says, every recipe and set in
dev/imagegen/ reads, its waiting for ComfyUI ends when a job is lost or the server falls silent, and
dev/tools/flipbook's grid, sizes (dev/tools/art's) and loops come out right. The workflows the recipes
name are checked only where the ComfyUI folder is on this computer. Run by dev/tests/run."""
import contextlib
import importlib.machinery
import io
import importlib.util
import os
import socket
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


ig, fb, art = tool("imagegen"), tool("flipbook"), tool("art")
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

# Every recipe and set reads, names a workflow, and has a house style where it makes interface art. A part that
# other lists include and that names no workflow (the house style, a set's shared views) is checked in them.
lists = sorted((ROOT / "dev" / "imagegen").rglob("*.txt"))
check("recipes and sets found", len(lists) > 8, True)
parts = {(ROOT / line.partition(":")[2].strip()).resolve() for path in lists
         for line in path.read_text(encoding="utf-8").splitlines() if line.strip().startswith("include:")}
check("the house style is a part", (ROOT / "dev" / "imagegen" / "style.txt").resolve() in parts, True)
home = ig.WORKFLOWS[-1]
for path in lists:
    rel = path.relative_to(ROOT)
    run, jobs = ig.read_list(rel)
    if path.resolve() in parts and not run["workflow"]:
        continue
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

# The canvas' form sent with every job: slots before widgets, a seed's "fixed", an upload, links, forced inputs
definitions = {
    "Load": {"input": {"required": {"image": [["a.png"], {"image_upload": True}]}}, "output": ["IMAGE", "MASK"]},
    "Text": {"input": {"required": {"text": ["STRING", {"multiline": True}], "system": ["STRING", {"forceInput": True}]}},
             "output": ["COND"]},
    "Sample": {"input": {"required": {"cond": ["COND", {}], "seed": ["INT", {"control_after_generate": True}],
                                      "image": ["IMAGE", {}]}}, "output": ["IMAGE"], "display_name": "Sample"},
    "PrimitiveStringMultiline": {"input": {"required": {"value": ["STRING", {"multiline": True}]}}, "output": ["STRING"]},
}
graph = {"1": {"class_type": "Load", "inputs": {"image": "b.png"}, "_meta": {"title": "ref1"}},
         "2": {"class_type": "Text", "inputs": {"text": "a test", "system": "be brief"}},
         "3:4": {"class_type": "Sample", "inputs": {"cond": ["2", 0], "seed": 7, "image": ["1", 0]}, "_meta": {"title": "Sample"}}}
ui = ig.ui_workflow(graph, definitions, "test")
nodes = {n["id"]: n for n in ui["nodes"]}
check("canvas: a subgraph's node id", "3_4" in nodes, True)
check("canvas: seed then fixed", nodes["3_4"]["widgets_values"], [7, "fixed"])
check("canvas: slots first", [i["name"] for i in nodes["3_4"]["inputs"]], ["cond", "image", "seed"])
check("canvas: the upload widget", nodes[1]["widgets_values"], ["b.png", "image"])
check("canvas: a ref's title", nodes[1].get("title"), "ref1")
check("canvas: no title like the name", "title" not in nodes["3_4"], True)
check("canvas: a forced input's own node", nodes["2_system"]["widgets_values"], ["be brief"])
check("canvas: links", sorted(str(link[1:5]) for link in ui["links"]),
      sorted(str(link) for link in ([2, 0, "3_4", 0], [1, 0, "3_4", 1], ["2_system", 0, 2, 0])))
check("canvas: left to right", nodes[1]["pos"][0] < nodes["3_4"]["pos"][0], True)
check("canvas: an unknown node leaves it out", ig.ui_workflow({"1": {"class_type": "Nope", "inputs": {}}}, definitions), None)

# A second prompt of one name is refused (its pictures would overwrite the first one's); seed 0 is a seed
with tempfile.TemporaryDirectory() as folder:
    folder = Path(folder)
    (folder / "twice.txt").write_text("one: a star\ntwo: a ring\none: a moon\n")
    try:
        with contextlib.redirect_stderr(io.StringIO()):
            ig.read_list(folder / "twice.txt")
        check("a second prompt of one name is refused", "read", "refused")
    except SystemExit:
        check("a second prompt of one name is refused", "refused", "refused")
    (folder / "flow.json").write_text('{"1": {"class_type": "Text", "inputs": {"text": "{prompt}", "seed": 5}}}')
    (folder / "list.txt").write_text("seed: 0\ncount: 2\none: a star\n")

    def dry(*options):
        sys.argv = ["imagegen", str(folder / "flow.json"), str(folder / "list.txt"), "--dry-run", *options]
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            ig.main()
        return out.getvalue()

    check("seed 0 is a seed", "seeds 0-1" in dry(), True)
    check("--seed 0 too", "seeds 0-0" in dry("--seed", "0", "--count", "1"), True)

# Waiting for a job: one still queued is waited for; one gone from the queue without a history entry fails
ig.POLL = 0
server = ig.Server("127.0.0.1:1")
answers = {"/history/p1": [{}, {}, {"p1": {"status": {"status_str": "success"}}}],
           "/queue": [{"queue_pending": [[0, "p1", {}, {}]]}, {"queue_pending": []}, {"queue_pending": []}]}
server.call = lambda path, data=None, headers=None: ig.json.dumps(answers[path].pop(0)).encode()
check("wait: a job still queued is waited for", server.wait("p1"), {"status": {"status_str": "success"}})
check("wait: ... one look at a time", [len(a) for a in answers.values()], [0, 1])
answers = {"/history/p2": [{}] * 3, "/queue": [{"queue_running": [[0, "p1", {}, {}]], "queue_pending": []}] * 3}
try:
    with contextlib.redirect_stderr(io.StringIO()):
        server.wait("p2")
    check("wait: a job gone from the queue fails", "waited", "failed")
except SystemExit:
    check("wait: a job gone from the queue fails", "failed", "failed")
check("wait: ... after two looks", [len(a) for a in answers.values()], [1, 1])

# A call does not wait for ever: a server that never answers is given up on after TIMEOUT
deaf = socket.socket()
deaf.bind(("127.0.0.1", 0))
deaf.listen(1)
ig.TIMEOUT = 0.2
said = io.StringIO()
try:
    with contextlib.redirect_stderr(said):
        ig.Server(f"127.0.0.1:{deaf.getsockname()[1]}").call("/queue")
    check("call: a server that never answers is given up on", "answered", "given up")
except SystemExit:
    check("call: a server that never answers is given up on", "given up", "given up")
check("call: ... and says so", "did not answer" in said.getvalue(), True)
deaf.close()

# Flipbook: frame sides as dev/tools/art sizes every texture (its cap for the sheet), power-of-two grids, loops
check("side of 40 units", art.side(40), 128)
check("side of 24 units", art.side(24), 64)
check("side of 96 units", art.side(96), 256)
check("side: at most 1024", art.side(1000), 1024)
check("side: the flipbook's own cap", art.side(1000, fb.LARGEST), 2048)
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
