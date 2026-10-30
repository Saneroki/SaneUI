local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - QuestLog
--  The quest log, a window of its own over the full map (in or out by the bar's
--  button, TopBar.lua). Our own
--  list (the game's belongs to its map window, which stays closed), read from
--  the game's quest log: each quest with its level, its objectives under it, no
--  mark before it and no tick after it (Saneroki 2026-10-30).
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
--      a quest       a click: its text unfolds under it, or folds away again (Saneroki 2026-10-30), a moment later,
--                    once no second click came; the game's arrow leads to it, and the map moves to its objective,
--                    where the map shows it (its question mark, or the middle of the area where its foes are), at
--                    the zoom it has, as a drag would move it (Canvas.LookAt). A double click: the same but for its
--                    text, which stays as it was, and the game's map pin there, so the golden line leads there. Shift
--                    and a click: watched or not (the game's objective tracker); the chat link's modifier: its
--                    link into the chat; the right button: a menu (its text, the map at its
--                    objective with its zone whole, watch, share, abandon after a question). The mouse over
--                    it: its area on the map (Areas.lua). The item it wants used, as the game's tracker shows
--                    one, stands at the far end of its row (The quests' items)
--      under it      a quest's text, by a click on it, from its menu or by a click on its pin on the map: its
--                    objectives' words, its rewards and its story, one quest's at a time; a click there or on the
--                    quest folds it away
--      previews      quests of Core's data a click on their giver's pin showed (QuestLog.Preview): on top,
--                    under Not in your log, grey, each with its giver's mark and the game's red X that takes
--                    it out again; a click unfolds what the data knows of it (why it is not for you yet, its level, who
--                    gives and takes it, what it asks first, its objectives, its rewards) and moves the map to
--                    its giver, a double click puts the game's map pin there. Kept until the next /reload
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
--  sized by its corner's grip while the mouse is on it. Its title bar's pin (the
--  game's pin of its recent allies) keeps it on the screen while the map is small
--  too (kept, Saneroki 2026-10-20). Two looks, each with its own place and size,
--  kept (Saneroki 2026-10-29):
--      over the full map    its dark background, to be read over the map, which is not clicked through it;
--                           every objective, the done ones grey; the pin and the close button (out of both)
--      on the screen alone  at first in the screen's top left corner; no background, no border, no line under
--                           its title bar and none of its buttons, only the list and its words over the game;
--                           closer to the screen's edge; clicked through but its title bar, its words and its
--                           items; the objectives done left out, the
--                           headers without their fold marks; the game's quest tracker out of sight meanwhile
--                           (lent to a hidden frame, Core.Lend; back once it is not pinned)
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
QuestLog.BACK = 0.88      -- its background's opacity over the full map (pinned on the screen alone: none)
QuestLog.EDGE = 10        -- room inside its edges
QuestLog.EDGE_SMALL = 4   -- on the screen alone: at the side it stands at (and its title)
QuestLog.HEADER, QuestLog.QUEST, QuestLog.OBJECTIVE = 24, 20, 16 -- the rows' heights
QuestLog.ITEM = 24        -- a quest's item's button, and the height of a row with one
QuestLog.OVER = 30        -- the items' frame level above the log's
QuestLog.INDENT = 10      -- an objective's words from its quest's
QuestLog.MARK = 16        -- a preview's mark at its row's start; its words after it
QuestLog.ROOM = 6         -- under a quest's text
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
    pin = "Pin",
    pinTip = "Keeps the quest log on the screen while the map is small too, at a place of its own, without its background, in place of the game's quest tracker. Click again: only over the full map.",
    remove = "Take it out of the log",
    offered = "You can take this quest.",
    level = "Level %d",
    givenBy = "Given by: %s",
    takenBy = "Turned in to: %s",
    rewards = Core.Word("QUEST_REWARDS", "Rewards"),
    choices = Core.Word("REWARD_CHOICES", "You will be able to choose one of these rewards:"),
    experience = "%d experience",
    killed = Core.Word("QUEST_MONSTERS_KILLED", "%s slain: %d/%d"),
    items = Core.Word("QUEST_ITEMS_NEEDED", "%s: %d/%d"),
    objects = Core.Word("QUEST_OBJECTS_FOUND", "%s: %d/%d"),
}
QuestLog.REMOVE = "xmarksthespot" -- the game's red X (ObjectIconsAtlas) on a preview's row
QuestLog.PIN = "friendslist-recentallies-pin-yellow" -- the game's pin, lit while pinned
QuestLog.PIN_OFF = "friends-icon-pinned-dis"         -- and grey while not

local QUESTS, NPCS, OBJECTS = Core.Data.Set("Quests"), Core.Data.Set("NPCs"), Core.Data.Set("Objects")
local previews = {} -- quests shown from the map's pins (Preview), newest first
local givers = {}   -- [quest] = { map, x, y }: where the pin stood that showed it

local panel, box, view, bar, measure
local frame, handle, back, pinButton
local full = false -- its look over the full map, else on the screen alone (Dress)
local mirrored = false -- it stands on the screen's right half: its words at the right, the items at the left (Sided)
local rows = {}    -- what the list shows: { kind = "header" | "quest" | "objective", ... }
local stale = true -- the log changed while out of sight
local order = ""   -- the quests in the order shown (Proximity: drawn anew once it changes)
local heading      -- the title bar's words now
local ticker       -- sorted by proximity and in sight: the order looked at again (Tick)
local away, lent   -- the hidden frame the game's quest tracker is lent to while ours is pinned (Tracker)
local chosen       -- the quest last clicked or shown, lit in the list
local open = false -- its text shows under it
local opened       -- that text's row, while it is listed (Read)
local AddText      -- that row, under its quest (The chosen quest's text)
local Hover        -- the mouse came onto the window or one of its rows (The panel)

local function Plain(value)
    return Core.Plain(value)
end

-- Where a quest stands among the previews; nil for one not shown from the map's pins.
local function Previewed(quest)
    for index, each in ipairs(previews) do if each == quest then return index end end
    return nil
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
    local count = Plain(Core.Ask(C_QuestLog.GetNumQuestLogEntries)) or 0
    for index = 1, count do
        local info = Core.Ask(C_QuestLog.GetInfo, index)
        if type(info) == "table" then
            if info.isHeader then
                folded = (full and ns.store.questLogFolds and ns.store.questLogFolds[info.title]) and true or false
                entries[#entries + 1] = { kind = "header", text = info.title, index = index, collapsed = folded }
            elseif not info.isHidden and info.questID then
                quests = quests + 1
                entries[#entries + 1] = { kind = "quest", quest = info.questID, text = info.title, level = info.level,
                                          index = index, scaling = info.isScaling, folded = folded }
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
-- picture and how many charges it has; none for a quest done, unless the game keeps it then.
local function Special(index, complete)
    local link, picture, charges, keeps = Core.Ask(rawget(_G, "GetQuestLogSpecialItemInfo"), index)
    local item = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if item and (not complete or keeps) then return item, picture, charges end
    return nil
end

-- A quest's row and its objectives under it: over the full map every one, the done ones grey; on the screen alone
-- only those still to do. A quest done: its turn in last, an objective still to do in both.
local function Add(entry)
    local quest = entry.quest
    local complete = Core.Ask(C_QuestLog.IsComplete, quest) and true or false
    local failed = Core.Ask(C_QuestLog.IsFailed, quest) and true or false
    local item, picture, charges = Special(entry.index, complete)
    rows[#rows + 1] = { kind = "quest", quest = quest, text = entry.text, level = entry.level, index = entry.index,
                        complete = complete, failed = failed, scaling = entry.scaling,
                        item = item, picture = picture, charges = charges,
                        watched = (Core.Ask(C_QuestLog.GetQuestWatchType, quest)) ~= nil }
    local objectives = Core.Ask(C_QuestLog.GetQuestObjectives, quest)
    for _, objective in ipairs(type(objectives) == "table" and objectives or {}) do
        if objective.text and objective.text ~= "" and (full or not objective.finished) then
            rows[#rows + 1] = { kind = "objective", quest = quest, text = objective.text, done = objective.finished }
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
    opened = nil
    if chosen and not Previewed(chosen) then
        local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, chosen)
        if not index or index <= 0 then chosen, open = nil, false end
    end
    if #previews > 0 then
        rows[#rows + 1] = { kind = "header", text = QuestLog.TEXT.previews }
        for _, quest in ipairs(previews) do
            rows[#rows + 1] = { kind = "preview", quest = quest, text = QUESTS:Get(quest, "name") or ("#" .. quest),
                                level = QUESTS:Get(quest, "level"), standing = (ns.Pins.Standing(QUESTS:Get(quest), quest)) }
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
    box:ScrollToElementData(opened, tall and ScrollBoxConstants.AlignBegin or ScrollBoxConstants.AlignNearest)
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
    if row.kind == "header" then return QuestLog.HEADER end
    if row.kind == "text" then return row.height end
    if row.item then return QuestLog.ITEM end
    if row.kind == "quest" or row.kind == "preview" then return QuestLog.QUEST end
    return QuestLog.OBJECTIVE
end

local function Colour(row)
    if row.kind == "header" then return 1, 0.82, 0 end
    if row.kind == "preview" then return 0.55, 0.55, 0.55 end
    if row.kind == "text" then return 0.85, 0.85, 0.85 end
    if row.kind == "objective" then
        if row.done then return 0.5, 0.5, 0.5 end
        return 0.85, 0.85, 0.85
    end
    local difficulty = rawget(_G, "GetQuestDifficultyColor")
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
        ns.store.questLogFolds = ns.store.questLogFolds or {}
        ns.store.questLogFolds[row.text] = not row.collapsed or nil
        return QuestLog.Refresh()
    end
    local quest = row.quest
    if mouse == "RightButton" then return Menu(element, quest) end
    if row.kind == "text" then return Unfold(quest) end
    if row.kind == "preview" then return Pressed(quest) end
    if IsModifiedClick("CHATLINK") then
        local link = rawget(_G, "GetQuestLink") and GetQuestLink(quest)
        local chat = rawget(_G, "ChatFrameUtil")
        if link and chat and chat.InsertLink then chat.InsertLink(link) end
        return
    end
    if IsShiftKeyDown() then return Watch(quest, not row.watched) end
    Pressed(quest)
end

local function Entered(element)
    Hover()
    local row = element.row
    if row and row.quest then ns.Areas.Hover(row.quest) end
end

local function Left()
    ns.Areas.Hover(nil)
end

-- A preview's mark at its row's start, as its giver's pin on the map has it: the yellow exclamation mark, grey for a
-- quest too low, the red question mark for one for later.
local MARKS = { offered = "offer", low = "grey", later = "later" }
local function Mark(icon, row)
    local standing = row.standing
    icon:SetAtlas(ns.Pins.ICONS[MARKS[standing] or "done"])
    icon:SetDesaturated(standing == "low")
    local red = standing == "later" and ns.Pins.RED
    if red then icon:SetVertexColor(red[1], red[2], red[3], 1) else icon:SetVertexColor(1, 1, 1, 1) end
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
        -- A preview's red X: takes it out of the log again.
        element.remove = CreateFrame("Button", nil, element)
        element.remove:SetSize(16, 16)
        element.remove:SetNormalAtlas(QuestLog.REMOVE)
        element.remove:SetHighlightAtlas(QuestLog.REMOVE, "ADD")
        element.remove:SetScript("OnClick", ns.Guard(function(self)
            local row = self:GetParent().row
            if row and row.kind == "preview" then QuestLog.Unpreview(row.quest) end
        end))
        element.remove:SetScript("OnEnter", ns.Guard(function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(QuestLog.TEXT.remove, 1, 1, 1)
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
    element.remove:SetShown(row.kind == "preview")
    element.light:SetShown(row.kind ~= "text")
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
        Mark(element.icon, row)
        element.icon:ClearAllPoints()
        element.icon:SetPoint(near, 0, 0)
        element.remove:ClearAllPoints()
        element.remove:SetPoint(far, -sign * 2, 0)
        element.left = QuestLog.MARK + 4
        text:SetFontObject("GameFontHighlight")
        text:SetPoint(near, sign * element.left, 0)
        text:SetPoint(far, element.remove, near, -sign * 4, 0)
        text:SetText(row.level and ("[%d] %s"):format(row.level, row.text) or row.text)
    elseif row.kind == "quest" then
        element.left = 0
        -- At its far end its item, if it has one (Seat), and before that Failed.
        state:SetPoint(far, -sign * (row.item and QuestLog.ITEM + 4 or 4), 0)
        text:SetFontObject("GameFontHighlight")
        text:SetPoint(near, 0, 0)
        text:SetPoint(far, state, near, -sign * 4, 0)
        text:SetText(("[%d] %s"):format(row.level or 0, row.text or ""))
        if row.failed then
            state:SetText(QuestLog.TEXT.failed)
            state:SetTextColor(1, 0.2, 0.2)
        end
    elseif row.kind == "text" then
        element.left = QuestLog.INDENT
        text:SetFontObject("GameFontHighlightSmall")
        text:SetPoint("TOP" .. near, sign * element.left, 0)
        text:SetPoint("TOP" .. far, -sign * 4, 0)
        text:SetText(row.text)
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
    Core.Ask(C_Item.RequestLoadItemDataByID, id)
    return "#" .. tostring(id)
end

-- An objective of Core's data in the words of the game's log: what, none of how many done yet.
local function Objective(objective)
    local count, what = objective.count or 1, objective.what
    if objective.kind == "kill" then
        local name = what and NPCS:Get(what, "name") or objective.text
        if name then return QuestLog.TEXT.killed:format(name, 0, count) end
    elseif objective.kind == "loot" and what then
        return QuestLog.TEXT.items:format(Item(what), 0, count)
    elseif objective.kind == "object" then
        local name = what and OBJECTS:Get(what, "name") or objective.text
        if name then return QuestLog.TEXT.objects:format(name, 0, count) end
    end
    return objective.text
end

-- A part of a quest's text: its title in gold, its lines under it; none without lines.
local function Section(parts, title, lines)
    if #lines > 0 then parts[#parts + 1] = "|cffffd100" .. title .. "|r\n" .. table.concat(lines, "\n") end
end

-- What Core's data knows of a quest not in the log, as the log's words: why it is not for this character yet, its
-- level, who gives and takes it, what it asks first, its objectives and its rewards.
local function Preview(quest)
    local record = QUESTS:Get(quest) or {}
    local parts = {}
    local standing, reason = ns.Pins.Standing(record, quest)
    if reason then parts[#parts + 1] = "|cffff4040" .. reason .. "|r"
    elseif standing == "offered" then parts[#parts + 1] = "|cff20ff20" .. QuestLog.TEXT.offered .. "|r" end
    local facts = {}
    if record.level then facts[#facts + 1] = QuestLog.TEXT.level:format(record.level) end
    local givers = Names(record.startNPCs, "npc", NPCS) or Names(record.startObjects, "object", OBJECTS)
    if givers then facts[#facts + 1] = QuestLog.TEXT.givenBy:format(givers) end
    local takers = Names(record.finishNPCs, "npc", NPCS) or Names(record.finishObjects, "object", OBJECTS)
    if takers then facts[#facts + 1] = QuestLog.TEXT.takenBy:format(takers) end
    if #facts > 0 then parts[#parts + 1] = table.concat(facts, "\n") end
    local objectives = {}
    for _, objective in ipairs(record.objectives or {}) do
        local words = Objective(objective)
        if words and words ~= "" then objectives[#objectives + 1] = "- " .. words end
    end
    Section(parts, QuestLog.TEXT.objectives, objectives)
    local rewards = {}
    if record.rewardXP and record.rewardXP > 0 then rewards[#rewards + 1] = QuestLog.TEXT.experience:format(record.rewardXP) end
    local coins = rawget(_G, "GetCoinTextureString")
    if record.rewardMoney and record.rewardMoney > 0 and coins then rewards[#rewards + 1] = coins(record.rewardMoney) end
    for _, list in ipairs({ record.rewardItems or {}, record.rewardChoices or {} }) do
        for _, entry in ipairs(list) do
            rewards[#rewards + 1] = Item(entry.item) .. ((entry.count or 1) > 1 and (" x" .. entry.count) or "")
        end
    end
    Section(parts, QuestLog.TEXT.rewards, rewards)
    return table.concat(parts, "\n\n")
end

-- The things a quest in the log gives, in the game's words: its picture, its name, how many. An item the game does
-- not know yet is left out, until the log is read again.
local function Things(lines, quest, count, info)
    for index = 1, Core.Ask(rawget(_G, count), quest) or 0 do
        local name, picture, many = Core.Ask(rawget(_G, info), index, quest)
        if name then
            local shown = picture and ("|T%s:16:16|t %s"):format(tostring(picture), name) or name
            lines[#lines + 1] = (many or 1) > 1 and (shown .. " x" .. many) or shown
        end
    end
end

-- What the game says a quest in the log gives: by the quest's ID, no quest chosen in the game's own log for it.
local function Rewards(parts, quest)
    local rewards, choices = {}, {}
    local experience = Core.Ask(rawget(_G, "GetQuestLogRewardXP"), quest)
    if experience and experience > 0 then rewards[1] = QuestLog.TEXT.experience:format(experience) end
    local money = Core.Ask(rawget(_G, "GetQuestLogRewardMoney"), quest)
    local coins = rawget(_G, "GetCoinTextureString")
    if money and money > 0 and coins then rewards[#rewards + 1] = coins(money) end
    Things(rewards, quest, "GetNumQuestLogRewards", "GetQuestLogRewardInfo")
    Things(choices, quest, "GetNumQuestLogChoices", "GetQuestLogChoiceInfo")
    Section(parts, QuestLog.TEXT.rewards, rewards)
    Section(parts, QuestLog.TEXT.choices, choices)
end

-- A quest's text from the game's log: what it asks, its rewards, its story.
local function Story(quest)
    local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, quest)
    local description, objectives
    if index and rawget(_G, "GetQuestLogQuestText") then description, objectives = GetQuestLogQuestText(index) end
    local parts = {}
    if objectives and objectives ~= "" then Section(parts, QuestLog.TEXT.objectives, { objectives }) end
    Rewards(parts, quest)
    if description and description ~= "" then Section(parts, QuestLog.TEXT.description, { description }) end
    return table.concat(parts, "\n\n")
end

-- The open quest's text as a row of the list, wrapped in the list's width and as high as that takes: a preview's from
-- Core's data, else the game's.
function AddText(quest)
    local text = Previewed(quest) and Preview(quest) or Story(quest)
    if text == "" then return end
    measure:SetWidth(math.max((box:GetWidth() or 0) - QuestLog.INDENT - 4, 1))
    measure:SetText(text)
    opened = { kind = "text", quest = quest, text = text, height = measure:GetStringHeight() + QuestLog.ROOM }
    rows[#rows + 1] = opened
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

-- A preview taken out of the log again (its red X).
function QuestLog.Unpreview(quest)
    local at = Previewed(quest)
    if not at then return end
    table.remove(previews, at)
    givers[quest] = nil
    if chosen == quest then chosen, open = nil, false end
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

local function ItemTip(button)
    if not button.item then return end
    GameTooltip:SetOwner(button, mirrored and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(button.item)
    GameTooltip:Show()
end

local function ItemButton(index)
    local button = CreateFrame("Button", nil, tray, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("type", "item")
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
                button.item = row.item
                button:SetAttribute("item", "item:" .. row.item)
                button.icon:SetTexture(row.picture)
                button.count:SetText((row.charges or 0) > 1 and row.charges or "")
                button:ClearAllPoints()
                button:SetPoint(mirrored and "LEFT" or "RIGHT", tray, "BOTTOMLEFT", edge, middle)
                button:Show()
                Cooled(button)
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

-------------------------------------------------------------------------------
--  The panel
-------------------------------------------------------------------------------
-- Pinned to the screen (store.questLogPinned): shown while the map is small too.
function QuestLog.Pinned()
    return ns.store.questLogPinned and true or false
end

-- The pin as it is: lit while pinned, grey while not.
local function PinLook()
    local picture = pinButton and pinButton.picture
    if not picture then return end
    local on = QuestLog.Pinned()
    picture:SetAtlas(on and QuestLog.PIN or QuestLog.PIN_OFF)
    picture:SetDesaturated(not on)
end

local function Pin()
    ns.store.questLogPinned = not QuestLog.Pinned() or nil
    QuestLog.Lay(full)
end

-- The game's quest tracker out of sight while ours is pinned: lent to a hidden frame of ours (Core.Lend; its own
-- code goes on, unseen, its place among the game's frames kept), given back once ours is not, or stands down.
local function Tracker()
    local tracker = rawget(_G, "ObjectiveTrackerFrame")
    local hide = QuestLog.Pinned() and frame and frame:IsShown() and not ns.off
    if hide and tracker and not lent then
        if not away then
            away = CreateFrame("Frame", nil, UIParent)
            away:Hide()
        end
        local lend = Core.Lend(tracker)
        if lend:SetParent(away) then lent = lend end
    elseif not hide and lent then
        local was = lent
        lent = nil
        was:Return()
    end
end

-- Its close button: out of the full map and off the screen.
local function Close()
    ns.store.questLog = false
    ns.store.questLogPinned = nil
    QuestLog.Lay(full)
    ns.Safe("bar", ns.TopBar.Update)
end

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
    box:SetPoint("TOPLEFT", left, -4)
    box:SetPoint("BOTTOMRIGHT", -right, QuestLog.EDGE)
    panel.empty:SetPoint("TOPLEFT", left, -4)
    panel.empty:SetPoint("TOPRIGHT", -right, -4)
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
        dock = true, dragDocked = true, sizable = true, grip = "hover",
        minWidth = QuestLog.LEAST, minHeight = QuestLog.LEAST, first = FIRST[true],
        buttons = { { atlas = QuestLog.PIN_OFF, tip = QuestLog.TEXT.pin, text = QuestLog.TEXT.pinTip,
                      click = function() ns.Guarded(Pin) end } },
        close = function() ns.Guarded(Close) end,
        titleClick = function() ns.Guarded(Resorted) end,
        titleTip = { SortedTip, NextTip },
        barClick = function() ns.Guarded(QuestLog.Fold, not QuestLog.Folded()) end,
        bare = function() return not full end, -- on the screen alone: no pin, no close button
        usable = function() return not InCombatLockdown() end, -- its items cannot follow it in a fight
        lifted = function() ns.Guarded(Lifted) end,
        docked = function() ns.Guarded(Sided) end,
    })
    QuestLog.handle = handle
    full = true
    tray = CreateFrame("Frame", nil, UIParent)
    tray:SetAllPoints(UIParent)
    tray:Hide()
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
    measure = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    measure:SetPoint("TOPLEFT")
    measure:SetSpacing(2)
    measure:SetAlpha(0)
    -- Sized: an open quest's text wraps anew; on the screen alone its rows' words are measured again.
    local function Sized()
        if open then QuestLog.Refresh() end
        if not full and box.ForEachFrame then box:ForEachFrame(Reach) end
        Scroller()
        seat()
    end
    panel:SetScript("OnSizeChanged", ns.Guard(Sized))
    handle:Place() -- where it was left; at its first place and size if it never was moved
    Body()
    pinButton = handle.own and handle.own[1]
    PinLook()
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

-- Its look (Saneroki 2026-10-29): over the full map (on) its background, above the map's layer, the map not
-- clicked through it, its pin and close button, every objective; on the screen alone, in the game's minimap's
-- layer, none of these: clicked through but its title bar and its rows' words. Each look at its own place, kept.
local function Dress(on)
    on = on and true or false
    if on ~= full then stale = true end
    full = on
    Body()
    frame:SetFrameStrata(on and "DIALOG" or "LOW") -- the full map stands in the layer HIGH (Core's Edge)
    handle:Use(KEY[on], FIRST[on])
    handle:Refresh()
end

-- Shown or not, as the map is (on: it fills the screen and stands there) and the log is chosen: over the full map
-- while the bar's button has it in, on the screen alone while pinned (Dress: its look in each).
function QuestLog.Lay(on)
    if not frame then return end
    Dress(on)
    local shown = (full and ns.TopBar.LogShown()) or QuestLog.Pinned()
    frame:SetAlpha(1)
    tray:SetAlpha(1)
    if shown and not frame:IsShown() then frame:Show() elseif not shown and frame:IsShown() then frame:Hide() end
    PinLook()
    Tracker()
    if shown and stale then QuestLog.Refresh() end
    if not shown then
        ns.Areas.Hover(nil)
        Tick(false)
    end
    seat()
end

-- On the window's way to the full screen and back (share: how far it has come towards the full screen, 0 to 1):
-- a log not pinned comes in and goes out with the map; a pinned one stays as it is until the map stands.
function QuestLog.Fade(share, coming)
    if not frame or QuestLog.Pinned() or not ns.TopBar.LogShown() then return end
    if not frame:IsShown() and coming then
        Dress(true)
        frame:Show()
        if stale then QuestLog.Refresh() end
        seat()
    end
    frame:SetAlpha(share)
    tray:SetAlpha(share)
end

function QuestLog.Shown()
    return frame and frame:IsShown() or false
end

-- The module stood down: the window goes, the game's quest tracker is back.
function QuestLog.Hide()
    if frame then frame:Hide() end
    Tick(false)
    Tracker()
    seat()
end

ns.Listen("LIVE", function(what)
    if what == "quests" or what == "waypoint" then QuestLog.Refresh() end
end)

-- An item a preview names arrived from the game: its name in the words, once on the next frame however many came.
local named = Core.Later(function()
    if open and chosen and Previewed(chosen) then QuestLog.Refresh() end
end)
ns.On("ITEM_DATA_LOAD_RESULT", function()
    if chosen and Previewed(chosen) then named() end
end)
