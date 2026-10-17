local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Holder
--  Ours or the game's, never both (Saneroki, 2026-10-16; Doc/guides/windows.md,
--  section 7, The holder). A window of ours that stands for one of the game's
--  (native = { frame, hold = true }) keeps the game's out of sight while ours is
--  chosen: the game's window has a hidden frame of ours as its parent (lent,
--  Core.Lend: its parent and layer noted and given back exactly, the parent only
--  if it is still ours), but only while it is not open: at once, once its addon
--  has loaded (native.addon, for one the game loads when first wanted), and
--  again each time it closes. The game then opens and closes it as always, by
--  its own code (its key, a button of its micro menu, a link, an NPC): it counts
--  as shown, but never comes into sight, so its OnShow and OnHide do not run (no
--  talk ended, no action bar touched). Hooks after its own Show, Hide and SetShown
--  open and close ours; nothing of the game's is replaced.
--
--  To the game's (window:Native(true), our title bar's first button): ours
--  closes, and the game's goes back to its parent: open, it comes into sight and
--  its OnShow runs from our code, fine for most windows (a friends list, a vendor:
--  as if it had just opened). With native.unseen (a window whose OnShow must not
--  run from ours: the spellbook's sets the action bars' protected grids) it is
--  closed unseen first, and opens at its next asking.
--  To ours (window:Native(false): the Sane UI button on the game's window, while
--  that is in sight): the game's is not hidden (its OnHide would end a talk) but
--  made tiny and clear, its buttons shrunk to a point that takes no click, until
--  the game closes it; then it is held again. Ours opens at once.
--  Ours closed while the game's is held open: the game's is closed too, unseen.
--
--  In a fight a protected window of the game's is left as it is (Lend), given
--  back once the fight is over. A step that fails gives the game's window back
--  at once and holds it no more (holder.off), as does window:GiveBack() (a
--  module that stands down).
--
--      window.holder        made by Window.New for native.hold
--      holder.held          the game's window is out of sight now
-------------------------------------------------------------------------------
local Holder = {}
Core.Holder = Holder

Holder.TINY = 0.001 -- the game's window, made tiny while the game still has it open and ours is chosen

local box -- the hidden frame the game's windows are held in
local methods = {}

-- The game's window: its frame, or what its function gives (nil while its addon is not loaded).
local function Game(holder)
    local game = holder.window.options.native.frame
    if type(game) == "function" then game = game() end
    if type(game) ~= "table" or type(game.GetObjectType) ~= "function" then return nil end
    return game
end

-- Whether ours is the one chosen (not the game's: window:Native).
local function Ours(holder)
    return not holder.window:Recall("native")
end

-- Something failed: the game's window is the game's again, now, for the rest of the session.
local function Off(holder, problem)
    if holder.off then return end
    holder.off, holder.held, holder.shrunk = true, false, false
    if holder.lent then pcall(holder.lent.Return, holder.lent) end
    if problem then Core.Report("window holder", problem) end
end

-- One step; a failure gives the game's window back.
local function Step(holder, fn, ...)
    if holder.off then return end
    local ok, problem = xpcall(fn, Core.Trace, holder, ...)
    if not ok then Off(holder, problem) end
end

-- The game's window out of sight, if ours is chosen and the game's is not open (it is held when it closes).
local function Hold(holder)
    local game = Game(holder)
    if not game or holder.held or holder.shrunk or not Ours(holder) or game:IsShown() then return end
    if not box then
        box = CreateFrame("Frame", nil, UIParent)
        box:Hide()
    end
    holder.lent = holder.lent or Core.Lend(game)
    if not holder.lent:SetLayer() then return end -- its strata and level noted, to be given back with its parent
    holder.held = holder.lent:SetParent(box)
end

-- The game's window given back as it was: its parent (if still ours), its layer, scale and alpha.
local function Give(holder)
    holder.held, holder.shrunk = false, false
    if holder.lent and holder.lent:Lent() then holder.lent:Return() end
end

-- The game opened its window, held: ours opens instead. One that may not be shown now (a fight): the game's
-- is given back, so the game's own is seen.
local function Shown(holder)
    if not holder.held then return end
    if holder.window:Open() == "locked" then Give(holder) end
end

-- The game closed its window: ours closes, held or not. Made tiny for a while, it is given back as it was;
-- then, closed, it is held again.
local function Hidden(holder)
    local window = holder.window
    if holder.held or holder.shrunk then
        if window.frame:IsShown() and not window:Locked() then window.frame:Hide() end
    end
    if holder.shrunk then Give(holder) end
    Hold(holder)
end

-- Ours was closed while the game's is held open: the game's closes too, unseen, so its next asking opens it.
local function Closed(holder)
    local game = Game(holder)
    if holder.held and game and game:IsShown() and not Core.Locked(game) then game:Hide() end
end

-- The hooks after the game's own Show, Hide and SetShown, once for its window.
local hooked = setmetatable({}, { __mode = "k" })
local function Hook(holder)
    local game = Game(holder)
    if not game or hooked[game] then return end
    hooked[game] = true
    hooksecurefunc(game, "Show", function() Step(holder, Shown) end)
    hooksecurefunc(game, "Hide", function() Step(holder, Hidden) end)
    hooksecurefunc(game, "SetShown", function(_, on) Step(holder, on and Shown or Hidden) end)
end

-- To the game's window (on) or to ours: what window:Native does with a holder.
function methods:Native(on)
    if self.off then return end
    local window = self.window
    if on then
        local game = Game(self)
        Step(self, function(holder)
            -- Closed unseen first, for a window whose OnShow must not run from ours; then the game's again, and
            -- ours away (after: closing ours while the game's is held would close the game's too).
            if game and holder.held and window.options.native.unseen and game:IsShown() and not Core.Locked(game) then game:Hide() end
            Give(holder)
            if window.frame:IsShown() and not window:Locked() then window.frame:Hide() end
        end)
        return
    end
    Step(self, function(holder)
        local game = Game(holder)
        if game and game:IsShown() and not holder.held then
            -- In sight: tiny and clear until the game closes it (not hidden: its OnHide would end a talk).
            holder.lent = holder.lent or Core.Lend(game)
            holder.shrunk = holder.lent:SetScale(Holder.TINY) and holder.lent:SetAlpha(0)
        else
            Hold(holder)
        end
        window:Open()
    end)
end

-- The game's window back for good (a failure of ours, a module standing down).
function methods:GiveBack()
    Off(self)
end

-- Made for a window with native.hold: hooked and held now, or once its addon has loaded.
function Holder.Take(window)
    local holder = setmetatable({ window = window, held = false, shrunk = false }, { __index = methods })
    local function Begin()
        Step(holder, Hook)
        Step(holder, Hold)
        Core.Safe("window", window.Attach, window)
    end
    local addon, util = window.options.native.addon, rawget(_G, "EventUtil")
    if addon and util and util.ContinueOnAddOnLoaded then
        util.ContinueOnAddOnLoaded(addon, Begin)
    else
        Begin()
    end
    -- Ours closed (its close, Esc) while the game's is held open: the game's closes too.
    window.frame:HookScript("OnHide", function() Step(holder, Closed) end)
    return holder
end
