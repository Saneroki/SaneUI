local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Icons
--  The picture window (Saneroki, 2026-11-04): a click on the chosen macro's
--  picture opens it over whatever shows, the full screen too, large. On the left
--  the groups (all, those the game itself shows, each class, weapons, armor and
--  the rest), at the top a search box over the icons' names and groups, then the
--  icons; the mouse on one names it and says what shows it. A click gives the
--  macro that picture and closes the window; Steps' picture takes the macro's
--  own away.
--
--  The icons are Core's set Icons: every icon the client holds, by its file
--  number, with its name, and in Forever the classes, spells and items that show
--  it. An icon is in a class's group where that class's spells show it or its
--  name says so (Ability_Warrior_...), in an item group where items of that kind
--  show it or its name says so (INV_Sword_...). Without the set (refused), the
--  game's own list of macro icons stands in, without names. Read once, at the
--  first opening, a part per frame.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Icons = {}
Macros.Icons = Icons

Icons.SQUARE = 40              -- an icon in the grid
Icons.GAP = 6
Icons.SIDE = 190               -- the groups' column
Icons.ROW = 22                 -- a group's line
Icons.LARGEST = { 1180, 820 }  -- the window at most
Icons.SHARE = { 0.8, 0.86 }    -- of the screen, at most
Icons.STRATA = "FULLSCREEN_DIALOG" -- over the full screen (HIGH) and its meter (DIALOG); tooltips above it
Icons.WAIT = 0.25              -- seconds after the last key before the search runs
Icons.UNDER = { 0.02, 0.02, 0.02, 0.94 } -- the window's ground, under Core's plate
Icons.SHOWN = 6                -- spells or items named in a tooltip

-- The item classes (Enum.ItemClass) of the item groups, and the names' beginnings that put an icon there
-- without an item of the game's showing it.
Icons.ITEMS = {
    { key = "weapons", class = 2, names = { "inv_sword", "inv_axe", "inv_mace", "inv_hammer", "inv_staff", "inv_spear",
        "inv_polearm", "inv_weapon", "inv_bow", "inv_crossbow", "inv_gun", "inv_wand", "inv_knife", "inv_throwing",
        "inv_dagger", "inv_musket", "inv_rifle", "inv_glaive", "inv_fist", "inv_2h", "inv_1h" } },
    { key = "armor", class = 4, names = { "inv_helm", "inv_shoulder", "inv_chest", "inv_shirt", "inv_pants", "inv_boots",
        "inv_gauntlets", "inv_bracer", "inv_belt", "inv_misc_cape", "inv_cape", "inv_jewelry", "inv_shield",
        "inv_misc_head", "inv_robe", "inv_offhand" } },
    { key = "consumables", class = 0, names = { "inv_potion", "inv_misc_food", "inv_drink", "inv_scroll", "inv_elixir",
        "inv_alchemy", "inv_flask", "inv_misc_bandage", "inv_poison" } },
    { key = "goods", class = 7, names = { "inv_ore", "inv_fabric", "inv_misc_herb", "inv_misc_leatherscrap", "inv_ingot",
        "inv_misc_gem", "inv_jewelcrafting", "inv_enchant", "inv_misc_pelt", "inv_stone", "inv_cloth", "inv_leather",
        "inv_misc_dust", "inv_misc_powder", "inv_engineering", "inv_tradeskill" } },
}
-- The groups after the classes and the item groups, by their names' beginnings; the first that fits takes it.
Icons.NAMED = {
    { key = "mounts", names = { "ability_mount", "inv_pet", "inv_misc_pet", "ability_hunter_pet", "inv_mount" } },
    { key = "achievements", names = { "achievement_" } },
    { key = "items", names = { "inv_" } },
    { key = "spells", names = { "spell_", "ability_" } },
}

local frame, window, built
local search, count, clear, box, view, empty
local groupLines = {}
local entries          -- every icon: { key, name, plain, groups = { [group] = true }, words, classes, spells, items }
local groups           -- the groups shown: { key, title, list }
local reading          -- the set's walk is under way
local chosenGroup = "all"
local macro, done      -- the macro whose picture is chosen, and what to do with it
local typed = 0        -- when a key was last typed

local function Starts(low, names)
    for _, start in ipairs(names) do
        if low:sub(1, #start) == start then return true end
    end
    return false
end

local function Has(list, value)
    for _, each in ipairs(list or {}) do
        if each == value then return true end
    end
    return false
end

-- The classes the game has: { id, name, token } each.
local function Classes()
    local list = {}
    local total = Core.Ask(rawget(_G, "GetNumClasses")) or 0
    for id = 1, math.max(total, 13) do
        local name, file = Core.Ask(rawget(_G, "GetClassInfo"), id)
        if name and file then list[#list + 1] = { id = id, name = name, token = file:lower():gsub("_", "") } end
    end
    return list
end

-- Which groups an icon is in, and their names as words to search by.
local function Sort(entry, classes)
    local low = entry.name and entry.name:lower() or ""
    local inside, words = { all = true }, {}
    local function Put(key, title)
        if inside[key] then return end
        inside[key] = true
        words[#words + 1] = title
    end
    if entry.spells or entry.items then inside.game = true end
    local classed, sorted = false, false
    for _, class in ipairs(classes) do
        local token = class.token
        if Has(entry.classes, class.id) or Starts(low, { "ability_" .. token .. "_", "spell_" .. token .. "_",
                                                         "classicon_" .. token }) then
            Put("class" .. class.id, class.name)
            classed = true
        end
    end
    for _, group in ipairs(Icons.ITEMS) do
        if Has(entry.itemClasses, group.class) or Starts(low, group.names) then
            Put(group.key, Macros.TEXT.iconGroups[group.key])
            sorted = true
        end
    end
    -- The first named group that fits; other items only for an item of no group above, spells only for no class's.
    for _, group in ipairs(Icons.NAMED) do
        if Starts(low, group.names) then
            if not ((group.key == "items" and sorted) or (group.key == "spells" and classed)) then
                Put(group.key, Macros.TEXT.iconGroups[group.key])
            end
            sorted = true
            break
        end
    end
    if not sorted and not classed then Put("other", Macros.TEXT.iconGroups.other) end
    entry.groups, entry.words = inside, table.concat(words, " ")
    entry.plain = entry.name and entry.name:gsub("_", " ") or ""
end

-- The groups shown, in their order, each with its icons; the classes the game has, where any icon is theirs.
local function Group()
    local classes = Classes()
    for _, entry in ipairs(entries) do Sort(entry, classes) end
    local order = { { key = "all", title = Macros.TEXT.iconGroups.all }, { key = "game", title = Macros.TEXT.iconGroups.game } }
    for _, class in ipairs(classes) do order[#order + 1] = { key = "class" .. class.id, title = class.name } end
    for _, group in ipairs(Icons.ITEMS) do order[#order + 1] = { key = group.key, title = Macros.TEXT.iconGroups[group.key] } end
    for _, key in ipairs({ "items", "spells", "mounts", "achievements", "other" }) do
        order[#order + 1] = { key = key, title = Macros.TEXT.iconGroups[key] }
    end
    groups = {}
    for _, group in ipairs(order) do
        group.list = {}
        for _, entry in ipairs(entries) do
            if entry.groups[group.key] then group.list[#group.list + 1] = entry end
        end
        if group.list[1] then groups[#groups + 1] = group end
    end
end

-- Without the set: the game's own lists of macro icons, spells' then items', by their file numbers alone.
local function FromGame()
    local list = {}
    for _, name in ipairs({ "GetMacroIcons", "GetMacroItemIcons" }) do
        local found = {}
        Core.Ask(rawget(_G, name), found)
        for _, key in ipairs(found) do
            if type(key) == "number" then list[#list + 1] = { key = key } end
        end
    end
    return list
end

local Fill

-- Every icon of the set, read a part per frame (Data's job), then grouped.
local function Read()
    if entries or reading then return end
    local set = Core.Data.Set("Icons")
    local list = {}
    local started = set:Ready() and set:Each(function(key, record)
        list[#list + 1] = { key = key, name = record.name, classes = record.classes, spells = record.spells,
                            items = record.items, itemClasses = record.itemClasses }
    end, function(problem)
        reading = nil
        if problem then list = FromGame() end
        -- By name, whatever the case: the client spells some names in capitals.
        for _, entry in ipairs(list) do entry.order = (entry.name or ""):lower() end
        table.sort(list, function(a, b) return a.order < b.order end)
        entries = list
        Group()
        Fill()
    end)
    if started then
        reading = started
        return
    end
    entries = FromGame()
    Group()
end

local function Picture(button)
    local entry = button.entry
    if not (entry and done) then return end
    local give = done
    Icons.Close()
    give(entry.key)
end

-- Names of what shows an icon, as far as the game tells them now.
local function Named(list, ask)
    local names, more = {}, 0
    for _, id in ipairs(list or {}) do
        local name = Core.Ask(ask, id)
        if name and #names < Icons.SHOWN then names[#names + 1] = name else more = more + 1 end
    end
    if not names[1] then return nil end
    local text = table.concat(names, ", ")
    if more > 0 then text = text .. " " .. Macros.TEXT.iconMore:format(more) end
    return text
end

local function Enter(button)
    local entry = button.entry
    local tip = rawget(_G, "GameTooltip")
    if not (entry and tip) then return end
    tip:SetOwner(button, "ANCHOR_RIGHT")
    tip:SetText(entry.plain ~= "" and entry.plain or Macros.TEXT.iconNumber:format(entry.key), 1, 1, 1)
    if entry.words and entry.words ~= "" then tip:AddLine(entry.words, 1, 0.82, 0, true) end
    local spells = rawget(_G, "C_Spell")
    local items = rawget(_G, "C_Item")
    local spellNames = spells and Named(entry.spells, spells.GetSpellName)
    local itemNames = items and Named(entry.items, items.GetItemNameByID)
    if spellNames then tip:AddLine(Macros.TEXT.iconSpells:format(spellNames), 0.9, 0.9, 0.9, true) end
    if itemNames then tip:AddLine(Macros.TEXT.iconItems:format(itemNames), 0.9, 0.9, 0.9, true) end
    for _, id in ipairs(entry.items or {}) do
        -- An item the game has not read yet: asked for, its name there at the next look.
        if items and items.RequestLoadItemDataByID and not Core.Ask(items.GetItemNameByID, id) then
            Core.Ask(items.RequestLoadItemDataByID, id)
        end
    end
    if macro and macro.icon == entry.key then tip:AddLine(Macros.TEXT.iconChosen, 0.4, 1, 0.4) end
    tip:AddLine(Macros.TEXT.iconFile:format(entry.key), 0.6, 0.6, 0.6)
    tip:AddLine(Macros.TEXT.iconClick, 0.6, 0.6, 0.6)
    tip:Show()
end

-- One icon of the grid: the view hands its buttons round, so each is dressed whole.
local function Dress(button, entry)
    if not button.icon then
        button:SetSize(Icons.SQUARE, Icons.SQUARE)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        local lit = button:CreateTexture(nil, "HIGHLIGHT")
        lit:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        lit:SetBlendMode("ADD")
        lit:SetAllPoints()
        button.mark = button:CreateTexture(nil, "OVERLAY")
        button.mark:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        button.mark:SetBlendMode("ADD")
        button.mark:SetAllPoints()
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", ns.Guard(Picture))
        button:SetScript("OnEnter", ns.Guard(Enter))
        button:SetScript("OnLeave", ns.Guard(Core.HideTip))
    end
    button.entry = entry
    button.icon:SetTexture(entry.key)
    button.mark:SetShown(macro ~= nil and macro.icon == entry.key)
end

local function Number(value)
    return Core.Ask(rawget(_G, "BreakUpLargeNumbers"), value) or tostring(value)
end

local function Show(list)
    if not box then return end
    box:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.DiscardScrollPosition)
    count:SetText(Macros.TEXT.iconCount:format(Number(#list)))
    empty:SetText(Macros.TEXT.iconNone)
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
    if not entries then return end
    if GetTime() - typed < Icons.WAIT then return Icons.later() end
    local group = GroupOf(chosenGroup)
    local list = group and group.list or {}
    local query = Core.Fuzzy.Query(search:GetText())
    if not query then return Show(list) end
    -- A long list is searched a part per frame; a newer search stops an older one (Fuzzy.Filter).
    Core.Fuzzy.Filter(list, query, { "plain", "words" }, function(found) Show(found) end)
end
Icons.later = Core.Later(function() ns.Safe("macros", Search) end, Icons.WAIT, "Macros: pictures")

-- The groups' lines, their counts, the one chosen lit.
local function Lines()
    for index, group in ipairs(groups or {}) do
        local line = groupLines[index]
        if not line then
            line = CreateFrame("Button", nil, built.side)
            line:SetHeight(Icons.ROW)
            line:SetPoint("TOPLEFT", 0, -(index - 1) * Icons.ROW)
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
        line.title:SetText(group.title)
        line.count:SetText(Number(#group.list))
        line.mark:SetShown(group.key == (GroupOf(chosenGroup) or {}).key)
        line:Show()
    end
    for index = #(groups or {}) + 1, #groupLines do groupLines[index]:Hide() end
end

function Fill()
    if not built then return end
    if not entries then
        Show({})
        empty:SetText(Macros.TEXT.iconReading)
        count:SetText("")
        return
    end
    Lines()
    typed = 0
    Search()
end

local function Size()
    local width = math.min(Icons.LARGEST[1], (UIParent:GetWidth() or 1200) * Icons.SHARE[1])
    local height = math.min(Icons.LARGEST[2], (UIParent:GetHeight() or 800) * Icons.SHARE[2])
    return math.floor(width), math.floor(height)
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Size())
    frame:SetFrameStrata(Icons.STRATA)
    -- Under Core's plate, which lets a little through: over a busy full screen the icons read clean.
    local under = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    under:SetAllPoints()
    under:SetColorTexture(Icons.UNDER[1], Icons.UNDER[2], Icons.UNDER[3], Icons.UNDER[4])
    frame:EnableMouse(true) -- clicks on it stay on it
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = Macros.store, key = "pictures", title = Macros.TEXT.iconTitle, edge = false, dock = false,
        sizable = false, first = { point = "CENTER", x = 0, y = 0 },
        close = function() frame:Hide() end,
    })
    local inside, I = window.inside, Macros.Editor.INSET
    built = {}
    search = CreateFrame("EditBox", nil, inside, "SearchBoxTemplate")
    search:SetSize(320, 22)
    search:SetPoint("TOPLEFT", I + Icons.SIDE + I + 6, -I)
    search:SetAutoFocus(false)
    local hint = rawget(search, "Instructions") -- the game's grey words in the empty box
    if type(hint) == "table" then hint:SetText(Macros.TEXT.iconSearch) end
    search:HookScript("OnTextChanged", ns.Guard(function(_, user)
        if not user then return end
        typed = GetTime()
        Icons.later()
    end))
    count = inside:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetPoint("LEFT", search, "RIGHT", 12, 0)
    clear = Macros.Button(inside, Macros.TEXT.iconClear, 140)
    clear:SetPoint("TOPRIGHT", -I, -I + 1)
    clear:SetScript("OnClick", ns.Guard(function()
        local give = done
        Icons.Close()
        if give then give(nil) end
    end))
    Core.Tip(clear, Macros.TEXT.iconClear, Macros.TEXT.iconClearTip)
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
    view = CreateScrollBoxListGridView(1, 4, 4, 4, 4, Icons.GAP, Icons.GAP)
    view:SetElementSize(Icons.SQUARE, Icons.SQUARE)
    view:SetStrideExtent(Icons.SQUARE)
    view:SetElementInitializer("Button", ns.Guard(Dress))
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    empty = inside:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", box, "TOP", 0, -40)
    frame:HookScript("OnHide", ns.Guard(function()
        macro, done = nil, nil
        Core.HideTip()
    end))
    window:Place()
end

-- Opens the window for a macro: given(picture) with the file number clicked, or nil for Steps' picture.
function Icons.Open(which, given)
    if ns.off then return end
    if not frame then Build() end
    macro, done = which, given
    frame:Show()
    frame:Raise()
    Read()
    Fill()
    Core.Sound("IG_CHARACTER_INFO_OPEN")
end

function Icons.Close()
    if frame and frame:IsShown() then
        frame:Hide()
        Core.Sound("IG_CHARACTER_INFO_CLOSE")
    end
end

function Icons.Shown()
    return frame ~= nil and frame:IsShown()
end

-- For the test.
function Icons.Frame()
    return frame
end

function Icons.Groups()
    return groups
end

function Icons.Box()
    return box
end

function Icons.Search()
    return search
end

function Icons.GroupLine(index)
    return groupLines[index]
end

function Icons.Clear()
    return clear
end

function Icons.Forget()
    entries, groups, reading = nil, nil, nil
end
