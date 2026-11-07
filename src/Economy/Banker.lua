local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Economy - Banker
--  The tab Banker on the game's mail window, in the game's own look, and open
--  first (the option Open on Banker):
--
--      To: [ Droopy Fairwind            ]
--          Remembered for your Alliance characters on Argent Dawn
--      [x] [] Linen Cloth x47                         3 stacks
--      [x] [] Copper Ore x20
--      [ ] [] Holy Candle x5                     stays with you
--      14 stacks in 2 mails                          [ Send ]
--
--  What goes (Banker.Goods): every trade good and reagent in the bags (the
--  game's item classes Trade Goods and Reagent, as the bags' category Trade
--  Goods), not bound and not locked. An item unticked stays with you at every
--  mailbox until it is ticked again (store.kept, by item ID, for the account).
--  The banker's name is kept for the account, one per realm and faction
--  (store.bankers), since mail goes only to a character of both.
--
--  Send puts the stacks into mails of ATTACHMENTS_MAX_SEND each, by the game's
--  own calls (PickupContainerItem, ClickSendMailItemButton, SendMail): the
--  first on the click, each next one when the game says the last went
--  (MAIL_SEND_SUCCESS), until nothing is left. A mail the game refuses
--  (MAIL_FAILED) gets its items back into the bags and the game's reason on the
--  line (its UI_ERROR_MESSAGE). One the game neither sends nor refuses within
--  WAIT seconds (a question of the game's still open, a send it held back)
--  leaves the button to the player: Send again tries that mail once more.
--
--  It does not open first on the banker itself, nor when a banker is named and
--  nothing would go to it: then the inbox is what is wanted.
--
--  Nothing is written into the game's window, as with Deals (Tab.lua): our page
--  covers its page, our tab stands after its tabs and marks them as not chosen
--  with the game's own calls while ours is, and a hook on MailFrameTab_OnClick
--  tells when it wants its page back (its tabs, a reply, the window opened).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Ask = Core.Ask
local Banker = {}
ns.Banker = Banker

local TEXT, SIZE = ns.TEXT, ns.SIZE.banker
local CLASS = Enum and Enum.ItemClass or {}
local GOODS = { [CLASS.Tradegoods or 7] = true, [CLASS.Reagent or 5] = true } -- the game's item classes that go
local SOFT = { 0.7, 0.7, 0.7 }  -- small words, and what stays
local WAIT = 10                 -- seconds a mail may take before the button is the player's again
local STEP = 0.5                -- seconds after a mail went before the next is put together: the bags catch up
local LETTERS = 77              -- the most a name may have, as in the game's own box for it
local BASE_LEVEL = 100          -- our page over the game's pages, under its portrait and border

local page, tab, box, empty, nameBox, note, summary, status, send
-- The mails going out: { name, sent, total, busy, at, error, attached = { [slot] = true }, skip = { ["bag:slot"] = true } }
local run = nil
local given = false

local function Now()
    return Ask(rawget(_G, "GetTime")) or 0
end

local function Many(count, words)
    return ("%d %s"):format(count, count == 1 and words[1] or words[2])
end

-------------------------------------------------------------------------------
--  What is kept: the bankers by realm and faction, the items kept back
-------------------------------------------------------------------------------
local function Store()
    local store = ns.store
    if type(store.bankers) ~= "table" then store.bankers = {} end
    if type(store.kept) ~= "table" then store.kept = {} end
    return store
end

-- Where a banker serves, as a key, and the realm's and faction's names to show.
local function Place()
    local realm = Ask(rawget(_G, "GetNormalizedRealmName")) or "?"
    local side, sideName = Ask(UnitFactionGroup, "player")
    return realm .. "|" .. (side or "?"), Ask(rawget(_G, "GetRealmName")) or realm, sideName or side or ""
end

local function Trim(text)
    return type(text) == "string" and text:match("^%s*(.-)%s*$") or ""
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

-- Whether a name is the character you play: on Forever its whole name, elsewhere its name with or without the realm.
function Banker.IsMe(name)
    local mine = Core.FullName("player")
    if type(name) ~= "string" or not mine then return false end
    name = name:lower()
    if mine:lower() == name then return true end
    local realm = Ask(rawget(_G, "GetNormalizedRealmName"))
    return not Core.Surnames() and realm ~= nil and (mine .. "-" .. realm):lower() == name
end

-- Whether an item stays with you.
function Banker.Kept(id)
    return Store().kept[id] == true
end

function Banker.Keep(id, keep)
    Store().kept[id] = keep and true or nil
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

-- The bags carried: the backpack, the bags, the reagent bag where there is one.
local function LastBag()
    local constants = Constants and Constants.InventoryConstants or {}
    return (constants.NumBagSlots or rawget(_G, "NUM_BAG_SLOTS") or 4) + (constants.NumReagentBagSlots or 0)
end

-- The trade goods and reagents in the bags: the lines to show, one an item ({ id, count, stacks, kept, link }), and
-- the stacks that go ({ bag, slot, id }), both in the bags' order.
function Banker.Goods()
    local lines, stacks, seen = {}, {}, {}
    local container = C_Container
    if not (container and container.GetContainerItemInfo) then return lines, stacks end
    for bag = 0, LastBag() do
        for slot = 1, Ask(container.GetContainerNumSlots, bag) or 0 do
            local info = Ask(container.GetContainerItemInfo, bag, slot)
            local id = type(info) == "table" and Core.Plain(info.itemID)
            if id and not Core.Plain(info.isBound) and not Core.Plain(info.isLocked) and GOODS[Class(id)] then
                local line = seen[id]
                if not line then
                    line = { id = id, count = 0, stacks = 0, kept = Banker.Kept(id), link = Core.Plain(info.hyperlink) }
                    seen[id], lines[#lines + 1] = line, line
                end
                line.count, line.stacks = line.count + (Core.Plain(info.stackCount) or 1), line.stacks + 1
                if not line.kept then stacks[#stacks + 1] = { bag = bag, slot = slot, id = id } end
            end
        end
    end
    return lines, stacks
end

-------------------------------------------------------------------------------
--  Sending
-------------------------------------------------------------------------------
local function Max()
    return rawget(_G, "ATTACHMENTS_MAX_SEND") or 12
end

local function Mails(stacks)
    return math.ceil(stacks / Max())
end

local function Has(slot)
    return Ask(rawget(_G, "HasSendMailItem"), slot) == true
end

local function Cursor()
    return Ask(rawget(_G, "GetCursorInfo"))
end

local Draw

local function Say(word)
    if status then status:SetText(word or "") end
end

local function Stop(word)
    run = nil
    Say(word)
    Draw()
end

-- Our items out of the mail and back into the bags, as the game's right click on an attachment does.
local function Unattach()
    if not run then return end
    for slot in pairs(run.attached) do
        if Has(slot) then Ask(rawget(_G, "ClickSendMailItemButton"), slot, true) end
    end
    run.attached = {}
end

-- Up to a mail's worth of stacks into the mail, each as the game does it: picked up, put on an attachment. A stack the
-- game will not take goes back from the cursor into its bag, and is not tried again in this run.
local function Attach(stacks)
    local pick, put = C_Container.PickupContainerItem, rawget(_G, "ClickSendMailItemButton")
    local slot = 0
    for _, stack in ipairs(stacks) do
        if slot >= Max() then break end
        Ask(pick, stack.bag, stack.slot)
        if Cursor() == "item" then
            Ask(put, slot + 1)
            if Cursor() then
                Ask(rawget(_G, "ClearCursor"))
                run.skip[stack.bag .. ":" .. stack.slot] = true
            else
                slot = slot + 1
                run.attached[slot] = true
            end
        end
    end
end

-- The stacks that go and are still to be tried in this run.
local function Left()
    local _, stacks = Banker.Goods()
    local left = {}
    for _, stack in ipairs(stacks) do
        if not run.skip[stack.bag .. ":" .. stack.slot] then left[#left + 1] = stack end
    end
    return left
end

local Overdue -- a mail that takes too long (below)

-- After a mail went the game puts the keys into its own box for a name (SendMailFrame_Reset), hidden under our page:
-- they are let go, or typing would end up there.
local function Unfocus()
    local theirs = rawget(_G, "SendMailNameEditBox")
    if theirs and theirs:HasFocus() and not theirs:IsVisible() then theirs:ClearFocus() end
end

-- The next mail: put together (or the one already in the mail again, after Send again) and sent.
local function Next()
    if not run then return end
    Unfocus()
    if ns.off or not (page and page:IsShown()) then
        Unattach()
        run = nil
        return
    end
    if next(run.attached) == nil then
        if Cursor() then return Stop(TEXT.bankerCursor) end
        for slot = 1, Max() do
            if Has(slot) then return Stop(TEXT.bankerAttached) end
        end
        local stacks = Left()
        if #stacks > 0 then
            run.total = run.sent + Mails(#stacks)
            Attach(stacks)
        end
        if next(run.attached) == nil then -- all gone, or what is left the game will not take
            local word = #stacks > 0 and TEXT.bankerNone or nil
            if run.sent > 0 then word = TEXT.bankerSent:format(run.name, Many(run.sent, TEXT.bankerMail)) end
            return Stop(word)
        end
    end
    local price = Ask(rawget(_G, "GetSendMailPrice")) or 0
    if price > (Ask(GetMoney) or 0) then
        Unattach()
        return Stop(TEXT.bankerPostage:format(Core.Coins(price) or ""))
    end
    local subject = TEXT.bankerSubject
    if run.total > 1 then subject = TEXT.bankerOf:format(subject, run.sent + 1, run.total) end
    run.busy, run.error, run.at = true, nil, Now()
    Ask(rawget(_G, "SendMail"), run.name, subject, "")
    Overdue()
    Draw()
end
local NextSoon = Core.Later(Next, STEP)

-- Looked at each second while a mail is on its way: one that has neither gone nor been refused in WAIT seconds leaves
-- the button to the player again (Send again).
local function Late()
    if not (run and run.busy) then return end
    if Now() - run.at < WAIT then return Overdue() end
    run.busy = false
    Say(TEXT.bankerSlow)
    Draw()
end
Overdue = Core.Later(Late, 1)

-- The button: the first mail on the click, the others as each went.
local function Send()
    if ns.off or (run and run.busy) then return end
    local name = Banker.Name()
    if not name or Banker.IsMe(name) then return end
    if nameBox:HasFocus() then nameBox:ClearFocus() end
    if run then
        run.name = name
    else
        run = { name = name, sent = 0, total = 0, attached = {}, skip = {} }
    end
    Say("")
    Next()
end

local function Sent()
    if not run then return Draw() end
    run.sent, run.busy, run.attached = run.sent + 1, false, {}
    Draw()
    NextSoon()
end

local function Failed()
    if not (run and run.busy) then return end
    local why = run.error
    Unattach()
    Stop(why and TEXT.bankerRefused:format(why) or TEXT.bankerFailed)
end

-- What the game says is wrong while a mail of ours is on its way: the reason it is refused (no such player, ...).
local function Refused(_, message)
    if run and run.busy and type(message) == "string" then run.error = message end
end

-------------------------------------------------------------------------------
--  A line
-------------------------------------------------------------------------------
local function Toggle(tick)
    local row = tick:GetParent()
    if not row.line then return end
    Banker.Keep(row.line.id, not tick:GetChecked())
    Core.Sound(tick:GetChecked() and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    Draw()
end

local function Enter(row)
    local line = row.line
    if not line then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if line.link then GameTooltip:SetHyperlink(line.link) else GameTooltip:SetItemByID(line.id) end
    GameTooltip:Show()
end

local function Leave()
    GameTooltip:Hide()
end

local function Make(row)
    row:SetHeight(SIZE.row)
    row:EnableMouse(true)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.tick = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.tick:SetSize(SIZE.tick, SIZE.tick)
    row.tick:SetPoint("LEFT", 2, 0)
    row.tick:SetScript("OnClick", ns.Guard(Toggle))
    Core.Tip(row.tick, TEXT.bankerTick, TEXT.bankerTickTip)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(SIZE.icon, SIZE.icon)
    row.icon:SetPoint("LEFT", row.tick, "RIGHT", 4, 0)
    row.note = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.note:SetPoint("RIGHT", -6, 0)
    row.note:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT", row.note, "LEFT", -6, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row:SetScript("OnClick", ns.Guard(function(self) self.tick:Click() end))
    row:SetScript("OnEnter", ns.Guard(Enter))
    row:SetScript("OnLeave", ns.Guard(Leave))
    row.made = true
end

local function Fill(row, line)
    if not row.made then Make(row) end
    row.line = line
    row.icon:SetTexture(Ask(C_Item.GetItemIconByID, line.id))
    row.icon:SetDesaturated(line.kept)
    local name = ns.NameOf(line.id)
    row.name:SetText(line.count > 1 and ("%s x%d"):format(name, line.count) or name)
    if line.kept then row.name:SetTextColor(SOFT[1], SOFT[2], SOFT[3]) else row.name:SetTextColor(ns.Color(line.id)) end
    row.note:SetText(line.kept and TEXT.bankerStays or (line.stacks > 1 and TEXT.bankerStacks:format(line.stacks)) or "")
    row.tick:SetChecked(not line.kept)
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
Draw = function()
    if not (page and page:IsShown()) then return end
    local lines, stacks = Banker.Goods()
    box:SetDataProvider(CreateDataProvider(lines), ScrollBoxConstants.RetainScrollPosition)
    empty:SetText(TEXT.bankerNothing)
    empty:SetShown(#lines == 0)
    local name = Banker.Name()
    local me = name and Banker.IsMe(name)
    local _, realm, side = Place()
    note:SetText((not name and TEXT.bankerNoName) or (me and TEXT.bankerMe) or TEXT.bankerKept:format(side, realm))
    summary:SetText(#stacks > 0 and TEXT.bankerCount:format(Many(#stacks, TEXT.bankerOne), Many(Mails(#stacks), TEXT.bankerMail)) or "")
    local word, on = TEXT.bankerSend, #stacks > 0
    if run and run.busy then
        word, on = TEXT.bankerSending, false
    elseif run then
        word, on = TEXT.bankerAgain, true
    end
    send:SetText(word)
    send:SetEnabled(on and name ~= nil and not me)
end
local DrawSoon = Core.Later(Draw, 0.1)

local function Typed(self, byPlayer)
    if not byPlayer then return end
    Banker.SetName(self:GetText())
    DrawSoon()
end

local function Open()
    if ns.off or not page then return end
    local window = MailFrame
    page:Show()
    local tabs = type(window.Tabs) == "table" and window.Tabs or {} -- the game's mail window names its tabs instead
    for index = 1, tonumber(window.numTabs) or 2 do
        local each = tabs[index] or rawget(_G, "MailFrameTab" .. index)
        if each then PanelTemplates_DeselectTab(each) end
    end
    PanelTemplates_SelectTab(tab)
    window:SetTitle(TEXT.banker)
    nameBox:SetText(Banker.Name() or "")
    Say("")
    Draw()
end

-- The game wants its page back: ours goes, a mail of ours still in the mail back into the bags.
local function Close()
    if not (page and page:IsShown()) then return end
    page:Hide()
    PanelTemplates_DeselectTab(tab)
    PanelTemplates_UpdateTabs(MailFrame)
    if nameBox:HasFocus() then nameBox:ClearFocus() end
    if run and not run.busy then
        Unattach()
        run = nil
    end
end

-- The mailbox closed: the game gives back what was in the mail itself.
local function Closed()
    run = nil
    if nameBox and nameBox:HasFocus() then nameBox:ClearFocus() end
end

local function Build()
    if page or given then return end
    local window, after = rawget(_G, "MailFrame"), rawget(_G, "MailFrameTab2")
    if not (window and after) then return end
    page = CreateFrame("Frame", nil, window)
    page:SetPoint("TOPLEFT", window, "TOPLEFT", SIZE.left, -SIZE.top)
    page:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -SIZE.right, SIZE.bottom)
    page:SetFrameLevel(window:GetFrameLevel() + BASE_LEVEL)
    page:EnableMouse(true)
    local ground = page:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(page)
    ground:SetColorTexture(0, 0, 0, 1)

    -- The banker's name, right of the window's round portrait
    nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    nameBox:SetSize(SIZE.box, SIZE.boxHigh)
    nameBox:SetPoint("TOPLEFT", page, "TOPLEFT", SIZE.portrait + SIZE.label, -8)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(LETTERS)
    nameBox:HookScript("OnTextChanged", ns.Guard(Typed))
    nameBox:SetScript("OnEnterPressed", ns.Guard(function(self) self:ClearFocus() end))
    local label = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("RIGHT", nameBox, "LEFT", -10, 0)
    label:SetText(TEXT.bankerTo)
    note = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", -4, -4)
    note:SetPoint("RIGHT", page, "RIGHT", -6, 0)
    note:SetJustifyH("LEFT")
    note:SetTextColor(SOFT[1], SOFT[2], SOFT[3])

    -- The list
    local inset = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -SIZE.head)
    inset:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, SIZE.foot)
    box = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", inset, "TOPLEFT", 3, -4)
    box:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -ns.SIZE.scrollbar, 4)
    local bar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 3, -2)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 3, 2)
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(SIZE.row)
    view:SetElementInitializer("Button", ns.Guard(Fill))
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    empty = inset:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    empty:SetPoint("TOPLEFT", inset, "TOPLEFT", 16, -16)
    empty:SetPoint("RIGHT", inset, "RIGHT", -16, 0)
    empty:SetJustifyH("LEFT")

    -- The foot: how much goes, what happened, the button
    send = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    send:SetSize(SIZE.button, SIZE.buttonHigh)
    send:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -2, 6)
    send:SetScript("OnClick", ns.Guard(Send))
    summary = page:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    summary:SetPoint("TOPLEFT", inset, "BOTTOMLEFT", 6, -4)
    summary:SetPoint("RIGHT", send, "LEFT", -8, 0)
    status = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -3)
    status:SetPoint("RIGHT", send, "LEFT", -8, 0)
    for _, words in ipairs({ summary, status }) do
        words:SetJustifyH("LEFT")
        words:SetWordWrap(false)
    end
    page:Hide()

    -- The game's tab template joins its parent's list of tabs: its parent is a frame of ours, not the game's window.
    local holder = CreateFrame("Frame", nil, window)
    holder:SetAllPoints(window)
    tab = CreateFrame("Button", nil, holder, "PanelTabButtonTemplate")
    tab:SetText(TEXT.banker)
    tab:SetPoint("LEFT", after, "RIGHT", -8, 0)
    PanelTemplates_TabResize(tab)
    PanelTemplates_DeselectTab(tab)
    tab:SetScript("OnClick", ns.Guard(function()
        Core.Sound("IG_SPELLBOOK_OPEN")
        Open()
    end))

    hooksecurefunc("MailFrameTab_OnClick", ns.Guard(Close))
end

-- The mailbox opened: on Banker, unless you play the banker, or a banker is named and nothing would go to it.
local function Shown()
    Build()
    if ns.off or not page or not ns.options.bankerFirst then return end
    local name = Banker.Name()
    if name and Banker.IsMe(name) then return end
    local _, stacks = Banker.Goods()
    if name and #stacks == 0 then return end
    Open()
end
local ShownSoon = Core.Later(Shown)

function Banker.Start()
    Core.On("MAIL_SHOW", ns.Guard(ShownSoon))
    Core.On("MAIL_CLOSED", ns.Guard(Closed))
    Core.On("MAIL_SEND_SUCCESS", ns.Guard(Sent))
    Core.On("MAIL_FAILED", ns.Guard(Failed))
    Core.On("UI_ERROR_MESSAGE", ns.Guard(Refused))
    Core.On("BAG_UPDATE_DELAYED", ns.Guard(DrawSoon))
end

-- The window as the game made it: our tab and page gone, a mail of ours back into the bags.
function Banker.GiveBack()
    given = true
    Unattach()
    run = nil
    if page then
        Close()
        page:Hide()
    end
    if tab then tab:Hide() end
end
