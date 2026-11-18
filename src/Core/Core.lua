local ADDON = ...

-------------------------------------------------------------------------------
--  SaneUI - Core
--  What every module needs and none should build twice: a line in chat, the
--  game's events, a way to run a step so that an error in it stops nothing
--  else, the list of modules, the /sane command and the saved settings (Saved.lua).
--  Core also holds the options (Settings/) and keeps the game's own settings with
--  SaneUI's (Sync/).
--
--  SaneUI is several addons: this one (the addon "SaneUI"), and one per module
--  (SaneUI_Abilities, SaneUI_Social, ...), each in a folder of its own. A module
--  depends on this addon and on no other module, so every one of them can be
--  switched on and off by itself in the game's addon list.
--
--  The game gives every addon a table only its own files see. What the addons
--  share is therefore one global table, SaneUI: Core is SaneUI.Core, a module
--  SaneUI.<Name>.
--
--  A module starts like this, in the first file of its TOC:
--      local ADDON, ns = ...                           -- ns: the module's own table
--      SaneUI.Core.NewModule(ADDON, "Abilities", ns)
--      function ns.OnLoad() end     -- its addon is loaded, saved settings are there
--      function ns.OnLogin() end    -- the character is there
--      function ns.OnLogout() end   -- the game is about to write the saved settings
--
--  A file should only define things when it is read and start its work in
--  OnLoad or OnLogin, or later still, when what it serves is first used.
-------------------------------------------------------------------------------
local Core = { name = "Core" }
SaneUI = { Core = Core }

Core.TITLE = "SaneUI"
Core.VERSION = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "?"
Core.GOLD = { 0.525, 0.439, 0.282 }
-- SaneUI's Discord, by the server's own address (it never expires): on the page SaneUI (About.lua) and in the
-- line told for a problem.
Core.DISCORD = "https://discord.gg/saneui"
local PREFIX = "|cff867048" .. Core.TITLE .. ":|r "

function Core.Print(text)
    print(PREFIX .. text)
end

-- The game this client is: SaneUI is one code for WoW: Forever and Retail (Doc/guides/addon-standards.md,
-- *Forever and Retail*). Core.GAME is "forever" or "retail", nil on any other client; Core.FOREVER and
-- Core.RETAIL say the same for code that differs. Forever's client is Retail's with a layer of its own, so
-- WOW_PROJECT_ID tells them apart (18 and 1, should the game's names for them be missing). Told as Core is
-- read; again only by the tests.
function Core.TellGame()
    local project, game = rawget(_G, "WOW_PROJECT_ID"), nil
    if project ~= nil and project == (rawget(_G, "WOW_PROJECT_CAMELOT") or 18) then
        game = "forever"
    elseif project ~= nil and project == (rawget(_G, "WOW_PROJECT_MAINLINE") or 1) then
        game = "retail"
    end
    Core.GAME, Core.FOREVER, Core.RETAIL = game, game == "forever", game == "retail"
    return game
end
Core.TellGame()

-- This game's one of a choice made per game: Core.ForGame({ forever = 6, retail = 8 }) is 6 in Forever; nil
-- where the game is not named (what that game lacks).
function Core.ForGame(choices)
    return choices[Core.GAME]
end

-- Whether an addon of SaneUI serves this game: "## X-SaneUI-Games: forever" in its TOC names the games it
-- is made for (a module that needs the one game's art or systems); without it, both.
function Core.ServesGame(addon)
    local ok, games = pcall(C_AddOns.GetAddOnMetadata, addon, "X-SaneUI-Games")
    if not ok or type(games) ~= "string" or games == "" then return true end
    for game in games:lower():gmatch("[%a%-]+") do
        if game == Core.GAME then return true end
    end
    return false
end

-- The SaneUI an addon of ours was published with, when this Core is older: each module is a download of its
-- own and Core one beside them (dev/tools/release), so a player may update a module and not Core. A packaged
-- module's TOC names its Core ("## X-SaneUI-Core: 0.3.2"); a copy built here names none. nil: Core is new enough.
local function Numbers(version)
    local major, minor, patch = tostring(version or ""):match("^(%d+)%.(%d+)%.(%d+)")
    if major then return tonumber(major), tonumber(minor), tonumber(patch) end
end
function Core.NewerCoreWanted(addon)
    local ok, wanted = pcall(C_AddOns.GetAddOnMetadata, addon, "X-SaneUI-Core")
    if not ok then return nil end
    local a1, b1, c1 = Numbers(wanted)
    local a2, b2, c2 = Numbers(Core.VERSION)
    if not (a1 and a2) then return nil end
    if a1 ~= a2 then return a1 > a2 and wanted or nil end
    if b1 ~= b2 then return b1 > b2 and wanted or nil end
    return c1 > c2 and wanted or nil
end

-- Told once per addon, in a line: the module runs on, though it may miss a part of Core it was made with.
local toldOld = {}
local function TellOldCore(addon)
    local wanted = not toldOld[addon] and Core.NewerCoreWanted(addon)
    if not wanted then return end
    toldOld[addon] = true
    local ok, title = pcall(C_AddOns.GetAddOnMetadata, addon, "Title")
    Core.Print(("%s was made with SaneUI %s, and this is %s: update SaneUI too."):format(
        ok and type(title) == "string" and title or addon, wanted, Core.VERSION))
end

-- The 12.x client hides some values from addons during combat ("secret values").
-- Using one in a comparison is an error, so everything read from the game goes through here.
function Core.Secret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

-- Every answer of the game passes here, so the check is written out rather than asked of Core.Secret (half the time);
-- the game's issecretvalue is read at each call, never kept: nil is plain, and needs no asking.
function Core.Plain(value)
    local secret = issecretvalue
    if value ~= nil and secret ~= nil and secret(value) then return nil end
    return value
end

local Plain = Core.Plain

local function Answer(ok, a, b, c)
    if not ok then return nil end
    local secret = issecretvalue
    if secret == nil then return a, b, c end
    if a ~= nil and secret(a) then a = nil end
    if b ~= nil and secret(b) then b = nil end
    if c ~= nil and secret(c) then c = nil end
    return a, b, c
end

-- Asks the game: fn(...)'s first three answers, each nil when hidden. All nil when fn is not
-- there (a client update renamed it) or failed. For a game function that may be missing or
-- may fail, as many do for a unit that is gone. Makes no table and no closure.
function Core.Ask(fn, ...)
    if type(fn) ~= "function" then return nil end
    return Answer(pcall(fn, ...))
end

-- Whether a menu is open: the game's own kind, or the older dropdown list addons still open. For a view that goes
-- when the mouse leaves it and stays for a menu it opened, which lies outside it.
function Core.MenuOpen()
    local menus = rawget(_G, "Menu")
    local manager = menus and menus.GetManager and Core.Ask(menus.GetManager)
    if manager ~= nil and Core.Ask(manager.IsAnyMenuOpen, manager) == true then return true end
    local list = rawget(_G, "DropDownList1")
    return list ~= nil and Plain(list:IsShown()) == true
end

-- Whether this client names a player by a first name and a surname, the two together unique across the
-- region (WoW: Forever, "Droopy Fairwind": two players can share the first name, or the surname), rather
-- than by one name unique on its realm (Retail, "Thrall-Draenor").
function Core.Surnames()
    if Core.FOREVER then return true end
    return Core.Ask(rawget(_G, "RegionalUniqueNamesEnabled")) == true
end

local function Separator()
    local names = Constants and Constants.CharacterNameSeparatorConsts
    return names and names.CHARACTERNAME_SURNAME_SEPARATOR or " "
end

-- A unit's whole name, as the game shows it: a Forever character has a first name and a surname
-- (UnitName gives both), joined by the game's separator ("Droopy Fairwind"); a unit without a
-- surname only its name. nil when it has none or the game hides it. As the game's NameUtil. On a client
-- without surnames UnitName's second answer is a realm, which is not shown here.
function Core.FullName(unit)
    local name, surname = Core.Ask(UnitName, unit)
    if type(name) ~= "string" or name == "" then return nil end
    if not Core.Surnames() or type(surname) ~= "string" or surname == "" then return name end
    return name .. Separator() .. surname
end

local function OwnRealm()
    local realm = Core.Ask(rawget(_G, "GetNormalizedRealmName"))
    return type(realm) == "string" and realm ~= "" and realm or nil
end

-- A player's key: the one name that tells players apart, for whatever is kept, compared or shared about
-- a player. On Forever the first name and the surname as one ("Droopy Fairwind"), never one of them alone,
-- and no realm (the whole name is unique across the region); elsewhere "Name-Realm". nil for a name that is
-- not a whole one: a Forever name without its surname is dropped, never guessed.
local function Key(name, second)
    if type(name) ~= "string" then return nil end
    name = name:match("^%s*(.-)%s*$")
    if name == "" or name:find("-", 1, true) then return nil end
    second = type(second) == "string" and second:match("^%s*(.-)%s*$") or ""
    if Core.Surnames() then
        local separator = Separator()
        if second == "" then
            -- the name may hold both already, as names in events and lists do
            local at = name:find(separator, 1, true)
            if not at then return nil end
            name, second = name:sub(1, at - 1), name:sub(at + #separator):match("^%s*(.-)$")
        end
        if name == "" or second == "" then return nil end
        return name .. separator .. second
    end
    if name:find("%s") then return nil end
    local realm = second ~= "" and second:gsub("%s", "") or OwnRealm()
    return realm and name .. "-" .. realm or nil
end

-- The key of a player unit (Core.PlayerKey("target")); nil for a unit that is no player, or hidden.
function Core.PlayerKey(unit)
    if Core.Ask(UnitIsPlayer, unit) ~= true then return nil end
    return Key(Core.Ask(rawget(_G, "UnitNameUnmodified") or UnitName, unit))
end

-- The key of a player named by text, as an event, a list or a message gives it: "Droopy Fairwind",
-- "Droopy Fairwind-Realm" (the realm dropped on Forever), "Thrall-Draenor" or "Thrall" (the own realm added
-- elsewhere).
function Core.PlayerKeyOf(text)
    text = Core.Plain(text)
    if type(text) ~= "string" then return nil end
    local name, realm = text:match("^([^%-]+)%-(.+)$")
    if not name then return Key(text) end
    if Core.Surnames() then return Key(name) end
    return Key(name, realm)
end

-- An amount of money, the one way SaneUI writes it: 1g1s1c, the letters being the game's coin icons, at the size of the words
-- around them, with no spaces (Saneroki, 2026-10-30). A coin there is none of is left out. Where the game has not its coins' words,
-- what it writes itself; nil if it cannot.
function Core.Coins(copper)
    if type(copper) ~= "number" then return nil end
    local gold, silver, bronze = rawget(_G, "GOLD_AMOUNT_TEXTURE"), rawget(_G, "SILVER_AMOUNT_TEXTURE"), rawget(_G, "COPPER_AMOUNT_TEXTURE")
    if not (gold and silver and bronze) then
        local currency = C_CurrencyInfo
        return currency and currency.GetCoinTextureString and (Core.Ask(currency.GetCoinTextureString, copper)) or nil
    end
    copper = math.max(0, math.floor(copper))
    local golds, silvers, coppers = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    return (golds > 0 and gold:format(golds, 0, 0) or "") .. (silvers > 0 and silver:format(silvers, 0, 0) or "")
        .. ((coppers > 0 or copper == 0) and bronze:format(coppers, 0, 0) or "")
end

-- A region's anchors, to put back later with Core.Repoint (a frame of the game's that we move
-- for a while). Each is { point, relativeTo, relativePoint, x, y }.
function Core.Points(region)
    local points = {}
    for index = 1, region:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = region:GetPoint(index)
        points[index] = { point, relativeTo, relativePoint, x, y }
    end
    return points
end

function Core.Repoint(region, points)
    region:ClearAllPoints()
    for _, p in ipairs(points) do region:SetPoint(p[1], p[2], p[3], p[4], p[5]) end
end

-------------------------------------------------------------------------------
--  Errors: caught, told once, kept, and the part that failed steps aside
--  Every piece of SaneUI's code the game calls runs behind a guard: a step (Safe, a module's
--  Guarded) or the door it came in by (an event, Later, a module's start, module.Guard). What
--  slips past all of them reaches the game's error window, and is caught there too. A module's
--  error stands that module down: it gives the game's own back and stops (module.StandDown).
-------------------------------------------------------------------------------
-- [label] = { text, count, when }: text is the problem's first line, what went wrong; the log below
-- has the whole of it, with the place. Saved.lua keeps this table in the saved settings file, so it
-- can still be read after a /reload: /sane errors.
Core.errors = {}
-- The log: every problem in the order it happened, the newest last, each with its time, what
-- went wrong and where (the text), the addon's version and the game's build. Saved.lua keeps
-- it in the saved settings file too. That file is the only one an addon can write, and the
-- game writes it at a /reload or when you log out: dev/tools/errors reads the log from it.
Core.log = {}
local LOG_MAX = 100 -- the oldest entries go
local ERRORS_MAX = 100 -- kinds of problem kept by label; the one seen longest ago goes
local BUILD = GetBuildInfo and select(2, GetBuildInfo()) or "?"
-- The general switches, those of no module. Saved.lua describes them and puts the saved ones here.
Core.general = {}
local told = {}

-- It runs while an error is handled, so it must not fail itself on a hand-edited saved file.
function Core.NoteError(label, text)
    -- An error about a value the game hides is hidden too: it can be neither compared nor saved.
    if Core.Secret(text) then text = "(a value the game hides)" end
    local now = date("%Y-%m-%d %H:%M:%S")
    -- Only the first line here: the place it happened (the trace) is in the log entry, and both are
    -- saved, so it is written once.
    local line = type(text) == "string" and text:match("^[^\n]*") or text
    local seen = Core.errors[label]
    if type(seen) == "table" then
        seen.text, seen.count, seen.when = line, (tonumber(seen.count) or 0) + 1, now:sub(1, 16)
    else
        -- A new kind: the list stays short however many there were (a label with a number in it).
        local count, oldest, oldestWhen = 0, nil, nil
        for known, problem in pairs(Core.errors) do
            count = count + 1
            local when = type(problem) == "table" and tostring(problem.when) or ""
            if not oldestWhen or when < oldestWhen then oldest, oldestWhen = known, when end
        end
        if count >= ERRORS_MAX and oldest ~= nil then Core.errors[oldest] = nil end
        Core.errors[label] = { text = line, count = 1, when = now:sub(1, 16) }
    end
    -- The same problem again and again (in every frame, say) is one entry that counts.
    local log = Core.log
    local last = log[#log]
    if type(last) == "table" and last.label == label and last.text == text and tonumber(last.count) then
        last.count, last.when = last.count + 1, now
        return
    end
    log[#log + 1] = { when = now, label = label, text = text, count = 1, version = Core.VERSION, build = BUILD }
    while #log > LOG_MAX do table.remove(log, 1) end
end

-- The line in chat for a problem: where it happened, and how the player reports it: /sane bug makes the report
-- (with the latest errors, About.lua) to paste on SaneUI's Discord. Chat cannot be copied, so the invite is
-- written short, to type (the page SaneUI copies it whole).
local TOLD = "problem in %s. Type /sane bug to make a bug report, then copy and paste it into #bug-reports on SaneUI's Discord: "
    .. (Core.DISCORD:gsub("^https?://", ""))

-- Keeps a problem and says so in chat, once per label (unless the player switched that off).
-- For a problem a module found itself, without an error being raised.
function Core.Report(label, text)
    Core.NoteError(label, text)
    if not told[label] and Core.general.errors ~= false then
        told[label] = true
        Core.Print(TOLD:format(label))
    end
end

-- The error handler for xpcall: the error with the place it happened.
local function Trace(message)
    return tostring(message) .. "\n" .. (debugstack and debugstack(2) or "")
end
Core.Trace = Trace

-- Run one step so that an error in it cannot stop the others. Returns the step's first result.
-- The game's xpcall hands the arguments on, so a step costs no table and no closure.
function Core.Safe(label, fn, ...)
    local ok, result = xpcall(fn, Trace, ...)
    if ok then return result end
    Core.Report(label, result)
    return nil
end

-- [addon folder] = its module (NewModule). The game names an error's place by its file, and the
-- file by its addon's folder: Interface/AddOns/SaneUI_Social/Board.lua.
local byAddon = {}

-- The module an error came from: the first module's folder named in its text (its place, then the
-- trace under it), so a step of Core that a module called is that module's. nil: Core's own.
local function Owner(text)
    if Core.Secret(text) or type(text) ~= "string" then return nil end
    for folder in text:gmatch("AddOns[/\\]([%w_]+)[/\\]") do
        if byAddon[folder] then return byAddon[folder] end
    end
    return nil
end

-- True while one of our errors is handed to the game's error window (Show): GameError, which
-- listens there, leaves it alone. It is noted already.
local showing = false

-- The game shows Lua errors in its error window only if it was asked to (/console scriptErrors 1).
-- Then ours are shown there too, as every addon's are. Without it nothing pops up: the line in chat
-- and the log say what happened.
local function Show(problem)
    local handler = rawget(_G, "CallErrorHandler")
    if not handler or Core.Ask(rawget(_G, "GetCVarBool"), "scriptErrors") ~= true then return end
    showing = true
    pcall(handler, problem)
    showing = false
end

-- Where an error goes that no step caught, but the door it came in by: an event, Later, a module's
-- start, module.Guard, or the game's error window (seen: it was shown there already). The module it
-- came from stands down: it gives the game's own back and stops. owner: that module when the door
-- knows it, otherwise it is found in the error's text. Core's own is told once under the label (the
-- event, say), and Core goes on.
local function Failed(owner, label, problem, seen)
    owner = owner or Owner(problem)
    if not owner then
        Core.Report(label, problem)
    elseif owner.off then
        -- Stopped already, by an earlier error (a script without a guard runs on): kept, not told again.
        Core.NoteError(owner.name .. ": after it stopped", problem)
    else
        owner.StandDown(problem)
    end
    if not seen then Show(problem) end
end

-- An error that slipped past every guard (a frame's script or a hook that has none) goes to the
-- game's own error handler, which hands it to its error window: those of SaneUI are caught there,
-- and fail as at any door. The game's handling is left as it is: this only listens. A Lua warning
-- (messageType 1, no error) is only noted.
local function GameError(_, message, messageType, stack)
    if showing then return end
    message, stack = Core.Plain(message), Core.Plain(stack)
    if type(message) ~= "string" then return end
    local text = type(stack) == "string" and message .. "\n" .. stack or message
    if not text:find(ADDON, 1, true) then return end
    if messageType == 1 then
        Core.NoteError("Lua warning", text)
    else
        Failed(nil, "Core", text, true)
    end
end

local function ListenForGameErrors()
    local window = rawget(_G, "ScriptErrorsFrame")
    if not (window and window.DisplayMessageInternal) then return end
    hooksecurefunc(window, "DisplayMessageInternal", function(...) pcall(GameError, ...) end) -- unguarded: the guard's own ear, behind pcall
end

-- Through(label, xpcall(fn, ...)): all of fn's results when it worked. Its error came in by a door of Core's.
local function Through(label, ok, ...)
    if ok then return ... end
    Failed(nil, label, (...))
    return nil
end

-- fn guarded, for the game to call later: a door of Core's own (a frame's script, a hook, a timer, a
-- menu's function), as module.Guard is a module's. Core stands down for nobody: an error that ran into a
-- module's code stands that module down, Core's own is told once under the label (the window, the
-- options), and the next call tries again. It hands on all of fn's results and makes no table and no
-- closure when called; made once, where the script is set, not where it runs.
--     close:SetScript("OnClick", Core.Guard("window", Close))
function Core.Guard(label, fn)
    return function(...)
        return Through(label, xpcall(fn, Trace, ...))
    end
end

-- Softly(label, xpcall(fn, ...)): all of fn's results when it worked; its error only noted and told once.
local function Softly(label, ok, ...)
    if ok then return ... end
    Core.Report(label, (...))
    return nil
end

-- fn guarded gently, for the game to call later where what the player does may run into an error that must stop
-- nothing: a search field's keys, its list and its answers (Saneroki, 2026-11-15: "The search fields everywhere in
-- our addon needs to have a very greacefull error handeling"). Its error stands no module down, Core's or any other
-- named in its trace: it is kept in the error log and told once in chat under the label, fn answers nil, and the
-- next key tries again. A search that lists its answers says so in its list (Core.SEARCH_FAILED). As Core.Guard: it
-- hands on all of fn's results and makes no table and no closure when called.
--     box:HookScript("OnTextChanged", Core.Gently("icons", Typed))
function Core.Gently(label, fn)
    return function(...)
        return Softly(label, xpcall(fn, Trace, ...))
    end
end

-- What a search's list says where its search ran into an error (Core.Gently): the field goes on working.
Core.SEARCH_FAILED = "This search ran into a problem (noted in /sane errors). Try other words."

-- Core.Later(fn, delay, label) returns a function that asks for fn to run once, delay seconds later
-- (0 or none: the next frame). Asking again before then changes nothing. For events that come in
-- bursts, and for work that must wait until the game has finished its own. An error in fn comes in by
-- the door "later", or by label where one is given (as Core.Guard's): Core's own told once under it.
function Core.Later(fn, delay, label)
    local asked = false
    label = label or "later"
    local function Run()
        asked = false
        local ok, problem = xpcall(fn, Trace)
        if not ok then Failed(nil, label, problem) end
    end
    return function()
        if asked then return end
        asked = true
        C_Timer.After(delay or 0, Run) -- unguarded: Run is the guard (xpcall, Failed)
    end
end

-------------------------------------------------------------------------------
--  A /reload offered
-------------------------------------------------------------------------------
local RELOAD = {
    text = "SaneUI changed %s. The game shows the change after the interface is reloaded.",
    reload = "Reload",
    later = "Later",
    both = "%s and %s",
}

-- "a", "a and b", "a, b and c"
local function Named(names)
    local count = #names
    if count <= 1 then return tostring(names[1] or "") end
    return RELOAD.both:format(table.concat(names, ", ", 1, count - 1), names[count])
end

-- The dialog's Reload: the game's own /reload (made once). Changes in the options not answered yet are saved by it
-- as the save window's Yes saves them (Unsaved.lua, at the logout), so it waits for nothing.
local Reload = Core.Guard("reload", function()
    local ui = rawget(_G, "C_UI")
    local reload = ui and ui.Reload or ReloadUI
    if reload then reload() end
end)

-- Offers a /reload in the game's own dialog (Reload / Later), for a change the game shows only after
-- one; names: what changed, a few words each. Nothing happens if the game's dialog is gone (noted
-- once). Whoever asks says it only once per change: nothing is throttled here.
function Core.AskReload(names)
    local dialogs = rawget(_G, "StaticPopupDialogs")
    if not (type(dialogs) == "table" and dialogs.GENERIC_CONFIRMATION and StaticPopup_Show) then
        Core.Report("reload", "the game's dialog for it is missing (GENERIC_CONFIRMATION)")
        return
    end
    StaticPopup_Show("GENERIC_CONFIRMATION", nil, nil, { text = RELOAD.text, text_arg1 = Named(names),
        acceptText = RELOAD.reload, cancelText = RELOAD.later, callback = Reload })
end

-------------------------------------------------------------------------------
--  Game events
-------------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}

-- A list of listeners is never changed while it is walked: a listener added or taken away during an
-- event makes a new list (that happens seldom), so the event in hand reaches exactly those it had.
local function Without(list, fn)
    local rest = {}
    for _, known in ipairs(list) do
        if known ~= fn then rest[#rest + 1] = known end
    end
    return rest
end

local function With(list, fn)
    local more = {}
    for index, known in ipairs(list) do more[index] = known end
    more[#more + 1] = fn
    return more
end

-- Registers an event on a frame; an event name this client does not know is an error: skipped instead
-- of breaking the addon, and noted (not told: it is nothing the player can mend), so /sane errors and
-- the log say why a feature is quiet.
local function Register(target, event, ...)
    local method = select("#", ...) > 0 and target.RegisterUnitEvent or target.RegisterEvent
    if pcall(method, target, event, ...) then return true end
    Core.NoteError("event " .. tostring(event), "this client has no such event; whatever listens to it is off")
    return false
end

-- An event is only asked of the game once somebody listens to it.
function Core.On(event, fn)
    if not handlers[event] then
        if not Register(frame, event) then return end
        handlers[event] = {}
    end
    handlers[event] = With(handlers[event], fn)
end

-- Stops listening; the last listener gone, the game no longer sends the event.
function Core.Off(event, fn)
    local list = handlers[event]
    if not list then return end
    list = Without(list, fn)
    if #list > 0 then
        handlers[event] = list
    else
        handlers[event] = nil
        frame:UnregisterEvent(event)
    end
end

-- Hands an event to its listeners, each behind a guard of its own: one listener's error keeps no
-- other (another module's, mostly) from hearing the event, and stands its own module down.
local function Deliver(list, event, ...)
    for _, fn in ipairs(list) do
        local ok, problem = xpcall(fn, Trace, ...)
        if not ok then Failed(nil, event, problem) end
    end
end

frame:SetScript("OnEvent", function(_, event, ...) -- unguarded: the events' guard itself (Deliver)
    local list = handlers[event]
    if list then Deliver(list, event, ...) end
end)

-- An event of one unit only (UNIT_AURA of "player"): the game sends it for that unit alone, not for
-- every unit about, which matters for the UNIT_ events that come many times a second in a group.
-- One frame per unit; fn gets the event's arguments as Core.On's listeners do (the unit first).
local units = {} -- [unit] = { frame, handlers = { [event] = list } }

function Core.OnUnit(event, unit, fn)
    local entry = units[unit]
    if not entry then
        entry = { frame = CreateFrame("Frame"), handlers = {} }
        entry.frame:SetScript("OnEvent", function(_, name, ...) -- unguarded: the events' guard itself (Deliver)
            local list = entry.handlers[name]
            if list then Deliver(list, name, ...) end
        end)
        units[unit] = entry
    end
    if not entry.handlers[event] then
        if not Register(entry.frame, event, unit) then return end
        entry.handlers[event] = {}
    end
    entry.handlers[event] = With(entry.handlers[event], fn)
end

function Core.OffUnit(event, unit, fn)
    local entry = units[unit]
    local list = entry and entry.handlers[event]
    if not list then return end
    list = Without(list, fn)
    if #list > 0 then
        entry.handlers[event] = list
    else
        entry.handlers[event] = nil
        entry.frame:UnregisterEvent(event)
    end
end

-------------------------------------------------------------------------------
--  Fights and the game's restrictions
-------------------------------------------------------------------------------
-- Whether a frame may not be moved, sized, shown or hidden by our code now: it is protected (it
-- holds secure buttons, or is one) and a fight is on.
function Core.Locked(frame)
    return InCombatLockdown() and frame:IsProtected() and true or false
end

-- The restrictions under which SaneUI's long work waits (Enum.AddOnRestrictionType): combat, an
-- encounter, a challenge mode, a PvP match, a map that restricts addons. Not chat, which only limits
-- addon messages. The game tells each change before a restriction begins and after it ends; its state
-- is kept from that event, not asked (the game answers false while the event is sent).
Core.RESTRICTIONS = { 0, 1, 2, 3, 4 }
local restricted = {} -- [type] = true while the game restricts it (or is about to)

Core.On("ADDON_RESTRICTION_STATE_CHANGED", function(kind, state)
    for _, known in ipairs(Core.RESTRICTIONS) do
        if known == kind then restricted[kind] = state ~= 0 or nil end
    end
end)

-- At login the state is asked once: a /reload inside a restriction gets no event for its beginning.
Core.On("PLAYER_LOGIN", function()
    local api = rawget(_G, "C_RestrictedActions")
    if not (api and api.IsAddOnRestrictionActive) then return end
    for _, kind in ipairs(Core.RESTRICTIONS) do
        restricted[kind] = Core.Ask(api.IsAddOnRestrictionActive, kind) == true or nil
    end
end)

-- In a fight, or the game restricts addons now.
function Core.Restricted()
    return InCombatLockdown() or next(restricted) ~= nil
end

-- Runs fn now, or once the fight is over (in a fight). The same key asked again in a fight is one
-- run, with the arguments asked last: for a window to place, a frame to give back. Returns true when
-- it ran now. Each run is safe: a failure is noted, the others go on.
local owed, order = {}, {} -- [key] = { fn, label, args, count }; the keys in the order they were asked

local function Label(key)
    return type(key) == "string" and key or "after the fight"
end

function Core.AfterCombat(key, fn, ...)
    if not InCombatLockdown() then
        Core.Safe(Label(key), fn, ...)
        return true
    end
    if not owed[key] then order[#order + 1] = key end
    owed[key] = { fn = fn, args = { ... }, count = select("#", ...) }
    return false
end

-- Whether something waits for the fight's end under that key.
function Core.Owed(key)
    return owed[key] ~= nil
end

Core.On("PLAYER_REGEN_ENABLED", function()
    local keys = order
    order = {}
    for _, key in ipairs(keys) do
        local job = owed[key]
        owed[key] = nil
        if job then Core.Safe(Label(key), job.fn, unpack(job.args, 1, job.count)) end
    end
end)

-- An action the game blocked because it came from SaneUI's code ("Interface action failed because of
-- an AddOn"): noted, so the error log says what did it. Another addon's are not ours to note. The game
-- tells it while the blocked call still runs, so the trace names the place that made it: the action
-- alone is often UNKNOWN(), and the addon named is the one whose code came first (Core, whose guards
-- every module's code runs through).
local function Blocked(addon, action)
    if type(addon) ~= "string" or not addon:find("^SaneUI") then return end
    local trace = debugstack and debugstack(2, 20, 10) or ""
    Core.Report("blocked action", ("%s: the game blocked %s\n%s"):format(addon, tostring(action), trace))
end
Core.On("ADDON_ACTION_BLOCKED", Blocked)
Core.On("ADDON_ACTION_FORBIDDEN", Blocked)

-------------------------------------------------------------------------------
--  Modules
-------------------------------------------------------------------------------
Core.modules = {} -- in the order they were made, which is the order the game loaded their addons

-- Modules that are part of another now, by their old name (Saneroki, 2026-11-18: "I want a combat module that has the
-- unit frames, party frames, Nameplates and the edit aura tracking functionality in it"): the old addon, still in a
-- player's AddOns folder, stays off (as module.elsewhere: never started, no options page) and is told once at the
-- login, so its folder goes; its part runs in the module it is part of, never twice.
Core.RETIRED = { Nameplates = { into = "Combat", addon = "SaneUI_Nameplates" } }
Core.TEXT_RETIRED = "the addon %s is part of %s now: delete its folder %s from Interface\\AddOns and switch %s on in the addon list."
local retired = {} -- the old addons that were loaded, told at the login

-- Makes a module: a table of its own, found again as SaneUI.<name>, with the
-- tools above and messages of its own (Listen and Fire) for its files to talk.
-- addon is the folder its files are in: the module is started when that addon is loaded.
function Core.NewModule(addon, name, module)
    assert(type(addon) == "string" and type(name) == "string", "SaneUI: a module needs its addon and a name")
    assert(SaneUI[name] == nil, "SaneUI: there are two modules called " .. name)
    module = module or {}
    module.addon, module.name = addon, name
    module.title = module.title or name
    module.Print, module.Plain, module.On = Core.Print, Core.Plain, Core.On
    byAddon[addon] = byAddon[addon] or module
    -- A module made for the other game only (its TOC's X-SaneUI-Games) is off here from the start, without a
    -- word: never started, its guards shut, no options page (module.elsewhere).
    if not Core.ServesGame(addon) then module.off, module.elsewhere = true, true end
    if Core.RETIRED[name] then
        module.off, module.elsewhere, module.retired = true, true, Core.RETIRED[name].into
        retired[#retired + 1] = name
    end

    -- As Core.Safe, the label under the module's name. The step runs first: the label's string is
    -- only made when it failed (Safe is used for what runs many times a second).
    function module.Safe(label, fn, ...)
        local ok, result = xpcall(fn, Trace, ...)
        if ok then return result end
        Core.Report(name .. ": " .. label, result)
        return nil
    end

    function module.Report(label, text)
        Core.Report(name .. ": " .. label, text)
    end

    -- An error that no step of the module caught stands it down, once: from then on module.off is
    -- true, and its guarded steps (Guarded) and functions (Guard) do nothing. A module that stands in
    -- for something of the game's (its tooltips, its chat, its spellbook) gives it back then: it says
    -- how in module.GiveBack (a function) and what is told in module.GIVEN_BACK (a few words). What
    -- works beside the game's own (a switch, the channels a character is in) may go on: it runs Safe.
    function module.StandDown(problem)
        if module.off then return end
        module.off = true
        if module.GiveBack then
            local ok, failed = xpcall(module.GiveBack, Trace)
            if not ok then Core.NoteError(name .. ": giving back", failed) end
        end
        module.Report(module.GIVEN_BACK or "it stopped", problem)
    end

    -- Runs a step; an error stands the module down. Returns the step's first result. Makes no
    -- table and no closure: for what runs many times a second (Safe makes none either).
    function module.Guarded(fn, ...)
        if module.off then return nil end
        local ok, result = xpcall(fn, Trace, ...)
        if ok then return result end
        module.StandDown(result)
        return nil
    end

    -- Pass(xpcall(fn, ...)): all of fn's results when it worked. Its error came in by the door.
    local function Pass(ok, ...)
        if ok then return ... end
        Failed(module, name, (...))
        return nil
    end

    -- As Core.Gently, the label under the module's name: a door whose error stands nothing down (a search field's
    -- keys, list and answers); it does nothing once the module stood down for another error.
    --     box:SetScript("OnTextChanged", ns.Gently("map search", Changed))
    function module.Gently(label, fn)
        label = name .. ": " .. label
        return function(...)
            if module.off then return nil end
            return Softly(label, xpcall(fn, Trace, ...))
        end
    end

    -- fn guarded, for the game to call later: a frame's script, a hook, a timer, a menu's or a
    -- dialog's function. It does nothing once the module stood down, and its error stands the
    -- module down. It hands on all of fn's results and makes no table and no closure when called.
    --     button:SetScript("OnClick", ns.Guard(OnClick))
    function module.Guard(fn)
        return function(...)
            if module.off then return nil end
            return Pass(xpcall(fn, Trace, ...))
        end
    end

    local listeners, labels = {}, {} -- [message] = its functions; = their labels ("refresh2"), made once

    function module.Listen(message, fn)
        local list = listeners[message] or {}
        listeners[message], labels[message] = list, labels[message] or {}
        list[#list + 1] = fn
        labels[message][#list] = message:lower() .. #list
    end

    -- Fires a message to its listeners. Makes no string and no table while they succeed.
    function module.Fire(message, ...)
        local list = listeners[message]
        if not list then return end
        local names = labels[message]
        for index, fn in ipairs(list) do module.Safe(names[index], fn, ...) end
    end

    Core.modules[#Core.modules + 1] = module
    SaneUI[name] = module
    return module
end

-- An old addon of a retired module was loaded: said once, at the login, in chat.
Core.On("PLAYER_LOGIN", function()
    for _, name in ipairs(retired) do
        local old = Core.RETIRED[name]
        Core.Print(Core.TEXT_RETIRED:format(old.addon, old.into, old.addon, old.into))
    end
end)

-- addon: only the modules of that addon; nil: all of them. A step that fails stands its module
-- down. A module that stood down, in whichever step or at whichever door (its OnLoad, an error in
-- one of its files, a listener before the login), gets no further step: its OnLogin would take back
-- what it gave back, with every guard of it shut.
local function Start(step, addon)
    for _, module in ipairs(Core.modules) do
        if module[step] and not module.off and (not addon or module.addon == addon) then
            local ok, problem = xpcall(module[step], Trace)
            if not ok then Failed(module, step, problem) end
        end
    end
end

Core.On("ADDON_LOADED", function(name)
    -- The modules' files are read after Core's addon: an error in one of them (a template or a
    -- function a client update took away) is noted from here on.
    if name == ADDON then Core.Safe("error log", ListenForGameErrors) end
    if type(name) == "string" and name:find("^SaneUI_") then Core.Safe("Core's version", TellOldCore, name) end
    Start("OnLoad", name)
    -- A module whose addon is read after the login (one loaded on demand) missed it.
    if Core.charKey then Start("OnLogin", name) end
end)

Core.On("PLAYER_LOGIN", function()
    -- A Forever name is a first name and a surname ("Droopy Fairwind"); two of your characters
    -- can share the first. The GUID is the character's own number.
    local _, class = UnitClass("player")
    local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or "?"
    Core.class, Core.charName, Core.realm = class, Core.FullName("player") or "?", (GetRealmName and Core.Plain(GetRealmName())) or realm
    Core.charKey = Core.Plain(UnitGUID("player")) or (Core.charName .. "-" .. realm)
    Start("OnLogin")
end)

-- Before the game writes the saved settings (a logout, a /reload). Core.lua's listener comes first. The
-- settings in use stay where they live (Profiles.lua moves nothing at the logout), so a module may read
-- its options here or in a listener of its own.
Core.On("PLAYER_LOGOUT", function()
    Start("OnLogout")
end)

-------------------------------------------------------------------------------
--  /sane
-------------------------------------------------------------------------------
local commands, listed = {}, {}

-- Core.Command("spellbook", "what it is for", fn, "sb"): "/sane spellbook list" and
-- "/sane sb list" both run fn("list").
function Core.Command(word, about, fn, ...)
    local command = { word = word, about = about, fn = fn }
    commands[word] = command
    for _, alias in ipairs({ ... }) do commands[alias] = command end
    listed[#listed + 1] = command
end

Core.Command("errors", "the error log, one line per problem (/sane errors clear empties it)", function(rest)
    if rest == "clear" then
        wipe(Core.errors)
        wipe(Core.log)
        wipe(told) -- a problem that comes again is told again
        Core.Print("errors forgotten.")
        return
    end
    local labels = {}
    for label in pairs(Core.errors) do labels[#labels + 1] = tostring(label) end
    table.sort(labels)
    if #labels == 0 then
        Core.Print("no errors noted.")
        return
    end
    for _, label in ipairs(labels) do
        local problem = Core.errors[label]
        if type(problem) == "table" then -- the saved file may hold anything
            Core.Print(("%s (%dx, last %s): %s"):format(tostring(label), tonumber(problem.count) or 1,
                tostring(problem.when or "?"), (tostring(problem.text):match("^[^\n]*"))))
        end
    end
    Core.Print(("the log has %d entries, with the place each happened. It is written to the saved settings file at a /reload or when you log out."):format(#Core.log))
end)

SLASH_SANEUI1 = "/sane"
SLASH_SANEUI2 = "/saneui"
SlashCmdList.SANEUI = Core.Guard("/sane", function(text)
    text = strtrim(text or "")
    local word, rest = text:match("^(%S+)%s*(.-)$")
    local command = word and commands[word:lower()]
    if command then
        Core.Safe("/sane " .. command.word, command.fn, rest)
        return
    end
    local titles = {}
    for _, module in ipairs(Core.modules) do
        if not module.retired then -- an old addon of a module that is part of another now: not one of them
            titles[#titles + 1] = module.off and module.title .. " (stopped, see /sane errors)" or module.title
        end
    end
    Core.Print(("version %s. %s"):format(Core.VERSION, #titles > 0 and "Modules: " .. table.concat(titles, ", ") .. "."
        or "No module is switched on: tick them under " .. Core.TITLE .. " in the addon list."))
    for _, known in ipairs(listed) do
        Core.Print(("/sane %s - %s"):format(known.word, known.about))
    end
end)
