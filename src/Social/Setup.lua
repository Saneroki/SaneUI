local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Setup
--  Social's setup, step by step (Saneroki, 2026-11-18: "In the onboarding they
--  need to get teached again about the hotcorners and select if they want the
--  hotcorner not at all or with left click or with just moving their mouse
--  there. They need to be able to define a keybind (if they want to) to open
--  the socials fullscreen. And have the checkbox checks for the social
--  windows."). The module's own words and samples, handed to Core
--  (Core.Onboarding.Add); the window is the addon Onboarding's, read only when
--  it opens: by itself the first time the module is on, from the module's
--  options page (Set up step by step), or /sane setup social (/sane setup chat).
--
--  The steps, each a few short lines that start with gold words, its switches
--  and a board drawn on the window's solid grey box:
--    intro    what this is: the chat as a messenger, the game's chat out of
--             sight and keeping every line, Enter to write as always
--    corner   the hot corner: the screen's corner the chat is docked in fills
--             the screen with Social and brings it back; not at all, with a left
--             click, or with the mouse alone (one choice over three switches:
--             Can expand to fullscreen, Hotcorner, Hotcorner requires leftclick)
--    keys     a key of its own for the full screen, and the chat window's key;
--             they work beside the corner
--    windows  the windows: the chat window itself, the game's chat beside it,
--             the second chat as a window of its own on the screen (a chat view:
--             no switch, its own tick, ChatWindows.lua), the group finder's tab
--    full     the full screen: the conversations in parts (whispers, groups),
--             a head folds its part; chat views; the friends list and the guild
--             window ticked into its layout or out of it (Saneroki, 2026-11-18:
--             "Add the friends list and guild window to the setup too"; the
--             layout chosen, also while the full screen is away: Board.Put)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Setup = {}
ns.Setup = Setup

Setup.TITLE = "Social"     -- the window's title: "Social: setup" (and /sane setup social)
Setup.SIZE = 13            -- the boards' words (Look.SetFont)
Setup.SCREEN = { 360, 203 } -- a screen drawn on a board: 16 to 9
Setup.CHAT = { 110, 70 }   -- the chat on a drawn screen
Setup.ARROW = 70           -- the tutorial arrow on a board
Setup.ARROW_ART = "NPE_ArrowRight"
Setup.GLOW_ART = "NPE_ArrowRightGlow"
Setup.WORLD = { 0.05, 0.05, 0.06 } -- a drawn screen's world
Setup.PLATE = { 0.15, 0.15, 0.17 } -- a drawn bubble, the chat's grey
Setup.GAME = { 0.10, 0.08, 0.04 }  -- the game's own chat, drawn: its dark brown
Setup.FULL = { 0.09, 0.09, 0.10 }  -- a drawn full screen's panels
-- Which way the arrow points (degrees, counterclockwise from the right) into each corner or side.
Setup.ANGLES = { TOPRIGHT = 45, TOPLEFT = 135, BOTTOMLEFT = 225, BOTTOMRIGHT = 315,
                 RIGHT = 0, TOP = 90, LEFT = 180, BOTTOM = 270 }

Setup.TEXT = {
    corner = "The hot corner",
    cornerTip = "The screen's corner (or edge) the chat is docked to fills the screen with Social, and brings it back. Not at all: only its key does (the next page).",
    cornerOff = "Not at all: only by a key",
    cornerClick = "With a left click in it",
    cornerHover = "When the mouse goes into it",
    keyFull = "Social's full screen",
    keyFullTip = "Full screen and back, from wherever you are; with the hot corner off, the way in.",
    keyChat = "The chat window",
    keyChatTip = "SaneUI's chat window shown or hidden: the game's own chat in its place, and back.",
    second = "The second chat on the screen",
    secondTip = "Your whispers, party, raid, instance and guild chat in a chat window of their own beside the chat. Its button (the mouse over it) ticks what it shows; Edit Mode moves it.",
    friendsTick = "The friends list on the full screen",
    friendsTip = "Your friends, requests, ignored players, your raid and the group finder, at the full screen's right. Off: the conversations and the chat take its room; the dropdown Windows there brings it back too.",
    guildTick = "The guild window on the full screen",
    guildTip = "The window the guild key opens (the module Guild's while it is on), at the full screen's top right while you are in a guild. Off: the full screen leaves it out; the guild key opens it as always.",
    guild = "Guild",
    into = "All the way into the corner",
    click = ", then click",
    off = "The corner does nothing: use the key",
    fills = "and Social fills the screen",
    chat = "SaneUI's chat",
    game = "The game's chat",
    secondChat = "Second chat",
    whispers = "Whispers",
    groups = "Groups",
    friends = "Friends",
}

local function Hued(words)
    return "|cff" .. Core.Hex(Look.GOLD[1], Look.GOLD[2], Look.GOLD[3]) .. words .. "|r"
end

-- A step's words: one line each, its first words in gold ({ "Gold", "the rest" }), so the page reads at a glance.
local function Lines(...)
    local lines = {}
    for index = 1, select("#", ...) do
        local line = select(index, ...)
        lines[index] = Hued(line[1]) .. "  " .. line[2]
    end
    return table.concat(lines, "\n")
end

-- The first chat view, the second chat (Feed.lua): whether it stands on the screen as a window of its own.
local function Second()
    return ns.Feed.Views()[1]
end

local function SecondShown()
    local view = Second()
    return view ~= nil and view.screen == true
end

local function ShowSecond(on)
    local view = Second()
    if view then ns.ChatWindows.Put(view, on) end
end

-------------------------------------------------------------------------------
--  The steps: their words and the switches each is about
-------------------------------------------------------------------------------
Setup.STEPS = {
    { key = "intro", title = "Your chat",
      text = Lines({ "Every message", "in a bubble: yours at the right, everybody else's at the left with name and class." },
          { "The game's chat", "is out of sight while this one is open, and keeps every line." },
          { "Enter", "writes as always: slash commands, /w, /r, the history." },
          { "This setup", "shows how to open Social's full screen and which windows you want." },
          { "Every choice", "counts at once. Close at any time: it stays." }),
      settings = {} },
    { key = "corner", title = "The hot corner",
      text = Lines({ "The hot corner", "the screen's corner your chat is docked in: the arrow points at it." },
          { "Into it", "the mouse all the way into it: Social fills the screen. Again: it goes back." },
          { "Or a click", "the mouse in the corner, then a left click: nothing opens by mistake." },
          { "Not at all", "the corner does nothing: a key opens the full screen (the next page)." }),
      settings = { { key = "expandCorner", text = Setup.TEXT.corner, tip = Setup.TEXT.cornerTip, column = true, parent = false,
                     choices = { { { expand = true, expandCorner = false }, Setup.TEXT.cornerOff },
                                 { { expand = true, expandCorner = true, expandClick = true }, Setup.TEXT.cornerClick },
                                 { { expand = true, expandCorner = true, expandClick = false }, Setup.TEXT.cornerHover } } } } },
    { key = "keys", title = "Or a key",
      text = Lines({ "Social's full screen", "full screen and back by a key of its own, if you want one." },
          { "The chat window", "SaneUI's chat or the game's, by a key." },
          { "Together", "the corner and the keys work side by side: use any of them, or all." },
          { "A key", "click its box, press the key. Right click: no key." }),
      settings = { { binding = "SANEUI_SOCIAL_FULL", text = Setup.TEXT.keyFull, tip = Setup.TEXT.keyFullTip },
                   { binding = "SANEUI_SOCIAL", text = Setup.TEXT.keyChat, tip = Setup.TEXT.keyChatTip } } },
    { key = "windows", title = "Your windows",
      text = Lines({ "The chat window", "SaneUI's chat in place of the game's. Off: the game's chat, as it was." },
          { "The game's chat", "on show beside it too, if you like both." },
          { "More chat windows", "the second chat on the screen; more from the list of the chat's button (Chat windows)." },
          { "Each window", "its button (the mouse over it) ticks what it shows. Edit Mode moves and sizes them." }),
      settings = { "window", "showNative",
                   { check = function() return SecondShown() end, set = function(on) ShowSecond(on) end,
                     text = Setup.TEXT.second, tip = Setup.TEXT.secondTip },
                   "boardFinder" } },
    { key = "full", title = "The full screen",
      text = Lines({ "Conversations", "every whisper and every group you join, each its own, kept to read." },
          { "In parts", "the whispers, then the groups: a click on a part's head folds it away." },
          { "Chat views", "New chat view: its own choice of chats; a right click puts it on the screen." },
          { "Windows", "tick the friends list and the guild window here, or in the dropdown Windows there." },
          { "Arrange", "drag a window's head onto another, or the line between two." },
          { "Done", "your chat is set." }),
      settings = { { check = function() return ns.Board.Holds("friends") end, set = function(on) ns.Board.Put("friends", on) end,
                     text = Setup.TEXT.friendsTick, tip = Setup.TEXT.friendsTip },
                   { check = function() return ns.Board.Holds("guild") end, set = function(on) ns.Board.Put("guild", on) end,
                     text = Setup.TEXT.guildTick, tip = Setup.TEXT.guildTip } } },
}

-------------------------------------------------------------------------------
--  The boards: each step's sample, made the first time it shows
-------------------------------------------------------------------------------
local boards = {} -- [step key] = its board on the stage

local function Wide(board)
    local width = board:GetWidth()
    return type(width) == "number" and width > 0 and width or 420
end

-- A part of a board, made once by its name.
local function Part(board, name, make)
    local part = board.parts[name]
    if not part then
        part = make()
        board.parts[name] = part
    end
    return part
end

local function Words(board, name, host)
    return Part(board, name, function()
        local words = (host or board):CreateFontString(nil, "OVERLAY")
        Look.SetFont(words, Setup.SIZE, false)
        words:SetJustifyH("CENTER")
        words:SetWordWrap(true)
        return words
    end)
end

-- Words centred at y from the board's top, as wide as the board allows.
local function Caption(board, name, y, text)
    local words = Words(board, name)
    words:ClearAllPoints()
    words:SetPoint("TOP", board, "TOP", 0, -y)
    words:SetWidth(Wide(board) - 40)
    words:SetText(text)
    return words
end

-- A frame in the thin golden outline, filled with a colour: a drawn screen, a drawn window.
local function Boxed(parent, colour)
    local box = CreateFrame("Frame", nil, parent)
    local fill = box:CreateTexture(nil, "BACKGROUND")
    fill:SetColorTexture(colour[1], colour[2], colour[3], 1)
    fill:SetAllPoints()
    box.outline = Look.Outline(box, "ARTWORK")
    box.outline.fill:Hide() -- (its own dark inside: the colour given is the inside here)
    box.fill = fill
    return box
end

-- A screen drawn on the board: its top at y, centred.
local function Screen(board, name, y)
    local screen = Part(board, name, function() return Boxed(board, Setup.WORLD) end)
    screen:ClearAllPoints()
    screen:SetSize(Setup.SCREEN[1], Setup.SCREEN[2])
    screen:SetPoint("TOP", board, "TOP", 0, -y)
    return screen
end

-- A drawn chat window: its name small at its top, a few bubbles in it, yours at the right.
local function Chat(parent, title, colour)
    local chat = Boxed(parent, colour or Setup.WORLD)
    chat.fill:SetAlpha(colour and 1 or 0)
    chat.name = chat:CreateFontString(nil, "OVERLAY")
    Look.SetFont(chat.name, 10, false, Look.GOLD)
    chat.name:SetPoint("TOPLEFT", 4, -3)
    chat.name:SetText(title)
    chat.bubbles = {}
    for index = 1, 3 do
        local bubble = chat:CreateTexture(nil, "ARTWORK")
        bubble:SetColorTexture(Setup.PLATE[1], Setup.PLATE[2], Setup.PLATE[3], 1)
        bubble:SetSize(index == 2 and 44 or 60, 10)
        bubble:SetPoint(index == 2 and "BOTTOMRIGHT" or "BOTTOMLEFT", chat, index == 2 and "BOTTOMRIGHT" or "BOTTOMLEFT",
            index == 2 and -6 or 6, 6 + (3 - index) * 14)
        chat.bubbles[index] = bubble
    end
    return chat
end

-- The chat on a drawn screen where it is docked (a corner, the middle of a side; in the middle for none).
local function Dock(chat, screen, at)
    local point = at or "CENTER"
    chat:ClearAllPoints()
    chat:SetSize(Setup.CHAT[1], Setup.CHAT[2])
    chat:SetPoint(point, screen, point, 0, 0)
end

-- A layer over the drawn screens and windows: for the arrow.
local function Top(board)
    return Part(board, "top", function()
        local frame = CreateFrame("Frame", nil, board)
        frame:SetAllPoints(board)
        frame:SetFrameLevel(board:GetFrameLevel() + 20)
        return frame
    end)
end

-- The game's tutorial arrow and its glow, pointing into a drawn screen's corner (or side) at.
local function Arrow(board)
    return Part(board, "arrow", function()
        local frame = CreateFrame("Frame", nil, Top(board))
        frame:SetSize(Setup.ARROW, Setup.ARROW)
        local art = frame:CreateTexture(nil, "ARTWORK")
        Look.Atlas(art, Setup.ARROW_ART)
        art:SetAllPoints()
        local glow = frame:CreateTexture(nil, "OVERLAY")
        Look.Atlas(glow, Setup.GLOW_ART)
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.75)
        glow:SetAllPoints()
        frame.parts = { art, glow }
        return frame
    end)
end

local function Into(arrow, screen, at)
    local angle = at and Setup.ANGLES[at]
    arrow:SetShown(angle ~= nil)
    if not angle then return end
    for _, part in ipairs(arrow.parts) do part:SetRotation(math.rad(angle)) end
    local turn = math.rad(angle)
    local reach = arrow:GetWidth() * 0.62
    arrow:ClearAllPoints()
    arrow:SetPoint("CENTER", screen, at, -math.cos(turn) * reach, -math.sin(turn) * reach)
end

-- Where the chat is docked now ("BOTTOMLEFT" at first), or nil while it stands free.
local function Zone()
    return ns.Window.Zone()
end

local DRAW = {}

-- The chat on a screen, its bubbles; the game's chat out of sight.
function DRAW.intro(board)
    local screen = Screen(board, "screen", 30)
    local chat = Part(board, "chat", function() return Chat(screen, Setup.TEXT.chat) end)
    Dock(chat, screen, Zone() or "BOTTOMLEFT")
    Caption(board, "words", 30 + Setup.SCREEN[2] + 12, Hued("Messages") .. " in bubbles over the game: they fade a while "
        .. "after they came, and the mouse wheel brings them back to read.")
end

-- The screen with the chat in its corner, the arrow into it as the choice says: the mouse, a click, or nothing.
function DRAW.corner(board)
    local options = ns.options
    local screen = Screen(board, "screen", 40)
    local chat = Part(board, "chat", function() return Chat(screen, Setup.TEXT.chat) end)
    local at = Zone()
    Dock(chat, screen, at)
    local hot = options.expand and options.expandCorner ~= false
    Into(Arrow(board), screen, hot and at or nil)
    local say
    if not hot then
        say = Hued(Setup.TEXT.off)
    elseif not at then
        say = "Docked in no corner, the chat has none: dock it in Edit Mode, or use a key."
    else
        say = Hued(Setup.TEXT.into .. (options.expandClick and Setup.TEXT.click or "")) .. " " .. Setup.TEXT.fills
    end
    Caption(board, "words", 40 + Setup.SCREEN[2] + 16, say)
end

-- The keys bound to a command in the game's words ("Shift-M"), or nil.
local function KeyWords(command)
    local keys = { Core.Ask(rawget(_G, "GetBindingKey"), command) }
    local said = {}
    for _, key in ipairs(keys) do
        if type(key) == "string" and key ~= "" then
            local words = Core.Ask(rawget(_G, "GetBindingText"), key)
            said[#said + 1] = type(words) == "string" and words ~= "" and words or key
        end
    end
    return #said > 0 and table.concat(said, ", ") or nil
end

-- What each key opens, and the key it has now.
function DRAW.keys(board)
    local full = KeyWords("SANEUI_SOCIAL_FULL")
    local chat = KeyWords("SANEUI_SOCIAL")
    local none = Core.Word("NOT_BOUND", "Not bound")
    Caption(board, "full", 90, Hued(Setup.TEXT.keyFull) .. "\n" .. (full or none))
    Caption(board, "chat", 170, Hued(Setup.TEXT.keyChat) .. "\n" .. (chat or none))
    Caption(board, "together", 260, "The hot corner and the keys work side by side.")
end

-- The screen with the windows ticked: SaneUI's chat, the game's beside it, the second chat above it.
function DRAW.windows(board)
    local options = ns.options
    local screen = Screen(board, "screen", 40)
    local chat = Part(board, "chat", function() return Chat(screen, Setup.TEXT.chat) end)
    local game = Part(board, "game", function() return Chat(screen, Setup.TEXT.game, Setup.GAME) end)
    local second = Part(board, "second", function() return Chat(screen, Setup.TEXT.secondChat) end)
    local at = Zone() or "BOTTOMLEFT"
    Dock(chat, screen, at)
    chat:SetShown(options.window ~= false)
    game:ClearAllPoints()
    game:SetSize(Setup.CHAT[1], Setup.CHAT[2])
    if options.window ~= false then
        game:SetPoint("BOTTOMLEFT", chat, "BOTTOMRIGHT", 6, 0)
    else
        Dock(game, screen, at)
    end
    game:SetShown(options.window == false or options.showNative == true)
    second:ClearAllPoints()
    second:SetSize(Setup.CHAT[1], Setup.CHAT[2])
    second:SetPoint("BOTTOMLEFT", chat, "TOPLEFT", 0, 6)
    second:SetShown(options.window ~= false and SecondShown())
    Caption(board, "words", 40 + Setup.SCREEN[2] + 16, Hued("On the screen") .. " as ticked at the right.")
end

-- A drawn full screen: the conversations in their parts at the left, the chat beside them, and at the right the guild
-- window over the friends list, each as ticked (the layout chosen).
function DRAW.full(board)
    local screen = Screen(board, "screen", 30)
    local list = Part(board, "list", function()
        local panel = Boxed(screen, Setup.FULL)
        local lines = {}
        local rows = { { Setup.TEXT.whispers, true }, { "Thrall" }, { "Jaina" }, { Setup.TEXT.groups, true }, { "Party: Thrall, Jaina" } }
        for index, row in ipairs(rows) do
            local words = panel:CreateFontString(nil, "OVERLAY")
            Look.SetFont(words, 10, false, row[2] and Look.GOLD or Look.INK)
            words:SetPoint("TOPLEFT", panel, "TOPLEFT", row[2] and 6 or 14, -6 - (index - 1) * 16)
            words:SetText((row[2] and "- " or "") .. row[1])
            lines[index] = words
        end
        panel.lines = lines
        return panel
    end)
    local width, height = Setup.SCREEN[1], Setup.SCREEN[2]
    local friendsOn, guildOn = ns.Board.Holds("friends"), ns.Board.Holds("guild")
    local column = (friendsOn or guildOn) and math.floor(width * 0.28) or 0
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", screen, "TOPLEFT", 6, -6)
    list:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 6, 6)
    list:SetWidth(math.floor(width * 0.34))
    local chat = Part(board, "chat", function() return Chat(screen, Setup.TEXT.chat, Setup.FULL) end)
    chat:ClearAllPoints()
    chat:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, 0)
    chat:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -(6 + (column > 0 and column + 4 or 0)), 6)
    local guild = Part(board, "guild", function() return Chat(screen, Setup.TEXT.guild, Setup.FULL) end)
    local friends = Part(board, "friends", function() return Chat(screen, Setup.TEXT.friends, Setup.FULL) end)
    guild:ClearAllPoints()
    guild:SetPoint("TOPRIGHT", screen, "TOPRIGHT", -6, -6)
    guild:SetSize(math.max(column, 1), friendsOn and math.floor((height - 16) * 0.45) or height - 12)
    guild:SetShown(guildOn)
    friends:ClearAllPoints()
    friends:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -6, 6)
    friends:SetSize(math.max(column, 1), guildOn and height - 16 - math.floor((height - 16) * 0.45) or height - 12)
    friends:SetShown(friendsOn)
    Caption(board, "words", 30 + height + 12, Hued("Full screen") .. ": the conversations in their parts, the chat beside "
        .. "them" .. ((friendsOn or guildOn) and ", at the right what you ticked." or "."))
end

-- The step's board on the stage, the others out of sight; drawn anew as the settings in use say.
local function Stage(stage, step)
    for key, board in pairs(boards) do board:SetShown(key == step.key) end
    local draw = DRAW[step.key]
    if not draw then return end
    local board = boards[step.key]
    if not board then
        board = CreateFrame("Frame", nil, stage)
        board:SetAllPoints(stage)
        board.parts = {}
        boards[step.key] = board
    end
    draw(board)
    board:Show()
end

-- For the tests: a step's board, once drawn.
function Setup.Board(key) return boards[key] end

Core.Onboarding.Add(ns.name, {
    title = Setup.TITLE,
    steps = Setup.STEPS,
    aliases = { chat = "intro" },
    Stage = function(stage, step, index) ns.Safe("setup sample", Stage, stage, step, index) end,
})
