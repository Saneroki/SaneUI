local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Requests
--  Friend requests, and a friend to add: the requests the game's friends list
--  shows at its top, and what its dialog Add Friend asks for, in one tab.
--
--  At the top a line to type a BattleTag (or an e-mail, or a character's name)
--  into, and Add Friend: a BattleTag or an address asks over Battle.net, a name
--  adds the character, as the game's dialog decides (BNSendFriendInvite,
--  C_BattleNet.SendTitleFriendInviteByName, C_FriendList.AddFriend). Opened by
--  Add Friend of the friends list with a friendly player targeted, the line
--  holds their name.
--
--  Under it every request somebody sent you, the newest first, with when it
--  came and the game's two buttons: Accept, and Decline, which opens a menu as
--  the game's (Decline, Block Invites: no more requests from them, asked once).
--
--  Read anew when the game tells of a request, only while the tab is shown;
--  its count is on the tab (Requests (2)) whenever the panel is.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Layout, Contacts = ns.Board, ns.Layout, ns.Contacts
local View = { name = ns.TEXT.requests }
Contacts.Requests = View

local box, line, add
local shown
local query

-- How many requests wait, for the tab's words.
local function Waiting()
    return rawget(_G, "BNGetNumFriendInvites") and BNGetNumFriendInvites() or 0
end

function View.Label()
    local waiting = Waiting()
    return waiting > 0 and ns.TEXT.requestsCount:format(waiting) or ns.TEXT.requests
end

-- Every request, the newest first.
local function Read()
    local requests = {}
    for index = 1, Waiting() do
        local info = C_BattleNet.GetFriendInviteInfo(index)
        if info and info.inviteID then
            requests[#requests + 1] = { id = info.inviteID, name = info.accountName or "?", at = info.creationTimestamp, index = index }
        end
    end
    table.sort(requests, function(a, b) return (a.at or 0) > (b.at or 0) end)
    return requests
end

local function Update()
    if not shown then return end
    local elements = {}
    for _, request in ipairs(Read()) do
        if not query or Core.Fuzzy.Match(query, request.name) then elements[#elements + 1] = request end
    end
    Board.Fill(box, elements, query and ns.TEXT.noRequestsFound or ns.TEXT.noRequests)
end

local Changed = Core.Later(function() ns.Safe("requests", Update) end)

-------------------------------------------------------------------------------
--  Adding a friend
-------------------------------------------------------------------------------

-- A BattleTag or an e-mail address, as the game's dialog tells them from a character's name.
local function OverBattleNet(text)
    local _, battleTag, _, _, _, _, realID = BNGetInfo()
    return (battleTag and text:find("#", 1, true) ~= nil) or (realID and text:find("@", 1, true) ~= nil)
end

local function Add()
    local text = strtrim(line:GetText() or "")
    if text == "" then return end
    local connected = not rawget(_G, "BNConnected") or BNConnected()
    if OverBattleNet(text) and connected then
        BNSendFriendInvite(text, "")
    elseif C_BattleNet.AreTitleFriendsEnabled and C_BattleNet.AreTitleFriendsEnabled() then
        C_BattleNet.SendTitleFriendInviteByName(text)
    elseif not C_FriendList.IsLegacyFriendSystemEnabled or C_FriendList.IsLegacyFriendSystemEnabled() then
        C_FriendList.AddFriend(text)
    else
        return UIErrorsFrame:AddMessage(Core.Word("ERR_SYSTEM_DISABLED", "That system is currently disabled."), 1, 0.1, 0.1)
    end
    line:SetText("")
    line:ClearFocus()
end

-- The friendly player you have targeted, by the name a friend is added by ("Name-Realm" from another realm).
local function Target()
    if not UnitExists("target") or not UnitIsPlayer("target") or not UnitCanCooperate("player", "target") then return nil end
    local name, realm = UnitName("target")
    if not name then return nil end
    if realm and realm ~= "" then name = name .. "-" .. realm end
    if C_FriendList.GetFriendInfo and C_FriendList.GetFriendInfo(name) then return nil end
    return name
end

-------------------------------------------------------------------------------
--  Rows: a request with its two buttons
-------------------------------------------------------------------------------

local function Accept(request) BNAcceptFriendInvite(request.id) end

local function Decline(request, owner)
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateButton(Core.Word("DECLINE", "Decline"), function() BNDeclineFriendInvite(request.id) end)
        if C_BattleNet.SetBlocked then
            root:CreateButton(Core.Word("BLOCK_INVITES", "Block Invites"), function()
                Core.Confirm(Core.Word("BLOCK_INVITES_CONFIRMATION", "Are you sure you want to block all invites from %s?"), request.name, function()
                    C_BattleNet.SetBlocked(request.id, true)
                    BNDeclineFriendInvite(request.id)
                end)
            end)
        end
    end)
end

-- A small button of the game's at a row's right (UIMenuButtonStretchTemplate, as its requests have): Accept
-- in words, Decline as the game's red cross.
local function Small(row, width, click)
    local button = CreateFrame("Button", nil, row, "UIMenuButtonStretchTemplate")
    button:SetSize(width, 22)
    button:SetScript("OnClick", function(self) ns.Safe("requests", click, row.request, self) end)
    return button
end

local function Draw(row, request)
    Board.Row(row)
    Contacts.Entry(row)
    row.request = request
    row:UnlockHighlight()
    local back = Contacts.BACKS.bnet
    row.back:SetColorTexture(back[1], back[2], back[3], back[4])
    row.icon:Hide()
    if not row.decline then
        row.decline = Small(row, 24, Decline)
        row.decline:SetPoint("RIGHT", -7, 1)
        local cross = row.decline:CreateTexture(nil, "ARTWORK")
        cross:SetAtlas("groupfinder-icon-redx", true)
        cross:SetPoint("CENTER")
        Core.Tip(row.decline, Core.Word("DECLINE", "Decline"), nil, "ANCHOR_TOP")
        row.accept = Small(row, 70, Accept)
        row.accept:SetText(Core.Word("ACCEPT", "Accept"))
        row.accept:SetPoint("RIGHT", row.decline, "LEFT", -2, 0)
    end
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 8, -4)
    row.top:SetPoint("RIGHT", row.accept, "LEFT", -4, 0)
    row.top:SetText(request.name)
    row.top:SetTextColor(Contacts.BNET[1], Contacts.BNET[2], Contacts.BNET[3])
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("RIGHT", row.accept, "LEFT", -4, 0)
    row.bottom:SetText(request.at and ns.TEXT.sent:format(Contacts.Ago(request.at)) or "")
    row.side:Hide()
    row.right:SetText("")
end

function View.Build(page)
    line = CreateFrame("EditBox", nil, page.body, "InputBoxTemplate")
    line:SetHeight(20)
    line:SetPoint("TOPLEFT", Layout.EDGE + 6, -(Layout.LINE - 20) / 2 - Layout.EDGE)
    line:SetAutoFocus(false)
    line:SetMaxLetters(127)
    line:SetScript("OnEnterPressed", function() ns.Safe("add friend", Add) end)
    line:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    add = CreateFrame("Button", nil, page.body, "UIPanelButtonTemplate")
    add:SetSize(100, 22)
    add:SetPoint("TOPRIGHT", -Layout.EDGE, -(Layout.LINE - 22) / 2 - Layout.EDGE)
    add:SetText(Core.Word("ADD_FRIEND", "Add Friend"))
    add:SetScript("OnClick", function() ns.Safe("add friend", Add) end)
    line:SetPoint("RIGHT", add, "LEFT", -6, 0)
    -- What to type, in the line while it is empty.
    local hint = line:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("LEFT", 2, 0)
    hint:SetText(ns.TEXT.addHint)
    line:HookScript("OnTextChanged", function(self) hint:SetShown((self:GetText() or "") == "") end)
    Core.Tip(add, Core.Word("ADD_FRIEND", "Add Friend"), ns.TEXT.addTip, "ANCHOR_TOP")
    box = Board.List(page, function(row, request) Draw(row, request) end, Layout.LINE + Layout.EDGE)
end

local EVENTS = { "BN_FRIEND_INVITE_ADDED", "BN_FRIEND_INVITE_REMOVED", "BN_FRIEND_INVITE_LIST_INITIALIZED", "BN_CONNECTED", "BN_DISCONNECTED" }

function View.Show(on)
    shown = on
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    if on then Update() end
end

-- Opened to add a friend (Add Friend of the friends list): the line takes the keys, holding the player
-- targeted if there is one to add.
function View.Focus()
    local name = Target()
    if name and (line:GetText() or "") == "" then
        line:SetText(name)
        line:HighlightText()
    end
    line:SetFocus()
end

function View.Search(found)
    query = found
    Update()
end
