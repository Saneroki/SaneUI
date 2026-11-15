-- Runs the Combat module's reminders (src/Combat/Reminders/) and the marks on the game's buff list (src/Combat/Units/
-- BuffList.lua) against the stand-in client (wowstub.lua): the right click on the game's own buffs, the marks Important,
-- Unimportant and Hidden there, what shows on a bar and when (missing, active, the offset, combat, resting), a bar as wide
-- as what it holds, bars made and deleted, a fight in which the game hides the auras, the window, standing down. At its end
-- it runs again as Retail loads the module ("retail": W.Play).
-- Usage, from the project folder:  lua5.1 dev/tests/reminders.lua

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
function methods:SetClampedToScreen(on) self._clamped = on end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:GetFrameLevel() return self._level or 1 end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:IsProtected() return self._protected or false end
function methods:SetTexture(texture, wrap) self._texture, self._wrap = texture, wrap return true end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:OverrideText(text) self._override = text end -- a dropdown's own words
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
local function noop() end
function methods:CreateAnimationGroup()
    local group = setmetatable({}, { __index = function() return noop end })
    function group:CreateAnimation() return setmetatable({}, { __index = function() return noop end }) end
    return group
end
W.templates.PagingControlsHorizontalTemplate = function(controls)
    controls.PageText = W.NewWidget("FontString", nil, controls)
    function controls:GetCurrentPage() return 1 end
end
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:GetCenter()
    return self._left and self._left + self._width / 2, self._bottom and self._bottom + self._height / 2
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

-- The auras on you and your target, by name; the game's two frames of aura buttons.
local on = { player = {}, target = {} }
local THORNS = { name = "Thorns", spellId = 782, icon = 136104, auraInstanceID = 11, expirationTime = 0 }
local MARK = { name = "Mark of the Wild", spellId = 1126, icon = 136078, auraInstanceID = 12, expirationTime = 0 }
local SHADE = { name = "Weakened Soul", spellId = 6788, icon = 136000, auraInstanceID = 13, expirationTime = 0 }
local secret, plainSpells = false, {}
C_Secrets = { ShouldAurasBeSecret = function() return secret end,
              ShouldSpellAuraBeSecret = function(id) return secret and not plainSpells[id] end }
local function Secret(data, spell)
    if secret and not plainSpells[spell or (data and data.spellId)] then return data and W.Secret() end
    return data
end
C_UnitAuras.GetAuraDataBySpellName = function(unit, name) return Secret((on[unit] or {})[name]) end
C_UnitAuras.GetAuraDataByAuraInstanceID = function(unit, id)
    for _, data in pairs(on[unit] or {}) do
        if data.auraInstanceID == id then return Secret(data) end
    end
end
C_UnitAuras.GetAuraDuration = function(unit, id) -- the game fails on an instance that is gone
    for _, data in pairs(on[unit] or {}) do
        if data.auraInstanceID == id then return {} end
    end
    error("invalid aura instance")
end
local resting, shift = false, false
IsResting = function() return resting end
IsShiftKeyDown = function() return shift end
local function Buttons(count)
    local frame = { auraFrames = {}, UpdateAuraButtons = function() end, AuraContainer = { UpdateGridLayout = function() end } }
    for index = 1, count do
        local button = W.NewWidget("Button", nil, UIParent)
        button:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -35 * index, 0)
        for _, key in ipairs({ "Icon", "Duration", "Count", "Symbol", "DebuffBorder", "TempEnchantBorder" }) do
            rawset(button, key, W.NewWidget("Frame", nil, button))
        end
        rawget(button, "Icon"):SetSize(30, 30)
        frame.auraFrames[index] = button
    end
    return frame
end
BuffFrame, DebuffFrame = Buttons(3), Buttons(1)
-- The game's classes, three of them (When class in group).
local CLASSES = { { "Warrior", "WARRIOR" }, { "Paladin", "PALADIN" }, { "Druid", "DRUID" } }
GetNumClasses = function() return #CLASSES end
GetClassInfo = function(id) local class = CLASSES[id] if class then return class[1], class[2], id end end
BuffFrame.auraFrames[4] = { isAuraAnchor = true }

if RETAIL then W.Play("retail") end
W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Combat == ns and not ns.off, "the module is made and started")
local Reminders, Bars = ns.Reminders, ns.ReminderBars
local Update = Reminders.Update
local TEXT = ns.TEXT
-- Whether the reminder shows at that place alone; its places, in order ("2 0 -1").
local function Only(reminder, place)
    local places = Reminders.Places(reminder)
    return #places == 1 and places[1] == place
end
local function Where(reminder) return table.concat(Reminders.Places(reminder), " ") end

local function Click(button, mouse)
    W.menus = {}
    button._scripts.OnClick(button, mouse or "LeftButton")
    return W.menus[1]
end
local function Alert(button)
    for _, widget in ipairs(W.frames) do
        if widget._parent == button and widget._template == ns.BuffList.ALERT then return widget end
    end
end
local thorns = BuffFrame.auraFrames[1]

-------------------------------------------------------------------------------
--  The click on the game's own auras
-------------------------------------------------------------------------------
on.player.Thorns = THORNS
thorns.auraType, thorns.buttonInfo = "Buff", { index = 1, auraInstanceID = 11 }
BuffFrame.auraFrames[2].auraType = "TempEnchant"
DebuffFrame.auraFrames[1].auraType = "Debuff"
check(Click(thorns, "RightButton") == nil, "a right click is the game's alone: it cancels")
check(Click(BuffFrame.auraFrames[2]) == nil, "a weapon enchant is no aura: no menu")
local menu = Click(thorns)
check(menu and menu[1].title == "Thorns" and menu[2].text == TEXT.auraImportant and menu[3].text == TEXT.auraUnimportant
    and menu[4].text == TEXT.auraHidden and menu[5].text == TEXT.auraFramesShow and menu[6].text == TEXT.auraFramesHide
    and menu[7].text == TEXT.auraLists and menu[8].text == TEXT.trackAdd and #menu == 8,
    "a left click: its menu, the spell, the marks, Edit tracked..., last Add tracking")
check(TEXT.auraLists == "Edit tracked..." and TEXT.listsTitle == "Edit tracked" and TEXT.aurasOpen == "Edit tracked",
    "the window's line in the menu, its title and its button on the settings page, in their words")
menu[8].fn()
local list = Reminders.List()
local reminder = list[1]
check(#list == 1 and reminder.name == "Thorns" and reminder.id == 782 and #reminder.units == 1
    and reminder.units[1] == "player" and reminder.unit == nil and Only(reminder, Reminders.Bars()[1]),
    "Add tracking: the reminder is made, on the first aura bar, of your own aura, watched on you")
check(reminder.missing and not reminder.active and reminder.early == 0 and reminder.combat == "any", "a buff: shown when missing")
check(ns.options.auraKept[782] == "Thorns" and ns.ReminderEditor.panel and ns.ReminderEditor.panel:IsVisible(),
    "and Edit tracked opens on it, the aura on its list")
menu = Click(thorns)
check(#menu == 7 and menu[7].text == TEXT.auraLists, "tracked: no Add tracking, Edit tracked... last")
ns.AuraLists.Hide()
menu[7].fn()
check(#Reminders.List() == 1 and ns.ReminderEditor.panel:IsVisible(), "which opens the window on it, nothing made twice")
ns.AuraLists.Hide()
Reminders.Take(reminder)
Click(thorns)[8].fn()
reminder = Reminders.List()[1]
check(#Reminders.List() == 1 and Only(reminder, Reminders.Bars()[1]), "deleted, then added again")
ns.AuraLists.Hide()

-------------------------------------------------------------------------------
--  The marks on the game's list
-------------------------------------------------------------------------------
local List = ns.BuffList
local function Line(button, word)
    for _, item in ipairs(Click(button)) do
        if item.text == word then return item end
    end
end
local function Glows(button)
    local glow = Alert(button)
    return glow ~= nil and glow:IsShown()
end
local bear = BuffFrame.auraFrames[3]
local mid = BuffFrame.auraFrames[2]
local slotOf = {}
for index, button in ipairs({ thorns, mid, bear }) do slotOf[index] = button._points[1][4] end
thorns.hasValidInfo, mid.hasValidInfo, bear.hasValidInfo = true, true, true
mid.buttonInfo = { index = 1 }
on.player.Bear = { name = "Bear", spellId = 5487, icon = 1, auraInstanceID = 14, expirationTime = 0 }
bear.auraType, bear.buttonInfo = "Buff", { index = 2, auraInstanceID = 14 }
local function Rebuilt() BuffFrame:UpdateAuraButtons() end

Line(thorns, TEXT.auraFramesHide).fn()
check(ns.options.auraHide[782] and not Glows(thorns) and thorns.Icon._alpha ~= List.FADED,
    "Hide from unit frames: the list as it is, no fade")
Line(thorns, TEXT.auraFramesHide).fn()
Line(thorns, TEXT.auraFramesShow).fn()
check(ns.options.auraShow[782] and not Glows(thorns), "Show on unit frames: no glow")
Line(thorns, TEXT.auraImportant).fn()
check(Glows(thorns) and ns.options.auraShow[782], "a mark of how it looks beside it, each of its own")
local alert = Alert(thorns)
check(alert._template == "ActionButtonSpellAlertTemplate" and alert:GetParent() == thorns,
    "the game's own outline, a frame of ours in the button")
check(alert._width == 42 and alert._height == 42 and alert._points[1][2] == thorns.Icon, "as big as the game makes it: 1.4 times the icon, around it")
check(alert.ProcLoop:IsPlaying() and alert.ProcStartFlipbook._alpha == 0, "its loop runs, no burst")
alert.ProcLoop:Stop()
alert:Hide()
alert:Show()
check(alert.ProcLoop:IsPlaying(), "shown again, it runs again")
check(Line(thorns, TEXT.auraFramesShow).checked() == true and Line(thorns, TEXT.auraImportant).checked() == true, "both ticked")
Line(thorns, TEXT.auraImportant).fn()
Line(thorns, TEXT.auraFramesShow).fn()
check(not ns.options.auraShow[782] and not Glows(thorns), "both off")
Line(thorns, TEXT.auraImportant).fn()
check(ns.options.auraWhite[782] == "Thorns" and Glows(thorns), "Important: on the list, and a glow in the game's list")
check(Line(thorns, TEXT.auraImportant).checked() == true, "its line ticked")
check(thorns.Icon._alpha ~= 0.25 and not Glows(bear), "the others as they were")
-- A fight the icon showed in hides its size, past the fight's end: the first outline of a Victorious after a fight.
local bearWidth, bearHeight = bear.Icon._width, bear.Icon._height
bear.Icon._width, bear.Icon._height = W.Secret(), W.Secret()
Line(bear, TEXT.auraImportant).fn()
check(not ns.off and Glows(bear) and Alert(bear)._width == 42 and Alert(bear)._height == 42,
    "an icon whose size the game hides gets its outline at the size of the game's icons, and Combat stays on")
Line(bear, TEXT.auraImportant).fn()
bear.Icon._width, bear.Icon._height = bearWidth, bearHeight
Line(thorns, TEXT.auraUnimportant).fn()
check(ns.options.auraBlack[782] and not ns.options.auraWhite[782] and not Glows(thorns),
    "Unimportant: off the other list, no glow")
check(thorns.Icon._alpha == List.FADED and thorns.Count._alpha == List.FADED and thorns.Duration._alpha == List.FADED,
    "faded, in its parts: the button's own alpha is the game's warning flash")
check(thorns._alpha ~= List.FADED, "the button itself is not touched")
Line(thorns, TEXT.auraUnimportant).fn()
check(not ns.options.auraBlack[782] and thorns.Icon._alpha == 1, "clicked again: no mark")

Line(thorns, TEXT.auraHidden).fn()
check(ns.options.auraHidden[782] and thorns.Icon._alpha == 0, "Hidden: out of sight")
check(mid._points[1][4] == slotOf[1] and bear._points[1][4] == slotOf[2] and thorns._points[1][4] == slotOf[3],
    "and last in the list: no hole, and showing it moves nothing under the mouse")
thorns._scripts.OnEnter(thorns)
check(thorns.Icon._alpha == 1, "the mouse on the list shows it")
thorns._scripts.OnLeave(thorns)
check(thorns.Icon._alpha == 1, "as the buttons have gaps it stays a moment")
mid._scripts.OnEnter(mid)
W.Wait(List.LINGER + 0.1)
check(thorns.Icon._alpha == 1, "on to the next button: it stays")
mid._scripts.OnLeave(mid)
W.Wait(List.LINGER + 0.1)
check(thorns.Icon._alpha == 0, "off the list: gone again")

-- In a fight: by the aura's instance where the game tells it, else plain at the first change.
W.Combat(true)
secret = true
Rebuilt()
check(thorns.Icon._alpha == 0, "in a fight it stays by its instance")
local inFight = Click(thorns)
check(inFight[1].title == "Thorns" and inFight[7].text == TEXT.auraLists,
    "and its menu opens: it was on before the fight")
inFight = Click(bear)
inFight[2].fn()
check(ns.options.auraWhite[5487] == "Bear" and Glows(bear), "and marks it in the fight")
inFight = Click(bear)
inFight[2].fn()
local info = thorns.buttonInfo
thorns.buttonInfo = { index = 1, auraInstanceID = W.Secret() }
Rebuilt()
check(thorns.Icon._alpha == 1 and mid._points[1][4] == slotOf[2] and thorns._points[1][4] == slotOf[1],
    "the instance hidden too: the list as the game has it, as a mark on the wrong aura is worse than none")
inFight = Click(thorns)
check(inFight[1].title == TEXT.auraFight and inFight[2].text == TEXT.auraLists, "and the menu says the game keeps it")
thorns.buttonInfo = info
secret = false
W.Combat(false)
W.Fire("PLAYER_REGEN_ENABLED")
check(thorns.Icon._alpha == 0, "marked again after the fight")
Line(thorns, TEXT.auraHidden).fn()
check(thorns._points[1][4] == slotOf[1] and thorns.Icon._alpha == 1, "no mark: back in its place")
Core.Set("Combat", "buffList", false)
check(Click(thorns) == nil, "off: the game's list as it is")
Core.Set("Combat", "buffList", true)
check(Click(thorns) ~= nil, "on again")

-------------------------------------------------------------------------------
--  What shows on a bar
-------------------------------------------------------------------------------
local function Row(which)
    local found = 0
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Frame" and widget._parent ~= UIParent and widget._height == Bars.SIZE
            and widget._points[1] and widget._points[1][1] == "CENTER" then
            found = found + 1
            if found == (which or 1) then return widget end
        end
    end
end
Update()
local row = Row()
check(row and not row:GetParent():IsShown() or row == nil or row._width <= 1, "the buff on you: nothing to remind of")
on.player.Thorns = nil
Update()
row = Row()
check(row ~= nil and row._width == Bars.SIZE, "gone: its icon shows, the bar one icon wide")
local mark = Reminders.Make({ id = 1126, name = "Mark of the Wild", icon = 136078, harmful = false, unit = "player" })
Update()
check(row._width == 2 * Bars.SIZE + Bars.GAP, "two missing: the bar as wide as both")
on.player.Thorns = THORNS
Update()
check(row._width == Bars.SIZE, "one back: it shrinks to what shows")
Reminders.Take(mark)
Update()
check(row._width == 1, "nothing to show: no width")

-- The offset: shown already that long before it runs out.
THORNS.expirationTime = W.clock + 30
reminder.early = 10
Update()
check(row._width == 1, "30 seconds left, offset 10: not yet")
W.Wait(21)
Update()
check(row._width == Bars.SIZE, "9 left: shown already")
W.Wait(5)
THORNS.expirationTime = 0
check(Bars.Left(9.2) == "10" and Bars.Left(90) == "2m", "seconds up to a minute, then minutes")
Update()
check(row._width == 1, "without an end it never shows early")
reminder.early = 0

-- Active, in or out of a fight, in a city, dead.
reminder.missing, reminder.active = false, true
Update()
check(row._width == Bars.SIZE, "display when active: shown while it is on")
on.player.Thorns = nil
Update()
check(row._width == 1, "and not when it is gone")
reminder.missing, reminder.active = true, false
reminder.combat = "in"
Update()
check(row._width == 1, "only inside of combat: not out of one")
W.Combat(true)
Update()
check(row._width == Bars.SIZE, "and shown in one")
reminder.combat = "out"
Update()
check(row._width == 1, "only outside of combat: not in one")
W.Combat(false)
Update()
check(row._width == Bars.SIZE, "and shown out of one")
reminder.combat, reminder.noRest = "any", true
resting = true
Update()
check(row._width == 1, "don't show in resting areas")
resting, reminder.noRest = false, false
Update()
check(row._width == Bars.SIZE, "out of them it shows")
-- When class in group: you or one of your party or raid (a druid yourself).
reminder.class = "WARRIOR"
W.Fire("GROUP_ROSTER_UPDATE")
Update()
check(row._width == 1, "When class in group, a warrior: none in your group, not shown")
units.party1 = { name = "Brakk", class = "WARRIOR", level = 60, health = 900, most = 900 }
W.Fire("GROUP_ROSTER_UPDATE")
Update()
check(row._width == Bars.SIZE, "a warrior in your party: shown")
units.party1.class = "PRIEST"
Update()
check(row._width == Bars.SIZE, "read again at most once a second")
W.Wait(1)
Update()
check(row._width == 1, "then a priest in the warrior's place: not shown")
reminder.class = "DRUID"
Update()
check(row._width == Bars.SIZE, "a druid: you are one, your own class counts")
units.party1, reminder.class = nil, nil
W.Fire("GROUP_ROSTER_UPDATE")
Update()
check(row._width == Bars.SIZE, "no class needed: shown again")

-------------------------------------------------------------------------------
--  A fight with the auras hidden by the game
-------------------------------------------------------------------------------
on.player.Thorns = THORNS
THORNS.expirationTime, THORNS.duration = W.clock + 100, 600
reminder.early = 10
Update()
check(row._width == 1, "on before the fight")
check(reminder.lasts and reminder.lasts.Thorns == 600, "how long it lasts, kept for a fight")
W.Combat(true)
secret = true
Update()
check(row._width == 1, "hidden in the fight: known from before, still there")
W.Wait(92)
Update()
check(row._width == Bars.SIZE, "its time as known before: the offset works in a fight")
W.Wait(20)
Update()
check(row._width == 1, "past its end and the game still has it: renewed in the fight, and hidden again")
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", W.Secret())
Update()
check(row._width == 1, "a cast the game hides tells nothing")
on.player.Thorns = nil
reminder.early = 0
W.spells[782] = { name = "Thorns" }
C_Spell.GetSpellName = function(id) return W.spells[id] and W.spells[id].name end
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 782)
W.Wait(599)
Update()
check(row._width == 1, "your own cast of it, told: there again, as long as it lasted when last read")
W.Wait(2)
Update()
check(row._width == Bars.SIZE, "then it ran out, by the clock")
reminder.lasts = nil
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 782)
W.Wait(1000)
Update()
check(row._width == 1, "how long not known: there until the fight ends")
secret = false
W.Combat(false)
on.player.Thorns = THORNS
THORNS.expirationTime = 0
Update()
reminder.early = 0
plainSpells[782] = true
secret = true
on.player.Thorns = nil
Update()
check(row._width == Bars.SIZE, "a spell the game never hides is read as ever in a fight")
secret, plainSpells = false, {}
on.player.Thorns = THORNS
Update()

-------------------------------------------------------------------------------
--  On your target; a debuff; the unit frames' icons
-------------------------------------------------------------------------------
local sunder = Reminders.Make({ id = 7386, name = "Sunder Armor", icon = 132363, harmful = true, unit = "target" })
check(sunder.missing and not sunder.active, "a debuff on another: shown when missing")
Update()
check(row._width == 1, "no target: nothing")
units.target = { name = "Hogger", level = 11, enemy = true, health = 100, most = 100 }
UnitCanAttack = function(_, unit) return unit == "target" end
UnitExists = function(unit) return units[unit] ~= nil end
Update()
check(row._width == Bars.SIZE, "a target without it: shown")
on.target["Sunder Armor"] = { name = "Sunder Armor", spellId = 7386, auraInstanceID = 20, expirationTime = 0 }
Update()
check(row._width == 1, "with it: gone")
Reminders.Take(sunder)
local soul = Reminders.Make({ id = 6788, name = "Weakened Soul", icon = 136000, harmful = true, unit = "player" })
check(soul.active and not soul.missing, "a debuff on you: shown when active")
Reminders.Take(soul)

-------------------------------------------------------------------------------
--  Watched on several units: you and your target at once, one icon
-------------------------------------------------------------------------------
do
    local function Number() -- the seconds at the foot of the bar's first icon, "" for none
        for _, widget in ipairs(W.frames) do
            if widget._parent == row and widget.left and widget._shown then return widget.left._text end
        end
    end
    local hogger, attack = units.target, UnitCanAttack
    units.target = { name = "Brakk", level = 60, health = 900, most = 900 }
    UnitCanAttack = function() return false end
    local THEIRS = { name = "Thorns", spellId = 782, icon = 136104, auraInstanceID = 21, expirationTime = 0, duration = 600 }
    on.player.Thorns, on.target = THORNS, { Thorns = THEIRS }
    THORNS.expirationTime = 0
    reminder.units = { "player", "target" }
    Update()
    check(row._width == 1, "watched on you and your target, both have it: nothing to remind of")
    check(Reminders.Find({ name = "Thorns", harmful = false, unit = "target" }) == reminder
        and Reminders.Make({ id = 782, name = "Thorns", icon = 136104, harmful = false, unit = "target" }) == reminder
        and #Reminders.List() == 1, "the aura on your target is the same reminder's: none made twice")
    on.target.Thorns = nil
    Update()
    check(row._width == Bars.SIZE and Number() == "", "your target without it: shown, one icon")
    on.player.Thorns = nil
    Update()
    check(row._width == Bars.SIZE, "both without it: still one icon")
    on.player.Thorns, on.target.Thorns = THORNS, THEIRS
    THORNS.expirationTime, THEIRS.expirationTime = W.clock + 20, W.clock + 30
    reminder.early = 40
    Update()
    check(row._width == Bars.SIZE and Number() == "20", "both within the offset: the seconds of the one that runs out first")
    on.player.Thorns = nil
    Update()
    check(row._width == Bars.SIZE and Number() == "", "one wants it for missing it: no seconds")
    -- An older reminder of a single unit: read into the list, its one unit watched.
    local old = { id = 782, name = "Thorns", icon = 136104, harmful = false, unit = "target", bar = Reminders.Bars()[1],
                  missing = true, active = false, early = 0, combat = "any", noRest = false, own = false }
    table.insert(Reminders.List(), old)
    on.player.Thorns, on.target.Thorns = nil, nil
    Update()
    check(old.unit == nil and #old.units == 1 and old.units[1] == "target"
        and ns.ReminderEditor.Watched(old) == TEXT.reminderUnits.target, "an older reminder's single unit: read into the list")
    check(old.bar == nil and Only(old, Reminders.Bars()[1]) and ns.ReminderEditor.Where(old) == "Aura bar 1",
        "its single bar too: its one place")
    check(row._width == 2 * Bars.SIZE + Bars.GAP, "and watched: your target lacks it")
    on.target.Thorns = THEIRS
    Update()
    check(row._width == Bars.SIZE, "your target has it: the older one goes, the other still misses yours")
    Reminders.Take(old)
    -- A fight: each unit as known before, on its own.
    on.player.Thorns = THORNS
    THORNS.expirationTime, THEIRS.expirationTime = W.clock + 100, W.clock + 50
    reminder.early = 10
    Update()
    check(row._width == 1, "on both, far from their ends")
    W.Combat(true)
    secret = true
    W.Wait(41)
    Update()
    check(row._width == Bars.SIZE and Number() == "9", "hidden in the fight: your target's as known before, within the offset")
    W.Wait(10)
    Update()
    check(row._width == 1, "past its end on your target and the game still has it there: renewed, yours still running")
    on.player.Thorns = nil
    W.Wait(50)
    Update()
    check(row._width == Bars.SIZE and Number() == "", "past your end and gone from you: missing on you alone")
    W.Fire("UNIT_SPELLCAST_SENT", "player", "Brakk", "cast-9", 782)
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-9", 782)
    Update()
    check(row._width == Bars.SIZE, "your Thorns cast at your target: on it, not on you")
    W.Fire("UNIT_SPELLCAST_SENT", "player", "Someone Else", "cast-10", 782)
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-10", 782)
    Update()
    check(row._width == 1, "one cast at none of them: on each it watches, as with a single unit")
    reminder.missing, reminder.active = false, true
    W.Fire("PLAYER_TARGET_CHANGED")
    Update()
    check(row._width == Bars.SIZE and Number():match("m$"), "another target: what was known of it forgotten, yours kept")
    reminder.missing, reminder.active, reminder.early = true, false, 0
    secret = false
    W.Combat(false)
    units.target, UnitCanAttack, on.target = hogger, attack, {}
    on.player.Thorns, THORNS.expirationTime = THORNS, 0
    reminder.units = { "player" }
    Update()
    check(row._width == 1, "you alone again")
end

-------------------------------------------------------------------------------
--  Watched on your group: a role, everyone, one of your party (Saneroki, 2026-11-09); the bar's icons take the mouse
--  out of a fight, as the buffs do; an older reminder's Health bars
-------------------------------------------------------------------------------
do
    local roles = rawget(_G, "UnitGroupRolesAssigned")
    units.party1 = { name = "Tess", level = 60, health = 900, most = 900 }
    units.party2 = { name = "Rolf", level = 60, health = 900, most = 900 }
    on.party1, on.party2 = { Thorns = THORNS }, { Thorns = THORNS }
    UnitGroupRolesAssigned = function(unit) return unit == "party2" and "TANK" or "DAMAGER" end
    reminder.units = { "tank" }
    Update()
    check(row._width == 1, "watched on the tank: the tank has it, nothing to remind of")
    on.party2.Thorns = nil
    Update()
    check(row._width == Bars.SIZE, "the tank without it: shown")
    reminder.units = { "party1" }
    Update()
    check(row._width == 1, "on Party 1, who has it: nothing")
    reminder.units = { "group" }
    Update()
    check(row._width == Bars.SIZE, "on everyone: one of them lacks it, one icon")
    units.party2.offline = true
    Update()
    check(row._width == 1, "the one without it offline: counts for none")
    units.party2.offline = nil
    reminder.inGroup = true
    Update()
    check(row._width == 1, "Only in groups: out of a group, not shown")
    IsInGroup = function() return true end
    Update()
    check(row._width == Bars.SIZE, "in one: shown")
    IsInGroup = function() return false end
    reminder.inGroup, reminder.ignore = false, true
    Update()
    check(row._width == 1, "Ignore everywhere: not shown, its settings kept")
    reminder.ignore = false
    Update()
    -- Its icon, out of a fight: the aura's tooltip, a click its menu, the marks and Edit tracked... on this tracking.
    local icon
    for _, widget in ipairs(W.frames) do
        if widget._parent == row and widget.picture and widget._shown then icon = widget end
    end
    check(icon and icon._mouse == true and icon.reminder == reminder, "out of a fight the bar's icon takes the mouse")
    icon._scripts.OnEnter(icon)
    check(GameTooltip:IsOwned(icon), "the mouse on it: the aura's tooltip")
    icon._scripts.OnLeave(icon)
    W.menus = {}
    icon._scripts.OnMouseUp(icon, "RightButton")
    local menu = W.menus[1]
    check(menu and menu[1].title == "Thorns" and menu[2].text == TEXT.auraImportant and menu[#menu].text == TEXT.auraLists,
        "a click: the aura's menu as a buff's, its marks, last Edit tracked... (it is tracked)")
    menu[2].fn()
    check(ns.options.auraWhite[782] == "Thorns", "a mark put from it")
    menu[2].fn()
    menu[#menu].fn()
    check(ns.ReminderEditor.panel:IsVisible(), "Edit tracked... opens the window on it")
    ns.AuraLists.Hide()
    W.Combat(true)
    Update()
    check(icon._mouse == false, "in a fight: no mouse, clicks go through to the world")
    W.Combat(false)
    Update()
    check(icon._mouse == true, "after it: again")
    EventRegistry:TriggerEvent("EditMode.Enter")
    check(icon._mouse == false, "in Edit Mode: none, the bar is dragged")
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(icon._mouse == true, "and back after it")
    -- Made on the frames: watched on everyone. An older one's Health bars: both frames, on everyone where on no bar.
    local renew = Reminders.Make({ id = 139, name = "Renew", icon = 135953, harmful = false, unit = "player" }, Reminders.GROUP)
    check(Only(renew, Reminders.GROUP) and renew.units[1] == "group" and #renew.units == 1, "made on the group frames: everyone")
    Reminders.Take(renew)
    local older = { id = 1126, name = "Mark of the Wild", icon = 136078, harmful = false, units = { "player" },
                    places = { Reminders.HEALTH }, missing = true, active = false, early = 0, combat = "any" }
    check(Where(older) == Reminders.FRAMES .. " " .. Reminders.GROUP and older.units[1] == "group" and #older.units == 1,
        "an older reminder's Health bars: your unit frames and the group frames, watched on everyone as they showed it")
    local barred = { id = 1126, name = "Mark of the Wild", units = { "player" }, places = { 1, Reminders.HEALTH } }
    check(Where(barred) == "1 " .. Reminders.FRAMES .. " " .. Reminders.GROUP and barred.units[1] == "player",
        "on a bar too: its watch kept, for its bar")
    UnitGroupRolesAssigned = roles
    units.party1, units.party2, on.party1, on.party2 = nil, nil, nil, nil
    on.player.Thorns = THORNS
    reminder.units = { "player" }
    Update()
    check(row._width == 1 and not ns.off, "you alone again, nothing failed")
end

-------------------------------------------------------------------------------
--  On the nameplates: right under each plate, side by side without a gap
-------------------------------------------------------------------------------
do
    local Plates = ns.PlateReminders
    local plates, guids = {}, { nameplate1 = "Creature-1", nameplate2 = "Player-2" }
    local canAttack, guid, same = UnitCanAttack, UnitGUID, UnitIsUnit
    C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
    UnitCanAttack = function(_, unit) return units[unit] ~= nil and units[unit].enemy == true end
    UnitGUID = function(unit) return guids[unit] or guid(unit) end
    local function Plate(unit, info)
        units[unit], on[unit] = info, {}
        local plate = W.NewWidget("Frame", nil, UIParent)
        plate.UnitFrame = W.NewWidget("Frame", nil, plate)
        plate.UnitFrame.HealthBarsContainer = W.NewWidget("Frame", nil, plate.UnitFrame)
        plates[unit] = plate
        W.Fire("NAME_PLATE_UNIT_ADDED", unit)
        return plate
    end
    local function Under(parent) -- our row on it, and how many icons it shows
        for _, widget in ipairs(W.frames) do
            if widget._parent == parent and widget.icons then
                local count = 0
                for _, icon in ipairs(widget.icons) do if icon._shown then count = count + 1 end end
                return widget, widget._shown and count or 0
            end
        end
        return nil, 0
    end
    local wolf = Plate("nameplate1", { name = "Young Wolf", level = 5, enemy = true, health = 50, most = 50 })
    local friend = Plate("nameplate2", { name = "Ally", player = true, level = 60, health = 900, most = 900 })
    check(Under(wolf) == nil and Under(friend) == nil, "nothing on the nameplates: no row made")
    local sunder = Reminders.Make({ id = 7386, name = "Sunder Armor", icon = 132363, harmful = true, unit = "target" },
                                  Reminders.PLATES)
    check(Only(sunder, Reminders.PLATES) and sunder.missing and not sunder.active, "a debuff on the nameplates: shown where missing")
    Update()
    local row, count = Under(wolf)
    local point = row and row._points[1]
    check(count == 1 and point[1] == "TOPLEFT" and point[2] == wolf.UnitFrame.HealthBarsContainer and point[3] == "BOTTOMLEFT"
        and point[4] == 0 and point[5] == 0 and row._width == Plates.SIZE,
        "a foe without it: its icon right under the plate's health bar, no gap")
    check(select(2, Under(friend)) == 0, "a friend: none of your debuffs to miss")
    check(Reminders.Wanted(sunder, { on = false }, "nameplate2", Reminders.GROUP)
        and not Reminders.Wanted(sunder, { on = false }, "nameplate2", Reminders.PLATES),
        "by the place asked: a debuff missing on a friend counts on the health bars, not on a plate")
    on.nameplate1["Sunder Armor"] = { name = "Sunder Armor", spellId = 7386, auraInstanceID = 30, expirationTime = 0 }
    Update()
    check(select(2, Under(wolf)) == 0, "with it: gone")
    on.nameplate1["Sunder Armor"] = nil
    local rend = Reminders.Make({ id = 772, name = "Rend", icon = 132155, harmful = true, unit = "target" }, Reminders.PLATES)
    local mark = Reminders.Make({ id = 1126, name = "Mark of the Wild", icon = 136078, harmful = false, unit = "player" },
                                Reminders.PLATES)
    Update()
    row, count = Under(wolf)
    check(count == 2 and row.icons[1]._points[1][4] == 0 and row.icons[2]._points[1][4] == Plates.SIZE
        and row._width == 2 * Plates.SIZE, "two missing: side by side, no gap between them; a buff not on a foe")
    check(select(2, Under(friend)) == 1, "the buff on a friend who misses it")
    mark.places = { Reminders.Bars()[1], Reminders.PLATES }
    on.player["Mark of the Wild"] = nil
    Update()
    check(select(2, Under(friend)) == 1 and Row()._width == Bars.SIZE,
        "ticked on its bar and the nameplates at once: on both, by the same settings")
    mark.places = { Reminders.PLATES }
    Update()
    check(select(2, Under(friend)) == 1 and Row()._width == 1, "the nameplates alone again: off the bar")
    units.nameplate1.dead = true
    Update()
    check(select(2, Under(wolf)) == 0, "none on the dead")
    units.nameplate1.dead = nil
    -- A fight: the auras hidden, known from before; your cast at your target's plate.
    W.Combat(true)
    secret = true
    Update()
    check(select(2, Under(wolf)) == 2, "in a fight, hidden: as known before it")
    UnitIsUnit = function(a, b) return a == b or (a == "nameplate1" and b == "target") end
    W.spells[7386] = { name = "Sunder Armor" }
    C_Spell.GetSpellName = function(id) return W.spells[id] and W.spells[id].name end
    W.Fire("UNIT_SPELLCAST_SENT", "player", "Young Wolf", "cast-1", 7386)
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 7386)
    check(select(2, Under(wolf)) == 1, "your Sunder Armor at it: on, by your cast")
    W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
    check(select(2, Under(wolf)) == 0, "its plate gone: nothing on it")
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    Update()
    check(select(2, Under(wolf)) == 0, "back in the fight: what was known forgotten, the game hides the rest")
    secret = false
    W.Combat(false)
    Update()
    check(select(2, Under(wolf)) == 2, "after it, read again")
    -- Dressed by the module Nameplates: right under its dress's lowest row, on it.
    local foot = W.NewWidget("Frame", nil, friend)
    rawset(SaneUI, "Nameplates", { Plate = { Foot = function(plate) return plate == friend and foot or nil end } })
    Update()
    row, count = Under(foot)
    check(row and count == 1 and row._points[1][1] == "TOPLEFT" and row._points[1][2] == foot and row._points[1][4] == 0
        and row._points[1][5] == 0, "on a dressed plate: right under the dress, on its foot, no gap")
    SaneUI.Nameplates.off = true
    Update()
    row = Under(friend)
    check(row and row._points[1][2] == friend.UnitFrame.HealthBarsContainer, "the module stood down: under the game's bar again")
    rawset(SaneUI, "Nameplates", nil)
    Core.Set("Combat", "reminders", false)
    check(not row:IsShown(), "off: none on the plates")
    Core.Set("Combat", "reminders", true)
    check(row:IsShown(), "on again")
    for _, made in ipairs({ sunder, rend, mark }) do Reminders.Take(made) end
    check(not row:IsShown(), "none left on the nameplates: the rows go")
    W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
    W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
    units.nameplate1, units.nameplate2, on.nameplate1, on.nameplate2 = nil, nil, nil, nil
    UnitCanAttack, UnitGUID, UnitIsUnit = canAttack, guid, same
end

-------------------------------------------------------------------------------
--  Bars: one at first, more made, deleted
-------------------------------------------------------------------------------
check(#Reminders.Bars() == 1, "one bar by default")
local second = Reminders.AddBar()
local third = Reminders.AddBar()
check(#Reminders.Bars() == 3 and second ~= third, "as many as you make, each its own")
local rage = Reminders.Make({ id = 5487, name = "Bear", icon = 1, harmful = false, unit = "player" })
rage.places = { second }
on.player.Thorns, on.player.Bear = nil, nil
Update()
local rowTwo = Row(2)
check(Row()._width == Bars.SIZE and rowTwo ~= nil and rowTwo._width == Bars.SIZE, "each bar holds its own, apart")
for _, widget in ipairs(W.frames) do
    check(not (widget._template == List.ALERT and widget._parent and widget._parent._parent == rowTwo),
        "no glow on a reminder bar")
end
Reminders.TakeBar(second)
check(#Reminders.Bars() == 2 and Only(rage, Reminders.Bars()[1]), "a bar deleted: its reminders on the first bar left")
Update()
check(Row()._width == 2 * Bars.SIZE + Bars.GAP and not rowTwo:IsVisible(), "and its frame gone")
Reminders.TakeBar(third)
Reminders.TakeBar(Reminders.Bars()[1])
check(#Reminders.Bars() == 1, "the last bar stays")
Reminders.Take(rage)
on.player.Thorns = THORNS
Update()

-------------------------------------------------------------------------------
--  Edit tracked: the list's Reminder tick, the chosen aura's reminder under it
-------------------------------------------------------------------------------
local Editor, Lists = ns.ReminderEditor, ns.AuraLists
local function Inside(widget, parent)
    while widget do
        if widget == parent then return true end
        widget = widget._parent
    end
    return false
end
local function Kind(kind, template, within, outside)
    local found = {}
    for _, widget in ipairs(W.frames) do
        if widget._kind == kind and widget._template == template and (not within or Inside(widget, within))
            and not (outside and Inside(widget, outside)) then
            found[#found + 1] = widget
        end
    end
    return found
end
local function Said(text)
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and widget._text == text and widget:IsVisible() then return true end
    end
    return false
end
-- The list's line of an aura.
local function Of(name)
    for _, widget in ipairs(W.frames) do
        if widget.row and widget.remind and widget._shown and widget.row.name == name then return widget end
    end
end
Editor.Open(reminder)
local panel = Editor.panel
check(panel and panel:IsVisible() and Said(TEXT.listsTitle), "the reminder's settings are a part of Edit tracked, open")
check(Of("Thorns") and Of("Thorns").remind:GetChecked() and Of("Thorns").mark._shown,
    "its aura on the list, its Reminder ticked, chosen")
local ticks, menus = Kind("CheckButton", "UICheckButtonTemplate", panel), Kind("DropdownButton", "WowStyle1DropdownTemplate", panel)
check(#ticks == 8 and #menus == 4 and Said(TEXT.reminderTitle),
    "under the list, titled Edit Tracked conditions: six ticks, the aura's two marks and four dropdowns: where it shows, "
    .. "on whom, combat, which class in your group")
check(ticks[3].words._text == TEXT.reminderRest and TEXT.reminderRest == "Hide in rested areas"
    and ticks[5].words._text == TEXT.reminderInGroup and ticks[6].words._text == TEXT.reminderIgnore,
    "Hide in rested areas, Only in groups and Ignore everywhere, in Saneroki's words")
for at, key in ipairs({ "inGroup", "ignore" }) do
    local tick = ticks[4 + at]
    tick:SetChecked(true)
    tick._scripts.OnClick(tick)
    check(reminder[key] == true, key .. " ticked")
    tick:SetChecked(false)
    tick._scripts.OnClick(tick)
    check(reminder[key] == false, key .. " unticked")
end
check(ticks[7].words._text == TEXT.auraFramesHide and ticks[8].words._text == TEXT.auraFramesShow
    and ticks[7]:IsVisible() and not ticks[7]:GetChecked(),
    "the aura's two marks for the unit frames there too, no columns of the list's any more")
ticks[8]:SetChecked(true)
ticks[8]._scripts.OnClick(ticks[8])
check(ns.options.auraShow[782] == "Thorns" and ticks[8]:GetChecked(), "Prioritize on unit frames ticked: marked")
ticks[7]:SetChecked(true)
ticks[7]._scripts.OnClick(ticks[7])
check(ns.options.auraHide[782] == "Thorns" and not ns.options.auraShow[782] and not ticks[8]:GetChecked(),
    "Hide from unit frames takes its place, as in the menu")
ticks[7]:SetChecked(false)
ticks[7]._scripts.OnClick(ticks[7])
check(not ns.options.auraHide[782] and not ticks[7]:GetChecked(), "and unticked")
check(menus[4].words._text == TEXT.reminderClass and #menus[4]._items == 4 and menus[4]._items[1].text == TEXT.reminderClassAny
    and menus[4]._items[2].text == "Druid" and menus[4]._items[4].text == "Warrior",
    "When class in group: Not needed, then the game's classes by name")
menus[4]._items[2].fn()
check(reminder.class == "DRUID", "a class chosen")
menus[4]._items[1].fn()
check(reminder.class == nil, "and none needed again")
check(ticks[1]:GetChecked() == true and ticks[2]:GetChecked() == false, "as the reminder is set")
ticks[2]:SetChecked(true)
ticks[2]._scripts.OnClick(ticks[2])
check(reminder.active == true, "a tick takes effect at once")
local function Pressed(word)
    for _, button in ipairs(Kind("Button", "UIPanelButtonTemplate", panel)) do
        if button:GetText() == word then return button end
    end
end
local newBar, takeBar = Pressed(TEXT.reminderNewBar), Pressed(TEXT.reminderDeleteBar)
check(takeBar._disabled, "one bar: it cannot be deleted")
local shows = menus[1]._items
check(menus[1].words._text == TEXT.reminderOnBar and #shows == 4 and shows[1].checkbox and shows[4].checkbox
    and shows[1].checked() and not shows[2].checked() and menus[1]._override == "Aura bar 1",
    "Shows on: a tick for each place; the first aura bar ticked, and the dropdown says so")
newBar._scripts.OnClick(newBar)
shows = menus[1]._items
check(#Reminders.Bars() == 2 and Only(reminder, Reminders.Bars()[2]) and not takeBar._disabled
    and menus[1]._override == "Aura bar 2", "a new bar by its button, the reminder on it in place of the first")
check(#shows == 5 and shows[3].text == TEXT.reminderFrames and shows[4].text == TEXT.reminderGroup
    and shows[5].text == TEXT.reminderPlates and shows[2].checkbox and shows[2].checked() and not shows[1].checked(),
    "a tick for each bar, then your unit frames, the party and raid frames (Group frames), the nameplates last")
menus[1]._items[4].fn()
check(Where(reminder) == Reminders.Bars()[2] .. " " .. Reminders.GROUP and takeBar._shown and menus[2]._shown
    and menus[1]._override == "Aura bar 2, Group frames", "the group frames ticked too: on both, both named")
menus[1]._items[2].fn()
check(Only(reminder, Reminders.GROUP) and not takeBar._shown and menus[2]._shown and menus[2].words._shown,
    "its bar unticked, on the group frames alone: no bar of it to delete; Watch on stays, it counts there")
menus[1]._items[4].fn()
check(Only(reminder, Reminders.GROUP) and menus[1]._items[4].checked() and menus[1]._override == "Group frames",
    "the last one unticked: it stays ticked, a reminder shows somewhere")
menus[1]._items[3].fn()
check(Where(reminder) == Reminders.FRAMES .. " " .. Reminders.GROUP and menus[1]._override == "Unit frames, Group frames",
    "your unit frames ticked too, a place of their own")
menus[1]._items[3].fn()
menus[1]._items[5].fn()
check(Where(reminder) == Reminders.GROUP .. " -1" and menus[1]._override == "Group frames, Nameplates"
    and Said(TEXT.reminderOnPlates), "the nameplates ticked too: the window says they watch each plate's unit")
menus[1]._items[4].fn()
check(Only(reminder, Reminders.PLATES) and not takeBar._shown and not menus[2]._shown and Said(TEXT.reminderOnPlates),
    "on the nameplates alone: no bar to delete, no unit to choose, each plate's unit watched")
Update()
check(row._width == 1, "and it is off its bar")
ticks[4]:SetChecked(true)
ticks[4]._scripts.OnClick(ticks[4])
check(reminder.own == true, "only yours, ticked")
ticks[4]:SetChecked(false)
ticks[4]._scripts.OnClick(ticks[4])
menus[1]._items[2].fn()
check(Where(reminder) == Reminders.Bars()[2] .. " -1" and menus[2]._shown and takeBar._shown and not takeBar._disabled,
    "on the new bar too: its unit and Delete bar back")
menus[1]._items[1].fn()
check(Where(reminder) == "1 " .. Reminders.Bars()[2] .. " -1" and menus[1]._override == "Aura bar 1, Aura bar 2, Nameplates",
    "and on the first: in their order whatever the order ticked")
Update()
local function Lit() -- the bars in sight with one icon on them
    local count = 0
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Frame" and widget._parent ~= UIParent and widget._height == Bars.SIZE and widget._points[1]
            and widget._points[1][1] == "CENTER" and widget:IsVisible() and widget._width == Bars.SIZE then
            count = count + 1
        end
    end
    return count
end
check(row._width == Bars.SIZE and Lit() == 2, "one icon on each bar ticked")
local before = #W.menus
takeBar._scripts.OnClick(takeBar)
local asks = W.menus[#W.menus]
check(#W.menus == before + 1 and asks.owner == takeBar and asks[1].title == TEXT.reminderDeleteBar and #asks == 3
    and asks[2].text == "Aura bar 1" and asks[3].text == "Aura bar 2" and #Reminders.Bars() == 2,
    "on two bars, Delete bar asks which: a menu of them, nothing deleted yet")
asks[3].fn()
check(#Reminders.Bars() == 1 and Where(reminder) == "1 -1", "the bar picked deleted; the reminder on the first, and the nameplates")
newBar._scripts.OnClick(newBar)
check(#Reminders.Bars() == 2 and Where(reminder) == Reminders.Bars()[2] .. " -1",
    "a new bar again: the reminder off the first bar onto it, the nameplates kept")
takeBar._scripts.OnClick(takeBar)
check(#W.menus == before + 1 and #Reminders.Bars() == 1 and Where(reminder) == "1 -1",
    "on one bar, Delete bar deletes it at once: the reminder on the first bar left, the nameplates kept")
menus[1]._items[4].fn()
check(#Reminders.Bars() == 1 and Only(reminder, Reminders.Bars()[1]), "the bar deleted by its button, the reminder kept")
local function Watched() return table.concat(reminder.units, " ") end
local watch = menus[2]._items
check(#watch == 12 and watch[1].text == TEXT.reminderUnits.player and watch[2].text == TEXT.reminderUnits.target
    and watch[3].text == TEXT.reminderUnits.focus and watch[1].checkbox and watch[2].checkbox and watch[3].checkbox
    and watch[1].checked() and not watch[2].checked() and menus[2]._override == "You",
    "Watch on: a tick for you, your target and your focus; you ticked, and the dropdown says so")
check(watch[4].text == "Everyone" and watch[5].text == "Tank" and watch[6].text == "Healer" and watch[7].text == "DPS"
    and watch[8].text == "Party 1" and watch[11].text == "Party 4" and watch[11].checkbox and watch[12].text == "Group"
    and #watch[12].sub == 40 and watch[12].sub[1].text == "Group 1" and watch[12].sub[40].text == "Group 40"
    and watch[12].sub[40].checkbox and watch[12].sub.grid,
    "then everyone, the roles, your party 1 to 4, and your raid's Group 1 to 40 in a menu of its own (Saneroki, 2026-11-09)")
menus[2]._items[2].fn()
watch = menus[2]._items
check(Watched() == "player target" and watch[1].checked() and watch[2].checked() and not watch[3].checked()
    and menus[2]._override == "You, Your target", "your target ticked too: both watched, both named")
menus[2]._items[1].fn()
check(Watched() == "target" and not menus[2]._items[1].checked() and menus[2]._override == "Your target",
    "you unticked: your target alone")
menus[2]._items[2].fn()
check(Watched() == "target" and menus[2]._items[2].checked() and menus[2]._override == "Your target",
    "the last one unticked: it stays ticked, a reminder watches someone")
menus[2]._items[3].fn()
menus[2]._items[1].fn()
check(Watched() == "player target focus" and menus[2]._override == "You, Your target, Your focus",
    "all three, in their order whatever the order ticked")
menus[2]._items[2].fn()
menus[2]._items[3].fn()
check(Watched() == "player" and menus[2]._override == "You", "back to you alone")
menus[2]._items[12].sub[3].fn()
menus[2]._items[5].fn()
check(Watched() == "player tank raid3" and menus[2]._override == "You, Tank, Group 3", "a role and a raid member too, named")
menus[2]._items[5].fn()
menus[2]._items[12].sub[3].fn()
check(Watched() == "player", "and off again")
check(menus[3]._items[2].text == TEXT.reminderCombat.out, "only outside of combat, in its words")
menus[3]._items[3].fn()
check(reminder.combat == "in", "chosen")
menus[3]._items[1].fn()
local early = Kind("EditBox", "InputBoxTemplate", panel)[1]
early:SetText("12")
early._scripts.OnTextChanged(early, true)
check(reminder.early == 12, "the offset typed")
reminder.early, reminder.active = 0, false
-- The line's tick: the reminder deleted, the panel says how to make one; ticked again, made.
local thornsLine = Of("Thorns")
thornsLine.remind:SetChecked(false)
thornsLine.remind._scripts.OnClick(thornsLine.remind)
local function Pressable(word) -- a button of the window in sight, by its words
    for _, widget in ipairs(W.frames) do
        if widget._template == "UIPanelButtonTemplate" and widget._text == word and widget:IsVisible() then return widget end
    end
end
check(#Reminders.List() == 0 and Of("Thorns") and Said(TEXT.reminderNone) and Pressable(TEXT.trackAdd),
    "unticked: deleted, the aura stays on the list, chosen, with Add tracking under it")
Of("Thorns").remind:SetChecked(true)
Of("Thorns").remind._scripts.OnClick(Of("Thorns").remind)
reminder = Reminders.List()[1]
check(reminder and reminder.name == "Thorns" and Only(reminder, Reminders.Bars()[1]) and reminder.missing and Said("Thorns")
    and #Kind("CheckButton", "UICheckButtonTemplate", panel) == 8, "ticked: made again, on the first aura bar, its settings shown")
check(TEXT.reminderColumn == "Tracked", "the column's word")
-- The +: the aura tracked once more, a line of its own under the first, chosen, with its own settings.
local function Lines(name) -- the list's lines of an aura, top to bottom
    local found = {}
    for _, widget in ipairs(W.frames) do
        if widget.row and widget.remind and widget._shown and widget.row.name == name then found[#found + 1] = widget end
    end
    return found
end
local function Cross(line)
    for _, widget in ipairs(W.frames) do
        if widget._parent == line and widget._template == "UIPanelCloseButton" then return widget end
    end
end
local thornsLines = Lines("Thorns")
check(#thornsLines == 1 and thornsLines[1].copy and thornsLines[1].icon._points[1][2] == thornsLines[1].copy
    and thornsLines[1].copy._points[1][2] == Cross(thornsLines[1]), "one tracking, one line: its + right of its X")
thornsLines[1].copy._scripts.OnClick(thornsLines[1].copy)
local copy = Reminders.List()[2]
thornsLines = Lines("Thorns")
check(#Reminders.List() == 2 and copy ~= reminder and copy.name == "Thorns" and copy.places ~= reminder.places
    and Where(copy) == Where(reminder) and copy.missing == reminder.missing and #thornsLines == 2 and thornsLines[2].row.reminder == copy
    and thornsLines[2].mark._shown and not thornsLines[1].mark._shown and thornsLines[2].remind:GetChecked(),
    "the +: a copy of its tracking, on a line of its own under it, chosen")
check(copy.units ~= reminder.units and #copy.units == 1 and copy.units[1] == "player", "whom it watches, its own too")
menus[1]._items[3].fn()
menus[1]._items[1].fn()
check(Only(copy, Reminders.GROUP) and Only(reminder, Reminders.Bars()[1]), "the copy's own places, the first's as they were")
thornsLines[1]._scripts.OnMouseUp(thornsLines[1])
menus[1]._items[4].fn()
check(Where(reminder) == "1 -1" and Only(copy, Reminders.GROUP) and thornsLines[1].mark._shown
    and menus[1]._override == "Aura bar 1, Nameplates", "the first line chosen: its own settings under the list")
menus[1]._items[4].fn()
local cross = Cross(thornsLines[2])
cross._scripts.OnClick(cross)
check(#Reminders.List() == 1 and Reminders.List()[1] == reminder and #Lines("Thorns") == 1 and Of("Thorns"),
    "the X on one of two lines: that tracking alone goes")
thornsLines = Lines("Thorns")
thornsLines[1].remind:SetChecked(false)
thornsLines[1].remind._scripts.OnClick(thornsLines[1].remind)
check(#Reminders.List() == 0 and #Lines("Thorns") == 1, "the last one unticked: the line stays, not tracked")
thornsLines[1].copy._scripts.OnClick(thornsLines[1].copy)
reminder = Reminders.List()[1]
check(reminder and reminder.name == "Thorns" and Only(reminder, Reminders.Bars()[1]) and Of("Thorns").remind:GetChecked(),
    "the + on an aura not tracked: its first tracking, on the first aura bar")
-- Any spell by the search: on the list, chosen; its tick, a reminder; on the first aura bar, then the health bars.
W.spells[1126] = { name = "Mark of the Wild" }
C_Spell.GetSpellName = function(id) return W.spells[id] and W.spells[id].name end
local search = Kind("EditBox", "InputBoxTemplate", nil, panel)
search = search[#search]
search:SetText("1126")
search._scripts.OnTextChanged(search, true)
W.Wait(1)
search._scripts.OnEnterPressed(search)
local markLine = Of("Mark of the Wild")
check(markLine and markLine.mark._shown and not markLine.remind:GetChecked() and Said(TEXT.reminderNone),
    "a spell searched, Enter: on the list, chosen, no reminder yet")
local track = Pressable(TEXT.trackAdd)
check(track and markLine.lit._shown and markLine.lit._points[1][2] == markLine.mark
    and markLine.mark._points[2][4] == -Lists.COLUMN * (#Lists.COLUMNS + 2),
    "its Add tracking under the list; the line lit up to its ticks, the cog and Tracked")
track._scripts.OnClick(track)
local mark = Reminders.Named("Mark of the Wild")
check(mark and mark.id == 1126 and Only(mark, Reminders.Bars()[1]) and markLine.remind:GetChecked()
    and #Kind("CheckButton", "UICheckButtonTemplate", panel) == 8 and not track:IsVisible(),
    "Add tracking: made on Aura bar 1, its settings there at once")
menus[1]._items[3].fn()
check(Where(mark) == "1 " .. Reminders.GROUP, "and on the group frames too")
menus[1]._items[1].fn()
check(Only(mark, Reminders.GROUP), "then on them alone")
-- Its X: off the list, every mark and its reminder.
local take
for _, widget in ipairs(W.frames) do
    if widget._parent == Of("Mark of the Wild") and widget._template == "UIPanelCloseButton" then take = widget end
end
take._scripts.OnClick(take)
check(not Reminders.Named("Mark of the Wild") and not Of("Mark of the Wild") and #Reminders.List() == 1,
    "its X: off the list and its reminder gone")
check(#Kind("DropdownButton", "WowStyle1DropdownTemplate") == 4, "one window: no other dropdowns made")
Reminders.Take(reminder)
check(#Reminders.List() == 0, "deleted")
Lists.Hide()

-------------------------------------------------------------------------------
--  Off, standing down
-------------------------------------------------------------------------------
Reminders.Make({ id = 782, name = "Thorns", icon = 136104, harmful = false, unit = "player" })
on.player.Thorns = nil
Update()
check(row:GetParent() and row._width == Bars.SIZE, "shown again")
Core.Set("Combat", "reminders", false)
check(not row:IsVisible(), "off: no bars")
on.player.Thorns = THORNS
check(Click(thorns)[2].text == TEXT.auraImportant, "and no reminder in the menu; the marks stay")
on.player.Thorns = nil
Core.Set("Combat", "reminders", true)
check(row:IsVisible(), "on again")
on.player.Thorns = THORNS
Line(thorns, TEXT.auraUnimportant).fn()
ns.StandDown("a test")
check(Click(thorns) == nil and thorns.Icon._alpha == 1, "standing down: the game's list as it is")

if RETAIL then
    io.write(("Reminders in Retail: all %d checks passed.\n"):format(passed))
    return
end
check(os.execute(("lua5.1 '%s/dev/tests/reminders.lua' retail"):format(root)) == 0, "in Retail the reminders run as that game has it")
io.write(("Reminders: all %d checks passed.\n"):format(passed))
