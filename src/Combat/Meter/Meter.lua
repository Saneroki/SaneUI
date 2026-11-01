local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Meter
--  The threat and damage meter, a window of Core's on the screen and over Combat's
--  full screen, each look with its own place and size, kept, as the quest log's.
--  At first right of the quest log's first place at the very top of the screen; on the
--  full screen in its top left corner.
--
--  The list of your party or raid, you on top (Row.lua), as many as fit: the mouse
--  wheel over the window scrolls the others under your own line, which stays. Sorted
--  by what the flyout says (Read.ORDERS); in a fight, where the game hides the numbers,
--  by the places on its own list, and threat not at all on a boss.
--
--  There is nothing else to it: no title bar, no background, and clicks go through
--  all of it. Only while the mouse is on it the buttons stand at the right end of the
--  first line (Controls.lua), the first line drags the window and its corner's grip
--  sizes it (Core's grip = "hover"). Edit Mode's box moves and sizes it too.
--
--  In the screen's top half the list hangs from the window's top and grows down, in the
--  bottom half it stands on the window's bottom and grows up.
--
--  The game gathers these numbers for its own meter (C_DamageMeter, Read.lua), so its
--  setting is on and its window out of sight while ours is on (Hold); ours or the
--  game's, never both. Nothing runs at rest: a look every Meter.EVERY seconds in a fight,
--  or while somebody's item level is still to be asked for (Core.Inspect), and at rest
--  only when the game says something changed.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Row = ns.MeterRow
local Controls = ns.MeterControls
local Meter = {}
ns.Meter = Meter

Meter.WIDTH, Meter.HEIGHT = 260, 400 -- its first size
Meter.LEAST_WIDTH, Meter.LEAST_HEIGHT = 170, 60 -- its least
Meter.QUEST_LOG = 320       -- the quest log's first width: it stands at the top left corner, the meter right of it
Meter.FULL_X, Meter.FULL_Y = 12, -40 -- on the full screen, from its top left corner, under its title bar
Meter.EVERY = 0.5           -- seconds between two looks in a fight
Meter.ASK = 4               -- out of a fight, looks between two questions for an item level
Meter.MARGIN = 6            -- how far around the window the mouse still counts as on it
Meter.LINGER = 0.3          -- seconds the buttons stay after the mouse left
Meter.CVAR = "damageMeterEnabled" -- the game's meter's switch
Meter.KINDS = { { "threat", "meterThreat" }, { "damage", "meterDamage" }, { "healing", "meterHealing" },
                { "interrupts", "meterInterrupts" } } -- the bars, in their order, and each one's tick

local KEY = { [true] = "meterFullPlace", [false] = "meterPlace" } -- where each look's place is kept
local FIRST = {
    [true] = { point = "TOPLEFT", x = Meter.FULL_X, y = Meter.FULL_Y, width = Meter.WIDTH, height = Meter.HEIGHT },
    [false] = { point = "TOPLEFT", x = Meter.QUEST_LOG, y = 0, width = Meter.WIDTH, height = Meter.HEIGHT },
}

local frame, handle, hover, watch
local block, mine, box, view -- what holds the rows, your own, the list of the others
local kinds = {}             -- the kinds shown now
local worth = {}             -- [person] = what the list is sorted by, this round
local read                   -- the fight read last
local leader                 -- who stands on the first line of the list: without your own line, the buttons stand there
local full = false           -- the look over the full screen
local line                   -- what the list holds, as guids in order: drawn anew only when that changed
local extent                 -- a row's height now
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

-- What to read of the game: the kinds shown, and the one the list is sorted by, as a rate if it goes by that.
local function Types()
    wipe(kinds)
    local types = {}
    for _, each in ipairs(Meter.KINDS) do
        if ns.options[each[2]] then
            kinds[#kinds + 1] = each[1]
            local names = ns.MeterRead.TYPES[each[1]]
            if names then types[each[1]] = names.total end
        end
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

local function Draw(row, person)
    Row.Draw(row, person, read, kinds, Room(person == leader))
end

-- The list's room in the window, from what is shown: rows whole, so nobody stands half out of it. Your own line first.
local function Lay(list, me)
    local height = Row.Height(#kinds)
    local top = me and height or 0
    local fit = math.floor((frame:GetHeight() - top) / height)
    local shown = math.max(0, math.min(fit, #list))
    mine:SetHeight(height)
    mine:SetShown(me ~= nil)
    box:SetPoint("TOPLEFT", block, "TOPLEFT", 0, -top)
    box:SetPoint("TOPRIGHT", block, "TOPRIGHT", 0, -top)
    box:SetHeight(math.max(shown * height, 1))
    box:SetShown(shown > 0)
    block:SetHeight(math.max(top + shown * height, Row.LINE))
    frame:EnableMouseWheel(#list > shown)
    if me then Row.Draw(mine, me, read, kinds, Room(true)) end
    leader = not me and list[1] or nil

    local names = {}
    for index, person in ipairs(list) do names[index] = person.guid end
    local now = table.concat(names, " ")
    if now ~= line or height ~= extent then
        line, extent = now, height
        view:SetElementExtent(height)
        box:SetPanExtent(height)
        box:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.RetainScrollPosition)
    else
        box:ForEachFrame(Draw)
    end
end

-- Read and drawn anew, if in sight; else once it is.
function Refresh()
    if not frame or not frame:IsShown() then
        stale = true
        return
    end
    stale = false
    ns.MeterFights.Settle()
    read = ns.MeterFights.Read(Types())
    Lay(Sorted())
    Controls.Page()
end
Meter.Refresh = function() ns.Guarded(Refresh) end
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
    if InCombatLockdown() then return Refresh() end
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
    if frame:IsShown() and (InCombatLockdown() or Missing()) then
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

-- The mouse came or left: all that stands only for it.
local function Hovered(on)
    hovered = on
    Controls.Show(on)
    handle:Hover(on)
    frame.drag:SetShown(on)
    Refresh()
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

-- As the settings say: shown or not, drawn anew.
function Meter.Apply()
    if not frame then return end
    local on = ns.options.meter and not ns.off
    Hold(on)
    frame:SetShown(on and true or false)
    Refresh()
    Watching()
end

-- Its look: over Combat's full screen (on), above the board, or on the screen. Each at its own place, kept.
function Meter.Dress(on)
    on = on and true or false
    if not frame or on == full then return end
    full = on
    frame:SetFrameStrata(on and "DIALOG" or "LOW")
    handle:Use(KEY[on], FIRST[on])
    Sided()
    Refresh()
end

-- On or off, as the button on the full screen's bar and /sane meter say.
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
        store = ns.store, key = KEY[false], title = ns.TEXT.meter, first = FIRST[false],
        dock = true, dragDocked = true, sizable = true, grip = "hover",
        minWidth = Meter.LEAST_WIDTH, minHeight = Meter.LEAST_HEIGHT,
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
    view:SetElementInitializer("Frame", function(row, person) ns.Safe("meter", Draw, row, person) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    box:EnableMouseWheel(false) -- the window's wheel, on your own line too
    frame:SetScript("OnMouseWheel", ns.Guard(function(_, delta) box:OnMouseWheel(delta) end))

    -- The first line drags the window, while the mouse is on it.
    local drag = CreateFrame("Frame", nil, block)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("TOPRIGHT", -Controls.WIDTH, 0)
    drag:SetHeight(Row.LINE)
    drag:SetFrameLevel(block:GetFrameLevel() + 10)
    drag:EnableMouse(true)
    drag:Hide()
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
    Core.EditMode.Watch(ns.Guard(function() Hold(ns.options.meter and not ns.off) end))
    Meter.Apply()
    Meter.Dress(ns.Window.Full())
end

local function Began()
    ns.MeterFights.Began()
    Refresh()
    Watching()
end

local function Ended()
    ns.MeterFights.Ended()
    Refresh()
    Watching()
end

-- The game's words of a change: at rest drawn anew once however many came; in a fight the next look shows it.
local function Changed()
    if not InCombatLockdown() then soon() end
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
