local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Talks
--  The full screen at a vendor and a banker (Saneroki, 2026-11-09): "When
--  vendor is open show vendor on the left and the bags on the right in the
--  fullscreen", "When the banker is open show the banker window on the right
--  and the bags on the left fullscreen." Each talk has a layout of its own on
--  Core's board (its occasions, Board.Occasion): the game's vendor window on
--  the left (the part vendor: seated in its panel while it is open, Core.Seat.
--  Part) and the bags on the right; the bags on the left and our bank window
--  on the right. That layout stands behind a tab of its own, first in the
--  title bar while the talk is on, and is kept as the player arranges it.
--
--  The game opens and closes its vendor window as always (at the NPC, by Esc,
--  by walking away); our code only follows it, and the bank by the game's
--  events. The talk over, the full screen goes back if it came for it; one
--  that stood before keeps standing, with the layout chosen. Going back by the
--  corner leaves the talk be: the vendor window stays open at its own place.
--  The setting Full Screen at Vendors and the Bank (talks) switches it off.
--
--      Talks.Start()       at the login: the vendor window and the bank followed
--      Talks.Began(name)   a talk began ("vendor", "bank"): its layout on the full screen; false when switched off
--      Talks.Ended(name)   it ended: false when its layout did not stand
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talks = {}
ns.Talks = Talks

Talks.VENDOR = 336   -- the game's vendor window's width, until it is there to ask (MerchantFrame.xml)
Talks.LEAST = 200    -- the vendor's panel's least height

local came -- the talk the full screen came for: it goes back when that ends

function Talks.Began(name)
    if ns.off or (ns.options or {}).talks == false then return false end
    ns.Board.Talk(name) -- a full screen that stands lays out anew with it
    if not ns.Window.Full() and ns.Window.Fill() then came = name end
    return true
end

function Talks.Ended(name)
    local layouts = ns.Board.layouts
    if not layouts or layouts.occasion ~= name then return false end
    ns.Board.Talk(nil)
    local mine = came == name
    came = nil
    if mine then ns.Window.Back() end
    return true
end

-------------------------------------------------------------------------------
--  The vendor: the game's own window, seated on the full screen
-------------------------------------------------------------------------------
local Shop = Core.Seat.Part({
    frame = "MerchantFrame", label = "Inventory: vendor", width = Talks.VENDOR,
    -- Opened or closed: the talk's layout comes or goes; switched off, a layout the player put it in lays out anew.
    opened = function() if not Talks.Began("vendor") then ns.Window.Reboard() end end,
    closed = function() if not Talks.Ended("vendor") then ns.Window.Reboard() end end,
})
Talks.shop = Shop

ns.Board.Part("vendor", ns.TEXT.talkVendor, { Talks.VENDOR, Talks.LEAST }, Shop)

-- The vendor's window on the left, as wide as it is, the bags taking the rest.
ns.Board.Occasion("vendor", ns.TEXT.talkVendor, function(width)
    local pad = Core.Board.PAD
    local wide = math.ceil(Shop.Width()) + 2 * Core.Board.EDGE
    return { split = "x", parts = { { key = "vendor" }, { key = "bags" } },
             shares = { wide, math.max((width or 0) - 3 * pad - wide, wide) } }
end)

-- The bags on the left, the bank on the right, sharing the screen.
ns.Board.Occasion("bank", ns.TEXT.talkBank, function()
    return { split = "x", parts = { { key = "bags" }, { key = "bank" } }, shares = { 1, 1 } }
end)

function Talks.Start()
    Shop.Follow()
    ns.On("BANKFRAME_OPENED", function() Talks.Began("bank") end)
    ns.On("BANKFRAME_CLOSED", function() Talks.Ended("bank") end)
end
