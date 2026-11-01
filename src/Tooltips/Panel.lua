local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Panel
--  The panel that is drawn in place of a tooltip, from a model (Model.lua):
--
--      /---------------------------------------\
--      | EQUIPPED (a comparison only)  [ICON] |   the first rows stand beside the icon,
--      | NAME                          [ 60 ] |   a word on its lower edge (a level)
--      | A line under it                       |
--      | STATS ------------------------------- |   a section's name and a rule after it: the
--      |  MANA   |  RANGE  |  CAST   | COOLDOWN|   only dividers. A strip: facts side by side,
--      | 30 (6%) |  35 yd  | 1.5 sec |  8 sec  |   each caption over its value, each cell as
--      | QUEST ------------------------------- |   wide as its words
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
--  A panel taller than the screen goes on in a second column (and a third...)
--  beside the first, as wide as it, a groove between them: its rows are laid
--  once in one column to know their heights, then again with each column
--  starting at the top where the one before would run off the screen (Columns).
--
--  Five pictures are ours (made by dev/tools/tooltip-art; the game has none like
--  them): Art\soft.tga, the background's shape with its soft edge, and four masks
--  that give a soft edge: Art\icon-mask.tga and Art\portrait-mask.tga to an icon
--  or a portrait, Art\bar-mask.tga to a unit's bars, Art\aura-mask.tga to its buff
--  icons (Live.lua). Icons and the dragons are the game's.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
-- (Missing only after an update that brought Pools.lua and a mere /reload: Tooltips.lua then
-- leaves the tooltips to the game and asks for a restart. Until then nothing here is called.)
local Pools = ns.Pools or {}
local Text, LiveText, Width, Place = Pools.Text, Pools.LiveText, Pools.Width, Pools.Place
local Line, Rule, Icon, BarText, LiveBar = Pools.Line, Pools.Rule, Pools.Icon, Pools.BarText, Pools.LiveBar
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
local SPACE = 6                 -- above a row with room above it (the game's empty line inside a section)
local CAPTION_ABOVE, CAPTION_BELOW = 6, 5 -- round a section's name
local CAPTION_GAP = 6           -- between a section's name and the rule at each side of it
local CAPTION_RULE = 12         -- the shortest rule beside a section's name; less room, no rules
local CELL_INSET = 6            -- at each side of a strip's cell, at least
local HEALTH_HEIGHT, POWER_HEIGHT = 18, 5 -- a unit's bars: its health (written inside) and, over
                                          -- the health bar's lower part, its mana, rage or energy
local SMALL_ICON = 16           -- beside a row's text
local LIVE_ROOM = 80            -- for a text Live.lua writes (a unit's target's name)
local NAME_GAP = 6              -- between the word Target and that name
local AURA_WORDS = 30           -- a buff's bar: its insets and the gap between its two texts
local AURA, AURA_GAP = 20, 2
local DEFAULT_SIZE, DEFAULT_OPACITY = 14, 97 -- as the settings have them at first (Tooltips.lua)
local COMPARED_ALPHA = 0.85     -- the panel of what you wear, beside the panel of what you look at
local SCREEN_MARGIN = 8         -- a panel in columns keeps so much room above and below it on the screen
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
-- One grey (COLOR.NOTE) for a section's name and its rules, a table's captions and the lines between its cells, the
-- groove between two columns and the notes at the bottom (Saneroki, 2026-10-23: a dark see-through shade read badly).
-- A table's values keep their colour.
local LABEL, VALUE, TAG, NOTE = COLOR.DETAIL, COLOR.WHITE, COLOR.GOLD, COLOR.NOTE
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
local ox = 0       -- how far right of the panel's left side the column being laid begins, for one draw
local tops = {}    -- [row] = where it begins, laid in one column (Lay, Columns), for one draw
local breaks = {}  -- [row] = true: it begins a new column (Columns), for one draw
local widestCell = 0 -- the widest cell of a panel's tables, for one draw
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
    -- In grey (NOTE): a table's captions, a section's name between its rules, and the notes at the bottom
    -- (Unconfirmed Data, Hold ALT for more), smaller, without rules
    caption = { font = "GameTooltipText", add = -4, least = 8 },
    section = { font = "GameTooltipText", add = -4, least = 8 },
    hint = { font = "GameTooltipText", add = -6, least = 7 },
    detail = { font = "GameTooltipText", add = -4, least = 8 },  -- a unit's kind, PvP
    mark = { font = "GameTooltipHeaderText", add = -5, least = 8 }, -- the red ! beside Unconfirmed Data
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
    panel.icon:SetSize(ICON, ICON)
    panel.iconMask = panel:CreateMaskTexture()
    panel.iconMask:SetAllPoints(panel.icon)
    panel.icon:AddMaskTexture(panel.iconMask)
    -- Over the 3D model (Figure, a frame of its own: it would cover the panel's own pictures): the
    -- dragon, the plaque and the level on it.
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

-- The 3D model in the picture's place (the option models), on a see-through ground: a unit's own,
-- moving, its face in view (PlayerModel: SetUnit, SetPortraitZoom); a mount's or a pet's (PlayerModel:
-- SetDisplayInfo). Which one, and how near and turned, is the reader's (head.model, Figures.lua). The
-- frame is made for the first model a panel shows (a client without it: the picture, always).
-- A frame is given its model only when that changes, as giving it again would load it anew and start
-- its moves over, and a panel is drawn many times while it is shown. It keeps it while hidden: a panel
-- shown again with the same thing is not drawn anew (Tooltips.lua), so the model must still be there.
-- The model is always wanted, the picture only its stand-in (Saneroki, 2026-10-21): it stands until the
-- model is there: a unit's as soon as the game takes the unit; a creature's and a piece of gear when the
-- game has loaded it (OnModelLoaded). A unit the game refuses at first (its model not ready yet) is asked
-- for again every Panel.RETRY seconds, Panel.RETRIES times, while the panel shows it (no Alt, no new draw
-- needed). Where the game still cannot draw it (a unit out of sight, its identity hidden, a model it does
-- not load), the picture stays, until the next draw.
local FRAMES = { figure = "PlayerModel" } -- [the panel's field] = the kind of frame
Panel.RETRY, Panel.RETRIES = 0.1, 10 -- a unit's model refused at first: asked again so often, so many times
local Retry, retrying -- below; Retry guarded once when the first frame is made (Made)
local TRIED = Enum.ItemTryOnReason and Enum.ItemTryOnReason.Success or 0

-- The model has come: it stands in the picture's place from now.
local function Loaded(figure)
    if figure.ready or not figure.key then return end
    figure.ready = true
    local panel = figure.panel
    if panel.figured ~= figure then return end
    panel.icon:Hide()
    figure:SetAlpha(panel.allowed and 1 or 0)
end

local function Made(panel, field)
    local figure = panel[field]
    if figure ~= nil then return figure end
    local made
    made, figure = pcall(CreateFrame, FRAMES[field], nil, panel)
    figure = made and figure or false -- false: this client has none, not asked again
    if figure then
        figure.panel = panel
        figure:SetAllPoints(panel.icon)
        pcall(figure.SetKeepModelOnHide, figure, true) -- (see above: kept while hidden)
        pcall(figure.SetScript, figure, "OnModelLoaded", ns.Guard(Loaded))
        figure.ready = false
        retrying = retrying or ns.Guard(Retry)
    end
    panel[field] = figure
    return figure
end

-- Gives a frame its model. Returns whether the game took it, and whether it is there at once. was:
-- whether the frame's model before was there.
local LOAD = {
    unit = function(figure, head)
        local taken = Ask(figure.SetUnit, figure, head.portrait) == true
        if taken then figure:SetPortraitZoom(1) end
        return taken, taken
    end,
    display = function(figure, head)
        return pcall(figure.SetDisplayInfo, figure, head.model), false
    end,
}

-- The model the picture's place shows: what kind, which (it is given anew when this changes).
local function Wanted(head)
    if head.portrait then return head.guid and "unit" or nil, head.guid end
    if head.icon then return head.modelKind, head.model end
    return nil
end

-- A unit's model the game refused at first, asked for again (see above) while the frame waits unseen; taken, it
-- stands in the picture's place at once. The panel drawn anew, or shown with another thing, ends the asking.
function Retry(figure, elapsed)
    figure.wait = figure.wait - (elapsed or 0)
    if figure.wait > 0 then return end
    figure.wait, figure.tries = Panel.RETRY, figure.tries - 1
    local panel, head = figure.panel, figure.head
    local kind, key = Wanted(head)
    local taken = key == figure.want and LOAD[kind] and LOAD[kind](figure, head)
    if taken then
        figure:SetScript("OnUpdate", nil)
        figure.key, figure.ready, figure.head = key, true, nil
        panel.figured = figure
        panel.icon:Hide()
        figure:SetAlpha(panel.allowed and 1 or 0)
    elseif key ~= figure.want or figure.tries <= 0 then
        figure:SetScript("OnUpdate", nil)
        figure.head = nil
        figure:Hide()
    end
end
-- Shows the frame for the head's model, given it if it is a new one. Returns whether the model stands
-- in the picture's place now.
local function Figure(panel, head)
    local kind, key = Wanted(head)
    if not (key and LOAD[kind] and ns.options and ns.options.models ~= false) then kind = nil end
    local field = "figure"
    for other in pairs(FRAMES) do
        local frame = panel[other]
        if frame and (other ~= field or not kind) then frame:Hide() end
    end
    panel.figured = nil
    local waiting = panel[field]
    if waiting and waiting.head then -- a refused unit's asking ends: this draw decides anew
        waiting:SetScript("OnUpdate", nil)
        waiting.head = nil
    end
    if not kind then return false end
    local figure = Made(panel, field)
    if not figure then return false end
    figure:Show()
    if figure.key ~= key then
        figure:ClearModel()
        figure.key, figure.ready = key, false
        local taken, ready = LOAD[kind](figure, head)
        if not taken then
            figure.key = nil -- asked again at the next draw
            if kind == "unit" then -- perhaps not ready yet: asked again in a moment, unseen meanwhile (Retry)
                figure.head, figure.want, figure.tries, figure.wait = head, key, Panel.RETRIES, Panel.RETRY
                figure:SetAlpha(0)
                figure:SetScript("OnUpdate", retrying)
            else
                figure:Hide()
            end
            return false
        end
        if kind ~= "unit" then pcall(figure.SetPortraitZoom, figure, head.modelZoom or 0) end
        -- Turned (a mount a little, a cloak from behind); a unit as the game turns it, back from a turn
        local turn = kind ~= "unit" and head.modelTurn or 0
        if turn ~= 0 or figure.turned then
            pcall(figure.SetFacing, figure, turn)
            figure.turned = turn ~= 0
        end
        -- There at once: the game says so, or it had the model already
        local file = Ask(figure.GetModelFileID, figure)
        if ready or (type(file) == "number" and file > 0) then figure.ready = true end
    end
    panel.figured = figure
    return figure.ready
end

-- The tooltip's panel, made when it is first asked for.
function Panel.Of(tooltip)
    return panels[tooltip] or Create(tooltip)
end

function Panel.All()
    return panels
end

-- The panel seen at its strength, or see-through while it may not be seen yet (the option show).
-- Its 3D model too, by itself (a model frame need not follow the alpha of the frame it is in), once
-- the model is there.
function Panel.Strength(panel, allowed)
    panel.allowed = allowed
    panel:SetAlpha(allowed and panel.strength or 0)
    local figure = panel.figured
    if figure then figure:SetAlpha(allowed and figure.ready and 1 or 0) end
    local stage = panel.stage
    if stage then stage.model:SetAlpha(allowed and stage.model.ready and 1 or 0) end
end

-------------------------------------------------------------------------------
--  The stage: with Alt held over a piece of gear (head.dress, Figures.lua),
--  your own character wearing it, as the game's dressing room puts it on you
--  (DressUpModel: you as you are, then TryOn), see-through beside the panel,
--  no ground of its own: as high as the panel, as far from it as two panels
--  stand apart, turning slowly round. At the panel's left; at its right where the left has
--  no room on the screen, or the comparisons (Host.lua) stand there. Let go
--  of Alt and it is gone; hidden, it does not turn.
--
--  Your character is given to the frame once (SetUnit) and kept while hidden
--  (SetKeepModelOnHide), so Alt shows it at once; each time it is shown it is
--  dressed anew in what you wear (Dress), then tries the piece on. It stands
--  unseen until the game has loaded it (OnModelLoaded), so nothing half-made
--  is seen. A client without the frame, or that cannot put your character in
--  it, has no stage: the panel alone.
-------------------------------------------------------------------------------
local STAGE_WIDE = 0.6 -- the stage's width, of its height: room for a character standing and turning
local STAGE_TURNS = 0.1 -- turns a second: once round in ten seconds
local STAGE_IN = 4      -- between the stage's edge and your character
local TURN = 2 * math.pi
local FACING = rawget(_G, "MODELFRAME_DEFAULT_ROTATION") or 0 -- where it starts: as the game's dressing room turns you

-- Turns the character, every frame while the stage is shown. Should the game refuse, it stands still.
local function Turn(model, elapsed)
    model.facing = (model.facing + elapsed * STAGE_TURNS * TURN) % TURN
    if not pcall(model.SetFacing, model, model.facing) then model:SetScript("OnUpdate", nil) end
end

local function Arrived(model)
    model.ready = true
    local panel = model.panel
    model:SetAlpha(panel.allowed and 1 or 0)
end

-- The panel's stage, made when it is first wanted; false where the client has no such frame.
local function Staged(panel)
    local stage = panel.stage
    if stage ~= nil then return stage end
    stage = CreateFrame("Frame", nil, panel)
    local made, model = pcall(CreateFrame, "DressUpModel", nil, stage)
    if not made or not model then
        panel.stage = false
        return false
    end
    model.panel, model.ready, model.facing = panel, false, FACING
    model:SetPoint("TOPLEFT", stage, "TOPLEFT", STAGE_IN, -STAGE_IN)
    model:SetPoint("BOTTOMRIGHT", stage, "BOTTOMRIGHT", -STAGE_IN, STAGE_IN)
    pcall(model.SetKeepModelOnHide, model, true)
    pcall(model.SetScript, model, "OnModelLoaded", ns.Guard(Arrived))
    model:SetScript("OnUpdate", ns.Guard(Turn))
    stage.model = model
    stage:Hide()
    panel.stage = stage
    return stage
end

-- Your character in the stage's frame, wearing link. False where the game will not have it.
local function Dressed(model, link)
    if not model.unit then
        if Ask(model.SetUnit, model, "player") ~= true then return false end
        model.unit = true
        local file = Ask(model.GetModelFileID, model)
        if type(file) == "number" and file > 0 then model.ready = true end
    else
        pcall(model.Dress, model) -- what you wear now, not the piece tried on before
    end
    pcall(model.SetPortraitZoom, model, 0) -- the whole of you
    local tried, reason = pcall(model.TryOn, model, link)
    reason = Plain(reason)
    return tried and (reason == nil or reason == TRIED)
end

-- The side of the panel the stage stands on: its left, unless the left has no room for it on the
-- screen or the panel's comparisons stand there.
local function StageSide(panel, wide)
    if ns.Host.CompareSide and ns.Host.CompareSide(panel.tooltip) == "left" then return "right" end
    local left = Plain(panel:GetLeft())
    if type(left) == "number" and left - wide - 2 * SOFT_OUT < 0 then return "right" end
    return "left"
end

-- Shows the stage where it is wanted now, or hides it: at every draw and once a frame while the panel is
-- shown (Tooltips.lua), so pressing or letting go of Alt, or the comparisons coming, moves it at once.
function Panel.Stage(panel)
    local head = panel.model.shown.head
    local link = head.dress
    local wanted = link and not head.compared and IsAltKeyDown() and ns.options and ns.options.models ~= false
    local stage = panel.stage
    if not wanted then
        if stage and stage:IsShown() then stage:Hide() end
        return
    end
    stage = Staged(panel)
    if not stage then return end
    local high = Plain(panel:GetHeight())
    if not (type(high) == "number" and high > 0) then return end
    local wide = math.floor(high * STAGE_WIDE + 0.5)
    if stage.high ~= high then
        stage.high = high
        stage:SetSize(wide, high)
    end
    local side = StageSide(panel, wide)
    if stage.side ~= side then
        stage.side = side
        stage:ClearAllPoints()
        if side == "left" then
            stage:SetPoint("TOPRIGHT", panel, "TOPLEFT", -2 * SOFT_OUT, 0)
        else
            stage:SetPoint("TOPLEFT", panel, "TOPRIGHT", 2 * SOFT_OUT, 0)
        end
    end
    -- Among the frames just over the panel
    local model, own = stage.model, Plain(panel:GetFrameLevel()) or 0
    if stage.level ~= own then
        stage.level = own
        stage:SetFrameLevel(own + 1)
        model:SetFrameLevel(own + 2)
    end
    -- Shown already, or refused: nothing to do until the piece changes (asked once a frame)
    if stage.link == link and (stage.refused or stage:IsShown()) then return end
    stage.link, stage.refused = link, false
    stage:Show()
    if not Dressed(model, link) then
        stage.refused = true -- (your character cannot wear it: not asked again for this piece)
        stage:Hide()
        return
    end
    model:SetAlpha(panel.allowed and model.ready and 1 or 0)
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
-- before the first caption stand beside the icon (iconRoom). Returns that width, and the tag's text.
local function Measure(panel, head, rows, count, r, g, b, iconRoom)
    local wanted, beside, tag = 0, true, nil
    widestCell = 0
    if head.tag and head.tag ~= "" then
        tag = Text(panel, FONTS.tag, Upper(head.tag), TAG[1], TAG[2], TAG[3])
        wanted = Width(tag) + iconRoom
    end
    for index = 1, count do
        local row = rows[index]
        local kind = row.kind
        if row.space or kind ~= "text" then beside = false end
        panel.left[index], panel.right[index], panel.after[index] = nil, nil, nil
        if kind == "text" and row.live then
            -- A row Live.lua fills: only words of our own are measured (see Pools.lua).
            local left = Text(panel, FONTS[row.font] or FONTS.row, row.left, row.lr, row.lg, row.lb)
            panel.left[index] = left
            wanted = math.max(wanted, Width(left) + NAME_GAP + LIVE_ROOM)
        elseif kind == "bar" and (row.live == "aura" or row.inside) then
            -- A buff's bar, an item's durability: wide enough for the words written inside it
            local font = FONTS.inside
            local time, caster = Text(panel, font, row.left), Text(panel, font, row.right)
            wanted = math.max(wanted, Width(time) + Width(caster) + AURA_WORDS)
            time:Hide()
            caster:Hide()
        elseif kind == "text" then
            local font = FONTS[row.font] or FONTS.row
            -- A description stands in the middle, each of its lines
            local left = Text(panel, font, Words(row, head, r, g, b), row.lr, row.lg, row.lb, row.prose and "CENTER" or nil)
            local right = Text(panel, font, row.right, row.rr, row.rg, row.rb, "RIGHT")
            panel.left[index], panel.right[index] = left, right
            local wide = Width(left) + (row.indent or 0) + (row.icon and SMALL_ICON + 4 or 0)
                + (row.iconRight and SMALL_ICON + 4 or 0)
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
            -- A row of a table: every row of a panel's tables has the same columns, each as wide as the
            -- widest cell of them all
            cells[index] = panel.texts.taken + 1
            for cell = 1, #row, 2 do
                local caption = Text(panel, FONTS.caption, Upper(row[cell]), NOTE[1], NOTE[2], NOTE[3], "CENTER")
                local value = Text(panel, FONTS.value, row[cell + 1], VALUE[1], VALUE[2], VALUE[3], "CENTER")
                widestCell = math.max(widestCell, math.max(Width(caption), Width(value)) + 2 * CELL_INSET)
            end
            wanted = math.max(wanted, widestCell * #row / 2)
        elseif kind == "caption" then
            -- In the middle, with a rule at each side
            local font = FONTS[row.font] or FONTS.section
            local caption = Text(panel, font, row.caps and Upper(row.left) or row.left, NOTE[1], NOTE[2], NOTE[3], "CENTER")
            panel.left[index] = caption
            local marks = 0
            if row.mark then
                -- A red ! at each side of the name, between it and its rules
                local red = COLOR.RED
                panel.after[index] = Text(panel, FONTS.mark, "!", red[1], red[2], red[3], "CENTER")
                panel.right[index] = Text(panel, FONTS.mark, "!", red[1], red[2], red[3], "CENTER")
                marks = 2 * (Width(panel.after[index]) + CAPTION_GAP)
            end
            wanted = math.max(wanted, Width(caption) + marks + (row.bare and 0 or 2 * (CAPTION_GAP + CAPTION_RULE)))
        elseif kind == "graph" then
            wanted = math.max(wanted, ns.Graph.WIDE)
        end
    end
    return wanted, tag
end

-- The icon, or a unit's portrait, or the 3D model in their place (Figure), and the plaque with its
-- words on the lower edge. Returns how far down the picture reaches, and where a plaque wider
-- than the picture begins (its left and top), for the rows beside it.
local function Picture(panel, head, badge, width, pictured)
    -- At the first column's top right corner (a panel in columns is wider than width)
    panel.icon:ClearAllPoints()
    panel.icon:SetPoint("TOPLEFT", panel, "TOPLEFT", width + ICON_OUT - ICON, ICON_OUT)
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
    Pools.Lift(badge, panel.front) -- over a 3D model, with its plaque
    badge:SetDrawLayer("OVERLAY", 7)
    badge:SetShadowColor(0, 0, 0, 1)
    Place(panel, badge, left, top + (height - FONTS.badge.size) / 2, wide)
    return bottom + height / 2, left - PLAQUE.out, top - PLAQUE.out
end

-- A row of words, with what may stand at its sides (small icons), at y. Returns its height.
local function TextRow(panel, row, index, y, room, reserve, width)
    local left, right, after = panel.left[index], panel.right[index], panel.after[index]
    local font = FONTS[row.font] or FONTS.row
    local x = ox + SIDE + (row.indent or 0)
    if row.icon then
        Icon(panel, row.icon, SMALL_ICON):SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
        x, room = x + SMALL_ICON + 4, room - SMALL_ICON - 4
    end
    room = room - (row.indent or 0)
    local edge = SIDE + reserve -- from the panel's right side
    if row.iconRight then
        Icon(panel, row.iconRight, SMALL_ICON):SetPoint("TOPLEFT", panel, "TOPLEFT", ox + width - edge - SMALL_ICON, -y)
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
        height = math.max(height, Place(panel, right, ox + width - edge - rightRoom, y, rightRoom))
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
    local wide = inner / math.max(1, number) -- columns alike, so the rows of a table line up
    local valueTop = y + FONTS.caption.size + 2
    local height = FONTS.caption.size + 2 + FONTS.value.size + 2
    local x = ox + SIDE
    for cell = 1, number do
        Place(panel, panel.texts[first + 2 * cell - 2], x, y, wide)
        Place(panel, panel.texts[first + 2 * cell - 1], x, valueTop, wide)
        if cell > 1 then
            local separator = Line(panel, NOTE[1], NOTE[2], NOTE[3], 1)
            separator:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -(y + 1))
            separator:SetSize(hairline, height - 2)
        end
        x = x + wide
    end
    return height
end

-- A unit's health or a buff's time, as Live.lua keeps them (power lies over health: no place of
-- its own), or an item's durability with its words inside. Returns the y under it.
local function BarRow(panel, row, y, inner, block)
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
        bar:SetPoint("TOPLEFT", panel, "TOPLEFT", ox + SIDE, -y)
        bar:SetWidth(inner)
        live[row.live] = bar
        block.top, block.bottom, block.left = block.top or y, y + HEALTH_HEIGHT, block.left or ox
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
    if row.inside then
        -- An item's durability: as a unit's health bar, flat with round corners, the word at its left and
        -- the numbers at its right inside
        local bar = LiveBar(panel, "inside", HEALTH_HEIGHT, row.br, row.bg, row.bb)
        bar:SetMinMaxValues(0, row.max or 1)
        bar:SetValue(row.value or 0)
        bar:SetPoint("TOPLEFT", panel, "TOPLEFT", ox + SIDE, -y)
        bar:SetWidth(inner)
        block.top, block.bottom, block.left = block.top or y, y + HEALTH_HEIGHT, block.left or ox
        if bar.texts then for _, text in pairs(bar.texts) do text:Hide() end end
        BarText(bar, "LEFT", FONTS.inside):SetText(row.left)
        BarText(bar, "RIGHT", FONTS.inside):SetText(row.right)
        return y + HEALTH_HEIGHT + ROW_GAP
    end
    return y
end

local block = {} -- the stretch of a unit's bars, for their round corners, for one draw

-- Lays out the rows from y down, a new column at each of breaks (none: one column). Notes where each row
-- begins (tops). Returns the y under the last, and the lowest y of all columns.
local function Lay(panel, rows, count, y, width, iconRoom, iconBottom, plaqueLeft, plaqueTop, hairline, columned)
    local inner = width - 2 * SIDE
    local live = panel.live
    local lowest = 0
    block.top, block.bottom, block.left = nil, nil, nil
    ox = 0
    for index = 1, count do
        local row = rows[index]
        local kind = row.kind
        if columned and breaks[index] then
            -- The next column, from the top; the icon stands beside the first one only
            lowest = math.max(lowest, y)
            ox, y = ox + width, SIDE
            iconBottom, plaqueLeft = 0, nil
        end
        tops[index] = y
        local font = FONTS[row.font] or FONTS.row
        if (row.space or kind ~= "text") and y < iconBottom then y = iconBottom + ROW_GAP end
        if row.space then y = y + SPACE end
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
            Place(panel, word, ox + SIDE, y, wide)
            live.targetName = LiveText(panel, "targetName", font, "LEFT", ox + SIDE + wide + NAME_GAP, y, room - wide - NAME_GAP)
            y = y + font.size + 2 + ROW_GAP
        elseif kind == "text" then
            if row.flush then y = y - FLUSH end -- close under the row before it (a guild under a name)
            y = y + TextRow(panel, row, index, y, room, reserve, width) + ROW_GAP
        elseif kind == "strip" then
            y = y + StripRow(panel, row, index, y, inner, hairline) + ROW_GAP
        elseif kind == "bar" then
            y = BarRow(panel, row, y, inner, block)
        elseif kind == "caption" then
            -- A section's name in the middle, and a rule from each side to it
            local caption, before, after = panel.left[index], panel.after[index], panel.right[index]
            local wide = math.min(Width(caption) + 2, inner)
            local left = ox + SIDE + math.floor((inner - wide) / 2)
            y = y + CAPTION_ABOVE
            local height = Place(panel, caption, left, y, wide)
            local outer, mark = 0, 0 -- the marks' room at each side of the name
            if row.mark and before then
                mark = Width(before)
                outer = mark + CAPTION_GAP
                -- On the name's base line: the marks' text is larger
                local drop = ((FONTS[row.font] or FONTS.section).size - FONTS.mark.size) * BASE_LINE
                Place(panel, before, left - outer, y + drop, mark)
                Place(panel, after, left + wide + CAPTION_GAP, y + drop, mark)
            end
            local rule = left - outer - ox - SIDE - CAPTION_GAP
            if rule >= CAPTION_RULE and not row.bare then
                local middle = y + math.floor(height / 2)
                Rule(panel, ox + SIDE, middle, rule, hairline)
                Rule(panel, left + wide + outer + CAPTION_GAP, middle, rule, hairline)
            end
            y = y + height + CAPTION_BELOW
        elseif kind == "auras" then
            live.aurasTop, live.aurasWidth, live.aurasLeft = y, inner, ox + SIDE
            y = y + AURA + ROW_GAP
        elseif kind == "graph" then
            -- Only its place: drawn once the rows have theirs for good (Panel.Draw)
            panel.graphRow, panel.graphX, panel.graphY = row, ox + SIDE, y
            y = y + ns.Graph.Height() + ROW_GAP
        end
    end
    if block.top then
        panel.barMask:ClearAllPoints()
        panel.barMask:SetPoint("TOPLEFT", panel, "TOPLEFT", block.left + SIDE, -block.top)
        panel.barMask:SetPoint("BOTTOMRIGHT", panel, "TOPLEFT", block.left + width - SIDE, -block.bottom)
    end
    return y, math.max(lowest, y)
end

-- How tall a panel may be: the screen's height in the panel's units, less a margin above and below.
local function Tallest(panel)
    local screen, ui, own = Plain(UIParent:GetHeight()), Plain(UIParent:GetEffectiveScale()), Plain(panel:GetEffectiveScale())
    if not (type(screen) == "number" and screen > 0 and type(ui) == "number" and type(own) == "number" and own > 0) then return nil end
    return screen * ui / own - 2 * (SOFT_OUT + SCREEN_MARGIN)
end

-- Where the columns of a panel too tall for the screen begin (breaks), from the rows laid in one column
-- (tops, bottom: the y under the last). A column ends before the row that would run past tallest; a
-- section's name never stays alone at a column's foot: it goes on with its rows. Returns how many columns.
local function Columns(rows, count, bottom, tallest)
    for index in pairs(breaks) do breaks[index] = nil end
    if not tallest or bottom + SIDE - ROW_GAP <= tallest then return 1 end
    local columns, base, first = 1, 0, 1 -- base: how far up the column's rows are moved; first: its first row
    for index = 2, count do
        local under = (index < count and tops[index + 1] or bottom) - base
        if under + SIDE - ROW_GAP > tallest then
            local at = index
            if rows[at - 1].kind == "caption" and at - 1 > first then at = at - 1 end
            breaks[at] = true
            columns, base, first = columns + 1, tops[at] - SIDE, at
        end
    end
    return columns
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
    -- The 3D model over the panel's own pictures, the dragon and the plaque over the model
    local own = Plain(panel:GetFrameLevel()) or 0
    if panel.figured then panel.figured:SetFrameLevel(own + 1) end
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
    panel.graphRow = nil
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
    -- A hairline: one unit of the UI, rounded to whole dots of the screen and never less than one
    -- (Core.Pixels, by the game's PixelUtil): it stays sharp at every scale.
    local hairline = Core.Pixels(panel, 1)
    local top, lines, icons = y, panel.lines.taken, panel.icons.taken
    y = Lay(panel, rows, count, top, width, iconRoom, iconBottom, plaqueLeft, plaqueTop, hairline)
    local columns = Columns(rows, count, y, Tallest(panel))
    if columns > 1 then
        -- Laid again in columns: the lines and icons of the first laying given back (texts are placed anew)
        Pools.Rewind(panel.lines, lines)
        Pools.Rewind(panel.icons, icons)
        local _, lowest = Lay(panel, rows, count, top, width, iconRoom, iconBottom, plaqueLeft, plaqueTop, hairline, true)
        y = lowest
        panel:SetWidth(width * columns)
    end
    ns.Graph.Draw(panel, width - 2 * SIDE, hairline)
    y = math.max(y, iconBottom + ROW_GAP)
    local height = y + SIDE - ROW_GAP
    panel:SetHeight(height)
    for column = 2, columns do
        -- A groove between two columns
        local groove = Line(panel, NOTE[1], NOTE[2], NOTE[3], 1)
        groove:SetPoint("TOPLEFT", panel, "TOPLEFT", (column - 1) * width, -SIDE)
        groove:SetSize(hairline, height - 2 * SIDE)
    end
    Finish(panel, head, pictured, r, g, b)
    if Pools.Spoilt() then
        panel:Hide()
        return false
    end
    local shown = panel:IsShown()
    panel:Show()
    if shown then ns.Live.Start(panel) end -- shown anew, its OnShow started the live parts already
    return true
end

-- For Live.lua, which lays out a unit's buff icons itself: their size, the gap between them, and
-- where the panel's content begins. For Host.lua: how far a panel's soft edge reaches out.
Panel.AURA, Panel.AURA_GAP, Panel.SIDE, Panel.EDGE = AURA, AURA_GAP, SIDE, SOFT_OUT
Panel.FONTS = FONTS -- the kinds of text, for the tests
