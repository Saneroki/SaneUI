-- Runs Core (with its options and Sync) against the stand-in client (wowstub.lua) with small modules made here.
-- Each is an addon of its own, as in the game: Core first, then the modules in any order.
-- Usage, from the project folder:  lua5.1 dev/tests/core.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function printedMatch(pattern)
    for _, line in ipairs(W.printed) do if line:find(pattern) then return true end end
    return false
end

-- Core: the addon SaneUI, with its options (Settings) and Sync ----------------------------------
W.LoadCore(root)
local Core = SaneUI.Core
check(Core and Core.VERSION == "1.2.3", "the addons share one table, SaneUI; the version comes from the TOC")

-- An error before the saved settings are there
check(Core.Safe("early", function() error("too soon") end) == nil and printedMatch("problem in early, noted"), "a failing step is caught and told")
W.printed = {}
SlashCmdList.SANEUI("")
check(printedMatch("version 1%.2%.3%. No module is switched on") and printedMatch("/sane options"), "/sane alone says so when no module is switched on")

-- The game reads the saved settings of an earlier session: one switch already flipped, and something a module kept.
-- Some of it is spoiled (an older version, a hand edit): a switch that is no switch, a log that is no list.
SaneUIDB = { modules = { Demo = { options = { shy = true, loud = "yes" }, kept = 7 }, Spoiled = "?" }, log = "lost",
    characters = { ["Player-70-00000002"] = { name = "Alt", realm = "Stub Realm", class = "WARRIOR" } } } -- a character seen before
ScriptErrorsFrame = { DisplayMessageInternal = function() end } -- the game's error window, there from the start
W.Fire("ADDON_LOADED", "SaneUI")
check(SaneUIDB.errors.early and SaneUIDB.errors.early.text:find("too soon") and Core.errors == SaneUIDB.errors, "errors are kept in the saved settings, earlier ones too")
check(type(SaneUIDB.log) == "table" and type(Core.Store("Spoiled")) == "table", "what is spoiled is made new, not trusted")
check(SaneUIDB.modules.Core.options.errors == true and Core.general == SaneUIDB.modules.Core.options, "the general switches are kept there as well, with their defaults")

-- Modules: each an addon of its own, read after Core ----------------------------------------
local steps, flipped, toldDemo, captured = {}, nil, {}, 0
local broken = Core.NewModule("SaneUI_Broken", "Broken")
function broken.OnLoad() error("this module cannot start") end
function broken.OnLogin() steps[#steps + 1] = "broken login" end

local demo = Core.NewModule("SaneUI_Demo", "Demo", { title = "Demo module" })
function demo.OnLoad()
    steps[#steps + 1] = "load"
    demo.DB = Core.Store(demo.name)
end
function demo.OnLogin()
    steps[#steps + 1] = "login"
    demo.char = Core.Character(demo.name)
end
-- Its settings also hold something of the game's own (as the Sync module's do), without a control:
-- brought up to date before they are saved anywhere.
Core.Options(demo.name, {
    { key = "loud", default = true, text = "Be loud", tip = "Says everything twice." },
    { key = "shy", default = false, text = "Be shy" },
    { key = "outside", default = {} },
}, function(key, value)
    if key == "outside" then return end -- a table: told after every profile load (a copy is a new table)
    flipped = key .. "=" .. tostring(value)
    toldDemo[#toldDemo + 1] = flipped
end, function()
    captured = captured + 1
    demo.DB.options.outside.taken = captured
end)

check(SaneUI.Demo == demo and demo.name == "Demo" and demo.title == "Demo module" and demo.addon == "SaneUI_Demo", "a module is found by its name")
check(broken.title == "Broken", "without a title it is called by its name")
check(not pcall(Core.NewModule, "SaneUI_Demo", "Demo"), "two modules cannot share a name")
check(not pcall(Core.NewModule, nil, "Lost") and SaneUI.Lost == nil, "and a module says which addon it is made of")
check(Core.modules[1] == broken and Core.modules[2] == demo, "modules are kept in the order they were made")

W.Fire("ADDON_LOADED", "SomeOtherAddon")
check(#steps == 0, "another addon's load starts nothing")
W.printed = {}
W.Fire("ADDON_LOADED", "SaneUI_Demo")
check(#steps == 1 and steps[1] == "load" and demo.DB == SaneUIDB.modules.Demo, "a module is started once its own addon is loaded")
check(#W.printed == 0, "and only that one")
check(demo.DB.kept == 7, "what a module kept is still there")
check(demo.DB.options.loud == true and demo.DB.options.shy == true, "a switch gets its default (also in place of a spoiled one); one you flipped keeps your choice")
W.Fire("ADDON_LOADED", "SaneUI_Broken")
check(printedMatch("problem in Broken: OnLoad, noted") and #steps == 1, "a module that cannot start says so, and the others are not started twice")

-- The options are part of Core: no module, and nothing in the game's options before the login.
check(Core.Config and SaneUI.Settings == nil and SaneUI.Sync == nil and Core.Sync and #W.options.pages == 0,
    "the options and Sync are part of Core, not modules; the options have no page before the login")

-- The options: their pages put up at login, filled when the game's options are first opened -----------
SettingsPanel = W.NewWidget("Frame", "SettingsPanel") -- the game's options window
-- The game finds a picture only if its file is there: Interface\AddOns\SaneUI_<Module>\<path> is
-- src/<Module>/<path>.blp (SaneUI: src/Core). So Core has its banner (Sane UI's), the Demo module none.
function W.methods:SetTexture(file)
    self._texture = file
    local addon, path = tostring(file):match("^Interface\\AddOns\\([%w_]+)\\(.+)$")
    local folder = addon == "SaneUI" and "Core" or addon and addon:match("^SaneUI_(.+)$")
    if not folder then return file ~= nil end
    local handle = io.open(root .. "/src/" .. folder .. "/" .. path:gsub("\\", "/") .. ".blp", "rb")
    if handle then handle:close() end
    return handle ~= nil
end

-- The game's own error window, where errors go that nothing of ours caught.
W.Fire("PLAYER_LOGIN")
check(steps[2] == "login" and #steps == 2, "a module is told when the character is there; one that could not start is not")
-- The game's options window shows its AddOns tab only if an addon has a page the first time it opens.
local function Empty()
    for _, page in ipairs(W.options.pages) do if #page.items > 0 then return false end end
    return true
end
check(#W.options.pages == 5 and W.options.pages[1].registered and Core.pages.top == W.options.pages[1] and Core.pages.Profiles == W.options.pages[2]
    and Core.pages.Core == W.options.pages[3] and Core.pages.Appearance == W.options.pages[4] and Core.pages.Demo == W.options.pages[5] and Empty(),
    "but the pages are put up at login, empty, so the game's options have their AddOns tab")
SettingsPanel:GetScript("OnShow")(SettingsPanel)
local Config = Core.Config
check(#W.options.pages == 5 and #W.options.pages[5].items == 2, "opening the game's options fills the pages")
SettingsPanel:GetScript("OnShow")(SettingsPanel)
check(#W.options.pages == 5 and #W.options.pages[5].items == 2 and #steps == 2, "once")
check(Core.class == "MAGE" and Core.charName == "Tester Stub" and Core.charKey == "Player-70-0000ABCD",
    "a character is known by its own number, and named by its first name and surname")
check(demo.char == demo.DB.chars["Player-70-0000ABCD"] and demo.char.name == "Tester Stub" and demo.char.class == "MAGE", "a module's notes per character are kept under that number")
demo.char.note = "mine"
check(Core.Character(demo.name).note == "mine", "and found again")

-- The options pages -----------------------------------------------------------------
local top, profilesPage, general, appearance, page = unpack(W.options.pages)
check(top.name == "Sane UI" and top.registered and not top.parent, "the game's options get one entry, Sane UI")
local banner = top.items[1]
check(banner.template == "SaneUISettingsBannerTemplate" and banner.data.file == "Interface\\AddOns\\SaneUI\\Art\\banner",
    "its own page starts with Sane UI's banner")

-- Under it: the links and feedback (About.lua)
local About = Config.About
local names = {}
for index = 2, #top.items do names[#names + 1] = top.items[index].header or top.items[index].name end
check(table.concat(names, ",") == "Community,Discord,Website,GitHub,Feedback,Report a bug,Suggest a feature,General feedback",
    "then Community with Discord, Website and GitHub, and Feedback with a bug, a feature and general feedback")
local discord = top.items[3]
check(discord.button == "Coming soon" and discord.tooltip == About.TEXT.soonTip, "a link without an address is not there yet")
local link = About.LINKS[1]
link.url = "the address"
W.popups = {}
About.ShowLink(link)
local popup = W.popups[1]
check(popup and popup.which == "GENERIC_INPUT_BOX" and popup.box.text == link.url and popup.box.highlighted,
    "a link is shown in the game's dialog, its address selected to copy")
link.url = ""
About.ShowLink(link)
check(#W.popups == 1, "one without an address shows nothing")
local bug, idea = About.KINDS[1], About.KINDS[2]
Core.log[#Core.log + 1] = { when = "2026-10-16 12:00:00", label = "Test", text = "broke\nat line 1", count = 2 }
local report = About.Report(bug, "  The bar vanished.  ")
check(report:find("Sane UI Bug report: 1.2.3", 1, true) and report:find("Game 1.60.1 (70245), enUS", 1, true)
    and report:find("Character: MAGE", 1, true) and report:find("\nThe bar vanished.\n", 1, true)
    and report:find("- Test (2026-10-16 12:00:00, 2x): broke | at line 1", 1, true),
    "a bug report carries the versions, the class, what was written and the latest errors")
check(not About.Report(idea, "More bars"):find("Latest errors", 1, true) and not report:find("Tester", 1, true),
    "an idea carries no errors, and no report names the character")
local feedback = top.items[7]
feedback.click()
local window = SaneUIFeedbackFrame
check(window and window:IsShown() and window._title == "Report a bug" and window.Ask:GetText() == bug.ask,
    "Report a bug opens the feedback window, asking what happened")
About.Toggle()
check(window.Ask:GetText() == About.TEXT.empty and not window.made, "nothing written makes no report")
window.Box:SetText("The bar vanished.")
About.Toggle()
check(window.made and window.Box:GetText():find("Latest errors", 1, true) and window.Make:GetText() == About.TEXT.edit,
    "written, it makes the report to copy")
About.Toggle()
check(not window.made and window.Box:GetText() == "The bar vanished.", "and goes back to what was written")
window:Hide()
About.Open(idea)
check(window.Box:GetText() == "" and window._title == "Suggest a feature", "each kind keeps its own writing")
About.Open(bug)
check(window.Box:GetText() == "The bar vanished.", "kept while the session lasts")
window:Hide()
table.remove(Core.log)
check(profilesPage.name == "Profiles" and general.name == "General" and appearance.name == "Appearance"
    and profilesPage.parent == top and general.parent == top and appearance.parent == top,
    "under it first Sane UI's own pages: Profiles, General, Appearance")
check(#general.items == 1 and general.items[1].setting.name == "Errors in chat", "General: the switches of no module")
local windows, animations, motion = appearance.items[1], appearance.items[2], appearance.items[3]
local kinds = {}
for index, choice in ipairs(motion and motion.options and motion.options() or {}) do kinds[index] = choice.value .. "=" .. choice.label end
check(#appearance.items == 3 and windows.header == "Windows" and animations.setting.name == "Animations" and motion.setting.name == "Animation type"
    and table.concat(kinds, " ") == "glide=Glide swing=Swing even=Even off=Instant",
    "Appearance: under Windows, animations on or off, and the animation type for all windows, as a dropdown")
Core.general.animations = false
check(Core.Motion.Kind("swing").key == "off", "animations off: nothing moves, whatever a window's own setting says")
Core.general.animations = true
check(motion.setting:GetValue() == "glide" and Core.general.motion == "glide" and Core.Motion.Kind().key == "glide", "Glide at first")
motion.setting:SetValue("even")
check(Core.Motion.Kind().key == "even" and Core.Motion.Kind("global").key == "even" and Core.Motion.Kind("swing").key == "swing",
    "chosen, it is every window's that has none of its own")
motion.setting:SetValue("glide")
check(page.name == "Demo module" and page.parent == top, "then one page per module that has switches, called by its name")
check(not page.registered, "the game lists those with their parent")
local loud, shy = page.items[1], page.items[2]
check(#page.items == 2 and loud.setting.name == "Be loud" and loud.tooltip == "Says everything twice." and shy.setting.name == "Be shy", "with a checkbox per switch")
check(loud.setting.variable == "SaneUI_Demo_loud" and loud.setting.kind == "boolean", "each under a name of its own")
check(not loud.template, "a module without a banner of its own has none: its page keeps the game's title")
check(loud.setting:GetValue() == true and shy.setting:GetValue() == true, "showing what is saved")
loud.setting:SetValue(false)
check(demo.DB.options.loud == false and flipped == "loud=false", "ticking one saves it and tells the module")

-- The banner is a row of the game's settings list: it stands in for the page's title while it is there.
local title = W.NewWidget("FontString")
SettingsPanel.GetSettingsList = function() return { Header = { Title = title } } end
local row = { Art = W.NewWidget("Texture") }
function row.Art:SetTexCoord(...) self._coords = { ... } end
SaneUISettingsBannerMixin.Init(row, { GetData = function() return banner.data end })
check(row.Art._texture == banner.data.file and title:GetAlpha() == 0, "drawn, the banner hides the page's title")
check(row.Art._coords[2] == 0.75 and row.Art._coords[4] == 1, "and shows only the part of its file the banner fills")
SaneUISettingsBannerMixin.Release(row)
check(title:GetAlpha() == 1, "and the title is back when the game lets the row go (another page, or scrolled away)")
SaneUISettingsBannerMixin.Init(row, { GetData = function() return { file = "Interface\\AddOns\\SaneUI_Gone\\Art\\banner" } end })
check(title:GetAlpha() == 1, "a picture the game cannot find leaves the title")
SettingsPanel.GetSettingsList = nil

-- The general switch: errors in chat
local tell = general.items[1].setting
tell:SetValue(false)
W.printed = {}
check(Core.Safe("quiet", function() error("hush") end) == nil and #W.printed == 0 and Core.errors.quiet.text:find("hush"), "switched off, a problem is kept but not told")
tell:SetValue(true)
Core.Safe("quiet", function() error("hush") end)
check(printedMatch("problem in quiet, noted") and Core.errors.quiet.count == 2, "switched on again, it is")
Core.errors.quiet = nil

-- Profiles: the page Profiles, a page of our own with tabs ----------------------------------
local Profiles = Core.Profiles
local canvas = Core.frames.Profiles
check(profilesPage.frame == canvas and #profilesPage.items == 0, "Profiles is a page of our own: its frame is shown in place of the game's list")
local function Control(label)
    for _, control in ipairs(Config.Panel.controls) do if control.label == label then return control end end
end
local function Click(control) control:GetScript("OnClick")(control) end
local function Tick(check, on)
    check:SetChecked(on)
    Click(check)
end
-- Whether a line with these words is on a page
local function Shows(words)
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and type(widget._text) == "string" and widget._text:find(words, 1, true) then return true end
    end
    return false
end
local menu = Control("Profile").widget
local function Items()
    menu:GenerateMenu()
    return menu._items
end
local function Choices()
    local names = {}
    for _, item in ipairs(Items()) do names[#names + 1] = item.text end
    return #names > 0 and table.concat(names, ", ") or menu._defaultText
end
local function Chosen()
    for _, item in ipairs(Items()) do if item.checked(item.data) then return item.text end end
    return ""
end
local function Choose(name)
    for _, item in ipairs(Items()) do if item.text == name then item.fn(item.data) end end
end
local buttons = {}
for _, name in ipairs({ "Load", "Save", "Duplicate", "Rename", "Delete" }) do buttons[name] = Control(name) end
local allCheck = Control("All settings accountwide")
local function Dialog() return W.popups[#W.popups] end

check(canvas.tabs and #canvas.tabs == 3 and canvas.tabs[1].Text._text == "Profiles" and canvas.tabs[2].Text._text == "Accountwide"
    and canvas.tabs[3].Text._text == "CVars", "its tabs: Profiles, Accountwide and CVars (Chat channels comes with the Sync module)")
check(canvas.parts[1]:IsShown() and not canvas.parts[2]:IsShown(), "the first is shown at first")
check(Shows("Settings are saved account wide by default"), "over the tabs a line says the settings are the account's at first")
check(Shows("Account wide") and Shows("Saved profiles") and Shows("Characters"), "the tab Profiles: boxes Account wide, Saved profiles, Characters")
check(allCheck and allCheck:GetChecked() and Shows("Ticked will sync all settings accountwide by default. Profiles overwrites the setting on a per character basis."),
    "first All settings accountwide, ticked at first, and what it means")
check(Choices() == "Empty, SaneUI Defaults" and Chosen() == "Empty", "then the profiles to choose from: at first Empty, chosen, and SaneUI Defaults")
check(buttons.Load and buttons.Save and buttons.Duplicate and buttons.Rename and buttons.Delete, "its buttons: Load, Save, Duplicate, Rename, Delete")
check(buttons.Load:IsEnabled() and buttons.Save:IsEnabled() and buttons.Duplicate:IsEnabled() and not buttons.Rename:IsEnabled()
    and not buttons.Delete:IsEnabled(), "Empty can be loaded and duplicated, not renamed or deleted")
local me, alt = Config.characters["Player-70-0000ABCD"], Config.characters["Player-70-00000002"]
check(me and alt and me.name._text:find("Tester Stub", 1, true) and me.name._text:find("this character") and alt.name._text:find("Alt")
    and not alt.name._text:find("this character"), "Characters: every character seen by its whole name, this one marked")
check(not me.load:IsEnabled() and me.load:GetChecked() and not me.save:IsEnabled() and me.save:GetChecked() and me.menu
    and Profiles.Character(Core.charKey).profile == "Empty",
    "each with Load at login, Save at logout and its profile: Empty at first, which always loads and saves (ticked, switched off)")
local newRow = Config.characters[Profiles.NEW]
check(newRow and newRow.name._text == "New Characters" and not newRow.load:IsEnabled() and newRow.load:GetChecked() and not newRow.save:IsEnabled() and newRow.menu,
    "first a line New Characters, for characters not seen yet, with the same")
Click(canvas.tabs[3])
check(canvas.parts[3]:IsShown() and not canvas.parts[1]:IsShown() and canvas.parts[3].list, "the tab CVars shows the list of the game's CVars")
check(Shows("Every console setting of the game."), "under a line that says what it is for")
Click(canvas.tabs[1])

-- Save: the settings of every module, under a name asked for in the game's own dialog
Click(buttons.Save)
local dialog = Dialog()
check(dialog.which == "GENERIC_INPUT_BOX" and dialog.data.maxLetters == 32 and dialog.data.acceptText == "Save" and dialog.box.text == "",
    "Save asks for a name in the game's own dialog")
W.printed = {}
local before = captured
dialog.data.callback("  Quiet ")
local quietProfile = SaneUIDB.profiles.Quiet
check(captured == before + 1 and quietProfile.Demo.outside.taken == captured,
    "before a profile is saved, a module whose settings hold something of the game's brings it up to date")
check(quietProfile and quietProfile.Demo.loud == false and quietProfile.Demo.shy == true and quietProfile.Core.errors == true
    and quietProfile.Demo ~= demo.DB.options, "a copy of the settings of every module is kept under that name, without the spaces around it")
check(Chosen() == "Quiet" and Choices() == "Empty, SaneUI Defaults, Quiet" and printedMatch("saved as the profile Quiet"), "it is the chosen profile now, and chat says so")
local notified = loud.setting.notified or 0
W.Wait(0.1)
check((loud.setting.notified or 0) > notified and buttons.Load:IsEnabled(),
    "a moment later the controls show what changed")

-- Another profile, from other settings. The chosen one's name is offered, to save over it.
loud.setting:SetValue(true)
shy.setting:SetValue(false)
Click(buttons.Save)
dialog = Dialog()
check(dialog.box.text == "Quiet" and dialog.box.highlighted, "saving again offers the chosen profile's name")
dialog.data.callback("loud")
check(Choices() == "Empty, SaneUI Defaults, loud, Quiet" and SaneUIDB.profiles.loud.Demo.loud == true and Chosen() == "loud",
    "another name keeps another profile; they are listed in alphabetical order, after Empty and SaneUI Defaults")

-- Load
Choose("Quiet")
toldDemo = {}
W.printed = {}
Click(buttons.Load)
check(demo.DB.options.loud == false and demo.DB.options.shy == true and printedMatch("profile Quiet are in use"),
    "loading the chosen profile puts its settings in use")
check(#toldDemo == 2 and toldDemo[1] == "loud=false" and toldDemo[2] == "shy=true", "and each module is told of each switch that changed")
W.Wait(0.1)
check(#toldDemo == 2 and loud.setting:GetValue() == false, "the controls show the new values without telling the module twice")
-- A profile from an older version or a hand edit: a spoiled switch, a module not here, no general switches
SaneUIDB.profiles.Old = { Demo = { loud = "yes" }, Gone = { x = 1 } }
Choose("Old")
toldDemo = {}
Click(buttons.Load)
check(demo.DB.options.loud == true and demo.DB.options.shy == true and #toldDemo == 1 and Core.general.errors == true,
    "a profile's spoiled switch gets its default; what it does not have stays as it is")
check(SaneUIDB.modules.Gone.options.x == 1, "the settings of a module not switched on here are kept for it")

-- Duplicate and Rename: a name of its own
Choose("Quiet")
Click(buttons.Duplicate)
dialog = Dialog()
check(dialog.data.text:find("%%s") and dialog.data.text_arg1 == "Quiet" and dialog.box.text == "", "Duplicate asks for the copy's name")
W.printed = {}
dialog.data.callback("loud")
check(printedMatch("there is already a profile called loud") and Choices() == "Empty, SaneUI Defaults, loud, Old, Quiet", "a name that is taken is refused")
dialog.data.callback("   ")
check(printedMatch("a profile needs a name"), "and so is none")
dialog.data.callback("Raid")
check(SaneUIDB.profiles.Raid.Demo.loud == false and SaneUIDB.profiles.Raid.Demo ~= SaneUIDB.profiles.Quiet.Demo and Chosen() == "Raid",
    "a copy of the profile is kept under the new name, and chosen")
Click(buttons.Rename)
dialog = Dialog()
check(dialog.box.text == "Raid" and dialog.data.text_arg1 == "Raid", "Rename offers the profile's name to change")
W.printed = {}
dialog.data.callback("Quiet")
check(printedMatch("already a profile called Quiet"), "not into one that is taken")
dialog.data.callback("Raid night")
check(SaneUIDB.profiles.Raid == nil and SaneUIDB.profiles["Raid night"].Demo.loud == false and Chosen() == "Raid night",
    "renamed, it is still the chosen one")

-- A game without the dialog (a client update took it): noted and told, nothing else happens.
local inputBox, popups = StaticPopupDialogs.GENERIC_INPUT_BOX, #W.popups
StaticPopupDialogs.GENERIC_INPUT_BOX = nil
W.printed = {}
Click(buttons.Rename)
check(#W.popups == popups and Core.errors["Settings: profiles"] and printedMatch("problem in Settings: profiles, noted"),
    "a dialog the game no longer has is noted, not shown")
StaticPopupDialogs.GENERIC_INPUT_BOX, Core.errors["Settings: profiles"] = inputBox, nil

-- Delete, after asking
Click(buttons.Delete)
dialog = Dialog()
check(dialog.which == "GENERIC_CONFIRMATION" and dialog.data.text_arg1 == "Raid night" and SaneUIDB.profiles["Raid night"], "Delete asks first")
dialog.data.callback()
check(SaneUIDB.profiles["Raid night"] == nil and Chosen() == "Empty", "then the profile is gone, and Empty is chosen")
for _, name in ipairs({ "loud", "Old", "Quiet" }) do Profiles.Delete(name) end
Config.Refresh()
check(Chosen() == "Empty" and Choices() == "Empty, SaneUI Defaults" and buttons.Load:IsEnabled() and not buttons.Delete:IsEnabled(),
    "with none left Empty and SaneUI Defaults are still there")

-- Empty: no profile, the settings as they are kept; loaded and duplicated, never changed
Click(buttons.Save)
dialog = Dialog()
check(dialog.box.text == "", "Save does not offer Empty's name")
W.printed = {}
dialog.data.callback("Empty")
check(printedMatch("Empty stays as it is") and SaneUIDB.profiles.Empty == nil, "nor saves over it")
check(not Profiles.Rename("Empty", "Mine") and not Profiles.Delete("Empty") and Chosen() == "Empty", "it cannot be renamed or deleted")
Profiles.Duplicate("Empty", "Kept")
check(SaneUIDB.profiles.Kept.Demo.loud == demo.DB.options.loud and SaneUIDB.profiles.Kept.Sync and Chosen() == "Kept",
    "duplicated, it is a profile of the settings as they are kept, the game's that Sync keeps too")
Profiles.Delete("Kept")

-- SaneUI Defaults: every switch of Sane UI's own at its default, made from what the modules describe;
-- not the game's settings Sync keeps; never saved
loud.setting:SetValue(false)
shy.setting:SetValue(true)
check(demo.DB.options.outside.taken ~= nil, "(what the module took from the game is in use)")
local syncOptions = Core.Sync.options
syncOptions.off.CONTROLS_LABEL, syncOptions.named.someThing, syncOptions.taken.perCharacter = true, "1", { cvars = { cameraSavedDistance = "30" } }
toldDemo = {}
W.printed = {}
Choose("SaneUI Defaults")
Click(buttons.Load)
check(demo.DB.options.loud == true and demo.DB.options.shy == false and next(demo.DB.options.outside) == nil and Core.general.errors == true
    and printedMatch("profile SaneUI Defaults are in use"), "loading SaneUI Defaults puts every switch back to its default, a table empty again")
check(#toldDemo == 2 and toldDemo[1] == "loud=true" and toldDemo[2] == "shy=false", "and each module is told of each switch that changed")
check(SaneUIDB.modules.Gone.options.x == 1 and SaneUIDB.profiles["SaneUI Defaults"] == nil,
    "a module not switched on here keeps its settings; SaneUI Defaults is not saved anywhere")
check(syncOptions.off.CONTROLS_LABEL and syncOptions.named.someThing == "1" and syncOptions.taken.perCharacter.cvars.cameraSavedDistance == "30",
    "the game's settings Sync keeps stay as they are, and which of them it keeps")
syncOptions.off.CONTROLS_LABEL, syncOptions.named.someThing, syncOptions.taken.perCharacter = nil, nil, nil
Click(buttons.Save)
dialog = Dialog()
check(dialog.box.text == "", "Save does not offer its name")
W.printed = {}
dialog.data.callback("SaneUI Defaults")
check(printedMatch("SaneUI Defaults stays as it is") and SaneUIDB.profiles["SaneUI Defaults"] == nil, "nor saves over it")
check(not Profiles.Rename("SaneUI Defaults", "Mine") and not Profiles.Delete("SaneUI Defaults") and Chosen() == "SaneUI Defaults",
    "it cannot be renamed or deleted")
Click(buttons.Duplicate)
Dialog().data.callback("Mine")
W.Wait(0.1)
local mine = SaneUIDB.profiles.Mine
check(mine and mine.Demo.loud == true and mine.Demo.shy == false and type(mine.Demo.outside) == "table" and mine.Core.errors == true
    and mine.Sync == nil and Chosen() == "Mine" and buttons.Rename:IsEnabled() and buttons.Delete:IsEnabled(),
    "duplicated, it is a profile of its own with every switch at its default, which can be renamed and deleted")
check(not Profiles.Duplicate("Mine", "SaneUI Defaults") and not Profiles.Rename("Mine", "SaneUI Defaults"), "no other profile takes its name")
Profiles.Delete("Mine")
shy.setting:SetValue(true)

-- All settings accountwide: unticked, every character keeps all its settings to itself
loud.setting:SetValue(false)
toldDemo = {}
Tick(allCheck, false)
check(not Profiles.AccountWide() and SaneUIDB.separate == true and SaneUIDB.account.Demo.loud == false and SaneUIDB.account.Core.errors == true,
    "unticked, no settings are account wide: the account's are kept aside")
check(demo.DB.options.loud == false and #toldDemo == 0, "at first this character's own are a copy of the account's: nothing changes")
loud.setting:SetValue(true)
check(SaneUIDB.account.Demo.loud == false, "a change is this character's own")
toldDemo = {}
Tick(allCheck, true)
check(Profiles.AccountWide() and SaneUIDB.separate == nil and demo.DB.options.loud == false and SaneUIDB.account == nil and toldDemo[1] == "loud=false",
    "ticked again, the account's settings are in use, and the module is told")
check(SaneUICharDB.settings.Demo.loud == true, "this character's own are kept for when they count again")

-- One module's settings each character's own: the tab Accountwide, its box Sane UI
local demoShared = Control("Demo module")
check(Shows("Sane UI") and Control("General") and demoShared and demoShared:GetChecked() and demoShared:IsEnabled(),
    "the tab Accountwide: a box Sane UI with a checkbox for every module, account wide at first")
toldDemo = {}
Tick(demoShared, false)
check(not Profiles.Shared("Demo") and SaneUIDB.perCharacter.Demo and demo.DB.options.loud == true and SaneUIDB.account.Demo.loud == false
    and SaneUIDB.account.Core == nil and toldDemo[1] == "loud=true",
    "unticked, that module's settings are this character's own; the others stay the account's")
Tick(allCheck, false)
check(not demoShared:IsEnabled() and SaneUIDB.account.Core, "with nothing account wide, those checkboxes are switched off")
Tick(allCheck, true)
Tick(demoShared, true)
check(Profiles.Shared("Demo") and demo.DB.options.loud == false and SaneUIDB.account == nil, "ticked again: the account's")
W.Wait(0.1)

-- A character's profile: chosen on its line, loaded at login and saved at logout if ticked there
local function ChooseFor(row, name)
    row.menu:GenerateMenu()
    for _, item in ipairs(row.menu._items) do if item.text == name then item.fn(item.data) end end
end
Profiles.Save("Solo")
ChooseFor(alt, "Solo")
Tick(alt.load, true)
W.Wait(0.1)
check(SaneUIDB.characters["Player-70-00000002"].profile == "Solo" and SaneUIDB.characters["Player-70-00000002"].autoLoad and alt.load:IsEnabled(),
    "another character's profile and Load at login are set from here, kept for the account")
check(SaneUIDB.account == nil and demo.DB.options.loud == false, "and change nothing for this one")
ChooseFor(me, "Solo")
Tick(me.save, true)
W.Wait(0.1)
check(Profiles.Character(Core.charKey).profile == "Solo" and SaneUIDB.characters[Core.charKey].autoSave and me.load:IsEnabled() and not me.load:GetChecked(),
    "this character: Save at logout into its profile, without Load at login")
ChooseFor(newRow, "Solo")
Tick(newRow.load, true)
W.Wait(0.1)
check(SaneUIDB.newCharacters.profile == "Solo" and SaneUIDB.newCharacters.autoLoad and newRow.save:IsEnabled() and SaneUIDB.account == nil,
    "New Characters: a profile and Load at login for characters not seen yet, kept for the account; nothing changes for this one")
Profiles.Rename("Solo", "Duo")
check(SaneUIDB.newCharacters.profile == "Duo" and SaneUIDB.characters[Core.charKey].profile == "Duo", "a profile renamed is renamed there too")
Profiles.Rename("Duo", "Solo")
Tick(newRow.load, false)
ChooseFor(newRow, "Empty")
check(SaneUIDB.newCharacters.profile == nil and not SaneUIDB.newCharacters.autoLoad, "and taken off again")
shy.setting:SetValue(false)

W.printed = {}
SlashCmdList.SANEUI("options")
check(W.options.opened == top.id, "/sane options opens the options, at Sane UI")
W.options.opened = nil
SaneUI_OnAddonCompartmentClick()
check(W.options.opened == top.id, "and so does the minimap's addon list")
W.options.opened, W.combat = nil, true
SlashCmdList.SANEUI("config")
check(W.options.opened == nil and printedMatch("in combat"), "in a fight it says why not")
W.combat = false

-- The CVars section ----------------------------------------------------------------------
W.cvarInfo = {
    autoLootDefault = { default = "0", scope = "account", category = 4, help = "Loot everything at once" },
    cameraSavedDistance = { default = "15", scope = "character", category = 4 },
    graphicsQuality = { default = "5", category = 1 },
    secureThing = { default = "1", secure = true, category = 3 },
    buildVersion = { default = "70245", readOnly = true, category = 0 },
}
W.cvars.autoLootDefault = "1"
AUTO_LOOT_DEFAULT_TEXT, OPTION_TOOLTIP_AUTO_LOOT_DEFAULT = "Auto Loot", "Loot all items when you open a corpse."
local CVars = Config.CVars
local function Names(list)
    local names = {}
    for _, entry in ipairs(list) do names[#names + 1] = entry.name end
    return table.concat(names, " ")
end
check(Names(CVars.All()) == "autoLootDefault buildVersion cameraSavedDistance graphicsQuality secureThing",
    "every CVar of the game is listed, by name, not its commands")
local loot = CVars.All()[1]
check(loot.label == "Auto Loot" and loot.tip == "Loot all items when you open a corpse." and loot.help == "Loot everything at once" and loot.kind == "game",
    "with the label and tooltip the game's own options give it, in the game's words, and its kind")
check(CVars.All()[3].label == nil and CVars.All()[4].kind == "graphics", "one the options do not show has none")
local list = SaneUISettingsCVarsMixin
check(type(list) == "table" and type(SaneUISettingsCVarRowMixin) == "table", "the list and its rows are the game's kind of templates, with mixins")

-- The list: the search, the filter button, the count
local function Made(mixin, parts)
    local widget = W.NewWidget("Frame")
    for key, value in pairs(mixin) do widget[key] = value end
    for key, value in pairs(parts or {}) do widget[key] = value end
    return widget
end
local frame = Made(list)
W.templates.UICheckButtonTemplate = function(widget) widget.Text = W.NewWidget("FontString") end
CreateScrollBoxListLinearView = function()
    return { SetElementInitializer = function(self, template, fn) self.template, self.fn = template, fn end }
end
ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, _, view) box._view = view end }
ScrollBoxConstants = { RetainScrollPosition = true }
CreateDataProvider = function(rows) return { rows = rows } end
GameTooltip_Hide, GameTooltip_AddHighlightLine = function() end, function() end
function W.methods:SetDataProvider(provider) self._provider = provider end
function W.methods:ForEachFrame(fn) for _, row in ipairs(self._rows or {}) do fn(row) end end
-- The game's filter button: whether the filters are as at first, and what its red cross does.
function W.methods:SetIsDefaultCallback(fn) self._isDefault = fn end
function W.methods:SetDefaultCallback(fn) self._toDefault = fn end
function W.methods:ValidateResetState() self._cross = not self._isDefault() end
function W.methods:HasFocus() return self._focus or false end
function W.methods:SetFocus() self._focus = true end
function W.methods:ClearFocus()
    if not self._focus then return end
    self._focus = false
    if self._scripts.OnEditFocusLost then self._scripts.OnEditFocusLost(self) end
end
list.OnLoad(frame)
list.Init(frame)
local function Listed() return Names(frame.List._provider.rows) end
local function Item(text)
    frame.Filter:GenerateMenu()
    for _, item in ipairs(frame.Filter._items) do if item.text == text then return item end end
end
check(frame.List._view.template == "SaneUISettingsCVarRowTemplate" and Listed() == "autoLootDefault buildVersion cameraSavedDistance graphicsQuality secureThing"
    and frame.Count._text == "5 CVars" and not frame.Filter._cross, "shown, the list has every CVar, and says how many")
frame.Search:SetText("loot")
frame.Search:GetScript("OnTextChanged")(frame.Search)
W.Wait(0.2)
check(Listed() == "autoLootDefault" and frame.Count._text == "1 matching", "searching finds a CVar by its name, and the count says how many match")
frame.Search:SetText("auto l")
frame.Search:GetScript("OnTextChanged")(frame.Search)
W.Wait(0.2)
check(Listed() == "autoLootDefault", "and by the label the game's options give it")
frame.Search:SetText("")
frame.Search:GetScript("OnTextChanged")(frame.Search)
local notDefault = Item("Not at their default")
notDefault.fn()
W.Wait(0.2)
check(notDefault.checked() and Listed() == "autoLootDefault" and frame.Count._text == "1 matching" and frame.Filter._cross,
    "the filter button: only those not at the game's default; its red cross is shown")
frame.Filter._toDefault()
W.Wait(0.2)
check(not notDefault.checked() and #frame.List._provider.rows == 5 and not frame.Filter._cross, "the red cross clears every filter")
local graphics = Item("Graphics")
graphics.fn(graphics.data)
W.Wait(0.2)
check(graphics.checked(graphics.data) and Listed() == "graphicsQuality", "one of the game's kinds of CVar")
local every = Item("Every kind")
every.fn(every.data)
W.Wait(0.2)
check(Item("Kept with Sane UI") and #frame.List._provider.rows == 5, "and a filter for the CVars Sync keeps")

-- A row
local row = Made(SaneUISettingsCVarRowMixin, { Name = W.NewWidget("FontString"), Label = W.NewWidget("FontString"),
    Value = W.NewWidget("EditBox"), Keep = W.NewWidget("CheckButton"), Reset = W.NewWidget("Button") })
row:OnLoad()
row:Init(loot)
check(row.Name._text == "autoLootDefault" and row.Label._text == "Auto Loot" and row.Value._text == "1" and row.Value:IsEnabled()
    and not row.Keep:GetChecked() and row.Reset:IsShown(), "a row: a tick to keep it, its name, its label, its value to type into; not at its default, the undo arrow")
row.Keep:SetChecked(true)
row.Keep:GetScript("OnClick")(row.Keep)
check(Core.Sync.Kept("autoLootDefault"), "ticked, Sync keeps it")
row.Keep:SetChecked(false)
row.Keep:GetScript("OnClick")(row.Keep)
check(not Core.Sync.Kept("autoLootDefault"), "unticked, no more")
frame.List._rows = { row }

-- Changing one in its row
row:OnClick()
row.Value._text = "2"
row.Value:GetScript("OnEscapePressed")(row.Value)
check(W.cvars.autoLootDefault == "1" and row.Value._text == "1" and not row.Value:HasFocus(), "a click goes into its value; Esc leaves it as it was")
row:OnClick()
row.Value._text = "0"
row.Value:GetScript("OnEnterPressed")(row.Value)
check(W.cvars.autoLootDefault == "0" and row.Value._text == "0" and not row.Reset:IsShown() and frame.Status._text == "",
    "Enter sets what was typed; at its default again, the undo arrow goes")
row:Init(CVars.All()[2])
check(not row.Value:IsEnabled() and not row.Reset:IsShown(), "one the game does not let change cannot be typed into")
check(select(2, CVars.Set("buildVersion", "1")) and W.cvars.buildVersion == nil, "and is not changed")
W.combat = true
local now, why = CVars.Set("secureThing", "0")
check(now == "1" and why:find("fight"), "a secure one is not changed in a fight")
row:Init(CVars.All()[5])
row.Value._text = "0"
row.Value:GetScript("OnEnterPressed")(row.Value)
check(frame.Status._text:find("secureThing") and frame.Status._text:find("fight") and row.Value._text == "1",
    "the row shows what the game kept, and under the list it says why")
W.combat = false
check(CVars.Set("secureThing", "0") == "0", "but out of it")
W.cvars.cameraSavedDistance = "30"
row:Init(CVars.All()[3])
check(row.Reset:IsShown(), "one away from its default has the undo arrow")
row.Reset:GetScript("OnClick")(row.Reset)
check(W.cvars.cameraSavedDistance == "15" and not row.Reset:IsShown(), "which gives it the game's default")
list.Release(frame)
W.cvarInfo, W.cvars = {}, {}

-- /sane -------------------------------------------------------------------------------
local said
Core.Command("demo", "a test command", function(rest) said = rest end, "d")
SlashCmdList.SANEUI("demo  hello there ")
check(said == "hello there", "/sane <word> runs that module's command with the rest of the line")
SlashCmdList.SANEUI("D again")
check(said == "again", "a short word for it works too, in any case")
W.printed = {}
SlashCmdList.SANEUI("")
check(printedMatch("version 1%.2%.3%. Modules: Broken %(failed to start, see /sane errors%), Demo module%.$"), "/sane alone says which modules are switched on")
check(printedMatch("/sane demo %- a test command") and printedMatch("/sane options") and printedMatch("/sane errors"), "and lists the commands")
check(not printedMatch("/sane d %-"), "each once")
W.printed = {}
SlashCmdList.SANEUI("nonsense")
check(printedMatch("/sane demo"), "and so does a word nobody knows")
Core.Command("fail", "a failing command", function() error("no") end)
W.printed = {}
SlashCmdList.SANEUI("fail")
check(printedMatch("problem in /sane fail, noted"), "a failing command is caught")

-- Errors ------------------------------------------------------------------------------
W.printed = {}
local function boom() error("boom") end
check(demo.Safe("step", boom) == nil, "a failing step does not stop the addon")
demo.Safe("step", boom)
local kept = Core.errors["Demo: step"]
check(kept and kept.count == 2 and kept.text:find("boom") and kept.when, "the error is kept under the module's name, counted and dated")
check(#W.printed == 1 and printedMatch("/sane errors"), "and told only once")
check(demo.Safe("fine", function(a, b) return a + b end, 2, 3) == 5, "a working step passes its result through")
-- The log: every problem in the order it happened
local last = Core.log[#Core.log]
check(Core.log == SaneUIDB.log and last.label == "Demo: step" and last.count == 2 and last.text:find("boom") and last.when:find("^%d+%-%d+%-%d+ %d+:%d+:%d+$")
    and last.version == "1.2.3" and last.build == "70245",
    "every problem is also in a log: when, what and where, the addon's version, the game's build; the same one twice in a row counts")
check(Core.log[1].label == "early", "errors from before the saved settings were there are in it too, the oldest first")
local entries = #Core.log
ScriptErrorsFrame:DisplayMessageInternal("Interface/AddOns/SaneUI_Demo/Demo.lua:7: attempt to index a nil value", 1, "[Interface/AddOns/SaneUI_Demo/Demo.lua]:7: in function <OnUpdate>")
check(#Core.log == entries + 1 and Core.log[#Core.log].label == "Lua error" and Core.log[#Core.log].text:find("Demo.lua:7.*in function") and Core.errors["Lua error"],
    "an error nothing of ours caught is noted from the game's error window, with the place it happened")
ScriptErrorsFrame:DisplayMessageInternal("Interface/AddOns/OtherAddon/Other.lua:1: oops", 1, "[Interface/AddOns/OtherAddon/Other.lua]:1")
ScriptErrorsFrame:DisplayMessageInternal(nil, 1, nil)
check(#Core.log == entries + 1, "another addon's error is not ours to note")
for index = 1, 120 do Core.NoteError("flood", "problem " .. index) end
check(#Core.log == 100 and Core.log[100].text == "problem 120" and Core.log[1].text == "problem 21", "the log keeps the newest hundred")
Core.errors.flood, Core.errors["Lua error"] = nil, nil
W.printed = {}
SlashCmdList.SANEUI("errors")
check(printedMatch("Demo: step %(2x, last .+%): .*boom") and printedMatch("^.-early"), "/sane errors lists them, one line each")
check(printedMatch("the log has 100 entries"), "and says how much is in the log")
-- What the saved file holds may be spoiled (a hand edit): the list is still shown.
Core.errors.spoiled, Core.errors.counted = "not a table", { count = "many", text = "a count that is no number" }
W.printed = {}
SlashCmdList.SANEUI("errors")
check(printedMatch("counted %(1x, last %?%): a count that is no number") and printedMatch("Demo: step"), "/sane errors skips what it cannot read")
-- An error about a value the game hides is a hidden text: it can be neither compared nor saved.
local hidden = setmetatable({}, { __tostring = function() return "hidden" end })
issecretvalue = function(value) return value == hidden end
Core.NoteError("hidden", hidden)
Core.NoteError("hidden", hidden)
issecretvalue = nil
check(Core.errors.hidden.count == 2 and type(Core.errors.hidden.text) == "string" and Core.log[#Core.log].text == Core.errors.hidden.text
    and Core.log[#Core.log].count == 2, "an error with a hidden text is noted without it, and counted")
SlashCmdList.SANEUI("errors clear")
check(next(SaneUIDB.errors) == nil and Core.errors == SaneUIDB.errors and #Core.log == 0 and Core.log == SaneUIDB.log, "/sane errors clear forgets them, and empties the log")
W.printed = {}
SlashCmdList.SANEUI("errors")
check(printedMatch("no errors noted"), "and then there are none")

-- A module that stands in for something of the game's gives it back when a step fails
local given = 0
function demo.GiveBack() given = given + 1 end
demo.GIVEN_BACK = "the game's own demo is back"
W.printed = {}
check(demo.Guarded(function(a, b) return a * b end, 6, 7) == 42 and not demo.off, "a guarded step passes its result through")
check(demo.Guarded(function() error("broken") end) == nil and demo.off and given == 1, "an error in one stands the module down and gives the game's own back")
check(printedMatch("problem in Demo: the game's own demo is back, noted") and Core.errors["Demo: the game's own demo is back"].text:find("broken"),
    "it is kept and told, with what happened")
check(demo.Guarded(function() given = 99 end) == nil and given == 1, "from then on nothing runs")
demo.StandDown("again")
check(given == 1, "and it stands down only once")
W.printed = {}
broken.GiveBack = function() error("cannot give it back") end
broken.StandDown("a part is missing")
check(broken.off and Core.errors["Broken: giving back"] and Core.errors["Broken: it stopped"].text == "a part is missing",
    "a giving back that fails is kept too; without words of its own it is told as stopped")
Core.Report("found", "a problem nobody raised")
check(printedMatch("problem in found, noted") and Core.errors.found.count == 1, "a module can report a problem it found itself")
Core.errors.found, Core.errors["Broken: giving back"], Core.errors["Broken: it stopped"], Core.errors["Demo: the game's own demo is back"] = nil, nil, nil, nil

-- Later: once, a moment later, however often it is asked for
local runs = 0
local soon = Core.Later(function() runs = runs + 1 end)
soon() soon() soon()
check(runs == 0, "asked for later, it does not run at once")
W.Wait(0.1)
check(runs == 1, "it runs once, the next frame")
soon()
W.Wait(0.1)
check(runs == 2, "and again when asked again")

-- Game events ---------------------------------------------------------------------------
local heard = {}
Core.On("ZONE_CHANGED", function() error("first listener fails") end)
Core.On("ZONE_CHANGED", function(where) heard[#heard + 1] = where end)
W.caught = {}
W.Fire("ZONE_CHANGED", "Elwynn")
check(heard[1] == "Elwynn", "one listener's error does not keep the next from hearing the event")
check(#W.caught == 1 and W.caught[1]:find("first listener fails"), "and the game's error handler gets it")
W.caught = nil
Core.On("NOT_A_REAL_EVENT", function() end)
check(true, "an event this client does not know is skipped")

-- Listening stops; a listener taken away while the event is sent still hears that one
local offHeard = 0
local function Once() offHeard = offHeard + 1; Core.Off("ZONE_CHANGED_INDOORS", Once) end
local function Stays() offHeard = offHeard + 10 end
Core.On("ZONE_CHANGED_INDOORS", Once)
Core.On("ZONE_CHANGED_INDOORS", Stays)
W.Fire("ZONE_CHANGED_INDOORS")
W.Fire("ZONE_CHANGED_INDOORS")
check(offHeard == 21, "Core.Off: a listener that leaves while the event is sent misses only the next ones; the others hear every one")
Core.Off("ZONE_CHANGED_INDOORS", Stays)
W.Fire("ZONE_CHANGED_INDOORS")
check(offHeard == 21, "the last one gone, the event reaches nobody")

-- An event of one unit only
local auras = {}
local function Aura(unit) auras[#auras + 1] = unit end
Core.OnUnit("UNIT_AURA", "player", Aura)
W.Fire("UNIT_AURA", "party1")
W.Fire("UNIT_AURA", "player")
check(#auras == 1 and auras[1] == "player", "Core.OnUnit: the game sends the event for that unit alone")
Core.OffUnit("UNIT_AURA", "player", Aura)
W.Fire("UNIT_AURA", "player")
check(#auras == 1, "and Core.OffUnit stops it")

-- After the fight
local afterRuns = {}
check(Core.AfterCombat("now", function(a) afterRuns[#afterRuns + 1] = a end, "free") and afterRuns[1] == "free",
    "Core.AfterCombat: out of a fight it runs at once")
W.combat = true
check(not Core.AfterCombat("place", function(a) afterRuns[#afterRuns + 1] = a end, "first") and Core.Owed("place"), "in a fight it waits")
Core.AfterCombat("place", function(a) afterRuns[#afterRuns + 1] = a end, "last")
Core.AfterCombat("other", function() error("fails after the fight") end)
check(Core.Restricted(), "a fight is a restriction")
W.combat = false
W.printed = {}
W.Fire("PLAYER_REGEN_ENABLED")
check(#afterRuns == 2 and afterRuns[2] == "last" and not Core.Owed("place"), "the fight over, the same key asked twice runs once, as asked last")
check(printedMatch("problem in other, noted"), "a failing one is caught and told under its key; the others ran")
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 1)
check(Core.Restricted(), "the game's restrictions count from their announcement (an encounter)")
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 5, 2)
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 0)
check(not Core.Restricted(), "until they end; the chat's restriction does not hold the work up")
local guarded = W.NewWidget("Frame")
function guarded:IsProtected() return true end
W.combat = true
check(Core.Locked(guarded) and not Core.Locked(W.NewWidget("Frame")), "Core.Locked: a protected frame in a fight")
W.combat = false

-- An action the game blocked because of Sane UI's code is noted; another addon's is not ours
W.printed = {}
W.Fire("ADDON_ACTION_BLOCKED", "SaneUI_Social", "Frame:Hide()")
W.Fire("ADDON_ACTION_FORBIDDEN", "SomeOther", "CastSpell()")
check(Core.errors["blocked action"] and Core.errors["blocked action"].text:find("SaneUI_Social") and printedMatch("problem in blocked action"),
    "the game's blocked actions of ours are in the error log")
check(not tostring(Core.errors["blocked action"].text):find("SomeOther"), "another addon's are left alone")

-- Many kinds of problem: the list of kinds stays short
for index = 1, 130 do Core.NoteError("many " .. index, "again") end
local kinds = 0
for _ in pairs(Core.errors) do kinds = kinds + 1 end
check(kinds <= 100, "the error log keeps at most a hundred kinds of problem")

-- A switch set from elsewhere than the options page (a menu, a command)
local before = #toldDemo
local loudWas = Core.Settings("Demo").loud
check(Core.Set("Demo", "loud", not loudWas) == not loudWas and toldDemo[#toldDemo] == "loud=" .. tostring(not loudWas),
    "Core.Set: written, and the module is told")
check(Core.Set("Demo", "loud", "nonsense") == true and Core.Settings("Demo").loud == true, "a value of the wrong kind gets the default")
Core.Set("Demo", "loud", loudWas)
local count = #toldDemo
Core.Set("Demo", "loud", loudWas)
check(#toldDemo == count and count > before, "the same value again tells nobody")
check(Core.Set("Demo", "nothing", 1) == nil and Core.Described("Demo", "shy").text == "Be shy", "a switch nobody describes is not set; a described one is found")

-- The kit: the game's words, colours, pools, dialogs, a frame of the game's lent for a while
check(Core.Word("CLOSE", "Shut") == "Close" and Core.Word("NO_SUCH_STRING", "Ours") == "Ours", "the game's own words where it has them")
local red, green, blue = Core.RGB("FF8000")
check(red == 1 and green > 0.5 and green < 0.51 and blue == 0 and Core.RGB("nope") == nil and Core.Hex(1, 0.5, 0) == "FF8000",
    "colours as six hex digits, and back")
local made = 0
local pool = Core.Pool(function() made = made + 1; return W.NewWidget("Frame") end)
local first, second = pool:Take(), pool:Take()
pool:Done()
pool:Begin()
check(pool:Take() == first and made == 2, "a pool makes a part only when it has no free one")
pool:Done()
check(first:IsShown() and not second:IsShown(), "and hides what a round did not take")
W.popups = {}
local yes = 0
Core.Confirm("Delete %s?", "this", function() yes = yes + 1 end)
W.popups[1].data.callback()
check(W.popups[1].which == "GENERIC_CONFIRMATION" and W.popups[1].data.text_arg1 == "this" and yes == 1, "a question in the game's own dialog")
local typedName
Core.AskText("Name:", nil, "Save", "Old", function(text) typedName = text end, 20)
W.popups[2].data.callback("New")
check(W.popups[2].box.text == "Old" and W.popups[2].data.maxLetters == 20 and typedName == "New", "a name asked in the game's own dialog")
local seat, home = W.NewWidget("Frame"), W.NewWidget("Frame")
local borrowed = W.NewWidget("Frame", nil, home)
borrowed:SetPoint("TOPLEFT", home, "TOPLEFT", 5, 5)
borrowed:SetAlpha(0.5)
local lent = Core.Lend(borrowed)
lent:SetParent(seat)
lent:SetPoints(function(frame) frame:ClearAllPoints(); frame:SetPoint("CENTER") end)
lent:SetAlpha(1)
lent:SetAlpha(0.2)
check(lent:Lent() and borrowed:GetParent() == seat and borrowed:GetAlpha() == 0.2, "Core.Lend: a frame of the game's changed for a while")
lent:Return()
local point = borrowed:GetPoint(1)
check(not lent:Lent() and borrowed:GetParent() == home and point == "TOPLEFT" and borrowed:GetAlpha() == 0.5,
    "and given back as it was, its alpha as before the first change")
lent:SetParent(seat)
local other = W.NewWidget("Frame")
borrowed:SetParent(other)
lent:Return()
check(borrowed:GetParent() == other, "a parent the game gave it since is left as it is")
function borrowed:IsProtected() return true end
W.combat = true
check(lent:SetParent(seat) == false and borrowed:GetParent() == other, "a protected frame is not changed in a fight")
borrowed.IsProtected = nil
W.combat = false
check(Core.Fuzzy.Plain("|cffff0000Red|r |Hitem:1|h[Sword]|h |TInterface\\Icons\\X:0|t") == "Red [Sword] ", "a text of the game's without its codes, for finding")

-- Messages inside a module ----------------------------------------------------------------
local got
demo.Listen("PING", function(a, b) got = a + b end)
demo.Listen("PING", function() error("second listener fails") end)
broken.Listen("PING", function() got = "wrong module" end)
W.printed = {}
demo.Fire("PING", 2, 3)
check(got == 5, "a module's files talk through messages of their own")
check(printedMatch("problem in Demo: ping2, noted"), "a failing listener is caught there too")
demo.Fire("NOBODY_LISTENS")

-- Secret values -----------------------------------------------------------------------------
check(Core.Plain(5) == 5 and not Core.Secret(5), "a value from the game is used as it is")
issecretvalue = function(value) return value == "hidden" end
check(Core.Secret("hidden") and Core.Plain("hidden") == nil and Core.Plain("open") == "open", "but a value the game hides in combat counts as not there")
check(Core.Ask(function(a) return a, "hidden", 3 end, 1) == 1 and select(2, Core.Ask(function() return 1, "hidden" end)) == nil,
    "asking the game gives its answers, a hidden one as nil")
issecretvalue = nil
check(Core.Ask(nil) == nil and Core.Ask(function() error("gone") end) == nil, "a function that is not there, or fails, answers nil")
check(Core.Coins("lots") == nil, "money that is no number is not written")

-- Anchors kept and put back
local box = W.NewWidget("Frame", "SaneUITestBox")
box:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 3, -4)
local kept = Core.Points(box)
box:ClearAllPoints()
box:SetPoint("CENTER")
Core.Repoint(box, kept)
local point, relativeTo, relativePoint, x, y = box:GetPoint(1)
check(box:GetNumPoints() == 1 and point == "TOPLEFT" and relativeTo == UIParent and relativePoint == "TOPLEFT" and x == 3 and y == -4,
    "a frame's anchors are kept and put back")

-- Profiles: the next session --------------------------------------------------------------
-- This character logs out; the game writes the saved settings and reads them at the next login.
before = captured
W.Fire("PLAYER_LOGOUT")
check(SaneUIDB.account == nil and captured == before + 1 and SaneUIDB.profiles.Solo.Demo.shy == false and SaneUIDB.profiles.Solo.Demo.outside.taken == captured,
    "at logout the settings are brought up to date and saved into its profile, with Save at logout ticked")
local function Written(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = Written(inner) end
    return copy
end
local function NextSession(account, character)
    SaneUIDB, SaneUICharDB = Written(account), Written(character)
    Core.errors, Core.log = {}, {}
    W.Fire("ADDON_LOADED", "SaneUI")
end
SaneUIDB.characters[Core.charKey].autoLoad = true
SaneUIDB.profiles.Solo.Demo.loud = true
NextSession(SaneUIDB, SaneUICharDB)
check(SaneUIDB.modules.Demo.options.loud == true and SaneUIDB.account.Demo.loud == false,
    "with Load at login, the character uses its profile before any module reads its settings; the account's are kept aside")
SaneUIDB.modules.Demo.options.shy = true
W.Fire("PLAYER_LOGOUT")
check(SaneUIDB.profiles.Solo.Demo.shy == true and SaneUIDB.modules.Demo.options.loud == false and SaneUIDB.account == nil,
    "its changes go into its profile at logout, and the account's are back where every character finds them")
-- A logout that does not finish (the account's still aside), and a character never seen comes next.
SaneUIDB.account = { Demo = { loud = false } }
SaneUIDB.modules.Demo.options.loud = true
UnitGUID = function() return "Player-70-00000003" end
NextSession(SaneUIDB, "spoiled")
check(SaneUIDB.modules.Demo.options.loud == false and SaneUIDB.account == nil and type(SaneUICharDB) == "table",
    "the account's settings, still kept aside, are put back in use first")
-- That other one has its own settings for one module.
SaneUIDB.perCharacter.Demo = true
SaneUICharDB.settings = { Demo = { loud = true } }
NextSession(SaneUIDB, SaneUICharDB)
check(SaneUIDB.modules.Demo.options.loud == true and SaneUIDB.account.Demo.loud == false and SaneUIDB.account.Core == nil,
    "a module not account wide takes this character's own at login, the others the account's")
-- That one is given SaneUI Defaults with Load at login (and Save at logout, which does not count for it).
-- A profile a player called so before it was there keeps its settings under another name.
W.Fire("PLAYER_LOGOUT")
SaneUIDB.characters["Player-70-00000003"] = { name = "Third", profile = "SaneUI Defaults", autoLoad = true, autoSave = true }
SaneUIDB.profiles["SaneUI Defaults"], SaneUIDB.profiles.Empty = { Demo = { loud = false } }, { Demo = { loud = true } }
SaneUIDB.modules.Demo.options.shy = true
SaneUIDB.modules.Sync.options.off.CONTROLS_LABEL = true
NextSession(SaneUIDB, SaneUICharDB)
check(SaneUIDB.profiles["SaneUI Defaults"] == nil and SaneUIDB.profiles["SaneUI Defaults (old)"].Demo.loud == false
    and SaneUIDB.profiles.Empty == nil and SaneUIDB.profiles["Empty (old)"].Demo.loud == true,
    "saved profiles called SaneUI Defaults or Empty are kept as SaneUI Defaults (old), Empty (old)")
check(SaneUIDB.modules.Demo.options.loud == true and SaneUIDB.modules.Demo.options.shy == false and SaneUIDB.account.Demo.shy == true,
    "with Load at login, every switch is at its default before any module reads them; the account's are kept aside")
check(next(SaneUIDB.modules.Gone.options) == nil and SaneUIDB.account.Gone.x == 1,
    "a module whose addon is read later starts empty: it gets its defaults when it describes its switches")
check(SaneUIDB.modules.Sync.options.off.CONTROLS_LABEL == true and SaneUIDB.account.Sync == nil,
    "the game's settings Sync keeps stay the account's")
check(Profiles.Character("Player-70-00000003").profile == "SaneUI Defaults" and not Profiles.Character("Player-70-00000003").autoSave,
    "its line shows SaneUI Defaults, without Save at logout")
SaneUICharDB.settings.Demo.loud = false -- this character's own, kept while the profile is in use (Demo is not account wide)
Profiles.Load("Empty")
check(SaneUIDB.modules.Demo.options.loud == false and SaneUIDB.modules.Sync.options.off.CONTROLS_LABEL == true,
    "loading Empty puts the kept settings back in use: here this character's own")
SaneUIDB.modules.Demo.options.loud = false
W.Fire("PLAYER_LOGOUT")
check(SaneUIDB.profiles["SaneUI Defaults"] == nil and SaneUIDB.modules.Demo.options.shy == true and SaneUIDB.modules.Gone.options.x == 1
    and SaneUIDB.account == nil, "at logout nothing is saved into it, and the account's settings are back")
-- A line that names Empty (an older version, a hand edit) has no profile: what is changed is kept at logout.
-- A profile called Empty from before is kept under a free name.
SaneUIDB.characters["Player-70-00000003"] = { name = "Third", profile = "Empty", autoLoad = true, autoSave = true }
SaneUIDB.profiles.Empty = { Demo = { loud = false } }
NextSession(SaneUIDB, SaneUICharDB)
check(SaneUIDB.profiles["Empty (old 2)"] and SaneUIDB.profiles["Empty (old 2)"].Demo.loud == false and SaneUIDB.profiles["Empty (old)"].Demo.loud == true,
    "a name taken by an earlier move: the profile gets the next free one")
SaneUIDB.modules.Demo.options.shy = false
W.Fire("PLAYER_LOGOUT")
NextSession(SaneUIDB, SaneUICharDB)
check(SaneUIDB.modules.Demo.options.shy == false, "a line that names Empty keeps the settings changed in the session")
-- A module renamed (Chat is Social now): what was kept under its old name moves to the new one, once.
SaneUIDB.modules.Chat, SaneUIDB.perCharacter.Chat = { options = { window = false } }, true
SaneUIDB.profiles.Solo.Chat, SaneUIDB.profiles.Solo.Social = { window = false }, { window = true }
SaneUICharDB.settings = SaneUICharDB.settings or {}
SaneUICharDB.settings.Chat = { window = false }
NextSession(SaneUIDB, SaneUICharDB)
check(SaneUIDB.modules.Chat == nil and SaneUIDB.modules.Social.options.window == false and SaneUIDB.perCharacter.Social == true
    and SaneUICharDB.settings.Social.window == false and SaneUIDB.profiles.Solo.Chat == nil and SaneUIDB.profiles.Solo.Social.window == true,
    "a renamed module's saved settings move to its new name, everywhere; what the new name already has stays")
SaneUIDB.modules.Social, SaneUIDB.perCharacter.Social, SaneUIDB.profiles.Solo.Social, SaneUICharDB.settings.Social = nil, nil, nil, nil
SaneUIDB.characters["Player-70-00000003"].profile = nil
-- New Characters with a profile and Load at login: a character never seen takes them at its first login.
Profiles.SetCharacter(Profiles.NEW, "profile", "Solo")
Profiles.SetCharacter(Profiles.NEW, "autoLoad", true)
SaneUIDB.modules.Demo.options.loud = not SaneUIDB.profiles.Solo.Demo.loud
UnitGUID = function() return "Player-70-00000004" end
NextSession(SaneUIDB, nil)
local fourth = SaneUIDB.characters["Player-70-00000004"]
check(fourth and fourth.profile == "Solo" and fourth.autoLoad and not fourth.autoSave and fourth ~= SaneUIDB.newCharacters,
    "a character never seen gets the line of New Characters as its own")
check(SaneUIDB.modules.Demo.options.loud == SaneUIDB.profiles.Solo.Demo.loud and SaneUIDB.account.Demo.loud ~= SaneUIDB.profiles.Solo.Demo.loud,
    "and uses that profile from its very first login, before any module reads its settings")
Profiles.Delete("Solo")
check(SaneUIDB.newCharacters.profile == nil and fourth.profile == nil, "a profile deleted is taken off New Characters too")

-- Players' names ----------------------------------------------------------------------
-- WoW: Forever names a player by a first name and a surname, unique together across the region; players
-- can share either one. Retail names a player by one name, unique on its realm.
check(Core.Surnames() and Core.FullName("player") == "Tester Stub" and Core.PlayerKey("player") == "Tester Stub",
    "Forever: a player's name and key are the first name and surname as one")
check(Core.PlayerKeyOf("Droopy Fairwind") == "Droopy Fairwind" and Core.PlayerKeyOf(" Droopy Fairwind ") == "Droopy Fairwind"
    and Core.PlayerKeyOf("Droopy Fairwind-Stormrage") == "Droopy Fairwind", "a whole name from an event, with or without a realm, is one key")
check(Core.PlayerKeyOf("Droopy Fairwind") ~= Core.PlayerKeyOf("Droopy Brightwater")
    and Core.PlayerKeyOf("Ama Fairwind") ~= Core.PlayerKeyOf("Droopy Fairwind"), "the same first name, or the same surname: two players")
check(Core.PlayerKeyOf("Droopy") == nil and Core.PlayerKeyOf("Droopy-Stormrage") == nil and Core.PlayerKeyOf("") == nil
    and Core.PlayerKeyOf(nil) == nil and Core.PlayerKeyOf(42) == nil and Core.PlayerKeyOf("-Stormrage") == nil,
    "a first name alone is no player's key: dropped, never guessed")
local unitName, unitIsPlayer = UnitName, UnitIsPlayer
UnitName = function() return "Droopy", nil end
check(Core.PlayerKey("target") == nil and Core.FullName("target") == "Droopy", "a unit whose surname the game does not give has no key")
UnitName = function() return "Droopy Fairwind", nil end
check(Core.PlayerKey("target") == "Droopy Fairwind", "a name that holds the surname already")
UnitName, UnitIsPlayer = function() return "Marshal Dughan", nil end, function() return false end
check(Core.PlayerKey("target") == nil and Core.FullName("target") == "Marshal Dughan", "a creature is no player: no key")
UnitIsPlayer = unitIsPlayer
-- Retail: UnitName's second answer is a realm, never shown as a surname
WOW_PROJECT_ID, W.regionalNames = 1, false
UnitName = function(unit) if unit == "target" then return "Thrall", "Draenor" end return "Jaina", nil end
check(not Core.Surnames() and Core.FullName("target") == "Thrall" and Core.FullName("player") == "Jaina",
    "Retail: the name alone is shown, not the realm as a surname")
check(Core.PlayerKey("target") == "Thrall-Draenor" and Core.PlayerKey("player") == "Jaina-Stub", "Retail: the key is name and realm")
check(Core.PlayerKeyOf("Thrall-Draenor") == "Thrall-Draenor" and Core.PlayerKeyOf("Thrall") == "Thrall-Stub"
    and Core.PlayerKeyOf("Droopy Fairwind") == nil, "Retail: the own realm added; a name with a space is none")
W.regionalNames = true
check(Core.Surnames() and Core.PlayerKeyOf("Droopy Fairwind") == "Droopy Fairwind", "another client with regional names: first name and surname too")
WOW_PROJECT_ID, UnitName = 18, unitName

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Core: all %d checks passed.\n"):format(passed))
