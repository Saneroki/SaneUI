local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Onboarding - Controls
--  A step's controls: the module's own switches as its options page has them
--  (Core.Described: the switch's words, its tip, its kind), one under another:
--    a switch           a tick and its words (the words click it too)
--    a number           its words, its value at the right, the game's slider
--                       with its steppers under them (MinimalSliderWithSteppers)
--    one of a few       its words, then a round button and the words of each
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

-- The value of a switch as a number shows it: with its unit ("75%"), a distance as the setting Units says.
function Controls.Value(option, value)
    value = tonumber(value) or 0
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

-- One of a few: its words, then a round button and the words of each choice.
local function Choice(host, name, option, width)
    local row = CreateFrame("Frame", nil, host)
    row:SetSize(width, Controls.WORDS + #option.choices * Controls.CHOICE)
    local words = Words(row)
    words:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
    words:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    words:SetText(option.text or option.key)
    local rounds = {}
    for index, choice in ipairs(option.choices) do
        local round = Round(row)
        round:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -(Controls.WORDS + (index - 1) * Controls.CHOICE + 2))
        round:SetHitRectInsets(0, -(width - 30), -3, -3)
        local label = Words(row)
        label:SetPoint("LEFT", round, "RIGHT", 6, 0)
        label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
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
        local option = Core.Described(name, key)
        local hidden = option and type(option.hidden) == "function" and ns.Safe("hidden", option.hidden, options)
        local inset = option and option.parent and Controls.UNDER or 0
        local row = option and option.text and not hidden and Make(holder, name, option, width - inset)
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
