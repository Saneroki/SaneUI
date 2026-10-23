local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Text
--  The line inside a plate's bar, left to right, each piece taking room only
--  while it shows:
--    quest    the game's sword (to kill) or sack (to loot) and the count
--             ("0/7") while the unit belongs to a quest in your log with an
--             objective still open (Core.UnitQuest)
--    marker   the raid marker (Marks.lua)
--    level    the unit's level in the game's colour for how hard it is to you
--             (a skull where it is too high to tell)
--    gear     a player's item level ("i32"), once inspected (Core.Inspect)
--    threat   your threat on it while you are on its threat list: grey while
--             low, orange when you are about to take its aggro, red while you
--             have it (and then the bar glows)
--    name     its name: a player's first name and surname
--    health   short ("850", "1.2k", "1.32m") and how much is left ("| 100%")
--  The bar is as wide as the line and its insets (Text.Layout, Plate.Place).
--
--  The line's font is the game's for its plates' names, smaller (Text.SMALLER),
--  the icons as high as it and a little more. A plain text is measured on
--  itself, whole (not as cut by the width it was given), and given a pixel
--  more; one that cannot say (a font string once given a hidden value answers
--  its width hidden) is measured on a ruler of ours, never seen. In a fight
--  the game may hide health, threat and a name from addons (secret values).
--  The texts then take them as they are, formatted by the game: the
--  percentages as numbers, the health by the game's abbreviation in the same
--  steps, the threat in grey (its kind cannot be told), and the glow follows
--  the game's hidden answer (Bar.Glow). Their room is kept as the plain ones
--  had it: health as wide as its most ("1.32m | 100%"), threat as "100%", a
--  hidden name as wide as the last plain one (Text.NAME without one).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Text = {}
ns.Text = Text

-- The game's own font for its plates' names.
Text.FONTS = { "SystemFont_NamePlate_Outlined", "SystemFont_NamePlate", "GameFontHighlightSmall" }
Text.INSET = 3   -- from the bar's ends to the line
Text.PAD = 2     -- over and under the line, inside the bar
Text.GAP = 4     -- between two pieces of the line
Text.NEAR = 1    -- between the quest's icon and its count
Text.SMALLER = 0.72 -- the line's font, a share of the height of the game's font for its plates' names
Text.ICON = 1.2  -- an icon's size, times the font's height
Text.SLACK = 1   -- room given to a text beyond its measured width, so it is never cut short by rounding
Text.NAME = 80   -- the room of a name the game hides, before a plain one was seen
Text.MOST = 180  -- the most room a name takes (cut short beyond it)
Text.GEAR = { 0.75, 0.75, 0.75 } -- the item level's colour
Text.SKULL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t" -- the game's mark for a level too high to tell
-- The game's mouse cursors for a creature to fight and one to loot, as Sane UI shows objectives elsewhere.
Text.QUEST = { kill = "Interface\\CURSOR\\Attack", loot = "Interface\\CURSOR\\LootAll" }
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

-- The line's font: the game's font for its plates' names (its face and outline), smaller, set once on every text
-- of ours, so a change the game makes to its font object later changes none of them.
local font
local function Font()
    if font then return font end
    for _, name in ipairs(Text.FONTS) do
        local object = rawget(_G, name)
        local file, height, flags
        if type(object) == "table" and object.GetFont then file, height, flags = object:GetFont() end
        if type(file) == "string" and type(height) == "number" and height > 0 then
            font = { name = name, file = file, height = math.max(height * Text.SMALLER, 6), flags = flags or "" }
            return font
        end
    end
    font = { height = 10 } -- no font object of the game's here: the template's own
    return font
end

local function Line(host, justify)
    local look = Font()
    local text = host:CreateFontString(nil, "OVERLAY", look.name)
    if look.file then text:SetFont(look.file, look.height, look.flags) end
    text:SetJustifyH(justify)
    text:SetWordWrap(false)
    text:SetTextColor(1, 1, 1)
    return text
end

-- A text's whole width as drawn (not cut by a width it was given); nil where the text answers it hidden.
local function Drawn(text)
    local measure = text.GetUnboundedStringWidth or text.GetStringWidth
    local width = Plain(measure(text))
    return type(width) == "number" and width or nil
end

-- A font string of ours that only measures: never seen (alpha 0), never given a hidden value, on a frame of its own
-- that is always shown (a hidden one may not measure what it was given).
local ruler

-- How wide a plain text is in the line's font, with its slack.
function Text.Width(text)
    ruler:SetText(text)
    return math.ceil(Drawn(ruler) or 0) + Text.SLACK
end

-- How high the bar is: the line's font and its padding over and under it, inside a border of a pixel.
function Text.Height(dress)
    return math.ceil(Font().height) + 2 * Text.PAD + 2 * Core.Pixels(dress, 1)
end

-- How wide a text of the line is as it shows now (plain): measured on itself; on the ruler where it answers hidden
-- (a font string once given a hidden value may answer so ever after).
local function Measure(region, plain)
    local width = Drawn(region)
    if width then return math.ceil(width) + Text.SLACK end
    return Text.Width(plain)
end

-- The texts on the dress, on a frame of their own above the bar and its lines.
function Text.Make(dress)
    local top = CreateFrame("Frame", nil, dress)
    top:SetAllPoints(dress)
    top:SetFrameLevel(dress.health:GetFrameLevel() + 3)
    if not ruler then
        local holder = CreateFrame("Frame", nil, UIParent)
        holder:SetSize(1, 1)
        holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
        holder:SetAlpha(0)
        ruler = Line(holder, "LEFT")
        ruler:SetPoint("LEFT", holder, "LEFT")
        Text.size = math.floor(Font().height * Text.ICON + 0.5)
    end
    local quest = top:CreateTexture(nil, "OVERLAY")
    quest:SetSize(Text.size, Text.size)
    quest:Hide()
    dress.top, dress.quest, dress.count = top, quest, Line(top, "LEFT")
    dress.level, dress.gear, dress.threat = Line(top, "LEFT"), Line(top, "LEFT"), Line(top, "LEFT")
    dress.name, dress.value = Line(top, "LEFT"), Line(top, "LEFT")
    dress.gear:SetTextColor(Text.GEAR[1], Text.GEAR[2], Text.GEAR[3])
    dress.room = {} -- [piece] = its room on the line now; none while it does not show
end

-- A piece's room on the line (nil: it takes none), and the line laid out anew when it changed.
local function Room(dress, piece, width)
    if dress.room[piece] == width then return end
    dress.room[piece] = width
    if not dress.holding then Text.Layout(dress) end
end
Text.Room = Room

-- The pieces of the line in their order: the region, and the key of its room.
local ORDER = { { "quest", "quest" }, { "count", "count" }, { "raid", "raid" }, { "level", "level" }, { "gear", "gear" },
                { "threat", "threat" }, { "name", "name" }, { "value", "value" } }

-- The line laid out from the left, each piece that shows after the last, and the bar as wide as it (Plate.Place).
function Text.Layout(dress)
    local top, room = dress.top, dress.room
    local x, last = Text.INSET, nil
    for _, entry in ipairs(ORDER) do
        local region, width = dress[entry[1]], room[entry[2]]
        if region and width then
            if last then x = x + (last == "quest" and Text.NEAR or Text.GAP) end
            region:ClearAllPoints()
            region:SetPoint("LEFT", top, "LEFT", x, 0)
            -- A text as wide as its room (cut short past it), but the health: as wide as it is (its room is a guess
            -- while the game hides the most health).
            if region.SetWordWrap then region:SetWidth(entry[2] == "value" and 0 or width) end
            x, last = x + width, entry[2]
        end
    end
    dress.want = x + Text.INSET
    ns.Plate.Place(dress)
end

function Text.Name(dress, unit)
    local text = Plain(UnitIsPlayer(unit)) and Core.FullName(unit)
    if type(text) ~= "string" then text = ns.Bar.Raw(UnitName, unit) end -- hidden or not: the text takes it
    if type(text) == "nil" then text = "" end
    dress.name:SetText(text)
    local plain = Plain(text)
    if type(plain) == "string" then
        dress.nameRoom = plain ~= "" and math.min(Measure(dress.name, plain), Text.MOST) or nil
        return Room(dress, "name", dress.nameRoom)
    end
    Room(dress, "name", dress.nameRoom or Text.NAME)
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
    local text, shown = dress.level, nil
    if type(level) ~= "number" then
        text:SetText("")
    elseif level > 0 then
        shown = tostring(level)
        text:SetTextColor(LevelColour(unit, level))
    else
        shown = Text.SKULL
        text:SetTextColor(1, 1, 1)
    end
    if shown then text:SetText(shown) end
    Room(dress, "level", shown and Measure(text, shown) or nil)
end

-- A player's item level ("i32"), as Core's inspections have it (asked for while it has not come); none for
-- creatures, or with the setting off.
function Text.Gear(dress, unit)
    local text, shown = dress.gear, nil
    if (ns.options or {}).gear ~= false and Plain(UnitIsPlayer(unit)) then
        local level = Core.Inspect.Level(unit, Core.Ask(UnitGUID, unit))
        if type(level) == "number" and level > 0 then shown = "i" .. level end
    end
    text:SetText(shown or "")
    Room(dress, "gear", shown and Measure(text, shown) or nil)
    return shown ~= nil
end

-- What is still to do about the unit for a quest: the icon and the count, or none. Kept as it was while the game
-- hides it. None for players, or with the setting off.
function Text.Quest(dress, unit)
    local kind, count = nil, nil
    if (ns.options or {}).quest ~= false and not Plain(UnitIsPlayer(unit)) then
        kind, count = Core.UnitQuest(unit)
        if kind == false then return end
    end
    local icon, text = dress.quest, dress.count
    if kind then icon:SetTexture(Text.QUEST[kind]) end
    icon:SetShown(kind ~= nil)
    count = kind and count or ""
    text:SetText(count)
    Room(dress, "quest", kind and Text.size or nil)
    Room(dress, "count", count ~= "" and Measure(text, count) or nil)
end

-- Your threat on the unit, and the glow while you have its aggro. Nothing while you are not on its threat list.
function Text.Threat(dress, unit)
    local text = dress.threat
    local ok, tanking, kind, share = pcall(UnitDetailedThreatSituation, "player", unit)
    if not ok or type(kind) == "nil" or type(share) == "nil" then
        text:SetText("")
        Room(dress, "threat", nil)
        return ns.Bar.Glow(dress, false)
    end
    Room(dress, "threat", Text.Width("100%"))
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

-- A guess at how the most health of a unit looks short, for its room while the game hides it: about Text.PER_LEVEL a
-- level (a player Text.PLAYER), three times that for an elite, a boss's in millions, each digit an 8 (the widest).
Text.PER_LEVEL, Text.PLAYER = 60, 100
function Text.Guess(unit)
    local level = Core.Ask(UnitLevel, unit)
    local rank = ns.Bar.Rank(unit)
    local most
    if rank == "boss" or (type(level) == "number" and level <= 0) then
        most = 1000000
    else
        level = type(level) == "number" and level or 60
        most = level * (Plain(UnitIsPlayer(unit)) and Text.PLAYER or Text.PER_LEVEL) * (rank and 3 or 1)
    end
    local short = Text.Short(most)
    -- With the places a real one may have ("1.2k", "1.23m"), though the guess is round.
    if not short:find(".", 1, true) then short = short:gsub("k$", ".8k"):gsub("m$", ".88m") end
    return (short:gsub("%d", "8"))
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
    if type(now) == "nil" or type(most) == "nil" then
        text:SetText("")
        return Room(dress, "value", nil)
    end
    local plainNow, plainMost = Plain(now), Plain(most)
    -- Its room: as wide as the most it can show, so the bar does not change width as health goes. The game hides the
    -- health of a plate's unit from addons always, and its most often: the most's width when it says it (kept),
    -- else a guess from the unit's level and rank (Text.Guess).
    if type(plainMost) == "number" then dress.valueRoom = Text.Width(Text.Short(plainMost) .. " | 100%") end
    Room(dress, "value", dress.valueRoom or Text.Width(Text.Guess(unit) .. " | 100%"))
    if type(plainNow) == "number" and type(plainMost) == "number" then
        return text:SetText(("%s | %d%%"):format(Text.Short(plainNow), Text.Percent(plainNow, plainMost)))
    end
    Hidden(text, unit, now)
end

-- Every piece for the unit (or none: a plate taken back keeps nothing of its last unit).
function Text.Set(dress, unit)
    if not unit then
        for _, text in ipairs({ dress.count, dress.level, dress.gear, dress.threat, dress.value, dress.name }) do text:SetText("") end
        dress.quest:Hide()
        dress.raid:Hide()
        dress.nameRoom, dress.valueRoom = nil, nil
        for piece in pairs(dress.room) do dress.room[piece] = nil end
        return
    end
    dress.holding = true -- laid out once, after all of them
    Text.Quest(dress, unit)
    Text.Level(dress, unit)
    Text.Gear(dress, unit)
    Text.Name(dress, unit)
    Text.Threat(dress, unit)
    Text.Health(dress, unit)
    dress.holding = false
    Text.Layout(dress)
end
