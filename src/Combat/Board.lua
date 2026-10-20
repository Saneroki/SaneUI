local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Board
--  The full screen's windows, while the window stands full: on Core's board
--  (Core.Board), so they share the screen as you arrange them, in layouts
--  behind tabs in the full window's title bar (drag a window's head to move
--  it, the gap between two to share their room anew, its X to take it off;
--  the dropdown Windows adds one). Combat's windows:
--      talents    the window of a talent planner Sane UI knows (Core.Neighbours),
--                 while that addon is installed: it opens with the full screen
--                 and closes when it goes. Without it, the game's own window
--                 while it shows your talents.
--      spellbook  the game's own window (its talents and spellbook are one
--                 window, PlayerSpellsFrame, that shows one of them at a time):
--                 here while it shows your spellbook, or whatever it shows
--                 while the planner holds the Talents panel.
--  The first layout has them side by side, each as wide as its share of what
--  both hold wants (the window in it at its own size, else the game's size
--  for it), laid out anew as that changes, until you change the layout.
--
--  A panel is Core's (a plate, a head with its title and the X, the body).
--  What is in its body is a window that is not ours, seated there (Core.Seat:
--  its place, scale and layer lent; given back when it closes or the full
--  screen goes); the window itself works as always. With its own panel taken
--  off the layout, a window stands in the other panel while that has nothing
--  of its own, else in the middle of the whole board: an open window is never
--  left behind the full screen.
--
--  The game's window is opened by the game only, never by our code. Its OnShow
--  and OnHide run the game's panel manager and show the action bars' grids
--  (their buttons are protected), and its spellbook's OnShow writes which spell
--  each entry casts: run from our code, all of that would be written tainted,
--  and the game's own later opening and closing, the grids, and a spell clicked
--  in the spellbook would be refused in a fight (Doc/guides/addon-standards.md,
--  Taint). So whatever opens it (its keys, its micro menu buttons, a link)
--  brings the full screen and seats it there, and an empty panel opens it with
--  one click: its body is a secure button of the game's
--  (SecureActionButtonTemplate) that clicks the game's own micro menu button,
--  so the game's code opens the window as its own. That button is a frame of
--  its own on UIParent over the panel's body, not in our window (which would be
--  locked in a fight with it): made, placed, shown and hidden out of a fight
--  only, hidden as a fight begins and back after it; meanwhile the panel says
--  the key. Going back from the full screen gives the game's window back to
--  its own place, still open (Esc closes it with the full screen; the bottom
--  edge leaves it to you).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board = {}
ns.Board = Board

Board.LEVEL = 30   -- how far above what the full window holds a seated window and a click stand (over Core's panels)
Board.LEAST = 0.4  -- a panel's least width and height: that share of the game's window there
Board.LIGHT = 0.08 -- how strongly an empty panel's body lights up under the mouse
Board.INSET = 24   -- the words of an empty panel from its body's sides
-- The game's window's size for each (Blizzard_PlayerSpells, Camelot: talentsWidth and talentsHeight,
-- spellBookMinimizedWidth and spellBookHeight): an empty panel's share in the first layout.
Board.TALENTS = { 1218, 708 }
Board.SPELLBOOK = { 809, 720 }

-- The panels, left to right in the first layout: the game's key binding that opens what each holds, and its
-- micro menu button.
Board.PANELS = {
    { key = "talents", title = ns.TEXT.talents, binding = "TOGGLETALENTS", micro = "TalentMicroButton", size = Board.TALENTS },
    { key = "spellbook", title = ns.TEXT.spellbook, binding = "TOGGLESPELLBOOK", micro = "SpellbookMicroButton", size = Board.SPELLBOOK },
}

local layouts      -- Core's board, once the window is there (Board.Take)
local inside       -- what the full window holds, while it stands full
local wide, high   -- its size then
local rects = {}   -- where each panel stands now (Core's board's: from inside's top left, down)
local fighting     -- a fight is on, from the moment the game says it begins
local buttons = {} -- [key] = the click of an empty panel of the game's window (secure), made out of a fight
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

-- The open windows and the panel each belongs in: [key] = frame.
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

-- What each panel would be as wide as: the window it holds at its own size, else the game's size for it.
local function Wants(holds)
    local wants = {}
    for _, spec in ipairs(Board.PANELS) do
        local frame = holds[spec.key]
        local width, height = 0, 0
        if frame then width, height = SeatOf(frame):Size() end
        wants[spec.key] = (width > 0 and height > 0) and { width, height } or spec.size
    end
    return wants
end

-- The first layout: the talents at the left, the spellbook at the right, each as wide as its share of what both want.
local function Default()
    local wants = Wants(Holds())
    return { split = "x", parts = { { key = "talents" }, { key = "spellbook" } },
             shares = { wants.talents[1], wants.spellbook[1] } }
end

-------------------------------------------------------------------------------
--  Where things stand
-------------------------------------------------------------------------------
-- A panel's body (rect: the panel, as Core's board lays it out), less the room round what is in it.
local function Body(rect)
    local head, edge = Core.Board.HEAD, Core.Board.EDGE
    return { rect[1] + edge, rect[2] + head + edge, math.max(rect[3] - 2 * edge, 1), math.max(rect[4] - head - 2 * edge, 1) }
end

-- A rect of the board in UIParent's units: left and top from its bottom left corner, width, height. Nothing while
-- what the window holds has no place yet.
local function Screen(rect)
    local left, top = inside:GetLeft(), inside:GetTop()
    if not (left and top) then return nil end
    local ratio = inside:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return (left + rect[1]) * ratio, (top - rect[2]) * ratio, rect[3] * ratio, rect[4] * ratio
end

-------------------------------------------------------------------------------
--  An empty panel
-------------------------------------------------------------------------------
-- What an empty panel says, in its body; made with the panel (Core's board: build).
local function Build(panel)
    local hint = panel.body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("LEFT", Board.INSET, 0)
    hint:SetPoint("RIGHT", -Board.INSET, 0)
    hint:SetWordWrap(true)
    hint:Hide()
    panel.hint = hint
end

-- A click area lights up under the mouse.
local function Light(button)
    local light = button:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], Board.LIGHT)
end

-- The game's words for the key that opens it; nil without one.
local function KeyText(binding)
    local key = Core.Ask(rawget(_G, "GetBindingKey"), binding)
    return key and (Core.Ask(rawget(_G, "GetBindingText"), key) or key) or nil
end

-- The planner's click: ours, over the panel's body; it opens the planner by its own function.
local function PlannerClick(panel)
    if panel.open then return panel.open end
    local button = CreateFrame("Button", nil, panel.body)
    button:SetAllPoints()
    button:SetScript("OnClick", ns.Guard(function()
        local planner = Planner()
        if planner then planner:Open() end
    end))
    Light(button)
    panel.open = button
    return button
end

-- The click of an empty panel of the game's window: a secure click on the game's own micro menu button. Made
-- out of a fight only; nil in one, or without that button.
local function Secure(spec)
    if buttons[spec.key] then return buttons[spec.key] end
    local micro = rawget(_G, spec.micro)
    if InCombatLockdown() or type(micro) ~= "table" then return nil end
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("type", "click")
    button:SetAttribute("clickbutton", micro)
    button:SetAttribute("useOnKeyDown", false)
    Light(button)
    button:Hide()
    buttons[spec.key] = button
    return button
end

-- The clicks out of sight: as a fight begins, when the full screen goes, when their panel fills.
local function Hide(key)
    if InCombatLockdown() then return end
    for each, button in pairs(buttons) do
        if not key or each == key then button:Hide() end
    end
end

-- What an empty panel of the game's window says (other: the game's window is open in the other panel), and
-- whether a click opens it now (not in a fight; not while the game has it closed to you, its micro menu button
-- off until a level).
local function Words(spec, other)
    local micro = rawget(_G, spec.micro)
    if type(micro) == "table" and Core.Ask(micro.IsEnabled, micro) == false then
        local level = tonumber(rawget(micro, "minLevel"))
        return level and ns.TEXT.later:format(level) or ns.TEXT.notYet, false
    end
    local key, fight = KeyText(spec.binding), fighting or InCombatLockdown()
    local words
    if fight then
        words = key and ns.TEXT.fight:format(key) or ns.TEXT.fightNoKey
    else
        words = key and ns.TEXT.click:format(key) or ns.TEXT.clickNoKey
    end
    if other then words = ns.TEXT.one .. "\n\n" .. words end
    return words, not fight
end

-- A panel's body with nothing in it (body), or none (nil: the panel holds a window, or is not laid out): what
-- opens it there, and the click on it. planner: the panel is the planner's; other: as Words.
local function Empty(spec, body, planner, other)
    local panel = layouts.panels[spec.key]
    if not body then
        if panel and panel.hint then panel.hint:Hide() end
        if panel and panel.open then panel.open:Hide() end
        Hide(spec.key)
        return
    end
    if not (panel and panel.hint) then return end
    if planner then
        panel.hint:SetText(ns.TEXT.planner)
        panel.hint:Show()
        PlannerClick(panel):Show()
        Hide(spec.key)
        return
    end
    if panel.open then panel.open:Hide() end
    local words, click = Words(spec, other)
    panel.hint:SetText(words)
    panel.hint:Show()
    local button = click and Secure(spec)
    if not button then return Hide(spec.key) end
    local left, top, width, height = Screen(body)
    if not left then return button:Hide() end
    -- Over the body, in UIParent's units: the button stands on UIParent, not in our window.
    button:SetFrameStrata(inside:GetFrameStrata())
    button:SetFrameLevel(inside:GetFrameLevel() + Board.LEVEL)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    button:SetSize(width, height)
    button:Show()
end

-------------------------------------------------------------------------------
--  The full screen
-------------------------------------------------------------------------------
-- Each open window seated in its panel's body (else in another that holds nothing, else on the whole board);
-- each panel without one says what opens it there.
local function Lay()
    if not inside then return end
    local holds, planner, game = Holds(), Planner(), Game()
    local into, places = {}, {} -- [key] = the window in that panel; [frame] = the room it stands in
    for _, spec in ipairs(Board.PANELS) do
        local frame = holds[spec.key]
        if frame and rects[spec.key] then into[spec.key], places[frame] = frame, Body(rects[spec.key]) end
    end
    for _, spec in ipairs(Board.PANELS) do
        local frame = holds[spec.key]
        if frame and not places[frame] then
            for _, other in ipairs(Board.PANELS) do
                if not places[frame] and rects[other.key] and not holds[other.key] and not into[other.key] then
                    into[other.key], places[frame] = frame, Body(rects[other.key])
                end
            end
            local pad = Core.Board.PAD
            places[frame] = places[frame] or { pad, pad, math.max(wide - 2 * pad, 1), math.max(high - 2 * pad, 1) }
        end
    end
    -- A window seated before that stands nowhere now (closed): given back.
    for frame, seat in pairs(seats) do
        if seat.held and not places[frame] then seat:Free() end
    end
    local strata, level, seated = inside:GetFrameStrata(), inside:GetFrameLevel() + Board.LEVEL, {}
    for frame, room in pairs(places) do
        local left, top, width, height = Screen(room)
        seated[frame] = left and SeatOf(frame):Hold(left, top, width, height, strata, level) or false
    end
    local open = not planner and game and game:IsShown()
    for _, spec in ipairs(Board.PANELS) do
        local rect, frame = rects[spec.key], into[spec.key]
        local empty = rect and not (frame and seated[frame])
        Empty(spec, empty and Body(rect) or nil, spec.key == "talents" and planner, open)
    end
end

-- Combat's windows on the board, in the dropdown's order.
local function Spec(entry)
    return { key = entry.key, title = entry.title,
             least = { math.floor(entry.size[1] * Board.LEAST), math.floor(entry.size[2] * Board.LEAST) },
             build = function(panel) ns.Safe(entry.key, Build, panel) end }
end
local WINDOWS = { Spec(Board.PANELS[1]), Spec(Board.PANELS[2]) }

-- Core's window is made (Window.lua): its full screen is Core's board.
function Board.Take(window)
    layouts = Core.Board.New(window, {
        store = ns.store, key = "board", label = ns.name,
        windows = function() return WINDOWS end,
        default = function() return ns.Safe("board", Default) end,
        changed = function() ns.Guarded(ns.Window.Reboard) end,
    })
    Board.layouts = layouts
end

-- The window stands full: what it holds (room) is that wide and high. The panels of the layout chosen are laid
-- out (Core's board) and what is open is seated in them. Coming to the full screen, the planner comes with it,
-- if the layout has the Talents panel.
function Board.Show(room, width, height)
    if not layouts then return end
    local coming = not inside
    inside, wide, high = room, width, height
    rects = layouts:Show(room, width, height) or {}
    if coming and layouts:Has("talents") then
        local planner = Planner()
        if planner then
            Board.Watch(planner)
            if not planner:Shown() then planner:Open() end
        end
    end
    Lay()
end

-- The window goes back to its size, or is there: each window seated is given back (the game's stays open, at
-- its own place), the planner closes, the panels and the clicks go.
function Board.Hide()
    if layouts then layouts:Hide() end
    if not inside then return end
    inside, rects = nil, {}
    for _, seat in pairs(seats) do seat:Free() end
    Hide()
    local planner = Planner()
    if planner and planner:Shown() then planner:Close() end
end

-- The module stood down (GiveBack): all given back; the clicks hidden now or once the fight is over.
function Board.Leave()
    Board.Hide()
    Core.AfterCombat("Combat: clicks", Hide)
end

Reboard = Core.Later(function() ns.Guarded(ns.Window.Reboard) end)

-- A window that belongs on the board opened (the game's, by any way; the planner, by any way): the full
-- screen comes with it, or, full already, it takes its panel. Not in Edit Mode (Edge.lua says no there).
local function Opened()
    if ns.Window.Full() then return Reboard() end
    ns.Window.Fill()
end

-- A fight begins (the game says so before it locks protected frames): the clicks go now; the panels say what
-- opens them meanwhile. It ends: the clicks come back.
local function Fight()
    fighting = true
    Hide()
    if inside then Reboard() end
end

local function Peace()
    fighting = false
    if inside then Reboard() end
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
            view:HookScript("OnShow", ns.Guard(function() if inside then Reboard() end end))
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
