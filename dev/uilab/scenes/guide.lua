-- Speed Leveling's guide over the world: the steps at hand and the list, a made-up guide over a screenshot of the game
-- Core from its TOC and the view, Steps.lua, with its row of icons, Icons.lua, alone: what they ask of the rest of the
-- module stands in, the key's secure frames are not in the lab. The module table is LabGuide in the console,
-- LabGuide.Steps.Update() draws it anew; LabGround(0.9) lays a plain ground of that lightness under it, to read it on snow.
Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.Addon("SaneUI_SpeedLeveling", "src/SpeedLeveling/Steps.lua", "src/SpeedLeveling/Icons.lua")
LabGuide = ns

local world = CreateFrame("Frame", nil, UIParent)
world:SetAllPoints(UIParent)
world:SetFrameStrata("BACKGROUND")
local picture = world:CreateTexture(nil, "BACKGROUND")
picture:SetAllPoints(world)
picture:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")

function LabGround(shade) picture:SetColorTexture(shade, shade, shade) end

local PICTURE = { title = "Elwynn Forest", levels = "6-10", at = 35, place = 35, total = 100, hand = {
    { number = 34, shown = 34, lines = {
        { text = "Clear the farm of |cffff2020Defias|r and pick up their bandanas" },
        { text = "0/12 Defias Thug slain", count = true, have = 0, need = 12, what = "goal" },
        { text = "Red Burlap Bandana: 3/8", count = true, have = 3, need = 8, what = "goal" },
        { text = "Speak to |cff19ff19Marshal Dughan|r", count = true, done = true, what = "goal" },
        { text = "|cffffd100The farm house upstairs has more of them than it seems|r" },
        { text = "Go round the back to stay out of their sight" } } },
    { number = 35, shown = 35, lines = {
        { text = "Level Mining to 65" },
        { text = "Before Westfall", count = true, have = 40, need = 65, what = "skill" } } },
} }

local WORDS = { "Accept Bounty on Murlocs from Marshal McBride", "Hand in The Fargodeep Mine", "Fly to Stormwind City",
                "Train your class spells", "Take the road west into Westfall", "Set your hearthstone at Sentinel Hill",
                "Kill Harvest Watchers around the farms", "Collect Goretusk Livers" }

local function Nothing() end
ns.name, ns.options = "SpeedLeveling", { showGuide = true, ahead = 10, icons = true }
ns.Guard = function(fn) return fn end
ns.Guarded = function(fn, ...) return fn(...) end
ns.TEXT = { step = "Step %d", progress = "%d/%d \194\183 %d%%", guideView = "Guide" }
ns.On = Nothing
ns.Arrow, ns.Pin, ns.Detours = { Update = Nothing }, { Update = Nothing }, { Update = Nothing }
ns.Items = { QuestItems = function() return {} end }
-- A guide of a hundred steps, you at the 35th. LabWheel(-1) turns the wheel, LabMouse(false) takes the mouse off the view.
local function Listed()
    local list = {}
    for number = 1, 100 do list[number] = number end
    return list, 35
end

local function Line(number)
    return { number = number, shown = number, text = WORDS[number % #WORDS + 1], done = number < 34 }
end

ns.Guide = { Picture = function() return PICTURE end, Listed = Listed, Line = Line, State = function() return "on" end,
             Empty = Nothing, Go = Nothing, Uses = Nothing,
             Targets = function() return { "Defias Thug", "Defias Pillager" }, { "Marshal Dughan" } end,
             WarnHex = function() return "ffffd100" end }
ns.Run = { Guide = function() return PICTURE end }

function LabWheel(delta)
    local view = _G.SaneUISpeedLevelingSteps
    view:GetScript("OnMouseWheel")(view, delta)
end

function LabMouse(over)
    _G.SaneUISpeedLevelingSteps.IsMouseOver = function() return over end
end

-- The view's place that far from the screen's top, as Edit Mode leaves it: LabPlace(40) in the upper half, LabPlace(600) in the lower.
function LabPlace(down)
    local spot = _G.SaneUISpeedLevelingGuide
    spot:ClearAllPoints()
    spot:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -70, -down)
    ns.Steps.Update()
end

Lab.OnLogin(function()
    ns.Steps.Update()
    LabMouse(false)
end)
