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
-- A slot the game hides from addons (hidden = true on its action, as the 12.x client does in a fight) answers
-- every reader with a secret value. Before Abilities.lua runs: it keeps the readers it finds.
local function Hidden(reader)
    return function(slot)
        local action = W.actions[slot]
        if action and action.hidden then return W.Secret(), W.Secret() end -- a kind and an ID; the others take one
        return reader(slot)
    end
end
C_ActionBar.HasAction, C_ActionBar.GetActionTexture, C_ActionBar.GetActionText =
    Hidden(C_ActionBar.HasAction), Hidden(C_ActionBar.GetActionTexture), Hidden(C_ActionBar.GetActionText)
GetActionInfo = Hidden(GetActionInfo)
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

for _, file in ipairs({ "Data/SkillLines", "Sources", "Buttons", "Engine", "Ghosts", "Presets", "Bar1", "FormBar", "Spacing",
                        "Book/Layout", "Book/Item", "Book/Drag", "Book/Book", "Book/Home", "Book/Window", "Book/Menu",
                        "Book/Offer" }) do
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
local words = true
for _, text in pairs(ns.TEXT) do
    if type(text) == "table" then
        for _, line in pairs(text) do words = words and type(line) == "string" end
    else
        words = words and type(text) == "string"
    end
end
check(words and ns.TEXT.home == "Home" and #ns.TEXT.help >= 6, "every word the module shows is in one table of its own (ns.TEXT)")
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
check(ns.options == Core.Settings("Abilities") and ns.options == SaneUIDB.modules.Abilities.options, "the switches are the table Core keeps for the module")
check(ns.options.showHidden and ns.options.book and ns.options.ghosts, "hidden spells are shown unless you switch them off")
check(ns.options.announce == false, "a switch you flipped keeps your choice")
ns.options.announce = true
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
    { kind = "unavailable", name = "Mana Shield", icon = 305, level = 20, sub = "Rank 1", category = "Arcane", cost = 2000, id = SHIELD }, -- a spell the game has not named yet: no ID to be had
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
-- The game had not loaded the spell's name when the row was read (without it the row's ID is not taken): read
-- again at the next look, the row gets its ID once the game names the spell.
W.spells[SHIELD] = { name = "Mana Shield", sub = "Rank 1" }
W.Fire("TRAINER_SHOW")
W.Wait(1)
check(taught.spells[SHIELD] and taught.spells[SHIELD].id == SHIELD and taught.spells[SHIELD].cost == 2000
    and taught.spells["Mana Shield#Rank 1"] == nil and entry("Mana Shield") and entry("Mana Shield").id == SHIELD and #S.All() == 14,
    "a row kept without its spell ID gets it at a later read, once the game names the spell")
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
check(pages[1][2].x == 0 and pages[1][2].y == 70 and pages[1][5].y == 280, "ten spells need four rows: the first column takes four")
check(pages[1][6].x == 215 and pages[1][6].y == 70 and pages[1][10].x == 430 and pages[1][11].y == 140, "the second four, the third the last two")
check(L.Paginate({ group(3, true) }, 200)[1][2].y == L.Paginate({ group(6, false) }, 200)[1][2].y,
    "a heading is as high as a row (this client's template): the rows under it line up with those of a page without one")
pages = L.Paginate({ group(30, true) }, 200)
check(#pages == 2 and #pages[1] == 22 and #pages[2] == 9, "under a heading a page holds seven rows; the rest goes on")
check(pages[2][1].y == 0 and pages[2][4].x == 215 and pages[2][9].y == 140, "and is spread over as few rows as it needs")
pages = L.Paginate({ group(24, false) }, 200)
check(#pages == 1 and pages[1][24].y == 490, "without a heading a page holds eight rows")
pages = L.Paginate({ group(3, true), group(3, true) }, 200)
check(#pages == 1 and pages[1][5].header and pages[1][5].y == 170 and pages[1][6].y == 240, "a second group follows after a gap")
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
check(stands(heading, view1, 0, 0) and stands(made[1], view1, 0, -70), "the game's own entries are put where they belong, first")
check(ghost("Combustion") and stands(ghost("Combustion"), view1, 231, -70) and stands(ghost("Pyroblast"), view1, 462, -70),
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
check(ghostCount() == 2 and at(made[1]) == UIParent and stands(made[2], view1, 0, -70),
    "with ranks shown, the ranks of a spell are folded into the highest one you have")
local plus = fold("Fireball")
check(plus and plus.more == 3 and stands(plus, view1, 216 - 18, -72) and not fold("Pyroblast"), "it carries a + that says how many more there are; a spell of one rank has none")
plus:GetScript("OnEnter")(plus)
check(GameTooltip:GetOwner() == plus and GameTooltip._text == "Show all ranks of Fireball (3 more)", "pointed at, it says so")
plus:GetScript("OnLeave")(plus)
local sounds = {}
local play = PlaySound
PlaySound = function(id) sounds[#sounds + 1] = id end
plus:GetScript("OnClick")(plus)
PlaySound = play
check(sounds[1] == SOUNDKIT.IG_ABILITY_PAGE_TURN, "a page turns, with the game's sound for it")
check(fold("Fireball", true) and stands(fold("Fireball", true), view1, 0, -150) and not fold("Fireball"), "a click on it unfolds the ranks into a section of their own, under the tab's spells")
check(ghostCount() == 4 and stands(made[1], view1, 0, -182) and stands(made[2], view1, 0, -252), "the ranks you have first")
check(stands(ghost("Fireball", "Rank 3"), view1, 231, -182) and stands(ghost("Fireball", "Rank 4"), view1, 231, -252), "the ranks to come right after them")
check(ghost("Fireball", "Rank 3").SubName:GetText() == "Rank 3" and ghost("Fireball", "Rank 3").RequiredLevel:GetText() == "Available at level 12", "each with its rank and level")
made = DrawTab("Fire", { "Fireball", "Fireball" })
check(fold("Fireball", true) and ghostCount() == 4, "they stay unfolded when the game draws the tab again")
fold("Fireball", true):GetScript("OnClick")(fold("Fireball", true))
check(not fold("Fireball", true) and fold("Fireball") and ghostCount() == 2 and at(made[1]) == UIParent, "a click on the heading folds them away again")
W.cvars.ShowAllSpellRanks = nil

made = DrawTab("Fire", { "Fireball" })
ns.options.showHidden = false
ns.Fire("REFRESH")
check(ghostCount() == 0 and stands(made[1], view1, 0, -70), "'Show hidden spells' off: the spellbook as the game draws it")
ns.options.showHidden = true
ns.Fire("REFRESH")
check(ghostCount() == 2, "and on again")

-- A displaced entry is put back (the game lays its column out again now and then)
made[1]:ClearAllPoints()
made[1]:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -999)
SaneUISpellbook:GetScript("OnUpdate")(SaneUISpellbook)
check(stands(made[1], view1, 0, -70), "an entry the game moved is put back at once")
local silent = W.NewWidget("Frame", nil, view1)
silent.spellBookItemInfo = { name = "Scorch" }
silent.GetElementData = function() return { isHeader = false } end
silent:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -140)
paged.frames[#paged.frames + 1] = silent
SaneUISpellbook:GetScript("OnUpdate")(SaneUISpellbook)
check(stands(silent, view1, 0, -140) and stands(ghost("Pyroblast"), view1, 231, -140), "and so is an entry the game added without saying so")
local watch = SaneUISpellbook:GetScript("OnUpdate")
for _ = 1, 10 do watch(SaneUISpellbook, 0.01) end -- the frames right after a layout are over
local _, _, _, homeX, homeY = made[1]:GetPoint(1)
made[1]:ClearAllPoints()
made[1]:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -999)
watch(SaneUISpellbook, 0.05)
check(stands(made[1], view1, 0, -999), "after them the entries are looked at five times a second, not in every frame")
watch(SaneUISpellbook, 0.2)
check(stands(made[1], view1, homeX, homeY), "and one out of place is put back at the next look")
-- Closed, the watcher does not run (it is a script of our page frame): an entry the game moves then is put back as the
-- spellbook opens, by the OnShow of the game's first column, shown with its window; ours is hooked after the game's.
book:Hide()
made[1]:ClearAllPoints()
made[1]:SetPoint("TOPLEFT", view1, "TOPLEFT", 0, -999)
book:Show()
check(stands(made[1], view1, homeX, homeY), "an entry moved while the spellbook was closed is put back as it opens: the column's OnShow runs when its window shows")

-- Spells without a tab: at the end of the first class tab
S.AddExtra(LATE)
W.Wait(1)
activeTab = tabs[2]
made = DrawTab("Arcane", { "Arcane Intellect" })
check(stands(made[1], view1, 0, -70) and stands(ghost("Polymorph"), view1, 0, -140) and stands(ghost("Arcane Explosion"), view1, 231, -70)
    and stands(ghost("Blink"), view1, 231, -140) and stands(ghost("Counterspell"), view1, 462, -140),
    "the Arcane tab: the spell you have, then what you can learn now, then the rest by level")
check(ghost("Mana Shield") and not ghost("Arcane Mind"), "the trainer-only spell among them, the passive one not")
local ourHeader
for _, widget in ipairs(W.frames) do
    if widget.isOurHeader and widget._parent == SaneUISpellbook and widget:IsShown() then ourHeader = widget end
end
check(ourHeader:IsShown() and ourHeader.Text:GetText() == "Other spells to learn" and stands(ourHeader, view1, 0, -240) and stands(ghost("Late Spell"), view1, 0, -310),
    "spells without a known tab get a group of their own at the end of the first class tab")
activeTab = tabs[4]
DrawTab("Frost", {})
check(not ourHeader:IsShown() and ghost("Frost Nova") and ghost("Ice Lance") and ghostCount() == 2, "and not on the other tabs")
DrawTab(nil, {})
local tabHeader
for _, widget in ipairs(W.frames) do
    if widget.isOurHeader and widget._parent == SaneUISpellbook and widget:IsShown() then tabHeader = widget end
end
check(tabHeader and tabHeader.Text:GetText() == "Frost" and stands(tabHeader, view1, 0, 0) and stands(ghost("Frost Nova"), view1, 0, -70),
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
check(stands(made[1], view1, 0, -70) and stands(made[22], view2, 0, 0), "the second column of the book is the game's second view")
check(not ghost("Counterspell"), "a grey entry of the next page is not on this one")
paged:GetScript("OnMouseWheel")(paged, -1)
check(SaneUISpellbookPager.currentPage == 2 and stands(ghost("Counterspell"), view1, 0, 0), "the mouse wheel turns the page")
check(at(made[1]) == UIParent and select(2, at(made[1])) < -5000, "entries of another page wait far off the screen")
check(ghostCount() == 1, "and the grey entries of the first page are gone from the second")
paged:GetScript("OnMouseWheel")(paged, 1)
check(stands(made[1], view1, 0, -70) and not ghost("Counterspell"), "and back")
paged.viewsPerPage = 1
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
check(SaneUISpellbookPager.maxPages == 3 and at(made[22]) == UIParent, "the small spellbook shows one column per page")
paged.viewsPerPage = 2
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
paged:GetScript("OnMouseWheel")(paged, -1)
W.slotOfSpell[4001] = 1              -- the game's slot of the first entry
book:GoToSpell(4001, true)
check(SaneUISpellbookPager.currentPage == 1 and stands(made[1], view1, 0, -70), "when the game jumps to a spell, our page follows")
paged:GetScript("OnMouseWheel")(paged, -1)
paged.viewsPerPage = 1
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
check(SaneUISpellbookPager.currentPage == 3 and stands(ghost("Counterspell"), view1, 0, 0), "making the spellbook small keeps the column you were reading")
paged.viewsPerPage = 2
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged")
check(SaneUISpellbookPager.currentPage == 2, "and large again")
activeTab = tabs[3]
made = DrawTab("Fire", { "Fireball" })
check(SaneUISpellbookPager.currentPage == 1 and stands(made[1], view1, 0, -70), "another tab starts on its first page")

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
check(stands(made[1], view1, 0, -70), "and put right when the fight is over")
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
check(ghostCount() == 0 and stands(made[2], view1, 231, -70), "search results are laid out as the game would")
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

-- A new rank: the buttons on the rank you had until now move up to it -------------------------------
do
    local FIREBALL5, FIREBALL6, FIREBALL7 = 8400, 8401, 8402
    local FROSTBOLT1, FROSTBOLT2, FROSTBOLT3, FROSTBOLT4 = 116, 205, 837, 7322
    W.spells[FIREBALL5], W.spells[FIREBALL6] = { name = "Fireball", sub = "Rank 5" }, { name = "Fireball", sub = "Rank 6" }
    W.spells[FIREBALL7] = { name = "Fireball", sub = "Rank 7" }
    W.spells[FROSTBOLT1], W.spells[FROSTBOLT2] = { name = "Frostbolt", sub = "Rank 1" }, { name = "Frostbolt", sub = "Rank 2" }
    W.spells[FROSTBOLT3], W.spells[FROSTBOLT4] = { name = "Frostbolt", sub = "Rank 3" }, { name = "Frostbolt", sub = "Rank 4" }
    local slots = { 14, 40, 41, 42, 43, 44, 45, 46, 75, 134 }
    for _, slot in ipairs(slots) do
        check(not W.actions[slot] and not reserved(slot), "(button " .. slot .. " is free for these checks)")
    end
    local function holds(slot, id) return action(slot) and action(slot).id == id end
    -- As in the game: the rank before it is a low rank from now on.
    local function learnRank(id, before, line)
        for _, row in ipairs(W.book) do
            if row.id == before then row.low = true end
        end
        W.Learn(id, line or 3)
    end

    W.actions[40] = { kind = "spell", id = FIREBALL2 }
    W.actions[14] = { kind = "spell", id = FIREBALL2 }    -- Bar 1's second page
    W.actions[75] = { kind = "spell", id = FIREBALL2 }    -- a form's row
    W.actions[41] = { kind = "spell", id = FIREBALL1 }    -- an older rank, kept on purpose
    W.actions[134] = { kind = "spell", id = FIREBALL2 }   -- a slot on no bar of yours
    W.actions[42] = { kind = "macro", id = 1, text = "Burn" }
    W.printed = {}
    learnRank(FIREBALL3, FIREBALL2)
    W.Wait(1)
    check(holds(40, FIREBALL3) and holds(14, FIREBALL3) and holds(75, FIREBALL3), "a new rank: every button on the rank you had moves up to it")
    check(holds(41, FIREBALL1), "a button on an older rank stays: you keep that one on purpose")
    check(holds(134, FIREBALL2) and action(42).kind == "macro", "a slot on no bar of yours and your macros stay as they are")
    check(not W.cursor and not next(S.outranked) and #W.printed == 0, "the old rank is gone from the cursor, and it goes without a word in chat")

    W.cursor = { kind = "item", id = 6948 }
    learnRank(FIREBALL4, FIREBALL3)
    W.Wait(1)
    check(holds(40, FIREBALL3) and W.cursor and W.cursor.id == 6948 and E.pending, "with something on your cursor it waits, and leaves your cursor alone")
    W.cursor = nil
    W.Fire("CURSOR_CHANGED")
    W.Wait(1)
    check(holds(40, FIREBALL4) and holds(14, FIREBALL4) and not W.cursor, "and is done when the cursor is free")

    W.combat = true
    learnRank(FIREBALL5, FIREBALL4)
    learnRank(FIREBALL6, FIREBALL5)
    W.Wait(1)
    check(holds(40, FIREBALL4), "in a fight the buttons stay")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    W.Wait(2)
    check(holds(40, FIREBALL6) and holds(41, FIREBALL1), "and move when it is over: two ranks at once land on the newest, the older button still stays")

    -- A rank named with a numeral (the rogue's poisons): a new name, the same spell.
    W.spells[8692] = { name = "Instant Poison III", sub = "Rank 3" }
    W.actions[46] = { kind = "spell", id = 8691 }
    learnRank(8692, 8691, 2)
    W.Wait(1)
    check(holds(46, 8692), "a rank named with a numeral moves up too: the spell is the same, its name is not")
    W.actions[46] = nil

    -- The pick-up refused: tried again at the next update, however the update came about.
    local Pickup = C_Spell.PickupSpell
    C_Spell.PickupSpell = function() end
    learnRank(FIREBALL7, FIREBALL6)
    W.Wait(1)
    check(holds(40, FIREBALL6) and next(S.outranked) ~= nil, "what the game refuses is not forgotten")
    C_Spell.PickupSpell = Pickup
    W.Fire("BAG_UPDATE_DELAYED")
    W.Wait(1)
    check(holds(40, FIREBALL7) and not next(S.outranked), "and is done at the next update")

    -- The game's own copy of a new rank, on a free button.
    W.Learn(FROSTBOLT1, 4)
    W.Wait(1)
    W.actions[43] = { kind = "spell", id = FROSTBOLT1 }
    learnRank(FROSTBOLT2, FROSTBOLT1, 4)
    W.actions[44] = { kind = "spell", id = FROSTBOLT2 }
    W.Fire("SPELL_PUSHED_TO_ACTIONBAR", FROSTBOLT2, 44, 1)
    W.Wait(1)
    check(holds(43, FROSTBOLT2) and not action(44), "the game's own copy of the new rank goes: your button has moved up to it")
    learnRank(FROSTBOLT3, FROSTBOLT2, 4)
    W.Wait(1)
    W.actions[44] = { kind = "spell", id = FROSTBOLT3 }
    W.Fire("SPELL_PUSHED_TO_ACTIONBAR", FROSTBOLT3, 44, 1)
    W.Wait(1)
    check(holds(43, FROSTBOLT3) and not action(44), "also when the game says so a moment later")
    W.actions[43] = nil
    learnRank(FROSTBOLT4, FROSTBOLT3, 4)
    W.actions[44] = { kind = "spell", id = FROSTBOLT4 }
    W.Fire("SPELL_PUSHED_TO_ACTIONBAR", FROSTBOLT4, 44, 1)
    W.Wait(1)
    check(holds(44, FROSTBOLT4), "with no button on the old rank it stays where the game put it")

    -- A rank given back (a talent) moves nothing down, and with the switch off nothing moves.
    local function giveBack(id, before)
        for index = #W.book, 1, -1 do
            if W.book[index].id == id then table.remove(W.book, index) end
        end
        for _, row in ipairs(W.book) do
            if row.id == before then row.low = false end
        end
        W.Fire("SPELLS_CHANGED")
        W.Wait(1)
    end
    W.actions[45] = { kind = "spell", id = FIREBALL7 }
    giveBack(FIREBALL7, FIREBALL6)
    check(S.known.Fireball == FIREBALL6 and holds(45, FIREBALL7) and not next(S.outranked), "a rank given back moves no button down")
    W.actions[46] = { kind = "spell", id = FIREBALL6 }
    ns.options.ranks = false
    learnRank(FIREBALL7, FIREBALL6)
    W.Wait(1)
    check(holds(46, FIREBALL6), "with the switch off the old rank stays, as in the game")
    ns.options.ranks = true

    -- Back as it was: Fireball rank 2 the highest, no Frostbolt.
    for index = #W.book, 1, -1 do
        local id = W.book[index].id
        if id == FIREBALL2 then
            W.book[index].low = false
        elseif id == 8692 or (id ~= FIREBALL1 and (W.spells[id].name == "Fireball" or W.spells[id].name == "Frostbolt")) then
            table.remove(W.book, index)
        end
    end
    for _, slot in ipairs(slots) do W.actions[slot] = nil end
    for _, id in ipairs({ FIREBALL5, FIREBALL6, FIREBALL7, FROSTBOLT1, FROSTBOLT2, FROSTBOLT3, FROSTBOLT4, 8692 }) do W.spells[id] = nil end
    W.Fire("SPELLS_CHANGED")
    W.Wait(1)
    check(S.known.Fireball == FIREBALL2 and not S.known.Frostbolt, "(the spellbook is back as it was)")
end

-- A slot the game hides from addons (a secret value) is no answer: nothing is ended or filled on it
E.Reserve(66, entry("Blink"))
W.Wait(2)
W.actions[66] = { kind = "spell", id = FIREBALL2, hidden = true }
ns.QueueUpdate(false, 0)
W.Wait(1)
check(reserved(66) and ns.HasAction(66) == "unknown", "a hidden slot keeps its reservation")
check(ns.RealEntry(66) == nil and ns.ActionTexture(66) == nil, "what sits there, and its icon, are not known: a secret goes through Core.Plain and comes out nil")
W.actions[66].hidden = nil
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
check(ns.options.showHidden == false and ghostCount() == 0, "which switches the grey entries off")
line("Show unlearned spells").fn()
check(ns.options.showHidden == true and ghostCount() > 0, "and on")
check(not line("Show all spell ranks"), "a mage has the game's own 'Show all spell ranks' line; no second one is added")
check(line("Show reservations on the action bars").checked() and line("Say in chat when a reserved button is filled"), "the two older options moved here")
check(line("Move buttons up to a new rank").checked(), "and the switch for new ranks stands with them, on by default")
local layouts = line("Action bar layouts")
check(layouts.sub[1].text == "Save the current layout as..." and layouts.sub[2].text == "Raid" and layouts.sub[2].sub[1].text == "Load", "and so did the saved layouts")
check(StaticPopupDialogs.SANEUI_SPELLBOOK_SAVE == nil and StaticPopupDialogs.SANEUI_SPELLBOOK_LOAD == nil,
    "no dialog of the module's own is put into the game's list")
layouts.sub[1].fn()
local asked = W.popups[#W.popups]
check(asked.which == "GENERIC_INPUT_BOX" and asked.data.acceptText == "Save" and asked.data.maxLetters == 32, "saving asks for a name, in the game's own dialog")
W.printed = {}
asked.data.callback("  Raid 2 ")
check(ns.DB.presets.MAGE["Raid 2"] and printedMatch('Layout "Raid 2" saved'), "and saves the bars under that name")
layouts.sub[2].sub[1].fn()
asked = W.popups[#W.popups]
check(asked.which == "GENERIC_CONFIRMATION" and asked.data.text_arg1 == "Raid" and asked.data.text:find("replaces the buttons"), "loading asks first")
asked.data.callback()
check(printedMatch('Layout "Raid" loaded'), "and loads the layout once confirmed")
ns.Presets.Delete("Raid 2")
layouts.sub[2].sub[3].fn()
check(#ns.Presets.List() == 1 and W.popups[#W.popups].which == "GENERIC_CONFIRMATION" and W.popups[#W.popups].data.showAlert, "Delete asks first, with the warning sign")
W.popups[#W.popups].data.callback()
check(#ns.Presets.List() == 0, "and deletes the layout once confirmed")
local show = StaticPopup_Show
StaticPopup_Show = function() return nil end
W.printed = {}
ns.Presets.AskDelete("Raid")
StaticPopup_Show = show
check(printedMatch("type /sane ab delete Raid"), "without the game's dialog the command to type is said")
check(lines[1].title == "Sane UI", "under the addon's name")
do
    -- The game's menu asks a line whether it is enabled, and for its tooltip, while it is open.
    local function Opened()
        local seen = {}
        local function Sub() return { CreateButton = function() return Sub() end } end
        local root = { CreateDivider = function() end, CreateTitle = function() end, CreateButton = function() return Sub() end }
        function root:CreateCheckbox(text)
            local item = {}
            seen[text] = item
            return { SetEnabled = function(_, fn) item.enabled = fn end, SetTooltip = function(_, fn) item.tooltip = fn end }
        end
        W.menuModifiers.MENU_SPELL_BOOK_SETTINGS(nil, root)
        return seen["Compact spellbook pages"]
    end
    local first, again = Opened(), Opened()
    local title
    local setTitle = GameTooltip_SetTitle
    GameTooltip_SetTitle = function(_, text) title = text end
    first.tooltip(GameTooltip) -- guarded: an error in it would stand the module down
    GameTooltip_SetTitle = setTitle
    check(first.enabled() == true and first.tooltip == again.tooltip and first.enabled == again.enabled
        and title == "Compact spellbook pages" and not ns.off,
        "a line's tooltip and whether it is enabled are asked of functions of ours made once, not at every opening")
end

-- Sane UI, its own pages Profiles, General and Appearance, then the module's
check(#W.options.pages == 5 and #W.options.pages[5].items == 0,
    "the options are not filled before somebody wants them; their pages are up, empty")
SlashCmdList.SANEUI("options")
local page = W.options.pages[5]
local function box(text)
    for _, item in ipairs(page.items) do if item.setting and item.setting.name == text then return item.setting end end
end
check(#W.options.pages == 5 and page.name == "Abilities" and page.parent.name == "Sane UI" and #page.items == 12
    and W.options.opened == page.parent.id, "/sane options fills them: a page for the module under Sane UI, called Abilities, with its ten switches under two headers")
check(box("Show unlearned spells"):GetValue() == true and box("Show reservations on the action bars") and box("Say in chat when a reserved button is filled"), "the same ones as the spellbook's menu")
box("Show unlearned spells"):SetValue(false)
check(ns.options.showHidden == false and ghostCount() == 0 and line("Show unlearned spells").checked() == false, "ticked there, the spellbook follows, and so does its menu")
box("Show unlearned spells"):SetValue(true)
check(ghostCount() > 0, "and back")
local notified = box("Show unlearned spells").notified or 0
line("Show unlearned spells").fn()
W.Wait(0.1)
check(ns.options.showHidden == false and ghostCount() == 0 and (box("Show unlearned spells").notified or 0) > notified,
    "a switch flipped in the spellbook's menu goes through Core: the spellbook follows, and so does the options page")
line("Show unlearned spells").fn()
W.Wait(0.1)
W.printed = {}
box("Sane UI lays out the spellbook pages"):SetValue(false)
check(ns.options.book == false and printedMatch("after /reload") and ghostCount() > 0, "giving the pages back to the game waits for a /reload, and says so")
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
ns.options.ghosts = false
ns.Fire("REFRESH")
check(not barGhost:IsShown(), "and hides when ghosts are switched off")
ns.options.ghosts = true
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
check(ns.options.book == false and printedMatch("left to the game after /reload"), "/sane ab pages off leaves the spellbook's pages to the game from the next /reload")
W.printed = {}
SlashCmdList.SANEUI("AB pages off")
check(ns.options.book == false and printedMatch("left to the game after /reload"), "/sane ab is short for /sane abilities; the same choice again is told too")
SlashCmdList.SANEUI("SB pages on")
check(ns.options.book == true, "and the old words, /sane spellbook and /sane sb, still work")

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
check(stands(made[1], view1, 0, -70) and section("Passive spells to learn") and stands(section("Passive spells to learn"), view1, 0, -170)
    and stands(ghost("Arcane Mind"), view1, 0, -240), "General lists the passive spells to come in a section under its active spells")
check(section("Skills to learn") and stands(section("Skills to learn"), view1, 0, -340) and stands(ghost("Staves"), view1, 0, -410), "and the skills to learn in another")
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
local sounds, play = {}, PlaySound
PlaySound = function(id) sounds[#sounds + 1] = id end
SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF = 856, 857
box.checked = false
box:GetScript("OnClick")(box)
check(ns.options.showHidden == false and ghostCount() == 0, "unticking it hides them")
box.checked = true
box:GetScript("OnClick")(box)
check(ns.options.showHidden == true and ghostCount() > 0 and box.checked == true, "ticking it shows them again")
check(sounds[1] == 857 and sounds[2] == 856, "with the game's sounds for a checkbox: off, then on")
PlaySound = play
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
local homeTab
for _, widget in ipairs(W.frames) do
    if widget._parent == book and widget._kind == "Button" and widget.Icon and widget.Icon._texture == "Interface\\Icons\\INV_Misc_Rune_01" then homeTab = widget end
end
GameTooltip._lines = {}
homeTab:GetScript("OnEnter")(homeTab)
check(GameTooltip:GetOwner() == homeTab and GameTooltip._text == "Home" and GameTooltip._lines[1]:find("What you can learn now"),
    "its tab, pointed at, says what Home is")
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
check(trainHeader and trainHeader.Text:GetText() == "At your trainer now: 1000 copper" and stands(trainHeader, view1, 0, 0) and stands(wand, view2, 0, -112),
    "the trainer's spells on the left page under their total, the quests on the right")
local levelLine
for _, widget in ipairs(W.frames) do
    if widget._parent == SaneUISpellbookHome and widget._kind == "FontString" and widget:IsShown() and widget:GetText() == "Level 8" then levelLine = widget end
end
check(levelLine and stands(levelLine, view2, 8, -80), "the quest rewards stand under the level you get them at")
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
ns.options.home = false
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Hide")
W.Wait(1)
EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Show")
check(not H.IsOpen(), "with the switch off the spellbook opens on its own tab")
H.Open()
check(H.IsOpen(), "and Home is one click away")
H.Close()
tabSystem.selectedTabID = 3

-- Combat's spellbook, through Core: the same spells still to learn, Home, the menu's lines -----------------
do -- its own locals: the main chunk has room for no more
    local offer = Core.Spellbook.Offer()
    check(offer and offer.Home and offer.Home.name == "Home" and offer.Switch.text == "Show unlearned spells",
        "the module offers its spells still to learn, Home and its switch to a book of Sane UI's own")
    local lines = { 1, 2, 3, 4 }
    local blinkTab = entry("Blink").tab
    local own = offer.Spells(blinkTab, false)
    local inOrder = true
    for index = 2, #own do inOrder = inOrder and not L.ByLevel({ entry = own[index] }, { entry = own[index - 1] }) end
    check(names(own):find("Blink") and inOrder and not names(own):find("Staves") and not names(own):find("Arcane Mind"),
        "a tab: its spells still to learn in the book's order, no passive spell or skill among them")
    local function texts(sections)
        local out = {}
        for index, section in ipairs(sections) do out[index] = section.text .. ":" .. names(section.entries) end
        return table.concat(out, " | ")
    end
    local general = texts(offer.Sections(1, lines, false, false))
    check(general:find("^Passive spells to learn:") and general:find("Skills to learn:Staves$"),
        "General: the passive spells and the skills to learn, each a section")
    check(texts(offer.Sections(1, lines, true, false)) == "Skills to learn:Staves", "the passive spells' section not while the game hides passives")
    check(texts(offer.Sections(3, lines, false, false)) == "", "a class tab after the first: no section of its own")
    local found = offer.Search("staves", lines, false)
    check(found[1] and names(found[1]) == "Staves" and names(offer.Search("blink", lines, false)[blinkTab]) == "Blink",
        "a search: each find in the tab it is listed in")
    ns.options.showHidden = false
    check(#offer.Spells(blinkTab, false) == 0 and #offer.Sections(1, lines, false, false) == 0
        and next(offer.Search("blink", lines, false)) == nil, "Show unlearned spells off: none of them")
    ns.options.showHidden = true
    -- Home on another book's pages, in that book's headings.
    local other = CreateFrame("Frame", nil, UIParent)
    local otherLeft, otherRight = CreateFrame("Frame", nil, other), CreateFrame("Frame", nil, other)
    local function OtherHeader(parent)
        local header = CreateFrame("Frame", nil, parent)
        header.Text = header:CreateFontString(nil, "ARTWORK")
        header.otherBook = true
        return header
    end
    W.level = 12 -- the trainer has the third rank of Fireball again
    ns.QueueUpdate(true, 0)
    W.Wait(1)
    local surface = offer.Home.Surface(other, OtherHeader)
    offer.Home.Draw(surface, otherLeft, otherRight)
    local function otherRow(name)
        for _, widget in ipairs(W.frames) do
            if widget._parent == other and widget.entry and widget:IsShown() and widget.entry.name == name then return widget end
        end
    end
    local wandRow, trainRow = otherRow("Conjure Wand"), nil
    for _, widget in ipairs(W.frames) do
        if widget._parent == other and widget.entry and widget:IsShown() and widget.entry.state == "trainable" then trainRow = widget end
    end
    check(surface.headers.train.otherBook and surface.headers.train:IsShown() and surface.headers.train.Text:GetText():find("trainer")
        and trainRow and at(trainRow) == otherLeft and wandRow and at(wandRow) == otherRight,
        "Home on another book: the trainer's spells on its left page under that book's heading, the quests on its right")
    offer.Home.Draw(surface, otherLeft, nil)
    check(at(otherRow("Conjure Wand")) == otherLeft, "one page shown there: both sections on it")
    W.level = 10
    ns.QueueUpdate(true, 0)
    W.Wait(1)
    ns.options.home = false
    check(offer.Home.First() == false, "whether that book opens on Home: the switch's")
    ns.options.home = true
    check(offer.Home.First() == true, "(on again)")
    -- Its entries: the module's own, a drag from one reserves, and it ends with the entry gone.
    local grey = offer.Make(other)
    offer.Set(grey, entry("Blink"), 216)
    check(grey.entry == entry("Blink") and grey:GetWidth() == 216 and grey.Name:GetText() == "Blink", "an entry of the module's own, drawn at that book's width")
    grey.Button:GetScript("OnDragStart")(grey.Button)
    check(ns.Drag.Held() == entry("Blink") and ns.Drag.Source() == grey.Button, "dragged: carried to the bars, as from the game's book")
    grey.Button:Hide()
    check(not ns.Drag.Held(), "its entry hidden (that book closed): the drag ends")
    grey:Hide()
    -- The menu's lines there: none that waits for the game's pages, none that is the game's book's alone.
    local items = {}
    offer.Menu(W.Description(items))
    local lineTexts = {}
    for _, item in ipairs(items) do lineTexts[#lineTexts + 1] = item.text or item.title or "-" end
    lineTexts = table.concat(lineTexts, "|")
    check(lineTexts:find("Show unlearned spells") and lineTexts:find("Open the spellbook on its Home page")
        and not lineTexts:find("Compact spellbook pages") and not lineTexts:find("Move and resize the spellbook")
        and lineTexts:find("Show reservations on the action bars"), "the menu's lines there: the book's that serve it, then the bars'")
    offer.Switch.Set(false)
    check(ns.options.showHidden == false and offer.Switch.On() == false, "the switch beside its pages sets Show unlearned spells")
    offer.Switch.Set(true)
    local told = 0
    Core.Spellbook.Watch(function() told = told + 1 end)
    ns.Fire("REFRESH")
    ns.Fire("REFRESH")
    W.Wait(0)
    check(told == 1, "what the module draws anew, that book is told to, once a frame")
end

-- Compact pages that follow the window's size ---------------------------------------------------
searching, activeTab = false, tabs[2]
ns.options.compact = true
paged:SetSize(1612, 652) -- the game's own open book
made = DrawTab("Arcane", many)
-- Where an entry stands in the page's own measure: an entry drawn smaller counts in its own.
local function small(frame, relativeTo, x, y) return stands(frame, relativeTo, x / 0.75, y / 0.75) end
check(made[1]:GetScale() == 0.75 and ghost("Arcane Explosion"):GetScale() == 0.75, "compact: every entry is drawn smaller")
check(small(made[1], view1, 0, -64) and small(made[11], view1, 170, -64) and small(made[40], view1, 510, -505),
    "and stands closer: four columns of ten on a page")
check(SaneUISpellbookPager.maxPages == 1 and small(ghost("Arcane Explosion"), view1, 797, 0) and small(ghost("Blink"), view1, 967, 0), "43 entries are one open book now; the right page starts right of the middle")
paged:SetSize(900, 500) -- the window dragged small
ns.Fire("REFRESH")
check(SaneUISpellbookPager.maxPages == 3 and small(made[7], view1, 0, -358) and small(made[8], view1, 441, 0) and small(made[15], view1, 441, -343),
    "a smaller window: one column of seven, then eight, to a page, and more pages")
paged.viewsPerPage = 1
ns.Fire("REFRESH")
check(SaneUISpellbookPager.maxPages == 2 and small(made[8], view1, 170, -64) and small(made[22], view1, 510, -64) and at(made[30]) == UIParent,
    "the small spellbook of that width: one page as wide as the window, four columns again")
paged.viewsPerPage = 2
ns.options.compact = false
paged:SetSize(0, 0)
ns.Fire("REFRESH")
check(made[1]:GetScale() == 1 and stands(made[1], view1, 0, -70) and at(made[40]) == view2, "switched off, the pages are the game's again")

-- Moving and sizing the window --------------------------------------------------------------------
check(not rawget(_G, "SaneUISpellbookDragBar"), "with the switch off the window is left alone")
ns.options.window = true
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
PlayerSpellsFrame:SetSize(1618, 720) -- large again, as the game sizes it
book:SetWidth(1612)
grip:GetScript("OnMouseDown")(grip)
PlayerSpellsFrame:SetSize(1000, 600)
PlayerSpellsFrame:GetScript("OnSizeChanged")(PlayerSpellsFrame)
grip:GetScript("OnMouseUp")(grip)
book:Hide() -- the spellbook is closed when the switch goes off
ns.options.window = false
ns.Fire("REFRESH")
check(not bar:IsShown() and not grip:IsShown(), "switched off, the bar and the grip go")
PlayerSpellsFrame:SetSize(1618, 720) -- the game sizes the window when it opens the spellbook, never the book in it
book:Show()
check(book:GetWidth() == 1612 and book:GetHeight() == 702, "switched off while the spellbook was closed, the book takes the game's size when it opens next")

-- Giving the pages back --------------------------------------------------------------------
W.printed = {}
searching, activeTab = false, tabs[3]
-- An entry drawn smaller (compact) that the game has taken back into its pool since: it is no longer
-- among the tab's entries, and the game draws its next tabs from that pool.
ns.options.compact = true
local pooled = DrawTab("Fire", { "Fireball", "Scorch", "Fire Blast" })[3]
ns.options.compact = false
made = DrawTab("Fire", { "Fireball", "Scorch", "Fire Blast" })
check(pooled:GetScale() == 0.75 and ghostCount() == 2 and stands(made[1], view1, 0, -70) and stands(made[3], view1, 231, -70),
    "the Fire tab once more, with its grey entries")
-- It happens in a fight, where the game locks its frames: the column, the page buttons, the row of
-- tabs, and an entry drawn small (one whose flyout was opened).
local function locked() return true end
local held = W.NewWidget("Frame", nil, view1)
held:SetScale(0.75)
paged.frames[#paged.frames + 1] = held
view1.IsProtected, nativePager.IsProtected, tabSystem.IsProtected, held.IsProtected = locked, locked, locked, locked
W.combat = true
W.gamepad = true                      -- a controller is switched on: the game pages by itself then
H.Open()                              -- Home empties the page underneath, and that redraw notices it
check(view1:GetHeight() == 60000 and not stands(nativePager, paged, -75, 40) and stands(tabSystem, book, 116, -26) and held:GetScale() == 0.75,
    "in a fight what the game locks is left as it is")
check(pooled:GetScale() == 1, "an entry the game took back into its pool after we drew it smaller gets its own size back too")
W.combat = false
view1.IsProtected, nativePager.IsProtected, tabSystem.IsProtected, held.IsProtected = nil, nil, nil, nil
W.Fire("PLAYER_REGEN_ENABLED")
check(view1:GetHeight() == 590 and stands(nativePager, paged, -75, 40) and held:GetScale() == 1,
    "when the plan cannot hold, the game's column and page buttons are given back, and every entry its own size: after the fight")
check(not SaneUISpellbook:IsShown() and printedMatch("left the spellbook's pages to the game %(a controller is in use%)"), "the addon's entries go, and it says why")
H.Open()
check(not ns.Home.IsOpen() and not SaneUISpellbookHome:IsShown() and stands(tabSystem, book, 70, -26),
    "Home goes with them, also when it was opening: it needs the pages. The row of tabs gets its place back")
check(book.SearchBox:GetWidth() == 290, "and the search box its room")
check(stands(made[3], view1, 462, -70), "what is on screen is tidied one last time: the game's entries, without the grey ones")
made = DrawTab("Fire", { "Fireball", "Scorch", "Fire Blast" })
check(stands(made[3], view1, 0, -210), "and the game's layout is left alone from then on")

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

-- Retail ------------------------------------------------------------------------------------------
-- The same code there (Abilities.lua, at the top): what you have is read without Forever's ranks and the
-- reservations work as in Forever; Forever's trainer data is not read, the spellbook's pages stay the
-- game's, and its menu, the options and the commands keep only what serves the bars.
W.Play("retail") -- and what Retail lacks of Forever's is not there (games.lua): IsSpellBookItemLowRank, for one
do
    local toc = {}
    for text in io.lines(root .. "/src/Abilities/SaneUI_Abilities.toc") do
        local file, conditions = text:match("^([%w\\]+%.lua)%s*(.*)$")
        if file and W.Allowed(conditions) then toc[file] = true end
    end
    check(toc["Data\\Trainer.lua"] and toc["Sources.lua"] and toc["Book\\Drag.lua"] and toc["Book\\Menu.lua"]
        and not (toc["Data\\Classes\\Mage.lua"] or toc["Data\\QuestSpells.lua"] or toc["Data\\WeaponSkills.lua"] or toc["Data\\SkillLines.lua"]),
        "Retail reads none of Forever's trainer data, only Trainer.lua, whose functions every file uses")

    local ICEBLOCK = 45438
    W.spells[ICEBLOCK] = { name = "Ice Block" }
    W.actions[1] = nil
    ns.QueueUpdate(true, 0)
    W.Wait(1)
    check(S.known.Fireball and S.has.Fireball and next(Core.errors) == nil, "Retail: what you have is read without the question about low ranks")
    check(E.Reserve(1, { kind = "spell", id = ICEBLOCK, name = "Ice Block" }), "Retail: a button is reserved")
    W.Wait(1)
    check(reserved(1) and not action(1) and barGhost:IsShown(), "it waits, with its grey icon on the bar")
    W.Learn(ICEBLOCK, 4)
    W.Wait(2)
    check(action(1) and action(1).id == ICEBLOCK and not reserved(1) and not barGhost:IsShown(), "and becomes the real button once learned")
    -- Retail has no ranks: a spell that comes back under another ID (a talent, a specialization) is no new rank.
    local ICEBLOCK2 = 45439
    W.spells[ICEBLOCK2] = { name = "Ice Block" }
    for _, row in ipairs(W.book) do
        if row.id == ICEBLOCK then row.id = ICEBLOCK2 end
    end
    W.Fire("SPELLS_CHANGED")
    W.Wait(1)
    check(S.known["Ice Block"] == ICEBLOCK2 and action(1).id == ICEBLOCK and not next(S.outranked), "Retail: no rank moves a button up there")
    W.actions[1] = nil

    -- Without the built-in lists of spellbook tabs (Data/SkillLines.lua) a spell still to come has no tab, and no error
    local trees, names = ns.TreeLines, ns.SkillLineOfName
    ns.TreeLines, ns.SkillLineOfName = nil, nil
    S.AddExtra(LANCE)
    check(#S.All() > 0 and not ns.off, "the list of spells to come needs none of Forever's lists to be built")
    S.RemoveExtra({ id = LANCE })
    ns.TreeLines, ns.SkillLineOfName = trees, names

    -- A spellbook read in Retail never takes the pages over (a second one: the first left them to the game further up)
    local copy = setmetatable({}, { __index = ns })
    W.Load(root, "SaneUI_Abilities", "Abilities/Book/Book", copy)
    W.Fire("ADDON_LOADED", "Blizzard_PlayerSpells")
    check(not copy.Book.Armed() and view1:GetHeight() == 590 and stands(nativePager, paged, -75, 40),
        "Retail: the spellbook's pages, its column and its page buttons stay the game's")

    lines = {}
    ns.class = "WARRIOR"
    W.menuModifiers.MENU_SPELL_BOOK_SETTINGS(nil, W.Description(lines))
    ns.class = "MAGE"
    check(lines[1].title == "Sane UI" and line("Show reservations on the action bars") and line("Action bar layouts")
        and not line("Show unlearned spells") and not line("Compact spellbook pages") and not line("Show all spell ranks")
        and not line("Move buttons up to a new rank"),
        "Retail: the spellbook's menu has the bars' lines only, also for a warrior")

    W.printed = {}
    sane("")
    check(printedMatch("/sane ab list") and printedMatch("saved layout") and not printedMatch("/sane ab add")
        and not printedMatch("pages off") and not printedMatch("window reset") and not printedMatch("in grey"),
        "Retail: /sane abilities explains what serves there")
    W.printed = {}
    local extras = #ns.DB.extras.MAGE
    sane("pages off")
    sane("window reset")
    sane("add " .. LANCE)
    check(ns.options.book == true and #ns.DB.extras.MAGE == extras and not printedMatch("after /reload")
        and not printedMatch("own size again") and printedMatch("/sane ab list"),
        "the commands for the spellbook's pages, its window and its grey spells are not there: the help instead")
    W.printed = {}
    sane("debug")
    check(printedMatch("reservations: ") and not printedMatch("still to learn") and not printedMatch("spellbook:"),
        "/sane ab debug tells the reservations only")
end
W.Play("forever")
ns.QueueUpdate(true, 0)
W.Wait(1)

-- Action Bar 1 keeps its page -----------------------------------------------------------------
-- The game's part as its own code has it: its controller writes the main bar's page, a button takes its
-- own page before its bar's, the state driver reads the conditions. The snippet itself runs for real.
local barOne = {}
do
    local function Attributes(widget)
        widget.attributes = {}
        function widget:GetAttribute(name) return self.attributes[name] end
        function widget:SetAttribute(name, value)
            self.attributes[name] = value
            local changed = self:GetScript("OnAttributeChanged")
            if changed then changed(self, name, value) end
        end
    end

    local bound = { MULTIACTIONBAR5BUTTON1 = { "1" }, MULTIACTIONBAR5BUTTON12 = { "=", "F12" }, MULTIACTIONBAR6BUTTON1 = { "SHIFT-1" } }
    local drivers, holds = {}, { ["bar:1"] = true } -- the frames driven, and the conditions that hold now
    local page, bonus, instead = 1, 0, nil          -- the page you chose, a form's number, a row of the game's own

    -- A snippet runs for real, given a handle on its frame as the game's secure code gives one: the frame's attributes,
    -- its frame references (the frames themselves, whose attributes it may set) and its keys.
    local function Run(frame, head, body, ...)
        local handle = {}
        function handle:GetAttribute(name) return frame:GetAttribute(name) end
        function handle:SetAttribute(name, value) frame:SetAttribute(name, value) end
        function handle:GetFrameRef(label) return frame.refs[label] end
        function handle:ClearBindings() wipe(frame.keys) end
        function handle:SetBinding(priority, key, command)
            assert(priority == true)
            frame.keys[key] = command
        end
        local run = assert(loadstring(head .. "\n" .. body))
        setfenv(run, { tonumber = tonumber, tostring = tostring,
                       GetBindingKey = function(command) return unpack(bound[command] or {}) end })
        run(handle, ...)
    end
    local function Secure(frame)
        Attributes(frame)
        frame.refs, frame.keys = {}, {}
        function frame:SetFrameRef(label, other) self.refs[label] = other end
    end
    -- A state's snippet on each change of that state.
    W.templates.SecureHandlerStateTemplate = function(header)
        Secure(header)
        header:SetScript("OnAttributeChanged", function(self, name, value)
            local state = name:match("^state%-(.+)")
            local body = state and self:GetAttribute("_onstate-" .. state)
            if body then Run(self, "local self, stateid, newstate = ...", body, state, value) end
        end)
    end
    -- The click's snippet on each click.
    W.templates.SecureHandlerClickTemplate = function(button)
        Secure(button)
        button:SetScript("OnClick", function(self, mouse, down)
            local body = self:GetAttribute("_onclick")
            if body then Run(self, "local self, button, down = ...", body, mouse, down) end
        end)
    end

    -- The first clause with a condition that holds, or without one.
    local function Parse(values)
        for clause in (values .. ";"):gmatch("(.-);") do
            local answer = clause:gsub("%b[]", ""):match("%S+")
            if not clause:find("[", 1, true) then return answer end
            for condition in clause:gmatch("%[(.-)%]") do
                if holds[condition] then return answer end
            end
        end
    end
    local function Drive()
        for frame, driver in pairs(drivers) do
            local value = Parse(driver.values)
            value = tonumber(value) or value
            local name = "state-" .. driver.state
            if frame:GetAttribute(name) ~= value then frame:SetAttribute(name, value) end
        end
    end
    RegisterStateDriver = function(frame, state, values)
        assert(not W.combat)
        drivers[frame] = { state = state, values = values }
        Drive()
    end
    UnregisterStateDriver = function(frame)
        assert(not W.combat)
        drivers[frame] = nil
    end

    local mainBar = W.NewWidget("Frame", "MainActionBar")
    Attributes(mainBar)
    mainBar.attributes.actionpage = 1
    local function Slot(button)
        return button.id + ((button:GetAttribute("actionpage") or mainBar:GetAttribute("actionpage")) - 1) * 12
    end
    local function Controller()
        mainBar:SetAttribute("actionpage", instead or (bonus > 0 and page == 1 and 6 + bonus) or page)
        for _, button in ipairs(barOne) do button.action = Slot(button) end
    end
    local function Turn(to)
        holds["bar:" .. page], page = nil, to
        holds["bar:" .. to] = true
        Controller()
        Drive()
    end
    local function Form(number)
        bonus = number
        Controller()
        Drive()
    end
    local function Replaced(condition, row)
        holds[condition], instead = row and true or nil, row
        Controller()
        Drive()
    end

    check(ns.options.holdPage and not ns.Bar1.Held(), "without the game's twelve buttons the bar stays the game's")
    local firstButton = ActionButton1
    for index = 1, ns.NUM_BUTTONS do
        local button = W.NewWidget("CheckButton", "ActionButton" .. index, mainBar)
        button.id = index
        Attributes(button)
        button:SetScript("OnAttributeChanged", function(self) self.action = Slot(self) end)
        button.action = index
        _G["ActionButton" .. index], barOne[index] = button, button
    end
    local header
    W.combat = true
    ns.Bar1.Apply()
    check(not ns.Bar1.Held(), "in a fight it waits")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    for _, widget in ipairs(W.frames) do
        if widget._template == "SecureHandlerStateTemplate" then header = widget end
    end
    check(ns.Bar1.Held() and header and barOne[1]:GetAttribute("actionpage") == 1 and barOne[12]:GetAttribute("actionpage") == 1,
        "after it every button holds the page you chose")

    -- A warrior's stances and a druid's forms
    for number = 1, 4 do
        Form(number)
        check(mainBar:GetAttribute("actionpage") == 6 + number, "(the game writes the form's row to the bar)")
        check(barOne[1].action == 1 and barOne[12].action == 12 and Slot(barOne[5]) == 5, "and the buttons stay: what they show is what their keys cast")
    end
    Turn(3)
    check(barOne[1].action == 25 and barOne[12].action == 36 and ns.Bar1Offset() == 24, "your pages turn in a form")
    W.combat = true
    Turn(2)
    check(barOne[1].action == 13 and barOne[12].action == 24, "also in a fight")
    W.combat = false
    Turn(1)
    check(barOne[1].action == 1, "and page 1 is page 1 in a form too")
    Turn(2)

    -- The game's own bar in the bar's place
    check(next(header.keys) == nil, "(your main keys are your own)")
    W.combat = true
    Replaced("vehicleui", 12)
    W.combat = false
    check(barOne[1].action == 133 and barOne[12].action == 144, "in a vehicle the buttons are the game's again")
    check(header.keys["1"] == "ACTIONBUTTON1" and header.keys["="] == "ACTIONBUTTON12" and header.keys.F12 == "ACTIONBUTTON12",
        "and the keys of Bar 6 press them, each key of a button")
    check(header.keys["SHIFT-1"] == nil, "Bar 7's keys stay Bar 7's")
    Replaced("vehicleui", nil)
    check(barOne[1].action == 13 and next(header.keys) == nil, "out of it the page you chose is back, and your keys")
    for _, condition in ipairs({ "overridebar", "possessbar", "shapeshift", "bonusbar:5", "petbattle" }) do
        Replaced(condition, 11)
        check(barOne[1].action == 121 and header.keys["1"] == "ACTIONBUTTON1", "the same with " .. condition)
        Replaced(condition, nil)
    end

    -- The switch
    Turn(1)
    Form(1)
    Core.Set(ns.name, "holdPage", false)
    Controller()
    check(not ns.Bar1.Held() and barOne[1]:GetAttribute("actionpage") == nil and barOne[1].action == 73 and next(header.keys) == nil,
        "switched off the bar follows the game again")
    check(not ns.Bar1.Unseen(73), "and a form's row is seen")
    Core.Set(ns.name, "holdPage", true)
    Controller()
    check(ns.Bar1.Held() and barOne[1].action == 1, "switched on it holds again, at once")
    W.combat = true
    Core.Set(ns.name, "holdPage", false)
    check(ns.Bar1.Held(), "the switch waits for the end of a fight")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    check(not ns.Bar1.Held(), "and then does as it says")
    Core.Set(ns.name, "holdPage", true)
    check(ns.Bar1.Unseen(73) and ns.Bar1.Unseen(120) and not ns.Bar1.Unseen(72) and not ns.Bar1.Unseen(121), "the four rows of the forms are out of sight")
    Form(0)

    -- A druid's Bar 6 swaps with its form (FormBar.lua): Bar 9 in Bear Form, Bar 10 in Cat, Aquatic and Travel Form.
    local six, barSix = W.NewWidget("Frame", "MultiBar5"), {}
    _G.MultiBar5 = six
    Attributes(six)
    six.attributes.actionpage = 13
    local function Slot6(button)
        return button.id + ((button:GetAttribute("actionpage") or six:GetAttribute("actionpage")) - 1) * 12
    end
    -- The conditions of a form as the game has them: every form [form], and some a row of Bar 1's ([bonusbar:n]).
    local function InForm(...)
        for _, condition in ipairs({ "form", "bonusbar:1", "bonusbar:2", "bonusbar:3", "bonusbar:4" }) do holds[condition] = nil end
        for _, condition in ipairs({ ... }) do holds[condition] = true end
        Drive()
    end
    local function Number(pager) return tostring(pager.number:GetText()) end
    local function Press(button, mouse) button:GetScript("OnClick")(button, mouse or "LeftButton", false) end
    local class = ns.class
    ns.class = "DRUID"
    ns.FormBar.Apply()
    check(not ns.FormBar.Held() and not ns.FormBar.Pager(), "without the game's twelve buttons the bar stays the game's")
    for index = 1, 12 do
        local button = W.NewWidget("CheckButton", "MultiBar5Button" .. index, six)
        Attributes(button)
        button.id = index
        button:SetScript("OnAttributeChanged", function(self) self.action = Slot6(self) end)
        button.action = Slot6(button)
        _G["MultiBar5Button" .. index], barSix[index] = button, button
    end
    check(barSix[1].action == 145 and barSix[12].action == 156, "(Bar 6 on its own slots)")
    ns.class = class
    ns.FormBar.Apply()
    InForm("form", "bonusbar:3")
    check(not ns.FormBar.Held() and barSix[1].action == 145, "another class's Bar 6 stays as it is in a form")
    InForm()

    ns.class = "DRUID"
    W.combat = true
    ns.FormBar.Apply()
    check(not ns.FormBar.Held(), "in a fight it waits")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    local pager = ns.FormBar.Pager()
    check(ns.FormBar.Held() and pager and pager:IsShown() and ns.FormBar.On() and ns.char.formBar == nil and pager.box:GetChecked(),
        "and then a druid's Bar 6 swaps with its form, ticked at first")
    check(barSix[1].action == 145 and Number(pager) == "6", "as a human the bar's own slots")
    local forms = {
        { "Bear Form", { "form", "bonusbar:3" }, 97, "9" },
        { "Cat Form", { "form", "bonusbar:1" }, 109, "10" },
        { "Prowl, a row of its own in Retail", { "form", "bonusbar:2" }, 109, "10" },
        { "Aquatic and Travel Form", { "form" }, 109, "10" },
        { "Moonkin Form", { "form", "bonusbar:4" }, 145, "6" },
    }
    for _, form in ipairs(forms) do
        InForm(unpack(form[2]))
        check(barSix[1].action == form[3] and barSix[12].action == form[3] + 11 and Number(pager) == form[4], form[1] .. ": its bar")
        check(barOne[1].action == 1, "and Bar 1 keeps its page")
    end
    InForm()
    check(barSix[1].action == 145 and Number(pager) == "6", "a human has Bar 6 again")
    check(ns.SlotLabel(97) == "Bar 9, button 1" and ns.SlotLabel(120) == "Bar 10, button 12", "Bars 9 and 10 by their numbers")
    check(not ns.Bar1.Unseen(97) and not ns.Bar1.Unseen(120) and ns.Bar1.Unseen(73) and ns.Bar1.Unseen(96),
        "Bars 9 and 10 are seen, the other forms' rows not")

    -- The arrows turn the bar without a change of form, in a fight too; the next change of form swaps it again.
    W.combat = true
    InForm("form", "bonusbar:3")
    check(barSix[1].action == 97, "a form swaps it in a fight too")
    Press(pager.up)
    check(barSix[1].action == 109 and Number(pager) == "10", "the arrow up shows the next bar, in a fight too")
    Press(pager.up)
    check(barSix[1].action == 145 and Number(pager) == "6", "past the last, the first again")
    Press(pager.down)
    check(barSix[1].action == 109 and Number(pager) == "10", "the arrow down the one before")
    InForm("form", "bonusbar:1")
    InForm("form", "bonusbar:3")
    check(barSix[1].action == 97, "the next change of form swaps it again")
    W.printed = {}
    pager.box:SetChecked(false)
    Press(pager.box)
    check(pager.box:GetChecked() and ns.FormBar.On() and printedMatch("after the fight"), "in a fight the checkbox waits")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")

    -- Not ticked, the bar stays on the one its arrows show.
    pager.box:SetChecked(false)
    Press(pager.box)
    check(not ns.FormBar.On() and ns.char.formBar == false, "unticked")
    InForm("form", "bonusbar:1")
    check(barSix[1].action == 97 and Number(pager) == "9", "a change of form leaves the bar as it is")
    Press(pager.down)
    check(barSix[1].action == 145, "and the arrows still turn it")
    pager.box:SetChecked(true)
    Press(pager.box)
    check(ns.FormBar.On() and ns.char.formBar == nil and barSix[1].action == 109 and Number(pager) == "10",
        "ticked again, it takes the form's bar at once")
    InForm()

    -- /sane ab formbar, and the line in the spellbook's menu
    sane("formbar off")
    check(not ns.FormBar.On() and not pager.box:GetChecked() and printedMatch("stays on the bar its arrows show"), "by the command")
    sane("formbar on")
    check(ns.FormBar.On() and pager.box:GetChecked() and printedMatch("swaps with its form"), "and on")
    sane("formbar")
    check(printedMatch("/sane ab formbar on"), "the command's words")

    -- A module stood down leaves the bar to the game; the checkbox stays.
    InForm("form", "bonusbar:3")
    ns.off = true
    ns.FormBar.Apply()
    check(not ns.FormBar.Held() and barSix[1]:GetAttribute("actionpage") == nil and barSix[1].action == 145
        and not pager:IsShown() and ns.FormBar.On(), "standing down gives the bar back")
    check(ns.Bar1.Unseen(97), "and Bar 9 is out of sight again")
    ns.off = nil
    ns.FormBar.Apply()
    check(ns.FormBar.Held() and barSix[1].action == 97 and pager:IsShown(), "back with the module, in the form's bar at once")
    InForm()
    ns.class = class
    ns.FormBar.Apply()
    check(not ns.FormBar.Held() and barSix[1].action == 145 and not pager:IsShown(), "a character of another class: a plain Bar 6")
    W.printed = {}
    sane("formbar on")
    check(printedMatch("only a druid's"), "and the command says so")
    for index = 1, 12 do _G["MultiBar5Button" .. index] = nil end
    _G.MultiBar5 = nil

    -- Every page is yours: page 2 in layouts and reservations, the bars that are off seen as pages
    check(ns.SlotLabel(13) == "Bar 1 (page 2), button 1" and ns.SlotLabel(24) == "Bar 1 (page 2), button 12", "page 2 has a name")
    check(ns.SlotLabel(145) == "Bar 6, button 1" and ns.SlotLabel(180) == "Bar 8, button 12", "bars 6 to 8 stand as themselves")
    ns.DB.pageNames.MAGE = { [72] = "Bear Form", [84] = {} }
    check(ns.SlotLabel(73) == "Bar 1 (Bear Form), button 1" and ns.SlotLabel(85) == "Bar 1 (form or stance 2), button 1",
        "a form's row by the name noted for it; a name of another kind in the saved settings is none")
    ns.DB.pageNames.MAGE = nil
    local sideBar = W.NewWidget("Frame", "MultiBarRight")
    local sideFrame = W.NewWidget("Frame", "MultiBarRightButtonContainer1", sideBar)
    local sideButton = MultiBarRightButton1
    MultiBarRightButton1 = W.NewWidget("CheckButton", "MultiBarRightButton1", sideFrame)
    check(ns.SlotLabel(25) == "Bar 4, button 1", "a bar that is on is a bar")
    sideBar:Hide()
    check(ns.SlotLabel(25) == "Bar 1 (page 3), button 1", "a bar that is off is a page of Bar 1, though the small frame its button stands in is not hidden itself")
    MultiBarRightButton1 = sideButton
    local seen = {}
    for _, slot in ipairs(ns.ManagedSlots()) do
        check(not seen[slot], "no slot twice")
        seen[slot] = true
    end
    check(#ns.ManagedSlots() == 156 and seen[13] and seen[24] and seen[145] and seen[180] and seen[120] and not seen[121], "the eight bars, page 2 and the forms' rows")
    W.actions[13] = { kind = "spell", id = FIREBALL2 }
    check(ns.Presets.Save("Pages") and ns.DB.presets.MAGE.Pages.slots[13], "a layout keeps page 2")
    W.actions[13] = nil
    check(ns.Presets.Load("Pages"), "(loaded)")
    W.Wait(1)
    check(action(13) and action(13).id == FIREBALL2, "and puts it back")
    ns.DB.presets.MAGE.Pages = nil
    E.Clear(13)
    W.Wait(1)

    -- Ghosts on page 2 and on the bars with no page
    local sixthBar = W.NewWidget("Frame", "MultiBar5")
    local sixth = W.NewWidget("CheckButton", "MultiBar5Button1", sixthBar)
    sixth.action = 145
    MultiBar5Button1 = sixth
    Turn(2)
    E.Reserve(13, entry("Blink"))
    E.Reserve(145, entry("Polymorph") or entry("Blink"))
    W.Wait(1)
    ns.Buttons.All(true)
    ns.Fire("REFRESH")
    local onPage, onSixth
    for _, widget in ipairs(W.frames) do
        if widget.entry and widget.fallback ~= nil and widget:IsShown() then
            if widget.action == 13 then onPage = widget end
            if widget.action == 145 then onSixth = widget end
        end
    end
    check(onPage and onSixth, "a reservation shows on page 2 and on Bar 6")
    check(not action(13) and reserved(13) and reserved(145), "and waits there")
    E.Clear(13)
    E.Clear(145)
    MultiBar5Button1 = nil
    Turn(1)
    W.Wait(1)

    -- The game drops a new spell on a form's row that never shows now
    W.spells[6100] = { name = "Quick Step" }
    W.book[#W.book + 1] = { id = 6100, line = 2 }
    W.actions[73] = { kind = "spell", id = 6100 }
    W.Fire("SPELL_PUSHED_TO_ACTIONBAR", 6100, 73, 1)
    W.Fire("SPELLS_CHANGED")
    W.Wait(3)
    local landed
    for slot = 1, ns.NUM_BUTTONS do
        if action(slot) and action(slot).id == 6100 then landed = slot end
    end
    check(not action(73) and landed, "a spell the game drops on a form's row comes to a button you can see")
    W.actions[landed] = nil
    Core.Set(ns.name, "holdPage", false)
    W.actions[73] = { kind = "spell", id = 6100 }
    W.Fire("SPELL_PUSHED_TO_ACTIONBAR", 6100, 73, 1)
    W.Fire("SPELLS_CHANGED")
    W.Wait(3)
    check(action(73), "with the switch off that row is seen and it stays")
    W.actions[73] = nil
    Core.Set(ns.name, "holdPage", true)
    -- Turned to page 2, the button you can see is one of page 2
    Turn(2)
    W.actions[73] = { kind = "spell", id = 6100 }
    W.Fire("SPELL_PUSHED_TO_ACTIONBAR", 6100, 73, 1)
    W.Fire("SPELLS_CHANGED")
    W.Wait(3)
    landed = nil
    for slot = 1, 2 * ns.NUM_BUTTONS do
        if action(slot) and action(slot).id == 6100 then landed = slot end
    end
    check(not action(73) and landed and landed > ns.NUM_BUTTONS, "turned to page 2, it comes to a free button of that page: the row you see")
    W.actions[landed] = nil
    Turn(1)

    for index = 1, ns.NUM_BUTTONS do _G["ActionButton" .. index] = nil end
    ActionButton1 = firstButton
    W.Wait(1)
end

-- The buttons of every action bar touch --------------------------------------------------------
-- A bar as the game makes it: a small frame for each button, the grid moving those frames (place: as its grid does,
-- in the scale of the button), the button in the middle of its frame.
local tightBar
do
    local WIDTH = 45
    local function Grid(name, count, fields)
        local bar = W.NewWidget("Frame", name)
        bar.actionButtons, bar.shownButtonContainers, bar.numRows = {}, {}, 1
        bar.minButtonPadding, bar.buttonPadding, bar.isHorizontal, bar.addButtonsToRight, bar.addButtonsToTop = 2, 2, true, true, true
        for key, value in pairs(fields or {}) do bar[key] = value end
        function bar:UpdateGridLayout() end
        -- Edit Mode on the bar: its SetPoint writes the game's fields and runs its manager (never ours to call), the
        -- frame's own is SetPointBase; the layout takes the place a bar stands at, and gives a bar the layout's.
        bar.SetPointBase = bar.SetPoint
        bar.SetPoint = function() error("Edit Mode's SetPoint, from our code") end
        function bar:OnSystemPositionChange()
            local point, to, relative, x, y = self:GetPoint(1)
            local scale = self:GetScale()
            self.systemInfo = { anchorInfo = { point = point, relativeTo = to._name, relativePoint = relative,
                offsetX = x * scale, offsetY = y * scale } }
        end
        function bar:ApplySystemAnchor()
            local anchor, scale = self.systemInfo.anchorInfo, self:GetScale()
            self:ClearAllPoints()
            self:SetPointBase(anchor.point, _G[anchor.relativeTo], anchor.relativePoint, anchor.offsetX / scale, anchor.offsetY / scale)
        end
        for index = 1, count do
            local frame = W.NewWidget("Frame", name .. "ButtonContainer" .. index, bar)
            local button = W.NewWidget("CheckButton", name .. "Button" .. index, frame)
            button:SetPoint("CENTER")
            button.container = frame
            button._protected = true -- the game's buttons are secure frames: in a fight the stand-in refuses to move one, as the game blocks it
            bar.actionButtons[index], bar.shownButtonContainers[index] = button, frame
        end
        _G[name] = bar
        return bar
    end
    -- Where the game has a shown frame, then where our button stands.
    local function FramePlace(bar, at)
        local stride = math.ceil(#bar.shownButtonContainers / bar.numRows)
        local along, across = (at - 1) % stride, math.floor((at - 1) / stride)
        local step = WIDTH + math.max(bar.minButtonPadding, bar.buttonPadding)
        local right, up = bar.addButtonsToRight and 1 or -1, bar.addButtonsToTop and 1 or -1
        if bar.isHorizontal then return along * step * right, across * step * up end
        return across * step * right, along * step * up
    end
    local function Place(bar, at)
        local x, y = FramePlace(bar, at)
        local _, frame, _, ox, oy = bar.actionButtons[at]:GetPoint(1)
        assert(frame == bar.shownButtonContainers[at] and bar.actionButtons[at]:GetNumPoints() == 1)
        return x + ox, y + oy
    end
    local function Touching(bar, first, second)
        local ax, ay = Place(bar, first)
        local bx, by = Place(bar, second)
        return math.abs(math.abs(ax - bx) + math.abs(ay - by) - WIDTH) < 0.001 and (ax == bx or ay == by)
    end
    local function Row(bar, from, to, step)
        for at = from, to - step, step do
            if not Touching(bar, at, at + step) then return false end
        end
        return true
    end

    check(ns.options.tightBars, "the buttons touch from the start")
    local main = Grid("MainActionBar", 12)
    tightBar = main
    local sixth = Grid("MultiBar5", 12, { buttonPadding = 7 })
    local right = Grid("MultiBarRight", 12, { isHorizontal = false, addButtonsToTop = false })
    local two = Grid("MultiBarBottomLeft", 12, { numRows = 2 })
    local left = Grid("MultiBarBottomRight", 12, { addButtonsToRight = false })
    local stance = Grid("StanceBar", 10)
    for _, spare in ipairs({ 9, 10 }) do stance.shownButtonContainers[spare] = nil end -- a bar without spacers: two forms fewer
    W.combat = true
    ns.Spacing.Apply()
    check(select(4, main.actionButtons[1]:GetPoint(1)) == 0, "in a fight no button moves")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    check(Row(main, 1, 12, 1), "after it every button of a row touches the next")
    check(Row(sixth, 1, 12, 1), "whatever the padding Edit Mode has")
    check(Row(right, 1, 12, 1), "a vertical bar too")
    check(Row(left, 1, 12, 1), "and a bar that grows to the left")
    check(Row(stance, 1, 8, 1), "the stance bar, with the forms you have")
    check(select(4, stance.actionButtons[9]:GetPoint(1)) == 0, "a button on no line stands in its frame")
    check(Row(two, 1, 6, 1) and Row(two, 7, 12, 1) and Touching(two, 1, 7) and Touching(two, 6, 12), "the rows of a bar touch each other")
    -- The bar stays where it is: the row closes towards its middle, so the place of the bar is the place of the row.
    local fx, fy = FramePlace(main, 1)
    local lx = FramePlace(main, 12)
    local bx1, by1 = Place(main, 1)
    local bx2 = Place(main, 12)
    check(math.abs((bx1 + bx2) - (fx + lx)) < 0.001 and by1 == fy, "the row stays in the middle of its bar")
    check(ns.Bar1Offset() == 0 and main.actionButtons[1]:GetParent() == main.shownButtonContainers[1], "(the button stays in its own frame)")

    -- The game lays a bar out anew: Edit Mode's padding, its orientation
    main.buttonPadding = 6
    main:UpdateGridLayout()
    check(Row(main, 1, 12, 1), "a new padding closes as well")
    main.isHorizontal, main.addButtonsToTop = false, false
    main:UpdateGridLayout()
    check(Row(main, 1, 12, 1), "and a new orientation")
    main.isHorizontal, main.addButtonsToTop, main.buttonPadding = true, true, 2
    W.combat = true
    main:UpdateGridLayout()
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    check(Row(main, 1, 12, 1), "laid out in a fight, it follows after the fight")
    -- By the stand-in's own fight (the game's two events): a protected button moved in it would be an error here, and
    -- the module stood down; a padding changed in a fight is owed until the fight's end
    W.Combat(true)
    main.buttonPadding = 8
    main:UpdateGridLayout()
    local owed, moved = Core.Owed("Abilities: spacing"), Row(main, 1, 12, 1)
    W.Combat(false)
    check(owed and not moved and not ns.off and Row(main, 1, 12, 1), "a padding changed in a fight is owed, no protected button touched; the fight's end pays it")
    main.buttonPadding = 2
    main:UpdateGridLayout()

    -- The switch
    Core.Set(ns.name, "tightBars", false)
    check(select(4, main.actionButtons[12]:GetPoint(1)) == 0 and select(5, two.actionButtons[1]:GetPoint(1)) == 0, "switched off every button is back in the middle of its frame")
    main.buttonPadding = 4
    main:UpdateGridLayout()
    check(select(4, main.actionButtons[1]:GetPoint(1)) == 0, "and the game's padding counts again")
    main.buttonPadding = 2
    Core.Set(ns.name, "tightBars", true)
    check(Row(main, 1, 12, 1), "switched on they touch again")
    local _, frame = main.actionButtons[3]:GetPoint(1)
    check(frame == main.shownButtonContainers[3], "(in their own frames)")

    -- Bars snapped together touch. The game's snap puts the bar 4 away (a padding of 2 around each box), then the
    -- layout takes that place.
    local function Snap(bar, point, other, relative, x, y)
        bar:ClearAllPoints()
        bar:SetPointBase(point, other, relative, x, y)
        bar:OnSystemPositionChange()
    end
    local function Stands(bar, x, y)
        local _, _, _, nowX, nowY = bar:GetPoint(1)
        return math.abs(nowX - x) < 0.001 and math.abs(nowY - y) < 0.001
    end
    sixth.buttonPadding = 2
    sixth:UpdateGridLayout()
    main:SetPointBase("BOTTOM", UIParent, "BOTTOM", 0, 40)
    main:OnSystemPositionChange()
    check(Stands(main, 0, 40), "a bar on the screen stands as the game put it")
    Snap(sixth, "BOTTOM", main, "TOP", 0, 4)
    check(Stands(sixth, 0, 0), "a bar snapped on top of another touches it")
    check(sixth.systemInfo.anchorInfo.offsetY == 4, "and the layout keeps the game's place")
    Snap(left, "BOTTOMLEFT", sixth, "TOPLEFT", 0, 4)
    check(Stands(left, 0, 0), "a third, snapped by the corner, stands on the second")
    Snap(two, "BOTTOM", left, "TOP", 0, 4)
    check(Stands(two, 0, -1), "a bar of two rows comes down by what its closed rows left in its box")
    Snap(right, "TOP", two, "BOTTOM", 0, -4)
    check(Stands(right, 0, 12), "a vertical bar under it comes up by what its closed column left too")
    Snap(stance, "LEFT", main, "RIGHT", 4, 0)
    check(Stands(stance, -18, 0), "side by side the closed rows of both meet")
    Snap(stance, "BOTTOMLEFT", main, "TOPLEFT", 0, 4)
    check(Stands(stance, 4, 0), "by the corner, the first buttons of a short and a long bar stand in line")
    for _, small in ipairs(sixth.shownButtonContainers) do small:SetScale(1.5) end
    Snap(sixth, "LEFT", main, "RIGHT", 4, 0)
    check(Stands(sixth, -27.5, 0), "the icon size counts")
    sixth:SetScale(0.5)
    Snap(sixth, "LEFT", main, "RIGHT", 8, 0)
    check(Stands(sixth, -38.5, 0), "and a bar's own scale")
    sixth:SetScale(1)
    Snap(sixth, "BOTTOM", main, "TOP", 0, 4)
    for _, small in ipairs(sixth.shownButtonContainers) do small:SetScale(1) end
    Snap(stance, "LEFT", main, "RIGHT", 4, 0)
    main.buttonPadding = 6
    main:UpdateGridLayout()
    check(Stands(stance, -40, 0), "a new padding of the bar it stands against counts at once")
    main.buttonPadding = 2
    main:UpdateGridLayout()
    check(Stands(stance, -18, 0), "(and back)")

    sixth:ClearAllPoints()
    sixth:SetPointBase("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
    ns.Spacing.Apply()
    check(Stands(sixth, 10, -10), "a bar in the mouse's hands stays there")
    sixth:ApplySystemAnchor()
    check(Stands(sixth, 0, 0), "a layout given to the bars again (a login, Revert) touches again")
    sixth.systemInfo.isInDefaultPosition = true
    sixth:ApplySystemAnchor()
    check(Stands(sixth, 0, 4), "a bar in the game's own place is the game's")
    sixth.systemInfo.isInDefaultPosition = nil
    sixth:OnSystemPositionChange()
    check(Stands(sixth, 0, 0), "(a place of its own again)")
    Snap(sixth, "BOTTOM", UIParent, "BOTTOM", 0, 90)
    check(Stands(sixth, 0, 90), "snapped to the screen it keeps what the game gave it")
    Snap(sixth, "BOTTOM", main, "TOP", 0, 4)

    sixth._protected = true
    W.Combat(true)
    ns.Spacing.Apply()
    local waits = Core.Owed("Abilities: spacing")
    W.Combat(false)
    sixth._protected = nil
    check(waits and not ns.off and Stands(sixth, 0, 0), "in a fight no bar moves: the fight's end pays it")

    Core.Set(ns.name, "tightBars", false)
    check(Stands(sixth, 0, 4) and Stands(two, 0, 4) and Stands(right, 0, -4) and Stands(stance, 4, 0),
        "switched off every bar stands as the game has it")
    Core.Set(ns.name, "tightBars", true)
    check(Stands(sixth, 0, 0) and Stands(two, 0, -1) and Stands(right, 0, 12) and Stands(stance, -18, 0), "switched on they touch again")
    for _, name in ipairs({ "MultiBar5", "MultiBarRight", "MultiBarBottomLeft", "MultiBarBottomRight", "StanceBar" }) do _G[name] = nil end
end

-- Errors are caught and kept (core.lua); none happened in everything above ----------------
for label, problem in pairs(Core.errors) do io.stderr:write(label .. ": " .. problem.text .. "\n") end
check(next(Core.errors) == nil, "no step of the module raised an error")
ns.Safe("test", function() error("boom") end)
check(SaneUIDB.errors["Abilities: test"].text:find("boom"), "one that does is kept under the module's name")

-- An error at one of its doors (a timer, a script) stands the module down: the game's own is back
W.actions[1] = nil
E.Reserve(1, entry("Blink"))
ns.Fire("REFRESH")
check(barGhost:IsShown(), "(a ghost on the bars)")
W.trainerFilter.unavailable = false
W.trainer = { { kind = "available", name = "Frost Nova", icon = 301, level = 10, sub = "Rank 1", category = "Frost", id = FROSTNOVA, cost = 400 } }
W.Fire("TRAINER_SHOW")
ns.Drag.Start(entry("Blink"))
local carried, gold -- the icon that follows the mouse, and the gold frame on the button under it
for _, widget in ipairs(W.frames) do
    if widget._parent == UIParent and widget.icon and widget:GetScript("OnUpdate") then carried = widget end
    if widget.glow then gold = widget end
end
GetCursorPosition = function() return 120, 130 end -- over the hidden button of the bar further up
carried:GetScript("OnUpdate")(carried)
GetCursorPosition = cursorAt
check(W.trainerFilter.unavailable == true and ns.Drag.Held() and gold:IsShown(),
    "(a class trainer's window, its hidden rows switched on to be read; a grey spell carried, its gold frame on a button)")
-- A step of giving back that fails (the first one, the ghosts', here, after it took them off) keeps none
-- of the others: the carried spell, the trainer's filter and the spellbook are given back all the same.
-- (The pages went back to the game further up already: whether the book's step ran is noted here.)
local hideGhosts, standDown, bookGiven = ns.Ghosts.Hide, ns.Book.StandDown, false
ns.Ghosts.Hide = function(...)
    hideGhosts(...)
    error("the ghosts could not give everything back")
end
ns.Book.StandDown = function(...)
    bookGiven = true
    return standDown(...)
end
W.printed, W.caught = {}, {}
ns.Guard(function() error("a script broke") end)()
ns.Ghosts.Hide, ns.Book.StandDown = hideGhosts, standDown
check(#W.caught == 1, "(the game's error window gets it too: the stand-in shows Lua errors)")
W.caught = nil
check(ns.off and not ns.Book.Armed() and not barGhost:IsShown(), "an error no step caught leaves the spellbook to the game and takes the ghosts off the bars")
check(Core.Spellbook.Offer() == nil, "and Combat's spellbook to the game's spells alone: no offer while the module is off")
check(bookGiven and not ns.Drag.Held() and not carried:IsShown() and not gold:IsShown() and W.trainerFilter.unavailable == false
    and printedMatch("problem in Abilities: giving back"),
    "also when one step of giving back fails: the carried spell is let go (its gold frame too), the trainer's filter put back, the book given back")
W.Fire("TRAINER_SHOW")
W.Wait(1)
check(W.trainerFilter.unavailable == false, "and from then on the trainer's window is the game's alone")
W.trainer = nil
check(Core.errors["Abilities: " .. ns.GIVEN_BACK] and printedMatch("problem in Abilities: " .. ns.GIVEN_BACK), "it is kept and told")
ns.QueueUpdate(true, 0)
W.Wait(1)
ns.Fire("REFRESH")
check(not barGhost:IsShown() and ns.char.reserved[1], "nothing shows them again; the reservations are kept for the next session")
check(not ns.Bar1.Held() and barOne[1]:GetAttribute("actionpage") == nil, "and Bar 1 follows the game again")
check(select(4, tightBar.actionButtons[1]:GetPoint(1)) == 0 and select(4, tightBar.actionButtons[12]:GetPoint(1)) == 0, "and the buttons are back in the middle of their frames")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Abilities: all %d checks passed.\n"):format(passed))
