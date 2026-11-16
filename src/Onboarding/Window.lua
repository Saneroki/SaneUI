local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Onboarding - Window
--  The setup's window, made the first time one opens: a window of its own in
--  the bronze (Look.Dress), in the middle of the screen, moved by its head,
--  closed by its X or Esc. It never blocks the game: the world goes on behind
--  it and the module's plates follow each change at once.
--
--    left    the stage, the module's sample (the guide's Stage, drawn anew
--            whenever the step shows or a setting changes) over the world
--            itself: the window's plate stops round it, only a thin golden
--            line frames it (Saneroki, 2026-11-16: "fully transparent, so
--            that the player sees it like it would be in the real world")
--    right   the step: its head in the game's gold, its words, its controls
--            (Controls.lua), made the first time the step shows and kept
--    under   the loading screen's bar, filled as far as the steps have
--            come, "Step 2 of 9" in it (Saneroki, 2026-11-16), and the
--            buttons Back and Next (Done on the last step), red with the
--            game's arrows, as Forever's own steps of the character creation
--            have them
--
--  Changes are made as they are clicked (Core.Set), so closing the window at
--  any step keeps what was chosen; nothing to save or undo here.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Window = {}
ns.Window = Window

Window.WIDTH, Window.HEIGHT = 860, 600 -- UI units
Window.STAGE = 420   -- the sample's room at the left
Window.GAP = 20      -- between the sample and the step
Window.FOOT = 46     -- the row under them: the count, Back and Next
Window.BUTTON = { 132, 32 }
Window.HEAD = 22     -- the step's head (Look.SetFont's size)
Window.TEXT = 15     -- its words
Window.ARROWS = { back = "common-icon-backarrow", next = "common-icon-forwardarrow" } -- the character creation's
Window.BAR = 28      -- the loading screen's bar's height
Window.FILL = "Interface\\Glues\\LoadingBar\\Loading-BarFill" -- its fill
Window.FILL_IN = { 0.9, 0.3 } -- the fill this far in from the bar's ends and edges, shares of its height
Window.PLATE = "heavybronze-frame-background" -- the window's plate (Look.Frame's)

local frame, look, stage, side, title, words, count, back, forward, progress
local current   -- { name, guide, index } while a setup shows
local made = {} -- [module name] = { [step index] = its controls' frame }, made the first time each shows

-- A button's words with the game's arrow at its side (CharacterCreateNavButtonMixin:UpdateText).
local function Arrowed(text, arrow, before)
    local markup = rawget(_G, "CreateAtlasMarkup")
    local mark = markup and Core.Ask(markup, arrow, 8, 13, 0, 0)
    if type(mark) ~= "string" then return text end
    return before and (mark .. "  " .. text) or (text .. "  " .. mark)
end

function Window.Close()
    if frame and frame:IsShown() then
        frame:Hide()
        Core.Sound("IG_MAINMENU_CLOSE")
    end
end

-- The sample drawn anew by the module and the step's controls showing the values in use.
function Window.Changed()
    if not current then return end
    local index = current.index
    local holder = made[current.name] and made[current.name][index]
    if holder then ns.Controls.Refresh(holder, current.name) end
    local guide = current.guide
    if type(guide.Stage) == "function" then
        ns.Safe("sample", guide.Stage, stage, guide.steps[index], index)
    end
end

-- A control was changed by the player: the module's switch set (Core.Set tells the module), then all shown anew.
function Window.Set(name, key, value)
    Core.Set(name, key, value)
    Window.Changed()
end

-- To a step: its head, words and controls, the count and the buttons.
function Window.Go(index)
    if not current then return end
    local steps = current.guide.steps
    index = math.max(1, math.min(tonumber(index) or 1, #steps))
    current.index = index
    local step = steps[index]
    title:SetText(step.title or "")
    words:SetText(step.text or "")
    for name, holders in pairs(made) do
        for at, holder in pairs(holders) do holder:SetShown(name == current.name and at == index) end
    end
    local holders = made[current.name] or {}
    made[current.name] = holders
    if not holders[index] then
        holders[index] = ns.Controls.Build(side, current.name, step.settings, Window.WIDTH - Window.STAGE - Window.GAP
            - 2 * Look.INSIDE)
    end
    local holder = holders[index]
    holder:ClearAllPoints()
    holder:SetPoint("TOPLEFT", words, "BOTTOMLEFT", 0, -16)
    holder:Show()
    count:SetText(ns.TEXT.step:format(index, #steps))
    progress:Share(index / #steps)
    back:SetEnabled(index > 1)
    forward:SetText(index == #steps and ns.TEXT.done or Arrowed(ns.TEXT.next, Window.ARROWS.next))
    Window.Changed()
end

local function Turn(by)
    if not current then return end
    local index = current.index + by
    if index > #current.guide.steps then return Window.Close() end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    Window.Go(index)
end

-- The window's plate everywhere but over the stage: four pieces round it, each a frame that clips a plate as large as
-- the window's own (so the picture runs on unbroken), under the bronze frame (Look.Frame's level is the window's less
-- one); the stage in a thin golden line, nothing inside it.
local function Hole(content)
    look.frame.plate:SetAlpha(0)
    local level = math.max((look.frame:GetFrameLevel() or 1) - 1, 0)
    local pieces = {}
    for index = 1, 4 do
        local clip = CreateFrame("Frame", nil, frame)
        clip:SetFrameLevel(level)
        clip:SetClipsChildren(true)
        local plate = clip:CreateTexture(nil, "BACKGROUND")
        Look.Atlas(plate, Window.PLATE)
        plate:SetHorizTile(false)
        plate:SetVertTile(false)
        plate:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
        plate:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
        pieces[index] = clip
    end
    local top, below = Look.DRESS_HEAD + 4, Look.INSIDE + Window.FOOT -- the stage from the window's top and bottom
    pieces[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    pieces[1]:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -top)
    pieces[2]:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", -Look.INSIDE, 0)
    pieces[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    pieces[3]:SetPoint("TOPLEFT", stage, "TOPLEFT", -Look.INSIDE, 0)
    pieces[3]:SetPoint("BOTTOMRIGHT", stage, "BOTTOMLEFT", 0, 0)
    pieces[4]:SetPoint("TOPLEFT", stage, "TOPRIGHT", 0, 0)
    pieces[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, below)
    local line = Look.Outline(stage)
    line.fill:Hide()
    Window.pieces = pieces
end

-- The loading screen's bar (Look.Headline) with its fill as far as the steps have come and the count in its middle.
local function Progress(content)
    local bar = Look.Headline(content, Window.BAR)
    local fill = bar:CreateTexture(nil, "BACKGROUND", nil, 2)
    fill:SetTexture(Window.FILL)
    local inX, inY = Window.BAR * Window.FILL_IN[1], Window.BAR * Window.FILL_IN[2]
    fill:SetPoint("TOPLEFT", bar, "TOPLEFT", inX, -inY)
    fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", inX, inY)
    function bar.Share(_, share)
        bar.share = share
        local inner = math.max((bar:GetWidth() or 0) - 2 * inX, 0)
        fill:SetWidth(math.max(inner * math.min(math.max(share, 0), 1), 0.01))
        fill:SetTexCoord(0, math.max(share, 0.01), 0, 1)
    end
    bar.fill = fill
    return bar
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Window.WIDTH, Window.HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG") -- over the game's options (SettingsPanel, HIGH), where its button opens it
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameLevel(10) -- room under it for the plate's pieces round the stage (Hole)
    frame:Hide()
    look = Look.Dress(frame, "")
    look.close:SetScript("OnClick", ns.Guard(Window.Close))
    -- Moved by its head.
    local head = look.head
    head:EnableMouse(true)
    head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart", ns.Guard(function() frame:StartMoving() end))
    head:SetScript("OnDragStop", ns.Guard(function() frame:StopMovingOrSizing() end))
    local content = look.content
    -- The stage: the module's sample over the world; what rises over a plate stays inside it.
    stage = CreateFrame("Frame", nil, content)
    stage:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    stage:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, Window.FOOT)
    stage:SetWidth(Window.STAGE)
    stage:SetClipsChildren(true)
    Hole(content)
    -- The step.
    side = CreateFrame("Frame", nil, content)
    side:SetPoint("TOPLEFT", stage, "TOPRIGHT", Window.GAP, -4)
    side:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, Window.FOOT)
    title = side:CreateFontString(nil, "ARTWORK")
    Look.SetFont(title, Window.HEAD, true, Look.GOLD)
    title:SetPoint("TOPLEFT", side, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", side, "TOPRIGHT", 0, 0)
    title:SetJustifyH("LEFT")
    words = side:CreateFontString(nil, "ARTWORK")
    Look.SetFont(words, Window.TEXT)
    words:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    words:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -10)
    words:SetJustifyH("LEFT")
    words:SetJustifyV("TOP")
    words:SetWordWrap(true)
    words:SetSpacing(3)
    -- Under them: the thin golden line, the count, Back and Next.
    local rule = Look.Rule(content)
    rule:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, Window.FOOT - 6)
    rule:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, Window.FOOT - 6)
    forward = Look.Red(content, ns.TEXT.next, Window.BUTTON[1], Window.BUTTON[2])
    forward:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 2)
    forward:SetScript("OnClick", ns.Guard(function() Turn(1) end))
    back = Look.Red(content, Arrowed(ns.TEXT.back, Window.ARROWS.back, true), Window.BUTTON[1], Window.BUTTON[2])
    back:SetPoint("RIGHT", forward, "LEFT", -10, 0)
    back:SetScript("OnClick", ns.Guard(function() Turn(-1) end))
    progress = Progress(content)
    progress:SetPoint("LEFT", content, "BOTTOMLEFT", 0, 2 + Window.BUTTON[2] / 2)
    progress:SetPoint("RIGHT", back, "LEFT", -16, 0)
    count = progress:CreateFontString(nil, "OVERLAY")
    Look.SetFont(count, 14, false, Look.INK)
    count:SetPoint("CENTER", progress, "CENTER", 0, 1)
    frame:HookScript("OnShow", ns.Guard(function() Core.Escape(frame, Window.Close) end))
    frame:HookScript("OnHide", ns.Guard(function() Core.Escape(frame, nil) end))
end

-- The window on a module's setup at that step (the first). True once it shows.
function Window.Show(name, guide, index)
    if not frame then Build() end
    current = { name = name, guide = guide, index = 1 }
    look.title:SetText(ns.TEXT.setup:format(guide.title or name))
    if not frame:IsShown() then
        frame:Show()
        Core.Sound("IG_MAINMENU_OPEN")
    end
    frame:Raise()
    Window.Go(index or 1)
    return true
end

-- For the tests.
function Window.Frame() return frame end
function Window.Parts()
    return { stage = stage, title = title, words = words, count = count, back = back, forward = forward, made = made,
             current = current, progress = progress }
end
