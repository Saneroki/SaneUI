local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Guild
--  The module's own table (ns in all its files), its words, its settings, how
--  it starts and how it stands down.
--
--  An addon of its own (SaneUI_Guild): it needs Core and nothing else, and is
--  switched on and off in the game's addon list. The plan is Doc/ideas/Guild.md.
--
--  Everything a guild needs in one window: its page (Page.lua) with the
--  guild's crest, its tabs and their views. The page stands on Social's full
--  screen, offered to Social's board as its guild window (Core.Board.Offer), and
--  the guild key opens it there; while Social is off, in a window of its own
--  (Window.lua). The game's guild window stays as it is: its micro menu button
--  still opens it.
--
--  The data is Core's (Core.Data.Guild): the roster and its history, and what
--  members share with the guild, each kind behind a switch here. This module
--  only reads it, and tells Core what the player allows.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Guild", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = Core.Word("GUILD", "Guild"),
    noGuild = Core.Word("ERR_GUILD_PLAYER_NOT_IN_GUILD", "You are not in a guild."),
    noGuildHint = "Join a guild, and its roster, its members' gear, quests, runs and loot come here.",
    sync = "Sync",
    syncTip = "Ask the guild for what is newer: the roster, and what members share.",
    synced = "Synced %s",
    neverSynced = "Not synced yet",
    settings = Core.Word("SETTINGS", "Settings"),
    online = "%d online",
    members = "%d members",
    membersOnline = "%d members · %d online",
    -- The tabs and their views (Page.lua)
    overview = "Overview",
    guild = Core.Word("GUILD", "Guild"),
    roster = "Roster",
    equipment = "Equipment",
    bank = Core.Word("GUILD_BANK", "Guild Bank"),
    handbook = "Handbook",
    quests = Core.Word("QUESTS_LABEL", "Quests"),
    dungeons = Core.Word("DUNGEONS", "Dungeons"),
    runs = "Runs",
    together = "Together",
    loot = Core.Word("LOOT", "Loot"),
    session = "Session",
    history = Core.Word("HISTORY", "History"),
    wishlist = "Wishlist",
    rules = "Rules",
    professions = Core.Word("TRADE_SKILLS", "Professions"),
    raid = Core.Word("RAID", "Raid"),
    plan = "Plan",
    numbers = "Numbers",
    officers = "Officers",
    mains = "Mains and Alts",
    promotions = "Promotions",
    notices = "Notices",
    -- Overview
    whoIsWhere = "Who Is Where",
    nobodyOnline = "Nobody else of the guild is online.",
    questRequests = "Quest Requests",
    plannedRuns = "Planned Runs",
    news = "News",
    guildChat = Core.Word("GUILD_CHAT", "Guild Chat"),
    offered = "Offered to the Guild",
    race = "Race to the Top",
    noNews = "Nothing new in the guild lately.",
    newsJoin = "%s joined the guild",
    newsLeave = "%s left the guild",
    newsUp = "%s was promoted to %s",
    newsDown = "%s was demoted to %s",
    newsLevel = "%s reached level %d",
    noLevels = "No levels known yet.",
    -- Roster
    search = Core.Word("SEARCH", "Search"),
    searchRoster = "Name, note or zone",
    colName = Core.Word("NAME", "Name"),
    colLevel = Core.Word("LEVEL_ABBR", "Lvl"),
    colRank = Core.Word("RANK", "Rank"),
    colZone = Core.Word("ZONE", "Zone"),
    colNote = Core.Word("LABEL_NOTE", "Note"),
    colSeen = "Last Online",
    groupOnline = "Online · %d",
    groupOffline = "Offline · %d",
    shown = "%d of %d",
    here = "here",
    seenNow = Core.Word("GUILD_ONLINE_LABEL", "Online"),
    seenToday = "today",
    seenDays = "%d days ago",
    seenMonths = "%d months ago",
    motd = Core.Word("GUILD_MOTD_LABEL", "Message of the Day"),
    noMotd = "No message of the day.",
    guildInfo = Core.Word("GUILD_INFORMATION", "Guild Information"),
    gameWindow = "The Game's Guild Window",
    invite = Core.Word("INVITE", "Invite"),
    inviteGuild = Core.Word("GUILD_INVITE", "Invite to Guild"),
    inviteAsk = "Name of the player to invite to the guild:",
    whisper = Core.Word("WHISPER", "Whisper"),
    player = "Player",
    promote = Core.Word("GUILD_PROMOTE", "Promote"),
    demote = Core.Word("GUILD_DEMOTE", "Demote"),
    rankUp = "Up: %s",
    rankDown = "Down: %s",
    note = Core.Word("LABEL_NOTE", "Note"),
    officerNote = Core.Word("OFFICER_NOTE_COLON", "Officer's Note"),
    noteEdit = "Click to change the note.",
    noteAsk = "The note of %s:",
    officerNoteAsk = "The officer's note of %s:",
    memberHistory = Core.Word("HISTORY", "History"),
    noHistory = "Nothing noted since Sane UI first read the roster.",
    joinedOn = "In the guild since %s",
    pickMember = "Choose a member in the list.",
    inFight = "Not in a fight: the game does not let addons do that now.",
    -- Equipment
    characters = Core.Word("CHARACTER", "Characters"),
    searchCharacters = "Name",
    itemLevel = Core.Word("STAT_AVERAGE_ITEM_LEVEL", "Item Level"),
    slotsWorn = "%d of %d slots worn",
    sharedAgo = "Shared %s · not live",
    ownLive = "Your own, live",
    noCard = "Nothing shared yet: this member's gear comes once they run Sane UI with sharing on.",
    pickCharacter = "Choose a character in the list.",
    -- Views still to come (Later.lua)
    later = "%s comes in a later step of the guild window.",
    -- Status line
    noted = "Noted: %s.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the guild window is closed; the guild key opens the game's own again"

local OPTIONS = {
    { key = "social", default = true, text = "On Social's Full Screen",
      tip = "With Social on, the guild window stands on Social's full screen, in place of the game's guild window there. Off: a window of its own.",
      header = "Window" },
    { key = "keys", default = true, text = "The Guild Key Opens It",
      tip = "Your guild key opens this window instead of the game's. The game's micro menu button still opens the game's own." },
    { key = "shareCard", default = true, text = "Share My Gear and Professions",
      tip = "Your guild sees who your characters are, what they wear and their professions, in its Sane UI. Nothing goes to anybody outside your guild, and nothing into the data Sane UI ships.",
      header = "Sharing with the Guild" },
}

Core.Options(ns.name, OPTIONS, {
    changed = function(key, value)
        if key == "shareCard" then Core.Data.Guild.Allow("card", value) end
        if key == "keys" and ns.Keys then ns.Keys.Bind() end
        if key == "social" and ns.Window then ns.Window.Rehome() end
    end,
})

-- Standing down: the guild key the game's again (first: it is the game's own), the window closed, the guild
-- window Social's own again, the roster no more asked for. Each step on its own: one failing stops no other.
function ns.GiveBack()
    if ns.Keys then ns.Safe("giving back", ns.Keys.Leave) end
    if ns.Window then ns.Safe("giving back", ns.Window.Leave) end
    ns.Safe("giving back", Core.Data.Guild.Watch, false)
end

-- A line in the page's status line (Page.lua), or in chat while it is not on show.
function ns.Say(text)
    if ns.Page and ns.Page.Status(text) then return end
    ns.Print(text)
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
    ns.Window.Offer()
end

function ns.OnLogin()
    local Guild = Core.Data.Guild
    Guild.Allow("card", ns.options.shareCard ~= false)
    Guild.Start()
    ns.Keys.Start()
    Core.Command("guild", "the guild window: open or close it", function() ns.Guarded(ns.Window.Toggle) end)
end
