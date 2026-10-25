-- Far sparkles: found herbs and ore over the world (Glints.lua) and on a minimap (Found.lua): a Peacebloom, an Earthroot and Copper
-- The rest of Navigation stands in: you stand at 0, 0 facing north, the camera 12 yards behind you. In the console,
-- LabGlints.found holds the found ones (u yards east, v yards north of you) and LabGlints.facing your facing
-- (radians, turning to the left: 0.5 turns you a little left).
Lab.TOC("src/Core/SaneUI.toc")
local Core = SaneUI.Core
local ns = Lab.Addon("SaneUI_Navigation")
Core.NewModule("SaneUI_Navigation", "Navigation", ns)

local lab = { facing = 0 }
LabGlints = lab
GetPlayerFacing = function() return lab.facing end
GetCameraZoom = function() return 12 end
ns.options = { nodeGlints = true }
ns.Pins = { Shows = function() return true end }
ns.Coords = { Player = function() return 0, 0, 0 end }
-- The pictures are the items' own (Core's set Items: Peacebloom, Earthroot, Copper Ore).
ns.Nodes = { FOUND = { herb = "foundHerb", ore = "foundOre" }, Picture = function() return nil end,
             TooHard = function(node) return node.low end }
Lab.Addon("SaneUI_Navigation", "src/Navigation/Found.lua", "src/Navigation/Glints.lua")

lab.found = ns.Found.Each()
local function Found(u, v, kind, name, picture)
    lab.found[#lab.found + 1] = { u = u, v = v, plane = 0, kind = kind, node = { name = name }, picture = picture }
end
Found(-28, 74, "herb", "Peacebloom", 133939)   -- ahead, a little to the left
Found(46, 124, "herb", "Earthroot", 134187)    -- farther ahead, to the right
Found(64, -38, "ore", "Copper Vein", 134566)   -- behind you, to the right: at the right edge

-- The world behind: a screenshot of the game's (a local picture, assets/generated/ui-lab/backdrops/, not in the
-- repository; without it a magenta box: choose the backdrop dark).
local world = CreateFrame("Frame", nil, UIParent)
world:SetAllPoints(UIParent)
world:SetFrameStrata("BACKGROUND")
world:SetFrameLevel(0)
local picture = world:CreateTexture(nil, "BACKGROUND")
picture:SetAllPoints(world)
picture:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")

-- A minimap's stand-in in the top right corner (the lab has none): one of Navigation's terrain pictures, round, and the
-- same three found ones on it as the minimap draws them (Found.Round, Found.Ring, at the pin filter's size 14).
local function Minimap()
    local map = CreateFrame("Frame", nil, UIParent)
    map:SetSize(200, 200)
    map:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
    local ground = map:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(map)
    ground:SetTexture("Interface\\AddOns\\SaneUI_Navigation\\Art\\Terrain\\0-4-4")
    ground:SetTexCoord(0.3, 0.5, 0.3, 0.5)
    local round = map:CreateMaskTexture()
    round:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    round:SetAllPoints(map)
    ground:AddMaskTexture(round)
    for _, found in ipairs({ { -40, 50, 133939 }, { 35, 70, 134187 }, { 55, -30, 134566 } }) do
        local icon = map:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("CENTER", map, "CENTER", found[1], found[2])
        icon:SetTexture(found[3])
        ns.Found.Round(icon, map:CreateMaskTexture())
        local ring = map:CreateTexture(nil, "OVERLAY")
        ring:SetTexture(ns.Found.RING)
        ns.Found.Ring(ring, icon, 14)
    end
end

Lab.OnLogin(function()
    ns.Glints.Start()
    ns.Glints.frame:SetFrameLevel(5)
    Minimap()
end)
