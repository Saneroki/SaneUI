-- Stand-ins for the game's bit library and C_EncodingUtil, in plain Lua, for the tests: bit's band and bxor; base64
-- both ways; zlib and deflate "packing" as stored blocks (no compression), unpacked both ways, the Adler-32 checked.
local E = {}

local function Bits(a, b, both)
    local result, place = 0, 1
    a, b = a % 4294967296, b % 4294967296
    while a > 0 or b > 0 do
        local x, y = a % 2, b % 2
        if (both and x == 1 and y == 1) or (not both and x ~= y) then result = result + place end
        a, b, place = (a - x) / 2, (b - y) / 2, place * 2
    end
    return result
end
E.bit = { band = function(a, b) return Bits(a, b, true) end, bxor = function(a, b) return Bits(a, b, false) end }

local LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local VALUE = {}
for at = 1, 64 do VALUE[LETTERS:byte(at)] = at - 1 end

function E.Encode64(bytes)
    local out = {}
    for at = 1, #bytes, 3 do
        local a, b, c = bytes:byte(at, at + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local d1, d2, d3, d4 = math.floor(n / 262144) % 64, math.floor(n / 4096) % 64, math.floor(n / 64) % 64, n % 64
        out[#out + 1] = LETTERS:sub(d1 + 1, d1 + 1) .. LETTERS:sub(d2 + 1, d2 + 1)
            .. (b and LETTERS:sub(d3 + 1, d3 + 1) or "=") .. (c and LETTERS:sub(d4 + 1, d4 + 1) or "=")
    end
    return table.concat(out)
end

function E.Decode64(text)
    text = text:gsub("[^%w%+/]", "")
    local out = {}
    for at = 1, #text, 4 do
        local n, count = 0, 0
        for k = at, math.min(at + 3, #text) do
            n = n * 64 + VALUE[text:byte(k)]
            count = count + 1
        end
        for _ = count + 1, 4 do n = n * 64 end
        local bytes = { math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 }
        for k = 1, count - 1 do out[#out + 1] = string.char(bytes[k]) end
    end
    return table.concat(out)
end

function E.Adler(text)
    local a, b = 1, 0
    for at = 1, #text do
        a = (a + text:byte(at)) % 65521
        b = (b + a) % 65521
    end
    return b * 65536 + a
end

-- Deflate's stored blocks of a text (no compression), each at most 65535 bytes.
local function Stored(text)
    local out, at = {}, 1
    repeat
        local piece = text:sub(at, at + 65534)
        at = at + #piece
        local last = at > #text and 1 or 0
        local n = #piece
        out[#out + 1] = string.char(last, n % 256, math.floor(n / 256), 255 - n % 256, 255 - math.floor(n / 256)) .. piece
    until at > #text
    return table.concat(out)
end

local function Unstored(bytes, at)
    local out = {}
    while true do
        local head = bytes:byte(at)
        assert(head and head % 8 < 2, "only stored blocks")
        local n = bytes:byte(at + 1) + bytes:byte(at + 2) * 256
        out[#out + 1] = bytes:sub(at + 5, at + 4 + n)
        at = at + 5 + n
        if head % 2 == 1 then break end
    end
    return table.concat(out), at
end

function E.Zlib(text)
    local sum = E.Adler(text)
    return "\120\1" .. Stored(text) .. string.char(math.floor(sum / 16777216) % 256, math.floor(sum / 65536) % 256,
                                                   math.floor(sum / 256) % 256, sum % 256)
end

E.C_EncodingUtil = {
    EncodeBase64 = function(bytes) return E.Encode64(bytes) end,
    DecodeBase64 = function(text) return E.Decode64(text) end,
    CompressString = function(text, method)
        if method == 1 then return E.Zlib(text) end
        return Stored(text)
    end,
    DecompressString = function(bytes, method)
        if method == 1 then
            assert(bytes:byte(1) == 120, "zlib's head")
            local text, at = Unstored(bytes, 3)
            local w, x, y, z = bytes:byte(at, at + 3)
            assert(((w * 256 + x) * 256 + y) * 256 + z == E.Adler(text), "zlib's sum")
            return text
        end
        return (Unstored(bytes, 1))
    end,
}

-- An import string of guides for an account's tag, as the bought guides come: the same recipe the test checks.
function E.Lock(tag, texts, recipe)
    local width, taps = recipe.width, recipe.taps
    tag = tag:lower()
    if #tag > width then tag = tag:sub(-width) end
    local before, key = width - #tag, {}
    for at = 0, width - 1 do key[at] = at >= before and tag:byte(at - before + 1) or 0 end
    for at = 0, width - 1 do
        local stirred = 0
        for _, tap in ipairs(taps) do stirred = E.bit.bxor(stirred, key[(tap - at) % width]) end
        key[(-at) % width] = stirred
    end
    local box, j = {}, 0
    for at = 0, 255 do box[at] = at end
    for at = 0, 255 do
        j = (j + box[at] + key[at % width]) % 256
        box[at], box[j] = box[j], box[at]
    end
    local pieces = {}
    for _, text in ipairs(texts) do
        local s = {}
        for at = 0, 255 do s[at] = box[at] end
        local packed, out, i, k = E.Zlib(text), {}, 0, 0
        for at = 1, #packed do
            i = (i + 1) % 256
            k = (k + s[i]) % 256
            s[i], s[k] = s[k], s[i]
            out[at] = string.char(E.bit.bxor(packed:byte(at), s[(s[i] + s[k]) % 256]))
        end
        pieces[#pieces + 1] = E.Adler(text) .. recipe.mark .. E.Encode64(table.concat(out)) .. recipe.close
    end
    return #texts .. "|" .. table.concat(pieces) .. "|" .. recipe.version
end

return E
