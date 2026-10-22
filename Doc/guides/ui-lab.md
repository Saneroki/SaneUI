# The interface lab

A local website that runs Sane UI's Lua as the game runs it and draws what it makes, so windows can be built and
refined in the browser with the same code that then goes into the game. The texts that would come from the
server (who is online, chat, items) come from a fake server.

```bash
saneui showuilab
```

It is on 127.0.0.1 port 8774, in a browser. `saneui checkuilab [scene]` runs a scene without the page for a few seconds and
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
  (`references/BlizzardInterfaceCode`, `Blizzard_APIDocumentationGenerated`). Such a method is still there, as in
  the game, and calling it puts a "not in the lab" line in the log. The same documentation gives `Enum`,
  `Constants` and the list of events: registering an event the game does not have is an error, as in the game.
- **Blizzard's own shared Lua** (`Blizzard_SharedXMLBase`, and the parts of `Blizzard_SharedXML` that stand
  without its XML) runs as it is, so `Mixin`, `CreateColor`, the colour constants, pools, callbacks and
  `BackdropTemplate` are Blizzard's. Its font objects (`GameFontNormal` and the rest) are read from its font XML.
- **Drawing:** the host sends the page every region that is seen, in the game's order, in the screen's pixels;
  the page draws them and sends back the mouse and the keys. Texts are broken into lines and measured by the
  host with the font files' own widths, so the page draws each line where the game would.
- **Reload:** every file the scene read is watched. A change runs it again as `/reload` does, keeping the saved
  variables of the addons it loaded (`## SavedVariables` of a TOC, `Lab.Saved`); **Fresh** clears them.

## Scenes, worlds and drafts

- **A scene** (`dev/uilab/scenes/<name>.lua`) is lab-only: it loads the code it shows and may build things after
  the login. Its first comment line is its description in the page's list.

  ```lua
  local ns = Lab.Addon("SaneUI_Draft", "dev/uilab/drafts/Journal.lua")   -- files as one addon's
  Lab.TOC("src/Core/SaneUI.toc")             -- an addon from its TOC (its XML files are not read yet)
  Lab.World("default")                       -- the fake server's world (default: default)
  Lab.OnLogin(function() ... end)            -- after PLAYER_LOGIN and PLAYER_ENTERING_WORLD
  Lab.Say("GUILD", "Mirabel Ashgrove", "Hello")   -- a chat line from the server now
  ```

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
  file on the game's API alone. `Journal.lua` builds the journal window from the art's pieces. Once it is right,
  it moves into its module (`src/`) as it is, gets Core's guards on its scripts (`ns.Guard`, a hard rule there),
  and joins the TOC.

## Pictures and fonts

The lab's server finds the files by the paths code gives them, as the game does, case ignored:

| Path | Where the lab finds it |
| --- | --- |
| `Interface\AddOns\SaneUI\...`, `SaneUI_<Module>\...` | `assets/optimized/Core/...` (`<Module>`), then `BUILD/`, then the drafts |
| `Interface\AddOns\SaneUI\Art\Journal\<piece>` | not chosen yet: `assets/generated/interface/pieces/<piece>.png` |
| `Interface\...` | Blizzard's art, `references/BlizzardInterfaceArt` |
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

- XML is not read yet, so frames made from Blizzard's XML templates (`UIPanelButtonTemplate`,
  `TabSystemTemplate`) get no template: the lab says so and makes the frame without it. Font XML is read. Next:
  frame and texture templates from XML, then Core loaded from its TOC, so Core's windows (`Window`, `Board`,
  `Views`) can be built in the lab too.
- No 3D: a model frame is a dashed box.
- Not the game's renderer: the page draws with the browser. Texts use the font files' widths without kerning.
  Masks, blend modes and texture coordinates follow the game's rules, but sub-pixel edges can differ. Judge the
  final look in the game.
- The pieces repeat by drawing one texture per tile with their texture coordinates, so the art can go into the
  game in power-of-two textures, `SetTexCoord` taking the part in use (`Doc/guides/images.md`).
