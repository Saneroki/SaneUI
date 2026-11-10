local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Label
--  What lights up under the mouse (Art.Light), named at the top of the full map,
--  under its bar, as Blizzard's map names it (AreaLabelDataProvider.lua): the
--  zone's name in the game's map font, its levels after it in the colour of how
--  hard they are for you (C_Map.GetMapLevels, the game's own word; Forever tells
--  none, so there the levels of the quests given in the zone, Core's data: its
--  Data.Map's quest givers and the set Quests, those of your side and of every
--  class, Label.TRIM of them at each end left out; Saneroki, 2026-11-11: "Forever's
--  quest levels"; the red mark before them while one is not yet confirmed); under it the
--  fishing skill its waters ask, from where a cast first catches to where none
--  gets away, in the colour of your own fishing skill (Core's set Fishing by the
--  zone's area, Core's set Zones; Saneroki, 2026-11-10). That set is the older
--  game's, not yet confirmed: its line starts with the red mark.
--
--      Label.Show(map, x, y)   the zone under the point x, y (0 to 1) of map (the one the view shows whole)
--      Label.Hide()            out of sight
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

Label.TRIM = 0.1   -- the share of a zone's quests left out at each end of their levels (a few far off its bulk)
Label.FEW = 5      -- a zone with fewer quests than this: every one counts

local Zones, Fishing, Quests = Core.Data.Set("Zones"), Core.Data.Set("Fishing"), Core.Data.Set("Quests")
local Map = Core.Data.Map()
local frame, name, line
local shown -- the zone named now, nil while none
local ranges = {} -- [zone] = { low, high, doubt } from its quests, or false (none there); until Core's places change
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

-- The levels of the quests given in a zone (Core's data: the quest givers standing there, Data.Map, and their quests in
-- the set Quests), those of the player's side or of both and of every class (a class's own skews a city), sorted, the
-- far few at each end left out (Label.TRIM, from Label.FEW quests on): low, high, and whether one of them is not yet
-- confirmed; nil where none, or while Core's places are first read.
local function FromQuests(zone)
    local known = ranges[zone]
    if known ~= nil then return known or nil end
    local places = Map:On(zone)
    if not places then return nil end
    local side = Core.Plain(UnitFactionGroup("player"))
    side = type(side) == "string" and side:lower() or nil
    local levels, seen, doubt = {}, {}, false
    for _, place in ipairs(places) do
        local what = place.kind == "npc" and place.what
        for _, id in ipairs(type(what) == "table" and what.quests or NONE) do
            if not seen[id] then
                seen[id] = true
                local quest = Quests:Get(id)
                local level = type(quest) == "table" and quest.level
                if type(level) == "number" and level > 0 and not quest.classes and (not quest.side or quest.side == side) then
                    levels[#levels + 1] = level
                    doubt = doubt or Quests:Unverified(id)
                end
            end
        end
    end
    if #levels == 0 then
        ranges[zone] = false
        return nil
    end
    table.sort(levels)
    local cut = #levels >= Label.FEW and math.floor(#levels * Label.TRIM) or 0
    known = { levels[1 + cut], levels[#levels - cut], doubt }
    ranges[zone] = known
    return known
end

-- The zone's levels as Blizzard's map writes them after its name: " (min-max)", coloured as hard as they are for you:
-- below you as the highest less two (a zone wholly below you is not yellow), above you as its lowest, else yellow.
-- The game's own where it tells them, else its quests' (FromQuests), the red mark before them while not confirmed.
local function Levels(zone)
    local low, high = Core.Ask(C_Map.GetMapLevels, zone)
    low, high = Core.Plain(low), Core.Plain(high)
    local mark = ""
    if type(low) ~= "number" or type(high) ~= "number" or low <= 0 or high <= 0 then
        local range = FromQuests(zone)
        if not range then return "" end
        low, high = range[1], range[2]
        if range[3] then mark = " " .. Core.UNCONFIRMED_MARK end
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
    return (mark ~= "" and mark or " ") .. (hex and hex .. words .. "|r" or words)
end

-- The fishing skill the zone's waters ask (its area's base in Core's set Fishing): from where a cast first catches
-- to where every one does, in red while you cannot fish there yet, yellow while fish get away, green past it; the
-- red mark before it while the game has not confirmed it. Nil where the set has none.
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
    if Fishing:Unverified(area) then words = Core.UNCONFIRMED_MARK .. words end
    return words
end

function Label.Show(map, x, y)
    if ns.Canvas.camera ~= ns.Window.full or not Build() then return Label.Hide() end
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

-- A level gained, a skill learned or raised: the colours told again at the next look. Core's places or quests changed:
-- the zones' quest levels worked out again.
ns.On("PLAYER_LEVEL_UP", Label.Hide)
ns.On("SKILL_LINES_CHANGED", Label.Hide)
Map:OnChange(ns.Guard(function()
    wipe(ranges)
    Label.Hide()
end))
