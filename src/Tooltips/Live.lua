local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Live
--  The parts of a panel that change while it is shown and are therefore not
--  drawn from the model but kept up to date here: a unit's health and power,
--  whom it targets, its buffs and debuffs, and a buff's running time.
--
--  Panel.lua lays the parts out and puts them into panel.live; this file
--  fills them. It runs from the panel's OnUpdate (Tooltips.lua), so only
--  while a panel is shown, and not on every frame (PERIOD).
--
--  In a fight the game hides a unit's numbers from addons. The bars and texts
--  take such numbers as they are (the game's own widgets may show them);
--  nothing here computes with them, and nothing asks a bar or a text what it
--  was given: once it holds a hidden number, its answers are hidden too
--  (Pools.lua keeps these texts apart from the ones it measures). A unit's
--  buffs cannot be asked for in a fight at all: they are shown outside of one.
--
--  The unit is asked for by a name the game's functions take ("mouseover").
--  Once the mouse has left it, that name means another unit or none (the
--  panel is gone then, Faded in Tooltips.lua; should it still stand, it stands
--  still as it was: the unit's GUID tells).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local TEXT = ns.TEXT
local Live = {}
ns.Live = Live

local PERIOD = 0.1       -- seconds between two updates of a unit's numbers
local AURA_PERIOD = 0.5  -- ... of its buffs
local MAX_AURAS = 16
local YOU, YOU_WORD = ns.COLOR.RED, ns.Global("UNIT_YOU") or TEXT.YOU -- you as a unit's target: the game's word, in its red
-- A buff's icon fades out at its edge like the panel's (a mask of our own, made by dev/tools/tooltip-art)
local AURA_MASK = "Interface\\AddOns\\" .. ADDON .. "\\Art\\aura-mask"
local PLAIN_NAME = ns.COLOR.LIGHT

-- Buffs can be asked for: not in a fight, and not while the game keeps them to itself.
local function AurasOpen()
    if InCombatLockdown() then return false end
    local secrets = rawget(_G, "C_Secrets")
    if secrets and secrets.ShouldAurasBeSecret and secrets.ShouldAurasBeSecret() then return false end
    return true
end

local function Aura(unit, index, filter)
    local aura = Ask(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
    return type(aura) == "table" and aura or nil
end

-- What a unit has that takes a row: a target, buffs or debuffs, and the kind of its power
-- ("MANA"). Asked when its tooltip is read, and again while its panel is shown: a change
-- lays the panel out anew.
function Live.Facts(unit)
    local target = Plain(UnitExists(unit .. "target")) == true
    local auras = AurasOpen() and (Aura(unit, 1, "HELPFUL") or Aura(unit, 1, "HARMFUL")) and true or false
    local _, power = UnitPowerType(unit)
    power = Plain(power)
    local most = Plain(UnitPowerMax(unit))
    if most == 0 then power = nil end
    return target, auras, power or false
end

function Live.Changed(panel)
    local head = panel.model.shown.head
    if not head.unit then return false end
    local target, auras, power = Live.Facts(head.unit)
    return target ~= head.hasTarget or auras ~= head.hasAuras or power ~= head.power
end

-- The colour of a name: a player's class, or how the unit feels about you.
local function NameColor(unit)
    if Plain(UnitIsPlayer(unit)) then
        local _, class = UnitClass(unit)
        local color = Plain(class) and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end
    local reaction = Plain(UnitReaction(unit, "player"))
    local color = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
    if color then return color.r, color.g, color.b end
    return PLAIN_NAME[1], PLAIN_NAME[2], PLAIN_NAME[3]
end

-- The unit's health, power and target, into the parts Panel.lua laid out.
local function Refresh(panel, unit)
    local live = panel.live
    local health, most = UnitHealth(unit), UnitHealthMax(unit)
    if live.health then
        live.health:SetMinMaxValues(0, most)
        live.health:SetValue(health)
    end
    if live.healthText then
        -- "4,230   83%": as the game gives the numbers, hidden or not, formatted by the game
        local scale = CurveConstants and CurveConstants.ScaleTo100
        if UnitHealthPercent and scale then
            live.healthText:SetFormattedText("%s   %d%%", BreakUpLargeNumbers(health), UnitHealthPercent(unit, true, scale))
        else
            local now, all = Plain(health), Plain(most)
            live.healthText:SetText(now and all and all > 0 and ("%s   %d%%"):format(BreakUpLargeNumbers(now), now / all * 100) or "")
        end
    end
    if live.power then
        live.power:SetMinMaxValues(0, UnitPowerMax(unit))
        live.power:SetValue(UnitPower(unit))
    end
    local name = live.targetName
    if name then
        local target = unit .. "target"
        if Plain(UnitIsUnit(target, "player")) then
            name:SetText(YOU_WORD)
            name:SetTextColor(YOU[1], YOU[2], YOU[3])
        else
            -- The whole name (first name and surname); hidden, as the game gives it
            name:SetText(Core.FullName(target) or UnitName(target))
            name:SetTextColor(NameColor(target))
        end
    end
end

-- The unit's buffs, then its debuffs, in one row of small icons.
local function Auras(panel, unit)
    local live = panel.live
    local icons = panel.auraIcons
    if not icons then
        icons = {}
        panel.auraIcons = icons
    end
    local used = 0
    if live.aurasTop and AurasOpen() then
        local size, gap, crop = ns.Panel.AURA, ns.Panel.AURA_GAP, ns.Pools.ICON_CROP
        local room = math.min(MAX_AURAS, math.floor((live.aurasWidth + gap) / (size + gap)))
        local x = ns.Panel.SIDE
        for pass = 1, 2 do
            local filter = pass == 1 and "HELPFUL" or "HARMFUL"
            local index = 1
            while used < room do
                local aura = Aura(unit, index, filter)
                if not aura then break end
                used, index = used + 1, index + 1
                local icon = icons[used]
                if not icon then
                    icon = panel:CreateTexture(nil, "ARTWORK", nil, 2)
                    icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
                    icon:SetSize(size, size)
                    local mask = panel:CreateMaskTexture()
                    mask:SetTexture(AURA_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    mask:SetAllPoints(icon)
                    icon:AddMaskTexture(mask)
                    icon.mask = mask
                    icons[used] = icon
                end
                icon:SetTexture(aura.icon)
                icon:ClearAllPoints()
                icon:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -live.aurasTop)
                icon:Show()
                x = x + size + gap
            end
            if pass == 1 and used > 0 then x = x + 6 end -- a little room between the two kinds
        end
    end
    for index = used + 1, #icons do icons[index]:Hide() end
end

-- A buff's time: a bar that runs out. The game's own timer drives it where the client has one
-- (and then a time the game hides in a fight still shows); otherwise it is set from here.
local function AuraTimer(panel)
    local live, head = panel.live, panel.model.shown.head
    local bar = live.aura
    live.auraEnds, live.auraLasts = nil, nil
    if not (bar and head.auraUnit and head.auraID) then return end
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    local timer = Enum.StatusBarTimerDirection
    if bar.SetTimerDuration and C_UnitAuras.GetAuraDuration and timer then
        local ok, duration = pcall(C_UnitAuras.GetAuraDuration, head.auraUnit, head.auraID)
        if ok and duration and pcall(bar.SetTimerDuration, bar, duration, nil, timer.RemainingTime) then return end
    end
    local aura = Ask(C_UnitAuras.GetAuraDataByAuraInstanceID, head.auraUnit, head.auraID)
    local lasts, ends = type(aura) == "table" and Plain(aura.duration), type(aura) == "table" and Plain(aura.expirationTime)
    if lasts and ends and lasts > 0 then
        live.auraEnds, live.auraLasts = ends, lasts
        bar:SetMinMaxValues(0, lasts)
        bar:SetValue(math.max(0, ends - GetTime()))
    end
end

-- A panel was drawn: fill its live parts at once.
local function Start(panel)
    panel.sinceNumbers, panel.sinceAuras = 0, 0
    AuraTimer(panel)
    local unit = panel.model.shown.head.unit
    if unit then
        Refresh(panel, unit)
        Auras(panel, unit)
    elseif panel.auraIcons then
        for _, icon in ipairs(panel.auraIcons) do icon:Hide() end
    end
end

-- From the panel's OnUpdate. Returns true when the panel has to be laid out anew (the unit
-- has a target now, lost its buffs, ...).
local function Update(panel, elapsed)
    local live = panel.live
    if live.auraEnds then live.aura:SetValue(math.max(0, live.auraEnds - GetTime())) end
    local head = panel.model.shown.head
    local unit = head.unit
    if not unit then return false end
    panel.sinceNumbers = (panel.sinceNumbers or 0) + elapsed
    if panel.sinceNumbers < PERIOD then return false end
    panel.sinceNumbers = 0
    -- The name means another unit now, or none (the mouse has left it): the panel stands still.
    if head.guid and Plain(UnitGUID(unit)) ~= head.guid then return false end
    Refresh(panel, unit)
    panel.sinceAuras = (panel.sinceAuras or 0) + PERIOD
    if panel.sinceAuras < AURA_PERIOD then return false end
    panel.sinceAuras = 0
    if Live.Changed(panel) then return true end
    Auras(panel, unit)
    return false
end

-- A live part that fails (a unit the game does not let us ask about, a renamed constant) would fail
-- again twice a second: from then on panels show what they were drawn with, and the rest of the
-- tooltips works on. Told once.
local broken = false
local function Failed(problem)
    broken = true
    ns.Report("live values", problem)
end

function Live.Start(panel)
    if broken then return end
    local ok, problem = xpcall(Start, Core.Trace, panel)
    if not ok then Failed(problem) end
end

function Live.Update(panel, elapsed)
    if broken then return false end
    local ok, result = xpcall(Update, Core.Trace, panel, elapsed)
    if ok then return result end
    Failed(result)
    return false
end
