local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Keys
--  Your bag keys open our bags instead of the game's (Saneroki, 2026-10-20):
--  whatever keys the game's key bindings give its actions TOGGLEBACKPACK,
--  OPENALLBAGS, TOGGLEBAG1 to TOGGLEBAG4 and TOGGLEREAGENTBAG1 run ours
--  (Bindings.xml, in the game's key bindings under Sane UI), by the game's own
--  override bindings, which leave your key bindings as they are: the full
--  screen with the bags on it, and pressed again while it shows, back to its
--  size.
--
--  The game's bag windows stay closed meanwhile: they stand in a hidden frame
--  of ours (lent: Core.Lend, their parent given back as it was), so the game
--  opens and closes them as it always does (at a vendor, the bank, the mail)
--  and nothing of them shows. Chosen in the full window's dropdown Classic
--  windows (Window.lua: Keys.GameBags), they show again until they are all
--  closed. The game's bag bar (the backpack, the bag slots, the keyring) stands
--  in that frame too, for as long as ours are the bags (Saneroki, 2026-10-31):
--  no button of it to see or click, and not in Edit Mode either; the Classic
--  windows leave it there. The setting Bag Keys Open Our Bags (bagKeys)
--  switches all of it; so does Can expand to fullscreen (expand), without which
--  the full screen never comes, and, for the keys and windows, Edit Mode while
--  it is open (Core.EditMode); standing down gives it all back.
--
--  Override bindings change out of a fight only: set at the login, anew when
--  your key bindings change (UPDATE_BINDINGS, only when the keys of those
--  actions did); in a fight, once it is over. Our key itself works in a fight
--  too.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Keys = {}
ns.Keys = Keys

-- The game's actions whose keys open ours; our own key (Bindings.xml) and its words in the game's key bindings.
Keys.ACTIONS = { "TOGGLEBACKPACK", "OPENALLBAGS", "TOGGLEBAG1", "TOGGLEBAG2", "TOGGLEBAG3", "TOGGLEBAG4", "TOGGLEREAGENTBAG1" }
Keys.COMMAND = "SANEUI_INVENTORY_BAGS"
BINDING_NAME_SANEUI_INVENTORY_BAGS = "Open the bags on Inventory's full screen"

local owner         -- the frame our override bindings belong to
local hidden        -- the hidden frame the game's bag windows and bag bar stand in
local bound         -- the keys of those actions when they were last bound: rebound only when they change
local lends = {}    -- [frame] = its lend (Core.Lend)
local barLend       -- the lend of the game's bag bar
local gameBags = false -- the player chose the game's bags (Classic windows): they show

-- Whether ours stand in for the game's bags: the setting on, the module running, and the full screen able to come
-- (with Can expand to fullscreen off it never does).
local function Ours()
    local options = ns.options or {}
    return owner ~= nil and not ns.off and options.bagKeys ~= false and options.expand ~= false
end

-- Whether our bags are the bags now: so, and Edit Mode closed (the game's keys and bags are the game's until then).
function Keys.Taken()
    local editing = Core.EditMode and Core.EditMode.active
    return Ours() and not editing
end

-- The game's binding functions, where this client has them.
local function Game(name)
    local fn = rawget(_G, name)
    return type(fn) == "function" and fn or nil
end

-- The keys the game's key bindings give those actions, as one line.
local function Signature()
    local parts = {}
    local keys = Game("GetBindingKey")
    if not keys then return "" end
    for _, action in ipairs(Keys.ACTIONS) do
        local one, two = keys(action)
        parts[#parts + 1] = action .. "=" .. tostring(one) .. "," .. tostring(two)
    end
    return table.concat(parts, "|")
end

-- Our key on the game's bag keys: out of a fight, or once it is over.
function Keys.Bind()
    local clear, set, keys = Game("ClearOverrideBindings"), Game("SetOverrideBinding"), Game("GetBindingKey")
    if not (owner and clear and set and keys) then return end
    if InCombatLockdown() then return Core.AfterCombat("Inventory: keys", Keys.Bind) end
    clear(owner)
    bound = Signature()
    if not Keys.Taken() then return end
    for _, action in ipairs(Keys.ACTIONS) do
        for _, key in ipairs({ keys(action) }) do
            if type(key) == "string" and key ~= "" then set(owner, false, key, Keys.COMMAND) end
        end
    end
end

local function Changed()
    if ns.off or Signature() == bound then return end
    Keys.Bind()
end

-------------------------------------------------------------------------------
--  The game's bag windows
-------------------------------------------------------------------------------
-- The game's bag windows there are: the combined one and each bag's.
local function Frames()
    local list = {}
    local combined = rawget(_G, "ContainerFrameCombinedBags")
    if type(combined) == "table" then list[#list + 1] = combined end
    for index = 1, tonumber(rawget(_G, "NUM_CONTAINER_FRAMES")) or 13 do
        local frame = rawget(_G, "ContainerFrame" .. index)
        if type(frame) == "table" then list[#list + 1] = frame end
    end
    return list
end

-- The game's bag windows in our hidden frame (nothing of them shows), or back where they stood.
local function Away()
    for _, frame in ipairs(Frames()) do
        lends[frame] = lends[frame] or Core.Lend(frame)
        lends[frame]:SetParent(hidden)
    end
end

local function Back()
    for frame, lend in pairs(lends) do
        if lend:Lent() then ns.Safe("keys", lend.Return, lend) end
        lends[frame] = nil
    end
end

-- The game's bag bar in our hidden frame while ours stand in for the game's bags, or back where it stood.
local function Bar()
    local bar = rawget(_G, "BagsBar")
    if type(bar) ~= "table" then return end
    if Ours() and not barLend then
        local lend = Core.Lend(bar)
        if lend:SetParent(hidden) then barLend = lend end
    elseif barLend and not Ours() then
        local lent = barLend
        barLend = nil
        ns.Safe("keys", lent.Return, lent)
    end
end

-- As things stand now: away while our bags are the bags and the player did not choose the game's.
function Keys.Apply()
    if not owner then return end
    Keys.Bind()
    if Keys.Taken() and not gameBags then Away() else Back() end
    Bar()
end

-- The player chose the game's bags (on: they show, Classic windows) or ours again.
function Keys.GameBags(on)
    gameBags = on and true or false
    Keys.Apply()
end

-- A bag window of the game's hid: once none shows, ours are the bags again.
local function Closed()
    if not gameBags then return end
    for _, frame in ipairs(Frames()) do
        if frame:IsShown() then return end
    end
    Keys.GameBags(false)
end

-------------------------------------------------------------------------------
--  Opening ours
-------------------------------------------------------------------------------
-- Our key (Bindings.xml): the full screen with the bags, or back from it.
function Keys.Press()
    if ns.off then return end
    ns.Safe("keys", ns.Window.Toggle, "bags")
end

function Keys.Start()
    owner = CreateFrame("Frame")
    hidden = CreateFrame("Frame")
    hidden:Hide()
    ns.On("UPDATE_BINDINGS", Changed)
    for _, frame in ipairs(Frames()) do frame:HookScript("OnHide", ns.Guard(Closed)) end
    -- Edit Mode opened or closed: the bag keys are the game's while it is open (Keys.Taken).
    if Core.EditMode and Core.EditMode.Watch then Core.EditMode.Watch(ns.Guard(Keys.Apply)) end
    Keys.Apply()
end

-- The module stood down: the game's keys and bag windows are the game's again.
function Keys.Leave()
    if not owner then return end
    Back()
    Bar()
    if InCombatLockdown() then
        Core.AfterCombat("Inventory: keys", Keys.Leave)
        return
    end
    local clear = Game("ClearOverrideBindings")
    if clear then clear(owner) end
end
