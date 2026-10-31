-- Speed Leveling's guide over the world: the steps at hand and the list, a made-up guide over a screenshot of the game
-- Core from its TOC and the view, Steps.lua, alone: what it asks of the rest of the module stands in, the key's secure
-- frames are not in the lab. The module table is LabGuide in the console, LabGuide.Steps.Update() draws it anew;
-- LabGround(0.9) lays a plain ground of that lightness under it, to read it on snow.
Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.Addon("SaneUI_SpeedLeveling", "src/SpeedLeveling/Steps.lua")
LabGuide = ns

local world = CreateFrame("Frame", nil, UIParent)
world:SetAllPoints(UIParent)
world:SetFrameStrata("BACKGROUND")
local picture = world:CreateTexture(nil, "BACKGROUND")
picture:SetAllPoints(world)
picture:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")

function LabGround(shade) picture:SetColorTexture(shade, shade, shade) end

local function Rows(...)
    local rows = {}
    for index, text in ipairs({ ... }) do
        rows[index] = { number = 14 + index, shown = 14 + index, text = text, done = index == 2 }
    end
    return rows
end

local PICTURE = { title = "Elwynn Forest", levels = "6-10", at = 12, place = 12, total = 124, shift = 0, hand = {
    { number = 12, shown = 12, lines = {
        { text = "Clear the farm of |cffff2020Defias|r and pick up their bandanas" },
        { text = "0/12 Defias Thug slain", count = true, have = 0, need = 12, what = "goal" },
        { text = "Red Burlap Bandana: 3/8", count = true, have = 3, need = 8, what = "goal" },
        { text = "Speak to |cff19ff19Marshal Dughan|r", count = true, done = true, what = "goal" },
        { text = "|cffffd100The farm house upstairs has more of them than it seems|r" },
        { text = "Go round the back to stay out of their sight" } } },
    { number = 13, shown = 13, lines = {
        { text = "Level Mining to 65" },
        { text = "Before Westfall", count = true, have = 40, need = 65, what = "skill" } } },
    { number = 14, shown = 14, chain = "The Lost Hero, part 2 of 4 in its chain", lines = {
        { text = "Hand in |cffffd100An Old Letter|r at the Abbey" },
        { text = "Hand in An Old Letter", count = true, what = "handin" } } },
}, ahead = Rows("Accept Bounty on Murlocs from Marshal McBride", "Hand in The Fargodeep Mine",
                "Fly to Stormwind City", "Train your class spells", "Take the road west into Westfall",
                "Set your hearthstone at Sentinel Hill") }

local function Nothing() end
ns.name, ns.options = "SpeedLeveling", { showGuide = true, ahead = 6 }
ns.Guard = function(fn) return fn end
ns.Guarded = function(fn, ...) return fn(...) end
ns.TEXT = { step = "Step %d", progress = "%d/%d \194\183 %d%%", guideView = "Guide" }
ns.Arrow, ns.Icons, ns.Pin, ns.Detours = { Update = Nothing }, { Update = Nothing }, { Update = Nothing }, { Update = Nothing }
ns.Guide = { Picture = function() return PICTURE end, State = function() return "on" end, Empty = Nothing,
             WarnHex = function() return "ffffd100" end }

Lab.OnLogin(function() ns.Steps.Update() end)
