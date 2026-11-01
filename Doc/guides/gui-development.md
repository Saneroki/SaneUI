# GUI development

How to build windows, lists, menus and other widgets so they behave like Blizzard's and look like Sane UI's
own ([interface-style.md](interface-style.md)). Read this before creating or changing anything the player
sees. For what a feature should show, read
[blizzard-design-principles.md](blizzard-design-principles.md). For code rules (taint, combat, events),
read [addon-standards.md](addon-standards.md).

## Sane UI's own look

Sane UI redesigns every window and view it makes or recreates (Saneroki, 2026-10-30, replacing the journal look of
2026-10-21): the layout stays Sane UI's own, but it is built from WoW: Forever's own images in the game's default
fonts; the pencil drawing icons stay; no red buttons, but natural buttons with golden or silver, beaten-up metal
borders. The parts are picked by number from the catalogue (`saneui showgameart`); the picks, the references (the
character list, the character screen's top bar) and how Retail is served stand in
[interface-style.md](interface-style.md), *The new direction*. What is built in the journal look (parchment,
leather, Kalam, Sane UI's own painted art) keeps it until it is rebuilt from the picks. The game's
native windows that Sane UI does not recreate stay as the game draws them, mostly untouched.

What stays from Blizzard for our own windows too: how the game works, found in Blizzard's code as below
(its API, events, secure templates and taint, scaling, Esc and the window manager, languages), and the
design principles of what a view shows and how it behaves
([blizzard-design-principles.md](blizzard-design-principles.md)). Where this guide below says to use
Blizzard's art or fonts for the look, that holds for our own windows too (the images and fonts are the game's,
the layout ours); its templates' looks hold for the native windows Sane UI changes in place.

## The one rule

**Look it up in Blizzard's code first (its newest export, `dev/tools/blizzard where`), then build with Blizzard's own parts** (for how it works; the look of
our own windows is Sane UI's, above). Blizzard's interface is
written in the same Lua and XML an addon uses, and its templates, fonts, colours, textures and sounds
are all available to us. Something built from them looks right, follows the client's scaling and
languages, and changes with the game. Something drawn by hand does none of that.

1. Find the Blizzard window that solves the nearest problem (`Interface/AddOns/Blizzard_*` of the newest export's code).
2. See which template, font and art it uses, and how it behaves (open, close, sound, tooltip, Esc).
3. Use the same parts. Write own code only for what Blizzard has no part for.

The newest export (`dev/tools/blizzard where`) holds several game flavours side by side (`Mainline`, `Classic`, `Camelot`, `Shared`
folders). A file only exists in our client if the Blizzard TOC next to it loads it there: check the
`.toc` (`[Family]`, `[Game]`, `[AllowLoadGameType ...]`) before relying on a template. Every name in
this guide was found in the export of 2026-10-14; check again in the newest export before use, and guard for `nil`.

## Building blocks

| Need | Blizzard part | Where in the newest export |
| --- | --- | --- |
| Window with title, close button, portrait | `ButtonFrameTemplate`, `PortraitFrameTemplate`; without portrait: `ButtonFrameTemplate_HidePortrait`, `DefaultPanelTemplate` | `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml` |
| Sunken area inside a window | `InsetFrameTemplate` | same |
| Borders and backgrounds from pieces | `NineSliceUtil.ApplyLayout` with a named layout | `Blizzard_SharedXML/NineSlice.lua`, `Blizzard_SharedXML/Mainline/NineSliceLayouts.lua` |
| Simple border and fill | `BackdropTemplate`, `TooltipBackdropTemplate` | `Blizzard_SharedXML/Backdrop.xml` |
| Button | `UIPanelButtonTemplate`, `SharedButtonTemplate`; close: `UIPanelCloseButton` | `SharedUIPanelTemplates.xml`, `Shared/Button/` |
| Checkbox | `UICheckButtonTemplate` | `Shared/Button/CheckButtonTemplates.xml` |
| Text input, search box | `InputBoxTemplate`, `SearchBoxTemplate` | `Shared/InputBox/InputBoxTemplates.xml` |
| Tabs | `PanelTabButtonTemplate` with `PanelTemplates_SetNumTabs` / `PanelTemplates_SetTab`; newer: `TabSystemTemplate` | `SharedUIPanelTemplates.*`, `Shared/TabSystem/` |
| Scrolling list | `WowScrollBoxList` + `MinimalScrollBar` + a view + a data provider | `Blizzard_SharedXML/Shared/Scroll/`, `DataProvider.lua` |
| Context menu, dropdown | `MenuUtil.CreateContextMenu`, `WowStyle1DropdownTemplate` with `:SetupMenu` | `Blizzard_Menu/` (read `11_0_0_MenuImplementationGuide.lua`) |
| Options page | `Settings.RegisterVerticalLayoutCategory` and `...Subcategory` (a page under a page, of the game's controls), `Settings.RegisterCanvasLayoutSubcategory` (a page drawn by own code: Profiles and Core's tabbed module pages), `Settings.CreateElementInitializer` (an own row in a list: the banner), `Settings.OpenToCategory`, `Settings.RegisterAddOnSetting`, `Settings.CreateCheckboxInitializer` / `CreateDropdownInitializer` / `CreateSliderInitializer` with `Settings.RegisterInitializer`, `Settings.RegisterAddOnCategory` | `Blizzard_Settings_Shared/` (read `Blizzard_ImplementationReadme.lua`) |
| Tooltip | `GameTooltip`, `GameTooltip_SetTitle`, `GameTooltip_AddNormalLine` / `AddHighlightLine` / `AddInstructionLine` / `AddErrorLine` / `AddDisabledLine` | `Blizzard_SharedXML/SharedTooltipTemplates.lua` |
| Yes/no or text question | `StaticPopupDialogs[...]` + `StaticPopup_Show` | `Blizzard_StaticPopup/` |
| One-time hint pointing at something | `HelpTip:Show` | `Blizzard_SharedXML/HelpTip.lua` |
| Many frames of one kind | `CreateFramePool` | `Blizzard_SharedXMLBase/Pools.lua` |
| Shared behaviour | `Mixin`, `CreateFromMixins`, `CallbackRegistryMixin` | `Blizzard_SharedXMLBase/` |
| Money, big numbers | `GetMoneyString`, `FormatLargeNumber` | `Blizzard_SharedXML/FormattingUtil.lua` |
| Icon inside text | `CreateAtlasMarkup`, `CreateTextureMarkup` | `Blizzard_SharedXMLBase/TextureUtil.lua` |

In Sane UI the options pages are filled by Core's options (`src/Core/Settings/`), not by a module directly: a
module describes its switches to Core and gets a page of its own under *Sane UI*
([src/Core/Settings/README.md](../../src/Core/Settings/README.md)).

An addon's category must be registered before the options window first opens: `SettingsPanelMixin:OnShow`
hides the *Game* and *AddOns* tabs for the whole session when no addon category exists at that moment, and
nothing shows them again. A page registered later (from a load-on-demand addon) is then unreachable. Core
registers Sane UI's pages at login for that reason; only their controls wait until the options first open.

## Windows

- A window of ours is `Core.Window.New` with `skin = true`: Core's skin (the game's dark dialog tile and a thin trim in
  Sane UI's bronze, with round corners that are square on the screen's edges, as set: Core's `Shape.lua`)
  is the look of Sane UI's windows until each is rebuilt from Forever's own images in its own layout
  ([interface-style.md](interface-style.md), *The new direction*). A dialog that should look like one of the game's starts from a
  Blizzard frame template (`ButtonFrameTemplate`), which brings border, title bar, close button and the
  right sizes. Neither rebuilds a border from single textures: the game has no border whose corners take
  any radius, so Core's Shape is the one place that draws one.
- **Esc closes it:** add the frame's global name to `UISpecialFrames`. This is the safe way for an
  addon window that opens and closes. Not `ShowUIPanel`/`UIPanelWindows`: see
  [addon-standards.md](addon-standards.md), section 5, known traps.
- Opening and closing play the same sounds as Blizzard's windows (`PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)`
  / `..._CLOSE`; tabs `IG_CHARACTER_INFO_TAB`; checkbox `IG_MAINMENU_OPTION_CHECKBOX_ON`). Always by
  `SOUNDKIT` constant, never by number or file. A sound of our own only where the game has none that fits
  (`Doc/guides/voice-generation.md`, *Short sounds*): a file in `assets/optimized/<Module>/Sounds/` (never in
  `src/`), which `dev/build` puts into the addon's `Sounds/`, played with
  `PlaySoundFile(path, "SFX")`.
- A movable window is clamped to the screen (`SetClampedToScreen(true)`), remembers its place, and has
  a way back to the default place. In Sane UI that is Core's work, never a module's own code:
  `Core.Window.New` for a window of ours (arranged in Blizzard's Edit Mode, as the game's own frames:
  Edit Mode's box to drag it by and a grip, there only; a title bar for a kind of window that has one,
  with its name, a fuzzy search and the buttons [the game's own window] [full screen] [close], by which it
  also moves; docking to the screen's edges, a skin, the kept place and what it was left as). Every
  window, the ones that stand for a game window too (a spellbook, a vendor), is one of these: the
  game's key or NPC opens ours, as the player left it (`window:Open()`), `Core.Window.Mover` and `Sizer` for one of the game's, `Core.Expand.New` for a window
  that opens once the mouse rests on it (and can be kept open), `Core.Bar.New` for a progress bar
  ([src/Core/README.md](../../src/Core/README.md)).
- Build the window when it is first opened. Create child widgets once and reuse them.
- Use the lowest frame strata and level that works. Raising a frame to be "on top" hides tooltips and
  other addons.
- Never anchor into, re-parent or resize a protected Blizzard frame in combat
  ([addon-standards.md](addon-standards.md), section 5).

## Layout

- Anchor relative to the parent and to neighbours (`SetPoint`), not to absolute screen positions. The
  layout must survive a different UI scale, resolution and longer text in another language.
- Take spacing from the Blizzard window that was the model, instead of inventing numbers. Keep one set
  of spacing values per module in one place.
- Let text decide the size where it can (`GetStringWidth`, word wrap, a set width). Never cut a
  translated text by a fixed pixel width without an ellipsis and a tooltip with the full text.
- Align to whole pixels; half pixels blur lines and borders.
- Click targets are as large as Blizzard's for the same control.

## Art

- **Atlas first:** `texture:SetAtlas("name")`. Atlas names survive when Blizzard repacks its texture
  files. Second choice is a file path into the client (`Interface\...`), found in
  the newest export's art. Icons by file ID from the API.
- Blizzard's art is used from the client, never copied into the addon (policy and licence).
- Sane UI's own windows are built from WoW: Forever's own images (above: atlas first), picked by number from
  the catalogue (`saneui showgameart`) and written into [interface-style.md](interface-style.md), *The new
  direction*, in Sane UI's own layouts; the pencil drawing icons stay. The parts still in the journal look
  (painted parts in `assets/`, stretched and tiled by code, with text, stains and sketches laid over them by
  code) keep it until they are rebuilt from the picks. Blizzard's art (above) for the native windows Sane UI
  changes in place, and for the game's icons.
- Own pictures: format, size for 4K, encoder and how to draw them are decided in
  [images.md](images.md) (BLP2, DXT5 with mipmaps, made by `dev/tools/art`; the game's own filter).
- Stretch only what was made for it (nine-slice borders, tiling backgrounds). Everything else keeps its
  proportions (`SetAtlas(name, true)` uses the atlas size).
- Do not tint Blizzard art into new colours piece by piece to make a "theme"; tint it only where
  Blizzard does (desaturate for unavailable, vertex colour for state).

## Text

- **Stats are written short** (Saneroki, 2026-10-30): every view that names a stat takes the word from `Core.StatWord`, a
  line of a number and a stat from `Core.StatLine` (`src/Core/Stats.lua`): Str, Stam, Crit. A new stat's word goes there,
  never into a module.
- **Distances and the time of day follow the setting Units** (Saneroki, 2026-10-30; Metric at first): the code keeps yards,
  what a player reads comes from `Core.Distance`, `Core.DistanceText`, `Core.Clock` and `Core.ClockAt`
  (`src/Core/Units.lua`), never a written `"%d yd"` or `date("%H:%M")`. A slider of yards: `distance = true`.
- **Sane UI's own windows:** the game's default fonts, by their font objects as below (Saneroki, 2026-10-30;
  [interface-style.md](interface-style.md), *The new direction*). The parts still in the journal look keep its
  text until they are rebuilt: Kalam in pencil grey with the paper's grain on paper, pressed into the leather
  on leather, both made in code (*Text* there), Sane UI's own font file behind a font object of our own that
  falls back to the game's font for a language Kalam lacks.
- **Native windows: font objects (`SetFontObject`), never a font file of our own.** The client's font objects switch
  fonts per language and follow its text settings. To change only the size, take file and flags from
  the game's font object (`GetFont`) and set them back with the new size, as Chat does with
  `ChatFontNormal` and Tooltips with `GameTooltipText`: the file still follows the language. The basic
  set (`Blizzard_Fonts_Shared/Shared/FontStyles.xml`):

  | Font object | Looks | Use for |
  | --- | --- | --- |
  | `GameFontNormal` | gold | titles, labels, headers |
  | `GameFontHighlight` | white | values, body text, the thing the label names |
  | `GameFontDisable` | grey | unavailable, switched off |
  | `GameFontRed` / `GameFontGreen` | red / green | cannot / can, error / good |
  | `...Small`, `...Large`, `...Huge` | same colours | secondary text, window headings |

- **Colours by constant**, not by number: `NORMAL_FONT_COLOR`, `HIGHLIGHT_FONT_COLOR`,
  `DISABLED_FONT_COLOR`, `RED_FONT_COLOR`, `GREEN_FONT_COLOR`, `GRAY_FONT_COLOR`; item quality from
  `ITEM_QUALITY_COLORS`, classes from `RAID_CLASS_COLORS`. Wrap with `color:WrapTextInColorCode(text)`.
- Colour has a fixed meaning in WoW (gold label, white value, grey unavailable, red not possible, green
  available, quality colours for items). Do not reuse a colour for something else.
- **Never colour alone:** pair it with an icon, a word or a state
  ([principle 11](blizzard-design-principles.md)).
- Reuse Blizzard's translated strings where one fits; keep own texts short.
- **An edit box of several lines keeps the game's blinking cursor only if the game can lay it out in peace**
  (Saneroki, 2026-11-01): no text insets above or below (the room around its text belongs to what stands
  behind it, as the plate of Social's line, with `SetHitRectInsets` so a click there is still the box's), and
  its height written only when a line comes or goes, never with every key or frame: the game grows such a box
  with its text by itself. Nothing fails when this goes wrong, the text just has no cursor: look here first
  when a field shows none. `OnCursorChanged` tells where the cursor stands; `x` and `y` count from inside the
  insets.

## Lists

Use the scroll box, not a hand-made list of frames and not the old `FauxScrollFrame`/`HybridScrollFrame`:

```lua
local box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
local bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
local view = CreateScrollBoxListLinearView()
view:SetElementInitializer("SomeRowTemplate", function(row, data)
    row:Init(data)            -- set every visible field: rows are reused
end)
ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)

local provider = CreateDataProvider()
view:SetDataProvider(provider)
provider:Insert({ ... })
```

- Rows are recycled. The initializer must set **every** field it shows, or an old row's content
  appears in a new place. Use `SetElementResetter` to undo special state.
- With a plain frame type instead of a template, give the row height (`SetElementExtent` or
  `SetElementExtentCalculator`).
- Trees: `CreateScrollBoxListTreeListView` with `CreateTreeDataProvider`. Grids:
  `CreateScrollBoxListGridView`.
- Change the data, not the frames: insert, remove or sort in the provider and let the view redraw.
- A search field over a large list waits a moment after the last key before filtering.

## Menus and dropdowns

Use the menu system from `Blizzard_Menu`:

```lua
MenuUtil.CreateContextMenu(owner, function(_, root)
    root:CreateTitle(title)
    root:CreateButton(text, function() ... end)
    root:CreateCheckbox(text, isSelected, setSelected)
end)
```

The old `UIDropDownMenu` is still in the client but is a known source of taint
([addon-standards.md](addon-standards.md), section 5): do not use it.

## Tooltips

- Use `GameTooltip`. Show it in `OnEnter` (`GameTooltip:SetOwner(self, "ANCHOR_RIGHT")`), hide it in
  `OnLeave`. Never leave it open, never keep it open by a timer.
- First line is the title (`GameTooltip_SetTitle`), then normal lines; hints for clicks as instruction
  lines (green), reasons something is not possible as error lines (red).
- A tooltip explains; it must not be the only place for something the player needs in order to act.
- Adding to Blizzard's tooltips goes through `TooltipDataProcessor.AddTooltipPostCall`, not by
  replacing tooltip scripts.

## Changing a Blizzard window

- Add to it through `hooksecurefunc` and `HookScript`. Own widgets are children of own frames that are
  anchored to the Blizzard frame; own state lives in own tables.
- Never write a field on a Blizzard frame, replace one of its scripts or functions, or change one of
  its tables.
- Do not hide or move Blizzard's regions permanently. Every change must be undone by the module's
  fall-back (`GiveBack`, which Core's `StandDown` runs), and the Blizzard window must work untouched
  when our part fails.
- Edit Mode's manager frame is read, never written; a layout is set through `C_EditMode` out of combat
  and outside Edit Mode, with a `/reload` asked for afterwards (Sync; [addon-standards.md](addon-standards.md),
  section 5). An own movable window keeps its own place through `Core.Window.New`.
- Blizzard frames can change under us with any client update: check that a frame and its children
  exist before touching them.

## Motion

- Animation groups (`CreateAnimationGroup`) for the fade, pulse or slide of one frame. Where many
  recycled rows move at once (Chat's fading messages) one `OnUpdate` on their window, which stops
  itself as soon as nothing moves.
- A `TextureCoordTranslation` (art scrolling inside its region) comes from an XML template,
  `CreateAnimationGroup(nil, "SaneUI...Template")`, as the game's own UI defines it: one made in Lua with
  `CreateAnimation` has no `SetOffset` in this client, and calling it is an error.
- Short and rare. Motion means "look here" ([principle 2](blizzard-design-principles.md)). Nothing
  loops for ever.

## Structure of GUI code

- One file per widget or view, with a table of its own (`ns.Bubble`, `ns.BookItem`) or, for an XML
  template, a mixin; its `Init(frame, data)` sets every field (and a `Reset` where needed). No file
  that builds a whole window with all its rows and logic.
- Data and logic do not know about frames. A view reads data and draws it; a click calls a function
  of the logic. This also lets the logic be tested outside the game.
- Sizes, spacing and colours of a module in one place, built from Blizzard's constants.
- Follow the style the module already has (Lua-built frames or XML templates); do not mix both in one
  module without a reason.

## Checklist for a new window or widget

- [ ] The nearest Blizzard window was found in Blizzard's code (the newest export) and used as the model.
- [ ] Built from Blizzard templates; the templates exist for this client's flavour.
- [ ] Art by atlas or client path, nothing copied; fonts by font object; colours by constant.
- [ ] A window that opens and closes does it like Blizzard's: sound, Esc, close button. A part that
      stays (`Core.Window.New`): moved by its bar, clamped to the screen, its place kept.
- [ ] Created on first use; does nothing while hidden.
- [ ] Lists use the scroll box and set every field in the initializer.
- [ ] Reads without colour, with large text, and with long translated text.
- [ ] Nothing written into Blizzard frames; protected frames untouched in combat.
- [ ] On an error the Blizzard default is back.
- [ ] The answer says what the game needs to take it: a `/reload`, or a restart (a TOC change, a new file).

## Sources

| Source | Used for |
| --- | --- |
| Blizzard's code, the newest export (`dev/tools/blizzard where`) | every template and function name |
| [Making scrollable frames (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/Making_scrollable_frames) | Lists |
| [Secure Execution and Tainting (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting) | Changing a Blizzard window |
| [Secret Values (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/Secret_Values) | widgets that show combat values |
| [UI best practices (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/UI_best_practices) | hooks, event handlers |
| [XML user interface](https://warcraft.wiki.gg/wiki/XML_user_interface), [Mixin](https://warcraft.wiki.gg/wiki/Mixin), [FramePoolMixin](https://warcraft.wiki.gg/wiki/FramePoolMixin) (Warcraft Wiki) | templates, mixins, pools (read as search summaries only) |
| [Dragonflight HUD and UI Revamp (Blizzard)](https://news.blizzard.com/en-us/article/23841481/world-of-warcraft-dragonflight-hud-and-ui-revamp) | accessibility, Edit Mode |

The rules on `UISpecialFrames`, `ShowUIPanel`, `UIDropDownMenu` and Edit Mode taint are community
experience, not from a page listed here. Test in the game before relying on them either way.
