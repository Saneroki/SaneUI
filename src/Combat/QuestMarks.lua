local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - QuestMarks
--  A small mark beside a creature's nameplate while it belongs to a quest in your
--  log with an objective still to do, as the game itself says in the creature's
--  tooltip data (Core.UnitQuest, src/Core/Objectives.lua): the game's sword where
--  the objective names the creature (to kill), its sack otherwise (to loot), and
--  left of it the count ("3/8") of the first objective still open. Nothing is
--  guessed: a creature the game says nothing about has no mark. While our
--  nameplates dress the plates (Nameplates/), they show the same inside their own bar, and there is no mark.
--
--  A frame of ours on the plate, kept per plate while the game shows it
--  (NAME_PLATE_UNIT_ADDED, _REMOVED), looked at again when the quest log changes
--  (once a frame). Display only: nothing of the plate's own is touched, and the
--  plates the game forbids to addons and players' plates have none. In a fight
--  the game may hide what the tooltip says (a secret value): the mark stays as it
--  was until it says again. The setting Quest marks on nameplates switches it off.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local QuestMarks = {}
ns.QuestMarks = QuestMarks

QuestMarks.SIZE = 18 -- the mark, a square
-- The game's mouse cursors for a creature to fight and one to loot, as SaneUI's tooltips show objectives.
QuestMarks.ICONS = { kill = "Interface\\CURSOR\\Attack", loot = "Interface\\CURSOR\\LootAll" }

local shown = {}  -- [unit token] = the mark on its plate
local byPlate = {} -- [plate] = its mark, made once per plate the game hands out (it reuses its plates)

-- What is still to do about a creature, as the game says (Core.UnitQuest): "kill" or "loot" and the count ("3/8",
-- or ""); nil when nothing; false when the game hides it now (a secret value).
function QuestMarks.Read(unit)
    return Core.UnitQuest(unit)
end

-- Whether our nameplates show the quest inside their own bar (Nameplates/: the switch Nameplates on, started): then no
-- mark beside the plate.
local function Dressed()
    return ns.Nameplates.Dressing()
end

local function Make(plate)
    local mark = CreateFrame("Frame", nil, plate)
    mark:SetSize(QuestMarks.SIZE, QuestMarks.SIZE)
    mark.icon = mark:CreateTexture(nil, "OVERLAY")
    mark.icon:SetAllPoints()
    mark.count = mark:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark.count:SetPoint("RIGHT", mark, "LEFT", -1, 0)
    byPlate[plate] = mark
    return mark
end

-- A creature's mark as the game says now; hidden when there is nothing to do, kept while the game hides it. With
-- the setting off nothing of the game's is read.
local function Mark(unit)
    local mark = shown[unit]
    if not mark then return end
    if not ns.options.questMarks then return mark:Hide() end
    local kind, count = QuestMarks.Read(unit)
    if kind == false then return end
    if not kind then return mark:Hide() end
    mark.icon:SetTexture(QuestMarks.ICONS[kind])
    mark.count:SetText(count)
    mark:Show()
end

-- Plates come and go after the module stood down too (the events still come): then nothing is marked.
local function Added(unit)
    if ns.off or not unit or Plain(UnitIsPlayer(unit)) or Dressed() then return end
    local plate = Core.Ask(C_NamePlate.GetNamePlateForUnit, unit)
    if type(plate) ~= "table" then return end -- a plate the game forbids to addons
    local mark = byPlate[plate] or Make(plate)
    -- Left of the plate's health bar, where the game's plate has one (its fields read, never written).
    local unitFrame = rawget(plate, "UnitFrame")
    local bar = type(unitFrame) == "table" and rawget(unitFrame, "healthBar")
    local anchor = type(bar) == "table" and bar or type(unitFrame) == "table" and unitFrame or plate
    mark:ClearAllPoints()
    mark:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
    mark:Hide()
    shown[unit] = mark
    Mark(unit)
end

local function Removed(unit)
    if ns.off then return end
    local mark = unit and shown[unit]
    if mark then mark:Hide() end
    if unit then shown[unit] = nil end
end

-- Every mark looked at again (the quest log changed, the setting).
function QuestMarks.Update()
    for unit in pairs(shown) do Mark(unit) end
end
local again = Core.Later(ns.Guard(QuestMarks.Update)) -- once a frame, however often the log says it changed

function QuestMarks.Start()
    ns.On("NAME_PLATE_UNIT_ADDED", Added)
    ns.On("NAME_PLATE_UNIT_REMOVED", Removed)
    ns.On("QUEST_LOG_UPDATE", again)
    ns.On("UNIT_QUEST_LOG_CHANGED", again)
end

-- Every mark out of sight (the module stood down).
function QuestMarks.Hide()
    for _, mark in pairs(byPlate) do mark:Hide() end
    wipe(shown)
end
