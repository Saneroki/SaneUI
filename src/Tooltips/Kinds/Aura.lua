local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Aura
--  The tooltip of a buff or a debuff:
--
--      POWER WORD: FORTITUDE           [icon]
--      Buff  ·  Magic                             what it is, and what takes it away
--      DESCRIPTION ────────────────────────
--      Increases Stamina by 26.                   its numbers in the panel's colour
--      DURATION ───────────────────────────
--      [ 17 minutes remaining  by Somniferie ]    a bar that runs out with its time; inside it
--                                                 the game's line for that, and who cast it
--
--  The panel has the game's colour of what takes the aura away (magic, curse,
--  poison, disease: the colour of a debuff's border). A debuff nothing takes
--  away has the game's colour for that; a buff nothing takes away, none.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local Read, TEXT, COLOR = ns.Reader, ns.TEXT, ns.COLOR
local TYPE = Enum.TooltipDataType or {}
local LINE = Enum.TooltipDataLineType or {}

local DESCRIPTION = LINE.SpellDescription or -1
local DETAIL = COLOR.DETAIL
local UNREMOVABLE = { 0.8, 0, 0 } -- the game's DEBUFF_TYPE_NONE_COLOR, where AuraUtil has none

-- How the game asked for the aura a tooltip shows (its getter's name, TooltipDataHandler), and so
-- how to ask for it again: by the aura's own number (instance), or by its place in the unit's list
-- of buffs or debuffs (list; none: the filter the game passed).
local GETTERS = {
    GetUnitAura = { instance = false },
    GetUnitBuff = { instance = false, list = "HELPFUL" },
    GetUnitDebuff = { instance = false, list = "HARMFUL" },
    GetUnitAuraByAuraInstanceID = { instance = true },
    GetUnitBuffByAuraInstanceID = { instance = true },
    GetUnitDebuffByAuraInstanceID = { instance = true },
}

-- The aura a tooltip shows: whose it is, and what the game says about it. Nil for one filled
-- another way.
local function Which(tooltip)
    local info = tooltip.GetPrimaryTooltipInfo and Plain(tooltip:GetPrimaryTooltipInfo())
    local how = type(info) == "table" and GETTERS[Plain(info.getterName) or ""]
    local args = how and Plain(info.getterArgs)
    if type(args) ~= "table" then return nil, nil end
    local unit, key = Plain(args[1]), Plain(args[2])
    if not (unit and key) then return nil, nil end
    local aura
    if how.instance then
        aura = Ask(C_UnitAuras.GetAuraDataByAuraInstanceID, unit, key)
    else
        aura = Ask(C_UnitAuras.GetAuraDataByIndex, unit, key, how.list or Plain(args[3]))
    end
    return unit, type(aura) == "table" and aura or nil
end

-- The game's colour of what takes an aura away ("Magic"; "None" for nothing): the one it gives a
-- debuff's border (AuraUtil). Nil when the client has none for it.
local function DispelColor(dispel)
    local display = AuraUtil and Ask(AuraUtil.GetDebuffDisplayInfoTable)
    local info = type(display) == "table" and Plain(display[dispel])
    local color = type(info) == "table" and Plain(info.color)
    if type(color) ~= "table" then return nil end
    local r, g, b = Plain(color.r), Plain(color.g), Plain(color.b)
    if not (r and g and b) then return nil end
    return r, g, b
end

local function Aura(ctx)
    local head, id = ctx.head, ctx.id
    Read.Title(true)
    head.icon = ctx.options.icons and id and Plain(C_Spell.GetSpellTexture(id)) or nil
    local unit, aura = Which(ctx.tooltip)
    if aura then
        local harmful = Plain(aura.isHarmful) == true
        local dispel = Plain(aura.dispelName)
        if type(dispel) ~= "string" or dispel == "" then dispel = nil end
        local r, g, b
        if dispel then r, g, b = DispelColor(dispel) end
        if not r and harmful then
            r, g, b = DispelColor("None")
            if not r then r, g, b = UNREMOVABLE[1], UNREMOVABLE[2], UNREMOVABLE[3] end
        end
        if r then Read.Accent(r, g, b) end
        local word = harmful and (ns.Global("DEBUFF") or TEXT.DEBUFF) or (ns.Global("BUFF") or TEXT.BUFF)
        Read.Text("sub", dispel and Read.Memo("kind", "%s  \194\183  %s", word, dispel) or word, DETAIL[1], DETAIL[2], DETAIL[3])
        head.numbers = true
    else
        Read.AccentFromTitle()
    end
    -- An aura with a time gets a bar that runs out with it. Inside it: the game's own line that
    -- says how long it still runs (its last line, not the description), and who cast it.
    local source = aura and Plain(aura.sourceUnit)
    local caster = source and Core.FullName(source)
    local by = caster and Read.Memo("by", TEXT.BY, caster) or ""
    local lasts = aura and Plain(aura.duration)
    local timed = lasts and lasts > 0
    local time
    if timed then
        local L = ctx.L
        for index = ctx.count, 2, -1 do
            local line = L[index]
            -- The game's line for the time has a number in it, and is not another addon's ID line
            if (line.own or not ctx.matched) and not line.blank and line.type ~= DESCRIPTION
                and line.left:find("%d") and not Read.IsIdLine(line) then
                time, line.used = line, true
                break
            end
        end
    end

    ctx.each = Read.Prose
    Read.Rest()
    if timed then
        Read.Section(TEXT.DURATION)
        local bar = Read.Row()
        bar.kind, bar.live = "bar", "aura"
        bar.left, bar.right = time and time.left or "", by
        local color = head.accent and head or nil
        local neutral = COLOR.NEUTRAL
        bar.br, bar.bg, bar.bb = color and color.ar or neutral[1], color and color.ag or neutral[2], color and color.ab or neutral[3]
        head.auraUnit, head.auraID = unit, Plain(aura.auraInstanceID)
    elseif by ~= "" then
        local row = Read.Row()
        row.font, row.right = "sub", by
        row.rr, row.rg, row.rb = DETAIL[1], DETAIL[2], DETAIL[3]
    end
end

if TYPE.UnitAura then ns.KINDS[TYPE.UnitAura] = Aura end
