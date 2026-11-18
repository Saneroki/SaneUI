-------------------------------------------------------------------------------
--  SaneUI - Core - Sync - Layout: the Edit Mode layout in use
--  Kept by its name and kind (the game numbers its layouts in a list that is
--  not the same on every character), and as the game's own text of it (Saneroki,
--  2026-10-30: the layouts themselves too): one that a character does not have
--  is added from that text, through C_EditMode alone, as Edit Mode adds one
--  (Add). Read from Edit Mode's manager, the game's
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
--  the one in use meanwhile; one the player picks meanwhile wins over it. One
--  that is not there and cannot be added leaves the layout in use as it is,
--  and still counts as the one kept until the layout in use changes this
--  session (the player picks one): this character's own does not take its
--  place at the logout.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sync = Core.Sync -- Sync.lua

local ID = "hudLayout"
local RELOAD = "the Edit Mode layout"
local SET = "%s set: it is number %d, Edit Mode's manager had %s, the game said %s" -- for the error log (Sync.OfferReload)
local ADDED = "%s added: this character's list did not have it"
local TYPES = rawget(_G, "Enum") and Enum.EditModeLayoutType or {}
local PRESET, ACCOUNT, CHARACTER = TYPES.Preset or 0, TYPES.Account or 1, TYPES.Character or 2

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
    local text = layout.layoutType ~= PRESET and Core.Ask(C_EditMode.ConvertLayoutInfoToString, layout) or nil
    return { name = layout.layoutName, kind = layout.layoutType, text = text }
end

-- The layout in use, as the manager says it in the world. Another one than seen last, which we did not set
-- (we note one as seen before we set it): the player picked it, or the game did for a specialization. That
-- one wins: a missing one counts no longer, nor one still waiting to be set (Edit Mode was open).
local function See()
    if not inWorld then return end
    local now = InUse()
    if not now then return end
    if seen and (now.name ~= seen.name or now.kind ~= seen.kind) then missing, waiting = nil, nil end
    seen = now
end

-- A layout this character does not have, from the game's text of it: put after those of its kind in the game's list
-- and made the one in use, as Edit Mode does; its manager hears of it by the game's event. Whether it could be.
-- Only a layout of a player's kind (account, character): a preset is the game's own, there or not.
local function Add(want, info)
    if want.kind ~= ACCOUNT and want.kind ~= CHARACTER then return false end
    local all = Core.Ask(C_EditMode.GetLayouts)
    local layout = type(want.text) == "string" and Core.Ask(C_EditMode.ConvertStringToLayoutInfo, want.text)
    if type(all) ~= "table" or type(all.layouts) ~= "table" or type(layout) ~= "table"
        or not Core.Ask(C_EditMode.IsValidLayoutName, want.name) then return false end
    layout.layoutName, layout.layoutType = want.name, want.kind
    local at, presets = 0, 0
    for index, known in ipairs(info.layouts) do
        if known.layoutType == PRESET then presets = index end
        if known.layoutType == want.kind or known.layoutType == PRESET
            or (want.kind == CHARACTER and known.layoutType == ACCOUNT) then at = index end
    end
    table.insert(all.layouts, at + 1 - presets, layout)
    -- Saved by the game, or not at all: only then is the manager told of it, at its index, as the one in use.
    if not pcall(C_EditMode.SaveLayouts, all) then return false end
    Core.Ask(C_EditMode.OnLayoutAdded, at + 1, true, false)
    return true
end

-- The next layout set takes its own text too (Sync.ExactLayout), where the game's differs: the save window's No
-- after frames were moved in Edit Mode and saved (Unsaved.lua). Otherwise a layout the character has stays as it is.
local exact

function Sync.ExactLayout()
    exact = true
end

-- A layout the character has, given the text it had: saved through the game, which reads it at the next /reload
-- (offered). Edit Mode's manager is not told: its frames would move under our taint. Whether it was changed.
local function Replace(want)
    if (want.kind ~= ACCOUNT and want.kind ~= CHARACTER) or type(want.text) ~= "string" then return false end
    local all = Core.Ask(C_EditMode.GetLayouts)
    if type(all) ~= "table" or type(all.layouts) ~= "table" then return false end
    for index, known in ipairs(all.layouts) do
        if type(known) == "table" and known.layoutName == want.name and known.layoutType == want.kind then
            if Core.Ask(C_EditMode.ConvertLayoutInfoToString, known) == want.text then return false end
            local layout = Core.Ask(C_EditMode.ConvertStringToLayoutInfo, want.text)
            if type(layout) ~= "table" then return false end
            layout.layoutName, layout.layoutType = want.name, want.kind
            all.layouts[index] = layout
            return pcall(C_EditMode.SaveLayouts, all) and true or false
        end
    end
    return false
end

-- Sets a layout. Returns nil when it has to wait; else true, and whether another layout was set. One
-- that is not there is added from its text; without one the layout in use stays, and the one wanted is
-- kept as missing.
local function Choose(want)
    local info = Layouts()
    if not info or InCombatLockdown() or Core.EditMode.active then return nil end
    local again = exact
    exact = nil
    for index, layout in ipairs(info.layouts) do
        if type(layout) == "table" and layout.layoutName == want.name and layout.layoutType == want.kind then
            seen, missing = { name = want.name, kind = want.kind, text = want.text }, nil
            local replaced = again and Replace(want) or false
            if index == info.activeLayout then return true, replaced end
            local own = Core.Ask(C_EditMode.GetLayouts)
            Sync.said = SET:format(want.name, index, tostring(info.activeLayout),
                tostring(type(own) == "table" and own.activeLayout or nil))
            C_EditMode.SetActiveLayout(index)
            return true, true
        end
    end
    if Add(want, info) then
        seen, missing = { name = want.name, kind = want.kind, text = want.text }, nil
        Sync.said = ADDED:format(want.name)
        return true, true
    end
    missing = { name = want.name, kind = want.kind, text = want.text }
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
    tip = "The Edit Mode layout in use, and the layout itself: a character that does not have it gets it.",
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
