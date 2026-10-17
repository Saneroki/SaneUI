local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Tabbed
--  A module's page of our own, in tabs, as the page Profiles has them: for a
--  module whose switches name their tab (option.tab; Core puts the page up,
--  Core.frames[module]). Drawn from the switches' descriptions alone:
--      tab       the tab it is in; those that name none are in the first, General
--      header    starts a titled box (Panel.Box) in its tab
--      a switch  a checkbox; a number a slider, its value and unit beside it; one of
--                a few a dropdown. Their words at the left, the slider or dropdown in
--                a column right of them. A colour (option.color, six hex digits) a
--                swatch in that column that opens the game's colour picker.
--      inline    a number on the line of its parent switch: [x] Fade in <slider> 0.40 seconds
--      parent    greyed out while that switch, or one it is under, is off; with
--                parentValue, while that one of a few is not set to that value
--  A change is written into the module's settings and told to the module, as
--  on the game's own pages (Settings.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Panel = Config.Panel

local TEXT = { general = "General" }

local ROW = 30       -- a line in a box
local CHECK_X = 12   -- a checkbox, from the box's left edge
local TEXT_X = 42    -- words without a checkbox: under the checkboxes' words (CHECK_X, the box, 4 of room)
local CONTROL_X = 230 -- the column of sliders and dropdowns

-- A line's control, its middle on the line's middle.
local function Place(control, box, x, y)
    control:SetPoint("LEFT", box, "TOPLEFT", x, y - ROW / 2)
end

local function Words(box, text, y)
    local words = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Place(words, box, TEXT_X, y)
    words:SetText(text)
    return words
end

-- The tabs, in the order they are first named; General first if a switch names none. Each tab:
-- { name, options = { option, ... } }.
local function Tabs(list)
    local tabs, byName = {}, {}
    for _, option in ipairs(list) do
        local name = option.tab or TEXT.general
        local tab = byName[name]
        if not tab then
            tab = { name = name, options = {} }
            byName[name] = tab
            if name == TEXT.general then table.insert(tabs, 1, tab) else tabs[#tabs + 1] = tab end
        end
        tab.options[#tab.options + 1] = option
    end
    return tabs
end

-- Fills one tab's scroll area with its boxes. Returns the height they take.
local function Fill(child, name, tab, byKey)
    local options, changed = Core.Store(name).options, Core.described[name].changed
    local function Get(option) return function() return options[option.key] end end
    local function Set(option)
        return function(value)
            options[option.key] = value
            if changed then changed(option.key, value) end
        end
    end
    local function Enabled(option)
        if not option.parent then return nil end
        return function() return Config.Free(options, byKey, option) end
    end
    -- The number drawn on a switch's line, by the switch's key.
    local beside = {}
    for _, option in ipairs(tab.options) do
        if option.inline and option.parent then beside[option.parent] = option end
    end

    local top, box, y = -4, nil, 0
    local function Close()
        if not box then return end
        box:SetHeight(-y + 6)
        top = top - 18 - box:GetHeight() - 16
    end
    for _, option in ipairs(tab.options) do
        if option.header or not box then
            Close()
            box = Panel.Box(child, option.header or "", top)
            y = -6
        end
        if option.text and not (option.inline and option.parent and byKey[option.parent].text) then
            if option.max then
                Words(box, option.text, y)
                Place(Panel.Slider(box, option.text, option.tip, option, Get(option), Set(option), Enabled(option)), box, CONTROL_X, y)
            elseif option.choices then
                Words(box, option.text, y)
                Place(Panel.Dropdown(box, option.text, option.tip, option, Get(option), Set(option), Enabled(option)), box, CONTROL_X, y)
            elseif option.color then
                Words(box, option.text, y)
                Place(Panel.Color(box, option.text, option.tip, Get(option), Set(option), Enabled(option)), box, CONTROL_X, y)
            else
                Place(Panel.Check(box, option.text, option.tip, Get(option), Set(option), Enabled(option)), box, CHECK_X, y)
                local number = beside[option.key]
                if number then
                    Place(Panel.Slider(box, number.text, number.tip, number, Get(number), Set(number), Enabled(number)), box, CONTROL_X, y)
                end
            end
            y = y - ROW
        end
    end
    Close()
    return -top
end

-- Builds a module's page into the frame Core put up for it: its title, the tabs, each a scroll area.
function Config.BuildTabbed(page, name)
    local list = Core.described[name].list
    local byKey = {}
    for _, option in ipairs(list) do byKey[option.key] = option end
    Panel.Header(page, SaneUI[name].title)

    local frame = CreateFrame("Frame", nil, page, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", 7, -96)
    frame:SetPoint("BOTTOMRIGHT", -7, 8)
    Panel.Frame(frame)
    local names, parts = {}, {}
    for index, tab in ipairs(Tabs(list)) do
        local part = CreateFrame("Frame", nil, frame)
        part:SetAllPoints()
        part:Hide()
        local child = Panel.Scroll(part)
        child:SetHeight(Core.Safe("Settings: " .. name .. " " .. tab.name, Fill, child, name, tab, byKey) or 1)
        names[index], parts[index] = tab.name, part
    end
    page.tabs = Panel.Tabs(page, names, function(index)
        for which, part in ipairs(parts) do part:SetShown(which == index) end
    end, 14, -62)
    page.parts = parts
    page.OnRefresh = function() Panel.Refresh() end
    Panel.Refresh()
end
