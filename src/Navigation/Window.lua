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
--  player. Going full screen and back returns each to where it was. Full, a row
--  of buttons at the map's top left chooses how it is drawn (the setting Map
--  view; both views draw it so): Parchment, Scrying, and Atlas while its module
--  is there (Painted.lua); the dropdown Classic windows offers the game's own
--  minimap and map.
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
Window.BUTTON_WIDTH, Window.BUTTON_HEIGHT = 120, 24
Window.INSET = 12 -- the buttons' row from the map's top left corner
Window.GAP = 4    -- between two buttons

local frame, handle, inside, bar, buttons
local small, full = ns.Camera.New(), ns.Camera.New() -- each view's camera
Window.small, Window.full = small, full

-- The buttons as the settings say: the view drawn lit.
local function Light()
    local drawn = ns.View()
    for key, button in pairs(buttons) do
        if key == drawn then button:LockHighlight() else button:UnlockHighlight() end
    end
end

-- The buttons of the views offered (Navigation.lua, Offer), in a row from the map's top left corner.
function Window.Arrange()
    if not buttons then return end
    local previous
    for _, key in ipairs(ns.VIEWS) do
        local button, offered = buttons[key], ns.Offered(key)
        button:SetShown(offered)
        if offered then
            button:ClearAllPoints()
            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", Window.GAP, 0)
            else
                button:SetPoint("TOPLEFT", Window.INSET, -Window.INSET)
            end
            previous = button
        end
    end
    Light()
end

-- The view chosen changed (its button, or the settings): the buttons, and the map drawn anew.
function Window.Restyle()
    if not frame then return end
    Light()
    ns.Canvas.Refresh()
end

-- Kept in the settings, so profiles keep it; Core tells the module of the change (Restyle).
local function Choose(button)
    if button.key ~= ns.options.view then Core.Set(ns.name, "view", button.key) end
end

local function Tip(button)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
    GameTooltip:SetText(ns.TEXT.views[button.key], 1, 1, 1)
    GameTooltip:AddLine(ns.TEXT.viewTips[button.key], nil, nil, nil, true)
    GameTooltip:Show()
end

-- The window stands, small or full: that view's camera, and the map at its size.
local function Placed()
    local filled = handle.edge and handle.edge.full or false
    ns.Canvas.Use(filled and full or small)
    bar:SetShown(filled)
    ns.Canvas.Open()
end

-- On its way to the full screen (full) or back, the window to be width x height: the map goes with it,
-- into the other view's camera; its buttons wait until it stands.
local function Filled(on, width, height)
    bar:Hide()
    local top = on and Core.Window.BAR or 0 -- full, the title bar is over the map
    ns.Canvas.Morph(on and full or small, width or 0, (height or 0) - top)
end

local function Moving(share)
    ns.Canvas.Step(share)
end

local function Back()
    if handle.edge then handle.edge:Fill(false) end
end

-- The dropdown Classic windows: the game's own minimap (the switch, kept) and map (once).
local CLASSIC = {
    { text = ns.TEXT.classicMinimap, show = function() ns.Safe("classic minimap", Core.Set, ns.name, "nativeMinimap", true) end },
    { text = ns.TEXT.classicMap, show = function() ns.Safe("classic map", ns.Native.ShowMap) end },
}

function Window.Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("LOW") -- the game's minimap's layer: the queue's eye and the game's bars stand over it
    Window.frame = frame
    inside = CreateFrame("Frame", nil, frame)
    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options, content = inside, classic = CLASSIC,
        first = { dock = "TOPRIGHT", width = Window.WIDTH, height = Window.HEIGHT },
        minWidth = Window.WIDTH / 2, minHeight = Window.HEIGHT / 2,
        docked = function() ns.Guarded(Placed) end,
        filled = function(on, width, height) ns.Guarded(Filled, on, width, height) end,
        moving = function(share) ns.Guarded(Moving, share) end,
        close = function() ns.Guarded(Back) end, -- back to its corner: closed, the corner could not bring it again
    })
    inside:SetAllPoints(handle.inside)
    local canvas = ns.Canvas.Build(inside)

    bar = CreateFrame("Frame", nil, inside)
    bar:SetAllPoints()
    bar:SetFrameLevel(canvas:GetFrameLevel() + 30) -- over the map, its marks and the game's minimap
    bar:Hide()
    buttons = {}
    for _, key in ipairs(ns.VIEWS) do
        local button = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
        button:SetSize(Window.BUTTON_WIDTH, Window.BUTTON_HEIGHT)
        button:SetText(ns.TEXT.views[key])
        button.key = key
        button:SetScript("OnClick", ns.Guard(Choose))
        button:SetScript("OnEnter", ns.Guard(Tip))
        button:SetScript("OnLeave", GameTooltip_Hide)
        buttons[key] = button
    end
    Window.Arrange()
    handle:Place() -- where it was left; at its first place and size if it never was moved
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

-- Our map at a map the game was asked for (Native.lua): full screen, the map whole in it.
function Window.OpenTo(map)
    if not handle or not handle.edge then return end
    if not frame:IsShown() then
        frame:Show()
        handle:Place()
    end
    if map then ns.Canvas.Fit(full, map, UIParent:GetWidth(), UIParent:GetHeight() - Core.Window.BAR) end
    if handle.edge.full then
        ns.Canvas.Use(full)
        ns.Canvas.Refresh()
    else
        handle.edge:Fill(true)
    end
end

-- The game's minimap key: the window shown or hidden (hidden, it lets go of every texture).
function Window.ToggleShown()
    if not frame then return end
    if frame:IsShown() then
        ns.Canvas.Close()
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
    ns.Canvas.Close()
    frame:Hide()
end
