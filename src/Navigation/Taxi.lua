local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Taxi
--  At a flight master, our full map in place of the game's flight map
--  (Saneroki, 2026-11-10): "if you open it normally it shows our own fullscreen
--  map instead but where the flightpath icons are huge and you can click them to
--  fly there like the normal flightpath window"; Shift held as it opens: the
--  game's own, as always ("shiftclicking will open it normally").
--
--      the game's   opens its flight map as always (TaxiFrame, or FlightMapFrame where its map asks for that one),
--                   by its own code; a hook after its OnShow makes it tiny and clear (Core.Lend: never hidden, its
--                   OnHide would end the talk; Doc/guides/windows.md, The holder), and our map fills the screen as
--                   it always does (Window.OpenTo: both continents, its views, every pin, the quest log; Saneroki,
--                   2026-11-11: "the exact same map as our normal fullscreen map ... just with the extra big
--                   flightpaths"; never at the master's own map, Forever's flight maps being maps of their own:
--                   1463, 1464, 2665), zoomed out to the world whole ("fully zoomed out to max level where we can
--                   see both continents"; Retail: at the master's map, one of its map tree). Its OnHide (a flight taken, the master left) gives it back as it was, and our
--                   map goes back to its corner
--      the pins     the flight points as the master tells them (C_TaxiMap.GetAllTaxiNodes of its map), Taxi.SIZE
--                   large, over every other pin and never gathered (Pins.lua, PinView.lua): the one you stand at
--                   glowing, those you can fly to taken by a click (TakeTaxiNode, as the game's buttons do), the
--                   rest red, as a flight point not found yet is on the map; at each one's right its name and price
--                   (Taxi.Label, PinView.LABEL: sized by the zoom, under every pin); the tooltip what the flight costs (TaxiNodeCost, Core.Coins); the mouse on one draws
--                   its way there hop by hop (GetNumRoutes, TaxiGetNodeSlot; each hop's path from Core's set
--                   Travel, else straight between the two flight points as their continent's map has them: Paths.lua)
--      ours closed  (Esc, back to the corner) while the master is open: the game's closes too (CloseTaxiMap)
--
--  Whatever the switch Show the game's map says (the world map's). No frames of its own.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Taxi = {}
ns.Taxi = Taxi

Taxi.SIZE = 40                                   -- units a flight point is on our map at a flight master
Taxi.FRAMES = { "TaxiFrame", "FlightMapFrame" }  -- the game's flight maps
Taxi.ADDON = "Blizzard_FlightMap"                -- FlightMapFrame's addon, loaded when the game first wants it

local Travel = Core.Data.Set("Travel")
local hooked = {}  -- [frame] = true: its OnShow and OnHide followed
local open         -- the game's flight map ours stands in for now, nil while none
local lent         -- its lend (tiny and clear)
local closing      -- ours is closing it (CloseTaxiMap): our map is on its way back already
local nodes = {}   -- [node ID] = { slot, current, reachable, cost }, as the master told them when it opened
local map          -- the flight master's map (GetTaxiMapID): a map of its own in Forever, only asked for its nodes

function Taxi.On()
    return open ~= nil
end

-- A flight point as the master tells it, while ours stands in for its map; nil else.
function Taxi.Node(node)
    return open and node and nodes[node] or nil
end

-- What the master tells: each flight point's slot, state and cost.
local function Read()
    wipe(nodes)
    map = Core.Plain(Core.Ask(rawget(_G, "GetTaxiMapID")))
    local list = map and Core.Ask(C_TaxiMap.GetAllTaxiNodes, map)
    local states = rawget(_G, "Enum") and Enum.FlightPathState or {}
    local cost = rawget(_G, "TaxiNodeCost")
    for _, info in ipairs(type(list) == "table" and list or {}) do
        local node, slot, state = Core.Plain(info.nodeID), Core.Plain(info.slotIndex), Core.Plain(info.state)
        if node and slot then
            local entry = { slot = slot, current = state == (states.Current or 0), reachable = state == (states.Reachable or 1) }
            local copper = entry.reachable and cost and Core.Plain(Core.Ask(cost, slot))
            entry.cost = type(copper) == "number" and copper or nil
            nodes[node] = entry
        end
    end
end

-- A flight point's tooltip lines: you are here; what the flight costs and that a click takes it; or none from here.
function Taxi.Lines(node)
    local entry = Taxi.Node(node)
    if not entry then return nil end
    local text = ns.TEXT
    if entry.current then return { { text.taxiHere, 0.2, 1, 0.2 } } end
    if not entry.reachable then return { { text.taxiFar, 0.6, 0.6, 0.6 } } end
    local lines = {}
    local coins = entry.cost and Core.Coins(entry.cost)
    if coins and entry.cost > 0 then lines[1] = coins end
    lines[#lines + 1] = { text.taxiFly, 0.5, 0.5, 0.5 }
    return lines
end

-- A flight point's name and what the flight there costs (where it is flown to from here), for its pin's right
-- (PinView.lua); nil where it is no flight point of the master's.
function Taxi.Label(node, name)
    local entry = Taxi.Node(node)
    if not entry or type(name) ~= "string" then return nil end
    local coins = entry.reachable and entry.cost and entry.cost > 0 and Core.Coins(entry.cost)
    return coins and (name .. "  " .. coins) or name
end

-- A click on a flight point: the flight there, where the master flies; true where the click is ours (a flight point
-- at a flight master), the flight or none.
function Taxi.Fly(node)
    local entry = Taxi.Node(node)
    if not entry then return false end
    if entry.reachable then TakeTaxiNode(entry.slot) end
    return true
end

-- Where each flight point stands in a plane, as its continent's map has them (the game's: Live.Flights): [node] = u, v.
local function Places(plane)
    local found = {}
    for _, info in ipairs(ns.Live.Flights(plane)) do
        local position, node = info.position, Core.Plain(info.nodeID)
        local x, y = type(position) == "table" and Core.Plain(position.x), type(position) == "table" and Core.Plain(position.y)
        if node and type(x) == "number" and type(y) == "number" then
            local u, v = Coords.MapToPlane(plane, x, y, plane)
            if u then found[node] = { u = u, v = v } end
        end
    end
    return found
end

-- A hop's way: its flight's path from Core's set Travel, else straight from the one flight point to the other (places).
local function Hop(a, b, plane, places)
    for _, key in ipairs(Travel:Keys("byFromNode", a)) do
        local flight = Travel:Get(key)
        if flight and flight.kind == "flight" and flight.toNode == b and type(flight.path) == "table" and #flight.path >= 2 then
            return { kind = "flight", points = ns.Paths.FromPath(flight.path, plane) }
        end
    end
    local from, to = places[a], places[b]
    if not (from and to) then return nil end
    return { kind = "flight", points = { { map = plane, u = from.u, v = from.v }, { map = plane, u = to.u, v = to.v } } }
end

-- The way from where one stands to a flight point, hop by hop as the master flies it (Paths.lua draws it), in the plane
-- of the map its pin stands on (pinMap); nil where it is no flight point of the master's, or the one one stands at.
function Taxi.Ways(node, pinMap)
    local entry = Taxi.Node(node)
    local plane = pinMap and Coords.PlaneOf(pinMap)
    if not entry or entry.current or not entry.reachable or not plane then return nil end
    local places = Places(plane)
    local bySlot = {}
    for id, each in pairs(nodes) do bySlot[each.slot] = id end
    local hops, ways = Core.Plain(Core.Ask(rawget(_G, "GetNumRoutes"), entry.slot)) or 0, {}
    for hop = 1, hops do
        local a = bySlot[Core.Plain(Core.Ask(TaxiGetNodeSlot, entry.slot, hop, true))]
        local b = bySlot[Core.Plain(Core.Ask(TaxiGetNodeSlot, entry.slot, hop, false))]
        local way = a and b and Hop(a, b, plane, places)
        if way then ways[#ways + 1] = way end
    end
    return ways
end

-- The game's flight map opened (a hook after its OnShow): ours in its place, unless Shift is held or the module stands
-- down. Whatever the switch Show the game's map says: that one is the world map's (Saneroki, 2026-11-11, his game's map
-- on: "the flightmaster still opens only the native window normally").
local function Opened(frame)
    if open or ns.off or Core.Plain(IsShiftKeyDown()) then return end
    local made = Core.Lend(frame)
    if not (made:SetScale(Core.Holder.TINY) and made:SetAlpha(0)) then
        made:Return()
        return
    end
    open, lent, closing = frame, made, false
    Read()
    ns.Pins.Changed("flights")
    -- The full map as always, zoomed out to the world whole: both continents (Saneroki, 2026-11-11). Never at the
    -- master's own map in Forever (a map of its own); Retail's one map at a time shows no flight point at its world
    -- map, so there the master's map, one of its tree.
    ns.Window.OpenTo(Core.RETAIL and map or Coords.WorldMap())
end

-- The game's flight map closed (a flight taken, the master left, ours closed): given back as it was, the flight points
-- as they always are, our map back to its corner.
local function Closed(frame)
    if frame ~= open then return end
    local had, going = lent, closing
    open, lent, closing, map = nil, nil, false, nil
    wipe(nodes)
    ns.Pins.Changed("flights")
    ns.Safe("paths", ns.Paths.Hide)
    if not going then ns.Safe("taxi", ns.Window.Back) end
    if had then had:Return() end
end

-- Our map on its way back to its corner (Window.lua): the game's flight map closes too.
function Taxi.Filled(on)
    if on or not open or closing then return end
    closing = true
    CloseTaxiMap()
end

local function Hook(frame)
    if not frame or hooked[frame] or type(frame.HookScript) ~= "function" then return end
    hooked[frame] = true
    frame:HookScript("OnShow", ns.Guard(Opened))
    frame:HookScript("OnHide", ns.Guard(Closed))
end

function Taxi.Start()
    for _, name in ipairs(Taxi.FRAMES) do Hook(rawget(_G, name)) end
    local util = rawget(_G, "EventUtil")
    if util and util.ContinueOnAddOnLoaded then
        util.ContinueOnAddOnLoaded(Taxi.ADDON, ns.Guard(function() Hook(rawget(_G, "FlightMapFrame")) end))
    end
end

-- The module stands down (ns.GiveBack): the game's flight map in sight again, open as it is.
function Taxi.GiveBack()
    local had = lent
    open, lent, closing = nil, nil, false
    wipe(nodes)
    if had then had:Return() end
end
