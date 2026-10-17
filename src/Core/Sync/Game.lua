-------------------------------------------------------------------------------
--  Sane UI - Core - Sync - Game: the game's options pages, its graphics and
--  sound, and what else it keeps for each character
--      a page part     one per options page of the game's groups Gameplay and
--                      Accessibility, holding what that page sets (Data/Pages.lua:
--                      its CVars, pairs of game functions, modifier keys of clicks,
--                      the extra action bars)
--      Graphics, Audio the game's own kinds of CVar Graphics and Sound
--                      (Enum.ConsoleCategory), as its pages under System show them
--      per character   every other CVar the game stores for each character on its
--                      servers (C_CVar.GetCVarInfo): map filters, the minimap,
--                      tutorials seen, ...
--  The last two the game lists (ConsoleGetAllCommands): once a session, when
--  first wanted, in one pass, of which only the names stay. A part reads only
--  what this client has, and writes only what differs.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sync = Core.Sync -- Sync.lua
local Plain = Core.Plain

local TEXT = {
    page = "What you set on the game's options page %s (Esc > Options).",
    tips = {
        CONTROLS_LABEL = "The game's page Controls: the mouse, the camera, looting, clicking to move and to interact.",
        INTERFACE_LABEL = "The game's page Interface: status text, portraits, raid frames, chat bubbles, toasts, tutorials, coordinates on the maps.",
        ACTIONBARS_LABEL = "The game's page Action Bars: which extra bars are shown (in place after a /reload), whether they are locked, numbers on cooldowns.",
        COMBAT_LABEL = "The game's page Combat: self and mouseover cast, spell alerts, loss of control, floating combat text, the target of your target.",
        SOCIAL_LABEL = "The game's page Social: chat style, new whispers, time stamps, the language filter, what is blocked or declined, friends coming online.",
        SETTINGS_KEYBINDINGS_LABEL = "The modifier keys of clicks (to link in chat, to self cast, to split a stack, to compare items), not the key bindings, which the game keeps itself.",
        NAMEPLATE_OPTIONS_LABEL = "The game's page Nameplates: which nameplates and names over heads show, their size and style.",
        GRAPHICS_LABEL = "The game's graphics settings (System > Graphics), not the screen and its hardware.",
        AUDIO_LABEL = "The volumes and sound settings (System > Audio), not the sound devices.",
    },
    perCharacter = "Other per-character settings",
    perCharacterTip = "Everything else the game keeps for each character on its own: filters of the world map and the minimap, the quest log, the calendar, the tutorials you have seen, and more. Not what a character tracks or last chose.",
    bars = "the action bars",
}

-- Never kept by the parts that find their CVars in the game: a character's state rather than a setting
-- (what it tracks, collapsed, last chose or saw), and what belongs to one computer (the screen, drivers
-- and devices, speech voices). Patterns, in lower case.
local STATE = { "^tracked", "^hardtracked", "collapsed", "^last", "^seen", "pending", "^ej" }
local MACHINE = { "^gx", "hwdetect", "driver", "device", "monitor", "adapter", "windowed", "maximize", "^videooptions", "voice" }

local CVAR = Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar or 0
local KIND = Enum and Enum.ConsoleCategory or {}
local NONE = {}

-- A page's name where this client lacks the game's string: CONTROLS_LABEL is "Controls".
local function Named(page)
    local words = page:gsub("^SETTINGS_", ""):gsub("_LABEL$", ""):gsub("_", " "):lower()
    return words:sub(1, 1):upper() .. words:sub(2)
end

local function Game(name)
    local fn = rawget(_G, name)
    return type(fn) == "function" and fn or nil
end

-------------------------------------------------------------------------------
--  CVars by name
-------------------------------------------------------------------------------
-- [name] = value of those of the list this client has.
local function ReadCVars(list)
    local values = {}
    for _, name in ipairs(list) do values[name] = Plain(C_CVar.GetCVar(name)) end
    return values
end

-- Sets those that differ; only names of the list (allowed: [lower-case name] = true) this client has.
local function WriteCVars(values, allowed)
    for name, value in pairs(values) do
        local now = type(name) == "string" and allowed[name:lower()] and Plain(C_CVar.GetCVar(name))
        if now and type(value) == "string" and now ~= value then C_CVar.SetCVar(name, value) end
    end
end

local function Lower(list)
    local set = {}
    for _, name in ipairs(list) do set[name:lower()] = true end
    return set
end

-------------------------------------------------------------------------------
--  A page's other settings
-------------------------------------------------------------------------------
-- flags: { getter, setter } pairs; read as [getter] = on. One the game does not answer (it failed, or
-- hides it) stays as it was kept (before: what was read last).
local function ReadFlags(list, before)
    local values, kept = {}, type(before) == "table" and before or NONE
    for _, pair in ipairs(list) do
        local on = Core.Ask(Game(pair[1]))
        if on == nil then
            values[pair[1]] = kept[pair[1]]
        else
            values[pair[1]] = on and true or false
        end
    end
    return values
end

local function WriteFlags(list, values)
    for _, pair in ipairs(list) do
        local want, put = values[pair[1]], Game(pair[2])
        local now = Core.Ask(Game(pair[1]))
        if type(want) == "boolean" and put and now ~= nil and (now and true or false) ~= want then put(want) end
    end
end

-- clicks: [action] = its modifier key ("SHIFT"). Kept with the key bindings in use, which the game
-- saves when one changed.
local function ReadClicks(actions, before)
    local keys, kept = {}, type(before) == "table" and before or NONE
    for _, action in ipairs(actions) do
        keys[action] = Core.Ask(Game("GetModifiedClick"), action) or kept[action]
    end
    return keys
end

local function WriteClicks(actions, keys)
    local changed = false
    for _, action in ipairs(actions) do
        local want, now = keys[action], Core.Ask(Game("GetModifiedClick"), action)
        if type(want) == "string" and now ~= nil and now ~= want then
            SetModifiedClick(action, want)
            changed = true
        end
    end
    local save, set = Game("SaveBindings"), Game("GetCurrentBindingSet")
    if changed and save and set then save(set()) end
end

-- Which extra action bars are shown: the character's switches, read by the bars when the interface
-- loads. True if they differed.
local function ReadBars()
    local shown = { GetActionBarToggles() }
    for index, on in ipairs(shown) do shown[index] = on and true or false end
    return shown
end

local function WriteBars(shown)
    local rules = rawget(_G, "C_GameRules")
    if rules and rules.IsMultiActionBarVisibilityForced and rules.IsMultiActionBarVisibilityForced() then return false end
    local now = { GetActionBarToggles() }
    for index = 1, #now do
        if (now[index] and true or false) ~= (shown[index] and true or false) then
            SetActionBarToggles(unpack(shown, 1, #now))
            return true
        end
    end
    return false
end

-------------------------------------------------------------------------------
--  The page parts
-------------------------------------------------------------------------------
local onPages = {} -- [lower-case name] = true: a CVar some page holds; no other part takes it

for _, page in ipairs(Sync.PAGES or NONE) do
    local cvars, flags, clicks = page.cvars or NONE, page.flags or NONE, page.clicks or NONE
    local allowed = Lower(cvars)
    for name in pairs(allowed) do onPages[name] = true end
    local text = Sync.Word(page.page, Named(page.page))
    local hasClicks = #clicks > 0 and Game("GetModifiedClick") and Game("SetModifiedClick")
    local hasBars = page.bars and Game("GetActionBarToggles") and Game("SetActionBarToggles")
    Sync.Part(page.page, page.group, {
        text = text,
        tip = TEXT.tips[page.page] or TEXT.page:format(text),
        reload = hasBars and TEXT.bars or nil,
        Read = function()
            local before = Sync.Taken(page.page)
            if type(before) ~= "table" then before = NONE end
            return { cvars = ReadCVars(cvars), flags = ReadFlags(flags, before.flags),
                clicks = hasClicks and ReadClicks(clicks, before.clicks) or nil, bars = hasBars and ReadBars() or nil }
        end,
        Write = function(data)
            if type(data.cvars) == "table" then WriteCVars(data.cvars, allowed) end
            if type(data.flags) == "table" then WriteFlags(flags, data.flags) end
            if hasClicks and type(data.clicks) == "table" then WriteClicks(clicks, data.clicks) end
            return hasBars and type(data.bars) == "table" and WriteBars(data.bars) or false
        end,
    })
end

-------------------------------------------------------------------------------
--  The parts that find their CVars in the game
-------------------------------------------------------------------------------
local found = {} -- the parts below, each with names = { CVar, ... } and has = [name] = true once resolved

local function Matches(lower, patterns)
    for _, pattern in ipairs(patterns) do
        if lower:find(pattern) then return true end
    end
    return false
end

-- Whether the game stores a CVar for each character, and lets it be changed.
local function PerCharacter(name)
    local ok, _, _, _, character, locked, _, readOnly = pcall(C_CVar.GetCVarInfo, name)
    return ok and character == true and not locked and not readOnly
end

-- One pass over the game's list, for every such part at once; nothing is set when the game cannot
-- say (a client update renamed its function): it is asked again next time. A name listed twice
-- counts once.
local function Resolve()
    local ok, commands = pcall(ConsoleGetAllCommands)
    if not ok or type(commands) ~= "table" then return end
    local byKind, rest = {}, nil
    for _, part in ipairs(found) do
        part.names, part.has = {}, {}
        if part.kind then byKind[part.kind] = part else rest = part end
    end
    local seen = {}
    for _, command in ipairs(commands) do
        local name = type(command) == "table" and command.commandType == CVAR and command.command
        local lower = type(name) == "string" and name:lower()
        if lower and not seen[lower] and not onPages[lower] then
            seen[lower] = true
            local part = byKind[command.category]
            if not part and rest and PerCharacter(name) then part = rest end
            if part and not Matches(lower, MACHINE) and not Matches(lower, STATE) then
                part.names[#part.names + 1] = name
                part.has[lower] = true
            end
        end
    end
end

-- The names of such a part's CVars on this client; empty when the game cannot say.
local function Names(part)
    if not part.names then Resolve() end
    return part.names or NONE
end
Sync.CVarsOf = function(id) return Names(Sync.part[id] or NONE) end

-- A part of CVars the game names; kind: its Enum.ConsoleCategory, none for the per-character one.
local function Found(id, group, kind, part)
    part.kind = kind
    found[#found + 1] = part
    -- The game cannot say which CVars it has: what was kept stays.
    part.Read = function()
        local names = Names(part)
        if #names == 0 then return Sync.Taken(id) end
        return { cvars = ReadCVars(names) }
    end
    part.Write = function(data)
        Names(part)
        if type(data.cvars) == "table" then WriteCVars(data.cvars, part.has or NONE) end
    end
    Sync.Part(id, group, part)
end

local SYSTEM = "SETTING_GROUP_SYSTEM"
for _, def in ipairs({ { "GRAPHICS_LABEL", KIND.Graphics or 1 }, { "AUDIO_LABEL", KIND.Sound or 7 } }) do
    local id = def[1]
    local text = Sync.Word(id, Named(id))
    Found(id, SYSTEM, def[2], { text = text, tip = TEXT.tips[id] or TEXT.page:format(text) })
end

Found("perCharacter", "elsewhere", nil, { text = TEXT.perCharacter, tip = TEXT.perCharacterTip })
