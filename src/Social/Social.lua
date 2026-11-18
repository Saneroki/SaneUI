local ADDON, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social
--  The module's own table (ns in all its files), the game's chat events and
--  the command.
--
--  An addon of its own (SaneUI_Social): it needs Core and nothing else, and is
--  switched on and off in the game's addon list.
--
--  A chat window in the style of a messenger: every message in a bubble, yours
--  on the right, everybody else's on the left. While it is open the game's edit
--  box is the line you write in at the bottom of our window (Input.lua), and the
--  game's own chat stands next to it, or is out of sight if set so (Native.lua).
--
--      game event -> Log.Read (what it says) -> Log.Add (the list)
--                 -> Log.added -> Window (shows it, if it is open)
--      any other line the game's chat writes (the system's, loot, a ping, an addon's print)
--                 -> Log.Line -> Log.Add
--
--  Every step that touches the game runs through ns.Guarded (Core): an error
--  stands the module down, and GiveBack gives the game its chat back.
--
--  Apart from the window, and whether it is open or not: the game's own chat
--  channels kept the same on every character, as wished in the list on the
--  chat's name (Join.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Social", ns)

-- The module's texts, in one place.
ns.TEXT = {
    title = "Social",
    to = "To %s",       -- a whisper you sent: "To Thrall"
    writeIn = "Write in",
    showing = "Show in the window",
    -- The smiley beside the line you write in, and its list (Picker.lua).
    picker = "Icons and emotes",
    marks = "Icons",
    noMarks = "No icons in the game's public channels",
    emotes = "Emotes",
    noEmotes = "No emotes while chat is locked down",
    -- Kinds of chat the game has no word of its own for, or may not have. The four with a switch of
    -- their own (ns.SHOWS) are named so on the options page too: the same words in both places.
    kinds = { SAY = "Say", YELL = "Yell", EMOTE = "Emote", WHISPER = "Whisper", PARTY = "Party", RAID = "Raid",
              INSTANCE_CHAT = "Instance", GUILD = "Guild", OFFICER = "Officer", SYSTEM = "System messages",
              MONSTER = "Creature messages", PRINT = "Addon messages", PING = "Pings",
              REWARDS = "Loot, money and experience", BATTLEGROUND = "Battlegrounds", PET_BATTLE = "Pet battles",
              CHANNEL_NOTICES = "Channel joins and leaves" },
    stopped = "the chat window is closed until the next /reload; the game's own chat is back.",
    reset = "the chat window is back at its first place and size.",
    about = "shows or hides the chat window (/sane social reset: first place and size)",
    binding = "Show or hide the chat window", -- its key, in the game's key bindings under SaneUI (Bindings.xml)
    setup = "Set up step by step",
    setupTip = "A window that walks you through Social, a page at a time: the hot corner (not at all, a click, the mouse), a key for the full screen, and which chat windows you want. Also /sane setup social.",
    bindingFull = "Social's full screen (and back)", -- the full screen's key, beside it
    unread = "a chat message could not be read",
    solid = "Solid colour", -- what the bubbles stand on, the first of the choices (Core.Skin.Choices)
    -- The dropdown Classic windows while the window fills the screen: the game's own windows it stands for.
    classicChat = Core.Word("CHAT", "Chat"),
    classicFriends = "Friends list",
    classicFinder = "Group finder",
    friendsInFight = "in a fight the game's friends list opens only by its own key.",
    finderInFight = "in a fight the game's group finder opens only by its own key.",
    -- The full screen's chat views (Feed.lua): the first one's name, a new one's, the list of chats on the line with
    -- a view's name, its button and its right click.
    feed = "Second chat",
    newView = "Chat view %d",
    newViewButton = "New chat view",
    viewRename = "Name of the chat view:",
    viewRemove = "Remove the chat view %s?",
    rename = "Rename",
    feedFilter = "Chats",
    -- A chat view on the screen as a chat window of its own (ChatWindows.lua): the column of the chat's list, a new
    -- one's name, the line on a view's right click, its button's tip, what it says while it shows nothing.
    windows = "Chat windows",
    newWindow = "Chat window %d",
    onScreen = "Its own window on the screen",
    windowRename = "Name of the chat window:",
    windowTip = "Click for its list: rename or close this window, and tick what it shows. Move and size it in Edit Mode. You write in the chat's line (Enter).",
    windowPick = "Nothing to show yet: click the button in the lower left corner and tick what this window shows.",
    windowQuiet = "Nothing said here yet.",
    friends = Core.Word("FRIENDS", "Friends"),
    online = "%d / %d online",
    noFriends = "No friends yet. Add Friend adds one.",
    noFriendsFound = "No friend found.",
    noneFound = "Nobody found.",
    status = Core.Word("STATUS", "Status"),
    kind = "Kind",
    bnetFriends = "Battle.net friends",
    characterFriends = "Characters",
    requests = "Requests",
    requestsCount = "Requests (%d)",
    noRequests = "No friend requests.",
    noRequestsFound = "No request found.",
    sent = "Sent %s ago",
    addHint = "BattleTag, e-mail or character",
    addTip = "A BattleTag (Name#1234) or an e-mail address asks over Battle.net; a character's name adds the character.",
    noIgnored = "You ignore nobody.",
    noAllies = "No recent allies yet.",
    dragToMove = "Drag onto another group or member to move.",
    quickCount = "%s (%d)",
    noQuick = "None of your friends or guild is in a group you can join.",
    chooseRole = "Choose a role first.",
    category = "Category",
    refreshTip = "Looks again for groups in the category chosen.",
    listYourself = "List yourself",
    activities = "%d activities",
    level = "Lvl %d",
    chooseCategory = "Choose a category to look for groups.",
    searching = Core.Word("SEARCHING", "Searching..."),
    searchFailed = "The search failed. Refresh to try again.",
    noGroups = "No groups found. Refresh to look again.",
    noGroupsFound = "No group found.",
    finderOff = "The group finder is not open to you here.",
    finderLocked = "Paused in chat lockdown", -- the group finder's line while the game hides the listings
    nativeChat = "the chat window is off, the game's own chat is back (its button SaneUI, /sane social, or the switch Chat window, brings it again).",
    -- The conversations' panel of the full screen (Conversations.lua, Talks.lua).
    talks = "Conversations",
    talksCount = "Conversations (%d)",
    talkEmpty = "Nothing said here yet.",
    talkHint = "Message %s",
    talkGone = "Not among your Battle.net friends.",
    talkLocked = "while chat is locked down (a fight, a dungeon), only the game's own chat line can send. The message is still in the line.",
    talkRemove = "Remove the conversation with %s and all its messages?",
    groupOver = "You left this group.",
    -- The parts of the conversations' list, each under a head that folds it away (Conversations.lua).
    whispers = "Whispers",
    groups = "Groups",
    partTip = "Click to fold this part of the list away, or to show it again. Its messages waiting to be read are counted on its head.",
    alliesWaiting = "The game has not read your recent allies yet. Its own friends list does, on its Recent Allies tab (Classic windows: Friends list).",
    today = "Today",
    yesterday = "Yesterday",
    you = Core.Word("YOU", "You"),
    -- The game's channels in the list on the chat's name: ticked while you are in them, on every character (Join.lua).
    everywhere = "Joined on every character",
}
-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the chat window is closed"

-- What the bubbles stand on: a colour of your choice, or one of the game's own background textures,
-- quiet ones its windows are filled with, repeated every size points (Core.Skin.TILES, as a full window's).
local BACK_CHOICES = Core.Skin.Choices(ns.TEXT.solid)

-- Retail's own group finder (PVEFrame: the dungeon finder and premade groups), where the game has it; nil in WoW:
-- Forever, whose finder is the vanilla style one (LFGParentFrame) the tab Group finder is built after. Where
-- Retail's is there, that tab and its switch stand down, and the game's own finder is the one opened.
function ns.RetailFinder()
    return rawget(_G, "PVEFrame")
end

-- The groups of messages (Log.GROUPS) that have a switch of their own: it says whether they are shown
-- (Channels.Shown), in the settings and in the list of what to show alike.
ns.SHOWS = { SYSTEM = "showSystem", MONSTER = "showCreatures", PRINT = "showAddons", CHANNEL_NOTICES = "showJoins" }
local SHOWN = {}
for _, key in pairs(ns.SHOWS) do SHOWN[key] = true end

-- The page Chat has two tabs: General (the switches that name no tab) and Appearance.
local LOOK = "Appearance"
local OPTIONS = {
    -- The setup, step by step (Setup.lua, the window of the addon Onboarding).
    { key = "setup", text = ns.TEXT.setup, tip = ns.TEXT.setupTip,
      button = function() Core.Onboarding.Open(ns.name) end },
    { key = "window", default = true, text = "Chat window", header = "Chat window",
      headerTip = "This window next to the game's chat, and what it keeps between sessions.",
      tip = "This window, in place of or next to the game's chat. Off: only the game's chat, as it was." },
    { key = "showNative", default = false, text = "Show the game's chat too",
      tip = "The game's own chat window stays on screen next to this one. Off: it is hidden while this window is open, but keeps every line." },
    { key = "history", default = true, text = "Save chat history",
      tip = "The last messages of each character come back in the window at its next login, faded out. Turn the mouse wheel over the window to read them." },
    { key = "historySize", default = 100, min = 10, max = 500, step = 10, unit = "messages", text = "Messages kept", parent = "history", inline = true,
      tip = "How many of the last messages are kept for the next login." },

    { key = "showSystem", default = true, text = ns.TEXT.kinds.SYSTEM, header = "Messages to show",
      headerTip = "Which of these the window shows. The same ticks are in the list on the chat's name in the line to write in.",
      tip = "What the game tells you: a friend coming online, your time played, answers to slash commands, achievements and the like." },
    { key = "showCreatures", default = true, text = ns.TEXT.kinds.MONSTER,
      tip = "What creatures and bosses say, yell, whisper and emote." },
    { key = "showAddons", default = true, text = ns.TEXT.kinds.PRINT,
      tip = "Lines an addon, or the game itself, prints into the chat." },
    { key = "showJoins", default = false, text = ns.TEXT.kinds.CHANNEL_NOTICES,
      tip = "Somebody joined or left a chat channel, also the hidden channels addons use, and you joined, left or changed one." },
    -- The ticks of the list on the chat's name for every other group ([group] = true: not shown):
    -- kept with the settings, so profiles and a character's own settings carry them; no control.
    -- Off at first (Saneroki, 2026-10-30): loot, money and experience, and the busy public channels by the game's own word
    -- for them (Channels.Group; TradeLocal is Forever's Trade (Local), Services Trade (Services), NewcomerChat Retail's
    -- Newcomer Chat).
    { key = "mute", default = { REWARDS = true, ["CHANNEL:General"] = true, ["CHANNEL:Trade"] = true, ["CHANNEL:TradeLocal"] = true,
                                ["CHANNEL:LocalDefense"] = true, ["CHANNEL:Services"] = true, ["CHANNEL:NewcomerChat"] = true } },

    -- The full screen's windows (Board.lua): which stand there is the layouts' (the dropdown Windows in its title bar).
    { key = "talkSize", default = 100, min = 20, max = 500, step = 10, unit = "messages", text = "Messages kept per conversation", header = "Full screen",
      headerTip = "What the full screen's windows hold. Which windows stand there, and where, you arrange on the full screen itself: drag a window's head to move it, the gap between two to share their room, add one from the dropdown Windows, take one off with its X; each layout behind a tab of its own.",
      tip = "How many of the last messages each conversation keeps, also for the next login (then 1,000 of all conversations together at most, the newest first)." },
    -- The game's friends list and group finder keys open ours (Keys.lua), each until its tick in the dropdown Classic
    -- windows says the game's own (Saneroki, 2026-11-18): no control here, the tick is the place.
    { key = "friendsKey", default = true },
    { key = "finderKey", default = true },
    { key = "groupEach", default = true, text = "A new conversation for each group",
      tip = "Each party or raid you join gets a conversation of its own, named by who is in it, to read on after you leave. Off: one conversation for all your parties and raids, and one for your instance groups, read on from where they were." },
    { key = "boardFinder", default = true, text = "Group finder", hidden = function() return ns.RetailFinder() ~= nil end,
      tip = "The group finder as a tab of the friends list, as the game's: the groups and players looking for others in a category. Whisper a leader, or invite a player who is alone." },

    { key = "textSize", default = 14, min = 10, max = 24, step = 1, text = "Text size", tab = LOOK, header = "Messages",
      headerTip = "How the messages and their bubbles look.",
      tip = "The size of the message text and of the names above the bubbles." },
    { key = "bubbleOpacity", default = 50, min = 0, max = 100, step = 5, unit = "%", text = "Bubble opacity", tab = LOOK,
      tip = "How solid the bubbles and the line to write in are: 100 is solid, 0 leaves only the text." },
    { key = "bubbleBack", default = "solid", text = "Bubble background", tab = LOOK, choices = BACK_CHOICES,
      tip = "What the bubbles and the line to write in stand on: a colour of your choice, or one of the game's own background textures." },
    { key = "bubbleColor", default = "26262B", color = true, text = "Bubble colour", tab = LOOK, parent = "bubbleBack", parentValue = "solid",
      tip = "The colour of the bubbles and the line to write in while the background is Solid colour. Click to pick it." },
    { key = "mineSide", default = "right", text = "Your messages", tab = LOOK,
      choices = { { "right", "On the right" }, { "left", "On the left" } },
      tip = "Where your own messages stand: on the right, as in a messenger, or on the left with your name and class, as everybody else's." },
    { key = "shortNames", default = false, text = "Short names", tab = LOOK,
      tip = "The chat above a message is named by its initials: G for Guild, P for Party, RW for Raid Warning. Off: its whole name." },

    { key = "animations", default = true, text = "All animations and fades", tab = LOOK, header = "Animations",
      headerTip = "How messages fade and slide, and how the window fills the screen.",
      tip = "Messages fade in and out and slide up to make room, and the window fills the screen with motion. Off: nothing moves or fades, and every message stays." },
    { key = "fadeInOn", default = true, text = "Fade in", tab = LOOK, parent = "animations",
      tip = "A new message fades in, and so do all of them when they come back. Off: a message is there at once." },
    { key = "fadeInTime", default = 0.5, min = 0, max = 2, step = 0.05, unit = "seconds", text = "Fade-in time", tab = LOOK, parent = "fadeInOn", inline = true,
      tip = "How long a message takes to fade in." },
    { key = "fade", default = true, text = "Fade out", tab = LOOK, parent = "animations",
      tip = "Each message fades out a while after it came. Turn the mouse wheel over the window, or let it fill the screen, and all come back. Off: every message stays." },
    { key = "fadeOutTime", default = 1, min = 0, max = 2, step = 0.05, unit = "seconds", text = "Fade-out time", tab = LOOK, parent = "fade", inline = true,
      tip = "How long a message takes to fade out." },
    { key = "fadeAfter", default = 10, min = 5, max = 300, step = 5, unit = "seconds", text = "Fade messages after", tab = LOOK, parent = "fade",
      tip = "How long a message stays fully visible before it fades out." },
    { key = "fadeFloorOn", default = false, text = "Faded messages stay visible", tab = LOOK, parent = "fade",
      tip = "A faded message stays a little visible instead of going out of sight." },
    { key = "fadeFloor", default = 30, min = 5, max = 95, step = 5, unit = "%", text = "Opacity of faded messages", tab = LOOK, parent = "fadeFloorOn", inline = true,
      tip = "How visible a faded message stays." },
    { key = "slide", default = true, text = "Slide up", tab = LOOK, parent = "animations",
      tip = "Messages slide up to make room for a new one or for the line to write in. Off: they jump there." },
    { key = "slideTime", default = 0.5, min = 0, max = 2, step = 0.05, unit = "seconds", text = "Slide time", tab = LOOK, parent = "slide", inline = true,
      tip = "How long a slide takes." },
}
-- Last on the tab Appearance, after the messages' look: the sections Expand window and Window corners, as
-- Core has them for every window (Edge.lua, Shape.lua). Its Animation type is ignored while all
-- animations are off (Window.lua, Kind): greyed out then too.
local last
for index, option in ipairs(OPTIONS) do
    if option.tab == LOOK then last = index end
end
Core.Edge.Options(OPTIONS, (last or #OPTIONS) + 1, LOOK, { motion = "animations" })
-- The switches of fading and sliding: a change of one sets every fade and slide anew (Window.Animate).
local MOVES = { animations = true, fadeInOn = true, fadeInTime = true, fadeOutTime = true, slide = true, slideTime = true,
                fadeFloorOn = true, fadeFloor = true, fade = true, fadeAfter = true }

-- What each of the game's channels does on every character ([its name] = true: always in it, false:
-- never in it; none: the game decides). Set in the list on the chat's name (Join.lua, Menu.lua); kept
-- with the settings, so profiles and a character's own settings carry it; no control on the page.
OPTIONS[#OPTIONS + 1] = { key = "presence", default = {} }

-- Settings saved by an older version, in each copy of them (a profile's, a character's own), brought up
-- to this shape before Core checks them (Core.Options: version, upgrade). 3: the bubbles' Transparency
-- (bubbleClear, 0 solid) is their Bubble opacity now (100 solid).
local function Upgrade(copy, from)
    if from < 3 and type(copy.bubbleClear) == "number" then copy.bubbleOpacity = 100 - copy.bubbleClear end
    copy.bubbleClear = nil
end

Core.Options(ns.name, OPTIONS, { version = 3, upgrade = Upgrade, changed = function(key)
    if key == "presence" then return ns.Safe("channels", ns.Join.Settle) end
    -- Whether the game's friends list and group finder keys open ours (Keys.lua).
    if key == "friendsKey" or key == "finderKey" or key == "expand" or key == "boardFinder" then ns.Guarded(ns.Keys.Bind) end
    -- The section Expand window: Core's window takes it in by itself (Edge.lua); its Animation type is asked
    -- for each time the window fills the screen.
    if Core.Edge.KEYS[key] then return end
    if key == "window" then return ns.Guarded(ns.Window.Follow) end
    if SHOWN[key] or key == "mute" then return ns.Guarded(ns.Window.Refill) end
    -- The group finder is a tab of the friends list: its switch offers the tab or takes it away.
    if key == "boardFinder" then return ns.Safe("friends tabs", ns.Friends.Relabel) end
    if key == "talkSize" then return ns.Safe("conversations", ns.Talks.Trim) end
    if key == "groupEach" then return end -- the next group you join
    if key == "history" or key == "historySize" then return ns.Keep() end
    local Window = ns.Window
    ns.Guarded(key == "textSize" and Window.Resize or key == "showNative" and Window.Native or MOVES[key] and Window.Animate
        or Window.Repaint)
end })

-- One step of giving back. Each runs by itself, so one that fails does not keep the next from its work.
local function Back(step)
    local ok, problem = xpcall(step, Core.Trace)
    if not ok then Core.NoteError(ns.name .. ": giving back", problem) end
end

-- Something failed (Core's StandDown calls this once): the edit boxes go back to where the game had
-- them first, then the window goes and the game's own chat is back, with every line it got meanwhile.
function ns.GiveBack()
    Back(ns.Keys.Leave)
    Back(ns.Input.Release)
    Back(ns.Input.Forget)
    Back(ns.Window.Hide)
    Back(ns.Native.Show)
end

-- Reading a message touches nothing (Log.Read): one that cannot be read is left out and noted,
-- and the window goes on. Chat arrives many times a second in a city: no table and no closure here.
-- A whisper, or a group's chat, goes into its conversation too (Talks.lua), apart from the window.
local function Heard(event, ...)
    if ns.off then return end
    local ok, entry = xpcall(ns.Log.Read, Core.Trace, event, ...)
    if not ok then
        ns.Report(ns.TEXT.unread, entry)
    elseif entry then
        ns.Guarded(ns.Log.Add, entry)
        if entry.with or ns.Talks.GROUPS[entry.group] then ns.Safe("conversations", ns.Talks.Add, entry) end
    end
end


function ns.OnLoad()
    local store = Core.Store(ns.name)
    ns.store, ns.options = store, Core.Settings(ns.name)
    -- 2: the ticks of the list (store.mute) and whether the window is shown (store.hidden) were kept
    -- beside the settings; they are settings now, so profiles and a character's own carry them.
    if (store.version or 1) < 2 then
        if type(store.mute) == "table" then
            for group in pairs(store.mute) do ns.options.mute[group] = true end
        end
        if store.hidden then ns.options.window = false end
        store.mute, store.hidden = nil, nil
        store.version = 2
    end
    ns.Keep()
end

-- The log keeps at least as many messages as the history saves.
function ns.Keep()
    ns.Log.Keep(ns.options.history and ns.options.historySize or 0)
end

-- The history (Log.Saved): the last messages of this character, saved at a logout or /reload (the
-- game writes the saved settings right after), back in the log at the next login.
local function History(char)
    local options = ns.options
    char.history = options.history and ns.Log.Saved(options.historySize) or nil
    char.historyVersion = char.history and ns.Log.HISTORY or nil
end

-- Every line one of the game's chat windows writes (AddMessage): what none of our events told
-- (Log.Line).
-- A filter of the game's chat (ChatFrame_AddMessageEventFilter): asked right before a window writes
-- the line of a chat event, so that line is known by its event (Log.Before). It filters nothing, also
-- after a failure (false: the game writes the line).
local function Before(window, event)
    return ns.Safe("chat filter", ns.Log.Before, window, event) or false
end

local Printed = ns.Guard(function(window, text, r, g, b, id, _, _, event)
    if Core.Secret(id) or Core.Secret(event) then return end
    ns.Log.Line(window, text, r, g, b, id, event)
end)

-- Whether the game has chat locked down now (a fight, a dungeon): then it hands addons no messages, hides the
-- group finder's listings from them and takes no message or emote from their code (Window, Conversations,
-- Picker, the group finder).
function ns.ChatLocked()
    local chat = rawget(_G, "C_ChatInfo")
    return chat ~= nil and Core.Ask(chat.InChatMessagingLockdown) == true
end

-- While chat is locked down (a fight, a dungeon) addons get no messages to show: the game's own
-- chat comes back for that time. The game tells before a lockdown begins and after it ended; it
-- counts once that is done, a frame later.
local Lockdown = Core.Later(function() ns.Guarded(ns.Window.Native) end)

-- What a speaker is to you changes with these: what the log knows of it is asked anew.
local TIES = { "FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_LIST_SIZE_CHANGED", "GUILD_ROSTER_UPDATE",
               "PLAYER_GUILD_UPDATE", "GROUP_ROSTER_UPDATE" }

function ns.OnLogin()
    ns.Safe("channels", ns.Join.Watch)
    for event in pairs(ns.Log.EVENTS) do
        ns.On(event, function(...) Heard(event, ...) end)
    end
    for _, event in ipairs(TIES) do ns.On(event, ns.Log.Forget) end
    ns.On("GUILD_MOTD", function(motd) ns.Guarded(ns.Log.Motd, motd) end)
    ns.On("ADDON_RESTRICTION_STATE_CHANGED", Lockdown)
    for _, name in ipairs(CHAT_FRAMES or {}) do
        local window = _G[name]
        -- The game's combat log is no chat.
        if window and window ~= COMBATLOG and window.AddMessage then
            hooksecurefunc(window, "AddMessage", Printed)
            window:HookScript("OnEvent", ns.Guard(ns.Log.After))
        end
    end
    local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or rawget(_G, "ChatFrame_AddMessageEventFilter")
    if AddFilter then
        for event in pairs(ns.Log.Unread()) do AddFilter(event, Before) end
    end
    local char = Core.Character(ns.name)
    if ns.options.history then ns.Safe("history", ns.Log.Restore, char.history, char.historyVersion) end
    ns.Safe("conversations", ns.Talks.Restore, char.talks, char.talkGroups)
    ns.On("PLAYER_LOGOUT", function()
        ns.Safe("history", History, char)
        ns.Safe("conversations", ns.Talks.Save, char)
    end)
    ns.Guarded(ns.Window.Follow)
    ns.Safe("keys", ns.Keys.Start)
    -- An alias given or changed (Core.People, the game's menu of a player): the names above the bubbles anew.
    if Core.People then Core.People.Watch(function() ns.Guarded(ns.Window.Repaint) end) end
end

-- Ours (on) or the game's chat. The switch Chat window is the one place that is kept: Core.Set tells the
-- window (changed: Window.Follow, which keeps Core's window's memory of it the same) and an open options
-- page, so the button Classic window, close, the dropdown, /sane social, its key and the switch agree.
local function Choose(on)
    Core.Set(ns.name, "window", on and true or false)
end

-- The game's own windows ours stands for, in Core's dropdown Classic windows while the window fills
-- the screen (Edge.lua), each a tick, ticked while the game's own is the one (Saneroki, 2026-11-18: "Make sure
-- you can check all of them"): its chat, for which ours is put away (the switch Chat window off); its friends
-- list and its group finder, whose keys then open the game's again (friendsKey, finderKey: Keys.lua), opened
-- as its key opens it (ToggleFriendsFrame), only if it is not open already. Unticked, ours again. The
-- window goes back to its zone either way (Core's). In a fight the game refuses to open its panels from
-- an addon's code ("Interface action failed"; UIParentPanelManager.lua): then it is only said.
-- The game's friends list is FriendsFrame, or its newer social window (SocialUIFrame) where the game has that on
-- in its place (SocialUIControl.IsEnabled, in both games).
local FRIENDS = { "FriendsFrame", "SocialUIFrame" }
local function Friends()
    local toggle = rawget(_G, "ToggleFriendsFrame")
    if not toggle then return end
    for _, name in ipairs(FRIENDS) do
        local friends = rawget(_G, name)
        if friends and friends:IsShown() then return end
    end
    if InCombatLockdown() then return ns.Print(ns.TEXT.friendsInFight) end
    toggle(rawget(_G, "FRIEND_TAB_FRIENDS"))
end

-- Ours put away, the game's chat back (the switch Chat window off), and how to bring ours again is said.
local function PutAway()
    Choose(false)
    ns.Print(ns.TEXT.nativeChat)
end

-- The game's group finder, opened as its micro menu button opens it, only if it is not open already; as the
-- friends list. In WoW: Forever ToggleGroupFinderFrame: the game's vanilla style finder, LFGParentFrame, loaded
-- by the game when it allows it; tab: that finder's own (1 to list yourself, 2 to browse). In Retail its own
-- finder (PVEFrame_ToggleFrame: PVEFrame, where it was last).
function ns.OpenFinder(tab)
    local finder = rawget(_G, "LFGParentFrame") or ns.RetailFinder()
    if finder and finder:IsShown() then return end
    if InCombatLockdown() then return ns.Print(ns.TEXT.finderInFight) end
    local show = rawget(_G, "LFGVanilla_ShowFrame")
    local toggle = rawget(_G, "ToggleGroupFinderFrame") or rawget(_G, "PVEFrame_ToggleFrame")
    if tab and show then show(tab) elseif toggle then toggle() end
end

-- The button SaneUI on the game's friends list and group finder (Core's Classic.lua): ours, filling the
-- screen. The game's chat has its own (ns.NATIVE).
local function Ours() Choose(true) end
local function Running() return not ns.off end
ns.CLASSIC = {
    { text = ns.TEXT.classicChat, show = PutAway, checked = function() return ns.options.window == false end,
      back = function() Choose(true) end },
    { text = ns.TEXT.classicFriends, checked = function() return ns.options.friendsKey == false end,
      show = function()
          Core.Set(ns.name, "friendsKey", false)
          ns.Safe("friends list", Friends)
      end,
      back = function() Core.Set(ns.name, "friendsKey", true) end,
      frame = FRIENDS, full = true, ours = Ours, ready = Running },
    -- The finder of either game: Forever's comes with its addon, loaded on demand; Retail's is there from the start.
    { text = ns.TEXT.classicFinder, checked = function() return ns.options.finderKey == false end,
      show = function()
          Core.Set(ns.name, "finderKey", false)
          ns.Safe("group finder", ns.OpenFinder)
      end,
      back = function() Core.Set(ns.name, "finderKey", true) end,
      frame = { "LFGParentFrame", "PVEFrame" }, addon = "Blizzard_GroupFinder_VanillaStyle", full = true, ours = Ours,
      ready = Running },
}
-- Core's buttons while the window stands free or in the middle of the screen: the game's own window is
-- its chat, and closing ours puts it away the same way. The button back to ours (SaneUI) goes onto the
-- game's chat, in the strip of buttons left of it (ChatFrame1ButtonFrame), just above its chat menu
-- button: it fades with them, as the game's own. There only while ours is away (Window.lua, Back).
local function Strip() return rawget(_G, "ChatFrame1ButtonFrame") end
ns.NATIVE = {
    frame = Strip,
    show = PutAway,
    back = function() if not ns.off then Choose(true) end end,
    anchor = function(button)
        local menu = rawget(_G, "ChatFrameMenuButton")
        if menu and menu:GetParent() == Strip() then
            button:SetPoint("BOTTOM", menu, "TOP", 0, 2)
        else
            button:SetPoint("BOTTOM", 0, 34)
        end
    end,
}
ns.Close = PutAway

-- The chat window shown or hidden: /sane social, and its key (Bindings.xml).
function ns.Toggle()
    if ns.off then return ns.Print(ns.TEXT.stopped) end
    Choose(not ns.options.window)
end
BINDING_NAME_SANEUI_SOCIAL = ns.TEXT.binding

-- Social's full screen and back, by a key of its own (Bindings.xml): the chat window first, if it was put away. As the
-- hot corner, only while Can expand to fullscreen is on.
function ns.Full()
    if ns.off then return ns.Print(ns.TEXT.stopped) end
    if not ns.options.window then Choose(true) end
    ns.Window.Full()
end
BINDING_NAME_SANEUI_SOCIAL_FULL = ns.TEXT.bindingFull

Core.Command("social", ns.TEXT.about, function(rest)
    if ns.off then
        ns.Print(ns.TEXT.stopped)
    elseif rest == "reset" then
        Choose(true)
        ns.Guarded(ns.Window.Reset)
        ns.Print(ns.TEXT.reset)
    else
        ns.Toggle()
    end
end, "chat") -- the module's name before it was Social
