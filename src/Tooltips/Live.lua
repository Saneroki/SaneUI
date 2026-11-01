local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Live
--  The parts of a panel that change while it is shown and are therefore not
--  drawn from the model but kept up to date here: a unit's health and power,
--  whom it targets, its buffs and debuffs, and a buff's running time.
--
--  Panel.lua lays the parts out and puts them into panel.live; this file
--  fills them: when the panel is drawn or shown (Start), and after that when
--  the unit's own events say something changed (its health, its power, its
--  target, its buffs: Listen, from the panel's OnShow to its OnHide,
--  Tooltips.lua), answered once per frame from the panel's OnUpdate (Update),
--  which also runs a buff's timer. Nothing is asked again and again.
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
        local x = live.aurasLeft or ns.Panel.SIDE
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

-------------------------------------------------------------------------------
--  The unit's events. While its panel is shown, the game is asked to send the
--  events of that unit alone (Core.OnUnit): its health, its power, its target,
--  its buffs. Each only notes that something was heard; the panel's next frame
--  answers them all at once (Update), so a burst of them (a buff's every tick)
--  costs one look. A fight beginning or ending changes what may be asked
--  (AurasOpen), so every listening panel hears that too.
-------------------------------------------------------------------------------
local EVENTS = { "UNIT_HEALTH", "UNIT_POWER_UPDATE", "UNIT_TARGET", "UNIT_AURA" }
local FIGHT = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }
local listening = {} -- [panel] = true: it listens for its unit (panel.liveUnit) with its ear (panel.ear)
local fightHeard = false

local function FightChanged()
    for panel in pairs(listening) do panel.heard = true end
end

local function Stop(panel)
    local unit = panel.liveUnit
    if not unit then return end
    for _, event in ipairs(EVENTS) do Core.OffUnit(event, unit, panel.ear) end
    panel.liveUnit, listening[panel] = nil, nil
end

-- Listens for unit (nil: for nobody), unless the panel does already.
local function Listen(panel, unit)
    if panel.liveUnit == unit then return end
    Stop(panel)
    if not unit then return end
    local ear = panel.ear
    if not ear then
        ear = function() panel.heard = true end -- made once for the panel
        panel.ear = ear
    end
    for _, event in ipairs(EVENTS) do Core.OnUnit(event, unit, ear) end
    panel.liveUnit, listening[panel] = unit, true
    if not fightHeard then
        fightHeard = true
        for _, event in ipairs(FIGHT) do Core.On(event, FightChanged) end
    end
end

-- A panel was drawn, or shown again: fill its live parts at once, and listen for its unit from now on.
local function Start(panel)
    panel.heard = false
    AuraTimer(panel)
    local unit = panel.model.shown.head.unit
    if unit then
        Refresh(panel, unit)
        Auras(panel, unit)
    elseif panel.auraIcons then
        for _, icon in ipairs(panel.auraIcons) do icon:Hide() end
    end
    Listen(panel, unit)
end

-- From the panel's OnUpdate, every frame: a buff's time runs on; and once the unit's events said
-- something changed (heard), its numbers and buffs anew. Returns true when the panel has to be laid
-- out anew (the unit has a target now, lost its buffs, ...).
local function Update(panel)
    local live = panel.live
    if live.auraEnds then live.aura:SetValue(math.max(0, live.auraEnds - GetTime())) end
    if not panel.heard then return false end
    panel.heard = false
    local head = panel.model.shown.head
    local unit = head.unit
    if not unit then return false end
    -- The name means another unit now, or none (the mouse has left it): the panel stands still.
    if head.guid and Plain(UnitGUID(unit)) ~= head.guid then return false end
    if Live.Changed(panel) then return true end
    Refresh(panel, unit)
    Auras(panel, unit)
    return false
end

-- A live part that fails (a unit the game does not let us ask about, a renamed constant) would fail
-- again at the unit's every event: from then on panels show what they were drawn with, and the rest
-- of the tooltips works on. Told once. (A panel stops listening when it is hidden all the same.)
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

-- The panel is hidden (Tooltips.lua): its unit's events are not listened for any more.
function Live.Stop(panel)
    local ok, problem = xpcall(Stop, Core.Trace, panel)
    if not ok then Failed(problem) end
end

function Live.Update(panel)
    if broken then return false end
    local ok, result = xpcall(Update, Core.Trace, panel)
    if ok then return result end
    Failed(result)
    return false
end
