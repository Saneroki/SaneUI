local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Facts
--  What the game shows of creatures, spells, vendors and items as the player meets them, compared with the sets
--  (Data.Check, Doc/guides/data.md, *Checked in play*): what agrees confirmed, what differs or is missing learned.
--
--      a creature   seen (the mouse, the target, a nameplate), out of a fight: its name, level (the set's lowest and
--                   highest widened by a level seen outside them), rank, kind, the health at the level seen; never
--                   one a player controls (a pet, a totem, a guardian takes its master's level)
--      its services talked to: a vendor (and repair), a trainer, a flight master, a banker, an auctioneer, a stable
--                   master, a quest giver
--      a vendor     its goods, as its window lists them: an item it sells that the set does not name added (never one
--                   taken away: a limited good may be sold out). Prices not: they are the player's, after the
--                   discount their standing earns
--      a spell      of the spellbook, or in a tooltip: its name, rank and icon (its cost, cast time and range not:
--                   talents and gear change them for the player)
--      an item      in a tooltip: compared as the items the character has (Watchers.Item)
--
--  Texts (names, ranks, kinds) only on an English client: the sets' are English. Each thing once a session (a
--  creature once for each level seen).
-------------------------------------------------------------------------------
local Data = Core.Data
local Watchers = Data.Watchers

local Facts = {}
Data.Facts = Facts
Facts.TIPS = 20   -- tooltips' items and spells compared a frame at most

local ENGLISH = { enUS = true, enGB = true }
local KINDS = { Beast = "beast", Critter = "critter", Demon = "demon", Dragonkin = "dragonkin", Elemental = "elemental",
    Giant = "giant", Humanoid = "humanoid", Mechanical = "mechanical", Undead = "undead", Totem = "totem",
    ["Not specified"] = "other" }
local RANKS = { normal = true, elite = true, rare = true, rareelite = true, worldboss = true, trivial = true, minus = true }

local NPCs = Data.Set("NPCs")
local seen = {}      -- ["<creature>:<level>"] = true: compared this session
local spells = {}    -- [spell] = true: compared this session
local waiting = { items = {}, spells = {} } -- what tooltips showed, compared a little later

local function English()
    return ENGLISH[Core.Ask(rawget(_G, "GetLocale")) or ""] == true
end

-------------------------------------------------------------------------------
--  Creatures
-------------------------------------------------------------------------------
-- A creature the player sees, compared once for each level.
local function Creature(unit)
    if Core.Restricted() or not NPCs:Ready() then return end
    if Core.Ask(rawget(_G, "UnitIsPlayer"), unit) or Core.Ask(rawget(_G, "UnitPlayerControlled"), unit) then return end
    local kind, id = Watchers.Thing(unit)
    if kind ~= "npc" then return end
    local level = Core.Ask(rawget(_G, "UnitLevel"), unit)
    if type(level) ~= "number" or seen[id .. ":" .. level] then return end
    seen[id .. ":" .. level] = true
    local record, told = NPCs:Get(id), {}
    if level < 0 then
        told.boss = true
    elseif level > 0 then
        local low, high = record and record.levelMin, record and record.levelMax
        if not low or level <= low then told.levelMin = level end
        if not high or level >= high then told.levelMax = level end
        local health = Core.Ask(rawget(_G, "UnitHealthMax"), unit)
        -- 100 is the share the game gives where it hides the real number
        if type(health) == "number" and health > 0 and health ~= 100 then told.health = { [level] = health } end
    end
    local rank = Core.Ask(rawget(_G, "UnitClassification"), unit)
    if RANKS[rank or ""] then told.rank = rank end
    if English() then
        local name = Core.Ask(rawget(_G, "UnitName"), unit)
        if type(name) == "string" and name ~= "" then told.name = name end
        local creature = KINDS[Core.Ask(rawget(_G, "UnitCreatureType"), unit) or ""]
        if creature then told.kind = creature end
    end
    Data.Check("NPCs", id, told)
end
Facts.Creature = Creature

Core.On("UPDATE_MOUSEOVER_UNIT", function() Creature("mouseover") end)
Core.On("PLAYER_TARGET_CHANGED", function() Creature("target") end)
Core.On("NAME_PLATE_UNIT_ADDED", function(unit) if type(unit) == "string" then Creature(unit) end end)

-- A service the NPC talked to gives (the game's unit "npc").
local function Service(service)
    if Core.Restricted() then return end
    local kind, id = Watchers.Thing("npc")
    if kind ~= "npc" then return end
    local list = { service }
    if service == "vendor" and Core.Ask(rawget(_G, "CanMerchantRepair")) then list[2] = "repair" end
    Data.Check("NPCs", id, { services = list })
end

local SERVICES = { TRAINER_SHOW = "trainer", TAXIMAP_OPENED = "flightmaster", BANKFRAME_OPENED = "banker",
    AUCTION_HOUSE_SHOW = "auctioneer", PET_STABLE_SHOW = "stablemaster", QUEST_GREETING = "questgiver",
    QUEST_DETAIL = "questgiver" }
for event, service in pairs(SERVICES) do
    Core.On(event, function() Service(service) end)
end
Core.On("GOSSIP_SHOW", function()
    local gossip = rawget(_G, "C_GossipInfo")
    local available = gossip and Core.Ask(gossip.GetNumAvailableQuests)
    if type(available) == "number" and available > 0 then Service("questgiver") end
end)

-------------------------------------------------------------------------------
--  Vendors
-------------------------------------------------------------------------------
-- The vendor's goods as its window lists them: each item a member of the set's list.
local Goods = Core.Later(function()
    local kind, id = Watchers.Thing("npc")
    if kind ~= "npc" then return end
    local count = Core.Ask(rawget(_G, "GetMerchantNumItems"))
    if type(count) ~= "number" or count <= 0 then return end
    local list = {}
    for index = 1, count do
        local item = Core.Ask(rawget(_G, "GetMerchantItemID"), index)
        if type(item) == "number" and item > 0 then list[#list + 1] = { item = item } end
    end
    if #list > 0 then Data.Check("Vendors", id, { goods = list }) end
end, 0.5)
Core.On("MERCHANT_SHOW", function()
    Service("vendor")
    Goods()
end)

-------------------------------------------------------------------------------
--  Spells
-------------------------------------------------------------------------------
local function Spell(id)
    if type(id) ~= "number" or id <= 0 or spells[id] or not Data.Set("Spells"):Ready() then return end
    local api = rawget(_G, "C_Spell") or {}
    local told = {}
    local icon = Core.Ask(api.GetSpellTexture, id)
    if type(icon) == "number" and icon > 0 then told.icon = icon end
    if English() then
        local name = Core.Ask(api.GetSpellName, id)
        if type(name) ~= "string" or name == "" then return end -- not loaded yet: asked again when shown again
        told.name = name
        local rank = Core.Ask(api.GetSpellSubtext, id)
        if type(rank) == "string" and rank ~= "" then told.rank = rank end
    end
    spells[id] = true
    if next(told) then Data.Check("Spells", id, told) end
end
Facts.Spell = Spell

-- The spells of the player's spellbook, a few a frame (the scheduler), once a session and when one is learnt.
local Book = Core.Later(function()
    local book = rawget(_G, "C_SpellBook")
    local bank = rawget(_G, "Enum") and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    local lines = book and Core.Ask(book.GetNumSpellBookSkillLines)
    if type(lines) ~= "number" or Core.Steps.Running("watch: spells") then return end
    local list = {}
    for line = 1, lines do
        local info = Core.Ask(book.GetSpellBookSkillLineInfo, line)
        local first, many = type(info) == "table" and Core.Plain(info.itemIndexOffset), type(info) == "table" and Core.Plain(info.numSpellBookItems)
        if type(first) == "number" and type(many) == "number" then
            for index = first + 1, first + many do
                local item = Core.Ask(book.GetSpellBookItemInfo, index, bank)
                local spell = type(item) == "table" and Core.Plain(item.actionID)
                if type(spell) == "number" and not spells[spell] then list[#list + 1] = spell end
            end
        end
    end
    if #list == 0 then return end
    Core.Steps.Run({ name = "watch: spells", label = "data: spells" }, function()
        for _, spell in ipairs(list) do
            Spell(spell)
            Core.Steps.Check()
        end
    end)
end, 5)
Core.On("PLAYER_ENTERING_WORLD", function() Book() end)
Core.On("LEARNED_SPELL_IN_SKILL_LINE", function() Book() end)
Core.On("SPELLS_CHANGED", function() Book() end)

-------------------------------------------------------------------------------
--  Tooltips: the items and spells they show
-------------------------------------------------------------------------------
local Tips = Core.Later(function()
    if Core.Restricted() then return end
    local done = 0
    for id in pairs(waiting.items) do
        waiting.items[id] = nil
        Watchers.Item(id)
        done = done + 1
        if done >= Facts.TIPS then break end
    end
    for id in pairs(waiting.spells) do
        if done >= Facts.TIPS then break end
        waiting.spells[id] = nil
        Spell(id)
        done = done + 1
    end
end, 1)

local function Shown(kind)
    return function(_, data)
        local id = type(data) == "table" and Core.Plain(data.id)
        if type(id) ~= "number" then return end
        if kind == "items" or not spells[id] then waiting[kind][id] = true end
        Tips()
    end
end

local processor, types = rawget(_G, "TooltipDataProcessor"), rawget(_G, "Enum") and Enum.TooltipDataType
if processor and processor.AddTooltipPostCall and types then
    if types.Item then processor.AddTooltipPostCall(types.Item, Core.Guard("data: tooltip items", Shown("items"))) end
    if types.Spell then processor.AddTooltipPostCall(types.Spell, Core.Guard("data: tooltip spells", Shown("spells"))) end
end
