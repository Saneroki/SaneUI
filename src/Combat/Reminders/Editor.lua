local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Editor
--  The reminder of the aura chosen in Edit tracked (Units/Lists.lua: /sane auras,
--  /sane reminders, an aura's menu), under its list, each setting taking effect
--  at once (Saneroki, 2026-11-06: one window for every aura's setup):
--      Shows on   a reminder bar (the first one for a new reminder), the
--                 party and raid frames, the nameplates: a tick on each line,
--                 any number of them, one at least (the last stays ticked),
--                 the dropdown's words naming them ("Aura bar 1, Nameplates";
--                 Saneroki, 2026-11-07: "make the shows on also multiple
--                 choice"); New bar (the reminder on it in place of its bars),
--                 Delete bar (its reminders on the first bar left; the last
--                 bar stays; on several bars a menu of them asks which)
--      Watch on   you, your target, your focus: a tick on each line, any
--                 number of them, one at least (the last stays ticked), the
--                 dropdown's words naming those watched ("You, Your target";
--                 Saneroki, 2026-11-07: "select multiple targets in its
--                 dropdown with checkboxes"); on the frames each member, on
--                 the nameplates each plate's unit (on none of the bars it and
--                 Delete bar are out of sight)
--      Display when missing, Display when active, Combat, Don't show in
--      resting areas, Only yours, Offset time
--      When class in group   Not needed, or a class of the game's: shown only
--                 while you or one of your party or raid is of it (Saneroki,
--                 2026-11-07: "if a druid is in the party or raid it will
--                 then show that spell", "my own included")
--  A line's tick Tracked makes or deletes one; a line chosen without
--  one has the button Add tracking (Lists.Track: made on the first bar, its
--  settings here at once; Saneroki, 2026-11-07: a spell searched could not be
--  set up).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Editor = {}
ns.ReminderEditor = Editor

Editor.HEIGHT = 158 -- the panel under the list
Editor.ICON = 20
Editor.ROW = 30     -- from one row of settings to the next
Editor.RIGHT = 520  -- where the settings' right half starts
Editor.WORD = 80    -- a dropdown's words before it
Editor.LONG = 140   -- longer words before it (When class in group)
Editor.MENU = 170   -- a dropdown's width
Editor.WIDE = 220   -- Shows on's and Watch on's: room for three names ("You, Your target, Your focus")
Editor.TRACK = 130  -- the button Add tracking's width
Editor.HINT = 5     -- the words beside it, down from its top
Editor.COMBAT = { "any", "out", "in" }
Editor.UNITS = { "player", "target", "focus" }

local panel, controls, face, head, on, hint, track, place, unit, combat, early, takeBar, class
local ticks = {}
local chosen -- the reminder whose settings show

local Fill

-- A setting of the reminder chosen changed: it counts now, on its bars, the frames, the plates.
local function Set(key, value)
    if not chosen then return end
    chosen[key] = value
    ns.Reminders.Apply()
    Fill()
end

local classes -- the game's classes, { name, token } each by name, read once

-- Which class must be in your group: none needed, then the game's classes by name.
local function Classes()
    if not classes then
        classes = {}
        local total = Core.Ask(rawget(_G, "GetNumClasses")) or 0
        for id = 1, math.max(total, 13) do
            local name, token = Core.Ask(rawget(_G, "GetClassInfo"), id)
            if type(name) == "string" and type(token) == "string" then classes[#classes + 1] = { name, token } end
        end
        table.sort(classes, function(a, b) return a[1] < b[1] end)
    end
    local entries = { { ns.TEXT.reminderClassAny } }
    for at, entry in ipairs(classes) do entries[at + 1] = entry end
    return entries
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

-- The bars the reminder shows on, as Places gives them.
local function OwnBars(reminder)
    local entries = {}
    for _, entry in ipairs(Places()) do
        if ns.Reminders.IsBar(entry[2]) and ns.Reminders.At(reminder, entry[2]) then entries[#entries + 1] = entry end
    end
    return entries
end

-- Shows on's words: the places ticked, by name ("Aura bar 1, Nameplates").
function Editor.Where(reminder)
    local words = {}
    for _, entry in ipairs(Places()) do
        if ns.Reminders.At(reminder, entry[2]) then words[#words + 1] = entry[1] end
    end
    return table.concat(words, ", ")
end

-- What the window says of the places that watch each one there (the health bars, the nameplates), one after the other.
local function Says(reminder)
    local words = {}
    if ns.Reminders.At(reminder, ns.Reminders.GROUP) then words[#words + 1] = ns.TEXT.reminderOnGroup end
    if ns.Reminders.At(reminder, ns.Reminders.PLATES) then
        words[#words + 1] = words[1] and ns.TEXT.reminderOnPlates:gsub("^%u", string.lower) or ns.TEXT.reminderOnPlates
    end
    return table.concat(words, "; ")
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
    on:SetText(Says(chosen))
    for key, tick in pairs(ticks) do tick:SetChecked(chosen[key] and true or false) end
    -- On none of the bars (the health bars, the nameplates: each member, each plate's unit) no bar to delete and no unit
    -- to choose: out of sight, not greyed out.
    takeBar:SetShown(not barless)
    takeBar:SetEnabled(ns.Reminders.Bars()[2] ~= nil)
    unit:SetShown(not barless)
    unit.words:SetShown(not barless)
    place:GenerateMenu()
    place:OverrideText(Editor.Where(chosen))
    unit:GenerateMenu()
    unit:OverrideText(Editor.Watched(chosen))
    combat:GenerateMenu()
    class:GenerateMenu()
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

-- A dropdown on the panel's row at x, its words before it (room: theirs, Editor.WORD where not said), that wide
-- (Editor.MENU where not said), its lines made by lines(root).
local function Dropdown(x, row, word, lines, room, wide)
    local words = Words(x, row, word)
    local menu = CreateFrame("DropdownButton", nil, controls, "WowStyle1DropdownTemplate")
    menu.words = words
    menu:SetWidth(wide or Editor.MENU)
    menu:SetPoint("TOPLEFT", controls, "TOPLEFT", x + (room or Editor.WORD), -row * Editor.ROW)
    menu:SetupMenu(ns.Guard(function(_, root) lines(root) end))
    return menu
end

-- A dropdown of one setting: entries as { word, value } (or a function that gives them; no value: the setting none).
local function Choice(key, x, row, word, entries, room)
    return Dropdown(x, row, word, function(root)
        for _, entry in ipairs(type(entries) == "function" and entries() or entries) do
            root:CreateRadio(entry[1], ns.Guard(function() return chosen ~= nil and chosen[key] == entry[2] end),
                             ns.Guard(function() Set(key, entry[2]) end))
        end
    end, room)
end

-- Watch on: that unit ticked or not, the others as they were, in Editor.UNITS's order; the last one ticked stays.
local function Watch(value)
    if not chosen then return end
    local Watches, list = ns.Reminders.On, {}
    for _, each in ipairs(Editor.UNITS) do
        local ticked = Watches(chosen, each)
        if each == value then ticked = not ticked end
        if ticked then list[#list + 1] = each end
    end
    if list[1] then Set("units", list) else Fill() end
end

-- Watch on's words: the units watched, by name ("You, Your target").
function Editor.Watched(reminder)
    local words = {}
    for at, each in ipairs(ns.Reminders.Units(reminder)) do words[at] = ns.TEXT.reminderUnits[each] or each end
    return table.concat(words, ", ")
end

-- Shows on: that place ticked or not, the others as they were, in Places' order; the last one ticked stays.
local function Put(value)
    if not chosen then return end
    local list = {}
    for _, entry in ipairs(Places()) do
        local ticked = ns.Reminders.At(chosen, entry[2])
        if entry[2] == value then ticked = not ticked end
        if ticked then list[#list + 1] = entry[2] end
    end
    if list[1] then Set("places", list) else Fill() end
end

-- Shows on's lines: a tick for each place.
local function Showing(root)
    for _, entry in ipairs(Places()) do
        local value = entry[2]
        root:CreateCheckbox(entry[1], ns.Guard(function() return chosen ~= nil and ns.Reminders.At(chosen, value) end),
                            ns.Guard(function() Put(value) end))
    end
end

-- New bar: the reminder on it, off the bars it was on; the health bars and the nameplates as they were.
local function NewBar()
    if not chosen then return end
    local list = { ns.Reminders.AddBar() }
    for _, place in ipairs(ns.Reminders.Places(chosen)) do
        if not ns.Reminders.IsBar(place) then list[#list + 1] = place end
    end
    Set("places", list)
end

-- Delete bar: the reminder's bar; on several, a menu of them asks which.
local function TakeBar(button)
    if not chosen then return end
    local own = OwnBars(chosen)
    local function Take(entry)
        ns.Reminders.TakeBar(entry[2])
        Fill()
    end
    if not own[2] then
        if own[1] then Take(own[1]) end
        return
    end
    MenuUtil.CreateContextMenu(button, ns.Guard(function(_, root)
        root:CreateTitle(ns.TEXT.reminderDeleteBar)
        for _, entry in ipairs(own) do root:CreateButton(entry[1], ns.Guard(function() Take(entry) end)) end
    end))
end

-- Watch on's lines: a tick for each unit.
local function Watching(root)
    for _, value in ipairs(Editor.UNITS) do
        root:CreateCheckbox(ns.TEXT.reminderUnits[value],
                            ns.Guard(function() return chosen ~= nil and ns.Reminders.On(chosen, value) end),
                            ns.Guard(function() Watch(value) end))
    end
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
    place = Dropdown(0, 0, ns.TEXT.reminderOnBar, Showing, nil, Editor.WIDE)
    Button(ns.TEXT.reminderNewBar, Editor.WORD + Editor.WIDE + 8, 0, NewBar)
    takeBar = Button(ns.TEXT.reminderDeleteBar, Editor.WORD + Editor.WIDE + 102, 0, TakeBar)
    unit = Dropdown(R, 0, ns.TEXT.reminderWatch, Watching, nil, Editor.WIDE)
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
    class = Choice("class", 0, 3, ns.TEXT.reminderClass, Classes, Editor.LONG)
    Editor.panel = panel
    return panel
end

-- The panel for that reminder; nil: none, the aura of that name and icon (if any) chosen without one.
function Editor.Show(reminder, name, icon)
    chosen = reminder
    if panel then panel.name, panel.icon = name, icon end
    Fill()
end

-- Edit tracked on that reminder's aura (nil: as it was left).
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
