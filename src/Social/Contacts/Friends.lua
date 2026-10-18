local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Friends
--  The friends list itself, as the game's (Blizzard_FriendsFrame, its Camelot
--  copy), in its order: your favourite Battle.net friends, a divider, the
--  Battle.net friends and characters online, a divider, the offline ones. A
--  row has the status icon (online, away, busy, offline), the name (for a
--  Battle.net friend with the character they play in brackets, a star for a
--  favourite), a line under it (where they are, what they play, or when they
--  were last online), and at its right the icon of the game a Battle.net friend
--  is in and the game's button to ask them into your group.
--
--  As the game's: a click chooses a friend, the buttons at the foot act on the
--  one chosen (Add Friend, Send Message, Invite); a right click opens the
--  game's own menu of a friend; the mouse on a row tells who they are: their
--  character, where, their note, their broadcast, their other games. The invite
--  button asks a Battle.net friend into your group, or to let you into theirs,
--  on the game account that can be asked (a menu where there are several);
--  greyed, its tooltip says why not. Every action is the game's own function;
--  nothing of the game's friends list is changed.
--
--  Read anew when the game tells of a change (a few events, once a frame at
--  most), only while the list is shown. The search box finds friends by their
--  names, where they are and their notes; the filter keeps them by status and
--  by kind (Battle.net friends, characters).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Layout, Contacts = ns.Board, ns.Layout, ns.Contacts
local View = { name = ns.TEXT.friends }
Contacts.Friends = View

local box, send, invite
local shown
local chosen   -- the friend chosen: "bnet:<account id>" or "wow:<name>"
local query    -- what the search box finds (Core.Fuzzy.Query), nil: everyone
local wanted, kinds = {}, {} -- the filter: statuses ticked, kinds ticked ("bnet", "wow"); none: all
local friends = {} -- the rows as last read

-- Why the game will not ask a game account into your group, in its words, nearest to an invite first: one
-- of another faction (where the game keeps them apart), without a known realm, in another region, in
-- another version of the game, in another game.
local REFUSALS = {
    { key = "faction", word = "ERR_TRAVEL_PASS_NOT_ALLIED", text = "You cannot invite players of the other faction." },
    { key = "info", word = "ERR_TRAVEL_PASS_NO_INFO", text = "Not enough information about this player yet." },
    { key = "region", word = "ERR_TRAVEL_PASS_DIFFERENT_REGION", text = "This player is in another region." },
    { key = "project", word = "ERR_TRAVEL_PASS_WRONG_PROJECT", text = "This player is in another version of World of Warcraft." },
    { key = "client", word = "ERR_TRAVEL_PASS_NOT_WOW", text = "This player is not in World of Warcraft." },
}
local RANK = {}
for rank, refusal in ipairs(REFUSALS) do RANK[refusal.key] = rank end

-- The game's words on its invite button, by what an invite would be (GetDisplayedInviteType).
local ASKS = {
    INVITE = Core.Word("TRAVEL_PASS_INVITE", "Invite to Group"),
    SUGGEST_INVITE = Core.Word("SUGGEST_INVITE", "Suggest Invite"),
    REQUEST_INVITE = Core.Word("REQUEST_INVITE", "Request to Join"),
}

-- Why one game account cannot be asked into your group (a key of REFUSALS), or nil: it can.
local function Refusal(game)
    if game.clientProgram ~= rawget(_G, "BNET_CLIENT_WOW") then return "client" end
    local project = rawget(_G, "WOW_PROJECT_ID")
    if project and game.wowProjectID and game.wowProjectID ~= project then return "project" end
    if game.isInCurrentRegion == false then return "region" end
    if not game.playerGuid or game.realmID == 0 then return "info" end
    local faction = UnitFactionGroup("player")
    local both = C_PartyInfo.CanFormCrossFactionParties and Core.Ask(C_PartyInfo.CanFormCrossFactionParties)
    if game.factionName and faction and game.factionName ~= faction and not both then return "faction" end
    return nil
end

-- The game accounts of a Battle.net friend (its place in the game's list) that can be asked into your
-- group; and, where none can, why not (the reason nearest to an invite).
local function Invitable(index, account)
    local games = {}
    local count = C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendNumGameAccounts(index)
    if count then
        for which = 1, count do games[#games + 1] = C_BattleNet.GetFriendGameAccountInfo(index, which) end
    else
        games[1] = account.gameAccountInfo
    end
    local fit, why = {}, nil
    for _, game in ipairs(games) do
        local refusal = game.isOnline ~= false and Refusal(game)
        if game.isOnline ~= false and not refusal then
            fit[#fit + 1] = game
        elseif refusal and (not why or RANK[refusal] < RANK[why]) then
            why = refusal
        end
    end
    return fit, why
end

-- A Battle.net friend: their account's name (or their BattleTag without its number), the character they play.
local function BattleNet(index)
    local account = C_BattleNet.GetFriendAccountInfo(index)
    if not account then return nil end
    local game = account.gameAccountInfo or {}
    local online = game.isOnline and true or false
    local name = account.accountName
    if not name or name == "" then name = (account.battleTag or "?"):match("^[^#]+") end
    local wow = game.clientProgram == rawget(_G, "BNET_CLIENT_WOW")
    local info
    if not online then
        info = account.lastOnlineTime and account.lastOnlineTime > 0
            and Core.Word("BNET_LAST_ONLINE_TIME", "Last online %s"):format(Contacts.Ago(account.lastOnlineTime))
            or Core.Word("FRIENDS_LIST_OFFLINE", "Offline")
    elseif wow and game.areaName and game.areaName ~= "" and not (game.wowProjectID and game.wowProjectID ~= rawget(_G, "WOW_PROJECT_ID")) then
        info = game.areaName
    else
        info = game.richPresence or ""
    end
    local friend = {
        kind = "bnet", key = "bnet:" .. tostring(account.bnetAccountID), online = online, index = index,
        name = name, character = online and game.characterName ~= "" and game.characterName or nil, info = info,
        status = Contacts.Status(online, account.isAFK or game.isGameAFK, account.isDND or game.isGameBusy),
        client = online and game.clientProgram or nil, account = account.accountName, favorite = account.isFavorite,
        battleTag = account.battleTag, id = account.bnetAccountID, note = account.note, game = game,
        broadcast = account.customMessage, broadcastAt = account.customMessageTime, lastOnline = account.lastOnlineTime,
    }
    if online then
        friend.games, friend.refusal = Invitable(index, account)
        friend.cooperate = wow and Refusal(game) == nil
        friend.otherProject = wow and game.wowProjectID and game.wowProjectID ~= rawget(_G, "WOW_PROJECT_ID")
    end
    return friend
end

-- A character friend: "Name, Level 60 Warrior" and where they are, as the game's list writes it.
local function Character(index)
    local friend = C_FriendList.GetFriendInfoByIndex(index)
    if not friend or not friend.name then return nil end
    local online = friend.connected and true or false
    local name = friend.name
    if online and friend.level and friend.className then
        name = name .. ", " .. Core.Word("FRIENDS_LEVEL_TEMPLATE", "Level %d %s"):format(friend.level, friend.className)
    end
    return {
        kind = "wow", key = "wow:" .. friend.name, online = online, name = name, whisper = friend.name,
        info = online and (friend.area or "") or Core.Word("FRIENDS_LIST_OFFLINE", "Offline"),
        status = Contacts.Status(online, friend.afk, friend.dnd), guid = friend.guid, note = friend.notes,
        level = friend.level, className = friend.className, area = friend.area,
    }
end

-- Every friend, in the game's order: favourites, online, offline (the game gives its Battle.net friends sorted so).
local function Read()
    local favorites, online, offline = {}, {}, {}
    local total = BNGetNumFriends and BNGetNumFriends() or 0
    for index = 1, total or 0 do
        local friend = BattleNet(index)
        if friend then table.insert(friend.favorite and favorites or friend.online and online or offline, friend) end
    end
    local legacy = C_FriendList.IsLegacyFriendSystemEnabled
    if not legacy or legacy() then
        for index = 1, C_FriendList.GetNumFriends() or 0 do
            local friend = Character(index)
            if friend then table.insert(friend.online and online or offline, friend) end
        end
    end
    return favorites, online, offline
end

local function Found(friend)
    if not Contacts.Wanted(wanted, friend.status) or (next(kinds) and not kinds[friend.kind]) then return false end
    return not query or Core.Fuzzy.Match(query, friend.name, friend.character, friend.info, friend.battleTag, friend.note) ~= nil
end

local function Chosen()
    for _, friend in ipairs(friends) do
        if friend.key == chosen then return friend end
    end
end

-- A friend can be invited: a character online, or a Battle.net friend with a game account that can be asked.
local function CanInvite(friend)
    if not friend or not friend.online then return false end
    if friend.kind == "wow" then return true end
    return friend.games ~= nil and #friend.games > 0
end

-- The buttons of the foot, for the friend chosen: a message to one who can get it (a Battle.net friend
-- always, a character online), an invite to one who can be asked.
local function Buttons()
    local friend = Chosen()
    send:SetEnabled(friend ~= nil and (friend.kind == "bnet" or friend.online))
    invite:SetEnabled(CanInvite(friend))
end

local function Update()
    if not shown then return end
    wipe(friends)
    local elements = {}
    -- The favourites, those online, those offline; a divider between the parts that show anybody, as the game's.
    for _, part in ipairs({ Read() }) do
        local found = {}
        for _, friend in ipairs(part) do
            friends[#friends + 1] = friend
            if Found(friend) then found[#found + 1] = friend end
        end
        if #found > 0 and #elements > 0 then elements[#elements + 1] = { kind = "divider" } end
        for _, friend in ipairs(found) do elements[#elements + 1] = friend end
    end
    Board.Fill(box, elements, (query or next(wanted) or next(kinds)) and ns.TEXT.noFriendsFound or ns.TEXT.noFriends)
    Buttons()
end

local Changed = Core.Later(function() ns.Safe("friends", Update) end)
local EVENTS = { "FRIENDLIST_UPDATE", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_FRIEND_INFO_CHANGED", "BN_CONNECTED",
                 "BN_DISCONNECTED", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_CUSTOM_MESSAGE_CHANGED",
                 "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED" }

-------------------------------------------------------------------------------
--  Asking a Battle.net friend into your group
-------------------------------------------------------------------------------

-- One game account asked, as the game's invite button asks: an invite, a suggestion to your leader, or a
-- request to join their group, as the game says it would be (GetDisplayedInviteType).
local function Ask(game)
    local kind = Core.Ask(rawget(_G, "GetDisplayedInviteType"), game.playerGuid) or "INVITE"
    if kind == "REQUEST_INVITE" and rawget(_G, "BNRequestInviteFriend") then return BNRequestInviteFriend(game.gameAccountID) end
    if kind == "SUGGEST_INVITE" and C_PartyInfo.IsPartyFull and C_PartyInfo.IsPartyFull() then
        return UIErrorsFrame:AddMessage(Core.Word("ERR_GROUP_FULL", "Your party is full."), 1, 0.1, 0.1)
    end
    C_BattleNet.InviteFriend(game.gameAccountID)
end

-- A character of a game account, as the game's tooltip names it: "Proudmoore, Level 60 Human Mage".
local function Toon(game)
    return Core.Word("FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE", "%s, Level %s %s %s"):format(game.characterName or "?",
        tostring(game.characterLevel or "?"), game.raceName or "", game.className or "")
end

-- A friend asked into your group: a character by name; a Battle.net friend on the one game account that
-- can be asked, or a menu of them where there are several (owner: what the menu opens at).
local function Invite(friend, owner)
    if not CanInvite(friend) then return end
    if friend.kind == "wow" then return C_PartyInfo.InviteUnit(friend.whisper) end
    if #friend.games == 1 then return Ask(friend.games[1]) end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(ASKS.INVITE)
        for _, game in ipairs(friend.games) do
            root:CreateButton(Toon(game), function() ns.Safe("friends", Ask, game) end)
        end
    end)
end

-- What the invite button of a row says: what it would do, or why it cannot.
local function InviteTip(button)
    local friend = button.friend
    if not friend then return end
    local game = friend.games and friend.games[1]
    local kind = game and Core.Ask(rawget(_G, "GetDisplayedInviteType"), game.playerGuid) or "INVITE"
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(ASKS[kind] or ASKS.INVITE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    if not game then
        for _, refusal in ipairs(REFUSALS) do
            if refusal.key == friend.refusal then
                GameTooltip:AddLine(Core.Word(refusal.word, refusal.text), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
            end
        end
    end
    GameTooltip:Show()
end

-- The invite button of a row, as the game's (its art says the faction of a friend of the other one).
local function InviteButton(row)
    if row.invite then return row.invite end
    local button = CreateFrame("Button", nil, row)
    button:SetSize(Layout.INVITE, 32)
    button:SetPoint("RIGHT", -2, 0)
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnClick", function(self) ns.Safe("friends", Invite, self.friend, self) end)
    button:SetScript("OnEnter", function(self) ns.Safe("friends", InviteTip, self) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    row.invite = button
    return button
end

local function InviteArt(button, friend)
    local faction = friend.game and friend.game.factionName
    local look = (faction == "Horde" or faction == "Alliance") and faction ~= UnitFactionGroup("player") and faction:lower() or "default"
    button:SetNormalAtlas("friendslist-invitebutton-" .. look .. "-normal")
    button:SetPushedAtlas("friendslist-invitebutton-" .. look .. "-pressed")
    button:SetDisabledAtlas("friendslist-invitebutton-" .. look .. "-disabled")
    button:SetHighlightAtlas("friendslist-invitebutton-highlight", "ADD")
end

-------------------------------------------------------------------------------
--  Rows
-------------------------------------------------------------------------------

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
    if friend.kind == "divider" then return Contacts.Divider(row) end
    Contacts.Entry(row)
    local back = Contacts.BACKS[friend.online and friend.kind or "offline"]
    row.back:SetColorTexture(back[1], back[2], back[3], back[4])
    row.icon:ClearAllPoints()
    row.icon:SetTexture(Contacts.STATUS .. friend.status)
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", 4, -3)
    local game = friend.kind == "bnet" and friend.online
    local right = game and (Layout.INVITE + 30) or 8
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 22, -4)
    row.top:SetPoint("TOPRIGHT", -right, -4)
    local colour = not friend.online and Contacts.GRAY or friend.kind == "bnet" and Contacts.BNET or Contacts.WOW
    local name = friend.name
    if friend.character then
        local tint = friend.cooperate and Contacts.WOW or Contacts.OTHER
        name = name .. " |cff" .. Core.Hex(tint[1], tint[2], tint[3]) .. "(" .. friend.character .. ")|r"
    end
    if friend.favorite then name = name .. " " .. Contacts.Atlas("friendslist-favorite", 14) end
    row.top:SetText(name)
    row.top:SetTextColor(colour[1], colour[2], colour[3])
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    row.bottom:SetText(friend.info or "")
    row.right:SetText("")
    row.side:ClearAllPoints()
    row.side:SetSize(24, 24)
    row.side:SetPoint("RIGHT", -(Layout.INVITE + 4), 0)
    row.side:SetShown(friend.client ~= nil)
    if friend.client then
        Game(row.side, friend.client)
        row.side:SetAlpha(friend.otherProject and 0.6 or 1)
    end
    local button = InviteButton(row)
    button.friend = friend
    button:SetShown(game)
    if game then
        InviteArt(button, friend)
        button:SetEnabled(CanInvite(friend))
    end
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
    Contacts.Mark(box, "key", chosen)
    Buttons()
end

-- Who a friend is, as the game's tooltip of its friends list tells it, in the game's own tooltip.
local function Tip(row)
    local friend = row.friend
    if not friend or friend.kind == "divider" then return end
    local tip = GameTooltip
    tip:SetOwner(row, "ANCHOR_RIGHT", 4, 0)
    local colour = not friend.online and Contacts.GRAY or friend.kind == "bnet" and Contacts.BNET or Contacts.WOW
    tip:SetText(friend.kind == "bnet" and friend.name or friend.whisper, colour[1], colour[2], colour[3])
    if friend.kind == "bnet" then
        if friend.battleTag then tip:AddLine(friend.battleTag, Contacts.GRAY[1], Contacts.GRAY[2], Contacts.GRAY[3]) end
        local game = friend.game
        if friend.online and game.clientProgram == rawget(_G, "BNET_CLIENT_WOW") and game.characterName then
            tip:AddLine(Toon(game), 1, 1, 1)
            local where = game.areaName or Core.Word("UNKNOWN", "Unknown")
            if game.realmDisplayName and game.realmDisplayName ~= "" then
                where = Core.Word("BNET_FRIEND_TOOLTIP_ZONE_AND_REALM", "%s - %s"):format(where, game.realmDisplayName)
            end
            tip:AddLine(where, 1, 1, 1)
        elseif friend.online and game.richPresence and game.richPresence ~= "" then
            tip:AddLine(game.richPresence, 1, 1, 1)
        end
    elseif friend.online then
        tip:AddLine(Core.Word("FRIENDS_LEVEL_TEMPLATE", "Level %d %s"):format(friend.level or 0, friend.className or ""), 1, 1, 1)
        if friend.area then tip:AddLine(friend.area, 1, 1, 1) end
    end
    if friend.note and friend.note ~= "" then
        tip:AddLine(("|T%s:14:14|t %s"):format(Contacts.NOTE, friend.note), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    if friend.broadcast and friend.broadcast ~= "" then
        local said = ("|T%s:14:14|t %s"):format(Contacts.BROADCAST, friend.broadcast)
        if friend.broadcastAt and friend.broadcastAt > 0 then
            said = said .. "|n" .. Core.Word("BNET_BROADCAST_SENT_TIME", "(%s ago)"):format(Contacts.Ago(friend.broadcastAt))
        end
        tip:AddLine(said, 0.345, 0.667, 0.867, true)
    end
    if not friend.online then
        tip:AddLine(friend.info, Contacts.GRAY[1], Contacts.GRAY[2], Contacts.GRAY[3])
    elseif friend.kind == "bnet" and C_BattleNet.GetFriendNumGameAccounts then
        -- The other games they are logged in to, under the game's heading.
        local count, header = C_BattleNet.GetFriendNumGameAccounts(friend.index) or 0, false
        for which = 1, count do
            local other = C_BattleNet.GetFriendGameAccountInfo(friend.index, which)
            local client = other and other.clientProgram
            if other and not other.hasFocus and client ~= rawget(_G, "BNET_CLIENT_APP") and client ~= rawget(_G, "BNET_CLIENT_CLNT") then
                if not header then
                    tip:AddLine(" ")
                    tip:AddLine(Core.Word("FRIENDS_LIST_PLAYING", "Currently Playing"), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                    header = true
                end
                local wow = client == rawget(_G, "BNET_CLIENT_WOW") and other.characterName
                tip:AddLine(wow and Toon(other) or other.richPresence or client or "", 1, 1, 1)
            end
        end
    end
    tip:Show()
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------

local function Send()
    local friend = Chosen()
    if friend then Contacts.Tell(friend.kind == "bnet" and friend.account or friend.whisper, friend.kind == "bnet") end
end

function View.Build(page)
    box = Board.List(page, function(row, friend)
        Draw(row, friend)
        row:SetScript("OnClick", function(self, button) ns.Safe("friends", Click, self, button) end)
        row:SetScript("OnEnter", function(self) ns.Safe("friends", Tip, self) end)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end)
    -- Add Friend: the line to add one, in the tab Requests (the game's own dialog does it there).
    local add = Board.Button(page, Core.Word("ADD_FRIEND", "Add Friend"), 100, function() ns.Friends.Open("Requests", true) end)
    send = Board.Button(page, Core.Word("SEND_MESSAGE", "Send Message"), 108, Send, add)
    invite = Board.Button(page, Core.Word("INVITE", "Invite"), 100, function(self) Invite(Chosen(), self) end, send)
end

-- Shown, it listens to the game and asks for the list anew (the game's own does that when it opens);
-- hidden, it hears nothing.
function View.Show(on)
    shown = on
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    if not on then return end
    if C_FriendList.ShowFriends then C_FriendList.ShowFriends() end
    Update()
end

function View.Search(found)
    query = found
    Update()
end

local KINDS = { { key = "bnet", text = ns.TEXT.bnetFriends }, { key = "wow", text = ns.TEXT.characterFriends } }

function View.Filter(root)
    root:CreateTitle(ns.TEXT.status)
    Contacts.StatusMenu(root, wanted, Update)
    root:CreateTitle(ns.TEXT.kind)
    local function IsTicked(key) return kinds[key] == true end
    local function Tick(key)
        kinds[key] = not kinds[key] or nil
        Update()
    end
    for _, kind in ipairs(KINDS) do root:CreateCheckbox(kind.text, IsTicked, Tick, kind.key) end
end

function View.Filtered() return next(wanted) ~= nil or next(kinds) ~= nil end

function View.Unfilter()
    wipe(wanted)
    wipe(kinds)
    Update()
end
