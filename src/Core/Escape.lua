local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Escape
--  Esc closes what Sane UI has open, as it closes the game's own panels. The
--  game hides every frame its list UISpecialFrames names when Esc is pressed
--  (CloseSpecialWindows). One frame of ours stands in that list for all of
--  Sane UI, with nothing to see: shown while something of ours is to be closed
--  by Esc, and when the game hides it, each of those is closed as its owner
--  says (a window Esc closes closes, full as it is; a window that fills the
--  screen goes back; the feedback window hides). A moment later it is shown
--  again while anything is left: a window that may not be hidden in a fight,
--  one whose module closes it later.
--
--      Core.Escape(owner, close)   -- Esc runs close(owner) from now on; nil: no more
-------------------------------------------------------------------------------
local closes = {} -- [owner] = what Esc does to it
local stand       -- the frame in the game's list, made with the first owner
local closing = false

local function Again()
    stand:SetShown(next(closes) ~= nil)
end

-- The game hid the stand-in (Esc). The owners are taken first: closing one may tell of another.
local function Closed()
    closing = true -- what is closed now does not show the stand-in again in the middle of this
    local owners = {}
    for owner, close in pairs(closes) do owners[#owners + 1] = { owner, close } end
    for _, entry in ipairs(owners) do Core.Safe("Esc", entry[2], entry[1]) end
    closing = false
    C_Timer.After(0, Again)
end

function Core.Escape(owner, close)
    if not stand then
        if not close then return end
        stand = CreateFrame("Frame", "SaneUIEscape", UIParent)
        stand:Hide()
        stand:SetScript("OnHide", Closed)
        local special = rawget(_G, "UISpecialFrames")
        if type(special) == "table" then table.insert(special, "SaneUIEscape") end
    end
    closes[owner] = close
    if not closing then Again() end
end
