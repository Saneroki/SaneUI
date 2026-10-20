local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Board
--  The full screen's panels: your talents at the left, your spellbook at the
--  right, side by side, each as wide as its share of what both hold wants
--  (Board.Layout). What a panel holds is a window that is not ours, seated in
--  it while the full screen stands (Core.Seat: its place, scale and layer lent,
--  given back when the full screen goes); the window itself works as always.
--
--      Talents    the window of a talent planner Sane UI knows (Core.Neighbours),
--                 while that addon is installed: it opens with the full screen
--                 and closes when it goes. Without it, the game's own window
--                 while it shows your talents.
--      Spellbook  the game's own window (its talents and spellbook are one
--                 window, PlayerSpellsFrame, that shows one of them at a time):
--                 here while it shows your spellbook, or whatever it shows
--                 while the planner holds the Talents panel.
--
--  The game's window is never opened or closed by our code: its OnShow and
--  OnHide touch the action bars, whose buttons are protected (Doc/guides/
--  windows.md, Taint). The game opens it, by its keys, its micro menu buttons,
--  a link, or the open button of an empty panel: a secure button of the
--  game's (SecureActionButtonTemplate) that clicks the game's own micro menu
--  button, so the game's code opens it as its own. That button is a frame of
--  its own on UIParent, not in our window (which would be locked in a fight
--  with it): made, shown, placed and hidden out of a fight only, hidden as a
--  fight begins and back after it. Going back from the full screen gives the
--  game's window back to its own place, still open (Esc closes it with the
--  full screen; the bottom edge leaves it to you).
--
--  Whatever opens the game's window or the planner (its key, a micro menu
--  button, its own command) fills the screen with the window too, and each
--  stands in its panel there. A panel whose window is closed shows a plate in
--  Sane UI's look with its title, what opens it, and the open button.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board = {}
ns.Board = Board

Board.MARGIN, Board.GAP = 24, 24 -- room kept round the panels and between them, UI units
Board.LEVEL = 30                 -- how far above the full window what is seated stands
Board.RADIUS = 8                 -- an empty panel's plate's corners
Board.BUTTON_WIDTH, Board.BUTTON_HEIGHT = 140, 26
-- An empty panel is as large as the game's window would be there (Blizzard_PlayerSpells, Camelot:
-- talentsWidth and talentsHeight, spellBookMinimizedWidth and spellBookHeight).
Board.TALENTS = { 1218, 708 }
Board.SPELLBOOK = { 809, 720 }

-- The panels, left to right: the game's key binding that opens what each holds, and its micro menu button.
Board.PANELS = {
    { key = "talents", title = ns.TEXT.talents, binding = "TOGGLETALENTS", micro = "TalentMicroButton", size = Board.TALENTS },
    { key = "spellbook", title = ns.TEXT.spellbook, binding = "TOGGLESPELLBOOK", micro = "SpellbookMicroButton", size = Board.SPELLBOOK },
}

local room     -- while the window is full: { left, top, width, height } in UIParent's units, inside, strata, level
local standing -- the full window stands (not on its way): the open buttons may show
local fighting -- a fight is on, from the moment the game says it begins
local panels = {}  -- [key] = our plate for an empty panel, made when first needed
local buttons = {} -- [key] = its open button (secure), made out of a fight when first needed
local seats = {}   -- [frame] = its seat (Core.Seat)
local Reboard      -- below

-------------------------------------------------------------------------------
--  What the panels hold
-------------------------------------------------------------------------------
-- The game's window of talents and spellbook, once its addon is loaded (the game loads it when first wanted).
local function Game()
    local frame = rawget(_G, "PlayerSpellsFrame")
    if type(frame) == "table" and type(frame.IsShown) == "function" then return frame end
end

-- The talent planner, while an addon Sane UI knows for it is loaded.
local function Planner()
    return Core.Neighbours.Window("talents")
end

-- The open windows each panel holds now: [key] = frame.
local function Holds()
    local holds, planner, game = {}, Planner(), Game()
    if planner and planner:Shown() then holds.talents = planner:Frame() end
    if game and game:IsShown() then
        local book = game.SpellBookFrame
        local spellbook = planner or (type(book) == "table" and book:IsShown())
        holds[spellbook and "spellbook" or "talents"] = game
    end
    return holds
end

local function SeatOf(frame)
    local seat = seats[frame]
    if not seat then
        seat = Core.Seat.New(frame, { label = "Combat: seat", sized = function() Reboard() end, gone = function() Reboard() end })
        seats[frame] = seat
    end
    return seat
end

-------------------------------------------------------------------------------
--  Layout
-------------------------------------------------------------------------------
-- The panels' rooms in the full window's room (left, top from UIParent's bottom left, width, height): side by
-- side, each as wide as its share of what both want ([key] = { width, height }), the margin round them and the
-- gap between them. [key] = { left, top, width, height }.
function Board.Layout(left, top, width, height, wants)
    local free = math.max(width - 2 * Board.MARGIN - Board.GAP, 2)
    local first = wants.talents[1] / (wants.talents[1] + wants.spellbook[1])
    local talents = math.floor(free * first + 0.5)
    local high = math.max(height - 2 * Board.MARGIN, 1)
    return {
        talents = { left + Board.MARGIN, top - Board.MARGIN, talents, high },
        spellbook = { left + Board.MARGIN + talents + Board.GAP, top - Board.MARGIN, free - talents, high },
    }
end

-- A size of width x height in a room: as large as fits and never larger than it is, in the room's middle.
function Board.Fit(width, height, rect)
    local scale = math.min(rect[3] / width, rect[4] / height, 1)
    local w, h = width * scale, height * scale
    return rect[1] + (rect[3] - w) / 2, rect[2] - (rect[4] - h) / 2, w, h
end

-------------------------------------------------------------------------------
--  An empty panel
-------------------------------------------------------------------------------
-- The game's words for the key that opens it, or ours without one.
local function KeyText(binding)
    local key = Core.Ask(rawget(_G, "GetBindingKey"), binding)
    local text = key and Core.Ask(rawget(_G, "GetBindingText"), key)
    return text or key or ns.TEXT.noKey
end

local function Plate(spec)
    local panel = panels[spec.key]
    if panel then return panel end
    panel = CreateFrame("Frame", nil, room.inside)
    panel.skin = Core.Skin.New(panel, { radius = Board.RADIUS })
    panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    panel.title:SetPoint("TOP", 0, -24)
    panel.title:SetText(spec.title)
    panel.hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    panel.hint:SetPoint("LEFT", 24, 16)
    panel.hint:SetPoint("RIGHT", -24, 16)
    panel.hint:SetWordWrap(true)
    panels[spec.key] = panel
    return panel
end

-- The planner's open button: ours, it opens the planner by its own function.
local function PlannerButton(panel)
    if panel.open then return panel.open end
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(Board.BUTTON_WIDTH, Board.BUTTON_HEIGHT)
    button:SetPoint("TOP", panel.hint, "BOTTOM", 0, -16)
    button:SetText(ns.TEXT.open)
    button:SetScript("OnClick", ns.Guard(function()
        local planner = Planner()
        if planner then planner:Open() end
    end))
    panel.open = button
    return button
end

-- The open button of the game's window in that panel: a secure click on the game's own micro menu button.
-- Made out of a fight only; nil in one, or without that button.
local function Secure(spec)
    if buttons[spec.key] then return buttons[spec.key] end
    local micro = rawget(_G, spec.micro)
    if InCombatLockdown() or type(micro) ~= "table" then return nil end
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    button:SetSize(Board.BUTTON_WIDTH, Board.BUTTON_HEIGHT)
    button:SetFrameStrata("DIALOG") -- above the full window (HIGH)
    button:SetText(ns.TEXT.open)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("type", "click")
    button:SetAttribute("clickbutton", micro)
    button:SetAttribute("useOnKeyDown", false)
    button:Hide()
    buttons[spec.key] = button
    return button
end

-- The open buttons out of sight: as a fight begins, when the full screen goes, when their panel fills.
local function Hide(key)
    if InCombatLockdown() then return end
    for each, button in pairs(buttons) do
        if not key or each == key then button:Hide() end
    end
end

-- A panel with nothing in it at its room (rect), or none (nil): the plate, as large as its window would be.
local function Empty(spec, rect, planner)
    local panel = panels[spec.key]
    if not rect then
        if panel then panel:Hide() end
        Hide(spec.key)
        return
    end
    panel = Plate(spec)
    local left, top, width, height = Board.Fit(spec.size[1], spec.size[2], rect)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", room.inside, "TOPLEFT", left - room[1], top - room[2])
    panel:SetSize(width, height)
    panel:Show()
    panel.skin:Rest()
    local fight = fighting or InCombatLockdown()
    if planner then
        panel.hint:SetText(ns.TEXT.hintPlanner)
        PlannerButton(panel):Show()
        return
    end
    if panel.open then panel.open:Hide() end
    local button = not fight and Secure(spec)
    local words = button and ns.TEXT.hint or fight and ns.TEXT.hintFight or ns.TEXT.hintKey
    panel.hint:SetText(words:format(KeyText(spec.binding)))
    if not button then return end
    if not standing then return button:Hide() end
    -- Under the hint, in UIParent's units: the button stands on UIParent, not in our window.
    button:ClearAllPoints()
    button:SetPoint("TOP", UIParent, "BOTTOMLEFT", left + width / 2, top - height / 2 - 24)
    button:Show()
end

-------------------------------------------------------------------------------
--  The full screen
-------------------------------------------------------------------------------
-- Each panel at its room: what it holds seated there, or its plate.
local function Lay()
    if not room then return end
    local holds, planner = Holds(), Planner()
    local wants = {}
    for _, spec in ipairs(Board.PANELS) do
        local frame = holds[spec.key]
        local width, height = 0, 0
        if frame then width, height = SeatOf(frame):Size() end
        wants[spec.key] = (width > 0 and height > 0) and { width, height } or spec.size
    end
    local rects = Board.Layout(room[1], room[2], room[3], room[4], wants)
    -- A window seated before that no panel holds now (closed, or the game's in the other panel: seated anew).
    for frame, seat in pairs(seats) do
        if seat.held and frame ~= holds.talents and frame ~= holds.spellbook then seat:Free() end
    end
    for _, spec in ipairs(Board.PANELS) do
        local rect, frame = rects[spec.key], holds[spec.key]
        local seated = frame and SeatOf(frame):Hold(rect[1], rect[2], rect[3], rect[4], room.strata, room.level + Board.LEVEL)
        Empty(spec, not seated and rect or nil, spec.key == "talents" and planner)
    end
end

-- The window fills the screen, or is on its way there (moving: not standing yet): what the window holds
-- (inside) under its title bar, on that layer, is the room left, top (from UIParent's bottom left), width,
-- height. Coming to the full screen, the planner comes with it.
function Board.Show(inside, strata, level, left, top, width, height, moving)
    local coming = not room
    room = room or {}
    room.inside, room.strata, room.level = inside, strata, level
    room[1], room[2], room[3], room[4] = left, top, width, height
    standing = not moving
    if coming then
        local planner = Planner()
        if planner then
            Board.Watch(planner)
            if not planner:Shown() then planner:Open() end
        end
    end
    Lay()
end

-- The window goes back to its size, or is there: each window seated is given back (the game's stays open, at
-- its own place), the planner closes, the plates and the open buttons go.
function Board.Hide()
    if not room then return end
    room, standing = nil, false
    for _, seat in pairs(seats) do seat:Free() end
    for _, panel in pairs(panels) do panel:Hide() end
    Hide()
    local planner = Planner()
    if planner and planner:Shown() then planner:Close() end
end

-- The module stood down (GiveBack): all given back; the open buttons hidden now or once the fight is over.
function Board.Leave()
    Board.Hide()
    Core.AfterCombat("Combat: open buttons", Hide)
end

Reboard = Core.Later(function() ns.Guarded(Lay) end)

-- A window that belongs on the board opened (the game's, by any way; the planner, by any way): the full
-- screen comes with it, or, full already, it takes its panel. Not in Edit Mode (Edge.lua says no there).
local function Opened()
    if ns.Window.Full() then return Reboard() end
    ns.Window.Fill()
end

-- A fight begins (the game says so before it locks protected frames): the open buttons go now; the panels
-- say what opens them meanwhile. It ends: the buttons come back.
local function Fight()
    fighting = true
    Hide()
    if room then Reboard() end
end

local function Peace()
    fighting = false
    if room then Reboard() end
end

-- Hooks after the game's window opening and after its tabs changing (another panel, another size), once its
-- addon is loaded.
local hooked
local function Hook()
    local game = Game()
    if hooked or not game then return end
    hooked = true
    game:HookScript("OnShow", ns.Guard(Opened))
    for _, key in ipairs({ "SpecFrame", "TalentsFrame", "SpellBookFrame" }) do
        local view = game[key]
        if type(view) == "table" and type(view.HookScript) == "function" then
            view:HookScript("OnShow", ns.Guard(function() if room then Reboard() end end))
        end
    end
end

-- The planner's opening followed (once; Neighbours.lua).
local opening = ns.Guard(function() Opened() end)
function Board.Watch(planner)
    planner:Follow(opening)
end

-- At login: the game's window and the planner followed, and the fights.
function Board.Follow()
    local planner = Planner()
    if planner then Board.Watch(planner) end
    local util = rawget(_G, "EventUtil")
    if util and util.ContinueOnAddOnLoaded then
        util.ContinueOnAddOnLoaded("Blizzard_PlayerSpells", ns.Guard(Hook))
    else
        Hook()
    end
    ns.On("PLAYER_REGEN_DISABLED", function() if not ns.off then Fight() end end)
    ns.On("PLAYER_REGEN_ENABLED", function() if not ns.off then Peace() end end)
end
