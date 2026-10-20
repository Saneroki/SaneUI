local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Foot
--  The bag window's foot, left to right:
--      the bags     a button for the backpack and for each bag slot (the
--                   reagent bag's too) and the keyring: the bag's icon on the
--                   game's bag frame, the game's tooltip for it (the bag, or
--                   Equip Container for an empty slot) and how many of its
--                   slots are free; the mouse on it lights that bag's items
--                   (Cells.Light); a click or a drag picks the bag up, a bag
--                   let go over a slot is put there (the game's
--                   PickupBagFromSlot, PutItemInBag, PutItemInBackpack), out
--                   of a fight only, as the game's bag bar does
--      free         how many slots of the ordinary bags are free; its tooltip
--                   every bag's
--      currencies   those the player watches in the backpack (the game's
--                   C_CurrencyInfo.GetBackpackCurrencyInfo), icon and amount
--      gold         the character's, in the game's coins; its tooltip every
--                   character of the account's gold and the total, from Core's
--                   data (Core.Data.Characters)
--  And on the window's head, left of the clean-up, a button for what can be
--  done here and now: Sell All Junk Items at a vendor while there is junk
--  (asked first, in the game's words: C_MerchantFrame.SellAllJunkItems),
--  Deposit All Reagents at a banker whose bank takes them
--  (C_Bank.AutoDepositItemsIntoBank).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Foot = {}
ns.Foot = Foot

Foot.HEIGHT = 30
Foot.BAG = 24          -- a bag's button
Foot.BAG_GAP = 3
Foot.FRAME = 46 / 45   -- the game's bag frame round its icon, as large to the button as on the game's bag bar
Foot.TOKENS = 3        -- the currencies the game lets the backpack watch (MAX_WATCHED_TOKENS)

local Contents = ns.Contents
local foot, free, gold, act, tokens
local bags = {}        -- [index] = a bag's button; bagOf[button] = its container
local bagOf = {}
local doing            -- what the button does now: "junk", "deposit" or nil

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
        tip:AddLine(ns.TEXT.bagsFree:format(left) .. " / " .. size, 1, 1, 1)
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

local function MakeBag(index)
    local made, button = pcall(CreateFrame, "ItemButton", nil, foot)
    if not made then button = CreateFrame("Button", nil, foot, "ItemButtonTemplate") end
    button:SetSize(Foot.BAG, Foot.BAG)
    local frame = button:CreateTexture(nil, "OVERLAY")
    frame:SetAtlas("ui-hud-actionbar-iconframe-bags")
    frame:SetSize(Foot.BAG * Foot.FRAME, Foot.BAG * Foot.FRAME)
    frame:SetPoint("CENTER")
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

function Foot.Bags()
    local before
    for index, bag in ipairs(Bar()) do
        local button = bags[index] or MakeBag(index)
        bagOf[button] = bag
        Game("SetItemButtonTexture", button, Icon(bag))
        button:ClearAllPoints()
        if before then button:SetPoint("LEFT", before, "RIGHT", Foot.BAG_GAP, 0) else button:SetPoint("LEFT", ns.Bags.EDGE, 0) end
        button:Show()
        before = button
    end
    for index = #list + 1, #bags do bags[index]:Hide() end
    Foot.last = before
end

-------------------------------------------------------------------------------
--  Free slots, the button, currencies, gold
-------------------------------------------------------------------------------
-- How many slots are free, and every bag's in the tooltip.
function Foot.Free(tally)
    free:SetText(ns.TEXT.bagsFree:format(tally.count))
    free:ClearAllPoints()
    free:SetPoint("LEFT", Foot.last or foot, Foot.last and "RIGHT" or "LEFT", 8, 0)
end

local function FreeEnter(owner)
    local tip = GameTooltip
    tip:SetOwner(owner, "ANCHOR_TOP")
    tip:SetText(ns.TEXT.bags, 1, 0.82, 0)
    local api = Container()
    for _, bag in ipairs(Bar()) do
        local size = Contents.Size(bag)
        if size > 0 then
            local left = Core.Plain(Core.Ask(api.GetContainerNumFreeSlots, bag)) or 0
            local name = bag == Contents.BACKPACK and Core.Word("BACKPACK_TOOLTIP", "Backpack") or Contents.KindWord(bag)
            tip:AddDoubleLine(name, ns.TEXT.bagsFree:format(left) .. " / " .. size, 1, 1, 1, 1, 1, 1)
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
    local merchant = rawget(_G, "C_MerchantFrame")
    if not (merchant and merchant.SellAllJunkItems and Talking("Merchant")) then return false end
    if merchant.IsSellAllJunkEnabled and Core.Ask(merchant.IsSellAllJunkEnabled) == false then return false end
    local count = merchant.GetNumJunkItems and Core.Plain(Core.Ask(merchant.GetNumJunkItems))
    return type(count) == "number" and count > 0
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
        act:SetText(Core.Word("SELL_ALL_JUNK_ITEMS", "Sell All Junk Items"))
    elseif doing == "deposit" then
        act:SetText(Core.Word("REAGENTBANK_DEPOSIT", "Deposit All Reagents"))
    end
    act:SetWidth(math.max(80, (act:GetTextWidth() or 0) + 24))
    act:SetShown(doing ~= nil)
end

local function Sell()
    local merchant = rawget(_G, "C_MerchantFrame")
    if merchant and merchant.SellAllJunkItems then merchant.SellAllJunkItems() end
end

local function Act()
    if doing == "junk" then
        Core.Confirm(Core.Word("SELL_ALL_JUNK_ITEMS_POPUP", Core.Word("SELL_ALL_JUNK_ITEMS", "Sell All Junk Items")), nil, Sell)
    elseif doing == "deposit" and not InCombatLockdown() then
        C_Bank.AutoDepositItemsIntoBank(Enum.BankType.Character)
    end
end

-- The currencies watched in the backpack, right of the button's place, left of the gold.
function Foot.Tokens()
    local info = rawget(_G, "C_CurrencyInfo")
    local before = gold
    for index = 1, Foot.TOKENS do
        local token = tokens[index]
        local data = info and info.GetBackpackCurrencyInfo and Core.Ask(info.GetBackpackCurrencyInfo, index)
        if type(data) == "table" and Core.Plain(data.quantity) then
            local large = rawget(_G, "BreakUpLargeNumbers")
            token.text:SetText(large and large(data.quantity) or tostring(data.quantity))
            token.icon:SetTexture(data.iconFileID)
            token:SetWidth((token.text:GetStringWidth() or 0) + 18)
            token:ClearAllPoints()
            token:SetPoint("RIGHT", before, "LEFT", -8, 0)
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
    frame.text = frame:CreateFontString(nil, "ARTWORK", font)
    frame.text:SetPoint("RIGHT")
    frame.SetText = function(self, text) self.text:SetText(text) end
    return frame
end

-- The foot in the window's body; the button for what can be done here left of beside (on the head).
function Foot.Build(body, beside)
    foot = CreateFrame("Frame", nil, body)
    foot:SetPoint("BOTTOMLEFT")
    foot:SetPoint("BOTTOMRIGHT")
    foot:SetHeight(Foot.HEIGHT)
    Foot.frame = foot
    free = foot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    local hover = CreateFrame("Frame", nil, foot)
    hover:SetAllPoints(free)
    hover:SetScript("OnEnter", function(self) ns.Safe("bags", FreeEnter, self) end)
    hover:SetScript("OnLeave", GameTooltip_Hide)
    gold = Label(foot, "GameFontHighlight")
    gold:SetPoint("RIGHT", -ns.Bags.EDGE - 2, 0)
    gold:SetScript("OnEnter", function(self) ns.Safe("bags", GoldEnter, self) end)
    gold:SetScript("OnLeave", GameTooltip_Hide)
    tokens = {}
    for index = 1, Foot.TOKENS do
        local token = Label(foot, "GameFontHighlightSmall")
        token:SetID(index)
        token.text:SetPoint("RIGHT", -16, 0)
        token.icon = token:CreateTexture(nil, "ARTWORK")
        token.icon:SetSize(14, 14)
        token.icon:SetPoint("RIGHT")
        token:SetScript("OnEnter", function(self) ns.Safe("bags", TokenEnter, self) end)
        token:SetScript("OnLeave", GameTooltip_Hide)
        token:Hide()
        tokens[index] = token
    end
    act = CreateFrame("Button", nil, beside:GetParent(), "UIPanelButtonTemplate")
    act:SetHeight(22)
    act:SetPoint("RIGHT", beside, "LEFT", -6, 0)
    act:SetScript("OnClick", function() ns.Safe("bags", Act) end)
    act:Hide()
end

-- Everything in the foot as it is now.
function Foot.Refresh(tally)
    Foot.Bags()
    Foot.Free(tally)
    Foot.Act()
    Foot.Gold()
    Foot.Tokens()
end
