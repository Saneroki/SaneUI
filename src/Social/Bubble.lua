local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Bubble
--  One message in the window: measured (Measure), drawn (Init) and taken out
--  of sight when the list's top edge cuts it (Cut). How much of it is seen is
--  the window's, from the message's own fade (Fade.lua), on the row's alpha.
--
--  The list has to know a row's height before the row exists, and the height
--  depends on where the text wraps. So every message is measured once per
--  window width and text size with a text nobody sees (the ruler), and the
--  result is kept on the message. Drawing uses the same numbers, so both
--  always agree.
--
--  The rows are the list's and are used again for other messages: Init sets
--  everything a row shows. What belongs to a row is kept here, not on the row.
--  All a row shows is in one frame of ours inside it (body), so it can be
--  hidden as a whole while the row itself, whose alpha the fading uses, stays
--  the list's.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Bubble = {}
ns.Bubble = Bubble

local UNKNOWN = "Interface\\Icons\\INV_Misc_QuestionMark" -- a speaker without a class the game knows

local font       -- the messages' and the names' font: the game's chat font, in the size chosen
local sized = 0  -- counts the changes of that size: a message measured before one is measured again
local look = { top = { 0.15, 0.15, 0.17 }, alpha = 1 } -- every bubble's fill (Core's Shape), as set
local painted = 0 -- counts the changes of that look: a bubble drawn before one is painted again
local brief = true -- the chats' names in short: "G" for "Guild"
local ruler
local parts = {} -- [row] = { body, ring, icon, name, meta, bubble, plate, text, painted }

-- The size of the text. The font stays the game's chat font (which differs by language); a font of
-- ours takes it over and only changes the size, as the game does for its own chat windows (Core.Font).
function Bubble.Size(size)
    font = Core.Font("SaneUIChatFont", ChatFontNormal, size)
    Layout.HEAD = size + 4
    sized = sized + 1
end

-- How solid the bubbles' fill is, in percent (100 solid, 0 only the text); and what it is, as set
-- (bubbleBack: one of the game's tiles, Core.Skin.TILES, or a colour, bubbleColor), the same for every
-- bubble. The text in them stays as it is: only its colour tells the kind of message.
function Bubble.Opacity(percent)
    local options = ns.options or {}
    local tile = Core.Skin.Tile(options.bubbleBack)
    look.alpha = math.min(math.max(percent, 0), 100) / 100
    look.file, look.size = tile and tile.file, tile and tile.size
    local red, green, blue = Core.RGB(options.bubbleColor)
    if red then look.top[1], look.top[2], look.top[3] = red, green, blue end
    look.bottom = nil -- the colour all the way down
    painted = painted + 1
end

-- The chats' names above the bubbles in short, or in full.
function Bubble.Brief(on)
    brief = on and true or false
end

-- Paints a plate (Core's Shape) as the bubbles are painted; the line you write in has their fill too.
function Bubble.Paint(plate)
    plate:Look(look)
end

-- A text that only measures, never seen: in a frame of its own that is fully see-through. Not the
-- text's own alpha: the game sets that anew from its font object whenever the font changes (a new
-- text size), and the last message measured stood in the window's corner in white.
function ns.Ruler(parent)
    local hidden = CreateFrame("Frame", nil, parent)
    hidden:SetAllPoints()
    hidden:SetAlpha(0)
    local text = hidden:CreateFontString(nil, "BACKGROUND")
    text:SetPoint("TOPLEFT")
    text:SetNonSpaceWrap(true)
    return text
end

-- The text that measures the messages, in the window.
function Bubble.Ruler(parent)
    ruler = ns.Ruler(parent)
    ruler:SetFontObject(font)
end

-- The height of a message's row in a list that wide.
-- A message's height if it was measured at this width and text size; nil if not.
function Bubble.Known(entry, rowWidth)
    if entry.fits ~= rowWidth or entry.sized ~= sized then return nil end
    return Layout.RowHeight(entry.side, entry.textHeight)
end

function Bubble.Measure(entry, rowWidth)
    if entry.fits ~= rowWidth or entry.sized ~= sized then
        local widest = Layout.TextWidth(rowWidth, entry.side)
        ruler:SetWidth(widest)
        ruler:SetText(entry.text)
        entry.textWidth = math.min(ruler:GetWrappedWidth(), widest)
        entry.textHeight = ruler:GetStringHeight()
        -- Only now: a measuring that failed half way is not taken for done.
        entry.fits, entry.sized, entry.widest = rowWidth, sized, widest
    end
    return Layout.RowHeight(entry.side, entry.textHeight)
end

-- "Guild  21:07", or "G  21:07": the chat in its colour, and the time. Made once per message and way of naming.
local function Meta(entry)
    if not entry.meta or entry.metaBrief ~= brief then
        local time = GRAY_FONT_COLOR:WrapTextInColorCode(entry.time)
        local label = brief and entry.short or entry.label
        entry.meta = label and (RGBToColorCode(entry.r, entry.g, entry.b) .. label .. "|r  " .. time) or time
        entry.metaBrief = brief
    end
    return entry.meta
end

local function Build(row)
    local part = {}
    local body = CreateFrame("Frame", nil, row)
    body:SetAllPoints()
    part.body = body
    ns.Links.Enable(body) -- the speaker's name

    -- The icon is round, on a round disc a little larger: the disc's rim is the ring around the icon.
    -- Both are round by a round mask over the whole of each (Core.Shape.Round).
    part.ring = body:CreateTexture(nil, "BACKGROUND")
    part.ring:SetSize(Layout.ICON, Layout.ICON)
    part.ring:SetPoint("TOPLEFT")
    Core.Shape.Round(part.ring)
    part.icon = body:CreateTexture(nil, "ARTWORK")
    part.icon:SetSize(Layout.ICON - 2 * Layout.RING, Layout.ICON - 2 * Layout.RING)
    part.icon:SetPoint("CENTER", part.ring)
    Core.Shape.Round(part.icon)

    part.name = body:CreateFontString(nil, "ARTWORK")
    part.name:SetFontObject(font)
    part.name:SetPoint("TOPLEFT", Layout.ICON + Layout.GAP, 0)
    part.name:SetWordWrap(false)
    part.meta = body:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    part.meta:SetWordWrap(false)

    -- A plain fill with round corners and nothing else: no border, no ornament (Core's Shape, of one
    -- radius wherever it is).
    part.bubble = CreateFrame("Frame", nil, body)
    part.plate = Core.Shape.New(part.bubble, { radius = Layout.RADIUS })
    ns.Links.Enable(part.bubble) -- the links in a message
    part.text = part.bubble:CreateFontString(nil, "ARTWORK")
    part.text:SetFontObject(font)
    part.text:SetPoint("TOPLEFT", Layout.PAD_X, -Layout.PAD_Y)
    part.text:SetJustifyH("LEFT")
    part.text:SetNonSpaceWrap(true)

    parts[row] = part
    return part
end

-- The speaker's class, round; and around it the colour of what the speaker is to you (white: nothing).
local function Icon(part, entry)
    if entry.class and GetClassAtlas then
        part.icon:SetAtlas(GetClassAtlas(entry.class:lower()))
    else
        part.icon:SetTexture(UNKNOWN)
    end
    local color = Layout.TIES[entry.tie or "none"] or Layout.TIES.none
    part.ring:SetColorTexture(color[1], color[2], color[3])
end

function Bubble.Init(row, entry, rowWidth)
    local part = parts[row] or Build(row)
    Bubble.Measure(entry, rowWidth) -- already known, unless the width or the text size changed since
    local side = entry.side
    local note, theirs = side == "center", side == "left"

    part.body:Show()
    part.meta:SetShown(not note)
    part.name:SetShown(theirs)
    part.icon:SetShown(theirs)
    part.ring:SetShown(theirs)

    -- Above the bubble: the name as large as the message, then the chat and the time, small.
    -- A note has nothing above it: it is no one's, or its text says whose.
    part.meta:ClearAllPoints()
    if theirs then
        Icon(part, entry)
        local color = entry.class and RAID_CLASS_COLORS[entry.class] or HIGHLIGHT_FONT_COLOR
        part.name:SetHeight(Layout.HEAD)
        part.name:SetText(entry.link or entry.name or "") -- a click on it whispers to them (Links.lua)
        part.name:SetTextColor(color.r, color.g, color.b)
        part.meta:SetPoint("LEFT", part.name, "RIGHT", entry.name and Layout.GAP or 0, 0)
    elseif not note then
        part.meta:SetPoint("RIGHT", part.body, "TOPRIGHT", -2, -Layout.HEAD / 2)
    end
    if not note then part.meta:SetText(Meta(entry)) end

    part.bubble:ClearAllPoints()
    if note then
        part.bubble:SetPoint("TOP")
    elseif theirs then
        part.bubble:SetPoint("TOPLEFT", Layout.ICON + Layout.GAP, -Layout.HEAD)
    else
        part.bubble:SetPoint("TOPRIGHT", 0, -Layout.HEAD)
    end
    local width, height = Layout.Bubble(entry.textWidth, entry.textHeight)
    part.bubble:SetSize(width, height)
    if part.painted ~= painted then
        part.painted = painted
        Bubble.Paint(part.plate)
    end
    part.plate:Fit(0, 0, width, height) -- only its size counts: its corners are round wherever it is
    -- As wide as the ruler was, so the text wraps where it was measured.
    part.text:SetWidth(entry.widest)
    part.text:SetText(entry.text)
    part.text:SetTextColor(entry.r, entry.g, entry.b)
end

-- A row the list's top edge cuts through shows nothing: half a message is worse than none.
function Bubble.Cut(row, cut)
    local part = parts[row]
    if part then part.body:SetShown(not cut) end
end
