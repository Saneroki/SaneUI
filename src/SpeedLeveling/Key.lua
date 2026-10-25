local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Key
--  The key (Bindings.xml: in the game's key bindings under Sane UI) and what
--  one press of it does. An addon may target, mark, attack and interact only by
--  the game's secure ways and on a key press, so the choice is made by those,
--  in a fight too. What is due first (Saneroki, 2026-10-25: loot, then the
--  quest givers, then the things on the ground, then the foes; the order the
--  game's own gamepad button keeps):
--
--    loot    a corpse with loot beside you (the game's own pick for its
--            interact key, its "soft" target, dead; the switch Loot first):
--            the game's Interact With Target, which opens its loot as a right
--            click does; what is taken is the game's loot window's to say
--    fight   in a fight, your target a living foe: the button Fight, which
--            marks it and attacks it
--    talk    a living friendly NPC right in front of you, the one the game's
--            interact key would talk to (the switch Talk to NPCs): Interact
--            With Target; a quest giver's quests then go as Quests.lua says
--    use     the thing of the world in front of you is one your quests or your
--            guide want (Wanted.Object; the switch Quest objects): Interact
--            With Target, which picks it up, opens or uses it
--    fight   your target a living foe: Fight
--    talk    your target a living friendly NPC that is wanted (the switch Talk
--            to NPCs): Interact With Target
--    find    else: the button Find. Its macro is the hearth when your guide's
--            step wants it (Items.lua); else it lets your target go, targets
--            the first wanted name around you (Wanted.lua), marks it with a
--            skull and starts the attack on a foe, and when it found none,
--            uses one quest item (Items.lua)
--
--  A state driver of the game reads loot, a foe in a fight, an NPC in front of
--  you, a foe, a friend from the macro conditions; the header's snippet then
--  puts that action on the key's keys as override bindings of its own (above
--  other overrides). Whether your friendly target is wanted and whether the
--  thing in front of you is a wanted one the module says out of a fight (the
--  attributes wanted and object), and the macros are written out of a fight
--  only: anew the moment before each press (PreClick) and when the quests
--  change, without hearth and items as a fight begins. In a fight they all stay
--  as they were.
--
--  The game runs only the first 255 characters of a button's macro, so the
--  names go into a chain: Find holds the first names and its ending (the mark,
--  the attack, the item), and while nothing is found it clicks the next button
--  of the chain (/click), which holds the next names; the game runs that
--  button's macro there and then goes on with Find's ending.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Key = {}
ns.Key = Key

Key.ROOM = 255  -- characters of a button's macro text the game runs
Key.LINKS = 4   -- buttons in the chain after Find
Key.HEADER, Key.FIND, Key.FIGHT = "SaneUISpeedLevelingKey", "SaneUISpeedLevelingFind", "SaneUISpeedLevelingFight"
Key.LINK = "SaneUISLFind"  -- the chain's buttons: SaneUISLFind2, SaneUISLFind3, ...
Key.COMMAND = "CLICK " .. Key.FIND .. ":LeftButton" -- the key's own binding (Bindings.xml)

-- Its words in the game's key bindings.
_G["BINDING_NAME_" .. Key.COMMAND] = ns.TEXT.binding

-- What the macro conditions tell the state driver: the first that holds.
local LOOT = "[@softinteract,exists,dead] loot; "
local FIGHT = "[@target,harm,nodead,combat] fight; "
local NEAR = "[@softinteract,exists,help,nodead] near; "
local REST = "[@target,harm,nodead] foe; [@target,help,nodead] friend; find"

-- The header's snippets, which the game runs in its restricted environment, in a fight too. A change of the state
-- or of what decides it: the action due on each of the key's keys.
local ON_CHANGE = [[
    if name == "state-mode" or name == "wanted" or name == "object" or name == "talk" or name == "keys" then
        self:RunAttribute("_bind")
    end
]]
local BIND = [[
    local state = self:GetAttribute("state-mode")
    local action = "find"
    if state == "loot" or state == "near" then
        action = "interact"
    elseif state == "fight" then
        action = "fight"
    elseif self:GetAttribute("object") then
        action = "interact"
    elseif state == "foe" then
        action = self:GetAttribute("wanted") and "fight" or "find"
    elseif state == "friend" and self:GetAttribute("wanted") and self:GetAttribute("talk") then
        action = "interact"
    end
    self:ClearBindings()
    for index = 1, self:GetAttribute("keys") or 0 do
        local key = self:GetAttribute("key" .. index)
        if action == "interact" then
            self:SetBinding(true, key, "INTERACTTARGET")
        elseif action == "fight" then
            self:SetBindingClick(true, key, "SaneUISpeedLevelingFight")
        else
            self:SetBindingClick(true, key, "SaneUISpeedLevelingFind")
        end
    end
]]

-- What the key needs of the game's settings, each as text: its interact key on for the mouse and keyboard too (it
-- picks the corpse, the NPC or the thing in front of you).
local ANY = Enum and Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any or 3
local SETTINGS = { softTargetInteract = tostring(ANY) }

local header, find, fight
local links = {}  -- the chain's buttons, in order
local keys        -- the key's keys as the header has them; nil before the first reading
local soft        -- the GUID of what the interact key would use now, as the game last said

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
    return type(name) == "string" and name ~= "" and not name:find("[;%[%]\n]")
end

-- The macros of Find and of the chain after it: your target let go, the first wanted name around you targeted (a
-- dead one is passed over, the next may take its place, and let go at the end), the one found marked and a foe
-- attacked; with use (a macro line), that line when none was found. As many names as there is room for in the
-- chain, the first first. A list: Find's text, then each link's ("" for one not needed).
function Key.Macros(names, use)
    local tail = { "/cleartarget [dead]" }
    if ns.options.skull then tail[#tail + 1] = "/tm [exists] !8" end
    tail[#tail + 1] = "/startattack [harm,nodead]"
    if use then tail[#tail + 1] = "/stopmacro [exists]\n" .. use end
    local ending = table.concat(tail, "\n")
    local texts = {}
    local lines = { "/cleartarget" }
    local index = 1 -- the chain's button being filled: 1 is Find
    local function Room() -- what one button has for names: its click to the next and, for Find, the head and ending
        local room = Key.ROOM
        if index <= Key.LINKS then room = room - #("/click [noexists][dead] " .. Key.LINK .. (index + 1)) - 1 end
        if index == 1 then room = room - #lines[1] - 1 - #ending - 1 end
        return room
    end
    local room, used = Room(), 0
    for _, name in ipairs(names) do
        local line = "/targetexact [noexists][dead] " .. name
        if Fits(name) then
            while index <= Key.LINKS + 1 and used + #line + 1 > room do
                texts[index] = lines
                index, lines, used = index + 1, {}, 0
                room = Room()
            end
            if index > Key.LINKS + 1 then break end
            lines[#lines + 1] = line
            used = used + #line + 1
        end
    end
    texts[index] = lines
    -- Each button's text: its names, the click to the next where that holds names, Find's ending.
    local found = false
    for at = 1, Key.LINKS + 1 do
        local own = texts[at] or {}
        found = found or #own > (at == 1 and 1 or 0)
        if texts[at + 1] and #texts[at + 1] > 0 then own[#own + 1] = "/click [noexists][dead] " .. Key.LINK .. (at + 1) end
        if at == 1 then own[#own + 1] = ending end
        texts[at] = table.concat(own, "\n")
    end
    if not found then texts[1] = use or "" end
    return texts
end

-- Find's macros now: the hearth the guide's step wants (the switch Hearthstone), else the wanted names with one item
-- for when none is found (the switch Quest items). In a fight (fighting): the names alone.
function Key.Find(fighting)
    local items, spells
    if ns.options.guide then items, spells = ns.Guide.Uses() end
    if not fighting and ns.options.hearth then
        local hearth = ns.Items.Hearth(items, spells)
        if hearth then
            local texts = { hearth }
            for at = 2, Key.LINKS + 1 do texts[at] = "" end
            return texts
        end
    end
    local use = not fighting and ns.options.items and ns.Items.Pick(items) or nil
    return Key.Macros((ns.Wanted.Names()), use)
end

-- The macro of Fight: your living foe marked (the switch) and attacked.
local function Attack()
    return ns.options.skull and "/tm [harm,nodead] !8\n/startattack [harm,nodead]" or "/startattack [harm,nodead]"
end

local function Write(button, text)
    if button:GetAttribute("macrotext") ~= text then button:SetAttribute("macrotext", text) end
end

local function WriteFind(texts)
    Write(find, texts[1])
    for at, link in ipairs(links) do Write(link, texts[at + 1] or "") end
end

-- The moment before a press of Find, out of a fight: its macros from what is wanted now.
local function Before()
    if not InCombatLockdown() then WriteFind(Key.Find()) end
end

-- A fight begins (the moment before the lock): Find without the hearth and items, which a fight would only break.
local function Fighting()
    if not InCombatLockdown() and header and not ns.off then WriteFind(Key.Find(true)) end
end

local function Later(fn)
    return function() ns.Guarded(fn) end
end

-- Out of a fight: whether your target is wanted, whether the interact key's thing is a wanted one, and the macros of
-- Find, as they are now.
function Key.Refresh()
    if not header or ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: refresh", Key.refreshLater) end
    header:SetAttribute("wanted", ns.Wanted.Unit("target"))
    local thing = soft or Core.Ask(UnitGUID, "softinteract")
    header:SetAttribute("object", ns.options.objects and ns.Wanted.Object(thing) or false)
    WriteFind(Key.Find())
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

-- The switches as they are: the game's interact key for Loot first, Talk to NPCs and Quest objects, the driver's
-- conditions, the macros.
function Key.Update()
    if not header or ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: settings", Key.updateLater) end
    if ns.options.loot or ns.options.objects or ns.options.talk then Lend() else PutBack() end
    Write(fight, Attack())
    header:SetAttribute("talk", ns.options.talk and true or false)
    RegisterStateDriver(header, "mode", (ns.options.loot and LOOT or "") .. FIGHT .. (ns.options.talk and NEAR or "")
        .. REST)
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
    -- The chain's buttons are clicked by Find's macro, a click without key down: they act on it.
    for at = 2, Key.LINKS + 1 do
        local link = Button(Key.LINK .. at, "")
        link:SetAttribute("useOnKeyDown", false)
        links[#links + 1] = link
    end
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
        Core.Print(ns.TEXT.hint)
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
    for _, link in ipairs(links) do Write(link, "") end
    PutBack()
end
