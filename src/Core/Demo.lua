local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Demo
--  /sane window: a small window to try what Core gives every window, a panel
--  (Window.KINDS). Its title bar moves it (let go in the middle of the screen,
--  it docks there) and has the buttons of a panel, with one of the module's own
--  before them (start the bar again); in Blizzard's Edit Mode its box moves it to
--  a corner or an edge too, and docked there the mouse pushed against that
--  screen edge fills the screen. Esc closes it, a click brings it to the front.
--  Rest the mouse on it and it opens (Expand.lua): two views behind the game's
--  tabs (Views.lua), one that explains it with a box Keep open, one with a bar
--  (Bar.lua) that its button Add fills a step at a time; full, the bar starts
--  again from nothing. What it holds stands in window.inside, under its title
--  bar. Made when the command is first typed; its place and its tab are kept
--  with Core's settings.
-------------------------------------------------------------------------------
local SMALL_WIDTH = 260
local SMALL_HEIGHT = Core.Window.BAR + 32 -- the title bar and the row of tabs (Views.lua: Window.TABS)
local OPEN_WIDTH, OPEN_HEIGHT = 380, 250
local INSET = 14                       -- what a view holds, from its sides and bottom
local MOST, STEP, AHEAD = 100, 15, 25  -- the bar: its whole, one Add, the part still to come
local TEXT = {
    title = "Sane UI window",
    window = "Window",
    bar = "Bar",
    help = "Rest the mouse on me and I open; take it away and I close a moment later, unless Keep open is ticked.\n\n"
        .. "Drag my title bar to move me: let go in the middle of the screen and I dock there. In Edit Mode "
        .. "(Esc > Edit Mode) I dock at the corners and edges too; docked at one, push the mouse against that screen "
        .. "edge and I fill the screen. My buttons do the same, and close me, as Esc does.",
    barHelp = "Add fills the bar a step at a time; the button before mine starts it again.",
    keep = "Keep open",
    add = "Add",
    again = "Start again",
    againTip = "The bar back to nothing.",
    number = "%d / %d",
    about = "a window to try Sane UI's windows with: rest the mouse on it, dock it in Edit Mode, fill the screen from its edge (/sane window reset; reset all: every window of Sane UI)",
    resetAll = "every window is back at its first place and size.",
}

local frame, window, bar, value, number, keep

-- The bar at that value; the number beside it follows (moved).
local function Fill(to)
    value = to
    if bar then Core.Safe("window", bar.SetValue, bar, value, MOST, AHEAD) end
end

-- The view that explains the window, and keeps it open.
local function About(view)
    local help = view:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", INSET + 2, -8)
    help:SetPoint("RIGHT", -(INSET + 2), 0)
    help:SetJustifyH("LEFT")
    help:SetText(TEXT.help)
    keep = CreateFrame("CheckButton", nil, view, "UICheckButtonTemplate")
    keep:SetSize(24, 24)
    keep:SetPoint("BOTTOMLEFT", INSET - 4, INSET - 4)
    local words = keep.Text or keep.text -- the template's words beside the box
    if type(words) == "table" then words:SetText(TEXT.keep) end
    keep:SetScript("OnClick", function(box) window.expand:Stay(box:GetChecked() and true or false) end)
end

-- The view with the bar, which Add fills a step at a time; full, from nothing again.
local function Bar(view)
    local help = view:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", INSET + 2, -8)
    help:SetPoint("RIGHT", -(INSET + 2), 0)
    help:SetJustifyH("LEFT")
    help:SetText(TEXT.barHelp)
    local add = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
    add:SetSize(90, 22)
    add:SetPoint("BOTTOMRIGHT", -INSET, INSET + 18)
    add:SetText(TEXT.add)
    number = view:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    number:SetPoint("RIGHT", add, "LEFT", -8, 0)
    -- Anchored by both sides, the bar is as long as the view.
    bar = Core.Bar.New(view, { height = 12, segments = 10, -- the game's twenty are for a bar the screen's width
        moved = function(shown, most) number:SetFormattedText(TEXT.number, math.floor(shown + 0.5), most) end })
    bar.frame:SetPoint("BOTTOMLEFT", INSET, INSET)
    bar.frame:SetPoint("BOTTOMRIGHT", -INSET, INSET)
    Fill(value or 0)
    add:SetScript("OnClick", function()
        -- A step, up to full; full, from nothing again (at once: a loss does not move)
        if value >= MOST then Fill(0) else Fill(math.min(value + STEP, MOST)) end
    end)
end

-- It begins to open, or to close: closed, nothing keeps it open.
local function Opened(now)
    if not now and keep then keep:SetChecked(false) end
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(SMALL_WIDTH, SMALL_HEIGHT)
    frame:SetClipsChildren(true) -- what it holds open is larger than the small window
    window = Core.Window.New(frame, {
        kind = "panel", store = Core.Store(Core.name), key = "demo", title = TEXT.title,
        sizable = false, -- it opens under the mouse: its size is Expand's (Doc/guides/windows.md, invariant 2)
        first = { point = "CENTER", x = 0, y = 120 },
        buttons = { { atlas = "common-icon-undo", tip = TEXT.again, text = TEXT.againTip, click = function() Fill(0) end } },
        tabs = { { text = TEXT.window, build = About }, { text = TEXT.bar, build = Bar } },
    })
    window.expand = Core.Expand.New(frame, { width = OPEN_WIDTH, height = OPEN_HEIGHT, changed = Opened,
        still = function() return window.edge.away end }) -- filling the screen, its size is the edge's
    value = 0
    window:Place()
end

Core.Command("window", TEXT.about, function(rest)
    if rest == "reset all" then
        Core.Window.ResetAll()
        Core.Print(TEXT.resetAll)
    elseif not frame then
        Build()
    elseif rest == "reset" then
        frame:Show()
        window:Reset()
    else
        frame:SetShown(not frame:IsShown())
    end
end)
