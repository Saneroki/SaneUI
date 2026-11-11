local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Look
--  What the talk's parts share. No window over the world, but each part on a
--  plate of its own (Saneroki, 2026-11-11: the shades faded into each other;
--  the talk now in the make of the loot window and the guide's steps): round
--  corners, a thin border nearly black, no edge fading out, so two parts side
--  by side stay apart. A plate of no colour is a dark grey that darkens to its
--  foot; a reward's is its quality's colour, deepened; under the mouse the
--  border is grey, round a reward chosen gold. How solid the plates are is the
--  setting Shade behind the words (0: the words alone over the world). The words
--  in the game's outlined font of its nameplates, as the loot window's. The
--  parts stand in one frame of ours over the interface, in sight while the
--  interface is faded out (Quiet.lua), sized by the setting Size; it appears and
--  goes with a quick fade.
--
--      Look.Root()                 the frame the talk's parts stand in
--      Look.Text(parent, part)     a font string in that part's font (Look.SIZES)
--      Look.Plate(frame)           a plate behind a frame: plate:Paint(r, g, b) (none: dark), plate:SetLit(on),
--                                  plate:SetChosen(on), plate:Fit() (after the frame's size changed)
--      Look.Show(), Look.Hide()    the talk appears, or goes (quickly faded); Look.Gone(): at once
--      Look.Coins(copper), Look.Number(n)   money in the game's coins, a number with its separators
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = {}
ns.Look = Look

Look.SIZES = { name = 19, words = 15.5, count = 11, answer = 14, head = 13, reward = 13, detail = 11.5 }
Look.FADE = 0.3  -- seconds to appear or go
Look.GREY = { 0.62, 0.62, 0.62 }
Look.ROUND = 6   -- a plate's corners' radius, as the guide's steps over the world
Look.TRIM = 1    -- its border's width
Look.SHADE = 60  -- how solid the plates are at first, in % (the setting Shade behind the words)
Look.DARK = { { 0.16, 0.16, 0.18 }, { 0.07, 0.07, 0.08 } } -- a plate of no colour, at its top and its foot
Look.DEEP = { 0.5, 0.28 }  -- a coloured plate: its colour so far, at its top and its foot
Look.BORDER = { 0, 0, 0 }  -- nearly black (Look.BORDER_ALPHA)
Look.BORDER_ALPHA = 0.9
Look.LIT = { 0.5, 0.5, 0.5 } -- under the mouse, as a nameplate's border on your target
Look.GOLD = { 1, 0.82, 0 }   -- round a reward chosen

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
--  The plate: Core's shape of round corners and a thin border
-------------------------------------------------------------------------------
local plate = {}
plate.__index = plate

local function Solid()
    return ((ns.options and ns.options.shade) or Look.SHADE) / 100
end

-- Laid out at its frame's size (a plate that is not by the screen's edges needs only that).
function plate:Fit()
    local width, height = Core.Plain(self.frame:GetWidth()), Core.Plain(self.frame:GetHeight())
    if type(width) == "number" and type(height) == "number" and width > 0 and height > 0 then
        self.shape:Fit(0, 0, width, height)
    end
end

function plate:Draw()
    local solid = Solid()
    local trim = self.chosen and Look.GOLD or self.lit and Look.LIT or Look.BORDER
    self.shape:Look({ top = self.top, bottom = self.bottom, alpha = solid, trim = trim })
    -- The border goes with the plate: none without one, whole when lit or chosen.
    self.shape:SetAlpha(1, solid <= 0 and 0 or (self.lit or self.chosen) and 1 or Look.BORDER_ALPHA)
    self:Fit()
end

function plate:Paint(r, g, b)
    if r then
        local top, foot = Look.DEEP[1], Look.DEEP[2]
        self.top, self.bottom = { r * top, g * top, b * top }, { r * foot, g * foot, b * foot }
    else
        self.top, self.bottom = Look.DARK[1], Look.DARK[2]
    end
    self:Draw()
end

function plate:SetLit(on)
    on = on and true or false
    if on == self.lit then return end
    self.lit = on
    self:Draw()
end

function plate:SetChosen(on)
    on = on and true or false
    if on == self.chosen then return end
    self.chosen = on
    self:Draw()
end

function Look.Plate(frame)
    local made = setmetatable({ frame = frame, lit = false, chosen = false }, plate)
    made.shape = Core.Shape.New(frame, { radius = Look.ROUND, trim = Look.TRIM })
    made.shape:Follow()
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
