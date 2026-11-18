local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Arrange
--  How SaneUI's windows find their places in Edit Mode, beside the box each is
--  dragged by (Window.lua). Saneroki, 2026-11-18: "During edit mode, can you
--  add a checkbox to toggle snap to hotcorner and a checkbox to "snap to grid"
--  that will put things on a grid. Native windows have the red guide lines to
--  display if things are centered to something. Can you enable that edit mode
--  functionality into our edit mode widgets as well."
--
--  The panel: a small one of SaneUI's under the game's Edit Mode window, in the
--  look of Edit Mode's own dialogs, while Edit Mode is open; two ticks, kept in
--  Core's settings (Saved.lua; no control on the options pages):
--    Snap to hot corners  a window let go near a corner of the screen, the
--                         middle of an edge or the screen's middle docks there
--                         (Dock.lua), and its hot corner or edge fills the
--                         screen with it; off, it stays where it was let go
--                         (snapCorners, on at first)
--    Snap to grid         a free window let go goes onto the nearest lines of
--                         Edit Mode's grid (the game's Grid Spacing), shown or
--                         not (snapGrid, off at first); off, as before: only
--                         near a line, while the game snaps and shows its grid
--
--  The guide lines: while a window of ours is dragged by its box and the game
--  snaps (Edit Mode's own Snap, IsSnapEnabled, only read), a red line as the
--  game's own (MagnetismPreviewLineTemplate: red, 1.5 pixels, across the
--  screen) where an edge or the middle of the window comes within
--  Arrange.REACH (the game's magnetism range) of the screen's middle or edge,
--  or of an edge or the middle of another window of ours or of a frame of the
--  game's that Edit Mode shows. Let go, it goes onto those lines, before the
--  grid. Edit Mode's frames are only read (their places, their Selection
--  shown), never written: the game's own frames do not snap to ours.
--
--      Core.Arrange.Start(frame)    a drag of that frame begins: its lines while it moves
--      Core.Arrange.Stop()          it is let go: how far it goes onto its lines, x and y (screen units; nil: none)
--      Core.Arrange.Corners()       whether a window docks where it is let go (Snap to hot corners)
--      Core.Arrange.Grid()          the grid's spacing to put a free window on, and whether always; nil: none
-------------------------------------------------------------------------------
local Arrange = {}
Core.Arrange = Arrange
local Plain = Core.Plain

Arrange.REACH = 8      -- how near a line an edge or middle comes before it is drawn and snapped to (EditModeMagnetismManager's)
Arrange.SPACING = 100  -- the grid's spacing where the game tells none
Arrange.LINE = 1.5     -- a guide line's thickness, in pixels (MagnetismPreviewLineTemplate's)
Arrange.COLOUR = { 1, 0, 0 } -- and its colour
Arrange.WIDTH = 300    -- the panel's width
Arrange.TEXT = {
    title = "SaneUI",
    corners = "Snap to hot corners",
    cornersTip = "A window let go near a corner of the screen, the middle of an edge or the screen's middle docks there, and its hot corner or edge fills the screen with it. Off: it stays exactly where you let it go.",
    grid = "Snap to grid",
    gridTip = "A window let go goes onto the nearest lines of Edit Mode's grid, at its Grid Spacing, whether the grid shows or not. Off: only near a line, while Edit Mode snaps and shows its grid. Edit Mode's own Snap also draws red guide lines where a window lines up with the screen's middle or another frame.",
}

local function Setting(key) return (Core.general or {})[key] end

function Arrange.Corners()
    return Setting("snapCorners") ~= false
end

-- The game's Edit Mode, only read: its manager while it snaps.
local function Manager()
    local manager = rawget(_G, "EditModeManagerFrame")
    if type(manager) ~= "table" then return nil end
    return manager
end

local function Snapping()
    local manager = Manager()
    if not (Core.EditMode.active and manager and type(manager.IsSnapEnabled) == "function") then return false end
    return Core.Ask(manager.IsSnapEnabled, manager) == true
end

function Arrange.Grid()
    local manager = Manager()
    local grid = manager and rawget(manager, "Grid")
    local spacing = type(grid) == "table" and Plain(rawget(grid, "gridSpacing")) or nil
    if type(spacing) ~= "number" or spacing <= 0 then spacing = nil end
    if Setting("snapGrid") == true then return spacing or Arrange.SPACING, true end
    if not (spacing and Snapping() and Plain(grid:IsShown())) then return nil end
    return spacing, false
end

-------------------------------------------------------------------------------
--  The guide lines
-------------------------------------------------------------------------------
local held          -- the frame in hand
local lines         -- [x or y] = the line on the screen
local targets       -- { x = { ... }, y = { ... } }: where lines may be, in screen units
local found         -- { x = by, y = by }: how far the frame goes onto them, as last looked at
local watch         -- the frame whose OnUpdate looks while one is in hand

-- How many screen units a frame's are.
local function Ratio(frame)
    local own, screen = Plain(frame:GetEffectiveScale()), Plain(UIParent:GetEffectiveScale())
    if type(own) == "number" and type(screen) == "number" and own > 0 and screen > 0 then return own / screen end
    return 1
end

-- A frame's sides in screen units: left, right, bottom, top; nil where the game does not tell them.
local function Sides(frame)
    local left, right = Plain(frame:GetLeft()), Plain(frame:GetRight())
    local bottom, top = Plain(frame:GetBottom()), Plain(frame:GetTop())
    if type(left) ~= "number" or type(right) ~= "number" or type(bottom) ~= "number" or type(top) ~= "number" then
        return nil
    end
    local ratio = Ratio(frame)
    return left * ratio, right * ratio, bottom * ratio, top * ratio
end

local function Add(frame)
    local left, right, bottom, top = Sides(frame)
    if not left then return end
    local xs, ys = targets.x, targets.y
    xs[#xs + 1], xs[#xs + 2], xs[#xs + 3] = left, (left + right) / 2, right
    ys[#ys + 1], ys[#ys + 2], ys[#ys + 3] = bottom, (bottom + top) / 2, top
end

-- Where lines may be while this frame moves: the screen's middle and edges, our other windows shown, the game's
-- frames Edit Mode shows with their boxes. Looked at once a drag: nothing else moves meanwhile.
local function Targets(frame)
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    targets = { x = { 0, width / 2, width }, y = { 0, height / 2, height } }
    for _, window in ipairs(Core.Window and Core.Window.All() or {}) do
        local other = window.frame
        if other ~= frame and Plain(other:IsVisible()) then Add(other) end
    end
    local manager = Manager()
    local systems = manager and rawget(manager, "registeredSystemFrames")
    for _, system in ipairs(type(systems) == "table" and systems or {}) do
        local selection = type(system) == "table" and rawget(system, "Selection")
        if type(selection) == "table" and Plain(selection:IsShown()) and Plain(system:IsVisible()) then Add(system) end
    end
end

-- The least way from one of the three points to one of the lines, within reach: the way and the line; nil for none.
local function Nearest(points, list)
    local by, at
    for _, point in ipairs(points) do
        for _, line in ipairs(list) do
            local way = line - point
            if math.abs(way) <= Arrange.REACH and (not by or math.abs(way) < math.abs(by)) then by, at = way, line end
        end
    end
    return by, at
end

local function Line(axis)
    lines = lines or {}
    local line = lines[axis]
    if line then return line end
    line = watch:CreateTexture(nil, "OVERLAY")
    line:SetColorTexture(Arrange.COLOUR[1], Arrange.COLOUR[2], Arrange.COLOUR[3], 1)
    lines[axis] = line
    return line
end

-- A line's thickness in UI units: so many pixels of the screen.
local function Thickness()
    local pixel = rawget(_G, "PixelUtil")
    if type(pixel) == "table" and type(pixel.GetNearestPixelSize) == "function" then
        local size = Core.Ask(pixel.GetNearestPixelSize, Arrange.LINE, UIParent:GetEffectiveScale(), 1)
        if type(size) == "number" and size > 0 then return size end
    end
    return Arrange.LINE
end

-- A line across the screen at that place (x: from its top to its bottom; y: from its left to its right), or none.
local function Draw(axis, at)
    local line = Line(axis)
    if not at then return line:Hide() end
    line:ClearAllPoints()
    if axis == "x" then
        line:SetPoint("TOP", UIParent, "TOPLEFT", at, 0)
        line:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", at, 0)
        line:SetWidth(Thickness())
    else
        line:SetPoint("LEFT", UIParent, "BOTTOMLEFT", 0, at)
        line:SetPoint("RIGHT", UIParent, "BOTTOMRIGHT", 0, at)
        line:SetHeight(Thickness())
    end
    line:Show()
end

-- Where the frame in hand stands now: the lines it meets drawn, how far it would go onto them kept.
function Arrange.Look()
    found = {}
    local left, right, bottom, top
    if held and Snapping() then left, right, bottom, top = Sides(held) end
    if not left then
        Draw("x", nil)
        Draw("y", nil)
        return
    end
    local byX, atX = Nearest({ left, (left + right) / 2, right }, targets.x)
    local byY, atY = Nearest({ bottom, (bottom + top) / 2, top }, targets.y)
    found.x, found.y = byX, byY
    Draw("x", atX)
    Draw("y", atY)
end

function Arrange.Start(frame)
    if not watch then
        watch = CreateFrame("Frame", nil, UIParent)
        watch:SetAllPoints(UIParent)
        watch:SetFrameStrata("HIGH") -- as Edit Mode's own lines (MagnetismPreviewLinesContainer)
        -- An error here would come again every frame: the lines go, the drag itself is the game's.
        watch:SetScript("OnUpdate", Core.Guard("Edit Mode", function()
            local ok, problem = pcall(Arrange.Look)
            if ok then return end
            held = nil
            watch:Hide()
            Core.NoteError("guide lines", problem)
        end))
    end
    held, found = frame, {}
    Targets(frame)
    watch:Show()
end

function Arrange.Stop()
    if not held then return nil end
    Core.Safe("Edit Mode", Arrange.Look)
    held = nil
    if watch then
        watch:Hide()
        Draw("x", nil)
        Draw("y", nil)
    end
    return found and found.x, found and found.y
end

-------------------------------------------------------------------------------
--  The panel
-------------------------------------------------------------------------------
local panel

local function Tick(parent, key, text, tip, y)
    local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    box:SetSize(26, 26)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    local word = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    word:SetPoint("LEFT", box, "RIGHT", 4, 0)
    word:SetText(text)
    box:SetHitRectInsets(0, -(Arrange.WIDTH - 70), 0, 0) -- its words click it too
    box:SetScript("OnClick", Core.Guard("Edit Mode", function(self)
        Core.Set(Core.name, key, self:GetChecked() and true or false)
    end))
    Core.Tip(box, text, tip)
    box.key = key
    return box
end

local function Shown()
    panel.corners:SetChecked(Arrange.Corners())
    panel.grid:SetChecked(Setting("snapGrid") == true)
end

local function Panel()
    if panel then return panel end
    panel = CreateFrame("Frame", nil, UIParent)
    panel:SetFrameStrata("DIALOG")
    panel:SetSize(Arrange.WIDTH, 110)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    local ok, border = pcall(CreateFrame, "Frame", nil, panel, "DialogBorderTranslucentTemplate")
    if ok and border then border:SetAllPoints() end
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(Arrange.TEXT.title)
    panel.title = title
    panel.corners = Tick(panel, "snapCorners", Arrange.TEXT.corners, Arrange.TEXT.cornersTip, -40)
    panel.grid = Tick(panel, "snapGrid", Arrange.TEXT.grid, Arrange.TEXT.gridTip, -70)
    panel:Hide()
    return panel
end

-- Under the game's Edit Mode window while that shows, else at the screen's top.
local function Place()
    panel:ClearAllPoints()
    local manager = Manager()
    if manager and type(manager.IsShown) == "function" and Plain(manager:IsShown()) then
        panel:SetPoint("TOP", manager, "BOTTOM", 0, -4)
    else
        panel:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end
end

Core.EditMode.Watch(Core.Guard("Edit Mode", function(active)
    if not active then
        if panel then panel:Hide() end
        return Arrange.Stop()
    end
    Panel()
    Place()
    Shown()
    panel:Show()
end))

-- Changed elsewhere (a profile, the tick itself): the ticks show it (Saved.lua tells).
function Arrange.Changed()
    if panel then Shown() end
end

-- For the tests.
function Arrange.Panel() return panel end
function Arrange.Lines() return lines end
