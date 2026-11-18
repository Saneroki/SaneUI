local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Nameplates - CombatText
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
--  from a point of ours under the screen's middle, about at your character's
--  feet, where the camera keeps it (CombatText.SELF; Saneroki, 2026-10-23).
--  Your damage taken has a minus.
--
--  Numbers in the game's own font (its combat text's, Friz Quadrata),
--  outlined (Saneroki, 2026-11-15: the game's fonts and art in place of our
--  own). What did no harm is the game's word (Miss, Dodge, ...).
--
--  A number is a small frame of ours with one text, from a
--  pool, on its host (a dress, so it follows the plate's place, size and
--  fading; or our point over the middle), moved and faded by an animation of
--  the game's (no OnUpdate); back to the pool when it is done or its plate
--  goes. Each new one takes the next lane (CombatText.LANES), so hits at once
--  stand side by side; no more than CombatText.MOST on a host (the oldest goes).
--
--  Sizes as the game's own combat feedback has them: a critical hit or heal
--  half again as large, a glancing blow smaller. Three colours: physical
--  damage (auto attacks) white, spell damage red, heals green. In a
--  fight the game may hide the event from addons (secret values), and an
--  addon may not compare what is hidden, only write it into a text: a hidden
--  amount is written as it is, in the game's abbreviation; a hidden school
--  picks its colour inside the text (Hued); a hidden kind is a plain number,
--  in its school's colour over a foe, where it is damage, and white
--  elsewhere, where it may be a heal.
--
--  The game's own combat text is switched off by its CVars while ours shows
--  (CombatText.CVARS, *Instead of the game's*): its numbers over units while
--  ours are over the plates, its scrolling text about you while ours is over
--  your character. What they had before ours is kept with the module's
--  settings and goes back when ours is switched off, the module stands down,
--  or the game is about to write its settings (a logout, a /reload): so a
--  module switched off or not loaded leaves the game's and the profiles'
--  values alone. None is set in a fight: that waits for its end.
--  They are set again a little after the game has its stored settings and
--  Core's Sync has written a profile's (both come after the login, and would
--  turn the game's numbers back on), and whenever one of them changes while
--  ours shows (CVAR_UPDATE).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local CombatText = {}
ns.CombatText = CombatText

CombatText.HEIGHT = 15     -- a number's font height, before the plate's size
CombatText.CRIT = 1.5      -- a critical hit or heal, times that (the game's combat feedback)
CombatText.SMALL = 0.75    -- a glancing blow or a word, times that (the same)
CombatText.ABOVE = 2       -- from the top of the bar to where a number starts
CombatText.RISE = 34       -- how far it rises
CombatText.TIME = 1.1      -- seconds it shows
CombatText.FADE = 0.45     -- its last seconds, fading out
CombatText.POP = 0.08      -- seconds a critical one swells, and again to shrink back
CombatText.SWELL = 1.35    -- how large it swells
CombatText.LANES = { 0, -22, 22, -11, 11 } -- where numbers at once stand, from the middle
CombatText.MOST = 6        -- numbers on one host at once
CombatText.SELF = -130     -- your character's point: this far from the screen's middle (down: about at its feet)
CombatText.FONT = rawget(_G, "DAMAGE_TEXT_FONT") or Core.Look.FONT -- the game's combat text font
CombatText.FLAGS = "OUTLINE"
-- The game's fonts, where its font file cannot be set.
CombatText.FALLBACK = { "CombatTextFont", "SystemFont_NamePlate_Outlined", "GameFontHighlight" }
-- The game's CVars for its own combat text: over units (off while ours is over the plates) and about you (off while
-- ours is over your character).
CombatText.CVARS = {
    plates = { "floatingCombatTextCombatDamage_v2", "floatingCombatTextCombatHealing_v2" },
    self = { "enableFloatingCombatText" },
}

-- Three colours only (Saneroki, 2026-10-23: a school's own colour confused): physical damage (auto attacks and
-- physical abilities) white, spell damage red, heals green; the red and green are the game's in its combat text.
CombatText.WHITE = { 1, 1, 1 }
CombatText.SPELL = { 1, 0.1, 0.1 }
CombatText.HEAL = { 0.1, 1, 0.1 }
CombatText.PHYSICAL = 1 -- the physical school's bit (the game's SCHOOL_MASK_PHYSICAL)
CombatText.SHADE = "2550e-" -- a hidden school's green and blue, with the school as the exponent (Hued)
-- What a hit of nothing says (UNIT_COMBAT's flags).
CombatText.NOTHING = { ABSORB = true, BLOCK = true, RESIST = true }

local free = {}       -- numbers back in the pool
local waiting = false -- the CVars wait for the fight's end
local you             -- the point about at your character's feet its own combat text rises from
local listening = false

-- The font: the game's combat text font, outlined; the game's font objects where its file cannot be set.
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
local steps -- the game's abbreviation in our steps, made once
local function Amount(amount)
    steps = steps or { breakpointData = ns.Text.STEPS }
    local ok, short = pcall(AbbreviateNumbers, amount, steps)
    if ok then return short end
    ok, short = pcall(string.format, "%d", amount)
    if ok then return short end
    return ""
end

-- The colour of damage of a school (its bits): white for physical alone or where it cannot be told, red for any
-- spell school.
local function School(mask)
    if type(mask) ~= "number" or mask == 0 or mask == CombatText.PHYSICAL then return CombatText.WHITE end
    return CombatText.SPELL
end

-- A text in the colour of a school the game hides. A hidden number cannot be compared or looked up, only written into
-- a text, but such a text is read as a number again: as the exponent of 2550 the physical school (1) makes 255 and
-- every spell school (2 and up) 25 or less, in hex the green and blue of white or of red. No school told (0) comes out
-- the palest pink: that one has too many digits and is cut to two.
function CombatText.Hued(form, value, school)
    local shade = ("%02x"):format(CombatText.SHADE .. school)
    return ("|cffff%.2s%.2s" .. form .. "|r"):format(shade, shade, value)
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
    SetFont(number.text, CombatText.HEIGHT * size)
    number.text:SetTextColor(color[1], color[2], color[3])
    number.text:SetFormattedText(form, value)
    number.text:Show()
    Play(number, critical)
end

-- Damage over a host, in its school's colour; a hidden school's goes into the text, white where the game refuses that.
local function Damage(host, form, value, school, size, critical)
    if not Core.Secret(school) then
        CombatText.Show(host, form, value, School(school), size, critical)
        return
    end
    local ok, text = pcall(CombatText.Hued, form, value, school)
    if ok then form, value = "%s", text end
    CombatText.Show(host, form, value, CombatText.WHITE, size, critical)
end

-- What did no harm, over a host: the game's word.
function CombatText.Nothing(host, kind)
    CombatText.Show(host, "%s", Word(kind), CombatText.WHITE, CombatText.SMALL)
end

-- What a host's unit took (UNIT_COMBAT: its kind, flags, amount and school), as a number or a drawing over it; mine:
-- the host is your character's (damage with a minus).
local function Took(host, mine, kind, flags, amount, school)
    local options = ns.options or {}
    kind, flags = Plain(kind), Plain(flags)
    local plain = Plain(amount)
    if kind == nil then -- the game hides what it was: its amount as it is, damage only over a foe
        local foe = host.unit and Core.Ask(UnitCanAttack, "player", host.unit) == true
        -- The school may be hidden too: never tested, only handed on (Damage writes a hidden one into the text).
        local hue = CombatText.PHYSICAL
        if foe then hue = school end
        Damage(host, "%s", Amount(amount), hue, 1)
    elseif kind == "WOUND" then
        -- The game hides the amount (Forever since build 70755, Retail since 70783) and a hidden one cannot be told
        -- from 0: then the flags say a blow taken whole (a part blocked is BLOCK_REDUCED).
        if plain == 0 or (plain == nil and CombatText.NOTHING[flags]) then
            CombatText.Nothing(host, CombatText.NOTHING[flags] and flags or "MISS")
            return
        end
        local critical = flags == "CRITICAL" or flags == "CRUSHING"
        local size = critical and CombatText.CRIT or flags == "GLANCING" and CombatText.SMALL or 1
        local form = mine and "-%s" or "%s"
        if flags == "BLOCK_REDUCED" then form = Core.Word("COMBAT_TEXT_BLOCK_REDUCED", "%s (blocked)") end
        Damage(host, form, Amount(amount), school, size, critical)
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

-- One CVar set: through Core's Sync where it is there (it leaves one the game locked alone, and notes one the game
-- does not take), else the game's own.
local function Put(name, value)
    local sync = Core.Sync
    if sync and sync.SetCVar then sync.SetCVar(name, value) else Core.Ask(C_CVar.SetCVar, name, value) end
end

-- The values the CVars had before ours (the game's, a profile's, the player's), kept with the module's settings so a
-- logout can put them back: [name] = value.
local function Found()
    local options = ns.options or {}
    if type(options.combatFoundCVars) ~= "table" then options.combatFoundCVars = {} end
    return options.combatFoundCVars
end

local applied = {} -- [group of CombatText.CVARS] = true: ours were set this session

-- A group's CVars ours (0), where this client has them; what each had before kept first (once, as it was first
-- seen, also one already at 0: a value of the player's own, never a later value of ours).
local function Ours(group)
    local found = Found()
    applied[group] = true
    for _, name in ipairs(CombatText.CVARS[group]) do
        local now = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil then
            if found[name] == nil then found[name] = tostring(now) end
            if tostring(now) ~= "0" then Put(name, "0") end
        end
    end
end

-- A group's CVars back to what they had before ours, once, and nothing kept any more: from now on they are the
-- game's and the profiles' alone.
local function Restore(group)
    if not applied[group] then return end
    applied[group] = nil
    local found = Found()
    for _, name in ipairs(CombatText.CVARS[group]) do
        local now, default = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil then
            -- What was found before ours (kept whether it equalled ours or not); a found table wiped meanwhile (a
            -- reset of the settings, a profile moved) with the CVar still at our 0: the game's default.
            local back = found[name]
            if back == nil and tostring(now) == "0" then back = default end
            if back ~= nil and tostring(now) ~= tostring(back) then Put(name, tostring(back)) end
        end
        found[name] = nil
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
    if plates and game then Ours("plates") else Restore("plates") end
    if yours and game then Ours("self") else Restore("self") end
end
CombatText.Update = Apply

-- The game about to write its settings (a logout, a /reload): what was there before ours goes back, so with the
-- module gone the game and the profiles have their own; loaded again, it sets ours again at the login.
function CombatText.Logout()
    Restore("plates")
    Restore("self")
end

-- Standing down: the game's combat text back, yours no longer heard.
function CombatText.GiveBack()
    Apply()
end

-- Once more a little later: after the game's stored settings and Sync's (Sync waits 2 seconds), or after
-- something else set one of ours.
CombatText.AGAIN = 3
local again = Core.Later(Apply, CombatText.AGAIN)
local watched = {} -- [lower-case CVar name] = true
for _, names in pairs(CombatText.CVARS) do
    for _, name in ipairs(names) do watched[name:lower()] = true end
end

local function Changed(name)
    if type(name) == "string" and watched[name:lower()] then again() end
end

function CombatText.Start()
    ns.On("PLAYER_REGEN_ENABLED", function()
        if waiting then Apply() end
    end)
    ns.On("PLAYER_ENTERING_WORLD", again)
    ns.On("VARIABLES_LOADED", again)
    ns.On("CVAR_UPDATE", Changed)
    Apply()
end
