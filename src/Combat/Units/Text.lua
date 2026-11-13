local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Text
--  The line inside a unit frame's bar, in a nameplate's font and colours:
--    left     the unit's level, in the game's colour for how hard it is to
--             you (a skull where it is too high to tell), the raid marker while
--             there is one; then the name: a player's first name and surname
--             (Core.FullName), as long as the room up to the health allows (cut
--             short beyond it); none on your own frame
--    right    its health, short ("850", "1.2k", "1.32m"), and how much is
--             left ("| 100%"); Dead or Offline instead where it is
--  in each power bar under it, at its left, the power as the health is
--  written ("3.2k | 85%", in a smaller size); in the row under them (your
--  target's target, your focus's target, your pet) its unit's name alone, in
--  its middle; and in your pet's power under that, the power again.
--
--  The health's room is as wide as the most it can show ("1.32m | 100%"), so
--  the name's does not change as health goes, measured once for that most (the
--  words every frame may show, once for all); while the game hides the most
--  health (a creature's, in a fight), as wide as the last plain one, or a guess.
--  A group's frame shows how much is left alone ("85%": face.compact), and
--  nothing where it is too narrow for even that (face.bare), so the name has
--  all the room; Dead and Offline it says all the same. It also keeps its words
--  closer to the bar's ends and to each other (Text.MakeLine's inset and gap).
--
--  The left side is a line of anchors, each piece after the last; a raid marker
--  that is not there is as wide as nothing. Over all of it, at its left, floats
--  the type icon of a dispellable aura (Core's HealthMarks.lua).
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
Text.SMALL = 9   -- in a power bar
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
Text.Font = Font -- for a field in the frames' look (LookOut.lua)

local function Line(host, justify, size)
    local look = Font()
    local text = host:CreateFontString(nil, "OVERLAY", look.name or "GameFontHighlightSmall")
    if look.file then text:SetFont(look.file, size or Text.SIZE, look.flags) end
    text:SetJustifyH(justify)
    text:SetWordWrap(false)
    text:SetTextColor(1, 1, 1)
    return text
end
Text.Line = Line

-- A frame of its own on a bar, over it, for its words: they show and go with it.
function Text.Over(bar)
    local over = CreateFrame("Frame", nil, bar)
    over:SetAllPoints(bar)
    over:SetFrameLevel(bar:GetFrameLevel() + 3)
    return over
end

-- A text's whole width as drawn; nil where it answers hidden, or absurd (the game not set up yet).
local function Drawn(text)
    local measure = text.GetUnboundedStringWidth or text.GetStringWidth
    local width = Plain(measure(text))
    if type(width) ~= "number" or width ~= width or width <= 0 or width > Text.WIDEST then return nil end
    return width
end

-- A font string of ours that only measures plain texts: never seen, on a frame of its own that is always shown. The
-- width, and whether it was measured (a guess by the letters while the game cannot measure).
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
    local width = Drawn(ruler)
    if width then return math.ceil(width) + Text.SLACK, true end
    return math.ceil(#plain * Text.SIZE * Text.GUESS) + Text.SLACK, false
end

-- The words every frame may show ("100%", Dead, Offline, the sample), each measured once the game can measure it.
local fixed = {}
local function Fixed(plain)
    local width = fixed[plain]
    if width then return width end
    local measured
    width, measured = Text.Width(plain)
    if measured then fixed[plain] = width end
    return width
end

-- The line itself: the level, the raid marker, the name and the health, on a frame over the health bar; inset from the
-- bar's ends and gap between two pieces where it wants other than every frame's.
function Text.MakeLine(face, inset, gap)
    inset, gap = inset or Text.INSET, gap or Text.GAP
    face.inset, face.gap = inset, gap
    local top = CreateFrame("Frame", nil, face)
    top:SetAllPoints(face)
    top:SetFrameLevel(face.health:GetFrameLevel() + 3)
    face.level, face.name, face.value = Line(top, "LEFT"), Line(top, "LEFT"), Line(top, "RIGHT")
    face.marks:Place("LEFT", top, "LEFT", inset, 0)
    face.level:SetPoint("LEFT", top, "LEFT", inset, 0)
    face.value:SetPoint("RIGHT", top, "RIGHT", -inset, 0)
    local raid = top:CreateTexture(nil, "OVERLAY")
    raid:SetTexture(Text.MARKS)
    local size = math.floor(Text.SIZE * Text.ICON + 0.5)
    raid:SetSize(Core.HealthMarks.NONE, size)
    raid:Hide()
    face.raid, face.top, face.room, face.markSize = raid, top, { right = 0 }, size
    Text.Mark(face, nil)
end

function Text.Make(face)
    Text.MakeLine(face)
    -- A power's words on its bar's left (Saneroki, 2026-11-07), under the level, clear of the health's on the right.
    for _, power in ipairs({ face.powers[1], face.powers[2], face.rowPower }) do
        power.value = Line(Text.Over(power), "LEFT", Text.SMALL)
        power.value:SetPoint("LEFT", power, "LEFT", Text.INSET - 1, 0)
    end
    face.rowName = Line(Text.Over(face.row), "CENTER")
    face.rowName:SetPoint("LEFT", face.row, "LEFT", Text.INSET - 1, 0)
    face.rowName:SetPoint("RIGHT", face.row, "RIGHT", 1 - Text.INSET, 0)
end

-- The name's room: from the raid marker's right to the health's left.
function Text.Layout(face)
    local right, gap = face.room.right, face.gap
    face.name:ClearAllPoints()
    face.name:SetPoint("LEFT", face.raid, "RIGHT", gap, 0)
    face.name:SetPoint("RIGHT", face.top, "RIGHT", -(right + gap), 0)
    if face.roomed then face.roomed(face, right) end
end

local function Side(face, key, width)
    if face.room[key] == width then return end
    face.room[key] = width
    Text.Layout(face)
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
end

-- The raid marker of that number (nil: none): it may be hidden; the texture takes it as it is, and only whether there
-- is one is looked at.
function Text.Mark(face, index)
    local on = type(index) ~= "nil"
    local raid = face.raid
    if on then raid:SetSpriteSheetCell(index, ROWS, COLUMNS) end
    raid:SetShown(on)
    raid:SetWidth(on and face.markSize or Core.HealthMarks.NONE)
    raid:ClearAllPoints()
    raid:SetPoint("LEFT", face.level, "RIGHT", on and face.gap or 0, 0)
end

function Text.Raid(face, unit)
    Text.Mark(face, Raw(GetRaidTargetIndex, unit))
end

-- A unit's name: a player's first name and surname; another unit's as the game gives it, hidden or not.
local function NameOf(unit)
    local text = Core.Ask(UnitIsPlayer, unit) and Core.FullName(unit)
    if type(text) ~= "string" then text = Raw(UnitName, unit) end
    if type(text) == "nil" then text = "" end
    return text
end

-- The frame's name (none on your own: face.noName); instead: a name in its place (a sample in Edit Mode).
function Text.Name(face, unit, instead)
    if face.noName then return face.name:SetText("") end
    face.name:SetText(instead or NameOf(unit))
end

-- The row's name, its unit's (or instead).
function Text.Row(face, unit, instead)
    face.rowName:SetText(instead or NameOf(unit))
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
-- A hidden value as the game formats it: its abbreviation in our steps, and the share the game gives by its curve to
-- a hundred (share: the game's function for it, and what it takes before the curve); the share alone where compact.
local function Hidden(text, compact, now, share, ...)
    local curves = rawget(_G, "CurveConstants")
    local count = select("#", ...)
    local args = { ... }
    args[count + 1] = curves and curves.ScaleTo100
    share = args[count + 1] and Raw(share, unpack(args, 1, count + 1))
    if compact and type(share) ~= "nil" and pcall(text.SetFormattedText, text, "%d%%", share) then return end
    steps = steps or { breakpointData = Text.STEPS }
    local ok, short = pcall(AbbreviateNumbers, now, steps)
    if not ok then ok, short = pcall(AbbreviateNumbers, now) end
    if not ok then return text:SetText("") end
    if type(share) == "nil" or not pcall(text.SetFormattedText, text, "%s | %d%%", short, share) then
        text:SetText(short)
    end
end

-- The health's room on this face: the widest it can be written with that most ("1.32m | 100%"), measured again only
-- for another most (what was guessed is not kept), or "100%" where compact; while the most is hidden (nil), as wide as
-- the last plain one, or the sample; nothing on a bare face.
local function Room(face, most)
    if face.bare then return 0 end
    if face.compact then return Fixed("100%") end
    if type(most) == "number" and face.valueMost ~= most then
        local width, measured = Text.Width(Text.Short(most) .. " | 100%")
        face.valueRoom, face.valueMost = width, measured and most or nil
    end
    return face.valueRoom or Fixed(Text.SAMPLE)
end

-- Plain health in its words.
local function Written(face, now, most)
    if face.bare then return "" end
    if face.compact then return ("%d%%"):format(Text.Percent(now, most)) end
    return ("%s | %d%%"):format(Text.Short(now), Text.Percent(now, most))
end

-- No words on the right: something else stands there, that wide.
local function Unwritten(face)
    face.value:SetText("")
    Side(face, "right", face.inset + face.noHealth)
end

-- Health on the right, its room as wide as the most it can show; Dead or Offline where the unit is so. None on a
-- face that takes the room for something else (face.noHealth).
function Text.Health(face, unit)
    if face.noHealth then return Unwritten(face) end
    local text = face.value
    local word = nil
    if Core.Ask(UnitIsPlayer, unit) and Core.Ask(UnitIsConnected, unit) == false then
        word = Text.OFFLINE
    elseif Core.Ask(UnitIsDeadOrGhost, unit) then
        word = Text.DEAD
    end
    local now, most = Raw(UnitHealth, unit), Raw(UnitHealthMax, unit)
    local plainNow, plainMost = Plain(now), Plain(most)
    local room = Room(face, plainMost)
    if word then
        text:SetText(word)
        room = math.max(room, Fixed(word))
    elseif face.bare or type(now) == "nil" or type(most) == "nil" then
        text:SetText("")
    elseif type(plainNow) == "number" and type(plainMost) == "number" then
        text:SetText(Written(face, plainNow, plainMost))
    else
        Hidden(text, face.compact, now, rawget(_G, "UnitHealthPercent"), unit, true)
    end
    Side(face, "right", face.inset + room)
end

-- Made-up health in the same words (a sample): now of most, or a word instead.
function Text.Sample(face, now, most, word)
    if face.noHealth then return Unwritten(face) end
    local room = Room(face, most)
    if word then room = math.max(room, Fixed(word)) end
    face.value:SetText(word or Written(face, now, most))
    Side(face, "right", face.inset + room)
end

-- A power's words on its bar: "3.2k | 85%"; none for an empty one.
local function PowerWords(text, unit, kind)
    local now, most = ns.UnitBar.Read(unit, kind)
    local plainNow, plainMost = Plain(now), Plain(most)
    if type(now) == "nil" or type(most) == "nil" or plainMost == 0 then
        text:SetText("")
    elseif type(plainNow) == "number" and type(plainMost) == "number" then
        text:SetText(("%s | %d%%"):format(Text.Short(plainNow), Text.Percent(plainNow, plainMost)))
    else
        Hidden(text, false, now, rawget(_G, "UnitPowerPercent"), unit, kind.type, false)
    end
end

-- Each power's words, as Bar.Powers read them (kinds).
function Text.Powers(face, unit, kinds)
    for index, kind in ipairs(kinds) do PowerWords(face.powers[index].value, unit, kind) end
end

-- The row's power's words, as Bar.RowPower read it (kind; none on a row without).
function Text.RowPower(face, unit, kind)
    if kind then PowerWords(face.rowPower.value, unit, kind) end
end

-- Every piece for the unit; instead: a name in its place (a sample in Edit Mode).
function Text.Set(face, unit, instead)
    Text.Level(face, unit)
    Text.Raid(face, unit)
    Text.Name(face, unit, instead)
    Text.Health(face, unit)
end
