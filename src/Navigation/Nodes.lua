local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Nodes
--  Herbs and ore: what one is by the name the game shows (Core's sets Objects
--  and Drops), its picture, and the game's three finders, Find Herbs, Find
--  Minerals and Find Fish. Knows no frames.
--
--      Nodes.Find(name)        the herb's or ore's record of Objects ({ key, name, kind, skill, ... }), nil for
--                              anything else (the data has the names in English)
--      Nodes.Picture(node)     the file ID of what it gives (its herb, its ore), nil while not known
--      Nodes.TooHard(node)     whether your skill (with its bonus) is below what it needs, or you have none
--      Nodes.Active()          the kind whose finder is on now ("herb", "ore", "fish"), nil for none
--      Nodes.Wanted()          the kinds the pin filter wants found, as one string ("herb fish")
--
--  The finders follow the pin filter's kinds Found herbs, Found ore and Found fishing pools (Apply): the one
--  switched on, the one switched off. With two or more on and their spells known they take turns while you move,
--  herbs, ore, fish and round again, those not wanted or not known left out (the setting Switch finders every:
--  yards moved between two turns, 15 at first). Dying takes Forever's tracking: alive again, the first finder wanted comes back on as
--  soon as it can be cast (Revived), and the turns go on from it. Retail's tracking holds them all at once and keeps
--  them through death (Nodes.TOGETHER): there each is simply on while its kind is, and no turns are taken. Fishing
--  pools are no records of Core's: the game's own minimap dots show them, and only herbs and ore are told by their
--  names (Nodes.DRAWN). Without Core's herbs and ore (Nodes.Known: Retail, until its data comes) nothing is told by
--  its name. A finder is a spell, and
--  switching it sounds as a cast: Sane UI's own switches are silent. The game's effect sounds are off from the switch
--  until the cast went through (a moment later; at most Nodes.QUIET seconds), then as they were; what they
--  were is kept in the store meanwhile, so a /reload in between puts it back (Start).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local OBJECTS, DROPS = Core.Data.Set("Objects"), Core.Data.Set("Drops")
local Nodes = {}
ns.Nodes = Nodes

-- The finders in the order they take turns, each kind's spell (Find Herbs, Find Minerals, Find Fish), and the kind by
-- spell: Retail's tracking may list the first two by spells of their own (Blizzard_Minimap's list of tracking icons).
Nodes.ORDER = { "herb", "ore", "fish" }
Nodes.FINDERS = { herb = 2383, ore = 2580, fish = 43308 }
Nodes.KIND = { [2383] = "herb", [8387] = "herb", [2580] = "ore", [8388] = "ore", [43308] = "fish" }
Nodes.FOUND = { herb = "foundHerb", ore = "foundOre", fish = "foundFish" } -- the pin filter's kind for each
Nodes.DRAWN = { herb = true, ore = true } -- the kinds Core's Objects names (and Found.lua draws)
Nodes.QUIET = 2      -- seconds the effect sounds stay off at most after a switch
Nodes.AFTER = 0.25   -- and how long after the cast went through (its sound comes with it)
Nodes.LOOK = 0.5     -- seconds between two looks whether a turn is due
Nodes.REVIVE = 10    -- seconds a finder is tried after you are alive again, until it can be cast
-- Whether the game's tracking holds both finders at once (Retail's ticks any number of them), so they take no
-- turns; Forever's holds one at a time, as Classic did. Nothing of the game tells it: the game's rule.
Nodes.TOGETHER = Core.RETAIL
local SFX = "Sound_EnableSFX"
local WAIT = "navigation: finders" -- what waits for the fight's end
local HERB, METAL, GOODS = 9, 7, 7 -- the game's item class Trade Goods and its subclasses Herb, Metal & Stone

local named = {}   -- [name] = its record, or false: none
local pictures = {} -- [object key] = file ID, or false: none known yet
local moving = 0   -- yards moved since the last turn
local ticker, loud, reviving

-------------------------------------------------------------------------------
--  What a herb or ore is
-------------------------------------------------------------------------------
function Nodes.Find(name)
    if type(name) ~= "string" or name == "" or not OBJECTS:Ready() then return nil end
    local known = named[name]
    if known == nil then
        known = false
        for _, key in ipairs(OBJECTS:Keys("byName", name)) do
            local record = OBJECTS:Get(key)
            if type(record) == "table" and Nodes.DRAWN[record.kind] then
                known = { key = key, name = record.name, kind = record.kind, skill = record.skill,
                          skillLevel = tonumber(record.skillLevel) or 0, yellowAt = record.yellowAt,
                          greyAt = record.greyAt }
                break
            end
        end
        named[name] = known
    end
    return known or nil
end

-- Whether herbs and ore can be told by their names here: Core's set Objects is there (not in Retail, until its data
-- comes: the sparkles and the far ones stand down then).
function Nodes.Known()
    return ns.Has("Objects")
end

-- Whether a word stands in a name as a word of its own.
local function HasWord(name, word)
    return (" " .. name .. " "):find(" " .. word .. " ", 1, true) ~= nil
end

-- The picture of a node: of what it gives by gathering, the herb or the ore (an ore vein gives stone and gems
-- too): the one whose first word the node's name has ("Copper Ore" of a Copper Vein), else the first herb or
-- ore. Item names the game has not told yet are asked for; until then the first is taken, not kept.
function Nodes.Picture(node)
    local known = pictures[node.key]
    if known ~= nil then return known or nil end
    local entry = DROPS:Get("object:" .. node.key)
    if type(entry) ~= "table" then return nil end
    local first, waiting
    for _, drop in ipairs(type(entry.items) == "table" and entry.items or {}) do
        local item = type(drop) == "table" and drop.how == "gather" and drop.item
        if item then
            -- (Core.Ask gives three answers: these are its fifth to seventh)
            local ok, _, _, _, _, icon, class, subclass = pcall(C_Item.GetItemInfoInstant, item)
            icon, class, subclass = Core.Plain(icon), Core.Plain(class), Core.Plain(subclass)
            if ok and icon and class == GOODS and (subclass == HERB or subclass == METAL) then
                first = first or icon
                local name = Core.Plain(Core.Ask(C_Item.GetItemNameByID, item))
                if type(name) == "string" then
                    if HasWord(node.name or "", name:match("^(%S+)") or name) then
                        pictures[node.key] = icon
                        return icon
                    end
                else
                    waiting = true
                    Core.Ask(C_Item.RequestLoadItemDataByID, item)
                end
            end
        end
    end
    if not waiting then pictures[node.key] = first or false end
    return first
end

local skills = {} -- [skill line] = what you reach with its bonus, or false: not learned

function Nodes.TooHard(node)
    local skill = node.skill
    local lines = rawget(_G, "C_SkillInfo")
    -- A game that tells no skill line's rank (Retail): none greyed, rather than all.
    if not skill or not (lines and lines.GetSkillLineInfoByID) then return false end
    local reach = skills[skill]
    if reach == nil then
        reach = false
        local info = Core.Ask(lines.GetSkillLineInfoByID, skill)
        local rank = type(info) == "table" and Core.Plain(info.rank)
        if type(rank) == "number" and rank > 0 then
            local bonus = Core.Plain(info.modifier)
            reach = rank + (type(bonus) == "number" and bonus or 0)
        end
        skills[skill] = reach
    end
    return not reach or reach < node.skillLevel
end

-------------------------------------------------------------------------------
--  The finders
-------------------------------------------------------------------------------
-- The finders the game lists for this character: [kind] = its place in the game's tracking list, the kind
-- whose finder is on, and [kind] = true for each that is on (all, where the game holds them all: Nodes.TOGETHER).
local function Finders()
    local places, on, lit = {}, nil, {}
    local count = Core.Plain(Core.Ask(C_Minimap.GetNumTrackingTypes)) or 0
    for index = 1, count do
        local info = Core.Ask(C_Minimap.GetTrackingInfo, index)
        local kind = type(info) == "table" and Nodes.KIND[Core.Plain(info.spellID) or 0]
        if kind then
            places[kind] = index
            if Core.Plain(info.active) then on, lit[kind] = kind, true end
        end
    end
    return places, on, lit
end

-- The kind whose finder is on, as the game told it last: asked once, then again only after the game says its
-- tracking changed (or a switch of ours), not each time Found.lua looks (every frame the game's minimap shows).
local active, told = nil, false
function Nodes.Active()
    if not told then active, told = select(2, Finders()), true end
    return active
end

local function Changed()
    told = false
end

-- The effect sounds as they were before the switch.
local function Loud()
    if loud then loud:Cancel() end
    loud = nil
    local was = ns.store and ns.store.sounds
    if was == nil then return end
    ns.store.sounds = nil
    if Core.Plain(Core.Ask(C_CVar.GetCVar, SFX)) == "0" then Core.Ask(C_CVar.SetCVar, SFX, was) end
end

local function LoudSoon(seconds)
    if loud then loud:Cancel() end
    loud = C_Timer.NewTimer(seconds, function() ns.Safe("sounds back", Loud) end)
end

-- The effect sounds off for a switch (only when they are on: nothing to silence otherwise).
local function Quiet()
    if ns.store.sounds == nil then
        local now = Core.Plain(Core.Ask(C_CVar.GetCVar, SFX))
        if now ~= "1" then return end
        ns.store.sounds = now
        Core.Ask(C_CVar.SetCVar, SFX, "0")
    end
    LoudSoon(Nodes.QUIET)
end

-- One finder on (the game has one tracking of these at a time) or off, silently.
local function Switch(index, on)
    Quiet()
    Core.Ask(C_Minimap.SetTracking, index, on)
    Changed()
    if not on then LoudSoon(Nodes.AFTER) end -- (no cast comes to wait for)
    moving = 0
end

-- Whether a kind's finder can be cast now: not in a fight, not dead, not casting, not hidden (it would show you),
-- and the global cooldown over (where the game tells it).
local function Free(kind)
    if InCombatLockdown() or UnitIsDeadOrGhost("player") or IsStealthed() then return false end
    if Core.Ask(UnitCastingInfo, "player") or Core.Ask(UnitChannelInfo, "player") then return false end
    local cooldown = Core.Ask(C_Spell.GetSpellCooldown, Nodes.FINDERS[kind] or Nodes.FINDERS.herb)
    local start = type(cooldown) == "table" and Core.Plain(cooldown.startTime)
    local duration = type(cooldown) == "table" and Core.Plain(cooldown.duration)
    return not (start and duration and duration > 0 and start + duration > GetTime())
end

local function Wants(kind)
    return ns.Pins.Shows(Nodes.FOUND[kind])
end

function Nodes.Wanted()
    local list = {}
    for _, kind in ipairs(Nodes.ORDER) do
        if Wants(kind) then list[#list + 1] = kind end
    end
    return table.concat(list, " ")
end

-- The kinds that take turns: wanted and known, in their order.
local function Turning(places)
    local list = {}
    for _, kind in ipairs(Nodes.ORDER) do
        if places[kind] and Wants(kind) then list[#list + 1] = kind end
    end
    return list
end

-- The kind after this one in turn, round to the first (the first, where this one is not among them); nil where
-- it is the only one.
local function After(list, kind)
    for index, each in ipairs(list) do
        if each == kind then
            local after = list[index % #list + 1]
            return after ~= kind and after or nil
        end
    end
    return list[1]
end

-- Where the game holds them all (Nodes.TOGETHER): each on while its kind is wanted, off while not; those to go
-- off first, so the sounds stay off for the cast of the one that comes on.
local function Together(places, lit)
    for _, on in ipairs({ false, true }) do
        for _, kind in ipairs(Nodes.ORDER) do
            if places[kind] and Wants(kind) == on and (lit[kind] or false) ~= on then Switch(places[kind], on) end
        end
    end
end

-- The pin filter's Found herbs, Found ore and Found fishing pools as the finders: the one on that is no longer
-- wanted gives way to the first kind wanted and known, or goes off; none on, the first wanted and known comes on.
function Nodes.Apply()
    if ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Nodes.Apply) end
    local places, on, lit = Finders()
    if Nodes.TOGETHER then return Together(places, lit) end
    if on and Wants(on) then return end
    local first = Turning(places)[1]
    if first then
        Switch(places[first], true)
    elseif on then
        Switch(places[on], false)
    end
end

-- A look whether a turn is due: a finder on, and you moved the setting's yards since the last turn (your speed in
-- yards a second at each look); the next kind in turn then, as soon as it can be cast. A tracking of another kind
-- you chose (Track Beasts) is left as it is: no finder is on then.
local function Look()
    local yards = ns.options.nodeYards
    if not (yards and yards > 0) then return end
    moving = moving + (Core.Plain(Core.Ask(GetUnitSpeed, "player")) or 0) * Nodes.LOOK
    if moving < yards then return end
    local places, on = Finders()
    local after = on and After(Turning(places), on)
    if after and Free(after) then Switch(places[after], true) end
end

-- The looks run while turns may come: the setting above 0, two or more kinds wanted and their finders known, and a
-- game whose finders take turns.
function Nodes.Update()
    local wanted = not ns.off and not Nodes.TOGETHER and (ns.options.nodeYards or 0) > 0
        and #Turning((Finders())) >= 2
    if wanted and not ticker then
        moving = 0
        ticker = C_Timer.NewTicker(Nodes.LOOK, ns.Guard(Look))
    elseif not wanted and ticker then
        ticker:Cancel()
        ticker = nil
    end
end

-- Alive again (dying took Forever's tracking): the first finder wanted and known back on, tried at each look for
-- Nodes.REVIVE seconds until it can be cast; none where a finder is on already. Releasing your spirit tells it
-- too: the tries run out while you are a ghost, and your corpse or the spirit healer tells it again.
local function Stop()
    if reviving then reviving:Cancel() end
    reviving = nil
end

local function Revived()
    Stop()
    if ns.off or Nodes.TOGETHER then return end
    local tries = Nodes.REVIVE / Nodes.LOOK
    reviving = C_Timer.NewTicker(Nodes.LOOK, ns.Guard(function()
        tries = tries - 1
        local places, on = Finders()
        local first = Turning(places)[1]
        if ns.off or on or not first then return Stop() end
        if Free(first) then
            Switch(places[first], true)
            Stop()
        elseif tries <= 0 then
            Stop()
        end
    end))
end

-- A finder's cast went through (or failed): the sounds back a moment later, once its own has passed.
local function Cast(_, _, spell)
    if ns.store.sounds == nil then return end
    if Nodes.KIND[Core.Plain(spell) or 0] then LoudSoon(Nodes.AFTER) end
end

function Nodes.Start()
    -- Sounds left off by a /reload in the middle of a switch.
    Loud()
    Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", Cast)
    Core.OnUnit("UNIT_SPELLCAST_FAILED", "player", Cast)
    -- The finder that is on asked again after the game's tracking changed: its list, a spell learnt, a loading screen.
    ns.On("MINIMAP_UPDATE_TRACKING", Changed)
    ns.On("SPELLS_CHANGED", Changed)
    ns.On("PLAYER_ENTERING_WORLD", Changed)
    ns.On("SPELLS_CHANGED", Nodes.Update)
    -- Alive again: by another's resurrection, at your corpse or by the spirit healer.
    ns.On("PLAYER_ALIVE", Revived)
    ns.On("PLAYER_UNGHOST", Revived)
    ns.On("SKILL_LINES_CHANGED", function() wipe(skills) end)
    ns.On("GET_ITEM_INFO_RECEIVED", function() wipe(pictures) end)
    OBJECTS:OnStamp(function() wipe(named) end)
    DROPS:OnStamp(function() wipe(pictures) end)
    Core.Data.Prepare("Objects")
    Nodes.Update()
end

-- The module stood down: no more turns nor tries, the sounds as they were.
function Nodes.GiveBack()
    if ticker then ticker:Cancel() end
    ticker = nil
    Stop()
    Loud()
end
