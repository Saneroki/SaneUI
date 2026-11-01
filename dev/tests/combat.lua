-- Runs the Combat module against the stand-in client (wowstub.lua): its window docked at the bottom middle, the
-- middle half of the bottom edge filling the screen, its windows there on Core's board (our own talents and
-- spellbook side by side, each as wide as its share of the game's sizes), a planner Sane UI knows as a window of
-- its own (listed only while it is there, seated in its panel, opened and closed with it), the quest marks beside
-- nameplates, and giving everything back. Our spellbook itself is tried in dev/tests/book.lua, our talents in
-- dev/tests/talents.lua. The look can only be judged in the game. At its end it runs again as Retail loads the module
-- ("retail": W.Play), where neither our spellbook nor our talents are.
-- Usage, from the project folder:  lua5.1 dev/tests/combat.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
local RETAIL = arg[1] == "retail"
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
--  What the module needs of the client
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
function methods:SetRotation(angle) self._rotation = angle end
function methods:SetSwipeColor(...) self._swipe = { ... } end
function methods:SetBlendMode(mode) self._blend = mode end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:IsForbidden() return false end
function methods:GetChildren()
    local children = {}
    for _, widget in ipairs(W.frames) do
        if widget._parent == self and widget._kind ~= "Texture" and widget._kind ~= "FontString" then children[#children + 1] = widget end
    end
    return unpack(children)
end
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
GetBindingKey = function(action) return action == "TOGGLESPELLBOOK" and "P" or nil end
GetBindingText = function(key) return key end
-- The game's addons it loads when first wanted: a function waits for one.
local waiting = {}
EventUtil = { ContinueOnAddOnLoaded = function(name, fn)
    if W.loaded[name] then return fn() end
    waiting[name] = fn
end }

-- The game's micro menu buttons the open buttons click.
TalentMicroButton = W.NewWidget("Button", "TalentMicroButton")
SpellbookMicroButton = W.NewWidget("Button", "SpellbookMicroButton")

-- The game's override bindings (Keys.lua): kept per owner, to look at.
W.overrides = {}
ClearOverrideBindings = function(owner) W.overrides[owner] = nil end
SetOverrideBinding = function(owner, _, key, command)
    W.overrides[owner] = W.overrides[owner] or {}
    W.overrides[owner][key] = command
end

-- The game's paging controls in our spellbook (dev/tests/book.lua tries them): a page of so many.
W.templates.PagingControlsHorizontalTemplate = function(controls)
    controls.PageText = W.NewWidget("FontString", nil, controls)
    controls.currentPage, controls.maxPages = 1, 1
    function controls:GetCurrentPage() return self.currentPage end
    function controls:SetMaxPages(count) self.maxPages = math.max(count, 1) end
    function controls:UpdateControls() end
end
-- WoW: Forever's spellbook and talents, which ours are made after (Combat.lua, ns.Serves): the spells of its flyouts
-- loose in its book, its two specializations each with a talent config of its own. Retail lacks both (W.Play).
C_SpellBook.IsSpellBookItemLooseFlyoutMember = function() return false end
C_SpecializationInfo = { GetCombatConfigIDForSpecGroup = function(group) return 100 + group end }

-- The unit frames and the clean action bars: the game's unit functions, unit watch, frames and main action bar.
local fight = require("combatclient").Install(W)
local units, Unit, watched, divider = fight.units, fight.Unit, fight.watched, fight.divider
-- The module hooks each bar's UpdateDividers, Update and UpdateState and each button's Update and UpdateButtonArt,
-- where the game's bars have them (the newest export: the main bar UpdateDividers alone, the stance bar Update and
-- UpdateState); the stand-in's widgets answer every such name as a call, so the module hooks them all here, and its
-- hooksecurefunc wants a function there: no-ops.
for _, bar in ipairs({ MainActionBar, StanceBar }) do
    bar.UpdateDividers, bar.Update, bar.UpdateState = function() end, function() end, function() end
end
for _, button in ipairs(MainActionBar.actionButtons) do button.Update, button.UpdateButtonArt = function() end, function() end end
units.player = { name = "Droopy", surname = "Fairwind", player = true, class = "WARRIOR", level = 20, health = 850,
                 most = 1000, power = 30, powerMost = 100 }
W.actions[1] = { kind = "spell", id = 6603 } -- the main bar's first button holds an action, its second is empty
if RETAIL then W.Play("retail") end
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Combat == ns and not ns.off, "the module is made and started")
local Board, Edge = ns.Board, Core.Edge

-------------------------------------------------------------------------------
--  In Retail: neither our spellbook nor our talents, so no full screen and the game's keys its own; the quest marks
-------------------------------------------------------------------------------
if RETAIL then
    check(Core.RETAIL and not ns.Serves() and not Board.Present("spellbook") and not Board.Present("talents"),
        "Retail has not the spellbook and talents ours are made after: neither of ours is there")
    check(ns.MouseRings.SPELL == 61304 and ns.MouseRings.holder and ns.MouseRings.holder:IsEventRegistered("SPELL_UPDATE_COOLDOWN"),
        "the rings around the mouse stand in Retail too, on that game's own spell for the global cooldown")
    check(ns.Window.handle == nil and not ns.Window.Full() and not ns.Window.Fill(),
        "no window: the bottom edge fills no screen")
    check(next(W.overrides) == nil and not ns.Keys.Taken() and not ns.Keys.Taken("TOGGLETALENTS"),
        "no key of the game's runs ours: its spellbook and talents keys open its own windows")
    ns.Keys.Press("spellbook")
    ns.Keys.Press("talents")
    check(not ns.off and not ns.Window.Full(), "our own keys (in the game's key bindings) do nothing, and nothing fails")
    local listed = {}
    for _, option in ipairs(Core.described[ns.name].list) do listed[option.key] = true end
    check(listed.questMarks and listed.unitPlayer and listed.unitSize and listed.cleanBars and not listed.keys
        and not listed.expand, "its settings: the unit frames, the action bars and the quest marks")
    local player = ns.Units.KINDS[1].button
    check(player and watched[player] and player.face.level._text == "20" and PlayerFrame._mouse == false
        and TargetFrame._parent ~= UIParent and ns.ActionBars.Clean() and MainActionBar.BorderArt._alpha == 0,
        "the unit frames and the clean action bars, as in Forever")
    Enum.TooltipDataLineType = { QuestTitle = 17, QuestObjective = 8 }
    local plate = W.NewWidget("Frame", nil, UIParent)
    C_NamePlate = { GetNamePlateForUnit = function(unit) return unit == "nameplate1" and plate or nil end }
    C_QuestLog = { UnitIsRelatedToActiveQuest = function() return true end }
    C_TooltipInfo.GetUnit = function() return { lines = { { type = 8, leftText = "Young Wolf slain: 3/8" } } } end
    UnitIsPlayer, UnitName = function() return false end, function() return "Young Wolf" end
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    local mark
    for _, widget in ipairs(W.frames) do if widget._parent == plate and widget.icon then mark = widget end end
    check(mark and mark._shown and mark.icon._texture == ns.QuestMarks.ICONS.kill and mark.count._text == "3/8",
        "the quest marks beside nameplates, as in Forever")
    ns.StandDown("a test")
    check(ns.off and not mark._shown
        and ns.GIVEN_BACK == "no quest marks beside nameplates; the game's own unit, party and raid frames, action, experience, stance and menu bars and damage meter are back, a right click on a buff cancels it, no reminder bars",
        "standing down: the quest marks go, and what is told says so")
    check(PlayerFrame._mouse == true and TargetFrame._parent == UIParent and MainActionBar.BorderArt._alpha == 1,
        "and the game's unit frames and action bars are its own again")
    io.write(("Combat in Retail: all %d checks passed.\n"):format(passed))
    return
end

-------------------------------------------------------------------------------
--  Your party and raid
-------------------------------------------------------------------------------
do
    local Group, Face, Buffs = ns.Group, ns.GroupFace, ns.GroupBuffs
    local deadOf, onlineOf = UnitIsDeadOrGhost, UnitIsConnected -- back as they were at the end: the tests after these use them
    local Marks = Core.HealthMarks
    check(Group.GAP == 0, "units stand edge to edge, no gap between them")
    -- Sizes: within the limits, the unit's own limit first.
    local wide, high = Group.Size(1, 1000, 500, 100)
    check(wide == 100 and high == 100, "a party: as wide as a unit may be, five of them fill the height whoever is there")
    wide, high = Group.Size(2, 1000, 500, 100)
    check(wide == 100 and high == 100, "two groups fit: the same size")
    wide, high = Group.Size(3, 250, 500, 100)
    check(wide == 83 and high == 100, "three do not fit: all share the width, the height stays")
    wide, high = Group.Size(8, 960, 140, 150)
    check(wide == 120 and high == 28, "forty in eight columns share the max width")
    wide, high = Group.Size(8, 100, 30, 150)
    check(wide == Group.LEAST_WIDTH and high == Group.LEAST_HEIGHT, "never smaller than can be read")
    check(ns.options.groupUnitWidth == ns.Units.WIDTH, "a unit at most as wide as the unit frames, at first")

    -- Alone: the window is there, no header, the game's frames away and given back whole.
    PartyFrame = W.NewWidget("Frame", "PartyFrame", UIParent)
    CompactRaidFrameContainer = W.NewWidget("Frame", "CompactRaidFrameContainer", UIParent)
    CompactRaidFrameManager = W.NewWidget("Frame", "CompactRaidFrameManager", UIParent)
    Core.Set(ns.name, "group", false)
    Core.Set(ns.name, "group", true)
    check(PartyFrame._parent ~= UIParent and CompactRaidFrameContainer._parent ~= UIParent,
        "the game's party and raid frames stand out of sight")
    Core.Set(ns.name, "group", false)
    check(PartyFrame._parent == UIParent and CompactRaidFrameContainer._parent == UIParent, "off: back where they were")
    Core.Set(ns.name, "group", true)

    -- A party: going up from the bottom left, the units its header gives them.
    local grouped, raid, members = true, false, 3
    IsInGroup, IsInRaid = function() return grouped end, function() return raid end
    GetNumGroupMembers = function() return members end
    W.members[1] = { "player", "party1", "party2" }
    units.party1 = { name = "Tess", surname = "Brook", player = true, class = "PRIEST", health = 500, most = 1000,
                     power = 40, powerMost = 100, mana = 40, manaMost = 100 }
    units.party2 = { name = "Rolf", surname = "Stone", player = true, class = "WARRIOR", health = 900, most = 1000,
                     power = 10, powerMost = 100 }
    UnitInRange = function() return true, true end
    UnitGroupRolesAssigned = function() return "NONE" end
    Group.Apply()
    local live
    for frame in pairs(W.drivers) do
        if W.drivers[frame].values == Group.SHOWN then live = frame end
    end
    check(live and W.drivers[live].state == "visibility", "the live frames show while you are in a group, by the game's state driver")
    local headers = {}
    for _, widget in ipairs(W.frames) do
        if widget._template == "SecureGroupHeaderTemplate" then headers[#headers + 1] = widget end
    end
    check(#headers == Group.GROUPS and headers[1]:GetAttribute("showParty") and headers[1]:GetAttribute("showRaid")
        and headers[1]:GetAttribute("showPlayer") and headers[3]:GetAttribute("groupFilter") == "3"
        and headers[1]:GetAttribute("point") == "BOTTOM" and headers[1]:GetAttribute("startingIndex") == 1,
        "a header for each raid group, its units going up, the player in the party's")
    local point = headers[2]._points[1]
    check(point[1] == "BOTTOMLEFT" and point[2] == headers[1] and point[3] == "BOTTOMRIGHT" and point[4] == 0,
        "each group a column to the right of the last, touching it")
    local first, second, third = headers[1][1], headers[1][2], headers[1][3]
    check(first._template == "SecureUnitButtonTemplate" and first:GetAttribute("*type2") == "togglemenu"
        and first:GetScript("OnEnter") and first._width == 240 and first._height == 28,
        "its buttons answer as your other frames do, at the size the limits give")
    check(first.face.unit == "player" and second.face.unit == "party1" and second.face.name._text == "Tess Brook"
        and second.face.value._text == "50%", "a face follows its button's unit: the name left, how much health is left right")
    -- Your own slot: no unit frame but the tools' button, and the game's manager out of sight.
    check(first.face.mine and not second.face.mine and first.face.name._text == "Party" and first.face.cog._shown
        and first.face.value._text == "" and first.face.health._value == 850 and not second.face.cog._shown,
        "your own slot: its name is the word Party, the cog instead of the health's words, and otherwise a frame like any other")
    check(first.face.cog._points[1][1] == "RIGHT" and first.face.cog._points[1][4] == -Face.INSET, "the cog at the far right")
    check(CompactRaidFrameManager._parent ~= UIParent, "the game's raid manager at the screen's edge is out of sight")
    local tools
    for _, widget in ipairs(W.frames) do
        if widget._template == "SecureHandlerClickTemplate" and widget._refs then tools = widget end
    end
    check(tools and tools._shown and tools._parent == live and tools._points[1][2] == first and tools._width == ns.GroupTools.COG
        and tools._points[1][4] == -(Face.INSET + Face.ICON / 2)
        and tools:GetAttribute("_onclick"):find("panel:Show", 1, true), "the button lies on the cog alone and opens the panel by the game's secure means")
    check(first:GetAttribute("*type1") == "target" and first:GetAttribute("*type2") == "togglemenu", "the rest of the slot answers as any other's")
    local panel = tools._refs.panel
    check(panel and panel._template == "SecureFrameTemplate" and panel._strata == "DIALOG", "the panel is a protected frame over all")
    local kinds = {}
    for _, widget in ipairs(W.frames) do
        if widget._parent == panel and widget:GetAttribute("type") then
            local kind = widget:GetAttribute("type")
            kinds[kind] = (kinds[kind] or 0) + 1
        end
    end
    check(kinds.raidtarget == 9 and kinds.worldmarker == 9 and kinds.togglemenu == 1 and kinds.click == 4,
        "markers and clear for your target and the ground, the game's menu, and four of the game's own buttons clicked")
    tools:ClearAllPoints()
    W.members[1] = { "party1", "player", "party2" }
    headers[1]:SetAttribute("yOffset", Group.GAP)
    Group.Apply()
    check(first.face.unit == "party1" and not first.face.mine and second.face.mine and tools._points[1][2] == second
        and not first.face.cog._shown and second.face.cog._shown, "the group changed: your slot is another button, the button goes with it")
    W.members[1] = { "player", "party1", "party2" }
    headers[1]:SetAttribute("yOffset", Group.GAP)
    Group.Apply()
    -- A member left in a fight and the next slid into the slot: the header gives the button the same token, and no
    -- event of the unit's tells of its new occupant; the face reads it anew at once, the sizes wait for the fight's end.
    local tess = units.party1
    units.party1 = { name = "Mara", surname = "Vale", player = true, class = "MAGE", health = 700, most = 1000,
                     power = 50, powerMost = 100, mana = 50, manaMost = 100 }
    W.combat = true
    headers[1]:SetAttribute("yOffset", Group.GAP)
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(0)
    check(second.face.unit == "party1" and second.face.name._text == "Mara Vale" and second.face.value._text == "70%"
        and Core.Owed("group frames"), "the group changed in a fight: the slot shows its new member at once, the sizes wait")
    W.combat = false
    units.party1 = tess
    W.Fire("PLAYER_REGEN_ENABLED")
    W.Wait(0)
    check(second.face.name._text == "Tess Brook" and not Core.Owed("group frames"), "after the fight: read again, and the sizes")

    -- The power line, inside the bar: no taller for it.
    Face.Fill(second.face)
    check(second.face.power._shown and second.face.power._value == 40, "no role set: a class that heals shows its mana")
    check(not third.face.power._shown, "no role set: a warrior shows none")
    check(not second.face.role._shown and not third.face.role._shown, "no role set: no role's icon, whatever its class")
    UnitGroupRolesAssigned = function(unit) return unit == "party2" and "TANK" or "DAMAGER" end
    Face.Fill(second.face)
    Face.Fill(third.face)
    check(third.face.power._shown and third.face.power._value == 10 and not second.face.power._shown,
        "by role: a tank's own power where it has no mana, a damage dealer none")
    check(third.face.role._shown and third.face.role._atlas == Face.ROLES.TANK and not second.face.role._shown,
        "a tank's tiny icon, a damage dealer none")
    check(third.face.role._points[1][1] == "TOPLEFT" and third.face.role._parent == third.face.top
        and third.face.role._layer == "BACKGROUND", "in the frame's top left corner, in front of the bar, behind the words")
    check(third.face.role._points[1][4] + Face.ROLE / 2 == Face.INSET + Face.GAP + third.face.markSize / 2,
        "centred on where the raid marker stands")
    UnitGroupRolesAssigned = function(unit) return unit == "party1" and "HEALER" or "NONE" end
    Face.Fill(second.face)
    Face.Fill(third.face)
    check(second.face.role._atlas == Face.ROLES.HEALER and second.face.role._shown and not third.face.role._shown, "a healer's too")
    UnitGroupRolesAssigned = function() return "NONE" end
    Face.Fill(second.face)
    Face.Fill(third.face)

    -- Your own slot shows your own role and raid marker, and the word changes with your group.
    local markOf = GetRaidTargetIndex
    GetRaidTargetIndex = function(unit) return unit == "player" and 3 or nil end
    UnitGroupRolesAssigned = function(unit) return unit == "player" and "HEALER" or "NONE" end
    Face.Fill(first.face)
    check(first.face.raid._shown and first.face.raid._cell == 3 and first.face.role._shown
        and first.face.role._atlas == Face.ROLES.HEALER, "your slot: your raid marker and role, as on any frame")
    local incoming = true
    UnitHasIncomingResurrection = function() return incoming end
    first.face:GetScript("OnEvent")(first.face, "INCOMING_RESURRECT_CHANGED", "player")
    check(first.face.rez._shown, "a resurrection on its way too")
    incoming = false
    first.face:GetScript("OnEvent")(first.face, "INCOMING_RESURRECT_CHANGED", "player")
    first.face:GetScript("OnEvent")(first.face, "UNIT_NAME_UPDATE", "player")
    check(first.face.name._text == "Party" and not first.face.rez._shown, "its name stays the word")
    UnitHasIncomingResurrection = nil
    IsInRaid = function() return true end
    Face.Fill(first.face)
    check(first.face.name._text == ns.TEXT.groupRaid, "in a raid it says Raid")
    IsInRaid = function() return raid end
    GetRaidTargetIndex = markOf
    UnitGroupRolesAssigned = function() return "NONE" end
    Face.Fill(first.face)

    -- A click or @mouseover: nothing of ours takes the mouse from the button.
    check(not second.face._mouse and not second.face.health._mouse, "the face takes no mouse")

    -- The dead, the offline, aggro, a resurrection and a ready check.
    local on = second.face:GetScript("OnEvent")
    local incoming
    UnitHasIncomingResurrection = function(unit) return unit == incoming end
    check(not second.face.rez._shown and second.face.rez._width == Core.HealthMarks.NONE, "no resurrection: no icon, and no room for it")
    incoming = "party1"
    on(second.face, "INCOMING_RESURRECT_CHANGED", "party1")
    second.face._width, second.face._height = 150, 28
    Face.Fit(second.face)
    on(second.face, "INCOMING_RESURRECT_CHANGED", "party1")
    check(second.face.big == 24 and second.face.rez._shown and second.face.rez._width == 24 and second.face.rez._height == 24
        and second.face.rez._atlas == Face.REZ and second.face.rez._parent == second.face.floating,
        "one on its way: the game's icon, big, floating over the name")
    incoming = nil
    on(second.face, "INCOMING_RESURRECT_CHANGED", "party1")
    check(not second.face.rez._shown and second.face.rez._width == Core.HealthMarks.NONE, "it came or stopped: gone")
    local fill = second.face.health
    local green = fill._barColor[1]
    UnitIsDeadOrGhost = function(unit) return unit == "party1" end
    on(second.face, "UNIT_HEALTH", "party1")
    check(fill._value == 1 and fill._max == 1 and fill._barColor[1] == Face.DEAD[1] and second.face.value._text == "Dead",
        "the dead: the bar full and red")
    UnitIsDeadOrGhost = function() return false end
    UnitIsConnected = function(unit) return unit ~= "party1" end
    on(second.face, "UNIT_CONNECTION", "party1")
    check(fill._value == 1 and fill._barColor[1] == Face.OFFLINE[1] and second.face.value._text == "Offline",
        "the offline: the bar full and grey")
    UnitIsConnected = function() return true end
    on(second.face, "UNIT_CONNECTION", "party1")
    check(fill._value == 500 and fill._barColor[1] == green, "back: green, its health")
    W.threat.party1 = 3
    on(second.face, "UNIT_THREAT_SITUATION_UPDATE", "party1")
    check(second.face.border[1]._vertex[1] == 1 and second.face.border[1]._vertex[2] == 0 and second.face.border[1]._vertex[4] == 1,
        "aggro: a solid red border")
    W.threat.party1 = 1
    on(second.face, "UNIT_THREAT_SITUATION_UPDATE", "party1")
    check(second.face.border[1]._vertex[1] == 0, "without it: black")
    W.ready.party1 = "waiting"
    W.Fire("READY_CHECK", "player", 30)
    check(second.face.ready._shown and second.face.ready._atlas == Face.READY.waiting and second.face.ready._width == second.face.big
        and second.face.ready._parent == second.face.floating, "a ready check: its picture, big, floating over the name")
    check(second.face.ready._points[1][2] == second.face.marks.lead and second.face.rez._points[1][2] == second.face.ready
        and second.face.raid._points[1][2] == second.face.level and first.face.cog._shown,
        "from the left dispel, ready check, resurrection; the raid marker stays where it is; your own slot keeps its cog")
    W.Fire("READY_CHECK_FINISHED")
    check(second.face.ready._shown and second.face.ready._atlas == Face.READY.notready, "it ended: who did not answer is not ready")
    W.ready.party1 = nil
    Face.Fill(second.face)
    check(second.face.ready._shown, "and the result stays a while")
    W.Wait(Face.READY_HOLD + 1)
    check(not second.face.ready._shown and second.face.ready._width == Core.HealthMarks.NONE and first.face.cog._shown,
        "then it goes, and takes no room")

    -- Your buffs: a family counts from anyone, and a fight leaves them as they were.
    local auras = {}
    C_UnitAuras.GetAuraDataBySpellName = function(unit, name) return auras[unit] and auras[unit][name] end
    C_Spell = C_Spell or {}
    local spellInfo = C_Spell.GetSpellInfo
    C_Spell.GetSpellInfo = function(name) if name == "Power Word: Fortitude" then return { iconID = 135987 } end end
    local class = UnitClass
    UnitClass = function(unit) if unit == "player" then return "Priest", "PRIEST" end return class(unit) end
    Buffs.Learn()
    check(Buffs.Any() and Buffs.Icons()[1] == 135987, "what you know of your class's buffs")
    local list = {}
    check(Buffs.Missing("party1", list) == 1 and list[1] == 135987, "a member without it is missing it")
    auras.party1 = { ["Prayer of Fortitude"] = {} }
    check(Buffs.Missing("party1", list) == 0, "the group's version counts")
    auras.party1 = nil
    Face.Fill(second.face)
    local roomBefore = second.face.name._width
    Face.Fill(second.face)
    check(second.face.icons[1]._shown and second.face.icons[1]._texture == 135987 and second.face.name._width == roomBefore
        and second.face.icons[1]._parent == second.face.floating, "the icon floats over the name, which keeps its room")
    auras.party1 = { ["Power Word: Fortitude"] = {} }
    local fighting = InCombatLockdown
    InCombatLockdown = function() return true end
    check(Buffs.Missing("party1", list) == nil, "in a fight auras are hidden: nothing is told")
    second.face:GetScript("OnEvent")(second.face, "UNIT_AURA", "party1")
    check(second.face.icons[1]._shown, "and the icon stays as it was")
    InCombatLockdown = fighting
    second.face:GetScript("OnEvent")(second.face, "UNIT_AURA", "party1")
    check(not second.face.icons[1]._shown, "after it, it is read again")
    -- An update that only refreshed what is there is not read again; one that added a buff or took an aura away is.
    auras.party1 = nil
    on(second.face, "UNIT_AURA", "party1", { isFullUpdate = false, updatedAuraInstanceIDs = { 7 } })
    check(not second.face.icons[1]._shown, "an aura refreshed: not read again")
    on(second.face, "UNIT_AURA", "party1", { isFullUpdate = false, removedAuraInstanceIDs = { 7 } })
    check(second.face.icons[1]._shown, "an aura gone: read again, the buff is missing")
    auras.party1 = { ["Power Word: Fortitude"] = {} }
    on(second.face, "UNIT_AURA", "party1", { isFullUpdate = false, addedAuras = { { isHelpful = false } } })
    check(second.face.icons[1]._shown, "a debuff added: not read again")
    on(second.face, "UNIT_AURA", "party1", { isFullUpdate = false, addedAuras = { { isHelpful = true } } })
    check(not second.face.icons[1]._shown, "a buff added: read again, it has it")
    on(second.face, "UNIT_AURA", "party1", { isFullUpdate = true })
    check(not second.face.icons[1]._shown and not ns.off, "all of them anew: read again")
    UnitClass, C_Spell.GetSpellInfo = class, spellInfo
    Buffs.Learn()

    -- A raid of forty: eight columns; a frame too narrow for its health gives that room to the name.
    raid, members = true, 40
    GetRaidRosterInfo = function(index) return "x", 0, math.ceil(index / 5) end
    check(Group.Filled() == 8, "a raid fills a column a group")
    GetRaidRosterInfo = function(index) return "x", 0, index <= 3 and 1 or 4 end
    members = 7
    check(Group.Filled() == 2, "only the groups in use count")
    members = 40
    GetRaidRosterInfo = function(index) return "x", 0, math.ceil(index / 5) end
    -- A face takes its button's size by its anchors, and hears of it by OnSizeChanged.
    local function Sized(button)
        button.face._width, button.face._height = button._width, button._height
        button.face:GetScript("OnSizeChanged")(button.face)
    end
    Group.Apply()
    Sized(second)
    check(second._width == 120 and not second.face.bare and second.face.value._text == "50%", "at forty the units are narrow")
    Core.Set(ns.name, "groupWidth", 480)
    Sized(second)
    check(second._width == 60 and second.face.bare and second.face.value._text == "", "too narrow: no health at all")
    check(second.face.room.right == Face.INSET, "and its room is the name's")
    UnitIsConnected = function(unit) return unit ~= "party1" end
    second.face:GetScript("OnEvent")(second.face, "UNIT_CONNECTION", "party1")
    check(second.face.value._text == "Offline", "Offline is said all the same")
    UnitIsConnected = function() return true end
    Core.Set(ns.name, "groupWidth", 960)
    raid, members = false, 3
    Group.Apply()
    Sized(second)
    check(second._width == 240 and not second.face.bare and second.face.value._text == "50%", "back in a party they are wide again")
    Core.Set(ns.name, "groupHeight", 500)
    check(second._height == 100 and first._height == 100, "a higher window: three in a party are a fifth of it high")
    second._height = 28
    Sized(second)
    Core.Set(ns.name, "groupHeight", 140)

    -- Edit Mode: the preview, no box around it, its settings in the dialog.
    local drawn = {}
    NineSliceUtil = { ApplyLayout = function(container) drawn[container] = true end }
    EventRegistry:TriggerEvent("EditMode.Enter")
    check(W.drivers[live] == nil and not live._shown, "the live frames rest in Edit Mode")
    Core.Set(ns.name, "groupPreview", 40)
    local window
    for _, one in ipairs(Core.Window.All()) do
        if one.options.key == "groupPlace" then window = one end
    end
    check(window and window.box and drawn[window.box], "in Edit Mode it has the box every window has")
    local host, faces = nil, {}
    for _, widget in ipairs(W.frames) do
        if widget.marks and widget._parent._parent == window.frame then
            host = widget._parent
            faces[#faces + 1] = widget
        end
    end
    check(#faces == 40, "forty units for forty")
    local last = faces[40]
    check(last._points[1][4] == 840 and last._points[1][5] == 112 and last._width == 120 and last._height == 28,
        "the last at the top of the eighth column, touching its neighbours")
    local name = faces[2].name._text
    check(faces[1].name._text == ns.TEXT.groupRaid and faces[1].cog._shown and not faces[2].cog._shown, "the first is your own slot")
    local rolled = 0
    for _, face in ipairs(faces) do
        if face.role._shown then rolled = rolled + 1 end
    end
    check(rolled > 0, "made-up tanks and healers show their role")
    Core.Set(ns.name, "groupWidth", 800)
    check(faces[2].name._text == name and faces[2]._width == 100, "a size changed: the same units, narrower")
    Core.Set(ns.name, "groupWidth", 960)
    Core.Set(ns.name, "groupPreview", 7)
    check(faces[7]._shown and not faces[8]._shown and faces[6]._points[1][4] == 240 and faces[7]._height == 28, "seven: two columns")
    Core.Selection.Select(window)
    check(window.settingRows and #window.settingRows.shows == #Group.SETTINGS, "its settings in Edit Mode's dialog")
    window.options.set("groupPreview", 12)
    check(ns.options.groupPreview == 12, "what the dialog sets is the module's")
    Core.Selection.Clear()
    Core.Set(ns.name, "groupPreview", 5)
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(W.drivers[live] and W.drivers[live].values == Group.SHOWN and not host._shown, "after Edit Mode: the live frames again")

    -- Core's marks, on a sample and on a unit whose numbers the game hides.
    local marks = Face.Make(UIParent, true).marks
    marks:Sample({ barrier = 0.25, lost = 0.2, dispel = "Curse" })
    check(marks.barrier._value == 0.25 and marks:Reach(100) == 20, "a sample's barrier and lost part")
    check(marks.icon._shown and marks.icon._atlas == "RaidFrame-Icon-DebuffCurse" and marks.lead._width == marks.options.size,
        "a sample's dispel: the type's icon, what follows it stepping aside")
    marks:Sample({})
    check(marks.barrier._value == 0 and marks:Reach(100) == 0 and not marks.icon._shown
        and marks.lead._width == Marks.NONE, "and none of it")
    local face = headers[1][1].face
    GetUnitTotalModifiedMaxHealthPercent = function() return 0.3 end
    local calc = W.calculator
    calc.amount, calc.clamped, calc.total = 100, false, 100
    face.marks:Set("party1")
    check(face.marks:Reach(100) == 30, "maximum health lost: the bar ends that much earlier")
    check(face.marks.barrier._value == 100 and face.marks.barrier._max == 1000 and face.marks.over._alpha == 0,
        "a barrier that fits: after the health, on the bar's scale")
    calc.amount, calc.clamped, calc.total = 200, true, 450
    face.marks:Heard("party1")
    check(face.marks.barrier._value == 200 and face.marks.over._value == 450 and face.marks.over._alpha == 1,
        "one that does not: what fits, and all of it against the bar's right end")
    GetUnitTotalModifiedMaxHealthPercent = nil
    face.marks:Set(nil)
    check(face.marks:Reach(100) == 0 and face.marks.barrier._value == 0, "no unit, no marks")
    local filter = face.marks.container and face.marks.container._groups[Marks.GROUP]
    check(filter and filter.options.maxFrameCount == 1, "one dispellable aura at most, in a container of the game's")
    Face.Fill(face)
    grouped, raid, members = false, false, 1
    W.members[1] = nil
    headers[1]:SetAttribute("yOffset", Group.GAP) -- the header gives its buttons no units any more
    Group.Apply()
    NineSliceUtil = nil
    UnitIsDeadOrGhost, UnitIsConnected = deadOf, onlineOf
    -- What Edit Mode showed, the game's unit watch would hide again: all but your own frame (you are there).
    for _, kind in ipairs(ns.Units.KINDS) do
        if kind.unit ~= "player" then kind.button:Hide() end
        kind.row.button:Hide()
    end
end

-------------------------------------------------------------------------------
--  The window, docked at the bottom middle
-------------------------------------------------------------------------------
local handle = ns.Window.handle
local frame = handle.frame
check(handle.zone == "BOTTOM" and frame._width == ns.Window.WIDTH and not frame._mouse,
    "its window is docked at the bottom middle at first, and takes no click while small")
frame._left, frame._bottom = (1920 - ns.Window.WIDTH) / 2, 0
local strip = handle.edge.strips.bottom
check(strip and strip:IsShown() and strip._points[1][1] == "BOTTOM" and strip._points[1][2] == UIParent
    and strip._width == 1920 * ns.Window.STRIP and near(strip._height, 2 * 768 / 2160) and strip._strata == "DIALOG",
    "the strip that fills the screen is the middle half of the screen's bottom edge, however wide the window is")
UIParent._width = 1600
W.Fire("DISPLAY_SIZE_CHANGED")
check(strip._width == 800, "another screen size: still half of it")
UIParent._width = 1920
W.Fire("UI_SCALE_CHANGED")
check(strip._width == 960, "another UI scale: still half")


-------------------------------------------------------------------------------
--  The full screen: Core's board, nothing open
-------------------------------------------------------------------------------
local inside, layouts = handle.inside, Board.layouts
-- Where what the full window holds stands, and its layer, as the game gives a child its parent's (the stand-in
-- knows no anchors).
local top = 1080 - Core.Window.BAR
inside._left, inside._bottom, inside._height = 0, 0, top
inside._strata, inside._level = "HIGH", 501
local pad, edge, head = Core.Board.PAD, Core.Board.EDGE, Core.Board.HEAD

local function Push()
    W.Wait(1) -- a while after the strip came under the mouse
    strip:GetScript("OnEnter")(strip)
    W.cursorX, W.cursorY = 960, 500 -- the mouse goes away again: the next push counts
    W.Wait(Edge.LOOK)
end
local function Stand()
    frame._group:Run(1)
    W.Wait(0)
end
local function Back()
    frame._group:Run(1)
    handle:Place()
    frame._left, frame._bottom = (1920 - ns.Window.WIDTH) / 2, 0
end
-- A panel's body (a rect of the board), as a window seated there has it.
local function Body(rect)
    return { rect[1] + edge, rect[2] + head + edge, rect[3] - 2 * edge, rect[4] - head - 2 * edge }
end
-- A window of that size seated in a room of the board: as large as fits, never larger, in its middle.
local function Seated(window, room, width, height)
    local scale = math.min(room[3] / width, room[4] / height, 1)
    local point = window._points[1]
    return Core.Lent(window) and near(window._scale, scale) and #window._points == 1 and point[1] == "TOPLEFT"
        and point[2] == UIParent and near(point[4] * scale, room[1] + (room[3] - width * scale) / 2)
        and near(point[5] * scale, top - room[2] - (room[4] - height * scale) / 2)
end
local function In(key) return Body(layouts.rects[key]) end


Push()
check(handle.edge.full and not layouts.standing, "the mouse pushed against the middle of the bottom edge fills the screen; the board waits until it stands")
Stand()
local talents, book = layouts.panels.talents, layouts.panels.spellbook
local hasTalents = Board.Present("talents")
check(layouts.standing and layouts:Has("spellbook") and book and book:IsShown()
    and (not hasTalents or (layouts:Has("talents") and talents and talents:IsShown())),
    "standing, Core's board holds our own talents and spellbook")
check(book.title._text == ns.TEXT.spellbook and (not hasTalents or talents.title._text == ns.TEXT.talents),
    "each panel is headed with its name")
if hasTalents then
    local rects = layouts.rects
    local room = 1920 - 3 * pad
    local talentsWidth = math.floor(room * 1218 / (1218 + ns.Book.WIDE) + 0.5)
    check(rects.talents[1] == pad and rects.talents[3] == talentsWidth and rects.spellbook[1] == 2 * pad + talentsWidth
        and rects.spellbook[3] == room - talentsWidth and rects.talents[4] == top - 2 * pad,
        "the first layout: the talents at the left, the spellbook at the right, each as wide as its share of the game's sizes")
end
check(not Board.Present("planner"), "without a talent planner Sane UI knows, there is no planner's window to add")
Push()
check(not handle.edge.full, "back to its size")
Back()

-------------------------------------------------------------------------------
--  Your spellbook and talents keys open ours
-------------------------------------------------------------------------------
local owner
for each, bindings in pairs(W.overrides) do if bindings.P then owner = each end end
check(owner and W.overrides[owner].P == ns.Keys.COMMANDS.spellbook and ns.Keys.Taken(),
    "at the login, the key of the game's spellbook (P) runs our own key")
ns.Keys.Press("spellbook")
check(handle.edge.full, "pressed: the full screen comes")
Stand()
check(layouts:Has("spellbook"), "with the spellbook on it")
ns.Keys.Press("spellbook")
check(not handle.edge.full, "pressed again: back to its size, as the game's key toggles its window")
Back()
Core.Set(ns.name, "keys", false)
check(W.overrides[owner] == nil and not ns.Keys.Taken(), "the switch off: the game's keys open the game's windows")
Core.Set(ns.name, "keys", true)
check(W.overrides[owner] and W.overrides[owner].P == ns.Keys.COMMANDS.spellbook, "on again: ours")
ns.Keys.Press("pet")
check(not handle.edge.full, "without a pet's spellbook the pet book's key does nothing, as the game's")
-- A key while the screen may not fill (Edit Mode): what it asked for does not wait for a full screen that comes
-- another way.
C_SpellBook.HasPetSpells = function() return 1 end -- a pet with its spellbook from here on
PetHasSpellbook = function() return true end
Core.EditMode.active = true
ns.Keys.Press("pet")
Core.EditMode.active = false
check(not handle.edge.full, "in Edit Mode a key fills no screen")
Push()
Stand()
check(handle.edge.full and ns.Book.Chosen() == "line1", "the next full screen comes as it is: the book not at the pet's tab")
-- The full screen's search box: what is typed reaches its windows (the book shows what it finds).
local box = handle.bar.box
handle.bar.find:GetScript("OnClick")(handle.bar.find) -- the search opened over the title bar
box:SetText("frost")
box:GetScript("OnTextChanged")(box)
check(Board.layouts.search == "frost" and ns.Book.Chosen() == nil, "what is typed into the full screen's search box reaches its windows")
-- The pet book's key: the book at the pet's tab, the search left and its box emptied, the screen staying full
-- where it showed another; pressed again at the pet's tab, back to its size.
ns.Keys.Press("pet")
box:GetScript("OnTextChanged")(box) -- the game's box tells its change by itself
check(handle.edge.full and ns.Book.Chosen() == "pet" and box:GetText() == "" and Board.layouts.search == "",
    "the pet book's key: the book at the pet's tab, the search box emptied")
check(not box:IsShown() and handle.bar.find:IsShown(), "and closed as Esc closes it: the title and the layouts' tabs back")
ns.Keys.Press("pet")
check(not handle.edge.full, "pressed again there: back to its size, as the game's key toggles its window")
Back()

-------------------------------------------------------------------------------
--  A talent planner Sane UI knows: a window of its own
-------------------------------------------------------------------------------
-- Its folder, window and functions as Core knows them (Neighbours.lua), so this file names no addon.
local known = Core.Neighbours.KNOWN.talents
check(Core.Neighbours.Window("talents") == nil, "while it is not installed, there is no planner")
local planner
local opens, closes = 0, 0
_G[known.api] = { UI = {
    [known.open] = function()
        opens = opens + 1
        planner = planner or W.NewWidget("Frame", known.window, UIParent)
        _G[known.window] = planner
        planner:SetSize(1000, 640)
        planner._strata = "HIGH"
        planner:Show()
    end,
    [known.close] = function()
        closes = closes + 1
        if planner then planner:Hide() end
    end,
} }
W.loaded[known.addon] = true
local handleOf = Core.Neighbours.Window("talents")
check(handleOf and handleOf.title == known.title and not handleOf:Shown(), "installed and loaded: Core gives a handle on it")
check(Board.Present("planner"), "now its window is there to add to the full screen")

Push()
Stand()
layouts:Toggle("planner") -- the dropdown Windows ticks it: on the layout
W.Wait(0)
local plannerPanel = layouts.panels.planner
check(layouts:Has("planner") and plannerPanel and plannerPanel:IsShown() and plannerPanel.title._text == ns.TEXT.planner,
    "ticked in the dropdown, the planner gets a panel of its own")
-- Its body where the board put it (the stand-in knows no anchors); laid out again, the planner is seated a frame later.
plannerPanel.body._left, plannerPanel.body._bottom, plannerPanel.body._width, plannerPanel.body._height = 100, 100, 800, 500
ns.Window.Reboard()
W.Wait(0)
check(opens >= 1 and planner and planner:IsShown() and Core.Lent(planner), "its panel shown, the planner opens and is seated in it")
Push()
check(not handle.edge.full and closes >= 1 and not planner:IsShown() and not Core.Lent(planner),
    "the window goes back: the planner is given back and closes")
Back()
_G[known.api].UI[known.open]() -- opened by its own command while the window is small
W.Wait(0)
check(handle.edge.full, "opened any way of its own while its panel is on the layout, the full screen comes with it")
Stand()
-------------------------------------------------------------------------------
--  Quest marks beside nameplates: as the game says it in the creature's tooltip data
-------------------------------------------------------------------------------
local questMark -- a mark shown at the end, looked at again after standing down
do
    local QuestMarks = ns.QuestMarks
    Enum.TooltipDataLineType = { QuestTitle = 17, QuestObjective = 8 }
    local plates, related, lines = {}, {}, {}
    C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
    C_QuestLog = { UnitIsRelatedToActiveQuest = function(unit) return related[unit] or false end }
    C_TooltipInfo.GetUnit = function(unit) return { lines = lines[unit] or {} } end
    UnitIsPlayer = function(unit) return unit == "nameplate9" end
    UnitName = function(unit) return unit == "nameplate1" and "Young Wolf" or "Kobold Miner" end
    plates.nameplate1 = W.NewWidget("Frame", nil, UIParent)
    plates.nameplate1.UnitFrame = W.NewWidget("Frame", nil, plates.nameplate1)
    plates.nameplate2 = W.NewWidget("Frame", nil, UIParent)
    related.nameplate1, related.nameplate2 = true, true
    lines.nameplate1 = { { type = 17, leftText = "Wolves Across the Border" }, { type = 8, leftText = "Young Wolf slain: 3/8" } }
    lines.nameplate2 = { { type = 17, leftText = "Kobold Candles" }, { type = 8, leftText = "Large Candle: 1/8" } }
    local function Mark(plate)
        for _, widget in ipairs(W.frames) do if widget._parent == plate and widget.icon then return widget end end
    end
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
    local wolf, kobold = Mark(plates.nameplate1), Mark(plates.nameplate2)
    check(wolf and wolf._shown and wolf.icon._texture == QuestMarks.ICONS.kill and wolf.count._text == "3/8"
        and wolf._points[1][2] == plates.nameplate1.UnitFrame, "a creature an objective names: the sword beside its plate, the count left of it")
    check(kobold and kobold._shown and kobold.icon._texture == QuestMarks.ICONS.loot and kobold.count._text == "1/8",
        "one the game ties to a quest whose objective names something else: the sack, to loot it")
    lines.nameplate1[2] = { type = 8, leftText = "Young Wolf slain: 8/8", completed = true }
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(not wolf._shown and kobold._shown, "the objective done (the quest log changed): its mark goes, the others stay")
    related.nameplate2 = nil
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(not kobold._shown, "the game says it no longer belongs to a quest: no mark")
    related.nameplate2 = true
    W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(not kobold._shown, "its plate gone: nothing of it is looked at")
    plates.nameplate9 = W.NewWidget("Frame", nil, UIParent)
    related.nameplate9 = true
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate9")
    check(not Mark(plates.nameplate9), "a player's plate: none")
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
    check(kobold._shown, "shown again on the plate the game hands out again")
    Core.Set(ns.name, "questMarks", false)
    check(not kobold._shown, "the setting Quest marks on nameplates off: none")
    local reads = 0
    C_TooltipInfo.GetUnit = function(unit) reads = reads + 1 return { lines = lines[unit] or {} } end
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(reads == 0, "and nothing of the game's tooltip data is read meanwhile")
    Core.Set(ns.name, "questMarks", true)
    check(kobold._shown, "on again: there")
    questMark = kobold
end



-------------------------------------------------------------------------------
--  Unit frames: ours for you, your target and your focus, the game's out of sight
-------------------------------------------------------------------------------
local unitButtons = {}
do
    UnitName, UnitIsPlayer = fight.UnitName, fight.UnitIsPlayer -- as before the quest marks' plates
    local Units, Text = ns.Units, ns.UnitText
    for index, kind in ipairs(Units.KINDS) do unitButtons[kind.unit] = kind.button end
    local player, target, focus = unitButtons.player, unitButtons.target, unitButtons.focus
    check(player and target and focus and player._template == "SecureUnitButtonTemplate"
        and player:GetAttribute("unit") == "player" and target:GetAttribute("unit") == "target"
        and player:GetAttribute("*type1") == "target" and player:GetAttribute("*type2") == "togglemenu",
        "three secure unit buttons: a click targets, a right click opens the game's menu")
    check(watched[player] and watched[target] and watched[focus], "the game's unit watch shows each while its unit is there")
    local face = player.face
    check(face.name._text == "" and face.level._text == "20" and face.value._text == "850 | 85%",
        "your frame: your level, no name, your health and how much is left")
    local green = ns.UnitBar.GREEN
    check(face.health._max == 1000 and face.health._value == 850 and face.health._barColor[1] == green[1]
        and face.health._barColor[2] == green[2], "the bar green, not in your class's colour")
    local rage = face.powers[1]
    check(rage._shown and rage._max == 100 and rage._value == 30 and rage.value._text == "30 | 30%"
        and not face.powers[2]._shown and player._height == Units.HEIGHT + Units.POWER and Units.POWER == Units.HEIGHT / 2,
        "your rage in a bar under it, half as high, its words on the right: \"30 | 30%\"")
    check(near(rage._points[1][5], -(Units.HEIGHT + Core.Pixels(face, 1))) and rage._points[2][3] == "TOPRIGHT",
        "the power bar a pixel under the health bar, inside the outline")
    face._width, face._height = Units.WIDTH, Units.HEIGHT -- the stand-in places nothing: as large as its button
    Text.Layout(face)
    check(face.level._points[1][1] == "LEFT" and face.value._points[1][1] == "RIGHT" and face.name._points[1][1] == "LEFT"
        and face.name._points[1][2] == face.raid and near(face.name._points[2][4], -(face.room.right + Text.GAP)),
        "the level on the left, the name after it from the left up to the health, the health on the right")
    check(PlayerFrame.PlayerFrameContainer._alpha == 0 and PlayerFrame.PlayerFrameContent._alpha == 0
        and PlayerFrame._mouse == false and PlayerFrame._parent == UIParent,
        "the game's own frame out of sight and takes no clicks; it stays where it is, with what hangs on it")
    check(TargetFrame._parent ~= UIParent and TargetFrame._parent == FocusFrame._parent and not TargetFrame._parent._shown,
        "the game's target and focus frames stand in a hidden frame of ours")

    -- Your target: a creature, an elite, marked with a skull.
    units.target = { name = "Kobold Miner", level = 22, health = 40, most = 120, foe = true, reaction = 2,
                     classification = "elite", raid = 8 }
    W.Fire("PLAYER_TARGET_CHANGED")
    target:Show() -- the game's unit watch: your target is there
    local foe = target.face
    check(foe.name._text == "Kobold Miner" and foe.value._text == "40 | 33%" and foe.raid._shown and foe.raid._cell == 8,
        "your target: its name, health, and its raid marker beside its level")
    check(foe.rank == ns.UnitBar.RANKS.elite and foe.health._barColor[2] == green[2] and foe.health._barColor[1] == green[1],
        "green for a foe too; the gold line of an elite")
    -- One width for every frame: the border on its edge, an elite's gold line inside it, the bar inside both.
    local pixel = Core.Pixels(foe, 1)
    check(target._width == Units.WIDTH and target._width == player._width and foe.border[1]._points[1][4] == 0
        and near(foe.rankLine[1]._points[1][4], pixel) and foe.rankLine[1]._shown
        and near(foe.health._points[1][4], 2 * pixel) and near(face.health._points[1][4], pixel)
        and near(foe.halo[1][1]._points[1][4], -pixel),
        "an elite's frame as wide as any: its rank's line inside the border, only the glow beyond the edge")
    -- Your target's target: a row under your target's frame while there is one, as a cast bar under a nameplate.
    local row = foe.rowButton
    check(row and row._template == "SecureUnitButtonTemplate" and row:GetAttribute("unit") == "targettarget"
        and row:GetAttribute("*type1") == "target" and row._parent == target and row._points[1][3] == "BOTTOMLEFT"
        and watched[row] and not foe.rowShown and not foe.row._shown,
        "its target's row: a secure button right under the frame, shown by the unit watch, none while it has no target")
    units.targettarget = { name = "Droopy", surname = "Fairwind", player = true, health = 600, most = 1000 }
    row:Show() -- the game's unit watch: your target has a target
    local calm = ns.UnitBar.CALM
    check(foe.rowShown and foe.row._shown and foe.rowName._text == "Droopy Fairwind" and foe.row._value == 600
        and foe.row._barColor[1] == calm[1] and foe.row._barColor[2] == calm[2] and foe.row._barColor[3] == calm[3]
        and foe.rowName._justify == "CENTER",
        "it shows under the frame: in the nameplates' light yellow of a neutral creature, its name alone in the middle")
    check(near(foe.border[2]._points[1][5], -(Units.POWER + Units.ROW)) and near(foe.health._points[2][5], -Units.HEIGHT)
        and near(foe.powers[1]._points[2][5], -(Units.HEIGHT + Units.POWER)),
        "the frame's outline goes round all, its power bar square at its bottom over the row")
    units.targettarget.health = 300
    foe.row._scripts.OnUpdate(foe.row, Units.POLL)
    check(foe.row._value == 300, "read again while it shows (the game sends no events of a target's target)")
    row:Hide()
    check(not foe.rowShown and not foe.row._shown and near(foe.border[2]._points[1][5], -Units.POWER),
        "gone: the frame alone again, its outline round its health and power")
    -- The game hides the row while the frame is out of sight (your target gone): no OnHide then; the frame looks again
    -- as it shows.
    foe.rowShown = true
    row._shown = false
    target:Hide()
    target:Show()
    check(not foe.rowShown and not foe.row._shown, "a row hidden while its frame was out of sight is gone when it shows")
    -- The other way round: the game's unit watch shows the row while the frame is out of sight (its unit seen before
    -- the frame's); the row's OnShow runs with the frame's as the frame shows, and the row is looked at then.
    target:Hide() -- the game's unit watch: your target gone
    units.targettarget = { name = "Droopy", surname = "Fairwind", player = true, health = 600, most = 1000 }
    row:Show() -- the game's unit watch: its target, while the frame is out of sight
    check(not foe.rowShown and not foe.row._shown, "a row shown while its frame is out of sight: nothing yet")
    target:Show() -- the game's unit watch: your target is there
    check(foe.rowShown and foe.row._shown and foe.rowName._text == "Droopy Fairwind",
        "as the frame shows, the row's OnShow runs with the frame's: the row is there")
    row:Hide()
    units.targettarget = nil
    units.target.health = 30
    W.Fire("UNIT_HEALTH", "target")
    check(foe.value._text == "30 | 25%" and foe.health._value == 30, "its health as it goes, heard from its own events")
    -- The health's room is measured once for a most: a beat of health measures nothing, another most once more.
    local measures, Width = 0, Text.Width
    Text.Width = function(...) measures = measures + 1 return Width(...) end
    units.target.health = 25
    W.Fire("UNIT_HEALTH", "target")
    W.Fire("UNIT_HEALTH", "target")
    check(foe.value._text == "25 | 20%" and measures == 0 and foe.valueMost == 120, "a beat of health measures nothing: the room is known for that most")
    units.target.most = 240
    W.Fire("UNIT_MAXHEALTH", "target")
    check(measures == 1 and foe.valueMost == 240 and foe.value._text == "25 | 10%", "another most: measured once more")
    Text.Width = Width
    units.target.health, units.target.most = 30, 120
    W.Fire("UNIT_MAXHEALTH", "target")
    units.target.tanking = true
    W.Fire("UNIT_THREAT_LIST_UPDATE", "target")
    check(foe.glow._alpha == 1, "the glow while you have its aggro")
    units.target.tanking = false
    W.Fire("UNIT_THREAT_LIST_UPDATE", "target")
    check(foe.glow._alpha == 0, "and none while you do not")
    -- In a fight the game hides its health and your threat: shown as they are, nothing computed with them.
    local hidden = W.Secret()
    units.target.health, units.target.tanking = hidden, hidden
    W.Fire("UNIT_HEALTH", "target")
    W.Fire("UNIT_THREAT_LIST_UPDATE", "target")
    check(not ns.off and foe.health._value == hidden and type(foe.value._text) == "table"
        and foe.value._text.abbreviated == hidden and foe.glow._alpha.from == hidden,
        "hidden health and threat: the bar, the text and the glow take them as they are")
    units.target.health, units.target.tanking, units.target.dead = 0, false, true
    W.Fire("UNIT_HEALTH", "target")
    check(foe.value._text == ns.UnitText.DEAD, "a dead unit: Dead in place of its health")
    units.target.dead = false
    units.target.raid = nil
    W.Fire("RAID_TARGET_UPDATE")
    check(not foe.raid._shown and foe.raid._width == Core.HealthMarks.NONE, "its marker taken off: none, and no room kept")

    -- Edit Mode: a frame whose unit is not there shows a sample, to be placed; after it, the unit watch again.
    EventRegistry:TriggerEvent("EditMode.Enter")
    check(not watched[focus] and focus._shown and focus.face.sample and focus.face.name._text == ns.TEXT.samples.focus
        and focus.face.level._text == "20", "in Edit Mode your focus's frame shows as a sample, named for it")
    check(MicroMenu._alpha == 1 and StanceBar._parent ~= UIParent,
        "the game's menu bar shows in Edit Mode, to be placed; its stance bar stays gone")
    check(focus.face.rowShown and focus.face.rowName._text == ns.TEXT.samples.focustarget
        and player.face.rowShown and player.face.rowName._text == ns.TEXT.samples.pet,
        "and the rows under the frames too, named for what they stand for")
    check(player.face.cast._shown and player.face.cast.sample and player.face.cast.text._text == ns.TEXT.samples.cast
        and player.face.breath._shown and player.face.breath.label._text == ns.TEXT.samples.breath
        and focus.face.cast._shown and target.face.cast._shown and target.face.cast.text._text == ns.TEXT.samples.cast
        and not target.face.breath, "every frame's cast as a sample, your breath on your own frame alone")
    check(not target.face.sample and target.face.name._text == "Kobold Miner", "a frame whose unit is there shows it")
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(watched[focus] and not focus.face.sample and watched[focus.face.rowButton],
        "after Edit Mode the unit watch shows it again, and its row")
    check(MicroMenu._alpha == 0, "and the menu bar rests out of sight again")
    check(not player.face.cast._shown and not player.face.cast.sample and not target.face.cast._shown
        and not player.face.breath._shown,
        "and your cast and breath only while they run")
    focus.face.rowButton:Hide() -- the game's unit watch: your focus has no target
    player.face.rowButton:Hide() -- nor you a pet
    -- Edit Mode put the full screen back to its place (as every window of Core's): full again for what follows.
    if not handle.edge.full then
        Push()
        Stand()
    end

    -- The settings: each frame on or off, their size.
    Core.Set(ns.name, "unitFocus", false)
    check(not focus._shown and not watched[focus] and FocusFrame._parent == UIParent,
        "Your focus's frame off: ours hidden, the game's back")
    Core.Set(ns.name, "unitFocus", true)
    check(watched[focus] and FocusFrame._parent ~= UIParent, "on again: ours, the game's away")
    Core.Set(ns.name, "unitPlayer", false)
    check(PlayerFrame.PlayerFrameContainer._alpha == 1 and PlayerFrame._mouse == true and not player._shown,
        "Your frame off: the game's own frame as it was")
    Core.Set(ns.name, "unitPlayer", true)
    player:Show() -- the game's unit watch: you are there
    -- Your pet: a row under your frame; the game's pet frame by its alpha and clicks (its layout re-parents it).
    local pet = player.face.rowButton
    check(pet:GetAttribute("unit") == "pet" and watched[pet] and PetFrame._alpha == 0 and PetFrame._mouse == false
        and PetFrame._parent == PlayerFrame, "your pet's row under your frame, the game's pet frame out of sight")
    check(not PlayerFrame.PlayerFrameContent.HealthBar._motion and not PetFrameHappiness._mouse and not PetFrameHappiness._motion,
        "what lies under the game's frames takes no mouse either: nothing of them stands in the way")
    units.pet = { name = "Wolf", health = 80, most = 100, powerType = 2, powerToken = "FOCUS", power = 50, powerMost = 100 }
    pet:Show()
    check(player.face.rowName._text == "Wolf" and player.face.row._value == 80 and player.face.row._barColor[2] == green[2],
        "your pet: its name and health, green")
    do
        local face, power = player.face, player.face.rowPower
        local slots = face.slots * Units.POWER
        check(pet._height == Units.ROW + Units.ROW_POWER and power._shown and power._value == 50 and power._max == 100
            and power.value._text == "50 | 50%" and near(power._points[1][5], -(Units.HEIGHT + slots + Units.ROW + Core.Pixels(face, 1)))
            and near(face.border[2]._points[1][5], -(slots + Units.ROW + Units.ROW_POWER)),
            "your pet's resource under its health, inside the outline, its button over both")
        units.pet.power = 20
        face.row._scripts.OnUpdate(face.row, Units.POLL)
        check(power._value == 20 and power.value._text == "20 | 20%", "read again while it shows")
        units.pet.powerMost = 0
        face.row._scripts.OnUpdate(face.row, Units.POLL)
        check(not power._shown and near(face.border[2]._points[1][5], -(slots + Units.ROW)), "a pet without one: its health alone")
        units.pet.powerMost = 100
        face.row._scripts.OnUpdate(face.row, Units.POLL)
        check(power._shown and not target.face.rowPower, "and only your pet has one")
    end
    Core.Set(ns.name, "unitPet", false)
    check(not watched[pet] and not pet._shown and PetFrame._alpha == 1 and PetFrame._mouse == true
        and not player.face.rowShown, "Your pet off: no row, the game's pet frame back")
    Core.Set(ns.name, "unitPet", true)
    check(watched[pet] and PetFrame._alpha == 0, "on again")
    Core.Set(ns.name, "unitTargetTarget", false)
    check(not watched[target.face.rowButton] and watched[target], "Your target's target off: no row, the frame stays")
    Core.Set(ns.name, "unitTargetTarget", true)
    units.pet = nil
    -- A druid: your frame keeps two power slots, mana always, a form's power under it.
    units.player.class, units.player.powerType, units.player.powerToken = "DRUID", 3, "ENERGY"
    units.player.power, units.player.powerMost, units.player.mana, units.player.manaMost = 80, 100, 2400, 3000
    ns.Units.Apply()
    check(player._height == Units.HEIGHT + 2 * Units.POWER and face.powersShown == 2
        and face.powers[1].value._text == "2.4k | 80%" and face.powers[2].value._text == "80 | 80%" and face.powers[2]._shown,
        "a druid in cat form: mana in the first bar, energy under it")
    local kinds = face.kinds
    units.player.power = 60
    W.Fire("UNIT_POWER_UPDATE", "player")
    check(face.kinds == kinds and #kinds == 2 and face.powers[2].value._text == "60 | 60%", "a beat of power: the kinds are kept, the bar follows")
    units.player.powerType, units.player.powerToken, units.player.power, units.player.powerMost = 0, "MANA", 2400, 3000
    W.Fire("UNIT_DISPLAYPOWER", "player")
    check(face.powersShown == 1 and not face.powers[2]._shown and face.powers[1].value._text == "2.4k | 80%"
        and player._height == Units.HEIGHT + 2 * Units.POWER,
        "out of the form: the mana bar alone (the button keeps its size: it is changed out of a fight only)")
    check(face.kinds ~= kinds and #face.kinds == 1, "another power: the kinds anew")
    units.player.class, units.player.powerType, units.player.powerToken = "WARRIOR", 1, "RAGE"
    units.player.power, units.player.powerMost, units.player.mana, units.player.manaMost = 30, 100, nil, nil
    ns.Units.Apply()
    check(player._height == Units.HEIGHT + Units.POWER and face.powers[1].value._text == "30 | 30%", "a warrior again: one bar")

    -- Your cast and the game's timers on you as part of your frame, in place of the game's bars.
    do
        local Cast, bar, timers = ns.UnitCast, face.cast, face.timers
        local pixel = Core.Pixels(face, 1)
        local function Hears(frame, event) return (frame:IsEventRegistered(event)) end
        local function Tick() bar._scripts.OnUpdate(bar, 0) end
        local function Casting(id)
            W.cast = { name = "Fireball", icon = 135812, starts = W.clock * 1000, ends = (W.clock + 2.5) * 1000, id = id, spell = 133 }
            W.Fire("UNIT_SPELLCAST_START", "player", id, 133)
        end
        local function Below() return -face.border[2]._points[1][5] end
        local function Above() return face.border[1]._points[1][5] end
        local function Over()
            W.Wait(Cast.HOLD)
            Tick()
        end
        check(not Hears(PlayerCastingBarFrame, "UNIT_SPELLCAST_START") and not Hears(PlayerCastingBarFrame, "UNIT_SPELLCAST_INTERRUPTIBLE")
            and not Hears(PlayerCastingBarFrame, "PLAYER_ENTERING_WORLD") and not Hears(OverlayPlayerCastingBarFrame, "UNIT_SPELLCAST_STOP")
            and not Hears(MirrorTimerContainer, "MIRROR_TIMER_START") and Hears(MirrorTimerContainer, "MIRROR_TIMER_STOP"),
            "the game's cast bars and timers hear nothing start: they never show")
        check(not bar._shown and not bar.on and near(Above(), 0) and near(Below(), Units.POWER), "no cast: nothing above your frame")
        Casting("cast-1")
        local ends = W.cast.ends
        check(bar._shown and bar.text._text == "Fireball" and bar.icon._texture == 135812 and bar.timer._text == "2.5"
            and bar.fill._min == W.cast.starts and bar.fill._max == ends and bar.fill._barTexture == Cast.ART.cast
            and bar.fill._reverse == false, "your cast: its icon, name and seconds left, filling in the game's art")
        check(near(Above(), Units.ROW) and near(Below(), Units.POWER) and near(bar._points[1][5], Units.ROW - pixel)
            and near(bar._points[2][5], 0) and near(face.health._points[1][5], -pixel),
            "as part of your frame: directly above your health, a pixel apart, inside the frame's outline")
        check(near(face.roof._points[1][5], Units.ROW), "the auras stand on it")
        W.Fire("UNIT_SPELLCAST_FAILED", "player", "cast-2", 116)
        W.Fire("UNIT_SPELLCAST_INTERRUPTED", "player", "cast-2", 116)
        check(bar.cast and not bar.cast.held and bar.text._text == "Fireball", "what else you tried while casting changes nothing")
        W.Wait(1)
        Tick()
        check(bar.timer._text == "1.5" and bar.fill._value == W.clock * 1000, "the seconds go down, the bar fills")
        W.cast = nil
        W.Fire("UNIT_SPELLCAST_STOP", "player", "cast-1", 133)
        check(bar._shown and bar.cast.held and bar.fill._value == ends and bar.timer._text == "", "done: full, for a moment")
        Over()
        check(not bar._shown and not bar.on and near(Above(), 0) and near(face.roof._points[1][5], 0), "then gone, the outline and the auras back")
        Casting("cast-3")
        W.cast = nil
        UnitNameFromGUID = function() return "Kobold Miner" end
        W.Fire("UNIT_SPELLCAST_INTERRUPTED", "player", "cast-3", 133, "Creature-1")
        W.Fire("UNIT_SPELLCAST_STOP", "player", "cast-3", 133)
        check(bar.fill._barTexture == Cast.ART.broken and bar.fill._value == 1 and bar.text._text == Cast.BY:format("Kobold Miner"),
            "interrupted: red, by whom, whatever the game says after it")
        Over()
        check(not bar._shown, "and gone")
        Casting("cast-4")
        W.cast = nil
        W.Fire("UNIT_SPELLCAST_FAILED", "player", "cast-4", 133)
        check(not bar._shown, "failed: gone at once")
        W.channel = { name = "Drain Life", icon = 136169, starts = W.clock * 1000, ends = (W.clock + 5) * 1000, spell = 689 }
        W.Fire("UNIT_SPELLCAST_CHANNEL_START", "player", "x", 689)
        check(bar._shown and bar.fill._reverse == true and bar.fill.background._atlas == Cast.ART.channel and bar.text._text == "Drain Life",
            "a channel empties, in its own art")
        W.channel = nil
        W.Fire("UNIT_SPELLCAST_CHANNEL_STOP", "player", "x", 689, "Creature-1")
        check(bar.fill._barTexture == Cast.ART.broken, "a channel someone stopped: red")
        Over()
        GetUnitEmpowerStageDuration = function() return 500 end
        GetUnitEmpowerHoldAtMaxTime = function() return 1000 end
        local began = W.clock * 1000
        W.channel = { name = "Fire Breath", icon = 1, starts = began, ends = began + 3000, spell = 2, empowered = true, stages = 2 }
        bar.fill._width = 200
        W.Fire("UNIT_SPELLCAST_EMPOWER_START", "player", "x", 2)
        check(bar.fill._reverse == false and bar.fill._max == began + 4000 and bar.lines[1]._shown and bar.lines[2]._shown
            and near(bar.lines[1]._points[1][4], 25) and near(bar.lines[2]._points[1][4], 50),
            "an empowered cast fills on to its hold, a line where each stage ends")
        W.channel = nil
        W.Fire("UNIT_SPELLCAST_EMPOWER_STOP", "player", "x", 2, false, "Creature-1")
        check(bar.fill._barTexture == Cast.ART.broken and not bar.lines[1]._shown, "stopped before it was done: red")
        Over()
        GameRulesUtil = { ShouldShowPlayerCastBar = function() return false end }
        Casting("cast-5")
        check(not bar._shown, "where the game's rules take your cast bar away, ours too")
        GameRulesUtil, W.cast = nil, nil

        local first, second, third, health = face.breath, timers[1], timers[2], face.health
        check(first._level == health._level + 1 and first._level < face.top._level and not first.background._shown,
            "your breath lies between your health and the frame's words, nothing behind its fill")
        W.mirrorLeft.BREATH = 60000
        local height = Below()
        W.Fire("MIRROR_TIMER_START", "BREATH", 60000, 60000, -1, 0, "Breath")
        check(first._shown and first.label._text == "Breath" and first.left._text == "60" and first._max == 60
            and first._barTexture == ns.UnitTimers.ART.BREATH and first._barColor[4] == ns.UnitTimers.SHEER
            and near(Below(), height),
            "your breath: over your health, in the game's bubbles, sheer, what it is and the seconds left; the frame no higher")
        check(first._points[1][2] == health and first.ends[1]._texture == health.ends[1]._texture
            and first.ends[2]._texture == health.ends[2]._texture, "and as big and as round as the health bar")
        W.mirrorLeft.BREATH = 41500
        first._scripts.OnUpdate(first, 0)
        check(first._value == 41.5 and first.left._text == "42", "going down as the game says")
        W.Fire("MIRROR_TIMER_PAUSE", "BREATH", 1)
        W.mirrorLeft.BREATH = 20000
        first._scripts.OnUpdate(first, 0)
        check(first._value == 41.5, "held while the game holds it")
        Casting("cast-6")
        W.Fire("MIRROR_TIMER_START", "EXHAUSTION", 30000, 60000, -1, 0, "Fatigue")
        check(second._shown and second.label._text == "Fatigue" and second._barTexture == ns.UnitTimers.ART.EXHAUSTION
            and second._barColor[4] == 1 and first._shown and near(Above(), Units.ROW + Units.POWER)
            and near(Below(), Units.POWER) and near(second._points[1][5], Units.ROW + Units.POWER - pixel),
            "any other timer above your cast, solid, in the game's art for it; your breath stays over your health")
        W.Fire("MIRROR_TIMER_START", "FEIGNDEATH", 30000, 60000, -1, 0, "Feign Death")
        check(third._shown and third._barTexture == ns.UnitTimers.ART.FEIGNDEATH
            and near(Above(), Units.ROW + 2 * Units.POWER) and near(third._points[1][5], Units.ROW + 2 * Units.POWER - pixel),
            "two at once, one over the other")
        W.Fire("MIRROR_TIMER_STOP", "EXHAUSTION")
        check(not second._shown and third._shown and near(third._points[1][5], Units.ROW + Units.POWER - pixel),
            "one stopped: the other moves down")
        W.Fire("MIRROR_TIMER_STOP", "FEIGNDEATH")
        W.Fire("MIRROR_TIMER_STOP", "BREATH")
        check(not first._shown, "your breath over: your health alone")
        W.mirror[1] = { "BREATH", 30000, 60000, -1, 0, "Breath" }
        W.Fire("PLAYER_ENTERING_WORLD")
        check(first._shown and first.left._text == "30", "after a loading screen the game is asked again")
        W.mirror[1] = nil
        W.Fire("MIRROR_TIMER_STOP", "BREATH")

        Core.Set(ns.name, "unitCast", false)
        local heard, unit = PlayerCastingBarFrame:IsEventRegistered("UNIT_SPELLCAST_START")
        check(heard and unit == "player" and Hears(OverlayPlayerCastingBarFrame, "UNIT_SPELLCAST_STOP")
            and Hears(PlayerCastingBarFrame, "PLAYER_ENTERING_WORLD") and not bar._shown
            and not Hears(MirrorTimerContainer, "MIRROR_TIMER_START"),
            "Your cast bar off: the game's hears again, for you alone; your breath stays ours")
        Core.Set(ns.name, "unitCast", true)
        check(bar._shown and bar.cast and not Hears(PlayerCastingBarFrame, "UNIT_SPELLCAST_START"), "on again, with the cast under way")
        Core.Set(ns.name, "unitBreath", false)
        check(Hears(MirrorTimerContainer, "MIRROR_TIMER_START") and Hears(MirrorTimerContainer, "PLAYER_ENTERING_WORLD"),
            "Your breath bar off: the game's hears again")
        W.Fire("MIRROR_TIMER_START", "BREATH", 60000, 60000, -1, 0, "Breath")
        check(not first._shown, "and ours stays away")
        Core.Set(ns.name, "unitBreath", true)
        W.cast = nil
        W.Fire("UNIT_SPELLCAST_STOP", "player", "cast-6", 133)
        Over()
        Core.Set(ns.name, "unitPlayer", false)
        check(Hears(PlayerCastingBarFrame, "UNIT_SPELLCAST_START") and Hears(MirrorTimerContainer, "MIRROR_TIMER_START"),
            "Your frame off: the game's cast bar and timers with the game's frame")
        Core.Set(ns.name, "unitPlayer", true)
        player:Show() -- the game's unit watch: you are there
        check(not Hears(PlayerCastingBarFrame, "UNIT_SPELLCAST_START") and not ns.off, "on again, and nothing failed")
    end

    -- Your target's and focus's casts: the same bar, directly above their health.
    do
        local Cast, foe, bar = ns.UnitCast, target.face, target.face.cast
        local mine = player.face.cast
        local function Above() return foe.border[1]._points[1][5] end
        local function Foe(cast)
            cast.name, cast.icon, cast.starts, cast.ends = "Shadow Bolt", 136197, W.clock * 1000, (W.clock + 3) * 1000
            cast.id, cast.spell = "foe-1", 686
            W.casts.target = cast
        end
        local _, unit = bar:IsEventRegistered("UNIT_SPELLCAST_START")
        local _, other = focus.face.cast:IsEventRegistered("UNIT_SPELLCAST_START")
        check(unit == "target" and other == "focus" and not bar._shown and near(Above(), 0), "each frame hears its own unit's cast")
        Foe({})
        W.Fire("UNIT_SPELLCAST_START", "target", "foe-1", 686)
        check(bar._shown and bar.text._text == "Shadow Bolt" and bar.timer._text == "3.0"
            and near(Above(), Units.ROW - Core.Pixels(foe, 1)) -- an elite: its rank's line, a pixel more than the border, is in that
            and bar.lock._alpha == 0 and not mine._shown, "your target's cast above its health, and not on your frame")
        W.casts.target.locked = true
        W.Fire("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "target", "foe-1", 686)
        check(bar.lock._alpha == 1 and bar.lock._barTexture == Cast.ART.locked and bar.text._text == "Shadow Bolt",
            "one that cannot be interrupted: grey, in the game's art")
        W.Wait(1)
        bar._scripts.OnUpdate(bar, 0)
        check(bar.lock._value == bar.fill._value and bar.lock._value == W.clock * 1000, "the grey goes along with the fill")
        W.casts.target.locked = nil
        W.Fire("UNIT_SPELLCAST_INTERRUPTIBLE", "target", "foe-1", 686)
        check(bar.lock._alpha == 0, "and gold again when it can be")
        W.casts.target = nil
        W.Fire("PLAYER_TARGET_CHANGED")
        check(not bar._shown and not bar.cast and near(Above(), 0), "another target: the last one's cast gone at once")
        Foe({})
        W.Fire("PLAYER_TARGET_CHANGED")
        check(bar._shown and bar.cast, "and one under way seen at once")
        W.casts.target = nil
        W.Fire("UNIT_SPELLCAST_STOP", "target", "foe-1", 686)
        check(bar._shown and bar.cast.held, "done: it stays a moment")
        W.Wait(Cast.HOLD)
        bar._scripts.OnUpdate(bar, 0)
        Foe({ craft = true })
        W.Fire("UNIT_SPELLCAST_START", "target", "foe-1", 686)
        check(not bar._shown, "nobody else's crafting shows, as on the game's bars")
        Foe({})
        GameRulesUtil = { ShouldShowTargetCastBar = function() return false end }
        W.Fire("UNIT_SPELLCAST_START", "target", "foe-1", 686)
        check(not bar._shown, "where the game's rules take your target's cast bar away, ours too")
        GameRulesUtil = nil
        W.Fire("UNIT_SPELLCAST_START", "target", "foe-1", 686)
        check(bar._shown, "and back without them")
        Core.Set(ns.name, "unitCast", false)
        check(not bar._shown and not bar.wanted, "Cast bars off: none here")
        Core.Set(ns.name, "unitCast", true)
        check(bar._shown, "on again, with the cast under way")
        W.casts.target = nil
        W.Fire("UNIT_SPELLCAST_FAILED", "target", "foe-1", 686)
        check(not bar._shown and not ns.off, "and nothing failed")
    end

    -- The health bar is the anchor: whatever comes or goes around it, on every frame, it stays exactly where it is.
    do
        local function Spot(face)
            local parts = {}
            for _, point in ipairs(face.health._points) do
                for index = 1, 5 do
                    if index ~= 2 then parts[#parts + 1] = tostring(point[index]) end
                end
            end
            return table.concat(parts, " ")
        end
        local face, foe = player.face, target.face
        local pixel = Core.Pixels(foe, 1)
        for _, button in ipairs({ player, target, focus }) do
            local point = button._points[1]
            check(point[1] == "TOP" and point[3] == "BOTTOM", "every frame stands by its top: its button's height moves no health bar")
        end
        local kept = units.target.classification
        for _, rank in ipairs({ "normal", "rare", "elite", "worldboss" }) do
            units.target.classification = rank
            W.Fire("UNIT_CLASSIFICATION_CHANGED", "target")
            local spot = Spot(foe)
            W.casts.target = { name = "Shadow Bolt", icon = 1, starts = W.clock * 1000, ends = (W.clock + 3) * 1000, id = "foe-2", spell = 686 }
            W.Fire("UNIT_SPELLCAST_START", "target", "foe-2", 686)
            check(foe.cast._shown and Spot(foe) == spot, rank .. ": a cast leaves the health bar where it is")
            check(near(foe.cast._points[2][5] - foe.health._points[1][5], pixel), rank .. ": and rests on it, a pixel over it")
            units.targettarget = { name = "Droopy", health = 600, most = 1000 }
            foe.rowButton:Show()
            check(foe.rowShown and Spot(foe) == spot, rank .. ": so does a row")
            foe.rowButton:Hide()
            units.targettarget = nil
            W.casts.target = nil
            W.Fire("UNIT_SPELLCAST_FAILED", "target", "foe-2", 686)
            check(not foe.cast._shown and Spot(foe) == spot, rank .. ": and all of it going")
        end
        units.target.classification = kept
        W.Fire("UNIT_CLASSIFICATION_CHANGED", "target")

        local spot = Spot(face)
        W.cast = { name = "Fireball", icon = 135812, starts = W.clock * 1000, ends = (W.clock + 2.5) * 1000, id = "cast-9", spell = 133 }
        W.Fire("UNIT_SPELLCAST_START", "player", "cast-9", 133)
        W.mirrorLeft.BREATH, W.mirrorLeft.EXHAUSTION = 30000, 30000
        W.Fire("MIRROR_TIMER_START", "BREATH", 30000, 60000, -1, 0, "Breath")
        W.Fire("MIRROR_TIMER_START", "EXHAUSTION", 30000, 60000, -1, 0, "Fatigue")
        W.Fire("MIRROR_TIMER_START", "FEIGNDEATH", 30000, 60000, -1, 0, "Feign Death")
        check(face.cast._shown and face.breath._shown and face.timers[2]._shown and Spot(face) == spot,
            "on your own frame too: a cast, your breath and two timers")
        units.pet = { name = "Wolf", health = 80, most = 100, powerType = 2, powerToken = "FOCUS", power = 50, powerMost = 100 }
        face.rowButton:Show()
        check(face.rowShown and face.rowPower._shown and Spot(face) == spot, "and your pet with its resource")
        face.rowButton:Hide()
        W.cast = nil
        W.Fire("UNIT_SPELLCAST_FAILED", "player", "cast-9", 133)
        for _, timer in ipairs({ "BREATH", "EXHAUSTION", "FEIGNDEATH" }) do W.Fire("MIRROR_TIMER_STOP", timer) end
        check(not face.cast._shown and not face.breath._shown and Spot(face) == spot and not ns.off, "and all of it going")
    end

    Core.Set(ns.name, "unitSize", 150)
    check(player._scale == 1.5 and target._scale == 1.5 and PlayerFrame._mouse == false, "Unit frame size: all three larger")
    Core.Set(ns.name, "unitSize", 100)
    -- In a fight secure frames are not changed (the stand-in refuses a touch of one while W.Combat is on): what is
    -- asked for waits for its end.
    W.Combat(true)
    Core.Set(ns.name, "unitTarget", false)
    check(watched[target] and target._shown and TargetFrame._parent ~= UIParent, "switched off in a fight: nothing changes yet")
    W.Combat(false)
    check(not watched[target] and not target._shown and TargetFrame._parent == UIParent, "after the fight: ours hidden, the game's back")
    Core.Set(ns.name, "unitTarget", true)
    check(not ns.off, "and nothing failed")
end

-------------------------------------------------------------------------------
--  Auras on the frames: the game's containers, three of each kind; your lists
-------------------------------------------------------------------------------
do
    local target, player = unitButtons.target, unitButtons.player
    units.target = { name = "Kobold Miner", level = 22, health = 40, most = 120, foe = true, reaction = 2 }
    W.Fire("PLAYER_TARGET_CHANGED")
    local auras = target.face.auras
    local debuffs, buffs, control = auras.debuffs, auras.buffs, auras.control
    check(debuffs and buffs and control and debuffs._template == "CustomAuraContainerTemplate"
        and debuffs._groups.auto.options.maxFrameCount == 3 and buffs._groups.auto.options.maxFrameCount == 3
        and control._groups.auto.options.maxFrameCount == 3, "three containers of the game's, three auras of each kind")
    check(debuffs._groups.auto.filter == "HARMFUL|PLAYER|!CROWD_CONTROL" and buffs._groups.auto.filter == "HELPFUL|INCLUDE_NAME_PLATE_ONLY"
        and control._groups.auto.filter == "HARMFUL|CROWD_CONTROL" and debuffs._unit == "target",
        "on a foe: your debuffs, its buffs as the game shows them on plates, crowd control")
    check(debuffs._groups.auto.options.sortMethod == AuraContainerSortMethod.UnitFrameDebuff
        and buffs._groups.auto.options.sortMethod == AuraContainerSortMethod.BigDefensive,
        "the most important first: the game's unit frame order for debuffs, big defensives for buffs")
    local mine = player.face.auras
    check(mine.debuffs._groups.auto.filter == "HARMFUL|!CROWD_CONTROL" and mine.buffs._groups.auto.filter == "HELPFUL",
        "on you: any debuffs, any buffs")
    local roof = target.face.roof
    check(buffs._points[1][1] == "BOTTOMLEFT" and buffs._points[1][2] == roof and buffs._points[1][3] == "BOTTOMLEFT"
        and control._points[1][1] == "BOTTOM" and control._points[1][2] == roof and control._points[1][3] == "BOTTOM"
        and debuffs._points[1][1] == "BOTTOMRIGHT" and debuffs._points[1][2] == roof and debuffs._points[1][3] == "BOTTOMRIGHT",
        "above the frame, on its roof: buffs on the left, crowd control in the middle, debuffs on the right")
    check(buffs._flow.corner == "BOTTOMLEFT" and buffs._flow.across == "Right" and debuffs._flow.corner == "BOTTOMRIGHT"
        and debuffs._flow.across == "Left" and control._flow.corner == "BOTTOMLEFT" and control._flow.up == "Up",
        "buffs grow from the left edge, debuffs from the right; crowd control fills its own width, so it stays centred")
    check(debuffs._flow.line == 70 and buffs._flow.line == 70 and control._flow.line == 70
        and debuffs._groups.auto.options.layout.lineSpacing == ns.UnitAuras.GAP,
        "at most three in a line: what you marked Important goes up, not into the middle")
    check(not debuffs._groups.listed.enabled and debuffs._groups.auto.candidates == nil, "no lists yet: nothing filtered")
    -- A right click on an icon, out of a fight: the spell on a list.
    local icon = debuffs._groups.auto.icon
    icon._SetSpellName._text = "Sunder Armor"
    W.auras.target = { HARMFUL = { { name = "Rend", spellId = 772 }, { name = "Sunder Armor", spellId = 7386, icon = 132363 } } }
    W.menus = {}
    icon._scripts.OnMouseUp(icon, "RightButton")
    local menu = W.menus[1]
    check(menu and menu[1].title == "Sunder Armor" and menu[2].text == ns.TEXT.reminderCreate
        and menu[3].text == ns.TEXT.auraImportant and menu[4].text == ns.TEXT.auraUnimportant
        and menu[5].text == ns.TEXT.auraHidden and menu[6].text == ns.TEXT.auraLists,
        "its menu: Create reminder, Important, Unimportant, Hidden, Aura lists")
    menu[3].fn()
    check(ns.options.auraWhite[7386] == "Sunder Armor" and debuffs._groups.listed.enabled
        and debuffs._groups.listed.candidates.includeSpellIDs[7386] and debuffs._groups.auto.candidates.excludeSpellIDs[7386]
        and mine.buffs._groups.listed.candidates.includeSpellIDs[7386],
        "Important: shown in front of the rest (the game includes it there and leaves it out of the rest)")
    local function Shines(button)
        for _, widget in ipairs(W.frames) do
            if widget._texture == ns.BuffList.GLOW and widget._parent and widget._parent._parent == button then return true end
        end
    end
    check(Shines(debuffs._groups.listed.icon) and not Shines(debuffs._groups.auto.icon),
        "the important ones glow on the frame, the group's own icons in a fight too; the rest do not")
    W.menus = {}
    icon._scripts.OnMouseUp(icon, "RightButton")
    W.menus[1][4].fn()
    check(ns.options.auraBlack[7386] and not ns.options.auraWhite[7386] and not debuffs._groups.listed.enabled
        and control._groups.auto.candidates.excludeSpellIDs[7386], "Unimportant: off the other list, never shown")
    W.combat = true
    W.menus = {}
    icon._scripts.OnMouseUp(icon, "RightButton")
    check(W.menus[1][1].title == ns.TEXT.auraFight and W.menus[1][2].text == ns.TEXT.auraLists,
        "in a fight the game keeps the icons from addons: only the lists' window")
    W.combat = false
    -- The window: the lists side by side, a spell added by its number, taken off by its X.
    W.menus[1][2].fn()
    local lists = ns.AuraLists
    W.spells[1459] = { name = "Arcane Intellect" }
    local box
    for _, widget in ipairs(W.frames) do if widget._kind == "EditBox" and widget._template == "InputBoxTemplate" then box = widget end end
    box:SetText("1459")
    box._scripts.OnEnterPressed(box)
    check(ns.options.auraWhite[1459] == "Arcane Intellect" and mine.buffs._groups.listed.candidates.includeSpellIDs[1459],
        "typed by its number, Enter: Important")
    local line
    for _, widget in ipairs(W.frames) do
        if widget.entry and widget.entry.id == 1459 and widget._shown then line = widget end
    end
    check(line and line.name._text == "Arcane Intellect" and line.number._text == 1459, "listed with its name and number")
    box:SetText("Nonsense")
    box._scripts.OnEnterPressed(box)
    check(ns.options.auraWhite.Nonsense == nil, "a name the game does not know: nothing added")
    lists.Take("white", 1459)
    lists.Take("black", 7386)
    check(next(ns.options.auraWhite) == nil and next(ns.options.auraBlack) == nil and debuffs._groups.auto.candidates == nil,
        "taken off: no lists again")
    Core.Set(ns.name, "unitAuras", false)
    check(not debuffs._shown and debuffs._unit == "none", "Auras on the frames off: none")
    Core.Set(ns.name, "unitAuras", true)
    check(debuffs._shown and debuffs._unit == "target" and not ns.off, "on again")
    units.target = nil
end

-------------------------------------------------------------------------------
--  The action bars, clean: only the buttons that hold something, each its icon alone
-------------------------------------------------------------------------------
do
    local bar = MainActionBar
    local full, empty = bar.actionButtons[1], bar.actionButtons[2]
    local arrow = bar.ActionBarPageNumber.UpButton
    check(ns.ActionBars.Clean() and bar.BorderArt._alpha == 0 and bar.EndCaps._alpha == 0 and divider._alpha == 0,
        "the bar's frame, end caps and dividers out of sight")
    check(bar.ActionBarPageNumber._alpha == 1 and arrow._mouse == true,
        "its page number and arrows stay: which bar shows, and the clicks to change it")
    check(full.NormalTexture._alpha == 0 and full.SlotArt._alpha == 0 and full.SlotBackground._alpha == 0
        and full.Border._alpha == 0, "a button's frame, slot, background and border out of sight")
    check(not full.icon._masks[full.IconMask] and full.icon._coords[1] == ns.ActionBars.CROP[1]
        and full.cooldown._points[1][2] == full.icon and full.cooldown._points[1][4] == 0,
        "its icon square and cropped, the cooldown over all of it")
    check(full:GetHighlightTexture()._colour and full:GetHighlightTexture()._blend == "ADD"
        and full:GetPushedTexture()._colour, "the mouse over it and a press: a flat wash")
    check(full._alpha == 1 and empty._alpha == 0, "a button that holds something shows; an empty one does not")
    W.Fire("ACTIONBAR_SHOWGRID")
    local slot
    for _, widget in ipairs(W.frames) do
        if widget._parent == empty and widget._colour and widget._colour[4] == ns.ActionBars.SLOT[4] then slot = widget end
    end
    check(empty._alpha == 1 and slot and slot._shown, "while something is dragged, the empty one shows as a dark square")
    W.Fire("ACTIONBAR_HIDEGRID")
    check(empty._alpha == 0 and not slot._shown, "dropped: out of sight again")
    W.actions[2] = { kind = "spell", id = 78 }
    empty:Update()
    check(empty._alpha == 1, "given an action, it shows (after the game's own update)")
    W.actions[2] = nil
    empty:Update()
    Core.Set(ns.name, "cleanBars", false)
    check(not ns.ActionBars.Clean() and bar.BorderArt._alpha == 1 and arrow._mouse == true and divider._alpha == 1
        and full.NormalTexture._alpha == 1 and full.icon._masks[full.IconMask] and full.icon._coords[2] == 1
        and full:GetHighlightTexture()._texture == "highlight" and full.cooldown._points[1][4] == 3 and empty._alpha == 1,
        "Clean action bars off: everything as the game had it")
    Core.Set(ns.name, "cleanBars", true)
    check(ns.ActionBars.Clean() and full.NormalTexture._alpha == 0 and empty._alpha == 0, "on again: clean")
end

-------------------------------------------------------------------------------
--  The game's experience and stance bars gone, its menu bar on mouseover
-------------------------------------------------------------------------------
do
    local box = StanceBar._parent
    check(box ~= UIParent and not box._shown and StatusTrackingBarManager._parent == box and not StanceBar:IsVisible()
        and not StatusTrackingBarManager:IsVisible(), "the game's experience and stance bars stand in a hidden frame")
    Core.Set(ns.name, "hideTracking", false)
    check(StatusTrackingBarManager._parent == UIParent and StanceBar._parent == box, "its switch off: the experience bar alone is back")
    Core.Set(ns.name, "hideTracking", true)
    Core.Set(ns.name, "hideStance", false)
    check(StanceBar._parent == UIParent and StatusTrackingBarManager._parent == box, "and the stance bar's its own")
    Core.Set(ns.name, "hideStance", true)
    check(StanceBar._parent == box, "on again: gone again")

    local general = Core.general
    local animations = general.animations
    general.animations = false -- each fade where it goes at once
    local button = MicroMenu.Button
    local function Leave()
        for index = #W.frames, 1, -1 do
            local widget = W.frames[index]
            if not widget._parent and widget._scripts.OnUpdate and widget._shown then return widget._scripts.OnUpdate(widget, 0) end
        end
    end
    check(MicroMenu._alpha == 0 and MicroMenu._parent == UIParent, "the menu bar out of sight at rest, in its place")
    button:GetScript("OnEnter")(button)
    check(MicroMenu._alpha == 1, "the mouse on a button of it: in sight")
    MicroMenu._mouseOver = true
    Leave()
    check(MicroMenu._alpha == 1, "and while the mouse stays on it")
    MicroMenu._mouseOver = false
    Leave()
    check(MicroMenu._alpha == 0, "the mouse off it: out of sight again")
    Core.Set(ns.name, "menuHover", false)
    check(MicroMenu._alpha == 1, "its switch off: always in sight")
    button:GetScript("OnEnter")(button)
    Leave()
    check(MicroMenu._alpha == 1, "and the mouse changes nothing then")
    Core.Set(ns.name, "menuHover", true)
    check(MicroMenu._alpha == 0, "on again")

    -- Out of sight at rest (Core.Rest): your frames and the game's action bars. The rest of what it does: window.lua.
    local bars, you, foe = ns.ActionBars.Rest(), ns.Units.KINDS[1], ns.Units.KINDS[2]
    local health, power, most = units.player.health, units.player.power, units.player.powerMost
    units.player.health, units.player.power, units.player.powerMost = units.player.most, 0, 100 -- a warrior at rest
    Core.Set(ns.name, "unitRest", false)
    check(you.button._alpha == 1 and foe.button._alpha == 1 and not you.rest:Resting(), "Hide the unit frames at rest off: always in sight")
    Core.Set(ns.name, "unitRest", true)
    Core.Set(ns.name, "barsRest", false)
    check(MainActionBar._alpha == 1 and StanceBar._alpha == 1 and not bars:Resting(), "Hide the action bars at rest off: always in sight")
    Core.Set(ns.name, "barsRest", true)
    local function Rested()
        return you.button._alpha == 0 and foe.button._alpha == 0 and MainActionBar._alpha == 0 and StanceBar._alpha == 0
    end
    local function Seen()
        return you.button._alpha == 1 and foe.button._alpha == 1 and MainActionBar._alpha == 1 and StanceBar._alpha == 1
    end
    W.Fire("UNIT_POWER_UPDATE", "player")
    check(Rested(), "both on by themselves: frames and bars out of sight at rest")
    units.player.power = 30
    W.Fire("UNIT_POWER_UPDATE", "player")
    check(Seen(), "your resource not where it rests: all in sight")
    units.player.power = 0
    W.Fire("UNIT_POWER_UPDATE", "player")
    check(Rested(), "at rest again")
    W.Combat(true)
    check(Seen(), "in a fight all in sight")
    W.Combat(false)
    check(Rested(), "after it out of sight")

    -- The mouse: one bar shows them all, one frame itself.
    local function Look(rest, seconds)
        local watch = rest.hover.watch.frame
        watch:GetScript("OnUpdate")(watch, seconds or 1)
    end
    local key = MainActionBar.actionButtons[2]
    key:GetScript("OnEnter")(key)
    check(MainActionBar._alpha == 1 and StanceBar._alpha == 1 and you.button._alpha == 0,
        "the mouse on an empty button of one bar: every bar in sight, no unit frame")
    MainActionBar._mouseOver = true
    Look(bars)
    check(MainActionBar._alpha == 1 and StanceBar._alpha == 1, "and stay while the mouse is on a bar")
    MainActionBar._mouseOver = false
    Look(bars)
    check(Rested(), "off every bar: out of sight")
    you.button:GetScript("OnEnter")(you.button)
    check(you.button._alpha == 1 and foe.button._alpha == 0 and MainActionBar._alpha == 0, "the mouse on your frame: it alone in sight")
    Look(you.rest)
    check(Rested(), "and off it again")
    foe.row.button:GetScript("OnEnter")(foe.row.button)
    check(foe.button._alpha == 1 and you.button._alpha == 0, "the mouse on a frame's row: that frame")
    Look(foe.rest)
    check(Rested(), "and off it")

    -- What a frame has to show, and what holds the bars.
    W.cast = { name = "Fireball", icon = 135812, starts = W.clock * 1000, ends = (W.clock + 2.5) * 1000, id = 1, spell = 133 }
    W.Fire("UNIT_SPELLCAST_START", "player", 1, 133)
    check(you.button._alpha == 1 and foe.button._alpha == 0, "your cast shows on your frame at rest")
    W.cast = nil
    W.Fire("UNIT_SPELLCAST_STOP", "player", 1, 133)
    W.clock = W.clock + ns.UnitCast.HOLD
    local cast = you.button.face.cast
    cast:GetScript("OnUpdate")(cast, 1)
    check(you.button._alpha == 0, "and goes with it")
    W.mirror = { { timer = "BREATH", value = 30000, maxvalue = 60000, scale = -1, paused = 0, label = "Breath" } }
    W.Fire("MIRROR_TIMER_START", "BREATH", 30000, 60000, -1, 0, "Breath")
    check(you.face == nil and you.button.face.breath.on and you.button._alpha == 1, "your breath under water too")
    W.mirror = nil
    W.Fire("MIRROR_TIMER_STOP", "BREATH")
    check(you.button._alpha == 0, "and out of the water it goes")
    W.Fire("ACTIONBAR_SHOWGRID")
    check(MainActionBar._alpha == 1 and you.button._alpha == 0, "something dragged: the bars in sight to drop it on")
    W.Fire("ACTIONBAR_HIDEGRID")
    check(MainActionBar._alpha == 0, "let go: out of sight")
    EventRegistry:TriggerEvent("QuickKeybindFrame.QuickKeybindModeEnabled")
    check(MainActionBar._alpha == 1 and key._alpha == 1, "setting your keys: the bars in sight, their empty buttons too")
    EventRegistry:TriggerEvent("QuickKeybindFrame.QuickKeybindModeDisabled")
    check(MainActionBar._alpha == 0 and key._alpha == 0, "done: out of sight")
    local vehicle = C_ActionBar.HasVehicleActionBar
    C_ActionBar.HasVehicleActionBar = function() return true end
    W.Fire("UPDATE_VEHICLE_ACTIONBAR")
    check(MainActionBar._alpha == 1 and you.button._alpha == 0, "in a vehicle the bars stay in sight: its actions are on them")
    C_ActionBar.HasVehicleActionBar = vehicle
    W.Fire("UPDATE_VEHICLE_ACTIONBAR")
    check(MainActionBar._alpha == 0, "out of it they rest")
    Core.Set(ns.name, "unitPlayer", false)
    check(not you.rest:Resting(), "your frame off: nothing of it rests")
    Core.Set(ns.name, "unitPlayer", true)
    check(you.rest:Resting(), "on again it does")
    units.player.health, units.player.power, units.player.powerMost = health, power, most
    W.Fire("UNIT_POWER_UPDATE", "player")
    general.animations = animations
end

-------------------------------------------------------------------------------
--  A window of ours this game has not (Combat.lua, ns.Serves): it alone is not there
-------------------------------------------------------------------------------
do
    local configs, keyOf = C_SpecializationInfo.GetCombatConfigIDForSpecGroup, GetBindingKey
    C_SpecializationInfo.GetCombatConfigIDForSpecGroup = nil -- talents not of two specializations, as Retail's
    GetBindingKey = function(action) return ({ TOGGLESPELLBOOK = "P", TOGGLETALENTS = "N" })[action] end
    ns.Keys.Bind()
    check(not Board.Present("talents") and Board.Present("spellbook") and ns.Serves(),
        "without the talents ours are made after, our talents are not there; our spellbook is")
    check(W.overrides[owner].P == ns.Keys.COMMANDS.spellbook and W.overrides[owner].N == nil
        and ns.Keys.Taken("TOGGLESPELLBOOK") and not ns.Keys.Taken("TOGGLETALENTS"),
        "the talents key opens the game's talents; the spellbook's key ours")
    local entries = Core.Classic.List(handle)
    check(#entries == 1 and entries[1].window == "spellbook", "Classic windows: the game's spellbook, not its talents")
    local first, listed = layouts.options.default(), {}
    for _, spec in ipairs(layouts.options.windows()) do listed[spec.key] = true end
    check(first and first.key == "spellbook" and listed.spellbook and not listed.talents,
        "the first layout is the spellbook alone, and the dropdown Windows has no talents")
    W.Play("retail")
    ns.Keys.Bind()
    check(not ns.Serves() and W.overrides[owner] == nil and not ns.Keys.Taken() and Core.Classic.List(handle) == nil,
        "with neither (Retail): no key of the game's runs ours, and no Classic windows of Combat's")
    W.Play("forever")
    C_SpecializationInfo.GetCombatConfigIDForSpecGroup, GetBindingKey = configs, keyOf
    ns.Keys.Bind()
    check(Board.Present("talents") and W.overrides[owner].P == ns.Keys.COMMANDS.spellbook, "back in Forever: both ours again")
end

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
ns.Window.Reboard()
W.Wait(0)
check(Core.Lent(planner), "seated before the module fails")
-- The rings around the mouse: out only while they run, around the cursor's picture, not its tip.
do
    local Rings = ns.MouseRings
    local holder, cooldown, casting = Rings.holder, Rings.cooldown, Rings.casting
    function methods:SetCooldown(start, duration) self._start, self._duration, self._object, self._shown = start, duration, nil, true end
    function methods:SetCooldownFromDurationObject(object)
        if W.refuseDuration then error("secret value") end
        self._object, self._start, self._shown = object, nil, true
    end
    function methods:Clear() self._start, self._object = nil, nil end
    methods.UnregisterAllEvents = methods.UnregisterAllEvents or function(self) self._events, self._units = {}, nil end
    function methods:SetReverse(on) self._reverse = on end
    local spell, asked = rawget(_G, "C_Spell"), {}
    local global
    local GetCooldown, GetDuration, GetCVar = spell.GetSpellCooldown, spell.GetSpellCooldownDuration, C_CVar.GetCVar
    spell.GetSpellCooldown = function(id) asked[#asked + 1] = id; return global end
    spell.GetSpellCooldownDuration = function() return "the game's duration" end
    local size, scale, dpi, effective = "-1", 1, 1, methods.GetEffectiveScale
    C_CVar.GetCVar = function(name) if name == "cursorSizePreferred" then return size end return GetCVar(name) end
    GetScreenDPIScale = function() return dpi end
    function methods:GetEffectiveScale() return scale end
    local function Cooldown(active, duration)
        global = active ~= nil and { isActive = active, duration = duration } or nil
        W.Fire("SPELL_UPDATE_COOLDOWN")
    end
    local function Follow() holder._scripts.OnUpdate(holder, 0) end
    local function Done(ring)
        ring._shown = false
        ring._scripts.OnCooldownDone(ring)
        Follow()
    end
    local function Spot()
        local point = holder._points[1]
        return point[4], point[5]
    end
    W.cursorX, W.cursorY = 1000, 500
    local unit = 768 / 2160 -- a real pixel in UI units on the stand-in's screen
    Follow() -- the casts of the tests above are over

    check(holder._strata == "TOOLTIP" and not holder._shown and not cooldown._shown and not casting._shown,
        "no ring at rest: nothing around the mouse")
    local class = RAID_CLASS_COLORS.WARRIOR
    check(cooldown._swipe[1] == 1 and cooldown._swipe[3] == 1 and cooldown._swipe[4] == Rings.ALPHA and Rings.ALPHA < 1
        and casting._swipe[1] == class.r and casting._swipe[2] == class.g and casting._swipe[4] == Rings.ALPHA,
        "see-through: the global cooldown's white, the cast's your class's colour")
    check(Rings.spark._blend == "ADD" and Rings.glow._blend == "ADD" and Rings.glow._alpha == Rings.GLOW_ALPHA,
        "the leading line and its softer glow add light")
    local toTip = math.sqrt(Rings.MIDDLE[1] ^ 2 + Rings.MIDDLE[2] ^ 2)
    check(near(cooldown._rotation, -Rings.TURN) and near(casting._rotation, -Rings.TURN)
        and near(math.cos(math.pi / 2 + Rings.TURN) * toTip, -Rings.MIDDLE[1])
        and near(math.sin(math.pi / 2 + Rings.TURN) * toTip, Rings.MIDDLE[2]),
        "both rings start and end on the line to the cursor's tip, not straight up")
    Cooldown(false, 0)
    check(not holder._shown and not cooldown._shown, "no global cooldown: still none")
    check(asked[#asked] == (RETAIL and 61304 or 29515), "the game's own spell for it where it has one, another in Forever")
    Cooldown(true, 1.5)
    check(holder._shown and cooldown._shown and cooldown._object == "the game's duration" and not casting._shown,
        "the global cooldown starts: the inner ring runs on the game's duration, whatever it hides")
    local x, y = Spot()
    check(near(x, 1000 + 32 * Rings.MIDDLE[1] * unit) and near(y, 500 - 32 * Rings.MIDDLE[2] * unit),
        "the rings stand on the middle of the cursor's picture, right of and below its tip")
    check(near(cooldown._width, 2 * 32 * Rings.INNER * unit) and near(casting._width, 2 * 32 * Rings.OUTER * unit)
        and cooldown._width == cooldown._height, "as large as the cursor asks for")
    check(Rings.INNER * 0.86 > math.sqrt((1 - Rings.MIDDLE[1]) ^ 2 + (1 - Rings.MIDDLE[2]) ^ 2) - 0.02,
        "the hole holds the cursor's picture as far as it ever reaches")
    W.cursorX, W.cursorY = 300, 700
    Follow()
    x, y = Spot()
    check(near(x, 300 + 32 * Rings.MIDDLE[1] * unit) and near(y, 700 - 32 * Rings.MIDDLE[2] * unit), "with the mouse while it runs")
    Done(cooldown)
    check(not cooldown._shown and not holder._shown, "over: gone, and nothing runs any more")
    Cooldown(true, 8)
    check(not holder._shown, "a school locked by an interrupt is no global cooldown")
    local plain, hidden = rawget(_G, "issecretvalue"), { secret = true }
    issecretvalue = function(value) return type(value) == "table" and value.secret == true end
    global = { isActive = true, duration = hidden }
    W.Fire("SPELL_UPDATE_COOLDOWN")
    check(cooldown._shown and cooldown._object, "in a fight the game hides the numbers: the ring runs all the same")
    Cooldown(false, 0)
    check(not cooldown._shown, "the game took the cooldown back (the spell failed): gone at once")
    Follow()

    -- The cursor's size, in real pixels: neither the screen's height nor the UI's scale changes it.
    dpi = 2
    Cooldown(true, 1.5)
    x = Spot()
    check(near(x, 300 + 64 * Rings.MIDDLE[1] * unit) and near(cooldown._width, 2 * 64 * Rings.INNER * unit),
        "on Default the display's scale sizes the cursor: twice as large at 200%")
    Cooldown(false, 0)
    Follow()
    size, scale = "3", 0.5
    Cooldown(true, 1.5)
    x = Spot()
    check(near(x, 300 / 0.5 + 96 * Rings.MIDDLE[1] * unit / 0.5), "the Cursor Size chosen wins; a smaller UI asks for more of its units")
    Cooldown(false, 0)
    Follow()
    size, scale = "0", 1
    dpi = 1.25
    Cooldown(true, 1.5)
    check(near(cooldown._width, 2 * 32 * Rings.INNER * unit), "the smallest size chosen")
    Cooldown(false, 0)
    Follow()
    size = "-1"
    Cooldown(true, 1.5)
    check(near(cooldown._width, 2 * 32 * Rings.INNER * unit), "a scale between two sizes takes the one it reaches")
    Cooldown(false, 0)
    Follow()

    -- Your cast: the outer ring.
    local began = W.clock * 1000
    W.cast = { name = "Fireball", icon = 135812, starts = began, ends = began + 2500, id = "ring-1", spell = 133 }
    W.Fire("UNIT_SPELLCAST_START", "player", "ring-1", 133)
    check(holder._shown and casting._shown and near(casting._start, began / 1000) and near(casting._duration, 2.5)
        and casting._reverse == true, "a cast: the outer ring fills, from its start to its end")
    W.cast.ends = began + 3000
    W.Fire("UNIT_SPELLCAST_DELAYED", "player", "ring-1", 133)
    check(near(casting._duration, 3), "pushed back: the ring goes with it")
    W.Wait(0.75)
    Follow()
    local orbit = casting._width / 2 * (1 + Rings.HOLE) / 2
    local line, turned = Rings.spark._points[1], Rings.TURN - math.pi / 2
    check(Rings.sparks._shown and near(line[4], orbit * math.cos(Rings.TURN)) and near(line[5], orbit * math.sin(Rings.TURN))
        and near(Rings.spark._rotation, turned) and near(Rings.glow._rotation, turned) and Rings.glow._width > Rings.spark._width,
        "a quarter of the way: the line and its glow at the sweep's head, across the ring's band")
    W.Fire("UNIT_SPELLCAST_FAILED", "player", "ring-2", 116)
    check(casting._shown, "what you tried while casting leaves the cast alone")
    W.cast = nil
    W.Fire("UNIT_SPELLCAST_INTERRUPTED", "player", "ring-1", 133)
    Follow()
    check(not casting._shown and not holder._shown and not Rings.sparks._shown, "interrupted: gone at once, the line with it")
    W.channel = { name = "Drain Life", icon = 136169, starts = began, ends = began + 5000, spell = 689 }
    W.Fire("UNIT_SPELLCAST_CHANNEL_START", "player", "ring-3", 689)
    check(casting._shown and casting._reverse == false and near(casting._duration, 5), "a channel: the ring empties")
    W.channel = nil
    W.Fire("UNIT_SPELLCAST_CHANNEL_STOP", "player", "ring-3", 689)
    Follow()
    check(not casting._shown and not holder._shown, "the channel over: gone")

    -- A cast the game hides: its duration where the game takes that, else no ring.
    local CastingDuration = rawget(_G, "UnitCastingDuration")
    UnitCastingDuration = function() return "the cast's duration" end
    W.cast = { name = "Fireball", icon = 135812, starts = hidden, ends = hidden, id = "ring-4", spell = 133 }
    W.Fire("UNIT_SPELLCAST_START", "player", "ring-4", 133)
    Follow()
    check(casting._shown and casting._object == "the cast's duration" and not Rings.sparks._shown,
        "its numbers hidden: the ring runs on the game's duration, without the line")
    casting._shown = false
    W.refuseDuration = true
    W.Fire("UNIT_SPELLCAST_DELAYED", "player", "ring-4", 133)
    check(not casting._shown and not ns.off, "and where the game refuses that: no ring, and nothing broken")
    W.refuseDuration, W.cast, UnitCastingDuration, issecretvalue = nil, nil, CastingDuration, plain
    W.Fire("UNIT_SPELLCAST_STOP", "player", "ring-4", 133)
    Follow()

    -- The settings: a ring off hears nothing and goes.
    W.cast = { name = "Fireball", icon = 135812, starts = began, ends = began + 2500, id = "ring-5", spell = 133 }
    W.Fire("UNIT_SPELLCAST_START", "player", "ring-5", 133)
    Cooldown(true, 1.5)
    Core.Set(ns.name, "mouseCast", false)
    check(not casting._shown and cooldown._shown and not holder:IsEventRegistered("UNIT_SPELLCAST_START")
        and holder:IsEventRegistered("SPELL_UPDATE_COOLDOWN"), "the cast's ring off: it goes, the other runs on")
    Core.Set(ns.name, "mouseCooldown", false)
    Follow()
    check(not cooldown._shown and not holder._shown and not holder:IsEventRegistered("SPELL_UPDATE_COOLDOWN"), "both off: nothing is heard")
    Core.Set(ns.name, "mouseCast", true)
    check(casting._shown and holder._shown, "on again in the middle of a cast: the ring is there at once")
    Core.Set(ns.name, "mouseCooldown", true)
    W.cast = nil
    W.Fire("UNIT_SPELLCAST_STOP", "player", "ring-5", 133)
    Cooldown(false, 0)
    Follow()
    check(not holder._shown, "and at rest again")

    spell.GetSpellCooldown, spell.GetSpellCooldownDuration, C_CVar.GetCVar = GetCooldown, GetDuration, GetCVar
    GetScreenDPIScale, methods.GetEffectiveScale = nil, effective
    W.cursorX, W.cursorY = nil, nil
end

-- A step of the giving back fails (here the board's own): the others give back all the same, the keys first.
Board.layouts.Hide = function() error("the board failed") end
ns.StandDown("a test")
check(ns.off and not Core.Lent(planner) and not frame:IsShown(),
    "standing down, all is given back and the window goes, though a step of it failed")
check(W.overrides[owner] == nil, "and the game's keys open the game's windows again")
check(unitButtons.player._alpha == 0 and not unitButtons.player._shown and not watched[unitButtons.target]
    and PlayerFrame._mouse == true and PlayerFrame.PlayerFrameContent._alpha == 1 and FocusFrame._parent == UIParent
    and PlayerCastingBarFrame:IsEventRegistered("UNIT_SPELLCAST_START") and MirrorTimerContainer:IsEventRegistered("MIRROR_TIMER_START"),
    "our unit frames gone, the game's back, its cast bar and timers hearing again")
check(not ns.ActionBars.Clean() and MainActionBar.BorderArt._alpha == 1 and MainActionBar.actionButtons[2]._alpha == 1
    and not ns.ActionBars.Rest().on and MainActionBar._alpha == 1,
    "the action bars as the game has them, in sight")
check(StatusTrackingBarManager._parent == UIParent and StanceBar._parent == UIParent and MicroMenu._alpha == 1,
    "its experience, stance and menu bars too")
check(PlayerFrame.PlayerFrameContent.HealthBar._motion == true and not PlayerFrame.PlayerFrameContent.HealthBar._mouse
    and PetFrameHappiness._mouse == true and PetFrameHappiness._motion == true,
    "what took the mouse takes it again, and no more than it did")
check(PartyFrame._parent == UIParent and CompactRaidFrameContainer._parent == UIParent,
    "and the game's party and raid frames are its own again")
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
check(not questMark._shown, "a plate the game shows after it gets no quest mark")

check(not ns.MouseRings.holder._shown and not ns.MouseRings.holder:IsEventRegistered("SPELL_UPDATE_COOLDOWN")
    and not ns.MouseRings.holder:IsEventRegistered("UNIT_SPELLCAST_START"), "and no ring around the mouse, none to come")

-- As Retail loads the module: this file once more, in a client of its own.
check(os.execute(("lua5.1 '%s/dev/tests/combat.lua' retail"):format(root)) == 0, "in Retail the module loads and runs as that game has it")

io.write(("Combat: all %d checks passed.\n"):format(passed))
