local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - DockWatch
--  At a dock, under the game's own widgets at the top of the screen: each boat
--  and zeppelin that stops there, where it goes, and when it comes and leaves,
--  once a ride taught its times on this realm (Core's Data.Ships); until then how
--  often it sails. Aboard: where it lands, and in how long. While the setting
--  Ship times at a dock is on, and not while the map fills the screen.
--
--      DockWatch.Rows()     what it shows now: a list of { icon, name, status, known } (knows no frames)
--      DockWatch.Update()   looked at again now (the setting changed)
--
--  Shown within DockWatch.NEAR yards of where one stops, kept up to DockWatch.FAR
--  (so it does not blink at the edge); looked at every DockWatch.LOOK seconds,
--  every second while shown, the times counting down. No mouse, no clicks.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local DockWatch = {}
ns.DockWatch = DockWatch

DockWatch.NEAR = 60      -- yards from where a boat or zeppelin stops within which its times show
DockWatch.FAR = 90       -- yards beyond which they go again
DockWatch.LOOK = 2       -- seconds between two looks while nothing shows
DockWatch.ROWS = 4       -- rows at most
DockWatch.GAP = 6        -- pixels under the game's widgets at the top of the screen
DockWatch.LINE = 2       -- pixels between two rows

DockWatch.TEXT = {
    here = "In port, leaves in %s",
    coming = "Arrives in %s, leaves in %s",
    every = "Sails every %s (ride it once for its times)",
    about = "Sails about every %s (ride it once for its times)",
    lands = "Lands in %s",
    to = "To %s",
}

local Travel = Core.Data.Set("Travel")
local Ships = Core.Data.Ships()
local frame, lines
local shown = false      -- whether the last look showed rows (then kept up to DockWatch.FAR yards)
local looking = false

-- Seconds as the game's clock writes them (1:05).
local function Clock(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    local clock = rawget(_G, "SecondsToClock")
    if clock then
        local ok, text = pcall(clock, seconds)
        if ok and type(text) == "string" then return text end
    end
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

-- A stop's dock in the game's words (its area, and the zone where that is another); nil when not known.
local function DockName(key, stop)
    local record = Travel:Get(key)
    local dock = record and type(record.docks) == "table" and record.docks[stop.dock]
    if not dock then return nil end
    return ns.Pins.Towards({ map = dock.map, area = stop.area })
end

-- Where a stop's boat goes on from it: the name of the next stop at another dock.
local function Onward(key, timetable, number)
    local stops, from = timetable.stops, timetable.stops[number].dock
    for step = 1, #stops - 1 do
        local stop = stops[(number - 1 + step) % #stops + 1]
        if stop.dock ~= from then return DockName(key, stop) end
    end
    return nil
end

local function Icon(timetable)
    return ns.Pins.WAY_ICONS[timetable.kind] or ns.Pins.WAY_ICONS.boat
end

-- Aboard: where it lands and in how long. Else each way that stops near: the stop of it there that it leaves
-- soonest, and when, known first and soonest first.
function DockWatch.Rows()
    local rows = {}
    local key, stop, left = Ships:Aboard()
    local timetable = key and Ships:Table(key)
    if timetable then
        local name = timetable.stops[stop] and DockName(key, timetable.stops[stop])
        rows[1] = { icon = Icon(timetable), name = name or ns.Pins.WAY_WORDS[timetable.kind],
                    status = DockWatch.TEXT.lands:format(Clock(left)), known = true, at = 0 }
        return rows
    end
    local best = {}
    for _, near in ipairs(Ships:Near(shown and DockWatch.FAR or DockWatch.NEAR)) do
        timetable = Ships:Table(near.key)
        local arrive, leave, here = Ships:Next(near.key, near.stop)
        local row = best[near.key]
        if timetable and (not row or (leave and (not row.leave or leave < row.leave))) then
            local name = Onward(near.key, timetable, near.stop)
            row = { icon = Icon(timetable), name = name and DockWatch.TEXT.to:format(name) or ns.Pins.WAY_WORDS[timetable.kind],
                    leave = leave, known = leave ~= nil }
            local now = Ships.Now()
            if not leave then
                row.status = (timetable.known and DockWatch.TEXT.every or DockWatch.TEXT.about):format(Clock(timetable.round))
            elseif here then
                row.status = DockWatch.TEXT.here:format(Clock(leave - now))
            else
                row.status = DockWatch.TEXT.coming:format(Clock(arrive - now), Clock(leave - now))
            end
            best[near.key] = row
        end
    end
    for _, row in pairs(best) do rows[#rows + 1] = row end
    table.sort(rows, function(a, b)
        if a.known ~= b.known then return a.known end
        if a.leave and b.leave and a.leave ~= b.leave then return a.leave < b.leave end
        return a.name < b.name
    end)
    while #rows > DockWatch.ROWS do table.remove(rows) end
    return rows
end

-- Under the game's widgets at the top of the screen (its zone's states), where the game shows what goes on around.
local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    DockWatch.frame = frame
    frame:SetFrameStrata("LOW")
    frame:SetSize(1, 1)
    frame:EnableMouse(false)
    local widgets = rawget(_G, "UIWidgetTopCenterContainerFrame")
    if widgets then
        frame:SetPoint("TOP", widgets, "BOTTOM", 0, -DockWatch.GAP)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -40)
    end
    lines = {}
    for index = 1, DockWatch.ROWS do
        local line = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if index == 1 then
            line:SetPoint("TOP", frame, "TOP", 0, 0)
        else
            line:SetPoint("TOP", lines[index - 1], "BOTTOM", 0, -DockWatch.LINE)
        end
        lines[index] = line
    end
    frame:Hide()
end

-- Words in one of the game's colours (as they are where the game has no such colour).
local function Paint(color, text)
    if type(color) == "table" and color.WrapTextInColorCode then return color:WrapTextInColorCode(text) end
    return text
end

-- The rows drawn: the icon and where it goes in gold, the times in white (grey while not known).
local function Draw(rows)
    if #rows == 0 then
        if frame then frame:Hide() end
        return
    end
    if not frame then Build() end
    for index, line in ipairs(lines) do
        local row = rows[index]
        if row then
            local color = rawget(_G, row.known and "HIGHLIGHT_FONT_COLOR" or "DISABLED_FONT_COLOR")
            line:SetText(("|A:%s:16:16|a %s  %s"):format(row.icon, row.name, Paint(color, row.status)))
            line:Show()
        else
            line:Hide()
        end
    end
    frame:Show()
end

local function Wanted()
    if ns.off or not ns.options or ns.options.dockTimes == false then return false end
    local handle = ns.Window.handle
    return not (handle and handle.edge and handle.edge.full)
end

-- The module stood down (GiveBack): out of sight, and no more looks.
function DockWatch.Hide()
    if frame then frame:Hide() end
end

function DockWatch.Update()
    local rows = Wanted() and DockWatch.Rows() or {}
    shown = #rows > 0
    Draw(rows)
end

-- The looks, one after the other: every second while it shows, else seldom.
local Tick
Tick = ns.Guard(function()
    if ns.off then return DockWatch.Hide() end
    DockWatch.Update()
    C_Timer.After(shown and 1 or DockWatch.LOOK, Tick) -- unguarded: Tick is the guard (ns.Guard)
end)

-- Started once the world is there, unless the set Travel is missing.
ns.On("PLAYER_ENTERING_WORLD", function()
    if looking or Travel:State() == "missing" then return end
    looking = true
    C_Timer.After(DockWatch.LOOK, Tick) -- unguarded: Tick is the guard (ns.Guard)
end)
