local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Exchange
--  Sketches shared with the players of a dungeon map addon Sane UI knows (Saneroki, 2026-11-16: "Yes, build it";
--  "it would be nice to make the map sharing as compatible as possible were we can from out side"), both ways, in
--  that addon's own way of sharing, whose words Core gives (Core.Neighbours.Sketches): nothing of the addon is
--  called, read or changed, and all of it works the same whether it is installed or not.
--
--      heard   its drawings shared on its own addon messages (in a group, a guild, a whisper): put together, read
--              and asked about as a sketch of ours is (Markers' card: Keep or No), kept as a sketch of its own
--      pasted  its share strings (one drawing, or a backup of all of a player's) pasted in the Sketches menu
--              (DrawBar.lua): kept at once, each drawing a sketch of its own; pasted again, the copy replaced
--      sent    a sketch shared (Plans.Share) and markers shared (Markers.Send) go in its format too, on the same
--              channel: one of its drawings per dungeon and one for the game's maps; its players get them as its
--              own shares, and Sane UI's leave that copy for ours (a field of ours, Exchange.MARK, says ours came)
--
--      Exchange.on                     whether it works here (Forever: that addon's game; Core knows its words)
--      Exchange.Pack(kind, value)      a share string of its kind; Exchange.Unpack(text): value, kind, sum, or nil
--                                      and why ("format", "damaged")
--      Exchange.Share(route, sender, origin)   one of its drawings as a share of ours (Plans.Keep, Markers.Offer):
--                                      { sender, plan, rows, drawings, left (what has no map of ours), via }
--      Exchange.Routes(name, markers, drawings, origin)   ours as its drawings, as they travel: { payload, ... }
--      Exchange.Paste(text)            a share string pasted: the plans kept and how much was left out, or nil, why
--      Exchange.Send(name, markers, drawings, channel, target, origin)   ours sent in its format: how many went
--      Exchange.Heard(sender, text)    a message on its prefix (Core.Wire.Hear)
--
--  Where it lies: its dungeon maps are our floors as Core's words say (the same 0 to 1, or fitted), its drawings on
--  the game's maps ours as they are (both keep a map's ID and 0 to 1 on it). Its drawings on maps we have no match
--  for are left out, and the card says how many. Its eight colours and three widths are ours one to one, its words'
--  sizes our three, its marks our markers' icons (Saneroki, 2026-11-16: "expand to 8 colours and 3 lines and other
--  stuff so we are as compatible as possible"); what we have and it lacks (a marker's words, a line, an arrow, a
--  circle) goes as the nearest it has, what it has and we lack (a stamp's own colour) is dropped.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Exchange = {}
ns.Exchange = Exchange

local neighbours = Core.Neighbours
local words = neighbours and neighbours.Sketches and neighbours.Sketches("dungeonMaps")
Exchange.on = words ~= nil and Core.FOREVER == true
Exchange.words = words
Exchange.MARK = "sane"     -- our own field in a drawing we send: a Sane UI share of it came too
Exchange.MOST_PARTS = 100  -- parts of one drawing sent at most (its players keep a share's parts two minutes; ours go
                           -- one a second once the first ten went)
Exchange.GATHERING = 20    -- shares being put together at once at most
Exchange.HEAD = 0.05       -- an arrow's head, a share of the map's height at most
Exchange.SIDES = 32        -- a circle's sides
Exchange.LABEL = 0.035     -- a stop's words under it, a share of the map's height
Exchange.TEXT = {
    unnamed = "Shared drawing",
    markers = "Markers",
    alsoSent = "Also sent for those who use %s.",
    kept = "Kept from %s: %s.",
    left = "%d of its drawings lie on maps Sane UI has no match for and were left out.",
    nothing = "Nothing in it lies on a map Sane UI has.",
    format = "That is no drawing copied from %s: copy it with its Export or Backup and paste it whole.",
    damaged = "That text is cut short or damaged: copy it again and paste it whole.",
}
if not Exchange.on then return end

local tags, fields, saved, limits = words.tags, words.fields, words.saved, words.limits
local STROKE, MARK = {}, {} -- the place of each of a stroke's and a mark's fields in its list
for index, name in ipairs(words.stroke) do STROKE[name] = index end
for index, name in ipairs(words.mark) do MARK[name] = index end
local DEFLATE = Enum and Enum.CompressionMethod and Enum.CompressionMethod.Deflate or 0

-------------------------------------------------------------------------------
--  The share string
-------------------------------------------------------------------------------
local function Number(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- A value written as text, onto out.
local function Write(value, out, depth)
    local kind = type(value)
    if kind == "string" then
        out[#out + 1] = tags.text .. #value .. tags.long .. value
    elseif kind == "number" then
        if not Number(value) then value = 0 end
        if value % 1 == 0 and math.abs(value) < 1e15 then
            out[#out + 1] = tags.whole .. ("%d"):format(value) .. tags.stop
        else
            out[#out + 1] = tags.number .. ("%.6g"):format(value) .. tags.stop
        end
    elseif kind == "boolean" then
        out[#out + 1] = value and tags.yes or tags.no
    elseif kind == "table" and depth < words.deepest then
        out[#out + 1] = tags.open
        local count = 0
        while value[count + 1] ~= nil do
            count = count + 1
            Write(value[count], out, depth + 1)
        end
        out[#out + 1] = tags.split
        for key, each in pairs(value) do
            local listed = type(key) == "number" and key >= 1 and key <= count and key % 1 == 0
            local plain = type(each) ~= "function" and type(each) ~= "userdata" and type(each) ~= "thread"
            if not listed and plain and (type(key) == "string" or Number(key)) then
                Write(key, out, depth + 1)
                Write(each, out, depth + 1)
            end
        end
        out[#out + 1] = tags.close
    else
        out[#out + 1] = tags.no
    end
end

-- A value read from text at at: the value and where the next begins. Errors on text off its shape (Unpack catches).
local function Read(text, at, depth)
    local tag = text:sub(at, at)
    if tag == tags.text then
        local long = text:find(tags.long, at + 1, true)
        local length = long and tonumber(text:sub(at + 1, long - 1))
        if not length or length < 0 or length % 1 ~= 0 or long + length > #text then error("text") end
        return text:sub(long + 1, long + length), long + length + 1
    elseif tag == tags.whole or tag == tags.number then
        local stop = text:find(tags.stop, at + 1, true)
        local value = stop and tonumber(text:sub(at + 1, stop - 1))
        if not Number(value) then error("number") end
        return value, stop + 1
    elseif tag == tags.yes then
        return true, at + 1
    elseif tag == tags.no then
        return false, at + 1
    elseif tag == tags.open then
        if depth >= words.deepest then error("deep") end
        local list, value, key = {}, nil, nil
        at = at + 1
        while text:sub(at, at) ~= tags.split do
            if at > #text then error("short") end
            value, at = Read(text, at, depth + 1)
            list[#list + 1] = value
        end
        at = at + 1
        while text:sub(at, at) ~= tags.close do
            if at > #text then error("short") end
            key, at = Read(text, at, depth + 1)
            value, at = Read(text, at, depth + 1)
            if type(key) == "string" or type(key) == "number" then list[key] = value end
        end
        return list, at + 1
    end
    error("tag")
end

-- Bytes as its letters (six bits each, the last group short: no padding), and back; nil for a letter not its.
local LETTERS = words.letters
local VALUE = {}
for index = 1, #LETTERS do VALUE[LETTERS:byte(index)] = index - 1 end

local function ToLetters(bytes)
    local out = {}
    for at = 1, #bytes, 3 do
        local a, b, c = bytes:byte(at, at + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        for place = 1, c and 4 or b and 3 or 2 do
            local digit = math.floor(n / 64 ^ (4 - place)) % 64
            out[#out + 1] = LETTERS:sub(digit + 1, digit + 1)
        end
    end
    return table.concat(out)
end

local function FromLetters(text)
    local out = {}
    for at = 1, #text, 4 do
        local group = text:sub(at, at + 3)
        if #group < 2 then return nil end
        local n = 0
        for place = 1, 4 do
            local digit = 0
            if place <= #group then
                digit = VALUE[group:byte(place)]
                if not digit then return nil end
            end
            n = n * 64 + digit
        end
        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        if #group >= 3 then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
        if #group >= 4 then out[#out + 1] = string.char(n % 256) end
    end
    return table.concat(out)
end

-- The sum of a string's body: its two rolling sums, five hexadecimal digits each.
local function Sum(body)
    local one, two = words.sums[1], words.sums[2]
    local a, b = one[1], two[1]
    for at = 1, #body do
        local byte = body:byte(at)
        a = (a * one[2] + byte) % one[3]
        b = (b * two[2] + byte * at) % two[3]
    end
    return ("%05x%05x"):format(a, b)
end

function Exchange.Pack(kind, value)
    local out = {}
    Write(value, out, 0)
    local raw, packing = table.concat(out), words.plain
    local util = rawget(_G, "C_EncodingUtil")
    local packed = util and Core.Ask(util.CompressString, raw, DEFLATE)
    if type(packed) == "string" and #packed < #raw then raw, packing = packed, words.packed end
    local body = ToLetters(raw)
    return table.concat({ words.head, kind, packing, Sum(body), body }, ".")
end

Exchange.LONGEST = 400000   -- letters of a string read at most
Exchange.UNPACKED = 2000000 -- bytes it may unpack to at most

function Exchange.Unpack(text)
    if type(text) ~= "string" or #text > Exchange.LONGEST then return nil, "format" end
    text = text:gsub("%s+", "")
    local head, kind, packing, sum, body = text:match("^(%w+)%.(%w+)%.(%a)%.(%x+)%.([%w%-_]+)$")
    if head ~= words.head then return nil, "format" end
    if Sum(body) ~= sum:lower() then return nil, "damaged" end
    local raw = FromLetters(body)
    if not raw then return nil, "damaged" end
    if packing == words.packed then
        local util = rawget(_G, "C_EncodingUtil")
        raw = util and Core.Ask(util.DecompressString, raw, DEFLATE)
        if type(raw) ~= "string" or #raw > Exchange.UNPACKED then return nil, "damaged" end
    elseif packing ~= words.plain then
        return nil, "format"
    end
    local ok, value, stop = pcall(Read, raw, 1, 0)
    if not ok or stop ~= #raw + 1 then return nil, "damaged" end
    return value, kind, sum
end

-------------------------------------------------------------------------------
--  Its drawings in their plain form: { name, scope, key, colour, author, id, stops = { { map, x, y, label } },
--  strokes = { { map, width, colour, points } }, marks = { { map, x, y, kind, colour, label } } }, 0 to 1
-------------------------------------------------------------------------------
-- Words as a label: no escapes of the game's (|) nor control signs, trimmed, cut; nil when nothing is left.
local function Label(text, most)
    if type(text) ~= "string" then return nil end
    text = text:gsub("[|%c]", ""):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    return text:sub(1, most)
end

local function Clamp(value) return math.max(0, math.min(1, value)) end

local function Scope(scope) return (scope == words.chart or scope == words.world) and scope or nil end

-- One of its drawings as it travels.
local function FromWire(data)
    if type(data) ~= "table" then return nil end
    local known = false
    for _, version in ipairs(words.versions) do known = known or data[fields.version] == version end
    local stops = data[fields.stops]
    if not known or not Scope(data[fields.scope]) or type(stops) ~= "table" or #stops % 3 ~= 0 then return nil end
    local route = { name = Label(data[fields.name], limits.name), scope = data[fields.scope],
                    key = type(data[fields.key]) == "string" and data[fields.key] or nil, colour = data[fields.colour],
                    author = Label(data[fields.author], limits.author), stops = {}, strokes = {}, marks = {} }
    local function Place(value) return Clamp(value / words.scale) end
    local labels = type(data[fields.labels]) == "table" and data[fields.labels] or {}
    for at = 1, math.min(#stops, limits.stops * 3), 3 do
        local map, x, y = stops[at], stops[at + 1], stops[at + 2]
        if not (Number(map) and Number(x) and Number(y)) then return nil end
        route.stops[#route.stops + 1] = { map = map, x = Place(x), y = Place(y),
                                          label = Label(labels[(at + 2) / 3], limits.label) }
    end
    for _, stroke in ipairs(type(data[fields.strokes]) == "table" and data[fields.strokes] or {}) do
        if #route.strokes >= limits.strokes then break end
        local points = type(stroke) == "table" and stroke[STROKE.points]
        if type(points) == "table" and Number(stroke[STROKE.map]) and #points >= 4 and #points % 2 == 0
                and #points <= limits.points * 2 then
            local list = {}
            for index, value in ipairs(points) do
                if not Number(value) then list = nil break end
                list[index] = Place(value)
            end
            if list then
                route.strokes[#route.strokes + 1] = { map = stroke[STROKE.map], points = list,
                    width = Number(stroke[STROKE.width]) and stroke[STROKE.width] or words.widths[1],
                    colour = stroke[STROKE.colour] }
            end
        end
    end
    for _, mark in ipairs(type(data[fields.marks]) == "table" and data[fields.marks] or {}) do
        if #route.marks >= limits.marks then break end
        if type(mark) == "table" and Number(mark[MARK.map]) and Number(mark[MARK.x]) and Number(mark[MARK.y])
                and type(mark[MARK.kind]) == "string" then
            route.marks[#route.marks + 1] = { map = mark[MARK.map], x = Place(mark[MARK.x]), y = Place(mark[MARK.y]),
                kind = mark[MARK.kind], colour = mark[MARK.colour], label = Label(mark[MARK.label], limits.label),
                size = mark[MARK.size] }
        end
    end
    return route
end

-- One of its drawings as a player of it keeps it (a backup).
local function FromSaved(each)
    if type(each) ~= "table" or not Scope(each[saved.scope]) then return nil end
    local route = { name = Label(each[saved.name], limits.name), scope = each[saved.scope],
                    key = type(each[saved.key]) == "string" and each[saved.key] or nil, colour = each[saved.colour],
                    author = Label(each[saved.author], limits.author), id = each[saved.id], stops = {}, strokes = {},
                    marks = {} }
    local function Lists(name) return type(each[name]) == "table" and each[name] or {} end
    for _, stop in ipairs(Lists(saved.stops)) do
        if #route.stops >= limits.stops then break end
        if type(stop) == "table" and Number(stop[saved.map]) and Number(stop[saved.x]) and Number(stop[saved.y]) then
            route.stops[#route.stops + 1] = { map = stop[saved.map], x = Clamp(stop[saved.x]), y = Clamp(stop[saved.y]),
                                              label = Label(stop[saved.label], limits.label) }
        end
    end
    for _, stroke in ipairs(Lists(saved.strokes)) do
        if #route.strokes >= limits.strokes then break end
        local points = type(stroke) == "table" and stroke[saved.points]
        if type(points) == "table" and Number(stroke[saved.map]) and #points >= 4 and #points % 2 == 0 then
            local list = {}
            for index, value in ipairs(points) do
                if not Number(value) then list = nil break end
                list[index] = Clamp(value)
            end
            if list then
                route.strokes[#route.strokes + 1] = { map = stroke[saved.map], points = list, colour = stroke[saved.colourOf],
                    width = Number(stroke[saved.width]) and stroke[saved.width] or words.widths[1] }
            end
        end
    end
    for _, mark in ipairs(Lists(saved.marks)) do
        if #route.marks >= limits.marks then break end
        if type(mark) == "table" and Number(mark[saved.map]) and Number(mark[saved.x]) and Number(mark[saved.y])
                and type(mark[saved.kind]) == "string" then
            route.marks[#route.marks + 1] = { map = mark[saved.map], x = Clamp(mark[saved.x]), y = Clamp(mark[saved.y]),
                kind = mark[saved.kind], colour = mark[saved.colourOf], label = Label(mark[saved.label], limits.label),
                size = mark[saved.size] }
        end
    end
    return route
end

-------------------------------------------------------------------------------
--  Its drawings as ours
-------------------------------------------------------------------------------
-- The entry of a list whose colour lies nearest rgb.
local function Nearest(rgb, list, colourOf)
    local best, far
    for index, entry in ipairs(list) do
        local other = colourOf(entry)
        local distance = (other[1] - rgb[1]) ^ 2 + (other[2] - rgb[2]) ^ 2 + (other[3] - rgb[3]) ^ 2
        if not far or distance < far then best, far = index, distance end
    end
    return best
end

-- Our colour of its colour of that number (the drawing's own where it has none): the one it is (words.colourKeys),
-- else the nearest.
local function ColourIn(route, number)
    local index = words.colours[number] and number or words.colours[route.colour] and route.colour or 1
    local key = words.colourKeys[index]
    for _, colour in ipairs(ns.Plans.COLOURS) do
        if colour.key == key then return key end
    end
    return ns.Plans.COLOURS[Nearest(words.colours[index], ns.Plans.COLOURS, function(colour) return colour.rgb end)].key
end

-- Its colour's number of ours: the one it is, else the nearest.
local function ColourOut(key)
    for index, each in ipairs(words.colourKeys) do
        if each == key then return index end
    end
    return Nearest(ns.Plans.Colour(key), words.colours, function(rgb) return rgb end)
end

-- Our width of its width (the nearest of its three), and its words' size as our width.
local function WidthIn(width)
    local best, far = 1, nil
    for index, each in ipairs(words.widths) do
        local distance = math.abs(each - width)
        if not far or distance < far then best, far = index, distance end
    end
    return best
end

local function SizeIn(size)
    return words.textSizes[size] or words.textSizes[words.textSize] or 1
end

-- Where a point of its drawing lies on our maps: the map and the point; nil where we have no match for its map.
local function MapIn(route, map, x, y)
    if route.scope == words.chart then
        local chart = words.charts[map]
        if not chart then return nil end
        local fit = chart.fit
        if fit then x, y = fit[1] * x + fit[2] * y + fit[3], fit[4] * x + fit[5] * y + fit[6] end
        return chart.floor, x, y
    end
    if ns.Coords.Box(map) then return map, x, y end
    return nil
end

-- At most Plans.POINTS points of a list, spread evenly, its first and last among them.
local function Thin(points)
    local count, most = #points / 2, ns.Plans.POINTS
    if count <= most then return points end
    local kept = {}
    for index = 0, most - 1 do
        local from = math.floor(index * (count - 1) / (most - 1) + 0.5)
        kept[#kept + 1] = points[from * 2 + 1]
        kept[#kept + 1] = points[from * 2 + 2]
    end
    return kept
end

function Exchange.Share(route, sender, origin)
    local Plans, Markers = ns.Plans, ns.Markers
    local share = { sender = tostring(sender or route.author or "?"), rows = {}, drawings = {}, left = 0,
                    plan = { origin = origin, name = route.name or Exchange.TEXT.unnamed }, via = words.title }
    local function Drawing(kind, map, colour, width, points, text)
        if #share.drawings >= Plans.TAKE then
            share.left = share.left + 1
            return
        end
        local drawing = { origin = origin .. ":d" .. (#share.drawings + 1), map = map, kind = kind, colour = colour,
                          width = width, points = points, text = text }
        share.drawings[#share.drawings + 1] = drawing
        return drawing
    end
    for _, stroke in ipairs(route.strokes) do
        local map, points = nil, {}
        for at = 1, #stroke.points - 1, 2 do
            local onto, x, y = MapIn(route, stroke.map, stroke.points[at], stroke.points[at + 1])
            map = onto
            if not map then break end
            points[#points + 1], points[#points + 2] = x, y
        end
        if map then
            Drawing("pen", map, ColourIn(route, stroke.colour), WidthIn(stroke.width), Thin(points))
        else
            share.left = share.left + 1
        end
    end
    -- the stops: one route of ours per map they go along in turn, each stop's words under it
    local run, runMap, labels = nil, nil, {}
    local function Done()
        if run then Drawing("route", runMap, ColourIn(route, nil), 1, Thin(run)) end
        run = nil
    end
    for _, stop in ipairs(route.stops) do
        local map, x, y = MapIn(route, stop.map, stop.x, stop.y)
        if not map then
            share.left = share.left + 1
        else
            if not run or map ~= runMap then
                Done()
                run, runMap = {}, map
            end
            run[#run + 1], run[#run + 2] = x, y
            if stop.label then labels[#labels + 1] = { map, x, y + Exchange.LABEL, stop.label } end
        end
    end
    Done()
    for _, label in ipairs(labels) do
        local words_ = Drawing("text", label[1], ColourIn(route, nil), 1, { label[2], Clamp(label[3]) }, label[4])
        if words_ then words_.stop = true end -- (a stop's words: sent back as that stop's, Exchange.Routes)
    end
    for _, mark in ipairs(route.marks) do
        local map, x, y = MapIn(route, mark.map, mark.x, mark.y)
        if not map then
            share.left = share.left + 1
        elseif mark.kind == words.text then
            if mark.label then
                Drawing("text", map, words.colours[mark.colour] and ColourIn(route, mark.colour) or "white",
                    SizeIn(mark.size), { x, y }, mark.label)
            end
        elseif #share.rows >= Plans.MARKERS then
            share.left = share.left + 1
        else
            share.rows[#share.rows + 1] = { origin = origin .. ":m" .. (#share.rows + 1), map = map, x = Clamp(x),
                y = Clamp(y), icon = Markers.Icon(words.marks[mark.kind] or "unknown").key, title = mark.label or "",
                text = "" }
        end
    end
    return share
end

-------------------------------------------------------------------------------
--  Ours as its drawings
-------------------------------------------------------------------------------
-- A fit turned round: its map from ours.
local function Inverse(fit)
    local det = fit[1] * fit[5] - fit[2] * fit[4]
    if math.abs(det) < 1e-9 then return nil end
    local a, b, d, e = fit[5] / det, -fit[2] / det, -fit[4] / det, fit[1] / det
    return { a, b, -(a * fit[3] + b * fit[6]), d, e, -(d * fit[3] + e * fit[6]) }
end

local floors -- [our floor] = { chart, key, back (the fit turned round) }: its lowest chart of each floor
local function Floors()
    if floors then return floors end
    floors = {}
    for chart, entry in pairs(words.charts) do
        local known = floors[entry.floor]
        if not known or chart < known.chart then
            floors[entry.floor] = { chart = chart, key = entry.key, back = entry.fit and Inverse(entry.fit) or nil }
        end
    end
    return floors
end

local function Whole(value) return math.floor(Clamp(value) * words.scale + 0.5) end

-- How much wider than high a map of ours is (0 to 1 is no square): a floor's art, a zone's box.
local function Aspect(map)
    if type(map) == "number" then
        local box = ns.Coords.Box(map)
        if box and box.height > 0 then return box.width / box.height end
    end
    return 1002 / 668 -- (the game's map art)
end

function Exchange.Routes(name, markers, drawings, origin)
    local groups, order = {}, {}
    local author = Label(Core.Ask(rawget(_G, "UnitName"), "player"), limits.author) or "?"
    -- The drawing of its that a map of ours goes into, its map there and how a point gets there; nil: none.
    local function Into(map)
        local key, onto, back = false, map, nil
        if type(map) == "string" then
            local floor = Floors()[map]
            if not floor then return nil end
            key, onto, back = floor.key, floor.chart, floor.back
        elseif type(map) ~= "number" then
            return nil
        end
        local id = key or words.world
        local group = groups[id]
        if not group then
            group = { scope = key and words.chart or words.world, key = key or nil, stops = {}, labels = {}, strokes = {},
                      marks = {} }
            groups[id] = group
            order[#order + 1] = id
        end
        return group, onto, back
    end
    local function Out(back, x, y)
        if back then x, y = back[1] * x + back[2] * y + back[3], back[4] * x + back[5] * y + back[6] end
        return Whole(x), Whole(y)
    end
    -- The stop of the group right over words at x, y (its map's, as whole numbers): its number; nil where none is.
    local function StopOver(group, onto, x, y)
        local best, far
        local under = Exchange.LABEL * words.scale
        for at = 1, #group.stops - 2, 3 do
            local dx, dy = math.abs(group.stops[at + 1] - x), y - group.stops[at + 2]
            if group.stops[at] == onto and dx <= 2 and dy >= -2 and dy <= under + 2 and (not far or dx + dy < far) then
                best, far = (at + 2) / 3, dx + dy
            end
        end
        return best
    end
    local function Stroke(group, onto, back, width, colour, points)
        if #group.strokes >= limits.strokes or #points < 4 then return end
        local list = {}
        for at = 1, math.min(#points, limits.points * 2) - 1, 2 do
            list[#list + 1], list[#list + 2] = Out(back, points[at], points[at + 1])
        end
        local stroke = {}
        stroke[STROKE.map], stroke[STROKE.width], stroke[STROKE.colour], stroke[STROKE.points] = onto, width, colour, list
        group.strokes[#group.strokes + 1] = stroke
    end
    local function Mark(group, onto, back, x, y, kind, colour, label, size)
        if #group.marks >= limits.marks then return end
        local mark, mx, my = {}, Out(back, x, y)
        mark[MARK.map], mark[MARK.x], mark[MARK.y], mark[MARK.kind] = onto, mx, my, kind
        mark[MARK.colour], mark[MARK.label] = colour, Label(label, limits.label) or ""
        mark[MARK.size] = size or words.textSize
        group.marks[#group.marks + 1] = mark
    end
    for _, drawing in ipairs(drawings or {}) do
        local group, onto, back = Into(drawing.map)
        local points = drawing.points or {}
        if group and #points >= 2 then
            local colour = ColourOut(drawing.colour)
            local size = ns.Draw and ns.Draw.Widths(drawing.width) or 1
            local width = words.widths[size] or words.widths[1]
            local kind, x1, y1, x2, y2 = drawing.kind, points[1], points[2], points[3], points[4]
            if kind == "pen" or kind == "line" then
                Stroke(group, onto, back, width, colour, points)
            elseif kind == "arrow" and x2 then
                Stroke(group, onto, back, width, colour, { x1, y1, x2, y2 })
                local aspect = Aspect(drawing.map)
                local dx, dy = (x1 - x2) * aspect, y1 - y2
                local head = math.min(Exchange.HEAD, math.sqrt(dx * dx + dy * dy) / 3)
                local angle, spread = math.atan2(dy, dx), ns.Draw and ns.Draw.SPREAD or 0.45
                Stroke(group, onto, back, width, colour, {
                    x2 + head * math.cos(angle + spread) / aspect, y2 + head * math.sin(angle + spread), x2, y2,
                    x2 + head * math.cos(angle - spread) / aspect, y2 + head * math.sin(angle - spread) })
            elseif kind == "circle" and x2 then
                local aspect = Aspect(drawing.map)
                local radius = math.sqrt(((x2 - x1) * aspect) ^ 2 + (y2 - y1) ^ 2)
                local ring = {}
                for side = 0, Exchange.SIDES do
                    local angle = side * 2 * math.pi / Exchange.SIDES
                    ring[#ring + 1] = x1 + radius * math.cos(angle) / aspect
                    ring[#ring + 1] = y1 + radius * math.sin(angle)
                end
                Stroke(group, onto, back, width, colour, ring)
            elseif kind == "route" then
                group.colour = group.colour or colour -- (its stops are in its drawing's own colour)
                for at = 1, #points - 1, 2 do
                    if #group.stops >= limits.stops * 3 then break end
                    local x, y = Out(back, points[at], points[at + 1])
                    group.stops[#group.stops + 1], group.stops[#group.stops + 2], group.stops[#group.stops + 3] = onto, x, y
                end
            elseif kind == "text" and drawing.text then
                -- a stop's words (Exchange.Share): that stop's label again, if the stop over them is there
                local stop = drawing.stop and StopOver(group, onto, Out(back, x1, y1))
                if stop then
                    group.labels[stop] = Label(drawing.text, limits.label)
                else
                    Mark(group, onto, back, x1, y1, words.text, colour, drawing.text, words.ourTextSizes[size])
                end
            end
        end
    end
    for _, marker in ipairs(markers or {}) do
        local group, onto, back = Into(marker.map)
        if group and marker.x and marker.y then
            local title = (marker.title and marker.title ~= "") and marker.title or marker.text
            Mark(group, onto, back, marker.x, marker.y, words.icons[marker.icon] or words.unknown, 0, title)
        end
    end
    local list = {}
    for _, id in ipairs(order) do
        local group = groups[id]
        local payload = { [fields.version] = words.version, [fields.scope] = group.scope, [fields.key] = group.key,
                          [fields.name] = Label(name, limits.name) or Exchange.TEXT.unnamed,
                          [fields.colour] = group.colour or 1,
                          [fields.author] = author, [fields.stops] = group.stops, [fields.labels] = group.labels,
                          [fields.strokes] = group.strokes, [fields.marks] = group.marks,
                          [Exchange.MARK] = tostring(origin or "") }
        list[#list + 1] = payload
    end
    return list
end

-------------------------------------------------------------------------------
--  Pasted, sent, heard
-------------------------------------------------------------------------------
function Exchange.Paste(text)
    local data, kind, sum = Exchange.Unpack(text)
    if not data then return nil, kind end
    local routes = {}
    if kind == words.route then
        local route = FromWire(data)
        if route then routes[1] = { route = route, origin = "x:" .. sum } end
    elseif kind == words.backup then
        local list = type(data) == "table" and data[saved.routes]
        for id, each in pairs(type(list) == "table" and list or {}) do
            local route = FromSaved(each)
            if route then routes[#routes + 1] = { route = route, origin = "x:" .. tostring(route.id or id) } end
        end
        table.sort(routes, function(a, b) return (a.route.name or "") < (b.route.name or "") end)
    else
        return nil, "format"
    end
    if #routes == 0 then return nil, "format" end
    local kept, left = {}, 0
    for _, each in ipairs(routes) do
        local share = Exchange.Share(each.route, each.route.author, each.origin)
        left = left + share.left
        if #share.rows + #share.drawings > 0 then kept[#kept + 1] = ns.Plans.Keep(share) end
    end
    return kept, left
end

local serial = 0 -- shares sent since the login, the number each of its shares travels with

function Exchange.Send(name, markers, drawings, channel, target, origin)
    if ns.off or not channel then return 0 end
    local sent = 0
    for _, payload in ipairs(Exchange.Routes(name, markers, drawings, origin)) do
        local text = Exchange.Pack(words.route, payload)
        local parts = math.ceil(#text / words.piece)
        if parts <= math.min(words.most, Exchange.MOST_PARTS) then
            serial = serial % 4095 + 1
            local went = true
            for part = 1, parts do
                local message = table.concat({ words.share, ("%x"):format(serial), ("%x"):format(part),
                    ("%x"):format(parts), text:sub((part - 1) * words.piece + 1, part * words.piece) }, words.cut)
                went = went and Core.Wire.Say(words.prefix, message, channel, target)
            end
            if went then sent = sent + 1 end
        end
    end
    if sent > 0 then ns.Print(Exchange.TEXT.alsoSent:format(words.title)) end
    return sent
end

local CUT = words.cut:gsub("%p", "%%%0")
local MESSAGE = "^(%w+)" .. CUT .. "(%x+)" .. CUT .. "(%x+)" .. CUT .. "(%x+)" .. CUT .. "(.*)$"
local gathering, gathered = {}, 0 -- [sender \t number] = a share's parts heard: { parts, got, pieces, since }

function Exchange.Heard(sender, text)
    if ns.off or type(sender) ~= "string" or type(text) ~= "string" then return end
    local kind, number, part, parts, piece = text:match(MESSAGE)
    if kind ~= words.share then return end -- (its other messages: its quests and runs, not ours to read)
    part, parts = tonumber(part, 16), tonumber(parts, 16)
    if not part or not parts or parts < 1 or parts > words.most or part < 1 or part > parts then return end
    local now = Core.Ask(GetTime) or 0
    for key, held in pairs(gathering) do
        if now - held.since > words.hold then
            gathering[key] = nil
            gathered = gathered - 1
        end
    end
    local key = sender .. "\t" .. number
    local held = gathering[key]
    if not held or held.parts ~= parts then
        if not held then
            if gathered >= Exchange.GATHERING then return end
            gathered = gathered + 1
        end
        held = { parts = parts, got = 0, pieces = {}, since = now }
        gathering[key] = held
    end
    if not held.pieces[part] then
        held.pieces[part] = piece
        held.got = held.got + 1
    end
    if held.got < parts then return end
    gathering[key] = nil
    gathered = gathered - 1
    local data, what, sum = Exchange.Unpack(table.concat(held.pieces))
    if what ~= words.route or type(data) ~= "table" or data[Exchange.MARK] ~= nil then return end -- (ours came too)
    local route = FromWire(data)
    if not route then return end
    local share = Exchange.Share(route, sender, "x:" .. sender .. ":" .. sum)
    if #share.rows + #share.drawings > 0 then ns.Markers.Offer(share) end
end

if Core.Wire and Core.Wire.Hear then Core.Wire.Hear(words.prefix, ns.Guard(Exchange.Heard)) end
