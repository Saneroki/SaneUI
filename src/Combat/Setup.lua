local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Setup
--  Combat's setup, step by step (Saneroki, 2026-11-18: "We need a onboarding
--  for our combat module that integrates the nameplates module now"): its
--  words and samples, handed to Core (Core.Onboarding.Add); the window is the
--  addon Onboarding's, read only when it opens: by itself the first time the
--  module is on, from its options page (Set up step by step), or /sane setup
--  combat (/sane setup nameplates: at the nameplates' first step).
--
--  The steps, each a few short lines that start with gold words, its switches
--  and a sample on the window's solid grey box:
--    parts    which parts are ours: unit frames, party and raid frames,
--             nameplates, aura tracking ("people can for example choose to
--             use our party and unit frames but disable our nameplates")
--    units    your frame, your target's, your focus's, your pet; how large,
--             out of sight at rest
--    party    the party and raid frames: a preview of 5, 10, 20 and 40, going
--             through them a few seconds each, a click on a number holds it
--             ("previews of the party with 5, 10, 20 and 40 people in it where
--             people can see where everything is"), at the size the settings
--             keep; and the button Place and size in Edit Mode: the game's own
--             Edit Mode opens (its /editmode, by Onboarding's secure command
--             button), this window steps out of the way until it closes, the
--             frame's box has a grip at each corner and a handle on each side,
--             and its preview goes through 5, 10, 20 and 40 meanwhile
--             (Units/Group.lua, Group.Cycle)
--    then the nameplates' steps (Nameplates/Setup.lua), each headed Nameplates
--    tracking aura tracking: your marks of auras, the icons you track
--  A step of a part switched off says so, and its sample is faint.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Guide = {}
ns.Guide = Guide

Guide.PAD = 16          -- the samples' room from the stage's edges
Guide.TABS = 26         -- the numbers' row over the party's sample
Guide.SIZE = 13         -- the boards' words (Look.SetFont)
Guide.FAINT = 0.35      -- a sample of a part that is the game's now
Guide.ROW = 30          -- a unit frame's sample: its height, and the gap under it
Guide.UNIT = 240        -- its width

-- Words in the game's gold, then the rest: one line each, so a step reads at a glance.
local function Lines(...)
    local lines = {}
    for index = 1, select("#", ...) do
        local line = select(index, ...)
        lines[index] = "|cff" .. Core.Hex(Look.GOLD[1], Look.GOLD[2], Look.GOLD[3]) .. line[1] .. "|r  " .. line[2]
    end
    return table.concat(lines, "\n")
end

Guide.TEXT = {
    title = "Combat",
    editMode = "Place and size in Edit Mode",
    editModeTip = "Opens the game's Edit Mode with your party and raid frames in it, going through 5, 10, 20 and 40 players. Drag the frame to move it, a corner or a side to size it. This window steps aside and comes back when you leave Edit Mode.",
    editModeMissing = "Open Edit Mode from the game's menu (Esc, then Edit Mode): your party and raid frames are in it.",
    count = "%d",
    countTip = "Show it with %d players. Click again to let it go through 5, 10, 20 and 40.",
    gameNow = "Off: the game's own is in its place now.",
    you = "Your frame",
    target = "Your target",
    focus = "Your focus",
    pet = "Your pet",
}
local T = Guide.TEXT

-------------------------------------------------------------------------------
--  The steps: their words and the switches each is about
-------------------------------------------------------------------------------
local OWN = {
    { key = "parts", title = "Set up Combat",
      text = Lines({ "Combat", "your unit frames, your party and raid, the nameplates and the auras you track." },
          { "Ours or the game's", "untick a part to keep the game's own, as before Sane UI." },
          { "At the left", "a sample shows each choice at once." },
          { "Every choice", "counts at once. Close at any time: it stays." }),
      settings = { "units", "group", "plates", "reminders" } },
    { key = "units", title = "Your unit frames",
      text = Lines({ "Your frame", "your level and health; your target's and your focus's with their names." },
          { "Under them", "your pet, and whom your target and your focus target." },
          { "Over the bar", "the cast; your breath under water over your own." },
          { "At rest", "out of sight until something goes on: the mouse, a fight, your health." },
          { "Edit Mode", "places each of them." }),
      settings = { "unitPlayer", "unitTarget", "unitFocus", "unitPet", "unitSize", "unitRest" } },
    { key = "party", title = "Party and raid frames",
      text = Lines({ "One frame", "for your party and your raid, up to forty, in place of the game's two." },
          { "5, 10, 20, 40", "the sample goes through them: click a number to hold it." },
          { "It fills", "up from its bottom left corner, five to a column, a column per raid group." },
          { "Edit Mode", "moves it and sizes it: drag a corner or a side." }),
      settings = { "groupClass", "groupBeside",
                   { macro = "/editmode", command = "EDITMODE", text = T.editMode, tip = T.editModeTip,
                     missing = T.editModeMissing, done = function() ns.Guarded(ns.Group.Cycle, true) end } } },
    { key = "tracking", title = "Aura tracking",
      text = Lines({ "Click a buff", "or a debuff, or right click a spell in the spellbook: mark it, or track it." },
          { "Important", "glows and comes first. Unimportant fades. Hidden goes." },
          { "Track it", "and its icon shows on a bar of its own, the health bars or the nameplates." },
          { "Edit tracked", "every aura's marks and tracking in one window: /sane auras." }),
      settings = { "buffList", "unitAuras", "groupBuffs" } },
}

-- Which part a step is of: its sample faint while that part is the game's.
local PART = { units = "units", party = "group", tracking = "reminders" }

-- Combat's own steps and the nameplates' (all but their intro: the first step here says what this is), in order.
Guide.STEPS = {}
for _, step in ipairs(OWN) do
    if step.key == "tracking" then
        for _, plate in ipairs(ns.Setup.STEPS) do
            if plate.key ~= "intro" then
                local copy = {}
                for field, value in pairs(plate) do copy[field] = value end
                copy.title = ns.TEXT.platesTitle .. ": " .. plate.title
                PART[plate.key] = "plates"
                Guide.STEPS[#Guide.STEPS + 1] = copy
            end
        end
    end
    Guide.STEPS[#Guide.STEPS + 1] = step
end

-------------------------------------------------------------------------------
--  The samples
-------------------------------------------------------------------------------
local boards = {} -- [step key] = its board on the stage, made once
local function Board(stage, key)
    local board = boards[key]
    if board then return board end
    board = CreateFrame("Frame", nil, stage)
    board:SetAllPoints(stage)
    board.words = {}
    boards[key] = board
    return board
end

local function Words(board, index)
    local line = board.words[index]
    if not line then
        line = board:CreateFontString(nil, "ARTWORK")
        Look.SetFont(line, Guide.SIZE)
        line:SetJustifyH("LEFT")
        board.words[index] = line
    end
    return line
end

local function Wide(board)
    local width = board:GetWidth()
    return type(width) == "number" and width > 0 and width or 420
end
local function High(board)
    local height = board:GetHeight()
    return type(height) == "number" and height > 0 and height or 400
end

-- A part switched off: its sample faint, and words that say so at the board's foot.
local function Faint(board, key)
    local part = PART[key]
    local off = part and ns.options[part] == false
    board:SetAlpha(off and Guide.FAINT or 1)
    local note = Words(board, 99)
    note:ClearAllPoints()
    note:SetPoint("BOTTOMLEFT", board, "BOTTOMLEFT", Guide.PAD, Guide.PAD)
    note:SetText(off and T.gameNow or "")
end

-- Made-up members of the party and raid frames, as they show there (Units/Group.lua), scaled to fit the room.
local function Party(board, count, top)
    local frame = board.party
    if not frame then
        frame = CreateFrame("Frame", nil, board)
        board.party = frame
    end
    local width, height = ns.Group.Sample(frame, count)
    local roomWidth, roomHeight = Wide(board) - 2 * Guide.PAD, High(board) - top - 2 * Guide.PAD
    local scale = math.min(1, roomWidth / math.max(width, 1), roomHeight / math.max(height, 1))
    frame:SetScale(math.max(scale, 0.05))
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", board, "TOPLEFT", Guide.PAD / frame:GetScale(), -(top + Guide.PAD) / frame:GetScale())
    frame:Show()
    return frame
end

-- The numbers over the party's sample: the one shown lit; a click holds it, again lets it go through them.
local function Tabs(board)
    if board.tabs then return board.tabs end
    local tabs = {}
    for index, count in ipairs(ns.Group.CYCLE) do
        local tab = CreateFrame("Button", nil, board)
        tab:SetSize(36, Guide.TABS - 6)
        tab:SetPoint("TOPLEFT", board, "TOPLEFT", Guide.PAD + (index - 1) * 42, -Guide.PAD / 2)
        local outline = Look.Outline(tab)
        local words = tab:CreateFontString(nil, "OVERLAY")
        Look.SetFont(words, Guide.SIZE)
        words:SetPoint("CENTER")
        words:SetText(T.count:format(count))
        tab.outline, tab.words, tab.count = outline, words, count
        tab:SetScript("OnClick", ns.Guard(function()
            board.held = board.held ~= count and count or nil
            board.shown = count
            Guide.Party(board)
        end))
        Core.Tip(tab, T.count:format(count), T.countTip:format(count))
        tabs[index] = tab
    end
    board.tabs = tabs
    -- Through the numbers a few seconds each while it shows and none is held, as Edit Mode's preview from here.
    board.cycled = 0
    board:SetScript("OnUpdate", ns.Guard(function(_, elapsed)
        if board.held then return end
        board.cycled = board.cycled + elapsed
        if board.cycled < ns.Group.CYCLE_SECONDS then return end
        board.cycled = 0
        local list, at = ns.Group.CYCLE, 1
        for index, count in ipairs(list) do if count == board.shown then at = index end end
        board.shown = list[at % #list + 1]
        Guide.Party(board)
    end))
    return tabs
end

-- The party's board as it stands: the count shown (held or going through), its tabs lit.
function Guide.Party(board)
    board.shown = board.held or board.shown or ns.Group.CYCLE[1]
    for _, tab in ipairs(Tabs(board)) do
        local lit = tab.count == board.shown
        tab.outline:SetStrong(lit)
        tab.words:SetTextColor(lit and Look.GOLD[1] or 0.8, lit and Look.GOLD[2] or 0.8, lit and Look.GOLD[3] or 0.8)
    end
    Party(board, board.shown, Guide.TABS)
end

-- One of your unit frames as a member's frame shows (the same look: Units/GroupFace.lua), with its words beside it.
local function Unit(board, index, sample, words)
    board.units = board.units or {}
    local face = board.units[index]
    if not face then
        face = ns.GroupFace.Make(board, true)
        board.units[index] = face
    end
    local y = Guide.PAD + (index - 1) * (Guide.ROW + 10)
    face:ClearAllPoints()
    face:SetPoint("TOPLEFT", board, "TOPLEFT", Guide.PAD, -y)
    face:SetSize(Guide.UNIT * (tonumber(ns.options.unitSize) or 100) / 100 * 0.6, Guide.ROW)
    ns.GroupFace.Fit(face)
    ns.GroupFace.Sample(face, sample)
    face:Show()
    local line = Words(board, index)
    line:ClearAllPoints()
    line:SetPoint("LEFT", face, "RIGHT", 10, 0)
    line:SetText(words)
end

local DRAW = {}
function DRAW.parts(board)
    Party(board, ns.Group.CYCLE[1], 0)
end
function DRAW.party(board)
    Guide.Party(board)
end
function DRAW.tracking(board)
    Party(board, ns.Group.CYCLE[1], 0)
end
function DRAW.units(board)
    local class = select(2, Core.Ask(UnitClass, "player"))
    local names = ns.TEXT.groupSamples
    Unit(board, 1, { name = "", health = 0.85, most = 4200, class = class, icons = {} }, T.you)
    Unit(board, 2, { name = names.foes[1], health = 0.6, most = 1800, reaction = 2, icons = {} }, T.target)
    Unit(board, 3, { name = names.first[2] .. " " .. names.last[3], health = 1, most = 3100, class = "PRIEST", mana = 0.7,
                     icons = {} }, T.focus)
    Unit(board, 4, { name = names.pets[1], health = 0.9, most = 900, icons = {} }, T.pet)
end

-- The step's board on the stage, the others out of sight (the nameplates' too, Nameplates/Setup.lua, which draws
-- its own steps); drawn anew as the settings in use say.
local function Stage(stage, step, index)
    ns.Setup.Stage(stage, step)
    for key, board in pairs(boards) do board:SetShown(key == step.key) end
    local draw = DRAW[step.key]
    if draw then
        local board = Board(stage, step.key)
        draw(board)
        board:Show()
        Faint(board, step.key)
    end
    local plates = PART[step.key] == "plates" and ns.Setup.Board(step.key)
    if plates then plates:SetAlpha(ns.options.plates == false and Guide.FAINT or 1) end
end

-- For the tests: a step's board, once drawn.
function Guide.Board(key) return boards[key] end

Core.Onboarding.Add(ns.name, {
    title = T.title,
    steps = Guide.STEPS,
    aliases = { nameplates = "size" },
    Stage = function(stage, step, index) ns.Safe("setup sample", Stage, stage, step, index) end,
})
