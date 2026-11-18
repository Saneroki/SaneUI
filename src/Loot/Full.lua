local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Loot - Full
--  Your bags are full and the loot window holds a thing you cannot take: at
--  the right of the window's lines, made as they are (Saneroki, 2026-11-02: all
--  of the loot window as the nameplates): no paper, no frame, on the world,
--  bare words in off white and two lines of the window (Row.lua), with no A:
--      the thing      under its name what it is, at the right what a vendor
--                     pays for all of the stack;
--      to make room   the thing in your bags worth the least at a vendor
--                     (Full.Rank), the same, with small dark bars as the A to
--                     the next cheapest and back ("2 of 9"); a click on it
--                     picks it up, and dropped on the world the game asks
--                     before it is gone (what the bags do to keep a slot free
--                     is Inventory's: Bags/Room.lua).
--  Never offered: what a vendor will not take, a quest's things, the epic and
--  better. The page goes once there is room again (BAG_UPDATE_DELAYED).
--
--      Full.Rank(things)   -- the bags' things that could go, the cheapest first
--      Full.Update()       -- shown or hidden, as the bags and the loot are now
--      Full.Hide()
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local S = ns.SIZE
local Full = {}
ns.Full = Full

local EPIC = 4 -- the epic quality and better are never offered
local page, this, room, how, back, ahead, place
local things = {} -- the bags' things that could go, the cheapest first
local at = 1      -- the one offered of them

-------------------------------------------------------------------------------
--  What could go
-------------------------------------------------------------------------------
-- A thing in the bags: { bag, slot, icon, name, link, count, quality, worth (one's), noValue, quest }.
function Full.Rank(list)
    local ranked = {}
    for _, thing in ipairs(list) do
        if not thing.noValue and not thing.quest and (thing.worth or 0) > 0 and (thing.quality or 0) < EPIC then
            ranked[#ranked + 1] = thing
        end
    end
    table.sort(ranked, function(a, b)
        local wa, wb = a.worth * (a.count or 1), b.worth * (b.count or 1)
        if wa ~= wb then return wa < wb end
        if (a.quality or 0) ~= (b.quality or 0) then return (a.quality or 0) < (b.quality or 0) end
        if (a.name or "") ~= (b.name or "") then return (a.name or "") < (b.name or "") end
        return a.bag * 100 + a.slot < b.bag * 100 + b.slot
    end)
    return ranked
end

local function Worth(link)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if type(info) ~= "function" or not link then return nil end
    local ok, name, _, _, _, _, _, _, _, _, _, worth = pcall(info, link)
    if not ok then return nil end
    return Plain(worth), Plain(name)
end

local function Bags()
    return 0, tonumber(rawget(_G, "NUM_BAG_SLOTS")) or 4
end

-- The free room for any thing (bags of a kind of their own, a quiver, a herb bag, are not counted).
local function Free()
    local free = 0
    local first, last = Bags()
    for bag = first, last do
        local n, family = Core.Ask(C_Container.GetContainerNumFreeSlots, bag)
        if n and (family == nil or family == 0) then free = free + n end
    end
    return free
end

local function Read()
    local list = {}
    local first, last = Bags()
    for bag = first, last do
        local slots = Core.Ask(C_Container.GetContainerNumSlots, bag) or 0
        for slot = 1, slots do
            local info = Plain(C_Container.GetContainerItemInfo(bag, slot))
            if type(info) == "table" and Plain(info.hyperlink) and not Plain(info.isLocked) then
                local quest = C_Container.GetContainerItemQuestInfo and Plain(C_Container.GetContainerItemQuestInfo(bag, slot))
                local worth, name = Worth(info.hyperlink)
                list[#list + 1] = { bag = bag, slot = slot, icon = Plain(info.iconFileID), link = Plain(info.hyperlink),
                    name = name or Plain(info.hyperlink), count = Plain(info.stackCount) or 1,
                    quality = Plain(info.quality) or 1, worth = worth, noValue = Plain(info.hasNoValue) and true or false,
                    quest = type(quest) == "table" and (Plain(quest.isQuestItem) or Plain(quest.questID)) and true or false }
            end
        end
    end
    return Full.Rank(list)
end

-- The loot window's first thing to take: the one room is wanted for.
local function Wanted()
    for _, line in ipairs(ns.Window.Lines()) do
        if line.kind == "item" and not line.locked then return line end
    end
    return nil
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
-- A thing: a line of the window, with no A.
local function Thing(parent)
    local thing = ns.Row.New(parent)
    thing.noAuto = true
    return thing
end

-- A thing of your bags as a line of the window: under its name what it is, at the right its worth.
local function Carried(thing)
    local line = { kind = "item", icon = thing.icon, name = thing.name, count = thing.count, quality = thing.quality,
                   locked = false, link = thing.link }
    ns.Slots.Facts(line)
    return line
end

-- Bare words, in the game's outlined nameplate font in off white, as Link and Close.
local function Label(parent, text, size)
    local label = parent:CreateFontString(nil, "ARTWORK")
    ns.Row.Font(label, size)
    label:SetTextColor(unpack(ns.Row.OFF_WHITE))
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

-- To the next cheapest and back: a small dark bar, as a line's A.
local function Arrow(parent, word, step)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(S.auto, S.auto)
    button.bar = ns.Row.Bar(button, S.auto)
    button.text = button:CreateFontString(nil, "OVERLAY")
    ns.Row.Font(button.text, 13)
    button.text:SetPoint("CENTER", 0, 0)
    button.text:SetText(word)
    button:SetScript("OnClick", ns.Guard(function()
        if #things == 0 then return end
        at = (at - 1 + step) % #things + 1
        Full.Show()
    end))
    button:SetScript("OnEnter", ns.Guard(function() button.bar:SetLit(true) end))
    button:SetScript("OnLeave", ns.Guard(function() button.bar:SetLit(false) end))
    return button
end

local function Untip(row)
    row.bar:SetLit(false)
    GameTooltip_Hide()
end

local function ThisTip(row)
    local line = Wanted()
    if not line then return end
    row.bar:SetLit(true)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetLootItem(line.slot)
    GameTooltip:Show()
end

local function RoomTip(row)
    local thing = things[at]
    if not thing then return end
    row.bar:SetLit(true)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(thing.bag, thing.slot)
    GameTooltip:AddLine(ns.TEXT.fullHow, 1, 1, 1, true)
    GameTooltip:Show()
end

-- Picked up: the player drops it on the world, and the game asks.
local function Pick()
    local thing = things[at]
    -- with something on the cursor already, a pick would put that down in the thing's place: nothing then
    if not thing or Core.Ask(rawget(_G, "CursorHasItem")) then return end
    C_Container.PickupContainerItem(thing.bag, thing.slot)
end

local function Build()
    local parent = ns.Window.frame
    page = CreateFrame("Frame", nil, parent)
    page:SetWidth(S.full)
    page:SetFrameLevel(parent:GetFrameLevel() + 2)
    page.head = Label(page, ns.TEXT.fullTitle, 16)
    page.head:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

    page.thisLabel = Label(page, ns.TEXT.fullThis, 14)
    page.thisLabel:SetPoint("TOPLEFT", page.head, "BOTTOMLEFT", 0, -S.gap)
    this = Thing(page)
    this:SetPoint("TOPLEFT", page.thisLabel, "BOTTOMLEFT", 0, -2)
    this:SetPoint("RIGHT", page, "RIGHT", 0, 0)
    this:SetScript("OnEnter", ns.Guard(ThisTip))
    this:SetScript("OnLeave", ns.Guard(Untip))

    page.roomLabel = Label(page, ns.TEXT.fullRoom, 14)
    page.roomLabel:SetPoint("TOPLEFT", this, "BOTTOMLEFT", 0, -S.gap)
    place = Label(page, "", 14)
    place:SetJustifyH("RIGHT")
    room = Thing(page)
    room:SetPoint("TOPLEFT", page.roomLabel, "BOTTOMLEFT", 0, -2)
    room:SetPoint("RIGHT", page, "RIGHT", 0, 0)
    room:RegisterForClicks("LeftButtonUp")
    room:RegisterForDrag("LeftButton")
    room:SetScript("OnClick", ns.Guard(Pick))
    room:SetScript("OnDragStart", ns.Guard(Pick))
    room:SetScript("OnEnter", ns.Guard(RoomTip))
    room:SetScript("OnLeave", ns.Guard(Untip))
    ahead = Arrow(page, ns.TEXT.fullAhead, 1)
    ahead:SetPoint("BOTTOMRIGHT", room, "TOPRIGHT", 0, 2)
    place:SetPoint("RIGHT", ahead, "LEFT", -S.gap / 2, 0)
    back = Arrow(page, ns.TEXT.fullBack, -1)
    back:SetPoint("RIGHT", place, "LEFT", -S.gap / 2, 0)

    how = Label(page, ns.TEXT.fullHow, 14)
    how:SetWordWrap(true)
    how:SetPoint("TOPLEFT", room, "BOTTOMLEFT", 0, -S.gap)
    how:SetPoint("RIGHT", page, "RIGHT", 0, 0)
    page:Hide()
end

-- The page as it is now: the wanted thing, the one offered, how to make room.
function Full.Show()
    local line = Wanted()
    if not line then return Full.Hide() end
    if not page then Build() end
    local parent = ns.Window.frame
    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", parent, "TOPRIGHT", S.gap, 0)
    ns.Row.Set(this, line, true, false)
    at = math.min(math.max(at, 1), math.max(#things, 1))
    local thing = things[at]
    if thing then
        ns.Row.Set(room, Carried(thing), true, false)
        how:SetText(ns.TEXT.fullHow)
        place:SetText(ns.TEXT.fullOf:format(at, #things))
    else
        room:Hide()
        how:SetText(ns.TEXT.fullNone)
        place:SetText("")
    end
    back:SetShown(#things > 1)
    ahead:SetShown(#things > 1)
    page:SetHeight(16 + S.gap + 14 + 2 + S.row + S.gap + 14 + 2 + (thing and S.row or 0) + S.gap
        + (tonumber(how:GetStringHeight()) or 24))
    page:Show()
end

function Full.Hide()
    if page then page:Hide() end
    wipe(things)
    at = 1
end

function Full.Update()
    if ns.off or not ns.options.full or not ns.Window.Shown() or not Wanted() or Free() > 0 then return Full.Hide() end
    local offered = things[at]
    things = Read()
    -- the one offered stays offered while it is there
    at = 1
    if offered then
        for index, thing in ipairs(things) do
            if thing.bag == offered.bag and thing.slot == offered.slot and thing.link == offered.link then at = index end
        end
    end
    Full.Show()
end

function Full.Start()
    ns.On("BAG_UPDATE_DELAYED", ns.Guard(function() if ns.Window.Shown() then Full.Update() end end))
end
