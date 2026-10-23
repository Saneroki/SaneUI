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
--      gathered    pins that would cover each other: one marker, in their icon where all have the same one (two
--                  trainers: the trainer's), else the game's plus (PinView.PLUS; Saneroki, 2026-10-23); its
--                  tooltip what is there, each with its own pin's icon before its name; a click zooms in
--      a rare      with Alt held, its 3D model (the game's, by its creature: SetCreature) stands beside the
--                  tooltip, at its left, or at its right where the left has no room; Alt let go, or the
--                  mouse off the pin, and it goes. Where the game has no model of it, nothing stands there
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
PinView.PLUS = "Garr_Building-AddFollowerPlus" -- a gathered marker of pins with different icons: the game's round plus
PinView.TIP_ICON = 16 -- a pin's icon before its name in a gathered marker's tooltip

-- The pins' own levels over their layer, by kind (a gathered marker: its first pin's), in Pins' order: a higher kind
-- stands over a lower one. Kinds that share a level are those Pins.Gather gathers where they would cover each other
-- (the game's own marks nearby aside); at most PinView.LEVELS, all under the marks (Canvas.LEVELS).
PinView.TIERS = { log = 6, quest = 5, rare = 4, entrance = 3, flight = 3, travel = 3, place = 3, treasure = 2,
                  service = 1 }
PinView.LEVELS = 6
PinView.MODEL_WIDTH, PinView.MODEL_HEIGHT = 170, 210 -- a rare's model beside its tooltip (Alt held)
PinView.MODEL_GAP = 8     -- between the tooltip and the model
PinView.MODEL_TURN = -0.5 -- radians: a little from the side, as the tooltips turn a creature

local layer, holder, view
local used, free = {}, {} -- [key] = button while in view; buttons let go
local hovered             -- the pin's button the mouse is on (Tip), for the rare's model
local stage               -- the rare's model frame, once made; false where the client has none
local Model               -- below

-- A pin's tooltip: its name (an NPC's role: Pins.lua), its lines; a quest's objectives as the game tells them. Words
-- the tooltip says already are not said again (two trainers of a kind gathered: Priest Trainer once).
local said = {} -- the words in the tooltip so far, for one tooltip
local function Say(words, r, g, b, wrap)
    if said[words] then return end
    said[words] = true
    GameTooltip:AddLine(words, r, g, b, wrap)
end

-- A pin's name with its icon before it, as its pin shows it (a grey one grey, a tinted one in its colour).
local function Iconed(pin, words)
    local size = PinView.TIP_ICON
    if not pin.atlas then return words end
    local tint = pin.tint or (pin.grey or pin.dim) and { 0.6, 0.6, 0.6 } or nil
    if tint then
        return ("|A:%s:%d:%d:0:0:%d:%d:%d|a %s"):format(pin.atlas, size, size, math.floor(tint[1] * 255),
            math.floor(tint[2] * 255), math.floor(tint[3] * 255), words)
    end
    return ("|A:%s:%d:%d|a %s"):format(pin.atlas, size, size, words)
end
PinView.Iconed = Iconed

local function Tip(button)
    local pin = button.pin
    if not pin then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    wipe(said)
    if pin.gathered then
        -- What is there, one under the other, each with its own pin's icon: the first as the heading
        for index, each in ipairs(pin.gathered) do
            if index > 12 then break end
            local words = each.role or each.name or "?"
            if index == 1 then
                said[words] = true
                GameTooltip:SetText(Iconed(each, words), 1, 1, 1)
            elseif not said[words] then
                said[words] = true
                GameTooltip:AddLine(Iconed(each, words), 1, 0.82, 0)
            end
        end
        return GameTooltip:Show()
    end
    local heading = pin.role or pin.name or "?"
    said[heading] = true
    GameTooltip:SetText(heading, 1, 1, 1)
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
        if pin.offer then Say(Pins.TEXT.offered, 1, 0.82, 0) end
        for _, line in ipairs(pin.lines or {}) do
            -- A line in its own colour: { words, r, g, b }.
            if type(line) == "table" then Say(line[1], line[2], line[3], line[4], true)
            else Say(line, 1, 1, 1, true) end
        end
        if pin.unverified then GameTooltip:AddLine(Pins.TEXT.unverified, 0.5, 0.5, 0.5) end
    end
    GameTooltip:Show()
    hovered = button
    Model()
end

-- The game's map pin where a pin stands (its own map and its place there; a gathered marker's first pin), as Ctrl
-- and a click puts it on the map: the golden line leads there. Also for what else is clicked to put it somewhere
-- (a quest in the quest log, a herb found on the minimap): { map, x, y }; where the game takes none, it says so.
function PinView.Drop(pin)
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
    PinView.Drop(pin)
    if pin.gathered then return ns.Canvas.ZoomTo(pin.pu, pin.pv, 3) end
    if ns.Canvas.camera ~= ns.Window.full then return end
    if pin.click == "quest" and pin.quest then return ns.QuestLog.Focus(pin.quest) end
    if pin.click == "preview" and pin.quests then return ns.QuestLog.Preview(pin.quests, pin.map, pin.x, pin.y) end
end

-- A rare's creature (its NPC ID), from its pin's key ("npc:<id>": Core's data, or the game's mark of it).
local function Creature(pin)
    if not pin or pin.kind ~= "rare" or pin.gathered then return nil end
    return tonumber(tostring(pin.key):match("^npc:(%d+)$"))
end

-- The model's frame, made the first time Alt is held over a rare: see-through, over the tooltips' layer, unseen
-- until the game has the model (OnModelLoaded).
local function Stage()
    if stage ~= nil then return stage end
    local made, model = pcall(CreateFrame, "PlayerModel", nil, UIParent)
    stage = made and model or false
    if not stage then return false end
    model:SetFrameStrata("TOOLTIP")
    model:SetSize(PinView.MODEL_WIDTH, PinView.MODEL_HEIGHT)
    model:Hide()
    pcall(model.SetScript, model, "OnModelLoaded", ns.Guard(function(self) self:SetAlpha(1) end))
    return model
end

-- The rare's model beside the tooltip while Alt is held over its pin (see above), else none.
function Model()
    local npc = hovered and hovered:IsMouseOver() and IsAltKeyDown() and Creature(hovered.pin)
    local model = (npc or stage) and Stage()
    if not model then return end
    if not npc then
        model:Hide()
        return
    end
    if model.npc ~= npc then
        model:SetAlpha(0)
        model:ClearModel()
        model.npc = nil
        if not pcall(model.SetCreature, model, npc) then return model:Hide() end
        model.npc = npc
        pcall(model.SetPortraitZoom, model, 0)
        pcall(model.SetFacing, model, PinView.MODEL_TURN)
        local file = Core.Ask(model.GetModelFileID, model)
        if type(file) == "number" and file > 0 then model:SetAlpha(1) end -- the game had it already
    end
    model:ClearAllPoints()
    local left = GameTooltip:GetLeft()
    if left and left > PinView.MODEL_WIDTH + PinView.MODEL_GAP then
        model:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT", -PinView.MODEL_GAP, 0)
    else
        model:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", PinView.MODEL_GAP, 0)
    end
    model:Show()
end

local function Left()
    hovered = nil
    GameTooltip_Hide()
    Model()
end

local function Down(button, mouse)
    ns.Canvas.Press(mouse)
end

local function Up(button, mouse)
    if ns.Canvas.Release(mouse) and button.pin then Act(button.pin) end
end

-- A pin's level: over the layer, a higher kind over a lower one, and still under the marks (Canvas.LEVELS).
local function Level(button)
    local pin = button.pin
    local first = pin and (pin.gathered and pin.gathered[1] or pin)
    local tier = first and PinView.TIERS[first.kind] or 0
    button:SetFrameLevel(layer:GetFrameLevel() + 1 + math.min(tier, PinView.LEVELS))
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
    button:SetScript("OnLeave", ns.Guard(Left))
    return button
end

-- Whether the pins of a gathered marker all have the same icon (atlas and colour): then it shows that one.
local function Alike(gathered)
    local first = gathered[1]
    for index = 2, #gathered do
        local each = gathered[index]
        if each.atlas ~= first.atlas or each.tint ~= first.tint or (each.grey or each.dim) ~= (first.grey or first.dim) then
            return false
        end
    end
    return true
end
PinView.Alike = Alike

-- A button's look for its pin: its icon, whatever its kind (a gathered marker: its pins' where all have the same, else
-- the game's plus, PinView.PLUS), at its kind's size from the pin filter's slider. A grey quest without its colour, a tinted one in its
-- colour (a quest for later: red; a flight point not found yet: its colour taken out first, then red), the quest the
-- game's arrow leads to with a glow
-- behind it. Not made again while it is the same (the same first pin, size and glow: a pin's record is made anew
-- whenever what it shows changes).
local function Look(button, pin)
    local first = pin.gathered and pin.gathered[1] or pin
    local size = (Pins.SIZE[first.kind] or 20) * ns.PinScale(first.kind)
    local glowing = first.focused and not pin.gathered and true or false
    local plus = pin.gathered and not Alike(pin.gathered) or false
    if button.first == first and button.size == size and button.glowing == glowing and button.plus == plus then return end
    button.first, button.size, button.glowing, button.plus = first, size, glowing, plus
    button:SetSize(size, size)
    button.half = size / 2 -- how far it reaches from its middle (Fit); the focused quest's glow farther
    local icon, glow = button.icon, button.glow
    local grey, tint = first.grey or first.dim, first.tint
    if plus then grey, tint = nil, nil end
    icon:SetDesaturated(grey and true or false)
    if tint then icon:SetVertexColor(tint[1], tint[2], tint[3], 1)
    else icon:SetVertexColor(1, 1, 1, grey and PinView.GREY or 1) end
    local atlas = plus and PinView.PLUS or first.atlas or Pins.ICONS.offer
    icon:SetAtlas(atlas)
    button.light:SetAtlas(atlas)
    glow:Hide()
    if glowing then
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
            button.pin, button.inside = nil, false
            used[key] = nil
            free[#free + 1] = button
        end
    end
    PinView.Fit()
end

-- Each pin shown while it lies wholly inside the canvas' rectangle (Canvas.edge, in the holder's units); told the
-- game only when that changed.
function PinView.Fit()
    local Inside = ns.Canvas.Inside
    for _, button in pairs(used) do
        local inside = Inside(button.x, button.y, button.half)
        if inside ~= button.inside then
            button.inside = inside
            button:SetShown(inside)
        end
    end
end

-- Every pin out of sight (the window hidden).
function PinView.Clear()
    for key, button in pairs(used) do
        button:Hide()
        button.pin, button.inside = nil, false
        used[key] = nil
        free[#free + 1] = button
    end
    hovered = nil
    if stage then stage:Hide() end
end

-- Alt pressed or let go over a rare's pin: its model comes or goes.
ns.On("MODIFIER_STATE_CHANGED", function()
    if hovered or (stage and stage:IsShown()) then Model() end
end)
