local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Native
--  The game's map kept closed while ours stands in for it, and given back.
--
--      the keys     the keys bound to the game's map, quest log and minimap open ours instead:
--                   override bindings on a button of ours (SaneUINavigationKey), set out of combat
--                   and again when the bindings change. The map's and the quest log's fill the screen
--                   with our map and back; the minimap's shows or hides our window
--      every other  way to the game's map (the minimap's zone text, the quest log's button, the objective
--                   tracker, a chat link, an event of the game) ends in WorldMapFrame showing: seen by
--                   a hook after its OnShow, out of sight at once, closed on the next frame
--                   (HideUIPanel, out of combat) and ours opened at the map it was asked for
--      in a fight   the game's panel manager refuses to close a panel for an addon: the game's map
--                   then stays open as the game's, and ours does not open
--
--  Nothing is written into the game's map: its own methods only (SetAlpha,
--  GetMapID), a hook after its OnShow and OnHide, the game's panel functions.
--  The switches Show the game's map and Show the game's minimap stop the keys and
--  the catching for that window; the dropdown Classic windows opens the game's map
--  once, not caught.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Native = {}
ns.Native = Native

-- The game's key bindings Navigation takes, and what each does here.
Native.KEYS = { TOGGLEWORLDMAP = "map", TOGGLEQUESTLOG = "quests", TOGGLEMINIMAP = "minimap" }
Native.BUTTON = "SaneUINavigationKey"
local WAIT = "navigation: keys"

local button, hooked
local bound = "" -- the keys as last set: one text, to set them again only when they changed
local passing    -- the game's map was asked for from Classic windows: this showing is not caught
local pressed    -- a key's press was acted on: its release is not

-- Whether Navigation takes that window's key now.
local function Takes(which)
    if ns.off then return false end
    if which == "minimap" then return not ns.options.nativeMinimap end
    return not ns.options.nativeMap
end

-- A key of the game's map, quest log or minimap was pressed: the game sends the press and the release.
local function Key(_, which, down)
    if down == false and pressed then
        pressed = false
        return
    end
    pressed = down == true
    if which == "minimap" then ns.Window.ToggleShown() else ns.Window.Toggle() end
end

-- The override bindings as the switches say, out of combat. Setting them makes the game send
-- UPDATE_BINDINGS again: the same keys then change nothing.
function Native.Bind()
    if not button then return end
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Native.Bind) end
    local list = {}
    for action, which in pairs(Native.KEYS) do
        if Takes(which) then
            for _, key in ipairs({ GetBindingKey(action) }) do list[#list + 1] = key .. "\t" .. which end
        end
    end
    table.sort(list)
    local text = table.concat(list, "\n")
    if text == bound then return end
    bound = text
    ClearOverrideBindings(button)
    for _, entry in ipairs(list) do
        local key, which = entry:match("^(.-)\t(%a+)$")
        SetOverrideBindingClick(button, true, key, Native.BUTTON, which)
    end
end

-------------------------------------------------------------------------------
--  The game's map
-------------------------------------------------------------------------------
local function Map()
    return rawget(_G, "WorldMapFrame")
end

-- The frame after the game's map showed: closed, and ours opened at its map. In a fight it stays.
local function Close()
    local map = Map()
    if not map:IsShown() then return map:SetAlpha(1) end
    if InCombatLockdown() then return map:SetAlpha(1) end
    local asked = map:GetMapID()
    HideUIPanel(map)
    map:SetAlpha(1)
    ns.Window.OpenTo(asked)
end
local closing = ns.Guard(Close)

local function Shown()
    if passing or not Takes("map") then return end
    if InCombatLockdown() then return end -- the panel manager would refuse to close it: the game's map it is
    Map():SetAlpha(0) -- out of sight for the one frame until it is closed
    C_Timer.After(0, closing)
end

local function Hidden()
    passing = false
    Map():SetAlpha(1)
end

-- The game's map once, not caught (the dropdown Classic windows); in a fight the game refuses.
function Native.ShowMap()
    local map = Map()
    if not map then return end
    if InCombatLockdown() then return ns.Print(ns.TEXT.mapInFight) end
    passing = true
    ShowUIPanel(map)
    if not map:IsShown() then passing = false end
end

-- Hooks after the game's map's OnShow and OnHide, once it exists (it comes with the game's map addon).
local function Hook()
    local map = Map()
    if hooked or not map then return end
    hooked = true
    map:HookScript("OnShow", ns.Guard(Shown))
    map:HookScript("OnHide", ns.Guard(Hidden))
end

function Native.Start()
    button = CreateFrame("Button", Native.BUTTON, UIParent)
    button:SetSize(1, 1)
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetScript("OnClick", ns.Guard(Key))
    Hook()
    if not hooked then
        ns.On("ADDON_LOADED", function(name) if name == "Blizzard_WorldMap" then Hook() end end)
    end
    ns.On("UPDATE_BINDINGS", function() ns.Safe("keys", Native.Bind) end)
    Native.Bind()
end

-- A switch changed (Show the game's map, Show the game's minimap): the keys as it says now.
function Native.Update()
    Native.Bind()
end

-- The module stood down: the keys back to the game's own, the game's map in sight. The hooks do nothing
-- from now on (ns.off: Takes).
function Native.GiveBack()
    local map = Map()
    if map then map:SetAlpha(1) end
    if not button then return end
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Native.GiveBack) end
    bound = ""
    ClearOverrideBindings(button)
end
