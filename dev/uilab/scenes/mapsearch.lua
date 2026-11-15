-- The full map's search: the field in its title bar and the finds under it, on Core's real sets (Find.lua, FindBox.lua)
-- The sets are the built ones (BUILD/SaneUI/Sets: dev/build makes them); the rest of Navigation stands in: the title bar
-- of the full map (Core's, as a frame of its own here), Elwynn Forest's map art under it, the map's spaces (a few zones'
-- boxes in the world's yards, the rest far away), you in Stormwind's Mage Quarter facing north. In the console:
-- LabFind("who sells linen cloth") types and searches, LabFind() empties the field; LabFindKey("DOWN") presses an arrow,
-- LabFindKey("ENTER") Enter; LabFindShown() names the find whose pins the map would show.
Lab.TOC("src/Core/SaneUI.toc")
local sets = {}
for _, name in ipairs({ "Classes", "SkillLines", "Spells", "NPCs", "Spawns", "CreatureSpawns", "Objects", "Items", "Drops",
                        "Vendors", "Quests", "Places", "Trainers" }) do
    sets[#sets + 1] = "BUILD/SaneUI/Sets/" .. name .. ".lua"
end
Lab.Addon("SaneUI_LabSets", unpack(sets))
local Core = SaneUI.Core
local ns = Lab.Addon("SaneUI_Navigation")
Core.NewModule("SaneUI_Navigation", "Navigation", ns)
ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
ns.options = ns.options or {}

-- The zones' boxes in the world's yards (left and right: west, top and bottom: north), as the game's map tree gives them.
local BOXES = {
    [1429] = { "Elwynn Forest", 1535.4, -1935.4, -7939.6, -10254.2 },
    [1453] = { "Stormwind City", 1722.9, -14.6, -7995.8, -9152.1 },
    [1436] = { "Westfall", 3016.7, -483.3, -9400.0, -11733.3 },
    [1431] = { "Duskwood", 833.3, -1866.7, -9716.7, -11516.7 },
    [1433] = { "Redridge Mountains", -1570.8, -3741.7, -8575.0, -10022.9 },
    [1426] = { "Dun Morogh", 1802.1, -3122.9, -3877.1, -7160.4 },
    [1455] = { "Ironforge", -713.6, -1504.2, -4569.2, -5096.9 },
    [1432] = { "Loch Modan", -1993.8, -4752.1, -4487.5, -6327.1 },
}
local names = { [1415] = "Eastern Kingdoms", [1414] = "Kalimdor" }
for map, box in pairs(BOXES) do names[map] = box[1] end
C_Map.GetMapInfo = function(map) return names[map] and { mapID = map, name = names[map] } or nil end
C_Map.GetBestMapForUnit = function() return 1453 end

local function ToPlane(map, x, y)
    local box = BOXES[map]
    if not box then return nil end
    local west, north = box[2] - x * (box[2] - box[3]), box[4] - y * (box[4] - box[5])
    return -west, north -- (the plane: east, north)
end
ns.Coords = {
    Planes = function() return { 1415, 1414 } end,
    Zones = function(plane)
        local list = {}
        if plane == 1415 then for map in pairs(BOXES) do list[#list + 1] = { map = map } end end
        return list
    end,
    PlaneOf = function(map) return BOXES[map] and 1415 or nil end,
    MapToPlane = function(map, x, y, plane) if plane == 1415 then return ToPlane(map, x, y) end end,
}
local hereU, hereV = ToPlane(1453, 0.40, 0.80) -- the Mage Quarter
ns.Live = { Player = function() return 1415, hereU, hereV, 0 end, Flights = function() return {} end }
ns.Canvas = { Show = function() return true end, LookAt = function() return true end, Refresh = function() end,
              view = { zone = 1453 } }
ns.Dungeons = { List = function() return {} end, Show = function() return true end }
ns.Label = { Range = function() return nil end }
ns.QuestLog = { Focus = function() end }
ns.PinView = { Drop = function() end }
ns.Planner = { Knows = function() return true end }
ns.Window = { Full = function() end }
-- The pins' icons as the map's own pins have them (Pins.lua): a trainer's by its title, a merchant's by its goods.
local SERVICES = { repair = "repair", innkeeper = "innkeeper", banker = "banker", auctioneer = "auctioneer",
                   stablemaster = "stablemaster", trainer = "profession", vendor = "repair", flightmaster = "flightmaster" }
ns.Pins = {
    LookOf = function(services, title)
        for _, service in ipairs(services or {}) do
            if service == "trainer" and title and title:find("Trainer") and not title:find("Pet") then
                for _, class in ipairs({ "Warrior", "Mage", "Priest", "Rogue", "Hunter", "Warlock", "Druid", "Paladin", "Shaman" }) do
                    if title:find(class) then return "class" end
                end
            end
            if SERVICES[service] then return SERVICES[service] end
        end
        return "monsterneutral"
    end,
    ObjectLook = function(kind) return ({ herb = "professions_tracking_herb", ore = "professions_tracking_ore",
                                          mailbox = "mailbox" })[kind] or "vignetteloot" end,
    PlaceLook = function(kind) return ({ dungeon = "dungeon", raid = "raid" })[kind] or "poi-town" end,
}

Lab.Addon("SaneUI_Navigation", "src/Navigation/Find.lua", "src/Navigation/FindBox.lua")

-- The full map's title bar, as Core's window draws it while it fills the screen (Window.lua): the title at its left,
-- a thin gold line under it, the close button at its right; Elwynn's map art under it.
local bar = CreateFrame("Frame", nil, UIParent)
bar:SetPoint("TOPLEFT")
bar:SetPoint("TOPRIGHT")
bar:SetHeight(Core.Window.BAR)
bar:SetFrameStrata("LOW")
local ground = bar:CreateTexture(nil, "BACKGROUND")
ground:SetAllPoints()
ground:SetColorTexture(0.05, 0.05, 0.05, 0.92)
local line = bar:CreateTexture(nil, "ARTWORK")
line:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.5)
line:SetPoint("BOTTOMLEFT", 8, 0)
line:SetPoint("BOTTOMRIGHT", -8, 0)
line:SetHeight(1)
bar.find = CreateFrame("Button", nil, bar)
bar.find:SetSize(110, Core.Window.BAR)
bar.find:SetPoint("LEFT")
local title = bar.find:CreateFontString(nil, "ARTWORK", "GameFontNormal")
title:SetPoint("LEFT", 8, 0)
title:SetText("World Map")
local close = CreateFrame("Button", nil, bar, "UIPanelCloseButtonNoScripts")
close:SetPoint("RIGHT", -4, 0)
local map = CreateFrame("Frame", nil, UIParent)
map:SetPoint("TOPLEFT", bar, "BOTTOMLEFT")
map:SetPoint("BOTTOMRIGHT")
map:SetFrameStrata("BACKGROUND")
for index = 1, 12 do
    local tile = map:CreateTexture(nil, "BACKGROUND")
    tile:SetTexture("Interface\\WorldMap\\Elwynn\\Elwynn" .. index)
    local column, row = (index - 1) % 4, math.floor((index - 1) / 4)
    tile:SetSize(512, 512)
    tile:SetPoint("TOPLEFT", map, "TOPLEFT", column * 512 - 200, -row * 512 + 60)
end
local handle = { bar = bar, buttons = { list = { close } }, edge = {} }

function LabFind(text)
    ns.FindBox.Search(text or "")
    if not text then ns.FindBox.Clear() end
end
function LabFindShown()
    local shown = ns.Find.Shown()
    return shown and shown.name
end

Lab.OnLogin(function()
    ns.FindBox.SetShown(true, handle)
    local box
    for _, child in ipairs({ bar:GetChildren() }) do
        for _, inner in ipairs({ child:GetChildren() }) do
            if inner:GetObjectType() == "EditBox" then box = inner end
        end
    end
    LabFindKey = function(key)
        if key == "ENTER" then return box:GetScript("OnEnterPressed")(box) end
        if key == "ESCAPE" then return box:GetScript("OnEscapePressed")(box) end
        box:GetScript("OnArrowPressed")(box, key)
    end
    C_Timer.After(1, function() LabFind("nearest warrior trainer") end)
end)
