local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Look
--  What the talk's parts share (Saneroki, 2026-10-28: the talk see-through over
--  the world). As the guide over the world (Doc/guides/interface-style.md): no
--  window, no paper; words in Expressway with a thin dark outline straight on
--  the game, names in the game's own colours, a soft dark shade behind each
--  part whose sides fade out into the world (how dark: the setting Shade behind
--  the words). The parts stand in one frame of ours over the interface, in
--  sight while the interface is faded out (Quiet.lua), sized by the setting
--  Size; it appears and goes with a quick fade.
--
--      Look.Root()                 the frame the talk's parts stand in
--      Look.Text(parent, part)     a font string in that part's font (Look.SIZES)
--      Look.Shade(frame)           a soft shade behind a frame: shade:SetStrength(share of the setting)
--      Look.Show(), Look.Hide()    the talk appears, or goes (quickly faded); Look.Gone(): at once
--      Look.Coins(copper), Look.Number(n)   money in the game's coins, a number with its separators
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = {}
ns.Look = Look

Look.FONT = "Interface\\AddOns\\SaneUI_Lore\\Fonts\\Expressway.ttf"
Look.SIZES = { name = 19, words = 15.5, count = 11, answer = 14, head = 13, reward = 13, detail = 11.5 }
Look.FADE = 0.3  -- seconds to appear or go
Look.EDGE = 48   -- how far a shade's sides fade out
Look.GREY = { 0.62, 0.62, 0.62 }

local root
local fonts = {}
local shades = {} -- every shade made, to follow the setting
local from, to, began
local Fading

local function Font(part)
    if fonts[part] then return fonts[part] end
    local size = Look.SIZES[part]
    local font = CreateFont("SaneUILore" .. part)
    if not font:SetFont(Look.FONT, size, "OUTLINE") then
        -- The font could not be set: the game's, outlined, at that size.
        local base = rawget(_G, "GameFontHighlight")
        local file = base and base:GetFont()
        if file then font:SetFont(file, size, "OUTLINE") end
    end
    font:SetTextColor(1, 1, 1)
    font:SetShadowOffset(1, -1)
    font:SetShadowColor(0, 0, 0, 0.6)
    fonts[part] = font
    return font
end

function Look.Text(parent, part, layer)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFontObject(Font(part))
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    return text
end

-- Money in the game's coins (gold, silver, copper with their pictures), a number with the game's separators.
function Look.Coins(copper)
    local coins = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or rawget(_G, "GetCoinTextureString")
    return Core.Ask(coins, copper) or tostring(copper)
end

function Look.Number(amount)
    return Core.Ask(rawget(_G, "BreakUpLargeNumbers"), amount) or tostring(amount)
end

-------------------------------------------------------------------------------
--  The shade: dark in its middle, its two sides fading out
-------------------------------------------------------------------------------
local shade = {}
shade.__index = shade

local function Darkness()
    return ((ns.options and ns.options.shade) or 30) / 100
end

local function Gradient(texture, left, right)
    if texture.SetGradient and rawget(_G, "CreateColor") then
        texture:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, left), CreateColor(0, 0, 0, right))
    else
        texture:SetVertexColor(0, 0, 0, (left + right) / 2)
    end
end

function shade:SetStrength(strength)
    self.strength = strength or self.strength or 1
    local alpha = Darkness() * self.strength
    self.middle:SetColorTexture(0, 0, 0, alpha)
    Gradient(self.left, 0, alpha)
    Gradient(self.right, alpha, 0)
end

function Look.Shade(frame)
    local made = setmetatable({}, shade)
    made.left = frame:CreateTexture(nil, "BACKGROUND")
    made.middle = frame:CreateTexture(nil, "BACKGROUND")
    made.right = frame:CreateTexture(nil, "BACKGROUND")
    made.left:SetColorTexture(1, 1, 1, 1)
    made.right:SetColorTexture(1, 1, 1, 1)
    made.left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0)
    made.left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)
    made.left:SetWidth(Look.EDGE)
    made.middle:SetAllPoints(frame)
    made.right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
    made.right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0)
    made.right:SetWidth(Look.EDGE)
    made:SetStrength(1)
    shades[#shades + 1] = made
    return made
end

-- The setting changed: every shade anew, the talk at its size.
function Look.Update()
    for _, made in ipairs(shades) do made:SetStrength() end
    if root then root:SetScale(((ns.options and ns.options.size) or 100) / 100) end
end

-------------------------------------------------------------------------------
--  The frame the parts stand in, and its fade
-------------------------------------------------------------------------------
function Look.Root()
    if root then return root end
    root = CreateFrame("Frame", nil, UIParent)
    root:SetFrameStrata("HIGH") -- over the interface; the game's questions (DIALOG) and tooltips over the talk
    root:SetPoint("CENTER")
    root:SetSize(1, 1)
    if root.SetIgnoreParentAlpha then root:SetIgnoreParentAlpha(true) end -- in sight while the interface is not
    root:Hide()
    Fading = ns.Guard(function()
        local share = math.min(1, (GetTime() - began) / Look.FADE)
        root:SetAlpha(from + (to - from) * share)
        if share < 1 then return end
        root:SetScript("OnUpdate", nil)
        if to == 0 then root:Hide() end
    end)
    Look.Update()
    return root
end

local function Fade(target)
    from, to, began = root:IsShown() and root:GetAlpha() or 0, target, GetTime()
    root:SetScript("OnUpdate", Fading)
end

function Look.Show()
    Look.Root()
    if root:IsShown() and to == 1 then return end
    if not root:IsShown() then root:SetAlpha(0) end
    Fade(1)
    root:Show()
end

function Look.Hide()
    if not root or not root:IsShown() or to == 0 then return end
    Fade(0)
end

-- At once, without a fade (a fight, standing down).
function Look.Gone()
    if not root then return end
    root:SetScript("OnUpdate", nil)
    to = 0
    root:Hide()
end
