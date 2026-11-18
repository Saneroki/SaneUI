local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Speed Leveling - Unlock
--  The guides you bought, opened for the account you play (Saneroki,
--  2026-10-25). A bought guide of the leveling guide SaneUI knows comes as an
--  import string that only the buyer's account opens: pieces of the guides'
--  text, each packed (zlib) and locked with a key made from the buyer's
--  BattleTag. SaneUI opens it as that guide does, with the BattleTag of the
--  account you play and no other: the key is made in memory and never kept, and
--  a string bought for another account stays shut. How the key is made and how
--  the string is marked are that guide's (Core.Neighbours.Lock); base64 and zlib
--  are the game's own (C_EncodingUtil). The work runs in steps over frames
--  (Core.Steps), so a large string does not hold the game up.
--
--      Unlock.Looks(text)          whether a text is such a string
--      Unlock.Open(text, done)     done(texts) with the guides' texts in it, or done(nil, problem) with our words why;
--                                  false when none was started (one is open already)
--      Unlock.Shown()              how far the one open now is: a share of 1, or nil
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Unlock = {}
ns.Unlock = Unlock

Unlock.CHUNK = 4096 -- bytes worked between two looks at the frame's time
Unlock.WHOLE = 4294967296

local ZLIB = 1 -- the game's Enum.CompressionMethod.Zlib, should its name be missing
local band, bxor = bit and bit.band, bit and bit.bxor

local opening   -- the share done of the string open now, or nil

-------------------------------------------------------------------------------
--  The string
-------------------------------------------------------------------------------
-- The string's parts: its pieces { { sum, body } } in order, its format's version; nil for a text that is none.
local function Parts(text, recipe)
    local body = text:gsub("%s+", ""):gsub("^%D+", ""):gsub("%D+$", "")
    local version = tonumber(body:match("|(%d+)$"))
    if not (body:find("^%d+|%d") and version) then return nil end
    local pieces = {}
    local close = recipe.close:gsub("%p", "%%%0")
    for sum, mark, packed in body:gmatch("(%-?%d+)(%D)([A-Za-z0-9%+/=]+)" .. close) do
        if mark ~= recipe.mark then return nil end
        pieces[#pieces + 1] = { sum = tonumber(sum) % Unlock.WHOLE, packed = packed }
    end
    if not pieces[1] then return nil end
    return pieces, version
end

function Unlock.Looks(text)
    local recipe = Core.Neighbours.Lock("guide")
    return type(text) == "string" and recipe ~= nil and Parts(text, recipe) ~= nil
end

-------------------------------------------------------------------------------
--  The key
-------------------------------------------------------------------------------
-- The key of the account played, as a list of bytes from 0; nil while the game does not name it.
local function Key(recipe)
    local answers = { Core.Ask(rawget(_G, recipe.account)) }
    local tag = answers[recipe.tag]
    if type(tag) ~= "string" or tag == "" then return nil end
    local width = recipe.width
    tag = tag:lower()
    if #tag > width then tag = tag:sub(-width) end
    local before = width - #tag
    local key = {}
    for at = 0, width - 1 do key[at] = at >= before and tag:byte(at - before + 1) or 0 end
    for at = 0, width - 1 do
        local stirred = 0
        for _, tap in ipairs(recipe.taps) do stirred = bxor(stirred, key[(tap - at) % width]) end
        key[(-at) % width] = stirred
    end
    return key
end

-- The cipher's box for a key: the bytes 0 to 255, mixed by it.
local function Box(key, width)
    local box = {}
    for at = 0, 255 do box[at] = at end
    local other = 0
    for at = 0, 255 do
        other = (other + box[at] + key[at % width]) % 256
        box[at], box[other] = box[other], box[at]
    end
    return box
end

-------------------------------------------------------------------------------
--  A piece
-------------------------------------------------------------------------------
-- A piece's bytes unlocked: each with the cipher's next byte, from a fresh copy of the box.
local function Unlocked(bytes, box, step)
    local s = {}
    for at = 0, 255 do s[at] = box[at] end
    local i, j = 0, 0
    local parts, chunk = {}, {}
    local size = #bytes
    for first = 1, size, Unlock.CHUNK do
        local last = math.min(size, first + Unlock.CHUNK - 1)
        local count = 0
        for at = first, last do
            i = (i + 1) % 256
            local a = s[i]
            j = (j + a) % 256
            local b = s[j]
            s[i], s[j] = b, a
            count = count + 1
            chunk[count] = bxor(bytes:byte(at), s[(a + b) % 256])
        end
        parts[#parts + 1] = string.char(unpack(chunk, 1, count))
        step(last)
    end
    return table.concat(parts)
end

-- The Adler-32 sum of a text, as zlib has it.
local function Adler(text, step)
    local a, b = 1, 0
    local size = #text
    for first = 1, size, Unlock.CHUNK do
        local last = math.min(size, first + Unlock.CHUNK - 1)
        local bytes = { text:byte(first, last) }
        for at = 1, #bytes do
            a = (a + bytes[at]) % 65521
            b = (b + a) % 65521
        end
        step()
    end
    return b * 65536 + a
end

-- Whether unlocked bytes are zlib's packing of a text with that sum: its head, and the sum at its end. Bytes
-- unlocked with another account's key are noise and fail here.
local function Packed(bytes, sum)
    local size = #bytes
    if size < 8 then return false end
    local method, flags = bytes:byte(1, 2)
    if method % 16 ~= 8 or method > 0x78 or math.floor(flags / 32) % 2 ~= 0 or (method * 256 + flags) % 31 ~= 0 then
        return false
    end
    local w, x, y, z = bytes:byte(size - 3, size)
    return ((w * 256 + x) * 256 + y) * 256 + z == sum
end

-------------------------------------------------------------------------------
--  Opening
-------------------------------------------------------------------------------
-- Our words for what went wrong.
local function Problem(what) return ns.TEXT["unlock" .. what] or what end

-- Each piece opened in turn, as a job; its result into into.texts or into.problem.
local function Work(pieces, box, into)
    local encoding = rawget(_G, "C_EncodingUtil")
    local zlib = rawget(_G, "Enum") and Enum.CompressionMethod and Enum.CompressionMethod.Zlib or ZLIB
    -- How far: the pieces' lengths as written, each piece's share by its bytes unlocked so far.
    local total, done = 0, 0
    for _, piece in ipairs(pieces) do total = total + #piece.packed end
    local texts = {}
    for _, piece in ipairs(pieces) do
        local ok, bytes = pcall(encoding.DecodeBase64, piece.packed)
        if not ok or type(bytes) ~= "string" or bytes == "" then into.problem = Problem("Broken") return end
        local plain = Unlocked(bytes, box, function(at)
            opening = (done + #piece.packed * at / #bytes) / total
            Core.Steps.Check()
        end)
        done = done + #piece.packed
        if not Packed(plain, piece.sum) then into.problem = Problem("Account") return end
        local unpacked, text = pcall(encoding.DecompressString, plain, zlib)
        if not unpacked or type(text) ~= "string" then into.problem = Problem("Broken") return end
        if Adler(text, Core.Steps.Check) ~= piece.sum then into.problem = Problem("Account") return end
        for guide in text:gmatch("[^%z]+") do
            if guide:find("%S") then texts[#texts + 1] = guide end
        end
    end
    if not texts[1] then into.problem = Problem("Empty") return end
    into.texts = texts
end

function Unlock.Open(text, done)
    if opening then return false end
    local recipe = Core.Neighbours.Lock("guide")
    local pieces, version = nil, nil
    if recipe and type(text) == "string" then pieces, version = Parts(text, recipe) end
    local function Tell(texts, problem) ns.Safe("unlock", done, texts, problem) end
    if not pieces then Tell(nil, Problem("Broken")) return true end
    if version < recipe.version then Tell(nil, Problem("Old")) return true end
    local encoding = rawget(_G, "C_EncodingUtil")
    if not (band and encoding and encoding.DecodeBase64 and encoding.DecompressString) then
        Tell(nil, Problem("Game"))
        return true
    end
    local key = Key(recipe)
    if not key then Tell(nil, Problem("Offline")) return true end
    local box = Box(key, recipe.width)
    local into = {}
    opening = 0
    local job = Core.Steps.Run({ name = "Speed Leveling: unlock", label = "speedleveling: unlock",
                                 done = function(problem)
                                     opening = nil
                                     if problem then Tell(nil, Problem("Broken")) else Tell(into.texts, into.problem) end
                                 end }, Work, pieces, box, into)
    if not job then
        opening = nil
        return false
    end
    return true
end

function Unlock.Shown() return opening end
