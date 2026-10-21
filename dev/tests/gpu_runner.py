#!/usr/bin/env python3
"""Tests of dev/tools/gpu-runner without the graphics card, ComfyUI or the game: the job list and its order,
which job comes next, the claims, and what counts as the card being wanted elsewhere (the game, programs on
the card, the desktop, ComfyUI pictures of others), on made-up looks. Run by dev/tests/run."""
import fnmatch
import importlib.machinery
import importlib.util
import os
import shutil
import sys
import tempfile
import time
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)
TEMP = Path(tempfile.mkdtemp(prefix="gpu-runner-test-"))
os.environ["GPU_RUNNER_DIR"] = str(TEMP / "run")
os.environ["GPU_RUNNER_STATE"] = str(TEMP / "state")

loader = importlib.machinery.SourceFileLoader("gpu_runner", str(ROOT / "dev" / "tools" / "gpu-runner"))
runner = importlib.util.module_from_spec(importlib.util.spec_from_loader("gpu_runner", loader))
loader.exec_module(runner)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


# --- The job list --------------------------------------------------------------------------------

settings, jobs = runner.load_jobs(runner.JOBS)
check("jobs.toml reads", isinstance(jobs, list), True)
check("jobs.toml: its settings are the defaults", {k: settings[k] for k in runner.DEFAULTS}, runner.DEFAULTS)

listed = TEMP / "jobs.toml"
listed.write_text("""hold = 30
[[job]]
name = "low"
command = ["true"]
[[job]]
name = "high"
priority = 10
command = ["true"]
[[job]]
name = "also-high"
priority = 10
command = ["true"]
""")
settings, jobs = runner.load_jobs(listed)
check("order: priority, then the file's order", [j["name"] for j in jobs], ["high", "also-high", "low"])
check("a setting of the file wins", settings["hold"], 30)
check("the others stay", settings["poll"], runner.DEFAULTS["poll"])
check("next: the most important", runner.next_job(jobs, {}, 3)["name"], "high")
check("next: finished ones are left", runner.next_job(jobs, {"high": {"finished": "x"}}, 3)["name"], "also-high")
check("next: failed too often", runner.next_job(jobs, {"high": {"failures": 3}, "also-high": {"failures": 2}}, 3)["name"],
      "also-high")
check("next: a held one is left", runner.next_job(jobs, {}, 3, {"high": "waiting"})["name"], "also-high")
check("next: none left", runner.next_job(jobs, {j["name"]: {"finished": "x"} for j in jobs}, 3), None)

done = {"name": "d", "command": ["true"], "priority": 0, "at": 0,
        "status": [sys.executable, "-c", "print('5 of 5 squares painted (100 %)')"], "done": r"^(\d+) of \1 squares"}
check("progress: its first line, done", runner.progress(done), ("5 of 5 squares painted (100 %)", True))
half = {**done, "status": [sys.executable, "-c", "print('3 of 5 squares painted')"]}
check("progress: not done", runner.progress(half)[1], False)
state = {}
half["name"] = "h"
check("next: done by its status is finished", runner.next_job([done, half], state, 3)["name"], "h")
check("next: ... and kept so", bool(state.get("d", {}).get("finished")), True)

for bad, why in (('[[job]]\nname = "x"\n', "no command"),
                 ('[[job]]\nname = "x"\ncommand = ["a"]\n[[job]]\nname = "x"\ncommand = ["b"]\n', "twice")):
    listed.write_text(bad)
    try:
        runner.load_jobs(listed)
        check(f"refused: {why}", False, True)
    except SystemExit:
        check(f"refused: {why}", True, True)


# --- Who wants the card --------------------------------------------------------------------------

claims = runner.RUNTIME / "claims"
claims.mkdir(parents=True, exist_ok=True)
(claims / "by-hand").write_text("")
(claims / "mine").write_text(f"{os.getpid()}\n")
(claims / "ended").write_text("999999999\n")
check("claims: standing ones", runner.claims(), ["by-hand", "mine"])
check("claims: one whose process ended goes", (claims / "ended").exists(), False)
for path in claims.iterdir():
    path.unlink()

looks = {"users": [], "queue": [], "games": [], "comfy": 100}
runner.card_users = lambda: looks["users"]
runner.comfy_queue = lambda: looks["queue"]
runner.playing = lambda patterns: looks["games"]
runner.comfyui_pid = lambda: looks["comfy"]
runner.comm = lambda pid: {1: "kwin_wayland", 2: "WowB.exe", 3: "firefox", 100: "python"}.get(pid, "?")
watch = runner.Watch({**runner.DEFAULTS}, "gpu-runner-me")

check("free: nothing else", watch.reasons(set()), [])
looks["users"] = [(100, 99, 11000)]
check("ComfyUI itself never counts", watch.reasons(set()), [])
looks["users"] = [(2, 30, 3000)]
check("a program holding much of the card", watch.reasons(set()), ["WowB.exe (2) holds 3000 MiB of the card"])
check("... not when it is the job's own", watch.reasons({2}), [])
looks["users"] = [(1, 90, 400)]
check("the desktop never counts", [watch.reasons(set()) for _ in range(4)], [[]] * 4)
looks["users"] = [(3, 60, 300)]
check("busy: counts at the third look in a row", [bool(watch.reasons(set())) for _ in range(3)], [False, False, True])
looks["users"] = [(3, 10, 300)]
watch.reasons(set())
looks["users"] = [(3, 60, 300)]
check("busy: a quiet look starts over", bool(watch.reasons(set())), False)
looks["users"] = []
watch.reasons(set())
looks["queue"] = [("a", "gpu-runner-me", True), ("b", "gpu-runner-me", False)]
check("ComfyUI: the runner's own pictures", watch.reasons(set()), [])
looks["queue"] = [("a", "gpu-runner-me", True), ("c", "someone", False)]
check("ComfyUI: pictures of others", watch.reasons(set()), ["ComfyUI makes pictures of another session or tool"])
check("... and remembered", watch.others_seen, True)
looks["queue"] = None
check("ComfyUI not there", watch.reasons(set()), [])
looks["games"] = ["the game (WowB.exe, 7)"]
check("the game", watch.reasons(set()), ["the game (WowB.exe, 7)"])
looks["games"] = []
runner.STATE.mkdir(parents=True, exist_ok=True)
runner.PAUSED.touch()
(claims / "voice").write_text("")
check("paused and claimed", watch.reasons(set()), ["paused by hand", "claimed by voice"])
runner.PAUSED.unlink()
(claims / "voice").unlink()


# --- A switch, and the more important job taking over (a runner on made-up jobs, nothing on the card) ---------

looks.update(users=[], queue=[], games=[])
listed.write_text("""hold = 0
poll = 0.05
[[job]]
name = "a"
priority = 5
comfyui = false
command = ["sleep", "30"]
[[job]]
name = "b"
priority = 1
comfyui = false
command = ["sleep", "30"]
[[job]]
name = "quick"
comfyui = false
command = ["true"]
""")
_, jobs = runner.load_jobs(listed)
check("ordered: by priority", [j["name"] for j in runner.ordered(jobs)], ["a", "b", "quick"])
check("ordered: the one switched to first", [j["name"] for j in runner.ordered(jobs, {"name": "b"})], ["b", "a", "quick"])
check("waiting: held, finished or failed ones not", [runner.waiting(j, {"b": {"finished": "x"}, "quick": {"failures": 3}}, 3,
                                                                   {"a": "x"}) for j in jobs], [False, False, False])
import threading
live = runner.Runner(listed)
thread = threading.Thread(target=live.loop, daemon=True)
thread.start()


def becomes(what, want, seconds=5):
    end = time.time() + seconds
    while time.time() < end:
        if what() == want:
            return want
        time.sleep(0.05)
    return what()


name = lambda: live.job and live.job["name"]
check("live: the most important runs", becomes(name, "a"), "a")
runner.write_json(runner.FIRST, {"name": "b", "at": time.time()})
check("live: a switch takes over at once", becomes(name, "b"), "b")
kept = runner.read_json(runner.STATE / "state.json", {})
check("live: the job switched from is only stopped", kept.get("a", {}).get("failures", 0), 0)
runner.FIRST.unlink()
check("live: back to the priorities", becomes(name, "a"), "a")
listed.write_text(listed.read_text() + '[[job]]\nname = "new"\npriority = 9\ncomfyui = false\ncommand = ["sleep", "30"]\n')
check("live: a more important new job takes over", becomes(name, "new"), "new")
runner.write_json(runner.FIRST, {"name": "quick", "at": time.time()})
check("live: one switched to and finished ...", becomes(lambda: bool(runner.read_json(runner.STATE / "state.json", {})
                                                                      .get("quick", {}).get("finished")), True), True)
check("... is no longer first", becomes(lambda: runner.FIRST.exists(), False), False)
check("... and the priorities go on", becomes(name, "new"), "new")
live.quit = True
thread.join(5)
live.shut()
check("live: stopped, nothing left running", live.proc, None)

check("the game's name under Proton", fnmatch.fnmatch("WowB.exe".lower(), "Wow*.exe".lower()), True)
check("Battle.net is no game", fnmatch.fnmatch("Battle.net.exe".lower(), "Wow*.exe".lower()), False)
check("this process' tree holds it", os.getpid() in runner.tree(os.getpid()), True)

shutil.rmtree(TEMP, ignore_errors=True)
print(f"GPU runner: all {checks} checks passed." if not failed else f"GPU runner: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
