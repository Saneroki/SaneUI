local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot
--  The module's own table (ns in all its files), its words, its sizes, its
--  settings, and how it stands down.
--
--  An addon of its own (SaneUI_Loot): it needs Core and nothing else, and is
--  switched on and off in the game's addon list.
--
--  It stands in for the game's loot window and its roll frames, and adds what
--  the game has not:
--    Slots.lua   what the open loot holds, as plain lines read from the game;
--                what the player's rules take at once (everything, or kinds:
--                coins, currencies, quest items, trade goods, gear,
--                consumables, junk; the player's word on an item over them;
--                an upgrade never, with Always show upgrades)
--    Chat.lua   the game's sentences about loot (received, rolled for, coins)
--                read back into their parts, by the game's own words
--    Game.lua    the game's loot window no longer told of loot, its Auto
--                Loot lent off, its roll frames held out of sight; all given
--                back
--    Row.lua     one line of the loot window
--    Window.lua  the loot window: a line a thing (Row.lua), a bar as the
--                nameplates' in its quality's colour, Link and Close, bare
--                words, at its foot;
--                at the mouse or where Edit Mode placed it; a thing taken, the
--                next comes under the mouse; the rules' things taken at once
--    Items.lua   the options' tab Your items: the things met in loot, ticked
--                where they are taken at once
--    Master.lua  the master looter's menu on a thing: who may have it, a roll
--    Full.lua    your bags full: a page beside the window with what the thing
--                is worth and the least worth thing of yours, to make room
--    Rolls.lua   a card for each roll of your group: Need, Greed, Pass (and
--                what else the game offers), the time left as a pencil line,
--                how many chose what and who
--    Feed.lua    what you and your group receive, rising over the world
--  Standing down, the game's loot window and roll frames are the game's again
--  (GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Loot", ns)

local function Word(name, fallback) return Core.Word(name, fallback) end

-- The game's names of the qualities, Poor to Heirloom.
local function Quality(index, fallback) return Word("ITEM_QUALITY" .. index .. "_DESC", fallback) end

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    link = "Link",
    linkTip = "Puts the links of the loot's things into the chat box: Enter sends them where you write.",
    close = Word("CLOSE", "Close"),
    auto = "A",
    autoOn = "Taken at once",
    autoOnTip = "On your list: taken at once wherever it drops. Click to take it off the list.",
    autoOff = "Take this at once",
    autoOffTip = "Puts it on your list, to be taken at once wherever it drops, and takes it now.",
    coins = "Coins",
    currency = Word("CURRENCY", "Currency"),
    -- the short tags under a name (Saneroki: abbreviations, not whole words)
    questItem = "Quest",
    questStarts = "Starts a quest",
    pickup = "BoP",       -- binds when picked up
    equip = "BoE",        -- binds when equipped
    use = "BoU",          -- binds when used
    account = "BoA",      -- binds to the account
    warbound = "WuE",     -- warbound until equipped
    uncollected = "Uncollected", -- an appearance the character could collect and has not
    locked = "Not yours to take now",
    onList = "On your list: taken at once wherever it drops",
    offList = "Never taken at once: your word",
    listEmpty = "Your loot list is empty. Click the A of a thing in the loot window to put it on.",
    listHead = "Your loot list (taken at once):",
    neverHead = "Never taken at once:",
    -- Edit Mode's names of the parts placed there
    window = "Loot window",
    rollsView = "Group rolls",
    feedView = "Loot feed",
    -- the master looter's menu
    give = "Give to",
    rollFor = Word("REQUEST_ROLL", "Request Roll"),
    rollForTip = "Every one of the group may roll for it; you give it to the winner afterwards.",
    -- the page beside the window with the bags full
    fullTitle = "Bags full",
    fullThis = "This one",
    fullRoom = "Make room",
    fullWorth = "Worth %s",
    fullNoWorth = "Sells for nothing",
    fullNone = "Nothing in your bags you could do without.",
    fullHow = "Click it to pick it up, then drop it on the world: the game asks before it is gone.",
    fullOf = "%d of %d",
    -- the roll cards
    need = Word("NEED", "Need"),
    greed = Word("GREED", "Greed"),
    pass = Word("PASS", "Pass"),
    disenchant = Word("ROLL_DISENCHANT", "Disenchant"),
    transmog = Word("TRANSMOGRIFY", "Transmog"),
    chose = "Chose %s:",
    -- /sane loot
    about = "the loot window's list (/sane loot list), a try of the roll cards and the feed (/sane loot try)",
    -- the options' tabs
    windowTab = "Loot window",
    takeTab = "Taken at once",
    itemsTab = "Your items",
    groupTab = "Rolls and feed",
    -- the options
    windowHeader = "Loot window",
    windowSwitch = "Sane UI's loot window",
    windowSwitchTip = "What a corpse, a chest or a catch holds, a line a thing, a bar as the nameplates draw theirs in its quality's colour (a quest's in gold): its picture, its name (a green arrow in front of it on an upgrade) and an A to take it at once from now on. Link and Close at the foot. A click takes a thing and the next comes under the mouse. While it is on, the game's own Auto Loot is off: the switches Taken at once decide (Shift while looting still takes everything). Off: the game's own loot window.",
    atMouse = "At the mouse",
    atMouseTip = "The loot window opens where the mouse is, its first thing under it. Off: where you placed it in Edit Mode (Esc > Edit Mode).",
    notes = "A line under each name",
    notesTip = "Under each thing's name, small: how it binds, short (BoP red, BoE orange), Uncollected in light blue where you could collect its look and have not, its kind or a quest's, and what a vendor pays for it.",
    showUpgrades = "Always show upgrades",
    showUpgradesTip = "A thing that would make your character better (gear you can wear now, where you wear nothing or something of a lower item level) is never taken at once, whatever the switches below and your word on it say: it waits in the loot window, a green arrow in front of its name.",
    upgradeEmpty = "An upgrade: you wear nothing there",
    upgradeBetter = "An upgrade: a higher item level than what you wear there",
    takeHeader = "Taken at once",
    takeHeaderTip = "What is taken as soon as the loot opens, without a click, as fast as the game lets it; the rest waits in the loot window. At first coins, currencies, quest items and junk. Never a thing locked to a roll, and only by Everything one that binds when picked up (the game asks first); your word on an item (its A, the tab Your items) goes over them.",
    takeAll = "Everything",
    takeAllTip = "Every thing the loot holds is taken at once, whatever the switches below say; for one that binds when picked up the game asks first. Speed Leveling's switch Take all loot sets this.",
    takeCoins = "Coins",
    takeCoinsTip = "Money is taken at once.",
    takeCurrency = "Currencies",
    takeCurrencyTip = "Currencies (tokens, marks, badges) are taken at once.",
    takeQuest = "Quest items",
    takeQuestTip = "Things a quest of yours wants, and things that begin a quest, are taken at once.",
    takeTrade = "Trade goods",
    takeTradeTip = "Cloth, herbs, ore, leather, meat and the other goods of the professions, and reagents, are taken at once.",
    takeGear = "Gear",
    takeGearTip = "Armour and weapons are taken at once (never one that binds when picked up).",
    takeConsumable = "Consumables",
    takeConsumableTip = "Food, drinks, potions, scrolls and bandages are taken at once.",
    takeJunk = "Junk",
    takeJunkTip = "Poor things, the grey ones only a vendor wants, are taken at once.",
    -- the tab Your items
    itemsIntro = "The things you met in loot of late, and those you gave your word on. Ticked: taken at once. A tick changes it for that item alone, over the switches of Taken at once.",
    itemsTaken = "Taken at once",
    itemsLeft = "Left for a click",
    itemsNone = "Nothing yet: what you loot comes here.",
    itemsWaiting = "Asking the game for its name...",
    whyList = "your word",
    whyNever = "your word: never",
    whyAll = "Everything",
    itemsForget = "Forget the rest",
    itemsForgetTip = "Takes the things you gave no word on off this list (until you loot them again).",
    rollsHeader = "Group rolls",
    rolls = "Sane UI's roll cards",
    rollsTip = "When your group rolls for a thing: a card on the page with its picture and name, Need, Greed and Pass (Disenchant or Transmog when the game offers them), the time left as a pencil line that shrinks. Placed in Edit Mode. Off: the game's own roll frames.",
    tally = "Who chose what",
    tallyTip = "On each choice of a card, how many of your group took it; the mouse on it names them. Read from the game's own lines about the rolls.",
    feedHeader = "Loot feed",
    feed = "What you receive",
    feedTip = "Each thing you receive, also what is taken at once, rises over the world for a few seconds: its picture, its name and how many, then how many you carry. Placed in Edit Mode.",
    feedMoney = "Coins",
    feedMoneyTip = "Money you loot rises with the rest.",
    feedGroup = "Your group's",
    feedGroupTip = "What the others in your group receive rises too, with their names, from the quality below on.",
    feedQuality = "From",
    feedQualityTip = "The least quality of the group's things shown.",
    fullHeader = "Bags full",
    full = "Make room for loot",
    fullTip = "With your bags full while the loot window is open, a page beside it shows what the thing is worth, and the thing of yours worth the least at a vendor (arrows go through the others). Click it to pick it up; drop it on the world to get rid of it. And one slot of your bags stays free: your cheapest junk is destroyed at your next key press, with a warning on the screen when there is no junk. Also a box at the foot of the bags.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the game's loot window, its Auto Loot and its roll frames are back"

-- Sizes in UI units, one place for the module (Doc/guides/gui-development.md, Layout).
ns.SIZE = {
    width = 330,    -- the loot window at its widest (it is as wide as its words); longer names are cut
    least = 190,    -- and at its narrowest: room for Link and Close
    row = 38,       -- a line of the loot window
    rowGap = 2,     -- between its lines
    icon = 30,      -- a thing's picture on the page beside the window with the bags full
    pad = 4,        -- over and under a line's words inside its bar
    auto = 16,      -- the A of a line
    foot = 22,      -- the buttons Link and Close
    arrow = 14,     -- the green arrow of an upgrade, in front of its name
    gap = 6,        -- between a picture and its words, and round the page's parts
    room = 0.6,     -- the most of the screen's height the window's lines take; more scroll
    seen = 60,      -- the things met in loot kept for the tab Your items, the newest first
    burst = 4,      -- slots taken at once in one frame; the rest in the frames after
    card = { 300, 50 }, -- a roll card
    cardGap = 6,    -- between roll cards
    choice = 54,    -- a choice's pencil box on a card
    feedLine = 24,  -- a line of the feed
    full = 196,     -- the page beside the window with the bags full
}

-- The qualities a choice lists, Poor to Legendary, as the game names them.
local function Qualities(first, last)
    local list = {}
    for index = first, last do list[#list + 1] = { index, Quality(index, tostring(index)) } end
    return list
end

local W, T, G = ns.TEXT.windowTab, ns.TEXT.takeTab, ns.TEXT.groupTab
local OPTIONS = {
    { key = "window", default = true, text = ns.TEXT.windowSwitch, tip = ns.TEXT.windowSwitchTip, header = ns.TEXT.windowHeader, tab = W },
    { key = "atMouse", default = true, text = ns.TEXT.atMouse, tip = ns.TEXT.atMouseTip, parent = "window", tab = W },
    { key = "notes", default = false, text = ns.TEXT.notes, tip = ns.TEXT.notesTip, parent = "window", tab = W },
    { key = "full", default = true, text = ns.TEXT.full, tip = ns.TEXT.fullTip, header = ns.TEXT.fullHeader, tab = W },
    { key = "showUpgrades", default = true, text = ns.TEXT.showUpgrades, tip = ns.TEXT.showUpgradesTip, parent = "window",
      header = ns.TEXT.takeHeader, headerTip = ns.TEXT.takeHeaderTip, tab = T },
    { key = "takeAll", default = false, text = ns.TEXT.takeAll, tip = ns.TEXT.takeAllTip, parent = "window", tab = T },
    { key = "takeCoins", default = true, text = ns.TEXT.takeCoins, tip = ns.TEXT.takeCoinsTip, parent = "window", tab = T },
    { key = "takeCurrency", default = true, text = ns.TEXT.takeCurrency, tip = ns.TEXT.takeCurrencyTip, parent = "window", tab = T },
    { key = "takeQuest", default = true, text = ns.TEXT.takeQuest, tip = ns.TEXT.takeQuestTip, parent = "window", tab = T },
    { key = "takeTrade", default = false, text = ns.TEXT.takeTrade, tip = ns.TEXT.takeTradeTip, parent = "window", tab = T },
    { key = "takeGear", default = false, text = ns.TEXT.takeGear, tip = ns.TEXT.takeGearTip, parent = "window", tab = T },
    { key = "takeConsumable", default = false, text = ns.TEXT.takeConsumable, tip = ns.TEXT.takeConsumableTip, parent = "window", tab = T },
    { key = "takeJunk", default = true, text = ns.TEXT.takeJunk, tip = ns.TEXT.takeJunkTip, parent = "window", tab = T },
    { key = "kept", default = {} }, -- the player's word on items: [item ID] = true taken at once, false never
    { key = "seen", default = {} }, -- the items met in loot of late, the newest first (IDs only; the tab Your items)
    { key = "lent", default = {} }, -- the game's settings the window lends while it is on: [name] = { was, set }
    { key = "rolls", default = true, text = ns.TEXT.rolls, tip = ns.TEXT.rollsTip, header = ns.TEXT.rollsHeader, tab = G },
    { key = "tally", default = true, text = ns.TEXT.tally, tip = ns.TEXT.tallyTip, parent = "rolls", tab = G },
    { key = "feed", default = true, text = ns.TEXT.feed, tip = ns.TEXT.feedTip, header = ns.TEXT.feedHeader, tab = G },
    { key = "feedMoney", default = true, text = ns.TEXT.feedMoney, tip = ns.TEXT.feedMoneyTip, parent = "feed", tab = G },
    { key = "feedGroup", default = true, text = ns.TEXT.feedGroup, tip = ns.TEXT.feedGroupTip, parent = "feed", tab = G },
    { key = "feedQuality", default = 2, text = ns.TEXT.feedQuality, tip = ns.TEXT.feedQualityTip,
      choices = Qualities(0, 5), parent = { "feed", "feedGroup" }, tab = G },
}
Core.Options(ns.name, OPTIONS, {
    changed = function(key)
        if key == "window" or key == "rolls" then
            ns.Guarded(ns.Game.Update)
        elseif key == "atMouse" then
            ns.Guarded(ns.Window.Place)
        elseif key == "notes" then
            ns.Guarded(ns.Window.Fill)
        elseif key == "full" then
            ns.Guarded(ns.Full.Update)
            Core.SwitchChanged() -- its box in the bags
        end
        if key == "kept" or key == "showUpgrades" or key:find("^take") then ns.Guarded(ns.Items.Refresh) end
    end,
    -- the list of items, after the switches' tabs
    tabs = { { name = ns.TEXT.itemsTab, build = function(child) return ns.Items.Build(child) end } },
})

-- Standing down: the game's loot window and roll frames are the game's again, ours out of sight.
function ns.GiveBack()
    ns.Safe("give back", ns.Window.GiveBack)
    ns.Safe("give back", ns.Rolls.GiveBack)
    ns.Safe("give back", ns.Feed.GiveBack)
    ns.Game.GiveBack()
end

-- The player's word on items: those taken at once, then those never, by name.
local function List()
    local kept, taken, never = ns.options.kept, {}, {}
    for id, word in pairs(type(kept) == "table" and kept or {}) do
        local into = word and taken or never
        into[#into + 1] = ns.Slots.Name(id) or ("item " .. tostring(id))
    end
    if #taken == 0 and #never == 0 then return ns.Print(ns.TEXT.listEmpty) end
    table.sort(taken)
    table.sort(never)
    if #taken > 0 then ns.Print(ns.TEXT.listHead .. " " .. table.concat(taken, ", ")) end
    if #never > 0 then ns.Print(ns.TEXT.neverHead .. " " .. table.concat(never, ", ")) end
end

-- /sane loot: the list; /sane loot try: a roll card and the feed as they will look.
local function Command(rest)
    if rest == "try" then
        ns.Rolls.Try()
        ns.Feed.Try()
    else
        List()
    end
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
    for _, key in ipairs({ "kept", "seen", "lent" }) do
        if type(ns.options[key]) ~= "table" then ns.options[key] = {} end
    end
    Core.Command("loot", ns.TEXT.about, ns.Guard(Command))
end

function ns.OnLogin()
    ns.Window.Start()
    ns.Rolls.Start()
    ns.Feed.Start()
    ns.Full.Start()
    ns.Game.Update()
end
