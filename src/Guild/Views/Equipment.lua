local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Guild - Views - Equipment
--  Everybody's gear (Guild › Equipment). At the left the characters: every
--  member, those who share their gear with their item level, sorted by it
--  (a click on a column's head sorts by another), searched by name. At the
--  right the one chosen as a paper doll: its name, level, class and rank, its
--  item level large, eight slots down each side and the weapons under them
--  (the ranged slot only where the game has one), around a figure (your own
--  as it stands; another's gear dressed on your own figure, as in the game's
--  dressing room: this client cannot show another's race), and when it was
--  shared (not live, but your own).
--
--  The gear is Core's (Core.Data.Guild): each member's card, which that member
--  shares with the guild while its switch is on; your own is read live.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Views, Layout, Kit, TEXT = ns.Views, ns.Layout, ns.Kit, ns.TEXT
local Equipment = {}
Views.equipment = Equipment

local view, list, doll
local chosen
local search, sortKey, descending = "", "itemLevel", true

-- The doll's slots: the left column, the right column, the weapons (the game's slot IDs), the ranged one of them.
Equipment.LEFT = { 1, 2, 3, 15, 5, 4, 19, 9 }
Equipment.RIGHT = { 10, 6, 7, 8, 11, 12, 13, 14 }
Equipment.WEAPONS = { 16, 17, 18 }
Equipment.RANGED = 18
-- The game's empty-slot pictures, by slot.
local EMPTY = { [1] = "Head", [2] = "Neck", [3] = "Shoulder", [15] = "Chest", [5] = "Chest", [4] = "Shirt", [19] = "Tabard",
    [9] = "Wrists", [10] = "Hands", [6] = "Waist", [7] = "Legs", [8] = "Feet", [11] = "Finger", [12] = "Finger",
    [13] = "Trinket", [14] = "Trinket", [16] = "MainHand", [17] = "SecondaryHand", [18] = "Ranged" }

local function Guild() return Core.Data.Guild end

-------------------------------------------------------------------------------
--  What the list shows (no frames: tested)
-------------------------------------------------------------------------------
local levels = {} -- [member key] = { stamp, level }: a card's item level, read once for each stamp

-- A card's item level: its text taken apart only when its stamp is new.
local function ItemLevel(key, card)
    local known = levels[key]
    if known and known.stamp == card.stamp then return known.level end
    local read = Guild().ReadCard(card.text)
    levels[key] = { stamp = card.stamp, level = read and read.itemLevel }
    return levels[key].level
end

-- Every member with what its card says: { key, name, class, level, itemLevel (nil: not shared), stamp }.
function Equipment.Characters(members, cards, text)
    local rows = {}
    for _, member in ipairs(members) do
        local name = member.name or ""
        if not text or text == "" or name:lower():find(text:lower(), 1, true) then
            local card = cards[member.key]
            rows[#rows + 1] = { key = member.key, name = name, class = member.class, level = member.level,
                                online = member.online, itemLevel = card and ItemLevel(member.key, card), stamp = card and card.stamp }
        end
    end
    return rows
end

function Equipment.Sort(rows, key, down)
    table.sort(rows, function(a, b)
        local x, y = a[key], b[key]
        if type(x) == "string" or type(y) == "string" then x, y = tostring(x or ""):lower(), tostring(y or ""):lower() end
        if x == nil and y ~= nil then return false end
        if y == nil and x ~= nil then return true end
        if x == y or x == nil then return (a.name or "") < (b.name or "") end
        if down then return x > y end
        return x < y
    end)
    return rows
end

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
local function Fill()
    if not list then return end
    local rows = Equipment.Characters(Guild().Roster(), Guild().Records("card"), search)
    Equipment.Sort(rows, sortKey, descending)
    for index, row in ipairs(rows) do row.index = index end
    list:Fill(rows, "")
end

local function Init(row, element)
    Kit.ClassIcon(row.icon, element.class)
    row.icon:SetDesaturated(not element.online)
    row.cells.name:SetText(element.online and Kit.Colored(element.name, element.class) or ("|cff9d9d9d%s|r"):format(element.name))
    row.cells.level:SetText(element.level or "")
    row.cells.itemLevel:SetText(element.itemLevel and ("%.1f"):format(element.itemLevel) or "|cff606060—|r")
    Kit.Stripe(row, element.index or 0)
    if row.LockHighlight then
        if element.key == chosen then row:LockHighlight() else row:UnlockHighlight() end
    end
end

-- The weapon slots this client's doll has: the ranged one only where the game's own paper doll shows it
-- (C_PaperDollInfo.IsRangedSlotShown: WoW: Forever, not Retail; a client that cannot say keeps it).
function Equipment.Weapons()
    local info = rawget(_G, "C_PaperDollInfo")
    local ranged = not (info and info.IsRangedSlotShown) or Core.Ask(info.IsRangedSlotShown) ~= false
    local slots = {}
    for _, slot in ipairs(Equipment.WEAPONS) do
        if ranged or slot ~= Equipment.RANGED then slots[#slots + 1] = slot end
    end
    return slots
end

-------------------------------------------------------------------------------
--  The doll
-------------------------------------------------------------------------------
local function Quality(item)
    local items = rawget(_G, "C_Item")
    local quality = items and items.GetItemQualityByID and Core.Ask(items.GetItemQualityByID, item)
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = quality and colors and colors[quality]
    if color then return color.r, color.g, color.b end
    return nil
end

local function Slot(parent, slot)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(Layout.SLOT, Layout.SLOT)
    button.slot = slot
    button.empty = button:CreateTexture(nil, "BACKGROUND")
    button.empty:SetAllPoints()
    button.empty:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. (EMPTY[slot] or "Chest"))
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetAllPoints()
    button.border:SetTexture("Interface\\Common\\WhiteIconFrame")
    button.level = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.level:SetPoint("BOTTOMRIGHT", -2, 2)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnEnter", ns.Guard(function(self)
        if not self.item then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.own then GameTooltip:SetInventoryItem("player", self.slot) else GameTooltip:SetItemByID(self.item) end
        GameTooltip:Show()
    end))
    button:SetScript("OnLeave", ns.Guard(function() GameTooltip:Hide() end))
    return button
end

local function Dress(button, worn, own)
    button.item, button.own = worn and worn.item, own
    if not worn then
        button.icon:Hide()
        button.border:Hide()
        button.level:SetText("")
        return
    end
    local items = rawget(_G, "C_Item")
    local icon = items and items.GetItemIconByID and Core.Ask(items.GetItemIconByID, worn.item)
    button.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.icon:Show()
    local r, g, b = Quality(worn.item)
    button.border:SetShown(r ~= nil)
    if r then button.border:SetVertexColor(r, g, b) end
    button.level:SetText(worn.level or "")
end

local function Model(card, member, own)
    local model = doll.model
    if not model then return end
    if own then
        model:Show() -- hidden for a member who shared nothing
        Core.Safe("doll", model.SetUnit, model, "player")
        return
    end
    if not (card and card.race) then
        model:Hide()
        return
    end
    model:Show()
    Core.Safe("doll", function()
        if model.SetCustomRace then model:SetCustomRace(card.race, card.sex == 3 and 1 or 0) end
        if model.Undress then model:Undress() end
        for slot, worn in pairs(card.worn) do
            if slot ~= 4 and slot ~= 19 and model.TryOn then model:TryOn("item:" .. worn.item) end
        end
    end)
end

local function Draw()
    local member = chosen and Guild().Member(chosen)
    doll.empty:SetShown(member == nil)
    doll.body:SetShown(member ~= nil)
    if not member then return end
    local own = member.key == Core.PlayerKey("player")
    local text, stamp = Guild().Record(member.key, "card")
    local card = text and Guild().ReadCard(text)
    if own then card = Guild().ReadCard(Guild().Card()) or card end
    local b = doll.body
    Kit.ClassIcon(b.icon, member.class)
    b.name:SetText(Kit.Colored(member.name, member.class))
    b.meta:SetText(("%s %d %s · %s"):format(Core.Word("LEVEL", "Level"), member.level or 0, member.className or "", member.rank or ""))
    local now = Core.Ask(GetServerTime) or 0
    b.stamp:SetText(own and TEXT.ownLive or (stamp and TEXT.sharedAgo:format(Layout.SinceText(now - stamp))) or "")
    b.itemLevel:SetText(card and card.itemLevel and ("%.1f"):format(card.itemLevel) or "—")
    local worn = 0
    for _, button in ipairs(b.slots) do
        local piece = card and card.worn[button.slot]
        if piece then worn = worn + 1 end
        Dress(button, piece, own)
    end
    b.count:SetText(TEXT.slotsWorn:format(worn, #b.slots))
    b.noCard:SetShown(card == nil)
    Model(card, member, own)
end

local function BuildDoll(parent)
    doll = Kit.Inset(parent)
    doll.empty = Kit.Empty(doll)
    doll.empty:SetText(TEXT.pickCharacter)
    local b = CreateFrame("Frame", nil, doll)
    b:SetAllPoints()
    doll.body = b
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(44, 44)
    b.icon:SetPoint("TOPLEFT", 14, -12)
    b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    b.name:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 10, -2)
    b.meta = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    b.meta:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -4)
    b.stamp = b:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    b.stamp:SetPoint("TOPLEFT", b.meta, "BOTTOMLEFT", 0, -3)
    b.laurel = b:CreateTexture(nil, "ARTWORK")
    b.laurel:SetSize(84, 84)
    b.laurel:SetPoint("TOPRIGHT", -24, -6)
    ns.Art.Set(b.laurel, "laurel")
    b.itemLevel = b:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    b.itemLevel:SetPoint("CENTER", b.laurel, "CENTER", 0, 0)
    b.itemLevelLabel = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    b.itemLevelLabel:SetPoint("RIGHT", b.laurel, "LEFT", -6, 6)
    b.itemLevelLabel:SetText(TEXT.itemLevel)
    b.count = b:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    b.count:SetPoint("TOPRIGHT", b.itemLevelLabel, "BOTTOMRIGHT", 0, -3)
    b.slots = {}
    local top = 92
    for index, slot in ipairs(Equipment.LEFT) do
        local button = Slot(b, slot)
        button:SetPoint("TOPLEFT", 16, -(top + (index - 1) * (Layout.SLOT + Layout.SLOT_GAP)))
        b.slots[#b.slots + 1] = button
    end
    for index, slot in ipairs(Equipment.RIGHT) do
        local button = Slot(b, slot)
        button:SetPoint("TOPRIGHT", -16, -(top + (index - 1) * (Layout.SLOT + Layout.SLOT_GAP)))
        b.slots[#b.slots + 1] = button
    end
    local weapons, held = CreateFrame("Frame", nil, b), Equipment.Weapons()
    weapons:SetSize(#held * Layout.SLOT + (#held - 1) * 40, Layout.SLOT)
    weapons:SetPoint("BOTTOM", 0, 16)
    for index, slot in ipairs(held) do
        local button = Slot(weapons, slot)
        button:SetPoint("LEFT", (index - 1) * (Layout.SLOT + 40), 0)
        b.slots[#b.slots + 1] = button
    end
    local ok, model = pcall(CreateFrame, "DressUpModel", nil, b)
    if ok and model then
        model:SetPoint("TOPLEFT", 16 + Layout.SLOT + 30, -top)
        model:SetPoint("BOTTOMRIGHT", -(16 + Layout.SLOT + 30), 16 + Layout.SLOT + 10)
        if model.SetPortraitZoom then model:SetPortraitZoom(0) end
        doll.model = model
    end
    b.noCard = Kit.Empty(b)
    b.noCard:ClearAllPoints()
    b.noCard:SetPoint("CENTER", 0, 0)
    b.noCard:SetWidth(300)
    b.noCard:SetText(TEXT.noCard)
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
function Equipment.Build(frame)
    view = frame
    local left = Kit.Inset(frame)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(Layout.LIST)
    local box = CreateFrame("EditBox", nil, left, "SearchBoxTemplate")
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", 10, -6)
    box:SetPoint("TOPRIGHT", -6, -6)
    box:SetAutoFocus(false)
    if box.Instructions then box.Instructions:SetText(TEXT.searchCharacters) end
    box:HookScript("OnTextChanged", ns.Guard(function(self)
        search = self:GetText() or ""
        Fill()
    end))
    list = Kit.Table(left, {
        columns = {
            { key = "name", text = TEXT.colName },
            { key = "level", text = TEXT.colLevel, width = 30, justify = "RIGHT" },
            { key = "itemLevel", text = TEXT.itemLevel, width = 64, justify = "RIGHT" },
        },
        icon = true, row = Layout.ROW + 2, init = Init,
        sort = function(key)
            if sortKey == key then descending = not descending else sortKey, descending = key, key ~= "name" end
            list:Sorted(sortKey, descending)
            Fill()
        end,
        click = function(_, element)
            chosen = element.key
            Fill()
            Draw()
        end,
    })
    list:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -6)
    list:SetPoint("BOTTOMRIGHT", -4, 4)
    list:Sorted(sortKey, descending)
    BuildDoll(frame)
    doll:SetPoint("TOPLEFT", left, "TOPRIGHT", Layout.GAP, 0)
    doll:SetPoint("BOTTOMRIGHT")
    chosen = chosen or Core.PlayerKey("player")
end

function Equipment.Refresh()
    if not view then return end
    Fill()
    Draw()
end

function Equipment.Show(on)
    if on then Equipment.Refresh() end
end

function Equipment.Title()
    local count = 0
    for _ in pairs(Guild().Records("card")) do count = count + 1 end
    return ("%d / %d"):format(count, #Guild().Roster())
end

function Equipment.Search(text)
    search = text or ""
    Fill()
end
