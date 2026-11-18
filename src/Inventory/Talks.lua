local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Talks
--  The full screen at a vendor and a banker (Saneroki, 2026-11-09): "When
--  vendor is open show vendor on the left and the bags on the right in the
--  fullscreen", "When the banker is open show the banker window on the right
--  and the bags on the left fullscreen." "Mail window should open inside the
--  inventory fullscreen with the mail window on the left and the bags on the
--  right side." Each talk has a layout of its own on
--  Core's board (its occasions, Board.Occasion): the game's vendor window on
--  the left (the part vendor: seated in its panel while it is open, Core.Seat.
--  Part) and the bags on the right; the bags on the left and our bank window
--  on the right; the game's mail window on the left (the part mail), a letter
--  being read beside it (the part letter: the game's own window of it, which
--  stands on its own beside the mail window), the bags on the right; Economy's
--  tick Send to banker on its Send Mail tab goes with it, being the window's own child.
--  That layout stands behind a tab of its own, first in the
--  title bar while the talk is on, and is kept as the player arranges it.
--
--  The game opens and closes its vendor and mail windows as always (at the NPC
--  or the mailbox, by Esc, by walking away); our code only follows them, and
--  the bank by the game's events. The talk over, the full screen goes back if it came for it; one
--  that stood before keeps standing, with the layout chosen. Going back by the
--  corner leaves the talk be: the game's window stays open at its own place.
--  The setting Full Screen at Vendors, the Bank and Mail (talks) switches it off.
--
--      Talks.Start()       at the login: the vendor window and the bank followed
--      Talks.Began(name)   a talk began ("vendor", "bank", "mail"): its layout on the full screen; false when switched off
--      Talks.Ended(name)   it ended: false when its layout did not stand
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talks = {}
ns.Talks = Talks

Talks.VENDOR = 336   -- the game's vendor window's width, until it is there to ask (MerchantFrame.xml)
Talks.MAIL = 338     -- the game's mail window's and a letter's, likewise (ButtonFrameTemplate)
Talks.LEAST = 200    -- a seated window's panel's least height

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

-------------------------------------------------------------------------------
--  The mail: the game's own mail window and a letter's, seated on the full screen
-------------------------------------------------------------------------------
local Post = Core.Seat.Part({
    frame = "MailFrame", addon = "Blizzard_MailFrame", label = "Inventory: mail", width = Talks.MAIL,
    opened = function() if not Talks.Began("mail") then ns.Window.Reboard() end end,
    closed = function() if not Talks.Ended("mail") then ns.Window.Reboard() end end,
})
-- A letter opened: it takes its place beside the mail window, put back into the mail's layout should the player have
-- taken it out there (else it would stand behind the full screen, out of sight).
local function Read()
    if ns.off then return end
    local layouts = ns.Board.layouts
    if layouts and layouts.standing and layouts:Talking() == "mail" and not layouts:Has("letter") then return ns.Board.Add("letter") end
    ns.Window.Reboard()
end
local Letter = Core.Seat.Part({
    frame = "OpenMailFrame", addon = "Blizzard_MailFrame", label = "Inventory: letter", width = Talks.MAIL,
    opened = Read,
    closed = function() if not ns.off then ns.Window.Reboard() end end,
})
Talks.post, Talks.letter = Post, Letter

ns.Board.Part("mail", ns.TEXT.talkMail, { Talks.MAIL, Talks.LEAST }, Post)
ns.Board.Part("letter", ns.TEXT.talkLetter, { Talks.MAIL, Talks.LEAST }, Letter)

-- The mail window on the left, a letter being read beside it, each as wide as its window, the bags taking the rest.
-- The letter is always in the layout; while none is open it is left out and the others keep their widths.
ns.Board.Occasion("mail", ns.TEXT.talkMail, function(width)
    local pad, edge = Core.Board.PAD, Core.Board.EDGE
    local mail = math.ceil(Post.Width()) + 2 * edge
    local letter = math.ceil(Letter.Width()) + 2 * edge
    local reading = Letter.Present()
    local rest = (width or 0) - (reading and 4 or 3) * pad - mail - (reading and letter or 0)
    return { split = "x", parts = { { key = "mail" }, { key = "letter" }, { key = "bags" } },
             shares = { mail, letter, math.max(rest, mail) } }
end)

-- The bags on the left, the bank on the right, sharing the screen.
ns.Board.Occasion("bank", ns.TEXT.talkBank, function()
    return { split = "x", parts = { { key = "bags" }, { key = "bank" } }, shares = { 1, 1 } }
end)

function Talks.Start()
    Shop.Follow()
    Post.Follow()
    Letter.Follow()
    ns.On("BANKFRAME_OPENED", function() Talks.Began("bank") end)
    ns.On("BANKFRAME_CLOSED", function() Talks.Ended("bank") end)
end
