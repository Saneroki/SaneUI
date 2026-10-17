local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Characters
--  What each of the account's characters has, so that every character sees its alts' things
--  (Doc/guides/data.md, *Characters*): who it is, its bags, its bank, what it wears, its gold. Kept in the
--  saved variable of the pack Characters (SaneUIData_Characters), which ships nothing and is loaded soon
--  after every login; never shared.
--
--      Data.Characters()     every character of the account, by name: { key, name, realm, class, race,
--                            level, side, seen, money, bankSeen }; nil until the pack is loaded
--      Data.Character(key)   one of them, or nil
--      Data.Count(item)      { total = 40, [key] = { bags = 12, bank = 8, worn = 1 } }: where the account
--                            has the item (the key "account": the account's own bank), or nil: none, or
--                            not known yet
--      Data.CharactersStamp(), Data.OnCharacters(fn)   moves (fn() is called) when any of it changes
--
--  A character is kept by its GUID (Core.charKey), never by a name: two of them can share a first name.
--  Its whole name, first name and surname ("Sane Lunatic"), is kept beside it for showing; a first name
--  alone is never written over a whole one.
--
--  Mark, then read: an event only marks what changed (the bags, the bank, what is worn, the gold); the
--  reading follows as a job of the scheduler (Steps.lua), out of combat and within the frame's budget, a
--  bag at a time. The bank is read only while it is open (the game knows it only then); at the logout
--  what is still marked is read at once. What things are is not kept, only their IDs and counts, one
--  packed string per place: "item\031count\030item\031count", items in order. Counts across characters
--  are worked out once, in steps, when the pack has loaded, and kept up to date from then on.
-------------------------------------------------------------------------------
local Data, Steps, Codec = Core.Data, Core.Steps, Core.Data.Codec
local Plain, Ask = Core.Plain, Core.Ask

local PACK = "Characters"
local JOB, COUNTING = "characters", "characters: counts"
local PLACES = { "bags", "bank", "worn" } -- a character's places, in the order a count names them
local ACCOUNT = "account"                 -- the key of the account's own bank in a count
local LIST, PART = "\030", "\031"

local part      -- SaneUIData_Characters[game], once the pack has loaded
local mine      -- this character's entry in it
local marks = {} -- [what] = true: changed since it was last read (who, bags, worn, money, bank, account)
local bankOpen = false
local parsed = {} -- [key] = { [place] = { [item] = count } }: the packed strings taken apart
local counted = false -- every place taken apart: Count answers
local counts = {} -- [item] = the count handed out, or false: none
local views, list = {}, nil -- what Character and Characters hand out, made anew after a change
local listeners = {}
local stamp = 0

local function Day()
    local now = Ask(rawget(_G, "GetServerTime"))
    return now and math.floor(now / 86400) or nil
end

-------------------------------------------------------------------------------
--  Packed places
-------------------------------------------------------------------------------

-- { [item] = count } as one string, items in order; "" for none
local function Pack(map)
    local items = {}
    for item in pairs(map) do items[#items + 1] = item end
    table.sort(items)
    for index, item in ipairs(items) do items[index] = item .. PART .. map[item] end
    return table.concat(items, LIST)
end

-- A packed string taken apart; a broken element is left out
local function Unpack(text)
    local map = {}
    if type(text) ~= "string" or text == "" then return map end
    for _, element in ipairs(Codec.Cut(text, LIST)) do
        local item, count = element:match("^(%d+)\031(%d+)$")
        if item then map[tonumber(item)] = tonumber(count) end
    end
    return map
end

local function Map(key, place)
    local maps = parsed[key]
    if not maps then
        maps = {}
        parsed[key] = maps
    end
    local map = maps[place]
    if not map then
        local entry = key == ACCOUNT and part.account or part.characters[key]
        map = Unpack(entry and entry[place])
        maps[place] = map
    end
    return map
end

-------------------------------------------------------------------------------
--  Changes: the answers made anew, and those who listen told
-------------------------------------------------------------------------------
local function Changed()
    stamp = stamp + 1
    wipe(counts)
    wipe(views)
    list = nil
    for _, fn in ipairs(listeners) do Core.Safe("data: characters", fn) end
end

-------------------------------------------------------------------------------
--  Reading this character
-------------------------------------------------------------------------------

-- The whole name: on a client of surnames, a name without its surname (not known yet) does not replace
-- one with it.
local function Named(old)
    local name = Core.FullName("player")
    if type(old) == "string" and Core.Surnames() and not Core.PlayerKey("player") then return old end
    return name or old
end

local function Who()
    local entry = mine
    local _, class = Ask(UnitClass, "player")
    local _, _, race = Ask(UnitRace, "player")
    local name, realm, level, side = Named(entry.name), Ask(rawget(_G, "GetRealmName")), Ask(UnitLevel, "player"), Ask(UnitFactionGroup, "player")
    local changed = entry.name ~= name or entry.level ~= level or entry.class ~= class
    entry.name, entry.realm, entry.class, entry.race = name or entry.name or "?", realm or entry.realm, class or entry.class, race or entry.race
    entry.level, entry.side, entry.seen = level or entry.level, side or entry.side, Day() or entry.seen
    if changed then Changed() end
end

local function Money()
    local money = Ask(rawget(_G, "GetMoney"))
    if type(money) == "number" then mine.money = money end
end

-- The game's containers, or nil on a client without them: then nothing is read (and nothing kept is
-- written over with nothing)
local function Containers()
    local api = rawget(_G, "C_Container")
    return api and api.GetContainerNumSlots and api.GetContainerItemInfo and api or nil
end

-- Adds a container's items to map
local function Container(api, bag, map)
    local slots = Ask(api.GetContainerNumSlots, bag)
    for slot = 1, type(slots) == "number" and slots or 0 do
        local info = Ask(api.GetContainerItemInfo, bag, slot)
        local item, count = type(info) == "table" and Plain(info.itemID), type(info) == "table" and Plain(info.stackCount)
        if type(item) == "number" then map[item] = (map[item] or 0) + (type(count) == "number" and count > 0 and count or 1) end
    end
end

-- The bags carried: the backpack, the bags and the reagent bag, and the keyring where the client has one
local function BagCount()
    local constants = rawget(_G, "Constants") and Constants.InventoryConstants
    local bags = constants and constants.NumBagSlots or rawget(_G, "NUM_BAG_SLOTS") or 4
    return bags + (constants and constants.NumReagentBagSlots or 0)
end
local KEYRING = Enum and Enum.BagIndex and Enum.BagIndex.Keyring

local function Bags()
    local api = Containers()
    if not api then return nil end
    local map = {}
    if KEYRING then Container(api, KEYRING, map) end
    for bag = 0, BagCount() do
        Container(api, bag, map)
        Steps.Check()
    end
    return map
end

-- What is worn: the gear and the bags in their slots
local function Worn()
    if not rawget(_G, "GetInventoryItemID") then return nil end
    local map = {}
    local first, last = rawget(_G, "INVSLOT_FIRST_EQUIPPED") or 1, rawget(_G, "INVSLOT_LAST_EQUIPPED") or 19
    local slots = {}
    for slot = first, last do slots[#slots + 1] = slot end
    local api = Containers()
    if api and api.ContainerIDToInventoryID then
        for bag = 1, BagCount() do slots[#slots + 1] = Ask(api.ContainerIDToInventoryID, bag) end
    end
    for _, slot in ipairs(slots) do
        local item = Ask(GetInventoryItemID, "player", slot)
        if type(item) == "number" then map[item] = (map[item] or 0) + 1 end
    end
    return map
end

-- A bank's tabs (Enum.BankType.Character or .Account): the containers the game lists for it
local function Tabs(kind)
    local bank = rawget(_G, "C_Bank")
    if not (bank and kind) then return nil end
    if bank.CanViewBank and Ask(bank.CanViewBank, kind) == false then return nil end
    local ids = Ask(bank.FetchPurchasedBankTabIDs, kind)
    return type(ids) == "table" and ids or nil
end

local function Bank(kind)
    local tabs, api = Tabs(kind), Containers()
    if not (tabs and api) then return nil end
    local map = {}
    for _, bag in ipairs(tabs) do
        Container(api, bag, map)
        Steps.Check()
    end
    return map
end

local BANK_TYPE = Enum and Enum.BankType or {}

-- Puts a place's map into its entry (packed) and into the counts; nil (nothing could be read) keeps
-- what is there
local function Store(key, entry, place, map)
    if not map then return end
    local text = Pack(map)
    if (entry[place] or "") == text then return end
    entry[place] = text ~= "" and text or nil
    parsed[key] = parsed[key] or {}
    parsed[key][place] = map
    Changed()
end

-- What each mark reads
local READ = {
    who = Who,
    money = Money,
    bags = function() Store(Core.charKey, mine, "bags", Bags()) end,
    worn = function() Store(Core.charKey, mine, "worn", Worn()) end,
    bank = function()
        if not bankOpen then return end
        local map = Bank(BANK_TYPE.Character)
        if map then
            Store(Core.charKey, mine, "bank", map)
            mine.bankSeen = Day()
        end
    end,
    account = function()
        if not bankOpen then return end
        local map = Bank(BANK_TYPE.Account)
        if map then
            part.account = type(part.account) == "table" and part.account or {}
            Store(ACCOUNT, part.account, "bank", map)
            part.account.seen = Day()
        end
    end,
}

-- The job: every mark read, one after the other, within the frame's budget
local function Read()
    while part do
        local what = next(marks)
        if not what then return end
        marks[what] = nil
        READ[what]()
        Steps.Check()
    end
end

local function Mark(what)
    marks[what] = true
    if part then Steps.Run(JOB, Read) end
end

-- Every place of every character taken apart, a character at a time: then Count answers
local function Counting()
    for key in pairs(part.characters) do
        for _, place in ipairs(PLACES) do Map(key, place) end
        Steps.Check()
    end
    Map(ACCOUNT, "bank")
    counted = true
    Changed()
end

-------------------------------------------------------------------------------
--  The saved part: checked, then this character's entry
-------------------------------------------------------------------------------

-- A part of a wrong shape is set aside under broken, never wiped (for the harvest to look at)
local function Aside(what, value)
    if type(part.broken) ~= "table" then part.broken = {} end
    part.broken[#part.broken + 1] = { what = tostring(what), value = value }
end

local function Check()
    if type(part.characters) ~= "table" then
        if part.characters ~= nil then Aside("characters", part.characters) end
        part.characters = {}
    end
    for key, entry in pairs(part.characters) do
        if type(key) ~= "string" or type(entry) ~= "table" or type(entry.name) ~= "string" then
            Aside(key, entry)
            part.characters[key] = nil
        else
            for _, place in ipairs(PLACES) do
                if entry[place] ~= nil and type(entry[place]) ~= "string" then
                    Aside(key .. " " .. place, entry[place])
                    entry[place] = nil
                end
            end
        end
    end
    if part.account ~= nil and (type(part.account) ~= "table" or (part.account.bank ~= nil and type(part.account.bank) ~= "string")) then
        Aside(ACCOUNT, part.account)
        part.account = nil
    end
end

-- The pack has loaded (Data.Saved): its part checked, this character's entry made, everything marked
-- read, and the counts worked out.
local function Opened(saved)
    part = saved
    Check()
    mine = part.characters[Core.charKey]
    if not mine then
        mine = { name = Named(nil) or "?" }
        part.characters[Core.charKey] = mine
    end
    marks.who, marks.money, marks.bags, marks.worn = true, true, true, true
    if bankOpen then marks.bank, marks.account = true, true end
    Steps.Run(JOB, Read)
    Steps.Run(COUNTING, Counting)
end

-------------------------------------------------------------------------------
--  What Core gives
-------------------------------------------------------------------------------
local function View(key)
    local view = views[key]
    if view then return view end
    local entry = part and part.characters[key]
    if type(entry) ~= "table" then return nil end
    view = { key = key, name = entry.name, realm = entry.realm, class = entry.class, race = entry.race, level = entry.level,
             side = entry.side, seen = entry.seen, money = entry.money, bankSeen = entry.bankSeen }
    views[key] = view
    return view
end

function Data.Character(key)
    return View(key)
end

function Data.Characters()
    if not part then return nil end
    if list then return list end
    list = {}
    for key in pairs(part.characters) do list[#list + 1] = View(key) end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

function Data.Count(item)
    if not (counted and type(item) == "number") then return nil end
    local known = counts[item]
    if known ~= nil then return known or nil end
    local count, total = nil, 0
    for key in pairs(part.characters) do
        for _, place in ipairs(PLACES) do
            local number = Map(key, place)[item]
            if number then
                count = count or {}
                count[key] = count[key] or {}
                count[key][place] = number
                total = total + number
            end
        end
    end
    local banked = Map(ACCOUNT, "bank")[item]
    if banked then
        count = count or {}
        count[ACCOUNT] = { bank = banked }
        total = total + banked
    end
    if count then count.total = total end
    counts[item] = count or false
    return count
end

function Data.CharactersStamp()
    return stamp
end

function Data.OnCharacters(fn)
    listeners[#listeners + 1] = fn
end

-------------------------------------------------------------------------------
--  Events: marks only
-------------------------------------------------------------------------------
local BANK_FIRST = Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1 or 6
local ACCOUNT_FIRST = Enum and Enum.BagIndex and Enum.BagIndex.AccountBankTab_1 or 15

Core.On("PLAYER_LOGIN", function()
    marks.who, marks.money, marks.bags, marks.worn = true, true, true, true
    Data.Saved(PACK, Opened)
end)
Core.On("BAG_UPDATE", function(bag)
    bag = Plain(bag)
    if type(bag) ~= "number" then return end
    if bag >= ACCOUNT_FIRST then
        marks.account = true
    elseif bag >= BANK_FIRST then
        marks.bank = true
    else
        marks.bags = true
    end
end)
Core.On("BAG_UPDATE_DELAYED", function()
    if part and next(marks) then Steps.Run(JOB, Read) end
end)
Core.On("PLAYER_EQUIPMENT_CHANGED", function() Mark("worn") end)
Core.On("PLAYER_MONEY", function() Mark("money") end)
Core.On("PLAYER_LEVEL_UP", function() Mark("who") end)
Core.On("BANKFRAME_OPENED", function()
    bankOpen = true
    Mark("bank")
    Mark("account")
end)
Core.On("PLAYERBANKSLOTS_CHANGED", function() Mark("bank") end)
Core.On("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", function() Mark("account") end)
-- The bank closes: what is still marked of it is read now, while the game still has it.
Core.On("BANKFRAME_CLOSED", function()
    if part and mine then
        for _, what in ipairs({ "bank", "account" }) do
            if marks[what] then
                marks[what] = nil
                Core.Safe("data: characters", READ[what])
            end
        end
    end
    bankOpen = false
end)
-- The logout: what is still marked is read at once, and the day is noted.
Core.On("PLAYER_LOGOUT", function()
    if not (part and mine) then return end
    for what in pairs(marks) do Core.Safe("data: characters", READ[what]) end
    wipe(marks)
    mine.seen = Day() or mine.seen
end)
