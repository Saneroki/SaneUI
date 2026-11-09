local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Trainer
--  The full screen at a trainer (Saneroki, 2026-11-09): "When the class
--  trainer is open show the fullscreen with Class Trainer on the left and the
--  skills window on the right"; asked, the skills window is our spellbook,
--  "Weapon trainers open up the skillbook as well but profession trainers open
--  up the Profession window", and a hunter's pet trainer the spellbook too.
--
--  The game's trainer window (ClassTrainerFrame, loaded on demand with
--  Blizzard_TrainerUI; the same window for every kind of trainer, in both
--  games) is seated on the left (the part trainer, Core.Seat.Part). On the
--  right our spellbook (in a game without ours, Retail: the game's own window,
--  GameWindow.lua); at a profession trainer the game's Profession window
--  (ProfessionsFrame, Blizzard_Professions; the part profession) of the
--  profession that trainer teaches, once the character knows it and it has
--  something to craft. Each kind is a layout of its own on Core's board (its
--  occasions trainer and profession), behind its tab while the talk is on,
--  kept as the player arranges it.
--
--  The game opens and closes its windows as always; our code only follows
--  them. The Profession window is opened the game's own way: the trade skill
--  asked of the server (C_TradeSkillUI.OpenTradeSkill), whose answer the
--  game's own code shows; never shown by our code. Opened so, it is closed the
--  same way when the talk ends (C_TradeSkillUI.CloseTradeSkill), if it is
--  still open. The talk over, the full screen goes back if it came for it; one
--  that stood before keeps standing, with the layout chosen. The setting Full
--  Screen at Trainers (trainers) switches it off.
--
--      Trainer.Start()   at the login: the trainer and Profession windows followed
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Trainer = {}
ns.Trainer = Trainer

Trainer.WIDTH = 338       -- the game's trainer window, until it is there to ask (ButtonFrameTemplate)
Trainer.PROFESSION = 750  -- the game's Profession window, likewise (WoW: Forever's width for it)
Trainer.LEAST = 200       -- either panel's least height

local came  -- the talk the full screen came for: it goes back when that ends
local asked -- the trade skill our code opened for this talk, closed at its end

local function Game(name, ...)
    return Core.Ask(rawget(_G, name), ...)
end

-------------------------------------------------------------------------------
--  Which profession the trainer teaches
-------------------------------------------------------------------------------
-- Whether that profession has a window to craft in: its first spell in the book opens one (as the game's own tabs
-- of its Profession window ask); a client without the question: yes.
local function Crafts(offset)
    local book, trade = rawget(_G, "C_SpellBook"), rawget(_G, "C_TradeSkillUI")
    if not (book and book.GetSpellBookItemInfo and trade and trade.CanTradeSkillShowCraftingUI) then return true end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local item = Core.Ask(book.GetSpellBookItemInfo, (tonumber(offset) or 0) + 1, bank)
    local spell = type(item) == "table" and Core.Plain(item.spellID) or nil
    return spell ~= nil and Core.Ask(trade.CanTradeSkillShowCraftingUI, spell) == true
end

-- The skill line of the profession the trainer teaches, if the character knows it: its services' skill line (the
-- game's words) matched by name to the character's professions.
function Trainer.Taught()
    local taught = {}
    for index = 1, tonumber(Game("GetNumTrainerServices")) or 0 do
        local line = Game("GetTrainerServiceSkillLine", index)
        if type(line) == "string" and line ~= "" then taught[line] = true end
    end
    local professions, info = rawget(_G, "GetProfessions"), rawget(_G, "GetProfessionInfo")
    if type(professions) ~= "function" or type(info) ~= "function" then return nil end
    local slots = { pcall(professions) } -- its answers have holes: a profession not learned is nil
    if not slots[1] then return nil end
    for index = 2, table.maxn(slots) do
        local slot = slots[index]
        if slot then
            local ok, name, _, _, _, _, offset, line = pcall(info, slot)
            name, line = Core.Plain(name), Core.Plain(line)
            if ok and name and taught[name] and type(line) == "number" and Crafts(Core.Plain(offset)) then return line end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
--  The talk
-------------------------------------------------------------------------------
local Seated, Profession -- the parts, below

-- The Profession window of what the trainer teaches, asked of the server, unless one is open already.
local function Craft()
    local trade = rawget(_G, "C_TradeSkillUI")
    local frame = Profession.Frame()
    if not (trade and trade.OpenTradeSkill) or (frame and frame:IsShown()) then return end
    local line = Trainer.Taught()
    if line and Core.Ask(trade.OpenTradeSkill, line) then asked = line end
end

-- The trainer's window opened: its kind's layout on the full screen; switched off, a layout the player put it in
-- lays out anew.
local function Opened()
    if ns.off then return end
    if (ns.options or {}).trainers == false then return ns.Window.Reboard() end
    local kind = Game("IsTradeskillTrainer") and "profession" or "trainer"
    ns.Board.Talk(kind) -- a full screen that stands lays out anew with it
    if not ns.Window.Full() and ns.Window.Fill() then came = kind end
    if kind == "profession" then ns.Safe("trainer", Craft) end
end

-- It closed: the Profession window our code opened closes the same way, the talk's layout goes, and so does the full
-- screen if it came for it.
local function Closed()
    if asked then
        asked = nil
        local trade, frame = rawget(_G, "C_TradeSkillUI"), Profession.Frame()
        if trade and trade.CloseTradeSkill and frame and frame:IsShown() then Core.Ask(trade.CloseTradeSkill) end
    end
    local layouts = ns.Board.layouts
    local talk = layouts and layouts.occasion
    if talk ~= "trainer" and talk ~= "profession" then return ns.Window.Reboard() end
    ns.Board.Talk(nil)
    local mine = came ~= nil
    came = nil
    if mine then ns.Window.Back() end
end

-------------------------------------------------------------------------------
--  The parts and their layouts (Board.lua)
-------------------------------------------------------------------------------
Seated = Core.Seat.Part({
    frame = "ClassTrainerFrame", addon = "Blizzard_TrainerUI", label = "Combat: trainer", width = Trainer.WIDTH,
    opened = function() ns.Safe("trainer", Opened) end,
    closed = function() ns.Safe("trainer", Closed) end,
})
Profession = Core.Seat.Part({
    frame = "ProfessionsFrame", addon = "Blizzard_Professions", label = "Combat: profession", width = Trainer.PROFESSION,
    -- It came or went: the board lays out with it or without.
    opened = function() if not ns.off then ns.Window.Reboard() end end,
    closed = function() if not ns.off then ns.Window.Reboard() end end,
})
Trainer.seated, Trainer.profession = Seated, Profession

ns.Board.Part("trainer", ns.TEXT.trainer, { Trainer.WIDTH, Trainer.LEAST }, Seated)
ns.Board.Part("profession", ns.TEXT.profession, { 400, Trainer.LEAST }, Profession)

-- The trainer on the left, as wide as its window is, the other taking the rest.
local function Beside(other)
    return function(width)
        local pad = Core.Board.PAD
        local wide = math.ceil(Seated.Width()) + 2 * Core.Board.EDGE
        return { split = "x", parts = { { key = "trainer" }, { key = other() } },
                 shares = { wide, math.max((width or 0) - 3 * pad - wide, wide) } }
    end
end
-- The spellbook: ours, or the game's own window where ours is not (GameWindow.lua).
ns.Board.Occasion("trainer", ns.TEXT.trainer, Beside(function() return ns.Serves("spellbook") and "spellbook" or "game" end))
ns.Board.Occasion("profession", ns.TEXT.professionTrainer, Beside(function() return "profession" end))

function Trainer.Start()
    Seated.Follow()
    Profession.Follow()
end
