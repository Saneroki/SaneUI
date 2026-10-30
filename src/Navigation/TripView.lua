local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - TripView
--  The overlay of a trip, centred high up the screen at a toast's height
--  (Core.TOAST_TOP, the words over its line level with it): a fine golden
--  line in the art of the map's route (Route.lua: the game's dependency bar, its
--  glint pulsing along), the vehicle's icon riding at its tip.
--
--    on a trip   (Core's Data.Trips: a flight, a boat or a zeppelin, the tram) where it began at the
--                line's left end, where it ends at its right, a flight point's mark at each stop on it (dim
--                once passed); under it the time to the end, the next stop and its time, the zone.
--                Setting: Your trip on screen.
--    waiting     at a dock or a tram's station (DockWatch.lua): the next to come there, the line filling as it
--                nears (from when it last left here to when it arrives), then when it leaves; how often it
--                sails while its times are not known; the others there in a line each below. Setting: Ship
--                times at a dock.
--    the way out wherever the game offers one, beside the line, alone in the overlay's place in a vehicle:
--                the game's art and words, Request Stop on a flight (it lands at the next flight point),
--                Leave Vehicle in a vehicle. It stands in for the game's button at the action bars, which
--                is out of sight and takes no clicks while Your trip on screen is on; in Edit Mode the
--                game's is back, to be placed. A vehicle's own action bar keeps its own leave button.
--
--      TripView.Lines(trip)   the words for a trip: { from, to, title, next, left, zone } (knows no frames)
--      TripView.Update()      looked at again now (a trip began or ended, a setting changed)
--
--  Looked at every second while shown (every TripView.LOOK seconds else); between
--  two looks the line moves on smoothly every frame (OnUpdate, only while shown).
--  Not while the map fills the screen.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local TripView = {}
ns.TripView = TripView

TripView.ABOVE = 30      -- from the line up to the top of the words over it
TripView.WIDTH = 320     -- the line's length
TripView.THICK = 4       -- its thickness; its dark edge EDGE
TripView.EDGE = 7
TripView.MARK = 16       -- a stop's mark on it, an end's END, the vehicle's RIDER
TripView.END = 20
TripView.RIDER = 24
TripView.BUTTON = 32     -- the way out, as large as the game's
TripView.GAP = 6         -- pixels between the parts
TripView.EASE = 5        -- how quickly the line follows where the trip is (eased, a share of the gap a second)
TripView.LOOK = 2        -- seconds between two looks while nothing shows

TripView.TEXT = {
    title = "%s to %s",
    tram = "%s: %s to %s",
    next = "Next: %s in %s",
    landing = "Landing at %s",
    arrives = "Arrives in %s",
    board = "Board now",
    leaves = "Leaves in %s",
    learn = "Ride it once on this realm for its times",
    every = "About every %s",
    unknown = "...",
    stop = Core.Word("TAXI_CANCEL", "Request Stop"),
    stopTip = Core.Word("TAXI_CANCEL_DESCRIPTION", "Stop at the next flight point."),
    leave = Core.Word("LEAVE_VEHICLE", "Leave Vehicle"),
}

-- The game's own leave button's art (MainMenuBarVehicleLeaveButton), and its look once a stop was asked for.
local EXIT = { up = "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up", down = "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down",
               crop = { 0.140625, 0.859375, 0.140625, 0.859375 }, light = "Interface\\Buttons\\ButtonHilight-Square",
               asked = "Interface\\Buttons\\CheckButtonHilight" }
local STOP = "TaxiNode_Neutral"  -- a flight point, as the game's flight map draws one
local FLIGHT = "flightmaster"    -- a flight master, as the game's map shows one

local Trips, Ships = Core.Data.Trips(), Core.Data.Ships()
local frame, track, lines, fromLabel, toLabel, timeLine, subLine, zoneLine, rider, exit
local lent, hooked        -- the game's leave button lent to us; hooked: its updates heard
local ends, marks, others = {}, {}, {}
local shown = nil         -- what is drawn: { trip } or { row, rows }, with the line's share as drawn
local looking = false

-- A stop's name: the game's (a flight point), else its dock's area and zone, else the way's kind.
local function Name(stop, kind)
    if stop.name and stop.name ~= "" then return stop.name end
    if stop.map then return ns.Pins.Towards({ map = stop.map, area = stop.area }) end
    return ns.Pins.WAY_WORDS[kind] or "?"
end

local function Clock(seconds)
    if not seconds then return TripView.TEXT.unknown end
    return ns.DockWatch.Clock(seconds)
end

local function Icon(kind)
    if kind == "flight" then return FLIGHT end
    return ns.Pins.WAY_ICONS[kind] or ns.Pins.WAY_ICONS.boat
end

function TripView.Lines(trip)
    local stops = trip.stops
    local first, last = Name(stops[1], trip.kind), Name(stops[#stops], trip.kind)
    local lines = { from = first, to = last, title = TripView.TEXT.title:format(first, last), left = Clock(trip.left) }
    if trip.kind == "tram" and trip.name then lines.title = TripView.TEXT.tram:format(trip.name, first, last) end
    local next = stops[trip.next]
    if trip.landing then
        lines.next = TripView.TEXT.landing:format(last)
    elseif next and trip.next < #stops then
        lines.next = TripView.TEXT.next:format(Name(next, trip.kind), Clock(trip.nextLeft))
    else
        lines.next = trip.kind == "tram" and trip.name or ""
    end
    local zone = Core.Plain(Core.Ask(rawget(_G, "GetZoneText")))
    if zone and zone ~= "" then lines.zone = zone end
    return lines
end

-------------------------------------------------------------------------------
--  The frames
-------------------------------------------------------------------------------
local function Line(file, sublevel, add)
    local line = track:CreateLine(nil, "ARTWORK", nil, sublevel)
    line:SetTexture(file, "REPEAT", "CLAMP")
    if add then line:SetBlendMode("ADD") end
    line:SetStartPoint("LEFT", track, 0, 0)
    return line
end

-- A line of the art from the track's left end to x pixels along it, the art in the map route's repeats.
local function Reach(line, x, thickness)
    if x < 1 then return line:Hide() end
    line:SetEndPoint("LEFT", track, x, 0)
    line:SetThickness(thickness)
    line:SetTexCoord(0, x / ns.Route.PERIOD, 0, 1)
    line:Show()
end

local function OnTaxi()
    return Core.Ask(rawget(_G, "UnitOnTaxi"), "player") and true or false
end

-- What the game's button does when clicked.
local function Exit()
    if not OnTaxi() then return Core.Ask(rawget(_G, "VehicleExit")) end
    Trips:Land()
    exit:Disable()
    exit:SetHighlightTexture(EXIT.asked, "ADD")
    exit:LockHighlight()
end

local function Tip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if OnTaxi() then
        GameTooltip_SetTitle(GameTooltip, TripView.TEXT.stop)
        GameTooltip:AddLine(TripView.TEXT.stopTip, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    else
        GameTooltip_SetTitle(GameTooltip, TripView.TEXT.leave)
    end
    GameTooltip:Show()
end

local Moving -- (below)

local function Label(justify, point)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOM" .. point, track, "TOP" .. point, 0, TripView.GAP + TripView.END / 2)
    label:SetWidth(TripView.WIDTH / 2 - TripView.GAP)
    label:SetJustifyH(justify)
    label:SetWordWrap(false)
    return label
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    TripView.frame = frame
    frame:SetFrameStrata("LOW")
    frame:SetSize(TripView.WIDTH, TripView.END)
    frame:SetPoint("CENTER", UIParent, "TOP", 0, -(Core.TOAST_TOP + TripView.ABOVE))
    frame:EnableMouse(false)
    track = CreateFrame("Frame", nil, frame)
    track:SetSize(TripView.WIDTH, TripView.EDGE)
    track:SetPoint("CENTER")
    local colour = ns.Route.COLOURS.walk
    lines = { edge = Line(ns.Route.EDGE, 0), rest = Line(ns.Route.FILL, 1), done = Line(ns.Route.FILL, 2),
              glint = Line(ns.Route.GLINT, 3, true) }
    lines.edge:SetVertexColor(0, 0, 0, 0.8)
    lines.rest:SetVertexColor(colour[1], colour[2], colour[3], 0.25)
    lines.done:SetVertexColor(colour[1], colour[2], colour[3], 0.95)
    lines.glint:SetVertexColor(colour[1], colour[2], colour[3], 1)
    if C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(ns.Route.GLINT_PULSE) then
        lines.pulse = lines.glint:CreateAnimationGroup(nil, ns.Route.GLINT_PULSE)
    end
    Reach(lines.edge, TripView.WIDTH, TripView.EDGE)
    Reach(lines.rest, TripView.WIDTH, TripView.THICK)
    for index, point in ipairs({ "LEFT", "RIGHT" }) do
        local mark = track:CreateTexture(nil, "OVERLAY", nil, 1)
        mark:SetSize(TripView.END, TripView.END)
        mark:SetPoint("CENTER", track, point, 0, 0)
        ends[index] = mark
    end
    rider = track:CreateTexture(nil, "OVERLAY", nil, 3)
    rider:SetSize(TripView.RIDER, TripView.RIDER)
    fromLabel, toLabel = Label("LEFT", "LEFT"), Label("RIGHT", "RIGHT")
    timeLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    timeLine:SetPoint("TOP", track, "BOTTOM", 0, -(TripView.GAP + TripView.END / 2))
    subLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subLine:SetPoint("TOP", timeLine, "BOTTOM", 0, -2)
    zoneLine = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneLine:SetPoint("TOP", subLine, "BOTTOM", 0, -2)
    exit = CreateFrame("Button", nil, frame)
    TripView.exit = exit
    exit:SetSize(TripView.BUTTON, TripView.BUTTON)
    for _, art in ipairs({ { "SetNormalTexture", EXIT.up }, { "SetPushedTexture", EXIT.down } }) do
        local texture = exit:CreateTexture()
        texture:SetTexture(art[2])
        texture:SetTexCoord(unpack(EXIT.crop))
        exit[art[1]](exit, texture)
    end
    exit:SetHighlightTexture(EXIT.light, "ADD")
    exit:SetMotionScriptsWhileDisabled(true)
    exit:SetScript("OnClick", ns.Guard(Exit))
    exit:SetScript("OnEnter", ns.Guard(Tip))
    exit:SetScript("OnLeave", ns.Guard(function() GameTooltip:Hide() end))
    exit:Hide()
    frame:SetScript("OnUpdate", ns.Guard(function(_, elapsed) Moving(elapsed) end))
    frame:Hide()
end

-------------------------------------------------------------------------------
--  Drawing
-------------------------------------------------------------------------------
-- The share of the line where the trip or the wait is now, between two looks too; and the seconds to its end
-- (a wait: to the arrival, then to the departure).
local function Target()
    local now = GetTime()
    if shown.trip then
        local trip = shown.trip
        local since = now - (trip.t or now)
        local left = trip.left and math.max(0, trip.left - since)
        if not trip.yards or trip.yards <= 0 then return 0, left end
        return math.max(0, math.min(1, (trip.at + (trip.pace or 0) * since) / trip.yards)), left
    end
    local row = shown.row
    if not row.known then return 0, nil end
    if row.here or now >= row.arriveAt then return 1, math.max(0, row.leaveAt - now), true end
    return math.max(0, math.min(1, (now - row.lastAt) / (row.arriveAt - row.lastAt))), row.arriveAt - now
end

-- Every frame while shown: the line eased towards where the trip is, the vehicle at its tip, the time.
Moving = function(elapsed)
    if not shown or shown.alone then return end
    local target, left, docked = Target()
    local share = shown.share or target
    share = share + (target - share) * math.min(1, (elapsed or 0) * TripView.EASE)
    shown.share = share
    local x = TripView.WIDTH * share
    Reach(lines.done, x, TripView.THICK)
    Reach(lines.glint, x, TripView.THICK)
    if lines.pulse and x >= 1 and not lines.pulse:IsPlaying() then lines.pulse:Play() end
    rider:ClearAllPoints()
    rider:SetPoint("CENTER", track, "LEFT", x, TripView.RIDER / 3)
    -- The big time: to the end of a trip; to the arrival of what is waited for, then that it is in.
    local text, sub
    if shown.trip then
        text = Clock(left)
    elseif shown.row.known then
        text = docked and TripView.TEXT.board or TripView.TEXT.arrives:format(Clock(left))
        sub = TripView.TEXT.leaves:format(Clock(docked and left or (shown.row.leaveAt - GetTime())))
    else
        text, sub = TripView.TEXT.every:format(Clock(shown.row.every)), TripView.TEXT.learn
    end
    if text ~= shown.text then
        shown.text = text
        timeLine:SetText(text)
    end
    if sub and sub ~= shown.sub then
        shown.sub = sub
        subLine:SetText(sub)
    end
end

-- The marks of a trip's stops between its ends, along the line; dim once passed.
local function Marks(trip)
    local count = 0
    if trip.yards and trip.yards > 0 then
        for index = 2, #trip.stops - 1 do
            local stop = trip.stops[index]
            if stop.at then
                count = count + 1
                local mark = marks[count]
                if not mark then
                    mark = track:CreateTexture(nil, "OVERLAY", nil, 2)
                    mark:SetAtlas(STOP)
                    mark:SetSize(TripView.MARK, TripView.MARK)
                    marks[count] = mark
                end
                mark:ClearAllPoints()
                mark:SetPoint("CENTER", track, "LEFT", TripView.WIDTH * stop.at / trip.yards, 0)
                mark:SetDesaturated(stop.at <= trip.at)
                mark:Show()
            end
        end
    end
    for index = count + 1, #marks do marks[index]:Hide() end
end

-- The other ways waiting here, a line each under the first.
local function Others(rows)
    local anchor = zoneLine
    for index = 2, #rows do
        local row, line = rows[index], others[index - 1]
        if not line then
            line = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            others[index - 1] = line
        end
        line:ClearAllPoints()
        line:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
        local gold = rawget(_G, "NORMAL_FONT_COLOR")
        local name = gold and gold:WrapTextInColorCode(row.name) or row.name
        line:SetText(("|A:%s:14:14|a %s  %s"):format(row.icon, name, row.status))
        line:Show()
        anchor = line
    end
    for index = math.max(1, #rows), #others do others[index]:Hide() end
end

local function Ends(left, right, dim)
    ends[1]:SetAtlas(left)
    ends[2]:SetAtlas(right)
    ends[1]:SetDesaturated(true)
    ends[2]:SetDesaturated(dim)
end

local function DrawTrip(trip)
    local lines = TripView.Lines(trip)
    -- The same trip as the last look (its kind and length alike): the line goes on easing from where it was drawn.
    local same = shown and shown.trip and shown.trip.kind == trip.kind and shown.trip.yards == trip.yards
        and #shown.trip.stops == #trip.stops
    shown = { trip = trip, share = same and shown.share or nil }
    fromLabel:SetText(lines.from)
    toLabel:SetText(lines.to)
    local icon = trip.kind == "flight" and STOP or Icon(trip.kind)
    Ends(icon, icon, false)
    Marks(trip)
    rider:SetAtlas(Icon(trip.kind))
    rider:Show()
    subLine:SetText(lines.next)
    zoneLine:SetText(lines.zone or "")
    Others({})
end

local function DrawWait(rows)
    local row = rows[1]
    if row.known then
        local now, server = GetTime(), Ships.Now()
        row.arriveAt, row.leaveAt, row.lastAt = now + row.arrive - server, now + row.leave - server, now + row.last - server
    end
    local same = shown and shown.row and shown.row.name == row.name and shown.row.known == row.known
    shown = { row = row, rows = rows, share = same and shown.share or nil }
    fromLabel:SetText(("|A:%s:16:16|a %s"):format(row.icon, row.name))
    toLabel:SetText("")
    Ends(row.icon, row.icon, not row.known)
    Marks({ stops = {} })
    if row.known then
        rider:SetAtlas(row.icon)
        rider:Show()
    else
        rider:Hide()
    end
    zoneLine:SetText("")
    Others(rows)
end

-- Nothing but the way out: in a vehicle, on a flight whose route is not known.
local function DrawAlone()
    shown = { alone = true }
    for _, text in ipairs({ fromLabel, toLabel, timeLine, subLine, zoneLine }) do text:SetText("") end
    Others({})
end

-- The way out: beside the line, alone in its place; new each time it comes, not to be pressed again once a
-- landing was asked for.
local function DrawExit(wanted, landing)
    track:SetShown(not shown.alone)
    exit:ClearAllPoints()
    if shown.alone then
        exit:SetPoint("CENTER")
    else
        exit:SetPoint("LEFT", track, "RIGHT", TripView.END / 2 + TripView.GAP, 0)
    end
    if not wanted then return exit:Hide() end
    if not exit:IsShown() then
        exit:Enable()
        exit:SetHighlightTexture(EXIT.light, "ADD")
        exit:UnlockHighlight()
    end
    if landing then exit:Disable() end
    exit:Show()
end

local function Wanted(key)
    if ns.off or not ns.options or ns.options[key] == false then return false end
    local handle = ns.Window.handle
    return not (handle and handle.edge and handle.edge.full)
end

local function Hide()
    shown = nil
    if frame then
        frame:Hide()
        exit:Hide() -- the next flight's button new
    end
end

-------------------------------------------------------------------------------
--  The game's leave button
-------------------------------------------------------------------------------
-- The game's button, while it is as we know it: otherwise it stays, and ours does not stand in for it.
local function Game()
    local button = rawget(_G, "MainMenuBarVehicleLeaveButton")
    if button and type(button.CanExitVehicle) == "function" then return button end
end

-- Whether there is a way out now: any flight, else as the game's button asks (a vehicle's own action bar has its own).
local function Leaving()
    if OnTaxi() then return true end
    local button = Game()
    return button and Core.Ask(button.CanExitVehicle, button) and true or false
end

local Changed -- (below)

-- The game's button out of sight and without clicks while ours stands in for it. Never hidden by us: its OnHide
-- has Edit Mode's manager lay out the action bars, which would run tainted. A fight that locks it: the next look.
local function Stand()
    local button = Game()
    if button and not hooked then
        hooked = true
        hooksecurefunc(button, "Update", Changed)
    end
    local wanted = button and not ns.off and ns.options and ns.options.tripView ~= false and not Core.EditMode.active
    if wanted and not lent then
        if Core.Locked(button) then return end
        lent = Core.Lend(button)
        lent:SetAlpha(0)
        lent:SetMouse(false)
    elseif lent and not wanted then
        lent:Return()
        lent = nil
    end
end

function TripView.Update()
    Stand()
    local trip = Trips:Now()
    local rows = not trip and ns.DockWatch.Rows() or {}
    local drawTrip = trip and Wanted("tripView")
    local drawWait = #rows > 0 and Wanted("dockTimes")
    local leaving = Leaving() and Wanted("tripView")
    if not drawTrip and not drawWait and not leaving then return Hide() end
    if not frame then Build() end
    if drawTrip then DrawTrip(trip) elseif drawWait then DrawWait(rows) else DrawAlone() end
    DrawExit(leaving, drawTrip and trip.landing)
    frame:Show()
    Moving(0)
end

function TripView.Hide()
    Hide()
    Stand()
end

-- The looks, one after the other while the world is there: every second while shown, else seldom.
local Tick
Tick = ns.Guard(function()
    if ns.off then return Hide() end
    TripView.Update()
    C_Timer.After(shown and 1 or TripView.LOOK, Tick) -- unguarded: Tick is the guard (ns.Guard)
end)
-- A trip began, ended or changed its end, or the game looked at its leave button again: drawn at once.
Changed = ns.Guard(function()
    if not ns.off then TripView.Update() end
end)
ns.On("PLAYER_ENTERING_WORLD", function()
    Stand()
    if looking then return end
    looking = true
    C_Timer.After(1, Tick) -- unguarded: Tick is the guard (ns.Guard)
end)
Trips:OnChange(Changed)
Core.EditMode.Watch(ns.Guard(Stand))
