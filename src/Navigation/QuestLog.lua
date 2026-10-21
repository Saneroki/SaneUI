local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - QuestLog
--  The quest log, a window of its own over the full map (in or out by the bar's
--  button, TopBar.lua). Our own
--  list (the game's belongs to its map window, which stays closed), read from
--  the game's quest log: its zones as headers, each quest under its zone with
--  its level and state, its objectives under it. Built again once a frame after
--  the game says the log changed, and only while it is in sight.
--
--      a header      a click folds it in or out, as the game's own log keeps it
--      a quest       its mark at the left, as its pin on the map has it (the yellow question mark). A click:
--                    the game's map pin on its objective, where the map shows it (its question mark, or the
--                    middle of the area where its foes are), and the game's arrow leads to it; the map stays
--                    as it is. Shift and a click: watched or not (the game's objective tracker); the chat
--                    link's modifier: its link into the chat; the right button: a menu (its text below the
--                    list, the map moved to its objective, watch, share, abandon after a question). The mouse
--                    over it: its area on the map (Areas.lua)
--      below         a quest's text, chosen from its menu (or by a click on its pin on the map): its
--                    objectives' words and its story, and its buttons; its X closes it
--      previews      quests of Core's data a click on their giver's pin showed (QuestLog.Preview): on top,
--                    under Not in your log, grey, each with its giver's mark and the game's red X that takes
--                    it out again; what the data knows of it below (why it is not for you yet, its level, who
--                    gives and takes it, what it asks first, its objectives, its rewards); a click puts the
--                    game's map pin at its giver. Kept until the next /reload
--
--  No scroll bar at rest: the mouse wheel scrolls the list. While the mouse is on the window and the list is
--  longer than its room, the game's thin scroll bar shows at the side the window stands at (docked at the
--  screen's left edge: at its left), in the room of the window's edge.
--
--  The window (one of Core's): moved by its title bar, docked at a screen edge,
--  sized by its corner's grip while the mouse is on it; where it stands and its
--  size are kept. Its title bar's pin (the game's pin of its recent allies) keeps
--  it on the screen while the map is small too (kept, Saneroki 2026-10-20):
--  then it has no background, no border and no line under its title bar, only
--  the list and its words over the game. Over the full map it has its dark
--  background, to be read over the map; its close button takes it out of both.
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
QuestLog.BACK = 0.88      -- its background's opacity over the full map (pinned on the screen alone: none)
QuestLog.EDGE = 10        -- room inside its edges
QuestLog.HEADER, QuestLog.QUEST, QuestLog.OBJECTIVE = 24, 20, 16 -- the rows' heights
QuestLog.MARK = 16        -- a quest's mark at its row's left; its words start after it
QuestLog.DETAILS = 0.42   -- the share of the panel's height the chosen quest's text takes
QuestLog.TEXT = {
    title = Core.Word("QUEST_LOG", "Quest Log"),
    count = "%d / %d",
    empty = "No quests. Quests you accept are listed here.",
    complete = Core.Word("COMPLETE", "Complete"),
    failed = Core.Word("FAILED", "Failed"),
    watch = Core.Word("TRACK_QUEST", "Track Quest"), unwatch = Core.Word("UNTRACK_QUEST", "Untrack Quest"),
    details = Core.Word("QUEST_DETAILS", "Quest Details"),
    closeDetails = Core.Word("CLOSE", "Close"),
    share = Core.Word("SHARE_QUEST", "Share Quest"),
    abandon = Core.Word("ABANDON_QUEST", "Abandon Quest"),
    abandonAsk = Core.Word("ABANDON_QUEST_CONFIRM", "Abandon \"%s\"?"),
    showMap = Core.Word("SHOW_MAP", "Show Map"),
    objectives = Core.Word("QUEST_OBJECTIVES", "Quest Objectives"),
    description = Core.Word("QUEST_DESCRIPTION", "Description"),
    previews = "Not in your log",
    pin = "Pin",
    pinTip = "Keeps the quest log on the screen while the map is small too, without its background. Click again: only over the full map.",
    remove = "Take it out of the log",
    offered = "You can take this quest.",
    level = "Level %d",
    givenBy = "Given by: %s",
    takenBy = "Turned in to: %s",
    rewards = Core.Word("QUEST_REWARDS", "Rewards"),
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

local panel, box, view, bar, details, story, words, buttons
local frame, handle, back, pinButton
local full = false -- the map fills the screen and stands there (Lay)
local rows = {}    -- what the list shows: { kind = "header" | "quest" | "objective", ... }
local stale = true -- the log changed while out of sight
local chosen       -- the quest last clicked or shown, lit in the list
local open = false -- its text shows below the list
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
-- The log as rows: each header, its quests (not the hidden ones), each quest's objectives.
local function Read()
    wipe(rows)
    if #previews > 0 then
        rows[#rows + 1] = { kind = "header", text = QuestLog.TEXT.previews }
        for _, quest in ipairs(previews) do
            rows[#rows + 1] = { kind = "preview", quest = quest, text = QUESTS:Get(quest, "name") or ("#" .. quest),
                                level = QUESTS:Get(quest, "level"), standing = (ns.Pins.Standing(QUESTS:Get(quest), quest)) }
        end
    end
    local count = Plain(Core.Ask(C_QuestLog.GetNumQuestLogEntries)) or 0
    local quests = 0
    for index = 1, count do
        local info = Core.Ask(C_QuestLog.GetInfo, index)
        if type(info) == "table" then
            if info.isHeader then
                rows[#rows + 1] = { kind = "header", text = info.title, index = index, collapsed = info.isCollapsed }
            elseif not info.isHidden and info.questID then
                quests = quests + 1
                local quest = info.questID
                local complete = Core.Ask(C_QuestLog.IsComplete, quest) and true or false
                local failed = Core.Ask(C_QuestLog.IsFailed, quest) and true or false
                rows[#rows + 1] = { kind = "quest", quest = quest, text = info.title, level = info.level, index = index,
                                    complete = complete, failed = failed, scaling = info.isScaling,
                                    watched = (Core.Ask(C_QuestLog.GetQuestWatchType, quest)) ~= nil }
                local objectives = Core.Ask(C_QuestLog.GetQuestObjectives, quest)
                for _, objective in ipairs(type(objectives) == "table" and objectives or {}) do
                    if objective.text and objective.text ~= "" then
                        rows[#rows + 1] = { kind = "objective", quest = quest, text = objective.text, done = objective.finished }
                    end
                end
            end
        end
    end
    return quests
end

-------------------------------------------------------------------------------
--  Doing
-------------------------------------------------------------------------------
-- A place on a map where the quest is done or turned in: the player's own maps first, then the zones of
-- every plane (the continents, Zephras Isle), then the game's next way to it. nil when the game tells none.
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

-- Abandoned only after a question, in the game's own dialog.
local function Abandon(quest)
    if not rawget(_G, "StaticPopup_Show") then return end
    local title = Core.Ask(C_QuestLog.GetTitleForQuestID, quest) or ""
    StaticPopup_Show("GENERIC_CONFIRMATION", nil, nil, { text = QuestLog.TEXT.abandonAsk, text_arg1 = title,
        callback = ns.Guard(function()
            C_QuestLog.SetSelectedQuest(quest)
            C_QuestLog.SetAbandonQuest()
            C_QuestLog.AbandonQuest()
        end) })
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

-- A quest's text below the list (or none: nil), lit in the list.
function QuestLog.Text(quest)
    if quest then chosen = quest end
    open = quest ~= nil
    QuestLog.Refresh()
end

-- The game's arrow leads to a quest in the log; its pin on the arrow's disc at once, not only once the game tells.
local function Lead(quest)
    if not Previewed(quest) then
        C_SuperTrack.SetSuperTrackedQuestID(quest)
        ns.Pins.Changed("quests")
    end
end

-- A click on a quest in the list: the game's map pin on its objective (a preview's: at its giver), the arrow
-- leads to it, lit in the list; the map stays as it is.
local function Pin(quest)
    Lead(quest)
    local map, x, y = Place(quest)
    ns.PinView.Drop({ map = map, x = x, y = y })
    chosen = quest
    QuestLog.Refresh()
end

-- A click on its pin on the map: the arrow leads to it, its text below the list.
function QuestLog.Focus(quest)
    Lead(quest)
    QuestLog.Text(quest)
end

-- The right button's menu: its text below the list, the map at its objective; for a quest in the log the game's
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
    if row.kind == "quest" or row.kind == "preview" then return QuestLog.QUEST end
    return QuestLog.OBJECTIVE
end

local function Colour(row)
    if row.kind == "header" then return 1, 0.82, 0 end
    if row.kind == "preview" then return 0.55, 0.55, 0.55 end
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
        if not row.index then return end -- Not in your log: no header of the game's
        if row.collapsed then ExpandQuestHeader(row.index) else CollapseQuestHeader(row.index) end
        return
    end
    local quest = row.quest
    if mouse == "RightButton" then return Menu(element, quest) end
    if row.kind == "preview" then return Pin(quest) end
    if IsModifiedClick("CHATLINK") then
        local link = rawget(_G, "GetQuestLink") and GetQuestLink(quest)
        local chat = rawget(_G, "ChatFrameUtil")
        if link and chat and chat.InsertLink then chat.InsertLink(link) end
        return
    end
    if IsShiftKeyDown() then return Watch(quest, not row.watched) end
    Pin(quest)
end

local function Entered(element)
    Hover()
    local row = element.row
    if row and row.quest then ns.Areas.Hover(row.quest) end
end

local function Left()
    ns.Areas.Hover(nil)
end

-- A quest's mark at its row's left, as its pin on the map has it: a quest in the log the yellow question mark; a
-- preview its giver's (the yellow exclamation mark, grey for a quest too low, the red question mark for one for later).
local MARKS = { offered = "offer", low = "grey", later = "later", log = "log" }
local function Mark(icon, row)
    local standing = row.kind == "quest" and "log" or row.standing
    icon:SetAtlas(ns.Pins.ICONS[MARKS[standing] or "done"])
    icon:SetDesaturated(standing == "low")
    local red = standing == "later" and ns.Pins.RED
    if red then icon:SetVertexColor(red[1], red[2], red[3], 1) else icon:SetVertexColor(1, 1, 1, 1) end
    icon:Show()
end

-- A row's frame, made the first time the list draws one (the list's elements are plain buttons).
local function Draw(element, row)
    if not element.text then
        element.icon = element:CreateTexture(nil, "ARTWORK")
        element.icon:SetSize(QuestLog.MARK, QuestLog.MARK)
        element.icon:SetPoint("LEFT", 0, 0)
        element.text = element:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        element.text:SetJustifyH("LEFT")
        element.text:SetWordWrap(false)
        element.state = element:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        element.state:SetPoint("RIGHT", -4, 0)
        element.mark = element:CreateTexture(nil, "ARTWORK")
        element.mark:SetSize(12, 12)
        element.light = element:CreateTexture(nil, "HIGHLIGHT")
        element.light:SetAllPoints()
        element.light:SetColorTexture(1, 1, 1, 0.08)
        -- A preview's red X: takes it out of the log again.
        element.remove = CreateFrame("Button", nil, element)
        element.remove:SetSize(16, 16)
        element.remove:SetPoint("RIGHT", -2, 0)
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
    text:ClearAllPoints()
    mark:ClearAllPoints()
    state:SetText("")
    mark:Hide()
    element.icon:Hide()
    element.remove:SetShown(row.kind == "preview")
    if row.kind == "header" then
        text:SetFontObject("GameFontNormal")
        text:SetPoint("LEFT", 16, 0)
        mark:SetAtlas(row.collapsed and "campaign_headericon_closed" or "campaign_headericon_open")
        mark:SetPoint("LEFT", 0, 0)
        mark:Show()
        text:SetText(row.text or "")
    elseif row.kind == "preview" then
        Mark(element.icon, row)
        text:SetFontObject("GameFontHighlight")
        text:SetPoint("LEFT", QuestLog.MARK + 4, 0)
        text:SetPoint("RIGHT", element.remove, "LEFT", -4, 0)
        text:SetText(row.level and ("[%d] %s"):format(row.level, row.text) or row.text)
    elseif row.kind == "quest" then
        Mark(element.icon, row)
        text:SetFontObject("GameFontHighlight")
        text:SetPoint("LEFT", QuestLog.MARK + 4, 0)
        text:SetText(("[%d] %s"):format(row.level or 0, row.text or ""))
        if row.complete then
            state:SetText(QuestLog.TEXT.complete)
            state:SetTextColor(0.2, 1, 0.2)
        elseif row.failed then
            state:SetText(QuestLog.TEXT.failed)
            state:SetTextColor(1, 0.2, 0.2)
        end
        -- Watched: the game's tick right of its words.
        if row.watched then
            mark:SetAtlas("checkmark-minimal")
            mark:SetPoint("RIGHT", state, "LEFT", -2, 0)
            mark:Show()
            text:SetPoint("RIGHT", mark, "LEFT", -2, 0)
        else
            text:SetPoint("RIGHT", state, "LEFT", -4, 0)
        end
    else
        text:SetFontObject("GameFontHighlightSmall")
        text:SetPoint("LEFT", 30, 0)
        text:SetPoint("RIGHT", -4, 0)
        text:SetText("- " .. (row.text or ""))
    end
    text:SetTextColor(Colour(row))
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

-- What Core's data knows of a quest not in the log, as the log's words: why it is not for this character yet, its
-- level, who gives and takes it, what it asks first, its objectives and its rewards.
local function Preview(quest)
    local record = QUESTS:Get(quest) or {}
    local parts = { "|cff999999" .. (record.name or ("#" .. quest)) .. "|r" }
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
    if #objectives > 0 then
        parts[#parts + 1] = "|cffffd100" .. QuestLog.TEXT.objectives .. "|r\n" .. table.concat(objectives, "\n")
    end
    local rewards = {}
    if record.rewardXP and record.rewardXP > 0 then rewards[#rewards + 1] = QuestLog.TEXT.experience:format(record.rewardXP) end
    local coins = rawget(_G, "GetCoinTextureString")
    if record.rewardMoney and record.rewardMoney > 0 and coins then rewards[#rewards + 1] = coins(record.rewardMoney) end
    for _, list in ipairs({ record.rewardItems or {}, record.rewardChoices or {} }) do
        for _, entry in ipairs(list) do
            rewards[#rewards + 1] = Item(entry.item) .. ((entry.count or 1) > 1 and (" x" .. entry.count) or "")
        end
    end
    if #rewards > 0 then
        parts[#parts + 1] = "|cffffd100" .. QuestLog.TEXT.rewards .. "|r\n" .. table.concat(rewards, "\n")
    end
    return table.concat(parts, "\n\n")
end

-- The words below the list (a preview's from Core's data), the buttons only for a quest in the log.
local function Words(text, inLog)
    local width = math.max(details.scroll:GetWidth() - 4, 1)
    words:SetWidth(width)
    words:SetText(text)
    story:SetSize(width, math.max(words:GetStringHeight(), 1))
    details.scroll:SetVerticalScroll(0)
    for _, button in pairs(buttons) do button:SetShown(inLog) end
    details:Show()
    box:SetPoint("BOTTOMRIGHT", details, "TOPRIGHT", 0, 6)
end

-- The words below the list away: the list down to the panel's foot.
local function NoWords()
    details:Hide()
    box:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -QuestLog.EDGE, QuestLog.EDGE)
end

function QuestLog.Details()
    if not details then return end
    if chosen and Previewed(chosen) then
        if open then return Words(Preview(chosen), false) end
        return NoWords()
    end
    local index = chosen and Core.Ask(C_QuestLog.GetLogIndexForQuestID, chosen)
    if not index or index <= 0 then chosen, open = nil, false end
    if not open then return NoWords() end
    local description, objectives
    if rawget(_G, "GetQuestLogQuestText") then description, objectives = GetQuestLogQuestText(index) end
    local title = Core.Ask(C_QuestLog.GetTitleForQuestID, chosen) or ""
    local parts = { "|cffffd100" .. title .. "|r" }
    if objectives and objectives ~= "" then parts[#parts + 1] = objectives end
    if description and description ~= "" then
        parts[#parts + 1] = "|cffffd100" .. QuestLog.TEXT.description .. "|r"
        parts[#parts + 1] = description
    end
    Words(table.concat(parts, "\n\n"), true)
    local watched = (Core.Ask(C_QuestLog.GetQuestWatchType, chosen)) ~= nil
    buttons.watch:SetText(watched and QuestLog.TEXT.unwatch or QuestLog.TEXT.watch)
    buttons.share:SetEnabled(Core.Ask(C_QuestLog.IsPushableQuest, chosen) and IsInGroup() or false)
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
    if not ns.TopBar.LogShown() then
        ns.store.questLog = true
        QuestLog.Lay(full)
    end
    ns.Window.OpenTo(map, x, y)
    QuestLog.Refresh()
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
--  The panel
-------------------------------------------------------------------------------
local function Button(parent, text, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetHeight(22)
    button:SetText(text)
    button:SetScript("OnClick", ns.Guard(function() if chosen then click(chosen) end end))
    return button
end

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
-- room, at the window's side (Side), in the room of its edge (QuestLog.EDGE).
local function Scroller()
    local shown = frame:IsMouseOver() and box.HasScrollableExtent and box:HasScrollableExtent() and true or false
    if shown then
        local left = Side() == "LEFT"
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

function Hover()
    handle:Hover(true)
    Scroller()
    if not frame:GetScript("OnUpdate") then frame:SetScript("OnUpdate", ns.Guard(Watching)) end
end

-- The window, built at login with the map's (Window.lua); hidden until the full map or its pin shows it.
function QuestLog.Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("LOW")
    frame:Hide()
    handle = Core.Window.New(frame, {
        store = ns.store, key = "questLogPlace", title = QuestLog.TEXT.title, titleBar = true, barLine = false,
        dock = true, dragDocked = true, sizable = true, grip = "hover",
        minWidth = QuestLog.LEAST, minHeight = QuestLog.LEAST,
        first = { point = "TOPLEFT", x = QuestLog.FIRST.x, y = QuestLog.FIRST.y, width = QuestLog.WIDTH,
                  height = QuestLog.HEIGHT },
        buttons = { { atlas = QuestLog.PIN_OFF, tip = QuestLog.TEXT.pin, text = QuestLog.TEXT.pinTip,
                      click = function() ns.Guarded(Pin) end } },
        close = function() ns.Guarded(Close) end,
    })
    QuestLog.handle = handle
    frame:EnableMouse(true) -- the map behind it is not clicked through it
    frame:SetScript("OnEnter", ns.Guard(Hover))
    back = frame:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0.03, 0.03, 0.04, QuestLog.BACK)

    panel = CreateFrame("Frame", nil, handle.inside)
    panel:SetAllPoints()
    panel.count = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.count:SetPoint("TOPRIGHT", -QuestLog.EDGE, -4)
    panel.empty = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    panel.empty:SetPoint("TOPLEFT", QuestLog.EDGE, -24)
    panel.empty:SetPoint("RIGHT", -QuestLog.EDGE, 0)
    panel.empty:SetJustifyH("LEFT")
    panel.empty:SetText(QuestLog.TEXT.empty)

    box = CreateFrame("Frame", nil, panel, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", QuestLog.EDGE, -20)
    box:SetPoint("BOTTOMRIGHT", -QuestLog.EDGE, QuestLog.EDGE)
    bar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    bar:Hide()
    view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(Height)
    view:SetElementInitializer("Button", Draw)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)

    -- The chosen quest's words and buttons.
    details = CreateFrame("Frame", nil, panel)
    details:SetPoint("BOTTOMLEFT", QuestLog.EDGE, QuestLog.EDGE)
    details:SetPoint("BOTTOMRIGHT", -QuestLog.EDGE, QuestLog.EDGE)
    details:Hide()
    local rule = details:CreateTexture(nil, "BORDER")
    rule:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.4)
    rule:SetPoint("TOPLEFT")
    rule:SetPoint("TOPRIGHT")
    rule:SetHeight(1)
    -- Its X: the words away, the list down to the foot again.
    local close = CreateFrame("Button", nil, details, "UIPanelCloseButtonNoScripts")
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", 2, -2)
    close:SetScript("OnClick", ns.Guard(function() QuestLog.Text(nil) end))
    Core.Tip(close, QuestLog.TEXT.closeDetails, nil, "ANCHOR_TOP")
    buttons = {
        watch = Button(details, QuestLog.TEXT.watch, function(quest)
            Watch(quest, (Core.Ask(C_QuestLog.GetQuestWatchType, quest)) == nil)
        end),
        share = Button(details, QuestLog.TEXT.share, Share),
        abandon = Button(details, QuestLog.TEXT.abandon, Abandon),
    }
    buttons.watch:SetPoint("BOTTOMLEFT")
    buttons.abandon:SetPoint("BOTTOMRIGHT")
    buttons.share:SetPoint("LEFT", buttons.watch, "RIGHT", 4, 0)
    buttons.share:SetPoint("RIGHT", buttons.abandon, "LEFT", -4, 0)
    local scroll = CreateFrame("ScrollFrame", nil, details)
    scroll:SetPoint("TOPLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", buttons.abandon, "TOPRIGHT", -20, 6)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", ns.Guard(function(self, delta)
        local most = math.max(0, words:GetStringHeight() - self:GetHeight())
        self:SetVerticalScroll(math.min(most, math.max(0, self:GetVerticalScroll() - delta * 30)))
    end))
    story = CreateFrame("Frame", nil, scroll)
    story:SetSize(1, 1)
    scroll:SetScrollChild(story)
    words = story:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    words:SetPoint("TOPLEFT")
    words:SetJustifyH("LEFT")
    words:SetSpacing(2)
    details.scroll = scroll
    -- Sized: the words take their share of its height, the three buttons its width.
    local function Sized()
        details:SetHeight(panel:GetHeight() * QuestLog.DETAILS)
        local width = (panel:GetWidth() - 2 * QuestLog.EDGE - 8) / 3
        for _, button in pairs(buttons) do button:SetWidth(math.max(width, 1)) end
        if chosen and details:IsShown() then QuestLog.Details() end
        Scroller()
    end
    panel:SetScript("OnSizeChanged", ns.Guard(Sized))
    handle:Place() -- where it was left; at its first place and size if it never was moved
    pinButton = handle.own and handle.own[1]
    PinLook()
    return frame
end

-- The list drawn anew from the game's log, if it is in sight; else once it is.
function QuestLog.Refresh()
    if not frame or not frame:IsShown() then
        stale = true
        return
    end
    stale = false
    local quests = Read()
    local most = Plain(Core.Ask(C_QuestLog.GetMaxNumQuestsCanAccept)) or 25
    panel.count:SetText(QuestLog.TEXT.count:format(quests, most))
    panel.empty:SetShown(quests == 0)
    box:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
    QuestLog.Details()
    Scroller()
end

-- Shown or not, as the map is (on: it fills the screen and stands there) and the log is chosen: over the full map
-- while the bar's button has it in (its background there, above the map's layer), on the screen alone while
-- pinned (no background, in the game's minimap's layer).
function QuestLog.Lay(on)
    if not frame then return end
    full = on and true or false
    local shown = (full and ns.TopBar.LogShown()) or QuestLog.Pinned()
    back:SetShown(full)
    frame:SetFrameStrata(full and "DIALOG" or "LOW") -- the full map stands in the layer HIGH (Core's Edge)
    frame:SetAlpha(1)
    if shown and not frame:IsShown() then frame:Show() elseif not shown and frame:IsShown() then frame:Hide() end
    PinLook()
    if shown and stale then QuestLog.Refresh() end
    if not shown then ns.Areas.Hover(nil) end
end

-- On the window's way to the full screen and back (share: how far it has come towards the full screen, 0 to 1):
-- a log not pinned comes in and goes out with the map; a pinned one stays as it is.
function QuestLog.Fade(share, coming)
    if not frame or QuestLog.Pinned() or not ns.TopBar.LogShown() then return end
    if not frame:IsShown() and coming then
        back:SetShown(true)
        frame:SetFrameStrata("DIALOG")
        frame:Show()
        if stale then QuestLog.Refresh() end
    end
    frame:SetAlpha(share)
end

function QuestLog.Shown()
    return frame and frame:IsShown() or false
end

-- The module stood down: the window goes.
function QuestLog.Hide()
    if frame then frame:Hide() end
end

ns.Listen("LIVE", function(what)
    if what == "quests" or what == "waypoint" then QuestLog.Refresh() end
end)

-- An item a preview names arrived from the game: its name in the words.
ns.On("ITEM_DATA_LOAD_RESULT", function()
    if chosen and Previewed(chosen) and QuestLog.Shown() then QuestLog.Details() end
end)
