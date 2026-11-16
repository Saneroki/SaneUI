# Sane UI: Onboarding

## TL;DR

The setup of a Sane UI addon, step by step: one window that walks you through what a module shows, a step at a time,
each step with its own purpose, its words, the switches it is about and a sample that shows each choice at once. It
comes with Sane UI (Core's download) and is read only when a setup opens. Each module keeps its own words and sample;
this addon only draws them. Nameplates has the first setup.

## How to use

- **It opens by itself** the first time a module with a setup is on, a few seconds after the login (after the game's
  own What's new, never in a fight), once per account.
- **Open it again** with the button *Set up step by step* at the top of the module's options page (Esc > Options >
  AddOns > Sane UI > the module), or `/sane setup <module>` (`/sane setup nameplates`; `/sane setup` alone: the only
  one there, or the list of them).
- **In the window:** the sample at the left, over the world itself (the window's plate stops round it, a thin
  golden line frames it), the step at the right: its head, its words, its switches. Each switch is the module's own,
  as on its options page, with the same words and tips: a tick, a slider with its steppers, or a round button per
  choice (side by side for three or fewer); one under another stands a little in and is greyed out while that one is
  off. A key: click its box, then press the key (with Shift, Ctrl or Alt if you like); Esc keeps it as it was, a right
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
  command said in chat), and set through `Core.Set`,
  as a menu or a command does: the module's `changed` is told, its options page shows it, its profile keeps it.
  Switches without words (kept values), buttons, colours, typed entries and multiple choices have no control in a
  step. A slider shown anew (`Refresh`) does not set its value again.
- **The window** (`Window.lua`): a frame of its own on `UIParent` in the bronze (`Look.Dress`), 860 x 600, strata
  `DIALOG` (over the game's options, `SettingsPanel` at `HIGH`, where the module's button opens it), moved by its head, closed by its X or Esc (`Core.Escape` while shown). The stage clips what it holds and has nothing behind it:
  the window's plate (`heavybronze-frame-background`) is four pieces round it, each a clipping frame holding a plate
  as large as the window's (so its picture runs on unbroken), under the bronze frame. Each step's controls are made
  the first time it shows and kept. The progress: `Look.Headline` (the loading screen's bar) with
  `Interface\Glues\LoadingBar\Loading-BarFill` as far as the steps have come. The buttons
  are the red ones (`Look.Red`) with the game's `common-icon-backarrow` and `-forwardarrow`, as
  `CharacterCreateNavButtonMixin:UpdateText` puts them; sounds as the game's windows and steps play them.
- **When it opens by itself:** Core looks a few seconds (`Core.Onboarding.WAIT`) after the first
  `PLAYER_ENTERING_WORLD` of the session, waits while the game's `SplashFrame` shows, opens the first setup of a
  module that is on and was never shown (`SaneUIDB.modules.Onboarding.shown[name]`, the day; for the account, outside
  the profiles), one a session, through `Core.AfterCombat`.

## Files

| File | What it holds |
| --- | --- |
| `SaneUI_Onboarding.toc` | The addon, load on demand |
| `Onboarding.lua` | The module's table and words; `Show(name, step)`, which Core calls |
| `Controls.lua` | A step's controls: the module's switches as ticks, sliders and round buttons, set through `Core.Set` |
| `Window.lua` | The window: the stage, the step, Back and Next |

## History
- 2026-11-16 (later) — The stage over the world, the loading screen's bar for the progress, keys as controls, choices
  side by side, 600 high (Saneroki: "can that be fully transparent", "add the loading screen bar there").

- 2026-11-16 — First version (Saneroki: "I want a window where it goes step by step through to explain the nameplates
  and where people can see a live preview of a fake nameplate"): the window, the controls from a module's own
  switches, Core's part (`Core.Onboarding`, `/sane setup`, the first time by itself); Nameplates' setup the first
  (`src/Nameplates/Setup.lua`). Ships with Core.
