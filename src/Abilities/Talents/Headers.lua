local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Talents - Headers
--  Over each of the three trees its head, and at the top right your unspent
--  points, as the game's class talents frame shows them (Camelot:
--  ClassTalents/Blizzard_ClassTalentsFrame.xml, ClassTalentTreeHeaderTemplate
--  and ClassTalentCurrencyDisplayTemplate; their code in Camelot's
--  Blizzard_ClassTalentsFrame.lua, RefreshTreeHeaders, and the shared one's
--  RefreshClassCurrencyDisplay):
--    - a tree's head: its icon in the game's round mask and ring, its name, and
--      in the box under the ring the points spent in it (C_Traits: the tree's
--      groups, GetGroupDisplayInfoByTreeID, and what each group has spent,
--      GetGroupCurrencyInfo); the first at 140 from the frame's left, each next
--      400 further, 100 down
--    - the unspent points in the game's square box, green while there are any,
--      grey while there are none
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talents = ns.Talents
local Class = Talents.Class
local Headers = {}
ns.TalentsHeaders = Headers

-- The game's places (ClassTalentTreeHeaderTemplate, RefreshTreeHeaders): the heads over the frame's border, a head's
-- size and its parts; the unspent points from the border's top right corner, the box's amount (its container).
Headers.FIRST, Headers.SPACING, Headers.DOWN = 140, 400, -100
Headers.SIZE, Headers.ICON, Headers.MASK = 48, 36, 40
Headers.ICON_AT, Headers.MASK_AT, Headers.NAME_AT = { -3, 3 }, { -2, 2 }, { 54, 2 }
Headers.BOX_AT, Headers.DIVIDER_AT = { 14, -12 }, { 60, -20 }
Headers.LEVEL = 1010 -- the game's frame level for them, over the tree's nodes' parent
Headers.UNSPENT_AT = { -20, -6 }
Headers.AMOUNT = { 48, 36 }
Headers.AMOUNT_AT = -4
Headers.LABEL_AT = 60

local heads = {}   -- [frame] = its heads, made as needed, kept
local purses = {}  -- [frame] = its unspent points: { border, label, amount }

local function Traits()
    return rawget(_G, "C_Traits") or {}
end

-- A head as the game's template makes it.
local function MakeHead(frame)
    local head = CreateFrame("Frame", nil, frame)
    head:SetSize(Headers.SIZE, Headers.SIZE)
    head:SetFrameLevel(Headers.LEVEL)
    local icon = head:CreateTexture(nil, "BORDER")
    icon:SetSize(Headers.ICON, Headers.ICON)
    icon:SetPoint("CENTER", Headers.ICON_AT[1], Headers.ICON_AT[2])
    local mask = head:CreateMaskTexture(nil, "BORDER")
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetSize(Headers.MASK, Headers.MASK)
    mask:SetPoint("CENTER", Headers.MASK_AT[1], Headers.MASK_AT[2])
    icon:AddMaskTexture(mask)
    head.icon = icon

    local name = head:CreateFontString(nil, "OVERLAY", "GameFontWhiteLarge")
    local font, size = name:GetFont()
    if font then name:SetFont(font, size, "OUTLINE") end -- the game's outline="NORMAL"
    name:SetPoint("LEFT", Headers.NAME_AT[1], Headers.NAME_AT[2])
    head.name = name
    local ring = head:CreateTexture(nil, "OVERLAY")
    ring:SetAtlas("Talents-Main-Ring-c60", true)
    ring:SetPoint("CENTER", icon, "CENTER")
    local box = head:CreateTexture(nil, "OVERLAY")
    box:SetAtlas("talents-main-ring-box-c60", true)
    box:SetPoint("CENTER", Headers.BOX_AT[1], Headers.BOX_AT[2])
    local spent = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spent:SetJustifyH("CENTER")
    spent:SetJustifyV("MIDDLE")
    spent:SetPoint("CENTER", box, "CENTER")
    head.spent = spent
    local divider = head:CreateTexture(nil, "OVERLAY")
    divider:SetAtlas("Talents-small-divider-c60", true)
    divider:SetPoint("BOTTOM", head, "BOTTOM", Headers.DIVIDER_AT[1], Headers.DIVIDER_AT[2])
    return head
end

-- The group's spent points among what the game told of every group (ClassTalentTreeHeaderMixin:Setup).
local function Spent(groups, groupID)
    for _, group in ipairs(groups) do
        if type(group) == "table" and group.traitNodeGroupID == groupID then
            local currency = type(group.currencyInfos) == "table" and group.currencyInfos[1]
            return currency and currency.spent or nil, true
        end
    end
    return "0", false
end

-------------------------------------------------------------------------------
--  Made with the frame (Tree.lua)
-------------------------------------------------------------------------------
function Headers.Build(frame)
    heads[frame] = {}
    -- The unspent points: the game's box with the amount in it and the words before it, placed as the game's
    -- resizing frame ends up (as high as its box, from the border's top right corner).
    local purse = CreateFrame("Frame", nil, frame)
    purse:SetFrameLevel(Headers.LEVEL)
    local border = purse:CreateTexture(nil, "ARTWORK")
    border:SetAtlas("Talents-Square-Box-c60", true)
    purse:SetSize(1, math.max(border:GetHeight() or 0, Headers.AMOUNT[2]))
    purse:SetPoint("TOPRIGHT", frame.BackgroundBorder, "TOPRIGHT", Headers.UNSPENT_AT[1], Headers.UNSPENT_AT[2])
    border:SetPoint("RIGHT")
    local label = purse:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")
    label:SetJustifyH("RIGHT")
    label:SetText(Talents.TEXT.unspent)
    label:SetPoint("RIGHT", border, "LEFT", Headers.LABEL_AT, 0)
    local container = CreateFrame("Frame", nil, purse)
    container:SetSize(Headers.AMOUNT[1], Headers.AMOUNT[2])
    container:SetPoint("RIGHT", border, "RIGHT", Headers.AMOUNT_AT, 0)
    local amount = container:CreateFontString(nil, "ARTWORK", "Game32Font_Shadow2")
    amount:SetJustifyH("LEFT")
    amount:SetPoint("CENTER")
    purses[frame] = { border = border, label = label, amount = amount }
end

-- The frame's heads and its unspent points, as made.
function Headers.Heads(frame)
    return heads[frame] or {}
end

function Headers.Unspent(frame)
    return purses[frame]
end

-------------------------------------------------------------------------------
--  The frame's methods
-------------------------------------------------------------------------------
-- The trees' heads, from the game's groups of this tree (Camelot's RefreshTreeHeaders).
function Class:RefreshTreeHeaders()
    local list = heads[self]
    if not list then return end
    for _, head in ipairs(list) do head:Hide() end
    local treeID, configID = self:GetTalentTreeID(), self:GetConfigID()
    if not (treeID and configID) then return end
    local displays = Core.Ask(Traits().GetGroupDisplayInfoByTreeID, treeID)
    if type(displays) ~= "table" then return end
    local ids = {}
    for index, display in ipairs(displays) do ids[index] = display.groupID end
    local groups = #ids > 0 and Core.Ask(Traits().GetGroupCurrencyInfo, configID, ids) or nil
    if type(groups) ~= "table" then groups = {} end
    for index, display in ipairs(displays) do
        local head = list[index] or MakeHead(self)
        list[index] = head
        head:ClearAllPoints()
        head:SetPoint("CENTER", self.BackgroundBorder, "TOPLEFT", Headers.FIRST + (index - 1) * Headers.SPACING, Headers.DOWN)
        head.name:SetText(display.displayName or "")
        head.icon:SetTexture(display.icon)
        local spent, found = Spent(groups, display.groupID)
        head.spent:SetText(found and spent or "0")
        head.groupID = display.groupID
        head:Show()
    end
end

-- The unspent points (ClassTalentCurrencyDisplayMixin:SetAmount): this tree's first currency, green while any.
function Class:RefreshCurrencyDisplay()
    local purse = purses[self]
    if not purse then return end
    local currency = self.treeCurrencyInfo and self.treeCurrencyInfo[1]
    local amount = currency and type(currency.quantity) == "number" and currency.quantity or 0
    purse.amount:SetText(amount)
    local color = rawget(_G, amount > 0 and "GREEN_FONT_COLOR" or "GRAY_FONT_COLOR")
    if color and color.GetRGBA then purse.amount:SetTextColor(color:GetRGBA()) end
end
