local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Model
--  The contents of a panel, as plain data: a head (what holds for the whole panel)
--  and a list of rows, top to bottom. The readers fill it (Read.lua and the
--  files in Kinds), Panel.lua draws it.
--
--  A shown tooltip is filled again several times a second, mostly with the
--  same lines. So a model has two copies: the one that is drawn (shown) and
--  one to fill. After a fill the two are compared; only if they differ do
--  they change places and the panel is drawn again. Their tables are used
--  again and again, so reading a tooltip makes no new ones.
--
--  A row, by its kind:
--    "text"     left, right (and their colours), font; label: dimmer words after left, in
--               labelFont if given; icon, iconRight; indent; caps; prose (its numbers are
--               coloured); flush: close under the row before it;
--               live: "health" | "target" (Live.lua writes the text)
--    "strip"    facts side by side, each a caption over a value: its array part holds them
--               as caption, value, caption, value, ... (Read.Cell)
--    "bar"      live: "health" | "power" | "aura", or value and max; flush: no gap above;
--               short: a small bar with left and right text beside it
--    "caption"  left: a section's name, with a rule running on after it
--    "auras"    the unit's buffs and debuffs (Live.lua)
--  Every row: space (a little room above it: the game's empty line inside a
--  section), bar colour br, bg, bb. A panel's only dividers are its sections'
--  captions.
--
--  The palette is here too (ns.COLOR): every colour the rows are given, and
--  the panel's own.
-------------------------------------------------------------------------------
local Model = {}
ns.Model = Model

-------------------------------------------------------------------------------
--  The palette. Each colour of ours starts from one of the game's colours and
--  is moved part of the way toward another of them (Tone): no colour is typed
--  in by hand. The game's colours are read at load; the numbers beside their
--  names are the client's own, for a client that lacks one. Meanings stay the
--  game's: gold names a thing and heads a section, white is a value, grey is
--  said about the thing, red is what you cannot do, green what is done.
-------------------------------------------------------------------------------
local function Game(name, r, g, b)
    local color = rawget(_G, name)
    if type(color) == "table" and type(color.r) == "number" then return { color.r, color.g, color.b } end
    return { r, g, b }
end
ns.GameColor = Game

-- r, g, b of a colour moved share of the way to another: 0 is from, 1 is to.
local function Mix(from, to, share)
    return from[1] + (to[1] - from[1]) * share, from[2] + (to[2] - from[2]) * share, from[3] + (to[3] - from[3]) * share
end
ns.Mix = Mix

local function Tone(from, to, share)
    return { Mix(from, to, share) }
end

local WHITE = Game("HIGHLIGHT_FONT_COLOR", 1, 1, 1)
local GOLD = Game("NORMAL_FONT_COLOR", 1, 0.82, 0)
local GREY = Game("GRAY_FONT_COLOR", 0.5, 0.5, 0.5)
local RED = Game("RED_FONT_COLOR", 1, 0.125, 0.125)
local GREEN = Game("GREEN_FONT_COLOR", 0.1, 1, 0.1)
local BLACK = { 0, 0, 0 }

ns.COLOR = {
    -- The game's own, as they are: to know a line's colour by (ns.Like), and to show where the
    -- game would show them
    WHITE = WHITE, GOLD = GOLD, GREEN = GREEN, RED = RED,
    TITLE = Tone(WHITE, GREY, 0.08),    -- a name in the game's white, a large number, a strip's value
    LIGHT = Tone(WHITE, GREY, 0.2),     -- the game's white in a line
    DETAIL = Tone(WHITE, GREY, 0.42),   -- what is said about the thing: its kind, a time, who cast it
    ASIDE = Tone(GREY, WHITE, 0.3),     -- another addon's lines, the details Alt shows, a heading over a list
    NEUTRAL = Tone(GREY, WHITE, 0.2),   -- a panel without a colour of its own; a dead or offline unit's
    SILVER = Tone(GREY, WHITE, 0.6),    -- a rare creature's rank, as its silver dragon
    CAPTION = Tone(GOLD, BLACK, 0.2),   -- a section's name and a strip's captions: the game's gold, darker
    PROSE = Tone(GOLD, WHITE, 0.4),     -- a description, which the game writes in its gold: lighter
    PLAQUE = Tone(GOLD, WHITE, 0.75),   -- words on the gold plaque of a level (Panel.lua): almost white
    DONE = Tone(GREEN, GREY, 0.2),      -- an objective that is done, a quest to turn in, a good price
    HEALTH = Tone(GREEN, GREY, 0.35),   -- a unit's health, an item's durability
    AWAY = Game("ORANGE_FONT_COLOR", 1, 0.5, 0.25), -- a player who is away (AFK, DND)
    BACKDROP = Game("TOOLTIP_DEFAULT_BACKGROUND_COLOR", 0.09, 0.09, 0.19), -- the game's tooltips' ground
    BLACK = BLACK,
}

-- A colour as it is written inside a text, after "|cff": "ff7f00". (The game's RGBToColorCode
-- writes the same, with the "|cff".)
function ns.Hex(r, g, b)
    return ("%02x%02x%02x"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

-- Whether r, g, b is one of the game's colours (a line's white, gold or green): no part of it
-- further from the colour's than LIKE. The game hands a font's colour back a little rounded.
local LIKE = 0.12
function ns.Like(r, g, b, color)
    if not (r and g and b) then return false end
    return math.abs(r - color[1]) <= LIKE and math.abs(g - color[2]) <= LIKE and math.abs(b - color[3]) <= LIKE
end

-------------------------------------------------------------------------------
--  The two copies
-------------------------------------------------------------------------------
local ROW = { "kind", "font", "left", "right", "lr", "lg", "lb", "rr", "rg", "rb", "space", "label", "labelFont", "icon",
    "iconRight", "indent", "caps", "prose", "live", "value", "max", "flush", "short", "br", "bg", "bb", "points" }
local HEAD = { "tag", "compared", "accent", "ar", "ag", "ab", "icon", "portrait", "badge", "badgeR", "badgeG", "badgeB",
    "dragon", "unit", "guid", "power", "hasTarget", "hasAuras", "auraUnit", "auraID", "numbers",
    "model", "modelKind", "modelZoom", "modelTurn" }

local function Copy()
    return { n = 0, head = {}, rows = {} }
end

function Model.New()
    return { shown = Copy(), fill = Copy() }
end

-- Starts a fill: an empty head, no rows. Returns the copy to fill.
function Model.Begin(model)
    local fill = model.fill
    fill.n = 0
    local head = fill.head
    for index = 1, #HEAD do head[HEAD[index]] = nil end
    return fill
end

-- The next row of the copy being filled: a line of text until its kind is set.
function Model.Row(fill)
    local n = fill.n + 1
    local row = fill.rows[n]
    if not row then
        row = {}
        fill.rows[n] = row
    end
    for index = 1, #ROW do row[ROW[index]] = nil end
    for index = #row, 1, -1 do row[index] = nil end -- a strip's cells
    row.kind, row.font, row.left, row.right = "text", "row", "", ""
    fill.n = n
    return row
end

local function SameRow(a, b)
    for index = 1, #ROW do
        local key = ROW[index]
        if a[key] ~= b[key] then return false end
    end
    if #a ~= #b then return false end
    for index = 1, #a do
        if a[index] ~= b[index] then return false end
    end
    return true
end

local function Same(a, b)
    if a.n ~= b.n then return false end
    local headA, headB = a.head, b.head
    for index = 1, #HEAD do
        local key = HEAD[index]
        if headA[key] ~= headB[key] then return false end
    end
    for n = 1, a.n do
        if not SameRow(a.rows[n], b.rows[n]) then return false end
    end
    return true
end

-- Ends a fill. Returns whether it differs from what is shown; if it does, it is what is shown now.
function Model.Commit(model)
    if Same(model.fill, model.shown) then return false end
    model.fill, model.shown = model.shown, model.fill
    return true
end
