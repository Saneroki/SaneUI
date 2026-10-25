local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Key
--  The key (Bindings.xml: in the game's key bindings under Sane UI) and what
--  one press of it does. An addon may target, mark, attack and interact only by
--  the game's secure ways and on a key press, so the choice is made by those,
--  in a fight too. The first that holds:
--
--    loot    a corpse with loot beside you (the game's own pick for its
--            interact key, its "soft" target, dead; the switch Loot first):
--            the game's Interact With Target, which opens its loot as a right
--            click does; what is taken is the game's loot window's (or a loot
--            module's) to say
--    fight   your target a living foe in a fight: the button Fight, which
--            marks it and starts the attack
--    object  the thing of the world the interact key would use is one your
--            quests want (Wanted.Object; the switch Quest objects): Interact
--            With Target, which picks it up, opens or uses it
--    talk    a living friendly NPC right in front of you, the one the game's
--            interact key would talk to (its soft target; Saneroki, 2026-10-25:
--            one press talks to the quest giver you stand at; the switch Talk to
--            NPCs): Interact With Target
--    fight   your target a living foe that is wanted: Fight
--    talk    your target a living friendly NPC that is wanted (the switch Talk
--            to NPCs): Interact With Target, which talks to it
--    find    else: the button Find. Its macro is the hearth when your guide's
--            step wants it (Items.lua); else it lets your target go, targets
--            the first wanted name around you (Wanted.lua), marks it with a
--            skull and starts the attack on a foe, and when it found none,
--            uses one quest item (Items.lua)
--
--  A state driver of the game reads loot, a foe, an NPC in front of you, a
--  friend from the macro conditions, five times a second; the header's
--  snippet then puts that mode's action on the key's keys as override bindings
--  of its own (above other overrides). Whether your target is wanted and whether the soft target is a
--  wanted object the module says out of a fight (the attributes wanted and
--  object, at every change of either and of the quests), and the macro of Find
--  is written out of a fight only: anew the moment before each press
--  (PreClick) and when the quests change, without hearth and items as a fight
--  begins. In a fight they all stay as they were.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Key = {}
ns.Key = Key

Key.ROOM = 1023 -- characters of a button's macro text the game runs
Key.HEADER, Key.FIND, Key.FIGHT = "SaneUISpeedLevelingKey", "SaneUISpeedLevelingFind", "SaneUISpeedLevelingFight"
Key.COMMAND = "CLICK " .. Key.FIND .. ":LeftButton" -- the key's own binding (Bindings.xml)

-- Its words in the game's key bindings.
_G["BINDING_NAME_" .. Key.COMMAND] = ns.TEXT.binding

local HINT = "Speed Leveling: give it a key in Esc > Options > Keybindings, under Sane UI."

-- What the macro conditions tell the state driver: the first that holds.
local LOOT = "[@softinteract,exists,dead] loot; "
local REST = "[@target,harm,nodead,combat] fight; [@softinteract,exists,help,nodead] near; [@target,harm,nodead] foe; "
    .. "[@target,help,nodead] friend; find"

-- The header's snippets, which the game runs in its restricted environment, in a fight too. A change of the state
-- or of what decides it: the action of the mode on each of the key's keys.
local ON_CHANGE = [[
    if name == "state-mode" or name == "wanted" or name == "object" or name == "talk" or name == "keys" then
        self:RunAttribute("_bind")
    end
]]
local BIND = [[
    local mode = self:GetAttribute("state-mode")
    if mode ~= "loot" and mode ~= "fight" and self:GetAttribute("object") then
        mode = "object"
    elseif mode == "foe" then
        mode = self:GetAttribute("wanted") and "fight" or "find"
    elseif mode == "friend" then
        mode = self:GetAttribute("wanted") and self:GetAttribute("talk") and "talk" or "find"
    elseif mode == "near" then
        mode = self:GetAttribute("talk") and "talk" or "find"
    end
    self:ClearBindings()
    for index = 1, self:GetAttribute("keys") or 0 do
        local key = self:GetAttribute("key" .. index)
        if mode == "loot" or mode == "object" or mode == "talk" then
            self:SetBinding(true, key, "INTERACTTARGET")
        elseif mode == "fight" then
            self:SetBindingClick(true, key, "SaneUISpeedLevelingFight")
        else
            self:SetBindingClick(true, key, "SaneUISpeedLevelingFind")
        end
    end
]]

-- What Loot first and Quest objects need of the game's settings, each as text: its interact key on for the mouse and
-- keyboard too (it picks the corpse or the thing beside you).
local ANY = Enum and Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any or 3
local SETTINGS = { softTargetInteract = tostring(ANY) }

local header, find, fight
local keys -- the key's keys as the header has them; nil before the first reading
local soft -- the GUID of what the interact key would use now, as the game last said

local function Same(a, b)
    return tostring(a) == tostring(b)
end

-- Each setting as needed; what it was is kept (the first time only) to be put back.
local function Lend()
    local kept = ns.options.foundCVars
    for name, value in pairs(SETTINGS) do
        local now = Core.Ask(C_CVar.GetCVar, name)
        if now ~= nil and not Same(now, value) then
            Core.Ask(C_CVar.SetCVar, name, value)
            if not kept[name] and Same(Core.Ask(C_CVar.GetCVar, name), value) then kept[name] = { was = now, set = value } end
        end
    end
end

-- Each kept setting back as it was, unless it was changed since.
local function PutBack()
    local kept = ns.options.foundCVars
    for name, entry in pairs(kept) do
        if type(entry) == "table" and Same(Core.Ask(C_CVar.GetCVar, name), entry.set) then
            Core.Ask(C_CVar.SetCVar, name, entry.was)
        end
        kept[name] = nil
    end
end

-- A name a macro line can carry: nothing that ends the line or the conditions.
local function Fits(name)
    return not name:find("[;%[%]\n]")
end

-- The macro of Find: your target let go, the first wanted name around you targeted (a dead one is passed over, the
-- next may take its place, and let go at the end), the one found marked and a foe attacked; with use (a macro line),
-- that line when none was found. As many names as there is room for, the first first; no names: use alone.
function Key.Macro(names, use)
    local tail = { "/cleartarget [dead]" }
    if ns.options.skull then tail[#tail + 1] = "/tm [exists] !8" end
    tail[#tail + 1] = "/startattack [harm,nodead]"
    if use then tail[#tail + 1] = "/stopmacro [exists]\n" .. use end
    local ending = table.concat(tail, "\n")
    local lines = { "/cleartarget" }
    local size = #lines[1] + 1 + #ending
    for _, name in ipairs(names) do
        local line = "/targetexact [noexists][dead] " .. name
        if Fits(name) and size + #line + 1 <= Key.ROOM then
            lines[#lines + 1] = line
            size = size + #line + 1
        end
    end
    if #lines == 1 then return use or "" end
    lines[#lines + 1] = ending
    return table.concat(lines, "\n")
end

-- Find's macro now: the hearth the guide's step wants (the switch Hearthstone), else the wanted names with one item
-- for when none is found (the switch Quest items). In a fight (fighting): the names alone.
function Key.Find(fighting)
    local items, spells
    if ns.options.guide then items, spells = ns.Guide.Uses() end
    if not fighting and ns.options.hearth then
        local hearth = ns.Items.Hearth(items, spells)
        if hearth then return hearth end
    end
    local use = not fighting and ns.options.items and ns.Items.Pick(items) or nil
    return Key.Macro((ns.Wanted.Names()), use)
end

-- The macro of Fight: your living foe marked (the switch) and attacked.
local function Attack()
    return ns.options.skull and "/tm [harm,nodead] !8\n/startattack [harm,nodead]" or "/startattack [harm,nodead]"
end

local function Write(button, text)
    if button:GetAttribute("macrotext") ~= text then button:SetAttribute("macrotext", text) end
end

-- The moment before a press of Find, out of a fight: its macro from what is wanted now.
local function Before()
    if not InCombatLockdown() then Write(find, Key.Find()) end
end

-- A fight begins (the moment before the lock): Find without the hearth and items, which a fight would only break.
local function Fighting()
    if not InCombatLockdown() and header and not ns.off then Write(find, Key.Find(true)) end
end

local function Later(fn)
    return function() ns.Guarded(fn) end
end

-- Out of a fight: whether your target is wanted, whether the interact key's thing is a wanted object, and the macro of
-- Find, as they are now.
function Key.Refresh()
    if not header or ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: refresh", Key.refreshLater) end
    header:SetAttribute("wanted", ns.Wanted.Unit("target"))
    local thing = soft or Core.Ask(UnitGUID, "softinteract")
    header:SetAttribute("object", ns.options.objects and ns.Wanted.Object(thing) or false)
    Write(find, Key.Find())
end
Key.refreshLater = Later(Key.Refresh)

-- The key's keys from the game's key bindings onto the header, when they changed. None at the first start: told how
-- to give it one, once.
function Key.Keys()
    if not header or ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: keys", Key.keysLater) end
    local now = {}
    for _, key in ipairs({ GetBindingKey(Key.COMMAND) }) do
        if type(key) == "string" and key ~= "" then now[#now + 1] = key end
    end
    if keys and table.concat(now, " ") == table.concat(keys, " ") then return end
    keys = now
    for index, key in ipairs(keys) do header:SetAttribute("key" .. index, key) end
    header:SetAttribute("keys", #keys)
end
Key.keysLater = Later(Key.Keys)

-- The switches as they are: the game's settings for Loot first and Quest objects, the driver's conditions, the macros.
function Key.Update()
    if not header or ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: settings", Key.updateLater) end
    if ns.options.loot or ns.options.objects then Lend() else PutBack() end
    Write(fight, Attack())
    header:SetAttribute("talk", ns.options.talk and true or false)
    RegisterStateDriver(header, "mode", (ns.options.loot and LOOT or "") .. REST)
    Key.Refresh()
end
Key.updateLater = Later(Key.Update)

local function Button(name, text)
    local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", text)
    button:RegisterForClicks("AnyUp", "AnyDown")
    return button
end

function Key.Start()
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: start", Key.startLater) end
    if header then return end
    find, fight = Button(Key.FIND, ""), Button(Key.FIGHT, "")
    find:SetScript("PreClick", ns.Guard(Before))
    header = CreateFrame("Frame", Key.HEADER, UIParent, "SecureHandlerAttributeTemplate")
    header:SetAttribute("_bind", BIND)
    header:SetAttribute("_onattributechanged", ON_CHANGE)
    Key.Keys()
    Key.Update()
    ns.On("PLAYER_TARGET_CHANGED", Key.Refresh)
    ns.On("UPDATE_BINDINGS", Key.Keys)
    ns.On("PLAYER_REGEN_DISABLED", Fighting)
    ns.On("PLAYER_SOFT_INTERACT_CHANGED", function(_, now)
        soft = Core.Plain(now)
        Key.Refresh()
    end)
    if #keys == 0 and not ns.options.told then
        ns.options.told = true
        Core.Print(HINT)
    end
end
Key.startLater = Later(Key.Start)

-- Standing down: the driver and the snippet stopped, no override binding of ours, the macros empty, the game's
-- settings as they were.
function Key.GiveBack()
    if not header then return PutBack() end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: give back", Key.GiveBack) end
    UnregisterStateDriver(header, "mode")
    header:SetAttribute("_onattributechanged", nil)
    ClearOverrideBindings(header)
    Write(find, "")
    Write(fight, "")
    PutBack()
end
