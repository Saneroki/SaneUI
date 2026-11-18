local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Bags - Room
--  One slot of your bags kept free for what comes (Saneroki, 2026-10-30; Loot's
--  switch Make room for loot, also a box at the foot of the bags). When the last
--  slot fills, the junk worth the least goes: what the bags call junk
--  (Contents.Junk: the game's grey items and your marks, nothing that can still
--  be refunded), and the chat says what went. The game destroys an item only on
--  a press of the player's, so it goes at your next key press out of a fight: a
--  frame hears the keyboard while something waits, and hands every key on. Where
--  the game refuses, or your hand is full, it is tried again Room.AGAIN seconds
--  later: nothing is wrong, destroying is just held up now and then. No junk: a
--  warning on the screen, once in Room.WARN.
--
--      Room.Start()   listens to the bags, from the login on
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Room = {}
ns.Room = Room

Room.KEEP = 1    -- slots kept free
Room.WARN = 60   -- seconds between two warnings that nothing can go
Room.CHECK = 0.3 -- seconds after destroying before the cursor shows whether the game let it
Room.AGAIN = 5   -- seconds before trying again after the game refused

local LOOT = "Loot"  -- the module with the switch
local catcher        -- hears the next key
local warned         -- when the last warning was given
local going          -- the link of what was just destroyed
local waitUntil      -- the game refused: no try before this time
local junk = {}      -- the records of junk (Contents.Junk), used again
local Look

local function On()
    local loot = Core.Settings(LOOT)
    return not ns.off and loot and loot.full and true or false
end

-- The free slots for any thing (bags of a kind of their own, a quiver, a herb bag, are not counted).
local function Free()
    local free = 0
    for bag = 0, tonumber(rawget(_G, "NUM_BAG_SLOTS")) or 4 do
        local count, family = Core.Ask(C_Container.GetContainerNumFreeSlots, bag)
        if count and (family == nil or family == 0) then free = free + count end
    end
    return free
end

-- The junk worth the least, all of its stack.
local function Cheapest()
    ns.Bags.Store() -- the player's junk marks, the bags' window perhaps not built yet
    local best, least
    for _, record in ipairs(ns.Contents.Junk(ns.Bags.Carried().slots, junk)) do
        local worth = (record.sell or 0) * (record.count or 1)
        if not record.locked and (not least or worth < least) then best, least = record, worth end
    end
    return best
end

local function Warn(text)
    local now = GetTime()
    if warned and now - warned < Room.WARN then return end
    warned = now
    local errors = rawget(_G, "UIErrorsFrame")
    if errors then errors:AddMessage(text, 1, 0.1, 0.1) end
end

local function Listen(on)
    if catcher then catcher:SetShown(on) end
end

local tryAgain = Core.Later(function() ns.Guarded(Look) end, Room.AGAIN)

-- A moment after: gone, or the game left it on the cursor: back into the bags, and tried again a little later.
local Checked = Core.Later(function()
    ns.Guarded(function()
        local link = going
        going = nil
        if not link then return end
        if not Core.Ask(rawget(_G, "CursorHasItem")) then return ns.Print(ns.TEXT.bagsRoomGone:format(link)) end
        waitUntil = GetTime() + Room.AGAIN
        Core.Ask(rawget(_G, "ClearCursor"))
        tryAgain()
    end)
end, Room.CHECK)

-- A key was pressed, and the game takes that for the player's word.
local function Pressed()
    Listen(false)
    if not On() or InCombatLockdown() or Free() >= Room.KEEP then return end
    if Core.Ask(rawget(_G, "CursorHasItem")) then return tryAgain() end -- something in your hand: a little later
    local record = Cheapest()
    if not record then return end
    C_Container.PickupContainerItem(record.bag, record.slot)
    Core.Ask(rawget(_G, "DeleteCursorItem"))
    going = record.link or record.name
    Checked()
end

local function Catcher()
    catcher = CreateFrame("Frame", nil, UIParent)
    catcher:EnableKeyboard(true)
    catcher:SetPropagateKeyboardInput(true)
    catcher:SetScript("OnKeyDown", ns.Guard(Pressed))
    catcher:Hide()
    Room.catcher = catcher
end

-- The bags as they are now: room enough, something to go at the next key, or nothing that could.
function Look()
    if not On() or Free() >= Room.KEEP then
        warned = nil
        return Listen(false)
    end
    if InCombatLockdown() then return Listen(false) end
    if waitUntil and GetTime() < waitUntil then
        Listen(false)
        return tryAgain()
    end
    if not Cheapest() then
        Listen(false)
        return Warn(ns.TEXT.bagsRoomNone)
    end
    if not catcher then Catcher() end
    Listen(true)
end

function Room.Start()
    local soon = Core.Later(function() ns.Guarded(Look) end)
    ns.On("BAG_UPDATE_DELAYED", soon)
    ns.On("PLAYER_REGEN_ENABLED", soon)
    Core.OnSwitches(soon)
end
