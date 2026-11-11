local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Secrecy
--  Which spells the game hides from addons, asked of the game itself, for the
--  developer's lists (saneui showsecrets; Saneroki, 2026-11-11: "a list of
--  spells that are invisible or secret to the addon? And a list which are
--  visible?"). The client's own tables carry no flag to read it from, so
--  /sane secrets asks C_Secrets about every spell there is, out of a fight, a
--  slice of Secrecy.STEP numbers a frame, and keeps the answer in Core's store
--  (SaneUIDB.modules.SaneUI.secrecy), which the game writes at the next
--  /reload. Each spell is asked twice, as an aura (GetSpellAuraSecrecy) and as a
--  cast (GetSpellCastSecrecy); the game's answer is its base secrecy, one of
--      0  NeverSecret         plain, in a fight too
--      1  AlwaysSecret        hidden, out of a fight too
--      2  ContextuallySecret  hidden while a restriction is on: a fight, an
--                             encounter, a keystone, a rated match
--  Kept: the spells of the first two by number with their names; the third,
--  nearly every spell, only counted (saneui showsecrets lists them from the
--  client's spell names). /sane secrets clear forgets it.
-------------------------------------------------------------------------------
local Secrecy = {}
Core.Secrecy = Secrecy

Secrecy.TOP = 1600000 -- the highest spell number asked (Retail's reach past 1.5 million, Forever's past 1.3)
Secrecy.STEP = 20000  -- numbers asked in one frame
Secrecy.KINDS = { aura = "GetSpellAuraSecrecy", cast = "GetSpellCastSecrecy" }

local TEXT = {
    about = "which spells the game hides from addons, asked of the game (/sane secrets clear forgets the answer)",
    missing = "this client cannot tell which spells it hides (C_Secrets or C_Spell is missing).",
    started = "asking the game about every spell; a few seconds, out of a fight.",
    waiting = "paused for the fight; it goes on after it.",
    running = "still asking (%d%%).",
    done = "%d spells asked. As auras: %d never hidden, %d always hidden, %d hidden in a fight. As casts: %d, %d, %d. /reload to write them, then saneui showsecrets.",
    cleared = "the answer is forgotten.",
}

local running, from -- a scan under way, and the first number of its next slice

local function Store()
    return Core.Store(Core.name)
end

local function Asks()
    local secrets, spells = rawget(_G, "C_Secrets"), rawget(_G, "C_Spell")
    if not (secrets and spells and type(spells.DoesSpellExist) == "function") then return nil end
    for _, name in pairs(Secrecy.KINDS) do
        if type(secrets[name]) ~= "function" then return nil end
    end
    return secrets, spells
end

local function Finish(found)
    running = nil
    local store = Store()
    store.secrecy = found
    local aura, cast = found.counts.aura, found.counts.cast
    Core.Print(TEXT.done:format(found.spells, aura[0], aura[1], aura[2], cast[0], cast[1], cast[2]))
end

local Step
local soon = Core.Later(function() Step() end, 0, "secrecy")
local later = Core.Later(function() Step() end, 1, "secrecy")

function Step()
    local found = running
    if not found then return end
    if Core.Restricted() then return later() end -- the answer is the base one, but a fight is no time for this
    local secrets, spells = Asks()
    if not secrets then running = nil return Core.Print(TEXT.missing) end
    local last = math.min(from + Secrecy.STEP - 1, Secrecy.TOP)
    for id = from, last do
        if spells.DoesSpellExist(id) then
            found.spells = found.spells + 1
            for kind, name in pairs(Secrecy.KINDS) do
                local level = Core.Plain(secrets[name](id))
                if type(level) == "number" then
                    found.counts[kind][level] = (found.counts[kind][level] or 0) + 1
                    if level ~= 2 then
                        found[kind][level][id] = Core.Ask(spells.GetSpellName, id) or ""
                    end
                end
            end
        end
    end
    from = last + 1
    if from > Secrecy.TOP then return Finish(found) end
    soon()
end

function Secrecy.Start()
    if running then return Core.Print(TEXT.running:format(math.floor(100 * from / Secrecy.TOP))) end
    if not Asks() then return Core.Print(TEXT.missing) end
    local _, build = Core.Ask(rawget(_G, "GetBuildInfo"))
    running = {
        build = build, game = Core.GAME, day = Core.Ask(rawget(_G, "date"), "%Y-%m-%d"), top = Secrecy.TOP, spells = 0,
        aura = { [0] = {}, [1] = {} }, cast = { [0] = {}, [1] = {} },
        counts = { aura = { [0] = 0, [1] = 0, [2] = 0 }, cast = { [0] = 0, [1] = 0, [2] = 0 } },
    }
    from = 1
    Core.Print(Core.Restricted() and TEXT.waiting or TEXT.started)
    soon()
end

function Secrecy.Clear()
    running = nil
    Store().secrecy = nil
    Core.Print(TEXT.cleared)
end

Core.Command("secrets", TEXT.about, function(rest)
    if rest == "clear" then return Core.Safe("secrecy", Secrecy.Clear) end
    Core.Safe("secrecy", Secrecy.Start)
end)
