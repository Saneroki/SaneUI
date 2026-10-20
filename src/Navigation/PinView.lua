local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - PinView
--  The pins drawn: a button for each pin Pins.For gives, at a fixed size on the
--  screen whatever the zoom, in the game's own looks (its quest marks, flight
--  points, vignettes, town tracking and map legend), on a layer of the canvas
--  above the map and the game's minimap (Canvas.LEVELS), so they can be seen and
--  clicked in both views.
--
--      every pin   its own icon from the game's map icons (Pins.ICONS and the kinds' tables): no discs, no
--                  numbers. A quest in your log: the yellow question mark (the one the game's arrow leads to with
--                  a glow); a click shows it in the quest log and lets the arrow lead to it (QuestLog.lua). A
--                  quest giver of Core's data: the yellow exclamation mark, grey for a quest too low, a red
--                  question mark for one for later; a click shows its quests in the quest log as previews
--                  (QuestLog.Preview)
--      gathered    pins that would cover each other: one marker in the icon of the first (drawn highest), its
--                  tooltip what is there; a click zooms in
--      a click     the game's map pin where it stands, on the small map and the full one (Act); on the
--                  full map a quest also shows in the quest log; Shift and a click on one that leads into
--                  another map opens that map
--
--  Placed against the canvas' holder like the map's layers, so a drag moves them
--  with the map; laid out again with the map. A pin shows only while it lies
--  wholly inside the canvas (Fit: the game does not cut a button at its edge, nor
--  its clicks). A press on a pin is the map's (a drag that starts on a pin moves
--  the map); a plain click is the pin's.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Pins = ns.Pins
local PinView = {}
ns.PinView = PinView

PinView.GLOW = "UI-QuestPoi-OuterGlow" -- behind the quest the game's arrow leads to
PinView.GREY = 0.8 -- a grey quest's icon: so opaque, its colour taken away

PinView.LEVELS = 6 -- the pins' own levels over their layer: a pin of a higher order stands over a lower one

local layer, holder, view
local used, free = {}, {} -- [key] = button while in view; buttons let go

-- A pin's tooltip: its name, its lines; a quest's objectives as the game tells them.
local function Tip(button)
    local pin = button.pin
    if not pin then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if pin.gathered then
        GameTooltip:SetText(Pins.TEXT.gathered:format(#pin.gathered), 1, 1, 1)
        for index, each in ipairs(pin.gathered) do
            if index > 12 then break end
            GameTooltip:AddLine(each.name or "?", 1, 0.82, 0)
        end
        return GameTooltip:Show()
    end
    GameTooltip:SetText(pin.name or "?", 1, 1, 1)
    if pin.kind == "log" and pin.quest then
        if pin.complete then GameTooltip:AddLine(Pins.TEXT.turnIn, 0.2, 1, 0.2) end
        local objectives = Core.Ask(C_QuestLog.GetQuestObjectives, pin.quest)
        for _, objective in ipairs(type(objectives) == "table" and objectives or {}) do
            local done = objective.finished
            if objective.text and objective.text ~= "" then
                GameTooltip:AddLine("- " .. objective.text, done and 0.5 or 1, done and 0.5 or 1, done and 0.5 or 1, true)
            end
        end
        GameTooltip:AddLine(Pins.TEXT.open, 0.5, 0.5, 0.5)
    else
        if pin.offer then GameTooltip:AddLine(Pins.TEXT.offered, 1, 0.82, 0) end
        for _, line in ipairs(pin.lines or {}) do
            -- A line in its own colour: { words, r, g, b }.
            if type(line) == "table" then GameTooltip:AddLine(line[1], line[2], line[3], line[4], true)
            else GameTooltip:AddLine(line, 1, 1, 1, true) end
        end
        if pin.unverified then GameTooltip:AddLine(Pins.TEXT.unverified, 0.5, 0.5, 0.5) end
    end
    GameTooltip:Show()
end

-- The game's map pin where a pin stands (its own map and its place there; a gathered marker's first pin), as Ctrl
-- and a click puts it on the map: the golden line leads there.
local function Drop(pin)
    local first = pin.gathered and pin.gathered[1] or pin
    if first.map and first.x and ns.Live.SetWaypoint(first.map, first.x, first.y) then
        ns.Marks.Sound("UI_MAP_WAYPOINT_CONTROL_CLICK")
    else
        UIErrorsFrame:AddMessage(ns.TEXT.noPin, 1, 0.1, 0.1)
    end
end

-- A plain click, on the small map and the full one: the game's map pin there; a gathered marker zooms in too, and
-- on the full map a quest shows in the quest log (in the log: the arrow leads to it; a giver's: its quests as
-- previews). Shift and a click: a pin that leads into another map opens it.
local function Act(pin)
    if IsShiftKeyDown() and pin.to then return ns.Canvas.Show(pin.to) end
    Drop(pin)
    if pin.gathered then return ns.Canvas.ZoomTo(pin.pu, pin.pv, 3) end
    if ns.Canvas.camera ~= ns.Window.full then return end
    if pin.click == "quest" and pin.quest then return ns.QuestLog.Focus(pin.quest) end
    if pin.click == "preview" and pin.quests then return ns.QuestLog.Preview(pin.quests, pin.map, pin.x, pin.y) end
end

local function Down(button, mouse)
    ns.Canvas.Press(mouse)
end

local function Up(button, mouse)
    if ns.Canvas.Release(mouse) and button.pin then Act(button.pin) end
end

-- A pin's level: over the layer, a higher order over a lower one, and still under the marks (Canvas.LEVELS).
local function Level(button)
    local order = button.pin and button.pin.order or 0
    button:SetFrameLevel(layer:GetFrameLevel() + 1 + math.min(order, PinView.LEVELS))
end

local function Make()
    local button = CreateFrame("Button", nil, layer)
    button.glow = button:CreateTexture(nil, "BACKGROUND")
    button.glow:SetAtlas(PinView.GLOW)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.light = button:CreateTexture(nil, "HIGHLIGHT")
    button.light:SetAllPoints()
    button.light:SetBlendMode("ADD")
    button.light:SetAlpha(0.5)
    button:RegisterForClicks() -- the press and the release are the map's and the pin's (Down, Up)
    button:SetScript("OnMouseDown", ns.Guard(Down))
    button:SetScript("OnMouseUp", ns.Guard(Up))
    button:SetScript("OnEnter", ns.Guard(Tip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- A button's look for its pin: its icon, whatever its kind (a gathered marker: its first pin's, the one drawn
-- highest), at its kind's size from the pin filter's slider. A grey quest (and a flight point not found yet) without
-- its colour, a tinted one in its colour (a quest for later: red), the quest the game's arrow leads to with a glow
-- behind it.
local function Look(button, pin)
    local first = pin.gathered and pin.gathered[1] or pin
    local size = (Pins.SIZE[first.kind] or 20) * ns.PinScale(first.kind)
    button:SetSize(size, size)
    button.half = size / 2 -- how far it reaches from its middle (Fit); the focused quest's glow farther
    local icon, glow = button.icon, button.glow
    local grey, tint = first.grey or first.dim, first.tint
    icon:SetDesaturated(grey and true or false)
    if tint then icon:SetVertexColor(tint[1], tint[2], tint[3], 1)
    else icon:SetVertexColor(1, 1, 1, grey and PinView.GREY or 1) end
    icon:SetAtlas(first.atlas or Pins.ICONS.offer)
    button.light:SetAtlas(first.atlas or Pins.ICONS.offer)
    glow:Hide()
    if first.focused and not pin.gathered then
        glow:SetSize(size * 1.6, size * 1.6)
        glow:SetPoint("CENTER")
        glow:Show()
        button.half = size * 0.8
    end
end

function PinView.Build(canvasHolder)
    holder = canvasHolder
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    return layer
end

-- The layer at that frame level (the canvas' order: over the map and the game's minimap), its buttons over it.
function PinView.Stack(level)
    layer:SetFrameLevel(level)
    for _, button in pairs(used) do Level(button) end
end

local seen = {}

-- Every pin in view placed, as the canvas laid it out (view: Canvas.view); small: the small window. The
-- buttons of pins still in view are kept, the others let go.
function PinView.Place(laidView, small)
    view = laidView
    wipe(seen)
    local pu, pv
    if small then
        local map, u, v = ns.Live.Player()
        local link = map and u and ns.Coords.Link(map, view.map)
        if link then pu, pv = link.du + link.su * u, link.dv + link.sv * v end
    end
    local drawn = Pins.Gather(Pins.For(view, small, pu, pv), view.k)
    for index = 1, #drawn do
        local pin = drawn[index]
        local button = used[pin.key]
        if not button then
            button = table.remove(free) or Make()
            used[pin.key] = button
        end
        seen[pin.key] = true
        button.pin = pin
        Look(button, pin)
        Level(button)
        button.x, button.y = (pin.pu - view.u) * view.k, (pin.pv - view.v) * view.k
        button:ClearAllPoints()
        button:SetPoint("CENTER", holder, "CENTER", button.x, button.y)
    end
    for key, button in pairs(used) do
        if not seen[key] then
            button:Hide()
            button.pin = nil
            used[key] = nil
            free[#free + 1] = button
        end
    end
    PinView.Fit()
end

-- Each pin shown while it lies wholly inside the canvas' rectangle (Canvas.edge, in the holder's units).
function PinView.Fit()
    local Inside = ns.Canvas.Inside
    for _, button in pairs(used) do button:SetShown(Inside(button.x, button.y, button.half)) end
end

-- Every pin out of sight (the window hidden).
function PinView.Clear()
    for key, button in pairs(used) do
        button:Hide()
        button.pin = nil
        used[key] = nil
        free[#free + 1] = button
    end
end
