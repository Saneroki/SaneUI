local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Panel
--  The panel that is drawn in place of a tooltip, from a model (Model.lua):
--
--      /---------------------------------------\
--      | EQUIPPED (a comparison only)  [ICON] |   the first rows stand beside the icon,
--      | NAME                          [ 60 ] |   a word on its lower edge (a level)
--      | A line under it                       |
--      |---------------------------------------|   a divider: a thin dark line
--      |  MANA   |  RANGE  |  CAST   | COOLDOWN|   a strip: facts side by side, each caption
--      | 30 (6%) |  35 yd  | 1.5 sec |  8 sec  |   over its value, each cell as wide as its words
--      |---------------------------------------|
--      | QUEST ------------------------------- |   a section's name and a rule after it
--      | Rows: text left and right, a bar, a   |
--      | unit's buffs.                         |
--      \---------------------------------------/
--
--  One look for every kind of tooltip: the game's own tooltip ground, tinted
--  in the panel's colour, more at the top than at the bottom, with round
--  corners and an edge that fades out softly. No border, no band behind the
--  name, no boxes.
--
--  A panel is a frame of its own, one per tooltip, made when that tooltip is
--  first drawn. Its texts, lines, icons and bars come from pools (Pools.lua)
--  and are used again for every draw. Its width follows what it holds, in
--  steps (Fit).
--
--  Five pictures are ours (made by dev/tools/tooltip-art; the game has none like
--  them): Art\soft.tga, the background's shape with its soft edge, and four masks
--  that give a soft edge: Art\icon-mask.tga and Art\portrait-mask.tga to an icon
--  or a portrait, Art\bar-mask.tga to a unit's bars, Art\aura-mask.tga to its buff
--  icons (Live.lua). Icons and the dragons are the game's.
-------------------------------------------------------------------------------
local Plain, Ask = SaneUI.Core.Plain, SaneUI.Core.Ask
-- (Missing only after an update that brought Pools.lua and a mere /reload: Tooltips.lua then
-- leaves the tooltips to the game and asks for a restart. Until then nothing here is called.)
local Pools = ns.Pools or {}
local Text, LiveText, Width, Place = Pools.Text, Pools.LiveText, Pools.Width, Pools.Place
local Line, Rule, Icon, BarText, LiveBar, Bar = Pools.Line, Pools.Rule, Pools.Icon, Pools.BarText, Pools.LiveBar, Pools.Bar
local COLOR, Mix = ns.COLOR, ns.Mix
local Panel = {}
ns.Panel = Panel

-- Sizes, all in one place. Text sizes hang on the player's setting (Sizes); where a space is
-- counted in ems (the size of the row's text), it grows with the text.
local SIDE = 12                 -- between the panel's edges and its content
local NARROWEST, WIDEST = 224, 432
local WIDTH_STEP = 8            -- a panel's width moves in steps: a line a little longer or shorter (a
                                -- comparison refilled, a new rank) leaves its edge where it was
local WRAP_EMS = 22             -- a text that wraps is no wider than so many ems: a measure to read by
local RIGHT_LEAST = 4           -- ems a row's right side keeps when its left side would want all the room
local AFTER_GAP = 4             -- between a row's words and the smaller words after them
local ICON = 64                 -- the icon or portrait in the top right corner
local ICON_OUT = 10             -- how far it stands out past the panel's right side and its top
local ICON_GAP = 10             -- between it and the rows beside it
local ICON_CROP = Pools.ICON_CROP
local ROW_GAP = 3
local FLUSH = 1                 -- a row that stands close under the one before it: its gap is so much smaller
local BASE_LINE = 0.8           -- where a text's base line is, of its size from its top
local RULE_ABOVE, RULE_BELOW = 6, 8
local CAPTION_ABOVE, CAPTION_BELOW = 6, 5 -- round a section's name
local CAPTION_GAP = 6           -- between a section's name and its rule
local CAPTION_RULE = 24         -- the shortest rule after a section's name; less room, no rule
local CELL_INSET = 6            -- at each side of a strip's cell, at least
local BAR_HEIGHT = Pools.BAR_HEIGHT -- a bar of our own: durability, a buff's time
local HEALTH_HEIGHT, POWER_HEIGHT = 18, 5 -- a unit's bars: its health (written inside) and, over
                                          -- the health bar's lower part, its mana, rage or energy
local SHORT_BAR = 100           -- an item's durability
local SMALL_ICON = 16           -- beside a row's text
local LIVE_ROOM = 80            -- for a text Live.lua writes (a unit's target's name)
local NAME_GAP = 6              -- between the word Target and that name
local AURA_WORDS = 30           -- a buff's bar: its insets and the gap between its two texts
local AURA, AURA_GAP = 20, 2
local DEFAULT_SIZE, DEFAULT_OPACITY = 14, 97 -- as the settings have them at first (Tooltips.lua)
local COMPARED_ALPHA = 0.85     -- the panel of what you wear, beside the panel of what you look at
-- The dragons round a portrait: the game's own, from its target frame (Interface\HUD\UIUnitFrameBoss2x,
-- the art the game lays round the target's portrait for a boss, an elite and a rare). Each curls
-- round a circle: DRAGONS gives its place on the sheet of 512 by 512 (left, top, right, bottom) and
-- the middle of that circle in it (x, y), measured from the art; the circle's inner radius is
-- DRAGON_RING on the sheet. Each is laid round the portrait so that it covers its edge by
-- DRAGON_COVER: the scale follows from that.
local DRAGON_ART = "Interface\\HUD\\UIUnitFrameBoss2x"
local DRAGONS = {
    boss = { 2, 2, 197, 161, 69.3, 83.2 },    -- gold, winged: a raid or dungeon boss
    elite = { 2, 164, 160, 326, 69.3, 83.2 }, -- gold: an elite, a player
    silver = { 2, 326, 170, 484, 69.2, 81.3 }, -- silver, winged: a rare, a rare elite
}
local DRAGON_RING, DRAGON_COVER = 56.3, 2
-- The portrait's round picture is a little narrower than its square, so the dragon is moved in by
-- DRAGON_LEFT (from a look in the game: no gap between the picture and the dragon's body).
local DRAGON_LEFT = 4

-- The panel's own colours (Model.lua has the palette).
local LABEL, CAPTION, VALUE, TAG = COLOR.DETAIL, COLOR.CAPTION, COLOR.TITLE, COLOR.GOLD
-- The background: the game's own tooltip ground, taken toward the panel's colour TOP_TINT of the
-- way at the top; at the bottom the ground darkened by FOOT_DARK, then FOOT_TINT of the way.
local TOP_TINT, FOOT_TINT, FOOT_DARK = 0.28, 0.06, 0.55
local GROUND = COLOR.BACKDROP
local FOOT = { Mix(GROUND, COLOR.BLACK, FOOT_DARK) }
-- The plaque a level stands on: the game's gold, darkened, darker at the bottom; its edge fades out
-- softly like the panel's (Art/plaque.tga, stretched with its corners kept: margin; reaching out past
-- the plaque's box, so the box is solid). The box is hardly larger than its words (pad). Its right
-- side stays where a plaque with a level alone has it (least wide, round the icon's middle); longer
-- words (an item level) make it reach left, and the rows beside it make room for it.
local PLAQUE = {
    art = "Interface\\AddOns\\" .. ADDON .. "\\Art\\plaque", margin = 8, out = 3, least = 22, pad = 2, alpha = 0.95,
    top = { Mix(COLOR.GOLD, COLOR.BLACK, 0.35) }, foot = { Mix(COLOR.GOLD, COLOR.BLACK, 0.6) },
}

-- The background's shape: a white square with round corners and a soft edge, stretched to the
-- panel with its corners kept (SOFT_MARGIN), reaching SOFT_OUT past the panel's sides, so the
-- edge fades out around the panel and the panel's content stands on the solid part.
local SOFT = "Interface\\AddOns\\" .. ADDON .. "\\Art\\soft"
local SOFT_MARGIN, SOFT_OUT = 24, 8
-- Masks for round corners. A mask is stretched whole (its corners are not kept as a texture's
-- are), so each is made in the shape it is used in: a square icon's, and the long flat block of a
-- unit's bars.
local ICON_MASK = "Interface\\AddOns\\" .. ADDON .. "\\Art\\icon-mask"         -- soft, round corners
local PORTRAIT_MASK = "Interface\\AddOns\\" .. ADDON .. "\\Art\\portrait-mask" -- soft, round
local BAR_MASK = "Interface\\AddOns\\" .. ADDON .. "\\Art\\bar-mask"

local panels = {}  -- [tooltip] = its panel
local cells = {}   -- [a strip's row] = its first text, for one draw
local wides = {}   -- a strip's cells' widths, for one draw
local tint = {}    -- the panel's colour, for one draw
local low, high    -- two colours for gradients, used again for every draw

-- The kinds of text: which of the game's fonts, and how large beside the player's text size.
-- The font file is asked of the game's font object at every draw, so the game's language and a
-- UI addon's choice of font are followed; only the size is ours.
local FONTS = {
    title = { font = "GameTooltipHeaderText", add = 0 },
    row = { font = "GameTooltipText", add = 0 },   -- as large as the title
    big = { font = "GameTooltipHeaderText", add = 4 },
    sub = { font = "GameTooltipText", add = -2 },
    value = { font = "GameTooltipText", add = -2 },
    tag = { font = "GameTooltipHeaderText", add = -2 },
    badge = { font = "GameTooltipHeaderText", add = -1, outline = true }, -- on its gold plaque, outlined
    -- At the default size the small ones are 10, as the game's own small font (GameFontNormalSmall)
    small = { font = "GameTooltipText", add = -4, least = 8 },   -- another addon's lines, the details with Alt
    caption = { font = "GameTooltipText", add = -4, least = 8 }, -- a section's name, a strip's captions
    detail = { font = "GameTooltipText", add = -4, least = 8 },  -- a unit's kind, PvP
    inside = { font = "GameTooltipText", add = -4, least = 8 },  -- the numbers inside a health bar
}

-- Works out every kind's file and size for one draw. Should any of them change (the text size, the
-- game's font), the pools' texts are dressed anew (Pools.Restyle).
local function Sizes()
    local size = ns.options and tonumber(ns.options.textSize) or DEFAULT_SIZE
    local changed = false
    for _, kind in pairs(FONTS) do
        local object = rawget(_G, kind.font)
        local path, flags
        if object and object.GetFont then
            local file, _, own = object:GetFont()
            path, flags = file, kind.outline and "OUTLINE" or own
        end
        local wanted = math.max(kind.least or 6, size + kind.add)
        if kind.object ~= object or kind.path ~= path or kind.flags ~= flags or kind.size ~= wanted then
            kind.object, kind.path, kind.flags, kind.size = object, path, flags, wanted
            changed = true
        end
    end
    if changed then Pools.Restyle() end
end

-- How thick a hairline is in the panel's own units: one unit of the UI, rounded to whole dots of
-- the screen by the game's PixelUtil, and never less than one dot. It stays sharp at every scale.
local function Hairline(panel)
    local scale = Plain(panel:GetEffectiveScale())
    if PixelUtil and PixelUtil.GetNearestPixelSize and scale and scale > 0 then
        return PixelUtil.GetNearestPixelSize(1, scale, 1)
    end
    return 1
end

local function Gradient(texture, r1, g1, b1, a1, r2, g2, b2, a2)
    if not low then low, high = CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 1) end
    low:SetRGBA(r1, g1, b1, a1)
    high:SetRGBA(r2, g2, b2, a2)
    texture:SetGradient("VERTICAL", low, high)
end

-- The panel's width for what it holds: at least NARROWEST, at most WIDEST, in WIDTH_STEP steps.
local function Fit(wanted)
    local steps = math.ceil(math.max(0, wanted + 2 * SIDE - NARROWEST) / WIDTH_STEP)
    return math.min(WIDEST, NARROWEST + steps * WIDTH_STEP)
end

local function Create(tooltip)
    local panel = CreateFrame("Frame", nil, UIParent)
    panel:SetFrameStrata("TOOLTIP")
    panel:SetClampedToScreen(true)
    panel:Hide()
    panel.tooltip = tooltip
    panel.model = ns.Model.New()
    Pools.Prepare(panel)
    panel.left, panel.right, panel.after = {}, {}, {} -- [row] = its texts, for one draw
    panel.live = {}                                    -- the parts Live.lua keeps up to date

    panel.back = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
    panel.back:SetTexture(SOFT)
    panel.back:SetTextureSliceMargins(SOFT_MARGIN, SOFT_MARGIN, SOFT_MARGIN, SOFT_MARGIN)
    panel.back:SetPoint("TOPLEFT", panel, "TOPLEFT", -SOFT_OUT, SOFT_OUT)
    panel.back:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", SOFT_OUT, -SOFT_OUT)
    -- The icon or portrait, its edge fading out softly like the panel's (a mask of its shape)
    panel.icon = panel:CreateTexture(nil, "ARTWORK", nil, 1)
    panel.icon:SetPoint("TOPRIGHT", panel, "TOPRIGHT", ICON_OUT, ICON_OUT)
    panel.icon:SetSize(ICON, ICON)
    panel.iconMask = panel:CreateMaskTexture()
    panel.iconMask:SetAllPoints(panel.icon)
    panel.icon:AddMaskTexture(panel.iconMask)
    -- Over a unit's live figure (Figure, a frame of its own: it would cover the panel's own
    -- pictures): the dragon, the plaque and the level on it.
    panel.front = CreateFrame("Frame", nil, panel)
    panel.front:SetAllPoints(panel)
    -- The level's plaque, over the dragon, under the number
    panel.plaque = panel.front:CreateTexture(nil, "OVERLAY", nil, 4)
    panel.plaque:SetTexture(PLAQUE.art)
    panel.plaque:SetTextureSliceMargins(PLAQUE.margin, PLAQUE.margin, PLAQUE.margin, PLAQUE.margin)
    -- A dragon round the portrait: over it (it goes round it), under the texts.
    panel.dragon = panel.front:CreateTexture(nil, "OVERLAY", nil, -1)
    panel.dragon:SetTexture(DRAGON_ART)
    panel.dragon:Hide()
    -- A unit's health and power bars together are one block with round corners.
    panel.barMask = panel:CreateMaskTexture()
    panel.barMask:SetTexture(BAR_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

    panels[tooltip] = panel
    return panel
end

-- A unit's live figure in the portrait's place (the option models): the game's 3D model of the
-- unit, moving, on a see-through ground, its face in view (SetPortraitZoom). A frame of its own
-- (PlayerModel), made for the first unit a panel shows. It is given the unit only when the unit
-- changes (its GUID), as giving it again would load it anew and start its moves over, and a panel is
-- drawn many times while it is shown; once hidden it forgets the unit. False where the game cannot
-- draw the model (the unit out of sight, its identity hidden, a client without the frame): the flat
-- picture (SetPortraitTexture) stands there then.
local function Forget(figure) figure.guid = nil end
local function Figure(panel, head)
    local figure = panel.figure
    if not (head.portrait and head.guid and ns.options and ns.options.models ~= false) then
        if figure then figure:Hide() end
        return false
    end
    if figure == nil then
        local made
        made, figure = pcall(CreateFrame, "PlayerModel", nil, panel)
        figure = made and figure or false -- false: this client has none, not asked again
        if figure then
            figure:SetAllPoints(panel.icon)
            figure:SetScript("OnHide", Forget)
        end
        panel.figure = figure
    end
    if not figure then return false end
    if figure.guid ~= head.guid then
        figure:ClearModel()
        figure.guid = Ask(figure.SetUnit, figure, head.portrait) == true and head.guid or nil
        if figure.guid then figure:SetPortraitZoom(1) end
    end
    figure:SetShown(figure.guid ~= nil)
    return figure.guid ~= nil
end

-- The tooltip's panel, made when it is first asked for.
function Panel.Of(tooltip)
    return panels[tooltip] or Create(tooltip)
end

function Panel.All()
    return panels
end

-- The panel seen at its strength, or see-through while it may not be seen yet (the option show).
-- Its live figure too, by itself: a model frame need not follow the alpha of the frame it is in.
function Panel.Strength(panel, allowed)
    panel:SetAlpha(allowed and panel.strength or 0)
    if panel.figure then panel.figure:SetAlpha(allowed and 1 or 0) end
end

-------------------------------------------------------------------------------
--  Drawing, in four steps: every text made and measured (Measure), the panel
--  given its width, the icon or portrait with its plaque (Picture), the rows
--  laid out top to bottom (Lay), and last the background, the dragon and the
--  panel's place among the frames (Finish).
-------------------------------------------------------------------------------
local function Upper(text)
    -- Colour and icon codes inside a name are spelled in small letters: such a name stays as it is.
    if text:find("|", 1, true) then return text end
    return text:upper()
end

-- A description with its numbers in the panel's colour at full strength: that colour scaled until
-- its strongest part is whole. Only the digits are coloured; a point or a comma between them keeps
-- the description's colour. A description with codes of its own stays as it is.
local function Tinted(text, r, g, b)
    if text:find("|", 1, true) then return text end
    local top = math.max(r, g, b)
    if top <= 0 then return text end
    return (text:gsub("%d+", "|cff" .. ns.Hex(r / top, g / top, b / top) .. "%0|r"))
end

local function Words(row, head, r, g, b)
    local text = row.left
    if row.caps then text = Upper(text) end
    if row.prose and head.numbers then text = Tinted(text, r, g, b) end
    return text
end

-- A row's words in room, and the words after them (a guild's rank, an objective's drop chance),
-- smaller ones on the same base line. Returns the height of the row's words.
local function WordsAndAfter(panel, row, left, after, x, y, room)
    if not after then return Place(panel, left, x, y, room) end
    local leftWidth = math.min(Width(left), room)
    local height = Place(panel, left, x, y, leftWidth)
    local font, small = FONTS[row.font] or FONTS.row, FONTS[row.labelFont] or FONTS[row.font] or FONTS.row
    Place(panel, after, x + leftWidth + AFTER_GAP, y + (font.size - small.size) * BASE_LINE, room - leftWidth - AFTER_GAP)
    return height
end

-- Makes every text of the model and works out how wide the panel must be for them. The rows
-- before the first divider stand beside the icon (iconRoom). Returns that width, and the tag's text.
local function Measure(panel, head, rows, count, r, g, b, iconRoom)
    local wanted, beside, tag = 0, true, nil
    if head.tag and head.tag ~= "" then
        tag = Text(panel, FONTS.tag, Upper(head.tag), TAG[1], TAG[2], TAG[3])
        wanted = Width(tag) + iconRoom
    end
    for index = 1, count do
        local row = rows[index]
        local kind = row.kind
        if row.rule or kind ~= "text" then beside = false end
        panel.left[index], panel.right[index], panel.after[index] = nil, nil, nil
        if kind == "text" and row.live then
            -- A row Live.lua fills: only words of our own are measured (see Pools.lua).
            local left = Text(panel, FONTS[row.font] or FONTS.row, row.left, row.lr, row.lg, row.lb)
            panel.left[index] = left
            wanted = math.max(wanted, Width(left) + NAME_GAP + LIVE_ROOM)
        elseif kind == "bar" and row.live == "aura" then
            -- A buff's bar: wide enough for the time and the caster written inside it
            local font = FONTS.inside
            local time, caster = Text(panel, font, row.left), Text(panel, font, row.right)
            wanted = math.max(wanted, Width(time) + Width(caster) + AURA_WORDS)
            time:Hide()
            caster:Hide()
        elseif kind == "text" or (kind == "bar" and row.short) then
            local font = FONTS[row.font] or FONTS.row
            -- A description stands in the middle, each of its lines
            local left = Text(panel, font, Words(row, head, r, g, b), row.lr, row.lg, row.lb, row.prose and "CENTER" or nil)
            local right = Text(panel, font, row.right, row.rr, row.rg, row.rb, "RIGHT")
            panel.left[index], panel.right[index] = left, right
            local wide = Width(left) + (row.indent or 0) + (row.icon and SMALL_ICON + 4 or 0)
                + (row.iconRight and SMALL_ICON + 4 or 0) + (kind == "bar" and SHORT_BAR + 8 or 0)
            if row.label then
                local after = Text(panel, FONTS[row.labelFont] or font, row.label, LABEL[1], LABEL[2], LABEL[3])
                panel.after[index] = after
                wide = wide + AFTER_GAP + Width(after)
            end
            if row.right ~= "" then
                wide = wide + font.size + Width(right) -- an em between the two sides
            else
                wide = math.min(wide, WRAP_EMS * font.size) -- it wraps beyond that
            end
            wanted = math.max(wanted, wide + (beside and iconRoom or 0))
        elseif kind == "strip" then
            cells[index] = panel.texts.taken + 1
            local wide = 0
            for cell = 1, #row, 2 do
                local caption = Text(panel, FONTS.caption, Upper(row[cell]), CAPTION[1], CAPTION[2], CAPTION[3], "CENTER")
                local value = Text(panel, FONTS.value, row[cell + 1], VALUE[1], VALUE[2], VALUE[3], "CENTER")
                wide = wide + math.max(Width(caption), Width(value)) + 2 * CELL_INSET
            end
            wanted = math.max(wanted, wide)
        elseif kind == "caption" then
            local caption = Text(panel, FONTS.caption, Upper(row.left), CAPTION[1], CAPTION[2], CAPTION[3])
            panel.left[index] = caption
            wanted = math.max(wanted, Width(caption) + CAPTION_GAP + CAPTION_RULE)
        end
    end
    return wanted, tag
end

-- The icon, or a unit's portrait (its live figure, or else its flat picture), and the plaque with
-- its words on the lower edge. Returns how far down the picture reaches, and where a plaque wider
-- than the picture begins (its left and top), for the rows beside it.
local function Picture(panel, head, badge, width, pictured)
    local figured = Figure(panel, head)
    panel.icon:SetShown(pictured and not figured)
    panel.plaque:SetShown(badge ~= nil)
    if not pictured then return 0 end
    local square = not head.portrait
    if square then
        panel.icon:SetTexCoord(ICON_CROP, 1 - ICON_CROP, ICON_CROP, 1 - ICON_CROP)
        panel.icon:SetTexture(head.icon)
    elseif not figured then
        panel.icon:SetTexCoord(0, 1, 0, 1)
        SetPortraitTexture(panel.icon, head.portrait)
    end
    -- A soft edge: round corners for a square icon, a circle for a portrait
    local mask = square and ICON_MASK or PORTRAIT_MASK
    if panel.iconMaskArt ~= mask then
        panel.iconMask:SetTexture(mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        panel.iconMaskArt = mask
    end
    local bottom = ICON - ICON_OUT
    if not badge then return bottom end
    -- The plaque on the icon's lower edge, half on it and half under it, its words on it
    local height = FONTS.badge.size + PLAQUE.pad
    local wide = math.max(PLAQUE.least, Width(badge) + 2 * PLAQUE.pad)
    local right = width + ICON_OUT - ICON / 2 + PLAQUE.least / 2
    local left, top = right - wide, bottom - height / 2
    local plaque = panel.plaque
    plaque:ClearAllPoints()
    plaque:SetPoint("TOPLEFT", panel, "TOPLEFT", left - PLAQUE.out, -(top - PLAQUE.out))
    plaque:SetPoint("BOTTOMRIGHT", panel, "TOPLEFT", right + PLAQUE.out, -(top + height + PLAQUE.out))
    Gradient(plaque, PLAQUE.foot[1], PLAQUE.foot[2], PLAQUE.foot[3], PLAQUE.alpha,
        PLAQUE.top[1], PLAQUE.top[2], PLAQUE.top[3], PLAQUE.alpha)
    Pools.Lift(badge, panel.front) -- over a live figure, with its plaque
    badge:SetDrawLayer("OVERLAY", 7)
    badge:SetShadowColor(0, 0, 0, 1)
    Place(panel, badge, left, top + (height - FONTS.badge.size) / 2, wide)
    return bottom + height / 2, left - PLAQUE.out, top - PLAQUE.out
end

-- A row of words, with what may stand at its sides (small icons), at y. Returns its height.
local function TextRow(panel, row, index, y, room, reserve, width)
    local left, right, after = panel.left[index], panel.right[index], panel.after[index]
    local font = FONTS[row.font] or FONTS.row
    local x = SIDE + (row.indent or 0)
    if row.icon then
        Icon(panel, row.icon, SMALL_ICON):SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
        x, room = x + SMALL_ICON + 4, room - SMALL_ICON - 4
    end
    room = room - (row.indent or 0)
    local edge = SIDE + reserve -- from the panel's right side
    if row.iconRight then
        Icon(panel, row.iconRight, SMALL_ICON):SetPoint("TOPRIGHT", panel, "TOPRIGHT", -edge, -y)
        edge, room = edge + SMALL_ICON + 4, room - SMALL_ICON - 4
    end
    local height
    if row.right ~= "" then
        -- The left side keeps the room it needs; the right side takes what is left, on one line,
        -- cut short where the panel is too narrow for both (it keeps RIGHT_LEAST ems).
        local gutter = font.size
        local want = Width(left) + (after and AFTER_GAP + Width(after) or 0)
        local leftRoom = math.max(1, math.min(want, room - gutter - math.min(Width(right), RIGHT_LEAST * font.size)))
        local rightRoom = room - gutter - leftRoom
        right:SetWordWrap(false)
        height = WordsAndAfter(panel, row, left, after, x, y, leftRoom)
        height = math.max(height, Place(panel, right, width - edge - rightRoom, y, rightRoom))
    else
        right:Hide()
        height = WordsAndAfter(panel, row, left, after, x, y, room)
    end
    return math.max(height, row.icon and SMALL_ICON or 0)
end

-- A strip at y: each fact's caption over its value. A cell is as wide as its words; the room the
-- cells leave is shared out among them. Returns its height.
local function StripRow(panel, row, index, y, inner, hairline)
    local first, number = cells[index], #row / 2
    local used = 0
    for cell = 1, number do
        local caption, value = panel.texts[first + 2 * cell - 2], panel.texts[first + 2 * cell - 1]
        wides[cell] = math.max(Width(caption), Width(value)) + 2 * CELL_INSET
        used = used + wides[cell]
    end
    local spare = math.max(0, inner - used) / number
    local valueTop = y + FONTS.caption.size + 2
    local height = FONTS.caption.size + 2 + FONTS.value.size + 2
    local x = SIDE
    for cell = 1, number do
        local wide = wides[cell] + spare
        Place(panel, panel.texts[first + 2 * cell - 2], x, y, wide)
        Place(panel, panel.texts[first + 2 * cell - 1], x, valueTop, wide)
        if cell > 1 then
            local separator = Line(panel, 0, 0, 0, 0.4)
            separator:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -(y + 1))
            separator:SetSize(hairline, height - 2)
        end
        x = x + wide
    end
    return height
end

-- A unit's health or a buff's time, as Live.lua keeps them (power lies over health: no place of
-- its own), or a bar of ours (durability). Returns the y under it.
local function BarRow(panel, row, index, y, inner, block)
    local live = panel.live
    if row.live == "power" then
        -- A unit's mana, rage or energy: over the lower part of its health bar
        if not live.health then return y end
        local bar = LiveBar(panel, "power", POWER_HEIGHT, row.br, row.bg, row.bb)
        bar:SetPoint("BOTTOMLEFT", live.health, "BOTTOMLEFT")
        bar:SetPoint("BOTTOMRIGHT", live.health, "BOTTOMRIGHT")
        bar:SetFrameLevel(live.health:GetFrameLevel() + 1)
        live.power = bar
        return y
    end
    if row.flush then y = y - ROW_GAP end
    if row.live then
        -- A unit's health (its numbers inside); a buff's time (how long it still runs inside, who
        -- cast it at the right). Flat, with round corners: block is the stretch of them all.
        local bar = LiveBar(panel, row.live, HEALTH_HEIGHT, row.br, row.bg, row.bb)
        bar:SetPoint("TOPLEFT", panel, "TOPLEFT", SIDE, -y)
        bar:SetWidth(inner)
        live[row.live] = bar
        block.top, block.bottom = block.top or y, y + HEALTH_HEIGHT
        if bar.texts then for _, text in pairs(bar.texts) do text:Hide() end end
        if row.live == "health" then
            -- In the middle of the bar, over the power bar's strip
            live.healthText = BarText(bar, "CENTER", FONTS.inside)
        elseif row.live == "aura" then
            BarText(bar, row.right ~= "" and "LEFT" or "CENTER", FONTS.inside):SetText(row.left)
            if row.right ~= "" then BarText(bar, "RIGHT", FONTS.inside):SetText(row.right) end
        end
        return y + HEALTH_HEIGHT + ROW_GAP
    end
    local bar = Bar(panel, row.br, row.bg, row.bb)
    bar:SetMinMaxValues(0, row.max or 1)
    bar:SetValue(row.value or 0)
    if row.short then
        -- A small bar with its numbers beside it, and something at the right (a price)
        local left, right = panel.left[index], panel.right[index]
        local height = math.max(Place(panel, left, SIDE + SHORT_BAR + 8, y, inner - SHORT_BAR - 8),
            Place(panel, right, SIDE, y, inner))
        bar:SetPoint("LEFT", panel, "TOPLEFT", SIDE, -(y + height / 2))
        bar:SetWidth(SHORT_BAR)
        return y + height + ROW_GAP
    end
    bar:SetPoint("TOPLEFT", panel, "TOPLEFT", SIDE, -y)
    bar:SetWidth(inner)
    return y + BAR_HEIGHT + ROW_GAP
end

local block = {} -- the stretch of a unit's bars, for their round corners, for one draw

-- Lays out the rows from y down. Returns the y under the last.
local function Lay(panel, rows, count, y, width, iconRoom, iconBottom, plaqueLeft, plaqueTop, hairline)
    local inner = width - 2 * SIDE
    local live = panel.live
    block.top, block.bottom = nil, nil
    for index = 1, count do
        local row = rows[index]
        local kind = row.kind
        local font = FONTS[row.font] or FONTS.row
        if (row.rule or kind ~= "text") and y < iconBottom then y = iconBottom + ROW_GAP end
        if row.rule then
            Rule(panel, SIDE, y + RULE_ABOVE, inner, hairline)
            y = y + RULE_ABOVE + RULE_BELOW
        end
        -- What the icon (and a plaque wider than it) takes of the row's width, from the right side
        local reserve = y < iconBottom and iconRoom or 0
        if plaqueLeft and y < iconBottom and y + font.size > plaqueTop then
            reserve = math.max(reserve, width - SIDE - plaqueLeft + ICON_GAP / 2)
        end
        local room = inner - reserve

        if kind == "text" and row.live then
            -- Whom a unit targets: our word, and right after it the name Live.lua writes
            local word = panel.left[index]
            local wide = math.min(Width(word), room)
            Place(panel, word, SIDE, y, wide)
            live.targetName = LiveText(panel, "targetName", font, "LEFT", SIDE + wide + NAME_GAP, y, room - wide - NAME_GAP)
            y = y + font.size + 2 + ROW_GAP
        elseif kind == "text" then
            if row.flush then y = y - FLUSH end -- close under the row before it (a guild under a name)
            y = y + TextRow(panel, row, index, y, room, reserve, width) + ROW_GAP
        elseif kind == "strip" then
            y = y + StripRow(panel, row, index, y, inner, hairline) + ROW_GAP
        elseif kind == "bar" then
            y = BarRow(panel, row, index, y, inner, block)
        elseif kind == "caption" then
            -- A section's name at the left, and a rule from it on to the right side
            local caption = panel.left[index]
            local wide = math.min(Width(caption), inner)
            y = y + CAPTION_ABOVE
            local height = Place(panel, caption, SIDE, y, wide)
            local start = wide + CAPTION_GAP
            if inner - start >= CAPTION_RULE then Rule(panel, SIDE + start, y + math.floor(height / 2), inner - start, hairline) end
            y = y + height + CAPTION_BELOW
        elseif kind == "auras" then
            live.aurasTop, live.aurasWidth = y, inner
            y = y + AURA + ROW_GAP
        end
    end
    if block.top then
        panel.barMask:ClearAllPoints()
        panel.barMask:SetPoint("TOPLEFT", panel, "TOPLEFT", SIDE, -block.top)
        panel.barMask:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -SIDE, -block.bottom)
    end
    return y
end

-- The background in the panel's colour (more of it at the top), the dragon round a portrait, how
-- strongly the panel is seen, and its place among the frames.
local function Finish(panel, head, pictured, r, g, b)
    local opacity = (ns.options and tonumber(ns.options.opacity) or DEFAULT_OPACITY) / 100
    tint[1], tint[2], tint[3] = r, g, b
    local topR, topG, topB = Mix(GROUND, tint, TOP_TINT)
    local footR, footG, footB = Mix(FOOT, tint, FOOT_TINT)
    Gradient(panel.back, footR, footG, footB, opacity, topR, topG, topB, opacity)
    -- A dragon round the portrait: the game's for a boss, an elite or a player, a rare
    local dragon = pictured and head.dragon and DRAGONS[head.dragon]
    panel.dragon:SetShown(dragon and true or false)
    if dragon then
        local scale = (ICON / 2 - DRAGON_COVER) / DRAGON_RING
        panel.dragon:SetTexCoord(dragon[1] / 512, dragon[3] / 512, dragon[2] / 512, dragon[4] / 512)
        panel.dragon:SetSize((dragon[3] - dragon[1]) * scale, (dragon[4] - dragon[2]) * scale)
        panel.dragon:ClearAllPoints()
        panel.dragon:SetPoint("TOPLEFT", panel.icon, "CENTER", -dragon[5] * scale - DRAGON_LEFT, dragon[6] * scale)
    end
    -- What you wear stands back a little; any tooltip is see-through while it may not be seen yet
    -- (the option show: Tooltips.lua)
    panel.strength = head.compared and COMPARED_ALPHA or 1
    Panel.Strength(panel, ns.Allowed())
    -- (A chat link's tooltip has no X here: a click on it closes it. Tooltips.lua, Host.lua)
    -- Over its tooltip. (A frame's level may be hidden: then the panel keeps its own.)
    local level = Plain(panel.tooltip:GetFrameLevel())
    if level then panel:SetFrameLevel(level + 5) end
    -- The live figure over the panel's own pictures, the dragon and the plaque over the figure
    local own = Plain(panel:GetFrameLevel()) or 0
    if panel.figure then panel.figure:SetFrameLevel(own + 1) end
    panel.front:SetFrameLevel(own + 2)
end

-- Draws what the panel's model shows. The panel is shown afterwards; where it stands is Host.lua's.
-- False when a size was hidden (Pools.lua): the panel is not shown then.
function Panel.Draw(panel)
    local shown = panel.model.shown
    local head, rows, count = shown.head, shown.rows, shown.n
    -- The panel lets go of the tooltip (or panel) it hung on: a text's size is hidden while what it
    -- hangs on is placed by something hidden. Host.lua places it again after the draw.
    panel:ClearAllPoints()
    panel.corner = nil
    Pools.Reset(panel)
    Sizes()
    local neutral = COLOR.NEUTRAL
    local r, g, b = neutral[1], neutral[2], neutral[3]
    if head.accent then r, g, b = head.ar, head.ag, head.ab end

    local pictured = (head.icon or head.portrait) and true or false
    local iconRoom = pictured and (ICON - ICON_OUT - SIDE + ICON_GAP) or 0
    local wanted, tag = Measure(panel, head, rows, count, r, g, b, iconRoom)
    local badge
    if head.badge and pictured then
        -- A unit's level in the colour of how hard it is; an item level light. Outlined, on the plaque.
        local words = head.badgeR and head or nil
        local light = COLOR.PLAQUE
        badge = Text(panel, FONTS.badge, head.badge, words and words.badgeR or light[1],
            words and words.badgeG or light[2], words and words.badgeB or light[3], "CENTER")
    end
    local width = Fit(wanted)
    panel:SetWidth(width)

    local y = SIDE
    if tag then y = y + Place(panel, tag, SIDE, y, width - 2 * SIDE - iconRoom) + 3 end
    local iconBottom, plaqueLeft, plaqueTop = Picture(panel, head, badge, width, pictured)
    y = Lay(panel, rows, count, y, width, iconRoom, iconBottom, plaqueLeft, plaqueTop, Hairline(panel))
    y = math.max(y, iconBottom + ROW_GAP)
    panel:SetHeight(y + SIDE - ROW_GAP)
    Finish(panel, head, pictured, r, g, b)
    if Pools.Spoilt() then
        panel:Hide()
        return false
    end
    panel:Show()
    ns.Live.Start(panel)
    return true
end

-- For Live.lua, which lays out a unit's buff icons itself: their size, the gap between them, and
-- where the panel's content begins. For Host.lua: how far a panel's soft edge reaches out.
Panel.AURA, Panel.AURA_GAP, Panel.SIDE, Panel.EDGE = AURA, AURA_GAP, SIDE, SOFT_OUT
