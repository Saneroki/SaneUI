local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Window
--  Moving and sizing a window, for every module, in two layers.
--
--  The parts, for a window that is not ours to keep (the game's spellbook):
--      Window.Mover(handle, frame, hooks)   drag the handle to move the frame
--      Window.Sizer(frame, hooks)           a grip in a corner that sizes it
--  They move and size, and tell when it is over. Nothing is written into the
--  frame; where it stands is the caller's to keep.
--
--  The whole, for a window of our own. Every window is arranged in Blizzard's
--  Edit Mode (EditMode.lua): a box in Edit Mode's own look lies over it there
--  (window.box: Edit Mode's art, the window's title with the mouse on it), it is
--  dragged by that box and docks where it is let go, and a sizable one has its
--  grip in a corner; one that fills the screen when Edit Mode opens is back in
--  its zone at once. Sizing is only there.
--
--  A kind of window that has a title bar (titleBar; the small chat, a unit
--  frame have none) shows it across its top: its title at the left (with
--  search, a magnifier before it: a click there opens the game's search box
--  over the whole bar but its buttons, fuzzy search is the module's, Fuzzy.lua),
--  and at the right the buttons [the game's own window] [full screen / back]
--  [close]. The first only with native: the game's square button with its
--  circling arrows; the same button stands on the game's window, beside its
--  close button, to come back to ours. The second only with edge (and its switch
--  Can expand to fullscreen on): the game's own (MaximizeMinimizeButtonFrameTemplate),
--  filling the screen and back as Edge.lua does. The third is the game's close
--  button. Outside Edit Mode the bar also moves the window, at any time, but
--  docked at a screen edge (that is Edit Mode's; dragDocked lets it), and such
--  a drag docks only in the middle of the screen. Every window that fills the
--  screen has the bar at its top, the window's full screen view's own; in Edit
--  Mode the buttons are not there.
--
--  What a window was left as is kept with its place: whether it filled the
--  screen, and whether the game's own window was chosen instead. When the game
--  asks for the window (its key, an NPC), the module calls window:Open(), which
--  shows the one chosen, as it was left (Doc/ideas/Windows.md: the game's
--  triggers).
--      local window = Window.New(frame, {
--          kind = "panel",              -- its kind (Window.KINDS): the options below it has unless given here
--          store = ns.store,            -- the module's saved table; the place is kept in store.place
--          key = "place",               -- another name for it, for a module's second window
--          first = { point = "LEFT", x = 40, y = 0, width = 380, height = 260 },  -- where it stands at first;
--                                       -- or dock = "BOTTOMLEFT": docked in that zone at first (a talk: CENTER)
--          title = "Social",            -- its name, on its title bar and on its box in Edit Mode
--          titleBar = true,             -- it has a title bar (without: only while it fills the screen)
--          search = function(text) end, -- what is typed into its search box, at every change ("": none)
--          dragDocked = true,           -- its title bar moves it docked at a screen edge too (not in Edit Mode)
--          escape = "close",            -- Esc closes it, small or full, as the game's panels close (close, else
--                                       -- hidden); full, it is not made small first, so it opens full again.
--                                       -- Without: Esc only brings a full window back to its size (Edge.lua)
--          sizable = true,              -- a grip in Edit Mode (window.grip); its size is kept too
--          minWidth = 180, minHeight = 130,
--          dock = true,                 -- it docks to the screen's edges (Dock.lua)
--          skin = true,                 -- background and border (Skin.lua) with round corners (Shape.lua),
--                                       -- one with an edge it is docked to
--          corners = ns.options,        -- the module's settings with the switches Corner radius and Don't
--                                       -- round corners on screen edges (Shape.Options); without: edge's
--          usable = function() end,     -- may it be moved and sized right now? Without: yes
--          docked = function(zone) end, -- after it was placed, and once it has filled the screen (edge):
--                                       -- the entry of Dock.ZONES it hangs on, or nil
--          edge = ns.options,           -- docked, it fills the screen when the mouse is pushed against
--                                       -- that screen edge, and goes back when pushed there again (Edge.lua),
--                                       -- as the module's section Expand window says (Edge.Options, with
--                                       -- the corners' switches); true: as that section is by default
--          motion = function() end,     -- its kind of motion for that, instead of the section's (Motion.lua)
--          content = region,            -- what it holds: out of sight while its size moves (Edge.lua)
--          classic = { { text = "Friends list", show = function() end } },  -- the game's own windows it
--                                       -- stands for: full, it lists them in the dropdown Classic windows;
--                                       -- one chosen, it goes back to its zone and show() brings the game's
--          filled = function(full) end, -- it has begun to fill the screen (true) or to go back (false)
--          close = function() end,      -- what its close button does; without: it hides the window
--          native = {                   -- the game's own window it stands for (a vendor's, the auction house)
--              frame = function() end,  -- that window (or a function giving it, nil while not loaded)
--              show = function() end,   -- the game's window instead of ours (the module does both)
--              back = function() end,   -- ours instead of the game's
--              anchor = function(button) end, -- where the button back to ours goes on the game's window
--                                       -- (without: beside its close button, else at its top right)
--          },
--      })
--      window:Place()                   -- where it was left; call it once the window is built
--      window:Reset()                   -- its first place and size again
--      window:Open()                    -- the game asks for it: the game's own window or ours, as last chosen;
--                                       -- ours filling the screen if it was left so ("native" / "ours")
--      window:Native(on)                -- the game's own window instead (on), or ours again; kept for Open
--      window:Remember(what, value)     -- kept with its place (full, native)
--      window:Refresh()                 -- its title bar and buttons as the window is now
--      window:Locked()                  -- it holds the game's protected frames and a fight is on: nothing of
--                                       -- ours moves, sizes, shows or hides it now (placing waits for the end)
--      window:Attach()                  -- puts the button back to ours onto the game's window (done at New
--                                       -- if that is there; again once it is, for one loaded on demand)
--      window.zone                      -- the name of the zone it is docked to, or nil
--      window.edge                      -- with edge: edge.full, it fills the screen (Edge.lua)
--  window.bar, window.buttons       -- the title bar and its buttons, once shown
--
--  The kept place is plain numbers: { x, y, width, height, dock, full, native }, x and y of
--  the top left corner from the screen's lower left one. A docked window grows
--  away from its edges, so its grip moves to a corner that is not at one.
--
--  A window made by New is a child of UIParent at its scale.
-------------------------------------------------------------------------------
local Window = {}
Core.Window = Window

Window.BAR, Window.BAR_LEVEL = 32, 20 -- the title bar's height; how far above the window (over what it holds)
Window.DRAG_ZONES = { CENTER = true } -- where a title bar's drag, outside Edit Mode, may dock a window
Window.BUTTON, Window.BUTTON_INSET = 24, 4 -- the buttons' size (the game's close button's); from the bar's right
Window.TEXT_INSET, Window.GLASS = 8, 12 -- the title from the bar's left; the search's magnifier
Window.BOX, Window.BOX_INSET = 20, 6 -- the search box's height; its room from what stands beside it
Window.CASCADE = Window.BAR -- a window that cannot stand where it was left stands that far down and right of it
Window.TEXT = {
    classic = "Classic window", classicTip = "The game's own window instead of this one.",
    sane = "Sane UI window", saneTip = "Sane UI's window instead of the game's.",
}
-- The kinds of window (Saneroki, 2026-10-16; Doc/guides/windows.md, section 2): the options each kind has
-- unless the module gives them itself. What the Combat module shows (unit frames, nameplates, buffs, action
-- bars) is no window.
Window.KINDS = {
    -- on the screen all the time: the chat, the minimap; no title bar while small, see-through
    screen = { dock = true, edge = true, sizable = true },
    -- opened and closed by the player: the spellbook, the talents, the guild, the bags
    panel = { titleBar = true, dock = true, skin = true, edge = true, sizable = true, escape = "close" },
    -- an NPC's: a vendor, a trainer, the auction house, the bank; at first in the middle (its first place),
    -- closing it ends the talk (its close)
    talk = { titleBar = true, dock = true, skin = true, edge = true, sizable = true, escape = "close", first = { dock = "CENTER" } },
}
local SQUARE = "Interface\\Buttons\\UI-SquareButton-" -- the game's square button, as its group finder's refresh
local ARROWS = "Interface\\Buttons\\UI-RefreshButton"   -- and its icon, the circling arrows, half the button's size
Window.BOX_LEVEL = 100 -- how far above the window its box in Edit Mode lies, over all it holds; the grip over that
-- Edit Mode's look for a frame that can be moved, as Blizzard_EditMode draws it
-- (EditModeSystemSelectionLayout, local there): its atlases, in a nine-slice of our own frame.
local SELECTION = {
    TopRightCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = 8 },
    TopLeftCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = 8 },
    BottomLeftCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = -8 },
    BottomRightCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = -8 },
    TopEdge = { atlas = "_%s-NineSlice-EdgeTop" },
    BottomEdge = { atlas = "_%s-NineSlice-EdgeBottom" },
    LeftEdge = { atlas = "!%s-NineSlice-EdgeLeft" },
    RightEdge = { atlas = "!%s-NineSlice-EdgeRight" },
    Center = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8 },
}
local HIGHLIGHT = "editmode-actionbar-highlight" -- the kit Edit Mode shows every movable frame in
local HOVER = 0.4 -- the brighter copy over it while the mouse is on it: so opaque, added (as Blizzard's)

local GRIP = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-" -- the game's grip (PanelResizeButtonTemplate)
-- The art is drawn for the lower right corner: mirrored for the others.
local MIRROR = {
    BOTTOMRIGHT = { 0, 1, 0, 1 }, BOTTOMLEFT = { 1, 0, 0, 1 },
    TOPRIGHT = { 0, 1, 1, 0 }, TOPLEFT = { 1, 0, 1, 0 },
}

-------------------------------------------------------------------------------
--  The parts
-------------------------------------------------------------------------------
-- hooks: usable() may it be moved now, started(), stopped() the drag is over. Each runs in Core.Safe: one
-- that fails is noted, and the drag is still begun or let go as the game's.
function Window.Mover(handle, frame, hooks)
    local moving
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if hooks.usable and not Core.Safe("window", hooks.usable) then return end
        frame:SetMovable(true)
        frame:SetClampedToScreen(true)
        frame:StartMoving()
        moving = true
        if hooks.started then Core.Safe("window", hooks.started) end
    end)
    handle:SetScript("OnDragStop", function()
        if not moving then return end
        moving = false
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(false) -- the place is kept by us; the game's own memory of it would fight ours
        if hooks.stopped then Core.Safe("window", hooks.stopped) end
    end)
end

-- Puts the grip into that corner of its window: the corner it then drags.
function Window.Corner(grip, corner)
    grip.corner = corner
    grip:ClearAllPoints()
    grip:SetPoint(corner, corner:find("RIGHT") and -grip.insetX or grip.insetX, corner:find("TOP") and -grip.insetY or grip.insetY)
    local mirror = MIRROR[corner]
    for _, texture in ipairs({ grip:GetNormalTexture(), grip:GetHighlightTexture(), grip:GetPushedTexture() }) do
        texture:SetTexCoord(mirror[1], mirror[2], mirror[3], mirror[4])
    end
end

-- The corner across from the dragged one stays where it is while the frame is sized.
local function Hold(frame, corner)
    local right, top = corner:find("RIGHT") ~= nil, corner:find("TOP") ~= nil
    local x = right and frame:GetLeft() or frame:GetRight()
    local y = top and frame:GetBottom() or frame:GetTop()
    frame:ClearAllPoints()
    frame:SetPoint((top and "BOTTOM" or "TOP") .. (right and "LEFT" or "RIGHT"), UIParent, "BOTTOMLEFT", x, y)
end

-- Returns the grip, a button in the frame's lower right corner (Window.Corner moves it).
-- hooks: minWidth, minHeight; usable(); started() before the sizing begins; stopped() it is over;
-- name (a global name for the grip); insetX, insetY from the corner; tip, tipMore: its tooltip.
function Window.Sizer(frame, hooks)
    local sizing
    local grip = CreateFrame("Button", hooks.name, frame)
    grip:SetSize(16, 16)
    grip:SetNormalTexture(GRIP .. "Up")
    grip:SetHighlightTexture(GRIP .. "Highlight")
    grip:SetPushedTexture(GRIP .. "Down")
    grip.insetX, grip.insetY = hooks.insetX or 2, hooks.insetY or 2
    Window.Corner(grip, "BOTTOMRIGHT")

    grip:SetScript("OnMouseDown", function()
        if hooks.usable and not Core.Safe("window", hooks.usable) then return end
        Hold(frame, grip.corner)
        frame:SetResizable(true)
        if frame.SetResizeBounds then
            frame:SetResizeBounds(hooks.minWidth or 1, hooks.minHeight or 1, UIParent:GetWidth(), UIParent:GetHeight())
        end
        if hooks.started then Core.Safe("window", hooks.started) end
        frame:StartSizing(grip.corner)
        sizing = true
    end)
    grip:SetScript("OnMouseUp", function()
        if not sizing then return end
        sizing = false
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(false)
        if hooks.stopped then Core.Safe("window", hooks.stopped) end
    end)
    grip:SetScript("OnEnter", function(self)
        SetCursor("UI_RESIZE_CURSOR")
        if not hooks.tip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(hooks.tip)
        if hooks.tipMore then GameTooltip:AddLine(hooks.tipMore, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function()
        SetCursor(nil)
        if hooks.tip then GameTooltip:Hide() end
    end)
    return grip
end

-------------------------------------------------------------------------------
--  The whole: a window of our own
-------------------------------------------------------------------------------
local methods = {}
local Later -- (below: a window to place once a fight is over)

local function Key(window)
    return window.options.key or "place"
end

-- What is kept, if it can be used: it comes from older versions and from hand edits.
local function Kept(window)
    local place = window.options.store[Key(window)]
    if type(place) == "table" and type(place.x) == "number" and type(place.y) == "number" then return place end
    return nil
end

-- Where the window stands now is kept. zone: the name of the zone it docks to, or nil.
local function Keep(window, zone)
    local frame = window.frame
    local place = { x = frame:GetLeft(), y = frame:GetTop(), dock = zone }
    if window.options.sizable then place.width, place.height = frame:GetWidth(), frame:GetHeight() end
    local was = window.options.store[Key(window)] -- what it was left as stays (Remember)
    if type(was) == "table" then place.full, place.native = was.full, was.native end
    window.options.store[Key(window)] = place
    window:Place()
end

local windows = {} -- every window made by New, in the order they were made (Edit Mode, the registry)

-- Where a window's top left corner stands, from the screen's lower left: docked, where its zone puts it;
-- free, where it was put. nil if that is not known.
local function Corner(window)
    if window.zone then
        local width, height = window.frame:GetSize()
        local left, bottom = Core.Dock.Rect(window.zone, width, height, UIParent:GetWidth(), UIParent:GetHeight(), window.options.insets)
        return left, bottom + height
    end
    if window.spotX then return window.spotX, window.spotY end
    return window.frame:GetLeft(), window.frame:GetTop()
end

-- Whether another shown window of ours has its top left corner at that spot.
local function Taken(window, x, y)
    for _, other in ipairs(windows) do
        if other ~= window and other.frame:IsShown() then
            local left, top = Corner(other)
            if left and top and math.abs(left - x) < 1 and math.abs(top - y) < 1 then return true end
        end
    end
    return false
end

-- A spot clear of the others: the one given, else a step down and to the right of it while another window of
-- ours starts there; nil once that would leave the screen.
local function Clear(window, x, y)
    local width, height = window.frame:GetSize()
    while Taken(window, x, y) do
        x, y = x + Window.CASCADE, y - Window.CASCADE
        if x + width > UIParent:GetWidth() or y - height < 0 then return nil end
    end
    return x, y
end

-- Puts the window where it was left: docked, or at its place; at its first place if it never was moved
-- (docked, with first.dock). One that fills the screen is back in its zone at once. Locked (a fight),
-- once the fight is over.
function methods:Place()
    if self:Locked() then return Later(self) end
    local frame, options = self.frame, self.options
    if self.edge then self.edge:Stop() end
    local place, first = Kept(self), options.first
    if options.sizable then
        local width = place and type(place.width) == "number" and place.width or first.width
        local height = place and type(place.height) == "number" and place.height or first.height
        width, height = math.max(width, options.minWidth or 0), math.max(height, options.minHeight or 0)
        -- No larger than the screen: its size or the UI scale may have changed since it was kept.
        local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
        if screenWidth > 0 and screenHeight > 0 then
            width, height = math.min(width, screenWidth), math.min(height, screenHeight)
        end
        frame:SetSize(width, height)
    end
    local wanted
    if place then wanted = place.dock else wanted = first.dock end
    local name = options.dock and Core.Dock.ZONES[wanted] and wanted or nil
    -- A zone holds one window at a time (Dock.lua): with another shown there, this one stands clear of the
    -- others this time (where it was left, or a step aside: Clear); the zone stays kept for the next.
    local held = name and Core.Dock.Holder(name, frame)
    if held then name = nil end
    local x, y
    if name then
        Core.Dock.Anchor(frame, name, options.insets)
    else
        frame:ClearAllPoints()
        if place then
            x, y = place.x, place.y
        elseif held then
            local width, height = frame:GetSize()
            local left, bottom = Core.Dock.Rect(wanted, width, height, UIParent:GetWidth(), UIParent:GetHeight(), options.insets)
            x, y = left, bottom + height
        end
        if x and held then x, y = Clear(self, x, y) end
        if x then
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
        else
            local point = first.point or "CENTER"
            frame:SetPoint(point, UIParent, point, first.x or 0, first.y or 0)
        end
    end
    self.zone, self.spotX, self.spotY = name, x, y
    Core.Dock.Hold(frame, name)
    local zone = name and Core.Dock.ZONES[name]
    if self.skin then self.skin:Rest() end
    -- The grip is of no use at the screen's edge: there the window cannot be dragged larger.
    if self.grip then
        Window.Corner(self.grip, (zone and zone.bottom and "TOP" or "BOTTOM") .. (zone and zone.right and "LEFT" or "RIGHT"))
    end
    if self.edge then self.edge:Docked(name) end
    self:Refresh()
    if options.docked then Core.Safe("window", options.docked, zone or nil) end
end

-- Its first place and size again; what it was left as (full, native) stays.
function methods:Reset()
    local store, key = self.options.store, Key(self)
    local was = store[key]
    store[key] = type(was) == "table" and (was.full or was.native) and { full = was.full, native = was.native } or nil
    self:Place()
end

-- A window that holds the game's protected frames (secure buttons: a spellbook's spells) is protected
-- itself, and in a fight addon code may not move, size, show or hide it. Then nothing of ours does: a
-- drag or a sizing does not begin, full screen does not change (Edge.lua), and a placing waits for the
-- fight's end (Later).
function methods:Locked()
    return InCombatLockdown() and self.frame:IsProtected() and true or false
end

local waiting = {} -- windows to place once the fight is over
Later = function(window)
    waiting[window] = true
end
Core.On("PLAYER_REGEN_ENABLED", function()
    for window in pairs(waiting) do
        waiting[window] = nil
        Core.Safe("window", window.Place, window)
    end
end)

-- What closing means for the window: its module's (options.close), else it is hidden. One that holds the
-- game's protected frames is not hidden in a fight (Locked): it closes once the fight is over.
local function Close(window)
    if window:Locked() then return Core.AfterCombat(window, Close, window) end
    if window.options.close then window.options.close() else window.frame:Hide() end
end

-- A drag of the box, or a sizing by the grip, is over (also when Edit Mode closes in the middle of it):
-- a dragged window docks where it was let go, a sized one stays in its zone. Once: Edit Mode let go of
-- it, and the game's end of the drag that comes after finds nothing in hand.
local function Moved(window)
    if not window.moving then return end
    window.moving = false
    window.frame:StopMovingOrSizing()
    window.frame:SetUserPlaced(false) -- the place is kept by us
    Keep(window, window.options.dock and Core.Dock.Drop() or nil)
end

local function Sized(window)
    if not window.sizing then return end
    window.sizing = false
    window.frame:StopMovingOrSizing()
    window.frame:SetUserPlaced(false)
    Keep(window, window.zone)
end

-- The box over the window in Edit Mode, made when Edit Mode first opens: Edit Mode's blue frame, a
-- brighter copy and the window's title while the mouse is on it, and the handle it is dragged by.
-- Without the game's nine-slice code the box is still there to drag, only not to see.
local function Box(window)
    if window.box then return window.box end
    local frame, options = window.frame, window.options
    local nineSlice = rawget(_G, "NineSliceUtil")
    local box = CreateFrame("Frame", nil, frame)
    box:SetAllPoints()
    box:SetFrameLevel(frame:GetFrameLevel() + Window.BOX_LEVEL)
    if nineSlice then Core.Safe("Edit Mode", nineSlice.ApplyLayout, box, SELECTION, HIGHLIGHT) end
    local hover = CreateFrame("Frame", nil, box)
    hover:SetAllPoints()
    hover:SetAlpha(HOVER)
    if nineSlice then Core.Safe("Edit Mode", nineSlice.ApplyLayout, hover, SELECTION, HIGHLIGHT) end
    for name in pairs(SELECTION) do
        local piece = rawget(hover, name)
        if piece then piece:SetBlendMode("ADD") end
    end
    hover:Hide()
    local title = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("CENTER")
    title:SetText(options.title or "")
    title:Hide()
    box:SetScript("OnEnter", function()
        hover:Show()
        title:Show()
    end)
    box:SetScript("OnLeave", function()
        hover:Hide()
        title:Hide()
    end)
    Window.Mover(box, frame, {
        usable = window.usable,
        started = function()
            window.moving = true
            if options.dock then Core.Dock.Watch(frame, nil, options.insets) end
        end,
        stopped = function() Moved(window) end,
    })
    window.box = box
    return box
end

-- The button that swaps a window for the game's own one, or back: the game's square button with its
-- circling arrows, a tip to say which way.
local function Toggle(parent, text, tip, click)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(Window.BUTTON, Window.BUTTON)
    button:SetNormalTexture(SQUARE .. "Up")
    button:SetPushedTexture(SQUARE .. "Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local arrows = button:CreateTexture(nil, "ARTWORK", nil, 5)
    arrows:SetTexture(ARROWS)
    arrows:SetSize(Window.BUTTON / 2, Window.BUTTON / 2)
    arrows:SetPoint("CENTER", -1, 0)
    button:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        Core.Safe("window", click)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(text)
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- Full screen (on) or back, by the button: as the edge does it; the button then shows what it is now.
local function Full(window, on)
    window.edge:Fill(on)
    window:Refresh()
end

-- What is typed into the search box goes to the module, on every change ("" once it is empty again).
local function Searched(window, text)
    if window.options.search then Core.Safe("window", window.options.search, text) end
end

-- The search box open over the title bar (on), the cursor in it; or closed: emptied (told), the title back.
local function Search(window, on)
    local bar = window.bar
    if on and not window.options.search then return end
    bar.box:SetShown(on)
    bar.find:SetShown(not on)
    if on then
        bar.box:SetFocus()
    else
        if bar.box:GetText() ~= "" then bar.box:SetText("") end -- OnTextChanged tells the module
        bar.box:ClearFocus()
    end
end

-- The title bar, made when it is first shown: across the window's top, Window.BAR high, above what the
-- window holds, a thin bronze line under it. At its left the search's magnifier (with search) and the
-- window's title: a click there opens the search box (the game's), which then lies over the whole bar but
-- what stands at its right; there the buttons. A drag anywhere on the bar, its title too, moves the window
-- where it may be moved (Draggable): a press that was a drag opens no search.
local function Bar(window)
    if window.bar then return window.bar end
    local frame, options = window.frame, window.options
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(Window.BAR)
    bar:SetFrameLevel(frame:GetFrameLevel() + Window.BAR_LEVEL)
    local line = bar:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.5)
    line:SetPoint("BOTTOMLEFT", Window.BUTTON_INSET, 0)
    line:SetPoint("BOTTOMRIGHT", -Window.BUTTON_INSET, 0)
    line:SetHeight(1)

    local find = CreateFrame("Button", nil, bar)
    find:SetPoint("TOPLEFT")
    find:SetPoint("BOTTOMLEFT")
    local glass = find:CreateTexture(nil, "ARTWORK")
    glass:SetAtlas("common-search-magnifyingglass") -- the game's search box's
    glass:SetSize(Window.GLASS, Window.GLASS)
    glass:SetPoint("LEFT", Window.TEXT_INSET, 0)
    glass:SetShown(options.search ~= nil)
    local title = find:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    if options.search then title:SetPoint("LEFT", glass, "RIGHT", 4, 0) else title:SetPoint("LEFT", Window.TEXT_INSET, 0) end
    title:SetText(options.title or "")
    find:SetWidth(Window.TEXT_INSET * 2 + (options.search and Window.GLASS + 4 or 0) + math.max(title:GetStringWidth() or 0, 40))
    find:SetScript("OnMouseDown", function() find.dragged = false end)
    find:SetScript("OnClick", function()
        if not find.dragged then Core.Safe("window", Search, window, true) end
    end)

    local box = CreateFrame("EditBox", nil, bar, "SearchBoxTemplate")
    box:SetHeight(Window.BOX)
    box:Hide()
    box:HookScript("OnTextChanged", function(self) Searched(window, self:GetText()) end)
    box:HookScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then Core.Safe("window", Search, window, false) end
    end)
    box:HookScript("OnEscapePressed", function() Core.Safe("window", Search, window, false) end)
    bar.find, bar.title, bar.glass, bar.box = find, title, glass, box

    Window.Mover(bar, frame, {
        usable = function() return window:Draggable() end,
        started = function()
            window.moving = true
            -- Outside Edit Mode a drag docks only where a screen edge is not (the middle), or not at all.
            if options.dock then Core.Dock.Watch(frame, not options.dragDocked and Window.DRAG_ZONES or nil, options.insets) end
        end,
        stopped = function() Moved(window) end,
    })
    find:RegisterForDrag("LeftButton")
    find:SetScript("OnDragStart", function()
        find.dragged = true
        bar:GetScript("OnDragStart")(bar)
    end)
    find:SetScript("OnDragStop", function() bar:GetScript("OnDragStop")(bar) end)
    window.bar = bar
    return bar
end

-- The buttons at the title bar's right, made with it: from the right, close, full screen (with edge), the
-- game's own window (with native).
local function Buttons(window)
    if window.buttons then return window.buttons end
    local frame, options = window.frame, window.options
    local buttons = CreateFrame("Frame", nil, Bar(window))
    buttons:SetPoint("RIGHT", window.bar, "RIGHT", -Window.BUTTON_INSET, 0)
    buttons:SetSize(Window.BUTTON, Window.BUTTON)
    local close = CreateFrame("Button", nil, buttons, "UIPanelCloseButtonNoScripts")
    close:SetScript("OnClick", function() Core.Safe("window", Close, window) end)
    buttons.list = { close }
    if window.edge then
        local full = CreateFrame("Frame", nil, buttons, "MaximizeMinimizeButtonFrameTemplate")
        full:SetOnMaximizedCallback(function() Core.Safe("window", Full, window, true) end)
        full:SetOnMinimizedCallback(function() Core.Safe("window", Full, window, false) end)
        window.full = full
        buttons.list[2] = full
    end
    if options.native then
        window.toggle = Toggle(buttons, Window.TEXT.classic, Window.TEXT.classicTip, function() window:Native(true) end)
        buttons.list[#buttons.list + 1] = window.toggle
    end
    window.buttons = buttons
    return buttons
end

-- The title bar as the window is now: there with titleBar (a kind of window that has one; the chat, small,
-- has none), and on every window while it fills the screen, at the top of it. Its buttons not in Edit Mode;
-- full screen only while the window may fill the screen, offering what it does not do now; side by side
-- from the right (buttons.first: the leftmost). The search box ends left of them, or of Edge's dropdown
-- Classic windows there. A bar that goes closes its search.
function methods:Refresh()
    local edge = self.edge
    local shown = (self.options.titleBar or (edge and edge.full)) and true or false
    if not shown and not self.bar then return end
    local bar, buttons = Bar(self), Buttons(self)
    if not shown and bar.box:IsShown() then Search(self, false) end
    bar:SetShown(shown)
    buttons:SetShown(not Core.EditMode.active)
    local full = self.full
    if full then
        full:SetShown(edge.settings.expand and not edge.off and true or false)
        if edge.full then full:Maximize(true, true) else full:Minimize(true, true) end
    end
    local right
    for _, button in ipairs(buttons.list) do
        if button:IsShown() then
            button:ClearAllPoints()
            if right then button:SetPoint("RIGHT", right, "LEFT") else button:SetPoint("RIGHT") end
            right = button
        end
    end
    buttons.first = right
    local menu = edge and edge.classic
    local stop = menu and menu:IsShown() and menu or right
    bar.box:ClearAllPoints()
    bar.box:SetPoint("LEFT", Window.TEXT_INSET + Window.BOX_INSET, 0)
    if stop then bar.box:SetPoint("RIGHT", stop, "LEFT", -Window.BOX_INSET, 0) else bar.box:SetPoint("RIGHT", -Window.BOX_INSET, 0) end
end

-- May the title bar move the window now: only a kind of window with a title bar of its own, not in Edit
-- Mode (there its box does), not while it fills the screen or is on its way, and, docked at a screen edge,
-- only if it says so (dragDocked): an edge is Edit Mode's.
function methods:Draggable()
    if not self.options.titleBar or Core.EditMode.active or (self.edge and self.edge.away) or self:Locked() then return false end
    local zone = self.zone
    if zone and not Window.DRAG_ZONES[zone] and not self.options.dragDocked then return false end
    return not self.options.usable or self.options.usable()
end

-- What the window was left as, kept with its place in the module's settings: full (it filled the screen),
-- native (the game's own window was chosen instead). Open acts on both.
function methods:Remember(what, value)
    local store, key = self.options.store, Key(self)
    local place = type(store[key]) == "table" and store[key] or {}
    place[what] = value or nil
    store[key] = place
end

-- The game's own window instead of ours (on), or ours again: what the toggle buttons do, kept for Open.
function methods:Native(on)
    local native = self.options.native
    if not native then return end
    self:Remember("native", on)
    if on then native.show() else native.back() end
end

-- The game asks for the window (its key, an NPC, a link): the game's own if that was chosen last
-- (native.show), else ours, shown, filling the screen again if it was left so. Returns "native" or
-- "ours"; "locked" if ours may not be shown now (Locked): then the module lets the game's own show.
function methods:Open()
    if self:Locked() and not self.frame:IsShown() then return "locked" end
    local place = self.options.store[Key(self)]
    local left = type(place) == "table" and place or {}
    if left.native and self.options.native then
        self.options.native.show()
        return "native"
    end
    self.frame:Show()
    if left.full and self.edge and not self.edge.full then self.edge:Fill(true) end
    return "ours"
end

-- The game's own windows with our button on them, and that button: kept in our table, nothing written
-- into theirs. Blizzard's close button is read where its template puts it, or by its name.
local attached = setmetatable({}, { __mode = "k" })

function methods:Attach()
    local native = self.options.native
    local game = native and native.frame
    if type(game) == "function" then game = game() end
    if type(game) ~= "table" or type(game.GetObjectType) ~= "function" then return nil end
    if attached[game] then return attached[game] end
    local name = game:GetName()
    local close = rawget(game, "CloseButton")
    if type(close) ~= "table" then close = name and rawget(_G, name .. "CloseButton") end
    if type(close) ~= "table" or type(close.GetFrameLevel) ~= "function" then close = nil end
    local button = Toggle(game, Window.TEXT.sane, Window.TEXT.saneTip, function() self:Native(false) end)
    if native.anchor then
        native.anchor(button)
    elseif close then
        button:SetPoint("RIGHT", close, "LEFT")
        button:SetFrameLevel(close:GetFrameLevel())
    else
        button:SetPoint("TOPRIGHT", -Window.BUTTON - Window.BUTTON_INSET, -Window.BUTTON_INSET)
    end
    attached[game] = button
    return button
end

-- Edit Mode opened (on) or closed: the box and the grip are there only then, the buttons only not. A
-- window that fills the screen is back in its zone first, to be arranged; one in hand when it closes is
-- let go.
local function Edit(window, on)
    if on and window.edge and window.edge.away then window:Place() end
    if not on and window.moving then Moved(window) end
    if not on and window.sizing then Sized(window) end
    local box = on and Box(window) or window.box
    if box then box:SetShown(on) end
    if window.grip then window.grip:SetShown(on) end
    window:Refresh()
end

Core.EditMode.Watch(function(on)
    for _, window in ipairs(windows) do Core.Safe("Edit Mode", Edit, window, on) end
end)

function Window.New(frame, options)
    local kind = Window.KINDS[options.kind]
    if kind then
        for name, value in pairs(kind) do
            if options[name] == nil then
                options[name] = Core.Copy(value)
            elseif type(value) == "table" and type(options[name]) == "table" then
                -- The module's own (its first place), with the kind's for what it leaves out.
                local own = Core.Copy(options[name])
                for key, given in pairs(value) do
                    if own[key] == nil then own[key] = given end
                end
                options[name] = own
            end
        end
    end
    options.first = options.first or {}
    local window = setmetatable({ frame = frame, options = options }, { __index = methods })
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    if options.skin then
        window.skin = Core.Skin.New(frame, options.corners or type(options.edge) == "table" and options.edge or nil)
    end
    if options.edge then window.edge = Core.Edge.New(window) end
    -- Only in Edit Mode, and not while it fills the screen or is on its way, nor in a fight (Locked).
    function window.usable()
        if not Core.EditMode.active or (window.edge and window.edge.away) or window:Locked() then return false end
        return not options.usable or options.usable()
    end
    if options.sizable then
        frame:SetResizable(true)
        if frame.SetResizeBounds then frame:SetResizeBounds(options.minWidth or 1, options.minHeight or 1) end
        window.grip = Window.Sizer(frame, {
            minWidth = options.minWidth, minHeight = options.minHeight, usable = window.usable,
            started = function() window.sizing = true end,
            -- A docked window stays docked: it hangs on its zone again at its new size.
            stopped = function() Sized(window) end,
        })
        window.grip:SetFrameLevel(frame:GetFrameLevel() + Window.BOX_LEVEL + 1) -- over the box
        window.grip:Hide()
    end
    windows[#windows + 1] = window
    -- Shown again in a zone another window holds now (it came first): it stands free this time.
    frame:HookScript("OnShow", function()
        if window.zone and Core.Dock.Holder(window.zone, frame) then Core.Safe("window", window.Place, window) end
    end)
    if Core.EditMode.active then Edit(window, true) end
    Core.Safe("window", window.Attach, window)
    -- Esc closes a window made with escape = "close" while it is shown, as the game closes its panels
    -- (Core.Escape): full as it is. A module that closes it later (the talk ends on the game's side
    -- first) leaves it shown, and Esc is still its next time.
    if options.escape == "close" then
        frame:HookScript("OnShow", function() Core.Escape(window, Close) end)
        frame:HookScript("OnHide", function() Core.Escape(window, nil) end)
        if frame:IsShown() then Core.Escape(window, Close) end
    end
    return window
end
