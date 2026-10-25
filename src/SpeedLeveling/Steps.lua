local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Steps
--  The guide over the world (Saneroki, 2026-10-25): no window, words in
--  Kalam with a dark outline straight on the game, from the top:
--    - the guide's zone, its levels after it, and at the right how far you are
--      ("12/84 · 14%"), a thin rule under them;
--    - each step at hand on a faint dark shade: "Step 12" small, its first
--      words large (what to do), its things to do (a count and a thin bar under
--      those that have one; a tick on those done), its other words smaller, a
--      "!" before a warning and an "i" before the rest;
--    - the next steps, a line each with its number, fading as they go down.
--  A click on a step at hand skips it, a right click goes back one; the wheel
--  over the next steps scrolls them, a double click goes to one; a right click
--  on the zone opens the guides. It stands where Edit Mode puts it
--  (Core.Window), at first right of the middle.
--
--  While the leveling guide Sane UI knows shows its own window, this shows its
--  guide, and its own window is made unseen and small (Core.Lend; the switch
--  Hide its own window), given back as it was when this stops showing it.
--
--      Steps.Update()   shown or hidden and drawn anew, as the switches and the guide are now
--      Steps.GiveBack() hidden, the known guide's window given back
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Steps = {}
ns.Steps = Steps

Steps.WIDTH = 300     -- the view's width
Steps.PAD = 7         -- inside a step's shade
Steps.GAP = 6         -- between two steps
Steps.NUMBERS = 26    -- the next steps' numbers' column
Steps.SHADE = 0.3     -- the shade behind a step at hand
Steps.FADE = 0.12     -- each next step is so much fainter than the one above it
Steps.FAINTEST = 0.3
Steps.DONE = 0.5      -- a thing done, so faint
Steps.BAR = 2         -- a count's bar, high
Steps.UNSEEN = 0.01   -- the known guide's own window, so small while this shows its guide
Steps.TICK = "\226\136\154" -- Kalam's root sign: a tick drawn by hand

-- The fonts, by part: size in 1080p pixels (Core.Journal), bold.
local FONTS = {
    title = { 22, true }, levels = { 14 }, count = { 13 }, label = { 12 }, instruction = { 17 },
    line = { 14 }, note = { 13 }, mark = { 13, true }, ahead = { 14 }, number = { 12 },
}
local WHITE = { 1, 1, 1 }
local SOFT = { 0.8, 0.8, 0.8 }

local frame, window, header, rule, ruleShadow, title, levels, progress
local cards, rows = {}, {}
local fonts = {}
local offset = 0    -- the next steps scrolled past
local hovered = false
local lent          -- the known guide's window while it is lent

local function Font(part)
    if fonts[part] then return fonts[part] end
    local size, bold = unpack(FONTS[part])
    local font = Core.Journal.FontObject("SaneUISpeedLevelingGuide" .. part, size, bold, "OUTLINE", WHITE)
    if not font:GetFont() then
        -- Kalam could not be set: the game's font, outlined, at that size.
        local base = rawget(_G, "GameFontHighlight")
        local file = base and base:GetFont()
        if file then font:SetFont(file, size * Core.Journal.PX, "OUTLINE") end
    end
    fonts[part] = font
    return font
end

local function Text(parent, part, layer)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFontObject(Font(part))
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    return text
end

-------------------------------------------------------------------------------
--  Building
-------------------------------------------------------------------------------
local Menu

local function Card()
    local card = CreateFrame("Button", nil, frame)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card.shade = card:CreateTexture(nil, "BACKGROUND")
    card.shade:SetAllPoints()
    card.shade:SetColorTexture(0, 0, 0, Steps.SHADE)
    card.label = Text(card, "label")
    card.texts, card.counts, card.tracks, card.fills, card.marks = {}, {}, {}, {}, {}
    card:SetScript("OnClick", ns.Guard(function(self, button)
        if button == "RightButton" then ns.Guide.Back() else ns.Guide.Skip(self.number) end
    end))
    return card
end

-- The parts of a card's n-th line, made when first needed.
local function Part(card, list, n, make)
    if not list[n] then list[n] = make() end
    return list[n]
end

local function Hover(on)
    if hovered == on then return end
    hovered = on
    Steps.Update()
end

local function Row()
    local row = CreateFrame("Button", nil, frame)
    row.number = Text(row, "number")
    row.number:SetJustifyH("RIGHT")
    row.text = Text(row, "ahead")
    row.text:SetWordWrap(false)
    row:SetScript("OnDoubleClick", ns.Guard(function(self) ns.Guide.Go(self.step) end))
    row:SetScript("OnEnter", ns.Guard(function() Hover(true) end))
    row:SetScript("OnLeave", ns.Guard(function() Hover(false) end))
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", ns.Guard(function(_, delta)
        offset = math.max(0, offset - delta)
        Steps.Update()
    end))
    return row
end

local function Build()
    frame = CreateFrame("Frame", "SaneUISpeedLevelingSteps", UIParent)
    frame:SetSize(Steps.WIDTH, 120)
    frame:SetFrameStrata("LOW")
    header = CreateFrame("Button", nil, frame)
    header:RegisterForClicks("RightButtonUp")
    header:SetScript("OnClick", ns.Guard(function(self) Menu(self) end))
    title = Text(header, "title")
    title:SetWordWrap(false)
    levels = Text(header, "levels")
    levels:SetTextColor(unpack(SOFT))
    progress = Text(header, "count")
    progress:SetJustifyH("RIGHT")
    progress:SetTextColor(unpack(SOFT))
    rule = frame:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(1, 1, 1, 0.45)
    ruleShadow = frame:CreateTexture(nil, "ARTWORK")
    ruleShadow:SetColorTexture(0, 0, 0, 0.6)
    window = Core.Window.New(frame, { store = Core.Store(ns.name), key = "guidePlace", title = ns.TEXT.guideView,
                                      first = { point = "RIGHT", x = -70, y = 150 } })
    window:Place()
end

-------------------------------------------------------------------------------
--  The menu
-------------------------------------------------------------------------------
function Menu(owner)
    local util = rawget(_G, "MenuUtil")
    if not (util and util.CreateContextMenu) then return end
    util.CreateContextMenu(owner, ns.Guard(function(_, root)
        root:CreateTitle(ns.TEXT.guides)
        if ns.Guide.Known() then
            root:CreateButton(ns.TEXT.knownShown, function() end):SetEnabled(false) -- unguarded: it does nothing
        else
            for _, kept in ipairs(ns.Guide.Kept()) do
                if kept.mine then
                    local name = kept.name
                    root:CreateRadio(name, ns.Guard(function() return ns.Guide.Chosen() == name end),
                                     ns.Guard(function() ns.Guide.Choose(name) end))
                end
            end
        end
        root:CreateDivider()
        root:CreateButton(ns.TEXT.paste, ns.Guard(ns.Guides.Open))
    end))
end

-------------------------------------------------------------------------------
--  Drawing
-------------------------------------------------------------------------------
-- Whether words carry the warning colour.
local function Warns(text, warn)
    return warn ~= nil and text:lower():find("|c" .. warn, 1, true) ~= nil
end

-- One step at hand on its card, from the top y of the view; its height.
local function DrawCard(card, step, y, warn)
    local P = Steps.PAD
    local inner = Steps.WIDTH - P * 2
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
    card:SetWidth(Steps.WIDTH)
    card.number = step.number
    card.label:ClearAllPoints()
    card.label:SetPoint("TOPLEFT", card, "TOPLEFT", P, -P)
    card.label:SetText(ns.TEXT.step:format(step.number))
    card.label:SetTextColor(unpack(SOFT))
    local cy = -P - card.label:GetStringHeight() - 2
    local used = { texts = 0, counts = 0, bars = 0, marks = 0 }
    local function Next(kind, part)
        used[kind] = used[kind] + 1
        local list = kind == "texts" and card.texts or kind == "counts" and card.counts or card.marks
        return Part(card, list, used[kind], function() return Text(card, part) end)
    end
    local instructed = false
    for index, line in ipairs(step.lines) do
        local alpha = line.done and Steps.DONE or 1
        if not line.count and not instructed and index == 1 then
            -- What to do, large.
            instructed = true
            local text = Next("texts", "instruction")
            text:SetFontObject(Font("instruction"))
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            text:SetWidth(inner)
            text:SetText(line.text)
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 4
        elseif line.count then
            -- A thing to do: its words, its count or tick at the right, a bar under one with a count.
            local count = Next("counts", "count")
            count:ClearAllPoints()
            count:SetPoint("TOPRIGHT", card, "TOPRIGHT", -P, cy)
            count:SetJustifyH("RIGHT")
            if line.have and line.need then
                count:SetText(line.done and Steps.TICK or ("%d/%d"):format(line.have, line.need))
            else
                count:SetText(line.done and Steps.TICK or "")
            end
            count:SetAlpha(alpha)
            local text = Next("texts", "line")
            text:SetFontObject(Font("line"))
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            text:SetWidth(inner - math.max(count:GetStringWidth(), 12) - 6)
            text:SetText((line.text:gsub(":?%s*%d+%s*/%s*%d+%s*$", "")))
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 2
            if line.have and line.need and line.need > 0 then
                used.bars = used.bars + 1
                local track = Part(card, card.tracks, used.bars, function() return card:CreateTexture(nil, "ARTWORK") end)
                local fill = Part(card, card.fills, used.bars, function() return card:CreateTexture(nil, "OVERLAY") end)
                track:SetColorTexture(1, 1, 1, 0.18)
                track:ClearAllPoints()
                track:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy - 1)
                track:SetSize(inner, Steps.BAR)
                fill:SetColorTexture(1, 1, 1, line.done and 0.45 or 0.85)
                fill:ClearAllPoints()
                fill:SetPoint("TOPLEFT", track, "TOPLEFT")
                fill:SetSize(math.max(0.01, inner * math.min(1, line.have / line.need)), Steps.BAR)
                track:Show()
                fill:Show()
                cy = cy - Steps.BAR - 4
            else
                cy = cy - 2
            end
        else
            -- Other words: "!" before a warning, "i" before the rest.
            instructed = true
            local warned = Warns(line.text, warn)
            local mark = Next("marks", "mark")
            mark:ClearAllPoints()
            mark:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            mark:SetText(warned and "!" or "i")
            mark:SetTextColor(unpack(SOFT))
            mark:SetAlpha(alpha)
            local text = Next("texts", "note")
            text:SetFontObject(Font("note"))
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", card, "TOPLEFT", P + 10, cy)
            text:SetWidth(inner - 10)
            text:SetText(line.text)
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 3
        end
    end
    -- What this step did not use, out of sight.
    for n = used.texts + 1, #card.texts do card.texts[n]:SetText("") end
    for n = used.counts + 1, #card.counts do card.counts[n]:SetText("") end
    for n = used.marks + 1, #card.marks do card.marks[n]:SetText("") end
    for n = used.bars + 1, #card.tracks do
        card.tracks[n]:Hide()
        card.fills[n]:Hide()
    end
    local height = -cy + P - 2
    card:SetHeight(height)
    card:Show()
    return height
end

-- The known guide's own window: made unseen and small while this shows its guide, else given back.
local function Lend(on)
    if on and not lent then
        local own = Core.Neighbours.Frame("guide")
        if not own then return end
        lent = Core.Lend(own)
        lent:SetAlpha(0)
        lent:SetScale(Steps.UNSEEN)
    elseif not on and lent then
        local was = lent
        lent = nil
        was:Return()
    end
end

local function Hide()
    if frame then frame:Hide() end
    Lend(false)
end

function Steps.Update()
    if ns.off then return Hide() end
    local picture = ns.options.showGuide and ns.Guide.Picture()
    local book = picture and picture.known
    -- The known guide's guide is shown only while its own window is there to be shown.
    local own = book and Core.Neighbours.Frame("guide")
    if not picture or (book and own and not own:IsShown()) then return Hide() end
    Lend(book and ns.options.knownWindow or false)
    if not frame then Build() end
    frame:Show()

    -- The head: the zone, its levels, how far.
    local y = 0
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", frame, "TOPLEFT")
    header:SetWidth(Steps.WIDTH)
    progress:SetText(picture.total > 0 and ns.TEXT.progress:format(picture.at, picture.total,
                     math.floor(picture.at / picture.total * 100 + 0.5)) or "")
    local room = Steps.WIDTH - progress:GetStringWidth() - 10
    levels:SetText(picture.levels or "")
    local levelsWidth = picture.levels and levels:GetStringWidth() + 6 or 0
    title:SetText(picture.title)
    title:SetWidth(math.max(40, math.min(title:GetStringWidth() + 2, room - levelsWidth)))
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    levels:ClearAllPoints()
    levels:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 2)
    progress:ClearAllPoints()
    progress:SetPoint("BOTTOMRIGHT", header, "TOPRIGHT", 0, -title:GetStringHeight() + 2)
    y = y - title:GetStringHeight() - 5
    header:SetHeight(-y)
    rule:ClearAllPoints()
    rule:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
    rule:SetSize(Steps.WIDTH, 1)
    ruleShadow:ClearAllPoints()
    ruleShadow:SetPoint("TOPLEFT", rule, "BOTTOMLEFT")
    ruleShadow:SetSize(Steps.WIDTH, 1)
    y = y - 2 - 8

    -- The steps at hand.
    local warn = ns.Guide.WarnHex()
    for index, step in ipairs(picture.hand) do
        cards[index] = cards[index] or Card()
        y = y - DrawCard(cards[index], step, y, warn) - Steps.GAP
    end
    for index = #picture.hand + 1, #cards do cards[index]:Hide() end

    -- The next steps, fading as they go down.
    local shown = math.min(ns.options.ahead or 0, #picture.ahead)
    offset = math.max(0, math.min(offset, #picture.ahead - shown))
    for index = 1, shown do
        local line = picture.ahead[index + offset]
        local row = rows[index] or Row()
        rows[index] = row
        row.step = line.number
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
        row:SetWidth(Steps.WIDTH)
        row.number:ClearAllPoints()
        row.number:SetPoint("TOPRIGHT", row, "TOPLEFT", Steps.NUMBERS - 6, -1)
        row.number:SetText(line.number)
        row.number:SetTextColor(unpack(SOFT))
        row.text:ClearAllPoints()
        row.text:SetPoint("TOPLEFT", row, "TOPLEFT", Steps.NUMBERS, 0)
        row.text:SetWidth(Steps.WIDTH - Steps.NUMBERS)
        row.text:SetText(line.text)
        local height = row.text:GetStringHeight() + 3
        row:SetHeight(height)
        row:SetAlpha(hovered and 1 or math.max(Steps.FAINTEST, 1 - Steps.FADE * index))
        row:Show()
        y = y - height
    end
    for index = shown + 1, #rows do rows[index]:Hide() end
    frame:SetHeight(math.max(1, -y))
end

function Steps.GiveBack()
    Hide()
end
