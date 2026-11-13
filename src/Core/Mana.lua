local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Mana
--  A druid's mana in a form, for its group (Saneroki, 2026-11-13: "let my
--  druid send its mana to the party"). The game tells a druid's mana in a form
--  whose power is not mana (rage, energy) to that druid alone: another
--  member's game answers none. So a druid's Sane UI tells its group's Sane UI:
--  a live message of Core's wire (Wire.SendLive, kind Mana.KIND: its mana and
--  its most), at once as it takes such a form or the group changes, then while
--  the mana changes at most every Mana.EVERY seconds, and every Mana.BEAT while
--  it stays the same. Live: in a fight too, where the game lets addon messages
--  go (not in its lockdown of boss fights), never queued. Only to the party,
--  the raid or the instance group, only while in such a form; nothing to turn
--  on.
--
--  Every member's Sane UI keeps what came per player (by key) for Mana.FRESH
--  seconds without a newer one; views read it through Core.Mana(unit) (Kit.lua:
--  what a member shared, else the game's) and Core.FormPower, and hear of it by
--  Core.OnMana(fn): fn(key) when a member's mana came, changed or went.
--
--      Core.SharedMana(unit) -> { now, most, at }   what that member shared, while fresh; nil for yourself
--      Core.OnMana(fn)                             fn(key): a member's shared mana came, changed or went
-------------------------------------------------------------------------------
local Mana = {}
Core.ManaShare = Mana

Mana.KIND = "M"   -- the wire's kind of these messages
Mana.EVERY = 2    -- seconds at least between two messages while the mana changes
Mana.BEAT = 6     -- seconds between two while it stays the same
Mana.FRESH = 15   -- seconds what came is kept without a newer one
Mana.CHANNELS = { PARTY = true, RAID = true, INSTANCE_CHAT = true } -- taken from these channels only

local kept = {}      -- [player key] = { now, most, at }: what members shared
local listeners = {} -- fn(key)
local sent = { at = -math.huge } -- your last message: now, most, at
local frame

local function Now()
    return Core.Ask(GetTime) or 0
end

local function Tell(key)
    for _, fn in ipairs(listeners) do Core.Safe("mana", fn, key) end
end

-- fn(key) whenever a member's shared mana came, changed or went.
function Core.OnMana(fn)
    listeners[#listeners + 1] = fn
end

-- What that unit's own Sane UI shared, while fresh and while the unit shows another power than mana (out of a form the
-- game gives its mana to all); nil for yourself, for anyone who shared nothing, and once stale.
function Core.SharedMana(unit)
    if not next(kept) or Core.Ask(UnitIsUnit, unit, "player") == true then return nil end
    if Core.Ask(UnitPowerType, unit) == Core.MANA then return nil end
    local key = Core.PlayerKey(unit)
    local entry = key and kept[key]
    if not entry then return nil end
    if Now() - entry.at > Mana.FRESH then return nil end
    return entry
end

-- What has gone stale goes, its views told; looked at again while anything is kept.
local Expire
Expire = Core.Later(function()
    local now = Now()
    for key, entry in pairs(kept) do
        if now - entry.at > Mana.FRESH then
            kept[key] = nil
            Tell(key)
        end
    end
    if next(kept) then Expire() end
end, Mana.FRESH / 3, "mana")

-- A number in a message: digits only.
local function Whole(text)
    return type(text) == "string" and text:match("^%d+$") and tonumber(text) or nil
end

-- A member's message: their mana now and most, kept as it came.
local function Heard(sender, fields, channel)
    if not Mana.CHANNELS[channel] then return end
    local now, most = Whole(fields[1]), Whole(fields[2])
    if not now or not most or most <= 0 or now > most then return end
    local entry = kept[sender]
    if entry and entry.now == now and entry.most == most then
        entry.at = Now()
        return
    end
    kept[sender] = { now = now, most = most, at = Now() }
    Tell(sender)
    Expire()
end

-------------------------------------------------------------------------------
--  Yours to your group
-------------------------------------------------------------------------------
-- Your group's channel: the raid's, the party's, an instance group's; nil alone.
local function Group()
    local home = rawget(_G, "LE_PARTY_CATEGORY_HOME")
    local instance = rawget(_G, "LE_PARTY_CATEGORY_INSTANCE")
    if Core.Ask(IsInRaid, home) == true then return "RAID" end
    if Core.Ask(IsInGroup, home) == true then return "PARTY" end
    if instance and Core.Ask(IsInGroup, instance) == true then return "INSTANCE_CHAT" end
end

-- Whether you are a druid (asked of the game: at the login Core may not have told its class yet).
local function Druid()
    local _, class = Core.Ask(UnitClass, "player")
    return class == "DRUID"
end

-- Where your mana goes now: you a druid in a form whose power is not mana, in a group; nil else.
local function Channel()
    if not Druid() then return nil end
    local kind = Core.Ask(UnitPowerType, "player")
    if type(kind) ~= "number" or kind == Core.MANA then return nil end
    return Group()
end

-- A look, a few times a second while it may go: sent once it changed and Mana.EVERY passed, or Mana.BEAT passed.
local waited = 0
local function Look(_, elapsed)
    waited = waited + (elapsed or 0)
    if waited < 0.25 then return end
    waited = 0
    local channel = Channel()
    if not channel then return frame:Hide() end
    local now, most = Core.Ask(UnitPower, "player", Core.MANA), Core.Ask(UnitPowerMax, "player", Core.MANA)
    if type(now) ~= "number" or type(most) ~= "number" or most <= 0 then return end
    now, most = math.floor(now), math.floor(most)
    local clock = Now()
    local wait = (now ~= sent.now or most ~= sent.most) and Mana.EVERY or Mana.BEAT
    if clock - sent.at < wait then return end
    if Core.Wire.SendLive(Mana.KIND, { now, most, n = 2 }, channel) then
        sent.now, sent.most, sent.at = now, most, clock
    end
end

-- Your form or your group changed: the look runs while your mana may go, its next message at once (soon: Mana.EVERY
-- since the last at most, so a burst of changes sends no burst of messages).
local function Again()
    if not Channel() then
        if frame then frame:Hide() end
        return
    end
    if not frame then
        frame = CreateFrame("Frame")
        frame:Hide()
        frame:SetScript("OnUpdate", Core.Guard("mana", Look))
        Mana.frame = frame -- for the tests
    end
    sent.now = nil -- what goes next counts as changed
    waited = 1
    frame:Show()
end
Mana.Again = Again

function Mana.Start()
    if not Core.Wire then return end
    Core.Wire.ListenLive(Mana.KIND, Heard)
    if not Druid() then return end
    Core.OnUnit("UNIT_DISPLAYPOWER", "player", Again)
    Core.On("GROUP_ROSTER_UPDATE", Again)
    Core.On("PLAYER_ENTERING_WORLD", Again)
    Again()
end

Core.On("PLAYER_LOGIN", function() Core.Safe("mana", Mana.Start) end)
