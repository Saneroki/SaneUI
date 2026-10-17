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
--      Core.Selection.Select(window)   Core.Selection.Clear()   Core.Selection.window
-------------------------------------------------------------------------------
local Selection = {}
Core.Selection = Selection

Selection.WIDTH, Selection.BUTTON = 370, 28 -- the dialog's width and its button's height, as Edit Mode's
Selection.PADDING = 20                      -- from its sides, as Edit Mode's (half of its widthPadding)
Selection.LEVEL = 200                       -- above what Edit Mode shows, as its own dialog (DIALOG, 200)
-- Where the dialog stands at first: where Edit Mode's own stands for a frame that names no other place.
Selection.ANCHOR = { "BOTTOMRIGHT", -250, 200 }
local TEXT = { reset = Core.Word("HUD_EDIT_MODE_RESET_POSITION", "Reset To Default Position") }

local dialog

-- Whether the window stands where it was at first: nothing of its place is kept.
local function Default(window)
    local place = window.options.store[window.options.key or "place"]
    return type(place) ~= "table" or type(place.x) ~= "number"
end

-- The button can do something only for a window that was moved or sized.
local function Update()
    local window = Selection.window
    if not (dialog and window) then return end
    dialog.title:SetText(window.options.title or "")
    dialog.reset:SetEnabled(not Default(window))
end

local function Dialog()
    if dialog then return dialog end
    dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(Selection.LEVEL)
    dialog:SetSize(Selection.WIDTH, Selection.PADDING * 2 + 24 + 12 + Selection.BUTTON)
    dialog:SetPoint(Selection.ANCHOR[1], UIParent, Selection.ANCHOR[1], Selection.ANCHOR[2], Selection.ANCHOR[3])
    dialog:SetClampedToScreen(true)
    dialog:EnableMouse(true)
    -- Dragged by itself, as Edit Mode's; where it was dragged is not kept.
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(false)
    end)
    local ok, border = pcall(CreateFrame, "Frame", nil, dialog, "DialogBorderTranslucentTemplate")
    if ok and border then border:SetAllPoints() end
    local title = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButtonNoScripts")
    close:SetPoint("TOPRIGHT")
    close:SetScript("OnClick", function() Core.Safe("Edit Mode", Selection.Clear) end)
    local reset = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    reset:SetSize(Selection.WIDTH - 2 * Selection.PADDING, Selection.BUTTON)
    reset:SetPoint("BOTTOM", 0, Selection.PADDING)
    reset:SetText(TEXT.reset)
    reset:SetScript("OnClick", function()
        local window = Selection.window
        if window then Core.Safe("Edit Mode", window.Reset, window) end
        Update()
    end)
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
    Update()
end

function Selection.Clear()
    local window = Selection.window
    Selection.window = nil
    if window then window:Selected(false) end
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
