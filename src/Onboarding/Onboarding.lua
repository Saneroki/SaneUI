local ADDON, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Onboarding
--  A module's setup, step by step (Doc/ideas/Onboarding.md): one window that
--  walks the player through what the module shows, a step at a time, each
--  step with its own purpose, its words, the module's switches it is about and
--  a sample that shows at once what they change.
--
--  An addon of its own (SaneUI_Onboarding), loaded on demand and shipped with
--  Core (Saneroki, 2026-11-16): Core reads it only when a setup opens
--  (src/Core/Onboarding.lua: by itself the first time a module is on, from
--  the module's options page, /sane setup). Each module keeps its own words
--  (Saneroki, 2026-11-16): its steps and the sample are the module's, handed
--  to Core while its files are read (Core.Onboarding.Add); this addon only
--  draws them:
--    Controls.lua  a step's controls: the module's own switches as its
--                  options page has them, set through Core.Set
--    Window.lua    the window: the sample at its left (the module draws it),
--                  the step at its right, Back and Next under it
--  It changes nothing of the game's: what a control sets is the module's own
--  setting, which the module follows as it follows its options page.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Onboarding", ns)

-- Every word the window shows; the game's own where it has one.
ns.TEXT = {
    back = Core.Word("BACK", "Back"),
    next = Core.Word("NEXT", "Next"),
    done = Core.Word("DONE", "Done"),
    step = "Step %d of %d",
    setup = "%s: setup",
    setupOf = "%s: setup %d of %d", -- one of the run (Core.Onboarding.Start): the setups still to go through
    nextSetup = "Next setup",
    -- Choose defaults (Saneroki, 2026-11-18: "instead of skip it says Choose Defaults on each of the onboardings").
    defaults = "Choose defaults",
    defaultsTip = "Sets this addon to SaneUI's defaults instead, without going through its setup (your key bindings stay). Its setup no longer opens by itself, unless it changes a lot.",
    defaultsChosen = "Defaults chosen",
    goneThrough = "Set up",
    -- The run's first page (Saneroki, 2026-11-18: "a very first page where all the onboardings that still need to go
    -- through is listed").
    firstHead = "SaneUI: setup",
    firstTitle = "Set up your addons",
    firstText = "Please go through these setups to configure your addons to your needs, one after another. Choose defaults keeps an addon as SaneUI sets it up.\n\nYou find the setups again under /sane setup, or in the addon settings: Esc > Options > AddOns > SaneUI > the addon, Set up step by step.",
    steps = "%d steps",
    oneStep = "1 step",
    left = "%d setups to go through",
    oneLeft = "1 setup to go through",
    noneLeft = "All set",
    start = "Start",
    -- On the first page's stage, under the logo (Saneroki, 2026-11-18: "show very clearly that the small button with
    -- the circle arrow means to show the classic windows instead and also in fullscreen you have the dropdown
    -- selectors to choose which one is the default one").
    windows = "SaneUI's windows and the game's own",
    swap = "This button in a SaneUI window's title bar shows the game's classic window instead. The same button on the game's window brings SaneUI's back.",
    classic = "In full screen, the dropdown Classic windows at the top right chooses which one is the default: ticked, the game's classic window opens instead of SaneUI's; unticked, SaneUI's again. You can choose here too.",
    -- (Saneroki, 2026-11-18: "show that the red arrow up / down button will detatch windows from fullscreen or not")
    alone = "On a full screen, beside a window's X: makes it a window of its own, without the full screen. Its key then opens it alone.",
    onto = "On a window of its own: back onto the full screen, and its key opens that again.",
    -- The note under each step: where to start it again; for one not gone through yet, that it comes back.
    again = "Start this setup again any time: Esc > Options > AddOns > SaneUI > %s, Set up step by step.",
    againTyped = "Start this setup again any time: /sane setup %s.",
    unfinished = "Closed before its end, it opens again at your next login, where you left it.",
    following = "Next: the setup of %s.",
    -- On the first step, to whoever went through an older version of it (guide.version raised, guide.changed).
    changed = "Changed since you last saw it: %s",
    changedAny = "Changed since you last saw it: new steps and settings to choose.",
}

-- The window on a module's setup at that step (the first). False for a module without one.
function ns.Show(name, step)
    local guide = Core.Onboarding.Guide(name)
    if not guide or #guide.steps == 0 then return false end
    return ns.Window.Show(name, guide, step)
end

-- The window on the run's first page: the setups still to go through (Core.Onboarding.Start).
function ns.First()
    return ns.Window.First()
end
