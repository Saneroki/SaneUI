local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Edge
--  A window docked to the screen's edge (Dock.lua) fills the whole screen when
--  the mouse is pushed against that edge where the window touches it: the
--  game window's own last pixels, not the window's border. Pushed there again,
--  or with Esc, it goes back to its size in its zone. A window in the middle of
--  the screen, or not docked, has no such edge: its full screen button does the
--  same (Window.lua), and it goes back to where it stood. Full, it has a background
--  of its own (solid black or one of Blizzard's tiles, as opaque as set: a plate,
--  Shape.lua, square once it fills the screen), stands above the game's bars
--  and windows, and takes the mouse: what is behind it can be neither clicked
--  nor scrolled, as the game's map does it while it is locked.
--
--  Full, it has a dropdown Classic windows in its top right corner: the game's
--  own windows that Sane UI's windows stand for (their option classic), each
--  module's under its name, this window's first (Classic.lua). One chosen, the
--  window goes back to its zone and the game's own comes instead (the entry's
--  show: the game's friends list, or the game's chat with ours put away). An
--  entry that is a kept choice (checked) is a checkbox, ticked while the game's
--  own is the one kept; chosen again, ours is the one again (back) and the
--  window stays as it is. The game's windows have the button Sane UI the other
--  way.
--
--  Each window has a section Expand window in its options (Edge.Options):
--  whether it fills the screen at all, whether its edge wants a left click, its kind of motion, the background's
--  opacity and texture, and how round its corners are (Corner radius, Don't
--  round corners on screen edges; Shape.Options).
--
--  Made by Window.New (option edge). What it reads of the window's options:
--      edge = settings                      -- the module's settings with that section's switches;
--                                           -- true: as they are by default (Edge.DEFAULTS)
--      motion = function() return key end  -- its kind of motion, instead of the section's (Motion.lua)
--      content = region                     -- what the window holds (a chat's list)
--      classic = { { text = "Friends list", show = function() end }, ... }  -- the game's windows it stands
--                                           -- for, in the dropdown Classic windows (or a function giving them);
--                                           -- checked = function() end: a kept choice, ticked while true;
--                                           -- back = function() end: ours again, when chosen while ticked;
--                                           -- the rest of an entry (its button on the game's window): Classic.lua
--      filled = function(full, width, height) end  -- it has begun to fill the screen (true) or to go back,
--                                           -- to that size
--      moving = function(share) end         -- what it holds goes with the motion instead of fading out:
--                                           -- at each step, the share of the way (0 to 1; Swing goes a
--                                           -- little past 1 and back)
--      docked = function(zone) end          -- Window's hook, called once it has filled the screen too
--      strip = 0.5                          -- docked at an edge's middle: the strip there is that share of
--                                           -- the screen's side, in its middle, however wide the window is
--                                           -- (Combat: half the bottom edge); without, the window's side
--  A switch of the section changed (its options page, a profile, Core.Set):
--  every window that reads that module's settings is updated at once
--  (edge:Update()); the module need not pass it on.
--  edge.full: it fills the screen or is on its way there. edge.away: it is not
--  at rest in its zone (full, or on its way back); it is neither moved nor
--  sized then, and its grip is out of sight.
--
--  The motion: size and place go from where the window is at that moment to
--  the whole screen, or back to its zone, as its kind of motion says (Swing
--  goes a little past the screen's edge); a change of mind on the way never
--  jumps. The background comes and goes with the way, with the window's own
--  skin going as it comes. Its corners start as round as the window's at rest
--  and flatten as it comes, so the full window is square, whatever the corners'
--  switches say (only a window at rest is round). What the window holds fades
--  out when the motion begins and comes in again once the window stands, from
--  a little above, as a panel's intro: laid out for the new size
--  only then (docked), once, not on every step. A window that lays itself out
--  in its own OnSizeChanged should skip that while edge.away (every step of
--  the motion sizes it, unseen) and lay out in its docked hook instead, which
--  Edge calls once at the end of either way. A window whose content can go with
--  the motion (option moving: the map grows and zooms with its window) keeps it
--  in sight the whole way: moving is told how far the motion has come at every
--  step, and filled where the window goes (its size there), so the content is
--  made ready once, at the start, and only placed on the steps.
--
--  One window fills the screen at a time: when another begins to (Social's,
--  then the map's), the one that filled it goes back to its zone.
--
--  Esc brings a full window back as it closes the game's windows (Core.Escape,
--  Escape.lua); a window Esc closes (escape = "close") is closed instead, full
--  as it is (Window.lua).
--
--  The mouse at the edge is an event, not a look every frame: along the
--  docked side lies a strip two of the screen's pixels wide, above everything,
--  that only takes the mouse's coming (clicks and the wheel go on to what is
--  under it). With the option strip it is a share of the screen's side instead,
--  in that side's middle, and stays there while the window fills the screen
--  (its length follows the screen's size and the UI's scale). Docked in a
--  corner, only a square of four pixels in that corner:
--  the mouse has to go all the way into it. A strip that comes under a mouse
--  that is there already (a window let go at the edge) does nothing: the mouse
--  has to come anew. One push is one change: after it the strip counts again
--  only once the mouse has gone some way from that edge or corner (the window's
--  motion moves the strip from under the mouse and back, which is no new push);
--  meanwhile a look a few times a second sees whether it has gone. A held
--  button stops it, unless the cursor carries something (an item dragged out
--  of the full bags goes to the corner, the bags go back, it goes on the bars).
--
--  With Hotcorner requires leftclick (the section's expandClick, each window's
--  own: the bags may want a click while the map does not) the mouse's coming does nothing: a left click in the strip or the square
--  fills the screen, and another there brings the window back. The strips take
--  the left clicks then (nothing under them gets them).
-------------------------------------------------------------------------------
local Edge = {}
Core.Edge = Edge

Edge.STRATA = "HIGH" -- full: above the game's bars and windows (MEDIUM); tooltips and dialogs stay above it
Edge.PIXELS = 2      -- a strip's width, in the screen's own pixels
Edge.CORNER = 4      -- in a corner: the side of the square the mouse has to reach, likewise
Edge.QUIET = 0.25    -- seconds after the window was placed in which the mouse's coming counts for nothing
Edge.OUT = 0.15      -- seconds what the window holds takes to fade out when the motion begins
Edge.IN = 0.4        -- and to come in once the window stands, from so far above
Edge.DROP = 10
Edge.CLASSIC = "Classic windows"
Edge.CORNERS = "Window corners" -- the section of the corners' switches (Edge.Options) -- the dropdown's words
Edge.MENU_WIDTH, Edge.MENU_INSET = 180, 10 -- its width; from the full window's top right corner, or its buttons
Edge.AWAY = 24   -- the screen's pixels the mouse has to go from the edge or corner it pushed before a push counts again
Edge.LOOK = 0.1  -- seconds between two looks whether it has gone

-- The backgrounds to choose from: solid black, or one of the quiet tiles Blizzard fills its windows
-- with (Skin.TILES), repeated every size units.
Edge.SOLID = "Solid black"
local BLACK = { 0, 0, 0 }

-- The section's switches, as a window without settings of its own has them (edge = true).
Edge.DEFAULTS = { expand = true, expandClick = false, motion = Core.Motion.GLOBAL, expandOpacity = 50, expandTexture = "solid" }
Edge.KEYS = { expand = true, expandClick = true, motion = true, expandOpacity = true, expandTexture = true }
for key, value in pairs(Core.Shape.DEFAULTS) do
    Edge.DEFAULTS[key], Edge.KEYS[key] = value, true
end

local sections = {} -- [a module's list of switches] = true: it holds the section
local edges = setmetatable({}, { __mode = "k" }) -- every window's edge (Edge.New)

-- Puts the section Expand window into a module's switches (Core.Options) at that place of its list,
-- in that tab of its page. A window reads them by its option edge = the module's settings. under: switches
-- of the module's own that some of the section's stand under too, [key] = a key or a list of them
-- ({ motion = "animations" }: the animation type is greyed out while the module's animations are off).
function Edge.Options(list, at, tab, under)
    local section = {
        { key = "expand", default = Edge.DEFAULTS.expand, text = "Can expand to fullscreen", header = "Expand window",
          headerTip = "Docked to a screen edge, the window can fill the whole screen and go back.",
          tip = "Push the mouse against the screen edge or corner the window is docked to and it fills the screen. Push there again and it goes back. Off: the edge does nothing." },
        { key = "expandClick", default = Edge.DEFAULTS.expandClick, text = "Hotcorner requires leftclick", parent = "expand",
          tip = "The mouse at the screen edge or corner the window is docked to is not enough: left-click there and it fills the screen, left-click there again and it goes back." },
        { key = "motion", default = Edge.DEFAULTS.motion, text = "Animation type", parent = "expand", choices = Core.Motion.Choices(true),
          tip = "Glide is quick and settles softly, Swing goes a little past and comes back, Even starts and ends gently, Instant does not move at all. Use global type: as set under Sane UI > Appearance." },
        { key = "expandOpacity", default = Edge.DEFAULTS.expandOpacity, min = 0, max = 100, step = 5, unit = "%", text = "Background opacity", parent = "expand",
          tip = "How much the background hides the game while the window fills the screen: 0 shows all of it, 100 hides it." },
        { key = "expandTexture", default = Edge.DEFAULTS.expandTexture, text = "Background texture", parent = "expand", choices = Core.Skin.Choices(Edge.SOLID),
          tip = "What the full window stands on: solid black, or one of the game's own backgrounds." },
    }
    for index, option in ipairs(section) do
        option.tab = tab
        local more = under and under[option.key]
        if more then
            local parents = { option.parent }
            for _, key in ipairs(type(more) == "table" and more or { more }) do parents[#parents + 1] = key end
            option.parent = parents
        end
        table.insert(list, at + index - 1, option)
    end
    -- The corners shape the window at its place too: a section of their own, not under the full screen.
    Core.Shape.Options(list, at + #section, tab, nil, Edge.CORNERS)
    sections[list] = true
end

-- The corners a side's strip runs between, inside the window; and which way is out of it.
local SIDES = { left = { "TOPLEFT", "BOTTOMLEFT", -1, 0 }, right = { "TOPRIGHT", "BOTTOMRIGHT", 1, 0 },
                top = { "TOPLEFT", "TOPRIGHT", 0, 1 }, bottom = { "BOTTOMLEFT", "BOTTOMRIGHT", 0, -1 } }

-- How far out of the window a strip at that side lies: as far as the window keeps from the screen's edge
-- there (its insets), so the strip is on the screen's very edge.
local function Out(edge, side)
    local insets = edge.window.options.insets
    return insets and insets[side] or 0
end

local methods = {}

-- So many of the screen's own pixels, in the window's measure. The screen is 768 high at scale 1
-- (the game's PixelUtil).
local function Pixels(frame, count)
    local _, pixels = Core.Ask(GetPhysicalScreenSize)
    local scale = frame:GetEffectiveScale()
    if not pixels or pixels <= 0 or not scale or scale <= 0 then return count end
    return count * 768 / pixels / scale
end

-- Whether the window's strips want a left click instead of the mouse's coming (the section's switch).
local function Clicks(edge)
    return edge.settings.expandClick == true
end

-- The strip along a side (left, right, top, bottom), or the square in a corner (corner).
local function Strip(edge, key)
    local strip = edge.strips[key]
    if strip then return strip end
    strip = CreateFrame("Frame", nil, edge.frame)
    -- Above the window and all it holds, and still so when the window is raised (Fill).
    strip:SetFrameStrata("DIALOG")
    if strip.SetFixedFrameStrata then strip:SetFixedFrameStrata(true) end
    if strip.SetMouseMotionEnabled then strip:SetMouseMotionEnabled(true) else strip:EnableMouse(true) end
    if strip.SetMouseClickEnabled then strip:SetMouseClickEnabled(Clicks(edge)) end -- clicks go through, unless wanted
    strip:SetScript("OnEnter", function() Core.Safe("full screen", edge.Pushed, edge, key) end)
    strip:SetScript("OnMouseDown", Core.Guard("full screen", function(_, button)
        if button == "LeftButton" then edge:Clicked() end
    end))
    local corners = SIDES[key]
    if corners and edge.window.options.strip then
        -- A share of the screen's side, in its middle (its length: Strips).
        local middle = key:upper()
        strip:SetPoint(middle, UIParent, middle)
    elseif corners then
        local out = Out(edge, key)
        strip:SetPoint(corners[1], corners[3] * out, corners[4] * out)
        strip:SetPoint(corners[2], corners[3] * out, corners[4] * out)
    end
    edge.strips[key] = strip
    return strip
end

-- The background as set: one of Blizzard's tiles, or solid black; the trim in Sane UI's bronze.
local function Paint(edge)
    local tile = Core.Skin.Tile(edge.settings.expandTexture)
    edge.back:Look({ file = tile and tile.file, size = tile and tile.size, top = BLACK, bottom = BLACK, trim = Core.GOLD })
end

-- How opaque the background is once the window fills the screen.
local function Opacity(edge)
    return math.min(math.max((tonumber(edge.settings.expandOpacity) or 0) / 100, 0), 1)
end

-- The background has come that far (cover: 0 not at all, 1 as opaque as set), the window at that place:
-- the plate fits it, as flat as it has come (square at the end), and the window's own skin, if it has
-- one, goes as the background comes.
local function Cover(edge, cover, left, bottom, width, height)
    edge.cover = cover
    edge.back:Flatten(cover)
    edge.back:Fit(left, bottom, width, height)
    edge.back:SetAlpha(cover * Opacity(edge), cover)
    local skin = edge.window.skin
    if skin then
        skin:SetAlpha(1 - cover)
        skin:Fit(left, bottom, width, height)
    end
end

-- The background, made at the first fill: in the window itself, under all it holds. While the window
-- fills the screen it follows the screen's size (another resolution or UI scale).
local function Back(edge)
    if not edge.back then
        local frame = edge.frame
        edge.back = Core.Shape.New(frame, edge.settings)
        local watch = CreateFrame("Frame", nil, frame)
        watch:SetAllPoints()
        watch:SetScript("OnSizeChanged", Core.Guard("window", function()
            if not edge.full or not edge.clock or edge.clock:IsRunning() then return end
            Core.Safe("full screen", Cover, edge, edge.cover, 0, 0, frame:GetWidth(), frame:GetHeight())
        end))
    end
    Paint(edge)
    return edge.back
end

-- Esc, while the window fills the screen: it goes back (Core.Escape). A window Esc closes (escape =
-- "close") is closed by Window.lua instead, full as it is.
local function Escaped(edge)
    edge:Fill(false)
end

local function Escape(edge, on)
    if edge.window.options.escape == "close" then return end
    Core.Escape(edge, on and Escaped or nil)
end

-- Esc for the full screen given up (false) while a view over it takes Esc for itself (Core's options,
-- Settings/Screen.lua), and taken again (true) once it has gone.
function methods:Escapes(on)
    Escape(self, on)
end

-- What the window holds: coming, true, it comes in, from a little above down to its place, as a panel's
-- intro (Motion.Slide, Motion.Fade); false, it fades out; nil, it is in sight and still. With a motion of
-- no time it is simply in sight.
local function Content(edge, coming)
    local content = edge.window.options.content
    if edge.window.options.moving then return end -- it goes with the motion, in sight
    if not content or (coming == nil and not edge.fade) then return end
    if not edge.fade then
        edge.fade = Core.Motion.Fade(content)
        edge.slide = Core.Motion.Slide(content, Edge.IN)
    end
    edge.slide:Stop()
    if coming == nil or edge.kind.time <= 0 then
        edge.fade:To(1)
    elseif coming then
        edge.fade:To(1, Edge.IN, 0)
        edge.slide:From(0, Edge.DROP)
    else
        edge.fade:To(0, Edge.OUT)
    end
end

-- The dropdown Classic windows, the game's own menu (WowStyle1DropdownTemplate): the game's windows of every
-- module (Classic.lua), its words always the same (OverrideText). Made when the window first fills the screen
-- while some window has them; nil without.
local function Classic(edge)
    if edge.classic or #Core.Classic.Windows(edge.window) == 0 then return edge.classic end
    local frame = edge.frame
    local menu = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    menu:SetWidth(Edge.MENU_WIDTH)
    menu:SetFrameLevel(frame:GetFrameLevel() + 50) -- above what the window holds
    menu:OverrideText(Edge.CLASSIC)
    menu:SetupMenu(Core.Guard("full screen", function(_, root) Core.Classic.Menu(edge, root) end))
    menu:Hide()
    edge.classic = menu
    return menu
end

-- The dropdown is there while the window stands full, not on the way: in its title bar, left of its
-- buttons (Window.lua), or in its top right corner without them.
local function Menu(edge, on)
    local menu = on and Classic(edge) or edge.classic
    if not menu then return end
    if not on and menu.CloseMenu then menu:CloseMenu() end -- its list goes with it
    if on then
        menu:GenerateMenu() -- the list as the window gives it now
        local buttons = edge.window.buttons
        menu:ClearAllPoints()
        if buttons and buttons:IsShown() and buttons.first then
            menu:SetPoint("RIGHT", buttons.first, "LEFT", -Edge.MENU_INSET, 0)
        else
            menu:SetPoint("TOPRIGHT", -Edge.MENU_INSET, -Edge.MENU_INSET)
        end
    end
    menu:SetShown(on)
end

-- The motion is over. Full, the window hangs on the whole screen (and follows its size); back, it is
-- placed in its zone as before (Window:Place, which ends the rest: Stop). Either way it lays out what it
-- holds for its new size (docked), and that comes in.
local function Stand(edge)
    local window = edge.window
    if edge.full then
        local frame = edge.frame
        frame:ClearAllPoints()
        frame:SetAllPoints(UIParent)
        Menu(edge, true)
        window:Refresh() -- the search box ends left of the dropdown now
        if window.options.docked then Core.Safe("full screen", window.options.docked, Core.Dock.ZONES[edge.zone]) end
    else
        window:Place()
    end
    Content(edge, true)
end

local function Between(from, to, share)
    return from + (to - from) * share
end

-- One step of the motion: its place, its size and the background's coming, that share of the way.
local function Step(edge, progress)
    local share = Core.Motion.Share(edge.kind, progress)
    local frame, from, to = edge.frame, edge.from, edge.to
    local left, bottom = Between(from[1], to[1], share), Between(from[2], to[2], share)
    local width, height = math.max(Between(from[3], to[3], share), 1), math.max(Between(from[4], to[4], share), 1)
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    frame:SetSize(width, height)
    Cover(edge, Between(from[5], to[5], math.min(math.max(share, 0), 1)), left, bottom, width, height)
    local moving = edge.window.options.moving
    if moving then Core.Safe("full screen", moving, share) end
    if progress >= 1 then Stand(edge) end
end

-- A step failed: it would fail again, so this window stays in its zone from now on, and says so once.
local function Failed(edge, problem)
    edge.off = true
    Core.Report("full screen", problem)
    Core.Safe("full screen", edge.window.Place, edge.window)
end

-- One full screen at a time: another window that fills the screen, or is on its way there, goes back.
local function Others(edge)
    for other in pairs(edges) do
        if other ~= edge and other.full and other.frame:IsShown() then Core.Safe("full screen", other.Fill, other, false) end
    end
end

-- Fills the screen (true) or goes back to its zone (false), from where the window is now. Not in Edit
-- Mode, where windows are arranged at their size.
function methods:Fill(on)
    if on == self.full or not self.placed or self.off or (on and not self.settings.expand) then return end
    if on and Core.EditMode.active then return end
    if self.window:Locked() then return end -- a protected window in a fight: not now (Window.lua)
    local frame, window = self.frame, self.window
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    if not left or not bottom then return end -- it has no place yet
    if on then Others(self) end
    if not self.away then
        -- At rest: what it goes back to is its size, its layer and its mouse now.
        self.away = true
        self.width, self.height = frame:GetSize()
        self.left, self.bottom = left, bottom -- where a window not docked goes back to
        self.strata, self.level = frame:GetFrameStrata(), frame:GetFrameLevel()
        -- Clicks and the mouse's coming apart: a frame may take one without the other.
        if frame.IsMouseClickEnabled then
            self.clicks, self.motion = frame:IsMouseClickEnabled(), frame:IsMouseMotionEnabled()
        else
            self.clicks = frame:IsMouseEnabled()
        end
        self.wheel = frame:IsMouseWheelEnabled()
        frame:SetFrameStrata(Edge.STRATA)
        frame:Raise() -- above the others of that layer too
        frame:EnableMouse(true) -- nothing behind it is clicked, nor scrolled (the camera)
        frame:EnableMouseWheel(true)
        frame:SetClampedToScreen(false) -- a motion may go a little past the screen's edge (Swing)
        -- The background, not there yet; its corners as round as the window's at rest.
        Back(self):Base(self.width, self.height)
        self.back:SetShown(true)
        Cover(self, 0, left, bottom, self.width, self.height)
        if window.grip then
            window.grip:SetAlpha(0)
            window.grip:EnableMouse(false)
        end
        if window.skin then window.skin:Hold(true) end -- fitted on every step (Cover), once
    end
    self.full = on
    Escape(self, on)
    Menu(self, false)
    window:Remember("full", on) -- the next time the game asks for the window, it is as it was left
    window:Refresh() -- the title bar at the top of the full window, its full screen button the way back
    local from, to = self.from, self.to
    from[1], from[2], from[3], from[4], from[5] = left, bottom, frame:GetWidth(), frame:GetHeight(), self.cover
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    if on then
        to[1], to[2], to[3], to[4], to[5] = 0, 0, screenWidth, screenHeight, 1
    else
        if self.zone then
            to[1], to[2] = Core.Dock.Rect(self.zone, self.width, self.height, screenWidth, screenHeight, window.options.insets)
        else
            to[1], to[2] = self.left, self.bottom
        end
        to[3], to[4], to[5] = self.width, self.height, 0
    end
    self.kind = Core.Motion.Kind(window.options.motion and Core.Safe("full screen", window.options.motion) or self.settings.motion)
    Content(self, false)
    if window.options.filled then Core.Safe("full screen", window.options.filled, on, to[3], to[4]) end
    self.clock = self.clock or Core.Motion.Clock(frame, function(progress) Step(self, progress) end,
        function(problem) Failed(self, problem) end)
    self.clock:Run(self.kind.time)
end

-- Whether the mouse is still at the edge or corner it pushed (edge.pushed: a side, or "corner"), within
-- Edge.AWAY of the screen's pixels.
local function Near(edge)
    local zone, key = edge.zone and Core.Dock.ZONES[edge.zone], edge.pushed
    if not zone or not key then return false end
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    local room = Pixels(UIParent, Edge.AWAY)
    local corner = key == "corner"
    local left, right = key == "left" or corner and zone.left, key == "right" or corner and zone.right
    local top, bottom = key == "top" or corner and zone.top, key == "bottom" or corner and zone.bottom
    return (not left or x <= room) and (not right or x >= UIParent:GetWidth() - room)
        and (not top or y >= UIParent:GetHeight() - room) and (not bottom or y <= room)
end

-- A look whether the mouse has gone from where it pushed: gone, a push counts again; else another look soon.
local function Look(edge)
    if not edge.pushed then return end
    if not Near(edge) then
        edge.pushed = nil
        return
    end
    C_Timer.After(Edge.LOOK, edge.looking) -- unguarded: edge.looking is made by Core.Guard (Edge.New)
end

-- The mouse came into a strip (key: its side, or "corner"): it is at the screen's edge where the window
-- touches it, or in its corner. Once a visit: not again before the mouse has gone from there. Not if the
-- window was placed under it a moment ago, nor while a button is held with nothing on the cursor (a
-- window moved, the camera turned), nor in Edit Mode, where windows are arranged. Held with something
-- on the cursor (an item, a spell, a macro), it is carried to be dropped: the full window goes back so
-- it can go onto the action bars, and fills the screen again for a drop into it.
function methods:Pushed(key)
    if self.pushed or Clicks(self) then return end
    if GetTime() < self.quiet or Core.EditMode.active then return end
    if IsMouseButtonDown() and not GetCursorInfo() then return end
    local usable = self.window.options.usable
    if usable and not usable() then return end
    self.pushed = key or "corner"
    C_Timer.After(Edge.LOOK, self.looking) -- unguarded: self.looking is made by Core.Guard (Edge.New)
    self:Fill(not self.full)
end

-- A left click in a strip, while the section's switch wants one: each click is one change. Not in Edit Mode.
function methods:Clicked()
    if not Clicks(self) or Core.EditMode.active then return end
    local usable = self.window.options.usable
    if usable and not usable() then return end
    self:Fill(not self.full)
end

-- At rest in its zone at once, without motion: Window:Place calls it before it places the window.
function methods:Stop()
    if not self.away then return end
    local frame, window = self.frame, self.window
    self.away, self.full = false, false
    Escape(self, false)
    Menu(self, false)
    if self.clock then self.clock:Stop() end
    if self.strata then frame:SetFrameStrata(self.strata) end
    if self.level then frame:SetFrameLevel(self.level) end
    if frame.SetMouseClickEnabled and self.motion ~= nil then
        frame:SetMouseClickEnabled(self.clicks or false)
        frame:SetMouseMotionEnabled(self.motion or false)
    else
        frame:EnableMouse(self.clicks or false)
    end
    frame:EnableMouseWheel(self.wheel or false)
    self.back:SetShown(false)
    if window.skin then
        window.skin:Hold(false)
        window.skin:SetAlpha(1)
    end
    frame:SetClampedToScreen(true)
    frame:SetSize(self.width, self.height)
    if window.grip then
        window.grip:SetAlpha(1)
        window.grip:EnableMouse(true)
    end
    Content(self, nil)
end

-- If it may fill the screen (the section's first switch): docked along a screen edge, the window's
-- side there has its strip; docked in a corner, that corner has its square. Nothing else has one.
local function Strips(edge)
    local clicks = Clicks(edge)
    for _, strip in pairs(edge.strips) do
        if strip.SetMouseClickEnabled then strip:SetMouseClickEnabled(clicks) end
    end
    local zone = edge.zone and edge.settings.expand and Core.Dock.ZONES[edge.zone]
    local corner = zone and (zone.left or zone.right) and (zone.top or zone.bottom) and zone[1] -- TOPLEFT, ...
    local width = zone and Pixels(edge.frame, corner and Edge.CORNER or Edge.PIXELS)
    for side in pairs(SIDES) do
        local on = zone and not corner and zone[side] or false
        local strip = on and Strip(edge, side) or edge.strips[side]
        if strip then
            if not on then
                strip:Hide()
            else
                local across = side == "left" or side == "right"
                if across then strip:SetWidth(width) else strip:SetHeight(width) end
                local share = edge.window.options.strip
                if share then
                    if across then strip:SetHeight(UIParent:GetHeight() * share) else strip:SetWidth(UIParent:GetWidth() * share) end
                end
                strip:Show()
            end
        end
    end
    local square = corner and Strip(edge, "corner") or edge.strips.corner
    if not square then return end
    if corner then
        square:ClearAllPoints()
        square:SetPoint(corner, zone.left and -Out(edge, "left") or Out(edge, "right"),
            zone.top and Out(edge, "top") or -Out(edge, "bottom"))
        square:SetSize(width, width)
    end
    square:SetShown(corner and true or false)
end

-- The window was placed (Window:Place): docked to the zone of that name, or free (nil). Either way it may
-- fill the screen now (from its edge, or by its button), unless a step once failed.
function methods:Docked(name)
    self.zone = not self.off and name or nil
    self.placed = not self.off
    self.quiet = GetTime() + Edge.QUIET
    Strips(self)
end

-- A switch of the section Expand window was changed. Switched off, a window that fills the screen is
-- back in its zone at once; the background and the corners are as set now (the skin's too), the
-- strips as the switch says.
function methods:Update()
    if self.away and not self.settings.expand then return self.window:Place() end
    Strips(self)
    self.window:Refresh() -- its full screen button, there or not
    local skin = self.window.skin
    if skin and not self.away then skin:Fit() end
    if not self.back then return end
    Paint(self)
    if self.away then self.back:SetAlpha(self.cover * Opacity(self), self.cover) end
end

-- A fight begins (the game says so just before it locks protected frames): a protected window on its
-- way is put at the end of the way at once, so no step of the motion moves it in the fight.
Core.On("PLAYER_REGEN_DISABLED", function()
    for edge in pairs(edges) do
        if edge.away and edge.clock and edge.clock:IsRunning() and edge.frame:IsProtected() then
            edge.clock:Stop()
            Core.Safe("full screen", Step, edge, 1)
        end
    end
end)

-- The screen's size or the UI's scale changed: a strip that is a share of the screen's side takes its new length.
local function Resized()
    for edge in pairs(edges) do
        if edge.window.options.strip then Core.Safe("full screen", Strips, edge) end
    end
end
Core.On("DISPLAY_SIZE_CHANGED", Resized)
Core.On("UI_SCALE_CHANGED", Resized)

-- A switch of the section changed in a module's settings: every window that reads them is as set now.
local function Changed(name)
    local settings = Core.Settings(name)
    for edge in pairs(edges) do
        if edge.settings == settings then edge:Update() end
    end
end

-- Each module whose switches hold the section is followed once its addon has loaded (it described them
-- while its files were read): its changed hears of a switch of the section only after the windows have
-- taken it in.
local followed = {}
Core.On("ADDON_LOADED", function()
    for name, described in pairs(Core.described) do
        if sections[described.list] and not followed[name] then
            followed[name] = true
            local own = described.changed
            described.changed = function(key, ...)
                if Edge.KEYS[key] then Core.Safe("full screen", Changed, name) end
                if own then return own(key, ...) end
            end
        end
    end
end)

function Edge.New(window)
    local settings = window.options.edge
    local edge = setmetatable({ window = window, frame = window.frame, strips = {}, from = {}, to = {}, quiet = 0,
                                full = false, away = false, cover = 0,
                                settings = type(settings) == "table" and settings or Edge.DEFAULTS }, { __index = methods })
    -- Hidden, it is back in its zone at once: shown again, it is as it was before it filled the screen.
    edge.frame:HookScript("OnHide", Core.Guard("window", function()
        if edge.away then Core.Safe("full screen", window.Place, window) end
    end))
    edge.looking = Core.Guard("full screen", function() Look(edge) end) -- made once: the look while pushed
    edges[edge] = true
    return edge
end
