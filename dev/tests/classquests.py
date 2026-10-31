#!/usr/bin/env python3
"""The set ClassQuests against the master: every chain can be followed in the game, and every Forever character has chains.

Runs on the real master (the set is short and picked by hand, so a quest or NPC that goes away must not go unnoticed):
each chain's class plays its races, its quests are in Quests, each has a giver and a taker with a place in Spawns (or
an item that starts it), no two chains of one character share a quest, and each class and race has its chains.

Usage, from the project folder:  python3 -I dev/tests/classquests.py
"""
import collections
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DATA = os.path.join(ROOT, "assets", "data")

WARRIOR, PALADIN, HUNTER, ROGUE, PRIEST, SHAMAN, MAGE, WARLOCK, DRUID = 1, 2, 3, 4, 5, 7, 8, 9, 11
HUMAN, ORC, DWARF, NIGHTELF, UNDEAD, TAUREN, GNOME, TROLL, HIGH_ORDER, WINDSHAPER = 1, 2, 3, 4, 5, 6, 7, 8, 95, 96
# Who plays what in Forever: the game's own table of a race's classes, and each race's side.
PLAYS = {
    HUMAN: {WARRIOR, PALADIN, ROGUE, PRIEST, MAGE, WARLOCK, HUNTER},
    ORC: {WARRIOR, HUNTER, ROGUE, SHAMAN, WARLOCK, MAGE},
    DWARF: {WARRIOR, PALADIN, HUNTER, PRIEST, ROGUE, SHAMAN},
    NIGHTELF: {WARRIOR, HUNTER, ROGUE, PRIEST, DRUID},
    TAUREN: {WARRIOR, HUNTER, SHAMAN, DRUID},
    UNDEAD: {WARRIOR, ROGUE, PRIEST, MAGE, WARLOCK, PALADIN},
    GNOME: {WARRIOR, ROGUE, MAGE, WARLOCK, PRIEST},
    TROLL: {WARRIOR, ROGUE, HUNTER, PRIEST, SHAMAN, MAGE, WARLOCK},
    HIGH_ORDER: {HUNTER, ROGUE, WARRIOR, MAGE, DRUID},
    WINDSHAPER: {HUNTER, ROGUE, SHAMAN, WARRIOR, DRUID},
}
SIDE = {HUMAN: "alliance", DWARF: "alliance", NIGHTELF: "alliance", GNOME: "alliance", HIGH_ORDER: "alliance",
        ORC: "horde", UNDEAD: "horde", TAUREN: "horde", TROLL: "horde", WINDSHAPER: "horde"}


def lines(name):
    """The first version of each entry of a set's master file, with the fixes laid over it."""
    folder = os.path.join(DATA, name)
    entries = {}
    for line in open(os.path.join(folder, name + ".jsonl"), encoding="utf-8"):
        record = json.loads(line)
        entries.setdefault(record["key"], {}).update(record)
    fixes = os.path.join(folder, "fixes.jsonl")
    if os.path.exists(fixes):
        for line in open(fixes, encoding="utf-8"):
            if line.strip():
                record = json.loads(line)
                entries.setdefault(record["key"], {}).update(record)
    return entries


def main():
    chains, quests, spawns = lines("ClassQuests"), lines("Quests"), lines("Spawns")
    wrong = []
    count = 0

    def check(condition, what):
        nonlocal count
        count += 1
        if not condition:
            wrong.append(what)

    mine = collections.defaultdict(list)  # (race, class): its chains
    for key, chain in sorted(chains.items()):
        for race in chain.get("races") or PLAYS:
            if chain["class"] in PLAYS[race] and chain.get("side", SIDE[race]) == SIDE[race]:
                mine[race, chain["class"]].append(chain)
        for race in chain.get("races") or ():
            check(chain["class"] in PLAYS[race], f"chain {key}: its class does not play race {race}")
            check(chain.get("side", SIDE[race]) == SIDE[race], f"chain {key}: race {race} is of the other side")
        check(key // 100 == chain["class"], f"chain {key}: its number says another class")
        for quest in chain["quests"]:
            record = quests.get(quest)
            check(record is not None, f"chain {key}: quest {quest} is not in Quests")
            if not record:
                continue
            check(not record.get("gone") and not record.get("retired"), f"chain {key}: quest {quest} is gone")
            givers = [("npc:%d" % each["npc"]) for each in record.get("startNPCs", [])]
            givers += [("object:%d" % each["object"]) for each in record.get("startObjects", [])]
            takers = [("npc:%d" % each["npc"]) for each in record.get("finishNPCs", [])]
            takers += [("object:%d" % each["object"]) for each in record.get("finishObjects", [])]
            check(givers or record.get("startItems"), f"chain {key}: quest {quest} has no giver")
            check(takers, f"chain {key}: quest {quest} has no taker")
            check(not givers or any(giver in spawns for giver in givers), f"chain {key}: quest {quest}'s giver has no place")
            check(any(taker in spawns for taker in takers), f"chain {key}: quest {quest}'s taker has no place")
        for quest in chain.get("also", ()):
            check(quest in quests, f"chain {key}: quest {quest} is not in Quests")

    for (race, class_), list_ in sorted(mine.items()):
        seen = set()
        for chain in list_:
            for quest in chain["quests"]:
                check(quest not in seen, f"race {race}, class {class_}: quest {quest} in two chains")
                seen.add(quest)
    for race, classes in PLAYS.items():
        for class_ in classes:
            check(mine[race, class_], f"race {race}, class {class_} has no chain")

    for what in wrong:
        print("FAILED:", what)
    if wrong:
        sys.exit(1)
    print(f"Class quests' data: all {count} checks passed, {len(chains)} chains")
    return mine


if __name__ == "__main__":
    main()
