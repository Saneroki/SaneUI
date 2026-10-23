local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Marks
--  The raid marker, outside the bar at its left end, left of the quest's icon
--  (Text.lua), as large as the line's icons; it shows only while there is one.
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

Marks.ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
-- The raid markers' grid in that file, as the game counts it.
local ROWS, COLUMNS = rawget(_G, "RAID_TARGET_TEXTURE_ROWS") or 4, rawget(_G, "RAID_TARGET_TEXTURE_COLUMNS") or 4

function Marks.Make(dress)
    local raid = dress.top:CreateTexture(nil, "OVERLAY")
    raid:SetTexture(Marks.ICONS)
    raid:SetSize(ns.Text.size, ns.Text.size)
    raid:Hide()
    dress.raid = raid
end

function Marks.Raid(dress, unit)
    local raid = dress.raid
    local index = unit and ns.Bar.Raw(GetRaidTargetIndex, unit)
    local foe = unit and Plain(UnitIsPlayer(unit)) and not Plain(UnitIsFriend("player", unit))
    local on = type(index) ~= "nil" and not foe
    if on then raid:SetSpriteSheetCell(index, ROWS, COLUMNS) end
    raid:SetShown(on)
    ns.Text.Room(dress, "raid", on and ns.Text.size or nil)
end
