local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Look
--  What the talk's parts share. No window over the world, but each part on a
--  plate of its own (Saneroki, 2026-11-11: first the shades faded into each
--  other, then "instead of the black sharp border ... a fuzzy fadeout with
--  rounded corners so they blend naturally into the world"): round corners and
--  no border, its edge fading out softly into the world, all of it inside the
--  part's own frame, so two parts side by side stay apart. The panels (the
--  words, the quest) fade wider than the bars (an answer, a reward, a picture).
--  A plate of no colour is a dark grey; a reward's is its quality's colour,
--  deepened; under the mouse a little lighter. (A quest's rewards are lines of
--  the loot rolls' make, Quest.lua.) How solid
--  the plates are is the setting Shade behind the words (0: the words alone over
--  the world). The words
--  in the game's outlined font of its nameplates, as the loot window's. The
--  parts stand in one frame of ours over the interface, in sight while the
--  interface is faded out (Quiet.lua), sized by the setting Size; it appears and
--  goes with a quick fade.
--
--      Look.Root()                 the frame the talk's parts stand in
--      Look.Text(parent, part)     a font string in that part's font (Look.SIZES)
--      Look.Plate(frame, corner)   a plate behind a frame, its soft corners that large (Look.PANEL, Look.BAR):
--                                  plate:Paint(r, g, b) (none: dark), plate:SetLit(on), plate:Fit() (after the
--                                  frame's size changed)
--      Look.Show(), Look.Hide()    the talk appears, or goes (quickly faded); Look.Gone(): at once
--      Look.Coins(copper), Look.Number(n)   money in the game's coins, a number with its separators
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = {}
ns.Look = Look

Look.SIZES = { name = 19, words = 15.5, count = 11, answer = 14, head = 13, reward = 13, detail = 11.5 }
Look.FADE = 0.3  -- seconds to appear or go
Look.GREY = { 0.62, 0.62, 0.62 }
Look.SHADE = 60  -- how solid the plates are at first, in % (the setting Shade behind the words)
-- A plate's soft corner, as large as this (Core's Shape.SOFT_CORNER: half of it the fade, three eighths the round):
Look.PANEL = 32  -- the words' and the quest's (a fade of 16)
Look.BAR = 14    -- an answer's, a reward's, a picture's (a fade of 7)
Look.DARK = { 0.1, 0.1, 0.12 } -- a plate of no colour
Look.DEEP = 0.42               -- a coloured plate: its colour so far
Look.LIGHT = 0.12              -- under the mouse: that share of the way to white

-- The game's fonts of its nameplates' names, outlined (the loot window's), then its own plain one.
local FACES = { "SystemFont_NamePlate_Outlined", "SystemFont_NamePlate", "GameFontHighlight" }

local root
local fonts = {}
local plates = {} -- every plate made, to follow the setting
local from, to, began
local Fading

-- The game's font file and outline (asked once); nil where it tells none.
local face, outline
local function Face()
    if face then return face, outline end
    for _, name in ipairs(FACES) do
        local object = rawget(_G, name)
        if type(object) == "table" and object.GetFont then
            local file, _, flags = object:GetFont()
            if type(file) == "string" then
                face, outline = file, (flags and flags ~= "") and flags or "OUTLINE"
                return face, outline
            end
        end
    end
end

local function Font(part)
    if fonts[part] then return fonts[part] end
    local font = CreateFont("SaneUILore" .. part)
    local file, flags = Face()
    if file then font:SetFont(file, Look.SIZES[part], flags) end
    font:SetTextColor(1, 1, 1)
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
    return Core.Coins(copper) or Core.Ask(coins, copper) or tostring(copper)
end

function Look.Number(amount)
    return Core.Ask(rawget(_G, "BreakUpLargeNumbers"), amount) or tostring(amount)
end

-------------------------------------------------------------------------------
--  The plate: nine pieces of Core's soft corner, its edge fading out
-------------------------------------------------------------------------------
-- The corner picture (white, its alpha the fade) turned by its texture coordinates; a side is its last column or row
-- (the straight edge's fade) stretched, the middle its whole part.
local EDGE = 63 / 64
local PIECES = {
    { "TOPLEFT", 0, 1, 0, 1 }, { "TOPRIGHT", 1, 0, 0, 1 }, { "BOTTOMLEFT", 0, 1, 1, 0 }, { "BOTTOMRIGHT", 1, 0, 1, 0 },
    { "TOP", EDGE, 1, 0, 1 }, { "BOTTOM", EDGE, 1, 1, 0 }, { "LEFT", 0, 1, EDGE, 1 }, { "RIGHT", 1, 0, EDGE, 1 },
    { "MIDDLE", EDGE, 1, EDGE, 1 },
}

local plate = {}
plate.__index = plate

local function Solid()
    return ((ns.options and ns.options.shade) or Look.SHADE) / 100
end

local function Toward(colour, target, share)
    return colour[1] + (target[1] - colour[1]) * share, colour[2] + (target[2] - colour[2]) * share,
        colour[3] + (target[3] - colour[3]) * share
end

-- Its corners as large as wanted, but never more than half its frame's width or height.
function plate:Fit()
    local width, height = Core.Plain(self.frame:GetWidth()), Core.Plain(self.frame:GetHeight())
    local size = self.corner
    if type(width) == "number" and type(height) == "number" and width > 0 and height > 0 then
        size = math.min(size, width / 2, height / 2)
    end
    for index = 1, 4 do self.pieces[index]:SetSize(size, size) end
end

function plate:Draw()
    local r, g, b = self.colour[1], self.colour[2], self.colour[3]
    if self.lit then r, g, b = Toward({ r, g, b }, { 1, 1, 1 }, Look.LIGHT) end
    self.alpha = Solid()
    for _, piece in ipairs(self.pieces) do piece:SetVertexColor(r, g, b, self.alpha) end
    self:Fit()
end

function plate:Paint(r, g, b)
    if r then
        self.colour = { r * Look.DEEP, g * Look.DEEP, b * Look.DEEP }
    else
        self.colour = Look.DARK
    end
    self:Draw()
end

function plate:SetLit(on)
    on = on and true or false
    if on == self.lit then return end
    self.lit = on
    self:Draw()
end

function Look.Plate(frame, corner)
    local made = setmetatable({ frame = frame, corner = corner or Look.PANEL, lit = false, pieces = {} }, plate)
    local file = Core.Shape.SOFT_CORNER
    local at = {}
    for index, piece in ipairs(PIECES) do
        local texture = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        texture:SetTexture(file)
        texture:SetTexCoord(piece[2], piece[3], piece[4], piece[5])
        made.pieces[index] = texture
        at[piece[1]] = texture
    end
    for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
        at[corner]:SetPoint(corner, frame, corner)
    end
    -- The sides and the middle between the corners: they follow the frame's size by themselves.
    local function Between(texture, from, fromPoint, to, toPoint)
        texture:SetPoint("TOPLEFT", from, fromPoint)
        texture:SetPoint("BOTTOMRIGHT", to, toPoint)
    end
    Between(at.TOP, at.TOPLEFT, "TOPRIGHT", at.TOPRIGHT, "BOTTOMLEFT")
    Between(at.BOTTOM, at.BOTTOMLEFT, "TOPRIGHT", at.BOTTOMRIGHT, "BOTTOMLEFT")
    Between(at.LEFT, at.TOPLEFT, "BOTTOMLEFT", at.BOTTOMLEFT, "TOPRIGHT")
    Between(at.RIGHT, at.TOPRIGHT, "BOTTOMLEFT", at.BOTTOMRIGHT, "TOPRIGHT")
    Between(at.MIDDLE, at.TOPLEFT, "BOTTOMRIGHT", at.BOTTOMRIGHT, "TOPLEFT")
    made:Paint()
    plates[#plates + 1] = made
    return made
end

-- The setting changed: every plate anew, the talk at its size.
function Look.Update()
    for _, made in ipairs(plates) do made:Draw() end
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
