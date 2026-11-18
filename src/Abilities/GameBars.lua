local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - GameBars
--  The game's bars a SaneUI screen does without (Saneroki, 2026-10-31), each
--  by its switch; off, or standing down, the game's own again:
--    experience bars  the game's experience and reputation bars are gone
--                     (SaneUI's own comes later)
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
--
--  Its alert "You have unopened items in your collection" (Saneroki, 2026-11-06):
--  the game shows it at the Collections button at every login while a new mount
--  or pet waits to be opened in the collections window, and closing it holds for
--  that session alone, so it came back at every login, alone on the screen where
--  the menu bar rests. Here closing it holds until more come: the counts it was
--  closed at are kept (the account's, as the game's are), and while neither is
--  higher it is out of sight as soon as the game shows it. Only its look and the
--  mouse are taken from it, so none of the game's code runs in ours: to the game
--  it still shows, as before it was closed (its other alerts of the menu bar wait
--  behind it, as they would). Each item opened in the collections window lowers
--  the counts kept, so a new one is told again.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local GameBars = {}
ns.GameBars = GameBars

-- The game's bars put away, each with its switch.
GameBars.AWAY = { { option = "hideTracking", game = "StatusTrackingBarManager" },
                  { option = "hideStance", game = "StanceBar" } }
GameBars.FADE = 0.2 -- seconds the menu bar takes to come and go
GameBars.UNOPENED = { "COLLECTION_UNOPENED_SINGULAR", "COLLECTION_UNOPENED_PLURAL" } -- the alert's words, the game's

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

-------------------------------------------------------------------------------
--  The alert of unopened collection items
-------------------------------------------------------------------------------
local hushed = setmetatable({}, { __mode = "k" })  -- [the game's tip] = true: out of sight while it shows
local watched = setmetatable({}, { __mode = "k" }) -- [the game's tip] = its hooks are placed (they stay)

-- The mounts and the pets waiting to be opened, as the game counts them.
local function Waiting()
    local mounts, pets = rawget(_G, "C_MountJournal"), rawget(_G, "C_PetJournal")
    mounts = tonumber(Core.Plain(Core.Ask(mounts and mounts.GetNumMountsNeedingFanfare))) or 0
    pets = tonumber(Core.Plain(Core.Ask(pets and pets.GetNumPetsNeedingFanfare))) or 0
    return mounts, pets
end

-- The counts the alert was closed at, or nil.
local function Kept()
    local kept = ns.store and ns.store.unopened
    if type(kept) ~= "table" then return nil end
    return tonumber(kept.mounts) or 0, tonumber(kept.pets) or 0
end

-- Whether one of the game's tips is the alert, by what the game gave it (read only).
local function Unopened(info)
    if type(info) ~= "table" or info.system ~= "MicroButtons" then return false end
    if info.callbackArg ~= rawget(_G, "CollectionsMicroButton") then return false end
    for _, name in ipairs(GameBars.UNOPENED) do
        if info.text == rawget(_G, name) then return true end
    end
    return false
end

local function Hush(tip, on)
    hushed[tip] = on or nil
    tip:SetAlpha(on and 0 or 1)
    tip:EnableMouse(not on)
    local close = rawget(tip, "CloseButton")
    if close then close:EnableMouse(not on) end
end

-- Its close button (or Okay) was clicked: the counts waiting now are kept.
local function Closed(tip)
    if not Unopened(rawget(tip, "info")) then return end
    local mounts, pets = Waiting()
    ns.store.unopened = { mounts = mounts, pets = pets }
end

-- An item opened: fewer wait than were kept, and the counts kept come down to them.
local function Opened()
    local mounts, pets = Kept()
    if not mounts then return end
    local nowMounts, nowPets = Waiting()
    ns.store.unopened = { mounts = math.min(mounts, nowMounts), pets = math.min(pets, nowPets) }
end

-- A tip of the game's pool given back hidden: its look and the mouse again, for the next tip it shows.
local function Released(tip)
    if hushed[tip] then Hush(tip, false) end
end

local closed = ns.Guard(Closed)
local released = ns.Guard(Released)

local function Watch(tip)
    if watched[tip] then return end
    watched[tip] = true
    hooksecurefunc(tip, "HandleAcknowledge", closed)
    tip:HookScript("OnHide", released)
end

-- The game showed an alert of the menu bar: the unopened items' is watched for its closing, and out of sight while
-- no more wait than when it was closed.
local function Alerted(button)
    if button ~= rawget(_G, "CollectionsMicroButton") then return end
    local help = rawget(_G, "HelpTip")
    local pool = type(help) == "table" and rawget(help, "framePool")
    if not (pool and pool.EnumerateActive) then return end
    local mounts, pets = Kept()
    local nowMounts, nowPets = Waiting()
    for tip in pool:EnumerateActive() do
        if Unopened(rawget(tip, "info")) then
            Watch(tip)
            if not ns.off and mounts and nowMounts <= mounts and nowPets <= pets then Hush(tip, true) end
        end
    end
end

-- Hooks after the game's alert and its opening of an item; where a client lacks one, that part is left out.
local function WatchAlerts()
    if type(rawget(_G, "MainMenuMicroButton_ShowAlert")) == "function" then
        hooksecurefunc("MainMenuMicroButton_ShowAlert", ns.Guard(Alerted))
    end
    local opened = ns.Guard(Opened)
    for _, name in ipairs({ "C_MountJournal", "C_PetJournal" }) do
        local journal = rawget(_G, name)
        if type(journal) == "table" and type(journal.ClearFanfare) == "function" then
            hooksecurefunc(journal, "ClearFanfare", opened)
        end
    end
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
    WatchAlerts()
    Core.EditMode.Watch(ns.Guard(GameBars.Apply))
    GameBars.Apply()
end

-- Standing down: the game's bars back (Core.Lend gives back after a fight what may not change in one), the alert in
-- sight again.
function GameBars.GiveBack()
    Apply()
    for tip in pairs(hushed) do Hush(tip, false) end
end
