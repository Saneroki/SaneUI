local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - EditMode
--  Whether Blizzard's Edit Mode is open. SaneUI's windows are moved and sized
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
--  for SaneUI's windows alone (the resilience rule: never stuck, never broken).
--
--  The boxes seen only under the mouse (Saneroki, 2026-11-18: "only show that
--  blue box while you mouseover it so you can see how your interface looks like
--  without the blue boxes that are edit mode only"): a box's blue frame is out
--  of sight until the mouse is on it, ours (Window.lua) and the game's frames'
--  alike; the one chosen keeps its yellow frame. Only its art goes, by its alpha:
--  the box still takes the mouse, its brighter copy and its words under the mouse
--  are as before. The game's: a hook after each frame's ShowHighlighted,
--  ShowSelected and ShowEditInstructions (its Selection, of a system the manager
--  lists, hooked as Edit Mode opens), reading its isSelected and
--  instructionsShown. The alpha of a texture carries no taint and nothing of
--  Blizzard's reads it.
--
--      Core.EditMode.Seen(box, seen)      -- a box's frame (its nine-slice) in sight or not
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
    registry:RegisterCallback("EditMode.Enter", Core.Guard("Edit Mode", function() Tell(true) end), EditMode)
    registry:RegisterCallback("EditMode.Exit", Core.Guard("Edit Mode", function() Tell(false) end), EditMode)
end

-- Open already when the game is loaded (a /reload in Edit Mode); and whether there is one to follow.
Core.On("PLAYER_LOGIN", function()
    local manager = rawget(_G, "EditModeManagerFrame")
    EditMode.available = heard and manager and type(manager.IsEditModeActive) == "function" or false
    if not EditMode.available then return end
    for name, active in pairs({ ShowSystemSelections = true, HideSystemSelections = false }) do
        if type(manager[name]) == "function" then hooksecurefunc(manager, name, Core.Guard("Edit Mode", function() Tell(active) end)) end
    end
    Tell(Core.Ask(manager.IsEditModeActive, manager) and true or false)
end)

-------------------------------------------------------------------------------
--  The boxes seen only under the mouse
-------------------------------------------------------------------------------
-- A box's frame: the pieces Blizzard's nine-slice code puts on it (NineSliceUtil, EditModeSystemSelectionLayout).
EditMode.PIECES = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge",
                    "BottomEdge", "LeftEdge", "RightEdge", "Center" }

function EditMode.Seen(box, seen)
    for _, name in ipairs(EditMode.PIECES) do
        local piece = rawget(box, name) -- put on the frame's own table by the nine-slice code
        if type(piece) == "table" and piece.SetAlpha then piece:SetAlpha(seen and 1 or 0) end
    end
end

-- One of the game's boxes as it stands: chosen, or the mouse on it.
local hooked = setmetatable({}, { __mode = "k" })
local function Follow(selection)
    EditMode.Seen(selection, selection.isSelected == true or selection.instructionsShown == true)
end

local function Hook(system)
    local selection = type(system) == "table" and system.Selection
    if type(selection) ~= "table" or hooked[selection] then return end
    hooked[selection] = true
    local follow = Core.Guard("Edit Mode", function() Follow(selection) end)
    for _, name in ipairs({ "ShowHighlighted", "ShowSelected", "ShowEditInstructions" }) do
        if type(selection[name]) == "function" then hooksecurefunc(selection, name, follow) end
    end
    Follow(selection)
end

-- Each time Edit Mode opens: the boxes of every frame it lists (one an addon of the game's brought since, too).
EditMode.Watch(function(active)
    local manager = rawget(_G, "EditModeManagerFrame")
    local systems = active and manager and manager.registeredSystemFrames
    if type(systems) ~= "table" then return end
    for _, system in ipairs(systems) do Core.Safe("Edit Mode", Hook, system) end
end)

Core.Command("arrange", "move and size SaneUI's windows, if this game has no Edit Mode (Esc > Edit Mode) to do it in", function()
    if EditMode.available then
        Core.Print("windows are arranged in the game's Edit Mode: Esc > Edit Mode.")
    else
        Tell(not EditMode.active)
    end
end)
