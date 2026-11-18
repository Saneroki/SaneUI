local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Meter
--  The threat and damage meter, a window of Core's on the screen, its place and size
--  kept; at first right of the quest log's first place at the very top of the screen.
--  Never on or over a full screen (Abilities', the map's, any): out of sight while one is up (Cover, Core's
--  Edge.Watch).
--
--  The list of your party or raid, you on top (Row.lua), as many as fit whole: the mouse
--  wheel over the window takes the others a character at a time under your own line,
--  which stays. A character has the bars the ticks say, or their own (Shows.lua), so rows
--  differ in height. Sorted by what the flyout says (Read.ORDERS); in a fight, where the
--  game hides the numbers, by the places on its own list, and threat not at all on a boss.
--  Nothing at 0 (Bars): a bar whose number is 0 is not drawn, and a character with no bar
--  left, your own line too, is not on the list; in a fight a bar stands for whoever the
--  game's list holds of that kind, as its numbers may not be asked what they are.
--
--  Hide outside combat and Hide when not in group take it out of sight (Seen), but in
--  Edit Mode and with a saved fight loaded. With Show on mouseover
--  the window stays there empty, so the mouse coming onto its place brings it back;
--  without, it is hidden whole.
--
--  There is nothing else to it: no title bar, no background, and a click anywhere on
--  it goes through to the world, but on what stands there to be clicked. Only while the
--  mouse is on it: the buttons at the right end of the first line (Controls.lua), each
--  name as far as its words reach (a right click there: that character's flyout), the
--  first one dragging the window (Grab), and its corner's grip sizing it (Core's grip =
--  "hover"); the wheel scrolls a list longer than the window. Edit Mode's box moves and
--  sizes it too. Lock window
--  (the cog's, and on the page Combat) holds it: then neither the line nor a grip is
--  there to move or size it, but Edit Mode's box still is, as Edit Mode arranges the
--  game's own meter (Free).
--
--  In the screen's top half the list hangs from the window's top and grows down, in the
--  bottom half it stands on the window's bottom and grows up.
--
--  The game gathers these numbers for its own meter (C_DamageMeter, Read.lua), so its
--  setting is on and its window out of sight while ours is on (Hold); ours or the
--  game's, never both. Nothing runs at rest: a look every Meter.EVERY seconds in a fight,
--  or while somebody's item level is still to be asked for (Core.Inspect), and at rest
--  only when the game says something changed. The fight is the events' (Fights.Fighting):
--  as the game tells of it its lockdown has not begun.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Row = ns.MeterRow
local Controls = ns.MeterControls
local Shows = ns.MeterShows
local Meter = {}
ns.Meter = Meter

Meter.WIDTH, Meter.HEIGHT = 260, 400 -- its first size
Meter.LEAST_WIDTH, Meter.LEAST_HEIGHT = 170, 60 -- its least
Meter.QUEST_LOG = 320       -- the quest log's first width: it stands at the top left corner, the meter right of it
Meter.EVERY = 0.5           -- seconds between two looks in a fight
Meter.ASK = 4               -- out of a fight, looks between two questions for an item level
Meter.MARGIN = 6            -- how far around the window the mouse still counts as on it
Meter.LINGER = 0.3          -- seconds the buttons stay after the mouse left
Meter.CVAR = "damageMeterEnabled" -- the game's meter's switch

local FIRST = { point = "TOPLEFT", x = Meter.QUEST_LOG, y = 0, width = Meter.WIDTH, height = Meter.HEIGHT }

local frame, handle, hover, watch
local block, mine, box, view -- what holds the rows, your own, the list of the others
local shown = {}             -- [person] = their bars, this round
local worth = {}             -- [person] = what the list is sorted by, this round
local read                   -- the fight read last
local leader                 -- who stands on the first line of the list: without your own line, the buttons stand there
local covered = false        -- Combat's full screen is up: the meter is out of sight meanwhile
local line                   -- what the list holds, as guids and bars in order: drawn anew only when that changed
local first = 1              -- the first of the list that shows: the wheel moves it
local stale                  -- something changed while out of sight
local hovered                -- the mouse is on it
local rest = 0               -- looks out of a fight since the last question
local lent, away             -- the game's window lent to a hidden frame; that frame

local Refresh

local function Order()
    for _, each in ipairs(ns.MeterRead.ORDERS) do
        if each.key == ns.options.meterOrder then return each end
    end
    return ns.MeterRead.ORDERS[1]
end

-- What to read of the game: the kinds anybody has, and the one the list is sorted by, as a rate if it goes by that.
local function Types()
    local types = {}
    for kind in pairs(Shows.Wanted()) do
        local names = ns.MeterRead.TYPES[kind]
        if names then types[kind] = names.total end
    end
    local order = Order()
    local names = ns.MeterRead.TYPES[order.kind]
    if names then types[order.kind] = names[order.field] or names.total end
    return types
end

-- What sorts a character: their number; in a fight, where it is hidden, their place on the game's list, and whoever
-- is not on it after the last.
local function Worth(person, order)
    local numbers = read.numbers[person.guid]
    local entry = numbers and numbers[order.kind]
    local value = entry and Core.Plain(entry[order.field])
    if value then return value end
    if not read.hidden then return 0 end
    local ranks = read.rank[order.kind]
    return -(ranks and ranks[person.guid] or #read.people + 1)
end

local function Better(a, b)
    if worth[a] ~= worth[b] then return worth[a] > worth[b] end
    return a.name < b.name
end

-- The others, sorted, and you apart while My self on top is ticked.
local function Sorted()
    local order, list, me = Order(), {}, nil
    wipe(worth)
    for _, person in ipairs(read.people) do
        if person.me and ns.options.meterMine then
            me = person
        else
            worth[person] = Worth(person, order)
            list[#list + 1] = person
        end
    end
    table.sort(list, Better)
    return list, me
end

-- The first line's room at its right end while the buttons stand there: the name stops before them.
local function Room(first)
    return first and hovered and Controls.WIDTH or 0
end

-- A character's bars that have something to show: theirs (Shows.lua), none at 0 (Row.Has).
local function Bars(person)
    local bars = {}
    for _, kind in ipairs(Shows.Of(person)) do
        if Row.Has(read, person, kind) then bars[#bars + 1] = kind end
    end
    return bars
end

-- The first line drags the window, as far as the words on it reach (reach; nil: nobody stands there), and only while
-- the mouse is on the window: the rest of it lets clicks through.
local function Grab(reach)
    local drag = frame.drag
    if reach ~= nil then drag.reach = reach end
    if drag.person == nil then drag.reach = nil end
    if drag.reach then drag:SetWidth(drag.reach) end
    drag:SetShown((hovered and drag.reach ~= nil) and true or false)
end

local function Draw(row, person)
    Row.Draw(row, person, read, shown[person] or Bars(person), Room(person == leader), hovered, block:GetWidth())
    if person == leader then Grab(row.reach) end
end

-- How high a row of the list stands.
local function Extent(person)
    return Row.Height(#(shown[person] or Bars(person)))
end

-- How many of the list fit whole from its first shown on, and how high they stand. Room left at the list's end
-- takes the first shown back up, so a window made larger shows no gap under the last.
local function Fit(list, room)
    first = math.max(1, math.min(first, #list))
    local used, count = 0, 0
    for index = first, #list do
        local height = Extent(list[index])
        if used + height > room then break end
        used, count = used + height, count + 1
    end
    while first > 1 and first + count > #list do
        local height = Extent(list[first - 1])
        if used + height > room then break end
        first, used, count = first - 1, used + height, count + 1
    end
    return count, used
end

-- Who has something to show, each with their bars (shown), and you, if you have.
local function Listed(list, me)
    wipe(shown)
    local kept = {}
    for _, person in ipairs(list) do
        local bars = Bars(person)
        if #bars > 0 then
            shown[person] = bars
            kept[#kept + 1] = person
        end
    end
    if me then
        local bars = Bars(me)
        if #bars == 0 then return kept, nil end
        shown[me] = bars
    end
    return kept, me
end

-- The list in the window: whole rows, so nobody stands half out of it, your own line first.
local function Lay(list, me)
    local top = 0
    if me then
        top = Row.Height(#shown[me])
        mine:SetHeight(top)
    end
    mine:SetShown(me ~= nil)
    local names = {}
    for index, person in ipairs(list) do
        names[index] = person.guid .. ":" .. #shown[person]
    end
    local count, used = Fit(list, frame:GetHeight() - top)
    box:SetPoint("TOPLEFT", block, "TOPLEFT", 0, -top)
    box:SetPoint("TOPRIGHT", block, "TOPRIGHT", 0, -top)
    box:SetHeight(math.max(used, 1))
    box:SetShown(count > 0)
    block:SetHeight(math.max(top + used, Row.LINE))
    frame:EnableMouseWheel(count < #list)
    leader = not me and list[first] or nil
    frame.drag.person = me or leader
    Grab()
    if me then
        Row.Draw(mine, me, read, shown[me], Room(true), hovered, block:GetWidth())
        Grab(mine.reach)
    end

    local now = table.concat(names, " ")
    if now ~= line then
        line = now
        box:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.RetainScrollPosition)
    else
        box:ForEachFrame(Draw)
    end
    if count > 0 then
        box:ScrollToElementDataIndex(first, ScrollBoxConstants.AlignBegin, 0, ScrollBoxConstants.NoScrollInterpolation)
    end
end

-- Read and drawn anew, if in sight; else once it is.
function Refresh()
    if not frame or not frame:IsShown() or not block:IsShown() then
        stale = true
        return
    end
    stale = false
    ns.MeterFights.Settle()
    read = ns.MeterFights.Read(Types())
    Lay(Listed(Sorted()))
    Controls.Page()
end

-- Whether it stands in sight by itself, the mouse aside.
local function Wanted()
    if Core.EditMode.active or ns.MeterFights.Loaded() then return true end
    if ns.options.meterHideRest and not ns.MeterFights.Fighting() then return false end
    if ns.options.meterHideAlone and not Core.Ask(IsInGroup) then return false end
    return true
end

-- In sight or not. With Show on mouseover the empty window stays, for the mouse's coming; its wheel is the game's then.
local function Seen()
    if not frame then return end
    local on = ns.options.meter and not ns.off and not covered
    local wanted = Wanted()
    frame:SetShown((on and (wanted or ns.options.meterHover)) and true or false)
    local seen = (wanted or hovered) and true or false
    block:SetShown(seen)
    if not seen then frame:EnableMouseWheel(false) end
    if seen and stale then Refresh() end
end

local function Again()
    Seen()
    Refresh()
end
Meter.Refresh = function() ns.Guarded(Again) end
local soon = Core.Later(Meter.Refresh)

-- Somebody of the group whose item level is still to be asked for.
local function Missing()
    for _, person in ipairs(read and read.people or {}) do
        if person.unit and not person.item then return true end
    end
    return false
end

-- A look: in a fight all of it, out of one only the question for an item level, a few looks apart; with nobody left
-- to ask about the look ends.
local function Look()
    if ns.MeterFights.Fighting() then return Refresh() end
    if not Missing() then return watch:Stop() end
    rest = rest + 1
    if rest < Meter.ASK then return end
    rest = 0
    for _, person in ipairs(read.people) do
        if person.unit and not person.item then Core.Inspect.Level(person.unit, person.guid) end
    end
end

-- Whether there is something to look for: looks run or end.
local function Watching()
    if not watch then return end
    if frame:IsShown() and (ns.MeterFights.Fighting() or Missing()) then
        if not watch:IsRunning() then watch:Start() end
    else
        watch:Stop()
    end
end

-- Which half of the screen it stands in: the list hangs from the top or stands on the bottom.
local function Sided()
    if not block then return end
    local _, y = frame:GetCenter()
    local up = y ~= nil and y < UIParent:GetHeight() / 2
    block:ClearAllPoints()
    block:SetPoint(up and "BOTTOMLEFT" or "TOPLEFT")
    block:SetPoint(up and "BOTTOMRIGHT" or "TOPRIGHT")
end

-- Whether it may be moved and sized now (Core's usable): not while locked, but in Edit Mode, where the game's own meter
-- is arranged too.
local function Free()
    return Core.EditMode.active or not ns.options.meterLocked
end

-- The mouse came or left: all that stands only for it.
local function Hovered(on)
    hovered = on
    Controls.Show(on)
    handle:Hover(on)
    Grab()
    Again()
end

-- The game keeps gathering while its meter is switched on: its setting on and its window out of sight (Hold(true)),
-- or given back as they were (its setting as it stood before ours is kept: store.meterGame, as a /reload finds it
-- on). In Edit Mode its window is the game's, to be placed.
local function Hold(on)
    local game = rawget(_G, "DamageMeter")
    local take = on and not Core.EditMode.active
    if take and game and not lent then
        away = away or CreateFrame("Frame", nil, UIParent)
        away:Hide()
        local lend = Core.Lend(game)
        if lend:SetParent(away) then lent = lend end
    elseif not take and lent then
        local given = lent
        lent = nil
        given:Return()
    end
    local was = ns.store.meterGame
    if on then
        local now = Core.Ask(C_CVar.GetCVar, Meter.CVAR)
        ns.store.meterGame = was or now or "0"
        if now ~= "1" then Core.Ask(C_CVar.SetCVar, Meter.CVAR, "1") end
    elseif was then
        if was ~= "1" then Core.Ask(C_CVar.SetCVar, Meter.CVAR, was) end
        ns.store.meterGame = nil
    end
end

-- As the settings say: shown or not, drawn anew, its grip there or gone as Lock window has it.
function Meter.Apply()
    if not frame then return end
    Hold(ns.options.meter and not ns.off)
    handle:Hover(hovered)
    Again()
    Watching()
end

-- Combat's full screen is up (on, from as it begins to fill) or gone: never on or over it, the meter is out of sight
-- meanwhile, and back at its place after.
function Meter.Cover(on)
    on = on and true or false
    if not frame or on == covered then return end
    covered = on
    Again()
    Watching()
end

-- On or off, as /sane meter says.
function Meter.Toggle()
    Core.Set(ns.name, "meter", not ns.options.meter)
end

-- Whether it is switched on.
function Meter.Shown()
    return frame ~= nil and frame:IsShown()
end

-- The module stood down: the window goes, the game's own meter is back.
function Meter.GiveBack()
    if frame then frame:Hide() end
    Hold(false)
end

-- Built at the login. Nothing takes the mouse but its coming: every click goes through.
function Meter.Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("LOW")
    frame:Hide()
    handle = Core.Window.New(frame, {
        store = ns.store, key = "meterPlace", title = ns.TEXT.meter, first = FIRST,
        dock = true, dragDocked = true, sizable = true, grip = "hover",
        minWidth = Meter.LEAST_WIDTH, minHeight = Meter.LEAST_HEIGHT, usable = Free,
        docked = function() ns.Guarded(Sided) end,
    })
    Meter.handle = handle

    block = CreateFrame("Frame", nil, handle.inside)
    block:SetPoint("TOPLEFT")
    block:SetPoint("TOPRIGHT")
    block:SetHeight(Row.LINE)
    mine = CreateFrame("Frame", nil, block)
    mine:SetPoint("TOPLEFT")
    mine:SetPoint("TOPRIGHT")
    box = CreateFrame("Frame", nil, block, "WowScrollBoxList")
    local bar = CreateFrame("EventFrame", nil, block, "MinimalScrollBar")
    bar:Hide() -- the wheel scrolls: the list shows nothing but its rows
    view = CreateScrollBoxListLinearView()
    -- The game's list asks these of every row: always a number (also after a failure), each row drawn apart.
    view:SetElementExtentCalculator(function(_, person) return ns.Safe("meter", Extent, person) or Row.LINE end)
    view:SetElementInitializer("Frame", function(row, person) ns.Safe("meter", Draw, row, person) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    box:EnableMouseWheel(false) -- the window's wheel, on your own line too: a character a notch
    frame:SetScript("OnMouseWheel", ns.Guard(function(_, delta)
        first = first + (delta < 0 and 1 or -1)
        Refresh()
    end))

    -- The first line drags the window, while the mouse is on it, as far as its words reach (Grab), and a right click
    -- there is on its name as on any.
    local drag = CreateFrame("Frame", nil, block)
    drag:SetPoint("TOPLEFT")
    drag:SetSize(Row.NAME, Row.LINE)
    drag:SetFrameLevel(block:GetFrameLevel() + 10)
    drag:EnableMouse(true)
    drag:Hide()
    drag:SetScript("OnMouseUp", ns.Guard(function(self, mouse)
        if mouse == "RightButton" and self.person then Controls.Character(self, self.person) end
    end))
    frame.drag = drag
    handle:DragBy(drag)
    Controls.Build(block)

    hover = Core.Hover(frame, { margin = Meter.MARGIN, linger = Meter.LINGER, keep = Controls.Open, label = "meter",
                                enter = function() ns.Guarded(Hovered, true) end,
                                leave = function() ns.Guarded(Hovered, false) end })
    watch = Core.Watch(frame, Meter.EVERY, ns.Guard(Look), "meter")
    frame:HookScript("OnShow", ns.Guard(function() -- Core's window has its own there
        if stale then Refresh() end
        Watching()
    end))
    frame:HookScript("OnSizeChanged", ns.Guard(function()
        if read then Refresh() end
    end))
    handle:Place()
    Sided()
    Core.Inspect.Watch(ns.Guard(function() soon() end))
    Core.EditMode.Watch(ns.Guard(Meter.Apply))
    if InCombatLockdown() then ns.MeterFights.Began() end -- a /reload in a fight
    Meter.Apply()
    Core.Edge.Watch(ns.Guard(Meter.Cover))
    Meter.Cover(Core.Edge.AnyFull())
end

local function Began()
    ns.MeterFights.Began()
    Again()
    Watching()
end

local function Ended()
    ns.MeterFights.Ended()
    Again()
    Watching()
end

-- The game's words of a change: at rest drawn anew once however many came; in a fight only whether it is to be seen
-- (a group joined), the next look shows the rest.
local function Changed()
    if not ns.MeterFights.Fighting() then return soon() end
    if frame then ns.Guarded(Seen) end
end

ns.On("PLAYER_REGEN_DISABLED", function() if frame then ns.Guarded(Began) end end)
ns.On("PLAYER_REGEN_ENABLED", function() if frame then ns.Guarded(Ended) end end)
ns.On("PLAYER_TARGET_CHANGED", function() ns.MeterThreat.Retarget() end)
ns.On("DAMAGE_METER_RESET", function()
    ns.MeterFights.Cleared()
    Changed()
end)
for _, event in ipairs({ "DAMAGE_METER_COMBAT_SESSION_UPDATED", "DAMAGE_METER_CURRENT_SESSION_UPDATED",
                         "GROUP_ROSTER_UPDATE", "PLAYER_LEVEL_CHANGED" }) do
    ns.On(event, Changed)
end
