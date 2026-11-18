-------------------------------------------------------------------------------
--  Sane UI - Core - SpellSearch
--  The search over every spell Sane UI knows (Core's for every module since
--  2026-11-18, when the full screen went to Abilities: Combat's aura lists and
--  reminders ask it for auras, Abilities' Sane Macros for any spell), in
--  groups: each class's auras (the spells of its class lines that put an aura
--  on: Core's sets SkillLines and Spells), the enemies' (CreatureSpells) and
--  those of food, potions, elixirs, items and the world (Auras). One entry per
--  name in a group, whatever its rank, as the lists mark auras by name. Read
--  once, at the first search: the classes at once, the other two a part per
--  frame, out of a fight (Data's jobs); a search asked for meanwhile runs when
--  they are read.
--
--  Typed, a spell's number finds that spell wherever the game knows it, first.
--  Without the sets (Retail, until its data comes) a name finds only a spell of
--  your own, as the game knows it by name.
--
--  A search is Core's (Fuzzy): forgiving, ranked. The groups come in the order
--  of their best find, your own class first where two are as good, and within a
--  group the best first.
--
--  The box that asks it (Search.Box) is Combat's aura lists' window's and its
--  reminders' window's: what is typed searched a moment after the last key, the
--  finds under it in their groups, over everything below it; a click on one, or
--  Enter for the first, picks it; the mouse on one shows its tooltip. Up and
--  Down light one as the mouse would, round at the ends, and Enter picks the lit
--  one (Core.Fuzzy.Keys; Saneroki, 2026-11-09). Sane
--  Macros' step hands it a box of its own and its own search (any spell), the
--  finds flying up over the steps (Abilities' Macros/Detail.lua, Macros/Spells.lua).
--  Every door of the box is Core.Gently's: a search never stands a module down.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Search = {}
Core.SpellSearch = Search

Search.TEXT = {
    searchEnemies = "Enemies",
    searchItems = "Food, potions, items and the world",
    searchNumber = "By its number",
    searchYours = "Your spells",
    searchMore = "%s (%d)",
    searchReading = "Reading every class's spells...",
    searchNothing = "Nothing found.",
}

Search.CLASSES = 20 -- the class numbers looked at, from 1: the game's, and room for more
Search.ENEMIES, Search.ITEMS = 100, 101 -- the two groups' places after the classes
Search.WAIT = 0.15  -- seconds after the last key before a box's search runs
Search.FIND = { line = 20, icon = 16, lines = 16, per = 5 } -- a box's suggestions: a group shows per at least

local entries, groups -- what is searched: { id, name, icon, group } each; the groups by key
local reading = 0     -- the jobs still reading a set
local pending         -- the newest search asked for while they read

-- Whether a spell's record puts an aura on: one of its effects does. A spell the set holds no effects of counts.
local function Aura(record)
    local effects = record.effects
    if type(effects) ~= "table" then return true end
    for _, effect in pairs(effects) do
        if type(effect) == "table" and (tonumber(effect.aura) or 0) > 0 then return true end
    end
    return false
end

local function Group(key, title, colour, order)
    local group = { key = key, title = title, colour = colour, order = order, names = {} }
    groups[key] = group
    return group
end

-- An entry of a group, once per name.
local function Add(group, id, name, icon)
    if type(name) ~= "string" or name == "" or group.names[name] then return end
    group.names[name] = true
    entries[#entries + 1] = { id = id, name = name, icon = icon, group = group }
end

-- The players' auras, class by class: the spells of each class line.
local function Classes()
    local Data = Core.Data
    local classes, lines, spells = Data.Set("Classes"), Data.Set("SkillLines"), Data.Set("Spells")
    if not (classes:Ready() and lines:Ready() and spells:Ready()) then return end
    local _, mine = Core.Ask(UnitClass, "player")
    for id = 1, Search.CLASSES do
        local class = classes:Get(id)
        if class then
            local group = Group("class" .. id, class.name or class.file, class.color, id)
            group.own = class.file ~= nil and class.file == mine
            for _, line in ipairs(lines:Keys("byClass", id)) do
                local record = lines:Get(line)
                if record and record.kind == "class" then
                    for _, spell in pairs(record.spells or {}) do
                        local found = spells:Get(spell)
                        if found and Aura(found) then Add(group, spell, found.name, found.icon) end
                    end
                end
            end
        end
    end
end

-- A set read: the search asked for meanwhile runs once all are.
local function Finished()
    reading = reading - 1
    if reading > 0 or not pending then return end
    local again = pending
    pending = nil
    again()
end

-- A set read into its group a part per frame.
local function Walk(name, group)
    local set = Core.Data.Set(name)
    local job = set:Ready() and set:Each(function(key, record) Add(group, key, record.name, record.icon) end, Finished)
    if job then reading = reading + 1 end
end

-- Everything to search, once; again later while Core is still reading its own files.
local function Gather()
    if entries then return end
    if Core.Data.Set("Spells"):State() == "loading" then return end
    entries, groups = {}, {}
    Classes()
    local TEXT = Search.TEXT
    Walk("CreatureSpells", Group("enemies", TEXT.searchEnemies, nil, Search.ENEMIES))
    Walk("Auras", Group("items", TEXT.searchItems, nil, Search.ITEMS))
end

-- What the game itself finds by the text: the spell of that number, or (without the sets) a spell of yours by name.
local function Typed(text)
    local spells = rawget(_G, "C_Spell")
    if not spells then return nil end
    local id = tonumber(text)
    local name, title
    if id then
        name, title = Core.Ask(spells.GetSpellName, id), Search.TEXT.searchNumber
    elseif not (entries and entries[1]) then
        local info = Core.Ask(spells.GetSpellInfo, text)
        id = type(info) == "table" and Plain(info.spellID) or nil
        name, title = id and Plain(info.name), Search.TEXT.searchYours
    end
    if type(name) ~= "string" or type(id) ~= "number" then return nil end
    local entry = { id = id, name = name, icon = Core.Ask(spells.GetSpellTexture, id) }
    return { title = title, entries = { entry } }
end

local function Better(a, b)
    if a.rank ~= b.rank then return a.rank > b.rank end
    return a.name < b.name
end

local function First(a, b)
    if a.best ~= b.best then return a.best > b.best end
    if (a.group.own or false) ~= (b.group.own or false) then return a.group.own == true end
    return a.group.order < b.group.order
end

-- The entries found, by group: { title, colour, entries } each, in the order they come. Each entry's group: { title,
-- colour, order, own }; Sane Macros' spell search groups its own the same way (Search.Grouped).
local function Grouped(found, ranks, typed)
    local list, by = {}, {}
    for index, entry in ipairs(found or {}) do
        local group = entry.group
        local shown = by[group]
        if not shown then
            shown = { group = group, title = group.title, colour = group.colour, best = 0, entries = {} }
            by[group] = shown
            list[#list + 1] = shown
        end
        entry.rank = ranks[index] or 0
        shown.entries[#shown.entries + 1] = entry
        if entry.rank > shown.best then shown.best = entry.rank end
    end
    for _, shown in ipairs(list) do table.sort(shown.entries, Better) end
    table.sort(list, First)
    if typed then table.insert(list, 1, typed) end
    return list
end
Search.Grouped = Grouped

-- A search: done(list) with the groups found (an empty list: nothing; nil: nothing typed). While the sets are read
-- the list holds what the game found by itself, list.reading is true, and done is told again once they are read.
function Search.Find(text, done)
    text = (text or ""):match("^%s*(.-)%s*$")
    local query = Core.Fuzzy.Query(text)
    if not query then
        pending = nil
        return done(nil)
    end
    Gather()
    local typed = Typed(text)
    if not entries or reading > 0 then
        pending = function() Search.Find(text, done) end
        local list = { typed }
        list.reading = true
        return done(list)
    end
    pending = nil
    Core.Fuzzy.Filter(entries, query, { "name" }, function(found, ranks) done(Grouped(found, ranks, typed)) end)
end

-- The shown entry's name with what was typed in it in the game's gold.
function Search.Lit(entry, text)
    local query = Core.Fuzzy.Query(text)
    if not query then return entry.name end
    local spots, all = {}, {}
    for _, word in ipairs(query) do
        if Core.Fuzzy.Rank(word, entry.name, nil, spots) then
            for _, at in ipairs(spots) do all[#all + 1] = at end
        end
    end
    return Core.Fuzzy.Highlight(entry.name, all)
end

-- A spell's picture, by its number.
function Search.Icon(id)
    local spells = rawget(_G, "C_Spell")
    return spells and id and Core.Ask(spells.GetSpellTexture, id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- A spell's tooltip by owner; its name alone where the game does not know it.
function Search.Tip(owner, id, name)
    if not id then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if not pcall(GameTooltip.SetSpellByID, GameTooltip, id) then GameTooltip:SetText(name) end
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
--  The box
-------------------------------------------------------------------------------
local Box = {}
Box.__index = Box

-- One of the suggestions' lines.
function Box:Line(index)
    local F = Search.FIND
    local line = CreateFrame("Button", nil, self.finder)
    line:SetHeight(F.line)
    line:SetPoint("TOPLEFT", self.finder, "TOPLEFT", 4, -4 - (index - 1) * F.line)
    line:SetPoint("RIGHT", self.finder, "RIGHT", -4, 0)
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
    line:SetScript("OnClick", Core.Gently("aura search", function(button) self:Pick(button.entry) end))
    line:SetScript("OnEnter", Core.Gently("aura search", function(button)
        if button.entry then Search.Tip(button, button.entry.id, button.entry.name) end
    end))
    line:SetScript("OnLeave", GameTooltip_Hide)
    self.lines[index] = line
    return line
end

-- A suggestions' line: a group's title (its class's colour, how many it found) or one of its finds.
function Box:Fill(index, entry, text, colour)
    local line = self.lines[index] or self:Line(index)
    line.entry = entry
    line:EnableMouse(entry ~= nil)
    line.glow:SetShown(entry ~= nil)
    line.icon:SetShown(entry ~= nil)
    line.text:ClearAllPoints()
    line.text:SetPoint("RIGHT", line, "RIGHT", -4, 0)
    if entry then
        line.icon:SetTexture(entry.icon or Search.Icon(entry.id))
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
function Box:Show(list)
    self.first = nil
    self.keys:Rows(nil)
    if not list then return self.finder:Hide() end
    local F = Search.FIND
    local typed = self.box:GetText()
    local at, most, finds = 0, self.most, {}
    local per = math.max(F.per, math.floor((most - math.max(#list, 1)) / math.max(#list, 1)))
    for _, group in ipairs(list) do
        local room = most - at - 1
        if room < 1 then break end
        local count = math.min(#group.entries, per, room)
        local title = group.title or ""
        if #group.entries > count then title = Search.TEXT.searchMore:format(title, #group.entries) end
        at = at + 1
        self:Fill(at, nil, title, group.colour)
        for index = 1, count do
            local entry = group.entries[index]
            at = at + 1
            self:Fill(at, entry, Search.Lit(entry, typed))
            finds[#finds + 1] = self.lines[at]
            self.first = self.first or entry
        end
    end
    if list.reading or at == 0 then
        at = at + 1
        self:Fill(at, nil, list.reading and Search.TEXT.searchReading or Search.TEXT.searchNothing, "808080")
    end
    for index = at + 1, #self.lines do self.lines[index]:Hide() end
    self.finder:SetHeight(at * F.line + 8)
    self.finder:Show()
    self.keys:Rows(finds)
end

-- What is typed now, searched; the answer shown while the box is in sight and it is still what is typed.
function Box:Run()
    if Plain(self.box:IsVisible()) ~= true then return end
    local text = self.box:GetText()
    self.find(text, function(list)
        if Plain(self.box:IsVisible()) == true and self.box:GetText() == text then self:Show(list) end
    end)
end

-- Nothing typed, nothing suggested.
function Box:Clear()
    self.box:SetText("")
    self.box:ClearFocus()
    self:Show(nil)
end

-- A suggestion taken: the box empty again (one handed over keeps its text: its pick writes it), then its window's pick.
function Box:Pick(entry)
    if not (entry and entry.id and entry.name) then return end
    if self.own then self:Clear() else self:Show(nil) end
    self.pick(entry)
end

-- Searched at once, as if typed.
function Box:Search(text)
    self.box:SetText(text)
    self:Run()
end

-- A search box on parent, its words over it with their top left at (x, y) from the parent's: opts = { words, width,
-- pick(entry): a suggestion taken, label: a name for an error's place }. Returns it: { box, words, finder, ... }.
-- Or a box of the caller's (opts.box; no words, x and y unused), whose own scripts stay and whose text a pick does not
-- empty: opts.find(text, done) its search (as Search.Find), opts.up the finds over it, opts.lines how many at most.
function Search.Box(parent, x, y, opts)
    local self = setmetatable({ lines = {}, pick = opts.pick, find = opts.find or Search.Find,
                                most = opts.lines or Search.FIND.lines, own = opts.box == nil }, Box)
    local box, words = opts.box, nil
    -- A box of its own takes the scripts; one handed over keeps its own and gets these after them.
    local Script = function(frame, name, fn) frame:SetScript(name, fn) end -- guarded: every fn below is Core.Gently's (a search)
    if box then
        Script = function(frame, name, fn) frame:HookScript(name, fn) end -- guarded: every fn below is Core.Gently's (a search)
    else
        words = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        words:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        words:SetText(opts.words)
        box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        box:SetSize(opts.width - 6, 22)
        box:SetPoint("TOPLEFT", words, "BOTTOMLEFT", 6, -4)
        box:SetAutoFocus(false)
    end
    self.keys = Core.Fuzzy.Keys(box)
    local later = Core.Later(function() Core.Safe(opts.label, Box.Run, self) end, Search.WAIT, "spell search: " .. opts.label)
    Script(box, "OnTextChanged", Core.Gently("aura search", function(_, typed) if typed then later() end end))
    Script(box, "OnEnterPressed", Core.Gently("aura search", function(edit)
        if self.keys:Take() then return end -- the one lit by the arrows, as a click
        if self.first then return self:Pick(self.first) end
        edit:ClearFocus()
    end))
    Script(box, "OnEscapePressed", Core.Gently("aura search", function()
        if self.own then self:Clear() else self:Show(nil) end
    end))
    local finder = CreateFrame("Frame", nil, parent)
    if opts.up then
        finder:SetPoint("BOTTOMLEFT", box, "TOPLEFT", -6, 2)
    else
        finder:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -2)
    end
    finder:SetWidth(opts.width)
    finder:SetFrameLevel((Plain(parent:GetFrameLevel()) or 1) + 20)
    finder:EnableMouse(true)
    local edge = finder:CreateTexture(nil, "BACKGROUND", nil, -1)
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(0.45, 0.4, 0.3, 1)
    local ground = finder:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(finder)
    ground:SetColorTexture(0.03, 0.03, 0.03, 0.97)
    finder:Hide()
    self.box, self.words, self.finder = box, words, finder
    return self
end
