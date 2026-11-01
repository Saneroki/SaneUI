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
--            click does; what is taken is the game's loot window's to say.
--            Away from you the game's Click-to-Move runs you there first (the
--            switch Walk to corpses): for a moment after a fight the interact
--            key looks all around you and further (Key.REACH), so that it picks
--            the corpses behind you too, and your target's corpse counts as
--            well, however far
--    fight   in a fight, your target a living foe: the button Fight, which
--            marks it and attacks it
--    talk    a living NPC right in front of you that is no foe, the one the
--            game's interact key would talk to (the switch Talk to NPCs):
--            Interact With Target; a quest giver's quests then go as
--            Quests.lua says
--    use     the thing of the world in front of you is one your quests or your
--            guide want (Wanted.Object; the switch Quest objects): Interact
--            With Target, which picks it up, opens or uses it
--    fight   your target a living foe: Fight
--    talk    your target a living NPC that is no foe and is wanted (the switch
--            Talk to NPCs): Interact With Target. Far away, the game's own
--            Click-to-Move runs you there first (the switch Walk to the NPC
--            found: lent while such an NPC is your target, given back after)
--    use     out of a fight, your target the one a step's item is used on, as
--            the step's words say (a corpse, a creature or NPC they name;
--            Items.OnTarget; the switch Use items on what is found): the
--            button Use. This comes before talking and fighting; a friendly
--            target only once it is within the item's reach (looked at three
--            times a second while it is your target), and never again on a
--            target the game refused the item on
--    find    else: the button Find. Its macro is the hearth when your guide's
--            step wants it (Items.lua); else it lets your target go, targets
--            the first wanted name around you (Wanted.lua), marks it with a
--            skull and starts the attack on a foe, and when it found none,
--            uses one quest item (Items.lua)
--
--  A state driver of the game reads loot, a foe in a fight, an NPC in front of
--  you, a foe, a friend from the macro conditions; the header's snippet then
--  puts that action on the key's keys as override bindings of its own (above
--  other overrides). "Friend" is any living target that is no foe (noharm):
--  the condition help holds only for one your spells could help, which many
--  quest givers are not (Saneroki, 2026-10-26: the key talked to none in
--  Retail). Whether your friendly target is wanted, whether the NPC in front of
--  you is one to talk to (a creature, alive, no foe), whether it is one you are
--  through with (Quests.Left: no talking to it again), whether your target's
--  corpse has loot and whether the thing in front of you is a wanted one the
--  module says out of a fight (the attributes wanted, npc, left, corpse and
--  object), and the macros are written out of a fight only: anew the moment
--  before each press (PreClick) and when the quests change, without hearth and
--  items as a fight begins. In a fight they all stay as they were.
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
Key.AIM = 0.3   -- seconds between looks at a target's reach while a step's item waits to be used on it
Key.LOOK = 2    -- seconds after a fight, and after the last corpse it found, the interact key looks all around you
Key.LOOKS = 30  -- seconds it does that at most after a fight, should a corpse be out of reach
Key.TICK = 0.5  -- seconds between looks at the corpses meanwhile
Key.FIRST = "E" -- the key it gets where it has none (Saneroki, 2026-10-30), once: the game's Strafe Right is the game's
Key.SETTLE = 3  -- seconds after the login before that: the profile's key bindings are written first (Sync)
Key.REACH = { SoftTargetInteractArc = "2", SoftTargetInteractRange = "30" } -- all around you, as far as a spell reaches
Key.HEADER, Key.FIND, Key.FIGHT = "SaneUISpeedLevelingKey", "SaneUISpeedLevelingFind", "SaneUISpeedLevelingFight"
Key.USE = "SaneUISpeedLevelingUse"
Key.LINK = "SaneUISLFind"  -- the chain's buttons: SaneUISLFind2, SaneUISLFind3, ...
Key.COMMAND = "CLICK " .. Key.FIND .. ":LeftButton" -- the key's own binding (Bindings.xml)

-- Its words in the game's key bindings.
_G["BINDING_NAME_" .. Key.COMMAND] = ns.TEXT.binding

-- What the macro conditions tell the state driver: the first that holds.
local LOOT = "[@softinteract,exists,dead] loot; "
local FIGHT = "[@target,harm,nodead,combat] fight; "
local NEAR = "[@softinteract,exists,help,nodead] near; "
local REST = "[@target,harm,nodead] foe; [@target,noharm,nodead] friend; [@target,exists,dead] corpse; find"

-- The header's snippets, which the game runs in its restricted environment, in a fight too. A change of the state
-- or of what decides it: the action due on each of the key's keys.
local ON_CHANGE = [[
    if name == "state-mode" or name == "wanted" or name == "object" or name == "talk" or name == "keys"
        or name == "use" or name == "npc" or name == "left" or name == "corpse" then
        self:RunAttribute("_bind")
    end
]]
local BIND = [[
    local state = self:GetAttribute("state-mode")
    local action = "find"
    if state == "loot" then
        action = "interact"
    elseif state == "fight" then
        action = "fight"
    elseif self:GetAttribute("use") then
        action = "use"
    elseif state == "corpse" and self:GetAttribute("corpse") then
        action = "interact"
    elseif (state == "near" and not self:GetAttribute("left")) or self:GetAttribute("npc") then
        action = "interact"
    elseif self:GetAttribute("object") then
        action = "interact"
    elseif state == "foe" then
        action = self:GetAttribute("wanted") and "fight" or "find"
    elseif state == "friend" and self:GetAttribute("wanted") and self:GetAttribute("talk") then
        action = "interact"
    end
    self:SetAttribute("action", action)
    self:ClearBindings()
    for index = 1, self:GetAttribute("keys") or 0 do
        local key = self:GetAttribute("key" .. index)
        if action == "interact" then
            self:SetBinding(true, key, "INTERACTTARGET")
        elseif action == "fight" then
            self:SetBindingClick(true, key, "SaneUISpeedLevelingFight")
        elseif action == "use" then
            self:SetBindingClick(true, key, "SaneUISpeedLevelingUse")
        else
            self:SetBindingClick(true, key, "SaneUISpeedLevelingFind")
        end
    end
]]

-- What the key needs of the game's settings, each as text: its interact key on for the mouse and keyboard too (it
-- picks the corpse, the NPC or the thing in front of you).
local ANY = Enum and Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any or 3
local SETTINGS = { softTargetInteract = tostring(ANY) }
-- What Walk to the NPC found lends, only while such an NPC is your target: the game's Click-to-Move, with which its
-- Interact With Target runs you to the target first.
local WALK, WALKING = "autointeract", "1"

local header, find, fight, use
local links = {}  -- the chain's buttons, in order
local keys        -- the key's keys as the header has them; nil before the first reading
local soft        -- the GUID of what the interact key would use now, as the game last said
local using       -- the item the button Use uses on your target now, or nil
local refused = { items = {} } -- the items the game refused on the target now (refused.guid: which target)
local aiming      -- the ticker looking at a friendly target's reach, while a step's item waits for it
local looking     -- while the interact key looks all around you: until when, and the last moment it may (stop, last)

local function Same(a, b)
    return tostring(a) == tostring(b)
end

-- A setting lent: what it was kept (the first time only) to be put back.
local function Borrow(name, value)
    local kept = ns.options.foundCVars
    local now = Core.Ask(C_CVar.GetCVar, name)
    if now ~= nil and not Same(now, value) then
        Core.Ask(C_CVar.SetCVar, name, value)
        if not kept[name] and Same(Core.Ask(C_CVar.GetCVar, name), value) then kept[name] = { was = now, set = value } end
    end
end

-- A kept setting back as it was, unless it was changed since.
local function Return(name)
    local kept = ns.options.foundCVars
    local entry = kept[name]
    if type(entry) == "table" and Same(Core.Ask(C_CVar.GetCVar, name), entry.set) then
        Core.Ask(C_CVar.SetCVar, name, entry.was)
    end
    kept[name] = nil
end

-- Each setting the key needs, as needed.
local function Lend()
    for name, value in pairs(SETTINGS) do Borrow(name, value) end
end

-- Every kept setting back as it was.
local function PutBack()
    for name in pairs(ns.options.foundCVars) do Return(name) end
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
-- for when none is found (the switch Quest items). In a fight (fighting): the names alone. names: what is wanted, where
-- the caller asked for it already (Key.Refresh asks once for all it does).
function Key.Find(fighting, names)
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
    return Key.Macros(names or (ns.Wanted.Names()), use)
end

-- The macro of Fight: your living foe marked (the switch) and attacked.
local function Attack()
    return ns.options.skull and "/tm [harm,nodead] !8\n/startattack [harm,nodead]" or "/startattack [harm,nodead]"
end

local function Write(button, text)
    if button:GetAttribute("macrotext") ~= text then button:SetAttribute("macrotext", text) end
end

-- The header told only what changed: each attribute set runs its snippet, the bindings anew.
local function Set(name, value)
    if header:GetAttribute(name) ~= value then header:SetAttribute(name, value) end
end

local function WriteFind(texts)
    Write(find, texts[1])
    for at, link in ipairs(links) do Write(link, texts[at + 1] or "") end
end

-- The moment before a press of Find, out of a fight: its macros from what is wanted now.
local function Before()
    if not InCombatLockdown() then WriteFind(Key.Find()) end
end

-- Whether a unit is a living NPC that is no foe (one to talk to or walk to): friendly or neutral, as long as it cannot
-- be attacked.
local function Peaceful(unit)
    return Core.Ask(UnitExists, unit) and not Core.Ask(UnitIsPlayer, unit) and not Core.Ask(UnitIsDead, unit)
        and Core.Ask(UnitCanAttack, "player", unit) ~= true
end

local function Friendly()
    return Peaceful("target")
end

-- Whether the interact key's pick (its GUID) is an NPC to talk to: a creature, alive, no foe (the switch Talk to NPCs).
local function Talkable(guid)
    if not ns.options.talk or type(guid) ~= "string" then return false end
    if not (guid:find("^Creature%-") or guid:find("^Vehicle%-")) then return false end
    return Peaceful("softinteract") and true or false
end

-- Whether a unit is a corpse with loot for you, as the game says.
local function Spoils(unit)
    if not (Core.Ask(UnitExists, unit) and Core.Ask(UnitIsDead, unit)) then return false end
    return Core.Ask(rawget(_G, "CanLootUnit"), Core.Ask(UnitGUID, unit)) == true
end

local function Walks()
    return ns.options.loot and ns.options.corpses
end

-- Whether a corpse is there to walk to (the switch Walk to corpses): your target's, or the interact key's pick.
local function Corpse()
    if not Walks() then return false end
    return Spoils("target") or (Core.Ask(UnitExists, "softinteract") and Core.Ask(UnitIsDead, "softinteract") and true or false)
end

local Aim

-- While a step's item waits for a friendly target to come within reach, looked at again a few times a second.
local function Watch(on)
    if on and not aiming then
        aiming = C_Timer.NewTicker(Key.AIM, Key.aimLater)
    elseif not on and aiming then
        aiming:Cancel()
        aiming = nil
    end
end

-- Out of a fight: the step's item for your target now (the button Use, the attribute use), and the game's
-- Click-to-Move lent while a living friendly NPC the key wants is your target (the switch Walk to the NPC found) and
-- while a corpse is there to walk to (the switch Walk to corpses).
function Aim()
    if not header or ns.off then return Watch(false) end
    if InCombatLockdown() then return end
    local guid = Core.Ask(UnitGUID, "target")
    if guid ~= refused.guid then refused.guid, refused.items = guid, {} end
    using = ns.options.useOn and ns.Items.OnTarget(refused.items) or nil
    Write(use, using and ("/use item:" .. using) or "")
    if (header:GetAttribute("use") and true or false) ~= (using ~= nil) then header:SetAttribute("use", using ~= nil) end
    local friendly = Friendly()
    local npc = ns.options.walk and ns.options.talk and friendly and header:GetAttribute("wanted") and not using
    if npc or Corpse() then Borrow(WALK, WALKING) else Return(WALK) end
    local waits = ns.options.useOn and friendly and not using and ns.Guide.UseOn()
    Watch(waits and waits[1] ~= nil or false)
end
Key.aimLater = ns.Guard(function() Aim() end)

-- The interact key looks all around you and further, or as far as it did before.
local function Reach(on)
    for name, value in pairs(Key.REACH) do
        if on then Borrow(name, value) else Return(name) end
    end
end

local function StopLooking()
    looking = nil
    Reach(false)
    Key.Refresh()
end

-- While the interact key looks around after a fight: on for as long as it finds corpses, then as far as it did before.
local LookOn
local function Look()
    if not looking then return end
    Key.Refresh()
    local now = GetTime()
    if Corpse() then looking.stop = math.min(now + Key.LOOK, looking.last) end
    if now >= looking.stop or not header or ns.off then return StopLooking() end
    LookOn()
end
LookOn = Core.Later(function() ns.Guarded(Look) end, Key.TICK)

-- A fight is over: the corpses around you, for a moment (the switch Walk to corpses).
local function Over()
    if header and not ns.off and Walks() then
        local now = GetTime()
        looking = { stop = now + Key.LOOK, last = now + Key.LOOKS }
        Reach(true)
        LookOn()
    end
    Key.Refresh()
end

-- The game refused the item the button Use used on your target (a cast that failed, not one too far): not again on
-- that target.
local function Refused(unit, _, spell)
    if unit ~= "player" or not using or InCombatLockdown() then return end
    local items = rawget(_G, "C_Item")
    local _, itemSpell = Core.Ask(items and items.GetItemSpell, using)
    if Core.Plain(spell) ~= itemSpell then return end
    if Core.Ask(items and items.IsItemInRange, using, "target") == false then return end
    refused.items[using] = true
    Aim()
end

-- A fight begins (the moment before the lock): Find without the hearth and items, which a fight would only break; no
-- item used on the target and no Click-to-Move in the fight.
local function Fighting()
    if InCombatLockdown() or not header or ns.off then return end
    WriteFind(Key.Find(true))
    if header:GetAttribute("use") then header:SetAttribute("use", false) end
    if header:GetAttribute("npc") then header:SetAttribute("npc", false) end
    if header:GetAttribute("corpse") then header:SetAttribute("corpse", false) end
    using = nil
    looking = nil
    Reach(false)
    Return(WALK)
    Watch(false)
end

local function Later(fn)
    return function() ns.Guarded(fn) end
end

-- Out of a fight: whether your target is wanted, whether its corpse has loot, whether the interact key's thing is a
-- wanted one or an NPC you are through with, and the macros of Find, as they are now. While the interact key looks all
-- around you only its corpses count: what else it picks then may be far away.
function Key.Refresh()
    if not header or ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: refresh", Key.refreshLater) end
    local thing, target = soft or Core.Ask(UnitGUID, "softinteract"), Core.Ask(UnitGUID, "target")
    ns.Quests.Moved(thing, target)
    -- What is wanted, asked once for all of it: your target, the thing in front of you and Find's macros.
    local names, have = ns.Wanted.Names()
    Set("wanted", ns.Wanted.Unit("target", have) and not ns.Quests.Left(target, true))
    Set("corpse", Walks() and Spoils("target") or false)
    local left = looking ~= nil or ns.Quests.Left(thing, ns.Wanted.Unit("softinteract", have))
    Set("left", left)
    Set("npc", not left and Talkable(thing))
    Set("object", not looking and ns.options.objects and ns.Wanted.Object(thing) or false)
    WriteFind(Key.Find(false, names))
    Aim()
end
Key.refreshLater = Later(Key.Refresh)

-- The key's keys from the game's key bindings onto the header, when they changed.
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

-- No key on the profile Speedleveling: it gets Key.FIRST, once, and the chat says so; one taken off again stays off,
-- and the module says so at every login. The game keeps key bindings per account, so a new account starts without it,
-- and a key may still be bound to a button that is gone (Saneroki, 2026-10-29: E did nothing). The other profiles have
-- key bindings of their own, without it (Saneroki, 2026-10-30). Nothing until the keys were read (keys nil).
local function FirstKey()
    if not header or ns.off or not keys or #keys > 0 or not Core.Profiles.Leveling() then return end
    if ns.options.keyGiven then return Core.Print(ns.TEXT.hint) end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: first key", Key.firstLater) end
    ns.options.keyGiven = true
    Core.Ask(rawget(_G, "SetBinding"), Key.FIRST, Key.COMMAND)
    Core.Ask(rawget(_G, "SaveBindings"), Core.Ask(rawget(_G, "GetCurrentBindingSet")))
    Core.Print(ns.TEXT.keyFirst:format(Key.FIRST))
end
Key.firstLater = Later(FirstKey)
local FirstSoon = Core.Later(Key.firstLater, Key.SETTLE)
Key.First = FirstSoon

-- The switches as they are: the game's interact key for Loot first, Talk to NPCs and Quest objects, the driver's
-- conditions, the macros.
function Key.Update()
    if not header or ns.off then return end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: settings", Key.updateLater) end
    if ns.options.loot or ns.options.objects or ns.options.talk then Lend() else PutBack() end
    if not looking then Reach(false) end
    Write(fight, Attack())
    Set("talk", ns.options.talk and true or false)
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
    find, fight, use = Button(Key.FIND, ""), Button(Key.FIGHT, ""), Button(Key.USE, "")
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
    ns.On("PLAYER_REGEN_ENABLED", Over)
    ns.On("LOOT_CLOSED", Key.Refresh)
    ns.On("UNIT_SPELLCAST_FAILED", Refused)
    ns.On("PLAYER_SOFT_INTERACT_CHANGED", function(_, now)
        soft = Core.Plain(now)
        Key.Refresh()
    end)
    FirstSoon()
end
Key.startLater = Later(Key.Start)

-- /sane key: what the key sees now, in chat, and kept for the account (keyCheck, read after a /reload): its state and
-- what a press does, the NPC or thing in front of you and your target as the game judges them, the item for your
-- target, Click-to-Move.
local function Seen(unit)
    if not Core.Ask(UnitExists, unit) then return ns.TEXT.keyNobody end
    local guid = Core.Ask(UnitGUID, unit)
    local judged = {}
    if Core.Ask(UnitIsDead, unit) then judged[#judged + 1] = "dead" end
    judged[#judged + 1] = Core.Ask(UnitCanAttack, "player", unit) and "a foe" or "no foe"
    if Core.Ask(UnitIsFriend, "player", unit) then judged[#judged + 1] = "friendly" end
    if Core.Ask(UnitCanAssist, "player", unit) then judged[#judged + 1] = "helpable" end
    return ns.TEXT.keyUnit:format(tostring(Core.Ask(UnitName, unit)),
        tostring(type(guid) == "string" and guid:match("^(%a+)") or "?"), table.concat(judged, ", "))
end

function Key.Check()
    local lines
    if not header then
        lines = { ns.TEXT.keyNone }
    else
        local guide = ns.Run.Guide()
        lines = {
            ns.TEXT.keyState:format(tostring(header:GetAttribute("state-mode")), tostring(header:GetAttribute("action")),
                keys and keys[1] and table.concat(keys, ", ") or ns.TEXT.keyNoKey),
            ns.TEXT.keyFront:format(Seen("softinteract"), tostring(header:GetAttribute("npc")),
                tostring(header:GetAttribute("object"))),
            ns.TEXT.keyTarget:format(Seen("target"), tostring(header:GetAttribute("wanted")), tostring(using)),
            ns.TEXT.keyCorpse:format(tostring(header:GetAttribute("corpse")), tostring(looking ~= nil),
                tostring(header:GetAttribute("left"))),
            ns.TEXT.keyWalk:format(tostring(Core.Ask(C_CVar.GetCVar, WALK)), tostring(ns.options.foundCVars[WALK] ~= nil),
                guide and ns.Guide.Following() and tostring(guide.name) or "not followed"),
        }
    end
    for _, line in ipairs(lines) do Core.Print(line) end
    Core.Store(ns.name).keyCheck = { when = Core.Ask(date, "%Y-%m-%d %H:%M:%S"), lines = lines }
end

-- Standing down: the driver and the snippet stopped, no override binding of ours, the macros empty, the game's
-- settings as they were.
function Key.GiveBack()
    if not header then return PutBack() end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: give back", Key.GiveBack) end
    if not ns.off then return end -- woken up in the same fight
    UnregisterStateDriver(header, "mode")
    header:SetAttribute("_onattributechanged", nil)
    ClearOverrideBindings(header)
    Write(find, "")
    Write(fight, "")
    Write(use, "")
    for _, link in ipairs(links) do Write(link, "") end
    Watch(false)
    looking = nil
    PutBack()
end

-- After a rest (no switch on, then one is): the header hears again, the settings lent, the action due put on the key's
-- keys anew. A key never made is made now: its start waited for a fight's end at the login, and the module rested by
-- then (a guarded step does nothing while it rests).
function Key.Wake()
    if not header then return Key.Start() end
    if InCombatLockdown() then return Core.AfterCombat("Speed Leveling: wake", Key.wakeLater) end
    header:SetAttribute("_onattributechanged", ON_CHANGE)
    header:SetAttribute("keys", 0)
    Key.Update()
    header:SetAttribute("keys", keys and #keys or 0)
    FirstSoon()
end
Key.wakeLater = Later(Key.Wake)
