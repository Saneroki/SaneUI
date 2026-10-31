local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - GameBars
--  The game's bars a Sane UI screen does without (Saneroki, 2026-10-31), each
--  by its switch; off, or standing down, the game's own again:
--    experience bars  the game's experience and reputation bars are gone (Sane
--                     UI's own comes later)
--    stance bar       the game's stance, form and aura buttons are gone; the
--                     keys bound to them and your action bars change stances
--                     still (its keys run the game's StanceBar:Select)
--    menu bar         out of sight at rest, in sight while the mouse is on it
--
--  The first two stand in a hidden frame of ours (Core.Lend: their parent given
--  back exactly). The game goes on running them unseen and stacks its other
--  bars as before: its layout asks each bar's IsShown, which a hidden parent
--  leaves as it is. Neither has an OnHide that does more than Edit Mode's own
--  clean-up of a selected frame, so ours may hide them.
--
--  The menu bar keeps its place: WoW: Forever's main action bar hangs on it
--  (Edit Mode's layout), and in a vehicle the game moves it onto its own bar.
--  So only its alpha changes (MicroMenu's, which goes where it goes), and its
--  buttons take the mouse at alpha 0 as ever: a hook after a button's OnEnter
--  brings it into sight, and while it is, the look of a frame of ours each
--  frame sees the mouse off it. In Edit Mode it shows, to be placed.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local GameBars = {}
ns.GameBars = GameBars

-- The game's bars put away, each with its switch.
GameBars.AWAY = { { option = "hideTracking", game = "StatusTrackingBarManager" },
                  { option = "hideStance", game = "StanceBar" } }
GameBars.FADE = 0.2 -- seconds the menu bar takes to come and go

local box             -- the hidden frame the game's bars stand in
local lends = {}      -- [an entry of GameBars.AWAY] = its lend
local menu, fade      -- the game's menu bar and its fade
local rest            -- the lend of its alpha, while it rests out of sight
local seen = false    -- the mouse brought it into sight
local watcher         -- shown while it is in sight: looks for the mouse leaving it

local function Seen(on)
    if on == seen then return end
    seen = on
    fade:To(on and 1 or 0, GameBars.FADE)
end

local function Entered()
    if not rest then return end
    Seen(true)
    watcher:Show()
end

local function Watching()
    if menu:IsMouseOver() then return end
    watcher:Hide()
    Seen(false)
end

-- The menu bar resting out of sight, or as the game has it.
local function Menu()
    if not menu then return end
    local want = not ns.off and ns.options.menuHover ~= false and not Core.EditMode.active
    if want and not rest then
        rest = Core.Lend(menu)
        rest:SetAlpha(0)
    elseif rest and not want then
        fade:Stop()
        watcher:Hide()
        seen = false
        local lent = rest
        rest = nil
        lent:Return()
    end
end

local function Apply()
    for _, entry in ipairs(GameBars.AWAY) do
        local game = rawget(_G, entry.game)
        local want = not ns.off and ns.options[entry.option] ~= false
        if want and not lends[entry] and type(game) == "table" then
            local lend = Core.Lend(game)
            if lend:SetParent(box) then lends[entry] = lend end
        elseif lends[entry] and not want then
            local lent = lends[entry]
            lends[entry] = nil
            ns.Safe("game bars", lent.Return, lent)
        end
    end
    Menu()
end

-- As the switches say, now or once the fight is over.
function GameBars.Apply()
    Core.AfterCombat("game bars", Apply)
end

function GameBars.Start()
    box = CreateFrame("Frame", nil, UIParent)
    box:Hide()
    menu = rawget(_G, "MicroMenu")
    if type(menu) == "table" then
        fade = Core.Motion.Fade(menu)
        watcher = CreateFrame("Frame")
        watcher:Hide()
        watcher:SetScript("OnUpdate", ns.Guard(Watching))
        local entered = ns.Guard(Entered)
        for _, button in ipairs({ menu:GetChildren() }) do button:HookScript("OnEnter", entered) end
    else
        menu = nil
    end
    Core.EditMode.Watch(ns.Guard(GameBars.Apply))
    GameBars.Apply()
end

-- Standing down: the game's bars back (Core.Lend gives back after a fight what may not change in one).
function GameBars.GiveBack()
    Apply()
end
