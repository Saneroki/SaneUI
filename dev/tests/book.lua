-- Runs Combat's own spellbook (src/Combat/Book/) against the stand-in client (wowstub.lua): the game's rules for
-- where each entry stands on the pages (Layout.lua), the tabs and what each shows as the game's book filters it,
-- the search (Data.lua), the book's pages, tabs, paging and settings (Book.lua), an entry as the game draws it
-- (Item.lua), and the game's secure buttons that cast out of a fight only (Casts.lua). The look can only be
-- judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/book.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
require("combatclient").Install(W) -- what the module's unit frames and action bars need of the client

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the book needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetLeft() return self._left or 0 end
function methods:GetTop() return self._top or 0 end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:SetTexture(texture) self._texture = texture return true end
function methods:SetDesaturated(on) self._desaturated = on end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetScale(scale) self._scale = scale end
function methods:Clear() self._cooldown = nil end
function methods:SetCooldownFromDurationObject(duration) self._cooldown = duration end
function methods:SetCooldown(start, duration) self._cooldown = { start, duration } end
local function noop() end
function methods:CreateAnimationGroup()
    local group = { playing = false }
    function group:Play() self.playing = true end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetLooping, group.SetToFinalAlpha, group.SetScript = noop, noop, noop
    function group:CreateAnimation()
        return setmetatable({}, { __index = function() return noop end })
    end
    return group
end

-- The game's paging controls (Blizzard_PagedContent): a page of so many, asking their frame to show it.
W.templates.PagingControlsHorizontalTemplate = function(controls)
    controls.PageText = W.NewWidget("FontString", nil, controls)
    controls.currentPage, controls.maxPages = 1, 1
    function controls:GetCurrentPage() return self.currentPage end
    function controls:SetMaxPages(count) self.maxPages = math.max(count, 1) end
    function controls:UpdateControls() end
    function controls:SetCurrentPage(page)
        page = math.max(1, math.min(page, self.maxPages))
        if page == self.currentPage then return false end
        self.currentPage = page
        self:GetParent():OnPageChanged()
        return true
    end
    function controls:OnMouseWheel(delta) self:SetCurrentPage(self.currentPage + (delta > 0 and -1 or 1)) end
end

-- The spellbook as the game gives it: skill lines, their slots, each slot's spell.
Enum.SpellBookSpellBank = { Player = 0, Pet = 1 }
Enum.SpellBookItemType = { None = 0, Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 }
Enum.SpellBookSkillLineIndex = { General = 1, Class = 2 }
local lines = {
    { name = "General", iconID = 100, itemIndexOffset = 0, numSpellBookItems = 2 },
    { name = "Frost", iconID = 200, itemIndexOffset = 2, numSpellBookItems = 5 },
    { name = "Fishing", iconID = 300, itemIndexOffset = 7, numSpellBookItems = 1, shouldHide = true },
}
local spells = {
    [0] = {}, [1] = {},
}
local function Spell(bank, slot, info) spells[bank][slot] = info end
Spell(0, 1, { name = "Attack", spellID = 6603, actionID = 6603, iconID = 1, itemType = 1 })
Spell(0, 2, { name = "Dodge", spellID = 81, actionID = 81, iconID = 2, itemType = 1, isPassive = true })
Spell(0, 3, { name = "Frostbolt", subName = "Rank 2", spellID = 205, actionID = 116, iconID = 3, itemType = 1 })
Spell(0, 4, { name = "Frostbolt", subName = "Rank 1", spellID = 116, actionID = 116, iconID = 3, itemType = 1, lowRank = true })
Spell(0, 5, { name = "Frost Nova", spellID = 122, actionID = 122, iconID = 4, itemType = 1 })
Spell(0, 6, { name = "Blizzard", spellID = 10, actionID = 10, iconID = 5, itemType = 2, level = 20 })
Spell(0, 7, { name = "Portals", actionID = 9, iconID = 6, itemType = 4 })
Spell(1, 1, { name = "Bite", spellID = 17253, actionID = 17253, iconID = 7, itemType = 3 })
local level, petSpells, onBars = 12, 0, { [116] = true, [122] = true }
local picked
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return #lines end,
    GetSpellBookSkillLineInfo = function(index) return lines[index] end,
    GetClassSkillLineInfo = function() return { iconID = 999 } end,
    GetSpellBookItemInfo = function(slot, bank) return spells[bank][slot] end,
    GetSpellBookItemType = function(slot, bank) local info = spells[bank][slot] return info and info.itemType end,
    IsSpellBookItemPassive = function(slot, bank) return spells[bank][slot].isPassive or false end,
    IsSpellBookItemLowRank = function(slot, bank) return spells[bank][slot].lowRank or false end,
    GetSpellBookItemLevelLearned = function(slot, bank) return spells[bank][slot].level end,
    HasPetSpells = function() return petSpells > 0 and petSpells or nil end,
    GetSpellBookItemAutoCast = function(slot, bank) return bank == 1, bank == 1 end,
    PickupSpellBookItem = function(slot, bank) picked = { slot, bank } end,
    GetSpellBookItemCooldownDuration = function(slot) return slot == 5 and "nova's cooldown" or nil end,
    GetSpellBookItemCooldown = function() return nil end,
    IsSpellBookItemLooseFlyoutMember = function() return false end, -- Forever's: the book our own is made after
}
PetHasSpellbook = function() return true end
GetPetIcon = function() return 500 end
ActionButtonUtil = {
    ActionBarActionStatus = { NotMissing = 1, MissingFromAllBars = 2 },
    GetActionBarStatusForSpell = function(actionID) return onBars[actionID] and 1 or 2 end,
    GetActionBarStatusForPetAction = function() return 1 end,
}
UnitLevel = function() return level end
IsModifiedClick = function(kind) return W.modified == kind end
W.cvars.spellBookHidePassives, W.cvars.ShowAllSpellRanks = "0", "0"
SetCVar = function(name, value) W.cvars[name] = tostring(value) end

-- The game's override bindings (Keys.lua): kept per owner, to look at.
W.overrides = {}
ClearOverrideBindings = function(owner) W.overrides[owner] = nil end
SetOverrideBinding = function(owner, _, key, command)
    W.overrides[owner] = W.overrides[owner] or {}
    W.overrides[owner][key] = command
end
GetBindingKey = function(action) return action == "TOGGLESPELLBOOK" and "P" or nil end

W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
local Core = SaneUI.Core
local Layout, Data, Item, Casts, Book = ns.BookLayout, ns.BookData, ns.BookItem, ns.BookCasts, ns.Book

-------------------------------------------------------------------------------
--  The game's rules for the pages
-------------------------------------------------------------------------------
local function Columns(count)
    local elements = {}
    for index = 1, count do elements[index] = index end
    local view = Layout.Split({ { elements = elements } })[1]
    local per = { 0, 0, 0 }
    for _, item in ipairs(view) do per[item.column] = per[item.column] + 1 end
    return table.concat(per, " ")
end
-- The game's own table (Blizzard_PagedCondensedGridContentFrame.lua): column by column, in as few rows as needed.
check(Columns(1) == "1 0 0" and Columns(2) == "1 1 0" and Columns(4) == "2 2 0" and Columns(5) == "2 2 1"
    and Columns(7) == "3 3 1" and Columns(10) == "4 4 2" and Columns(13) == "5 5 3",
    "a group fills its columns as the game's book does")
local views = Layout.Split({ { header = { text = "A" }, elements = { 1, 2, 3, 4, 5 } }, { header = { text = "B" }, elements = { 6 } } })
check(#views == 1 and views[1][1].kind == "header" and views[1][2].row == 2 and views[1][4].column == 2
    and views[1][7].kind == "spacer" and views[1][8].kind == "header", "two groups on one page: headings, entries, the gap between")
Layout.Place(views[1])
check(views[1][1].width == Layout.WIDTH and views[1][2].y == Layout.HEADER + Layout.Y_PAD
    and math.abs(views[1][4].x - ((Layout.WIDTH - 2 * Layout.X_PAD) / 3 + Layout.X_PAD)) < 1e-6,
    "headings take the view's width; entries share it in three columns")
local many = {}
for index = 1, 30 do many[index] = index end
views = Layout.Split({ { header = { text = "A" }, elements = many } })
-- 590 high: a heading (70) and seven rows (70 each) fit, so 21 entries; the other 9 on the next view, in 3 rows.
check(#views == 2 and #views[1] == 22 and #views[2] == 9 and views[2][1].row == 1 and views[2][3].column == 1
    and views[2][4].column == 2, "a group too long for a view goes on in the next, its rows counted anew")
views = Layout.Split({ { elements = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 } },
                       { header = { text = "B" }, elements = { 25 } } })
check(views[2][1].kind == "header", "a heading never stands alone at a view's foot")

-------------------------------------------------------------------------------
--  The tabs and what they show
-------------------------------------------------------------------------------
local tabs = Data.Tabs()
check(#tabs == 2 and tabs[1].icon == 999 and tabs[1].name == "General" and tabs[2].name == "Frost" and tabs[2].first == 3
    and tabs[2].count == 5, "a tab per skill line the game shows, the General tab with the class's icon")
local frost = Data.Groups(tabs[2])[1]
check(frost.header.text == "Frost" and #frost.elements == 3 and frost.elements[1].slot == 3 and frost.elements[3].slot == 6,
    "the game's filter: the highest rank only, no flyout's own entry")
W.cvars.ShowAllSpellRanks = "1"
check(#Data.Groups(tabs[2])[1].elements == 4, "all ranks while the game's option shows them")
W.cvars.ShowAllSpellRanks = "0"
W.cvars.spellBookHidePassives = "1"
check(#Data.Groups(tabs[1])[1].elements == 1, "no passives while the game's option hides them")
W.cvars.spellBookHidePassives = "0"
petSpells = 1
tabs = Data.Tabs()
check(#tabs == 3 and tabs[3].key == "pet" and tabs[3].icon == 500 and tabs[3].bank == 1, "the pet's tab while the pet has a spellbook")
local found = Data.Search(tabs, "frost")
check(#found == 1 and found[1].header.text == "Frost" and #found[1].elements == 3, "a search finds by name in every tab, low ranks too")
check(#Data.Search(tabs, "rank 2")[1].elements == 1, "and by rank")

-------------------------------------------------------------------------------
--  The book
-------------------------------------------------------------------------------
local Part = Book.Part
local panel = { body = W.NewWidget("Frame", nil, UIParent) }
panel.body._strata, panel.body._level = "HIGH", 510
Part.Build(panel)
Part.Size(1900, 900)
local holder
for _, widget in ipairs(W.frames) do if widget._parent == panel.body and rawget(widget, "Halved") then holder = widget end end
check(holder and holder._width == Book.WIDE and holder._scale == 1 and holder.Left:IsShown() and not holder.Halved:IsShown(),
    "a wide panel: both pages at the game's size")
Part.Size(900, 702)
check(holder._width == Book.NARROW and holder.Halved:IsShown() and not holder.Left:IsShown(), "a narrow one: one page, as the game's book minimized")
Part.Size(1900, 900)
Part.Show(true)

local function Entries()
    local list = {}
    for _, widget in ipairs(W.frames) do
        if rawget(widget, "TextContainer") and rawget(widget, "entry") and widget:IsShown() then list[#list + 1] = widget end
    end
    return list
end
local function Tabs()
    local list = {}
    for _, widget in ipairs(W.frames) do
        if rawget(widget, "Lit") and widget:IsShown() then list[#list + 1] = widget end
    end
    return list
end
local shown = Entries()
check(#shown == 2 and shown[1].Name._text == "Attack" and shown[2].SubName._text == Item.TEXT.passive,
    "the first tab shown: its spells, a passive's rank line saying so")
check(shown[2].art == Item.ART.Circle and shown[1].art == Item.ART.Square and shown[1].Button.Border._atlas == Item.ART.Square.active,
    "a spell in the game's square frame, a passive in its round one")
local bar = Tabs()
check(#bar == 3 and bar[1].Lit:IsShown() and not bar[2].Lit:IsShown() and bar[2].Icon._texture == 200, "the tabs, the chosen one lit")
bar[2]:GetScript("OnClick")(bar[2])
shown = Entries()
local bolt, nova, blizzard
for _, item in ipairs(shown) do
    if item.Name._text == "Frostbolt" then bolt = item elseif item.Name._text == "Frost Nova" then nova = item
    elseif item.Name._text == "Blizzard" then blizzard = item end
end
check(bolt and nova and blizzard and bolt.SubName._text == "Rank 2", "another tab: its spells")
check(blizzard.unlearned and blizzard.RequiredLevel._text == Item.TEXT.at:format(20) and blizzard.Button.Icon._desaturated
    and blizzard.Button.Border._atlas == Item.ART.Square.inactive, "a spell still to learn: grey, with the level it comes at")
level = 25
bar[1]:GetScript("OnClick")(bar[1])
bar[2]:GetScript("OnClick")(bar[2])
for _, item in ipairs(Entries()) do if item.Name._text == "Blizzard" then blizzard = item end end
check(blizzard.RequiredLevel._text == Item.TEXT.trainable and blizzard.Button.TrainableShadow:IsShown(), "at that level: trainable")
check(nova.Button.Cooldown._cooldown == "nova's cooldown", "the cooldown by the game's duration object")
-- Without it, the cooldown's numbers, only where they are plain: the game's swirl takes no hidden value from us.
local start = W.Secret() -- that start hidden from addons, as the game hides it in a fight: an error if computed with
C_SpellBook.GetSpellBookItemCooldown = function() return { isEnabled = true, startTime = start, duration = 8, modRate = 1 } end
Item.Cooldown(bolt)
check(bolt.Button.Cooldown._cooldown == nil, "without the duration object, a hidden start: no swirl, nothing computed with it")
start = 1234.5
Item.Cooldown(bolt)
check(bolt.Button.Cooldown._cooldown and bolt.Button.Cooldown._cooldown[1] == 1234.5, "a plain one: the swirl from its numbers")
C_SpellBook.GetSpellBookItemCooldown = function() return nil end
Item.Cooldown(bolt)
onBars[122] = nil
W.Fire("ACTIONBAR_SLOT_CHANGED")
W.Wait(0)
check(nova.missing and nova.Button.ActionBarHighlight:IsShown() and not bolt.Button.ActionBarHighlight:IsShown(),
    "a spell on none of your action bars glows, as in the game's book")
nova.Button:GetScript("OnDragStart")(nova.Button)
check(not nova.Button.ActionBarHighlight:IsShown(), "picked up for a bar: no glow while it is on the cursor")
W.Fire("CURSOR_CHANGED") -- dropped where no bar is
W.Wait(0)
check(nova.Button.ActionBarHighlight:IsShown(), "let go: it glows again, as in the game's book")
-- The status hidden from addons: nothing compared with it, so no glow.
local status = ActionButtonUtil.GetActionBarStatusForSpell
ActionButtonUtil.GetActionBarStatusForSpell = function() return W.Secret() end
W.Fire("ACTIONBAR_SLOT_CHANGED")
W.Wait(0)
check(not nova.missing and not nova.Button.ActionBarHighlight:IsShown(), "a status the game hides: no glow, nothing compared with it")
ActionButtonUtil.GetActionBarStatusForSpell = status
onBars[122] = true

-- Casting: the game's secure buttons over the icons, out of a fight.
W.Wait(0)
local function Covers()
    local list = {}
    for _, widget in ipairs(W.frames) do
        if widget._attributes and widget._attributes.checkselfcast and widget:IsShown() then list[#list + 1] = widget end
    end
    return list
end
local covers = Covers()
check(#covers == 2 and covers[1]._parent == UIParent and covers[1]._attributes.type1 == "spell"
    and covers[1]._attributes["shift-type1"] == "" and covers[1]._attributes.useOnKeyDown == false
    and covers[1]._strata == "HIGH" and covers[1]._level == 510 + Book.LEVEL,
    "a secure button over each learned spell's icon, on UIParent above the panel; none over one still to learn")
local spellsCovered = { [covers[1]._attributes.spell] = true, [covers[2]._attributes.spell] = true }
check(spellsCovered[205] and spellsCovered[122], "each casts its spell by its ID (the rank it is)")
-- The game locks the secure buttons only after PLAYER_REGEN_DISABLED's handlers ran (the buttons' last chance to
-- go), so the event first and the lock then: the stand-in's W.Combat(true) locks first.
W.Fire("PLAYER_REGEN_DISABLED")
check(#Covers() == 0, "a fight begins: the secure buttons go")
W.combat = true
bar[1]:GetScript("OnClick")(bar[1])
bar[2]:GetScript("OnClick")(bar[2])
W.Wait(0)
check(#Covers() == 0 and #Entries() == 3, "in a fight the book still shows and pages, without casting")
W.errors = {}
for _, item in ipairs(Entries()) do if item.Name._text == "Frost Nova" then nova = item end end
nova.Button:GetScript("OnClick")(nova.Button, "LeftButton")
check(W.errors[1] == Item.TEXT.fight, "a click in a fight says the book casts again after it")
nova.Button:GetScript("OnDragStart")(nova.Button)
check(picked and picked[1] == 5 and picked[2] == 0, "a drag still picks the spell up, for an action bar")
-- The module standing down in the fight (the board's Part.Leave): the secure buttons are the game's to lock, so
-- their clearing waits for the fight's end (Core.AfterCombat), none touched meanwhile: the stand-in refuses a
-- touch in a fight, an error Core would keep.
local function Problems()
    local count = 0
    for _, problem in pairs(Core.errors) do count = count + (type(problem) == "table" and tonumber(problem.count) or 1) end
    return count
end
local problems = Problems()
Part.Leave()
check(#Covers() == 0 and covers[1]:IsProtected() and Core.Owed("Combat: spellbook casts") and Problems() == problems,
    "left in a fight: the secure buttons' clearing waits for its end, none of the game's locked ones touched")
W.Combat(false) -- the lock lifted, then PLAYER_REGEN_ENABLED: the game's order, the stand-in's too
check(not Core.Owed("Combat: spellbook casts") and Problems() == problems, "the fight over: cleared then, no error kept")
Part.Show(true)
W.Wait(0)
check(#Covers() == 2, "shown again, the fight over: the secure buttons are back over the page")

-- The pet's abilities: by name, a right click switching autocast.
local petTab = Tabs()[3]
petTab:GetScript("OnClick")(petTab)
W.Wait(0)
covers = Covers()
check(#covers == 1 and covers[1]._attributes.type1 == "macro" and covers[1]._attributes.macrotext1 == "/cast Bite"
    and covers[1]._attributes.macrotext2 == "/petautocasttoggle Bite", "a pet's ability: cast by its name, autocast on a right click")
check(Entries()[1].Button.AutoCastOverlay:IsShown() and Entries()[1].Button.Ants:IsShown(), "its autocast shown, as in the game's book")
spells[1][1].subName = "Rank 2" -- the game's Show all ranks shows each rank of a pet's ability: each casts its own
W.Fire("SPELLS_CHANGED")
W.Wait(0)
covers = Covers()
check(covers[1]._attributes.macrotext1 == "/cast Bite(Rank 2)" and covers[1]._attributes.macrotext2 == "/petautocasttoggle Bite",
    "a pet's ability with a rank casts that rank")
spells[1][1].subName = nil

-- The search: every tab's finds; the tabs unlit meanwhile.
Part.Search("nova")
check(#Entries() == 1 and Entries()[1].Name._text == "Frost Nova" and not Tabs()[2].Lit:IsShown(), "the search finds spells of every tab")
Part.Search("")
check(#Entries() == 1 and Tabs()[3].Lit:IsShown(), "cleared: the tab chosen before")
Part.Search("frost")
local searching = Book.Chosen()
local general = Tabs()[1]
general:GetScript("OnClick")(general)
check(searching == nil and Book.Chosen() == "line1" and #Entries() == 2 and Entries()[1].Name._text == "Attack"
    and Tabs()[1].Lit:IsShown(), "a tab chosen while searching: its spells, the search left, as the game's book does")

-- Hidden: no secure buttons, nothing listened to.
Part.Show(false)
check(#Covers() == 0, "its panel hidden: the secure buttons go")
local before, made = Entries(), #W.frames
W.Fire("SPELLS_CHANGED")
W.Wait(0)
local after = Entries()
local same = #after == #before and #W.frames == made
for index, entry in ipairs(before) do same = same and after[index] == entry end
check(same and #Covers() == 0, "deaf while hidden: the entries as they were, nothing made, no secure buttons")

-- In Retail, whose book is not the one ours is made after (its art, no flyouts' spells loose in it: Combat.lua,
-- ns.Serves): ours is not there, the game's spellbook stays.
W.Play("retail")
check(not Part.Present() and not ns.Board.Present("spellbook"), "in Retail our spellbook is not there: the game's stays")
W.Play("forever")
check(Part.Present(), "in Forever it is")

io.write(("Book: all %d checks passed.\n"):format(passed))
