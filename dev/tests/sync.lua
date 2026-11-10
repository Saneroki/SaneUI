-- Runs Core's Sync against the stand-in client (wowstub.lua), with a small model of the game's own
-- settings: CVars kept for the character, the account or the computer, chat windows and the colours of
-- the kinds of chat, chat channels of your own, Edit Mode layouts, the action bar switches, guild
-- invitations, the modifier keys of clicks. The options pages' lists are the real ones (Data/Pages.lua).
-- Whether the game's frames show what was set can only be seen in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/sync.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-- The game's own settings of the character that is played ----------------------------------------
local game = {}

local function Fresh()
    W.cvarInfo = {
        autoLootDefault = { default = "0", scope = "account" },        -- on the page Controls
        cameraSmoothStyle = { default = "4", scope = "account" },      -- on the page Controls
        nameplateSize = { default = "1", scope = "character" },        -- on the page Nameplates
        cameraSavedDistance = { default = "15", scope = "character" }, -- on no page, kept per character
        questLogOpen = { default = "0", scope = "character" },         -- on no page, kept per character
        trackedQuests = { default = "", scope = "character" },         -- a character's state
        lastSelectedTab = { default = "1", scope = "character" },      -- a character's state
        accountThing = { default = "0", scope = "account" },           -- on no page, the account's
        graphicsQuality = { default = "5", category = 1 },
        gxMonitor = { default = "0", category = 1 },
        Sound_MasterVolume = { default = "1", category = 7 },
        Sound_EnableReverb = { default = "1", category = 7 },
        debugThing = { default = "0", category = 0 },
        graphicsFixed = { default = "1", category = 1, readOnly = true }, -- the game does not let these be set
        soundLocked = { default = "1", category = 7, locked = true },
        secureNote = { default = "0", scope = "character", secure = true }, -- not in a fight
    }
    W.cvars = {}
    game.windows = {
        { name = "General", size = 14, r = 0, g = 0, b = 0, alpha = 0.25, shown = true, locked = true, docked = 1,
          messages = { "SAY", "GUILD" }, channels = { "General" } },
        { name = "Combat Log", size = 14, r = 0, g = 0, b = 0, alpha = 0.25, shown = true, docked = 2, messages = {}, channels = {} },
        { name = "", size = 0, r = 0, g = 0, b = 0, alpha = 0, shown = false, messages = {}, channels = {} },
    }
    game.colours = { SAY = { r = 1, g = 1, b = 1 }, CHANNEL1 = { r = 1, g = 0.75, b = 0.75 } }
    ChatTypeInfo = game.colours -- the game's table of the kinds of chat
    game.channels = { { 1, "General" }, { 2, "Trade" } }
    game.layouts = { "Modern", "Classic", "Mine" } -- two of the game's, then the account's own
    game.active = 1
    game.editMode, game.loggedOut = false, false
    game.bars = { true, false, false }
    game.declineGuild = false
    game.places = { [2] = { "TOPLEFT", 10, -20, 300, 200 }, [3] = { "BOTTOMLEFT", 0, 0, 0, 0 } }
    game.calls = {}
end
Fresh()

local function Call(name)
    game.calls[#game.calls + 1] = name
end

Constants = { ChatFrameConstants = { MaxChatWindows = 3 } }
GetChatWindowInfo = function(id)
    local w = game.windows[id]
    return w.name, w.size, w.r, w.g, w.b, w.alpha, w.shown, w.locked, w.docked, w.uninteractable
end
GetChatWindowMessages = function(id) return unpack(game.windows[id].messages) end
GetChatWindowChannels = function(id)
    local list = {}
    for _, name in ipairs(game.windows[id].channels) do list[#list + 1] = name; list[#list + 1] = 0 end
    return unpack(list)
end
local function Setter(field)
    return function(id, value) Call("SetChatWindow" .. field); game.windows[id][field] = value end
end
SetChatWindowName, SetChatWindowSize, SetChatWindowAlpha = Setter("name"), Setter("size"), Setter("alpha")
SetChatWindowShown, SetChatWindowLocked, SetChatWindowDocked = Setter("shown"), Setter("locked"), Setter("docked")
SetChatWindowUninteractable = Setter("uninteractable")
SetChatWindowColor = function(id, r, g, b)
    Call("SetChatWindowColor")
    local w = game.windows[id]
    w.r, w.g, w.b = r, g, b
end
local function Lister(field, add)
    return function(id, value)
        local list = game.windows[id][field]
        if add then list[#list + 1] = value return end
        for index, known in ipairs(list) do if known == value then table.remove(list, index) return end end
    end
end
AddChatWindowMessages, RemoveChatWindowMessages = Lister("messages", true), Lister("messages")
AddChatWindowChannel, RemoveChatWindowChannel = Lister("channels", true), Lister("channels")
ChangeChatColor = function(kind, r, g, b)
    Call("ChangeChatColor")
    local info = game.colours[kind]
    info.r, info.g, info.b = r, g, b
end
SetChatColorNameByClass = function(kind, on) game.colours[kind].colorNameByClass = on end
-- Where the chat windows that stand free are, and their size
GetChatWindowSavedPosition = function(id) local place = game.places[id] return place[1], place[2], place[3] end
GetChatWindowSavedDimensions = function(id) local place = game.places[id] return place[4], place[5] end
SetChatWindowSavedPosition = function(id, point, x, y) local place = game.places[id] place[1], place[2], place[3] = point, x, y end
SetChatWindowSavedDimensions = function(id, width, height) local place = game.places[id] place[4], place[5] = width, height end

EnumerateServerChannels = function() return "General", "Trade", "LocalDefense", "LookingForGroup", "Services" end
GetChannelList = function()
    local list = {}
    for _, channel in ipairs(game.channels) do
        list[#list + 1], list[#list + 2], list[#list + 3] = channel[1], channel[2], false
    end
    return unpack(list)
end
GetChannelName = function(which)
    for _, channel in ipairs(game.channels) do
        if channel[1] == which or channel[2] == which then return channel[1], channel[2], nil, channel[3] end
    end
    return 0
end
JoinPermanentChannel = function(name)
    Call("Join " .. name)
    game.channels[#game.channels + 1] = { #game.channels + 1, name }
end

-- Edit Mode's manager as the game's: its list (presets first) and the active one in layoutInfo, none
-- before the game gave it its layouts (game.layouts nil). After the logout the game says Modern.
EditModeManagerFrame = setmetatable({ IsEditModeActive = function() return game.editMode end }, { __index = function(_, key)
    if key ~= "layoutInfo" or not game.layouts then return nil end
    local list = {}
    for index, name in ipairs(game.layouts) do list[index] = { layoutName = name, layoutType = index <= 2 and 0 or 1 } end
    return { layouts = list, activeLayout = game.loggedOut and 1 or game.active }
end })
C_EditMode = {
    -- As the game: the event comes at once, and the manager takes the new layouts.
    SetActiveLayout = function(index) Call("SetActiveLayout"); game.active = index; W.Fire("EDIT_MODE_LAYOUTS_UPDATED") end,
}
C_GameRules = { IsMultiActionBarVisibilityForced = function() return false end }
GetActionBarToggles = function() return unpack(game.bars) end
SetActionBarToggles = function(...) Call("SetActionBarToggles"); game.bars = { ... } end
GetAutoDeclineGuildInvites = function() return game.declineGuild end
SetAutoDeclineGuildInvites = function(on) game.declineGuild = on end
C_UI = { Reload = function() W.reloaded = true end }
-- The modifier keys of the game's clicks, kept with its key bindings
game.clicks = { SELFCAST = "ALT", CHATLINK = "SHIFT" }
GetModifiedClick = function(action) return game.clicks[action] or "NONE" end
SetModifiedClick = function(action, key) game.clicks[action] = key end
GetCurrentBindingSet = function() return 1 end
SaveBindings = function(set) game.bindingsSaved = set end
-- Two of the game's own words; the others this stand-in lacks, so ours stand in.
CONTROLS_LABEL, SETTING_GROUP_GAMEPLAY = "Controls", "Gameplay"

-- Core, with Sync and the options ------------------------------------------------------------------
W.LoadCore(root)
SettingsPanel = W.NewWidget("Frame", "SettingsPanel")
SettingsPanel:Hide() -- closed: its OnShow is run by hand below; the save window's checks (sync.lua) open it
local Core = SaneUI.Core
local Sync = Core.Sync
check(Sync and SaneUI.Sync == nil and Sync.name == "Sync", "Sync is part of Core, no module; its settings are kept under the name Sync")
-- Settings an earlier version saved, in a shape this one does not know: nothing of them counts.
SaneUIDB = { modules = { Sync = { options = { camera = false, saved = { camera = { cvars = { cameraSavedDistance = "3" } } } } } },
    newCharacters = { autoLoad = true, profile = "Accountwide" } }
W.Fire("ADDON_LOADED", "SaneUI")
local options = SaneUIDB.modules.Sync.options
check(Sync.options == options and type(options.off) == "table" and type(options.taken) == "table" and type(options.named) == "table"
    and next(options.off) == nil and next(options.taken) == nil, "its settings: parts left to the game, what was read, CVars kept by name")

local ids = {}
for index, part in ipairs(Sync.parts) do ids[part.id] = index end
check(ids.CONTROLS_LABEL and ids.INTERFACE_LABEL and ids.ACTIONBARS_LABEL and ids.COMBAT_LABEL and ids.SOCIAL_LABEL
    and ids.SETTINGS_KEYBINDINGS_LABEL and ids.NAMEPLATE_OPTIONS_LABEL and ids.GRAPHICS_LABEL and ids.AUDIO_LABEL
    and ids.hudLayout and ids.ownChannels and ids.chatFrames and ids.perCharacter, "a part per options page of the game, and for what is on none")
local kept = true
for _, part in ipairs(Sync.parts) do kept = kept and Sync.PartKept(part.id) end
check(kept, "every part is kept at first, also with what an earlier version saved")
check(ids.ownChannels < ids.chatFrames, "a channel of its own is joined before the chat windows are written (a join puts it into the first)")
check(Sync.part.CONTROLS_LABEL.group == "SETTING_GROUP_GAMEPLAY" and Sync.part.GRAPHICS_LABEL.group == "SETTING_GROUP_SYSTEM"
    and Sync.part.COLORS_LABEL.group == "SETTING_GROUP_ACCESSIBILITY" and Sync.part.chatFrames.group == "elsewhere",
    "each in the game's group of its page; the rest elsewhere")
check(Sync.part.CONTROLS_LABEL.text == "Controls" and Sync.part.NAMEPLATE_OPTIONS_LABEL.text == "Nameplate options",
    "named in the game's words, ours where the client lacks them")
-- Data/Pages.lua: Blizzard's options code as this client loads it (game type camelot with the group mainline)
local pageOf = {}
for _, page in ipairs(Sync.PAGES) do
    for _, name in ipairs(page.cvars or {}) do pageOf[name] = page.page end
end
check(ids.PING_SYSTEM_LABEL and pageOf.showSwingTimer == "ADVANCED_OPTIONS_LABEL" and pageOf.questTextContrast == "ACCESSIBILITY_INTERFACE_LABEL"
    and pageOf.motionSicknessFocalCircle == nil, "the pages of the group mainline are there, a file left out for camelot is not")
check(pageOf.floatingCombatTextAuras_v2 == "COMBAT_LABEL" and pageOf.floatingCombatTextSpellMechanicsOther_v2 == "COMBAT_LABEL"
    and pageOf.excludedCensorSources == "SOCIAL_LABEL" and pageOf.GamePadCameraYawSpeed == "GAMEPAD_LABEL",
    "a CVar the options name through a variable: a table's rows, a menu's fields, a local, a function's parameter")

check(Sync.Word == Core.Word, "the game's words: Core's (Kit.lua)")

-- The parts that find their CVars in the game: once a session, a job of Core's scheduler -------------
local steps = Core.Steps.frame
-- Frames of the game: the scheduler's work, until it has none.
local function Settle()
    for _ = 1, 100 do
        if not (steps:IsShown() and steps._scripts.OnUpdate) then return end
        steps._scripts.OnUpdate(steps, 0.016)
    end
end
local graphics, FINDING = Sync.part.GRAPHICS_LABEL, "Sync: the game's CVars"
options.taken.GRAPHICS_LABEL = { cvars = { graphicsQuality = "2" } }
check(graphics.Read() == options.taken.GRAPHICS_LABEL and Core.Steps.Running(FINDING) and W.cvarSets == nil,
    "not found yet: the part keeps what it took, and the game's list is read in a job of the scheduler, not at once")
graphics.Write({ cvars = { graphicsQuality = "3" } })
check(W.cvars.graphicsQuality == nil, "what it is given meanwhile waits")
Settle()
check(W.cvars.graphicsQuality == "3" and not Core.Steps.Running(FINDING), "and is set once they are found")
options.taken, W.cvars.graphicsQuality, W.cvarSets = {}, nil, nil
local function Has(id, name)
    local data = Sync.part[id].Read()
    return type(data) == "table" and type(data.cvars) == "table" and data.cvars[name] ~= nil
end
check(Has("GRAPHICS_LABEL", "graphicsQuality") and not Has("GRAPHICS_LABEL", "gxMonitor") and Has("AUDIO_LABEL", "Sound_EnableReverb"),
    "graphics and sound: the game's own kinds, but not the hardware")
check(not Has("AUDIO_LABEL", "Sound_MasterVolume") and not Sync.SetCVar("Sound_MasterVolume", "0.5")
    and W.cvars.Sound_MasterVolume == nil,
    "nor the settings of the sound profiles (Core's Audio.lua, Sync.Leave): Sync neither reads nor writes them")
check(not Has("GRAPHICS_LABEL", "graphicsFixed") and not Has("AUDIO_LABEL", "soundLocked") and not Has("perCharacter", "secureNote"),
    "nor a CVar the game does not let us set: read only, locked, secure")
check(not Core.Steps.Running(FINDING), "found once a session")
check(Has("perCharacter", "cameraSavedDistance") and Has("perCharacter", "questLogOpen"), "what the game keeps per character")
check(Has("perCharacter", "accountThing"), "and the account's too")
check(not Has("perCharacter", "trackedQuests") and not Has("perCharacter", "lastSelectedTab")
    and not Has("perCharacter", "nameplateSize") and not Has("perCharacter", "debugThing"),
    "not a character's state, not what a page holds, not this computer's alone")

W.Fire("PLAYER_LOGIN")
-- Before the character was given its settings, nothing is read: one that leaves at once spreads nothing.
Sync.Capture()
check(next(options.taken) == nil, "nothing is read before the settings were written into the game")

-- The page Profiles ------------------------------------------------------------------------------
check(Core.pages.Sync == nil and #W.options.pages == 4, "no page of its own: its checkboxes are on the page Profiles")
SettingsPanel:GetScript("OnShow")(SettingsPanel)
local canvas, Config = Core.frames.Profiles, Core.Config
canvas:Show() -- the game shows the page Profiles: it is built then
local function Control(label)
    for _, control in ipairs(Config.Panel.controls) do if control.label == label then return control end end
end
local function Click(control) control:GetScript("OnClick")(control) end
local function Tick(box, on)
    box:SetChecked(on)
    Click(box)
end
local function Shows(words)
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and type(widget._text) == "string" and widget._text:find(words, 1, true) then return true end
    end
    return false
end
local names = {}
for index, tab in ipairs(canvas.tabs) do names[index] = tab.Text._text end
check(table.concat(names, ", ") == "Profiles, Game settings, CVars", "its tabs: Profiles, Game settings, CVars")
check(not Control("General") and not Control("Sync"), "Game settings: no box of Sane UI's modules: all of their settings are in the profile")
check(Shows("Gameplay") and Shows("Accessibility") and Shows("System") and Shows("Elsewhere in the game"),
    "then the game's groups of options pages, and what is on none")
check(Control("Controls") and Control("Nameplate options") and Control("Graphics") and Control("Edit Mode layout")
    and Control("Chat windows") and Control("Your own chat channels") and Control("All other game settings")
    and Control("Controls"):GetChecked(), "a checkbox for each part, showing whether it is kept")
-- The tab CVars (Settings/CVars.lua: the CVars kept by name, through Sync): its list is made when the tab is first
-- shown, released when the page is hidden with it and shown anew when the page shows again: the part's OnHide and
-- OnShow run with its parent's, as the game runs them.
do
    local part = canvas.parts[3]
    Click(canvas.tabs[3])
    local list = part.list
    check(part:IsVisible() and not canvas.parts[1]:IsShown() and list ~= nil, "the tab CVars chosen: its part shown, the others hidden, its list made")
    local inits, releases = 0, 0
    list.Init = function() inits = inits + 1 end
    list.Release = function() releases = releases + 1 end
    canvas:Hide()
    canvas:Show()
    check(releases == 1 and inits == 1 and part.list == list,
        "the page hidden and shown again: the list is released and shown anew with it (the tab's OnHide and OnShow run under the page's)")
    Click(canvas.tabs[1])
end

-- Character A comes into the game: nothing kept yet, so nothing is written --------------------------
-- A slow login: the game has its stored settings only after entering the world. Sane UI waits for them.
local loaded = false
C_CVar.AreCVarsLoaded = function() return loaded end
W.Fire("PLAYER_ENTERING_WORLD", true, false)
W.Wait(2.5)
Sync.Capture()
check(next(options.taken) == nil, "before the game has its own settings nothing is written, and so nothing read")
loaded = true
W.Fire("VARIABLES_LOADED")
W.Wait(2.5)
Sync.Capture()
check(options.taken.CONTROLS_LABEL ~= nil, "once it has them, the settings are written a moment later")
options.taken = {}
check(#game.calls == 0 and #W.popups == 0, "with nothing kept, the game is left as it is")

-- A's own settings, then A logs out: what the kept parts hold is read -------------------------------
W.cvars.autoLootDefault, W.cvars.cameraSmoothStyle, W.cvars.nameplateSize = "1", "1", "2"
W.cvars.cameraSavedDistance, W.cvars.questLogOpen, W.cvars.trackedQuests = "30", "1", "123:456"
game.windows[1].messages = { "SAY", "GUILD", "WHISPER" }
game.windows[1].size, game.windows[2].shown = 12, false
game.channels[#game.channels + 1] = { 3, "Raiders" }
game.channels[#game.channels + 1] = { 4, "Community:1:2", true } -- a community's channel
game.colours.SAY.r = 0.5
C_EditMode.SetActiveLayout(3) -- chosen in Edit Mode
W.Wait(0.1)
game.declineGuild = true
game.bars = { true, true, false }
-- Leaving: the game forgets which Edit Mode layout was in use before the settings are read.
W.Fire("PLAYER_LEAVING_WORLD")
game.loggedOut = true
W.Fire("PLAYER_LOGOUT")
local taken = options.taken
check(taken.CONTROLS_LABEL.cvars.autoLootDefault == "1" and taken.CONTROLS_LABEL.cvars.cameraSmoothStyle == "1",
    "the page Controls: every CVar on it, whoever the game keeps it for")
check(taken.NAMEPLATE_OPTIONS_LABEL.cvars.nameplateSize == "2" and taken.SOCIAL_LABEL.flags.GetAutoDeclineGuildInvites == true,
    "the nameplates, and that guild invitations are declined (a game function the page reads)")
check(taken.SOCIAL_LABEL.flags.GetAllowRecentAlliesSeeLocation == nil, "one this client lacks is left out")
check(taken.perCharacter.cvars.cameraSavedDistance == "30" and taken.perCharacter.cvars.questLogOpen == "1"
    and taken.perCharacter.cvars.trackedQuests == nil, "what the game keeps per character, not what it tracks")
check(taken.GRAPHICS_LABEL.cvars.graphicsQuality == "5" and taken.GRAPHICS_LABEL.cvars.gxMonitor == nil, "graphics, not the hardware")
local tabs = taken.chatFrames.tabs
check(tabs[1].font == 12 and #tabs[1].kinds == 3 and tabs[2].shown == false and taken.chatFrames.colours.SAY.r == 0.5,
    "the chat windows as the game keeps them, and the colours of the kinds of chat")
check(tabs[2].spot[1] == "TOPLEFT" and tabs[2].spot[4] == 300 and tabs[1].spot == nil,
    "where the free windows stand, and their size; not the first, which Edit Mode places")
check(#taken.ownChannels == 1 and taken.ownChannels[1] == "Raiders", "the chat channels of its own: not the game's, not a community's")
check(taken.hudLayout.name == "Mine" and taken.hudLayout.kind == 1,
    "the Edit Mode layout as it was seen in the world (not what the game says at the logout), by its name")
check(taken.ACTIONBARS_LABEL.bars[2] == true and taken.SETTINGS_KEYBINDINGS_LABEL.clicks.SELFCAST == "ALT"
    and taken.SETTINGS_KEYBINDINGS_LABEL.clicks.CHATLINK == "SHIFT", "the action bars shown, the modifier keys of clicks")
local getDecline = GetAutoDeclineGuildInvites
GetAutoDeclineGuildInvites = function() error("renamed in a client update") end
Sync.Capture()
GetAutoDeclineGuildInvites = getDecline
taken = options.taken
check(taken.SOCIAL_LABEL.flags.GetAutoDeclineGuildInvites == true, "a setting the game does not answer stays as it was kept, not off")

-- Character B comes into the game, with the game's settings of its own --------------------------------
Fresh()
W.Fire("PLAYER_ENTERING_WORLD", true, false)
Sync.Give()
check(W.cvars.autoLootDefault == "1" and W.cvars.cameraSmoothStyle == "1" and W.cvars.nameplateSize == "2"
    and W.cvars.cameraSavedDistance == "30" and W.cvars.questLogOpen == "1" and game.declineGuild == true,
    "B is given A's pages, what A kept per character, and its guild invitations")
check(W.cvars.trackedQuests == nil, "not what A tracks")
check(game.windows[1].size == 12 and #game.windows[1].messages == 3 and game.windows[2].shown == false and game.colours.SAY.r == 0.5,
    "A's chat windows and colours, through the game's own settings")
check(game.channels[3][2] == "Raiders" and #game.channels == 3, "A's channel of its own is joined")
check(game.active == 3 and game.bars[2] == true, "A's Edit Mode layout, found by its name, and A's action bars")
local popup = W.popups[#W.popups]
check(popup and popup.which == "GENERIC_CONFIRMATION" and popup.data.text_arg1 == "the Edit Mode layout, the chat windows and the action bars",
    "the game shows chat windows and action bars after a /reload, and its answer to a new layout ran in our call: a reload is offered")
popup.data.callback()
check(W.reloaded, "and reloads")
local colours = Sync.part.chatFrames.Read().colours
colours.SAY.r = 0.9
check(Sync.part.chatFrames.Write({ colours = colours }) == true and game.colours.SAY.r == 0.9,
    "a chat colour alone is a change too: the game's answer to it runs in our call")
colours.SAY.r = 0.5
Sync.part.chatFrames.Write({ colours = colours })

-- A channel's colour: the game keeps it by the channel's number, which another character may give another
-- channel. Kept by the channel's name, it goes to that channel whatever its number there; to one whose join
-- the server answers later, once it is answered, and meanwhile the profile keeps it.
do
    local channelsWere, coloursWere, joinWas, keptWas = game.channels, game.colours, JoinPermanentChannel, options.taken.chatFrames
    game.channels = { { 1, "General" }, { 2, "Trade" }, { 3, "World" } }
    game.colours = { SAY = { r = 1, g = 1, b = 1 }, CHANNEL1 = { r = 1, g = 0.75, b = 0.75 }, CHANNEL3 = { r = 1, g = 0.5, b = 0 },
        CHANNEL4 = { r = 1, g = 1, b = 1 } }
    ChatTypeInfo = game.colours
    local kept = Sync.part.chatFrames.Read()
    check(kept.channels.world.g == 0.5 and kept.channels.world.name == "World" and kept.channels.general and kept.colours.SAY
        and kept.colours.CHANNEL3 == nil and kept.colours.CHANNEL4 == nil,
        "a channel's colour is kept by the channel's name, not its number; a number no channel has keeps none")
    options.taken.chatFrames = kept -- the profile's, as this character leaves it
    -- Another character: LookingForGroup is its third channel, and World it joins in this writing; the server
    -- answers the join later.
    local asked = {}
    JoinPermanentChannel = function(name) asked[#asked + 1] = name end
    game.channels = { { 1, "General" }, { 2, "Trade" }, { 3, "LookingForGroup" } }
    game.colours = { SAY = { r = 1, g = 1, b = 1 }, CHANNEL1 = { r = 1, g = 0.75, b = 0.75 }, CHANNEL3 = { r = 1, g = 1, b = 1 },
        CHANNEL4 = { r = 1, g = 1, b = 1 } }
    ChatTypeInfo = game.colours
    Sync.part.ownChannels.Write({ "World" })
    Sync.part.chatFrames.Write(kept)
    check(asked[1] == "World" and game.colours.CHANNEL3.g == 1 and game.colours.CHANNEL4.g == 1,
        "not joined yet: the colour goes to no channel, not to the number it had")
    check(Sync.part.chatFrames.Read().channels.world.g == 0.5, "read meanwhile (a logout), the profile keeps the channel's colour")
    game.channels[4] = { 4, "World" } -- the join answered: World is this character's fourth channel
    check(Sync.part.chatFrames.Read().channels.world.g == 0.5, "joined, but its colour not given yet: the profile's stays")
    W.Fire("CHANNEL_UI_UPDATE")
    W.Wait(0.1)
    check(game.colours.CHANNEL4.g == 0.5 and game.colours.CHANNEL3.g == 1, "once joined, the channel takes its colour, at its own number")
    check(Sync.part.chatFrames.Read().channels.world.g == 0.5, "and keeps it")
    game.channels[4] = nil -- left again
    check(Sync.part.chatFrames.Read().channels.world.g == 0.5, "a channel this character is not in keeps its colour in the profile")
    -- Kept by a number alone (an older shape), or for a channel this character is not in: given to no channel.
    game.channels[4], game.colours.CHANNEL4 = { 4, "Services" }, { r = 1, g = 1, b = 1 }
    Sync.part.chatFrames.Write({ colours = { CHANNEL4 = { r = 0, g = 0, b = 1 } }, channels = { raiders = { name = "Raiders", r = 0, g = 0, b = 1 } } })
    check(game.colours.CHANNEL4.r == 1 and game.colours.CHANNEL4.b == 1,
        "one kept by its number alone, or of a channel not joined here, is given to none (not to this one's fourth)")
    JoinPermanentChannel, options.taken.chatFrames = joinWas, keptWas
    game.channels, game.colours = channelsWere, coloursWere
    ChatTypeInfo = game.colours
end

-- A window's channels: what a character left stays left, whatever the profile's windows name (Social leaves the
-- public channels on a first load), and one no kept window names is no change: a new character is offered no /reload.
do
    local channelsWere, firstWas, secondWas, ownWas = game.channels, game.windows[1].channels, game.windows[2].channels, options.taken.ownChannels
    local joinWas = JoinPermanentChannel
    local asked, popups = {}, #W.popups
    JoinPermanentChannel = function(name) asked[#asked + 1] = name end
    options.taken.ownChannels = {}
    game.channels, game.windows[1].channels, game.windows[2].channels = { { 1, "Raiders" } }, {}, {}
    local changed = Sync.part.chatFrames.Write({ tabs = { { channels = { "General", "Trade" } } } })
    check(not changed and #game.windows[1].channels == 0 and #asked == 0, "a channel the profile's windows name and this character left is not brought back")
    game.channels, game.windows[1].channels = { { 1, "General" }, { 2, "LocalDefense" } }, { "General", "LocalDefense" }
    changed = Sync.part.chatFrames.Write({ tabs = { { channels = {} }, { channels = {} } } })
    check(not changed and #game.windows[1].channels == 2, "a new character's channels, which no kept window names, stay as the game has them")
    game.channels, game.windows[1].channels = { { 1, "General" }, { 2, "Raiders" } }, { "General", "Raiders" }
    changed = Sync.part.chatFrames.Write({ tabs = { { channels = { "Raiders" } }, { channels = { "General" } } } })
    check(changed and #game.windows[1].channels == 1 and game.windows[1].channels[1] == "Raiders" and game.windows[2].channels[1] == "General",
        "a channel the character is in goes to the kept windows that show it, and leaves the others")
    options.taken.ownChannels = { "World" }
    game.channels, game.windows[2].channels = { { 1, "General" } }, {}
    changed = Sync.part.chatFrames.Write({ tabs = { { channels = {} }, { channels = { "World" } } } })
    check(changed and game.windows[2].channels[1] == "World", "one of the player's own, joined in this same writing, still gets its window")
    check(#W.popups == popups, "the windows' writing itself offers nothing")
    game.channels = { { 1, "Raiders" } } -- the public ones left: read at the logout, the profile has only the player's own
    check(#Sync.part.ownChannels.Read() == 1 and Sync.part.ownChannels.Read()[1] == "Raiders", "the game's channels are never kept as the player's own")
    Sync.part.ownChannels.Write(Sync.part.ownChannels.Read())
    check(#asked == 0, "so a character on the same profile rejoins none of them")
    game.channels, game.windows[1].channels, game.windows[2].channels = channelsWere, firstWas, secondWas
    options.taken.ownChannels, JoinPermanentChannel = ownWas, joinWas
end

-- Taken off every window, a channel the keeping character was in is taken off another's windows too (it once came back
-- from the other character's logout). An own channel left on one character is left on the others; one joined again
-- anywhere is the profile's again. A capture before the server answers a leave does not bring it back.
do
    local channelsWere, firstWas, secondWas, ownWas = game.channels, game.windows[1].channels, game.windows[2].channels, options.taken.ownChannels
    local joinWas, framesWas = JoinPermanentChannel, options.taken.chatFrames
    local asked, left = {}, {}
    JoinPermanentChannel = function(name) asked[#asked + 1] = name end
    LeaveChannelByName = function(name) left[#left + 1] = name end -- answered later: the game lists it meanwhile
    local function Joined(name)
        W.Fire("CHAT_MSG_CHANNEL_NOTICE", "YOU_JOINED", "", "", "4. " .. name, "", "", 0, 4, name)
    end
    -- A: in General and Trade, Trade shown on no window.
    game.channels, game.windows[1].channels, game.windows[2].channels = { { 1, "General" }, { 2, "Trade" } }, { "General" }, {}
    local kept = Sync.part.chatFrames.Read()
    check(kept.joined.general and kept.joined.trade and not kept.joined.raiders, "the windows' part keeps which channels the character was in")
    -- B: the same channels, Trade still on its first window.
    game.windows[1].channels = { "General", "Trade" }
    local changed = Sync.part.chatFrames.Write(kept)
    check(changed and #game.windows[1].channels == 1 and game.windows[1].channels[1] == "General",
        "a channel A was in and showed on no window is taken off B's windows too")
    -- A new character's General, which A had left (Social): no window named it, A was not in it.
    kept.joined.general, kept.tabs[1].channels = nil, {}
    game.windows[1].channels = { "General" }
    changed = Sync.part.chatFrames.Write(kept)
    check(not changed and game.windows[1].channels[1] == "General", "one A was not in and no window names stays as the game has it")

    -- A, in two channels of its own, leaves World; the game's Trade left outside a city is none of the player's.
    options.taken.ownChannels = { "Raiders", "World" }
    game.channels = { { 1, "General" }, { 2, "Trade" }, { 3, "Raiders" } }
    W.Fire("CHANNEL_LEFT", 4, "World")
    W.Fire("CHANNEL_LEFT", 2, "Trade")
    local own = Sync.part.ownChannels.Read()
    check(#own == 1 and own[1] == "Raiders" and own.left and own.left.world == "World" and own.left.trade == nil,
        "an own channel left is kept as left; a game channel left is not")
    game.channels[4] = { 4, "World" }
    Joined("World")
    own = Sync.part.ownChannels.Read()
    check(#own == 2 and own.left == nil, "joined again, it is the profile's again")
    game.channels[4] = nil
    W.Fire("CHANNEL_LEFT", 4, "World")
    own = Sync.part.ownChannels.Read()
    options.taken.ownChannels = own -- A's logout
    -- B, still in World: it leaves it, and joins none of the left.
    game.channels = { { 1, "General" }, { 2, "Raiders" }, { 3, "World" } }
    game.windows[1].channels, game.windows[2].channels = { "General" }, { "World" }
    Sync.part.ownChannels.Write(own)
    check(#left == 1 and left[1] == "World" and #asked == 0, "B leaves the channel A left, as /leave does, and joins nothing")
    local again = Sync.part.ownChannels.Read()
    check(#again == 1 and again[1] == "Raiders" and again.left.world == "World",
        "read before the server answers (a menu opened at once), World is still left: A does not join it again")
    changed = Sync.part.chatFrames.Write({ tabs = { { channels = { "General" } }, { channels = {} } }, joined = { general = true, raiders = true } })
    check(not changed and game.windows[2].channels[1] == "World", "a channel being left is no change to the windows: no /reload for it")
    -- Chat locked down: nothing is left now, the next login leaves it; it still counts as left.
    C_ChatInfo = { InChatMessagingLockdown = function() return true end }
    Sync.part.ownChannels.Write(own)
    C_ChatInfo = nil
    check(#left == 1 and Sync.part.ownChannels.Read().left.world == "World", "while chat is locked down nothing is left, and it stays left")
    -- An older profile, a list alone: joined as before.
    game.channels = { { 1, "General" } }
    Sync.part.ownChannels.Write({ "Raiders" })
    check(#asked == 1 and asked[1] == "Raiders" and #left == 1, "a profile kept before, a list alone, only joins")
    Joined("World")
    game.channels, game.windows[1].channels, game.windows[2].channels = channelsWere, firstWas, secondWas
    options.taken.ownChannels, options.taken.chatFrames, JoinPermanentChannel, LeaveChannelByName = ownWas, framesWas, joinWas, nil
end

-- Again: nothing differs, so nothing is set, and no dialog -----------------------------------------
game.calls, W.cvarSets = {}, 0
local popups = #W.popups
Sync.Give()
check(#game.calls == 0 and W.cvarSets == 0 and #W.popups == popups, "what is the same already is not set again")

-- A profile that holds nothing of a part that finds its CVars: found at the writing all the same, or the logout's
-- reading would only start looking and such a profile would never hold them -----------------------
graphics.names, graphics.has, Sync.options.taken.GRAPHICS_LABEL = nil, nil, nil
Sync.Give()
check(Core.Steps.Running(FINDING), "the writing finds them, whatever the profile holds")
Settle()
Sync.Capture()
check(type(Sync.options.taken.GRAPHICS_LABEL) == "table" and Sync.options.taken.GRAPHICS_LABEL.cvars.graphicsQuality ~= nil,
    "so the next reading saves them")

-- Not in a fight: it waits until the fight is over ------------------------------------------------
W.cvars.cameraSavedDistance = "5"
W.combat = true
Sync.Give()
check(W.cvars.cameraSavedDistance == "5", "in a fight nothing is written")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(W.cvars.cameraSavedDistance == "30", "it follows when the fight is over")

-- Another game's: each game has settings of its own, so what one kept is never written into the other ---
check(Sync.options.from == "forever", "what is kept was read in Forever")
W.cvars.cameraSavedDistance = "7"
W.Play("retail")
Sync.Give()
check(W.cvars.cameraSavedDistance == "7" and Sync.Taken("perCharacter") == nil,
    "in Retail Forever's are neither written nor handed out (a game folder's saved settings copied into the other's)")
Sync.Capture()
check(Sync.options.from == "retail" and Sync.Taken("perCharacter") ~= nil, "Retail's own take their place")
W.Play("forever")
W.cvars.cameraSavedDistance = "30"
Sync.Give()
check(W.cvars.cameraSavedDistance == "30", "and are not written into Forever either")
Sync.Capture()
check(Sync.options.from == "forever", "Forever's own again")

-- A part that is not kept is neither read nor written -------------------------------------------
Tick(Control("All other game settings"), false)
check(options.off.perCharacter == true and not Sync.PartKept("perCharacter"), "unticked, the part is left to the game")
W.cvars.cameraSavedDistance = "8"
Sync.Capture()
check(options.taken.perCharacter == nil, "an unticked part is forgotten when the settings are read")
Sync.Give()
check(W.cvars.cameraSavedDistance == "8", "and not written")
Tick(Control("All other game settings"), true)
check(options.off.perCharacter == nil, "ticked again, it is kept")

-- The modifier keys: kept with the key bindings in use, which the game saves when they changed -------
game.clicks.SELFCAST = "CTRL"
Sync.Give()
check(game.clicks.SELFCAST == "ALT" and game.bindingsSaved == 1, "the modifier keys are given back, the key bindings in use saved")

-- The places of the free chat windows --------------------------------------------------------------
game.places[2] = { "CENTER", 0, 0, 100, 100 }
Sync.Give()
check(game.places[2][1] == "TOPLEFT" and game.places[2][4] == 300, "a free window's place and size are given back")

-- The Edit Mode layout: set only when the game lets us; meanwhile that one counts as in use ----------
taken = options.taken
local function Called(name)
    for _, call in ipairs(game.calls) do if call == name then return true end end
    return false
end
local layouts = game.layouts
-- Early in a login the manager has no layouts yet.
game.layouts, game.calls = nil, {}
taken.hudLayout = { name = "Classic", kind = 0 }
Sync.Give()
check(not Called("SetActiveLayout"), "before Edit Mode's manager has its layouts, none is set")
Sync.Capture()
taken = options.taken
check(taken.hudLayout.name == "Classic", "the one waiting counts as in use: read now, it is kept")
game.layouts = layouts
W.Fire("EDIT_MODE_LAYOUTS_UPDATED")
W.Wait(0.1)
check(game.active == 2 and Called("SetActiveLayout"), "once the manager has them, it is set")
-- Edit Mode open: the player is changing layouts. Core follows it (EditMode.lua).
game.editMode, game.calls = true, {}
EventRegistry:TriggerEvent("EditMode.Enter")
taken = options.taken -- Edit Mode opened: the game's settings read in, the save window's last save (Unsaved.lua)
taken.hudLayout = { name = "Mine", kind = 1 }
Sync.Give()
check(Core.EditMode.active and game.active == 2 and not Called("SetActiveLayout"), "while Edit Mode is open nothing is set")
game.editMode = false
EventRegistry:TriggerEvent("EditMode.Exit")
W.Wait(0.1)
check(game.active == 3, "it is set when Edit Mode closes")
-- One that waits while Edit Mode is open, and the player picks another there: the player's wins.
game.editMode = true
EventRegistry:TriggerEvent("EditMode.Enter")
taken = options.taken -- Edit Mode opened: the game's settings read in, the save window's last save (Unsaved.lua)
taken.hudLayout = { name = "Classic", kind = 0 }
Sync.Give()
C_EditMode.SetActiveLayout(1) -- the player picks Modern in Edit Mode
W.Wait(0.1)
game.editMode = false
EventRegistry:TriggerEvent("EditMode.Exit")
W.Wait(0.1)
Sync.Capture()
taken = options.taken
check(game.active == 1 and taken.hudLayout.name == "Modern", "one waiting gives way to the layout the player picks meanwhile")
check(Core.Unsaved.Pending() and Core.Unsaved.Save(), "what Edit Mode changed waits for the save window: kept (its Yes, Unsaved.lua)")
C_EditMode.SetActiveLayout(3) -- back as it was
W.Wait(0.1)
-- A fight.
game.layouts = nil
taken.hudLayout = { name = "Classic", kind = 0 }
Sync.Give()
game.layouts, W.combat = layouts, true
W.Fire("EDIT_MODE_LAYOUTS_UPDATED")
W.Wait(0.1)
check(game.active == 3, "not in a fight")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0.1)
check(game.active == 2, "but after it")
-- One that is not there (another character's own, or deleted) leaves the one in use, and stays the one kept
-- until the player picks a layout: this character's own does not take its place at its logout, so the
-- character that has it finds it again.
taken.hudLayout = { name = "Raid A", kind = 1 }
Sync.Give()
Sync.Capture()
check(game.active == 2 and options.taken.hudLayout.name == "Raid A", "a layout that is not there leaves the one in use, and is still kept")
W.Fire("PLAYER_LEAVING_WORLD")
game.loggedOut = true
Sync.Capture()
check(options.taken.hudLayout.name == "Raid A", "also at the logout")
game.loggedOut = false
W.Fire("PLAYER_ENTERING_WORLD", false, false)
W.Wait(0.1)
Sync.Capture()
check(options.taken.hudLayout.name == "Raid A", "and after a loading screen")
C_EditMode.SetActiveLayout(1) -- the player picks one in Edit Mode
W.Wait(0.1)
Sync.Capture()
check(options.taken.hudLayout.name == "Modern", "the player picks a layout: that one is kept from now on")

-- Data of a shape this version does not know is left alone, not an error -----------------------------
options.taken.CONTROLS_LABEL, options.taken.chatFrames = 7, "spoiled"
Sync.Give()
check(not Core.errors["Sync: writing CONTROLS_LABEL"] and not Core.errors["Sync: writing chatFrames"], "a spoiled value is skipped")
Sync.Capture()
-- Kept in an older shape: a window without its switches, a colour that is no number, a kind of chat that is
-- no name, a shorter list of the bars. What this version does not know stays as the game has it.
game.calls = {}
local kinds = #game.windows[1].messages
local older = { 5 }
for _, kind in ipairs(game.windows[1].messages) do older[#older + 1] = kind end
check(Sync.part.chatFrames.Write({ tabs = { { title = game.windows[1].name, tint = { "dark" }, kinds = older } },
    colours = { SAY = { r = "white" } } }) == false and #game.calls == 0 and #game.windows[1].messages == kinds,
    "chat windows of an older shape: nothing set, no reload")
game.bars = { true, true, false }
check(Sync.part.ACTIONBARS_LABEL.Write({ bars = { false } }) == true and game.bars[1] == false and game.bars[2] == true
    and game.bars[3] == false, "a shorter list of bars: the bars it does not name stay as they are")
check(Sync.part.ACTIONBARS_LABEL.Write({ bars = { 1, "on" } }) == false and game.bars[1] == false, "nor one that is not true or false")

-- What the game does not let us set is left alone; one it does not take is noted once, the rest written --
local setCVar = C_CVar.SetCVar
C_CVar.SetCVar = function(name, value)
    if name == "accountThing" then error("the game refused it") end
    return setCVar(name, value)
end
local guarded = { "graphicsFixed", "soundLocked", "accountThing", "debugThing" }
for _, name in ipairs(guarded) do Sync.Keep(name, true) end
options.named.graphicsFixed, options.named.soundLocked, options.named.accountThing, options.named.debugThing = "0", "0", "5", "4"
W.printed = {}
Sync.Give()
Sync.Give()
local noted = Core.errors["Sync: setting CVars"]
check(W.cvars.debugThing == "4" and W.cvars.graphicsFixed == nil and W.cvars.soundLocked == nil and W.cvars.accountThing == nil,
    "read only and locked CVars are left alone, and the others are written all the same")
check(noted and noted.count == 1 and noted.text:find("accountThing") and #W.printed == 0,
    "one the game does not take is noted once, quietly, and not tried again")
W.combat = true
check(Sync.SetCVar("secureNote", "1") == false and W.cvars.secureNote == nil, "a secure CVar is not set in a fight")
W.combat = false
check(Sync.SetCVar("secureNote", "1") == true and W.cvars.secureNote == "1", "out of it, it is")
C_CVar.SetCVar = setCVar
Core.errors["Sync: setting CVars"] = nil
for _, name in ipairs(guarded) do Sync.Keep(name, false) end
W.cvars.debugThing, W.cvars.secureNote = nil, nil

-- CVars kept by name (the options' CVar list) --------------------------------------------------------
Sync.Keep("debugThing", true)
check(Sync.Kept("debugThing") and options.named.debugThing == "0", "a CVar kept by name is kept with its value now, though no part holds it")
W.cvars.debugThing = "3"
Sync.Capture()
check(options.named.debugThing == "3", "read like the parts")
W.cvars.debugThing = "0"
Sync.Give()
check(W.cvars.debugThing == "3", "and written like them")
Config.CVars.Keep("debugThing", false)
check(not Sync.Kept("debugThing") and options.named.debugThing == nil, "the CVar list unticks it through Sync")

-- A value the game hides (a secret value, as the 12.x client hands some out): read as nothing, never written, never
-- a secret in the saved settings: what Sync reads of the game goes through Core.Plain ---------------------------
do
    local getCVar, getInfo = C_CVar.GetCVar, C_CVar.GetCVarInfo
    C_CVar.GetCVar = function(name) if name == "debugThing" then return W.Secret() end return getCVar(name) end
    C_CVar.GetCVarInfo = function(name)
        if name == "debugThing" then return W.Secret(), select(2, getInfo(name)) end
        return getInfo(name)
    end
    W.cvars.debugThing = "2"
    check(Sync.Value("debugThing") == nil and Sync.Settable("debugThing") == nil and Sync.SetCVar("debugThing", "4") == false
        and W.cvars.debugThing == "2" and Core.errors["Sync: setting CVars"] == nil,
        "a CVar whose value the game hides reads as nothing, and is not written (the game would refuse it)")
    Sync.Keep("debugThing", true)
    Sync.Capture()
    Sync.Give()
    check(options.named.debugThing == false and W.cvars.debugThing == "2",
        "kept by name, the profile holds false for it until it can be read, never the secret, and writes nothing")
    C_CVar.GetCVar, C_CVar.GetCVarInfo = getCVar, getInfo
    Sync.Keep("debugThing", false)
    W.cvars.debugThing = nil
end

-- A standard profile's CVars (Presets.lua) -----------------------------------------------------------
do
    local preset = Core.Presets.profiles.Speedleveling.Sync.named
    for name, value in pairs(preset) do
        options.named[name] = value
        if name ~= "instantQuestText" then W.cvarInfo[name] = { default = "x" } end
    end
    Sync.Give()
    local written = true
    for name, value in pairs(preset) do
        if name ~= "instantQuestText" and W.cvars[name] ~= value then written = false end
    end
    check(written and W.cvars.instantQuestText == nil and Core.errors["Sync: setting CVars"] == nil,
        "written at the first login, none of its parts read yet; one this game lacks is passed over, quietly")
    W.cvars.maxFPS = "60"
    Sync.Capture()
    W.cvars.maxFPS = "30"
    Sync.Give()
    check(options.named.maxFPS == "60" and W.cvars.maxFPS == "60" and options.named.instantQuestText == preset.instantQuestText,
        "what the player sets afterwards is the profile's; the other game's stays for that game")
    for name in pairs(preset) do options.named[name], W.cvarInfo[name], W.cvars[name] = nil, nil, nil end
end

-- The bug hunt (card #377): SaneUIDB.hunt holds Sync's writing back ---------------------------------
do
    for _, name in ipairs({ "huntThing", "keptThing" }) do
        options.named[name], W.cvarInfo[name], W.cvars[name] = "4", { default = "x" }, "3"
    end
    SaneUIDB.hunt = true
    Sync.Give()
    W.cvars.huntThing = "2"
    Sync.Capture()
    check(W.cvars.huntThing == "2" and W.cvars.keptThing == "3", "true: Sync writes none of the game's settings")
    check(options.named.huntThing == "4", "and reads nothing back: the profile keeps what it holds")
    SaneUIDB.hunt = { "huntThing" }
    Sync.Give()
    check(W.cvars.huntThing == "2" and W.cvars.keptThing == "4", "a list: those CVars alone are held, the rest written")
    W.cvars.keptThing = "5"
    Sync.Capture()
    check(options.named.huntThing == "4" and options.named.keptThing == "5", "the held one is not read back either")
    -- /sane hunt: one setting of the profile at a time, where the player stands.
    options.named.shownThing, W.cvarInfo.shownThing, W.cvars.shownThing = "4", { default = "x" }, "3"
    SaneUIDB.hunt = true
    local function Said(text)
        for _, line in ipairs(W.printed) do if line:find(text, 1, true) then return true end end
        return false
    end
    W.printed = {}
    SlashCmdList.SANEUI("hunt")
    check(Said("shownThing is 3, the profile has 4") and not Said("keptThing is"), "/sane hunt: the CVars kept by name the game differs in")
    W.printed = {}
    SlashCmdList.SANEUI("hunt SHOWNTHING")
    check(W.cvars.shownThing == "4" and W.cvars.keptThing == "5" and Said("shownThing set to 4 (was 3)"),
        "/sane hunt shownThing: that one written at once, in any letter case, the rest left")
    W.printed = {}
    SlashCmdList.SANEUI("hunt shownThing nothingKept huntThing")
    check(Said("shownThing is 4 already") and Said("nothingKept is neither kept by name nor a part")
        and Said("huntThing is held back by the list") and W.cvars.huntThing == "2",
        "one as the profile has it, one unknown, one held by a list earlier: said, and the held one stays")
    W.cvars.shownThing = "3"
    SlashCmdList.SANEUI("hunt named")
    Sync.Capture()
    check(W.cvars.shownThing == "4" and options.named.shownThing == "4" and options.named.keptThing == "5",
        "named: every CVar kept by name; nothing read back while the hunt holds Sync")
    options.named.shownThing, W.cvarInfo.shownThing, W.cvars.shownThing = nil, nil, nil
    SaneUIDB.hunt = nil
    for _, name in ipairs({ "huntThing", "keptThing" }) do options.named[name], W.cvarInfo[name], W.cvars[name] = nil, nil, nil end
end

-- Water detail: never set, read back or kept (card #377) ----------------------------------------------
do
    for _, name in ipairs({ "waterDetail", "graphicsLiquidDetail" }) do W.cvarInfo[name], W.cvars[name] = { default = "2" }, "2" end
    options.named.waterDetail = "3"
    check(Sync.Barred("WATERDETAIL") and Sync.Barred("RAIDWaterDetail") and Sync.Barred("graphicsLiquidDetail")
        and Sync.Barred("raidGraphicsLiquidDetail") and not Sync.Barred("shadowMode"), "water detail and the Liquid Detail behind it are barred")
    local now, free, why = Sync.Settable("waterDetail")
    check(now == "2" and free == false and why == "barred", "the game's value shown, not to be set")
    check(not Sync.SetCVar("waterDetail", "3") and W.cvars.waterDetail == "2", "never set")
    Sync.Give()
    Sync.part.GRAPHICS_LABEL.Write({ cvars = { graphicsLiquidDetail = "3" } })
    check(W.cvars.waterDetail == "2" and W.cvars.graphicsLiquidDetail == "2", "not by name, not by a part, even if a profile holds it")
    Sync.Capture()
    check(options.named.waterDetail == nil, "never saved: a profile that holds it loses it at the next capture")
    check(type(options.taken.GRAPHICS_LABEL) ~= "table" or type(options.taken.GRAPHICS_LABEL.cvars) ~= "table"
        or options.taken.GRAPHICS_LABEL.cvars.graphicsLiquidDetail == nil, "nor read into a part")
    Sync.Keep("waterDetail", true)
    check(options.named.waterDetail == nil, "nor kept by name when ticked")
    for _, name in ipairs({ "waterDetail", "graphicsLiquidDetail" }) do W.cvarInfo[name], W.cvars[name] = nil, nil end
end

-- Profiles read and write the game's settings too ------------------------------------------------
local Profiles = Core.Profiles
W.cvars.nameplateSize = "3"
check(Profiles.Create("Big") and SaneUIDB.profiles.Big.Sync.taken.NAMEPLATE_OPTIONS_LABEL.cvars.nameplateSize == "3",
    "a new profile keeps the game's settings of the kept parts, as they are this moment")
check(Profiles.Use("Big") and Profiles.InUse() == "Big", "the character uses it")
W.cvars.nameplateSize = "1"
check(Profiles.Use("Accountwide") and W.cvars.nameplateSize == "3",
    "back to Accountwide: what was set meanwhile went into Big, and Accountwide's own are written into the game at once")
check(SaneUIDB.profiles.Big.Sync.taken.NAMEPLATE_OPTIONS_LABEL.cvars.nameplateSize == "1", "Big kept what was set while it was in use")
Profiles.Use("Big")
check(W.cvars.nameplateSize == "1", "and gives it back when it is used again")
C_EditMode.SetActiveLayout(3)
W.Wait(0.1)
Profiles.Create("Mine")
C_EditMode.SetActiveLayout(1)
W.Wait(0.1)
check(SaneUIDB.profiles.Mine.Sync.taken.hudLayout.name == "Mine", "a profile keeps the Edit Mode layout in use")
Profiles.Use("Mine")
check(game.active == 3, "used, its layout is set again")

-- Character specific: the game's settings back at its defaults, then left to the game --------------
W.cvars.nameplateSize = "2"
Sync.Keep("debugThing", true)
W.cvars.debugThing = "3"
Profiles.Use(Profiles.OWN)
check(SaneUIDB.profiles.Mine.Sync.taken.NAMEPLATE_OPTIONS_LABEL.cvars.nameplateSize == "2",
    "the game's settings as they are go into the profile left, read while Sync still keeps them")
check(W.cvars.nameplateSize == W.cvarInfo.nameplateSize.default, "and the game holds its defaults, as on a fresh install")
check(W.cvars.debugThing == W.cvarInfo.debugThing.default, "those kept by name too, which no part reads")
W.cvars.nameplateSize = "4"
local sets = W.cvarSets
Sync.Give()
W.Fire("PLAYER_LOGOUT")
check(W.cvars.nameplateSize == "4" and W.cvarSets == sets and SaneUIDB.profiles.Mine.Sync.taken.NAMEPLATE_OPTIONS_LABEL.cvars.nameplateSize == "2",
    "off, nothing of the game's is written or read, not even at the logout")
check(SaneUICharDB.settings and SaneUICharDB.settings.Sync == nil, "nor kept with the character's own settings")
Profiles.Use("Mine")
check(Profiles.InUse() == "Mine" and W.cvars.nameplateSize == "2", "back on the profile, the character takes its settings, the game's too")
-- Turned to Character specific in a fight: the game's settings are left as they are until the fight is over
-- (Core.AfterCombat; a secure CVar the game would refuse), then they go to their defaults.
W.Combat(true)
Profiles.Use(Profiles.OWN)
check(W.cvars.nameplateSize == "2" and Core.Owed("Sync: defaults"), "turned to Character specific in a fight: the game keeps its settings until the fight is over")
W.Combat(false)
check(W.cvars.nameplateSize == W.cvarInfo.nameplateSize.default and not Core.Owed("Sync: defaults"), "over, they are at their defaults")
Profiles.Use("Mine")
check(W.cvars.nameplateSize == "2", "and the profile's again when it is used again")

-- The key bindings: every key by its command, written where they differ, saved in the game's set ---
do
    local list = { { "HEADER_MOVE" }, { "JUMP", "Jump", "SPACE" }, { "MOVEFORWARD", "Move", "W", "UP" }, { "SITORSTAND", "Sit" } }
    local saved, loaded = {}, nil
    GetNumBindings = function() return #list end
    GetBinding = function(index) return unpack(list[index]) end
    SetBinding = function(key, command)
        for _, line in ipairs(list) do
            for at = #line, 3, -1 do if line[at] == key then table.remove(line, at) end end
            if line[1] == command then line[#line + 1] = key end
        end
    end
    GetCurrentBindingSet = function() return 2 end
    SaveBindings = function(set) saved[#saved + 1] = set end
    LoadBindings = function(set) loaded = set end
    local part = Sync.part.keyBindings
    local read = part.Read()
    check(read.JUMP[1] == "SPACE" and read.MOVEFORWARD[2] == "UP" and read.SITORSTAND == false and read.HEADER_MOVE == nil,
        "what is bound, by command; false for a command seen without a key; nothing for a header")
    part.Write({ JUMP = { "BUTTON4" }, SITORSTAND = { "X" }, MOVEFORWARD = { "W", "UP" } })
    check(list[2][3] == "BUTTON4" and list[2][4] == nil and list[4][3] == "X" and saved[1] == 2, "written where they differ, saved in the set in use")
    part.Write({ JUMP = { "BUTTON4" }, SITORSTAND = { "X" }, MOVEFORWARD = { "W", "UP" } })
    check(#saved == 1, "nothing differs: nothing saved")
    part.Write({ JUMP = { "BUTTON4" }, MOVEFORWARD = { "W", "UP" } })
    check(list[4][3] == "X", "a command the profile has never seen (bound here, none where it was captured) keeps its keys")
    part.Write({ JUMP = { "BUTTON4" }, MOVEFORWARD = { "W", "UP" }, SITORSTAND = false })
    check(list[4][3] == nil, "a command the profile saw without a key is unbound here")
    list[4][3] = "X"
    part.Write({ JUMP = { "X" }, MOVEFORWARD = { "W", "UP" } })
    check(list[2][3] == "X" and list[2][4] == nil and list[4][3] == nil, "one of its keys the profile wants elsewhere is moved there all the same")
    options.taken.keyBindings = { OTHERADDON = { "F9" } }
    check(part.Read().OTHERADDON[1] == "F9", "a command this client does not list keeps its keys")
    part.Default()
    check(loaded == 0 and saved[#saved] == 2, "with no profile: the game's own keys, saved in the character's set")
    GetCurrentBindingSet = function() return 1 end
    local saves = #saved
    loaded = nil
    part.Default()
    check(loaded == nil and #saved == saves, "with the account's set in use they are left as they are: that set is every character's")
    GetCurrentBindingSet = function() return 2 end
    options.taken.keyBindings = nil
    loaded = nil
    Sync.Give()
    check(loaded == nil, "a login with no keys in the profile: the keys stay as the game has them")
    Profiles.Reset()
    check(loaded == nil, "Defaults on the page Profiles (Sane UI's settings only, the game's stay): the keys stay too")
    Sync.Moved()
    check(loaded == 0, "come over from another profile: the game's own keys, not the keys of the one left")
    local count = GetNumBindings
    GetNumBindings = function() return 0 end
    Sync.Capture()
    loaded = nil
    Sync.Moved()
    check(loaded == nil, "come over with the same settings (a copy of this profile): the keys stay")
    GetNumBindings = count
    -- Turning to Character specific: the game's own keys again only if the profile held them and the part is kept
    Sync.KeepPart("keyBindings", false)
    loaded = nil
    Profiles.Use(Profiles.OWN)
    check(loaded == nil, "Character specific with Key bindings unticked: the keys are left as they are")
    Profiles.Use("Mine")
    Sync.KeepPart("keyBindings", true)
    loaded = nil
    Profiles.Use(Profiles.OWN)
    check(loaded == 0, "ticked, the profile holding keys: the game's own again")
    Profiles.Use("Mine")
    GetNumBindings, GetBinding, SetBinding, GetCurrentBindingSet, SaveBindings, LoadBindings = nil, nil, nil, nil, nil, nil
end

-- A layout a character does not have comes from the profile's text of it
do
    local layouts = { layouts = { { layoutName = "Mine", layoutType = 1 } }, activeLayout = 3 }
    local added, savedAll
    local stubs = { "ConvertLayoutInfoToString", "ConvertStringToLayoutInfo", "GetLayouts", "IsValidLayoutName", "SaveLayouts", "OnLayoutAdded" }
    local was = {}
    for _, name in ipairs(stubs) do was[name] = C_EditMode[name] end
    C_EditMode.ConvertLayoutInfoToString = function(layout) return "text of " .. layout.layoutName end
    C_EditMode.ConvertStringToLayoutInfo = function(text) return { from = text } end
    C_EditMode.GetLayouts = function() return layouts end
    C_EditMode.IsValidLayoutName = function(name) return name ~= "bad" end
    C_EditMode.SaveLayouts = function(all) savedAll = all end
    C_EditMode.OnLayoutAdded = function(index, activate) added = { index, activate } end
    local part = Sync.part.hudLayout
    check(part.Write({ name = "Theirs", kind = 2, text = "their text" }) == true, "not there: added, a /reload due")
    check(savedAll == layouts and layouts.layouts[2].from == "their text" and layouts.layouts[2].layoutName == "Theirs"
        and layouts.layouts[2].layoutType == 2 and added[2] == true, "saved through the game, its name and kind, made the one in use")
    check(part.Write({ name = "bad", kind = 1, text = "x" }) == false, "one that cannot be added: the layout in use stays")
    check(part.Write({ name = "Nothing", kind = 1 }) == false, "nor one without its text")
    added = nil
    check(part.Write({ name = "Nowhere", kind = 0, text = "preset text" }) == false and added == nil,
        "nor one of the game's own kind (a preset), whatever text it comes with")
    C_EditMode.SaveLayouts = function() error("not now") end
    check(part.Write({ name = "Other", kind = 1, text = "other text" }) == false and added == nil,
        "one the game does not save is not made the one in use")
    for _, name in ipairs(stubs) do C_EditMode[name] = was[name] end
end

-- The addons switched on: kept in the profile, written with a /reload offered -----------------------
do
    local states = { One = 2, Two = 0, SaneUI = 2 }
    local names = { "One", "Two", "SaneUI" }
    local saved = 0
    C_AddOns = C_AddOns or {}
    local wasNum, wasInfo, wasState, wasOn, wasOff, wasSave = C_AddOns.GetNumAddOns, C_AddOns.GetAddOnInfo, C_AddOns.GetAddOnEnableState,
        C_AddOns.EnableAddOn, C_AddOns.DisableAddOn, C_AddOns.SaveAddOns
    C_AddOns.GetNumAddOns = function() return #names end
    C_AddOns.GetAddOnInfo = function(which) return type(which) == "number" and names[which] or (states[which] and which) or nil end
    C_AddOns.GetAddOnEnableState = function(name) return states[name] end
    C_AddOns.EnableAddOn = function(name) states[name] = 2 end
    C_AddOns.DisableAddOn = function(name) states[name] = 0 end
    C_AddOns.SaveAddOns = function() saved = saved + 1 end
    local part = Sync.part.addons
    local read = part.Read()
    check(read.One == true and read.Two == false and read.SaneUI == true, "which addons are on, read")
    check(part.Write({ One = false, Two = true, SaneUI = false, Gone = true }) == true and states.One == 0 and states.Two == 2,
        "written as the profile has them: a /reload is due")
    check(states.SaneUI == 2 and states.Gone == nil and saved == 1, "never Sane UI itself, nor one this client lacks")
    check(part.Write({ One = false, Two = true }) == false and saved == 1, "nothing to change: nothing asked")
    -- Switched on the character screen since this character's last logout (Sync.Outside): the profile takes it, so
    -- the login does not switch it back; one the profile changed meanwhile (on another character) stays the profile's.
    check(Core.Profiles.On() and Sync.options.from == Core.GAME, "a profile of this game in use")
    local taken, character = Sync.options.taken, Core.Character(Sync.name)
    local wasTaken, wasLogout = taken.addons, character.logout
    states.One, states.Two = 2, 2 -- the game now: One switched on at the character screen, Two on as at the logout
    taken.addons = { One = false, Two = false, SaneUI = true }
    character.logout = { addons = { One = false, Two = true, SaneUI = true } }
    Sync.Outside()
    check(taken.addons.One == true and taken.addons.Two == false, "switched on the character screen: the profile takes it; its own change stays")
    check(part.Write(taken.addons) == true and states.One == 2 and states.Two == 0, "the login's writing keeps it, writes the profile's")
    character.logout, taken.addons.One = nil, false
    Sync.Outside()
    check(taken.addons.One == false, "no logout kept (a first login): the profile's as before")
    -- The profile changed One after this character's logout (on another character): its word is newer than what this
    -- character brings, so a change on the character screen seen only now is passed over
    local stamps = Sync.options.stamps
    local wasStamps = stamps.addons
    states.One, states.Two = 2, 2
    taken.addons = { One = false, Two = true, SaneUI = true }
    character.logout = { at = 100, addons = { One = false, Two = true, SaneUI = true } }
    stamps.addons = { One = 200 }
    Sync.Outside()
    check(taken.addons.One == false, "the profile changed it after this character's logout: the profile's stays")
    stamps.addons = { One = 50 }
    Sync.Outside()
    check(taken.addons.One == true and stamps.addons.One > 100, "the profile's older: the character's change taken, stamped now")
    -- A capture stamps what changed in the profile
    stamps.addons = {}
    states.One = 0
    Sync.Capture()
    check(Sync.options.taken.addons.One == false and type(stamps.addons.One) == "number" and stamps.addons.Two == nil,
        "a capture stamps the addon that changed, only that one")
    stamps.addons, Sync.options.taken.addons, character.logout = wasStamps, wasTaken, wasLogout
    C_AddOns.GetNumAddOns, C_AddOns.GetAddOnInfo, C_AddOns.GetAddOnEnableState, C_AddOns.EnableAddOn, C_AddOns.DisableAddOn, C_AddOns.SaveAddOns =
        wasNum, wasInfo, wasState, wasOn, wasOff, wasSave
end

-- A CVar a module lends (Loot: the game's Auto Loot off) -----------------------------------------------
W.cvars.autoLootDefault = "1"
check(Sync.Lend("autoLootDefault", "0") and W.cvars.autoLootDefault == "0", "lent: the game holds the module's value")
SaneUIDB.profiles.Mine.Sync.taken.CONTROLS_LABEL.cvars.autoLootDefault = "1"
Sync.Give()
check(W.cvars.autoLootDefault == "0", "the profile's own written meanwhile does not undo the lend")
Sync.Capture()
check(Sync.options.taken.CONTROLS_LABEL.cvars.autoLootDefault == "1", "read: the player's own value goes into the profile")
check(Sync.Value("autoLootDefault") == "1" and C_CVar.GetCVar("autoLootDefault") == "0", "Sync.Value: the player's own")
Sync.Return("autoLootDefault")
check(W.cvars.autoLootDefault == "1", "given back: the player's own again")
Sync.Lend("autoLootDefault", "0", "1")
W.cvars.autoLootDefault = "1" -- the player set it on meanwhile, in the game's own options
Sync.Return("autoLootDefault")
check(W.cvars.autoLootDefault == "1", "changed meanwhile: left as the player set it")

-- A /reload that settled nothing is not offered again ---------------------------------------------------
-- The next login, with the game on that layout at the time of the writing.
local function Login(active)
    Sync.Began()
    game.active = active
    local before = #W.popups
    Sync.Give()
    return #W.popups - before
end
Sync.options.taken.hudLayout = { name = "Mine", kind = 1 }
check(Login(3) == 0, "a login with nothing to change, after all that went before")
check(Login(1) == 1 and game.active == 3, "the kept layout set at a login: a /reload is offered")
check(W.popups[#W.popups].data.text_arg1 == "the Edit Mode layout", "for that alone")
check(Login(1) == 0 and game.active == 3, "the game on its own one again at the next: set again, the same /reload, which settled nothing, not offered")
local settled = Core.errors["Sync: a /reload settled nothing"]
check(settled and settled.text == "the Edit Mode layout: Mine set: it is number 3, Edit Mode's manager had 1, the game said nil",
    "the error log says so, with what the game said")
Core.errors["Sync: a /reload settled nothing"] = nil
check(Login(1) == 0, "nor at the one after")
Core.errors["Sync: a /reload settled nothing"] = nil
check(Login(3) == 0 and Login(1) == 1, "a login with nothing to change ends that: the next one is new")
Sync.Began()
game.active = 1
local popups = #W.popups
Sync.Moved()
check(#W.popups == popups + 1, "another profile's writing is new too, whatever the login before offered")

-- The save window (Unsaved.lua, Settings/Save.lua): changes in the menus kept or taken back -------------
do
    local Unsaved = Core.Unsaved
    W.Wait(1)
    local use = Profiles.InUse()
    local other = use == "Accountwide" and "Speedleveling" or "Accountwide"
    local function Errors() return Core.Settings(Core.name).errors end
    local function Window() return rawget(_G, "SaneUISaveChanges") end
    local function Lists(words) return Window() and Window().List._text:find(words, 1, true) ~= nil end
    -- A frame for the change to be shown (Config.RefreshSoon), then the moment it is looked at (Unsaved.Soon).
    local function Frames() W.Wait(0.1) W.Wait(0.4) end

    Core.Set(Core.name, "errors", not Errors())
    Frames()
    check(not Unsaved.Pending() and not (Window() and Window():IsShown()), "a change with no menu open is no change for the save window")
    SettingsPanel:Show() -- the game's options open: the settings as they are now are the last save
    local was, cvar = Errors(), W.cvars.cameraSmoothStyle
    Core.Set(Core.name, "errors", not was)
    Frames()
    check(Unsaved.Pending() and Window() and Window():IsShown() and Lists("General: Errors in chat"),
        "a switch set in the options: the save window comes, beside them, and lists it")
    check(rawget(Window(), "CloseButton") == nil or not Window().CloseButton:IsShown(), "no close button: it stays until Yes or No")
    Core.Set(Core.name, "errors", was)
    Frames()
    check(not Unsaved.Pending() and not Window():IsShown(), "set back by hand: nothing to save, the window goes")

    -- A switch and one of the game's settings, saved into the profile in use and one ticked besides
    Core.Set(Core.name, "errors", not was)
    W.cvars.cameraSmoothStyle = cvar == "2" and "3" or "2"
    W.Fire("CVAR_UPDATE", "cameraSmoothStyle", W.cvars.cameraSmoothStyle)
    Frames()
    check(Lists("General: Errors in chat") and Lists("Game settings: Controls"), "the game's options page of a CVar that changed is listed too")
    check(Unsaved.Ticked(use) and not Unsaved.Ticked(other) and tContains(Unsaved.Targets(), other)
        and not tContains(Unsaved.Targets(), Profiles.OWN), "Save to: the profile in use ticked at first; Character specific only while in use")
    Unsaved.Tick(other, true)
    check(SaneUIDB.saveTo[other] == true, "a profile ticked besides is kept for the next time")
    local new = W.cvars.cameraSmoothStyle
    check(not Profiles.Use(other) and Profiles.InUse() == use and Unsaved.Next() == "Then the profile " .. other .. " is used.",
        "another profile waits for the answer, which the window names")
    check(Window().After._text == Unsaved.Next(), "the window says what follows")
    Window().Yes:GetScript("OnClick")(Window().Yes)
    local saved = SaneUIDB.profiles[other]
    check(saved.Core.errors == not was and saved.Sync.taken.CONTROLS_LABEL.cvars.cameraSmoothStyle == new,
        "Yes: the changes are in the profile ticked besides, the game's setting too")
    check(Profiles.InUse() == other and not Unsaved.Pending() and not Window():IsShown(), "then the profile that waited is used")
    check(SaneUIDB.profiles[use].Core.errors == not was, "and the profile left kept them")
    use, other = other, use

    -- No: back as at the last save, the game's settings written into the game
    Frames()
    local before, game, theirs = Errors(), W.cvars.cameraSmoothStyle, SaneUIDB.profiles[other].Core.errors
    Core.Set(Core.name, "errors", not before)
    W.cvars.cameraSmoothStyle = game == "2" and "3" or "2"
    W.Fire("CVAR_UPDATE", "cameraSmoothStyle", W.cvars.cameraSmoothStyle)
    Frames()
    check(Unsaved.Pending() and Unsaved.Ticked(use), "the profile in use ticked again")
    Unsaved.Tick(other, true)
    Window().No:GetScript("OnClick")(Window().No)
    check(Errors() == before and W.cvars.cameraSmoothStyle == game and not Unsaved.Pending(),
        "No: every change taken back, the game's setting written back into the game")
    check(SaneUIDB.profiles[other].Core.errors == theirs, "and no profile ticked was written")

    -- Unticked, the profile in use gets its settings back; the one ticked takes them
    Frames()
    local mine = Errors()
    Core.Set(Core.name, "errors", not mine)
    Frames()
    Unsaved.Tick(use, false)
    Unsaved.Tick(other, false)
    check(not Unsaved.Any() and not Window().Yes:IsEnabled() and not Unsaved.Save() and Unsaved.Pending(),
        "none ticked: Yes is off, nothing to save to")
    Unsaved.Tick(other, true)
    check(Window().Yes:IsEnabled(), "one ticked: Yes is on")
    Unsaved.Save()
    check(Errors() == mine and SaneUIDB.profiles[other].Core.errors == not mine and not Unsaved.Pending(),
        "Yes with the profile in use unticked: the one ticked takes the change, the one in use is back as it was")

    -- The page Profiles: Save and Load last settings, only while there are changes
    local load, keep = Control("Load last settings"), Control("Save")
    Config.Refresh()
    check(load and keep and not load:IsEnabled() and not keep:IsEnabled(), "the page Profiles: Save and Load last settings, off with nothing to save")
    Frames()
    local now = Errors()
    Core.Set(Core.name, "errors", not now)
    Frames()
    Frames()
    check(load:IsEnabled() and keep:IsEnabled(), "on while there are changes")
    Click(load)
    W.popups[#W.popups].data.callback()
    check(Errors() == now and not Unsaved.Pending(), "Load last settings asks first, then takes every change back")
    Frames()
    Core.Set(Core.name, "errors", not now)
    Frames()
    Click(keep)
    check(Errors() == not now and not Unsaved.Pending() and SaneUIDB.profiles[use].Core.errors == not now, "Save keeps them")

    -- A /reload Sane UI offers waits for nothing: the /reload saves the changes, as every /reload does (below)
    Frames()
    Core.Set(Core.name, "errors", now)
    Frames()
    W.reloaded = nil
    Core.AskReload({ "something" })
    W.popups[#W.popups].data.callback()
    check(W.reloaded == true and Unsaved.Next() == nil and Unsaved.Pending(), "a /reload offered with changes unsaved: at once, nothing waits")
    Unsaved.Undo()
    check(Errors() == not now and not Unsaved.Pending(), "No takes them back")
    W.reloaded = nil

    -- A /reload or logout unanswered saves the changes as Yes does (Saneroki, 2026-11-10: a change must not pop back
    -- at a /reload): Sane UI's switch, the game's setting, an addon switched off in the game's addon list, into the
    -- profile in use and the one ticked besides
    Frames()
    SettingsPanel:Hide()
    check(not Unsaved.Pending(), "nothing waits")
    local names, states, stubbed = { "One", "SaneUI" }, { One = 2, SaneUI = 2 }, {}
    for _, name in ipairs({ "GetNumAddOns", "GetAddOnInfo", "GetAddOnEnableState", "DisableAddOn", "SaveAddOns" }) do stubbed[name] = C_AddOns[name] end
    C_AddOns.GetNumAddOns = function() return #names end
    C_AddOns.GetAddOnInfo = function(which) return type(which) == "number" and names[which] or (states[which] and which) or nil end
    C_AddOns.GetAddOnEnableState = function(name) return states[name] end
    C_AddOns.DisableAddOn = function(name) states[name] = 0 end
    C_AddOns.SaveAddOns = function() end
    SettingsPanel:Show()
    Core.Set(Core.name, "errors", now)
    local camera = W.cvars.cameraSmoothStyle == "2" and "3" or "2"
    W.cvars.cameraSmoothStyle = camera
    W.Fire("CVAR_UPDATE", "cameraSmoothStyle", camera)
    Frames()
    SettingsPanel:Hide()
    Unsaved.Open("addons") -- the game's addon list (its OnShow)
    C_AddOns.DisableAddOn("One")
    Unsaved.Soon() -- its AddonList_Update
    Frames()
    Unsaved.Close("addons") -- its OnHide: Reload UI hides it, then reloads
    check(Unsaved.Pending() and Window():IsShown() and Lists("General: Errors in chat") and Lists("Game settings: Controls")
        and Lists("Game settings: Addons"), "the menus closed: the window stays and lists the switch, the setting and the addon")
    Unsaved.Tick(other, true)
    W.Fire("PLAYER_LOGOUT")
    local mine, ticked = SaneUIDB.profiles[use], SaneUIDB.profiles[other]
    check(mine.Core.errors == now and mine.Sync.taken.CONTROLS_LABEL.cvars.cameraSmoothStyle == camera and mine.Sync.taken.addons.One == false,
        "unanswered at the logout: saved in the profile in use, the game's setting and the addon too")
    check(ticked.Core.errors == now and ticked.Sync.taken.CONTROLS_LABEL.cvars.cameraSmoothStyle == camera and ticked.Sync.taken.addons.One == false,
        "and in the profile ticked besides")
    check(Core.Character(Sync.name).logout.addons.One == false and type(Core.Character(Sync.name).logout.at) == "number",
        "the addons as the logout left them, and when, for the next login (Sync.Outside)")
    Unsaved.Save()

    -- Unticked, the profile in use gets the last save back at the logout, in the saved settings only
    Frames()
    SettingsPanel:Show()
    Core.Set(Core.name, "errors", not now)
    Frames()
    Unsaved.Tick(use, false)
    Unsaved.Tick(other, true)
    W.Fire("PLAYER_LOGOUT")
    check(SaneUIDB.profiles[use].Core.errors == now and SaneUIDB.profiles[other].Core.errors == not now,
        "unticked in use at the logout: back as at the last save; the one ticked takes the change")
    Unsaved.Tick(use, true)
    Unsaved.Undo()

    -- The profile in use renamed while changes wait: still ticked, under its new name, and Yes keeps them
    Frames()
    check(Profiles.Create("Hunt A") and Profiles.Use("Hunt A") and Profiles.InUse() == "Hunt A", "a profile of our own in use")
    Frames()
    local before = Errors()
    Core.Set(Core.name, "errors", not before)
    Frames()
    check(Unsaved.Ticked("Hunt A"), "the profile in use ticked")
    check(Profiles.Rename("Hunt A", "Hunt B") and Unsaved.Ticked("Hunt B") and not Unsaved.Ticked("Hunt A"),
        "renamed: ticked under its new name")
    Unsaved.Save()
    check(Errors() == not before and SaneUIDB.profiles["Hunt B"].Core.errors == not before and not Unsaved.Pending(),
        "Yes keeps the change in the profile renamed (was: taken back, the old name ticked)")
    check(Profiles.Use(use) and Profiles.InUse() == use, "back to the profile of before")

    -- A profile ticked besides, then deleted: no tick left for it; with the one in use unticked, Yes is off
    Frames()
    Core.Set(Core.name, "errors", not Errors())
    Frames()
    Unsaved.Tick("Hunt B", true)
    Unsaved.Tick(use, false)
    Unsaved.Tick(other, false)
    check(Unsaved.Any() and SaneUIDB.saveTo["Hunt B"] == true, "ticked besides, for the next time too")
    check(Profiles.Delete("Hunt B") and not Unsaved.Any() and not Window().Yes:IsEnabled() and SaneUIDB.saveTo["Hunt B"] == nil,
        "deleted: its tick gone, Yes off")
    Unsaved.Tick(use, true)
    Unsaved.Undo()

    -- Another profile chosen while changes wait, then a /reload unanswered: that answers too, so the character uses
    -- the profile chosen from its next login (its line names it); the settings in use stay where they are till then
    Frames()
    Core.Set(Core.name, "errors", not Errors())
    Frames()
    local mineKey
    for key in pairs(SaneUIDB.characters) do
        local line = Profiles.Character(key)
        if line and line.current then mineKey = key end
    end
    check(mineKey and not Profiles.Use(other) and Unsaved.Next() == "Then the profile " .. other .. " is used.", "another profile waits")
    W.Fire("PLAYER_LOGOUT")
    check(SaneUIDB.characters[mineKey].profile == other and Profiles.InUse() == use and Unsaved.Next() == nil,
        "a /reload unanswered: the profile chosen is the character's at its next login")
    SaneUIDB.characters[mineKey].profile = use -- as the rest of this test has it
    Unsaved.Save()
    SettingsPanel:Hide()
    for name, fn in pairs(stubbed) do C_AddOns[name] = fn end
end

-- The save window's No after Edit Mode: the layout takes its own text again
do
    local layouts = { layouts = { { layoutName = "Mine", layoutType = 1 } }, activeLayout = 3 }
    local saved
    local was = {}
    for _, name in ipairs({ "ConvertLayoutInfoToString", "ConvertStringToLayoutInfo", "GetLayouts", "SaveLayouts" }) do was[name] = C_EditMode[name] end
    C_EditMode.ConvertLayoutInfoToString = function(layout) return "now " .. layout.layoutName end
    C_EditMode.ConvertStringToLayoutInfo = function(text) return { from = text } end
    C_EditMode.GetLayouts = function() return layouts end
    C_EditMode.SaveLayouts = function(all) saved = all end
    local part = Sync.part.hudLayout
    part.Write({ name = "Mine", kind = 1, text = "before" })
    check(saved == nil, "a layout the character has keeps its own text when a profile is used")
    Sync.ExactLayout()
    check(part.Write({ name = "Mine", kind = 1, text = "before" }) == true and saved == layouts and layouts.layouts[1].from == "before"
        and layouts.layouts[1].layoutName == "Mine" and layouts.layouts[1].layoutType == 1,
        "after No: its text from the last save, saved through the game, a /reload due")
    saved = nil
    part.Write({ name = "Mine", kind = 1, text = "again" })
    check(saved == nil, "once")
    for name, fn in pairs(was) do C_EditMode[name] = fn end
end

local problems = {}
for label, problem in pairs(Core.errors) do problems[#problems + 1] = label .. ": " .. tostring(problem.text) end
check(#problems == 0, "nothing went wrong on the way: " .. table.concat(problems, "; "))

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Sync: all %d checks passed.\n"):format(passed))
