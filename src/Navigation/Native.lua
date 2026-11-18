local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Native
--  The game's map kept closed while ours stands in for it, and given back.
--
--      the keys     the keys bound to the game's map, quest log and minimap open ours instead:
--                   override bindings on a button of ours (SaneUINavigationKey), set out of combat
--                   and again when the bindings change. The map's and the quest log's fill the screen
--                   with our map and back; the minimap's shows or hides our window
--      our own key  SaneUI's map has a key of its own (SANEUI_MAP, in the game's key bindings under
--                   SaneUI; the setup's Keys, Setup.lua): once it has one, the game's map key is the game's
--                   again and opens the game's map (Saneroki, 2026-11-18: "Give them options to put
--                   keybinds to open either the native map or our map"). The game's own binding opens it
--                   (ToggleWorldMap, its secure code; our code never opens the game's panels): a hook after
--                   ToggleWorldMap sees it shown and lets it stay (kept); every other way to the game's
--                   map still opens ours
--      every other  way to the game's map (the minimap's zone text, the quest log's button, the objective
--                   tracker, a chat link, an event of the game) ends in WorldMapFrame showing: seen by
--                   a hook after its OnShow, out of sight at once, hidden on the next frame (its own
--                   Hide, out of combat) and ours opened at the map it was asked for
--      in a fight   the game's map stays open as the game's, and ours does not open: hidden by our
--                   code then, its OnHide would run as ours in the fight
--      its quest log  the game's quest log chosen in the dropdown Classic windows (nativeQuestLog): the
--                   quest log's key is the game's again, and the game's map that shows its quest log
--                   beside it (its key, its button, a quest clicked in the game's tracker) stays
--
--  Nothing is written into the game's map: its own methods only (SetAlpha, Hide,
--  GetMapID), a hook after its OnShow and OnHide. Never the game's panel functions
--  (ShowUIPanel, HideUIPanel): their manager keeps the open panels in slots of its
--  own, and our call would leave them written by our code until a /reload, so the
--  game's next panel there (the character sheet) would open as ours and fail on a
--  secret value. A panel hidden by its own Hide the manager mends by itself, in its
--  own code, before it shows the next one (UIParentPanelManager.lua,
--  RepairUIPanelState). The switches Show the game's map and Show the game's
--  minimap stop the keys and the catching for that window; the game's map chosen
--  in the dropdown Classic windows opens by its own key or button.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Native = {}
ns.Native = Native

-- The game's key bindings Navigation takes, and what each does here.
Native.KEYS = { TOGGLEWORLDMAP = "map", TOGGLEQUESTLOG = "quests", TOGGLEMINIMAP = "minimap" }
Native.BUTTON = "SaneUINavigationKey"
Native.OWN = "SANEUI_MAP" -- our map's own key (Bindings.xml)
BINDING_NAME_SANEUI_MAP = "SaneUI's map (full screen and back)"
local WAIT = "navigation: keys"

local button, hooked
local bound = "" -- the keys as last set: one text, to set them again only when they changed
local pressed    -- a key's press was acted on: its release is not
local kept       -- the game's map opened by its own key while ours has a key of its own: it stays until it closes

-- Whether our map has a key of its own (SANEUI_MAP): the game's map key is the game's then.
function Native.Split()
    local key = Core.Ask(rawget(_G, "GetBindingKey"), Native.OWN)
    return type(key) == "string" and key ~= ""
end

-- Our map's own key (Bindings.xml): full screen and back, as the game's map key does while ours takes it.
function Native.Own()
    if ns.off then return end
    ns.Window.Toggle()
end

-- Whether Navigation takes that window's key now.
local function Takes(which)
    if ns.off then return false end
    if which == "minimap" then return not ns.options.nativeMinimap end
    if which == "quests" then return not (ns.options.nativeMap or ns.options.nativeQuestLog) end
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
    local split = Native.Split()
    for action, which in pairs(Native.KEYS) do
        if Takes(which) and not (which == "map" and split) then
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

-- Whether the game's map shows its quest log beside it (QuestLogOwnerMixin's side panel), while the game's quest
-- log is chosen.
local function GameQuestLog(map)
    if not ns.options.nativeQuestLog then return false end
    local log = map.QuestLog or rawget(_G, "QuestMapFrame")
    return log and log.IsShown and Core.Plain(log:IsShown()) and true or false
end
Native.GameQuestLog = GameQuestLog

-- The frame after the game's map showed (a frame later: its quest log is beside it by then): hidden by its own Hide
-- (never the game's HideUIPanel: the header says why), and ours opened at its map. In a fight it stays, and while it
-- shows the game's quest log chosen.
local function Close()
    local map = Map()
    if not map:IsShown() then return map:SetAlpha(1) end
    if InCombatLockdown() or GameQuestLog(map) or kept then return map:SetAlpha(1) end
    local asked = map:GetMapID()
    map:Hide()
    map:SetAlpha(1)
    ns.Window.OpenTo(asked)
end
local closing = ns.Guard(Close)

local function Shown()
    if not Takes("map") then return end
    if InCombatLockdown() then return end -- hidden by our code now, its OnHide would run as ours in the fight
    Map():SetAlpha(0) -- out of sight for the one frame until it is hidden
    C_Timer.After(0, closing)
end

local function Hidden()
    kept = false
    Map():SetAlpha(1)
end

-- After the game's ToggleWorldMap (its map key's binding, run by the game): opened while our map has a key of its
-- own, the game's map stays, in sight at once (its OnShow, above, has just put it out of sight).
local function Toggled()
    local map = Map()
    if not (map and Core.Plain(map:IsShown()) and Takes("map") and Native.Split()) then return end
    kept = true
    map:SetAlpha(1)
end

-- Hooks after the game's map's OnShow and OnHide, once it exists (it comes with the game's map addon).
local function Hook()
    local map = Map()
    if hooked or not map then return end
    hooked = true
    map:HookScript("OnShow", ns.Guard(Shown))
    map:HookScript("OnHide", ns.Guard(Hidden))
    if type(rawget(_G, "ToggleWorldMap")) == "function" then hooksecurefunc("ToggleWorldMap", ns.Guard(Toggled)) end
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

-- A switch changed (Show the game's map, Show the game's minimap, the game's quest log): the keys as it says now.
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
