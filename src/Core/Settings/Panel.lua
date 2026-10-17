local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Panel
--  The parts of an options page of our own (a canvas: the page Profiles, a
--  module's page in tabs), all made from the game's templates and art:
--      Header    the page's title over the game's divider, as its own pages have
--      Tabs      the options window's own tabs (MinimalTabTemplate, as Game and
--                AddOns), one shown at a time; TabbedFrame: the tabs over a box,
--                each tab's part filling it
--      Scroll    a scroll area with the game's thin scroll bar (ScrollFrameTemplate)
--      Box       a titled box around a group (BackdropTemplate, the tooltip border)
--      Check     a checkbox with its words (UICheckButtonTemplate)
--      Slider    the game's slider with steppers, its value beside it
--                (MinimalSliderWithSteppersTemplate, as on the game's own pages)
--      Dropdown  one of a few, or several of them (a checkbox each), in the game's
--                dropdown (WowStyle1DropdownTemplate)
--      Edit      words or a number typed into the game's input box (InputBoxTemplate)
--      Button    a button with its words (UIPanelButtonTemplate)
--      Color     a colour's swatch (ColorSwatchTemplate); a click opens the game's
--                colour picker (ColorPickerFrame), as its chat settings do
--      Text      a line of words that wraps
--  A control reads its value from get() whenever the page shows it anew
--  (Config.Refresh); a click calls set(value). The controls are kept by their
--  page (Page): a click shows its own page anew, not every page.
-------------------------------------------------------------------------------
local Core = SaneUI.Core

local Panel = {}
Config.Panel = Panel

local ROW = 28 -- a row of checkboxes
local BACKDROP = { bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16, insets = { left = 3, right = 3, top = 3, bottom = 3 } }

local controls = {} -- every control that shows a value, to show it anew; found by its words
Panel.controls = controls
local pages = {}    -- [page] = the controls on it (Panel.Page)
local loose = {}    -- the controls on no such page
local owner = {}    -- [control] = its page
local stale = {}    -- [page] = true: it was hidden when its controls were to show their values anew

local function Show(list)
    for _, control in ipairs(list) do Core.Safe("Settings: panel", control.Refresh, control) end
end

-- The controls show their values anew: those of one page, or (no page) those of every page that is
-- shown now, and of the others once they are shown (a hidden page waits: nobody sees it).
function Panel.Refresh(page)
    if page and pages[page] then
        stale[page] = nil
        Show(pages[page])
        return
    end
    Show(loose)
    for frame, list in pairs(pages) do
        if frame:IsVisible() then
            stale[frame] = nil
            Show(list)
        else
            stale[frame] = true
        end
    end
end

-- A frame of ours that is a page: its controls are shown anew together. The game calls its OnRefresh
-- when it shows the page (and for every page of ours each time its options open); a page left out
-- while it was hidden catches up once it is shown.
function Panel.Page(page)
    if pages[page] then return end
    pages[page] = {}
    page.OnRefresh = function(self)
        if self:IsShown() then Panel.Refresh(self) end
    end
    page:HookScript("OnShow", function(self)
        if stale[self] then Panel.Refresh(self) end
    end)
end

-- The page a control is on: the nearest frame from it up that is one (Panel.Page).
local function PageOf(widget)
    local frame = widget
    while frame do
        if pages[frame] then return frame end
        frame = frame.GetParent and frame:GetParent() or nil
    end
    return nil
end

-- A control is kept to be shown anew, with the page it is on (found from widget, or itself).
local function Keep(control, widget)
    controls[#controls + 1] = control
    local page = PageOf(widget or control)
    owner[control] = page
    local list = page and pages[page] or loose
    list[#list + 1] = control
end

-- What the mouse over a control tells. After the template's own (a dropdown's highlight, a swatch's
-- border): those stay.
local function Tooltip(widget, title, tip)
    widget:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, title)
        if tip then GameTooltip_AddNormalLine(GameTooltip, tip, true) end
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", GameTooltip_Hide)
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

-- Tabs along the top of a page; show(index) shows that tab's part. Returns the tabs and their group
-- (group:SelectAtIndex(index) shows one).
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

-- The tabs of a page over a box from top down to the page's foot, each tab's part filling the box: a
-- tab is { name, build = function(holder) }, holder a scroll area's frame (Panel.Scroll; build returns
-- the height of what it put there) or, with scroll = false, the part itself; label names it in the
-- error log. The page is one (Panel.Page). Returns the tabs, their parts (part.scroll and part.child
-- for a scroll area) and the tabs' group.
function Panel.TabbedFrame(page, tabs, top)
    Panel.Page(page)
    local frame = CreateFrame("Frame", nil, page, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", 7, top)
    frame:SetPoint("BOTTOMRIGHT", -7, 8)
    Panel.Frame(frame)
    local names, parts = {}, {}
    for index, tab in ipairs(tabs) do
        local part = CreateFrame("Frame", nil, frame)
        part:SetAllPoints()
        part:Hide()
        local label = tab.label or ("Settings: tab " .. tab.name)
        if tab.scroll == false then
            Core.Safe(label, tab.build, part)
        else
            local child, scroll = Panel.Scroll(part)
            part.child, part.scroll = child, scroll
            child:SetHeight(Core.Safe(label, tab.build, child) or 1)
        end
        names[index], parts[index] = tab.name, part
    end
    local buttons, group = Panel.Tabs(page, names, function(index)
        for which, part in ipairs(parts) do part:SetShown(which == index) end
    end, 14, top + 34)
    page.tabs, page.parts = buttons, parts
    Panel.Refresh(page)
    return buttons, parts, group
end

-- A box with a title over it, as wide as parent, its title y below parent's top; height is set by
-- whoever fills it. tip: what the box is for, in the tooltip of its title (as the game's section
-- headers have it). Returns the box.
function Panel.Box(parent, title, y, tip)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetText(title)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Panel.Frame(box)
    box.label = label
    if tip then
        local hover = CreateFrame("Frame", nil, parent)
        hover:SetAllPoints(label)
        hover:EnableMouse(true)
        Tooltip(hover, title, tip)
        box.hover = hover
    end
    Panel.PlaceBox(box, y)
    return box
end

-- A box (Panel.Box) put anew, its title y below its parent's top.
function Panel.PlaceBox(box, y)
    box.label:ClearAllPoints()
    box.label:SetPoint("TOPLEFT", 14, y)
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", 4, y - 18)
    box:SetPoint("RIGHT", -4, 0)
end

-- A box with its title shown or not.
function Panel.ShowBox(box, shown)
    box:SetShown(shown)
    box.label:SetShown(shown)
    if box.hover then box.hover:SetShown(shown) end
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
        Panel.Refresh(owner[self])
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
    Keep(check)
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

-- How a number is written beside its slider: two decimals for steps below 1 (none: whole steps),
-- then its unit.
function Panel.Format(value, step, unit)
    local text = (step or 1) < 1 and ("%.2f"):format(value) or ("%d"):format(math.floor(value + 0.5))
    return unit and (text .. " " .. unit) or text
end

-- A number on its step from option.min (a slider's own value is a float near it); two decimals at
-- most for steps below 1.
function Panel.Step(option, value)
    local step, low = option.step or 1, option.min or 0
    value = math.floor((value - low) / step + 0.5) * step + low
    if step < 1 then value = tonumber(("%.2f"):format(value)) end
    return value
end

-- A number typed: read, on its step if it has one, within option.min and max; nil if the words are
-- no number (nor endless).
function Panel.Number(option, text)
    local value = tonumber(text)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    if option.step then value = Panel.Step(option, value) end
    if option.min then value = math.max(value, option.min) end
    if option.max then value = math.min(value, option.max) end
    return value
end

-- A value as its box shows it: a number as Format writes it (two decimals unless it is whole), words
-- as they are.
function Panel.Written(option, value)
    if type(value) == "number" then
        return Panel.Format(value, option.step or (value == math.floor(value) and 1 or 0.01))
    end
    return value ~= nil and tostring(value) or ""
end

-- A number between option.min and option.max in steps of option.step, its value and option.unit
-- written right of it. get() its value, set(value) when moved, enabled() whether it can be.
function Panel.Slider(parent, text, tip, option, get, set, enabled)
    local slider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(220)
    local step, low = option.step or 1, option.min or 0
    local right = MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label.Right
    slider:Init(get(), low, option.max, (option.max - low) / step,
        right and { [right] = function(value) return Panel.Format(value, step, option.unit) end } or nil)
    slider.label, slider.get, slider.set = text, get, set
    -- Moved by hand: the value on its step (a slider's own is a float near it). Shown anew (Refresh)
    -- the slider tells of its value too; that is the one there already and is not set again.
    function slider.Moved(_, value)
        value = Panel.Step(option, value)
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
    Keep(slider)
    return slider
end

-- One of option.choices ({ value, words }) in the game's dropdown; with option.multi several of them,
-- a checkbox each, kept as { [value] = true } (none: the game's word None). get() its value,
-- set(value) when chosen, enabled() whether it can be.
function Panel.Dropdown(parent, text, tip, option, get, set, enabled)
    local menu = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    menu:SetWidth(220)
    local multi = option.multi
    if multi then menu:SetDefaultText(Core.Word("NONE", "None")) end
    menu:SetupMenu(function(_, root)
        local function IsChosen(value)
            if not multi then return get() == value end
            local chosen = get()
            return type(chosen) == "table" and chosen[value] == true
        end
        local function Choose(value)
            if multi then
                -- A new table: what is kept compares it with the one before.
                local chosen = get()
                chosen = Core.Copy(type(chosen) == "table" and chosen or {})
                chosen[value] = not chosen[value] or nil
                value = chosen
            end
            Core.Safe("Settings: " .. text, set, value)
            Panel.Refresh(owner[menu])
        end
        for _, choice in ipairs(option.choices) do
            if multi then
                root:CreateCheckbox(choice[2], IsChosen, Choose, choice[1])
            else
                root:CreateRadio(choice[2], IsChosen, Choose, choice[1])
            end
        end
    end)
    menu.label, menu.get, menu.set = text, get, set
    Tooltip(menu, text, tip)
    function menu:Refresh()
        self:GenerateMenu()
        if enabled then self:SetEnabled(enabled() and true or false) end
    end
    Keep(menu)
    return menu
end

-- Words, or a number (option.default is one), typed into the game's input box: Enter sets them, Esc
-- or a click elsewhere leaves the value as it was. A number is kept within option.min and max, on its
-- step (Panel.Number), its unit written right of the box. get() its value, set(value) when entered,
-- enabled() whether it can be.
function Panel.Edit(parent, text, tip, option, get, set, enabled)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    local number = type(option.default) == "number"
    box:SetSize(number and 70 or 214, 20)
    box:SetAutoFocus(false)
    if number and option.unit then
        local unit = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        unit:SetPoint("LEFT", box, "RIGHT", 8, 0)
        unit:SetText(option.unit)
    end
    box.label, box.get, box.set = text, get, set
    box:SetScript("OnEnterPressed", function(self)
        local value = self:GetText() or ""
        if number then value = Panel.Number(option, value) end
        if value ~= nil and value ~= get() then Core.Safe("Settings: " .. text, set, value) end
        self:ClearFocus()
        Panel.Refresh(owner[self])
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- Left without Enter (Esc, a click elsewhere): the value as it is.
    box:HookScript("OnEditFocusLost", function(self) self:SetText(Panel.Written(option, get())) end)
    Tooltip(box, text, tip)
    function box:Refresh()
        if not self:HasFocus() then self:SetText(Panel.Written(option, get())) end
        if enabled then self:SetEnabled(enabled() and true or false) end
    end
    Keep(box)
    return box
end

-- A colour written as six hex digits ("26262B"), and back (Core's); one that cannot be read is white.
Panel.Hex = Core.Hex

function Panel.RGB(hex)
    local r, g, b = Core.RGB(hex)
    if not r then return 1, 1, 1 end
    return r, g, b
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
    function swatch:Refresh()
        self:SetColorRGB(Panel.RGB(get()))
        local on = not enabled or enabled()
        self:SetEnabled(on and true or false)
        self:SetAlpha(on and 1 or 0.4) -- greyed out, as a control that cannot be used now
    end
    Keep(swatch)
    return swatch
end

-- A button with its words. click() when clicked; enabled() whether it can be; width (100 if not given).
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
    Keep(button)
    return button
end

-- Something else that shows a value: label names it, Refresh shows it anew; its page is found from
-- its widget.
function Panel.Watch(control)
    Keep(control, control.widget)
end
