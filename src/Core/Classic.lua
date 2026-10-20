local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Classic
--  The game's own windows that Sane UI's windows stand for (a window's option
--  classic, Window.lua), both ways:
--    - the dropdown Classic windows on a full window (Edge.lua): the game's
--      windows of every module, each module's under its name, this window's
--      first. One chosen, the full window goes back and the game's comes; a
--      kept choice is a checkbox, chosen again while ticked: ours again.
--    - the button Sane UI on each of those game windows, beside its close
--      button: the game's window goes and ours comes instead (filling the
--      screen where the entry says so); a kept choice is ours again.
--
--  Our code neither shows nor hides the game's panels (the friends list, the
--  map, the spellbook, the character sheet) where that was not tried in the
--  game (Doc/guides/addon-standards.md, Known traps). So on a panel the button
--  is a secure one that clicks the game's own close button: the game closes
--  its window as its own code, and ours comes after (Window.Beside). And an
--  entry that may not open the game's panel says which key opens it
--  (Classic.Press).
--
--  An entry of a window's list:
--      { text = "Friends list",
--        show = function() end,          -- the game's window instead of ours
--        checked = function() end,       -- a kept choice: ticked while the game's is the one kept
--        back = function() end,          -- with checked: ours is the one again
--        frame = "FriendsFrame",         -- the game's window, for the button on it: its name, a list of
--                                        -- names, or a function giving the frame
--        addon = "Blizzard_...",         -- the addon that window comes in, when the game loads it on demand
--        full = true,                    -- the button: ours fills the screen
--        ours = function() end,          -- the button: how ours is shown (without: the window shown, its
--                                        -- game's own given up, Window:Native(false))
--        plain = true,                   -- the game's window is no panel (the bags, the minimap): the
--                                        -- button is a plain one, and the game's is hidden by our code
--        hide = function(frame) end,     -- with plain: how the game's goes (without: Hide)
--        anchor = function(button, frame) end, -- the button elsewhere than beside the close button
--        ready = function() end }        -- the button is there only while true (the module runs)
--  Two entries of one game window share its button, the first one's.
-------------------------------------------------------------------------------
local Classic = {}
Core.Classic = Classic

Classic.TEXT = {
    key = "The game's %s opens with its key, %s.",
    noKey = "The game's %s opens from its button in the micro menu.",
}

-- A window's entries, as its option gives them; nil: none.
function Classic.List(window)
    local list = window.options.classic
    if type(list) == "function" then list = Core.Safe("classic window", list) end
    return type(list) == "table" and #list > 0 and list or nil
end

-- Every window with entries, this one first, the others in the order they were made.
function Classic.Windows(first)
    local found = {}
    if first and Classic.List(first) then found[1] = first end
    for _, window in ipairs(Core.Window.All()) do
        if window ~= first and Classic.List(window) then found[#found + 1] = window end
    end
    return found
end

-- Whether an entry is a kept choice that is ticked now.
function Classic.Ticked(entry)
    return entry.checked and Core.Safe("classic window", entry.checked) and true or false
end

-- Says which key opens a panel of the game's that our code may not open (binding: its key binding's name,
-- TOGGLESPELLBOOK). what: the window's name.
function Classic.Press(what, binding)
    local find, name = rawget(_G, "GetBindingKey"), rawget(_G, "GetBindingText")
    local key = find and find(binding)
    local text = key and (name and name(key) or key)
    Core.Print(text and Classic.TEXT.key:format(what, text) or Classic.TEXT.noKey:format(what))
end

-- One chosen from the dropdown of a full window (edge): a kept choice ticked, ours again and the window stays
-- as it is; else the full window goes back and the game's comes. Then the game's window has its button.
function Classic.Pick(edge, window, entry)
    if Classic.Ticked(entry) then
        if entry.back then Core.Safe("classic window", entry.back) end
        return
    end
    edge:Fill(false)
    if window.edge and window.edge ~= edge then window.edge:Fill(false) end
    Core.Safe("classic window", entry.show)
    Classic.Attach(window)
end

-- The dropdown's list: each window's entries under its name.
function Classic.Menu(edge, root)
    for _, window in ipairs(Classic.Windows(edge.window)) do
        if window.options.title then root:CreateTitle(window.options.title) end
        for _, entry in ipairs(Classic.List(window) or {}) do
            local chosen = Core.Guard("classic window", function() Classic.Pick(edge, window, entry) end)
            if entry.checked then
                root:CreateCheckbox(entry.text, Core.Guard("classic window", function() return Classic.Ticked(entry) end), chosen)
            else
                root:CreateButton(entry.text, chosen)
            end
        end
    end
end

-------------------------------------------------------------------------------
--  The button Sane UI on the game's windows
-------------------------------------------------------------------------------
local buttons = setmetatable({}, { __mode = "k" }) -- [the game's frame] = its button

-- The game's frames of an entry, those that are there now.
local function Frames(entry)
    local given, found = entry.frame, {}
    if type(given) == "function" then given = Core.Safe("classic window", given) end
    if type(given) ~= "table" or type(given.GetObjectType) == "function" then given = { given } end
    for _, item in ipairs(given) do
        local frame = type(item) == "string" and rawget(_G, item) or item
        if type(frame) == "table" and type(frame.GetObjectType) == "function" then found[#found + 1] = frame end
    end
    return found
end

local function Ready(entry)
    return not entry.ready or Core.Safe("classic window", entry.ready) and true or false
end

-- The button pressed: a kept choice is ours again, and ours comes (full where the entry says). A panel of the
-- game's is gone already (the button clicked its close button); a plain window is hidden here. Ours not in a
-- fight while it may not be shown then (Window:Locked).
local function Ours(window, entry, game, secure)
    if not secure then
        if entry.hide then entry.hide(game) else game:Hide() end
    end
    if InCombatLockdown() and window:Locked() then return end
    if Classic.Ticked(entry) and entry.back then entry.back() end
    if entry.ours then
        entry.ours()
    else
        if window.options.native then window:Native(false) end
        window.frame:Show()
    end
    if entry.full and window.edge and not window.edge.full then window.edge:Fill(true) end
end

-- Shown while the game's window is and the entry is ready; a secure one is shown, hidden and raised out of a
-- fight only (in a fight it waits for the fight's end).
local pending = {} -- [button] = { game, entry }
local function Follow(button, game, entry)
    if button.secure and InCombatLockdown() then
        pending[button] = { game, entry }
        return
    end
    pending[button] = nil
    local on = game:IsVisible() and Ready(entry)
    if on and button.over then button:SetFrameLevel(button.over:GetFrameLevel() + 2) end
    button:SetShown(on and true or false)
end

local waiting = false -- a fight held the buttons back: the fight's end puts them on
Core.On("PLAYER_REGEN_ENABLED", function()
    for button, held in pairs(pending) do Core.Safe("classic window", Follow, button, held[1], held[2]) end
    if waiting then
        waiting = false
        for _, window in ipairs(Core.Window.All()) do Core.Safe("classic window", Classic.Attach, window) end
    end
end)

-- Puts the button onto each of the window's game windows that is there and has none yet, out of a fight; one
-- loaded on demand gets it once its addon is loaded.
function Classic.Attach(window)
    if InCombatLockdown() then
        waiting = true
        return
    end
    for _, entry in ipairs(Classic.List(window) or {}) do
        if entry.frame then
            for _, game in ipairs(Frames(entry)) do
                if not buttons[game] then
                    local secure = not entry.plain and Core.Window.CloseOf(game) ~= nil
                    local anchor = entry.anchor and function(button) entry.anchor(button, game) end
                    local button = Core.Window.Beside(game, function() Ours(window, entry, game, secure) end, anchor, secure)
                    button.secure = secure
                    buttons[game] = button
                    Follow(button, game, entry)
                    local follow = Core.Guard("classic window", function() Follow(button, game, entry) end)
                    game:HookScript("OnShow", follow)
                    game:HookScript("OnHide", follow)
                end
            end
            local util = rawget(_G, "EventUtil")
            if entry.addon and not entry.waiting and util and util.ContinueOnAddOnLoaded then
                entry.waiting = true
                util.ContinueOnAddOnLoaded(entry.addon, Core.Guard("classic window", function() Classic.Attach(window) end))
            end
        end
    end
end

-- The button on a game's window, once it has one.
function Classic.Button(game) return buttons[game] end
