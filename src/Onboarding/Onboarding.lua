local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Onboarding
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
}

-- The window on a module's setup at that step (the first). False for a module without one.
function ns.Show(name, step)
    local guide = Core.Onboarding.Guide(name)
    if not guide or #guide.steps == 0 then return false end
    return ns.Window.Show(name, guide, step)
end
