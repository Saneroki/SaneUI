-- Runs Core's onboarding (src/Core/Onboarding.lua) and the addon Onboarding (src/Onboarding) against the stand-in
-- client (wowstub.lua), with a small module made here that hands in a setup of three steps: the window read only when
-- a setup opens (load on demand), by itself the first time (after the game's What's new, out of a fight, once), by
-- /sane setup and after a fight; the steps, their words and controls made from the module's own switches, set
-- through Core; Back, Next and Done; the module's sample drawn anew after each change; a setup kept where it was
-- left and as gone through with its version; all setups to go through one after another (the run) after its first
-- page, a version raised, Choose defaults.
-- Nameplates' own setup (its steps and sample plates) is tested in dev/tests/nameplates.lua.
-- Usage, from the project folder:  lua5.1 dev/tests/onboarding.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function printed(pattern)
    for _, line in ipairs(W.printed) do if line:find(pattern, 1, true) then return true end end
    return false
end

W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local Core = SaneUI.Core
local Onboarding = Core.Onboarding
check(Onboarding and Onboarding.ADDON == "SaneUI_Onboarding", "Core knows the setup's addon")

-- The addon list: Onboarding loaded on demand, switched off for now.
local listed = { name = "SaneUI_Onboarding", title = "Onboarding", notes = "", loadable = false, reason = "DEMAND_LOADED",
                 enabled = 0, metadata = { Version = "1.2.3" } }
W.addons[#W.addons + 1] = listed
local read = 0
local ons -- the addon's own table, once read
W.onDemand.SaneUI_Onboarding = function()
    read = read + 1
    ons = W.LoadAddon(root, "Onboarding", "SaneUI_Onboarding")
end

-- A module of three steps: a switch, a number and one of a few, with a switch under one of the choices.
local garden = Core.NewModule("SaneUI_Garden", "Garden", {})
Core.Options("Garden", {
    { key = "setup", text = "Set up step by step", button = function() Onboarding.Open("Garden") end },
    { key = "flowers", default = true, text = "Flowers", tip = "Flowers in the beds." },
    { key = "height", default = 75, min = 0, max = 100, step = 5, unit = "%", text = "Hedge height", tip = "How tall." },
    { key = "path", default = "gravel", choices = { { "gravel", "Gravel" }, { "stone", "Stone" } }, text = "Path",
      tip = "What the path is made of." },
    { key = "moss", default = false, parent = "path", parentValue = "stone", text = "Moss between the stones" },
    { key = "pond", default = "topleft", text = "Pond", tip = "Where the pond is.",
      choices = { { "topleft", "Top left" }, { "top", "Top center" }, { "topright", "Top right" }, { "left", "Left" },
                  { "right", "Right" }, { "bottomleft", "Bottom left" }, { "bottom", "Bottom center" },
                  { "bottomright", "Bottom right" } } },
    { key = "kept", default = {} },
    { key = "reset", text = "Reset the garden", button = function() end },
})
local drawn = {}
Onboarding.Add("Garden", {
    title = "Garden",
    steps = {
        { key = "beds", title = "The beds", text = "What grows.", settings = { "flowers", "kept", "reset" } },
        { key = "hedge", title = "The hedge", text = "How tall it is.",
          settings = { "height", { key = "pond", around = true, beside = true } } },
        { key = "path", title = "The path", text = "What you walk on.", settings = { "path", "moss" } },
        { key = "keys", title = "Keys", text = "Keys for it.",
          settings = { { binding = "SANEUI_GARDEN_WATER", text = "Water the garden" },
                       { binding = "SANEUI_GARDEN_LIGHT", text = "Light the lamps" } } },
    },
    Stage = function(stage, step, index) drawn[#drawn + 1] = { stage = stage, key = step.key, index = index } end,
})
check(Onboarding.Guide("Garden") ~= nil and Onboarding.Names()[1] == "Garden", "a module hands in its setup")
Onboarding.Add("Nothing", { title = "No steps" })
check(Onboarding.Guide("Nothing") == nil and Core.errors["onboarding"] ~= nil, "a setup without steps is refused, noted")

-- The game's key bindings: a key bound to one command; saved by SaveBindings.
bound, saved, shift, alt, ctrl = {}, 0, false, false, false
GetBindingKey = function(command)
    local keys = {}
    for key, action in pairs(bound) do if action == command then keys[#keys + 1] = key end end
    table.sort(keys)
    return unpack(keys)
end
SetBinding = function(key, command) bound[key] = command; return true end
SaveBindings = function() saved = saved + 1 end
GetCurrentBindingSet = function() return 2 end
GetBindingAction = function(key) return bound[key] or "" end
GetBindingText = function(key) return key end
IsShiftKeyDown = function() return shift end
IsAltKeyDown = function() return alt end
IsControlKeyDown = function() return ctrl end
W.Fire("ADDON_LOADED", "SaneUI_Garden")
W.Fire("PLAYER_LOGIN")
local options = Core.Settings("Garden")

-- The addon switched off: nothing read, the player told where to switch it on.
W.printed = {}
SlashCmdList.SANEUI("setup garden")
check(read == 0 and printed(Onboarding.TEXT.missing), "Onboarding switched off: not read, and said so")
SlashCmdList.SANEUI("setup roses")
check(printed("no setup called roses") and printed("Garden"), "a setup that is not there: the ones there are named")

-- The first time, by itself: a few seconds after the loading screen, not while the game's own What's new is open.
listed.enabled = 2
SplashFrame = CreateFrame("Frame")
SplashFrame:Show()
W.Fire("PLAYER_ENTERING_WORLD")
W.Wait(Onboarding.WAIT + 1)
check(read == 0, "the game's What's new is open: the setup waits")
SplashFrame:Hide()
W.Wait(Onboarding.WAIT + 1)
check(read == 1 and ons and ons.Window.Frame():IsShown(), "then the window is read and shows the run's first page")
local store = Core.Store("Onboarding")
local window = ons.Window
local parts = window.Parts()
check(parts.first and parts.head._text == ons.TEXT.firstHead and parts.title._text == ons.TEXT.firstTitle
    and parts.words._text == ons.TEXT.firstText, "the first page: please go through them, and where they are found again")
check(parts.list:IsShown() and parts.rows[1]:IsShown() and parts.rows[1].label._text == "Garden"
    and parts.rows[1].steps._text == "4 steps" and parts.rows[1].button:IsShown() and not parts.rows[1].state:IsShown(),
    "a row for each setup to go through: its name, its steps, Choose defaults")
check(parts.count._text == ons.TEXT.oneLeft and parts.forward._text:find(ons.TEXT.start, 1, true)
    and parts.back:IsEnabled() == false and not parts.defaults:IsShown() and parts.logo:IsVisible(),
    "under them: how many are left and Start; Sane UI's logo on the stage")
local explained = parts.explained
check(parts.logo._texture == ons.Window.LOGO and ons.Window.LOGO:find("SaneUI_Onboarding", 1, true),
    "the plain Sane UI logo, the Onboarding addon's own (not Core's banner)")
check(not explained.head:IsShown() and not explained.swap:IsShown() and not explained.own:IsShown()
    and not explained.menu:IsShown() and not explained.menuText:IsShown(),
    "no module that is on has a classic window's button, a full screen's red buttons or kept choices: none of them")

-- A module that has them (Saneroki: "On addons that do have those icons should show them on the onboarding"): a
-- window with the button with the circling arrows and two kept choices, and a full screen whose window can stand alone.
local hearth = { left = false, chosen = {} }
local HEARTH = {
    { text = "The game's fire", checked = function() return hearth.left end,
      show = function() hearth.left = true; hearth.chosen[#hearth.chosen + 1] = "show" end,
      back = function() hearth.left = false; hearth.chosen[#hearth.chosen + 1] = "back" end },
    { text = "Open the kettle", show = function() hearth.chosen[#hearth.chosen + 1] = "kettle" end } } -- no kept choice
local fakeWindow = { options = { title = "Hearth", native = { show = function() end }, classic = HEARTH },
                     frame = CreateFrame("Frame") }
local All = Core.Window.All
Core.Window.All = function() local all = All() all[#all + 1] = fakeWindow return all end
check(Core.Board.Apart() == false, "no full screen yet: no window can stand alone")
Core.Board.New(fakeWindow, { label = "Hearth", windows = function()
    return { { key = "logs", title = "Logs", apart = false }, { key = "pot", title = "Pot" } } end })
check(Core.Board.Apart() == true, "a full screen with a window that can stand alone (apart = false and fit cannot)")
local kept = Core.Classic.Kept()
check(#kept == 1 and kept[1].window == fakeWindow and #kept[1].entries == 1 and kept[1].entries[1] == HEARTH[1],
    "the kept choices: an entry with checked, not the one that only opens the game's window")
window.Close()
Onboarding.Start(true)
parts = window.Parts()
explained = parts.explained
local has = ons.Window.Has()
check(has.swap and has.own and has.kept and explained.head:IsShown() and explained.head._text == ons.TEXT.windows,
    "now they show, under their head")
check(explained.swap:IsShown() and explained.swap.picture._texture == "Interface\\Buttons\\UI-RefreshButton"
    and explained.swap:GetScale() == ons.Window.SWAP_SCALE and explained.swapText._text == ons.TEXT.swap,
    "the button with the circling arrows itself, larger, and what it does")
check(explained.own:IsShown() and explained.back:IsShown() and explained.ownText._text == ons.TEXT.alone
    and explained.backText._text == ons.TEXT.onto and explained.own:GetScale() == ons.Window.SWAP_SCALE
    and parts.back:GetText():find(ons.TEXT.back, 1, true) and not parts.back:GetText():find("onto", 1, true),
    "the red buttons beside a full screen window's X: its own window, and back onto the full screen")
check(explained.menu:IsShown() and explained.menu._kind == "DropdownButton" and explained.menuText._text == ons.TEXT.classic,
    "the dropdown Classic windows, with what it chooses")
check(explained.own._points[1][5] < explained.swap._points[1][5] * explained.swap:GetScale()
    and explained.menu._points[1][5] < explained.back._points[1][5] * explained.back:GetScale(),
    "one under another")
-- The dropdown works: its menu the kept choices, a tick each; chosen, the game's kept, again, Sane UI's.
local menu = { titles = {}, boxes = {} }
function menu:CreateTitle(text) self.titles[#self.titles + 1] = text end
function menu:CreateCheckbox(text, ticked, chosen)
    self.boxes[#self.boxes + 1] = { text = text, ticked = ticked, chosen = chosen }
end
Core.Classic.KeptMenu(menu)
check(menu.titles[1] == "Hearth" and #menu.boxes == 1 and menu.boxes[1].text == "The game's fire"
    and menu.boxes[1].ticked() == false, "its menu: the window's name, a tick for its kept choice, not ticked")
menu.boxes[1].chosen()
check(hearth.left and menu.boxes[1].ticked() == true and hearth.chosen[1] == "show", "ticked: the game's own kept")
menu.boxes[1].chosen()
check(not hearth.left and menu.boxes[1].ticked() == false and hearth.chosen[2] == "back" and #hearth.chosen == 2,
    "ticked again: Sane UI's again; nothing else opened")
Core.Window.All = All
window.Close()
Onboarding.Start(true)
parts = window.Parts()
check(parts.explained.head:IsShown() and parts.explained.own:IsShown() and not parts.explained.swap:IsShown()
    and not parts.explained.menu:IsShown(), "that window gone, its full screen left: only the red buttons")
check(store.done.Garden == nil and store.left.Garden == nil, "nothing kept yet")
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()
check(not parts.first and not parts.list:IsShown() and not parts.logo:IsVisible(), "Start: the setup, the first page gone")
check(store.done.Garden == nil and store.left.Garden == 1, "not gone through yet: kept where it was left, for the account")
check(not Onboarding.Done("Garden") and Onboarding.Due()[1] == "Garden", "still to go through")
check(parts.head._text == "Garden: setup", "a run of one: no count in the head")
check(parts.defaults:IsShown(), "Choose defaults, for a setup not gone through yet")
check(parts.note._text:find(ons.TEXT.unfinished, 1, true)
    and parts.note._text:find(ons.TEXT.again:format("Garden"), 1, true),
    "the note: closed before its end it comes back; where to start it again (the options page's button)")
check(parts.title._text == "The beds" and parts.words._text == "What grows.", "the first step: its head and words")
check(parts.count._text == "Step 1 of 4", "Step 1 of 4")
check(parts.back:IsEnabled() ~= false, "Back on the first step of a run's setup")
parts.back._scripts.OnClick(parts.back)
check(window.Parts().first and window.Parts().rows[1].label._text == "Garden", "Back: the first page again")
window.Parts().forward._scripts.OnClick(window.Parts().forward)
parts = window.Parts()
check(parts.title._text == "The beds", "and Start: the setup where it was left")
check(drawn[#drawn].key == "beds" and drawn[#drawn].index == 1 and drawn[#drawn].stage ~= nil, "the module drew its sample")
check(drawn[#drawn].stage == parts.own.Garden and parts.own.Garden:GetParent() == parts.stage and parts.own.Garden:IsShown(),
    "into a frame of its own over the stage: what another module drew never shows under it")

-- The first step's controls: the switch alone (kept values and buttons have none).
local holder = parts.made.Garden[1]
check(#holder.rows == 1 and holder.rows[1].option.key == "flowers", "a control per switch with words, none for the rest")
local tick = holder.rows[1].tick
check(tick:GetChecked() == true, "the tick shows the value in use")
local before = #drawn
tick:SetChecked(false)
tick._scripts.OnClick(tick)
check(options.flowers == false, "a click sets the module's switch through Core")
check(#drawn == before + 1, "and the sample is drawn anew")

-- Next: the number.
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()
check(parts.title._text == "The hedge" and parts.count._text == "Step 2 of 4" and parts.back:IsEnabled() ~= false
    and parts.progress.share == 0.5,
    "Next: the second step, Back there")
check(drawn[#drawn].key == "hedge", "its sample")
check(not parts.made.Garden[1]:IsShown() and parts.made.Garden[2]:IsShown(), "only the step's own controls show")
local number = parts.made.Garden[2].rows[1]
check(number.slider ~= nil, "a number has the game's slider")
Core.Set("Garden", "height", 40)
window.Changed()
check(ons.Controls.Value(number.option, 40) == "40%", "its value with its unit")
check(ons.Controls.Value({ unit = "%", offAt = 100 }, 100) == "Off" and ons.Controls.Value({ unit = "%", offAt = 100 }, 95) == "95%",
    "a slider with offAt says Off there, its number below it")
-- Places round a bar (around), beside the number (beside): a round button at each, at the right of the slider's row.
local pond = parts.made.Garden[2].rows[2]
check(pond and #pond.rounds == 8 and pond.bar ~= nil and pond._points[1][1] == "TOPRIGHT"
    and pond._points[1][5] == number._points[1][5] and number._width < parts.made.Garden[2]._width - pond._width,
    "places round a small bar, beside the number on its row, the number narrower")
check(pond.rounds[1].button:GetChecked() == true and pond.rounds[1].button._points[1][5] == 0
    and pond.rounds[7].button._points[1][5] < pond.rounds[4].button._points[1][5]
    and pond.rounds[4].button._points[1][5] < 0 and pond.rounds[4].button._points[1][4] == 0
    and pond.rounds[5].button._points[1][4] > pond.rounds[3].button._points[1][4],
    "top left lit; over, beside and under the bar in three rows, left and right beyond its ends")
pond.rounds[7].button._scripts.OnClick(pond.rounds[7].button)
check(options.pond == "bottom" and pond.rounds[7].button:GetChecked() == true and pond.rounds[1].button:GetChecked() == false,
    "a click on the one under the middle: Bottom center, set through Core")

-- The last: one of a few, and a switch under one of them, greyed out until it is chosen.
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()
local path, moss = parts.made.Garden[3].rows[1], parts.made.Garden[3].rows[2]
check(#path.rounds == 2 and path.rounds[1].button:GetChecked() == true, "a round button per choice, the one in use lit")
check(path.rounds[1].button._points[1][5] == path.rounds[2].button._points[1][5]
    and path.rounds[2].button._points[1][4] > path.rounds[1].button._points[1][4], "two choices side by side, on one line")
check(moss.tick:IsEnabled() == false, "the switch under Stone greyed out while the path is gravel")
path.rounds[2].button._scripts.OnClick(path.rounds[2].button)
check(options.path == "stone" and moss.tick:IsEnabled() ~= false, "Stone chosen: set, and the switch under it usable")
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()

-- The last: two keys, in the game's own key bindings: a click, then the key with the modifiers held; Esc keeps it; a
-- right click unbinds it. No box takes the keyboard itself: in the game a frame with an OnKeyDown script has it and
-- passes no key on, so the top box of a step kept every key from the box clicked. The one listener has it while a
-- box waits, and only then.
local key, lamps = parts.made.Garden[4].rows[1], parts.made.Garden[4].rows[2]
local function Listener() return ons.Controls.listener end
local function Press(name) Listener()._scripts.OnKeyDown(Listener(), name) end
local function Free() return Listener()._scripts.OnKeyDown == nil and not Listener():IsShown() end
check(key.box._scripts.OnKeyDown == nil and lamps.box._scripts.OnKeyDown == nil, "no box takes the keyboard")
check(key.label._text == ons.Controls.TEXT.unbound and key.box ~= nil, "a key without one: Not bound")
key.box._scripts.OnClick(key.box, "LeftButton")
check(key.box.listening and key.label._text == ons.Controls.TEXT.press, "clicked: it waits for a key")
check(Listener() and Listener()._scripts.OnKeyDown ~= nil and Listener():IsShown(), "the listener hears the keys")
Press("LSHIFT")
check(key.box.listening, "a modifier alone is no key")
shift = true
Press("F")
shift = false
check(not key.box.listening and bound["SHIFT-F"] == "SANEUI_GARDEN_WATER" and saved == 1 and key.label._text == "SHIFT-F",
    "Shift-F: bound to it, the game's bindings saved")
check(Free(), "bound: the keyboard back to the game")
key.box._scripts.OnClick(key.box, "LeftButton")
lamps.box._scripts.OnClick(lamps.box, "LeftButton")
check(not key.box.listening and key.label._text == "SHIFT-F" and lamps.box.listening, "one box waits at a time")
Press("LALT")
Press("LSHIFT")
alt, shift = true, true
Press("V")
alt, shift = false, false
check(bound["ALT-SHIFT-V"] == "SANEUI_GARDEN_LIGHT" and bound["SHIFT-F"] == "SANEUI_GARDEN_WATER"
    and lamps.label._text == "ALT-SHIFT-V" and Free(), "Alt-Shift-V: the second box's key, the first one's kept")
lamps.box._scripts.OnClick(lamps.box, "LeftButton")
lamps.box._scripts.OnClick(lamps.box, "MiddleButton")
check(bound.BUTTON3 == "SANEUI_GARDEN_LIGHT" and bound["ALT-SHIFT-V"] == nil and not lamps.box.listening,
    "the middle mouse button while it waits: BUTTON3")
lamps.box._scripts.OnClick(lamps.box, "LeftButton")
ctrl = true
lamps.box._scripts.OnClick(lamps.box, "Button4")
ctrl = false
check(bound["CTRL-BUTTON4"] == "SANEUI_GARDEN_LIGHT" and Free(), "Ctrl and a side button: CTRL-BUTTON4")
CreateKeyChordStringUsingMetaKeyState = function(pressed) return "META-" .. pressed end
check(ons.Controls.Chord("V") == "META-V" and ons.Controls.Chord("LMETA") == nil, "the game's own chord, where it has one")
CreateKeyChordStringUsingMetaKeyState = nil
lamps.box._scripts.OnClick(lamps.box, "LeftButton")
lamps.box._scripts.OnHide(lamps.box)
check(not lamps.box.listening and Free(), "hidden while it waits: the keyboard let go")
bound.G = "MOVEFORWARD"
key.box._scripts.OnClick(key.box, "LeftButton")
W.printed = {}
Press("G")
check(bound.G == "SANEUI_GARDEN_WATER" and bound["SHIFT-F"] == nil and printed("no longer does: MOVEFORWARD"),
    "another key: the old one let go, the key's other command said")
key.box._scripts.OnClick(key.box, "LeftButton")
Press("ESCAPE")
check(not key.box.listening and bound.G == "SANEUI_GARDEN_WATER" and Free(), "Esc: kept as it was")
key.box._scripts.OnClick(key.box, "RightButton")
check(bound.G == nil and key.label._text == ons.Controls.TEXT.unbound, "a right click: no key")
W.combat = true
key.box._scripts.OnClick(key.box, "LeftButton")
check(not key.box.listening, "in a fight keys stay as they are")
W.combat = false
check(parts.forward._text == ons.TEXT.done and parts.progress.share == 1, "the last step: the bar full, its button Done")
check(store.left.Garden == 4 and not Onboarding.Done("Garden"), "each step kept as where it was left")
parts.forward._scripts.OnClick(parts.forward)
check(not window.Frame():IsShown(), "Done closes the window; what was chosen stays")
check(Onboarding.Done("Garden") and store.done.Garden.version == 1 and type(store.done.Garden.day) == "string"
    and store.left.Garden == nil and #Onboarding.Due() == 0, "gone through: kept with its version and day")
check(options.path == "stone" and options.flowers == false, "the choices are the module's settings now")

-- Asked for again: /sane setup (the only one there: its name not needed), at the first step; in a fight, after it.
SlashCmdList.SANEUI("setup")
check(window.Frame():IsShown() and window.Parts().count._text == "Step 1 of 4", "/sane setup opens it again, at the start")
check(not window.Parts().note._text:find(ons.TEXT.unfinished, 1, true) and not window.Parts().defaults:IsShown(),
    "gone through: the note no longer says it comes back, and no Choose defaults")
check(window.Parts().back:IsEnabled() == false, "opened by hand: no Back on the first step")
window.Parts().forward._scripts.OnClick(window.Parts().forward)
check(store.left.Garden == nil, "a setup gone through keeps no step")
window.Close()
W.printed = {}
W.Combat(true)
SlashCmdList.SANEUI("setup Garden")
check(not window.Frame():IsShown() and printed(Onboarding.TEXT.later), "in a fight it waits, and says so")
W.Combat(false)
check(window.Frame():IsShown(), "after the fight it opens")
check(read == 1, "the addon read once")
window.Close()

-- A switch the step words its own way (Navigation's hot corner): its round buttons, one under another, set as the
-- switch is; a key the module does not describe has no control.
local worded = ons.Controls.Build(UIParent, "Garden", {
    { key = "flowers", text = "What grows", choices = { { true, "Flowers" }, { false, "Only grass" } }, column = true },
    { key = "weeds", text = "Weeds", choices = { { true, "Yes" } } } }, 300)
local grows = worded.rows[1]
check(#worded.rows == 1 and grows.option.text == "What grows" and grows.option.default == true and #grows.rounds == 2,
    "a step's own words over the switch: its choices as round buttons")
check(grows.rounds[2].button._points[1][4] == grows.rounds[1].button._points[1][4]
    and grows.rounds[2].button._points[1][5] < grows.rounds[1].button._points[1][5], "one under another (column)")
ons.Controls.Refresh(worded, "Garden")
check(grows.rounds[2].button:GetChecked() == true, "the one in use lit (Flowers off)")
grows.rounds[1].button._scripts.OnClick(grows.rounds[1].button)
check(options.flowers == true, "a click sets the switch")

-- All setups together: two more modules installed later, Orchard (two steps) and Shed (one, no button on its
-- options page). At the next login they open one after another in one window, the run; Garden, gone through, not.
local orchard = Core.NewModule("SaneUI_Orchard", "Orchard", {})
Core.Options("Orchard", { { key = "setup", text = "Set up step by step", button = function() Onboarding.Open("Orchard") end },
                          { key = "apples", default = true, text = "Apples" }, { key = "pears", default = true, text = "Pears" } })
local ORCHARD = { title = "Orchard", steps = { { key = "a", title = "Apples", text = "Red.", settings = { "apples" } },
                                               { key = "p", title = "Pears", text = "Green.", settings = { "pears" } } } }
Onboarding.Add("Orchard", ORCHARD)
local shed = Core.NewModule("SaneUI_Shed", "Shed", {})
Core.Options("Shed", { { key = "tools", default = true, text = "Tools" } })
local SHED = { title = "Shed", steps = { { key = "t", title = "Tools", text = "Kept dry.", settings = { "tools" } } } }
Onboarding.Add("Shed", SHED)
W.Fire("ADDON_LOADED", "SaneUI_Orchard")
W.Fire("ADDON_LOADED", "SaneUI_Shed")
local due = Onboarding.Due()
check(#due == 2 and due[1] == "Orchard" and due[2] == "Shed", "still to go through: the two new ones, in their order")
-- The run's first page, then Start: its first setup still to go through.
local function Started()
    if not Onboarding.Start(true) or not window.Parts().first then return false end
    window.Parts().forward._scripts.OnClick(window.Parts().forward)
    return true
end
check(Onboarding.Start(true) and window.Frame():IsShown(), "the next login's run opens")
parts = window.Parts()
check(parts.first and parts.rows[1].label._text == "Orchard" and parts.rows[1].steps._text == "2 steps"
    and parts.rows[2].label._text == "Shed" and parts.rows[2].steps._text == "1 step"
    and parts.count._text == ons.TEXT.left:format(2), "its first page: both, in their order")
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()
check(parts.head._text == "Orchard: setup 1 of 2" and parts.count._text == "Step 1 of 2", "the first of two: its head counts")
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()
check(parts.forward._text:find(ons.TEXT.nextSetup, 1, true) and parts.note._text:find(ons.TEXT.following:format("Shed"), 1, true),
    "its last step: Next setup, and the note says which")
window.Close()
check(store.left.Orchard == 2 and not Onboarding.Done("Orchard") and not Onboarding.Done("Shed"),
    "closed before its end: kept where it was left, both still to go through")
check(Started() and window.Parts().head._text == "Orchard: setup 1 of 2"
    and window.Parts().count._text == "Step 2 of 2", "the login after: it opens again where it was left")
parts = window.Parts()
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()
check(Onboarding.Done("Orchard") and window.Frame():IsShown() and parts.head._text == "Shed: setup 2 of 2"
    and parts.count._text == "Step 1 of 1", "Next setup: Orchard gone through, Shed in the same window")
check(parts.forward._text == ons.TEXT.done and not parts.note._text:find("Next:", 1, true), "the run's last: Done")
check(parts.note._text:find(ons.TEXT.againTyped:format("shed"), 1, true), "no button on its options page: the command")
parts.forward._scripts.OnClick(parts.forward)
check(not window.Frame():IsShown() and Onboarding.Done("Shed") and #Onboarding.Due() == 0, "all gone through")
check(not Onboarding.Start(true), "nothing to go through: no run")
W.printed = {}
SlashCmdList.SANEUI("setup")
check(not window.Frame():IsShown() and printed("setups: Garden, Orchard, Shed"), "/sane setup: the list, none left")

-- A big change: Orchard's setup raises its version, and whoever went through the older one goes through it again,
-- told what changed on its first step. The settings chosen stay.
options = Core.Settings("Orchard")
Core.Set("Orchard", "pears", false)
ORCHARD.version, ORCHARD.changed = 2, "plums too."
check(not Onboarding.Done("Orchard") and Onboarding.Changed("Orchard") and Onboarding.Due()[1] == "Orchard",
    "a new version: to go through again")
check(Started() and window.Parts().head._text == "Orchard: setup", "the login after: alone in its run")
parts = window.Parts()
check(parts.words._text:find(ons.TEXT.changed:format("plums too."), 1, true) and parts.words._text:find("Red.", 1, true),
    "its first step says what changed, then its own words")
parts.forward._scripts.OnClick(parts.forward)
check(not window.Parts().words._text:find("plums", 1, true), "only on the first step")
check(Core.Settings("Orchard").pears == false, "the settings chosen stay")
window.Parts().forward._scripts.OnClick(window.Parts().forward)
check(Onboarding.Done("Orchard") and store.done.Orchard.version == 2 and not Onboarding.Changed("Orchard"),
    "gone through again: kept at the new version")
ORCHARD.version, ORCHARD.changed = 3, nil
Started()
check(window.Parts().words._text:find(ons.TEXT.changedAny, 1, true), "a new version without its words: said plainly")
window.Close()

-- Opened by hand (the options page's button) while others are to go through: that one alone, no run.
check(Onboarding.Due()[1] == "Orchard", "Orchard still to go through")
store.done.Shed = nil
Onboarding.Open("Shed")
parts = window.Parts()
check(parts.head._text == "Shed: setup" and parts.forward._text == ons.TEXT.done, "by hand: alone, its last step Done")
parts.forward._scripts.OnClick(parts.forward)
check(not window.Frame():IsShown() and Onboarding.Done("Shed") and not Onboarding.Done("Orchard"), "only that one gone through")
SlashCmdList.SANEUI("setup")
check(window.Frame():IsShown() and window.Parts().first and window.Parts().rows[1].label._text == "Orchard"
    and not window.Parts().rows[2]:IsShown(), "/sane setup alone: the first page of those still to go through")
window.Close()

-- Choose defaults (Saneroki: "instead of skip it says Choose Defaults on each of the onboardings"): on the first
-- page's rows and in each setup. The setup's switches back to their defaults, kept as done with its version: it no
-- longer opens by itself. Where some differ from their defaults the game's yes or no asks first. Opened by hand: no
-- Choose defaults. A new version brings it back; gone through after all, its defaults are no longer chosen.
local asked
StaticPopupDialogs = { GENERIC_CONFIRMATION = {} }
StaticPopup_Show = function(which, _, _, data) asked = which == "GENERIC_CONFIRMATION" and data or nil; return {} end
SHED.version = 2
Core.Set("Shed", "tools", true)
due = Onboarding.Due()
check(#due == 2 and due[1] == "Orchard" and due[2] == "Shed", "both to go through")
Onboarding.Start(true)
parts = window.Parts()
local shedRow = parts.rows[2]
check(parts.first and shedRow.label._text == "Shed" and shedRow.button:IsShown(), "the first page: Choose defaults on each row")
shedRow.button._scripts.OnClick(shedRow.button)
parts = window.Parts()
check(asked == nil and Onboarding.Defaulted("Shed") and Onboarding.Done("Shed") and store.done.Shed.defaults == true
    and store.done.Shed.version == 2, "Shed already as its defaults: chosen at once, kept with its version")
check(parts.first and not shedRow.button:IsShown() and shedRow.state:IsShown()
    and shedRow.state._text == ons.TEXT.defaultsChosen and parts.count._text == ons.TEXT.oneLeft,
    "its row says so; one left")
parts.forward._scripts.OnClick(parts.forward)
parts = window.Parts()
check(parts.head._text == "Orchard: setup 1 of 2" and parts.defaults:IsShown(), "Start: Orchard, Choose defaults under it")
check(Core.Settings("Orchard").pears == false, "a pear tree chosen away before")
parts.defaults._scripts.OnClick(parts.defaults)
check(asked and asked.text_arg1 == "Orchard" and window.Frame():IsShown() and not Onboarding.Done("Orchard")
    and Core.Settings("Orchard").pears == false, "a choice differs from its default: asked first, nothing changed yet")
asked.callback()
check(Core.Settings("Orchard").pears == true and Onboarding.Defaulted("Orchard") and store.done.Orchard.version == 3
    and store.left.Orchard == nil, "yes: back to its defaults, kept as done")
check(not window.Frame():IsShown() and #Onboarding.Due() == 0 and not Onboarding.Start(true),
    "nothing left: the window closes, no run")
Onboarding.Open("Orchard")
parts = window.Parts()
check(window.Frame():IsShown() and not parts.defaults:IsShown() and not parts.note._text:find(ons.TEXT.unfinished, 1, true),
    "defaults chosen, opened by hand: no Choose defaults, and it does not come back")
window.Close()
check(Onboarding.Defaulted("Orchard"), "closed: its defaults still chosen")
ORCHARD.version = 4
check(Onboarding.Due()[1] == "Orchard" and Onboarding.Changed("Orchard") and not Onboarding.Defaulted("Orchard"),
    "a new version: to go through again")
Started()
check(window.Parts().words._text:find(ons.TEXT.changedAny, 1, true) and window.Parts().defaults:IsShown(),
    "told it changed since it was last seen, Choose defaults there again")
window.Close()
Onboarding.Open("Shed")
window.Parts().forward._scripts.OnClick(window.Parts().forward)
check(Onboarding.Done("Shed") and not Onboarding.Defaulted("Shed") and store.done.Shed.defaults == nil,
    "gone through after all: its defaults no longer chosen")
-- The game's key bindings stay: Garden's switches back to their defaults, its key kept; no: nothing changes.
bound.H = "SANEUI_GARDEN_WATER"
asked = nil
Onboarding.Defaults("Garden")
check(asked and Core.Settings("Garden").path == "stone", "Garden's choices differ: asked")
asked = nil
Onboarding.Defaults("Garden")
asked.callback()
check(Core.Settings("Garden").path == "gravel" and Core.Settings("Garden").flowers == true
    and bound.H == "SANEUI_GARDEN_WATER", "yes: its switches back to their defaults, the key binding kept")

-- The store of before (shown: the day a setup first opened) counts as gone through, at version 1.
SHED.version = nil
store.done.Shed, store.shown = nil, { Shed = "2026-11-16" }
check(Onboarding.Done("Shed") and store.shown == nil and store.done.Shed.version == 1 and store.done.Shed.day == "2026-11-16",
    "shown of before: gone through at version 1")

-- A module of the run that stood down is skipped.
orchard.off = true
due = Onboarding.Due()
check(#due == 0, "Orchard stood down: nothing to go through")
orchard.off = nil

-- A module that stood down has no setup to show.
garden.off, orchard.off, shed.off = true, true, true
W.printed = {}
check(Onboarding.Open("Garden") == false, "a module stood down: no setup")
SlashCmdList.SANEUI("setup")
check(printed(Onboarding.TEXT.none), "and /sane setup says none is there")

io.write(("Onboarding: all %d checks passed.\n"):format(passed))
