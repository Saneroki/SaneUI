local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Split
--  Splitting a stack: Shift and a click on a stack opens this little dialog
--  in place of the game's (always in the views that show no empty slots:
--  there the game's split would have nowhere to go; in the others when the
--  setting Stack Splitter Everywhere is on). How many: typed, or by - and +,
--  or the mouse wheel, of the stack's count. Split: that many put into the
--  first free slot of the bags (Enter does it). Auto Split: the stack split
--  into stacks of that many, one after the other, each into a free slot,
--  until what is left is no more than that many or no slot is free (Alt and
--  Enter). Each split waits for the game to have done the one before (the
--  slot unlocked, at most Split.LONGEST seconds). An item split stays apart
--  from its other stacks until the window closes (Views.split).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Split = {}
ns.Split = Split

Split.WIDTH, Split.HEIGHT = 206, 94
Split.WAIT = 0.05     -- seconds between two looks at the stack split from
Split.LONGEST = 2     -- the longest wait for one split
Split.BACK = { 0.067, 0.067, 0.067, 0.95 }
Split.EDGE = { 0.2, 0.2, 0.2, 1 }

local Contents = ns.Contents
local dialog, box, most
local source         -- { bag, slot, item } the stack split from
local auto           -- an auto split under way: { amount, started }

local function Container()
    return rawget(_G, "C_Container") or {}
end

-- The first free slot of the ordinary bags (not the reagent bag, not a bag for one kind of item).
local function Free()
    local api = Container()
    for _, bag in ipairs(Contents.Carried({})) do
        local _, family = Core.Ask(api.GetContainerNumFreeSlots, bag)
        if bag ~= Contents.KEYRING and not Contents.Reagent(bag) and (Core.Plain(family) or 0) == 0 then
            for slot = 1, Contents.Size(bag) do
                if not Core.Ask(api.GetContainerItemInfo, bag, slot) then return bag, slot end
            end
        end
    end
end

-- The stack's count now (0: gone, or another item there), and whether it is locked.
local function Stack()
    local info = Core.Ask(Container().GetContainerItemInfo, source.bag, source.slot)
    if type(info) ~= "table" or Core.Plain(info.itemID) ~= source.item then return 0, false end
    return Core.Plain(info.stackCount) or 1, Core.Plain(info.isLocked) == true
end

-- That many split off into the first free slot; false where none is free or nothing is left to split.
local function One(amount)
    local count, locked = Stack()
    if locked or count <= amount then return false end
    local bag, slot = Free()
    if not bag then return false end
    local api = Container()
    api.SplitContainerItem(source.bag, source.slot, amount)
    api.PickupContainerItem(bag, slot)
    ns.Views.split[source.item] = true
    return true
end

local Look
local function Next()
    if not auto then return end
    local count, locked = Stack()
    if locked then
        if GetTime() - auto.started > Split.LONGEST then auto = nil return end
        return C_Timer.After(Split.WAIT, Look)
    end
    if count <= auto.amount or not One(auto.amount) then
        auto = nil
        return
    end
    auto.started = GetTime()
    C_Timer.After(Split.WAIT, Look)
end
Look = ns.Guard(Next)

local function Amount()
    local value = tonumber(box:GetText()) or 1
    return math.max(1, math.min(most - 1, math.floor(value)))
end

local function SplitNow()
    if InCombatLockdown() then return end
    local amount = Amount()
    Split.Close()
    One(amount)
end

local function SplitAll()
    if InCombatLockdown() then return end
    local amount = Amount()
    Split.Close()
    auto = { amount = amount, started = GetTime() }
    if One(amount) then C_Timer.After(Split.WAIT, Look) else auto = nil end
end

local function Step(by)
    box:SetText(tostring(math.max(1, math.min(most - 1, Amount() + by))))
end

local function Key(_, key)
    if key == "ENTER" then
        local alt = rawget(_G, "IsAltKeyDown")
        if alt and alt() then SplitAll() else SplitNow() end
    elseif key == "ESCAPE" then
        Split.Close()
    end
end

-------------------------------------------------------------------------------
--  The dialog
-------------------------------------------------------------------------------
local function Button(word, width, click)
    local button = CreateFrame("Button", nil, dialog)
    button:SetSize(width, 22)
    local back = button:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0.15, 0.15, 0.15, 1)
    button.back = back
    ns.Cells.Edge(ns.Cells.Border(button), 0.25, 0.25, 0.25, 1, Core.Pixels(button, 1))
    local text = button:CreateFontString(nil, "ARTWORK")
    text:SetFontObject(Core.Font("SaneUIBagsSplitButton", "GameFontHighlightSmall", 12) or "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetText(word)
    button:SetScript("OnClick", ns.Guard(click))
    button:SetScript("OnEnter", ns.Guard(function(self) self.back:SetColorTexture(0.2, 0.2, 0.2, 1) end))
    button:SetScript("OnLeave", ns.Guard(function(self) self.back:SetColorTexture(0.15, 0.15, 0.15, 1) end))
    return button
end

local function Build()
    dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetSize(Split.WIDTH, Split.HEIGHT)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetClampedToScreen(true)
    dialog:EnableMouse(true)
    local back = dialog:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(Split.BACK[1], Split.BACK[2], Split.BACK[3], Split.BACK[4])
    ns.Cells.Edge(ns.Cells.Border(dialog), Split.EDGE[1], Split.EDGE[2], Split.EDGE[3], Split.EDGE[4], Core.Pixels(dialog, 1))
    local title = dialog:CreateFontString(nil, "ARTWORK")
    title:SetFontObject(Core.Font("SaneUIBagsSplitTitle", "GameFontHighlight", 13) or "GameFontHighlight")
    title:SetTextColor(1, 1, 1, 0.9)
    title:SetPoint("TOP", 0, -10)
    title:SetText(ns.TEXT.bagsSplit)
    box = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    box:SetSize(50, 22)
    box:SetPoint("TOP", -14, -32)
    box:SetNumeric(true)
    box:SetAutoFocus(true)
    box:SetJustifyH("CENTER")
    box:SetScript("OnKeyDown", ns.Guard(Key))
    box:SetScript("OnEscapePressed", ns.Guard(Split.Close))
    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", ns.Guard(function(_, delta) Step(delta) end))
    local less = Button("-", 22, function() Step(-1) end)
    less:SetPoint("RIGHT", box, "LEFT", -8, 0)
    local more = Button("+", 22, function() Step(1) end)
    more:SetPoint("LEFT", box, "RIGHT", 4, 0)
    dialog.most = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    dialog.most:SetPoint("LEFT", more, "RIGHT", 6, 0)
    local one = Button(ns.TEXT.bagsSplitOne, 90, SplitNow)
    one:SetPoint("BOTTOMLEFT", 10, 10)
    local all = Button(ns.TEXT.bagsSplitAll, 90, SplitAll)
    all:SetPoint("BOTTOMRIGHT", -10, 10)
    dialog:Hide()
    Split.dialog = dialog
end

-- The dialog for the stack a button of ours draws, by that button; an Auto Split still under way ends (it would go
-- on with this stack).
function Split.Open(button, record)
    if InCombatLockdown() or not (record and record.item) then return end
    local count = record.count or 1
    if count < 2 then return end
    if not dialog then Build() end
    auto = nil
    source = { bag = record.bag, slot = record.slot, item = record.item }
    most = count
    dialog:ClearAllPoints()
    dialog:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 4)
    dialog.most:SetText("/ " .. count)
    box:SetText(tostring(math.max(1, math.floor(count / 2))))
    dialog:Show()
    box:SetFocus()
    box:HighlightText()
end

function Split.Close()
    if dialog then dialog:Hide() end
end

-- The dialog closed and an Auto Split under way stopped (the bags or the bank hid).
function Split.Stop()
    auto = nil
    Split.Close()
end

-- Ours in place of the game's splitter, only where the template opened its own for this button just now (a Shift-click
-- that linked the item into the chat, or found something on the cursor or the stack locked, opened none); in a fight
-- the game's stays. Whether ours opened.
function Split.Replace(button, record)
    local modified = rawget(_G, "IsModifiedClick")
    local game = rawget(_G, "StackSplitFrame")
    if InCombatLockdown() or not (modified and modified("SPLITSTACK")) then return false end
    if not (type(game) == "table" and game.IsShown and game:IsShown() and game.owner == button) then return false end
    game:Hide()
    Split.Open(button, record)
    return true
end

-- Whether the dialog is open now (the tests); the amount in it.
function Split.Shown()
    return dialog ~= nil and dialog:IsShown(), box and box:GetText()
end
