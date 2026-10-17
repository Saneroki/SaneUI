#!/usr/bin/env python3
"""Tests of the voice database's rules (dev/tools/voicedb): the cast and the names read without errors,
and the words, the parts, the tone and the preset come out as Doc/guides/voice-generation.md says.
Needs no downloaded data. Run by dev/tests/run."""
import importlib.machinery
import importlib.util
import os
import sys

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
loader = importlib.machinery.SourceFileLoader("voicedb", os.path.join(HERE, "..", "tools", "voicedb"))
spec = importlib.util.spec_from_loader("voicedb", loader)
v = importlib.util.module_from_spec(spec)
loader.exec_module(v)

checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


presets, errors = v.read_cast()
check("cast reads", errors, [])
names, errors = v.read_names()
check("names read", errors, [])
for race in ("human", "dwarf", "gnome", "nightelf", "orc", "troll", "tauren", "undead"):
    for sex in ("male", "female"):
        for kind in ("common", "martial", "refined", "elder"):
            check(f"preset {race}-{sex}-{kind}", f"{race}-{sex}-{kind}" in presets, True)
for need in ("narrator", "reader", "crier"):
    check(f"preset {need}", need in presets, True)

# Words: placeholders and stage directions
say = lambda text, sex="male": v.speakable(text, sex)[0]
check("name with comma", say("Greetings, $N. Well met."), "Greetings. Well met.")
check("name first", say("$N, thank you."), "Thank you.")
check("name inside", say("I knew $N would come."), "I knew friend would come.")
check("class", say("A $c of your skill."), "An adventurer of your skill.")
check("player sex", say("Hello, $gsir:madam;!", "female"), "Hello, madam!")
check("line break", say("One.$BTwo."), "One. Two.")
check("stage direction", v.speakable("<She sighs.> It is late.", "male")[:2], ("It is late.", ["She sighs."]))

# Parts
one = "The first part is long enough to stand on its own, more than sixty characters."
two = "And the second part is long enough to stand on its own as well, here and now."
check("paragraphs", v.parts_of(f"{one}$B$B{two}"), [one, two])
check("short joins next", v.parts_of(f"And I don't mean farming.$B$B{two}"), [f"And I don't mean farming. {two}"])
check("direction joins", len(v.parts_of("<He sighs.>$B$BMy brother is gone, and nobody will say where.")), 1)
check("short end joins", len(v.parts_of(f"{one}$B$BThanks!")), 1)

# Tone and cadence
a = v.analyse("We must hurry, the Defias are burning the farms!", "offer", {})
check("urgent", (a["tone"], a["pace"]), ("urgent", "fast"))
check("grateful hand-in", v.analyse("You have my thanks.", "complete", {})["tone"], "grateful")
check("grief is soft", v.analyse("My brother was slain. Alas.", "offer", {})["volume"], "soft")
check("hostile yell", v.analyse("You will die!", "yell", {"side": "hostile"})["tone"], "menacing")
check("boss is all-out", v.analyse("You will die!", "yell", {"side": "hostile", "rank": "boss"})["intensity"], 5)
check("archaic", v.analyse("Thou art welcome here.", "gossip", {})["register"], "archaic")

# Names: whole words, with an 's after them, never inside another name
has = lambda name, text: bool(__import__("re").search(rf"(?<![A-Za-z']){__import__("re").escape(name)}(?![A-Za-z])(?!'(?!s\b))", text))
check("name alone", has("Onyxia", "Onyxia is near."), True)
check("name with 's", has("Onyxia", "Onyxia's Lair"), True)
check("name inside another", has("Kael", "Kael'thas rules"), False)

# Presets
p = lambda key, sp: v.preset_for(key, sp, presets, {})[0]
check("dwarf guard", p("npc:1", {"race": "dwarf", "sex": "male", "title": "Mountaineer"}), ["dwarf-male-martial"])
check("orc elder", p("npc:2", {"race": "orc", "sex": "female", "name": "Elder Crone"}), ["orc-female-elder"])
check("undead mage", p("npc:3", {"race": "scourge", "sex": "male", "class": "mage"}), ["undead-male-refined"])
check("mixed guards", p("npc:4", {"race": "human", "sex": "mixed", "title": "Guard"}),
      ["human-male-martial", "human-female-martial"])
check("ogre by model", p("npc:5", {"model": "ogre", "sex": "male"}), ["ogre-male"])
check("child by model", p("npc:6", {"model": "humanfemalekid"}), ["child-female"])
check("wanted poster", p("object:7", {"name": "Wanted Poster"}), ["crier"])
check("a book", p("item:8", {"name": "A Worn Journal"}), ["reader"])

# The voice tool (dev/tools/voicegen): what it sends and keeps, without the service
loader = importlib.machinery.SourceFileLoader("voicegen", os.path.join(HERE, "..", "tools", "voicegen"))
g = importlib.util.module_from_spec(importlib.util.spec_from_loader("voicegen", loader))
loader.exec_module(g)
quiet, loud = b"\0\0" * 500, (b"\xff\x3f" * 200)
keep = g.span(quiet + loud + quiet, 1000)
check("keeps the sound and a little quiet", (round(keep[0], 3), round(keep[1], 3)), (0.45, 0.849))
check("all quiet", g.span(quiet, 1000), (0.0, 0.5))
cfg = {"models": {"newest": {"id": "n", "sounds": True, "leave out": ["speed"], "stability steps": [0.0, 0.5, 1.0]},
                  "fast": {"id": "f", "leave out": ["next_text"]}}}
voices = {"presets": {"reader": {"voice": "v1"}}, "names": {"respellings": {"dictionary": "d", "version": "1"},
                                                            "sounds": {"dictionary": "s", "version": "1"}}}
r = {"text": "Hello.", "preset": "reader", "settings": {"stability": 0.62, "similarity": 0.8, "speed": 1.0},
     "previous text": None, "next text": "Bye.", "names": {}}
voice, body, shape = g.body_of(r, cfg, voices, "newest", 1)
fast = g.body_of(r, cfg, voices, "fast", 1)[1]
check("voice of the preset", voice, "v1")
check("stability in steps", body["voice_settings"]["stability"], 0.5)
check("stability as it is", fast["voice_settings"]["stability"], 0.62)
check("a setting left out", ("speed" in body["voice_settings"], "speed" in fast["voice_settings"]), (False, True))
check("neighbour sent", (body.get("previous_text"), body["next_text"]), (None, "Bye."))
check("a field left out", "next_text" in fast, False)
dictionaries = lambda b: [d["pronunciation_dictionary_id"] for d in b["pronunciation_dictionary_locators"]]
check("sounds first, then respellings", dictionaries(body), ["s", "d"])
check("respellings only", dictionaries(fast), ["d"])
check("same line, same hash", g.body_of(r, cfg, voices, "newest", 1)[2], shape)
check("another take", g.body_of(r, cfg, voices, "newest", 2)[2] != shape, True)
check("seed from the hash", body["seed"], int(shape[:8], 16))
newer = {**voices, "names": {"respellings": {"dictionary": "d", "version": "2"}}}
check("a new names list remakes nothing", g.body_of(r, cfg, newer, "newest", 1)[2], shape)
check("a name in the line remakes it", g.body_of({**r, "names": {"Elwynn": "Elwin"}}, cfg, voices, "newest", 1)[2]
      != shape, True)
rules = g.names_rules()
check("every name respelled", len(rules["respellings"]), len(names))
check("sounds where known", len(rules["sounds"]), sum(1 for n in names.values() if n["ipa"]))

print(f"Voices: {'all ' if not failed else ''}{checks - failed} of {checks} checks passed.")
sys.exit(1 if failed else 0)
