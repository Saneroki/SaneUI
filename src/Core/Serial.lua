local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Serial
--  Plain values as one line of text and back, to copy out of the game and into
--  it again (a profile to share: Profiles.Export, Profiles.Import). Only what
--  saved settings hold: tables, strings, numbers, true and false. The text is
--  read by this file alone, letter by letter; nothing in it is ever run.
--
--      local text = Core.Serial.Write(value)     -- nil for a value it cannot write
--      local value, why = Core.Serial.Read(text) -- nil and why for a text it cannot read
--
--  The shape, ours: t true, f false, n and a number, s"..." a string (a byte
--  outside the plain letters, a space, a quote, a backslash and the bar as \ and
--  three digits: the game's edit boxes treat the bar as the start of a code, and
--  line breaks or spaces put in while copying are left out), and
--  {key=value,...} a table, its keys sorted so the same settings give the same
--  text.
-------------------------------------------------------------------------------
local Serial = {}
Core.Serial = Serial

Serial.DEPTH = 24       -- tables inside tables, at most
Serial.LENGTH = 1000000 -- letters of a text it reads, at most

local TEXT = {
    long = "the text is too long",
    deep = "it holds too many tables inside each other",
    broken = "the text is broken at letter %d",
    rest = "there is more after the end, at letter %d",
}

-------------------------------------------------------------------------------
--  Writing
-------------------------------------------------------------------------------
local function Escape(text)
    return (text:gsub('[%z\1-\32\34\92\124\127-\255]', function(char) return ("\\%03d"):format(char:byte()) end))
end

local function Number(value)
    if value ~= value or value == math.huge or value == -math.huge then return "n0" end
    if value == math.floor(value) and math.abs(value) < 2 ^ 53 then return ("n%d"):format(value) end
    return ("n%.17g"):format(value)
end

-- The keys of a table in a fixed order: numbers first, then the others by their text.
local function Before(a, b)
    local x, y = type(a), type(b)
    if x ~= y then return x < y end
    if x == "boolean" then return not a and b end
    return a < b
end

local Write
function Write(value, depth, out)
    local kind = type(value)
    if kind == "boolean" then
        out[#out + 1] = value and "t" or "f"
    elseif kind == "number" then
        out[#out + 1] = Number(value)
    elseif kind == "string" then
        out[#out + 1] = 's"' .. Escape(value) .. '"'
    elseif kind == "table" then
        if depth >= Serial.DEPTH then return false end
        local keys = {}
        for key, inner in pairs(value) do
            local keyKind, innerKind = type(key), type(inner)
            if (keyKind == "string" or keyKind == "number" or keyKind == "boolean")
                and (innerKind == "string" or innerKind == "number" or innerKind == "boolean" or innerKind == "table") then
                keys[#keys + 1] = key
            end
        end
        table.sort(keys, Before)
        out[#out + 1] = "{"
        for index, key in ipairs(keys) do
            if index > 1 then out[#out + 1] = "," end
            if not Write(key, depth + 1, out) then return false end
            out[#out + 1] = "="
            if not Write(value[key], depth + 1, out) then return false end
        end
        out[#out + 1] = "}"
    else
        return false
    end
    return true
end

function Serial.Write(value)
    local out = {}
    if not Write(value, 0, out) then return nil end
    return table.concat(out)
end

-------------------------------------------------------------------------------
--  Reading
-------------------------------------------------------------------------------
local byte, sub, find = string.byte, string.sub, string.find

-- Each step reads one value from at; returns it and where the next begins, or nil and where it broke.
local Read
function Read(text, at, depth)
    local char = sub(text, at, at)
    if char == "t" then return true, at + 1 end
    if char == "f" then return false, at + 1 end
    if char == "n" then
        local from, to = find(text, "^[%-%+%.%deE]+", at + 1)
        local number = from and tonumber(sub(text, from, to))
        if not number then return nil, at end
        return number, to + 1
    end
    if char == "s" then
        if sub(text, at + 1, at + 1) ~= '"' then return nil, at end
        local close = find(text, '"', at + 2, true)
        if not close then return nil, at end
        local raw = sub(text, at + 2, close - 1)
        -- Every backslash starts three digits of a byte; anything else is no text of ours.
        if find((raw:gsub("\\%d%d%d", "")), "\\", 1, true) then return nil, at end
        local broken = false
        local body = raw:gsub("\\(%d%d%d)", function(digits)
            local code = tonumber(digits)
            if code > 255 then broken = true end
            return string.char(math.min(code, 255))
        end)
        if broken then return nil, at end
        return body, close + 1
    end
    if char == "{" then
        if depth >= Serial.DEPTH then return nil, at, TEXT.deep end
        local result, next = {}, at + 1
        if sub(text, next, next) == "}" then return result, next + 1 end
        while true do
            local key, after, why = Read(text, next, depth + 1)
            if key == nil or sub(text, after, after) ~= "=" then return nil, after, why end
            local value, rest
            value, rest, why = Read(text, after + 1, depth + 1)
            if value == nil then return nil, rest, why end
            result[key] = value
            local mark = sub(text, rest, rest)
            if mark == "}" then return result, rest + 1 end
            if mark ~= "," then return nil, rest end
            next = rest + 1
        end
    end
    return nil, at
end

function Serial.Read(text)
    if type(text) ~= "string" then return nil, TEXT.broken:format(1) end
    text = text:gsub("%s", "")
    if #text > Serial.LENGTH then return nil, TEXT.long end
    if byte(text, 1) == nil then return nil, TEXT.broken:format(1) end
    local value, after, why = Read(text, 1, 0)
    if value == nil then return nil, why or TEXT.broken:format(after) end
    if after <= #text then return nil, TEXT.rest:format(after) end
    return value
end
