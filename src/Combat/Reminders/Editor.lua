local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Editor
--  The reminder of the aura chosen in Edit auras (Units/Lists.lua: /sane auras,
--  /sane reminders, an aura's menu), under its list, each setting taking effect
--  at once (Saneroki, 2026-11-06: one window for every aura's setup):
--      Shows on   a reminder bar (the first one for a new reminder), the
--                 party and raid frames, or the nameplates; New bar (the
--                 reminder on it), Delete bar (its reminders on the first bar
--                 left; the last bar stays)
--      Watch on   you, your target or your focus; on the frames each member,
--                 on the nameplates each plate's unit (then it and Delete bar
--                 are out of sight)
--      Display when missing, Display when active, Combat, Don't show in
--      resting areas, Only yours, Offset time
--  A line's tick Tracked makes or deletes one; a line chosen without
--  one has the button Add tracking (Lists.Track: made on the first bar, its
--  settings here at once; Saneroki, 2026-11-07: a spell searched could not be
--  set up).
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
Editor.TRACK = 130  -- the button Add tracking's width
Editor.HINT = 5     -- the words beside it, down from its top
Editor.COMBAT = { "any", "out", "in" }
Editor.UNITS = { "player", "target", "focus" }

local panel, controls, face, head, on, hint, track, place, unit, combat, early, takeBar
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

-- Where a reminder may show: { word, number } each, the bars by their place among them; then the party and raid
-- frames, the nameplates.
local function Places()
    local entries = {}
    for at, number in ipairs(ns.Reminders.Bars()) do entries[at] = { ns.TEXT.reminderBar:format(at), number } end
    entries[#entries + 1] = { ns.TEXT.reminderGroup, ns.Reminders.GROUP }
    entries[#entries + 1] = { ns.TEXT.reminderPlates, ns.Reminders.PLATES }
    return entries
end

function Fill()
    if not panel then return end
    local untracked = chosen == nil and panel.name ~= nil
    controls:SetShown(chosen ~= nil)
    face:SetShown(chosen ~= nil or panel.icon ~= nil)
    hint:SetShown(chosen == nil)
    track:SetShown(untracked)
    if not chosen then
        face:SetTexture(panel.icon)
        head:SetText(panel.name or "")
        on:SetText("")
        hint:ClearAllPoints() -- beside Add tracking, else where the settings stand; both points by their tops
        if untracked then
            hint:SetPoint("TOPLEFT", track, "TOPRIGHT", 10, -Editor.HINT)
        else
            hint:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -32)
        end
        hint:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, untracked and -32 - Editor.HINT or -32)
        hint:SetText(untracked and ns.TEXT.reminderNone or ns.TEXT.reminderPick)
        return
    end
    local barless = not ns.Reminders.OnBar(chosen)
    face:SetTexture(chosen.icon)
    head:SetText(chosen.name)
    on:SetText(chosen.bar == ns.Reminders.GROUP and ns.TEXT.reminderOnGroup
               or chosen.bar == ns.Reminders.PLATES and ns.TEXT.reminderOnPlates or "")
    for key, tick in pairs(ticks) do tick:SetChecked(chosen[key] and true or false) end
    -- On the health bars and the nameplates no bar to delete and no unit to choose (each member, each plate's): out of
    -- sight, not greyed out.
    takeBar:SetShown(not barless)
    takeBar:SetEnabled(ns.Reminders.Bars()[2] ~= nil)
    unit:SetShown(not barless)
    unit.words:SetShown(not barless)
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
    local words = Words(x, row, word)
    local menu = CreateFrame("DropdownButton", nil, controls, "WowStyle1DropdownTemplate")
    menu.words = words
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
    hint:SetJustifyH("LEFT")
    track = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    track:SetSize(Editor.TRACK, 22)
    track:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -32)
    track:SetText(ns.TEXT.trackAdd)
    track:SetScript("OnClick", ns.Guard(function() ns.AuraLists.Track() end))

    controls = CreateFrame("Frame", nil, panel)
    controls:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -32)
    controls:SetPoint("BOTTOMRIGHT")
    local R = Editor.RIGHT
    place = Choice("bar", 0, 0, ns.TEXT.reminderOnBar, Places)
    Button(ns.TEXT.reminderNewBar, Editor.WORD + Editor.MENU + 8, 0, function()
        if chosen then Set("bar", ns.Reminders.AddBar()) end
    end)
    takeBar = Button(ns.TEXT.reminderDeleteBar, Editor.WORD + Editor.MENU + 102, 0, function()
        if not chosen or not ns.Reminders.OnBar(chosen) then return end
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

-- The panel for that reminder; nil: none, the aura of that name and icon (if any) chosen without one.
function Editor.Show(reminder, name, icon)
    chosen = reminder
    if panel then panel.name, panel.icon = name, icon end
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
