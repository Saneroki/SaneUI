local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Editor
--  The little window of your reminders (/sane reminders): on top your bars, one
--  to look at, a new one, deleting that one (its reminders go to the first bar
--  left, the last bar stays); under them on the left that bar's reminders, on
--  the right the settings of the one chosen, each taking effect at once.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Editor = {}
ns.ReminderEditor = Editor

Editor.WIDTH, Editor.HEIGHT = 520, 370
Editor.INSET = 12
Editor.LIST = 190 -- the list's width
Editor.LINE = 26  -- a reminder's line
Editor.ICON = 20
Editor.ROW = 30   -- from one setting to the next
Editor.TOP = 34   -- the bars' line
Editor.COMBAT = { "any", "out", "in" }

local frame, window, list, child, empty, panel, head, face, bar, combat, early, viewed, takeBar
local ticks, lines = {}, {}
local chosen  -- the reminder whose settings show
local looking -- the bar whose reminders show

local Fill

-- A setting of the reminder chosen changed: it counts now.
local function Set(key, value)
    if not chosen then return end
    chosen[key] = value
    ns.Reminders.Update()
    Fill()
end

-- The reminders on a bar.
local function On(number)
    local found = {}
    for _, reminder in ipairs(ns.Reminders.List()) do
        if reminder.bar == number then found[#found + 1] = reminder end
    end
    return found
end

local function Lines()
    local reminders = On(looking)
    for index, reminder in ipairs(reminders) do
        local line = lines[index] or Editor.Line(index)
        line.reminder = reminder
        line.icon:SetTexture(reminder.icon)
        line.name:SetText(reminder.name)
        line.mark:SetShown(reminder == chosen)
        line:Show()
    end
    for index = #reminders + 1, #lines do lines[index]:Hide() end
    empty:SetShown(reminders[1] == nil)
    child:SetHeight(math.max(#reminders * Editor.LINE, 1))
end

-- Which bar is looked at, and with it which reminder is chosen.
local function Look(number)
    local bars = ns.Reminders.Bars()
    looking = tContains(bars, number) and number or bars[1]
    if not chosen or chosen.bar ~= looking then chosen = On(looking)[1] end
end

function Fill()
    if not frame then return end
    Lines()
    viewed:GenerateMenu()
    takeBar:SetEnabled(ns.Reminders.Bars()[2] ~= nil)
    panel:SetShown(chosen ~= nil)
    if not chosen then return end
    face:SetTexture(chosen.icon)
    head:SetText(chosen.name)
    panel.on:SetText(ns.TEXT[chosen.unit == "player" and "reminderOnYou" or "reminderOnOther"])
    for key, tick in pairs(ticks) do tick:SetChecked(chosen[key] and true or false) end
    bar:GenerateMenu()
    combat:GenerateMenu()
    if not early:HasFocus() then early:SetText(tostring(chosen.early or 0)) end
end

function Editor.Line(index)
    local line = CreateFrame("Button", nil, child)
    line:SetHeight(Editor.LINE)
    line:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(index - 1) * Editor.LINE)
    line:SetPoint("RIGHT", child, "RIGHT", 0, 0)
    line.mark = line:CreateTexture(nil, "BACKGROUND")
    line.mark:SetAllPoints(line)
    line.mark:SetColorTexture(1, 1, 1, 0.1)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(Editor.ICON, Editor.ICON)
    line.icon:SetPoint("LEFT", 3, 0)
    line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    line.name = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line.name:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
    line.name:SetPoint("RIGHT", line, "RIGHT", -4, 0)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line:SetScript("OnClick", ns.Guard(function() Editor.Open(line.reminder) end))
    lines[index] = line
    return line
end

-- A tick for a setting, on its row of the panel.
local function Tick(key, row, word)
    local tick = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    tick:SetSize(24, 24)
    tick:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -row * Editor.ROW)
    tick:SetScript("OnClick", ns.Guard(function(self) Set(key, self:GetChecked() and true or false) end))
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", tick, "RIGHT", 4, 0)
    text:SetText(word)
    ticks[key] = tick
end

-- The bars' words for a dropdown: { word, number } each, by the bar's place among them.
local function Bars()
    local entries = {}
    for place, number in ipairs(ns.Reminders.Bars()) do entries[place] = { ns.TEXT.reminderBar:format(place), number } end
    return entries
end

-- A dropdown of one setting: entries as { word, value } (or a function that gives them), on its row of the panel, its
-- word before it.
local function Choice(key, row, word, entries)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -row * Editor.ROW - 6)
    label:SetText(word)
    local menu = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    menu:SetWidth(180)
    menu:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -row * Editor.ROW)
    menu:SetupMenu(ns.Guard(function(_, root)
        for _, entry in ipairs(type(entries) == "function" and entries() or entries) do
            root:CreateRadio(entry[1], ns.Guard(function() return chosen ~= nil and chosen[key] == entry[2] end),
                             ns.Guard(function()
                                 if key == "bar" then looking = entry[2] end
                                 Set(key, entry[2])
                             end))
        end
    end))
    return menu
end

-- The window's top line: the bar looked at, a new bar, deleting that one.
local function Top(inside, I)
    viewed = CreateFrame("DropdownButton", nil, inside, "WowStyle1DropdownTemplate")
    viewed:SetWidth(Editor.LIST)
    viewed:SetPoint("TOPLEFT", inside, "TOPLEFT", I, -I)
    viewed:SetupMenu(ns.Guard(function(_, root)
        for _, entry in ipairs(Bars()) do
            root:CreateRadio(entry[1], ns.Guard(function() return looking == entry[2] end), ns.Guard(function()
                Look(entry[2])
                Fill()
            end))
        end
    end))
    local add = CreateFrame("Button", nil, inside, "UIPanelButtonTemplate")
    add:SetSize(100, 22)
    add:SetPoint("LEFT", viewed, "RIGHT", I, 0)
    add:SetText(ns.TEXT.reminderNewBar)
    add:SetScript("OnClick", ns.Guard(function()
        Look(ns.Reminders.AddBar())
        Fill()
    end))
    takeBar = CreateFrame("Button", nil, inside, "UIPanelButtonTemplate")
    takeBar:SetSize(100, 22)
    takeBar:SetPoint("LEFT", add, "RIGHT", 6, 0)
    takeBar:SetText(ns.TEXT.reminderDeleteBar)
    takeBar:SetScript("OnClick", ns.Guard(function()
        ns.Reminders.TakeBar(looking)
        Look(ns.Reminders.Bars()[1])
        Fill()
    end))
end

local function Early(box)
    local seconds = tonumber(box:GetText()) or 0
    if chosen then chosen.early = math.min(seconds, ns.Reminders.MOST_EARLY) end
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Editor.WIDTH, Editor.HEIGHT)
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = ns.store, key = "remindersPlace", title = ns.TEXT.reminders, edge = false,
        dock = false, sizable = false, first = { point = "CENTER", x = 0, y = 60 },
        close = function() frame:Hide() end,
    })
    local inside, I = window.inside, Editor.INSET
    Top(inside, I)
    list = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    list:SetPoint("TOPLEFT", inside, "TOPLEFT", I, -I - Editor.TOP)
    list:SetPoint("BOTTOM", inside, "BOTTOM", 0, I)
    list:SetWidth(Editor.LIST - 24)
    child = CreateFrame("Frame", nil, list)
    child:SetSize(Editor.LIST - 24, 1)
    list:SetScrollChild(child)
    empty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", 4, -6)
    empty:SetWidth(Editor.LIST - 32)
    empty:SetJustifyH("LEFT")
    empty:SetText(ns.TEXT.reminderNone)

    panel = CreateFrame("Frame", nil, inside)
    panel:SetPoint("TOPLEFT", inside, "TOPLEFT", I + Editor.LIST + I, -I - Editor.TOP)
    panel:SetPoint("BOTTOMRIGHT", inside, "BOTTOMRIGHT", -I, I)
    face = panel:CreateTexture(nil, "ARTWORK")
    face:SetSize(Editor.ICON + 4, Editor.ICON + 4)
    face:SetPoint("TOPLEFT")
    face:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    head = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", face, "TOPRIGHT", 8, 0)
    head:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
    head:SetJustifyH("LEFT")
    head:SetWordWrap(false)
    panel.on = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.on:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -1)

    bar = Choice("bar", 1, ns.TEXT.reminderOnBar, Bars)
    Tick("missing", 2, ns.TEXT.reminderMissing)
    Tick("active", 3, ns.TEXT.reminderActive)
    local combats = {}
    for index, value in ipairs(Editor.COMBAT) do combats[index] = { ns.TEXT.reminderCombat[value], value } end
    combat = Choice("combat", 4, ns.TEXT.reminderWhen, combats)
    Tick("noRest", 5, ns.TEXT.reminderRest)

    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -6 * Editor.ROW - 6)
    label:SetText(ns.TEXT.reminderEarly)
    early = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    early:SetSize(50, 22)
    early:SetPoint("LEFT", label, "RIGHT", 10, 0)
    early:SetAutoFocus(false)
    early:SetNumeric(true)
    early:SetMaxLetters(4)
    early:SetScript("OnTextChanged", ns.Guard(function(self, typed) if typed then Early(self) end end))
    early:SetScript("OnEnterPressed", ns.Guard(function(self) self:ClearFocus() end))
    early:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))

    local delete = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    delete:SetSize(130, 22)
    delete:SetPoint("BOTTOMRIGHT")
    delete:SetText(ns.TEXT.reminderDelete)
    delete:SetScript("OnClick", ns.Guard(function()
        if not chosen then return end
        ns.Reminders.Take(chosen)
    end))
    window:Place()
end

-- The window, on that reminder (nil: as it was left).
function Editor.Open(reminder)
    if ns.off then return end
    if not frame then Build() end
    chosen = reminder or chosen
    Look(chosen and chosen.bar or looking)
    frame:Show()
    Fill()
end

-- A reminder deleted, from here or a menu: the window without it.
function Editor.Refresh()
    if not frame then return end
    if chosen and not tContains(ns.Reminders.List(), chosen) then chosen = nil end
    Look(looking)
    Fill()
end

function Editor.Toggle()
    if frame and frame:IsShown() then return frame:Hide() end
    Editor.Open()
end

function Editor.Hide()
    if frame then frame:Hide() end
end
