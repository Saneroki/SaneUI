local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Row
--  One line of the loot window, a bar drawn as the nameplates draw theirs
--  (Saneroki, 2026-10-29: "like the nameplates": their font, colour, round,
--  border and shading; the colour by the thing): the game's shaded health
--  fill (its raid frames') in the thing's quality colour (a quest's things in
--  the game's gold), its corners round a quarter of its height (Core's caps),
--  behind it a border of one screen pixel, nearly black, round with it (Core's
--  corner masks), grey under the mouse as a nameplate's on your target. At the
--  bar's left end, inside its border and as tall as its fill, the thing's
--  picture with no border of its own, round at its corners as the bar is (the
--  same caps, the same radius: its left corners follow the bar's), how many on
--  it; then the game's green arrow where it would make the character better
--  (Upgrade.lua) in front of its name in white in the game's outlined font of
--  its nameplates; with the switch A line under each name (off at first) under
--  it, smaller, its kind and how it binds (Slots.Note) and at the right what a
--  vendor pays for all of it; at the right an A, a small dark bar of the same
--  make: the thing taken at once from now on (on the player's list: its letter
--  gold). A thing that is not the player's to take now is faint.
--
--      local row = Row.New(parent)          -- made once, used again
--      Row.Set(row, line, notes, onList)    -- shows a line of Slots (notes: the line under the name)
--      Row.Auto(row, onList)                -- the A as the player's word stands
--      Row.Color(quality), Row.Gold()       -- a quality's colour, the game's gold
--      Row.Font(fontString, size)           -- the game's outlined font of its nameplates, that size
--      Row.Bar(frame, height)               -- a bar of that make behind a frame (the line's, the A's)
--      Row.Time(row)                        -- the time left, a line over the bar's foot (a roll card's)
--      Row.TimeColor(share)                 -- its colour with that share left: green, through yellow, to red
--      Row.Upgrade(line)                    -- the tooltip's line about an upgrade
--      Row.Width(row)                       -- how wide its parts run
--  A line of a roll (Rolls.lua) has no A; row.room keeps that much of the
--  bar's right end free for its choices. The clicks and the tooltips are the
--  window's (Window.lua) and the roll cards'.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local S = ns.SIZE
local Row = {}
ns.Row = Row

-- As the nameplates' bars (Nameplates' Bar.lua): the game's raid frames' health fill, a round of a quarter of the
-- height, a border nearly black, grey on what the mouse is on (a nameplate's on your target).
local FILL = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CAP = 1 / 4
local BORDER = { 0, 0, 0, 0.9 }
local HOVER = { 0.5, 0.5, 0.5, 1 }
-- The game's font objects for its nameplates' names: their face and outline.
local FONTS = { "SystemFont_NamePlate_Outlined", "SystemFont_NamePlate" }
local DARK = { 0.16, 0.16, 0.18 } -- a bar of no thing (the A)
local SOFT = { 0.88, 0.88, 0.88 } -- the line under the name
local SHADE = 0.6 -- the dark under the time left

function Row.Color(quality)
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = colors and quality and colors[quality]
    if not color then return 1, 1, 1 end
    return color.r, color.g, color.b
end

-- The game's gold, as its quest things are marked.
function Row.Gold()
    local gold = rawget(_G, "NORMAL_FONT_COLOR")
    if type(gold) == "table" and gold.r then return gold.r, gold.g, gold.b end
    return 1, 0.82, 0
end

-- The face and outline of the game's font for its nameplates (asked once); Kalam outlined where it has none.
local face
local function Face()
    if face then return face end
    for _, name in ipairs(FONTS) do
        local object = rawget(_G, name)
        local file, _, flags
        if type(object) == "table" and object.GetFont then file, _, flags = object:GetFont() end
        if type(file) == "string" then
            face = { file = file, flags = (flags and flags ~= "") and flags or "OUTLINE" }
            return face
        end
    end
    face = { file = J.FONT_BOLD, flags = "OUTLINE" }
    return face
end

-- size: in 1080p pixels, as Sane UI's other words.
function Row.Font(fs, size)
    local look = Face()
    fs:SetFont(look.file, size * J.PX, look.flags)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.6)
end

-- A bar behind a frame of that height, as the nameplates make theirs:
--      bar:Paint(r, g, b)   the fill's colour
--      bar:SetLit(on)       the border grey, under the mouse
-- The border is a plate of two halves behind the fill, each round at its own two corners by Core's corner masks (a
-- texture takes three masks at most), so its round is the same at any width; the fill a screen pixel inside it, its
-- ends round by Core's two caps.
-- Two caps over a texture laid at a region's two ends (anchor), rounding them as a bar of that height is rounded;
-- made on the texture's own frame, as a mask must be.
local function Caps(texture, anchor, height)
    for _, side in ipairs({ "LEFT", "RIGHT" }) do
        local cap = texture:GetParent():CreateMaskTexture()
        cap:SetTexture(side == "LEFT" and Core.Shape.CAP_LEFT or Core.Shape.CAP_RIGHT, "CLAMPTOWHITE", "CLAMPTOWHITE")
        cap:SetPoint("TOP" .. side, anchor, "TOP" .. side)
        cap:SetPoint("BOTTOM" .. side, anchor, "BOTTOM" .. side)
        cap:SetWidth(math.max(height * CAP, 0.01))
        texture:AddMaskTexture(cap)
    end
end

function Row.Bar(frame, height)
    local bar = { lit = false }
    local pixel = Core.Pixels(frame, 1)
    local radius = height * CAP
    bar.halves = {}
    for index, corners in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" } }) do
        local half = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        half:SetTexture(WHITE)
        half:SetPoint(corners[1], frame, corners[1])
        half:SetPoint(corners[2], frame, corners[2])
        half:SetHeight(height / 2)
        for _, corner in ipairs(corners) do
            local mask = frame:CreateMaskTexture()
            mask:SetTexture(Core.Shape.CORNER[corner], "CLAMPTOWHITE", "CLAMPTOWHITE")
            mask:SetPoint(corner, half, corner)
            mask:SetSize(radius, radius)
            half:AddMaskTexture(mask)
        end
        bar.halves[index] = half
    end
    bar.fill = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    bar.fill:SetTexture(FILL)
    bar.fill:SetPoint("TOPLEFT", frame, "TOPLEFT", pixel, -pixel)
    bar.fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pixel, pixel)
    bar.inner = height - 2 * pixel
    bar.pixel = pixel
    Caps(bar.fill, bar.fill, bar.inner)
    function bar.Paint(_, r, g, b)
        bar.colour = { r, g, b }
        bar.fill:SetVertexColor(r, g, b, 1)
    end
    function bar.SetLit(_, on)
        bar.lit = on and true or false
        local colour = bar.lit and HOVER or BORDER
        for _, half in ipairs(bar.halves) do half:SetVertexColor(colour[1], colour[2], colour[3], colour[4]) end
    end
    bar:Paint(DARK[1], DARK[2], DARK[3])
    bar:SetLit(false)
    return bar
end

-- The colour of a share left, as the game blends a health bar's (HealthBar_OnValueChanged, smooth): green to half
-- way, yellow there, then red at nothing.
function Row.TimeColor(share)
    if share > 0.5 then return (1 - share) * 2, 1, 0 end
    return 1, share * 2, 0
end

-- The time left as a line over the bar's foot, as a nameplate's resource lies on its health (Nameplates' Bar.lua: the
-- same fill, the bar's own round at its right end), from the picture on, the picture kept clear. Under it a dark
-- shade: the bar is still seen where the time is spent, and the line stands out on a bar of its own colour (green on
-- an uncommon thing's). The words stand over it (row.lift).
--      line:Left(share)   how much is left, 0 to 1: so long, in its colour
function Row.Time(row)
    local bar = row.bar
    local line = CreateFrame("StatusBar", nil, row)
    line:SetHeight(S.time)
    line:SetPoint("BOTTOMLEFT", row.holder, "BOTTOMRIGHT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -bar.pixel, bar.pixel)
    line:SetStatusBarTexture(FILL)
    line:SetMinMaxValues(0, 1)
    local shade = line:CreateTexture(nil, "BACKGROUND")
    shade:SetTexture(WHITE)
    shade:SetVertexColor(0, 0, 0, SHADE)
    shade:SetAllPoints(line)
    Caps(line:GetStatusBarTexture(), bar.fill, bar.inner)
    Caps(shade, bar.fill, bar.inner)
    function line.Left(_, share)
        line:SetValue(share)
        line:SetStatusBarColor(Row.TimeColor(share))
    end
    line:Left(1)
    row.lift = S.time / 2
    return line
end

-- The tooltip's line about a thing that would make the character better.
function Row.Upgrade(line)
    if not line.upgrade then return end
    GameTooltip:AddLine(line.upgrade == "empty" and ns.TEXT.upgradeEmpty or ns.TEXT.upgradeBetter, 0.1, 1, 0.1, true)
end

function Row.New(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(S.row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.bar = Row.Bar(row, S.row)

    -- the picture at the bar's left end, inside its border, as tall as its fill; no border of its own, round at its
    -- corners by the fill's own caps, so its left corners follow the bar's round
    local inner, pixel = row.bar.inner, row.bar.pixel
    row.holder = CreateFrame("Frame", nil, row)
    row.holder:SetSize(inner, inner)
    row.holder:SetPoint("TOPLEFT", row, "TOPLEFT", pixel, -pixel)
    row.icon = row.holder:CreateTexture(nil, "ARTWORK")
    row.icon:SetAllPoints(row.holder)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    Caps(row.icon, row.holder, inner)
    -- the game's own sign of an upgrade (its bags have it): a green arrow in front of the name
    row.upgrade = row:CreateTexture(nil, "OVERLAY")
    row.upgrade:SetAtlas("bags-greenarrow")
    row.upgrade:SetSize(S.arrow, S.arrow)
    row.upgrade:Hide()
    row.count = row.holder:CreateFontString(nil, "OVERLAY")
    Row.Font(row.count, 11)
    row.count:SetTextColor(1, 1, 1)
    row.count:SetPoint("BOTTOMRIGHT", row.holder, "BOTTOMRIGHT", -2, 1)

    -- the A: taken at once from now on
    row.auto = CreateFrame("Button", nil, row)
    row.auto:SetSize(S.auto, S.auto)
    row.auto.bar = Row.Bar(row.auto, S.auto)
    row.auto.text = row.auto:CreateFontString(nil, "OVERLAY")
    Row.Font(row.auto.text, 11)
    row.auto.text:SetPoint("CENTER", 0, 0)
    row.auto.text:SetText(ns.TEXT.auto)

    row.name = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.name, 14)
    row.name:SetTextColor(1, 1, 1)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.note = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.note, 11)
    row.note:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    row.note:SetJustifyH("LEFT")
    row.note:SetWordWrap(false)
    row.worth = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.worth, 11)
    row.worth:SetTextColor(1, 1, 1)
    row.worth:SetJustifyH("RIGHT")
    return row
end

-- The name alone beside the picture (the A at its right), or the name over the line of its kind and worth (the kind
-- reaches to the line's right end where it sells for nothing: no empty words to lean on). The words keep clear of
-- the bar's round right end.
local function Lay(row, second, worth)
    local left, right = row.bar.pixel + row.bar.inner + S.gap, S.row * CAP + (row.room or 0)
    local named = left + (row.upgrade:IsShown() and S.arrow + S.gap / 2 or 0) -- the name after the green arrow
    for _, part in ipairs({ row.name, row.note, row.worth, row.auto, row.upgrade }) do part:ClearAllPoints() end
    row.upgrade:SetPoint("RIGHT", row.name, "LEFT", -S.gap / 2, 0)
    if second then
        row.auto:SetPoint("TOPRIGHT", row, "TOPRIGHT", -right, -S.pad)
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", named, -S.pad)
        row.worth:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -right, S.pad)
        row.note:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", left, S.pad)
        if worth then
            row.note:SetPoint("RIGHT", row.worth, "LEFT", -S.gap, 0)
        else
            row.note:SetPoint("RIGHT", row, "RIGHT", -right, 0)
        end
    else
        row.auto:SetPoint("RIGHT", row, "RIGHT", -right, 0)
        row.name:SetPoint("LEFT", row, "LEFT", named, row.lift or 0)
    end
    if row.auto:IsShown() then
        row.name:SetPoint("RIGHT", row.auto, "LEFT", -S.gap / 2, 0)
    else
        row.name:SetPoint("RIGHT", row, "RIGHT", -right, 0)
    end
end

-- What a vendor pays for all of it, in the game's coins; nothing for what sells for nothing.
local function Worth(line)
    local each = tonumber(line.worth) or 0
    if line.kind ~= "item" or each <= 0 then return "" end
    return Core.Coins(each * (tonumber(line.count) or 1)) or ""
end

-- The A as the player's word stands: its letter gold while the thing is on the list.
function Row.Auto(row, onList)
    row.auto.on = onList and true or false
    if onList then row.auto.text:SetTextColor(Row.Gold()) else row.auto.text:SetTextColor(SOFT[1], SOFT[2], SOFT[3]) end
end

function Row.Set(row, line, notes, onList)
    row.line = line
    row.icon:SetTexture(line.icon)
    row.icon:SetDesaturated(line.locked)
    row.upgrade:SetShown(line.upgrade ~= nil)
    row.count:SetText(line.count and line.count > 1 and line.count or "")
    row.name:SetText(line.name)
    local r, g, b
    if ns.Slots.Quest(line) then r, g, b = Row.Gold() else r, g, b = Row.Color(line.quality) end
    row.bar:Paint(r, g, b)
    local note = notes and (line.locked and ns.TEXT.locked or ns.Slots.Note(line)) or ""
    row.note:SetText(note)
    local worth = notes and Worth(line) or ""
    row.worth:SetText(worth)
    row.auto:SetShown(line.kind == "item" and line.id ~= nil and not line.roll)
    Row.Auto(row, onList)
    Lay(row, note ~= "" or worth ~= "", worth ~= "")
    row.bar:SetLit(false)
    row:SetAlpha(line.locked and 0.5 or 1)
    row:Show()
end

-- How wide the line's parts run: its picture, then the wider of its name (and A) and its second line, clear of the
-- bar's round right end.
function Row.Width(row)
    local function Wide(fs) return tonumber(fs:GetStringWidth()) or 0 end
    local top = Wide(row.name) + (row.auto:IsShown() and S.auto + S.gap / 2 or 0)
        + (row.upgrade:IsShown() and S.arrow + S.gap / 2 or 0)
    local second = Wide(row.note) + Wide(row.worth) + S.gap
    return row.bar.pixel + row.bar.inner + S.gap + math.max(top, second) + S.row * CAP
end
