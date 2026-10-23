#!/usr/bin/env python3
"""Tests of dev/tools/board on a board of its own: cards made, edited, moved before others and to a column's
top, deleted; the log; Backlog.md as text; a ranked Markdown list read in. Run by dev/tests/run."""
import importlib.machinery
import importlib.util
import json
import os
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEMP = Path(tempfile.mkdtemp(prefix="board-test-"))
os.environ["SANEUI_BOARD"] = str(TEMP / "board.json")

loader = importlib.machinery.SourceFileLoader("board", str(ROOT / "dev" / "tools" / "board"))
board = importlib.util.module_from_spec(importlib.util.spec_from_loader("board", loader))
loader.exec_module(board)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def order(b, key):
    return [c["id"] for c in b["cards"] if c["column"] == key]


path = board.board_file()
with board.changing(path) as b:
    for title in ("one", "two", "three"):
        board.apply(b, {"op": "add", "title": title}, "Claude")
    board.apply(b, {"op": "add", "title": "top", "priority": "high", "top": True}, "Saneroki")
b = board.read(path)
check("made in order, the top one first", order(b, "backlog"), [4, 1, 2, 3])
check("ids count on", b["next"], 5)
check("the version counts writes", b["version"], 1)
check("a card's default priority", board.find(b, 1)["priority"], "medium")

with board.changing(path) as b:
    board.apply(b, {"op": "move", "id": 3, "column": "In progress"}, "Claude")
    board.apply(b, {"op": "move", "id": 1, "column": "doing", "before": 3}, "Claude")
    board.apply(b, {"op": "move", "id": 2, "column": "backlog", "before": 4}, "Saneroki")
b = board.read(path)
check("moved by name and key, before another", order(b, "doing"), [1, 3])
check("reordered within a column", order(b, "backlog"), [2, 4])
check("the log keeps the steps", [t for _, _, t in board.find(b, 1)["log"]], ["made in Backlog", "moved to In progress"])
check("who changed it last", board.find(b, 2)["by"], "Saneroki")

with board.changing(path) as b:
    board.apply(b, {"op": "edit", "id": 4, "title": "top!", "priority": "low", "notes": None}, "Claude")
    board.apply(b, {"op": "delete", "id": 2}, "Claude")
b = board.read(path)
check("edited", (board.find(b, 4)["title"], board.find(b, 4)["priority"]), ("top!", "low"))
check("deleted", [c["id"] for c in b["cards"]], [4, 1, 3])
for name, op in (("no title", {"op": "add", "title": " "}), ("bad priority", {"op": "edit", "id": 4, "priority": "urgent"}),
                 ("bad column", {"op": "move", "id": 4, "column": "later"}), ("no card", {"op": "move", "id": 9, "column": "done"})):
    try:
        board.apply(board.read(path), op, "Claude")
        check(name + " refused", False, True)
    except (KeyError, ValueError):
        check(name + " refused", True, True)

text = (TEMP / "Backlog.md").read_text()
check("Backlog.md written", "- [ ] #1 **medium** one" in text and "## In progress (2)" in text, True)

cards = board.parse_markdown("""# Plan
## High
### Bugs (found in QA)
- [ ] The cursor does not blink.
- [ ] A long item: with many words that go on and on so that it is far longer than ninety letters. And notes
      that wrap onto a second line.
## Low
### Combat, later
- [x] Meters.
""")
check("read: titles", [c["title"] for c in cards][::2], ["The cursor does not blink.", "Meters."])
check("read: priority and area", [(c["priority"], c["area"]) for c in cards], [("high", "Bugs"), ("high", "Bugs"), ("low", "Combat")])
check("read: a long item's notes", cards[1]["notes"], "And notes that wrap onto a second line.")
check("read: ticked items are finalized", cards[2]["column"], "done")
json.loads(path.read_text())

print(f"board: all {checks} checks passed." if not failed else f"board: {failed} of {checks} checks failed.")
raise SystemExit(1 if failed else 0)
