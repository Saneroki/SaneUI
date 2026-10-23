local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Numbers
--  Combat numbers over a plate: what its unit takes (damage, heals, a miss,
--  a dodge, a block) rises from the top of its bar and fades, in place of the
--  numbers the game draws into the world itself.
--
--  Each plate's dress hears its own unit's UNIT_COMBAT (Plate.EVENTS; the
--  combat log is closed to addons in this client) and hands it here
--  (Numbers.Hit). The event says what the unit took, not from whom: in a
--  group it is everybody's damage on it, not yours alone.
--
--  A number is a small frame of ours with one text, from a pool, on the
--  dress (so it follows the plate's place, size and fading), moved and faded
--  by an animation of the game's (no OnUpdate); back to the pool when it is
--  done or its plate goes. Each new number takes the next lane (Numbers.LANES),
--  so hits at once stand side by side; no more than Numbers.MOST on a plate
--  (the oldest goes).
--
--  Sizes as the game's own combat feedback has them: a critical hit or heal
--  half again as large, a glancing blow and a word (a miss, a block) smaller.
--  Damage white when physical, else in the game's colour for its school; heals
--  in the game's green. In a fight the game may hide the event from addons
--  (secret values): a hidden amount is written as it is, in the game's
--  abbreviation, and a hidden kind as a plain white number.
--
--  The game's own numbers over units are switched off by its CVars while ours
--  show (Numbers.CVARS, *Instead of the game's numbers*), and get their
--  defaults back when ours are switched off or the module stands down. None is
--  set in a fight: that waits for its end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Numbers = {}
ns.Numbers = Numbers

Numbers.HEIGHT = 15     -- a number's font height, before the plate's size
Numbers.CRIT = 1.5      -- a critical hit or heal, times that (the game's combat feedback)
Numbers.SMALL = 0.75    -- a glancing blow or a word, times that (the same)
Numbers.ABOVE = 2       -- from the top of the bar to where a number starts
Numbers.RISE = 34       -- how far it rises
Numbers.TIME = 1.1      -- seconds it shows
Numbers.FADE = 0.45     -- its last seconds, fading out
Numbers.POP = 0.08      -- seconds a critical one swells, and again to shrink back
Numbers.SWELL = 1.35    -- how large it swells
Numbers.LANES = { 0, -22, 22, -11, 11 } -- where numbers at once stand, from the bar's middle
Numbers.MOST = 6        -- numbers on one plate at once
Numbers.FONTS = { "CombatTextFont", "SystemFont_NamePlate_Outlined", "GameFontHighlight" }
-- The game's CVars for its own numbers over units, off while ours show.
Numbers.CVARS = { "floatingCombatTextCombatDamage_v2", "floatingCombatTextCombatHealing_v2" }

Numbers.WHITE = { 1, 1, 1 }
Numbers.HEAL = { 0.1, 1, 0.1 } -- the game's colour for heals in its combat text
-- Each school's bit and the game's colour for it (its combat log's), physical left white; a hit of several schools
-- takes the first of them here.
Numbers.SCHOOLS = {
    { 2, { 1, 0.9, 0.5 } },   -- holy
    { 4, { 1, 0.5, 0 } },     -- fire
    { 8, { 0.3, 1, 0.3 } },   -- nature
    { 16, { 0.5, 1, 1 } },    -- frost
    { 32, { 0.5, 0.5, 1 } },  -- shadow
    { 64, { 1, 0.5, 1 } },    -- arcane
}
-- What a hit of nothing says (UNIT_COMBAT's flags), in the game's words.
Numbers.NOTHING = { ABSORB = true, BLOCK = true, RESIST = true }

local free = {}       -- numbers back in the pool
local waiting = false -- the CVars wait for the fight's end

-- The font for the numbers: the game's combat text font (its face, outlined), read once.
local font
local function Font()
    if font then return font end
    for _, name in ipairs(Numbers.FONTS) do
        local object = rawget(_G, name)
        local file, _, flags
        if type(object) == "table" and object.GetFont then file, _, flags = object:GetFont() end
        if type(file) == "string" then
            font = { file = file, flags = (flags and flags ~= "") and flags or "OUTLINE" }
            return font
        end
    end
    font = { file = "Fonts\\FRIZQT__.TTF", flags = "OUTLINE" }
    return font
end

-- The game's word for a kind of hit (MISS, DODGE, ...), as its combat feedback says it.
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

-- The colour of damage of a school (its bits): white for physical alone or where it cannot be told.
local function School(mask)
    mask = Plain(mask)
    if type(mask) ~= "number" then return Numbers.WHITE end
    for _, school in ipairs(Numbers.SCHOOLS) do
        if math.floor(mask / school[1]) % 2 == 1 then return school[2] end
    end
    return Numbers.WHITE
end

local function Release(number)
    if number.dress then
        local list = number.dress.numbers
        for index = #list, 1, -1 do
            if list[index] == number then table.remove(list, index) end
        end
    end
    number.dress = nil
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
    rise:SetDuration(Numbers.TIME)
    rise:SetSmoothing("OUT")
    local fade = motion:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetStartDelay(Numbers.TIME - Numbers.FADE)
    fade:SetDuration(Numbers.FADE)
    local swell = motion:CreateAnimation("Scale")
    swell:SetOrigin("BOTTOM", 0, 0)
    swell:SetDuration(Numbers.POP)
    local shrink = motion:CreateAnimation("Scale") -- after the swell, while it still rises
    shrink:SetOrigin("BOTTOM", 0, 0)
    shrink:SetStartDelay(Numbers.POP)
    shrink:SetDuration(Numbers.POP)
    motion:SetScript("OnFinished", OnFinished)
    number.motion, number.rise, number.swell, number.shrink = motion, rise, swell, shrink
    return number
end

-- One number over a dress: its text (a value written into a form: "%s", "+%s"; a hidden one too), colour, size
-- (times Numbers.HEIGHT), swelling once where it is critical.
function Numbers.Show(dress, form, value, color, size, critical)
    local list = dress.numbers
    if not list then
        list = {}
        dress.numbers, dress.lane = list, 0
    end
    if #list >= Numbers.MOST then Release(list[1]) end
    local number = table.remove(free) or Make()
    number.dress = dress
    list[#list + 1] = number
    dress.lane = dress.lane % #Numbers.LANES + 1
    number:SetParent(dress)
    number:SetFrameLevel(dress:GetFrameLevel() + 20)
    number:SetPoint("BOTTOM", dress, "TOP", Numbers.LANES[dress.lane], Numbers.ABOVE)
    local look = Font()
    number.text:SetFont(look.file, Numbers.HEIGHT * size, look.flags)
    number.text:SetTextColor(color[1], color[2], color[3])
    number.text:SetFormattedText(form, value)
    number.rise:SetOffset(0, Numbers.RISE)
    local swell = critical and Numbers.SWELL or 1
    number.swell:SetScale(swell, swell)
    number.shrink:SetScale(1 / swell, 1 / swell)
    number:SetAlpha(1)
    number:Show()
    number.motion:Restart()
end

-- What a dress's unit took (UNIT_COMBAT: its kind, flags, amount and school), as a number or a word over it.
function Numbers.Hit(dress, kind, flags, amount, school)
    local options = ns.options or {}
    if ns.off or not options.numbers or not dress:IsShown() then return end
    kind, flags = Plain(kind), Plain(flags)
    local plain = Plain(amount)
    if kind == nil then -- the game hides what it was: its amount as it is
        Numbers.Show(dress, "%s", Amount(amount), Numbers.WHITE, 1)
    elseif kind == "WOUND" then
        if plain == 0 then
            Numbers.Show(dress, "%s", Word(Numbers.NOTHING[flags] and flags or "MISS"), Numbers.WHITE, Numbers.SMALL)
            return
        end
        local critical = flags == "CRITICAL" or flags == "CRUSHING"
        local size = critical and Numbers.CRIT or flags == "GLANCING" and Numbers.SMALL or 1
        local form = flags == "BLOCK_REDUCED" and Core.Word("COMBAT_TEXT_BLOCK_REDUCED", "%s (blocked)") or "%s"
        Numbers.Show(dress, form, Amount(amount), School(school), size, critical)
    elseif kind == "HEAL" then
        if options.numbersHeal == false then return end
        local critical = flags == "CRITICAL"
        Numbers.Show(dress, "+%s", Amount(amount), Numbers.HEAL, critical and Numbers.CRIT or 1, critical)
    elseif kind ~= "ENERGIZE" then -- a miss, dodge, parry, block, immune, evade, deflect, reflect, interrupt
        Numbers.Show(dress, "%s", Word(kind), Numbers.WHITE, Numbers.SMALL)
    end
end

-- Every number off a dress (its plate went).
function Numbers.Clear(dress)
    local list = dress.numbers
    if not list then return end
    for index = #list, 1, -1 do Release(list[index]) end
end

-- The game's numbers over units off (0) or at their defaults; where this client has them, never in a fight.
local function Apply()
    if InCombatLockdown() then
        waiting = true
        return
    end
    waiting = false
    local options = ns.options or {}
    local hide = not ns.off and options.numbers ~= false and options.numbersGame ~= false
    for _, name in ipairs(Numbers.CVARS) do
        local now, default = Core.Ask(C_CVar.GetCVarInfo, name)
        local wanted = hide and "0" or default
        if now ~= nil and wanted ~= nil and tostring(now) ~= wanted then Core.Ask(C_CVar.SetCVar, name, wanted) end
    end
end
Numbers.Update = Apply

-- Standing down: the game's numbers back.
function Numbers.GiveBack()
    Apply()
end

function Numbers.Start()
    ns.On("PLAYER_REGEN_ENABLED", function()
        if waiting then Apply() end
    end)
    Apply()
end
