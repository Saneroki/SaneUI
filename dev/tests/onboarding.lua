-- Runs Core's onboarding (src/Core/Onboarding.lua) and the addon Onboarding (src/Onboarding) against the stand-in
-- client (wowstub.lua), with a small module made here that hands in a setup of three steps: the window read only when
-- a setup opens (load on demand), by itself the first time (after the game's What's new, out of a fight, once), by
-- /sane setup and after a fight; the steps, their words and controls made from the module's own switches, set
-- through Core; Back, Next and Done; the module's sample drawn anew after each change; a setup kept as shown.
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
    { key = "flowers", default = true, text = "Flowers", tip = "Flowers in the beds." },
    { key = "height", default = 75, min = 0, max = 100, step = 5, unit = "%", text = "Hedge height", tip = "How tall." },
    { key = "path", default = "gravel", choices = { { "gravel", "Gravel" }, { "stone", "Stone" } }, text = "Path",
      tip = "What the path is made of." },
    { key = "moss", default = false, parent = "path", parentValue = "stone", text = "Moss between the stones" },
    { key = "kept", default = {} },
    { key = "reset", text = "Reset the garden", button = function() end },
})
local drawn = {}
Onboarding.Add("Garden", {
    title = "Garden",
    steps = {
        { key = "beds", title = "The beds", text = "What grows.", settings = { "flowers", "kept", "reset" } },
        { key = "hedge", title = "The hedge", text = "How tall it is.", settings = { "height" } },
        { key = "path", title = "The path", text = "What you walk on.", settings = { "path", "moss" } },
        { key = "keys", title = "Keys", text = "Keys for it.",
          settings = { { binding = "SANEUI_GARDEN_WATER", text = "Water the garden" } } },
    },
    Stage = function(stage, step, index) drawn[#drawn + 1] = { stage = stage, key = step.key, index = index } end,
})
check(Onboarding.Guide("Garden") ~= nil and Onboarding.Names()[1] == "Garden", "a module hands in its setup")
Onboarding.Add("Nothing", { title = "No steps" })
check(Onboarding.Guide("Nothing") == nil and Core.errors["onboarding"] ~= nil, "a setup without steps is refused, noted")

-- The game's key bindings: a key bound to one command; saved by SaveBindings.
bound, saved, shift = {}, 0, false
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
IsAltKeyDown = function() return false end
IsControlKeyDown = function() return false end
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
check(read == 1 and ons and ons.Window.Frame():IsShown(), "then the window is read and shows the module's setup")
local store = Core.Store("Onboarding")
check(type(store.shown.Garden) == "string", "kept as shown, for the account")
local window = ons.Window
local parts = window.Parts()
check(parts.title._text == "The beds" and parts.words._text == "What grows.", "the first step: its head and words")
check(parts.count._text == "Step 1 of 4", "Step 1 of 4")
check(parts.back:IsEnabled() == false, "no Back on the first step")
check(drawn[#drawn].key == "beds" and drawn[#drawn].index == 1 and drawn[#drawn].stage ~= nil, "the module drew its sample")

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

-- The last: a key, in the game's own key bindings: a click, then the key; Esc keeps it; a right click unbinds it.
local key = parts.made.Garden[4].rows[1]
check(key.label._text == ons.Controls.TEXT.unbound and key.box ~= nil, "a key without one: Not bound")
key.box._scripts.OnClick(key.box, "LeftButton")
check(key.box.listening and key.label._text == ons.Controls.TEXT.press, "clicked: it waits for a key")
key.box._scripts.OnKeyDown(key.box, "LSHIFT")
check(key.box.listening, "a modifier alone is no key")
shift = true
key.box._scripts.OnKeyDown(key.box, "F")
shift = false
check(not key.box.listening and bound["SHIFT-F"] == "SANEUI_GARDEN_WATER" and saved == 1 and key.label._text == "SHIFT-F",
    "Shift-F: bound to it, the game's bindings saved")
bound.G = "MOVEFORWARD"
key.box._scripts.OnClick(key.box, "LeftButton")
W.printed = {}
key.box._scripts.OnKeyDown(key.box, "G")
check(bound.G == "SANEUI_GARDEN_WATER" and bound["SHIFT-F"] == nil and printed("no longer does: MOVEFORWARD"),
    "another key: the old one let go, the key's other command said")
key.box._scripts.OnClick(key.box, "LeftButton")
key.box._scripts.OnKeyDown(key.box, "ESCAPE")
check(not key.box.listening and bound.G == "SANEUI_GARDEN_WATER", "Esc: kept as it was")
key.box._scripts.OnClick(key.box, "RightButton")
check(bound.G == nil and key.label._text == ons.Controls.TEXT.unbound, "a right click: no key")
W.combat = true
key.box._scripts.OnClick(key.box, "LeftButton")
check(not key.box.listening, "in a fight keys stay as they are")
W.combat = false
check(parts.forward._text == ons.TEXT.done and parts.progress.share == 1, "the last step: the bar full, its button Done")
parts.forward._scripts.OnClick(parts.forward)
check(not window.Frame():IsShown(), "Done closes the window; what was chosen stays")
check(options.path == "stone" and options.flowers == false, "the choices are the module's settings now")

-- Asked for again: /sane setup (the only one there: its name not needed), at the first step; in a fight, after it.
SlashCmdList.SANEUI("setup")
check(window.Frame():IsShown() and window.Parts().count._text == "Step 1 of 4", "/sane setup opens it again, at the start")
window.Close()
W.printed = {}
W.Combat(true)
SlashCmdList.SANEUI("setup Garden")
check(not window.Frame():IsShown() and printed(Onboarding.TEXT.later), "in a fight it waits, and says so")
W.Combat(false)
check(window.Frame():IsShown(), "after the fight it opens")
check(read == 1, "the addon read once")
window.Close()

-- A module that stood down has no setup to show.
garden.off = true
W.printed = {}
check(Onboarding.Open("Garden") == false, "a module stood down: no setup")
SlashCmdList.SANEUI("setup")
check(printed(Onboarding.TEXT.none), "and /sane setup says none is there")

io.write(("Onboarding: all %d checks passed.\n"):format(passed))
