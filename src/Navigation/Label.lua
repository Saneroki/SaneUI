local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Label
--  What lights up under the mouse (Art.Light), named at the top of the full map,
--  under its bar, as Blizzard's map names it (AreaLabelDataProvider.lua): the
--  zone's name in the game's map font, its levels after it in the colour of how
--  hard they are for you (C_Map.GetMapLevels, the game's own word); under it the
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

local Zones, Fishing = Core.Data.Set("Zones"), Core.Data.Set("Fishing")
local frame, name, line
local shown -- the zone named now, nil while none

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

-- The zone's levels as Blizzard's map writes them after its name: " (min-max)", coloured as hard as they are for you:
-- below you as the highest less two (a zone wholly below you is not yellow), above you as its lowest, else yellow.
local function Levels(zone)
    local low, high = Core.Ask(C_Map.GetMapLevels, zone)
    low, high = Core.Plain(low), Core.Plain(high)
    if type(low) ~= "number" or type(high) ~= "number" or low <= 0 or high <= 0 then return "" end
    local level, colour = Core.Plain(UnitLevel("player")) or 1, Difficulty("difficult")
    local tell = rawget(_G, "GetQuestDifficultyColor")
    if tell and level < low then
        colour = Core.Ask(tell, low)
    elseif tell and level > high then
        colour = Core.Ask(tell, high - 2)
    end
    local words = low == high and (" (%d)"):format(high) or (" (%d-%d)"):format(low, high)
    local hex = Hex(colour)
    return hex and hex .. words .. "|r" or words
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

-- A level gained, a skill learned or raised: the colours told again at the next look.
ns.On("PLAYER_LEVEL_UP", Label.Hide)
ns.On("SKILL_LINES_CHANGED", Label.Hide)
