-- The full map's Dungeons: every dungeon and raid of Forever this year as banners, on Core's real sets (Instances.lua)
-- The sets are the built ones (BUILD/SaneUI/Sets: dev/build makes them); the rest of Navigation stands in: the full
-- map's title bar (Core's, as a frame of its own here) over Elwynn's map art, the dungeons' floor view, the map's search
-- (Route, Show and Maps say in the log what they would do). In the console: LabDungeons() opens or closes the banners,
-- LabLog(true) puts the quest log over the map's left (the banners beside it), LabLog() takes it away.
Lab.TOC("src/Core/SaneUI.toc")
local sets = {}
for _, name in ipairs({ "Instances", "Places", "Dungeons", "Encounters", "NPCs", "Quests", "Drops", "Maps" }) do
    sets[#sets + 1] = "BUILD/SaneUI/Sets/" .. name .. ".lua"
end
Lab.Addon("SaneUI_LabSets", unpack(sets))
local Core = SaneUI.Core
local ns = Lab.Addon("SaneUI_Navigation")
Core.NewModule("SaneUI_Navigation", "Navigation", ns)
ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
ns.options = ns.options or {}

-- The full map (its camera, the canvas the banners lie over), the bar's room, the quest log's place.
local full = {}
local logBox
ns.Window = { full = full }
ns.Canvas = { camera = full, GROUND = { 22 / 255, 38 / 255, 50 / 255 },
              Show = function(map) print("The map shows the zone " .. tostring(map) .. " whole.") return true end }
ns.TopBar = { INSET = 8, Top = function() return Core.Window.BAR end, Update = function() end }
ns.QuestLog = { Box = function() if logBox then return unpack(logBox) end end }
local DUNGEONS = Core.Data.Set("Dungeons")
ns.Dungeons = {
    LEVEL = 22,
    Key = function(map) return DUNGEONS:Get(map, "floors") and (map .. ":1") or nil end,
    Named = function(key) return key end,
    List = function() return {} end,
    Show = function(key) print("Its maps: the floor " .. tostring(key) .. " over the map.") return true end,
    Close = function() end,
}
function ns.Dungeons.Margins(view)
    local top, left = ns.TopBar.Top() + ns.TopBar.INSET, 0
    if logBox then left = math.min(logBox[2] / view:GetEffectiveScale() + ns.TopBar.INSET, view:GetWidth() / 3) end
    return top, left, 0
end
ns.Find = {
    Show = function(find) print("Shown on the map: " .. find.name .. "'s entrance.") return true end,
    Pin = function(find) print("The map pin at " .. find.name .. "'s entrance: the golden line leads there.") return true end,
    Clear = function() end,
    TEXT = { dungeon = "Dungeon", raid = "Raid" },
}

Lab.Addon("SaneUI_Navigation", "src/Navigation/Instances.lua")

-- The full map's title bar, as Core's window draws it while it fills the screen; Elwynn's map art under all of it.
local map = CreateFrame("Frame", nil, UIParent)
map:SetAllPoints()
map:SetFrameStrata("BACKGROUND")
map:SetClipsChildren(true)
for index = 1, 12 do
    local tile = map:CreateTexture(nil, "BACKGROUND")
    tile:SetTexture("Interface\\WorldMap\\Elwynn\\Elwynn" .. index)
    local column, row = (index - 1) % 4, math.floor((index - 1) / 4)
    tile:SetSize(512, 512)
    tile:SetPoint("TOPLEFT", map, "TOPLEFT", column * 512 - 200, -row * 512 + 60)
end
local bar = CreateFrame("Frame", nil, UIParent)
bar:SetPoint("TOPLEFT")
bar:SetPoint("TOPRIGHT")
bar:SetHeight(Core.Window.BAR)
bar:SetFrameStrata("MEDIUM")
bar:SetFrameLevel(100) -- over the banners, as the window's bar is
local ground = bar:CreateTexture(nil, "BACKGROUND")
ground:SetAllPoints()
ground:SetColorTexture(0.05, 0.05, 0.05, 0.92)
local button = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
button:SetSize(140, 24)
button:SetPoint("LEFT", 8, 0)
button:SetText("Dungeons")
button:SetScript("OnClick", function() ns.Instances.Toggle() end)

function LabDungeons() ns.Instances.Toggle() end
function LabLog(on)
    logBox = on and { 12, 420, 0, 800 } or nil
    ns.Instances.Refit()
end

Lab.OnLogin(function()
    ns.Instances.Build(map)
    ns.Instances.Open()
end)
