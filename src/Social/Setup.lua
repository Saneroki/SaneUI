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
--    corner   the hot corner and the keys on one page (Saneroki, 2026-11-18:
--             "Same for Social setup with the Hotcorner and or a key page", as
--             Navigation's): the screen's corner the chat is docked in fills
--             the screen with Social and brings it back; not at all, with a left
--             click, or with the mouse alone (one choice over three switches:
--             Can expand to fullscreen, Hotcorner, Hotcorner requires leftclick);
--             under it a key of its own for the full screen, and the chat
--             window's key; they work beside the corner
--    windows  the windows: the chat window itself, the game's chat beside it,
--             the second chat as a window of its own on the screen (a chat view:
--             no switch, its own tick, ChatWindows.lua), the group finder's tab
--    messages your messages (Saneroki, 2026-11-18: "ask the user if they want
--             your own messages to be on the left or right side", "how long
--             messages should stay on screen before disappearing", "bubble
--             oppacity", "tell them that they can scroll the window to see older
--             messages"): their side, Fade out and Fade messages after, Bubble
--             opacity; a drawn chat that shows each choice
--    keep     what is kept ("ask if the user wants a new conversation each time
--             they join a new party and how many messages should be saved"):
--             Save chat history and Messages kept, Messages kept per
--             conversation, A new conversation for each group; a drawn list of
--             the conversations as the choice makes them
--    full     the full screen: the conversations in parts (whispers, groups),
--             a head folds its part; chat views; the friends list and the guild
--             window ticked into its layout or out of it (Saneroki, 2026-11-18:
--             "Add the friends list and guild window to the setup too"; the
--             layout chosen, also while the full screen is away: Board.Put);
--             its drawn full screen in the first layout's columns
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
    cornerTip = "The screen's corner (or edge) the chat is docked to fills the screen with Social, and brings it back. Not at all: only its key does (below).",
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
    you = "You",
    wheel = "The mouse wheel over the chat: older messages, scrolled back.",
    fadeAfter = "They fade out %d seconds after they come.",
    fadeNever = "They stay: no fading out.",
    kept = "The chat keeps its last %d messages over a logout.",
    keptNone = "The chat starts empty at each login.",
    keptTalk = "Each conversation keeps its last %d.",
    eachGroup = "A new conversation for each group.",
    oneGroup = "One conversation for all your groups.",
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
    { key = "corner", title = "The hot corner, or a key",
      text = Lines({ "The hot corner", "the screen's corner your chat is docked in: the arrow points at it." },
          { "Into it", "the mouse all the way into it, or into it and a left click: Social fills the screen." },
          { "Or a key", "Social's full screen and the chat window, each by a key of its own if you want one." },
          { "A key", "click its box, press the key. Right click: no key. They all work together." }),
      settings = { { key = "expandCorner", text = Setup.TEXT.corner, tip = Setup.TEXT.cornerTip, column = true, parent = false,
                     choices = { { { expand = true, expandCorner = false }, Setup.TEXT.cornerOff },
                                 { { expand = true, expandCorner = true, expandClick = true }, Setup.TEXT.cornerClick },
                                 { { expand = true, expandCorner = true, expandClick = false }, Setup.TEXT.cornerHover } } },
                   { binding = "SANEUI_SOCIAL_FULL", text = Setup.TEXT.keyFull, tip = Setup.TEXT.keyFullTip },
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
    { key = "messages", title = "Your messages",
      text = Lines({ "Yours", "on the right, as in a messenger, or on the left with your name, as everybody else's." },
          { "They fade", "out a while after they come, as long as set here. Off: they stay." },
          { "Older ones", "turn the mouse wheel over the chat: it scrolls back to them." },
          { "The bubbles", "as solid as you like: 100 % solid, 0 % only the words." }),
      settings = { "mineSide", "fade", "fadeAfter", "bubbleOpacity" } },
    { key = "keep", title = "What is kept",
      text = Lines({ "The chat", "keeps its last messages over a logout, as many as set here." },
          { "Each conversation", "keeps its own last messages too: every whisper, every group." },
          { "A group you join", "a conversation of its own each time, or one for all your parties and raids." }),
      settings = { "history", "historySize", "talkSize", "groupEach" } },
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
    -- Under it what each key opens and the key it has now (the boxes at the step's right set them).
    local none = Core.Word("NOT_BOUND", "Not bound")
    Caption(board, "keyFull", 330, Hued(Setup.TEXT.keyFull) .. ": " .. (KeyWords("SANEUI_SOCIAL_FULL") or none))
    Caption(board, "keyChat", 360, Hued(Setup.TEXT.keyChat) .. ": " .. (KeyWords("SANEUI_SOCIAL") or none))
    Caption(board, "together", 400, "The hot corner and the keys work side by side.")
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

-- A drawn message: an icon and a name above a bubble (somebody's, or yours on the left), or a bubble alone at the right
-- (yours); the bubble as solid as Bubble opacity, its words always there.
local function Message(board, parent, name)
    return Part(board, name, function()
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(Setup.SCREEN[1] - 24, 34)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(14, 14)
        row.name = row:CreateFontString(nil, "OVERLAY")
        Look.SetFont(row.name, 10, false)
        row.bubble = row:CreateTexture(nil, "BACKGROUND")
        row.words = row:CreateTexture(nil, "ARTWORK")
        row.words:SetColorTexture(0.85, 0.85, 0.85, 1)
        return row
    end)
end

local function Lay(row, left, who, class, width)
    row.icon:ClearAllPoints()
    row.name:ClearAllPoints()
    row.bubble:ClearAllPoints()
    row.icon:SetShown(left)
    row.name:SetShown(left)
    if left then
        local colour = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.icon:SetColorTexture(colour and colour.r or 0.6, colour and colour.g or 0.6, colour and colour.b or 0.6, 1)
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.name:SetText(who)
        if colour then row.name:SetTextColor(colour.r, colour.g, colour.b) end
        row.bubble:SetPoint("TOPLEFT", row, "TOPLEFT", 18, -16)
    else
        row.bubble:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -16)
    end
    row.bubble:SetSize(width, 16)
    row.words:ClearAllPoints()
    row.words:SetPoint("LEFT", row.bubble, "LEFT", 6, 0)
    row.words:SetSize(width - 12, 3)
end

-- The chat drawn with somebody's messages and yours, on the side chosen, the bubbles as solid as set, the older ones
-- faded as Fade out says; under it what each choice does, and that the wheel brings older ones back.
function DRAW.messages(board)
    local options = ns.options
    local screen = Part(board, "chat", function() return Boxed(board, Setup.FULL) end)
    screen:ClearAllPoints()
    screen:SetSize(Setup.SCREEN[1], 230)
    screen:SetPoint("TOP", board, "TOP", 0, -30)
    local left = options.mineSide == "left"
    local opacity = math.max(math.min((tonumber(options.bubbleOpacity) or 50) / 100, 1), 0)
    local fading = options.animations ~= false and options.fade ~= false
    local _, class = Core.Ask(UnitClass, "player")
    local rows = { { "Thrall", "SHAMAN", 150 }, { false, nil, 110 }, { "Jaina", "MAGE", 180 }, { false, nil, 90 } }
    for index, spec in ipairs(rows) do
        local row = Message(board, screen, "message" .. index)
        local mine = spec[1] == false
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", screen, "TOPLEFT", 12, -10 - (index - 1) * 52)
        Lay(row, not mine or left, mine and Setup.TEXT.you or spec[1], mine and class or spec[2], spec[3])
        row.bubble:SetColorTexture(Setup.PLATE[1], Setup.PLATE[2], Setup.PLATE[3], opacity)
        row:SetAlpha(fading and index <= 2 and 0.3 or 1) -- the older two faded out
    end
    local after = tonumber(options.fadeAfter) or 10
    Caption(board, "fades", 30 + 230 + 14, fading and Setup.TEXT.fadeAfter:format(after) or Setup.TEXT.fadeNever)
    Caption(board, "wheel", 30 + 230 + 44, Hued(Setup.TEXT.wheel))
end

-- The conversations drawn as they are kept: the whispers, and the groups' (one each, or one for all as chosen);
-- beside it how many messages the chat and each conversation keep.
function DRAW.keep(board)
    local options = ns.options
    local list = Part(board, "list", function()
        local panel = Boxed(board, Setup.FULL)
        panel.lines = {}
        for index = 1, 7 do
            local words = panel:CreateFontString(nil, "OVERLAY")
            Look.SetFont(words, 11, false)
            words:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8 - (index - 1) * 20)
            words:SetJustifyH("LEFT")
            panel.lines[index] = words
        end
        return panel
    end)
    list:ClearAllPoints()
    list:SetSize(Setup.SCREEN[1], 160)
    list:SetPoint("TOP", board, "TOP", 0, -30)
    local each = options.groupEach ~= false
    local lines = { Hued("- " .. Setup.TEXT.whispers), "   Thrall", "   Jaina", Hued("- " .. Setup.TEXT.groups) }
    if each then
        lines[#lines + 1] = "   Party: Varian, Anduin"
        lines[#lines + 1] = "   Party: Thrall, Jaina"
        lines[#lines + 1] = "   Raid: Rexxar, Valeera +12"
    else
        lines[#lines + 1] = "   Party: Varian, Anduin"
    end
    for index, words in ipairs(list.lines) do words:SetText(lines[index] or "") end
    local history = options.history ~= false
    Caption(board, "kept", 30 + 160 + 16, history and Setup.TEXT.kept:format(tonumber(options.historySize) or 100)
        or Setup.TEXT.keptNone)
    Caption(board, "keptTalk", 30 + 160 + 42, Setup.TEXT.keptTalk:format(tonumber(options.talkSize) or 100))
    Caption(board, "groups", 30 + 160 + 68, Hued(each and Setup.TEXT.eachGroup or Setup.TEXT.oneGroup))
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
            words:SetJustifyH("LEFT")
            words:SetWordWrap(false)
            words:SetText((row[2] and "- " or "") .. row[1])
            words.inset = row[2] and 6 or 14
            lines[index] = words
        end
        panel.lines = lines
        return panel
    end)
    -- As the first layout has them (Layout.SHARES, Saneroki's picture): side by side, as high as the screen, the
    -- conversations (their list and the chat beside it), the friends list, the guild window; one not ticked gives
    -- its room to the conversations.
    local width, height = Setup.SCREEN[1], Setup.SCREEN[2]
    local friendsOn, guildOn = ns.Board.Holds("friends"), ns.Board.Holds("guild")
    local shares = ns.Layout.SHARES
    local whole = shares.talks + shares.friends + shares.guild
    local room = width - 12 - (friendsOn and 4 or 0) - (guildOn and 4 or 0)
    local friendsWide = friendsOn and math.floor(room * shares.friends / whole) or 0
    local guildWide = guildOn and math.floor(room * shares.guild / whole) or 0
    local talksWide = room - friendsWide - guildWide
    local listWide = math.floor(talksWide * 0.5)
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", screen, "TOPLEFT", 6, -6)
    list:SetSize(listWide, height - 12)
    for _, words in ipairs(list.lines) do words:SetWidth(math.max(listWide - words.inset - 2, 1)) end
    local chat = Part(board, "chat", function() return Chat(screen, Setup.TEXT.chat, Setup.FULL) end)
    chat:ClearAllPoints()
    chat:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, 0)
    chat:SetSize(math.max(talksWide - listWide - 4, 1), height - 12)
    local friends = Part(board, "friends", function() return Chat(screen, Setup.TEXT.friends, Setup.FULL) end)
    friends:ClearAllPoints()
    friends:SetPoint("TOPLEFT", screen, "TOPLEFT", 6 + talksWide + 4, -6)
    friends:SetSize(math.max(friendsWide, 1), height - 12)
    friends:SetShown(friendsOn)
    local guild = Part(board, "guild", function() return Chat(screen, Setup.TEXT.guild, Setup.FULL) end)
    guild:ClearAllPoints()
    guild:SetPoint("TOPRIGHT", screen, "TOPRIGHT", -6, -6)
    guild:SetSize(math.max(guildWide, 1), height - 12)
    guild:SetShown(guildOn)
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
