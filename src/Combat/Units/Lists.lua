local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Units - Lists
--  Your marks of auras, kept in the module's settings by the spell's number with
--  its name, in two sides. How it looks:
--      Important      on the unit frames shown in front of the rest, whoever cast
--                     them, with a glow (Auras.lua); a glow in the game's list of
--                     your buffs and debuffs (BuffList.lua)
--      Unimportant    never on the unit frames, faded in that list
--      Hidden         out of sight in that list, until the mouse is on it
--  And the unit frames alone, nothing changed in that list, over what the first
--  side says of them:
--      Prioritize on unit frames   in front of the rest, without a glow
--      Hide from unit frames       never there
--  A spell has one mark of each side at most: put on one, it leaves the others
--  of its side.
--
--  Filled from the menu of a click on an aura or a spell of the spellbook
--  (Lists.Menu), and in the window Edit tracked (/sane auras, /sane reminders, the
--  menu's Edit tracked...), Saneroki, 2026-11-06: one window for every aura's setup,
--  the marks and the reminders together. One long list of every aura you set up,
--  by name, a line for each of its reminders (one where it has none), each with
--  its red X in front (off the list, every mark and its reminder; on one of
--  several lines of an aura that line's reminder alone), a + (the aura tracked
--  once more, a copy of the line's reminder under it: Saneroki, 2026-11-07,
--  "Sometimes I want to show it on multiple places or have different
--  conditions"), its icon, name and number, a tick for each mark in the columns
--  Hidden, Unimportant, Important, then a cog (Edit Tracked conditions: the line
--  chosen; Saneroki, 2026-11-09, in place of the columns Hide from unit frames
--  and Prioritize on unit frames, whose ticks stand in that section now), and
--  last Tracked: a reminder made or deleted (Reminders/: on the first aura bar,
--  or where its settings choose: another bar, your unit frames, the party and
--  raid frames, the nameplates). A spell stays on the list with no tick, until
--  its X (auraKept). A line clicked is chosen, and under the list stand its
--  reminder's settings and its marks for the unit frames, under the title Edit
--  Tracked conditions (Reminders/Editor.lua). Over it a
--  search box: as you type, suggestions under it in groups, each class's auras,
--  the enemies', the items' (Core's SpellSearch.lua); a click on one, or Enter for the
--  first, puts it on the list, lit and chosen, to tick. At the foot, what the
--  game lets the marks do.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Lists = {}
ns.AuraLists = Lists

Lists.WIDTH, Lists.HEIGHT = 920, 520 -- and the reminder's settings under the list (Editor.HEIGHT)
Lists.INSET = 12
Lists.LINE = 26     -- a spell's line
Lists.ICON = 18
Lists.TICK = 24
Lists.COLUMN = 92   -- a mark's column, its tick in the middle; the cog's and Tracked's too
Lists.TOP = 56      -- from the window's top to the marks' words, under the search box
Lists.HEAD = 30     -- the marks' words over their columns, two lines at most
Lists.BAR = 24      -- the scroll bar's room at the list's right
Lists.PLUS = 18     -- the + beside the X, square: the game's own plus button (its quest log's)
Lists.PLUS_ART = { up = "Interface\\Buttons\\UI-PlusButton-Up", down = "Interface\\Buttons\\UI-PlusButton-Down",
                   lit = "Interface\\Buttons\\UI-PlusButton-Hilight" }
Lists.SEARCH = 360  -- the search box's suggestions, wide
Lists.KEYS = { white = "auraWhite", black = "auraBlack", hidden = "auraHidden", show = "auraShow", hide = "auraHide",
               kept = "auraKept" } -- the lists' settings; kept: the window's own, every spell put on it
Lists.ORDER = { "white", "black", "hidden", "show", "hide" }
Lists.COLUMNS = { "hidden", "black", "white" } -- the window's ticks, left to right; then the cog, then Tracked
Lists.COG = "questlog-icon-setting" -- the game's cog, as Core's windows have it
Lists.WORDS = { white = "auraImportant", black = "auraUnimportant", hidden = "auraHidden",
                show = "auraFramesShow", hide = "auraFramesHide" } -- their words in ns.TEXT
Lists.SIDE = { white = "look", black = "look", hidden = "look", show = "frames", hide = "frames" }

local frame, window, status, scroll, child, empty, finder
local lines = {} -- the list's lines
local names      -- [a side][a spell's name] = its list, made when asked after a change
local rows       -- the list as last shown: { id, name } each, by name
local fresh      -- the name of the spell last put on it, lit
local chosen     -- the name of the spell whose reminder's settings show
local pick       -- which of its reminders (nil: its first line's)

-- A list: { [spell number] = its name }.
local function List(which)
    local key = Lists.KEYS[which]
    ns.options[key] = type(ns.options[key]) == "table" and ns.options[key] or {}
    return ns.options[key]
end

local Icon = Core.SpellSearch.Icon

-- Every spell on the window's list, a mark or a reminder, by name: a line ({ id, name, reminder }) for each of its
-- reminders in the order made, one without where it has none. by: a name's first line.
local function Rows()
    local found, by, ids, tracked, order = {}, {}, {}, {}, {}
    local function Add(id, name)
        name = tostring(name)
        if ids[name] then return end
        ids[name] = tonumber(id) or false
        order[#order + 1] = name
    end
    for id, name in pairs(List("kept")) do Add(id, name) end
    for _, which in ipairs(Lists.ORDER) do
        for id, name in pairs(List(which)) do Add(id, name) end
    end
    for _, reminder in ipairs(ns.Reminders.List()) do
        Add(reminder.id, reminder.name)
        local name = tostring(reminder.name)
        tracked[name] = tracked[name] or {}
        table.insert(tracked[name], reminder)
    end
    table.sort(order, function(a, b) return a:lower() < b:lower() end)
    for _, name in ipairs(order) do
        local own = tracked[name]
        for index = 1, own and #own or 1 do
            local row = { id = ids[name] or nil, name = name, reminder = own and own[index] }
            found[#found + 1] = row
            by[name] = by[name] or row
        end
    end
    return found, by
end

-- The line chosen: the chosen reminder's, else the first of the chosen name.
local function Current(found, by)
    if not chosen then return nil end
    for _, row in ipairs(found) do
        if pick and row.reminder == pick then return row end
    end
    return by[chosen]
end

-- The list of a spell on a side by its name, any rank of it; nil where it has none.
local function Side(side, name)
    if not names then
        names = { look = {}, frames = {} }
        for _, which in ipairs(Lists.ORDER) do
            for _, spell in pairs(List(which)) do names[Lists.SIDE[which]][spell] = which end
        end
    end
    return names[side][name]
end

-- The window's list as it is now.
local function Fill()
    if not frame then return end
    local by
    rows, by = Rows()
    local current = Current(rows, by)
    for index, row in ipairs(rows) do
        local line = lines[index] or Lists.Line(index)
        line.row = row
        line.icon:SetTexture(Icon(row.id))
        line.name:SetText(row.name)
        line.number:SetText(row.id or "")
        line.lit:SetShown(row.name == fresh)
        line.mark:SetShown(row == current)
        for which, tick in pairs(line.ticks) do tick:SetChecked(Side(Lists.SIDE[which], row.name) == which) end
        line.remind:SetChecked(row.reminder ~= nil)
        line:Show()
    end
    for index = #rows + 1, #lines do lines[index]:Hide() end
    empty:SetShown(rows[1] == nil)
    child:SetHeight(math.max(#rows * Lists.LINE, 1))
    ns.ReminderEditor.Show(current and current.reminder, current and current.name, current and Icon(current.id),
                           current and current.id)
end

-- The list as it is now, from outside (a reminder made or deleted elsewhere).
function Lists.Refresh()
    Fill()
end

-- A list changed: every frame's auras anew, the game's list, the window.
local function Changed()
    names = nil
    ns.UnitAuras.Refresh()
    ns.BuffList.Style()
    Fill()
end

-- How a spell looks in the game's list: "white", "black", "hidden" or nil.
function Lists.Mark(name)
    return Side("look", name)
end

-- Whether a spell has that mark ("hide", "white"), by its name, any rank of it.
function Lists.Has(which, name)
    return Side(Lists.SIDE[which], name) == which
end

-- A spell on a list (and on the window's): off the others of its side.
function Lists.Put(which, spell)
    local id = tonumber(spell and spell.id)
    if not id then return end
    for _, other in ipairs(Lists.ORDER) do
        if Lists.SIDE[other] == Lists.SIDE[which] then List(other)[id] = nil end
    end
    local name = spell.name or tostring(id)
    List(which)[id] = name
    List("kept")[id] = List("kept")[id] or name
    Changed()
    if status then status:SetText(ns.TEXT.listsPut:format(name, ns.TEXT[Lists.WORDS[which]])) end
end

function Lists.Take(which, id)
    List(which)[id] = nil
    Changed()
end

-- A spell off one list, by its name: every rank of it.
function Lists.Unmark(which, name)
    for id, spell in pairs(List(which)) do
        if spell == name then List(which)[id] = nil end
    end
    Changed()
end

-- A spell off every list and the window's, by its name, and its reminders gone.
function Lists.Forget(name)
    for which in pairs(Lists.KEYS) do
        for id, spell in pairs(List(which)) do
            if spell == name then List(which)[id] = nil end
        end
    end
    if fresh == name then fresh = nil end
    if chosen == name then chosen, pick = nil, nil end
    while ns.Reminders.Named(name) do ns.Reminders.Take(ns.Reminders.Named(name)) end
    Changed()
    if status then status:SetText(ns.TEXT.listsGone:format(name)) end
end

-- A menu's lines for an aura: the marks by side, one of each at most, a tick taken off again by a click; then the window
-- (Edit tracked...: Saneroki, 2026-11-07, "change the name from edit aura to edit tracked").
function Lists.Entries(root, spell)
    local last
    for _, which in ipairs(Lists.ORDER) do
        local side = Lists.SIDE[which]
        if last and last ~= side then root:CreateDivider() end
        last = side
        root:CreateCheckbox(ns.TEXT[Lists.WORDS[which]], ns.Guard(function() return Side(side, spell.name) == which end),
            ns.Guard(function()
                if Side(side, spell.name) ~= which then return Lists.Put(which, spell) end
                Lists.Unmark(which, spell.name)
            end))
    end
    root:CreateDivider()
    root:CreateButton(ns.TEXT.auraLists, ns.Guard(function() Lists.Open(nil, spell.name, spell.reminder) end))
end

-- The menu of an aura or a spell ({ id, name, icon, harmful, unit }): the marks, the window, last Add tracking where it is
-- not tracked yet. Without one (the game hides which aura it is, in a fight) it says so, and offers the window.
function Lists.Menu(owner, spell)
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        if spell then
            root:CreateTitle(spell.name)
            Lists.Entries(root, spell)
            ns.Reminders.Entry(root, spell)
        else
            root:CreateTitle(ns.TEXT.auraFight)
            root:CreateDivider()
            root:CreateButton(ns.TEXT.auraLists, ns.Guard(function() Lists.Open() end))
        end
    end))
end

local Tip = Core.SpellSearch.Tip

-------------------------------------------------------------------------------
--  Choosing, the search
-------------------------------------------------------------------------------
-- The list scrolled so that the spell of that name is in sight.
local function Reach(name)
    for index, row in ipairs(rows or {}) do
        if row.name == name then
            if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
            local most = Plain(scroll:GetVerticalScrollRange()) or 0
            local height = Plain(scroll:GetHeight()) or 0
            local top = (index - 1) * Lists.LINE
            local now = Plain(scroll:GetVerticalScroll()) or 0
            if top < now or top + Lists.LINE > now + height then
                scroll:SetVerticalScroll(math.max(0, math.min(top - Lists.LINE, most)))
            end
            return
        end
    end
end

-- That spell chosen, that reminder of it (nil: its first line's): its settings under the list.
local function Choose(name, reminder)
    chosen, pick = name, reminder
    Fill()
end

-- A suggestion taken: on the window's list with no mark yet, lit, chosen and in sight.
local function Pick(entry)
    local _, by = Rows()
    local there = by[entry.name] ~= nil
    if not there then List("kept")[entry.id] = entry.name end
    fresh, chosen, pick = entry.name, entry.name, nil
    Fill()
    Reach(entry.name)
    status:SetText((there and ns.TEXT.listsThere or ns.TEXT.listsAdded):format(entry.name))
end

-- A line's aura as a new reminder takes it: a debuff on your target, a buff on you (its settings can change that).
local function Spell(row)
    local spells = rawget(_G, "C_Spell")
    local harmful = spells and Core.Ask(spells.IsSpellHarmful, row.id) == true or false
    return { id = row.id, name = row.name, icon = Icon(row.id), harmful = harmful, unit = harmful and "target" or "player" }
end

-- A spell kept on the window's list, though it has no mark and no reminder (left by its X).
local function Keep(id, name)
    id = tonumber(id)
    if id and name then List("kept")[id] = List("kept")[id] or name end
end

-- A line's tick Tracked: its reminder made on the first aura bar, or deleted (an aura's last line stays); the line
-- chosen.
local function Remind(row, on)
    chosen, pick = row.name, nil
    Keep(row.id, row.name)
    if on and not row.reminder then
        pick = ns.Reminders.Make(Spell(row))
    elseif not on and row.reminder then
        ns.Reminders.Take(row.reminder)
    end
    Fill()
end

-- A line's +: its aura tracked once more, a copy of the line's reminder under it (its own place and settings from
-- now on), or its first where it has none; the new line chosen.
local function Copy(row)
    Keep(row.id, row.name)
    local copy = row.reminder and ns.Reminders.Copy(row.reminder) or ns.Reminders.Make(Spell(row))
    chosen, pick = row.name, copy
    Fill()
    if status then status:SetText(ns.TEXT.listsCopied:format(row.name)) end
end

-- A line's X: on one of several lines of an aura its reminder alone goes, with the line; on its last line the aura goes
-- off the list, every mark and its reminder (Forget).
local function Drop(row)
    local count = 0
    for _, reminder in ipairs(ns.Reminders.List()) do
        if reminder.name == row.name then count = count + 1 end
    end
    if not (row.reminder and count > 1) then return Lists.Forget(row.name) end
    if pick == row.reminder then pick = nil end
    ns.Reminders.Take(row.reminder)
    if status then status:SetText(ns.TEXT.listsCopyGone:format(row.name)) end
end

-- Add tracking (an aura's menu, ns.Reminders.Entry; the button under the list, Reminders/Editor.lua: spell nil, the
-- line chosen): the aura on the window's list, its reminder made on the first aura bar where it has none (Saneroki,
-- 2026-11-07: "make the reminder bar 1 the default one"), the window open on it with its settings under the list.
function Lists.Track(spell)
    if not spell then
        local _, by = Rows()
        local row = chosen and by[chosen]
        if not row then return end
        spell = Spell(row)
    end
    if not spell.name then return end
    Keep(spell.id, spell.name)
    if not ns.Reminders.Named(spell.name) then ns.Reminders.Make(spell) end
    Lists.Open(nil, spell.name)
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
-- The middle of a column from the list's right: the marks' in their order, then the cog (#Lists.COLUMNS + 1), then
-- Tracked (#Lists.COLUMNS + 2).
local function Middle(place)
    return -((#Lists.COLUMNS + 2 - place) * Lists.COLUMN + Lists.COLUMN / 2)
end

-- A tooltip of a few words for a button.
local function Says(button, words)
    button:SetScript("OnEnter", ns.Guard(function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(words, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end))
    button:SetScript("OnLeave", GameTooltip_Hide)
end

-- One line of the list, made as needed: the X, the +, the icon, the name and number, a tick per mark, the cog, its
-- reminder's tick; a click on it, or on its cog, chooses it.
function Lists.Line(index)
    local line = CreateFrame("Frame", nil, child)
    line:SetHeight(Lists.LINE)
    line:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(index - 1) * Lists.LINE)
    line:SetPoint("RIGHT", child, "RIGHT", 0, 0)
    line:EnableMouse(true)
    line:SetScript("OnEnter", ns.Guard(function(self) if self.row then Tip(self, self.row.id, self.row.name) end end))
    line:SetScript("OnLeave", GameTooltip_Hide)
    line:SetScript("OnMouseUp", ns.Guard(function(self) if self.row then Choose(self.row.name, self.row.reminder) end end))
    -- Chosen and lit (just put on the list), the name's part only: under the ticks they made them look greyed out.
    line.mark = line:CreateTexture(nil, "BACKGROUND")
    line.mark:SetPoint("TOPLEFT", line, "TOPLEFT", 0, 0)
    line.mark:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", Middle(1) - Lists.COLUMN / 2, 0)
    line.mark:SetColorTexture(1, 1, 1, 0.1)
    line.mark:Hide()
    line.lit = line:CreateTexture(nil, "BACKGROUND")
    line.lit:SetAllPoints(line.mark)
    line.lit:SetColorTexture(1, 0.82, 0, 0.14)
    line.lit:Hide()
    if index % 2 == 0 then
        local band = line:CreateTexture(nil, "BACKGROUND", nil, -1)
        band:SetAllPoints(line)
        band:SetColorTexture(1, 1, 1, 0.03)
    end
    local take = CreateFrame("Button", nil, line, "UIPanelCloseButton")
    take:SetFrameLevel((Plain(line:GetFrameLevel()) or 1) + 1) -- the template stands high (510): over the suggestions else
    take:SetSize(Lists.LINE, Lists.LINE)
    take:SetPoint("LEFT", line, "LEFT", 0, 0)
    take:SetScript("OnClick", ns.Guard(function() if line.row then Drop(line.row) end end))
    local copy = CreateFrame("Button", nil, line)
    copy:SetSize(Lists.PLUS, Lists.PLUS)
    copy:SetPoint("LEFT", take, "RIGHT", 0, 0)
    copy:SetNormalTexture(Lists.PLUS_ART.up)
    copy:SetPushedTexture(Lists.PLUS_ART.down)
    copy:SetHighlightTexture(Lists.PLUS_ART.lit, "ADD")
    copy:SetScript("OnClick", ns.Guard(function() if line.row then Copy(line.row) end end))
    Says(copy, ns.TEXT.listsCopy)
    line.copy = copy
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(Lists.ICON, Lists.ICON)
    line.icon:SetPoint("LEFT", copy, "RIGHT", 4, 0)
    line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    line.number = line:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    line.number:SetPoint("RIGHT", line, "RIGHT", Middle(1) - Lists.COLUMN / 2 - 6, 0)
    line.name = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line.name:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
    line.name:SetPoint("RIGHT", line.number, "LEFT", -6, 0)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line.ticks = {}
    for place, which in ipairs(Lists.COLUMNS) do
        local tick = CreateFrame("CheckButton", nil, line, "UICheckButtonTemplate")
        tick:SetSize(Lists.TICK, Lists.TICK)
        tick:SetPoint("CENTER", line, "RIGHT", Middle(place), 0)
        tick:SetScript("OnClick", ns.Guard(function(self)
            local row = line.row
            if not row then return end
            if self:GetChecked() then return Lists.Put(which, row) end
            Lists.Unmark(which, row.name)
        end))
        line.ticks[which] = tick
    end
    -- The cog: the line chosen, its conditions under the list (Saneroki, 2026-11-09).
    local cog = CreateFrame("Button", nil, line)
    cog:SetSize(Lists.ICON, Lists.ICON)
    cog:SetPoint("CENTER", line, "RIGHT", Middle(#Lists.COLUMNS + 1), 0)
    cog:SetNormalAtlas(Lists.COG)
    cog:SetHighlightAtlas(Lists.COG, "ADD")
    cog:SetScript("OnClick", ns.Guard(function() if line.row then Choose(line.row.name, line.row.reminder) end end))
    Says(cog, ns.TEXT.reminderTitle)
    line.cog = cog
    line.remind = CreateFrame("CheckButton", nil, line, "UICheckButtonTemplate")
    line.remind:SetSize(Lists.TICK, Lists.TICK)
    line.remind:SetPoint("CENTER", line, "RIGHT", Middle(#Lists.COLUMNS + 2), 0)
    line.remind:SetScript("OnClick", ns.Guard(function(self)
        if line.row then Remind(line.row, self:GetChecked() and true or false) end
    end))
    lines[index] = line
    return line
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Lists.WIDTH, Lists.HEIGHT + ns.ReminderEditor.HEIGHT)
    frame:SetFrameStrata("DIALOG") -- over the full screen, opened from the spellbook there
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = ns.store, key = "auraListsPlace", title = ns.TEXT.listsTitle, edge = false,
        dock = false, sizable = false, first = { point = "CENTER", x = 0, y = 60 },
        close = function() frame:Hide() end,
    })
    local inside, I = window.inside, Lists.INSET
    scroll = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", inside, "TOPLEFT", I, -(I + Lists.TOP + Lists.HEAD))
    scroll:SetPoint("BOTTOMRIGHT", inside, "BOTTOMRIGHT", -(I + Lists.BAR), I + 48 + ns.ReminderEditor.HEIGHT)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(Lists.WIDTH - 2 * I - Lists.BAR, 1)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", ns.Guard(function(_, width)
        width = Plain(width)
        if width and width > 0 then child:SetWidth(width) end
    end))
    for place, which in ipairs(Lists.COLUMNS) do
        local head = inside:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        head:SetWidth(Lists.COLUMN - 6)
        head:SetPoint("BOTTOM", scroll, "TOPRIGHT", Middle(place), 4)
        head:SetJustifyH("CENTER")
        head:SetWordWrap(true)
        head:SetText(ns.TEXT[Lists.WORDS[which]])
    end
    for place, word in ipairs({ ns.TEXT.reminderTitle, ns.TEXT.reminderColumn }) do -- the cog's, Tracked's
        local head = inside:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        head:SetWidth(Lists.COLUMN - 6)
        head:SetPoint("BOTTOM", scroll, "TOPRIGHT", Middle(#Lists.COLUMNS + place), 4)
        head:SetJustifyH("CENTER")
        head:SetWordWrap(true)
        head:SetText(word)
    end
    empty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", 4, -6)
    empty:SetText(ns.TEXT.listsEmpty)
    local rule = inside:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    rule:SetPoint("BOTTOMLEFT", inside, "BOTTOMLEFT", I, I)
    rule:SetPoint("BOTTOMRIGHT", inside, "BOTTOMRIGHT", -I, I)
    rule:SetJustifyH("LEFT")
    rule:SetText(ns.TEXT.listsRule)
    status = inside:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", rule, "TOPLEFT", 0, 6)
    status:SetPoint("BOTTOMRIGHT", rule, "TOPRIGHT", 0, 6)
    status:SetJustifyH("LEFT")
    -- The chosen aura's reminder under the list, then the search over all (its box the window's last: the suggestions
    -- lie over the rest).
    local settings = ns.ReminderEditor.Build(inside)
    settings:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -8)
    settings:SetPoint("RIGHT", inside, "RIGHT", -I, 0)
    finder = Core.SpellSearch.Box(inside, I, -I, { words = ns.TEXT.listsInput, width = Lists.SEARCH, pick = Pick,
                                               label = "aura lists" })
    frame:HookScript("OnShow", ns.Guard(Fill))
    frame:HookScript("OnHide", ns.Guard(function() finder:Clear() end))
    window:Place()
end

-- The window; text: searched for at once, as if typed (/sane auras rejuv); name: that aura chosen, in sight; reminder:
-- that line of it (nil: its first).
function Lists.Open(text, name, reminder)
    if ns.off then return end
    if not frame then Build() end
    status:SetText("")
    if name then chosen, pick = name, reminder end
    frame:Show()
    Fill()
    if name then Reach(name) end
    if type(text) == "string" and text:find("%S") then finder:Search(text) end
end

function Lists.Toggle()
    if frame and frame:IsShown() then return frame:Hide() end
    Lists.Open()
end

-- Standing down: the window goes.
function Lists.Hide()
    if frame then frame:Hide() end
end

-- The menu, for Abilities' spellbook and aura history (Core's AuraMarks.lua): there while the module stands.
Core.AuraMarks.Serve(ns, Lists.Menu)
