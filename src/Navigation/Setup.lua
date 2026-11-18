local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Setup
--  The map's setup, step by step (Saneroki, 2026-11-18: "make a onboarding
--  window for the navigation module"). The module's own words and samples,
--  handed to Core (Core.Onboarding.Add); the window is the addon Onboarding's,
--  read only when it opens: by itself the first time the module is on, from
--  the module's options page (Set up step by step), or /sane setup navigation
--  (/sane setup map).
--
--  The steps, in Saneroki's order, each a few short lines that start with
--  gold words, its switches and a board drawn on the window's solid grey box:
--    intro    what this is: the minimap is the map, small in its corner, the
--             whole screen when you want it
--    corner   the hot corner, one of the first (Saneroki: "people should move
--             their mouse into the corner of the minimap to open the map full
--             screen and closing it the same way. The other way would be to
--             do the same but requires a click in the corner"): the mouse
--             into it, or a click in it (expandClick, as round buttons); the
--             big arrow points into the real corner meanwhile (below)
--    keys     "The 3rd would be to use the keybind": SaneUI's map, the
--             game's map (Native.lua: once ours has a key, the game's map key
--             opens the game's), the map's search; "Remind people that it is
--             possible to use a combination of things"
--    move     Edit Mode moves the map, and its hot corner with it; the big
--             arrow shows where it is now
--    quests   the quest log: a click opens a quest, a double click puts a
--             route to it
--    map      on the map: a double click puts the pin there with a route to
--             it, a right click often offers more; the wheel zooms
--
--  The big arrow (Saneroki: "Show a very big clear arror during the onbarding
--  on the corner so people know that they should move the mouse all the way
--  into the corner"): the game's tutorial arrow and its glow (NPE_ArrowRight,
--  as its tutorials point), Setup.ARROW large, over the setup's window
--  (FULLSCREEN_DIALOG), moving towards the corner (or the edge) that fills
--  the screen from now (Core's edge:Spot()) again and again, with words beside
--  it: into the corner, then click where the corner wants a click, and once
--  the map fills the screen, that the corner brings it back. It takes no
--  mouse: the mouse goes through it to the corner. It follows the map
--  wherever Edit Mode docks it (a look a few times a second while it shows),
--  and shows only while the board of corner or move is in sight: the board's
--  OnHide (Back, Next, Done, Esc, the X) takes it away.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Setup = {}
ns.Setup = Setup

Setup.TITLE = "Map"     -- the window's title: "Map: setup" (and /sane setup map)
Setup.SIZE = 13         -- the boards' words (Look.SetFont)
Setup.SCREEN = { 360, 203 } -- a screen drawn on a board: 16 to 9
Setup.SMALL = 58        -- the small map on a drawn screen
Setup.ARROW = 170       -- the big arrow's side (UI units)
Setup.REACH = 96        -- its middle this far from the spot it points at, at rest
Setup.TRAVEL = 34       -- and this much nearer at the end of each move
Setup.BOB = 0.55        -- seconds a move takes, there and back again
Setup.SAY = 26          -- its words' size; the line under them
Setup.MORE = 16
Setup.SAY_WIDTH = 300
Setup.LOOK = 0.2        -- seconds between two looks where the spot is now
Setup.ARROW_ART = "NPE_ArrowRight"
Setup.GLOW_ART = "NPE_ArrowRightGlow"
Setup.CURSOR = "Interface\\CURSOR\\Point"
Setup.PLAYER = "Interface\\Minimap\\MinimapArrow"
Setup.PIN = "Waypoint-MapPin-Tracked"
Setup.MOUSE = { left = "newplayertutorial-icon-mouse-leftbutton", right = "newplayertutorial-icon-mouse-rightbutton" }
Setup.GROUND = { 0.16, 0.21, 0.13 } -- a drawn map's land
Setup.WORLD = { 0.05, 0.05, 0.06 }  -- a drawn screen's world around it
-- Which way the arrow points (degrees, counterclockwise from the right) for the corner or the side the spot is at.
Setup.ANGLES = { TOPRIGHT = 45, TOPLEFT = 135, BOTTOMLEFT = 225, BOTTOMRIGHT = 315,
                 right = 0, top = 90, left = 180, bottom = 270 }

Setup.TEXT = {
    into = "All the way into the corner",
    edge = "All the way to the edge",
    click = ", then click",
    fills = "and the map fills the screen",
    again = "Into the corner again",
    againEdge = "To the edge again",
    back = "and the map goes back",
    keyOwn = "SaneUI's map",
    keyOwnTip = "Full screen and back, from wherever you are.",
    keyGame = "The game's map",
    keyGameTip = "The game's own map. Until SaneUI's map has a key of its own, this key opens SaneUI's map.",
    keyFind = "Search the map",
    keyFindTip = "The full map, the cursor in its search: type a name, a place, an item.",
    cornerSwitch = "The corner opens the map",
    cornerHover = "When the mouse goes into it",
    cornerClick = "With a left click in it",
    cornerTip = "The mouse in the screen's corner where the map stands fills the screen with the map, and brings it back. With a left click: only when you click there, so nothing opens by mistake.",
}

local function Hued(colour, words)
    if not words then colour, words = Look.GOLD, colour end
    return "|cff" .. Core.Hex(colour[1], colour[2], colour[3]) .. words .. "|r"
end

-- A step's words: one line each, its first words in gold ({ "Gold", "the rest" }), so the page reads at a glance.
local function Lines(...)
    local lines = {}
    for index = 1, select("#", ...) do
        local line = select(index, ...)
        lines[index] = Hued(line[1]) .. "  " .. line[2]
    end
    return table.concat(lines, "\n")
end

-------------------------------------------------------------------------------
--  The steps: their words and the switches each is about
-------------------------------------------------------------------------------
Setup.STEPS = {
    { key = "intro", title = "Your map",
      text = Lines({ "The minimap", "is the map: small in its corner, the whole screen when you want it." },
          { "The same map", "in both, moved and zoomed the same way, each keeping its own place." },
          { "This setup", "shows how to open it, where it stands and how to find your way." },
          { "Every choice", "counts at once. Close at any time: it stays." }),
      settings = {} },
    { key = "corner", title = "Into the corner",
      text = Lines({ "The hot corner", "the screen's corner your map stands in: the big arrow points at it." },
          { "The mouse", "all the way into it: the map fills the screen. Again: it goes back." },
          { "Or a click", "the mouse in the corner, then a left click: nothing opens by mistake." },
          { "Or a key", "the next page. They all work together." }),
      settings = { { key = "expandClick", text = Setup.TEXT.cornerSwitch, tip = Setup.TEXT.cornerTip, column = true,
                     choices = { { false, Setup.TEXT.cornerHover }, { true, Setup.TEXT.cornerClick } } } } },
    { key = "keys", title = "Or a key",
      text = Lines({ "SaneUI's map", "full screen and back by a key of its own." },
          { "The game's map", "its key opens SaneUI's map until that has a key: then the game's map." },
          { "Together", "the corner and the keys work side by side: use any of them, or all." },
          { "A key", "click its box, press the key. Right click: no key." }),
      settings = { { binding = ns.Native.OWN, text = Setup.TEXT.keyOwn, tip = Setup.TEXT.keyOwnTip },
                   { binding = "TOGGLEWORLDMAP", text = Setup.TEXT.keyGame, tip = Setup.TEXT.keyGameTip },
                   { binding = "SANEUI_MAP_FIND", text = Setup.TEXT.keyFind, tip = Setup.TEXT.keyFindTip } } },
    { key = "move", title = "Move it in Edit Mode",
      text = Lines({ "Edit Mode", "Esc > Edit Mode: drag the map where you like it." },
          { "The hot corner", "moves with it: docked in a corner, that corner; along an edge, that edge." },
          { "In the middle", "of the screen it has none: use a key." },
          { "Its size", "drag its inner corner, the mouse on the map." },
          { "The arrow", "always points where the hot corner is now." }),
      settings = {} },
    { key = "quests", title = "The quest log",
      text = Lines({ "A click", "on a quest opens it: its objectives under it." },
          { "A double click", "puts the map pin on it: a golden line leads you there." },
          { "A right click", "its menu: its text, the map at it, share, abandon." }),
      settings = {} },
    { key = "map", title = "On the map",
      text = Lines({ "A double click", "anywhere: the map pin there, and the way to it." },
          { "A right click", "often offers more: on a pin, a marker, the map pin." },
          { "The wheel", "zooms. A drag moves the map, the middle button brings it back to you." },
          { "Done", "your map is set." }),
      settings = {} },
}

-------------------------------------------------------------------------------
--  Where the hot corner is now
-------------------------------------------------------------------------------
-- The map's window's edge (Core's Edge.lua), once it is made.
local function Edge()
    local handle = ns.Window.handle
    return handle and handle.edge or nil
end

-- The spot the mouse fills the screen from: its frame, and where it is ("TOPRIGHT" ..., or a side); nil for none.
function Setup.Spot()
    local edge = Edge()
    if not edge or not edge.Spot then return nil end
    local strip, key, corner = edge:Spot()
    if not strip then return nil end
    return strip, corner or key
end

local function Clicks() return ns.options.expandClick == true end
local function Full() local edge = Edge() return edge and edge.full or false end

-------------------------------------------------------------------------------
--  The big arrow on the screen
-------------------------------------------------------------------------------
local pointer, aimed

-- The game's tutorial arrow and its glow on a frame of their own, turned to point at angle (degrees).
local function ArrowArt(frame)
    local art = frame:CreateTexture(nil, "ARTWORK")
    Look.Atlas(art, Setup.ARROW_ART)
    art:SetAllPoints()
    local glow = frame:CreateTexture(nil, "OVERLAY")
    Look.Atlas(glow, Setup.GLOW_ART)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.75)
    glow:SetAllPoints()
    return { art, glow }
end
local function Turn(parts, angle)
    for _, part in ipairs(parts) do part:SetRotation(math.rad(angle)) end
end

-- Its words as the spot and the switch say now: into the corner (then click); the map full, back the same way.
local function Say()
    local _, at = Setup.Spot()
    local corner = at and at:upper() == at -- (TOPRIGHT ...; a side is "right", "top" ...)
    local click = Clicks() and Setup.TEXT.click or ""
    if Full() then
        return (corner and Setup.TEXT.again or Setup.TEXT.againEdge) .. click, Setup.TEXT.back
    end
    return (corner and Setup.TEXT.into or Setup.TEXT.edge) .. click, Setup.TEXT.fills
end

-- Pointed at the spot as it is now: placed anew only where it moved (Edit Mode docked the map elsewhere).
local function Aim()
    if not pointer then return end
    local strip, at = Setup.Spot()
    local angle = strip and Setup.ANGLES[at]
    pointer.arrow:SetShown(angle ~= nil)
    pointer.say:SetShown(angle ~= nil)
    pointer.more:SetShown(angle ~= nil)
    if not angle then
        aimed = nil
        return
    end
    local mark = tostring(strip) .. at
    if aimed ~= mark then
        aimed = mark
        local turn = math.rad(angle)
        local dx, dy = math.cos(turn), math.sin(turn)
        pointer:ClearAllPoints()
        pointer:SetPoint("CENTER", strip, "CENTER", -dx * Setup.REACH, -dy * Setup.REACH)
        Turn(pointer.parts, angle)
        if pointer.move then
            pointer.move:SetOffset(dx * Setup.TRAVEL, dy * Setup.TRAVEL)
            pointer.group:Stop()
            pointer.group:Play()
        end
        -- The words on the far side of the arrow, clear of it whichever way it points.
        local away = 110 + 110 * math.abs(dx)
        pointer.say:ClearAllPoints()
        pointer.say:SetPoint("CENTER", pointer, "CENTER", -dx * away, -dy * away)
    end
    local say, more = Say()
    if pointer.say:GetText() ~= say then pointer.say:SetText(say) end
    if pointer.more:GetText() ~= more then pointer.more:SetText(more) end
end

local function Build()
    pointer = CreateFrame("Frame", nil, UIParent)
    pointer:SetFrameStrata("FULLSCREEN_DIALOG") -- over the setup's window (DIALOG) and the full map (HIGH)
    pointer:SetSize(Setup.ARROW, Setup.ARROW)
    pointer:EnableMouse(false) -- the mouse goes through to the corner
    pointer:Hide()
    local arrow = CreateFrame("Frame", nil, pointer)
    arrow:SetAllPoints(pointer)
    pointer.arrow = arrow
    pointer.parts = ArrowArt(arrow)
    local group = arrow.CreateAnimationGroup and arrow:CreateAnimationGroup()
    local move = group and group:CreateAnimation("Translation")
    if move then
        move:SetDuration(Setup.BOB)
        move:SetSmoothing("IN_OUT")
        group:SetLooping("BOUNCE")
        pointer.group, pointer.move = group, move
    end
    local say = pointer:CreateFontString(nil, "OVERLAY")
    Look.SetFont(say, Setup.SAY, true, Look.GOLD)
    say:SetWidth(Setup.SAY_WIDTH)
    say:SetJustifyH("CENTER")
    say:SetWordWrap(true)
    local more = pointer:CreateFontString(nil, "OVERLAY")
    Look.SetFont(more, Setup.MORE)
    more:SetWidth(Setup.SAY_WIDTH)
    more:SetJustifyH("CENTER")
    more:SetPoint("TOP", say, "BOTTOM", 0, -4)
    pointer.say, pointer.more = say, more
    local waited = 0
    pointer:SetScript("OnUpdate", ns.Guard(function(_, elapsed)
        waited = waited + (elapsed or 0)
        if waited < Setup.LOOK then return end
        waited = 0
        Aim()
    end))
end

-- The big arrow in sight (on) or not.
function Setup.Point(on)
    if not on then
        if pointer then pointer:Hide() end
        return
    end
    if not pointer then Build() end
    aimed = nil
    pointer:Show()
    Aim()
end

-------------------------------------------------------------------------------
--  The boards: each step's sample, made the first time it shows
-------------------------------------------------------------------------------
local boards = {} -- [step key] = its board on the stage

local function Wide(board)
    local width = board:GetWidth()
    return type(width) == "number" and width > 0 and width or 420
end

-- A part of a board, made once by its name.
local function Part(board, name, make)
    local part = board.parts[name]
    if not part then
        part = make()
        board.parts[name] = part
    end
    return part
end

local function Words(board, name, size, colour, host)
    return Part(board, name, function()
        local words = (host or board):CreateFontString(nil, "OVERLAY")
        Look.SetFont(words, size or Setup.SIZE, false, colour)
        words:SetJustifyH("CENTER")
        words:SetWordWrap(true)
        return words
    end)
end

-- Words centred at y from the board's top, as wide as the board allows.
local function Caption(board, name, y, text, size, colour)
    local words = Words(board, name, size, colour)
    words:ClearAllPoints()
    words:SetPoint("TOP", board, "TOP", 0, -y)
    words:SetWidth(Wide(board) - 40)
    words:SetText(text)
    return words
end

-- A frame in the thin golden outline, filled with a colour: a drawn screen, a drawn map.
local function Boxed(parent, colour, alpha)
    local box = CreateFrame("Frame", nil, parent)
    local fill = box:CreateTexture(nil, "BACKGROUND")
    fill:SetColorTexture(colour[1], colour[2], colour[3], alpha or 1)
    fill:SetAllPoints()
    box.outline = Look.Outline(box, "ARTWORK")
    box.outline.fill:Hide() -- (its own dark inside: the colour given is the inside here)
    box.fill = fill
    return box
end

-- A screen drawn on the board: its top at y, centred, Setup.SCREEN large.
local function Screen(board, name, y)
    local screen = Part(board, name, function() return Boxed(board, Setup.WORLD) end)
    screen:ClearAllPoints()
    screen:SetSize(Setup.SCREEN[1], Setup.SCREEN[2])
    screen:SetPoint("TOP", board, "TOP", 0, -y)
    return screen
end

-- A drawn map: land in the golden outline, the player's arrow in its middle.
local function Map(parent)
    local map = Boxed(parent, Setup.GROUND)
    local player = map:CreateTexture(nil, "OVERLAY")
    player:SetTexture(Setup.PLAYER)
    player:SetSize(18, 18)
    player:SetPoint("CENTER")
    map.player = player
    return map
end

-- The small map on a drawn screen where the spot is (a corner, the middle of a side, the middle for none).
local POINTS = { right = "RIGHT", left = "LEFT", top = "TOP", bottom = "BOTTOM" }
local function Dock(map, screen, at)
    local point = at and (POINTS[at] or at) or "CENTER"
    map:ClearAllPoints()
    map:SetSize(Setup.SMALL, Setup.SMALL)
    map:SetPoint(point, screen, point, 0, 0)
end

-- A layer over everything else on the board (its drawn screens and maps are frames of their own): for the arrows,
-- the cursor and the mouse.
local function Top(board)
    return Part(board, "top", function()
        local frame = CreateFrame("Frame", nil, board)
        frame:SetAllPoints(board)
        frame:SetFrameLevel(board:GetFrameLevel() + 20)
        return frame
    end)
end

-- A small arrow of the game's (its tutorial arrow) on a board, pointing at angle; its point placed by the caller.
local function Pointer(board, name, size)
    return Part(board, name, function()
        local frame = CreateFrame("Frame", nil, Top(board))
        frame:SetSize(size, size)
        frame.parts = ArrowArt(frame)
        return frame
    end)
end

-- The arrow pointing into a drawn screen's corner (or side) at, its tip near it.
local function Into(arrow, screen, at)
    local angle = Setup.ANGLES[at]
    arrow:SetShown(angle ~= nil)
    if not angle then return end
    Turn(arrow.parts, angle)
    local turn = math.rad(angle)
    local reach = arrow:GetWidth() * 0.62
    local point = POINTS[at] or at
    arrow:ClearAllPoints()
    arrow:SetPoint("CENTER", screen, point, -math.cos(turn) * reach, -math.sin(turn) * reach)
end

local function Icon(board, name, size, set)
    local icon = Part(board, name, function()
        local texture = Top(board):CreateTexture(nil, "OVERLAY")
        set(texture)
        return texture
    end)
    icon:SetSize(size, size)
    return icon
end

-- The keys bound to a command in the game's words ("Shift-M"), or "Not bound".
local function KeyWords(command)
    local keys = { Core.Ask(rawget(_G, "GetBindingKey"), command) }
    local said = {}
    for _, key in ipairs(keys) do
        if type(key) == "string" and key ~= "" then
            local words = Core.Ask(rawget(_G, "GetBindingText"), key)
            said[#said + 1] = type(words) == "string" and words ~= "" and words or key
        end
    end
    return #said > 0 and table.concat(said, ", ") or nil
end

local DRAW = {}

-- Small in its corner, and the same map full screen.
function DRAW.intro(board)
    local top = Screen(board, "top", 20)
    local small = Part(board, "small", function() return Map(top) end)
    local _, at = Setup.Spot()
    Dock(small, top, at or "TOPRIGHT")
    Caption(board, "topWords", 20 + Setup.SCREEN[2] + 8, Hued("Small") .. ": the minimap, in its corner")
    local bottom = Screen(board, "bottom", 260)
    local full = Part(board, "full", function() return Map(bottom) end)
    full:ClearAllPoints()
    full:SetAllPoints(bottom)
    Caption(board, "bottomWords", 260 + Setup.SCREEN[2] + 8, Hued("Full screen") .. ": the same map, all of it")
end

-- The screen with the map in its corner, the mouse there, the arrow into it; a click where the corner wants one.
function DRAW.corner(board)
    local screen = Screen(board, "screen", 40)
    local small = Part(board, "small", function() return Map(screen) end)
    local _, at = Setup.Spot()
    Dock(small, screen, at) -- (not docked: in the middle, no arrow)
    local arrow = Pointer(board, "arrow", 70)
    Into(arrow, screen, at)
    -- The cursor's point (its picture's top left) in the corner, pushed as far as it goes.
    local cursor = Icon(board, "cursor", 26, function(texture) texture:SetTexture(Setup.CURSOR) end)
    cursor:ClearAllPoints()
    cursor:SetPoint("TOPLEFT", screen, at and (POINTS[at] or at) or "CENTER", 0, 0)
    cursor:SetShown(at ~= nil)
    local mouse = Icon(board, "mouse", 40, function(texture) Look.Atlas(texture, Setup.MOUSE.left) end)
    mouse:ClearAllPoints()
    mouse:SetPoint("TOP", screen, "BOTTOM", 0, -10)
    mouse:SetShown(at ~= nil and Clicks())
    local words
    if not at then
        words = "Your map is not docked to the screen's edge, so it has no hot corner: dock it in Edit Mode (two pages "
            .. "on), or use a key (the next page)."
    elseif Clicks() then
        words = Hued("The mouse into the corner, then a left click") .. ": the map fills the screen. "
            .. "A click there again: back."
    else
        words = Hued("The mouse all the way into the corner") .. ": the map fills the screen. Into it again: back."
    end
    Caption(board, "words", 40 + Setup.SCREEN[2] + 64, words)
    Caption(board, "seen", 40 + Setup.SCREEN[2] + 130, "The big arrow on your screen points into your own corner. Try it now.",
        Setup.SIZE, Look.FAINT)
end

-- A row of the keys' board: an icon or a key's box at the left, its words beside it.
local function Row(board, index, y, text, key)
    local box = Part(board, "box" .. index, function()
        local frame = CreateFrame("Frame", nil, board)
        frame:SetSize(110, 26)
        frame.outline = Look.Outline(frame)
        local label = frame:CreateFontString(nil, "OVERLAY")
        Look.SetFont(label, Setup.SIZE, false, Look.GOLD)
        label:SetPoint("LEFT", 4, 0)
        label:SetPoint("RIGHT", -4, 0)
        label:SetJustifyH("CENTER")
        frame.label = label
        return frame
    end)
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", board, "TOPLEFT", 24, -y)
    box.label:SetText(key or Hued(Look.FAINT, "No key"))
    local words = Words(board, "row" .. index)
    words:ClearAllPoints()
    words:SetPoint("LEFT", box, "RIGHT", 14, 0)
    words:SetWidth(Wide(board) - 24 - 110 - 14 - 16)
    words:SetJustifyH("LEFT")
    words:SetText(text)
end

-- The ways to open the map, each as it is set now, and that they work together.
function DRAW.keys(board)
    local own, game, find = KeyWords(ns.Native.OWN), KeyWords("TOGGLEWORLDMAP"), KeyWords("SANEUI_MAP_FIND")
    Row(board, 1, 34, Hued("The corner") .. ": " .. (Clicks() and "the mouse into it, then a left click"
        or "the mouse all the way into it"), Clicks() and "Click" or "Mouse")
    Row(board, 2, 84, Hued(Setup.TEXT.keyOwn) .. ": full screen and back", own)
    Row(board, 3, 134, Hued(Setup.TEXT.keyGame) .. ": " .. (own and "the game's own map"
        or "SaneUI's map, until that has a key"), game)
    Row(board, 4, 184, Hued(Setup.TEXT.keyFind) .. ": the full map, the cursor in its search", find)
    Caption(board, "together", 250, Hued("All of them work side by side") .. ": the corner for the mouse, a key for "
        .. "when your hands are on the keyboard.")
end

-- The screen with every place the map can stand faint, the one it stands now in the outline, and the arrow there.
local PLACES = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "right", "left" }
function DRAW.move(board)
    local screen = Screen(board, "screen", 40)
    local _, at = Setup.Spot()
    for _, place in ipairs(PLACES) do
        local ghost = Part(board, "ghost" .. place, function()
            local frame = Boxed(screen, Setup.GROUND, 0.35)
            frame.outline:SetStrong(false)
            return frame
        end)
        Dock(ghost, screen, place)
        ghost:SetAlpha(0.45)
        ghost:SetShown(place ~= at)
    end
    local small = Part(board, "small", function() return Map(screen) end)
    Dock(small, screen, at)
    local arrow = Pointer(board, "arrow", 70)
    Into(arrow, screen, at)
    Caption(board, "words", 40 + Setup.SCREEN[2] + 20, Hued("Docked in a corner") .. ": that corner. "
        .. Hued("Along an edge") .. ": that edge, where the map touches it. " .. Hued("In the middle") .. ": none.")
    Caption(board, "now", 40 + Setup.SCREEN[2] + 90, at and "The big arrow on your screen points where yours is now."
        or "Yours stands away from the edges now: no hot corner, a key opens it.", Setup.SIZE, Look.FAINT)
end

-- A quest log of two quests in the game's colours: the first opened by a click, the second with its route.
function DRAW.quests(board)
    local log = Part(board, "log", function() return Boxed(board, Setup.WORLD, 0.6) end)
    log:ClearAllPoints()
    log:SetSize(330, 190)
    log:SetPoint("TOP", board, "TOP", 0, -30)
    local zone = Core.Plain(Core.Ask(rawget(_G, "GetZoneText")))
    local rows = {
        { Hued(type(zone) == "string" and zone ~= "" and zone or "Your zone"), 0 },
        { Hued({ 1, 1, 0 }, "The Thornspine Raiders"), 12 },
        { Hued({ 0.85, 0.85, 0.85 }, "Raider slain: 4/10"), 26 },
        { Hued({ 0.85, 0.85, 0.85 }, "Raider's tusk: 2/6"), 26 },
        { Hued({ 0.25, 0.75, 0.25 }, "Lost Supplies"), 12 },
    }
    for index, row in ipairs(rows) do
        local words = Words(board, "quest" .. index, nil, nil, log) -- (on the log: over its dark inside)
        words:ClearAllPoints()
        words:SetPoint("TOPLEFT", log, "TOPLEFT", 12 + row[2], -14 - (index - 1) * 30)
        words:SetJustifyH("LEFT")
        words:SetWidth(165)
        words:SetText(row[1])
    end
    local left = Icon(board, "left", 30, function(texture) Look.Atlas(texture, Setup.MOUSE.left) end)
    left:ClearAllPoints()
    left:SetPoint("LEFT", log, "TOPLEFT", 190, -50)
    local once = Words(board, "once", nil, nil, log)
    once:ClearAllPoints()
    once:SetPoint("LEFT", left, "RIGHT", 2, 0)
    once:SetJustifyH("LEFT")
    once:SetWidth(80)
    once:SetText(Hued("A click") .. ": open")
    local twice = Icon(board, "twice", 30, function(texture) Look.Atlas(texture, Setup.MOUSE.left) end)
    twice:ClearAllPoints()
    twice:SetPoint("LEFT", log, "TOPLEFT", 190, -140)
    local double = Words(board, "double", nil, nil, log)
    double:ClearAllPoints()
    double:SetPoint("LEFT", twice, "RIGHT", 2, 0)
    double:SetJustifyH("LEFT")
    double:SetWidth(80)
    double:SetText(Hued("Twice") .. ": a route")
    Caption(board, "words", 240, Hued("A click") .. " opens a quest: its objectives under it. " .. Hued("A double click")
        .. " puts the map pin on it, and a golden line leads you there. " .. Hued("A right click") .. ": its menu.")
end

-- A map with you, the map pin a double click put, and the golden line between.
local function Way(board, map)
    local lines = board.parts.way
    if lines then return lines end
    lines = {}
    local points = { { -120, -50 }, { -70, -10 }, { -10, 0 }, { 50, 25 }, { 110, 55 } } -- from the map's middle
    for index = 1, #points - 1 do
        local edge = map:CreateLine(nil, "ARTWORK", nil, 0)
        edge:SetTexture(ns.Route.EDGE, "REPEAT", "CLAMP")
        local fill = map:CreateLine(nil, "ARTWORK", nil, 1)
        fill:SetTexture(ns.Route.FILL, "REPEAT", "CLAMP")
        for _, line in ipairs({ edge, fill }) do
            line:SetStartPoint("CENTER", map, points[index][1], points[index][2])
            line:SetEndPoint("CENTER", map, points[index + 1][1], points[index + 1][2])
        end
        edge:SetThickness(ns.Route.THICK + 2)
        fill:SetThickness(ns.Route.THICK)
        lines[#lines + 1] = edge
        lines[#lines + 1] = fill
    end
    lines.from, lines.to = points[1], points[#points]
    board.parts.way = lines
    return lines
end

function DRAW.map(board)
    local map = Part(board, "land", function() return Map(board) end)
    map:ClearAllPoints()
    map:SetSize(Setup.SCREEN[1], 200)
    map:SetPoint("TOP", board, "TOP", 0, -30)
    local way = Way(board, map)
    map.player:ClearAllPoints()
    map.player:SetPoint("CENTER", map, "CENTER", way.from[1], way.from[2])
    local pin = Part(board, "pin", function()
        local texture = map:CreateTexture(nil, "OVERLAY")
        Look.Atlas(texture, Setup.PIN)
        texture:SetSize(28, 28)
        return texture
    end)
    pin:ClearAllPoints()
    pin:SetPoint("BOTTOM", map, "CENTER", way.to[1], way.to[2] - 4)
    local cursor = Icon(board, "cursor", 26, function(texture) texture:SetTexture(Setup.CURSOR) end)
    cursor:ClearAllPoints()
    cursor:SetPoint("TOPLEFT", map, "CENTER", way.to[1] + 6, way.to[2] - 8)
    local left = Icon(board, "left", 34, function(texture) Look.Atlas(texture, Setup.MOUSE.left) end)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", board, "TOPLEFT", 30, -250)
    local double = Words(board, "double")
    double:ClearAllPoints()
    double:SetPoint("LEFT", left, "RIGHT", 8, 0)
    double:SetJustifyH("LEFT")
    double:SetWidth(Wide(board) - 90)
    double:SetText(Hued("A double click") .. " anywhere: the map pin there, and the golden line, the way to it.")
    local right = Icon(board, "right", 34, function(texture) Look.Atlas(texture, Setup.MOUSE.right) end)
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", board, "TOPLEFT", 30, -310)
    local more = Words(board, "more")
    more:ClearAllPoints()
    more:SetPoint("LEFT", right, "RIGHT", 8, 0)
    more:SetJustifyH("LEFT")
    more:SetWidth(Wide(board) - 90)
    more:SetText(Hued("A right click") .. " often offers more: on a pin, a marker, the map pin. It never zooms: "
        .. "the wheel does.")
end

-- The step's board on the stage, the others out of sight; drawn anew as the settings in use say. The big arrow on
-- the screen while the corner or Edit Mode's step shows.
local POINTED = { corner = true, move = true }
local function Stage(stage, step)
    for key, board in pairs(boards) do board:SetShown(key == step.key) end
    local draw = DRAW[step.key]
    if draw then
        local board = boards[step.key]
        if not board then
            board = CreateFrame("Frame", nil, stage)
            board:SetAllPoints(stage)
            board.parts = {}
            -- Out of sight (the step left, the window closed): the big arrow goes with it.
            if POINTED[step.key] then board:SetScript("OnHide", ns.Guard(function() Setup.Point(false) end)) end
            boards[step.key] = board
        end
        draw(board)
        board:Show()
    end
    Setup.Point(POINTED[step.key] == true)
end

-- For the tests: a step's board, once drawn; the big arrow.
function Setup.Board(key) return boards[key] end
function Setup.Pointer() return pointer end

Core.Onboarding.Add(ns.name, {
    title = Setup.TITLE,
    steps = Setup.STEPS,
    Stage = function(stage, step, index) ns.Safe("setup sample", Stage, stage, step, index) end,
})
