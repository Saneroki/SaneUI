local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Lists
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
--  (Lists.Menu), and in a window of its own (/sane auras, and the menu's Aura
--  lists), Saneroki, 2026-11-06: one long list of every aura you set up, by name,
--  each with its red X in front (off the list and every mark), its icon, name and
--  number, and a tick for each mark in the columns Hidden, Unimportant, Important,
--  Hide from unit frames, Prioritize on unit frames. A spell stays on the list
--  with no tick, until its X (auraKept). Over it a search box: as you type,
--  suggestions under it in groups, each class's auras, the enemies', the items'
--  (AuraSearch.lua); a click on one, or Enter for the first, puts it on the list,
--  lit, to tick. Under the list, what the game lets the marks do.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Lists = {}
ns.AuraLists = Lists

Lists.WIDTH, Lists.HEIGHT = 840, 520
Lists.INSET = 12
Lists.LINE = 26     -- a spell's line
Lists.ICON = 18
Lists.TICK = 24
Lists.COLUMN = 92   -- a mark's column, its tick in the middle
Lists.TOP = 56      -- from the window's top to the marks' words, under the search box
Lists.HEAD = 30     -- the marks' words over their columns, two lines at most
Lists.BAR = 24      -- the scroll bar's room at the list's right
Lists.WAIT = 0.15   -- seconds after the last key before the search runs
Lists.FIND = { width = 360, line = 20, icon = 16, lines = 16, per = 5 } -- the suggestions: a group shows per at least
Lists.KEYS = { white = "auraWhite", black = "auraBlack", hidden = "auraHidden", show = "auraShow", hide = "auraHide",
               kept = "auraKept" } -- the lists' settings; kept: the window's own, every spell put on it
Lists.ORDER = { "white", "black", "hidden", "show", "hide" }
Lists.COLUMNS = { "hidden", "black", "white", "hide", "show" } -- the window's ticks, left to right
Lists.WORDS = { white = "auraImportant", black = "auraUnimportant", hidden = "auraHidden",
                show = "auraFramesShow", hide = "auraFramesHide" } -- their words in ns.TEXT
Lists.SIDE = { white = "look", black = "look", hidden = "look", show = "frames", hide = "frames" }

local frame, window, box, status, scroll, child, empty, finder
local lines, finds = {}, {} -- the list's lines; the suggestions' lines
local names                 -- [a side][a spell's name] = its list, made when asked after a change
local rows                  -- the list as last shown: { id, name } each, by name
local fresh                 -- the name of the spell last put on it, lit
local first                 -- the first suggestion shown, for Enter

-- A list: { [spell number] = its name }.
local function List(which)
    local key = Lists.KEYS[which]
    ns.options[key] = type(ns.options[key]) == "table" and ns.options[key] or {}
    return ns.options[key]
end

-- A spell's picture, by its number.
local function Icon(id)
    local spells = rawget(_G, "C_Spell")
    return spells and id and Core.Ask(spells.GetSpellTexture, id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Every spell on the window's list or a mark, once by name, by name.
local function Rows()
    local found, by = {}, {}
    local function Add(id, name)
        name = tostring(name)
        if by[name] then return end
        by[name] = { id = tonumber(id), name = name }
        found[#found + 1] = by[name]
    end
    for id, name in pairs(List("kept")) do Add(id, name) end
    for _, which in ipairs(Lists.ORDER) do
        for id, name in pairs(List(which)) do Add(id, name) end
    end
    table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)
    return found, by
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
    rows = Rows()
    for index, row in ipairs(rows) do
        local line = lines[index] or Lists.Line(index)
        line.row = row
        line.icon:SetTexture(Icon(row.id))
        line.name:SetText(row.name)
        line.number:SetText(row.id or "")
        line.lit:SetShown(row.name == fresh)
        for which, tick in pairs(line.ticks) do tick:SetChecked(Side(Lists.SIDE[which], row.name) == which) end
        line:Show()
    end
    for index = #rows + 1, #lines do lines[index]:Hide() end
    empty:SetShown(rows[1] == nil)
    child:SetHeight(math.max(#rows * Lists.LINE, 1))
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

-- A spell off every list and the window's, by its name.
function Lists.Forget(name)
    for which in pairs(Lists.KEYS) do
        for id, spell in pairs(List(which)) do
            if spell == name then List(which)[id] = nil end
        end
    end
    if fresh == name then fresh = nil end
    Changed()
    if status then status:SetText(ns.TEXT.listsGone:format(name)) end
end

-- A menu's lines for an aura: the marks by side, one of each at most, a tick taken off again by a click; then the window.
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
    root:CreateButton(ns.TEXT.auraLists, ns.Guard(function() Lists.Open() end))
end

-- The menu of an aura or a spell ({ id, name, icon, harmful, unit }): a reminder, the marks, the window. Without one (the
-- game hides which aura it is, in a fight) it says so, and offers the window.
function Lists.Menu(owner, spell)
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        if spell then
            root:CreateTitle(spell.name)
            ns.Reminders.Entry(root, spell)
            Lists.Entries(root, spell)
        else
            root:CreateTitle(ns.TEXT.auraFight)
            root:CreateDivider()
            root:CreateButton(ns.TEXT.auraLists, ns.Guard(function() Lists.Open() end))
        end
    end))
end

local function Tip(owner, id, name)
    if not id then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if not pcall(GameTooltip.SetSpellByID, GameTooltip, id) then GameTooltip:SetText(name) end
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
--  The search
-------------------------------------------------------------------------------
local Suggest

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

-- A suggestion taken: on the window's list with no mark yet, lit and in sight.
local function Pick(entry)
    if not (entry and entry.id and entry.name) then return end
    local _, by = Rows()
    local there = by[entry.name] ~= nil
    if not there then List("kept")[entry.id] = entry.name end
    fresh = entry.name
    box:SetText("")
    box:ClearFocus()
    Suggest(nil)
    Fill()
    Reach(entry.name)
    status:SetText((there and ns.TEXT.listsThere or ns.TEXT.listsAdded):format(entry.name))
end

local function Find(index)
    local line = CreateFrame("Button", nil, finder)
    local F = Lists.FIND
    line:SetHeight(F.line)
    line:SetPoint("TOPLEFT", finder, "TOPLEFT", 4, -4 - (index - 1) * F.line)
    line:SetPoint("RIGHT", finder, "RIGHT", -4, 0)
    line.glow = line:CreateTexture(nil, "HIGHLIGHT")
    line.glow:SetAllPoints(line)
    line.glow:SetColorTexture(1, 1, 1, 0.1)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(F.icon, F.icon)
    line.icon:SetPoint("LEFT", 14, 0)
    line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line.text:SetPoint("RIGHT", line, "RIGHT", -4, 0)
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    line:SetScript("OnClick", ns.Guard(function(self) Pick(self.entry) end))
    line:SetScript("OnEnter", ns.Guard(function(self) if self.entry then Tip(self, self.entry.id, self.entry.name) end end))
    line:SetScript("OnLeave", GameTooltip_Hide)
    finds[index] = line
    return line
end

-- A suggestions' line: a group's title (its class's colour, how many it found) or one of its finds.
local function FindLine(index, entry, text, colour)
    local line = finds[index] or Find(index)
    line.entry = entry
    line:EnableMouse(entry ~= nil)
    line.glow:SetShown(entry ~= nil)
    line.icon:SetShown(entry ~= nil)
    line.text:ClearAllPoints()
    line.text:SetPoint("RIGHT", line, "RIGHT", -4, 0)
    if entry then
        line.icon:SetTexture(entry.icon or Icon(entry.id))
        line.text:SetFontObject("GameFontHighlight")
        line.text:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
    else
        line.text:SetFontObject("GameFontNormalSmall")
        line.text:SetPoint("LEFT", line, "LEFT", 2, 0)
    end
    line.text:SetText(colour and ("|cff%s%s|r"):format(colour, text) or text)
    line:Show()
end

-- What the search found under the box: each group's title, then its best finds; nil: none of it.
function Suggest(list)
    first = nil
    if not list then return finder:Hide() end
    local F = Lists.FIND
    local typed = box:GetText()
    local at = 0
    local groups = math.max(#list, 1)
    local per = math.max(F.per, math.floor((F.lines - groups) / groups))
    for _, group in ipairs(list) do
        local room = F.lines - at - 1
        if room < 1 then break end
        local count = math.min(#group.entries, per, room)
        local title = group.title or ""
        if #group.entries > count then title = ns.TEXT.searchMore:format(title, #group.entries) end
        at = at + 1
        FindLine(at, nil, title, group.colour)
        for index = 1, count do
            local entry = group.entries[index]
            at = at + 1
            FindLine(at, entry, ns.AuraSearch.Lit(entry, typed))
            first = first or entry
        end
    end
    if list.reading or at == 0 then
        at = at + 1
        FindLine(at, nil, list.reading and ns.TEXT.searchReading or ns.TEXT.searchNothing, "808080")
    end
    for index = at + 1, #finds do finds[index]:Hide() end
    finder:SetHeight(at * F.line + 8)
    finder:Show()
end

-- What is typed now, searched; the answer shown while it is still what is typed.
local function Search()
    if not frame or not frame:IsShown() then return end
    local text = box:GetText()
    ns.AuraSearch.Find(text, function(list)
        if frame:IsShown() and box:GetText() == text then Suggest(list) end
    end)
end
local Later = Core.Later(function() ns.Safe("aura lists", Search) end, Lists.WAIT, "Combat: aura lists")

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
-- The middle of a mark's column, from the list's right.
local function Middle(place)
    return -((#Lists.COLUMNS - place) * Lists.COLUMN + Lists.COLUMN / 2)
end

-- One line of the list, made as needed: the X, the icon, the name and number, a tick per mark.
function Lists.Line(index)
    local line = CreateFrame("Frame", nil, child)
    line:SetHeight(Lists.LINE)
    line:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(index - 1) * Lists.LINE)
    line:SetPoint("RIGHT", child, "RIGHT", 0, 0)
    line:EnableMouse(true)
    line:SetScript("OnEnter", ns.Guard(function(self) if self.row then Tip(self, self.row.id, self.row.name) end end))
    line:SetScript("OnLeave", GameTooltip_Hide)
    line.lit = line:CreateTexture(nil, "BACKGROUND")
    line.lit:SetAllPoints(line)
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
    take:SetScript("OnClick", ns.Guard(function() if line.row then Lists.Forget(line.row.name) end end))
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(Lists.ICON, Lists.ICON)
    line.icon:SetPoint("LEFT", take, "RIGHT", 4, 0)
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
    lines[index] = line
    return line
end

-- The search box and, over everything under it, the suggestions.
local function Searcher(inside, I)
    local label = inside:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", I, -I)
    label:SetText(ns.TEXT.listsInput)
    box = CreateFrame("EditBox", nil, inside, "InputBoxTemplate")
    box:SetSize(Lists.FIND.width - 6, 22)
    box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 6, -4)
    box:SetAutoFocus(false)
    box:SetScript("OnTextChanged", ns.Guard(function(_, typed) if typed then Later() end end))
    box:SetScript("OnEnterPressed", ns.Guard(function(self)
        if first then return Pick(first) end
        self:ClearFocus()
    end))
    box:SetScript("OnEscapePressed", ns.Guard(function(self)
        self:SetText("")
        self:ClearFocus()
        Suggest(nil)
    end))
    finder = CreateFrame("Frame", nil, inside)
    finder:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -2)
    finder:SetWidth(Lists.FIND.width)
    finder:SetFrameLevel((Plain(inside:GetFrameLevel()) or 1) + 20)
    finder:EnableMouse(true)
    local edge = finder:CreateTexture(nil, "BACKGROUND", nil, -1)
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(0.45, 0.4, 0.3, 1)
    local ground = finder:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(finder)
    ground:SetColorTexture(0.03, 0.03, 0.03, 0.97)
    finder:Hide()
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Lists.WIDTH, Lists.HEIGHT)
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
    scroll:SetPoint("BOTTOMRIGHT", inside, "BOTTOMRIGHT", -(I + Lists.BAR), I + 40)
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
    Searcher(inside, I)
    frame:HookScript("OnShow", ns.Guard(Fill))
    frame:HookScript("OnHide", ns.Guard(function()
        box:SetText("")
        Suggest(nil)
    end))
    window:Place()
end

-- The window; text: searched for at once, as if typed (/sane auras rejuv).
function Lists.Open(text)
    if ns.off then return end
    if not frame then Build() end
    status:SetText("")
    frame:Show()
    Fill()
    if type(text) == "string" and text:find("%S") then
        box:SetText(text)
        Search()
    end
end

function Lists.Toggle()
    if frame and frame:IsShown() then return frame:Hide() end
    Lists.Open()
end

-- Standing down: the window goes.
function Lists.Hide()
    if frame then frame:Hide() end
end
