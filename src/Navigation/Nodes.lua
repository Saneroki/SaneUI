local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Nodes
--  Herbs and ore: what one is by the name the game shows (Core's sets Objects
--  and Drops), its picture, and the game's two finders, Find Herbs and Find
--  Minerals. Knows no frames.
--
--      Nodes.Find(name)        the herb's or ore's record of Objects ({ key, name, kind, skill, ... }), nil for
--                              anything else (the data has the names in English)
--      Nodes.Picture(node)     the file ID of what it gives (its herb, its ore), nil while not known
--      Nodes.TooHard(node)     whether your skill (with its bonus) is below what it needs, or you have none
--      Nodes.Active()          the kind whose finder is on now ("herb", "ore"), nil for none
--
--  The finders follow the pin filter's kinds Found herbs and Found ore (Apply): the one switched on, the
--  one switched off; with both on and both known they take turns while you move (the setting Find Herbs
--  and Find Minerals in turn: seconds of moving between two turns). Retail's tracking holds both at once
--  (Nodes.TOGETHER): there each is simply on while its kind is, and no turns are taken. Without Core's herbs
--  and ore (Nodes.Known: Retail, until its data comes) nothing is told by its name. A finder is a spell, and
--  switching it sounds as a cast: Sane UI's own switches are silent. The game's effect sounds are off from the switch
--  until the cast went through (a moment later; at most Nodes.QUIET seconds), then as they were; what they
--  were is kept in the store meanwhile, so a /reload in between puts it back (Start).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local OBJECTS, DROPS = Core.Data.Set("Objects"), Core.Data.Set("Drops")
local Nodes = {}
ns.Nodes = Nodes

Nodes.FINDERS = { herb = 2383, ore = 2580 } -- the spells Find Herbs and Find Minerals
Nodes.FOUND = { herb = "foundHerb", ore = "foundOre" } -- the pin filter's kind for each
Nodes.QUIET = 2      -- seconds the effect sounds stay off at most after a switch
Nodes.AFTER = 0.25   -- and how long after the cast went through (its sound comes with it)
Nodes.LOOK = 0.5     -- seconds between two looks whether a turn is due
-- Whether the game's tracking holds both finders at once (Retail's ticks any number of them), so they take no
-- turns; Forever's holds one at a time, as Classic did. Nothing of the game tells it: the game's rule.
Nodes.TOGETHER = Core.RETAIL
local SFX = "Sound_EnableSFX"
local WAIT = "navigation: finders" -- what waits for the fight's end
local HERB, METAL, GOODS = 9, 7, 7 -- the game's item class Trade Goods and its subclasses Herb, Metal & Stone

local named = {}   -- [name] = its record, or false: none
local pictures = {} -- [object key] = file ID, or false: none known yet
local moving = 0   -- seconds moved since the last turn
local ticker, loud

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
            if type(record) == "table" and Nodes.FINDERS[record.kind] then
                known = { key = key, name = record.name, kind = record.kind, skill = record.skill,
                          skillLevel = tonumber(record.skillLevel) or 0 }
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
-- whose finder is on, and [kind] = true for each that is on (both, where the game holds both: Nodes.TOGETHER).
local function Finders()
    local places, on, lit = {}, nil, {}
    local count = Core.Plain(Core.Ask(C_Minimap.GetNumTrackingTypes)) or 0
    for index = 1, count do
        local info = Core.Ask(C_Minimap.GetTrackingInfo, index)
        local spell = type(info) == "table" and Core.Plain(info.spellID)
        for kind, id in pairs(Nodes.FINDERS) do
            if spell == id then
                places[kind] = index
                if Core.Plain(info.active) then on, lit[kind] = kind, true end
            end
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

-- Whether a finder can be cast now: not in a fight, not dead, not casting, not hidden (it would show you),
-- and the global cooldown over (where the game tells it).
local function Free()
    if InCombatLockdown() or UnitIsDeadOrGhost("player") or IsStealthed() then return false end
    if Core.Ask(UnitCastingInfo, "player") or Core.Ask(UnitChannelInfo, "player") then return false end
    local cooldown = Core.Ask(C_Spell.GetSpellCooldown, Nodes.FINDERS.herb)
    local start = type(cooldown) == "table" and Core.Plain(cooldown.startTime)
    local duration = type(cooldown) == "table" and Core.Plain(cooldown.duration)
    return not (start and duration and duration > 0 and start + duration > GetTime())
end

local function Wants(kind)
    return ns.Pins.Shows(Nodes.FOUND[kind])
end

-- Where the game holds both finders (Nodes.TOGETHER): each on while its kind is wanted, off while not; those to go
-- off first, so the sounds stay off for the cast of the one that comes on.
local function Together(places, lit)
    for _, on in ipairs({ false, true }) do
        for _, kind in ipairs({ "herb", "ore" }) do
            if places[kind] and Wants(kind) == on and (lit[kind] or false) ~= on then Switch(places[kind], on) end
        end
    end
end

-- The pin filter's Found herbs and Found ore as the finders: the one on that is no longer wanted gives way to
-- the other kind (if wanted and known) or goes off; none on, the wanted one comes on.
function Nodes.Apply()
    if ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Nodes.Apply) end
    local places, on, lit = Finders()
    if Nodes.TOGETHER then return Together(places, lit) end
    if on and not Wants(on) then
        local other = on == "herb" and "ore" or "herb"
        if Wants(other) and places[other] then
            Switch(places[other], true)
        else
            Switch(places[on], false)
        end
    elseif not on then
        for _, kind in ipairs({ "herb", "ore" }) do
            if Wants(kind) and places[kind] then return Switch(places[kind], true) end
        end
    end
end

-- A look whether a turn is due: both kinds wanted and known, one of them on, and you moved the setting's
-- seconds since the last turn.
local function Look()
    local every = ns.options.nodeTurns
    if not (every and every > 0 and Wants("herb") and Wants("ore")) then return end
    if (Core.Plain(Core.Ask(GetUnitSpeed, "player")) or 0) > 0 then moving = moving + Nodes.LOOK end
    if moving < every or not Free() then return end
    local places, on = Finders()
    local other = on == "herb" and "ore" or on == "ore" and "herb"
    if other and places[other] then Switch(places[other], true) end
end

-- The looks run while turns may come: the setting above 0, both kinds wanted, both finders known, and a game whose
-- finders take turns.
function Nodes.Update()
    local places = Finders()
    local wanted = not ns.off and not Nodes.TOGETHER and (ns.options.nodeTurns or 0) > 0 and Wants("herb")
        and Wants("ore") and places.herb and places.ore
    if wanted and not ticker then
        moving = 0
        ticker = C_Timer.NewTicker(Nodes.LOOK, ns.Guard(Look))
    elseif not wanted and ticker then
        ticker:Cancel()
        ticker = nil
    end
end

-- A finder's cast went through (or failed): the sounds back a moment later, once its own has passed.
local function Cast(_, _, spell)
    if ns.store.sounds == nil then return end
    spell = Core.Plain(spell)
    if spell == Nodes.FINDERS.herb or spell == Nodes.FINDERS.ore then LoudSoon(Nodes.AFTER) end
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
    ns.On("SKILL_LINES_CHANGED", function() wipe(skills) end)
    ns.On("GET_ITEM_INFO_RECEIVED", function() wipe(pictures) end)
    OBJECTS:OnStamp(function() wipe(named) end)
    DROPS:OnStamp(function() wipe(pictures) end)
    Core.Data.Prepare("Objects")
    Nodes.Update()
end

-- The module stood down: no more turns, the sounds as they were.
function Nodes.GiveBack()
    if ticker then ticker:Cancel() end
    ticker = nil
    Loud()
end
