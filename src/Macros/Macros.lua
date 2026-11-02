local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros
--  The module's own table (ns in all its files), its words, its switches and
--  how it stands down. An addon of its own (SaneUI_Macros): it needs Core and
--  nothing else, and is switched on and off in the game's addon list.
--
--  Sane Macros stands in for the game's macro window. A macro is a list of
--  steps, as long as you like; one step is what a normal macro is. There are no
--  macro slots to run out of: a macro lives in Sane UI's saved settings, for the
--  whole account, and reaches the game by a key or a bar button of the character.
--    Conditions.lua  the game's macro conditions in plain words, explained
--    Book.lua        your macros and steps, and each character's keys and places
--    Write.lua       a macro written out into what one press may do
--    Check.lua       what would not work as it stands
--    Press.lua       a macro's secure button: what runs on each press
--    Face.lua        our button lying over a bar button, its picture and swirl
--    Reach.lua       keys and bar buttons
--    Place.lua       choosing a bar button with the mouse
--    Picker.lua      the list of conditions behind the + button
--    Steps.lua       a macro's steps in a list
--    Detail.lua      the chosen step's settings
--    Editor.lua      the window
--
--  What the game allows sets the shape. On a press, secure code may rewrite the
--  button it runs on, in a fight too, and may ask the game's macro conditions.
--  It cannot read rage, cooldowns or auras, and neither can it be told by other
--  code in a fight. So a step that cannot be cast costs that press and nothing
--  else, and only conditions can skip a step. Standing down, every key and bar
--  button is the game's again (GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Macros", ns)

local function Word(name, fallback) return Core.Word(name, fallback) end

-- Its words in the game's key bindings.
BINDING_NAME_SANEUI_MACROS = "Open or close Sane Macros"

-- Every word the module shows, but the conditions' (Conditions.lua); the game's own where it has one.
ns.TEXT = {
    title = "Sane Macros",
    about = "Sane Macros, the window of your macros and sequences",
    macros = "Your macros",
    none = "No macros yet. New makes the first.",
    new = "New",
    newTip = "A new macro, empty, or one taken over from the game's macros.",
    newEmpty = "An empty macro",
    newFrom = "From the game's macros",
    newFromNone = "The game has no macros here.",
    copy = "Copy",
    copyTip = "A copy of this macro, under a new name.",
    delete = Word("DELETE", "Delete"),
    deleteTip = "Deletes this macro, on every character of your account.",
    deleteAsk = "Delete the macro %s, on every character of your account?",
    copyOf = "%s (copy)",
    firstName = "New macro",

    name = Word("NAME", "Name"),
    nameTip = "What the macro is called. Names may repeat, and may be as long as you like.",

    key = "Key",
    keyNone = "Set key",
    keyTip = "The key of this macro, on this character. It stays out of the game's own key settings: take it away here and the key is as it was.",
    keyWait = "Press a key",
    keyClear = "Right click takes the key away.",
    keyTaken = "It takes over from %s while it is set.",
    keyOther = "That key held another macro, %s: it is yours now.",

    place = "Place on bar",
    placeTip = "Click, or drag the macro's picture, and choose a button on your action bars. What that button holds stays underneath. On this character.",
    placed = "On a bar",
    placedTip = "On %s, button %d. Click to choose another. Right click takes it off.",
    placeAsk = "Click the action bar button for %s. Esc or a right click cancels.",
    picture = "The picture of the step that comes next. Drag it onto an action bar to place the macro.",
    bars = { "Bar 1", "Bar 2", "Bar 3", "Bar 4", "Bar 5", "Bar 6", "Bar 7", "Bar 8" },

    order = "Order",
    orderTurn = "Each press takes the next step",
    orderTurnTip = "A sequence. Every press goes on to the next step and comes round again. A step the game refuses costs that one press, so keep pressing: what can be cast gets its turn. Conditions skip a step without costing a press.",
    orderTop = "Every press starts at the top",
    orderTopTip = "A normal macro. Every press takes the first step whose conditions hold. Use conditions to choose between steps; a step without conditions ends the list.",
    fresh = "Back to the first step after a fight",
    freshTip = "When a fight ends, the next press starts at the first step again.",

    steps = "Steps",
    stepsNone = "No steps yet. Add one, or drop a spell, an item or a macro of the game's here.",
    add = "Add step",
    addTip = "A new step after the one chosen. You can also drop a spell, an item or a macro of the game's on this list.",
    stepOn = "On",
    stepOnTip = "Off, the step is left out and the macro goes on as if it were not there.",
    stepTake = "Delete step",
    stepDrag = "Drag to move this step.",
    stepEmpty = "(nothing yet)",

    kind = "Kind",
    kinds = { spell = "Spell", item = "Item", text = "Macro text" },
    kindTip = "Spell and Item are the quick way. Macro text is a normal macro with any commands: /cast, /use, /target, /stopcasting and the rest.",
    spell = "Spell's name",
    spellTip = "The spell's name, or drop it here from your spellbook. Its highest rank is cast.",
    item = "Item's name",
    itemTip = "The item's name, or drop it here from your bags.",
    text = "Macro text",
    textTip = "Up to 255 characters in a step. The + button adds a condition where the cursor stands.",
    letters = "%d of 255",

    target = "Cast on",
    targetTip = "Who the step is cast on, and who its conditions about a target ask about.",
    targets = {
        { "", "Your target", "The usual: your target, or yourself where the spell allows." },
        { "mouseover", "Under the mouse", "Whoever the mouse is on, in the world or on a unit frame." },
        { "focus", "Your focus", "The one you set as your focus." },
        { "player", "Yourself", "You, whatever you have targeted." },
        { "targettarget", "Your target's target", "Whoever your target has targeted." },
        { "pet", "Your pet", "Your pet." },
        { "party1", "Party member 1", "The first other member of your party." },
        { "party2", "Party member 2", "The second other member of your party." },
        { "party3", "Party member 3", "The third other member of your party." },
        { "party4", "Party member 4", "The fourth other member of your party." },
        { "cursor", "At the mouse", "A spell cast on the ground lands at the mouse at once." },
    },

    often = "Comes up",
    oftenTip = "How many times this step comes up in one round of the macro. They are spread out evenly among the others. Only with Each press takes the next step.",
    oftenWord = "%d× a round",

    when = "Only when",
    whenTip = "All of these must hold for the step to run. If not, the step is skipped in that same press.",
    whenAdd = "Add a condition",
    whenNone = "Always",
    whenFlip = "Click: the opposite. Right click: take it away.",
    whenAsk = "Which %s?",

    writes = "The game gets",
    writesTip = "What this step comes to as a macro line.",

    problems = "%d to look at",

    check = {
        noSteps = "This macro has no steps yet.",
        allOff = "Every step is switched off.",
        unreachable = "Never reached: the step above has no conditions, and every press stops there.",
        empty = "This step is empty.",
        noSpell = "The game knows no spell of this name.",
        notKnown = "This character does not know this spell.",
        noItem = "The game knows no item of this name yet. It may only need a moment; check the spelling.",
        noneHeld = "This character has none of this item.",
        contradiction = "It can never run: %s and %s cannot both hold.",
        tooLong = "Too long: the game runs only the first 255 characters of a step.",
        brackets = "A bracket is left open in: %s",
        unknownWord = "The game ignores words it does not know and takes them as true: %s",
        notCommand = "This line has no / and would be sent to chat: %s",
        afterOpen = "Never reached: after a ; with no condition, nothing more can be picked: %s",
        secondCast = "Only the first /cast of a step is sure to run. Make the second one a step of its own: %s",
    },

    noCombat = "Not in a fight: this changes the game's secure buttons.",

    checks = "Check macros",
    checksTip = "Looks over your macros when they change, and when you learn something new while the window is open, and marks what would not work.",
    usable = "Dim what cannot be used",
    usableTip = "A macro on a bar button is dimmed while its next step cannot be used, as the game does.",
    keyText = "Show the key on the button",
    keyTextTip = "A macro on a bar button shows that button's key.",
}

ns.GIVEN_BACK = "your bar buttons and keys are the game's again"

-- A button of this window: dark, with a thin bronze edge, as no red button is wanted and no metal one is picked yet.
local PLATE, EDGE, LIT = { 0.09, 0.08, 0.07 }, { 0.62, 0.5, 0.3 }, { 0.2, 0.17, 0.12 }

local function Light(button, colour)
    button:SetBackdropColor(colour[1], colour[2], colour[3], 0.95)
end

function ns.Button(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 22)
    button:EnableMouse(true)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    button:SetBackdropBorderColor(EDGE[1], EDGE[2], EDGE[3], 1)
    Light(button, PLATE)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("CENTER")
    button:SetFontString(button.label)
    button:SetDisabledFontObject("GameFontDisableSmall")
    button:SetText(text)
    button:HookScript("OnEnter", ns.Guard(function(self) Light(self, LIT) end))
    button:HookScript("OnLeave", ns.Guard(function(self) Light(self, PLATE) end))
    return button
end

local OPTIONS = {
    { key = "checks", default = true, text = ns.TEXT.checks, tip = ns.TEXT.checksTip },
    { key = "usable", default = true, text = ns.TEXT.usable, tip = ns.TEXT.usableTip },
    { key = "keyText", default = true, text = ns.TEXT.keyText, tip = ns.TEXT.keyTextTip },
}
Core.Options(ns.name, OPTIONS, {
    changed = function(key)
        if key == "checks" then
            ns.Safe("checks", ns.Editor.Refresh)
        else
            ns.Safe("faces", ns.Face.Paint)
        end
    end,
})

-- Standing down: every key and bar button is the game's again.
function ns.GiveBack()
    ns.Safe("give back", ns.Place.Stop)
    ns.Safe("give back", ns.Reach.GiveBack)
    ns.Safe("give back", ns.Editor.GiveBack)
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
    ns.store = Core.Store(ns.name)
    ns.Book.Clean()
    Core.Command("macros", ns.TEXT.about, ns.Guard(function() ns.Editor.Toggle() end), "macro")
end

function ns.OnLogin()
    ns.own = Core.Character(ns.name)
    ns.Book.CleanOwn()
    ns.Editor.Prepare()
    ns.Reach.Start()
end

SaneUI.Macros = ns
