local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Economy
--  The module's own table (ns in all its files), its words, its sizes, its
--  settings, and how it stands down.
--
--  An addon of its own (SaneUI_Economy): it needs Core and nothing else, and is
--  switched on and off in the game's addon list. What it shows is Core's: the
--  scans, the prices, the forecast, the fees and the characters' things. It
--  gathers and keeps no data of its own.
--
--  It adds to the game's auction house window, which stays the game's:
--    Deals.lua   what is worth buying and what worth selling right now
--    Live.lua    what the server says of the items in sight, a search at a time
--    Trade.lua   a purchase and a post, each from a click of the player
--    Tab.lua     the tab Deals, its two columns, the gold on sale in the corner
--  and to the game's mail window, which stays the game's too:
--    Banker.lua  the tab Banker: the trade goods, reagents and profession items
--                sent to your banker, by themselves with Send by itself
--  Standing down, the tabs are gone and the windows are as the game made them
--  (GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Economy", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    tab = "Deals",
    buyHead = "Buy now",
    sellHead = "Sell now",
    onSale = "On sale: %s",
    onSaleHead = "On sale",
    onSaleTip = "What your auctions are worth together, at their buyouts: all your characters' in the last full scan, and what you posted here since. It takes in every account whose auction file is linked.",
    buy = Core.Word("AUCTION_HOUSE_BUY_ITEM_BUTTON", "Buy"),
    post = "Post",
    confirm = "Confirm",
    waiting = "...",
    gone = "Gone",
    each = "+%s each",
    total = "+%s in all",
    buyLine = "%s, sell %s for %s",
    buyLineNow = "%s, sell for %s",
    buyAway = "%s, sell at %s for %s",
    takeAway = "Sell at %s for %s",
    neutral = "the neutral AH",
    faction = "your faction's AH",
    buyCount = "%d under %s",
    sellLine = "Post at %s",
    sellHere = "%d in your bags",
    sellThere = "%s: %d",
    bank = "bank",
    accountBank = "Account bank",
    when = "%s %s-%s",
    today = "Today",
    confirmLine = "%d for %s: click again to buy",
    dearer = "The price went up: not bought",
    noMoney = "Not enough gold",
    bought = "Bought",
    posted = "Posted",
    noPost = "Not posted: try it on the Sell tab",
    noBuys = "Nothing cheap enough right now.",
    fewBuys = "Prices build up with your full scans: an item needs %d days of them, and sales seen.",
    noSells = "Nothing of yours is worth selling right now.",
    noScan = "Keep the auction house open: its first full scan is on the way.",
    dealsFirst = "Open on Deals",
    dealsFirstTip = "The auction house opens on the tab Deals. Off: on the game's own first tab.",

    -- The tab Banker on the mail window
    banker = "Banker",
    bankerTo = Core.Word("MAIL_TO_LABEL", "To:"),
    bankerKept = "Remembered for your %s characters on %s",
    bankerNoName = "Type your banker's name above: every trade good, reagent and profession item in your bags goes to it with one Send.",
    bankerMe = "This is your banker: your other characters send to it.",
    bankerNothing = "No trade goods, reagents or profession items in your bags.",
    bankerStacks = "%d stacks",
    bankerStays = "stays with you",
    bankerTick = "Goes to your banker",
    bankerTickTip = "Untick what you keep: it stays in your bags at every mailbox until you tick it again.",
    bankerCount = "%s in %s",
    bankerOne = { "stack", "stacks" },
    bankerMail = { "mail", "mails" },
    bankerSend = Core.Word("SEND_LABEL", "Send"),
    bankerSending = "Sending...",
    bankerAgain = "Send again",
    bankerSubject = "Trade goods and profession items",
    bankerOf = "%s (%d/%d)",
    bankerSent = "Sent to %s: %s",
    bankerSlow = "The mail has not gone yet: Send tries again.",
    bankerRefused = "Not sent: %s",
    bankerFailed = "Not sent: the game refused the mail.",
    bankerPostage = "Not sent: the postage is %s.",
    bankerAttached = "Not sent: take the items off the Send Mail tab first.",
    bankerCursor = "Not sent: put down what is on your cursor first.",
    bankerNone = "Not sent: none of it could be put into a mail.",
    bankerFirst = "Open on Banker",
    bankerFirstTip = "The mailbox opens on the tab Banker, unless you play your banker or nothing would go to it. Off: on the inbox.",
    bankerAuto = "Send by itself",
    bankerAutoTip = "At the mailbox all that goes to your banker is sent at once, without a click on Send; Shift held as you open the mailbox leaves it to you. On in the profile Speedleveling.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the auction house and mail windows are as the game made them"

-- Sizes in UI units, one place for the module (Doc/guides/gui-development.md, Layout).
ns.SIZE = {
    top = 26,       -- from the window's top to the tab's page
    side = 4,       -- from the window's sides
    bottom = 27,    -- from its foot, over the bar with your gold
    gap = 6,        -- between the columns
    head = 34,      -- a column's caption: the lists start under the window's round portrait
    portrait = 60,  -- how far that reaches in from the window's left, past the left caption
    row = 42,       -- a line of a column
    icon = 32,      -- its picture
    noteWide = 270, -- how far its small words reach, past the picture: they stop short of the button
    button = 62,    -- its button's width
    buttonHigh = 22, -- and height
    corner = 34,    -- the gold on sale, from the window's right end
    cornerHigh = 20, -- and how high it is
    scrollbar = 18, -- what a list leaves for its scroll bar
    -- The tab Banker on the mail window
    banker = {
        top = 24,       -- from the window's top to our page
        left = 4,       -- from its left side
        right = 6,      -- from its right side
        bottom = 4,     -- from its foot
        portrait = 62,  -- how far the window's round portrait reaches in, past it the name's box
        label = 26,     -- the room for "To:" before the box
        box = 190,      -- the box's width
        boxHigh = 20,   -- and height
        head = 60,      -- from our page's top to the list: the box and two lines of its note
        foot = 34,      -- under the list: the count, the words, the button
        row = 30,       -- a line of the list
        tick = 24,      -- its tick
        icon = 24,      -- its picture
        button = 90,    -- the button Send
        buttonHigh = 22,
    },
}

-- An item's name, asked of the game (loaded for later if it does not know it yet: "?" until then), and the
-- colour of its quality; for the lines of both tabs.
function ns.NameOf(id)
    local name = Core.Plain(Core.Ask(C_Item.GetItemNameByID, id))
    if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return name or "?"
end

function ns.Color(id)
    local quality = Core.Plain(Core.Ask(C_Item.GetItemQualityByID, id))
    local color = quality and rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[quality]
    if color then return color.r, color.g, color.b end
    return 1, 1, 1
end

Core.Options(ns.name, {
    { key = "dealsFirst", default = true, text = ns.TEXT.dealsFirst, tip = ns.TEXT.dealsFirstTip },
    { key = "bankerFirst", default = true, text = ns.TEXT.bankerFirst, tip = ns.TEXT.bankerFirstTip },
    -- On in the profile Speedleveling (Core's Presets.lua), off elsewhere at first.
    { key = "bankerAuto", default = false, text = ns.TEXT.bankerAuto, tip = ns.TEXT.bankerAutoTip },
}, {})

-- Standing down: the tabs are gone, the windows as the game made them.
function ns.GiveBack()
    ns.Safe("give back", ns.Tab.GiveBack)
    ns.Safe("give back", ns.Banker.GiveBack)
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
    -- What the module keeps besides its settings: the bankers' names and the items kept back (Banker.lua).
    ns.store = Core.Store(ns.name)
end

function ns.OnLogin()
    ns.Live.Start()
    ns.Trade.Start()
    ns.Tab.Start()
    ns.Banker.Start()
end
