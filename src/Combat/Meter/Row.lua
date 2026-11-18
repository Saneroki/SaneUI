local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Meter - Row
--  One character on the meter: a line with their class's icon, level, item level
--  and name, and under it a bar for each thing shown, left to right, in its own
--  colour, its name in it and its numbers at its right end. A bar at 0 is not drawn
--  (Row.Has): the meter leaves out what says nothing. Nothing else: no background,
--  and nothing takes the mouse but, while the mouse is on the window, the line with
--  the name for a right click (Controls.Character), only as far as its words reach:
--  past the name, between the lines and on the bars clicks go through to the world.
--
--  A bar's length is the character's total against the highest of the fight; threat's,
--  while there is a mob, their share of it, as the game counts aggro.
--  The numbers go to the bars and words as the game gave them: in a fight they are
--  hidden, and only the game's own functions may touch them.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Row = {}
ns.MeterRow = Row

Row.LINE = 15    -- the line with the name
Row.BAR = 13     -- a bar
Row.GAP = 5      -- under a character
Row.ICON = 13    -- the class's icon
Row.LEVEL = 16   -- the room for the level
Row.ITEM = 22    -- the room for the item level
Row.TEXT = 3     -- the words in a bar from its ends
Row.NAME = Row.ICON + 3 + Row.LEVEL + Row.ITEM + 2 -- where the name begins on its line
Row.ALPHA = 0.42 -- a bar's fill: subtle, the world still shows through
Row.FONT = "NumberFontNormalSmall" -- the game's own meter writes in this family: outlined, read over anything
Row.FILL = "Interface\\Buttons\\WHITE8X8"
Row.COLOURS = {
    threat = { 0.85, 0.27, 0.22 },
    damage = { 0.90, 0.58, 0.18 },
    healing = { 0.26, 0.76, 0.36 },
    interrupts = { 0.32, 0.55, 0.95 },
}
Row.WORDS = "%s/s  %s"    -- per second, the whole fight
Row.SHARE = "%d%%"        -- a share of a mob's threat, its numbers hidden
Row.NONE = "-"            -- an item level nobody could read yet

-- How high a character stands with that many bars.
function Row.Height(bars)
    return Row.LINE + bars * Row.BAR + Row.GAP
end

-- A number as the game gave it, 0 for none. Hidden, it may not be asked whether it is there: only its type tells.
local function Given(number)
    if type(number) == "nil" then return 0 end
    return number
end

-- The game's short words for a number, hidden or not.
local function Short(number)
    return AbbreviateLargeNumbers(Given(number))
end

-- Whether a number says something: one the game hides (in a fight) may not be asked what it is, so it does; a plain
-- one above 0.
local function Some(number)
    if Core.Secret(number) then return true end
    return type(number) == "number" and number > 0
end

-- Whether that character's bar of that kind has something to show, in a read fight (Read.Fight): a number above 0;
-- threat also a share of the mob while there is one. In a fight, where the game hides its numbers, whoever its list
-- holds of that kind.
function Row.Has(read, person, kind)
    local entry = ns.MeterRead.Entry(read, kind, person.guid)
    if not entry then return false end
    if kind == "threat" and Some(entry.share) then return true end
    return Some(entry.total)
end

local function Bar(row, index)
    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetStatusBarTexture(Row.FILL)
    bar:SetPoint("TOPLEFT", 0, -Row.LINE - (index - 1) * Row.BAR)
    bar:SetPoint("TOPRIGHT", 0, -Row.LINE - (index - 1) * Row.BAR)
    bar:SetHeight(Row.BAR - 1)
    bar.label = bar:CreateFontString(nil, "OVERLAY", Row.FONT)
    bar.label:SetPoint("LEFT", Row.TEXT, 0)
    bar.value = bar:CreateFontString(nil, "OVERLAY", Row.FONT)
    bar.value:SetPoint("RIGHT", -Row.TEXT, 0)
    row.bars[index] = bar
    return bar
end

local function Picked(line)
    ns.MeterControls.Character(line, line.person)
end

local function Make(row)
    row.bars = {}
    row.line = CreateFrame("Button", nil, row)
    row.line:SetPoint("TOPLEFT")
    row.line:SetSize(Row.NAME, Row.LINE) -- as wide as its words: Reach
    row.line:RegisterForClicks("RightButtonUp")
    row.line:SetScript("OnClick", ns.Guard(Picked))
    row.line:Hide()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(Row.ICON, Row.ICON)
    row.icon:SetPoint("TOPLEFT", 0, -1)
    row.level = row:CreateFontString(nil, "OVERLAY", Row.FONT)
    row.level:SetPoint("TOPLEFT", Row.ICON + 3, -2)
    row.level:SetWidth(Row.LEVEL)
    row.level:SetJustifyH("LEFT")
    row.item = row:CreateFontString(nil, "OVERLAY", Row.FONT)
    row.item:SetPoint("TOPLEFT", row.level, "TOPRIGHT", 0, 0)
    row.item:SetWidth(Row.ITEM)
    row.item:SetJustifyH("LEFT")
    row.item:SetTextColor(0.75, 0.75, 0.75)
    row.name = row:CreateFontString(nil, "OVERLAY", Row.FONT)
    row.name:SetPoint("TOPLEFT", row.item, "TOPRIGHT", 2, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
end

local function Class(row, class)
    local atlas = class and rawget(_G, "GetClassAtlas") and GetClassAtlas(class:lower())
    row.icon:SetShown(atlas ~= nil)
    if atlas then row.icon:SetAtlas(atlas) end
    local colour = class and rawget(_G, "RAID_CLASS_COLORS") and RAID_CLASS_COLORS[class]
    if colour then return row.name:SetTextColor(colour.r, colour.g, colour.b) end
    row.name:SetTextColor(1, 1, 1)
end

-- A number that may be hidden, for the bar's length; none of it stands as one.
local function Whole(number)
    if Core.Secret(number) then return number end
    return number and number > 0 and number or 1
end

local function Rated(text, entry)
    if pcall(text.SetFormattedText, text, Row.WORDS, Short(entry.rate), Short(entry.total)) then return end
    text:SetText(Short(entry.total))
end

local function Threat(bar, entry, top)
    local share = entry and entry.share
    if type(share) ~= "nil" then
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(share)
    else
        bar:SetMinMaxValues(0, Whole(top))
        bar:SetValue(Given(entry and entry.total))
    end
    if not entry then return bar.value:SetText("0") end
    if Core.Secret(share) and entry.total == 0 then
        if not pcall(bar.value.SetFormattedText, bar.value, Row.SHARE, share) then bar.value:SetText("") end
        return
    end
    Rated(bar.value, entry)
end

local function Amount(bar, kind, entry, top)
    bar:SetMinMaxValues(0, Whole(top))
    bar:SetValue(Given(entry and entry.total))
    if not entry then return bar.value:SetText("0") end
    if kind == "interrupts" then return bar.value:SetText(Short(entry.total)) end
    Rated(bar.value, entry)
end

-- How far the line's words reach from its left: the icon, level and item level, and the name as far as it shows
-- (wide: the row's width, where known; room: what stays free at its right end).
local function Reach(row, room, wide)
    local name = row.name
    local text = name.GetUnboundedStringWidth and name:GetUnboundedStringWidth() or name:GetStringWidth() or 0
    local reach = Row.NAME + text
    if wide and wide > room then reach = math.min(reach, wide - room) end
    return math.max(reach, Row.ICON)
end

-- That character's line and a bar for each of kinds, from a read fight (Read.Fight). room: what stays free at the
-- line's right end (the buttons stand there on the first line); live: the mouse is on the window, the line takes a
-- right click; wide: the row's width. row.reach: how far its words reach, all of the line that takes the mouse.
function Row.Draw(row, person, read, kinds, room, live, wide)
    if not row.bars then Make(row) end
    row.line.person = person
    row.line:SetShown(live and true or false)
    Class(row, person.class)
    row.level:SetText(person.level or "")
    row.item:SetText(person.item or Row.NONE)
    row.name:SetText(person.name)
    if row.room ~= room then
        row.room = room
        row.name:SetPoint("RIGHT", row, "TOPRIGHT", -room, -Row.LINE / 2)
    end
    row.reach = Reach(row, room, wide)
    row.line:SetWidth(row.reach)
    for index, kind in ipairs(kinds) do
        local bar = row.bars[index] or Bar(row, index)
        local colour = Row.COLOURS[kind]
        bar:SetStatusBarColor(colour[1], colour[2], colour[3], Row.ALPHA)
        bar.label:SetText(ns.TEXT.meterKinds[kind])
        local entry = ns.MeterRead.Entry(read, kind, person.guid)
        if kind == "threat" then Threat(bar, entry, read.top.threat) else Amount(bar, kind, entry, read.top[kind]) end
        bar:Show()
    end
    for index = #kinds + 1, #row.bars do row.bars[index]:Hide() end
end
