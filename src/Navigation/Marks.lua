local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Marks
--  What stands over the map at a fixed size on the screen, whatever the zoom:
--
--      the player's arrow   Blizzard's world map arrow (UI-WorldMapArrow), turned to the facing;
--                           out of sight while the game's minimap shows its own (Hybrid.lua)
--      the map pin          the game's own (Waypoint-MapPin-Tracked / -Untracked, as its map's);
--                           a click leads the game's arrow to it or not, Ctrl-click takes it away
--      the party, the raid  the game's party blip in each member's class colour, a few times a
--                           second while the map is shown (the pin filter's Party and raid)
--      a ping               the game's minimap ping where the group (or the player) pinged (Ping.lua),
--                           its ring turning and its wave growing, who pinged under it in their class
--                           colour (not the player); Ping.TIME seconds, fading out at the end; none
--                           where the game's minimap shows over our map, which draws its own there
--
--  Placed against the canvas' holder like the layers (Canvas.lua), so a drag moves
--  them with the map; the arrow is moved again on every step of the canvas'
--  tracker. Each shows only while it lies wholly inside the canvas (Fit), as the
--  pins do. The map's other pins are PinView.lua's.
-------------------------------------------------------------------------------
local Marks = {}
ns.Marks = Marks

Marks.ARROW = 27  -- the player's arrow, as Blizzard's map draws it (GroupMembersDataProvider)
Marks.PIN = 30    -- the map pin, as Blizzard's (WaypointLocationDataProvider)
Marks.MEMBER = 14 -- a member of the party or raid
Marks.BLIP = "PlayerPartyBlip"
Marks.GROUP = 0.25 -- seconds between two looks at where the party is
Marks.PING = 32    -- a ping, about as large as the game's minimap draws its own
Marks.PING_ART = "Interface\\Minimap\\UI-Minimap-Ping-" -- the game's minimap ping: its Center, Rotate and Expand
Marks.TURN = 2     -- seconds its ring takes to turn once
Marks.WAVE = 0.8   -- seconds its wave takes to grow out once
Marks.FADE = 0.5   -- seconds it fades out at its end

local Coords, Live = ns.Coords, ns.Live
local layer, holder, arrow, pin
local members = {} -- the members' textures, made as many as needed
local pinged = {}  -- the pings' marks, made as many as needed
local nextGroup = 0

-- The game's own words for its map pin.
local function Tip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT", -16, -4)
    GameTooltip:SetText(SaneUI.Core.Word("MAP_PIN_SHARING", "Map Pin"), 1, 1, 1)
    local more = rawget(_G, "MAP_PIN_SHARING_TOOLTIP")
    if type(more) == "string" then GameTooltip:AddLine(more, nil, nil, nil, true) end
    GameTooltip:Show()
end

local function Sound(key)
    local id = rawget(_G, "SOUNDKIT") and SOUNDKIT[key]
    if id then PlaySound(id) end
end

-- A click on the pin, as on the game's map: Ctrl takes it away, the chat link's modifier writes it into the
-- chat, a left click leads the game's arrow on the screen to it, or no longer.
local function Clicked(_, button)
    if IsControlKeyDown() then
        Live.ClearWaypoint()
        Sound("UI_MAP_WAYPOINT_REMOVE")
    elseif IsModifiedClick("CHATLINK") then
        local link = C_Map.GetUserWaypointHyperlink and C_Map.GetUserWaypointHyperlink()
        local chat = rawget(_G, "ChatFrameUtil")
        if link and chat and chat.InsertLink then chat.InsertLink(link) end
        Sound("UI_MAP_WAYPOINT_CHAT_SHARE")
    elseif button == "LeftButton" then
        local track = not Live.Tracked()
        C_SuperTrack.SetSuperTrackedUserWaypoint(track)
        Sound(track and "UI_MAP_WAYPOINT_SUPER_TRACK_ON" or "UI_MAP_WAYPOINT_SUPER_TRACK_OFF")
    end
end
Marks.Sound = Sound

function Marks.Build(canvasHolder)
    holder = canvasHolder
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    arrow = layer:CreateTexture(nil, "OVERLAY", nil, 7)
    arrow:SetAtlas("UI-WorldMapArrow")
    arrow:SetSize(Marks.ARROW, Marks.ARROW)
    arrow:Hide()
    pin = CreateFrame("Button", nil, layer)
    pin:SetSize(Marks.PIN, Marks.PIN)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    pin:SetHighlightAtlas("Waypoint-MapPin-Highlight", "ADD")
    pin:SetScript("OnClick", ns.Guard(Clicked))
    pin:SetScript("OnEnter", ns.Guard(Tip))
    pin:SetScript("OnLeave", GameTooltip_Hide)
    pin:Hide()
end

-- The layer at that frame level (the canvas' order, Canvas.lua: over the game's minimap), the pin over it.
function Marks.Stack(level)
    layer:SetFrameLevel(level)
    pin:SetFrameLevel(level + 1)
end

-- A point of a plane, at the view's place (the canvas' origin and zoom); nil when not linked.
local function Spot(view, map, u, v)
    local link = Coords.Link(map, view.map)
    if not link then return nil end
    return (link.du + link.su * u - view.u) * view.k, (link.dv + link.sv * v - view.v) * view.k
end

-- A mark at x, y (the holder's units, nil: none) reaching half units from its middle: placed there, and
-- shown while it lies wholly inside the canvas.
local function Put(mark, x, y, half)
    mark.x, mark.y, mark.half = x, y, half
    if not x then return mark:Hide() end
    mark:ClearAllPoints()
    mark:SetPoint("CENTER", holder, "CENTER", x, y)
    mark:SetShown(ns.Canvas.Inside(x, y, half))
end

-- The player's arrow: where the player is (map, u, v, facing from Live.Player), hidden when hidden is true.
function Marks.Player(view, map, u, v, facing, hidden)
    local x, y
    if not hidden and u then x, y = Spot(view, map, u, v) end
    if x and facing then arrow:SetRotation(facing) end
    Put(arrow, x, y, Marks.ARROW / 2)
end

-- The map pin, where the game has it.
function Marks.Pin(view)
    local map, x, y = Live.Waypoint()
    local home = map and Coords.PlaneOf(map)
    local u, v, px, py
    if home then u, v = Coords.MapToPlane(map, x, y, home) end
    if u then px, py = Spot(view, home, u, v) end
    if px then pin.icon:SetAtlas(Live.Tracked() and "Waypoint-MapPin-Tracked" or "Waypoint-MapPin-Untracked") end
    Put(pin, px, py, Marks.PIN / 2)
end

-- The party or raid where the game tells their places (on the view's plane's map), a few times a second.
function Marks.Group(view, now)
    if now < nextGroup then return end
    nextGroup = now + Marks.GROUP
    local count = 0
    local box = view.map and Coords.Box(view.map)
    if box and ns.Pins.Shows("group") and IsInGroup() then
        for _, member in ipairs(Live.Group(view.map)) do
            local u, v = Coords.ToPlane(box, member.x, member.y)
            count = count + 1
            local texture = members[count]
            if not texture then
                texture = layer:CreateTexture(nil, "ARTWORK")
                texture:SetAtlas(Marks.BLIP)
                texture:SetSize(Marks.MEMBER, Marks.MEMBER)
                members[count] = texture
            end
            local _, class = UnitClass(member.unit)
            local color = class and rawget(_G, "RAID_CLASS_COLORS") and RAID_CLASS_COLORS[class]
            if color then texture:SetVertexColor(color.r, color.g, color.b) else texture:SetVertexColor(1, 1, 1) end
            local size = Marks.MEMBER * ns.PinScale("group") -- the pin filter's slider
            texture:SetSize(size, size)
            Put(texture, (u - view.u) * view.k, (v - view.v) * view.k, size / 2)
        end
    end
    for index = count + 1, #members do Put(members[index], nil) end
end

-- A ping's mark, made the first time one more is needed: the game's minimap ping, its ring turning and its wave
-- growing out of its middle again and again, and the words under it.
local function PingMark()
    local mark = CreateFrame("Frame", nil, layer)
    mark:SetSize(Marks.PING, Marks.PING)
    local function Art(part, sublevel)
        local texture = mark:CreateTexture(nil, "OVERLAY", nil, sublevel)
        texture:SetTexture(Marks.PING_ART .. part)
        texture:SetAllPoints()
        return texture
    end
    Art("Center", 1)
    local ring, wave = Art("Rotate", 2), Art("Expand", 3)
    wave:SetBlendMode("ADD")
    mark.turn = ring:CreateAnimationGroup()
    mark.turn:SetLooping("REPEAT")
    local spin = mark.turn:CreateAnimation("Rotation")
    spin:SetDegrees(-360)
    spin:SetDuration(Marks.TURN)
    mark.grow = wave:CreateAnimationGroup()
    mark.grow:SetLooping("REPEAT")
    local size = mark.grow:CreateAnimation("Scale")
    size:SetScaleFrom(0.5, 0.5)
    size:SetScaleTo(1.3, 1.3)
    size:SetDuration(Marks.WAVE)
    local fade = mark.grow:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetDuration(Marks.WAVE)
    mark.name = mark:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark.name:SetPoint("TOP", mark, "BOTTOM", 0, 4)
    return mark
end

-- A ping's mark let go: out of sight, still.
local function Let(mark)
    mark.ping = nil
    mark.turn:Stop()
    mark.grow:Stop()
    Put(mark, nil)
end

-- The pings (Ping.lua) where they are on the view's plane, each fading out at its end; none where the game's
-- minimap shows over our map (it draws its own there). At each look of the canvas' tracker, and when one comes.
function Marks.Pings(view, now)
    local list = ns.Ping.List(now)
    for index, ping in ipairs(list) do
        local mark = pinged[index] or PingMark()
        pinged[index] = mark
        if mark.ping ~= ping then
            mark.ping = ping
            local Core, unit = SaneUI.Core, ping.unit
            local other = unit and Core.Ask(UnitIsUnit, unit, "player") == false
            mark.name:SetText(other and Core.FullName(unit) or "")
            local _, class = Core.Ask(UnitClass, unit)
            local color = other and class and rawget(_G, "RAID_CLASS_COLORS") and RAID_CLASS_COLORS[class]
            if color then mark.name:SetTextColor(color.r, color.g, color.b) else mark.name:SetTextColor(1, 0.82, 0) end
            mark.turn:Play()
            mark.grow:Play()
        end
        local x, y = Spot(view, ping.map, ping.u, ping.v)
        if x and ns.Hybrid.Covers(x, y) then x = nil end
        mark:SetAlpha(math.min(1, (ping.ends - now) / Marks.FADE))
        Put(mark, x, y, Marks.PING / 2)
    end
    for index = #list + 1, #pinged do
        if pinged[index].ping then Let(pinged[index]) end
    end
end

-- Each mark shown while it lies wholly inside the canvas' rectangle as it is now (Canvas.edge).
function Marks.Fit()
    if not arrow then return end
    local Inside = ns.Canvas.Inside
    for _, mark in ipairs({ arrow, pin }) do
        if mark.x then mark:SetShown(Inside(mark.x, mark.y, mark.half)) end
    end
    for _, texture in ipairs(members) do
        if texture.x then texture:SetShown(Inside(texture.x, texture.y, texture.half)) end
    end
    for _, mark in ipairs(pinged) do
        if mark.x then mark:SetShown(Inside(mark.x, mark.y, mark.half)) end
    end
end

-- Out of sight, all of them.
function Marks.Clear()
    if not arrow then return end
    Put(arrow, nil)
    Put(pin, nil)
    for _, texture in ipairs(members) do Put(texture, nil) end
    for _, mark in ipairs(pinged) do Let(mark) end
    nextGroup = 0
end
