local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Stats
--  The stats in the character sheet's right pane, as the game's sheet lists
--  them (Camelot's CharacterStatsPaneScrollBox): under the pane's stone, the
--  game's scrolling list (CharacterStatsPaneScrollBoxTemplate) of its
--  categories (PAPERDOLL_STATCATEGORIES: general, attributes, weapons,
--  modifiers, defense) and then the resistances. Every row is the game's
--  (its element templates), filled by the game's own function for that stat
--  (PAPERDOLL_STATINFO: its words, its value, its tooltip). The list itself is
--  put together by our code as the game puts its own together
--  (CharacterStatsPaneScrollBoxMixin:UpdateStats), with frames of ours: the
--  game's sheet and its frames are never touched.
--
--  While the game restricts addons (a fight, an encounter: Core.Restricted)
--  stats are secret to addon code and the game's functions cannot do their
--  sums on them: the list stays as it was, and is drawn anew once the
--  restriction is over. Drawn when shown, and when the game says a stat
--  changed: a frame later, however many such events come at once.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Stats = {}
ns.Stats = Stats

Stats.BOTTOM = 8 -- room under the last row, as the game's list keeps it

-- The resistances under the stats, as the game lists them: its school's words, its damage class, its atlas.
Stats.RESISTANCES = {
    { word = "DAMAGE_SCHOOL7", class = "Arcane", atlas = "UI-Character-Info-Resistance-Arcane" },
    { word = "DAMAGE_SCHOOL3", class = "Fire", atlas = "UI-Character-Info-Resistance-Fire" },
    { word = "DAMAGE_SCHOOL5", class = "Frost", atlas = "UI-Character-Info-Resistance-Frost" },
    { word = "DAMAGE_SCHOOL4", class = "Nature", atlas = "UI-Character-Info-Resistance-Nature" },
    { word = "DAMAGE_SCHOOL6", class = "Shadow", atlas = "UI-Character-Info-Resistance-Shadow" },
}

local list    -- the game's scrolling list, ours
local scratch -- a row of ours the game's functions fill to tell whether a stat shows (its value)
local owed = false -- a refresh was asked for under a restriction

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- The row a list element is drawn with: the game's for a category's head, for a stat with an icon, for one without.
local function Template(element)
    if element.isHeader then return "CharacterStatFrameCategoryScrollBoxElementTemplate" end
    if element.texture or element.atlas then return "CharacterStatFrameScrollBoxIconElementTemplate" end
    return "CharacterStatFrameScrollBoxLabelElementTemplate"
end

local function Draw(row, element)
    row:Init(element)
end

local function Initialize(row, element)
    ns.Safe("character", Draw, row, element)
end

local function Make(factory, element)
    factory(Template(element), Initialize)
end

-- The character's specialization and its role, where the game has them (a stat may show for some only).
local function Spec()
    local specs = rawget(_G, "C_SpecializationInfo")
    local spec = specs and specs.GetSpecialization and Core.Ask(specs.GetSpecialization)
    if not spec then return nil end
    return spec, Core.Ask(rawget(_G, "GetSpecializationRoleEnum"), spec)
end

-- Whether a stat of the game's list shows for this character, as the game decides it.
local function Shown(stat, spec, role)
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
    if stat.unit and stat.unit ~= "player" then return false end
    if stat.showFunc then return stat.showFunc() and true or false end
    return true
end

-- The list's elements, as the game makes its own: each category's head once a stat of it shows, then its stats
-- whose value is not the one they hide at; then the resistances.
local function Elements()
    local elements = {}
    local categories, info = rawget(_G, "PAPERDOLL_STATCATEGORIES"), rawget(_G, "PAPERDOLL_STATINFO")
    if type(categories) ~= "table" or type(info) ~= "table" then return elements end
    local spec, role = Spec()
    for _, category in ipairs(categories) do
        if not category.unit or category.unit == "player" then
            local stats = {}
            for _, stat in ipairs(category.stats or {}) do
                if info[stat.stat] and Shown(stat, spec, role) then stats[#stats + 1] = stat end
            end
            if #stats > 0 then
                elements[#elements + 1] = { isHeader = true, name = category.categoryName }
                local index = 1
                for _, stat in ipairs(stats) do
                    local value = Core.Plain(info[stat.stat].updateFunc(scratch, "player", stat.id))
                    if value == nil or value ~= stat.hideAt then
                        elements[#elements + 1] = {
                            isHeader = false, unit = "player", name = stat.stat, id = stat.id, statIndex = index,
                            texture = stat.texture, textureCoordL = stat.textureCoordL, textureCoordR = stat.textureCoordR,
                            textureCoordT = stat.textureCoordT, textureCoordB = stat.textureCoordB, hideAt = stat.hideAt,
                        }
                        index = index + 1
                    end
                end
            end
        end
    end
    elements[#elements + 1] = { isHeader = true, name = Core.Word("STAT_CATEGORY_RESISTANCE", "Resistance") }
    local classes = Enum and Enum.Damageclass or {}
    for index, school in ipairs(Stats.RESISTANCES) do
        local class = classes[school.class]
        local _, _, effective, bonus = UnitResistance("player", class)
        local name = Core.Word(school.word, school.class)
        local tips = {}
        Game("PaperDollFrame_SetResistanceTooltips", tips, name, effective, "player", class)
        local text = Game("BreakUpLargeNumbers", effective) or tostring(effective or "")
        text = Game("PaperDollFrame_FormatBonusValue", text, bonus) or text
        elements[#elements + 1] = {
            isHeader = false, statIndex = index, atlas = school.atlas, labelText = name, valueText = text,
            numericValue = effective, tooltip = tips.tooltip, tooltip2 = tips.tooltip2, tooltip3 = tips.tooltip3,
        }
    end
    return elements
end

-- The game's list under the pane's stone, to the pane's bottom right; the rows the game's.
function Stats.Build(pane, stone)
    local made, frame = pcall(CreateFrame, "Frame", nil, pane, "CharacterStatsPaneScrollBoxTemplate")
    if not made then return ns.Report("character", "this client has no stats list: " .. tostring(frame)) end
    list = frame
    list:SetPoint("TOPLEFT", stone, "BOTTOMLEFT")
    list:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT")
    local view = CreateScrollBoxListLinearView(0, Stats.BOTTOM, 0, 0, 0)
    view:SetElementFactory(function(factory, element) ns.Safe("character", Make, factory, element) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(list.ScrollBox, list.ScrollBar, view)
    scratch = CreateFrame("Frame", nil, pane, "CharacterStatFrameTemplate")
    scratch:Hide()
end

-- The list drawn as the stats are now, unless the game restricts addons: then once it no longer does.
function Stats.Refresh()
    if not list then return end
    if Core.Restricted() then
        owed = true
        return
    end
    owed = false
    list.ScrollBox:SetDataProvider(CreateDataProvider(Elements()), ScrollBoxConstants.RetainScrollPosition)
end

-- Whether a refresh waits for a restriction to end.
function Stats.Owed()
    return owed
end

local later = Core.Later(function() ns.Safe("character", Stats.Refresh) end)

-- What the game says changes a stat (the game's sheet listens to the same), and the end of a restriction.
local EVENTS = { "COMBAT_RATING_UPDATE", "SPEED_UPDATE", "SKILL_LINES_CHANGED", "CHARACTER_POINTS_CHANGED",
                 "PLAYER_DAMAGE_DONE_MODS", "SPELL_POWER_CHANGED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED",
                 "ADDON_RESTRICTION_STATE_CHANGED" }
local UNIT_EVENTS = { "UNIT_STATS", "UNIT_RANGEDDAMAGE", "UNIT_RANGED_ATTACK_POWER", "UNIT_ATTACK", "UNIT_SPELL_HASTE",
                      "UNIT_RESISTANCES", "UNIT_ATTACK_POWER", "UNIT_ATTACK_SPEED", "UNIT_DAMAGE", "UNIT_MAXHEALTH",
                      "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_LEVEL" }

-- The character sheet's panel is shown (on) or hidden: the game listened to only while it is shown.
function Stats.Show(on)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    for _, event in ipairs(UNIT_EVENTS) do
        if on then Core.OnUnit(event, "player", later) else Core.OffUnit(event, "player", later) end
    end
    if on then ns.Safe("character", Stats.Refresh) end
end
