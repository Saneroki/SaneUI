-- JSON for the interface lab's host (dev/uilab/host.lua): its messages to the lab's server and back.
-- Small on purpose: numbers, strings, booleans, arrays (tables 1..n), objects (string keys); nil is null.
local json = {}

local escapes = { ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n", ["\r"] = "\\r",
    ["\t"] = "\\t" }

local function quote(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        return escapes[c] or string.format("\\u%04x", c:byte())
    end) .. '"'
end

local function number(n)
    if n ~= n or n == math.huge or n == -math.huge then return "0" end
    if n == math.floor(n) and n > -1e15 and n < 1e15 then return string.format("%d", n) end
    local s = string.format("%.4f", n):gsub("0+$", ""):gsub("%.$", "")
    return s
end

local encode
local function array(t, n, out)
    out[#out + 1] = "["
    for i = 1, n do
        if i > 1 then out[#out + 1] = "," end
        encode(t[i], out)
    end
    out[#out + 1] = "]"
end

function encode(v, out)
    local kind = type(v)
    if kind == "string" then
        out[#out + 1] = quote(v)
    elseif kind == "number" then
        out[#out + 1] = number(v)
    elseif kind == "boolean" then
        out[#out + 1] = v and "true" or "false"
    elseif kind == "table" then
        local n = #v
        if n > 0 or next(v) == nil then
            if next(v) == nil and getmetatable(v) == json.object then
                out[#out + 1] = "{}"
            else
                array(v, n, out)
            end
        else
            out[#out + 1] = "{"
            local first = true
            for k, x in pairs(v) do
                if not first then out[#out + 1] = "," end
                first = false
                out[#out + 1] = quote(tostring(k))
                out[#out + 1] = ":"
                encode(x, out)
            end
            out[#out + 1] = "}"
        end
    else
        out[#out + 1] = "null"
    end
end

json.object = {}   -- setmetatable({}, json.object): an empty table written as {} rather than []

function json.encode(v)
    local out = {}
    encode(v, out)
    return table.concat(out)
end

-- Decoding ----------------------------------------------------------------------------------------------------------
local decode

local function skip(s, i)
    return s:find("[^ \t\r\n]", i) or #s + 1
end

local function utf8(code)
    if code < 0x80 then return string.char(code) end
    if code < 0x800 then return string.char(0xC0 + math.floor(code / 64), 0x80 + code % 64) end
    return string.char(0xE0 + math.floor(code / 4096), 0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
end

local function str(s, i)
    local out, j = {}, i + 1
    while true do
        local c = s:sub(j, j)
        if c == "" then error("json: unfinished string") end
        if c == '"' then return table.concat(out), j + 1 end
        if c == "\\" then
            local e = s:sub(j + 1, j + 1)
            if e == "u" then
                local code = tonumber(s:sub(j + 2, j + 5), 16)
                if code >= 0xD800 and code < 0xDC00 and s:sub(j + 6, j + 7) == "\\u" then
                    local low = tonumber(s:sub(j + 8, j + 11), 16)
                    code = 0x10000 + (code - 0xD800) * 1024 + (low - 0xDC00)
                    j = j + 6
                    out[#out + 1] = string.char(0xF0 + math.floor(code / 262144), 0x80 + math.floor(code / 4096) % 64,
                        0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
                else
                    out[#out + 1] = utf8(code)
                end
                j = j + 6
            else
                local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
                out[#out + 1] = map[e] or e
                j = j + 2
            end
        else
            local k = s:find('["\\]', j) or #s + 1
            out[#out + 1] = s:sub(j, k - 1)
            j = k
        end
    end
end

function decode(s, i)
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == "{" then
        local t = {}
        i = skip(s, i + 1)
        if s:sub(i, i) == "}" then return t, i + 1 end
        while true do
            local k
            k, i = str(s, skip(s, i))
            i = skip(s, i)
            if s:sub(i, i) ~= ":" then error("json: : expected at " .. i) end
            t[k], i = decode(s, i + 1)
            i = skip(s, i)
            local d = s:sub(i, i)
            if d == "}" then return t, i + 1 end
            if d ~= "," then error("json: , expected at " .. i) end
            i = i + 1
        end
    elseif c == "[" then
        local t, n = {}, 0
        i = skip(s, i + 1)
        if s:sub(i, i) == "]" then return t, i + 1 end
        while true do
            n = n + 1
            t[n], i = decode(s, i)
            i = skip(s, i)
            local d = s:sub(i, i)
            if d == "]" then return t, i + 1 end
            if d ~= "," then error("json: , expected at " .. i) end
            i = i + 1
        end
    elseif c == '"' then
        return str(s, i)
    elseif s:sub(i, i + 3) == "true" then
        return true, i + 4
    elseif s:sub(i, i + 4) == "false" then
        return false, i + 5
    elseif s:sub(i, i + 3) == "null" then
        return nil, i + 4
    end
    local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
    if not num or num == "" then error("json: unexpected '" .. c .. "' at " .. i) end
    return tonumber(num), i + #num
end

function json.decode(s)
    return (decode(s, 1))
end

return json
