local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Tabbed
--  A module's page of our own, in tabs, as the page Profiles has them: for a
--  module whose switches name their tab (option.tab; Core puts the page up,
--  Core.frames[module], and has it built the first time it is shown). Drawn from
--  the switches' descriptions alone:
--      tab       the tab it is in; those that name none are in the first, General
--      header    starts a titled box (Panel.Box) in its tab; headerTip is the tooltip
--                of the box's title
--      a switch  a checkbox; a number a slider, its value and unit beside it, or a
--                box to type it in (entry = true, or no ends); one of a few a
--                dropdown, several of a few (multi) a dropdown of checkboxes; words a
--                box to type them in; a colour (option.color, six hex digits) a swatch
--                that opens the game's colour picker; an action (button) a button.
--                Their words at the left, the control in a column right of them.
--      inline    a number on the line of its parent switch: [x] Fade in <slider> 0.40 seconds
--                (on a line of its own if that switch is no checkbox of the same tab)
--      parent    greyed out while that switch, or one it is under, is off; with
--                parentValue, while that one of a few is not set to that value
--      hidden    fn(settings): the line is not there while it says so, the lines
--                under it close up
--  Over the tabs, at the right of the title: a search box that finds a switch of the
--  page by its words (Core.Fuzzy), in every tab, and the button Defaults (it asks
--  first). A change goes through Core.Set: checked, told to the module, a /reload
--  offered where one is needed, shown on the page.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Panel = Config.Panel
local Fuzzy = Core.Fuzzy

local TEXT = {
    general = "General",
    defaults = Core.Word("SETTINGS_DEFAULTS", "Defaults"),
    defaultsTip = "Sets every setting of this page back to its default, in all its tabs. You are asked first.",
    askDefaults = "Set every setting of %s back to its default?",
    nothing = Core.Word("SETTINGS_SEARCH_NOTHING_FOUND", "Nothing found"),
    where = "%s, %s", -- a setting's tab, and the box it is in
}

local ROW = 30        -- a line in a box
local CHECK_X = 12    -- a checkbox, from the box's left edge
local TEXT_X = 42     -- words without a checkbox: under the checkboxes' words (CHECK_X, the box, 4 of room)
local CONTROL_X = 230 -- the column of sliders and dropdowns
local TOP = -96       -- the tabs' box, under the title and the tabs
local FOUND = 8       -- the most settings the search lists
local MATCH = 20      -- a line of that list
local OTHER = 300     -- a word found in a setting's tab, box or tooltip counts this much less than in its words

-- A line's control, its middle on the line's middle.
local function Place(control, box, x, y)
    control:ClearAllPoints()
    control:SetPoint("LEFT", box, "TOPLEFT", x, y - ROW / 2)
end

local function Words(box, text)
    local words = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    words:SetText(text)
    return words
end

-- The first key a switch is under (parent, or the first of its list).
local function Parent(option)
    if type(option.parent) == "table" then return option.parent[1] end
    return option.parent
end

-- The tabs, in the order they are first named; General first if a switch names none. Each tab:
-- { name, options = { option, ... } }: the switches with a control, and those with a header. A tab
-- with no control is none.
local function Tabs(list)
    local tabs, byName = {}, {}
    for _, option in ipairs(list) do
        local kind = Config.Kind(option)
        if kind or option.header then
            local name = option.tab or TEXT.general
            local tab = byName[name]
            if not tab then
                tab = { name = name, options = {} }
                byName[name] = tab
                if name == TEXT.general then table.insert(tabs, 1, tab) else tabs[#tabs + 1] = tab end
            end
            tab.options[#tab.options + 1] = option
            tab.controls = tab.controls or kind ~= nil
        end
    end
    for index = #tabs, 1, -1 do
        if not tabs[index].controls then table.remove(tabs, index) end
    end
    return tabs
end

-- The lines of one tab (state), each in the box of the header above it: a line is { option, box,
-- parts = { { widget, x, option } } }; a number inline is a part of its switch's line. Every switch
-- drawn is also a setting the search finds (state.entries).
local function Build(state)
    local name, byKey = state.name, state.byKey
    local function Get(option) -- the default if the module keeps none: a slider fails on none
        return function()
            local settings = Core.Settings(name)
            local value = settings and settings[option.key]
            if value == nil then return option.default end
            return value
        end
    end
    local function Set(option) return function(value) Core.Set(name, option.key, value) end end
    local function Enabled(option)
        if not option.parent then return nil end
        return function() return Config.Free(Core.Settings(name) or {}, byKey, option) end
    end
    -- The control right of a line's words, by its kind (Config.Kind).
    local function Control(box, option)
        local kind = Config.Kind(option)
        if kind == "slider" then
            return Panel.Slider(box, option.text, option.tip, option, Get(option), Set(option), Enabled(option))
        elseif kind == "choice" or kind == "multi" then
            return Panel.Dropdown(box, option.text, option.tip, option, Get(option), Set(option), Enabled(option))
        elseif kind == "color" then
            return Panel.Color(box, option.text, option.tip, Get(option), Set(option), Enabled(option))
        end
        return Panel.Edit(box, option.text, option.tip, option, Get(option), Set(option), Enabled(option))
    end
    -- The checkbox a number inline is drawn beside: its parent, a checkbox of this tab, one number
    -- each. Any other is on a line of its own.
    local inTab, beside, taken = {}, {}, {}
    for _, option in ipairs(state.tab.options) do inTab[option.key] = true end
    for _, option in ipairs(state.tab.options) do
        local kind, up = Config.Kind(option), Parent(option)
        local host = up and inTab[up] and byKey[up]
        if option.inline and (kind == "slider" or kind == "number") and host and Config.Kind(host) == "check" and not beside[up] then
            beside[up], taken[option.key] = option, true
        end
    end

    local boxes, box = {}, nil
    for _, option in ipairs(state.tab.options) do
        if option.header or not box then
            box = { frame = Panel.Box(state.child, option.header or "", -4, option.headerTip), title = option.header, lines = {} }
            boxes[#boxes + 1] = box
        end
        local kind = Config.Kind(option)
        if kind and not taken[option.key] then
            local frame, line = box.frame, { option = option, box = box, parts = {} }
            local function Part(widget, x, of)
                line.parts[#line.parts + 1] = { widget = widget, x = x, option = of or option }
                if of then state.entries[#state.entries + 1] = { option = of, line = line } end
            end
            state.entries[#state.entries + 1] = { option = option, line = line }
            if kind == "check" then
                Part(Panel.Check(frame, option.text, option.tip, Get(option), Set(option), Enabled(option)), CHECK_X)
                local number = beside[option.key]
                if number then Part(Control(frame, number), CONTROL_X, number) end
            elseif kind == "button" then
                local button = Panel.Button(frame, option.text, option.tip, function()
                    Core.Safe(name .. ": " .. option.key, option.button)
                end, Enabled(option))
                button:SetWidth(math.max(120, (button:GetTextWidth() or 0) + 40))
                Part(button, TEXT_X)
            else
                Part(Words(frame, option.text), TEXT_X)
                Part(Control(frame, option), CONTROL_X)
            end
            box.lines[#box.lines + 1] = line
            state.lines[#state.lines + 1] = line
        end
    end
    state.boxes = boxes
end

-- Puts the lines that are not hidden one under another, each box as high as its lines, the boxes
-- under each other (one with no line shown is not there at all); anew only when a line came or
-- went. A number inline that is hidden leaves its line. Returns the height they take.
local function Layout(state)
    if not state.boxes then return 1 end
    local changed = state.height == nil
    for _, line in ipairs(state.lines) do
        local shown = not Config.Hidden(state.name, line.option)
        if shown ~= line.shown then line.shown, changed = shown, true end
        for _, part in ipairs(line.parts) do
            local here = shown and (part.option == line.option or not Config.Hidden(state.name, part.option))
            if here ~= part.shown then
                part.shown = here
                part.widget:SetShown(here)
            end
        end
    end
    if not changed then return state.height end
    local top = -4
    for _, box in ipairs(state.boxes) do
        if box.mark then box.mark:Hide() end -- the line it marked may be elsewhere now
        local y = -6
        for _, line in ipairs(box.lines) do
            if line.shown then
                for _, part in ipairs(line.parts) do Place(part.widget, box.frame, part.x, y) end
                line.at, line.y = y, top - 18 + y -- in its box; from the top of what the tab holds
                y = y - ROW
            end
        end
        local any = y < -6
        Panel.ShowBox(box.frame, any)
        if any then
            local height = -y + 6
            Panel.PlaceBox(box.frame, top)
            box.frame:SetHeight(height)
            top = top - 18 - height - 16
        end
    end
    state.height = -top
    state.child:SetHeight(state.height)
    return state.height
end

-------------------------------------------------------------------------------
--  The search over the tabs
-------------------------------------------------------------------------------
-- How well what was typed fits a setting: each word in its words, in any of Core.Fuzzy's ways, or
-- else at the start of a word of its tab, its box's title or its tooltip (counted lower: OTHER); nil
-- if a word fits none.
local function Rank(query, entry)
    local total = 0
    for _, word in ipairs(query) do
        local best = Fuzzy.Rank(word, entry.option.text)
        for _, other in ipairs(entry.others) do
            local rank = Fuzzy.Rank(word, other)
            if rank and rank >= Fuzzy.WORD and (not best or rank - OTHER > best) then best = rank - OTHER end
        end
        if not best then return nil end
        total = total + best
    end
    return total
end

-- The letters of a setting's words that the words typed took, to show them in gold.
local function Spots(query, text)
    local all, spots = {}, {}
    for _, word in ipairs(query) do
        if Fuzzy.Rank(word, text, nil, spots) then
            for _, at in ipairs(spots) do all[#all + 1] = at end
        end
    end
    return all
end

-- A setting found: its tab shown, scrolled to its line, the line marked (until the search changes,
-- or the lines move).
local function Go(find, entry)
    local state, line = entry.state, entry.line
    find.group:SelectAtIndex(state.index)
    local part = find.parts[state.index]
    if part.scroll and line.y then
        local room = math.max((part.child:GetHeight() or 0) - (part.scroll:GetHeight() or 0), 0)
        part.scroll:SetVerticalScroll(math.min(math.max(-line.y - ROW, 0), room))
    end
    if find.marked then find.marked:Hide() end
    local box = line.box
    if not box.mark then
        box.mark = box.frame:CreateTexture(nil, "ARTWORK", nil, -1)
        box.mark:SetAtlas("search-highlight")
        box.mark:SetBlendMode("ADD")
    end
    box.mark:ClearAllPoints()
    box.mark:SetPoint("TOPLEFT", box.frame, "TOPLEFT", 4, line.at)
    box.mark:SetPoint("BOTTOMRIGHT", box.frame, "TOPRIGHT", -4, line.at - ROW)
    box.mark:Show()
    find.marked, find.went = box.mark, entry
end

-- The search box over the tabs, left of anchor, and the list of what it found under it: at every key
-- (a page has a few dozen settings) the best FOUND, the letters found in gold, each with its tab and
-- box; a click on one, or Enter for the first, goes to it (Go). A setting hidden now is not found.
local function Search(page, anchor, find)
    local search = CreateFrame("EditBox", nil, page, "SearchBoxTemplate")
    search:SetSize(200, 20)
    search:SetPoint("RIGHT", anchor, "LEFT", -12, 0)
    local list = CreateFrame("Frame", nil, page, "BackdropTemplate")
    Panel.Frame(list)
    list:SetPoint("TOPRIGHT", search, "BOTTOMRIGHT", 4, -4)
    list:SetWidth(320)
    list:SetFrameLevel(page:GetFrameLevel() + 20) -- over the tabs' box
    list:Hide()
    find.search, find.list, find.found = search, list, {}
    local found = find.found
    local rows = Core.Pool(function(_, index)
        local row = CreateFrame("Button", nil, list)
        row:SetHeight(MATCH)
        row:SetPoint("TOPLEFT", 4, -4 - (index - 1) * MATCH)
        row:SetPoint("RIGHT", -4, 0)
        row:SetHighlightAtlas("search-highlight", "ADD")
        row.Where = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        row.Where:SetPoint("RIGHT", -6, 0)
        row.Words = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.Words:SetPoint("LEFT", 6, 0)
        row.Words:SetPoint("RIGHT", row.Where, "LEFT", -8, 0)
        row.Words:SetJustifyH("LEFT")
        row.Words:SetWordWrap(false)
        row:SetScript("OnClick", function(self)
            if not self.entry then return end
            Go(find, self.entry)
            list:Hide()
            search:ClearFocus()
        end)
        return row
    end)
    find.rows = rows
    local function Look()
        if find.marked then find.marked:Hide() end
        for index = #found, 1, -1 do found[index] = nil end
        local query = Fuzzy.Query(search:GetText())
        if not query then
            list:Hide()
            return
        end
        for _, entry in ipairs(find.entries) do
            local here = entry.line.shown ~= false and not Config.Hidden(entry.state.name, entry.option)
            entry.rank = here and Rank(query, entry) or nil
            if entry.rank then found[#found + 1] = entry end
        end
        table.sort(found, function(a, b)
            if a.rank ~= b.rank then return a.rank > b.rank end
            return a.order < b.order
        end)
        rows:Begin()
        for index = 1, math.min(#found, FOUND) do
            local entry, row = found[index], rows:Take()
            row.entry = entry
            row.Words:SetText(Fuzzy.Highlight(entry.option.text, Spots(query, entry.option.text)))
            row.Where:SetText(entry.where)
            row:Show()
        end
        if #found == 0 then
            local row = rows:Take()
            row.entry = nil
            row.Words:SetText(TEXT.nothing)
            row.Where:SetText("")
            row:Show()
        end
        rows:Done()
        list:SetHeight(8 + rows.taken * MATCH)
        list:Show()
    end
    search:HookScript("OnTextChanged", Look)
    search:HookScript("OnEnterPressed", function(self)
        if found[1] then Go(find, found[1]) end
        list:Hide()
        self:ClearFocus()
    end)
    search:HookScript("OnEscapePressed", function() list:Hide() end)
    search:HookScript("OnEditFocusGained", function(self)
        if (self:GetText() or "") ~= "" then Look() end
    end)
    page:HookScript("OnHide", function() list:Hide() end)
    return search
end

-- Builds a module's page into the frame Core put up for it: its title, the search box and Defaults,
-- the tabs (Panel.TabbedFrame), each a scroll area of boxes.
function Config.BuildTabbed(page, name)
    local list = Core.described[name].list
    local byKey = {}
    for _, option in ipairs(list) do byKey[option.key] = option end
    local module = SaneUI[name]
    local title = module and module.title or name
    Panel.Header(page, title)

    local states, tabs = {}, {}
    for index, tab in ipairs(Tabs(list)) do
        local state = { name = name, index = index, tab = tab, byKey = byKey, lines = {}, entries = {} }
        states[index] = state
        tabs[index] = { name = tab.name, label = ("Settings: %s %s"):format(name, tab.name), build = function(child)
            state.child = child
            Build(state)
            return Layout(state)
        end }
    end
    local _, parts, group = Panel.TabbedFrame(page, tabs, TOP)
    -- When the page shows its values anew, a line that came or went (hidden) closes up the others.
    Panel.Watch({ widget = page, Refresh = function()
        for _, state in ipairs(states) do Layout(state) end
    end })

    -- Defaults: every setting of the module back to its default (Core.Reset), after asking; the game's
    -- own Defaults (All settings) does the same through the page's OnDefault (Settings.lua).
    local defaults = Panel.Button(page, TEXT.defaults, TEXT.defaultsTip, function()
        Core.Confirm(TEXT.askDefaults, title, function() Core.Reset(name) end, true)
    end, nil, 96)
    defaults:SetPoint("TOPRIGHT", -36, -16)

    local find = { group = group, parts = parts, entries = {} }
    for _, state in ipairs(states) do
        for _, entry in ipairs(state.entries) do
            local box = entry.line.box.title
            entry.state, entry.order = state, #find.entries + 1
            entry.where = box and TEXT.where:format(state.tab.name, box) or state.tab.name
            entry.others = { state.tab.name }
            if box then entry.others[#entry.others + 1] = box end
            if type(entry.option.tip) == "string" then entry.others[#entry.others + 1] = entry.option.tip end
            find.entries[#find.entries + 1] = entry
        end
    end
    page.find = find
    Search(page, defaults, find)
end
