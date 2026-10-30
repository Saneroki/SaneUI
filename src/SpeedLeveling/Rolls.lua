local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Rolls
--  Group rolls decided for you (Saneroki, 2026-10-30, who plays two characters
--  at once, Sane UI on both; the switch Roll on group loot). As a roll starts,
--  each Sane UI of the group says what the thing would bring its character
--  (Core.Upgrade: what it gains, 0 for none or where the game lets it not Need)
--  over Core's addon messages. Then the one it brings the most Needs it and the
--  others Greed, where the game lets them, else Pass. Nobody it brings anything:
--  all Greed. No word from anybody: Need on an upgrade.
--
--  Core's messages wait for the end of a fight on both sides, so a roll started
--  in one waits too, as long as its clock allows (Rolls.LAST); the rest of the
--  time it is decided Rolls.WAIT seconds after the last fight. The game's
--  question on a thing that binds is answered for the rolls made here.
--
--      Rolls.Start()                listens, from the login on
--      Rolls.Heard(sender, fields)  another Sane UI's word: its item, what it brings, its GUID
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Rolls = {}
ns.Rolls = Rolls

Rolls.KIND = "SLR"   -- the addon messages of this
Rolls.WAIT = 2       -- seconds out of a fight before a roll is decided with what was heard
Rolls.LAST = 10000   -- milliseconds left on a roll's clock at which it is decided, fight or no fight
Rolls.TICK = 0.5     -- seconds between looks at the open rolls
Rolls.KEEP = 90      -- seconds a word heard stays good: about as long as a roll lasts

local PASS, NEED, GREED = 0, 1, 2
local EMPTY = {}

local open = {}      -- [rollID] = { item, gain, need, greed, said, quiet (out of a fight since) }
local heard = {}     -- [item] = { { gain, who, when } }
local mine = {}      -- [rollID] = true: rolled here, the game's question is ours to answer
local Look

local function Channel()
    local instance = rawget(_G, "LE_PARTY_CATEGORY_INSTANCE") or 2
    if Core.Ask(rawget(_G, "IsInGroup"), instance) then return "INSTANCE_CHAT" end
    if Core.Ask(rawget(_G, "IsInRaid")) then return "RAID" end
    if Core.Ask(rawget(_G, "IsInGroup")) then return "PARTY" end
    return nil
end

-- What the thing would bring you is said, once the game knows it (late: the clock is running out, as it is).
local function Say(roll, late)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if roll.need and not late and not Core.Ask(info, roll.link) then return end
    local gain
    if roll.need then gain = select(2, Core.Upgrade(roll.link, roll.item)) end
    gain = gain or 0
    roll.gain, roll.said = gain, GetTime()
    local channel = Channel()
    if channel then
        Core.Wire.Send(Rolls.KIND, { roll.item, gain, Core.Ask(UnitGUID, "player") or "" }, channel, nil, true)
    end
end

-- Whether another Sane UI's character gets more of it than yours (of two the same, the lower GUID).
local function Beaten(roll)
    local me, now = Core.Ask(UnitGUID, "player") or "", GetTime()
    for _, word in ipairs(heard[roll.item] or EMPTY) do
        if now - word.when <= Rolls.KEEP and (word.gain > roll.gain or (word.gain == roll.gain and word.who < me)) then
            return true
        end
    end
    return false
end

local function Decide(rollID, roll)
    open[rollID] = nil
    local best = roll.gain > 0 and not Beaten(roll)
    heard[roll.item] = nil
    mine[rollID] = true
    local choice = PASS
    if best and roll.need then choice = NEED elseif roll.greed then choice = GREED end
    Core.Ask(rawget(_G, "RollOnLoot"), rollID, choice)
end

local function Tick()
    local now, any = GetTime(), false
    local fighting = InCombatLockdown()
    for rollID, roll in pairs(open) do
        local left = Plain(Core.Ask(rawget(_G, "GetLootRollTimeLeft"), rollID))
        if ns.off or type(left) ~= "number" or left <= 0 then
            open[rollID] = nil
        else
            if not roll.said then Say(roll, left <= Rolls.LAST) end
            roll.quiet = not fighting and (roll.quiet or now) or nil
            if roll.said and (left <= Rolls.LAST or (roll.quiet and now - roll.quiet >= Rolls.WAIT)) then
                Decide(rollID, roll)
            else
                any = true
            end
        end
    end
    if any then Look() end
end
Look = Core.Later(function() ns.Guarded(Tick) end, Rolls.TICK)

local function Started(rollID)
    rollID = Plain(rollID)
    if ns.off or not ns.options.rolls or open[rollID] then return end
    local link = Plain(Core.Ask(rawget(_G, "GetLootRollItemLink"), rollID))
    local ok, _, _, _, _, _, canNeed, canGreed = pcall(GetLootRollItemInfo, rollID)
    if not ok or type(link) ~= "string" then return end
    open[rollID] = { link = link, item = tonumber(link:match("item:(%d+)")), need = Plain(canNeed) and true or false,
                     greed = Plain(canGreed) and true or false, gain = 0 }
    Tick()
end

function Rolls.Heard(_, fields)
    local item, gain, who = tonumber(fields[1]), tonumber(fields[2]), fields[3]
    if not item or not gain or type(who) ~= "string" then return end
    heard[item] = heard[item] or {}
    table.insert(heard[item], { gain = gain, who = who, when = GetTime() })
end

-- The game asks whether a thing may bind: yes, for a roll made here. Its dialog goes a frame later: the game shows it
-- after telling us.
local HideQuestion = Core.Later(function()
    ns.Guarded(function() Core.Ask(rawget(_G, "StaticPopup_Hide"), "CONFIRM_LOOT_ROLL") end)
end)
local function Asked(rollID, choice)
    rollID = Plain(rollID)
    if not mine[rollID] then return end
    Core.Ask(rawget(_G, "ConfirmLootRoll"), rollID, Plain(choice))
    HideQuestion()
end

function Rolls.Start()
    Core.Wire.Listen(Rolls.KIND, ns.Guard(Rolls.Heard))
    ns.On("START_LOOT_ROLL", Started)
    ns.On("CONFIRM_LOOT_ROLL", Asked)
    ns.On("CONFIRM_DISENCHANT_ROLL", Asked)
    ns.On("CANCEL_LOOT_ROLL", function(rollID)
        rollID = Plain(rollID)
        open[rollID], mine[rollID] = nil, nil
    end)
end
