local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Text
--  The line inside a unit frame's bar, in a nameplate's font and colours:
--    left     the unit's level, in the game's colour for how hard it is to
--             you (a skull where it is too high to tell), and right of it the
--             raid marker while there is one
--    middle   its name, centred on the bar: a player's first name and
--             surname (Core.FullName), as long as the room between the two
--             sides allows (cut short beyond it)
--    right    its health, short ("850", "1.2k", "1.32m"), and how much is
--             left ("| 100%"); Dead or Offline instead where it is
--
--  The name keeps the middle: it has the bar's width less twice the wider of
--  the two sides, so it never moves off the middle as the sides change. The
--  health's room is as wide as the most it can show ("1.32m | 100%"), so the
--  name does not shift as health goes; while the game hides the most health
--  (a creature's, in a fight), as wide as the last plain one, or a guess.
--  Hidden health is written by the game's own abbreviation, in the same steps,
--  and the percentage by its curve (secret values: shown, never computed).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Raw = ns.UnitBar.Raw -- a game function's answer as it is, hidden or not (Bar.lua, loaded first)
local Text = {}
ns.UnitText = Text

-- The game's font for its plates' names: its face and outline, at Text.SIZE.
Text.FONTS = { "SystemFont_NamePlate_Outlined", "SystemFont_NamePlate", "GameFontHighlightSmall" }
Text.SIZE = 12   -- the font's height in the frame's units (the frame's scale makes it larger or smaller)
Text.INSET = 6   -- from the bar's ends to the line
Text.GAP = 4     -- between two pieces, and around the name
Text.ICON = 1.2  -- the raid marker's size, times the font's height
Text.SLACK = 1   -- room beyond a measured width, so a text is never cut by rounding
Text.WIDEST = 1000 -- a width measured wider than this was not measured (the game not ready yet)
Text.GUESS = 0.6 -- a letter's width, a share of the font's height, while the game cannot measure
Text.SAMPLE = "88.8k | 100%" -- the health's room while the game hides the most health and none was seen
Text.SKULL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t"
Text.MARKS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local ROWS, COLUMNS = rawget(_G, "RAID_TARGET_TEXTURE_ROWS") or 4, rawget(_G, "RAID_TARGET_TEXTURE_COLUMNS") or 4
-- The game's abbreviation for hidden health, in the steps of Text.Short: millions to two places, thousands to one.
Text.STEPS = {
    { breakpoint = 1000000, abbreviation = "m", significandDivisor = 10000, fractionDivisor = 100, abbreviationIsGlobal = false },
    { breakpoint = 1000, abbreviation = "k", significandDivisor = 100, fractionDivisor = 10, abbreviationIsGlobal = false },
}
Text.DEAD = Core.Word("DEAD", "Dead")
Text.OFFLINE = Core.Word("PLAYER_OFFLINE", "Offline")

local font -- { name, file, flags }: the game's font object, read once
local function Font()
    if font then return font end
    for _, name in ipairs(Text.FONTS) do
        local object = rawget(_G, name)
        local file, _, flags
        if type(object) == "table" and object.GetFont then file, _, flags = object:GetFont() end
        if type(file) == "string" then
            font = { name = name, file = file, flags = flags or "" }
            return font
        end
    end
    font = {} -- no font object of the game's here: the template's own
    return font
end

local function Line(host, justify)
    local look = Font()
    local text = host:CreateFontString(nil, "OVERLAY", look.name or "GameFontHighlightSmall")
    if look.file then text:SetFont(look.file, Text.SIZE, look.flags) end
    text:SetJustifyH(justify)
    text:SetWordWrap(false)
    text:SetTextColor(1, 1, 1)
    return text
end

-- A text's whole width as drawn; nil where it answers hidden, or absurd (the game not set up yet).
local function Drawn(text)
    local measure = text.GetUnboundedStringWidth or text.GetStringWidth
    local width = Plain(measure(text))
    if type(width) ~= "number" or width ~= width or width < 0 or width > Text.WIDEST then return nil end
    return width
end

-- A font string of ours that only measures plain texts: never seen, on a frame of its own that is always shown.
local ruler
function Text.Width(plain)
    if not ruler then
        local holder = CreateFrame("Frame", nil, UIParent)
        holder:SetSize(1, 1)
        holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
        holder:SetAlpha(0)
        ruler = Line(holder, "LEFT")
        ruler:SetPoint("LEFT", holder, "LEFT")
    end
    ruler:SetText(plain)
    local width = Drawn(ruler) or #plain * Text.SIZE * Text.GUESS
    return math.ceil(width) + Text.SLACK
end

function Text.Make(face)
    local top = CreateFrame("Frame", nil, face)
    top:SetAllPoints(face)
    top:SetFrameLevel(face.health:GetFrameLevel() + 3)
    face.level, face.name, face.value = Line(top, "LEFT"), Line(top, "CENTER"), Line(top, "RIGHT")
    face.level:SetPoint("LEFT", top, "LEFT", Text.INSET, 0)
    face.value:SetPoint("RIGHT", top, "RIGHT", -Text.INSET, 0)
    face.name:SetPoint("CENTER", top, "CENTER", 0, 0)
    local raid = top:CreateTexture(nil, "OVERLAY")
    raid:SetTexture(Text.MARKS)
    local size = math.floor(Text.SIZE * Text.ICON + 0.5)
    raid:SetSize(size, size)
    raid:SetPoint("LEFT", face.level, "RIGHT", Text.GAP, 0)
    raid:Hide()
    face.raid, face.top, face.room = raid, top, { left = 0, right = 0 }
end

-- The name's room: the bar's width less twice the wider side, so it stays in the middle.
function Text.Layout(face)
    local side = math.max(face.room.left, face.room.right) + Text.GAP
    local width = (Plain(face:GetWidth()) or 0) - 2 * side
    face.name:SetWidth(math.max(width, 1))
end

local function Side(face, key, width)
    if face.room[key] == width then return end
    face.room[key] = width
    Text.Layout(face)
end

-- The left side: the level, and the raid marker after it while there is one.
local function Left(face)
    local width = Text.INSET + (face.levelRoom or 0)
    if face.raid:IsShown() then width = width + Text.GAP + face.raid:GetWidth() end
    Side(face, "left", width)
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

function Text.Level(face, unit)
    local level, text, shown = Core.Ask(UnitLevel, unit), face.level, nil
    if type(level) == "number" and level > 0 then
        shown = tostring(level)
        text:SetTextColor(LevelColour(unit, level))
    elseif type(level) == "number" then
        shown = Text.SKULL
        text:SetTextColor(1, 1, 1)
    end
    text:SetText(shown or "")
    local width = shown and Drawn(text)
    face.levelRoom = shown and (width and math.ceil(width) + Text.SLACK or Text.Width(shown)) or 0
    Left(face)
end

-- The raid marker: its number may be hidden; the texture takes it as it is, and only whether there is one is looked at.
function Text.Raid(face, unit)
    local index = Raw(GetRaidTargetIndex, unit)
    local on = type(index) ~= "nil"
    if on then face.raid:SetSpriteSheetCell(index, ROWS, COLUMNS) end
    face.raid:SetShown(on)
    Left(face)
end

-- The name: a player's first name and surname; another unit's name as the game gives it, hidden or not.
function Text.Name(face, unit, instead)
    local text = instead or (Core.Ask(UnitIsPlayer, unit) and Core.FullName(unit))
    if type(text) ~= "string" then text = Raw(UnitName, unit) end
    if type(text) == "nil" then text = "" end
    face.name:SetText(text)
end

-- A number cut (not rounded) to that many places, without the zeros at its end: 1.25 to one place is "1.2".
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
-- Hidden health as the game formats it: its abbreviation in our steps, the percentage by its curve to a hundred.
local function Hidden(text, unit, now)
    local curves = rawget(_G, "CurveConstants")
    local share = curves and curves.ScaleTo100 and Raw(rawget(_G, "UnitHealthPercent"), unit, true, curves.ScaleTo100)
    steps = steps or { breakpointData = Text.STEPS }
    local ok, short = pcall(AbbreviateNumbers, now, steps)
    if not ok then ok, short = pcall(AbbreviateNumbers, now) end
    if not ok then return text:SetText("") end
    if type(share) == "nil" or not pcall(text.SetFormattedText, text, "%s | %d%%", short, share) then
        text:SetText(short)
    end
end

-- Health on the right, its room as wide as the most it can show; Dead or Offline where the unit is so.
function Text.Health(face, unit)
    local text = face.value
    local word = nil
    if Core.Ask(UnitIsPlayer, unit) and Core.Ask(UnitIsConnected, unit) == false then
        word = Text.OFFLINE
    elseif Core.Ask(UnitIsDeadOrGhost, unit) then
        word = Text.DEAD
    end
    local now, most = Raw(UnitHealth, unit), Raw(UnitHealthMax, unit)
    local plainNow, plainMost = Plain(now), Plain(most)
    if type(plainMost) == "number" then face.valueRoom = Text.Width(Text.Short(plainMost) .. " | 100%") end
    local room = face.valueRoom or Text.Width(Text.SAMPLE)
    if word then
        text:SetText(word)
        room = math.max(room, Text.Width(word))
    elseif type(now) == "nil" or type(most) == "nil" then
        text:SetText("")
    elseif type(plainNow) == "number" and type(plainMost) == "number" then
        text:SetText(("%s | %d%%"):format(Text.Short(plainNow), Text.Percent(plainNow, plainMost)))
    else
        Hidden(text, unit, now)
    end
    Side(face, "right", Text.INSET + room)
end

-- Every piece for the unit; instead: a name in its place (a sample in Edit Mode).
function Text.Set(face, unit, instead)
    Text.Level(face, unit)
    Text.Raid(face, unit)
    Text.Name(face, unit, instead)
    Text.Health(face, unit)
end
