local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - QuestLog
--  The quest log, a window of its own over the full map and on the screen alone (on
--  or off by the full map's bar's button, TopBar.lua). Our own
--  list (the game's belongs to its map window, which stays closed), read from
--  the game's quest log: each quest with its level, its objectives under it, no
--  mark before it and no tick after it (Saneroki 2026-10-30). A + on the level says
--  it is meant for a group, as WoW: Forever's own log writes it ([60+], Saneroki 2026-10-30).
--  Built again once a frame after the game says the log changed, and only while
--  it is in sight.
--
--  Its title bar says how many quests the log holds of how many it may, and how
--  they are sorted, no more; a click on those words sorts them the next way, kept
--  (Saneroki 2026-10-29), a click on the title bar beside them folds the list away
--  and opens it again, kept (Saneroki 2026-10-30):
--      Proximity     the nearest first, as the game measures the way to each (first; looked at again every
--                    QuestLog.RESORT seconds while in sight, drawn anew once the order changed)
--      Level         the lowest first
--      Zone          the game's own order: its zones as headers, each quest under its zone, always: how the game's
--                    own log keeps its headers folded is that log's (Saneroki 2026-10-30)
--      Type          under the game's tag of each (Elite, Group, Dungeon, ...; the rest Normal)
--  A quest done keeps one objective: to be turned in, in the game's words ("Report back to ..."), never left out.
--
--      a header      over the full map a click folds it in or out, kept (Zone); on the screen alone none is folded
--      an objective  how many, the game's sword (to kill) or sack (to loot or find) and its name: 4/7 <sack>: Nightstalker
--                    (Saneroki 2026-10-30); words without a count as the game has them
--      a quest       a click: its text unfolds under it, or folds away again (Saneroki 2026-10-30), a moment later,
--                    once no second click came; the game's arrow leads to it, and the map moves to its objective,
--                    where the map shows it (its question mark, or the middle of the area where its foes are), at
--                    the zoom it has, as a drag would move it (Canvas.LookAt). A double click: the same but for its
--                    text, which stays as it was, and the game's map pin there, so the golden line leads there. Shift
--                    and a click: watched or not (the game's objective tracker); the chat link's modifier, where
--                    something takes it: its link into the chat instead; the right button: a menu (its text, the map at its
--                    objective with its zone whole, watch, share, abandon after a question). The mouse over
--                    it: its area on the map (Areas.lua). The item it wants used, as the game's tracker shows
--                    one, stands at the far end of its row (The quests' items)
--      under it      a quest's text, by a click on it, from its menu or by a click on its pin on the map, one quest's
--                    at a time, on a dark panel: its story, what it asks and what it gives, each under its heading in
--                    gold. What it gives: experience and coin in words, its things as big icons with their names, two
--                    side by side where they fit (The rewards). A click there or on the quest folds it away
--      previews      ghosts: quests of Core's data a click on their giver's exclamation mark on the map added, not in
--                    the game's log (QuestLog.Preview): on top, under Not in your log, each between a red exclamation
--                    mark and the game's red X, which say so; the rest as any quest (Saneroki 2026-10-30). That X or the
--                    right button takes one out, the X on Not in your log all of them; one taken from its giver
--                    meanwhile goes by itself. A click unfolds
--                    what the data knows of it (why it is not for you yet, its level, who gives and takes it, what it
--                    asks first, its objectives, its rewards) and moves the map to its giver, a double click puts the
--                    game's map pin there. Kept until the next /reload
--
--  It reads from the screen's edge inwards (Saneroki 2026-10-30): on the screen's left half its words at the
--  left and the items at the right; on the right half (or docked at its right edge) mirrored, its title and words
--  right aligned, the items at the left.
--
--  No scroll bar at rest: the mouse wheel scrolls the list. While the mouse is on the window and the list is
--  longer than its room, the game's thin scroll bar shows at the side the window stands at (docked at the
--  screen's left edge: at its left), in the room of the window's edge; on the screen alone, where the list stands
--  close to that edge, at the other side.
--
--  The window (one of Core's): moved by its title bar, docked at a screen edge,
--  sized by its corner's grip while the mouse is on it. No buttons on its low title
--  bar: the button Quest Log on the full map's bar is its one switch, in both looks,
--  kept (Saneroki 2026-10-30). Two looks, each with its own place and size, kept
--  (Saneroki 2026-10-29):
--      over the full map    its dark background, to be read over the map, which is not clicked through it;
--                           every objective, the done ones grey
--      on the screen alone  at first in the screen's top left corner; no background, no border, no line under
--                           its title bar, only the list and its words over the game;
--                           closer to the screen's edge; clicked through but its title bar, its words and its
--                           items; the objectives done left out, the
--                           headers without their fold marks
--  On the screen alone it rests out of sight (Core.Rest, the setting Hide the quest log at rest; Saneroki, 2026-11-01):
--  it shows with the mouse on its words, title bar or items, and as your unit frames and action bars do while something
--  goes on. Its items' tray goes with it.
--  The game's quest tracker is out of sight, the log shown or off (lent to a hidden frame, Core.Lend: QuestLog.Tracker),
--  but in Edit Mode, where it is the game's to place.
--
--  Only the game's quest API (C_QuestLog, the game's quest link and share), never
--  the quest panels of the game's map: called from here they would taint its pins.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local QuestLog = {}
ns.QuestLog = QuestLog

QuestLog.WIDTH, QuestLog.HEIGHT = 320, 640 -- the window's first size
QuestLog.LEAST = 220      -- its least width and height
QuestLog.FIRST = { x = 12, y = -84 } -- its first place, from the screen's top left: under the map's bar
QuestLog.FIRST_SMALL = { x = 0, y = 0 } -- on the screen alone: the screen's top left corner
QuestLog.SORTS = { "proximity", "level", "zone", "type" } -- a click on its title: the next of them, round
QuestLog.RESORT = 2       -- sorted by proximity: the order looked at again every so many seconds while in sight
QuestLog.REFLOW = 0.1     -- seconds after the last step of a size change that an open quest's text is wrapped anew
QuestLog.BACK = 0.88      -- its background's opacity over the full map (on the screen alone: none)
QuestLog.EDGE = 10        -- room inside its edges
QuestLog.EDGE_SMALL = 4   -- on the screen alone: at the side it stands at (and its title)
QuestLog.BAR = 22         -- its title bar, low: the first row stands right under its words
QuestLog.HEADER, QuestLog.QUEST, QuestLog.OBJECTIVE = 24, 20, 16 -- the rows' heights
QuestLog.ITEM = 24        -- a quest's item's button, and the height of a row with one
QuestLog.ASK = 16         -- the picture in an objective's words: as high as its row
QuestLog.OVER = 30        -- the items' frame level above the log's
QuestLog.INDENT = 10      -- an objective's words from its quest's
QuestLog.MARK = 16        -- a preview's mark at its row's start; its words after it
QuestLog.ROOM = 6         -- under a quest's words
QuestLog.SECTION = 24     -- a heading in a quest's text, with the room over it
QuestLog.INSET = 10       -- a quest's text from the sides of its panel
QuestLog.PANEL = 0.35     -- that panel's opacity over the full map, on the log's background
QuestLog.PANEL_SMALL = 0.75 -- and on the screen alone, right on the game's world
QuestLog.REWARD = 40      -- a reward's icon (the game's own: 39)
QuestLog.REWARD_WIDTH = 130 -- a reward with its name at the least: two side by side where two of these fit
QuestLog.GAP = 4          -- between rewards
QuestLog.TEXT = {
    title = Core.Word("QUEST_LOG", "Quest Log"),
    heading = "|cffffffff%d/%d|r %s", -- quests, of how many, sorted by
    sorts = { proximity = "Proximity", level = Core.Word("LEVEL", "Level"), zone = Core.Word("ZONE", "Zone"),
              type = Core.Word("TYPE", "Type") },
    sorted = "Sorted by %s",
    sortNext = "A click sorts them by %s.",
    fold = "A click beside these words hides the list.",
    unfold = "A click beside these words shows the list.",
    normal = "Normal", -- the type of a quest the game gives no tag
    ready = Core.Word("QUEST_WATCH_QUEST_READY", "Ready for turn-in"),
    empty = "No quests. Quests you accept are listed here.",
    failed = Core.Word("FAILED", "Failed"),
    watch = Core.Word("TRACK_QUEST", "Track Quest"), unwatch = Core.Word("UNTRACK_QUEST", "Untrack Quest"),
    details = Core.Word("QUEST_DETAILS", "Quest Details"),
    share = Core.Word("SHARE_QUEST", "Share Quest"),
    abandon = Core.Word("ABANDON_QUEST", "Abandon Quest"),
    abandonAsk = Core.Word("ABANDON_QUEST_CONFIRM", "Abandon \"%s\"?"),
    showMap = Core.Word("SHOW_MAP", "Show Map"),
    objectives = Core.Word("QUEST_OBJECTIVES", "Quest Objectives"),
    description = Core.Word("QUEST_DESCRIPTION", "Description"),
    previews = "Not in your log",
    remove = "Take it out of the log",
    removeAll = "Take them all out of the log",
    offered = "You can take this quest.",
    level = "Level %d",
    givenBy = "Given by: %s",
    takenBy = "Turned in to: %s",
    rewards = Core.Word("QUEST_REWARDS", "Rewards"),
    choices = Core.Word("REWARD_CHOICES", "You will be able to choose one of these rewards:"),
    experience = "%s experience",
    asked = "%s/%s%s: %s", -- how many done, of how many, its picture, what
}
QuestLog.REMOVE = "xmarksthespot" -- the game's red X (ObjectIconsAtlas) on a preview's row
-- The game's tags of a quest meant for a group (Enum.QuestTag): Group (Forever's Elite), Raid, Dungeon, Heroic, Raid10, Raid25.
QuestLog.GROUP_TAGS = { [1] = true, [62] = true, [81] = true, [85] = true, [88] = true, [89] = true }
QuestLog.RIM = "Interface\\Common\\WhiteIconFrame" -- the game's frame round a reward's icon, in its quality's colour
QuestLog.PLATE = "Interface\\QuestFrame\\UI-QuestItemNameFrame" -- the game's plate behind a reward's name
QuestLog.PLATE_PART = { 10 / 128, 118 / 128, 11 / 64, 53 / 64 } -- the plate itself in that picture
-- What an objective asks, by the game's word for it and Core's: the game's mouse cursors, as the tooltips show them.
QuestLog.SWORD, QuestLog.SACK = "Interface\\CURSOR\\Attack", "Interface\\CURSOR\\LootAll"
QuestLog.ASKS = { monster = QuestLog.SWORD, player = QuestLog.SWORD, kill = QuestLog.SWORD,
                  item = QuestLog.SACK, object = QuestLog.SACK, loot = QuestLog.SACK }

local QUESTS, NPCS, OBJECTS = Core.Data.Set("Quests"), Core.Data.Set("NPCs"), Core.Data.Set("Objects")
local previews = {} -- quests shown from the map's pins (Preview), newest first
local givers = {}   -- [quest] = { map, x, y }: where the pin stood that showed it

local panel, box, view, bar, measure
local frame, handle, back
local full = false -- its look over the full map, else on the screen alone (Dress)
local mirrored = false -- it stands on the screen's right half: its words at the right, the items at the left (Sided)
local rows = {}    -- what the list shows: { kind = "header" | "quest" | "objective", ... }
local stale = true -- the log changed while out of sight
local order = ""   -- the quests in the order shown (Proximity: drawn anew once it changes)
local heading      -- the title bar's words now
local ticker       -- sorted by proximity and in sight: the order looked at again (Tick)
local away, lent   -- the hidden frame the game's quest tracker is lent to (QuestLog.Tracker)
local rest         -- on the screen alone, out of sight at rest (Core.Rest; QuestLog.Rested)
local doors = false -- the title bar is a way in for the mouse (Doors)
local chosen       -- the quest last clicked or shown, lit in the list
local open = false -- its text shows under it
local opened       -- that text's rows while they are listed (Read): the first, the last, how high they are together
local missing      -- that text names an item the game does not know yet (ITEM_DATA_LOAD_RESULT)
local AddText      -- those rows, under its quest (The chosen quest's text)
local Hover        -- the mouse came onto the window or one of its rows (The panel)

local function Plain(value)
    return Core.Plain(value)
end

-- Where a quest stands among the previews; nil for one not shown from the map's pins.
local function Previewed(quest)
    for index, each in ipairs(previews) do if each == quest then return index end end
    return nil
end

-- One of them out of the list, its text with it.
local function Gone(quest)
    table.remove(previews, Previewed(quest))
    givers[quest] = nil
    if chosen == quest then chosen, open = nil, false end
end

-------------------------------------------------------------------------------
--  Reading the game's log
-------------------------------------------------------------------------------
-- How the log is sorted (store.questLogSort): one of QuestLog.SORTS, the first unless another was chosen.
function QuestLog.Sort()
    local sort = ns.store and ns.store.questLogSort
    for _, each in ipairs(QuestLog.SORTS) do if each == sort then return sort end end
    return QuestLog.SORTS[1]
end

-- The game's log in its own order: its headers and its quests (not the hidden ones), each quest marked folded under
-- a zone folded over the full map (store.questLogFolds, by its name). And how many quests it holds.
local function Entries()
    local entries, quests, folded = {}, 0, false
    local folds = full and ns.store.questLogFolds -- (as saved: a table, or nothing at all)
    if type(folds) ~= "table" then folds = nil end
    local count = Plain(Core.Ask(C_QuestLog.GetNumQuestLogEntries)) or 0
    for index = 1, count do
        local info = Core.Ask(C_QuestLog.GetInfo, index)
        if type(info) == "table" then
            if info.isHeader then
                folded = (folds and folds[info.title]) and true or false
                entries[#entries + 1] = { kind = "header", text = info.title, index = index, collapsed = folded }
            elseif not info.isHidden and info.questID then
                quests = quests + 1
                entries[#entries + 1] = { kind = "quest", quest = info.questID, text = info.title, level = info.level,
                                          index = index, scaling = info.isScaling, folded = folded,
                                          suggested = info.suggestedGroup }
            end
        end
    end
    return entries, quests
end

-- How far the player is from a quest's next step, as the game measures it (squared); one it gives no measure of,
-- or one on another continent, after all the rest.
local function Distance(quest)
    local distance, near = Core.Ask(C_QuestLog.GetDistanceSqToQuest, quest)
    if type(distance) == "number" and near ~= false then return distance end
    return math.huge
end

-- A quest's type: the game's tag of it (Elite, Group, Dungeon, Raid, PvP, ...) and the tag's number to order the
-- types by; Normal (0, first) for one without.
local function Kind(quest)
    local tag = Core.Ask(C_QuestLog.GetQuestTagInfo, quest)
    local name = type(tag) == "table" and tag.tagName
    if type(name) == "string" and name ~= "" then return name, tonumber(tag.tagID) or 1 end
    return QuestLog.TEXT.normal, 0
end

local function Before(a, b)
    if a.key ~= b.key then return a.key < b.key end
    if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
    if (a.text or "") ~= (b.text or "") then return (a.text or "") < (b.text or "") end
    return a.quest < b.quest
end

-- The log's quests sorted that way (but Zone, the game's own): the nearest, the lowest or by type first; equal ones
-- by level, then by name. Type: each quest's group (its type's name) too.
local function Sorted(entries, sort)
    local list = {}
    for _, entry in ipairs(entries) do
        if entry.kind == "quest" then
            if sort == "proximity" then entry.key = Distance(entry.quest)
            elseif sort == "type" then entry.group, entry.key = Kind(entry.quest)
            else entry.key = entry.level or 0 end
            list[#list + 1] = entry
        end
    end
    table.sort(list, Before)
    return list
end

-- The quests' order, to tell whether it changed.
local function Order(list)
    local ids = {}
    for index, entry in ipairs(list) do ids[index] = entry.quest end
    return table.concat(ids, ",")
end

-- What a quest done asks still, in the game's words, as its quest tracker has them: its completion text ("Report
-- back to ..."), else the way the game shows to it, else Ready for turn-in.
local function TurnIn(quest, index)
    local text = Core.Ask(rawget(_G, "GetQuestLogCompletionText"), index)
    if type(text) == "string" and text ~= "" then return text end
    text = Core.Ask(C_QuestLog.GetNextWaypointText, quest)
    if type(text) == "string" and text ~= "" then return text end
    return QuestLog.TEXT.ready
end

-- The item a quest wants used, where the game's tracker shows one (QuestUtil.QuestShowsItemByIndex): its ID, its
-- picture, how many charges it has and its link; none for a quest done, unless the game keeps it then.
local function Special(index, complete)
    local link, picture, charges, keeps = Core.Ask(rawget(_G, "GetQuestLogSpecialItemInfo"), index)
    local item = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if item and (not complete or keeps) then return item, picture, charges, link end
    return nil
end

-- Whether a quest is meant for a group: the game calls it elite (Forever alone asks that), suggests a group for it or
-- tags it for one. By its ID, so a preview is asked too, though the game may not tell of one out of the log.
local function ForGroup(quest, suggested)
    if type(suggested) == "number" and suggested > 1 then return true end
    if Core.Ask(C_QuestLog.IsEliteQuest, quest) then return true end
    local tag = Core.Ask(C_QuestLog.GetQuestTagInfo, quest)
    return type(tag) == "table" and (tag.isElite or QuestLog.GROUP_TAGS[tag.tagID]) and true or false
end

-- What an objective asks as the list writes it: how many, its picture, what: "4/7 <sack>: Nightstalker".
local function Asked(kind, have, need, name)
    local picture = QuestLog.ASKS[kind]
    local mark = picture and (" |T%s:%d:%d|t"):format(picture, QuestLog.ASK, QuestLog.ASK) or ""
    return QuestLog.TEXT.asked:format(have, need, mark, name)
end

-- The same from the game's words ("Nightstalker slain: 4/7", "4/10 Gold Dust"); words without a count stay as they are.
local function Objective(objective)
    local text = objective.text
    local have, need = text:match("(%d+)%s*/%s*(%d+)")
    local name = have and text:gsub("%d+%s*/%s*%d+", "", 1):gsub("^[%s:]+", ""):gsub("[%s:]+$", ""):gsub("%s+slain$", "")
    if not name or name == "" then return text end
    return Asked(objective.type, have, need, name)
end

-- A quest's row and its objectives under it: over the full map every one, the done ones grey; on the screen alone
-- only those still to do. A quest done: its turn in last, an objective still to do in both.
local function Add(entry)
    local quest = entry.quest
    local complete = Core.Ask(C_QuestLog.IsComplete, quest) and true or false
    local failed = Core.Ask(C_QuestLog.IsFailed, quest) and true or false
    local item, picture, charges, link = Special(entry.index, complete)
    rows[#rows + 1] = { kind = "quest", quest = quest, text = entry.text, level = entry.level, index = entry.index,
                        complete = complete, failed = failed, scaling = entry.scaling,
                        group = ForGroup(quest, entry.suggested), item = item, picture = picture, charges = charges,
                        link = link, watched = (Core.Ask(C_QuestLog.GetQuestWatchType, quest)) ~= nil }
    local objectives = Core.Ask(C_QuestLog.GetQuestObjectives, quest)
    for _, objective in ipairs(type(objectives) == "table" and objectives or {}) do
        if objective.text and objective.text ~= "" and (full or not objective.finished) then
            rows[#rows + 1] = { kind = "objective", quest = quest, text = Objective(objective), done = objective.finished }
        end
    end
    if complete then
        rows[#rows + 1] = { kind = "objective", quest = quest, text = TurnIn(quest, entry.index), turnIn = true }
    end
    if open and quest == chosen then AddText(quest) end
end

-- The log as rows, sorted as chosen: the previews on top; then each quest with its objectives, under its zone's
-- header (Zone: those of a zone folded not shown, but counted) or its type's (Type), else one after the other; the
-- open quest's text under it. Returns how many quests the log holds.
local function Read()
    wipe(rows)
    opened, missing = nil, false
    -- A ghost taken from its giver meanwhile stands in the log itself now.
    for index = #previews, 1, -1 do
        local at = Core.Ask(C_QuestLog.GetLogIndexForQuestID, previews[index])
        if at and at > 0 then Gone(previews[index]) end
    end
    if chosen and not Previewed(chosen) then
        local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, chosen)
        if not index or index <= 0 then chosen, open = nil, false end
    end
    if #previews > 0 then
        rows[#rows + 1] = { kind = "header", text = QuestLog.TEXT.previews, ghosts = true }
        for _, quest in ipairs(previews) do
            rows[#rows + 1] = { kind = "preview", quest = quest, text = QUESTS:Get(quest, "name") or ("#" .. quest),
                                level = QUESTS:Get(quest, "level"),
                                group = ForGroup(quest, QUESTS:Get(quest, "groupSize")) }
            if open and quest == chosen then AddText(quest) end
        end
    end
    local entries, quests = Entries()
    local sort = QuestLog.Sort()
    if sort == "zone" then
        order = ""
        for _, entry in ipairs(entries) do
            if entry.kind == "header" then rows[#rows + 1] = entry elseif not entry.folded then Add(entry) end
        end
        return quests
    end
    local list, group = Sorted(entries, sort), nil
    order = Order(list)
    for _, entry in ipairs(list) do
        if sort == "type" and entry.group ~= group then
            group = entry.group
            rows[#rows + 1] = { kind = "header", text = group }
        end
        Add(entry)
    end
    return quests
end

-------------------------------------------------------------------------------
--  Doing
-------------------------------------------------------------------------------
-- A place on a map where the quest is done or turned in: the player's own map first, then the one the game names for
-- the quest, then the zones of every plane (the continents, Zephras Isle), then the game's next way to it. nil when
-- the game tells none.
local function Where(quest)
    local function On(map)
        for _, info in ipairs(ns.Live.Quests(map)) do
            if info.questID == quest and info.x then return map, info.x, info.y end
        end
    end
    local here = Core.Ask(C_Map.GetBestMapForUnit, "player")
    if here then
        local map, x, y = On(here)
        if map then return map, x, y end
    end
    local named = Core.Ask(rawget(_G, "GetQuestUiMapID"), quest)
    if named and named > 0 and named ~= here then
        local map, x, y = On(named)
        if map then return map, x, y end
        x, y = Core.Ask(C_QuestLog.GetNextWaypointForMap, quest, named)
        if x then return named, x, y end
    end
    for _, plane in ipairs(ns.Coords.Planes()) do
        for _, zone in ipairs(ns.Coords.Zones(plane)) do
            local map, x, y = On(zone.map)
            if map then return map, x, y end
        end
    end
    local map, x, y = Core.Ask(C_QuestLog.GetNextWaypoint, quest)
    if map and x then return map, x, y end
    return nil
end

local function Watch(quest, on)
    if on then C_QuestLog.AddQuestWatch(quest) else C_QuestLog.RemoveQuestWatch(quest) end
end

local function Share(quest)
    local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, quest)
    if index and Core.Ask(C_QuestLog.IsPushableQuest, quest) and rawget(_G, "QuestLogPushQuest") then
        QuestLogPushQuest(index)
    end
end

-- Abandoned only after a question, in the game's own dialog (Core's).
local function Abandon(quest)
    local title = Core.Ask(C_QuestLog.GetTitleForQuestID, quest) or ""
    Core.Confirm(QuestLog.TEXT.abandonAsk, title, ns.Guard(function()
        C_QuestLog.SetSelectedQuest(quest)
        C_QuestLog.SetAbandonQuest()
        C_QuestLog.AbandonQuest()
    end))
end

-- Where a quest's objective is (Where), or a preview's giver.
local function Place(quest)
    local giver = givers[quest]
    if giver then return giver[1], giver[2], giver[3] end
    return Where(quest)
end

-- The map at the quest's objective: the full screen, the zone it is in whole around it.
function QuestLog.Show(quest)
    local map, x, y = Place(quest)
    if map then ns.Window.OpenTo(map, x, y) end
end

-- The open quest's text in sight in the list: whole where it fits, else from its start.
local function Reveal()
    if not opened then return end
    local tall = opened.height >= (box:GetHeight() or 0)
    if not tall then box:ScrollToElementData(opened.last, ScrollBoxConstants.AlignNearest) end
    box:ScrollToElementData(opened.first, tall and ScrollBoxConstants.AlignBegin or ScrollBoxConstants.AlignNearest)
end

-- A quest's text under it (or none: nil), lit in the list.
function QuestLog.Text(quest)
    if quest then chosen = quest end
    open = quest ~= nil
    if quest then QuestLog.Fold(false) end
    QuestLog.Refresh()
    Reveal()
end

-- The game's arrow leads to a quest in the log; its pin on the arrow's disc at once, not only once the game tells
-- (the game's own pins read again, those of Core's data stay as they are).
local function Lead(quest)
    if not Previewed(quest) then
        C_SuperTrack.SetSuperTrackedQuestID(quest)
        ns.Pins.Changed("waypoint")
    end
end

-- The arrow leads to a quest, the map at its objective (a preview's: at its giver) in the middle, at the zoom it has.
local function Look(quest)
    Lead(quest)
    local map, x, y = Place(quest)
    if map then ns.Canvas.LookAt(map, x, y) end
end

-- One click on a quest in the list: that, and its text under it, lit in the list, or away again (Saneroki 2026-10-30).
local function Unfold(quest)
    Look(quest)
    QuestLog.Text(not (open and chosen == quest) and quest or nil)
end

-- Two: that, and the game's map pin there, so the golden line leads there; its text as it was.
local function Pin(quest)
    Look(quest)
    local map, x, y = Place(quest)
    ns.PinView.Drop({ map = map, x = x, y = y })
end

-- A plain click on a quest waits Canvas.DOUBLE for a second one, as a click on the map does: told here, not by the
-- game's OnDoubleClick, so that a double click never unfolds its text first, whichever of the list's buttons takes it.
local waiting -- the quest a first click came on, until its second came or it is too late
local function Pressed(quest)
    if waiting == quest then
        waiting = nil
        return Pin(quest)
    end
    waiting = quest
    C_Timer.After(ns.Canvas.DOUBLE, ns.Guard(function()
        if waiting ~= quest then return end
        waiting = nil
        Unfold(quest)
    end))
end

-- A click on its pin on the map: the arrow leads to it, its text under it.
function QuestLog.Focus(quest)
    Lead(quest)
    QuestLog.Text(quest)
end

-- The right button's menu: its text, the map at its objective; for a quest in the log the game's
-- choices too (watch, share, abandon), for a preview the way out of the log again.
local function Menu(owner, quest)
    if not rawget(_G, "MenuUtil") then return end
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        local preview = Previewed(quest)
        root:CreateTitle(preview and (QUESTS:Get(quest, "name") or ("#" .. quest))
            or Core.Ask(C_QuestLog.GetTitleForQuestID, quest) or "")
        root:CreateButton(QuestLog.TEXT.details, ns.Guard(function() QuestLog.Text(quest) end))
        root:CreateButton(QuestLog.TEXT.showMap, ns.Guard(function() QuestLog.Show(quest) end))
        root:CreateDivider()
        if preview then
            root:CreateButton(QuestLog.TEXT.remove, ns.Guard(function() QuestLog.Unpreview(quest) end))
            return
        end
        local watched = (Core.Ask(C_QuestLog.GetQuestWatchType, quest)) ~= nil
        root:CreateButton(watched and QuestLog.TEXT.unwatch or QuestLog.TEXT.watch,
            ns.Guard(function() Watch(quest, not watched) end))
        local share = root:CreateButton(QuestLog.TEXT.share, ns.Guard(function() Share(quest) end))
        if share.SetEnabled then share:SetEnabled(Core.Ask(C_QuestLog.IsPushableQuest, quest) and IsInGroup() or false) end
        root:CreateButton(QuestLog.TEXT.abandon, ns.Guard(function() Abandon(quest) end))
    end))
end

-------------------------------------------------------------------------------
--  The rows
-------------------------------------------------------------------------------
local function Height(_, row)
    if row.height then return row.height end
    if row.kind == "header" then return QuestLog.HEADER end
    if row.item then return QuestLog.ITEM end
    if row.kind == "quest" or row.kind == "preview" then return QuestLog.QUEST end
    return QuestLog.OBJECTIVE
end

local function Colour(row)
    if row.kind == "header" or row.kind == "section" then return 1, 0.82, 0 end
    if row.part then return 0.9, 0.9, 0.9 end
    if row.kind == "objective" then
        if row.done then return 0.5, 0.5, 0.5 end
        return 0.85, 0.85, 0.85
    end
    local difficulty = row.level and rawget(_G, "GetQuestDifficultyColor")
    local colour = difficulty and Core.Safe("quest log", difficulty, row.level, row.scaling, row.quest)
    if type(colour) == "table" then return colour.r, colour.g, colour.b end
    return 1, 1, 1
end

local function Clicked(element, mouse)
    local row = element.row
    if not row then return end
    if row.kind == "header" then
        -- Not in your log, a type: no zone; on the screen alone no fold mark, no folding.
        if not row.index or not full then return end
        if type(ns.store.questLogFolds) ~= "table" then ns.store.questLogFolds = {} end
        ns.store.questLogFolds[row.text] = not row.collapsed or nil
        return QuestLog.Refresh()
    end
    local quest = row.quest
    if mouse == "RightButton" then
        if row.kind == "preview" then return QuestLog.Unpreview(quest) end
        return Menu(element, quest)
    end
    if row.part then return Unfold(quest) end
    if row.kind == "preview" then return Pressed(quest) end
    -- The link's modifier is Shift too unless the player changed it: where nothing takes the link, as in the game's
    -- own log, the click goes on to watching.
    if IsModifiedClick("CHATLINK") then
        local link = rawget(_G, "GetQuestLink") and GetQuestLink(quest)
        local chat = rawget(_G, "ChatFrameUtil")
        if link and chat and chat.InsertLink and chat.InsertLink(link) then return end
    end
    if IsShiftKeyDown() then return Watch(quest, not row.watched) end
    Pressed(quest)
end

-- The quest the mouse is on (nil: off it), shown on the map: its area, and its pins glow.
local function Point(quest)
    ns.Areas.Hover(quest)
    ns.PinView.Light(quest)
end

local function Entered(element)
    Hover()
    local row = element.row
    if row and row.quest then Point(row.quest) end
end

local function Left()
    Point(nil)
end

-- A preview's mark at its row's start: the game's exclamation mark in red, whatever its giver's pin shows on the map:
-- with its red X what tells it from a quest in the log.
local function Mark(icon)
    local red = ns.Pins.RED
    icon:SetAtlas(ns.Pins.ICONS.offer)
    icon:SetVertexColor(red[1], red[2], red[3], 1)
    icon:Show()
end

-- On the screen alone only a row's words take the mouse, the rest of it is clicked through (Dress); over the full
-- map all of it. Again once the list's width changes (Sized).
local function Reach(element)
    if full or not element.text then return element:SetHitRectInsets(0, 0, 0, 0) end
    local used = (element.left or 0) + (element.text:GetStringWidth() or 0) + 4
    local spare = math.max(0, (box:GetWidth() or 0) - used)
    if mirrored then element:SetHitRectInsets(spare, 0, 0, 0) else element:SetHitRectInsets(0, spare, 0, 0) end
end

-------------------------------------------------------------------------------
--  The rewards
-------------------------------------------------------------------------------
--  Each a cell in a row under the open quest: its icon big, its name beside it, and the game's tooltip with the mouse
--  anywhere on the two, compared with what is worn as on the game's own rewards. Nothing here is used, so unlike the
--  quests' items they need no secure button and stay in the list's rows. What the game cannot tell of a quest not in
--  the log (a preview's) comes from the item itself.
local function RewardTip(cell)
    local thing = cell.thing
    if not thing then return end
    Hover()
    GameTooltip:SetOwner(cell, mirrored and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
    if thing.list then GameTooltip:SetQuestLogItem(thing.list, thing.index, thing.quest)
    elseif thing.spell then GameTooltip:SetSpellByID(thing.spell)
    elseif thing.currency then GameTooltip:SetCurrencyByID(thing.currency)
    else GameTooltip:SetItemByID(thing.item) end
    local compare = rawget(_G, "GameTooltip_ShowCompareItem")
    if compare and (thing.list or thing.item) then compare(GameTooltip) end
    GameTooltip:Show()
end

-- As on the game's own rewards: a click with the chat link's or the dressing room's modifier; a plain one does nothing.
local function RewardClicked(cell)
    local thing, modified = cell.thing, rawget(_G, "HandleModifiedItemClick")
    if not thing or not modified or not IsModifiedClick() then return end
    local link
    if thing.list then link = Core.Ask(rawget(_G, "GetQuestLogItemLink"), thing.list, thing.index, thing.quest)
    elseif thing.item then link = select(2, Core.Ask(C_Item.GetItemInfo, thing.item)) end
    if link then modified(link) end
end

local function RewardCell(element)
    local cell = CreateFrame("Button", nil, element)
    cell:SetHeight(QuestLog.REWARD)
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetSize(QuestLog.REWARD, QuestLog.REWARD)
    cell.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.rim = cell:CreateTexture(nil, "OVERLAY")
    cell.rim:SetAllPoints(cell.icon)
    cell.rim:SetTexture(QuestLog.RIM)
    cell.plate = cell:CreateTexture(nil, "BACKGROUND")
    cell.plate:SetTexture(QuestLog.PLATE)
    cell.count = cell:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    cell.count:SetPoint("BOTTOMRIGHT", cell.icon, "BOTTOMRIGHT", -3, 3)
    cell.name = cell:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cell.light = cell:CreateTexture(nil, "HIGHLIGHT")
    cell.light:SetAllPoints()
    cell.light:SetColorTexture(1, 1, 1, 0.08)
    cell:SetScript("OnEnter", ns.Guard(RewardTip))
    cell:SetScript("OnLeave", ns.Guard(function() Core.HideTip() end))
    cell:SetScript("OnClick", ns.Guard(RewardClicked))
    return cell
end

-- A cell as its thing is: its name and rim in its quality's colour, its icon red where this character cannot use it,
-- as the game has them; from the side the log stands at inwards (Sided).
local function RewardShown(cell, thing, near, far, sign)
    cell.thing = thing
    cell.icon:ClearAllPoints()
    cell.icon:SetPoint(near)
    cell.icon:SetTexture(thing.picture)
    if thing.usable == false then cell.icon:SetVertexColor(0.9, 0, 0) else cell.icon:SetVertexColor(1, 1, 1) end
    local colours = rawget(_G, "ITEM_QUALITY_COLORS")
    local colour = colours and thing.quality and colours[thing.quality]
    if colour then
        cell.rim:SetVertexColor(colour.r, colour.g, colour.b)
        cell.name:SetTextColor(colour.r, colour.g, colour.b)
    else
        cell.name:SetTextColor(1, 1, 1)
    end
    cell.rim:SetShown(colour and true or false)
    -- From behind the icon to the cell's far end; its picture turned round where the log is mirrored.
    local part = QuestLog.PLATE_PART
    cell.plate:ClearAllPoints()
    cell.plate:SetPoint("TOP" .. near, cell.icon, "TOP" .. far, -sign * 4, 0)
    cell.plate:SetPoint("BOTTOM" .. far)
    cell.plate:SetTexCoord(mirrored and part[2] or part[1], mirrored and part[1] or part[2], part[3], part[4])
    -- Between the icon and the cell's far end, as many lines as fit, in the middle of the icon's height.
    cell.name:ClearAllPoints()
    cell.name:SetPoint("TOP" .. near, cell.icon, "TOP" .. far, sign * 6, 0)
    cell.name:SetPoint("BOTTOM" .. far, -sign * 6, 0)
    cell.name:SetJustifyH(near)
    cell.name:SetText(thing.name)
    cell.count:SetText((thing.count or 1) > 1 and thing.count or "")
end

-- A row's rewards side by side; the cells it had for another row go. The row sets what a cell's width is (AddText).
local function Rewards(element, row, near, far, sign)
    local cells = element.cells
    if not cells then
        cells = {}
        element.cells = cells
    end
    local things = row.kind == "reward" and row.things or {}
    for index, thing in ipairs(things) do
        local cell = cells[index]
        if not cell then
            cell = RewardCell(element)
            cells[index] = cell
        end
        cell:ClearAllPoints()
        cell:SetPoint("TOP" .. near, sign * (QuestLog.INSET + (index - 1) * (row.width + QuestLog.GAP)), 0)
        cell:SetWidth(row.width)
        RewardShown(cell, thing, near, far, sign)
        cell:Show()
    end
    for index = #things + 1, #cells do
        cells[index].thing = nil
        cells[index]:Hide()
    end
end

-- A quest's words in the list: its level, with a + if it is meant for a group, and its name.
local function Title(row)
    if not row.level then return row.text or "" end
    return ("[%d%s] %s"):format(row.level, row.group and "+" or "", row.text or "")
end

-- A row's frame, made the first time the list draws one (the list's elements are plain buttons).
local function Draw(element, row)
    if not element.text then
        element.icon = element:CreateTexture(nil, "ARTWORK")
        element.icon:SetSize(QuestLog.MARK, QuestLog.MARK)
        element.text = element:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        element.text:SetJustifyH("LEFT")
        element.text:SetWordWrap(false)
        element.state = element:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        element.mark = element:CreateTexture(nil, "ARTWORK")
        element.mark:SetSize(12, 12)
        element.light = element:CreateTexture(nil, "HIGHLIGHT")
        element.light:SetAllPoints()
        element.light:SetColorTexture(1, 1, 1, 0.08)
        -- An open quest's text: its rows' panel, a thin gold line down the side the words start at.
        element.back = element:CreateTexture(nil, "BACKGROUND")
        element.back:SetAllPoints()
        element.rule = element:CreateTexture(nil, "BORDER")
        element.rule:SetWidth(2)
        element.rule:SetColorTexture(1, 0.82, 0, 0.5)
        -- A preview's red X: takes it out of the log again; the one on Not in your log all of them.
        element.remove = CreateFrame("Button", nil, element)
        element.remove:SetSize(16, 16)
        element.remove:SetNormalAtlas(QuestLog.REMOVE)
        element.remove:SetHighlightAtlas(QuestLog.REMOVE, "ADD")
        element.remove:SetScript("OnClick", ns.Guard(function(self)
            local row = self:GetParent().row
            if row then QuestLog.Unpreview(row.quest) end
        end))
        element.remove:SetScript("OnEnter", ns.Guard(function(self)
            local row = self:GetParent().row
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(row and row.ghosts and QuestLog.TEXT.removeAll or QuestLog.TEXT.remove, 1, 1, 1)
            GameTooltip:Show()
        end))
        element.remove:SetScript("OnLeave", GameTooltip_Hide)
        element:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        element:SetScript("OnClick", ns.Guard(Clicked))
        element:SetScript("OnEnter", ns.Guard(Entered))
        element:SetScript("OnLeave", ns.Guard(Left))
    end
    element.row = row
    local text, state, mark = element.text, element.state, element.mark
    -- From the side it stands at inwards (Sided): near is where a row starts, far where it ends; sign: inwards.
    local near, far, sign = "LEFT", "RIGHT", 1
    if mirrored then near, far, sign = "RIGHT", "LEFT", -1 end
    text:ClearAllPoints()
    text:SetJustifyH(near)
    mark:ClearAllPoints()
    state:ClearAllPoints()
    state:SetText("")
    mark:Hide()
    element.icon:Hide()
    element.remove:SetShown(row.kind == "preview" or row.ghosts)
    element.remove:ClearAllPoints()
    element.remove:SetPoint(far, -sign * 2, 0)
    element.light:SetShown(not row.part)
    element.back:SetShown(row.part)
    element.back:SetColorTexture(0, 0, 0, full and QuestLog.PANEL or QuestLog.PANEL_SMALL)
    element.rule:SetShown(row.part)
    element.rule:ClearAllPoints()
    element.rule:SetPoint("TOP" .. near)
    element.rule:SetPoint("BOTTOM" .. near)
    Rewards(element, row, near, far, sign)
    if row.kind == "header" then
        -- The game's fold mark only for a zone, and only over the full map.
        local folds = full and row.index ~= nil
        element.left = folds and 16 or 0
        text:SetFontObject("GameFontNormal")
        text:SetPoint(near, sign * element.left, 0)
        if folds then
            mark:SetAtlas(row.collapsed and "campaign_headericon_closed" or "campaign_headericon_open")
            mark:SetPoint(near, 0, 0)
            mark:Show()
        end
        text:SetText(row.text or "")
    elseif row.kind == "preview" then
        Mark(element.icon)
        element.icon:ClearAllPoints()
        element.icon:SetPoint(near, 0, 0)
        element.left = QuestLog.MARK + 4
        text:SetFontObject("GameFontHighlight")
        text:SetPoint(near, sign * element.left, 0)
        text:SetPoint(far, element.remove, near, -sign * 4, 0)
        text:SetText(Title(row))
    elseif row.kind == "quest" then
        element.left = 0
        -- At its far end its item, if it has one (Seat), and before that Failed.
        state:SetPoint(far, -sign * (row.item and QuestLog.ITEM + 4 or 4), 0)
        text:SetFontObject("GameFontHighlight")
        text:SetPoint(near, 0, 0)
        text:SetPoint(far, state, near, -sign * 4, 0)
        text:SetText(Title(row))
        if row.failed then
            state:SetText(QuestLog.TEXT.failed)
            state:SetTextColor(1, 0.2, 0.2)
        end
    elseif row.kind == "section" then
        element.left = QuestLog.INSET
        text:SetFontObject("GameFontNormal")
        text:SetPoint("BOTTOM" .. near, sign * element.left, 4)
        text:SetPoint("BOTTOM" .. far, -sign * element.left, 4)
        text:SetText(row.text)
    elseif row.kind == "text" then
        element.left = QuestLog.INSET
        text:SetFontObject("GameFontHighlight")
        text:SetPoint("TOP" .. near, sign * element.left, 0)
        text:SetPoint("TOP" .. far, -sign * element.left, 0)
        text:SetText(row.text)
    elseif row.kind == "reward" then
        element.left = QuestLog.INSET
        text:SetText("")
    else
        element.left = QuestLog.INDENT
        text:SetFontObject("GameFontHighlightSmall")
        text:SetPoint(near, sign * element.left, 0)
        text:SetPoint(far, -sign * 4, 0)
        text:SetText("- " .. (row.text or ""))
    end
    text:SetWordWrap(row.kind == "text")
    text:SetSpacing(row.kind == "text" and 2 or 0)
    text:SetTextColor(Colour(row))
    Reach(element)
    if row.quest and row.quest == chosen and (row.kind == "quest" or row.kind == "preview") then
        element.light:SetColorTexture(1, 0.82, 0, 0.15)
        element:LockHighlight()
    else
        element.light:SetColorTexture(1, 1, 1, 0.08)
        element:UnlockHighlight()
    end
end

-------------------------------------------------------------------------------
--  The chosen quest's text
-------------------------------------------------------------------------------
-- Names of a list of creatures (tuples with npc) or objects of Core's data, joined.
local function Names(list, field, set)
    local names = {}
    for _, entry in ipairs(list or {}) do
        local id = type(entry) == "table" and entry[field] or entry
        local name = id and set:Get(id, "name")
        if name and name ~= "" then names[#names + 1] = name end
    end
    return #names > 0 and table.concat(names, ", ") or nil
end

-- An item's name as the game has it; asked of the game when it has not (the details again once it answers).
local function Item(id)
    local name = Core.Ask(C_Item.GetItemNameByID, id)
    if name then return name end
    missing = true
    Core.Ask(C_Item.RequestLoadItemDataByID, id)
    return "#" .. tostring(id)
end

-- An objective of Core's data as the list writes the log's: none of how many done yet.
local function Listed(objective)
    local count, what = objective.count or 1, objective.what
    local name
    if objective.kind == "kill" then name = what and NPCS:Get(what, "name") or objective.text
    elseif objective.kind == "loot" and what then name = Item(what)
    elseif objective.kind == "object" then name = what and OBJECTS:Get(what, "name") or objective.text end
    if name then return Asked(objective.kind, 0, count, name) end
    return objective.text
end

-- The game's words without the blank lines around them, and no more than one blank line between paragraphs.
local function Tidy(words)
    return ((words or ""):gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n%s*\n%s*\n", "\n\n"))
end

-- A part of a quest's text: its words, none without.
local function Words(parts, words)
    words = Tidy(words)
    if words ~= "" then parts[#parts + 1] = { kind = "text", text = words } end
end

-- Under a heading in gold, none without words.
local function Section(parts, title, words)
    if Tidy(words) == "" then return end
    parts[#parts + 1] = { kind = "section", text = title }
    Words(parts, words)
end

-- What a quest gives: experience and coin in words, its things side by side, then those to choose from.
local function Given(parts, experience, money, things, choices)
    local words = {}
    if experience and experience > 0 then
        words[1] = QuestLog.TEXT.experience:format(Core.Ask(rawget(_G, "BreakUpLargeNumbers"), experience) or experience)
    end
    if money and money > 0 then words[#words + 1] = Core.Coins(money) end
    if #words == 0 and #things == 0 and #choices == 0 then return end
    parts[#parts + 1] = { kind = "section", text = QuestLog.TEXT.rewards }
    Words(parts, table.concat(words, "    "))
    if #things > 0 then parts[#parts + 1] = { kind = "reward", things = things } end
    if #choices > 0 then
        Words(parts, QuestLog.TEXT.choices)
        parts[#parts + 1] = { kind = "reward", things = choices }
    end
end

-- Rewards of Core's data as cells, known from the items themselves.
local function Cells(things, entries)
    for _, entry in ipairs(entries or {}) do
        things[#things + 1] = { item = entry.item, count = entry.count, name = Item(entry.item),
                                picture = Core.Ask(C_Item.GetItemIconByID, entry.item),
                                quality = Core.Ask(C_Item.GetItemQualityByID, entry.item) }
    end
end

-- What Core's data knows of a quest not in the log, as the log's words: why it is not for this character yet, its
-- level, who gives and takes it, what it asks first, its objectives and its rewards.
local function Preview(quest)
    local record = QUESTS:Get(quest) or {}
    local parts = {}
    local standing, reason = ns.Pins.Standing(record, quest)
    if reason then Words(parts, "|cffff4040" .. reason .. "|r")
    elseif standing == "offered" then Words(parts, "|cff20ff20" .. QuestLog.TEXT.offered .. "|r") end
    local facts = {}
    if record.level then facts[#facts + 1] = QuestLog.TEXT.level:format(record.level) end
    local givers = Names(record.startNPCs, "npc", NPCS) or Names(record.startObjects, "object", OBJECTS)
    if givers then facts[#facts + 1] = QuestLog.TEXT.givenBy:format(givers) end
    local takers = Names(record.finishNPCs, "npc", NPCS) or Names(record.finishObjects, "object", OBJECTS)
    if takers then facts[#facts + 1] = QuestLog.TEXT.takenBy:format(takers) end
    Words(parts, table.concat(facts, "\n"))
    local objectives = {}
    for _, objective in ipairs(record.objectives or {}) do
        local words = Listed(objective)
        if words and words ~= "" then objectives[#objectives + 1] = "- " .. words end
    end
    Section(parts, QuestLog.TEXT.objectives, table.concat(objectives, "\n"))
    local things, choices = {}, {}
    Cells(things, record.rewardItems)
    Cells(choices, record.rewardChoices)
    Given(parts, record.rewardXP, record.rewardMoney, things, choices)
    return parts
end

-- The things a quest in the log gives, by the quest's ID, no quest chosen in the game's own log for it (list: the
-- game's word for which of them, "reward" or "choice"). An item the game does not know yet follows once it does.
local function Things(things, quest, list, count, info)
    for index = 1, Core.Ask(rawget(_G, count), quest) or 0 do
        local ok, name, picture, many, quality, usable, item = pcall(rawget(_G, info), index, quest)
        if ok and name and name ~= "" then
            things[#things + 1] = { list = list, index = index, quest = quest, name = name, picture = picture,
                                    count = many, quality = quality, usable = usable, item = item }
        elseif ok and item then
            missing = true
            Core.Ask(C_Item.RequestLoadItemDataByID, item)
        end
    end
end

-- Its currencies, and the spells it teaches that this character does not know yet (the game's own rewards leave
-- out the others too).
local function Others(things, quest)
    local system = rawget(_G, "C_QuestInfoSystem")
    if not system then return end
    local currencies = Core.Ask(system.GetQuestRewardCurrencies, quest)
    for _, info in ipairs(type(currencies) == "table" and currencies or {}) do
        things[#things + 1] = { currency = info.currencyID, name = info.name, picture = info.texture,
                                quality = info.quality, count = info.totalRewardAmount or info.baseRewardAmount }
    end
    local spells = Core.Ask(system.GetQuestRewardSpells, quest)
    local book = rawget(_G, "C_SpellBook")
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    for _, spell in ipairs(type(spells) == "table" and spells or {}) do
        local info = Core.Ask(system.GetQuestRewardSpellInfo, quest, spell)
        local known = book and bank and Core.Ask(book.IsSpellInSpellBook, spell, bank, true)
        if type(info) == "table" and info.texture and not known then
            things[#things + 1] = { spell = spell, name = info.name, picture = info.texture }
        end
    end
end

-- A quest's text from the game's log: its story, what it asks, what it gives.
local function Story(quest)
    local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, quest)
    local description, objectives
    if index and rawget(_G, "GetQuestLogQuestText") then description, objectives = GetQuestLogQuestText(index) end
    local parts = {}
    Section(parts, QuestLog.TEXT.description, description)
    Section(parts, QuestLog.TEXT.objectives, objectives)
    local things, choices = {}, {}
    Things(things, quest, "reward", "GetNumQuestLogRewards", "GetQuestLogRewardInfo")
    Others(things, quest)
    Things(choices, quest, "choice", "GetNumQuestLogChoices", "GetQuestLogChoiceInfo")
    Given(parts, Core.Ask(rawget(_G, "GetQuestLogRewardXP"), quest), Core.Ask(rawget(_G, "GetQuestLogRewardMoney"), quest),
          things, choices)
    return parts
end

-- One row of the open quest's text, as high as it takes.
local function Put(row, height)
    row.part, row.quest, row.height = true, opened.quest, height
    rows[#rows + 1] = row
    opened.first, opened.last = opened.first or row, row
    opened.height = opened.height + height
end

-- The open quest's text as rows of the list: a preview's from Core's data, else the game's. Words wrapped in the
-- list's width, its rewards two to a row where two fit.
function AddText(quest)
    local parts = Previewed(quest) and Preview(quest) or Story(quest)
    if #parts == 0 then return end
    local width = math.max((box:GetWidth() or 0) - 2 * QuestLog.INSET, 1)
    local columns = width >= 2 * QuestLog.REWARD_WIDTH + QuestLog.GAP and 2 or 1
    measure:SetWidth(width)
    opened = { quest = quest, height = 0 }
    for _, part in ipairs(parts) do
        if part.kind == "section" then
            Put(part, QuestLog.SECTION)
        elseif part.kind == "text" then
            measure:SetText(part.text)
            Put(part, measure:GetStringHeight() + QuestLog.ROOM)
        else
            for first = 1, #part.things, columns do
                Put({ kind = "reward", things = { part.things[first], columns == 2 and part.things[first + 1] or nil },
                      width = (width - (columns - 1) * QuestLog.GAP) / columns }, QuestLog.REWARD + QuestLog.GAP)
            end
        end
    end
end

-- Quests of Core's data shown in the log (a click on their giver's pin): on top under Not in your log, the first
-- chosen; the map full screen with the log at the giver's place (map, x, y: 0 to 1 on it).
function QuestLog.Preview(quests, map, x, y)
    for index = #quests, 1, -1 do
        local quest = quests[index]
        local at = Previewed(quest)
        if at then table.remove(previews, at) end
        table.insert(previews, 1, quest)
        givers[quest] = map and x and { map, x, y } or nil
    end
    chosen, open = quests[1], true
    QuestLog.Fold(false)
    if not ns.TopBar.LogShown() then
        ns.store.questLog = true
        QuestLog.Lay(full)
    end
    ns.Window.OpenTo(map, x, y)
    QuestLog.Refresh()
    Reveal()
end

-- A preview taken out of the log again (its red X, the right button), or all of them (none named: the X over them).
function QuestLog.Unpreview(quest)
    if quest and not Previewed(quest) then return end
    if quest then Gone(quest) end
    while not quest and previews[1] do Gone(previews[1]) end
    QuestLog.Refresh()
end

-------------------------------------------------------------------------------
--  The quests' items
-------------------------------------------------------------------------------
--  Each at the far end of its quest's row, to be used as the game's tracker uses it. Only a secure button may use
--  an item (the game's SecureActionButtonTemplate), and the game protects the parent of one (Doc/guides/windows.md,
--  Combat), while the log has to come and go with the map in a fight. So they stand on a tray of their own over
--  the whole screen, placed by the screen, never anchored to the log. What each uses, where it stands and whether it is
--  there is set out of a fight only: in one they stay as they stood (their pictures do change) and follow once it
--  is over. Over the full map none shows in a fight: the map may go then, and they could not go with it.
local WAIT = "quest log: items"
local itemButtons = {}
local tray, trayLook -- as the tray was last set (Tray): "full", "small", or nil while hidden

local function Cooled(button)
    local bags = rawget(_G, "C_Container")
    local start, duration = Core.Ask(bags and bags.GetItemCooldown, button.item)
    if type(start) == "number" and type(duration) == "number" and duration > 0 then
        button.cooldown:SetCooldown(start, duration)
    else
        button.cooldown:Clear()
    end
end

-- The game's tooltip of what the player carries, as its tracker shows it: how it is bound, its charges, its cooldown,
-- not the item as such. Filled like any other, so the module Tooltips draws it and keeps to its settings. By where
-- its quest stands in the log now; the item as such once it is gone from there (a fight holds a button where it stood).
local function ItemTip(button)
    if not button.item then return end
    Hover()
    GameTooltip:SetOwner(button, mirrored and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
    local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, button.quest)
    if index and Special(index) == button.item then
        GameTooltip:SetQuestLogSpecialItem(index)
    else
        GameTooltip:SetItemByID(button.item)
    end
    GameTooltip:Show()
end

-- As on the game's tracker: with the chat's box open the link's modifier writes the item into it. With the box closed
-- Shift and a click uses it, so holding Shift to see its tooltip (the option Show tooltips) changes nothing.
local function Linking()
    local chat = rawget(_G, "ChatFrameUtil")
    return IsModifiedClick("CHATLINK") and chat and chat.GetActiveWindow and chat.GetActiveWindow() and true or false
end

-- Linked, the click uses nothing: only out of a fight, in one the game locks what the button does. So the link is
-- written only where the use was held off: in a fight the click uses the item alone (a click does one thing, as on
-- the game's tracker).
local function ItemPressed(button)
    if Linking() and not InCombatLockdown() then button:SetAttribute("type", "") end
end

local function ItemClicked(button)
    if Linking() and button.link and button:GetAttribute("type") == "" then ChatFrameUtil.InsertLink(button.link) end
    if not InCombatLockdown() then button:SetAttribute("type", "item") end
end

local function ItemButton(index)
    local button = CreateFrame("Button", nil, tray, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("type", "item")
    button:SetAttribute("useOnKeyDown", false) -- on the release, as the game's tracker, whatever the game's option says
    button:SetSize(QuestLog.ITEM, QuestLog.ITEM)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.light = button:CreateTexture(nil, "HIGHLIGHT")
    button.light:SetAllPoints()
    button.light:SetColorTexture(1, 1, 1, 0.2)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", -1, 1)
    button:SetScript("OnEnter", ns.Guard(ItemTip))
    button:SetScript("OnLeave", ns.Guard(function() Core.HideTip() end))
    button:SetScript("PreClick", ns.Guard(ItemPressed))
    button:SetScript("PostClick", ns.Guard(ItemClicked))
    itemButtons[index] = button
    return button
end

-- The tray shown or not, above the log, in its layer; over the full map out of sight in a fight, by the game's own
-- driver, which alone can hide it then.
local function Tray(on)
    local look = on and (full and "full" or "small") or nil
    if look == trayLook then return end
    trayLook = look
    UnregisterStateDriver(tray, "visibility")
    tray:SetShown(on)
    if on then
        tray:SetFrameStrata(frame:GetFrameStrata())
        tray:SetFrameLevel(frame:GetFrameLevel() + QuestLog.OVER)
    end
    if look == "full" then RegisterStateDriver(tray, "visibility", "[combat] hide; show") end
end

-- Each row in sight with an item gets a button at its far end, the others go; a row half out of the list has none.
local function Seat()
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Seat) end
    local used, top, bottom = 0, box:GetTop(), box:GetBottom()
    local half = QuestLog.ITEM / 2
    if frame:IsShown() and panel:IsShown() and top and box.ForEachFrame then
        local edge = mirrored and box:GetLeft() or box:GetRight()
        box:ForEachFrame(function(element)
            local row, middle = element.row, select(2, element:GetCenter())
            if row and row.item and middle and middle + half <= top + 1 and middle - half >= bottom - 1 then
                used = used + 1
                local button = itemButtons[used] or ItemButton(used)
                local other = button.item ~= row.item
                button.item, button.quest, button.link = row.item, row.quest, row.link
                button:SetAttribute("item", "item:" .. row.item)
                button.icon:SetTexture(row.picture)
                button.count:SetText((row.charges or 0) > 1 and row.charges or "")
                button:ClearAllPoints()
                button:SetPoint(mirrored and "LEFT" or "RIGHT", tray, "BOTTOMLEFT", edge, middle)
                button:Show()
                Cooled(button)
                if other and GameTooltip:IsOwned(button) then ItemTip(button) end -- the list changed under the mouse
            end
        end)
    end
    for index = used + 1, #itemButtons do
        itemButtons[index].item = nil
        itemButtons[index]:Hide()
    end
    Tray(used > 0)
end
local seat = Core.Later(Seat) -- on the next frame: the list has laid its rows out by then

-- Out of sight while it is carried: they could not follow it, and come back where it is let go (Sided).
local function Lifted()
    if not InCombatLockdown() then Tray(false) end
end

ns.On("BAG_UPDATE_COOLDOWN", function()
    for _, button in ipairs(itemButtons) do
        if button.item then Cooled(button) end
    end
end)

-- The game tells of no quest's item that came, went or lost a charge, its tracker keeps looking for itself: looked at
-- once a bag changed, the list drawn anew only then.
ns.On("BAG_UPDATE_DELAYED", function()
    for _, row in ipairs(rows) do
        if row.kind == "quest" then
            local item, _, charges = Special(row.index, row.complete)
            if item ~= row.item or charges ~= row.charges then return QuestLog.Refresh() end
        end
    end
end)

-------------------------------------------------------------------------------
--  The panel
-------------------------------------------------------------------------------
-- The game's quest tracker out of sight (Saneroki, 2026-10-31): whether ours shows or was switched off, while the
-- game's map and quest log are not chosen (Show the game's map; chosen, it goes only while ours shows). Lent to a
-- hidden frame of ours (Core.Lend; its own code goes on, unseen, its place among the game's frames kept), given back
-- once the game's are chosen, or the module stands down. The tracker is a frame the game manages: each time a layout
-- of Edit Mode is applied (the login, Edit Mode closing, a layout changed) its manager takes it back under its own
-- parent, whatever parent it has now. A hook after its SetParent puts it out of sight again at once. Not in Edit Mode:
-- there the tracker is the game's, to be seen and placed (its manager breaks it from its container as it is dragged,
-- and Reclaim would take it back at once); ours again as Edit Mode closes (Core.EditMode.Watch).
local function Reclaim(tracker)
    if not lent or tracker:GetParent() == away then return end
    if Core.Locked(tracker) then return Core.AfterCombat("quest tracker", Reclaim, tracker) end
    tracker:SetParent(away)
end

function QuestLog.Tracker()
    local tracker = rawget(_G, "ObjectiveTrackerFrame")
    local hide = not ns.off and not Core.EditMode.active
        and (not (ns.options or {}).nativeMap or (frame and frame:IsShown()))
    if hide and tracker and not lent then
        if not away then
            away = CreateFrame("Frame", nil, UIParent)
            away:Hide()
            hooksecurefunc(tracker, "SetParent", ns.Guard(Reclaim))
        end
        local lend = Core.Lend(tracker)
        if lend:SetParent(away) then lent = lend end
    elseif not hide and lent then
        local was = lent
        lent = nil
        was:Return()
    end
end
Core.EditMode.Watch(ns.Guard(QuestLog.Tracker))

-- The side the window stands at: the screen edge it is docked to, else the half of the screen its middle is in.
local function Side()
    local zone = handle.zone and Core.Dock.ZONES[handle.zone]
    if zone and (zone.left or zone.right) then return zone.left and "LEFT" or "RIGHT" end
    local x = frame:GetCenter()
    return (x and x > UIParent:GetWidth() / 2) and "RIGHT" or "LEFT"
end

-- The scroll bar, out of sight at rest: shown while the mouse is on the window and the list is longer than its
-- room, at the window's side (Side), in the room of its edge (QuestLog.EDGE); on the screen alone at the other, the
-- list stands too close to that one (Room). There a list that fits leaves the mouse wheel to the game (its camera).
local function Scroller()
    local long = not QuestLog.Folded() and box.HasScrollableExtent and box:HasScrollableExtent() and true or false
    box:EnableMouseWheel(full or long)
    local shown = frame:IsMouseOver() and long
    if shown then
        local left = (Side() == "LEFT") == full
        bar:ClearAllPoints()
        bar:SetPoint(left and "TOPRIGHT" or "TOPLEFT", box, left and "TOPLEFT" or "TOPRIGHT", left and -1 or 1, 0)
        bar:SetPoint(left and "BOTTOMRIGHT" or "BOTTOMLEFT", box, left and "BOTTOMLEFT" or "BOTTOMRIGHT", left and -1 or 1, 0)
    end
    bar:SetShown(shown)
end

-- The mouse on the window, rows and all: its grip (Core's grip = "hover") and its scroll bar are seen while it
-- is. Looked at each frame until the mouse is off it: leaving the window itself for one of its rows is no leaving.
local function Watching()
    if frame:IsMouseOver() then return end
    frame:SetScript("OnUpdate", nil)
    handle:Hover(false)
    Scroller()
end
local watching = ns.Guard(Watching) -- made once: set at every coming of the mouse

function Hover()
    handle:Hover(true)
    rest:Enter()
    Scroller()
    if not frame:GetScript("OnUpdate") then frame:SetScript("OnUpdate", watching) end
end

-- The list's room from a side of the window ("LEFT", "RIGHT"): QuestLog.EDGE; on the screen alone less at the side
-- it stands at, closer to the screen's edge.
local function Margin(side)
    return (not full and (side == "RIGHT") == mirrored) and QuestLog.EDGE_SMALL or QuestLog.EDGE
end

-- The list and its title at the side it stands at (Margin), its words from there inwards.
local function Room()
    local left, right = Margin("LEFT"), Margin("RIGHT")
    box:SetPoint("TOPLEFT", left, 0)
    box:SetPoint("BOTTOMRIGHT", -right, QuestLog.EDGE)
    panel.empty:SetPoint("TOPLEFT", left, 0)
    panel.empty:SetPoint("TOPRIGHT", -right, 0)
    panel.empty:SetJustifyH(mirrored and "RIGHT" or "LEFT")
    handle:TitleAt(mirrored and "RIGHT" or "LEFT", not full and QuestLog.EDGE_SMALL or nil)
end

-- Wherever it was put (Core's docked): which half of the screen it stands on, drawn anew once that changed.
local function Sided()
    if not box then return end
    local right = Side() == "RIGHT"
    local changed = right ~= mirrored
    mirrored = right
    Room()
    if changed then QuestLog.Refresh() end
    seat()
end

-- The sorting after this one (QuestLog.SORTS, round).
local function Next()
    local sort = QuestLog.Sort()
    for index, each in ipairs(QuestLog.SORTS) do
        if each == sort then return QuestLog.SORTS[index % #QuestLog.SORTS + 1] end
    end
    return QuestLog.SORTS[1]
end

-- A click on the title: sorted the next way, kept.
local function Resorted()
    ns.store.questLogSort = Next()
    QuestLog.Refresh()
end

-- Folded (store.questLogFolded): only its title bar stays, nothing else of it takes the mouse.
function QuestLog.Folded()
    return ns.store.questLogFolded and true or false
end

-- What it shows under its title bar, and its background: as it is folded and in which look (Dress).
local function Body()
    local whole = not QuestLog.Folded()
    panel:SetShown(whole)
    back:SetShown(full and whole)
    frame:EnableMouse(full and whole)
end

-- Folded (on) or not, kept, drawn anew.
function QuestLog.Fold(on)
    if (on and true or false) == QuestLog.Folded() then return end
    ns.store.questLogFolded = on or nil
    Body()
    QuestLog.Refresh()
end

-- The title's tip: how the quests are sorted, what a click does, there and beside it.
local function SortedTip() return QuestLog.TEXT.sorted:format(QuestLog.TEXT.sorts[QuestLog.Sort()]:lower()) end
local function NextTip()
    return QuestLog.TEXT.sortNext:format(QuestLog.TEXT.sorts[Next()]:lower()) .. " "
        .. (QuestLog.Folded() and QuestLog.TEXT.unfold or QuestLog.TEXT.fold)
end

-- Its first place in each look, from the screen's top left (Dress).
local FIRST = {
    [true] = { point = "TOPLEFT", x = QuestLog.FIRST.x, y = QuestLog.FIRST.y, width = QuestLog.WIDTH, height = QuestLog.HEIGHT },
    [false] = { point = "TOPLEFT", x = QuestLog.FIRST_SMALL.x, y = QuestLog.FIRST_SMALL.y, width = QuestLog.WIDTH,
                height = QuestLog.HEIGHT },
}
local KEY = { [true] = "questLogPlace", [false] = "questLogSmallPlace" } -- where each look's place is kept

-- The window, built at login with the map's (Window.lua); hidden until the full map or its pin shows it.
function QuestLog.Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("LOW")
    frame:Hide()
    handle = Core.Window.New(frame, {
        store = ns.store, key = KEY[true], title = QuestLog.TEXT.title, titleBar = true, barLine = false,
        barHeight = QuestLog.BAR,
        dock = true, dragDocked = true, sizable = true, grip = "hover",
        minWidth = QuestLog.LEAST, minHeight = QuestLog.LEAST, first = FIRST[true],
        titleClick = function() ns.Guarded(Resorted) end,
        titleTip = { SortedTip, NextTip },
        barClick = function() ns.Guarded(QuestLog.Fold, not QuestLog.Folded()) end,
        bare = function() return true end, -- no buttons: the full map's bar has its switch
        usable = function() return not InCombatLockdown() end, -- its items cannot follow it in a fight
        lifted = function() ns.Guarded(Lifted) end,
        docked = function() ns.Guarded(Sided) end,
    })
    QuestLog.handle = handle
    full = true
    tray = CreateFrame("Frame", nil, UIParent)
    tray:SetAllPoints(UIParent)
    tray:Hide()
    rest = Core.Rest.New({ label = "quest log", frames = { frame, tray } })
    rest:Hot(frame)
    frame:EnableMouse(true) -- over the full map: the map behind it is not clicked through it (Dress)
    frame:SetScript("OnEnter", ns.Guard(Hover))
    back = frame:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0.03, 0.03, 0.04, QuestLog.BACK)

    panel = CreateFrame("Frame", nil, handle.inside)
    panel:SetAllPoints()
    panel.empty = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    panel.empty:SetText(QuestLog.TEXT.empty)

    box = CreateFrame("Frame", nil, panel, "WowScrollBoxList")
    bar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    bar:Hide()
    view = CreateScrollBoxListLinearView()
    -- The game's list asks these of every row: always a number (also after a failure), each row drawn apart.
    view:SetElementExtentCalculator(function(_, row) return ns.Safe("quest log", Height, nil, row) or QuestLog.OBJECTIVE end)
    view:SetElementInitializer("Button", function(element, row) ns.Safe("quest log", Draw, element, row) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    box:RegisterCallback(BaseScrollBoxEvents.OnScroll, ns.Guard(function() seat() end), QuestLog)

    -- What a quest's text will take in the list: as its row draws it (Draw), not to be seen.
    measure = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    measure:SetPoint("TOPLEFT")
    measure:SetSpacing(2)
    measure:SetAlpha(0)
    -- Sized: an open quest's text wraps anew, once the size rests (a grip's drag sizes it every frame: the whole log
    -- read anew each time is too much); on the screen alone its rows' words are measured again at once.
    local reflow = Core.Later(function() if open then QuestLog.Refresh() end end, QuestLog.REFLOW)
    local function Sized()
        if open then reflow() end
        if not full and box.ForEachFrame then box:ForEachFrame(Reach) end
        Scroller()
        seat()
    end
    panel:SetScript("OnSizeChanged", ns.Guard(Sized))
    handle:Place() -- where it was left; at its first place and size if it never was moved
    Body()
    return frame
end

-- Sorted by proximity and in sight: the order looked at again every QuestLog.RESORT seconds (Resort); else not.
local Resort
local function Tick(on)
    if on and not ticker then
        ticker = C_Timer.NewTicker(QuestLog.RESORT, ns.Guard(function() Resort() end))
    elseif not on and ticker then
        ticker:Cancel()
        ticker = nil
    end
end

-- The list drawn anew from the game's log, if it is in sight; else once it is. The title bar says how many quests
-- of how many and how they are sorted.
function QuestLog.Refresh()
    if not frame or not frame:IsShown() then
        stale = true
        return
    end
    stale = false
    local quests = Read()
    local most = Plain(Core.Ask(C_QuestLog.GetMaxNumQuestsCanAccept)) or 25
    local text = QuestLog.TEXT.heading:format(quests, most, QuestLog.TEXT.sorts[QuestLog.Sort()])
    if text ~= heading then
        heading = text
        handle:SetTitle(text)
    end
    panel.empty:SetShown(quests == 0)
    box:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
    Scroller()
    seat()
    Tick(QuestLog.Sort() == "proximity" and not QuestLog.Folded())
end

-- The player walked on: drawn anew once the nearest quests come in another order.
function Resort()
    if not QuestLog.Shown() or QuestLog.Sort() ~= "proximity" then return Tick(false) end
    if Order(Sorted((Entries()), "proximity")) ~= order then QuestLog.Refresh() end
end

-- At rest out of sight, as the setting says: only on the screen alone, over the full map it is opened to be seen.
function QuestLog.Rested()
    if rest then rest:Switch(not ns.off and not full and (ns.options or {}).questLogRest ~= false) end
end

-- Core's title bar comes with the first look: the mouse on it, or on the words in it, brings the log into sight.
local function Doors()
    local titleBar = handle.bar
    if doors or not titleBar then return end
    doors = true
    rest:Door(titleBar)
    rest:Door(titleBar.find)
end

-- Its look (Saneroki 2026-10-29): over the full map (on) its background, above the map's layer, the map not
-- clicked through it, every objective; on the screen alone, in the game's minimap's
-- layer, none of these: clicked through but its title bar and its rows' words. Each look at its own place, kept.
local function Dress(on)
    on = on and true or false
    if on ~= full then stale = true end
    full = on
    Body()
    frame:SetFrameStrata(on and "DIALOG" or "LOW") -- the full map stands in the layer HIGH (Core's Edge)
    handle:Use(KEY[on], FIRST[on])
    handle:Refresh()
    Doors()
    QuestLog.Rested()
end

-- Shown or not, as the full map's bar's button has it, in the look of the map as it is (on: it fills the screen and
-- stands there; Dress).
function QuestLog.Lay(on)
    if not frame then return end
    Dress(on)
    local shown = ns.TopBar.LogShown()
    if shown and not frame:IsShown() then frame:Show() elseif not shown and frame:IsShown() then frame:Hide() end
    QuestLog.Tracker()
    if shown and stale then QuestLog.Refresh() end
    if not shown then
        Point(nil)
        Tick(false)
    end
    seat()
end

function QuestLog.Shown()
    return frame and frame:IsShown() or false
end

-- For the test: its set.
function QuestLog.Rest()
    return rest
end

-- The module stood down: the window goes, the game's quest tracker is back.
function QuestLog.Hide()
    if frame then frame:Hide() end
    QuestLog.Rested()
    Tick(false)
    QuestLog.Tracker()
    seat()
end

ns.Listen("LIVE", function(what)
    if what == "quests" or what == "waypoint" then QuestLog.Refresh() end
end)

-- An item the open text waits for arrived from the game: read again, once on the next frame however many came.
local named = Core.Later(function()
    if open then QuestLog.Refresh() end
end)
ns.On("ITEM_DATA_LOAD_RESULT", function()
    if missing then named() end
end)
