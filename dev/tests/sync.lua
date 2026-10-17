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
        debugThing = { default = "0", category = 0 },
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
local Core = SaneUI.Core
local Sync = Core.Sync
check(Sync and SaneUI.Sync == nil and Sync.name == "Sync", "Sync is part of Core, no module; its settings are kept under the name Sync")
-- Settings an earlier version saved, in a shape this one does not know: nothing of them counts.
SaneUIDB = { modules = { Sync = { options = { camera = false, saved = { camera = { cvars = { cameraSavedDistance = "3" } } } } } } }
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

-- The parts that find their CVars in the game
local function Has(id, name)
    for _, known in ipairs(Sync.CVarsOf(id)) do if known == name then return true end end
    return false
end
check(Has("GRAPHICS_LABEL", "graphicsQuality") and not Has("GRAPHICS_LABEL", "gxMonitor") and Has("AUDIO_LABEL", "Sound_MasterVolume"),
    "graphics and sound: the game's own kinds, but not the hardware")
check(Has("perCharacter", "cameraSavedDistance") and Has("perCharacter", "questLogOpen"), "what the game keeps per character")
check(not Has("perCharacter", "trackedQuests") and not Has("perCharacter", "lastSelectedTab") and not Has("perCharacter", "accountThing")
    and not Has("perCharacter", "nameplateSize") and not Has("perCharacter", "debugThing"),
    "not a character's state, not the account's, not what a page holds")

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
check(table.concat(names, ", ") == "Profiles, Accountwide, CVars", "its tabs: Profiles, Accountwide, CVars")
check(Shows("Sane UI") and Control("General") and not Control("Sync"), "Accountwide: first a box Sane UI with Sane UI's modules (not Sync)")
check(Shows("Gameplay") and Shows("Accessibility") and Shows("System") and Shows("Elsewhere in the game"),
    "then the game's groups of options pages, and what is on none")
check(Control("Controls") and Control("Nameplate options") and Control("Graphics") and Control("Edit Mode layout")
    and Control("Chat windows") and Control("Your own chat channels") and Control("Other per-character settings")
    and Control("Controls"):GetChecked(), "a checkbox for each part, showing whether it is kept")

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

-- Again: nothing differs, so nothing is set, and no dialog -----------------------------------------
game.calls, W.cvarSets = {}, 0
local popups = #W.popups
Sync.Give()
check(#game.calls == 0 and W.cvarSets == 0 and #W.popups == popups, "what is the same already is not set again")

-- Not in a fight: it waits until the fight is over ------------------------------------------------
W.cvars.cameraSavedDistance = "5"
W.combat = true
Sync.Give()
check(W.cvars.cameraSavedDistance == "5", "in a fight nothing is written")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(W.cvars.cameraSavedDistance == "30", "it follows when the fight is over")

-- A part that is not kept is neither read nor written -------------------------------------------
Tick(Control("Other per-character settings"), false)
check(options.off.perCharacter == true and not Sync.PartKept("perCharacter"), "unticked, the part is left to the game")
W.cvars.cameraSavedDistance = "8"
Sync.Capture()
check(options.taken.perCharacter == nil, "an unticked part is forgotten when the settings are read")
Sync.Give()
check(W.cvars.cameraSavedDistance == "8", "and not written")
Tick(Control("Other per-character settings"), true)
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
-- Edit Mode open: the player is changing layouts.
game.editMode, game.calls = true, {}
taken.hudLayout = { name = "Mine", kind = 1 }
Sync.Give()
check(game.active == 2 and not Called("SetActiveLayout"), "while Edit Mode is open nothing is set")
game.editMode = false
EventRegistry:TriggerEvent("EditMode.Exit")
W.Wait(0.1)
check(game.active == 3, "it is set when Edit Mode closes")
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
-- One that is not there (deleted, or another character's own) leaves the one in use.
taken.hudLayout = { name = "Gone", kind = 1 }
Sync.Give()
Sync.Capture()
check(game.active == 2 and options.taken.hudLayout.name == "Classic", "a layout that is not there leaves the one in use, which is read then")

-- Data of a shape this version does not know is left alone, not an error -----------------------------
options.taken.CONTROLS_LABEL, options.taken.chatFrames = 7, "spoiled"
Sync.Give()
check(not Core.errors["Sync: writing CONTROLS_LABEL"] and not Core.errors["Sync: writing chatFrames"], "a spoiled value is skipped")
Sync.Capture()

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

-- Profiles read and write the game's settings too ------------------------------------------------
W.cvars.nameplateSize = "3"
Core.Profiles.Save("Big")
check(SaneUIDB.profiles.Big.Sync.taken.NAMEPLATE_OPTIONS_LABEL.cvars.nameplateSize == "3", "a profile keeps the game's settings of the kept parts")
W.cvars.nameplateSize = "1"
Sync.Capture()
Core.Profiles.Load("Big")
check(W.cvars.nameplateSize == "3", "loading it writes them into the game at once")
C_EditMode.SetActiveLayout(3)
W.Wait(0.1)
Core.Profiles.Save("Mine")
C_EditMode.SetActiveLayout(1)
W.Wait(0.1)
check(SaneUIDB.profiles.Mine.Sync.taken.hudLayout.name == "Mine", "a profile keeps the Edit Mode layout in use")
Core.Profiles.Load("Mine")
check(game.active == 3, "loaded, its layout is set again")

local problems = {}
for label, problem in pairs(Core.errors) do problems[#problems + 1] = label .. ": " .. tostring(problem.text) end
check(#problems == 0, "nothing went wrong on the way: " .. table.concat(problems, "; "))

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Sync: all %d checks passed.\n"):format(passed))
