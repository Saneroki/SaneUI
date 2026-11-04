local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - LevelUp
--  A new level, told once below the screen's top, right of its middle beside
--  the guide's arrow (Saneroki, 2026-11-04), in place of the game's toast and
--  its lines in the chat (Saneroki, 2026-10-30):
--
--      Level 22!
--      HP +18
--      Mana +20
--      Str +2
--      Stam +1
--      Talent +1
--      Leveled 7h
--
--  What it brought comes with the game's PLAYER_LEVEL_UP, in Core's short
--  words; a line only for what grew. The time is the game's: it tells your
--  time on this level at TIME_PLAYED_MSG, asked once after the login; from
--  there GetTime() counts on. It is asked with the chat windows deaf to that
--  one answer, so /played stays as it was.
--
--  The chat: its windows write those lines when they hear PLAYER_LEVEL_UP
--  themselves, and Social's window takes what they write. So they no longer
--  hear it (Core.Lend, the frames left as they are; given back at GiveBack).
--  The game adds that event to a window again whenever the player changes what
--  the window shows, so it is checked at each XP gain.
--
--  The game's toast (EventToastManagerFrame) must run its course: its own
--  animations end it and bring the next one, and those stop on a hidden frame.
--  So while it tells a level it stands under a frame of ours at alpha 0, and
--  any other toast of the game's shows as ever.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local LevelUp = {}
ns.LevelUp = LevelUp

LevelUp.WIDTH = 240     -- its shade, without the edges that fade out
LevelUp.EDGE = 90
LevelUp.PAD = 12
LevelUp.RIGHT = 340     -- right of the screen's middle (Saneroki, 2026-11-04): the guide's arrow, 240 wide, stands in the
                        -- middle at this height and stays in sight; the shade's fading left edge ends beside it
LevelUp.TITLE = 34      -- the level's font size, its line's height with some air
LevelUp.TITLE_HEIGHT = 42
LevelUp.LINE = 19       -- the lines under it
LevelUp.LINE_HEIGHT = 24
LevelUp.DARK = 0.45     -- the shade behind it
LevelUp.FADE_IN = 0.3
LevelUp.HOLD = 5
LevelUp.FADE_OUT = 1
LevelUp.ASK_AFTER = 5   -- seconds after the login: by then every chat window has its events
LevelUp.ASK_MOST = 10   -- the seconds an answer may take, before the chat hears /played again anyway

local FONT = "Interface\\AddOns\\SaneUI\\Fonts\\Expressway.ttf"
local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 1, 1 }
local GREY = { 0.72, 0.72, 0.72 }
-- The stats in the order the game's event gives them.
local STATS = { { "SPELL_STAT1_NAME", "Strength" }, { "SPELL_STAT2_NAME", "Agility" }, { "SPELL_STAT3_NAME", "Stamina" },
                { "SPELL_STAT4_NAME", "Intellect" }, { "SPELL_STAT5_NAME", "Spirit" } }
-- Retail writes its line at the second, WoW: Forever at the first.
local LINES = { "PLAYER_LEVEL_UP", "PLAYER_LEVEL_CHANGED" }
local ANSWER = { "TIME_PLAYED_MSG" }

local view, title, fade
local rows = {}
local deaf = {}         -- [a chat window] = its lend while it does not hear LINES
local waiting           -- the chat windows' lends while they do not hear ANSWER
local thisLevel, told   -- what the game said of your time on this level, and when (GetTime)
local game              -- the game's toast
local lent, under       -- its lend while ours stands in for it, and the frame it stands under
local turn = 0          -- the toast shown last: a new level while one shows keeps the old one's end from it

-------------------------------------------------------------------------------
--  How long you played on the level
-------------------------------------------------------------------------------
-- How long a time is, as short as the toast has it: 7h 12m, 35m, 40s.
function LevelUp.Took(seconds)
    if seconds >= 3600 then return ("%dh %dm"):format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)) end
    if seconds >= 60 then return ("%dm"):format(math.floor(seconds / 60)) end
    return ("%ds"):format(math.floor(seconds))
end

local function Hear()
    if not waiting then return end
    local lends = waiting
    waiting = nil
    for _, lend in ipairs(lends) do ns.Safe("level up", lend.Return, lend) end
end
-- A frame later: the answer is on its way to the windows until then.
local HearLater = Core.Later(Hear)

local function Told(_, level)
    level = Core.Plain(level)
    if type(level) == "number" then thisLevel, told = level, GetTime() end
    if waiting then HearLater() end
end

function LevelUp.Ask()
    local request = rawget(_G, "RequestTimePlayed")
    if not request or ns.off or thisLevel or waiting then return end
    waiting = {}
    for _, name in ipairs(rawget(_G, "CHAT_FRAMES") or {}) do
        local frame = rawget(_G, name)
        if frame and frame:IsEventRegistered(ANSWER[1]) then
            local lend = Core.Lend(frame)
            if lend:SetDeaf(ANSWER) then waiting[#waiting + 1] = lend end
        end
    end
    request()
    C_Timer.After(LevelUp.ASK_MOST, ns.Guard(Hear))
end

-------------------------------------------------------------------------------
--  The game's lines in the chat
-------------------------------------------------------------------------------
local function Deafen()
    if ns.off then return end
    for _, name in ipairs(rawget(_G, "CHAT_FRAMES") or {}) do
        local frame = rawget(_G, name)
        if frame and (frame:IsEventRegistered(LINES[1]) or frame:IsEventRegistered(LINES[2])) then
            deaf[frame] = deaf[frame] or Core.Lend(frame)
            deaf[frame]:SetDeaf(LINES)
        end
    end
end

local function Undeafen()
    for frame, lend in pairs(deaf) do
        deaf[frame] = nil
        ns.Safe("level up", lend.Return, lend)
    end
end

-------------------------------------------------------------------------------
--  The game's toast
-------------------------------------------------------------------------------
local function Release()
    if not lent then return end
    local lend = lent
    lent = nil
    lend:Return()
end

-- Each toast of the game's: one that tells your level goes unseen, any other is seen. No toast left: as it was.
local function Toasted()
    local shown = game.currentDisplayingToast
    local info = shown and shown.toastInfo
    local kinds = Enum and Enum.EventToastEventType
    if info and kinds and not ns.off and Core.Plain(info.eventType) == kinds.LevelUp then
        if lent then return end
        if not under then
            under = CreateFrame("Frame", nil, UIParent)
            under:SetAllPoints(UIParent)
            under:SetAlpha(0)
        end
        lent = Core.Lend(game)
        lent:SetLayer()
        lent:SetParent(under)
    else
        Release()
    end
end

-------------------------------------------------------------------------------
--  Ours
-------------------------------------------------------------------------------
-- A part of the dark behind it, left to right: its middle is even, its edges fade out into the world.
local function Shade(parent, from, to)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetColorTexture(1, 1, 1, 1)
    if texture.SetGradient and rawget(_G, "CreateColor") then
        texture:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, from), CreateColor(0, 0, 0, to))
    else
        texture:SetVertexColor(0, 0, 0, (from + to) / 2)
    end
    return texture
end

local function Build()
    view = CreateFrame("Frame", nil, UIParent)
    view:SetFrameStrata("HIGH")
    view:SetPoint("TOP", UIParent, "TOP", LevelUp.RIGHT, -Core.TOAST_TOP)
    view:SetWidth(LevelUp.WIDTH)
    -- In sight while Lore fades the interface out for a talk: a quest handed in is where most levels come.
    if view.SetIgnoreParentAlpha then view:SetIgnoreParentAlpha(true) end
    view:Hide()
    fade = Core.Motion.Fade(view)

    local middle, left, right = Shade(view, LevelUp.DARK, LevelUp.DARK), Shade(view, 0, LevelUp.DARK), Shade(view, LevelUp.DARK, 0)
    middle:SetAllPoints(view)
    left:SetPoint("TOPRIGHT", view, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", view, "BOTTOMLEFT", 0, 0)
    left:SetWidth(LevelUp.EDGE)
    right:SetPoint("TOPLEFT", view, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMLEFT", view, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(LevelUp.EDGE)

    title = view:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, LevelUp.TITLE, "OUTLINE")
    title:SetPoint("TOP", 0, -LevelUp.PAD)
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
end

local function Row(index)
    local row = rows[index]
    if not row then
        row = view:CreateFontString(nil, "OVERLAY")
        row:SetFont(FONT, LevelUp.LINE, "OUTLINE")
        row:SetPoint("TOP", 0, -LevelUp.PAD - LevelUp.TITLE_HEIGHT - (index - 1) * LevelUp.LINE_HEIGHT)
        rows[index] = row
    end
    return row
end

-- level: the new one; lines: what it brought (LevelUp.Lines); took: how long the last one took, nil when the game has
-- not said.
function LevelUp.Show(level, lines, took)
    if not view then Build() end
    title:SetText(ns.TEXT.levelTitle:format(level))
    local count = #lines
    for index, line in ipairs(lines) do
        local row = Row(index)
        row:SetText(line)
        row:SetTextColor(WHITE[1], WHITE[2], WHITE[3])
        row:Show()
    end
    if took then
        count = count + 1
        local row = Row(count)
        row:SetText(ns.TEXT.levelTook:format(took))
        row:SetTextColor(GREY[1], GREY[2], GREY[3])
        row:Show()
    end
    for index = count + 1, #rows do rows[index]:Hide() end
    view:SetHeight(2 * LevelUp.PAD + LevelUp.TITLE_HEIGHT + count * LevelUp.LINE_HEIGHT)
    view:Show()
    fade:To(1, LevelUp.FADE_IN, 0)

    turn = turn + 1
    local mine = turn
    C_Timer.After(LevelUp.FADE_IN + LevelUp.HOLD, ns.Guard(function()
        if mine ~= turn then return end
        fade:To(0, LevelUp.FADE_OUT)
        C_Timer.After(LevelUp.FADE_OUT, ns.Guard(function()
            if mine == turn then view:Hide() end
        end))
    end))
end

local function Gain(lines, word, amount)
    amount = Core.Plain(amount)
    if type(amount) == "number" and amount > 0 then lines[#lines + 1] = ns.TEXT.levelStat:format(word, amount) end
end

-- What a level brought, as lines: the event's values after the level, in the order the chat told them but for the
-- talent points, which close the list. The game says "mana" for its second number, as this does.
function LevelUp.Lines(health, power, talents, _, ...)
    local lines = {}
    Gain(lines, Core.StatWord(Core.Word("HEALTH", "Health")), health)
    Gain(lines, Core.Word("MANA", "Mana"), power)
    for index, stat in ipairs(STATS) do
        Gain(lines, Core.StatWord(Core.Word(stat[1], stat[2])), (select(index, ...)))
    end
    Gain(lines, ns.TEXT.levelTalent, talents)
    return lines
end

local function Leveled(level, ...)
    level = Core.Plain(level)
    if not ns.off and type(level) == "number" then
        LevelUp.Show(level, LevelUp.Lines(...), thisLevel and LevelUp.Took(thisLevel + GetTime() - told) or nil)
    end
    if thisLevel then thisLevel, told = 0, GetTime() end -- the time on the new level starts now
end

-------------------------------------------------------------------------------
--  The module
-------------------------------------------------------------------------------
function LevelUp.GiveBack()
    Hear()
    Undeafen()
    Release()
    turn = turn + 1
    if view then view:Hide() end
end

function LevelUp.Start()
    ns.On("PLAYER_LEVEL_UP", Leveled)
    ns.On("TIME_PLAYED_MSG", Told)
    ns.On("PLAYER_XP_UPDATE", Deafen)
    ns.On("PLAYER_ENTERING_WORLD", Deafen)
    game = rawget(_G, "EventToastManagerFrame")
    if game then hooksecurefunc(game, "DisplayToast", ns.Guard(Toasted)) end
    C_Timer.After(LevelUp.ASK_AFTER, ns.Guard(LevelUp.Ask))
end
