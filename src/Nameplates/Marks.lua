local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Marks
--  Right of a plate's bar: the raid marker, at the size the game's plates
--  give it. The unit's rank is the bar's border (Bar.lua), its level inside
--  the bar (Text.lua); the crowd control on it stands right of the marker, or
--  of the bar where there is none (Auras.lua).
--
--  The raid marker's number may be hidden from addons (a secret value): the
--  texture takes it as it is (SetSpriteSheetCell, the game's icon grid), and
--  only whether there is one is looked at (its type: none, or a value). As on
--  the game's own plates, a player you could fight shows no marker.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Marks = {}
ns.Marks = Marks

Marks.RAID = 22 -- the game's raid marker on its plates
Marks.GAP = 2
Marks.ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
-- The raid markers' grid in that file, as the game counts it.
local ROWS, COLUMNS = rawget(_G, "RAID_TARGET_TEXTURE_ROWS") or 4, rawget(_G, "RAID_TARGET_TEXTURE_COLUMNS") or 4

function Marks.Make(dress)
    local raid = dress:CreateTexture(nil, "ARTWORK")
    raid:SetTexture(Marks.ICONS)
    raid:SetSize(Marks.RAID, Marks.RAID)
    raid:SetPoint("LEFT", dress, "RIGHT", Marks.GAP, 0)
    raid:Hide()
    dress.raid = raid
end

function Marks.Raid(dress, unit)
    local raid = dress.raid
    local index = unit and ns.Bar.Raw(GetRaidTargetIndex, unit)
    local foe = unit and Plain(UnitIsPlayer(unit)) and not Plain(UnitIsFriend("player", unit))
    if type(index) == "nil" or foe then
        raid:Hide()
    else
        raid:SetSpriteSheetCell(index, ROWS, COLUMNS)
        raid:Show()
    end
    ns.Auras.Place(dress)
end
