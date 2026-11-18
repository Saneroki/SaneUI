local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Onboarding - Window
--  The setup's window, made the first time one opens: a window of its own in
--  the bronze (Look.Dress), in the middle of the screen, moved by its head,
--  closed by its X or Esc. It never blocks the game: the world goes on behind
--  it and the module's plates follow each change at once.
--
--  The run's first page (Saneroki, 2026-11-18: "a very first page where all
--  the onboardings that still need to go through is listed"): on the stage
--  the plain Sane UI logo ("use a plain Sane UI logo instead of the Core
--  banner") and under it, very clearly, Sane UI's windows and the game's own,
--  each only where a window of a module that is on has it (Window.Has): the
--  button with the circling arrows itself (Core's Window.Swap), larger,
--  "means to show the classic windows instead"; the red buttons beside a full
--  screen window's X, "will detatch windows from fullscreen or not"; and the
--  dropdown Classic windows itself as full screen has it, "to choose which
--  one is the default one", working (its kept choices, Core.Classic); at the right why and where ("please go through this to
--  configure your addons to your needs. The configure steps are found under
--  /sane setup or in the addon settings") and a row for each setup of the run,
--  its name, its steps and Choose defaults (done: Defaults chosen, or Set
--  up); under them Start, to the first setup still to go through. Back on a
--  setup's first step comes back to it.
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
--            them, for a setup not gone through yet, Choose defaults in the
--            words of Forever's top bar (Saneroki, 2026-11-18: "Add a Skip",
--            then "instead of skip it says Choose Defaults"): the setup's
--            switches to their defaults, it no longer opens by itself, and the
--            run goes on to the next
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
Window.WORDS = 14    -- a button of words alone (Choose defaults)
Window.ROW = 34      -- a setup's row on the first page
Window.NAME = 16     -- its name's size
Window.LOGO = "Interface\\AddOns\\SaneUI_Onboarding\\Art\\logo" -- the plain Sane UI logo (dev/tools/logo-art saneui)
Window.LOGO_SIZE = { 300, 100 } -- drawn as dev/tools/art made it (kind banner)
Window.LOGO_RIGHT = 0.75 -- its box fills the file's left 768 of 1024 texels
Window.SWAP_SCALE = 1.75 -- the button with the circling arrows on the first page: its 24 units, larger
Window.EXPLAIN = 15  -- the words beside it and under the dropdown
Window.EXPLAIN_HEAD = 18 -- their head
Window.EXPLAIN_ROW = 62 -- a button's row there, with its words beside it

local frame, look, stage, side, title, words, count, back, forward, progress, note, defaults
local list, logo  -- the first page's rows' holder and the logo on its stage
local explained   -- under the logo: the classic window's button and the dropdown Classic windows, with their words
local rows = {}   -- the first page's rows, made when first needed
local first       -- true while the run's first page shows
local current     -- { name, guide, index } while a setup shows
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
    Window.away = false -- closed while Edit Mode held it away: it stays closed
    if frame and frame:IsShown() then
        frame:Hide()
        Core.Sound("IG_MAINMENU_CLOSE")
    end
end

-- The sample drawn anew by the module and the step's controls showing the values in use.
function Window.Changed()
    if first or not current then return end
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
    first = false
    list:Hide()
    StageOf(current.name) -- the first page's logo out of sight, whether the module draws a sample or not
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
    -- Choose defaults for a setup not gone through yet (nor its defaults chosen); the bar reaches to it, else to Back.
    local open = Core.Onboarding.Pending(current.name)
    defaults:SetShown(open)
    progress:SetPoint("RIGHT", open and defaults or back, "LEFT", -16, 0)
    progress:Share(index / #steps)
    back:SetEnabled(index > 1 or Core.Onboarding.Run() ~= nil) -- the first step of a run's setup: to its first page
    local last = index == #steps
    forward:SetText(last and not Core.Onboarding.Following(current.name) and ns.TEXT.done
        or Arrowed(last and ns.TEXT.nextSetup or ns.TEXT.next, Window.ARROWS.next))
    Window.Changed()
end

local Row -- a setup's row on the first page (below)
local Lay -- the first page's explanations, those that apply (below)

-- The run's setups in a row each: its name, its steps, Choose defaults (done: Defaults chosen or Set up, faint).
-- What is left to go through: the count under them, Start or Done.
local function Listed()
    local names, y, left = Core.Onboarding.Run() or {}, 0, 0
    for index, name in ipairs(names) do
        local row, guide = rows[index] or Row(index), Core.Onboarding.Guide(name)
        row.name = name
        row.label:SetText(guide and guide.title or name)
        local steps = guide and #guide.steps or 0
        row.steps:SetText(steps == 1 and ns.TEXT.oneStep or ns.TEXT.steps:format(steps))
        local done = not Core.Onboarding.Pending(name)
        if not done then left = left + 1 end
        row.button:SetShown(not done)
        row.state:SetShown(done)
        row.state:SetText(Core.Onboarding.Defaulted(name) and ns.TEXT.defaultsChosen or ns.TEXT.goneThrough)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -y)
        row:Show()
        y = y + Window.ROW
    end
    for index = #names + 1, #rows do rows[index]:Hide() end
    count:SetText(left == 0 and ns.TEXT.noneLeft or left == 1 and ns.TEXT.oneLeft or ns.TEXT.left:format(left))
    forward:SetText(left == 0 and ns.TEXT.done or Arrowed(ns.TEXT.start, Window.ARROWS.next))
    return left
end

-- The run's first page.
local function FirstPage()
    first = true
    current = nil
    look.title:SetText(ns.TEXT.firstHead)
    title:SetText(ns.TEXT.firstTitle)
    words:SetText(ns.TEXT.firstText)
    note:SetText("")
    for _, holders in pairs(made) do
        for _, holder in pairs(holders) do holder:Hide() end
    end
    StageOf("*first") -- the modules' samples out of sight
    logo:Show()
    Lay()
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", words, "BOTTOMLEFT", 0, -18)
    list:SetPoint("TOPRIGHT", words, "BOTTOMRIGHT", 0, -18)
    list:Show()
    defaults:Hide()
    progress:SetPoint("RIGHT", back, "LEFT", -16, 0)
    progress:Share(0)
    back:SetEnabled(false)
    Listed()
end

-- Back or on; past the last step the setup is gone through (Core keeps it) and the run's next one shows here. On the
-- first page: Start, the first setup still to go through (none left: the window closes); Back from a run's setup's
-- first step: the first page.
local function Turn(by)
    if first then
        if by < 0 then return end
        Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
        if not Core.Onboarding.Continue() then Window.Close() end
        return
    end
    if not current then return end
    local index = current.index + by
    if index < 1 then
        if Core.Onboarding.Run() then
            Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
            FirstPage()
        end
        return
    end
    if index > #current.guide.steps then
        if Core.Onboarding.Finished(current.name) then return Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON") end
        return Window.Close()
    end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    Window.Go(index)
end

-- Choose defaults in a setup: its switches back to their defaults (Core asks first where some differ), kept as done;
-- the run's first setup still to go through here, else the window closes.
local function Defaults()
    if not current then return end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF")
    Core.Onboarding.Defaults(current.name, function()
        if not Core.Onboarding.Continue() then Window.Close() end
    end)
end

-- A button of words alone in the colours of Forever's top bar (Look.NAV, lit under the mouse), not a red one: red is
-- for what matters (Back and Next stand beside it). Its tooltip: the words and tip.
local function WordsButton(parent, text, tip, click)
    local button = CreateFrame("Button", nil, parent)
    local label = button:CreateFontString(nil, "ARTWORK")
    Look.SetFont(label, Window.WORDS, false, Look.NAV)
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetText(text)
    local width = label:GetStringWidth()
    button:SetSize(math.max(type(width) == "number" and width or 0, 60) + 12, Window.BUTTON[2])
    local function Lit(lit)
        local colour = lit and Look.NAV_LIT or Look.NAV
        label:SetTextColor(colour[1], colour[2], colour[3])
    end
    button:SetScript("OnEnter", ns.Guard(function() Lit(true) end))
    button:SetScript("OnLeave", ns.Guard(function() Lit(false) end))
    button:SetScript("OnClick", ns.Guard(click))
    Core.Tip(button, text, tip)
    button.label = label
    return button
end

-- A setup's row on the first page: its name, its steps faint, Choose defaults at its right (done: the state, faint).
function Row(index)
    local row = CreateFrame("Frame", nil, list)
    row:SetHeight(Window.ROW)
    row.label = row:CreateFontString(nil, "ARTWORK")
    Look.SetFont(row.label, Window.NAME, false, Look.GOLD)
    row.label:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.label:SetJustifyH("LEFT")
    row.steps = row:CreateFontString(nil, "ARTWORK")
    Look.SetFont(row.steps, Window.NOTE, false, Look.FAINT)
    row.steps:SetPoint("LEFT", row.label, "RIGHT", 10, -1)
    row.button = WordsButton(row, ns.TEXT.defaults, ns.TEXT.defaultsTip, function()
        if not row.name then return end
        Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF")
        Core.Onboarding.Defaults(row.name, function() if first then Listed() end end)
    end)
    row.button:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.state = row:CreateFontString(nil, "ARTWORK")
    Look.SetFont(row.state, Window.NOTE, false, Look.FAINT)
    row.state:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    local line = Look.Rule(row)
    line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    line:SetAlpha(0.35)
    rows[index] = row
    return row
end

-- Words for the first page's stage, wrapped, as wide as the stage leaves.
local function Explain(holder, size, colour)
    local text = holder:CreateFontString(nil, "ARTWORK")
    Look.SetFont(text, size, false, colour)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    text:SetSpacing(3)
    return text
end

-- What the windows of the modules that are on have (Saneroki, 2026-11-18: "some addons like the navigation, tooltip
-- and nameplate doesn't have those buttons in it so if only those addons are part of the onboarding then it should
-- not show those because that would cause confusion. On addons that do have those icons should show them"): the
-- button with the circling arrows (a window with native: Social's chat), the button that makes a full screen's
-- window one of its own (a board with a window that can stand alone: Social's, Inventory's, Combat's), the
-- dropdown's kept choices (Navigation's minimap, map and quest log too).
function Window.Has()
    local has = { swap = false, own = false, kept = false }
    for _, window in ipairs(Core.Window and Core.Window.All and Core.Window.All() or {}) do
        if type(window.options) == "table" and window.options.native then has.swap = true end
    end
    has.own = Core.Board and Core.Board.Apart and Core.Board.Apart() == true or false
    has.kept = Core.Classic and Core.Classic.Kept and #Core.Classic.Kept() > 0 or false
    return has
end

-- A red button of the full screen's as Core's board draws it (RedButton-Condense: its own window; -Expand: back onto
-- the full screen), larger, its tip Core's: a picture with a tooltip, it does nothing here.
local function Red(holder, atlas, tip, tipText)
    local button = CreateFrame("Button", nil, holder)
    button:SetSize(24, 24)
    local normal = button:CreateTexture(nil, "ARTWORK")
    Look.Atlas(normal, atlas)
    normal:SetAllPoints()
    button:SetNormalTexture(normal)
    local lit = button:CreateTexture(nil, "HIGHLIGHT")
    Look.Atlas(lit, "RedButton-Highlight")
    lit:SetBlendMode("ADD")
    lit:SetAllPoints()
    button:SetScale(Window.SWAP_SCALE)
    Core.Tip(button, tip, tipText)
    button.normal = normal
    return button
end

-- Under the logo, very clearly, each where it applies (Lay): the button with the circling arrows (Core's own, larger)
-- and what it does; the red buttons beside a full screen window's X and what they do; the dropdown Classic windows
-- as full screen has it, working (Saneroki, 2026-11-18: "make the dropdown on the first page actually work": the kept
-- choices, Core.Classic.KeptMenu), and what it chooses. Without the dropdown's template (another client) its words
-- alone.
local function Explained(holder)
    local parts = {}
    local head = Explain(holder, Window.EXPLAIN_HEAD, Look.GOLD)
    head:SetPoint("TOPLEFT", holder, "TOPLEFT", 24, -150)
    head:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -24, -150)
    head:SetText(ns.TEXT.windows)
    parts.head = head
    parts.swap = Core.Window.Swap(holder, Core.Window.TEXT.classic, Core.Window.TEXT.classicTip, function() end)
    parts.swap:SetScale(Window.SWAP_SCALE)
    parts.swapText = Explain(holder, Window.EXPLAIN, Look.INK)
    parts.swapText:SetText(ns.TEXT.swap)
    local board = Core.Board.TEXT
    parts.own = Red(holder, "RedButton-Condense", board.own, board.ownTip)
    parts.ownText = Explain(holder, Window.EXPLAIN, Look.INK)
    parts.ownText:SetText(ns.TEXT.alone)
    parts.back = Red(holder, "RedButton-Expand", board.back, board.backTip)
    parts.backText = Explain(holder, Window.EXPLAIN, Look.INK)
    parts.backText:SetText(ns.TEXT.onto)
    local made, menu = pcall(CreateFrame, "DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
    if made and menu then
        menu:SetWidth(Core.Edge.MENU_WIDTH)
        if menu.OverrideText then menu:OverrideText(Core.Edge.CLASSIC) end
        if menu.SetupMenu then menu:SetupMenu(ns.Guard(function(_, root) Core.Classic.KeptMenu(root) end)) end
        parts.menu = menu
    end
    parts.menuText = Explain(holder, Window.EXPLAIN, Look.INK)
    parts.menuText:SetWidth(Window.STAGE - 2 * 24 - 2) -- a width, not a right anchor: that would pull its middle down
    parts.menuText:SetText(ns.TEXT.classic)
    for _, part in pairs(parts) do part:Hide() end
    return parts
end

-- The explanations that apply (Window.Has), one under another under their head; none: not the head either.
function Lay()
    local parts, has = explained, Window.Has()
    for _, part in pairs(parts) do part:Hide() end
    if not (has.swap or has.own or has.kept) then return has end
    local head, scale, y = parts.head, Window.SWAP_SCALE, 14
    head:Show()
    local beside = 24 * scale + 18 -- the words right of a button
    local function Row(button, text, height)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 2 / scale, -y / scale)
        text:ClearAllPoints()
        text:SetPoint("TOPLEFT", head, "BOTTOMLEFT", beside, -(y - 2))
        text:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -(y - 2))
        button:Show()
        text:Show()
        y = y + height
    end
    if has.swap then Row(parts.swap, parts.swapText, Window.EXPLAIN_ROW) end
    if has.own then
        Row(parts.own, parts.ownText, Window.EXPLAIN_ROW - 12)
        Row(parts.back, parts.backText, Window.EXPLAIN_ROW - 12)
    end
    if has.kept then
        local text = parts.menuText
        text:ClearAllPoints()
        if parts.menu then
            parts.menu:ClearAllPoints()
            parts.menu:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -y)
            parts.menu:Show()
            text:SetPoint("TOPLEFT", parts.menu, "BOTTOMLEFT", 2, -10)
        else
            text:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -y)
        end
        text:Show()
    end
    return has
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
    -- The first page: its rows under its words, Sane UI's logo on the stage.
    list = CreateFrame("Frame", nil, side)
    list:SetHeight(1)
    list:Hide()
    local holder = StageOf("*first")
    logo = holder:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(Window.LOGO)
    logo:SetTexCoord(0, Window.LOGO_RIGHT, 0, 1)
    logo:SetSize(Window.LOGO_SIZE[1], Window.LOGO_SIZE[2])
    logo:SetPoint("TOP", holder, "TOP", 0, -24)
    explained = Explained(holder)
    holder:Hide()
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
    defaults = WordsButton(content, ns.TEXT.defaults, ns.TEXT.defaultsTip, Defaults)
    defaults:SetPoint("RIGHT", back, "LEFT", -10, 0)
    progress = Progress(content)
    progress:SetPoint("LEFT", content, "BOTTOMLEFT", 0, 2 + Window.BUTTON[2] / 2)
    progress:SetPoint("RIGHT", back, "LEFT", -16, 0)
    count = progress:CreateFontString(nil, "OVERLAY")
    Look.SetFont(count, 14, false, Look.INK)
    count:SetPoint("CENTER", progress, "CENTER", 0, 1)
    frame:HookScript("OnShow", ns.Guard(function() Core.Escape(frame, Window.Close) end))
    frame:HookScript("OnHide", ns.Guard(function() Core.Escape(frame, nil) end))
    -- Edit Mode opened while it shows (a step's button for it, or the game's menu): out of sight until Edit Mode
    -- closes, then back at the same step, its sample drawn anew (Saneroki, 2026-11-18: "During the edit mode the
    -- setup window is temporarily hiden until you exit edit mode again").
    Core.EditMode.Watch(ns.Guard(function(on)
        if on and frame:IsShown() then
            Window.away = true
            frame:Hide()
        elseif not on and Window.away then
            Window.away = false
            frame:Show()
            frame:Raise()
            Window.Changed()
        end
    end))
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

-- The window on the run's first page. True once it shows.
function Window.First()
    if not frame then Build() end
    if not frame:IsShown() then
        frame:Show()
        Core.Sound("IG_MAINMENU_OPEN")
    end
    frame:Raise()
    FirstPage()
    return true
end

-- For the tests.
function Window.Frame() return frame end
function Window.Parts()
    return { stage = stage, title = title, words = words, count = count, back = back, forward = forward, made = made,
             current = current, progress = progress, own = own, note = note, head = look and look.title,
             defaults = defaults, list = list, rows = rows, logo = logo, first = first, explained = explained }
end
