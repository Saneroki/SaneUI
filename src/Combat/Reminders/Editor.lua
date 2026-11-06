local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Editor
--  The reminder of the aura chosen in Edit auras (Units/Lists.lua: /sane auras,
--  /sane reminders, an aura's menu), under its list, each setting taking effect
--  at once (Saneroki, 2026-11-06: one window for every aura's setup):
--      Shows on   a reminder bar, or the party and raid frames; New bar (the
--                 reminder on it), Delete bar (its reminders on the first bar
--                 left; the last bar stays)
--      Watch on   you, your target or your focus; on the frames each member
--      Display when missing, Display when active, Combat, Don't show in
--      resting areas, Only yours, Offset time
--  A line's tick Reminder makes or deletes one; without one the panel says how.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Editor = {}
ns.ReminderEditor = Editor

Editor.HEIGHT = 128 -- the panel under the list
Editor.ICON = 20
Editor.ROW = 30     -- from one row of settings to the next
Editor.RIGHT = 470  -- where the settings' right half starts
Editor.WORD = 80    -- a dropdown's words before it
Editor.MENU = 170   -- a dropdown's width
Editor.COMBAT = { "any", "out", "in" }
Editor.UNITS = { "player", "target", "focus" }

local panel, controls, face, head, on, hint, place, unit, combat, early, takeBar
local ticks = {}
local chosen -- the reminder whose settings show

local Fill

-- A setting of the reminder chosen changed: it counts now, on its bar or the frames.
local function Set(key, value)
    if not chosen then return end
    chosen[key] = value
    ns.Reminders.Apply()
    Fill()
end

-- Where a reminder may show: { word, number } each, the bars by their place among them; the party and raid frames last.
local function Places()
    local entries = {}
    for at, number in ipairs(ns.Reminders.Bars()) do entries[at] = { ns.TEXT.reminderBar:format(at), number } end
    entries[#entries + 1] = { ns.TEXT.reminderGroup, ns.Reminders.GROUP }
    return entries
end

function Fill()
    if not panel then return end
    controls:SetShown(chosen ~= nil)
    face:SetShown(chosen ~= nil)
    hint:SetShown(chosen == nil)
    if not chosen then
        head:SetText(panel.name or "")
        on:SetText("")
        return
    end
    local frames = chosen.bar == ns.Reminders.GROUP
    face:SetTexture(chosen.icon)
    head:SetText(chosen.name)
    on:SetText(frames and ns.TEXT.reminderOnGroup or "")
    for key, tick in pairs(ticks) do tick:SetChecked(chosen[key] and true or false) end
    takeBar:SetEnabled(ns.Reminders.Bars()[2] ~= nil and not frames)
    unit:SetEnabled(not frames)
    place:GenerateMenu()
    unit:GenerateMenu()
    combat:GenerateMenu()
    if not early:HasFocus() then early:SetText(tostring(chosen.early or 0)) end
end

-- Words on the panel's row, at x.
local function Words(x, row, word)
    local words = controls:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    words:SetPoint("TOPLEFT", controls, "TOPLEFT", x, -row * Editor.ROW - 6)
    words:SetText(word)
    return words
end

-- A tick for a setting, on its row at x.
local function Tick(key, x, row, word)
    local tick = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
    tick:SetSize(24, 24)
    tick:SetPoint("TOPLEFT", controls, "TOPLEFT", x, -row * Editor.ROW)
    tick:SetScript("OnClick", ns.Guard(function(self) Set(key, self:GetChecked() and true or false) end))
    local text = controls:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", tick, "RIGHT", 4, 0)
    text:SetText(word)
    ticks[key] = tick
end

-- A dropdown of one setting, its words before it: entries as { word, value } (or a function that gives them).
local function Choice(key, x, row, word, entries)
    Words(x, row, word)
    local menu = CreateFrame("DropdownButton", nil, controls, "WowStyle1DropdownTemplate")
    menu:SetWidth(Editor.MENU)
    menu:SetPoint("TOPLEFT", controls, "TOPLEFT", x + Editor.WORD, -row * Editor.ROW)
    menu:SetupMenu(ns.Guard(function(_, root)
        for _, entry in ipairs(type(entries) == "function" and entries() or entries) do
            root:CreateRadio(entry[1], ns.Guard(function() return chosen ~= nil and chosen[key] == entry[2] end),
                             ns.Guard(function() Set(key, entry[2]) end))
        end
    end))
    return menu
end

local function Button(word, x, row, click)
    local button = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    button:SetSize(90, 22)
    button:SetPoint("TOPLEFT", controls, "TOPLEFT", x, -row * Editor.ROW)
    button:SetText(word)
    button:SetScript("OnClick", ns.Guard(click))
    return button
end

local function Early(box)
    local seconds = tonumber(box:GetText()) or 0
    if chosen then chosen.early = math.min(seconds, ns.Reminders.MOST_EARLY) end
    ns.Reminders.Apply()
end

-- The panel, on the window's inside (Lists.lua places it under the list).
function Editor.Build(parent)
    panel = CreateFrame("Frame", nil, parent)
    panel:SetHeight(Editor.HEIGHT)
    local line = panel:CreateTexture(nil, "BACKGROUND")
    line:SetPoint("TOPLEFT")
    line:SetPoint("TOPRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(0.45, 0.4, 0.3, 0.8)
    face = panel:CreateTexture(nil, "ARTWORK")
    face:SetSize(Editor.ICON, Editor.ICON)
    face:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -6)
    face:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    head = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("LEFT", face, "RIGHT", 8, 0)
    on = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    on:SetPoint("LEFT", head, "RIGHT", 10, 0)
    hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -32)
    hint:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText(ns.TEXT.reminderPick)

    controls = CreateFrame("Frame", nil, panel)
    controls:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -32)
    controls:SetPoint("BOTTOMRIGHT")
    local R = Editor.RIGHT
    place = Choice("bar", 0, 0, ns.TEXT.reminderOnBar, Places)
    Button(ns.TEXT.reminderNewBar, Editor.WORD + Editor.MENU + 8, 0, function()
        if chosen then Set("bar", ns.Reminders.AddBar()) end
    end)
    takeBar = Button(ns.TEXT.reminderDeleteBar, Editor.WORD + Editor.MENU + 102, 0, function()
        if not chosen or chosen.bar == ns.Reminders.GROUP then return end
        ns.Reminders.TakeBar(chosen.bar)
        Fill()
    end)
    local units = {}
    for index, value in ipairs(Editor.UNITS) do units[index] = { ns.TEXT.reminderUnits[value], value } end
    unit = Choice("unit", R, 0, ns.TEXT.reminderWatch, units)
    Tick("missing", 0, 1, ns.TEXT.reminderMissing)
    Tick("active", 200, 1, ns.TEXT.reminderActive)
    local combats = {}
    for index, value in ipairs(Editor.COMBAT) do combats[index] = { ns.TEXT.reminderCombat[value], value } end
    combat = Choice("combat", R, 1, ns.TEXT.reminderWhen, combats)
    Tick("noRest", 0, 2, ns.TEXT.reminderRest)
    Tick("own", 200, 2, ns.TEXT.reminderOwn)
    local words = Words(R, 2, ns.TEXT.reminderEarly)
    early = CreateFrame("EditBox", nil, controls, "InputBoxTemplate")
    early:SetSize(50, 22)
    early:SetPoint("LEFT", words, "RIGHT", 10, 0)
    early:SetAutoFocus(false)
    early:SetNumeric(true)
    early:SetMaxLetters(4)
    early:SetScript("OnTextChanged", ns.Guard(function(self, typed) if typed then Early(self) end end))
    early:SetScript("OnEnterPressed", ns.Guard(function(self) self:ClearFocus() end))
    early:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    Editor.panel = panel
    return panel
end

-- The panel for that reminder; nil: none, the aura of that name (if any) chosen without one.
function Editor.Show(reminder, name)
    chosen = reminder
    if panel then panel.name = name end
    Fill()
end

-- Edit auras on that reminder's aura (nil: as it was left).
function Editor.Open(reminder)
    ns.AuraLists.Open(nil, reminder and reminder.name)
end

-- A reminder deleted, from here or a menu: the window without it.
function Editor.Refresh()
    ns.AuraLists.Refresh()
end

function Editor.Toggle()
    ns.AuraLists.Toggle()
end

function Editor.Hide()
    ns.AuraLists.Hide()
end
