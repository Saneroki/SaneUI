-- Runs the Inventory module's character sheet against the stand-in client (wowstub.lua): its side tabs and the
-- tabs behind them (reputation, ...), each built when first chosen and listening to the game only while shown.
-- The window, the board, the paper doll and the stats are tried in dev/tests/inventory.lua. The look can only
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
RAID_CLASS_COLORS = { MAGE = { colorStr = "ff3fc7eb" } }
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
    return view
end
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
--  The side tabs
-------------------------------------------------------------------------------
local tabButtons = {}
for _, widget in ipairs(W.frames) do
    if rawget(widget, "_mouseUp") then tabButtons[widget.tooltipText] = widget end
end
check(tabButtons.Character and tabButtons.Reputation and tabButtons.Character._checked and not tabButtons.Reputation._checked,
    "the side tabs, the game's: Character chosen at first")
check(tabButtons.Character._points[1][2] == ns.Sheet.left:GetParent() and tabButtons.Character._points[1][3] == "TOPRIGHT",
    "right of the sheet, as the game's")
local function Pick(name)
    local button = tabButtons[name]
    button._mouseUp(button, "LeftButton", true)
end
local function Lists()
    local found = {}
    for _, widget in ipairs(W.frames) do
        local rows = rawget(widget, "rows")
        if type(rows) == "table" and widget.provider then found[#found + 1] = widget end
    end
    return found
end
check(#Lists() == 0, "a tab is built only when first chosen")
tabButtons.Reputation._mouseUp(tabButtons.Reputation, "RightButton", true)
check(tabButtons.Character._checked, "only the left button chooses a tab")

-------------------------------------------------------------------------------
--  Reputation
-------------------------------------------------------------------------------
Pick("Reputation")
check(tabButtons.Reputation._checked and not tabButtons.Character._checked and panel.title._text == "Reputation",
    "the reputation tab chosen: its side tab lit, the head says Reputation")
check(not head:IsVisible(), "the paper doll goes while another tab shows")
local repList = Lists()[1]
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
    if widget._kind == "CheckButton" and widget.label then boxes[widget.label._text] = widget end
end
selectedFaction = 2
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(boxes["At War"]:IsShown() and boxes["At War"]._checked == false, "the chosen faction's switches, as the game has them")
boxes["At War"]:GetScript("OnClick")(boxes["At War"])
check(repCalls.war == 2, "At War: the game's toggle for the chosen faction")
boxes["Move to Inactive"]:SetChecked(true)
boxes["Move to Inactive"]:GetScript("OnClick")(boxes["Move to Inactive"])
check(repCalls.active[1] == 2 and repCalls.active[2] == false, "Move to Inactive: the game's call, the faction made inactive")
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

-- Back to the paper doll; the reputation tab no longer listens.
Pick("Character")
check(head:IsVisible() and panel.title._text == "Tester Stub, the Patient", "the Character tab again: the paper doll and the name")
factionList[2].name = "Stormwind"
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(repList.rows[2].name._text == "Stormwind City", "the reputation tab hidden, it does not listen to the game")
Pick("Reputation")
check(repList.rows[2].name._text == "Stormwind", "chosen again: drawn as the game has it now, built only once")
check(#Lists() == 1, "one list: the tab is built once")

-------------------------------------------------------------------------------
--  Skills
-------------------------------------------------------------------------------
Pick("Skills")
check(tabButtons.Skills._checked and panel.title._text == "Skills", "the skills tab chosen")
local skillBox = Lists()[2]
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
Pick("Reputation")
W.Fire("SKILL_LINES_CHANGED")
W.Wait(0)
check(swords.bar._text:find("^150"), "the skills tab hidden, it does not listen to the game")
Pick("Skills")
check(skillBox.rows[2].bar._text:find("^151"), "chosen again: drawn as the game has it now")

-- The sheet hidden with the full screen: the tab shown no longer listens either.
Push()
Stand()
factionList[2].name = "Stormwind Keep"
W.Fire("UPDATE_FACTION")
W.Wait(0)
check(repList.rows[2].name._text == "Stormwind", "the full screen gone: the tabs do not listen")
Push()
Stand()
check(tabButtons.Skills._checked and skillBox.rows[2]:IsVisible(), "back: the tab chosen before")

io.write(("Sheet: all %d checks passed.\n"):format(passed))
