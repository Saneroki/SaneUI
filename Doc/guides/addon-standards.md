# Addon standards and best practices

The rules a World of Warcraft addon has to follow, and the conventions good addons share. Read this
before writing or reviewing code. For what a feature should show, read
[blizzard-design-principles.md](blizzard-design-principles.md). For frames and widgets, read
[gui-development.md](gui-development.md).

Every API named here must be checked against `references/BlizzardInterfaceCode` for this client before
it is used: the reference is the ground truth, the web is not. Lines marked *(convention)* are
long-standing community practice, not taken from a page listed under [sources](#sources).

## 1. Blizzard's rules

The [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534)
is binding:

1. **Free.** No paid versions, no paid download, no paid service around the addon.
2. **Visible code.** No hiding, no obfuscation.
3. **No harm to realms or players.** Named examples: too much chat traffic, unnecessary disk reads, slow
   frame rates.
4. **No advertising** in the game.
5. **No donation requests in the game.** They may be on the addon's website only.
6. **No objectionable content** (the game's age rating applies).
7. **Terms of Use and EULA apply.**
8. **Blizzard may disable any addon function** at any time.

Blizzard's art and sounds stay Blizzard's: an addon uses them from the client by path or atlas name and
does not ship copies of them.

Since patch 12.0 there is also a design rule: an addon may present combat information but must not
compute decisions from it ([principle 12](blizzard-design-principles.md)).

## 2. The TOC file

- One `.toc`, named like its folder. Directives are `## Name: value`, other `#` lines are comments,
  every other line is a file, loaded top to bottom. Use backslashes in paths.
- **Needed:** `Interface`, `Title`, `Notes`, `Author`, `Version`. **Useful:** `Category` (the header in
  the addon list), `IconTexture` or `IconAtlas`, `AddonCompartmentFunc` (the minimap's addon list),
  `SavedVariables`, `SavedVariablesPerCharacter`, `OptionalDeps`, `X-...` for own metadata.
- **Loading:** `LoadOnDemand: 1` loads only on `C_AddOns.LoadAddOn`; `LoadWith` loads together with
  another addon; `Dependencies` must load first; `OptionalDeps` load first if present.
- **Several addons that belong together:** the addon list shows an addon under another one when its
  `Group` is that addon's folder name (the client sets it by itself for similar names with a dependency;
  `Blizzard_AddOnList/AddonList.lua`). An addon whose dependency is switched off does not load.
- In Sane UI a module's `Title` is its plain name (*Abilities*, not *Sane UI Abilities*): it stands under
  *Sane UI* in the addon list already.
- Several game versions: prefer a comma-separated `Interface` and per-line conditions
  (`[AllowLoadGameType ...]`) over several TOC files.
- Media files are not listed. Only Lua and XML are.
- In Sane UI every module is an addon of its own with its TOC in its folder (`src/Core/SaneUI.toc`,
  `src/Abilities/SaneUI_Abilities.toc`). A module's TOC says `## Dependencies: SaneUI` and
  `## Group: SaneUI`, and the TOCs share `Interface` and `Version`. A file that is not in its module's TOC
  is never loaded. `dev/tests/lint` checks all of this.

## 3. Loading and start-up

| Moment | What is safe |
| --- | --- |
| File is read | Define things only. No saved variables yet, no game data. |
| `ADDON_LOADED` (check the name argument) | Saved variables are there. Apply defaults. |
| `PLAYER_LOGIN` | Once per session. Most game data is there. One-time setup. |
| `PLAYER_ENTERING_WORLD` | Every loading screen. Only for work that must repeat per zone. |
| `SPELLS_CHANGED` | The spellbook is filled. Anything that reads spells waits for this. |
| `PLAYER_LOGOUT` | Last chance to write saved variables. |

- `VARIABLES_LOADED` is no signal for saved variables (they are there at `ADDON_LOADED`). It says the
  game's own stored settings, the CVars, have arrived, which on a slow login is after
  `PLAYER_ENTERING_WORLD`: Sync waits for it when `C_CVar.AreCVarsLoaded` says no. `PLAYER_ALIVE` is no
  start-up signal at all.
- A load-on-demand addon can arrive at any time: never assume the order above for somebody else's addon.
- **Do the work late.** Build a window when it is first opened, not at login. Ask the game for an event
  only once something listens. In Sane UI, Core does both (`OnLoad`, `OnLogin`, `Core.On`); see
  [src/Core/README.md](../../src/Core/README.md).

## 4. Names and globals

- **Everything is `local`.** Globals are slower, collide with other addons and can taint Blizzard's code
  (the classic case: an addon writing a global named like one of Blizzard's).
- Share between files through the addon's private table: `local ADDON, ns = ...`. Not through globals.
  Between addons there is no such table: Sane UI's addons share one global table, `SaneUI`, and nothing else.
- A global is only allowed where the client demands one (slash commands `SLASH_...`, key binding names
  `BINDING_...`, saved variables, the compartment function, named frames and font objects, a mixin an
  XML template names). Prefix every one with the addon's name. In Sane UI the lint fails on any other
  global write.
- **Frame names:** give a frame a global name only when something needs it (Esc-to-close, a Blizzard
  template that looks up `$parentChild`, debugging). Prefix it: `SaneUI...`.
- Keep a `local` alias of a global function only in code that runs very often. Elsewhere it is noise.

## 5. Taint and protected actions

Blizzard's own code runs *secure*. Addon code is *tainted*, and taint spreads to everything it writes.
When a tainted path reaches a protected function (casting, targeting, moving a protected frame in
combat) the call is blocked and the player sees "action blocked by an addon". Taint stays until
`/reload`.

- **Never write into Blizzard's things.** No fields on Blizzard frames (`SomeBlizzardFrame.myFlag = x`),
  no replaced global functions, no changed Blizzard tables. A value an addon wrote is tainted, and
  Blizzard's code reading it later becomes tainted too. Keep own state in own tables, keyed by the
  frame if needed.
- **Hook, do not replace.** `hooksecurefunc(name, fn)` and `frame:HookScript(script, fn)` run after the
  original, get copies of the arguments and leave the original secure. If a function really must be
  replaced: keep the original in a local, pass `...` through and return every result.
- **Protected frames** (action buttons, unit frames, anything from a secure template) cannot be shown,
  hidden, moved, resized or re-parented by addon code in combat. The same lock reaches their parents
  and frames anchored to them. Once protected, a frame stays protected.
- **Combat:** check `InCombatLockdown()` before touching a protected frame. If it is locked, remember
  the change and apply it on `PLAYER_REGEN_ENABLED`. Finish secure setup before `PLAYER_REGEN_DISABLED`.
- Behaviour that must work in combat is built from secure templates (`SecureActionButtonTemplate`,
  `SecureHandler...`) and frame attributes set out of combat.
- **Known traps** *(convention)*: the old `UIDropDownMenu`, Edit Mode's manager frame, and
  `ShowUIPanel`/`UIPanelWindows` with addon windows have all carried addon taint into combat code. Use
  the newer menu system ([gui-development.md](gui-development.md)). Edit Mode's manager is read, never
  written: a layout is set through `C_EditMode.SetActiveLayout` out of combat and outside Edit Mode, and
  a `/reload` is asked for afterwards, since the manager moved the game's frames in our call (Sync's
  `hudLayout` part, `src/Core/Sync/Layout.lua`).
- **Finding taint** *(convention)*: `/console taintLog 1` writes `Logs/taint.log`; the events
  `ADDON_ACTION_BLOCKED` and `ADDON_ACTION_FORBIDDEN` name the addon. Turn the log off afterwards.

## 6. Secret values

Since patch 12.0 the client hands some combat values (health, auras, cooldowns) to addon code as
*secret values*. This client has them (`issecretvalue` is in the reference).

- **Allowed:** store them, pass them on, concatenate or `format` them into text, and give them to
  widget methods that accept them from addon code: those whose entry in `Blizzard_APIDocumentationGenerated`
  says `SecretArguments = "AllowedWhenTainted"` (`FontString:SetText`, `StatusBar:SetValue` and
  `SetMinMaxValues`, `Region:SetVertexColor`, `SetAlpha`, `SetAlphaFromBoolean`, `Texture:SetTexture`, ...).
  `"AllowedWhenUntainted"` is for Blizzard's own code only: `SetShown` and `Cooldown:SetCooldown` are of
  these (checked 2026-10-16). A cooldown swirl or a bar that runs out takes a duration object of the game
  instead (`C_UnitAuras.GetAuraDuration` into `Cooldown:SetCooldownFromDurationObject` or
  `StatusBar:SetTimerDuration`; to try in the game).
- **An immediate Lua error:** arithmetic, comparison, `#`, indexing, calling, or a boolean test on a
  secret boolean.
- **Never use one as a table key.** It locks that table for good.
- A widget that was given a secret returns secrets from its getters afterwards, and frames anchored to
  it can become secret in position and size.
- Test with `issecretvalue(v)` / `canaccessvalue(v)` before computing with anything read from the game.
  In Sane UI everything read from the game goes through `Core.Plain(value)`, which gives `nil` for a
  hidden value; `Core.Ask(fn, ...)` calls a game function that may be missing or fail and gives its
  answers plain.

## 7. Events and performance

CPU matters more than memory: everything an addon does happens between two frames.

- **Events, not polling.** No `OnUpdate` unless something really changes every frame. For anything
  else use `C_Timer.After`, `C_Timer.NewTicker` or an animation group. An `OnUpdate` that stays must
  throttle itself and must stop (hide its frame) when idle.
- **Unregister** what is no longer needed. Use `RegisterUnitEvent` for unit events so the client
  filters by unit.
- **Burst events** (`BAG_UPDATE`, `ZONE_CHANGED`, aura and spell updates) fire many times in a row.
  Prefer the delayed variant where one exists (`BAG_UPDATE_DELAYED`), or mark "dirty" and do the work
  once on the next frame. In Sane UI: `Core.Later(fn, delay)` gives a function that runs `fn` once, on
  the next frame or `delay` seconds later, however often it is called before then.
- **Do nothing while hidden.** A window updates when it is shown and on events while shown.
- **Do nothing heavy in combat.** Rebuilds, scans and sorting wait until combat ends.
- **Garbage:** do not create tables or closures in code that runs often; reuse them. Do not build
  strings in a loop that are thrown away. Reuse frames through pools: a frame can never be destroyed.
- **Conditions:** cheapest test first, guard before indexing (`if t and t[k] then`).
- **Measure before optimising.** The client has an addon profiler (`C_AddOnProfiler`, shown in the
  addon list). Profilers slow the game themselves: switch them off after measuring.
- Chat, disk and server: no chat traffic or server queries on a timer; throttle anything that asks the
  server.

## 8. Saved variables

- As few global names as possible, each prefixed. One table for the addon is best.
- Read them from `ADDON_LOADED` on. Fill in missing keys from a defaults table on load, so a new
  option works for an old save. Do not save values that equal the default if that is easy to avoid.
- Never trust the shape of saved data: check each value's kind where it is read and replace what is
  wrong (Core's `Saved.lua`). While nothing has been handed out, a changed shape is simply not read (its part falls back to the
  default); once versions are out, a changed part carries a version number and an upgrade step on load. Never crash on an unexpected shape: saved data comes from older
  versions and from hand edits.
- Save plain data only (numbers, strings, booleans, tables). Never a secret value, a frame or a
  function.
- Account-wide by default; per character only what really differs per character.
- In Sane UI a module does not declare its own saved variables: it uses Core's (`Core.Store`,
  `Core.Options`; [src/Core/README.md](../../src/Core/README.md)). They stay when the module is switched off.

## 9. Text and languages

- Never depend on a localised name (spell, item, zone, NPC). Use IDs and ask the client for the name.
- Use Blizzard's own strings where one exists (`GlobalStrings`: `OKAY`, `CANCEL`, `SETTINGS`, ...).
  They are already translated and match the rest of the game.
- Keep own texts in one place per module, not scattered through the code, so they can be translated.
- Build sentences with `format` and whole patterns, not by gluing words: word order differs by language.
- Texts for the player are short, plain and without jargon.

## 10. Errors and resilience

- An addon error must never break the game's own UI. Guard every step that touches Blizzard code or
  an API that may be missing: check for `nil` first, use `pcall`/`xpcall` where a call may fail.
- When a feature fails, switch that feature off and give the player the Blizzard default back. Tell it
  once, not on every frame.
- Check that a function or frame exists before using it; client updates rename and remove things.
- Do not swallow errors silently during development: they still go to the game's error handler.
- In Sane UI: `Core.Safe(label, fn, ...)`, `Core.Report`, `Core.NoteError`, and a way back for every
  module that changes something of the game's: a module that stands in for a whole feature defines
  `GiveBack` and runs its steps through `module.Guarded`, which calls `module.StandDown` on an error
  ([src/Core/README.md](../../src/Core/README.md)).

## 11. Living next to other addons

- Change as little of the shared UI as possible, and only through hooks.
- Never assume to be the only addon that hooks a function or moves a frame.
- Sane UI embeds no third-party libraries: everything it needs is its own code or the game's.
- No output to chat unless the player asked for it or something failed.
- One slash command with sub-commands, not many commands.

## 12. Code quality

- Small files with one job; no file that does everything. Comment why, not what.
- No dead code, no options nobody asked for, no abstraction for one caller.
- Tests for logic that can run outside the game (`dev/tests/`). Things that only the client can show
  are tried in the game and noted as tried or not tried.
- Record every change in `Doc/Changed.md`.

## Checklist before a commit

- [ ] New files are in their module's TOC; `dev/build` passes.
- [ ] A module needs Core only: it works with every other module switched off.
- [ ] No new global except a prefixed one the client requires.
- [ ] Nothing written into a Blizzard frame, table or global; hooks only.
- [ ] Nothing touches a protected frame without `InCombatLockdown()`.
- [ ] Values read from the game are tested before they are compared or computed with.
- [ ] No `OnUpdate`, timer or event that runs while the feature is hidden or idle.
- [ ] A failure leaves the Blizzard default working.
- [ ] No Blizzard art or sound copied into the addon.

## Sources

| Source | Used for |
| --- | --- |
| [UI Add-On Development Policy (Blizzard)](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534) | 1 |
| [Combat Philosophy and Addon Disarmament in Midnight (Blizzard)](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) | 1, 6 |
| [TOC format (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/TOC_format) | 2 |
| [AddOn loading process (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/AddOn_loading_process) | 3 |
| [UI best practices (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/UI_best_practices) | 4, 5, 7 |
| [Secure Execution and Tainting (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting) | 5 |
| [Secret Values (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/Secret_Values) | 6 |
| [Optimizing CPU usage (Blizzard forum)](https://us.forums.blizzard.com/en/wow/t/optimizing-cpu-usage/1366572) | 7 (read as a search summary only) |
| [Localizing an addon (Warcraft Wiki)](https://warcraft.wiki.gg/wiki/Localizing_an_addon) | 9 (read as a search summary only) |

Worth reading when taint becomes a problem: the Warcraft Wiki's
[Secure Execution and Tainting](https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting) (above).
