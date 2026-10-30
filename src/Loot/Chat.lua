local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Chat
--  The game tells of loot in sentences of its own (its global strings, in the
--  player's language): "You receive loot: %s.", "%s has selected Need for:
--  %s". Each is turned once into a pattern, and a line of the chat read back
--  into its parts. Nothing here knows a frame.
--
--      Chat.Received(text)  -- who (nil: you), the item's link, how many
--      Chat.Rolled(text)    -- who (nil: you), the choice ("need", "greed",
--                           -- "disenchant", "transmog", "pass", "won"), the link
--      Chat.Money(text)     -- the copper in a line about money you looted
--      Chat.Currency(text)  -- a currency's link and how many, received
--  A line the game hides from addons (a secret value) reads as nothing.
-------------------------------------------------------------------------------
local Plain = SaneUI.Core.Plain
local Chat = {}
ns.Chat = Chat

-- A sentence of the game's as a pattern: its %s are any words, its %d a number; the rest found as written.
local function Pattern(name)
    local words = rawget(_G, name)
    if type(words) ~= "string" or words == "" then return nil end
    -- its parts marked first ("%s", "%d", "%1$s"), the rest made plain, then the marks made captures
    words = words:gsub("%%%d?%$?s", "\001"):gsub("%%%d?%$?d", "\002")
    words = words:gsub("[%%%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
    words = words:gsub("\001", "(.-)"):gsub("\002", "(%%d+)")
    return "^" .. words .. "$"
end

-- The sentences, each with what its parts are: who (an "other"'s name first), whether a count ends it.
-- The longer of two alike comes first ("...: %sx%d." before "...: %s.").
local RECEIVED = {
    { "LOOT_ITEM_SELF_MULTIPLE", count = true }, { "LOOT_ITEM_SELF" },
    { "LOOT_ITEM_PUSHED_SELF_MULTIPLE", count = true }, { "LOOT_ITEM_PUSHED_SELF" },
    { "LOOT_ITEM_CREATED_SELF_MULTIPLE", count = true }, { "LOOT_ITEM_CREATED_SELF" },
    { "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE", count = true }, { "LOOT_ITEM_BONUS_ROLL_SELF" },
    { "LOOT_ITEM_MULTIPLE", other = true, count = true }, { "LOOT_ITEM", other = true },
    { "LOOT_ITEM_PUSHED_MULTIPLE", other = true, count = true }, { "LOOT_ITEM_PUSHED", other = true },
    { "LOOT_ITEM_BONUS_ROLL_MULTIPLE", other = true, count = true }, { "LOOT_ITEM_BONUS_ROLL", other = true },
}
local ROLLED = {
    { "LOOT_ROLL_NEED_SELF", "need" }, { "LOOT_ROLL_GREED_SELF", "greed" },
    { "LOOT_ROLL_DISENCHANT_SELF", "disenchant" }, { "LOOT_ROLL_TRANSMOG_SELF", "transmog" },
    { "LOOT_ROLL_PASSED_SELF_AUTO", "pass" }, { "LOOT_ROLL_PASSED_SELF", "pass" },
    { "LOOT_ROLL_YOU_WON", "won" },
    { "LOOT_ROLL_NEED", "need", other = true }, { "LOOT_ROLL_GREED", "greed", other = true },
    { "LOOT_ROLL_DISENCHANT", "disenchant", other = true }, { "LOOT_ROLL_TRANSMOG", "transmog", other = true },
    { "LOOT_ROLL_PASSED_AUTO", "pass", other = true }, { "LOOT_ROLL_PASSED_AUTO_FEMALE", "pass", other = true },
    { "LOOT_ROLL_PASSED", "pass", other = true }, { "LOOT_ROLL_WON", "won", other = true },
}
local MONEY = { "YOU_LOOT_MONEY_GUILD", "YOU_LOOT_MONEY", "LOOT_MONEY_SPLIT_GUILD", "LOOT_MONEY_SPLIT" }
local COINS = { { "GOLD_AMOUNT", 10000 }, { "SILVER_AMOUNT", 100 }, { "COPPER_AMOUNT", 1 } }
local CURRENCY = { { "CURRENCY_GAINED_MULTIPLE_BONUS", count = true }, { "CURRENCY_GAINED_MULTIPLE", count = true },
                   { "CURRENCY_GAINED" } }

-- Each list's patterns, made at its first use (the game's strings are all there by then).
local made = {}
local function Patterns(list)
    if made[list] then return made[list] end
    local patterns = {}
    for _, entry in ipairs(list) do
        local name = type(entry) == "table" and entry[1] or entry
        local pattern = Pattern(name)
        if pattern then patterns[#patterns + 1] = { pattern = pattern, entry = entry } end
    end
    made[list] = patterns
    return patterns
end

function Chat.Received(text)
    text = Plain(text)
    if type(text) ~= "string" then return nil end
    for _, p in ipairs(Patterns(RECEIVED)) do
        local a, b, c = text:match(p.pattern)
        if a then
            local entry = p.entry
            if entry.other then return a, b, entry.count and tonumber(c) or 1 end
            return nil, a, entry.count and tonumber(b) or 1
        end
    end
    return nil
end

-- Returns found (true), who, the choice, the link: who is nil for you.
function Chat.Rolled(text)
    text = Plain(text)
    if type(text) ~= "string" then return nil end
    for _, p in ipairs(Patterns(ROLLED)) do
        local a, b = text:match(p.pattern)
        if a then
            if p.entry.other then return true, a, p.entry[2], b end
            return true, nil, p.entry[2], a
        end
    end
    return nil
end

function Chat.Money(text)
    text = Plain(text)
    if type(text) ~= "string" then return nil end
    for _, p in ipairs(Patterns(MONEY)) do
        local amount = text:match(p.pattern)
        if amount then
            local copper = 0
            for _, coin in ipairs(COINS) do
                local words = rawget(_G, coin[1])
                local form = type(words) == "string" and words:gsub("%%d", "(%%d+)")
                local n = form and amount:match(form)
                if n then copper = copper + tonumber(n) * coin[2] end
            end
            return copper > 0 and copper or nil
        end
    end
    return nil
end

function Chat.Currency(text)
    text = Plain(text)
    if type(text) ~= "string" then return nil end
    for _, p in ipairs(Patterns(CURRENCY)) do
        local link, count = text:match(p.pattern)
        if link then return link, p.entry.count and tonumber(count) or 1 end
    end
    return nil
end
