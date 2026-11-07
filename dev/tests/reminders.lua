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
check(menu and menu[1].title == "Thorns" and menu[2].text == TEXT.trackAdd and menu[3].text == TEXT.auraImportant
    and menu[4].text == TEXT.auraUnimportant and menu[5].text == TEXT.auraHidden and menu[6].text == TEXT.auraFramesShow
    and menu[7].text == TEXT.auraFramesHide and menu[8].text == TEXT.auraLists,
    "a left click: its menu, the spell, Add tracking, the marks")
menu[2].fn()
local list = Reminders.List()
local reminder = list[1]
check(#list == 1 and reminder.name == "Thorns" and reminder.id == 782 and reminder.unit == "player"
    and reminder.bar == Reminders.GROUP, "Add tracking: the reminder is made, on the health bars, of your own aura")
check(reminder.missing and not reminder.active and reminder.early == 0 and reminder.combat == "any", "a buff: shown when missing")
check(ns.options.auraKept[782] == "Thorns" and ns.ReminderEditor.panel and ns.ReminderEditor.panel:IsVisible(),
    "and Edit auras opens on it, the aura on its list")
menu = Click(thorns)
check(menu[2].text == TEXT.trackEdit, "tracked: the menu says Edit tracking")
ns.AuraLists.Hide()
menu[2].fn()
check(#Reminders.List() == 1 and ns.ReminderEditor.panel:IsVisible(), "which opens the window on it, nothing made twice")
ns.AuraLists.Hide()
Reminders.Take(reminder)
Click(thorns)[2].fn()
reminder = Reminders.List()[1]
check(#Reminders.List() == 1 and reminder.bar == Reminders.GROUP, "deleted, then added again")
ns.AuraLists.Hide()
reminder.bar = Reminders.Bars()[1] -- on its bar for what follows

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
check(inFight[1].title == "Thorns" and inFight[2].text == TEXT.trackEdit,
    "and its menu opens: it was on before the fight")
inFight = Click(bear)
inFight[3].fn()
check(ns.options.auraWhite[5487] == "Bear" and Glows(bear), "and marks it in the fight")
inFight = Click(bear)
inFight[3].fn()
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
--  Bars: one at first, more made, deleted
-------------------------------------------------------------------------------
check(#Reminders.Bars() == 1, "one bar by default")
local second = Reminders.AddBar()
local third = Reminders.AddBar()
check(#Reminders.Bars() == 3 and second ~= third, "as many as you make, each its own")
local rage = Reminders.Make({ id = 5487, name = "Bear", icon = 1, harmful = false, unit = "player" })
rage.bar = second
on.player.Thorns, on.player.Bear = nil, nil
Update()
local rowTwo = Row(2)
check(Row()._width == Bars.SIZE and rowTwo ~= nil and rowTwo._width == Bars.SIZE, "each bar holds its own, apart")
for _, widget in ipairs(W.frames) do
    check(not (widget._template == List.ALERT and widget._parent and widget._parent._parent == rowTwo),
        "no glow on a reminder bar")
end
Reminders.TakeBar(second)
check(#Reminders.Bars() == 2 and rage.bar == Reminders.Bars()[1], "a bar deleted: its reminders on the first bar left")
Update()
check(Row()._width == 2 * Bars.SIZE + Bars.GAP and not rowTwo:IsVisible(), "and its frame gone")
Reminders.TakeBar(third)
Reminders.TakeBar(Reminders.Bars()[1])
check(#Reminders.Bars() == 1, "the last bar stays")
Reminders.Take(rage)
on.player.Thorns = THORNS
Update()

-------------------------------------------------------------------------------
--  Edit auras: the list's Reminder tick, the chosen aura's reminder under it
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
check(panel and panel:IsVisible() and Said(TEXT.listsTitle), "the reminder's settings are a part of Edit auras, open")
check(Of("Thorns") and Of("Thorns").remind:GetChecked() and Of("Thorns").mark._shown,
    "its aura on the list, its Reminder ticked, chosen")
local ticks, menus = Kind("CheckButton", "UICheckButtonTemplate", panel), Kind("DropdownButton", "WowStyle1DropdownTemplate", panel)
check(#ticks == 4 and #menus == 3, "under the list: four ticks and three dropdowns: where it shows, on whom, combat")
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
newBar._scripts.OnClick(newBar)
check(#Reminders.Bars() == 2 and reminder.bar == Reminders.Bars()[2] and not takeBar._disabled,
    "a new bar by its button, the reminder on it")
check(#menus[1]._items == 3 and menus[1]._items[3].text == TEXT.reminderGroup,
    "a line for each bar, and the party and raid frames last")
menus[1]._items[3].fn()
check(reminder.bar == Reminders.GROUP and not takeBar._shown and not menus[2]._shown and not menus[2].words._shown,
    "on the health bars: no bar of it to delete, no unit, out of sight")
check(Said(TEXT.reminderOnGroup), "and the window says where it watches")
Update()
check(row._width == 1, "and it is off its bar")
ticks[4]:SetChecked(true)
ticks[4]._scripts.OnClick(ticks[4])
check(reminder.own == true, "only yours, ticked")
ticks[4]:SetChecked(false)
ticks[4]._scripts.OnClick(ticks[4])
menus[1]._items[2].fn()
check(reminder.bar == Reminders.Bars()[2] and menus[2]._shown and takeBar._shown and not takeBar._disabled,
    "on the new bar: its unit and Delete bar back")
takeBar._scripts.OnClick(takeBar)
check(#Reminders.Bars() == 1 and reminder.bar == Reminders.Bars()[1], "the bar deleted by its button, the reminder kept")
check(menus[2]._items[2].text == TEXT.reminderUnits.target, "watched on you, your target or your focus")
menus[2]._items[3].fn()
check(reminder.unit == "focus", "chosen")
menus[2]._items[1].fn()
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
check(reminder and reminder.name == "Thorns" and reminder.bar == Reminders.GROUP and reminder.missing and Said("Thorns")
    and #Kind("CheckButton", "UICheckButtonTemplate", panel) == 4, "ticked: made again, on the raid frames, its settings shown")
check(TEXT.reminderColumn == "Show on healthbars", "the column's word")
-- Any spell by the search: on the list, chosen; its tick, a reminder; on the party and raid frames.
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
    and markLine.mark._points[2][4] < Lists.COLUMN * -5, "its Add tracking under the list; the line lit up to its ticks")
track._scripts.OnClick(track)
local mark = Reminders.Named("Mark of the Wild")
check(mark and mark.id == 1126 and mark.bar == Reminders.GROUP and markLine.remind:GetChecked()
    and #Kind("CheckButton", "UICheckButtonTemplate", panel) == 4 and not track:IsVisible(),
    "Add tracking: made on the health bars, its settings there at once")
menus[1]._items[1].fn()
check(mark.bar == Reminders.Bars()[1], "and put on an aura bar instead")
-- Its X: off the list, every mark and its reminder.
local take
for _, widget in ipairs(W.frames) do
    if widget._parent == Of("Mark of the Wild") and widget._template == "UIPanelCloseButton" then take = widget end
end
take._scripts.OnClick(take)
check(not Reminders.Named("Mark of the Wild") and not Of("Mark of the Wild") and #Reminders.List() == 1,
    "its X: off the list and its reminder gone")
check(#Kind("DropdownButton", "WowStyle1DropdownTemplate") == 3, "one window: no other dropdowns made")
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
