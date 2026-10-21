# Image generation

How Sane UI's art is made with image models on this computer: one pipeline from a first idea to the
game's textures, for still parts and for animated ones, so that every set of pictures looks like Sane UI.
Whether to draw our own art at all is in [gui-development.md](gui-development.md), *Art*: Blizzard's
atlases and files come first. What a finished picture becomes (BLP, sizes, `dev/tools/art`) is in
[images.md](images.md).

**Status (2026-10-17):** ComfyUI and its models run on this computer, and every recipe was tried with
the example set (`dev/imagegen/sets/example/`): a concept, parts cut out of it, a looping glow of one part
packed as a flipbook, and an effect. The times were measured here. Not tried yet: a flipbook in the game,
and a frame cut for stretching.

## The pipeline at a glance

| Step | What comes out | Recipe | Model, image 1 | Time | Then |
| --- | --- | --- | --- | --- | --- |
| 1. Concept | the whole window or panel as one picture | `concept` (`concept-free`) | Qwen 2.1 turbo edit, the house's anchor | 8 s | choose one: `assets/Concept art/<Set>/concept.png`, the set's anchor |
| 2. Parts | each part alone, on a transparent background | `part` (`part-new`, `part-clean`) | Qwen 2.1 turbo edit, the set's concept | 8 s | choose: `assets/<Set>-<part>.png` |
| 3. Animation, if any | a clip of frames | `anim` (`anim-5b`, `effect`) | Wan 2.2 14B, the chosen part; Wan-Alpha | 1 min | `dev/tools/flipbook`: a sheet in `assets/` |
| 4. Finish in code | the game's textures | | | | slicing, `dev/tools/art`, the module |

Each step is the same: run a list, look at its `contact.png`, choose, copy the chosen picture to where
the next step reads it. **Models make, code finishes:** exact sizes, symmetry, slicing, the hover and
pressed looks and most motion are made in code, from the chosen pictures.

## What keeps a set alike

1. **The house style:** `dev/imagegen/style.txt` holds the look in words, made from
   [interface-style.md](interface-style.md), and its picture is the anchor,
   `assets/Concept art/UI style/edges-and-buttons.png`. Every concept is made from the anchor, so a new set looks
   like the old ones.
2. **One concept per set, every part from it.** A part cut out of the concept keeps its light, colours
   and rim width; parts made one at a time drift apart.
3. **Recipes:** each step's workflow, settings and fixed words are in one file
   (`dev/imagegen/recipes/`). A set's lists include them and say only what to make.
4. **The same seeds:** every prompt runs through seeds 1, 2, 3 ...; a picture is made again by its seed.
5. **Choose, don't repair:** several seeds a part, keep the best one. Change the words, not the pixels.
6. **Every picture is on record:** `imagegen.jsonl` beside it holds its prompt, seed, workflow, settings
   and references, and ComfyUI writes its whole graph into the PNG. Note the chosen ones in the set's
   list (`# chosen: star-2`).
7. **The house style changes only on purpose:** sets made before and after a change look different.

## ComfyUI on this computer

Installed in `/data/Projects/ImageGen` (ComfyUI 0.41, Python 3.13, PyTorch for CUDA 13, RTX 4070 Ti
with 12 GB, 61 GB of RAM). The command `comfyui` runs it:

| | |
| --- | --- |
| `comfyui start` | start it in the background (`comfyui` alone also opens it in the browser, `127.0.0.1:8188`) |
| `comfyui stop` | stop it: frees the graphics card. Stop it before playing. |
| `comfyui status`, `comfyui log` | running or not, its graphics memory; its output (look here when a job fails) |
| `comfyui models` | download the models that are missing |
| `comfyui update` | the newest ComfyUI |

It answers only this computer, and runs with `--fast-disk` (the models are read from the disk instead of
held in RAM, which leaves 18 GB free during a 14B clip). How it is set up, the downloads and what is
backed up: `/data/Projects/GArch/SystemConfigs/ImageGen/README.md`.

### The models

Measured here on 2026-10-17, one picture after the model is loaded (the first of a run adds 5 to 20 s).

| Model | Use it for | Workflows | Time |
| --- | --- | --- | --- |
| **Qwen-Image 2.1** (int8, and Turbo) | The main one: reference pictures, transparent PNGs, up to 2048 px | `qwen21-t2i`, `qwen21-turbo-t2i`, `qwen21-edit-1ref` / `-2ref`, `qwen21-turbo-edit-1ref` / `-2ref` | Turbo 6-8 s, full 15-18 s |
| **FLUX.2 [klein] 4B** | Fast variations, good light on metal and gems. No real transparency. | `klein4b-t2i`, `klein4b-edit-1ref` / `-2ref` | 3 s |
| **Z-Image Turbo** | Fast drafts from words alone | `zimage-turbo-t2i` | 5 s |
| **SDXL**, DreamShaper XL Turbo | A painted look; it ignored "the inside empty" in the test. Later: seamless tiling, our own style trained (extension packs, not installed). | `sdxl-dreamshaper-t2i` | 5 s |
| **FLUX.2 [dev]** (fp8, Turbo LoRA) | A few best pictures. The only one that put all the ornament into the corners with plain mouldings between them unasked: good for frames that stretch. RAM runs nearly full: only with no game running. | `flux2dev-turbo-t2i`, `flux2dev-turbo-edit-2ref` | 57 s with loading |
| **Wan 2.2 TI2V 5B** | A part comes alive quickly | `wan22-5b-i2v-1ref`: 704 x 704, 49 frames, 24 fps | 59 s a clip |
| **Wan 2.2 14B**, first and last frame | The same as a true loop | `wan22-14b-loop-1ref`: 640 x 640, 49 frames, 16 fps | 61 s a clip |
| **Wan-Alpha** (Wan 2.1 14B, RGBA) | An effect on its own, with real transparency | `wan-alpha-t2v`: 832 x 480, 33 frames, 16 fps | 48 s a clip |
| **BiRefNet**, **FILM** | Cut a picture out of its background; frames in between | ComfyUI's templates *Remove Background*, *Frame Interpolation* (not in the batch tool) | |

### Workflows

The ready workflows are in `/data/Projects/ImageGen/workflows/`, made from ComfyUI's own templates, in
the API form the batch tool sends. Each has `{prompt}` in its prompt, `imagegen/{name}` as Save Image's
prefix, and its Load Image nodes titled `ref1`, `ref2`. A list names one by its name (`workflow:
qwen21-turbo-edit-1ref`); `dev/imagegen/workflows/` is looked in first, for workflows of our own.

**Making a workflow of our own:**

1. Open the model's template in ComfyUI and make one picture with it, to be sure it works.
2. Write `{prompt}` into the prompt's text box. A fixed sentence around it stays.
3. Write `imagegen/{name}` into Save Image's *filename_prefix*.
4. For references: one Load Image node per picture, titled `ref1`, `ref2`, ... (double-click a node's
   title to rename it), wired as in the template.
5. Menu *Workflow* > *Export (API)*, saved as `dev/imagegen/workflows/<model>-<task>.json`.

## The house style

The look of Sane UI's own windows is decided in [interface-style.md](interface-style.md) (Saneroki,
2026-10-21): an adventurer's journal of parchment and stitched leather, pencil on the paper; Saneroki's
decisions go there. `dev/imagegen/style.txt` is that look in one `style:` line for parts, put after every
prompt of the recipes that make interface art (`concept`, `concept-free`, `part-new`): flat front view, light
from the top left, no text, no stains, no sketches (code lays those over). Its picture, the anchor, is
`assets/Concept art/UI style/edges-and-buttons.png` (its edges, title strap and patch buttons were picked); the
recipe `concept` gives it as image 1. The parts and views of Sane UI's own windows are made by the strict
harness in `dev/imagegen/sets/interface/` ([interface-style.md](interface-style.md), *The harness*): each part
from its crop of a pick, the views laid out in code.

The older bronze house style and the exploration that led to the journal look are archived outside the project.

## The recipes

In `dev/imagegen/recipes/`, each a list without prompts: a set's list includes one and adds its own.

| Recipe | For | Workflow | Count | Image 1 |
| --- | --- | --- | --- | --- |
| `concept` | the whole thing, in the house style | `qwen21-turbo-edit-1ref`, 1536 x 1024 | 8 | the house's anchor |
| `concept-free` | a new look, from words alone | `zimage-turbo-t2i`, 1536 x 1024 | 8 | |
| `part` | a part cut out of the concept | `qwen21-turbo-edit-1ref`, 1024 x 1024 | 4 | the set's concept |
| `part-new` | a part the concept lacks, in its style | the same | 4 | the set's concept |
| `part-clean` | a piece cut out of the concept by hand, made clean | the same | 4 | that piece |
| `anim` | a part comes alive, a loop of 3 s | `wan22-14b-loop-1ref` | 2 | the chosen part, on black |
| `anim-5b` | the same, not a loop, 2 s | `wan22-5b-i2v-1ref` | 2 | the chosen part, on black |
| `effect` | an effect on its own, transparent | `wan-alpha-t2v` | 2 | |

What the words in them are for, found while making the example set:

- **An edit model changes image 1** unless told otherwise. For something new: "Use image 1 only as a
  reference for the style, materials, colours ... and do not show anything from image 1."
- **Cutting a part out:** "Isolate one element of image 1 as a game asset: keep only *the star inside
  the round medallion on the left*. Remove *the medallion, the plate* and everything else." Without the
  house style: its words about panels brought the whole concept back, and so did "create a new picture
  of one single part". In the test 3 of 3 stars came out alone, 1 of 3 medallions: hence several seeds,
  and `part-clean` for what the model does not find (cut a rectangle around it in any picture editor).
- **Transparency:** Qwen's sentence comes first (the part recipes have it): *This is an RGBA format image
  with transparency. It has an alpha channel and a transparent background.* Turbo and full both give real
  alpha. A faint haze (alpha 1 to 8 of 255) stays around a part: invisible, and `dev/tools/art` crops
  above it.
- **Fill the picture:** "small" gives a tiny part on a large empty picture.
- **Turbo first:** the recipes use Qwen's turbo model (8 s). For the very best, run the chosen words again
  with `--workflow qwen21-edit-1ref` (25 steps): another model, so other pictures for the same seeds.

## A set, step by step

A set is a folder `dev/imagegen/sets/<set>/` with a list per step. To start one, copy
`dev/imagegen/sets/example/` and change its names and prompts. What the models make goes into
`assets/generated/<set>/<step>/` (not committed); the chosen pictures are copied out of it.

1. **Concept.** `concept.txt` says what the whole thing is. Run it, look at `contact.png`, copy the
   chosen one to `assets/Concept art/<Set>/concept.png`:

   ```bash
   dev/tools/imagegen dev/imagegen/sets/example/concept.txt
   ```

2. **Parts.** `parts.txt` names each part as it is in the concept (recipe `part`), `parts-new.txt` the
   parts it lacks (recipe `part-new`). Run, choose, copy each chosen one to `assets/<Set>-<part>.png`:

   ```bash
   dev/tools/imagegen dev/imagegen/sets/example/parts.txt
   ```

3. **Animation** (only for what code cannot move, see *Animation*). `anim.txt` says what moves in a
   chosen part. Run, choose a clip by its `.gif`, pack it:

   ```bash
   dev/tools/imagegen dev/imagegen/sets/example/anim.txt
   ```

   ```bash
   dev/tools/flipbook assets/generated/example/anim/star-glint-1 assets/Example-star-glint.png --loop drop-last --glow --fps 16 --drawn 24
   ```

4. **Finish in code:** cut what stretches (*From a picture to pieces*, below), add each picture to
   `dev/tools/art` and ship it as [images.md](images.md) says.

## The list

A list is a text file, one line each. `dev/tools/imagegen`'s head says the same.

| Line | Means | Holds for |
| --- | --- | --- |
| `# ...` | a comment | |
| `include: <file>` | that file's lines, as if written here (a recipe, the house style) | |
| `workflow: <name or file>` | the workflow | the whole list |
| `set: steps=25, width=1024` | inputs of the workflow, set by name in every node | the whole list; adds up |
| `count: 4`, `seed: 1` | pictures per prompt; the first seed | the whole list |
| `out: <folder>` | where the pictures are saved; the tool waits for them | the whole list |
| `fps: 16` | a clip's frame rate, for its preview | the whole list |
| `flatten: #000000` | reference pictures with transparency are laid on this colour (Wan takes no alpha) | the whole list |
| `before: <text>` | put before every prompt | the prompts after it |
| `style: <text>` | put after every prompt | the prompts after it |
| `ref: <file>, <file>` | the reference pictures, image 1, image 2 (PNG, JPG, or the game's BLP) | the prompts after it |
| `<name>: <text>` | one prompt: its name (letters, digits, `-`, `_`) and what to make | |

For the whole list, the last line counts; for the prompts after it, a new line replaces it and an empty
one ends it. Paths are from Sane UI's folder.

## Running it

```bash
dev/tools/imagegen dev/imagegen/sets/example/parts.txt --count 2 --only star
```

- `--count`, `--seed`, `--out`, `--set key=value`, `--workflow` win over the list; `--only a,b` runs
  only those prompts; `--dry-run` prints the prompts as they will be sent.
- The old form takes the workflow first: `dev/tools/imagegen <workflow.json> <list.txt>`.
- **What it saves** in the list's `out:` folder:

  | File | What |
  | --- | --- |
  | `<name>-<seed>.png` | a picture |
  | `<name>-<seed>/001.png` ... | a clip's frames, for `dev/tools/flipbook` |
  | `<name>-<seed>.gif` | a clip's preview, at its speed |
  | `contact.png` | this run's pictures side by side, a row per prompt, a column per seed, on a checkerboard where they are clear |
  | `imagegen.jsonl` | how each was made, a line each |

- Without an `out:` the tool returns once all is queued, and the pictures stay in ComfyUI's
  `output/imagegen/`. ComfyUI keeps a copy there in any case: clear it now and then.
- Ctrl+C stops the waiting, not ComfyUI: clear its queue there (*Queue* panel).

## The GPU runner

The card is also the game's. Long work (the Atlas, a big set) goes to `dev/tools/gpu-runner`, the queue of
ComfyUI renders, which runs it by priority only while the card is idle and gives the card back the moment
something else wants it. Saneroki runs it as `saneui start gpurunner` / `saneui stop gpurunner`, sees the queue
with `saneui gpuqueue` and changes the job at work with `saneui switch <job>` (Saneroki, 2026-10-21).

- **The jobs:** `dev/imagegen/jobs.toml`, one `[[job]]` each: a `name`, a `priority` (higher first) and the
  `command` of a tool, optionally a `status` command and a `done` pattern for its output (the Atlas:
  `dev/tools/atlas status`, `'^(\d+) of \1 squares painted'`). The runner reads the file at every look and runs
  the most important unfinished job; stopped, it runs the same command again later. A job more important than
  the one at work (a new one in the file, a switch) takes over at once: the one at work is stopped as for the
  game, its progress kept, and comes back when its turn comes. The Atlas goes on where it
  stopped (it skips the squares it has painted); `dev/tools/imagegen` makes its whole list again, so give the
  runner short lists. Long runs go into the file only on Saneroki's word; the Atlas' close squares are in it
  (Saneroki, 2026-10-21).
- **New GPU work goes here:** a tool that runs long on the card is added as a job (with `status` and `done`
  when it can tell how far it is, and skipping what it has made when run again), never started by itself
  next to the runner. Its command also gets its name in `dev/saneui` (README.md, *Building*).
- **Every render plan is in the queue (Saneroki, 2026-10-21):** a session that adds or changes a render plan
  (a set's lists in `dev/imagegen/sets/`, such as the UI looks of `ui-explore/` and `ui-style/`, a map's
  plan, a job's words or workflow) adds or updates its job in `dev/imagegen/jobs.toml` in the same commit: a
  `name`, a `priority` (the Atlas' close squares are 10; above it what Saneroki waits for, below it what can
  wait; ask Saneroki when unclear; the dungeons' paintings are 2, and the redesigns of interface parts, such as
  the map pins, the route line and the raid markers, go above them when they are queued: Saneroki, 2026-10-21) and a `rebuild` command when the plan's change has to start it anew. A
  finished job whose plan changed is let go again with `saneui switch <job>` or `saneui rebuildstart <job>`
  when it should run now, else `dev/tools/gpu-runner reset <job>`. Quick tries of a few pictures while a
  session works on a look need no job (their pictures in ComfyUI's queue make the runner yield); what is left
  to render when the session ends goes in as a job.
- **The switch:** `saneui switch <job>` makes the job run now: held, finished or failed, it is let go again;
  the job at work is stopped with its progress kept (the Atlas keeps every square painted and its own plan);
  the runner is started if it is not running, and skips its three minutes' hold. The job switched to stays
  first, also after the game or a claim took the card, until it is finished or another is switched to; then
  the priorities rule again (`saneui switch --back` at once). `saneui rebuildstart <job>` rebuilds the job's
  plan and its ComfyUI instructions first (`saneui rebuild`), then switches to it.
- **Wanted elsewhere:** the game (`Wow*.exe`; WoW Forever is `WowB.exe` under Proton); another program on the
  card holding more than 1.5 GB of it, or using more than 40 % at three looks in a row (the desktop's own
  programs never count); pictures of another session or tool in ComfyUI's queue (the runner gives its jobs an
  `IMAGEGEN_CLIENT`, which `dev/tools/imagegen` and the Atlas send with each picture); a claim; a pause by hand.
- **Then:** the job is stopped at once (the Atlas drops the picture being painted and keeps every square
  finished), its pictures leave ComfyUI's queue (by their id: never another's) and the card is freed: ComfyUI
  stopped if the runner started it and nobody else used it meanwhile, else told to let go of its memory, as the
  Atlas' `p`. With the card free for three minutes (`hold`, after its own start too), the runner goes on: an
  alt-tab or a restart of the game does not start it again.
- **Another session or tool that needs the card** claims it:

  ```bash
  dev/tools/gpu-runner claim my-test -- dev/tools/imagegen dev/imagegen/sets/example/parts.txt --count 1
  ```

  runs the command once the runner has given the card back, and releases the claim after it.
  `claim NAME --wait` and `release NAME` do the same around several steps; a file in
  `$XDG_RUNTIME_DIR/saneui-gpu/claims/` is a claim too (`touch` it, `rm` it; a process id as its first line ends
  the claim with that process). A short ComfyUI job of a session needs no claim: its pictures in the queue are
  enough.

| | |
| --- | --- |
| `dev/tools/gpu-runner install` / `uninstall` | the runner as the user service `saneui-gpu-runner`: started now and at every login, standing by while the card is busy (installed 2026-10-21) |
| `saneui start gpurunner` / `stop gpurunner` | the runner at work through the queue (the service) / stopped, its job's progress kept, the card freed |
| `dev/tools/gpu-runner run` | the runner in this terminal (Ctrl+C stops it) |
| `saneui pause gpurunner` / `resume gpurunner` | held by hand (the job stopped, the card freed) / going on after the hold |
| `saneui gpuqueue` (`saneui status gpurunner`) | what it does or why it waits, the claims, the queue in the order it runs: priority, progress, which runs now and which next, the held, finished and failed |
| `saneui switch <job>` / `switch --back` | that job now, first until it is finished, the one at work kept for later / the priorities again |
| `saneui rebuildstart <job>` | `rebuild`, then `switch` |
| `dev/tools/gpu-runner reset NAME` | a job finished or left after three failures runs again when its turn comes |
| `saneui hold NAME` / `unhold NAME` | a job kept from running (stopped if it runs), across restarts, the others going on (`--why TEXT`) |
| `saneui rebuild NAME` | the job anew with the plans as they are (its `rebuild` command; the Atlas: the run so far put aside in `assets/generated/atlas-runs/`); without it the job goes on with its own plan |

A pause by hand, the holds and the switch (`first.json`) are kept there too, so they last over a restart. **The Atlas' plan:** a run
paints with the words, zone briefs and workflow it began with (a copy in the run's `plan/`, made at its first
paint; `dev/tools/atlas status` says when the plans have changed since), so new rules never mix into a run under
way: they take effect with `saneui rebuild atlas`.

Its log is `~/.local/state/saneui/gpu-runner/runner.log`, each job's output `<name>.log` beside it. The limits
and the hold are set at the head of `jobs.toml`.

## Maps

Navigation's painted map view (`Doc/ideas/Navigation.md`, *The painted view*) is made with the same tool and
lists, from inputs of its own:

- **Guides from the game's files:** `dev/tools/map-meta` writes the roads, the standing buildings, the ground
  cover and `places.json` (areas, city districts, flight masters, entrances, caves and mines, exits) to
  `assets/generated/maps/meta/`; `dev/tools/terrain-art` makes the terrain and the stitched Sketches.
- **Zone briefs:** `dev/imagegen/maps/zones.toml`, one table a zone or city: biome, land, plants, colours,
  buildings, roads, places, mood, atmosphere and a prompt paragraph, all without names. A square's words take
  only the zone's colours and the light of its atmosphere (its first sentence), never its buildings, plants,
  places, features or props: the model paints whatever the words name into the square it is given.
- **One picture a square, the look in words:** image 1 the terrain of the square (the layout and everything on
  it, kept; `qwen21-edit-1ref`; the Atlas at 2048 x 2048, one tile, with `resolution=2048` so the reference
  is read at the painting's size; the minimap textures softened a little first, or their dot pattern comes
  back). A picture of
  the look as image 2, even "only as a reference for the art style", was painted instead of image 1 when it
  showed the same place from further out. The look pilot (`looks.txt`) gave image 2 the softened Sketches of
  the square, for painted continent maps.
- **No names, anywhere the model can read them:** a place's name in the words, or a label it can read in
  image 2, comes back as garbled lettering in the picture. Describe ("a mine mouth in the hills at the bottom
  left"), never name.
- **Say what the game has:** without "the flat dark blue areas of image 1 are the sea …, no land or paper where
  image 1 has water" the parchment looks painted the sea over as land; with "the flat dark blue areas are
  water" and nothing of the kind in the square, the photorealistic look painted Blackrock's dark ash plain as
  lakes between islands. So each square's words say which liquids the game has in it ("there is no water
  anywhere in this picture", "the flat bright orange areas are molten lava"), and every painting is checked
  against the game's water and lava (Navigation.md, *Checked against the game*).
- **Words of an edit keep a picture faithful:** "make image 1 look like a photograph of exactly the same
  place; change only how things look, never where or what anything is" kept the layout of 8 of 8 hard places,
  where "repaint image 1 as …" kept 2 (the Atlas lab, Navigation.md, *The lab*). Words that name features,
  props or buildings bring them into the picture; give colours and light instead. Words of motion bring their
  traces too: lava "smoking" drew a cloud of smoke over it.
- **Colours drift with the light:** a zone's light words shift its colours (orange ground painted tan), more for
  a whole zone in one picture than for a close square. Fix them after the painting, not in the words: the
  Atlas' colour pass moves the painting's broad colour back toward the game's and keeps its detail.
- **Straight from above:** "like an orthographic satellite image: no perspective, no tilt, no horizon" keeps
  mountains from turning into cones seen at an angle.
- The pilots: `dev/imagegen/sets/maps-pilot/looks.txt` (five looks on two squares, 20 pictures in 9 minutes with
  the full model), `close.txt` (the stylised look on the terrain, close up), `dev/imagegen/sets/maps-styles/`
  (five styles; chosen: the photorealistic render), `dev/imagegen/sets/maps-atlas/pilot.txt` (that look, one
  square of ten zones at 2048, each in its zone's atmosphere; about two and a half minutes a picture).
- **The Atlas' run:** `dev/tools/atlas` paints every square of both continents from these, checks it against the
  game's water and keeps the best of three seeds; `--near` paints a few squares around a place first, `join`
  stitches them, each through the colour pass (`--mood`); in a terminal it shows its progress, `p` pauses (and frees the graphics card), `q` quits; the whole run goes
  to the GPU runner (*The GPU runner*), which paints only while the card is idle.
- **The three levels, the world's and the instances' alike** (`dev/tools/map-layers`, `saneui makemaplayers`;
  [map-style.md](map-style.md); Saneroki, 2026-10-21: strict maps of the layout, not free concept art): each subject
  (a zone, an instance, an instance's floor) has one frame, its box in the world, that its three levels share.
  - **Inputs** (`map-layers inputs`): the terrain plan of the frame, from the game's minimap textures (an
    instance's from its own map's tiles, with the indoor maps of the buildings its object files place laid over
    them, placed as Navigation places indoor maps: the instances' terrain is extracted into a folder of its own,
    so the continents' tools never read it); the game's map art in the same frame (a zone's full map with its
    explored parts; an instance floor's map, its title banner painted over; Forever's new dungeons have none, so
    another dungeon's map gives only its manner).
  - **Close:** the Atlas' own squares, words, water and lava check (up to three seeds) and colour pass, by its own
    code (`dev/tools/atlas`'s `Game`, `words`, `check`, `colour_of`), an instance's map in place of a continent.
  - **Middle** (`qwen21-edit-3ref-i2i`: image to image, starting from image 1 itself): image 1 the game's map
    art, image 2 the terrain plan, image 3 a piece of the house parchment (where the game has no map, image 1 the
    plan and image 2 another place's map for its manner); edit words, no brief; strength 0.94, 0.96 (one step
    skipped, two seeds), then 0.98 (none) (at 0.8 and 0.88, six and three skipped, the Deadmines' map stayed the
    game's coloured map, labels and all).
  - **Far** (from noise, its layout held by controls: the Fun ControlNet Union, `QwenImageDiffsynthControlnet`):
    image 1 the place seen from a plane at an angle, blurred and toned down to where each land lies, image 2 a piece
    of the close level; a photograph of the landscape, its layout kept roughly. A zone (`qwen21-edit-2ref-i2i-cn2`):
    image 1 the game's terrain with its heights standing up (`relief`: the terrain files' heights under the minimap
    textures, drawn as the voxel spaces of old drew land, 6 s a zone), its water a sea's blue; the controls its depth
    (0.7 to 60 % of the steps) and the lines where the walking data's water meets land (0.6 to 50 %); its words name
    the zones around it. An instance (`qwen21-edit-2ref-i2i-cn`): image 1 its plan warped into the view
    (`plane_view`; its halls lie under rock, which a relief would show), the control its clear edges. Learned on
    Westfall: the middle drawing as a picture had its pencil symbols stamped on the land; the sharp view as image 1
    came back as the game's own terrain, read at 512 pixels too; the walking data's barriers as lines came back as
    lakes; without controls the model painted a closer view than the frame. Its outlines must share FAR (0.3) with
    the sharp view, a zone's water agree with the walking data's.
  - **Strength is in steps:** ComfyUI's KSampler runs int(steps / denoise) steps and skips the first ones beyond
    `steps`: with 25 steps a denoise from 0.927 to 0.961 skips one, above it none, so 0.93 and 0.96 make the same
    picture and 0.97 is a painting from noise. Choose a denoise by the steps it skips.
  - **Memory:** the pictures are read for the words at about 1024 pixels (`resolution`); the painting keeps image
    1's 2048. Three pictures read at 2048 by the vision-language encoder took ComfyUI past the computer's memory.
  - **Checks**, a painting that fails painted again, three tries at most: its outlines against image 1's (the
    normalised correlation of their edges at 256 pixels across, against how well the game's own map agrees with
    the terrain: a middle level must reach three quarters of it, a far one under half), and the vision model.
  - The words: `levels.toml` (middle, far) and `atlas.toml` (close), with the briefs of `zones.toml` and
    `dungeons.toml`.
- **The check by a vision model** (`dev/imagegen/workflows/qwen3vl-look.json`): ComfyUI's `TextGenerate` with the
  Qwen3-VL model the image model reads its words with looks at a picture and answers questions in JSON, about six
  seconds a picture with no other model to load. The map levels ask about writing, a pencil map seen from above
  (middle), and a real place, not a map or panels, seen from above, of the brief's kind (far). Tried on the first
  dungeon paintings (2026-10-21): it caught a plan painted flat, a city painted as four panels and a cave painted
  from inside in a reference picture's own view (a second picture may be copied instead of followed: its words say
  what is taken from it, and the check catches it when it is not).
- **Upscaling models** (`models/upscale_models/` of ImageGen: 4x-UltraSharpV2 and 4xNomos2, both DAT2, as
  safetensors, 17 s for 1024 to 4096): they sharpen what is there, the faults too, and add no detail; the
  painting is made at the size it is shown.

## Asking for interface art

- **Say the view:** "flat front view, no perspective, even light from the top left" (the house style).
- **Say what is not wanted, in the prompt:** "no text, no letters". The Qwen workflows run at CFG 1,
  where a negative prompt does nothing.
- **Frames empty inside:** "the inside is empty and transparent". The fill is a texture of its own.
- **Symmetric:** ask for it, then make it exact in code (mirror the left half onto the right).
- **Chunky, readable shapes:** interface parts are drawn small in the game (a corner of 20 to 40 UI
  units); fine detail turns to noise at that size.
- **Large:** 1024 to 2048 pixels; `dev/tools/art` shrinks it with care.
- **The shape from code, the surface from the model:** for an exact outline, draw it as a plain black and
  white picture at the exact border width and corner size (as `dev/tools/shape-art` draws its masks) and
  give it as image 2 in a `-2ref` workflow ("exactly the outline of image 2"). The model is good at
  material and ornament, bad at exact sizes.
- **Blizzard's art as a second reference:** the game's own frames are the ground truth for how a frame is
  built (`references/BlizzardInterfaceArt/Interface/FrameGeneral/UIFrameMetal2x.BLP` and its
  neighbours); the tool takes BLP files as they are.

## Animation

**Most motion is code**, on the still parts: the game's animation groups (an alpha pulse, a scale, a
rotation, texture coordinates scrolled for a shimmer). It is cheap and sharp at any size, and
[gui-development.md](gui-development.md), *Motion*, says how. A **flipbook** is for motion code cannot
make: a glow that swells through a gem, glints running along a rim, fire, magic. It is one texture with
the frames in a grid, played by a FlipBook animation. Blizzard's use 20 to 64 frames for 0.7 to 1.5
seconds (the proc glow of an action button: 30 frames, 1 second, `ActionButtonSpellAlerts.xml`), many
of them drawn with additive blending, on black.

**Making the clip** (recipes `anim`, `anim-5b`, `effect`):

- Image 1 is the chosen part; `flatten: #000000` lays it on black (the Wan models take no alpha).
- Say only what moves, and say that the colour stays: for "glow" the 14B model turned a blue gem orange,
  the 5B one gave it green glints. Write "the sapphire stays deep blue; a blue glow swells and fades".
  The recipes add that the camera and the shape stay still.
- **Wan 2.2 14B** (`anim`) has the part as its first and last frame: a clean loop that starts and ends on
  the still part (`--loop drop-last`, the last frame is the first again). In the test the star's centre
  swelled to white and back, and stayed gold; 54 s a clip.
- **Wan 2.2 5B** (`anim-5b`) only starts on the part, and is not a loop: the flipbook fades its end into
  its start (`--loop fade:8`). With the same words it hardly moved; it is no faster.
- **Wan-Alpha** (`effect`) grows over the clip: it plays once (a burst), it does not loop. In the test: a
  burst of golden sparks, 64 % of the packed sheet clear; 47 s a clip.

**Packing it:** `dev/tools/flipbook <clip folder> <sheet.png>`:

| Option | |
| --- | --- |
| `--frames N` | frames in the flipbook (32), picked evenly from the clip |
| `--drawn UNITS` | the size it is drawn at in the game; a frame's side follows from it as in [images.md](images.md) (40 units: 128 px) |
| `--loop` | `none`, `drop-last`, `fade:K` |
| `--glow` | only the light the clip adds to its first frame: drawn with additive blending over the still part, it gives the clip back, and the still part stays as it is. On its own such a sheet looks odd (gold turning white shows blue, the light gold lacks). |
| `--black` | the clip is on black for additive blending: no transparency |
| `--fps N` | the clip's frame rate, for the duration (24; the 14B models: 16) |

The grid's columns, rows and frame side are powers of two, so the sheet is too, and the FlipBook divides
the whole texture. The tool writes the sheet, a `.gif` preview at the game's speed, and prints the
FlipBook's numbers. The sheet becomes a BLP like any picture: add it to `dev/tools/art`'s `PICTURES` with
the kind `sheet`, which keeps it whole.

**In the game** (Blizzard's pattern; not tried in Sane UI yet):

```xml
<Texture parentKey="StarGlint" file="Interface\AddOns\SaneUI_Module\Art\star-glint" alphaMode="ADD" setAllPoints="true"/>
...
<AnimationGroup parentKey="Glint" looping="REPEAT">
	<FlipBook childKey="StarGlint" duration="1.71" flipBookRows="4" flipBookColumns="8" flipBookFrames="32" flipBookFrameWidth="0" flipBookFrameHeight="0"/>
</AnimationGroup>
```

## From a picture to pieces the game stretches

**How the game stretches art.** Two ways, both Blizzard's:

- **One texture with slice margins:** `texture:SetTextureSliceMargins(left, top, right, bottom)` (in
  texels) keeps the four corners as they are and stretches the edges and the middle;
  `texture:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)` repeats them instead
  (`SimpleTextureBaseAPIDocumentation.lua`). The Tooltips module draws its panel so (`Panel.lua`).
- **Nine pieces** with `NineSliceUtil.ApplyLayout` (Core's windows, `Window.lua`, with Blizzard's atlases).
  Blizzard's own frames show the layout: the corners in one file (`FrameGeneral/UI-Frame.blp`, 128 x 128),
  the top and bottom edges in a second, repeated sideways (`_UI-Frame.blp`, 256 x 128), the sides in a
  third, repeated downwards (`!UI-Frame.blp`, 64 x 256). In Blizzard's names `_` means repeated sideways
  and `!` repeated downwards, as in the atlases `Window.lua` uses.

**Design for it.** All the ornament goes into the corners. Between them an edge is either the same along
its whole length (a moulding: the same cross-section everywhere, so stretching does not show) or a short
pattern that repeats without a seam (then tiled). The middle is empty or a plain fill of its own. A crest
on top of a window is a separate texture laid over the frame. Ask the model for exactly that (*ornate
corners, plain straight mouldings between them*); FLUX.2 [dev] does it best.

**Cutting a frame** (by hand for now; worth a tool, `dev/tools/slice`, once the first frames exist):

1. Clean the alpha (no faint pixels outside the frame).
2. Make it symmetric: mirror one half onto the other, so all four corners match.
3. Choose the margins: the corner's size, where the ornament ends.
4. Edges for stretching: replace each edge by its middle cross-section repeated along it, so it is
   exactly even. Edges for tiling: cut one repeat and blend its seam.
5. Pack the corners, a short piece of each edge and the middle into one small texture, and note the
   margins. The texture's size follows [images.md](images.md): the drawn size of a corner in UI units
   times 2.81 texels at 4K (a *frame* kind in `dev/tools/art`, still to add).

**Buttons and other parts.** Make only the normal look. The others are made the way Blizzard makes
them ([gui-development.md](gui-development.md), *Art*): a highlight laid over with additive blending, a
pressed look a little darker and moved down by a pixel, desaturated when unavailable. Parts of a fixed
size (check marks, a slider's knob, a close button) need no slicing. A progress bar is a track sliced
only sideways and a fill that repeats sideways.

## Sources

| Source | Used for |
| --- | --- |
| ComfyUI's documentation, blog and templates (`Comfy-Org/workflow_templates`) | the workflows, the models' files and settings, Qwen 2.1's transparency sentence |
| The models' pages on Hugging Face | files and sizes |
| Measured on this computer, 2026-10-17 (`/data/Projects/ImageGen/output/`, `assets/generated/example/`) | the times, what each model did, the words in the recipes |
| `references/.../SimpleTextureBaseAPIDocumentation.lua`, `UITextureConstantsDocumentation.lua` | slice margins and slice mode |
| `references/BlizzardInterfaceArt/Interface/FrameGeneral/` | how Blizzard splits a frame into files |
| `references/.../ActionButtonSpellAlerts.xml`, `SimpleAnimFlipBookAPIDocumentation.lua` | flipbooks: frames, grids, durations |
