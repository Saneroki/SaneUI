local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Read
--  Reads a tooltip the game has filled and sorts what it says into a model
--  (Model.lua), from which its panel is drawn.
--
--  What is read are the tooltip's own lines as they stand (text and colour),
--  so every language and other addons' lines come along. The data the game
--  filled the tooltip from says what kind of thing it is and what kind each
--  line is; a file in Kinds sorts the lines of its kind of thing (an item, a
--  spell, a unit, ...) with the tools here. Anything else gets a name and its
--  lines (Generic).
--
--  Everything here works on tables that are used again: reading a tooltip
--  makes no new ones.
--
--  Each kind's reader runs by itself (ns.Read): one that fails switches only
--  its own kind off, whose tooltips are the game's own from then on.
--
--  Lines other addons add to a tooltip never stand among the panel's own rows
--  and sections: they come last, all of them, in a section of their own under
--  the caption Other addons (Others).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Secret = Core.Plain, Core.Secret
local Model = ns.Model
local LINE = Enum.TooltipDataLineType or {}
local TEXT, COLOR, Like = ns.TEXT, ns.COLOR, ns.Like
local TITLE, LIGHT, DETAIL, ASIDE, PROSE = COLOR.TITLE, COLOR.LIGHT, COLOR.DETAIL, COLOR.ASIDE, COLOR.PROSE

local Read = {}
ns.Reader = Read
ns.KINDS = {} -- [the game's kind of tooltip data] = function(ctx): fills the model

-- The kinds of line Rest knows. -1: this client has no such kind (a line's kind is never -1).
local BLANK, SEPARATOR, NESTED = LINE.Blank or -1, LINE.Separator or -1, LINE.NestedBlock or -1
local DESCRIPTION, UNTYPED = LINE.SpellDescription or -1, LINE.None or 0
local PROSE_WORDS = 6 -- a gold line of so many words reads as a description, where the data does not say
local LOOK_AHEAD = 3 -- how far a line may stand from where the data has it

-- What is being read. One table for every tooltip:
--   tooltip, data, kind, id, options, model   what is read, and for whom
--   fill, head                                 the copy of the model being filled
--   L[1..count]                                the tooltip's lines:
--       left, right, their colours (lr.. rb)   as they stand
--       type, data                             the kind of line and its data, if the game says
--       own                                    the game's line (not one another addon added)
--       blank, used                            empty; already shown by the kind's reader
--   rule                                       the next row gets a divider above it
--   tones                                      a change of colour group starts a new section (items)
--   each(row, line)                            the kind's last word on a row Rest makes
--   nested                                     the caption over a thing inside the thing (a recipe's item)
local ctx = { L = {} }

-- A line's colour on the dark panel. The game's white is toned down a little (less for a name);
-- its gold, which it writes descriptions in, is made lighter. Every other colour means something
-- (quality, cannot use, a bonus) and stays as it is.
local function Ease(r, g, b, title)
    if not (r and g and b) then return LIGHT[1], LIGHT[2], LIGHT[3] end
    if Like(r, g, b, COLOR.WHITE) then
        local soft = title and TITLE or LIGHT
        return soft[1], soft[2], soft[3]
    end
    if not title and Like(r, g, b, COLOR.GOLD) then return PROSE[1], PROSE[2], PROSE[3] end
    return r, g, b
end

-- Which of the game's line colours a line has: "green" (what an item does), "gold" (what is told
-- about it), or "plain" (white, and any other).
local function Family(r, g, b)
    if Like(r, g, b, COLOR.GREEN) then return "green" end
    if Like(r, g, b, COLOR.GOLD) then return "gold" end
    return "plain"
end
Read.Family = Family

-- One side of a line: its text and colour. "" when it has none, nil when the game hides it.
local function Side(font)
    if not font or not font:IsShown() then return "" end
    local text = font:GetText()
    if Secret(text) then return nil end
    local r, g, b = font:GetTextColor()
    return text or "", Plain(r), Plain(g), Plain(b)
end

-- The test realms' client adds a line to its tooltips, "Press F6 to submit an issue for this
-- spell". It is the same on every tooltip and says nothing about the thing: it is left out.
-- Known by how the game's own text for it begins.
local feedback
local function IsFeedback(text)
    if feedback == nil then
        local reporter = rawget(_G, "PTR_IssueReporter")
        local format = reporter and reporter.BugTooltipString
        feedback = type(format) == "string" and format:match("^(.-)%%s") or "|c0042b1fePress "
    end
    return text:find(feedback, 1, true) == 1 -- (no new string for every line, as a sub would make)
end

-- A line another addon writes with a number of the thing: "Spell ID: 1459", or "IconID" with the
-- number at the right. Such numbers belong in the section that Alt shows (Details), which has
-- them: the line is left out, with Alt held or not.
-- The words without colour codes: the game's own C_StringUtil.StripHyperlinks where it has it.
local strip = rawget(_G, "C_StringUtil") and C_StringUtil.StripHyperlinks
local function Plainer(text)
    if strip then return strip(text) end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
function Read.IsIdLine(line)
    local left, right = line.left, line.right
    if not left:find("I[Dd]") then return false end
    if not Plainer(left):match("^%s*[%a ]-I[Dd]%s*:?%s*%d*%s*$") then return false end
    return right == "" or Plainer(right):match("^%s*%d+%s*$") ~= nil
end

-- A description. The data says which line is one; a line it gives another kind is none. Where it
-- gives none (another addon's line, a line of no kind), a sentence in the game's gold is taken for
-- one: PROSE_WORDS words or more, nothing at the right.
local function Words(text)
    local count, at = 0, 1
    while true do
        local _, stop = text:find("%S+", at)
        if not stop then return count end
        count, at = count + 1, stop + 1
    end
end
function Read.IsProse(line)
    local kind = line.type
    if kind == DESCRIPTION then return true end
    if kind ~= nil and kind ~= UNTYPED then return false end
    return line.right == "" and Family(line.lr, line.lg, line.lb) == "gold" and Words(line.left) >= PROSE_WORDS
end

-- For ctx.each: a description's numbers are drawn in the panel's colour (Panel.lua).
function Read.Prose(row, line)
    if Read.IsProse(line) then row.prose = true end
end

-- A creature's number: the sixth part of its GUID, Creature-0-1-2-3-<NPC>-4. Nil for a player,
-- a pet and anything else that is not a creature (or a vehicle).
function Read.NpcId(guid)
    if type(guid) ~= "string" then return nil end
    local kind, npc = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    return tonumber(npc)
end

-- The words over a comparison tooltip ("Equipped"). The game shows them on a tab above the tooltip.
local function Tag(tooltip)
    local header = tooltip.CompareHeader
    if not (header and header:IsShown() and header.Label) then return "" end
    return Plain(header.Label:GetText()) or TEXT.EQUIPPED
end

local function Mark(index, info)
    local line = ctx.L[index]
    line.type, line.data, line.own = Plain(info.type), info, true
    ctx.matched = true
    if index > ctx.lastOwn then ctx.lastOwn = index end
end

-- Reads the tooltip's lines into ctx.L and says which the game's data knows. False when a line
-- cannot be read.
local function Collect(tooltip, data)
    local count = Plain(tooltip:NumLines())
    if not count or count < 1 then return false end
    local L = ctx.L
    for index = 1, count do
        local line = L[index]
        if not line then
            line = {}
            L[index] = line
        end
        local left, lr, lg, lb = Side(tooltip:GetLeftLine(index))
        local right, rr, rg, rb = Side(tooltip:GetRightLine(index))
        if not (left and right) then return false end
        line.left, line.right = left, right
        line.lr, line.lg, line.lb, line.rr, line.rg, line.rb = lr, lg, lb, rr, rg, rb
        line.type, line.data, line.own, line.used = nil, nil, false, false
        line.blank = right == "" and not left:find("%S")
    end
    ctx.count, ctx.matched, ctx.lastOwn = count, false, 0

    local lines = data and Plain(data.lines)
    if type(lines) ~= "table" then lines = nil end
    ctx.lines = lines
    if not lines then return true end
    -- The data says where each of its lines stands... A line of it without text added nothing, yet
    -- the game gives it the index of the last line there (TooltipDataHandler): the first one wins.
    for look = 1, #lines do
        local info = Plain(lines[look])
        local index = type(info) == "table" and Plain(info.lineIndex)
        if type(index) == "number" and index >= 1 and index <= count and not L[index].own then Mark(index, info) end
    end
    if ctx.matched then return true end
    -- ...or it does not: then its lines are found by their text, in the tooltip's order.
    local nextLine = 1
    for index = 1, count do
        for look = nextLine, math.min(nextLine + LOOK_AHEAD - 1, #lines) do
            local info = Plain(lines[look])
            if type(info) == "table" and Plain(info.leftText) == L[index].left then
                Mark(index, info)
                nextLine = look + 1
                break
            end
        end
    end
    return true
end

-------------------------------------------------------------------------------
--  The tools of the readers
-------------------------------------------------------------------------------
-- The next row. It takes the divider that is waiting, unless it is the panel's first row.
function Read.Row()
    local row = Model.Row(ctx.fill)
    if ctx.rule then
        row.rule = ctx.fill.n > 1 or nil
        ctx.rule = false
    end
    return row
end

-- A row from one of the tooltip's lines, in its own colours.
function Read.Line(line, font)
    local row = Read.Row()
    row.font = font or "row"
    row.left, row.right = line.left, line.right
    row.lr, row.lg, row.lb = Ease(line.lr, line.lg, line.lb)
    row.rr, row.rg, row.rb = Ease(line.rr, line.rg, line.rb)
    line.used = true
    return row
end

-- A row of our own words.
function Read.Text(font, left, r, g, b)
    local row = Read.Row()
    row.font, row.left = font, left
    row.lr, row.lg, row.lb = r, g, b
    row.rr, row.rg, row.rb = r, g, b
    return row
end

-- The panel's first row: the tooltip's first line.
function Read.Title(caps)
    local line = ctx.L[1]
    local row = Read.Row()
    row.font, row.left, row.caps = "title", line.left, caps or nil
    row.lr, row.lg, row.lb = Ease(line.lr, line.lg, line.lb, true)
    line.used = true
    return row
end

-- A section's caption: its name in small capitals and a rule after it, which set it off from what is
-- above (no divider over it).
function Read.Caption(text)
    ctx.rule = false
    local row = Read.Row()
    row.kind, row.left = "caption", text
    return row
end

-- A fact in a strip row: its caption over its value (Model.lua).
function Read.Cell(row, caption, value)
    row[#row + 1] = caption
    row[#row + 1] = value
end

-- The panel's colour.
function Read.Accent(r, g, b)
    local head = ctx.head
    head.accent, head.ar, head.ag, head.ab = true, r, g, b
end

-- Without a colour of its own a panel takes its first line's, unless that is plain white or
-- hidden: then the panel is grey.
function Read.AccentFromTitle()
    local line = ctx.L[1]
    local r, g, b = line.lr, line.lg, line.lb
    if r and g and b and not Like(r, g, b, COLOR.WHITE) then Read.Accent(r, g, b) end
end

-- A text put together from parts ("Axe  ·  Two-Hand"), kept until a part changes: the same
-- tooltip is read again and again, and its words are not built anew every time.
function Read.Memo(key, format, a, b, c)
    local memos = ctx.model.memos
    if not memos then
        memos = {}
        ctx.model.memos = memos
    end
    local memo = memos[key]
    if not memo then
        memo = {}
        memos[key] = memo
    end
    if memo.format ~= format or memo.a ~= a or memo.b ~= b or memo.c ~= c then
        memo.format, memo.a, memo.b, memo.c = format, a, b, c
        memo.text = format:format(a, b, c)
    end
    return memo.text
end

-- Whether a line is one another addon added (after the game's own).
local function Added(line, index)
    return ctx.matched and not line.own and index > ctx.lastOwn
end
Read.Added = Added

-- Every line of the game's no reader has shown yet, as rows: an empty line is a divider. Other
-- addons' lines are not among them: they get a section of their own at the panel's end (Others).
function Read.Rest()
    local L = ctx.L
    local lastFamily, caption = nil, false
    for index = 2, ctx.count do
        local line = L[index]
        local kind = line.type
        if line.used or IsFeedback(line.left) or Read.IsIdLine(line) or Added(line, index) then
            -- nothing
        elseif ctx.nested and kind == NESTED then
            caption = true
        elseif line.blank or kind == BLANK or kind == SEPARATOR then
            ctx.rule = true
        else
            if ctx.tones then
                local family = Family(line.lr, line.lg, line.lb)
                if lastFamily and family ~= lastFamily then ctx.rule = true end
                lastFamily = family
            end
            if caption then
                -- The thing inside the thing: a caption, then its name like a second title.
                Read.Caption(ctx.nested)
            end
            local row = Read.Line(line, "row")
            if caption then
                row.font, row.caps, row.icon = "title", true, ctx.nestedIcon or nil
                caption, lastFamily = false, nil
            end
            if ctx.each then ctx.each(row, line, index) end
        end
    end
end

-- The lines other addons added to the tooltip, all of them, in a section of their own at the end of
-- every panel, under the caption Other addons: small and quiet, as they stand, in their order; an empty
-- line among them is a divider (it parts one addon's lines from the next one's). Nothing when there are
-- none. Their ID lines are left out (Alt shows the numbers, Details).
local function Others()
    local L, captioned = ctx.L, false
    for index = 2, ctx.count do
        local line = L[index]
        if not line.used and Added(line, index) and not IsFeedback(line.left) and not Read.IsIdLine(line) then
            local kind = line.type
            if line.blank or kind == BLANK or kind == SEPARATOR then
                if captioned then ctx.rule = true end
            else
                if not captioned then
                    captioned = true
                    Read.Caption(TEXT.ADDONS)
                end
                local row = Read.Line(line, "small")
                row.lr, row.lg, row.lb, row.rr, row.rg, row.rb = ASIDE[1], ASIDE[2], ASIDE[3], ASIDE[1], ASIDE[2], ASIDE[3]
            end
        end
    end
end

-- A name and its lines: every kind of tooltip no file in Kinds knows (a mailbox, a herb, a button's
-- hint). Its panel has no colour of its own (Panel.lua: COLOR.NEUTRAL), whatever colour its name has.
function Read.Generic()
    Read.Title(ctx.data ~= nil) -- a name in capitals; a hint somebody wrote stays as written
    local rank = ctx.L[1].right
    if rank ~= "" then Read.Text("sub", rank, DETAIL[1], DETAIL[2], DETAIL[3]) end
    ctx.rule = true
    Read.Rest()
end

-------------------------------------------------------------------------------
--  With Alt held: the technical details, small, in a section of their own at
--  the bottom: the number of the thing at the left, of its icon at the right.
-------------------------------------------------------------------------------
local TYPE = Enum.TooltipDataType or {}
local KIND_NAMES = {} -- [the game's kind of tooltip data] = its name: "Item", "Quest", ...
for name, value in pairs(TYPE) do KIND_NAMES[value] = name end
local SPELLS = { [TYPE.Spell or -1] = true, [TYPE.UnitAura or -1] = true, [TYPE.PetAction or -1] = true }
local ITEMS = { [TYPE.Item or -1] = true, [TYPE.Toy or -1] = true }

local function Details()
    local data, id, kind = ctx.data, ctx.id, ctx.kind
    if not (data and kind) then return end
    local left, right = "", ""
    if kind == TYPE.Unit or kind == TYPE.Corpse then
        local guid = Plain(data.guid)
        if type(guid) == "string" then
            local npc = Read.NpcId(guid)
            left = npc and Read.Memo("detailLeft", TEXT.ID, TEXT.NPC, npc) or Read.Memo("detailLeft", TEXT.GUID, guid)
        end
    elseif id then
        left = Read.Memo("detailLeft", TEXT.ID, SPELLS[kind] and TEXT.SPELL or KIND_NAMES[kind] or "?", id)
        local icon = (SPELLS[kind] and Plain(C_Spell.GetSpellTexture(id))) or (ITEMS[kind] and Plain(C_Item.GetItemIconByID(id)))
        if icon then right = Read.Memo("detailRight", TEXT.ID, TEXT.ICON, icon) end
    end
    if left == "" and right == "" then return end
    ctx.rule = true
    local row = Read.Text("small", left, ASIDE[1], ASIDE[2], ASIDE[3])
    row.right = right
end

local broken = {} -- [a kind's reader] = true: it failed; its tooltips are the game's own from then on

-- Fills model from the tooltip. Returns false when the tooltip cannot be read (the game hides a
-- line, it is empty, or the reader of its kind failed); otherwise true and whether what the panel
-- shows has changed.
function ns.Read(tooltip, data, model, options)
    model.priced = false
    data = Plain(data)
    if type(data) ~= "table" then data = nil end
    if not Collect(tooltip, data) then return false end
    ctx.tooltip, ctx.data, ctx.options, ctx.model = tooltip, data, options, model
    ctx.kind, ctx.id = data and Plain(data.type), data and Plain(data.id)
    ctx.fill = Model.Begin(model)
    ctx.head = ctx.fill.head
    ctx.rule, ctx.tones, ctx.each, ctx.nested, ctx.nestedIcon = false, false, nil, nil, nil
    ctx.head.tag = Tag(tooltip)
    ctx.head.compared = ctx.head.tag ~= "" or nil -- what you wear, beside what you look at
    local kind = ctx.kind ~= nil and ns.KINDS[ctx.kind] or Read.Generic
    if broken[kind] then return false end
    -- A client update that breaks one reader (a renamed function of the game's) costs that kind
    -- only: the problem is noted and told once, and the other kinds are still drawn.
    local ok, problem = xpcall(kind, Core.Trace, ctx)
    if not ok then
        broken[kind] = true
        ns.Report(("%s tooltips are the game's own"):format(kind ~= Read.Generic and KIND_NAMES[ctx.kind] or "Other"), problem)
        return false
    end
    if IsAltKeyDown() then Details() end
    -- Last, apart from everything of the panel's own: other addons' lines
    Others()
    return true, Model.Commit(model)
end
