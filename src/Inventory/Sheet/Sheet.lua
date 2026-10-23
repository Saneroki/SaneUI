local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet
--  The character: the paper doll of the game's character sheet (Camelot's
--  CharacterFrame and PaperDollFrame), ours, a window of its own on the
--  module's full screen (Board.lua, the key "character"), in Sane UI's own
--  look: the doll (Doll.lua), its own leather frame and paper, the equipment
--  slots in their arcs with the items' strips (Slots.lua), and in the hero's
--  place the character's name with its title, the level line under it and the
--  character's live model (Model.lua) standing on the page's plain paper. The
--  doll's top is the head it is dragged by, the X on its right strap. The rest
--  of the game's sheet stands in windows
--  of its own beside it: the stats (Stats.lua), the gear sets (Gear.lua), the
--  titles (Titles.lua), and what the
--  game's sheet has behind its tabs (Reputation.lua, Skills.lua, PvP.lua,
--  Currency.lua, Statistics.lua).
--
--  The window is moved and sized on Core's board: the doll stands in its middle,
--  as large as fits and never larger than its picture is drawn for 4K. It
--  listens to the game only while shown. Nothing of the game's sheet is
--  touched: ours reads the game and calls only what the game lets addon code
--  call.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sheet = {}
ns.Sheet = Sheet

-- The game's sizes (CharacterFrame.xml, PaperDollFrame.xml): its left pane (the other characters' window reads
-- it); how small the doll may be made on the board.
Sheet.WIDTH, Sheet.HEIGHT = 398, 464
Sheet.LEFT = Sheet.WIDTH
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
    -- the class's colour as ink on the paper (Core.Journal.Ink: darkened, so a light one reads)
    local colour = "ff1e1711"
    if color then
        local r, g, b = Core.Journal.Ink(color.r, color.g, color.b)
        colour = ("ff%02x%02x%02x"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    end
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

-- The panel's title, in the hero's place: the character's name with its title.
local function Title()
    if panel and panel.title then panel.title:SetText(Game("UnitPVPName", "player") or Core.charName or "") end
end

-- The level line, in Kalam on the paper: the class's colour outlined, so a light one reads on it.
local function Ink()
    level:SetFont(Core.Journal.FONT, 13 * Core.Journal.PX, "")
    level:SetTextColor(Core.Journal.INK[1], Core.Journal.INK[2], Core.Journal.INK[3], 0.9)
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
    local Doll = ns.Doll
    holder = CreateFrame("Frame", nil, panel.body)
    holder:SetSize(Doll.WIDTH, Doll.HEIGHT)
    holder:SetPoint("TOP")
    Doll.Build(holder)
    Sheet.pane = holder
    local function At(x, y) return x * Core.Journal.PX, -y * Core.Journal.PX end

    -- the hero's place: the name, the level line, the model under them
    local hero = Doll.HERO
    local x, top = At((hero[1] + hero[3]) / 2, Doll.NAME_Y)
    local width = (hero[3] - hero[1] - 8) * Core.Journal.PX
    panel.head:SetParent(holder)
    panel.head:ClearAllPoints()
    panel.head:SetPoint("TOPLEFT", holder, "TOPLEFT")
    panel.head:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    panel.head:SetHeight(Doll.HEAD * Core.Journal.PX)
    panel.title:SetParent(holder)
    panel.title:ClearAllPoints()
    panel.title:SetPoint("TOP", holder, "TOPLEFT", x, top)
    panel.title:SetWidth(width)
    panel.title:SetWordWrap(false)
    Core.Journal.Font(panel.title, 16, true)
    local _, levelY = At(0, Doll.LEVEL_Y)
    level = holder:CreateFontString(nil, "OVERLAY")
    level:SetPoint("TOP", holder, "TOPLEFT", x, levelY)
    level:SetWidth(width)
    level:SetWordWrap(false)
    Ink()
    panel.close:SetParent(holder)
    panel.close:ClearAllPoints()
    panel.close:SetPoint("CENTER", holder, "TOPLEFT", At(Doll.CLOSE[1], Doll.CLOSE[2]))
    panel.close:SetFrameLevel(holder:GetFrameLevel() + 30)

    local left, modelTop = At(hero[1], Doll.MODEL_TOP)
    local right, bottom = At(hero[3], Doll.GROUND)
    local place = CreateFrame("Frame", nil, holder)
    place:SetPoint("TOPLEFT", holder, "TOPLEFT", left, modelTop)
    place:SetSize(right - left, modelTop - bottom)
    ns.Model.Build(place)
    -- the doll's picture again below the hero's column, over the model and under the items: zoomed in, its legs go
    -- behind the weapons' row instead of over it
    local cover = CreateFrame("Frame", nil, holder)
    cover:SetAllPoints()
    cover:SetFrameLevel(holder:GetFrameLevel() + 6)
    local middle, half = (hero[1] + hero[3]) / 2, ns.Model.SIZE[1] / 2
    Doll.Cover(cover, middle - half, middle + half, Doll.FOOT)
    -- the name and the level over the model, which is drawn larger than its place
    local words = CreateFrame("Frame", nil, holder)
    words:SetAllPoints()
    words:SetFrameLevel(holder:GetFrameLevel() + 12)
    panel.title:SetParent(words)
    level:SetParent(words)

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

-- The panel placed that large: the doll as large as fits in it at its top middle, never larger than its picture
-- is drawn for 4K.
function Sheet.Size(width, height)
    if not holder then return end
    holder:SetScale(math.max(0.1, math.min(1, width / ns.Doll.WIDTH, height / ns.Doll.HEIGHT)))
end

ns.Board.Part("character", Core.Word("CHARACTER", "Character"),
    ns.Board.Least("character", math.floor(ns.Doll.WIDTH * Sheet.LEAST), math.floor(ns.Doll.HEIGHT * Sheet.LEAST)), Sheet)
