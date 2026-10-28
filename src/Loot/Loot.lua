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
--                what the player's rules take at once (coins and currencies,
--                quest items, the things on the player's list, everything up
--                to a quality; never what binds when picked up)
--    Chat.lua    the game's sentences about loot (received, rolled for, coins)
--                read back into their parts, by the game's own words
--    Game.lua    the game's loot window no longer told of loot, its roll
--                frames held out of sight; both given back
--    Row.lua     one line of the loot window
--    Window.lua  the loot window: a page of the journal (Core.Journal), its
--                title the thing looted, a line a thing, Take all at its foot;
--                at the mouse or where Edit Mode placed it
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
    title = Word("LOOT", "Loot"),
    takeAll = "Take all",
    takeAllTip = "Takes every thing the loot holds, as a click on each would.",
    empty = "Nothing left",
    fishing = Word("PROFESSIONS_FISHING", "Fishing"),
    coins = "Coins",
    currency = Word("CURRENCY", "Currency"),
    questItem = Word("ITEM_BIND_QUEST", "Quest Item"),
    questStarts = Word("ITEM_STARTS_QUEST", "This Item Begins a Quest"),
    pickup = Word("ITEM_BIND_ON_PICKUP", "Binds when picked up"),
    equip = Word("ITEM_BIND_ON_EQUIP", "Binds when equipped"),
    use = Word("ITEM_BIND_ON_USE", "Binds when used"),
    locked = "Not yours to take now",
    onList = "On your list: taken at once wherever it drops",
    listed = "%s is on your loot list now: taken at once wherever it drops.",
    unlisted = "%s is off your loot list.",
    listEmpty = "Your loot list is empty. Alt-click a thing in the loot window to put it on.",
    listHead = "Your loot list (taken at once):",
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
    nobody = "Nobody yet",
    chose = "Chose %s:",
    yours = "You chose %s.",
    won = "%s won it",
    -- /sane loot
    about = "the loot window's list (/sane loot list), a try of the roll cards and the feed (/sane loot try)",
    -- the options
    windowHeader = "Loot window",
    windowSwitch = "Sane UI's loot window",
    windowSwitchTip = "What a corpse, a chest or a catch holds, on a page of the journal. A click takes a thing; Shift-click links it in the chat, Ctrl-click tries it on, Alt-click puts it on your loot list or takes it off. Off: the game's own loot window.",
    atMouse = "At the mouse",
    atMouseTip = "The loot window opens where the mouse is, its first thing under it. Off: where you placed it in Edit Mode (Esc > Edit Mode).",
    notes = "A line under each name",
    notesTip = "Under each thing's name, small: whether it binds, its kind, and whether a quest wants it.",
    takeHeader = "Taken at once",
    takeHeaderTip = "What the loot window takes as soon as it opens, without a click. The game's own Auto Loot (Esc > Options > Controls) takes everything, whatever these say.",
    takeCoins = "Coins and currencies",
    takeCoinsTip = "Money and currencies are taken at once.",
    takeQuest = "Quest items",
    takeQuestTip = "Things a quest of yours wants, and things that begin a quest, are taken at once.",
    takeKept = "Your loot list",
    takeKeptTip = "The things on your list are taken at once. Alt-click a thing in the loot window to put it on the list or take it off; /sane loot list shows it.",
    takeUpTo = "Everything up to",
    takeUpToTip = "Every thing of that quality or below is taken at once. Never one that binds when picked up: the game asks you first.",
    takeNothing = "Nothing more",
    rollsHeader = "Group rolls",
    rolls = "Sane UI's roll cards",
    rollsTip = "When your group rolls for a thing: a card on the page with its picture and name, Need, Greed and Pass (Disenchant or Transmog when the game offers them), the time left as a pencil line that shrinks. Placed in Edit Mode. Off: the game's own roll frames.",
    tally = "Who chose what",
    tallyTip = "On each choice of a card, how many of your group took it; the mouse on it names them. Read from the game's own lines about the rolls.",
    feedHeader = "Loot feed",
    feed = "What you receive",
    feedTip = "Each thing you receive rises over the world for a few seconds: its picture, its name and how many, then how many you carry. Placed in Edit Mode.",
    feedMoney = "Coins",
    feedMoneyTip = "Money you loot rises with the rest.",
    feedGroup = "Your group's",
    feedGroupTip = "What the others in your group receive rises too, with their names, from the quality below on.",
    feedQuality = "From",
    feedQualityTip = "The least quality of the group's things shown.",
    fullHeader = "Bags full",
    full = "Make room for loot",
    fullTip = "With your bags full while the loot window is open, a page beside it shows what the thing is worth, and the thing of yours worth the least at a vendor (arrows go through the others). Click it to pick it up; drop it on the world to get rid of it.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the game's loot window and roll frames are back"

-- Sizes in UI units, one place for the module (Doc/guides/gui-development.md, Layout).
ns.SIZE = {
    width = 236,    -- the loot window's page: room for a picture, a name and its note
    row = 34,       -- a line of the loot window
    icon = 28,      -- a thing's picture in its pencil slot
    gap = 6,        -- between a picture and its words, and round the page's parts
    foot = 28,      -- the foot with Take all
    room = 0.6,     -- the most of the screen's height the window's page takes; more lines scroll
    card = { 300, 50 }, -- a roll card
    cardGap = 6,    -- between roll cards
    choice = 54,    -- a choice's pencil box on a card
    feedLine = 24,  -- a line of the feed
    full = 196,     -- the page beside the window with the bags full
}

-- The qualities a choice lists, Poor to Legendary, as the game names them.
local function Qualities(first, last, extra)
    local list = extra and { extra } or {}
    for index = first, last do list[#list + 1] = { index, Quality(index, tostring(index)) } end
    return list
end

local OPTIONS = {
    { key = "window", default = true, text = ns.TEXT.windowSwitch, tip = ns.TEXT.windowSwitchTip, header = ns.TEXT.windowHeader },
    { key = "atMouse", default = true, text = ns.TEXT.atMouse, tip = ns.TEXT.atMouseTip, parent = "window" },
    { key = "notes", default = true, text = ns.TEXT.notes, tip = ns.TEXT.notesTip, parent = "window" },
    { key = "takeCoins", default = true, text = ns.TEXT.takeCoins, tip = ns.TEXT.takeCoinsTip,
      header = ns.TEXT.takeHeader, headerTip = ns.TEXT.takeHeaderTip },
    { key = "takeQuest", default = true, text = ns.TEXT.takeQuest, tip = ns.TEXT.takeQuestTip },
    { key = "takeKept", default = true, text = ns.TEXT.takeKept, tip = ns.TEXT.takeKeptTip },
    { key = "takeUpTo", default = -1, text = ns.TEXT.takeUpTo, tip = ns.TEXT.takeUpToTip,
      choices = Qualities(0, 3, { -1, ns.TEXT.takeNothing }) },
    { key = "kept", default = {} }, -- the player's loot list: [item ID] = true (Alt-click in the window)
    { key = "rolls", default = true, text = ns.TEXT.rolls, tip = ns.TEXT.rollsTip, header = ns.TEXT.rollsHeader },
    { key = "tally", default = true, text = ns.TEXT.tally, tip = ns.TEXT.tallyTip, parent = "rolls" },
    { key = "feed", default = true, text = ns.TEXT.feed, tip = ns.TEXT.feedTip, header = ns.TEXT.feedHeader },
    { key = "feedMoney", default = true, text = ns.TEXT.feedMoney, tip = ns.TEXT.feedMoneyTip, parent = "feed" },
    { key = "feedGroup", default = true, text = ns.TEXT.feedGroup, tip = ns.TEXT.feedGroupTip, parent = "feed" },
    { key = "feedQuality", default = 2, text = ns.TEXT.feedQuality, tip = ns.TEXT.feedQualityTip,
      choices = Qualities(0, 5), parent = { "feed", "feedGroup" } },
    { key = "full", default = true, text = ns.TEXT.full, tip = ns.TEXT.fullTip, header = ns.TEXT.fullHeader },
}
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "window" or key == "rolls" then
        ns.Guarded(ns.Game.Update)
    elseif key == "atMouse" then
        ns.Guarded(ns.Window.Place)
    elseif key == "notes" then
        ns.Guarded(ns.Window.Fill)
    elseif key == "full" then
        ns.Guarded(ns.Full.Update)
    end
end })

-- Standing down: the game's loot window and roll frames are the game's again, ours out of sight.
function ns.GiveBack()
    ns.Safe("give back", ns.Window.GiveBack)
    ns.Safe("give back", ns.Rolls.GiveBack)
    ns.Safe("give back", ns.Feed.GiveBack)
    ns.Game.GiveBack()
end

-- The loot list: its things by name, one line each.
local function List()
    local kept, names = ns.options.kept, {}
    for id in pairs(type(kept) == "table" and kept or {}) do
        names[#names + 1] = ns.Slots.Name(id) or ("item " .. tostring(id))
    end
    if #names == 0 then return ns.Print(ns.TEXT.listEmpty) end
    table.sort(names)
    ns.Print(ns.TEXT.listHead .. " " .. table.concat(names, ", "))
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
    if type(ns.options.kept) ~= "table" then ns.options.kept = {} end
    Core.Command("loot", ns.TEXT.about, ns.Guard(Command))
end

function ns.OnLogin()
    ns.Window.Start()
    ns.Rolls.Start()
    ns.Feed.Start()
    ns.Full.Start()
    ns.Game.Update()
end
