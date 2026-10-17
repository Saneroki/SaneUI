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
check(Core.Settings("Core").errors == true and Core.general == Core.Settings("Core") and SaneUIDB.profiles.Accountwide.Core == Core.general,
    "the general switches are kept with every module's, in the profile Accountwide at first, with their defaults")
check(SaneUIDB.version == 2 and SaneUIDB.profiles.Accountwide.Demo.shy == true and rawget(SaneUIDB.modules.Demo, "options") == nil,
    "settings of the first shape (the account's, beside each module's store) are in the profile Accountwide now")

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
-- One of the page's dropdowns of profiles: what it lists, which is ticked, choosing one.
local function Menu(label) return Control(label).widget end
local function Items(menu)
    menu:GenerateMenu()
    return menu._items
end
local function Names(menu)
    local list = {}
    for _, item in ipairs(Items(menu)) do list[#list + 1] = item.text end
    return table.concat(list, ", ")
end
local function Ticked(menu)
    for _, item in ipairs(Items(menu)) do if item.checked(item.data) then return item.text end end
    return ""
end
local function Pick(menu, name)
    for _, item in ipairs(Items(menu)) do if item.text == name then item.fn(item.data) end end
end
local function Dialog() return W.popups[#W.popups] end
local onCheck, profileMenu = Control("Accountwide settings"), Menu("Profile")
local buttons = {}
for _, name in ipairs({ "New", "Rename", "Delete", "Defaults", "Export", "Import" }) do buttons[name] = Control(name) end

local tabNames = {}
for index, tab in ipairs(canvas.tabs) do tabNames[index] = tab.Text._text end
check(table.concat(tabNames, ", ") == "Profiles, Game settings, CVars", "its tabs: Profiles, Game settings and CVars")
check(canvas.parts[1]:IsShown() and not canvas.parts[2]:IsShown(), "the first is shown at first")
check(Shows("Profiles keep the settings of Sane UI and of the game"), "over the tabs a line says what profiles are")
check(Shows("Accountwide") and Shows("This character") and Shows("Characters"), "the tab Profiles: boxes Accountwide, This character, Characters")
check(onCheck and onCheck:GetChecked() and Profiles.On() and Shows("every character uses the profile Accountwide"),
    "first Accountwide settings, on at first, and what it means")
check(Names(profileMenu) == "Accountwide" and Ticked(profileMenu) == "Accountwide" and Profiles.InUse() == "Accountwide",
    "this character's profile: at first the only one there is, Accountwide")
for _, name in ipairs({ "New", "Rename", "Delete", "Defaults", "Export", "Import" }) do check(buttons[name], "a button " .. name) end
check(buttons.New:IsEnabled() and not buttons.Rename:IsEnabled() and not buttons.Delete:IsEnabled() and buttons.Defaults:IsEnabled(),
    "Accountwide is always there: it cannot be renamed or deleted")
local me, alt = Config.characters["Player-70-0000ABCD"], Config.characters["Player-70-00000002"]
check(me and alt and me.name._text:find("Tester Stub", 1, true) and me.name._text:find("this character") and alt.name._text:find("Alt")
    and not alt.name._text:find("this character"), "Characters: every character seen by its whole name, this one marked")
check(Ticked(me.menu) == "Accountwide" and Ticked(alt.menu) == "Accountwide" and alt.forget and not me.forget,
    "each with its profile, Accountwide at first; the others can be forgotten, not the one played")
local newRow = Config.characters[Profiles.NEW]
check(newRow and newRow.name._text == "New Characters" and Ticked(newRow.menu) == "Accountwide",
    "first a line New Characters: the profile a character not seen yet starts with")
Click(canvas.tabs[3])
check(canvas.parts[3]:IsShown() and not canvas.parts[1]:IsShown() and canvas.parts[3].list, "the tab CVars shows the list of the game's CVars")
check(Shows("Every console setting of the game."), "under a line that says what it is for")
Click(canvas.tabs[1])

-- New: a copy of the settings in use under a name asked for in the game's own dialog, used from then on
local held = Core.Settings("Demo")
loud.setting:SetValue(false)
Click(buttons.New)
local dialog = Dialog()
check(dialog.which == "GENERIC_INPUT_BOX" and dialog.data.maxLetters == 32 and dialog.data.acceptText == "New" and dialog.box.text == "",
    "New asks for a name in the game's own dialog")
W.printed = {}
local before = captured
dialog.data.callback("  Quiet ")
local quiet = SaneUIDB.profiles.Quiet
check(captured > before and quiet.Demo.outside.taken == before + 1,
    "before a profile is made, a module whose settings hold something of the game's brings it up to date")
check(quiet and quiet.Demo.loud == false and quiet.Demo.shy == true and quiet.Core.errors == true,
    "it holds the settings of every module, under the name without the spaces around it")
check(Profiles.InUse() == "Quiet" and Core.Settings("Demo") == held and quiet.Demo == held and demo.DB.options == held,
    "this character uses it: the table the module holds is the same, and lives in the new profile now")
check(SaneUIDB.profiles.Accountwide.Demo ~= held and SaneUIDB.profiles.Accountwide.Demo.loud == false,
    "Accountwide keeps a copy of its own of what it had")
check(printedMatch("the profile Quiet is made"), "chat says so")
W.Wait(0.1)
check(Ticked(profileMenu) == "Quiet" and Names(profileMenu) == "Accountwide, Quiet" and buttons.Rename:IsEnabled() and buttons.Delete:IsEnabled(),
    "a moment later the page shows it: chosen, listed after Accountwide; it can be renamed and deleted")
check(Profiles.Create("quiet") == false and Profiles.Create("  ") == false and Profiles.Create("Quiet") == false,
    "a name needs letters, and one that is taken is refused, in any letter case")

-- A change goes into the profile in use, and only there
loud.setting:SetValue(true)
check(quiet.Demo.loud == true and SaneUIDB.profiles.Accountwide.Demo.loud == false, "a change is the profile's in use, the others keep theirs")

-- Another profile in use: the modules are told what differs
local toldBefore = #toldDemo
Pick(profileMenu, "Accountwide")
check(Profiles.InUse() == "Accountwide" and Core.Settings("Demo") == held and held.loud == false and SaneUIDB.profiles.Accountwide.Demo == held,
    "chosen, the module's table takes the settings of Accountwide, and lives there now")
check(toldDemo[toldBefore + 1] == "loud=false" and #toldDemo == toldBefore + 1, "the module is told of what changed, only that")
check(quiet.Demo.loud == true and quiet.Demo ~= held, "Quiet keeps what it had, as a copy of its own")
check(printedMatch("this character uses the profile Accountwide"), "chat says so")
Pick(profileMenu, "Quiet")

-- Rename
Click(buttons.Rename)
dialog = Dialog()
check(dialog.box.text == "Quiet" and dialog.box.highlighted and dialog.data.text_arg1 == "Quiet", "Rename offers the name, marked")
dialog.data.callback("Solo")
check(SaneUIDB.profiles.Solo == quiet and SaneUIDB.profiles.Quiet == nil and Profiles.InUse() == "Solo"
    and Profiles.Character(Core.charKey).profile == "Solo", "renamed, it stays in use, every character that had it keeps it")
check(Profiles.Rename("Solo", "Accountwide") == false and Profiles.Rename("Accountwide", "Mine") == false and SaneUIDB.profiles.Accountwide,
    "a name taken is refused; Accountwide keeps its name")

-- Copy from another profile
local copyMenu = Menu("Copy from")
check(Names(copyMenu) == "Accountwide", "Copy from lists the other profiles, not the one in use")
Pick(copyMenu, "Accountwide")
dialog = Dialog()
check(dialog.which == "GENERIC_CONFIRMATION" and dialog.data.text_arg1 == "Accountwide" and held.loud == true, "it asks first")
dialog.data.callback()
check(Profiles.InUse() == "Solo" and held.loud == false and SaneUIDB.profiles.Accountwide.Demo.loud == false and SaneUIDB.profiles.Accountwide.Demo ~= held,
    "the profile in use takes the other's settings, as a copy")

-- Defaults: Sane UI's settings in the profile in use back to their defaults; the game's stay
local syncTaken = Core.Settings("Sync").taken
syncTaken.marker = { kept = true }
shy.setting:SetValue(false)
Click(buttons.Defaults)
Dialog().data.callback()
check(held.loud == true and held.shy == false and Core.Settings("Sync").taken.marker and Core.Settings("Sync").taken.marker.kept,
    "every setting of Sane UI at its default, the game's as they were")
syncTaken.marker = nil

-- Export and import, as a line of text
Click(buttons.Export)
local textWindow = SaneUIProfileText
local text = textWindow.Box:GetText()
local value = Core.Serial.Read(text)
check(textWindow:IsShown() and type(value) == "table" and value.kind == "Sane UI profile" and value.name == "Solo"
    and value.settings.Demo.loud == true, "Export shows the profile in use as a line of text to copy")
textWindow:Hide()
Click(buttons.Import)
textWindow.Box:SetText(text)
Click(textWindow.Act)
dialog = Dialog()
check(dialog.which == "GENERIC_INPUT_BOX" and dialog.box.text == "Solo", "Import asks for the new profile's name, the text's own offered")
dialog.data.callback("Shared")
check(SaneUIDB.profiles.Shared and SaneUIDB.profiles.Shared.Demo.loud == true and not textWindow:IsShown()
    and printedMatch("the profile Shared is imported"), "and keeps it under that name")
check(Profiles.Import("nonsense") == false and Profiles.Import(Core.Serial.Write({ kind = "other" })) == false
    and Profiles.Import(text, "Shared") == false, "a text that is no profile, or a name that is taken, is refused")

-- The characters' profiles
Pick(alt.menu, "Solo")
check(SaneUIDB.characters["Player-70-00000002"].profile == "Solo" and Profiles.InUse() == "Solo", "another character is given a profile for its next login")
Pick(newRow.menu, "Shared")
check(SaneUIDB.newProfile == "Shared", "and the characters not seen yet")
Pick(me.menu, "Shared")
check(Profiles.InUse() == "Shared", "this character's, at once")
Pick(me.menu, "Solo")

-- Delete
Click(buttons.Delete)
dialog = Dialog()
check(dialog.data.showAlert and dialog.data.text_arg1 == "Solo", "Delete asks first, with the game's warning sign")
dialog.data.callback()
check(SaneUIDB.profiles.Solo == nil and Profiles.InUse() == "Accountwide" and SaneUIDB.characters["Player-70-00000002"].profile == nil
    and Core.Settings("Demo") == held, "deleted, the characters that had it use Accountwide, this one at once")
check(Profiles.Delete("Accountwide") == false, "Accountwide cannot be deleted")

-- Forget a character: its line and what every module kept for it
demo.DB.chars["Player-70-00000002"] = { note = "theirs" }
Click(alt.forget)
Dialog().data.callback()
check(SaneUIDB.characters["Player-70-00000002"] == nil and demo.DB.chars["Player-70-00000002"] == nil, "forgotten, nothing of it is kept")
check(Profiles.Forget(Core.charKey) == false, "not the one played")

-- Accountwide off: each character keeps its own settings
local loudWas = held.loud
Tick(onCheck, false)
check(not Profiles.On() and Profiles.InUse() == nil and SaneUICharDB.settings.Demo == held and held.loud == loudWas,
    "switched off, this character keeps what it uses as its own: the module's table lives in its file now")
check(SaneUIDB.profiles.Accountwide.Demo.loud == loudWas and SaneUIDB.profiles.Accountwide.Demo ~= held, "its profile keeps a copy")
check(SaneUICharDB.settings.Sync == nil, "the game's settings are kept nowhere then")
W.Wait(0.1)
check(not buttons.New:IsEnabled() and not buttons.Defaults:IsEnabled(), "the profiles' buttons are switched off")
loud.setting:SetValue(not loudWas)
check(SaneUIDB.profiles.Accountwide.Demo.loud == loudWas and held.loud == not loudWas, "a change is this character's alone")
Tick(onCheck, true)
dialog = Dialog()
check(not Profiles.On() and dialog.which == "GENERIC_CONFIRMATION" and dialog.data.text_arg1 == "Accountwide", "switching it on asks first")
dialog.data.callback()
check(Profiles.On() and Profiles.InUse() == "Accountwide" and held.loud == loudWas and SaneUIDB.profiles.Accountwide.Demo == held,
    "on again, this character takes its profile's settings")
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
local held = Core.Settings("Demo")
before = captured
W.Fire("PLAYER_LOGOUT")
check(captured == before + 1 and Core.Settings("Demo") == held and SaneUIDB.profiles.Accountwide.Demo == held,
    "at logout the game's settings are brought up to date; everything stays where it lives")
Profiles.Create("Raid")
Profiles.Use("Raid")
Core.Set("Demo", "loud", false)
NextSession(SaneUIDB, SaneUICharDB)
check(Profiles.InUse() == "Raid" and Core.Settings("Demo").loud == false and Core.Settings("Demo") == SaneUIDB.profiles.Raid.Demo,
    "the next session, this character uses its profile before any module reads its settings")
check(SaneUICharDB.key == Core.charKey, "and its file says which character it is")

-- The key of the file must not win over the game's own number for the character (a file copied from another)
SaneUICharDB.key = "Player-70-00000009"
NextSession(SaneUIDB, SaneUICharDB)
check(Profiles.InUse() == "Raid", "the game's number for the character counts, not a key copied with the file")

-- A character never seen, the game's number not known yet at the load: its profile from the login on
SaneUIDB.newProfile = "Shared"
local guid = UnitGUID
UnitGUID = function() return nil end
NextSession(SaneUIDB, nil)
check(Profiles.InUse() == "Accountwide", "before the game names it, it uses Accountwide")
UnitGUID = function() return "Player-70-00000004" end
local toldBefore = #toldDemo
W.Fire("PLAYER_LOGIN")
local fourth = SaneUIDB.characters["Player-70-00000004"]
check(fourth and fourth.profile == "Shared" and Profiles.InUse() == "Shared" and fourth.name == "Tester Stub",
    "named at the login, it gets the profile for new characters, and uses it from then on")
check(#toldDemo > toldBefore, "the modules are told of what changed")

-- Accountwide off: two characters, each with its own settings
Profiles.SetOn(false)
Core.Set("Demo", "shy", true)
local fourthFile = Written(SaneUICharDB)
UnitGUID = guid
NextSession(SaneUIDB, {})
check(not Profiles.On() and Profiles.InUse() == nil and SaneUICharDB.settings.Demo.shy == SaneUIDB.profiles.Raid.Demo.shy
    and Core.Settings("Demo").loud == false, "another character's own settings start as a copy of its profile's")
Core.Set("Demo", "loud", true)
local firstFile = Written(SaneUICharDB)
UnitGUID = function() return "Player-70-00000004" end
NextSession(SaneUIDB, fourthFile)
check(Core.Settings("Demo").shy == true and Core.Settings("Demo").loud == SaneUIDB.profiles.Shared.Demo.loud,
    "each keeps its own: the fourth has what it set")
-- On, then off again: own settings from before start anew
Profiles.SetOn(true)
check(Profiles.InUse() == "Shared" and Core.Settings("Demo").shy == SaneUIDB.profiles.Shared.Demo.shy, "on again, its profile")
Profiles.SetOn(false)
UnitGUID = guid
NextSession(SaneUIDB, firstFile)
check(Core.Settings("Demo").loud == SaneUIDB.profiles.Raid.Demo.loud, "own settings from an earlier time off start anew from the profile")
Profiles.SetOn(true)

-- A module installed later: in the profile it starts at its defaults; off, a copy of the profile's
SaneUIDB.profiles.Raid.Later = nil
local later = Core.Options("Later", { { key = "on", default = true, text = "On" } })
check(later and later.on == true and SaneUIDB.profiles.Raid.Later == later, "a module read later gets its settings in the profile in use")

-- What no description has any more goes; Core's own keys stay
Core.Settings("Demo").gone, Core.Settings("Demo")._mine = 1, 2
NextSession(SaneUIDB, SaneUICharDB)
check(Core.Settings("Demo").gone == nil and Core.Settings("Demo")._mine == 2, "a setting no module describes any more is left out")

-- A module whose settings changed their shape: its upgrade comes before the check of their kinds
SaneUIDB.profiles.Raid.Shaped = { size = true, colour = "red" } -- the first shape: big or not
SaneUIDB.profiles.Accountwide.Shaped = { size = "large", _version = 2 }
local shaped = Core.Options("Shaped", {
    { key = "size", default = "medium", text = "Size", choices = { { "small", "Small" }, { "medium", "Medium" }, { "large", "Large" } } },
}, { version = 2, upgrade = function(values, from)
    if from < 2 then values.size = values.size == true and "large" or "small" end
end })
check(shaped.size == "large" and shaped._version == 2 and shaped.colour == nil,
    "an older copy is brought up to date, not reset: the switch that became a choice keeps its meaning")
Profiles.Use("Accountwide")
check(shaped.size == "large" and SaneUIDB.profiles.Raid.Shaped._version == 2, "each copy carries its own version")
Profiles.Use("Raid")

-- The first shape of these settings (an earlier version of Sane UI) is brought over once
UnitGUID = guid
NextSession({
    modules = { Demo = { options = { loud = false, shy = true }, version = 1 }, Chat = { options = { window = false } } },
    account = { Demo = { loud = true, shy = true } }, -- kept aside by a logout that did not finish: the account's own
    profiles = { Raid = { Demo = { loud = false } }, Accountwide = { Demo = { shy = false } }, Unused = { Demo = { shy = false } } },
    characters = { ["Player-70-0000ABCD"] = { name = "Tester Stub", profile = "Raid", autoLoad = true, autoSave = true },
        ["Player-70-00000002"] = { name = "Alt", profile = "Unused", autoLoad = false } },
    newCharacters = { profile = "Raid", autoLoad = true },
    perCharacter = { Demo = true },
}, { settings = { Demo = { loud = true } }, profile = "Raid" })
check(SaneUIDB.version == 2 and SaneUIDB.profiles.Accountwide.Demo.loud == true and SaneUIDB.profiles.Accountwide.Demo.shy == true
    and SaneUIDB.profiles["Accountwide (old)"].Demo.shy == false, "the account's settings (also those kept aside) are the profile Accountwide; one called so before keeps its under another name")
check(SaneUIDB.profiles.Accountwide.Social.window == false and SaneUIDB.modules.Chat == nil, "a module renamed since is found under its new name")
check(SaneUIDB.characters["Player-70-0000ABCD"].profile == "Raid" and SaneUIDB.characters["Player-70-00000002"].profile == nil
    and SaneUIDB.characters["Player-70-0000ABCD"].autoLoad == nil and SaneUIDB.newProfile == "Raid",
    "a character that loaded its profile at login keeps it; one that did not uses Accountwide")
check(Profiles.On() and Profiles.InUse() == "Raid" and SaneUICharDB.settings == nil and SaneUIDB.perCharacter == nil
    and SaneUIDB.account == nil and SaneUIDB.newCharacters == nil, "all settings were account wide: Accountwide on, nothing of the first shape left")
check(SaneUIDB.profiles.Accountwide.Demo._version == 1, "a module's own count of its shape is carried by its copies")
NextSession({ modules = { Demo = { options = { loud = false } } }, separate = true }, { settings = { Demo = { loud = true } } })
check(not Profiles.On() and Core.Settings("Demo").loud == true and SaneUICharDB.since == 1,
    "every setting each character's own (All settings accountwide unticked): Accountwide off, each keeps its own")
Profiles.SetOn(true)
check(Profiles.InUse() == "Accountwide" and Core.Settings("Demo").loud == false, "switched on, the account's are in use")
Profiles.Create("Raid")
W.printed = {}
SlashCmdList.SANEUI("profile")
check(printedMatch("profiles: Accountwide, Raid%.") and printedMatch("This character uses Accountwide"), "/sane profile lists them")
SlashCmdList.SANEUI("profile raid")
check(Profiles.InUse() == "Raid" and printedMatch("uses the profile Raid"), "/sane profile <name> uses one, in any letter case")
SlashCmdList.SANEUI("profiles nothing")
check(Profiles.InUse() == "Raid" and printedMatch("there is no profile called nothing"), "a name that is none says so")
UnitGUID = guid

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
