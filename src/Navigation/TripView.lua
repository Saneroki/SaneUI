local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - TripView
--  The trip the player is on (Core's Data.Trips: a flight, a boat or a zeppelin,
--  the tram), under the game's own widgets at the top of the screen: where it
--  goes, a bar of the way flown or sailed (Core's bar, the game's experience bar
--  art) with a flight point's mark at each stop on it, the next stop and the
--  time to it, the time to the end, and the zone below. On a flight with a stop
--  before its end, the game's own Request Stop button: it lands at the next
--  flight point. While the setting Your trip on screen is on, and not while the
--  map fills the screen.
--
--      TripView.Lines(trip)   what it shows for a trip: { title, next, left, zone } (knows no frames)
--      TripView.Update()      drawn again now (the trip or the setting changed)
--
--  Drawn every second while a trip lasts; nothing runs without one.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local TripView = {}
ns.TripView = TripView

TripView.WIDTH = 260     -- the bar's length
TripView.BAR = 10        -- its thickness
TripView.MARK = 14       -- a stop's mark on it
TripView.BUTTON = 28     -- the Request Stop button
TripView.GAP = 6         -- pixels under the game's widgets at the top of the screen, and between the parts
TripView.LINE = 2        -- pixels between two lines

TripView.TEXT = {
    title = "%s to %s",
    tram = "%s: %s to %s",
    next = "Next: %s, %s",
    landing = "Landing at %s",
    arrives = "Arrives in %s",
    unknown = "...",
    stop = Core.Word("TAXI_CANCEL", "Request Stop"),
    stopTip = Core.Word("TAXI_CANCEL_DESCRIPTION", "Stop at the next flight point."),
}

-- The game's own leave button's art (MainMenuBarVehicleLeaveButton), and its look once a stop was asked for.
local EXIT = { up = "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up", down = "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down",
               crop = { 0.140625, 0.859375, 0.140625, 0.859375 }, light = "Interface\\Buttons\\ButtonHilight-Square",
               asked = "Interface\\Buttons\\CheckButtonHilight" }
local MARK = "TaxiNode_Neutral"  -- a flight point, as the game's flight map draws one

local Trips = Core.Data.Trips()
local frame, title, bar, nextLine, leftLine, zoneLine, exit
local marks = {}
local drawing = false

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

function TripView.Lines(trip)
    local stops = trip.stops
    local first, last = Name(stops[1], trip.kind), Name(stops[#stops], trip.kind)
    local lines = { title = TripView.TEXT.title:format(first, last), left = Clock(trip.left) }
    if trip.kind == "tram" and trip.name then lines.title = TripView.TEXT.tram:format(trip.name, first, last) end
    local next = stops[trip.next]
    if trip.landing then
        lines.next = TripView.TEXT.landing:format(last)
    elseif next and trip.next < #stops then
        lines.next = TripView.TEXT.next:format(Name(next, trip.kind), Clock(trip.nextLeft))
    else
        lines.next = TripView.TEXT.arrives:format(Clock(trip.left))
    end
    local zone = Core.Plain(Core.Ask(rawget(_G, "GetZoneText")))
    if zone and zone ~= "" then lines.zone = zone end
    return lines
end

local function Wanted()
    if ns.off or not ns.options or ns.options.tripView == false then return false end
    local handle = ns.Window.handle
    return not (handle and handle.edge and handle.edge.full)
end

local function Exit()
    Trips:Land()
    exit:Disable()
    exit:SetHighlightTexture(EXIT.asked, "ADD")
    exit:LockHighlight()
end

local function Tip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, TripView.TEXT.stop)
    GameTooltip:AddLine(TripView.TEXT.stopTip, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    GameTooltip:Show()
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    TripView.frame = frame
    frame:SetFrameStrata("LOW")
    frame:SetSize(TripView.WIDTH, 1)
    frame:EnableMouse(false)
    local widgets = rawget(_G, "UIWidgetTopCenterContainerFrame")
    if widgets then
        frame:SetPoint("TOP", widgets, "BOTTOM", 0, -TripView.GAP)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -40)
    end
    title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, 0)
    bar = Core.Bar.New(frame, { width = TripView.WIDTH, height = TripView.BAR, segments = 1 })
    bar.frame:SetPoint("TOP", title, "BOTTOM", 0, -TripView.GAP)
    nextLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nextLine:SetPoint("TOPLEFT", bar.frame, "BOTTOMLEFT", 0, -TripView.GAP)
    leftLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    leftLine:SetPoint("TOPRIGHT", bar.frame, "BOTTOMRIGHT", 0, -TripView.GAP)
    zoneLine = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneLine:SetPoint("TOPLEFT", nextLine, "BOTTOMLEFT", 0, -TripView.LINE)
    exit = CreateFrame("Button", nil, frame)
    TripView.exit = exit
    exit:SetSize(TripView.BUTTON, TripView.BUTTON)
    exit:SetPoint("LEFT", bar.frame, "RIGHT", TripView.GAP, 0)
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
    frame:Hide()
end

-- A mark for each stop between the ends, where it lies along the bar; dim once passed.
local function Marks(trip)
    local shown = 0
    if trip.yards and trip.yards > 0 then
        for index = 2, #trip.stops - 1 do
            local stop = trip.stops[index]
            if stop.at then
                shown = shown + 1
                local mark = marks[shown]
                if not mark then
                    mark = bar.frame:CreateTexture(nil, "OVERLAY")
                    mark:SetAtlas(MARK)
                    mark:SetSize(TripView.MARK, TripView.MARK)
                    marks[shown] = mark
                end
                mark:ClearAllPoints()
                mark:SetPoint("CENTER", bar.frame, "LEFT", TripView.WIDTH * stop.at / trip.yards, 0)
                mark:SetDesaturated(stop.at <= trip.at)
                mark:Show()
            end
        end
    end
    for index = shown + 1, #marks do marks[index]:Hide() end
end

local function Draw(trip)
    if not trip or not Wanted() then
        if frame then
            frame:Hide()
            if not trip then exit:Hide() end -- the next flight's button new
        end
        return
    end
    if not frame then Build() end
    local lines = TripView.Lines(trip)
    local icon = trip.kind == "flight" and "flightmaster" or ns.Pins.WAY_ICONS[trip.kind] or ns.Pins.WAY_ICONS.boat
    title:SetText(("|A:%s:16:16|a %s"):format(icon, lines.title))
    if trip.yards and trip.yards > 0 then bar:SetValue(math.min(trip.at, trip.yards), trip.yards) else bar:SetValue(0, 1) end
    Marks(trip)
    nextLine:SetText(lines.next)
    leftLine:SetText(lines.left)
    zoneLine:SetText(lines.zone or "")
    local can = trip.kind == "flight" and (trip.canLand or trip.landing)
    if can then
        if not exit:IsShown() then
            exit:Enable()
            exit:SetHighlightTexture(EXIT.light, "ADD")
            exit:UnlockHighlight()
        end
        if trip.landing then exit:Disable() end
        exit:Show()
    else
        exit:Hide()
    end
    frame:Show()
end

function TripView.Update()
    Draw(Trips:Now())
end

-- Every second while a trip lasts.
local Tick
Tick = ns.Guard(function()
    if ns.off then
        drawing = false
        if frame then frame:Hide() end
        return
    end
    local trip = Trips:Now()
    Draw(trip)
    if trip then
        C_Timer.After(1, Tick) -- unguarded: Tick is the guard (ns.Guard)
    else
        drawing = false
    end
end)

-- A trip began, ended or changed its end: drawn at once, then every second while it lasts.
local function Changed()
    if ns.off then return end
    Draw(Trips:Now())
    if drawing or not Trips:Now() then return end
    drawing = true
    C_Timer.After(1, Tick) -- unguarded: Tick is the guard (ns.Guard)
end
Trips:OnChange(ns.Guard(Changed))

-- The module stood down (GiveBack): out of sight.
function TripView.Hide()
    if frame then frame:Hide() end
end
