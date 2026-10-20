local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet
--  The character sheet, our own: what the game's character window holds
--  (Camelot's CharacterFrame), in a window on the module's full screen
--  (Board.lua, the key "character"). Built from Blizzard's code for it: its
--  panes, sizes, art, words and side tabs, rewritten for our panel.
--
--      the left pane (398 wide)   the game's art; what the tab chosen shows there
--      the right pane (233 wide)  the game's art and stone; the tab's side
--      the side tabs              right of the sheet, as the game's: Character,
--                                 then each tab a file registers (Sheet.Tab)
--  The Character tab is the paper doll: a strip at the top with the level line,
--  the character's model (Model.lua) and the equipment slots round it
--  (Slots.lua), the stats at the right (Stats.lua). The panel's head says what
--  the tab says: the character's name with its title, or the tab's word.
--
--  The sheet stands at its own size, the game's (631 by 464 under the head),
--  with its side tabs, at the top of its panel's body, in its middle; the board
--  never makes the panel smaller than that (least). A tab is built the first
--  time it is chosen, and listens to the game only while it is shown. Nothing
--  of the game's sheet is touched: ours reads the game and calls only what the
--  game lets addon code call.
--
--  A tab is a table: key, tip (the side tab's tooltip), title (the head's words,
--  or a function giving them), icon (a texture) or portrait (the character's),
--  Build(left, right) (its frames over the panes, made on first choice),
--  Show(on) (shown or hidden, with the panel or by another tab chosen).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sheet = {}
ns.Sheet = Sheet

-- The game's sizes (CharacterFrameConstants.lua, CharacterFrame.xml): the whole window and its panes under its
-- title, the strip at the top of the left pane, the side tabs below the window's top right corner.
Sheet.LEFT, Sheet.RIGHT, Sheet.HEIGHT = 398, 233, 464
Sheet.STRIP = 36
Sheet.LEVEL_Y = -2 -- the level line in the strip's middle, a little low
Sheet.TABS_Y, Sheet.TAB_GAP = -30, 2
Sheet.TAB_WIDTH = 46 -- the side tabs' width where the game cannot say it (its tab art's width)

local holder, level, panel
local tabs = {}  -- in their order, the Character tab first
local chosen     -- the tab shown
local shown = false

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- A tab's file registers it (see the head of this file).
function Sheet.Tab(tab)
    tabs[#tabs + 1] = tab
end

-- The side tabs' width: the game's tab art's (SidePanelTabButtonMixin).
local function TabWidth()
    local mixin = rawget(_G, "SidePanelTabButtonMixin")
    local width = mixin and mixin.CalculateTabSizeBasedOnTabArt and Core.Ask(mixin.CalculateTabSizeBasedOnTabArt)
    return width or Sheet.TAB_WIDTH
end

-------------------------------------------------------------------------------
--  The Character tab: the paper doll and the stats
-------------------------------------------------------------------------------
-- The level line as the game writes it (PaperDollFrame_SetLevel): the level (the effective one with the real one
-- beside it while they differ), then the specialization and class in the class's colour.
local function Level()
    local now = Core.Plain(UnitLevel("player"))
    local effective = Core.Plain(Game("UnitEffectiveLevel", "player"))
    local shownLevel = now
    if now and effective and effective ~= now then shownLevel = Core.Word("EFFECTIVE_LEVEL_FORMAT", "%d (%d)"):format(effective, now) end
    local className, class, classID = UnitClass("player")
    local colors = rawget(_G, "RAID_CLASS_COLORS")
    local color = colors and class and colors[class]
    local colour = color and color.colorStr or "ffffffff"
    local spec
    local specs = rawget(_G, "C_SpecializationInfo")
    if specs and specs.GetSpecialization and specs.IsSpecSelectionEnabled and specs.GetSpecializationInfo then
        local tree = Core.Ask(specs.GetSpecialization)
        if tree and Core.Ask(specs.IsSpecSelectionEnabled, classID) then
            spec = select(2, Core.Ask(specs.GetSpecializationInfo, tree, false, false, nil, UnitSex("player")))
        end
    end
    if spec and spec ~= "" then
        level:SetFormattedText(Core.Word("PLAYER_LEVEL", "Level %s |c%s%s %s|r"), shownLevel or "", colour, spec, className or "")
    else
        level:SetFormattedText(Core.Word("PLAYER_LEVEL_NO_SPEC", "Level %s |c%s%s|r"), shownLevel or "", colour, className or "")
    end
end

-- The paper doll as it is now.
local function Doll()
    ns.Safe("character", Level)
    ns.Safe("character", ns.Slots.Place)
    ns.Slots.Update()
    ns.Safe("character", ns.Model.Refresh)
end

local function Equipped(slot)
    ns.Slots.Update(Core.Plain(slot))
end

-- A lock changed: an equipped item's when no bag is named (the slot comes first then).
local function Locked(bag, slot)
    if slot == nil then ns.Slots.Update(Core.Plain(bag)) end
end

local function Items()
    ns.Slots.Update()
end

local function Leveled()
    ns.Safe("character", Level)
end

local function Remodeled()
    ns.Safe("character", ns.Model.Refresh)
end

local DOLL_EVENTS = {
    PLAYER_EQUIPMENT_CHANGED = Equipped, ITEM_LOCK_CHANGED = Locked,
    UPDATE_INVENTORY_DURABILITY = Items, UPDATE_INVENTORY_ALERTS = Items,
    PLAYER_LEVEL_UP = Leveled, PLAYER_ENTERING_WORLD = Doll,
}
local DOLL_UNIT_EVENTS = { UNIT_MODEL_CHANGED = Remodeled, UNIT_INVENTORY_CHANGED = Items }

-- Its frames: the strip with the level line, the model and the slots over the left pane; the stats at the right.
local function BuildDoll(left, right)
    local strip = CreateFrame("Frame", nil, left)
    strip:SetPoint("TOPLEFT")
    strip:SetPoint("TOPRIGHT")
    strip:SetHeight(Sheet.STRIP)
    local rock = strip:CreateTexture(nil, "ARTWORK")
    rock:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
    rock:SetHorizTile(true)
    rock:SetVertTile(true)
    rock:SetAllPoints()
    local edge = strip:CreateTexture(nil, "ARTWORK", nil, 1)
    edge:SetAtlas("_UI-Frame-InnerTopTile", true)
    edge:SetHorizTile(true)
    edge:SetPoint("BOTTOMLEFT")
    edge:SetPoint("BOTTOMRIGHT")
    level = strip:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2Outline")
    level:SetPoint("CENTER", 0, Sheet.LEVEL_Y)

    ns.Model.Build(left, strip)
    local items = CreateFrame("Frame", nil, left)
    items:SetAllPoints()
    items:SetFrameLevel(left:GetFrameLevel() + 10) -- above the model, as the game's items frame
    ns.Slots.Build(items)
    ns.Stats.Build(right, Sheet.stone)
end

local function ShowDoll(on)
    for event, fn in pairs(DOLL_EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
    for event, fn in pairs(DOLL_UNIT_EVENTS) do
        if on then Core.OnUnit(event, "player", fn) else Core.OffUnit(event, "player", fn) end
    end
    ns.Stats.Show(on)
    if on then Doll() end
end

Sheet.Tab({
    key = "character", portrait = true, tip = Core.Word("CHARACTER_FRAME_TAB_CHARACTER", "Character"),
    title = function() return Game("UnitPVPName", "player") or Core.charName or "" end,
    Build = BuildDoll, Show = ShowDoll,
})

-------------------------------------------------------------------------------
--  The tabs
-------------------------------------------------------------------------------
local function Find(key)
    for _, tab in ipairs(tabs) do
        if tab.key == key then return tab end
    end
end

-- The panel's head: what the tab chosen says.
local function Title()
    local tab = Find(chosen)
    if not (tab and panel and panel.title) then return end
    local title = tab.title
    if type(title) == "function" then title = title() end
    panel.title:SetText(title or "")
end

-- Shown (on) or hidden: the tab's own step, alone.
local function Tell(tab, on)
    if tab and tab.built and tab.Show then ns.Safe("character", tab.Show, on) end
end

-- A tab chosen (by its key): the one before goes, this one is built if it is not yet, and shows.
function Sheet.Choose(key)
    local tab = Find(key) or tabs[1]
    if not holder or not tab then return end
    local before = Find(chosen)
    if before and before ~= tab and before.built then
        before.left:Hide()
        before.right:Hide()
        if shown then Tell(before, false) end
    end
    chosen = tab.key
    if not tab.built then
        tab.built = true
        tab.left = CreateFrame("Frame", nil, Sheet.left)
        tab.left:SetAllPoints()
        tab.right = CreateFrame("Frame", nil, Sheet.right)
        tab.right:SetAllPoints()
        ns.Safe("character", tab.Build, tab.left, tab.right)
    end
    tab.left:Show()
    tab.right:Show()
    for _, other in ipairs(tabs) do
        if other.button then other.button:SetChecked(other == tab) end
    end
    Title()
    if shown and before ~= tab then Tell(tab, true) end
end

-- The tab shown now.
function Sheet.Chosen()
    return chosen
end

-- A side tab let go over with the left button: its tab.
local function Clicked(tab, which, inside)
    if which == "LeftButton" and inside then Sheet.Choose(tab.key) end
end

-- The side tabs right of the sheet, the game's (LargeSideTabButtonTemplate), one under the other.
local function Buttons()
    local before
    for _, tab in ipairs(tabs) do
        local made, button = pcall(CreateFrame, "Frame", nil, holder, "LargeSideTabButtonTemplate")
        if made then
            button.tooltipText = tab.tip
            if button.SetFillToInterior then button:SetFillToInterior(true) end
            if tab.portrait then
                Game("SetPortraitTexture", button.Icon, "player")
                button.Icon:SetTexCoord(0.03125, 0.96875, 0.03125, 0.96875)
            else
                button.Icon:SetTexture(tab.icon)
            end
            local mine = tab
            button:SetCustomOnMouseUpHandler(function(_, which, inside) ns.Safe("character", Clicked, mine, which, inside) end)
            if before then
                button:SetPoint("TOPLEFT", before, "BOTTOMLEFT", 0, -Sheet.TAB_GAP)
            else
                button:SetPoint("TOPLEFT", holder, "TOPRIGHT", 0, Sheet.TABS_Y)
            end
            tab.button, before = button, button
        end
    end
end

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
-- The game's art for one pane: a frame of that width and the sheet's height.
local function Pane(width, atlas)
    local pane = CreateFrame("Frame", nil, holder)
    pane:SetSize(width, Sheet.HEIGHT)
    local back = pane:CreateTexture(nil, "BACKGROUND")
    back:SetAtlas(atlas, true)
    back:SetPoint("TOPLEFT")
    return pane
end

function Sheet.Build(made)
    panel = made
    holder = CreateFrame("Frame", nil, panel.body)
    holder:SetSize(Sheet.LEFT + Sheet.RIGHT, Sheet.HEIGHT)
    holder:SetPoint("TOP", panel.body, "TOP", -TabWidth() / 2, 0) -- the sheet and its side tabs in the middle

    local left = Pane(Sheet.LEFT, "UI-Character-Info-General-BG")
    left:SetPoint("TOPLEFT")
    local right = Pane(Sheet.RIGHT, "UI-Character-Info-Stat-BG")
    right:SetPoint("TOPLEFT", left, "TOPRIGHT")
    local stone = right:CreateTexture(nil, "ARTWORK")
    stone:SetAtlas("UI-Character-Info-Stat-StoneBG3", true)
    stone:SetPoint("TOPLEFT")
    local divider = right:CreateTexture(nil, "OVERLAY")
    divider:SetAtlas("common-framedivider", true)
    divider:SetPoint("TOPLEFT", -6, -1)
    divider:SetPoint("BOTTOMLEFT", -6, 0)
    Sheet.left, Sheet.right, Sheet.stone = left, right, stone

    Buttons()
    Sheet.Choose("character")
end

local function Named()
    Title()
end

function Sheet.Show(on)
    shown = on
    if on then Core.On("UNIT_NAME_UPDATE", Named) else Core.Off("UNIT_NAME_UPDATE", Named) end
    Tell(Find(chosen), on)
    if on then Title() end
end

-- The board's least: the sheet with its side tabs, and the panel's head and edges round it.
ns.Board.Part("character", Core.Word("CHARACTER", "Character"), function()
    local edge, head = Core.Board.EDGE, Core.Board.HEAD
    return { Sheet.LEFT + Sheet.RIGHT + TabWidth() + 2 * edge, Sheet.HEIGHT + head + 2 * edge }
end, Sheet)
