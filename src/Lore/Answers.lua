local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Answers
--  What you can answer, a column beside the words (Saneroki, 2026-10-28): its
--  top level with the box's top, right of it. A line an answer, each a dark bar
--  of its own (Look.Plate), its border grey and its words gold under the mouse,
--  apart from the next (Saneroki, 2026-11-11): the game's picture for its kind at the
--  left (a quest to hand in, offered, not done yet; the NPC's own picture for
--  its other options), the words beside it. A quest far below your level is
--  dimmed, as the game does; an answer that cannot be given yet (a quest not
--  done) is greyed out. A click gives the answer (Talk.Answer). An NPC's
--  service with a large picture, and Goodbye, stand over the talk instead
--  (Icons.lua).
--  Always on the screen (Saneroki, 2026-11-11: a guard's many answers went
--  past its bottom, out of reach): a column that would reach past the screen's
--  foot is lifted until it stands on it; one taller than the screen shows the
--  lines that fit, the game's small scroll arrows over and under them where
--  more lie that way, and the mouse wheel or a click on an arrow goes on a line.
--  One that would reach past the screen's right side (a large Size) moves the
--  talk left as far as it needs, the box never past the left side; past that
--  the column lies over the box's right edge.
--
--      Answers.Draw(talk)    the talk's answers, beside the box
--      Answers.Place()       the column placed anew (the box's height changed)
--      Answers.Scroll(step)  so many lines on (down), or back (negative)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Answers = {}
ns.Answers = Answers

Answers.WIDTH = 288 -- a line's width
Answers.GAP = 10    -- between the box and the column, as between the box and the quest
Answers.SPACE = 4   -- between two lines
Answers.PAD = 7     -- inside a line's shade
Answers.ICON = 16
Answers.MARGIN = 24 -- the column's distance from the screen's top and bottom, at the least
Answers.ARROW = 22  -- the room of a scroll arrow over and under a column taller than the screen
Answers.ARROW_SIZE = { 26, 17 } -- the arrow, the game's (17 x 11) half as large again: a mark to see and click

-- The game's pictures for a quest in a talk.
local ICONS = {
    offer = "Interface\\GossipFrame\\AvailableQuestIcon",
    offerAgain = "Interface\\GossipFrame\\DailyQuestIcon",
    offerLegend = "Interface\\GossipFrame\\AvailableLegendaryQuestIcon",
    done = "Interface\\GossipFrame\\ActiveQuestIcon",
    doneAgain = "Interface\\GossipFrame\\DailyActiveQuestIcon",
    doneLegend = "Interface\\GossipFrame\\ActiveLegendaryQuestIcon",
    open = "Interface\\GossipFrame\\IncompleteQuestIcon",
}
-- The game's own small scroll arrows (its minimal scroll bar's), with their looks under the mouse and pressed.
local ARROWS = { up = "minimal-scrollbar-small-arrow-top", down = "minimal-scrollbar-small-arrow-bottom" }

local column, up, down
local lines = {}
local listed = {} -- the answers in the column, in order (lines[i] shows listed[i])
local first = 1   -- the first line shown
local drawn       -- the talk they are of: a new one starts at its first line

local function Hover(line, on)
    line.plate:SetLit(on)
    if not line.answer or line.answer.disabled then return end
    if on then line.text:SetTextColor(1, 0.82, 0) else line.text:SetTextColor(1, 1, 1) end
end

local function Line(index)
    if lines[index] then return lines[index] end
    local line = CreateFrame("Button", nil, column)
    line:SetWidth(Answers.WIDTH)
    line.plate = ns.Look.Plate(line)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(Answers.ICON, Answers.ICON)
    line.icon:SetPoint("TOPLEFT", line, "TOPLEFT", Answers.PAD, -Answers.PAD)
    line.text = ns.Look.Text(line, "answer")
    line.text:SetPoint("TOPLEFT", line, "TOPLEFT", Answers.PAD * 2 + Answers.ICON, -Answers.PAD)
    line.text:SetWidth(Answers.WIDTH - Answers.PAD * 3 - Answers.ICON)
    line:SetScript("OnClick", ns.Guard(function(self) ns.Talk.Answer(self.answer) end))
    line:SetScript("OnEnter", ns.Guard(function(self) Hover(self, true) end))
    line:SetScript("OnLeave", ns.Guard(function(self) Hover(self, false) end))
    lines[index] = line
    return line
end

local function Picture(line, answer)
    local icon = answer.icon
    if answer.quest then
        local again = answer.repeatable and "Again" or (answer.legend and "Legend") or ""
        icon = answer.offer and ICONS["offer" .. again] or (answer.complete and ICONS["done" .. again]) or ICONS.open
    end
    line.icon:SetTexture(icon)
    line.icon:SetShown(icon ~= nil)
    local dim = answer.trivial or answer.disabled
    line.icon:SetVertexColor(dim and 0.5 or 1, dim and 0.5 or 1, dim and 0.5 or 1)
end

local function Fill(line, answer)
    line.answer = answer
    line.text:SetText(answer.text or "")
    Picture(line, answer)
    if answer.disabled or answer.trivial then
        line.text:SetTextColor(unpack(ns.Look.GREY))
    else
        line.text:SetTextColor(1, 1, 1)
    end
    line.plate:SetLit(false)
    line:SetHeight(math.max(Answers.ICON, Core.Plain(line.text:GetStringHeight()) or 0) + Answers.PAD * 2)
    line.plate:Fit()
end

local function Arrow(direction)
    local arrow = CreateFrame("Button", nil, column)
    arrow:SetSize(unpack(Answers.ARROW_SIZE))
    arrow:SetNormalAtlas(ARROWS[direction])
    arrow:SetHighlightAtlas(ARROWS[direction] .. "-over")
    arrow:SetPushedAtlas(ARROWS[direction] .. "-down")
    local inset = (Answers.ARROW - Answers.ARROW_SIZE[2]) / 2
    arrow:SetPoint(direction == "up" and "TOP" or "BOTTOM", column, direction == "up" and "TOP" or "BOTTOM", 0,
                   direction == "up" and -inset or inset)
    arrow:SetScript("OnClick", ns.Guard(function() Answers.Scroll(direction == "up" and -1 or 1) end))
    return arrow
end

local function Build()
    column = CreateFrame("Frame", nil, ns.Look.Root())
    column:SetWidth(Answers.WIDTH)
    column:SetScript("OnMouseWheel", ns.Guard(function(_, delta) Answers.Scroll(delta > 0 and -1 or 1) end))
    up, down = Arrow("up"), Arrow("down")
end

-------------------------------------------------------------------------------
--  On the screen
-------------------------------------------------------------------------------
-- The screen's height or width in the talk's units (nil while the screen tells none).
local function Screen(side)
    local size = Core.Plain(side == "width" and UIParent:GetWidth() or UIParent:GetHeight())
    if type(size) ~= "number" or size <= 0 then return nil end
    return size / (Core.Plain(ns.Look.Root():GetScale()) or 1)
end

-- How tall the column may be: the screen less its margins (no limit while the screen tells none).
local function Room()
    local height = Screen("height")
    return height and height - Answers.MARGIN * 2 or math.huge
end

-- Across: the talk moved left so far that the column ends inside the screen's right margin, the box's left side
-- not past the left one; what is still over, the column's own way left over the box. Its offset from the box.
local function Across()
    local width = Screen("width")
    local half = ns.Box.WIDTH / 2
    local over = width and half + Answers.GAP + Answers.WIDTH - (width / 2 - Answers.MARGIN) or 0
    local moved = over > 0 and math.min(over, math.max(0, width / 2 - Answers.MARGIN - half)) or 0
    ns.Box.Shift(-moved)
    return Answers.GAP - math.max(0, over - moved)
end

local function Tall(index)
    return Core.Plain(lines[index]:GetHeight()) or 0
end

-- The lines from `from` on that fit in so much room (one at least): the last of them, and how tall they stand.
local function Fit(from, room)
    local used, last = 0, from - 1
    for index = from, #listed do
        local add = Tall(index) + (index > from and Answers.SPACE or 0)
        if index > from and used + add > room then break end
        used, last = used + add, index
    end
    return last, used
end

-- The first line from which the last ones fill the room.
local function Furthest(room)
    local used = 0
    for index = #listed, 1, -1 do
        used = used + Tall(index) + (index < #listed and Answers.SPACE or 0)
        if used > room then return math.min(index + 1, #listed) end
    end
    return 1
end

function Answers.Place()
    if not column or #listed == 0 then return end
    local room = Room()
    local last, used = Fit(1, math.huge)
    local scrolled = used > room
    local over = 0 -- room over the first line, for its arrow
    if scrolled then
        local inner = room - Answers.ARROW * 2
        first = math.max(1, math.min(first, Furthest(inner)))
        last, used = Fit(first, inner)
        over = Answers.ARROW
        used = used + Answers.ARROW * 2
    else
        first = 1
    end
    local above
    for index, line in ipairs(lines) do
        if index >= first and index <= last then
            line:ClearAllPoints()
            if above then
                line:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -Answers.SPACE)
            else
                line:SetPoint("TOPLEFT", column, "TOPLEFT", 0, -over)
            end
            line:Show()
            above = line
        else
            line:Hide()
        end
    end
    up:SetShown(scrolled and first > 1)
    down:SetShown(scrolled and last < #listed)
    column:EnableMouseWheel(scrolled)
    column:SetHeight(used)
    -- Its top level with the box's, lifted while its foot would be past the screen's.
    local top = ns.Box.Top()
    local lifted = math.max(top, Answers.MARGIN + used)
    column:ClearAllPoints()
    column:SetPoint("TOPLEFT", ns.Box.Frame(), "TOPRIGHT", Across(), lifted - top)
end

function Answers.Scroll(step)
    if not column then return end
    first = first + step
    Answers.Place()
end

function Answers.Draw(talk)
    if not column then Build() end
    if talk ~= drawn then first = 1 end
    drawn = talk
    listed = {}
    for _, answer in ipairs(talk.answers) do
        if not ns.Icons.Shown(answer) then listed[#listed + 1] = answer end
    end
    for index, answer in ipairs(listed) do Fill(Line(index), answer) end
    for index = #listed + 1, #lines do
        lines[index].answer = nil
        lines[index]:Hide()
    end
    up:Hide()
    down:Hide()
    Answers.Place()
    column:Show()
end
