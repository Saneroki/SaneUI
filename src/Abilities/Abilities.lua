local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities
--  The module's own table (ns in all its files), the action slots, its saved
--  settings, the update pipeline and its commands (/sane abilities).
--
--  An addon of its own (SaneUI_Abilities): it needs Core and nothing else, and
--  is switched on and off in the game's addon list. It was called Spellbook until
--  its features went beyond the spellbook; Core moves what was kept under that name.
--  The spellbook is its first part (Book/).
--
--  The idea in one line: a button on a bar is a window onto a numbered action
--  slot. The game refuses a spell you do not know in a slot, so this module
--  keeps a "reservation" for the slot and places the real thing once you have it.
--
--  You make a reservation in the game's own spellbook: the spells you have not
--  learned yet are listed there in grey (Book/), and you drag one onto a button.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Abilities", ns)

ns.NUM_BUTTONS = 12

-- The bars this module manages, in the game's own numbering.
--   prefix   Blizzard's button frames
--   offset   first action slot of the bar, minus one
ns.BARS = {
    { prefix = "ActionButton",              offset = 0,   paged = true },
    { prefix = "MultiBarBottomLeftButton",  offset = 60  },
    { prefix = "MultiBarBottomRightButton", offset = 48  },
    { prefix = "MultiBarRightButton",       offset = 24  },
    { prefix = "MultiBarLeftButton",        offset = 36  },
    { prefix = "MultiBar5Button",           offset = 144 },
    { prefix = "MultiBar6Button",           offset = 156 },
    { prefix = "MultiBar7Button",           offset = 168 },
}

-- Bar 1 shows another row of 12 slots in a form, a stance or stealth.
ns.PAGES = { 0, 72, 84, 96, 108 }

-- The two marks on an icon, in the spellbook (Book/Item.lua) and on the action bars (Ghosts.lua).
ns.QUEST_MARK = "QuestNormal"                -- the quest giver's "!": a quest reward
ns.RESERVED_MARK = "auctionhouse-icon-clock" -- waiting for something: a button is reserved for it

-- The module's switches: on its page in the options (Core's) and in the spellbook's own menu (Book/Menu.lua).
-- Two sections: the book itself, with the four switches under the one they all need, then the action bars.
local OPTIONS = {
    { key = "book", default = true, text = "Sane UI lays out the spellbook pages",
      header = "Spellbook", headerTip = "The game's spellbook, laid out by Sane UI.",
      tip = "Needed for the grey spells, the Home page, compact pages and moving or resizing. Off: the game draws its pages itself after /reload, a way out if they ever look wrong." },
    { key = "showHidden", default = true, text = "Show unlearned spells", parent = "book",
      tip = "The spells you have not learned yet are listed in grey, in the tab they will be in. Drag one onto an action bar button to reserve that button for it." },
    { key = "home", default = true, text = "Open the spellbook on its Home page", parent = "book",
      tip = "Home lists what your trainer teaches you now, with the cost, and which spells come from quests. Off: the spellbook opens on the tab you last used." },
    { key = "compact", default = true, text = "Compact spellbook pages", parent = "book",
      tip = "Entries at three quarters of their size and closer together: about twice as many spells on a page." },
    { key = "window", default = true, text = "Move and resize the spellbook", parent = "book",
      tip = "Drag the bar at the top to move it and the grip in its lower right corner to resize it, not in a fight. /sane ab window reset puts it back." },
    { key = "ghosts", default = true, text = "Show reservations on the action bars",
      header = "Action bars", headerTip = "What reserved buttons show and say.",
      tip = "A reserved button shows the spell's icon in grey with a small clock in its corner until you learn it. Point at it for the spell's tooltip." },
    { key = "announce", default = true, text = "Say in chat when a reserved button is filled",
      tip = "When you learn a spell or get an item a button was reserved for, one chat line names the button. Off: it lands quietly." },
}

-- The pages change hands at a /reload only: said in chat, and offered through Core's dialog where it has one.
local function PagesChanged(on)
    ns.Print(on and "the spellbook shows your unlearned spells again after /reload."
        or "the spellbook's pages are left to the game after /reload.")
    if Core.AskReload then Core.AskReload({ "the spellbook's pages" }) end
end

Core.Options(ns.name, OPTIONS, function(key, value)
    if key == "book" then PagesChanged(value) else ns.Fire("REFRESH") end
end)

-------------------------------------------------------------------------------
--  Reading action slots
-------------------------------------------------------------------------------
local HasActionFn = (C_ActionBar and C_ActionBar.HasAction) or HasAction
local TextureFn = (C_ActionBar and C_ActionBar.GetActionTexture) or GetActionTexture
local TextFn = (C_ActionBar and C_ActionBar.GetActionText) or GetActionText

-- true or false; "unknown" while the game hides the answer. That is no answer to act on: a
-- caller that would end or place something leaves the slot alone then (Engine.lua).
function ns.HasAction(slot)
    local has = HasActionFn(slot)
    if Core.Secret(has) then return "unknown" end
    return has and true or false
end

function ns.ActionTexture(slot)
    return ns.Plain(TextureFn(slot))
end

-- What really sits in a slot, as { kind, id, name, icon }; nil for an empty slot, and for one the
-- game hides right now (what is there is no "other" thing: it is not known).
-- kind "other" is anything this module leaves alone (mounts, equipment sets, pet actions).
function ns.RealEntry(slot)
    if ns.HasAction(slot) ~= true then return nil end
    local kind, id = GetActionInfo(slot)
    kind, id = ns.Plain(kind), ns.Plain(id)
    local icon = ns.ActionTexture(slot)
    if kind == "spell" and id then
        return { kind = "spell", id = id, name = C_Spell.GetSpellName(id), icon = icon }
    elseif kind == "item" and id then
        return { kind = "item", id = id, name = C_Item.GetItemNameByID(id), icon = icon }
    elseif kind == "macro" then
        return { kind = "macro", name = ns.Plain(TextFn(slot)), icon = icon }
    end
    return { kind = "other", icon = icon }
end

-- The action slot a button shows right now, or nil. A secure action button keeps it in its
-- attribute "action"; bar addons that make buttons of their own may keep it only
-- there. Blizzard's own buttons also have it as a field. A frame addons may not read gives nil.
function ns.ActionOf(frame)
    if type(frame) ~= "table" then return nil end
    local ok, action = pcall(function() return frame.GetAttribute and frame:GetAttribute("action") end)
    action = ok and ns.Plain(action) or nil
    if type(action) ~= "number" then
        ok, action = pcall(function() return frame.action end)
        action = ok and ns.Plain(action) or nil
    end
    if type(action) == "number" and action >= 1 and action <= 180 then return action end
    return nil
end

-- Which row of slots Bar 1 shows right now: 0 normally, 72/84/96/108 in a form or stance.
-- The first button of Bar 1 knows.
function ns.Bar1Offset()
    local button = _G.ActionButton1
    local action = ns.ActionOf(button)
    if action and action <= 120 then
        return action - 1 - ((action - 1) % ns.NUM_BUTTONS)
    end
    return 0
end

-- The slot a real button shows right now; for Bar 1 it changes with your form or stance.
function ns.SlotOf(button, fallback)
    return ns.ActionOf(button) or fallback
end

local managed
-- Every slot the module looks after: the bars plus Bar 1's form and stance rows.
function ns.ManagedSlots()
    if not managed then
        managed = {}
        for _, bar in ipairs(ns.BARS) do
            for i = 1, ns.NUM_BUTTONS do managed[#managed + 1] = bar.offset + i end
        end
        for page = 2, #ns.PAGES do
            for i = 1, ns.NUM_BUTTONS do managed[#managed + 1] = ns.PAGES[page] + i end
        end
    end
    return managed
end

function ns.PageName(offset)
    if offset == 0 then return "normal" end
    local names = ns.DB and ns.DB.pageNames[ns.class]
    if type(names) == "table" and names[offset] then return names[offset] end
    for page = 2, #ns.PAGES do
        if ns.PAGES[page] == offset then return "form or stance " .. (page - 1) end
    end
    return "page " .. (offset / ns.NUM_BUTTONS + 1)
end

function ns.SlotLabel(slot)
    for number, bar in ipairs(ns.BARS) do
        if slot > bar.offset and slot <= bar.offset + ns.NUM_BUTTONS then
            return ("Bar %d, button %d"):format(number, slot - bar.offset)
        end
    end
    local offset = slot - 1 - ((slot - 1) % ns.NUM_BUTTONS)
    for page = 2, #ns.PAGES do
        if ns.PAGES[page] == offset then
            return ("Bar 1 (%s), button %d"):format(ns.PageName(offset), slot - offset)
        end
    end
    return ("action slot %d"):format(slot)
end

-- t[key] as a table: what is there if it is one, a new one if not. Saved data comes from older
-- versions and from hand edits, so a value of the wrong kind is replaced, not trusted.
local function Table(t, key)
    if type(t[key]) ~= "table" then t[key] = {} end
    return t[key]
end

-- The game never says which row belongs to which form, so the name is noted
-- the first time you are in that form: "Bear Form" instead of "form or stance 3".
local function LearnPageName()
    if not (GetShapeshiftForm and GetShapeshiftFormInfo) then return end
    local form = ns.Plain(GetShapeshiftForm())
    local offset = ns.Bar1Offset()
    if not form or form < 1 or offset < ns.PAGES[2] then return end
    local _, _, _, spellID = GetShapeshiftFormInfo(form)
    spellID = ns.Plain(spellID)
    local name = spellID and C_Spell.GetSpellName(spellID)
    if name then Table(ns.DB.pageNames, ns.class)[offset] = name end
end

-------------------------------------------------------------------------------
--  One update pipeline: read the spellbook, place what can be placed, redraw.
--  Events arrive in bursts, so they only ask for an update; it runs once, a moment later.
-------------------------------------------------------------------------------
local queued, wantScan = false, false

local function RunUpdate()
    queued = false
    if not ns.ready then return end
    -- What you have is read again out of a fight only: in one nothing real can be placed, and an
    -- update in a fight asks for another once it is over (Core.AfterCombat: however many there
    -- were, one). The list of spells still to come is not built here at all, but when something
    -- shows it (Sources.lua, S.All).
    if InCombatLockdown() then
        Core.AfterCombat("Abilities: update", ns.QueueUpdate, false)
    elseif wantScan then
        wantScan = false
        ns.Safe("scan", ns.Sources.ScanBook)
    end
    ns.Safe("pages", LearnPageName)
    ns.Safe("reconcile", ns.Engine.Reconcile)
    ns.Fire("REFRESH")
end

function ns.QueueUpdate(scan, delay)
    wantScan = wantScan or scan or false
    if queued then return end
    queued = true
    C_Timer.After(delay or 0.2, RunUpdate)
end

-------------------------------------------------------------------------------
--  Saved settings (kept by Core, in SaneUIDB.modules.Abilities)
-------------------------------------------------------------------------------
function ns.OnLoad()
    ns.options = Core.Settings(ns.name) -- the switches above, as Core keeps them
    local db = Core.Store(ns.name)
    Table(db, "presets")                -- per class: saved layouts
    Table(db, "extras")                 -- per class: spells added by hand
    Table(db, "trainer")                -- per class: what was read at the class trainer
    Table(db, "pageNames")              -- per class: names of Bar 1's form rows
    ns.DB = db
end

-- A reservation is { kind = "spell" | "item" | "macro", id, name, icon } on an action slot.
-- One of another shape (an older version, a hand edit) is dropped, so nothing trips over it later:
-- the game's action functions fail on a slot that is none, and on an ID that is no number, and a
-- texture fails on an icon that is neither a file ID nor a path.
local MAX_SLOT = 180
local function Texture(icon)
    return icon == nil or type(icon) == "number" or type(icon) == "string"
end
ns.Texture = Texture -- also for the slots of a saved layout (Presets.lua)

local function KeepReservations(reserved)
    for slot, entry in pairs(reserved) do
        local good = type(slot) == "number" and slot >= 1 and slot <= MAX_SLOT and slot % 1 == 0
            and type(entry) == "table" and type(entry.kind) == "string"
            and (entry.id == nil or type(entry.id) == "number") and (entry.name == nil or type(entry.name) == "string")
            and Texture(entry.icon)
        if not good then reserved[slot] = nil end
    end
end

function ns.OnLogin()
    local db, class = ns.DB, Core.class
    ns.class = class
    ns.char = Core.Character(ns.name)   -- db.chars, per character: the reservations
    KeepReservations(Table(ns.char, "reserved"))

    Table(db.presets, class)
    Table(db.extras, class)
    local trainer = Table(db.trainer, class)
    Table(trainer, "tabs")
    Table(trainer, "spells")
    -- The trainer data meant for your class, faction and race (Data/Trainer.lua).
    ns.Safe("trainer data", ns.Data.Fill)

    local function scan() ns.QueueUpdate(true) end
    local function update() ns.QueueUpdate(false) end

    ns.On("SPELLS_CHANGED", scan)
    ns.On("LEARNED_SPELL_IN_SKILL_LINE", scan)
    ns.On("PLAYER_LEVEL_UP", scan)
    ns.On("ACTIONBAR_SLOT_CHANGED", update)
    ns.On("ACTIONBAR_PAGE_CHANGED", update)
    ns.On("UPDATE_BONUS_ACTIONBAR", update)
    ns.On("UPDATE_OVERRIDE_ACTIONBAR", update)
    ns.On("UPDATE_SHAPESHIFT_FORM", update)
    ns.On("UPDATE_BINDINGS", update)
    ns.On("UPDATE_MACROS", update)
    ns.On("BAG_UPDATE_DELAYED", update)
    ns.On("PLAYER_REGEN_DISABLED", update)
    ns.On("CURSOR_CHANGED", function()
        if ns.Engine.pending then update() end
    end)
    -- The game put a new spell on a button by itself: which spell, and the action slot.
    ns.On("SPELL_PUSHED_TO_ACTIONBAR", function(spellID, slot)
        ns.Engine.NotePushed(ns.Plain(spellID), ns.Plain(slot))
        update()
    end)
    -- A name the game had to fetch first: what shows the list draws it again (many come at once).
    ns.On("SPELL_DATA_LOAD_RESULT", function(spellID)
        spellID = ns.Plain(spellID)
        if spellID and ns.Sources.Loaded(spellID) then ns.QueueUpdate(false, 0.5) end
    end)
    -- The class trainer's window says which spellbook tab each spell belongs to.
    ns.On("TRAINER_SHOW", function() ns.Safe("trainer", ns.Sources.TrainerShown) end)
    ns.On("TRAINER_UPDATE", function() ns.Safe("trainer", ns.Sources.TrainerUpdated) end)
    ns.On("TRAINER_CLOSED", function() ns.Safe("trainer", ns.Sources.TrainerClosed) end)
end

-- The buttons' contents arrive with the login data. Nothing is placed before
-- they are certainly there, or a reservation could land on a button that is not really empty.
local entered = false
ns.On("PLAYER_ENTERING_WORLD", function()
    if entered then
        ns.QueueUpdate(false)
        return
    end
    entered = true
    C_Timer.After(2, function()
        ns.ready = true
        ns.QueueUpdate(true, 0)
    end)
end)

-------------------------------------------------------------------------------
--  /sane abilities
-------------------------------------------------------------------------------
local function Reservations()
    local slots = {}
    for slot in pairs(ns.char.reserved) do slots[#slots + 1] = slot end
    table.sort(slots)
    return slots
end

-- /sane ab debug: what the lists were built from. Also kept in the saved settings file.
local function Debug()
    ns.Sources.All() -- built first, if something changed since
    local stats = ns.Sources.stats
    ns.Print(("spells: %d learned, %d still to learn (trainer list %d, weapon skills %d, talents %d, read at the trainer %d, added by hand %d)."):format(
        stats.known or 0, stats.unlearned or 0, stats.data or 0, stats.skill or 0, stats.talent or 0, stats.trainer or 0, stats.extra or 0))
    ns.Print(("spellbook tab found for %d of them (%d by a rank you know, %d at the trainer, %d asked from the game, %d from the built-in list, %d by talent tree); %d without a tab."):format(
        (stats.unlearned or 0) - (stats.tabNone or 0), stats.tabKnown or 0, stats.tabTrainer or 0,
        stats.tabProbe or 0, stats.tabStatic or 0, stats.tabTalent or 0, stats.tabNone or 0))
    if ns.Book and ns.Book.Describe then ns.Print(ns.Book.Describe()) end
    ns.Print(("reservations: %d. Bar 1 shows slots %d-%d."):format(#Reservations(), ns.Bar1Offset() + 1, ns.Bar1Offset() + ns.NUM_BUTTONS))
end

local function List()
    local slots = Reservations()
    if #slots == 0 then
        ns.Print("no reservations. Drag a grey spell from the spellbook onto an action bar button to make one.")
        return
    end
    for _, slot in ipairs(slots) do
        ns.Print(("%s: %s"):format(ns.SlotLabel(slot), ns.Sources.Name(ns.char.reserved[slot])))
    end
end

local function ClearAll()
    local count = #Reservations()
    wipe(ns.char.reserved)
    ns.QueueUpdate(false, 0)
    ns.Print(count == 1 and "1 reservation removed." or count .. " reservations removed.")
end

-- "/sane ab item 6948 2 5": reserve an item you do not have yet on bar 2, button 5.
local function ReserveItem(text)
    local what, bar, button = text:match("^(.-)%s+(%d+)%s+(%d+)%s*$")
    local kind, id = ns.Sources.Parse(what, true)
    bar, button = tonumber(bar), tonumber(button)
    local info = bar and ns.BARS[bar]
    if kind ~= "item" or not info or not button or button < 1 or button > ns.NUM_BUTTONS then
        ns.Print("type: /sane ab item <item ID or link> <bar 1-" .. #ns.BARS .. "> <button 1-12>")
        return
    end
    if not C_Item.DoesItemExistByID(id) then
        ns.Print("there is no item with the ID " .. id .. ".")
        return
    end
    local slot = (info.paged and ns.Bar1Offset() or info.offset) + button
    local ok, why = ns.Engine.Reserve(slot, { kind = "item", id = id, name = C_Item.GetItemNameByID(id) })
    ns.Print(ok and ("item reserved on %s."):format(ns.SlotLabel(slot)) or ns.Engine.Reason(why))
end

local HELP = {
    "the spells you have not learned yet are in your spellbook, in grey. Drag one onto an action bar button to reserve that button. (/sane ab is short for /sane abilities.)",
    "/sane ab list - your reservations     /sane ab clear - remove them all",
    "/sane ab save <name>, /sane ab load <name>, /sane ab delete <name>, /sane ab layouts - saved bar layouts",
    "/sane ab add <spell ID or link> - list a spell the addon does not know about",
    "/sane ab item <item ID or link> <bar> <button> - reserve a button for an item",
    "/sane ab pages off - leave the spellbook's pages to the game (and /sane ab pages on)",
    "/sane ab window reset - the spellbook's own size and place again",
    "/sane ab debug - what the lists were built from",
}

local commands = {
    debug = Debug,
    list = List,
    clear = ClearAll,
    item = ReserveItem,
    layouts = function()
        local names = ns.Presets.List()
        ns.Print(#names == 0 and "no saved layouts yet. Save one with /sane ab save <name>."
            or "saved layouts: " .. table.concat(names, ", "))
    end,
    save = function(rest) ns.Print((select(2, ns.Presets.Save(rest)))) end,
    load = function(rest) ns.Print((select(2, ns.Presets.Load(rest)))) end,
    delete = function(rest)
        if ns.DB.presets[ns.class][rest] then
            ns.Presets.Delete(rest)
            ns.Print(("layout \"%s\" deleted."):format(rest))
        else
            ns.Print("there is no saved layout with that name.")
        end
    end,
    add = function(rest)
        local kind, id = ns.Sources.Parse(rest)
        if kind ~= "spell" then
            ns.Print("type: /sane ab add <spell ID or link>")
        else
            ns.Print((select(2, ns.Sources.AddExtra(id))))
        end
    end,
    window = function(rest)
        if rest == "reset" then
            ns.Window.Reset()
        else
            ns.Print("type: /sane ab window reset")
        end
    end,
    pages = function(rest)
        if rest == "on" or rest == "off" then
            -- Core.Set tells the module (PagesChanged) and the options page; the same choice again is told here.
            local on = rest == "on"
            if ns.options.book == on then PagesChanged(on) else Core.Set(ns.name, "book", on) end
        else
            ns.Print("type: /sane ab pages on  or  /sane ab pages off")
        end
    end,
}

Core.Command("abilities", "unlearned spells in the spellbook, reserved buttons, saved bar layouts", function(text)
    local word, rest = text:match("^(%S+)%s*(.-)$")
    local command = word and commands[word:lower()]
    if not ns.char then return end
    if command then
        command(rest)
    else
        for _, line in ipairs(HELP) do ns.Print(line) end
    end
end, "ab", "spellbook", "sb") -- its old name, and the old short word, still work
