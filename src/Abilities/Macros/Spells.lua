local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Macros - Spells
--  The spell window (Saneroki, 2026-11-07: "big spell window on the plus"): the
--  + beside a spell step's name opens it over whatever shows, the full screen
--  too, as the picture window does (Core's icon chooser, Core.Icons). On the left the groups: the
--  spells this character knows, each tab of its spellbook (the game's own book's
--  tabs, BookData.Tabs), each class's spells (its own first; Core's sets
--  Classes, SkillLines and Spells) and all of them; at the top a search over
--  their names; then the spells, picture and name. The mouse on one shows the
--  game's tooltip; a click puts it in the step and closes the window.
--
--  The same spells fly out under the name's box while it is typed in (Detail.lua,
--  by Core's spell search's box, Core's SpellSearch.lua): the best first, yours before
--  your class's before the others' where two are as good.
--
--  No passives (nothing to cast) and one entry per name, the highest rank: a
--  step casts its spell by name. Retail, without the sets until its data comes,
--  has the spellbook's alone. The class groups are read once, the first time
--  the sets are there; the spellbook's at every opening, as it changes.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Spells = {}
Macros.Spells = Spells

Spells.TILE = { 220, 40 } -- a spell in the grid: its width and height
Spells.ICON = 34
Spells.GAP = 6
Spells.CLASSES = 20       -- the class numbers looked at, from 1: the game's, and room for more

local frame, window, built, search, count, box, empty
local groupLines = {}
local groups        -- the groups shown: { key, title, colour, list } each
local finds         -- for the fly-out: every name once, in its best group: { id, name, icon, group }
local classGroups   -- every class's spells, read once from Core's sets
local chosenGroup = "known"
local done          -- what to do with the spell clicked
local typed = 0     -- when a key was last typed

-- The number of a rank's words ("Rank 3"); 0 without.
local function Level(rank)
    return tonumber(type(rank) == "string" and rank:match("(%d+)") or nil) or 0
end

-- An entry of a list, once per name: the highest rank's.
local function Put(list, seen, id, name, icon, level)
    if type(name) ~= "string" or name == "" or type(id) ~= "number" then return end
    local entry = seen[name]
    if entry then
        if level > entry.level then entry.id, entry.icon, entry.level = id, icon or entry.icon, level end
        return
    end
    entry = { id = id, name = name, icon = icon, level = level }
    seen[name] = entry
    list[#list + 1] = entry
end

local function ByName(a, b)
    return a.name < b.name
end

-- What this character knows, as its spellbook's tabs hold it: all of it, and a group per tab.
local function Known()
    local all, tabs, allSeen = {}, {}, {}
    local book, enum = rawget(_G, "C_SpellBook"), rawget(_G, "Enum")
    local spell = enum and enum.SpellBookItemType and enum.SpellBookItemType.Spell
    if not (book and ns.SpellbookData) then return all, tabs end
    for _, tab in ipairs(ns.SpellbookData.Tabs()) do
        if tab.bank then
            local list, seen = {}, {}
            for slot = tab.first, tab.first + tab.count - 1 do
                local item = Core.Ask(book.GetSpellBookItemInfo, slot, tab.bank)
                local castable = type(item) == "table" and (spell == nil or Plain(item.itemType) == spell)
                    and not Plain(item.isPassive) and not Plain(item.isOffSpec)
                    and not Core.Ask(book.IsSpellBookItemLowRank, slot, tab.bank)
                if castable then
                    local id, name, icon = Plain(item.spellID), Plain(item.name), Plain(item.iconID)
                    Put(list, seen, id, name, icon, 0)
                    Put(all, allSeen, id, name, icon, 0)
                end
            end
            table.sort(list, ByName)
            if list[1] then tabs[#tabs + 1] = { key = tab.key, title = tab.name, list = list } end
        end
    end
    table.sort(all, ByName)
    return all, tabs
end

-- Every class's spells from Core's sets, its own first: nil while Core still reads its files, none without the sets.
local function Classes()
    if classGroups then return classGroups end
    local Data = Core.Data
    local classes, lines, spells = Data.Set("Classes"), Data.Set("SkillLines"), Data.Set("Spells")
    if spells:State() == "loading" then return nil end
    classGroups = {}
    if not (classes:Ready() and lines:Ready() and spells:Ready()) then return classGroups end
    local passive = rawget(_G, "C_Spell") and C_Spell.IsSpellPassive
    local _, mine = Core.Ask(UnitClass, "player")
    for id = 1, Spells.CLASSES do
        local class = classes:Get(id)
        if class then
            local group = { key = "class" .. id, title = class.name or class.file, colour = class.color, order = id,
                            own = class.file ~= nil and class.file == mine, list = {} }
            local seen = {}
            for _, line in ipairs(lines:Keys("byClass", id)) do
                local record = lines:Get(line)
                if record and record.kind == "class" then
                    for _, number in pairs(record.spells or {}) do
                        local found = spells:Get(number)
                        if found and not Core.Ask(passive, number) then
                            Put(group.list, seen, number, found.name, found.icon, Level(found.rank))
                        end
                    end
                end
            end
            table.sort(group.list, ByName)
            if group.list[1] then classGroups[#classGroups + 1] = group end
        end
    end
    table.sort(classGroups, function(a, b)
        if a.own ~= b.own then return a.own end
        return a.order < b.order
    end)
    return classGroups
end

-- Everything, again: the spellbook's now, the classes' once read; the groups shown and the fly-out's finds.
function Spells.Gather()
    local known, tabs = Known()
    local TEXT = Macros.TEXT
    local yours = { key = "known", title = TEXT.spellsYours, list = known, own = true, order = 0 }
    groups = { yours }
    for _, tab in ipairs(tabs) do groups[#groups + 1] = tab end
    finds = {}
    local seen = {}
    local function Find(entry, group)
        if seen[entry.name] then return end
        seen[entry.name] = true
        finds[#finds + 1] = { id = entry.id, name = entry.name, icon = entry.icon, group = group }
    end
    for _, entry in ipairs(known) do Find(entry, yours) end
    for _, group in ipairs(Classes() or {}) do
        groups[#groups + 1] = group
        for _, entry in ipairs(group.list) do Find(entry, group) end
    end
    local all = {}
    for _, find in ipairs(finds) do all[#all + 1] = find end
    table.sort(all, ByName)
    groups[#groups + 1] = { key = "all", title = TEXT.spellsAll, list = all }
end

-- For the fly-out under a name's box (Core's spell search's box): done(list) with the groups found, nil with nothing typed.
function Spells.Find(text, done)
    local query = Core.Fuzzy.Query((text or ""):match("^%s*(.-)%s*$"))
    if not query then return done(nil) end
    Spells.Gather()
    Core.Fuzzy.Filter(finds, query, { "name" }, function(found, ranks) done(Core.SpellSearch.Grouped(found, ranks)) end)
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
local function Picked(button)
    local entry = button.entry
    if not (entry and done) then return end
    local give = done
    Spells.Close()
    give(entry)
end

local function Enter(button)
    local entry = button.entry
    local tip = rawget(_G, "GameTooltip")
    if not (entry and tip) then return end
    tip:SetOwner(button, "ANCHOR_RIGHT")
    if not pcall(tip.SetSpellByID, tip, entry.id) then tip:SetText(entry.name, 1, 1, 1) end
    tip:AddLine(Macros.TEXT.spellsClick, 0.6, 0.6, 0.6)
    tip:Show()
end

-- One spell of the grid: the view hands its buttons round, so each is dressed whole.
local function Dress(button, entry)
    if not button.icon then
        button:SetSize(Spells.TILE[1], Spells.TILE[2])
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(Spells.ICON, Spells.ICON)
        button.icon:SetPoint("LEFT", 3, 0)
        button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        button.name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.name:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
        button.name:SetPoint("RIGHT", -4, 0)
        button.name:SetJustifyH("LEFT")
        button.name:SetWordWrap(true)
        local lit = button:CreateTexture(nil, "HIGHLIGHT")
        lit:SetAllPoints()
        lit:SetColorTexture(1, 1, 1, 0.08)
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", ns.Guard(Picked))
        button:SetScript("OnEnter", ns.Guard(Enter))
        button:SetScript("OnLeave", ns.Guard(Core.HideTip))
    end
    button.entry = entry
    button.icon:SetTexture(entry.icon or Core.SpellSearch.Icon(entry.id))
    button.name:SetText(entry.name)
end

local function Show(list)
    if not box then return end
    box:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.DiscardScrollPosition)
    count:SetText(Macros.TEXT.spellsCount:format(#list))
    empty:SetShown(#list == 0)
end

local function GroupOf(key)
    for _, group in ipairs(groups or {}) do
        if group.key == key then return group end
    end
    return groups and groups[1]
end

-- The group chosen, searched by what is typed.
local function Search()
    if not groups then return end
    if GetTime() - typed < Macros.Icons.WAIT then return Spells.later() end
    local group = GroupOf(chosenGroup)
    local list = group and group.list or {}
    local query = Core.Fuzzy.Query(search:GetText())
    if not query then return Show(list) end
    Core.Fuzzy.Filter(list, query, { "name" }, function(found) Show(found) end)
end
Spells.later = Core.Later(function() ns.Safe("macros", Search) end, Macros.Icons.WAIT, "Macros: spells")

-- The groups' lines, their counts, the one chosen lit; a class's in its colour.
local function Lines()
    local row = Macros.Icons.ROW
    for index, group in ipairs(groups or {}) do
        local line = groupLines[index]
        if not line then
            line = CreateFrame("Button", nil, built.side)
            line:SetHeight(row)
            line:SetPoint("TOPLEFT", 0, -(index - 1) * row)
            line:SetPoint("RIGHT")
            line.mark = line:CreateTexture(nil, "BACKGROUND")
            line.mark:SetAllPoints()
            line.mark:SetColorTexture(1, 0.82, 0, 0.16)
            local lit = line:CreateTexture(nil, "HIGHLIGHT")
            lit:SetAllPoints()
            lit:SetColorTexture(1, 1, 1, 0.08)
            line.title = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            line.title:SetPoint("LEFT", 8, 0)
            line.count = line:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            line.count:SetPoint("RIGHT", -6, 0)
            line:SetScript("OnClick", ns.Guard(function(self)
                chosenGroup = self.key
                Lines()
                typed = 0
                Search()
            end))
            groupLines[index] = line
        end
        line.key = group.key
        line.title:SetText(group.colour and ("|cff%s%s|r"):format(group.colour, group.title) or group.title)
        line.count:SetText(#group.list)
        line.mark:SetShown(group.key == (GroupOf(chosenGroup) or {}).key)
        line:Show()
    end
    for index = #(groups or {}) + 1, #groupLines do groupLines[index]:Hide() end
end

local function Fill()
    if not built then return end
    Spells.Gather()
    Lines()
    typed = 0
    Search()
end

local function Build()
    local I, Icons = Macros.Editor.INSET, Core.Icons -- the picture window's sizes (Core's icon chooser)
    frame = CreateFrame("Frame", nil, UIParent)
    local width = math.min(Icons.LARGEST[1], (UIParent:GetWidth() or 1200) * Icons.SHARE[1])
    local height = math.min(Icons.LARGEST[2], (UIParent:GetHeight() or 800) * Icons.SHARE[2])
    frame:SetSize(math.floor(width), math.floor(height))
    frame:SetFrameStrata(Icons.STRATA)
    -- Under Core's plate, which lets a little through: over a busy full screen the spells read clean.
    local under = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    under:SetAllPoints()
    under:SetColorTexture(Icons.UNDER[1], Icons.UNDER[2], Icons.UNDER[3], Icons.UNDER[4])
    frame:EnableMouse(true) -- clicks on it stay on it
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = Macros.store, key = "spells", title = Macros.TEXT.spellsTitle, edge = false, dock = false,
        sizable = false, first = { point = "CENTER", x = 0, y = 0 },
        close = function() frame:Hide() end,
    })
    local inside = window.inside
    built = {}
    search = CreateFrame("EditBox", nil, inside, "SearchBoxTemplate")
    search:SetSize(320, 22)
    search:SetPoint("TOPLEFT", I + Icons.SIDE + I + 6, -I)
    search:SetAutoFocus(false)
    local hint = rawget(search, "Instructions") -- the game's grey words in the empty box
    if type(hint) == "table" then hint:SetText(Macros.TEXT.spellsSearch) end
    search:HookScript("OnTextChanged", ns.Gently("spell search", function(_, user) -- (a search: gentle, its error stands no module down; Core.Gently)
        if not user then return end
        typed = GetTime()
        Spells.later()
    end))
    count = inside:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetPoint("LEFT", search, "RIGHT", 12, 0)
    built.side = CreateFrame("Frame", nil, inside)
    built.side:SetPoint("TOPLEFT", I, -I)
    built.side:SetPoint("BOTTOM", 0, I)
    built.side:SetWidth(Icons.SIDE)
    box = CreateFrame("Frame", nil, inside, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", I + Icons.SIDE + I, -I - 32)
    box:SetPoint("BOTTOMRIGHT", -I - 18, I)
    local bar = CreateFrame("EventFrame", nil, inside, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 6, 0)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 6, 0)
    local view = CreateScrollBoxListGridView(1, 4, 4, 4, 4, Spells.GAP, Spells.GAP)
    view:SetElementSize(Spells.TILE[1], Spells.TILE[2])
    view:SetStrideExtent(Spells.TILE[1])
    view:SetElementInitializer("Button", ns.Guard(Dress))
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    empty = inside:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", box, "TOP", 0, -40)
    empty:SetText(Macros.TEXT.spellsNone)
    frame:HookScript("OnHide", ns.Guard(function()
        done = nil
        Core.HideTip()
    end))
    window:Place()
end

-- Opens the window: given(entry) with the spell clicked ({ id, name, icon }).
function Spells.Open(given)
    if ns.off then return end
    if not frame then Build() end
    done = given
    frame:Show()
    frame:Raise()
    Fill()
    Core.Sound("IG_CHARACTER_INFO_OPEN")
end

function Spells.Close()
    if frame and frame:IsShown() then
        frame:Hide()
        Core.Sound("IG_CHARACTER_INFO_CLOSE")
    end
end

function Spells.Shown()
    return frame ~= nil and frame:IsShown()
end

-- For the test.
function Spells.Frame() return frame end
function Spells.Groups() return groups end
function Spells.Box() return box end
function Spells.Search() return search end
function Spells.GroupLine(index) return groupLines[index] end
function Spells.Forget() classGroups, groups, finds = nil, nil, nil end
