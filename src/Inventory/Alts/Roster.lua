local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts - Roster
--  The account's characters down the left of the window (Snapshot.Characters):
--  each by its class's icon and its whole name in its class's colour, its gold
--  beside it; the account's own bank last, where it holds something; under the
--  list, the gold of them all. A click chooses whose things the window shows
--  (Alts.Choose), the chosen one lit as the game lights a chosen line in its
--  options. While searching, each says how many of what is found it has, and
--  one that has none of it is dimmed. Its tooltip says the rest: the level and
--  class, the realm, when it was seen last, its gold to the copper.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Roster = {}
ns.Roster = Roster

Roster.WIDTH = 230  -- the list's width
Roster.ROW = 24     -- a character's line
Roster.ICON = 16    -- its class's icon
Roster.FOOT = 26    -- the line of the gold of them all
Roster.DIM = 0.45   -- a character without anything the search finds
local GOLD = 10000  -- copper in a gold coin: the list shows whole gold (all of it under one), the tooltip and the total all
local BANK_ICON = "Interface\\Icons\\INV_Misc_Bag_08"

local box, foot
local chosen, found -- the key shown; [key] = how many the search finds (nil: no search)

-- The class's colour (RAID_CLASS_COLORS), or the game's white.
function Roster.Colour(class)
    local colours = rawget(_G, "RAID_CLASS_COLORS")
    local colour = colours and class and colours[class]
    if colour then return colour.r, colour.g, colour.b end
    return 1, 1, 1
end

local function Enter(row)
    local who = row.who
    if not who then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    for _, line in ipairs(ns.Alts.About(who)) do
        GameTooltip:AddLine(line[1], line[2], line[3], line[4])
    end
    GameTooltip:Show()
end

local function Click(row)
    if row.who then ns.Alts.Choose(row.who.key) end
end

local function OnEnter(row) ns.Safe("alts", Enter, row) end
local function OnClick(row) ns.Safe("alts", Click, row) end

local function Draw(row, who)
    if not row.name then
        row.lit = row:CreateTexture(nil, "BACKGROUND")
        row.lit:SetAllPoints()
        row.lit:SetAtlas("Options_List_Active")
        local light = row:CreateTexture(nil, "HIGHLIGHT")
        light:SetAllPoints()
        light:SetAtlas("Options_List_Hover")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(Roster.ICON, Roster.ICON)
        row.icon:SetPoint("LEFT", 4, 0)
        row.right = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.right:SetPoint("RIGHT", -6, 0)
        row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.name:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", OnClick)
        row:SetScript("OnEnter", OnEnter)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end
    row.who = who
    local bank = who.key == ns.Snapshot.ACCOUNT
    if bank then
        row.icon:SetTexture(BANK_ICON)
        row.name:SetText(ns.Alts.TEXT.account)
        row.name:SetTextColor(1, 1, 1)
    else
        local atlas = rawget(_G, "GetClassAtlas")
        row.icon:SetTexture(nil)
        if atlas and who.class then row.icon:SetAtlas(atlas(who.class:lower())) end
        row.name:SetText(who.name or "?")
        row.name:SetTextColor(Roster.Colour(who.class))
    end
    local count = found and found[who.key]
    if found then
        row.right:SetText(count > 0 and count or "")
    else
        local money = not bank and type(who.money) == "number" and who.money or nil
        if money and money >= GOLD then money = money - money % GOLD end
        row.right:SetText(money and Core.Coins(money) or "")
    end
    row:SetAlpha(found and count == 0 and Roster.DIM or 1)
    row.lit:SetShown(who.key == chosen)
end

local function Init(row, who)
    ns.Safe("alts", Draw, row, who)
end
local function Factory(factory)
    factory("Button", Init)
end

function Roster.Build(parent)
    foot = CreateFrame("Frame", nil, parent)
    foot:SetPoint("BOTTOMLEFT")
    foot:SetSize(Roster.WIDTH, Roster.FOOT)
    foot.label = foot:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    foot.label:SetPoint("LEFT", 6, 0)
    foot.label:SetText(ns.Alts.TEXT.total)
    foot.gold = foot:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    foot.gold:SetPoint("RIGHT", -6, 0)
    local rule = foot:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.25)
    rule:SetPoint("TOPLEFT")
    rule:SetPoint("TOPRIGHT")
    rule:SetHeight(1)

    box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    box:SetPoint("TOPLEFT")
    box:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", 0, 4)
    local bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, 0)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 0)
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(Roster.ROW)
    view:SetElementFactory(Factory)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    Roster.box, Roster.foot = box, foot
end

-- The list drawn: these characters (Snapshot.Characters), the one shown lit; counts: [key] = how many the
-- search finds, or nil while nothing is searched.
function Roster.Show(characters, key, counts)
    chosen, found = key, counts
    box:SetDataProvider(CreateDataProvider(characters), ScrollBoxConstants.RetainScrollPosition)
    foot.gold:SetText(Core.Coins(ns.Snapshot.Gold()) or "")
end
