local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Account
--  The head of the friends list's panel: you on Battle.net, as the game's
--  friends list shows you at its top. At the left the status you are seen in
--  (Available, Away, Busy: the game's dropdown with its status icons), then
--  your BattleTag (its number dimmed, as the game writes it), at the right how
--  many friends are online and the game's contacts menu: your broadcast, the
--  message every friend sees in their list, and the ignore list.
--
--  Without Battle.net (disconnected) the head says so, and only the ignore
--  list is in the menu. The status and the broadcast are set by the game's own
--  functions (C_BattleNet.SetAFK, SetDND, SetCustomMessage).
--
--  Read anew when the game tells of a change, only while the panel is shown.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Contacts = ns.Layout, ns.Contacts
local Account = {}
Contacts.Account = Account

local panel, status, count, menu
local shown

-- You on Battle.net: your BattleTag, whether you are away or busy; nil while Battle.net is not there.
local function Me()
    if rawget(_G, "BNFeaturesEnabled") and not BNFeaturesEnabled() then return nil end
    if rawget(_G, "BNConnected") and not BNConnected() then return nil end
    local _, battleTag, _, broadcast, afk, dnd = BNGetInfo()
    if not battleTag then return nil end
    return { battleTag = battleTag, broadcast = broadcast or "", status = Contacts.Status(true, afk, dnd) }
end

-- Your BattleTag as the game's friends list writes it: the number after the # dimmed.
local function Tag(battleTag)
    local name, number = battleTag:match("^([^#]*)(#.*)$")
    if not name then return battleTag end
    return name .. "|cff416380" .. number .. "|r"
end

-- How many friends are online, of how many: Battle.net friends and characters.
local function Count()
    local all, on = 0, 0
    if BNGetNumFriends then
        local total, online = BNGetNumFriends()
        all, on = total or 0, online or 0
    end
    local legacy = C_FriendList.IsLegacyFriendSystemEnabled
    if not legacy or legacy() then
        all = all + (C_FriendList.GetNumFriends() or 0)
        on = on + (C_FriendList.GetNumOnlineFriends() or 0)
    end
    return on, all
end

local function Update()
    if not shown then return end
    local me = Me()
    status:SetShown(me ~= nil)
    if me then
        panel.title:SetText(Tag(me.battleTag))
        panel.title:SetTextColor(0.345, 0.667, 0.867) -- the game's colour of your BattleTag
        status:GenerateMenu()
    else
        panel.title:SetText(Core.Word("BATTLENET_UNAVAILABLE", "Battle.net Unavailable"))
        panel.title:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    end
    panel.title:ClearAllPoints()
    if me then
        panel.title:SetPoint("LEFT", status, "RIGHT", 6, 0)
    else
        panel.title:SetPoint("LEFT", Layout.EDGE + 4, 0)
    end
    panel.title:SetPoint("RIGHT", count, "LEFT", -6, 0)
    count:SetText(ns.TEXT.online:format(Count()))
end

-- The status you are seen in, as the game sets it from its own dropdown.
local function Mine(key)
    local me = Me()
    return me ~= nil and me.status == key
end

local function Choose(key)
    if Mine(key) then return end
    if key == "Online" then
        C_BattleNet.SetAFK(false)
        C_BattleNet.SetDND(false)
    elseif key == "Away" then
        C_BattleNet.SetAFK(true)
    else
        C_BattleNet.SetDND(true)
    end
end

local function Statuses(_, root)
    for index = 1, 3 do -- Offline is not a status you can choose
        local entry = Contacts.STATUSES[index]
        root:CreateRadio(Contacts.StatusText(entry.key), Mine, function(key) ns.Safe("status", Choose, key) end, entry.key)
    end
end

-- Your broadcast, written in the game's own dialog for a line: shown to every friend in their list.
local function Broadcast()
    local me = Me()
    if not me then return end
    Core.AskText(Core.Word("BATTLENET_BROADCAST", "Broadcast"), nil, Core.Word("UPDATE", "Update"), me.broadcast, function(text)
        if text ~= me.broadcast then C_BattleNet.SetCustomMessage(text) end
    end, 127)
end

local function Contents(_, root)
    root:CreateTitle(Core.Word("CONTACTS_MENU_NAME", "Contacts Menu"))
    if Me() then root:CreateButton(Core.Word("CONTACTS_MENU_BROADCAST_BUTTON_NAME", "Broadcast"), function() ns.Safe("broadcast", Broadcast) end) end
    root:CreateButton(Core.Word("CONTACTS_MENU_IGNORE_BUTTON_NAME", "Ignore List"), function() ns.Friends.Open("Ignored") end)
end

function Account.Build(holder)
    panel = holder
    status = CreateFrame("DropdownButton", nil, panel.head, "WowStyle1DropdownTemplate")
    status:SetPoint("LEFT", Layout.EDGE, 0)
    status:SetWidth(51)
    status:SetupMenu(Statuses)
    -- The dropdown shows the icon of the status chosen, as the game's.
    if status.SetSelectionTranslator then
        status:SetSelectionTranslator(function(selection) return ("|T%s%s:16:16:0:0|t"):format(Contacts.STATUS, selection.data) end)
    end
    Core.Tip(status, function()
        local me = Me()
        local words = me and Contacts.StatusText(me.status) or ""
        return Core.Word("FRIENDS_LIST_STATUS_TOOLTIP", "Status: %s"):format(words)
    end)
    -- The game's contacts menu: a square button with its arrow.
    menu = CreateFrame("DropdownButton", nil, panel.head)
    menu:SetSize(24, 24)
    menu:SetPoint("RIGHT", -Layout.EDGE, 0)
    menu:SetNormalTexture("Interface\\Buttons\\UI-SquareButton-Up")
    menu:SetPushedTexture("Interface\\Buttons\\UI-SquareButton-Down")
    menu:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local arrow = menu:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\Buttons\\SquareButtonTextures")
    arrow:SetTexCoord(0.453125, 0.640625, 0.203125, 0.015625)
    arrow:SetSize(12, 12)
    arrow:SetPoint("CENTER")
    menu:SetupMenu(Contents)
    Core.Tip(menu, Core.Word("CONTACTS_MENU_NAME", "Contacts Menu"), nil, "ANCHOR_TOP")
    count = panel.head:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    count:SetPoint("RIGHT", menu, "LEFT", -6, 0)
    panel.title:SetWordWrap(false)
    panel.title:SetJustifyH("LEFT")
end

local Changed = Core.Later(function() ns.Safe("account", Update) end)
local EVENTS = { "BN_INFO_CHANGED", "BN_CONNECTED", "BN_DISCONNECTED", "PLAYER_FLAGS_CHANGED", "BN_CUSTOM_MESSAGE_LOADED",
                 "BN_CUSTOM_MESSAGE_CHANGED", "FRIENDLIST_UPDATE", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_FRIEND_INFO_CHANGED",
                 "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE" }

function Account.Show(on)
    shown = on
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    if on then Update() end
end
