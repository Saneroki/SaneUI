local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Marks
--  Right of a plate's bar, or of the game's level box beside it where its
--  plate shows one: the mark on a rare (the game's own marks for its plates:
--  the silver star of a rare, the silver dragon of a rare elite), and right of
--  it, or in its place where there is none, the raid marker. At the sizes the
--  game's plates give them.
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

Marks.RARE = 20 -- the game's classification mark on its plates
Marks.RAID = 22 -- the game's raid marker on its plates
Marks.GAP = 2
Marks.ATLAS = { rare = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star", rareelite = "nameplates-icon-elite-silver" }
Marks.ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
-- The raid markers' grid in that file, as the game counts it.
local ROWS, COLUMNS = rawget(_G, "RAID_TARGET_TEXTURE_ROWS") or 4, rawget(_G, "RAID_TARGET_TEXTURE_COLUMNS") or 4

function Marks.Make(dress)
    local rare = dress:CreateTexture(nil, "ARTWORK")
    rare:SetSize(Marks.RARE, Marks.RARE)
    rare:SetPoint("LEFT", dress, "RIGHT", Marks.GAP, 0)
    rare:Hide()
    local raid = dress:CreateTexture(nil, "ARTWORK")
    raid:SetTexture(Marks.ICONS)
    raid:SetSize(Marks.RAID, Marks.RAID)
    raid:SetPoint("LEFT", dress, "RIGHT", Marks.GAP, 0)
    raid:Hide()
    dress.rare, dress.raid = rare, raid
end

-- The game's mark for a unit's classification, where it is a rare; nil otherwise.
function Marks.Atlas(unit)
    local classification = Plain(UnitClassification(unit))
    return type(classification) == "string" and Marks.ATLAS[classification] or nil
end

-- What the marks stand right of: the game's level box where its plate shows one beside the bar (this
-- client's plates do, right of the bar), else our bar.
local function Beside(dress)
    local level = dress.frame and rawget(dress.frame, "PlayerLevelDiffFrame")
    if type(level) == "table" and Plain(level:IsShown()) then return level end
    return dress
end

function Marks.Rare(dress, unit)
    local atlas = unit and Marks.Atlas(unit)
    local rare, raid = dress.rare, dress.raid
    local beside = Beside(dress)
    if atlas then
        rare:SetAtlas(atlas)
        rare:Show()
    else
        rare:Hide()
    end
    rare:ClearAllPoints()
    rare:SetPoint("LEFT", beside, "RIGHT", Marks.GAP, 0)
    raid:ClearAllPoints()
    raid:SetPoint("LEFT", atlas and rare or beside, "RIGHT", Marks.GAP, 0)
end

function Marks.Raid(dress, unit)
    local raid = dress.raid
    local index = unit and ns.Bar.Raw(GetRaidTargetIndex, unit)
    local foe = unit and Plain(UnitIsPlayer(unit)) and not Plain(UnitIsFriend("player", unit))
    if type(index) == "nil" or foe then return raid:Hide() end
    raid:SetSpriteSheetCell(index, ROWS, COLUMNS)
    raid:Show()
end
