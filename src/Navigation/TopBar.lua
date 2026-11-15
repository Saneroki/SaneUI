local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - TopBar
--  The full map's controls, in its title bar (Core's, standing over the map, which reaches up behind it;
--  Saneroki, 2026-11-15: "Put the dropdown for the zones, dungeons and pins and the questlog, blended scrying into
--  the titlebar"), left to right:
--
--      Quest Log         the quest log on or off, over the map and on the screen alone (kept; QuestLog.lua)
--      Zone              every continent (the map shows it whole) and under it its zones (A to Z); it says the zone
--                        the map shows now
--      Dungeons          every dungeon and raid the game has a map of (A to Z): its map over the map
--                        (Dungeons.lua); beside it, while one with floors shows, its floors
--      ... the map's search in the room between (FindBox.lua) ...
--      the view          one button: Blended and Scrying in turn (Saneroki: "Blended and scrying will be one button
--                        that just toggles the map views"), its words the view drawn; Parchment only in the
--                        settings (the setting Map view); none where only one view is offered (ns.Several)
--      Sketches          a dropdown: every sketch with its checkbox (shown) and its own menu, Draw on the map,
--                        New sketch (DrawBar.lua; in place of the pencil button: Saneroki, 2026-11-15)
--      Follow me         a checkbox: the map keeps you in its middle as you move and comes back to you, small and
--                        full (the setting followMap; Canvas.lua), on at first
--      Pins              the pin filter, in sections under their titles (ns.PIN_SECTIONS: around you, quests,
--                        travel, towns, rares and treasures, gathering): a checkbox per kind of pin with its
--                        icon large before its words (the setting Pins on the map), and at its right a slider
--                        for that kind's size (the quest areas': their opacity; the setting pinSizes, kept per
--                        profile)
--      ... Core's dropdown Classic windows and its buttons at the bar's right
--
--  Only while the window fills the screen; made the first time it does (the title bar is Core's, made then). A
--  soft shade from the screen's top down past the bar keeps its words readable over any map. The game's own menus
--  (WowStyle1DropdownTemplate, Blizzard's menu system) for the dropdowns.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local TopBar = {}
ns.TopBar = TopBar

TopBar.INSET = 8     -- from the title bar's left edge
TopBar.GAP = 4       -- between two controls
TopBar.BUTTON_WIDTH, TopBar.BUTTON_HEIGHT = 96, 24
TopBar.VIEW_WIDTH = 84 -- the view's button: its one word
TopBar.MENU_WIDTH = 160
TopBar.PINS_WIDTH = 90 -- the pin filter's dropdown: Pins
TopBar.SHADE = 18    -- units the shade reaches below the title bar
TopBar.SHADE_ALPHA = 0.6
-- The pin filter's rows: a size slider this wide, room right of it for its words (150%), the checkbox's room left
-- of the kind's name, the row's height, and its icon's size.
TopBar.SIZER, TopBar.SIZE_LABEL, TopBar.CHECK, TopBar.ROW, TopBar.ICON = 120, 44, 40, 30, 24
TopBar.TEXT = {
    questLog = Core.Word("QUEST_LOG", "Quest Log"),
    questLogTip = "The quest log on or off: over the map, and on the screen while the map is small.",
    pins = "Pins",
    follow = ns.TEXT.followMap,
    followTip = ns.TEXT.followMapTip,
    world = Core.Word("WORLD", "World"),
    zones = "Zone",
    viewNext = "Click: %s.",
}
TopBar.DUNGEON_WIDTH, TopBar.FLOOR_WIDTH = 140, 110 -- narrower: the bar fits a screen 1366 units wide
TopBar.LIST_HEIGHT = 440 -- the dungeons' list scrolls past so high

local bar, viewButton, logButton, zoneMenu, dungeonMenu, floorMenu, pinMenu, followBox, draw, gap
local shownMap, shownZone -- what the selector says now
local shownFloor          -- the dungeon's floor the bar says is shown

-- The map's name, as the game has it.
local function Name(map)
    local info = Core.Ask(C_Map.GetMapInfo, map)
    return type(info) == "table" and info.name or ("#" .. tostring(map))
end

-- The room the title bar takes at the top of the full map (for what stands under it: the zone's name, a dungeon's floor,
-- the palette): the bar stands over the map.
function TopBar.Top()
    return Core.Window.BAR
end

-- The room between the controls at the bar's left and those at its right (FindBox.lua: the search there); nil before
-- the bar is made.
function TopBar.Gap()
    return gap
end

-- The view the button goes to: Blended and Scrying in turn (from Parchment, Scrying).
local function Other(view)
    return view == "terrain" and "blend" or "terrain"
end

-- The view's button as the settings say: the view drawn its words; only while both Blended and Scrying are offered.
function TopBar.Arrange()
    if not viewButton then return end
    local offered = ns.Several() and ns.Offered("blend") and ns.Offered("terrain")
    viewButton:SetShown(offered and true or false)
    local drawn = ns.View()
    viewButton:SetText(ns.TEXT.views[drawn] or drawn)
    viewButton.title = ns.TEXT.views[drawn] or drawn
    viewButton.tip = (ns.TEXT.viewTips[drawn] or "") .. "\n\n" .. TopBar.TEXT.viewNext:format(ns.TEXT.views[Other(drawn)] or "")
    draw:ClearAllPoints()
    if offered then draw:SetPoint("RIGHT", viewButton, "LEFT", -TopBar.GAP * 2, 0)
    else draw:SetPoint("RIGHT", followBox, "LEFT", -TopBar.GAP * 3, 0) end
    if offered then
        viewButton:ClearAllPoints()
        viewButton:SetPoint("RIGHT", followBox, "LEFT", -TopBar.GAP * 3, 0)
    end
end

local function Toggle()
    Core.Set(ns.name, "view", Other(ns.View()))
    TopBar.Arrange()
end

local function Tip(button)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
    GameTooltip:SetText(button.title, 1, 1, 1)
    GameTooltip:AddLine(button.tip, nil, nil, nil, true)
    GameTooltip:Show()
end

-- A map chosen in the selector: shown whole (a dungeon's view that shows goes).
local function Go(map)
    ns.Dungeons.Close()
    ns.Canvas.Show(map)
end

local function Radio(root, name, map)
    root:CreateRadio(name, ns.Guard(function() return not shownFloor and (shownMap == map or shownZone == map) end),
        ns.Guard(function() Go(map) end))
end

-- Every dungeon and raid, A to Z: its map over the map; ticked while it shows.
local function DungeonList(_, root)
    if root.SetScrollMode then root:SetScrollMode(TopBar.LIST_HEIGHT) end -- a long list: scrolled
    for _, entry in ipairs(ns.Dungeons.List()) do
        root:CreateRadio(entry.name, ns.Guard(function() return entry.floors == select(2, ns.Dungeons.Shown()) end),
            ns.Guard(function() ns.Dungeons.Show(entry.map) end))
    end
end

-- The floors of the dungeon shown, lowest first.
local function FloorList(_, root)
    local _, floors = ns.Dungeons.Shown()
    for index, floor in ipairs(floors or {}) do
        root:CreateRadio(floor.name or tostring(index), ns.Guard(function() return shownFloor == floor.map end),
            ns.Guard(function() ns.Dungeons.Show(floor.map) end))
    end
end

-- Every continent (and a plane of its own, Zephras Isle; the map of the world in Retail over them; the continents
-- beside the world map, Retail's Outland and the rest) shown whole by a click, each with its zones under it, A to Z
-- (the dropdown of continents went: Saneroki, 2026-11-15).
local function Zones(_, root)
    if root.SetScrollMode then root:SetScrollMode(TopBar.LIST_HEIGHT) end -- a long list: scrolled
    local world, top = Coords.WorldMap(), Coords.Top()
    if top and top ~= world and Coords.Box(top) then Radio(root, Name(top), top) end
    if world then Radio(root, Name(world), world) end
    local planes = {}
    for _, plane in ipairs(Coords.Planes()) do planes[#planes + 1] = plane end
    for _, plane in ipairs(Coords.Elsewhere()) do planes[#planes + 1] = plane end
    for _, plane in ipairs(planes) do
        root:CreateDivider()
        Radio(root, Name(plane), plane)
        local list = {}
        for _, zone in ipairs(Coords.Zones(plane)) do
            if zone.map ~= plane then list[#list + 1] = { map = zone.map, name = Name(zone.map) } end
        end
        table.sort(list, function(a, b) return a.name < b.name end)
        for _, zone in ipairs(list) do Radio(root, "   " .. zone.name, zone.map) end
    end
end

-- A kind's size kept, in the pin filter's steps (100 %: none kept).
local function Resize(key, value)
    local sizes = ns.PinRange(key)
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
    local sizes, labels = ns.PinRange(key), MinimalSliderWithSteppersMixin.Label
    slider:SetWidth(TopBar.SIZER)
    slider:ClearAllPoints()
    slider:SetPoint("RIGHT", -TopBar.SIZE_LABEL, 0)
    -- The menu's sliders are its pool's: one that showed another kind's size still has our callback for that kind,
    -- which its Init would tell this kind's size. Let go first.
    slider:UnregisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, OWNER)
    slider:Init(ns.PinPercent(key), sizes.low, sizes.high, (sizes.high - sizes.low) / sizes.step,
        { [labels.Right] = function(value) return ("%d%%"):format(value) end })
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged,
        ns.Guard(function(_, value) Resize(key, value) end), OWNER)
    local text = button.fontString
    local width = (text and text:GetUnboundedStringWidth() or 100) + TopBar.CHECK + TopBar.SIZER + TopBar.SIZE_LABEL
    return width, TopBar.ROW
end

-- A row without a slider as tall as those with one, room for its large icon.
local function Tall(button)
    local text = button.fontString
    return (text and text:GetUnboundedStringWidth() or 100) + TopBar.CHECK, TopBar.ROW
end

-- The pin filter: its sections, each under its title and a line between them; in each a checkbox per kind with its
-- icon before its words, and the size slider of each kind that has a size (the pins, the party's marks, the route's
-- line); the quest areas' slider is their opacity. A kind of no known section comes last; one that can show nothing
-- here (only Core's data has it, and that is not there: ns.KindOffered) is left out, and a section left empty with it.
local SIZED = { group = true, route = true, area = true }
local function Filter(_, root)
    local sliders = rawget(_G, "MinimalSliderWithSteppersMixin") ~= nil
    -- Scrolled only where the screen is lower than the list (the game's menu scrolls past that height alone).
    local room = (tonumber(UIParent:GetHeight()) or 0) - TopBar.Top() - 2 * TopBar.INSET
    if root.SetScrollMode then root:SetScrollMode(math.max(TopBar.LIST_HEIGHT, room)) end
    local known, sections = {}, {}
    for index, section in ipairs(ns.PIN_SECTIONS) do
        known[section[1]] = index
        sections[index] = { title = section[2] }
    end
    local rest = {}
    for _, kind in ipairs(ns.KINDS) do
        local section = sections[known[kind.section]] or rest
        if ns.KindOffered(kind) then section[#section + 1] = kind end
    end
    sections[#sections + 1] = rest
    local first = true
    for _, section in ipairs(sections) do
        if #section > 0 then
            if not first then root:CreateDivider() end
            first = false
            if section.title then root:CreateTitle(section.title) end
            for _, kind in ipairs(section) do
                local key = kind[1]
                local box = root:CreateCheckbox(ns.KindLabel(kind, TopBar.ICON),
                    ns.Guard(function() return ns.Pins.Shows(key) end), ns.Guard(function() ns.SwitchPin(key) end))
                if sliders and (ns.Pins.SIZE[key] or SIZED[key]) then
                    box:AddInitializer(ns.Guard(function(button) return Sizer(button, key) end))
                else
                    box:AddInitializer(ns.Guard(Tall))
                end
            end
        end
    end
end

local function Dropdown(width, generator, text)
    local menu = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    menu:SetHeight(TopBar.BUTTON_HEIGHT)
    menu:SetWidth(width)
    if text then menu:OverrideText(text) end
    menu:SetupMenu(ns.Guard(generator)) -- made once: each dropdown is made once
    return menu
end

-- The quest log on or off, in both its looks, kept.
local function Log()
    ns.store.questLog = not TopBar.LogShown()
    ns.Window.Lay()
end

function TopBar.LogShown()
    return ns.store.questLog ~= false
end

-- The box Follow me, kept in the settings (Canvas.Following takes it in).
local function Follow(box)
    Core.Set(ns.name, "followMap", box:GetChecked() and true or false)
end

-- The box Follow me left of the pin filter, its words between them (the game's checkbox, as on the options pages).
local function FollowBox()
    local box = CreateFrame("CheckButton", nil, bar, "UICheckButtonTemplate")
    box:SetSize(TopBar.BUTTON_HEIGHT, TopBar.BUTTON_HEIGHT)
    local words = box.Text or box.text
    if type(words) == "table" then
        words:SetFontObject("GameFontHighlight")
        words:SetText(TopBar.TEXT.follow)
        words:ClearAllPoints()
        words:SetPoint("RIGHT", pinMenu, "LEFT", -TopBar.GAP * 3, 0)
        box:SetPoint("RIGHT", words, "LEFT", -TopBar.GAP, 0)
    else
        box:SetPoint("RIGHT", pinMenu, "LEFT", -TopBar.GAP * 3, 0)
    end
    box.title, box.tip = TopBar.TEXT.follow, TopBar.TEXT.followTip
    box:SetScript("OnClick", ns.Guard(Follow))
    box:SetScript("OnEnter", ns.Guard(Tip))
    box:SetScript("OnLeave", GameTooltip_Hide)
    return box
end

local function Button(width, text, title, tip, click)
    local button = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    button:SetSize(width, TopBar.BUTTON_HEIGHT)
    button:SetText(text)
    button.title, button.tip = title, tip
    button:SetScript("OnClick", ns.Guard(click))
    button:SetScript("OnEnter", ns.Guard(Tip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- The controls in the map's title bar (Core's, made the first time the map filled the screen): over what the bar holds
-- of Core's own (its title's click), the shade behind them; the right ones left of Core's Classic windows and buttons.
local function Build()
    local handle = ns.Window.handle
    local title = handle and handle.bar
    if bar or not title then return bar end
    bar = CreateFrame("Frame", nil, title)
    bar:SetAllPoints(title)
    bar:SetFrameLevel(title:GetFrameLevel() + 5)
    local shade = bar:CreateTexture(nil, "BACKGROUND")
    shade:SetPoint("TOPLEFT")
    shade:SetPoint("TOPRIGHT")
    shade:SetHeight(TopBar.Top() + TopBar.SHADE)
    shade:SetColorTexture(0, 0, 0, 1)
    if rawget(_G, "CreateColor") and shade.SetGradient then
        Core.Safe("bar", shade.SetGradient, shade, "VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, TopBar.SHADE_ALPHA))
    else
        shade:SetAlpha(TopBar.SHADE_ALPHA / 2)
    end
    -- at the left: the quest log, the zone, the dungeons and a dungeon's floors
    logButton = Button(TopBar.BUTTON_WIDTH, TopBar.TEXT.questLog, TopBar.TEXT.questLog, TopBar.TEXT.questLogTip, Log)
    logButton:SetPoint("LEFT", TopBar.INSET, 0)
    zoneMenu = Dropdown(TopBar.MENU_WIDTH, Zones, TopBar.TEXT.zones)
    zoneMenu:SetPoint("LEFT", logButton, "RIGHT", TopBar.GAP * 2, 0)
    dungeonMenu = Dropdown(TopBar.DUNGEON_WIDTH, DungeonList, ns.Dungeons.TEXT.dungeons)
    dungeonMenu:SetPoint("LEFT", zoneMenu, "RIGHT", TopBar.GAP, 0)
    floorMenu = Dropdown(TopBar.FLOOR_WIDTH, FloorList, ns.Dungeons.TEXT.floor)
    floorMenu:SetPoint("LEFT", dungeonMenu, "RIGHT", TopBar.GAP, 0)
    floorMenu:Hide()
    -- at the right, left of Core's: the view, drawing and planning, Follow me, the pins
    pinMenu = Dropdown(TopBar.PINS_WIDTH, Filter, TopBar.TEXT.pins)
    followBox = FollowBox()
    viewButton = Button(TopBar.VIEW_WIDTH, "", "", "", Toggle)
    viewButton.key = "view"
    draw = ns.DrawBar.Menu(bar, TopBar.BUTTON_HEIGHT)
    -- the room between, for the search
    gap = CreateFrame("Frame", nil, bar)
    gap:SetPoint("TOP")
    gap:SetPoint("BOTTOM")
    gap:SetPoint("LEFT", floorMenu, "RIGHT", TopBar.GAP * 2, 0)
    gap:SetPoint("RIGHT", draw, "LEFT", -TopBar.GAP * 2, 0)
    TopBar.Arrange()
    bar:Hide()
    return bar
end
TopBar.Build = function() end -- (made the first time the map fills the screen: Build)

-- The pins' dropdown at the bar's right, left of Core's dropdown Classic windows (or its buttons): placed anew each
-- time the bar shows (Core lays its own out at every refresh).
local function Place()
    local handle = ns.Window.handle
    local stop = handle.edge and handle.edge.classic
    if not (stop and stop:IsShown()) then stop = handle.buttons and handle.buttons.first end
    pinMenu:ClearAllPoints()
    if stop then pinMenu:SetPoint("RIGHT", stop, "LEFT", -TopBar.GAP * 3, 0) else pinMenu:SetPoint("RIGHT", -TopBar.INSET, 0) end
end

-- In sight while the window fills the screen and stands there; made the first time.
function TopBar.SetShown(on)
    if on then Build() end
    if not bar then return end
    if not on then ns.Safe("drawings", ns.DrawBar.Hide) end -- (the palette and its tool go with the bar)
    bar:SetShown(on and true or false)
    if on then
        Place()
        TopBar.Arrange()
        TopBar.Update()
    end
end

-- The selector says what the map shows now (after every layout of the full view).
function TopBar.Update()
    if not bar or not bar:IsShown() then return end
    local camera = ns.Canvas.camera
    if not camera or not camera.map then return end
    -- (one map at a time, Retail: the world level is the map shown, Azeroth or the Cosmic map)
    local map = camera.level == "world" and (camera.shown or Coords.WorldMap()) or camera.map
    local zone = camera.level == "zone" and ns.Canvas.view.zone or nil
    logButton:SetButtonState(TopBar.LogShown() and "PUSHED" or "NORMAL", TopBar.LogShown())
    followBox:SetChecked(ns.options.followMap and true or false)
    local floor, floors = ns.Dungeons.Shown()
    if floor ~= shownFloor then
        shownFloor = floor
        dungeonMenu:OverrideText(floor and (floors.name or Name(floors[1].map)) or ns.Dungeons.TEXT.dungeons)
        local named
        for _, each in ipairs(floors or {}) do if each.map == floor then named = each.name end end
        floorMenu:OverrideText(named or ns.Dungeons.TEXT.floor)
        floorMenu:SetShown(floors and #floors > 1 or false)
        -- the search's room begins after the floors while they show
        gap:SetPoint("LEFT", floorMenu:IsShown() and floorMenu or dungeonMenu, "RIGHT", TopBar.GAP * 2, 0)
    end
    if map == shownMap and zone == shownZone then return end
    shownMap, shownZone = map, zone
    zoneMenu:OverrideText(zone and Name(zone) or TopBar.TEXT.zones)
    zoneMenu:SetEnabled(camera.level ~= "world")
end
