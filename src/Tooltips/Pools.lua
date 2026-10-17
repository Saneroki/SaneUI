local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Pools
--  The parts a panel is drawn with (Panel.lua): texts, thin lines, small
--  pictures and bars. Each kind is a pool of the panel's own (Core.Pool): a
--  list of the parts made so far, and how many of them the draw has taken
--  (taken). A draw begins with every pool given back (Reset) and takes what it
--  needs again. And how large a text is (Width, Place).
--
--  A unit's numbers (Live.lua) get texts and bars of their own instead
--  (LiveText, LiveBar, BarText): the game may hand them numbers it hides, and
--  a text that once held one answers every question about its size with a
--  hidden number. Those are never measured, never used for anything else.
--
--  A size is only plain while what the text hangs on is: a panel hangs on the
--  game's tooltip. Panel.Draw lets go of that before it measures; should a
--  size still be hidden, it counts as 0 and the draw is spoilt (Spoilt): that
--  tooltip is then left to the game.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Secret = Core.Secret
local COLOR = ns.COLOR
local VALUE, HEALTH = COLOR.TITLE, COLOR.HEALTH
local Pools = {}
ns.Pools = Pools

Pools.BAR_HEIGHT = 6     -- a bar of our own: durability, a buff's time
Pools.ICON_CROP = 4 / 64 -- the dark rim round the game's icons: four of their 64 texels each side
local LIVE_ALPHA = 0.5   -- a unit's bars: a flat colour, half see-through
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BAR = "Interface\\TargetingFrame\\UI-StatusBar"
-- The game's art for the small pictures a row can carry
local PICTURE = {
    check = "Interface\\Buttons\\UI-CheckBox-Check",
    box = "Interface\\Buttons\\UI-CheckBox-Up",
    kill = "Interface\\CURSOR\\Attack",            -- the mouse over a creature to fight: a sword
    loot = "Interface\\CURSOR\\LootAll",           -- ... over one to loot: a sack
    available = "Interface\\GossipFrame\\AvailableQuestIcon", -- a quest to take: the yellow !
    active = "Interface\\GossipFrame\\ActiveQuestIcon",       -- a quest in the log: the ?
}
local POOLS = { "texts", "lines", "icons", "bars" }
local NewText, NewLine, NewIcon, NewBar -- below: how each kind of part is made

local spoilt = false -- a size of this draw was hidden
local style = 0      -- counts the changes of the fonts' files and sizes (Restyle)

-- A panel's pools and its live parts, when it is made.
function Pools.Prepare(panel)
    panel.texts = Core.Pool(function() return NewText(panel) end)
    panel.lines = Core.Pool(function() return NewLine(panel) end)
    panel.icons = Core.Pool(function() return NewIcon(panel) end)
    panel.bars = Core.Pool(function() return NewBar(panel) end)
    panel.liveTexts, panel.liveBars = {}, {} -- [use] = its own text or bar (LiveText, LiveBar)
end

-- Every part of the panel hidden, the pools given back: a draw begins. Only what the last draw
-- took is hidden: the rest is hidden already.
function Pools.Reset(panel)
    for _, name in ipairs(POOLS) do
        local pool = panel[name]
        for index = 1, pool.taken do pool[index]:Hide() end
        pool:Begin()
    end
    local live = panel.live
    for key in pairs(live) do live[key] = nil end
    for _, label in pairs(panel.liveTexts) do label:Hide() end
    for _, bar in pairs(panel.liveBars) do bar:Hide() end
    spoilt = false
end

-- Whether a size of this draw was hidden (see the top).
function Pools.Spoilt()
    return spoilt
end

-- The fonts' files or sizes have changed (Panel.lua, Sizes): every text is dressed anew when next used.
function Pools.Restyle()
    style = style + 1
end

-- A text's font: the game's font object (its shadow and spacing), then the file and size of the
-- kind of text (Panel.lua, FONTS). A font file that does not load leaves the game's own size.
local function Dress(label, kind)
    if kind.object then label:SetFontObject(kind.object) end
    if kind.path then label:SetFont(kind.path, kind.size, kind.flags or "") end
end

function NewText(panel)
    local label = panel:CreateFontString(nil, "OVERLAY")
    label:SetJustifyV("TOP")
    return label
end

function Pools.Text(panel, kind, text, r, g, b, align)
    local label = panel.texts:Take()
    if label.lifted then
        label:SetParent(panel)
        label.lifted = nil
    end
    -- A font is set only when it is another than the text had: the kind changed, or the fonts did
    if label.dressed ~= kind or label.style ~= style then
        label.dressed, label.style = kind, style
        Dress(label, kind)
    end
    label:SetTextColor(r or VALUE[1], g or VALUE[2], b or VALUE[3])
    label:SetJustifyH(align or "LEFT")
    label:SetWordWrap(true)
    label:SetWidth(0) -- unbounded, so its natural width can be asked
    label:SetText(text)
    label:Show()
    return label
end

-- A text of this draw onto a frame over the panel (one over a unit's live figure); back on the
-- panel when it is used again.
function Pools.Lift(label, frame)
    label:SetParent(frame)
    label.lifted = true
end

-- A text Live.lua writes, one for each use (key), never measured (see the top).
function Pools.LiveText(panel, key, kind, align, x, y, width)
    local label = panel.liveTexts[key]
    if not label then
        label = panel:CreateFontString(nil, "OVERLAY")
        label:SetJustifyV("TOP")
        label:SetWordWrap(false)
        panel.liveTexts[key] = label
    end
    Dress(label, kind)
    label:SetJustifyH(align)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
    label:SetWidth(width)
    label:Show()
    return label
end

-- A size the game hides counts as 0, and spoils the draw.
local function Size(value)
    if Secret(value) then
        spoilt = true
        return 0
    end
    return value or 0
end

-- How wide a text is, unbounded, to the whole unit past its end: given that width, it does not
-- break or cut its last letter.
function Pools.Width(label)
    local wide = Size((label.GetUnboundedStringWidth and label:GetUnboundedStringWidth()) or label:GetStringWidth())
    return wide > 0 and math.floor(wide) + 1 or 0
end

-- Puts a text at x, y (from the panel's top left) with a width; returns its height.
function Pools.Place(panel, label, x, y, width)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
    label:SetWidth(width)
    return Size(label:GetStringHeight())
end

function NewLine(panel)
    local line = panel:CreateTexture(nil, "ARTWORK", nil, 0)
    line:SetTexture(WHITE)
    return line
end

function Pools.Line(panel, r, g, b, a)
    local line = panel.lines:Take()
    line:ClearAllPoints()
    line:SetVertexColor(r, g, b, a)
    line:Show()
    return line
end

-- A divider from x over width at y: a dark band two hairlines high, and a faint light hairline
-- under it. The dark one shows where the panel is light, the light one where it is dark.
function Pools.Rule(panel, x, y, width, hairline)
    local dark = Pools.Line(panel, 0, 0, 0, 0.55)
    dark:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
    dark:SetSize(width, 2 * hairline)
    local light = Pools.Line(panel, 1, 1, 1, 0.10)
    light:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -(y + 2 * hairline))
    light:SetSize(width, hairline)
end

function NewIcon(panel)
    return panel:CreateTexture(nil, "ARTWORK", nil, 2)
end

-- A small picture: one of PICTURE, or an icon of the game's.
function Pools.Icon(panel, picture, size)
    local icon = panel.icons:Take()
    local known = PICTURE[picture]
    local crop = Pools.ICON_CROP
    icon:SetTexture(known or picture)
    if known then icon:SetTexCoord(0, 1, 0, 1) else icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop) end
    icon:SetSize(size, size)
    icon:ClearAllPoints()
    icon:Show()
    return icon
end

-- A text on a bar (on it, or the bar would cover it), at its left, middle or right, in the kind of
-- text given. Its own, so it may be given a number the game hides; never measured.
function Pools.BarText(bar, align, kind)
    bar.texts = bar.texts or {}
    local text = bar.texts[align]
    if not text then
        -- On a frame of its own over the bar, so a bar laid over this one (power over health)
        -- does not cover the words
        if not bar.words then
            bar.words = CreateFrame("Frame", nil, bar)
            bar.words:SetAllPoints()
        end
        text = bar.words:CreateFontString(nil, "OVERLAY")
        text:SetWordWrap(false)
        text:SetJustifyH(align)
        text:SetPoint("LEFT", bar, "LEFT", 5, 0)
        text:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
        bar.texts[align] = text
    end
    bar.words:SetFrameLevel(bar:GetFrameLevel() + 3)
    Dress(text, kind)
    text:SetTextColor(VALUE[1], VALUE[2], VALUE[3])
    text:Show()
    return text
end

-- A unit's health or power bar. Like a LiveText, it is given numbers the game may hide, so it is
-- one of its own and used for nothing else. Health has its numbers written inside.
function Pools.LiveBar(panel, key, height, r, g, b)
    local bar = panel.liveBars[key]
    if not bar then
        bar = CreateFrame("StatusBar", nil, panel)
        bar:SetStatusBarTexture(WHITE) -- a flat colour
        local track = bar:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints()
        -- The power bar lies over the health bar: nothing behind it, so an empty one shows nothing.
        track:SetColorTexture(0, 0, 0, key == "power" and 0 or 0.3)
        -- Both inside the block's round corners
        track:AddMaskTexture(panel.barMask)
        local fill = bar:GetStatusBarTexture()
        if fill and fill.AddMaskTexture then fill:AddMaskTexture(panel.barMask) end
        panel.liveBars[key] = bar
    end
    bar:SetStatusBarColor(r or HEALTH[1], g or HEALTH[2], b or HEALTH[3], LIVE_ALPHA)
    bar:SetHeight(height)
    bar:ClearAllPoints()
    bar:Show()
    return bar
end

function NewBar(panel)
    local bar = CreateFrame("StatusBar", nil, panel)
    bar:SetStatusBarTexture(BAR)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.5)
    return bar
end

function Pools.Bar(panel, r, g, b)
    local bar = panel.bars:Take()
    bar:SetStatusBarColor(r or HEALTH[1], g or HEALTH[2], b or HEALTH[3])
    bar:SetHeight(Pools.BAR_HEIGHT)
    bar:ClearAllPoints()
    bar:Show()
    return bar
end
