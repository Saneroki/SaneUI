local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Selection
--  A window chosen in Blizzard's Edit Mode, as the game's own frames are: a
--  click on its box there selects it (the box in Edit Mode's selected look), and
--  a small dialog of Core's in the look of Edit Mode's own (the game's
--  translucent dialog border, its title in GameFontHighlightLarge, a close
--  button, its button Reset To Default Position in the game's words) names it
--  and puts it back at its first place and size (window:Reset). Our windows are
--  no systems of Blizzard's Edit Mode, so its own dialog does not know them; its
--  templates for systems (which select a frame in its manager) are not used.
--  Selecting one of the game's frames there takes ours off (a hook after the
--  manager's SelectSystem, which is only followed); closing Edit Mode closes the
--  dialog.
--
--  A window may bring settings into the dialog, as the game's own frames do,
--  a row each between its title and its button: the game's slider with its
--  steppers and the number at its right, or a field to type a number into. What
--  a row changes shows at once.
--
--      Core.Window.New(frame, { ...,
--          settings = { { key = "width", text = "Max width", min = 100, max = 1600, step = 10 },
--                       { key = "count", text = "Preview", min = 0, max = 40, input = true } },
--          get = function(key) return value end,  set = function(key, value) end })
--
--      Core.Selection.Select(window)   Core.Selection.Clear()   Core.Selection.window
-------------------------------------------------------------------------------
local Selection = {}
Core.Selection = Selection

Selection.WIDTH, Selection.BUTTON = 370, 28 -- the dialog's width and its button's height, as Edit Mode's
Selection.PADDING = 20                      -- from its sides, as Edit Mode's (half of its widthPadding)
Selection.LEVEL = 200                       -- above what Edit Mode shows, as its own dialog (DIALOG, 200)
Selection.ROW, Selection.LABEL = 34, 130    -- a setting's row: its height, and how wide its word is
Selection.NUMBER, Selection.FIELD = 44, 64  -- the room for a slider's number at its right, a field's width
-- Where the dialog stands at first: where Edit Mode's own stands for a frame that names no other place.
Selection.ANCHOR = { "BOTTOMRIGHT", -250, 200 }
local TEXT = { reset = Core.Word("HUD_EDIT_MODE_RESET_POSITION", "Reset To Default Position") }

local dialog

-- Whether the window stands where it was at first: nothing of its place is kept.
local function Default(window)
    local place = window.options.store[window.options.key or "place"]
    return type(place) ~= "table" or type(place.x) ~= "number"
end

-- The dialog's height with that many rows.
local function Height(rows)
    return Selection.PADDING * 2 + 24 + 12 + Selection.BUTTON + (rows or 0) * Selection.ROW
end

-- A setting's new value, within its limits and on its steps.
local function Put(window, setting, value)
    value = tonumber(value)
    if not value then return end
    local step = setting.step or 1
    value = math.floor(value / step + 0.5) * step
    window.options.set(setting.key, math.max(math.min(value, setting.max), setting.min))
end

-- A row's slider: the game's, with its steppers and the number at its right.
local function Slider(row, setting, window)
    local mixin = rawget(_G, "MinimalSliderWithSteppersMixin")
    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("LEFT", row, "LEFT", Selection.LABEL, 0)
    slider:SetPoint("RIGHT", row, "RIGHT", -Selection.NUMBER, 0)
    slider:Init(window.options.get(setting.key), setting.min, setting.max, (setting.max - setting.min) / (setting.step or 1),
        { [mixin.Label.Right] = function(value) return tostring(math.floor(value + 0.5)) end })
    slider:RegisterCallback(mixin.Event.OnValueChanged, Core.Guard("Edit Mode", function(_, value)
        Put(window, setting, value)
    end), row)
    return function() slider:SetValue(window.options.get(setting.key)) end
end

-- A row's field: a number typed in, taken as it is typed; Enter or Esc let the field go.
local function Field(row, setting, window)
    local box = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    box:SetSize(Selection.FIELD, 22)
    box:SetPoint("RIGHT", row, "RIGHT", -Selection.NUMBER, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(#tostring(setting.max))
    box:SetJustifyH("CENTER")
    local function Shown()
        box:SetText(tostring(window.options.get(setting.key)))
        box:SetCursorPosition(0)
    end
    box:SetScript("OnTextChanged", Core.Guard("Edit Mode", function(_, typed)
        if typed then Put(window, setting, box:GetText()) end
    end))
    local done = Core.Guard("Edit Mode", function() box:ClearFocus() end)
    box:SetScript("OnEnterPressed", done)
    box:SetScript("OnEscapePressed", done)
    box:SetScript("OnEditFocusLost", Core.Guard("Edit Mode", Shown))
    return Shown
end

-- The rows of a window's settings, made when it is first chosen; each row's way to show its value anew.
local function Rows(window)
    if window.settingRows then return window.settingRows end
    local rows = CreateFrame("Frame", nil, dialog)
    rows:SetPoint("TOPLEFT", dialog, "TOPLEFT", Selection.PADDING, -(Selection.PADDING + 24))
    rows:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -Selection.PADDING, -(Selection.PADDING + 24))
    rows:SetHeight(#window.options.settings * Selection.ROW)
    rows.shows = {}
    for index, setting in ipairs(window.options.settings) do
        local row = CreateFrame("Frame", nil, rows)
        row:SetHeight(Selection.ROW)
        row:SetPoint("TOPLEFT", rows, "TOPLEFT", 0, -(index - 1) * Selection.ROW)
        row:SetPoint("TOPRIGHT", rows, "TOPRIGHT", 0, -(index - 1) * Selection.ROW)
        local word = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        word:SetPoint("LEFT", row, "LEFT", 0, 0)
        word:SetWidth(Selection.LABEL)
        word:SetJustifyH("LEFT")
        word:SetText(setting.text)
        local sliders = rawget(_G, "MinimalSliderWithSteppersMixin") ~= nil
        rows.shows[index] = (setting.input or not sliders) and Field(row, setting, window) or Slider(row, setting, window)
    end
    window.settingRows = rows
    return rows
end

-- The button can do something only for a window that was moved or sized.
local function Update()
    local window = Selection.window
    if not (dialog and window) then return end
    dialog.title:SetText(window.options.title or "")
    dialog.reset:SetEnabled(not Default(window))
    local settings = window.options.settings
    if settings then
        for _, show in ipairs(Rows(window).shows) do Core.Safe("Edit Mode", show) end
    end
    dialog:SetHeight(Height(settings and #settings))
end

local function Dialog()
    if dialog then return dialog end
    dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(Selection.LEVEL)
    dialog:SetSize(Selection.WIDTH, Height())
    dialog:SetPoint(Selection.ANCHOR[1], UIParent, Selection.ANCHOR[1], Selection.ANCHOR[2], Selection.ANCHOR[3])
    dialog:SetClampedToScreen(true)
    dialog:EnableMouse(true)
    -- Dragged by itself, as Edit Mode's; where it was dragged is not kept.
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", Core.Guard("Edit Mode", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(false)
    end))
    local ok, border = pcall(CreateFrame, "Frame", nil, dialog, "DialogBorderTranslucentTemplate")
    if ok and border then border:SetAllPoints() end
    local title = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButtonNoScripts")
    close:SetPoint("TOPRIGHT")
    close:SetScript("OnClick", Core.Guard("Edit Mode", Selection.Clear))
    local reset = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    reset:SetSize(Selection.WIDTH - 2 * Selection.PADDING, Selection.BUTTON)
    reset:SetPoint("BOTTOM", 0, Selection.PADDING)
    reset:SetText(TEXT.reset)
    reset:SetScript("OnClick", Core.Guard("Edit Mode", function()
        local window = Selection.window
        if window then Core.Safe("Edit Mode", window.Reset, window) end
        Update()
    end))
    dialog.title, dialog.reset = title, reset
    dialog:Hide()
    return dialog
end

-- The window chosen: its box in the selected look, the dialog for it. The one chosen before is not any more.
function Selection.Select(window)
    if Selection.window == window then return Update() end
    Selection.Clear()
    Selection.window = window
    window:Selected(true)
    Dialog():Show()
    if window.settingRows then window.settingRows:Show() end
    Update()
end

function Selection.Clear()
    local window = Selection.window
    Selection.window = nil
    if window then window:Selected(false) end
    if window and window.settingRows then window.settingRows:Hide() end
    if dialog then dialog:Hide() end
end

-- A window let go or sized while it is chosen: the dialog says whether it is at its first place now.
function Selection.Moved(window)
    if Selection.window == window then Update() end
end

Core.EditMode.Watch(function(on)
    if not on then Selection.Clear() end
end)

-- One of the game's own frames chosen in Edit Mode: ours is not any more (the manager is followed, not
-- written).
Core.On("PLAYER_LOGIN", function()
    local manager = rawget(_G, "EditModeManagerFrame")
    if manager and type(manager.SelectSystem) == "function" then
        hooksecurefunc(manager, "SelectSystem", function() Core.Safe("Edit Mode", Selection.Clear) end)
    end
end)
