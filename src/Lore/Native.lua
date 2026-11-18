local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Lore - Native
--  The game's gossip window and quest window, held out of sight while ours
--  shows the talk (the holder's way, Doc/guides/windows.md, section 7). While
--  closed, each has a hidden frame of ours as its parent (Core.Lend: noted and
--  given back exactly), so the game opens and closes it as always, by its own
--  code: it counts as shown, but never comes into sight, and its OnShow and
--  OnHide do not run (its OnHide would end the talk). Nothing of the game's is
--  written: no event taken away, no field, no panel list. A window open when it
--  is to be held (a talk under way) is held once it closes.
--  Given back: in a fight (a talk begun there is the game's own), while Talks
--  as a scene is off, and when the module stands down; and at once for a talk
--  the game shows while ours does not (one of a kind ours leaves to the game):
--  never a talk out of sight.
--
--      Native.Hold()        held from now on (each window once it is closed)
--      Native.Release()     given back from now on (each window once it is closed)
--      Native.Held(family)  whether the game's window for a talk ("gossip", "quest") is held now
--      Native.Closed()      the game closed a talk: held or given back, as wanted
--      Native.Check(family, ours)  the game's window open and held while ours does not show
--                           that talk: in sight at once
--      Native.GiveBack()    every window back now, open or not
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Native = {}
ns.Native = Native

local NAMES = { gossip = "GossipFrame", quest = "QuestFrame" }
local box          -- the hidden frame they are held in
local lent = {}    -- [family] = the window's lend while it is held
local wanted = false

local function Frame(family)
    local frame = rawget(_G, NAMES[family])
    if type(frame) == "table" and type(frame.GetObjectType) == "function" then return frame end
    return nil
end

local function HoldOne(family)
    if lent[family] then return end
    local frame = Frame(family)
    if not frame or frame:IsShown() then return end -- open now: held once it closes (Closed)
    if not box then
        box = CreateFrame("Frame", nil, UIParent)
        box:Hide()
    end
    local lend = Core.Lend(frame)
    -- Its strata and level noted first, given back with its parent (a new parent changes them).
    if not lend:SetLayer() or not lend:SetParent(box) then return lend:Return() end
    lent[family] = lend
end

-- now: at once, open or not (it comes into sight with the talk it shows).
local function ReleaseOne(family, now)
    local lend = lent[family]
    if not lend then return end
    local frame = Frame(family)
    if not now and frame and frame:IsShown() then return end -- open: given back once it closes
    lent[family] = nil
    lend:Return()
end

function Native.Hold()
    wanted = true
    for family in pairs(NAMES) do HoldOne(family) end
end

function Native.Release()
    wanted = false
    for family in pairs(NAMES) do ReleaseOne(family) end
end

function Native.Held(family)
    return lent[family] ~= nil
end

function Native.Closed()
    for family in pairs(NAMES) do
        if wanted then HoldOne(family) else ReleaseOne(family) end
    end
end

function Native.Check(family, ours)
    if ours or not lent[family] then return end
    local frame = Frame(family)
    if frame and frame:IsShown() then ReleaseOne(family, true) end
end

function Native.GiveBack()
    wanted = false
    local first
    for family in pairs(NAMES) do
        local ok, problem = pcall(ReleaseOne, family, true) -- each by itself
        if not ok and not first then first = problem end
    end
    if first then error(first, 0) end
end
