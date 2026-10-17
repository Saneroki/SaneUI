local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Inspect
--  The item level and the talents of the player a tooltip shows.
--
--  Talents: on this client a class's talents are one tree in three groups
--  ("Balance", "Feral Combat", "Restoration"), each with the points spent in it
--  (C_Traits); the group with the most is the player's spec.
--
--  Yours are the game's at once (GetAverageItemLevel, your active talents).
--  Another player's can only be had by inspecting them: the game asks the server (NotifyInspect)
--  and says when the answer is there (INSPECT_READY). That is paced, so the
--  server is not asked more than it should be:
--    - only out of a fight, when the game allows an inspection (CanInspect) and
--      the player is near enough (CheckInteractDistance);
--    - not while the game's own inspect window is open;
--    - one question at a time, and GAP seconds after anybody's last one (other
--      addons inspect too);
--    - the same player not again for RETRY seconds; an answer is kept KEEP.
--  When the answer comes, the panel of that player's tooltip is drawn anew.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local Inspect = {}
ns.Inspect = Inspect

local KEEP = 300  -- seconds a player's item level is kept
local GAP = 2     -- seconds between two inspections, anybody's
local RETRY = 15  -- seconds before the same player is asked for again
local WAIT = 5    -- an answer that has not come by then is not coming
local LOTS = 200  -- players kept (and asked for) before the old ones are forgotten

local known, count = {}, 0 -- [guid] = { level = , spec = , points = , at = }
local mine = {}            -- your own talents: spec, points, at (asked again after MINE seconds)
local MINE = 5
local asked, askedCount = {}, 0 -- [guid] = when it was last asked for
local pending              -- { guid = , unit = , at = }: the question that waits for its answer
local lastAsked = -GAP     -- anybody's last NotifyInspect

local function InspectWindowOpen()
    local window = rawget(_G, "InspectFrame")
    return window ~= nil and window:IsShown()
end

-- Notes that a player was asked for. Only the last RETRY seconds count: in a long session of many
-- players, the older ones are forgotten.
local function Asked(guid, now)
    if not asked[guid] then askedCount = askedCount + 1 end
    asked[guid] = now
    if askedCount < LOTS then return end
    for old, at in pairs(asked) do
        if now - at >= RETRY then asked[old], askedCount = nil, askedCount - 1 end
    end
end

local function Question(unit, guid, now)
    if now - lastAsked < GAP or (asked[guid] and now - asked[guid] < RETRY) then return false end
    if InCombatLockdown() or InspectWindowOpen() then return false end
    if not (Plain(CanInspect(unit)) and Plain(CheckInteractDistance(unit, 1))) then return false end
    pending = { guid = guid, unit = unit, at = now }
    Asked(guid, now)
    NotifyInspect(unit)
    return true
end

-- A player's spec and points ("Feral Combat", "0/31/20") from a talent configuration: yours
-- (C_ClassTalents.GetActiveConfigID) or the inspected player's (INSPECT_TRAIT_CONFIG_ID). Nil
-- when the client cannot say, or no point is spent.
local function Talents(config)
    local traits = rawget(_G, "C_Traits")
    if not (config and traits) then return nil end
    local info = Ask(traits.GetConfigInfo, config)
    local tree = type(info) == "table" and type(info.treeIDs) == "table" and Plain(info.treeIDs[1])
    if not tree then return nil end
    local groups = Ask(traits.GetGroupDisplayInfoByTreeID, tree)
    if type(groups) ~= "table" or #groups == 0 then return nil end
    local ids = {}
    for index, group in ipairs(groups) do ids[index] = Plain(group.groupID) end
    local spent = Ask(traits.GetGroupCurrencyInfo, config, ids)
    if type(spent) ~= "table" then return nil end
    local points, best, most = {}, nil, 0
    for index, group in ipairs(groups) do
        local count = 0
        for _, entry in ipairs(spent) do
            local currency = Plain(entry.traitNodeGroupID) == ids[index] and type(entry.currencyInfos) == "table" and entry.currencyInfos[1]
            if currency then count = tonumber(Plain(currency.spent)) or 0 end
        end
        points[index] = count
        if count > most then best, most = Plain(group.displayName), count end
    end
    if not best then return nil end
    return best, table.concat(points, "/")
end

local function Keep(guid, level, spec, points)
    if count >= LOTS then
        local now = GetTime()
        for old, entry in pairs(known) do
            if now - entry.at >= KEEP then
                known[old], count = nil, count - 1
            end
        end
    end
    if not known[guid] then count = count + 1 end
    known[guid] = { level = level, spec = spec, points = points, at = GetTime() }
end

-- The item level of a player: a number, or nil. The second value says whether it is on its way
-- (the server was asked). Asks if it may.
function Inspect.Level(unit, guid)
    if Plain(UnitIsUnit(unit, "player")) then
        local _, equipped = GetAverageItemLevel()
        equipped = Plain(equipped)
        return equipped and math.floor(equipped + 0.5) or nil, false
    end
    if not guid then return nil, false end
    local now = GetTime()
    local entry = known[guid]
    -- Talents without an item level (its items were not there yet) are asked for again, paced.
    if entry and entry.level and now - entry.at < KEEP then return entry.level, false end
    if pending and now - pending.at > WAIT then pending = nil end
    if pending then return nil, pending.guid == guid end
    return nil, Question(unit, guid, now)
end

-- A player's spec and its points ("Feral Combat", "0/31/20"), or nil: yours at once, another's
-- once inspected (Level asks).
function Inspect.Talents(unit, guid)
    if Plain(UnitIsUnit(unit, "player")) then
        local now = GetTime()
        if not mine.at or now - mine.at >= MINE then
            local classTalents = rawget(_G, "C_ClassTalents")
            mine.spec, mine.points = Talents(classTalents and Ask(classTalents.GetActiveConfigID))
            mine.at = now
        end
        return mine.spec, mine.points
    end
    local entry = guid and known[guid]
    if entry and GetTime() - entry.at < KEEP then return entry.spec, entry.points end
    return nil
end

-- Listens for the answers. arrived(guid): an item level or talents are there.
function Inspect.Start(arrived)
    if not (NotifyInspect and C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel) then return end
    hooksecurefunc("NotifyInspect", function() lastAsked = GetTime() end)
    SaneUI.Core.On("INSPECT_READY", function(guid)
        guid = Plain(guid)
        if not (pending and guid and pending.guid == guid) then return end
        local unit, at = pending.unit, pending.at
        pending = nil
        if Plain(UnitGUID(unit)) ~= guid then unit = UnitTokenFromGUID and Plain(UnitTokenFromGUID(guid)) end
        local level = unit and Plain(C_PaperDollInfo.GetInspectItemLevel(unit))
        local consts = rawget(_G, "Constants")
        local spec, points = Talents(consts and consts.TraitConsts and consts.TraitConsts.INSPECT_TRAIT_CONFIG_ID)
        -- The answer is read: what was inspected is let go, unless the game's inspect window shows it
        -- or somebody else (another addon) has asked for an inspection since ours.
        if not InspectWindowOpen() and ClearInspectPlayer and lastAsked <= at then ClearInspectPlayer() end
        level = type(level) == "number" and level > 0 and math.floor(level + 0.5) or nil
        if level or spec then
            Keep(guid, level, spec, points)
            arrived(guid)
        end
    end)
end
