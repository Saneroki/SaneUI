local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Skin
--  A window's background and border: the dark tile the game's own dialogs
--  stand on (BACKDROP_DARK_DIALOG_32_32's background, repeated every 32 units
--  as the game repeats it), and a thin trim in Sane UI's colour (Core.GOLD), on
--  a plate with round corners (Shape.lua) as round as the window's settings say
--  (Corner radius; without settings, Shape's own).
--
--  Docked to a screen edge (Dock.lua) the window becomes one with that edge:
--  with Don't round corners on screen edges (on at first) the corners there are
--  square and the trim is out of the screen, so the fill ends flush with the
--  edge. The free sides keep both.
--
--  The skin is a frame inside the window that follows its size, one level
--  under the window: what the window itself draws (its texts, Edge's full
--  screen background) and its other children are drawn over it, whatever the
--  order they were made in. Children follow their parent's level, so the skin
--  stays under the window when that is raised or put back (Edge.lua).
--  Sized (its grip, or opening under the mouse) it fits its new size; its
--  corners are measured on the size the window was placed at (skin:Rest).
-------------------------------------------------------------------------------
local Skin = {}
Core.Skin = Skin

Skin.TILE = { file = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", size = 32 }

-- The window was placed: its corners are measured on its size now, and the skin fits its place.
local function Rest(skin)
    skin.shape:Base(skin:GetParent():GetSize())
    skin.shape:Fit()
end

-- Fits the place given (left, bottom, width, height), or the window's own.
local function Fit(skin, ...)
    skin.shape:Fit(...)
end

-- Gives the frame a skin and returns it. settings: the window's (Shape.Options), or nil.
function Skin.New(frame, settings)
    local skin = CreateFrame("Frame", nil, frame)
    skin:SetAllPoints()
    -- A child stands one level above its parent, over the parent's own textures and texts, whatever
    -- their layers. One level under it, the fill lies beneath them, as the game's chat puts the button
    -- under its frame (FloatingChatFrame.lua, ClickAnywhereButton).
    skin:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
    local shape = Core.Shape.New(skin, settings, frame)
    shape:Look({ file = Skin.TILE.file, size = Skin.TILE.size, trim = Core.GOLD })
    skin.shape, skin.Rest, skin.Fit = shape, Rest, Fit
    skin:SetScript("OnSizeChanged", function() Core.Safe("skin", Fit, skin) end)
    return skin
end
