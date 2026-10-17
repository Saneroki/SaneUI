-- A small stand-in for the WoW client, so the addon's logic can run under plain Lua 5.1.
-- It models only what Sane UI touches: action slots, the cursor, the spellbook, bags,
-- timers, events, the options and "frames" that accept any widget call.
-- Used by the tests next to it (core.lua, spellbook.lua, tooltips.lua, social.lua). Not part of the addon.

local W = {}

W.clock = 100
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
W.cvars = {}
W.level = 1
W.printed = {}
W.frames = {}
W.timers = {}
W.popups = {}
W.menus = {}
W.links = {}              -- what was sent to the chat line
W.errors = {}             -- what the red text in the middle of the screen said
W.foci = {}               -- frames "under the mouse"
W.loaded = {}             -- [addon name] = true
W.onDemand = {}           -- [addon name] = function that reads it, for an addon that is loaded when asked for
W.slotOfSpell = {}        -- [spell ID] = spellbook slot, for the game's "go to this spell"
W.gamepad = false         -- a controller is in use
W.templates = {}          -- [frame template] = function(widget) that gives it its parts
W.cvarInfo = {}           -- [CVar name] = { default, scope = "character" | "account" | nil (the computer),
                          -- locked, secure, readOnly, category, help }; its value is in W.cvars
W.options = { pages = {} } -- the pages the addon put into the game's options (a page under another one has
                           -- .parent); opened = the page on show
W.caught = nil            -- set to a list to collect the errors of event handlers instead of stopping
W.ms = 0                  -- the client's precise clock in milliseconds (debugprofilestop), moved by the test
W.fps = 60                -- the frame rate (GetFramerate)
W.restrictions = {}       -- [Enum.AddOnRestrictionType] = true while the game restricts addons so
W.addons = {}             -- the addon list: { name, title, notes, loadable, reason, enabled (0 or 2),
                          -- metadata = { [field] = text } }; W.AddPack puts a compiled pack in it
W.fileErrors = {}         -- the errors of an addon's files that LoadAddOn ran (the game shows them, goes on)
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
-- them). Anything else is an error: a file the game would load must never be skipped here unnoticed.
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
    else
        error(("%s lists a file that is neither Lua nor XML: %s"):format(addon, path))
    end
end

-- Runs every file an addon's TOC lists, in its order: each line that is not empty and not a comment
-- (the ## directives are comments too) names one.
local function LoadToc(root, addon, folder, toc, private)
    for line in io.lines(root .. "/src/" .. folder .. "/" .. toc) do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then LoadListed(root, addon, folder, line, private) end
    end
end

-- Runs every file of Core (its Sync and Settings too), in the order its TOC lists them. Its
-- ADDON_LOADED is the test's to fire.
function W.LoadCore(root)
    LoadToc(root, "SaneUI", "Core", "SaneUI.toc", {})
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

-- Puts a compiled pack (folder: its whole path, as dev/tools/data compile wrote it) into the addon list,
-- not loaded, as the game lists a load-on-demand addon: its TOC's ## lines are its metadata, and
-- LoadAddOn runs the files it lists (an error in one is kept in W.fileErrors and the next one runs, as
-- in the game), then fires ADDON_LOADED. options: name (another addon name), enabled, loadable, reason,
-- metadata (fields over the TOC's; false takes one away). Gives the list's entry.
function W.AddPack(folder, options)
    options = options or {}
    local name = options.name or folder:match("([^/]+)/*$")
    local toc = assert(io.open(folder .. "/" .. folder:match("([^/]+)/*$") .. ".toc", "r"), "no TOC in " .. folder)
    local metadata, files = {}, {}
    for line in toc:lines() do
        local field, value = line:match("^##%s*([^:]+):%s*(.-)%s*$")
        if field then
            metadata[field] = value
        elseif line:match("%S") and not line:match("^%s*#") then
            files[#files + 1] = line:match("^%s*(.-)%s*$")
        end
    end
    toc:close()
    for field, value in pairs(options.metadata or {}) do metadata[field] = value or nil end
    local addon = { name = name, title = metadata.Title or name, notes = metadata.Notes, metadata = metadata,
                    loadable = options.loadable or false, reason = options.reason or "DEMAND_LOADED",
                    enabled = options.enabled or 2 }
    W.addons[#W.addons + 1] = addon
    W.onDemand[name] = function()
        for _, file in ipairs(files) do
            local chunk, problem = loadfile(folder .. "/" .. file:gsub("\\", "/"))
            local ok = chunk and true
            if chunk then ok, problem = pcall(chunk, name, {}) end
            if not ok then W.fileErrors[#W.fileErrors + 1] = name .. "/" .. file .. ": " .. tostring(problem) end
        end
        addon.loadable, addon.reason = true, nil
    end
    return addon
end

-- Takes a pack (or any addon) out of the addon list again.
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
local function NewWidget(kind, name, parent)
    local widget = { _kind = kind, _name = name, _parent = parent, _shown = true, _scripts = {}, _events = {},
                     _points = {}, _width = 0, _height = 0, _alpha = 1 }
    setmetatable(widget, { __index = function(_, key)
        if methods[key] then return methods[key] end
        if type(key) == "string" and key:match("^%u") then return function() end end
        return nil
    end })
    W.frames[#W.frames + 1] = widget
    return widget
end
W.NewWidget = NewWidget

-- The parts of the game's templates the addon reaches for.
W.templates.UICheckButtonTemplate = function(widget) widget.Text = NewWidget("FontString", nil, widget) end
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
end

function methods:CreateTexture() return NewWidget("Texture", nil, self) end
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
function methods:SetScript(name, fn) self._scripts[name] = fn end
function methods:GetScript(name) return self._scripts[name] end
function methods:HookScript(name, fn)
    local original = self._scripts[name]
    self._scripts[name] = function(...)
        if original then original(...) end
        fn(...)
    end
end
function methods:RegisterEvent(event)
    if event == "NOT_A_REAL_EVENT" then error("unknown event") end
    self._events[event] = true
end
function methods:RegisterUnitEvent(event, ...)
    self:RegisterEvent(event)
    self._units = self._units or {}
    self._units[event] = { ... }
end
function methods:UnregisterEvent(event) self._events[event] = nil end
function methods:IsEventRegistered(event) return self._events[event] == true end
function methods:Show()
    local was = self._shown
    self._shown = true
    if not was and self._scripts.OnShow then self._scripts.OnShow(self) end
end
function methods:Hide()
    local was = self._shown
    self._shown = false
    if was and self._scripts.OnHide then self._scripts.OnHide(self) end
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
function methods:SetParent(parent) self._parent = parent end
function methods:ClearAllPoints() self._points = {} end
function methods:SetPoint(point, relativeTo, relativePoint, x, y)
    if type(relativeTo) == "number" then relativeTo, relativePoint, x, y = nil, nil, relativeTo, relativePoint end
    self._points[#self._points + 1] = { point, relativeTo, relativePoint or point, x or 0, y or 0 }
end
function methods:SetAllPoints(other) self._points = { { "TOPLEFT", other, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", other, "BOTTOMRIGHT", 0, 0 } } end
function methods:GetPoint(index)
    local point = self._points[index or 1]
    if point then return point[1], point[2], point[3], point[4], point[5] end
end
function methods:GetNumPoints() return #self._points end
function methods:SetWidth(width) self._width = width end
function methods:SetScale(scale) self._scale = scale end
function methods:GetObjectType() return self._kind end
function methods:GetScale() return self._scale or 1 end
function methods:GetSize() return self._width, self._height end
function methods:GetWidth() return self._width end
function methods:SetHeight(height) self._height = height end
function methods:GetHeight() return self._height end
function methods:SetSize(width, height) self._width, self._height = width, height end
function methods:SetAlpha(alpha) self._alpha = alpha end
function methods:GetAlpha() return self._alpha end
function methods:SetTextColor(r, g, b) self._color = { r, g, b } end
function methods:GetTextColor()
    local color = self._color or { 1, 1, 1 }
    return color[1], color[2], color[3]
end
function methods:SetOwner(owner) self._owner = owner end
function methods:GetOwner() return self._owner end
function methods:AddLine(text) self._lines = self._lines or {}; self._lines[#self._lines + 1] = text end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return 1 end

function W.Fire(event, ...)
    for _, widget in ipairs(W.frames) do
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
-- while its predicate says no.
function W.Row(row)
    function row:SetParentInitializer(parent, predicate) self.parent, self.predicate = parent, predicate end
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
    env.date = function(format) return os.date(format) end

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
    env.C_Timer = { After = function(delay, fn) W.timers[#W.timers + 1] = { at = W.clock + delay, fn = fn } end }
    env.CreateFrame = function(kind, name, parent, template)
        local widget = NewWidget(kind, name, parent)
        if name then env[name] = widget end
        if template and W.templates[template] then W.templates[template](widget) end
        return widget
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
    env.hooksecurefunc = function(a, b, c)
        local owner, name, hook = env, a, b
        if type(a) == "table" then owner, name, hook = a, b, c end
        local original = rawget(owner, name)
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
        function description:CreateTitle(text) list[#list + 1] = { title = text } end
        function description:CreateDivider() end
        function description:CreateButton(text, fn, data)
            local item = { text = text, fn = fn, data = data, sub = {} }
            list[#list + 1] = item
            local sub = Description(item.sub)
            function sub:SetEnabled(enabled) item.disabled = not enabled end
            return sub
        end
        -- A line drawn by the addon (CreateFrame): its initializers, to call with a frame.
        function description:CreateFrame()
            local item = { frame = true, inits = {} }
            list[#list + 1] = item
            return { AddInitializer = function(_, init) item.inits[#item.inits + 1] = init end }
        end
        function description:CreateRadio(text, isSelected, setSelected, data)
            list[#list + 1] = { text = text, checked = isSelected, fn = setSelected, data = data }
        end
        function description:CreateCheckbox(text, isSelected, setSelected, data)
            local item = { text = text, checked = isSelected, fn = setSelected, data = data }
            list[#list + 1] = item
            return { SetTooltip = function() end }
        end
        return description
    end
    W.Description = Description
    env.MenuUtil = { CreateContextMenu = function(owner, generator)
        local menu = {}
        generator(owner, Description(menu))
        W.menus[#W.menus + 1] = menu
    end }
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
        CreateControlTextContainer = function()
            local container = { data = {} }
            function container:Add(value, label) self.data[#self.data + 1] = { value = value, label = label } end
            function container:GetData() return self.data end
            return container
        end,
        RegisterInitializer = function(page, item) page.items[#page.items + 1] = item end,
        RegisterAddOnCategory = function(page) page.registered = true end,
        OpenToCategory = function(id) W.options.opened = id end,
    }
    env.CreateSettingsListSectionHeaderInitializer = function(name, tooltip) return { header = name, tooltip = tooltip } end
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
    env.debugprofilestop = function() return W.ms end
    env.GetFramerate = function() return W.fps end
    -- The game's restrictions on addons (combat, an encounter, a map, chat, ...): a test sets W.restrictions
    -- and fires ADDON_RESTRICTION_STATE_CHANGED (type, state).
    env.C_RestrictedActions = { IsAddOnRestrictionActive = function(kind) return W.restrictions[kind] or false end }
    env.GetCursorPosition = function() return 0, 0 end
    env.GetPhysicalScreenSize = function() return 3840, 2160 end
    env.SetCursor = function(cursor) W.cursorArt = cursor end
    env.GetShapeshiftForm = function() return 0 end
    env.GetShapeshiftFormInfo = function() return nil end
    env.GetMacroIndexByName = function(name) return W.macros[name] or 0 end

    env.Enum = {
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
        if optional[key] or (type(key) == "string" and key:match("Button%d+$")) then return nil end
        error("the addon read an undefined global: " .. tostring(key), 2)
    end })
end

return W
