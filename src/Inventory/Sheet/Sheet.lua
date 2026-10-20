local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet
--  The character sheet, our own: what the game's character window holds
--  (Camelot's CharacterFrame), in a window on the module's full screen
--  (Board.lua, the key "character"). Built from Blizzard's code for it: its
--  panes, sizes, art and words, rewritten for our panel.
--
--      the left pane (398 wide)   the paper doll: a strip at the top with the
--                                 level line, the character's model (Model.lua),
--                                 the equipment slots round it (Slots.lua)
--      the right pane (233 wide)  the stats, on the game's stone (to come)
--  The panel's head says the character's name with its title, as the game's
--  window does. The tabs (reputation, skills, honor, currency, statistics)
--  come later (Doc/ideas/Inventory.md).
--
--  The sheet stands at its own size, the game's (631 by 464 under the head),
--  at the top of its panel's body, in its middle; the board never makes the
--  panel smaller than that (least). Nothing of the game's sheet is touched:
--  ours reads the game (the player's items, level, class, model) and calls
--  only what the game lets addon code call. It listens to the game only while
--  its panel is shown.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sheet = {}
ns.Sheet = Sheet

-- The game's sizes (CharacterFrameConstants.lua, CharacterFrame.xml): the whole window and its panes under its
-- title, the strip at the top of the left pane.
Sheet.LEFT, Sheet.RIGHT, Sheet.HEIGHT = 398, 233, 464
Sheet.STRIP = 36
Sheet.LEVEL_Y = -2 -- the level line in the strip's middle, a little low

local holder, level, panel

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- The level line as the game writes it (PaperDollFrame_SetLevel): the level (the effective one with the real one
-- beside it while they differ), then the specialization and class in the class's colour.
local function Level()
    local now = Core.Plain(UnitLevel("player"))
    local effective = Core.Plain(Game("UnitEffectiveLevel", "player"))
    local shown = now
    if now and effective and effective ~= now then shown = Core.Word("EFFECTIVE_LEVEL_FORMAT", "%d (%d)"):format(effective, now) end
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
        level:SetFormattedText(Core.Word("PLAYER_LEVEL", "Level %s |c%s%s %s|r"), shown or "", colour, spec, className or "")
    else
        level:SetFormattedText(Core.Word("PLAYER_LEVEL_NO_SPEC", "Level %s |c%s%s|r"), shown or "", colour, className or "")
    end
end

-- The panel's head: the character's name with its title, as the game's window is headed.
local function Title()
    if panel and panel.title then panel.title:SetText(Game("UnitPVPName", "player") or Core.charName or "") end
end

-- Everything as it is now.
local function Refresh()
    Title()
    ns.Safe("character", Level)
    ns.Safe("character", ns.Slots.Place)
    ns.Slots.Update()
    ns.Safe("character", ns.Model.Refresh)
end

-------------------------------------------------------------------------------
--  The game's events, while the panel is shown
-------------------------------------------------------------------------------
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

local EVENTS = {
    PLAYER_EQUIPMENT_CHANGED = Equipped, ITEM_LOCK_CHANGED = Locked,
    UPDATE_INVENTORY_DURABILITY = Items, UPDATE_INVENTORY_ALERTS = Items,
    PLAYER_LEVEL_UP = Leveled, PLAYER_ENTERING_WORLD = Refresh, UNIT_NAME_UPDATE = Title,
}
local UNIT_EVENTS = { UNIT_MODEL_CHANGED = Remodeled, UNIT_INVENTORY_CHANGED = Items }

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
    holder:SetPoint("TOP", panel.body, "TOP")

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

    -- The strip at the top of the left pane, the game's rock with its edge, the level line in it.
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
end

function Sheet.Show(on)
    for event, fn in pairs(EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
    for event, fn in pairs(UNIT_EVENTS) do
        if on then Core.OnUnit(event, "player", fn) else Core.OffUnit(event, "player", fn) end
    end
    if on then Refresh() end
end

-- The board's least: the sheet and the panel's head and edges round it.
local edge, head = Core.Board.EDGE, Core.Board.HEAD
ns.Board.Part("character", Core.Word("CHARACTER", "Character"),
    { Sheet.LEFT + Sheet.RIGHT + 2 * edge, Sheet.HEIGHT + head + 2 * edge }, Sheet)
