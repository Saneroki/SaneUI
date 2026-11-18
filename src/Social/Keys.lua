local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Keys
--  The game's friends list keys and its group finder key open Social's full
--  screen (Saneroki, 2026-11-18: every entry of Core's dropdown Classic
--  windows a tick, "Keys open ours": unticked, the key opens ours; ticked, the
--  game's own window): whatever keys the game's key bindings give its actions
--  TOGGLESOCIAL and TOGGLEFRIENDSTAB (the friends list) and TOGGLEGROUPFINDER
--  (the group finder) run ours (Bindings.xml, in the game's key bindings under
--  SaneUI), by the game's own override bindings, which leave your key bindings
--  as they are: the full screen with the friends list on it at that tab, and
--  pressed again while it shows that tab, back to its size, as the game's keys
--  toggle its windows.
--
--  Each by its switch (friendsKey, finderKey: the ticks of Classic windows,
--  Social.lua; no control on the options page), only while the full screen can
--  come (Can expand to fullscreen), the module runs and Edit Mode is closed;
--  the finder's only where the finder is ours (Forever: Retail's is the game's
--  own, ns.RetailFinder). Override bindings change out of a fight only: set at
--  the login, anew when your key bindings or the switches change; in a fight,
--  once it is over. Our keys themselves work in a fight too.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Keys = {}
ns.Keys = Keys

-- The game's actions whose keys open ours: its switch, our command and the friends list's tab it shows.
Keys.ACTIONS = {
    { action = "TOGGLESOCIAL", switch = "friendsKey", command = "SANEUI_SOCIAL_FRIENDS", tab = "Friends" },
    { action = "TOGGLEFRIENDSTAB", switch = "friendsKey", command = "SANEUI_SOCIAL_FRIENDS", tab = "Friends" },
    { action = "TOGGLEGROUPFINDER", switch = "finderKey", command = "SANEUI_SOCIAL_FINDER", tab = "Finder" },
}
BINDING_NAME_SANEUI_SOCIAL_FRIENDS = "Social's full screen with the friends list (and back)"
BINDING_NAME_SANEUI_SOCIAL_FINDER = "Social's full screen with the group finder (and back)"

local owner -- the frame our override bindings belong to
local bound -- the keys of those actions and the switches when they were last bound: bound anew only when they change

local function Game(name)
    local fn = rawget(_G, name)
    return type(fn) == "function" and fn or nil
end

-- Whether a key of that switch is ours now: the switch on, the module running, the full screen able to come, Edit
-- Mode closed; the finder's only where it is ours.
function Keys.Taken(switch)
    local options = ns.options or {}
    if owner == nil or ns.off or options.expand == false or options[switch] == false then return false end
    if Core.EditMode and Core.EditMode.active then return false end
    if switch == "finderKey" and (ns.RetailFinder() ~= nil or options.boardFinder == false) then return false end
    return true
end

-- The keys of those actions and whether each is ours, as one line.
local function Signature()
    local keys, parts = Game("GetBindingKey"), {}
    if not keys then return "" end
    for _, each in ipairs(Keys.ACTIONS) do
        local one, two = keys(each.action)
        parts[#parts + 1] = each.action .. "=" .. tostring(one) .. "," .. tostring(two) .. "," .. tostring(Keys.Taken(each.switch))
    end
    return table.concat(parts, "|")
end

-- Our keys on the game's: out of a fight, or once it is over.
function Keys.Bind()
    local clear, set, keys = Game("ClearOverrideBindings"), Game("SetOverrideBinding"), Game("GetBindingKey")
    if not (owner and clear and set and keys) then return end
    if InCombatLockdown() then return Core.AfterCombat("Social: keys", Keys.Bind) end
    clear(owner)
    bound = Signature()
    for _, each in ipairs(Keys.ACTIONS) do
        if Keys.Taken(each.switch) then
            for _, key in ipairs({ keys(each.action) }) do
                if type(key) == "string" and key ~= "" then set(owner, false, key, each.command) end
            end
        end
    end
end

local function Changed()
    if ns.off or Signature() == bound then return end
    Keys.Bind()
end

-- Our key (Bindings.xml): the full screen with the friends list at that tab ("Friends", "Finder"), or pressed again
-- while it stands at that tab, back to its size. The chat window first, if it was put away (as Social's own key).
-- A friends list made a window of its own (the button beside its X) opens or closes by itself (Core.Board.Key).
function Keys.Press(tab)
    if ns.off then return end
    if Core.Board.Key(ns.name, "friends") then return ns.Friends.Want(tab) end
    if not ns.options.window then Core.Set(ns.name, "window", true) end
    local standing = ns.Window.Standing()
    if standing and ns.Board.Has("friends") and ns.Friends.Current() == tab then return ns.Window.Full() end
    if not ns.Board.Holds("friends") then ns.Board.Put("friends", true) end
    ns.Friends.Want(tab)
    if not standing then ns.Window.Full() end
end

function Keys.Start()
    owner = CreateFrame("Frame")
    ns.On("UPDATE_BINDINGS", Changed)
    -- Edit Mode opened or closed: the keys are the game's while it is open (Keys.Taken).
    if Core.EditMode and Core.EditMode.Watch then Core.EditMode.Watch(ns.Guard(Keys.Bind)) end
    Keys.Bind()
end

-- The module stood down: the game's keys are the game's again.
function Keys.Leave()
    if not owner then return end
    if InCombatLockdown() then return Core.AfterCombat("Social: keys", Keys.Leave) end
    local clear = Game("ClearOverrideBindings")
    if clear then clear(owner) end
end
