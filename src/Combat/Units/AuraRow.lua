local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Units - Aura row
--  The icons above a unit frame while the game tells addons a unit's auras (out
--  of a fight), as Auras.lua says which show and where: frames of ours, because
--  no script of an addon runs on the game's aura icons, nor on anything made a
--  child of one (AuraButton's UntrustedScriptExecution), and what they show is
--  kept from addons at all times (their regions' secret aspects).
--
--  On these the mouse works: on an icon your tooltip of the aura (GameTooltip, the
--  one the module Tooltips draws) and the unit frame in sight at rest (a door of
--  its Core.Rest, Auras.Make's area holding it over the gaps); a left or right
--  click the aura's menu (Lists.Menu). A fight begins and the game's icons take
--  over (Auras.Set), with the game's own tooltip and no click.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Auras = ns.UnitAuras
local Row = {}
ns.AuraRow = Row

-- Whether the game tells addons a unit's auras now.
function Row.Open()
    if Core.Restricted() then return false end
    local secrets = rawget(_G, "C_Secrets")
    return not (secrets and secrets.ShouldAurasBeSecret and Core.Ask(secrets.ShouldAurasBeSecret) == true)
end

-- A unit's auras of a filter, in the game's order of that name (its rules have no Unit frame debuff order: its default).
local function Read(unit, filter, order)
    local rules = rawget(_G, "Enum") and Enum.UnitAuraSortRule
    local list = Core.Ask(C_UnitAuras.GetUnitAuras, unit, filter, nil, rules and (rules[order] or rules.Default))
    return type(list) == "table" and list or {}
end

-- What shows of a kind: the important, those marked Prioritize on unit frames, then the rest, each at most the kind's most.
-- Returns them, and the set of the important.
local function Pick(face, kind)
    local first, second, never = Auras.Sets()
    local unit, picked = face.auraUnit, {}
    local function Take(list, keep)
        local count = 0
        for _, aura in ipairs(list) do
            local id = Plain(aura.spellId)
            if count < kind.most and id and keep(id) then
                count = count + 1
                picked[#picked + 1] = aura
            end
        end
    end
    if kind.listed then
        local all = Read(unit, kind.listed)
        Take(all, function(id) return first and first[id] end)
        Take(all, function(id) return second and second[id] end)
    end
    Take(Read(unit, face.auraFoe and kind.foe or kind.friend, kind.sort), function(id)
        return not (never and never[id]) and not (kind.listed and (first and first[id] or second and second[id]))
    end)
    return picked, first
end

local function Clicked(icon, button)
    if button == "LeftButton" or button == "RightButton" then ns.AuraLists.Menu(icon, icon.spell) end
end

-- The aura's tooltip, the same way the game's list of your buffs asks for it.
local function Entered(icon)
    if not icon.instance then return end
    GameTooltip:SetOwner(icon, "ANCHOR_TOP")
    GameTooltip:SetUnitAuraByAuraInstanceID(icon.spell.unit, icon.instance)
    GameTooltip:Show()
end

local function Left(icon)
    if GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
end

local OnClicked = ns.Guard(Clicked)
local OnEntered = ns.Guard(Entered)
local OnLeft = ns.Guard(Left)

local function Icon(face, index)
    local icon = face.rowIcons[index]
    if icon then return icon end
    icon = CreateFrame("Frame", nil, face)
    icon:SetSize(Auras.SIZE, Auras.SIZE)
    icon.parts = Auras.Paint(icon)
    icon:EnableMouse(true)
    icon:SetScript("OnMouseUp", OnClicked)
    icon:SetScript("OnEnter", OnEntered)
    icon:SetScript("OnLeave", OnLeft)
    if face.rest then face.rest:Door(icon) end
    face.rowIcons[index] = icon
    return icon
end

-- Its place: the kind's corner of the frame's roof, in lines of the kind's most, going up; crowd control around the middle.
local function Place(icon, face, kind, index, wide)
    local column, line = (index - 1) % kind.most, math.floor((index - 1) / kind.most)
    local x = column * Auras.SIZE
    if kind.point == "BOTTOMRIGHT" then
        x = -x
    elseif kind.point == "BOTTOM" then
        x = (column - (wide - 1) / 2) * Auras.SIZE
    end
    icon:ClearAllPoints()
    icon:SetPoint(kind.point, face.roof, kind.point, x, Auras.GAP + line * Auras.SIZE)
end

local function Draw(icon, aura, kind, unit, shining)
    local parts = icon.parts
    icon.spell = { id = Plain(aura.spellId), name = Plain(aura.name), icon = Plain(aura.icon), harmful = kind.harmful, unit = unit }
    icon.instance = Plain(aura.auraInstanceID)
    parts.picture:SetTexture(icon.spell.icon)
    local lasts, ends = Plain(aura.duration), Plain(aura.expirationTime)
    if lasts and ends and lasts > 0 then
        parts.cooldown:SetCooldown(ends - lasts, lasts)
    else
        parts.cooldown:Clear()
    end
    local stacks = Plain(aura.applications)
    parts.count:SetText(stacks and stacks > 1 and stacks or "")
    if shining and not icon.alert then
        icon.alert = ns.BuffList.Alert(parts.top, icon)
        if icon.alert then icon.alert:SetFrameLevel(parts.top:GetFrameLevel() + 3) end
    end
    if icon.alert then icon.alert:SetShown(shining and true or false) end
    icon:Show()
end

-- The row as the unit's auras are now; none while it is not to show (Auras.Set).
function Row.Fill(face)
    face.rowIcons = face.rowIcons or {}
    local used = 0
    if face.auraUnit and Row.Open() then
        for _, kind in ipairs(Auras.KINDS) do
            local picked, first = Pick(face, kind)
            local wide = math.min(#picked, kind.most)
            for index, aura in ipairs(picked) do
                used = used + 1
                local icon = Icon(face, used)
                Place(icon, face, kind, index, wide)
                Draw(icon, aura, kind, face.auraUnit, first and first[Plain(aura.spellId)])
            end
        end
    end
    for index = used + 1, #face.rowIcons do face.rowIcons[index]:Hide() end
end

-- A frame's set at rest (Units.lua) takes the icons made so far as doors; the ones to come take it in Icon.
function Row.Doors(face)
    for _, icon in ipairs(face.rowIcons or {}) do face.rest:Door(icon) end
end

function Row.Start()
    local soon = Core.Later(function() Auras.Each(Row.Fill) end, 0, "unit frame auras")
    for _, unit in ipairs({ "player", "target", "focus" }) do
        Core.OnUnit("UNIT_AURA", unit, function() soon() end)
    end
    -- Who shows the auras changes as the game stops or starts telling them.
    local function Swap()
        Auras.Each(function(face) Auras.Set(face, face.auraAsked) end)
    end
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "ADDON_RESTRICTION_STATE_CHANGED" }) do
        Core.On(event, Swap)
    end
end
