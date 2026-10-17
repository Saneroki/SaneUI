local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Panel
--  The parts of an options page of our own (a canvas: the page Profiles), all
--  made from the game's templates and art:
--      Header    the page's title over the game's divider, as its own pages have
--      Tabs      the options window's own tabs (MinimalTabTemplate, as Game and
--                AddOns), one shown at a time
--      Scroll    a scroll area with the game's thin scroll bar (ScrollFrameTemplate)
--      Box       a titled box around a group (BackdropTemplate, the tooltip border)
--      Check     a checkbox with its words (UICheckButtonTemplate)
--      Slider    the game's slider with steppers, its value beside it
--                (MinimalSliderWithSteppersTemplate, as on the game's own pages)
--      Dropdown  one of a few, in the game's dropdown (WowStyle1DropdownTemplate)
--      Button    a button with its words (UIPanelButtonTemplate)
--      Color     a colour's swatch (ColorSwatchTemplate); a click opens the game's
--                colour picker (ColorPickerFrame), as its chat settings do
--      Text      a line of words that wraps
--  A control reads its value from get() whenever the page shows it anew
--  (Config.Refresh); a click calls set(value).
-------------------------------------------------------------------------------
local Core = SaneUI.Core

local Panel = {}
Config.Panel = Panel

local ROW = 28 -- a row of checkboxes
local BACKDROP = { bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16, insets = { left = 3, right = 3, top = 3, bottom = 3 } }
Panel.ROW = ROW

local controls = {} -- every control that shows a value, to show it anew; found by its words
Panel.controls = controls

function Panel.Refresh()
    for _, control in ipairs(controls) do Core.Safe("Settings: panel", control.Refresh, control) end
end

-- What the mouse over a control tells.
local function Tooltip(widget, title, tip)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, title)
        if tip then GameTooltip_AddNormalLine(GameTooltip, tip, true) end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", GameTooltip_Hide)
end
Panel.Tooltip = Tooltip

function Panel.Header(page, title)
    local text = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    text:SetPoint("TOPLEFT", 7, -22)
    text:SetText(title)
    local line = page:CreateTexture(nil, "ARTWORK")
    line:SetAtlas("Options_HorizontalDivider", true)
    line:SetPoint("TOP", 0, -50)
    return text
end

-- A line of words, as wide as its parent from x on.
function Panel.Text(parent, text, font, x, y)
    local line = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    line:SetPoint("TOPLEFT", x or 0, y or 0)
    line:SetPoint("RIGHT", -(x or 0), 0)
    line:SetJustifyH("LEFT")
    line:SetText(text)
    return line
end

-- Tabs along the top of a page; show(index) shows that tab's part. Returns the tabs.
function Panel.Tabs(page, names, show, x, y)
    local tabs, previous = {}, nil
    for index, name in ipairs(names) do
        local tab = CreateFrame("Button", nil, page, "MinimalTabTemplate")
        tab.Text:SetText(name)
        tab:SetWidth(tab.Text:GetStringWidth() + 40)
        if previous then tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 5, 0) else tab:SetPoint("TOPLEFT", x, y) end
        tab.index, tabs[index], previous = index, tab, tab
    end
    local group = CreateRadioButtonGroup()
    group:AddButtons(tabs)
    group:RegisterCallback(ButtonGroupBaseMixin.Event.Selected, function(_, tab) show(tab.index) end, page)
    group:SelectAtIndex(1)
    return tabs, group
end

-- A scroll area filling parent; what it holds goes into the returned frame, as wide as the area.
function Panel.Scroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", function(self, width) child:SetWidth(width) end)
    return child, scroll
end

-- A dark fill and the game's tooltip border, as boxes in the game's options have had.
function Panel.Frame(frame)
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
end

-- A box with a title over it, as wide as parent, its title y below parent's top; height is set by
-- whoever fills it. Returns the box.
function Panel.Box(parent, title, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 14, y)
    label:SetText(title)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 4, y - 18)
    box:SetPoint("RIGHT", -4, 0)
    Panel.Frame(box)
    box.label = label
    return box
end

-- A checkbox with its words. get() its value, set(value) when clicked, enabled() whether it can be;
-- bare: without its words beside it (under a column's head), but in its tooltip.
function Panel.Check(parent, text, tip, get, set, enabled, bare)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    local label = check.Text or check.text
    if type(label) == "table" then
        label:SetFontObject("GameFontHighlight")
        label:SetText(bare and "" or text)
        -- A little room between the box and its words (the game's template has them touch it).
        label:ClearAllPoints()
        label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    end
    check.label, check.get = text, get
    check:SetScript("OnClick", function(self)
        Core.Safe("Settings: " .. text, set, self:GetChecked() and true or false)
        Panel.Refresh()
    end)
    Tooltip(check, text, tip)
    function check:Refresh()
        self:SetChecked(get() and true or false)
        if not enabled then return end
        local on = enabled() and true or false
        self:SetEnabled(on)
        -- Grey words for one that cannot be used now, as the game's own options show it.
        if type(label) == "table" then label:SetFontObject(on and "GameFontHighlight" or "GameFontDisable") end
    end
    controls[#controls + 1] = check
    return check
end

-- Checkboxes in two columns inside a box, from top (below its top; -10 if not given); sets the
-- box's height to hold them and returns it.
function Panel.Columns(box, checks, top)
    top = top or -10
    for index, check in ipairs(checks) do
        local row, column = math.floor((index - 1) / 2), (index - 1) % 2
        if column == 0 then
            check:SetPoint("TOPLEFT", box, "TOPLEFT", 12, top - row * ROW)
        else
            check:SetPoint("TOPLEFT", box, "TOP", 6, top - row * ROW)
        end
    end
    local height = -top + 10 + math.ceil(#checks / 2) * ROW
    box:SetHeight(height)
    return height
end

-- How a number is written beside its slider: two decimals for steps below 1, then its unit.
function Panel.Format(value, step, unit)
    local text = step < 1 and ("%.2f"):format(value) or ("%d"):format(math.floor(value + 0.5))
    return unit and (text .. " " .. unit) or text
end

-- A number between option.min and option.max in steps of option.step, its value and option.unit
-- written right of it. get() its value, set(value) when moved, enabled() whether it can be.
function Panel.Slider(parent, text, tip, option, get, set, enabled)
    local slider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(220)
    local step = option.step
    local right = MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label.Right
    slider:Init(get(), option.min, option.max, (option.max - option.min) / step,
        right and { [right] = function(value) return Panel.Format(value, step, option.unit) end } or nil)
    slider.label, slider.get, slider.set = text, get, set
    -- Moved by hand: the value on its step (a slider's own is a float near it). Shown anew (Refresh)
    -- the slider tells of its value too; that is the one there already and is not set again.
    function slider.Moved(_, value)
        value = math.floor((value - option.min) / step + 0.5) * step + option.min
        if step < 1 then value = tonumber(("%.2f"):format(value)) end
        if value == get() then return end
        Core.Safe("Settings: " .. text, set, value)
    end
    if slider.RegisterCallback and MinimalSliderWithSteppersMixin then
        slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, slider.Moved, slider)
    end
    Tooltip(slider, text, tip)
    function slider:Refresh()
        self:SetValue(get())
        if enabled then self:SetEnabled(enabled() and true or false) end
    end
    controls[#controls + 1] = slider
    return slider
end

-- One of option.choices ({ value, words }) in the game's dropdown. get() its value, set(value) when
-- chosen, enabled() whether it can be.
function Panel.Dropdown(parent, text, tip, option, get, set, enabled)
    local menu = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    menu:SetWidth(220)
    menu:SetupMenu(function(_, root)
        local function IsChosen(value) return get() == value end
        local function Choose(value)
            Core.Safe("Settings: " .. text, set, value)
            Panel.Refresh()
        end
        for _, choice in ipairs(option.choices) do root:CreateRadio(choice[2], IsChosen, Choose, choice[1]) end
    end)
    menu.label, menu.get, menu.set = text, get, set
    Tooltip(menu, text, tip)
    function menu:Refresh()
        self:GenerateMenu()
        if enabled then self:SetEnabled(enabled() and true or false) end
    end
    controls[#controls + 1] = menu
    return menu
end

-- A colour written as six hex digits ("26262B"), and back. One that cannot be read is white.
function Panel.Hex(r, g, b)
    local function Byte(value) return math.floor(math.min(math.max(value, 0), 1) * 255 + 0.5) end
    return ("%02X%02X%02X"):format(Byte(r), Byte(g), Byte(b))
end

function Panel.RGB(hex)
    local r, g, b = tostring(hex):match("^(%x%x)(%x%x)(%x%x)$")
    if not r then return 1, 1, 1 end
    return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end

-- A colour's swatch: a click opens the game's colour picker on it, every move there is set at once
-- (so it shows where it is used), Cancel sets it back. get() its value as hex, set(hex), enabled().
function Panel.Color(parent, text, tip, get, set, enabled)
    local swatch = CreateFrame("Button", nil, parent, "ColorSwatchTemplate")
    swatch:SetSize(22, 22)
    swatch.label, swatch.get, swatch.set = text, get, set
    local function Set(hex)
        Core.Safe("Settings: " .. text, set, hex)
        swatch:Refresh()
    end
    swatch:SetScript("OnClick", function()
        local before = get()
        local r, g, b = Panel.RGB(before)
        ColorPickerFrame:SetupColorPickerAndShow({ r = r, g = g, b = b,
            swatchFunc = function() Set(Panel.Hex(ColorPickerFrame:GetColorRGB())) end,
            cancelFunc = function() Set(before) end })
    end)
    Tooltip(swatch, text, tip)
    swatch:HookScript("OnEnter", function(self) self:SetBorderColor(NORMAL_FONT_COLOR) end)
    swatch:HookScript("OnLeave", function(self) self:SetBorderColor(HIGHLIGHT_FONT_COLOR) end)
    function swatch:Refresh()
        self:SetColorRGB(Panel.RGB(get()))
        local on = not enabled or enabled()
        self:SetEnabled(on and true or false)
        self:SetAlpha(on and 1 or 0.4) -- greyed out, as a control that cannot be used now
    end
    controls[#controls + 1] = swatch
    return swatch
end

-- A button with its words. click() when clicked; enabled() whether it can be.
function Panel.Button(parent, text, tip, click, enabled, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 100, 22)
    button:SetText(text)
    button.label = text
    button:SetScript("OnClick", function() Core.Safe("Settings: " .. text, click) end)
    Tooltip(button, text, tip)
    function button:Refresh()
        if enabled then self:SetEnabled(enabled() and true or false) end
    end
    controls[#controls + 1] = button
    return button
end

-- Something else that shows a value: label names it, Refresh shows it anew.
function Panel.Watch(control)
    controls[#controls + 1] = control
end
