local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Window
--  The map's window, one of Core's (kind screen): docked in the screen's top
--  right corner, where the game's minimap was, and filling the screen when the
--  mouse goes into that corner (Edge.lua); the corner again, Esc or its close
--  button brings it back. Small it is the minimap, full the map: the same map,
--  drawn and handled the same way (Canvas.lua), only larger, as the chat window
--  is the same chat when it fills the screen.
--
--  Each view keeps its own camera: its zoom, its place, whether it follows the
--  player. Going full screen and back returns each to where it was. Full, the
--  map takes the whole screen, the quest log is a window of its own over it
--  (QuestLog.lua; in or out by the bar's button, kept; pinned, on the screen
--  while the map is small too), and a bar over the map's top edge holds the
--  views, the map selector, the dungeons and the pin filter (TopBar.lua); a
--  dungeon chosen there, or the one the player is in when the map fills the
--  screen, shows over the map (Dungeons.lua); in the middle of the title bar
--  the map's search (FindBox.lua, Find.lua); the dropdown Classic
--  windows in the title bar offers the game's own minimap and map, each a kept
--  choice (the switches Show the game's minimap, Show the game's map), ticked
--  while chosen and chosen again to come back.
--
--  Small, its corner away from the screen's edges sizes it (Core's grip, there
--  while the mouse is on the map, outside Edit Mode too); the size is kept.
--
--  With the game's own minimap chosen the small window rests out of sight (Rest):
--  the game's minimap stands in its place and takes the mouse, and the corner
--  still fills the screen with our map, which goes back out of sight when it
--  comes back. In Edit Mode it is in sight, to be arranged.
--
--  On its way to the full screen and back the map goes with the window (Core's
--  option moving): laid out once at the start for the view it comes to, scaled
--  and moved on each step from the view it leaves (Canvas.Morph); laid out anew
--  once the window stands (Core's docked hook).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Window = {}
ns.Window = Window

Window.WIDTH, Window.HEIGHT = 200, 200 -- small, about as large as the game's minimap

local frame, handle, inside, canvas
local resting = false -- out of sight: the game's own minimap is chosen (Rest)
local going           -- on the way: true to the full screen, false back, nil standing
local aimed = false   -- the full view was just set to a map the game was asked for (OpenTo): it opens there
local small, full = ns.Camera.New(), ns.Camera.New() -- each view's camera
Window.small, Window.full = small, full

-- The views' buttons (TopBar.lua) as the views offered say (Navigation.lua, Offer).
function Window.Arrange()
    ns.TopBar.Arrange()
end

-- The view chosen changed (its button, or the settings): the buttons, and the map drawn anew.
function Window.Restyle()
    if not frame then return end
    ns.TopBar.Arrange()
    ns.Canvas.Refresh()
    ns.Safe("dungeons", ns.Dungeons.Restyle) -- a dungeon's floor shown over the map: drawn in the view too
end

-- Whether the small window rests out of sight: the game's own minimap is chosen, the window is in its zone
-- (not full, nor on its way) and Edit Mode is closed.
local function Sleeping()
    local edge = handle.edge
    return ns.options.nativeMinimap and not (edge and edge.away) and not Core.EditMode.active or false
end

-- Out of sight and letting the mouse through to the game's minimap (on), or in sight and taking it.
local function Rest(on)
    resting = on
    frame:SetAlpha(on and 0 or 1)
    ns.Canvas.Mouse(not on)
    if on then ns.Canvas.Close() end
    handle:Hover(false) -- resting, its grip goes too
end

-- The canvas' size once the window fills the screen: all of it, the title bar over the map (Saneroki, 2026-11-15:
-- "Let the map view go to the very top behind the titlebar so it is truely fullscreen").
function Window.FullSize()
    return UIParent:GetWidth(), UIParent:GetHeight()
end

-- The window stands, small or full: that view's camera, and the map at its size; small with the game's own
-- minimap chosen, out of sight. Full, the quest log at the left and the bar over the map.
local function Placed()
    going = nil
    local filled = handle.edge and handle.edge.full or false
    ns.Canvas.Use(filled and full or small)
    ns.QuestLog.Lay(filled)
    ns.TopBar.SetShown(filled, canvas)
    ns.Safe("map search", ns.FindBox.SetShown, filled, handle) -- the search in the title bar (FindBox.lua)
    if not filled then
        ns.Dungeons.Close()
    elseif not ns.Dungeons.Shown() then
        local here = ns.Dungeons.Here() -- inside a dungeon: its map at once
        if here then ns.Dungeons.Show(here) end
    end
    ns.Satchel.Place(not filled and not ns.options.nativeMinimap)
    if Sleeping() then return Rest(true) end
    if resting then Rest(false) end
    ns.Canvas.Open()
end

-- The quest log in or out while the window stands full (TopBar's button); a dungeon's map fitted anew beside it.
function Window.Lay()
    if not frame or going ~= nil or not (handle.edge and handle.edge.full) then return end
    ns.QuestLog.Lay(true)
    ns.Safe("dungeons", ns.Dungeons.Refit)
    ns.TopBar.Update()
end

-- On its way to the full screen (full) or back, the window to be width x height: the map goes with it,
-- into the other view's camera; the quest log, the bar and a dungeon's map wait until it stands. Resting, it comes
-- into sight first. With the full map's box Follow me ticked, it
-- opens on the player (but at a map the game was asked for).
local function Filled(on, width, height)
    ns.Safe("taxi", ns.Taxi.Filled, on) -- back to the corner at a flight master: its map closes too
    if not on then ns.Safe("paths", ns.Paths.Reset) end -- the ways kept drawn let go
    if resting then Rest(false) end
    ns.Satchel.Place(false)
    if on and not aimed then ns.Canvas.Center(full) end
    aimed = false
    going = on
    ns.TopBar.SetShown(false)
    ns.Safe("map search", ns.FindBox.SetShown, false)
    ns.Dungeons.Close()
    ns.Canvas.Morph(on and full or small, width or 0, height or 0) -- (full, the title bar stands over the map)
end

local function Moving(share)
    ns.Canvas.Step(share)
end

local function Back()
    if handle.edge then handle.edge:Fill(false) end
end

-- The full screen, from the corner (the map's search, FindBox.lua: its key, /sane map find); shown first if hidden.
function Window.Full()
    if not handle or not handle.edge then return end
    if not frame:IsShown() then
        frame:Show()
        handle:Place()
    end
    if not handle.edge.full then handle.edge:Fill(true) end
end

-- The full screen back to its corner (Taxi.lua: the flight master left, a flight taken).
function Window.Back()
    if handle and handle.edge and handle.edge.full then Back() end
end

-- The dropdown Classic windows: the game's own minimap and map, each kept (its switch), ticked while chosen;
-- chosen again, ours is the one again. The game's map chosen opens by its own key or button (never by our
-- code: Native.lua), and its key is told (Core.Classic.Press), as the other modules' windows of the game's are.
local function Keep(key, on)
    ns.Safe("classic window", Core.Set, ns.name, key, on)
end
-- The button Sane UI on the game's minimap (at its top right) and on its map (beside the close button on its
-- border, a secure button that clicks it): ours again, the map filling the screen (Core's Classic.lua). Only
-- while that window is the game's own (its switch) and the module runs: on the game's minimap inside our map,
-- or on the game's map caught for the frame before it is hidden, it would only be in the way.
local function GameMinimap() return not ns.off and ns.options.nativeMinimap end
local function GameMap() return not ns.off and ns.options.nativeMap end
local function Border() local map = rawget(_G, "WorldMapFrame") return map and map.BorderFrame end
local CLASSIC = {
    { text = ns.TEXT.classicMinimap, checked = function() return ns.options.nativeMinimap end,
      show = function() Keep("nativeMinimap", true) end, back = function() Keep("nativeMinimap", false) end,
      frame = "Minimap", plain = true, ready = GameMinimap, hide = function() end,
      anchor = function(button, minimap) button:SetPoint("TOPRIGHT", minimap, "TOPRIGHT") end },
    { text = ns.TEXT.classicMap, checked = function() return ns.options.nativeMap end,
      show = function()
          Keep("nativeMap", true)
          Core.Classic.Press(ns.TEXT.classicMap, "TOGGLEWORLDMAP") -- its key, now the game's again, opens it
      end,
      back = function() Keep("nativeMap", false) end,
      frame = Border, full = true, ready = GameMap },
}

function Window.Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("LOW") -- the game's minimap's layer: the queue's eye and the game's bars stand over it
    Window.frame = frame
    inside = CreateFrame("Frame", nil, frame)
    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options, content = inside, classic = CLASSIC,
        under = true, untitled = true, -- full, the map under the title bar, which holds its controls (TopBar.lua)
        first = { dock = "TOPRIGHT", width = Window.WIDTH, height = Window.HEIGHT },
        minWidth = Window.WIDTH / 2, minHeight = Window.HEIGHT / 2,
        grip = "hover", usable = function() return not resting end,
        docked = function() ns.Guarded(Placed) end,
        filled = function(on, width, height) ns.Guarded(Filled, on, width, height) end,
        moving = function(share) ns.Guarded(Moving, share) end,
        close = function() ns.Guarded(Back) end, -- back to its corner: closed, the corner could not bring it again
    })
    Window.handle = handle
    inside:SetAllPoints(handle.inside)
    canvas = ns.Canvas.Build(inside)
    ns.Satchel.Build(canvas)
    ns.Dungeons.Build(canvas)
    ns.TopBar.Build(canvas)
    ns.QuestLog.Build()
    ns.QuestLog.Lay(false)
    Window.Arrange()
    handle:Place() -- where it was left; at its first place and size if it never was moved
    -- Edit Mode shows a resting window, to be arranged, and lets it rest again once it closes.
    Core.EditMode.Watch(function() ns.Guarded(Window.Update) end)
end

-- The switch Show the game's minimap changed, or Edit Mode opened or closed: the small window rests out of
-- sight or comes back, as they say now (full, it is as it is: it rests once it is back).
function Window.Update()
    if not frame or (handle.edge and handle.edge.away) then return end
    if Sleeping() ~= resting then Placed() end
end

-- The mouse is on the map, or has left it (Canvas.lua): the grip that sizes the small window is seen while it is.
function Window.Hovered(on)
    if handle then handle:Hover(on) end
    ns.Safe("satchel", ns.Satchel.Hover, on) -- the small map's face: its time, place and satchel
end

-- The game's minimap is ours now (Hybrid.lua): the small view starts at its zoom step, as the player had it.
function Window.Native(step)
    if not small.native then
        small.native = step
        ns.Canvas.Refresh()
    end
end

-- The full screen and back (the game's map key, /sane map); shown first if hidden (the minimap key).
function Window.Toggle()
    if not handle or not handle.edge then return end
    if not frame:IsShown() then
        frame:Show()
        handle:Place()
        return handle.edge:Fill(true)
    end
    handle.edge:Fill(not handle.edge.full)
end

-- Our map at a map the game was asked for (Native.lua): full screen, the map whole in it; x, y (0 to 1 on
-- it): that point in the middle (a quest's place, QuestLog.lua).
function Window.OpenTo(map, x, y)
    if not handle or not handle.edge then return end
    if not frame:IsShown() then
        frame:Show()
        handle:Place()
    end
    if map then
        local width, height = Window.FullSize()
        ns.Canvas.Fit(full, map, width, height)
        aimed = true
        local plane = x and ns.Coords.PlaneOf(map)
        if plane and plane == full.map then
            local u, v = ns.Coords.MapToPlane(map, x, y, plane)
            if u then full:Look(u, v) end
        end
    end
    if handle.edge.full then
        ns.Canvas.Use(full)
        ns.Canvas.Refresh()
    else
        handle.edge:Fill(true)
    end
end

-- The game's minimap key: the window shown or hidden (hidden, it lets go of every texture).
function Window.ToggleShown()
    if not frame or resting then return end
    if frame:IsShown() then
        ns.Canvas.Close()
        ns.Satchel.Close()
        frame:Hide()
    else
        frame:Show()
        handle:Place() -- laid out again (Core's docked hook)
    end
end

-- /sane map reset: its first place and size.
function Window.Reset()
    if handle then handle:Reset() end
end

-- The module stood down (GiveBack): the window goes.
function Window.Hide()
    if not frame then return end
    ns.Safe("paths", ns.Paths.Reset)
    ns.Canvas.Close()
    ns.Dungeons.Close()
    ns.QuestLog.Hide()
    ns.Safe("map search", ns.FindBox.Hide)
    frame:Hide()
end
