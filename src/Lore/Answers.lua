local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Answers
--  What you can answer, a column beside the words (Saneroki, 2026-10-28): its
--  top level with the box's top, right of it. A line an answer, each on its own
--  soft shade, darker under the mouse: the game's picture for its kind at the
--  left (a quest to hand in, offered, not done yet; the NPC's own picture for
--  its other options), the words beside it. A quest far below your level is
--  dimmed, as the game does; an answer that cannot be given yet (a quest not
--  done) is greyed out. A click gives the answer (Talk.Answer). An NPC's
--  service with a large picture stands over the talk instead (Icons.lua).
--
--      Answers.Draw(talk)   the talk's answers, beside the box
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Answers = {}
ns.Answers = Answers

Answers.WIDTH = 288 -- a line's width
Answers.GAP = 34    -- between the box and the column
Answers.SPACE = 4   -- between two lines
Answers.PAD = 7     -- inside a line's shade
Answers.ICON = 16

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

local column
local lines = {}

local function Hover(line, on)
    line.shade:SetStrength(on and 2 or 1)
    if not line.answer or line.answer.disabled then return end
    if on then line.text:SetTextColor(1, 0.82, 0) else line.text:SetTextColor(1, 1, 1) end
end

local function Line(index)
    if lines[index] then return lines[index] end
    local line = CreateFrame("Button", nil, column)
    line:SetWidth(Answers.WIDTH)
    line.shade = ns.Look.Shade(line)
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

function Answers.Draw(talk)
    if not column then
        column = CreateFrame("Frame", nil, ns.Look.Root())
        column:SetSize(Answers.WIDTH, 1)
    end
    column:ClearAllPoints()
    column:SetPoint("TOPLEFT", ns.Box.Frame(), "TOPRIGHT", Answers.GAP, 0)
    local above
    local count = 0
    for _, answer in ipairs(talk.answers) do
        if not ns.Icons.Shown(answer) then
            count = count + 1
            local line = Line(count)
            line.answer = answer
            line.text:SetText(answer.text or "")
            Picture(line, answer)
            if answer.disabled or answer.trivial then
                line.text:SetTextColor(unpack(ns.Look.GREY))
            else
                line.text:SetTextColor(1, 1, 1)
            end
            line.shade:SetStrength(1)
            line:SetHeight(math.max(Answers.ICON, Core.Plain(line.text:GetStringHeight()) or 0) + Answers.PAD * 2)
            line:ClearAllPoints()
            if above then
                line:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -Answers.SPACE)
            else
                line:SetPoint("TOPLEFT", column, "TOPLEFT", 0, 0)
            end
            line:Show()
            above = line
        end
    end
    for index = count + 1, #lines do lines[index]:Hide() end
    column:Show()
end
