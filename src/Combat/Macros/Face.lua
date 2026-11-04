local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Face
--  Our button lying over a bar button: the macro's look there and its own press
--  (the same hub, Press.lua). It sits in the bar's frame, so it comes and goes
--  with the bar, at rest too, and it never touches the game's button, which
--  keeps what it holds underneath. It shows the step that comes next, that
--  step's cooldown by the game's duration object (a hidden value in a fight is
--  taken as it is), dimmed while the game says it cannot be used.
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
    face.icon:SetTexture(Macros.Press.Picture(step, macro))
    local spell = step and Macros.Press.SpellOf(step)
    local dim = false
    if ns.options.macroDim and spell then
        local spells = rawget(_G, "C_Spell")
        dim = spells and Core.Plain(Core.Ask(spells.IsSpellUsable, spell)) == false
    end
    face.icon:SetVertexColor(dim and 0.4 or 1, dim and 0.4 or 1, dim and 0.4 or 1)
    Cooldown(face, spell)
    face.key:SetText(ns.options.macroKey and face.keyText or "")
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
    tip:Show()
end

-- What shows follows the game's own news, only once a macro lies on a bar.
local function Listen()
    if listening then return end
    listening = true
    for _, event in ipairs({ "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "PLAYER_TARGET_CHANGED",
                             "MODIFIER_STATE_CHANGED", "PLAYER_REGEN_DISABLED", "SPELLS_CHANGED" }) do
        ns.On(event, Face.Paint)
    end
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
        face.lit = face:CreateTexture(nil, "HIGHLIGHT")
        face.lit:SetAllPoints()
        face.lit:SetColorTexture(1, 1, 1, 0.15)
        face:SetScript("OnEnter", ns.Guard(Enter))
        face:SetScript("OnLeave", ns.Guard(Core.HideTip))
        face:Hide()
        faces[place] = face
        Macros.Press.Ready(face, true)
        Listen()
    end
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
