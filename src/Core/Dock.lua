local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Dock
--  Places a window snaps to, like to a magnet, when it is let go near one: the
--  four corners of the screen, the middle of each of its edges, and the middle
--  of the screen, for windows the player talks to (a vendor, a trainer, the
--  auction house).
--
--      TOPLEFT        TOP        TOPRIGHT
--      LEFT          CENTER         RIGHT
--      BOTTOMLEFT    BOTTOM   BOTTOMRIGHT
--
--  A docked window hangs on its zone, not on a place of its own: it stays at
--  the edge whatever its size, and grows away from the edge. It is docked until
--  it is dragged away. While a window is dragged, a tinted shape shows where
--  it would dock (Watch); only then is anything looked at every frame.
--
--  Watch can be given the zones a window may dock to on this drag (a set of
--  names: a title bar's drag outside Edit Mode only docks in the middle);
--  without, every zone.
--
--  A zone holds one window at a time (Saneroki, 2026-10-16): while a window is
--  docked there and shown, no other docks to it. A drag does not offer it (no
--  shape, let go there the window stays free), and a window that opens with
--  that zone kept stands free this time (Window.lua). Windows not shown hold
--  nothing, so the talk windows (a vendor, the auction house) share the middle.
--
--      Dock.Hold(frame, name)       -- the frame is docked to that zone now (nil: to none)
--      Dock.Holder(name, frame)     -- the shown window other than frame docked there, or nil
--
--  A window may keep a room from the screen's edges (its insets: { left, right,
--  top, bottom } in UI units, Window.lua's option insets): docked, it stands that
--  far from the edges it touches. Without, it is flush with them.
--
--  Find is plain numbers: it knows no frames. A window that docks is a child of
--  UIParent at its scale (Window.lua makes them so).
-------------------------------------------------------------------------------
local Dock = {}
Core.Dock = Dock

Dock.REACH = 60 -- how near a window's point must be to a zone's to dock there

-- [name] = { the window's point that goes there, the place on the screen: its share of the
-- screen's width from the left and of its height from the bottom }.
-- left, right, top, bottom (set below): the screen edges the window then touches; none in the middle.
Dock.ZONES = {
    CENTER = { "CENTER", 0.5, 0.5 },
    TOPLEFT = { "TOPLEFT", 0, 1 },
    TOP = { "TOP", 0.5, 1 },
    TOPRIGHT = { "TOPRIGHT", 1, 1 },
    LEFT = { "LEFT", 0, 0.5 },
    RIGHT = { "RIGHT", 1, 0.5 },
    BOTTOMLEFT = { "BOTTOMLEFT", 0, 0 },
    BOTTOM = { "BOTTOM", 0.5, 0 },
    BOTTOMRIGHT = { "BOTTOMRIGHT", 1, 0 },
}
for _, zone in pairs(Dock.ZONES) do
    for _, edge in ipairs({ "LEFT", "RIGHT", "TOP", "BOTTOM" }) do
        zone[edge:lower()] = zone[1]:find(edge) ~= nil
    end
end

-- How far from its zone's point on the screen a window with those insets stands (nil: none).
local function Offset(zone, insets)
    if not insets then return 0, 0 end
    local x = zone.left and (insets.left or 0) or zone.right and -(insets.right or 0) or 0
    local y = zone.bottom and (insets.bottom or 0) or zone.top and -(insets.top or 0) or 0
    return x, y
end

-- The zone a window of that place and size would dock to on a screen that large; nil: none.
-- left and bottom are counted from the screen's lower left corner. only: the names it may dock to;
-- insets: the room it keeps from the screen's edges.
function Dock.Find(left, bottom, width, height, screenWidth, screenHeight, only, insets)
    local found, nearest = nil, Dock.REACH * Dock.REACH
    for name, zone in pairs(Dock.ZONES) do
        if not only or only[name] then
            local dx, dy = Offset(zone, insets)
            local x = left + (zone.left and 0 or zone.right and width or width / 2) - zone[2] * screenWidth - dx
            local y = bottom + (zone.bottom and 0 or zone.top and height or height / 2) - zone[3] * screenHeight - dy
            local distance = x * x + y * y
            if distance <= nearest then found, nearest = name, distance end
        end
    end
    return found
end

-- Where a window of that size stands docked to a zone: its lower left corner, from the screen's.
function Dock.Rect(name, width, height, screenWidth, screenHeight, insets)
    local zone = Dock.ZONES[name]
    local dx, dy = Offset(zone, insets)
    return zone[2] * screenWidth - (zone.left and 0 or zone.right and width or width / 2) + dx,
        zone[3] * screenHeight - (zone.bottom and 0 or zone.top and height or height / 2) + dy
end

-- The zone the frame would dock to where it stands now (only: the names it may dock to).
function Dock.Of(frame, only, insets)
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    if not left or not bottom then return nil end -- it has no place yet
    return Dock.Find(left, bottom, frame:GetWidth(), frame:GetHeight(), UIParent:GetWidth(), UIParent:GetHeight(), only, insets)
end

local holders = setmetatable({}, { __mode = "k" }) -- [frame] = the zone it is docked to

function Dock.Hold(frame, name)
    holders[frame] = name
end

function Dock.Holder(name, frame)
    for other, zone in pairs(holders) do
        if zone == name and other ~= frame and other:IsShown() then return other end
    end
    return nil
end

-- Hangs the frame on a zone: on the screen's point of the same name, so it stays at its edge when the
-- screen's size or the UI scale changes (that far from it, with insets).
function Dock.Anchor(frame, name, insets)
    local zone = Dock.ZONES[name]
    local x, y = Offset(zone, insets)
    frame:ClearAllPoints()
    frame:SetPoint(zone[1], UIParent, zone[1], x, y)
end

-------------------------------------------------------------------------------
--  While a window is dragged: the shape of where it would dock
-------------------------------------------------------------------------------
local watcher, ghost
local held, over, allowed, room -- the window in hand; the zone its shape is shown at; the zones it may dock
                                -- to; the room it keeps from the screen's edges

local function Look()
    local zone = Dock.Of(held, allowed, room)
    if zone == over then return end
    over = zone
    if zone then
        ghost:SetSize(held:GetSize())
        Dock.Anchor(ghost, zone, room)
    end
    ghost:SetShown(zone ~= nil)
end

-- The window is in hand from now on, until Drop. only: the names of the zones it may dock to; nil: all.
-- A zone another window holds is not among them. insets: the room it keeps from the screen's edges.
function Dock.Watch(frame, only, insets)
    if not watcher then
        ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetFrameStrata("HIGH")
        local tint = ghost:CreateTexture(nil, "BACKGROUND")
        tint:SetAllPoints()
        tint:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.35)
        watcher = CreateFrame("Frame")
        -- An error here would come again every frame: the shape goes, the drag itself is the game's.
        watcher:SetScript("OnUpdate", function()
            local ok, problem = pcall(Look)
            if ok then return end
            watcher:Hide()
            ghost:Hide()
            Core.NoteError("dock", problem)
        end)
    end
    local free = {}
    for name in pairs(Dock.ZONES) do
        if (not only or only[name]) and not Dock.Holder(name, frame) then free[name] = true end
    end
    held, over, allowed, room = frame, nil, free, insets
    ghost:Hide()
    watcher:Show()
end

-- The window was let go. Returns the zone it docks to, nil for none.
function Dock.Drop()
    if not held then return nil end
    local frame, only, insets = held, allowed, room
    held, allowed, room = nil, nil, nil
    watcher:Hide()
    ghost:Hide()
    return Dock.Of(frame, only, insets)
end
