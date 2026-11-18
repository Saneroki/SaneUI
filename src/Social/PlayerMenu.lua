local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - PlayerMenu
--  A right click on someone in Social (Saneroki, 2026-11-18: "Enable right
--  click on peoples chat messages to have options like invite, whisper, set
--  alias, set note, Ignore, copy character name, pin, show on map, add wow
--  friend, report player"; and on a conversation: "Delete the conversation"):
--  the game's own menu of a player, as a right click on a name in its chat
--  opens it (FriendsFrame_ShowDropdown: Whisper, Invite, Ignore, Report,
--  Copy Character Name, Target; Core adds Set Alias and Set Note, its
--  People.lua), and under it Social's lines, added to the game's menus of a
--  player (Menu.ModifyMenu) only while Social opens one:
--      Add Friend           the character to your friends list
--                           (C_FriendList.AddFriend), where it is not on it
--      Pin them on the map  the map pin at their place, with its golden line
--                           (the game's own, C_Map.SetUserWaypoint): a member
--                           of your group whose place the game tells
--      Show on map          the full map, searching for them (Core.Ways.Look,
--                           the map's search where a module serves it): a
--                           member of your group, a guild member whose SaneUI
--                           says where it stands, else their zone
--      Delete conversation  on a conversation's row: it and all its
--                           messages, asked first
--  A group's conversation has no one player: its row's right click is a menu
--  of Social's own, its name and Delete conversation.
--
--  Where it opens: a right click on a name above a bubble (Links.lua), on a
--  message on the full screen (Select.lua: the list takes the mouse there),
--  and on a whisper's row in the conversations' list (Conversations.lua). The
--  chat at its size lets every click but a link's through into the game, so
--  there the name opens it.
--
--  Opened here (Open), not by the game's FriendsFrame_ShowDropdown or its
--  handling of a player link: those make the chat frame they are given the
--  menu's owner, and the game closes a menu the moment its owner is out of
--  sight (its menu manager, ownerRegion:IsVisible). The game's chat is out of
--  sight under Social's window (Native.lua), so in Forever its menu closed as
--  it opened (Saneroki, 2026-11-18: "never worked"). So the menu is the game's
--  very menu of a player (UnitPopup_OpenMenu, with what those give it), its
--  owner the part of ours clicked on; its chat frame stays the game's, where
--  Whisper writes (in the line, which is in our window, Input.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local PlayerMenu = {}
ns.PlayerMenu = PlayerMenu

PlayerMenu.MENUS = { "FRIEND", "FRIEND_OFFLINE", "BN_FRIEND", "BN_FRIEND_OFFLINE" } -- the game's, MENU_UNIT_<which>
PlayerMenu.TEXT = {
    addFriend = Core.Word("ADD_FRIEND", "Add Friend"),
    addFriendTip = "Puts this character on your friends list.",
    pin = "Pin them on the map",
    pinTip = "The map pin at their place, with the golden line to them.",
    pinNone = "Only for a member of your group whose place the game tells.",
    show = "Show on map",
    showTip = "The full map, searching for them: where they stand in your group, a guild member's SaneUI that says so, else their zone.",
    delete = "Delete conversation",
    deleteTip = "This conversation and all its messages, gone from the list.",
}
local T = PlayerMenu.TEXT

local asked                                          -- what Social opens the game's menu for, while the game makes it
local opened = setmetatable({}, { __mode = "k" })    -- [the menu's context] = asked: a menu made anew keeps its lines

-- The game's menu opened by fn(...) with Social's lines for what (asked: { talk, removed }; {} for a message).
local function With(what, fn, ...)
    asked = what
    local ok, why = pcall(fn, ...)
    asked = nil
    if not ok then error(why, 0) end
end
PlayerMenu.With = With

-- A name as the game compares it: without the realm where it is this one's.
local function Plain(name)
    if type(name) ~= "string" then return nil end
    return Ambiguate and Ambiguate(name, "none") or name
end

-- The member of your group by that name (its unit), or nil.
local function Member(name)
    local wanted = Plain(name)
    if not wanted or not IsInGroup() then return nil end
    local raid = IsInRaid()
    for index = 1, raid and GetNumGroupMembers() or GetNumSubgroupMembers() do
        local unit = (raid and "raid" or "party") .. index
        local own, realm = Core.Ask(UnitName, unit)
        own = Core.Plain(own)
        realm = Core.Plain(realm)
        local full = type(own) == "string" and (type(realm) == "string" and realm ~= "" and own .. "-" .. realm or own)
        if full and Plain(full) == wanted then return unit end
    end
    return nil
end

-- Where a member of your group stands, as the game tells it: map, x, y (0 to 1); nil where it does not.
function PlayerMenu.Place(name)
    local unit = Member(name)
    if not unit then return nil end
    local map = Core.Plain(Core.Ask(C_Map.GetBestMapForUnit, unit))
    local position = map and Core.Ask(C_Map.GetPlayerMapPosition, map, unit)
    local x, y = position and Core.Plain(position.x), position and Core.Plain(position.y)
    if not (type(x) == "number" and type(y) == "number") then return nil end
    if C_Map.CanSetUserWaypointOnMap and Core.Ask(C_Map.CanSetUserWaypointOnMap, map) == false then return nil end
    return map, x, y
end

-- The map pin at their place, tracked: the game's own, which the map's golden line follows.
local function Pin(name)
    local map, x, y = PlayerMenu.Place(name)
    if not map or not (UiMapPoint and C_Map.SetUserWaypoint) then return end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
end

-- Whether the character is on your friends list already.
local function Friend(name)
    local info = C_FriendList and C_FriendList.GetFriendInfo and Core.Ask(C_FriendList.GetFriendInfo, name)
    return type(info) == "table"
end

local function Tip(text)
    return ns.Guard(function(tooltip) GameTooltip_AddNormalLine(tooltip, text) end)
end

-- A line of Social's: its words, what it does, and its tip (greyed out with why, where it cannot).
local function Line(root, text, fn, tip, enabled, why)
    local button = root:CreateButton(text, ns.Guard(fn))
    if button.SetTooltip then button:SetTooltip(Tip(enabled == false and why or tip)) end -- guarded: Tip gives ns.Guard(fn)
    if enabled == false and button.SetEnabled then button:SetEnabled(false) end
    return button
end

-- The conversation and its messages gone, asked first; removed() tells the list.
local function Delete(talk, removed)
    Core.Confirm(ns.TEXT.talkRemove, ns.Talks.Name(talk), function()
        ns.Talks.Remove(talk)
        if removed then removed() end
    end)
end

-- Social's lines under the game's menu of a player, while Social opened it.
local function Extend(_, root, context)
    local what = asked or (type(context) == "table" and opened[context])
    if not what or type(context) ~= "table" then return end
    opened[context] = what
    root:CreateDivider()
    local name = context.name
    local character = not context.bnetIDAccount and type(name) == "string" and name ~= ""
    local mine = character and Plain(name) == Plain(Core.Ask(UnitName, "player"))
    if character and not mine then
        if not Friend(name) and C_FriendList and C_FriendList.AddFriend then
            Line(root, T.addFriend, function() C_FriendList.AddFriend(name) end, T.addFriendTip)
        end
        Line(root, T.pin, function() Pin(name) end, T.pinTip, PlayerMenu.Place(name) ~= nil, T.pinNone)
        if Core.Ways.CanLook() then Line(root, T.show, function() Core.Ways.Look(name) end, T.showTip) end
    end
    if what.talk then Line(root, T.delete, function() Delete(what.talk, what.removed) end, T.deleteTip) end
end

if Menu and Menu.ModifyMenu then
    for _, which in ipairs(PlayerMenu.MENUS) do Menu.ModifyMenu("MENU_UNIT_" .. which, ns.Guard(Extend)) end
end

-- The game's menu of a player, owned by owner (a part of ours on show), with Social's lines for what. who: name, and
-- where they wrote (lineID, chatType); a Battle.net friend's account and battleTag. The context is the very one the
-- game's FriendsFrame_ShowDropdown and FriendsFrame_ShowBNDropdown make, the owner aside. False where the game has no
-- such menu.
local function Open(owner, who, what)
    local open = rawget(_G, "UnitPopup_OpenMenu")
    if not open or type(who.name) ~= "string" or who.name == "" then return false end
    local context = {
        name = who.name, lineID = who.lineID, chatType = who.chatType, chatTarget = who.name,
        chatFrame = DEFAULT_CHAT_FRAME, bnetIDAccount = who.account, battleTag = who.battleTag, ownerFrame = owner,
    }
    opened[context] = what
    With(what, open, who.account and "BN_FRIEND" or "FRIEND", context)
    return true
end
PlayerMenu.Open = Open

-- The parts of a link's options, split at its colons (empty ones kept).
local function Parts(text)
    local parts = {}
    for part in (text .. ":"):gmatch("([^:]*):") do parts[#parts + 1] = part end
    return parts
end

-- Whom a player's link names ("player:Name-Realm:lineID:chatType", "BNplayer:name:account:lineID:chatType"); nil
-- for any other link, or a Battle.net link of your own.
function PlayerMenu.Who(link)
    if type(link) ~= "string" then return nil end
    local kind, rest = link:match("^(%a+):(.*)$")
    if kind == "player" then
        local name, lineID, chatType = unpack(Parts(rest))
        return { name = name, lineID = tonumber(lineID), chatType = chatType }
    elseif kind == "BNplayer" then
        local name, account, lineID, chatType = unpack(Parts(rest))
        account = tonumber(account)
        local isSelf = rawget(_G, "BNIsSelf")
        if not account or (isSelf and Core.Ask(isSelf, account) == true) then return nil end
        return { name = name, account = account, lineID = tonumber(lineID), chatType = chatType }
    end
    return nil
end

-- A right click on a player's link in a part of ours (owner): their menu; false where it is none of a player's.
function PlayerMenu.Link(owner, link)
    local who = PlayerMenu.Who(link)
    return who ~= nil and Open(owner, who, {})
end

-- A whisper's row: the game's menu of the player (a Battle.net friend's for one), with Delete conversation; a group's
-- row: Social's own, its name and Delete conversation. removed() tells the list once one is gone.
function PlayerMenu.Talk(owner, talk, removed)
    local what = { talk = talk, removed = removed }
    if talk.kind == "WHISPER" then
        if Open(owner, { name = talk.with, chatType = "WHISPER" }, what) then return end
    elseif talk.kind == "BN_WHISPER" then
        local account = ns.Talks.Account(talk)
        if account and Open(owner, { name = talk.name, account = account, chatType = "BN_WHISPER", battleTag = talk.with },
            what) then
            return
        end
    end
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        root:CreateTitle(ns.Talks.Name(talk))
        Line(root, T.delete, function() Delete(talk, removed) end, T.deleteTip)
    end))
end

-- A message on the full screen (owner: its list): the game's menu of whoever wrote it, as a right click on the name
-- above it opens it (whisper, report with the very line, ...); nothing for yours, a note or a creature's.
function PlayerMenu.Message(owner, entry)
    if type(entry) ~= "table" or entry.side ~= "left" or type(entry.link) ~= "string" then return end
    local link = entry.link:match("^|H(.-)|h")
    if link then PlayerMenu.Link(owner, link) end
end
