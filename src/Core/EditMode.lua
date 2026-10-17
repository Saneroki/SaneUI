local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - EditMode
--  Whether Blizzard's Edit Mode is open. Sane UI's windows are moved and sized
--  only then, as the game's own frames are (Window.lua); the rest of the time
--  they stay where they are.
--
--      Core.EditMode.active               -- open now
--      Core.EditMode.available            -- the game has an Edit Mode we can follow (known at login)
--      Core.EditMode.Watch(fn)            -- fn(active) each time it opens or closes
--
--  The game tells it on its event registry (EditMode.Enter, EditMode.Exit), whose
--  callbacks it calls sealed off from its own code (securecallfunction): our
--  code there carries no taint into Edit Mode. Edit Mode also hides its frames'
--  boxes for a while without leaving (another window over it, its lock state)
--  and shows them again: ours follow that too, by hooks after the manager's own
--  ShowSystemSelections and HideSystemSelections (hooksecurefunc on the frame,
--  which the mixin was copied into). Edit Mode's manager is only read and
--  followed, never written: no field, no call of its own that changes it
--  (Doc/guides/windows.md, section 9).
--
--  Should this client have no such Edit Mode (or no event registry to hear it
--  by), our windows are not stuck: /sane arrange opens and closes the same mode
--  for Sane UI's windows alone (the resilience rule: never stuck, never broken).
-------------------------------------------------------------------------------
local EditMode = { active = false, available = false }
Core.EditMode = EditMode

local watchers = {}

function EditMode.Watch(fn)
    watchers[#watchers + 1] = fn
end

local function Tell(active)
    if EditMode.active == active then return end
    EditMode.active = active
    for _, fn in ipairs(watchers) do Core.Safe("Edit Mode", fn, active) end
end

local registry = rawget(_G, "EventRegistry")
local heard = registry and type(registry.RegisterCallback) == "function"
if heard then
    registry:RegisterCallback("EditMode.Enter", function() Tell(true) end, EditMode)
    registry:RegisterCallback("EditMode.Exit", function() Tell(false) end, EditMode)
end

-- Open already when the game is loaded (a /reload in Edit Mode); and whether there is one to follow.
Core.On("PLAYER_LOGIN", function()
    local manager = rawget(_G, "EditModeManagerFrame")
    EditMode.available = heard and manager and type(manager.IsEditModeActive) == "function" or false
    if not EditMode.available then return end
    for name, active in pairs({ ShowSystemSelections = true, HideSystemSelections = false }) do
        if type(manager[name]) == "function" then hooksecurefunc(manager, name, function() Tell(active) end) end
    end
    Tell(Core.Ask(manager.IsEditModeActive, manager) and true or false)
end)

Core.Command("arrange", "move and size Sane UI's windows, if this game has no Edit Mode (Esc > Edit Mode) to do it in", function()
    if EditMode.available then
        Core.Print("windows are arranged in the game's Edit Mode: Esc > Edit Mode.")
    else
        Tell(not EditMode.active)
    end
end)
