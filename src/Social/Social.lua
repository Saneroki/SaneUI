local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social
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
    binding = "Show or hide the chat window", -- its key, in the game's key bindings under Sane UI (Bindings.xml)
    unread = "a chat message could not be read",
    solid = "Solid colour", -- what the bubbles stand on, the first of the choices (Core.Skin.Choices)
    -- The dropdown Classic windows while the window fills the screen: the game's own windows it stands for.
    classicChat = Core.Word("CHAT", "Chat"),
    classicFriends = "Friends list",
    friendsInFight = "in a fight the game's friends list opens only by its own key.",
    nativeChat = "the chat window is off, the game's own chat is back (its button Sane UI, /sane social, or the switch Chat window, brings it again).",
    -- The game's channels in the list on the chat's name: what each does on every character (Join.lua).
    everywhere = "On every character",
    wishes = { { text = "The game decides" }, { wish = true, text = "Always in it" }, { wish = false, text = "Never in it" } },
}
-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the chat window is closed"

-- What the bubbles stand on: a colour of your choice, or one of the game's own background textures,
-- quiet ones its windows are filled with, repeated every size points (Core.Skin.TILES, as a full window's).
local BACK_CHOICES = Core.Skin.Choices(ns.TEXT.solid)

-- The groups of messages (Log.GROUPS) that have a switch of their own: it says whether they are shown
-- (Channels.Shown), in the settings and in the list of what to show alike.
ns.SHOWS = { SYSTEM = "showSystem", MONSTER = "showCreatures", PRINT = "showAddons", CHANNEL_NOTICES = "showJoins" }
local SHOWN = {}
for _, key in pairs(ns.SHOWS) do SHOWN[key] = true end

-- The page Chat has two tabs: General (the switches that name no tab) and Appearance.
local LOOK = "Appearance"
local OPTIONS = {
    { key = "window", default = true, text = "Chat window", header = "Chat window",
      headerTip = "This window next to the game's chat, and what it keeps between sessions.",
      tip = "This window, in place of or next to the game's chat. Off: only the game's chat, as it was." },
    { key = "showNative", default = true, text = "Show the game's chat too",
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
    { key = "mute", default = {} },

    { key = "textSize", default = 14, min = 10, max = 24, step = 1, text = "Text size", tab = LOOK, header = "Messages",
      headerTip = "How the messages and their bubbles look.",
      tip = "The size of the message text and of the names above the bubbles." },
    { key = "bubbleOpacity", default = 50, min = 0, max = 100, step = 5, unit = "%", text = "Bubble opacity", tab = LOOK,
      tip = "How solid the bubbles and the line to write in are: 100 is solid, 0 leaves only the text." },
    { key = "bubbleBack", default = "solid", text = "Bubble background", tab = LOOK, choices = BACK_CHOICES,
      tip = "What the bubbles and the line to write in stand on: a colour of your choice, or one of the game's own background textures." },
    { key = "bubbleColor", default = "26262B", color = true, text = "Bubble colour", tab = LOOK, parent = "bubbleBack", parentValue = "solid",
      tip = "The colour of the bubbles and the line to write in while the background is Solid colour. Click to pick it." },
    { key = "shortNames", default = true, text = "Short names", tab = LOOK,
      tip = "The chat above a message is named by its initials: G for Guild, P for Party, RW for Raid Warning. Off: its whole name." },

    { key = "animations", default = true, text = "All animations and fades", tab = LOOK, header = "Animations",
      headerTip = "How messages fade and slide, and how the window fills the screen.",
      tip = "Messages fade in and out and slide up to make room, and the window fills the screen with motion. Off: nothing moves or fades, and every message stays." },
    { key = "fadeInOn", default = true, text = "Fade in", tab = LOOK, parent = "animations",
      tip = "A new message fades in, and so do all of them when they come back. Off: a message is there at once." },
    { key = "fadeInTime", default = 0.4, min = 0, max = 2, step = 0.05, unit = "seconds", text = "Fade-in time", tab = LOOK, parent = "fadeInOn", inline = true,
      tip = "How long a message takes to fade in." },
    { key = "fade", default = true, text = "Fade out", tab = LOOK, parent = "animations",
      tip = "Each message fades out a while after it came. Turn the mouse wheel over the window, or write, and all come back. Off: every message stays." },
    { key = "fadeOutTime", default = 1, min = 0, max = 2, step = 0.05, unit = "seconds", text = "Fade-out time", tab = LOOK, parent = "fade", inline = true,
      tip = "How long a message takes to fade out." },
    { key = "fadeAfter", default = 60, min = 5, max = 300, step = 5, unit = "seconds", text = "Fade messages after", tab = LOOK, parent = "fade",
      tip = "How long a message stays fully visible before it fades out." },
    { key = "fadeFloorOn", default = false, text = "Faded messages stay visible", tab = LOOK, parent = "fade",
      tip = "A faded message stays a little visible instead of going out of sight." },
    { key = "fadeFloor", default = 30, min = 5, max = 95, step = 5, unit = "%", text = "Opacity of faded messages", tab = LOOK, parent = "fadeFloorOn", inline = true,
      tip = "How visible a faded message stays." },
    { key = "slide", default = true, text = "Slide up", tab = LOOK, parent = "animations",
      tip = "Messages slide up to make room for a new one or for the line to write in. Off: they jump there." },
    { key = "slideTime", default = 0.3, min = 0, max = 2, step = 0.05, unit = "seconds", text = "Slide time", tab = LOOK, parent = "slide", inline = true,
      tip = "How long a slide takes." },
}
-- First on the tab Appearance, above the other sections: the section Expand window, as Core has it for
-- every window (Edge.lua), with how round its corners are (Shape.lua). Its Animation type is ignored
-- while all animations are off (Window.lua, Kind): greyed out then too.
for index, option in ipairs(OPTIONS) do
    if option.tab == LOOK then
        Core.Edge.Options(OPTIONS, index, LOOK, { motion = "animations" })
        break
    end
end
-- The switches of fading and sliding: a change of one sets every fade and slide anew (Window.Animate).
local MOVES = { animations = true, fadeInOn = true, fadeInTime = true, fadeOutTime = true, slide = true, slideTime = true,
                fadeFloorOn = true, fadeFloor = true, fade = true, fadeAfter = true }

-- What each of the game's channels does on every character ([its name] = true: always in it, false:
-- never in it; none: the game decides). Set in the list on the chat's name (Join.lua, Menu.lua); kept
-- with the settings, so profiles and a character's own settings carry it; no control on the page.
OPTIONS[#OPTIONS + 1] = { key = "presence", default = {} }

Core.Options(ns.name, OPTIONS, function(key)
    if key == "presence" then return ns.Safe("channels", ns.Join.Settle) end
    -- The section Expand window: Core's window takes it in by itself (Edge.lua); its Animation type is asked
    -- for each time the window fills the screen.
    if Core.Edge.KEYS[key] then return end
    if key == "window" then return ns.Guarded(ns.Window.Follow) end
    if SHOWN[key] or key == "mute" then return ns.Guarded(ns.Window.Refill) end
    if key == "history" or key == "historySize" then return ns.Keep() end
    local Window = ns.Window
    ns.Guarded(key == "textSize" and Window.Resize or key == "showNative" and Window.Native or MOVES[key] and Window.Animate
        or Window.Repaint)
end)

-- One step of giving back. Each runs by itself, so one that fails does not keep the next from its work.
local function Back(step)
    local ok, problem = xpcall(step, Core.Trace)
    if not ok then Core.NoteError(ns.name .. ": giving back", problem) end
end

-- Something failed (Core's StandDown calls this once): the edit boxes go back to where the game had
-- them first, then the window goes and the game's own chat is back, with every line it got meanwhile.
function ns.GiveBack()
    Back(ns.Input.Release)
    Back(ns.Input.Forget)
    Back(ns.Window.Hide)
    Back(ns.Native.Show)
end

-- Reading a message touches nothing (Log.Read): one that cannot be read is left out and noted,
-- and the window goes on. Chat arrives many times a second in a city: no table and no closure here.
local function Heard(event, ...)
    if ns.off then return end
    local ok, entry = xpcall(ns.Log.Read, Core.Trace, event, ...)
    if not ok then
        ns.Report(ns.TEXT.unread, entry)
    elseif entry then
        ns.Guarded(ns.Log.Add, entry)
    end
end

-- Settings saved by an older version, in every copy of them (the settings in use, a profile, a
-- character's own: Core.Profiles.Copies). The bubbles' Transparency (bubbleClear, 0 solid) is their
-- Bubble opacity now (100 solid). Done once per copy: the old key goes.
local function Mend(copy)
    if type(copy.bubbleClear) == "number" then copy.bubbleOpacity = 100 - copy.bubbleClear end
    copy.bubbleClear = nil
end

function ns.OnLoad()
    local store = Core.Store(ns.name)
    ns.store, ns.options = store, Core.Settings(ns.name)
    for _, copy in ipairs(Core.Profiles and Core.Profiles.Copies(ns.name) or {}) do Mend(copy) end
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
-- the line of a chat event, so that line is known by its event (Log.Before). It filters nothing.
local function Before(window, event)
    ns.Log.Before(window, event)
    return false
end

local function Printed(window, text, r, g, b, id, _, _, event)
    if ns.off or Core.Secret(id) or Core.Secret(event) then return end
    ns.Guarded(ns.Log.Line, window, text, r, g, b, id, event)
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
            window:HookScript("OnEvent", ns.Log.After)
        end
    end
    local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or rawget(_G, "ChatFrame_AddMessageEventFilter")
    if AddFilter then
        for event in pairs(ns.Log.Unread()) do AddFilter(event, Before) end
    end
    local char = Core.Character(ns.name)
    if ns.options.history then ns.Safe("history", ns.Log.Restore, char.history, char.historyVersion) end
    ns.On("PLAYER_LOGOUT", function() ns.Safe("history", History, char) end)
    ns.Guarded(ns.Window.Follow)
end

-- Ours (on) or the game's chat. The switch Chat window is the one place that is kept: Core.Set tells the
-- window (changed: Window.Follow, which keeps Core's window's memory of it the same) and an open options
-- page, so the button Classic window, close, the dropdown, /sane social, its key and the switch agree.
local function Choose(on)
    Core.Set(ns.name, "window", on and true or false)
end

-- The game's own windows ours stands for, in Core's dropdown Classic windows while the window fills
-- the screen (Edge.lua): its chat, for which ours is put away (the switch Chat window off), and its
-- friends list, opened as its key opens it (ToggleFriendsFrame), only if it is not open already. The
-- window goes back to its zone either way (Core's). In a fight the game refuses to open its panels from
-- an addon's code ("Interface action failed"; UIParentPanelManager.lua): then it is only said.
local function Friends()
    local friends, toggle = rawget(_G, "FriendsFrame"), rawget(_G, "ToggleFriendsFrame")
    if not toggle or (friends and friends:IsShown()) then return end
    if InCombatLockdown() then return ns.Print(ns.TEXT.friendsInFight) end
    toggle(rawget(_G, "FRIEND_TAB_FRIENDS"))
end

-- Ours put away, the game's chat back (the switch Chat window off), and how to bring ours again is said.
local function PutAway()
    Choose(false)
    ns.Print(ns.TEXT.nativeChat)
end

ns.CLASSIC = {
    { text = ns.TEXT.classicChat, show = PutAway },
    { text = ns.TEXT.classicFriends, show = function() ns.Safe("friends list", Friends) end },
}
-- Core's buttons while the window stands free or in the middle of the screen: the game's own window is
-- its chat, and closing ours puts it away the same way. The button back to ours (Sane UI) goes onto the
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
