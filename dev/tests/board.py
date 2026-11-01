#!/usr/bin/env python3
"""Tests of dev/tools/board on a board of its own: cards made, edited, moved before others and to a column's
top, deleted; the log; a card's count of changes, and a change with an old count refused; Backlog.md as text; a
ranked Markdown list read in; Review and Finalized refused on the command line. Run by dev/tests/run."""
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
check("Backlog.md names the page", "127.0.0.1 port 8768" in text and "/board/" in text, True)

# changes counts a card's steps; the page sends the count back, and a card changed meanwhile is refused.
with board.changing(path) as b:
    board.apply(b, {"op": "add", "title": "counted"}, "Claude")
    board.find(b, 4).pop("changes", None)   # a card from before the count
b = board.read(path)
check("changes counts a card's steps", board.find(b, 5)["changes"], 1)
try:
    board.apply(board.read(path), {"op": "edit", "id": 5, "title": "stale", "changes": 0}, "Saneroki")
    check("an edit with an old count is refused", False, True)
except ValueError as error:
    check("an edit with an old count is refused", "changed meanwhile" in str(error), True)
with board.changing(path) as b:
    board.apply(b, {"op": "edit", "id": 5, "title": "fresh", "changes": 1}, "Saneroki")
    board.apply(b, {"op": "edit", "id": 4, "notes": "old card", "changes": 0}, "Saneroki")
    board.apply(b, {"op": "edit", "id": 5, "notes": "the command line sends no count"}, "Claude")
b = board.read(path)
check("an edit with the count as it is goes through, and counts", (board.find(b, 5)["title"], board.find(b, 5)["changes"]), ("fresh", 3))
check("a card without the field counts as 0", (board.find(b, 4)["notes"], board.find(b, 4)["changes"]), ("old card", 1))
for name, op in (("a move with an old count", {"op": "move", "id": 5, "column": "done", "changes": 2}),
                 ("a delete with an old count", {"op": "delete", "id": 5, "changes": 2})):
    try:
        board.apply(board.read(path), op, "Saneroki")
        check(name + " is refused", False, True)
    except ValueError:
        check(name + " is refused", True, True)
with board.changing(path) as b:
    board.apply(b, {"op": "delete", "id": 5, "changes": 3}, "Saneroki")
check("a delete with the count as it is goes through", [c["id"] for c in board.read(path)["cards"]], [4, 1, 3])

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

before = path.read_text()
for name, argv in (("review", ["review", "1"]), ("done", ["done", "1"]), ("move", ["move", "1", "Review"]),
                   ("add", ["add", "new", "--column", "done"])):
    try:
        board.main(argv)
        got = "went through"
    except SystemExit as error:
        got = str(error.code)
    check(f"the command line refuses: {name}", got, "board: Review and Finalized are Saneroki's to move, on the board's page")
check("nothing written by a refusal", path.read_text(), before)

print(f"board: all {checks} checks passed." if not failed else f"board: {failed} of {checks} checks failed.")
raise SystemExit(1 if failed else 0)
