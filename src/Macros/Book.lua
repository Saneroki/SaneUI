local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros - Book
--  Your macros, in plain data; nothing here knows a frame.
--
--  A macro (the account's: Core.Store):
--    id        its number, which stays when it is renamed
--    name      what you call it
--    top       true: every press starts at the top; else each press goes on
--    fresh     back to the first step when a fight ends
--    steps     its steps, in order
--  A step:
--    kind      "spell", "item" or "text"
--    what      the spell's or item's name; the macro text
--    id        the spell's or item's number, where it is known
--    unit      who it is cast on ("mouseover"); nil: your target
--    when      its conditions: { word, no, value } each
--    often     how many times it comes up in a round
--    off       switched off
--  The character's (Core.Character): keys[key] = macro id, and
--  places["ActionButton1:2"] = macro id: a bar's prefix, a button, Bar 1's page.
-------------------------------------------------------------------------------
local Book = {}
ns.Book = Book

Book.KINDS = { spell = true, item = true, text = true }
Book.MOST_OFTEN = 5

-- A step as saved may be anything: it is kept only in the shape read here.
local function CleanStep(step)
    if type(step) ~= "table" or not Book.KINDS[step.kind] then return nil end
    step.what = type(step.what) == "string" and step.what or ""
    if type(step.id) ~= "number" then step.id = nil end
    if type(step.unit) ~= "string" then step.unit = nil end
    if type(step.often) ~= "number" or step.often < 1 then step.often = 1 end
    step.often = math.min(math.floor(step.often), Book.MOST_OFTEN)
    step.off = step.off and true or nil
    local when = {}
    for _, condition in ipairs(type(step.when) == "table" and step.when or {}) do
        if type(condition) == "table" and type(condition.word) == "string" then
            when[#when + 1] = { word = condition.word, no = condition.no and true or nil,
                                value = type(condition.value) == "string" and condition.value or nil }
        end
    end
    step.when = when
    return step
end

local function CleanMacro(macro)
    if type(macro) ~= "table" or type(macro.id) ~= "number" then return nil end
    macro.name = type(macro.name) == "string" and macro.name or ns.TEXT.firstName
    macro.top = macro.top and true or nil
    macro.fresh = macro.fresh ~= false
    local steps = {}
    for _, step in ipairs(type(macro.steps) == "table" and macro.steps or {}) do
        steps[#steps + 1] = CleanStep(step)
    end
    macro.steps = steps
    return macro
end

-- At load: what the saved files hold, in the shape this version reads.
function Book.Clean()
    local store = ns.store
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
    local own = ns.own
    own.keys = type(own.keys) == "table" and own.keys or {}
    own.places = type(own.places) == "table" and own.places or {}
end

function Book.All()
    return ns.store.macros
end

function Book.Find(id)
    for _, macro in ipairs(ns.store.macros) do
        if macro.id == id then return macro end
    end
    return nil
end

function Book.Step(kind, what, id)
    return { kind = kind or "spell", what = what or "", id = id, when = {}, often = 1 }
end

function Book.New(name)
    local store = ns.store
    local macro = { id = store.nextId, name = name or ns.TEXT.firstName, fresh = true, steps = {} }
    store.nextId = store.nextId + 1
    store.macros[#store.macros + 1] = macro
    return macro
end

-- A copy under a new name: plain data, step by step, with its own number.
function Book.Copy(macro)
    local copy = Book.New(ns.TEXT.copyOf:format(macro.name))
    copy.top, copy.fresh = macro.top, macro.fresh
    for index, step in ipairs(macro.steps) do
        local new = Book.Step(step.kind, step.what, step.id)
        new.unit, new.often, new.off = step.unit, step.often, step.off
        for at, condition in ipairs(step.when) do
            new.when[at] = { word = condition.word, no = condition.no, value = condition.value }
        end
        copy.steps[index] = new
    end
    return copy
end

-- Gone from the account. Other characters' keys and places to it fall away at their next login, by Reach.
function Book.Delete(macro)
    for index, candidate in ipairs(ns.store.macros) do
        if candidate == macro then
            table.remove(ns.store.macros, index)
            break
        end
    end
    for key, id in pairs(ns.own.keys) do
        if id == macro.id then ns.own.keys[key] = nil end
    end
    for place, id in pairs(ns.own.places) do
        if id == macro.id then ns.own.places[place] = nil end
    end
end

-- A step goes from one place in the list to another.
function Book.Move(macro, from, to)
    local steps = macro.steps
    if not steps[from] or to < 1 or to > #steps or from == to then return false end
    table.insert(steps, to, table.remove(steps, from))
    return true
end

-- A macro of the game's, taken over as a step of macro text under its name.
function Book.FromGame(name, body)
    local macro = Book.New(name)
    macro.top = true
    macro.steps[1] = Book.Step("text", body or "")
    return macro
end

-- This character's key of a macro, or nil.
function Book.KeyOf(macro)
    for key, id in pairs(ns.own.keys) do
        if id == macro.id then return key end
    end
    return nil
end

-- This character's bar button of a macro, or nil.
function Book.PlaceOf(macro)
    for place, id in pairs(ns.own.places) do
        if id == macro.id then return place end
    end
    return nil
end
