#!/usr/bin/env python3
"""Tests of dev/saneui, the one command of Sane UI's scripts: every command runs a script that is there, the names
are one word of small letters, every script in dev/, dev/tools/ and Scripts/ has one, the greeting card's words fit
its column, completion offers what may follow.
Run by dev/tests/run."""
import contextlib
import importlib.machinery
import importlib.util
import io
import os
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
loader = importlib.machinery.SourceFileLoader("saneui", str(ROOT / "dev" / "saneui"))
su = importlib.util.module_from_spec(importlib.util.spec_from_loader("saneui", loader))
loader.exec_module(su)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def output(*args):
    sys.argv = ["saneui", *args]
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        su.main()
    return out.getvalue().splitlines()


for name, (argv, what, card) in su.COMMANDS.items():
    check(f"{name}: one word of small letters", name.isalpha() and name.islower(), True)
    if argv[0].startswith("dev/") or argv[0].startswith("Scripts/"):
        check(f"{name}: its script is there", (ROOT / argv[0]).is_file(), True)
    elif argv[0] != "@installed":
        check(f"{name}: its program is a known one", argv[0] in ("comfyui",), True)
    check(f"{name}: says what it does", len(what) > 10, True)
    if card:
        check(f"{name}: its card words fit (30)", len(card) <= 30, True)
# Every script one runs has its command: a new script in dev/, dev/tools/ or Scripts/ gets its entry in dev/saneui.
run_by = {argv[0] for argv, _, _ in su.COMMANDS.values()}
for folder in ("dev", "dev/tools", "Scripts"):
    for path in sorted((ROOT / folder).iterdir()):
        if path.is_file() and os.access(path, os.X_OK) and path.name != "saneui":
            script = str(path.relative_to(ROOT))
            check(f"{script} has a saneui command (add it to dev/saneui's GROUPS)", script in run_by, True)
for name, verbs in su.BACKGROUND.items():
    check(f"{name}: background is a command", name in su.COMMANDS, True)
    check(f"{name}: verbs known", set(verbs) <= set(su.VERBS), True)
check("names: the commands first", output("--names")[:2], ["installdev", "installrelease"])
check("names: after a verb, the background ones", output("--names", "start"), list(su.BACKGROUND))
check("names: after a command, none", output("--names", "installdev"), [])
lines = [line.split("\t") for line in output("--card")]
check("card: sides and kinds", all(p[0] in "LR" and p[1] in "hrb" for p in lines), True)
check("card: a row has a command and words", all(len(p) == 4 for p in lines if p[1] == "r"), True)
check("card: rows fit the command column (18)", all(len(p[2]) < 18 for p in lines if p[1] == "r"), True)

print(f"saneui: all {checks} checks passed." if not failed else f"saneui: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
