-------------------------------------------------------------------------------
--  Sane UI - Core - Sync - Layout: which Edit Mode layout is in use
--  Kept by its name and kind (the game numbers its layouts in a list that is
--  not the same on every character). Read from Edit Mode's manager, the game's
--  own state of it (its list: the game's presets first, then the saved layouts;
--  and which one is active). Set through C_EditMode: the manager answers the
--  game's event itself, as when the player picks a layout in Edit Mode. That
--  answer runs in our call and moves the game's frames under our taint, so a
--  /reload is offered.
--
--  At the logout the game no longer says which layout was in use (it says the
--  first preset), so the layout is read only while the character is in the
--  world, and the last one seen is kept. One that cannot be set yet (the
--  manager has no layouts yet, Edit Mode is open, a fight) waits and counts as
--  the one in use meanwhile. One that is not there (deleted, another
--  character's own) leaves the layout in use as it is, and still counts as the
--  one kept until the layout in use changes this session (the player picks
--  one): this character's own does not take its place at the logout.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sync = Core.Sync -- Sync.lua

local ID = "hudLayout"
local RELOAD = "the Edit Mode layout"

local seen    -- { name, kind } of the layout in use, as last seen in the world
local waiting -- the one to set as soon as the game lets us
local missing -- the one kept that this character does not have: read in place of the one in use
local inWorld -- between entering the world and leaving it (a logout, a /reload, a loading screen)

-- The manager's list and active layout; nil before it has its layouts.
local function Layouts()
    local manager = rawget(_G, "EditModeManagerFrame")
    local info = manager and manager.layoutInfo
    if type(info) ~= "table" or type(info.layouts) ~= "table" then return nil end
    return info
end

local function InUse()
    local info = Layouts()
    local layout = info and info.layouts[info.activeLayout]
    if type(layout) ~= "table" or type(layout.layoutName) ~= "string" then return nil end
    return { name = layout.layoutName, kind = layout.layoutType }
end

-- The layout in use, as the manager says it in the world. Another one than seen last, which we did not set
-- (we note one as seen before we set it): the player picked it, or the game did for a specialization, and a
-- missing one counts no longer.
local function See()
    if not inWorld then return end
    local now = InUse()
    if not now then return end
    if seen and (now.name ~= seen.name or now.kind ~= seen.kind) then missing = nil end
    seen = now
end

-- Sets a layout. Returns nil when it has to wait; else true, and whether another layout was set. One
-- that is not there (deleted, another character's own) is left alone: the layout in use stays, and the
-- one wanted is kept as missing.
local function Choose(want)
    local info = Layouts()
    if not info or InCombatLockdown() or Core.EditMode.active then return nil end
    for index, layout in ipairs(info.layouts) do
        if type(layout) == "table" and layout.layoutName == want.name and layout.layoutType == want.kind then
            seen, missing = { name = want.name, kind = want.kind }, nil
            if index == info.activeLayout then return true, false end
            C_EditMode.SetActiveLayout(index)
            return true, true
        end
    end
    missing = { name = want.name, kind = want.kind }
    return true, false
end

-- A frame after the manager took new layouts: what is in use now, and a waiting layout set if it can be.
local function Look()
    See()
    if not waiting then return end
    local done, changed = Choose(waiting)
    if not done then return end
    waiting = nil
    if changed then Sync.OfferReload({ RELOAD }) end
end
local LookSoon = Core.Later(function() Sync.Safe("Edit Mode", Look) end)

Core.On("PLAYER_ENTERING_WORLD", function()
    inWorld = true
    LookSoon()
end)
Core.On("PLAYER_LEAVING_WORLD", function() inWorld = false end)
Core.On("EDIT_MODE_LAYOUTS_UPDATED", LookSoon) -- one chosen, saved or deleted; the login's
Core.On("PLAYER_SPECIALIZATION_CHANGED", function(unit) -- each specialization has its own
    if unit == nil or unit == "player" then LookSoon() end
end)
Core.On("PLAYER_REGEN_ENABLED", function() -- a layout the fight held up
    if waiting then LookSoon() end
end)
Core.EditMode.Watch(function(active) -- Edit Mode closed (EditMode.lua): a layout it held up
    if not active then LookSoon() end
end)

Sync.Part(ID, "elsewhere", {
    text = "Edit Mode layout",
    tip = "Which Edit Mode layout is in use, not the layouts themselves. A layout only one character has is set on that character only.",
    reload = RELOAD,
    Read = function()
        if waiting then return waiting end
        See()
        return missing or seen or Sync.Taken(ID) -- not seen at all this session: what was kept stays
    end,
    Write = function(want)
        if type(want) ~= "table" or type(want.name) ~= "string" then return false end
        waiting = nil
        local done, changed = Choose(want)
        if not done then waiting, missing = want, nil end
        return changed or false
    end,
})
