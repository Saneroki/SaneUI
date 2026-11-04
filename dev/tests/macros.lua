-- Runs Sane Macros, a part of the Combat module, against the stand-in client (wowstub.lua): macros and steps kept and cleaned, a macro written
-- out into its lines, conditions and turns, the checks, the snippet that runs on a press (a turn a press, conditions that
-- skip in that press, the top of the list, nothing true, a bar button on the same hub, a fight), keys and bar buttons by
-- page, the window with its + list, a game's macro taken over, Retail's path, and standing down.
-- The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/macros.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
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

function methods:WrapScript(_, script, snippet)
    self._wraps = self._wraps or {}
    self._wraps[script] = assert(loadstring("return function(self, button, down) " .. snippet .. "\nend"))()
end
function methods:SetFrameRef(name, frame)
    self._refs = self._refs or {}
    self._refs[name] = frame
end
function methods:GetFrameRef(name) return self._refs and self._refs[name] end
function methods:CallMethod(name, ...) return self[name](self, ...) end
function methods:SetTexCoord() end
function methods:SetVertexColor(r) self._shade = r end
function methods:SetDesaturated() end
function methods:SetCooldownFromDurationObject(duration) self._duration = duration end
function methods:Clear() self._duration = nil end
function methods:EnableKeyboard(on) self._keyboard = on end
function methods:SetPropagateKeyboardInput() end
function methods:RegisterForDrag() end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:GetStringWidth() return #(tostring(self._text or "")) * 6 end
function methods:GetFontString()
    self._label = self._label or W.NewWidget("FontString", nil, self)
    self._label._text = self._text
    return self._label
end
function methods:GetEffectiveScale() return 1 end
function methods:GetTop() return 500 end
function methods:SetScrollChild() end
function methods:HasFocus() return self._focus end
function methods:Insert(text) self._text = (self._text or "") .. text end
function methods:SetFocus() self._focus = true end
function methods:ClearFocus() self._focus = nil end
function methods:SetMaxLetters() end
function methods:SetFontString() end
function methods:SetDisabledFontObject() end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:SetAutoFocus() end
function methods:IsMouseOver() return self._over end

-- The game's condition parser, by the state of this test: "[a,b] x; [c] y; z".
local state = {}
local function Holds(word)
    if word:sub(1, 1) == "@" then return true end
    if word:sub(1, 2) == "no" and not state[word] then return not state[word:sub(3)] end
    return state[word]
end
SecureCmdOptionParse = function(text)
    for clause in (text .. ";"):gmatch("([^;]*);") do
        local when, rest = clause:match("^%s*(%b[])%s*(.*)$")
        if not when then return (clause:gsub("^%s+", "")) end
        local all = true
        for word in when:sub(2, -2):gmatch("[^,]+") do all = all and Holds(word) end
        if all then return rest end
    end
    return nil
end

local known = { Slam = 1464, ["Shield Slam"] = 23922, ["Shield Block"] = 2565 }
C_Spell = C_Spell or {}
C_Spell.DoesSpellExist = function(name) return known[name] ~= nil or name == "Rend" end
C_Spell.GetSpellInfo = function(name) return (known[name] or name == "Rend") and { spellID = known[name] or 772 } or nil end
C_Spell.GetSpellTexture = function(name) return known[name] and 1000 + known[name] or nil end
C_Spell.GetSpellName = function(id) return id == 772 and "Rend" or "Slam" end
C_Spell.IsSpellUsable = function(name) return name ~= "Shield Block", false end
C_Spell.GetSpellCooldownDuration = function(name) return "duration of " .. name end
C_SpellBook = C_SpellBook or {}
C_SpellBook.IsSpellKnown = function(id) return id ~= 772 end
C_Item = C_Item or {}
C_Item.GetItemInfo = function(what) return what == "Hearthstone" and "Hearthstone" or nil end
C_Item.GetItemCount = function(what) return what == 6948 and 1 or 0 end
C_Item.GetItemIconByID = function() return 134414 end
C_Item.GetItemNameByID = function() return "Hearthstone" end
GetCVarBool = function(name) return name == "ActionButtonUseKeyDown" end
GetBindingKey = function(name) if name == "ACTIONBUTTON3" then return "3", "SHIFT-3" end end
GetBindingText = function(key) return key end
GetBindingAction = function() return "JUMP" end
GetBindingName = function() return "Jump" end
GetNumMacros = function() return 1, 1 end
GetMacroInfo = function(index)
    if index == 1 then return "Mount", 1, "/use Horse" end
    if index == 121 then return "Mine", 1, "/cast Slam" end
end
local overrides, drivers = {}, {}
ClearOverrideBindings = function(owner) overrides[owner] = nil end
SetOverrideBindingClick = function(owner, _, key, name, mouse)
    overrides[owner] = overrides[owner] or {}
    overrides[owner][key] = name .. ":" .. mouse
end
local register, unregister = RegisterStateDriver, UnregisterStateDriver
-- The game's driver (SecureStateDriver.lua, resolveDriver) sets the state only when it changes; the header's snippet
-- (_onstate-slot) then runs, secure, with the bindings it may set its own.
local function Resolve(frame, words)
    local value = SecureCmdOptionParse(words)
    if value == nil or value == frame:GetAttribute("state-slot") then return end
    frame:SetAttribute("state-slot", value)
    local handle = setmetatable({
        ClearBindings = function() overrides[frame] = nil end,
        SetBindingClick = function(_, _, key, name, mouse)
            overrides[frame] = overrides[frame] or {}
            overrides[frame][key] = name .. ":" .. mouse
        end,
    }, { __index = function(_, name)
        local method = frame[name]
        if type(method) == "function" then return function(_, ...) return method(frame, ...) end end
        return method
    end })
    W.AsGame(function() assert(loadstring("local self, stateid, newstate = ...\n" .. frame:GetAttribute("_onstate-slot")))(handle, "slot", value) end)
end
RegisterStateDriver = function(frame, state_, words)
    if state_ == "slot" then
        drivers[frame] = { state_, words }
        Resolve(frame, words)
    elseif register then
        register(frame, state_, words)
    end
end
UnregisterStateDriver = function(frame, state_)
    if state_ == "slot" then drivers[frame] = nil elseif unregister then unregister(frame, state_) end
end
MenuUtil = MenuUtil or {}
GameTooltip_SetTitle, GameTooltip_AddNormalLine = function() end, function() end

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
-- What the saved files may hold: rubbish among a good macro.
local store = Core.Store("Macros")
store.macros = { "rubbish", { id = 5, name = 7, steps = { { kind = "nothing" }, { kind = "spell", what = "Slam", often = 99, when = { 3, { word = "harm" } } } } } }
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
W.Fire("PLAYER_ENTERING_WORLD")
local Macros = ns.Macros
local Book, Write, Check, Press, Face, Reach, Editor, TEXT = Macros.Book, Macros.Write, Macros.Check, Macros.Press, Macros.Face, Macros.Reach, Macros.Editor, Macros.TEXT

-------------------------------------------------------------------------------
--  The book
-------------------------------------------------------------------------------
check(#Book.All() == 1 and Book.All()[1].id == 5, "rubbish in the saved files is left out")
local cleaned = Book.All()[1]
check(cleaned.name == TEXT.firstName and #cleaned.steps == 1, "a bad name and a bad step fall away")
check(cleaned.steps[1].often == Book.MOST_OFTEN and #cleaned.steps[1].when == 1, "a step comes in the shape read")
check(Book.New().id == 6, "numbers go on after the saved ones")
local copied = Book.Copy(cleaned)
check(copied.name == TEXT.copyOf:format(cleaned.name) and copied.steps[1] ~= cleaned.steps[1], "a copy holds its own steps")
Book.Delete(copied)
check(Book.Find(copied.id) == nil, "deleted")

local function Macro(...)
    local macro = Book.New("Test")
    for _, step in ipairs({ ... }) do macro.steps[#macro.steps + 1] = step end
    return macro
end
local function Spell(name, when, unit, often)
    local step = Book.Step("spell", name)
    step.when, step.unit, step.often = when or {}, unit, often or 1
    return step
end

check(Book.Move(cleaned, 1, 1) == false, "a step stays where it is")
local three = Macro(Spell("Slam"), Spell("Rend"), Spell("Shield Slam"))
check(Book.Move(three, 3, 1) and three.steps[1].what == "Shield Slam" and three.steps[3].what == "Rend", "a step moves")

-------------------------------------------------------------------------------
--  Written out
-------------------------------------------------------------------------------
check(Write.Line(Spell("Slam")) == "/cast Slam", "a spell's line")
check(Write.Line(Spell("Slam", { { word = "harm" }, { word = "combat", no = true } }, "mouseover"))
      == "/cast [@mouseover,harm,nocombat] Slam", "the target first, then the conditions, in the game's words")
check(Write.When(Spell("Slam")) == nil, "no condition, nothing to ask")
check(Write.When(Spell("Slam", { { word = "stance", value = "2" } })) == "[stance:2] 1", "what the press asks")
local item = Book.Step("item", "Hearthstone", 6948)
check(Write.Line(item) == "/use item:6948", "an item by its number")
item.id = nil
check(Write.Line(item) == "/use Hearthstone", "an item by its name")
local words = Book.Step("text", "/stopcasting\n/cast Slam")
check(Write.Line(words) == words.what, "macro text stays as written")

local spread = Macro(Spell("Slam", nil, nil, 3), Spell("Rend"))
local order = {}
for index, turn in ipairs(Write.Turns(spread)) do order[index] = turn.step.what end
check(table.concat(order, " ") == "Slam Rend Slam Slam" or table.concat(order, " ") == "Slam Slam Rend Slam", "spread out: " .. table.concat(order, " "))
spread.top = true
check(#Write.Turns(spread) == 2, "from the top a step comes up once")
local partly = Macro(Spell("Slam"), Book.Step("spell", ""), Spell("Rend"))
partly.steps[3].off = true
check(#Write.Turns(partly) == 1, "an empty step and one switched off are left out")

-------------------------------------------------------------------------------
--  The checks
-------------------------------------------------------------------------------
local function Finds(step, word)
    for _, found in ipairs(Check.Step(step)) do
        if found:find(word, 1, true) then return true end
    end
    return false
end
local C = TEXT.check
check(#Check.Step(Spell("Slam")) == 0, "nothing wrong")
check(Finds(Book.Step("spell", ""), C.empty), "empty")
check(Finds(Spell("Sllam"), C.noSpell), "a spell the game does not know")
check(Finds(Spell("Rend"), C.notKnown), "a spell this character has not")
check(Finds(Book.Step("item", "Hearthstoen"), "no item"), "an item the game does not know")
check(not Finds(Book.Step("item", "Hearthstone", 6948), C.noneHeld), "an item you hold")
check(Finds(Book.Step("item", "Hearthstone", 7), C.noneHeld), "an item you have none of")
-- Not learnt yet, none held: said at the step, no red mark in the list; a spell the game does not know still counts.
do
    local later = Macro(Spell("Rend"), Book.Step("item", "Hearthstone", 7))
    local found = Check.Macro(later)
    check(found.count == 0 and found[later.steps[1]][1] == C.notKnown, "a spell to learn yet, an item to get: not counted")
    check(Check.Macro(Macro(Spell("Sllam"))).count == 1, "a spell the game does not know: counted")
    Book.Delete(later)
end
check(Finds(Spell("Slam", { { word = "combat" }, { word = "combat", no = true } }), "can never run"), "both sides of a word")
check(Finds(Spell("Slam", { { word = "help" }, { word = "harm" } }), "can never run"), "friend and enemy")
check(not Finds(Spell("Slam", { { word = "help", no = true }, { word = "harm" } }), "can never run"), "not a friend and an enemy can hold")
local function Text(text) return Book.Step("text", text) end
check(#Check.Step(Text("#showtooltip\n/cast [mod:shift,@focus,nodead,target=player] Slam; [btn:2] Rend; Shield Slam")) == 0, "a good macro: " .. tostring(Check.Step(Text("#showtooltip\n/cast [mod:shift,@focus,nodead,target=player] Slam; [btn:2] Rend; Shield Slam"))[1]))
check(Finds(Text(("x"):rep(256)), "Too long"), "over 255 characters")
check(Finds(Text("/cast [madeupword] Slam"), "madeupword"), "a word the game would take as true")
check(Finds(Text("/cast [combat Slam"), "bracket"), "an open bracket")
check(Finds(Text("cast Slam"), "chat"), "a line with no /")
check(Finds(Text("/cast Slam; Rend"), "Never reached"), "what follows a ; with no condition")
check(not Finds(Text("/run a=1; b=2"), "Never reached"), "a ; in a script is no choice")
check(Finds(Text("/cast Slam\n/cast Rend"), "first /cast"), "a second /cast")
local stopped = Macro(Spell("Slam"), Spell("Shield Slam"))
stopped.top = true
local found = Check.Macro(stopped)
check(found[stopped.steps[2]] and found[stopped.steps[2]][1] == C.unreachable, "under a step with no condition, from the top")
stopped.top = nil
check(Check.Macro(stopped).count == 0, "taking turns, every step is reached")
check(Check.Macro(Macro()).macro[1] == C.noSteps, "no steps")
local off = Macro(Spell("Slam"))
off.steps[1].off = true
check(Check.Macro(off).macro[1] == C.allOff, "every step off")

-------------------------------------------------------------------------------
--  A press
-------------------------------------------------------------------------------
check(not Press.SNIPPET:find("function", 1, true) and not Press.SNIPPET:find("[{}]"), "the game would take the snippet")
check(not Reach.SLOT:find("function", 1, true) and not Reach.SLOT:find("[{}]"), "and the slot's")

-- A press as the game gives it: the snippet, secure, then the macro's text run.
local function Hit(button, mouse)
    W.AsGame(function() button._wraps.OnClick(button, mouse or "LeftButton", true) end)
    return button:GetAttribute("macrotext")
end

local turns = Macro(Spell("Slam"), Spell("Rend"), Spell("Shield Slam"))
Press.Load(turns)
local hub = Press.Hub(turns)
check(hub:GetAttribute("useOnKeyDown") == true, "one edge, the game's setting")
check(Hit(hub) == "/cast Slam" and Hit(hub) == "/cast Rend" and Hit(hub) == "/cast Shield Slam" and Hit(hub) == "/cast Slam", "one turn a press, round and round")

local skips = Macro(Spell("Slam", { { word = "mod:shift" } }), Spell("Rend"), Spell("Shield Slam"))
Press.Load(skips)
local skipHub = Press.Hub(skips)
check(Hit(skipHub) == "/cast Rend", "a false condition is skipped in that press")
check(Hit(skipHub) == "/cast Shield Slam", "and the macro goes on")
state["mod:shift"] = true
check(Hit(skipHub) == "/cast [mod:shift] Slam", "with Shift the step runs")
state["mod:shift"] = nil

local top = Macro(Spell("Rend", { { word = "btn:2" } }), Spell("Slam", { { word = "harm" } }), Spell("Shield Slam"))
top.top = true
Press.Load(top)
local topHub = Press.Hub(top)
check(Hit(topHub) == "/cast Shield Slam" and Hit(topHub) == "/cast Shield Slam", "from the top, every press")
state.harm = true
check(Hit(topHub) == "/cast [harm] Slam", "the first that holds")
state.harm = nil
state["btn:2"] = true
check(Hit(topHub, "RightButton") == "/cast [btn:2] Rend", "another for the right button")
state["btn:2"] = nil

local none = Macro(Spell("Slam", { { word = "swimming" } }), Spell("Rend", { { word = "dead" } }))
Press.Load(none)
local noneHub = Press.Hub(none)
check(Hit(noneHub) == "" and noneHub:GetAttribute("at") == 1, "nothing true, nothing run, nothing moved")
check(Hit(Press.Hub(Macro())) == "", "no steps, nothing run")

-- A change in a fight waits for its end; the macro goes on as it was.
W.Combat(true)
turns.steps[1] = Spell("Shield Block")
Press.Update(turns)
check(Hit(hub) == "/cast Rend", "in a fight the macro stays as it was and works")
W.Combat(false)
check(hub:GetAttribute("m1") == "/cast Shield Block" and hub:GetAttribute("at") == 1, "changed when the fight ends")
check(Hit(hub) == "/cast Shield Block", "and started over")
Hit(hub)
W.Fire("PLAYER_REGEN_ENABLED")
check(hub:GetAttribute("at") == 1, "a fight's end starts it over")
turns.fresh = false
Hit(hub)
W.Fire("PLAYER_REGEN_ENABLED")
check(hub:GetAttribute("at") == 2, "unless it should not")

-------------------------------------------------------------------------------
--  Keys and bar buttons
-------------------------------------------------------------------------------
check(Macros.own.keys ~= nil, "the character's keys")
local keyed = Macro(Spell("Slam"))
local other = Macro(Spell("Rend"))
Reach.SetKey(keyed, "F")
local function Bound(key)
    for _, keys in pairs(overrides) do
        if keys[key] then return keys[key] end
    end
end
check(Bound("F") == Press.Name(keyed) .. ":LeftButton", "a key clicks the macro's button")
check(Reach.SetKey(other, "F") == keyed, "a key taken from another macro is told")
check(Book.KeyOf(keyed) == nil and Book.KeyOf(other) == "F", "one macro a key")
Reach.SetKey(other, "G")
check(Bound("F") == nil and Bound("G") ~= nil, "its old key is free again")
Reach.TakeKey(other)
check(Bound("G") == nil, "and the last one taken away")

check(Reach.PlaceOf(Reach.BARS[1], 3, 2) == "ActionButton3:2", "a place on Bar 1 names its page")
check(Reach.PlaceOf(Reach.BARS[6], 3, 2) == "MultiBar5Button3", "no other bar has pages")
local bar, button, page = Reach.Parts("ActionButton3:2")
check(bar == Reach.BARS[1] and button == 3 and page == 2, "read back")
check(Reach.Parts("MultiBar5Button12") == Reach.BARS[6], "a bar with a digit in its name")
local bars = MainActionBar
local slot = rawget(_G, "ActionButton3") or CreateFrame("Button", "ActionButton3", bars)
check(Reach.Page() == 1, "the page by the game's conditions")
state["bar:4"] = true
check(Reach.Page() == 4, "another page")
state["bar:4"] = nil

Reach.SetPlace(keyed, "ActionButton3:2")
local face = _G.SaneUIMacroFace_ActionButton3_2
check(face ~= nil and face:GetParent() == slot:GetParent(), "our button stands in the bar's frame, so it goes with the bar")
check(face:GetFrameRef("hub") == Press.Hub(keyed), "and reads the macro's hub")
local header, driven
for frame, driver in pairs(drivers) do header, driven = frame, driver end
check(driven[2]:find("[bar:2] ours", 1, true) and driven[2]:find("[vehicleui]", 1, true), "its page, and not in a vehicle: " .. driven[2])
check(header:GetAttribute("key1") == "3" and header:GetAttribute("key2") == "SHIFT-3", "the button's own keys")
check(Hit(face) == "/cast Slam", "a press there runs the macro")
check(Press.Hub(keyed):GetAttribute("at") == 1, "with a single step the ring is round")
check(face.icon:GetTexture() == 1000 + 1464, "the next step's picture")
keyed.icon = "Interface\\Icons\\INV_Sword_04"
Face.Paint()
check(face.icon:GetTexture() == 1000 + 1464, "a step with a spell shows the spell's, the macro's own picture or not")
keyed.icon = nil
Face.Paint()
check(face.cooldown._duration == "duration of Slam", "the swirl from the game's duration object")
check(face.key:GetText() == "3", "the key shows")
ns.options.macroKey = false
Face.Paint()
check(face.key:GetText() == "", "unless it should not")
ns.options.macroKey = true

Reach.SetPlace(keyed, "ActionButton3:3")
check(Book.PlaceOf(keyed) == "ActionButton3:3", "one bar button a macro")
Reach.TakePlace(keyed)
check(next(drivers) == nil, "taken off, the game's button is the game's")

-- Many macros on the bars at once (Saneroki, 2026-11-04: "When I move a macro to the action bar, the last macro i had
-- placed disapears"): a new place, a key or the game's key settings changed leave the others standing, with their keys.
;(function()
    state["bar:1"] = true
    local fourth = rawget(_G, "MultiBar5Button4") or CreateFrame("Button", "MultiBar5Button4", bars)
    local fifth = rawget(_G, "MultiBar5Button5") or CreateFrame("Button", "MultiBar5Button5", bars)
    local rend, block = Macro(Spell("Rend")), Macro(Spell("Shield Block"))
    Reach.SetPlace(keyed, "ActionButton3:1")
    local first = _G.SaneUIMacroFace_ActionButton3_1
    check(first._shown and overrides[next(drivers)] ~= nil, "one on Bar 1: shown, with the button's keys")
    Reach.SetPlace(rend, "MultiBar5Button4")
    Reach.SetPlace(block, "MultiBar5Button5")
    local second, third = _G.SaneUIMacroFace_MultiBar5Button4, _G.SaneUIMacroFace_MultiBar5Button5
    check(first._shown and second._shown and third._shown, "three macros on the bars: every one stands")
    local keyed1
    for frame, driver in pairs(drivers) do if driver[2]:find("[bar:1]", 1, true) then keyed1 = frame end end
    check(keyed1 and overrides[keyed1] and overrides[keyed1]["3"], "the first keeps its keys")
    Reach.SetKey(rend, "K")
    check(first._shown and second._shown and third._shown, "a key set: they all still stand")
    Reach.TakePlace(rend)
    check(first._shown and not second._shown and third._shown, "one taken off: only that one goes")
    -- Another macro dropped where one stands (Saneroki: "putting a macro on alt 7 nothing happens"): it stands there.
    Reach.SetPlace(rend, "ActionButton3:1")
    check(Book.PlaceOf(keyed) == nil and first._shown and first:GetFrameRef("hub") == Press.Hub(rend) and third._shown,
        "a macro dropped on a taken button: shown there, the one before off it")
    Reach.SetPlace(keyed, "ActionButton3:1")
    Reach.TakePlace(keyed)
    Reach.TakePlace(block)
    Reach.TakeKey(rend)
    check(next(drivers) == nil and not first._shown and not third._shown, "all taken off")
    state["bar:1"] = nil
end)()

-- Deleted on another character: its key and place fall away here at the login.
Macros.own.keys.Z, Macros.own.places["ActionButton3:1"] = 9999, 9999
Reach.Update()
check(Macros.own.keys.Z == nil and Macros.own.places["ActionButton3:1"] == nil, "what is gone from the book is gone here")

-- Waiting out a fight.
W.Combat(true)
check(Reach.SetKey(other, "H") == nil and Bound("H") == nil, "no key changes in a fight")
W.Combat(false)
check(Bound("H") ~= nil, "it comes at the fight's end")
Reach.TakeKey(other)

-- Choosing a bar button.
slot:Show()
local chosenPlace
Macros.Place.Start(function(place) chosenPlace = place end)
local function Square()
    for _, each in ipairs(Macros.Place.squares) do
        if each.place == "ActionButton3:1" then return each end
    end
end
local square = Square()
check(square and square.place == "ActionButton3:1", "a square over the button")
square._scripts.OnClick(square, "RightButton")
check(chosenPlace == nil and not square:IsShown(), "a right click cancels")
Macros.Place.Start(function(place) chosenPlace = place end)
square._scripts.OnClick(square, "LeftButton")
check(chosenPlace == "ActionButton3:1", "a click chooses")
Macros.Place.Start(function(place) chosenPlace = place end)
W.Combat(true)
check(not square:IsShown(), "a fight ends it")
W.Combat(false)

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
for _, macro in ipairs({ unpack(Book.All()) }) do Book.Delete(macro) end
-- The full screen cannot come here: the window of its own.
local open, full = ns.Window.Open, ns.Window.Full
ns.Window.Open, ns.Window.Full = function() end, function() return false end
Editor.Toggle()
local inner = Book.New("First")
Editor.Choose(inner)
check(Press.Picture(nil) == Press.ICON, "a macro with no step has the question mark")
Editor.AddStep(Book.Step("spell", "Slam"))
Editor.AddStep(Book.Step("spell", "Rend"))
check(#inner.steps == 2 and inner.steps[2].what == "Rend", "a step goes after the one chosen")
Editor.AddStep(Book.Step("spell", "Shield Slam"), 0)
check(inner.steps[1].what == "Shield Slam", "or where it fell")
Editor.TakeStep(1)
check(#inner.steps == 2 and inner.steps[1].what == "Slam", "taken away")

-- The + list: every group, every line with its explanation.
local groups = Macros.Conditions.Groups()
check(#groups >= 8, "the conditions by group")
for _, group in ipairs(groups) do
    for _, entry in ipairs(group.items) do check(entry.tip and entry.on and entry.off, "words for " .. entry.word) end
end
local menus = #W.menus
local picked
Macros.Picker.Open(UIParent, function(word, value) picked = word .. tostring(value) end)
check(#W.menus == menus + 1, "the + opens a list")
local function HasSpec()
    for _, group in ipairs(Macros.Conditions.Groups()) do
        for _, entry in ipairs(group.items) do
            if entry.word == "spec" then return true end
        end
    end
end
check(not HasSpec(), "what only Retail has stays out of Forever's list")
check(Macros.Conditions.Text({ word = "mod:shift", no = true }) == "nomod:shift", "the opposite in the game's words")
check(Macros.Conditions.Text({ word = "stance", value = "2" }) == "stance:2", "with its value")
check((Macros.Conditions.Words({ word = "combat", no = true })) == "Out of a fight", "and in plain ones")
check((Macros.Conditions.Words({ word = "stance", value = "2" })):find(": 2", 1, true), "a value shows")
check((Macros.Conditions.Words({ word = "odd" })) == "odd", "a word not in the list shows as it is")

-- On Combat's full screen: the same page, in the panel's body, and no window of its own.
local spec
for _, each in ipairs(ns.Board.layouts.options.windows()) do if each.key == "macros" then spec = each end end
check(spec and spec.title == TEXT.title and spec.least[1] >= 700 and spec.icon, "a window of Combat's board")
Editor.Toggle()
check(not Editor.Shown(), "the window of its own closed")
local panel = W.NewWidget("Frame", nil, UIParent)
panel.body = W.NewWidget("Frame", nil, panel)
panel.body._width = 900
spec.build(panel)
spec.show(panel, true)
check(Editor.Page():GetParent() == panel.body, "the page goes into the panel")
spec.size(panel, 760, 600)
Editor.Choose(inner)
local back = ns.Window.Back
local wentBack = false
ns.Window.Back = function() wentBack = true end
Editor.Toggle()
check(wentBack, "its key takes the full screen back while it stands there")
ns.Window.Back = back
spec.show(panel, false)
ns.Window.Full = function() return true end
ns.Window.Open = function(key) panel.opened = key end
Editor.Toggle()
check(panel.opened == "macros" and not Editor.Shown(), "opened, it goes to the full screen where that can come")
ns.Window.Full = function() return false end
ns.Window.Open = function() end

-- Dragging a macro from the list: the same squares, the macro chosen first.
local dragged = Book.New("Dragged")
Editor.Choose(dragged)
Editor.DragToBar()
check(square:IsShown(), "a drag lays the squares over the bar buttons")
square._over = true
Macros.Place.Drop()
square._over = nil
check(Book.PlaceOf(dragged) == "ActionButton3:1" and not square:IsShown(), "and let go on one it stands there")
-- The bars stay clear (Saneroki, 2026-11-04): nothing over a button but an unseen square; the picture follows the
-- mouse, the button under it gets a gold frame; the game's frames under the mouse say which, as a square's
-- IsMouseOver may answer no where the game keeps a button's place to itself.
Reach.TakePlace(dragged)
Editor.DragToBar()
local carried = Macros.Place.Carried()
check(#square._children == 0 and carried:IsShown() and carried.icon:GetTexture() == Macros.Press.ICON, "no wash over the buttons, the picture at the mouse")
W.foci = { square }
carried:GetScript("OnUpdate")(carried, 0.01)
check(Macros.Place.Over() == square and carried.hint:IsShown(), "the button under the mouse in a gold frame")
Macros.Place.Drop()
W.foci = {}
check(Book.PlaceOf(dragged) == "ActionButton3:1" and not carried:IsShown() and not carried.hint:IsShown(),
      "let go there, by the frames under the mouse: it stands there")
Editor.DragToBar()
Macros.Place.Drop()
check(Book.PlaceOf(dragged) == "ActionButton3:1" and not square:IsShown(), "let go on no button: nothing changes")
Reach.TakePlace(dragged)
Book.Delete(dragged)
Editor.Choose(inner)

-- A game's macro taken over.
local taken = Book.FromGame("Mount", "/use Horse")
check(taken.top and taken.steps[1].kind == "text" and taken.steps[1].what == "/use Horse", "as macro text, from the top")
Book.Delete(taken)

-- A macro's own picture (Saneroki, 2026-11-04: "sensible usefull icons instead of all having the questionmark").
local HORSE = "Interface\\Icons\\Ability_Mount_RidingHorse"
taken = Book.FromGame("Mount", "/use Horse", 132261)
check(taken.icon == 132261 and Press.MacroPicture(taken) == 132261, "a game's macro taken over keeps its picture")
Book.Delete(taken)
taken = Book.FromGame("Odd", "/say hi", Book.QUESTION)
check(taken.icon == nil and Press.MacroPicture(taken) == Press.ICON, "the question mark is no picture of its own")
check(Press.Picture(taken.steps[1], taken) == Press.ICON, "and the step's picture stays the question mark")
taken.icon = HORSE
check(Press.Picture(taken.steps[1], taken) == HORSE and Press.MacroPicture(taken) == HORSE,
      "macro text with no spell shows the macro's picture, in the list and on its bar button")
check(Press.Picture(keyed.steps[1], taken) == Press.Picture(keyed.steps[1]), "a step with a spell shows the spell's")
local copied = Book.Copy(taken)
check(copied.icon == HORSE, "a copy keeps it")
Book.Delete(copied)
taken.icon = { "odd" }
Macros.Book.Clean()
check(taken.icon == nil, "a picture that is none is dropped when the saved macros are read")
Book.Delete(taken)

-- The way in for other code: a macro of macro text by its name, made once.
local added, new = Macros.Add("Sit", "/sit")
check(new and added.top and added.steps[1].what == "/sit", "a macro added by its name")
local again, newAgain = Macros.Add("Sit", "/stand")
check(again == added and not newAgain and added.steps[1].what == "/sit", "one of that name is left as it is")
check(Macros.Add("", "/sit") == nil and Macros.Add("Odd", nil) == nil, "nothing without a name and a text")
Book.Delete(added)
added = Macros.Add("Sit", "/sit", "Interface\\Icons\\INV_FISHINGCHAIR")
check(added.icon == "Interface\\Icons\\INV_FISHINGCHAIR", "with the picture given")
again = Macros.Add("Sit", "/stand", "Interface\\Icons\\Spell_Nature_Sleep")
check(again == added and added.icon == "Interface\\Icons\\INV_FISHINGCHAIR", "one there keeps its own")
Book.Delete(added)

-- A macro of steps from other code (Saneroki, 2026-11-04: Launch Setup's rotations): conditions kept, a step that is
-- no step left out, the order and the start after a fight as given.
local rotation, newRotation = Macros.Add("Fight", { top = true, fresh = false, steps = {
    { kind = "spell", what = "Shield Slam", when = { { word = "known", value = "Shield Slam" } } },
    { kind = "spell", what = "Revenge", often = 9 },
    { kind = "nonsense", what = "x" },
    "not a step",
    { kind = "text", what = "/cast [stance:2] Shield Block" } } })
check(newRotation and rotation.top and rotation.fresh == false and #rotation.steps == 3, "a macro of steps, the odd ones left out")
check(rotation.steps[1].when[1].word == "known" and rotation.steps[1].when[1].value == "Shield Slam", "a step's conditions kept")
check(rotation.steps[2].often == Book.MOST_OFTEN and rotation.steps[3].kind == "text", "steps cleaned as saved ones are")
check(Macros.Add("Odd", { top = true }) == nil, "a table without steps is no macro")
local sequence = Macros.Add("Builder", { steps = { { kind = "spell", what = "Shred" } } })
check(not sequence.top and sequence.fresh, "without top each press goes on; back to the start after a fight")
Book.Delete(rotation)
Book.Delete(sequence)

-- A macro made anew by other code (Saneroki, 2026-11-04: a potion macro kept on the best potion held): the same macro,
-- its number, picture and place kept, its button taking the new steps.
do
    state["bar:1"] = true
    local potion = Macros.Add("HP Potion", "/use Minor Healing Potion", "Interface\\Icons\\INV_Potion_51")
    Reach.SetPlace(potion, "ActionButton3:1")
    local id = potion.id
    check(Macros.Set("HP Potion", { top = true, steps = { { kind = "item", what = "Healing Potion", id = 929 } } }),
        "a macro there made anew")
    check(potion.id == id and potion.icon == "Interface\\Icons\\INV_Potion_51" and #potion.steps == 1
        and potion.steps[1].kind == "item" and potion.steps[1].id == 929 and Book.PlaceOf(potion) == "ActionButton3:1",
        "its number, picture and place kept, its steps the new ones")
    check(Hit(Press.Hub(potion)) == "/use item:929" or Hit(Press.Hub(potion)):find("Healing Potion", 1, true),
        "its button presses the new step: " .. tostring(Press.Hub(potion):GetAttribute("macrotext")))
    check(Macros.Set("HP Potion", "/use Lesser Healing Potion") and potion.steps[1].kind == "text" and potion.top,
        "or of macro text, one step from the top")
    check(not Macros.Set("No such", "/sit") and not Macros.Set("HP Potion", nil), "none of that name, or no body: nothing")
    Reach.TakePlace(potion)
    Book.Delete(potion)
    state["bar:1"] = nil
end

-- The game's Press and Hold Casting stops our casts at the key's release (Saneroki, 2026-11-04: a Wrath began and
-- stopped at once): a macro that casts says so while it is on; one casting nothing does not.
do
    local cvar = GetCVarBool
    GetCVarBool = function(name) return name == "ActionButtonUseKeyDown" or name == "ActionButtonUseKeyHeldSpell" end
    local casts, waves = Macro(Spell("Slam")), Macro(Book.Step("text", "/wave"))
    local found = Check.Macro(casts)
    check(found.macro[1] == C.heldCasting and found.count == 1, "Press and Hold Casting on: a macro that casts says so")
    check(Check.Macro(waves).count == 0, "a macro that casts nothing: nothing to say")
    GetCVarBool = cvar
    check(Check.Macro(casts).count == 0, "off: nothing")
    Book.Delete(casts)
    Book.Delete(waves)
end

-- Our button over a bar slot is the mouse's: it acts on the release, the edge the game acts on for a mouse's click of a
-- secure button; the slot's keys press the macro's hub, a key's button.
do
    local registered, register = {}, W.methods.RegisterForClicks
    W.methods.RegisterForClicks = function(self, ...)
        registered[self] = table.concat({ ... }, ",")
        if register then return register(self, ...) end
    end
    state["bar:1"] = true
    local clicked = Macro(Spell("Slam"))
    Reach.SetPlace(clicked, "ActionButton3:1")
    local face = _G.SaneUIMacroFace_ActionButton3_1
    Face.Edges()
    check(registered[face] == "AnyUp" and face:GetAttribute("useOnKeyDown") == false, "the bar button: the mouse's release")
    local header
    for frame, driver in pairs(drivers) do if driver[2]:find("[bar:1]", 1, true) then header = frame end end
    check(header:GetAttribute("button") == Press.Name(clicked) and overrides[header]["3"] == Press.Name(clicked) .. ":LeftButton",
        "its keys press the macro's hub")
    Press.Edges()
    check(registered[Press.Hub(clicked)] == "AnyDown", "the hub: the key's edge, the game's key-down setting")
    Reach.TakePlace(clicked)
    Book.Delete(clicked)
    state["bar:1"] = nil
    W.methods.RegisterForClicks = register
end

-- The game's macros under ours, marked W (Saneroki, 2026-11-03): a click opens the game's window on it, a drag takes
-- it up as the game's, a right click makes a Sane Macro of it.
local opened, tabbed, pickedUp = 0, nil, nil
MacroFrame = W.NewWidget("Frame", "MacroFrame", UIParent)
MacroFrame:Hide()
MacroFrame.ChangeTab = function(_, tab) tabbed = tab end
MacroFrame.SelectMacro = function(self, at) self.at = at end
ShowMacroFrame = function() opened = opened + 1 MacroFrame:Show() end
PickupMacro = function(index) pickedUp = index end
Macros.own.filter = "all" -- every macro of the account, and all of the game's (the filter: below)
Editor.Refresh()
local ours = #Book.All()
local first, second = Editor.Line(ours + 1), Editor.Line(ours + 2)
check(first.game and first.game.index == 1 and first.name:GetText() == "Mount" and second.game.index == 121
    and first.badge:IsShown() and not Editor.Line(1).badge:IsShown(), "the game's macros under ours, marked")
check(not Editor.Line(ours + 3) or not Editor.Line(ours + 3):IsShown(), "and no more")
-- As the game's window shows them (Saneroki, 2026-11-04): squares of their pictures in rows, the names under them,
-- the game's under a line of their own.
do
    local across = math.floor((Editor.LIST - 24 + Editor.GAP) / (Editor.CELL + Editor.GAP))
    local function At(line) return line._points[1][4], line._points[1][5] end
    local extra = ours < 2 and Book.New("Second") or nil
    Editor.Refresh()
    ours = #Book.All()
    first = Editor.Line(ours + 1)
    check(across >= 4 and ours >= 2, "four macros or more a row")
    local x1, y1 = At(Editor.Line(1))
    local x2, y2 = At(Editor.Line(2))
    check(x1 == 0 and y2 == y1 and x2 == Editor.CELL + Editor.GAP, "yours side by side in a row")
    check(Editor.Line(1).icon:GetTexture() == Macros.Press.Picture(Book.All()[1].steps[1]) and first.icon:GetTexture() == 1,
          "each with its picture, a game's with the one the game gives it")
    local gx, gy = At(first)
    check(gx == 0 and gy < y1 - math.ceil(ours / across) * Editor.ROW + 1, "the game's on a row of their own, under yours")
    Editor.Choose(Book.All()[1])
    check(Editor.Line(1).name:GetText() == Book.All()[1].name and Editor.Line(1).mark:IsShown() and not Editor.Line(2).mark:IsShown(),
          "its name under it, the one chosen lit")
    if extra then Book.Delete(extra) end
    Editor.Refresh()
    ours = #Book.All()
    first, second = Editor.Line(ours + 1), Editor.Line(ours + 2)
end
second:GetScript("OnClick")(second, "LeftButton")
check(opened == 1 and tabbed == 2 and MacroFrame.at == 1, "a click opens the game's window on that macro, a character's on its tab")
MacroFrame:Hide()
first:GetScript("OnClick")(first, "LeftButton")
check(opened == 2 and tabbed == 1 and MacroFrame.at == 1, "an account's on the first tab")
MacroFrame:Hide()
first:GetScript("OnDragStart")(first)
check(pickedUp == 1, "a drag takes it up as the game's macro")
first:GetScript("OnClick")(first, "RightButton")
local menu = W.menus[#W.menus]
local take
for _, item in ipairs(menu) do if item.text == TEXT.gameTake then take = item end end
check(menu[1].title == "Mount" and take, "a right click: its menu")
local count = #Book.All()
take.fn()
check(#Book.All() == count + 1 and Book.All()[count + 1].name == "Mount", "a Sane Macro made of it")
Book.Delete(Book.All()[count + 1])
Editor.gameButton:GetScript("OnClick")(Editor.gameButton)
check(opened == 3 and MacroFrame:IsShown(), "the button Game macros opens the game's window")
MacroFrame:Hide()
Editor.Choose(inner)

-- What can be let go on the list.
GetCursorInfo = function() return "spell", 3, "spell", 772 end
local dropped = Macros.Steps.FromCursor()
check(dropped.kind == "spell" and dropped.what == "Rend" and dropped.id == 772, "a spell")
GetCursorInfo = function() return "item", 6948, "link" end
dropped = Macros.Steps.FromCursor()
check(dropped.kind == "item" and dropped.what == "Hearthstone" and dropped.id == 6948, "an item")
GetCursorInfo = function() return "macro", 1 end
dropped = Macros.Steps.FromCursor()
check(dropped.kind == "text" and dropped.what == "/use Horse", "a game's macro")
GetCursorInfo = function() return "money", 5 end
check(Macros.Steps.FromCursor() == nil, "nothing else")

Editor.Toggle()

-------------------------------------------------------------------------------
--  The picture window (Saneroki, 2026-11-04): over everything, the game's icons by group, searched
-------------------------------------------------------------------------------
do
    local Icons = Macros.Icons
    -- The game's grid of a scroll box, as far as the window uses it; the box (combatclient) dresses every icon it has.
    CreateScrollBoxListGridView = function()
        local grid = {}
        function grid:SetElementSize(width, height) self.size = { width, height } end
        function grid:SetStrideExtent(extent) self.stride = extent end
        function grid:SetElementInitializer(_, init) self.init = init end
        return grid
    end
    GetNumClasses = function() return 11 end
    GetClassInfo = function(id)
        if id == 1 then return "Warrior", "WARRIOR", 1 end
        if id == 11 then return "Druid", "DRUID", 11 end
    end
    -- Core's set Icons as the compiler writes it: Charge of the warrior's, a sword an item shows, a picture only
    -- its name sorts, one of nothing.
    local file = os.tmpname() .. "-Icons.lua"
    local out = assert(io.open(file, "w"))
    out:write('local S = SaneUI.Core.Data.Add(1, "Icons", { game = "forever", hash = "00000001", build = 70755, key = "int", '
        .. 'fields = { "name", "classes", "spells", "items", "itemClasses" }, types = { "text", "list int", "list int", '
        .. '"list int", "list int" }, patches = {} })\nif not S then return end\n'
        .. 'S.rows[132337] = "0\\t\\tAbility_Warrior_Charge\\t1\\t100"\n'
        .. 'S.rows[135274] = "0\\t\\tINV_Sword_04\\t\\t\\t6948\\t2"\n'
        .. 'S.rows[136090] = "0\\t\\tSpell_Nature_Sleep"\n'
        .. 'S.rows[999999] = "0\\t\\tWorld_Thing"\n')
    out:close()
    W.AddSets(file)
    os.remove(file)
    local function Frames()
        for _ = 1, 30 do
            local steps = Core.Steps.frame
            local run = steps:GetScript("OnUpdate")
            if run then run(steps, 0.02) end
            W.Wait(0.05)
        end
    end
    Frames()
    check(Core.Data.Set("Icons"):Get(135274, "name") == "INV_Sword_04", "the set of the game's icons is there: "
          .. table.concat({ Core.Data.Set("Icons"):State() }, " ") .. " " .. table.concat(W.fileErrors or {}, "; "))

    local macro = Book.New("Pictured")
    macro.steps[1] = Book.Step("text", "/wave")
    Editor.Choose(macro)
    Editor.ChoosePicture()
    check(Icons.Shown(), "a click on the macro's picture opens the window")
    Frames()
    local keys = {}
    for _, group in ipairs(Icons.Groups() or {}) do keys[group.key] = #group.list end
    check(keys.all == 4 and keys.game == 2 and keys.class1 == 1 and keys.class11 == nil, "all, those the game shows, a class with any")
    check(keys.weapons == 1 and keys.spells == 1 and keys.other == 1 and keys.items == nil, "the sword with the weapons, the sleep with the spells")
    local box = Icons.Box()
    check(#box.lines == 4 and box.lines[1].name == "Ability_Warrior_Charge" and box.rows[2].icon:GetTexture() == 135274,
          "every icon in the grid, by name, each its picture")
    -- The groups' lines: Weapons alone.
    local weapons
    for index = 1, 20 do
        local line = Icons.GroupLine(index)
        if line and line.key == "weapons" then weapons = line end
    end
    weapons:GetScript("OnClick")(weapons)
    check(#box.lines == 1 and box.lines[1].key == 135274, "a group chosen: its icons")
    -- The search: what is typed, a moment after the last key, in the group chosen; the groups' words count too.
    local search = Icons.Search()
    search:SetText("sleep")
    search:GetScript("OnTextChanged")(search, true)
    Frames()
    check(#box.lines == 0, "searched in the group chosen: nothing there")
    Icons.GroupLine(1):GetScript("OnClick")(Icons.GroupLine(1))
    check(#box.lines == 1 and box.lines[1].name == "Spell_Nature_Sleep", "in all: the sleep")
    search:SetText("warrior")
    search:GetScript("OnTextChanged")(search, true)
    Frames()
    check(#box.lines == 1 and box.lines[1].key == 132337, "a class's name finds its icons")
    search:SetText("")
    search:GetScript("OnTextChanged")(search, true)
    Frames()
    -- The mouse on an icon: its name, groups, what shows it, its file.
    local sword = box.rows[2]
    sword:GetScript("OnEnter")(sword)
    local said = table.concat(GameTooltip._lines or {}, "|")
    check(GameTooltip._text == "INV Sword 04" and said:find("Weapons", 1, true) and said:find("Hearthstone", 1, true)
          and said:find("File 135274", 1, true), "its tooltip: name, group, item, file: " .. said)
    GameTooltip._lines = nil
    -- A click: the macro's picture, the window closed.
    sword:GetScript("OnClick")(sword)
    check(macro.icon == 135274 and not Icons.Shown() and Press.MacroPicture(macro) == 135274, "clicked: the macro's picture")
    Editor.ChoosePicture()
    Frames()
    check(box.rows[2].mark:IsShown() and not box.rows[1].mark:IsShown(), "the picture it has is marked")
    Icons.Clear():GetScript("OnClick")(Icons.Clear())
    check(macro.icon == nil and not Icons.Shown(), "Steps' picture: none of its own")
    Editor.ChoosePicture()
    check(Icons.Shown() and Icons.Frame():GetFrameStrata() == "FULLSCREEN_DIALOG", "open again, over the full screen")
    Book.Delete(macro)
    Editor.Choose(inner)
end

-------------------------------------------------------------------------------
--  Whose a macro is, the list's filter, and bar buttons set by other code
--  (Saneroki, 2026-11-04: "only the relevant ones for each class", "a dropdown
--  that is show all ..., a general one ... and a per character one")
-------------------------------------------------------------------------------
do
    local class, key = Core.class, Core.charKey
    local otherClass = class == "DRUID" and "WARRIOR" or "DRUID"
    local general = Macros.Add("Everyone's", "/sit")
    local mine = Macros.Add("Mine", "/wave", nil, "class")
    local own = Macros.Add("Own", "/cheer", nil, "character")
    local theirs = Book.New("Theirs")
    theirs.class = otherClass
    local twin, twinNew = Macros.Add("Mine", "/bow", nil, "general")
    check(mine.class == class and not mine.char and own.char == key and not own.class and not general.class
        and not general.char, "an owner given: this character's class's or its own")
    check(twinNew and twin ~= mine and Macros.Add("Mine", "/kneel", nil, "class") == mine,
        "the same name of another owner is another macro; of the same owner it is left as it is")
    local function Has(list, macro)
        for _, candidate in ipairs(list) do if candidate == macro then return true end end
        return false
    end
    local mineShown, generalShown, allShown = Book.Shown("own"), Book.Shown("general"), Book.Shown("all")
    check(Has(mineShown, mine) and Has(mineShown, own) and not Has(mineShown, general) and not Has(mineShown, theirs),
        "this character's: its class's and its own")
    check(Has(generalShown, general) and Has(generalShown, twin) and not Has(generalShown, mine), "the general ones")
    check(Has(allShown, theirs) and Has(allShown, mine) and Has(allShown, general), "all of the account's")
    check(Book.Named("Mine") == mine and Book.Named("Theirs") == nil, "by name: its own before a general one, never another's")
    local copy = Book.Copy(mine)
    check(copy.class == class, "a copy keeps whose it is")
    Book.Delete(copy)

    -- Saved odd ones are read as general.
    local odd = Book.New("Odd")
    odd.class, odd.char = "warrior!", ""
    Book.Clean()
    check(odd.class == nil and odd.char == nil, "an owner that is none is dropped when the saved macros are read")
    Book.Delete(odd)

    -- The filter over the list, as this character chose it last; Show all at first (Saneroki, 2026-11-04).
    local menu = Editor.filterMenu
    Macros.own.filter = nil
    menu:GenerateMenu()
    check(menu._items[3].checked() and not menu._items[1].checked(), "a character that chose none shows all")
    Macros.own.filter = "all"
    menu:GenerateMenu()
    check(#menu._items == 3 and menu._items[1].text == TEXT.filterOwn and menu._items[2].text == TEXT.filterGeneral
        and menu._items[3].text == TEXT.filterAll and menu._items[3].checked(), "three filters, all chosen as above")
    local function Listed()
        local names, games = {}, {}
        for index = 1, 60 do
            local line = Editor.Line(index)
            if line and line:IsShown() then
                if line.macro then names[line.macro.name] = true elseif line.game then games[line.game.index] = true end
            end
        end
        return names, games
    end
    menu._items[1].fn()
    local names, games = Listed()
    check(Macros.own.filter == "own" and names.Mine and names.Own and not names["Everyone's"] and not names.Theirs,
        "this character's in the list")
    check(games[121] and not games[1], "of the game's, its character macros")
    menu._items[2].fn()
    names, games = Listed()
    check(names["Everyone's"] and not names.Own and games[1] and not games[121], "the general ones, the game's account macros")
    menu._items[3].fn()
    names, games = Listed()
    check(names.Theirs and names.Own and games[1] and games[121], "all of them")
    menu._items[1].fn()

    -- A right click on one: whose it is.
    local line
    for index = 1, 60 do
        local candidate = Editor.Line(index)
        if candidate and candidate:IsShown() and candidate.macro == own then line = candidate end
    end
    line:GetScript("OnClick")(line, "RightButton")
    local whose = W.menus[#W.menus]
    local radios = {}
    for _, item in ipairs(whose) do if item.fn then radios[#radios + 1] = item end end
    check(#radios == 3 and radios[3].checked() and not radios[1].checked(), "whose it is: this character's alone")
    radios[1].fn()
    check(Book.Owner(own) == "general" and own.char == nil, "made everyone's")
    radios[2].fn()
    check(own.class == class and Book.Owner(own) == "class", "made the class's")
    names = Listed()
    check(names.Own, "still in this character's list")

    -- Other code puts a macro on a bar button and takes it off (Launch Setup's keys).
    check(Macros.PlaceOn("Mine", "MultiBar5Button4") and Macros.On("MultiBar5Button4") == "Mine"
        and Book.PlaceOf(mine) == "MultiBar5Button4", "a macro by its name on a bar button")
    check(not Macros.PlaceOn("Theirs", "MultiBar5Button5") and not Macros.PlaceOn("Mine", "Nowhere1")
        and not Macros.PlaceOn("Mine", "MultiBar5Button13") and not Macros.PlaceOn("Nobody", "MultiBar5Button5"),
        "never another's, a place that is none or a name that is none")
    check(Macros.PlaceOn("Mine", "ActionButton1:1") and Macros.On("MultiBar5Button4") == nil
        and Macros.On("ActionButton1:1") == "Mine", "one button a macro")
    check(Macros.PlaceOn("Own", "ActionButton1:1") and Macros.On("ActionButton1:1") == "Own" and Book.PlaceOf(mine) == nil,
        "one macro a button")
    check(Macros.TakeOff("ActionButton1:1") and Macros.On("ActionButton1:1") == nil and not Macros.TakeOff("ActionButton1:1"),
        "taken off, once")
    for _, macro in ipairs({ general, mine, own, theirs, twin }) do Book.Delete(macro) end
    Macros.own.filter = "all"
    Editor.Choose(inner)
end

-------------------------------------------------------------------------------
--  Retail, and standing down
-------------------------------------------------------------------------------
W.Play("retail")
check(HasSpec(), "Retail's list has its own words")
W.Play("forever")

Reach.SetKey(inner, "J")
Reach.SetPlace(inner, "ActionButton3:1")
check(Bound("J") ~= nil and next(drivers) ~= nil, "a key and a bar button stand")
ns.StandDown("a test")
check(ns.off, "stood down")
check(Bound("J") == nil and next(drivers) == nil, "every key and bar button is the game's again")
check(not Macros.Icons.Shown(), "and the picture window is closed")

io.write(("Macros: all %d checks passed.\n"):format(passed))
