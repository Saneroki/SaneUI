local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Stats
--  The stats' window (the key "stats" on the module's board, Board.lua): the
--  player's stats, and the pet's under them while there is a pet, on the
--  journal's page in Sane UI's own look (Doc/guides/interface-style.md): each
--  of the game's categories (PAPERDOLL_STATCATEGORIES: general, attributes,
--  weapons, modifiers, defense; then the resistances; a pet's named with its
--  name) a section
--  with its head written in pencil and ruled, its stats in lines under it
--  (the name at the left, the value at the right). The sections stand in as
--  many columns as the window's width holds, in the game's order down each
--  column and on to the next, the columns as even in height as the order
--  lets them be: a narrow window is one list, a wide one a page of columns
--  (never wider than Stats.COLUMN_MOST each, together in the page's middle).
--  Where all five fit side by side over the columns, the primary attributes
--  stand above them as five boxes with their value written large.
--
--  What a stat says is the game's: each line is filled by the game's own
--  function for its stat (PAPERDOLL_STATINFO: its name, its value, its
--  tooltip), as the game fills its own rows, and its tooltip is the game's.
--  Which stats show is decided as the game decides it (its specs, roles and
--  show functions; a stat at its hideAt value left out). The game's colours in
--  a value (green for a bonus, red for a malus) are darkened to read on the
--  paper.
--
--  While the game restricts addons (a fight, an encounter: Core.Restricted)
--  stats are secret to addon code and the game's functions cannot do their
--  sums on them: the page stays as it was, and is drawn anew once the
--  restriction is over. Drawn when shown, and when the game says a stat
--  changed: a frame later, however many such events come at once.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local Paper = ns.Paper
local Stats = {}
ns.Stats = Stats

local Fit = Paper.Fit
Stats.PAD = Fit(5)         -- the page's margin round the sections
Stats.COLUMN = Fit(170)    -- the least width of a column; a window this wide (and its margins) is one list
Stats.COLUMN_MOST = Fit(320) -- the most: on a wider page the columns stand together in its middle
Stats.GAP = Fit(12)        -- between two columns
Stats.SPACE = Fit(6)       -- between two sections in a column
Stats.HEAD = Fit(21)       -- a section's head with its rule
Stats.ROW = Fit(18)        -- a stat's line
Stats.TILE = { Fit(70), Fit(48) } -- a primary attribute's box: its least width, its height
Stats.TILE_GAP = Fit(6)
Stats.STEP = Fit(40)       -- the wheel scrolls this far
Stats.LEAST = 300          -- how low the window may be made

-- The primary attributes (the game's stat names): written large in boxes while all of them fit side by side.
Stats.PRIMARY = { STRENGTH = true, AGILITY = true, STAMINA = true, INTELLECT = true, SPIRIT = true }

-- The resistances under the stats, as the game lists them: its damage class.
Stats.RESISTANCES = { "Arcane", "Fire", "Frost", "Nature", "Shadow" }

local Fonts = {
    head = Paper.Font("SaneUIStatsHead", 15, true),
    label = Paper.Font("SaneUIStatsLabel", 14),
    value = Paper.Font("SaneUIStatsValue", 14, true),
    tileLabel = Paper.Font("SaneUIStatsTileLabel", 13),
    tileValue = Paper.Font("SaneUIStatsTileValue", 24, true),
}

local view         -- the page: its scroll frame, sections, heads, spare lines
local owed = false -- a refresh was asked for under a restriction

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-------------------------------------------------------------------------------
--  Which stats show, as the game decides it
-------------------------------------------------------------------------------
-- The character's specialization and its role, where the game has them (a stat may show for some only).
local function Spec()
    local specs = rawget(_G, "C_SpecializationInfo")
    local spec = specs and specs.GetSpecialization and Core.Ask(specs.GetSpecialization)
    if not spec then return nil end
    return spec, Core.Ask(rawget(_G, "GetSpecializationRoleEnum"), spec)
end

-- Whether a stat of the game's list shows for this unit (the player, or the pet), as the game decides it.
local function Shown(stat, spec, role, unit)
    if stat.primary and spec then
        local specs = rawget(_G, "C_SpecializationInfo")
        local primary = select(6, specs.GetSpecializationInfo(spec, false, false, nil, UnitSex("player")))
        if stat.primary ~= primary then return false end
    end
    if stat.roles then
        local found = false
        for _, wanted in pairs(stat.roles) do found = found or wanted == role end
        if not found then return false end
    end
    if stat.unit and stat.unit ~= unit then return false end
    if stat.showFunc then return stat.showFunc() and true or false end
    return true
end

-------------------------------------------------------------------------------
--  A stat's line (or box): the game's function fills it
-------------------------------------------------------------------------------
-- The game's colours in a value darkened to read on the paper; the label's colon taken off (the line sets it apart).
local function Inked(text)
    return (tostring(text or ""):gsub("|c(%x%x)(%x%x)(%x%x)(%x%x)", function(_, r, g, b)
        return "|c" .. Paper.InkHex(tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255)
    end))
end

local function Bare(label)
    return (tostring(label or ""):gsub("%s*[:：]%s*$", ""))
end

-- The game's tooltip for the stat, as its rows show it: the stat's own function, else its tooltip lines.
local function Enter(row)
    row.shade:Show()
    if row.onEnterFunc then return row:onEnterFunc() end
    if rawget(_G, "PaperDollStatTooltip") then return PaperDollStatTooltip(row) end
    if not row.tooltip then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.tooltip)
    if row.tooltip2 then GameTooltip:AddLine(row.tooltip2, 1, 0.82, 0, true) end
    GameTooltip:Show()
end

local function Leave(row)
    row.shade:Hide()
    GameTooltip:Hide()
end

-- A line of ours with what the game's functions write into (Label, Value, the tooltip's fields): its shading under
-- the mouse, every other line's light stripe, and a pencil box for when it stands as an attribute's box.
local function Row(view)
    local row = CreateFrame("Button", nil, view.child)
    row.zebra = row:CreateTexture(nil, "BACKGROUND")
    row.zebra:SetAllPoints()
    row.zebra:SetColorTexture(Paper.ZEBRA[1], Paper.ZEBRA[2], Paper.ZEBRA[3], Paper.ZEBRA[4])
    row.shade = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.shade:SetAllPoints()
    row.shade:SetColorTexture(Paper.SHADE[1], Paper.SHADE[2], Paper.SHADE[3], Paper.SHADE[4])
    row.shade:Hide()
    row.Label = row:CreateFontString(nil, "ARTWORK")
    row.Label:SetFontObject(Fonts.label) -- a font from the start: the game's function writes before the layout
    row.Label:SetWordWrap(false)
    row.Value = row:CreateFontString(nil, "ARTWORK")
    row.Value:SetFontObject(Fonts.value)
    row.Value:SetWordWrap(false)
    row.box = J.Box(row, 0.5)
    row:SetScript("OnEnter", ns.Guard(Enter))
    row:SetScript("OnLeave", ns.Guard(Leave))
    return row
end

-- A line as a line: the name at the left, the value at the right, in graphite.
local function AsLine(row, striped)
    row.Label:SetFontObject(Fonts.label)
    row.Label:SetTextColor(Paper.SOFT[1], Paper.SOFT[2], Paper.SOFT[3], 1)
    row.Label:ClearAllPoints()
    row.Label:SetPoint("LEFT", Fit(5), 0)
    row.Label:SetPoint("RIGHT", row.Value, "LEFT", -Fit(6), 0)
    row.Label:SetJustifyH("LEFT")
    row.Value:SetFontObject(Fonts.value)
    row.Value:ClearAllPoints()
    row.Value:SetPoint("RIGHT", -Fit(5), 0)
    row.Value:SetJustifyH("RIGHT")
    row.zebra:SetShown(striped)
    for _, part in ipairs(row.box.parts) do part:Hide() end
end

-- A line as an attribute's box: the name small at its top, the value large under it, a pencil box round it.
local function AsTile(row)
    row.Label:SetFontObject(Fonts.tileLabel)
    row.Label:SetTextColor(Paper.SOFT[1], Paper.SOFT[2], Paper.SOFT[3], 1)
    row.Label:ClearAllPoints()
    row.Label:SetPoint("TOPLEFT", Fit(4), -Fit(5))
    row.Label:SetPoint("TOPRIGHT", -Fit(4), -Fit(5))
    row.Label:SetJustifyH("CENTER")
    row.Value:SetFontObject(Fonts.tileValue)
    row.Value:ClearAllPoints()
    row.Value:SetPoint("BOTTOM", 0, Fit(4))
    row.Value:SetJustifyH("CENTER")
    row.zebra:Hide()
    for index, part in ipairs(row.box.parts) do part:SetShown(index ~= 5) end
end

-- A line taken for a stat, its tooltip's fields as the game's rows start them.
local function Take(view)
    local row = table.remove(view.spare) or Row(view)
    row.onEnterFunc, row.UpdateTooltip, row.tooltip, row.tooltip2, row.tooltip3 = nil, nil, nil, nil, nil
    row.numericValue = nil
    row.Label:SetText("")
    row.Value:SetText("")
    row:Show()
    return row
end

local function Give(view, row)
    row:Hide()
    row:ClearAllPoints()
    view.spare[#view.spare + 1] = row
end

-- Filled by the game's function for its stat: shown unless the game hides it or it is at the value it hides at.
local function Fill(view, unit, stat, info)
    local row = Take(view)
    local value = Core.Plain(info.updateFunc(row, unit, stat.id))
    if not row:IsShown() or (stat.hideAt ~= nil and value == stat.hideAt) then
        Give(view, row)
        return nil
    end
    row.Label:SetText(Bare(row.Label:GetText()))
    row.Value:SetText(Inked(row.Value:GetText()))
    row.stat = stat.stat
    return row
end

-- A resistance's line, filled by the game's own function for it (else as it fills one: the name, the value with
-- its bonus, the tooltip).
local function Resistance(view, unit, name)
    local class = Enum and Enum.Damageclass and Enum.Damageclass[name]
    if not class then return nil end
    local row = Take(view)
    if rawget(_G, "PaperDollFrame_SetResistance") then
        PaperDollFrame_SetResistance(row, unit, class)
    else
        local _, _, effective, bonus = UnitResistance(unit, class)
        local word = Core.Word("RESISTANCE" .. class .. "_NAME", name)
        row.Label:SetText(word)
        local text = Game("BreakUpLargeNumbers", effective) or tostring(effective or "")
        row.Value:SetText(Game("PaperDollFrame_FormatBonusValue", text, bonus or 0) or text)
        Game("PaperDollFrame_SetResistanceTooltips", row, word, effective, unit, class)
    end
    row.Label:SetText(Bare(row.Label:GetText()))
    row.Value:SetText(Inked(row.Value:GetText()))
    row.stat = nil
    return row
end

-------------------------------------------------------------------------------
--  The sections: what the page holds now
-------------------------------------------------------------------------------
local function Head(view, index)
    local head = view.heads[index]
    if not head then
        head = CreateFrame("Frame", nil, view.child)
        head:SetHeight(Stats.HEAD)
        head.text = head:CreateFontString(nil, "ARTWORK")
        head.text:SetFontObject(Fonts.head)
        head.text:SetPoint("BOTTOMLEFT", Fit(3), Fit(3))
        head.text:SetPoint("BOTTOMRIGHT", -Fit(3), Fit(3))
        head.text:SetJustifyH("LEFT")
        head.text:SetWordWrap(false)
        Paper.Rule(head, "BOTTOM")
        view.heads[index] = head
    end
    head:Show()
    return head
end

-- Whether the player has a pet the game shows stats for.
local function Pet()
    return Game("HasPetUI") and UnitExists("pet") and true or false
end

-- Each category of a unit's (the player's, or the pet's) with the stats that show, added to sections; a pet's
-- category named with the pet's name. A section of the primary attributes alone is marked: it may stand as boxes.
local function Categories(view, sections, unit)
    local categories, info = rawget(_G, "PAPERDOLL_STATCATEGORIES"), rawget(_G, "PAPERDOLL_STATINFO")
    if type(categories) ~= "table" or type(info) ~= "table" then return end
    local spec, role = Spec()
    local owner = unit == "pet" and (UnitName("pet") or Core.Word("PET", "Pet")) or nil
    for _, category in ipairs(categories) do
        if (category.unit or "player") == unit then
            local name = owner and (owner .. ": " .. tostring(category.categoryName or "")) or category.categoryName
            local section = { name = name, rows = {}, primary = unit == "player" }
            for _, stat in ipairs(category.stats or {}) do
                if info[stat.stat] and Shown(stat, spec, role, unit) then
                    local row = Fill(view, unit, stat, info[stat.stat])
                    if row then
                        section.rows[#section.rows + 1] = row
                        section.primary = section.primary and Stats.PRIMARY[stat.stat] or false
                    end
                end
            end
            if #section.rows > 0 then sections[#sections + 1] = section end
        end
    end
end

-- Every line given back, then the sections anew: the player's categories, the resistances, and the pet's
-- categories while there is a pet.
local function Sections(view)
    for _, section in ipairs(view.sections) do
        for _, row in ipairs(section.rows) do Give(view, row) end
    end
    local sections = {}
    Categories(view, sections, "player")
    local resist = { name = Core.Word("STAT_CATEGORY_RESISTANCE", "Resistances"), rows = {} }
    for _, name in ipairs(Stats.RESISTANCES) do
        resist.rows[#resist.rows + 1] = Resistance(view, "player", name)
    end
    if #resist.rows > 0 then sections[#sections + 1] = resist end
    if Pet() then Categories(view, sections, "pet") end
    view.sections = sections
end

-------------------------------------------------------------------------------
--  The layout: as many columns as the width holds
-------------------------------------------------------------------------------
local function Height(section)
    return Stats.HEAD + #section.rows * Stats.ROW
end

-- The sections (in order) cut into n runs, one a column, so that the highest column is as low as it can be:
-- returns the index each column starts at. The sections are few, so every cut is tried.
local function Cuts(heights, n)
    local count = #heights
    local best, bestStarts = math.huge, nil
    local starts = {}
    local function Try(column, from, tallest)
        if tallest >= best then return end
        starts[column] = from
        if column == n then
            local h = -Stats.SPACE
            for i = from, count do h = h + heights[i] + Stats.SPACE end
            tallest = math.max(tallest, h)
            if tallest < best then
                best = tallest
                bestStarts = { unpack(starts, 1, n) }
            end
            return
        end
        local h = -Stats.SPACE
        for upto = from, count - (n - column) do
            h = h + heights[upto] + Stats.SPACE
            Try(column + 1, upto + 1, math.max(tallest, h))
        end
    end
    Try(1, 1, 0)
    return bestStarts or { 1 }
end

-- Everything put in its place for the page's width now: the columns first (how many, how wide, where the block
-- of them starts), then the attributes' boxes over the block's width, then the sections down the columns.
local function Layout(view)
    local width = view.scroll:GetWidth() or 0
    if width <= 0 then return end
    local inner = width - 2 * Stats.PAD
    view.child:SetWidth(width)
    local tiled, rest = nil, {}
    for _, section in ipairs(view.sections) do
        if section.primary and #section.rows > 1 and not tiled then tiled = section else rest[#rest + 1] = section end
    end
    local function Columns(count)
        local columns = math.max(1, math.min(count, math.floor((inner + Stats.GAP) / (Stats.COLUMN + Stats.GAP))))
        local columnWidth = math.min(Stats.COLUMN_MOST, (inner - (columns - 1) * Stats.GAP) / columns)
        return columns, columnWidth, columns * columnWidth + (columns - 1) * Stats.GAP
    end
    local columns, columnWidth, block = Columns(#rest)
    -- the attributes as boxes only where all of them fit side by side over the block; else a section like the others
    if tiled and #tiled.rows * Stats.TILE[1] + (#tiled.rows - 1) * Stats.TILE_GAP > block then
        table.insert(rest, 1, tiled)
        tiled = nil
        columns, columnWidth, block = Columns(#rest)
    end
    local left = Stats.PAD + math.floor((inner - block) / 2)
    local y = Stats.PAD
    if tiled then
        local n = #tiled.rows
        local w = (block - (n - 1) * Stats.TILE_GAP) / n
        for index, row in ipairs(tiled.rows) do
            AsTile(row)
            row:ClearAllPoints()
            row:SetSize(w, Stats.TILE[2])
            row:SetPoint("TOPLEFT", left + (index - 1) * (w + Stats.TILE_GAP), -y)
        end
        y = y + Stats.TILE[2] + Stats.SPACE
    end
    for _, head in ipairs(view.heads) do head:Hide() end
    local heights = {}
    for index, section in ipairs(rest) do heights[index] = Height(section) end
    local starts = Cuts(heights, columns)
    local tallest, column = y, 0
    local x, top = left, y
    for index, section in ipairs(rest) do
        if starts[column + 1] == index then
            column = column + 1
            x = left + (column - 1) * (columnWidth + Stats.GAP)
            y = top
        else
            y = y + Stats.SPACE
        end
        local head = Head(view, index)
        head.text:SetText(section.name or "")
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", x, -y)
        head:SetWidth(columnWidth)
        y = y + Stats.HEAD
        for line, row in ipairs(section.rows) do
            AsLine(row, line % 2 == 0)
            row:ClearAllPoints()
            row:SetSize(columnWidth, Stats.ROW)
            row:SetPoint("TOPLEFT", x, -y)
            y = y + Stats.ROW
        end
        tallest = math.max(tallest, y)
    end
    view.child:SetHeight(math.max(1, tallest + Stats.PAD))
    local most = math.max(0, view.child:GetHeight() - (view.scroll:GetHeight() or 0))
    if view.scroll:GetVerticalScroll() > most then view.scroll:SetVerticalScroll(most) end
end

-- The wheel over the page: a step up or down, never past the ends.
local function Wheel(view, delta)
    local most = math.max(0, (view.child:GetHeight() or 0) - (view.scroll:GetHeight() or 0))
    view.scroll:SetVerticalScroll(math.max(0, math.min(most, view.scroll:GetVerticalScroll() - delta * Stats.STEP)))
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
-- The page filling the window's body: a scrolling page of sections.
function Stats.Build(panel)
    local body = panel.body or panel
    view = { sections = {}, heads = {}, spare = {} }
    local scroll = CreateFrame("ScrollFrame", nil, body)
    scroll:SetAllPoints()
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", ns.Guard(function(_, delta) Wheel(view, delta) end))
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", ns.Guard(function() Layout(view) end))
    view.scroll, view.child = scroll, child
end

-- The page drawn as the stats are now, unless the game restricts addons: then once it no longer does.
function Stats.Refresh()
    if Core.Restricted() then
        owed = true
        return
    end
    owed = false
    if view and view.scroll:IsVisible() then
        Sections(view)
        Layout(view)
    end
end

-- Whether a refresh waits for a restriction to end.
function Stats.Owed()
    return owed
end

-- The page: its scroll frame, its sections and their lines (for the tests).
function Stats.View()
    return view
end

local later = Core.Later(function() ns.Safe("character", Stats.Refresh) end)

-- What the game says changes a stat (the game's sheet listens to the same), and the end of a restriction.
local EVENTS = { "COMBAT_RATING_UPDATE", "SPEED_UPDATE", "SKILL_LINES_CHANGED", "CHARACTER_POINTS_CHANGED",
                 "PLAYER_DAMAGE_DONE_MODS", "SPELL_POWER_CHANGED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED",
                 "ADDON_RESTRICTION_STATE_CHANGED" }
local UNIT_EVENTS = { "UNIT_STATS", "UNIT_RANGEDDAMAGE", "UNIT_RANGED_ATTACK_POWER", "UNIT_ATTACK", "UNIT_SPELL_HASTE",
                      "UNIT_RESISTANCES", "UNIT_ATTACK_POWER", "UNIT_ATTACK_SPEED", "UNIT_DAMAGE", "UNIT_MAXHEALTH",
                      "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_LEVEL" }
local PET_EVENTS = { "PET_STATS_UPDATE" }

-- The stats' window is shown (on) or hidden: the game listened to only while it is shown, the pet's too (UNIT_PET
-- names the pet's owner: the player's only).
function Stats.Show(on)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    for _, event in ipairs(PET_EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    if on then Core.OnUnit("UNIT_PET", "player", later) else Core.OffUnit("UNIT_PET", "player", later) end
    for _, event in ipairs(UNIT_EVENTS) do
        if on then
            Core.OnUnit(event, "player", later)
            Core.OnUnit(event, "pet", later)
        else
            Core.OffUnit(event, "player", later)
            Core.OffUnit(event, "pet", later)
        end
    end
    if on then ns.Safe("character", Stats.Refresh) end
end

ns.Board.Part("stats", Core.Word("PAPERDOLL_SIDEBAR_STATS", "Character Stats"),
    ns.Board.Least("stats", Stats.COLUMN + 2 * Stats.PAD, Stats.LEAST), Stats)
