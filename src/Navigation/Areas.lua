local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Areas
--  Where a quest's objectives are found, shaded as the game shades them on its
--  own map: the game's quest area frame (a QuestPOIFrame, the engine draws the
--  area of a quest on a map into it) laid over each zone in view, as large as the
--  zone's box, on a layer of the canvas under the route and the pins.
--
--      which quest   the one the mouse is over in the quest log (QuestLog.lua), else the one the game's
--                    arrow leads to (C_SuperTrack); in the log only
--      when          at a zone's level, while the pin filter's Quest areas is on
--
--  The engine shades the area into the frame's rectangle as it stands when it
--  is asked; a frame just placed or sized has its new rectangle only once the
--  game has laid it out, at the frame's end. So a frame is placed at once and
--  its area drawn on the next frame (Redraw), as Blizzard's map waits for the
--  frame's end after a change of its scale (QuestBlobPinMixin:OnCanvasScaleChanged):
--  drawn at once, the area stood where the zoom before had put it.
--
--  The game's minimap draws the areas near the player by itself (Hybrid.lua).
--  Should this client not make the frame for us, there are no areas, said once.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Areas = {}
ns.Areas = Areas

Areas.FILL = "Interface\\WorldMap\\UI-QuestBlob-Inside"   -- the game's own, as its map draws them
Areas.BORDER = "Interface\\WorldMap\\UI-QuestBlob-Outside"
Areas.FILL_ALPHA, Areas.BORDER_ALPHA = 128, 192

local layer, holder
local frames = {} -- [uiMapID] = its area frame, made when first needed
local works       -- the game makes the frame for us: nil not tried yet, false it did not
local hovered     -- the quest under the mouse in the quest log
local pending     -- the quest to draw on the next frame, into the frames placed for it (Redraw)

-- A zone's area frame, made the first time; nil when the game does not make one.
local function Frame(map)
    local frame = frames[map]
    if frame or works == false then return frame end
    local ok, made = pcall(CreateFrame, "QuestPOIFrame", nil, layer)
    if not ok or not made then
        works = false
        ns.Report("quest areas", tostring(made))
        return nil
    end
    works = true
    made:SetFillTexture(Areas.FILL)
    made:SetBorderTexture(Areas.BORDER)
    made:SetFillAlpha(Areas.FILL_ALPHA)
    made:SetBorderAlpha(Areas.BORDER_ALPHA)
    made:SetBorderScalar(1)
    made:SetMapID(map)
    frames[map] = made
    return made
end

local function HideAll()
    pending = nil
    if layer then layer:SetScript("OnUpdate", nil) end
    for _, frame in pairs(frames) do
        frame:DrawNone()
        frame:Hide()
    end
end

function Areas.Build(canvasHolder)
    holder = canvasHolder
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    return layer
end

-- The frame after a placing: the game has laid the frames out at their new place and size, the area is drawn
-- into each frame that shows. Once.
local function Redraw()
    layer:SetScript("OnUpdate", nil)
    local quest = pending
    pending = nil
    if not quest then return end
    for _, frame in pairs(frames) do
        if frame:IsShown() then
            frame:DrawNone()
            frame:DrawBlob(quest, true)
        end
    end
end
local redrawing = ns.Guard(Redraw) -- made once: the next frame's drawing after a placing

-- The quest whose area is drawn: the one under the mouse in the log, else the one the game's arrow leads to.
local function Quest()
    local quest = hovered or Core.Plain(Core.Ask(C_SuperTrack.GetSuperTrackedQuestID))
    if not quest or quest <= 0 then return nil end
    local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, quest)
    return index and index > 0 and quest or nil
end

-- Drawn for the view as the canvas laid it out: over each zone in view, at a zone's level.
function Areas.Place(view)
    local quest = view.level == "zone" and ns.Pins.Shows("area") and Quest()
    if not quest then return HideAll() end
    layer:SetAlpha(ns.PinScale("area")) -- the pin filter's slider for the quest areas is their opacity
    local drawn = {}
    for _, zone in ipairs(Coords.Zones(view.map)) do
        local box = zone.box
        if box.u <= view.right and box.u + box.width >= view.left and box.v >= view.bottom and box.v - box.height <= view.top then
            local frame = Frame(zone.map)
            if not frame then return HideAll() end
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", holder, "CENTER", (box.u - view.u) * view.k, (box.v - view.v) * view.k)
            frame:SetSize(box.width * view.k, box.height * view.k)
            frame:DrawNone() -- nothing at the old place meanwhile
            frame:Show()
            drawn[zone.map] = true
        end
    end
    for map, frame in pairs(frames) do
        if not drawn[map] then
            frame:DrawNone()
            frame:Hide()
        end
    end
    pending = quest
    layer:SetScript("OnUpdate", redrawing)
end

-- The quest log's mouse over a quest (nil: off it): its area drawn while it is there.
function Areas.Hover(quest)
    if hovered == quest then return end
    hovered = quest
    if ns.Canvas.Laid() then Areas.Place(ns.Canvas.view) end
end

function Areas.Clear()
    HideAll()
end
