-- A small stand-in for the WoW client, so the addon's logic can run under plain Lua 5.1.
-- It models only what Sane UI touches: action slots, the cursor, the spellbook, bags,
-- timers, events, the options and "frames" that accept any widget call.
-- Used by the tests next to it (core.lua, spellbook.lua, tooltips.lua, social.lua). Not part of the addon.
--
-- What it does of the game that a test may lean on:
--   timers: C_Timer.After, NewTimer and NewTicker as the game has them (callback(ticker), Cancel, IsCancelled,
--     Invoke, iterations), run by W.Wait; every ticker and timer made is in W.tickers, in order;
--   events: a frame hears an event from its RegisterEvent on, in the order of registering, never one in flight
--     when it registered; OnShow and OnHide run when a frame starts or stops being seen, its children with it
--     (those seen as the walk starts: one shown meanwhile had its own); a point anchored again replaces its anchor;
--   methods: a widget answers its kind's methods and, the game's frame API being wider than what is modelled here,
--     any other PascalCase name as a call that does nothing; hooksecurefunc hooks what that one lookup gives and
--     errors on what it does not (a nil global, a lower-case name, what the kind lacks); W.Methods(widget, own)
--     gives a widget a mixin's methods and, by false, the names it lacks (nil then, as in the game, and refused);
--     a StatusBar keeps its value and bounds as given (SetValue, GetValue, SetMinMaxValues, GetMinMaxValues);
--   W.Secret(value): a secret value as the 12.x client hands them out: a userdata that errors on arithmetic,
--     comparison, #, indexing and calling, and gives another secret when concatenated; issecretvalue and
--     canaccessvalue know it. Not modelled: a boolean test (if secret then), a secret as a table key, and == or ~=
--     of one against a value of another type (Lua 5.1 asks __eq of two userdata only) all pass here, where the
--     game errors; and type() says "userdata" of it, where the game's secret number says "number", so only
--     issecretvalue (Core.Plain) tells a secret apart in both;
--   W.Combat(on): in and out of combat with the game's events, in the game's order: PLAYER_REGEN_DISABLED fires
--     before the lock (W.combat), its handlers' last chance at a protected frame; the lock ends before
--     PLAYER_REGEN_ENABLED. While W.combat, Show, Hide, SetParent, SetAttribute and the anchoring and sizing calls
--     (SetPoint, SetAllPoints, ClearAllPoints, SetWidth, SetHeight, SetSize, SetScale) on a protected frame error
--     as the game blocks them (ADDON_ACTION_BLOCKED): one made from a Secure... template or marked _protected by
--     the test and, as in the game, every frame such a frame stands under (IsProtected answers both: protected,
--     explicitly so); a test that only sets W.combat = true gets the same, a frame that is not protected is never
--     blocked, and W.AsGame(fn) runs fn as the game's own secure code, the block lifted and W.combat kept;
--   W.SelfCheck(): the stand-in's own doors tried; Core.Plain and Core.Ask on a secret too when Core is loaded.

local W = {}

W.clock = 100
W.serverStart = 1800000000
W.combat = false
W.cursor = nil            -- { kind = , id = } on the simulated cursor
W.actions = {}            -- [slot] = { kind = , id = , text = }
W.spells = {}             -- [id] = { name = , sub = , passive = , icon = }
W.book = {}               -- learned spellbook rows: { id = , line = , low = }
W.lines = { "General" }   -- names of the spellbook tabs
W.skillLines = {}         -- [the game's skill line number] = tab number
W.items = {}              -- [id] = { name = , count = , usable = }
W.macros = {}             -- [name] = index
W.trainer = nil           -- rows of the open trainer window: { name, kind, icon, level, sub, category, id, cost }
W.trainerFilter = { available = true, unavailable = true, used = false }
W.traits = {}             -- spell IDs of the class talent tree
W.cvars = { scriptErrors = "1" } -- the game shows Lua errors: those Sane UI catches at a door go to CallErrorHandler too
W.level = 1
W.printed = {}
W.frames = {}
W.timers = {}
W.tickers = {}            -- every ticker and timer made (C_Timer.NewTicker, NewTimer), in order
W.popups = {}
W.menus = {}
W.links = {}              -- what was sent to the chat line
W.errors = {}             -- what the red text in the middle of the screen said
W.foci = {}               -- frames "under the mouse"
W.loaded = {}             -- [addon name] = true
W.onDemand = {}          -- [addon name] = function that reads it, for an addon that is loaded when asked for
W.slotOfSpell = {}        -- [spell ID] = spellbook slot, for the game's "go to this spell"
W.gamepad = false         -- a controller is in use
W.templates = {}          -- [frame template] = function(widget) that gives it its parts
W.xmlTemplates = {}       -- [template name] = its kind ("AnimationGroup", "Frame"): the virtual ones of the XML files loaded
W.cvarInfo = {}           -- [CVar name] = { default, scope = "character" | "account" | nil (the computer),
                          -- locked, secure, readOnly, category, help }; its value is in W.cvars
W.options = { pages = {} } -- the pages the addon put into the game's options (a page under another one has
                           -- .parent); opened = the page on show
W.caught = nil            -- set to a list to collect the errors of event handlers instead of stopping
W.ms = 0                  -- the client's precise clock in milliseconds (debugprofilestop), moved by the test
W.fps = 60                -- the frame rate (GetFramerate)
W.restrictions = {}       -- [Enum.AddOnRestrictionType] = true while the game restricts addons so
W.addons = {}             -- the addon list: { name, title, notes, loadable, reason, enabled (0 or 2),
                          -- metadata = { [field] = text } }
W.sets = {}               -- the set files given before W.LoadCore: run as the last files of Core's TOC (W.AddSets)
W.fileErrors = {}         -- the errors of files that ran as the game runs them (it shows them, goes on)
W.project = 18            -- the client: WOW_PROJECT_ID (WoW: Forever's is 18, WOW_PROJECT_CAMELOT)
W.build = 70245           -- its build (GetBuildInfo)
W.beta = false            -- IsBetaBuild
W.test = false            -- IsTestBuild and IsPublicTestClient
W.regionalNames = true    -- RegionalUniqueNamesEnabled: a player is a first name and a surname, unique in the region

-- Runs one file of an addon as the game would: with the addon's name and the table only its files see.
-- file is its path in src ("Abilities/Book/Item"). The addon's ADDON_LOADED is the test's to fire.
function W.Load(root, addon, file, private)
    local chunk = assert(loadfile(root .. "/src/" .. file .. ".lua"))
    chunk(addon, private)
end

-- One file a TOC lists (or an XML file includes), as the game loads it: a .lua runs; a .xml has its
-- <Script file="..."/> and <Include file="..."/> followed, relative to it (as dev/tests/lint reads
-- them), and its virtual templates noted (W.xmlTemplates, which C_XMLUtil.GetTemplateInfo answers from).
-- Anything else is an error: a file the game would load must never be skipped here unnoticed.
-- path: the file's path inside the addon's folder in src, with either kind of slash.
local function LoadListed(root, addon, folder, path, private)
    path = path:gsub("\\", "/")
    if path:match("%.lua$") then
        W.Load(root, addon, folder .. "/" .. path:sub(1, -5), private)
    elseif path:match("%.xml$") then
        local file = assert(io.open(root .. "/src/" .. folder .. "/" .. path, "r"), addon .. " lists a file that is not there: " .. path)
        local xml = file:read("*a")
        file:close()
        local dir = path:match("^(.*/)") or ""
        for kind, included in xml:gmatch('<(%a+)%s+file="([^"]+)"') do
            if kind == "Script" or kind == "Include" then LoadListed(root, addon, folder, dir .. included, private) end
        end
        for kind, attributes in xml:gmatch("<(%a+)%s([^>]-)>") do
            local name = attributes:match('name="([^"]+)"')
            if name and attributes:match('virtual="true"') then W.xmlTemplates[name] = kind end
        end
    else
        error(("%s lists a file that is neither Lua nor XML: %s"):format(addon, path))
    end
end

-- The game types each client is in (W.project): Forever's camelot and mainline, Retail's standard and mainline.
local GAME_TYPES = { [18] = { camelot = true, mainline = true }, [1] = { standard = true, mainline = true } }

-- Whether a file line's conditions ("[AllowLoadGameType standard]", "[ExcludeLoadGameType standard]") let the
-- client the test plays (W.project) read it, as the game decides it.
function W.Allowed(conditions)
    local types = GAME_TYPES[W.project] or {}
    for key, list in (conditions or ""):gmatch("%[%s*(%a+)%s*:?%s*([^%]]*)%]") do
        local named = false
        for word in list:lower():gmatch("%a+") do named = named or types[word] or false end
        if key == "AllowLoadGameType" and not named then return false end
        if key == "ExcludeLoadGameType" and named then return false end
    end
    return true
end

-- The game the test plays, Forever (at first) or Retail: its project (WOW_PROJECT_ID, W.project) and Core told
-- (Core.TellGame). Playing Retail, what Retail lacks of Forever's interface (games.lua, made from the newest
-- exports) is not there, as in the game: a global, a field of a table (C_SpellBook.IsSpellBookItemLowRank,
-- Enum.TrainerType), whether the stand-in or the test made it; reading such a global gives nil, and an event
-- Retail lacks cannot be registered. Back to Forever, all of it is there again. A test that wants one of them
-- in Retail all the same sets it after W.Play.
--     W.Play("retail")   ...   W.Play("forever")
W.hidden = {}        -- [global name] = true: a global the game played lacks (the stand-in's index gives nil)
W.hiddenEvents = {}  -- [event] = true: an event the game played lacks
local stash = {}     -- { table, key, value } of each thing hidden, to be given back
local lacks          -- [game] = the names it lacks (games.lua), read when first wanted
function W.Play(game, env)
    env = env or _G
    for index = #stash, 1, -1 do rawset(stash[index][1], stash[index][2], stash[index][3]) end
    stash, W.hidden, W.hiddenEvents = {}, {}, {}
    W.project = game == "retail" and 1 or 18
    rawset(env, "WOW_PROJECT_ID", W.project)
    if game == "retail" then
        lacks = lacks or require("games")
        for name in lacks.retail:gmatch("[^\n]+") do
            local event = name:match("^event:(.+)$")
            if event then
                W.hiddenEvents[event] = true
            else
                local holder, key = env, nil
                for part in name:gmatch("[^.]+") do
                    if key then holder = type(holder) == "table" and rawget(holder, key) or nil end
                    key = part
                end
                if holder == env then W.hidden[key] = true end
                if type(holder) == "table" and rawget(holder, key) ~= nil then
                    stash[#stash + 1] = { holder, key, rawget(holder, key) }
                    rawset(holder, key, nil)
                end
            end
        end
    end
    local sane = rawget(env, "SaneUI")
    if type(sane) == "table" and sane.Core and sane.Core.TellGame then sane.Core.TellGame() end
end

-- Runs every file an addon's TOC lists, in its order: each line that is not empty and not a comment
-- (the ## directives are comments too) names one, but for the other game's (its conditions, W.Allowed).
local function LoadToc(root, addon, folder, toc, private)
    for line in io.lines(root .. "/src/" .. folder .. "/" .. toc) do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            local file, conditions = line:match("^(.-)%s*(%[.*%])$")
            if W.Allowed(conditions) then LoadListed(root, addon, folder, file or line, private) end
        end
    end
end

-- Runs every file of Core (its Sync and Settings too), in the order its TOC lists them. Its
-- ADDON_LOADED is the test's to fire.
function W.LoadCore(root)
    LoadToc(root, "SaneUI", "Core", "SaneUI.toc", {})
    local given = W.sets
    W.sets = {}
    for _, path in ipairs(given) do W.AddSets(path) end
end

-- Runs every file of a module (src/<folder>), in the order its TOC lists them, with the one
-- table they share. Its ADDON_LOADED is the test's to fire (or C_AddOns.LoadAddOn's).
function W.LoadAddon(root, folder, addon)
    local private = {}
    LoadToc(root, addon, folder, addon .. ".toc", private)
    return private
end

local function Listed(name)
    for index, addon in ipairs(W.addons) do
        if addon.name == name then return addon, index end
    end
    return nil
end
W.Listed = Listed

-- Core's set files (Sets/<Set>.lua, as dev/tools/data compile writes them into Core's addon, or written by the
-- test): path is one file, or a folder whose .lua files run in the order of their names. Given before W.LoadCore
-- they run at the end of Core's files, where its TOC lists them; given later they run at once, as if they had
-- come late. An error in one is kept in W.fileErrors and the next one runs, as in the game.
function W.AddSets(path)
    if not (rawget(_G, "SaneUI") and SaneUI.Core and SaneUI.Core.Data and SaneUI.Core.Data.Add) then
        W.sets[#W.sets + 1] = path
        return
    end
    local files = {}
    if path:match("%.lua$") then
        files[1] = path
    else
        for file in io.popen(("ls '%s'"):format(path)):lines() do
            if file:match("%.lua$") then files[#files + 1] = path .. "/" .. file end
        end
        table.sort(files)
    end
    for _, file in ipairs(files) do
        local chunk, problem = loadfile(file)
        local ok = chunk and true
        if chunk then ok, problem = pcall(chunk, "SaneUI", {}) end
        if not ok then W.fileErrors[#W.fileErrors + 1] = file .. ": " .. tostring(problem) end
    end
end

-- Takes an addon out of the addon list again.
function W.RemoveAddon(name)
    local _, index = Listed(name)
    if index then table.remove(W.addons, index) end
    W.onDemand[name], W.loaded[name] = nil, nil
end

-------------------------------------------------------------------------------
--  Frames: any PascalCase call works; a few behave like the real thing.
-------------------------------------------------------------------------------
local methods = {}
W.methods = methods -- a test may add what its module needs of a widget
-- What a kind of the game's widgets does not have: nil there as in the game (a picture's calls on words).
local LACKS = {
    FontString = { SetAtlas = true, SetTexture = true, SetColorTexture = true, SetTexCoord = true },
    Texture = { SetText = true, SetFont = true, SetFontObject = true },
}
local function NewWidget(kind, name, parent)
    local widget = { _kind = kind, _name = name, _parent = parent, _shown = true, _scripts = {}, _events = {},
                     _points = {}, _width = 0, _height = 0, _alpha = 1, _children = {} }
    local lacks = LACKS[kind]
    setmetatable(widget, { __index = function(self, key)
        if lacks and lacks[key] then return nil end
        local own = rawget(self, "_lacks") -- what the test declared this one lacks (W.Methods)
        if own and own[key] then return nil end
        if methods[key] then return methods[key] end
        if type(key) == "string" and key:match("^%u") then return function() end end
        return nil
    end })
    if type(parent) == "table" and rawget(parent, "_children") then parent._children[#parent._children + 1] = widget end
    W.frames[#W.frames + 1] = widget
    return widget
end
W.NewWidget = NewWidget

-- What a widget has of its own beyond its kind's, as the game's Mixin gives a frame a mixin's methods
-- (MainActionBarMixin's UpdateDividers), and what it lacks (false): nil from the widget then, as the game's frame
-- answers a method it has not, never the catch-all, and hooksecurefunc refuses it; so a test's frames carry
-- exactly the game's methods where a module probes for them.
--     W.Methods(MainActionBar, { UpdateDividers = function() end, Update = false, UpdateState = false })
function W.Methods(widget, own)
    local lacks = rawget(widget, "_lacks") or {}
    rawset(widget, "_lacks", lacks)
    for name, fn in pairs(own) do
        lacks[name] = fn == false or nil
        rawset(widget, name, fn ~= false and fn or nil)
    end
end

-- The parts of the game's templates the addon reaches for.
W.templates.UICheckButtonTemplate = function(widget) widget.Text = NewWidget("FontString", nil, widget) end
-- The game's outline of a spell that wants attention: hidden at first, its animation asked to play or not.
W.templates.ActionButtonSpellAlertTemplate = function(widget)
    widget._shown = false
    widget.ProcStartFlipbook = NewWidget("Texture", nil, widget)
    local loop = {}
    function loop:Play() self._playing = true end
    function loop:Stop() self._playing = false end
    function loop:IsPlaying() return self._playing or false end
    widget.ProcLoop = loop
end
-- A window with a title (the feedback window), and a box to write several lines in.
W.templates.ButtonFrameTemplate = function(widget)
    function widget:SetTitle(text) self._title = text end
end
W.templates.InputScrollFrameTemplate = function(widget)
    widget.EditBox = NewWidget("EditBox", nil, widget)
    widget.EditBox.Instructions = NewWidget("FontString", nil, widget.EditBox)
    widget.CharCount = NewWidget("FontString", nil, widget)
end
W.templates.MinimalTabTemplate = function(widget)
    widget.Text = NewWidget("FontString", nil, widget)
    function widget.Text:GetStringWidth() return #(self._text or "") * 6 end -- a tab is as wide as its words
    function widget:SetSelected(selected) self._selected = selected end
end

-- The game refuses a draw layer that is no word ("Usage: local texture = self:CreateTexture(params)"), as the stand-in does.
function methods:CreateTexture(_, layer)
    if layer ~= nil and type(layer) ~= "string" then error("bad argument #3 to 'CreateTexture' (Usage: local texture = self:CreateTexture(params))", 2) end
    return NewWidget("Texture", nil, self)
end
-- A button's own art: a texture for each of its states, to ask for again.
for _, state in ipairs({ "Normal", "Highlight", "Pushed" }) do
    methods["Set" .. state .. "Texture"] = function(self, texture)
        self["_" .. state] = self["_" .. state] or NewWidget("Texture")
        self["_" .. state]._texture = texture
    end
    methods["Get" .. state .. "Texture"] = function(self) return self["_" .. state] end
end
function methods:CreateMaskTexture() return NewWidget("MaskTexture", nil, self) end
function methods:CreateFontString() return NewWidget("FontString", nil, self) end
function methods:CreateLine() return NewWidget("Line", nil, self) end
function methods:SetScript(name, fn) self._scripts[name] = fn end
function methods:GetScript(name) return self._scripts[name] end
function methods:HookScript(name, fn)
    local original = self._scripts[name]
    self._scripts[name] = function(...)
        if original then original(...) end
        fn(...)
    end
end
-- Who hears an event: W.listeners[event], the frames in the order they registered, as the game delivers it.
W.listeners = {}
function methods:RegisterEvent(event)
    if event == "NOT_A_REAL_EVENT" or W.hiddenEvents[event] then error("unknown event") end
    local list = W.listeners[event] or {}
    W.listeners[event] = list
    for _, known in ipairs(list) do
        if known == self then self._events[event] = true return end
    end
    list[#list + 1] = self
    self._events[event] = true
end
function methods:RegisterUnitEvent(event, ...)
    self:RegisterEvent(event)
    self._units = self._units or {}
    self._units[event] = { ... }
end
function methods:UnregisterEvent(event)
    self._events[event] = nil
    if self._units then self._units[event] = nil end
    local list = W.listeners[event]
    if list then
        for index = #list, 1, -1 do if list[index] == self then table.remove(list, index) end end
    end
end
function methods:UnregisterAllEvents()
    for event in pairs(self._events) do self:UnregisterEvent(event) end
end
function methods:IsEventRegistered(event)
    return self._events[event] == true, unpack(self._units and self._units[event] or {})
end
-- Combat: a protected frame cannot be shown, hidden, re-parented, given an attribute, anchored or sized while
-- W.combat, as the game blocks it (ADDON_ACTION_BLOCKED): here an error, so a test sees the call the game would
-- refuse. Protected explicitly: made from a Secure... template, or marked _protected by the test; and, as in the
-- game, every frame such a frame stands under, since hiding or moving it would hide or move the protected one
-- (IsProtected answers both, as the game's does: protected, explicitly so).
local function Explicit(widget)
    local template = rawget(widget, "_template")
    return rawget(widget, "_protected") == true or (type(template) == "string" and ("," .. template):match(",%s*Secure") ~= nil)
end
local function Protected(widget)
    if Explicit(widget) then return true, true end
    for _, child in ipairs(rawget(widget, "_children") or {}) do
        if Protected(child) then return true, false end
    end
    return false, false
end
-- The game's own secure code in a fight (a key that opens the spellbook, the unit watch): fn runs with the block
-- lifted while W.combat and InCombatLockdown() stay true. The frame scripts it sets off (OnShow, OnHide) run under
-- the block again, as the game runs an addon's hooks of them; a script that stands for the game's own wraps its
-- touch in W.AsGame itself.
function W.AsGame(fn, ...)
    local lifted = W.lifted
    W.lifted = true
    local function done(ok, ...)
        W.lifted = lifted
        if not ok then error((...), 0) end
        return ...
    end
    return done(pcall(fn, ...))
end
local function Blocked(widget, method)
    if W.combat and not W.lifted and Protected(widget) then
        error(("ADDON_ACTION_BLOCKED: %s() on a protected frame in combat"):format(method), 3)
    end
end
-- In the game's order: it tells of the fight before it locks protected frames, so a handler of
-- PLAYER_REGEN_DISABLED has its last chance at one (InCombatLockdown() false there); the lock ends before it tells
-- of the fight's end, so a handler of PLAYER_REGEN_ENABLED is free again.
function W.Combat(on)
    if on then
        W.Fire("PLAYER_REGEN_DISABLED")
        W.combat = true
    else
        W.combat = false
        W.Fire("PLAYER_REGEN_ENABLED")
    end
end
function methods:IsProtected() return Protected(self) end
function methods:SetAttribute(name, value)
    Blocked(self, "SetAttribute")
    self._attributes = self._attributes or {}
    self._attributes[name] = value
end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
-- A secure snippet wrapped round a script (SecureHandlerBaseTemplate's WrapScript): kept as a function of (self, button,
-- down), to run as the game's restricted code would, its functions (UnitExists) from the globals.
function methods:WrapScript(_, script, snippet)
    self._wraps = self._wraps or {}
    self._wraps[script] = assert(loadstring("return function(self, button, down) " .. snippet .. "\nend"))()
end

-- Shown and hidden: OnShow and OnHide reach every frame that starts or stops being seen, a parent's shown
-- children with it, as the game runs them (dev/uilab/lab/frames.lua does the same): nothing for a frame shown
-- under a hidden parent.
-- The frame itself first, whatever its own state says (hidden already, in OnHide: IsShown() is false there, as
-- in the game), then the children shown as the walk started and still shown: one a script shows meanwhile had
-- its OnShow from its own Show (the parent seen by then), once, as in the game.
-- A script runs under the block of a fight even inside W.AsGame: it is the addon's hook, which the game runs
-- insecure however secure the call that set it off.
local function Walk(widget, script)
    local shown = {}
    for index, child in ipairs(widget._children) do shown[index] = child._shown and child or false end
    local fn = widget._scripts[script]
    if fn then
        local lifted = W.lifted
        W.lifted = nil
        fn(widget)
        W.lifted = lifted
    end
    for _, child in ipairs(shown) do
        if child and child._shown then Walk(child, script) end
    end
end
local function ShownChanged(widget, wasVisible)
    local now = widget:IsVisible()
    if now and not wasVisible then
        Walk(widget, "OnShow")
    elseif wasVisible and not now then
        Walk(widget, "OnHide")
    end
end
function methods:Show()
    Blocked(self, "Show")
    if self._shown then return end
    local was = self:IsVisible()
    self._shown = true
    ShownChanged(self, was)
end
function methods:Hide()
    Blocked(self, "Hide")
    if not self._shown then return end
    local was = self:IsVisible()
    self._shown = false
    ShownChanged(self, was)
end
function methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function methods:IsShown() return self._shown end
function methods:IsVisible()
    local widget = self
    while widget do
        if not widget._shown then return false end
        widget = widget._parent
    end
    return true
end
function methods:IsMouseOver() return self._mouseOver or false end
function methods:SetText(text) self._text = text end
function methods:SetEnabled(enabled) self._disabled = not enabled end
function methods:IsEnabled() return not self._disabled end
function methods:Enable() self._disabled = false end
function methods:Disable() self._disabled = true end
-- A dropdown (WowStyle1DropdownTemplate): its menu is made anew when asked; _items is what it holds.
function methods:SetupMenu(generator)
    self._generator = generator
    self:GenerateMenu()
end
function methods:GenerateMenu()
    self._items = {}
    if self._generator then self._generator(self, W.Description(self._items)) end
end
function methods:SetDefaultText(text) self._defaultText = text end
function methods:SetScrollChild(child) self._child = child end
function methods:GetText() return self._text end
function methods:SetTexture(texture) self._texture = texture end
function methods:GetTexture() return self._texture end
function methods:SetAtlas(atlas) self._atlas = atlas end
function methods:SetChecked(checked) self._checked = checked end
function methods:GetChecked() return self._checked end
function methods:GetParent() return self._parent end
function methods:SetParent(parent)
    Blocked(self, "SetParent")
    local was = self:IsVisible()
    local old = self._parent
    if type(old) == "table" and rawget(old, "_children") then
        local list = old._children
        for index = #list, 1, -1 do if list[index] == self then table.remove(list, index) end end
    end
    self._parent = parent
    if type(parent) == "table" and rawget(parent, "_children") then parent._children[#parent._children + 1] = self end
    ShownChanged(self, was)
end
function methods:ClearAllPoints() Blocked(self, "ClearAllPoints") self._points = {} end
function methods:SetPoint(point, relativeTo, relativePoint, x, y)
    Blocked(self, "SetPoint")
    if type(relativeTo) == "number" then relativeTo, relativePoint, x, y = nil, nil, relativeTo, relativePoint end
    local entry = { point, relativeTo, relativePoint or point, x or 0, y or 0 }
    -- a point anchored again replaces its anchor, as in the game: one anchor a point
    for index, known in ipairs(self._points) do
        if known[1] == point then self._points[index] = entry return end
    end
    self._points[#self._points + 1] = entry
end
function methods:SetAllPoints(other)
    Blocked(self, "SetAllPoints")
    self._points = { { "TOPLEFT", other, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", other, "BOTTOMRIGHT", 0, 0 } }
end
function methods:GetPoint(index)
    local point = self._points[index or 1]
    if point then return point[1], point[2], point[3], point[4], point[5] end
end
function methods:GetNumPoints() return #self._points end
function methods:SetWidth(width) Blocked(self, "SetWidth") self._width = width end
function methods:SetScale(scale) Blocked(self, "SetScale") self._scale = scale end
function methods:GetObjectType() return self._kind end
function methods:GetScale() return self._scale or 1 end
function methods:GetSize() return self._width, self._height end
function methods:GetWidth() return self._width end
function methods:SetHeight(height) Blocked(self, "SetHeight") self._height = height end
function methods:GetHeight() return self._height end
function methods:SetSize(width, height) Blocked(self, "SetSize") self._width, self._height = width, height end
function methods:SetAlpha(alpha) self._alpha = alpha end
function methods:GetAlpha() return self._alpha end
-- A bar's value and bounds, kept as given (a secret too), for a test to see what the bar was handed.
function methods:SetMinMaxValues(low, high) self._min, self._max = low, high end
function methods:GetMinMaxValues() return self._min or 0, self._max or 0 end
function methods:SetValue(value) self._value = value end
function methods:GetValue() return self._value or 0 end
function methods:SetTextColor(r, g, b) self._color = { r, g, b } end
function methods:GetTextColor()
    local color = self._color or { 1, 1, 1 }
    return color[1], color[2], color[3]
end
function methods:SetOwner(owner) self._owner = owner end
function methods:GetOwner() return self._owner end
function methods:IsOwned(owner) return self._owner == owner end
function methods:AddLine(text) self._lines = self._lines or {}; self._lines[#self._lines + 1] = text end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return 1 end

-- Fires an event to the frames registered for it when it fires (a copy of the list: a frame a handler registers
-- hears the next one, as in the game), each one still registered when its turn comes.
function W.Fire(event, ...)
    local list = W.listeners[event]
    if not list then return end
    local heard = {}
    for index, widget in ipairs(list) do heard[index] = widget end
    for _, widget in ipairs(heard) do
        local only = widget._units and widget._units[event]
        local wanted = not only or #only == 0
        if only then
            for _, unit in ipairs(only) do wanted = wanted or unit == (...) end
        end
        if widget._events[event] and widget._scripts.OnEvent and wanted then
            widget._scripts.OnEvent(widget, event, ...)
        end
    end
end

-- Let simulated time pass and run the timers that come due.
function W.Wait(seconds)
    local target = W.clock + seconds
    while true do
        local nextIndex, nextTimer
        for index, timer in ipairs(W.timers) do
            if timer.at <= target and (not nextTimer or timer.at < nextTimer.at) then
                nextIndex, nextTimer = index, timer
            end
        end
        if not nextTimer then break end
        table.remove(W.timers, nextIndex)
        if nextTimer.at > W.clock then W.clock = nextTimer.at end
        nextTimer.fn()
    end
    W.clock = target
end

-- Secret values: what the 12.x client hides from addons (health, auras, cooldowns in combat). A userdata that
-- errors wherever the game's secret does (arithmetic, comparison, #, indexing, calling) and gives another secret
-- when concatenated, as the game does; issecretvalue and canaccessvalue (W.Install) know it by this table.
-- Not modelled: a boolean test of one and one as a table key, which the game refuses and plain Lua allows.
local secrets = setmetatable({}, { __mode = "k" })
W.secrets = secrets
function W.Secret()
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)
    local function refused() error("secret value", 2) end
    for _, event in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm", "__len", "__lt", "__le",
                             "__index", "__newindex", "__call" }) do
        mt[event] = refused
    end
    mt.__concat = function() return W.Secret() end
    secrets[proxy] = true
    return proxy
end

local function SlotChanged(slot)
    W.Fire("ACTIONBAR_SLOT_CHANGED", slot)
end

-- What a player does with the mouse on the real bars.
function W.PlayerPlaces(slot, kind, id, text)
    W.actions[slot] = { kind = kind, id = id, text = text }
    SlotChanged(slot)
end

local function IsLearned(id)
    for _, row in ipairs(W.book) do
        if row.id == id then return true end
    end
    return false
end
W.IsLearned = IsLearned

-- line: the spellbook tab the spell lands in (default 2, the first class tab).
function W.Learn(id, line)
    if not IsLearned(id) then W.book[#W.book + 1] = { id = id, line = line or 2 } end
    W.Fire("LEARNED_SPELL_IN_SKILL_LINE", id, 2, false)
    W.Fire("SPELLS_CHANGED")
end

-- The spellbook's rows in the game's order: tab by tab.
local function BookRows()
    local rows, offsets, counts = {}, {}, {}
    for line = 1, #W.lines do
        offsets[line], counts[line] = #rows, 0
        for _, row in ipairs(W.book) do
            if (row.line or 2) == line then
                rows[#rows + 1] = row
                counts[line] = counts[line] + 1
            end
        end
    end
    return rows, offsets, counts
end

-- A row of the game's options: one under another (its parent) is drawn indented, and switched off
-- while its predicate says no. Its predicates (AddModifyPredicate: switched off; AddShownPredicate: not
-- on the page) are asked as the game asks them; watched: the settings by whose change the game looks at
-- it again (AddEvaluateStateCVar); tags: what the options' search finds it by.
function W.Row(row)
    row.predicates, row.shownBy, row.watched, row.tags = {}, {}, {}, {}
    function row:SetParentInitializer(parent, predicate)
        self.parent, self.predicate = parent, predicate
        if predicate then self:AddModifyPredicate(predicate) end
    end
    function row:AddModifyPredicate(fn) self.predicates[#self.predicates + 1] = fn end
    function row:AddShownPredicate(fn) self.shownBy[#self.shownBy + 1] = fn end
    function row:AddEvaluateStateCVar(variable) self.watched[#self.watched + 1] = variable end
    function row:AddSearchTags(...) for index = 1, select("#", ...) do self.tags[#self.tags + 1] = select(index, ...) end end
    function row:EvaluateModifyPredicates()
        for _, fn in ipairs(self.predicates) do if not fn() then return false end end
        return true
    end
    function row:ShouldShow()
        for _, fn in ipairs(self.shownBy) do if not fn() then return false end end
        return true
    end
    function row:GetOptions() return self.options end
    function row:GetSetting() return self.setting end
    return row
end

-------------------------------------------------------------------------------
--  The global functions the addon calls
-------------------------------------------------------------------------------
function W.Install(env)
    env.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        W.printed[#W.printed + 1] = table.concat(parts, " ")
    end
    env.strtrim = function(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end return t end
    env.GetTime = function() return W.clock end
    -- The server's time, whole seconds, W.serverStart ahead of the client's clock.
    env.GetServerTime = function() return math.floor(W.serverStart + W.clock) end
    -- The player's place in the world (W.place = { x, y, z, map }, or a function giving it); nothing by default.
    env.UnitPosition = function(unit)
        local place = unit == "player" and W.place
        if type(place) == "function" then place = place() end
        if place then return place[1], place[2], place[3], place[4] end
    end
    env.C_XMLUtil = { GetTemplateInfo = function(name)
        if W.xmlTemplates[name] then return { type = W.xmlTemplates[name], width = 0, height = 0 } end
    end }
    env.date = function(format, at) return os.date(format, at) end

    -- The game's xpcall hands further arguments on to the function; plain Lua 5.1's does not.
    local plain = xpcall
    env.xpcall = function(fn, handler, ...)
        local args, count = { ... }, select("#", ...)
        return plain(function() return fn(unpack(args, 1, count)) end, handler)
    end
    -- The game's error handler. In a test an error in an event handler ends the run at once,
    -- with the place it happened, unless the test collects them (W.caught).
    env.CallErrorHandler = function(message)
        if W.caught then
            W.caught[#W.caught + 1] = tostring(message)
            return message
        end
        io.stderr:write(debug.traceback("an event handler raised an error: " .. tostring(message), 2) .. "\n")
        os.exit(1)
    end
    -- Timers, as the game's C_Timer has them: After runs fn once; NewTicker calls callback(ticker) every duration,
    -- iterations times (for ever without), until ticker:Cancel(), in its callback too; NewTimer is a ticker of one
    -- iteration. Every ticker made is in W.tickers, in order, for a test to reach.
    local function After(delay, fn) W.timers[#W.timers + 1] = { at = W.clock + delay, fn = fn } end
    local Ticker = {}
    Ticker.__index = Ticker
    function Ticker:Cancel() self._cancelled = true end
    function Ticker:IsCancelled() return self._cancelled end
    function Ticker:Invoke() self._callback() end
    local function NewTicker(duration, callback, iterations)
        local ticker = setmetatable({ _remaining = iterations, _cancelled = false }, Ticker)
        ticker._callback = function()
            if ticker._cancelled then return end
            callback(ticker)
            if ticker._cancelled then return end
            if ticker._remaining then ticker._remaining = ticker._remaining - 1 end
            if not ticker._remaining or ticker._remaining > 0 then After(duration, ticker._callback) end
        end
        After(duration, ticker._callback)
        W.tickers[#W.tickers + 1] = ticker
        return ticker
    end
    env.C_Timer = { After = After, NewTicker = NewTicker,
                    NewTimer = function(duration, callback) return NewTicker(duration, callback, 1) end }
    env.issecretvalue = function(value) return secrets[value] == true end
    env.canaccessvalue = function(value) return secrets[value] == nil end
    env.CreateFrame = function(kind, name, parent, template)
        local widget = NewWidget(kind, name, parent)
        if name then env[name] = widget end
        widget._template = template -- the template it was made from (the tests ask)
        if template and W.templates[template] then W.templates[template](widget) end
        return widget
    end
    -- A font object of the addon's own, by its name (Sane UI's Kalam): a global, as the game makes it.
    env.CreateFont = function(name)
        local font = NewWidget("Font", name)
        if name then env[name] = font end
        return font
    end
    env.UIParent = NewWidget("Frame", "UIParent")
    env.GameTooltip = NewWidget("GameTooltip", "GameTooltip")
    env.UIErrorsFrame = NewWidget("Frame", "UIErrorsFrame")
    env.UIErrorsFrame.AddMessage = function(_, text) W.errors[#W.errors + 1] = text end
    env.UISpecialFrames = {}
    env.SlashCmdList = {}
    -- The game's own dialogs that it keeps for addons, filled from data when shown.
    env.StaticPopupDialogs = { GENERIC_INPUT_BOX = {}, GENERIC_CONFIRMATION = {} }
    -- A dialog: what it was shown with, and its edit box. A test accepts one by calling data.callback.
    env.StaticPopup_Show = function(which, _, _, data)
        local box = { text = "" }
        function box:SetText(text) self.text = text end
        function box:GetText() return self.text end
        function box:HighlightText() self.highlighted = true end
        local dialog = { which = which, data = data, box = box }
        function dialog:GetEditBox() return box end
        W.popups[#W.popups + 1] = dialog
        return dialog
    end
    env.GameTooltip_SetTitle = function() end
    env.GameTooltip_Hide = function() end
    -- Buttons of which one is chosen (tabs): Selected is told with the button.
    env.ButtonGroupBaseMixin = { Event = { Selected = "Selected" } }
    env.CreateRadioButtonGroup = function()
        local group = { buttons = {} }
        function group:AddButtons(buttons)
            for _, button in ipairs(buttons) do
                self.buttons[#self.buttons + 1] = button
                button:SetScript("OnClick", function() self:SelectAtIndex(self:IndexOf(button)) end)
            end
        end
        function group:IndexOf(button)
            for index, known in ipairs(self.buttons) do if known == button then return index end end
        end
        function group:RegisterCallback(_, fn, owner) self.fn, self.owner = fn, owner end
        function group:SelectAtIndex(index)
            self.selected = index
            if self.fn then self.fn(self.owner, self.buttons[index], index) end
        end
        return group
    end
    env.GameTooltip_AddNormalLine = function() end
    env.PlaySound = function() end
    env.SOUNDKIT = { IG_ABILITY_PAGE_TURN = 1, IG_ABILITY_ICON_DROP = 2, IG_SPELLBOOK_OPEN = 3,
        IG_CHARACTER_INFO_OPEN = 4, IG_CHARACTER_INFO_CLOSE = 5 }
    env.CLOSE = "Close"
    env.GetLocale = function() return "enUS" end
    env.tinsert = table.insert
    env.ButtonFrameTemplate_HidePortrait = function(frame) frame._noPortrait = true end
    env.InputScrollFrame_SetInstructions = function(scroll, text) scroll.EditBox.Instructions:SetText(text) end
    -- hooksecurefunc(name, fn) or hooksecurefunc(table, name, fn): a function that is not there is an error at
    -- once, as in the game (a global that is nil, a method the widget lacks), not when it is called. A widget's
    -- method is what the one lookup a module's probe of the name makes gives (its kind's, the catch-all of any
    -- other PascalCase name, nil for what it lacks: LACKS, W.Methods), so the two doors answer alike; it is hooked
    -- on the frame, as the game does.
    env.hooksecurefunc = function(a, b, c)
        local owner, name, hook = env, a, b
        if type(a) == "table" then owner, name, hook = a, b, c end
        local original = rawget(owner, name)
        if original == nil and owner ~= env then original = owner[name] end
        if type(original) ~= "function" then
            error(("hooksecurefunc(): %s is not a function"):format(tostring(name)), 2)
        end
        rawset(owner, name, function(...)
            local results = { original(...) }
            hook(...)
            return unpack(results)
        end)
    end
    env.ChatFrameUtil = {
        InsertLink = function(link)
            W.links[#W.links + 1] = link
            return true
        end,
    }
    env.IsModifiedClick = function(action) return W.modifier == action end
    env.GetMouseFoci = function() return W.foci end

    -- Menus: remember what an addon put in them, so a test can "click" a line.
    local function Description(list)
        local description = {}
        function description:CreateTitle(text)
            local item = { title = text, inits = {} }
            list[#list + 1] = item
            return { AddInitializer = function(_, init) item.inits[#item.inits + 1] = init end }
        end
        function description:CreateDivider() end
        function description:CreateSpacer() list[#list + 1] = { spacer = true } end
        function description:SetGridMode(direction, columns, padding) list.grid = { direction, columns, padding } end
        function description:AddMenuReleasedCallback(fn)
            list.released = list.released or {}
            list.released[#list.released + 1] = fn
        end
        function description:CreateButton(text, fn, data)
            local item = { text = text, fn = fn, data = data, sub = {} }
            list[#list + 1] = item
            local sub = Description(item.sub)
            function sub:SetEnabled(enabled) item.disabled = not enabled end
            function sub:SetTooltip(fn) item.tooltip = fn end
            -- what draws its line (a name in its class's colour), to call with a frame
            function sub:AddInitializer(init) item.inits = item.inits or {}; item.inits[#item.inits + 1] = init end
            return sub
        end
        -- A line drawn by the addon (CreateFrame): its initializers, to call with a frame.
        function description:CreateFrame()
            local item = { frame = true, inits = {} }
            list[#list + 1] = item
            return { AddInitializer = function(_, init) item.inits[#item.inits + 1] = init end }
        end
        function description:CreateRadio(text, isSelected, setSelected, data)
            local item = { text = text, checked = isSelected, fn = setSelected, data = data, inits = {}, sub = {} }
            list[#list + 1] = item
            -- (a radio may hold a menu of its own, as every element of the game's menus may)
            local sub = Description(item.sub)
            function sub:SetResponse(response) item.response = response end
            function sub:SetTooltip(fn) item.tooltip = fn end
            function sub:AddInitializer(init) item.inits[#item.inits + 1] = init end
            return sub
        end
        function description:CreateCheckbox(text, isSelected, setSelected, data)
            local item = { text = text, checked = isSelected, fn = setSelected, data = data, inits = {}, checkbox = true }
            list[#list + 1] = item
            return { SetTooltip = function() end, AddInitializer = function(_, init) item.inits[#item.inits + 1] = init end }
        end
        return description
    end
    W.Description = Description
    env.MenuUtil = { CreateContextMenu = function(owner, generator)
        local menu = { owner = owner }
        generator(owner, Description(menu))
        W.menus[#W.menus + 1] = menu
        function menu:ReinitializeAll() self.refreshed = (self.refreshed or 0) + 1 end
        function menu:Close()
            self.closed = true
            for _, released in ipairs(self.released or {}) do released(self) end
        end
        return menu
    end }
    env.MenuResponse = { Open = 1, Refresh = 2, Close = 3, CloseAll = 4 }
    env.MenuConstants = { VerticalGridDirection = 2, HorizontalGridDirection = 3 }
    env.Menu = { ModifyMenu = function(tag, callback) W.menuModifiers = W.menuModifiers or {}; W.menuModifiers[tag] = callback end }

    -- The game's event registry: callbacks by event name and owner.
    env.EventRegistry = { callbacks = {} }
    function env.EventRegistry:RegisterCallback(event, fn, owner)
        self.callbacks[event] = self.callbacks[event] or {}
        self.callbacks[event][owner] = fn
    end
    function env.EventRegistry:TriggerEvent(event, ...)
        for owner, fn in pairs(self.callbacks[event] or {}) do fn(owner, ...) end
    end

    env.C_AddOns = {
        IsAddOnLoaded = function(name) return W.loaded[name] or false end,
        LoadAddOn = function(name)
            local read, listed = W.onDemand[name], Listed(name)
            if listed and listed.enabled == 0 then return false, "DISABLED" end
            if listed and not listed.loadable and listed.reason ~= "DEMAND_LOADED" then return false, listed.reason end
            if not read then return false, listed and "CORRUPT" or "MISSING" end
            if not W.loaded[name] then
                W.loaded[name] = true
                read()
                W.Fire("ADDON_LOADED", name)
            end
            return true
        end,
        -- An addon of the list answers from its metadata; any other has Version 1.2.3 (Core's own).
        GetAddOnMetadata = function(name, field)
            local listed = Listed(name)
            if listed then return listed.metadata[field] end
            return field == "Version" and "1.2.3" or nil
        end,
        -- 0: switched off for that character, 2: on. An addon the test did not offer is off.
        GetAddOnEnableState = function(name)
            local listed = Listed(name)
            if listed then return listed.enabled end
            return W.onDemand[name] and 2 or 0
        end,
        GetNumAddOns = function() return #W.addons end,
        -- By index or name: name, title, notes, loadable, reason, security, newVersion.
        GetAddOnInfo = function(which)
            local listed = type(which) == "number" and W.addons[which] or Listed(which)
            if not listed then error("no such addon: " .. tostring(which)) end
            return listed.name, listed.title, listed.notes, listed.loadable, listed.reason, "INSECURE", false
        end,
    }

    -- The game's options: remember what an addon puts there, so a test can "tick" a checkbox.
    local function Page(name, parent)
        local page = { name = name, parent = parent, id = #W.options.pages + 1, items = {} }
        function page:GetID() return self.id end
        W.options.pages[page.id] = page
        return page
    end
    env.Settings = {
        RegisterVerticalLayoutCategory = function(name) return Page(name) end,
        RegisterVerticalLayoutSubcategory = function(parent, name) return Page(name, parent) end,
        -- A page of the addon's own: its frame is shown in place of the game's list.
        RegisterCanvasLayoutSubcategory = function(parent, frame, name)
            local page = Page(name, parent)
            page.frame = frame
            return page
        end,
        RegisterAddOnSetting = function(_, variable, key, store, kind, name, default)
            if store[key] == nil then store[key] = default end
            local setting = { variable = variable, name = name, kind = kind }
            function setting:GetValue() return store[key] end
            function setting:SetValue(value)
                store[key] = value
                if self.changed then self.changed(self, value) end
            end
            function setting:SetValueChangedCallback(fn) self.changed = fn end
            -- The value changed from elsewhere: the control shows it, the callback hears it.
            function setting:NotifyUpdate()
                self.notified = (self.notified or 0) + 1
                if self.changed then self.changed(self, store[key]) end
            end
            return setting
        end,
        -- A setting whose value the addon gets and sets itself.
        RegisterProxySetting = function(_, variable, kind, name, default, get, set)
            local setting = { variable = variable, name = name, kind = kind, default = default }
            function setting:GetValue() return get() end
            function setting:SetValue(value)
                set(value)
                if self.changed then self.changed(self, value) end
            end
            function setting:SetValueChangedCallback(fn) self.changed = fn end
            function setting:NotifyUpdate()
                self.notified = (self.notified or 0) + 1
                if self.changed then self.changed(self, get()) end
            end
            return setting
        end,
        CreateCheckboxInitializer = function(setting, _, tooltip) return W.Row({ setting = setting, tooltip = tooltip }) end,
        CreateSliderOptions = function(min, max, step)
            return { min = min, max = max, step = step, SetLabelFormatter = function(self, _, format) self.format = format end }
        end,
        CreateSliderInitializer = function(setting, slider, tooltip) return W.Row({ setting = setting, slider = slider, tooltip = tooltip }) end,
        CreateElementInitializer = function(template, data) return { template = template, data = data } end,
        CreateDropdownInitializer = function(setting, options, tooltip) return W.Row({ setting = setting, options = options, tooltip = tooltip }) end,
        CreateColorSwatchInitializer = function(setting, options, tooltip)
            return W.Row({ setting = setting, options = options, tooltip = tooltip, swatch = true })
        end,
        -- A row of a template of the addon's own, for a setting (its frame is made by the game's list).
        CreateControlInitializer = function(template, setting, options, tooltip)
            return W.Row({ template = template, setting = setting, options = options, tooltip = tooltip,
                data = { setting = setting, options = options, tooltip = tooltip } })
        end,
        CreateControlTextContainer = function()
            local container = { data = {} }
            function container:Add(value, label) self.data[#self.data + 1] = { value = value, label = label } end
            function container:AddCheckbox(value, label) self.data[#self.data + 1] = { value = value, label = label, checkbox = true } end
            function container:GetData() return self.data end
            return container
        end,
        RegisterInitializer = function(page, item) page.items[#page.items + 1] = item end,
        RegisterAddOnCategory = function(page) page.registered = true end,
        OpenToCategory = function(id) W.options.opened = id end,
    }
    env.CreateSettingsListSectionHeaderInitializer = function(name, tooltip) return { header = name, tooltip = tooltip } end
    -- The game's own row of a setting in its list, which a row of the addon's builds on
    -- (SettingsControlMixin, made from SettingsListElementMixin): it keeps its initializer, shows the
    -- setting's value (SetValue), is there while its shown predicates say so and switched off by the
    -- others.
    env.CreateFromMixins = function(...)
        local made = {}
        for index = 1, select("#", ...) do
            for key, value in pairs((select(index, ...))) do made[key] = value end
        end
        return made
    end
    env.SettingsListElementMixin = {
        OnLoad = function() end,
        Init = function(self, initializer) self.initializer, self.data = initializer, initializer.data end,
        Release = function(self) self.initializer, self.data = nil, nil end,
        GetElementData = function(self) return self.initializer end,
        EvaluateState = function(self) self:SetShown(self.initializer:ShouldShow()) end,
        DisplayEnabled = function(self, enabled) self._displayEnabled = enabled end,
    }
    env.SettingsControlMixin = env.CreateFromMixins(env.SettingsListElementMixin, {
        GetSetting = function(self) return self.initializer:GetSetting() end,
        IsEnabled = function(self) return self.initializer:EvaluateModifyPredicates() end,
        OnSettingValueChanged = function(self, _, value) self:SetValue(value) end,
    })
    -- A row with a button; a child of another row (parent) is drawn under it, and switched off
    -- while its predicate says no.
    env.CreateSettingsButtonInitializer = function(name, button, click, tooltip)
        return W.Row({ name = name, button = button, click = click, tooltip = tooltip })
    end
    env.GENERAL = "General"
    env.InputUtil = { IsGamepadUIEnabled = function() return W.gamepad end }
    env.GetCVarBool = function(name) return W.cvars[name] == "1" end
    -- CVars the test describes in W.cvarInfo, as the game has them: found in any case of letters,
    -- some kept for the character or the account, some not to be changed.
    local function Known(name)
        if type(name) ~= "string" then return nil end
        for known, info in pairs(W.cvarInfo) do
            if known:lower() == name:lower() then return known, info end
        end
    end
    env.C_CVar = {
        GetCVarDefault = function(name)
            local known, info = Known(name)
            return known and info.default or nil
        end,
        GetCVar = function(name)
            local known = Known(name)
            return known and (W.cvars[known] or W.cvarInfo[known].default) or nil
        end,
        GetCVarInfo = function(name)
            local known, info = Known(name)
            if not known then return nil end
            return W.cvars[known] or info.default, info.default, info.scope == "account", info.scope == "character",
                info.locked or false, info.secure or false, info.readOnly or false
        end,
        SetCVar = function(name, value)
            local known, info = Known(name)
            if not known or info.locked or info.readOnly or (info.secure and W.combat) then return false end
            W.cvars[known] = tostring(value)
            W.cvarSets = (W.cvarSets or 0) + 1
            return true
        end,
    }
    env.ConsoleGetAllCommands = function()
        local commands = { { command = "reloadui", commandType = 1, category = 2, help = "" } }
        for name, info in pairs(W.cvarInfo) do
            commands[#commands + 1] = { command = name, commandType = 0, category = info.category or 4, help = info.help or "" }
        end
        return commands
    end
    env.SetCVar = function(name, value) W.cvars[name] = tostring(value) end

    env.UnitName = function() return "Tester", "Stub" end -- a Forever name: first name and surname
    env.UnitNameUnmodified = function(unit) return env.UnitName(unit) end
    env.UnitIsPlayer = function() return true end
    env.RegionalUniqueNamesEnabled = function() return W.regionalNames end
    env.Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } }
    env.UnitClass = function() return "Mage", "MAGE" end
    env.UnitFactionGroup = function() return "Alliance" end
    env.UnitRace = function() return "Human", "Human", 1 end
    env.tContains = function(list, value)
        for _, item in ipairs(list) do if item == value then return true end end
        return false
    end
    env.UnitLevel = function() return W.level end
    env.UnitGUID = function() return "Player-70-0000ABCD" end
    env.GetRealmName = function() return "Stub Realm" end
    env.GetNormalizedRealmName = function() return "Stub" end
    env.GetBuildInfo = function() return "1.60.1", tostring(W.build or 70245) end
    -- The client's game version, as Data.lua tells it: the project, then whether a beta or a test client.
    env.WOW_PROJECT_CAMELOT = 18
    env.WOW_PROJECT_ID = W.project
    env.IsBetaBuild = function() return W.beta end
    env.IsTestBuild = function() return W.test end
    env.IsPublicTestClient = function() return W.test end
    -- Every frame there is, in the order it was made, as the game's EnumerateFrames walks them.
    env.EnumerateFrames = function(after)
        local found = after == nil
        for _, widget in ipairs(W.frames) do
            if found and (widget._kind == "Frame" or widget._kind == "Button" or widget._kind == "CheckButton") then return widget end
            if widget == after then found = true end
        end
        return nil
    end
    env.InCombatLockdown = function() return W.combat end
    env.IsMouseButtonDown = function() return false end
    -- You, as Core.Rest reads you: alone, alive, whole, not in a fight unless W.Combat says so. A test sets its own.
    env.UnitAffectingCombat = function() return W.combat end
    env.IsInGroup = function() return false end
    env.UnitIsDeadOrGhost = function() return false end
    env.UnitIsGhost = function() return false end
    env.UnitHealth, env.UnitHealthMax = function() return 100 end, function() return 100 end
    env.UnitPowerType = function() return 0, "MANA" end
    local function Mana(_, kind) return (kind or 0) == 0 and 100 or 0 end
    env.UnitPower, env.UnitPowerMax = Mana, Mana
    env.IsShiftKeyDown = function() return false end
    env.debugprofilestop = function() return W.ms end
    env.GetFramerate = function() return W.fps end
    -- The game's restrictions on addons (combat, an encounter, a map, chat, ...): a test sets W.restrictions
    -- and fires ADDON_RESTRICTION_STATE_CHANGED (type, state).
    env.C_RestrictedActions = { IsAddOnRestrictionActive = function(kind) return W.restrictions[kind] or false end }
    env.GetCursorPosition = function() return W.cursorX or 0, W.cursorY or 0 end -- a test moves the mouse by W.cursorX, W.cursorY
    env.GetPhysicalScreenSize = function() return 3840, 2160 end
    env.SetCursor = function(cursor) W.cursorArt = cursor end
    env.GetShapeshiftForm = function() return 0 end
    env.GetShapeshiftFormInfo = function() return nil end
    env.GetMacroIndexByName = function(name) return W.macros[name] or 0 end

    env.Enum = {
        PowerType = { Mana = 0, Rage = 1, Focus = 2, Energy = 3, ComboPoints = 4, Runes = 5, RunicPower = 6, Essence = 19 },
        ConsoleCommandType = { Cvar = 0, Command = 1, Macro = 2, Script = 3 },
        ConsoleCategory = { Debug = 0, Graphics = 1, Console = 2, Combat = 3, Game = 4, Default = 5, Net = 6, Sound = 7 },
        SpellBookSpellBank = { Player = 0, Pet = 1 },
        SpellBookItemType = { None = 0, Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 },
        SpellBookSkillLineIndex = { General = 1, Class = 2 },
        TrainerType = { General = 0, TalentsObsolete = 1, Tradeskills = 2, Pet = 3 },
    }

    -- The trainer window. Like the game, it only lists the rows its filters let through.
    local function Rows()
        local rows = {}
        for _, row in ipairs(W.trainer or {}) do
            if W.trainerFilter[row.kind] then rows[#rows + 1] = row end
        end
        return rows
    end
    env.IsTradeskillTrainer = function() return W.tradeskill or false end
    env.GetTrainerServiceTypeFilter = function(filter) return W.trainerFilter[filter] end
    env.SetTrainerServiceTypeFilter = function(filter, on) W.trainerFilter[filter] = on and true or false end
    env.GetNumTrainerServices = function() return #Rows() end
    env.GetTrainerServiceInfo = function(index)
        local row = Rows()[index]
        if row then return row.name, row.kind, row.icon, row.level, row.sub or "", row.category end
    end
    env.GetTrainerServiceCost = function(index)
        local row = Rows()[index]
        return row and row.cost or 0, false
    end
    env.C_Trainer = { GetTrainerType = function() return W.trainerType or 0 end }
    env.C_TooltipInfo = { GetTrainerService = function(index)
        local row = Rows()[index]
        return row and row.id and { type = 1, id = row.id } or nil
    end }

    -- The talent tree: one tree, one node per talent, each node one entry.
    env.C_ClassTalents = { GetActiveConfigID = function() return 1 end }
    env.C_Traits = {
        GetConfigInfo = function() return { treeIDs = { 10 } } end,
        GetTreeNodes = function()
            local nodes = {}
            for index = 1, #W.traits do nodes[index] = index end
            return nodes
        end,
        GetNodeInfo = function(_, nodeID) return { entryIDs = { nodeID } } end,
        GetEntryInfo = function(_, entryID) return { definitionID = entryID } end,
        GetDefinitionInfo = function(definitionID) return { spellID = W.traits[definitionID] } end,
    }

    -- Action slots and the cursor
    env.GetCursorInfo = function() return W.cursor and W.cursor.kind or nil end
    env.ClearCursor = function() W.cursor = nil end
    env.PickupAction = function(slot)
        assert(not W.combat, "PickupAction in combat")
        W.cursor = W.actions[slot]
        W.actions[slot] = nil
        SlotChanged(slot)
    end
    env.PlaceAction = function(slot)
        assert(not W.combat, "PlaceAction in combat")
        if not W.cursor then return end
        local old = W.actions[slot]
        W.actions[slot] = W.cursor
        W.cursor = old
        SlotChanged(slot)
    end
    env.PickupMacro = function(index)
        for name, macroIndex in pairs(W.macros) do
            if macroIndex == index then W.cursor = { kind = "macro", id = index, text = name } end
        end
    end
    env.GetActionInfo = function(slot)
        local action = W.actions[slot]
        if action then return action.kind, action.id end
    end
    env.C_ActionBar = {
        HasAction = function(slot) return W.actions[slot] ~= nil end,
        GetActionTexture = function(slot) return W.actions[slot] and 4000 + slot or nil end,
        GetActionText = function(slot) return W.actions[slot] and W.actions[slot].text or nil end,
    }

    -- Spells
    env.C_Spell = {
        DoesSpellExist = function(id) return W.spells[id] ~= nil end,
        GetSpellName = function(id) return W.spells[id] and W.spells[id].name or nil end,
        GetSpellTexture = function(id) return W.spells[id] and (W.spells[id].icon or 1000 + id) or nil end,
        IsSpellPassive = function(id) return W.spells[id] and W.spells[id].passive or false end,
        GetSpellSubtext = function(id) return W.spells[id] and W.spells[id].sub or nil end,
        IsSpellDataCached = function(id) return W.spells[id] ~= nil and not W.spells[id].late end,
        RequestLoadSpellData = function() end,
        PickupSpell = function(id) if IsLearned(id) then W.cursor = { kind = "spell", id = id } end end,
        GetSpellLink = function(id) return W.spells[id] and ("|Hspell:" .. id .. "|h[" .. W.spells[id].name .. "]|h") or nil end,
    }
    env.C_SpellBook = {
        GetNumSpellBookSkillLines = function() return #W.lines end,
        GetSpellBookSkillLineInfo = function(line)
            local _, offsets, counts = BookRows()
            if not W.lines[line] then return nil end
            return { name = W.lines[line], itemIndexOffset = offsets[line], numSpellBookItems = counts[line] }
        end,
        GetSpellBookItemInfo = function(index)
            local row = BookRows()[index]
            if not row then return nil end
            local spell = W.spells[row.id]
            return { spellID = row.id, actionID = row.id, name = spell.name, subName = spell.sub, iconID = 1000 + row.id,
                     isPassive = spell.passive or false, isOffSpec = false, itemType = 1 }
        end,
        IsSpellBookItemLowRank = function(index) return BookRows()[index].low or false end,
        IsSpellKnown = function(id) return IsLearned(id) end,
        GetSkillLineIndexByID = function(skillLine) return W.skillLines[skillLine] end,
        FindSpellBookSlotForSpell = function(id)
            if W.slotOfSpell[id] then return W.slotOfSpell[id], 0 end
        end,
    }

    -- Items
    env.C_Item = {
        DoesItemExistByID = function(id) return W.items[id] ~= nil end,
        GetItemNameByID = function(id) return W.items[id] and W.items[id].name or nil end,
        GetItemIconByID = function(id) return W.items[id] and 2000 + id or nil end,
        GetItemCount = function(id) return W.items[id] and W.items[id].count or 0 end,
        RequestLoadItemDataByID = function() end,
        PickupItem = function(id) W.cursor = { kind = "item", id = id } end,
    }

    -- Reading a global that does not exist is an error here, unless the addon is
    -- allowed to probe for it (optional functions, its own saved settings, other addons).
    local optional = {
        issecretvalue = true, HasAction = true, GetActionTexture = true, GetActionText = true,
        SaneUIDB = true, SaneUICharDB = true, MinimalSliderWithSteppersMixin = true, debugstack = true,
        strcmputf8i = true, C_TradeSkillUI = true, PlayerSpellsFrame = true,
        SPELLBOOK_TRAINABLE = true, SPELLBOOK_AVAILABLE_AT = true, SPELL_PASSIVE = true,
        SPELLBOOK_FONT_COLOR = true, SPELLBOOK_UNLEARNED_TINT_COLOR = true, SHOW_ALL_SPELL_RANKS = true,
        C_CurrencyInfo = true, ChatFrame_OpenChat = true, GetMouseFocus = true,
        SettingsPanel = true, HOME = true, C_Map = true, GameTooltip_SetDefaultAnchor = true,
        UpdateUIPanelPositions = true,
        TooltipDataProcessor = true, TooltipBackdropTemplateMixin = true, UnitTokenFromGUID = true,
        ItemRefTooltip = true, ShoppingTooltip1 = true, ShoppingTooltip2 = true,
    }
    setmetatable(env, { __index = function(_, key)
        if optional[key] or W.hidden[key] or (type(key) == "string" and key:match("Button%d+$")) then return nil end
        error("the addon read an undefined global: " .. tostring(key), 2)
    end })
end

-- The stand-in's own doors tried: a secret value, a ticker (W.Wait moves the clock five seconds: call it before a
-- test's own timers matter), a protected frame in combat (W.combat set and cleared; the fight's events fired to a
-- frame of its own only), a widget's methods, a bar's value, the walk of OnShow; and Core.Plain and Core.Ask on a
-- secret when Core is loaded. The first thing wrong is an error.
function W.SelfCheck(env)
    env = env or _G
    local secret = W.Secret()
    assert(env.issecretvalue(secret) and not env.canaccessvalue(secret) and not env.issecretvalue(1) and env.canaccessvalue(1),
        "issecretvalue and canaccessvalue know a secret")
    assert(not pcall(function() return secret + 1 end) and not pcall(function() return secret < 2 end)
        and not pcall(function() return #secret end) and not pcall(function() return secret.x end)
        and not pcall(function() secret() end), "a secret errors in arithmetic, a comparison, #, indexing, a call")
    local ok, joined = pcall(function() return "hp " .. secret end)
    assert(ok and env.issecretvalue(joined), "concatenated: another secret")
    local ticks = 0
    local ticker = env.C_Timer.NewTicker(1, function(t) ticks = ticks + 1; if ticks == 2 then t:Cancel() end end)
    local once = 0
    env.C_Timer.NewTimer(1, function() once = once + 1 end)
    W.Wait(5)
    assert(ticks == 2 and once == 1 and ticker:IsCancelled() and W.tickers[#W.tickers - 1] == ticker,
        "a ticker runs until cancelled, a timer once, both in W.tickers")
    local holder = env.CreateFrame("Frame", nil, env.UIParent)
    local button = env.CreateFrame("Button", nil, holder, "SecureActionButtonTemplate")
    local plain = env.CreateFrame("Frame", nil, env.UIParent)
    local combat = W.combat
    W.combat = true
    assert(not pcall(button.Hide, button) and pcall(plain.Hide, plain) and button:IsProtected() and not plain:IsProtected(),
        "in combat a protected frame refuses, a plain one does not")
    local protected, explicitly = holder:IsProtected()
    assert(protected and not explicitly and select(2, button:IsProtected()) and not pcall(holder.SetWidth, holder, 1)
        and pcall(plain.SetWidth, plain, 1), "a frame holding a protected one is protected too, not explicitly, and refuses a size")
    local lockedInside
    W.AsGame(function() holder:Hide(); lockedInside = env.InCombatLockdown() end)
    assert(not holder:IsShown() and lockedInside and not W.lifted, "the game's own code hides it in the fight, the lock on")
    W.combat = combat
    local listeners, told = W.listeners, {}
    W.listeners = {}
    local ear = env.CreateFrame("Frame")
    ear:RegisterEvent("PLAYER_REGEN_DISABLED")
    ear:RegisterEvent("PLAYER_REGEN_ENABLED")
    ear:SetScript("OnEvent", function(_, event) told[event] = env.InCombatLockdown() end)
    W.Combat(true)
    local locked = W.combat
    W.Combat(false)
    W.listeners, W.combat = listeners, combat
    assert(told.PLAYER_REGEN_DISABLED == false and locked and told.PLAYER_REGEN_ENABLED == false,
        "the fight is told before the lock, its end after the lock is gone")
    local own, hooked = env.CreateFrame("Frame"), {}
    W.Methods(own, { Own = function() hooked[#hooked + 1] = "own" end, Lacking = false })
    env.hooksecurefunc(own, "Own", function() hooked[#hooked + 1] = "hook" end)
    env.hooksecurefunc(own, "Other", function() hooked[#hooked + 1] = "other" end)
    own:Own()
    own:Other()
    assert(own.Lacking == nil and not pcall(env.hooksecurefunc, own, "Lacking", print) and type(own.Other) == "function"
        and table.concat(hooked, " ") == "own hook other", "a declared method and the catch-all are hooked, a lack is nil and refused")
    local bar = env.CreateFrame("StatusBar")
    bar:SetMinMaxValues(0, 10)
    bar:SetValue(secret)
    assert(env.issecretvalue(bar:GetValue()) and select(2, bar:GetMinMaxValues()) == 10, "a bar keeps what it was given")
    local parent = env.CreateFrame("Frame")
    local first, second = env.CreateFrame("Frame", nil, parent), env.CreateFrame("Frame", nil, parent)
    local shows = 0
    second:Hide()
    second:SetScript("OnShow", function() shows = shows + 1 end)
    first:SetScript("OnShow", function() second:Show() end)
    parent:Hide()
    parent:Show()
    assert(shows == 1, "a frame shown by its sibling's OnShow has its own once")
    local sane = rawget(env, "SaneUI")
    if sane and sane.Core and sane.Core.Plain then
        assert(sane.Core.Plain(secret) == nil and sane.Core.Plain(1) == 1, "Core.Plain hides a secret")
        local first, second = sane.Core.Ask(function() return secret, 2 end)
        assert(first == nil and second == 2, "Core.Ask answers nil for a secret, the plain answers beside it")
    end
    return true
end

return W
