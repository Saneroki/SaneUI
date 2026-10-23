local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - CombatText
--  The combat text: what a unit takes (damage, heals, a miss, a parry, a
--  block) rises and fades over it, in place of the numbers the game draws
--  itself. Over each creature or player with a plate, and over your own
--  character.
--
--  Each plate's dress hears its own unit's UNIT_COMBAT (Plate.EVENTS; the
--  combat log is closed to addons in this client) and hands it here
--  (CombatText.Hit). The event says what the unit took, not from whom: in a
--  group it is everybody's damage on it, not yours alone.
--
--  Your own character has no plate in this client (the game's resource
--  display is a panel of Edit Mode, not over the character), so yours rise
--  from a point of ours over the screen's middle, where the camera keeps your
--  character, as the game's own combat text about you does (CombatText.SELF).
--  Your damage taken is red with a minus.
--
--  Numbers in Sane UI's own font, Kalam Bold, outlined. What did no harm is a
--  pencil drawing in white, an immunity's in bright red (dev/tools/combat-art:
--  miss, dodge, parry, block, evade, immune; Art/combat-<name>.blp), larger than the numbers so it reads at a glance;
--  what has none (resist, absorb, reflect, interrupt) is the game's word.
--
--  A number is a small frame of ours with one text and one picture, from a
--  pool, on its host (a dress, so it follows the plate's place, size and
--  fading; or our point over the middle), moved and faded by an animation of
--  the game's (no OnUpdate); back to the pool when it is done or its plate
--  goes. Each new one takes the next lane (CombatText.LANES), so hits at once
--  stand side by side; no more than CombatText.MOST on a host (the oldest goes).
--
--  Sizes as the game's own combat feedback has them: a critical hit or heal
--  half again as large, a glancing blow smaller. Damage white when physical,
--  else in the game's colour for its school; heals in the game's green. In a
--  fight the game may hide the event from addons (secret values): a hidden
--  amount is written as it is, in the game's abbreviation, and a hidden kind
--  as a plain white number.
--
--  The game's own combat text is switched off by its CVars while ours shows
--  (CombatText.CVARS, *Instead of the game's*): its numbers over units while
--  ours are over the plates, its scrolling text about you while ours is over
--  your character. They get their defaults back when ours is switched off or
--  the module stands down. None is set in a fight: that waits for its end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local CombatText = {}
ns.CombatText = CombatText

CombatText.HEIGHT = 15     -- a number's font height, before the plate's size
CombatText.CRIT = 1.5      -- a critical hit or heal, times that (the game's combat feedback)
CombatText.SMALL = 0.75    -- a glancing blow or a word, times that (the same)
CombatText.PICTURE = 48    -- a drawing's side (the size dev/tools/art made it for)
CombatText.ABOVE = 2       -- from the top of the bar to where a number starts
CombatText.RISE = 34       -- how far it rises
CombatText.TIME = 1.1      -- seconds it shows
CombatText.FADE = 0.45     -- its last seconds, fading out
CombatText.POP = 0.08      -- seconds a critical one swells, and again to shrink back
CombatText.SWELL = 1.35    -- how large it swells
CombatText.LANES = { 0, -22, 22, -11, 11 } -- where numbers at once stand, from the middle
CombatText.MOST = 6        -- numbers on one host at once
CombatText.SELF = 60       -- your character's point: this far over the screen's middle
CombatText.FONT = Core.Journal.FONT_BOLD
CombatText.FLAGS = "OUTLINE"
-- The game's fonts, where Kalam cannot be set (its file missing).
CombatText.FALLBACK = { "CombatTextFont", "SystemFont_NamePlate_Outlined", "GameFontHighlight" }
-- The drawings, by the game's kinds of hits that did no harm.
CombatText.ART = "Interface\\AddOns\\SaneUI_Nameplates\\Art\\combat-"
CombatText.PICTURES = { MISS = "miss", DODGE = "dodge", PARRY = "parry", DEFLECT = "parry", BLOCK = "block",
                        EVADE = "evade", IMMUNE = "immune" }
-- A drawing's colour where it is not white (Saneroki, 2026-10-23: an immunity bright red).
CombatText.TINTS = { immune = { 1, 0.15, 0.1 } }
-- The game's CVars for its own combat text: over units (off while ours is over the plates) and about you (off while
-- ours is over your character).
CombatText.CVARS = {
    plates = { "floatingCombatTextCombatDamage_v2", "floatingCombatTextCombatHealing_v2" },
    self = { "enableFloatingCombatText" },
}

CombatText.WHITE = { 1, 1, 1 }
CombatText.HURT = { 1, 0.1, 0.1 }  -- the game's colour for the damage you take, in its combat text
CombatText.HEAL = { 0.1, 1, 0.1 }  -- the game's colour for heals in its combat text
-- Each school's bit and the game's colour for it (its combat log's), physical left as it is; a hit of several
-- schools takes the first of them here.
CombatText.SCHOOLS = {
    { 2, { 1, 0.9, 0.5 } },   -- holy
    { 4, { 1, 0.5, 0 } },     -- fire
    { 8, { 0.3, 1, 0.3 } },   -- nature
    { 16, { 0.5, 1, 1 } },    -- frost
    { 32, { 0.5, 0.5, 1 } },  -- shadow
    { 64, { 1, 0.5, 1 } },    -- arcane
}
-- What a hit of nothing says (UNIT_COMBAT's flags).
CombatText.NOTHING = { ABSORB = true, BLOCK = true, RESIST = true }

local free = {}       -- numbers back in the pool
local waiting = false -- the CVars wait for the fight's end
local you             -- the point over the screen's middle your own combat text rises from
local listening = false

-- The font: Kalam Bold, outlined; the game's combat text font where Kalam cannot be set.
local fallback
local function SetFont(text, height)
    if text:SetFont(CombatText.FONT, height, CombatText.FLAGS) then return end
    if not fallback then
        for _, name in ipairs(CombatText.FALLBACK) do
            local object = rawget(_G, name)
            local file = type(object) == "table" and object.GetFont and object:GetFont()
            if type(file) == "string" then fallback = file break end
        end
        fallback = fallback or "Fonts\\FRIZQT__.TTF"
    end
    text:SetFont(fallback, height, CombatText.FLAGS)
end

-- The game's word for a kind of hit (MISS, RESIST, ...), as its combat feedback says it.
local function Word(kind)
    local words = rawget(_G, "CombatFeedbackText")
    local word = type(words) == "table" and words[kind] or rawget(_G, kind)
    return type(word) == "string" and word or kind:lower()
end

-- An amount as text, in the game's abbreviation (the steps of the plates' health); a hidden one too, as it is.
local function Amount(amount)
    local ok, short = pcall(AbbreviateNumbers, amount, { breakpointData = ns.Text.STEPS })
    if ok then return short end
    ok, short = pcall(string.format, "%d", amount)
    if ok then return short end
    return ""
end

-- The colour of damage of a school (its bits): plain (white over others, red over you) for physical alone or where
-- it cannot be told.
local function School(mask, plain)
    mask = Plain(mask)
    if type(mask) ~= "number" then return plain end
    for _, school in ipairs(CombatText.SCHOOLS) do
        if math.floor(mask / school[1]) % 2 == 1 then return school[2] end
    end
    return plain
end

local function Release(number)
    if number.host then
        local list = number.host.numbers
        for index = #list, 1, -1 do
            if list[index] == number then table.remove(list, index) end
        end
    end
    number.host = nil
    number.motion:Stop()
    number:Hide()
    number:ClearAllPoints()
    free[#free + 1] = number
end

local function Done(group)
    Release(group:GetParent())
end
local OnFinished = ns.Guard(Done)

local function Make()
    local number = CreateFrame("Frame")
    number:SetSize(1, 1)
    number.text = number:CreateFontString(nil, "OVERLAY")
    number.text:SetPoint("BOTTOM")
    number.text:SetWordWrap(false)
    number.picture = number:CreateTexture(nil, "OVERLAY")
    number.picture:SetPoint("BOTTOM")
    local motion = number:CreateAnimationGroup()
    local rise = motion:CreateAnimation("Translation")
    rise:SetDuration(CombatText.TIME)
    rise:SetSmoothing("OUT")
    local fade = motion:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetStartDelay(CombatText.TIME - CombatText.FADE)
    fade:SetDuration(CombatText.FADE)
    local swell = motion:CreateAnimation("Scale")
    swell:SetOrigin("BOTTOM", 0, 0)
    swell:SetDuration(CombatText.POP)
    local shrink = motion:CreateAnimation("Scale") -- after the swell, while it still rises
    shrink:SetOrigin("BOTTOM", 0, 0)
    shrink:SetStartDelay(CombatText.POP)
    shrink:SetDuration(CombatText.POP)
    motion:SetScript("OnFinished", OnFinished)
    number.motion, number.rise, number.swell, number.shrink = motion, rise, swell, shrink
    return number
end

-- A number taken from the pool onto a host, at its next lane, the oldest let go where it has its most.
local function Take(host)
    local list = host.numbers
    if not list then
        list = {}
        host.numbers, host.lane = list, 0
    end
    if #list >= CombatText.MOST then Release(list[1]) end
    local number = table.remove(free) or Make()
    number.host = host
    list[#list + 1] = number
    host.lane = host.lane % #CombatText.LANES + 1
    number:SetParent(host)
    number:SetFrameLevel(host:GetFrameLevel() + 20)
    number:SetPoint("BOTTOM", host, "TOP", CombatText.LANES[host.lane], CombatText.ABOVE)
    return number
end

local function Play(number, critical)
    number.rise:SetOffset(0, CombatText.RISE)
    local swell = critical and CombatText.SWELL or 1
    number.swell:SetScale(swell, swell)
    number.shrink:SetScale(1 / swell, 1 / swell)
    number:SetAlpha(1)
    number:Show()
    number.motion:Restart()
end

-- One number over a host: its text (a value written into a form: "%s", "+%s"; a hidden one too), colour, size
-- (times CombatText.HEIGHT), swelling once where it is critical.
function CombatText.Show(host, form, value, color, size, critical)
    local number = Take(host)
    number.picture:Hide()
    SetFont(number.text, CombatText.HEIGHT * size)
    number.text:SetTextColor(color[1], color[2], color[3])
    number.text:SetFormattedText(form, value)
    number.text:Show()
    Play(number, critical)
end

-- What did no harm, over a host: its drawing, or the game's word where there is none (or its file is missing).
function CombatText.Nothing(host, kind)
    local name = CombatText.PICTURES[kind]
    if not name then
        CombatText.Show(host, "%s", Word(kind), CombatText.WHITE, CombatText.SMALL)
        return
    end
    local number = Take(host)
    if not number.picture:SetTexture(CombatText.ART .. name) then
        Release(number)
        CombatText.Show(host, "%s", Word(kind), CombatText.WHITE, CombatText.SMALL)
        return
    end
    number.text:Hide()
    local tint = CombatText.TINTS[name] or CombatText.WHITE
    number.picture:SetVertexColor(tint[1], tint[2], tint[3])
    number.picture:SetSize(CombatText.PICTURE, CombatText.PICTURE)
    number.picture:Show()
    Play(number, false)
end

-- What a host's unit took (UNIT_COMBAT: its kind, flags, amount and school), as a number or a drawing over it; mine:
-- the host is your character's (damage red with a minus).
local function Took(host, mine, kind, flags, amount, school)
    local options = ns.options or {}
    kind, flags = Plain(kind), Plain(flags)
    local plain = Plain(amount)
    if kind == nil then -- the game hides what it was: its amount as it is
        CombatText.Show(host, "%s", Amount(amount), CombatText.WHITE, 1)
    elseif kind == "WOUND" then
        if plain == 0 then
            CombatText.Nothing(host, CombatText.NOTHING[flags] and flags or "MISS")
            return
        end
        local critical = flags == "CRITICAL" or flags == "CRUSHING"
        local size = critical and CombatText.CRIT or flags == "GLANCING" and CombatText.SMALL or 1
        local form = mine and "-%s" or "%s"
        if flags == "BLOCK_REDUCED" then form = Core.Word("COMBAT_TEXT_BLOCK_REDUCED", "%s (blocked)") end
        CombatText.Show(host, form, Amount(amount), School(school, mine and CombatText.HURT or CombatText.WHITE), size, critical)
    elseif kind == "HEAL" then
        if options.combatHeals == false then return end
        local critical = flags == "CRITICAL"
        CombatText.Show(host, "+%s", Amount(amount), CombatText.HEAL, critical and CombatText.CRIT or 1, critical)
    elseif kind ~= "ENERGIZE" then -- a miss, dodge, parry, block, immune, evade, deflect, reflect, resist, interrupt
        CombatText.Nothing(host, kind)
    end
end

-- What a plate's unit took.
function CombatText.Hit(dress, kind, flags, amount, school)
    if ns.off or (ns.options or {}).combatText == false or not dress:IsShown() then return end
    Took(dress, false, kind, flags, amount, school)
end

-- What your character took.
local function Yours(_, kind, flags, amount, school)
    if ns.off or not you then return end
    you:SetScale(ns.Scale.Full())
    Took(you, true, kind, flags, amount, school)
end

-- Every number off a host (its plate went).
function CombatText.Clear(host)
    local list = host.numbers
    if not list then return end
    for index = #list, 1, -1 do Release(list[index]) end
end

-- The game's CVars off (0) or at their defaults; where this client has them, never in a fight.
local function Set(names, hide)
    for _, name in ipairs(names) do
        local now, default = Core.Ask(C_CVar.GetCVarInfo, name)
        local wanted = hide and "0" or default
        if now ~= nil and wanted ~= nil and tostring(now) ~= wanted then Core.Ask(C_CVar.SetCVar, name, wanted) end
    end
end

-- Everything as the settings say: your character's text heard or not, the game's own combat text off or back.
local function Apply()
    local options = ns.options or {}
    local plates = not ns.off and options.combatText ~= false
    local yours = not ns.off and options.combatSelf ~= false
    if yours and not listening then
        you = you or CreateFrame("Frame", nil, UIParent)
        you:SetSize(1, 1)
        you:ClearAllPoints()
        you:SetPoint("CENTER", UIParent, "CENTER", 0, CombatText.SELF)
        Core.OnUnit("UNIT_COMBAT", "player", Yours)
        listening = true
    elseif not yours and listening then
        Core.OffUnit("UNIT_COMBAT", "player", Yours)
        listening = false
        CombatText.Clear(you)
    end
    if InCombatLockdown() then
        waiting = true
        return
    end
    waiting = false
    local game = options.combatGame ~= false
    Set(CombatText.CVARS.plates, plates and game)
    Set(CombatText.CVARS.self, yours and game)
end
CombatText.Update = Apply

-- Standing down: the game's combat text back, yours no longer heard.
function CombatText.GiveBack()
    Apply()
end

function CombatText.Start()
    ns.On("PLAYER_REGEN_ENABLED", function()
        if waiting then Apply() end
    end)
    Apply()
end
