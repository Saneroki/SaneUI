local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Ping
--  The game's minimap ping, from our map. The game has one way to show the party
--  and raid a place: its minimap's ping (Minimap:PingLocation), which every
--  member sees on their minimap. Knows no frames of ours.
--
--  A plain click on our map where it opens nothing (Canvas.lua), or on a herb or
--  ore found (Found.lua), pings there: the place's yards from the player, in the
--  game's minimap's units, as a click on the game's minimap there would ping;
--  where its view does not reach so far, at a wider step of its own for the moment
--  (Hybrid.PingAt). The game pings only inside its view: past its widest, none.
--  Sent at once, in the click itself: the game takes a ping only from the click
--  that asks for it (from a timer it blocks it as an action of its own), so the
--  first click of a double click (the map pin, Canvas.lua) pings too.
--
--  The pings that come (the group's, one's own) are not ours to hear: MINIMAP_PING
--  is one of the game's callback events with restrictions, which no frame can
--  register and whose callback the game blocks for an addon (seen 2026-10-23: a
--  blocked action at every login). The game's minimap draws them where it lies
--  over our map (Hybrid.lua), as it does on its own.
--
--  The game's minimap turns with the player where the game's setting says so and
--  it is the game's own (ours holds it north up, Hybrid.lua); a ping's place is
--  turned with it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Ping = {}
ns.Ping = Ping

-- How far the game's minimap is turned now (radians, counter-clockwise): the player's facing while it turns with
-- the player, else none.
local function Turned()
    if ns.Hybrid.Taken() or Core.Ask(rawget(_G, "GetCVarBool"), "rotateMinimap") ~= true then return 0 end
    return Core.Plain(Core.Ask(GetPlayerFacing)) or 0
end

-- Pings a place of a plane (map: the plane; u, v: its yards east and north) to the group, as a click on the game's
-- minimap there does; only in a click's own handler (above). False where the game cannot: the player's place not
-- known on that plane, the place past the game's minimap's widest view.
function Ping.Send(map, u, v)
    local here, pu, pv = ns.Live.Player()
    if not pu or here ~= map then return false end
    local east, north = u - pu, v - pv
    local turn = Turned()
    local cos, sin = math.cos(turn), math.sin(turn)
    return ns.Hybrid.PingAt(east * cos + north * sin, north * cos - east * sin)
end
