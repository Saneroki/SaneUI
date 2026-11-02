-- Runs the Macros module against the stand-in client (wowstub.lua): macros and steps kept and cleaned, a macro written
-- out into its lines, conditions and turns, the checks, the snippet that runs on a press (a turn a press, conditions that
-- skip in that press, the top of the list, nothing true, a bar button on the same hub, a fight), keys and bar buttons by
-- page, the window with its + list, a game's macro taken over, Retail's path, and standing down.
-- The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/macros.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
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
RegisterStateDriver = function(frame, state_, words) drivers[frame] = { state_, words } end
UnregisterStateDriver = function(frame) drivers[frame] = nil end
MenuUtil = MenuUtil or {}
GameTooltip_SetTitle, GameTooltip_AddNormalLine = function() end, function() end

W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Macros", "SaneUI_Macros")
-- What the saved files may hold: rubbish among a good macro.
SaneUIDB = SaneUIDB or {}
local store = SaneUI.Core.Store("Macros")
store.macros = { "rubbish", { id = 5, name = 7, steps = { { kind = "nothing" }, { kind = "spell", what = "Slam", often = 99, when = { 3, { word = "harm" } } } } } }
W.Fire("ADDON_LOADED", "SaneUI_Macros")
W.Fire("PLAYER_LOGIN")
W.Fire("PLAYER_ENTERING_WORLD")
local Core = SaneUI.Core
local Book, Write, Check, Press, Face, Reach, Editor, TEXT = ns.Book, ns.Write, ns.Check, ns.Press, ns.Face, ns.Reach, ns.Editor, ns.TEXT

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
check(ns.own.keys ~= nil, "the character's keys")
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
local bars = CreateFrame("Frame", "MainActionBar", UIParent)
local slot = CreateFrame("Button", "ActionButton3", bars)
check(Reach.Page() == 1, "the page by the game's conditions")
state["bar:4"] = true
check(Reach.Page() == 4, "another page")
state["bar:4"] = nil

Reach.SetPlace(keyed, "ActionButton3:2")
local face = _G.SaneUIMacroFace_ActionButton3_2
check(face ~= nil and face:GetParent() == bars, "our button stands in the bar's frame, so it goes with the bar")
check(face:GetFrameRef("hub") == Press.Hub(keyed), "and reads the macro's hub")
local header, driven
for frame, driver in pairs(drivers) do header, driven = frame, driver end
check(driven[2]:find("[bar:2] ours", 1, true) and driven[2]:find("[vehicleui]", 1, true), "its page, and not in a vehicle: " .. driven[2])
check(header:GetAttribute("key1") == "3" and header:GetAttribute("key2") == "SHIFT-3", "the button's own keys")
check(Hit(face) == "/cast Slam", "a press there runs the macro")
check(Press.Hub(keyed):GetAttribute("at") == 1, "with a single step the ring is round")
check(face.icon:GetTexture() == 1000 + 1464, "the next step's picture")
Face.Paint()
check(face.cooldown._duration == "duration of Slam", "the swirl from the game's duration object")
check(face.key:GetText() == "3", "the key shows")
ns.options.keyText = false
Face.Paint()
check(face.key:GetText() == "", "unless it should not")
ns.options.keyText = true

Reach.SetPlace(keyed, "ActionButton3:3")
check(Book.PlaceOf(keyed) == "ActionButton3:3", "one bar button a macro")
Reach.TakePlace(keyed)
check(next(drivers) == nil, "taken off, the game's button is the game's")

-- Deleted on another character: its key and place fall away here at the login.
ns.own.keys.Z, ns.own.places["ActionButton3:1"] = 9999, 9999
Reach.Update()
check(ns.own.keys.Z == nil and ns.own.places["ActionButton3:1"] == nil, "what is gone from the book is gone here")

-- Waiting out a fight.
W.Combat(true)
check(Reach.SetKey(other, "H") == nil and Bound("H") == nil, "no key changes in a fight")
W.Combat(false)
check(Bound("H") ~= nil, "it comes at the fight's end")
Reach.TakeKey(other)

-- Choosing a bar button.
slot:Show()
local chosenPlace
ns.Place.Start(function(place) chosenPlace = place end)
local square = ns.Place.squares[1]
check(square and square.place == "ActionButton3:1", "a square over the button")
square._scripts.OnClick(square, "RightButton")
check(chosenPlace == nil and not square:IsShown(), "a right click cancels")
ns.Place.Start(function(place) chosenPlace = place end)
square._scripts.OnClick(square, "LeftButton")
check(chosenPlace == "ActionButton3:1", "a click chooses")
ns.Place.Start(function(place) chosenPlace = place end)
W.Combat(true)
check(not square:IsShown(), "a fight ends it")
W.Combat(false)

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
for _, macro in ipairs({ unpack(Book.All()) }) do Book.Delete(macro) end
Editor.Toggle()
local inner = Book.New("First")
Editor.Choose(inner)
check(ns.Press.Picture(nil) == Press.ICON, "a macro with no step has the question mark")
Editor.AddStep(Book.Step("spell", "Slam"))
Editor.AddStep(Book.Step("spell", "Rend"))
check(#inner.steps == 2 and inner.steps[2].what == "Rend", "a step goes after the one chosen")
Editor.AddStep(Book.Step("spell", "Shield Slam"), 0)
check(inner.steps[1].what == "Shield Slam", "or where it fell")
Editor.TakeStep(1)
check(#inner.steps == 2 and inner.steps[1].what == "Slam", "taken away")

-- The + list: every group, every line with its explanation.
local groups = ns.Conditions.Groups()
check(#groups >= 8, "the conditions by group")
for _, group in ipairs(groups) do
    for _, entry in ipairs(group.items) do check(entry.tip and entry.on and entry.off, "words for " .. entry.word) end
end
local menus = #W.menus
local picked
ns.Picker.Open(UIParent, function(word, value) picked = word .. tostring(value) end)
check(#W.menus == menus + 1, "the + opens a list")
local function HasSpec()
    for _, group in ipairs(ns.Conditions.Groups()) do
        for _, entry in ipairs(group.items) do
            if entry.word == "spec" then return true end
        end
    end
end
check(not HasSpec(), "what only Retail has stays out of Forever's list")
check(ns.Conditions.Text({ word = "mod:shift", no = true }) == "nomod:shift", "the opposite in the game's words")
check(ns.Conditions.Text({ word = "stance", value = "2" }) == "stance:2", "with its value")
check((ns.Conditions.Words({ word = "combat", no = true })) == "Out of a fight", "and in plain ones")
check((ns.Conditions.Words({ word = "stance", value = "2" })):find(": 2", 1, true), "a value shows")
check((ns.Conditions.Words({ word = "odd" })) == "odd", "a word not in the list shows as it is")

-- A game's macro taken over.
local taken = Book.FromGame("Mount", "/use Horse")
check(taken.top and taken.steps[1].kind == "text" and taken.steps[1].what == "/use Horse", "as macro text, from the top")

-- What can be let go on the list.
GetCursorInfo = function() return "spell", 3, "spell", 772 end
local dropped = ns.Steps.FromCursor()
check(dropped.kind == "spell" and dropped.what == "Rend" and dropped.id == 772, "a spell")
GetCursorInfo = function() return "item", 6948, "link" end
dropped = ns.Steps.FromCursor()
check(dropped.kind == "item" and dropped.what == "Hearthstone" and dropped.id == 6948, "an item")
GetCursorInfo = function() return "macro", 1 end
dropped = ns.Steps.FromCursor()
check(dropped.kind == "text" and dropped.what == "/use Horse", "a game's macro")
GetCursorInfo = function() return "money", 5 end
check(ns.Steps.FromCursor() == nil, "nothing else")

Editor.Toggle()

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

io.write(("Macros: all %d checks passed.\n"):format(passed))
