-- Runs the Inventory module's character sheet against the stand-in client (wowstub.lua): its parts as windows of
-- their own on the module's board (the paper doll fitting its window; the stats with the game's sidebar: gear sets,
-- titles, the pet; reputation, skills, PvP, currency, statistics), each built when first shown and listening to
-- the game only while shown. The window, the board, the paper doll and the stats are tried in dev/tests/inventory.lua. The look can only
-- be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/sheet.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

-------------------------------------------------------------------------------
--  What the module needs of the client (as dev/tests/combat.lua)
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:Raise() self._level = 500 end
function methods:SetClampedToScreen(on) self._clamped = on end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:IsMouseWheelEnabled() return self._wheel or false end
function methods:SetTexture(texture, wrap) self._texture, self._wrap = texture, wrap return true end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:IsProtected() return self._protected or false end
-- An animation: the test moves its clock (as dev/tests/window.lua does).
local function noop() end
function methods:CreateAnimationGroup()
    local group = { scripts = {}, playing = false, progress = 0 }
    function group:SetScript(name, fn) self.scripts[name] = fn end
    function group:Play() self.playing, self.progress = true, 0 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetToFinalAlpha = noop
    function group:CreateAnimation()
        local animation = setmetatable({ SetSmoothing = noop, SetToAlpha = noop }, { __index = function() return noop end })
        function animation:SetDuration(seconds) group.duration = seconds end
        function animation:GetProgress() return group.progress end
        function animation:GetSmoothProgress() return group.progress end
        return animation
    end
    function group:Run(progress)
        self.progress = progress
        if progress < 1 then return self.scripts.OnUpdate and self.scripts.OnUpdate() end
        self.playing = false
        if self.scripts.OnFinished then self.scripts.OnFinished() end
    end
    self._group = self._group or group
    return group
end
EasingUtil = { OutQuartic = function(p) return 1 - (1 - p) ^ 4 end }
IsMouseButtonDown = function() return false end
GetCursorPosition = function() return W.cursorX or 0, W.cursorY or 0 end
function methods:SetID(id) self._id = id end
function methods:GetID() return self._id end
function methods:SetFormattedText(format, ...) self._text = format:format(...) end
W.modifier = false -- no modifier key held (the stand-in's IsModifiedClick compares with it)

-- The character's items, as the game tells them: [slot ID] = { texture, count, quality, id, link, broken, locked }.
local SLOT_IDS = { HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4, ChestSlot = 5, WaistSlot = 6, LegsSlot = 7,
                   FeetSlot = 8, WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12, Trinket0Slot = 13,
                   Trinket1Slot = 14, BackSlot = 15, MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18,
                   TabardSlot = 19, AmmoSlot = 0 }
local worn = { [1] = { texture = "helm", count = 1, quality = 3, id = 1001, link = "|Hitem:1001|h[Helm]|h" } }
local rangedShown, ammoUser = true, false
C_PaperDollInfo = { GetInventorySlotInfo = function(name) return SLOT_IDS[name], "empty-" .. name, name == "RangedSlot" end,
                    IsRangedSlotShown = function() return rangedShown end }
UnitUsesAmmo = function() return ammoUser end
UnitHasRelicSlot = function() return false end
GetInventoryItemTexture = function(_, id) return worn[id] and worn[id].texture end
GetInventoryItemCount = function(_, id) return worn[id] and worn[id].count or 0 end
GetInventoryItemBroken = function(_, id) return worn[id] and worn[id].broken or false end
GetInventoryItemEquippedUnusable = function() return false end
GetInventoryItemQuality = function(_, id) return worn[id] and worn[id].quality end
GetInventoryItemID = function(_, id) return worn[id] and worn[id].id end
GetInventoryItemLink = function(_, id) return worn[id] and worn[id].link end
IsInventoryItemLocked = function(id) return worn[id] and worn[id].locked or false end
-- What the game's item button functions were told, per button.
local drawn = setmetatable({}, { __index = function(t, button) t[button] = {} return t[button] end })
SetItemButtonTexture = function(button, texture) drawn[button].texture = texture end
SetItemButtonCount = function(button, count) drawn[button].count = count end
SetItemButtonQuality = function(button, quality) drawn[button].quality = quality end
SetItemButtonTextureVertexColor = function(button, r, g, b) drawn[button].tint = { r, g, b } end
SetItemButtonNormalTextureVertexColor = function() end
SetItemButtonDesaturated = function(button, on) drawn[button].grey = on end
local picked, linked = {}, nil
PickupInventoryItem = function(id) picked[#picked + 1] = id end
HandleModifiedItemClick = function(link) linked = link end
function GameTooltip:SetInventoryItem(_, id) self._item = id return worn[id] ~= nil end
UnitPVPName = function() return "Tester Stub, the Patient" end
UnitSex = function() return 2 end
UnitEffectiveLevel = function() return W.level end
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92, colorStr = "ff3fc7eb" } }
PLAYER_LEVEL_NO_SPEC = "Level %s |c%s%s|r"
DressUpTexturePath = function(race) return "bg-" .. race end
local scenes = 0
ModelSceneUtil = { SetUpCharacterSheetScene = function() scenes = scenes + 1 end }

-- The game's side tabs (LargeSideTabButtonTemplate): an icon, checked or not, a handler for the left button let go.
W.templates.LargeSideTabButtonTemplate = function(widget)
    widget.Icon = W.NewWidget("Texture", nil, widget)
    function widget:SetCustomOnMouseUpHandler(fn) self._mouseUp = fn end
end
-- The game's stats list (the right pane): its scrolling list and rows, its table of stats, the resistances.
W.templates.CharacterStatsPaneScrollBoxTemplate = function(widget)
    widget.ScrollBox = W.NewWidget("Frame", nil, widget)
    widget.ScrollBox.sets = 0
    function widget.ScrollBox:SetDataProvider(provider) self.provider, self.sets = provider, self.sets + 1 end
    widget.ScrollBar = W.NewWidget("Frame", nil, widget)
end
W.templates.CharacterStatFrameTemplate = function(widget)
    widget.Label, widget.Value = W.NewWidget("FontString", nil, widget), W.NewWidget("FontString", nil, widget)
end
CreateScrollBoxListLinearView = function()
    local view = {}
    function view:SetElementFactory(fn) self.factory = fn end
    function view:SetElementExtentCalculator(fn) self.extent = fn end
    function view:SetElementExtent(extent) self.extent = extent end -- the other characters' roster: one height
    return view
end
GetMoney = function() return 0 end -- the bags' foot: the gold
-- The game's scrolling list a tab shows (WowScrollBoxList): its data made into rows by the view's factory, as the
-- game's list does for the rows on screen.
W.templates.WowScrollBoxList = function(box)
    function box:SetDataProvider(provider)
        self.provider, self.rows = provider, {}
        for index, element in ipairs(provider.elements) do
            self.view.factory(function(kind, init)
                local row = W.NewWidget(kind, nil, self)
                self.rows[index] = row
                init(row, element)
            end, element)
        end
    end
    function box:ForEachFrame(fn)
        for index, row in ipairs(self.rows or {}) do fn(row, self.provider.elements[index]) end
    end
end
-- The game's coloured bar (ColoredProgressBarTemplate): its fill and its words.
W.templates.ColoredProgressBarTemplate = function(widget)
    widget.Fill = W.NewWidget("Texture", nil, widget)
    function widget:SetFillPercent(share) self._fill = share end
    function widget:SetFillTextureByColorType(kind) self._kind = kind end
end
-- The game's reputation: a header, a faction, a header with a standing of its own.
local factionList = {
    { factionID = 0, name = "Classic", isHeader = true, isCollapsed = false },
    { factionID = 72, name = "Stormwind", reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000,
      currentStanding = 6000, canToggleAtWar = true, canSetInactive = true, description = "The city of the Alliance." },
    { factionID = 469, name = "Alliance", isHeader = true, isHeaderWithRep = true, isCollapsed = true, reaction = 4,
      currentReactionThreshold = 0, nextReactionThreshold = 3000, currentStanding = 1500 },
}
local selectedFaction, repCalls = 0, {}
C_Reputation = {
    GetNumFactions = function() return #factionList end,
    GetFactionDataByIndex = function(index)
        local faction = factionList[index]
        if not faction then return nil end
        local copy = {}
        for key, value in pairs(faction) do copy[key] = value end
        return copy
    end,
    GetSelectedFaction = function() return selectedFaction end,
    SetSelectedFaction = function(index) selectedFaction = index end,
    ExpandFactionHeader = function(index) repCalls.expand = index end,
    CollapseFactionHeader = function(index) repCalls.collapse = index end,
    ToggleFactionAtWar = function(index) repCalls.war = index end,
    SetFactionActive = function(index, on) repCalls.active = { index, on } end,
    IsFactionActive = function() return true end,
    SetWatchedFactionByIndex = function(index) repCalls.watch = index end,
    IsMajorFaction = function() return false end,
    IsAccountWideReputation = function() return false end,
}
FACTION_BAR_COLORS = { [4] = { r = 1, g = 1, b = 0 }, [5] = { r = 0, g = 0.6, b = 0.1 } }
GetText = function(name) return ({ FACTION_STANDING_LABEL5 = "Friendly", FACTION_STANDING_LABEL4 = "Neutral" })[name] end
REPUTATION, CHARACTER_FRAME_TAB_REPUTATION, CHARACTER_FRAME_TAB_CHARACTER = "Reputation", "Reputation", "Character"
-- The game's skills: a header, a weapon skill, a class skill (left out), a sub-header with a skill under it.
local skillList = {
    { skillID = 6, name = "Weapon Skills", isHeader = true, isCollapsed = false, parentSkillLineID = 0 },
    { skillID = 43, name = "Swords", rank = 150, maxRank = 300, modifier = 5, skillLineCategoryID = 6, parentSkillLineID = 0,
      description = "Swords." },
    { skillID = 200, name = "Arcane", rank = 1, maxRank = 1, modifier = 0, skillLineCategoryID = 7, parentSkillLineID = 0 },
    { skillID = 11, name = "Professions", isHeader = true, isChild = true, isCollapsed = false, parentSkillLineID = 0 },
    { skillID = 164, name = "Blacksmithing", rank = 75, maxRank = 150, modifier = 0, isChild = true, skillLineCategoryID = 11,
      parentSkillLineID = 0, description = "Hammer and anvil." },
    { skillID = 999, name = "A specialization", rank = 1, maxRank = 1, modifier = 0, parentSkillLineID = 164 },
}
local selectedSkill, skillCalls = 0, {}
C_SkillInfo = {
    GetNumSkillLines = function() return #skillList end,
    GetSkillLineInfo = function(index)
        local skill = skillList[index]
        if not skill then return nil end
        local copy = {}
        for key, value in pairs(skill) do copy[key] = value end
        return copy
    end,
    GetSelectedSkill = function() return selectedSkill end,
    SetSelectedSkill = function(index) selectedSkill = index end,
    ExpandSkillHeader = function(index) skillCalls.expand = index end,
    CollapseSkillHeader = function(index) skillCalls.collapse = index end,
}
ColoredProgressBarMixin = { ColorType = { Blue = "blue" } }
GetGlancingBlowChance = function() return 0.4 end
GetGlancingBlowPenalty = function() return 0.35 end
SKILLS, CHARACTER_FRAME_TAB_SKILLS = "Skills", "Skills"
WEAPON_SKILL_DETAIL_BOSS = "Hit %s, crit %s, glancing %s at %s less"
-- The game's PvP rank: the renown of its rank faction, its rewards, the season.
local rankInfo = { renownLevel = 3, renownReputationEarned = 250, renownLevelThreshold = 1000, maxLevel = 10,
                   currentWeekProgressiveMaxLevel = 6, previousWeekProgressiveMaxLevel = 5 }
local ringShare
C_MajorFactions = {
    GetMajorFactionProgressionInfo = function(faction) return faction == 2800 and rankInfo or nil end,
    GetTotalReputationForRenownLevel = function(_, level) return level * 1000 end,
    GetRenownRewardsForLevel = function(_, level)
        if level == 5 then return { { icon = "tabard", description = "A tabard of rank five." } } end
        return {}
    end,
}
-- The game's ticker: a function every so many seconds until cancelled.
C_Timer.NewTicker = function(seconds, fn)
    local ticker = {}
    function ticker:Cancel() self.cancelled = true end
    local function Tick()
        if ticker.cancelled then return end
        fn()
        C_Timer.After(seconds, Tick)
    end
    C_Timer.After(seconds, Tick)
    return ticker
end
GetCurrentArenaSeason = function() return 2 end
CooldownFrame_SetDisplayAsPercentage = function(_, share) ringShare = share end
UnitFactionGroup = function() return "Alliance", "Alliance" end
SetPortraitTexture = function(texture, unit) texture._portrait = unit end
Enum.PvPRanks = { Rank_1 = 5 }
local gameText = GetText
GetText = function(name, ...) if name == "PVP_RANK_7_1" then return "Knight" end return gameText(name, ...) end
PVP, CHARACTER_FRAME_TAB_PVP = "PvP", "PvP"
PVP_RANK_NUMBER_AND_TITLE, PVP_RANK_CURRENT_PROGRESS = "Rank %d: %s", "%d / %d"
-- The game's currencies: a header, two currencies (one shown on the backpack, one you have none of).
local currencyList = {
    { name = "Miscellaneous", isHeader = true, isHeaderExpanded = true, currencyListDepth = 0 },
    { name = "Honor", currencyID = 1901, quantity = 1500, iconFileID = 101, isShowInBackpack = true, currencyListDepth = 1,
      maxQuantity = 15000, discovered = true },
    { name = "Marks", currencyID = 1902, quantity = 0, iconFileID = 102, currencyListDepth = 1, maxQuantity = 0, discovered = true },
}
local currencyCalls = {}
C_CurrencyInfo = {
    GetCurrencyListSize = function() return #currencyList end,
    GetCurrencyListInfo = function(index)
        local data = currencyList[index]
        if not data then return nil end
        local copy = {}
        for key, value in pairs(data) do copy[key] = value end
        return copy
    end,
    ExpandCurrencyList = function(index, open) currencyCalls.expand = { index, open } end,
    SetCurrencyBackpack = function(index, on) currencyCalls.backpack = { index, on } end,
    SetCurrencyUnused = function(index, on) currencyCalls.unused = { index, on } end,
    GetCurrencyListLink = function(index) return "currency:" .. index end,
    GetCurrencyDescription = function(id) return "Currency " .. id end,
}
CreateSimpleTextureMarkup = function(icon) return "|T" .. icon .. "|t" end
DISABLED_FONT_COLOR = { r = 0.5, g = 0.5, b = 0.5 }
CURRENCY, CHARACTER_FRAME_TAB_CURRENCY = "Currency", "Currency"
-- The game's statistics: a category with a statistic, a category under it with one that has none yet.
local statCategories = { [1] = 130, [2] = 141 }
local statisticRows = { [130] = { { "12", false, 1001 } }, [141] = { { "0", false, 1002 }, { "5", true, 1003 } } }
GetStatisticsCategoryList = function() return statCategories end
GetCategoryInfo = function(id) return ({ [130] = "Character", [141] = "Combat" })[id], (id == 141 and 130 or -1) end
GetCategoryNumAchievements = function(id) return #(statisticRows[id] or {}) end
GetStatistic = function(id, index) local row = statisticRows[id][index] return row[1], row[2], row[3] end
GetAchievementInfo = function(id) return id, ({ [1001] = "Deaths", [1002] = "Hugs given" })[id] end
STATISTICS, CHARACTER_FRAME_TAB_STATISTICS = "Statistics", "Statistics"
-- The game's titles, gear sets and pet, for the sidebar.
local titleWorn, titleCalls = 0, {}
GetNumTitles = function() return 3 end
IsTitleKnown = function(index) return index ~= 2 end
GetTitleName = function(index) return ({ " the Patient", "Private", "Jenkins " })[index] end
GetCurrentTitle = function() return titleWorn end
SetCurrentTitle = function(index) titleCalls.worn = index end
local gearSets = { [7] = { "Tank", 101, 7, true, 0 }, [9] = { "Heal", 102, 9, false, 1 } }
local gearCalls = {}
C_EquipmentSet = {
    GetEquipmentSetIDs = function() return { 7, 9 } end,
    GetEquipmentSetInfo = function(id) local set = gearSets[id] return set[1], set[2], set[3], set[4], 0, 0, 0, set[5] end,
    GetNumEquipmentSets = function() return 2 end,
    UseEquipmentSet = function(id) gearCalls.used = id end,
    EquipmentSetContainsLockedItems = function() return false end,
}
UnitCastingInfo = function() return nil end
RED_FONT_COLOR = { r = 1, g = 0.125, b = 0.125 }
rawset(_G, "NORMAL_FONT_COLOR", rawget(_G, "NORMAL_FONT_COLOR") or { r = 1, g = 0.82, b = 0 })
local hasPet = false
HasPetUI = function() return hasPet end
UnitExists = function(unit) return unit == "player" or (unit == "pet" and hasPet) end
ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, _, view) box.view = view end }
CreateDataProvider = function(elements) return { elements = elements } end
ScrollBoxConstants = { RetainScrollPosition = true }
local statValues, shield = { HEALTH = 120, MOVESPEED = 100, CRITCHANCE = 5, HASTE = 0, BLOCK = 4 }, false
local function Fill(name) return { updateFunc = function(frame) frame.Value:SetText(tostring(statValues[name])) return statValues[name] end } end
PAPERDOLL_STATINFO = { HEALTH = Fill("HEALTH"), MOVESPEED = Fill("MOVESPEED"), CRITCHANCE = Fill("CRITCHANCE"),
                       HASTE = Fill("HASTE"), BLOCK = Fill("BLOCK") }
PAPERDOLL_STATCATEGORIES = {
    { categoryName = "General", unit = "player", stats = { { stat = "HEALTH" }, { stat = "MOVESPEED" } } },
    { categoryName = "Modifiers", unit = "player", stats = { { stat = "CRITCHANCE", hideAt = 0 }, { stat = "HASTE", hideAt = 0 } } },
    { categoryName = "Defense", unit = "player", stats = { { stat = "BLOCK", hideAt = 0, showFunc = function() return shield end } } },
    { categoryName = "Pet", unit = "pet", stats = { { stat = "HEALTH" } } },
}
rawset(_G, "Enum", rawget(_G, "Enum") or {})
Enum.Damageclass = { Fire = 2, Nature = 3, Frost = 4, Shadow = 5, Arcane = 6 }
local resists = { [2] = 15 }
UnitResistance = function(_, class) return 0, 0, resists[class] or 0, 0 end
PaperDollFrame_SetResistanceTooltips = function(tips, name, value) tips.tooltip = name .. " " .. value end
BreakUpLargeNumbers = function(value) return tostring(value) end
PaperDollFrame_FormatBonusValue = function(text) return text end
STAT_CATEGORY_RESISTANCE, DAMAGE_SCHOOL3 = "Resistance", "Fire"

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Inventory", "SaneUI_Inventory")
W.Fire("ADDON_LOADED", "SaneUI_Inventory")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Inventory == ns and not ns.off, "the module is made and started")
local Board, Edge, Slots = ns.Board, Core.Edge, ns.Slots

-------------------------------------------------------------------------------
--  The window, docked in the bottom right corner
-------------------------------------------------------------------------------
local handle = ns.Window.handle
local frame = handle.frame
check(handle.zone == "BOTTOMRIGHT" and frame._width == ns.Window.WIDTH and not frame._mouse,
    "its window is docked in the bottom right corner at first, and takes no click while small")
frame._left, frame._bottom = 1920 - ns.Window.WIDTH, 0
local square = handle.edge.strips.corner
check(square and square:IsShown() and square._points[1][1] == "BOTTOMRIGHT" and near(square._width, 4 * 768 / 2160)
    and square._strata == "DIALOG", "the corner's square, four of the screen's pixels, fills the screen")
for _, side in ipairs({ "left", "right", "top", "bottom" }) do
    check(not (handle.edge.strips[side] and handle.edge.strips[side]:IsShown()), "no strip along a side: only the corner (" .. side .. ")")
end

local function Push()
    W.Wait(1) -- a while after the square came under the mouse
    W.cursorX, W.cursorY = 1920, 0
    square:GetScript("OnEnter")(square)
    W.cursorX, W.cursorY = 960, 500 -- the mouse goes away again: the next push counts
    W.Wait(Edge.LOOK)
end
local function Stand()
    frame._group:Run(1)
    W.Wait(0)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  The sheet on the full screen
-------------------------------------------------------------------------------
Push()
Stand()
local panel = Board.Panel("character")
local head = Slots.Button(1)
check(panel and panel:IsShown() and head and head:IsVisible(), "the character sheet on the full screen, the paper doll shown")

-------------------------------------------------------------------------------
--  The windows on the board
-------------------------------------------------------------------------------
-- A window of the module's put on the board from the dropdown Windows (Core's board), or taken off it.
local function Open(key)
    if not Board.layouts:Has(key) then Board.layouts:Toggle(key) end
    return Board.Panel(key)
end
local function Close(key)
    if Board.layouts:Has(key) then Board.layouts:Toggle(key) end
end
-- The game's list a window shows (the stand-in's rows), found by the panel that holds it.
local function Inside(widget, panel)
    while widget do
        if widget == panel then return true end
        widget = widget._parent
    end
end
local function ListIn(panel)
    for _, widget in ipairs(W.frames) do
        local rows = rawget(widget, "rows")
        if type(rows) == "table" and widget.provider and Inside(widget, panel) then return widget end
    end
end
for _, key in ipairs({ "reputation", "skills", "pvp", "currency", "statistics" }) do
    check(not Board.layouts:Has(key) and not Board.Panel(key), "at first " .. key .. " is not on the board, and not built")
end
check(Board.layouts:Has("character") and Board.layouts:Has("stats"), "the first layout holds the paper doll and the stats")
local dollRect = Board.layouts.rects.character
check(ns.Sheet.pane:GetScale() < 1 and near(ns.Sheet.pane:GetScale(),
    math.min(dollRect[3] / ns.Doll.WIDTH, dollRect[4] / ns.Doll.HEIGHT)),
    "the doll as large as fits in its window")

-- Each window's tab of its own in the title bar, after the layouts' tabs: its icon in place of words, lit while
-- the window is on the board; a click puts it on or takes it off.
local strip = Board.layouts.strip
local function IconTab(key)
    for index = 1, strip.icons.taken do
        if strip.icons[index].key == key then return strip.icons[index] end
    end
end
local iconKeys = {}
for index = 1, strip.icons.taken do iconKeys[index] = strip.icons[index].key end
check(table.concat(iconKeys, ",") == table.concat(Board.ORDER, ","),
    "a tab of its own for each window, in the dropdown's order: " .. table.concat(iconKeys, ","))
local repIcon, dollIcon = IconTab("reputation"), IconTab("character")
check(dollIcon._selected and IconTab("alts")._selected and not repIcon._selected and repIcon.Text._text == ""
    and repIcon.icon._texture == "Interface/ICONS/INV_SideTab_Reputation2_c60" and dollIcon.icon._portrait == "player",
    "the first layout's windows lit, the others not; no words, the game's icons, the paper doll's your portrait")
check(IconTab("pvp").icon._texture == "Interface/ICONS/INV_SideTab_Honor_Alliance_c60", "the PvP window's icon of your faction")
repIcon:GetScript("OnClick")(repIcon)
check(Board.layouts:Has("reputation") and IconTab("reputation")._selected, "a click puts the window on the board, its tab lit")
IconTab("reputation"):GetScript("OnClick")(IconTab("reputation"))
check(not Board.layouts:Has("reputation") and not IconTab("reputation")._selected, "another takes it off again")

-------------------------------------------------------------------------------
--  The stats and the sidebar
-------------------------------------------------------------------------------
local stats = Board.Panel("stats")
local Sidebar = ns.Sidebar
check(stats and stats:IsShown() and Sidebar.Chosen() == "stats" and stats.title._text == "Character Stats",
    "the stats' window, the stats tab chosen, the head says so")
local statsTab, gearTab, titlesTab, petTab = Sidebar.Button("stats"), Sidebar.Button("gear"), Sidebar.Button("titles"), Sidebar.Button("pet")
check(statsTab._checked and not petTab:IsShown() and gearTab:IsEnabled() and titlesTab:IsEnabled(),
    "the game's sidebar tabs: Stats chosen, no pet's tab without a pet, gear sets and titles to choose")
check(gearTab._points[1][1] == "TOP", "three tabs centred without a pet's, as the game centres them")
titlesTab:GetScript("OnClick")(titlesTab)
check(Sidebar.Chosen() == "titles" and stats.title._text == "Titles" and titlesTab._checked and not statsTab._checked,
    "Titles chosen: its tab checked, the head says Titles")
local titleList = ListIn(stats)
local function TitleNames()
    local names = {}
    for index, row in ipairs(titleList.rows) do names[index] = row.text._text .. (row.check:IsShown() and "*" or "") end
    return table.concat(names, ", ")
end
check(TitleNames() == "None*, Jenkins, the Patient", "None first and worn, then the titles you know by name: " .. TitleNames())
local titlesDrawn = titleList.provider
titlesTab:SetChecked(false) -- the game's button unchecks itself when clicked
titlesTab:GetScript("OnClick")(titlesTab)
check(Sidebar.Chosen() == "titles" and titlesTab._checked and titleList.provider == titlesDrawn,
    "the tab chosen clicked again: all stays as it is, its button checked")
titleList.rows[3]:GetScript("OnClick")(titleList.rows[3])
check(titleCalls.worn == 1, "a click wears the title, by the game's own call")
titleWorn = 1
W.Fire("KNOWN_TITLES_UPDATE")
W.Wait(0)
check(TitleNames() == "None, Jenkins, the Patient*", "the game tells of the change: the title worn ticked")
gearTab:GetScript("OnClick")(gearTab)
check(Sidebar.Chosen() == "gear", "the equipment manager chosen")
local gearList
for _, widget in ipairs(W.frames) do
    local rows = rawget(widget, "rows")
    if type(rows) == "table" and widget.provider and rows[1] and rows[1].data and rows[1].data.name == "Heal" then gearList = widget end
end
check(gearList and gearList.rows[2].check:IsShown() and gearList.rows[1].text._color[1] == 1,
    "the sets by name, a tick on the one worn, red with an item lost")
gearList.rows[1]:GetScript("OnClick")(gearList.rows[1], "LeftButton")
check(gearList.rows[1].chosen:IsShown(), "a click chooses a set")
gearList.rows[1]:GetScript("OnDoubleClick")(gearList.rows[1])
check(gearCalls.used == 9, "a double click puts it on, by the game's own call")
-- Save and New Set as the game's sheet saves: the slots the set leaves out left out first, a new set without the
-- shirt and the tabard; the game's note of them cleared after.
do
    local calls = {}
    local function Note(text) calls[#calls + 1] = text end
    C_EquipmentSet.GetIgnoredSlots = function(id) return id == 9 and { [4] = true, [1] = false } or {} end
    C_EquipmentSet.IgnoreSlotForSave = function(slot) Note("ignore " .. slot) end
    C_EquipmentSet.UnignoreSlotForSave = function(slot) Note("unignore " .. slot) end
    C_EquipmentSet.ClearIgnoredSlotsForSave = function() Note("clear") end
    C_EquipmentSet.SaveEquipmentSet = function(id) Note("save " .. id) end
    C_EquipmentSet.CreateEquipmentSet = function(name) Note("create " .. name) end
    local saveButton, newButton
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Button" and Inside(widget, stats) then
            if widget._text == "Save" then saveButton = widget elseif widget._text == "New Set" then newButton = widget end
        end
    end
    saveButton:GetScript("OnClick")(saveButton)
    W.popups[#W.popups].data.callback()
    local pair = tostring(calls[2]) .. ", " .. tostring(calls[3])
    check(calls[1] == "clear" and (pair == "ignore 4, unignore 1" or pair == "unignore 1, ignore 4") and calls[4] == "save 9"
        and calls[5] == "clear", "Save: the set's own slots left out first, as the game's sheet does: " .. table.concat(calls, ", "))
    calls = {}
    newButton:GetScript("OnClick")(newButton)
    W.popups[#W.popups].data.callback("Raid")
    check(table.concat(calls, ", ") == "clear, ignore 4, ignore 19, create Raid, clear",
        "New Set: made without the shirt and the tabard, as the game's sheet makes one: " .. table.concat(calls, ", "))
end
hasPet = true
W.Fire("UNIT_PET", "player")
W.Wait(0)
check(petTab:IsShown() and gearTab._points[1][1] == "TOPRIGHT", "a pet: its tab comes, the four as the game sets them")
petTab:GetScript("OnClick")(petTab)
check(Sidebar.Chosen() == "pet" and stats.title._text == "Pet", "the pet's tab chosen")
hasPet = false
W.Fire("UNIT_PET", "party1")
W.Wait(0)
check(Sidebar.Chosen() == "pet", "another's pet came or went: nothing to do, the player's pet only is listened to")
W.Fire("UNIT_PET", "player")
W.Wait(0)
check(Sidebar.Chosen() == "stats" and not petTab:IsShown(), "the pet gone: back to the stats")
-- The pet gone while the window is hidden: shown again with the stats.
hasPet = true
W.Fire("UNIT_PET", "player")
W.Wait(0)
petTab:GetScript("OnClick")(petTab)
Close("stats")
hasPet = false
W.Fire("UNIT_PET", "player")
W.Wait(0)
check(Open("stats") == stats and Sidebar.Chosen() == "stats" and stats.title._text == "Character Stats" and not petTab:IsShown(),
    "the pet gone while the window was hidden: shown again with the stats")

-------------------------------------------------------------------------------
--  Reputation
-------------------------------------------------------------------------------
local repPanel = Open("reputation")
check(repPanel and repPanel:IsShown() and repPanel.title._text == "Reputation" and head:IsVisible(),
    "the reputation window put on the board beside the paper doll")
local repList = ListIn(repPanel)
check(repList and #repList.rows == 3, "the factions as the game lists them")
check(selectedFaction == 2, "none chosen: the first faction that can be is chosen, as the game does")
local header, faction, withRep = repList.rows[1], repList.rows[2], repList.rows[3]
check(header.state:IsShown() and header.state._atlas == "common-button-list-minus" and not header.bar:IsShown(),
    "a header: the game's art and its fold sign, no bar")
check(faction.bar:IsShown() and faction.bar._text == "Friendly" and near(faction.bar._fill, 0.5) and faction.bar.Fill._vertex[2] == 0.6,
    "a faction: the game's bar, its standing's word, its share, its colour")
check(withRep.toggle:IsShown() and withRep.bar._text == "Neutral", "a header with a standing: its fold button and its own bar")
check(repList.view.extent(nil, factionList[1]) == ns.Rows.HEADER and repList.view.extent(nil, factionList[2]) == ns.Rows.ENTRY,
    "each row as high as the game's")
faction:GetScript("OnEnter")(faction)
check(faction.bar._text == faction.bar.progress and faction.bar.progress:find("3000 / 6000", 1, true),
    "under the mouse: the progress in numbers")
faction:GetScript("OnLeave")(faction)
check(faction.bar._text == "Friendly", "and its word again when the mouse leaves")
local sideTitle
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text == "Stormwind" and widget ~= faction.name then sideTitle = widget end
end
check(sideTitle, "the chosen faction at the right: its name")
header:GetScript("OnClick")(header)
check(repCalls.collapse == 1, "a click on a header folds it, by the game's own call")
withRep.toggle:GetScript("OnClick")(withRep.toggle)
check(repCalls.expand == 3, "a header with a standing unfolds by its button")
withRep:GetScript("OnClick")(withRep)
check(selectedFaction == 3, "a click on a faction chooses it, by the game's own call")
local boxes = {}
for _, widget in ipairs(W.frames) do
    if widget._kind == "CheckButton" and widget.label and Inside(widget, repPanel) then boxes[widget.label._text] = widget end
end
selectedFaction = 2
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(boxes["At War"]:IsShown() and boxes["At War"]._checked == false, "the chosen faction's switches, as the game has them")
boxes["At War"]:GetScript("OnClick")(boxes["At War"])
check(repCalls.war == 2, "At War: the game's toggle for the chosen faction")
-- Made inactive, the faction goes to the end of the game's list: chosen again there, by its ID, as the game's sheet does.
local setActive = C_Reputation.SetFactionActive
C_Reputation.SetFactionActive = function(index, on)
    setActive(index, on)
    local moved = table.remove(factionList, index)
    factionList[#factionList + 1] = moved
end
boxes["Move to Inactive"]:SetChecked(true)
boxes["Move to Inactive"]:GetScript("OnClick")(boxes["Move to Inactive"])
check(repCalls.active[1] == 2 and repCalls.active[2] == false and selectedFaction == 3 and factionList[3].factionID == 72,
    "Move to Inactive: the game's call, the faction made inactive and still the one chosen where it went")
C_Reputation.SetFactionActive = setActive
table.insert(factionList, 2, table.remove(factionList))
selectedFaction = 2
boxes["Show as Experience Bar"]:SetChecked(true)
boxes["Show as Experience Bar"]:GetScript("OnClick")(boxes["Show as Experience Bar"])
check(repCalls.watch == 2, "Show as Experience Bar: the game's watched faction")
factionList[2].name = "Stormwind City"
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(repList.rows[2].name._text == "Stormwind City", "the game tells of a change: the list drawn anew")
selectedFaction = 0
factionList[2].isHeader, factionList[3].isHeaderWithRep = true, nil
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(not boxes["At War"]:IsShown(), "nothing to choose: the side says so, the switches go")
factionList[2].isHeader, factionList[3].isHeaderWithRep = nil, true

-- Taken off the board, the reputation window no longer listens.
Close("reputation")
check(not repPanel:IsShown(), "taken off the board: the reputation window goes")
factionList[2].name = "Stormwind"
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(repList.rows[2].name._text == "Stormwind City", "off the board, it does not listen to the game")
check(Open("reputation") == repPanel and ListIn(repPanel) == repList and repList.rows[2].name._text == "Stormwind",
    "put on again: drawn as the game has it now, built only once")
Close("reputation")

-------------------------------------------------------------------------------
--  Skills
-------------------------------------------------------------------------------
local skillPanel = Open("skills")
check(skillPanel and skillPanel.title._text == "Skills", "the skills window on the board")
local skillBox = ListIn(skillPanel)
check(skillBox and #skillBox.rows == 4, "the skill lines as the game lists them: the class's own and the ones under another left out")
check(selectedSkill == 2, "none chosen: the first skill the game lists")
local skillHeader, swords, professions, smithing = skillBox.rows[1], skillBox.rows[2], skillBox.rows[3], skillBox.rows[4]
check(skillHeader.state:IsShown() and swords.bar._text == "150 |cnPURE_GREEN_COLOR:(+5)|r / 300" and near(swords.bar._fill, 0.5)
    and swords.bar._kind == "blue", "a skill: the game's blue bar, its rank and its bonus in green")
check(professions.toggle:IsShown() and professions.toggle._points[1][4] == 2 + ns.Skills.INDENT,
    "a sub-header: its fold button, set in as the game sets it")
check(smithing.name._points[1][4] == ns.Rows.NAME_LEFT + ns.Skills.INDENT_CHILD and smithing.bar._text == "75 / 150",
    "a skill under a sub-header: set in further")
professions:GetScript("OnClick")(professions)
check(skillCalls.collapse == 4, "a click on a sub-header folds it, as the game's does")
smithing:GetScript("OnClick")(smithing)
check(selectedSkill == 5, "a click on a skill chooses it")
local smithTitle, glancing
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text == "Blacksmithing" and widget ~= smithing.name then smithTitle = widget end
    if widget._kind == "FontString" and widget._text and widget._text:find("glancing", 1, true) and widget:IsVisible() then glancing = widget end
end
check(smithTitle and not glancing, "the chosen skill at the right: its name, no weapon lines for a trade")
selectedSkill = 2
W.Fire("SKILL_LINES_CHANGED")
W.Wait(0)
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text and widget._text:find("glancing", 1, true) and widget:IsVisible() then glancing = widget end
end
check(glancing and glancing._text == "Hit -6.40%, crit -6.40%, glancing 40% at 35% less",
    "a weapon skill: against a raid boss as the game works it out: " .. tostring(glancing and glancing._text))
skillList[2].rank = 151
Close("skills")
W.Fire("SKILL_LINES_CHANGED")
W.Wait(0)
check(swords.bar._text:find("^150"), "off the board, the skills window does not listen to the game")
Open("skills")
check(skillBox.rows[2].bar._text:find("^151"), "put on again: drawn as the game has it now")
Close("skills")

-------------------------------------------------------------------------------
--  PvP
-------------------------------------------------------------------------------
local pvpPanel = Open("pvp")
check(pvpPanel and pvpPanel.title._text == "PvP", "the PvP window on the board")
local function Shown(text)
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and widget._text == text and widget:IsVisible() then return widget end
    end
end
check(Shown("Rank 3: Knight") and Shown("250 / 1000") and near(ringShare, 0.25),
    "the rank's number and title, the points toward the next, the ring's share")
check(Shown("Knight") and Shown("A tabard of rank five."), "at the right the rank's title and the next reward, with its icon")
rankInfo.renownLevel, rankInfo.renownReputationEarned = 4, 500
W.Fire("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
W.Wait(0)
check(near(ringShare, 0.5), "a new rank: drawn anew")
local seasonSet = 0
C_SeasonInfo = { GetTimeUntilCurrentPVPSeasonEnd = function() seasonSet = seasonSet + 1 return 0 end }
W.Wait(1.1)
check(seasonSet >= 1, "while shown, the season's time is asked each second")
Close("pvp")
local before = seasonSet
W.Wait(3)
check(seasonSet == before, "hidden, no more")

-------------------------------------------------------------------------------
--  Currency
-------------------------------------------------------------------------------
local coinPanel = Open("currency")
check(coinPanel and coinPanel.title._text == "Currency", "the currency window on the board")
local coinBox = ListIn(coinPanel)
check(coinBox and #coinBox.rows == 3, "the currencies as the game lists them")
local coinHeader, honor, marks = coinBox.rows[1], coinBox.rows[2], coinBox.rows[3]
check(coinHeader.state:IsShown() and not coinHeader.coin:IsShown(), "a header: the game's art, no count")
check(honor.count._text == "1500" and honor.coin._texture == 101 and honor.watched:IsShown() and not honor.bar:IsShown(),
    "a currency: how many, its icon, the backpack's tick; no bar")
check(marks.name._color[1] == 0.5 and not marks.watched:IsShown(), "one you have none of: greyed, no tick")
check(Shown("Honor") and Shown("|T101|t 1500") and Shown("Currency 1901"), "the first chosen: its name, icon and count, its description at the right")
coinBox.rows[3]:GetScript("OnClick")(coinBox.rows[3])
check(Shown("Currency 1902"), "a click chooses another")
W.modifier = "TOKENWATCHTOGGLE"
coinBox.rows[2]:GetScript("OnClick")(coinBox.rows[2])
W.modifier = false
check(currencyCalls.backpack[1] == 2 and currencyCalls.backpack[2] == false, "the watch key and a click: off the backpack, by the game's call")
coinBox.rows[1]:GetScript("OnClick")(coinBox.rows[1])
check(currencyCalls.expand[1] == 1 and currencyCalls.expand[2] == false, "a click on a header folds it, by the game's call")

-------------------------------------------------------------------------------
--  Statistics
-------------------------------------------------------------------------------
Close("currency")
local statPanel = Open("statistics")
check(statPanel and statPanel.title._text == "Statistics", "the statistics window on the board")
local statBox = ListIn(statPanel)
local function StatNames()
    local names = {}
    for index, row in ipairs(statBox.rows) do names[index] = row.name._text .. (row.value:IsShown() and ("=" .. row.value._text) or "") end
    return table.concat(names, ", ")
end
check(StatNames() == "Character, Deaths=12, Combat, Hugs given=--", "the game's statistics as a tree, none yet as --, a skipped one left out: " .. StatNames())
check(statBox.rows[3].toggle:IsShown() and statBox.rows[3].toggle._points[1][4] == 2 + ns.Statistics.INDENT,
    "a category under another: a sub-header, set in")
statBox.rows[1]:GetScript("OnClick")(statBox.rows[1])
check(StatNames() == "Character", "a click on a category folds it and all under it")
statBox.rows[1]:GetScript("OnClick")(statBox.rows[1])
statisticRows[130][1][1] = "13"
W.Fire("CRITERIA_UPDATE")
W.Fire("CRITERIA_UPDATE")
W.Wait(0)
check(StatNames():find("Deaths=13", 1, true), "the game tells of a change: drawn anew")

-- The full screen gone: the windows on it no longer listen; back, they are where they were.
Open("reputation")
Push()
Stand()
factionList[2].name = "Stormwind Keep"
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(repList.rows[2].name._text == "Stormwind", "the full screen gone: the windows do not listen")
Push()
Stand()
check(repPanel:IsShown() and statPanel:IsShown() and head:IsVisible() and repList.rows[2].name._text == "Stormwind Keep",
    "back: the windows of the layout as they were, drawn as the game has it now")
for label, problem in pairs(Core.errors) do check(false, "no step failed on the way: " .. label .. ": " .. tostring(problem.text)) end

io.write(("Sheet: all %d checks passed.\n"):format(passed))
