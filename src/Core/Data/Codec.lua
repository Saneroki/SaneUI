local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Codec
--  A row of a data set into a record, and a record Core learned in play back into one (Doc/guides/data.md,
--  *A row*, *Learned*). A row is one string: its build, its
--  day, then the fields in the order the set's header names them, a tab between them; inside a field,
--  character 30 between a list's or map's elements and character 31 between an element's parts. Game text
--  holds none of these, so a row is taken apart with plain finds and nothing is escaped. An empty part is
--  no value. A row of only a build and a day is a gone version.
--
--  The same codec will read saved rows and shared blocks; it never runs what it reads.
-------------------------------------------------------------------------------
local Data = {}
Core.Data = Data
local Codec = {}
Data.Codec = Codec

local TAB, LIST, PART, VERSION = "\t", "\030", "\031", "\028"
local find, sub, match = string.find, string.sub, string.match

-- The parts of text cut by a one-character separator, empty ones included: a new array.
local function Cut(text, separator)
    local parts, start = {}, 1
    while true do
        local stop = find(text, separator, start, true)
        parts[#parts + 1] = sub(text, start, (stop or 0) - 1)
        if not stop then return parts end
        start = stop + 1
    end
end
Codec.Cut = Cut

local function Text(part) return part end
local function Bool(part) return part == "1" or nil end

local function Point(part)
    local map, x, y = match(part, "^([^\031]*)\031([^\031]*)\031([^\031]*)$")
    if not map then return nil end
    return { map = tonumber(map), x = tonumber(x), y = tonumber(y) }
end

local SCALARS = { int = tonumber, number = tonumber, text = Text, bool = Bool, point = Point }

-- tuple(kind:text,what:int,...): a table by the parts' names.
local function Tuple(spec)
    local names, decoders = {}, {}
    for name, kind in spec:gmatch("([%w_]+):([%w_]+)") do
        local decode = SCALARS[kind]
        if not decode or kind == "point" then error("a tuple's part of type " .. kind) end
        names[#names + 1], decoders[#decoders + 1] = name, decode
    end
    if #names == 0 then error("a tuple without parts: " .. spec) end
    return function(part)
        local parts, value = Cut(part, PART), {}
        for index, name in ipairs(names) do
            local piece = parts[index]
            if piece and piece ~= "" then value[name] = decoders[index](piece) end
        end
        return value
    end
end

local function Element(spec)
    local tuple = match(spec, "^tuple%((.*)%)$")
    if tuple then return Tuple(tuple) end
    local decode = SCALARS[spec]
    if not decode then error("no such type: " .. tostring(spec)) end
    return decode
end

-- The function that reads one field's part (never an empty one), from its type in the set's header:
-- int, number, text, bool, point, tuple(...), list <element>, map <int|text> <element>.
local function Field(spec)
    local of = match(spec, "^list (.+)$")
    if of then
        local decode = Element(of)
        -- Each element at its own place: an empty one is no value, a hole, and those after it keep theirs.
        return function(part)
            local items, list = Cut(part, LIST), {}
            for index, item in ipairs(items) do
                if item ~= "" then list[index] = decode(item) end
            end
            return list
        end
    end
    local keys, element = match(spec, "^map (%a+) (.+)$")
    if keys then
        if keys ~= "int" and keys ~= "text" then error("a map's keys are int or text, not " .. keys) end
        local decode, number = Element(element), keys == "int"
        return function(part)
            local map = {}
            for _, item in ipairs(Cut(part, LIST)) do
                local stop = find(item, PART, 1, true)
                local value = stop and sub(item, stop + 1)
                if value and value ~= "" then
                    local key = sub(item, 1, stop - 1)
                    -- a whole number only: tonumber also reads "nan" (no table key at all), "inf", "0x10"
                    if number then key = match(key, "^%-?%d+$") and tonumber(key) end
                    if key then map[key] = decode(value) end
                end
            end
            return map
        end
    end
    return Element(spec)
end

-- A decoder for the rows of a set: decode(row) gives a record, field = value, with since and day; a gone
-- version gives { since, day, gone = true }. Errors on a type it does not know (the set is refused then).
function Codec.Decoder(fields, types)
    assert(type(fields) == "table" and type(types) == "table" and #fields == #types, "fields and types do not match")
    local decoders = {}
    for index, spec in ipairs(types) do decoders[index] = Field(spec) end
    return function(row)
        local record, start, column, length = {}, 1, 0, #row
        while true do
            local stop = find(row, TAB, start, true)
            local part = sub(row, start, (stop or length + 1) - 1)
            if column == 0 then
                record.since = tonumber(part)
            elseif column == 1 then
                if part ~= "" then record.day = tonumber(part) end
            elseif part ~= "" then
                local decode = decoders[column - 1]
                if decode then record[fields[column - 1]] = decode(part) end
            end
            if not stop then break end
            start, column = stop + 1, column + 1
        end
        if column <= 1 then record.gone = true end
        return record
    end
end

-------------------------------------------------------------------------------
--  A record into a row: what Core learns in play (Data.Learn), in the set's own format
-------------------------------------------------------------------------------
local format, concat, maxn = string.format, table.concat, table.maxn

-- A number as the compiler writes it: a whole one as it is, any other as %.14g.
local function Number(value)
    if type(value) ~= "number" or value ~= value then error("no number: " .. tostring(value)) end
    if value == math.floor(value) and math.abs(value) < 2 ^ 53 then return format("%.0f", value) end
    return format("%.14g", value)
end

-- Text holds none of the row's separators (game text never does).
local function Clean(value)
    if type(value) ~= "string" or find(value, "[\t\028\030\031]") then
        error("no text for a row: " .. tostring(value))
    end
    return value
end

local function Spot(value)
    return Number(value.map) .. PART .. Number(value.x) .. PART .. Number(value.y)
end

local ENCODERS = { int = Number, number = Number, text = Clean, point = Spot,
                   bool = function(value) return value and "1" or "" end }

-- Parts joined by a separator, the empty ones at the end left out.
local function Joined(parts, separator)
    local last = #parts
    while last > 0 and parts[last] == "" do last = last - 1 end
    return concat(parts, separator, 1, last)
end

local function ElementEncoder(spec)
    local tuple = match(spec, "^tuple%((.*)%)$")
    if not tuple then
        local encode = ENCODERS[spec]
        if not encode then error("no such type: " .. tostring(spec)) end
        return encode
    end
    local names, encoders = {}, {}
    for name, kind in tuple:gmatch("([%w_]+):([%w_]+)") do
        names[#names + 1], encoders[#encoders + 1] = name, ENCODERS[kind]
    end
    return function(value)
        local parts = {}
        for index, name in ipairs(names) do
            local part = value[name]
            parts[index] = part == nil and "" or encoders[index](part)
        end
        return Joined(parts, PART)
    end
end

-- The function that writes one field's value as its part of a row (nil: an empty part), from its type in the set's
-- header: the decoder's (Field) turned round. A list keeps its holes; a map is written in the order of its keys.
local function FieldEncoder(spec)
    local of = match(spec, "^list (.+)$")
    if of then
        local encode = ElementEncoder(of)
        return function(list)
            local parts = {}
            for index = 1, maxn(list) do parts[index] = list[index] == nil and "" or encode(list[index]) end
            return concat(parts, LIST)
        end
    end
    local keys, element = match(spec, "^map (%a+) (.+)$")
    if keys then
        local encode = ElementEncoder(element)
        return function(map)
            local order = {}
            for key in pairs(map) do order[#order + 1] = key end
            table.sort(order)
            local parts = {}
            for index, key in ipairs(order) do
                parts[index] = (keys == "int" and Number(key) or Clean(key)) .. PART .. encode(map[key])
            end
            return concat(parts, LIST)
        end
    end
    return ElementEncoder(spec)
end

-- An encoder for the rows of a set: encode(record) gives the fields' part of its row, each behind a tab, those empty
-- at the end left out (the row is its build and day, then this), so that Decoder reads the same record back. Errors on
-- a value it cannot write (text with a separator, no number where one belongs) or a type it does not know.
function Codec.Encoder(fields, types)
    assert(type(fields) == "table" and type(types) == "table" and #fields == #types, "fields and types do not match")
    local encoders = {}
    for index, spec in ipairs(types) do encoders[index] = FieldEncoder(spec) end
    return function(record)
        local parts = {}
        for index, name in ipairs(fields) do
            local value = record[name]
            parts[index] = value == nil and "" or encoders[index](value)
        end
        local text = Joined(parts, TAB)
        return text == "" and "" or TAB .. text
    end
end

-- The build a row starts at, without taking it apart; nil for one that is no text.
function Codec.Build(row)
    if type(row) ~= "string" then return nil end
    return tonumber(match(row, "^(%d+)"))
end

-- An entry's older versions (a set's history string), oldest first; none for one that is no text.
function Codec.Versions(history)
    if type(history) ~= "string" then return {} end
    return Cut(history, VERSION)
end
