# The interface lab

A local website that runs Sane UI's Lua as the game runs it and draws what it makes, so windows can be built and
refined in the browser with the same code that then goes into the game. The texts that would come from the
server (who is online, chat, items) come from a fake server.

```bash
saneui showuilab
```

It is at `/lab/` on 127.0.0.1 port 8768, the one server of the tools' pages (`dev/tools/web-pages`), always running. `saneui checkuilab [scene]` runs a scene without the page for a few seconds and
prints its log.

## How it works

- **The host** (`dev/uilab/host.lua`) is plain Lua 5.1, the game's Lua. Code runs in an environment like the
  game's: no `io`, `os` or `require`, plus the game's extra string, table and math functions and `bit`. Each file
  gets `...` = the addon's name and its own table, as the game passes them.
- **The game's API** is the lab's stand-in for the client (`dev/uilab/lab/`):
  - widgets: frames, buttons, check buttons, edit boxes, scroll frames, sliders, status bars, message frames,
    the tooltip, cooldowns and animation groups;
  - regions: textures (with texture coordinates, tiling, nine slices, masks, blend modes, vertex colours and
    gradients), font strings and lines;
  - layout: anchors and sizes resolved as the game resolves them, strata, levels, draw layers, clipping and
    scale;
  - scripts and events, timers, the mouse (focus, clicks, dragging, moving and sizing, the wheel, links in
    text) and the keys.
- **What the game has but the lab does not do yet** is known from Blizzard's own API documentation
  (the newest export of its interface, `Blizzard_APIDocumentationGenerated`). Such a method, namespace or function
  is still there, as in the game, and calling it puts a "not in the lab" line in the log. The same documentation
  gives `Enum` (with each one's `Meta`), `Constants` and the list of events: registering an event the game does not
  have is an error, as in the game (the events Blizzard's own code registers count as the game's too).
- **Frame XML** (`dev/uilab/lab/xmlui.lua`) is read as the game reads it: `<Script>` (a file or inline) and
  `<Include>`, fonts, and every frame, region and animation. A virtual one is a template (CreateFrame's fourth
  argument, `inherits`, CreateTexture's), an intrinsic one a kind of its own (`CreateFrame("EventFrame")`), any
  other is made at once. Its attributes and parts: `name` and `$parent`, `parent`, `inherits`, `mixin`,
  `parentKey`, `parentArray`, `hidden`, `setAllPoints`, strata, levels, the mouse; `Size`, `Anchors` (with
  `relativeKey`, `relativeTo`), `Layers`, `Frames`, `Scripts` (`method`, `function`, inline code with the game's
  argument names, `inherit`, an intrinsic's `intrinsicOrder`), `KeyValues` (a dotted global too), `Attributes`,
  `Animations`, the buttons' textures and fonts, `ButtonText`, `ThumbTexture`, `BarTexture`, `ScrollChild`,
  `TexCoords`, `Color`, `Gradient`, `MaskedTextures`. An object's anchors are set once all its parts are there
  (so `relativeKey` finds a part made after it), then the OnLoads run, children before their parents. What it
  does not read yet it says ("not in the lab"). `C_XMLUtil` tells a template's kind, size and KeyValues.
- **Blizzard's own interface** is loaded from its TOCs as the game loads it for this client (its load groups
  `camelot` and `mainline`, `[Family]` Mainline, `[Game]` Camelot), Lua and XML, each addon after its
  dependencies: `Blizzard_SharedXMLBase`, `Blizzard_Fonts_Shared`, `Blizzard_SharedXML` (with its menus,
  colours and narration) and `Blizzard_SharedXMLGame` before the game's frames, `Blizzard_UIParentPanelManager`
  and `Blizzard_Settings_Shared` after them. So `Mixin`, `CreateColor`, pools, callbacks, the font objects
  (`GameFontNormal` and the rest) and the templates (`UIPanelButtonTemplate`, `TabSystemTemplate`,
  `UICheckButtonTemplate`, `InputBoxTemplate`, `WowStyle1DropdownTemplate`, `BackdropTemplate`, ...) are
  Blizzard's, and `Settings` with its panel is the game's own. A file of theirs that stops in the lab (it needs
  what the lab does not have) is a line under "the lab" in the log, and the rest goes on.
- **The client's own state** the lab keeps as the game's documentation describes it, where Sane UI needs it: CVars
  (`C_CVar`), the addons (`C_AddOns`), saved variables, Edit Mode's layouts (`C_EditMode`, sent again as
  `EDIT_MODE_LAYOUTS_UPDATED` at the login and on every change), the chat windows' settings, the settings panel's
  opening (`C_SettingsUtil`). Blizzard's `print` writes to the log.
- **Sane UI's caught errors:** Core's guards keep what fails in its error log; the lab shows each one of the run
  as an error ("Sane UI caught").
- **Drawing:** the host sends the page every region that is seen, in the game's order, in the screen's pixels;
  the page draws them and sends back the mouse and the keys. Texts are broken into lines and measured by the
  host with the font files' own widths, so the page draws each line where the game would.
- **Reload:** every file the scene read is watched. A change runs it again as `/reload` does, keeping the saved
  variables of the addons it loaded (`## SavedVariables` of a TOC, `Lab.Saved`); **Fresh** clears them.

## Scenes, worlds and drafts

- **A scene** (`dev/uilab/scenes/<name>.lua`) is lab-only: it loads the code it shows and may build things after
  the login. Its first comment line is its description in the page's list.

  ```lua
  local ns = Lab.Addon("SaneUI_Draft", "dev/uilab/drafts/Draft.lua")     -- files as one addon's (Lua or XML)
  Lab.TOC("src/Core/SaneUI.toc")             -- an addon from its TOC, its Lua and XML files
  Lab.World("default")                       -- the fake server's world (default: default)
  Lab.Blizzard("Blizzard_FrameXMLUtil")     -- one more of Blizzard's addons than the lab loads itself
  Lab.BlizzardFiles("Blizzard_UIPanels_Game", "Camelot/PaperDollFrame.lua")  -- only some files of one, in order
  Lab.OnLogin(function() ... end)            -- after PLAYER_LOGIN and PLAYER_ENTERING_WORLD
  Lab.Slash("/sane window")                  -- a slash command, as typed
  Lab.Say("GUILD", "Mirabel Ashgrove", "Hello")   -- a chat line from the server now
  ```

  The scenes: `groupframes` (Core and Combat from their TOCs: Edit Mode open with the party and raid frame chosen and forty made-up
  units; `LabPreview(10)`, `LabSize(600, 140, 120)`, `LabChoose()` for its dialog in the console; the game's secure headers are not in the lab), `loot` (Core and Loot from their TOCs: the group's roll cards at a share of their time, one running down, `LabLoot.Roll()`; your bags full, so the lines that make room stand beside the window, `LabLoot.BagsFull(false)`; the loot window over the world with a thing of every quality,
  a quest's item and coins; the game's loot functions stand in for a corpse, a click takes a thing, `LabLoot.Open()`
  in the console opens it again), `far-sparkles` (Navigation's marks of far herbs and ore, `Glints.lua`, and a minimap's stand-in with the
  found ones as `Found.lua` rings them, the rest of Navigation standing in, over a screenshot of the world: any texture path not under `Interface\` is a file of the project,
  here one in `assets/generated/ui-lab/backdrops/`, local), `satchel` (Navigation's satchel, `Satchel.lua` and
  `Strays.lua`: its button on a small map's stand-in and its page, with a pretend addon's button and the game's
  addon compartment; `LabSatchel` in the console), `meter` (Core and Combat from their TOCs, the threat and damage meter over the world, the game's meter, threat and a made-up raid standing in, a panel beside it to pull, end fights and change the group: all of the window is the real code, buttons, flyouts, a character's own bars, hiding, dragging, sizing, the wheel; `LabPull()`, `LabEnd()`, `LabGroup(25)`, `LabHalf()`; the numbers stay plain, the hidden ones are `dev/tests/meter.lua`'s), `questlog` (Navigation's quest log, `QuestLog.lua`, the rest of Navigation
  and the game's quest log standing in, a quest unfolded with its text and big reward icons, two ghosts on top; `LabOnScreen()` shows its look
  on the screen alone, `LabRight()` moves it to the right half, `LabQuestLog` in the console), `unitframes` (Core and Combat from their TOCs, your frame with its cast, your three timers
  and your pet, your target's and focus's frames, the game's cast and timer functions standing in; `LabCast("Fireball")` casts, `LabCombat`
  in the console), `guide` (Core from its TOC and Speed Leveling's view, `Steps.lua`, alone, a made-up guide over a screenshot of the world; `LabWheel(-1)` in the console turns the wheel over it, `LabGround(0.9)` reads it on snow, `LabGuide` is the module), `levelup` (Core and Inventory from their TOCs: the toast of a new level over the world, staying up; `LabLevel(23, 18, 20, 1, 0, 2)`
  says another), `auctionscan` (the game's auction house window from its own files and Core from its TOC: the full scan's bar
  under it through its phases, the game's scan calls standing in; `LabScan.Answer()` in the console is the server's answer),
  `deals` (the game's auction house window from its own files, Core, its auction data and Economy from their TOCs: the tab Deals on
  made-up prices, the game's search answers coming by themselves; `LabEmpty()`, `LabScan()`),
  `pricegraph` (Core, its auction data and Tooltips from their TOCs: an item's tooltip with Alt held, its price graph in the Gold
  section on made-up scans; `LabRange("24h")`, `LabTap()` for Ctrl, `LabAlt(false)`, `LabPinned()` for a chat link's tooltip, whose
  buttons take the mouse; when to buy and sell it: `LabBuying(2900)` as a row of the house's list, `LabBuying()` as yours,
  `LabSold(false)`, `LabScans(1)`; the panel's ground is white, as the lab does not load its art),
  `macros` (Core and Macros from their TOCs: Sane Macros open on three macros, the game's spells standing in; `LabMacros` in the
  console), `basics` (plain widgets), `journal-chat` (a chat window in Core's journal look), `inventory` (Core
  and Inventory from their TOCs, the full screen with the character, the stats, the bags and the alts, the stats
  filled by the game's own character sheet files; the module is `LabInventory` in the console), `xml-templates` (a window from the
  scene's own XML on Blizzard's templates), `core` (Core from its TOC, with its window to try windows with; rest
  the mouse on its free corner and it opens; `/sane options` in the console opens Core's options in the game's
  settings panel).

  Everything else in a scene is the game's API.
- **A world** (`dev/uilab/worlds/<name>.lua`) is the fake server:
  - the player with their gear, bags, money, stats and zone;
  - their guild (ranks, members, notes, who is online), the party and others;
  - the chat channels, and a script of chat lines and events at their seconds after the login, played again
    after `loop` seconds.

  Items and spells are the game's own, read from the data master (`assets/data`) by ID. Chat text may hold
  `{item:ID}`, `{spell:ID}` and `{player:Name}`: the lab puts the game's links there. The page's **Server** tab
  sends chat lines and any event while the scene runs. What the player sends (`SendChatMessage`, addon
  messages to the guild or group) comes back as the server sends it.
- **A draft** (`dev/uilab/drafts/`) is code that is meant for the game but not chosen yet, written as an addon's
  file on the game's API alone. Once it is right, it moves into its module (`src/`) as it is, gets Core's guards
  on its scripts (`ns.Guard`, a hard rule there), and joins the TOC. The journal window began as one; it is
  Core's now (`src/Core/Journal.lua`).

## Pictures and fonts

The lab's server finds the files by the paths code gives them, as the game does, case ignored:

| Path | Where the lab finds it |
| --- | --- |
| `Interface\AddOns\SaneUI\...`, `SaneUI_<Module>\...` | `assets/optimized/Core/...` (`<Module>`), then `BUILD/`, then the drafts |
| `Interface\AddOns\SaneUI\Art\Journal\<piece>` | Core's textures (`dev/tools/journal-art`); only where one is missing the harness's `assets/generated/interface/pieces/<piece>.png` |
| `Interface\...` | Blizzard's art, the newest export's (`dev/tools/blizzard where`) |
| a file ID (`GetItemInfo`'s icons) | the game's listfile (below) |
| `Fonts\FRIZQT__.TTF` and the game's other fonts | stand-ins: the client ships them compiled, so they cannot be read |
| `Interface\AddOns\SaneUI\Fonts\Kalam-Regular.ttf` | the addon's font, else `assets/fonts` by its name |

BLP and TGA files become PNG once, in `assets/generated/ui-lab/` (local, with the saved variables of the lab's
runs). A missing texture is drawn as a magenta box and named in the log.

The settings of this computer are in `~/.config/saneui/uilab.json`, all optional:

- `client`: a folder of the client's tables as CSV. It gives the game's named colours (`GlobalColor`), its global
  strings, and the names and colours of classes and races. Without it the lab keeps a few of its own.
- `listfile`: file IDs to paths (`id;path`).
- `atlas`: the game's atlases (TSV: `name file fileDataID width height left right top bottom tileH tileV`).
- `drafts`: more addon folders served from elsewhere, `{"SaneUI/Art/Journal": "assets/generated/interface/pieces"}`.
- `fonts`: stand-ins for the game's fonts, by file name.

## The page

- **Header:**
  - the scene and the world;
  - the screen (1080p, 1440p, 4K) and the UI scale: a UI unit is `screen height / 768` pixels times the scale,
    as in the game (`Doc/guides/images.md`), and the journal's pieces are drawn for UI scale 1;
  - the backdrop and the zoom;
  - **Reload**, **Fresh**, **Pause**.
- **Log:** errors with their stacks (the lab's own lines left out), warnings, what is not in the lab yet,
  `print`, the console's results, sounds and addon messages.
- **Inspect** (I): the frames under the mouse, top first. For each: its name, kind, size, strata and level, its
  anchors, the file and line that made it, and its regions there (textures with their files, texts with their
  fonts). A click keeps the list.
- **Console:** Lua in the game's environment, as `/run`; an expression shows its value, as `/dump`. Slash
  commands work too, `/reload` among them.

## Limits, and what comes next

- XML: what the lab does not read yet it tells (in Blizzard's own files under "the lab"): `<ModelScene>` and other
  model kinds, the animations past alpha, translation, scale and rotation, `autoplay`, a few attributes. A
  script of a texture or a font string is kept and its OnLoad runs, but the mouse reaches frames only.
- Blizzard's interface: only the addons named above; the game's own windows and HUD (action bars, the minimap,
  bags, the micro menu, Edit Mode's window) are not loaded, so Core's parts that lean on them stand aside, as
  Core's code allows where they are missing. What Blizzard's shared
  code calls of them does nothing (`CloseAllBags`, `UpdateMicroButtons`). The client's state the lab has no
  source for is its own choice, said where it is made: the CVars it knows, Edit Mode's default layout (Modern),
  the chat windows of a new character, no gamepad, no kiosk.
- Blizzard's code and art are the newest export's (`dev/tools/blizzard where`), never `references/`; without one on
  the computer the lab does not start. A picture that export lacks (a few hundred old ones the install does not
  hold) is a magenta box.
- No 3D: a model frame is a dashed box.
- Not the game's renderer: the page draws with the browser. Texts use the font files' widths without kerning.
  Masks (`CLAMPTOWHITE` too: the page draws those onto a canvas), blend modes and texture coordinates follow the game's
  rules, but sub-pixel edges can differ, and a status bar's atlas is taken for a file. Judge the final look in the game.
- The pieces repeat by drawing one texture per tile with their texture coordinates, so the art can go into the
  game in power-of-two textures, `SetTexCoord` taking the part in use (`Doc/guides/images.md`).
- Next: Core's own windows (`Window`, `Board`, `Views`) built in scenes of their own, and the modules from their
  TOCs.
