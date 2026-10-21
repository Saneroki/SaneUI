local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet
--  The character: the paper doll of the game's character sheet (Camelot's
--  CharacterFrame and PaperDollFrame), ours, a window of its own on the
--  module's full screen (Board.lua, the key "character"). The game's left pane
--  at the game's size (398 by 464), on its art: a strip at the top with the
--  level line, the character's model (Model.lua), the equipment slots round it
--  (Slots.lua). The panel's head says the character's name with its title, as
--  the game's window is headed. The rest of the game's sheet stands in windows
--  of its own beside it: the stats and the sidebar (Sidebar.lua), and what the
--  game's sheet has behind its tabs (Reputation.lua, Skills.lua, PvP.lua,
--  Currency.lua, Statistics.lua).
--
--  The window is moved and sized on Core's board: the paper doll stands in its
--  middle at the top, as large as fits and never larger than the game's. It
--  listens to the game only while shown. Nothing of the game's sheet is
--  touched: ours reads the game and calls only what the game lets addon code
--  call.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sheet = {}
ns.Sheet = Sheet

-- The game's sizes (CharacterFrame.xml, PaperDollFrame.xml): its left pane, the strip at its top, the level line
-- in the strip's middle a little low; how small the paper doll may be made on the board.
Sheet.WIDTH, Sheet.HEIGHT = 398, 464
Sheet.LEFT = Sheet.WIDTH -- the game's left pane, the paper doll's width (the other characters' window reads it)
Sheet.STRIP = 36
Sheet.LEVEL_Y = -2
Sheet.LEAST = 0.6

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

-- The panel's head: the character's name with its title.
local function Title()
    if panel and panel.title then panel.title:SetText(Game("UnitPVPName", "player") or Core.charName or "") end
end

-- The paper doll as it is now.
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
    PLAYER_LEVEL_UP = Leveled, PLAYER_ENTERING_WORLD = Refresh,
}
-- The player's only (Core.OnUnit): the game sends these for every unit about.
local UNIT_EVENTS = { UNIT_MODEL_CHANGED = Remodeled, UNIT_INVENTORY_CHANGED = Items, UNIT_NAME_UPDATE = Title }

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
function Sheet.Build(made)
    panel = made
    holder = CreateFrame("Frame", nil, panel.body)
    holder:SetSize(Sheet.WIDTH, Sheet.HEIGHT)
    holder:SetPoint("TOP", panel.body, "TOP")
    local back = holder:CreateTexture(nil, "BACKGROUND")
    back:SetAtlas("UI-Character-Info-General-BG", true)
    back:SetPoint("TOPLEFT")
    Sheet.pane = holder

    -- The strip at the top, the game's rock with its edge, the level line in it.
    local strip = CreateFrame("Frame", nil, holder)
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

    ns.Model.Build(holder, strip)
    local items = CreateFrame("Frame", nil, holder)
    items:SetAllPoints()
    items:SetFrameLevel(holder:GetFrameLevel() + 10) -- above the model, as the game's items frame
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

-- The panel placed that large: the paper doll as large as fits in its body, never larger than the game's.
function Sheet.Size(width, height)
    if not holder then return end
    local bodyWidth, bodyHeight = ns.Page.Body(width, height)
    holder:SetScale(math.max(0.1, math.min(1, bodyWidth / Sheet.WIDTH, bodyHeight / Sheet.HEIGHT)))
end

ns.Board.Part("character", Core.Word("CHARACTER", "Character"),
    ns.Page.Least(math.floor(Sheet.WIDTH * Sheet.LEAST), math.floor(Sheet.HEIGHT * Sheet.LEAST)), Sheet)
