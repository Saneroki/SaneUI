local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Slots
--  What the open loot holds, read from the game into plain lines: one for
--  each of the game's slots, in its order (a slot taken is left out). The
--  window draws them; the rules read them. Nothing here knows a frame.
--
--      local lines = Slots.Read()       -- the loot open now (empty while none is)
--      local line = Slots.Line(slot)    -- one slot anew; nil for one that is empty
--      Slots.Wanted(line, options)      -- whether the player's rules take it at once
--      Slots.Rule(line, options, own)   -- the rule that takes it: a switch's key, "list"; nil
--      Slots.Quest(line)                -- a quest's thing (the window's gold border)
--      Slots.Item(id)                   -- a line for an item the game knows (the list of items)
--      Slots.Name(id)                   -- an item's name, if the game knows it
--
--  A line: slot, kind ("item", "money", "currency"), icon, name, count,
--  quality, locked, link, id (an item's), quest (a quest wants it), starts (it
--  begins a quest not taken yet), bind (the game's: 1 when picked up, 2 when
--  equipped, 3 when used, 4 a quest's), class (the game's Enum.ItemClass),
--  kind's words (what, where), worth (a vendor's price for one).
--
--  The rules (the options Taken at once, every one off at first): Everything,
--  else a kind (coins, currencies, quest items, trade goods, gear, consumables,
--  junk). Over them the player's own word on an item (options.kept[id]: true
--  taken at once, false never). Never by a kind: a thing locked to a roll, or
--  one that binds when picked up (the game would ask), a quest's excepted.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Slots = {}
ns.Slots = Slots

-- The game's kinds of loot slot (Enum.LootSlotType); the numbers where this client has no such list.
local function Kinds()
    local kinds = rawget(_G, "Enum") and Enum.LootSlotType
    return kinds or { None = 0, Item = 1, Money = 2, Currency = 3 }
end

-- What the game says of an item (a link or an ID): its kind's words, where it is worn, its price at a vendor, how it
-- binds, its class, quality and picture.
local function ItemFacts(item)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if type(info) ~= "function" or not item then return nil end
    local ok, name, _, quality, _, _, what, sub, _, where, icon, worth, class, _, bind = pcall(info, item)
    if not ok then return nil end
    return Plain(name), Plain(what), Plain(sub), Plain(where), Plain(worth), Plain(bind), Plain(class), Plain(quality),
        Plain(icon)
end

-- An item's kind's words: where it is worn (the game's word), else its kind.
local function Where(line, where)
    line.where = where and where ~= "" and Core.Word(where, nil) or nil
end

function Slots.Name(id)
    return (ItemFacts(id))
end

-- One slot of the open loot as a line; nil for an empty one (taken, or nothing there).
function Slots.Line(slot)
    local icon, name, count, currency, quality, locked, questItem, questID, active, coin = GetLootSlotInfo(slot)
    name = Plain(name)
    if not name and not Plain(icon) then return nil end
    local kinds = Kinds()
    local kind = Plain(GetLootSlotType and GetLootSlotType(slot))
    if kind == kinds.None then return nil end
    local line = { slot = slot, icon = Plain(icon), name = name or "", count = Plain(count) or 1,
                   quality = Plain(quality) or 1, locked = Plain(locked) and true or false }
    currency = Plain(currency)
    if kind == kinds.Money or (kind == nil and Plain(coin)) then
        line.kind = "money"
        -- The game writes a coin slot's money as its name, on lines ("12 Silver\n3 Copper"): one line here.
        line.name = line.name:gsub("\n", " ")
    elseif kind == kinds.Currency or currency then
        line.kind = "currency"
        local util = rawget(_G, "CurrencyContainerUtil")
        if currency and util and util.GetCurrencyContainerInfo then
            local n, t, c, q = util.GetCurrencyContainerInfo(currency, line.count, line.name, line.icon, line.quality)
            line.name, line.icon, line.count, line.quality = Plain(n) or line.name, Plain(t) or line.icon,
                Plain(c) or line.count, Plain(q) or line.quality
        end
    else
        line.kind = "item"
    end
    questID = Plain(questID)
    line.quest = (Plain(questItem) or questID) and true or false
    line.starts = (questID and not Plain(active)) and true or false
    if line.kind == "item" then
        line.link = Plain(GetLootSlotLink(slot))
        line.id = line.link and tonumber(line.link:match("item:(%d+)"))
        local _, what, sub, where, worth, bind, class = ItemFacts(line.link)
        line.what, line.sub, line.worth, line.bind, line.class = what, sub, worth, bind, class
        Where(line, where)
    end
    return line
end

-- Every line of the loot open now, in the game's order.
function Slots.Read()
    local lines = {}
    local count = Plain(GetNumLootItems()) or 0
    for slot = 1, count do
        local line = Slots.Line(slot)
        if line then lines[#lines + 1] = line end
    end
    return lines
end

-- A line for an item the game knows by its ID (the list of items in the options), as a loot slot's would be; nil
-- while the game has not told it yet.
function Slots.Item(id)
    local name, what, sub, where, worth, bind, class, quality, icon = ItemFacts(id)
    if not name then return nil end
    local line = { kind = "item", id = id, name = name, what = what, sub = sub, worth = worth, bind = bind,
                   class = class, quality = quality or 1, icon = icon, count = 1 }
    Where(line, where)
    return line
end

-- The game's item classes the kinds are made of (Enum.ItemClass; its numbers where a client has none).
local function Class(name, number)
    local classes = rawget(_G, "Enum") and Enum.ItemClass
    return classes and classes[name] or number
end
local CONSUMABLE, WEAPON, ARMOR = Class("Consumable", 0), Class("Weapon", 2), Class("Armor", 4)
local REAGENT, TRADE, QUEST = Class("Reagent", 5), Class("Tradegoods", 7), Class("Questitem", 12)

-- Whether a quest wants the thing, or it begins one (or binds as a quest's, or is of the quests' class).
function Slots.Quest(line)
    return (line.quest or line.starts or line.bind == 4 or (line.kind == "item" and line.class == QUEST)) and true or false
end

local function Item(line) return line.kind == "item" end

-- The kinds the rules know, in the order of their switches: the switch's key, and whether a line is of the kind.
Slots.KINDS = {
    { key = "takeCoins", fits = function(line) return line.kind == "money" end },
    { key = "takeCurrency", fits = function(line) return line.kind == "currency" end },
    { key = "takeQuest", fits = function(line) return Item(line) and Slots.Quest(line) end },
    { key = "takeTrade", fits = function(line) return Item(line) and (line.class == TRADE or line.class == REAGENT) end },
    { key = "takeGear", fits = function(line) return Item(line) and (line.class == WEAPON or line.class == ARMOR) end },
    { key = "takeConsumable", fits = function(line) return Item(line) and line.class == CONSUMABLE end },
    { key = "takeJunk", fits = function(line) return Item(line) and line.quality == 0 end },
}

-- The rule that takes this line at once: "list" (the player's word on the item), "takeAll", or the key of the
-- kind's switch; nil for none. own = false leaves the player's word out (what the switches alone would do).
function Slots.Rule(line, options, own)
    if not line or line.locked then return nil end
    local kept = type(options.kept) == "table" and options.kept or {}
    local word
    if own ~= false and Item(line) and line.id then word = kept[line.id] end
    if word == false then return nil end
    if word == true then return "list" end
    if Item(line) and line.bind == 1 and not Slots.Quest(line) then return nil end -- the game would ask first
    if options.takeAll then return "takeAll" end
    for _, kind in ipairs(Slots.KINDS) do
        if options[kind.key] and kind.fits(line) then return kind.key end
    end
    return nil
end

-- Whether the player's rules take this line at once.
function Slots.Wanted(line, options)
    return Slots.Rule(line, options) ~= nil
end

-- The note under a line's name: how it binds, its kind and where it is worn; a quest's.
function Slots.Note(line)
    local T = ns.TEXT
    if line.kind == "money" then return T.coins end
    if line.kind == "currency" then return T.currency end
    if line.starts then return T.questStarts end
    if Slots.Quest(line) then return T.questItem end
    local parts = {}
    if line.bind == 1 then parts[1] = T.pickup elseif line.bind == 2 then parts[1] = T.equip
    elseif line.bind == 3 then parts[1] = T.use end
    local kind = line.where or line.sub or line.what
    if kind and kind ~= "" then parts[#parts + 1] = kind end
    return table.concat(parts, " · ")
end
