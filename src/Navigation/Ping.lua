local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Ping
--  The game's minimap ping, on our map. The game has one way to show the party
--  and raid a place: its minimap's ping (Minimap:PingLocation), which every
--  member sees on their minimap, the one who pinged too (the event MINIMAP_PING:
--  who, and where on their minimap, as a share of its width and of its height
--  from its middle). Knows no frames of ours.
--
--      sent        a plain click on our map where it opens nothing (Canvas.lua), or on a herb or ore found
--                  (Found.lua): the place's yards from the player, in the game's minimap's units, as a click on
--                  the game's minimap there would ping; where its view does not reach so far, at a wider step
--                  of its own for the moment (Hybrid.PingAt). The game pings only inside its view: past its
--                  widest, none. Sent once the time of a double click has passed without a second (Soon): a
--                  double click puts the game's map pin there instead, and takes the ping back (Cancel)
--      received    each ping a mark on our map at its place for Ping.TIME seconds (Marks.lua): its yards from
--                  the player at the game's minimap's zoom then, put on our plane; the game's minimap draws its
--                  own where it shows (Hybrid.Covers), the sound is the game's. MINIMAP_PING is one of the
--                  game's callback events: no frame can register it (RegisterEvent refuses it), only the
--                  game's RegisterEventCallback takes it, as Blizzard's minimap does (Listen)
--
--  The game's minimap turns with the player where the game's setting says so and it is the game's own (ours
--  holds it north up, Hybrid.lua); a ping's place is turned with it, both ways.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Ping = {}
ns.Ping = Ping

Ping.TIME = 5     -- seconds a ping stands on the map
Ping.DOUBLE = 0.3 -- a second click so many seconds after the first is a double click (Canvas.lua's too)

local pings = {} -- the pings shown: { map, u, v (its place on a plane), unit (who pinged), ends (when it goes) }

-- How far the game's minimap is turned now (radians, counter-clockwise): the player's facing while it turns with
-- the player, else none.
local function Turned()
    if ns.Hybrid.Taken() or Core.Ask(rawget(_G, "GetCVarBool"), "rotateMinimap") ~= true then return 0 end
    return Core.Plain(Core.Ask(GetPlayerFacing)) or 0
end

-- Pings a place of a plane (map: the plane; u, v: its yards east and north) to the group, as a click on the game's
-- minimap there does. False where the game cannot: the player's place not known on that plane, the place past the
-- game's minimap's widest view.
function Ping.Send(map, u, v)
    local here, pu, pv = ns.Live.Player()
    if not pu or here ~= map then return false end
    local east, north = u - pu, v - pv
    local turn = Turned()
    local cos, sin = math.cos(turn), math.sin(turn)
    return ns.Hybrid.PingAt(east * cos + north * sin, north * cos - east * sin)
end

-- The ping a click owes, sent once Ping.DOUBLE has passed and no double click took it back: { map, u, v } a place of
-- a plane (Send), { x, y } a point of the game's minimap from its middle where it is the map alone (an instance:
-- Hybrid.Ping). A newer click's ping takes its place.
local owed
function Ping.Soon(ping)
    owed = ping
    C_Timer.After(Ping.DOUBLE, ns.Guard(function()
        if owed ~= ping then return end
        owed = nil
        if ping.map then Ping.Send(ping.map, ping.u, ping.v) else ns.Hybrid.Ping(ping.x, ping.y) end
    end))
end

-- The ping owed is not sent: the click was the first of a double click.
function Ping.Cancel()
    owed = nil
end

-- A ping from the group (or one's own): its place on the player's plane, kept for Ping.TIME seconds. Its place may be
-- a secret in a fight (the event's own rule): then none.
local function Pinged(unit, x, y)
    if ns.off then return end
    x, y = Core.Plain(x), Core.Plain(y)
    local radius = Core.Plain(Core.Ask(C_Minimap.GetViewRadius))
    local map, pu, pv = ns.Live.Player()
    if type(x) ~= "number" or type(y) ~= "number" or type(radius) ~= "number" or radius <= 0 or not pu then return end
    -- Yards on the game's minimap from its middle, the player: its whole width is twice its radius.
    local right, up = x * 2 * radius, y * 2 * radius
    local turn = Turned()
    local cos, sin = math.cos(turn), math.sin(turn)
    local east, north = right * cos - up * sin, right * sin + up * cos
    pings[#pings + 1] = { map = map, u = pu + east, v = pv + north, unit = Core.Plain(unit), ends = GetTime() + Ping.TIME }
    ns.Fire("LIVE", "ping")
end
-- The game's callback for MINIMAP_PING, guarded (its first value is the callback's owner: none); a client without
-- callback events would tell it as a frame's event.
local function Listen()
    local register = rawget(_G, "RegisterEventCallback")
    if not register then return ns.On("MINIMAP_PING", Pinged) end
    local heard = ns.Guard(function(_, unit, x, y) Pinged(unit, x, y) end)
    if not pcall(register, "MINIMAP_PING", heard) then
        Core.NoteError("event MINIMAP_PING", "the game took no callback for it; the group's pings are off")
    end
end
Listen()

-- The pings still shown at now (GetTime), oldest first; those gone are let go.
function Ping.List(now)
    for index = #pings, 1, -1 do
        if pings[index].ends <= now then table.remove(pings, index) end
    end
    return pings
end
