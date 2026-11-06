local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros
--  Sane Macros, a part of Combat: in the game's macro window's stead, on Combat's
--  full screen beside the action bars. A macro is a list of steps, as long as you
--  like; one step is what a normal macro is. There are no macro slots to run out
--  of: a macro lives in Sane UI's saved settings, for the whole account, and
--  reaches the game by a key or a bar button of the character.
--    Conditions.lua  the game's macro conditions in plain words, explained
--    Book.lua        your macros and steps, and each character's keys and places
--    Write.lua       a macro written out into what one press may do
--    Check.lua       what would not work as it stands
--    Press.lua       a macro's secure button: what runs on each press
--    Face.lua        our button lying over a bar button, its picture and swirl
--    Reach.lua       keys and bar buttons
--    Place.lua       choosing a bar button with the mouse
--    Icons.lua       the picture window: the game's icons by group, searched
--    Picker.lua      the list of conditions behind the + button
--    Steps.lua       a macro's steps in a list
--    Detail.lua      the chosen step's settings
--    Editor.lua      the page, its panel on the full screen, its own window
--
--  What the game allows sets the shape. On a press, secure code may rewrite the
--  button it runs on, in a fight too, and may ask the game's macro conditions.
--  It cannot read rage, cooldowns or auras, and neither can it be told by other
--  code in a fight. So a step that cannot be cast costs that press and nothing
--  else, and only conditions can skip a step. Standing down, every key and bar
--  button is the game's again (Macros.GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Macros = {}
ns.Macros = Macros

-- Where macros are kept: under this name, apart from Combat's own settings.
Macros.STORE = "Macros"

local function Word(name, fallback) return Core.Word(name, fallback) end

-- Every word it shows, but the conditions' (Conditions.lua); the game's own where it has one.
Macros.TEXT = {
    title = "Sane Macros",
    about = "Sane Macros, the window of your macros and sequences",
    macros = "Your macros",
    none = "No macros yet. New makes the first.",
    new = "New",
    newTip = "A new macro, empty, or one taken over from the game's macros.",
    newEmpty = "An empty macro",
    newFrom = "From the game's macros",
    newFromNone = "The game has no macros here.",
    gameWindow = "Game macros",
    gameWindowTip = "Opens the game's own macro window. The button Sane UI on it brings Sane Macros back.",
    gameMark = "W",
    gameMacros = "The game's macros",
    lineTip = "Click: choose it. Right click: whose it is. Drag it onto a button of your action bars to place it there.",
    filterOwn = "This character",
    filterGeneral = "General",
    filterAll = "Show all",
    filterTip = "Which macros the list shows: this character's (its class's and its own), the general ones every character has, or all of your account's. The game's macros below follow it: its general ones are the account's, its character ones this character's.",
    noneHere = "None here. The filter above shows the others.",
    whose = "Whose it is",
    whoseGeneral = "Every character's",
    whoseClass = "Every %s's",
    whoseCharacter = "%s's alone",
    whoseOther = "Now another class's or character's",
    whoseTip = "Which characters have it in their list: every one, those of a class, or one alone. Every character can still press it from a key or a bar button it was put on.",
    lineKey = "Key: %s",
    gameLine = "One of the game's macros",
    gameLineTip = "Click: opens it in the game's macro window. Drag: onto an action bar, as a macro of the game's. Right click: make a Sane Macro of it.",
    gameOpen = "Open in the game's macro window",
    gameTake = "Make a Sane Macro of it",
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
    faceTip = "Drag it with the pick-up key (Shift) to another button, or off the bars. A spell or item dropped on it takes its place.",
    placeAsk = "Click the action bar button for %s. Esc or a right click cancels.",
    picture = "The macro's picture. Click: choose another. Drag it onto an action bar to place the macro; there it shows the step that comes next.",

    iconTitle = "Choose a picture",
    iconSearch = "Search the pictures",
    iconCount = "%s pictures",
    iconReading = "Reading the game's pictures...",
    iconNone = "No picture found.",
    iconClear = "Steps' picture",
    iconClearTip = "No picture of its own: the macro shows the picture of its first step.",
    iconSpells = "Spells: %s",
    iconItems = "Items: %s",
    iconMore = "and %d more",
    iconFile = "File %d",
    iconNumber = "Picture %d",
    iconChosen = "The macro's picture now",
    iconClick = "Click: the macro's picture.",
    iconGroups = {
        all = "All", game = "In the game", weapons = "Weapons", armor = "Armor", consumables = "Consumables",
        goods = "Trade goods", items = "Other items", spells = "Spells and abilities", mounts = "Mounts and pets",
        achievements = "Achievements", other = "Other",
    },
    bars = { "Bar 1", "Bar 2", "Bar 3", "Bar 4", "Bar 5", "Bar 6", "Bar 7", "Bar 8" },
    barNumber = "Bar %d", -- a row a bar's button shows, such as Bar 9 on a druid's Bar 6 in Bear Form

    order = "Order",
    orderTurn = "Each press takes the next step",
    orderTurnTip = "A sequence. Every press goes on to the next step and comes round again. A step the game refuses costs that one press, so keep pressing: what can be cast gets its turn. Conditions skip a step without costing a press.",
    orderTop = "Every press starts at the top",
    orderTopTip = "A normal macro. Every press takes the first step whose conditions hold. Use conditions to choose between steps; a step without conditions ends the list.",
    fresh = "Start over after a fight",
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
        heldCasting = "The game's Press and Hold Casting is on (Options, Gameplay, Combat): a cast of this macro stops when you let go of the key. Turn it off.",
    },

    noCombat = "Not in a fight: this changes the game's secure buttons.",

}

-- A button of this window: dark, with a thin bronze edge, as no red button is wanted and no metal one is picked yet.
local PLATE, EDGE, LIT = { 0.09, 0.08, 0.07 }, { 0.62, 0.5, 0.3 }, { 0.2, 0.17, 0.12 }

local function Light(button, colour)
    button:SetBackdropColor(colour[1], colour[2], colour[3], 0.95)
end

function Macros.Button(parent, text, width, height)
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


-- The way in for other code (SaneUI.Combat.Macros.Add, a setup addon or a script): a normal macro of macro text
-- under its name, or a macro of steps ({ top, fresh, steps }, as Book.FromSteps reads it; Saneroki, 2026-11-04: a
-- setup addon's rotations), with its own picture where one is given (a texture's path or number), made once; one of
-- that name and owner already there is left as it is. owner: nil or "general" every character's, "class" this
-- character's class's, "character" this character's alone (Book.SetOwner). Returns the macro and whether it is new.
function Macros.Add(name, body, picture, owner)
    if type(name) ~= "string" or name == "" or not Macros.store then return nil end
    if type(body) ~= "string" and not (type(body) == "table" and type(body.steps) == "table") then return nil end
    local whose = {}
    Macros.Book.SetOwner(whose, owner)
    for _, macro in ipairs(Macros.Book.All()) do
        if macro.name == name and macro.class == whose.class and macro.char == whose.char then return macro, false end
    end
    local macro = type(body) == "string" and Macros.Book.FromGame(name, body) or Macros.Book.FromSteps(name, body)
    macro.icon = Macros.Book.Icon(picture)
    macro.class, macro.char = whose.class, whose.char
    ns.Safe("macros", Macros.Editor.Refresh)
    return macro, true
end

-- For other code too (Saneroki, 2026-11-04: a setup addon keeps a potion macro on the best potion held): the macro of
-- that name and owner, as Add finds it, made anew from body (macro text, or { top, fresh, steps }); its number, picture,
-- keys and places stay, its button takes it at once or at a fight's end. Whether there was one to change.
function Macros.Set(name, body, owner)
    if type(name) ~= "string" or not Macros.store then return false end
    if type(body) ~= "string" and not (type(body) == "table" and type(body.steps) == "table") then return false end
    local whose = {}
    Macros.Book.SetOwner(whose, owner)
    for _, macro in ipairs(Macros.Book.All()) do
        if macro.name == name and macro.class == whose.class and macro.char == whose.char then
            Macros.Book.Fill(macro, body)
            Macros.Press.Update(macro)
            ns.Safe("macros", Macros.Editor.Refresh)
            return true
        end
    end
    return false
end

-- For other code too (Saneroki, 2026-11-04: a setup addon puts the macros on his keys and changes them as spells are
-- learned): the macro of that name this character uses (Book.Named) on a bar button, by its place ("MultiBar5Button4",
-- "ActionButton1:1"), for this character; one button a macro, one macro a button. It stands there at once, or at a
-- fight's end. Whether it was put there.
function Macros.PlaceOn(name, place)
    if not Macros.own or type(place) ~= "string" then return false end
    local bar, button = Macros.Reach.Parts(place)
    local macro = Macros.Book.Named(name)
    if not (bar and button and button >= 1 and button <= Macros.Reach.BUTTONS and macro) then return false end
    Macros.Reach.SetPlace(macro, place)
    ns.Safe("macros", Macros.Editor.Refresh)
    return true
end

-- The macro on a bar button comes off it: the button holds again what it held. Whether one was there.
function Macros.TakeOff(place)
    if not (Macros.own and Macros.own.places[place]) then return false end
    Macros.own.places[place] = nil
    Macros.Reach.Update()
    ns.Safe("macros", Macros.Editor.Refresh)
    return true
end

-- The name of the macro on a bar button, or nil.
function Macros.On(place)
    local macro = Macros.own and Macros.Book.Find(Macros.own.places[place] or 0)
    return macro and macro.name or nil
end

function Macros.Load()
    Macros.store = Core.Store(Macros.STORE)
    Macros.Book.Clean()
end

function Macros.Start()
    Macros.own = Core.Character(Macros.STORE)
    Macros.Book.CleanOwn()
    Macros.Editor.Prepare()
    Macros.Reach.Start()
end

function Macros.GiveBack()
    ns.Safe("macros", Macros.Icons.Close)
    ns.Safe("macros", Macros.Place.Stop)
    ns.Safe("macros", Macros.Reach.GiveBack)
    ns.Safe("macros", Macros.Editor.GiveBack)
end

-- A switch of its own changed.
function Macros.Changed(key)
    if key == "macroChecks" then
        ns.Safe("macros", Macros.Editor.Refresh)
    else
        ns.Safe("macros", Macros.Face.Paint)
    end
end
