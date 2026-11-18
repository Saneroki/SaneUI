local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Macros - Face
--  Our button lying over a bar button: the macro's look there and its own press
--  (the same hub, Press.lua). It sits in the bar's frame, so it comes and goes
--  with the bar, at rest too, and it never touches the game's button, which
--  keeps what it holds underneath. It shows the step that comes next (a macro
--  whose picture is fixed, its own the whole time: Press.FacePicture), that
--  step's cooldown by the game's duration object (a hidden value in a fight is
--  taken as it is), dimmed while the game says it cannot be used, or while a
--  step cast once a target waits for the next one (Press.Waits); the macro's
--  name along its bottom (Saneroki, 2026-11-07), as the game's button shows a
--  macro's name (ActionButtonTemplate's Name: GameFontHighlightSmallOutline,
--  10 high, 2 up from the bottom; one line, cut where it is too long).
--
--  As a game's button does (Saneroki, 2026-11-06: no spell would take its place,
--  and Shift-dragging it off did nothing): a spell, an item or anything else of
--  the game's dropped on it, or clicked onto it, takes the macro off and goes onto
--  the game's button beneath, whose own goes onto the cursor, as when two swap.
--  Dragged with the bars unlocked or the pick-up key (Shift) held, the macro
--  follows the mouse (Place.lua): let go on another button, it is there; on none,
--  it is off the bars. Out of a fight, as the game's buttons change.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Face = {}
Macros.Face = Face

local CROP = 0.08
local faces = {}      -- [place] = its frame
local listening = false

local function Cooldown(face, spell)
    local spells = rawget(_G, "C_Spell")
    local get = spells and spells.GetSpellCooldownDuration
    if spell and get and face.cooldown.SetCooldownFromDurationObject then
        local duration = Core.Ask(get, spell)
        if duration then
            local ok = pcall(face.cooldown.SetCooldownFromDurationObject, face.cooldown, duration, true)
            if ok then return end
        end
    end
    face.cooldown:Clear()
end

local function PaintOne(face)
    local macro = face.macro
    local turn = macro and Macros.Press.Next(macro)
    local step = turn and turn.step or (macro and macro.steps[1])
    face.icon:SetTexture(Macros.Press.FacePicture(macro, step))
    local spell = step and Macros.Press.SpellOf(step)
    local dim = false
    -- On the full screen every icon at full brightness (ActionBars.lua, Seated).
    local dims = ns.options.macroDim and not (ns.ActionBars and ns.ActionBars.Seated())
    if dims and Macros.Press.Waits(turn) then
        dim = true -- cast on this target already: this press does nothing
    elseif dims and spell then
        local spells = rawget(_G, "C_Spell")
        dim = spells and Core.Plain(Core.Ask(spells.IsSpellUsable, spell)) == false
    end
    face.icon:SetVertexColor(dim and 0.4 or 1, dim and 0.4 or 1, dim and 0.4 or 1)
    Cooldown(face, spell)
    face.key:SetText(ns.options.macroKey and face.keyText or "")
    face.name:SetText(ns.options.macroName and macro and macro.name or "")
end

-- Every face, or the one given.
function Face.Paint()
    for _, face in pairs(faces) do PaintOne(face) end
end

local function Enter(face)
    local tip = rawget(_G, "GameTooltip")
    local macro = face.macro
    if not (tip and macro) then return end
    tip:SetOwner(face, "ANCHOR_RIGHT")
    tip:SetText(macro.name, 1, 0.82, 0)
    local turn = Macros.Press.Next(macro)
    if turn then tip:AddLine(turn.line, 1, 1, 1, true) end
    if Macros.Press.Waits(turn) then tip:AddLine(Macros.TEXT.onceWaits, 1, 0.82, 0, true) end
    tip:AddLine(Macros.TEXT.faceTip, 0.6, 0.6, 0.6, true)
    tip:Show()
end

-- Something of the game's on the cursor let go on the face, or clicked onto it: the macro comes off, and the game's own
-- PlaceAction puts it on the button beneath (what that held goes onto the cursor).
local function Dropped(face)
    if not Core.Ask(rawget(_G, "GetCursorInfo")) then return end
    if InCombatLockdown() then return ns.Print(Macros.TEXT.noCombat) end
    local action = Core.Plain(rawget(face.slot, "action"))
    Macros.TakeOff(face.place)
    if type(action) == "number" then Core.Ask(rawget(_G, "PlaceAction"), action) end
end

local function Down(face, mouse)
    if mouse == "LeftButton" then Dropped(face) end
end

-- Whether a drag may lift it, as the game's buttons say: the bars unlocked, or the pick-up key held.
local function Liftable()
    return not GetCVarBool("lockActionBars") or IsModifiedClick("PICKUPACTION")
end

local lifted -- the face whose macro follows the mouse now

local function Lift(face)
    if not (face.macro and Liftable()) then return end
    if InCombatLockdown() then return ns.Print(Macros.TEXT.noCombat) end
    Core.HideTip()
    local macro = face.macro
    lifted = face
    Macros.Place.Start(function(place)
        Macros.Reach.SetPlace(macro, place)
        ns.Safe("macros", Macros.Editor.Refresh)
    end, face.icon:GetTexture())
end

-- Let go: on a button it is there now; on none, off the bars.
local function Land(face)
    if lifted ~= face then return end
    lifted = nil
    if Macros.Place.Drop() == false then Macros.TakeOff(face.place) end
end

-- What shows follows the game's own news, only once a macro lies on a bar. A new target, a fight's end and your cast
-- move the game's cast sequences (a step cast once a target) at the same news, so those paint a frame later, when
-- the game has moved them.
local function Listen()
    if listening then return end
    listening = true
    for _, event in ipairs({ "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "MODIFIER_STATE_CHANGED",
                             "PLAYER_REGEN_DISABLED", "SPELLS_CHANGED" }) do
        ns.On(event, Face.Paint)
    end
    local soon = Core.Later(ns.Guard(Face.Paint), nil, "macros")
    ns.On("PLAYER_TARGET_CHANGED", soon)
    ns.On("PLAYER_REGEN_ENABLED", soon)
    Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", soon)
end

-- The face of a place on bar button slot. Out of a fight.
function Face.Get(place, slot, name)
    local face = faces[place]
    if not face then
        face = CreateFrame("Button", name, slot:GetParent(), "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
        face.icon = face:CreateTexture(nil, "ARTWORK")
        face.icon:SetAllPoints()
        face.icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP)
        face.cooldown = CreateFrame("Cooldown", nil, face, "CooldownFrameTemplate")
        face.cooldown:SetAllPoints()
        face.key = face:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
        face.key:SetPoint("TOPRIGHT", -2, -3)
        face.name = face:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
        face.name:SetPoint("BOTTOMLEFT", 2, 2)
        face.name:SetPoint("BOTTOMRIGHT", -2, 2)
        face.name:SetHeight(10)
        face.name:SetWordWrap(false)
        face.name:SetJustifyH("CENTER")
        face.lit = face:CreateTexture(nil, "HIGHLIGHT")
        face.lit:SetAllPoints()
        face.lit:SetColorTexture(1, 1, 1, 0.15)
        face:SetScript("OnEnter", ns.Guard(Enter))
        face:SetScript("OnLeave", ns.Guard(Core.HideTip))
        face:RegisterForDrag("LeftButton")
        face:SetScript("OnReceiveDrag", ns.Guard(Dropped))
        face:SetScript("OnMouseDown", ns.Guard(Down))
        face:SetScript("OnDragStart", ns.Guard(Lift))
        face:SetScript("OnDragStop", ns.Guard(Land))
        face:Hide()
        face.place = place
        faces[place] = face
        Macros.Press.Ready(face, true)
        Listen()
    end
    face.slot = slot
    face:SetAllPoints(slot)
    face:SetFrameLevel(slot:GetFrameLevel() + 10)
    return face
end

-- A face's macro: its hub is what its press reads.
function Face.Show(face, macro, keyText)
    face.macro, face.keyText = macro, keyText or ""
    face:SetFrameRef("hub", Macros.Press.Hub(macro))
    PaintOne(face)
end

function Face.Edges()
    for _, face in pairs(faces) do Macros.Press.Ready(face, true) end
end
