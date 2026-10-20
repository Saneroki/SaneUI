local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - TopBar
--  The bar over the full map's top edge, left to right:
--
--      Quest Log         the quest log at the map's left in or out (kept)
--      the views         Parchment, Scrying and Atlas while its module is there: how the map is drawn
--                        (the setting Map view; Navigation.lua, Offer)
--      the map selector  the world, a continent or a plane of its own (Zephras Isle), then a zone of it (A to
--                        Z): the map shows it whole; each says what the map shows now
--      Pins              the pin filter: a checkbox per kind of pin (the setting Pins on the map), and at
--                        its right a slider for that kind's size (the setting pinSizes, kept per profile)
--
--  Only while the window fills the screen; the game's own menus (WowStyle1DropdownTemplate,
--  Blizzard's menu system) for the dropdowns.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local TopBar = {}
ns.TopBar = TopBar

TopBar.HEIGHT = 34
TopBar.INSET = 12    -- from the map's top left corner
TopBar.GAP = 4       -- between two buttons
TopBar.BUTTON_WIDTH, TopBar.BUTTON_HEIGHT = 110, 24
TopBar.MENU_WIDTH = 170
-- The pin filter's rows: a size slider this wide, room right of it for its words (150%), the checkbox's room left
-- of the kind's name, and the row's height.
TopBar.SIZER, TopBar.SIZE_LABEL, TopBar.CHECK, TopBar.ROW = 120, 44, 40, 26
TopBar.TEXT = {
    questLog = Core.Word("QUEST_LOG", "Quest Log"),
    questLogTip = "The quest log at the map's left, or the whole screen for the map.",
    pins = "Pins",
    world = Core.Word("WORLD", "World"),
    zones = "Zone",
}

local bar, buttons, logButton, continentMenu, zoneMenu, pinMenu
local shownMap, shownZone -- what the selector says now

-- The map's name, as the game has it.
local function Name(map)
    local info = Core.Ask(C_Map.GetMapInfo, map)
    return type(info) == "table" and info.name or ("#" .. tostring(map))
end

-- The views' buttons, as the settings say: the view drawn lit, those offered in a row.
function TopBar.Arrange()
    if not buttons then return end
    local previous = logButton
    local drawn = ns.View()
    for _, key in ipairs(ns.VIEWS) do
        local button, offered = buttons[key], ns.Offered(key)
        button:SetShown(offered)
        if offered then
            button:ClearAllPoints()
            button:SetPoint("LEFT", previous, "RIGHT", previous == logButton and TopBar.GAP * 3 or TopBar.GAP, 0)
            previous = button
        end
        if key == drawn then button:LockHighlight() else button:UnlockHighlight() end
    end
    continentMenu:ClearAllPoints()
    continentMenu:SetPoint("LEFT", previous, "RIGHT", TopBar.GAP * 3, 0)
end

local function Choose(button)
    if button.key ~= ns.options.view then Core.Set(ns.name, "view", button.key) end
end

local function Tip(button)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
    GameTooltip:SetText(button.title, 1, 1, 1)
    GameTooltip:AddLine(button.tip, nil, nil, nil, true)
    GameTooltip:Show()
end

local function ViewButton(key)
    local button = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    button:SetSize(TopBar.BUTTON_WIDTH, TopBar.BUTTON_HEIGHT)
    button:SetText(ns.TEXT.views[key])
    button.key, button.title, button.tip = key, ns.TEXT.views[key], ns.TEXT.viewTips[key]
    button:SetScript("OnClick", ns.Guard(Choose))
    button:SetScript("OnEnter", ns.Guard(Tip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- A map chosen in the selector: shown whole.
local function Go(map)
    ns.Canvas.Show(map)
end

local function Radio(root, name, map)
    root:CreateRadio(name, ns.Guard(function() return shownMap == map or shownZone == map end), ns.Guard(function() Go(map) end))
end

-- The world, then each continent and each plane of its own.
local function Continents(_, root)
    local world = Coords.WorldMap()
    if world then Radio(root, Name(world), world) end
    for _, plane in ipairs(Coords.Planes()) do Radio(root, Name(plane), plane) end
end

-- The zones of the plane shown, A to Z (a plane of its own is its own zone).
local function Zones(_, root)
    local plane = shownMap ~= Coords.WorldMap() and shownMap
    if not plane then return end
    local list = {}
    for _, zone in ipairs(Coords.Zones(plane)) do list[#list + 1] = { map = zone.map, name = Name(zone.map) } end
    table.sort(list, function(a, b) return a.name < b.name end)
    for _, zone in ipairs(list) do Radio(root, zone.name, zone.map) end
end

-- One kind of pin on or off, kept in the setting Pins on the map.
local function Switch(key)
    local chosen = {}
    for name, on in pairs(type(ns.options.pins) == "table" and ns.options.pins or {}) do chosen[name] = on end
    chosen[key] = not ns.Pins.Shows(key) or nil
    Core.Set(ns.name, "pins", chosen)
end

-- A kind's size kept, in the pin filter's steps (100 %: none kept).
local function Resize(key, value)
    local sizes = ns.PIN_SIZES
    local percent = math.floor((value - sizes.low) / sizes.step + 0.5) * sizes.step + sizes.low
    if percent == ns.PinPercent(key) then return end
    local kept = Core.Copy(type(ns.options.pinSizes) == "table" and ns.options.pinSizes or {})
    kept[key] = percent ~= 100 and percent or nil
    Core.Set(ns.name, "pinSizes", kept)
end

local OWNER = {} -- the sliders' callbacks are of this owner: a slider laid out anew replaces its last one

-- A kind's row in the pin filter with its size slider at its right (the game's slider, lent to the row by the
-- menu while it is open). Returns the row's size.
local function Sizer(button, key)
    local slider = button:AttachTemplate("MinimalSliderWithSteppersTemplate")
    local sizes, labels = ns.PIN_SIZES, MinimalSliderWithSteppersMixin.Label
    slider:SetWidth(TopBar.SIZER)
    slider:ClearAllPoints()
    slider:SetPoint("RIGHT", -TopBar.SIZE_LABEL, 0)
    slider:Init(ns.PinPercent(key), sizes.low, sizes.high, (sizes.high - sizes.low) / sizes.step,
        { [labels.Right] = function(value) return ("%d%%"):format(value) end })
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged,
        ns.Guard(function(_, value) Resize(key, value) end), OWNER)
    local text = button.fontString
    local width = (text and text:GetUnboundedStringWidth() or 100) + TopBar.CHECK + TopBar.SIZER + TopBar.SIZE_LABEL
    return width, TopBar.ROW
end

-- The pin filter: a checkbox per kind, and the size slider of each kind that has a size (the pins, the party's
-- marks, the route's line).
local SIZED = { group = true, route = true }
local function Filter(_, root)
    local sliders = rawget(_G, "MinimalSliderWithSteppersMixin") ~= nil
    for _, kind in ipairs(ns.KINDS) do
        local key = kind[1]
        local box = root:CreateCheckbox(kind[2], ns.Guard(function() return ns.Pins.Shows(key) end),
            ns.Guard(function() Switch(key) end))
        if sliders and (ns.Pins.SIZE[key] or SIZED[key]) then
            box:AddInitializer(ns.Guard(function(button) return Sizer(button, key) end))
        end
    end
end

local function Dropdown(width, generator, text)
    local menu = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    menu:SetWidth(width)
    if text then menu:OverrideText(text) end
    menu:SetupMenu(generator)
    return menu
end

-- The quest log in or out, kept for the next time the map fills the screen.
local function Log()
    ns.store.questLog = not TopBar.LogShown()
    ns.Window.Lay()
end

function TopBar.LogShown()
    return ns.store.questLog ~= false
end

-- The bar over the canvas' top edge, above the map, its pins and the game's minimap (Canvas.LEVELS).
function TopBar.Build(canvas)
    bar = CreateFrame("Frame", nil, canvas:GetParent())
    bar:SetPoint("TOPLEFT", canvas, "TOPLEFT", TopBar.INSET, -TopBar.INSET)
    bar:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", -TopBar.INSET, -TopBar.INSET)
    bar:SetHeight(TopBar.BUTTON_HEIGHT)
    bar:SetFrameLevel(canvas:GetFrameLevel() + 30)
    logButton = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    logButton:SetSize(TopBar.BUTTON_WIDTH, TopBar.BUTTON_HEIGHT)
    logButton:SetText(TopBar.TEXT.questLog)
    logButton:SetPoint("LEFT")
    logButton.title, logButton.tip = TopBar.TEXT.questLog, TopBar.TEXT.questLogTip
    logButton:SetScript("OnClick", ns.Guard(Log))
    logButton:SetScript("OnEnter", ns.Guard(Tip))
    logButton:SetScript("OnLeave", GameTooltip_Hide)
    buttons = {}
    for _, key in ipairs(ns.VIEWS) do buttons[key] = ViewButton(key) end
    continentMenu = Dropdown(TopBar.MENU_WIDTH, Continents)
    zoneMenu = Dropdown(TopBar.MENU_WIDTH, Zones)
    zoneMenu:SetPoint("LEFT", continentMenu, "RIGHT", TopBar.GAP, 0)
    pinMenu = Dropdown(TopBar.MENU_WIDTH - 40, Filter, TopBar.TEXT.pins)
    pinMenu:SetPoint("RIGHT")
    TopBar.Arrange()
    bar:Hide()
    return bar
end

-- In sight while the window fills the screen and stands there; its level over the canvas' again.
function TopBar.SetShown(on, canvas)
    if not bar then return end
    if on and canvas then bar:SetFrameLevel(canvas:GetFrameLevel() + 30) end
    bar:SetShown(on)
    if on then TopBar.Update() end
end

-- The selector says what the map shows now (after every layout of the full view).
function TopBar.Update()
    if not bar or not bar:IsShown() then return end
    local camera = ns.Canvas.camera
    if not camera or not camera.map then return end
    local map = camera.level == "world" and Coords.WorldMap() or camera.map
    local zone = camera.level == "zone" and ns.Canvas.view.zone or nil
    logButton:SetButtonState(TopBar.LogShown() and "PUSHED" or "NORMAL", TopBar.LogShown())
    if map == shownMap and zone == shownZone then return end
    shownMap, shownZone = map, zone
    continentMenu:OverrideText(Name(map))
    zoneMenu:OverrideText(zone and Name(zone) or TopBar.TEXT.zones)
    zoneMenu:SetEnabled(map ~= Coords.WorldMap())
end
