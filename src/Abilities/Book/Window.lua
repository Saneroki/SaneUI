local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Window
--  Lets you move the spellbook by the bar at its top and give it another size by
--  its lower right corner. The size and the place are kept; Book.lua and Home.lua
--  measure the pages every time they draw, so the entries follow the size.
--
--  The window is the game's (PlayerSpellsFrame, shared with the talents). The
--  game gives it a size whenever it is opened, made small or large, or its tab
--  changes, and puts it in its place among the other windows. So this file does
--  not take the window over. It only puts our size and place on it again after
--  the game has put its own (Apply), and only
--    - while the spellbook's pages are ours (Book.lua), the switch is on and the
--      spellbook, not the talents, is the tab on show;
--    - out of a fight: the game forbids an addon to move or size this window in
--      one. What a fight held up is done when it ends (Core.AfterCombat).
--  Nothing is written into the window: its size, its place, and whether it may
--  be moved are set through the frame's own functions; what we must remember is
--  kept here and in the saved settings (window = { large = , small = , left, top }).
--  The drag bar and the corner grip are frames of this addon; the dragging and
--  the sizing themselves are Core's (Core/Window.lua, Mover and Sizer).
--
--  Two sizes are kept: one for the open book, one for the small spellbook.
-------------------------------------------------------------------------------
local W = {}
ns.Window = W
local B = ns.Book
local Core = SaneUI.Core
local TEXT = ns.TEXT

local MIN_WIDTH, MIN_HEIGHT = 420, 360
-- The spellbook inside the window (Blizzard_PlayerSpells, the Forever variant): 1612 x 702 in
-- 1618 x 720 open, 806 x 702 in 809 x 720 small.
local INSET_X = { large = 6, small = 3 }
local INSET_Y = 18

local frame, book   -- the game's window and the spellbook in it
local bar, grip     -- ours: what you drag to move, what you drag to size
local on = false    -- we look after the window's size and place
local native = {}   -- [large or small] = { width, height } the game gave it, to give back
-- What a fight held up, each done once it is over: our size and place put on, the game's given back.
local AFTER_APPLY, AFTER_GIVE = "Abilities: spellbook window", "Abilities: spellbook window given back"

local function Saved()
    if type(ns.DB.window) ~= "table" then ns.DB.window = {} end
    return ns.DB.window
end

-- A kept size, if it can be used: it comes from older versions and from hand edits.
local function Size(saved, mode)
    local size = saved[mode]
    if type(size) == "table" and type(size[1]) == "number" and type(size[2]) == "number" then return size end
    return nil
end

-- "small": the spellbook made small with the game's own button; otherwise "large".
local function Mode()
    return book.isMinimized and "small" or "large"
end

local function Usable()
    return on and frame:IsShown() and book:IsShown() and not InCombatLockdown()
end

-- The spellbook fills the window, as it does at the game's own sizes.
local function FitBook()
    local width, height = frame:GetSize()
    width, height = width - INSET_X[Mode()], height - INSET_Y
    local isWidth, isHeight = book:GetSize()
    if math.abs((isWidth or 0) - width) > 0.5 or math.abs((isHeight or 0) - height) > 0.5 then
        book:SetSize(width, height)
    end
end

local Later -- below

-- Our size and place on the window, after the game has put its own. In a fight: once it is over.
local function Apply()
    if not Usable() then
        if on and InCombatLockdown() then Core.AfterCombat(AFTER_APPLY, Later) end
        return
    end
    local saved, mode = Saved(), Mode()
    local width, height = frame:GetSize()
    local size = Size(saved, mode)
    local ours = size and math.abs(width - size[1]) <= 0.5 and math.abs(height - size[2]) <= 0.5
    if not ours then native[mode] = { width, height } end -- the size the game has just given it
    if size and not ours then frame:SetSize(size[1], size[2]) end
    -- Also without a size of ours: the game sizes only the book's width when it is made small or
    -- large, and it may still have the height ours gave it in the other mode.
    FitBook()
    if type(saved.left) == "number" and type(saved.top) == "number" then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.left, saved.top)
    end
end

-- The game places its windows right after showing one: ours comes a moment later.
local ApplyLater = Core.Later(function() ns.Safe("window", Apply) end)
function Later()
    if on then ApplyLater() end
end

-- Where the window stands now, as the place to keep.
local function Remember(size)
    local saved = Saved()
    saved.left, saved.top = frame:GetLeft(), frame:GetTop()
    if size then saved[Mode()] = { frame:GetWidth(), frame:GetHeight() } end
end

-- The window got another size (ours, or the game's): the spellbook follows at once, the pages a
-- little later. While the corner is dragged the size changes every frame; laying the pages out
-- (a whole build of the tab, Home, the bar ghosts) ten times a second is plenty, and the grip's
-- stopped hook below draws the final size.
local Redraw = Core.Later(function() ns.Fire("REFRESH") end, 0.1)
local function OnSize()
    if not on or not book:IsShown() then return end
    if InCombatLockdown() then Core.AfterCombat(AFTER_APPLY, Later) else FitBook() end
    Redraw()
end

local function Setup()
    frame = PlayerSpellsFrame
    book = frame.SpellBookFrame
    if bar then return end

    -- The bar: over the window's title, clear of the buttons at its right end.
    bar = CreateFrame("Frame", "SaneUISpellbookDragBar", frame)
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 60, 0)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -60, 0)
    bar:SetHeight(22)
    bar:SetFrameLevel(5000) -- above the title, which is a frame of its own; the window's buttons are higher still
    Core.Window.Mover(bar, frame, {
        usable = Usable,
        stopped = function()
            Remember(false)
            Apply()
        end,
    })

    grip = Core.Window.Sizer(frame, {
        name = "SaneUISpellbookSizeGrip", insetX = 4, insetY = 6,
        minWidth = MIN_WIDTH, minHeight = MIN_HEIGHT, usable = Usable,
        tip = TEXT.sizeTip, tipMore = TEXT.sizeTipMore,
        -- The first sizing: from now on this size is ours, and the game's is remembered to give back.
        started = function()
            local saved, mode = Saved(), Mode()
            if not Size(saved, mode) then
                native[mode] = { frame:GetWidth(), frame:GetHeight() }
                saved[mode] = { frame:GetWidth(), frame:GetHeight() }
            end
        end,
        stopped = function()
            Remember(true)
            Apply()
            ns.Fire("REFRESH") -- the last size is drawn at once, whatever the throttle still owes
        end,
    })
    grip:SetFrameLevel(5000)

    -- All after the game's own handlers, and apart from them.
    frame:HookScript("OnShow", Later)
    frame:HookScript("OnSizeChanged", function() ns.Safe("window", OnSize) end)
    book:HookScript("OnShow", Later)
    if frame.UpdateSize then pcall(hooksecurefunc, frame, "UpdateSize", Later) end
    if UpdateUIPanelPositions then pcall(hooksecurefunc, "UpdateUIPanelPositions", Later) end
end

-- The game's own size again, and its own place the next time it puts its windows. Not in a
-- fight: then when it ends (GiveBackNow).
local function GiveBack()
    if not frame then return end
    local size = native[Mode()]
    -- With the talents on show the window has their size: the game gives it the book's at the next tab.
    if size and book:IsShown() then
        frame:SetSize(size[1], size[2])
        FitBook()
    end
end

-- Now, or once the fight is over; true when it was now (or there is no window to give back).
local function GiveBackNow()
    return not frame or Core.AfterCombat(AFTER_GIVE, GiveBack)
end

-- Takes the window (when the pages are ours and the switch is on) or lets it go.
function W.Update()
    local want = B.Armed() and ns.options.window and PlayerSpellsFrame ~= nil and true or false
    if want then Setup() end
    if want == on then return end
    on = want
    if bar then
        bar:SetShown(on)
        grip:SetShown(on)
    end
    if on then Later() else GiveBackNow() end
end

-- /sane ab window reset
function W.Reset()
    ns.DB.window = nil
    if GiveBackNow() then
        ns.Print(TEXT.windowReset)
    else
        ns.Print(TEXT.windowResetLater)
    end
end

ns.Listen("BOOK_PAGES", W.Update)
ns.Listen("REFRESH", W.Update)
