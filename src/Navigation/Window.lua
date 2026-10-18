local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Window
--  The map's window, one of Core's (kind screen): docked in the screen's top
--  right corner, and filling the screen when the mouse goes into that corner
--  (Edge.lua); the corner again, Esc or its close button brings it back. Small
--  it shows nothing yet and takes no click, so the game's minimap under it
--  works as before. Full, it shows the map (Canvas.lua) with a row of buttons
--  at its top left: the three ways to draw it, the one chosen lit.
--
--  Laid out only once the window stands (Core's docked hook), never on the
--  steps of its way to the full screen and back.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Window = {}
ns.Window = Window

Window.WIDTH, Window.HEIGHT = 200, 200 -- small, as large as the minimap it is to become
Window.BUTTON_WIDTH, Window.BUTTON_HEIGHT = 120, 24
Window.INSET = 12 -- the buttons' row from the map's top left corner
Window.GAP = 4    -- between two buttons

local frame, handle, inside, buttons

-- The buttons as the settings say: the view chosen lit.
local function Light()
    for key, button in pairs(buttons) do
        if key == ns.options.view then button:LockHighlight() else button:UnlockHighlight() end
    end
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

-- The window stands: full, the map at its size; small, nothing in it.
local function Placed()
    if handle.edge and handle.edge.full then
        inside:Show()
        ns.Canvas.Open()
    else
        inside:Hide()
        ns.Canvas.Close()
    end
end

-- On its way to the full screen: the map is there to come in once it stands (Edge fades it in).
local function Filled(full)
    if full then inside:Show() end
end

local function Back()
    if handle.edge then handle.edge:Fill(false) end
end

function Window.Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("MEDIUM")
    Window.frame = frame
    inside = CreateFrame("Frame", nil, frame)
    inside:Hide()
    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options, content = inside,
        first = { dock = "TOPRIGHT", width = Window.WIDTH, height = Window.HEIGHT },
        minWidth = Window.WIDTH / 2, minHeight = Window.HEIGHT / 2,
        docked = function() ns.Guarded(Placed) end,
        filled = function(full) ns.Guarded(Filled, full) end,
        close = function() ns.Guarded(Back) end, -- back to its corner: closed, the corner could not bring it again
    })
    inside:SetAllPoints(handle.inside)
    local canvas = ns.Canvas.Build(inside)

    buttons = {}
    local previous
    for _, key in ipairs(ns.VIEWS) do
        local button = CreateFrame("Button", nil, inside, "UIPanelButtonTemplate")
        button:SetSize(Window.BUTTON_WIDTH, Window.BUTTON_HEIGHT)
        button:SetFrameLevel(canvas:GetFrameLevel() + 10) -- over the map's layers
        button:SetText(ns.TEXT.views[key])
        button.key = key
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", Window.GAP, 0)
        else
            button:SetPoint("TOPLEFT", Window.INSET, -Window.INSET)
        end
        button:SetScript("OnClick", ns.Guard(Choose))
        button:SetScript("OnEnter", ns.Guard(Tip))
        button:SetScript("OnLeave", GameTooltip_Hide)
        buttons[key], previous = button, button
    end
    Light()
    handle:Place() -- where it was left; at its first place and size if it never was moved
end

-- /sane map: the full screen and back.
function Window.Toggle()
    if handle and handle.edge then handle.edge:Fill(not handle.edge.full) end
end

-- /sane map reset: its first place and size.
function Window.Reset()
    if handle then handle:Reset() end
end

-- The module stood down (GiveBack): the window goes.
function Window.Hide()
    if frame then frame:Hide() end
end
