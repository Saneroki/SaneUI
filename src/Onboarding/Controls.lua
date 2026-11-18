local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Onboarding - Controls
--  A step's controls: the module's own switches as its options page has them
--  (Core.Described: the switch's words, its tip, its kind), one under another:
--    a switch           a tick and its words (the words click it too)
--    a number           its words, its value at the right, the game's slider
--                       with its steppers under them (MinimalSliderWithSteppers)
--    one of a few       its words, then a round button and the words of each,
--                       side by side where three or fewer fit on a line;
--                       places round a bar (around): a round button at each
--                       place round a small bar, its tooltip its words
--    a key              its words, and a box with the keys it is bound to:
--                       a click, then the key to bind it to, with Shift,
--                       Ctrl and Alt as held (Alt-Shift-V), or a mouse
--                       button past the two main ones (Esc: as it was); a
--                       right click unbinds it (the game's own key
--                       bindings, saved as its key binding window saves them)
--    a command          a button with its words that runs one of the game's
--                       slash commands ({ macro = "/editmode", command =
--                       "EDITMODE", text, tip, done, missing }): Combat's
--                       party and raid frames placed in Edit Mode (Command)
--  A step may word one of the module's switches its own way: its entry
--  { key = "expandClick", text, tip, choices = { { value, words }, ... },
--  column = true } over the switch's description (a switch shown as round
--  buttons, one under another with column; Navigation's setup). With
--  around = true the choices are places round a bar (Controls.PLACES); with
--  beside = true a control stands at the right of the one before it, without
--  words of its own, that one narrower (Nameplates' place beside each count).
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
-- Places round a bar (option.around): each choice's value, its round button's row (1 over the bar, 2 beside it, 3
-- under it) and column (0 at the bar's left, 1 its left end, 2 its middle, 3 its right end, 4 at its right).
Controls.PLACES = { topleft = { 1, 1 }, top = { 1, 2 }, topright = { 1, 3 }, left = { 2, 0 }, right = { 2, 4 },
                    bottomleft = { 3, 1 }, bottom = { 3, 2 }, bottomright = { 3, 3 } }
Controls.BAR = { 64, 10 } -- the small bar they stand round
Controls.ROUND = 16       -- a round button
Controls.AROUND = { Controls.ROUND * 2 + 64 + 12, 3 * (Controls.ROUND + 4) } -- the places' room: width, height
Controls.BAR_COLOUR = { 0.75, 0.12, 0.08 } -- the small bar: a foe's red
Controls.LISTENER = "FULLSCREEN_DIALOG" -- the frame that hears the key: over the window (DIALOG)
-- Keys no binding takes alone (the game's IsKeyPressIgnoredForBinding where it has none): the modifiers, the two main
-- mouse buttons.
Controls.MODIFIERS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
                       LMETA = true, RMETA = true, ALT = true, CTRL = true, SHIFT = true, META = true,
                       UNKNOWN = true, BUTTON1 = true, BUTTON2 = true }
Controls.MOUSE = { LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3" } -- the rest: ButtonN
Controls.TEXT = {
    press = "Press a key",
    unbound = Core.Word("NOT_BOUND", "Not bound"),
    keyTip = "Click, then press the key you want for it, with Shift, Ctrl or Alt if you like (Alt-Shift-V). "
        .. "Esc: keep it as it was. Right click: no key.",
    fight = "Keys can be changed out of a fight only.",
    commandFight = "That opens after the fight.",
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

-- Whether every choice is a place round a bar (Controls.PLACES).
local function Places(option)
    if not option.around then return false end
    for _, choice in ipairs(option.choices) do
        if not Controls.PLACES[choice[1]] then return false end
    end
    return true
end

-- Places round a bar (option.around): its words (none beside another control), then a small bar with a round button
-- at each place round it, the choice's words its tooltip.
local function Around(host, name, option, width)
    local row = CreateFrame("Frame", nil, host)
    local top = option.beside and 0 or Controls.WORDS
    row:SetSize(option.beside and Controls.AROUND[1] or width, top + Controls.AROUND[2])
    local words
    if not option.beside then
        words = Words(row)
        words:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
        words:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        words:SetText(option.text or option.key)
    end
    local left = option.beside and 0 or 6
    local round, step = Controls.ROUND, Controls.ROUND + 4
    local start = left + round + 6 -- the small bar's left end
    local bar = row:CreateTexture(nil, "ARTWORK")
    bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    local colour = Controls.BAR_COLOUR
    bar:SetVertexColor(colour[1], colour[2], colour[3])
    bar:SetSize(Controls.BAR[1], Controls.BAR[2])
    bar:SetPoint("TOPLEFT", row, "TOPLEFT", start, -(top + step + (round - Controls.BAR[2]) / 2))
    local edge = CreateFrame("Frame", nil, row)
    edge:SetAllPoints(bar)
    Look.Outline(edge)
    local columns = { [0] = left, start, start + (Controls.BAR[1] - round) / 2, start + Controls.BAR[1] - round,
                      start + Controls.BAR[1] + 6 }
    local rounds = {}
    for index, choice in ipairs(option.choices) do
        local at = Controls.PLACES[choice[1]]
        local button = Round(row)
        button:SetPoint("TOPLEFT", row, "TOPLEFT", columns[at[2]], -(top + (at[1] - 1) * step))
        button:SetScript("OnClick", ns.Guard(function()
            Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
            ns.Window.Set(name, option.key, choice[1])
        end))
        Core.Tip(button, choice[2], option.text)
        rounds[index] = { button = button, value = choice[1] }
    end
    function row.Refresh(_, options, open)
        for _, entry in ipairs(rounds) do
            entry.button:SetChecked(options[option.key] == entry.value)
            entry.button:SetEnabled(open)
        end
        bar:SetAlpha(open and 1 or Controls.DIM)
        if words then Dim(words, open) end
    end
    row.rounds, row.bar = rounds, bar
    return row
end

-- One of a few: its words, then a round button and the words of each choice; side by side where they are few.
local function Choice(host, name, option, width)
    if Places(option) then return Around(host, name, option, width) end
    local row = CreateFrame("Frame", nil, host)
    local across = not option.column and #option.choices <= Controls.ACROSS
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

-- The key pressed with the modifiers held, as the game's key binding window makes it (its BindingUtil: a mouse
-- button "MiddleButton" as "BUTTON3", the modifiers in its order, "ALT-CTRL-SHIFT-V"); nil for a modifier alone, the
-- two main mouse buttons or a key the game does not know.
local function Converted(key)
    local converted = Core.Ask(rawget(_G, "GetConvertedKeyOrButton"), key)
    if type(converted) == "string" then return converted end
    if type(key) ~= "string" then return nil end
    local number = key:match("^Button(%d+)$")
    return number and ("BUTTON" .. number) or Controls.MOUSE[key] or key
end
function Controls.Chord(key)
    key = Converted(key)
    if type(key) ~= "string" or key == "" or Controls.MODIFIERS[key] then return nil end
    local ignored = rawget(_G, "IsKeyPressIgnoredForBinding")
    if ignored and Core.Ask(ignored, key) == true then return nil end
    local made = Core.Ask(rawget(_G, "CreateKeyChordStringUsingMetaKeyState"), key)
    if type(made) == "string" and made ~= "" then return made end
    local chord = ""
    if IsAltKeyDown() then chord = chord .. "ALT-" end
    if IsControlKeyDown() then chord = chord .. "CTRL-" end
    if IsShiftKeyDown() then chord = chord .. "SHIFT-" end
    return chord .. key
end

-- The one frame that hears the key a box waits for, as the game's own key listener (KeybindListener): over the
-- window, given its OnKeyDown only while a box waits. A frame with that script takes the keyboard and passes no key on,
-- so a box holding the script all along kept every key from the box clicked (a step of several keys: only the top
-- one heard any). One box waits at a time; the one waiting before is let go (its Release).
local listener, waiting
function Controls.Wait(box)
    local before = waiting
    waiting = box
    if before and before ~= box and before.Release then before.Release() end
    if not listener then
        listener = CreateFrame("Frame")
        listener:SetFrameStrata(Controls.LISTENER)
        listener.Heard = ns.Guard(function(_, key)
            if waiting and waiting.Heard then waiting.Heard(key) end
        end)
        Controls.listener = listener
    end
    if box then
        listener:Show()
        listener:SetScript("OnKeyDown", listener.Heard)
        listener:EnableKeyboard(true)
    else
        listener:SetScript("OnKeyDown", nil) -- the keyboard let go: back to the game
        listener:EnableKeyboard(false)
        listener:Hide()
    end
end
function Controls.Waiting() return waiting end

-- A key of the game's or a module's (its command): its words and a box with its keys, in the thin golden outline.
local function Key(host, entry, width)
    local row = CreateFrame("Frame", nil, host)
    row:SetSize(width, Controls.TICK + 4)
    local words = Words(row)
    words:SetPoint("LEFT", row, "LEFT", 2, 0)
    words:SetPoint("RIGHT", row, "RIGHT", -(Controls.KEY[1] + 8), 0)
    words:SetText(entry.text or rawget(_G, "BINDING_NAME_" .. entry.binding) or entry.binding)
    -- The box never takes the keyboard itself (Controls.Wait hears the key for it).
    local box = CreateFrame("Button", nil, row)
    box:SetSize(Controls.KEY[1], Controls.KEY[2])
    box:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    box:RegisterForClicks("AnyUp")
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
        if Controls.Waiting() == box then Controls.Wait(nil) end
        Shown()
    end
    box.Release = Stop
    -- A key (or a mouse button) while it waits: Esc keeps the key as it was, a modifier alone waits on for the rest.
    function box.Heard(key)
        if not box.listening then return end
        if key == "ESCAPE" then return Stop() end
        local chord = Controls.Chord(key)
        if not chord then return end
        Stop()
        if Controls.Bind(entry.binding, chord) then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON") end
        Shown()
    end
    box:SetScript("OnClick", ns.Guard(function(_, mouse)
        if mouse == "RightButton" then
            Stop()
            if Controls.Bind(entry.binding, nil) then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF") end
            return Shown()
        end
        if box.listening and mouse ~= "LeftButton" then return box.Heard(mouse) end -- the middle or a side button
        if InCombatLockdown() then return Core.Print(Controls.TEXT.fight) end
        box.listening = true
        Controls.Wait(box)
        Shown()
    end))
    box:SetScript("OnHide", ns.Guard(function() if box.listening then Stop() end end))
    Core.Tip(box, words:GetText(), entry.tip and (entry.tip .. "\n" .. Controls.TEXT.keyTip) or Controls.TEXT.keyTip)
    function row.Refresh() Shown() end
    row.box, row.label = box, label
    Shown()
    return row
end

-- A command of the game's ({ macro = "/editmode", command = "EDITMODE", text, tip, done = function() end, missing =
-- words }): a button with its words. The game runs a slash command for an addon only from its secure button
-- (SecureActionButtonTemplate, a macro of that text: Edit Mode opens as from the game's menu, nothing of ours in its
-- way), so the button seen is a plain one, and over it, on UIParent in its place (as Abilities' spellbook covers its
-- spells: a window of ours holding a protected frame could not be closed in a fight), the game's secure button takes
-- the click: there while the row shows and out of a fight, gone as a fight begins (PLAYER_REGEN_DISABLED comes
-- before the game locks it) and back after it, following the row while the window is dragged. done runs after the
-- command (PostClick). Where the game knows no such command (no SLASH_<command>1), the click says missing instead.
Controls.COMMAND = 260          -- the button's width at most
Controls.COVER = "FULLSCREEN_DIALOG" -- the secure button's layer: over the setup's window
local covers = {}               -- [row] = its secure button, made once
local function Place(row)
    local cover, button = covers[row], row.button
    if not cover or InCombatLockdown() then return end
    local left, top = button:GetLeft(), button:GetTop()
    if not (left and top) or not row:IsVisible() then
        cover:Hide()
        return
    end
    local ratio = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local width, height = button:GetWidth() * ratio, button:GetHeight() * ratio
    local at = { left * ratio, top * ratio, width, height }
    local was = cover.at
    if not (was and was[1] == at[1] and was[2] == at[2] and was[3] == at[3] and was[4] == at[4]) then
        cover.at = at
        cover:ClearAllPoints()
        cover:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", at[1], at[2])
        cover:SetSize(width, height)
    end
    cover:Show()
end
local function Cover(row, entry)
    local cover = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    cover:SetFrameStrata(Controls.COVER)
    cover:RegisterForClicks("LeftButtonUp")
    cover:SetAttribute("type", "macro")
    cover:SetAttribute("macrotext", entry.macro)
    cover:SetScript("PostClick", ns.Guard(function()
        if entry.done then ns.Safe("command", entry.done) end
    end))
    cover:SetScript("OnEnter", ns.Guard(function()
        row.button:LockHighlight()
        GameTooltip:SetOwner(cover, "ANCHOR_RIGHT")
        GameTooltip:SetText(entry.text)
        if entry.tip then GameTooltip:AddLine(entry.tip, 1, 1, 1, true) end
        GameTooltip:Show()
    end))
    cover:SetScript("OnLeave", ns.Guard(function()
        row.button:UnlockHighlight()
        GameTooltip:Hide()
    end))
    cover:Hide()
    covers[row] = cover
    return cover
end
local function Command(host, entry, width)
    local row = CreateFrame("Frame", nil, host)
    row:SetSize(width, Controls.TICK + 8)
    local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    button:SetSize(math.min(width, Controls.COMMAND), Controls.TICK + 2)
    button:SetPoint("LEFT", row, "LEFT", 0, 0)
    button:SetText(entry.text)
    row.button = button
    local known = type(entry.command) == "string" and rawget(_G, "SLASH_" .. entry.command .. "1") ~= nil
    -- The plain button's own click: the command where the game has none for us (words), or in a fight.
    button:SetScript("OnClick", ns.Guard(function()
        if InCombatLockdown() then return Core.Print(Controls.TEXT.commandFight) end
        if not known and entry.missing then Core.Print(entry.missing) end
    end))
    Core.Tip(button, entry.text, entry.tip)
    if known and type(entry.macro) == "string" then
        Cover(row, entry)
        row:SetScript("OnShow", ns.Guard(function() Place(row) end))
        row:SetScript("OnHide", ns.Guard(function()
            if not InCombatLockdown() then covers[row]:Hide() end
        end))
        -- Follows the row while the window is dragged (only while it shows).
        row:SetScript("OnUpdate", ns.Guard(function() Place(row) end))
    end
    function row.Refresh() end
    return row
end

-- A fight begins: every secure button of ours away before the game locks it; back over its row after the fight.
ns.On("PLAYER_REGEN_DISABLED", function()
    for _, cover in pairs(covers) do cover:Hide() end
end)
ns.On("PLAYER_REGEN_ENABLED", function()
    for row in pairs(covers) do Place(row) end
end)

-- One of the module's switches as a step words it ({ key, text, tip, choices, column }): its description with the
-- step's fields over it; nil for a switch the module does not describe.
local function Worded(name, entry)
    local option = type(entry.key) == "string" and Core.Described(name, entry.key)
    if not option then return nil end
    local worded = {}
    for field, value in pairs(option) do worded[field] = value end
    for field, value in pairs(entry) do worded[field] = value end
    return worded
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
    local last -- the control made just before, and where it stands: for one beside it
    keys = keys or {}
    for index, key in ipairs(keys) do
        local before = last
        last = nil
        local beside = type(key) == "table" and key.beside and before
        local after = keys[index + 1]
        local narrow = type(after) == "table" and after.beside -- the next one stands at the right of this one
        -- A key ({ binding = "COMMAND", text, tip }), one of the module's switches by its key, or one the step words
        -- its own way ({ key = "...", text, choices }).
        local binding = type(key) == "table" and type(key.binding) == "string" and key
        local command = type(key) == "table" and type(key.macro) == "string" and key
        local option = not (binding or command) and (type(key) == "table" and Worded(name, key) or Core.Described(name, key))
        local hidden = option and type(option.hidden) == "function" and ns.Safe("hidden", option.hidden, options)
        local inset = option and option.parent and Controls.UNDER or 0
        local row
        local room = width - inset - (narrow and Controls.AROUND[1] + 3 * Controls.GAP or 0)
        if binding then
            row = Key(holder, binding, room)
            option = { key = binding.binding }
        elseif command then
            row = Command(holder, command, room)
            option = { key = command.macro }
        else
            row = option and option.text and not hidden and Make(holder, name, option, room)
        end
        if row and beside then
            row:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -beside.y)
            y = beside.y + math.max(beside.row:GetHeight(), row:GetHeight()) + Controls.GAP
        elseif row then
            row:SetPoint("TOPLEFT", holder, "TOPLEFT", inset, -y)
            last = { row = row, y = y }
            y = y + row:GetHeight() + Controls.GAP
        end
        if row then
            row.option = option
            rows[#rows + 1] = row
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
