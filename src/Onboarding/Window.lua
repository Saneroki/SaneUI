local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Onboarding - Window
--  The setup's window, made the first time one opens: a window of its own in
--  the bronze (Look.Dress), in the middle of the screen, moved by its head,
--  closed by its X or Esc. It never blocks the game: the world goes on behind
--  it and the module's plates follow each change at once.
--
--    left    the stage: a grey box (Look.Box) on the window's plate, solid,
--            the module draws its sample into (the guide's Stage; each
--            module into a frame of its own over it, the others' hidden),
--            anew whenever the step shows or a setting changes (Saneroki,
--            2026-11-16: see-through tried, "make it solid not transparent.
--            it gets to confusing if it is transparent actually")
--    right   the step: its head in the game's gold, its words, its controls
--            (Controls.lua), made the first time the step shows and kept
--            and at its foot a faint note: where to start the setup again
--            (the module's options page, /sane setup), and for one not gone
--            through yet that it opens again at the next login (Saneroki,
--            2026-11-18: "during onboarding say that you can start this again
--            in the addon settings")
--    under   the loading screen's bar, filled as far as the steps have
--            come, "Step 2 of 9" in it (Saneroki, 2026-11-16), and the
--            buttons Back and Next (Done on the last step; Next setup there
--            while the run has one more), red with the game's arrows, as
--            Forever's own steps of the character creation have them; before
--            them, for a setup not gone through yet, Skip setup in the words
--            of Forever's top bar (Saneroki, 2026-11-18: "Add a Skip"): it no
--            longer opens by itself, and the run goes on to the next
--
--  Changes are made as they are clicked (Core.Set), so closing the window at
--  any step keeps what was chosen; nothing to save or undo here. Each step
--  shown is told to Core (Reached: where a setup not gone through yet was
--  left), and the last one done (Finished: gone through, and the next setup
--  of the run in this window).
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
Window.NOTE = 12     -- the faint note at the step's foot (every setup's steps leave it room: over 100 units)
Window.SKIP = 14     -- Skip setup's words

local frame, look, stage, side, title, words, count, back, forward, progress, note, skip
local current   -- { name, guide, index } while a setup shows
local made = {} -- [module name] = { [step index] = its controls' frame }, made the first time each shows
local own = {}  -- [module name] = its own frame over the stage, which it draws into; the other modules' hidden

-- The module's own frame on the stage, the others' out of sight: what one module drew never shows under another's.
local function StageOf(name)
    local frame = own[name]
    if not frame then
        frame = CreateFrame("Frame", nil, stage)
        frame:SetAllPoints(stage)
        own[name] = frame
    end
    for other, mine in pairs(own) do mine:SetShown(other == name) end
    return frame
end

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
        ns.Safe("sample", guide.Stage, StageOf(current.name), guide.steps[index], index)
    end
end

-- A control was changed by the player: the module's switch set (Core.Set tells the module), then all shown anew.
function Window.Set(name, key, value)
    Core.Set(name, key, value)
    Window.Changed()
end

-- Words in a colour of Look's, as the game's markup has them.
local function Hued(text, colour)
    local function Byte(share) return math.floor(math.min(math.max(share, 0), 1) * 255 + 0.5) end
    return ("|cff%02x%02x%02x%s|r"):format(Byte(colour[1]), Byte(colour[2]), Byte(colour[3]), text)
end

-- The first step's words to whoever went through an older version of the setup: what changed, in gold, first.
local function Opening(index)
    if index ~= 1 or not Core.Onboarding.Changed(current.name) then return "" end
    local changed = current.guide.changed
    local said = type(changed) == "string" and changed ~= "" and ns.TEXT.changed:format(changed) or ns.TEXT.changedAny
    return Hued(said, Look.GOLD) .. "\n\n"
end

-- The note at the step's foot: on the run's last step of a setup, the one that comes next; for a setup not gone
-- through yet, that it comes back; always where to start it again (its options page's button, else the command).
local function Noted(index)
    local name, lines = current.name, {}
    local following = index == #current.guide.steps and Core.Onboarding.Following(name)
    if following then
        local guide = Core.Onboarding.Guide(following)
        lines[#lines + 1] = ns.TEXT.following:format(guide and guide.title or following)
    end
    if not Core.Onboarding.Done(name) then lines[#lines + 1] = ns.TEXT.unfinished end
    local module = rawget(SaneUI, name)
    if Core.Described(name, "setup") then
        lines[#lines + 1] = ns.TEXT.again:format(type(module) == "table" and module.title or name)
    else
        lines[#lines + 1] = ns.TEXT.againTyped:format(name:lower())
    end
    return table.concat(lines, " ")
end

-- To a step: its head, words and controls, the count and the buttons; told to Core (where it was left).
function Window.Go(index)
    if not current then return end
    local steps = current.guide.steps
    index = math.max(1, math.min(tonumber(index) or 1, #steps))
    current.index = index
    Core.Onboarding.Reached(current.name, index)
    local step = steps[index]
    title:SetText(step.title or "")
    words:SetText(Opening(index) .. (step.text or ""))
    note:SetText(Noted(index))
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
    -- Skip for a setup not gone through yet (nor skipped); the bar reaches to it, else to Back.
    local skippable = not Core.Onboarding.Done(current.name)
    skip:SetShown(skippable)
    progress:SetPoint("RIGHT", skippable and skip or back, "LEFT", -16, 0)
    progress:Share(index / #steps)
    back:SetEnabled(index > 1)
    local last = index == #steps
    forward:SetText(last and not Core.Onboarding.Following(current.name) and ns.TEXT.done
        or Arrowed(last and ns.TEXT.nextSetup or ns.TEXT.next, Window.ARROWS.next))
    Window.Changed()
end

-- Back or on; past the last step the setup is gone through (Core keeps it) and the run's next one shows here.
local function Turn(by)
    if not current then return end
    local index = current.index + by
    if index > #current.guide.steps then
        if Core.Onboarding.Finished(current.name) then return Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON") end
        return Window.Close()
    end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    Window.Go(index)
end

-- Skipped: kept as if gone through (Core), the run's next setup here, else the window closes.
local function Skip()
    if not current then return end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF")
    if not Core.Onboarding.Finished(current.name, true) then Window.Close() end
end

-- Skip setup: words alone in the colours of Forever's top bar (Look.NAV, lit under the mouse), not a red button:
-- red is for what matters (Back and Next stand beside it).
local function SkipButton(content)
    local button = CreateFrame("Button", nil, content)
    local label = button:CreateFontString(nil, "ARTWORK")
    Look.SetFont(label, Window.SKIP, false, Look.NAV)
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetText(ns.TEXT.skip)
    local width = label:GetStringWidth()
    button:SetSize(math.max(type(width) == "number" and width or 0, 60) + 12, Window.BUTTON[2])
    local function Lit(lit)
        local colour = lit and Look.NAV_LIT or Look.NAV
        label:SetTextColor(colour[1], colour[2], colour[3])
    end
    button:SetScript("OnEnter", ns.Guard(function() Lit(true) end))
    button:SetScript("OnLeave", ns.Guard(function() Lit(false) end))
    button:SetScript("OnClick", ns.Guard(Skip))
    Core.Tip(button, ns.TEXT.skip, ns.TEXT.skipTip)
    button.label = label
    return button
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
    -- The stage: the module's sample in a grey box; what rises over a plate stays inside it.
    stage = CreateFrame("Frame", nil, content)
    stage:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    stage:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, Window.FOOT)
    stage:SetWidth(Window.STAGE)
    stage:SetClipsChildren(true)
    Look.Box(stage)
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
    note = side:CreateFontString(nil, "ARTWORK")
    Look.SetFont(note, Window.NOTE, false, Look.FAINT)
    note:SetPoint("BOTTOMLEFT", side, "BOTTOMLEFT", 0, 4)
    note:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", 0, 4)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("BOTTOM")
    note:SetWordWrap(true)
    note:SetSpacing(2)
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
    skip = SkipButton(content)
    skip:SetPoint("RIGHT", back, "LEFT", -10, 0)
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
    local place, total = Core.Onboarding.Place(name)
    look.title:SetText(total and total > 1 and ns.TEXT.setupOf:format(guide.title or name, place, total)
        or ns.TEXT.setup:format(guide.title or name))
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
             current = current, progress = progress, own = own, note = note, head = look and look.title, skip = skip }
end
