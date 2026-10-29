local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Full
--  Your bags are full and the loot window holds a thing you cannot take: a
--  page of paper beside the window's lines, at their right, with
--      the thing      its picture and name, and what a vendor pays for it
--                     (all of the stack);
--      to make room   the thing in your bags worth the least at a vendor
--                     (Full.Rank), with pencil arrows to the next cheapest and
--                     back ("2 of 9"); a click on it picks it up, and dropped
--                     on the world the game asks before it is gone (Sane UI
--                     destroys nothing itself: the game does not let it).
--  Never offered: what a vendor will not take, a quest's things, the epic and
--  better. The page goes once there is room again (BAG_UPDATE_DELAYED).
--
--      Full.Rank(things)   -- the bags' things that could go, the cheapest first
--      Full.Update()       -- shown or hidden, as the bags and the loot are now
--      Full.Hide()
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local J = Core.Journal
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
local function Price(worth, count)
    if not worth or worth <= 0 then return ns.TEXT.fullNoWorth end
    return ns.TEXT.fullWorth:format(Core.Coins(worth * (count or 1)) or tostring(worth * (count or 1)))
end

-- A thing: its picture in a pencil slot, its name, under it its worth.
local function Thing(parent)
    local thing = CreateFrame("Button", nil, parent)
    thing:SetHeight(S.row)
    thing.holder = CreateFrame("Frame", nil, thing)
    thing.holder:SetSize(S.icon, S.icon)
    thing.holder:SetPoint("LEFT", 2, 0)
    J.Slot(thing.holder, 1)
    local inset = S.icon * J.SLOT_ICON
    thing.icon = thing.holder:CreateTexture(nil, "ARTWORK")
    thing.icon:SetPoint("TOPLEFT", inset, -inset)
    thing.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    thing.count = thing.holder:CreateFontString(nil, "OVERLAY")
    thing.count:SetFont(J.FONT_BOLD, 11 * J.PX, "OUTLINE")
    thing.count:SetPoint("BOTTOMRIGHT", -1, 1)
    thing.name = thing:CreateFontString(nil, "ARTWORK")
    J.Font(thing.name, 13, true)
    thing.name:SetJustifyH("LEFT")
    thing.name:SetWordWrap(false)
    thing.name:SetPoint("BOTTOMLEFT", thing, "LEFT", S.icon + 2 + S.gap, 0)
    thing.name:SetPoint("BOTTOMRIGHT", thing, "RIGHT", -2, 0)
    thing.worth = thing:CreateFontString(nil, "ARTWORK")
    J.Font(thing.worth, 11, false, J.FAINT)
    thing.worth:SetJustifyH("LEFT")
    thing.worth:SetPoint("TOPLEFT", thing, "LEFT", S.icon + 2 + S.gap, -1)
    thing.worth:SetPoint("TOPRIGHT", thing, "RIGHT", -2, -1)
    return thing
end

local function Set(thing, icon, name, quality, count, worth)
    thing.icon:SetTexture(icon)
    thing.count:SetText(count and count > 1 and count or "")
    thing.name:SetText(name or "")
    thing.name:SetTextColor(ns.Row.Color(quality))
    thing.worth:SetText(Price(worth, count))
end

local function Label(parent, text, size, bold, color)
    local label = parent:CreateFontString(nil, "ARTWORK")
    J.Font(label, size, bold, color)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function Arrow(parent, angle, step)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(S.icon * 0.6, S.icon * 0.6)
    button.mark = J.Texture(button, "arrow", "ARTWORK")
    button.mark:SetAllPoints()
    button.mark:SetRotation(angle)
    button.mark:SetAlpha(0.6)
    button:SetScript("OnClick", ns.Guard(function()
        if #things == 0 then return end
        at = (at - 1 + step) % #things + 1
        Full.Show()
    end))
    button:SetScript("OnEnter", ns.Guard(function() button.mark:SetAlpha(1) end))
    button:SetScript("OnLeave", ns.Guard(function() button.mark:SetAlpha(0.6) end))
    return button
end

local function RoomTip(button)
    local thing = things[at]
    if not thing then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(thing.bag, thing.slot)
    GameTooltip:AddLine(ns.TEXT.fullHow, J.LIT[1], J.LIT[2], J.LIT[3], true)
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
    page:EnableMouse(true)
    J.Paper(page)
    J.Box(page, 0.6, "BORDER")
    local x = S.gap * 2
    page.head = Label(page, ns.TEXT.fullTitle, 15, true)
    page.head:SetPoint("TOPLEFT", x, -S.gap * 1.5)
    page.rule = J.Rule(page)
    page.rule:SetPoint("TOPLEFT", page.head, "BOTTOMLEFT", 0, -2)
    page.rule:SetPoint("RIGHT", page, "RIGHT", -x, 0)

    page.thisLabel = Label(page, ns.TEXT.fullThis, 11, false, J.FAINT)
    page.thisLabel:SetPoint("TOPLEFT", page.rule, "BOTTOMLEFT", 0, -S.gap)
    this = Thing(page)
    this:SetPoint("TOPLEFT", page.thisLabel, "BOTTOMLEFT", 0, -2)
    this:SetPoint("RIGHT", page, "RIGHT", -x, 0)
    this:SetScript("OnEnter", ns.Guard(function(self)
        local line = Wanted()
        if not line then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetLootItem(line.slot)
        GameTooltip:Show()
    end))
    this:SetScript("OnLeave", GameTooltip_Hide)

    page.roomLabel = Label(page, ns.TEXT.fullRoom, 11, false, J.FAINT)
    page.roomLabel:SetPoint("TOPLEFT", this, "BOTTOMLEFT", 0, -S.gap)
    place = Label(page, "", 11, false, J.FAINT)
    place:SetJustifyH("RIGHT")
    room = Thing(page)
    room:SetPoint("TOPLEFT", page.roomLabel, "BOTTOMLEFT", 0, -2)
    room:SetPoint("RIGHT", page, "RIGHT", -x, 0)
    room:RegisterForClicks("LeftButtonUp")
    room:RegisterForDrag("LeftButton")
    room:SetScript("OnClick", ns.Guard(Pick))
    room:SetScript("OnDragStart", ns.Guard(Pick))
    room:SetScript("OnEnter", ns.Guard(RoomTip))
    room:SetScript("OnLeave", GameTooltip_Hide)
    ahead = Arrow(page, math.pi / 2, 1)
    ahead:SetPoint("RIGHT", page, "RIGHT", -x, 0)
    ahead:SetPoint("TOP", page.roomLabel, "TOP", 0, 2)
    place:SetPoint("RIGHT", ahead, "LEFT", -2, 0)
    back = Arrow(page, -math.pi / 2, -1)
    back:SetPoint("RIGHT", place, "LEFT", -2, 0)

    how = Label(page, ns.TEXT.fullHow, 11, false, J.FAINT)
    how:SetWordWrap(true)
    how:SetPoint("TOPLEFT", room, "BOTTOMLEFT", 0, -S.gap)
    how:SetPoint("RIGHT", page, "RIGHT", -x, 0)
    page:Hide()
end

-- The page as it is now: the wanted thing, the one offered, how to make room.
function Full.Show()
    local line = Wanted()
    if not line then return Full.Hide() end
    if not page then Build() end
    local parent = ns.Window.frame
    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", parent, "TOPRIGHT", S.gap, -S.top)
    Set(this, line.icon, line.name, line.quality, line.count, line.worth)
    at = math.min(math.max(at, 1), math.max(#things, 1))
    local thing = things[at]
    if thing then
        Set(room, thing.icon, thing.name, thing.quality, thing.count, thing.worth)
        room:Show()
        how:SetText(ns.TEXT.fullHow)
        place:SetText(ns.TEXT.fullOf:format(at, #things))
    else
        room:Hide()
        how:SetText(ns.TEXT.fullNone)
        place:SetText("")
    end
    back:SetShown(#things > 1)
    ahead:SetShown(#things > 1)
    local height = S.gap * 1.5 + 18 + S.gap + 12 + 2 + S.row + S.gap + 12 + 2 + (thing and S.row or 0) + S.gap
        + (tonumber(how:GetStringHeight()) or 24) + S.gap * 2
    page:SetHeight(height)
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
