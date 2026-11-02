local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Steps
--  The guide over the world (Saneroki, 2026-10-25): no window, words in
--  Expressway with a thin dark outline straight on the game (Saneroki's pick of
--  font for it). In sight only the steps (Saneroki, 2026-11-01):
--    - each step at hand on a dark shade (Saneroki, 2026-10-31: to be read at a
--      glance on any ground, the shade alone sets the steps apart; 2026-11-01: its
--      corners round, no border): "Step 12"
--      small at its top right, its first words large (what to do), its things to
--      do, each once with its count before its words, or a tick when done, its
--      other words a little smaller, a "!" before a warning and an "i" before
--      the rest;
--    - the wheel turned over the view (Saneroki, 2026-10-31: the steps at hand
--      alone, to keep the eye on them) puts the list of the whole guide in their
--      place, on the same shade, the step you are at in its middle (2026-11-01).
--      A line each with its number or, for a step done as the game knows it
--      (Run.Ticked), a tick; those at hand white on a gold band, the rest a little
--      grey. The wheel scrolls it a line at a time from the guide's first step to
--      its last; a double click on one goes to it, a right click offers to. The
--      steps come back at the red cross by the head, or after Steps.LINGER
--      seconds without the mouse on the view.
--  With the mouse on the steps, and a moment after it left them (Steps.PEEK), the
--  rest comes: the head (the guide's zone, its levels after it, and at the right
--  how far you are, "12/84 · 14%") and past it the row of icons to use and to
--  target (Icons.lua). Which way the view goes is by where it stands (Saneroki,
--  2026-11-01): in the screen's upper half its top stays, it grows down, the head
--  and the icons under the steps; in the lower half its bottom stays, it grows
--  up, the head and the icons over them. The game's map pin goes with the view
--  (Pin.lua); the arrow is a part of its own (Arrow.lua). Both follow this view:
--  shown with it, drawn anew with it.
--  A click on a step at hand skips it (one the game knows is done, or one you
--  looked back at, only goes on, back to your place); a right click goes back
--  one, your place kept; a right click on a listed step opens its menu (Go to
--  step, the guides); a right click on the zone opens the menu of the guides kept (choose the one to follow, Paste
--  a guide, the class quests you left brought back). Edit Mode moves its place
--  (Core.Window), a box of one size, at first at the screen's right, a little
--  down: the steps hang from its top or stand on its bottom, so that edge stays.
--
--      Steps.Update()   shown or hidden and drawn anew, as the switches and the guide are now
--      Steps.Frame()    the view's frame while it is shown: the steps
--      Steps.Edge()     where the icons stand off: the view's left, the height of the head's far side, whether that
--                       side is its top; nil while the view is not shown
--      Steps.GiveBack() hidden; the arrow and the icons too
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Steps = {}
ns.Steps = Steps

Steps.WIDTH = 280     -- the view's width
Steps.PLACE = 120     -- its place's height: the box Edit Mode moves
Steps.PEEK = 0.4      -- seconds the head and the icons stay once the mouse left the view
Steps.LOOK = 0.05     -- seconds between two looks at where the mouse is
Steps.PAD = 7         -- inside a step's shade
Steps.GAP = 6         -- between two steps
Steps.NUMBERS = 28    -- the next steps' numbers' column
Steps.SHADE = 0.65    -- the shade behind a step at hand
Steps.ROUND = 6       -- its corners' radius
Steps.LIST_PAD = Steps.ROUND -- inside the shade, over and under the list: the gold band stays clear of the corners
Steps.LIST = 0.85     -- the listed steps' words, those at hand white; their numbers a little darker
Steps.ROW = 16        -- about a listed step's height: the list fills the steps' place, as long as it can
Steps.BAND = 0.3      -- the gold band behind a step at hand in the list
Steps.MARK = 3        -- and the gold line at its left, wide
Steps.CLOSE = 16      -- the cross that takes the list away, wide and high
Steps.CROSS = "Interface\\RaidFrame\\ReadyCheck-NotReady" -- the game's ready check's red cross
Steps.LINGER = 10     -- seconds without the mouse on the view before the steps come back
Steps.DONE = 0.7      -- a thing done, so faint
Steps.BESIDE = 8      -- between the step's number and the first words beside it
Steps.MENU = 520      -- a group's menu of guides, high at most: a longer one scrolls
Steps.FONT = "Interface\\AddOns\\SaneUI_SpeedLeveling\\Fonts\\Expressway.ttf"
Steps.TICK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t" -- the game's ready check's tick

-- The fonts, by part: size in UI units.
local FONTS = {
    title = 16, levels = 11, count = 11, label = 10, instruction = 13.5, line = 12.5, note = 12, mark = 12, ahead = 12,
    number = 11,
}
local SOFT = { 0.9, 0.9, 0.9 }

local spot            -- the view's place: Edit Mode's box, of one size
local frame, window, header, title, levels, progress
local low             -- it stands in the screen's lower half: it grows up, the head and the icons over the steps
local seen = false   -- the head and the icons are in sight
local bare = false    -- nothing but the head to show: it stays
local gone = Steps.PEEK -- seconds the mouse has been off the view
local waited = 0      -- seconds since the last look at where the mouse is
local empty           -- the line shown while no guide is followed: a click opens the guides
local listShade       -- the shade behind the listed steps
local closer          -- the cross that takes the list away
local cards, rows = {}, {}
local fonts = {}
local browsing = false -- the wheel put the list in the place of the steps at hand
local list = {}       -- the steps it goes through (Guide.Listed)
local browsed         -- the guide run as the list came: another one run since, and the steps come back
local top = 1         -- the place among them of its first line
local least = 0       -- the view's height as the list came: it stays so high, so that the mouse stays over it
local away = 0        -- seconds the mouse has been off the view

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
local Menu, TakesWheel

-- A dark shade in that frame: round corners, no border (Core's Shape, of one radius wherever it is).
local function Shade(host)
    local shade = Core.Shape.New(host, { radius = Steps.ROUND })
    shade:Look({ top = { 0, 0, 0 }, alpha = Steps.SHADE })
    return shade
end

local function Card()
    local card = CreateFrame("Button", nil, frame)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card.shade = Shade(card)
    card.label = Text(card, "label")
    card.label:SetJustifyH("RIGHT")
    card.texts, card.marks = {}, {}
    card:SetScript("OnClick", ns.Guard(function(self, button)
        if button == "RightButton" then ns.Guide.Back() else ns.Guide.Skip(self.number) end
    end))
    TakesWheel(card)
    return card
end

-- The parts of a card's n-th line, made when first needed.
local function Part(list, n, make)
    if not list[n] then list[n] = make() end
    return list[n]
end

-- Whether the mouse is on the view, on what shows with it, or in a menu it opened (a row's).
local function Over()
    return frame:IsMouseOver() or (seen and header:IsMouseOver()) or ns.Icons.Over() or Core.MenuOpen()
end

-- The head and the icons in sight or out of it.
local function Reveal(on)
    if on == seen then return end
    seen = on
    header:SetShown(on)
    ns.Icons.Reveal(on)
end

-- They follow the mouse and stay a moment after it left; while the view is being placed, or has nothing else, they stay.
local function Look(_, elapsed)
    waited = waited + elapsed
    if waited < Steps.LOOK then return end
    if bare or window.unlocked or Core.EditMode.active or Over() then gone = 0 else gone = gone + waited end
    waited = 0
    Reveal(gone < Steps.PEEK)
end

local Browse, Watching -- Watching: Watch, guarded, made once

-- How many lines the list shows: as the setting says, more where the steps stood higher: it fills their place.
local function Shows()
    return math.max(ns.options.ahead or 0, math.ceil(least / Steps.ROW), 1)
end

-- A first line that keeps the list within the guide.
local function Within(first)
    return math.max(1, math.min(first, #list - Shows() + 1))
end

-- While the list shows: left alone a while, the steps come back.
local function Watch(_, elapsed)
    if Over() then
        away = 0
    else
        away = away + elapsed
        if away >= Steps.LINGER then
            Browse(false)
            Steps.Update()
        end
    end
end

-- The list in the place of the steps at hand, the step you are at in its middle, or the steps back.
function Browse(on)
    browsing, away = on, 0
    least = on and frame:GetHeight() or 0
    closer:SetShown(on)
    Watching = Watching or ns.Guard(Watch)
    frame:SetScript("OnUpdate", on and Watching or nil) -- guarded: Watching is ns.Guard(Watch)
    browsed = on and ns.Run.Guide() or nil
    if not on then return end
    local at
    list, at = ns.Guide.Listed()
    top = Within(at - math.floor(Shows() / 2))
end

local RowMenu

-- The first turn brings the list; then the wheel scrolls it, a line at a time, from the guide's first step to its last.
local function Wheel(_, delta)
    if browsing then
        away = 0
        top = Within(top - delta)
    elseif ns.Guide.State() == "on" and ns.Guide.Picture() then
        Browse(true)
    else
        return
    end
    Steps.Update()
end

-- Over any part of the view.
function TakesWheel(part)
    part:EnableMouseWheel(true)
    part:SetScript("OnMouseWheel", ns.Guard(Wheel))
end

local function GoTo(step)
    Browse(false)
    ns.Guide.Go(step)
end

local function Row()
    local row = CreateFrame("Button", nil, frame)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local r, g, b = Core.RGB(ns.Guide.WarnHex():sub(3))
    row.band = row:CreateTexture(nil, "BACKGROUND")
    row.band:SetAllPoints()
    row.band:SetColorTexture(r, g, b, Steps.BAND)
    row.mark = row:CreateTexture(nil, "ARTWORK")
    row.mark:SetPoint("TOPLEFT")
    row.mark:SetPoint("BOTTOMLEFT")
    row.mark:SetWidth(Steps.MARK)
    row.mark:SetColorTexture(r, g, b, 1)
    row.number = Text(row, "number")
    row.number:SetJustifyH("RIGHT")
    row.text = Text(row, "ahead")
    row.text:SetWordWrap(false)
    row:SetScript("OnClick", ns.Guard(function(self, button)
        if button == "RightButton" then RowMenu(self) end
    end))
    row:SetScript("OnDoubleClick", ns.Guard(function(self, button)
        if button == "LeftButton" then GoTo(self.step) end
    end))
    TakesWheel(row)
    return row
end

local function Build()
    spot = CreateFrame("Frame", "SaneUISpeedLevelingGuide", UIParent)
    spot:SetSize(Steps.WIDTH, Steps.PLACE)
    spot:SetFrameStrata("LOW")
    frame = CreateFrame("Frame", "SaneUISpeedLevelingSteps", spot)
    frame:SetSize(Steps.WIDTH, Steps.PLACE)
    TakesWheel(frame)
    header = CreateFrame("Button", nil, frame)
    header:RegisterForClicks("RightButtonUp")
    header:Hide()
    TakesWheel(header)
    header:SetScript("OnClick", ns.Guard(function(self) Menu(self) end))
    title = Text(header, "title")
    title:SetWordWrap(false)
    levels = Text(header, "levels")
    levels:SetTextColor(unpack(SOFT))
    progress = Text(header, "count")
    progress:SetJustifyH("RIGHT")
    progress:SetTextColor(unpack(SOFT))
    listShade = CreateFrame("Frame", nil, frame)
    listShade:SetFrameLevel(frame:GetFrameLevel()) -- under the list's lines
    listShade.plate = Shade(listShade)
    closer = CreateFrame("Button", nil, header)
    closer:SetSize(Steps.CLOSE, Steps.CLOSE)
    closer:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
    closer:SetFrameLevel(header:GetFrameLevel() + 2)
    closer:SetNormalTexture(Steps.CROSS)
    closer:SetHighlightTexture(Steps.CROSS, "ADD")
    closer:SetScript("OnClick", ns.Guard(function()
        Browse(false)
        Steps.Update()
    end))
    closer:Hide()
    Steps.closer = closer
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
    window = Core.Window.New(spot, { store = Core.Store(ns.name), key = "guidePlace", title = ns.TEXT.guideView,
                                     first = { point = "TOPRIGHT", x = -70, y = -200 },
                                     -- moved in Edit Mode: which way it grows and the icons follow
                                     docked = function() ns.Guarded(Steps.Update) end,
                                     unlockedMenu = function(owner) Steps.LockMenu(owner, window) end })
    window:Place()
    spot:SetScript("OnUpdate", ns.Guard(Look))
end

-- The view on its place by the half of the screen that holds it: hanging from the top, the head under it, or standing
-- on the bottom, the head over it.
local function Seat()
    local top, bottom = spot:GetTop(), spot:GetBottom()
    local lower = top ~= nil and bottom ~= nil and top + bottom < UIParent:GetHeight()
    if lower == low then return end
    low = lower
    local corner = low and "BOTTOMLEFT" or "TOPLEFT"
    frame:ClearAllPoints()
    frame:SetPoint(corner, spot, corner)
    header:ClearAllPoints()
    if low then
        header:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, Steps.GAP)
    else
        header:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -Steps.GAP)
    end
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
        if ns.ClassQuests.Left() > 0 then
            root:CreateButton(ns.TEXT.classBack, ns.Guard(function()
                ns.ClassQuests.Back()
                ns.Guide.CheckSoon()
            end))
        end
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
    local step, shown = row.step, row.shown
    util.CreateContextMenu(row, ns.Guard(function(_, root)
        root:CreateTitle(ns.TEXT.step:format(shown))
        root:CreateButton(ns.TEXT.goToStep:format(shown), ns.Guard(function() GoTo(step) end))
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

-- A next step's words plain: no colours, no picture before them.
local function PlainWords(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return (text:gsub("^%s*|T.-|t%s*", ""))
end

-- A thing to do's words without a count of their own, which the game writes before them ("0/12 Boars slain") or after
-- them ("Boars slain: 0/12"), a colour around them or not: the line says it once.
local function Uncounted(text)
    text = text:gsub("^(|c%x%x%x%x%x%x%x%x)%s*%d+%s*/%s*%d+:?%s+", "%1"):gsub("^%s*%d+%s*/%s*%d+:?%s+", "")
    text = text:gsub(":?%s*%(?%d+%s*/%s*%d+%)?%s*(|r)%s*$", "%1")
    return (text:gsub(":?%s*%(?%d+%s*/%s*%d+%)?%s*$", ""))
end

-- What stands before a thing to do's words: a tick once it is done, else how far it is where it has a number.
local function Count(line)
    if line.done then return Steps.TICK end
    return line.have and line.need and ("%d/%d"):format(line.have, line.need) or nil
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
    card.label:SetPoint("TOPRIGHT", card, "TOPRIGHT", -P, -P)
    card.label:SetText((step.chain or ns.TEXT.step:format(step.shown)) .. (step.done and (" " .. Steps.TICK) or ""))
    card.label:SetTextColor(unpack(SOFT))
    -- The first words stand beside the number; a long name (a chain's) has the top to itself.
    local cy, beside = -P, inner - card.label:GetStringWidth() - Steps.BESIDE
    if beside < inner / 2 then cy, beside = cy - card.label:GetStringHeight() - 2, inner end
    local used = { texts = 0, marks = 0 }
    local function Next(kind, part)
        used[kind] = used[kind] + 1
        local list = kind == "texts" and card.texts or card.marks
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
            text:SetWidth(beside)
            text:SetText(line.text)
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 4
        elseif line.count then
            -- A thing to do: its count or tick, then its words.
            local text = Next("texts", "line")
            local count, words = Count(line), Uncounted(line.text)
            text:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            text:SetWidth(beside)
            text:SetText(count and (count .. " " .. words) or words)
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 4
        else
            -- Other words: "!" before a warning, "i" before the rest.
            local mark = Next("marks", "mark")
            mark:SetPoint("TOPLEFT", card, "TOPLEFT", P, cy)
            mark:SetText(Warns(line.text, warn) and "!" or "i")
            mark:SetTextColor(unpack(SOFT))
            mark:SetAlpha(alpha)
            local text = Next("texts", "note")
            text:SetPoint("TOPLEFT", card, "TOPLEFT", P + 10, cy)
            text:SetWidth(beside - 10)
            text:SetText(line.text)
            text:SetAlpha(alpha)
            cy = cy - text:GetStringHeight() - 3
        end
        beside = inner
    end
    -- What this step did not use, out of sight.
    for n = used.texts + 1, #card.texts do card.texts[n]:SetText("") end
    for n = used.marks + 1, #card.marks do card.marks[n]:SetText("") end
    local height = -cy + P - 2
    card:SetHeight(height)
    card.shade:Fit(0, 0, Steps.WIDTH, height) -- only its size counts: its corners are round wherever it is
    card:Show()
    return height
end

local function Hide()
    if frame then
        if browsing then Browse(false) end
        Reveal(false)
        gone = Steps.PEEK
        frame:Hide()
        spot:Hide()
    end
    ns.Arrow.Update(false)
    ns.Icons.Update(false)
    ns.Pin.Update(false)
    ns.Detours.Update(false)
end

function Steps.Update()
    if ns.off then return Hide() end
    -- Off: no guide over the world. Paused: its head and a line saying so, a click on it goes on (Saneroki, 2026-10-26).
    local follow = ns.Guide.State()
    if follow == "off" then return Hide() end
    local picture = ns.options.showGuide and ns.Guide.Picture()
    -- No guide followed: the view stays, its head and a line saying so; a click on it opens the guides.
    local hint = not picture and ns.options.showGuide and ns.Guide.Empty() or nil
    if picture and follow == "paused" then
        hint = ns.TEXT.paused
        picture = { title = picture.title, levels = picture.levels, total = picture.total, at = picture.at,
                    place = picture.place, hand = {} }
    end
    if not picture and not hint then return Hide() end
    if not frame then Build() end
    spot:Show()
    frame:Show()
    Seat()
    -- Another guide run since the list came (chosen, or the one after): its steps at hand, not the old guide's list.
    if browsing and ns.Run.Guide() ~= browsed then Browse(false) end
    if not picture then picture = { title = ns.TEXT.guideView, total = 0, at = 0, place = 0, hand = {} } end
    empty.resume = follow == "paused" and hint == ns.TEXT.paused

    -- The head: the zone, its levels, how far.
    local y = 0
    header:SetWidth(Steps.WIDTH)
    progress:SetText(picture.total > 0 and ns.TEXT.progress:format(picture.place, picture.total,
                     math.floor(picture.place / picture.total * 100 + 0.5)) or "")
    local cross = browsing and Steps.CLOSE + 4 or 0 -- room at the right for the cross
    local room = Steps.WIDTH - cross - progress:GetStringWidth() - 10
    levels:SetText(picture.levels or "")
    local levelsWidth = picture.levels and levels:GetStringWidth() + 6 or 0
    title:SetText(picture.title)
    title:SetWidth(math.max(40, math.min(title:GetStringWidth() + 2, room - levelsWidth)))
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    levels:ClearAllPoints()
    levels:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 1)
    progress:ClearAllPoints()
    progress:SetPoint("BOTTOMRIGHT", header, "TOPRIGHT", -cross, -title:GetStringHeight() + 1)
    header:SetHeight(title:GetStringHeight())

    bare = false
    if hint then
        if browsing then Browse(false) end
        empty.text:SetText(hint)
        empty:ClearAllPoints()
        empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
        empty:SetSize(Steps.WIDTH, empty.text:GetStringHeight() + 2)
        empty:Show()
        for _, card in ipairs(cards) do card:Hide() end
        for _, row in ipairs(rows) do row:Hide() end
        listShade:Hide()
        frame:SetHeight(math.max(1, -y + empty.text:GetStringHeight() + 2))
        ns.Arrow.Update(false)
        ns.Icons.Update(false)
        ns.Pin.Update(false)
        ns.Detours.Update(false)
        return
    end
    empty:Hide()
    local warn = ns.Guide.WarnHex()

    -- The steps at hand, or the list in their place.
    local hand = browsing and {} or picture.hand
    for index, step in ipairs(hand) do
        cards[index] = cards[index] or Card()
        y = y - DrawCard(cards[index], step, y, warn) - Steps.GAP
    end
    for index = #hand + 1, #cards do cards[index]:Hide() end

    -- The list, as far as the wheel took it: a tick for the number of a step done, those at hand on their gold band.
    local here = {}
    for _, step in ipairs(picture.hand) do here[step.number] = true end
    local shown = browsing and math.min(Shows(), #list - top + 1) or 0
    local listTop = y
    if shown > 0 then y = y - Steps.LIST_PAD end
    for index = 1, shown do
        local line = ns.Guide.Line(list[top + index - 1])
        local row = rows[index] or Row()
        rows[index] = row
        row.step, row.shown = line.number, line.shown
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
        row:SetWidth(Steps.WIDTH)
        row.number:ClearAllPoints()
        row.number:SetPoint("TOPRIGHT", row, "TOPLEFT", Steps.NUMBERS - 6, -1)
        row.number:SetText(line.done and Steps.TICK or line.shown)
        row.number:SetTextColor(Steps.LIST * 0.85, Steps.LIST * 0.85, Steps.LIST * 0.85)
        row.text:ClearAllPoints()
        row.text:SetPoint("TOPLEFT", row, "TOPLEFT", Steps.NUMBERS, 0)
        row.text:SetWidth(Steps.WIDTH - Steps.NUMBERS)
        row.text:SetText(PlainWords(line.text))
        local active = here[line.number] == true
        local light = active and 1 or Steps.LIST
        row.text:SetTextColor(light, light, light)
        row.band:SetShown(active)
        row.mark:SetShown(active)
        local height = row.text:GetStringHeight() + 3
        row:SetHeight(height)
        row:Show()
        y = y - height
    end
    for index = shown + 1, #rows do rows[index]:Hide() end
    if shown > 0 then y = math.min(y - Steps.LIST_PAD, -least) end
    local listHeight = math.max(1, listTop - y)
    listShade:ClearAllPoints()
    listShade:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, listTop)
    listShade:SetSize(Steps.WIDTH, listHeight)
    listShade.plate:Fit(0, 0, Steps.WIDTH, listHeight)
    listShade:SetShown(shown > 0)
    bare = #hand == 0 and shown == 0
    frame:SetHeight(math.max(1, -y))
    ns.Arrow.Update(true)
    ns.Icons.Update(true)
    ns.Pin.Update(true)
    ns.Detours.Update(true)
end

function Steps.Frame()
    return frame and frame:IsShown() and frame or nil
end

-- By the place, whose edges do not move, and the heights just set, however far the game is with laying them out.
function Steps.Edge()
    if not Steps.Frame() then return nil end
    local left, top, bottom = spot:GetLeft(), spot:GetTop(), spot:GetBottom()
    if not (left and top and bottom) then return nil end
    local reach = frame:GetHeight() + Steps.GAP + header:GetHeight()
    if low then return left, bottom + reach, true end
    return left, top - reach, false
end

function Steps.GiveBack()
    Hide()
end
