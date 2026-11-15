-- Runs the Social module against the stand-in client (wowstub.lua): what a chat event says, how a
-- message is laid out for a window's width, and that the window keeps its place and follows its size.
-- The look itself can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/social.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
-- Blizzard's nine-slice, for Core's box over the window in Edit Mode: a texture per piece.
NineSliceUtil = { ApplyLayout = function(container, layout)
    for name in pairs(layout) do rawset(container, name, rawget(container, name) or container:CreateTexture()) end
end }

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-- What the module needs of the client -----------------------------------------------------
local ME, THRALL = "Player-70-0000ABCD", "Player-70-00000001" -- the stand-in's own character, and another
ChatTypeInfo = {
    SAY = { r = 1, g = 1, b = 1 }, GUILD = { r = 0.25, g = 1, b = 0.25 }, WHISPER_INFORM = { r = 1, g = 0.5, b = 1 },
    CHANNEL = { r = 1, g = 0.75, b = 0.75 }, CHANNEL2 = { r = 0.5, g = 0.5, b = 1 },
    SYSTEM = { r = 1, g = 1, b = 0 }, EMOTE = { r = 1, g = 0.5, b = 0.25 }, MONSTER_EMOTE = { r = 1, g = 0.5, b = 0.25 },
    PING = { r = 0.5, g = 0.8, b = 1 },
}
-- The game numbers its kinds of chat; its chat windows write a line with that number.
for number, kind in ipairs({ "SAY", "GUILD", "WHISPER_INFORM", "CHANNEL", "CHANNEL2", "SYSTEM", "EMOTE", "MONSTER_EMOTE", "PING" }) do
    ChatTypeInfo[kind].id = number
end
rawset(_G, "COMBATLOG", false) -- no combat log in this client
-- The game's chat asks its filters with the event right before it writes that event's line.
ChatTypeGroup = { LOOT = { "CHAT_MSG_LOOT" }, SAY = { "CHAT_MSG_SAY" }, CHANNEL = { "CHAT_MSG_CHANNEL_JOIN" } }
local filters = {}
ChatFrameUtil.AddMessageEventFilter = function(event, filter) filters[event] = filter end
CHAT_MSG_SAY, CHAT_MSG_GUILD = "Say", "Guild"
GUILD_MOTD_TEMPLATE = "Guild Message of the Day: %s"
-- The game has a word for most kinds of chat; for some the module brings its own.
for kind, word in pairs({ EMOTE = "Emote", WHISPER = "Whisper", RAID = "Raid", RAID_WARNING = "Raid Warning", INSTANCE_CHAT = "Instance",
                          SYSTEM = "System", MONSTER = false, PRINT = false, CHANNEL = "Channel" }) do
    _G["CHAT_MSG_" .. kind] = word or nil
end
rawset(_G, "CHAT_MSG_MONSTER", false)
rawset(_G, "CHAT_MSG_PRINT", false)
for _, kind in ipairs({ "PING", "REWARDS", "BATTLEGROUND", "PET_BATTLE", "CHANNEL_NOTICES" }) do rawset(_G, "CHAT_MSG_" .. kind, false) end
Ambiguate = function(name)
    if name == "Broken" then error("a name the game changed") end
    return (name:gsub("%-.*$", ""))
end
local asked = { class = 0, tie = 0 } -- how often the module asked the game who a speaker is
GetPlayerInfoByGUID = function(guid)
    asked.class = asked.class + 1
    if guid == THRALL then return "Shaman", "SHAMAN" end
    error("not a player")
end
RGBToColorCode = function(r, g, b) return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255) end -- the game's
-- A community's channel is "Community:<club>:<stream>" inside; the game shows the community's name.
ChatFrameUtil.ResolveChannelName = function(name)
    return name:match("^Community:%d+:%d+$") and "Friends - General" or name
end
-- Chat is locked down in a fight or a dungeon: then addons get no messages to read.
-- The game's own channels are known by their number; the game names them in its language.
local CHANNEL_NAMES = { [1] = "General", [2] = "Trade", [22] = "LocalDefense", [26] = "LookingForGroup", [42] = "Services" }
C_ChatInfo = { InChatMessagingLockdown = function() return W.locked or false end,
               GetChannelShortcutForChannelID = function(id) return CHANNEL_NAMES[id] end }
-- In no channel at first; the game's channels below (Join) give them their own.
GetChannelName = function() return 0 end
local Joining -- what the stand-in's join does; the module hooks the one function below, at the login
JoinPermanentChannel = function(...) if Joining then Joining(...) end end
IsResting = function() return false end
GetClassAtlas = function(class) return "classicon-" .. class end
local function Color(r, g, b)
    local color = { r = r, g = g, b = b }
    function color:WrapTextInColorCode(text) return "<" .. text .. ">" end
    return color
end
RAID_CLASS_COLORS = { SHAMAN = Color(0, 0.44, 0.87) }
HIGHLIGHT_FONT_COLOR, GRAY_FONT_COLOR = Color(1, 1, 1), Color(0.5, 0.5, 0.5)
ScrollBoxConstants = { NoScrollInterpolation = true, RetainScrollPosition = true }
BaseScrollBoxEvents = { OnScroll = "OnScroll", OnLayout = "OnLayout" }
CHAT_MSG_YELL, CHAT_MSG_PARTY, CHAT_MSG_OFFICER, CHAT_MSG_BN_WHISPER = "Yell", "Party", "Officer", "Battle.net whisper"
LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE = 1, 2
local grouped, guilded, officer = false, true, false
IsInGroup = function(category) return grouped and category == LE_PARTY_CATEGORY_HOME end
IsInRaid = function() return W.raiding or false end
IsInGuild = function() return guilded end
C_GuildInfo = { IsGuildOfficer = function() return officer end }
GetChannelList = function() return 1, "General", false, 2, "Trade", false, 3, "Muted", true end
-- Friends: one Battle.net friend playing, one away elsewhere; two characters, one of them offline.
BNET_CLIENT_WOW = "WoW"
local asks = {} -- whispers and invites the module asked for; asks.searched: the group finder's last search
do
local BNET_FRIENDS = {
    { bnetAccountID = 7, accountName = "Jaina", battleTag = "Jaina#1234", note = "raid healer",
      gameAccountInfo = { isOnline = true, clientProgram = "WoW", characterName = "Proudmoore", areaName = "Theramore", gameAccountID = 70, playerGuid = "Player-1" } },
    { bnetAccountID = 8, accountName = "", battleTag = "Varian#5678", isAFK = true,
      gameAccountInfo = { isOnline = true, clientProgram = "App", richPresence = "In the Battle.net app" } },
    { bnetAccountID = 9, accountName = "Anduin", battleTag = "Anduin#1", gameAccountInfo = { isOnline = false } },
}
BNGetNumFriends = function() return #BNET_FRIENDS, 2 end
asks.bnet = BNET_FRIENDS -- a test makes one a favourite
C_BattleNet = { GetFriendAccountInfo = function(index) return BNET_FRIENDS[index] end,
                InviteFriend = function(id) asks[#asks + 1] = "bnet invite " .. id end }
local WOW_FRIENDS = {
    { connected = true, name = "Rexxar", className = "Hunter", level = 60, area = "Desolace", dnd = true },
    { connected = false, name = "Garrosh" },
}
C_FriendList = { GetNumFriends = function() return #WOW_FRIENDS end, GetNumOnlineFriends = function() return 1 end,
                 GetFriendInfoByIndex = function(index) return WOW_FRIENDS[index] end,
                 ShowFriends = function() asks[#asks + 1] = "show friends" end }
C_PartyInfo = { InviteUnit = function(name) asks[#asks + 1] = "invite " .. name end }
ChatFrameUtil.SendTell = function(name) asks[#asks + 1] = "tell " .. name end
ChatFrameUtil.SendBNetTell = function(name) asks[#asks + 1] = "bnet tell " .. name end
UnitIsGroupLeader = function() return asks.leader or false end
UnitIsGroupAssistant = function() return false end
FRIENDS_LEVEL_TEMPLATE = "Level %d %s"
NORMAL_FONT_COLOR, RED_FONT_COLOR, GREEN_FONT_COLOR = Color(1, 0.82, 0), Color(1, 0.1, 0.1), Color(0.1, 1, 0.1)
time = function() return 100000 end
UnitExists = function() return false end
UnitCanCooperate = function() return true end
-- You on Battle.net: your BattleTag, your status and your broadcast, set as the game sets them.
local me = { battleTag = "Tester#4321", broadcast = "hello", afk = false, dnd = false }
BNGetInfo = function() return 1, me.battleTag, 2, me.broadcast, me.afk, me.dnd, false end
BNConnected = function() return true end
BNFeaturesEnabled = function() return true end
C_BattleNet.SetAFK = function(on) me.afk = on; asks[#asks + 1] = "afk " .. tostring(on) end
C_BattleNet.SetDND = function(on) me.dnd = on; asks[#asks + 1] = "dnd " .. tostring(on) end
C_BattleNet.SetCustomMessage = function(text) me.broadcast = text; asks[#asks + 1] = "broadcast " .. text end
-- Two friend requests, the older first; adding a friend and blocking one are told.
-- Sylvanas asks over Battle.net (by BattleTag), Tyrande for a character only (Title).
Enum.BattleNetFriendLevel = { BattleTag = 1, RealID = 2, Title = 3 }
local REQUESTS = { { inviteID = 31, accountName = "Sylvanas", creationTimestamp = 1000, friendLevel = 1 },
                   { inviteID = 32, accountName = "Tyrande", creationTimestamp = 2000, friendLevel = 3 } }
BNGetNumFriendInvites = function() return #REQUESTS end
C_BattleNet.GetFriendInviteInfo = function(index) return REQUESTS[index] end
BNAcceptFriendInvite = function(id) asks[#asks + 1] = "accept " .. id end
BNDeclineFriendInvite = function(id) asks[#asks + 1] = "decline " .. id end
C_BattleNet.SetBlocked = function(id, on) asks[#asks + 1] = "block " .. id .. " " .. tostring(on) end
C_BattleNet.AreTitleFriendsEnabled = function() return false end
BNSendFriendInvite = function(text) asks[#asks + 1] = "bnet add " .. text end
C_FriendList.AddFriend = function(name) asks[#asks + 1] = "add " .. name end
-- The ignore list: a player ignored, an account whose invites are blocked.
C_FriendList.GetNumIgnores = function() return 1 end
C_FriendList.GetIgnoreName = function() return "Gamon" end
C_FriendList.DelIgnoreByIndex = function(index) asks[#asks + 1] = "unignore " .. index end
C_FriendList.AddIgnore = function(name) asks[#asks + 1] = "ignore " .. name end
BNGetNumBlocked = function() return 1 end
BNGetBlockedInfo = function() return 41, "Spammer" end
-- Recent allies: one pinned and online, one offline; only Raiding can be filtered by here.
local ALLIES = {
    { characterData = { guid = "Player-9", name = "Cairne", fullName = "Cairne Bloodhoof", level = 60, classID = 1, raceID = 6 },
      stateData = { isOnline = true, pinExpirationDate = 5000, currentLocation = "Mulgore" },
      interactionData = { interactions = { { description = "Grouped together", timestamp = 90000 } }, note = "tank" } },
    { characterData = { guid = "Player-10", name = "Magatha", fullName = "Magatha Grimtotem", level = 58, classID = 7 },
      stateData = { isOnline = false }, interactionData = { interactions = {} } },
}
Enum.RecentAlliesInteractionCategoryFilter = { Professions = 1, PvP = 2, Raiding = 3, Dungeons = 4, Delves = 5, Questing = 6 }
C_RecentAllies = { IsSystemEnabled = function() return true end, IsRecentAllyDataReady = function() return asks.alliesReady or false end,
                   TryRequestRecentAlliesData = function() asks[#asks + 1] = "allies asked" end,
                   GetRecentAllies = function() return ALLIES end,
                   SearchRecentAllies = function(info) asks.allySearch = info; return { ALLIES[2] } end,
                   IsInteractionCategoryFilterSupportedForCurrentGameType = function(value) return value == 3 end }
C_CreatureInfo = { GetClassInfo = function(id) return id == 1 and { className = "Warrior", classFile = "WARRIOR" } or { className = "Shaman", classFile = "SHAMAN" } end,
                   GetRaceInfo = function() return { raceName = "Tauren" } end }
UnitPopup_OpenMenu = function(which, data) asks[#asks + 1] = "menu " .. which .. " " .. tostring(data.name) end
-- A raid: you lead group 1 with Thrall, Rexxar is in group 2, offline; saved to one instance.
local RAID = { { "Tester", 2, 1, 60, "Warrior", "WARRIOR", "Orgrimmar", true, false },
               { "Thrall", 0, 1, 60, "Shaman", "SHAMAN", "Orgrimmar", true, false },
               { "Rexxar", 1, 2, 60, "Hunter", "HUNTER", "Desolace", false, false } }
GetNumGroupMembers = function() return W.raiding and #RAID or 0 end
GetRaidRosterInfo = function(index) if RAID[index] then return unpack(RAID[index]) end end
SwapRaidSubgroup = function(a, b) asks[#asks + 1] = "swap " .. a .. " " .. b end
SetRaidSubgroup = function(a, group) asks[#asks + 1] = "move " .. a .. " " .. group end
C_PartyInfo.ConvertToRaid = function() asks[#asks + 1] = "convert" end
C_PartyInfo.AllowedToDoPartyConversion = function() return true end
C_PartyInfo.SetEveryoneIsAssistant = function(on) asks[#asks + 1] = "all assist " .. tostring(on) end
GetNumSavedInstances = function() return 1 end
GetSavedInstanceInfo = function() return "Molten Core", 409, 3600, 9, true, false, 0, true, 40, "40 Player", 0, 0, false end
GetNumSavedWorldBosses = function() return 0 end
GetSavedWorldBossInfo = function() end
RequestRaidInfo = function() asks.raidInfo = true end
SecondsToTime = function(seconds) return seconds .. " s" end
GetSavedInstanceChatLink = function() return "[Molten Core]" end
-- Quick join: a group a Battle.net friend is in with somebody else, queued for a dungeon.
C_SocialQueue = { GetAllGroups = function() return { "Party-1" } end,
                  GetGroupMembers = function() return { { guid = "Player-1" }, { guid = "Player-5" } } end,
                  GetGroupQueues = function() return { { queueData = { queueType = "lfg" } } } end,
                  GetGroupInfo = function() return true, 1 end,
                  RequestToJoin = function(guid, tank, healer, damage)
                      asks[#asks + 1] = ("join %s %s %s %s"):format(guid, tostring(tank), tostring(healer), tostring(damage))
                  end }
SocialQueueUtil_GetRelationshipInfo = function() return "Jaina", "|cff82c5ff", "bnfriend" end
SocialQueueUtil_GetQueueName = function() return "Ragefire Chasm" end
GetLFGRoles = function() return false, false, true, false end
-- The group finder: a category with two listings, a group and a player alone; searching is told.
local LISTINGS = {
    [11] = { searchResultID = 11, activityIDs = { 100 }, leaderName = "Cairne", comment = "need healer", numMembers = 3, age = 60 },
    [12] = { searchResultID = 12, activityIDs = { 100 }, leaderName = "Baine", comment = "", numMembers = 1, age = 10 },
}
C_LFGInfo = { CanPlayerUsePremadeGroup = function() return true end }
C_LFGList = {
    GetAvailableCategories = function() return { 2 } end,
    GetLfgCategoryInfo = function(id) return { name = id == 2 and "Dungeons" or "?" } end,
    GetAvailableActivities = function() return { 100 } end,
    GetActivityInfoTable = function() return { fullName = "Wailing Caverns", shortName = "", maxNumPlayers = 5 } end,
    Search = function(category, _, _, _, _, _, activities) asks.searched = { category = category, activities = activities } end,
    GetFilteredSearchResults = function()
        if not asks.searched then return 0, {} end
        return 2, { 11, 12 }
    end,
    GetSearchResultInfo = function(id) return LISTINGS[id] end,
    GetSearchResultLeaderInfo = function(id) return { classFilename = id == 11 and "WARRIOR" or "SHAMAN" } end,
    GetSearchResultPlayerInfo = function() return { level = 24, classFilename = "SHAMAN" } end,
}
end

-- The game's own chat: one window, docked, with its tab, its dock and its edit box (which belongs to the screen).
local function Named(kind, name, parent)
    local widget = W.NewWidget(kind, name, parent)
    _G[name] = widget
    return widget
end
local native, dock = Named("Frame", "ChatFrame1", UIParent), Named("Frame", "GeneralDockManager", UIParent)
local nativeTab = Named("Button", "ChatFrame1Tab", dock)
native.isDocked, native.lines = true, {}
function native:AddMessage(text) self.lines[#self.lines + 1] = text end
CHAT_FRAMES, DEFAULT_CHAT_FRAME = { "ChatFrame1" }, native
-- The strip of buttons left of it, with its chat menu button at the bottom.
local nativeStrip = Named("Frame", "ChatFrame1ButtonFrame", native)
local nativeMenu = Named("Button", "ChatFrameMenuButton", nativeStrip)
for _, name in ipairs({ "QuickJoinToastButton", "TextToSpeechButtonFrame", "ChatAlertFrame", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton" }) do
    _G[name] = false -- not in this client
end
FrameUtil = {}
FCF_OpenTemporaryWindow = function() end
-- A chat window minimised for the first time gets a button of its own, a child of the screen.
ChatFrame1Minimized = false
FCF_MinimizeFrame = function() Named("Button", "ChatFrame1Minimized", UIParent) end
local editBox = Named("EditBox", "ChatFrame1EditBox", UIParent)
editBox.header, editBox.kind, editBox._shown = W.NewWidget("FontString", nil, editBox), "SAY", false
editBox._mouse = true -- it takes the mouse, as the game's does
editBox:SetPoint("TOPLEFT", native, "BOTTOMLEFT", -5, -2)
editBox:SetPoint("RIGHT", native, "RIGHT", 8, 0)
function editBox:GetChatType() return self.kind end
function editBox:SetChatType(kind) self.kind = kind end
function editBox:SetStickyType(kind) self.sticky = kind end
function editBox:GetChannelTarget() return self.target or 0 end
function editBox:SetChannelTarget(target) self.target = target end
function editBox:GetText() return self.typed or "" end
function editBox:GetName() return "ChatFrame1EditBox" end
function editBox:GetFont() return "the game's chat font", 14, "" end
function editBox:SetTextInsets(left, right, top, bottom) self.insets = { left, right, top, bottom } end
function editBox:GetTextInsets() return unpack(self.insets) end
function editBox:SetMultiLine(on) self.wraps = on end
function editBox:IsMultiLine() return self.wraps end
function editBox:GetBlinkSpeed() return 0.4 end
function editBox:SetHitRectInsets(left, right, top, bottom) self.hit = { left, right, top, bottom } end
function editBox:SetHeight(height) self._height = height; self.heightWrites = (self.heightWrites or 0) + 1 end
function editBox:SetText(text) self.typed = text; if self._scripts.OnTextChanged then self._scripts.OnTextChanged(self, false) end end
function editBox.UpdateHeader() end
editBox.insets, editBox._height = { 50, 13, 0, 0 }, 32
editBox.header._height = 14
editBox.header:SetPoint("LEFT", editBox, "LEFT", 15, 0)
local art = {}
for _, piece in ipairs({ "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }) do
    art[#art + 1] = Named("Texture", "ChatFrame1EditBox" .. piece, editBox)
end
function editBox:HasFocus() return self.focus or false end
-- The game tells of its edit box being shown and hidden, and of the cursor coming and leaving.
editBox:SetScript("OnShow", function(self) EventRegistry:TriggerEvent("ChatFrame.OnEditBoxShow", self) end)
editBox:SetScript("OnHide", function(self) self.focus = false; EventRegistry:TriggerEvent("ChatFrame.OnEditBoxHide", self) end)
-- The game's two chat styles: "classic" hides the line nobody writes in, "im" keeps it on show, faded.
local style = "classic"
function editBox:Deactivate()
    self._strata = "LOW"
    if style == "classic" then
        self:Hide()
    else
        self.typed, self.focus = nil, false
        self:SetAlpha(0.35)
    end
end
function editBox:ClearChat()
    if style == "classic" then
        self.typed = nil
        self:Hide()
    else
        self:Deactivate()
    end
end
ChatFrameUtil.ActivateChat = function(box)
    box.active = true
    box:Show()
    box.focus = true
    EventRegistry:TriggerEvent("ChatFrame.OnEditBoxFocusGained", box)
    box._strata, box._level = "DIALOG", 7 -- above everything, raised
    box:SetAlpha(1)
end
ChatFrameUtil.OpenChat = function() ChatFrameUtil.ActivateChat(editBox) end
local function open() ChatFrameUtil.OpenChat() end
local function close() editBox:ClearChat() end
-- The cursor leaves the line (a click elsewhere): the game puts an empty one to rest.
local function leave()
    editBox.focus = false
    EventRegistry:TriggerEvent("ChatFrame.OnEditBoxFocusLost", editBox)
    if editBox:GetText() == "" then editBox:Deactivate() end
end
function EventRegistry:UnregisterCallback(event, owner)
    if self.callbacks[event] then self.callbacks[event][owner] = nil end
end

-- The chat's font, and the font the module makes of it: it remembers its size.
local methods = W.methods
ChatFontNormal = W.NewWidget("Font", "ChatFontNormal")
function ChatFontNormal:GetFont() return "the game's chat font", 14, "" end
local chatFont
CreateFont = function(name)
    chatFont = W.NewWidget("Font", name)
    chatFont.size = 14
    function chatFont:GetFont() return "the game's chat font", self.size, "" end
    function chatFont:SetFont(file, size) self.file, self.size = file, size end
    return chatFont
end
-- Text: at size 14 every letter is 6 wide and every line 12 high, wrapped at the width it was given.
local function letter() return 6 * chatFont.size / 14 end
function methods:GetStringWidth() return letter() * #(self._text or "") end
function methods:GetWrappedWidth() return math.min(self:GetStringWidth(), self._width) end
function methods:GetStringHeight() return 2 * letter() * math.max(1, math.ceil(self:GetStringWidth() / self._width)) end
function methods:GetLineHeight() return 2 * letter() end
function methods:SetColorTexture(r, g, b, a) self._color = { r, g, b, a } end
function methods:SetVertexColor(r, g, b, a) self._color = { r, g, b, a } end -- (a fill's colour, how solid)
function methods:SetTexture(texture) self._texture = texture return true end -- found
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:EnableMouse(on) self._mouse = on end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:IsMouseWheelEnabled() return self._wheel or false end
IsMouseButtonDown = function() return W.held or false end
-- The game's link to a player: |Hplayer:name:line:chat|h shown|h
GetPlayerLink = function(name, shown, lineID, chatType) return ("|Hplayer:%s:%s:%s|h%s|h"):format(name, lineID or 0, chatType or 0, shown) end
-- Who is what to you.
local FRIEND, MATE, RAIDER = "Player-70-00000002", "Player-70-00000003", "Player-70-00000004"
C_FriendList.IsFriend = function(guid) asked.tie = asked.tie + 1; return guid == FRIEND end
C_BattleNet.GetAccountInfoByGUID = function() return nil end
IsGuildMember = function(guid) return guid == MATE or guid == FRIEND end
-- The game's own; the global IsGUIDInGroup is only there while its old names are switched on.
C_PartyInfo.IsGUIDInGroup = function(guid) return guid == RAIDER or guid == MATE end
function methods:GetLeft() return self._left or 40 end
function methods:GetTop() return self._top or 500 end
function methods:SetBackdropColor(r, g, b, a) self._fill = { r, g, b, a } end
function methods:SetTexCoord(...) self._texcoord = { ... } end
-- An animation: it remembers whether it runs, how long it waits first and how far it moves.
local function noop() end
function methods:CreateAnimationGroup()
    local group = { playing = false, plays = 0, moves = {} }
    function group:SetToFinalAlpha() end
    function group:Play() self.playing, self.plays = true, self.plays + 1 end
    group.Restart = group.Play
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetScript = noop -- (Core's clock, for a window that fills the screen)
    function group:CreateAnimation()
        local animation = { SetFromAlpha = noop, SetToAlpha = noop, SetSmoothing = noop, progress = 0 }
        function animation:SetDuration(seconds) self.duration = seconds end
        function animation:SetStartDelay(seconds) group.delay = seconds end
        function animation:SetOffset(x, y) self.y = y end
        function animation:GetSmoothProgress() return self.progress end
        group.moves[#group.moves + 1] = animation
        return animation
    end
    self._fade = group
    return group
end

-- The game's scrolling list: here it makes a row for every element, the real one only for those in view.
-- box is the chat's, the first made; the full screen's panels make their own (boxes, in the order made).
local box, grip
local boxes = {}
local function Relay(list)
    if not list then return end
    list.rows, list.heights = list.rows or {}, {}
    for index, entry in ipairs(list.provider.list) do
        list.heights[index] = list.view.height and list.view.height(index, entry) or list.view.extent
        list.rows[index] = list.rows[index] or W.NewWidget("Frame", nil, list)
        list.view.draw(list.rows[index], entry)
    end
    list.relays = (list.relays or 0) + 1
end
W.templates.WowScrollBoxList = function(widget)
    local box = widget
    boxes[#boxes + 1] = box
    box.atEnd, box.scrolls, box.ends = true, false, 0
    box.ScrollTarget = W.NewWidget("Frame", nil, box)
    function box:IsAtEnd() return self.atEnd end
    function box:HasScrollableExtent() return self.scrolls end
    function box:ScrollToEnd() self.ends = self.ends + 1 end
    -- How far down the list is scrolled, from its top: kept by the list when its data changes, as the game's does.
    function box:GetDerivedScrollOffset() return self.offset or 0 end
    function box:ScrollToOffset(offset) self.offset = offset end
    function box:SetDataProvider(provider) self.provider, provider.box = provider, self end
    function box:RegisterCallback(event, fn) if event == "OnScroll" then self.scrolled = fn else self.laid = fn end end
    function box:Rebuild() Relay(self) end
    function box:FullUpdate() self.updates = (self.updates or 0) + 1 end
    function box:ForEachFrame(fn)
        for index, entry in ipairs(self.provider.list) do fn(self.rows[index], entry) end
    end
end
-- The chat's list is the first made.
do
    local made = W.templates.WowScrollBoxList
    W.templates.WowScrollBoxList = function(widget)
        made(widget)
        box = box or widget
    end
end
CreateScrollBoxListLinearView = function(_, _, _, _, spacing)
    local view = { spacing = spacing, padding = { top = 0 } }
    function view.padding:GetTop() return self.top end
    function view.padding:SetTop(top) self.top = top end
    function view:GetPadding() return self.padding end
    function view:SetElementExtentCalculator(fn) self.height = fn end
    function view:SetElementExtent(extent) self.extent = extent end
    function view:SetElementInitializer(kind, fn) self.kind, self.draw = kind, fn end
    return view
end
ScrollUtil = { InitScrollBoxListWithScrollBar = function(scrollBox, _, view) scrollBox.view = view end }
CreateDataProvider = function()
    local provider = { list = {} }
    function provider:Flush() self.list = {}; Relay(self.box) end
    function provider:InsertTable(list) for _, entry in ipairs(list) do self.list[#self.list + 1] = entry end; Relay(self.box) end
    function provider:Insert(entry) self.list[#self.list + 1] = entry; Relay(self.box) end
    function provider:RemoveIndexRange(first, last)
        for _ = first, last do table.remove(self.list, first) end
        self.removals = (self.removals or 0) + 1
        Relay(self.box)
    end
    function provider:GetSize() return #self.list end
    return provider
end

-- The parts of a row, found by what they are.
local function part(row, kind, nth)
    local seen = 0
    for _, widget in ipairs(W.frames) do
        if widget._parent == row and widget._kind == kind then
            seen = seen + 1
            if seen == (nth or 1) then return widget end
        end
    end
end
-- Everything a row shows is in one frame inside it.
local function body(row) return part(row, "Frame") end
local function bubble(row) return part(body(row), "Frame") end
local function ring(row) return part(body(row), "Texture", 1) end
local function icon(row) return part(body(row), "Texture", 2) end
local function name(row) return part(body(row), "FontString", 1) end
local function meta(row) return part(body(row), "FontString", 2) end
local function text(row) return part(bubble(row), "FontString") end
local function say(text, guid, who) W.Fire("CHAT_MSG_SAY", text, who or "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, guid or THRALL) end

-- The addons: Core, then the module -----------------------------------------------------------
W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Social", "SaneUI_Social")
check(SaneUI.Social == ns and ns.addon == "SaneUI_Social", "the module is an addon of its own")
W.Fire("ADDON_LOADED", "SaneUI_Social")
local Log, Layout = ns.Log, ns.Layout
local options = Core.Store("Social").options
check(options.showNative == false, "the game's own chat is out of sight at first")
check(options.shortNames == false, "a chat's whole name stands above a message at first")
check(options.mute.REWARDS and options.mute["CHANNEL:General"] and options.mute["CHANNEL:Trade"] and options.mute["CHANNEL:TradeLocal"]
    and options.mute["CHANNEL:LocalDefense"] and options.mute["CHANNEL:Services"] and options.mute["CHANNEL:NewcomerChat"]
    and options.mute.SAY == nil,
    "loot, money and experience, General, Trade, Local Defense, Services and Newcomer Chat are not shown at first; every other chat is")
check(not ns.Channels.Shown("REWARDS") and not ns.Channels.Shown("CHANNEL:Trade") and not ns.Channels.Shown("CHANNEL:Services")
    and ns.Channels.Shown("GUILD") and ns.Channels.Shown("CHANNEL:Raiders"), "so the window leaves those out, and a channel of the player's own is shown")
options.mute = {} -- what follows shows every chat, and starts with the chats' names in short
options.shortNames = true
check(box == nil, "no window is made before the login")

-- Log: what a chat event says -------------------------------------------------------------------
Core.charKey = ME -- (Core knows the character from the login on)
local entry = Log.Read("CHAT_MSG_GUILD", "hello", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, THRALL)
check(entry.side == "left" and entry.name == "Thrall" and entry.class == "SHAMAN", "somebody else's message is on the left, with name and class")
check(entry.label == "Guild" and entry.g == 1 and entry.r == 0.25 and entry.time:match("^%d%d:%d%d$"), "with the game's word and colour for the chat, and the time")
entry = Log.Read("CHAT_MSG_GUILD", "hello", "Tester", "", "", "", "", 0, 0, "", 0, 1, ME)
check(entry.side == "right" and entry.name == nil and entry.label == "Guild", "your own is on the right, without your name")
-- A message written on Discord (discordInfo, the 18th value), in the guild's Discord stream or in its chat.
do
    rawset(_G, "CHAT_MSG_GUILD_DISCORD", "Guild Discord")
    Enum.DiscordDisplayNameType = { Default = 0, LastOnline = 1, GlobalName = 2 }
    ChatFrameUtil.FormatDiscordMessage = function(info, text) -- the game's, for an attachment
        return info.fromDiscord and info.hasAttachment and "[Attachment] " .. text or text
    end
    local function discord(fields)
        local info = { userID = 7, globalName = "Saner", type = 0, lastOnlineGUID = "", lastOnlineName = "", fromDiscord = true }
        for key, value in pairs(fields or {}) do info[key] = value end
        return info
    end
    entry = Log.Read("CHAT_MSG_GUILD_DISCORD", "hi from Discord", "Saner", "", "", "", "DISCORD", 0, 0, "", 0, 1, ME, nil, nil, nil, nil, nil, discord())
    check(entry.side == "left" and entry.name == "Saner" and entry.class == nil and entry.link == nil and entry.group == "GUILD"
        and entry.label == "Guild Discord" and entry.text == "hi from Discord",
        "a message from the guild's Discord stream is on the left, under its writer's Discord name, shown with the guild; no link whispers a character of that name")
    entry = Log.Read("CHAT_MSG_GUILD", "hi", "Saner", "", "", "", "DISCORD", 0, 0, "", 0, 1, ME, nil, nil, nil, nil, nil,
        discord({ lastOnlineGUID = THRALL, lastOnlineName = "Thrall-Stub" }))
    check(entry.side == "left" and entry.name == "Thrall" and entry.class == "SHAMAN" and entry.link == nil and entry.label == "Guild",
        "one from Discord in the guild's chat too, by the character its writer last played, with its class")
    entry = Log.Read("CHAT_MSG_GUILD", "hi", "Saner", "", "", "", "DISCORD", 0, 0, "", 0, 1, ME, nil, nil, nil, nil, nil,
        discord({ lastOnlineGUID = ME, lastOnlineName = "Tester", type = 2 }))
    check(entry.side == "left" and entry.name == "Saner" and entry.class == nil,
        "under the Discord name where its writer chose that; on the left even when written by the one playing")
    entry = Log.Read("CHAT_MSG_GUILD_DISCORD", "", "Saner", "", "", "", "DISCORD", 0, 0, "", 0, 1, ME, nil, nil, nil, nil, nil, discord({ hasAttachment = true }))
    check(entry and entry.side == "left" and entry.text == "[Attachment] ", "a picture alone is there, with the game's word for it")
    check(Log.Read("CHAT_MSG_GUILD_DISCORD", "", "Saner", "", "", "", "DISCORD", 0, 0, "", 0, 1, ME, nil, nil, nil, nil, nil, discord()) == nil,
        "one with nothing in it is left out")
    entry = Log.Read("CHAT_MSG_GUILD_DISCORD", "hello", "Tester", "", "", "", "", 0, 0, "", 0, 1, ME, nil, nil, nil, nil, nil,
        discord({ userID = 0, fromDiscord = false }))
    check(entry.side == "right" and entry.label == "Guild Discord", "your own line in the Discord stream, written in the game, is yours, on the right")
    ChatFrameUtil.FormatDiscordMessage = nil
end
entry = Log.Read("CHAT_MSG_WHISPER_INFORM", "psst", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, THRALL)
check(entry.side == "right" and entry.label == "To Thrall", "a whisper you sent is yours, and says to whom")
entry = Log.Read("CHAT_MSG_CHANNEL", "wts", "Thrall", "", "2. Trade - City", "", "", 0, 2, "Trade - City", 0, 1, THRALL)
check(entry.label == "Trade - City" and entry.b == 1 and entry.r == 0.5, "a channel has its own name and its own colour")
entry = Log.Read("CHAT_MSG_CHANNEL", "hi", "Thrall", "", "5. Community:1:1", "", "", 0, 5, "Community:1:1", 0, 1, THRALL)
local marks = entry
C_ChatInfo.ReplaceIconAndGroupExpressions = function(text, noIcons) return noIcons and text or (text:gsub("{skull}", "|T8:0|t")) end
entry = Log.Read("CHAT_MSG_GUILD", "pull {skull}", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, THRALL)
check(entry.text == "pull |T8:0|t", "a raid mark is its icon, as the game's chat shows it")
entry = Log.Read("CHAT_MSG_GUILD", "pull {skull}", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, THRALL, nil, nil, nil, nil, true)
check(entry.text == "pull {skull}", "unless the message says to leave it as words")
check(Log.Read("CHAT_MSG_SAY", "a secret", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, THRALL, nil, nil, nil, true) == nil,
    "a sender hidden in a letterbox (a cinematic's) is not shown, as the game's chat does not")
C_ChatInfo.ReplaceIconAndGroupExpressions = nil
entry = marks
check(entry.label == "Friends - General" and entry.short == "F", "a community's channel has the community's name, as the game shows it")
entry = Log.Read("CHAT_MSG_SAY", "grr", "Hogger", "", "", "", "", 0, 0, "", 0, 1, "Creature-1")
check(entry.side == "left" and entry.name == "Hogger" and entry.class == nil, "a speaker who is no player has no class")
check(Log.Read("CHAT_MSG_SYSTEM", "You are now AFK.", "") == nil, "the system's word is taken as the game's chat writes it, not from its event")
check(Log.Read("CHAT_MSG_EMOTE", "waves.", "Thrall-Stub").text == "Thrall waves.", "an emote gets its name in front")
check(Log.Read("CHAT_MSG_MONSTER_EMOTE", "%s goes into a frenzy!", "Hogger").text == "Hogger goes into a frenzy!", "a monster's emote gets it where it belongs")
entry = Log.Read("CHAT_MSG_GUILD_ACHIEVEMENT", "%s has earned the achievement [Level 10]!", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, THRALL)
check(entry.side == "center" and entry.group == "GUILD" and entry.text == "|Hplayer:Thrall-Stub:0:0|h[Thrall]|h has earned the achievement [Level 10]!",
    "a guild member's achievement is a note of the guild, the name the game's link to them")
check(Log.Read("CHAT_MSG_ACHIEVEMENT", "%s has earned it!", "Thrall-Stub").group == "SYSTEM", "anybody else's is the system's")
Log.Motd("Raid at eight")
Log.Motd("Raid at eight")
local told = 0
for _, line in ipairs(Log.list) do if line.text == "Guild Message of the Day: Raid at eight" then told = told + 1 end end
check(told == 1, "(told twice in one moment, it is there once)")
check(Log.list[#Log.list].text == "Guild Message of the Day: Raid at eight" and Log.list[#Log.list].group == "GUILD" and Log.list[#Log.list].side == "center",
    "the guild's message of the day is a note of the guild")
Log.list[#Log.list] = nil
check(Log.Read("CHAT_MSG_LOOT", "x", "y") == nil and Log.Read("CHAT_MSG_SAY", "", "Thrall") == nil and Log.Read("CHAT_MSG_SAY", nil, "Thrall") == nil,
    "an event the module does not know, or one without text, is nothing")
do -- a message the game hides in a fight: as the test names one, then as the client makes one (the stand-in's W.Secret)
    local secretly = issecretvalue -- the stand-in's own, which knows W.Secret's: put back after the test's own
    issecretvalue = function(value) return value == "hidden" end
    check(Log.Read("CHAT_MSG_SAY", "hidden", "Thrall") == nil, "a message the game hides in a fight is left to the game's own chat")
    entry = Log.Read("CHAT_MSG_SAY", "hi", "hidden", "", "", "", "", 0, 0, "", 0, 1, "hidden")
    check(entry.side == "left" and entry.name == nil and entry.class == nil, "a hidden speaker is nobody")
    issecretvalue = secretly
    -- The client's own kind of secret, an error to compare, index or measure: the text, the speaker and the GUID go
    -- through Core.Plain before anything else reads them, so a secret is nothing or nobody, never an error.
    entry = Log.Read("CHAT_MSG_SAY", "hi", W.Secret(), "", "", "", "", 0, 0, "", 0, 1, W.Secret())
    check(Log.Read("CHAT_MSG_SAY", W.Secret(), "Thrall") == nil and entry.side == "left" and entry.name == nil and entry.class == nil,
        "the client's own kind of secret: a secret message is left to the game's chat, a secret speaker is nobody")
end

-- Layout: what follows from the window's width ------------------------------------------------------
check(Layout.RowWidth(380.6) == 380 - 2 * Layout.EDGE - Layout.SCROLL, "a row is the window without its edges and the scroll bar, in whole pixels")
local wide, narrow = Layout.TextWidth(354, "left"), Layout.TextWidth(160, "left")
check(wide == math.floor((354 - Layout.ICON - Layout.GAP) * Layout.SHARE) - 2 * Layout.PAD_X and narrow < wide, "a bubble takes a share of the row, so a narrow window has narrow bubbles")
check(Layout.TextWidth(354, "right") == wide and Layout.TextWidth(354, "center") > wide, "yours are as wide as the others'; a note, without an icon beside it, a little wider")
check(Layout.TextWidth(10, "left") == Layout.MIN_TEXT and Layout.RowWidth(0) == Layout.MIN_TEXT, "however small the window, a text keeps a width")
local width, height = Layout.Bubble(100.2, 24)
check(width == 101 + 2 * Layout.PAD_X and height == 24 + 2 * Layout.PAD_Y, "a bubble is its text and the padding")
check(Layout.RowHeight("left", 24) == Layout.HEAD + height and Layout.RowHeight("center", 24) == height, "a row is the bubble and the line above it; a note is only its bubble")

-- Login: the window ------------------------------------------------------------------------------
W.Fire("PLAYER_LOGIN")
local window = box and box._parent and box._parent._parent -- the list hangs on the chat's frame, that on the window
check(window and window:IsShown() and window._parent == UIParent, "the window is there after the login")
check(window._motion and not window._mouse and window._scripts.OnEnter and #W.tickers == 0,
    "it takes only the mouse's coming, no click: a click goes through to the game; nothing looks for the mouse until it comes")
check(window._width == Layout.WIDTH and window._height == Layout.HEIGHT and window._points[1][1] == "BOTTOMLEFT"
    and window._points[1][3] == "BOTTOMLEFT", "at its first place and size: docked in the screen's lower left corner")
function methods:SetResizeBounds(width, height) self._bounds = { width, height } end
for _, widget in ipairs(W.frames) do
    if widget._parent == window and widget._Normal and type(widget._Normal._texture) == "string" and widget._Normal._texture:find("SizeGrabber") then grip = widget end
end
check(grip and grip._points[1][1] == "TOPRIGHT" and not grip:IsShown(),
    "with Core's grip in its corner away from the screen's edges, out of sight outside Blizzard's Edit Mode")
check(#box.provider.list == 0, "and empty")

-- Messages
local long = ("word "):rep(40) -- 200 letters: 1200 wide
say("hi")
say(long)
say("mine", ME, "Tester")
native:AddMessage("You are now AFK.", 1, 1, 0, ChatTypeInfo.SYSTEM.id)
check(#box.provider.list == 4 and #Log.list == 4, "every message goes into the log and into the list")
local rows = box.rows
-- The room the list leaves above the messages, for a list with or without the line to write in.
-- Where the list starts from the window's top: its last TOPLEFT (the one the game keeps), on what Core lays out
-- for what the window holds (under its title bar while there is one).
-- The list hangs on the chat's frame (column), which hangs on what Core lays out for what the window holds.
local column = box._points[1][2]
local function listTop()
    local y, on
    for _, point in ipairs(box._points) do if point[1] == "TOPLEFT" then y, on = point[5], point[2] end end
    while on and on ~= window do
        y = y + (on._points[1] and on._points[1][5] or 0)
        on = on._points[1] and on._points[1][2]
    end
    return y
end
-- The chat's height: the column's while it has one of its own (the full screen's panels), else the window's.
local function above(input)
    local total = 0
    for index, height in ipairs(box.heights) do total = total + height + (index > 1 and Layout.SPACING or 0) end
    local height = #column._points == 1 and column._height or window._height
    return math.max(Layout.ListHeight(height, input, -listTop()) - total, 0)
end
check(listTop() == -Layout.EDGE and column ~= window and column._parent == window and column._points[1][2]._parent == window,
    "the list starts at the window's top, in the chat's frame in what Core lays out for what a window holds: it has no bar of its own")
check(above() > 0 and box.view.padding.top == above(), "a few messages stand at the bottom of the list: the room they leave is above them")
check(bubble(rows[1]):IsShown() and bubble(rows[1])._points[1][1] == "TOPLEFT" and icon(rows[1]):IsShown(), "somebody else's bubble is on the left, with an icon")
check(icon(rows[1])._atlas == "classicon-shaman", "the class's")
local masks = 0
for _, widget in ipairs(W.frames) do if widget._kind == "MaskTexture" and widget._parent == body(rows[1]) then masks = masks + 1 end end
check(masks == 2 and ring(rows[1]):IsShown() and ring(rows[1])._color[1] == 1 and ring(rows[1])._color[2] == 1 and ring(rows[1])._color[3] == 1,
    "round, in a white ring for a stranger")
local pieces, corners = 0, 0
for _, widget in ipairs(W.frames) do
    if widget._parent == bubble(rows[1]) and widget._kind == "Texture" then pieces = pieces + 1 end
    if widget._parent == bubble(rows[1]) and widget._kind == "MaskTexture" then corners = corners + 1 end
end
check(pieces == 9 and corners == 4 and bubble(rows[1])._fill == nil,
    "the bubble is a plain fill with four round corners, without a border: Core's plate, without its trim")
local square, round = part(bubble(rows[1]), "Texture", 6), part(bubble(rows[1]), "MaskTexture", 1)
check(square._width == Layout.RADIUS and round._width == 2 * Layout.RADIUS and round._points[1][1] == "CENTER" and round._points[1][4] == Layout.RADIUS,
    "a corner is a square piece under a circle twice as wide, on the arc's centre: a quarter circle of the bubble's radius")
check(options.bubbleOpacity == 50 and part(bubble(rows[1]), "Texture")._color[4] == 0.5 and part(bubble(rows[1]), "Texture", 7)._color[4] == 0.5, "half see-through at first")
check(Layout.RING == 1 and icon(rows[1])._width == Layout.ICON - 2, "the ring around the icon is one pixel")
check(name(rows[1])._text == "|Hplayer:Thrall-Stub:1:SAY|hThrall|h" and name(rows[1])._color[3] == 0.87 and name(rows[1])._height == Layout.HEAD, "above it the name, in the class's colour")
check(meta(rows[1])._text == "|cffffffffS|r  <" .. Log.list[1].time .. ">" and meta(rows[1])._points[1][2] == name(rows[1]), "then the chat and the time")
check(bubble(rows[1])._width == 12 + 2 * Layout.PAD_X, "a short message has a short bubble")
check(bubble(rows[2])._width == wide + 2 * Layout.PAD_X and box.heights[2] > box.heights[1], "a long one is as wide as it may be, and as high as its lines")
check(bubble(rows[3])._points[1][1] == "TOPRIGHT" and not icon(rows[3]):IsShown() and not name(rows[3]):IsShown() and meta(rows[3]):IsShown(), "yours is on the right, without icon and name")
local FILL = 0x2B / 255 -- the blue of the bubbles' grey at first (26262B)
check(part(bubble(rows[3]), "Texture")._color[3] == FILL and part(bubble(rows[1]), "Texture", 6)._color[3] == FILL, "with the same fill as everybody else's")
check(bubble(rows[4]):IsShown() and text(rows[4])._text == "You are now AFK." and bubble(rows[4])._points[1][1] == "TOP"
    and not meta(rows[4]):IsShown() and not icon(rows[4]):IsShown(), "a note is a bubble too, in the middle, with nothing above it")
check(part(bubble(rows[4]), "Texture")._color[3] == FILL and text(rows[4])._color[3] == 0, "in the same fill, its text in the game's colour")
do
    local clock, note = part(bubble(rows[4]), "FontString", 2), box.provider.list[4]
    check(clock:IsShown() and clock._text == note.time and clock._points[1][1] == "RIGHT" and text(rows[4])._points[1][1] == "TOPLEFT"
        and bubble(rows[4])._width == math.ceil(text(rows[4]):GetStringWidth()) + 2 * Layout.PAD_X + Layout.GAP + clock:GetStringWidth(),
        "its time stands in its bubble, right of its text, and the bubble is as much wider")
    check(not part(bubble(rows[1]), "FontString", 2):IsShown() and not part(bubble(rows[3]), "FontString", 2):IsShown(),
        "somebody's message and yours have theirs above the bubble, as before")
    local width = Layout.RowWidth(window._width)
    ns.Bubble.Init(rows[4], { side = "center", text = "Today", time = "", r = 1, g = 1, b = 1 }, width)
    check(not clock:IsShown(), "a day's pill has no time, and shows none")
    ns.Bubble.Init(rows[4], note, width)
end
check(box.ends >= 4, "at the newest message, the list follows each new one")

box.atEnd, box.scrolls = false, true
box.scrolled()
local ends = box.ends
say("later")
check(box.ends == ends and #box.provider.list == 5, "scrolled up to read, it stays where it is")
box.atEnd = true
box.scrolled()

-- The game's own chat is out of sight ---------------------------------------------------------------
local away = native._parent
check(away ~= UIParent and not away:IsShown() and dock._parent == away, "with our window open, the game's chat window and its dock have a hidden parent")
check(nativeTab._parent == dock, "a docked window's tab stays in the dock")
check(editBox._points[1][2] == native, "its edit box is left alone until it is shown")
FCF_MinimizeFrame(native)
check(ChatFrame1Minimized._parent == away, "the button of a minimised chat window goes out of sight too, also one the game makes meanwhile")
local fullscreen = W.NewWidget("Frame", nil, UIParent)
ChatFrame1Minimized:SetParent(fullscreen) -- the game moves some of its chat's frames itself
SlashCmdList.SANEUI("social")
check(native._parent == UIParent and ChatFrame1Minimized._parent == fullscreen, "a frame the game moved meanwhile stays where the game put it")
SlashCmdList.SANEUI("social")
check(native._parent == away and ChatFrame1Minimized._parent == away, "(out of sight again)")
local count = #Log.list
native:AddMessage("Some addon: hello")
check(#Log.list == count + 1 and Log.list[#Log.list].side == "center" and Log.list[#Log.list].text == "Some addon: hello" and native.lines[#native.lines] == "Some addon: hello",
    "a line somebody printed into the game's chat is a note in ours, and still in the game's")
native:AddMessage("[Guild] Thrall: hello", 0.25, 1, 0.25, ChatTypeInfo.GUILD.id, 0, 0, "CHAT_MSG_GUILD")
native:AddMessage("[2. Trade] Thrall: wts", 0.5, 0.5, 1, ChatTypeInfo.CHANNEL2.id, 0, 0, "CHAT_MSG_CHANNEL")
native:AddMessage("|Hplayer:Thrall|h[Thrall]|h has earned the achievement!", 1, 1, 0, ChatTypeInfo.EMOTE.id)
check(#Log.list == count + 1, "a line the game's chat made of a chat event we read is not taken twice")
native:AddMessage("Thrall pinged: Attack", 0.5, 0.8, 1, ChatTypeInfo.PING.id)
check(#Log.list == count + 2 and Log.list[#Log.list].group == "PING" and Log.list[#Log.list].side == "center" and Log.list[#Log.list].b == 1,
    "a ping, which has no event of its own, is a note of its own kind, in its colour")
native:AddMessage("Joined Channel: [2. Trade]", 0.5, 0.5, 1, ChatTypeInfo.CHANNEL2.id)
check(#Log.list == count + 3 and Log.list[#Log.list].group == "CHANNEL_NOTICES", "a channel's notice goes with those of all channels")
check(box.provider.list[#box.provider.list].text ~= "Joined Channel: [2. Trade]", "which are not shown at first")
ns.options.showJoins = true
ns.Window.Refill()
check(box.provider.list[#box.provider.list].text == "Joined Channel: [2. Trade]" and ns.Channels.Shown("CHANNEL_NOTICES"), "but when switched on")
local loot = {} -- another of the game's chat windows, which shows the loot too
ns.Log.Line(native, "You receive loot: [Linen Cloth].", 0, 0.67, 0)
ns.Log.Line(loot, "You receive loot: [Linen Cloth].", 0, 0.67, 0)
check(#Log.list == count + 4 and Log.list[#Log.list].group == "PRINT", "a line two of the game's windows show is taken once")
ns.Log.Line(native, "You receive loot: [Linen Cloth].", 0, 0.67, 0)
ns.Log.Line(loot, "You receive loot: [Linen Cloth].", 0, 0.67, 0)
check(#Log.list == count + 5, "the same loot again in the same moment is a line of its own")
W.Wait(0.1)
-- A client whose chat writes a loot line without the number of its kind: the filter told the event.
check(filters.CHAT_MSG_LOOT and filters.CHAT_MSG_SYSTEM and not filters.CHAT_MSG_SAY, "the game's chat filters tell of every event we do not read")
check(filters.CHAT_MSG_LOOT(native, "CHAT_MSG_LOOT", "You receive loot: [Broken Fang].") == false, "(and filter nothing)")
native:AddMessage("You receive loot: [Broken Fang].", 0, 0.67, 0)
native:GetScript("OnEvent")(native, "CHAT_MSG_LOOT")
check(Log.list[#Log.list].group == "REWARDS" and Log.list[#Log.list].text == "You receive loot: [Broken Fang].", "so a loot line without a number goes with the loot")
native:AddMessage("Some addon: after", 1, 1, 1)
check(Log.list[#Log.list].group == "PRINT", "once the window is done with that event, a print is a print again")
filters.CHAT_MSG_CHANNEL_JOIN(native, "CHAT_MSG_CHANNEL_JOIN")
native:AddMessage("[1. HiddenRoom] Muvik joined channel.", 1, 0.75, 0.75)
native:GetScript("OnEvent")(native, "CHAT_MSG_CHANNEL_JOIN")
check(Log.list[#Log.list].group == "CHANNEL_NOTICES", "and a channel's join without a number goes with the joins and leaves")
native:AddMessage("|Hchannel:channel:1|h[1. HiddenRoom]|h Zarpas left channel.", 1, 0.75, 0.75)
check(Log.list[#Log.list].group == "CHANNEL_NOTICES", "one the game told nothing of goes there too, by its channel's link")
W.Wait(0.1)

-- The line to write in ---------------------------------------------------------------------------------
local function bottom() -- where the list ends: its last BOTTOMRIGHT, the one the game keeps
    local y
    for _, point in ipairs(box._points) do if point[1] == "BOTTOMRIGHT" then y = point[5] end end
    return y
end
check(bottom() == Layout.EDGE, "without the line to write in, the list goes down to the window's edge")
ends = box.ends
open()
check(editBox._points[1][1] == "BOTTOMLEFT" and editBox._points[1][2] == column and editBox._points[2][1] == "BOTTOMRIGHT" and #editBox._points == 2,
    "shown, the game's edit box sits at the bottom of our window, in the chat's frame")
check(bottom() == Layout.EDGE + Layout.Input(32) and box.ends > ends, "the list ends above it, and stays at the newest message")
check(box.view.padding.top == above(32) and above(32) <= above(), "the messages move up with it")
close()
check(bottom() == Layout.EDGE and box.view.padding.top == above(), "hidden again, the list has its room back")

-- Where to write
local function texts(list)
    local words = {}
    for index, channel in ipairs(list) do words[index] = channel.text end
    return table.concat(words, ", ")
end
check(texts(ns.Channels.List()) == "Say, Yell, Guild, 1. General, 2. Trade", "you can write where you are: no party, no officer chat, no channel that is switched off")
grouped, officer = true, true
check(texts(ns.Channels.List()) == "Say, Yell, Party, Guild, Officer, 1. General, 2. Trade", "in a party and as an officer there is more")
open()
local label
for _, widget in ipairs(W.frames) do if widget._kind == "Button" and widget._parent == editBox then label = widget end end
check(label and label:IsShown() and label._points[1][2] == editBox.header and not label._scripts.OnEnter, "the chat's name in the line is a button, without a tooltip")
label._scripts.OnClick(label)
local menu = W.menus[#W.menus]
check(menu[1].title == "Write in" and menu[2].checked(menu[2].data) and not menu[5].checked(menu[5].data),
    "a click lists the chats, the one you write in marked")
menu[5].fn(menu[5].data)
check(editBox.kind == "GUILD" and editBox.sticky == "GUILD" and editBox.active and menu[5].checked(menu[5].data), "choosing one makes the line write there, and keeps it so")
menu[8].fn(menu[8].data)
check(editBox.kind == "CHANNEL" and editBox.target == 2 and menu[8].checked(menu[8].data) and not menu[7].checked(menu[7].data), "a channel is chosen by its number")
;(function() -- the list in columns, open until a click outside it or on its button
    check(menu.grid[1] == MenuConstants.VerticalGridDirection and menu.grid[2] == 2 and menu.grid[3] > 0 and #menu % 2 == 0
        and menu[#menu / 2 + 1].title == "Show in the window" and menu[#menu / 2].spacer,
        "the chats to write in and what the window shows stand in columns of their own, the shorter filled up to the longest")
    check(menu[5].response == MenuResponse.Refresh, "choosing a chat leaves the list open, as the ticks do by themselves")
    check(menu.owner == window, "it belongs to the window: the game closes a menu with its owner, and the chat button goes with the mouse")
    check(label:HandlesGlobalMouseEvent("LeftButton", "GLOBAL_MOUSE_DOWN") and not label:HandlesGlobalMouseEvent("RightButton", "GLOBAL_MOUSE_DOWN"),
        "a press on the button is no click outside the list")
    local count = #W.menus
    label._scripts.OnClick(label)
    check(menu.closed and #W.menus == count, "a click on the button it came from closes it")
    label._scripts.OnClick(label)
    check(#W.menus == count + 1 and not W.menus[#W.menus].closed, "the next opens it")
    W.menus[#W.menus]:Close() -- the game's, at a click outside it
    label._scripts.OnClick(label)
    check(#W.menus == count + 2, "closed by a click outside it, the button opens it again at once")
    ns.Menu.Close()
end)()

-- The smiley beside the line: the raid marks to write, the emotes to do
local smiley
for _, widget in ipairs(W.frames) do
    if widget._kind == "Button" and widget._parent == window and widget._points[1] and widget._points[1][1] == "BOTTOMRIGHT" then smiley = widget end
end
check(smiley and smiley:IsShown() and smiley._points[1][4] == -Layout.GRIP_ROOM and editBox._points[2][4] == -Layout.INPUT_RIGHT
    and Layout.INPUT_RIGHT >= Layout.GRIP_ROOM + Layout.FACE, "right of the line, before the grip, a smiley; the line ends before it")
rawset(_G, "EMOTE101_TOKEN", "HELLO")
rawset(_G, "EMOTE101_CMD1", "/hallo") -- the game's own word, in its language
local emoted, closed, typed = {}, 0, nil
C_ChatInfo.PerformEmote = function(token) emoted[#emoted + 1] = token end
C_ChatInfo.GetChannelInfoFromIdentifier = function(name) return { channelType = name == "Trade - City" and 1 or 3 } end
GetChannelName = function(channel) return channel, channel == 2 and "Trade - City" or "Mine" end
rawset(_G, "MenuTemplates", { AttachBasicButton = function(parent) return CreateFrame("Button", nil, parent) end })
Menu.GetManager = function() return { CloseMenu = function() closed = closed + 1 end } end
MenuUtil.HookTooltipScripts = function() end
function editBox:Insert(text) typed = text end
smiley._scripts.OnClick(smiley)
menu = W.menus[#W.menus]
check(menu[1].title == "Icons" and menu[2].disabled and menu[2].text:find("public") and menu[3].title == "Emotes" and #menu == 3 + #ns.Picker.EMOTES,
    "writing in the game's public channel (Trade), where the game shows no marks, the list offers none; it has the emotes")
check(menu[4].text == "/hallo" and menu[5].text == "/wave", "each emote by its command, the game's word where it has one")
menu[4].fn(menu[4].data)
check(emoted[1] == "HELLO", "a click does the emote, as the game's chat menu does")
editBox.target = 1
smiley._scripts.OnClick(smiley)
menu = W.menus[#W.menus]
local row = CreateFrame("Frame")
check(menu[2].frame and #menu[2].inits == 1, "anywhere else the marks stand in one row")
local width, height = menu[2].inits[1](row, nil, "the menu")
local marks = {}
for _, widget in ipairs(W.frames) do if widget._parent == row then marks[#marks + 1] = widget end end
check(#marks == 8 and width > 8 * 20 and height >= 20, "eight marks, the row as wide as they are")
marks[8]._scripts.OnClick(marks[8])
check(typed == "{rt8}" and closed == 1, "a mark goes into the line as the game writes it in every language, and the list closes")
editBox.target = 2
;(function()
    W.locked = true
    smiley._scripts.OnClick(smiley)
    local list = W.menus[#W.menus]
    W.locked = false
    check(list[3].title == "Emotes" and list[4].disabled and list[4].text:find("locked down") and #list == 4,
        "while chat is locked down the list offers no emotes (the game refuses them to an addon then), and says why")
end)()

-- The window's width: the messages are wrapped anew once the sizing is over, not on every step of it
local function size(width, height)
    grip:GetScript("OnMouseDown")(grip)
    window._width = width
    window._scripts.OnSizeChanged(window, width, height)
end
local function let() grip:GetScript("OnMouseUp")(grip) end
local before, relays = box.heights[2], box.relays
EventRegistry:TriggerEvent("EditMode.Enter") -- sized only in Blizzard's Edit Mode
check(grip:IsShown(), "in Edit Mode the grip is there")
size(200, 260)
check(box.relays == relays and box.heights[2] == before, "while the window is sized, the messages keep their wrapping")
let()
check(box.relays == relays + 1 and box.heights[2] > before, "when it is over, a narrower window wraps them anew: the long one is higher")
check(bubble(rows[2])._width == Layout.TextWidth(Layout.RowWidth(200), "left") + 2 * Layout.PAD_X, "and its bubble narrower")
size(200.4, 400)
let()
check(box.relays == relays + 1, "a change of the height alone wraps nothing")
EventRegistry:TriggerEvent("EditMode.Exit")

-- The line is only there while you write
close()
check(not editBox:IsShown() and bottom() == Layout.EDGE, "(the line is closed)")
local write
for _, widget in ipairs(W.frames) do
    if widget._kind == "Button" and widget._parent == column and widget._points[1][1] == "BOTTOMLEFT" then write = widget end
end
check(write and write._points[1][1] == "BOTTOMLEFT" and write._height == Layout.INPUT_HEIGHT, "the window has a button in its lower left corner, as high as the line to write in")
check(editBox._points[1][4] == Layout.INPUT_LEFT and Layout.INPUT_LEFT > 0, "the line starts right of it")
local menus = #W.menus
write._scripts.OnClick(write)
check(editBox:IsShown() and editBox.focus and bottom() == Layout.EDGE + Layout.Input(32), "a click on it opens the line to write in")
menu = W.menus[#W.menus]
check(#W.menus == menus + 1 and menu[1].title == "Write in" and menu[8].checked(menu[8].data) and not menu[2].checked(menu[2].data),
    "and the list of the chats you can write in, the one you write in marked")
write._scripts.OnClick(write)
check(not editBox:IsShown() and bottom() == Layout.EDGE and #W.menus == menus + 1 and menu.closed, "another one closes it and the list, without a new list")
;(function()
    check(write:HandlesGlobalMouseEvent("LeftButton", "GLOBAL_MOUSE_DOWN"), "a press on the chat button is no click outside the list either")
    write._scripts.OnClick(write)
    local list, count = W.menus[#W.menus], #W.menus
    check(list.owner == window, "opened by the chat button, the list stays when the button goes with the mouse")
    editBox:ClearChat() -- a message sent
    write._scripts.OnClick(write)
    check(list.closed and not editBox:IsShown() and #W.menus == count, "the line gone meanwhile, the chat button closes the list alone")
end)()
check(not smiley:IsShown(), "the smiley goes with the line")

-- The line's look and height
open()
local plate
for _, widget in ipairs(W.frames) do
    if widget._kind == "Frame" and widget._parent == window and widget._points[1] and widget._points[1][2] == editBox then plate = widget end
end
local linePieces = 0
for _, widget in ipairs(W.frames) do if widget._parent == plate and widget._kind == "Texture" then linePieces = linePieces + 1 end end
check(plate and plate:IsShown() and linePieces == 9 and part(plate, "Texture")._color[3] == FILL and part(plate, "Texture")._color[4] == 0.5,
    "the line stands on the very fill of your own bubbles: same pieces, same colour, as see-through")
check(art[1]._alpha == 0 and art[6]._alpha == 0, "the game's border around it is invisible")
check(editBox.wraps == true and editBox.header._points[1][1] == "TOPLEFT" and editBox.header._points[1][5] == 1 and editBox.insets[1] == 50,
    "its text wraps, and the chat's name stands on its first line")
check(editBox.insets[3] == 0 and editBox.insets[4] == 0, "the room above and below its text is not the box's")
check(editBox._height == 12 and editBox._points[1][5] == Layout.INPUT_BOTTOM + 10, "the box is as tall as one line of text, in the middle of the line")
check(plate._points[1][5] == 7 and plate._points[2][5] == -7 and editBox.hit[3] == -10 and editBox.hit[4] == -10,
    "the plate fills the line around it, and a click anywhere on the line is the box's")
editBox._width = 300 -- 237 for the text: 39 letters a line
editBox:SetText(("x"):rep(30))
check(editBox._height == 12 and bottom() == Layout.EDGE + Layout.Input(32), "a text that fits leaves the line as it is")
local anchored = #box._points
do
    local writes = editBox.heightWrites
    editBox:SetText(("x"):rep(35))
    check(#box._points == anchored and editBox.heightWrites == writes, "and a key that leaves the line as high changes nothing in the window, nor the box's height")
end
-- A whisper's name the game hides (messaging lockdown): the insets it counts from that name are hidden too.
local hidden = {}
local insets = editBox.insets
issecretvalue = function(value) return value == hidden end
editBox.insets = { hidden, 13, 0, 0 }
editBox:SetText(("x"):rep(36))
issecretvalue = nil
editBox.insets = insets
check(not ns.off and editBox._height == 12, "a line whose room for the chat's name the game hides grows as it can, and nothing stands down")
editBox:SetText(("x"):rep(100))
check(editBox._height == 12 + 2 * 12 and bottom() == Layout.EDGE + Layout.Input(56) and box.view.padding.top == above(56), "a longer one makes it taller, and the messages move up")
editBox:SetText(("x"):rep(1000))
check(editBox._height == 12 + (Layout.INPUT_LINES - 1) * 12, "up to a number of lines")
editBox.typed = "two\nlines"
EventRegistry:TriggerEvent("ChatFrame.OnEditBoxPreSendText", editBox)
check(editBox.typed == "two lines", "a line break in it is a space when the message is sent")
-- The game's cursor does not show in the line: a bar of ours stands where the game says it is.
do
    local caret
    for _, widget in ipairs(W.frames) do
        if widget._parent == editBox and widget.fill then caret = widget end
    end
    local script = editBox._scripts
    editBox.focus = false
    script.OnEditFocusLost(editBox)
    check(caret and not caret:IsShown(), "no cursor of ours without the keyboard")
    editBox.focus = true
    script.OnEditFocusGained(editBox)
    check(caret:IsShown() and caret.fill:IsShown(), "with the keyboard it is there, lit")
    script.OnCursorChanged(editBox, 30, -12, 2, 15)
    check(caret._points[1][1] == "TOPLEFT" and caret._points[1][2] == editBox and caret._points[1][4] == 50 + 30 and caret._points[1][5] == -12
        and caret._height == 15 and caret._width == 2, "where the game says: counted from inside the insets, as high as a line")
    caret._scripts.OnUpdate(caret, 0.3)
    check(caret.fill:IsShown(), "lit for the game's blink")
    caret._scripts.OnUpdate(caret, 0.2)
    check(not caret.fill:IsShown(), "then dark for as long")
    script.OnCursorChanged(editBox, 30, -12, 2, 15)
    check(not caret.fill:IsShown(), "the game telling of its layout, the cursor where it was, changes nothing")
    script.OnCursorChanged(editBox, 36, -12, 2, 15)
    check(caret.fill:IsShown(), "a key that moves it lights it at once")
    editBox.insets = { 80, 13, 0, 0 }
    editBox.UpdateHeader(editBox)
    check(caret._points[1][4] == 80 + 36, "it follows the chat's name, whose width is the text's left inset")
    editBox.insets = { 50, 13, 0, 0 }
    editBox.typed = ""
    script.OnEditFocusGained(editBox)
    check(caret._points[1][4] == 50 and caret._points[1][5] == 0, "an empty line has it at the start, whatever was written before")
end
close()
check(not plate:IsShown() and bottom() == Layout.EDGE, "closed, the plate goes with it")
editBox._width = 0
open()
editBox.typed = "half a sen"
leave()
check(editBox:IsShown(), "when the cursor leaves a line with text in it, the line stays")
editBox.typed = nil
leave()
check(not editBox:IsShown() and bottom() == Layout.EDGE, "when it leaves an empty one, the game takes the line away")

-- The game's IM style keeps its line on show while nobody writes, faded: here it is out of sight instead
style = "im"
editBox:Show()
editBox:Deactivate() -- as the game does with the line of the chat window last written in
check(editBox:IsShown() and editBox._alpha == 0 and editBox._mouse == false and not plate:IsShown() and bottom() == Layout.EDGE,
    "in IM style a line nobody writes in stays on show for the game, but is invisible, lets the mouse through, and the window has its room")
check(label._mouse == false, "the button on the chat's name, unseen with it, takes no click either")
open()
check(editBox._alpha == 1 and editBox._mouse == true and plate:IsShown() and bottom() == Layout.EDGE + Layout.Input(32), "opened to write, it is seen again and has its room")
check(label._mouse == true, "and its button with it")
W.Wait(0)
check(editBox:IsShown() and editBox._alpha == 1, "and stays")
editBox.typed = "half a sen"
leave()
check(editBox._alpha == 1, "a line with text in it stays when the cursor leaves")
editBox.typed = nil
leave()
check(editBox:IsShown() and editBox._alpha == 0 and bottom() == Layout.EDGE, "an empty one goes out of sight: our code does not hide the game's edit box")
editBox:Deactivate() -- the game fades it anew
check(editBox._alpha == 0, "and it stays out of sight")
write._scripts.OnClick(write)
check(editBox._alpha == 1 and bottom() == Layout.EDGE + Layout.Input(32), "the window's button opens a line at rest")
write._scripts.OnClick(write)
check(editBox:IsShown() and editBox._alpha == 0 and bottom() == Layout.EDGE, "and puts it to rest again")
style = "classic"
editBox:Hide()
editBox:Show() -- shown empty and without the cursor, and not put to rest by the game
W.Wait(0)
check(editBox._alpha == 0 and bottom() == Layout.EDGE, "a line the game shows empty and without the cursor rests a frame later: it is only there while you write")
open()
leave()
check(not editBox:IsShown() and editBox._alpha == 1 and editBox._mouse == true, "(back to the classic style)")

-- Our window goes: the game gets its line back as it had it
open()
W.Wait(0)
check(editBox._strata == "MEDIUM" and editBox._level == Layout.LEVEL + Layout.INPUT_LEVEL, "(the line is drawn with the window)")
SlashCmdList.SANEUI("social")
check(editBox._points[1][2] == native and editBox._strata == "DIALOG" and editBox._level == 7, "in use, it is where the game had it and above everything again")
close()
SlashCmdList.SANEUI("social")
style = "im"
open()
W.Wait(0)
close()
check(editBox:IsShown() and editBox._alpha == 0, "(at rest in IM style)")
SlashCmdList.SANEUI("social")
check(editBox._points[1][2] == native and editBox._alpha == 0.35 and editBox._mouse == true and editBox._strata == "LOW",
    "at rest, it is the game's faded line again, low, and takes the mouse")
SlashCmdList.SANEUI("social")
check(editBox._alpha == 0 and editBox._points[1][2] == column, "back in our window it rests at once")
style = "classic"
editBox:Hide()

-- Its place
local sized
window.StartSizing = function(_, corner) sized = corner end
grip:GetScript("OnMouseDown")(grip)
check(sized == nil, "outside Edit Mode it is not sized")
EventRegistry:TriggerEvent("EditMode.Enter")
grip:GetScript("OnMouseDown")(grip)
window._left, window._top, window._width, window._height = 300, 700, 500, 320
grip:GetScript("OnMouseUp")(grip)
check(sized == "TOPRIGHT" and window._bounds[1] == Layout.MIN_WIDTH and window._bounds[2] == Layout.MIN_HEIGHT,
    "the grip sizes it from its corner away from the screen's edges, down to a smallest size")
local place = Core.general.places["Social:place"]
check(place.x == 300 and place.y == 700 and place.width == 500 and place.height == 320, "after sizing, place and size are kept")
EventRegistry:TriggerEvent("EditMode.Exit")
SlashCmdList.SANEUI("social")
check(not window:IsShown() and Core.Store("Social").options.window == false, "/sane social hides the window")
check(native._parent == UIParent and dock._parent == UIParent, "and the game's chat is back")
check(editBox._points[1][1] == "TOPLEFT" and editBox._points[1][2] == native and editBox._points[2][1] == "RIGHT" and not label:IsShown(),
    "with its edit box where the game had it")
check(art[1]._alpha == 1 and editBox.wraps == false and editBox._height == 32 and editBox.header._points[1][1] == "LEFT" and editBox.insets[3] == 0,
    "and as the game made it: its border, one line, the name in its place")
open()
check(editBox._points[1][2] == native, "while our window is hidden the edit box is the game's")
close()
relays = box.relays
say("unseen")
check(box.relays == relays and Log.list[#Log.list].text == "unseen", "hidden, it draws nothing; the log still gets the message")
SlashCmdList.SANEUI("social")
check(window:IsShown() and #box.provider.list == #Log.list and Core.Store("Social").options.window == true, "shown again, it has what came meanwhile")
check(native._parent == away, "and the game's chat is out of sight again")
SlashCmdList.SANEUI("social reset")
check(next(Core.general.places["Social:place"] or {}) == nil and window._width == Layout.WIDTH and window._points[1][1] == "BOTTOMLEFT",
    "/sane social reset puts it back at its first place and size")

-- Messages fade, each by itself: the fade is the message's own, not its row's -------------------------
local Fade = ns.Fade
local e = {}
Fade.Enter(e, 10)
check(Fade.Alpha(e, 10) == 0 and Fade.Alpha(e, 10 + Layout.APPEAR) == 1 and not Fade.Moving(e), "a fade goes from where it began to where it goes, and is over")
Fade.To(e, 0, 20)
check(Fade.Alpha(e, 20 + Layout.FADE / 2) == 0.5, "half way out, half seen")
Fade.To(e, 1, 20 + Layout.FADE / 2)
check(Fade.Alpha(e, 20 + Layout.FADE / 2) == 0.5 and e.span == Layout.APPEAR / 2, "one that turns back turns from where it is, for the rest of the way only")
Fade.To(e, 1, 21)
check(e.since == 20 + Layout.FADE / 2, "told again where it already goes, it goes on as it was")

-- The window paints every frame while a message fades, and only then.
local function step(seconds)
    W.Wait(seconds)
    if window._scripts.OnUpdate then window._scripts.OnUpdate(window, seconds) end
end
local function seen(index) return rows[index]._alpha end
local function entry(index) return box.provider.list[index] end
check(options.fade == true and options.fadeAfter == 10, "fading is on at first, after 10 seconds")
Core.Set("Social", "fadeAfter", 60) -- the steps below are timed for a minute
step(Layout.APPEAR) -- (the messages before are in)
say("fresh")
local last = #box.provider.list
check(seen(last) == 0 and window._scripts.OnUpdate, "a new message starts out of sight and fades in, painted every frame")
step(Layout.APPEAR / 2)
check(seen(last) > 0 and seen(last) < 1, "half way in it is half there")
step(Layout.APPEAR)
check(seen(last) == 1 and not window._scripts.OnUpdate, "then it is there, and the window paints no more")
W.Wait(45)
say("later still")
step(Layout.APPEAR)
W.Wait(entry(last).at + 60 - W.clock + 0.02) -- the first one's time runs out
check(entry(last).to == 0 and Fade.Moving(entry(last)) and entry(last + 1).to == 1, "a message whose time is over fades out; a younger one stays")
step(Layout.FADE / 2)
local half = seen(last)
check(half > 0 and half < 1, "half way out")
say("newest")
check(seen(last) == half and entry(last + 2).to == 1, "a new message coming meanwhile leaves that fade as it was")
step(Layout.FADE / 2)
check(seen(last) == 0 and seen(last + 1) == 1 and seen(last + 2) == 1, "and it ends in its own time, while the new one is in")
box.atEnd, box.scrolls = false, true
box.scrolled() -- the list, for a moment not at its end while a message is added
box.atEnd = true
box.scrolled()
step(Layout.APPEAR / 2)
check(seen(last) == 0 and entry(last).to == 0, "a gone message stays gone when the list moves by itself")
box.scrolls = false
-- The mouse comes over the window (the game's OnEnter: it takes the mouse's coming), and the watch that
-- looks after it then, until it has gone.
local function come()
    window._mouseOver = true
    window._scripts.OnEnter(window)
end
local function looker()
    for _, widget in ipairs(W.frames) do
        if widget._parent == window and widget._scripts.OnUpdate then return widget end
    end
end
local function look()
    local watching = looker()
    if watching:IsShown() then watching._scripts.OnUpdate(watching, 1) end
end
come()
step(Layout.APPEAR)
check(seen(last) == 0, "the mouse over the window does not bring them back")
box._scripts.OnMouseWheel(box, 1)
step(Layout.APPEAR / 2)
check(seen(last) > 0 and seen(last) < 1, "a turn of the mouse wheel does, fading them in")
step(Layout.APPEAR)
check(seen(last) == 1, "until they are there")
window._mouseOver = false
look()
step(Layout.FADE / 2)
check(seen(last) > 0 and seen(last) < 1 and seen(last + 1) == 1, "when the mouse leaves, those whose time is over fade out again; the others stay")
step(Layout.FADE)
check(seen(last) == 0, "and are gone")
box._scripts.OnMouseWheel(box, 1)
box.atEnd, box.scrolls = false, true
box.scrolled()
step(Layout.APPEAR)
check(seen(last) == 1, "scrolled up with the wheel, every message is there again")
come()
window._mouseOver = false
look()
step(Layout.FADE)
check(seen(last) == 1, "and stays, the mouse gone, to read on")
box.atEnd = true
box.scrolled()
step(Layout.FADE)
check(seen(last) == 0, "back at the newest message, with the mouse gone, they fade again")
box.scrolls = false
open()
step(Layout.APPEAR)
check(seen(last) == 0 and seen(last + 2) == 1, "the line to write in brings none back: they stay as their age says")
close()
step(Layout.FADE)
check(seen(last) == 0 and seen(last + 2) == 1, "nor does closing it")

-- Nothing jumps: the others slide up, a thing apart from fading
local slide = box.ScrollTarget._fade
slide:Stop() -- (here an animation never ends by itself)
local plays = slide.plays
say("slides in")
local newest = #box.provider.list
local by = box.heights[newest] + Layout.SPACING
check(seen(newest) == 0 and slide.plays == plays + 1 and slide.moves[1].y == -by and slide.moves[2].y == by,
    "a new message fades in, and the others are put back by its row and slide up to their place")
check(seen(last) == 0 and seen(last + 2) == 1, "the slide leaves every message as seen as it was")
slide.moves[2].progress = 0.5
say("and another")
local more = box.heights[newest + 1] + Layout.SPACING
check(slide.moves[2].y == more + by / 2, "a slide still going on goes on in the next")
slide:Stop()
open()
check(slide.playing and slide.moves[2].y == Layout.Input(Layout.INPUT_HEIGHT), "the line to write in pushes them up by its height, sliding")
slide:Stop()
close()
check(slide.moves[2].y == -Layout.Input(Layout.INPUT_HEIGHT), "and they slide back down when it closes")
step(Layout.FADE)

-- The options page: tabs, as the page Profiles has them
MinimalSliderWithSteppersMixin = { Label = { Right = 2 }, Event = { OnValueChanged = "OnValueChanged" } } -- (the game's slider)
Core.Config.Fill()
local Config = Core.Config
local page
for _, candidate in ipairs(W.options.pages) do if candidate.name == "Social" then page = candidate end end
local canvas = Core.frames.Social
check(page and page.frame == canvas and #page.items == 0 and not canvas.tabs, "the page Social is a page of our own, built when first shown")
canvas:Show() -- the game shows it
local tabNames = {}
for index, tab in ipairs(canvas.tabs) do tabNames[index] = tab.Text._text end
check(table.concat(tabNames, ", ") == "General, Appearance", "with two tabs: General and Appearance")
-- A control on the page, by its words; as a setting to get and set, and whether it can be used now.
local function control(text)
    local function OnPage(widget)
        while widget do
            if widget == canvas then return true end
            widget = widget._parent
        end
        return false
    end
    for _, widget in ipairs(Config.Panel.controls) do
        if widget.label == text and OnPage(widget) then
            local item = { widget = widget }
            item.setting = { name = text }
            function item.setting.GetValue() return widget.get() end
            function item.setting.SetValue(_, value)
                if rawget(widget, "Moved") then -- (the stand-in answers every name in capitals)
                    widget.Moved(nil, value)
                elseif rawget(widget, "set") then
                    widget.set(value)
                else
                    widget:SetChecked(value)
                    widget:GetScript("OnClick")(widget)
                end
                Config.Panel.Refresh()
            end
            function item.predicate() widget:Refresh(); return not widget._disabled end
            return item
        end
    end
end
local fadeSwitch, seconds = control("Fade out"), control("Fade messages after")
check(fadeSwitch and seconds and seconds.predicate() and seconds.setting:GetValue() == 60, "a switch to fade messages out; under it how long a message is displayed")
check(Config.Panel.Format(60, 5, "seconds") == "60 seconds" and Config.Panel.Format(0.35, 0.05, "seconds") == "0.35 seconds", "written with its unit, and two decimals for small steps")
seconds.setting:SetValue(100)
step(Layout.APPEAR)
check(options.fadeAfter == 100 and seen(last) == 1, "moving it counts at once: a message younger than that is back")
seconds.setting:SetValue(60)
step(Layout.FADE)
fadeSwitch.setting:SetValue(false)
step(Layout.APPEAR)
check(options.fade == false and seen(last) == 1 and seen(last + 2) == 1 and not seconds.predicate(), "switched off, every message stays, and the time is greyed out")
fadeSwitch.setting:SetValue(true)
step(Layout.FADE)

-- The animations: a switch for all of them, fading in and out, the opacity of faded messages, sliding
local all, fadeIn, fadeOut = control("All animations and fades"), control("Fade in"), control("Fade out")
local fadeInSpeed, fadeOutSpeed = control("Fade-in time"), control("Fade-out time")
local floor, floorValue = control("Faded messages stay visible"), control("Opacity of faded messages")
local slides, slideTime = control("Slide up"), control("Slide time")
check(all.setting:GetValue() == true and fadeIn.setting:GetValue() == true and fadeInSpeed.setting:GetValue() == 0.5 and fadeOutSpeed.setting:GetValue() == 1
    and floor.setting:GetValue() == false and floorValue.setting:GetValue() == 30 and slides.setting:GetValue() == true and slideTime.setting:GetValue() == 0.5,
    "all on at first: 0.5 seconds in, 1 out, faded messages gone (30 % when switched on), sliding in 0.5 seconds")
check(fadeInSpeed.widget._points[1][2] == fadeIn.widget:GetParent() and fadeInSpeed.widget._points[1][5] == fadeIn.widget._points[1][5], "a speed on its switch's line, in the same box")
fadeInSpeed.setting:SetValue(1)
say("slowly in")
local slow = #box.provider.list
step(0.5)
check(seen(slow) == 0.5, "a fade in takes the time set, from out of sight to all there")
step(1)
fadeIn.setting:SetValue(false)
say("in at once")
check(seen(#box.provider.list) == 1 and not floorValue.predicate(), "fading in off: a new message is there at once")
fadeIn.setting:SetValue(true)
fadeInSpeed.setting:SetValue(0.5)
fadeOutSpeed.setting:SetValue(0.5)
floor.setting:SetValue(true)
check(floorValue.predicate(), "the opacity switched on, its slider can be moved")
step(0.5)
check(seen(last) == 0.3, "faded messages stay at the opacity set")
floor.setting:SetValue(false)
step(0.5)
check(seen(last) == 0, "switched off, they go out of sight")
check(slide.moves[2].duration == 0.5, "a slide takes its time")
slideTime.setting:SetValue(0.6)
check(slide.moves[2].duration == 0.6, "and the time set")
slides.setting:SetValue(false)
check(not slideTime.predicate() and fadeInSpeed.predicate(), "the slide off, its time is greyed out, the fades are not")
slide:Stop()
plays = slide.plays
say("no slide")
check(slide.plays == plays and seen(#box.provider.list) == 0, "a new message does not slide, but still fades in")
slides.setting:SetValue(true)
step(1)
all.setting:SetValue(false)
check(not fadeIn.predicate() and not fadeInSpeed.predicate() and not fadeOut.predicate() and not seconds.predicate() and not floor.predicate()
    and not slides.predicate() and not slideTime.predicate(), "all animations off: every control under it is greyed out")
check(seen(last) == 1, "and every message is there at once, and stays")
say("at once")
check(seen(#box.provider.list) == 1 and slide.plays == plays, "a new message is there at once, with no slide")
W.Wait(61)
check(seen(#box.provider.list) == 1, "and still there when its time is over")
all.setting:SetValue(true)
fadeOutSpeed.setting:SetValue(1)
slideTime.setting:SetValue(0.5)
step(1)

-- The text's size
local size = control("Text size")
check(size and size.setting:GetValue() == 14 and chatFont.size == 14,
    "a third setting is the size of the text: the game's chat font at 14 at first")
local heightBefore, relays = box.heights[2], box.relays
-- A message in two lists of different widths (the chat's and the full screen's) is measured once for each width.
;(function()
    local Bubble, twice = ns.Bubble, box.provider.list[2]
    check(Bubble.Known(twice, 333) == nil and Bubble.Known(twice, 222) == nil, "(a message, not measured for these widths yet)")
    local wide, narrow = Bubble.Measure(twice, 333), Bubble.Measure(twice, 222)
    check(wide and narrow and Bubble.Known(twice, 333) == wide and Bubble.Known(twice, 222) == narrow,
        "measured for a wide list and a narrow one, a message is known at both widths: neither list measures it again")
end)()
size.setting:SetValue(21)
check(options.textSize == 21 and chatFont.size == 21 and chatFont.file == "the game's chat font", "moving it changes the size and keeps the font")
check(box.relays == relays + 1 and box.heights[2] > heightBefore and Layout.HEAD == 25 and name(rows[1])._height == 25, "and every message is measured anew: larger text, higher rows, a higher line for the name")
check(ns.Bubble.Known(box.provider.list[2], 333) == nil and ns.Bubble.Known(box.provider.list[2], 222) == nil,
    "a new text size forgets every width a message was measured at")
size.setting:SetValue(14)
-- The texts that only measure (the messages', the line's) are never seen: their frame is see-through,
-- which no change of the font sets anew (their own alpha it would).
local rulers = 0
for _, widget in ipairs(W.frames) do
    local holder = widget._parent
    if widget._kind == "FontString" and holder and holder._alpha == 0 and holder._parent == window then rulers = rulers + 1 end
end
check(rulers == 2, "the texts that measure stand in a see-through frame of their own")
check(box.heights[2] == heightBefore, "and back")

-- How see-through the bubbles are
local clear = control("Bubble opacity")
check(clear and clear.setting:GetValue() == 50, "a fourth setting is how see-through the bubbles are")
clear.setting:SetValue(100)
check(part(bubble(rows[1]), "Texture")._color[4] == 1 and part(bubble(rows[3]), "Texture")._color[4] == 1, "at 100 they are solid")
clear.setting:SetValue(0)
check(part(bubble(rows[1]), "Texture")._color[4] == 0 and part(bubble(rows[1]), "Texture")._color[3] == FILL, "at 0 only the text is left")
open()
check(part(plate, "Texture")._color[4] == 0, "and the line to write in follows")
close()
clear.setting:SetValue(50)

-- What the bubbles stand on
local backing, tint = control("Bubble background"), control("Bubble colour")
check(backing and backing.setting:GetValue() == "solid" and tint and tint.setting:GetValue() == "26262B" and tint.widget._alpha == 1,
    "the bubbles stand on a solid color at first, a grey, which can be chosen")
tint.setting:SetValue("FF0000")
check(part(bubble(rows[1]), "Texture")._color[1] == 1 and part(bubble(rows[3]), "Texture")._color[2] == 0, "a color chosen fills every bubble, yours too")
open()
check(part(plate, "Texture")._color[1] == 1, "and the line to write in")
close()
backing.setting:SetValue("marble")
local top = part(bubble(rows[1]), "Texture", 5) -- the piece between the upper corners
check(top._texture == "Interface\\FrameGeneral\\UI-Background-Marble" and top._texcoord[1] == Layout.RADIUS / 256 and top._texcoord[3] == 0,
    "or one of the game's textures, each piece showing the part where it lies")
check(tint.widget._alpha == 0.4, "the color is greyed out then")
backing.setting:SetValue("solid")
tint.setting:SetValue("26262B")
check(part(bubble(rows[1]), "Texture")._color[3] == FILL and tint.widget._alpha == 1, "(back to the grey)")

-- Links in a message: the tooltip on the mouse, the game's own click
local shownLink, clicked
function GameTooltip:SetHyperlink(link)
    if link:find("^item:0") then error("no such item") end
    shownLink = link
end
SetItemRef = function(link, text, button, chatFrame) clicked = { link, text, button, chatFrame } end
local lockbox = "item:4633::::::::60"
local over = bubble(rows[1])
check(over._scripts.OnHyperlinkEnter and body(rows[1])._scripts.OnHyperlinkEnter, "the links in a bubble and in a note answer the mouse")
GameTooltip:Hide()
over._scripts.OnHyperlinkEnter(over, lockbox, "[Strong Iron Lockbox]")
check(shownLink == lockbox and GameTooltip:IsShown() and GameTooltip._owner == over, "the mouse over an item's link shows the item's tooltip")
over._scripts.OnHyperlinkLeave(over)
check(not GameTooltip:IsShown(), "and leaving it hides the tooltip")
shownLink = nil
over._scripts.OnHyperlinkEnter(over, "player:Thrall-Stub", "[Thrall]")
check(shownLink == nil and not GameTooltip:IsShown(), "a player's link has no tooltip")
over._scripts.OnHyperlinkEnter(over, "item:0", "[Gone]")
check(not GameTooltip:IsShown() and not ns.off, "nor has an item the game cannot show, and nothing breaks")
over._scripts.OnHyperlinkClick(over, lockbox, "[Strong Iron Lockbox]", "LeftButton")
check(clicked[1] == lockbox and clicked[3] == "LeftButton" and clicked[4] == native, "a click is the game's own click on a chat link")
body(rows[1])._scripts.OnHyperlinkClick(body(rows[1]), "player:Thrall-Stub:1:SAY", "Thrall", "LeftButton")
check(clicked[1] == "player:Thrall-Stub:1:SAY", "the speaker's name is the game's link to them: a click on it whispers to them, with the realm")
-- Only clicks that open none of the game's panels go to the game: shown from our code, a panel runs its manager tainted.
;(function()
    local down = rawget(_G, "IsModifierKeyDown")
    clicked, W.modifier = nil, "DRESSUP"
    over._scripts.OnHyperlinkClick(over, lockbox, "[Strong Iron Lockbox]", "LeftButton")
    check(clicked == nil, "a click on an item's link with the dressing room's key does nothing: the dressing room is a panel of the game's")
    W.modifier = nil
    over._scripts.OnHyperlinkClick(over, "calendarEvent:0:1:2", "[Raid night]", "LeftButton")
    check(clicked == nil, "nor does a click on a kind of link that opens a panel of the game's (a calendar event)")
    IsModifierKeyDown, W.modifier = function() return true end, "CHATLINK"
    over._scripts.OnHyperlinkClick(over, lockbox, "[Strong Iron Lockbox]", "LeftButton")
    check(clicked and clicked[1] == lockbox, "the key that puts a link into the line still does, the game's way")
    clicked = nil
    over._scripts.OnHyperlinkClick(over, "channel:CHANNEL:2", "[2. Trade]", "LeftButton")
    check(clicked == nil, "but not on a channel's link, where that key opens the game's list of channels")
    IsModifierKeyDown, W.modifier = down, nil
    over._scripts.OnHyperlinkClick(over, lockbox, "[Strong Iron Lockbox]", "LeftButton")
    check(clicked and clicked[1] == lockbox and not ns.off, "a plain click is the game's own click again")
    -- In a fight the game's link tooltip is refused to our code: the tooltip on the mouse shows the link already.
    clicked, W.combat = nil, true
    over._scripts.OnHyperlinkClick(over, lockbox, "[Strong Iron Lockbox]", "LeftButton")
    check(clicked == nil, "in a fight a plain click on an item's link does nothing: no line that an action failed")
    over._scripts.OnHyperlinkClick(over, "player:Thrall-Stub:1:SAY", "Thrall", "LeftButton")
    check(clicked and clicked[1] == "player:Thrall-Stub:1:SAY", "a speaker's name still whispers to them in a fight")
    clicked, IsModifierKeyDown, W.modifier = nil, function() return true end, "CHATLINK"
    over._scripts.OnHyperlinkClick(over, lockbox, "[Strong Iron Lockbox]", "LeftButton")
    check(clicked and clicked[1] == lockbox, "and the key that puts a link into the line still does")
    IsModifierKeyDown, W.modifier, W.combat = down, nil, false
end)()
-- A creature's name is no link and nothing is asked about it, as in the game's chat; a message's words as they read
-- are made once (a search walks them all).
;(function()
    rawset(_G, "CHAT_MSG_MONSTER_SAY", "Monster Say")
    local said = Log.Read("CHAT_MSG_MONSTER_SAY", "You no take candle!", "Kobold Miner", "", "", "", "", 0, 0, "", 0, 3,
        "Creature-0-1-2-3-4-5")
    rawset(_G, "CHAT_MSG_MONSTER_SAY", nil)
    check(said and said.side == "left" and said.name == "Kobold Miner" and said.link == nil and said.tie == nil
        and said.class == nil, "a creature's name is no link to whisper to, and nothing is asked about it")
    local note = { text = "|cffff0000the red door|r" }
    check(Log.Readable(note) == "the red door" and note.plain == "the red door", "a message's words as they read, kept on it")
end)()

-- The chats' names in short
check(Log.list[1].label == "Say" and Log.list[1].short == "S" and Log.list[1].group == "SAY", "a message knows its chat's name, whole and in short")
local brief = ns.Channels.Brief
check(brief("Guild") == "G" and brief("Party") == "P" and brief("Raid Warning") == "RW" and brief("Trade") == "T" and brief("Ünter den Linden") == "ÜdL" and brief("-") == "-",
    "in short a name is the first letter of each of its words")
entry = Log.Read("CHAT_MSG_CHANNEL", "wts", "Thrall", "", "2. Trade - City", "", "", 0, 2, "Trade - City", 0, 1, THRALL)
check(entry.short == "T" and entry.group == "CHANNEL:Trade" and Log.Read("CHAT_MSG_RAID_WARNING", "run", "Thrall").short == "RW", "T for the trade channel, RW for a raid warning")
check(Log.Read("CHAT_MSG_RAID_WARNING", "run", "Thrall").group == "RAID" and Log.Read("CHAT_MSG_WHISPER_INFORM", "psst", "Thrall").group == "WHISPER"
    and Log.Read("CHAT_MSG_WHISPER_INFORM", "psst", "Thrall").short == nil, "a raid warning belongs to the raid's chat; a whisper you sent keeps saying to whom")
local names = control("Short names")
check(names and names.setting:GetValue() == true and options.shortNames == true, "a fifth setting names the chats in short")
names.setting:SetValue(false)
check(meta(rows[1])._text == "|cffffffffSay|r  <" .. Log.list[1].time .. ">", "switched off, the whole name stands above a message")
names.setting:SetValue(true)
check(meta(rows[1])._text == "|cffffffffS|r  <" .. Log.list[1].time .. ">", "and in short again")

-- What the window shows: the ticks in the list
open()
label._scripts.OnClick(label)
menu = W.menus[#W.menus]
local shows = {}
do
    local under
    for _, item in ipairs(menu) do
        if item.title then under = item.title == "Show in the window" elseif under then shows[#shows + 1] = item.text end
    end
end
check(table.concat(shows, ", ") == "Say, Yell, Emote, Whisper, Party, Raid, Instance, Guild, Officer, Creature messages, Pings, Loot, money and experience, Battlegrounds, Pet battles, Channel joins and leaves, System messages, Addon messages, 1. General, 2. Trade, 3. Muted",
    "beside the chats to write in, the list has every kind of chat and every channel you are in")
ns.Menu.Close()
local saying, shownBefore = menu[#menu / 2 + 2], #box.provider.list
check(saying.checked(saying.data) and shownBefore == #Log.list, "all of them ticked at first: everything is shown")
saying.fn(saying.data)
local said = 0
for _, message in ipairs(Log.list) do if message.group == "SAY" then said = said + 1 end end
check(not saying.checked(saying.data) and Core.Store("Social").options.mute.SAY == true and said > 0 and #box.provider.list == shownBefore - said, "unticked, the messages of that chat leave the window")
check(#Log.list == shownBefore, "but not the log")
say("not shown")
check(#box.provider.list == shownBefore - said and Log.list[#Log.list].text == "not shown", "a new one of that chat is kept and not shown")
W.Fire("CHAT_MSG_GUILD", "shown", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 1, THRALL)
check(#box.provider.list == shownBefore - said + 1, "one of another chat is")
saying.fn(saying.data)
check(saying.checked(saying.data) and Core.Store("Social").options.mute.SAY == nil and #box.provider.list == #Log.list, "ticked again, they are all back")
local trade = menu[#menu - 1]
check(trade.text == "2. Trade" and trade.data.group == "CHANNEL:Trade", "a channel is known by its own word, not its number")
do -- The game's own word, whatever the number it has now and the name it shows
    local function Said(number, name)
        return Log.Read("CHAT_MSG_CHANNEL", "wts", "Thrall", "", number .. ". " .. name, "", "", 2, number, name, 0, 1, THRALL).group
    end
    C_ChatInfo.GetChannelShortcut = function(number) return ({ [4] = "Services", [5] = "" })[number] end
    check(Said(4, "Trade (Services) - City") == "CHANNEL:Services", "Trade (Services) goes by its shortcut, as the setting names it")
    check(Said(7, "Trade - City") == "CHANNEL:Trade" and Said(5, "General - Elwynn") == "CHANNEL:General",
        "with no shortcut from the game, by its name without the zone, whatever its number")
    C_ChatInfo.GetChannelShortcut = nil
end
trade.fn(trade.data)
shownBefore = #box.provider.list
W.Fire("CHAT_MSG_CHANNEL", "wts", "Thrall", "", "2. Trade - City", "", "", 2, 2, "Trade - City", 0, 1, THRALL)
W.Fire("CHAT_MSG_CHANNEL", "hello", "Thrall", "", "1. General - Elwynn", "", "", 1, 1, "General - Elwynn", 0, 1, THRALL)
check(#box.provider.list == shownBefore + 1 and box.provider.list[#box.provider.list].text == "hello", "unticked, that channel's messages are not shown, whatever the game calls it there; another channel's are")
trade.fn(trade.data)
check(box.provider.list[#box.provider.list - 1].text == "wts", "ticked again, they are back")
-- A channel's message the game's chat writes with an event we do not read (a community's channel) goes
-- with its channel; a channel's join or leave with the notices.
native:AddMessage("[2. Trade] Thrall: from a community", 0.5, 0.5, 1, ChatTypeInfo.CHANNEL2.id, 0, 0, "CHAT_MSG_COMMUNITIES_CHANNEL")
native:AddMessage("[2. Trade] Thrall joined", 0.5, 0.5, 1, ChatTypeInfo.CHANNEL2.id, 0, 0, "CHAT_MSG_CHANNEL_JOIN")
check(Log.list[#Log.list - 1].group == "CHANNEL:Trade" and Log.list[#Log.list].group == "CHANNEL_NOTICES",
    "a line of a channel's kind with its message event is that channel's; with a join's, a notice")
trade.fn(trade.data)
check(box.provider.list[#box.provider.list].text ~= "[2. Trade] Thrall: from a community", "so unticking the channel hides it too")
trade.fn(trade.data)
-- Every tick of the list, one after the other: unticked, none of its messages is in the window and
-- all others are; ticked again, all are back.
local function count(group)
    local found = 0
    for _, message in ipairs(box.provider.list) do if message.group == group then found = found + 1 end end
    return found
end
local everything, works = #box.provider.list, 0
for index = #menu / 2 + 2, #menu do
    local tick = menu[index]
    local group, had = tick.data.group, count(tick.data.group)
    local wasOn = tick.checked(tick.data)
    if not wasOn then tick.fn(tick.data) had = count(group) end
    local all = #box.provider.list
    tick.fn(tick.data)
    local off = not tick.checked(tick.data) and count(group) == 0 and #box.provider.list == all - had
    tick.fn(tick.data)
    local on = tick.checked(tick.data) and count(group) == had and #box.provider.list == all
    if not wasOn then tick.fn(tick.data) end
    if off and on then works = works + 1 end
end
check(works == #menu / 2 - 1 and #box.provider.list == everything, "every tick in the list hides its messages, and only those, and brings them back")
close()

-- A few kinds of messages have a switch of their own in the settings, the same as their tick in the list
do
    local system = control("System messages")
    check(system and system.setting:GetValue() == true and control("Creature messages").setting:GetValue() == true
        and control("Addon messages").setting:GetValue() == true and control("Channel joins and leaves").setting:GetValue() == true,
        "the system's, the creatures' and the addons' messages, and the channels' joins and leaves, are switches of their own")
    local systems, before = 0, #box.provider.list
    for _, message in ipairs(box.provider.list) do if message.group == "SYSTEM" then systems = systems + 1 end end
    system.setting:SetValue(false)
    check(systems > 0 and #box.provider.list == before - systems and not ns.Channels.Shown("SYSTEM"), "switched off, the system's messages leave the window")
    open()
    label._scripts.OnClick(label)
    local tick
    for _, item in ipairs(W.menus[#W.menus]) do if item.text == "System messages" then tick = item end end
    check(tick and not tick.checked(tick.data), "and their tick in the list is off")
    tick.fn(tick.data)
    check(ns.options.showSystem == true and #box.provider.list == before, "ticked there, the switch is on again")
    ns.Menu.Close()
    close()
end

-- The game's own chat next to ours
local nativeToo = control("Show the game's chat too")
check(nativeToo.setting.name == "Show the game's chat too" and nativeToo.setting:GetValue() == false and native._parent == away, "a sixth setting shows the game's own chat (switched off for this test: out of sight)")
nativeToo.setting:SetValue(true)
check(native._parent == UIParent and dock._parent == UIParent and window:IsShown(), "switched on, the game's chat is on show next to our window")
open()
check(editBox._points[1][2] == column, "the line to write in is still ours")
close()
nativeToo.setting:SetValue(false)
check(native._parent == away, "switched off, it is out of sight again")
W.locked = true
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 5, 1)
W.Wait(0)
check(native._parent == UIParent and window:IsShown(), "while chat is locked down (a fight, a dungeon) addons get no messages: the game's own chat is on show")
W.locked = false
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 5, 0)
W.Wait(0)
check(native._parent == away, "and out of sight again when that is over")

-- Who a speaker is to you: the ring around the icon
local function tie(guid) return Log.Read("CHAT_MSG_SAY", "hi", "Somebody", "", "", "", "", 0, 0, "", 0, 1, guid).tie end
check(tie(FRIEND) == "friend" and tie(MATE) == "guild" and tie(RAIDER) == "party" and tie(THRALL) == nil and tie("Creature-1") == nil,
    "a friend, then a guild member, then somebody of your group; a stranger and a creature are nothing")
local classAsks, tieAsks = asked.class, asked.tie
check(tie(THRALL) == nil and tie(THRALL) == nil and asked.class == classAsks and asked.tie == tieAsks, "the game is asked who a speaker is once, not for every message")
W.Fire("FRIENDLIST_UPDATE")
tie(THRALL)
check(asked.tie == tieAsks + 1 and asked.class == classAsks, "what a speaker is to you is asked anew when your friends change; the class never")
W.raiding = true
W.Fire("GROUP_ROSTER_UPDATE")
check(tie(RAIDER) == "raid", "in a raid the group is the raid")
W.raiding = false
W.Fire("GROUP_ROSTER_UPDATE")
check(tie(RAIDER) == "party", "and back in a party, the party")
check(Log.Read("CHAT_MSG_BN_WHISPER", "hi", "Jaina").tie == "friend" and Log.Read("CHAT_MSG_SAY", "hi", "Tester", "", "", "", "", 0, 0, "", 0, 1, ME).tie == nil,
    "who whispers over Battle.net is a friend; you are nobody to yourself")
say("from a friend", FRIEND, "Jaina")
last = #box.provider.list
check(ring(rows[last]):IsShown() and ring(rows[last])._color[1] == Layout.TIES.friend[1] and ring(rows[last])._color[3] == Layout.TIES.friend[3], "a friend's icon has a yellow ring")
say("from the guild", MATE, "Anduin")
check(ring(rows[last + 1])._color[2] == Layout.TIES.guild[2] and ring(rows[last + 1])._color[1] == Layout.TIES.guild[1], "a guild member's a green one")
check(Layout.TIES.raid[3] > Layout.TIES.raid[2] and Layout.TIES.party[3] == 1, "(purple for the raid, blue for the party)")
say("from an alt", MATE, "Droopy Fairwind")
local alt = #box.provider.list
check(name(rows[alt])._text == "|Hplayer:Droopy Fairwind:1:SAY|hDroopy Fairwind|h", "a speaker by their own name")
Core.People.Set("Droopy Fairwind", "alias", "Saneroki")
check(name(rows[alt])._text == "|Hplayer:Droopy Fairwind:1:SAY|hSaneroki|h",
    "given an alias (the game's menu of a player), their messages show it, still a link to whisper the character")
Core.People.Set("Droopy Fairwind", "alias", nil)
check(name(rows[alt])._text:find("|hDroopy Fairwind|h$"), "taken away, their own name again")

-- What the window is handled by is only there with the mouse over it
local titled -- no title on the small window (Saneroki), nor a bar of its own
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text == "Social" and widget._parent and widget._parent._parent == window
        and not widget._parent._scripts.OnDragStart then titled = true end -- not the one on Core's box in Edit Mode
end
check(not titled, "the small window has no title")
check(not write:IsShown() and not grip:IsShown(), "without the mouse over the window its button is out of sight")
check(window._strata == "MEDIUM" and window._level == Layout.LEVEL and window._fill == nil, "the window has no background, and is drawn above the action bars")
W.held = true
look()
check(not write:IsShown() and not looker():IsShown(), "a button held elsewhere does not bring it, and nothing looks for the mouse")
W.held = false
come()
check(write:IsShown() and not grip:IsShown() and looker():IsShown(),
    "the mouse comes over it: the button is there at once, and the mouse is watched; the grip only in Blizzard's Edit Mode")
window._mouseOver, W.held = false, true
look()
check(write:IsShown(), "and stays while a mouse button is held: something of the window may be in hand")
W.held = false
look()
check(not write:IsShown() and not looker():IsShown(), "and goes when the mouse has left; then nothing looks for it any more")
local coreBar -- Core's title bar: the small chat has none (only filling the screen, below)
for _, widget in ipairs(W.frames) do
    if widget._parent == window and rawget(widget, "box") then coreBar = widget end
end
check(coreBar == nil, "the small chat has no title bar of Core's, nor its buttons")
open()
W.Wait(0)
check(editBox._strata == "MEDIUM" and editBox._level == Layout.LEVEL + Layout.INPUT_LEVEL, "the line to write in is drawn with the window, not above everything")
close()

-- A message the list's top edge cuts through
box._top, rows[1]._top, rows[2]._top = 500, 520, 500
box.scrolled()
check(not body(rows[1]):IsShown() and body(rows[2]):IsShown(), "a row that starts above the list's top edge shows nothing; one that starts at it is whole")
rows[1]._top = 480
box.laid()
check(body(rows[1]):IsShown(), "back inside, it is there again")

-- The scroll bar is there while the list is scrolled up from its newest message
local scrollBar
for _, widget in ipairs(W.frames) do if widget._kind == "EventFrame" and widget._parent == column then scrollBar = widget end end
check(scrollBar and not scrollBar:IsShown(), "at the newest message the list has no scroll bar")
box.atEnd, box.scrolls = false, true
box.scrolled()
check(scrollBar:IsShown(), "scrolled up, it has one, with or without the mouse over it")
box.atEnd = true
box.scrolled()
check(not scrollBar:IsShown(), "back down, it is gone again")
box.scrolls = false

-- The oldest messages go, a batch at a time
local had, removals = #Log.list, box.provider.removals or 0
for index = 1, Log.MAX do say("number " .. index) end
check(#Log.list <= Log.MAX and #Log.list > Log.MAX - Log.PRUNE and Log.list[#Log.list].text == "number " .. Log.MAX
    and #box.provider.list == #Log.list and box.provider.list[1] == Log.list[1], "the log keeps the last messages only, and the list with it")
check((box.provider.removals - removals) * Log.PRUNE == had + Log.MAX - #Log.list, "the oldest leave the list together, in one update for each batch")
check(box.view.padding.top == 0, "a full list has no room above its messages")
box.atEnd, box.scrolls = false, true
box.scrolled()
box.offset = 5000
for index = 1, Log.MAX - #Log.list + 1 do say("more " .. index) end
check(box.offset < 5000 and box.offset > 0, "scrolled up, the oldest leaving moves the list back by their rows: what you read stays in view")
box.atEnd = true
box.scrolled()
box.offset = nil
say("number " .. Log.MAX) -- the newest as before

-- The history: the last messages kept over a logout or /reload
do
    local char = Core.Character("Social")
    local switch, kept = control("Save chat history"), control("Messages kept")
    check(switch and switch.setting:GetValue() == true and kept and kept.setting:GetValue() == 100, "a history is kept at first: the last 100 messages")
    W.Fire("PLAYER_LOGOUT")
    local saved = char.history
    check(#saved == 100 and saved[100].text == Log.list[#Log.list].text and saved[100].side == "left" and saved[1].at == nil and saved[1].fits == nil,
        "at a logout the last 100 are kept for the character, only what they are made of")
    local live = Log.list
    Log.list = { { side = "left", text = "new", at = GetTime() } }
    Log.Restore(saved)
    check(#Log.list == 101 and Log.list[1].text == saved[1].text and Log.list[101].text == "new" and Log.list[1].at < GetTime() - 3600,
        "at the next login they stand in front of the log, long gone by: faded out")
    Log.Restore({ "junk", { text = 5, side = "left" }, { side = "left", text = "kept", r = {} } })
    check(Log.list[1].text == "kept" and Log.list[1].r == 1 and #Log.list == 102, "what is no message is left out")
    Log.Restore({ { side = "left", text = "tinted", r = "x", g = "0.5", b = 1 } })
    check(Log.list[1].text == "tinted" and Log.list[1].r == 1 and Log.list[1].g == 0.5 and #Log.list == 103,
        "a colour written in words is none, white; one written as a number in words is that number")
    check(char.historyVersion == Log.HISTORY, "the history says what it is")
    Log.Restore({ { side = "left", text = "spoiled", tie = "enemy", class = 5 } })
    check(Log.list[1].time == "" and Log.list[1].tie == nil and Log.list[1].class == nil, "a message without its time, with a tie or class that is none, can still be drawn")
    local list = Log.list
    Log.list = { { side = "left", text = "hi", name = "|Kq12|k", link = "|HBNplayer:|Kq12|k:3:57:BN_WHISPER:|h[|Kq12|k]|h" },
                 { side = "left", text = "hello", name = "Jaina", link = "|Hplayer:Jaina:57:WHISPER:Jaina|h[Jaina]|h" } }
    local session = Log.Saved(10)
    Log.list = list
    check(#session == 1 and session[1].link == "|Hplayer:Jaina:0:WHISPER:Jaina|h[Jaina]|h",
        "a Battle.net friend's name is this session's: not kept; nor is the number of a player's line")
    -- One saved before lines went by their event had loot, joins and the system's lines among the prints.
    local function Old(group, time, text, r, g, b) return { side = "center", group = group, time = time, text = text, r = r, g = g, b = b } end
    Log.list = {}
    Log.Restore({ Old("PRINT", "07:09", "|Hchannel:channel:1|h[1. HiddenRoom]|h Zarpas left channel.", 1, 0.75, 0.75),
                  Old("PRINT", "07:22", "Remember to act responsibly.", 1, 1, 0),
                  Old("PRINT", "07:22", "Guild Message of the Day: hi", 0.25, 1, 0.25),
                  Old("GUILD", "07:22", "Guild Message of the Day: hi", 0.25, 1, 0.25),
                  Old("PRINT", "07:23", "Some addon: hi", 1, 1, 1),
                  Old("PRINT", "07:23", "Some addon: hi", 1, 1, 1) })
    check(#Log.list == 5 and Log.list[1].group == "CHANNEL_NOTICES" and Log.list[2].group == "SYSTEM" and Log.list[3].group == "GUILD"
        and Log.list[4].group == "PRINT" and Log.list[5].group == "PRINT",
        "an older history's prints are sorted anew: a channel's link a notice, by colour the system's or the guild's, white a print; once each")
    Log.list = {}
    Log.Restore({ Old("PRINT", "07:30", "|Hchannel:channel:1|h[1. HiddenRoom]|h", 1, 0.75, 0.75) }, Log.HISTORY)
    check(Log.list[1].group == "PRINT", "a newer history's are left as they were saved")
    Log.list = live
    kept.setting:SetValue(500)
    check(Log.MAX == 500, "a longer history keeps the log that long too")
    kept.setting:SetValue(100)
    switch.setting:SetValue(false)
    W.Fire("PLAYER_LOGOUT")
    check(char.history == nil and Log.MAX == 200, "switched off, nothing is kept")
    switch.setting:SetValue(true)
end

-- The switch Group finder changed before the full screen's friends list was ever made: nothing to lay out yet.
;(function()
    Core.described[ns.name].changed("boardFinder")
    W.Wait(0.1)
    check(not Core.errors["Social: friends tabs"], "the switch Group finder changed before the friends list was made: nothing goes wrong")
end)()

-- Docked to a screen edge, it fills the screen when the mouse is pushed against that edge -------------
do
    local headers = {}
    for _, option in ipairs(Core.described.Social.list) do
        if option.tab == "Appearance" and option.header then headers[#headers + 1] = option.header end
    end
    local expand, kind = control("Can expand to fullscreen"), control("Animation type")
    local opacity, texture = control("Background opacity"), control("Background texture")
    local radius, edges = control("Corner radius"), control("Don't round corners on screen edges")
    check(table.concat(headers, ", ") == "Messages, Animations, Expand window, Window corners" and expand.setting:GetValue() == true,
        "the tab Appearance: first the messages' look and their animations, then Expand window and Window corners: the window can fill the screen at first")
    check(kind.setting:GetValue() == "global" and opacity.setting:GetValue() == 50 and texture.setting:GetValue() == "solid"
        and radius.setting:GetValue() == 10 and edges.setting:GetValue() == true
        and kind.predicate() and opacity.predicate() and texture.predicate() and radius.predicate() and edges.predicate(),
        "under it the window's own animation type (Use global type), the background half opaque, solid black, its corners a tenth round, square at the screen's edges")
    expand.setting:SetValue(false)
    check(not kind.predicate() and not opacity.predicate() and not texture.predicate() and radius.predicate() and edges.predicate(),
        "the full screen's switches greyed out while it cannot; the corners not: they shape the window at its place too")
    expand.setting:SetValue(true)
    UIParent._width, UIParent._height = 1920, 1080
    function methods:GetBottom() return self._bottom end
    local bar, strip
    EventRegistry:TriggerEvent("EditMode.Enter") -- arranged in Blizzard's Edit Mode, dragged by Core's box
    for _, widget in ipairs(W.frames) do
        if widget._parent == window and widget._scripts.OnDragStart then bar = widget end
    end
    window._left, window._bottom = 0, 410
    bar:GetScript("OnDragStart")(bar)
    bar:GetScript("OnDragStop")(bar)
    EventRegistry:TriggerEvent("EditMode.Exit")
    for _, widget in ipairs(W.frames) do
        if widget._parent == window and widget ~= grip and widget._scripts.OnEnter and widget:IsShown() then strip = widget end
    end
    check(Core.general.places["Social:place"].dock == "LEFT" and strip and strip._strata == "DIALOG", "let go at the left edge it docks there, a strip along that edge")
    local old = #box.provider.list
    step(options.fadeAfter + 2)
    check(seen(old) == 0, "(a message that has faded)")
    options.motion = "off"
    W.Wait(1)
    local moved = 0 -- what is done to the list as a whole: nothing (Core fades a window's content out on the way)
    box.CreateAnimationGroup = function(self) moved = moved + 1; return methods.CreateAnimationGroup(self) end
    strip:GetScript("OnEnter")(strip)
    step(2)
    check(moved == 0 and box._alpha == 1, "the messages stay in sight while the window fills the screen")
    local back -- the window's background while it fills the screen, solid black: its piece as large as the screen
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Texture" and widget._parent == window and widget._texture == "Interface\\Buttons\\WHITE8X8"
            and widget._width == 1920 and widget._height == 1080 then back = widget end
    end
    check(window._width == 1920 and window._height == 1080 and window._strata == "HIGH" and seen(old) == 1,
        "pushed against the screen's edge there, it fills the screen, above the game's bars, every message there to read")
    do
        local was = window._mouseOver
        come()
        window._mouseOver = false -- the mouse goes over the guild window, which is not ours
        look()
        step(options.fadeAfter + 2)
        check(seen(old) == 1 and seen(#box.provider.list) == 1, "full, no message fades, wherever the mouse is")
        window._mouseOver = was
    end
    do -- words picked out of the messages to copy: a drag over them, then Ctrl+C
        local Select = ns.Select
        check(box._mouse == true, "full, the chat's list takes the mouse: a drag over it picks words")
        -- The game's text, as far as picking needs it: one line, every letter (codes too) 6 wide from its left.
        function methods:FindCharacterIndexAtCoordinate(px, py)
            if not self._text then return nil end
            local left = self._left or 40
            local index = math.max(1, math.min(math.floor((px - left) / 6) + 1, #self._text + 1))
            return index, px >= left and px <= left + #self._text * 6 and py <= self:GetTop() and py >= (self._bottom or 0)
        end
        function methods:CalculateScreenAreaFromCharacterSpan(from, to)
            return { { left = (from - 1) * 6, bottom = 0, width = (to - from) * 6, height = 14 } }
        end
        IsControlKeyDown, IsMetaKeyDown = function() return W.ctrl or false end, function() return false end
        function methods:HighlightText() self.highlighted = true end
        say("hello there")
        say("the |cffff0000red|r door")
        say("bye now")
        local list, words = box.provider.list, {}
        for back = 0, 2 do -- the three newest, one under the other: "bye now" lowest
            words[3 - back] = text(box.rows[#list - back])
            words[3 - back]._left, words[3 - back]._top, words[3 - back]._bottom = 100, 300 + back * 40, 286 + back * 40
        end
        local function lit(nth)
            local count, shown = 0, 0
            for _, widget in ipairs(W.frames) do
                if widget._kind == "Texture" and widget._points[1] and widget._points[1][2] == words[nth] then
                    count = count + 1
                    if widget:IsShown() then shown = shown + 1 end
                end
            end
            return shown
        end
        local function copied()
            for _, widget in ipairs(W.frames) do
                if widget._kind == "EditBox" and widget._parent == UIParent and widget._alpha == 0 then return widget end
            end
        end
        local mouseX, mouseY = W.cursorX, W.cursorY
        W.cursorX, W.cursorY = 100 + 6 * 6 + 1, 375 -- in "hello there", before "there"
        box._scripts.OnMouseDown(box, "LeftButton")
        local driver
        for index = #W.frames, 1, -1 do
            local widget = W.frames[index]
            if not driver and widget._parent == nil and widget._scripts.OnUpdate and widget:IsShown() then driver = widget end
        end
        W.cursorX, W.cursorY = 100 + 6 * 3 + 1, 335 -- in "the red door", after "the"
        driver._scripts.OnUpdate(driver, 0.01)
        check(lit(1) == 1 and lit(2) == 1 and lit(3) == 0 and not copied(),
            "pressed in one message and dragged into the next: what is between is lit as it follows the mouse")
        box._scripts.OnMouseUp(box, "LeftButton")
        local copy = copied()
        check(copy and copy:IsShown() and copy.highlighted and copy._text == "Thrall: there\nThrall: the",
            "let go, the words wait highlighted to be copied, each message's on its own line after its speaker")
        W.ctrl = true
        copy._scripts.OnKeyDown(copy, "LCTRL")
        copy._scripts.OnKeyDown(copy, "C")
        check(copy:IsShown(), "Ctrl+C: the edit box copies them itself")
        W.Wait(0.1)
        W.ctrl = false
        check(not copy:IsShown() and lit(1) == 1 and lit(2) == 1, "and a frame later the keyboard is the game's again; they stay lit")
        W.cursorX, W.cursorY = 100, 295 -- "bye now", before its first letter
        box._scripts.OnMouseDown(box, "LeftButton")
        check(lit(1) == 0 and lit(2) == 0, "the next press lets them go")
        box._scripts.OnMouseUp(box, "LeftButton")
        check(not copy:IsShown() and lit(3) == 0, "a press with no drag picks nothing")
        W.cursorX, W.cursorY = 100, 335
        box._scripts.OnMouseDown(box, "LeftButton")
        W.cursorX = 900 -- past its end, beside the bubble
        box._scripts.OnMouseUp(box, "LeftButton")
        check(copy:IsShown() and copy._text == "the red door" and lit(2) == 1,
            "from one message only its words, as they read: without the colour's codes, no name")
        copy._scripts.OnKeyDown(copy, "W")
        check(not copy:IsShown() and lit(2) == 0, "any other key lets them go, and the keyboard is the game's")
        check(Select.Words("a |Hitem:19019:0|h[Thunderfury]|h b", 1, 40) == "a [Thunderfury] b"
            and Select.Words("x |TInterface\\Icons\\Star:0|t y || z", 1, 40) == "x  y | z"
            and Select.Words("über", 2, 6) == "über" and Select.Words("one|ntwo", 1, 9) == "one\ntwo",
            "a link reads as its words, an icon as nothing, a bar as one; a letter of two bytes is taken whole")
        check(Select.Words("WTS |cnIQ5:|Hitem:19019::::::::60:::::::::|h[Thunderfury]|h|r cheap", 1, 70) == "WTS [Thunderfury] cheap"
            and Select.Words("150 |cnPURE_GREEN_COLOR:(+5)|r / 300", 1, 40) == "150 (+5) / 300",
            "a colour by its name (|cn, the name, a colon) reads as nothing, as one of eight digits does")
        box._scripts.OnMouseDown(box, "LeftButton")
        W.cursorX, W.cursorY = 100, 375
        box._scripts.OnMouseUp(box, "LeftButton")
        ns.Window.Pick("feed")
        check(not copy:IsShown() and lit(2) == 0 and lit(1) == 0, "another of the conversations' rows chosen: what was picked goes")
        ns.Window.Pick("chat")
        W.cursorX, W.cursorY = mouseX, mouseY
        check(not Core.errors["Social: selection"], "(nothing went wrong in picking)")
    end
    check(window._mouse == true and window._wheel == true and back._alpha == 0.5,
        "nothing behind it takes the mouse; its background is half see-through")
    opacity.setting:SetValue(100)
    check(back._alpha == 1, "the opacity set counts at once")
    opacity.setting:SetValue(50)
    radius.setting:SetValue(30)
    check(not Core.errors["full screen"] and back:IsShown(), "a new corner radius is taken in while it fills the screen")
    radius.setting:SetValue(10)
    W.cursorX, W.cursorY = 900, 500 -- the mouse goes from the edge: a push there counts again (Edge.lua)
    W.Wait(Core.Edge.LOOK)
    strip:GetScript("OnEnter")(strip)
    check(not window._mouse and not window._wheel, "back, the mouse goes through it again")
    check(box._mouse == false, "and through its list: at its size no words are picked, a click goes into the game")
    check(window._width == Layout.WIDTH and window._height == Layout.HEIGHT and window._points[1][1] == "LEFT" and window._strata == "MEDIUM",
        "pushed there again, it is back in its zone, at its size")
    options.motion = "global"
    options.animations = false
    W.Wait(1)
    strip:GetScript("OnEnter")(strip)
    check(window._width == 1920, "with all animations off it fills the screen at once, whatever its type")
    local classic -- Core's dropdown Classic windows, in the window's top right corner
    for _, widget in ipairs(W.frames) do
        if widget._kind == "DropdownButton" and widget._parent == window and widget ~= ns.Board.layouts.menu then classic = widget end
    end
    check(classic and classic:IsShown() and #classic._items == 4 and classic._items[1].title == ns.TEXT.title and classic._items[2].text == "Chat"
        and classic._items[3].text == "Friends list" and classic._items[4].text == "Group finder",
        "full, the dropdown Classic windows offers the game's chat, friends list and group finder")
    local coreBar -- Core's title bar at the top of the full window
    for _, widget in ipairs(W.frames) do
        if widget._parent == window and rawget(widget, "box") then coreBar = widget end
    end
    -- The full screen's parts: the guild window at the top right with the friends list under it (the group finder a
    -- tab of it), the conversations at the left, the chat chosen there beside their list.
    local tall = 1080 - Core.Window.FULL_BAR
    local board = Layout.Board(1920, tall, { friends = true, talks = true })
    check(board.friends and board.talks and not board.guild and board.friends[1] == 1920 - Layout.PAD - Layout.FRIENDS_WIDTH
        and board.friends[2] == Layout.PAD and board.friends[4] == tall - 2 * Layout.PAD
        and board.talks[1] == Layout.PAD and board.talks[3] == 1920 - 3 * Layout.PAD - Layout.FRIENDS_WIDTH
        and board.talks[4] == tall - 2 * Layout.PAD and board.chat[1] == Layout.PAD + Layout.TALK_LIST + 1
        and board.chat[2] == Layout.PAD + Layout.HEADER + Layout.TALK_HEAD and board.chat[3] == board.talks[3] - Layout.TALK_LIST - 1
        and board.chat[4] == board.talks[4] - Layout.HEADER - Layout.TALK_HEAD,
        "the full screen: the friends list at the right, the conversations at the left, the chat beside their list")
    do
    local guilded = Layout.Board(1920, tall, { friends = true, talks = true, guild = { 814, 426 } })
    check(guilded.guild and guilded.guild[1] == 1920 - Layout.PAD - 814 and guilded.guild[2] == Layout.PAD
        and guilded.guild[3] == 814 and guilded.guild[4] == 426 and guilded.guild[5] == 1
        and guilded.friends[1] == guilded.guild[1] and guilded.friends[3] == 814 and guilded.friends[2] == 2 * Layout.PAD + 426
        and guilded.friends[4] == tall - 3 * Layout.PAD - 426 and guilded.talks[3] == 1920 - 3 * Layout.PAD - 814,
        "a guild window at the top right, as large as it is, the friends list under it and as wide, the conversations beside")
    local small = Layout.Board(1200, 700, { friends = true, talks = true, guild = { 814, 426 } })
    check(small.guild and small.guild[5] < 1 and small.guild[3] == math.floor(814 * small.guild[5] + 0.5)
        and small.talks[3] == Layout.TALKS_MIN and small.friends[4] >= Layout.FRIENDS_LOW,
        "on a smaller screen the guild window is made smaller: the conversations keep their least width")
    local low = Layout.Board(1920, 600, { friends = true, talks = true, guild = { 814, 426 } })
    check(low.guild[5] < 1 and low.friends[4] == Layout.FRIENDS_LOW and low.guild[4] == 600 - 3 * Layout.PAD - Layout.FRIENDS_LOW,
        "and on a low one, the friends list under it keeps its least height")
    local tiny = Layout.Board(900, 600, { friends = true, talks = true, guild = { 814, 426 } })
    check(not tiny.guild and tiny.friends and tiny.talks, "where it would be too small it is left out, the friends list stays")
    check(not Layout.Board(1920, tall, { friends = true, talks = true, guild = { 0, 0 } }).guild, "a guild window of no size is none")
    local alone = Layout.Board(1920, tall, { friends = true })
    check(not alone.talks and alone.chat[1] == Layout.PAD and alone.chat[3] == 1920 - 3 * Layout.PAD - Layout.FRIENDS_WIDTH
        and alone.chat[2] == Layout.PAD, "without the conversations the chat stands in their place")
    local dragged = Layout.Board(1920, tall, { friends = true, talks = true, list = 300 })
    check(dragged.chat[1] == Layout.PAD + 300 + 1 and dragged.chat[3] == dragged.talks[3] - 300 - 1,
        "the conversations' list as wide as it was dragged, the chat beside it")
    check(Layout.TalkList(nil, 800) == Layout.TALK_LIST and Layout.TalkList(20, 800) == Layout.TALK_LIST_LEAST
        and Layout.TalkList(5000, 800) == 800 - Layout.TALK_PAGE - 1 and Layout.TalkList(5000, Layout.TALKS_MIN) == Layout.TALK_LIST,
        "never narrower than its least, and the one chosen beside it keeps its least")
    end
    check(coreBar and coreBar:IsShown() and coreBar.title._text == "Social" and coreBar.glass:IsShown()
        and listTop() == -(Core.Window.FULL_BAR + board.chat[2] + Layout.EDGE) and column._width == board.chat[3],
        "full, Core's title bar is at its top, with the search; the chat stands beside the conversations' list")
    local panels, friends, finder = ns.Board.panels, nil, nil
    do
    local narrow = Layout.Board(900, 600, { friends = true })
    check(narrow.friends and narrow.chat[3] >= Layout.CHAT_MIN, "a screen with room keeps the friends list")
    narrow = Layout.Board(600, 300, { friends = true })
    check(not narrow.friends and narrow.chat[3] == 600 - 2 * Layout.PAD, "a small one leaves the chat alone")
    narrow = Layout.Board(400, 300, { friends = true, talks = true })
    check(not narrow.talks and narrow.chat[3] == 400 - 2 * Layout.PAD, "and one too small for the conversations, the chat")
    check(panels.friends:IsShown() and panels.finder == nil and panels.feed == nil and panels.talks:IsShown()
        and panels.friends._points[1][4] == board.friends[1] and panels.talks._width == board.talks[3]
        and panels.friends.title._text == "Tester|cff416380#4321|r",
        "each panel stands at its place, with its title; the friends list's is your BattleTag, its number dimmed")
    -- What a panel holds, wherever in it: the list on show, a button of a foot on show, a tab.
    local function within(widget, ancestor)
        while widget do
            if widget == ancestor then return true end
            widget = widget._parent
        end
        return false
    end
    local function list(panel)
        for _, other in ipairs(boxes) do
            if within(other, panel) and other:IsVisible() then return other end
        end
    end
    local function foot(panel, text)
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Button" and widget._text == text and within(widget, panel) and widget:IsVisible() then return widget end
        end
    end
    local send, invite, finderTab, friendsTab
    ;(function() -- the friends list's panel, its tabs one by one
    local function click(widget, button) widget:GetScript("OnClick")(widget, button or "LeftButton") end
    local function named(list, ...)
        local names = {}
        for index, element in ipairs(list.provider.list) do
            local name = element.kind == "divider" and "-" or element.divider and "-" or element.name or element.fullName
            names[index] = tostring(name)
        end
        return table.concat(names, ", ")
    end
    -- The head: your status (a dropdown of the game's three), your BattleTag, friends online, the contacts menu.
    local status, contacts, filter, tabs = nil, nil, nil, {}
    for _, widget in ipairs(W.frames) do
        if widget._kind == "DropdownButton" and widget._parent == panels.friends.head then
            if widget._width == 51 then status = widget else contacts = widget end
        elseif widget._kind == "DropdownButton" and within(widget, panels.friends) then
            filter = widget
        elseif widget._kind == "Button" and widget.key and within(widget, panels.friends) then
            tabs[widget.key] = widget
        end
    end
    local count
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and widget._parent == panels.friends.head and widget._text == "3 / 5 online" then count = widget end
    end
    check(status and #status._items == 3 and status._items[2].text:find("Away") and count,
        "the head: Available, Away and Busy to be seen in, and how many friends are online")
    status._items[2].fn(status._items[2].data)
    check(asks[#asks] == "afk true", "Away chosen, Battle.net is told")
    status._items[1].fn(status._items[1].data)
    check(asks[#asks - 1] == "afk false" and asks[#asks] == "dnd false", "Available: neither away nor busy")
    check(contacts and #contacts._items == 2 and contacts._items[2].text == "Ignore List",
        "Forever: the contacts menu holds the ignore list, no broadcast (its own took it out)")
    W.Play("retail")
    contacts:GenerateMenu()
    check(contacts._items[2].text == "Broadcast" and contacts._items[3].text == "Ignore List",
        "Retail: the contacts menu: your broadcast and the ignore list")
    contacts._items[2].fn()
    W.popups[#W.popups].data.callback("raid tonight")
    check(asks[#asks] == "broadcast raid tonight", "a broadcast written is sent to Battle.net")
    W.Play("forever")
    contacts:GenerateMenu()
    -- The tabs: the game's, a count where something waits.
    check(tabs.Friends._text == nil and tabs.Friends.Text._text == "Friends" and tabs.Allies.Text._text == "Recent Allies"
        and tabs.Requests.Text._text == "Requests (2)" and tabs.Raid.Text._text == "Raid" and tabs.Quick.Text._text == "Quick Join (1)"
        and tabs.Finder.Text._text == "Group Finder" and tabs.Finder:IsShown(),
        "the tabs: Friends, Recent Allies, Requests with how many wait, Raid, Quick Join with how many groups, Group Finder")
    finderTab, friendsTab = tabs.Finder, tabs.Friends
    -- The friends list, in the game's order: Battle.net friends online, characters online, a divider, the offline ones.
    friends = list(panels.friends)
    check(named(friends) == "Jaina, Varian, Rexxar, Level 60 Hunter, -, Anduin, Garrosh",
        "the friends list: online Battle.net friends, online characters, a divider, then the offline ones")
    check(friends.provider.list[1].character == "Proudmoore" and friends.provider.list[1].info == "Theramore"
        and friends.provider.list[2].status == "Away" and friends.provider.list[2].info == "In the Battle.net app"
        and friends.provider.list[3].status == "DnD" and friends.provider.list[5].status == "Offline",
        "with the character they play, where they are or what they do, and their status")
    check(friends.rows[1].icon._texture == "Interface\\FriendsFrame\\StatusIcon-Online" and friends.rows[1].top._text:find("Proudmoore")
        and friends.rows[1].side:IsShown() and friends.rows[1].bottom._text == "Theramore", "a row as the game's: status icon, name, where, the game's icon")
    send, invite = foot(panels.friends, "Send Message"), foot(panels.friends, "Invite")
    check(send and invite and not send:IsEnabled() and not invite:IsEnabled(), "Send Message and Invite wait for a friend to be chosen")
    click(friends.rows[1])
    click(send)
    click(invite)
    check(asks[#asks - 1] == "bnet tell Jaina" and asks[#asks] == "bnet invite 70", "chosen, a Battle.net friend gets a message and an invite to the game they play in")
    friends.rows[6]:GetScript("OnClick")(friends.rows[6], "LeftButton")
    check(not send:IsEnabled() and not invite:IsEnabled(), "a character offline gets neither")
    -- The invite button of a row: for a Battle.net friend online; greyed, with the reason, where they play another game.
    local jaina, varian = friends.rows[1].invite, friends.rows[2].invite
    check(jaina:IsShown() and jaina:IsEnabled() and varian:IsShown() and not varian:IsEnabled() and not friends.rows[3].invite:IsShown(),
        "the invite button: on Battle.net friends online, greyed for one in another game, none on a character")
    click(jaina)
    check(asks[#asks] == "bnet invite 70", "it asks the friend into your group")
    GameTooltip._lines = nil
    varian:GetScript("OnEnter")(varian)
    check(GameTooltip._lines and GameTooltip._lines[1]:find("not in World of Warcraft"), "greyed, its tooltip says why not")
    GameTooltip._lines = nil
    friends.rows[1]:GetScript("OnEnter")(friends.rows[1])
    local said = table.concat(GameTooltip._lines or {}, "|")
    check(said:find("Jaina#1234", 1, true) and said:find("Theramore") and said:find("raid healer"),
        "the mouse on a friend: their BattleTag, where they are, their note")
    -- A favourite stands first, with the game's star.
    asks.bnet[3].isFavorite = true
    W.Fire("BN_FRIEND_INFO_CHANGED")
    W.Wait(0.1)
    check(named(friends) == "Anduin, -, Jaina, Varian, Rexxar, Level 60 Hunter, -, Garrosh", "a favourite first, apart from the others")
    asks.bnet[3].isFavorite = nil
    W.Fire("BN_FRIEND_INFO_CHANGED")
    W.Wait(0.1)
    -- The filter: by status and by kind.
    filter:GenerateMenu()
    check(filter and filter:IsShown() and filter._items[1].title == "Status" and #filter._items == 8, "the filter: four statuses, two kinds")
    filter._items[5].fn(filter._items[5].data) -- Offline
    W.Wait(0.1) -- a tick asks for the list anew a frame later
    check(named(friends) == "Anduin, Garrosh", "ticked Offline, the friends offline only")
    filter._items[5].fn(filter._items[5].data)
    filter:GenerateMenu()
    filter._items[8].fn(filter._items[8].data) -- Characters
    W.Wait(0.1)
    check(named(friends) == "Rexxar, Level 60 Hunter, -, Garrosh", "ticked Characters, the characters only")
    filter._items[8].fn(filter._items[8].data)
    W.Wait(0.1)
    check(#friends.provider.list == 6, "unticked, all again")
    -- The ignore list, from the contacts menu, in the friends list's place.
    contacts:GenerateMenu()
    contacts._items[2].fn()
    local ignored = list(panels.friends)
    check(ignored ~= friends and named(ignored) == "Ignored, Gamon, Blocked Invites, Spammer", "the ignore list: players ignored, invites blocked")
    local remove = foot(panels.friends, "Remove")
    check(remove and not remove:IsEnabled(), "Remove waits for one to be chosen")
    click(ignored.rows[4])
    click(remove)
    check(asks[#asks] == "block 41 false", "a blocked account chosen and removed is blocked no longer")
    click(foot(panels.friends, "Ignore Player"))
    W.popups[#W.popups].data.callback("Gazlowe")
    check(asks[#asks] == "ignore Gazlowe", "Ignore Player asks for a name, and ignores them")
    click(foot(panels.friends, "Back"))
    check(list(panels.friends) == friends, "Back: the friends list again")
    -- Requests: the newest first, Accept and Decline (or block) on each; the line to add a friend.
    click(foot(panels.friends, "Add Friend"))
    local requests = list(panels.friends)
    check(requests ~= friends and named(requests) == "Tyrande, Sylvanas", "Add Friend: the tab Requests, the newest request first")
    click(requests.rows[1].accept)
    check(asks[#asks] == "accept 32", "Accept")
    click(requests.rows[2].decline)
    local declined = W.menus[#W.menus]
    check(declined[1].text == "Decline" and declined[2].text == "Block Invites", "Decline: decline, or block their invites")
    declined[2].fn()
    W.popups[#W.popups].data.callback()
    check(asks[#asks - 1] == "block 31 true" and asks[#asks] == "decline 31", "blocked once asked, and declined")
    local line
    for _, widget in ipairs(W.frames) do
        if widget._kind == "EditBox" and within(widget, panels.friends) and widget:IsVisible() and widget._scripts.OnEnterPressed then line = widget end
    end
    line._text = "Arthas#1111"
    line:GetScript("OnEnterPressed")(line)
    check(asks[#asks] == "bnet add Arthas#1111" and line._text == "", "a BattleTag typed asks over Battle.net")
    line._text = "Uther"
    click(foot(panels.friends, "Add Friend"))
    check(asks[#asks] == "add Uther", "a character's name adds the character")
    -- Recent allies: loading until the game has them; pinned first; the game's own menu.
    click(tabs.Allies)
    local allies = list(panels.friends)
    check(asks[#asks] ~= "allies asked" and #allies.provider.list == 0 and allies.empty._text:find("not read your recent allies"),
        "Recent Allies: not asked for (only the game's code may), and until the game has them the list says where they come from")
    asks.alliesReady = true
    W.Fire("RECENT_ALLIES_DATA_READY")
    W.Wait(0.1)
    check(named(allies) == "Cairne, -, Magatha" and allies.rows[1].top._text == "Cairne Bloodhoof" and allies.rows[1].side:IsShown(),
        "then the allies: the pinned one first, with the game's pin, a divider, the others")
    check(allies.rows[1].bottom._text == "Level 60 Warrior - Mulgore", "with the level, class and where they are")
    click(allies.rows[1], "RightButton")
    check(asks[#asks] == "menu RECENT_ALLY Cairne Bloodhoof", "a right click: the game's own menu of a recent ally")
    click(allies.rows[1])
    click(foot(panels.friends, "Invite"))
    check(asks[#asks] == "invite Cairne Bloodhoof", "chosen, invited")
    filter:GenerateMenu()
    check(#filter._items == 7 and filter._items[6].title == "Activities" and filter._items[7].text == "Raiding",
        "its filter: the statuses and the kinds of activity this client has")
    filter._items[7].fn(filter._items[7].data)
    W.Wait(0.1)
    check(asks.allySearch.interactionCategoryFilters[1] == 3 and named(allies) == "Magatha", "an activity ticked: the game finds the allies")
    filter._items[7].fn(filter._items[7].data)
    W.Wait(0.1)
    -- Raid: not in one, Convert to Raid; in one, its groups, to be arranged by dragging.
    click(tabs.Raid)
    local raid = list(panels.friends)
    check(#raid.provider.list == 0 and raid.empty._text:find("raid") and foot(panels.friends, "Convert to Raid"),
        "Raid: not in one, what a raid is, and Convert to Raid")
    click(foot(panels.friends, "Convert to Raid"))
    check(asks[#asks] == "convert", "a party turned into a raid")
    W.raiding = true
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(0.1)
    check(#raid.provider.list == 11 and raid.provider.list[1].kind == "group" and raid.provider.list[2].name == "Tester"
        and raid.provider.list[4].group == 2 and raid.provider.list[5].name == "Rexxar" and not foot(panels.friends, "Convert to Raid"),
        "in a raid: its eight groups with their members")
    check(raid.rows[2].top._text:find("LeaderIcon") and raid.rows[5].bottom._text == "Level 60 Hunter - Offline",
        "the leader's crown; one offline says so")
    raid.rows[3]:GetScript("OnDragStart")(raid.rows[3])
    raid.rows[5]._mouseOver = true
    raid.rows[3]:GetScript("OnDragStop")(raid.rows[3])
    check(asks[#asks] ~= "swap 2 3", "only the leader or an assistant arranges the raid")
    asks.leader = true
    raid.rows[3]:GetScript("OnDragStart")(raid.rows[3])
    raid.rows[3]:GetScript("OnDragStop")(raid.rows[3])
    check(asks[#asks] == "swap 2 3", "a member dragged onto one of another group: the two swap")
    raid.rows[5]._mouseOver = nil
    raid.rows[6]._mouseOver = true
    raid.rows[3]:GetScript("OnDragStart")(raid.rows[3])
    raid.rows[3]:GetScript("OnDragStop")(raid.rows[3])
    check(asks[#asks] == "move 2 3", "onto another group's line: moved there")
    raid.rows[6]._mouseOver = nil
    ;(function() -- a right click: a menu of its own, what the game's offers for that member at your rank that an addon may do
    local leads, assists, named = UnitIsGroupLeader, UnitIsGroupAssistant, UnitName
    local NAMES = { raid1 = { "Tester", "Stub" }, raid2 = { "Thrall", "Earthfury" }, raid3 = { "Rexxar", "Wildheart" } }
    UnitIsGroupLeader = function(unit) return unit == "player" or unit == "raid1" end -- you lead; Rexxar assists
    UnitIsGroupAssistant = function(unit) return unit == "raid3" end
    UnitIsUnit = function(a, b) return a == b or (a == "raid1" and b == "player") end
    UnitName = function(unit) if NAMES[unit] then return unpack(NAMES[unit]) end return named(unit) end
    for _, call in ipairs({ "PromoteToLeader", "PromoteToAssistant", "DemoteAssistant", "UninviteUnit" }) do
        C_PartyInfo[call] = function(name) asks[#asks + 1] = call .. " " .. name end
    end
    local function entries()
        local texts = {}
        for index, item in ipairs(W.menus[#W.menus]) do texts[index] = item.title or item.disabled and "(" .. item.text .. ")" or item.text end
        return table.concat(texts, ", ")
    end
    local before = #asks
    click(raid.rows[3], "RightButton")
    check(entries() == "Thrall, Whisper, Promote to Leader, Promote to Assistant, Remove" and #asks == before,
        "a right click: a menu of its own, what the game's offers its leader for a member, none of the game's opened")
    local thrall = W.menus[#W.menus]
    thrall[3].fn()
    check(asks[#asks] == "PromoteToLeader Thrall Earthfury", "Promote to Leader: the member by first name and surname")
    thrall[2].fn()
    check(asks[#asks] == "tell Thrall Earthfury", "Whisper: the line to write in opens with the whisper")
    click(raid.rows[5], "RightButton")
    check(entries() == "Rexxar, (Whisper), Promote to Leader, Demote, Remove", "an assistant, offline: demoted rather than promoted, no whisper")
    click(raid.rows[2], "RightButton")
    check(entries() == "Tester", "yourself: nothing to do")
    UnitIsGroupLeader = function(unit) return unit == "raid2" end -- Thrall leads, you assist
    UnitIsGroupAssistant = function(unit) return unit == "player" or unit == "raid1" end
    click(raid.rows[3], "RightButton")
    check(entries() == "Thrall, Whisper", "an assistant may not touch the leader")
    click(raid.rows[5], "RightButton")
    check(entries() == "Rexxar, (Whisper), Remove", "but removes a member who is neither")
    UnitIsGroupLeader, UnitIsGroupAssistant, UnitName, UnitIsUnit = leads, assists, named, nil
    for _, call in ipairs({ "PromoteToLeader", "PromoteToAssistant", "DemoteAssistant", "UninviteUnit" }) do C_PartyInfo[call] = nil end
    end)()
    click(foot(panels.friends, "Raid Info"))
    local locks = list(panels.friends)
    check(asks.raidInfo and locks ~= raid and named(locks) == "Molten Core" and locks.rows[1].right._text == "3600 s",
        "Raid Info: the instances you are saved to, with the time left")
    click(foot(panels.friends, "Back"))
    check(list(panels.friends) == raid, "Back: the groups again")
    asks.leader, W.raiding = nil, false
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(0.1)
    -- Quick Join: groups of friends; the roles to join as, then the request.
    click(tabs.Quick)
    local quick = list(panels.friends)
    check(named(quick) == "nil" and quick.rows[1].top._text:find("Jaina") and quick.rows[1].top._text:find("+1", 1, true)
        and quick.rows[1].bottom._text == "Ragefire Chasm", "Quick Join: who you know there, and what the group is queued for")
    local join = foot(panels.friends, "Join Queue")
    check(join and not join:IsEnabled(), "Join Queue waits for a group to be chosen")
    click(quick.rows[1])
    local wasGrouped = grouped
    grouped = true
    click(quick.rows[1])
    check(not join:IsEnabled(), "in a group of your own, none can be joined")
    grouped = false
    click(quick.rows[1])
    check(join:IsEnabled(), "chosen, out of a group, it can be joined")
    click(join)
    local roles = W.menus[#W.menus]
    check(roles[1].title == "Role" and #roles == 5 and roles[3].checked(roles[3].data) and not roles[2].checked(roles[2].data),
        "the roles to join as, as you chose them last in the group finder")
    roles[5].fn()
    check(asks[#asks] == "join Party-1 false true false", "and the request, as a healer")
    grouped = wasGrouped
    click(tabs.Friends)
    check(list(panels.friends) == friends, "back to the friends list")
    end)()
    ;(function() -- a player targeted, by first name and surname; a request of a character only; away and busy; the rows
    local function click(widget, button) widget:GetScript("OnClick")(widget, button or "LeftButton") end
    local exists, named = UnitExists, UnitName
    UnitExists = function(unit) return unit == "target" end
    UnitName = function(unit) if unit == "target" then return "Droopy", "Fairwind" end return named(unit) end
    ns.Friends.Open("Ignored")
    click(foot(panels.friends, "Ignore Player"))
    check(asks[#asks] == "ignore Droopy Fairwind", "Ignore Player: the friendly player targeted, by first name and surname (no realm)")
    ns.Friends.Open("Requests", true)
    local line
    for _, widget in ipairs(W.frames) do
        if widget._kind == "EditBox" and within(widget, panels.friends) and widget:IsVisible() and widget._scripts.OnEnterPressed then line = widget end
    end
    check(line and line._text == "Droopy Fairwind", "Add Friend: the line holds them by that whole name")
    line._text = ""
    UnitExists, UnitName = exists, named
    local requests = list(panels.friends)
    click(requests.rows[1].decline) -- Tyrande's, of a character only
    local declined = W.menus[#W.menus]
    check(#declined == 1 and declined[1].text == "Decline", "a request of a character only is declined, not blocked: as the game's")
    declined[1].fn()
    check(asks[#asks] == "decline 32", "(declined)")
    check(ns.Contacts.Status(true, true, true) == "Away" and ns.Contacts.Status(true, false, true) == "DnD",
        "away and busy at once: away, as the game's lists say")
    ns.Friends.Open("Friends")
    local scripted, relays = friends.rows[1]:GetScript("OnClick"), friends.relays
    W.Fire("BN_FRIEND_INFO_CHANGED")
    W.Wait(0.1)
    check(friends.relays > relays and friends.rows[1]:GetScript("OnClick") == scripted, "a row drawn anew keeps its scripts, made once")
    check(not Core.errors["Social: friends"] and not Core.errors["Social: requests"] and not Core.errors["Social: ignore list"],
        "(nothing went wrong in the friends list)")
    end)()
    -- The group finder, a tab of the friends list: nothing searched until a category is chosen.
    finderTab:GetScript("OnClick")(finderTab, "LeftButton")
    finder = list(panels.friends)
    check(#finder.provider.list == 0 and finder.empty._text == "Choose a category to look for groups." and not asks.searched,
        "the group finder searches nothing by itself")
    local categories
    for _, widget in ipairs(W.frames) do
        if widget._kind == "DropdownButton" and widget._defaultText == "Category" and within(widget, panels.friends) then categories = widget end
    end
    check(categories._items[1].text == "Dungeons", "its categories are the game's")
    categories._items[1].fn(categories._items[1].data)
    check(asks.searched.category == 2 and asks.searched.activities[1] == 100 and finder.empty._text == "Searching...",
        "a category chosen is searched, in all its activities")
    W.Fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
    W.Wait(0.1)
    check(#finder.provider.list == 2 and finder.provider.list[1].leader == "Baine" and finder.provider.list[1].solo
        and finder.provider.list[2].activity == "Wailing Caverns" and finder.provider.list[2].comment == "need healer",
        "what it found: the newest first, a player alone and a group, with the activity and the comment")
    send, invite = foot(panels.friends, "Send Message"), foot(panels.friends, "Invite")
    finder.rows[1]:GetScript("OnClick")(finder.rows[1], "LeftButton")
    check(invite:IsEnabled(), "a player alone can be invited")
    invite:GetScript("OnClick")(invite)
    finder.rows[2]:GetScript("OnClick")(finder.rows[2], "LeftButton")
    check(not invite:IsEnabled() and asks[#asks] == "invite Baine", "a group not: its leader gets a message")
    send:GetScript("OnClick")(send)
    check(asks[#asks] == "tell Cairne", "(the leader whispered)")
    ;(function() -- the finder in chat lockdown, a listing with hidden parts, a search the tab was away for
    local function paused()
        for _, widget in ipairs(W.frames) do
            if widget._kind == "FontString" and within(widget, panels.friends) and widget:IsVisible()
                and (widget._text or ""):find("lockdown") then return widget end
        end
    end
    -- The game hides a listing's parts from addons: every part while chat is locked down, else those named here.
    local info, hiding = C_LFGList.GetSearchResultInfo, {} -- [id] = { [part] = true }
    C_LFGList.GetSearchResultInfo = function(id)
        local listing, seen = info(id), {}
        if not listing or not (W.locked or hiding[id]) then return listing end
        for key, value in pairs(listing) do seen[key] = (W.locked or hiding[id][key]) and "hidden" or value end
        return seen
    end
    issecretvalue = function(value) return value == "hidden" end
    W.locked = true
    W.Fire("LFG_LIST_SEARCH_RESULT_UPDATED", 11)
    W.Wait(0.1)
    check(#finder.provider.list == 2 and finder.provider.list[1].leader == "Baine" and paused(),
        "in chat lockdown the rows read last stay (the game hides the listings now), and its line says so")
    W.locked = false
    W.Fire("ADDON_RESTRICTION_STATE_CHANGED")
    W.Wait(0.1)
    check(#finder.provider.list == 2 and not paused(), "once it ends they are read anew")
    hiding[12] = { age = true }
    W.Fire("LFG_LIST_SEARCH_RESULT_UPDATED", 12)
    W.Wait(0.1)
    check(#finder.provider.list == 1 and finder.provider.list[1].leader == "Cairne", "a listing the game hides a needed part of is left out")
    issecretvalue, C_LFGList.GetSearchResultInfo = nil, info
    categories._items[1].fn(categories._items[1].data)
    check(finder.empty._text == "Searching...", "(searching)")
    friendsTab:GetScript("OnClick")(friendsTab, "LeftButton")
    W.Fire("LFG_LIST_SEARCH_RESULTS_RECEIVED") -- unheard: the tab is away
    W.Wait(0.1)
    finderTab:GetScript("OnClick")(finderTab, "LeftButton")
    check(#finder.provider.list == 2 and finder.empty._text ~= "Searching...", "a search the tab was away for is read when it is back")
    check(not Core.errors["Social: group finder"], "(nothing went wrong in the group finder)")
    end)()
    options.boardFinder = false
    Core.described[ns.name].changed("boardFinder")
    W.Wait(0.1)
    check(not finderTab:IsShown() and list(panels.friends) == friends, "its switch off, the tab goes, and Friends is shown again")
    options.boardFinder = true
    Core.described[ns.name].changed("boardFinder")
    W.Wait(0.1)
    check(finderTab:IsShown(), "on again, the tab is back")
    ;(function() -- Retail: its own group finder, its own unblock, its raid locks always extendable
    local Finder, switch = ns.Contacts.Finder, nil
    for _, option in ipairs(Core.described[ns.name].list) do
        if option.key == "boardFinder" then switch = option end
    end
    check(Finder.Usable() and not Core.Config.Hidden(ns.name, switch), "(Forever: the tab Group finder and its switch)")
    -- Raid Info's Extend Raid Lock: Forever asks the game whether it can extend one; Retail has no such question.
    local saved, locks = rawget(_G, "SetSavedInstanceExtend"), rawget(_G, "C_RaidLocks")
    rawset(_G, "SetSavedInstanceExtend", function() end)
    rawset(_G, "C_RaidLocks", { IsRaidLockExtendFeatureSupported = function() return false end })
    local function Extend()
        ns.Friends.Open("Raid")
        local info = foot(panels.friends, "Raid Info")
        info:GetScript("OnClick")(info, "LeftButton")
        local extend = foot(panels.friends, "Extend Raid Lock")
        local back = foot(panels.friends, "Back")
        back:GetScript("OnClick")(back, "LeftButton")
        return extend
    end
    check(Extend() == nil, "Forever: no Extend Raid Lock where the game says it cannot extend one")
    W.Play("retail")
    local finderFrame = W.NewWidget("Frame", "PVEFrame", UIParent)
    finderFrame:Hide()
    local opened = 0
    rawset(_G, "PVEFrame", finderFrame)
    rawset(_G, "PVEFrame_ToggleFrame", function() opened = opened + 1 end)
    ns.Friends.Open("Finder")
    ns.Friends.Relabel()
    W.Wait(0.1)
    check(not Finder.Usable() and not finderTab:IsShown() and list(panels.friends) == friends
        and Core.Config.Hidden(ns.name, switch), "Retail: the tab Group finder and its switch stand down, Friends is shown")
    ns.CLASSIC[3].show()
    check(opened == 1, "Retail: Group finder in Classic windows opens the game's own finder, as its micro menu button does")
    finderFrame:Show()
    ns.CLASSIC[3].show()
    check(opened == 1, "(not while it is open)")
    local found = false
    for _, name in ipairs(ns.CLASSIC[3].frame) do found = found or name == "PVEFrame" end
    check(found, "Retail's finder gets the button Sane UI too")
    local unblocked
    rawset(_G, "BNSetBlocked", function(id, on) unblocked = id .. " " .. tostring(on) end)
    ns.Contacts.Blocker()(7, false)
    check(C_BattleNet.SetBlocked == nil and unblocked == "7 false", "Retail: invites are blocked and unblocked by its own function")
    check(Extend() ~= nil, "Retail: Raid Info offers Extend Raid Lock, as the game's own always does")
    rawset(_G, "BNSetBlocked", nil)
    rawset(_G, "PVEFrame", nil)
    rawset(_G, "PVEFrame_ToggleFrame", nil)
    W.Play("forever")
    rawset(_G, "SetSavedInstanceExtend", saved)
    rawset(_G, "C_RaidLocks", locks)
    ns.Friends.Relabel()
    W.Wait(0.1)
    check(C_BattleNet.SetBlocked ~= nil and finderTab:IsShown() and Finder.Usable()
        and not Core.errors["Social: group finder"] and not Core.errors["Social: raid"],
        "Forever again: the tab is back, nothing went wrong")
    ns.Friends.Open("Friends")
    end)()
    ;(function() -- the conversations' panel: the chat, the second chat, every whisper, the party's and the raid's chat
    local Talks, talks = ns.Talks, panels.talks
    local function click(widget, button) widget:GetScript("OnClick")(widget, button or "LeftButton") end
    local function inside(panel)
        local found = {}
        for _, other in ipairs(boxes) do
            if within(other, panel) then found[#found + 1] = other end
        end
        return found[1], found[2]
    end
    local function texts(list)
        local said = {}
        for index, element in ipairs(list.provider.list) do said[index] = element.text end
        return table.concat(said, " | ")
    end
    local rows, messages = inside(talks)
    local function rowOf(talk)
        for index, element in ipairs(rows.provider.list) do
            if element == talk then return rows.rows[index] end
        end
    end
    local edit, filter
    for _, widget in ipairs(W.frames) do
        if widget._kind == "EditBox" and within(widget, talks) then edit = widget end
        if widget._kind == "DropdownButton" and within(widget, talks) then filter = widget end
    end
    function edit:SetFocus() self.focus = true end
    function edit:ClearFocus() self.focus = false end
    function edit:HasFocus() return self.focus or false end
    local function write(words)
        edit._text = words
        edit:GetScript("OnEnterPressed")(edit)
    end
    local sent, told = {}, nil
    C_ChatInfo.SendChatMessage = function(text, kind, _, target) sent[#sent + 1] = kind .. " " .. tostring(target) .. " " .. text end
    C_BattleNet.SendWhisper = function(id, text) sent[#sent + 1] = "BN " .. id .. " " .. text end
    C_BattleNet.GetAccountInfoByID = function(id)
        for _, friend in ipairs(asks.bnet) do
            if friend.bnetAccountID == id then return friend end
        end
    end
    ChatFrameUtil.SetLastToldTarget = function(target, kind) told = kind .. " " .. target end
    GetBNPlayerLink = function(name, shown, account, line, kind)
        return ("|HBNplayer:%s:%d:%d:%s|h%s|h"):format(name, account, line, kind, shown)
    end
    local wasGrouped, wasRaiding = grouped, W.raiding
    grouped, W.raiding = false, false
    W.Fire("GROUP_LEFT")
    W.Wait(0.1)
    check(talks and talks:IsShown() and talks._points[1][4] == board.talks[1] and talks._width == board.talks[3]
        and talks.title._text == "Conversations" and rows and messages and edit and filter,
        "the conversations stand at the left of the full screen: their list, the one chosen, a line to write in it")
    check(#rows.provider.list == 2 and rows.rows[1].top._text == "Chat" and rows.rows[2].top._text == "Second chat"
        and rows.rows[1].icon._texture:find("UI%-ChatIcon%-Chat") and rows.rows[1].bottom._text ~= "",
        "first in the list the chat and the second chat, the chat's last message under its name")
    check(column:IsVisible() and box:IsVisible() and not messages:IsVisible() and not edit:IsVisible() and filter:IsShown(),
        "the chat is chosen at first: it stands beside the list, the conversations' own messages and line are away")
    do -- the line between the list and the one chosen, dragged: only the line follows; let go, the list is that wide
        local grip, mouseX = nil, W.cursorX
        for _, widget in ipairs(W.frames) do
            local corners = widget._parent and rawget(widget._parent, "corners") -- the board's corners of the panel
            local corner = type(corners) == "table" and (corners.TOPRIGHT == widget or corners.BOTTOMRIGHT == widget)
            if widget._scripts.OnMouseDown and widget._scripts.OnEnter and within(widget, talks) and not corner then grip = widget end
        end
        local chatWidth = column._width
        grip._scripts.OnEnter(grip)
        check(W.cursorArt == "UI_RESIZE_CURSOR", "the mouse on the line between the list and the one chosen: the game's cursor for sizing")
        W.cursorX = 900
        grip._scripts.OnMouseDown(grip, "LeftButton")
        W.cursorX = 980
        grip._scripts.OnUpdate(grip, 0.01)
        check(column._width == chatWidth and ns.store.talkList == nil, "held, only the line follows the mouse")
        grip._scripts.OnMouseUp(grip, "LeftButton")
        check(ns.store.talkList == Layout.TALK_LIST + 80 and column._width == chatWidth - 80
            and column._width == talks._width - (Layout.TALK_LIST + 80) - 1,
            "let go, the list is that much wider, and kept; the chat beside it that much narrower")
        grip._scripts.OnMouseDown(grip, "LeftButton")
        W.cursorX = 500
        grip._scripts.OnUpdate(grip, 0.01)
        grip._scripts.OnMouseUp(grip, "LeftButton")
        check(ns.store.talkList == Layout.TALK_LIST_LEAST and column._width == chatWidth + Layout.TALK_LIST - Layout.TALK_LIST_LEAST,
            "never narrower than its least")
        grip._scripts.OnMouseDown(grip, "LeftButton")
        grip:Hide() -- the full screen went while the line was held
        grip:Show()
        check(grip._scripts.OnUpdate == nil, "the full screen gone meanwhile, the line is let go")
        grip._scripts.OnMouseDown(grip, "LeftButton")
        ns.Board.Hide() -- the full screen itself: its panels go, nothing hides the line; its OnHide runs under its panel's
        check(grip._scripts.OnUpdate == nil and grip:IsShown() and not grip:IsVisible() and not talks:IsShown(),
            "and when the full screen goes indeed: the line, out of sight only with its panel, is let go by its own OnHide")
        grip._scripts.OnLeave(grip)
        check(W.cursorArt == nil, "the mouse gone, the cursor is the game's again")
        ns.store.talkList, W.cursorX = nil, mouseX
        ns.Window.Reboard()
        check(column._width == chatWidth, "(back as at first)")
    end
    check(messages._mouse == true, "a conversation's messages take the mouse too: their words are picked to copy as the chat's")
    -- The chat views: the first, the second chat, chosen: a list of its own beside the list, the chats ticked for it.
    click(rows.rows[2])
    local feed
    for _, other in ipairs(boxes) do
        if other ~= box and other ~= rows and other ~= messages and within(other, talks) and other:IsVisible() then feed = other end
    end
    check(feed and feed:IsVisible() and not column:IsVisible() and not messages:IsVisible() and filter:IsShown(),
        "a chat view chosen stands beside the list in a list of its own; the chat is out of sight")
    local says = #feed.provider.list
    W.Fire("CHAT_MSG_GUILD", "for the horde", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 2, THRALL)
    check(#feed.provider.list == says + 1 and feed.provider.list[#feed.provider.list].text == "for the horde"
        and box.provider.list[#box.provider.list].text == "for the horde", "a guild message is in the second chat and in the chat")
    W.Wait(0.1)
    check(rows.rows[2].bottom._text == "Thrall: for the horde", "its row says the last message")
    say("only here")
    check(#feed.provider.list == says + 1 and box.provider.list[#box.provider.list].text == "only here", "what is said nearby only in the chat")
    W.Wait(0.1)
    check(rows.rows[1].glow:IsShown() and rows.rows[1].count._text == "2" and not rows.rows[2].glow:IsShown(),
        "the chat out of sight: its row lit for its messages not seen yet (the guild's and what was said), counting them; the view's not, in sight")
    local second = ns.Feed.Views()[1]
    local tick
    for _, item in ipairs(filter._items) do if item.text == "Say" then tick = item end end
    check(tick and not tick.checked(tick.data), "its list of chats on the line with its name has Say unticked")
    tick.fn(tick.data)
    check(second.shows.SAY and feed.provider.list[#feed.provider.list].text == "only here" and ns.Feed.Shows(second, "SAY"),
        "ticked, the second chat shows what is said too")
    click(rows.rows[1])
    W.Wait(0.1)
    check(box:IsVisible() and not feed:IsVisible() and not rows.rows[1].glow:IsShown() and rows.rows[1].count._text == "",
        "the chat chosen again is back in its place, and seen")
    W.Fire("CHAT_MSG_GUILD", "anyone up?", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 3, THRALL)
    W.Wait(0.1)
    check(rows.rows[2].glow:IsShown() and rows.rows[2].count._text == "1" and ns.Feed.Unread(second) == 1,
        "a message the second chat shows comes while it is out of sight: its row is lit")
    check(second.unread == nil, "counted for this session only: nothing of it is kept with the view")
    ;(function()
        local _, tint = ns.Feed.Unread(second)
        ns.Feed.Added({ group = "GUILD", text = "", r = 0.5, g = 0.6, b = 0.7 }) -- no list of it on show: only counted
        local count, again = ns.Feed.Unread(second)
        check(tint and again == tint and tint[1] == 0.5 and count == 2,
            "the colour of the last message not seen: one table for each view, used again for the next")
        check(ns.Feed.Menu(second) == ns.Feed.Menu(second), "a view's list of chats is made once")
    end)()
    click(rows.rows[2])
    W.Wait(0.1)
    check(not rows.rows[2].glow:IsShown() and ns.Feed.Unread(second) == 0, "chosen, it is seen")
    -- New chat view: one more, chosen, showing nothing until its chats are ticked; renamed, removed.
    click(foot(talks, "New chat view"))
    local made = ns.Feed.Views()[2]
    check(made and made.name == "Chat view 2" and next(made.shows) == nil and rows.provider.list[3].view == made
        and #feed.provider.list == 0, "New chat view: one more under the second, chosen, showing nothing yet")
    click(rows.rows[3], "RightButton")
    local menu = W.menus[#W.menus]
    for _, item in ipairs(menu) do
        if item.text == "Rename" then item.fn() end
    end
    W.popups[#W.popups].data.callback("Trade")
    W.Wait(0.1)
    check(made.name == "Trade" and rows.rows[3].top._text == "Trade", "renamed by a right click")
    click(rows.rows[3])
    click(foot(talks, "Remove"))
    W.popups[#W.popups].data.callback()
    check(#ns.Feed.Views() == 1 and #rows.provider.list == 2 and column:IsVisible() and box:IsVisible(),
        "removed once confirmed, and the chat is chosen")
    ;(function() -- saved views of another shape (an older version, a hand edit) are mended or left out
        local views = ns.store.views
        ns.store.views = { next = "x", list = { "junk", { id = "2", name = "Second" }, { id = 3 }, { id = 7, name = 5, shows = "all" } } }
        local list = ns.Feed.Views()
        check(#list == 2 and list[1].id == 3 and list[1].name == "Chat view 3" and next(list[1].shows) == nil
            and list[2].id == 7 and list[2].name == "Chat view 7" and next(list[2].shows) == nil and ns.Feed.Make().id == 8,
            "a saved view without a number for its id is left out, one without a name or its chats gets them, the next id is past the last")
        ns.store.views = views
    end)()
    click(rows.rows[1])
    -- A whisper: a conversation of its own, read once it is chosen.
    W.Fire("CHAT_MSG_WHISPER", "are you coming?", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 5, THRALL)
    W.Wait(0.1) -- the list anew a frame later
    local thrall = Talks.by["W:Thrall-Stub"]
    check(thrall and thrall.kind == "WHISPER" and thrall.with == "Thrall-Stub" and thrall.class == "SHAMAN" and thrall.unread == 1
        and #rows.provider.list == 3 and rows.provider.list[3] == thrall and rows.rows[3].top._text == "Thrall"
        and rows.rows[3].bottom._text == "are you coming?" and rows.rows[3].icon._atlas == "classicon-shaman",
        "a whisper starts a conversation with its sender, under the chats: their class icon, their name, what they said")
    click(rowOf(thrall))
    check(thrall.unread == 0 and not column:IsVisible() and messages:IsVisible() and edit:IsVisible() and not filter:IsShown(),
        "chosen, it is read, beside the list in the chat's place")
    check(texts(messages) == "Today | are you coming?" and messages.provider.list[2].label == nil
        and messages.provider.list[2].name == "Thrall" and messages.provider.list[2] ~= Log.list[#Log.list],
        "its messages in the chat's bubbles, a pill for the day; its own copies, without the chat's name above them")
    check(edit:IsEnabled(), "chosen, it can be written in")
    write("on my way")
    check(sent[#sent] == "WHISPER Thrall-Stub on my way" and told == "WHISPER Thrall-Stub" and edit._text == "",
        "Enter sends the words as a whisper to them, as the game's line does (they are the one told last), and empties the line")
    W.Fire("CHAT_MSG_WHISPER_INFORM", "on my way", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 6, THRALL)
    W.Wait(0.1)
    check(texts(messages) == "Today | are you coming? | on my way" and messages.provider.list[3].side == "right"
        and rowOf(thrall).bottom._text == "You: on my way",
        "the whisper comes back from the game and joins the conversation on your side")
    -- The game's line opened meanwhile: by Enter alone the conversation's line takes the cursor, a command is the chat's.
    edit.focus = false
    open()
    W.Wait(0.1)
    check(not editBox:IsShown() and edit:HasFocus() and rows.provider.list[3] == thrall and not column:IsVisible(),
        "Enter while a conversation is chosen: the game's line closes again, the conversation's own has the cursor")
    edit.focus = false
    open()
    editBox.typed = "/dance"
    W.Wait(0.1)
    check(editBox:IsShown() and column:IsVisible() and box:IsVisible() and not edit:HasFocus(),
        "a command in the game's line: the chat is chosen, the line is its")
    click(rowOf(thrall))
    check(not editBox:IsShown() and not column:IsVisible(), "a conversation chosen while the game's line is open closes it")
    -- A Battle.net friend: by their BattleTag; the newest first, waiting to be read.
    W.Fire("CHAT_MSG_BN_WHISPER", "raid at 8?", "|Kq7|k", "", "", "", "", 0, 0, "", 0, 7, nil, 7)
    W.Wait(0.1)
    local jaina = Talks.by["B:Jaina#1234"]
    check(jaina and jaina.kind == "BN_WHISPER" and jaina.name == "|Kq7|k" and jaina.unread == 1
        and rows.provider.list[3] == jaina and rows.rows[3].icon._texture == "Interface\\FriendsFrame\\Battlenet-Portrait"
        and rows.rows[3].count._text == "1" and talks.title._text == "Conversations (1)" and messages.provider.list[2].text == "are you coming?",
        "a Battle.net friend's whisper: their own conversation, first, its count waiting, the title counting all; the one chosen stays")
    click(rowOf(jaina))
    check(jaina.unread == 0 and talks.title._text == "Conversations" and texts(messages) == "Today | raid at 8?",
        "chosen, its messages are on show and read")
    write("yes")
    check(sent[#sent] == "BN 7 yes" and told == "BN_WHISPER |Kq7|k", "written to over Battle.net")
    function editBox:GetTellTarget() return self.tell end
    edit.focus, editBox.kind, editBox.tell = false, "WHISPER", "Thrall-Stub"
    open()
    W.Wait(0.1)
    check(not editBox:IsShown() and edit:HasFocus() and Talks.reading == thrall and not column:IsVisible(),
        "a reply opened meanwhile: the conversation with them is chosen, its own line has the cursor")
    edit.focus, editBox.kind, editBox.tell = false, "SAY", nil
    click(rowOf(jaina))
    -- A group: each one you join a conversation of its own, named by the others in it, listed while you are in it.
    local unitName = UnitName
    UnitName = function(unit)
        if unit == "party1" then return "Thrall-Stub" end
        if unit == "party2" then return "Jaina" end
        return unitName(unit)
    end
    GetNumSubgroupMembers = function() return grouped and 2 or 0 end
    grouped = true
    W.Fire("GROUP_JOINED", LE_PARTY_CATEGORY_HOME, "Party-1")
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(0.1)
    local party = Talks.by["G:Party-1"]
    check(party and party.kind == "PARTY" and rows.provider.list[5] == party and rows.rows[5].top._text == "Party: Thrall, Jaina"
        and #party.messages == 0, "a party joined: a conversation of its own, named by the others in it, to write in though nobody spoke yet")
    W.Fire("CHAT_MSG_PARTY", "pull now", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 8, THRALL)
    W.Wait(0.1)
    check(rows.provider.list[3] == party and rows.rows[3].bottom._text == "Thrall: pull now" and party.unread == 1,
        "the party's chat comes into its conversation, the speaker named in the list")
    click(rowOf(party))
    write("ok")
    check(sent[#sent] == "PARTY nil ok" and messages.provider.list[2].label == "Party", "written in the party's chat; a group's bubbles keep its chat's name")
    W.raiding = true
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(0.1)
    W.Fire("CHAT_MSG_RAID", "raid now", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 9, THRALL)
    write("on it")
    check(party.kind == "RAID" and Talks.by["G:Party-1"] == party and party.messages[#party.messages].text == "raid now"
        and sent[#sent] == "RAID nil on it" and rowOf(party).top._text:find("^Raid: Thrall"),
        "the party become a raid is the same conversation, a raid's from then on, Rexxar among its names")
    W.raiding = false
    grouped = false
    W.Fire("GROUP_LEFT", LE_PARTY_CATEGORY_HOME, "Party-1")
    W.Wait(0.1)
    check(not edit:IsEnabled() and party.ended and rows.provider.list[3] == party, "the group left, its conversation stays to read, not to write in")
    local hint
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and widget._parent == edit then hint = widget end
    end
    check(hint and hint._text == "You left this group.", "the line says why")
    grouped = true
    W.Fire("GROUP_JOINED", LE_PARTY_CATEGORY_HOME, "Party-2")
    W.Wait(0.1)
    local again = Talks.by["G:Party-2"]
    check(again and again ~= party and not again.ended and Talks.Writable(again) and not Talks.Writable(party),
        "the next group joined: a new conversation; the last one stays as it was")
    W.Fire("CHAT_MSG_PARTY", "hello again", "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 10, THRALL)
    check(again.messages[1].text == "hello again" and party.messages[#party.messages].text == "raid now",
        "the new group's chat goes into its own conversation only")
    grouped = false
    W.Fire("GROUP_LEFT", LE_PARTY_CATEGORY_HOME, "Party-2")
    UnitName, GetNumSubgroupMembers = unitName, nil
    W.Wait(0.1)
    -- A command goes to the game's line; in a lockdown nothing is sent.
    click(rowOf(jaina))
    local opened
    local openChat = ChatFrameUtil.OpenChat
    ChatFrameUtil.OpenChat = function(text) opened = text end
    local before = #sent
    write("/dance")
    check(opened == "/dance" and #sent == before and edit._text == "", "a command goes to the game's line, where Enter runs it")
    W.locked = true
    W.printed = {}
    write("still there?")
    check(#sent == before and edit._text == "still there?" and W.printed[1] and W.printed[1]:find("locked down"),
        "while chat is locked down nothing is sent: the words stay, and that is said")
    W.locked = false
    edit._text = ""
    -- Whisper: the game's line opens, to name whom; your first message to them chooses their conversation, whole,
    -- also while the chat is the one chosen.
    click(rows.rows[1])
    click(foot(talks, "Whisper"))
    check(opened == "/w ", "Whisper opens the game's line with /w")
    ChatFrameUtil.OpenChat = openChat
    W.Fire("CHAT_MSG_WHISPER_INFORM", "hey", "Rexxar-Stub", "", "", "", "", 0, 0, "", 0, 9, nil)
    local rexxar = Talks.by["W:Rexxar-Stub"]
    check(rexxar and rows.provider.list[3] == rexxar and texts(messages) == "Today | hey" and rows.rows[3].icon._texture:find("QuestionMark"),
        "a conversation you began is chosen; whose class is not known yet shows the game's question mark")
    check(messages:IsVisible() and edit:IsVisible() and not column:IsVisible() and Talks.reading == rexxar,
        "begun while the chat was chosen, it is chosen whole: its messages and its line beside the list, the chat out of sight")
    -- A right click: the game's own menu of that player, as the friends list opens it.
    local menu
    FriendsFrame_ShowDropdown = function(name, connected, _, kind) menu = name .. " " .. tostring(connected) .. " " .. kind end
    click(rowOf(thrall), "RightButton")
    check(menu == "Thrall-Stub true WHISPER", "a right click opens the game's menu of the player")
    menu = nil
    click(rows.rows[1], "RightButton")
    check(menu == nil, "the chat has none")
    -- An alias: in the list and above the conversation, the whole name and the note in the tooltip.
    W.Fire("CHAT_MSG_WHISPER", "hi there", "Droopy Fairwind", "", "", "", "", 0, 0, "", 0, 9, nil)
    W.Wait(0.1)
    local droopy = Talks.by["W:Droopy Fairwind"]
    click(rowOf(droopy))
    Core.People.Set("Droopy Fairwind", "alias", "Saneroki")
    Core.People.Set("Droopy Fairwind", "note", "my alt")
    local heading
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and widget._parent and widget._parent._parent == talks.body and widget._text
            and widget._text:find("Saneroki") then heading = widget end
    end
    check(droopy and rowOf(droopy).top._text == "Saneroki" and heading and heading._text:find("my alt", 1, true),
        "an alias the player gave stands in place of the name, the note beside it above the conversation")
    GameTooltip._lines = nil
    rowOf(droopy):GetScript("OnEnter")(rowOf(droopy))
    check(GameTooltip._lines and GameTooltip._lines[1] == "Droopy Fairwind" and GameTooltip._lines[2]:find("my alt"),
        "the mouse on it: their whole name and the note")
    Talks.Remove(droopy)
    Core.People.Set("Droopy Fairwind", "alias", nil)
    Core.People.Set("Droopy Fairwind", "note", nil)
    click(rowOf(rexxar))
    -- Hidden, nothing is read; shown again, the one chosen is.
    ns.Board.Hide()
    W.Fire("CHAT_MSG_WHISPER", "hello?", "Rexxar-Stub", "", "", "", "", 0, 0, "", 0, 10, nil)
    check(rexxar.unread == 1, "a message while the panel is hidden waits to be read")
    ns.Window.Reboard()
    check(talks:IsShown() and rexxar.unread == 0 and texts(messages) == "Today | hey | hello?" and not column:IsVisible(),
        "shown again, the one chosen is read, with what came, and still stands in the chat's place")
    -- The search: conversations by name or by their messages; the chat and the second chat find their own.
    local function found()
        local set = {}
        for _, element in ipairs(rows.provider.list) do set[element] = true end
        return set
    end
    ns.Window.Search("raid at")
    W.Wait(0.5) -- the lists are searched a moment after the typing
    local hits = found()
    check(hits[jaina] and not hits[rexxar] and not hits[thrall] and rows.provider.list[1].pinned == "chat"
        and rows.provider.list[2].view ~= nil, "the full window's search finds a conversation by its messages; the chats stay, to find in")
    click(rowOf(jaina))
    check(texts(messages) == "Today | raid at 8?", "and shows them")
    ns.Window.Search("thrall")
    W.Wait(0.5)
    hits = found()
    check(hits[party] and hits[again] and hits[thrall] and not hits[jaina] and not hits[rexxar],
        "by its name, or a speaker's in a group")
    ns.Window.Search("")
    W.Wait(0.5)
    local all = 2
    for _, talk in ipairs(Talks.list) do
        if #talk.messages > 0 then all = all + 1 end
    end
    check(#rows.provider.list == all, "emptied, all of them again")
    -- Each keeps its last messages; the one read keeps all until it is left.
    click(rowOf(rexxar))
    options.talkSize = 20
    for count = 1, 25 do W.Fire("CHAT_MSG_WHISPER", "line " .. count, "Thrall-Stub", "", "", "", "", 0, 0, "", 0, 10 + count, THRALL) end
    check(#thrall.messages == 20 and thrall.messages[20].text == "line 25" and thrall.unread == 25,
        "a conversation keeps its last messages as set")
    for count = 1, 25 do W.Fire("CHAT_MSG_WHISPER", "more " .. count, "Rexxar-Stub", "", "", "", "", 0, 0, "", 0, 40 + count, nil) end
    check(#rexxar.messages == 27 and #messages.provider.list == 28, "the one read keeps all of them while it is read")
    click(rowOf(thrall))
    check(#rexxar.messages == 20 and Talks.reading == thrall and thrall.unread == 0, "left, it keeps its last ones too")
    options.talkSize = 100
    -- Kept over a logout: a Battle.net friend's by their BattleTag, without their name of this session.
    local char = {}
    Talks.Save(char)
    local kept = {}
    for _, talk in ipairs(char.talks) do kept[talk.key] = talk end
    check(char.talksVersion == 2 and kept["B:Jaina#1234"] and kept["B:Jaina#1234"].messages[1].name == nil
        and kept["B:Jaina#1234"].messages[1].text == "raid at 8?" and kept["W:Thrall-Stub"].messages[1].name == "Thrall"
        and kept["G:Party-1"] and kept["G:Party-1"].members[1] == "Thrall" and kept["G:Party-1"].ended
        and kept["G:Party-2"] and #char.talks == 5,
        "saved for the character: every conversation with messages, a Battle.net friend's without the name of this session")
    local saved = Talks.list
    Talks.list, Talks.by = {}, {}
    Talks.Restore(char.talks, { [LE_PARTY_CATEGORY_HOME] = "G:Party-1" })
    check(#Talks.list == 5 and Talks.by["G:Party-1"].category == LE_PARTY_CATEGORY_HOME
        and Talks.by["G:Party-1"].members[2] == "Jaina" and Talks.current[LE_PARTY_CATEGORY_HOME] == nil
        and Talks.by["B:Jaina#1234"] and Talks.by["B:Jaina#1234"].messages[1].name == nil
        and Talks.Name(Talks.by["B:Jaina#1234"]) == "Jaina" and Talks.Account(Talks.by["B:Jaina#1234"]) == 7,
        "back at the login, a Battle.net friend found anew by their BattleTag")
    ;(function()
        local list, by, inform, out = Talks.list, Talks.by, ChatTypeInfo.WHISPER_INFORM, {}
        Talks.list = {
            { key = "W:Probe", kind = "WHISPER", with = "Probe", last = 2, unread = 0, messages = {
                { side = "right", text = "hi", r = inform.r, g = inform.g, b = inform.b, group = "WHISPER", time = "", stamp = 2 } } },
            { key = "G:Probe", kind = "PARTY", category = LE_PARTY_CATEGORY_HOME, members = {}, last = 1, unread = 0, messages = {
                { side = "left", text = "go", name = "Thrall", label = "Party", short = "P", group = "PARTY", r = 0.6, g = 0.7, b = 1,
                  time = "", stamp = 1 } } },
        }
        Talks.Save(out)
        local whisper, group = out.talks[1].messages[1], out.talks[2].messages[1]
        Talks.list, Talks.by = {}, {}
        Talks.Restore(out.talks)
        local back, again = Talks.by["W:Probe"].messages[1], Talks.by["G:Probe"].messages[1]
        Talks.list, Talks.by = list, by
        check(whisper.r == nil and group.short == nil and group.r == 0.6 and back.r == inform.r and back.g == inform.g
            and back.b == inform.b and again.short == "P" and again.r == 0.6,
            "a whisper's colour and a chat's name in short are not kept: they come back from its kind and its name")
        local most, few, count = Talks.SAVED, {}, 0
        Talks.SAVED = 3
        Talks.Save(few)
        Talks.SAVED = most
        for _, talk in ipairs(few.talks) do count = count + #talk.messages end
        check(count == 3 and few.talks[1].key == Talks.list[1].key,
            "over a logout so many messages of all conversations together at most, the newest conversations' first")
    end)()
    Talks.Restore({ { key = "W:X", kind = "WHISPER", messages = { { text = "no with" } } }, "junk", { key = "Y", kind = "NOPE" } })
    check(#Talks.list == 5, "a saved conversation of the wrong shape is left out")
    ;(function() -- a Battle.net friend no longer among your friends is looked for once, and again when they change
        Talks.Restore({ { key = "B:Gone#9", kind = "BN_WHISPER", with = "Gone#9", last = 3, messages = { { side = "left", text = "bye" } } } })
        local gone, info, number, walks = Talks.by["B:Gone#9"], C_BattleNet.GetFriendAccountInfo, BNGetNumFriends, 0
        local friends = (number())
        C_BattleNet.GetFriendAccountInfo = function(index) -- counts the looks; one friend more, past the stub's, once the count says so
            walks = walks + 1
            if index > friends then return { bnetAccountID = 10, accountName = "Gone", battleTag = "Gone#9", gameAccountInfo = {} } end
            return info(index)
        end
        check(gone and Talks.Name(gone) == "Gone" and walks == friends and gone.looked, "one gone is looked for among your friends once")
        Talks.Name(gone)
        check(walks == friends and Talks.Account(gone) == nil, "and not again at the next draw")
        BNGetNumFriends = function() return friends + 1, 2 end
        W.Fire("BN_FRIEND_LIST_SIZE_CHANGED")
        check(not gone.looked and Talks.Account(gone) == 10 and Talks.Name(gone) == "Gone" and walks > friends,
            "once the friends changed they are looked for again, and found")
        BNGetNumFriends, C_BattleNet.GetFriendAccountInfo = number, info
    end)()
    Talks.list, Talks.by = saved, {}
    for _, talk in ipairs(saved) do Talks.by[talk.key] = talk end
    -- Remove: the one chosen and its messages, once confirmed; the chat cannot be.
    click(rows.rows[3])
    local chosen, listed = rows.provider.list[3], #rows.provider.list
    click(foot(talks, "Remove"))
    W.popups[#W.popups].data.callback()
    check(Talks.by[chosen.key] == nil and #rows.provider.list == listed - 1 and rows.provider.list[3] ~= chosen
        and rows.provider.list[1].pinned == "chat" and column:IsVisible(),
        "Remove takes the conversation chosen away, once confirmed, and the chat is chosen")
    check(not foot(talks, "Remove"):IsEnabled(), "the chat cannot be removed")
    -- A layout with the chat as a window of its own: it stands there, not among the conversations.
    ns.store.board.tabs[1].tree = { split = "x", parts = { { key = "talks" }, { key = "chat" } }, shares = { 0.6, 0.4 } }
    ns.Window.Reboard()
    local own = ns.Board.panels.chat
    check(own and own:IsShown() and rows.provider.list[1].pinned == "view" and column:IsVisible() and box:IsVisible()
        and column._width == own._width and column._points[1][4] == own._points[1][4],
        "a layout with the chat's own window: the chat stands there, with its line, and is no row of the conversations")
    local plate = own.skin:GetFrameLevel()
    check(column:GetFrameLevel() > plate and column:GetFrameLevel() >= own:GetFrameLevel() and column:GetFrameLevel() > ns.Board.panels.talks.skin:GetFrameLevel()
        and Layout.INPUT_LEVEL > column:GetFrameLevel() + 5,
        "the chat lies on its panel's see-through plate, not under it, and the line to write in over its messages")
    click(rows.rows[1])
    check(column:IsVisible() and box:IsVisible(), "a chat view chosen beside the list, the chat stays in its own window")
    ns.store.board.tabs[1].tree = nil
    ns.Window.Reboard()
    check(rows.provider.list[1].pinned == "chat" and not own:IsShown(), "the first layout again: the chat is among the conversations")
    click(rows.rows[1])
    check(not Core.errors["Social: conversations"] and not Core.errors["Social: talks"] and not ns.off, "nothing went wrong in the conversations")
    grouped, W.raiding = wasGrouped, wasRaiding
    end)()
    ;(function() -- the guild window: the one the guild key opens, held at the top right, the friends list under it
    local game = Named("Frame", "CommunitiesFrame", UIParent)
    game._shown, game._width, game._height, game._strata = false, 814, 426, "MEDIUM"
    function game:GetName() return "CommunitiesFrame" end
    game:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    UIPanelWindows = { CommunitiesFrame = { area = "left" } }
    UnitAffectingCombat = function() return W.combat or false end
    local closed = 0
    HideUIPanel = function(frame) closed = closed + 1; frame:Hide() end
    local toggles, answer = 0, nil -- answer: another addon's window, answering the guild key instead of the game's
    ToggleGuildFrame = function()
        toggles = toggles + 1
        if answer then return answer:Show() end
        if game:IsShown() then game:Hide() else game:Show() end
    end
    local function anew()
        ns.Board.Hide()
        ns.Window.Reboard()
        W.Wait(0.5)
    end
    -- Where a window is held: in the guild panel's body at the scale that fits there (at most its own), at the body's
    -- top in its middle; offsets in its own units from UIParent's lower left (40, 500: the stand-in's corner).
    local HEAD, EDGE = Core.Board.HEAD, Layout.EDGE
    local function heldAt(frame)
        local panel = panels.guild
        local left, top = panel._points[1][4], -panel._points[1][5]
        local bodyW, bodyH = panel._width - 2 * EDGE, panel._height - HEAD - 2 * EDGE
        local scale = math.min(1, bodyW / frame._width, bodyH / frame._height)
        return scale, 40 + left + EDGE + (bodyW - frame._width * scale) / 2, 500 - (top + HEAD + EDGE)
    end
    local function held(frame)
        local scale, x, y = heldAt(frame)
        local own = frame._scale or 1
        return #frame._points == 1 and frame._points[1][2] == UIParent and frame._points[1][3] == "BOTTOMLEFT"
            and math.abs(own - scale) < 1e-9 and math.abs(frame._points[1][4] * own - x) < 1e-6
            and math.abs(frame._points[1][5] * own - y) < 1e-6
    end
    anew()
    local framed = { 814 + 2 * EDGE, 426 + HEAD + 2 * EDGE }
    local guild = Layout.Board(1920, tall, { friends = true, talks = true, guild = framed })
    check(toggles == 1 and game:IsShown() and panels.guild and panels.guild:IsShown() and held(game)
        and game._scale == 1 and game._level == 1 + Layout.GUILD_LEVEL,
        "the full screen opens the guild window by the guild key's work and holds it in its panel at the top right, its own size")
    check(panels.guild._points[1][4] == guild.guild[1] and panels.friends._points[1][5] == -guild.friends[2]
        and panels.friends._width == framed[1] and column._width == guild.chat[3] and panels.talks._width == guild.talks[3],
        "its panel as large as it is with its head, the friends list under it and as wide")
    game:ClearAllPoints()
    game:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    check(#game._points == 1 and game._points[1][3] == "BOTTOMLEFT", "placed anew by the game, it is put back in its room")
    game._width = 600
    game:GetScript("OnSizeChanged")(game)
    W.Wait(0.1)
    check(panels.friends._width == 600 + 2 * EDGE and held(game), "a new size makes its room anew")
    game._height = tall -- too high for the screen
    game:GetScript("OnSizeChanged")(game)
    W.Wait(0.1)
    check(game._scale < 1 and held(game), "made smaller where its panel lacks room: at the scale that fits its body")
    game._width, game._height = 814, 426
    game:Hide()
    W.Wait(0.1)
    check(game._points[1][3] == "TOPLEFT" and game._points[1][4] == 16 and panels.friends._points[1][5] == -Layout.PAD
        and panels.friends._width == Layout.FRIENDS_WIDTH and not panels.guild:IsShown() and toggles == 1,
        "closed by the player: its place back as it was, the friends list takes the room, it is not opened again")
    check(game._scale == 1 and game._level == 1 and game._strata == "MEDIUM", "and its scale and layer")
    game:Show()
    W.Wait(0.1)
    check(panels.guild:IsShown() and held(game) and toggles == 1, "opened again by you (the guild key), it is back in its panel")
    game:Hide()
    W.Wait(0.1)
    anew()
    check(toggles == 2 and game:IsShown() and game._points[1][3] == "BOTTOMLEFT", "the full screen anew opens it anew")
    ns.Board.Hide()
    check(not game:IsShown() and closed == 1 and game._points[1][4] == 16, "opened for the full screen, it is closed with it, as Esc closes it")
    game:Show()
    ns.Window.Reboard()
    W.Wait(0.5)
    check(toggles == 2 and game._points[1][3] == "BOTTOMLEFT", "one open already is taken as it is")
    ns.Board.Hide()
    check(game:IsShown() and game._points[1][4] == 16 and closed == 1, "and left open, at its place, when the full screen goes")
    game:Hide()
    -- Another addon's window answers the guild key instead: that one is held, its own size.
    answer = Named("Frame", "SomeGuildWindow", UIParent)
    answer._shown, answer._width, answer._height = false, 900, 600
    function answer:GetName() return "SomeGuildWindow" end
    UISpecialFrames[#UISpecialFrames + 1] = "SomeGuildWindow"
    anew()
    check(answer:IsShown() and not game:IsShown() and held(answer) and panels.friends._width == 900 + 2 * EDGE
        and ns.store.guildWindow == "SomeGuildWindow",
        "a window that answers the guild key instead is the one held, as large as it is, and known by its name")
    ns.Board.Hide()
    check(not answer:IsShown() and closed == 1, "closed with the full screen as Esc closes it, by itself")
    answer:Show()
    toggles = 0
    ns.Window.Reboard()
    W.Wait(0.5)
    check(toggles == 0 and answer._points[1][3] == "BOTTOMLEFT", "open already, it is known by its name and held")
    ns.Board.Hide()
    answer:Hide()
    guilded = false
    anew()
    check(toggles == 0 and not answer:IsShown() and panels.friends._width == Layout.FRIENDS_WIDTH, "out of a guild there is none")
    guilded = true
    ns.store.board.tabs[1].tree = { split = "x", parts = { { key = "talks" }, { key = "friends" } }, shares = { 0.7, 0.3 } }
    anew()
    check(toggles == 0 and not answer:IsShown(), "a layout without the guild window opens none")
    ns.store.board.tabs[1].tree = nil
    W.combat = true
    anew()
    check(toggles == 0, "in a fight the game opens no panel for an addon: none is asked for")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    W.Wait(0.5)
    check(toggles == 1 and answer:IsShown() and answer._points[1][3] == "BOTTOMLEFT", "after the fight it comes")
    do -- the full screen gone in a fight: the window opened for it is closed once the fight is over
        W.combat = true
        ns.Board.Hide()
        check(answer:IsShown(), "the full screen gone in a fight: the window it opened stays while the fight lasts")
        W.combat = false
        W.Fire("PLAYER_REGEN_ENABLED")
        W.Wait(0.1)
        check(not answer:IsShown(), "and is closed once it is over")
    end
    do -- the window one with protected parts (the game's guild window holds protected buttons): in a fight the game refuses
        -- our code every touch of it (the stand-in errors on one), so it is left as it is; given back and closed after the fight
        anew()
        answer._protected = true
        W.Combat(true)
        ns.Board.Hide()
        local untouched = answer:IsShown() and held(answer) and Core.Owed("Social: guild window")
        W.Combat(false)
        W.Wait(0.1)
        check(untouched and not answer:IsShown() and #answer._points == 0 and answer._scale == 1 and not Core.errors["Social: guild window"],
            "a window with protected parts: the full screen gone in a fight, it stays held as it is and its closing waits; given back and closed once the fight is over")
        answer._protected = nil
    end
    check(not Core.errors["Social: guild window"] and not ns.off, "nothing went wrong with the guild window")
    ToggleGuildFrame, UIPanelWindows = nil, nil
    ns.Window.Reboard()
    -- A guild window another module offers: the first layout gives it room while it wants some, as large as it wants,
    -- the friends list under it; out of a guild it wants none, and the friends list has that room too.
    local wants = { 900, 500 }
    Core.Board.Offer("Social", { key = "guild", title = "offered", want = function() return wants end })
    check(ns.Board.Has("guild") and panels.guild:IsShown() and panels.friends:IsShown()
        and panels.guild._width == 900 + 2 * Layout.EDGE and panels.friends._width == panels.guild._width,
        "the first layout gives an offered guild window its room, the friends list under it")
    wants = nil
    Core.Board.Told("Social")
    check(not ns.Board.Has("guild") and not panels.guild:IsShown() and panels.friends:IsShown()
        and panels.friends._width == Layout.FRIENDS_WIDTH and panels.friends._points[1][5] == -Core.Board.PAD,
        "out of a guild it has none: the friends list stands at the top right")
    Core.Board.Withdraw("Social", "guild")
    check(not Core.errors.board and not Core.errors["Social: board"] and not ns.off, "nothing went wrong with the offered window")
    end)()
    end
    ;(function() -- Core's board: the layouts behind tabs, the windows sharing the screen as they are arranged
        local Board, layouts, PAD = Core.Board, ns.Board.layouts, Core.Board.PAD
        -- A layout, plainly.
        local pair = { split = "x", parts = { { key = "a" }, { key = "b" } }, shares = { 0.5, 0.5 } }
        local rects, lines = Board.Lay(Board.Copy(pair), 12, 12, 1000, 600, 12)
        check(rects.a[3] + rects.b[3] + 12 == 1000 and rects.b[1] == 12 + rects.a[3] + 12 and rects.a[4] == 600
            and #lines == 1 and lines[1][3] == 12 + rects.a[3] and lines[1][5] == 12,
            "two windows side by side share the room, the gap between them a line to drag")
        local three = Board.Beside(Board.Copy(pair), "c", "b", "bottom")
        check(three.split == "x" and three.parts[2].split == "y" and three.parts[2].parts[1].key == "b"
            and three.parts[2].parts[2].key == "c", "dropped near the bottom of one, the two share its room, one over the other")
        local row = Board.Beside(Board.Copy(pair), "c", "b", "right")
        check(#row.parts == 3 and row.parts[3].key == "c" and math.abs(row.shares[2] - 0.25) < 1e-9,
            "beside one the way its split goes, it joins that split")
        local back = Board.Without(Board.Copy(three), "c")
        check(back.split == "x" and #back.parts == 2 and back.parts[2].key == "b", "taken off, its neighbour has its room again")
        check(Board.Without({ key = "a" }, "a") == nil, "the last one taken off: an empty layout")
        local swapped = Board.Swap(Board.Copy(pair), "a", "b")
        check(swapped.parts[1].key == "b" and swapped.parts[2].key == "a", "dropped in another's middle, the two swap places")
        local side = Board.Beside(Board.Copy(pair), "c", nil, "left")
        check(side.parts[1].key == "c" and math.abs(side.shares[1] - Board.STRIP) < 1e-9, "near a side of the screen: a strip along it")
        local moved = Board.Move(lines[1], 5000, 100, 300)
        check(moved == rects.b[3] - 300, "a line dragged far: the window on its other side keeps its least")
        local kept = { split = "x", parts = { { key = "a" }, { key = "b" }, { key = "c" } }, shares = { 0.5, 0.25, 0.25 } }
        local present = Board.Present(kept, function(key) return key ~= "b" end)
        check(#present.parts == 2 and math.abs(present.shares[1] - 2 / 3) < 1e-9,
            "a window with nothing to show now is left out, the others share its room")
        local _, gaps = Board.Lay(present, 0, 0, 900, 300, 0)
        Board.Move(gaps[1], -150, 0, 0)
        check(math.abs(kept.shares[1] - 0.375) < 1e-9 and math.abs(kept.shares[3] - 0.375) < 1e-9 and kept.shares[2] == 0.25,
            "a line moved there is written back to the kept layout, the one left out keeping its share")

        -- On the full screen: the tabs after the title, the dropdown Windows.
        local strip = layouts.strip
        local function tabs()
            local list = {}
            for index = 1, strip.tabs.taken do list[index] = strip.tabs[index] end
            return list
        end
        local function watcher()
            for index = #W.frames, 1, -1 do
                local widget = W.frames[index]
                if widget._parent == nil and widget._scripts.OnUpdate and widget:IsShown() then return widget end
            end
        end
        local function item(text)
            layouts.menu:GenerateMenu()
            for _, entry in ipairs(layouts.menu._items) do
                if entry.text == text then return entry end
            end
        end
        local listed = tabs()
        check(strip:IsShown() and #listed == 2 and listed[1].Text._text == "Default" and listed[2].Text._text == "+"
            and layouts.menu:IsShown() and item("Conversations") and item("Conversations").checked() and item("Guild"),
            "full, a tab for each layout after the title, + to make one; the dropdown Windows ticks those in the layout")
        listed[2]._scripts.OnClick(listed[2], "LeftButton")
        listed = tabs()
        check(#listed == 3 and listed[2].Text._text == "Layout 2" and ns.store.board.chosen == 2 and layouts.hint:IsShown()
            and not panels.talks:IsShown() and not panels.friends:IsShown() and not column:IsShown(),
            "+ makes an empty layout and chooses it: no window, a word on how to add one, no chat")
        item("Friends List").fn()
        check(panels.friends:IsShown() and panels.friends._width == 1920 - 2 * PAD and not layouts.hint:IsShown()
            and item("Friends List").checked(), "ticked in the dropdown, a window comes into the layout: alone, it has the whole")
        item("Conversations").fn()
        local friendsWidth = panels.friends._width
        check(panels.talks:IsShown() and panels.talks._points[1][4] > panels.friends._points[1][4]
            and friendsWidth + panels.talks._width + 3 * PAD == 1920 and column:IsShown(),
            "the next shares the room of the largest there, side by side; the chat stands in the conversations again")
        -- The line between them, dragged: only the line follows; let go, the two share their room anew.
        local line = layouts.strips[1]
        local mouseX, mouseY = W.cursorX, W.cursorY
        W.cursorX, W.cursorY = 40 + line.of[3] + PAD / 2 + 100, 300
        line._scripts.OnEnter(line)
        check(W.cursorArt == "UI_RESIZE_CURSOR", "the mouse on the gap between two: the game's cursor for sizing")
        line._scripts.OnMouseDown(line, "LeftButton")
        local hand = watcher()
        hand._scripts.OnUpdate(hand, 0.01)
        check(panels.friends._width == friendsWidth, "held, only the line follows")
        line._scripts.OnMouseUp(line, "LeftButton")
        check(panels.friends._width == friendsWidth + 100 and panels.friends._width + panels.talks._width + 3 * PAD == 1920,
            "let go, the one at its left is that much wider, the other that much narrower")
        line._scripts.OnLeave(line)
        -- A head dragged onto the left side of the other: there it goes.
        local talks = panels.talks
        talks.head._scripts.OnDragStart(talks.head)
        W.cursorX, W.cursorY = 40 + panels.friends._points[1][4] + 10, 300
        hand = watcher()
        hand._scripts.OnUpdate(hand, 0.01)
        check(talks._alpha == 0.6, "held by its head, the window is lifted, and a shape shows where it would go")
        talks.head._scripts.OnDragStop(talks.head)
        check(talks._alpha == 1 and talks._points[1][4] < panels.friends._points[1][4], "let go at the left side of the other, it stands there")
        -- Its X: off the layout; the other has the whole.
        talks.close._scripts.OnClick(talks.close)
        check(not talks:IsShown() and panels.friends._width == 1920 - 2 * PAD and not item("Conversations").checked(),
            "its X takes it off the layout, the other takes its room")
        W.cursorX, W.cursorY = mouseX, mouseY
        item("Second chat").fn()
        local own = panels["view:1"]
        check(own and own:IsShown() and own.list and own.list.shown and own.filter and own.title._text == "Second chat"
            and own._points[1][4] > panels.friends._points[1][4],
            "a chat view in the dropdown too: a window of its own beside the largest, its list in it, its chats on its head")
        -- A right click on a tab: rename it, delete it.
        listed = tabs()
        listed[2]._scripts.OnClick(listed[2], "RightButton")
        local menu = W.menus[#W.menus]
        local function entry(text)
            for _, each in ipairs(menu) do
                if each.text == text then return each end
            end
        end
        entry("Rename").fn()
        W.popups[#W.popups].data.callback("Raid night")
        check(tabs()[2].Text._text == "Raid night" and ns.store.board.tabs[2].name == "Raid night", "renamed, the tab says so")
        listed = tabs()
        listed[2]._scripts.OnClick(listed[2], "RightButton")
        menu = W.menus[#W.menus]
        entry("Delete").fn()
        W.popups[#W.popups].data.callback()
        check(#tabs() == 2 and ns.store.board.chosen == 1 and panels.talks:IsShown() and panels.friends:IsShown(),
            "deleted once confirmed, and the first layout is chosen")
        listed = tabs()
        listed[1]._scripts.OnClick(listed[1], "RightButton")
        menu = W.menus[#W.menus]
        check(entry("Reset") and not entry("Delete"), "the first can be reset; the only one left is never deleted")
        listed[2]._scripts.OnClick(listed[2], "LeftButton") -- the +
        check(#tabs() == 3 and ns.store.board.chosen == 2, "+ makes another layout")
        listed = tabs()
        listed[1]._scripts.OnClick(listed[1], "RightButton")
        menu = W.menus[#W.menus]
        entry("Delete").fn()
        W.popups[#W.popups].data.callback()
        check(#tabs() == 2 and #ns.store.board.tabs == 1 and ns.store.board.chosen == 1 and ns.store.board.tabs[1].tree == false,
            "with another left the first can be deleted too: the other is the first then")
        ns.store.board.tabs[1].tree = nil -- the first layout as the module has it again (its tab's Reset)
        ns.store.board.tabs[1].name = nil
        ns.Window.Reboard()
        check(not Core.errors["board"] and not Core.errors["Social"] and not ns.off, "(nothing went wrong on the board)")
    end)()
    local shown = #box.provider.list
    coreBar.find:GetScript("OnMouseDown")(coreBar.find)
    coreBar.find:GetScript("OnClick")(coreBar.find)
    local search = coreBar.box
    search._text = "zzqqxx"
    search:GetScript("OnTextChanged")(search)
    W.Wait(0.5) -- the lists are searched a moment after the typing
    check(search:IsShown() and #box.provider.list == 0, "a search for letters no message has leaves none on show")
    search._text = ns.Log.list[#ns.Log.list].name or "number"
    search:GetScript("OnTextChanged")(search)
    W.Wait(0.5)
    check(#box.provider.list > 0 and #box.provider.list <= shown, "a search for a speaker's name shows their messages")
    search._text = "theramore"
    search:GetScript("OnTextChanged")(search)
    W.Wait(0.5)
    check(#friends.provider.list == 1 and friends.provider.list[1].name == "Jaina",
        "the search goes to the panels too: friends by where they are")
    search:GetScript("OnEscapePressed")(search)
    search:GetScript("OnTextChanged")(search) -- the game tells of the box emptied (the stand-in does not)
    W.Wait(0.5)
    check(not search:IsShown() and #box.provider.list == shown and #friends.provider.list == 6,
        "closed, all of them are on show again")
    local coreButtons
    for _, widget in ipairs(W.frames) do
        if widget._parent == coreBar and rawget(widget, "list") then coreButtons = widget end
    end
    check(coreButtons and #coreButtons.list == 5, "its buttons: close, full screen and back, the game's chat, options, help")
    local tab
    FriendsFrame = CreateFrame("Frame", "FriendsFrame", UIParent)
    FriendsFrame:Hide()
    ToggleFriendsFrame, FRIEND_TAB_FRIENDS = function(which) tab = which FriendsFrame:Show() end, 1
    classic._items[3].fn()
    check(tab == 1 and window._width == Layout.WIDTH and window:IsShown() and not classic:IsShown(),
        "Friends list: the window goes back to its zone, and the game's friends list opens")
    check(listTop() == -Layout.EDGE and not panels.friends:IsShown() and not panels.talks:IsShown() and column:IsShown()
        and box:IsShown(), "back, the panels are gone and the chat starts at the window's top again")
    do
    local friendsButton = Core.Classic.Button(FriendsFrame)
    check(friendsButton and friendsButton:IsShown() and friendsButton._parent == FriendsFrame,
        "the game's friends list has the button Sane UI")
    W.Wait(1)
    friendsButton:GetScript("OnClick")(friendsButton)
    local socialEdge
    for _, made in ipairs(Core.Window.All()) do if made.frame == window then socialEdge = made.edge end end
    check(not FriendsFrame:IsShown() and window:IsShown() and socialEdge and socialEdge.full,
        "pressed, the game's friends list goes and ours fills the screen")
    socialEdge:Fill(false)
    end
    W.Wait(1)
    strip:GetScript("OnEnter")(strip)
    W.printed = {}
    classic._items[2].fn()
    check(not window:IsShown() and options.window == false and native:IsShown() and W.printed[1]:find("/sane social"),
        "Chat: our window is put away (the switch Chat window off), the game's chat is back, and how to bring ours again is said")
    local sane
    for _, widget in ipairs(W.frames) do
        if widget._parent == nativeStrip and widget._kind == "Button" and widget ~= nativeMenu then sane = widget end
    end
    check(sane and sane:IsShown() and sane._points[1][2] == nativeMenu and sane._points[1][3] == "TOP",
        "the game's chat has a button Sane UI, just above its chat menu button")
    sane:GetScript("OnClick")(sane)
    check(window:IsShown() and options.window == true and not sane:IsShown(),
        "it brings our window back (the switch Chat window on), and goes while ours is there")
    SlashCmdList.SANEUI("social")
    check(not window:IsShown() and sane:IsShown(), "/sane social puts ours away again, and the button is back")
    SlashCmdList.SANEUI("social")
    check(window:IsShown() and options.window == true and window._width == Layout.WIDTH, "/sane social brings it back, in its zone")
    local file = assert(io.open(root .. "/src/Social/Bindings.xml", "r"))
    local xml = file:read("*a")
    file:close()
    local keys = 0
    for name, category, body in xml:gmatch('<Binding name="([%w_]+)" category="([%w_]+)">(.-)</Binding>') do
        keys = keys + 1
        check(category == "BINDING_HEADER_SANEUI" and type(_G[category]) == "string" and type(_G["BINDING_NAME_" .. name]) == "string",
            "Social's key is in Sane UI's section of the game's key bindings, named in the game's way")
        local press = assert(loadstring(body))
        press()
        check(not window:IsShown() and options.window == false and native:IsShown(), "pressed, it puts our window away as /sane social does")
        press()
        check(window:IsShown() and options.window == true and window._width == Layout.WIDTH, "pressed again, it is back")
    end
    check(keys == 1, "Social has one key")
    local kept = Core.Store("Social")
    W.Wait(1)
    strip:GetScript("OnEnter")(strip)
    SlashCmdList.SANEUI("social")
    check(not window:IsShown() and Core.general.places["Social:place"].full == true and Core.general.places["Social:place"].native == true and options.window == false,
        "put away while it fills the screen: the switch and Core's window say the same, the game's chat; ours was left full")
    SlashCmdList.SANEUI("social")
    check(window:IsShown() and window._width == 1920 and Core.general.places["Social:place"].native == nil, "brought back, it fills the screen again, as it was left")
    W.Wait(1)
    strip:GetScript("OnEnter")(strip)
    check(window._width == Layout.WIDTH, "(back in its zone)")
    W.Wait(1)
    strip:GetScript("OnEnter")(strip)
    for _, widget in ipairs(W.frames) do
        if widget._parent == window and rawget(widget, "box") then coreBar = widget end
    end
    local toggleButton, closeButton
    for _, widget in ipairs(W.frames) do
        if widget._parent == coreBar and rawget(widget, "list") then toggleButton, closeButton = widget.list[3], widget.list[1] end
    end
    W.printed = {}
    toggleButton:GetScript("OnClick")(toggleButton)
    check(not window:IsShown() and options.window == false and W.printed[1]:find("/sane social") and Core.general.places["Social:place"].native == true,
        "full, its button for the game's own window puts ours away and the game's chat is back: the switch and Core's window agree")
    SlashCmdList.SANEUI("social")
    W.Wait(1)
    strip:GetScript("OnEnter")(strip)
    closeButton:GetScript("OnClick")(closeButton)
    check(not window:IsShown() and options.window == false, "its close button puts it away the same way")
    SlashCmdList.SANEUI("social")
    W.Wait(1)
    strip:GetScript("OnEnter")(strip)
    options.animations = true
    expand.setting:SetValue(false)
    check(window._width == Layout.WIDTH and not strip:IsShown(), "switched off while it fills the screen, it is back at its size, and the edge does nothing")
    expand.setting:SetValue(true)
    check(strip:IsShown() and not Core.errors["full screen"] and not ns.off, "nothing went wrong on the way")
end

-- A message that cannot be read is left out ----------------------------------------------------------
W.printed = {}
local before = Log.list[#Log.list]
say("hello", THRALL, "Broken")
check(not ns.off and window:IsShown() and Log.list[#Log.list] == before and Core.errors["Social: a chat message could not be read"]
    and #W.printed == 1, "a message that cannot be read is left out and noted; the window goes on")
say("hello", THRALL, "Broken")
say("fine")
check(#W.printed == 1 and Log.list[#Log.list].text == "fine", "it is said once, and the next message is read as always")

-- A failure: the window goes -------------------------------------------------------------------------
W.printed = {}
open()
check(editBox._points[1][2] == column and editBox.wraps, "(the line to write in is in our window)")
local multiLine = editBox.SetMultiLine
editBox.SetMultiLine = function(self, on)
    if not on then error("and this too") end
    multiLine(self, on)
end
methods.GetStringHeight = function() error("the game changed this") end
say("breaks")
check(ns.off and not window:IsShown(), "an error closes the window")
check(native._parent == UIParent and dock._parent == UIParent, "and gives the game's chat back")
check(editBox._points[1][2] == native and editBox._points[2][1] == "RIGHT", "the edit box is where the game had it first, though giving back its look failed")
check(Core.errors["Social: giving back"] and Core.errors["Social: giving back"].text:find("and this too"), "(that failure is noted)")
check(next(EventRegistry.callbacks["ChatFrame.OnEditBoxShow"]) == nil and next(EventRegistry.callbacks["ChatFrame.OnEditBoxFocusGained"]) == nil,
    "and the module no longer listens to the game's edit boxes")
local kept = Core.errors["Social: the chat window is closed"]
check(kept and kept.text:find("the game changed this") and #W.printed == 1, "it is noted and said once")
local count = #Log.list
say("after")
check(#Log.list == count and Log.list[count].text == "breaks" and #W.printed == 1, "after that the module does nothing until the next /reload")
SlashCmdList.SANEUI("chat")
check(not window:IsShown() and #W.printed == 2, "and /sane chat, its word from before it was Social, says so too")

-- The game's own chat channels, the same on every character ----------------------------------------
-- Apart from the window: closed by now (above), and the channels still follow the wishes.
local joined, calls, zone = { General = 1, Trade = 2 }, {}, "Elwynn Forest"
local offer = { "General", "LocalDefense", "LookingForGroup" } -- what the game offers here: no city's channels
GetChannelName = function(channel) return joined[channel] or 0 end
Joining = function(channel) calls[#calls + 1] = "Join " .. channel; joined[channel] = 9 end
LeaveChannelByName = function(channel) calls[#calls + 1] = "Leave " .. channel; joined[channel] = nil end
GetRealZoneText = function() return zone end
EnumerateServerChannels = function() return unpack(offer) end
GetChannelList = function()
    local list = {}
    for name, number in pairs(joined) do list[#list + 1] = { number, name } end
    table.sort(list, function(a, b) return a[1] < b[1] end)
    local flat = {}
    for _, channel in ipairs(list) do flat[#flat + 1], flat[#flat + 2], flat[#flat + 3] = channel[1], channel[2], false end
    return unpack(flat)
end
C_ChatInfo.GetChannelInfoFromIdentifier = function(name) return { channelType = name == "Raiders" and 3 or 1 } end
local function Called(what)
    for _, call in ipairs(calls) do if call == what then return true end end
    return false
end

-- A first load: the public channels are left once, each the first time the character is seen in it. Whatever is
-- joined afterwards stays, on that login, after a /reload and on any other.
local char = Core.Character(ns.name)
check(type(char.public) == "table" and next(char.public) == nil, "a character with nothing saved starts with empty notes")
ns.Join.Wish("LookingForGroup", nil)
check(#calls == 0, "before the first look nothing is left: the game is still joining its own")
joined.Raiders = 3 -- a channel of the player's own: no public one
W.Fire("PLAYER_ENTERING_WORLD", true, false)
W.Wait(9)
check(Called("Leave General") and Called("Leave Trade") and #calls == 2, "the first look leaves every public channel, not one of the player's own")
check(joined.Raiders == 3 and char.public.general and char.public.trade and not char.public.raiders, "and notes those it left")
ns.Join.Settle()
check(#calls == 2, "looked at again, nothing more to do")

JoinPermanentChannel("General", nil, 1, 1) -- the player's /join, an hour later on that login
check(char.public.general and joined.General == 9, "the player joins one: that is the game's own join")
calls = {}
W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_JOINED")
W.Wait(2.5)
check(#calls == 0 and joined.General == 9, "and it stays, though the game tells of a channel joined")
joined.Services, joined.TradeLocal = 5, 6 -- a city: the game joins these by itself, late
W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_CHANGED")
W.Wait(2.5)
check(Called("Leave Services") and Called("Leave TradeLocal") and #calls == 2 and joined.General == 9,
    "a channel the game joins late, or by zone, is left the first time it is seen, also one of only one of the games")

-- Who joined what, by the game's other names for a channel and before it was ever seen
local shortcuts = { [7] = "Services" }
local shortcutWas = C_ChatInfo.GetChannelShortcut
C_ChatInfo.GetChannelShortcut = function(number) return shortcuts[number] end
char.public.services = nil
joined["Trade (Services)"], calls = 7, {}
JoinPermanentChannel("LocalDefense", nil, 1, 1) -- never seen yet, and joined by the player
joined.LocalDefense = 8
W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_JOINED")
W.Wait(2.5)
check(calls[1] == "Join LocalDefense" and joined.LocalDefense == 8, "a channel the player joins before the game ever put the character in it stays")
check(Called("Leave Trade (Services)") and char.public.services, "a channel is noted by the game's own word for it, also where the game shows another")
JoinPermanentChannel("Trade (Services)", nil, 1, 1)
joined["Trade (Services)"], char.public.services, calls = 7, nil, {}
W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_JOINED")
W.Wait(2.5)
check(#calls == 0 and joined["Trade (Services)"] == 7, "joined by the name the game shows, it counts the same")
C_ChatInfo.GetChannelShortcut, joined["Trade (Services)"], char.public.services = shortcutWas, nil, true

-- A channel that is switched off where the character is: not left yet, so that a leave that does not hold cannot use up its one time
local listWas = GetChannelList
GetChannelList = function() return 9, "Outside", true end
ns.Join.Settle()
check(not char.public.outside, "one the game lists as switched off here waits")
GetChannelList = function() return 9, "Outside", false end
joined.Outside, calls = 9, {}
ns.Join.Settle()
check(calls[1] == "Leave Outside" and char.public.outside, "and is left when the game switches it on")
GetChannelList = listWas
joined.Outside = nil

-- A /reload: the notes are what the character saved, so nothing joined before it is left, and what still comes is
ns.Join.Notes()
check(Core.Character(ns.name).public == char.public and char.public.general, "after a /reload the notes are still there, not made anew")
calls = {}
W.Fire("PLAYER_ENTERING_WORLD", true, false)
W.Wait(9)
check(#calls == 0 and joined.General == 9 and joined.LocalDefense == 8, "so what the player joined stays")
joined.WorldDefense = 10
W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_CHANGED")
W.Wait(2.5)
check(calls[1] == "Leave WorldDefense", "and one the game joins only now is still left")

-- A second character on the same profile: notes of its own, and it starts left too. A wish of the profile speaks first.
local firstKey = Core.charKey
Core.charKey, joined, calls = "Player-70-0000BEEF", { General = 1, LocalDefense = 2, Trade = 3 }, {}
options.presence.Trade = true
ns.Join.Notes()
local second = Core.Character(ns.name)
check(second ~= char and type(second.public) == "table" and next(second.public) == nil, "a second character has notes of its own, though the profile is there")
ns.Join.Settle()
check(Called("Leave General") and Called("Leave LocalDefense") and not Called("Leave Trade") and joined.Trade == 3,
    "it leaves the public channels as well; one the profile wishes always in it stays")
-- A wish kept by the channel's shortcut counts where the game lists the longer name
options.presence.Services = true
joined["Trade (Services)"], calls = 4, {}
local shortcutOf = C_ChatInfo.GetChannelShortcut
C_ChatInfo.GetChannelShortcut = function(number) return number == 4 and "Services" or nil end
ns.Join.Settle()
check(#calls == 0 and second.public.services, "a wish by the shortcut is a wish for the channel")
-- The standard profiles' wish on Retail's Newcomer Chat: left at once, and again when the game puts the character back.
options.presence["Newcomer Chat"] = false
joined["Newcomer Chat"], calls = 5, {}
ns.Join.Settle()
check(calls[1] == "Leave Newcomer Chat" and joined["Newcomer Chat"] == nil, "Newcomer Chat is left")
joined["Newcomer Chat"], calls = 6, {}
ns.Join.Settle()
check(calls[1] == "Leave Newcomer Chat", "and again when the game puts the character back in it")
options.presence["Newcomer Chat"] = nil
C_ChatInfo.GetChannelShortcut, options.presence.Services, joined["Trade (Services)"] = shortcutOf, nil, nil
options.presence.Trade = false
joined.Trade, calls = 3, {}
second.public.trade = nil
ns.Join.Settle()
check(#calls == 1 and calls[1] == "Leave Trade", "one wished never in it is left by the wish, once")
options.presence.Trade = nil

-- A character saved before these notes: nothing is left
Core.charKey, joined, calls = "Player-70-0000CAFE", { General = 1 }, {}
Core.Store(ns.name).chars[Core.charKey] = { history = {} }
ns.Join.Notes()
ns.Join.Settle()
check(Core.Character(ns.name).public == nil and #calls == 0 and joined.General == 1, "a character with something saved already is no first load: it stays in what it is in")

Core.charKey, joined, calls = firstKey, { General = 1, Trade = 2 }, {}
ns.Join.Notes()
check(type(options.presence) == "table" and next(options.presence) == nil and not control("General"),
    "at first the game decides for every channel; no switch for them on the page")
W.Fire("PLAYER_ENTERING_WORLD", true, false)
W.Wait(9)
check(#calls == 0, "with no wish, the game's channels stay as they are: each was left once, and is the character's own now")
joined.Raiders = 3 -- a channel of the player's own: not the game's
local names = {}
for index, channel in ipairs(ns.Join.List()) do names[index] = channel.name end
check(table.concat(names, ", ") == "General, Trade, LocalDefense, LookingForGroup",
    "the game's channels: those the character is in by their number, then those on offer here; not one of its own")
ns.Menu.Toggle(W.NewWidget("Frame"), nil)
local menu, entries = W.menus[#W.menus], {}
local titled
for _, item in ipairs(menu) do
    if item.title == "Joined on every character" then titled = true elseif titled and item.text then entries[item.text] = item end
end
local general = entries.General
check(titled and general and general.checked(general.data) and #general.inits == 0 and not general.sub
    and not entries.LookingForGroup.checked(entries.LookingForGroup.data),
    "last in the list on the chat's name, each of the game's channels has a tick of its own, on while the character is in it")
check(menu.grid[2] == 3 and #menu % 3 == 0 and menu[2 * #menu / 3 + 1].title == "Joined on every character",
    "the game's channels stand in a third column")
ns.Menu.Close()
general.fn(general.data)
check(calls[1] == "Leave General" and options.presence.General == false and not general.checked(general.data),
    "unticked: left as soon as it is clicked")
entries.LookingForGroup.fn(entries.LookingForGroup.data)
check(calls[2] == "Join LookingForGroup" and options.presence.LookingForGroup == true and entries.LookingForGroup.checked(entries.LookingForGroup.data),
    "ticked: joined when the character is not")
LeaveChannelByName("LookingForGroup")
ns.Join.Settle()
check(#calls == 3, "a join is asked for once a zone: one the game refuses is not asked for again and again")
ns.Join.Wish("Trade", false)
check(calls[4] == "Leave Trade", "a city's channel is left as any other")
ns.Join.Wish("Trade", true)
ns.Join.Wish("Services", true)
check(#calls == 4 and not Called("Join Trade"), "but joined only where the game offers it")
names = {}
for index, channel in ipairs(ns.Join.List()) do names[index] = channel.name end
check(names[#names - 1] == "Services" and names[#names] == "Trade", "a channel with a wish is listed though the game does not offer it here")
zone, offer = "Stormwind City", { "General", "Trade", "LocalDefense", "LookingForGroup", "Services" }
W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_CHANGED")
W.Wait(2.5)
check(Called("Join Trade") and Called("Join Services") and calls[5] and #calls == 7,
    "in a city, told by the game of its channels, those it offers there are joined, and in a new zone the refused one is asked for again")
general.fn(general.data)
check(options.presence.General == true and Called("Join General"), "ticked again, joined again")
options.presence.General = false
joined.General = 9 -- the game put the character in it again
W.locked, calls = true, {}
W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_JOINED")
W.Wait(2.5)
check(#calls == 0, "while chat is locked down it waits")
W.locked = false
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 5, 0)
W.Wait(2.5)
check(calls[1] == "Leave General", "and leaves it once the lockdown is over")
joined.LocalDefense, calls = 4, {}
options.presence.LocalDefense = false
Core.described[ns.name].changed("presence")
check(calls[1] == "Leave LocalDefense" and not Core.errors["Social: channels"], "a profile with other wishes is followed at once")
;(function() -- a leave the game refuses: it writes a line of its own each time
    ns.Menu.Toggle(W.NewWidget("Frame"), nil)
    local list = W.menus[#W.menus]
    local refreshed = list.refreshed or 0
    options.presence["Newcomer Chat"] = false
    joined["Newcomer Chat"], calls = 7, {}
    ns.Join.Settle()
    check(calls[1] == "Leave Newcomer Chat", "a channel wished away is asked to be left")
    joined["Newcomer Chat"] = 7 -- the game kept the character in it
    W.Fire("CHAT_MSG_CHANNEL_LEAVE_PREVENTED", "Newcomer Chat")
    check(ns.Join.In("Newcomer Chat") and (list.refreshed or 0) == refreshed + 1, "refused, its tick is on again at once: the character is still in it")
    calls = {}
    ns.Join.Flip("Services")
    ns.Join.Flip("Services")
    ns.Join.Settle()
    check(not Called("Leave Newcomer Chat"), "and a click on another channel does not ask for it again")
    ns.Join.Flip("Newcomer Chat")
    check(Called("Leave Newcomer Chat") and options.presence["Newcomer Chat"] == false, "a click on its own tick does: the player asked")
    ns.Menu.Close()
    options.presence["Newcomer Chat"], options.presence.Services, joined["Newcomer Chat"] = nil, nil, nil
end)()

-- The game's friends list from the dropdown Classic windows, in a fight and out of one
local toggled, fight = 0, W.combat
rawset(_G, "ToggleFriendsFrame", function() toggled = toggled + 1 end)
W.combat = true
ns.CLASSIC[2].show()
check(toggled == 0, "in a fight the game's friends list is not asked for: the game refuses it to an addon then")
W.combat = false
ns.CLASSIC[2].show()
check(toggled == 1 and not Core.errors["Social: friends list"], "out of one it opens as its key opens it")
rawset(_G, "ToggleFriendsFrame", nil)
W.combat = fight

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Social: all %d checks passed.\n"):format(passed))
