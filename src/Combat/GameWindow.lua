local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - GameWindow
--  The full screen's window in a game where ours are not (Combat.lua, ns.Serves:
--  Retail): the game's own talents and spellbook, one window of the game's
--  (PlayerSpellsFrame, load on demand) with its own tabs, seated in a panel of
--  the board (Core.Seat: its place, scale and layer lent, given back when it
--  closes or the full screen goes). Nothing is built anew for that game, and
--  the full screen around it is the same one.
--
--  The game's window is opened by the game only, never by our code: its OnShow
--  and OnHide set the action bars' grids and its book writes which spell each
--  entry casts; run from our code all of that is tainted, and the grids and a
--  spell clicked in the book are refused (Doc/guides/windows.md, Taint). So
--  whatever opens it (its keys, its micro menu buttons, a link) brings the full
--  screen and seats it. The bottom edge brings the full screen alone, a push
--  being no click, and the panel is then one click from the window: a secure
--  button of the game's (SecureActionButtonTemplate) that clicks its own micro
--  menu button, on UIParent over the panel's body, not in our window (which
--  would be locked in a fight with it): made, placed, shown and hidden out of a
--  fight only, gone as a fight begins and back after it; meanwhile the panel
--  says the key.
--
--  Closed (its key, its X, Esc), the full screen goes back with it. Going back
--  by the edge leaves it open at its own place: our code does not close it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Game = {}
ns.GameWindow = Game

Game.MICRO = "PlayerSpellsMicroButton" -- its button in the game's micro menu
Game.KEY = "TOGGLETALENTS"             -- the game's key binding that opens it
Game.LEVEL = 30                        -- how far above its panel it and the click stand (over Core's panels)
Game.LIGHT = 0.08                      -- how strongly the empty panel lights up under the mouse
Game.INSET = 24                        -- the words of the empty panel from its body's sides

local body, hint -- its panel's body and what it says there, once the panel is made
local seat       -- its seat in that body, once made
local click      -- the secure click over the empty body, once made
local shown      -- its panel is shown
local fighting   -- a fight is on, from the moment the game says it begins

-- The game's window, once its addon is loaded (the game loads it when first wanted).
local function Frame()
    local frame = rawget(_G, "PlayerSpellsFrame")
    if type(frame) == "table" and type(frame.IsShown) == "function" then return frame end
end

-- The game's words for the key that opens it; nil without one.
local function KeyText()
    local key = Core.Ask(rawget(_G, "GetBindingKey"), Game.KEY)
    return key and (Core.Ask(rawget(_G, "GetBindingText"), key) or key) or nil
end

-- What the empty panel says, and whether a click opens the window now (not in a fight; not while the game has it
-- closed to you, its micro menu button off).
local function Words()
    local micro = rawget(_G, Game.MICRO)
    if type(micro) == "table" and Core.Ask(micro.IsEnabled, micro) == false then return ns.TEXT.gameNotYet, false end
    local key = KeyText()
    if fighting or InCombatLockdown() then
        return key and ns.TEXT.gameFight:format(key) or ns.TEXT.gameFightNoKey, false
    end
    return key and ns.TEXT.gameClick:format(key) or ns.TEXT.gameClickNoKey, true
end

-- A secure click on the game's own micro menu button: the game's code opens its window as its own. Made out of a
-- fight only; nil in one, or without that button.
local function Click()
    if click then return click end
    local micro = rawget(_G, Game.MICRO)
    if InCombatLockdown() or type(micro) ~= "table" then return nil end
    click = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    click:RegisterForClicks("LeftButtonUp")
    click:SetAttribute("useOnKeyDown", false) -- on the release, as it is registered, whatever the game's key-down setting says
    click:SetAttribute("type", "click")
    click:SetAttribute("clickbutton", micro)
    local light = click:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], Game.LIGHT)
    click:Hide()
    return click
end

-- The click out of sight: as a fight begins, when the full screen goes, when the window is seated.
local function Away()
    if click and not InCombatLockdown() then click:Hide() end
end

-- Closed while seated (given back already): the full screen was for it.
local function SeatOf(frame)
    seat = seat or Core.Seat.New(frame, { label = "Combat: the game's window", gone = ns.Window.Back })
    return seat
end

-- The panel without the window: what opens it, and the click over its body (left, top, width, height: in UIParent's
-- units, the click stands on UIParent).
local function Empty(left, top, width, height)
    local words, clicks = Words()
    hint:SetText(words)
    hint:Show()
    local button = clicks and Click()
    if not button then return Away() end
    button:SetFrameStrata(body:GetFrameStrata())
    button:SetFrameLevel(body:GetFrameLevel() + Game.LEVEL)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    button:SetSize(width, height)
    button:Show()
end

-- Its panel as things stand: the window seated if it is open, else what opens it.
local function Lay()
    if not (shown and body) then return end
    local left, top = body:GetLeft(), body:GetTop()
    if not (left and top) then return end
    local ratio = body:GetEffectiveScale() / UIParent:GetEffectiveScale()
    left, top = left * ratio, top * ratio
    local width, height = body:GetWidth() * ratio, body:GetHeight() * ratio
    local frame = Frame()
    if frame and frame:IsShown() and SeatOf(frame):Hold(left, top, width, height, body:GetFrameStrata(),
                                                        body:GetFrameLevel() + Game.LEVEL) then
        hint:Hide()
        return Away()
    end
    Empty(left, top, width, height)
end
local Relay = Core.Later(function() ns.Safe("game window", Lay) end) -- once the panel stands where it goes

-- The part on the board (Board.lua).
local Part = {}
Part.Apart = false -- the game's own window seated on the full screen: never a window of its own (Core's board)

function Part.Build(panel)
    body = panel.body
    hint = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("LEFT", Game.INSET, 0)
    hint:SetPoint("RIGHT", -Game.INSET, 0)
    hint:SetWordWrap(true)
    hint:Hide()
    panel.hint = hint
end

function Part.Show(on)
    shown = on
    if on then return Relay() end
    if seat then seat:Free() end
    Away()
end

function Part.Size()
    Relay()
end

-- There where neither of ours is (Combat.lua, ns.Serves).
function Part.Present()
    return not ns.Serves()
end

function Part.Leave()
    shown = false
    if seat then seat:Free() end
    Core.AfterCombat("Combat: the game's window", Away)
end

ns.Board.Part("game", ns.TEXT.book, { 400, 300 }, Part)

-- It opened, by whatever way: the full screen comes with it, or, full already, it takes its panel. Not in Edit Mode
-- (Edge.lua says no there).
local function Opened()
    if ns.off then return end
    ns.Window.Open("game")
    Relay()
end

-- A fight begins (the game says so before it locks protected frames): the click goes now and the panel says what
-- opens the window meanwhile. It ends: the click comes back.
local function Fight(on)
    fighting = on
    if on then Away() end
    if shown then Relay() end
end

-- At the login: its opening and the fights followed, in a game where it is the full screen's window.
function Game.Start()
    if not Part.Present() then return end
    local registry = rawget(_G, "EventRegistry")
    if registry then registry:RegisterCallback("PlayerSpellsFrame.OpenFrame", ns.Guard(Opened), Game) end
    ns.On("PLAYER_REGEN_DISABLED", function() if not ns.off then Fight(true) end end)
    ns.On("PLAYER_REGEN_ENABLED", function() if not ns.off then Fight(false) end end)
end
