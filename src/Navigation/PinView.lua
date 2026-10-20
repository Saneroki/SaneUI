local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - PinView
--  The pins drawn: a button for each pin Pins.For gives, at a fixed size on the
--  screen whatever the zoom, in the game's own looks (its quest marks, flight
--  points, vignettes, town tracking and map legend), on a layer of the canvas
--  above the map and the game's minimap (Canvas.LEVELS), so they can be seen and
--  clicked in both views.
--
--      quest       the game's quest disc with its mark: in progress, ready to turn in (the quest the game's
--                  arrow leads to on its brown disc), a quest of Core's data to take; a click shows it in
--                  the quest log and lets the game's arrow lead to it (QuestLog.lua)
--      gathered    pins that would cover each other, one disc with their number; a click zooms in
--      the rest    the game's atlas of each; a click on one that leads into another map opens that map
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

PinView.DISC = "UI-QuestPoi-QuestNumber"            -- the game's quest disc
PinView.DISC_FOCUSED = "UI-QuestPoi-QuestNumber-SuperTracked"
PinView.IN_PROGRESS = "Quest-In-Progress-Icon-yellow"
PinView.IN_PROGRESS_FOCUSED = "Quest-In-Progress-Icon-Brown"
PinView.TURN_IN = "UI-QuestIcon-TurnIn-Normal"
PinView.GLOW = "UI-QuestPoi-OuterGlow"
PinView.HIGHLIGHT = "UI-QuestPoi-InnerGlow"
PinView.MARK = 0.6 -- the mark on a disc, as a share of the disc

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
    if pin.kind == "quest" and pin.quest and not pin.offer then
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
        for _, line in ipairs(pin.lines or {}) do GameTooltip:AddLine(line, 1, 1, 1, true) end
        if pin.unverified then GameTooltip:AddLine(Pins.TEXT.unverified, 0.5, 0.5, 0.5) end
    end
    GameTooltip:Show()
end

-- A plain click: the pin's own action.
local function Act(pin)
    if pin.gathered then
        return ns.Canvas.ZoomTo(pin.pu, pin.pv, 3)
    end
    if pin.click == "quest" and pin.quest then
        return ns.QuestLog.Focus(pin.quest)
    end
    if pin.to then return ns.Canvas.Show(pin.to) end
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
    button.disc = button:CreateTexture(nil, "BORDER")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.count = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.count:SetPoint("CENTER", 0, 1)
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

-- A button's look for its pin.
local function Look(button, pin)
    local kind = pin.gathered and "gathered" or pin.kind
    local size = Pins.SIZE[kind] or 20
    button:SetSize(size, size)
    button.half = size / 2 -- how far it reaches from its middle (Fit); the focused quest's glow farther
    local disc, icon, glow, count = button.disc, button.icon, button.glow, button.count
    icon:ClearAllPoints()
    icon:SetDesaturated(pin.dim and true or false)
    icon:SetVertexColor(1, 1, 1, pin.dim and 0.7 or 1)
    count:Hide()
    glow:Hide()
    if kind == "quest" and not pin.offer then
        disc:SetAtlas(pin.focused and PinView.DISC_FOCUSED or PinView.DISC)
        disc:SetAllPoints()
        disc:Show()
        local mark = pin.complete and PinView.TURN_IN or (pin.focused and PinView.IN_PROGRESS_FOCUSED or PinView.IN_PROGRESS)
        icon:SetAtlas(mark)
        icon:SetSize(size * PinView.MARK, size * PinView.MARK)
        icon:SetPoint("CENTER")
        if pin.focused then
            glow:SetSize(size * 1.6, size * 1.6)
            glow:SetPoint("CENTER")
            glow:Show()
            button.half = size * 0.8
        end
        button.light:SetAtlas(PinView.HIGHLIGHT)
    elseif kind == "gathered" then
        disc:SetAtlas(PinView.DISC)
        disc:SetAllPoints()
        disc:Show()
        icon:SetTexture(nil)
        count:SetText(#pin.gathered)
        count:Show()
        button.light:SetAtlas(PinView.HIGHLIGHT)
    else
        disc:Hide()
        if pin.atlas then icon:SetAtlas(pin.atlas) else icon:SetTexture(pin.texture) end
        icon:SetAllPoints()
        if pin.atlas then button.light:SetAtlas(pin.atlas) else button.light:SetTexture(pin.texture) end
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
