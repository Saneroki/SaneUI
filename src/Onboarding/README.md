# Sane UI: Onboarding

## TL;DR

The setup of a Sane UI addon, step by step: one window that walks you through what a module shows, a step at a time,
each step with its own purpose, its words, the switches it is about and a sample that shows each choice at once. It
comes with Sane UI (Core's download) and is read only when a setup opens. Each module keeps its own words and sample;
this addon only draws them. Nameplates has the first setup, Navigation the second (`src/Navigation/Setup.lua`).

## How to use

- **All setups together:** a few seconds after the login (after the game's own What's new, never in a fight) the
  setups still to go through open in one window: those of the modules that are on and that this account has not
  gone through yet, or that changed a lot since. **The first page** lists them: please go through them to configure
  your addons to your needs; where they are found again (`/sane setup`, the addon settings); a row for each, its
  name, its steps and *Choose defaults*. Beside them the plain Sane UI logo, and under it Sane UI's windows and the
  game's own, each only where an addon that is on has it: the small button with the circling arrows (in a Sane UI
  window's title bar: the game's classic window instead; on the game's window: Sane UI's back); the red buttons
  beside a full screen window's X (its own window without the full screen, and back onto the full screen); and the
  dropdown *Classic windows* that full screen has, which chooses which one is the default, and works here too.
  Navigation, Tooltips and Nameplates have none of the buttons (Navigation's full map has the dropdown). *Start*
  opens the first, and they follow one
  after another (*Navigation: setup 1 of 3*; *Next setup* on the last step of one); *Back* on a setup's first step
  comes back to the first page. A setup is gone through once its last step is done; closed before that, it opens
  again at the next login, at the step where it was left, the others after it.
- **Choose defaults**, on each row of the first page and in the row under a setup's step beside *Back* (only while a
  setup is not gone through): that addon's switches of its setup go back to Sane UI's defaults (the game's key
  bindings stay), and its setup no longer opens by itself until its module changes it a lot; in a setup the run goes
  on to the next. Where some of those switches were already changed, the game's yes or no asks first. The button on
  its options page still opens it.
- **Open it again** with the button *Set up step by step* at the top of the module's options page (Esc > Options >
  AddOns > Sane UI > the module), or `/sane setup <module>` (`/sane setup nameplates`; `/sane setup` alone: those still
  to go through, else the only one there, else the list of them). A faint note at the foot of every step says where,
  and for a setup not gone through yet that it comes back.
- **In the window:** the sample at the left, in a solid grey box, the step at the right: its head, its words, its switches. Each switch is the module's own,
  as on its options page, with the same words and tips: a tick, a slider with its steppers, or a round button per
  choice (side by side for three or fewer); one under another stands a little in and is greyed out while that one is
  off. A key: click its box, then press the key, with Shift, Ctrl or Alt held if you like (Alt-Shift-V), or a mouse
  button past the two main ones (the middle, a side button); Esc keeps it as it was, a right
  click leaves it without one (the game's own key bindings, saved as its key binding window saves them; out of a
  fight). A change shows at once on the sample and in the game. Under them the loading screen's bar, filled as far
  as the steps have come, *Step 2 of 12* in it; *Back* and *Next* (red, with the game's arrows, as Forever's own
  character creation) go through the steps; *Done* on the last step closes it.
- **Closing it** at any step (its X, Esc, Done) keeps what was chosen: there is nothing to save or undo. Drag its
  head to move it.
- **Switched off** in the addon list (under Sane UI), no setup opens; `/sane setup` says where to switch it on.

## Technical details

- **Load on demand, shipped with Core** (Saneroki, 2026-11-16: "both onboarding and core always ships together and
  lives in the same curseforge project"): `## LoadOnDemand: 1`, `## Dependencies: SaneUI`. Core's
  `src/Core/Onboarding.lua` holds what the modules hand in and reads this addon (`C_AddOns.LoadAddOn`) when a setup
  opens; this addon registers with `Core.NewModule` as every module does, so its `OnLoad` and `OnLogin` come at once.
  In `dev/tools/release` it is one of `CORE` and `CORE_PROJECT`: no stage, in Core's zip, a change to it a new SaneUI
  Core. It changes nothing of the game's: no `GiveBack`.
- **Each module keeps its own words** (Saneroki, 2026-11-16): a module hands Core its guide while its files are read,
  `Core.Onboarding.Add(name, { title, steps, Stage })` (`src/Core/Onboarding.lua` describes it). A step is
  `{ key, title, text, settings = { key, ... } }`; `Stage(stage, step, index)` draws the module's sample into the
  window's stage, when the step shows and again after each change. The module's code runs it in its own `ns.Safe`, so
  its error is its own and stands nothing down.
- **The controls** (`Controls.lua`) are made from the module's own descriptions (`Core.Described`: `text`, `tip`,
  `choices`, `min`, `max`, `step`, `unit`, `distance`, `parent`, `parentValue`, `hidden`), or for a key from the step's
  own entry (`{ binding = "COMMAND", text, tip }`: `GetBindingKey`, `SetBinding`, `SaveBindings`; the key's other
  command said in chat; the key named as the game's key binding window names it, by its `BindingUtil`:
  `GetConvertedKeyOrButton`, `IsKeyPressIgnoredForBinding`, `CreateKeyChordStringUsingMetaKeyState`, our own where it
  lacks them; heard by one listener of its own, `Controls.Wait`, as the game's `KeybindListener` hears it: over the
  window, its `OnKeyDown` set only while a box waits, since in the game a frame given that script takes the keyboard
  and passes no key on, so no box holds it, one box waits at a time, and the keyboard goes back to the game after the
  key, Esc, another box's click or the step hidden), or from a switch the step words its own way (`{ key = "expandClick", text, tip, choices = {
  { value, words }, ... }, column = true }` over the switch's description: a switch as round buttons, one under
  another with `column`; Navigation's hot corner; with `around = true`, choices that are places round a bar
  (`Controls.PLACES`: top left ... bottom right) as a small bar with a round button at each place, the choice's
  words its tooltip; with `beside = true`, at the right of the control before it, without words of its own, that one
  narrower: Nameplates' places beside their counts), and set through `Core.Set`,
  as a menu or a command does: the module's `changed` is told, its options page shows it, its profile keeps it.
  Switches without words (kept values), buttons, colours, typed entries and multiple choices have no control in a
  step. A slider shown anew (`Refresh`) does not set its value again.
- **The window** (`Window.lua`): a frame of its own on `UIParent` in the bronze (`Look.Dress`), 860 x 600, strata
  `DIALOG` (over the game's options, `SettingsPanel` at `HIGH`, where the module's button opens it), moved by its head, closed by its X or Esc (`Core.Escape` while shown). The stage is a grey box
  (`Look.Box`) on the window's plate that clips what it holds. Each module draws into a frame of its own over it (`StageOf`), the
  other modules' hidden, so a sample left from another setup never shows under it. Each step's controls are made
  the first time it shows and kept. The progress: `Look.Headline` (the loading screen's bar) with
  `Interface\Glues\LoadingBar\Loading-BarFill` as far as the steps have come. The buttons
  are the red ones (`Look.Red`) with the game's `common-icon-backarrow` and `-forwardarrow`, as
  `CharacterCreateNavButtonMixin:UpdateText` puts them; sounds as the game's windows and steps play them.
- **When it opens by itself:** Core looks a few seconds (`Core.Onboarding.WAIT`) after the first
  `PLAYER_ENTERING_WORLD` of the session, waits while the game's `SplashFrame` shows, and starts the run
  (`Core.Onboarding.Start`): every setup still to go through (`Core.Onboarding.Due()`: of a module that is on, with
  steps, not gone through at the guide's `version`), in their order, the first at the step where it was left, once a
  session, through `Core.AfterCombat`. The window tells Core each step it shows (`Reached`: kept as where a setup not
  gone through yet was left) and the last one done (`Finished`: gone through, kept with its version; the run's next
  setup, `Following`, shows in the same window; its head counts them, `Place`). Kept in
  `SaneUIDB.modules.Onboarding` for the account, outside the profiles: `done[name] = { version, day }`, `left[name] =
  step`; the store of before (`shown[name]`, the day a setup first opened) is read as gone through at version 1.
  Opened by hand (`Open`), a setup shows alone, with no run.
- **The first page** (Saneroki, 2026-11-18: "a very first page where all the onboardings that still need to go through
  is listed"; "On the first page it says that please go through this to configure your addons to your needs. The
  configure steps are found underer /sane setup or in the addon settings"): `Core.Onboarding.Start` opens it
  (`Window.First`, through `ns.First`), the run's setups from `Core.Onboarding.Run()`. On the stage the plain Sane UI
  logo (Saneroki, 2026-11-18: "use a plain Sane UI logo instead of the Core banner"; `Window.LOGO`, this addon's
  `Art/logo.blp`, drawn 300 x 100 by `dev/tools/logo-art saneui` and `dev/tools/art`) and under it, "very clearly"
  ("show very clearly that the small button with the circle arrow means to show the classic windows instead and also
  in fullscreen you have the dropdown selectors to choose which one is the default one"; then "show that the red arrow
  up / down button will detatch windows from fullscreen or not", and: "some addons like the navigation, tooltip and
  nameplate doesn't have those buttons in it so if only those addons are part of the onboarding then it should not
  show those because that would cause confusion. On addons that do have those icons should show them"), each where a
  window of an addon that is on has it (`Window.Has`, asked each time the page shows, `Lay` stacking those that apply
  under their head; none: not the head either): the button with the circling arrows itself (Core's `Window.Swap`,
  `Window.SWAP_SCALE` times its 24 units, its tip Core's) with what it does beside it, where a window has `native`
  (Social's chat, Combat's macro editor); the red buttons beside a full screen window's X (`RedButton-Condense`, its own
  window, and `-Expand`, back onto the full screen, as Core's board draws them, larger, Core's tips), where a board has
  a window that can stand alone (`Core.Board.Apart`: Social's, Inventory's, Combat's full screens); the dropdown
  *Classic windows* itself (`WowStyle1DropdownTemplate`, `Core.Edge.CLASSIC`, as wide as full screen has it, made in
  `pcall`), where a window has kept choices (`Core.Classic.Kept`: Navigation's minimap, map and quest log too), and it
  works ("make the dropdown on the first page actually work"): its menu is `Core.Classic.KeptMenu`, each window's
  kept choices under its name, ticked while the game's own is kept; a tick switches it (`Core.Classic.Keep`: the
  entry's `show` or `back`, nothing filled or closed). What each does is said beside it or under it (`Explained`). At
  the right the words, a row each (`Window.ROW`: the setup's title in gold, its steps faint,
  *Choose defaults* at its right; done: *Defaults chosen* or *Set up*, faint), made when first needed; under them how
  many are left and *Start* (none left: *Done*), which shows the first still to go through (`Core.Onboarding.Continue`).
  *Back* on the first step of a run's setup comes back to it.
- **Choose defaults** (Saneroki, 2026-11-18: "Add a Skip", then "instead of skip it says Choose Defaults on each of the
  onboardings"): words alone in the colours of Forever's top bar (`Look.NAV`, lit `Look.NAV_LIT` under the mouse; red
  is for what matters, and *Back* and *Next* stand beside it), on each row of the first page and between the progress
  bar and *Back* while a setup is not gone through (`Core.Onboarding.Done`), the bar reaching to it.
  `Core.Onboarding.Defaults(name, after)`: the setup's switches (its steps' keys; not the game's key bindings) back to
  their defaults (`Core.Reset`), kept as `done[name] = { version, day, defaults = true }`
  (`Core.Onboarding.Defaulted`), so it counts as gone through for the run and the login until a new `version`; where
  one of them differs from its default, the game's yes or no asks first (`Core.Confirm`; no: nothing changes). Then,
  in a setup, the run's first setup still to go through shows (`Continue`), else the window closes; on the first page
  its rows show anew.
- **A setup changed a lot:** its module raises the guide's `version` (1 when it has none) and may say what changed
  (`changed`); every account that went through an older version goes through it again at its next login, the first
  step saying what changed in gold (*Changed since you last went through it: ...*). The settings chosen stay.
- **The note** at each step's foot (faint, `Window.NOTE`): on a setup's last step in a run, which one comes next; for
  a setup not gone through yet, that it opens again at the next login; always where to start it again: the module's
  options page and its button when it has one (`Core.Described(name, "setup")`), else `/sane setup <module>`. So the
  setups' own words no longer say it.

## Files

| File | What it holds |
| --- | --- |
| `SaneUI_Onboarding.toc` | The addon, load on demand |
| `Onboarding.lua` | The module's table and words; `Show(name, step)`, which Core calls |
| `Controls.lua` | A step's controls: the module's switches as ticks, sliders and round buttons, set through `Core.Set`; keys in the game's key bindings, heard by one listener |
| `Window.lua` | The window: the stage, the step, Back and Next |

## History
- 2026-11-18 — All setups together (Saneroki: "it should remember which onboardings the user went through and which
  onboardings still has to be gone through"): the run of every setup still to go through, kept where each was left
  and as gone through at its end; a setup's `version` to have everyone go through it again after a big change
  ("a way to invalidate the old settings so when we make big changes the user can go through the onboarding again");
  the note at each step's foot ("during onboarding say that you can start this again in the addon settings"). Then
  *Skip setup* ("Add a Skip"), the same day *Choose defaults* in its place ("instead of skip it says Choose
  Defaults"), and the run's first page that lists its setups ("a very first page where all the onboardings that
  still need to go through is listed"); on it the plain Sane UI logo, and the classic window's button and the full
  screen's dropdown *Classic windows*, shown and said ("show very clearly"); then the dropdown working, the full
  screen's red buttons shown, and each only where an addon that is on has it.
- 2026-11-18 — The key boxes hear the key again (Saneroki: "the configure keybinds don't work. When I click it it says
  press a key but it doesn't register any keypresses. I want it to work with the modifier keys as well so that
  someone could press like alt shift v"): each box had its `OnKeyDown` from the start, which in the game takes the
  keyboard and passes nothing on, so on a step of several keys the top box heard every key and dropped it. One
  listener now hears the key for the box clicked, with the modifiers held and the game's own key names; a mouse
  button past the two main ones binds too.
- 2026-11-18 — Tooltips' setup (`src/Tooltips/Setup.lua`: one step, your own tooltip as the sample); each module's
  sample in a frame of its own over the stage, the others' hidden.
- 2026-11-18 — Navigation's setup, the second (Saneroki: "Can you make a onboarding window for the navigation
  module"); a step may word one of its module's switches its own way (its own words and round buttons).
- 2026-11-16 (later) — The loading screen's bar for the progress, keys as controls, choices side by side, 600 high
  (Saneroki: "add the loading screen bar there"). The stage over the world was tried and taken back the same day
  (Saneroki: "make it solid not transparent. it gets to confusing if it is transparent actually"): the grey box again.

- 2026-11-16 — First version (Saneroki: "I want a window where it goes step by step through to explain the nameplates
  and where people can see a live preview of a fake nameplate"): the window, the controls from a module's own
  switches, Core's part (`Core.Onboarding`, `/sane setup`, the first time by itself); Nameplates' setup the first
  (`src/Nameplates/Setup.lua`). Ships with Core.
