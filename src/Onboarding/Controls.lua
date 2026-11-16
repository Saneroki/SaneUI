local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Onboarding - Controls
--  A step's controls: the module's own switches as its options page has them
--  (Core.Described: the switch's words, its tip, its kind), one under another:
--    a switch           a tick and its words (the words click it too)
--    a number           its words, its value at the right, the game's slider
--                       with its steppers under them (MinimalSliderWithSteppers)
--    one of a few       its words, then a round button and the words of each,
--                       side by side where three or fewer fit on a line
--    a key              its words, and a box with the keys it is bound to:
--                       a click, then the key to bind it to (Esc: none);
--                       a right click unbinds it (the game's own key
--                       bindings, saved as its key binding window saves them)
--  Each shows the value in use (Core.Settings) and sets it through Core.Set,
--  as a menu or a command does: the module is told and follows it, its options
--  page shows it, its profile keeps it. One under another (parent) stands a
--  little in and is greyed out while that one is off or set otherwise
--  (parentValue). A switch of a kind not listed here, or hidden (hidden), has
--  no control in a step.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Controls = {}
ns.Controls = Controls

Controls.TICK = 26    -- a switch's row
Controls.SLIDER = 50  -- a number's: its words over the slider
Controls.WORDS = 20   -- the words over a number or one of a few
Controls.CHOICE = 22  -- each choice's row
Controls.GAP = 4      -- between two controls
Controls.UNDER = 22   -- a control under another (parent): this far in
Controls.SIZE = 14    -- the words' size (Look.SetFont: a 1080p layout's pixels)
Controls.RADIO = "Interface\\Buttons\\UI-RadioButton" -- the game's round button (UIRadioButtonTemplate's art)
Controls.DIM = 0.5    -- the words of a control greyed out
Controls.ACROSS = 3   -- one of a few with at most this many choices: side by side
Controls.KEY = { 150, 24 } -- a key's box
Controls.MODIFIERS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
                       LMETA = true, RMETA = true, UNKNOWN = true }
Controls.TEXT = {
    press = "Press a key",
    pressTip = "Press the key (with Shift, Ctrl or Alt if you like). Esc: keep it as it was.",
    unbound = Core.Word("NOT_BOUND", "Not bound"),
    keyTip = "Click, then press the key you want for it. Right click: no key.",
    fight = "Keys can be changed out of a fight only.",
    taken = "%s no longer does: %s.",
}

-- The value of a switch as a number shows it: with its unit ("75%"), a distance as the setting Units says.
function Controls.Value(option, value)
    value = tonumber(value) or 0
    if option.offAt ~= nil and value >= option.offAt then return Core.Word("OFF", "Off") end -- as the options page says
    if option.distance then return Core.Distance(value) end
    local text = tostring(math.floor(value + 0.5))
    if option.unit == "%" then return text .. "%" end
    if option.unit then return text .. " " .. option.unit end
    return text
end

-- Whether a control can be used: the switch it is under on (or set to its value, parentValue), and that one's too.
function Controls.Open(name, option, options, depth)
    depth = depth or 0
    local parent = option.parent
    if not parent or depth > 8 then return true end
    local parents = type(parent) == "table" and parent or { parent }
    for _, key in ipairs(parents) do
        local value = options[key]
        if option.parentValue ~= nil then
            if value ~= option.parentValue then return false end
        elseif value == false then
            return false
        end
        local above = Core.Described(name, key)
        if above and not Controls.Open(name, above, options, depth + 1) then return false end
    end
    return true
end

local function Words(host, colour)
    local words = host:CreateFontString(nil, "ARTWORK")
    Look.SetFont(words, Controls.SIZE, false, colour)
    words:SetJustifyH("LEFT")
    words:SetWordWrap(false)
    return words
end

local function Dim(words, open, colour)
    colour = colour or Look.INK
    local share = open and 1 or Controls.DIM
    words:SetTextColor(colour[1] * share, colour[2] * share, colour[3] * share)
end

-- A switch: a tick and its words, its tip on both.
local function Tick(host, name, option, width)
    local row = CreateFrame("Frame", nil, host)
    row:SetSize(width, Controls.TICK)
    local tick = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    tick:SetSize(24, 24)
    tick:SetPoint("LEFT", row, "LEFT", 0, 0)
    tick:SetHitRectInsets(0, -(width - 24), 0, 0) -- the words click it too
    local words = Words(row)
    words:SetPoint("LEFT", tick, "RIGHT", 4, 0)
    words:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    words:SetText(option.text or option.key)
    tick:SetScript("OnClick", ns.Guard(function(self)
        local on = self:GetChecked() == true
        Core.Sound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
        ns.Window.Set(name, option.key, on)
    end))
    Core.Tip(tick, option.text, option.tip)
    function row.Refresh(_, options, open)
        tick:SetChecked(options[option.key] ~= false)
        tick:SetEnabled(open)
        Dim(words, open)
    end
    row.tick = tick
    return row
end

-- A number: its words and value over the game's slider with its steppers.
local function Number(host, name, option, width)
    local row = CreateFrame("Frame", nil, host)
    row:SetSize(width, Controls.SLIDER)
    local words = Words(row)
    words:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
    words:SetPoint("TOPRIGHT", row, "TOPRIGHT", -60, 0)
    words:SetText(option.text or option.key)
    local value = Words(row, Look.GOLD)
    value:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, 0)
    value:SetJustifyH("RIGHT")
    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("TOPLEFT", row, "TOPLEFT", -6, -Controls.WORDS)
    slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", 6, -Controls.WORDS)
    slider:SetHeight(Controls.SLIDER - Controls.WORDS)
    local step, low, high = option.step or 1, option.min or 0, option.max or 100
    local options = Core.Settings(name) or {}
    slider:Init(tonumber(options[option.key]) or option.default or low, low, high, math.max((high - low) / step, 1))
    local busy = false -- shown anew (Refresh): not a change of the player's
    local mixin = rawget(_G, "MinimalSliderWithSteppersMixin")
    if mixin and mixin.Event then
        slider:RegisterCallback(mixin.Event.OnValueChanged, ns.Guard(function(_, moved)
            moved = math.floor((tonumber(moved) or low) / step + 0.5) * step
            value:SetText(Controls.Value(option, moved))
            if not busy then ns.Window.Set(name, option.key, math.max(math.min(moved, high), low)) end
        end), row)
    end
    Core.Tip(row, option.text, option.tip)
    function row.Refresh(_, now, open)
        local current = tonumber(now[option.key]) or option.default or low
        busy = true
        slider:SetValue(current)
        busy = false
        value:SetText(Controls.Value(option, current))
        slider:SetEnabled(open)
        Dim(words, open)
        Dim(value, open, Look.GOLD)
    end
    row.slider = slider
    return row
end

-- A round button of the game's (UIRadioButtonTemplate's art, made here: that template names its words globally).
local function Round(host)
    local button = CreateFrame("CheckButton", nil, host)
    button:SetSize(16, 16)
    local normal = button:CreateTexture(nil, "BACKGROUND")
    normal:SetTexture(Controls.RADIO)
    normal:SetTexCoord(0, 0.25, 0, 1)
    normal:SetAllPoints()
    button:SetNormalTexture(normal)
    local checked = button:CreateTexture(nil, "ARTWORK")
    checked:SetTexture(Controls.RADIO)
    checked:SetTexCoord(0.25, 0.5, 0, 1)
    checked:SetAllPoints()
    button:SetCheckedTexture(checked)
    local light = button:CreateTexture(nil, "HIGHLIGHT")
    light:SetTexture(Controls.RADIO)
    light:SetTexCoord(0.5, 0.75, 0, 1)
    light:SetBlendMode("ADD")
    light:SetAllPoints()
    button:SetHighlightTexture(light)
    return button
end

-- One of a few: its words, then a round button and the words of each choice; side by side where they are few.
local function Choice(host, name, option, width)
    local row = CreateFrame("Frame", nil, host)
    local across = #option.choices <= Controls.ACROSS
    row:SetSize(width, Controls.WORDS + (across and 1 or #option.choices) * Controls.CHOICE)
    local words = Words(row)
    words:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
    words:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    words:SetText(option.text or option.key)
    local rounds = {}
    for index, choice in ipairs(option.choices) do
        local round = Round(row)
        local column = across and (width - 6) / #option.choices or width - 6
        local x = 6 + (across and (index - 1) * column or 0)
        local y = Controls.WORDS + (across and 0 or (index - 1) * Controls.CHOICE) + 2
        round:SetPoint("TOPLEFT", row, "TOPLEFT", x, -y)
        round:SetHitRectInsets(0, -(column - 24), -3, -3)
        local label = Words(row)
        label:SetPoint("LEFT", round, "RIGHT", 6, 0)
        label:SetWidth(math.max(column - 28, 10))
        label:SetText(choice[2])
        round:SetScript("OnClick", ns.Guard(function()
            Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
            ns.Window.Set(name, option.key, choice[1])
        end))
        Core.Tip(round, option.text, option.tip)
        rounds[index] = { button = round, label = label, value = choice[1] }
    end
    function row.Refresh(_, options, open)
        for _, entry in ipairs(rounds) do
            entry.button:SetChecked(options[option.key] == entry.value)
            entry.button:SetEnabled(open)
            Dim(entry.label, open)
        end
        Dim(words, open)
    end
    row.rounds = rounds
    return row
end

-- The game's words for a key ("Shift-F"), and those of the keys a command is bound to ("Not bound" for none).
local function KeyWords(key)
    local words = Core.Ask(rawget(_G, "GetBindingText"), key)
    return type(words) == "string" and words ~= "" and words or key
end
local function Keys(command)
    local keys = { Core.Ask(rawget(_G, "GetBindingKey"), command) }
    local said = {}
    for _, key in ipairs(keys) do
        if type(key) == "string" and key ~= "" then said[#said + 1] = KeyWords(key) end
    end
    return #said > 0 and table.concat(said, ", ") or Controls.TEXT.unbound, keys
end

-- A command bound to that key alone (nil: to none): its keys let go first, the key's other command said, the game's
-- bindings saved as its own key binding window saves them. Out of a fight only. Whether it was done.
function Controls.Bind(command, key)
    if InCombatLockdown() then
        Core.Print(Controls.TEXT.fight)
        return false
    end
    local set, save = rawget(_G, "SetBinding"), rawget(_G, "SaveBindings")
    if not set or not save then return false end
    local _, keys = Keys(command)
    for _, old in ipairs(keys) do
        if type(old) == "string" and old ~= "" then Core.Ask(set, old) end
    end
    if key then
        local had = Core.Ask(rawget(_G, "GetBindingAction"), key)
        if type(had) == "string" and had ~= "" and had ~= command then
            Core.Print(Controls.TEXT.taken:format(KeyWords(key), rawget(_G, "BINDING_NAME_" .. had) or had))
        end
        Core.Ask(set, key, command)
    end
    local sets = rawget(_G, "GetCurrentBindingSet")
    Core.Ask(save, sets and Core.Ask(sets) or 2)
    return true
end

-- The key pressed with the modifiers held, in the game's order ("ALT-CTRL-SHIFT-F"); nil for a modifier alone.
function Controls.Chord(key)
    if Controls.MODIFIERS[key] then return nil end
    local chord = ""
    if IsAltKeyDown() then chord = chord .. "ALT-" end
    if IsControlKeyDown() then chord = chord .. "CTRL-" end
    if IsShiftKeyDown() then chord = chord .. "SHIFT-" end
    return chord .. key
end

-- A key of the game's or a module's (its command): its words and a box with its keys, in the thin golden outline.
local function Key(host, entry, width)
    local row = CreateFrame("Frame", nil, host)
    row:SetSize(width, Controls.TICK + 4)
    local words = Words(row)
    words:SetPoint("LEFT", row, "LEFT", 2, 0)
    words:SetPoint("RIGHT", row, "RIGHT", -(Controls.KEY[1] + 8), 0)
    words:SetText(entry.text or rawget(_G, "BINDING_NAME_" .. entry.binding) or entry.binding)
    local box = CreateFrame("Button", nil, row)
    box:SetSize(Controls.KEY[1], Controls.KEY[2])
    box:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    box:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local outline = Look.Outline(box)
    local label = Words(box, Look.GOLD)
    label:SetPoint("LEFT", box, "LEFT", 6, 0)
    label:SetPoint("RIGHT", box, "RIGHT", -6, 0)
    label:SetJustifyH("CENTER")
    local function Shown()
        label:SetText(box.listening and Controls.TEXT.press or (Keys(entry.binding)))
        outline:SetStrong(box.listening == true)
    end
    local function Stop()
        box.listening = false
        box:EnableKeyboard(false)
        Shown()
    end
    box:SetScript("OnClick", ns.Guard(function(_, mouse)
        if mouse == "RightButton" then
            Stop()
            if Controls.Bind(entry.binding, nil) then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF") end
            return Shown()
        end
        if InCombatLockdown() then return Core.Print(Controls.TEXT.fight) end
        box.listening = true
        box:EnableKeyboard(true)
        box:SetPropagateKeyboardInput(false)
        Shown()
    end))
    box:SetScript("OnKeyDown", ns.Guard(function(_, key)
        if not box.listening then return end
        if key == "ESCAPE" then return Stop() end
        local chord = Controls.Chord(key)
        if not chord then return end
        Stop()
        if Controls.Bind(entry.binding, chord) then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON") end
        Shown()
    end))
    box:SetScript("OnHide", ns.Guard(function() if box.listening then Stop() end end))
    Core.Tip(box, words:GetText(), entry.tip and (entry.tip .. "\n" .. Controls.TEXT.keyTip) or Controls.TEXT.keyTip)
    function row.Refresh() Shown() end
    row.box, row.label = box, label
    Shown()
    return row
end

-- The control for a switch of the module's, by its kind; nil for a kind a step does not show.
local function Make(host, name, option, width)
    if option.button or option.multi or option.color or option.entry then return nil end
    if option.choices then return Choice(host, name, option, width) end
    if option.min and option.max then return Number(host, name, option, width) end
    if type(option.default) == "boolean" then return Tick(host, name, option, width) end
    return nil
end

-- A step's controls on a frame of their own, one under another, as wide as width: the frame, its rows and its
-- height. keys: the module's switches by their keys, in the step's order.
function Controls.Build(parent, name, keys, width)
    local holder = CreateFrame("Frame", nil, parent)
    local rows, y = {}, 0
    local options = Core.Settings(name) or {}
    for _, key in ipairs(keys or {}) do
        -- A key ({ binding = "COMMAND", text, tip }), or one of the module's switches by its key.
        local binding = type(key) == "table" and type(key.binding) == "string" and key
        local option = not binding and Core.Described(name, key)
        local hidden = option and type(option.hidden) == "function" and ns.Safe("hidden", option.hidden, options)
        local inset = option and option.parent and Controls.UNDER or 0
        local row
        if binding then
            row = Key(holder, binding, width)
            option = { key = binding.binding }
        else
            row = option and option.text and not hidden and Make(holder, name, option, width - inset)
        end
        if row then
            row:SetPoint("TOPLEFT", holder, "TOPLEFT", inset, -y)
            row.option = option
            rows[#rows + 1] = row
            y = y + row:GetHeight() + Controls.GAP
        end
    end
    holder:SetSize(width, math.max(y, 1))
    holder.rows = rows
    return holder
end

-- Every control of a step showing the values in use, greyed out where its parent is off.
function Controls.Refresh(holder, name)
    local options = Core.Settings(name) or {}
    for _, row in ipairs(holder.rows or {}) do
        row:Refresh(options, Controls.Open(name, row.option, options))
    end
end
