local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Foot
--  The bag window's foot, a dark band at its bottom:
--      currencies   at the left, those the player watches in the backpack
--                   (the game's C_CurrencyInfo.GetBackpackCurrencyInfo), icon
--                   and amount
--      gold         at the right, the character's, in the game's coins; its
--                   tooltip every character of the account's gold and the
--                   total, from Core's data (Core.Data.Characters)
--  The bags themselves, in a strip under the window's bar (its button shows
--  or hides it): a square for the backpack and for each bag slot (the reagent
--  bag's too) and the keyring, the bag's icon in its quality's border, how
--  many of its slots are free on it, the game's tooltip for it (the bag, or
--  Equip Container for an empty slot) with its slots taken of how many; the
--  mouse on it lights that bag's items (Cells.Light); a click or a drag picks
--  the bag up, a bag let go over a slot is put there (the game's
--  PickupBagFromSlot, PutItemInBag, PutItemInBackpack), out of a fight only,
--  as the game's bag bar does.
--  And on the window's bar, left of the bags' button, a button for what can be
--  done here and now: Sell All Junk Items at a vendor while there is junk
--  (asked first, in the game's words), Deposit All Reagents at a banker whose
--  bank takes them (C_Bank.AutoDepositItemsIntoBank). The junk is what is
--  junk to us (Groups.lua: the game's grey items, the player's marks): where
--  that is just the game's junk, the game's own sell-all sells it
--  (C_MerchantFrame.SellAllJunkItems); else each item is sold as a click on it
--  at the vendor sells it (C_Container.UseContainerItem), while the vendor is
--  there.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Foot = {}
ns.Foot = Foot

Foot.HEIGHT = 28
Foot.BAG = 34          -- a bag's square in the strip
Foot.BAG_GAP = 4
Foot.STRIP = Foot.BAG + 12
Foot.TOKENS = 3        -- the currencies the game lets the backpack watch (MAX_WATCHED_TOKENS)
Foot.TOKEN = 17        -- a currency's icon
Foot.TOKEN_CUT = 5 / 64
Foot.TOKEN_GAP = 5
Foot.ACT = 18          -- the bar's button for what can be done here
Foot.ACT_COLOR = { 0.85, 0.82, 0.55 }
Foot.ACT_LIT = { 1, 0.96, 0.66 }

local Contents = ns.Contents
local foot, strip, gold, act, tokens
local bags = {}        -- [index] = a bag's button; bagOf[button] = its container
local bagOf = {}
local doing            -- what the button does now: "junk", "deposit" or nil
local carried          -- the bags' section (Bags.lua: its slots, its free slots)
local junk = {}        -- the records of junk to sell (Contents.Junk), used again

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Container()
    return rawget(_G, "C_Container") or {}
end

-- The inventory slot a bag sits in (nil: the backpack, the keyring).
local function Slot(bag)
    if bag == Contents.BACKPACK or bag == Contents.KEYRING then return nil end
    local api = Container()
    return api.ContainerIDToInventoryID and Core.Plain(Core.Ask(api.ContainerIDToInventoryID, bag)) or nil
end

-------------------------------------------------------------------------------
--  The bags
-------------------------------------------------------------------------------
local function BagEnter(button)
    local bag = bagOf[button]
    local tip = GameTooltip
    tip:SetOwner(button, "ANCHOR_TOP")
    local slot = Slot(bag)
    if bag == Contents.BACKPACK then
        tip:SetText(Core.Word("BACKPACK_TOOLTIP", "Backpack"), 1, 1, 1)
    elseif bag == Contents.KEYRING then
        tip:SetText(Core.Word("KEYRING", "Keyring"), 1, 1, 1)
    elseif not (slot and tip:SetInventoryItem("player", slot)) then
        local word = Contents.Reagent(bag) and Core.Word("EQUIP_CONTAINER_REAGENT", "Equip Reagent Bag")
            or Core.Word("EQUIP_CONTAINER", "Equip Container")
        tip:SetText(word, 1, 0.82, 0)
    end
    local size = Contents.Size(bag)
    if size > 0 then
        local api = Container()
        local left = Core.Plain(Core.Ask(api.GetContainerNumFreeSlots, bag)) or 0
        tip:AddLine(ns.TEXT.bagsTaken:format(size - left, size), 1, 1, 1)
    end
    tip:Show()
    ns.Cells.Light(bag)
end

local function BagLeave()
    GameTooltip:Hide()
    ns.Cells.Light(nil)
end

-- A click or a drag on a bag: what is on the cursor goes into it (a key on the keyring), else the bag is picked up
-- (not the backpack, not the keyring). Not in a fight.
local function BagClick(button)
    if InCombatLockdown() then return end
    local bag = bagOf[button]
    if bag == Contents.BACKPACK or bag == Contents.KEYRING then
        if Game("CursorHasItem") then Game(bag == Contents.KEYRING and "PutKeyInKeyRing" or "PutItemInBackpack") end
        return
    end
    local slot = Slot(bag)
    if not slot then return end
    if Game("CursorHasItem") then
        Game("PutItemInBag", slot)
    else
        Game("PickupBagFromSlot", slot)
    end
end

local edges = {}  -- [button] = a bag's border (Cells.Border)
local frees = {}  -- [button] = how many of its slots are free, on it

local function MakeBag(index)
    local made, button = pcall(CreateFrame, "ItemButton", nil, strip)
    if not made then button = CreateFrame("Button", nil, strip, "ItemButtonTemplate") end
    button:SetSize(Foot.BAG, Foot.BAG)
    local icon = ns.Cells.Part(button, "icon")
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints()
        icon:SetTexCoord(ns.Cells.ZOOM, 1 - ns.Cells.ZOOM, ns.Cells.ZOOM, 1 - ns.Cells.ZOOM)
    end
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    local border = ns.Cells.Part(button, "IconBorder")
    if border then border:SetAlpha(0) end
    edges[button] = ns.Cells.Border(button)
    local font = ns.Cells.Fonts()
    local count = ns.Cells.Part(button, "Count")
    if count then count:Hide() end
    frees[button] = button:CreateFontString(nil, "OVERLAY")
    if font.count then frees[button]:SetFontObject(font.count) end
    frees[button]:SetPoint("BOTTOMRIGHT", -2, 2)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnEnter", function(self) ns.Safe("bags", BagEnter, self) end)
    button:SetScript("OnLeave", function() ns.Safe("bags", BagLeave) end)
    button:SetScript("OnClick", function(self) ns.Safe("bags", BagClick, self) end)
    button:SetScript("OnDragStart", function(self) ns.Safe("bags", BagClick, self) end)
    button:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", BagClick, self) end)
    bags[index] = button
    return button
end

-- The bags in the bar: the backpack, every bag slot (equipped or not), the reagent bag's slot, the keyring if
-- the character has one.
local list = {}
local function Bar()
    for index = #list, 1, -1 do list[index] = nil end
    local constants = rawget(_G, "Constants") and Constants.InventoryConstants or {}
    local last = (constants.NumBagSlots or rawget(_G, "NUM_BAG_SLOTS") or 4) + (constants.NumReagentBagSlots or 0)
    for bag = Contents.BACKPACK, last do list[#list + 1] = bag end
    if Contents.Size(Contents.KEYRING) > 0 then list[#list + 1] = Contents.KEYRING end
    return list
end

local function Icon(bag)
    if bag == Contents.BACKPACK then return "Interface\\Icons\\ui-hud-actionbar-bag" end
    if bag == Contents.KEYRING then return "Interface\\Icons\\ui-hud-actionbar-keyring" end
    local slot = Slot(bag)
    local texture = slot and Core.Plain(Core.Ask(GetInventoryItemTexture, "player", slot))
    if texture then return texture end
    local paperdoll = rawget(_G, "C_PaperDollInfo")
    local info = paperdoll and paperdoll.GetInventorySlotInfo or rawget(_G, "GetInventorySlotInfo")
    local _, picture = Core.Ask(info, "Bag0Slot")
    return picture
end

-- A bag's quality, for its border (nil: the backpack, the keyring, an empty slot).
local function Quality(bag)
    local slot = Slot(bag)
    local quality = slot and Core.Plain(Core.Ask(rawget(_G, "GetInventoryItemQuality"), "player", slot))
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    return quality and colors and colors[quality]
end

function Foot.Bags()
    local before
    local api = Container()
    for index, bag in ipairs(Bar()) do
        local button = bags[index] or MakeBag(index)
        bagOf[button] = bag
        Game("SetItemButtonTexture", button, Icon(bag))
        local size = Contents.Size(bag)
        local left = size > 0 and Core.Plain(Core.Ask(api.GetContainerNumFreeSlots, bag)) or nil
        frees[button]:SetText(left and tostring(left) or "")
        local color = Quality(bag)
        local neutral = ns.Cells.NEUTRAL
        ns.Cells.Edge(edges[button], color and color.r or neutral[1], color and color.g or neutral[2],
            color and color.b or neutral[3], 1, Core.Pixels(button, 1))
        button:ClearAllPoints()
        if before then
            button:SetPoint("LEFT", before, "RIGHT", Foot.BAG_GAP, 0)
        else
            button:SetPoint("LEFT", ns.Bags.INSET + ns.Bags.EDGE, 0)
        end
        button:Show()
        before = button
    end
    for index = #list + 1, #bags do bags[index]:Hide() end
end

-------------------------------------------------------------------------------
--  Free slots, the button, currencies, gold
-------------------------------------------------------------------------------
-- Every bag's slots taken of how many, for the bar's count.
function Foot.FreeTip(owner)
    local tip = GameTooltip
    tip:SetOwner(owner, "ANCHOR_BOTTOM")
    tip:SetText(ns.TEXT.bags, 1, 0.82, 0)
    local api = Container()
    for _, bag in ipairs(Bar()) do
        local size = Contents.Size(bag)
        if size > 0 then
            local left = Core.Plain(Core.Ask(api.GetContainerNumFreeSlots, bag)) or 0
            local name = bag == Contents.BACKPACK and Core.Word("BACKPACK_TOOLTIP", "Backpack") or Contents.KindWord(bag)
            tip:AddDoubleLine(name, ns.TEXT.bagsTaken:format(size - left, size), 1, 1, 1, 1, 1, 1)
        end
    end
    tip:Show()
end

-- Who the player is talking to now (the game's interaction manager).
local function Talking(kind)
    local manager = rawget(_G, "C_PlayerInteractionManager")
    local types = Enum and Enum.PlayerInteractionType
    if not (manager and manager.IsInteractingWithNpcOfType and types and types[kind]) then return false end
    return Core.Ask(manager.IsInteractingWithNpcOfType, types[kind]) == true
end
Foot.Talking = Talking

-- Whether there is junk to sell at the vendor now.
local function Junk()
    if not (carried and Talking("Merchant")) then return false end
    return #Contents.Junk(carried.slots, junk) > 0
end

-- Whether the bank open now takes the reagents.
local function Deposit()
    local bank = rawget(_G, "C_Bank")
    local kind = Enum and Enum.BankType and Enum.BankType.Character
    if not (Contents.bankOpen and bank and bank.AutoDepositItemsIntoBank and kind) then return false end
    return not bank.DoesBankTypeSupportAutoDeposit or Core.Ask(bank.DoesBankTypeSupportAutoDeposit, kind) == true
end

function Foot.Act()
    doing = Junk() and "junk" or Deposit() and "deposit" or nil
    if doing == "junk" then
        act.text:SetText(Core.Word("SELL_ALL_JUNK_ITEMS", "Sell All Junk Items"))
    elseif doing == "deposit" then
        act.text:SetText(Core.Word("REAGENTBANK_DEPOSIT", "Deposit All Reagents"))
    end
    act:SetWidth(math.max(58, (act.text:GetStringWidth() or 0) + 14))
    act:SetShown(doing ~= nil)
end

-- The junk sold, the bags read anew first (they may have changed while the question was open).
local function Sell()
    if not Talking("Merchant") then return end
    local list, same = Contents.Junk(ns.Bags.Carried().slots, junk)
    local merchant = rawget(_G, "C_MerchantFrame")
    local game = merchant and merchant.SellAllJunkItems
        and not (merchant.IsSellAllJunkEnabled and Core.Ask(merchant.IsSellAllJunkEnabled) == false)
    if same and game then
        merchant.SellAllJunkItems()
        return
    end
    local api = Container()
    if not api.UseContainerItem or Game("CursorHasItem") then return end
    for _, record in ipairs(list) do
        if not record.locked then api.UseContainerItem(record.bag, record.slot) end
    end
end

local function Act()
    if doing == "junk" then
        Core.Confirm(Core.Word("SELL_ALL_JUNK_ITEMS_POPUP", Core.Word("SELL_ALL_JUNK_ITEMS", "Sell All Junk Items")), nil, Sell)
    elseif doing == "deposit" and not InCombatLockdown() then
        C_Bank.AutoDepositItemsIntoBank(Enum.BankType.Character)
    end
end

-- The currencies watched in the backpack, at the foot's left.
function Foot.Tokens()
    local info = rawget(_G, "C_CurrencyInfo")
    local before
    for index = 1, Foot.TOKENS do
        local token = tokens[index]
        local data = info and info.GetBackpackCurrencyInfo and Core.Ask(info.GetBackpackCurrencyInfo, index)
        if type(data) == "table" and Core.Plain(data.quantity) then
            local large = rawget(_G, "BreakUpLargeNumbers")
            token.text:SetText(large and large(data.quantity) or tostring(data.quantity))
            token.icon:SetTexture(data.iconFileID)
            token:SetWidth((token.text:GetStringWidth() or 0) + Foot.TOKEN + Foot.TOKEN_GAP)
            token:ClearAllPoints()
            if before then
                token:SetPoint("LEFT", before, "RIGHT", Foot.TOKEN_GAP * 2, 0)
            else
                token:SetPoint("LEFT", ns.Bags.INSET + ns.Bags.EDGE, 0)
            end
            token:Show()
            before = token
        else
            token:Hide()
        end
    end
end

local function TokenEnter(token)
    GameTooltip:SetOwner(token, "ANCHOR_TOP")
    if GameTooltip.SetBackpackToken then GameTooltip:SetBackpackToken(token:GetID()) end
    GameTooltip:Show()
end

function Foot.Gold()
    gold:SetText(Core.Coins(Core.Plain(Core.Ask(GetMoney)) or 0) or "")
    gold:SetWidth((gold.text:GetStringWidth() or 0) + 4)
end

-- Every character of the account and its gold, this one's as it is now; the total.
local function GoldEnter(owner)
    local tip = GameTooltip
    tip:SetOwner(owner, "ANCHOR_TOP")
    tip:SetText(ns.TEXT.bagsGold, 1, 0.82, 0)
    local total = 0
    local mine = Core.Plain(Core.Ask(GetMoney)) or 0
    local characters = Core.Data.Characters and Core.Data.Characters()
    local colors = rawget(_G, "RAID_CLASS_COLORS") or {}
    local white = { r = 1, g = 1, b = 1 }
    for _, character in ipairs(characters or {}) do
        local money = character.key == Core.charKey and mine or character.money
        if type(money) == "number" then
            local color = colors[character.class] or white
            tip:AddDoubleLine(character.name or "", Core.Coins(money) or "", color.r, color.g, color.b, 1, 1, 1)
            total = total + money
        end
    end
    if not characters then total = mine end
    tip:AddLine(" ")
    tip:AddDoubleLine(Core.Word("TOTAL", "Total"), Core.Coins(total) or "", 1, 0.82, 0, 1, 1, 1)
    tip:Show()
end

-------------------------------------------------------------------------------
--  Built once, in the window's body
-------------------------------------------------------------------------------
local function Label(parent, font)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(Foot.HEIGHT)
    frame.text = frame:CreateFontString(nil, "ARTWORK")
    if font then frame.text:SetFontObject(font) end
    frame.text:SetPoint("RIGHT")
    frame.SetText = function(self, text) self.text:SetText(text) end
    return frame
end

local function ActLit(on)
    local color = on and Foot.ACT_LIT or Foot.ACT_COLOR
    act.text:SetTextColor(color[1], color[2], color[3])
end

-- The foot in the window's body; the button for what can be done here left of beside (on the bar); the bags in
-- their strip (under the bar).
function Foot.Build(body, beside, holder)
    strip = holder
    foot = CreateFrame("Frame", nil, body)
    foot:SetPoint("BOTTOMLEFT")
    foot:SetPoint("BOTTOMRIGHT")
    foot:SetHeight(Foot.HEIGHT)
    ns.Bags.Band(foot, "TOP")
    Foot.frame = foot
    local font = ns.Bags.Fonts().count
    gold = Label(foot, font)
    gold.text:SetTextColor(1, 1, 1)
    gold:SetPoint("RIGHT", -(ns.Bags.INSET + ns.Bags.EDGE), 0)
    gold:SetScript("OnEnter", function(self) ns.Safe("bags", GoldEnter, self) end)
    gold:SetScript("OnLeave", GameTooltip_Hide)
    tokens = {}
    for index = 1, Foot.TOKENS do
        local token = Label(foot, font)
        token:SetID(index)
        token.text:SetTextColor(1, 1, 1)
        token.icon = token:CreateTexture(nil, "ARTWORK")
        token.icon:SetSize(Foot.TOKEN, Foot.TOKEN)
        token.icon:SetTexCoord(Foot.TOKEN_CUT, 1 - Foot.TOKEN_CUT, Foot.TOKEN_CUT, 1 - Foot.TOKEN_CUT)
        token.icon:SetPoint("LEFT")
        token:SetScript("OnEnter", function(self) ns.Safe("bags", TokenEnter, self) end)
        token:SetScript("OnLeave", GameTooltip_Hide)
        token:Hide()
        tokens[index] = token
    end
    act = CreateFrame("Button", nil, beside:GetParent())
    act:SetHeight(Foot.ACT)
    act:SetPoint("RIGHT", beside, "LEFT", -ns.Bags.BAR_GAP, 0)
    local back = act:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.4)
    act.text = act:CreateFontString(nil, "ARTWORK")
    act.text:SetFontObject(Core.Font("SaneUIBagsAct", "GameFontHighlightSmall", 10) or "GameFontHighlightSmall")
    act.text:SetPoint("CENTER")
    ActLit(false)
    act:SetScript("OnClick", function() ns.Safe("bags", Act) end)
    act:SetScript("OnEnter", function() ns.Safe("bags", ActLit, true) end)
    act:SetScript("OnLeave", function() ns.Safe("bags", ActLit, false) end)
    act:Hide()
end

-- Everything in the foot as it is now; section: the bags' (Bags.lua).
function Foot.Refresh(section)
    carried = section
    Foot.Bags()
    Foot.Act()
    Foot.Gold()
    Foot.Tokens()
end
