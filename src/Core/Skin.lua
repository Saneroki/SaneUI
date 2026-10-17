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
--  While another part fits it on every step of a motion (Edge.lua: skin:Hold),
--  a size change of its own fits nothing: once a step is enough.
--
--  The quiet tiles the game fills its own windows with, for what a module lets
--  the player choose as a background (a full screen's, a chat's bubbles):
--      Skin.TILES                  -- { key, text, file, size }, repeated every size units
--      Skin.Tile(key)              -- one of them; nil for none (a solid colour)
--      Skin.Choices(solid)         -- for a dropdown (Core.Options): solid's words first, then the tiles
-------------------------------------------------------------------------------
local Skin = {}
Core.Skin = Skin

Skin.TILE = { file = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", size = 32 }
Skin.TILES = {
    { key = "marble", text = "Marble", file = "Interface\\FrameGeneral\\UI-Background-Marble", size = 256 },
    { key = "rock", text = "Rock", file = "Interface\\FrameGeneral\\UI-Background-Rock", size = 512 },
    { key = "slate", text = "Slate", file = "Interface\\Collections\\CollectionsBackgroundTile", size = 256 },
    { key = "iron", text = "Iron", file = "Interface\\BlackMarket\\BlackMarketBackground-Tile", size = 256 },
    { key = "night", text = "Night", file = "Interface\\FrameGeneral\\UIFrameOribosBackground", size = 256 },
}
local tiles = {}
for _, tile in ipairs(Skin.TILES) do tiles[tile.key] = tile end

function Skin.Tile(key)
    return tiles[key]
end

-- The key of a solid colour is "solid".
function Skin.Choices(solid)
    local choices = { { "solid", solid } }
    for _, tile in ipairs(Skin.TILES) do choices[#choices + 1] = { tile.key, tile.text } end
    return choices
end

-- The window was placed: its corners are measured on its size now, and the skin fits its place.
local function Rest(skin)
    skin.shape:Base(skin:GetParent():GetSize())
    skin.shape:Fit()
end

-- Fits the place given (left, bottom, width, height), or the window's own.
local function Fit(skin, ...)
    skin.shape:Fit(...)
end

-- Another part fits it now, on every step of its motion (on), or no more.
local function Hold(skin, on)
    skin.held = on and true or nil
end

local function Sized(skin)
    if not skin.held then Fit(skin) end
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
    skin.shape, skin.Rest, skin.Fit, skin.Hold = shape, Rest, Fit, Hold
    skin:SetScript("OnSizeChanged", function() Core.Safe("skin", Sized, skin) end)
    return skin
end
