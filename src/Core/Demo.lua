local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Demo
--  /sane window: a small window to try what Core gives every window. Its title
--  bar moves it (let go in the middle of the screen, it docks there) and has
--  the buttons full screen and close; in Blizzard's Edit Mode its box moves it
--  to a corner or an edge too, and docked there the mouse pushed against that
--  screen edge fills the screen. Rest the mouse on it and it opens (Expand.lua):
--  then it explains itself, has a box Keep open, and a bar (Bar.lua) that its
--  button Add fills a step at a time; full, the bar starts again from nothing.
--  Made when the command is first typed; its place is kept with Core's settings.
-------------------------------------------------------------------------------
local SMALL_WIDTH, SMALL_HEIGHT = 260, 64
local OPEN_WIDTH, OPEN_HEIGHT = 380, 250
local INSET = 14                       -- the bar and the controls from the window's sides and bottom
local MOST, STEP, AHEAD = 100, 15, 25  -- the bar: its whole, one Add, the part still to come
local TEXT = {
    title = "Sane UI window",
    help = "Rest the mouse on me and I open; take it away and I close a moment later, unless Keep open is ticked.\n\n"
        .. "Drag my title bar to move me: let go in the middle of the screen and I dock there. In Edit Mode "
        .. "(Esc > Edit Mode) I dock at the corners and edges too; docked at one, push the mouse against that screen "
        .. "edge and I fill the screen, push again and I am back. My buttons do the same, and close me.\n\n"
        .. "Add fills the bar a step at a time. /sane window hides me, /sane window reset puts me back.",
    keep = "Keep open",
    add = "Add",
    number = "%d / %d",
    about = "a window to try Sane UI's windows with: rest the mouse on it, dock it in Edit Mode, fill the screen from its edge (/sane window reset)",
}

local frame, window

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(SMALL_WIDTH, SMALL_HEIGHT)
    frame:SetClipsChildren(true) -- what it holds open is larger than the small window
    window = Core.Window.New(frame, {
        store = Core.Store(Core.name), key = "demo", title = TEXT.title, titleBar = true, dock = true, skin = true, edge = true,
        first = { point = "CENTER", x = 0, y = 120 },
    })

    -- Seen only open: the help, Keep open, Add and the number.
    local help = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", INSET + 2, -(Core.Window.BAR + 8)) -- under the title bar (Window.lua)
    help:SetWidth(OPEN_WIDTH - 2 * (INSET + 2))
    help:SetJustifyH("LEFT")
    help:SetText(TEXT.help)
    local keep = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    keep:SetSize(24, 24)
    keep:SetPoint("BOTTOMLEFT", INSET - 4, INSET + 18)
    local words = keep.Text or keep.text -- the template's words beside the box
    if type(words) == "table" then words:SetText(TEXT.keep) end
    local add = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    add:SetSize(90, 22)
    add:SetPoint("BOTTOMRIGHT", -INSET, INSET + 18)
    add:SetText(TEXT.add)
    local number = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    number:SetPoint("RIGHT", add, "LEFT", -8, 0)
    local inside = { help, keep, add, number }
    local function Show(open)
        for _, part in ipairs(inside) do part:SetShown(open) end
        if not open then keep:SetChecked(false) end
    end
    Show(false)

    local expand = Core.Expand.New(frame, { width = OPEN_WIDTH, height = OPEN_HEIGHT, changed = Show,
        still = function() return window.edge.away end }) -- filling the screen, its size is the edge's
    keep:SetScript("OnClick", function(box) expand:Stay(box:GetChecked() and true or false) end)

    -- Anchored by both sides, the bar is as long as the window.
    local value = 0
    local bar = Core.Bar.New(frame, { height = 12, segments = 10, -- the game's twenty are for a bar the screen's width
        moved = function(value, most) number:SetFormattedText(TEXT.number, math.floor(value + 0.5), most) end })
    bar.frame:SetPoint("BOTTOMLEFT", INSET, INSET)
    bar.frame:SetPoint("BOTTOMRIGHT", -INSET, INSET)
    bar:SetValue(value, MOST, AHEAD)
    add:SetScript("OnClick", function()
        -- A step, up to full; full, from nothing again (at once: a loss does not move)
        if value >= MOST then value = 0 else value = math.min(value + STEP, MOST) end
        Core.Safe("window", bar.SetValue, bar, value, MOST, AHEAD)
    end)
    window:Place()
end

Core.Command("window", TEXT.about, function(rest)
    if not frame then
        Build()
    elseif rest == "reset" then
        frame:Show()
        window:Reset()
    else
        frame:SetShown(not frame:IsShown())
    end
end)
