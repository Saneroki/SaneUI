local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Label
--  What lights up under the mouse (Art.Light), named at the top of the full map,
--  under its bar, as Blizzard's map names it (AreaLabelDataProvider.lua): the
--  zone's name in the game's map font, its levels after it in the colour of how
--  hard they are for you (C_Map.GetMapLevels, the game's own word; Forever tells
--  none, so there the levels of the enemies in the zone, Core's data: each
--  creature's points there in the set CreatureSpawns, by its levels in the set
--  NPCs, the bulk of them by spawn, Label.LOW and Label.HIGH of them at the ends
--  left out; Saneroki, 2026-11-11: "make the zone level the range of the enemies,
--  not the quests"); under it the fishing skill its waters ask, from where a cast
--  first catches to where none gets away, in the colour of your own fishing skill
--  (Core's set Fishing by the zone's area, Core's set Zones; Saneroki, 2026-11-10).
--  No red mark of unconfirmed data on either line: "remove the !. That is not
--  needed here" (Saneroki, 2026-11-11).
--
--      Label.Show(map, x, y)   the zone under the point x, y (0 to 1) of map (the one the view shows whole)
--      Label.Hide()            out of sight
--      Label.Range(zone)       its levels: low, high (the map's search), nil while not known
--
--  Only on the full map: the small one has no room for it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Label = {}
ns.Label = Label

Label.SCALE = 0.695 -- the label's scale, Blizzard's (AreaLabelFrameTemplate)
Label.GAP = 10      -- units between the full map's bar and the zone's name
Label.FISHING = 356 -- the game's skill line of fishing
Label.SURE = 95     -- skill over an area's base at which every cast catches (5 % at the base, one more a point)

-- A zone's enemies by spawn: the share left out at its low end (its town's few level-1 folk) and at its high end (its
-- guards, a camp of a later zone's); a creature whose levels span more than Label.SPAN is none (a pet, a summon, seen
-- at many levels); a range wider than Label.WIDE is no leveling zone's (a city, a sanctuary): none shown.
Label.LOW, Label.HIGH = 0.1, 0.2
Label.SPAN = 3
Label.WIDE = 20
Label.SKIP = { rare = true, rareelite = true, worldboss = true, trivial = true } -- ranks that are no zone's bulk

local Zones, Fishing = Core.Data.Set("Zones"), Core.Data.Set("Fishing")
local Creatures, NPCs = Core.Data.Set("CreatureSpawns"), Core.Data.Set("NPCs")
local frame, name, line
local shown   -- the zone named now, nil while none
local ranges  -- [zone] = { low, high } of its enemies, or false (none, or too wide); nil until worked out (Enemies)
local reading -- the walk over the creatures' spawns working them out
local asked   -- the last look's map and point ({ map, x, y }), to name it again once the enemies are worked out
local NONE = {}

local function Build()
    local canvas = ns.Canvas.frame
    if frame or not canvas then return frame end
    frame = CreateFrame("Frame", nil, canvas:GetParent())
    frame:SetScale(Label.SCALE)
    frame:SetSize(400, 128)
    frame:SetPoint("TOP", canvas, "TOP", 0, -(ns.TopBar.INSET + ns.TopBar.BUTTON_HEIGHT + Label.GAP) / Label.SCALE)
    frame:SetFrameLevel(canvas:GetFrameLevel() + 29) -- over the map and its pins, under the bar (30)
    name = frame:CreateFontString(nil, "OVERLAY", rawget(_G, "WorldMapTextFont") and "WorldMapTextFont" or "GameFontNormalHuge")
    name:SetPoint("TOP")
    line = frame:CreateFontString(nil, "OVERLAY", rawget(_G, "SubZoneTextFont") and "SubZoneTextFont" or "GameFontHighlightLarge")
    line:SetPoint("TOP", name, "BOTTOM", 0, -10)
    frame:Hide()
    return frame
end

-- A colour of the game's ({ r, g, b } or a ColorMixin) as an escape for words in it; nil where it has none.
local function Hex(colour)
    if type(colour) ~= "table" or type(colour.r) ~= "number" then return nil end
    return ("|cff%s"):format(Core.Hex(colour.r, colour.g, colour.b))
end

-- The game's colour of a difficulty ("difficult", "standard", ...), nil where it has none.
local function Difficulty(kind)
    local colours = rawget(_G, "QuestDifficultyColors")
    return type(colours) == "table" and colours[kind] or nil
end

-- Every zone's enemies, once: one walk over the creatures' spawns (a job of Core's scheduler), each creature that is no
-- critter, no rare and spans at most Label.SPAN levels counting its lowest and highest level once for each of its
-- points on a map; then each map's range, its ends cut by Label.LOW and Label.HIGH of that count. Again when Core's
-- creatures change.
local function Range(counts)
    local levels, total = {}, 0
    for level, count in pairs(counts) do
        levels[#levels + 1] = level
        total = total + count
    end
    table.sort(levels)
    local function From(first, last, step, share)
        local cut, seen = total * share, 0
        for index = first, last, step do
            seen = seen + counts[levels[index]]
            if seen > cut then return levels[index] end
        end
    end
    local low, high = From(1, #levels, 1, Label.LOW), From(#levels, 1, -1, Label.HIGH)
    if not low or not high or high < low or high - low > Label.WIDE then return false end
    return { low, high }
end

local function Enemies()
    if ranges or reading then return end
    local byMap = {} -- [map] = { [level] = points }
    local job = Creatures:Each(function(id, record)
        local npc = NPCs:Get(id)
        local low = type(npc) == "table" and npc.levelMin
        if type(low) ~= "number" or low <= 0 or npc.kind == "critter" or not npc.kind or Label.SKIP[npc.rank or ""] then return end
        local high = type(npc.levelMax) == "number" and npc.levelMax or low
        if high - low > Label.SPAN then return end
        for _, point in ipairs(type(record.points) == "table" and record.points or NONE) do
            local map = type(point) == "table" and point.map
            if map then
                local counts = byMap[map]
                if not counts then
                    counts = {}
                    byMap[map] = counts
                end
                counts[low] = (counts[low] or 0) + 1
                counts[high] = (counts[high] or 0) + 1
            end
        end
    end, function(problem)
        reading = nil
        if problem then return end
        ranges = {}
        for map, counts in pairs(byMap) do ranges[map] = Range(counts) end
        -- Named again with its levels where the label still shows.
        local was = shown and frame and frame:IsShown() and asked
        shown = nil
        if was then Label.Show(was[1], was[2], was[3]) end
    end)
    reading = job or nil
end

-- The zone's levels as Blizzard's map writes them after its name: " (min-max)", coloured as hard as they are for you:
-- below you as the highest less two (a zone wholly below you is not yellow), above you as its lowest, else yellow.
-- The game's own where it tells them, else its enemies' (Enemies); none while those are being worked out.
local function Levels(zone)
    local low, high = Core.Ask(C_Map.GetMapLevels, zone)
    low, high = Core.Plain(low), Core.Plain(high)
    if type(low) ~= "number" or type(high) ~= "number" or low <= 0 or high <= 0 then
        Enemies()
        local range = ranges and ranges[zone]
        if not range then return "" end
        low, high = range[1], range[2]
    end
    local level, colour = Core.Plain(UnitLevel("player")) or 1, Difficulty("difficult")
    local tell = rawget(_G, "GetQuestDifficultyColor")
    if tell and level < low then
        colour = Core.Ask(tell, low)
    elseif tell and level > high then
        colour = Core.Ask(tell, high - 2)
    end
    local words = low == high and ("(%d)"):format(high) or ("(%d-%d)"):format(low, high)
    local hex = Hex(colour)
    return " " .. (hex and hex .. words .. "|r" or words)
end

-- A zone's levels as numbers (the map's search, Find.lua: where to level): the game's own, else its enemies' (being
-- worked out the first time: nil until then).
function Label.Range(zone)
    local low, high = Core.Ask(C_Map.GetMapLevels, zone)
    low, high = Core.Plain(low), Core.Plain(high)
    if type(low) == "number" and type(high) == "number" and low > 0 and high > 0 then return low, high end
    Enemies()
    local range = ranges and ranges[zone]
    if not range then return nil end
    return range[1], range[2]
end

-- The fishing skill the zone's waters ask (its area's base in Core's set Fishing): from where a cast first catches
-- to where every one does, in red while you cannot fish there yet, yellow while fish get away, green past it. Nil where
-- the set has none.
local function Waters(zone)
    local area = Zones:Get(zone, "area")
    local base = area and Fishing:Get(area, "skill")
    if type(base) ~= "number" then return nil end
    local low, sure = math.max(1, base), base + Label.SURE
    local words = ns.TEXT.fishing:format(low, sure)
    local reach = ns.Nodes.Reach(Label.FISHING)
    local colour = reach and Difficulty(reach < low and "impossible" or reach < sure and "difficult" or "standard")
    local hex = Hex(colour)
    if hex then words = hex .. words .. "|r" end
    return words
end

function Label.Show(map, x, y)
    if ns.Canvas.camera ~= ns.Window.full or not Build() then return Label.Hide() end
    asked = asked or {}
    asked[1], asked[2], asked[3] = map, x, y
    local info = Core.Ask(C_Map.GetMapInfoAtPosition, map, x, y)
    local zone = type(info) == "table" and Core.Plain(info.mapID)
    if not zone or zone == map or type(info.name) ~= "string" then return Label.Hide() end
    if zone ~= shown then
        shown = zone
        name:SetText(info.name .. Levels(zone))
        local colour = rawget(_G, "AREA_NAME_FONT_COLOR")
        if type(colour) == "table" and colour.GetRGB then name:SetTextColor(colour:GetRGB()) end
        line:SetText(Waters(zone) or "")
        colour = rawget(_G, "AREA_DESCRIPTION_FONT_COLOR")
        if type(colour) == "table" and colour.GetRGB then line:SetTextColor(colour:GetRGB()) end
    end
    frame:Show()
end

function Label.Hide()
    shown = nil
    if frame then frame:Hide() end
end

-- A level gained, a skill learned or raised: the colours told again at the next look. Core's creatures or their spawns
-- changed: the zones' enemies worked out again when next asked.
ns.On("PLAYER_LEVEL_UP", Label.Hide)
ns.On("SKILL_LINES_CHANGED", Label.Hide)
local function Stale()
    if reading then reading:Stop() end
    ranges, reading = nil, nil
    Label.Hide()
end
Creatures:OnStamp(ns.Guard(Stale))
NPCs:OnStamp(ns.Guard(Stale))
