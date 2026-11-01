-- Threat and damage meter: Core and the module Combat from their TOCs, a made-up raid over the world, a panel beside it to pull, end fights and change the group
-- The game's meter, the threat and the group stand in here, so everything of the window itself is Sane UI's real code:
-- the mouse on it shows the buttons, the first line drags it, its corner sizes it, the wheel scrolls, the flyouts tick.
-- The panel beside it: Pull and End fight, the group's size, the window to the other half of the screen. In the
-- console: LabPull(), LabEnd(), LabGroup(25), LabHalf(), LabMeter is the module's Meter table. It begins in a fight: End
-- fight hides the meter by its setting, the mouse on its place brings it back. The game hides the numbers in a fight
-- (secret values), which only dev/tests/meter.lua runs through: here they stay plain.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer", "PartyFrame", "CompactRaidFrameContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
    if template == "SecureGroupHeaderTemplate" then template = nil end -- not in the lab; the group frames are off here
    return create(kind, name, parent, template, ...)
end
RegisterUnitWatch = function(frame) frame:Show() end
UnregisterUnitWatch = function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
SecureHandlerSetFrameRef = function() end
ClearOverrideBindings, SetOverrideBinding, GetBindingKey = function() end, function() end, function() end

-- The game's short numbers.
AbbreviateLargeNumbers = function(number)
    if number >= 1000000 then return ("%.2fM"):format(number / 1000000) end
    if number >= 10000 then return ("%.1fK"):format(number / 1000) end
    if number >= 1000 then return ("%.2fK"):format(number / 1000) end
    return ("%d"):format(number)
end

-------------------------------------------------------------------------------
--  The group
-------------------------------------------------------------------------------
local CLASSES = {
    { "WARRIOR", "tank" }, { "PRIEST", "heal" }, { "MAGE", "dps" }, { "ROGUE", "dps" }, { "DRUID", "heal" },
    { "HUNTER", "dps" }, { "WARLOCK", "dps" }, { "PALADIN", "heal" }, { "SHAMAN", "dps" }, { "WARRIOR", "dps" },
}
local FIRST = { "Aldren", "Brisa", "Caelum", "Dorin", "Elsbeth", "Fenrick", "Gwyn", "Halden", "Ilsa", "Joren", "Kestra",
                "Lorcan", "Maeve", "Nolan", "Orla", "Perrin", "Quill", "Rhosyn", "Soren", "Tamsin", "Ulric", "Vesna",
                "Wynne", "Yorick", "Zara" }
local LAST = { "Ashford", "Brightwater", "Crowley", "Dunmere", "Everhart", "Fallowfield", "Greymoor", "Hollow" }

local me = { guid = "Player-1-00000001", name = "Saneroki", surname = "Moonwhisper", class = "DRUID", role = "dps", level = 60, item = 71 }
local group = {} -- everybody but you
local units = {} -- [unit] = one of them

local function Fill(count)
    group, units = {}, { player = me }
    for index = 1, count - 1 do
        local class = CLASSES[index % #CLASSES + 1]
        group[index] = { guid = ("Player-1-%08X"):format(100 + index), name = FIRST[index % #FIRST + 1],
                         surname = LAST[index % #LAST + 1], class = class[1], role = class[2],
                         level = 60 - (index * 7) % 4, item = 62 + (index * 11) % 17 }
        units[(count > 5 and "raid" or "party") .. (count > 5 and index + 1 or index)] = group[index]
    end
    if count > 5 then units.raid1 = me end
end

IsInGroup = function() return #group > 0 end
IsInRaid = function() return #group >= 5 end
GetNumGroupMembers = function() return #group > 0 and #group + 1 or 0 end
GetNumSubgroupMembers = function() return math.min(#group, 4) end
local game = { UnitGUID = UnitGUID, UnitName = UnitName, UnitClass = UnitClass, UnitLevel = UnitLevel, UnitExists = UnitExists }
UnitGUID = function(unit)
    if units[unit] then return units[unit].guid end
    return game.UnitGUID(unit)
end
UnitName = function(unit)
    if units[unit] then return units[unit].name, units[unit].surname end
    return game.UnitName(unit)
end
UnitClass = function(unit)
    if units[unit] then return units[unit].class, units[unit].class end
    return game.UnitClass(unit)
end
UnitLevel = function(unit)
    if units[unit] then return units[unit].level end
    return game.UnitLevel(unit)
end
UnitExists = function(unit)
    if unit == "target" then return true end
    return units[unit] ~= nil or game.UnitExists(unit)
end
UnitCanAttack = function() return true end

-------------------------------------------------------------------------------
--  The game's meter and threat
-------------------------------------------------------------------------------
local RATES = { tank = { 90, 12, 0.02 }, heal = { 12, 210, 0.01 }, dps = { 230, 4, 0.05 } } -- damage, healing, interrupts a second
local MOBS = { "Hogger", "Vancleef", "Ragnaros", "Onyxia", "Nefarian" }
local NAMES = { [0] = "damage", [1] = "damage", [2] = "healing", [3] = "healing", [5] = "interrupts" }
local fights, current, nextID = {}, nil, 1
local threat = {}
local fighting = false

local function Everyone()
    local all = { me }
    for _, person in ipairs(group) do all[#all + 1] = person end
    return all
end

local function Gain()
    if not current then return end
    current.seconds = current.seconds + 0.25
    for _, person in ipairs(Everyone()) do
        local rates, numbers = RATES[person.role], current.by[person.guid]
        if not numbers then
            numbers = { damage = 0, healing = 0, interrupts = 0, person = person, skill = 0.75 + math.random() * 0.5 }
            current.by[person.guid] = numbers
        end
        numbers.damage = numbers.damage + rates[1] * numbers.skill * (0.6 + math.random() * 0.8) * 0.25
        numbers.healing = numbers.healing + rates[2] * numbers.skill * (0.5 + math.random()) * 0.25
        if math.random() < rates[3] * 0.25 then numbers.interrupts = numbers.interrupts + 1 end
        threat[person.guid] = (threat[person.guid] or 0)
            + (person.role == "tank" and 900 or 100) * numbers.skill * (0.6 + math.random() * 0.8) * 0.25 * 100
    end
    Lab.Fire("DAMAGE_METER_CURRENT_SESSION_UPDATED")
end

local function Sources(fights_, kind)
    local by = {}
    for _, fight in ipairs(fights_) do
        for guid, numbers in pairs(fight.by) do
            by[guid] = by[guid] or { person = numbers.person, amount = 0 }
            by[guid].amount = by[guid].amount + numbers[kind]
        end
    end
    local seconds = 0
    for _, fight in ipairs(fights_) do seconds = seconds + fight.seconds end
    local list, top, total = {}, 0, 0
    for guid, one in pairs(by) do
        list[#list + 1] = { sourceGUID = guid, name = one.person.name, classFilename = one.person.class,
                            totalAmount = math.floor(one.amount), isLocalPlayer = one.person == me,
                            amountPerSecond = one.amount / math.max(seconds, 1) }
        top, total = math.max(top, math.floor(one.amount)), total + one.amount
    end
    table.sort(list, function(a, b) return a.totalAmount > b.totalAmount end)
    return { combatSources = list, maxAmount = top, totalAmount = total, durationSeconds = seconds }
end

C_DamageMeter.IsDamageMeterAvailable = function() return true, "" end
C_DamageMeter.GetAvailableCombatSessions = function()
    local list = {}
    for index, fight in ipairs(fights) do
        list[index] = { sessionID = fight.id, name = fight.name, durationSeconds = fight.seconds }
    end
    return list
end
C_DamageMeter.GetCombatSessionFromType = function(sessionType, kind)
    if sessionType == Enum.DamageMeterSessionType.Overall then return Sources(fights, NAMES[kind]) end
    return Sources({ fights[#fights] }, NAMES[kind])
end
C_DamageMeter.GetCombatSessionFromID = function(id, kind)
    for _, fight in ipairs(fights) do
        if fight.id == id then return Sources({ fight }, NAMES[kind]) end
    end
    return Sources({}, NAMES[kind])
end

UnitDetailedThreatSituation = function(unit)
    local person = units[unit]
    if not person or not fighting then return nil end
    local top = 0
    for _, value in pairs(threat) do top = math.max(top, value) end
    local value = threat[person.guid] or 0
    local share = top > 0 and value / top * 100 or 0
    return value == top, value == top and 3 or 0, share, share, value
end

-------------------------------------------------------------------------------
--  Fights
-------------------------------------------------------------------------------
local ticker

function LabPull()
    if fighting then return end
    fighting = true
    current = { id = nextID, name = MOBS[(nextID - 1) % #MOBS + 1], seconds = 0, by = {} }
    nextID = nextID + 1
    fights[#fights + 1] = current
    threat = {}
    InCombatLockdown = function() return true end
    Lab.Fire("PLAYER_REGEN_DISABLED")
    ticker = C_Timer.NewTicker(0.25, Gain)
end

function LabEnd()
    if not fighting then return end
    fighting = false
    ticker:Cancel()
    current = nil
    InCombatLockdown = function() return false end
    Lab.Fire("PLAYER_REGEN_ENABLED")
    Lab.Fire("DAMAGE_METER_CURRENT_SESSION_UPDATED")
end

function LabGroup(count)
    Fill(count)
    Lab.Fire("GROUP_ROSTER_UPDATE")
end

-- The window into the other half of the screen, so it grows the other way.
function LabHalf()
    local handle = LabMeter.handle
    local frame = handle.frame
    local _, y = frame:GetCenter()
    frame:ClearAllPoints()
    frame:SetPoint(y > UIParent:GetHeight() / 2 and "BOTTOMLEFT" or "TOPLEFT", UIParent,
                   y > UIParent:GetHeight() / 2 and "BOTTOMLEFT" or "TOPLEFT", 320, y > UIParent:GetHeight() / 2 and 140 or 0)
    handle.options.docked()
end

-------------------------------------------------------------------------------
--  The scene
-------------------------------------------------------------------------------
Fill(10)
Lab.TOC("src/Core/SaneUI.toc")
LabCombat = Lab.TOC("src/Combat/SaneUI_Combat.toc")
LabCombat.UnitAuras.missing = true -- the lab has no aura containers
SaneUI.Core.HealthMarks.missing = true
SaneUI.Core.Inspect.Level = function(unit)
    return units[unit] and units[unit].item
end

-- The panel beside the meter, in sight without scrolling at the page's 100 %.
local function Panel()
    local panel = CreateFrame("Frame", nil, UIParent)
    panel:SetSize(104, 8 * 28 + 8)
    panel:SetPoint("TOPLEFT", 640, -30)
    panel:SetFrameStrata("HIGH")
    local back = panel:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.55)
    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, 4)
    note:SetText("The lab's own, no part of the meter")
    local at = -4
    local function Button(text, click)
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(96, 24)
        button:SetPoint("TOP", 0, at)
        button:SetText(text)
        button:SetScript("OnClick", click)
        at = at - 28
    end
    Button("Pull", LabPull)
    Button("End fight", LabEnd)
    Button("Alone", function() LabGroup(1) end)
    Button("Party", function() LabGroup(5) end)
    Button("Raid 10", function() LabGroup(10) end)
    Button("Raid 25", function() LabGroup(25) end)
    Button("Raid 40", function() LabGroup(40) end)
    Button("Other half", LabHalf)
end

local function Backdrop()
    local world = CreateFrame("Frame", nil, UIParent)
    world:SetAllPoints(UIParent)
    world:SetFrameStrata("BACKGROUND")
    world:SetFrameLevel(0)
    local picture = world:CreateTexture(nil, "BACKGROUND")
    picture:SetAllPoints(world)
    picture:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")
    local log = world:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    log:SetPoint("TOPLEFT", 8, -8)
    log:SetText("Where the quest log stands: 320 wide")
end

Lab.OnLogin(function()
    for _, key in ipairs({ "unitPlayer", "unitCast", "unitBreath", "unitPet", "unitTarget", "unitTargetTarget", "unitFocus",
                           "unitFocusTarget", "group", "mouseCooldown", "mouseCast" }) do
        SaneUI.Core.Set("Combat", key, false)
    end
    LabMeter = LabCombat.Meter
    Backdrop()
    Panel()
    LabPull()
end)
