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
--  What does not fit a narrow window goes (Foot.Room): the currencies first,
--  then the words of the checkboxes (the boxes stay, their tooltips say them).
--  The bags themselves, in a strip under the window's bar (its button shows
--  or hides it): a pencil slot, a little smaller than an item's, for the
--  backpack and for each bag slot (the reagent bag's too) and the keyring; the
--  bag's icon in it, its corners rounded and no border (a slot of ours, not
--  the game's item button, so nothing of the game's touches the icon: read
--  from the slot, else from the item worn there; a bag worn whose icon the game
--  does not tell shows a bag), how many of its slots are free on it. An empty
--  one shows what goes there, in one of the bags' drawings (Foot.EMPTY: a pouch
--  for a bag, the mortar for the reagent bag, a key for a keyring without keys;
--  Saneroki, 2026-10-30). The game's tooltip for it (the bag, or
--  Equip Container for an empty slot) with its slots taken of how many; the
--  mouse on it lights that bag's items (Cells.Light); a click or a drag picks
--  the bag up, a bag let go over a slot is put there (the game's
--  PickupBagFromSlot, PutItemInBag, PutItemInBackpack), out of a fight only,
--  as the game's bag bar does.
--  And on the window's bar, left of the junk marker, a button for what can be
--  done here and now: Sell All Junk Items at a vendor while there is junk
--  (asked first, in the game's words). (Deposit All Reagents at a banker whose
--  bank takes them is the bank window's: Foot.Deposits, Bank.lua.) The junk is what is
--  junk to us (Categories.lua: the game's grey items, the player's marks):
--  where that is just the game's junk, the game's own sell-all sells it
--  (C_MerchantFrame.SellAllJunkItems); else each item is sold as a click on it
--  at the vendor sells it (C_Container.UseContainerItem), one at a time, while
--  the vendor is there, out of a fight and with nothing on the cursor; either
--  way the chat says how many were sold and for how much, and how many could
--  not be. Auto Sell and Auto Repair, the two checkboxes left of the gold, are
--  Vendor.lua's; they sell through Foot.Sell, unasked.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Foot = {}
ns.Foot = Foot

Foot.HEIGHT = 28
Foot.BAG = 40          -- a bag's square in the strip, in an item's look (Saneroki, 2026-10-30: a little smaller)
Foot.BAG_GAP = 4
Foot.STRIP = Foot.BAG + 10
Foot.DRAWING = 0.8     -- an empty slot's drawing against the slot's side
Foot.DRAWN = 0.6       -- and how much of it shows: plain to see, still empty
-- What an empty slot shows: a picture of the bags' (Categories.Art).
Foot.EMPTY = { bag = "one", reagent = "reagent", keyring = "key" }
Foot.BAG_ICON = "Interface\\Icons\\INV_Misc_Bag_08" -- a bag worn whose icon the game does not tell
Foot.TOKENS = 3        -- the currencies the game lets the backpack watch (MAX_WATCHED_TOKENS)
Foot.TOKEN = 17        -- a currency's icon
Foot.TOKEN_CUT = 5 / 64
Foot.TOKEN_GAP = 5
Foot.ACT = 22          -- the bank bar's button for what can be done there: the game's red button
Foot.ACT_COLOR = { ns.Style.GOLD[1], ns.Style.GOLD[2], ns.Style.GOLD[3] } -- a red button's words, the game's gold
Foot.STEP = 0.08       -- seconds between two items sold
Foot.SOLD = 0.5        -- seconds after the game's sell-all until its money is there

local Contents = ns.Contents
local foot, strip, gold, act, tokens
local room             -- the window's body is this wide (Foot.Room; nil: not known yet)
local bags = {}        -- [index] = a bag's button; bagOf[button] = its container
local bagOf = {}
local doing            -- what the button does now: "junk" or nil
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

local frees = {}  -- [button] = how many of its slots are free, on it
local slotOf = {} -- [button] = its pencil slot, half drawn while no bag is in it (ns.Cells.EMPTY_SLOT)
local iconOf = {} -- [button] = the bag's icon
local emptyOf = {} -- [button] = the drawing of what goes into it

local function MakeBag(index)
    local button = CreateFrame("Button", nil, strip)
    button:SetSize(Foot.BAG, Foot.BAG)
    -- a pencil slot on the paper, the bag's icon in it (Core.Journal)
    local inset = Foot.BAG * ns.Style.SLOT_ICON
    slotOf[button] = ns.Style.Slot(button, 1, "BACKGROUND")
    local face = CreateFrame("Frame", nil, button)
    face:SetPoint("TOPLEFT", inset, -inset)
    face:SetPoint("BOTTOMRIGHT", -inset, inset)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(face)
    icon:SetTexCoord(ns.Cells.ZOOM, 1 - ns.Cells.ZOOM, ns.Cells.ZOOM, 1 - ns.Cells.ZOOM)
    iconOf[button] = icon
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local light = button:GetHighlightTexture()
    if light then light:SetAllPoints(face) end
    ns.Cells.Mask(button, nil, icon, light)
    local drawing = button:CreateTexture(nil, "ARTWORK")
    drawing:SetSize(Foot.BAG * Foot.DRAWING, Foot.BAG * Foot.DRAWING)
    drawing:SetPoint("CENTER")
    drawing:SetAlpha(Foot.DRAWN)
    emptyOf[button] = drawing
    local font = ns.Cells.Fonts()
    frees[button] = button:CreateFontString(nil, "OVERLAY")
    if font.count then frees[button]:SetFontObject(font.count) end
    frees[button]:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", -1, 1)
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

-- A bag's icon: the backpack's, the keyring's while keys are on it, the bag's in its slot (the slot's as the game
-- tells it, else the item's worn there, else any bag's: a slot with a bag in it never looks empty); nil for an
-- empty slot.
local function Icon(bag, size, left)
    if bag == Contents.BACKPACK then return "Interface\\Icons\\ui-hud-actionbar-bag" end
    if bag == Contents.KEYRING then
        return left ~= size and "Interface\\Icons\\ui-hud-actionbar-keyring" or nil
    end
    local slot = Slot(bag)
    local file = slot and Core.Ask(GetInventoryItemTexture, "player", slot)
    if file then return file end
    local item = slot and Core.Ask(rawget(_G, "GetInventoryItemID"), "player", slot)
    local items = rawget(_G, "C_Item")
    file = item and items and Core.Ask(items.GetItemIconByID, item)
    return file or size > 0 and Foot.BAG_ICON or nil
end

-- What an empty slot of the strip shows: what goes there.
local function Drawing(bag)
    if bag == Contents.KEYRING then return Foot.EMPTY.keyring end
    return Contents.Reagent(bag) and Foot.EMPTY.reagent or Foot.EMPTY.bag
end

function Foot.Bags()
    local before
    local api = Container()
    for index, bag in ipairs(Bar()) do
        local button = bags[index] or MakeBag(index)
        bagOf[button] = bag
        local size = Contents.Size(bag)
        local left = size > 0 and Core.Plain(Core.Ask(api.GetContainerNumFreeSlots, bag)) or nil
        local picture = Icon(bag, size, left)
        iconOf[button]:SetTexture(picture)
        iconOf[button]:SetShown(picture ~= nil)
        emptyOf[button]:SetShown(picture == nil)
        if not picture then emptyOf[button]:SetTexture(ns.Categories.Art(Drawing(bag))) end
        slotOf[button]:SetAlpha(picture and 1 or ns.Cells.EMPTY_SLOT)
        frees[button]:SetText(left and tostring(left) or "")
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

-- A strip button's icon and drawing (the tests).
function Foot.Parts(button)
    return iconOf[button], emptyOf[button], slotOf[button]
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

Foot.Deposits = Deposit

function Foot.Act()
    doing = Junk() and "junk" or nil
    if doing == "junk" then act.text:SetText(Core.Word("SELL_ALL_JUNK_ITEMS", "Sell All Junk Items")) end
    act:SetWidth(math.max(64, (act.text:GetStringWidth() or 0) + 32)) -- room for the red button's ends
    act:SetShown(doing ~= nil)
    ns.Bags.CountBefore(doing and act or nil)
end

-- The items still to sell, one at a time: { bag, slot, item, price } each; what was sold, for how much, and
-- what could not be.
local selling, sold, earned, unsold = {}, 0, 0, 0
local afterwards -- what comes once the selling is done (Foot.Sell)

local function Afterwards()
    local run = afterwards
    afterwards = nil
    if run then run() end
end
local AfterGame = Core.Later(function() ns.Guarded(Afterwards) end, Foot.SOLD)

local function Finish()
    for index = #selling, 1, -1 do selling[index] = nil end
    if sold > 0 then Core.Print(ns.TEXT.bagsSold:format(sold, Core.Coins(earned) or tostring(earned))) end
    if unsold > 0 then Core.Print(ns.TEXT.bagsUnsold:format(unsold)) end
    sold, earned, unsold = 0, 0, 0
    Afterwards()
end

-- The next item sold, if it is still where it was and the vendor still there; then the next, a moment later.
local Step
local function Next()
    local entry = table.remove(selling, 1)
    if not entry then return Finish() end
    if not Talking("Merchant") or InCombatLockdown() or Game("CursorHasItem") then
        unsold = unsold + 1 + #selling
        return Finish()
    end
    local api = Container()
    local info = Core.Ask(api.GetContainerItemInfo, entry.bag, entry.slot)
    if type(info) == "table" and Core.Plain(info.itemID) == entry.item and not Core.Plain(info.isLocked) then
        api.UseContainerItem(entry.bag, entry.slot)
        sold = sold + 1
        earned = earned + entry.price * (Core.Plain(info.stackCount) or 1)
    else
        unsold = unsold + 1
    end
    C_Timer.After(Foot.STEP, Step)
end
Step = ns.Guard(Next)

-- The junk sold, the bags read anew first (they may have changed while the question was open); after, if given,
-- once that is done, or at once with nothing to sell.
function Foot.Sell(after)
    if not Talking("Merchant") or #selling > 0 then return end
    afterwards = after
    local list, same = Contents.Junk(ns.Bags.Carried().slots, junk)
    if #list == 0 then return Afterwards() end
    local merchant = rawget(_G, "C_MerchantFrame")
    local game = merchant and merchant.SellAllJunkItems
        and not (merchant.IsSellAllJunkEnabled and Core.Ask(merchant.IsSellAllJunkEnabled) == false)
    if same and game then
        merchant.SellAllJunkItems()
        local worth = 0
        for _, record in ipairs(list) do worth = worth + (record.sell or 0) * (record.count or 1) end
        Core.Print(ns.TEXT.bagsSold:format(#list, Core.Coins(worth) or tostring(worth)))
        return AfterGame()
    end
    local api = Container()
    if not api.UseContainerItem or Game("CursorHasItem") then return Afterwards() end
    for _, record in ipairs(list) do
        selling[#selling + 1] = { bag = record.bag, slot = record.slot, item = record.item, price = record.sell or 0 }
    end
    Next()
end

local function Act()
    if doing == "junk" then
        Core.Confirm(Core.Word("SELL_ALL_JUNK_ITEMS_POPUP", Core.Word("SELL_ALL_JUNK_ITEMS", "Sell All Junk Items")), nil, Foot.Sell)
    end
end

-- The foot as wide as the window: the gold and the checkboxes with their words, the currencies where they fit too;
-- too narrow for that, the currencies go, then the boxes' words.
local function Fit()
    if not (room and gold) then return end
    local left = room - 2 * (ns.Bags.INSET + ns.Bags.EDGE) - (gold:GetWidth() or 0)
    local words = ns.Vendor.Width(true) <= left
    ns.Vendor.Words(words)
    left = left - ns.Vendor.Width(words)
    local wide = 0
    for _, token in ipairs(tokens) do
        if token.has then wide = wide + (token:GetWidth() or 0) + 2 * Foot.TOKEN_GAP end
    end
    for _, token in ipairs(tokens) do token:SetShown(token.has and wide <= left) end
end

-- The window's body is this wide.
function Foot.Room(width)
    room = width
    Fit()
end

-- The currencies watched in the backpack, at the foot's left.
function Foot.Tokens()
    local info = rawget(_G, "C_CurrencyInfo")
    local before
    for index = 1, Foot.TOKENS do
        local token = tokens[index]
        local data = info and info.GetBackpackCurrencyInfo and Core.Ask(info.GetBackpackCurrencyInfo, index)
        token.has = type(data) == "table" and Core.Plain(data.quantity) ~= nil
        if token.has then
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
    Fit()
end

local function TokenEnter(token)
    GameTooltip:SetOwner(token, "ANCHOR_TOP")
    if GameTooltip.SetBackpackToken then GameTooltip:SetBackpackToken(token:GetID()) end
    GameTooltip:Show()
end

function Foot.Gold()
    gold:SetText(Core.Coins(Core.Plain(Core.Ask(GetMoney)) or 0) or "")
    gold:SetWidth((gold.text:GetStringWidth() or 0) + 4)
    Fit()
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

Foot.GoldTip = GoldEnter -- the alts' gold says the same

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

-- The button on the title line: a pencil box on the paper, its box drawn stronger under the mouse.
local function ActLit(on)
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
    local ink = ns.Style.INK
    gold = Label(foot, font)
    gold.text:SetTextColor(ink[1], ink[2], ink[3])
    gold:SetPoint("RIGHT", -(ns.Bags.INSET + ns.Bags.EDGE), 0)
    gold:SetScript("OnEnter", function(self) ns.Safe("bags", GoldEnter, self) end)
    gold:SetScript("OnLeave", GameTooltip_Hide)
    ns.Vendor.Build(foot, gold)
    tokens = {}
    for index = 1, Foot.TOKENS do
        local token = Label(foot, font)
        token:SetID(index)
        token.text:SetTextColor(ink[1], ink[2], ink[3])
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
    act:SetHeight(ns.Bags.BAR)
    act:SetPoint("RIGHT", beside, "LEFT", -ns.Bags.BAR_GAP, 0)
    act.text = act:CreateFontString(nil, "ARTWORK")
    ns.Style.Red(act, act.text, ns.Bags.BAR) -- the game's red button: what can be done here matters
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
    ns.Vendor.Refresh()
end
