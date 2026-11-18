local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Setup
--  The tooltips' setup (Saneroki, 2026-11-18: "a very simple onboarding for
--  the Tooltip window where we basically only have Show tooltip while x held,
--  Show at mouse cursor yes / no, 3d model yes / no, opacity slider with a
--  life preview"). One step: the module's own words, switches and sample,
--  handed to Core (Core.Onboarding.Add); the window is the addon Onboarding's,
--  read only when it opens: by itself the first time the module is on, from
--  the module's options page (Set up step by step), or /sane setup tooltips.
--
--  The sample: your own character's tooltip, drawn by the panels' own code
--  (Panel.Sample) over a piece of the world (Forever's own loading screen; on
--  Retail, the testing client, the grey box alone), anew after each change:
--    show     the line over it: at once, or which key to hold
--    cursor   Yes: beside the game's mouse pointer; No: in the corner, where
--             the game puts tooltips
--    models   your character moving in the portrait's place, or the portrait
--    opacity  how much of the world shows through its background
--  It is read from a tooltip of the game's own (Reader), filled with your
--  character and never placed: nobody sees it, and the module leaves it to
--  the game as it leaves another addon's that reads what the game says.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Setup = {}
ns.Setup = Setup

Setup.READER = "SaneUI_TooltipsSample" -- the tooltip the sample is read from (named: the game names its lines by it)
Setup.INSET = 6           -- the world inside the grey box's rim
Setup.BAND = 40           -- the dark band at the top that holds the words
Setup.SHADE = 0.6         -- how dark it is
Setup.LINE = 13           -- its words (Look.SetFont)
Setup.MARGIN = 24         -- between the world's edge and the sample in its corner
Setup.POINTER = { 22, 34 } -- the mouse pointer: from the world's left, and from under the band
Setup.BESIDE = { 26, 12 } -- the sample's top left from the pointer's tip, as the game puts a tooltip at the mouse
Setup.POINTER_SIZE = 32
Setup.CURSOR = "Interface\\Cursor\\Point" -- the game's mouse pointer
-- The world behind the sample: Forever's own loading screen (2992 x 1684), the middle of the picture between its
-- bands (as Navigation's instance banners cut it), as wide as the stage wants. Retail has no such picture.
Setup.WORLD = { forever = "Interface\\Glues\\LoadingScreens\\Camelot160\\Main\\LoadScreen_Camelot_Excavation" }
Setup.WORLD_SIZE = { 2992, 1684 }
Setup.WORLD_BAND = { 0.19, 0.81 }
Setup.WORLD_MIDDLE = 0.5
Setup.STAGE = { 420, 490 } -- the stage's size until the game has laid it out

-- The keys the options name, as the band says them.
Setup.HELD = { shift = "Shift", ctrl = "Ctrl", alt = "Alt", shiftalt = "Shift and Alt" }
Setup.TEXT = {
    always = "Tooltips show at once.",
    held = "Hold %s: tooltips show. Let go: they hide.",
    mouse = "At your mouse, following it.",
    mouseHeld = "At your mouse while %s is held, else in the corner.",
    corner = "In the corner of the screen, where the game puts them.",
    off = "The tooltips are the game's own until the next /reload.",
}

-- Words in the game's gold.
local function Gold(words)
    local gold = Look.GOLD
    return "|cff" .. Core.Hex(gold[1], gold[2], gold[3]) .. words .. "|r"
end

-- A step's words: one line each, its first words in gold, so the page reads at a glance (as Nameplates' setup).
local function Lines(...)
    local lines = {}
    for index = 1, select("#", ...) do
        local line = select(index, ...)
        lines[index] = Gold(line[1]) .. "  " .. line[2]
    end
    return table.concat(lines, "\n")
end

-------------------------------------------------------------------------------
--  The step: its words and the switches it is about (the module's own; the
--  mouse and the 3D model as a plain Yes or No)
-------------------------------------------------------------------------------
Setup.STEPS = {
    { key = "tooltips", title = "Set up your tooltips",
      text = Lines({ "Tooltips", "items, spells, creatures, players: drawn anew in SaneUI's panel." },
          { "When", "at once, or only while you hold a key: the screen stays clear." },
          { "Where", "in the corner, where the game puts them, or at your mouse." },
          { "At the left", "your own tooltip: every choice shows on it at once." }),
      settings = {
          "show",
          { key = "cursor", choices = { { "always", "Yes" }, { "default", "No" } },
            tip = "Yes: the tooltips of creatures, players and things in the world, and of your action bars, stand at the mouse pointer and follow it. No: where the game puts them, in the corner of the screen. The options page also has: at the mouse while a key is held." },
          { key = "models", choices = { { true, "Yes" }, { false, "No" } } },
          "opacity",
      } },
}

-------------------------------------------------------------------------------
--  The sample, made the first time it shows: the world, the band's words,
--  the mouse pointer and your tooltip
-------------------------------------------------------------------------------
local board -- on the module's frame over the window's stage

local Draw -- below

-- The world cut to the stage's shape: its picture's middle, as high as the band between the loading screen's bars.
function Setup.Cut(world, width, height)
    local size, band = Setup.WORLD_SIZE, Setup.WORLD_BAND
    local tall = (band[2] - band[1]) * size[2]
    local wide = math.min(tall * width / math.max(height, 1), size[1]) / size[1]
    local left = math.max(0, math.min(1 - wide, Setup.WORLD_MIDDLE - wide / 2))
    world:SetTexCoord(left, left + wide, band[1], band[2])
end

-- The game's tooltip the sample is read from: made once, owned by the board, never placed.
function Setup.Reader(parent)
    if not Setup.reader then Setup.reader = CreateFrame("GameTooltip", Setup.READER, parent, "GameTooltipTemplate") end
    return Setup.reader
end

local function Board(stage)
    if board then return board end
    board = CreateFrame("Frame", nil, stage)
    board:SetAllPoints(stage)
    local world = board:CreateTexture(nil, "BACKGROUND")
    world:SetPoint("TOPLEFT", board, "TOPLEFT", Setup.INSET, -Setup.INSET)
    world:SetPoint("BOTTOMRIGHT", board, "BOTTOMRIGHT", -Setup.INSET, Setup.INSET)
    local picture = Core.ForGame(Setup.WORLD)
    if picture then world:SetTexture(picture) end
    world:SetShown(picture ~= nil)
    board.world = world
    local band = board:CreateTexture(nil, "ARTWORK")
    band:SetColorTexture(0, 0, 0, Setup.SHADE)
    band:SetPoint("TOPLEFT", world, "TOPLEFT")
    band:SetPoint("TOPRIGHT", world, "TOPRIGHT")
    band:SetHeight(Setup.BAND)
    local words = board:CreateFontString(nil, "OVERLAY")
    Look.SetFont(words, Setup.LINE)
    words:SetPoint("LEFT", band, "LEFT", 10, 0)
    words:SetPoint("RIGHT", band, "RIGHT", -10, 0)
    words:SetJustifyH("CENTER")
    words:SetSpacing(3)
    board.words = words
    local pointer = board:CreateTexture(nil, "OVERLAY")
    pointer:SetTexture(Setup.CURSOR)
    pointer:SetSize(Setup.POINTER_SIZE, Setup.POINTER_SIZE)
    pointer:SetPoint("TOPLEFT", world, "TOPLEFT", Setup.POINTER[1], -(Setup.BAND + Setup.POINTER[2]))
    board.pointer = pointer
    -- Your tooltip: its health, power and buffs follow you while it shows (Live.lua), as a tooltip's do; laid out anew
    -- when they ask for it (a target, buffs gained or lost). Nothing of it stands the module down: it is a sample.
    local sample = ns.Panel.Sample(Setup.Reader(board), board)
    local function Watch(self)
        if ns.Live.Update(self) then Draw(stage) end
        return true
    end
    sample:SetScript("OnShow", ns.Guard(function(self) ns.Safe("setup sample", ns.Live.Start, self) end))
    sample:SetScript("OnHide", ns.Guard(function(self) ns.Safe("setup sample", ns.Live.Stop, self) end))
    sample:SetScript("OnUpdate", ns.Guard(function(self)
        if not ns.Safe("setup sample", Watch, self) then self:SetScript("OnUpdate", nil) end -- failed: it stands still
    end))
    board.sample = sample
    return board
end

-- The band's words: when tooltips show, and where.
function Setup.Said(options)
    local held = Setup.HELD[options.show]
    local when = held and Setup.TEXT.held:format(Gold(held)) or Setup.TEXT.always
    local where = Setup.TEXT.corner
    if options.cursor == "always" then
        where = Setup.TEXT.mouse
    elseif Setup.HELD[options.cursor] then
        where = Setup.TEXT.mouseHeld:format(Setup.HELD[options.cursor])
    end
    return when .. "\n" .. where
end

-- Your character's tooltip, filled by the game and read as the module reads every tooltip. Whether it could be read.
local function Read(sample)
    local reader = sample.tooltip
    reader:SetOwner(board, "ANCHOR_NONE")
    reader:SetUnit("player")
    local data = reader.GetPrimaryTooltipData and Core.Plain(reader:GetPrimaryTooltipData()) or nil
    local read = ns.Read(reader, data, sample.model, ns.options)
    reader:Hide()
    return read
end

-- The sample at the mouse pointer (the option cursor: Always) or in the corner.
local function Place(sample, atMouse)
    sample:ClearAllPoints()
    board.pointer:SetShown(atMouse)
    if atMouse then
        sample:SetPoint("TOPLEFT", board.pointer, "TOPLEFT", Setup.BESIDE[1], -Setup.BESIDE[2])
    else
        sample:SetPoint("BOTTOMRIGHT", board.world, "BOTTOMRIGHT", -Setup.MARGIN, Setup.MARGIN)
    end
end

function Draw(stage)
    Board(stage):Show()
    local options = ns.options or {}
    local width, height = board:GetWidth(), board:GetHeight()
    if not (type(width) == "number" and width > 0) then width = Setup.STAGE[1] end
    if not (type(height) == "number" and height > 0) then height = Setup.STAGE[2] end
    Setup.Cut(board.world, width - 2 * Setup.INSET, height - 2 * Setup.INSET)
    local sample = board.sample
    if ns.off then -- stood down: the tooltips are the game's, and so is nothing to show here
        board.words:SetText(Setup.TEXT.off)
        board.pointer:Hide()
        sample:Hide()
        return
    end
    board.words:SetText(Setup.Said(options))
    if not (Read(sample) and ns.Panel.Draw(sample)) then
        sample:Hide()
        return
    end
    Place(sample, options.cursor == "always")
end

-- For the tests: the sample's board, once drawn.
function Setup.Board() return board end

Core.Onboarding.Add(ns.name, {
    title = "Tooltips",
    steps = Setup.STEPS,
    Stage = function(stage) ns.Safe("setup sample", Draw, stage) end,
})
