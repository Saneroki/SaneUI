-- Far sparkles: Navigation's marks of found herbs and ore over the world (Glints.lua), a Peacebloom, an Earthroot and Copper found
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

Lab.OnLogin(function()
    ns.Glints.Start()
    ns.Glints.frame:SetFrameLevel(5)
end)
