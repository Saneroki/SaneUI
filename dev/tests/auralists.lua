-- Runs the Combat module's aura lists window (src/Combat/Units/Lists.lua) and its search (Core's SpellSearch.lua) against
-- the stand-in client (wowstub.lua) and small sets of Core's written here: one long list with a tick per mark and the X
-- in front, a spell kept with no tick until its X, the ticks of a side taking each other's place, a search over every
-- class's auras, the enemies' and the items' in groups, the best first, ranks of a name once, spells without an aura
-- left out, a spell's number, Enter and Escape. At its end it runs again as Retail loads the module ("retail":
-- W.Play), where the sets are another game's and a name finds only a spell of your own.
-- Usage, from the project folder:  lua5.1 dev/tests/auralists.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
local RETAIL = arg[1] == "retail"
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
local fight = require("combatclient").Install(W)
local units = fight.units

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:EnableMouse(on) self._mouse = on end
function methods:GetFrameLevel() return self._level or 1 end
function methods:SetFrameLevel(level) self._level = level end
function methods:SetTexture(texture) self._texture = texture return true end
function methods:SetFontObject(font) self._font = font end
function methods:LockHighlight() self._lit = true end
function methods:UnlockHighlight() self._lit = false end
function methods:Click(button) if self._scripts.OnClick then self._scripts.OnClick(self, button or "LeftButton", false) end end
local function noop() end
function methods:CreateAnimationGroup()
    local group = setmetatable({}, { __index = function() return noop end })
    function group:CreateAnimation() return setmetatable({}, { __index = function() return noop end }) end
    return group
end
EasingUtil = { OutQuartic = function(p) return 1 - (1 - p) ^ 4 end }
IsMouseButtonDown = function() return false end
GetCursorPosition = function() return 0, 0 end
GetBindingKey, GetBindingText = function() end, function(key) return key end
EventUtil = { ContinueOnAddOnLoaded = function() end }
TalentMicroButton, SpellbookMicroButton = W.NewWidget("Button", "TalentMicroButton"), W.NewWidget("Button", "SpellbookMicroButton")
ClearOverrideBindings, SetOverrideBinding = function() end, function() end
C_SpellBook.IsSpellBookItemLooseFlyoutMember = function() return false end
C_SpecializationInfo = { GetCombatConfigIDForSpecGroup = function(group) return 100 + group end }
for _, bar in ipairs({ MainActionBar, StanceBar }) do
    bar.UpdateDividers, bar.Update, bar.UpdateState = function() end, function() end, function() end
end
for _, button in ipairs(MainActionBar.actionButtons) do button.Update, button.UpdateButtonArt = function() end, function() end end
units.player = { name = "Droopy", surname = "Fairwind", player = true, class = "DRUID", level = 60, health = 850, most = 1000,
                 power = 30, powerMost = 100 }
NORMAL_FONT_COLOR = rawget(_G, "NORMAL_FONT_COLOR") or { WrapTextInColorCode = function(_, text) return "|cffffd100" .. text .. "|r" end }
W.spells[1459] = { name = "Arcane Intellect", icon = 135932 }
W.spells[774] = { name = "Rejuvenation", icon = 136081 }
C_Spell.GetSpellInfo = function(name) -- by name the game finds only your own spells, whatever the case
    for id, spell in pairs(W.spells) do
        if spell.name:lower() == tostring(name):lower() and id == 774 then
            return { spellID = id, name = spell.name, iconID = spell.icon }
        end
    end
end

-- Core's sets as the compiler writes them: three classes, their lines, the spells (Wrath and Rend put no aura on, a
-- second rank of Rejuvenation), the enemies' and the items' auras (two of one name).
local L, T = "\030", "\031"
local SETS = {
    { "Classes", '{ "name", "file", "description", "icon", "power", "color", "armor" }',
      '{ "text", "text", "text", "int", "int", "text", "int" }', {
        [1] = "Warrior\tWARRIOR\t\t626008\t1\tC69B6D\t127", [5] = "Priest\tPRIEST\t\t626004\t0\tFFFFFF\t1",
        [11] = "Druid\tDRUID\t\t625999\t0\tFF7C0A\t15" } },
    { "SkillLines", '{ "name", "kind", "class", "tree", "spells" }', '{ "text", "text", "int", "int", "list int" }', {
        [26] = "Arms\tclass\t1\t1\t6673" .. L .. "772",
        [56] = "Holy\tclass\t5\t2\t1243" .. L .. "139",
        [574] = "Balance\tclass\t11\t1\t774" .. L .. "1430" .. L .. "8936" .. L .. "1126" .. L .. "5176",
        [999] = "Herbalism\tprofession\t11\t\t2366" },
      'S.index.byClass = { [1] = "26", [5] = "56", [11] = "574" }' },
    { "Spells", '{ "name", "rank", "description", "icon", "cost", "castTime", "cooldown", "minRange", "maxRange", "effects" }',
      '{ "text", "text", "text", "int", "list tuple(power:int,amount:int)", "int", "int", "number", "number", '
      .. '"list tuple(index:int,effect:int,aura:int,points:number,perLevel:number,period:int,targets:int,misc:int,trigger:int)" }', {
        [774] = "Rejuvenation\tRank 1\t\t136081\t\t\t\t\t\t0" .. T .. "6" .. T .. "8",
        [1430] = "Rejuvenation\tRank 2\t\t136081\t\t\t\t\t\t0" .. T .. "6" .. T .. "8",
        [8936] = "Regrowth\tRank 1\t\t136085\t\t\t\t\t\t0" .. T .. "10" .. L .. "1" .. T .. "6" .. T .. "8",
        [1126] = "Mark of the Wild\tRank 1\t\t136078\t\t\t\t\t\t0" .. T .. "6" .. T .. "22",
        [5176] = "Wrath\tRank 1\t\t136006\t\t\t\t\t\t0" .. T .. "2",
        [6673] = "Battle Shout\tRank 1\t\t132333\t\t\t\t\t\t0" .. T .. "35" .. T .. "99",
        [772] = "Rend\tRank 1\t\t132155\t\t\t\t\t\t0" .. T .. "2",
        [1243] = "Power Word: Fortitude\tRank 1\t\t135987\t\t\t\t\t\t0" .. T .. "6" .. T .. "29",
        [139] = "Renew\tRank 1\t\t135953\t\t\t\t\t\t0" .. T .. "6" .. T .. "8",
        [2366] = "Herb Gathering\tApprentice\t\t136065" } },
    { "CreatureSpells", '{ "name", "description", "icon", "school", "castTime", "minRange", "maxRange", "kind", "duration" }',
      '{ "text", "text", "int", "int", "int", "number", "number", "text", "int" }', {
        [3427] = "Infected Wound\t\t136134\t1\t\t\t\tdisease\t300000", [8040] = "Druid's Slumber\t\t136090\t8\t1500",
        [11639] = "Renew\t\t135953\t2" } },
    { "Auras", '{ "name", "description", "icon", "school", "source", "kind", "castTime", "duration" }',
      '{ "text", "text", "int", "int", "text", "text", "int", "int" }', {
        [430] = "Drink\t\t132794\t1\tfood", [431] = "Drink\t\t132794\t1\tfood", [15366] = "Songflower Serenade\t\t135934\t1\tworld" } },
}
local file = os.tmpname() .. "-AuraSets.lua"
local out = assert(io.open(file, "w"))
for index, set in ipairs(SETS) do
    out:write(("do local S = SaneUI.Core.Data.Add(1, %q, { game = \"forever\", hash = \"0000000%d\", build = 70755, "
        .. "key = \"int\", fields = %s, types = %s, patches = {} })\nif S then\n"):format(set[1], index, set[2], set[3]))
    for key, row in pairs(set[4]) do out:write(("S.rows[%d] = %q\n"):format(key, "0\t\t" .. row)) end
    if set[5] then out:write(set[5], "\n") end
    out:write("end end\n")
end
out:close()
W.AddSets(file)

if RETAIL then W.Play("retail") end
W.LoadCore(root)
os.remove(file)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Combat == ns and not ns.off, "the module is made and started")
local Lists, TEXT = ns.AuraLists, ns.TEXT
if not RETAIL then
    check(Core.Data.Set("Spells"):Get(774, "name") == "Rejuvenation", "the sets are there: "
          .. table.concat({ Core.Data.Set("Spells"):State() }, " ") .. " " .. table.concat(W.fileErrors or {}, "; "))
end

-- Some frames of the game: its timers and Core's scheduler (Data's jobs, a long search) run.
local function Frames()
    for _ = 1, 20 do
        local steps = Core.Steps.frame
        local run = steps:GetScript("OnUpdate")
        if run then run(steps, 0.02) end
        W.Wait(0.05)
    end
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
Lists.Open()
local box
for _, widget in ipairs(W.frames) do if widget._kind == "EditBox" and widget._template == "InputBoxTemplate" then box = widget end end
check(box ~= nil, "a search box over the list")

-- The list's lines shown now, by name; one by its name.
local function Shown()
    local found = {}
    for _, widget in ipairs(W.frames) do
        if widget.row and widget.ticks and widget._shown then found[#found + 1] = widget end
    end
    table.sort(found, function(a, b) return a.row.name < b.row.name end)
    return found
end
local function Line(name)
    for _, line in ipairs(Shown()) do if line.row.name == name then return line end end
end
-- The suggestions shown: their texts, in order, the colour codes and gold taken out.
local finder
local function Suggested()
    local texts = {}
    for _, widget in ipairs(W.frames) do
        if widget.glow and widget.text and widget._shown and widget._parent and widget._parent._shown then
            texts[#texts + 1] = { widget = widget, text = Core.Fuzzy.Plain(widget.text._text or ""), entry = widget.entry,
                                  top = widget._points[1] and widget._points[1][5] or 0 }
            finder = widget._parent
        end
    end
    table.sort(texts, function(a, b) return a.top > b.top end)
    return texts
end
local function Type(text)
    box:SetText(text)
    box._scripts.OnTextChanged(box, true)
    Frames()
end

check(#Shown() == 0, "nothing on the list at first")
-- A mark from a menu stands on the list too.
Lists.Put("white", { id = 782, name = "Thorns" })
local thorns = Line("Thorns")
check(thorns and thorns.ticks.white:GetChecked() == true and thorns.ticks.black:GetChecked() == false,
    "a spell marked Important in a menu: on the list, its tick on")
check(thorns.number._text == 782, "with its number")
-- The X in front of the name, the ticks in Saneroki's order to its right.
local take
for _, widget in ipairs(W.frames) do
    if widget._parent == thorns and widget._template == "UIPanelCloseButton" then take = widget end
end
check(take and take._points[1][1] == "LEFT" and take._points[1][3] == "LEFT", "the red X at the line's left, in front of all")
local xs = {}
for index, which in ipairs(Lists.COLUMNS) do xs[index] = thorns.ticks[which]._points[1][4] end
check(#Lists.COLUMNS == 3 and Lists.COLUMNS[1] == "hidden" and Lists.COLUMNS[2] == "black" and Lists.COLUMNS[3] == "white"
      and xs[1] < xs[2] and xs[2] < xs[3] and not thorns.ticks.hide and not thorns.ticks.show,
    "the ticks: Hidden, Unimportant, Important, left to right; Hide from and Prioritize on unit frames no columns now")
check(TEXT.auraFramesShow == "Prioritize on unit frames", "Show on unit frames is now Prioritize on unit frames")
check(thorns.cog and thorns.cog._points[1][4] > xs[3] and thorns.remind and thorns.remind._points[1][4] > thorns.cog._points[1][4]
      and not thorns.remind:GetChecked(), "right of the marks a cog in their place, last the tick Tracked: none yet")
thorns.cog._scripts.OnEnter(thorns.cog)
check(GameTooltip:IsOwned(thorns.cog) and GameTooltip._text == "Edit Tracked conditions" and TEXT.reminderTitle == GameTooltip._text,
    "the cog's tooltip: Edit Tracked conditions (Saneroki, 2026-11-09)")
thorns.cog._scripts.OnLeave(thorns.cog)
thorns.cog._scripts.OnClick(thorns.cog)
thorns = Line("Thorns")
check(thorns.mark._shown and ns.ReminderEditor.panel.name == "Thorns", "a click on it: the line chosen, its conditions below")

-- A tick of a side takes the place of the other of that side; the other side stays.
thorns.ticks.black:SetChecked(true)
thorns.ticks.black._scripts.OnClick(thorns.ticks.black)
thorns = Line("Thorns")
check(ns.options.auraBlack[782] and not ns.options.auraWhite[782] and thorns.ticks.black:GetChecked()
      and not thorns.ticks.white:GetChecked(), "Unimportant ticked: Important off")
Lists.Put("show", { id = 782, name = "Thorns" })
check(ns.options.auraShow[782] and ns.options.auraBlack[782], "Prioritize on unit frames beside it, a side of its own")
Lists.Put("hide", { id = 782, name = "Thorns" })
check(ns.options.auraHide[782] and not ns.options.auraShow[782] and Lists.Has("hide", "Thorns") and not Lists.Has("show", "Thorns"),
    "Hide from unit frames takes Prioritize's place")
-- Every tick off: it stays on the list, until its X.
local tick = Line("Thorns").ticks.black
tick:SetChecked(false)
tick._scripts.OnClick(tick)
Lists.Unmark("hide", "Thorns")
check(not ns.options.auraBlack[782] and not ns.options.auraHide[782] and Line("Thorns") ~= nil,
    "every tick off: no mark, still on the list")
take._scripts.OnClick(take)
check(Line("Thorns") == nil and ns.options.auraKept[782] == nil, "its X: off the list")

-------------------------------------------------------------------------------
--  The search
-------------------------------------------------------------------------------
if not RETAIL then
    Type("re")
    local found = Suggested()
    check(found[1] and found[1].entry == nil and found[1].text:find("^Priest"), "a search: the groups by their best find, "
          .. "Renew in the priest's first: " .. tostring(found[1] and found[1].text))
    check(found[2].entry and found[2].entry.name == "Renew", "under its title the find")
    local titles, names = {}, {}
    for _, line in ipairs(found) do
        if line.entry then names[#names + 1] = line.entry.name else titles[#titles + 1] = line.text end
    end
    check(titles[2] == "Enemies" and titles[3] == "Druid", "then the enemies' (as good as the priest's: the classes first), "
          .. "then the druid's: " .. table.concat(titles, ", "))
    local count = 0
    for _, name in ipairs(names) do if name == "Rejuvenation" then count = count + 1 end end
    check(count == 1, "two ranks of one name: once")
    check(finder and finder._shown, "the suggestions under the box")
    local wrath = false
    Type("wrath")
    for _, line in ipairs(Suggested()) do wrath = wrath or line.text == "Wrath" end
    check(not wrath and Suggested()[1].text == SaneUI.Core.SpellSearch.TEXT.searchNothing, "a spell that puts no aura on: not found")
    Type("drink")
    found = Suggested()
    check(found[1].text == SaneUI.Core.SpellSearch.TEXT.searchItems and found[2].entry.name == "Drink" and not found[3], "the items' auras, a name once")
    Type("rgw")
    found = Suggested()
    check(found[2] and found[2].entry and found[2].entry.name == "Regrowth", "forgiving: letters of it in their order")
    check(found[2].widget.text._text:find("|c"), "what was typed in it in gold")
    -- A click on one: on the list, lit, no tick yet.
    found[2].widget._scripts.OnClick(found[2].widget)
    local regrowth = Line("Regrowth")
    check(regrowth and ns.options.auraKept[8936] == "Regrowth" and regrowth.lit._shown, "a click: on the list, lit")
    for _, which in ipairs(Lists.COLUMNS) do check(not regrowth.ticks[which]:GetChecked(), "no tick yet: " .. which) end
    check(box:GetText() == "" and not finder._shown, "the box empty again, the suggestions gone")
    regrowth.ticks.white:SetChecked(true)
    regrowth.ticks.white._scripts.OnClick(regrowth.ticks.white)
    check(ns.options.auraWhite[8936] == "Regrowth" and Lists.Mark("Regrowth") == "white", "ticked Important: marked")
    -- Enter: the first suggestion; one there already stays as it is.
    Type("regrowth")
    box._scripts.OnEnterPressed(box)
    check(ns.options.auraWhite[8936] == "Regrowth" and #Shown() == 1, "Enter on one there already: as it was")
    Type("battle shout")
    box._scripts.OnEnterPressed(box)
    check(Line("Battle Shout") and ns.options.auraKept[6673], "Enter: the first, another class's")
    Type("infected")
    box._scripts.OnEnterPressed(box)
    check(Line("Infected Wound") and ns.options.auraKept[3427], "an enemy's aura")
    -- Up and Down: a find lit as the mouse would light it, round at the ends; Enter picks the lit one, as a click.
    Type("re")
    local finds = {}
    for _, line in ipairs(Suggested()) do if line.entry then finds[#finds + 1] = line end end
    local function Arrow(key) box._scripts.OnArrowPressed(box, key) end
    Arrow("DOWN")
    Arrow("DOWN")
    check(finds[2].widget._lit and not finds[1].widget._lit and GameTooltip._owner == finds[2].widget,
        "Down twice: the second find lit, its tooltip shown")
    Arrow("UP")
    Arrow("UP")
    check(finds[#finds].widget._lit and not finds[1].widget._lit, "Up on the first: round to the last")
    Arrow("DOWN")
    Arrow("DOWN")
    local second = finds[2].entry
    check(finds[2].widget._lit and second ~= finds[1].entry and not Line(second.name), "Down on the last: round to the first")
    box._scripts.OnEnterPressed(box)
    check(Line(second.name) and ns.options.auraKept[second.id] == second.name and not Line(finds[1].entry.name),
        "Enter: the lit one picked, not the first")
    check(box:GetText() == "" and not finder._shown and not finds[2].widget._lit, "the box empty again, nothing lit")
end

-- A spell's number: that spell first, whatever the sets.
Type("1459")
local found = Suggested()
check(found[1].text == SaneUI.Core.SpellSearch.TEXT.searchNumber and found[2].entry.id == 1459, "a spell's number: that spell, first")
-- Escape: the box empty, no suggestions.
box._scripts.OnEscapePressed(box)
check(box:GetText() == "" and not finder._shown, "Escape: nothing typed, nothing suggested")
if RETAIL then
    Type("rejuvenation")
    found = Suggested()
    check(found[1].text == SaneUI.Core.SpellSearch.TEXT.searchYours and found[2].entry.id == 774, "without the sets: a spell of your own by its name")
    Type("renew")
    check(Suggested()[1].text == SaneUI.Core.SpellSearch.TEXT.searchNothing, "and no other")
end
-- Closed while a search waits: nothing happens.
box:SetText("re")
box._scripts.OnTextChanged(box, true)
Lists.Hide()
Frames()
check(not finder._shown, "closed: the suggestions gone")

if RETAIL then
    io.write(("Aura lists in Retail: all %d checks passed.\n"):format(passed))
    return
end
check(os.execute(("lua5.1 '%s/dev/tests/auralists.lua' retail"):format(root)) == 0, "in Retail the aura lists run as that game has it")
io.write(("Aura lists: all %d checks passed.\n"):format(passed))
