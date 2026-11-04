-- The satchel: the button on the small map and its page of the sound line, the addons' buttons, the pins and the
-- game's tracking (Satchel.lua, Strays.lua, AudioLine.lua). The rest of Navigation stands in: a small map in the top right corner, the game's minimap
-- with a pretend addon's button on it, the game's addon compartment with two addons, a few kinds of pin and tracking
-- entries. In the console, LabSatchel.pins holds which kinds show, LabSatchel.tracking the game's entries and
-- LabSatchel.Satchel the module's table. The page opens by itself here, so it waits for the mouse to come first.
Lab.TOC("src/Core/SaneUI.toc")
local Core = SaneUI.Core
local ns = Lab.Addon("SaneUI_Navigation")
Core.NewModule("SaneUI_Navigation", "Navigation", ns)

local lab = { pins = { flight = true, travel = true, entrance = true, place = true, rare = true, foundHerb = true } }
LabSatchel = lab
ns.options = {}
ns.Pins = { Shows = function(key) return lab.pins[key] or false end }
ns.KindOffered = function() return true end
ns.SwitchPin = function(key)
    lab.pins[key] = not lab.pins[key] or nil
    ns.Satchel.Fill()
end
ns.PIN_SECTIONS = { { "around", "Around you" }, { "quests", "Quests" }, { "travel", "Travel" },
                    { "towns", "Towns and services" }, { "finds", "Rares and treasures" }, { "gathering", "Gathering" } }
ns.KINDS = {
    { "route", "Route to the map pin", section = "around", icon = "poi-traveldirections-arrow" },
    { "minimap", "Minimap dots", section = "around", icon = "monsterneutral" },
    { "log", "Quests in your log", section = "quests", icon = "questturnin" },
    { "area", "Quest areas", section = "quests", icon = "questblob" },
    { "flight", "Flight points", section = "travel", icon = "flightmaster" },
    { "travel", "Boats, zeppelins and portals", section = "travel", icon = "flightmasterferry" },
    { "entrance", "Dungeons and raids", section = "travel", icon = "dungeon" },
    { "place", "Places", section = "towns", icon = "poi-town" },
    { "rare", "Rares", section = "finds", icon = "dungeonskull" },
    { "treasure", "Treasures", section = "finds", icon = "vignetteloot" },
    { "foundHerb", "Found herbs", section = "gathering", texture = 133939 },
    { "foundOre", "Found ore", section = "gathering", texture = 136025 },
    { "foundFish", "Found fishing pools", section = "gathering", texture = 133888 },
    { "group", "Party and raid", section = "around", icon = "partymember" },
}
ns.Nodes = { KIND = { [2383] = "herb", [2580] = "ore", [43308] = "fish" },
             FOUND = { herb = "foundHerb", ore = "foundOre", fish = "foundFish" },
             Picture = function() return nil end, TooHard = function() return false end }
ns.Coords = {}
ns.Hybrid = { Taken = function() return true end, Release = function() return false end }

-- The game's tracking, as its menu lists it (the finders left out by the satchel).
lab.tracking = {
    { name = "Find Herbs", spellID = 2383, type = "spell", texture = 133939, active = true },
    { name = "Find Minerals", spellID = 2580, type = "spell", texture = 136025, active = false },
    { name = "Track Beasts", spellID = 1494, type = "spell", texture = 132328, active = false },
    { name = "Banker", type = "other", texture = 136453, active = true, filter = "Banker" },
    { name = "Mailbox", type = "other", texture = 136456, active = false, filter = "Mailbox" },
    { name = "Innkeeper", type = "other", texture = 136458, active = true, filter = "Innkeeper" }, -- always on: not listed
}
C_Minimap = C_Minimap or {}
C_Minimap.GetNumTrackingTypes = function() return #lab.tracking end
C_Minimap.GetTrackingInfo = function(index) return lab.tracking[index] end
-- Its filters, as Retail's tracking menu reads them: a spell's, or one of the game's optional ones (Satchel.OPTIONAL).
C_Minimap.GetTrackingFilter = function(index)
    local entry = lab.tracking[index]
    return entry and { filterID = entry.filter and Enum.MinimapTrackingFilter[entry.filter] or 0, spellID = entry.spellID }
end
C_Minimap.SetTracking = function(index, on) lab.tracking[index].active = on end
MinimapUtil = nil

-- The game's minimap (the lab has none) with another addon's button on it, its global set by that addon, as the game's
-- issecurevariable tells; and the game's addon compartment.
Minimap = CreateFrame("Frame", "Minimap", UIParent)
Minimap:SetSize(140, 140)
Minimap:SetPoint("CENTER")
Minimap:Hide()
local stray = CreateFrame("Button", "LabAddonMinimapButton", Minimap)
stray:SetSize(31, 31)
stray:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
local back = stray:CreateTexture(nil, "BACKGROUND")
back:SetSize(20, 20)
back:SetPoint("TOPLEFT", 7, -5)
back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
local face = stray:CreateTexture(nil, "ARTWORK")
face:SetSize(17, 17)
face:SetPoint("TOPLEFT", 7, -6)
face:SetTexture(134400)
local border = stray:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
stray:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Lab Addon")
    GameTooltip:Show()
end)
stray:SetScript("OnLeave", function() GameTooltip:Hide() end)
stray:SetScript("OnClick", function() print("Lab Addon's own button clicked") end)
issecurevariable = function(name) if name:find("^LabAddon") then return false, "LabAddon" end return true, nil end
AddonCompartmentFrame = CreateFrame("Frame", "AddonCompartmentFrame", UIParent)
AddonCompartmentFrame.registeredAddons = {
    { text = "Lab Addon", icon = 134400, func = function() end },
    { text = "|cff33ff99Compartment|r Addon", icon = 133784,
      func = function(_, input) print("Compartment Addon: " .. tostring(input.buttonName)) end },
}

-- What the lab does not tell of the game's minimap and clock: the realm's time, the latency, new mail, an invitation,
-- the game's calendar button, its clock window and stopwatch (stand-ins: their windows are the lab's empty frames).
GetGameTime = function() return 17, 5 end
GetNetStats = function() return 0, 0, 35, 41 end
HasNewMail = function() return true end
GetLatestThreeSenders = function() return "Mirabel Ashgrove", "Tobin" end
C_Calendar = C_Calendar or {}
C_Calendar.GetNumPendingInvites = function() return 1 end
CreateFrame("Button", "GameTimeFrame", UIParent):Hide()
TimeManagerFrame = CreateFrame("Frame", "TimeManagerFrame", UIParent)
TimeManagerFrame:Hide()
StopwatchFrame = CreateFrame("Frame", "StopwatchFrame", UIParent)
StopwatchFrame:Hide()
TimeManager_Toggle = function() TimeManagerFrame:SetShown(not TimeManagerFrame:IsShown()) end
Stopwatch_Toggle = function() StopwatchFrame:SetShown(not StopwatchFrame:IsShown()) end
TimeManager_IsAlarmFiring = function() return false end
TimeManager_TurnOffAlarm = function() end

-- The game's five sounds, for the sound line (AudioLine.lua, Core's sound profiles): music low, the rest at full.
for _, kind in ipairs(Core.Audio.KINDS) do
    C_CVar.SetCVar(kind.on, "1")
    C_CVar.SetCVar(kind.volume, kind.key == "music" and "0.4" or "1")
end

Lab.Addon("SaneUI_Navigation", "src/Navigation/Found.lua", "src/Navigation/Strays.lua", "src/Navigation/Satchel.lua",
    "src/Navigation/AudioLine.lua")

-- The small map's stand-in in the top right corner: a terrain picture, as large as the window.
local function Small()
    local window = CreateFrame("Frame", nil, UIParent)
    window:SetSize(200, 200)
    window:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -12, -12)
    local ground = window:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(window)
    ground:SetTexture("Interface\\AddOns\\SaneUI_Navigation\\Art\\Terrain\\0-4-4")
    ground:SetTexCoord(0.3, 0.5, 0.3, 0.5)
    return window
end

Lab.OnLogin(function()
    local window = Small()
    ns.Window = { frame = window }
    ns.Satchel.Build(window)
    ns.Satchel.Stack(window:GetFrameLevel() + 30)
    ns.Strays.Start()
    ns.Satchel.Place(true)
    ns.Satchel.Open()
    lab.Satchel = ns.Satchel
end)
