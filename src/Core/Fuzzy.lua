local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Fuzzy
--  Finding what was typed in a text, forgivingly: whole, as a piece of it, as
--  the first letters of its words, or as letters spread through it in their
--  order. What a window's search box (Window.lua) hands its module, and what
--  the module hides, keeps or sorts its rows by.
--
--      local query = Fuzzy.Query("ston gate")   -- the words typed, lower case; nil: nothing typed
--      Fuzzy.Match(query, text, ...)            -- every word found in one of the texts: the sum of their
--                                               -- ranks; nil: a word is in none of them
--      Fuzzy.Rank(word, text, low, spots)       -- one word (lower case) in one text: its rank, or nil;
--                                               -- low: the text in lower case, if the caller has it;
--                                               -- spots: a table to get the bytes of the text it took
--      Fuzzy.Highlight(text, spots)             -- the text with those letters in the game's gold
--
--  A rank is a whole number. Its hundreds say how the word was found, best
--  first:
--      600  the whole text                       "darnassus" in "Darnassus"
--      500  the text's beginning                 "iron" in "Ironforge"
--      400  the beginning of one of its words    "city" in "Stormwind City"
--      300  the first letters of its words       "tb" in "Thunder Bluff" (a word may be left out)
--      200  inside a word                        "forge" in "Ironforge"
--      100  letters spread out, in their order   "gsr" in "Goldshire"
--  and the rest is up to 90 points more for a close fit, 30 for each of: few
--  letters in the text besides the word's, the word found early, and its
--  letters close together. A word starts at the text's start, after anything
--  but a letter or a digit (an apostrophe belongs to the word: "Hero's" is
--  one), and at a capital after a small letter.
--
--  Cost: no table is made unless spots are asked for, and each look goes once
--  through the text, so a long list can be ranked at every key. Ask for spots
--  (Highlight) only for the rows on screen. Colour codes and links in a text
--  are the caller's to take out first.
-------------------------------------------------------------------------------
local Fuzzy = {}
Core.Fuzzy = Fuzzy

Fuzzy.WHOLE, Fuzzy.FRONT, Fuzzy.WORD, Fuzzy.ACRONYM, Fuzzy.INSIDE, Fuzzy.SPREAD = 600, 500, 400, 300, 200, 100
local FIT = 30 -- the most each part of a close fit adds

local byte, find, lower, max = string.byte, string.find, string.lower, math.max

-- Each byte's class, made once: part of a word (a letter, a digit, an apostrophe, or any byte of a
-- letter beyond the plain ones, UTF-8), and the plain small and capital letters.
local INWORD, SMALL, BIG = {}, {}, {}
for code = 0, 255 do
    local char = string.char(code)
    INWORD[code] = code >= 128 or char == "'" or char:find("%w") ~= nil
    SMALL[code] = code < 128 and char:find("%l") ~= nil
    BIG[code] = code < 128 and char:find("%u") ~= nil
end

-- Whether a word of the text begins at byte at.
local function Begins(text, at)
    if at == 1 then return true end
    local before, here = byte(text, at - 1), byte(text, at)
    if not INWORD[before] then return INWORD[here] end
    return SMALL[before] and BIG[here] -- "LootFrame": the F
end

-- The rank of that kind for a word of n letters in a text of m bytes, found from first to last.
local function Ranked(kind, n, m, first, last)
    return kind + max(0, FIT - (m - n)) + max(0, FIT - (first - 1)) + max(0, FIT - (last - first + 1 - n))
end

local function Run(spots, from, n)
    if not spots then return end
    for index = 1, n do spots[index] = from + index - 1 end
end

-- The word as the first letters of the text's words, in their order; words may be left out between.
-- Returns where the first and the last letter were found.
local function FirstLetters(word, text, low, n, m, spots)
    if n < 2 then return nil end
    local k, first, last = 1, nil, nil
    for at = 1, m do
        if byte(low, at) == byte(word, k) and Begins(text, at) then
            if spots then spots[k] = at end
            first, last = first or at, at
            if k == n then return first, last end
            k = k + 1
        end
    end
    return nil
end

-- The word's letters spread through the text, each after the one before. First the earliest place the
-- last letter can be reached at, then back from it the latest place of each letter before: the letters
-- as close together as they come there. Returns where the first and the last were found.
local function Spread(word, low, n, m, spots)
    local k, last = 1, nil
    for at = 1, m do
        if byte(low, at) == byte(word, k) then
            if k == n then
                last = at
                break
            end
            k = k + 1
        end
    end
    if not last then return nil end
    local at = last
    for index = n - 1, 1, -1 do
        if spots then spots[index + 1] = at end
        local letter = byte(word, index)
        repeat at = at - 1 until byte(low, at) == letter
    end
    if spots then spots[1] = at end
    return at, last
end

function Fuzzy.Rank(word, text, low, spots)
    local n, m = #word, #text
    if n == 0 then return 0 end
    if n > m then return nil end
    low = low or lower(text)
    if spots then for index = #spots, n + 1, -1 do spots[index] = nil end end
    -- Side by side: the first place, or the first where a word begins.
    local inside = find(low, word, 1, true)
    if inside then
        local kind = low == word and Fuzzy.WHOLE or inside == 1 and Fuzzy.FRONT
        local at = inside
        while not kind and at do
            if Begins(text, at) then kind = Fuzzy.WORD else at = find(low, word, at + 1, true) end
        end
        if kind then
            Run(spots, at, n)
            return Ranked(kind, n, m, at, at + n - 1)
        end
    end
    local first, last = FirstLetters(word, text, low, n, m, spots)
    if first then return Ranked(Fuzzy.ACRONYM, n, m, first, last) end
    if inside then
        Run(spots, inside, n)
        return Ranked(Fuzzy.INSIDE, n, m, inside, inside + n - 1)
    end
    first, last = Spread(word, low, n, m, spots)
    if first then return Ranked(Fuzzy.SPREAD, n, m, first, last) end
    return nil
end

function Fuzzy.Query(text)
    local words
    for word in lower(tostring(text or "")):gmatch("%S+") do
        words = words or {}
        words[#words + 1] = word
    end
    return words
end

local texts, lows = {}, {} -- Match's texts and their lower case, kept between calls
function Fuzzy.Match(query, ...)
    if not query then return 0 end
    local total, count = 0, select("#", ...)
    for index = 1, count do -- each text lowered once, not once per word
        local text = select(index, ...)
        texts[index] = type(text) == "string" and text or false
        lows[index] = texts[index] and lower(text) or false
    end
    for _, word in ipairs(query) do
        local best
        for index = 1, count do
            local rank = texts[index] and Fuzzy.Rank(word, texts[index], lows[index])
            if rank and (not best or rank > best) then best = rank end
        end
        if not best then return nil end
        total = total + best
    end
    return total
end

-- One character of the text, with where it starts: a first byte and the bytes that continue it. A
-- stray continuing byte is a character of its own; the empty match at the very end is skipped.
local CHARACTER = "()([^\128-\191]?[\128-\191]*)"

-- The text with the characters at the spots (byte places, a character marked by any of its bytes) in
-- the game's gold, NORMAL_FONT_COLOR, run by run. A "|" of the text is doubled: the game shows it then.
function Fuzzy.Highlight(text, spots)
    local marked = {}
    for _, at in ipairs(spots or {}) do marked[at] = true end
    local gold = rawget(_G, "NORMAL_FONT_COLOR")
    local out, run = {}, {}
    local function Close()
        if not run[1] then return end
        local piece = table.concat(run)
        out[#out + 1] = gold and gold:WrapTextInColorCode(piece) or piece
        for index = #run, 1, -1 do run[index] = nil end
    end
    for at, character in text:gmatch(CHARACTER) do
        if character ~= "" then
            local hit = false
            for place = at, at + #character - 1 do hit = hit or marked[place] or false end
            if character == "|" then character = "||" end
            if hit then
                run[#run + 1] = character
            else
                Close()
                out[#out + 1] = character
            end
        end
    end
    Close()
    return table.concat(out)
end
