local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Plates
--  The reminders shown on the nameplates (Reminders.PLATES among their
--  places, the place Nameplates; Saneroki, 2026-11-07: "On those nameplates
--  the trackers are shown directly underneath with no gaps"; on a bar or the
--  health bars too where it is ticked there): each watched on the unit of every
--  plate the game shows, its icon in a row right under the plate, from the
--  plate's left, side by side without a gap, while its settings want it, as
--  on a bar: missing or active, the offset with the seconds left on the icon,
--  in or out of a fight, resting, only yours. A buff only on a unit you can
--  help, a debuff only on one you can attack (Reminders.Wanted); a party's
--  family (a shout) on your own party only; none on the dead; Plates.MOST on a
--  plate at most, in the order made.
--
--  Right under the plate: while our nameplates dress it (Nameplates/), under the
--  lowest row of its dress (the bar, your combo points, a cast's bar while one
--  shows: its Plate.Foot), on it, so the row grows, shrinks and fades with the
--  plate, and is out of sight with it while our nameplates show the health bar
--  only (its setting Plates show); else under the game's own health bar. A row of ours per plate, made
--  when it first has something to show and kept (the game hands its plates out
--  again), the plates followed from NAME_PLATE_UNIT_ADDED to _REMOVED, filled
--  with the bars (Reminders.Update, its ticker). Display only: nothing of a
--  plate's own is touched, nothing of ours takes the mouse. The plates the
--  game forbids to addons (in dungeons and raids every friendly one) and your
--  own have none.
--
--  In a fight the game hides most auras from addons: for each unit by its
--  GUID what the last look saw counts, until it runs out by the clock
--  (Reminders.Known), forgotten when its plate goes. Your own cast of a name
--  watched gives the aura to the plate of the unit it was aimed at (your
--  target's where the name the game gave is its, else a plate of that name),
--  for as long as it lasted when last read (Reminders.Ends).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Reminders = ns.Reminders
local Plates = {}
ns.PlateReminders = Plates

Plates.SIZE = 20 -- an icon, square: as big as our nameplates' auras above their bar
Plates.MOST = 6  -- icons on a plate at most

local plates = {} -- [unit token] = its plate, while the game shows it
local keys = {}   -- [unit token] = who it is (its GUID), as its plate came
local rows = {}   -- [a plate] = our row of icons on it
local seen = setmetatable({}, { __mode = "k" }) -- [a reminder] = { [a unit's GUID] = { on, instance, ends, left } }
local pictures, lefts = {}, {} -- one plate's icons and their seconds left (false: none), filled anew each time

local function On()
    return not ns.off and ns.options.reminders ~= false
end

local function Placed(reminder)
    return Reminders.At(reminder, Reminders.PLATES)
end

-- Whether any reminder is on the nameplates, and they are on.
function Plates.Any()
    if not On() then return false end
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) then return true end
    end
    return false
end

-- The frame right under our nameplates' dress on that plate, while they dress it (Nameplates/); else nil.
local function Foot(plate)
    if not ns.Nameplates.Dressing() then return nil end
    local foot = Core.Ask(ns.Plate.Foot, plate)
    return type(foot) == "table" and foot or nil
end

-- The game's own health bar on its plate (its fields read, never written), else the plate.
local function Bar(plate)
    local frame = rawget(plate, "UnitFrame")
    local row = type(frame) == "table" and rawget(frame, "HealthBarsContainer")
    if type(row) == "table" then return row end
    return type(frame) == "table" and frame or plate
end

-- The row right under the plate: on the dress's foot where our nameplates dress it (placed anew as soon as it does, or
-- stops), under the game's bar otherwise.
local function Place(row, plate)
    local foot = Foot(plate)
    if row.placed and row.foot == foot then return end
    row.placed, row.foot = true, foot
    row:SetParent(foot or plate)
    row:ClearAllPoints()
    if foot then
        row:SetPoint("TOPLEFT", foot, "TOPLEFT", 0, 0)
    else
        row:SetPoint("TOPLEFT", Bar(plate), "BOTTOMLEFT", 0, 0)
    end
end

local function Make(plate)
    local row = CreateFrame("Frame", nil, plate)
    row:SetSize(Plates.SIZE, Plates.SIZE)
    row:Hide()
    row.icons = {}
    rows[plate] = row
    return row
end

local function Icon(row, index)
    local icon = ns.ReminderBars.Icon(row, Plates.SIZE, "NumberFontNormalSmall")
    icon:SetPoint("TOPLEFT", row, "TOPLEFT", (index - 1) * Plates.SIZE, 0)
    row.icons[index] = icon
    return icon
end

-- What is known of the reminder's aura on the unit now: { on, left }; nil where nothing is.
local function Look(reminder, unit, key)
    local states = seen[reminder]
    if not states then
        states = {}
        seen[reminder] = states
    end
    states[key] = Reminders.Known(reminder, unit, states[key])
    return states[key]
end

-- The icons the unit's auras and the reminders' settings want on its plate, into pictures and lefts; how many.
local function Want(unit)
    if Core.Ask(UnitIsDeadOrGhost, unit) then return 0 end
    local key = keys[unit] or unit
    local helped = Core.Ask(UnitCanAssist, "player", unit) == true
    local count = 0
    for _, reminder in ipairs(Reminders.List()) do
        if count >= Plates.MOST then break end
        if Placed(reminder) and (reminder.harmful or helped) and Reminders.Reaches(reminder, unit) then
            local state = Look(reminder, unit, key)
            if Reminders.Wanted(reminder, state, unit, Reminders.PLATES) then
                count = count + 1
                pictures[count] = reminder.icon
                lefts[count] = state.on and state.left or false
            end
        end
    end
    return count
end

-- A plate's row as the unit's auras say now; none made until it has something to show.
local function Fill(unit)
    local plate = plates[unit]
    if not plate then return end
    local count = Want(unit)
    local row = rows[plate]
    if not row then
        if count == 0 then return end
        row = Make(plate)
    end
    Place(row, plate)
    for index = 1, math.max(count, #row.icons) do
        local icon = row.icons[index]
        if index <= count then
            icon = icon or Icon(row, index)
            icon.picture:SetTexture(pictures[index])
            icon.left:SetText(lefts[index] and ns.ReminderBars.Left(lefts[index]) or "")
            icon:Show()
        elseif icon then
            icon:Hide()
        end
    end
    row:SetWidth(math.max(count, 1) * Plates.SIZE)
    row:SetShown(count > 0)
end

function Plates.Hide()
    for _, row in pairs(rows) do row:Hide() end
end

-- Every plate looked at (Reminders.Update, a quarter of a second apart while reminders are on bars or the plates).
function Plates.Update()
    if not Plates.Any() then return Plates.Hide() end
    for unit in pairs(plates) do Fill(unit) end
end

-- The plate of the unit a cast was aimed at, by the name the game gave (nil: none given): your target's where it has
-- that name, else one of that name; nil where no plate has it.
local function Aimed(target)
    local name = type(target) == "string" and target:match("^[^-]+") or nil
    for unit in pairs(plates) do
        if Core.Ask(UnitIsUnit, unit, "target") and (not name or Core.Ask(UnitName, unit) == name) then return unit end
    end
    if not name then return nil end
    for unit in pairs(plates) do
        if Core.Ask(UnitName, unit) == name then return unit end
    end
    return nil
end

-- Your own cast of a spell, by its name and whom it was aimed at (a name, or nil), where the game tells it in a fight
-- (Reminders.lua): the unit of that plate has its aura, for as long as it lasted when last read.
function Plates.Cast(name, target)
    if not Plates.Any() then return end
    local unit = Aimed(target)
    if not unit then return end
    local key, gave = keys[unit] or unit, false
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) and Reminders.Watches(reminder, name) and Reminders.Hidden(reminder) then
            seen[reminder] = seen[reminder] or {}
            seen[reminder][key] = { on = true, ends = Reminders.Ends(reminder, name) }
            gave = true
        end
    end
    if gave then Fill(unit) end
end

-- Who was on a plate gone: what was known of them no longer counts.
local function Forget(key)
    for _, states in pairs(seen) do states[key] = nil end
end

-- Plates come and go after the module stood down too (the events still come): then nothing is followed.
local function Added(unit)
    if ns.off or type(unit) ~= "string" or Core.Ask(UnitIsUnit, unit, "player") then return end
    local plate = Core.Ask(C_NamePlate.GetNamePlateForUnit, unit)
    if type(plate) ~= "table" then return end -- a plate the game forbids to addons
    for other, held in pairs(plates) do
        if held == plate and other ~= unit then plates[other], keys[other] = nil, nil end -- handed out again
    end
    plates[unit], keys[unit] = plate, Core.Ask(UnitGUID, unit) or unit
    local row = rows[plate]
    if row then row.placed = nil end -- placed anew: the game may have given the plate another unit frame
    if Plates.Any() then Fill(unit) elseif row then row:Hide() end
end

local function Removed(unit)
    if type(unit) ~= "string" then return end
    local plate = plates[unit]
    if keys[unit] then Forget(keys[unit]) end
    plates[unit], keys[unit] = nil, nil
    local row = plate and rows[plate]
    if row then row:Hide() end
end

function Plates.Start()
    ns.On("NAME_PLATE_UNIT_ADDED", Added)
    ns.On("NAME_PLATE_UNIT_REMOVED", Removed)
end
