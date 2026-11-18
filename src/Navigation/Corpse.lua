local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Corpse
--  While you are dead, the game's map pin stands where you died, so the golden
--  line leads you back to your corpse; alive again, the pin you had before comes
--  back (Saneroki, 2026-11-10: "when you die the map pin is changed to where you
--  died and once you live again your map pin changes to where it has been
--  before"). No frames.
--
--      dead          the pin you had (or none) kept for the character (its saved corpse: a /reload or a logout
--                    while dead keeps it), the pin put where you fell, followed by the game's arrow
--      a ghost       the pin moved onto the corpse where the game tells it (C_DeathInfo.GetCorpseMapPosition, on
--                    the map you died on, else the one you stand on: a dungeon's corpse at its door), looked at
--                    again a moment after the release; the line from the spirit healer to it, on foot or by ship
--                    (the planner takes no flight, teleport or hearthstone for a ghost, Planner.Ghost)
--      alive again   by your corpse, the spirit healer or another's resurrection: the pin you had back as it was
--                    (followed or not), or none where you had none; a pin you set while dead stays yours
--
--  Where the game takes no pin (a dungeon's own map takes none) and tells no corpse, the pin stays as it is.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Live = ns.Live
local Corpse = {}
ns.Corpse = Corpse

Corpse.SAME = 0.002 -- a part of the map so near the corpse's pin that the pin there is still ours
Corpse.AGAIN = 2    -- seconds after a release (or a loading screen as a ghost) the corpse is looked for again

-- The character's saved corpse: { pin = { map, x, y, tracked } or false (none), died (the map one died on), at = { map,
-- x, y } (the pin put at the corpse, nil while none) }, nil while alive. Kept(false) forgets it.
local function Kept(value)
    local character = Core.Character(ns.name)
    if value ~= nil then character.corpse = value or nil end
    return character.corpse
end

local function Dead()
    return Core.Plain(UnitIsDeadOrGhost("player")) == true
end

local function Spirit()
    return Core.Plain(UnitIsGhost("player")) == true
end

-- Whether the game's pin is the one put at the corpse (not one set since).
local function Ours(at)
    local map, x, y = Live.Waypoint()
    return at ~= nil and map == at.map and math.abs(x - at.x) <= Corpse.SAME and math.abs(y - at.y) <= Corpse.SAME
end

-- The pin put at the corpse, followed by the game's arrow; true where the game took it.
local function Put(kept, map, x, y)
    if type(x) ~= "number" or type(y) ~= "number" or not Live.SetWaypoint(map, x, y) then return false end
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    kept.at = { map = map, x = x, y = y }
    Kept(kept)
    return true
end

-- A point of the game's (a Vector2D) as x, y; nil where it is none.
local function XY(position)
    if type(position) ~= "table" or not position.GetXY then return nil end
    local x, y = position:GetXY()
    x, y = Core.Plain(x), Core.Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

-- The pin one had back, as it was, or none where one had none; only while the pin is still the corpse's.
local function Back(kept)
    if not (kept.at and Ours(kept.at)) then return end
    local pin = kept.pin
    if pin and Live.SetWaypoint(pin.map, pin.x, pin.y) then
        C_SuperTrack.SetSuperTrackedUserWaypoint(pin.tracked and true or false)
    else
        Live.ClearWaypoint()
    end
end

-- Dead: the pin one had kept (once: not again after a /reload while dead), the pin put where one fell (not yet
-- released: one stands at the corpse).
local function Died()
    if not Dead() then return end
    local kept = Kept()
    local here = Core.Ask(C_Map.GetBestMapForUnit, "player")
    if not kept then
        local map, x, y = Live.Waypoint()
        kept = { pin = map and { map = map, x = x, y = y, tracked = Live.Tracked() } or false, died = here }
        Kept(kept)
    end
    if kept.at or Spirit() or not here then return end
    Put(kept, here, XY(Core.Ask(C_Map.GetPlayerMapPosition, here, "player")))
end

-- A ghost: the pin onto the corpse where the game tells it, while the pin there is still ours (or none was put).
local function Ghost()
    local kept = Kept()
    if not kept or not Spirit() then return end
    if kept.at and not Ours(kept.at) then return end
    local maps = { kept.died, Core.Ask(C_Map.GetBestMapForUnit, "player") }
    for index = 1, 2 do
        local map = maps[index]
        local x, y = XY(map and Core.Ask(C_DeathInfo.GetCorpseMapPosition, map))
        if x then
            local at = kept.at
            if at and at.map == map and math.abs(x - at.x) <= Corpse.SAME and math.abs(y - at.y) <= Corpse.SAME then return end
            if Put(kept, map, x, y) then return end
        end
    end
end
local later = Core.Later(function() ns.Guarded(Ghost) end, Corpse.AGAIN)

-- Alive again: the pin one had back (Back), the saved corpse forgotten.
local function Revived()
    local kept = Kept()
    if not kept or Dead() then return end
    Kept(false)
    Back(kept)
end

-- Dead, a ghost or alive again, as the game says it now.
function Corpse.Look()
    if not Dead() then return Revived() end
    if not Spirit() then return Died() end
    if not Kept() then Died() end -- a ghost the map saw not die (none kept): its pin kept now
    Ghost()
    later()
end

function Corpse.Start()
    ns.On("PLAYER_DEAD", Died)
    -- PLAYER_ALIVE: the spirit released (a ghost), or raised by another before that (alive).
    ns.On("PLAYER_ALIVE", Corpse.Look)
    ns.On("PLAYER_UNGHOST", Revived)
    -- After the loading screen of a release, at login or a /reload: as one stands now.
    ns.On("PLAYER_ENTERING_WORLD", Corpse.Look)
end

-- The module stands down (ns.GiveBack): the pin one had back, as at a revival.
function Corpse.GiveBack()
    local kept = Kept()
    if not kept then return end
    Kept(false)
    Back(kept)
end
