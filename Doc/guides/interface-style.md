# Interface style

Sane UI's own look for windows, panels and full screens: what each part is made of, how it looks, and what is
painted by image models versus made in code. Saneroki decides the look by picking from concept art; every decision
is written here, with the picture it came from, the moment it is taken. The harness that makes the parts and
views (`dev/imagegen/sets/interface/`, *The harness* below) and the house style's words (`dev/imagegen/style.txt`)
are made from this guide. When they disagree, this guide wins and the harness gets corrected.

The pictures named here are in `assets/Concept art/UI style/`. **Only what Saneroki explicitly likes is there, cut
out of its picture** (Saneroki, 2026-10-21): a picture he liked part of is cut down to that part, and only the cut
is a reference or an input for image models; the rest of the picture is excluded, as is every picture and part
he did not name, with the words that made them. The cut boxes and where each cut came from are recorded with the
cutting tool, outside the project.

## Scope

Sane UI is a complete redesign (Saneroki, 2026-10-21): every window and view Sane UI makes or recreates gets this
look and its own layout, art, fonts and style, not Blizzard's. The game's native windows that Sane UI leaves in
place stay in their own style, mostly untouched. How the game works (its API, secure frames, scaling) stays as
Blizzard's code has it ([gui-development.md](gui-development.md)).

## The idea

An adventurer's journal: an open book of light cream parchment bound in thin, stitched dark brown leather. The art
is a quiet background; the content (icons, names, numbers, text) is what stands out. Everything is compact and dense,
with as little room for frame and ornament as the look allows.

- **Leather and metal are the binding.** They form a window's outer border, its title bar and the hard buttons
  set into that border. A leather piece always joins the leather border; it never sits on its own on the paper.
- **Everything on the paper is pencil.** Outlines, dividers, slots, frames round content, tabs, buttons, section
  headers and decorations are clean pencil lines on transparency, flat on the page (*Pencil pieces*). The only
  paper pieces are those hanging out over the border (*Overhangs*). No leather on paper areas (Saneroki,
  2026-10-21: leather headline bars on paper panels are out).
- **What changes is made in code.** Text, icons, stains and sketches are laid over the painted parts by code, so
  windows can resize, scroll and show live data.
- **No colour in the design (Saneroki, 2026-10-21).** The design language is brown leather, paper and pencil lines.
  Tabs, buttons and bands are never coloured (no red, green or blue tabs sticking out). Colour comes only from
  the game's content: item and spell icons, class colours in text.

## Materials

### Paper

- **Texture:** `paper.png`: parchment with soft, large, faint clouds and an extremely subtle grain.
- **Tone:** a light cream (Saneroki, 2026-10-22): between the dark brown it was for a day (150, 114, 80) and an
  off-white (238, 229, 208) that was a little too white. The page's mean colour is (220, 204, 178); #12's strap
  is about (77, 48, 31). The harness sets it (`paper.py`, `TONE`). The paper of the window (#12) and of the doll
  (#3) is moved to the same tone, their leather and metal keeping their own colours (`pieces.py`, `tone_shift`).
- **Made of layers in code**, so a window can be any size and scroll without repeats:
  - `paper.png` scaled to cover the page and cut to it (never stretched or repeated);
  - a soft darker edge;
  - the stains (below).
  - `dev/imagegen/sets/interface/paper.py` lays them.
- **Stains** (coffee rings, blots, drops: `stain-*.png`, `stains-*.png`) are separate pieces with transparency.
  Code places a few at seeded random spots, faint, and they scroll with the page. They are never painted into a
  part.
- **Sketches:** the elaborate pencil line drawings in `sketches/` (paper #201–212: a wolf's head, landscapes with
  a ruin, a coastline map, trees; Saneroki, 2026-10-21) are the decorations of the paper, with the coffee stains. They are
  separate pieces in graphite with their own transparency, placed by code, very faint, never painted into a part.
- **Overhangs** (`doll.png`): paper strips and pieces may hang out over the leather border or cross it, where a
  strip belongs to content at the edge (a slot's stat strip, a note, a tab). Saneroki wants more of them, where
  they make sense.

### Leather

- **Look:** dark brown with a visible grain and neat saddle stitching along its edges. It is thin: a border, not a
  cover.
- **The window's edges** (`edges-and-buttons.png`, the left and right edges): a thin stitched leather binding. The
  book's edge shows a little, with small dark metal fittings (a corner cap, a ring or clasp at the side). The
  harness's edge parts are approved (`elements/edge-left-*.png`, `elements/edge-right-*.png`).

### Metal

- Small dark steel or iron accents, used sparingly: corner caps, rivets, a ring, a buckle. Always on leather.

### Pencil

- Dark graphite (30, 23, 17) on the paper, in clean, sharp lines (*Pencil pieces*).
- Pencil draws every outline and divider on the paper: slots, rows, the frames of panels and bubbles, ruled lines,
  and the decorations (the sketches).

## Text

- **On paper: Kalam** (a hand-printed, non-cursive font), in dark graphite (30, 23, 17) with the paper grain over
  it, readable on the paper (Saneroki, 2026-10-21). Its files are in `assets/fonts/Kalam/` (Light,
  Regular, Bold).
- **Colours that are hard to read on paper** (class colours on names in bubbles, lists, the podium; light quality
  colours): the game's own colour, unchanged, with a thin dark outline round the letters, made in code with the
  text (Saneroki, 2026-10-21). Light colours like the priest's white would vanish on the paper without it.
- **The window's title** stands on the paper label of #12's top, in Kalam (*The window's top, edges and bottom*).
- **On leather** (button and tab labels): letters pressed or burned into the leather, as in `title-text.png`
  ("WANTED"). Code makes them from the text, so they stay dynamic: they are never painted into a part. Their font
  is not decided yet; the harness uses a serif as a stand-in.
- Image models paint no text into parts. Concept art may show placeholder writing.

## Parts

### The window's top, edges and bottom

- **The window is `edges-and-buttons.png` (#12) itself** (Saneroki, 2026-10-21), as a book with many pages:
  - **the top:** its leather strap with the ribbon bookmark hanging from it, the hinge, and the small patch in
    the right corner (the close button); under it the pencil-drawn paper label that holds the window's title,
    written in Kalam by code;
  - **the edges and the bottom: one image** (Saneroki, 2026-10-22): #12's left edge, the thin stitched leather
    binding with the pages' edges beside it. The right edge is it mirrored, standing where #12's book ends; the
    bottom is it turned a quarter, its leather facing down. Where a side meets the bottom the corner is mitred,
    like a picture frame, so the stitching turns the corner. The clasp hangs on the right edge's middle;
  - **the corners:** at the top #12's metal caps and the hinge; at the bottom #12's rounded metal caps, laid
    over the mitred corners, which are rounded to #12's outline under them (Saneroki, 2026-10-22);
  - **the edges' paper** (the pages' edges beside the binding) is moved toward the page's tone and fades into
    the page, so the cream page and the tan edges meet without a line (Saneroki, 2026-10-22);
  - **no straight cut-off:** #12's own bottom (the page stack, cut where its strap was) is no longer used: it never
    fitted the page, the edges and the paper.
- **Joins:** the top is its two ends and a middle stretched whole between them, joined edge to edge, so the strap
  and the label run on (a cross-fade showed seams). The edges run from under the top's corners down to the
  bottom's mitres. The title label's light is evened out in code, its grain kept (the paper that covered its
  writing showed as lighter blocks).
- The harness uses #12's own pixels for all of it (*The harness*): its parts fit together exactly at their own
  scale. Repeats are joined without seams; where #12 has things that are not wanted, code cuts them out (the
  strap's rows) or covers them with #12's own paper (the label's writing).
- **Not wanted** (Saneroki, 2026-10-21): the title bars and borders of paper #61, #69 and #78. They are no
  reference and no input.

### Buttons

- **Buttons:** the leather patch `patch.png` (paper #183) is every button (Saneroki, 2026-10-21). Code sizes it,
  repeating its middle for wider buttons, and presses the label in. The earlier patch (round 1 #23) is dropped.
- **Dropdown buttons:** a leather band hanging down from the top, with a buckle: the band of the kit
  (`kit/kit3-09.png`). Its inside is plain leather for the code's inlay. A band opens an overlay.
- **On the paper:** pencil boxes (*Pencil pieces*), never leather; a dropdown or button on the paper (the bags'
  *View* on the title line) is a pencil box with its words in graphite (Saneroki, 2026-10-23).
- **Arrows and ticks on the paper:** one pencil arrow, a chevron drawn in graphite (the journal piece `arrow`,
  from `assets/interface/bags-arrow.png`), as large as a checkbox beside it and centred like it, drawn lightly and
  whole under the mouse, turned to point where it must (the bags' sidebar folds by it, a group's row turns it down
  or up); a checkbox is a square drawn in pencil with a light tick drawn by hand (Kalam's root sign), never the
  game's dark check mark (Saneroki, 2026-10-23).

### Kit parts

- The parts of `kit/` (cut from style shapes/kit-3 and kit-4, Saneroki, 2026-10-21: "look great"): framed paper
  panels, hanging leather banners, a band with a buckle, check and close marks, sliders, shields. They are the
  look of these parts wherever a view needs them.
- The framed panel (#17, `kit3-01`), the hanging banner (#18, `kit3-02`), the slider (#24, `kit3-08`), the
  blade-shaped bar (#27, `kit3-11`) and the three banners (#28, `kit4-01`) get variations to pick from, keeping
  their light inset lines (`catalog.py`, *variants*).

### Tabs

- **Top tabs:** a row of tabs right under the top, across the page (Saneroki, 2026-10-21). Three styles:
  - **leather arrow tabs:** `elements/top-tab-arrow-3.png` (and `-4`), the patch tab of paper #78's row shaped as
    an arrow pointing right:
    - the top and bottom are straight;
    - the left end is cut in as a V, and the right end runs out into a point;
    - side by side they form a strip, each tip in the next one's cut;
    - their slanted ends are worn and stitched like the top and bottom;
    - labels are pressed in by code.
  - **leather patch tabs:** `elements/top-tab-patch-3.png`, from paper #78's row (`top-tabs-patch-row.png`, the
    only part of #78 that is kept), with straight ends.
  - **drawn tabs:** pencil lines on the paper (*Pencil pieces*), labels in Kalam by code.
- **Side tabs:** the leather patch (`patch.png`) sticking out of the window's left edge with a small icon pressed
  in. Never coloured (*No colour in the design*).
- **Tabs that change the page's content** may stand down the left side of the page, as in `bags-page.png`.
- **Not wanted:** the leather tabs with pointed sides (explore sdxl/heraldry-sheet-1), dropped by Saneroki on
  2026-10-21.

### Pencil pieces

Everything drawn on the paper is made of pencil lines on transparency, never of separate paper pieces in another
colour (Saneroki, 2026-10-21): the page shows through, so boxes, buttons, tabs and lines are always the page's own
colour.

- **Clean, sharp lines** (Saneroki, 2026-10-21). The pencil is crisp lines, or elaborate line drawings for the
  decorations (the sketches). It is never smudged, shaded or a soft graphite drawing. `pencil.py` keeps only
  lines as thin as a pencil line and drops broader shading and shadows. The class icons on bubbles and the
  podium are drawn in crisp lines too.

- **The box:** paper #14's double pencil line with its rounded corners (`elements/top-tab-drawn-1.png`, "very
  clean"). Its lines alone, with the paper taken out, are the box (`pencil.py`).
  - Code stretches its sides and keeps its corners whole, at one line weight for every size (a box of any size
    has the same pencil).
  - Boxes are used for section frames, drawn tabs, buttons on the paper and item and gear slots.
  - The chosen tab or button has stronger lines.
- **The rule:** the box's top line, stretched: a section's header underline and dividers.
- **More pieces** drawn like #14 come from variants to pick from (`catalog.py`, *variants*): a wide section frame,
  a long divider with small flourishes, a corner piece.
- **Icons on the paper** (Saneroki, 2026-10-23): our own pencil drawings, never the game's tiny painted icons (a
  row of the bags' sidebar, the fold arrow): one simple object in a few bold graphite outlines, very little
  shading, centred in a square with a little room round it, thickened a little so it reads at 16 to 18 units.
  Made large enough for its largest use (256 x 256), its smaller mipmaps thickened for their size, so one texture
  serves a row and a slot. In an empty slot, a category's drawing is faded to a grey, three quarters of the slot
  (0.3; Saneroki, 2026-10-23: bigger and darker than first).
- **The words of the bags, the bank and the alts** are 1.2 times their first size (Saneroki, 2026-10-23: to be
  read); the heads, lines and the sidebar grow with them.
- **The podium** (the guild's race): steps drawn as an artist's pencil sketch of real blocks in perspective (each
  with its front, its top face and its side), in clean pencil lines only: firm outer edges, lighter inner edges,
  strokes running a little past their corners, a light second pass and a faint construction line. Nothing is
  filled, shaded or hatched; a step in front only hides the lines behind it. Drawn by code, so it fits any number
  and height of steps.

### Panels and sections on a page

- **Sections:** a page is divided by pencil pieces. A section's header is pencil writing on the paper with a
  pencil rule under its letters, never a leather bar.
- **Breaking the rectangles:** small details break up the straight edges: a folded corner, a note in the margin,
  a sketch.

### Combat text

What a unit takes, rising over its nameplate and over your character (Saneroki, 2026-10-23):

- **Numbers in Kalam Bold**, outlined, in three colours only: auto attacks and physical damage white, spell damage
  red, heals green (Saneroki, 2026-10-23: a school's own colour confused).
- **What did no harm is a drawing, not a word:** a miss, dodge, parry, block, evade or immunity is a pencil line
  drawing, large, with thick lines, white in the game (an immunity, a bubble with an "i", bright red: tinted by
  code), on transparency with a dark edge round its lines so it reads over any ground, as the outlined numbers do.
- **The drawings** are an image model's pencil sketches (`dev/imagegen/sets/combat-text/`), picked by Saneroki
  (2026-10-23), kept in `assets/interface/combat-text/` and traced by `dev/tools/combat-art` into white lines with
  the dark edge: sharp pencil lines, not thick ones (Saneroki, 2026-10-23), all of one weight (parry's and block's
  heavier lines made thinner to match), the bubble alone kept thick:
  - **dodge:** a fighter bending far back at the waist, an arrow flying over (from left to right);
  - **evade:** a fighter in a wide stance, the head swung aside, an arrow flying up past it (from bottom to top);
  - **parry:** two swords crossed, short sparks where the blades meet;
  - **block:** a heater shield with a double rim, an arrow breaking on its face, impact lines round the hit;
  - **immune:** a round bubble with a shine at its upper left, a big "i" in Kalam Bold set in by code, bright red;
  - **miss:** an arrow flying high over a target and past it, drawn by code in thin, even strokes (Saneroki's pick of
    the first drawings).

### Chat bubbles

Bubbles appear in two places:

- **On a chat window's paper:** a column of bubbles, each anchored left, right or in the middle of the page.
- **Floating:** over the game world.

Built on `assets/generated/picks/UI style/chat-bubble.png` (paper #133's top bubble), made more compact. Each bubble is:

- one piece of paper, drawn in code, in this silhouette:
  - a low rounded body;
  - a round bulge over its top left corner (top right when anchored right), holding the sketched class icon. The
    round is part of the paper and its outline, not a separate element (Saneroki, 2026-10-21);
  - the speech-bubble triangle below;
- one tiny, minimal pencil outline round the whole shape;
- two lines and very little padding:
  - the first holds the name in its class colour with the outline (*Text*), the channel and the time;
  - the second holds the message;
- no leather and no ornament.

### Far herbs and ore

A herb or ore the minimap found, marked over the world in its direction however far it is (Navigation, `Glints.lua`;
Saneroki, 2026-10-25):

- **the picture of what it gives** (Peacebloom's flower, Copper Ore's ore), cut round inside the item picture's own
  frame and a little wider than the ring's hole, so no straight edge of it ever shows inside the leather (Saneroki,
  2026-10-25);
- **in a ring of stitched leather** (Saneroki's pick of eight renders, five gold, leather, pencil, parchment:
  `dev/imagegen/sets/far-marks/rings.txt`, leather-1): dark brown leather with a fine grain, a saddle stitch round
  its outer edge and another round the hole;
- **the arrow is part of the ring:** the ring runs out into one leather point, the way to the node from where the
  player faces (up: ahead, down: behind), one cohesive piece; a flat yellow V beside the ring did not belong to it;
- **the same ring on the minimap,** perfectly round, without the point (Saneroki), so the found ones look alike
  there and in the world;
- **its yards under the ring,** the number alone ("79", no *yds*), in small outlined letters, under the point too
  while that points down (Saneroki, 2026-10-25; centred in the ring over the picture was tried and moved below);
- no column, no beam, no sparkles: a first build's column of gold sparkles was taken out.

### The leveling guide over the world

Speed Leveling's guide, straight on the world without a window (`src/SpeedLeveling/Steps.lua`; Saneroki,
2026-10-25):

- **Its words in Expressway**, a clean sans with a thin dark outline, not Kalam: it stands over the game, not on paper
  (Saneroki's pick). Names in the game's own font colours, as the guide marks them.
- **From the top:** a row of icons (the items to use, the names to target), then the zone with its levels and how
  far (*12/84 · 14%*) over a thin rule, the steps at hand on a faint dark shade, the next steps **greyed out** and
  fading as they go down (Saneroki: he likes them greyed).
- **The icons are icons only,** each in the far herbs' round leather ring (*Far herbs and ore*): an item's picture
  with its cooldown and count, a target's portrait once seen, else the game's speech bubble or sword (Saneroki: clean,
  just the icons, over the guide's top).
- **The arrow is a part of its own,** placed apart in Edit Mode (Saneroki): the far herbs' leather ring with its
  point, turned the way to the step's place; in its hole the game's own cursor picture of what to do there (a speech
  bubble to talk, a sword to kill, a bag to loot, an open hand to use, the quest's *!* and *?*, a coin bag, a book, the
  Hearthstone, a winged boot, a map); under it, words read at a glance: what to do there, then the yards and the time
  to get there.

### The talk over the world

Lore's talk with an NPC (`src/Lore/`; Saneroki, 2026-10-28: the dialogues "the same way, but more transparent"), as
the guide over the world: no window, no paper.

- **See-through over the world:** each part on a soft dark shade whose sides fade out into the world (its darkness a
  setting, 30 % at first), the rest of the interface faded out meanwhile.
- **Low in the middle:** the NPC's own 3D face with no frame or background at the left, its name beside it in the
  game's gold, the paragraph under the name in white, *2/4* small and grey at the bottom right.
- **The answers in a column right of the words,** a shade a line, darker under the mouse, the game's own pictures
  for a quest's kind.
- **The quest under the words,** as wide: its title in gold, headings in gold, each reward a line: its icon, its name
  in its quality's colour, under it what it is in grey (*Leather · Chest*, *Can't use* in red), at the right what it
  sells for and what it changes (green up, red down).
- **Words in Expressway** with a thin dark outline, as the guide over the world.

### The loot window

Loot's window (`src/Loot/Window.lua`, `Row.lua`; Saneroki, 2026-10-29: first "minimalistic to the extreme", then
each thing with an outline and a background):

- **No window round it:** a transparent background, no paper, frame or title; the lines stand on the world, and at
  the foot two buttons, *Link* and *Close* (the word spelled out), each on a dark shade half see-through with a thin
  grey outline so they read as buttons, their words light, gold under the mouse.
- **A line a thing:** a dark shade half see-through (darker under the mouse), outlined in the thing's quality colour,
  a quest's things in the game's gold. In it the picture in a border of the same colour (a dark hair round it), how
  many on it, the name in the quality's colour in Kalam Bold with a thin dark outline, as the combat text and the loot
  feed; under the name, small and grey, its kind and how it binds, and at the right what a vendor pays for all of
  it in the game's coins; at the top right a small **A** on its own shade, grey, gold while the thing is on the
  player's list.
- **The next under the mouse:** a thing taken, the lines close up so the next stands where it stood.

### Unit frames and action bars

Combat's unit frames and the game's action bars (`src/Combat/Units/`, `ActionBars.lua`; Saneroki, 2026-10-29):

- **Unit frames like the nameplates:** your frame, your target's and your focus's look very like a nameplate (the
  module Nameplates): the round bar with its thin border, the power line along its bottom, the rank's line and the
  red glow, in the plates' font. One line inside: the level and the raid marker on the left, the name in the
  middle, the current health and its share on the right ("850 | 85%"). A player's name is always the whole name,
  first name and surname. No portrait, no frame round it.
- **Clean action bars:** no border, decoration or background, not on the bars (frame, end caps, page number,
  dividers) nor on a button (frame, slot); only the filled slots, each its square icon alone, cut free of the edge
  its picture is drawn with. What answers the mouse and keys is a flat wash over the icon.

## Views

- **Character doll:** `doll.png` is the layout and the look, to be copied, not redrawn (Saneroki, 2026-10-21):
  - its shaped leather frame;
  - the hero in the middle: the game's live 3D model in the game; full-grown, he fills his place from under the
    level line down to the ground, every race at the same scale, so a gnome stands as small as it is; turned by a
    drag; the wheel moves the camera into his head, his legs hidden below the foot of his column; back to how he
    stood after ten seconds left alone (Saneroki, 2026-10-23).
    Nothing behind him but the page's own paper: no rectangle, no frame, no stony ground (Saneroki, 2026-10-23;
    `dev/tools/journal-art` covers the column with the page's paper);
  - the two top slots (head, hands) as large as the others (Saneroki, 2026-10-23);
  - the gear slots in a rounded layout, eight a side: each row shifted outward a little more toward the middle
    rows, so the slots form an arc round the hero, not a straight column (Saneroki, 2026-10-21);
  - the top slot of each side has no strip; each of the seven below has its paper stat strip outside it,
    hanging out over the leather border;
  - the main hand, off hand and ranged slots below, the smaller ammo slot beside them, with their stat strips
    under them.

  The harness's character view is this picture itself, with code putting the live content in (*The harness*).
- **Character stats** (Saneroki, 2026-10-23): a page, not a long narrow list. Each of the game's stat categories
  is a section (its head in Kalam Bold with a pencil rule under it, a line a stat: the name in soft graphite at the
  left, the value in bold graphite at the right, every other line a faint stripe). The sections stand in as many
  columns as the window's width holds (none narrower than 204 units, none wider than 384, kept together in the
  page's middle; compact: little room at the sides and between sections, Saneroki, 2026-10-23), one list when it is narrow. Where all five fit side by side over the columns, the primary
  attributes are five pencil boxes, the name small at the top, the value large under it. The window holds the stats
  only: no tabs (Saneroki, 2026-10-23).
- **Bags and bank:** `bags-page.png`. A condensed page cut into close sections, each with a pencil-ruled header
  and a dense grid of item icons. Tabs down the left change the content.
- **Choosing a class or specialisation:** `assets/generated/picks/UI style/class-fan.png`. Its layout and look (cards fanned out over the page)
  are kept for a view such as a spellbook's class choice.
- **Guild window:** `guild-top.png` (paper #120). Its paper top area (the guild's emblem, name and member count on
  the paper) and its row of tabs fit the guild window. Its leather panel headers on the paper do not (*The idea*).
  Its board's race to the highest level is a podium (*Pencil pieces*).

## To redesign

Parts that still show the game's art and get a redesign of our own in this style (Saneroki, 2026-10-21). Each
moves to its own heading here once it is decided, with its picture.

- **Map pins:** our own icons for every pin Sane UI draws on the map and the minimap, in place of the game's.
  They are coloured renders, not pencil, and are being developed soon (`Doc/ideas/Navigation.md`, *Map pins*).
- **The route line:** leather stitches across the map, in place of today's golden line (`Doc/ideas/Navigation.md`,
  *Waypoint and route*).
- **Raid markers:** the eight markers in our own style, wherever Sane UI shows them (the nameplates, the marks in
  the chat's picker).

## Animation

- Windows and panels appear out of nothing and disappear the same way (the appearing played backwards): a quick,
  subtle fade, a few hundred milliseconds. There is no closed book that opens and no page turning (Saneroki,
  2026-10-21). A page turn looked best in a test, but it does not fit content that code draws: icons, text and
  pictures that change.

## Out

- Leather bars, leather headers and other leather pieces on paper areas.
- The fanned-cards page with its numbers below (the first `book-fan` panel of the exploration): no use.
- Page-turning and book-opening animations.
- Stains, sketches and text painted into parts.

## High resolution

Sane UI is drawn for 4K screens too (Saneroki, 2026-10-21: "clean high quality renders" of every part the code
needs, for responsive, flexible designs).

- **Scale:** every painted part exists at twice the size it was picked at. The picks were painted for windows of
  about 600 pixels at 1080p, so twice is a 4K screen's scale. The game draws them smaller on smaller screens,
  never larger than this.
- **One render each** (Saneroki, 2026-10-22): every element is rendered once, at its final quality; no varieties
  of it. A render is only made again after its decision changed (`--rebuild`).
- **How:** `catalog.py hires`.
  1. Each decided part is prepared in code: a cut-out's holes (light metal its cut took for the background) are
     made solid, their colour carried in from the light pixels round them; a label's painted letters are covered
     by the part's own leather from beside them on the same rows (the patch tab of #78).
  2. It is upscaled in code (Lanczos).
  3. One gentle pass of Qwen goes over the whole part: `qwen21-inpaint.json` with a full mask, denoise 0.3,
     guidance 2.5 and negative words. It sharpens texture, stitches and pencil, and keeps every shape where it is.
  4. The part's transparency comes back from the upscaled source; marks the pass brought back are covered again
     in code (the letters in #12's title label).
  5. The results go to `assets/generated/interface/hires/`; `pencil.py` takes the pencil box's lines from the
     hires #14.
  6. `catalog.py masks`: the two whole picks (#12, #3) have a background round them; ComfyUI's background removal
     (BiRefNet, `dev/imagegen/workflows/birefnet-mask.json`) finds it, once each, so their outside becomes
     transparent.
- **Pieces** (`pieces.py`, `assets/generated/interface/pieces/`, Saneroki, 2026-10-22): the final puzzle pieces
  code builds every window from, at 4K, alone on transparency, trimmed. `pieces.json` says how each is laid.
  - **The window** from #12, its paper moved to the page's tone: `frame-top-left`, `-middle`, `-right` (the
    strap, ribbon, title label and corner patch; the middle stretched whole, joined edge to edge; its paper fades
    into the page);
    `frame-left` (the edge: a tile that repeats down without a seam, its paper fading into the page),
    `frame-right` (it mirrored), `frame-bottom` (it turned a quarter, repeating along), `frame-cap-left` and
    `-right` (the bottom corners' metal caps), `frame-corner-left` and `-right` (their rounded outlines, which
    code cuts the mitred corners to), `frame-mitre-left-edge`, `-left-bottom`, `-right-edge`, `-right-bottom`
    (masks of the corners' boxes: the edge's and the bottom's part of the mitre within the rounded outline, for
    the game, which cuts no picture on a slant), `frame-clasp`. The title's and the close button's places are in
    `pieces.json`. How the game lays them: Core's `src/Core/Journal.lua` (`Core.Journal`), from the textures
    `dev/tools/journal-art` makes of the pieces (*In the game*).
  - **The character window** (`doll`): #3 whole, on the page's tone; code fills its slots and strips. Its
    outside is what the background removal and #3's backdrop colour (a dark, cool grey reached from the
    border) call outside, cut to the frame's bounds, only the part that hangs together with the window (the
    removal alone kept only the hero). Code bends its two slot columns along the arc as one piece, so its
    edge curves with them, no steps.
  - **Cut-outs:** `patch` (every button and side tab), `tab-arrow`, `tab-arrow-b`, `tab-patch`, `edge-left`,
    `edge-right`, and every kit part (`kit3-01` to `kit4-11`). Their rim (the pick's light background left at
    their edge) is coloured from inside them, so no halo shows on any page.
  - **Pencil:** `pencil-box` (#14's lines; nine slices) and `pencil-rule` (its top line).
  - **Paper and decorations:** `paper`, the stains and the sketches.

  The views and the full screen are built from these pieces alone (`compose.py` takes them through `SOURCE` and
  the frame's pieces), so what the views show is what the pieces can build.
- **Parts, not pictures:** the code gets parts it can lay out at any size:
  - the window's pieces, whose middles stretch or repeat seamlessly;
  - buttons and tabs whose middles repeat;
  - pencil boxes that keep their corners;
  - paper laid in layers;
  - stains and sketches placed by code.

  Text is always the code's, so it is sharp at any size.
- **Layouts at any scale:** `compose.py` lays out in the pixels of a 1080p screen, and `S` turns them into pixels
  (2 at 4K); the pieces are scaled to it. The job lays out every view at 4K; the full screen
  (`views/fullscreen.png`, 3840 x 2160): the character window, the guild window and the chat window side by side.
- **For the game:** the pieces become textures by `Doc/guides/images.md` (format, mipmaps, sizes). Margins for
  slicing are taken at the pieces' scale.
- **Known flaw:** the two blades of the kit (`kit3-11`, `kit4-08`) keep the bites along their top edge that their
  cut-outs have.

## In the game

How the look reaches the game (2026-10-22, Saneroki asked for the inventory's windows in it):

- **Textures:** `dev/tools/journal-art` (`saneui makejournalart`) makes Core's `Art/Journal/` from the final pieces,
  BLP2 by `Doc/guides/images.md`, each piece at its texture's top left (a repeated piece repeated into the rest, so
  tiles join without a seam); a square pencil slot from the box's corners; Kalam into Core's `Fonts/`.
- **The character window for the game:** the doll with the hero taken out (the game's live model stands there): his
  place repainted as paper by an image model with the stony ground kept, the paper toned and grained to the
  column's in code (`assets/interface/doll-empty.png`); the slot columns bent into their arcs and the strips'
  writing covered, as the harness's view does.
- **Code:** `Core.Journal` (`src/Core/Journal.lua`) lays the window out for any size, so windows on a board follow
  the lines dragged between them; Core's board dresses a panel in it (`dress = "journal"`), or leaves it bare for a
  window that is a picture of its own (the doll). The leather is drawn at 0.8 of its 4K size on the board
  (`Journal.SCALE`), so several windows keep room for what they hold.
- **Letters pressed into leather** are the leather's light tan with a dark edge of the cut, as `title-text.png`
  shows them; still in Kalam Bold until the font is decided.
- **Colours on the paper:** graphite for words; a game colour (a quality's, a class's) outlined where it stands
  alone (a name), darkened toward the graphite inside a line of words (the class in a level line); the pencil's
  light shading for a row under the mouse or chosen.
- **In the look:** the character (the doll), the stats, the bags, the bank and the alts (Inventory). The other windows keep
  Core's dark plate until they are made over.

## The harness

How the parts and views of this style are made (`dev/imagegen/sets/interface/`, Saneroki, 2026-10-21). It is
strict on purpose: only what Saneroki decided may go in, and a model never gets the chance to fall back on looks
of its own or on earlier renders.

1. **Decided pixels first.** Where a pick shows the part itself, the harness uses those pixels; no model repaints
   it:
   - the window from #12, cleaned in code by `clean.py`. The strap's rows are cut out and the label's writing is
     covered by the label's own paper. It is cut into a top, a bottom and two edges at #12's own scale
     (`pieces.py`, `FRAME_*`); middles are stretched where their lines run lengthwise, or repeated seamlessly;
   - the character doll: `doll.png` itself, its rows moved outward into arcs. `clean.py` inpaints it twice: the
     rectangle behind the hero becomes paper, and the stony ground fills the bottom of his place.
2. **Crops** (`refs.py`): each decided part is cut out of the picture it was picked in. A crop is the only thing
   a part may be made from.
3. **Elements** (`elements-*.txt`): only for parts no pick shows ready to use, Qwen's edit makes them from their
   crop alone. The words ask for a clean copy (the same material and shape, transparent, no letters or icons).
   Where code can prepare the crop (marks smoothed, a label covered, `refs.py`), it does, so the model only
   finishes. Saneroki approves each element by number; approved ones are copied to
   `assets/Concept art/UI style/elements/`.
4. **Only decided parts** (`compose.py`, `SOURCE`): a view takes its parts from this list alone and refuses any
   other. A part Saneroki did not name is archived, never an input.
5. **Views** (`compose.py`): laid out in code the way the game will draw them:
   - the decided parts and pixels;
   - the paper from `paper.py`;
   - pencil lines, Kalam text and titles pressed into the leather;
   - the game's icons.

   No model pass runs over a finished view: a global pass repaints everything and brings back looks of its own.
6. **High resolution and pieces** (`catalog.py`; the GPU runner's job `interface`): every decided part at 4K
   scale, rendered once, and cut into the final pieces (*High resolution*).
7. **Gallery** (`gallery.py`): the decided references, the cleaned picks, the views, the hires parts, the
   variants of the earlier round (#88–121, still to pick from; no new ones are made) and the final pieces,
   numbered from #1, at `assets/generated/interface/index.html`.

Tools for when a model must touch a finished picture (ComfyUI has them built in; `clean.py` uses the first three
through `dev/imagegen/workflows/qwen21-inpaint.json`):

- **Masked inpainting** (`SetLatentNoiseMask` or `InpaintModelConditioning`, with `DifferentialDiffusion`): the
  model repaints only inside a mask (a label to remove, a seam to join), and every other pixel stays as it was.
- **Negative words with guidance:** the discarded looks named in the negative prompt. They only count with a
  guidance (cfg) above 1; `clean.py` runs at 3.
- **Code where the model fails:** when the model keeps writing letters or invents parts (a new stack of pages),
  code does it with the pick's own pixels (cut rows, copy the pick's own empty paper).
- **Low strength:** a pass at a low denoise keeps the model close to its input: the hires pass runs at 0.3.
- **Training:** a small LoRA trained only on the approved pictures (`TrainLoraNode`) teaches a model this style
  and nothing else. It is for later, when there are enough approved pictures.

Rules:

- Parts come from their picks' pixels or their crops, never from words alone or from a second picture. A second
  picture takes over the layout.
- A layout with exact counts (gear slots, rows) is never left to the model.
- No stains, sketches or text are painted into parts; code lays them over.
- New decisions go into this guide first, then into the harness's crops, lists and views.

## Running it

The whole render is one job of the GPU runner, `interface` (`dev/imagegen/jobs.toml`, priority 20), which runs
`catalog.py`: it cleans the picks, makes the 4K parts (one render each) and the two masks, takes out the pencil
lines, cuts the final pieces, lays out the views and the 4K full screen, and rebuilds the gallery. Each step skips what it has made, so a stopped run goes on where it stopped.

- See how far it is: `saneui gpuqueue` (the job's line is `catalog.py --status`).
- Run it now: `saneui switch interface`.
- After a decision changed (a pick, a cut, a part's source): `saneui rebuildstart interface` forgets what was
  made (`catalog.py --rebuild`) and renders it all anew.
- Single steps by hand: `python3 dev/imagegen/sets/interface/catalog.py clean|hires|masks|pencil|pieces|views`;
  the pieces and the views need no graphics card (`pieces.py`, `compose.py`, `gallery.py`).
- See the results: the gallery, `assets/generated/interface/index.html` (`.claude/launch.json` "interface").

When Saneroki decides:

1. The decision goes into this guide.
2. A liked part is cut out of its picture into `assets/Concept art/UI style/` (only the liked section); a part he
   did not name is archived and never an input.
3. A view or part that uses it changes in `compose.py` (`SOURCE`), `catalog.py` (`HIRES`), `pieces.py` or
   `clean.py`.
4. The job is rebuilt.

