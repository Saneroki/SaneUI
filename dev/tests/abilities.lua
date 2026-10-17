-- Runs the Abilities module (on Core) against the stand-in client (wowstub.lua) and checks its rules.
-- Usage, from the project folder:  lua5.1 dev/tests/abilities.lua
-- It proves the logic, not the look: how it sits in the real spellbook can only be judged in the game.
-- The class files of the trainer data (Data/Classes) are only checked for their format; a few rows stand in for them.

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

-- A level-10 mage: Fireball rank 1 and 2 learned, the rest still to come.
local FIREBALL1, FIREBALL2, FIREBALL3, FIREBALL4 = 133, 143, 145, 3140
local FROSTNOVA, BLINK, POLYMORPH, COUNTER = 122, 1953, 118, 2139
local MIND, CHANNELING, PYRO, COMBUSTION, LANCE, LATE = 9001, 9002, 11366, 11129, 30455, 777
local EXPLOSION1, EXPLOSION2, SHIELD, BITE = 1449, 8437, 1463, 17253
W.spells = {
    [FIREBALL1] = { name = "Fireball", sub = "Rank 1" }, [FIREBALL2] = { name = "Fireball", sub = "Rank 2" },
    [FIREBALL3] = { name = "Fireball", sub = "Rank 3" }, [FIREBALL4] = { name = "Fireball", sub = "Rank 4" },
    [FROSTNOVA] = { name = "Frost Nova", sub = "Rank 1" }, [BLINK] = { name = "Blink" },
    [POLYMORPH] = { name = "Polymorph", sub = "Rank 1" }, [COUNTER] = { name = "Counterspell" },
    [MIND] = { name = "Arcane Mind", passive = true }, [CHANNELING] = { name = "Frost Channeling", passive = true },
    [PYRO] = { name = "Pyroblast" }, [COMBUSTION] = { name = "Combustion" }, [LANCE] = { name = "Ice Lance" },
    [EXPLOSION1] = { name = "Arcane Explosion", sub = "Rank 1" }, [EXPLOSION2] = { name = "Arcane Explosion", sub = "Rank 2" },
    [BITE] = { name = "Bite", sub = "Rank 1" }, [LATE] = {},
}
W.level = 10
W.lines = { "General", "Arcane", "Fire", "Frost" }
W.skillLines = { [237] = 2, [8] = 3, [6] = 4 }
W.book = { { id = FIREBALL1, line = 3, low = true }, { id = FIREBALL2, line = 3 } }
W.items = { [5512] = { name = "Healthstone", count = 0 } }
W.loaded = { Blizzard_PlayerSpells = true }
-- The game's talent tree: three trees, one per class tab (Arcane, Fire, Frost), each talent a node.
W.traits = { COMBUSTION, PYRO, CHANNELING, LANCE }
local TREE = { [COMBUSTION] = 2, [PYRO] = 2, [CHANNELING] = 3, [LANCE] = 3 }
C_Traits.GetConfigInfo = function() return { treeIDs = { 1, 2, 3 } } end
C_Traits.GetTreeNodes = function(treeID)
    local nodes = {}
    for index, spell in ipairs(W.traits) do
        if TREE[spell] == treeID then nodes[#nodes + 1] = index end
    end
    return nodes
end

-- Settings from an earlier session: a reservation, and one switch flipped.
-- And a few of another shape, as an older version or a hand edit can leave them.
SaneUIDB = { modules = { Spellbook = {
    chars = { ["Player-70-0000ABCD"] = { reserved = { [70] = { kind = "macro", name = "Nope" }, [71] = "junk", [72] = { name = "Kindless" } } } },
    options = { announce = false, compact = false, window = false }, -- the game's own page first; compact and the window further down
    trainer = { MAGE = { spells = { junk = "x", nameless = { sub = 3, level = 5 } } } },
} } }

-------------------------------------------------------------------------------
--  A stand-in for the game's spellbook window
-------------------------------------------------------------------------------
W.templates.PagingControlsHorizontalTemplate = function(widget)
    widget.PageText = W.NewWidget("FontString", nil, widget)
    widget.currentPage, widget.maxPages = 1, 1
    widget.SetOverridePagedContentFrame = function(self, frame) self.override = frame end
    widget.OnMouseWheel = function(self, delta)
        local target = math.max(1, math.min(self.maxPages, self.currentPage + (delta > 0 and -1 or 1)))
        if target ~= self.currentPage then
            self.currentPage = target
            self.override:OnPageChanged()
        end
    end
end
W.templates.UICheckButtonTemplate = function(widget)
    widget.Text = W.NewWidget("FontString", nil, widget)
    widget.SetChecked = function(self, on) self.checked = on and true or false end
    widget.GetChecked = function(self) return self.checked end
end
W.templates.SpellBookHeaderTemplate = function(widget)
    widget.isOurHeader = true
    widget.Text = W.NewWidget("FontString", nil, widget)
    widget.Backplate = W.NewWidget("Texture", nil, widget)
    widget.Border = W.NewWidget("Texture", nil, widget)
end

local book = W.NewWidget("Frame", "SpellBookFrame")
local paged = W.NewWidget("Frame", "PagedSpellsFrame", book)
local view1, view2 = W.NewWidget("Frame", "View1", paged), W.NewWidget("Frame", "View2", paged)
view1:SetHeight(590)
local nativePager = W.NewWidget("Frame", "PagingControls", paged)
nativePager.PageText = W.NewWidget("FontString", nil, nativePager)
nativePager:SetPoint("BOTTOMRIGHT", paged, "BOTTOMRIGHT", -75, 40)
paged.ViewFrames, paged.PagingControls, paged.viewsPerPage = { view1, view2 }, nativePager, 2
paged.frames, paged.viewDataList = {}, { {} }
function paged:GetFrames() return self.frames end
local tabs = {}
for line = 1, 4 do tabs[line] = { skillLineIndex = line, spellBank = 0, tabID = line } end
tabs[5] = { spellBank = 1, tabID = 5 } -- the pet tab
local activeTab, searching = tabs[3], false
book.PagedSpellsFrame, book.categoryMixins = paged, tabs
-- The row of tabs: the game keeps the buttons by their number, and which one is selected.
local tabSystem = W.NewWidget("Frame", "CategoryTabSystem", book)
tabSystem.tabs, tabSystem.selectedTabID = {}, 3
for id = 1, 5 do
    tabSystem.tabs[id] = W.NewWidget("Button", nil, tabSystem)
    tabSystem.tabs[id].Icon = W.NewWidget("Texture")
    tabSystem.tabs[id].Icon:SetTexture("icon of tab " .. id)
end
tabSystem:SetPoint("TOPLEFT", book, "TOPLEFT", 70, -26)
function tabSystem:GetRight() return select(4, self:GetPoint(1)) + 230 end -- five tabs, from the book's left edge
book.SearchBox = W.NewWidget("EditBox", "SearchBox", book) -- anchored at its right, as the game does
function book.SearchBox:GetRight() return 600 end
book.CategoryTabSystem = tabSystem
function book:GetActiveCategoryMixin() return activeTab end
function book:GoToSpell() end -- the game's own: turns to the tab and the (one) page of a spell
function book:IsInSearchResultsMode() return searching end
PlayerSpellsFrame = W.NewWidget("Frame", "PlayerSpellsFrame") -- the window the spellbook and the talents share
PlayerSpellsFrame.SpellBookFrame = book
PlayerSpellsFrame:SetSize(1618, 720)
book:SetSize(1612, 702)

-- The game draws a tab: a heading and one entry per name, laid out its own way,
-- then says so through its event registry.
local function DrawTab(heading, names)
    paged.frames = {}
    paged.dataProvider = {} -- a new list every time, as in the game
    local function entry(isHeader, name)
        local frame = W.NewWidget("Frame", nil, view1)
        local data = { isHeader = isHeader, slotIndex = #paged.frames, spellBank = 0 }
        frame.GetElementData = function() return data end
        if isHeader then
            frame.Text = W.NewWidget("FontString", nil, frame)
            frame.Backplate, frame.Border = W.NewWidget("Texture", nil, frame), W.NewWidget("Texture", nil, frame)
        else
            frame.spellBookItemInfo = { name = name }
            frame.Name = W.NewWidget("FontString", nil, frame)
            frame.Name:SetTextColor(0.2, 0.3, 0.4)
            frame.Backplate = W.NewWidget("Texture", nil, frame)
            frame.Backplate:SetAlpha(0)
            frame.Button = W.NewWidget("Button", nil, frame)
            frame.Button.Border, frame.Button.IconHighlight = W.NewWidget("Texture"), W.NewWidget("Texture")
            frame:SetWidth(216)
        end
        frame:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -70 * #paged.frames)
        paged.frames[#paged.frames + 1] = frame
        return frame
    end
    if heading then entry(true, heading) end
    local made = {}
    for index, name in ipairs(names) do made[index] = entry(false, name) end
    EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
    return made, paged.frames[1]
end

-------------------------------------------------------------------------------
--  Load the addon
-------------------------------------------------------------------------------
-- Three addons, as in the game: Core first, with its saved settings; then the modules.
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local Core, ns = SaneUI.Core, {}
local function load(file) W.Load(root, "SaneUI_Abilities", "Abilities/" .. file, ns) end
load("Abilities")
-- A line typed after "/sane abilities".
local function sane(text) SlashCmdList.SANEUI("abilities " .. text) end

-- The client's one question for "known, or in the spellbook" (Data/Trainer.lua asks it where it is there).
C_SpellBook.IsSpellKnownOrInSpellBook = function(id) return W.IsLearned(id) end
-- The trainer's spells, as a class file in Data/Classes gives them: read at login, for a mage only.
load("Data/Trainer")
local D = ns.Data
local warriorRows = false
D.Class("WARRIOR", function() warriorRows = true end)
D.Class("MAGE", function()
    local f = string.format
    return {
        f("%d:1:10 %d:6:100 %d:12:900 %d:18:1800", FIREBALL1, FIREBALL2, FIREBALL3, FIREBALL4),
        f("%d:1:10", BITE),
        f("%d:8:200", POLYMORPH),
        f("%d:10:400", FROSTNOVA),
        f("%d:12:100", MIND),
        f("%d:14:900 %d:22:3000", EXPLOSION1, EXPLOSION2),
        f("%d:20:2000", BLINK),
        f("%d:24:5000", COUNTER),
    }, {
        [BITE] = { side = "Horde" },
    }
end)

for _, file in ipairs({ "Data/SkillLines", "Sources", "Buttons", "Engine", "Ghosts", "Presets",
                        "Book/Layout", "Book/Item", "Book/Drag", "Book/Book", "Book/Home", "Book/Window", "Book/Menu" }) do
    load(file)
end
W.Fire("ADDON_LOADED", "SaneUI_Abilities")

local S, E, L, B = ns.Sources, ns.Engine, ns.BookLayout, ns.Book
local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function action(slot) return W.actions[slot] end
local function reserved(slot) return ns.char.reserved[slot] end
local function entry(name, sub)
    for _, e in ipairs(S.All()) do
        if e.name == name and (not sub or e.sub == sub) then return e end
    end
end
local function names(list)
    local out = {}
    for index, e in ipairs(list) do out[index] = e.name .. (e.rank and e.rank or "") end
    return table.concat(out, ",")
end
local function printedMatch(pattern)
    for _, line in ipairs(W.printed) do if line:find(pattern) then return true end end
    return false
end
-- Where a frame stands: the frame it hangs on, and x and y from that frame's corner.
local function at(frame)
    local _, relativeTo, _, x, y = frame:GetPoint(1)
    return relativeTo, x, y
end
local function stands(frame, relativeTo, x, y)
    local where, isX, isY = at(frame)
    return frame:GetNumPoints() == 1 and where == relativeTo and math.abs(isX - x) < 0.01 and math.abs(isY - y) < 0.01
end
-- One of the addon's grey entries in the spellbook, by the spell it shows.
local function ghost(name, sub)
    for _, widget in ipairs(W.frames) do
        if widget._parent == SaneUISpellbook and widget:IsShown() and widget.entry
           and widget.entry.name == name and (not sub or widget.entry.sub == sub) then
            return widget
        end
    end
end
local function ghostCount()
    local count = 0
    for _, widget in ipairs(W.frames) do
        if widget._parent == SaneUISpellbook and widget.entry and widget:IsShown() then count = count + 1 end
    end
    return count
end

-- Login -----------------------------------------------------------------------
check(SaneUI.Abilities == ns and ns.addon == "SaneUI_Abilities", "the module is an addon of its own and found under its name")
check(next(D.spells) == nil and D.class == nil, "the trainer data waits for the login: who you are is only certain then")
W.Fire("PLAYER_LOGIN")
check(D.class == "MAGE" and D.raceID == 1 and #D.spells == 11 and not warriorRows, "at login only the spells of your class are read")
W.Fire("NOT_REGISTERED")
W.Fire("PLAYER_ENTERING_WORLD")
check(not ns.ready, "nothing is placed in the first two seconds after login")
W.Wait(3)
check(ns.ready, "ready after login")
check(Core.charKey == "Player-70-0000ABCD" and ns.char.name == "Tester Stub", "a character is kept under its own number, not its first name")
check(ns.DB == SaneUIDB.modules.Abilities and ns.char == ns.DB.chars["Player-70-0000ABCD"] and SaneUIDB.modules.Spellbook == nil,
    "the module's settings are kept by Core, under its name; what was kept under its old name, Spellbook, moved there")
check(reserved(70) and reserved(70).name == "Nope" and ns.char.class == "MAGE", "a reservation of an earlier session is still there")
check(not reserved(71) and not reserved(72) and type(ns.DB.trainer.MAGE.tabs) == "table", "saved data of another shape is dropped or mended at login")
check(ns.DB.options.showHidden and ns.DB.options.book and ns.DB.options.ghosts, "hidden spells are shown unless you switch them off")
check(ns.DB.options.announce == false, "a switch you flipped keeps your choice")
ns.DB.options.announce = true
W.Wait(5)
W.printed = {}

-- What you have, and what is still to come ---------------------------------------
check(S.known.Fireball == FIREBALL2 and S.has.Fireball, "of a spell you have, the highest learned rank is the one to cast")
check(S.knownTab.Fireball == 3, "and its spellbook tab is known")
check(#S.All() == 12, "twelve spells and ranks still to learn (got " .. #S.All() .. ")")
check(S.All()[1].name == "Arcane Explosion" and S.All()[1].rank == 1 and S.All()[12].name == "Pyroblast", "sorted by name, then rank")
check(not entry("Bite"), "a spell for the other faction is not yours")
check(entry("Polymorph").state == "trainable" and entry("Polymorph").cost == 200, "a spell of your level can be trained now, at its price")
check(entry("Fireball", "Rank 3").state == "level" and entry("Fireball", "Rank 4").state == "level", "a spell of a higher level waits for that level")
check(entry("Fireball", "Rank 3").prior == FIREBALL2 and entry("Fireball", "Rank 4").prior == FIREBALL3 and not entry("Polymorph").prior,
    "each rank knows the rank before it, from its place in the family")
check(entry("Pyroblast").state == "talent" and entry("Pyroblast").talent, "talent abilities come from the game's talent tree")
check(entry("Combustion") and entry("Combustion").state == "talent", "every one of them")
check(entry("Arcane Mind").passive and not entry("Frost Channeling"), "a passive spell of the trainer is listed, a passive talent is not")
check(ns.DB.diag.skipped.passive == 1 and ns.DB.diag.offered.traits == 4, "the settings file says what each source offered")

-- The spellbook tab of a spell you do not have yet
check(entry("Fireball", "Rank 3").tab == 3, "a new rank goes where the rank you have is")
check(entry("Polymorph").tab == 2 and entry("Frost Nova").tab == 4 and entry("Combustion").tab == 3, "a new spell is filed by the built-in list of names")
check(entry("Ice Lance").tab == 4, "a talent ability not on that list goes to the tab of its talent tree")
check(entry("Arcane Mind").tab == nil, "and a spell nobody knows the tab of has none")
local stats = S.stats
check(stats.tabKnown == 2 and stats.tabStatic == 8 and stats.tabTalent == 1 and stats.tabNone == 1, "/sane ab debug can say how each tab was found")
check(stats.data == 9 and stats.talent == 3 and stats.known == 1, "and what each list came from")

-- One icon per spell, or one per rank
check(names(S.Unlearned(2, false, false)) == "Arcane Explosion1,Blink,Counterspell,Polymorph1", "one icon per spell: the first rank stands for the spell")
check(names(S.Unlearned(2, true, false)) == "Arcane Explosion1,Arcane Explosion2,Blink,Counterspell,Polymorph1", "with ranks shown: every rank")
check(names(S.Unlearned(3, false, false)) == "Combustion,Pyroblast", "a spell you have a rank of needs no grey icon")
check(names(S.Unlearned(3, true, false)) == "Combustion,Fireball3,Fireball4,Pyroblast", "but its ranks to come show when ranks are shown")
check(#S.Unlearned(nil, true) == 0 and names(S.UnlearnedPassives(true)) == "Arcane Mind", "passive spells are not among a tab's spells: they are listed apart")
W.level = 22
ns.QueueUpdate(true, 0)
W.Wait(1)
check(entry("Arcane Explosion", "Rank 2").state == "spellfirst" and entry("Arcane Explosion", "Rank 2").missing == EXPLOSION1
      and entry("Blink").state == "trainable", "a rank waits for the rank before it")
check(ns.BookItem.Status(entry("Arcane Explosion", "Rank 2")) == "Needs the rank before it", "and says so")
-- A spell that needs a talent, or another spell, before the trainer teaches it.
local blink, counter
for _, spell in ipairs(D.spells) do
    if spell.id == BLINK then blink = spell elseif spell.id == COUNTER then counter = spell end
end
blink.talent, counter.after = COMBUSTION, FROSTNOVA
W.level = 24
ns.QueueUpdate(true, 0)
W.Wait(1)
check(entry("Blink").state == "talentfirst" and ns.BookItem.Status(entry("Blink")) == "Needs a talent first", "a spell that needs a talent first says so")
check(entry("Counterspell").state == "spellfirst" and ns.BookItem.Status(entry("Counterspell")) == "Needs Frost Nova first",
    "one that needs another spell first names that spell")
W.level = 18
ns.QueueUpdate(true, 0)
W.Wait(1)
check(entry("Blink").state == "level" and entry("Counterspell").state == "level", "the level is checked before anything else, as in the game's spellbook")
blink.talent, counter.after = nil, nil
-- A higher rank you have counts every rank before it as learned, whatever the game says of those.
W.book[#W.book + 1] = { id = EXPLOSION2, line = 2 }
ns.QueueUpdate(true, 0)
W.Wait(1)
check(D.Learned(EXPLOSION1) and not entry("Arcane Explosion"), "a lower rank counts as learned once you have a higher one")
table.remove(W.book)
check(not D.Learned(EXPLOSION1) and not D.Learned(EXPLOSION2), "and not without it")
W.level = 10
ns.QueueUpdate(true, 0)
W.Wait(1)

-- The trainer data's format, read by a second reader from a made-up class. A family is a spell's
-- ranks in order; a condition holds from the rank it is written on to the family's last rank.
local own = { Plain = ns.Plain }
W.Load(root, "SaneUI_Abilities", "Abilities/Data/Trainer", own)
local T = own.Data
T.Class("MAGE", function()
    return {
        "501 502:10:100 503:20:200 504:30:300",
        "601:12:50 602:24:500",
        "701:16:70 702:26:700 703:36:800",
        "801:20:10", "802:20:10", "803:20:10 804:40:40",
        "901:30:90 902:40:900 903:50:9000",
    }, {
        [601] = { talent = 650 },
        [701] = { after = 501 },
        [703] = { after = 601 },
        [801] = { side = "Horde" },
        [802] = { side = "Alliance", raceIDs = { 3, 1 } },
        [804] = { raceIDs = { 2, 5 } },
        [902] = { alone = true },
    }
end)
T.Fill()
local read = {}
for _, spell in ipairs(T.spells) do read[spell.id] = spell end
check(not read[501] and read[502].prior == 501 and read[503].prior == 502 and read[504].level == 30 and read[504].cost == 300,
    "a family's ranks each need the one before; a bare spell is a rank the trainer does not sell")
check(read[601].talent == 650 and read[602].talent == 650 and not read[701].talent, "a talent written on a rank holds for the later ranks too")
check(read[701].after == 501 and read[702].after == 501 and read[703].after == 601, "until a later rank sets that condition anew")
check(not read[801] and read[802] and read[803] and not read[804], "only the ranks your faction and race can learn are read")
check(read[901] and not read[902].prior and not read[903].prior, "a rank sold without the one before it needs none")
W.book[#W.book + 1] = { id = 503, line = 2 }
check(T.Learned(501) and T.Learned(502) and T.Learned(503) and not T.Learned(504), "a rank you have makes every rank before it learned, in every class")
W.book[#W.book + 1] = { id = 903, line = 2 }
check(T.Learned(901) and T.Learned(902), "also where each rank is sold alone")
table.remove(W.book)
table.remove(W.book)
check(not T.Learned(502), "and only while you have it")

-- A rank named with a numeral is its family's spell: the numeral must say the same rank.
local FamilyName = D.FamilyName
check(FamilyName("Instant Poison II", "Rank 2") == "Instant Poison" and FamilyName("Wound Poison IV", "Rank 4") == "Wound Poison",
    "a numeral that repeats the rank goes")
check(FamilyName("Instant Poison VI", "Rank 6") == "Instant Poison" and FamilyName("Mind-numbing Poison III", "Rank 3") == "Mind-numbing Poison",
    "also one of more letters")
check(FamilyName("Instant Poison II", "Rank 1") == "Instant Poison II" and FamilyName("Charm XII", "Rank 2") == "Charm XII",
    "a numeral that says another rank stays")
check(FamilyName("Fireball", "Rank 3") == "Fireball" and FamilyName("Blink", nil) == "Blink" and FamilyName("Ward I", nil) == "Ward I",
    "a name without one, or without a rank line, stays")
check(FamilyName("Ward XX", "Rank 20") == "Ward" and FamilyName("I", "Rank 1") == "I" and FamilyName("Shield XXI", "Rank 21") == "Shield XXI",
    "from I to XX, and never the whole name")

-- The list of spells to come is the expensive part: only built when something shows it
book:Hide()
local built = S.stats
W.level = 11
ns.QueueUpdate(true, 0)
W.Wait(1)
check(S.stats == built, "with the spellbook closed nothing builds the list of spells to come")
book:Show()
check(entry("Polymorph") and S.stats ~= built, "it is built when something reads it")
W.level = 10
ns.QueueUpdate(true, 0)
W.Wait(1)

-- A name the game has to fetch first ---------------------------------------------
table.insert(ns.DB.extras.MAGE, LATE)
ns.QueueUpdate(true, 0)
W.Wait(1)
check(not entry("Late Spell"), "a spell without a name yet is not listed")
W.spells[LATE].name = "Late Spell"
W.Fire("SPELL_DATA_LOAD_RESULT", 4242, true)
W.Wait(1)
check(not entry("Late Spell"), "somebody else's load event changes nothing")
W.Fire("SPELL_DATA_LOAD_RESULT", LATE, true)
W.Wait(1)
check(entry("Late Spell") and entry("Late Spell").extra and entry("Late Spell").state == "other", "it is listed when its name arrives")
S.RemoveExtra(entry("Late Spell"))
W.Wait(1)
check(not entry("Late Spell"), "and can be taken off the list again")

-- The class trainer ----------------------------------------------------------------
W.trainerFilter.unavailable = false                     -- the player hides what he cannot learn yet
W.trainer = {
    { kind = "available", name = "Frost Nova", icon = 301, level = 10, sub = "Rank 1", category = "Frost", id = FROSTNOVA, cost = 400 },
    { kind = "unavailable", name = "Arcane Mind", icon = 304, level = 12, category = "Arcane", id = MIND, cost = 100 },
    { kind = "unavailable", name = "Mana Shield", icon = 305, level = 20, sub = "Rank 1", category = "Arcane", cost = 2000 }, -- no spell ID to be had
    { kind = "unavailable", name = "Shadow Ward", icon = 306, level = 32, category = "Shadow", cost = 9000 }, -- a tab this mage does not have yet
    { kind = "used", name = "Fireball", icon = 307, level = 1, category = "Fire", id = FIREBALL1 },
}
W.Fire("TRAINER_SHOW")
check(W.trainerFilter.unavailable == true, "the hidden rows are switched on to be read")
W.Wait(1)
check(W.trainerFilter.unavailable == false, "and the filter is put back")
local taught = ns.DB.trainer.MAGE
check(taught.tabs["Arcane Mind"] == "Arcane" and taught.tabs["Frost Nova"] == "Frost", "the trainer's list says the tab of each spell")
check(taught.tabs.Fireball == nil, "rows the trainer's filter hides are not there to read")
check(taught.tabs["Shadow Ward"] == "Shadow" and entry("Shadow Ward") and entry("Shadow Ward").tab == nil,
    "a spell of a tab you do not have yet is kept, without a tab for now")
check(taught.spells["Mana Shield#Rank 1"] and taught.spells["Mana Shield#Rank 1"].cost == 2000, "a row without a spell ID is kept by name and rank")
check(printedMatch("read your class trainer's list"), "one chat line says the list was read")
check(entry("Arcane Mind").tab == 2 and S.stats.tabTrainer >= 2, "the tab from the trainer is used")
check(entry("Mana Shield") and entry("Mana Shield").source == "trainer" and entry("Mana Shield").tab == 2 and entry("Mana Shield").state == "level",
    "a spell only the trainer's window knows joins the list")
check(#S.All() == 14, "and a spell both lists have is there once")
W.lines[5], W.skillLines[78] = "Shadow", 5
ns.QueueUpdate(true, 0)
W.Wait(1)
check(entry("Shadow Ward").tab == 5, "it finds its tab when the tab appears")
W.lines[5], W.skillLines[78] = nil, nil
ns.DB.trainer.MAGE.tabs["Shadow Ward"], ns.DB.trainer.MAGE.spells["Shadow Ward#"] = nil, nil
ns.QueueUpdate(true, 0)
W.Wait(1)
W.printed = {}
W.Fire("TRAINER_UPDATE")
W.Wait(1)
check(#W.printed == 0, "reading the same list again says nothing")
W.Fire("TRAINER_CLOSED")
W.tradeskill = true
W.trainer = { { kind = "available", name = "Tailoring", icon = 1, level = 5, category = "Arcane" } }
W.Fire("TRAINER_SHOW")
W.Wait(1)
check(not taught.tabs.Tailoring, "a profession trainer is ignored")
W.tradeskill = false
W.trainer = { { kind = "available", name = "Two-Handed Swords", icon = 2, level = 1, category = "Weapon Skills", cost = 1000 } }
W.Fire("TRAINER_SHOW")
check(W.trainerFilter.unavailable == false, "another trainer's filter is not touched")
W.Wait(1)
check(not taught.tabs["Two-Handed Swords"], "and a weapon master is ignored: none of his rows is under one of your tabs")
W.trainer = nil

-- Page layout: the game's own rule, column by column ---------------------------------
local function group(count, header)
    local items = {}
    for index = 1, count do items[index] = { n = index } end
    return { header = header and { title = true } or nil, items = items }
end
local pages = L.Paginate({ group(10, true) }, 200)
check(#pages == 1 and #pages[1] == 11 and pages[1][1].header and pages[1][1].y == 0, "a heading, then its spells")
check(pages[1][2].x == 0 and pages[1][2].y == 61 and pages[1][5].y == 271, "ten spells need four rows: the first column takes four")
check(pages[1][6].x == 215 and pages[1][6].y == 61 and pages[1][10].x == 430 and pages[1][11].y == 131, "the second four, the third the last two")
pages = L.Paginate({ group(30, true) }, 200)
check(#pages == 2 and #pages[1] == 22 and #pages[2] == 9, "under a heading a page holds seven rows; the rest goes on")
check(pages[2][1].y == 0 and pages[2][4].x == 215 and pages[2][9].y == 140, "and is spread over as few rows as it needs")
pages = L.Paginate({ group(24, false) }, 200)
check(#pages == 1 and pages[1][24].y == 490, "without a heading a page holds eight rows")
pages = L.Paginate({ group(3, true), group(3, true) }, 200)
check(#pages == 1 and pages[1][5].header and pages[1][5].y == 161 and pages[1][6].y == 222, "a second group follows after a gap")
pages = L.Paginate({ group(18, true), group(3, true) }, 200)
check(#pages == 2 and pages[2][1].header and pages[2][1].y == 0, "a heading is never left alone at the foot of a page")
check(#L.Paginate({}, 200) == 1, "an empty tab is one empty page")

-- Mixing the spells you have with the ones to come
local function natives(...)
    local list = {}
    for index, name in ipairs({ ... }) do list[index] = { name = name, native = true } end
    return list
end
local function order(list)
    local out = {}
    for index, item in ipairs(list) do out[index] = (item.native and "" or "+") .. item.name .. (item.rank or "") end
    return table.concat(out, " ")
end
local function to(name, rank, level, state)
    return { name = name, rank = rank, entry = { name = name, rank = rank, level = level, state = state } }
end
local mixed = L.Order(natives("Scorch", "Blink", "Fireball", "Fireball"), {
    to("Pyroblast", nil, 20, "level"), to("Fireball", 4, 18, "level"), to("Zap", nil, 4, "trainable"),
    to("Fireball", 3, 12, "level"), to("Arcane Missiles", 1, 8, "trainable") })
check(order(mixed) == "Scorch Blink Fireball Fireball +Zap +Arcane Missiles1 +Fireball3 +Fireball4 +Pyroblast",
    "the spells you have first, in the game's order; then what you can learn now; then the rest by level (" .. order(mixed) .. ")")
check(order(L.Order({}, { to("B", nil, 2, "level"), to("A", nil, 9, "level") })) == "+B +A", "a tab with nothing learned is simply the list of what is to come, by level")

-- The spellbook ----------------------------------------------------------------------
check(view1:GetHeight() > 10000, "the game's first column is made tall, so the game draws a whole tab at once")
check(at(nativePager) == UIParent and SaneUISpellbookPager, "the game's page buttons step aside for the addon's")

local made, heading = DrawTab("Fire", { "Fireball" })
check(stands(heading, view1, 0, 0) and stands(made[1], view1, 0, -61), "the game's own entries are put where they belong, first")
check(ghost("Combustion") and stands(ghost("Combustion"), view1, 231, -61) and stands(ghost("Pyroblast"), view1, 462, -61),
    "with the spells to come in grey after them")
check(ghostCount() == 2, "one grey icon per spell")
local pyro = ghost("Pyroblast")
check(pyro.Name:GetText() == "Pyroblast" and pyro.RequiredLevel:GetText() == "Talent", "a grey entry says what it is waiting for")
check(pyro.Name._color[1] == 0.2 and pyro.Backplate:GetAlpha() == 0, "and takes the look of the game's entries, skin and all")

-- The "+" on a spell whose ranks are folded into it, and the heading of its unfolded ranks.
local function fold(name, heading)
    for _, widget in ipairs(W.frames) do
        if widget._parent == SaneUISpellbook and widget.spell == name and widget:IsShown()
           and (heading and rawget(widget, "Minus") ~= nil or not heading and rawget(widget, "more") ~= nil) then
            return widget
        end
    end
end
W.cvars.ShowAllSpellRanks = "1"
made = DrawTab("Fire", { "Fireball", "Fireball" })
check(ghostCount() == 2 and at(made[1]) == UIParent and stands(made[2], view1, 0, -61),
    "with ranks shown, the ranks of a spell are folded into the highest one you have")
local plus = fold("Fireball")
check(plus and plus.more == 3 and stands(plus, view1, 216 - 18, -63) and not fold("Pyroblast"), "it carries a + that says how many more there are; a spell of one rank has none")
plus:GetScript("OnClick")(plus)
check(fold("Fireball", true) and stands(fold("Fireball", true), view1, 0, -141) and not fold("Fireball"), "a click on it unfolds the ranks into a section of their own, under the tab's spells")
check(ghostCount() == 4 and stands(made[1], view1, 0, -173) and stands(made[2], view1, 0, -243), "the ranks you have first")
check(stands(ghost("Fireball", "Rank 3"), view1, 231, -173) and stands(ghost("Fireball", "Rank 4"), view1, 231, -243), "the ranks to come right after them")
check(ghost("Fireball", "Rank 3").SubName:GetText() == "Rank 3" and ghost("Fireball", "Rank 3").RequiredLevel:GetText() == "Available at level 12", "each with its rank and level")
made = DrawTab("Fire", { "Fireball", "Fireball" })
check(fold("Fireball", true) and ghostCount() == 4, "they stay unfolded when the game draws the tab again")
fold("Fireball", true):GetScript("OnClick")(fold("Fireball", true))
check(not fold("Fireball", true) and fold("Fireball") and ghostCount() == 2 and at(made[1]) == UIParent, "a click on the heading folds them away again")
W.cvars.ShowAllSpellRanks = nil

made = DrawTab("Fire", { "Fireball" })
ns.DB.options.showHidden = false
ns.Fire("REFRESH")
check(ghostCount() == 0 and stands(made[1], view1, 0, -61), "'Show hidden spells' off: the spellbook as the game draws it")
ns.DB.options.showHidden = true
ns.Fire("REFRESH")
check(ghostCount() == 2, "and on again")

-- A displaced entry is put back (the game lays its column out again now and then)
made[1]:ClearAllPoints()
made[1]:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -999)
SaneUISpellbook:GetScript("OnUpdate")(SaneUISpellbook)
check(stands(made[1], view1, 0, -61), "an entry the game moved is put back at once")
local silent = W.NewWidget("Frame", nil, view1)
silent.spellBookItemInfo = { name = "Scorch" }
silent.GetElementData = function() return { isHeader = false } end
silent:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -140)
paged.frames[#paged.frames + 1] = silent
SaneUISpellbook:GetScript("OnUpdate")(SaneUISpellbook)
check(stands(silent, view1, 0, -131) and stands(ghost("Pyroblast"), view1, 231, -131), "and so is an entry the game added without saying so")
local watch = SaneUISpellbook:GetScript("OnUpdate")
for _ = 1, 10 do watch(SaneUISpellbook, 0.01) end -- the frames right after a layout are over
local _, _, _, homeX, homeY = made[1]:GetPoint(1)
made[1]:ClearAllPoints()
made[1]:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -999)
watch(SaneUISpellbook, 0.05)
check(stands(made[1], view1, 0, -999), "after them the entries are looked at five times a second, not in every frame")
watch(SaneUISpellbook, 0.2)
check(stands(made[1], view1, homeX, homeY), "and one out of place is put back at the next look")

-- Spells without a tab: at the end of the first class tab
S.AddExtra(LATE)
W.Wait(1)
activeTab = tabs[2]
made = DrawTab("Arcane", { "Arcane Intellect" })
check(stands(made[1], view1, 0, -61) and stands(ghost("Polymorph"), view1, 0, -131) and stands(ghost("Arcane Explosion"), view1, 231, -61)
    and stands(ghost("Blink"), view1, 231, -131) and stands(ghost("Counterspell"), view1, 462, -131),
    "the Arcane tab: the spell you have, then what you can learn now, then the rest by level")
check(ghost("Mana Shield") and not ghost("Arcane Mind"), "the trainer-only spell among them, the passive one not")
local ourHeader
for _, widget in ipairs(W.frames) do
    if widget.isOurHeader and widget._parent == SaneUISpellbook and widget:IsShown() then ourHeader = widget end
end
check(ourHeader:IsShown() and ourHeader.Text:GetText() == "Other spells to learn" and stands(ourHeader, view1, 0, -231) and stands(ghost("Late Spell"), view1, 0, -292),
    "spells without a known tab get a group of their own at the end of the first class tab")
activeTab = tabs[4]
DrawTab("Frost", {})
check(not ourHeader:IsShown() and ghost("Frost Nova") and ghost("Ice Lance") and ghostCount() == 2, "and not on the other tabs")
DrawTab(nil, {})
local tabHeader
for _, widget in ipairs(W.frames) do
    if widget.isOurHeader and widget._parent == SaneUISpellbook and widget:IsShown() then tabHeader = widget end
end
check(tabHeader and tabHeader.Text:GetText() == "Frost" and stands(tabHeader, view1, 0, 0) and stands(ghost("Frost Nova"), view1, 0, -61),
    "a tab the game drew nothing for (all its spells hidden) still gets its heading")
S.RemoveExtra(entry("Late Spell"))
W.Wait(1)

-- More than one page. (Arcane Mind counts as an active spell for this part, to fill the Arcane tab:
-- a passive one would be listed in General.)
W.spells[MIND].passive = nil
ns.QueueUpdate(true, 0)
W.Wait(1)
activeTab = tabs[2]
local many = {}
for index = 1, 40 do many[index] = ("Zz%02d"):format(index) end
made = DrawTab("Arcane", many)
check(SaneUISpellbookPager.maxPages == 2 and SaneUISpellbookPager.currentPage == 1, "46 entries are two pages of two columns")
check(stands(made[1], view1, 0, -61) and stands(made[22], view2, 0, 0), "the second column of the book is the game's second view")
check(not ghost("Counterspell"), "a grey entry of the next page is not on this one")
paged:GetScript("OnMouseWheel")(paged, -1)
check(SaneUISpellbookPager.currentPage == 2 and stands(ghost("Counterspell"), view1, 0, 0), "the mouse wheel turns the page")
check(at(made[1]) == UIParent and select(2, at(made[1])) < -5000, "entries of another page wait far off the screen")
check(ghostCount() == 1, "and the grey entries of the first page are gone from the second")
paged:GetScript("OnMouseWheel")(paged, 1)
check(stands(made[1], view1, 0, -61) and not ghost("Counterspell"), "and back")
paged.viewsPerPage = 1
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
check(SaneUISpellbookPager.maxPages == 3 and at(made[22]) == UIParent, "the small spellbook shows one column per page")
paged.viewsPerPage = 2
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
paged:GetScript("OnMouseWheel")(paged, -1)
W.slotOfSpell[4001] = 1              -- the game's slot of the first entry
book:GoToSpell(4001, true)
check(SaneUISpellbookPager.currentPage == 1 and stands(made[1], view1, 0, -61), "when the game jumps to a spell, our page follows")
paged:GetScript("OnMouseWheel")(paged, -1)
paged.viewsPerPage = 1
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
check(SaneUISpellbookPager.currentPage == 3 and stands(ghost("Counterspell"), view1, 0, 0), "making the spellbook small keeps the column you were reading")
paged.viewsPerPage = 2
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
check(SaneUISpellbookPager.currentPage == 2, "and large again")
activeTab = tabs[3]
made = DrawTab("Fire", { "Fireball" })
check(SaneUISpellbookPager.currentPage == 1 and stands(made[1], view1, 0, -61), "another tab starts on its first page")

-- In a fight the game forbids moving an entry that holds one of its protected frames
-- (an entry whose spell flyout you opened). It waits for the fight's end.
W.combat = true
made[1].IsProtected = function() return true end
made[1]:ClearAllPoints()
made[1]:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -999)
W.printed = {}
for _ = 1, 60 do SaneUISpellbook:GetScript("OnUpdate")(SaneUISpellbook) end
check(stands(made[1], view1, 0, -999) and #W.printed == 0 and SaneUISpellbook:IsShown(), "such an entry is left alone in a fight, without a fuss")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(stands(made[1], view1, 0, -61), "and put right when the fight is over")
made[1].IsProtected = nil

-- Search results and the pet tab get no grey entries
searching = true
local results = {}
for index = 1, 50 do results[index] = ("Result%02d"):format(index) end
DrawTab("Results", results)
paged:GetScript("OnMouseWheel")(paged, -1)
check(SaneUISpellbookPager.currentPage == 2, "search results have pages too")
made = DrawTab("Results", { "Fireball", "Blink" })
check(SaneUISpellbookPager.currentPage == 1, "a new search starts on its first page")
check(ghostCount() == 0 and stands(made[2], view1, 231, -61), "search results are laid out as the game would")
searching, activeTab = false, tabs[5]
DrawTab("Pet", { "Growl" })
check(ghostCount() == 0, "the pet's tab is the pet's")
activeTab = tabs[3]
made = DrawTab("Fire", { "Fireball" })

-- A grey entry: tooltip, link, drag, menu --------------------------------------------------
pyro = ghost("Pyroblast")
GameTooltip._lines = {}
pyro.Button:GetScript("OnEnter")(pyro.Button)
check(table.concat(GameTooltip._lines, "|"):find("Talent%.") and table.concat(GameTooltip._lines, "|"):find("Drag onto an action bar button"), "its tooltip says what it waits for and what to do")
W.modifier = "CHATLINK"
pyro.Button:GetScript("OnClick")(pyro.Button, "LeftButton")
W.modifier = nil
check(W.links[#W.links]:find("spell:" .. PYRO), "Shift-click links the spell in chat")
pyro.Button:GetScript("OnClick")(pyro.Button, "LeftButton")
check(#W.links == 1, "a plain click does nothing")

for index = 1, 12 do
    local button = W.NewWidget("CheckButton", "MultiBarBottomLeftButton" .. index)
    _G["MultiBarBottomLeftButton" .. index] = button
    button.action = 60 + index
end
pyro.Button:GetScript("OnDragStart")(pyro.Button)
check(ns.Drag.Held() == pyro.entry, "dragging a grey entry picks the spell up")
MultiBarBottomLeftButton5._mouseOver = true
pyro.Button:GetScript("OnDragStop")(pyro.Button)
check(reserved(65) and reserved(65).name == "Pyroblast" and not action(65) and not ns.Drag.Held(), "dropping it on a real action bar button reserves that button")
check(W.errors[#W.errors] == "Pyroblast reserved on Bar 2, button 5.", "and says so on screen")
W.Wait(1)
-- A bar that hides its empty buttons ("always show buttons" off): the button is not there for the
-- mouse while our cursor, not the game's, carries the spell. Its place on the screen still counts.
MultiBarBottomLeftButton5._mouseOver = false
local hiddenBar = W.NewWidget("Frame", "HiddenBar6")
local hidden = W.NewWidget("CheckButton", "HiddenBarButton150", hiddenBar)
hidden.GetAttribute = function(_, key) return key == "action" and 150 or nil end
hidden.GetRect = function() return 100, 100, 40, 40 end
hidden.GetEffectiveScale = function() return 1 end
hidden:Hide()
HiddenBarButton150 = hidden
local cursorAt = GetCursorPosition
GetCursorPosition = function() return 120, 130 end
ns.Drag.Start(entry("Combustion"))
ns.Drag.Stop()
check(reserved(150) and reserved(150).name == "Combustion", "a hidden empty button of a bar you can see takes the spell all the same")
GetCursorPosition = function() return 300, 300 end
ns.Drag.Start(entry("Blink"))
ns.Drag.Stop()
check(reserved(150).name == "Combustion", "but only where it is")
GetCursorPosition = cursorAt
W.Wait(1)
local hiddenGhost
for _, widget in ipairs(W.frames) do
    if widget._parent == hiddenBar and widget.fallback == 150 then hiddenGhost = widget end
end
check(hiddenGhost and hiddenGhost:IsShown() and hiddenGhost.entry.name == "Combustion", "and shows the reservation: the grey icon hangs on the bar, not on the hidden button")
-- A hidden button the game gives no place any more, of a bar addon with names of its own: its place is
-- worked out from its anchor on the bar, and it is found by the slot it carries.
local otherBar = W.NewWidget("Frame", "OtherBar")
otherBar.GetRect = function() return 500, 200, 400, 40 end
local lost = W.NewWidget("CheckButton", "OtherBarButton3", otherBar)
lost.GetAttribute = function(_, key) return key == "action" and 151 or nil end
lost:SetSize(36, 36)
lost:SetPoint("TOPLEFT", otherBar, "TOPLEFT", 80, -2)
lost:Hide()
check(select(1, ns.Buttons.Rect(lost)) == 580 and select(2, ns.Buttons.Rect(lost)) == 202, "a hidden button's place is worked out from its anchor")
GetCursorPosition = function() return 600, 220 end
ns.Drag.Start(entry("Blink"))
ns.Drag.Stop()
GetCursorPosition = cursorAt
check(reserved(151) and reserved(151).name == "Blink", "and it takes a drop like any other button, whatever the bar addon calls it")
E.Clear(151)
hiddenGhost:GetScript("OnDragStart")(hiddenGhost)
check(ns.Drag.Held() and ns.Drag.Held().name == "Combustion", "the grey icon of a hidden button can be picked up itself")
hiddenGhost:GetScript("OnDragStop")(hiddenGhost)
check(not reserved(150) and not ns.Drag.Held(), "and let go on no button, it is taken off")
E.Clear(150)
W.Wait(1)
check(ghost("Pyroblast").Button.Reserved:IsShown() and not ghost("Combustion").Button.Reserved:IsShown(), "a reserved spell gets a tick in the spellbook")
pyro = ghost("Pyroblast")
GameTooltip._lines = {}
pyro.Button:GetScript("OnEnter")(pyro.Button)
check(table.concat(GameTooltip._lines, "|"):find("Reserved on Bar 2, button 5"), "and its tooltip names the button")
pyro.Button:GetScript("OnClick")(pyro.Button, "RightButton")
local menu = W.menus[#W.menus]
check(menu[2] and menu[2].text == "Remove from Bar 2, button 5", "right-click offers to remove the reservation")
menu[2].fn()
W.Wait(1)
check(not reserved(65), "and removes it")

-- a real action on the button goes onto the cursor, as when two real buttons swap
MultiBarBottomLeftButton5._mouseOver = false
MultiBarBottomLeftButton6._mouseOver = true
W.actions[66] = { kind = "spell", id = FIREBALL2 }
ns.Drag.Start(entry("Combustion"))
ns.Drag.Stop()
check(reserved(66) and reserved(66).name == "Combustion" and not action(66) and W.cursor and W.cursor.id == FIREBALL2, "what was on the button is on your cursor now")
W.cursor = nil
W.Fire("CURSOR_CHANGED")
W.Wait(1)
W.combat = true
MultiBarBottomLeftButton6._mouseOver = false
MultiBarBottomLeftButton7._mouseOver = true
W.actions[67] = { kind = "spell", id = FIREBALL2 }
W.printed = {}
ns.Drag.Start(entry("Combustion"))
ns.Drag.Stop()
check(not reserved(67) and action(67) and printedMatch("in combat"), "in combat a real button is left alone")
W.actions[67] = nil
ns.Drag.Start(entry("Combustion"))
ns.Drag.Stop()
check(reserved(67) and reserved(67).name == "Combustion", "but an empty button can be reserved in combat")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
MultiBarBottomLeftButton7._mouseOver = false
ns.Drag.Start(entry("Combustion"))
ns.Drag.Stop()
check(not ns.Drag.Held() and not reserved(68), "dropped anywhere else, nothing happens")
local other = W.NewWidget("Button")
other.action = 13
W.foci = { W.NewWidget("Frame", nil, other) }
ns.Drag.Start(entry("Combustion"))
ns.Drag.Stop()
check(reserved(13) and reserved(13).name == "Combustion", "a bar addon's own button is found by the slot it carries")
W.foci = {}
-- A bar addon's own buttons may keep their slot only in the secure attribute "action".
local own = W.NewWidget("CheckButton", "OtherBarButton160")
own.GetAttribute = function(_, key) return key == "action" and 160 or nil end
W.foci = { W.NewWidget("Texture", nil, own) }
ns.Drag.Start(entry("Combustion"))
ns.Drag.Stop()
check(reserved(160) and reserved(160).name == "Combustion", "a button that keeps its slot only as an attribute is found too")
W.foci = {}
E.Clear(160)
W.spells[MIND].passive = true
ns.QueueUpdate(true, 0)
W.Wait(1)
local mind = entry("Arcane Mind")
activeTab = tabs[1]
DrawTab("General", { "Attack" })
ghost("Arcane Mind").Button:GetScript("OnDragStart")(ghost("Arcane Mind").Button)
check(mind.passive and not ns.Drag.Held(), "a passive spell cannot be dragged")
for _, slot in ipairs({ 13, 66, 67 }) do E.Clear(slot) end
W.Wait(2)
W.errors, W.printed = {}, {}

-- A reservation waits, then becomes real ---------------------------------------
check(E.Reserve(71, entry("Mana Shield")), "reserve a spell known only by its name")
W.Wait(2)
check(reserved(71) and reserved(71).icon == 305 and not action(71), "it waits with the trainer's icon")
W.spells[SHIELD] = { name = "Mana Shield", sub = "Rank 1" }
W.Learn(SHIELD, 2)
W.Wait(2)
check(action(71) and action(71).id == SHIELD and not reserved(71), "and is placed by its name once learned")
check(not entry("Mana Shield"), "a learned spell leaves the list of spells to come")
W.printed = {}

check(E.Reserve(61, entry("Frost Nova")), "reserve an unknown spell")
W.Wait(1)
check(reserved(61) and not action(61), "the reservation waits on an empty button")
W.Learn(FROSTNOVA, 4)
W.Wait(2)
check(action(61) and action(61).id == FROSTNOVA and not reserved(61), "learning the spell puts it on its button")
check(printedMatch("Frost Nova is now on Bar 2, button 1"), "and says so in chat")

-- A spell you already have is placed at once, by any rank ------------------------
W.printed = {}
check(E.Reserve(62, { kind = "spell", id = FIREBALL1, name = "Fireball" }), "reserve a known spell")
W.Wait(0.1)
check(action(62) and action(62).id == FIREBALL2 and not reserved(62), "placed at once, as the highest rank")
check(#W.printed == 0, "no chat line for your own drop")
check(E.Reserve(72, entry("Fireball", "Rank 4")), "reserve a rank to come of a spell you have")
W.Wait(0.1)
check(action(72) and action(72).id == FIREBALL2 and not reserved(72), "the spell goes on the button with the rank you have")
E.Clear(72)

-- What you put on a button last wins ---------------------------------------------
E.Reserve(63, entry("Blink"))
W.Wait(2)
W.PlayerPlaces(63, "spell", FIREBALL2)
W.Wait(2)
check(not reserved(63) and action(63).id == FIREBALL2, "a real action on a reserved button ends the reservation")

E.Reserve(63, entry("Blink"))
W.Wait(2)
check(reserved(63) and not action(63) and W.cursor == nil, "a reservation set by a command takes the action off the bar")

-- Combat -------------------------------------------------------------------------
W.combat = true
check(E.Reserve(64, { kind = "spell", name = "Fireball" }), "reserving an empty button works in combat")
W.Wait(2)
check(reserved(64) and not action(64) and E.pending, "but nothing real is placed in combat")
W.spells[5152] = { name = "Dampen Magic" }
W.Learn(5152)
W.Wait(1)
check(not S.known["Dampen Magic"], "and what you have is not read again in a fight: nothing real could be placed anyway")
local ok, why = E.Reserve(61, entry("Blink"))
check(not ok and why == "combat" and action(61) and not reserved(61), "a real button cannot be reserved in combat")
ok, why = E.Clear(61)
check(not ok and why == "combat" and E.Reason(why):find("combat"), "or removed")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(2)
check(action(64) and action(64).id == FIREBALL2 and not reserved(64), "it is placed when the fight ends")
check(S.known["Dampen Magic"], "and what you have is read then")

-- A busy cursor ------------------------------------------------------------------
W.cursor = { kind = "item", id = 6948 }
ok, why = E.Clear(62)
check(not ok and why == "cursor" and action(62) and W.cursor.id == 6948, "nothing real moves while the cursor holds something")
W.cursor = nil

-- Removing -----------------------------------------------------------------------
E.Reserve(66, entry("Polymorph"))
check(E.Clear(66) and not reserved(66), "a reservation can be removed")
check(E.Clear(62) and not action(62), "and a real action taken off the bar")
W.Wait(2)

-- The game's own "new spell on the first free button" ------------------------------
E.Reserve(49, entry("Blink"))
E.Reserve(50, entry("Polymorph"))
W.Wait(2)
W.book[#W.book + 1] = { id = POLYMORPH, line = 2 }
W.actions[49] = { kind = "spell", id = POLYMORPH }       -- the game drops it on Blink's button
W.Fire("SPELL_PUSHED_TO_ACTIONBAR", POLYMORPH, 49, 1)
W.Fire("ACTIONBAR_SLOT_CHANGED", 49)
W.Fire("SPELLS_CHANGED")
W.Wait(3)
check(not action(49) and reserved(49) and reserved(49).name == "Blink", "Blink keeps its reserved button")
check(action(50) and action(50).id == POLYMORPH and not reserved(50), "the new spell goes to its own reserved button")

W.book[#W.book + 1] = { id = COUNTER, line = 2 }
W.actions[49] = { kind = "spell", id = COUNTER }          -- a spell with no reservation, again on Blink's button
W.Fire("SPELL_PUSHED_TO_ACTIONBAR", COUNTER, 49, 1)
W.Fire("ACTIONBAR_SLOT_CHANGED", 49)
W.Fire("SPELLS_CHANGED")
W.Wait(3)
check(not action(49) and reserved(49), "an unplanned new spell is moved off a reserved button")
check(action(1) and action(1).id == COUNTER, "to the first free, unreserved button")
local hiddenBar = W.NewWidget("Frame", "MainBar")
hiddenBar:Hide()
for index = 2, 4 do _G["ActionButton" .. index] = W.NewWidget("CheckButton", "ActionButton" .. index, hiddenBar) end
W.actions[1] = nil
W.spells[4242] = { name = "Surprise" }
W.book[#W.book + 1] = { id = 4242, line = 2 }
W.actions[49] = { kind = "spell", id = 4242 }
W.Fire("SPELL_PUSHED_TO_ACTIONBAR", 4242, 49, 1)
W.Fire("SPELLS_CHANGED")
W.Wait(3)
check(action(1) and action(1).id == 4242, "the first free button means one on a bar you can see")
for index = 2, 4 do _G["ActionButton" .. index] = nil end
W.spells[5150] = { name = "Slow Fall" }
E.Reserve(52, { kind = "spell", id = 5150, name = "Slow Fall" })
W.Wait(2)
W.book[#W.book + 1] = { id = 5150, line = 2 }
W.actions[54] = { kind = "spell", id = 5150 }             -- a copy of yours
W.actions[53] = { kind = "spell", id = 5150 }             -- where the game put it
W.Fire("SPELL_PUSHED_TO_ACTIONBAR", 5150, 53, 1)
W.Fire("SPELLS_CHANGED")
W.Wait(3)
check(action(52) and action(52).id == 5150 and not action(53) and action(54), "only the button the game chose is undone: a copy of yours stays")
for _, slot in ipairs({ 52, 54 }) do E.Clear(slot) end
-- A rank named with a numeral (the rogue's poisons) is the trainer's spell of the plain name.
W.spells[8691] = { name = "Instant Poison II", sub = "Rank 2" }
E.Reserve(55, { kind = "spell", id = 8691, name = "Instant Poison" })
W.Wait(2)
W.book[#W.book + 1] = { id = 8691, line = 2 }
W.actions[56] = { kind = "spell", id = 8691 }
W.Fire("SPELL_PUSHED_TO_ACTIONBAR", 8691, 56, 1)
W.Fire("SPELLS_CHANGED")
W.Wait(3)
check(S.has["Instant Poison"] and S.known["Instant Poison"] == 8691 and S.has["Instant Poison II"],
    "a rank named with a numeral is known by the trainer's name of it too")
check(action(55) and action(55).id == 8691 and not action(56), "and goes to the button reserved for it by that name")
E.Clear(55)
W.Wait(1)

-- A slot the game hides from addons (a secret value) is no answer: nothing is ended or filled on it
E.Reserve(66, entry("Blink"))
W.Wait(2)
W.actions[66] = { kind = "spell", id = FIREBALL2 }
issecretvalue = function() return true end
ns.QueueUpdate(false, 0)
W.Wait(1)
check(reserved(66) and ns.HasAction(66) == "unknown", "a hidden slot keeps its reservation")
issecretvalue = nil
ns.QueueUpdate(false, 0)
W.Wait(1)
check(not reserved(66) and action(66), "and is judged once the game shows it again")
W.actions[66] = nil

-- Items ----------------------------------------------------------------------------
W.printed = {}
sane("item |cff1eff00|Hitem:5512::::|h[Healthstone]|h|r 4 1")
W.Wait(2)
check(reserved(25) and reserved(25).kind == "item" and not action(25) and printedMatch("item reserved on Bar 4, button 1"), "/sane ab item reserves a button for an item you do not have")
W.items[5512].count = 1
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(2)
check(action(25) and action(25).kind == "item" and action(25).id == 5512 and not reserved(25), "and it is placed when it is in your bags")
sane("item 5512 9 1")
check(printedMatch("/sane ab item <item ID or link>"), "a bar that does not exist gets the usage line")

-- Links and IDs -----------------------------------------------------------------------
check(select(2, S.Parse("|cff1eff00|Hitem:5512::::|h[Healthstone]|h|r")) == 5512, "item link")
check(S.Parse("|Hspell:2139:0|h[Counterspell]|h") == "spell", "spell link")
check(S.Parse("item 6948") == "item" and S.Parse("118") == "spell" and S.Parse("118", true) == "item", "typed IDs")
check(S.Parse("hello") == nil, "nonsense is refused")
ok = S.AddExtra(MIND)
check(not ok, "a passive spell cannot be added")
ok = S.AddExtra(424242)
check(not ok, "an unknown ID is refused")
W.printed = {}
sane("add " .. COMBUSTION)
check(printedMatch("Combustion is already in the spellbook's list") and #ns.DB.extras.MAGE == 0, "a spell that is already listed is not added twice")

-- Saved layouts ------------------------------------------------------------------------
W.macros["Sheep"] = 3
W.PlayerPlaces(26, "macro", 3, "Sheep")
W.PlayerPlaces(27, "companion", 77)
W.Wait(2)
sane("save   Raid ")
check(ns.DB.presets.MAGE.Raid and ns.Presets.List()[1] == "Raid" and printedMatch('Layout "Raid" saved'), "save a layout, name trimmed")
local saved = ns.DB.presets.MAGE.Raid.slots
check(saved[49].name == "Blink" and saved[50].name == "Polymorph" and saved[26].kind == "macro" and saved[26].name == "Sheep", "real and reserved buttons are both in it")

-- wreck the layout, then load
for _, slot in ipairs({ 50, 25, 26, 63, 64, 65, 1 }) do W.actions[slot] = nil end
ns.char.reserved[49] = nil
W.PlayerPlaces(50, "spell", COUNTER)
W.PlayerPlaces(27, "companion", 78)
W.Wait(2)
W.printed = {}
ok = ns.Presets.Load("Raid")
check(ok, "load a layout")
W.Wait(3)
check(reserved(49) and reserved(49).name == "Blink" and not action(49), "unknown spells come back as reservations")
check(action(50) and action(50).id == POLYMORPH, "known spells come back as real buttons")
check(action(26) and action(26).kind == "macro", "macros come back by name")
check(action(25) and action(25).id == 5512, "items come back")
check(action(27).id == 78, "mounts and other special buttons are left alone")
check(#W.printed == 0, "loading a layout does not flood the chat")
W.combat = true
ok = ns.Presets.Load("Raid")
check(not ok, "no layout loading in combat")
ns.DB.presets.MAGE.Broken = { by = "a hand edit" }
check(not ns.Presets.Load("Broken") and type(S.Name({})) == "string", "a saved layout of another shape is refused, and anything gets a name")
ns.DB.presets.MAGE.Broken = nil
W.combat = false
sane("layouts")
check(printedMatch("saved layouts: Raid"), "/sane ab layouts lists them")

-- The spellbook's options menu ---------------------------------------------------------------
local lines = {}
W.menuModifiers.MENU_SPELL_BOOK_SETTINGS(nil, W.Description(lines))
local function line(text)
    for _, item in ipairs(lines) do if item.text == text then return item end end
end
check(line("Show unlearned spells") and line("Show unlearned spells").checked() == true, "the spellbook's own menu gets 'Show unlearned spells'")
line("Show unlearned spells").fn()
check(ns.DB.options.showHidden == false and ghostCount() == 0, "which switches the grey entries off")
line("Show unlearned spells").fn()
check(ns.DB.options.showHidden == true and ghostCount() > 0, "and on")
check(not line("Show all spell ranks"), "a mage has the game's own 'Show all spell ranks' line; no second one is added")
check(line("Show reservations on the action bars").checked() and line("Say in chat when a reserved button is filled"), "the two older options moved here")
local layouts = line("Action bar layouts")
check(layouts.sub[1].text == "Save the current layout as..." and layouts.sub[2].text == "Raid" and layouts.sub[2].sub[1].text == "Load", "and so did the saved layouts")
layouts.sub[1].fn()
check(W.popups[#W.popups].which == "SANEUI_SPELLBOOK_SAVE", "saving asks for a name")
layouts.sub[2].sub[3].fn()
check(#ns.Presets.List() == 1 and W.popups[#W.popups].which == "GENERIC_CONFIRMATION", "Delete asks first")
W.popups[#W.popups].data.callback()
check(#ns.Presets.List() == 0, "and deletes the layout once confirmed")
check(lines[1].title == "Sane UI", "under the addon's name")

-- Sane UI, its own pages Profiles, General and Appearance, then the module's
check(#W.options.pages == 5 and #W.options.pages[5].items == 0,
    "the options are not filled before somebody wants them; their pages are up, empty")
SlashCmdList.SANEUI("options")
local page = W.options.pages[5]
local function box(text)
    for _, item in ipairs(page.items) do if item.setting and item.setting.name == text then return item.setting end end
end
check(#W.options.pages == 5 and page.name == "Abilities" and page.parent.name == "Sane UI" and #page.items == 9
    and W.options.opened == page.parent.id, "/sane options fills them: a page for the module under Sane UI, called Abilities, with its seven switches under two headers")
check(box("Show unlearned spells"):GetValue() == true and box("Show reservations on the action bars") and box("Say in chat when a reserved button is filled"), "the same ones as the spellbook's menu")
box("Show unlearned spells"):SetValue(false)
check(ns.DB.options.showHidden == false and ghostCount() == 0 and line("Show unlearned spells").checked() == false, "ticked there, the spellbook follows, and so does its menu")
box("Show unlearned spells"):SetValue(true)
check(ghostCount() > 0, "and back")
W.printed = {}
box("Sane UI lays out the spellbook pages"):SetValue(false)
check(ns.DB.options.book == false and printedMatch("after /reload") and ghostCount() > 0, "giving the pages back to the game waits for a /reload, and says so")
box("Sane UI lays out the spellbook pages"):SetValue(true)

ns.class, ns.DB.presets.WARRIOR = "WARRIOR", {}
lines = {}
W.menuModifiers.MENU_SPELL_BOOK_SETTINGS(nil, W.Description(lines))
check(line("Show all spell ranks") and line("Show all spell ranks").checked() == false, "a warrior gets the rank line the game does not offer him")
line("Show all spell ranks").fn()
check(W.cvars.ShowAllSpellRanks == "1", "it is the game's own setting")
W.cvars.ShowAllSpellRanks = nil
ns.class = "MAGE"

-- Ghost icons on the real bars -----------------------------------------------------------
ActionButton1 = W.NewWidget("CheckButton", "ActionButton1")
ActionButton1.action = 73
check(ns.Bar1Offset() == 72, "Bar 1 follows the form row the real button shows")
ActionButton1.action = 1
W.actions[1] = nil
ns.Fire("REFRESH")
local barGhost
for _, widget in ipairs(W.frames) do
    if widget._parent == ActionButton1 and widget.fallback then barGhost = widget end
end
check(barGhost and not barGhost:IsShown(), "no ghost on a real button without a reservation")
E.Reserve(1, entry("Blink"))
W.Wait(2)
check(barGhost:IsShown(), "a ghost shows on the empty, reserved real button")
ns.DB.options.ghosts = false
ns.Fire("REFRESH")
check(not barGhost:IsShown(), "and hides when ghosts are switched off")
ns.DB.options.ghosts = true
ns.Fire("REFRESH")

-- Carrying a reservation from one button to another, as you drag a real one
check(barGhost:IsShown() and reserved(1).name == "Blink", "Blink waits on Bar 1, button 1")
check(E.Reserve(65, entry("Combustion")), "and Combustion on Bar 2, button 5")
W.Wait(1)
W.cvars.lockActionBars = "1"
ActionButton1:GetScript("OnDragStart")(ActionButton1)
check(not ns.Drag.Held(), "with the bars locked a reservation stays where it is")
W.modifier = "PICKUPACTION"
ActionButton1:GetScript("OnDragStart")(ActionButton1)
check(ns.Drag.Held() and ns.Drag.Held().name == "Blink", "with the pick-up key held it is picked up, as a real action would be")
W.modifier = nil
MultiBarBottomLeftButton5._mouseOver = true
ActionButton1:GetScript("OnDragStop")(ActionButton1)
MultiBarBottomLeftButton5._mouseOver = false
check(not ns.Drag.Held() and reserved(65).name == "Blink" and reserved(1).name == "Combustion", "dropped on a reserved button, the two change places")
W.cvars.lockActionBars = nil
ActionButton1:GetScript("OnDragStart")(ActionButton1)
check(ns.Drag.Held() and ns.Drag.Held().name == "Combustion", "with the bars unlocked no key is needed")
ActionButton1:GetScript("OnDragStop")(ActionButton1)
check(not reserved(1) and not ns.Drag.Held(), "let go where there is no button, it is taken off the bar, as a real action is")
E.Reserve(1, entry("Combustion"))
W.Wait(1)
W.actions[1] = { kind = "spell", id = FIREBALL2 }
ActionButton1:GetScript("OnDragStart")(ActionButton1)
check(not ns.Drag.Held(), "a button with a real action on it is the game's to drag")
W.actions[1] = nil
E.Clear(65)
E.Reserve(1, entry("Blink")) -- as it was, for what follows
W.Wait(1)

-- /sane abilities ---------------------------------------------------------------------------------
W.printed = {}
sane("list")
check(printedMatch("Bar 1, button 1: Blink") and printedMatch("Bar 3, button 1: Blink"), "/sane ab list names every reservation")
sane("debug")
check(printedMatch("still to learn") and printedMatch("spellbook: %d+ of the game's entries") and printedMatch("reservations: "), "/sane ab debug reports")
W.printed = {}
sane("")
check(#W.printed >= 6 and printedMatch("/sane ab list") and not printedMatch("train %-"), "/sane abilities alone explains itself")
sane("clear")
check(next(ns.char.reserved) == nil and printedMatch("reservations removed"), "/sane ab clear removes every reservation")
sane("pages off")
check(ns.DB.options.book == false and printedMatch("left to the game after /reload"), "/sane ab pages off leaves the spellbook's pages to the game from the next /reload")
SlashCmdList.SANEUI("AB pages off")
check(ns.DB.options.book == false, "/sane ab is short for /sane abilities")
SlashCmdList.SANEUI("SB pages on")
check(ns.DB.options.book == true, "and the old words, /sane spellbook and /sane sb, still work")

W.spells[MIND].passive = true
ns.QueueUpdate(true, 0)
W.Wait(1)

-- The General tab: passive spells and skills to learn ------------------------------------------
W.spells[227] = { name = "Staves" }
D.WeaponSkills = { { id = 227, level = 1, cost = 1000 } }
ns.QueueUpdate(true, 0)
W.Wait(1)
check(entry("Staves") and entry("Staves").skill and names(S.UnlearnedSkills()) == "Staves" and S.stats.skill == 1, "a weapon skill you have not learned is listed as a skill")
local function section(text)
    for _, widget in ipairs(W.frames) do
        if widget.isOurHeader and widget._parent == SaneUISpellbook and widget:IsShown() and widget.Text:GetText() == text then return widget end
    end
end
searching, activeTab = false, tabs[1]
made = DrawTab("General", { "Attack" })
check(stands(made[1], view1, 0, -61) and section("Passive spells to learn") and stands(section("Passive spells to learn"), view1, 0, -161)
    and stands(ghost("Arcane Mind"), view1, 0, -222), "General lists the passive spells to come in a section under its active spells")
check(section("Skills to learn") and stands(section("Skills to learn"), view1, 0, -322) and stands(ghost("Staves"), view1, 0, -383), "and the skills to learn in another")
W.cvars.spellBookHidePassives = "1"
DrawTab("General", { "Attack" })
check(not section("Passive spells to learn") and not ghost("Arcane Mind") and ghost("Staves"), "the spellbook's own 'hide passives' hides that section")
W.cvars.spellBookHidePassives = nil
activeTab = tabs[2]
DrawTab("Arcane", { "Arcane Intellect" })
check(not section("Skills to learn") and not ghost("Staves") and not ghost("Arcane Mind"), "the other tabs have neither")

-- The checkbox next to the page buttons
local box = SaneUISpellbookShowHidden
check(box:IsShown() and box.checked == true and box.Text:GetText() == "Show unlearned spells", "next to the page buttons a checkbox shows whether unlearned spells are on")
box.checked = false
box:GetScript("OnClick")(box)
check(ns.DB.options.showHidden == false and ghostCount() == 0, "unticking it hides them")
box.checked = true
box:GetScript("OnClick")(box)
check(ns.DB.options.showHidden == true and ghostCount() > 0 and box.checked == true, "ticking it shows them again")
check(stands(tabSystem, book, 116, -26), "the row of the game's tabs stands one tab to the right, to make room for Home")
check(book.SearchBox:GetWidth() == 244, "and the search box makes room for it, as the game's own sum would")

-- The two marks ------------------------------------------------------------------------------
searching, activeTab = false, tabs[2]
wipe(ns.char.reserved)
W.actions[1] = nil
check(E.Reserve(1, entry("Arcane Explosion", "Rank 2")), "reserve the second rank of a spell you have no rank of")
W.Wait(2)
W.cvars.ShowAllSpellRanks = "1"
made = DrawTab("Arcane", { "Arcane Intellect" })
local first = ghost("Arcane Explosion", "Rank 1")
check(first and not ghost("Arcane Explosion", "Rank 2") and first.Button.Reserved:IsShown(), "folded, the spell's one entry carries the clock for all its ranks")
check(not first.Button.Quest:IsShown(), "a spell the trainer sells carries no yellow mark")
fold("Arcane Explosion"):GetScript("OnClick")(fold("Arcane Explosion"))
local second
first, second = ghost("Arcane Explosion", "Rank 1"), ghost("Arcane Explosion", "Rank 2")
check(second.Button.Reserved:IsShown() and not first.Button.Reserved:IsShown(), "unfolded, only the rank that was reserved carries it")
check(#ns.BookItem.ReservedSlots(second.entry) == 1 and #ns.BookItem.ReservedSlots(first.entry) == 0, "and only that rank says where it is reserved")
fold("Arcane Explosion", true):GetScript("OnClick")(fold("Arcane Explosion", true))
W.cvars.ShowAllSpellRanks = nil
made = DrawTab("Arcane", { "Arcane Intellect" })
check(ghost("Arcane Explosion", "Rank 1").Button.Reserved:IsShown() and not ghost("Arcane Explosion", "Rank 2"), "with one icon per spell, that icon carries it")
check(not ghost("Blink").Button.Reserved:IsShown(), "a spell nothing is reserved for carries none")

check(barGhost:IsShown() and barGhost.mark and barGhost.entry.name == "Arcane Explosion", "the reserved button on the bar shows the spell, with the same clock in its corner")
local tipped
GameTooltip.SetSpellByID = function(_, id) tipped = id end
ActionButton1:GetScript("OnEnter")(ActionButton1)
check(tipped == EXPLOSION2, "pointing at a reserved button shows that spell's tooltip")
W.PlayerPlaces(1, "spell", FIREBALL2)
W.Wait(1)
tipped = nil
ActionButton1:GetScript("OnEnter")(ActionButton1)
check(tipped == nil and not barGhost:IsShown(), "a button with something real on it keeps the game's own tooltip")
GameTooltip.SetSpellByID = nil

-- The Home page --------------------------------------------------------------------------------
local H = ns.Home
local WAND = 9100
W.spells[WAND] = { name = "Conjure Wand" }
C_Map = { GetAreaInfo = function(area) return area == 12 and "Elwynn Forest" or nil end }
D.AddQuestSpells({ MAGE = { [WAND] = { { raceIDs = { 7 }, level = 4, area = 99, quests = { 1 } }, { raceIDs = { 1 }, level = 8, area = 12, quests = { 2 } } } } })
W.level = 12 -- the trainer now has the third rank of Fireball, and Arcane Mind
ns.QueueUpdate(true, 0)
W.Wait(1)
check(entry("Conjure Wand") and entry("Conjure Wand").state == "quest" and entry("Conjure Wand").level == 8, "a quest reward is listed from the row for your race")
local function homeRow(name)
    for _, widget in ipairs(W.frames) do
        if widget._parent == SaneUISpellbookHome and widget.entry and widget:IsShown() and widget.entry.name == name then return widget end
    end
end
check(not H.IsOpen() and not SaneUISpellbookHome:IsShown(), "the Home page is there, and closed while the spellbook is")
made = DrawTab("Fire", { "Fireball" })
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Show")
check(H.IsOpen() and SaneUISpellbookHome:IsShown(), "the spellbook opens on its Home page")
check(at(made[1]) == UIParent and ghostCount() == 0 and not SaneUISpellbookPager:IsShown() and not box:IsShown(), "the tab underneath steps aside: its entries, the grey ones, the page buttons and the checkbox")
local fire, wand = homeRow("Fireball"), homeRow("Conjure Wand")
check(fire and fire.entry.sub == "Rank 3" and fire.RequiredLevel:GetText() == "900 copper" and not fire.Button.Quest:IsShown() and homeRow("Arcane Mind"),
    "Home lists what the trainer teaches you now, with its price")
check(wand and wand.RequiredLevel:GetText() == "Quest in Elwynn Forest" and wand.Button.Quest:IsShown(), "and the spells that come from quests, with the place and the yellow mark")
check(not homeRow("Blink") and not homeRow("Arcane Explosion") and H.shown == 3, "but nothing that is still levels away")
local trainHeader
for _, widget in ipairs(W.frames) do
    if widget.isOurHeader and widget._parent == SaneUISpellbookHome and widget:IsShown() and widget.Text:GetText():find("trainer") then trainHeader = widget end
end
check(trainHeader and trainHeader.Text:GetText() == "At your trainer now: 1000 copper" and stands(trainHeader, view1, 0, 0) and stands(wand, view2, 0, -103),
    "the trainer's spells on the left page under their total, the quests on the right")
local levelLine
for _, widget in ipairs(W.frames) do
    if widget._parent == SaneUISpellbookHome and widget._kind == "FontString" and widget:IsShown() and widget:GetText() == "Level 8" then levelLine = widget end
end
check(levelLine and stands(levelLine, view2, 8, -71), "the quest rewards stand under the level you get them at")
W.level = 2
ns.QueueUpdate(true, 0)
W.Wait(1)
check(homeRow("Conjure Wand") and levelLine:IsShown() and levelLine:GetAlpha() == 0.5 and not homeRow("Fireball") and H.shown == 1, "a level you have not reached is fainter; Home follows your level")
W.level = 10
ns.QueueUpdate(true, 0)
W.Wait(1)

tabSystem.selectedTabID, activeTab = 2, tabs[2]
made = DrawTab("Arcane", { "Arcane Intellect" })
check(not H.IsOpen() and not SaneUISpellbookHome:IsShown() and at(made[1]) == view1 and ghostCount() > 0, "clicking a tab of the spellbook closes Home and shows that tab")
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Hide")
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Show")
check(not H.IsOpen(), "making the spellbook small or large is not opening it: the tab stays")
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Hide")
W.Wait(1)
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Show")
check(H.IsOpen(), "opening it again starts on Home again")
local drawn, All = 0, S.All
S.All = function(...)
    drawn = drawn + 1
    return All(...)
end
book:Hide()
ns.Fire("REFRESH")
check(drawn == 0, "closed, the spellbook keeps Home as it was: nothing is drawn on it until it opens")
book:Show()
ns.Fire("REFRESH")
S.All = All
check(drawn > 0, "open, Home follows every update")
searching = true
DrawTab(nil, { "Fireball" })
check(not H.IsOpen(), "a search closes Home")
searching = false
H.Open()
ns.Fire("BOOK_JUMP")
check(not H.IsOpen(), "and so does the game jumping to a spell")
ns.DB.options.home = false
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Hide")
W.Wait(1)
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Show")
check(not H.IsOpen(), "with the switch off the spellbook opens on its own tab")
H.Open()
check(H.IsOpen(), "and Home is one click away")
H.Close()
tabSystem.selectedTabID = 3

-- Compact pages that follow the window's size ---------------------------------------------------
searching, activeTab = false, tabs[2]
ns.DB.options.compact = true
paged:SetSize(1612, 652) -- the game's own open book
made = DrawTab("Arcane", many)
-- Where an entry stands in the page's own measure: an entry drawn smaller counts in its own.
local function small(frame, relativeTo, x, y) return stands(frame, relativeTo, x / 0.75, y / 0.75) end
check(made[1]:GetScale() == 0.75 and ghost("Arcane Explosion"):GetScale() == 0.75, "compact: every entry is drawn smaller")
check(small(made[1], view1, 0, -55) and small(made[11], view1, 170, -55) and small(made[40], view1, 510, -496),
    "and stands closer: four columns of ten on a page")
check(SaneUISpellbookPager.maxPages == 1 and small(ghost("Arcane Explosion"), view1, 797, 0) and small(ghost("Blink"), view1, 967, 0), "43 entries are one open book now; the right page starts right of the middle")
paged:SetSize(900, 500) -- the window dragged small
ns.Fire("REFRESH")
check(SaneUISpellbookPager.maxPages == 3 and small(made[7], view1, 0, -349) and small(made[8], view1, 441, 0) and small(made[15], view1, 441, -343),
    "a smaller window: one column of seven, then eight, to a page, and more pages")
paged.viewsPerPage = 1
ns.Fire("REFRESH")
check(SaneUISpellbookPager.maxPages == 2 and small(made[8], view1, 170, -55) and small(made[22], view1, 510, -55) and at(made[30]) == UIParent,
    "the small spellbook of that width: one page as wide as the window, four columns again")
paged.viewsPerPage = 2
ns.DB.options.compact = false
paged:SetSize(0, 0)
ns.Fire("REFRESH")
check(made[1]:GetScale() == 1 and stands(made[1], view1, 0, -61) and at(made[40]) == view2, "switched off, the pages are the game's again")

-- Moving and sizing the window --------------------------------------------------------------------
check(not rawget(_G, "SaneUISpellbookDragBar"), "with the switch off the window is left alone")
ns.DB.options.window = true
ns.Fire("REFRESH")
local bar, grip = SaneUISpellbookDragBar, SaneUISpellbookSizeGrip
check(bar and bar:IsShown() and grip:IsShown(), "switched on, the spellbook gets a bar to drag and a grip in its corner")
local frameCalls = {}
for _, method in ipairs({ "StartMoving", "StartSizing", "StopMovingOrSizing" }) do
    PlayerSpellsFrame[method] = function() frameCalls[#frameCalls + 1] = method end
end
PlayerSpellsFrame.GetLeft, PlayerSpellsFrame.GetTop = function() return 40 end, function() return 900 end
grip:GetScript("OnMouseDown")(grip)
PlayerSpellsFrame:SetSize(1000, 600) -- the mouse drags the corner
PlayerSpellsFrame:GetScript("OnSizeChanged")(PlayerSpellsFrame)
grip:GetScript("OnMouseUp")(grip)
check(frameCalls[1] == "StartSizing" and frameCalls[2] == "StopMovingOrSizing", "dragging the grip sizes the window")
check(ns.DB.window.large[1] == 1000 and ns.DB.window.large[2] == 600 and ns.DB.window.left == 40 and ns.DB.window.top == 900, "the size and the place are kept")
check(book:GetWidth() == 994 and book:GetHeight() == 582, "and the spellbook fills the window")
PlayerSpellsFrame:SetSize(1618, 720) -- the game gives the window its own size, as it does at every opening
book:SetSize(1612, 702)
PlayerSpellsFrame:GetScript("OnShow")(PlayerSpellsFrame)
W.Wait(0.1)
check(PlayerSpellsFrame:GetWidth() == 1000 and book:GetWidth() == 994 and stands(PlayerSpellsFrame, UIParent, 40, 900), "ours is put on it again a moment later, and its place")
bar:GetScript("OnDragStart")(bar)
PlayerSpellsFrame.GetLeft = function() return 300 end
bar:GetScript("OnDragStop")(bar)
check(frameCalls[3] == "StartMoving" and ns.DB.window.left == 300 and stands(PlayerSpellsFrame, UIParent, 300, 900), "dragging the bar moves the window, and that is kept too")
W.combat = true
grip:GetScript("OnMouseDown")(grip)
bar:GetScript("OnDragStart")(bar)
check(#frameCalls == 4, "in a fight the window cannot be moved or sized")
W.printed = {}
sane("window reset")
check(ns.DB.window == nil and PlayerSpellsFrame:GetWidth() == 1000 and printedMatch("when the fight is over"), "in a fight /sane sb window reset waits for its end")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0.1)
check(PlayerSpellsFrame:GetWidth() == 1618 and book:GetWidth() == 1612, "then the window has the game's size again")
book.isMinimized = true -- the small spellbook: 806 wide in a window of 809
PlayerSpellsFrame:SetSize(809, 720)
book:SetSize(806, 702)
grip:GetScript("OnMouseDown")(grip)
PlayerSpellsFrame:SetSize(700, 600)
PlayerSpellsFrame:GetScript("OnSizeChanged")(PlayerSpellsFrame)
grip:GetScript("OnMouseUp")(grip)
check(ns.DB.window.small[1] == 700 and book:GetWidth() == 697 and book:GetHeight() == 582, "the small spellbook keeps a size of its own, and the game's narrower margin")
book.isMinimized = nil -- made large: the game gives the window its size, and the book only its width
PlayerSpellsFrame:SetSize(1618, 720)
book:SetWidth(1612)
PlayerSpellsFrame:GetScript("OnShow")(PlayerSpellsFrame)
W.Wait(0.1)
check(PlayerSpellsFrame:GetWidth() == 1618 and book:GetWidth() == 1612 and book:GetHeight() == 702,
    "made large without a size of its own, the spellbook fills the game's window, in height too")
book.isMinimized = true
PlayerSpellsFrame:SetSize(809, 720)
book:SetWidth(806)
PlayerSpellsFrame:GetScript("OnShow")(PlayerSpellsFrame)
W.Wait(0.1)
check(PlayerSpellsFrame:GetWidth() == 700 and book:GetWidth() == 697 and book:GetHeight() == 582, "made small again, it has its small size again")
W.printed = {}
sane("window reset")
check(ns.DB.window == nil and PlayerSpellsFrame:GetWidth() == 809 and book:GetWidth() == 806 and printedMatch("its own size again"), "/sane ab window reset gives it the game's size back")
book.isMinimized = nil
ns.DB.options.window = false
ns.Fire("REFRESH")
check(not bar:IsShown() and not grip:IsShown(), "switched off, the bar and the grip go")

-- Giving the pages back --------------------------------------------------------------------
W.printed = {}
searching, activeTab = false, tabs[3]
made = DrawTab("Fire", { "Fireball" })
check(ghostCount() == 2 and stands(made[1], view1, 0, -61), "the Fire tab once more, with its grey entries")
W.gamepad = true                      -- a controller is switched on: the game pages by itself then
H.Open()                              -- Home empties the page underneath, and that redraw notices it
check(view1:GetHeight() == 590 and stands(nativePager, paged, -75, 40), "when the plan cannot hold, the game's column and page buttons are given back")
check(not SaneUISpellbook:IsShown() and printedMatch("left the spellbook's pages to the game %(a controller is in use%)"), "the addon's entries go, and it says why")
H.Open()
check(not ns.Home.IsOpen() and not SaneUISpellbookHome:IsShown() and stands(tabSystem, book, 70, -26),
    "Home goes with them, also when it was opening: it needs the pages. The row of tabs gets its place back")
check(book.SearchBox:GetWidth() == 290, "and the search box its room")
check(stands(made[1], view1, 0, -61), "what is on screen is tidied one last time")
made = DrawTab("Fire", { "Fireball" })
check(stands(made[1], view1, 0, -70), "and the game's layout is left alone from then on")

-- The class files: edited by hand, so their format is checked here ------------------------
local FIELDS = { talent = "number", after = "number", alone = "boolean", side = "string", raceIDs = "table" }
for _, class in ipairs({ "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }) do
    local given = {}
    W.Load(root, "SaneUI_Abilities", "Abilities/Data/Classes/" .. class,
        { Data = { Class = function(name, tables) given.name, given.tables = name, tables end } })
    local families, conditions = given.tables()
    local seen, problem = {}, nil
    for _, family in ipairs(families) do
        local last, sold = 0, false
        for token in family:gmatch("%S+") do
            local id, level, cost = token:match("^(%d+):(%d+):(%d+)$")
            id, level = tonumber(id or token:match("^(%d+)$")), tonumber(level)
            if not id or seen[id] then problem = problem or ("rank " .. token) end
            if level and (level <= last or level > 60 or not tonumber(cost)) then problem = problem or ("level of " .. token) end
            seen[id or token], last, sold = true, level or last, sold or level ~= nil
        end
        if not sold then problem = problem or ("nothing sold in " .. family) end
    end
    for id, rule in pairs(conditions) do
        if not seen[id] then problem = problem or ("condition of " .. id .. ", a spell of no family") end
        for key, value in pairs(rule) do
            if type(value) ~= FIELDS[key] then problem = problem or ("condition " .. key .. " of " .. id) end
        end
        if rule.side and rule.side ~= "Alliance" and rule.side ~= "Horde" then problem = problem or ("side of " .. id) end
    end
    check(given.name == class:upper() and #families > 20 and not problem,
        "the " .. class .. " file is in the trainer data's format" .. (problem and (": " .. problem) or ""))
end

-- Errors are caught and kept (core.lua); none happened in everything above ----------------
for label, problem in pairs(Core.errors) do io.stderr:write(label .. ": " .. problem.text .. "\n") end
check(next(Core.errors) == nil, "no step of the module raised an error")
ns.Safe("test", function() error("boom") end)
check(SaneUIDB.errors["Abilities: test"].text:find("boom"), "one that does is kept under the module's name")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Abilities: all %d checks passed.\n"):format(passed))
