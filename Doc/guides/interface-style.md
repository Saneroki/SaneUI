# Interface style

Sane UI's own look for windows, panels and full screens: what each part is made of, how it looks, and what is
painted by image models versus made in code. Saneroki decides the look by picking from concept art; every decision
is written here, with the picture it came from, the moment it is taken. The harness that makes the parts and
views (`dev/imagegen/sets/interface/`, *The harness* below) and the house style's words (`dev/imagegen/style.txt`)
are made from this guide. When they disagree, this guide wins and the harness gets corrected.

The pictures named here are in `assets/Concept art/UI style/`. They show the part the decision is about. The rest of
a picture (its other parts, its text, its colours elsewhere) is not part of the style unless a line here says
so. Pictures that are not named here are not part of the style at all, nor are the words that made them.

## Scope

Sane UI is a complete redesign (Saneroki, 2026-10-21): every window and view Sane UI makes or recreates gets this
look and its own layout, art, fonts and style, not Blizzard's. The game's native windows that Sane UI leaves in
place stay in their own style, mostly untouched. How the game works (its API, secure frames, scaling) stays as
Blizzard's code has it ([gui-development.md](gui-development.md)).

## The idea

An adventurer's journal: an open book of cream parchment bound in thin, stitched dark brown leather. The art is a
quiet background; the content (icons, names, numbers, text) is what stands out. Everything is compact and dense,
with as little room for frame and ornament as the look allows.

- **Leather and metal are the binding.** They form a window's outer border, its title bar and the hard buttons
  set into that border. A leather piece always joins the leather border; it never sits on its own on the paper.
- **Everything on the paper is pencil and paper.** Outlines, dividers, slots, frames round content, section
  headers and decorations are pencil strokes or pieces of paper (strips, tabs, notes), flat on the page. No
  leather on paper areas (Saneroki, 2026-10-21: leather headline bars on paper panels are out).
- **What changes is made in code.** Text, icons, stains and sketches are laid over the painted parts by code, so
  windows can resize, scroll and show live data.

## Materials

### Paper

- **Texture:** `paper.png`: cream parchment with soft, large, faint clouds and an extremely subtle grain.
- **Made of layers in code**, so a window can be any size and scroll without repeats:
  - `paper.png` scaled to cover the page and cut to it (never stretched or repeated);
  - a soft darker edge;
  - the stains (below).
  - `dev/imagegen/sets/interface/paper.py` lays them.
- **Stains** (coffee rings, blots, drops: `stain-*.png`, `stains-*.png`) are separate pieces with transparency.
  Code places a few at seeded random spots, faint, and they scroll with the page. They are never painted into a
  part.
- **Sketches** (a loose landscape, a ruin, a creature study) are separate pieces too, placed by code, very faint:
  few light, quick strokes that never fight the text over them.
- **Overhangs** (`doll.png`): paper strips and pieces may hang out over the leather border or cross it, where a
  strip belongs to content at the edge (a slot's stat strip, a note, a tab). Saneroki wants more of them, where
  they make sense.

### Leather

- **Look:** dark brown with a visible grain and neat saddle stitching along its edges. It is thin: a border, not a
  cover.
- **The window's edges** (`edges-and-buttons.png`, the left and right edges): a thin stitched leather binding. The
  book's edge shows a little, with small dark metal fittings (a corner cap, a ring or clasp at the side).

### Metal

- Small dark steel or iron accents, used sparingly: corner caps, rivets, a ring, a buckle. Always on leather.

### Pencil

- Graphite grey on the paper, with the paper's grain showing through.
- Pencil draws every outline and divider on the paper: slots, rows, the frames of panels and bubbles, ruled lines.
  Strokes are loose and hand-drawn but clean.

## Text

- **On paper: Kalam** (a hand-printed, non-cursive font), in pencil grey with the paper grain over it (Saneroki,
  2026-10-21). Its files are in `assets/fonts/Kalam/` (Light, Regular, Bold).
- **Class colours on paper** (names in bubbles, lists, the podium): the class's colour darkened until it reads on
  the paper, its hue kept. The game's own colours, light ones like the priest's white, vanish on the paper.
- **On leather** (titles, button labels): letters pressed or burned into the leather, as in `title-text.png`
  ("WANTED"). Code makes them from the text, so they stay dynamic: they are never painted into a part. Their font
  is not decided yet; the harness uses a serif as a stand-in.
- Image models paint no text into parts. Concept art may show placeholder writing.

## Parts

### Title bar

- **Look:** `title-bar.png`. A slim stitched leather strip across the top of the window, joined to its leather
  border, with a small metal fitting at each end. The title sits in its middle, pressed into the leather (*Text*).
- **Buttons:** room at its right end for small leather patch buttons (close, settings).

### Buttons

- **Hard buttons:** leather patches, as at the bottom left of `edges-and-buttons.png`. They are stitched or riveted
  and set into the leather border, along the title bar or along the bottom edge. Their labels are made in code.
- **Patch pieces for any width:** the square leather patches in the top right corner of `guild-board.png` are the
  pieces buttons are built from. Code places them and repeats their middle to make a button as wide as it needs
  (a left end, a middle that repeats, a right end). So the patch is painted as separate pieces:
  - edges that join seamlessly;
  - the stitching running on along the repeated middle;
  - no icon or text in it.
- **Dropdown buttons:** leather bands hanging down from the top border, with a buckle, as in `dropdown-bands.png`
  (only its bands and buckle). A band opens an overlay (a dropdown, a menu).
- **On the paper:** pencil-outlined paper pieces, never leather.

### Tabs

- **Top tabs:** a row of tabs right under the title bar, across the top of the page (Saneroki, 2026-10-21). There
  are two styles:
  - **patch tabs:** darker, patchy tabs, as in the row under the title bar in `top-tabs.png`;
  - **drawn tabs:** tabs drawn on the paper in pencil, as in the row under the paper top of `guild-board.png`.
- **Side tabs:** `side-tabs.png`. Small leather bookmark tabs sticking out of the window's left edge, each with a
  small icon in a muted colour (deep red, green, ochre, slate blue).
- **Tabs that change the page's content** may stand down the left side of the page, as in `bags-page.png`.

### Panels and sections on a page

- **Sections:** a page is divided by pencil lines and paper pieces. A section's header is pencil writing on the
  paper with a pencil rule, never a leather bar.
- **Breaking the rectangles:** small details break up the straight edges: a folded paper tab at the end of a row,
  a curled corner, a note in the margin.

### Chat bubbles

Bubbles appear in two places:

- **On a chat window's paper:** a column of bubbles, each anchored left, right or in the middle of the page.
- **Floating:** over the game world.

Built on `chat-bubble.png` (its top bubble), made more compact. Each bubble is:

- a small piece of paper with a tiny, minimal pencil outline and the speech-bubble triangle;
- two lines and very little padding: the first holds the name (in its class colour), the channel and the time; the
  second holds the message;
- room at the left for a sketched class icon, which sits in the bubble's top left corner and overlaps that corner a
  little, giving the bubble its shape;
- no leather and no ornament.

## Views

- **Character doll:** `doll.png` is the layout and the look, to be copied, not redrawn (Saneroki, 2026-10-21):
  - its shaped leather frame;
  - the hero in the middle: the game's live 3D model in the game;
  - the gear slots in a gentle arc down each side of him, eight a side;
  - the top slot of each side has no strip; each of the seven below has its paper stat strip outside it,
    hanging out over the leather border;
  - the main hand, off hand and ranged slots below, the smaller ammo slot beside them, with their stat strips
    under them.

  The harness's character view is this picture itself, with code putting the live content in (*The harness*).
- **Bags and bank:** `bags-page.png`. A condensed page cut into close sections, each with a pencil-ruled header
  and a dense grid of item icons. Tabs down the left change the content.
- **Choosing a class or specialisation:** `class-fan.png`. Its layout and look (cards fanned out over the page)
  are kept for a view such as a spellbook's class choice.
- **Guild window:** `guild-board.png`. Its paper top area (the guild's emblem, name and member count on the paper)
  and its row of tabs fit the guild window. Its leather panel headers on the paper do not (*The idea*).

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

## The harness

How the parts and views of this style are made (`dev/imagegen/sets/interface/`, Saneroki, 2026-10-21). It is
strict on purpose: nothing is painted from words alone, so nothing can drift from the picks.

1. **Crops** (`refs.py`): each decided part is cut out of the picture it was picked in (*Parts*), and that crop is
   the only thing the part is made from. A crop's box names the part's place in its picture.
2. **Elements** (`elements-wide.txt`, `elements-tall.txt`, `elements-square.txt`): Qwen's edit with the crop as
   its only picture. The words (`elements-before.txt`) ask only for a clean copy: the same material, colour,
   stitching and shape, alone on transparency, without letters, numbers or icons. Grouped by shape, so no crop
   is squeezed. Three seeds each.
3. **Checked against the brief** (`compose.py`, `CHOSEN`): the first seed that follows its brief is used: no label
   left in, the part whole. A part no seed delivers cleanly is made from its crop with the label covered in
   code (`refs.py`, `CLEAN`). Marks the edit left in are covered in code (`compose.py`, `COVER`).
4. **Views** (`compose.py`): laid out in code the way the game will draw them:
   - the leather parts sliced, their ends kept and their middles repeated;
   - the paper from `paper.py`;
   - pencil lines drawn by code;
   - text in Kalam with the paper's grain;
   - titles and labels pressed into the leather;
   - game icons from `references/`, and class icons turned into pencil sketches.

   A view with a decided picture is that picture with its content put in by code (the character doll).
5. **Polish** (`polish.txt`, `polish.py`): one light pass of Qwen's edit over each view, which may only make the
   parts sit together (light, soft shadows). The layout, the parts and the writing are the code's.
6. **Gallery** (`gallery.py`): every element, view and polished view, numbered from #1, at
   `assets/generated/interface/index.html`.

Rules:

- Parts come from their crops, never from words alone or from a second picture. A second picture takes over the
  layout.
- A layout with exact counts (gear slots, rows) is never left to the model.
- No stains, sketches or text are painted into parts; code lays them over.
- New decisions go into this guide first, then into the harness's crops, lists and views.
