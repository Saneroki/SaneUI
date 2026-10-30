local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Steps
--  The guide over the world (Saneroki, 2026-10-25): no window, words in
--  Expressway with a thin dark outline straight on the game (Saneroki's pick of
--  font for it), from the top:
--    - the guide's zone, its levels after it, and at the right how far you are
--      ("12/84 · 14%"), a thin rule under them;
--    - while your Herbalism or Mining is lower than the next zone the guide
--      goes to asks (Gathering.lua, the switch Gathering for the next zone), a
--      line saying so in the warning colour;
--    - each step at hand on a faint dark shade: "Step 12" small, its first
--      words large (what to do), its things to do (a count and a thin bar under
--      those that have one; a tick on those done), its other words smaller, a
--      "!" before a warning and an "i" before the rest;
--    - the next steps greyed out, a line each with its number, fading as they
--      go down; the wheel scrolls the list through every step of the guide,
--      the done ones above (a tick before each), a right click on one offers
--      to go to it.
--  Over its top the row of icons to use and to target (Icons.lua); the game's
--  map pin goes with it (Pin.lua); the arrow is
--  a part of its own (Arrow.lua). Both follow this view: shown with it, drawn
--  anew with it.
--  A click on a step at hand skips it, a right click goes back one; the wheel
--  over the list scrolls it, a double click on a listed step goes to it, a
--  right click on it opens its menu (Go to step, the guides); a right click on
--  the zone opens the menu of the guides kept (choose the one to follow, Paste
--  a guide). It stands where Edit Mode puts it (Core.Window), at first at the
--  screen's right, a little down; it grows downwards.
--
--      Steps.Update()   shown or hidden and drawn anew, as the switches and the guide are now
--      Steps.Frame()    the view's frame while it is shown (the icons stand over its top)
--      Steps.GiveBack() hidden; the arrow and the icons too
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Steps = {}
ns.Steps = Steps

Steps.WIDTH = 280     -- the view's width
Steps.PAD = 7         -- inside a step's shade
Steps.GAP = 6         -- between two steps
Steps.NUMBERS = 24    -- the next steps' numbers' column
Steps.SHADE = 0.3     -- the shade behind a step at hand
Steps.FADE = 0.12     -- each next step is so much fainter than the one above it
Steps.FAINTEST = 0.3
Steps.GREY = 0.55     -- the next steps' words, greyed out; their numbers a little darker
Steps.DONE = 0.5      -- a thing done, so faint
Steps.BAR = 2         -- a count's bar, high
Steps.MENU = 520      -- a group's menu of guides, high at most: a longer one scrolls
Steps.FONT = "Interface\\AddOns\\SaneUI_SpeedLeveling\\Fonts\\Expressway.ttf"
Steps.TICK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t" -- the game's ready check's tick

-- The fonts, by part: size in UI units.
local FONTS = {
    title = 16, levels = 11, count = 11, label = 10, instruction = 13.5, line = 12, note = 11, mark = 11, ahead = 12,
    number = 11,
}
local SOFT = { 0.8, 0.8, 0.8 }

local frame, window, header, rule, ruleShadow, title, levels, progress
local empty           -- the line shown while no guide is followed: a click opens the guides
local gather          -- the line saying your gathering is short for the next zone
local cards, rows = {}, {}
local fonts = {}
local offset = 0      -- the list scrolled from its start after the steps at hand (back for less than 0)
local lastAt          -- the step the guide was at when last drawn: when it moves on, the list starts again
local hovered = false

local function Font(part)
    if fonts[part] then return fonts[part] end
    local font = CreateFont("SaneUISpeedLevelingGuide" .. part)
    if not font:SetFont(Steps.FONT, FONTS[part], "OUTLINE") then
        -- The font could not be set: the game's, outlined, at that size.
        local base = rawget(_G, "GameFontHighlight")
        local file = base and base:GetFont()
        if file then font:SetFont(file, FONTS[part], "OUTLINE") end
    end
    font:SetTextColor(1, 1, 1)
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
local function Part(list, n, make)
    if not list[n] then list[n] = make() end
    return list[n]
end

local function Hover(on)
    if hovered == on then return end
    hovered = on
    Steps.Update()
end

local RowMenu

-- The list scrolled by the wheel: through every step of the guide, the done ones above too.
local listEnds -- the list drawn last reached the guide's end: it scrolls no further down

local function Wheel(_, delta)
    if delta < 0 and listEnds then return end
    offset = offset - delta
    Steps.Update()
end

local function Row()
    local row = CreateFrame("Button", nil, frame)
    row:RegisterForClicks("RightButtonUp")
    row.tick = row:CreateFontString(nil, "OVERLAY")
    row.tick:SetFontObject(Font("number"))
    row.number = Text(row, "number")
    row.number:SetJustifyH("RIGHT")
    row.text = Text(row, "ahead")
    row.text:SetWordWrap(false)
    row:SetScript("OnClick", ns.Guard(function(self) RowMenu(self) end))
    row:SetScript("OnDoubleClick", ns.Guard(function(self) ns.Guide.Go(self.step) end))
    row:SetScript("OnEnter", ns.Guard(function() Hover(true) end))
    row:SetScript("OnLeave", ns.Guard(function() Hover(false) end))
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", ns.Guard(Wheel))
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
    empty = CreateFrame("Button", nil, frame)
    empty:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    empty.text = Text(empty, "note")
    empty.text:SetPoint("TOPLEFT", empty, "TOPLEFT", 0, 0)
    empty.text:SetWidth(Steps.WIDTH)
    empty.text:SetTextColor(unpack(SOFT))
    -- No guide: the guides open; paused: the guide goes on.
    empty:SetScript("OnClick", ns.Guard(function(self, button)
        if button == "RightButton" then return Menu(self) end
        if self.resume then Core.Set(ns.name, "follow", "on") else ns.Guides.Open() end
    end))
    empty:Hide()
    gather = Text(frame, "note")
    gather:SetWidth(Steps.WIDTH)
    gather:Hide()
    window = Core.Window.New(frame, { store = Core.Store(ns.name), key = "guidePlace", title = ns.TEXT.guideView,
                                      first = { point = "TOPRIGHT", x = -70, y = -200 },
                                      -- moved in Edit Mode: the icons over it follow
                                      docked = function() ns.Guarded(Steps.Update) end,
                                      unlockedMenu = function(owner) Steps.LockMenu(owner, window) end })
    window:Place()
end

-------------------------------------------------------------------------------
--  The menu
-------------------------------------------------------------------------------
-- The guides for this character, kept and from packs, by group (a menu of its own each, its subgroups as titles):
-- the one to follow; then the window of the guides, to add one.
function Menu(owner)
    local util = rawget(_G, "MenuUtil")
    if not (util and util.CreateContextMenu) then return end
    util.CreateContextMenu(owner, ns.Guard(function(_, root)
        root:CreateTitle(ns.TEXT.guides)
        local groups = {}
        for _, kept in ipairs(ns.Guide.Kept()) do
            if kept.mine then
                local group = groups[kept.group]
                if not group then
                    local words = kept.group ~= "" and kept.group or ns.TEXT.ungrouped
                    group = { menu = root:CreateButton(words) }
                    if group.menu.SetScrollMode then group.menu:SetScrollMode(Steps.MENU) end
                    groups[kept.group] = group
                end
                if kept.subgroup ~= "" and kept.subgroup ~= group.subgroup then group.menu:CreateTitle(kept.subgroup) end
                group.subgroup = kept.subgroup
                local key = kept.key
                group.menu:CreateRadio(kept.title or kept.name, ns.Guard(function() return ns.Guide.Chosen() == key end),
                                       ns.Guard(function() ns.Guide.Choose(key) end))
            end
        end
        if not next(groups) then root:CreateTitle(ns.TEXT.noneHere) end
        root:CreateDivider()
        root:CreateButton(ns.TEXT.paste, ns.Guard(ns.Guides.Open))
        Steps.LockItem(root, window)
    end))
end

-- A menu's line that unlocks a window of the guide's, to drag it, or locks it again.
function Steps.LockItem(root, which)
    root:CreateButton(which.unlocked and ns.TEXT.lock or ns.TEXT.unlock, ns.Guard(function() which:Unlock(not which.unlocked) end))
end

-- That line alone: a right click on the arrow, or on the box over a window unlocked.
function Steps.LockMenu(owner, which)
    local util = rawget(_G, "MenuUtil")
    if not (util and util.CreateContextMenu) then return end
    util.CreateContextMenu(owner, ns.Guard(function(_, root) Steps.LockItem(root, which) end))
end

-- A listed step's menu: go to it; the guides kept a line under it.
function RowMenu(row)
    local util = rawget(_G, "MenuUtil")
    if not (util and util.CreateContextMenu) then return end
    local step = row.step
    util.CreateContextMenu(row, ns.Guard(function(_, root)
        root:CreateTitle(ns.TEXT.step:format(step))
        root:CreateButton(ns.TEXT.goToStep:format(step), ns.Guard(function() ns.Guide.Go(step) end))
        root:CreateButton(ns.TEXT.guides, ns.Guard(function() Menu(row) end))
    end))
end

-------------------------------------------------------------------------------
--  Drawing
-------------------------------------------------------------------------------
-- Whether words carry the warning colour.
local function Warns(text, warn)
    return warn ~= nil and text:lower():find("|c" .. warn, 1, true) ~= nil
end

-- A next step's words greyed out: no colours, no picture before them.
local function Greyed(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return (text:gsub("^%s*|T.-|t%s*", ""))
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
        local text = Part(list, used[kind], function() return Text(card, part) end)
        text:SetFontObject(Font(part))
        text:ClearAllPoints()
        return text
    end
    for index, line in ipairs(step.lines) do
        local alpha = line.done and Steps.DONE or 1
        if not line.count and index == 1 then
            -- What to do, large.
            local text = Next("texts", "instruction")
            text:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            text:SetWidth(inner)
            text:SetText(line.text)
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 4
        elseif line.count then
            -- A thing to do: its words, its count or tick at the right, a bar under one with a count.
            local count = Next("counts", "count")
            count:SetPoint("TOPRIGHT", card, "TOPRIGHT", -P, cy)
            count:SetJustifyH("RIGHT")
            if line.done then
                count:SetText(Steps.TICK)
            elseif line.have and line.need then
                count:SetText(("%d/%d"):format(line.have, line.need))
            else
                count:SetText("")
            end
            count:SetAlpha(alpha)
            local text = Next("texts", "line")
            text:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            text:SetWidth(inner - math.max(count:GetStringWidth(), 12) - 6)
            text:SetText((line.text:gsub(":?%s*%d+%s*/%s*%d+%s*$", "")))
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 2
            if line.have and line.need and line.need > 0 then
                used.bars = used.bars + 1
                local track = Part(card.tracks, used.bars, function() return card:CreateTexture(nil, "ARTWORK") end)
                local fill = Part(card.fills, used.bars, function() return card:CreateTexture(nil, "OVERLAY") end)
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
            local mark = Next("marks", "mark")
            mark:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            mark:SetText(Warns(line.text, warn) and "!" or "i")
            mark:SetTextColor(unpack(SOFT))
            mark:SetAlpha(alpha)
            local text = Next("texts", "note")
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

local function Hide()
    if frame then frame:Hide() end
    ns.Arrow.Update(false)
    ns.Icons.Update(false)
    ns.Pin.Update(false)
end

function Steps.Update()
    if ns.off then return Hide() end
    local count = ns.options.ahead or 0
    -- Off: no guide over the world. Paused: its head and a line saying so, a click on it goes on (Saneroki, 2026-10-26).
    local follow = ns.options.follow or "on"
    if follow == "off" then return Hide() end
    local picture = ns.options.showGuide and ns.Guide.Picture(count, offset)
    if picture and lastAt ~= picture.at then
        -- The guide moved on: the list starts after the steps at hand again.
        lastAt, offset = picture.at, 0
        if picture.shift ~= 0 then picture = ns.Guide.Picture(count, 0) end
    end
    if picture then offset = picture.shift end
    -- No guide followed: the view stays, its head and a line saying so; a click on it opens the guides.
    local hint = not picture and ns.options.showGuide and ns.Guide.Empty() or nil
    if picture and follow == "paused" then
        hint = ns.TEXT.paused
        picture = { title = picture.title, levels = picture.levels, total = picture.total, at = picture.at,
                    hand = {}, ahead = {} }
    end
    if not picture and not hint then return Hide() end
    if not frame then Build() end
    frame:Show()
    if not picture then picture = { title = ns.TEXT.guideView, total = 0, at = 0, hand = {}, ahead = {} } end
    empty.resume = follow == "paused" and hint == ns.TEXT.paused

    -- The head: the zone, its levels, how far.
    local y = 0
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
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
    levels:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 1)
    progress:ClearAllPoints()
    progress:SetPoint("BOTTOMRIGHT", header, "TOPRIGHT", 0, -title:GetStringHeight() + 1)
    local headHeight = title:GetStringHeight() + 5
    header:SetHeight(headHeight)
    y = y - headHeight
    rule:ClearAllPoints()
    rule:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
    rule:SetSize(Steps.WIDTH, 1)
    ruleShadow:ClearAllPoints()
    ruleShadow:SetPoint("TOPLEFT", rule, "BOTTOMLEFT")
    ruleShadow:SetSize(Steps.WIDTH, 1)
    y = y - 2 - 8

    if hint then
        empty.text:SetText(hint)
        empty:ClearAllPoints()
        empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
        empty:SetSize(Steps.WIDTH, empty.text:GetStringHeight() + 2)
        empty:Show()
        gather:Hide()
        for _, card in ipairs(cards) do card:Hide() end
        for _, row in ipairs(rows) do row:Hide() end
        frame:SetHeight(math.max(1, -y + empty.text:GetStringHeight() + 2))
        ns.Arrow.Update(false)
        ns.Icons.Update(false)
        ns.Pin.Update(false)
        return
    end
    empty:Hide()
    local warn = ns.Guide.WarnHex()

    -- Your gathering short for the next zone the guide goes to.
    local short = ns.Gathering.Short()
    if short then
        local skills = {}
        for _, entry in ipairs(short.short) do
            skills[#skills + 1] = ns.TEXT.gatherSkill:format(entry.skill, entry.have, entry.need)
        end
        local words = ns.TEXT.gatherShort:format(short.name, table.concat(skills, ", "))
        gather:SetText(warn and ("|c" .. warn .. words .. "|r") or words)
        gather:ClearAllPoints()
        gather:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
        gather:Show()
        y = y - gather:GetStringHeight() - Steps.GAP
    else
        gather:Hide()
    end

    -- The steps at hand.
    for index, step in ipairs(picture.hand) do
        cards[index] = cards[index] or Card()
        y = y - DrawCard(cards[index], step, y, warn) - Steps.GAP
    end
    for index = #picture.hand + 1, #cards do cards[index]:Hide() end

    -- The listed steps, greyed out and fading as they go down: the next ones, or wherever the wheel took the list
    -- (a tick before one done; one at hand a little lighter).
    local here = {}
    for _, step in ipairs(picture.hand) do here[step.number] = true end
    local shown = math.min(count, #picture.ahead)
    listEnds = #picture.ahead < count
    for index = 1, shown do
        local line = picture.ahead[index]
        local row = rows[index] or Row()
        rows[index] = row
        row.step = line.number
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
        row:SetWidth(Steps.WIDTH)
        row.number:ClearAllPoints()
        row.number:SetPoint("TOPRIGHT", row, "TOPLEFT", Steps.NUMBERS - 6, -1)
        row.number:SetText(line.number)
        row.number:SetTextColor(Steps.GREY * 0.8, Steps.GREY * 0.8, Steps.GREY * 0.8)
        row.tick:ClearAllPoints()
        row.tick:SetPoint("TOPRIGHT", row.number, "TOPLEFT", -2, 1)
        row.tick:SetText(line.done and Steps.TICK or "")
        row.text:ClearAllPoints()
        row.text:SetPoint("TOPLEFT", row, "TOPLEFT", Steps.NUMBERS, 0)
        row.text:SetWidth(Steps.WIDTH - Steps.NUMBERS)
        row.text:SetText(Greyed(line.text))
        local grey = here[line.number] and SOFT[1] or Steps.GREY
        row.text:SetTextColor(grey, grey, grey)
        local height = row.text:GetStringHeight() + 3
        row:SetHeight(height)
        row:SetAlpha(hovered and 1 or math.max(Steps.FAINTEST, 1 - Steps.FADE * index))
        row:Show()
        y = y - height
    end
    for index = shown + 1, #rows do rows[index]:Hide() end
    frame:SetHeight(math.max(1, -y))
    ns.Arrow.Update(true)
    ns.Icons.Update(true)
    ns.Pin.Update(true)
end

function Steps.Frame()
    return frame and frame:IsShown() and frame or nil
end

function Steps.GiveBack()
    Hide()
end
