local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Text
--  The words inside a plate's bar, on one line over its middle:
--    left    the unit's level in the game's colour for how hard it is to you
--            (a skull where it is too high to tell), and next to it your
--            threat on it: grey while low, orange when you are about to take
--            its aggro, red while you have it (and then the bar glows)
--    middle  its name: a player's first name and surname
--    right   its health, short ("850", "1.2k", "1.32m"), and how much of it
--            is left ("| 100%")
--
--  In a fight the game may hide health and threat from addons (secret
--  values). The texts then take them as they are, formatted by the game:
--  the percentages as numbers, the health by the game's abbreviation in
--  the same steps, the threat in grey (its kind cannot be told),
--  and the glow follows the game's hidden answer (Bar.Glow).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Text = {}
ns.Text = Text

-- The game's own font for its plates' names.
Text.FONTS = { "SystemFont_NamePlate_Outlined", "SystemFont_NamePlate", "GameFontHighlightSmall" }
Text.INSET = 4   -- from the bar's ends to the texts at its sides
Text.GAP = 3     -- between the level and the threat
Text.NAME = 0.44 -- the name's room, a share of the bar's width (it is cut short beyond it)
Text.SKULL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t" -- the game's mark for a level too high to tell
-- Threat by the game's kinds (UnitDetailedThreatSituation's status): 0 low, 1 about to take aggro, 2 and 3 having it.
Text.THREAT = {
    [0] = { 0.55, 0.55, 0.55 },
    [1] = { 1, 0.55, 0.05 },
    [2] = { 1, 0.1, 0.05 },
    [3] = { 1, 0.1, 0.05 },
}
Text.AGGRO = 2 -- the first kind that is having it
-- The game's abbreviation for hidden health, in the same steps as Text.Short: millions to two places, thousands to one.
Text.STEPS = {
    { breakpoint = 1000000, abbreviation = "m", significandDivisor = 10000, fractionDivisor = 100, abbreviationIsGlobal = false },
    { breakpoint = 1000, abbreviation = "k", significandDivisor = 100, fractionDivisor = 10, abbreviationIsGlobal = false },
}

local function Font()
    for _, name in ipairs(Text.FONTS) do
        if rawget(_G, name) then return name end
    end
    return nil
end

local function Line(host, justify)
    local text = host:CreateFontString(nil, "OVERLAY", Font())
    text:SetJustifyH(justify)
    text:SetWordWrap(false)
    text:SetTextColor(1, 1, 1)
    return text
end

-- The texts on the dress, on a frame of their own above the bar and its lines.
function Text.Make(dress)
    local top = CreateFrame("Frame", nil, dress)
    top:SetAllPoints(dress)
    top:SetFrameLevel(dress.health:GetFrameLevel() + 3)
    local level = Line(top, "LEFT")
    level:SetPoint("LEFT", top, "LEFT", Text.INSET, 0)
    local threat = Line(top, "LEFT")
    threat:SetPoint("LEFT", level, "RIGHT", Text.GAP, 0)
    local value = Line(top, "RIGHT")
    value:SetPoint("RIGHT", top, "RIGHT", -Text.INSET, 0)
    local name = Line(top, "CENTER")
    name:SetPoint("CENTER", top, "CENTER", 0, 0)
    dress.level, dress.threat, dress.value, dress.name = level, threat, value, name
end

-- The name's room for the dress's width (Plate's Fit).
function Text.Fit(dress)
    local width = Plain(dress:GetWidth()) or 0
    dress.name:SetWidth(math.max(width * Text.NAME, 1))
end

function Text.Name(dress, unit)
    local text = Plain(UnitIsPlayer(unit)) and Core.FullName(unit)
    if type(text) ~= "string" then text = ns.Bar.Raw(UnitName, unit) end -- hidden or not: the text takes it
    if type(text) == "nil" then text = "" end
    dress.name:SetText(text)
end

-- The game's colour for a level as it is to you: by difficulty for a unit you can attack, the game's colour for
-- one you cannot.
local function LevelColour(unit, level)
    if Core.Ask(UnitCanAttack, "player", unit) then
        local mine = Core.Ask(UnitLevel, "player")
        local colour = mine and Core.Ask(rawget(_G, "GetRelativeDifficultyColor"), mine, level)
        if type(colour) == "table" and type(colour.r) == "number" then return colour.r, colour.g, colour.b end
    end
    local colour = rawget(_G, "UNIT_LEVEL_NON_ATTACKABLE")
    if type(colour) == "table" and type(colour.r) == "number" then return colour.r, colour.g, colour.b end
    return 1, 1, 1
end

function Text.Level(dress, unit)
    local level = Core.Ask(UnitLevel, unit)
    local text = dress.level
    if type(level) ~= "number" then
        text:SetText("")
    elseif level > 0 then
        text:SetText(level)
        text:SetTextColor(LevelColour(unit, level))
    else
        text:SetText(Text.SKULL)
        text:SetTextColor(1, 1, 1)
    end
end

-- Your threat on the unit, and the glow while you have its aggro. Nothing while you are not on its threat list.
function Text.Threat(dress, unit)
    local text = dress.threat
    local ok, tanking, kind, share = pcall(UnitDetailedThreatSituation, "player", unit)
    if not ok or type(kind) == "nil" or type(share) == "nil" then
        text:SetText("")
        return ns.Bar.Glow(dress, false)
    end
    if not pcall(text.SetFormattedText, text, "%d%%", share) then text:SetText("") end
    local plain = Plain(kind)
    local colour = Text.THREAT[plain] or Text.THREAT[0]
    text:SetTextColor(colour[1], colour[2], colour[3])
    if plain then return ns.Bar.Glow(dress, plain >= Text.AGGRO) end
    ns.Bar.Glow(dress, tanking) -- hidden: the glow takes the game's answer as it is
end

-- A number cut (not rounded) to that many places, without the zeros at its end: 1.25 to one place is "1.2", 2.0 "2".
local function Cut(value, places)
    local scale = 10 ^ places
    local text = ("%." .. places .. "f"):format(math.floor(value * scale) / scale)
    return (text:gsub("%.?0+$", ""))
end

-- A health short: under a thousand as it is, then thousands to one place ("1.2k"), then millions to two ("1.32m").
function Text.Short(health)
    health = math.floor(health)
    if health < 1000 then return tostring(health) end
    if health < 1000000 then return Cut(health / 1000, 1) .. "k" end
    return Cut(health / 1000000, 2) .. "m"
end

-- How much is left, in whole percent: 100 only when full, 1 at least while any is left.
function Text.Percent(now, most)
    if most <= 0 or now >= most then return now > 0 and 100 or 0 end
    if now <= 0 then return 0 end
    return math.max(math.floor(now / most * 100), 1)
end

local steps
-- Hidden health as the game formats it: its abbreviation in our steps (the game's own form where it takes none),
-- the percentage by the game's curve to a hundred.
local function Hidden(text, unit, now)
    local curve = rawget(_G, "CurveConstants") and CurveConstants.ScaleTo100
    local share = curve and ns.Bar.Raw(UnitHealthPercent, unit, true, curve)
    steps = steps or { breakpointData = Text.STEPS }
    local ok, short = pcall(AbbreviateNumbers, now, steps)
    if not ok then ok, short = pcall(AbbreviateNumbers, now) end
    if not ok then return text:SetText("") end
    if type(share) == "nil" or not pcall(text.SetFormattedText, text, "%s | %d%%", short, share) then
        text:SetText(short)
    end
end

function Text.Health(dress, unit)
    local text = dress.value
    local now, most = ns.Bar.Raw(UnitHealth, unit), ns.Bar.Raw(UnitHealthMax, unit)
    if type(now) == "nil" or type(most) == "nil" then return text:SetText("") end
    local plainNow, plainMost = Plain(now), Plain(most)
    if type(plainNow) == "number" and type(plainMost) == "number" then
        return text:SetText(("%s | %d%%"):format(Text.Short(plainNow), Text.Percent(plainNow, plainMost)))
    end
    Hidden(text, unit, now)
end

-- Every text for the unit (or none).
function Text.Set(dress, unit)
    if not unit then
        for _, text in ipairs({ dress.level, dress.threat, dress.value, dress.name }) do text:SetText("") end
        return
    end
    Text.Name(dress, unit)
    Text.Level(dress, unit)
    Text.Threat(dress, unit)
    Text.Health(dress, unit)
end
