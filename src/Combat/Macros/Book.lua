local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Book
--  Your macros, in plain data; nothing here knows a frame.
--
--  A macro (the account's: Core.Store):
--    id        its number, which stays when it is renamed
--    name      what you call it
--    top       true: every press starts at the top; else each press goes on
--    fresh     back to the first step when a fight ends
--    steps     its steps, in order
--    icon      its own picture (a texture's path or number); nil: its steps' (Press.MacroPicture)
--    class     a class's file name ("WARRIOR"): the macro is that class's characters'
--    char      a character's key (Core.charKey): the macro is that character's
--              neither: every character's, a general one (Saneroki, 2026-11-04: "only the
--              relevant ones for each class", the list filtered by whose they are)
--  A step:
--    kind      "spell", "item" or "text"
--    what      the spell's or item's name; the macro text
--    id        the spell's or item's number, where it is known
--    units     who it is cast on, in order ({ "mouseover", "" }; "": your target); none: your
--              target. A unit alone (unit = "mouseover"), as other code may give it, is read too
--    when      its conditions: { word, no, value } each; Sane Macros' own too ("once":
--              Once per target), which have no opposite (Conditions.OURS)
--    often     how many times it comes up in a round
--    off       switched off
--  The character's (Core.Character): keys[key] = macro id, and
--  places["ActionButton1:2"] = macro id: a bar's prefix, a button, Bar 1's page;
--  filter: what the list shows ("own", "general", "all").
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Book = {}
Macros.Book = Book

Book.KINDS = { spell = true, item = true, text = true }
Book.MOST_OFTEN = 5

-- A step as saved may be anything: it is kept only in the shape read here.
local function CleanStep(step)
    if type(step) ~= "table" or not Book.KINDS[step.kind] then return nil end
    step.what = type(step.what) == "string" and step.what or ""
    if type(step.id) ~= "number" then step.id = nil end
    local units, seen = {}, {}
    local given = type(step.units) == "table" and step.units or { step.unit }
    for _, unit in ipairs(given) do
        if type(unit) == "string" and not seen[unit] then
            seen[unit] = true
            units[#units + 1] = unit
        end
    end
    step.units, step.unit = units, nil
    if type(step.often) ~= "number" or step.often < 1 then step.often = 1 end
    step.often = math.min(math.floor(step.often), Book.MOST_OFTEN)
    step.off = step.off and true or nil
    local when = {}
    for _, condition in ipairs(type(step.when) == "table" and step.when or {}) do
        if type(condition) == "table" and type(condition.word) == "string" then
            local ours = Macros.Conditions.OURS[condition.word]
            when[#when + 1] = { word = condition.word, no = condition.no and not ours or nil,
                                value = type(condition.value) == "string" and condition.value or nil }
        end
    end
    step.when = when
    return step
end

-- A picture as kept: a texture's path or number, never the question mark (that is no picture of its own).
function Book.Icon(picture)
    if type(picture) == "string" and picture ~= "" and picture:lower() ~= Macros.Press.ICON:lower() then return picture end
    if type(picture) == "number" and picture > 0 and picture ~= Book.QUESTION then return picture end
    return nil
end
Book.QUESTION = 134400 -- the question mark's file number, the picture the game gives a macro without one

local function CleanMacro(macro)
    if type(macro) ~= "table" or type(macro.id) ~= "number" then return nil end
    macro.name = type(macro.name) == "string" and macro.name or Macros.TEXT.firstName
    macro.icon = Book.Icon(macro.icon)
    macro.top = macro.top and true or nil
    macro.fresh = macro.fresh ~= false
    macro.class = type(macro.class) == "string" and macro.class:match("^%u+$") or nil
    macro.char = type(macro.char) == "string" and macro.char ~= "" and macro.char or nil
    local steps = {}
    for _, step in ipairs(type(macro.steps) == "table" and macro.steps or {}) do
        steps[#steps + 1] = CleanStep(step)
    end
    macro.steps = steps
    return macro
end

-- At load: what the saved files hold, in the shape this version reads.
function Book.Clean()
    local store = Macros.store
    local macros, highest = {}, 0
    for _, macro in ipairs(type(store.macros) == "table" and store.macros or {}) do
        local clean = CleanMacro(macro)
        if clean then
            macros[#macros + 1] = clean
            highest = math.max(highest, clean.id)
        end
    end
    store.macros = macros
    store.nextId = math.max(type(store.nextId) == "number" and store.nextId or 1, highest + 1)
end

-- At login: this character's keys and places.
function Book.CleanOwn()
    local own = Macros.own
    own.keys = type(own.keys) == "table" and own.keys or {}
    own.places = type(own.places) == "table" and own.places or {}
    if not Book.FILTER_WORDS[own.filter] then own.filter = nil end
end

function Book.All()
    return Macros.store.macros
end

-- Whose a macro is: "general" (every character's), "class" (a class's), "character" (one character's).
function Book.Owner(macro)
    if macro.char then return "character" end
    if macro.class then return "class" end
    return "general"
end

-- It becomes every character's, this character's class's or this character's own.
function Book.SetOwner(macro, owner)
    macro.class = owner == "class" and Core.class or nil
    macro.char = owner == "character" and Core.charKey or nil
end

-- Whether this character uses it: a general one, its class's or its own.
function Book.Mine(macro)
    return (not macro.class or macro.class == Core.class) and (not macro.char or macro.char == Core.charKey)
end

-- The list's filters: this character's (its class's and its own), the general ones, every one of the account's.
Book.FILTERS = { "own", "general", "all" }
Book.FILTER_WORDS = { own = true, general = true, all = true }

function Book.Shown(filter)
    local shown = {}
    for _, macro in ipairs(Macros.store.macros) do
        local general = Book.Owner(macro) == "general"
        if filter == "all" or (filter == "general" and general) or (filter == "own" and not general and Book.Mine(macro)) then
            shown[#shown + 1] = macro
        end
    end
    return shown
end

-- The macro of that name this character uses: its own or its class's before a general one; nil if none.
function Book.Named(name)
    local found
    for _, macro in ipairs(Macros.store.macros) do
        if macro.name == name and Book.Mine(macro) then
            if Book.Owner(macro) ~= "general" then return macro end
            found = found or macro
        end
    end
    return found
end

function Book.Find(id)
    for _, macro in ipairs(Macros.store.macros) do
        if macro.id == id then return macro end
    end
    return nil
end

function Book.Step(kind, what, id)
    return { kind = kind or "spell", what = what or "", id = id, units = {}, when = {}, often = 1 }
end

function Book.New(name)
    local store = Macros.store
    local macro = { id = store.nextId, name = name or Macros.TEXT.firstName, fresh = true, steps = {} }
    store.nextId = store.nextId + 1
    store.macros[#store.macros + 1] = macro
    return macro
end

-- A copy under a new name: plain data, step by step, with its own number.
function Book.Copy(macro)
    local copy = Book.New(Macros.TEXT.copyOf:format(macro.name))
    copy.top, copy.fresh, copy.icon, copy.class, copy.char = macro.top, macro.fresh, macro.icon, macro.class, macro.char
    for index, step in ipairs(macro.steps) do
        local new = Book.Step(step.kind, step.what, step.id)
        new.often, new.off = step.often, step.off
        for at, unit in ipairs(Macros.Write.Units(step)) do new.units[at] = unit end
        for at, condition in ipairs(step.when) do
            new.when[at] = { word = condition.word, no = condition.no, value = condition.value }
        end
        copy.steps[index] = new
    end
    return copy
end

-- Gone from the account. Other characters' keys and places to it fall away at their next login, by Reach.
function Book.Delete(macro)
    for index, candidate in ipairs(Macros.store.macros) do
        if candidate == macro then
            table.remove(Macros.store.macros, index)
            break
        end
    end
    for key, id in pairs(Macros.own.keys) do
        if id == macro.id then Macros.own.keys[key] = nil end
    end
    for place, id in pairs(Macros.own.places) do
        if id == macro.id then Macros.own.places[place] = nil end
    end
end

-- A step goes from one place in the list to another.
function Book.Move(macro, from, to)
    local steps = macro.steps
    if not steps[from] or to < 1 or to > #steps or from == to then return false end
    table.insert(steps, to, table.remove(steps, from))
    return true
end

-- A macro of the game's, taken over as a step of macro text under its name, with its picture.
function Book.FromGame(name, body, icon)
    local macro = Book.New(name)
    macro.icon = Book.Icon(icon)
    macro.top = true
    macro.steps[1] = Book.Step("text", body or "")
    return macro
end

-- A macro of steps from other code (Macros.Add): { top, fresh, steps = { a step as above, ... } }, each step kept only in
-- the shape read here, as one saved; a step that is no step is left out.
function Book.FromSteps(name, spec)
    return Book.Fill(Book.New(name), spec)
end

-- A macro's steps made anew (Macros.Set): of macro text one step of it, from the top; of { top, fresh, steps } those
-- steps, as FromSteps takes them. Its number, name, picture and whose it is stay.
function Book.Fill(macro, body)
    if type(body) == "string" then
        macro.top, macro.fresh, macro.steps = true, true, { Book.Step("text", body) }
        return macro
    end
    macro.top = body.top and true or nil
    macro.fresh = body.fresh ~= false
    macro.steps = {}
    for _, given in ipairs(type(body.steps) == "table" and body.steps or {}) do
        local copy = {}
        if type(given) == "table" then
            for key, value in pairs(given) do copy[key] = value end
        end
        macro.steps[#macro.steps + 1] = CleanStep(copy)
    end
    return macro
end

-- This character's key of a macro, or nil.
function Book.KeyOf(macro)
    for key, id in pairs(Macros.own.keys) do
        if id == macro.id then return key end
    end
    return nil
end

-- This character's bar button of a macro, or nil.
function Book.PlaceOf(macro)
    for place, id in pairs(Macros.own.places) do
        if id == macro.id then return place end
    end
    return nil
end
