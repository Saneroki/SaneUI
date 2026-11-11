local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Marks
--  What stands over the map, over the game's minimap too where it lies over ours (Hybrid.lua):
--
--      the player's arrow   Blizzard's world map arrow (UI-WorldMapArrow), turned to the facing; on
--                           the small map and the full one alike, at a fixed size on the screen (the
--                           game's own arrow, where it draws one, under it)
--      the map pin          the game's own (Waypoint-MapPin-Tracked / -Untracked, as its map's), at
--                           a fixed size; a click leads the game's arrow to it or not, Ctrl-click
--                           takes it away
--      the party, the raid  the game's party blip in each member's class colour, a few times a
--                           second while the map is shown (the pin filter's Party and raid), at
--                           every zoom, largest far out and smaller as the map zooms in
--                           (Marks.MEMBER; Saneroki, 2026-11-11: much bigger, with the zoom,
--                           always in sight, smaller when zoomed in closer); over the
--                           game's minimap too, there more often (Marks.OVER), so ours lie over
--                           its own dots of them, which it moves at each frame. Between two looks
--                           each glides at every frame from where it stands to the new place
--                           (Glide; Saneroki, 2026-11-11: smoother, no jumps)
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
Marks.MEMBER = { 44, 22 } -- a member of the party or raid: its side out at Marks.WIDE and farther, and at the
                          -- nearest zoom (Camera.NEAR), between them smaller by one step at each notch in
Marks.WIDE = 0.05  -- the zoom (the canvas' units per yard) out from which the members' marks are their largest:
                   -- about a continent whole on the full map
Marks.BLIP = "PlayerPartyBlip" -- 32 pixels of art, so as large as Marks.MEMBER's largest stays sharp
Marks.GROUP = 0.25 -- seconds between two looks at where the party is
Marks.OVER = 0.1   -- the same while the game's minimap shows: its own dots of them stay under ours
Marks.GLIDE = 1    -- seconds a member's mark takes at most to glide to the member's new place
Marks.LEAP = 200   -- yards: a member farther than this from its mark stands at its new place at once (a portal)

local Coords, Live, Plain = ns.Coords, ns.Live, SaneUI.Core.Plain
local layer, holder, arrow, pin
local pair         -- the arrow and the pin together, for Fit (made once with them: it runs every frame the player walks)
local members = {} -- the members' textures, made as many as needed; each knows where it glides (Aim)
local nextGroup = 0
local glider       -- a frame of the layer's whose OnUpdate glides the members' marks, set only while one is on its way
local gliding      -- whether it is set
local seen         -- the view the members' marks were placed in (Canvas.view)

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
    pair = { arrow, pin }
    glider = CreateFrame("Frame", nil, layer)
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

-- The player's arrow: where the player is (map, u, v, facing from Live.Player); none where the game tells no place.
function Marks.Player(view, map, u, v, facing)
    local x, y
    if u then x, y = Spot(view, map, u, v) end
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

-- A member's mark's side at the zoom k (the canvas' units per yard): Marks.MEMBER's first out from Marks.WIDE, its
-- second at the nearest zoom and nearer, between them the same step smaller at each notch in; the pin filter's
-- slider on top.
function Marks.MemberSize(k)
    local far, close = Marks.MEMBER[1], Marks.MEMBER[2]
    local near = math.log(math.max(k or 0, Marks.WIDE) / Marks.WIDE) / math.log(ns.Camera.NEAR / Marks.WIDE)
    return far * (close / far) ^ math.min(near, 1) * ns.PinScale("group")
end

-- A mark on its way moved on to where it is at the time now; true while it is not there yet.
local function Along(mark, now)
    if not mark.span then return false end
    local part = math.max(0, math.min((now - mark.start) / mark.span, 1))
    mark.u = mark.fromU + (mark.toU - mark.fromU) * part
    mark.v = mark.fromV + (mark.toV - mark.fromV) * part
    if part < 1 then return true end
    mark.span = nil
    return false
end

-- A member's new place (u, v on the plane; who: the member) at the time now: its mark glides there from where it
-- stands, over the time since the place last changed, as long as the time to the next look (interval) at least and
-- Marks.GLIDE at most, so one the game tells of only now and then glides on all the while. At once where the mark
-- stood for another member, on another plane or nowhere, or lies farther than Marks.LEAP.
local function Aim(mark, u, v, who, plane, now, interval)
    Along(mark, now)
    local du, dv = mark.u and u - mark.u, mark.v and v - mark.v
    if mark.who ~= who or mark.plane ~= plane or not du or du * du + dv * dv > Marks.LEAP * Marks.LEAP then
        mark.who, mark.plane, mark.u, mark.v, mark.toU, mark.toV = who, plane, u, v, u, v
        mark.span, mark.changed = nil, now
    elseif u ~= mark.toU or v ~= mark.toV then
        mark.fromU, mark.fromV, mark.toU, mark.toV = mark.u, mark.v, u, v
        mark.start, mark.span = now, math.min(math.max(now - mark.changed, interval), Marks.GLIDE)
        mark.changed = now
    end
end

-- The glider's OnUpdate: the marks on their way moved on at each frame (Marks.Glide).
local stepping = ns.Guard(function() Marks.Glide(GetTime()) end)

-- The members' marks at the time now: each on its way moved on along it and placed (shown while wholly inside the
-- canvas: Put); with all, every one placed anew (a look at the party, the view laid out anew). The glider runs
-- while one is still on its way.
function Marks.Glide(now, all)
    local moving = false
    for _, mark in ipairs(members) do
        local span = mark.who and mark.span
        if span and Along(mark, now) then moving = true end
        if mark.who and (span or all) then
            Put(mark, (mark.u - seen.u) * seen.k, (mark.v - seen.v) * seen.k, mark.side / 2)
        end
    end
    if moving ~= (gliding or false) then
        gliding = moving
        if moving then glider:SetScript("OnUpdate", stepping) else glider:SetScript("OnUpdate", nil) end
    end
end

-- Each member's mark aimed where the game tells at the time now, at the view's zoom (Marks.Group).
local function Members(view, now, interval)
    seen = view
    local count = 0
    local box = view.map and Coords.Box(view.map)
    if box and ns.Pins.Shows("group") and IsInGroup() then
        local size = Marks.MemberSize(view.k)
        for _, member in ipairs(Live.Group(view.map)) do
            local u, v = Coords.ToPlane(box, member.x, member.y)
            count = count + 1
            local texture = members[count]
            if not texture then
                texture = layer:CreateTexture(nil, "ARTWORK")
                texture:SetAtlas(Marks.BLIP)
                members[count] = texture
            end
            local _, class = UnitClass(member.unit)
            local color = class and rawget(_G, "RAID_CLASS_COLORS") and RAID_CLASS_COLORS[class]
            if color then texture:SetVertexColor(color.r, color.g, color.b) else texture:SetVertexColor(1, 1, 1) end
            texture:SetSize(size, size)
            texture.side = size
            Aim(texture, u, v, Plain(UnitGUID(member.unit)) or member.unit, view.map, now, interval)
        end
    end
    for index = count + 1, #members do
        members[index].who = nil
        Put(members[index], nil)
    end
    Marks.Glide(now, true)
end

-- The party or raid where the game tells their places (on the view's plane's map), asked a few times a second at
-- the canvas' tracker's steps (now), more often while the game's minimap shows (Marks.OVER): it moves its own dots of
-- them at each frame, and ours, larger, lie over them; without a time at once (the view laid out anew, at another
-- zoom: Canvas.lua). Between two looks the marks glide (Marks.Glide).
function Marks.Group(view, now)
    if now and now < nextGroup then return end
    local time = now or GetTime()
    local interval = ns.Hybrid.Shown() and Marks.OVER or Marks.GROUP
    nextGroup = time + interval
    Members(view, time, interval)
end

-- Each mark of a list shown while it lies wholly inside the canvas' rectangle as it is now (Canvas.edge).
local function Fit(list)
    local Inside = ns.Canvas.Inside
    for _, mark in ipairs(list) do
        if mark.x then mark:SetShown(Inside(mark.x, mark.y, mark.half)) end
    end
end

-- The canvas moved (Canvas.lua): every mark kept inside it.
function Marks.Fit()
    if not arrow then return end
    Fit(pair)
    Fit(members)
end

-- Out of sight, all of them.
function Marks.Clear()
    if not arrow then return end
    Put(arrow, nil)
    Put(pin, nil)
    for _, texture in ipairs(members) do
        texture.who = nil
        Put(texture, nil)
    end
    Marks.Glide(GetTime())
    nextGroup = 0
end
