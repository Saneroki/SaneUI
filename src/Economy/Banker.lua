local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Economy - Banker
--  Send to banker: a tick on the game's Send Mail tab, right of the window's
--  tabs (Saneroki, 2026-11-11; in the place of the tab Banker of 2026-11-07):
--
--      [ Inbox ][ Send Mail ]  [x] Send to banker   1 more mail
--
--  Ticked, the mailbox opens on Send Mail, its To: holds your banker, its
--  subject today's date, and every trade good, reagent, recipe, waylaid crate
--  and writ in the bags that is not soulbound is on the mail: press Send. A mail holds
--  ATTACHMENTS_MAX_SEND stacks; when one went (MAIL_SEND_SUCCESS, after which
--  the game empties its boxes) the next is filled in the same way, for the next
--  press. Unticked, what we put there comes off again, and the tab is the
--  game's as ever.
--
--  The banker is the name in To: while the tick is on (typed there once),
--  kept for the account per realm and faction (store.bankers), since mail goes
--  only to a character of both; the tick too (store.toBanker). On the banker
--  itself, and with nothing to go, the mailbox opens on the inbox as ever.
--
--  What goes (Banker.Goods): the item classes Trade Goods and Reagent (the
--  bags' category Trade Goods), Recipe and Profession (its category
--  Professions: recipes, patterns, plans; Saneroki, 2026-11-09, again on
--  2026-11-11: "Yes, send them"), and Forever's crafting orders, told by the
--  game's English names (Sane UI's clients are English): "Waylaid Crate",
--  "Waylaid Crate: Journeyman Ore", "Waylaid Supplies: Copper Bars", "Sealed
--  Apprentice's Writ", "Craftsman's Writ: Wizardweave Turban"; never what is
--  bound or locked, never a quest item.
--
--  Send by itself (the option bankerAuto, on in the profile Speedleveling:
--  Core's Presets.lua; Saneroki, 2026-11-09): with the tick on, the mail goes
--  as the mailbox opens, each next one as the last went, until nothing is left
--  or the game refuses one. Shift held as the mailbox opens leaves it to you.
--
--  The game's window stays the game's: the tick is a frame of ours on its Send
--  Mail page; what is filled in is what a player types and drags (its boxes'
--  SetText; C_Container.PickupContainerItem, then ClickSendMailItemButton into
--  a free slot only), and its own button sends. A hook on MailFrameTab_OnClick
--  tells when Send Mail opens; a reply (SendMailFrame.sendMode "reply", set
--  right after the game opens the tab for it) gets nothing of ours.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Ask = Core.Ask
local Banker = {}
ns.Banker = Banker

local TEXT, SIZE = ns.TEXT, ns.SIZE.banker
local CLASS = Enum and Enum.ItemClass or {}
-- The game's item classes that go: the bags' categories Trade Goods and Professions (Forever has no item of the class
-- Profession; its profession items are the recipes).
local GOODS = { [CLASS.Tradegoods or 7] = true, [CLASS.Reagent or 5] = true, [CLASS.Recipe or 9] = true,
                [CLASS.Profession or 19] = true }
local QUEST = CLASS.Questitem or 12
local ORDERS = { "^Waylaid ", "Writ$", "Writ[:%s%-]" } -- the crafting orders' names: crates, supplies, writs
local STEP = 0.5        -- seconds after a change before the mail is filled in: the bags and the game's boxes catch up
local LETTERS = 77      -- the most a name may have, as in the game's own box for it

local tick, more
local ours = {}         -- [slot] = true: what we put on the mail
local wrote = {}        -- what we wrote into the game's boxes: { name, subject }
local auto = false      -- Send by itself, for this visit to the mailbox
local sending = false   -- a mail Send by itself sent is on its way: no second one until the game answers
local given = false

local function Trim(text)
    return type(text) == "string" and text:match("^%s*(.-)%s*$") or ""
end

local function Box(name)
    return rawget(_G, name)
end

-------------------------------------------------------------------------------
--  What is kept: the banker and the tick, by realm and faction
-------------------------------------------------------------------------------
local function Store()
    local store = ns.store
    if type(store.bankers) ~= "table" then store.bankers = {} end
    if type(store.toBanker) ~= "table" then store.toBanker = {} end
    return store
end

-- Where a banker serves, as a key, and the realm's and faction's names to show.
local function Place()
    local realm = Ask(rawget(_G, "GetNormalizedRealmName")) or "?"
    local side, sideName = Ask(UnitFactionGroup, "player")
    return realm .. "|" .. (side or "?"), Ask(rawget(_G, "GetRealmName")) or realm, sideName or side or ""
end

-- The banker of the realm and faction you play: a name, or nil.
function Banker.Name()
    local name = Trim(Store().bankers[(Place())])
    return name ~= "" and name or nil
end

function Banker.SetName(name)
    name = Trim(name):sub(1, LETTERS)
    Store().bankers[(Place())] = name ~= "" and name or nil
end

-- Whether the tick is on, for the realm and faction you play.
function Banker.On()
    return Store().toBanker[(Place())] == true
end

function Banker.SetOn(on)
    Store().toBanker[(Place())] = on and true or nil
end

-- Whether a name is the character you play: on Forever its whole name, elsewhere its name with or without the realm.
function Banker.IsMe(name)
    local mine = Core.FullName("player")
    if type(name) ~= "string" or not mine then return false end
    name = name:lower()
    if mine:lower() == name then return true end
    local realm = Ask(rawget(_G, "GetNormalizedRealmName"))
    return not Core.Surnames() and realm ~= nil and (mine .. "-" .. realm):lower() == name
end

-- The banker to fill in now: named, and not the character you play.
local function Target()
    local name = Banker.Name()
    if name and not Banker.IsMe(name) then return name end
    return nil
end

-------------------------------------------------------------------------------
--  What goes
-------------------------------------------------------------------------------
local function Class(id)
    local items = C_Item
    if not (items and items.GetItemInfoInstant) then return nil end
    local ok, _, _, _, _, _, class = pcall(items.GetItemInfoInstant, id)
    return ok and Core.Plain(class) or nil
end

-- A crafting order of Forever's: a waylaid crate or supplies, a writ.
local function Order(name)
    if type(name) ~= "string" then return false end
    for _, pattern in ipairs(ORDERS) do
        if name:find(pattern) then return true end
    end
    return false
end

local function Goes(info, id)
    if Core.Plain(info.isBound) or Core.Plain(info.isLocked) then return false end
    local class = Class(id)
    if GOODS[class] then return true end
    if class == QUEST then return false end
    return Order(Core.Plain(info.itemName) or Ask(C_Item.GetItemNameByID, id))
end

-- The bags carried: the backpack, the bags, the reagent bag where there is one.
local function LastBag()
    local constants = Constants and Constants.InventoryConstants or {}
    return (constants.NumBagSlots or rawget(_G, "NUM_BAG_SLOTS") or 4) + (constants.NumReagentBagSlots or 0)
end

-- The stacks in the bags that go to the banker and are not on a mail yet: { { bag, slot, id }, ... }, in the bags' order.
function Banker.Goods()
    local stacks = {}
    local container = C_Container
    if not (container and container.GetContainerItemInfo) then return stacks end
    for bag = 0, LastBag() do
        for slot = 1, Ask(container.GetContainerNumSlots, bag) or 0 do
            local info = Ask(container.GetContainerItemInfo, bag, slot)
            local id = type(info) == "table" and Core.Plain(info.itemID)
            if id and Goes(info, id) then stacks[#stacks + 1] = { bag = bag, slot = slot, id = id } end
        end
    end
    return stacks
end

-------------------------------------------------------------------------------
--  The mail
-------------------------------------------------------------------------------
local function Max()
    return rawget(_G, "ATTACHMENTS_MAX_SEND") or 12
end

local function Has(slot)
    return Ask(rawget(_G, "HasSendMailItem"), slot) == true
end

local function Cursor()
    return Ask(rawget(_G, "GetCursorInfo"))
end

-- Whether the game's Send Mail page shows a mail of the player's own writing (not a reply).
local function Showing()
    local page = Box("SendMailFrame")
    return page ~= nil and Core.Plain(page:IsVisible()) == true and page.sendMode ~= "reply"
end

-- What stands beside the tick: how many more mails it takes after this one.
local function Count()
    if not more then return end
    local left = Banker.On() and Target() and #Banker.Goods() or 0
    local mails = math.ceil(left / Max())
    more:SetText(mails > 0 and TEXT.bankerMore:format(mails, mails == 1 and TEXT.bankerMail[1] or TEXT.bankerMail[2]) or "")
end

-- Stacks into the mail's free slots, each as a player does it: picked up, put on an attachment. A stack the game will not
-- take goes back from the cursor into its bag.
local function Attach(stacks)
    local pick, put = C_Container.PickupContainerItem, Box("ClickSendMailItemButton")
    local slot, index = 1, 1
    while slot <= Max() and index <= #stacks do
        if Has(slot) then
            slot = slot + 1
        else
            local stack = stacks[index]
            index = index + 1
            Ask(pick, stack.bag, stack.slot)
            if Cursor() == "item" then
                Ask(put, slot)
                if Cursor() then
                    Ask(Box("ClearCursor"))
                else
                    ours[slot] = true
                    slot = slot + 1
                end
            end
        end
    end
end

-- What we put on the mail and into its boxes taken off again: the items back into the bags, our words out of the boxes.
local function Unfill()
    for slot in pairs(ours) do
        if Has(slot) then Ask(Box("ClickSendMailItemButton"), slot, true) end
    end
    ours = {}
    local to, subject = Box("SendMailNameEditBox"), Box("SendMailSubjectEditBox")
    if to and wrote.name and to:GetText() == wrote.name then to:SetText("") end
    if subject and wrote.subject and subject:GetText() == wrote.subject then subject:SetText("") end
    wrote = {}
end

-- Send by itself: the mail as filled in, sent as the game's Send does (its button waits until the game answers).
local function SendNow()
    if sending or not (auto and next(ours) and Showing()) or ns.off then return end
    local to, subject, body = Box("SendMailNameEditBox"), Box("SendMailSubjectEditBox"), Box("SendMailBodyEditBox")
    if not (to and subject) then return end
    if (Ask(Box("GetSendMailPrice")) or 0) > (Ask(GetMoney) or 0) then
        auto = false -- too little for the postage: the game's own shows it in red
        return
    end
    local button = Box("SendMailMailButton")
    if button then button:Disable() end
    sending = true
    Ask(Box("SendMail"), to:GetText(), subject:GetText(), body and body:GetText() or "")
end

-- The mail to the banker filled in, where the tick is on and the player writes on Send Mail: the stacks into the free
-- slots, then To: and the subject where they are empty. Nothing to go: nothing is touched.
local function Fill()
    if ns.off or not Banker.On() or not Showing() then return Count() end
    local name = Target()
    local to, subject = Box("SendMailNameEditBox"), Box("SendMailSubjectEditBox")
    if not (name and to and subject) then return Count() end
    local stacks = Banker.Goods()
    if #stacks > 0 and not Cursor() then Attach(stacks) end
    if next(ours) then
        if Trim(to:GetText()) == "" then
            to:SetText(name)
            wrote.name = name
        end
        if Trim(subject:GetText()) == "" then
            wrote.subject = date(TEXT.bankerDate)
            subject:SetText(wrote.subject)
        end
    end
    Count()
    SendNow()
end
local FillSoon = Core.Later(Fill, STEP)

-------------------------------------------------------------------------------
--  The tick
-------------------------------------------------------------------------------
local function Tip()
    local _, realm, side = Place()
    local name = Banker.Name()
    if name and Banker.IsMe(name) then return TEXT.bankerTip .. "\n\n" .. TEXT.bankerMe end
    if name then return TEXT.bankerTip .. "\n\n" .. TEXT.bankerWho:format(name, side, realm) end
    return TEXT.bankerTip .. "\n\n" .. TEXT.bankerNone:format(side, realm)
end

local function Ticked(box)
    local on = box:GetChecked() and true or false
    Core.Sound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    Banker.SetOn(on)
    if on then
        local to = Box("SendMailNameEditBox")
        local typed = to and Trim(to:GetText()) or ""
        if typed ~= "" and not Banker.IsMe(typed) then Banker.SetName(typed) end
        Fill()
    else
        auto = false
        Unfill()
        Count()
    end
end

-- A name typed into To: while the tick is on is the banker; the mail is filled in once it stands there.
local function Typed(box, byPlayer)
    if not byPlayer or ns.off or not Banker.On() then return end
    local name = Trim(box:GetText())
    if name ~= "" and not Banker.IsMe(name) then Banker.SetName(name) end
    FillSoon()
end

-- The game opened Send Mail (its tab, a reply, our own open): filled in a moment later, once a reply has said it is one.
-- It left it (the inbox, the mailbox's own open): ours comes off, or a reply from the inbox would carry it.
local function Tabbed(_, id)
    if id == 2 then
        FillSoon()
    elseif not sending then
        Unfill()
    end
end

local function Build()
    if tick or given then return end
    local page, after = Box("SendMailFrame"), Box("MailFrameTab2")
    local to = Box("SendMailNameEditBox")
    if not (page and after and to and Box("MailFrameTab_OnClick")) then return end
    tick = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    tick:SetSize(SIZE.tick, SIZE.tick)
    tick:SetPoint("LEFT", after, "RIGHT", SIZE.gap, SIZE.lift)
    tick:SetScript("OnClick", ns.Guard(Ticked))
    local label = tick.Text -- the template's own label, the game's small font right of the box
    if not label then
        label = tick:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", tick, "RIGHT", 2, 0)
    end
    label:SetText(TEXT.banker)
    more = tick:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    more:SetPoint("LEFT", label, "RIGHT", 8, 0)
    Core.Tip(tick, TEXT.banker, Tip)
    tick:SetChecked(Banker.On())
    to:HookScript("OnTextChanged", ns.Guard(Typed))
    hooksecurefunc("MailFrameTab_OnClick", ns.Guard(Tabbed))
end

-- The mailbox opened: with the tick on, a banker to send to and something to go, on Send Mail, filled in (and sent, with
-- Send by itself and Shift not held).
local function Shown()
    Build()
    if ns.off or not tick then return end
    tick:SetChecked(Banker.On())
    ours, wrote, auto, sending = {}, {}, false, false
    Count()
    if not (Banker.On() and Target()) or #Banker.Goods() == 0 then return end
    local tab = Box("MailFrameTab2")
    if not (tab and Core.Plain(tab:IsShown()) == true) then return end -- a trial account sends no mail
    auto = ns.options.bankerAuto and not Ask(Box("IsShiftKeyDown")) or false
    MailFrameTab_OnClick(nil, 2) -- as the game's own Reply opens it
    Fill()
end
local ShownSoon = Core.Later(Shown)

-- A mail went: the game has emptied its boxes; the next one is filled in.
local function Sent()
    ours, wrote, sending = {}, {}, false
    if Banker.On() then FillSoon() else Count() end
end

-- The game refused a mail: Send by itself stops; the mail stays as it was, for the player to see why.
local function Failed()
    auto, sending = false, false
end

-- What came off the mail by the player's hand is no longer ours.
local function Changed()
    for slot in pairs(ours) do
        if not Has(slot) then ours[slot] = nil end
    end
end

local function Closed()
    ours, wrote, auto, sending = {}, {}, false, false
end

function Banker.Start()
    Core.On("MAIL_SHOW", ns.Guard(ShownSoon))
    Core.On("MAIL_CLOSED", ns.Guard(Closed))
    Core.On("MAIL_SEND_SUCCESS", ns.Guard(Sent))
    Core.On("MAIL_FAILED", ns.Guard(Failed))
    Core.On("MAIL_SEND_INFO_UPDATE", ns.Guard(Changed))
    Core.On("BAG_UPDATE_DELAYED", ns.Guard(Count))
end

-- The window as the game made it: the tick gone, what we put on the mail back into the bags.
function Banker.GiveBack()
    given, auto, sending = true, false, false
    Unfill()
    if tick then tick:Hide() end
end
