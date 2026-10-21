#!/usr/bin/env python3
"""Qwen against FLUX.2 [dev], in motion: each model's chosen open window (a picture of qwen.txt or flux.txt) is
closed by the same model's edit (the leather cover shut, the shutters drawn, the banners rolled up), and Wan
2.2 14B paints the opening between the two, the closed window as its first frame and the open one as its last
(dev/imagegen/workflows/wan22-14b-flf-2ref.json). Writes the lists and runs them, the closing first.
  python3 dev/imagegen/sets/ui-compare/anim.py [view] [seed for qwen] [seed for flux]
"""
import os, subprocess, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
SET = "dev/imagegen/sets/ui-compare"
OUT = "assets/generated/ui-compare"
VIEW = sys.argv[1] if len(sys.argv) > 1 else "window"
SEEDS = {"qwen": sys.argv[2] if len(sys.argv) > 2 else "1", "flux": sys.argv[3] if len(sys.argv) > 3 else "1"}

# direction: how it looks closed, how it opens
MOTION = {
    "leather": ("the leather cover folded shut over it and its strap buckled, so only the closed leather book is seen",
                "the strap unbuckles and the leather cover swings open to the side, revealing the window inside"),
    "dwarven": ("two heavy iron shutters with cut runes closed over its inside, the frame unchanged",
                "the iron shutters slide apart to the sides with a puff of dust, the runes glowing briefly"),
    "heraldry": ("its cloth banners rolled up tight on their iron rod, nothing hanging below the rod",
                 "the banners unroll downwards from the rod and the window unfolds with them"),
    "gothic": ("heavy carved stone doors closed inside its arches",
               "the carved stone doors swing open inwards, revealing the window"),
    "elven": ("its silver vines grown together over the whole panel like a closed bud of silver leaves",
              "the silver vines and leaves unfurl and draw back to the frame, revealing the window"),
    "castle": ("an iron portcullis lowered over its opening",
               "the iron portcullis rises up into the stone, revealing the window"),
}
EDIT = {"qwen": ("qwen21-edit-1ref", "set: width=1280, height=960", 1),
        "flux": ("flux2dev-turbo-edit-2ref", "", 2)}


def run(path):
    subprocess.run(["dev/tools/imagegen", path], cwd=ROOT, check=False)


def main():
    for model, (wf, size, refs) in EDIT.items():
        lines = [f"# Written by anim.py: {model}'s {VIEW} windows closed by its own edit.", f"workflow: {wf}"]
        lines += [size] if size else []
        lines += ["count: 1", f"out: {OUT}/closed-{model}"]
        for d, (closed, _) in MOTION.items():
            pic = f"{OUT}/{model}/{d}-{VIEW}-{SEEDS[model]}.png"
            lines.append("ref: " + ", ".join([pic] * refs))
            lines.append(f"{d}: Edit image 1: show exactly the same window, at the same size and place over the same "
                         f"background, but closed: {closed}. Keep the style, the materials and the light exactly.")
        path = f"{SET}/closed-{model}.txt"
        open(os.path.join(ROOT, path), "w").write("\n".join(lines) + "\n")
        run(path)
    for model in EDIT:
        lines = [f"# Written by anim.py: {model}'s {VIEW} windows opening, from its closed picture to its open one.",
                 "workflow: dev/imagegen/workflows/wan22-14b-flf-2ref.json", "count: 1", "fps: 16",
                 f"out: {OUT}/anim-{model}",
                 "style: The camera, the background and the frame stay perfectly still; only the opening moves, smoothly "
                 "and quickly, and the clip ends on the open window."]
        for d, (_, opening) in MOTION.items():
            # the edit saves <name>-<seed>.png with the list's first seed
            lines.append(f"ref: {OUT}/closed-{model}/{d}-1.png, {OUT}/{model}/{d}-{VIEW}-{SEEDS[model]}.png")
            lines.append(f"{d}: A fantasy game window opens: {opening}.")
        path = f"{SET}/anim-{model}.txt"
        open(os.path.join(ROOT, path), "w").write("\n".join(lines) + "\n")
        run(path)


if __name__ == "__main__":
    main()
