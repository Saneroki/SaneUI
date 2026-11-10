local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Unsaved
--  Changes made in the menus, kept or taken back (Saneroki, 2026-11-09). A
--  change counts at once, as it always has; the save window (Settings/Save.lua)
--  then asks whether to keep it, beside the menu, and stays until it is answered:
--      Yes   every change since the last save goes into each profile ticked
--            under Save to (the one in use ticked at first); unticked, the one
--            in use gets them back as they were
--      No    every change since the last save taken back (also the page
--            Profiles' Load last settings)
--  The menus that count: the game's options (Sane UI's pages in its AddOns tab,
--  the game's own pages, its key bindings, the CVar list), Edit Mode, the game's
--  addon list, and Sane UI's options over a full screen. What the profiles keep
--  of the game's settings is Sync's (as far as the tab Game settings ticks it).
--
--  The last save is a copy of every module's settings, taken when a menu opens
--  and nothing waits to be saved (Mark). While a menu is open each change (a
--  setting, a CVar, a key, an Edit Mode layout, an addon) is looked at a moment
--  later (Check, at most every 0.3 s): the game's settings read in (Sync's capture), then what
--  differs from the copy, setting by setting (Diff). A change made while no
--  menu is open (a window moved, a box in a window) is not one of them.
--
--  Unanswered, a /reload or logout saves them as Yes does (Saneroki, 2026-11-10:
--  a change must not pop back at a reload): only No and Load last settings take
--  changes back. Another profile used waits for the answer first (Wait); unanswered,
--  the /reload or logout counts as the answer and the character uses it at its
--  next login.
-------------------------------------------------------------------------------
local Unsaved = {}
Core.Unsaved = Unsaved

local Copy, Same = Core.Copy, Core.Same

local TEXT = {
    general = "General",
    game = "Game settings: %s",
    cvar = "CVar %s",
    kept = "Game settings: what the profiles keep",
}

local before     -- [module] = a copy of its settings at the last save; nil: no menu was opened since
local changes    -- { { module, path } }: each setting that differs from the last save, as last looked at
local menus = {} -- [menu] = true: the menus open now
local waiting    -- { words, fn }: a step that follows the answer
local ticks      -- [profile] = true: where Yes saves the changes, while there are some
local watchers = {}

-- Settings that are no setting of a menu: where the windows stand (Window.lua), which game Sync read in and when its
-- values changed.
local SKIP = { [Core.name] = { places = true }, Sync = { from = true, stamps = true } }

local function Tell()
    for _, fn in ipairs(watchers) do Core.Safe("unsaved", fn) end
end

-- fn() is told whenever the changes, the profiles ticked or the step waiting for the answer change.
function Unsaved.Watch(fn)
    watchers[#watchers + 1] = fn
end

-------------------------------------------------------------------------------
--  Settings, setting by setting
-------------------------------------------------------------------------------
-- A path into a module's settings: its key, then the keys in the tables under it.
local function Path(path, key)
    local new = { unpack(path) }
    new[#new + 1] = key
    return new
end

local function Get(values, path)
    for _, key in ipairs(path) do
        if type(values) ~= "table" then return nil end
        values = values[key]
    end
    return values
end

-- Writes a copy of value at path, making the tables on the way (nil takes it out).
local function Put(values, path, value)
    for index = 1, #path - 1 do
        local key = path[index]
        if type(values[key]) ~= "table" then values[key] = {} end
        values = values[key]
    end
    values[path[#path]] = Copy(value)
end

-- A list (keys 1, 2, ...) counts as one setting: the chat windows, a command's keys.
local function List(t)
    return t[1] ~= nil
end

-- Each place where old and new differ, into out: down into tables of names, a list or a value as a whole.
local function Diff(old, new, path, out)
    if type(old) == "table" and type(new) == "table" and not List(old) and not List(new) then
        for key, value in pairs(old) do Diff(value, new[key], Path(path, key), out) end
        for key, value in pairs(new) do
            if old[key] == nil then Diff(nil, value, Path(path, key), out) end
        end
    elseif not Same(old, new) then
        out[#out + 1] = path
    end
end

-- The game's settings read into the settings in use (Sync's capture, the one module that holds the game's).
local function Read()
    local sync = Core.Sync
    if sync and sync.Capture then Core.Safe("unsaved: reading the game's settings", sync.Capture) end
end

-- Every module's settings in use, by name.
local function Live()
    local all = {}
    for _, name in ipairs(Core.optionOrder) do
        local values = Core.Profiles.Live(name)
        if values then all[name] = values end
    end
    return all
end

-- What differs from the last save: { module, path } for each setting, its described keys only.
local function Differs()
    local list = {}
    for name, values in pairs(Live()) do
        local old, skip = before[name], SKIP[name] or {}
        local described = Core.described[name]
        if old and described then
            local paths = {}
            for _, option in ipairs(described.list) do
                local key = option.key
                if key and not skip[key] then Diff(old[key], values[key], { key }, paths) end
            end
            for _, path in ipairs(paths) do list[#list + 1] = { module = name, path = path } end
        end
    end
    table.sort(list, function(a, b)
        if a.module ~= b.module then return a.module < b.module end
        return table.concat(a.path, "\1") < table.concat(b.path, "\1")
    end)
    return list
end

-------------------------------------------------------------------------------
--  The last save and what changed since
-------------------------------------------------------------------------------
-- The profiles ticked at first: the one in use, and the others ticked the last time (SaneUIDB.saveTo).
local function Ticks()
    local use, kept = Core.Profiles.InUse(), rawget(_G, "SaneUIDB")
    ticks = { [use] = true }
    local saveTo = type(kept) == "table" and type(kept.saveTo) == "table" and kept.saveTo or {}
    for name in pairs(saveTo) do
        if name ~= use and Core.Profiles.Settings(name) then ticks[name] = true end
    end
end

-- The settings as they are now are the last save.
local function Mark()
    Read()
    before = {}
    for name, values in pairs(Live()) do before[name] = Copy(values) end
    changes, ticks = nil, nil
end

-- What follows the answer: a step that waited for it, then a new last save while a menu is open.
local function Done()
    before, changes, ticks = nil, nil, nil
    if next(menus) then Mark() end
    Tell()
    local step = waiting
    waiting = nil
    if step then Core.Safe("unsaved: then", step.fn) end
end

-- Looks at the settings in use: the game's read in, then each that differs from the last save.
local function Check()
    if not before then return end
    Read()
    local list = Differs()
    local was = changes
    changes = #list > 0 and list or nil
    if changes and not was then Ticks() end
    if not changes and waiting then return Done() end -- taken back by hand: what waited goes on
    if not Same(was, changes) then Tell() end
end
-- At most every 0.3 s: a slider of the game's options sets its CVar on every frame it is dragged.
local CheckSoon = Core.Later(Check, 0.3, "unsaved")

-- Something may have changed: looked at a moment later, while a menu is open.
function Unsaved.Soon()
    if before and next(menus) then CheckSoon() end
end

-- A menu opened: the settings as they are now are the last save, unless changes wait for an answer. frame: the menu's
-- own, which counts only while it is shown (its OnShow run by hand opens nothing).
function Unsaved.Open(menu, frame)
    if frame and not (frame.IsShown and frame:IsShown()) then return end
    menus[menu] = true
    if not before then Mark() end
end

-- A menu closed: what it changed is looked at; with no changes left, the last save is forgotten (the next menu takes
-- a new one).
function Unsaved.Close(menu)
    if not menus[menu] then return end
    Check()
    menus[menu] = nil
    if not changes and not next(menus) then before = nil end
end

-- Another profile came into use (Profiles.lua: Move): its settings count from now on.
function Unsaved.Moved()
    local had = changes ~= nil
    before, changes, ticks = nil, nil, nil
    if next(menus) then Mark() end
    if had then Tell() end
end

-------------------------------------------------------------------------------
--  What the save window shows and does
-------------------------------------------------------------------------------
function Unsaved.Pending()
    return changes ~= nil
end

-- A change in a few words: where it is, and the setting.
local function Words(change)
    local name, path = change.module, change.path
    local sync = Core.Sync
    if sync and name == sync.name then
        if path[1] == "taken" then
            local part = sync.part and sync.part[path[2]]
            return TEXT.game:format(part and part.text or tostring(path[2]))
        end
        if (path[1] == "named" or path[1] == "dropped") and path[2] then return TEXT.cvar:format(tostring(path[2])) end
        return TEXT.kept
    end
    local option = Core.Described(name, path[1])
    local module = rawget(SaneUI, name)
    local title = name == Core.name and (option and option.page or TEXT.general) or (module and module.title) or name
    return title .. ": " .. tostring(option and option.text or path[1])
end

-- The changes in words, each once, in order.
function Unsaved.Changes()
    local list, seen = {}, {}
    for _, change in ipairs(changes or {}) do
        local words = Words(change)
        if not seen[words] then
            seen[words] = true
            list[#list + 1] = words
        end
    end
    return list
end

-- The step that follows the answer, in words; nil if none waits.
function Unsaved.Next()
    return waiting and waiting.words or nil
end

-- The profiles the changes can be saved to: every saved one, and Character specific while it is in use.
function Unsaved.Targets()
    local list, use = {}, Core.Profiles.InUse()
    for _, name in ipairs(Core.Profiles.List()) do
        if name ~= Core.Profiles.OWN or name == use then list[#list + 1] = name end
    end
    return list
end

function Unsaved.Ticked(name)
    return ticks ~= nil and ticks[name] == true
end

-- Ticks a profile under Save to; one but the one in use is ticked again the next time (SaneUIDB.saveTo).
function Unsaved.Tick(name, on)
    if not ticks then return end
    ticks[name] = on and true or nil
    local kept = rawget(_G, "SaneUIDB")
    if name ~= Core.Profiles.InUse() and type(kept) == "table" then
        if type(kept.saveTo) ~= "table" then kept.saveTo = {} end
        kept.saveTo[name] = on and true or nil
    end
    Tell()
end

-- A profile renamed (Profiles.lua; new: nil for one deleted): its tick under Save to goes with it, now and the next
-- time. Left on the old name, the profile in use renamed would count as unticked and get its last save back at Yes.
function Unsaved.Renamed(old, new)
    if ticks and ticks[old] then
        ticks[old] = nil
        if new then ticks[new] = true end
    end
    local kept = rawget(_G, "SaneUIDB")
    local saveTo = type(kept) == "table" and type(kept.saveTo) == "table" and kept.saveTo or nil
    if saveTo and saveTo[old] then
        saveTo[old] = nil
        if new then saveTo[new] = true end
    end
    Tell()
end

-- Whether any profile is ticked.
function Unsaved.Any()
    return ticks ~= nil and next(ticks) ~= nil
end

-- The changes written into a saved profile that is not in use. The game's settings go into it only when it holds
-- none of another game's (Sync's from: a profile copied from the other game's folder).
local function Into(name)
    local profile = Core.Profiles.Settings(name)
    if not profile then return end
    local sync = Core.Sync and Core.Sync.name
    local held = sync and type(profile[sync]) == "table" and profile[sync] or nil
    local other = held and held.from ~= nil and held.from ~= Core.GAME and type(held.taken) == "table" and next(held.taken) ~= nil
    local live = Live()
    for _, change in ipairs(changes) do
        local module = change.module
        if not (module == sync and other) then
            if type(profile[module]) ~= "table" then profile[module] = {} end
            Put(profile[module], change.path, Get(live[module], change.path))
            if module == sync and change.path[1] == "taken" then profile[module].from = Core.GAME end
        end
    end
end

-- The settings in use back as they were at the last save: only those that changed, each module told
-- (Profiles.Put); the game's are written into it (Sync's moved). An Edit Mode layout takes its own text too.
local function Back()
    local new, live, layout = {}, Live(), false
    for _, change in ipairs(changes) do
        local module = change.module
        new[module] = new[module] or Copy(live[module])
        Put(new[module], change.path, Get(before[module], change.path))
        if change.path[1] == "taken" and change.path[2] == "hudLayout" then layout = true end
    end
    if layout and Core.Sync and Core.Sync.ExactLayout then Core.Sync.ExactLayout() end
    before, changes = nil, nil -- the game's writing that follows offers a /reload, which must not wait for an answer
    Core.Profiles.Put(function(name) return new[name] or false end)
end

-- The changes written into every other profile ticked; true when the one in use is ticked too (it holds them
-- already), false when it is to get the last save back.
local function Keep()
    local use = Core.Profiles.InUse()
    for name in pairs(ticks or {}) do
        if name ~= use then Into(name) end
    end
    return ticks ~= nil and ticks[use] == true
end

-- Yes: the changes into every profile ticked; the one in use, unticked, gets the last save back.
function Unsaved.Save()
    if not changes or not Unsaved.Any() then return false end
    if not Keep() then Back() end
    Done()
    return true
end

-- No (and Load last settings): every change since the last save taken back.
function Unsaved.Undo()
    if not changes then return false end
    Back()
    Done()
    return true
end

-- A step that needs the answer first: true when it waits for it (fn runs once the changes are saved or taken back),
-- false when nothing waits to be saved. words: what follows, for the save window. last: what of the step is done
-- at a /reload or logout unanswered, which saves the changes as Yes does and so answers too (another profile: the
-- character's line names it for the next login).
function Unsaved.Wait(words, fn, last)
    if not changes then return false end
    waiting = { words = words, fn = fn, last = last }
    Tell()
    return true
end

-------------------------------------------------------------------------------
--  The menus, and the changes made in them
-------------------------------------------------------------------------------
for _, event in ipairs({ "CVAR_UPDATE", "UPDATE_BINDINGS", "EDIT_MODE_LAYOUTS_UPDATED" }) do
    Core.On(event, Unsaved.Soon)
end

Core.On("PLAYER_LOGIN", function()
    local options = rawget(_G, "SettingsPanel")
    if options and options.HookScript then
        options:HookScript("OnShow", Core.Guard("unsaved", function() Unsaved.Open("options", options) end))
        options:HookScript("OnHide", Core.Guard("unsaved", function() Unsaved.Close("options") end))
        Unsaved.Open("options", options) -- shown already (a /reload with it open)
    end
    Core.EditMode.Watch(function(active)
        if active then Unsaved.Open("editmode") else Unsaved.Close("editmode") end
    end)
    -- The game's addon list: a tick changes the addon at once (AddonList_Update follows each, called by its global
    -- name); its Okay (Reload UI) needs nothing of ours: the /reload saves what changed, as every /reload does. Its
    -- Cancel gives the game the addons back (ResetAddOns, in its OnHide), so the look at its closing finds no change.
    local addons = rawget(_G, "AddonList")
    if addons and addons.HookScript then
        addons:HookScript("OnShow", Core.Guard("unsaved", function() Unsaved.Open("addons", addons) end))
        addons:HookScript("OnHide", Core.Guard("unsaved", function() Unsaved.Close("addons") end))
    end
    if rawget(_G, "AddonList_Update") then hooksecurefunc("AddonList_Update", Core.Guard("unsaved", Unsaved.Soon)) end
end)

-- The game writes the saved settings after this (a logout, a /reload); Profiles.lua has read the game's in. Changes
-- not answered are saved as Yes saves them: into every profile ticked. Only the one in use, unticked, gets the last
-- save's values back, in the saved settings only (the game gets them from the profile at the next login). A step
-- that waited for the answer has its lasting part done then (another profile chosen is used at the next login).
Core.On("PLAYER_LOGOUT", function()
    if next(menus) then Check() end
    if changes and not Keep() then
        local live = Live()
        for _, change in ipairs(changes) do
            local values = live[change.module]
            if values then Put(values, change.path, Get(before[change.module], change.path)) end
        end
    end
    local step = waiting
    waiting = nil
    if step and step.last then Core.Safe("unsaved: at the logout", step.last) end
end)
