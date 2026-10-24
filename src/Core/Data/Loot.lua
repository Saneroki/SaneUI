local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Loot
--  What every loot window teaches (Doc/guides/data.md, *Counted in play*), counted into the build's tally
--  (Tally.lua): one loot for each corpse, node or chest it came from and how (looted, skinned or gathered from the
--  corpse, picked from a pocket, gathered, fished), and each item it gave, so that the harvest can work out the
--  chance per corpse looted from every player's loots together. Where it was: a cell of the map for a creature (a
--  corpse lies where the fight ended), a point for a node or a chest (gathered from a few yards off).
--
--  - **The source** is the game's own word for each slot (GetLootSourceInfo: the GUIDs of the corpses or things
--    the slot came from, several at once when looting many corpses together). Without it nothing is counted: a
--    creature is never guessed from the target. Fishing has no source of its own: its loot counts for the zone
--    ("zone:<map>"), and a container opened in the bags for nothing.
--  - **Each source once a way:** a corpse looted again without a cast in between is the same loot window opened
--    again; right after a cast that gathers (Skinning, Herb Gathering, Mining: by their names in the set Spells) it is
--    gathered from the corpse ("skin"). Picking a pocket is the cast Pick Pocket before the window; a node or a chest
--    counts once for each cast that opened it.
--  - **Items a quest asks for** (an objective of a quest in the log, not done yet, whose text names the item) count for
--    those on that quest: one loot more for each such quest, so their chance is the chance while on it.
-------------------------------------------------------------------------------
local Data = Core.Data
local Tally, QuestWatch = Data.Tally, Data.QuestWatch

local Loot = {}
Data.Loot = Loot
Loot.CORPSE = 900   -- seconds a source looted is remembered (each corpse counts once)
Loot.CAST = 3       -- seconds before the window within which the player's cast is what opened it
Loot.blind = nil    -- true once the game showed it gives no source per slot: nothing counted

local PICKPOCKET = { [921] = true } -- the game's spell Pick Pocket
-- The casts that gather from a corpse or a node, by their names in the set Spells
local GATHER = { Skinning = true, ["Herb Gathering"] = true, Herbalism = true, Mining = true }
local Objects, Spells = Data.Set("Objects"), Data.Set("Spells")

local sources = {}  -- [GUID] = { at = GetTime() of its last count, hows = { [how] = true }, cast = the cast counted }
local cast          -- the player's last spell that went off: { spell, at }

Core.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spell)
    if unit ~= "player" then return end
    cast = { spell = Core.Plain(spell), at = GetTime() }
end)

-- The kind and ID a GUID names: "npc" for a creature, "object" for a thing; nil for anything else.
local function Source(guid)
    if type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind == "Creature" or kind == "Vehicle" then return "npc", tonumber(id) end
    if kind == "GameObject" then return "object", tonumber(id) end
    return nil
end
Loot.Source = Source

-- Whether a cast gathers from a corpse or a node: its name in the set Spells (English, whatever the client's language).
local function Gathering(recent)
    if not (recent and type(recent.spell) == "number" and Spells:Ready()) then return false end
    return GATHER[Spells:Get(recent.spell, "name") or ""] == true
end

-- How a source was looted now, or nil when this window is one counted before (opened again).
local function How(guid, kind, id, now)
    local known = sources[guid]
    if known and now - known.at > Loot.CORPSE then known = nil end
    local recent = cast and now - cast.at <= Loot.CAST and cast or nil
    if known and recent and known.cast == recent then recent = nil end -- the cast counted already
    local how
    if kind == "object" then
        if known and not recent then return nil end
        local family = Objects:Ready() and Objects:Get(id, "kind")
        how = (family == "herb" or family == "ore" or Gathering(recent)) and "gather" or "loot"
    elseif recent and PICKPOCKET[recent.spell] then
        how = "pickpocket"
    elseif Gathering(recent) then
        how = "skin"
    elseif not (known and known.hows.loot) then
        how = "loot"
    else
        return nil
    end
    if known and known.hows[how] and kind ~= "object" then return nil end
    known = known or { hows = {} }
    known.at, known.hows[how], known.cast = now, true, recent
    sources[guid] = known
    return how
end

-- The slots of the open window: [source GUID] = { [item] = units }, the money's sources too (a corpse with only money
-- was looted all the same), and the items' names; nil when the game names no sources.
local function Slots(fishing)
    local count = Core.Ask(rawget(_G, "GetNumLootItems")) or 0
    local bySource, names, all = {}, {}, {}
    local sourceOf = rawget(_G, "GetLootSourceInfo")
    if not sourceOf and not fishing then
        Loot.blind = true
        return nil
    end
    for slot = 1, count do
        local link = Core.Ask(rawget(_G, "GetLootSlotLink"), slot)
        local item = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
        local _, name, units = Core.Ask(rawget(_G, "GetLootSlotInfo"), slot)
        units = math.max(1, tonumber(units) or 1)
        if item then
            all[item] = (all[item] or 0) + units
            if type(name) == "string" then names[item] = name end
        end
        if sourceOf then
            local answers = { pcall(sourceOf, slot) }
            if answers[1] then
                for index = 2, #answers, 2 do
                    local guid, many = Core.Plain(answers[index]), Core.Plain(answers[index + 1])
                    if type(guid) == "string" then
                        local items = bySource[guid] or {}
                        bySource[guid] = items
                        if item then items[item] = (items[item] or 0) + (tonumber(many) or units) end
                    end
                end
            end
        end
    end
    return bySource, names, all
end

-- The quest an item counts for: one in the log, not done, whose objective's words are the item's name; else 0.
local function QuestOf(wanting, name)
    for quest, words in pairs(wanting) do
        if name and words[name] then return quest end
    end
    return 0
end

local function Count(key, how, items, names, wanting)
    Tally.Loot(key, how, 0)
    if how == "loot" then
        for quest in pairs(wanting) do Tally.Loot(key, how, quest) end
    end
    for item, units in pairs(items) do
        Tally.Drop(key, how, item, how == "loot" and QuestOf(wanting, names[item]) or 0, units)
        if QuestWatch and names[item] then QuestWatch.Looted(item, names[item]) end
    end
end

local function Opened(_, fromItem)
    if Core.Plain(fromItem) then return end -- a container opened in the bags: no source of the world's
    local fishing = Core.Ask(rawget(_G, "IsFishingLoot")) == true
    local bySource, names, all = Slots(fishing)
    if not bySource then return end
    local wanting = QuestWatch and QuestWatch.Wanting() or {}
    local map, x, y = Tally.Here()
    if fishing then
        if map then Count("zone:" .. map, "fish", all, names, {}) end
        return
    end
    local now = GetTime()
    for guid, items in pairs(bySource) do
        local kind, id = Source(guid)
        local how = kind and id and How(guid, kind, id, now)
        if how then
            local key = kind .. ":" .. id
            Count(key, how, items, names, wanting)
            if map and kind == "npc" and how == "loot" then Tally.Cell(key, map, x, y) end
            if map and kind == "object" then Tally.Point(key, map, x, y) end
        end
    end
end
Core.On("LOOT_OPENED", Opened)
Loot.Opened = Opened
