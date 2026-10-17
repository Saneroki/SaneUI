local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Presets
--  A preset (called a "layout" on screen) is a saved copy of all your bars: for
--  every slot the spell, item or macro that is there, real or reserved. Presets
--  are kept per class and are shared by all your characters of that class.
--
--  Loading one reserves every slot again; the Engine then makes real at once
--  whatever you already have. The rest waits as a reservation.
-------------------------------------------------------------------------------
local Presets = {}
ns.Presets = Presets
local E = ns.Engine
local Core = SaneUI.Core

local NAME_LETTERS = 32 -- the longest name a layout can have

local function Store()
    return ns.DB.presets[ns.class]
end

-- Whether a saved layout is one: saved settings come from older versions and hand edits too.
local function IsLayout(preset)
    return type(preset) == "table" and type(preset.slots) == "table"
end

-- The names of the saved layouts, sorted. A key or value of another shape is passed over: the
-- menu and /sane ab layouts must not trip over a hand edit.
function Presets.List()
    local names = {}
    for name, preset in pairs(Store()) do
        if type(name) == "string" and IsLayout(preset) then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

-- Returns ok, message. Not in a fight: the game hides what is on the buttons then, and a layout
-- saved without them would miss those buttons for good.
function Presets.Save(name)
    name = strtrim(name or "")
    if name == "" then return false, "The layout needs a name." end
    if InCombatLockdown() then return false, "You are in combat: save the layout after the fight." end
    local saved, count = {}, 0
    for _, slot in ipairs(ns.ManagedSlots()) do
        local entry = ns.RealEntry(slot) or ns.char.reserved[slot]
        if entry then
            saved[slot] = E.Copy(entry)
            count = count + 1
        end
    end
    Store()[name] = { slots = saved, by = ns.char.name }
    return true, ("Layout \"%s\" saved (%d buttons)."):format(name, count)
end

function Presets.Delete(name)
    Store()[name] = nil
end

-- What a saved slot holds, or nil. A layout is saved settings: an older version or a hand
-- edit may have left something of another shape, which is passed over.
local function Wanted(slots, slot)
    local want = slots[slot]
    if type(want) == "table" and type(want.kind) == "string" and (want.id == nil or type(want.id) == "number")
        and (want.name == nil or type(want.name) == "string") and ns.Texture(want.icon) then
        return want
    end
    return nil
end

-- Returns ok, message.
function Presets.Load(name)
    name = strtrim(name or "")
    local preset = Store()[name]
    if not IsLayout(preset) then return false, "There is no saved layout with that name." end
    local why = E.Blocked()
    if why == "combat" then return false, "You are in combat: load the layout after the fight." end
    if why then return false, E.Reason(why) end

    local reserved = ns.char.reserved
    for _, slot in ipairs(ns.ManagedSlots()) do
        local want = Wanted(preset.slots, slot)
        local real = ns.RealEntry(slot)
        -- Mounts, equipment sets and the like are never touched, in either direction.
        local keep = (real and real.kind == "other") or (want and want.kind == "other")
        if not keep then
            if real and want and E.Same(real, want) then
                reserved[slot] = nil
            else
                if real then
                    PickupAction(slot)
                    ClearCursor()
                end
                reserved[slot] = want and E.Copy(want) or nil
                E.Touched(slot)
            end
        end
    end
    ns.QueueUpdate(true, 0)
    return true, ("Layout \"%s\" loaded."):format(name)
end

-------------------------------------------------------------------------------
--  Asked first, in the game's own dialogs (Core.AskText, Core.Confirm). Without
--  them, nothing is done from here: the command to type is said instead.
-------------------------------------------------------------------------------
local function Asked(dialog, command)
    if not dialog then ns.Print(("the game's dialog for this is missing: type /sane ab %s."):format(command)) end
end

-- A name for the bars as they are now; they are saved under it.
function Presets.AskSave()
    Asked(Core.AskText("Name for this action bar layout:", nil, Core.Word("SAVE", "Save"), nil, function(name)
        ns.Print((select(2, Presets.Save(name))))
    end, NAME_LETTERS), "save <name>")
end

-- Loading replaces the buttons of every bar.
function Presets.AskLoad(name)
    Asked(Core.Confirm("Load the layout \"%s\"?\n\nIt replaces the buttons of your action bars. Spells and items you do not have yet become reservations.",
        name, function() ns.Print((select(2, Presets.Load(name)))) end), "load " .. name)
end

-- A saved layout is the only copy of every bar of the class: deleting it asks first, with the
-- game's warning sign, as Core's profiles do.
function Presets.AskDelete(name)
    Asked(Core.Confirm("Delete the layout \"%s\"?", name, function()
        Presets.Delete(name)
        ns.Print(("layout \"%s\" deleted."):format(name))
    end, true), "delete " .. name)
end
