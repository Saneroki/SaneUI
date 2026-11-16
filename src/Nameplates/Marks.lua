local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Marks
--  The raid marker, in the line right after the level (Text.lua), as on Sane
--  UI's unit frames, as large as the line's icons; it shows only while there
--  is one.
--
--  The raid marker's number may be hidden from addons (a secret value): the
--  texture takes it as it is (SetSpriteSheetCell, the game's icon grid), and
--  only whether there is one is looked at (its type: none, or a value). As on
--  the game's own plates, a player you could fight shows no marker.
--
--  With the setting Plates show at Spells only (no bar, no name; Saneroki,
--  2026-11-09) two marks more: a small faint dot in the plate's middle, in the
--  colour its bar would have, "so people know there is a nameplate" (the
--  setting Dot where a plate is; a raid marker there stands in its place), and
--  the game's gold arrow over your target's plate, above its debuffs (his
--  pick: the character list's arrow, the catalogue's #47). All three are on a
--  frame of their own over the line's, so they stay while the line is away.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Marks = {}
ns.Marks = Marks

Marks.ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
-- The raid markers' grid in that file, as the game counts it.
local ROWS, COLUMNS = rawget(_G, "RAID_TARGET_TEXTURE_ROWS") or 4, rawget(_G, "RAID_TARGET_TEXTURE_COLUMNS") or 4
Marks.ARROW = "glues-characterSelect-icon-arrowDown" -- the game's gold arrow pointing down, in both games
Marks.ARROW_FILE = "Interface\\Buttons\\Arrow-Down-Up" -- the game's older one, should the atlas be gone
Marks.ARROW_SIZE = 24 -- its square (the arrow fills about two thirds of it)
Marks.DOT = 6         -- the dot, across
Marks.FAINT = 0.5     -- how much of the dot shows

function Marks.Make(dress)
    local marks = CreateFrame("Frame", nil, dress)
    marks:SetAllPoints(dress)
    marks:SetFrameLevel(Plain(dress.top:GetFrameLevel()) or 1)
    local raid = marks:CreateTexture(nil, "OVERLAY")
    raid:SetTexture(Marks.ICONS)
    raid:SetSize(ns.Text.size, ns.Text.size)
    raid:Hide()
    local dot = marks:CreateTexture(nil, "ARTWORK")
    dot:SetTexture(ns.Bar.WHITE)
    dot:SetSize(Marks.DOT, Marks.DOT)
    dot:SetPoint("CENTER", dress, "CENTER")
    dot:SetVertexColor(1, 1, 1, Marks.FAINT)
    Core.Shape.Round(dot)
    dot:Hide()
    -- Above the row of your debuffs (Auras.lua), where it stands whether they show or not.
    local arrow = marks:CreateTexture(nil, "OVERLAY")
    local atlases = rawget(_G, "C_Texture")
    if atlases and Core.Ask(atlases.GetAtlasInfo, Marks.ARROW) then
        arrow:SetAtlas(Marks.ARROW)
    else
        arrow:SetTexture(Marks.ARROW_FILE)
    end
    arrow:SetSize(Marks.ARROW_SIZE, Marks.ARROW_SIZE)
    arrow:SetPoint("BOTTOM", dress, "TOP", 0, ns.Auras.SIZE)
    arrow:Hide()
    dress.raid, dress.dot, dress.arrow = raid, dot, arrow
end

function Marks.Raid(dress, unit)
    local raid = dress.raid
    local index = unit and ns.Bar.Raw(GetRaidTargetIndex, unit)
    local foe = unit and Plain(UnitIsPlayer(unit)) and not Plain(UnitIsFriend("player", unit))
    local on = type(index) ~= "nil" and not foe and (ns.options or {}).marker ~= false -- the setting Raid markers
    if on then raid:SetSpriteSheetCell(index, ROWS, COLUMNS) end
    raid:SetShown(on)
    ns.Text.Room(dress, "raid", on and ns.Text.size or nil)
    Marks.Spells(dress)
end

-- Spells only (ns.Style): the dot while its setting is on and no raid marker stands there; the arrow on your target's
-- plate. Neither otherwise. Asked again at each change of target (Plate.lua's Wear).
function Marks.Spells(dress)
    local bare = dress.unit ~= nil and ns.Style() == "spells"
    dress.dot:SetShown(bare and (ns.options or {}).dot == true and not dress.raid:IsShown())
    dress.arrow:SetShown(bare and Plain(UnitIsUnit(dress.unit, "target")) == true)
end

-- The dot in the colour the bar has (Bar.Paint), faint.
function Marks.Hue(dress, r, g, b)
    dress.dot:SetVertexColor(r, g, b, Marks.FAINT)
end
