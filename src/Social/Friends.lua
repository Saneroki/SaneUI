local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Friends
--  The friends list of the full screen (Board.lua), as the game's own
--  (Blizzard_FriendsFrame, its Camelot copy): a row for every friend, the
--  Battle.net ones and the character ones, in the game's order: online
--  Battle.net friends, online characters, a divider, then the offline ones.
--  A row has the status icon (online, away, busy, offline), the name and a
--  line under it (where they are, what they play, or when they were last
--  online), and for a Battle.net friend the icon of the game they are in.
--
--  As the game's: a click chooses a friend, the buttons at the foot act on
--  the one chosen (Send Message, Invite), a right click opens the game's own
--  menu of a friend; Add Friend opens the game's own dialog. Every action is
--  the game's own function; nothing of the game's friends list is changed.
--
--  Read anew when the game tells of a change (a few events, once a frame at
--  most), only while the panel is shown. The search box of the full window
--  finds friends by their names, where they are and their notes.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board = ns.Board
local Friends = {}
ns.Friends = Friends

local STATUS = "Interface\\FriendsFrame\\StatusIcon-" -- Online, Away, DnD, Offline
local DIVIDER = "Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider"
-- The game's colours for its friends list, where this client has them; else those of its other clients.
local function Colour(name, r, g, b, a)
    local colour = rawget(_G, name)
    if type(colour) == "table" and colour.r then return { colour.r, colour.g, colour.b, colour.a or a } end
    return { r, g, b, a }
end
local BNET = Colour("FRIENDS_BNET_NAME_COLOR", 0.510, 0.773, 1)
local WOW = Colour("FRIENDS_WOW_NAME_COLOR", 0.996, 0.882, 0.361)
local GRAY = Colour("FRIENDS_GRAY_COLOR", 0.486, 0.518, 0.541)
local BACKS = { bnet = Colour("FRIENDS_BNET_BACKGROUND_COLOR", 0, 0.694, 0.941, 0.05),
                wow = Colour("FRIENDS_WOW_BACKGROUND_COLOR", 1, 0.824, 0, 0.05),
                offline = Colour("FRIENDS_OFFLINE_BACKGROUND_COLOR", 0.588, 0.588, 0.588, 0.05) }

local panel, box, count, send, invite
local shown
local chosen   -- the friend chosen: "bnet:<account id>" or "wow:<name>"
local query    -- what the search box finds (Core.Fuzzy.Query), nil: everyone
local friends = {} -- the rows as last read

-- Where a friend is: online, away or busy (the game's status icons), or offline.
local function Status(online, afk, dnd)
    if not online then return "Offline" end
    if dnd then return "DnD" end
    if afk then return "Away" end
    return "Online"
end

-- A Battle.net friend: their account's name (or their BattleTag without its number), and the character
-- they play in brackets.
local function BattleNet(index)
    local account = C_BattleNet.GetFriendAccountInfo(index)
    if not account then return nil end
    local game = account.gameAccountInfo or {}
    local online = game.isOnline and true or false
    local name = account.accountName
    if not name or name == "" then name = (account.battleTag or "?"):match("^[^#]+") end
    local character = game.characterName
    local info
    if not online then
        info = rawget(_G, "FRIENDS_LIST_OFFLINE") or "Offline"
    elseif game.clientProgram == rawget(_G, "BNET_CLIENT_WOW") and game.areaName and game.areaName ~= "" then
        info = game.areaName
    else
        info = game.richPresence or ""
    end
    return {
        kind = "bnet", key = "bnet:" .. tostring(account.bnetAccountID), online = online,
        name = name, character = online and character ~= "" and character or nil, info = info,
        status = Status(online, account.isAFK or game.isGameAFK, account.isDND or game.isGameBusy),
        client = online and game.clientProgram or nil, account = account.accountName,
        battleTag = account.battleTag, id = account.bnetAccountID, gameID = game.gameAccountID,
        guid = game.playerGuid, note = account.note,
    }
end

-- A character friend: "Name, Level 60 Warrior" and where they are, as the game's list writes it.
local function Character(index)
    local friend = C_FriendList.GetFriendInfoByIndex(index)
    if not friend or not friend.name then return nil end
    local online = friend.connected and true or false
    local name = friend.name
    if online and friend.level and friend.className then
        local template = rawget(_G, "FRIENDS_LEVEL_TEMPLATE") or "Level %d %s"
        name = name .. ", " .. template:format(friend.level, friend.className)
    end
    return {
        kind = "wow", key = "wow:" .. friend.name, online = online, name = name, whisper = friend.name,
        info = online and (friend.area or "") or (rawget(_G, "FRIENDS_LIST_OFFLINE") or "Offline"),
        status = Status(online, friend.afk, friend.dnd), guid = friend.guid, note = friend.notes,
    }
end

-- Every friend, in the game's order; the numbers online and in all.
local function Read()
    local online, offline = {}, {}
    local bnetTotal, bnetOnline = 0, 0
    if BNGetNumFriends then bnetTotal, bnetOnline = BNGetNumFriends() end
    for index = 1, bnetTotal or 0 do
        local friend = BattleNet(index)
        if friend then table.insert(friend.online and online or offline, friend) end
    end
    local wowTotal, wowOnline = 0, 0
    local legacy = C_FriendList.IsLegacyFriendSystemEnabled
    if not legacy or legacy() then
        wowTotal, wowOnline = C_FriendList.GetNumFriends() or 0, C_FriendList.GetNumOnlineFriends() or 0
        for index = 1, wowTotal do
            local friend = Character(index)
            if friend then table.insert(friend.online and online or offline, friend) end
        end
    end
    return online, offline, (bnetOnline or 0) + wowOnline, (bnetTotal or 0) + wowTotal
end

local function Found(friend)
    return not query or Core.Fuzzy.Match(query, friend.name, friend.character, friend.info, friend.battleTag, friend.note) ~= nil
end

local function Chosen()
    for _, friend in ipairs(friends) do
        if friend.key == chosen then return friend end
    end
end

-- The buttons of the foot, for the friend chosen: a message to one who can get it (a Battle.net friend
-- always, a character online), an invite to one who plays a character of this game.
local function Buttons()
    local friend = Chosen()
    send:SetEnabled(friend ~= nil and (friend.kind == "bnet" or friend.online))
    invite:SetEnabled(friend ~= nil and friend.online and (friend.kind == "wow" or friend.client == rawget(_G, "BNET_CLIENT_WOW")))
end

local function Update()
    if not shown then return end
    local online, offline, on, all = Read()
    wipe(friends)
    local elements = {}
    for _, friend in ipairs(online) do
        if Found(friend) then elements[#elements + 1] = friend end
    end
    if #elements > 0 and #offline > 0 and not query then elements[#elements + 1] = { kind = "divider" } end
    for _, friend in ipairs(offline) do
        if Found(friend) then elements[#elements + 1] = friend end
    end
    for _, element in ipairs(elements) do
        if element.kind ~= "divider" then friends[#friends + 1] = element end
    end
    count:SetText(ns.TEXT.online:format(on, all))
    Board.Fill(box, elements, query and ns.TEXT.noFriendsFound or ns.TEXT.noFriends)
    Buttons()
end

local Changed = Core.Later(function() ns.Safe("friends", Update) end)
local EVENTS = { "FRIENDLIST_UPDATE", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_FRIEND_INFO_CHANGED", "BN_CONNECTED",
                 "BN_DISCONNECTED", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE" }

-- The icon of the game a Battle.net friend plays, as the game's list shows it.
local function Game(texture, client)
    local textures = rawget(_G, "C_Texture")
    local set = textures and textures.SetTitleIconTexture
    local version = Enum and Enum.TitleIconVersion and Enum.TitleIconVersion.Medium
    if set and version and pcall(set, texture, client, version) then return end
    texture:SetAtlas("Battlenet-ClientIcon-" .. client)
end

local function Draw(row, friend)
    Board.Row(row)
    row.friend = friend
    row:EnableMouse(friend.kind ~= "divider")
    row.back:SetShown(friend.kind ~= "divider")
    row.icon:ClearAllPoints()
    if friend.kind == "divider" then
        row.icon:SetTexture(DIVIDER)
        row.icon:SetPoint("LEFT", 0, 0)
        row.icon:SetPoint("RIGHT", 0, 0)
        row.icon:SetHeight(16)
        row.top:SetText("")
        row.bottom:SetText("")
        row.side:Hide()
        row.right:SetText("")
        row:UnlockHighlight()
        return
    end
    local back = BACKS[friend.online and friend.kind or "offline"]
    row.back:SetColorTexture(back[1], back[2], back[3], back[4])
    row.icon:SetTexture(STATUS .. friend.status)
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", 4, -3)
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 22, -4)
    row.top:SetPoint("TOPRIGHT", -34, -4)
    local colour = not friend.online and GRAY or friend.kind == "bnet" and BNET or WOW
    local name = friend.name
    if friend.character then
        name = name .. " |cff" .. Core.Hex(WOW[1], WOW[2], WOW[3]) .. "(" .. friend.character .. ")|r"
    end
    row.top:SetText(name)
    row.top:SetTextColor(colour[1], colour[2], colour[3])
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    row.bottom:SetText(friend.info or "")
    row.right:SetText("")
    row.side:ClearAllPoints()
    row.side:SetSize(24, 24)
    row.side:SetPoint("RIGHT", -6, 0)
    row.side:SetShown(friend.client ~= nil)
    if friend.client then Game(row.side, friend.client) end
    if friend.key == chosen then row:LockHighlight() else row:UnlockHighlight() end
end

-- The game's own menu of a friend (its friends list's right click).
local function Menu(friend)
    if friend.kind == "bnet" then
        local show = rawget(_G, "FriendsFrame_ShowBNDropdown")
        if show then show(friend.account, friend.online, nil, nil, nil, 1, friend.id, nil, nil, nil, nil, friend.battleTag) end
    else
        local show = rawget(_G, "FriendsFrame_ShowDropdown")
        if show then show(friend.whisper, friend.online, nil, nil, nil, 1, nil, nil, nil, nil, friend.guid) end
    end
end

local function Click(row, button)
    local friend = row.friend
    if not friend or friend.kind == "divider" then return end
    if button == "RightButton" then return Menu(friend) end
    chosen = friend.key
    box:ForEachFrame(function(other, element)
        if element.key == chosen then other:LockHighlight() else other:UnlockHighlight() end
    end)
    Buttons()
end

-- A message to the friend chosen, as the game's button Send Message writes one: the line to write in opens
-- with the whisper to them.
local function Send()
    local friend = Chosen()
    if not friend then return end
    if friend.kind == "bnet" then
        ChatFrameUtil.SendBNetTell(friend.account)
    else
        ChatFrameUtil.SendTell(friend.whisper)
    end
end

-- The friend chosen into your group, the game's way: a character by name; a Battle.net friend by their game
-- account (FriendsFrame_InviteOrRequestToJoin: an invite, or a request to join theirs).
local function Invite()
    local friend = Chosen()
    if not friend then return end
    if friend.kind == "wow" then return C_PartyInfo.InviteUnit(friend.whisper) end
    local join = rawget(_G, "FriendsFrame_InviteOrRequestToJoin")
    if join and friend.guid and friend.gameID then
        join(friend.guid, friend.gameID)
    elseif friend.gameID and C_BattleNet.InviteFriend then
        C_BattleNet.InviteFriend(friend.gameID)
    end
end

-- The game's own dialog to add a friend (Blizzard_AddFriend), or its older one.
local function Add()
    local show = rawget(_G, "AddFriendFrame_Show")
    if show then return show() end
    StaticPopup_Show("ADD_FRIEND")
end

function Friends.Build(holder)
    panel = holder
    panel.title:SetText(ns.TEXT.friends)
    count = panel.head:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    count:SetPoint("RIGHT", -ns.Layout.EDGE - 4, 0)
    box = Board.List(panel, function(row, friend)
        Draw(row, friend)
        row:SetScript("OnClick", function(self, button) ns.Safe("friends", Click, self, button) end)
    end)
    local add = Board.Button(panel, Core.Word("ADD_FRIEND", "Add Friend"), 92, Add)
    send = Board.Button(panel, Core.Word("SEND_MESSAGE", "Send Message"), 92, Send, add)
    invite = Board.Button(panel, Core.Word("INVITE", "Invite"), 92, Invite, send)
end

-- Shown, it listens to the game and asks for the list anew (the game's own does that when it opens);
-- hidden, it hears nothing.
function Friends.Show(on)
    shown = on
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    if not on then return end
    if C_FriendList.ShowFriends then C_FriendList.ShowFriends() end
    Update()
end

function Friends.Search(text)
    query = Core.Fuzzy.Query(text)
    Update()
end
