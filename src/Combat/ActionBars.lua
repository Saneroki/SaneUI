local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - ActionBars
--  The game's action bars, clean: no border, decoration or background of
--  theirs left, only the buttons that hold something, each its icon alone,
--  square, cut free of the edge its picture is drawn with.
--
--  The bars stay the game's own, placed and set up in its Edit Mode, its
--  buttons its secure ones; only how they look changes, by calls on what they
--  show (alpha, a texture's look), nothing of theirs written:
--    the bars     the main bar's frame, its end caps (gryphons, wyverns), the
--                 dividers between buttons: out of sight; its page number and
--                 arrows stay, to see and change which bar shows
--    a button     its frame, its slot and the slot's background, the green
--                 border of an equipped item: out of sight; the icon unmasked
--                 and cropped (Bars.CROP), the cooldown's swipe over the whole
--                 icon; the mouse over it, a press and an active action
--                 (an attack, a stance) a flat wash instead of the game's
--                 framed ones
--    empty        a button that holds nothing is out of sight (its alpha),
--                 though its key binding has a key; while something is dragged
--                 (the game's ACTIONBAR_SHOWGRID) and in Edit Mode every
--                 button shows, an empty one as a dark square to drop on
--  The reservations of the module Abilities stay on their empty buttons:
--  they hang on the bar, not on the button.
--
--  Out of sight at rest (Core.Rest, the setting Hide the action bars at rest;
--  Saneroki, 2026-11-01), the bars as one set, by their alpha: the mouse on any
--  bar shows them all, their buttons take it as ever and their keys work. They
--  stay in sight in a vehicle (its actions stand on them), on the full screen
--  (BarsWindow.lua, Seated) and while something is dragged or your keys are set
--  (the game's Quick Keybind mode), whatever goes on.
--  This goes for how they look or as the game has them alike.
--
--  Hooks after the game's own (each button's Update and UpdateButtonArt, a
--  bar's Update, UpdateState and UpdateDividers) keep the look as the game
--  changes them. Off (the setting) or standing down, everything is as the game
--  had it again.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Bars = {}
ns.ActionBars = Bars

-- The game's bars by their globals: the main bar, the extra bars, the stance, pet and possess bars.
Bars.BARS = { "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
              "MultiBar5", "MultiBar6", "MultiBar7", "StanceBar", "PetActionBar", "PossessActionBar" }
Bars.SEATS = { "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
               "MultiBar5", "MultiBar6", "MultiBar7" } -- those that stand on the full screen (BarsWindow.lua)
Bars.ART = { "BorderArt", "EndCaps" } -- a bar's own art (the main bar's page number and arrows stay)
Bars.BUTTON_ART = { "NormalTexture", "SlotArt", "SlotBackground", "Border" } -- a button's own art
Bars.COOLDOWNS = { "cooldown", "lossOfControlCooldown", "chargeCooldown" }    -- over the whole icon
Bars.DIVIDERS = { "HorizontalDividersPool", "VerticalDividersPool" }
Bars.CROP = { 0.07, 0.93, 0.07, 0.93 } -- the icon's picture without the edge it is drawn with
-- The feedback, flat: the button's texture of each state, its colour and blend.
Bars.LOOKS = {
    { get = "GetHighlightTexture", colour = { 1, 1, 1, 0.18 }, blend = "ADD" },  -- the mouse over it
    { get = "GetPushedTexture", colour = { 0, 0, 0, 0.45 }, blend = "BLEND" },   -- pressed
    { get = "GetCheckedTexture", colour = { 1, 0.82, 0, 0.32 }, blend = "ADD" }, -- active, in the game's gold
}
Bars.SLOT = { 0, 0, 0, 0.4 } -- an empty button while something is dragged, and in Edit Mode

local HasAction = (rawget(_G, "C_ActionBar") and C_ActionBar.HasAction) or rawget(_G, "HasAction")

local on = false      -- the bars are clean now
local dragging = false -- the game shows its grid: something is dragged onto the bars
local binding = false  -- the game's Quick Keybind mode: every button shows, to take a key
local seated = false   -- the bars stand on the full screen: every button shows, to drop something on
local rest            -- the bars as one set, out of sight at rest (Core.Rest)
local bars = {}       -- the game's bars found, each once
local dressed = {}    -- [the game's button] = what we changed on it: its lends, the looks it had
local slots = setmetatable({}, { __mode = "k" })  -- [the game's button] = our dark square on it, once made
local hooked = setmetatable({}, { __mode = "k" }) -- [the game's frame] = its hooks are placed (they stay)
local barLends = {}   -- the lends of the bars' own art

-- Whether a button holds something: its action, as the game says; a button without one (pet, stance) by its icon.
local function Holds(button)
    local action = rawget(button, "action")
    if type(action) == "number" then
        local has = Core.Ask(HasAction, action)
        if has ~= nil then return has == true end
    end
    local icon = rawget(button, "icon")
    return type(icon) == "table" and Plain(icon:IsShown()) == true
end

-- A button shown or not: an empty one only while something is dragged or in Edit Mode, then on its dark slot.
local function Empty(button)
    local own = dressed[button]
    if not on or not own then return end
    local showing = dragging or binding or seated or Core.EditMode.active
    slots[button]:SetShown(showing)
    button:SetAlpha((showing or Holds(button)) and 1 or 0)
end

-- The feedback textures flat; each one's look as the game had it noted first (again where the game set it anew).
local function Flat(button, own)
    for index, look in ipairs(Bars.LOOKS) do
        local get = button[look.get]
        local texture = type(get) == "function" and get(button)
        if type(texture) == "table" then
            local was = own.looks[index]
            if not was or was.texture ~= texture or was.renewed then
                own.looks[index] = { texture = texture, atlas = texture:GetAtlas(), file = texture:GetTexture(),
                                     blend = texture:GetBlendMode() }
            end
            local colour = look.colour
            texture:SetColorTexture(colour[1], colour[2], colour[3], colour[4])
            texture:SetBlendMode(look.blend)
        end
    end
end

-- The game set the button's art anew (its frame and pressed look, for a bar with or without its art): flat again.
local function Renewed(button)
    local own = dressed[button]
    if not on or not own then return end
    if own.looks[2] then own.looks[2].renewed = true end
    Flat(button, own)
end
local OnRenewed = ns.Guard(Renewed)
local OnUpdated = ns.Guard(Empty)

local function Lend(own, frame, change, ...)
    local lend = Core.Lend(frame)
    lend[change](lend, ...)
    own.lends[#own.lends + 1] = lend
end

local function Dress(button)
    local own = dressed[button]
    if own then return end
    own = { lends = {}, looks = {} }
    dressed[button] = own
    if not hooked[button] then
        hooked[button] = true
        if type(button.Update) == "function" then hooksecurefunc(button, "Update", OnUpdated) end
        if type(button.UpdateButtonArt) == "function" then hooksecurefunc(button, "UpdateButtonArt", OnRenewed) end
    end
    if not slots[button] then
        local slot = button:CreateTexture(nil, "BACKGROUND", nil, -8)
        slot:SetAllPoints(button)
        slot:SetColorTexture(Bars.SLOT[1], Bars.SLOT[2], Bars.SLOT[3], Bars.SLOT[4])
        slots[button] = slot
    end
    slots[button]:Hide()
    for _, key in ipairs(Bars.BUTTON_ART) do
        local part = rawget(button, key)
        if type(part) == "table" and part.SetAlpha then Lend(own, part, "SetAlpha", 0) end
    end
    local icon, mask = rawget(button, "icon"), rawget(button, "IconMask")
    if type(icon) == "table" then
        if type(mask) == "table" and icon.RemoveMaskTexture then
            icon:RemoveMaskTexture(mask)
            own.mask = mask
        end
        icon:SetTexCoord(Bars.CROP[1], Bars.CROP[2], Bars.CROP[3], Bars.CROP[4])
        own.icon = icon
        for _, key in ipairs(Bars.COOLDOWNS) do
            local cooldown = rawget(button, key)
            if type(cooldown) == "table" and cooldown.SetAllPoints then
                Lend(own, cooldown, "SetPoints", function(frame)
                    frame:ClearAllPoints()
                    frame:SetAllPoints(icon)
                end)
            end
        end
    end
    Flat(button, own)
    Empty(button)
end

-- The button as the game had it.
local function Undress(button)
    local own = dressed[button]
    if not own then return end
    dressed[button] = nil
    slots[button]:Hide()
    for index = #own.lends, 1, -1 do ns.Safe("action bars", own.lends[index].Return, own.lends[index]) end
    if own.icon then
        own.icon:SetTexCoord(0, 1, 0, 1)
        if own.mask then own.icon:AddMaskTexture(own.mask) end
    end
    for _, was in pairs(own.looks) do
        if was.atlas then
            was.texture:SetAtlas(was.atlas)
        elseif was.file then
            was.texture:SetTexture(was.file)
        end
        was.texture:SetBlendMode(was.blend or "BLEND")
    end
    button:SetAlpha(1)
end

-- The dividers a bar shows between its buttons: out of sight while clean. Each one ever put out of sight is
-- kept: the game's pool hands them out again as they are.
local hidden = setmetatable({}, { __mode = "k" })
local function Dividers(bar)
    for _, key in ipairs(Bars.DIVIDERS) do
        local pool = rawget(bar, key)
        if on and type(pool) == "table" and type(pool.EnumerateActive) == "function" then
            for divider in pool:EnumerateActive() do
                divider:SetAlpha(0)
                hidden[divider] = true
            end
        end
    end
end
local OnDividers = ns.Guard(function(bar) if on then Dividers(bar) end end)

-- Every button of a bar looked at again (the bar updated its pet actions, its stances).
local OnBar = ns.Guard(function(bar)
    if not on then return end
    for _, button in pairs(rawget(bar, "actionButtons") or {}) do Empty(button) end
end)

-- The game's bars this game has, each once.
local function Find()
    wipe(bars)
    local seen = {}
    for _, name in ipairs(Bars.BARS) do
        local bar = rawget(_G, name)
        if type(bar) == "table" and not seen[bar] then
            seen[bar] = true
            bars[#bars + 1] = bar
        end
    end
    return bars
end

local function Clean()
    on = true
    for _, bar in ipairs(Find()) do
        if not hooked[bar] then
            hooked[bar] = true
            if type(bar.UpdateDividers) == "function" then hooksecurefunc(bar, "UpdateDividers", OnDividers) end
            for _, method in ipairs({ "Update", "UpdateState" }) do
                if type(bar[method]) == "function" then hooksecurefunc(bar, method, OnBar) end
            end
        end
        for _, key in ipairs(Bars.ART) do
            local part = rawget(bar, key)
            if type(part) == "table" and part.SetAlpha then
                local lend = Core.Lend(part)
                lend:SetAlpha(0)
                barLends[#barLends + 1] = lend
            end
        end
        Dividers(bar)
        for _, button in pairs(rawget(bar, "actionButtons") or {}) do Dress(button) end
    end
end

-- Everything as the game had it (in a fight too: what may not change then is given back after it, Core.Lend).
local function Restore()
    on = false
    for button in pairs(dressed) do Undress(button) end
    for index = #barLends, 1, -1 do ns.Safe("action bars", barLends[index].Return, barLends[index]) end
    wipe(barLends)
    for divider in pairs(hidden) do divider:SetAlpha(1) end
    wipe(hidden)
end

-- Clean or as the game has them, as the setting says; out of a fight (the buttons' cooldowns are placed only then).
local function Apply()
    local want = not ns.off and (ns.options or {}).cleanBars ~= false
    if want ~= on then
        if want then Clean() else Restore() end
    end
    rest:Switch(not ns.off and (ns.options or {}).barsRest ~= false)
end

function Bars.Apply()
    Core.AfterCombat("action bars", Apply)
end

-- Something is dragged onto the bars, or no longer; Edit Mode opened or closed: every empty button anew.
local function Grid(shown)
    dragging = shown
    for button in pairs(dressed) do Empty(button) end
    rest:Look()
end

-- A vehicle's actions stand on the bars, and without one of its own (no art of its bar) on them alone.
local function Ridden()
    local actions = rawget(_G, "C_ActionBar")
    return actions and (Core.Ask(actions.HasVehicleActionBar) or Core.Ask(actions.HasOverrideActionBar)) or false
end

-- What keeps the bars in sight at rest.
local function Held()
    return dragging or binding or seated or Ridden()
end

-- The bars as one set: any of them, or a button on one, under the mouse shows them all.
local function Rests()
    rest = Core.Rest.New({ label = "action bars", frames = { unpack(Find()) }, hold = Held })
    for _, bar in ipairs(rest.frames) do
        rest:Hot(bar)
        for _, button in pairs(rawget(bar, "actionButtons") or {}) do rest:Door(button) end
    end
    local registry = rawget(_G, "EventRegistry")
    if not registry or type(registry.RegisterCallback) ~= "function" then return end
    for event, shown in pairs({ QuickKeybindModeEnabled = true, QuickKeybindModeDisabled = false }) do
        registry:RegisterCallback("QuickKeybindFrame." .. event, ns.Guard(function()
            binding = shown
            Grid(dragging)
        end), Bars)
    end
end

-- The bars on the full screen, or no longer.
function Bars.Seated(on)
    seated = on and true or false
    Grid(dragging)
end

-- The bars that stand on the full screen, as far as this game has them.
function Bars.Frames()
    local frames = {}
    for _, name in ipairs(Bars.SEATS) do
        local bar = rawget(_G, name)
        if type(bar) == "table" then frames[#frames + 1] = bar end
    end
    return frames
end

function Bars.Start()
    Rests()
    ns.On("ACTIONBAR_SHOWGRID", function() Grid(true) end)
    ns.On("ACTIONBAR_HIDEGRID", function() Grid(false) end)
    Core.EditMode.Watch(ns.Guard(function() Grid(dragging) end))
    -- Buttons that hold something now or no longer, without an update of their own the hooks would hear.
    ns.On("PLAYER_ENTERING_WORLD", function() Grid(dragging) end)
    local look = function() rest:Look() end
    ns.On("UPDATE_VEHICLE_ACTIONBAR", look)
    ns.On("UPDATE_OVERRIDE_ACTIONBAR", look)
    Bars.Apply()
end

-- Standing down: the bars as the game has them, at once.
function Bars.GiveBack()
    Restore()
    if rest then rest:Switch(false) end
end

-- For the test: whether the bars are clean now; their set.
function Bars.Clean()
    return on
end

function Bars.Rest()
    return rest
end
