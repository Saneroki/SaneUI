local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  SaneUI - Core - Settings - Screen
--  SaneUI's options on a full screen, besides the game's own (Esc > Options >
--  AddOns > SaneUI): the button with the game's cog in a full window's title
--  bar (Window.lua) puts this view over what the window holds. Pressed again,
--  Esc, or the window going back, and it goes.
--
--      at the left   SaneUI's pages as the game's options list them: General and
--                    Appearance, then a page for each module that is switched on and
--                    has switches; in the look of the game's own list of pages (the
--                    one chosen lit by its bar). The window's own module is chosen
--                    first; the page last chosen is kept for the session
--      at the right  the chosen page, drawn as a page of our own in the game's options
--                    is (Tabbed.lua): its title, the search box and Defaults, its
--                    switches in tabs; built the first time it is chosen
--      at the foot   the game's options at SaneUI, for what is only there (Profiles,
--                    the game's own settings): the window goes back first
--
--  A change goes through Core.Set as on the game's pages, which show it too
--  (Config.Refresh). The view covers what the window holds, dark, and takes the
--  mouse and its wheel: nothing behind it is clicked or scrolled. It stands in
--  the game's layer DIALOG, over the windows that stand over a full screen (the
--  map's quest log); the game's dialogs, menus and tooltips stand over it. While
--  it is there, Esc takes it away, not the full screen. One per window, made the
--  first time its cog is pressed.
--
--      Config.Screen.Toggle(window)   -- the view on or off
--      Config.Screen.Close(window)    -- off (the window goes back: Window:Refresh)
--      Config.Screen.Shown(window)
-------------------------------------------------------------------------------
local Core = SaneUI.Core

local Screen = {}
Config.Screen = Screen

Screen.WIDTH, Screen.HEIGHT = 1000, 780 -- the plate at most; less on a smaller screen
Screen.PAD = 24          -- the plate from the view's edges
Screen.LIST = 200        -- the list of pages
Screen.ROW = 24          -- a page in it
Screen.LEVEL = 100       -- the view over the window's own levels (the map's pins and models reach far up)
Screen.STRATA = "DIALOG"
Screen.COVER = { 0.02, 0.02, 0.025, 0.97 } -- the dark over what the window holds
Screen.TEXT = {
    title = Core.TITLE or "SaneUI",
    general = type(GENERAL) == "string" and GENERAL or "General",
    appearance = "Appearance",
    modules = "Modules",
    all = "All options",
    allTip = "The game's options at SaneUI (Esc > Options > AddOns): there too Profiles and the game's own settings. The full screen goes back first.",
}

local screens = {} -- [window] = its view, once made

-- The module whose settings the window reads (its option edge), by the table Core holds for it.
local function Module(window)
    local settings = window.options.edge
    if type(settings) ~= "table" then return nil end
    for _, name in ipairs(Core.optionOrder) do
        if name ~= Core.name and Core.Settings(name) == settings then return name end
    end
    return nil
end

-- Whether a page has a switch with a control (Config.Kind) on it.
local function Controls(name, onPage)
    for _, option in ipairs(Core.described[name] and Core.described[name].list or {}) do
        if option.page == onPage and Config.Kind(option) then return true end
    end
    return false
end

-- The pages as the game's options have them under SaneUI (Settings.lua, PutUpPages), but Profiles: a page
-- is { key, name, page, title, module }.
local function Pages()
    local pages = {}
    for _, own in ipairs({ { nil, Screen.TEXT.general }, { "Appearance", Screen.TEXT.appearance } }) do
        if Controls(Core.name, own[1]) then
            pages[#pages + 1] = { key = own[2], name = Core.name, page = own[1], title = own[2] }
        end
    end
    for _, name in ipairs(Core.optionOrder) do
        local module = SaneUI[name]
        if module and name ~= Core.name and Controls(name, nil) then
            pages[#pages + 1] = { key = name, name = name, title = module.title or name, module = true }
        end
    end
    return pages
end

-------------------------------------------------------------------------------
--  The list of pages
-------------------------------------------------------------------------------
local Choose -- below

-- A row in the look of the game's list of pages (SettingsCategoryListButtonTemplate): white words, the one
-- chosen lit by its bar (Options_List_Active), the mouse over one by its paler one (Options_List_Hover).
local function Row(screen, parent, page, y)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(Screen.LIST, Screen.ROW)
    row:SetPoint("TOPLEFT", 0, y)
    row.bar = row:CreateTexture(nil, "BACKGROUND")
    row.bar:SetAtlas("Options_List_Active", true)
    row.bar:SetPoint("CENTER")
    row.bar:Hide()
    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAtlas("Options_List_Hover", true)
    hover:SetPoint("CENTER")
    row.words = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.words:SetPoint("LEFT", 26, 0)
    row.words:SetPoint("RIGHT", -6, 0)
    row.words:SetJustifyH("LEFT")
    row.words:SetText(page.title)
    row:SetScript("OnClick", Core.Guard("options", function()
        Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
        Choose(screen, page.key)
    end))
    return row
end

-- A title over a part of the list, as the game's list has them.
local function Title(parent, text, y)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, y)
    title:SetText(text)
    return title
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
-- A page on show, built if it never was, its row lit; kept as the one to show next time.
function Choose(screen, key)
    local found
    for _, page in ipairs(screen.pages) do
        if page.key == key then found = page end
    end
    found = found or screen.pages[1]
    if not found then return end
    screen.chosen = found.key
    if not screen.built[found.key] then
        local frame = CreateFrame("Frame", nil, screen.holder)
        frame:SetAllPoints()
        frame:Hide()
        screen.built[found.key] = frame
        Core.Safe("Settings: " .. found.key, Config.BuildTabbed, frame, found.name, found.page, found.title)
    end
    for page, frame in pairs(screen.built) do frame:SetShown(page == found.key) end
    for page, row in pairs(screen.rows) do row.bar:SetShown(page == found.key) end
end

-- The plate as large as the view lets it be, at most Screen.WIDTH by Screen.HEIGHT, in its middle.
local function Sized(screen)
    local view = screen.view
    local width, height = view:GetWidth() or 0, view:GetHeight() or 0
    screen.plate:SetSize(math.max(math.min(width - 2 * Screen.PAD, Screen.WIDTH), 1),
        math.max(math.min(height - 2 * Screen.PAD, Screen.HEIGHT), 1))
    if screen.plate.skin and screen.plate.skin.Rest then screen.plate.skin:Rest() end
end

-- The game's options at SaneUI, the full screen gone back first (it stands over them).
local function All(screen)
    local edge = screen.window.edge
    if edge and edge.full then edge:Fill(false) end
    Config.Open()
end

local function Make(window)
    local frame = window.frame
    local screen = { window = window, built = {}, rows = {}, pages = Pages() }
    local view = CreateFrame("Frame", nil, frame)
    view:SetFrameStrata(Screen.STRATA)
    view:SetFrameLevel(frame:GetFrameLevel() + Screen.LEVEL)
    view:SetPoint("TOPLEFT", window.inside, "TOPLEFT")
    view:SetPoint("BOTTOMRIGHT", window.inside, "BOTTOMRIGHT")
    view:EnableMouse(true)       -- nothing behind it clicked
    view:EnableMouseWheel(true)  -- nor scrolled (the map's zoom)
    view:Hide()
    local cover = view:CreateTexture(nil, "BACKGROUND")
    cover:SetAllPoints()
    cover:SetColorTexture(Screen.COVER[1], Screen.COVER[2], Screen.COVER[3], Screen.COVER[4])
    screen.view = view

    local plate = CreateFrame("Frame", nil, view)
    plate:SetPoint("CENTER")
    plate.skin = Core.Skin.New(plate, { radius = Core.Board and Core.Board.RADIUS or 8 })
    screen.plate = plate

    -- The list at the left: SaneUI's own pages, then the modules'; the way to the game's options at its foot.
    local list = CreateFrame("Frame", nil, plate)
    list:SetPoint("TOPLEFT", 8, -12)
    list:SetPoint("BOTTOMLEFT", 8, 12)
    list:SetWidth(Screen.LIST)
    local y = 0
    Title(list, Screen.TEXT.title, y)
    y = y - 30
    local modules = false
    for _, page in ipairs(screen.pages) do
        if page.module and not modules then
            modules = true
            y = y - 10
            Title(list, Screen.TEXT.modules, y)
            y = y - 30
        end
        screen.rows[page.key] = Row(screen, list, page, y)
        y = y - Screen.ROW
    end
    local all = Config.Panel.Button(list, Screen.TEXT.all, Screen.TEXT.allTip, function() All(screen) end, nil,
        Screen.LIST - 24)
    all:SetPoint("BOTTOM", 0, 4)
    local line = plate:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.35)
    line:SetPoint("TOPLEFT", list, "TOPRIGHT", 8, 0)
    line:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 8, 0)
    line:SetWidth(1)

    -- The chosen page at the right.
    local holder = CreateFrame("Frame", nil, plate)
    holder:SetPoint("TOPLEFT", line, "TOPRIGHT", 8, 0)
    holder:SetPoint("BOTTOMRIGHT", -8, 12)
    screen.holder = holder

    view:SetScript("OnSizeChanged", Core.Guard("options", function() Sized(screen) end))
    -- The window closed (a panel Esc closes, full as it is): the view goes with it, not to come back on the small one.
    frame:HookScript("OnHide", Core.Guard("options", function() Screen.Close(window) end))
    local module = Module(window)
    screen.chosen = module and screen.rows[module] and module or nil
    screens[window] = screen
    return screen
end

-- Esc takes the view away while it is there, not the full screen; the full screen's Esc again once it has gone.
local function Escaped(screen)
    Screen.Close(screen.window)
end

function Screen.Shown(window)
    local screen = screens[window]
    return screen and screen.view:IsShown() or false
end

function Screen.Close(window)
    local screen = screens[window]
    if not screen or not screen.view:IsShown() then return end
    screen.view:Hide()
    if Core.Unsaved then Core.Unsaved.Close(screen) end -- a menu for the save window (Unsaved.lua)
    Core.Escape(screen, nil)
    window:Escapes(true) -- Esc is the window's again (Window.lua: a panel's close, else its full screen's way back)
    if window.settings then window.settings:UnlockHighlight() end
end

function Screen.Toggle(window)
    if Screen.Shown(window) then return Screen.Close(window) end
    local screen = screens[window] or Make(window)
    screen.view:Show()
    if Core.Unsaved then Core.Unsaved.Open(screen, screen.view) end
    Sized(screen)
    Choose(screen, screen.chosen)
    window:Escapes(false)
    Core.Escape(screen, Escaped)
    if window.settings then window.settings:LockHighlight() end
end
