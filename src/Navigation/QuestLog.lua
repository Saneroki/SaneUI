local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - QuestLog
--  The quest log, on the left of the full map; the map takes the rest. Our own
--  list (the game's belongs to its map window, which stays closed), read from
--  the game's quest log: its zones as headers, each quest under its zone with
--  its level and state, its objectives under it. Built again once a frame after
--  the game says the log changed, and only while it is in sight.
--
--      a header      a click folds it in or out, as the game's own log keeps it
--      a quest       a click: the game's arrow leads to it, the map shows where it is, its text below;
--                    Shift and a click: watched or not (the game's objective tracker); the chat link's
--                    modifier: its link into the chat; the right button: a menu (watch, lead to it,
--                    share, abandon after a question). The mouse over it: its area on the map (Areas.lua)
--      below         the chosen quest: its objectives' words and its story, and its buttons
--      previews      quests of Core's data a click on their giver's pin showed (QuestLog.Preview): on top,
--                    under Not in your log, grey, each with the game's red X that takes it out again; chosen,
--                    what the data knows of it below (why it is not for you yet, its level, who gives and
--                    takes it, what it asks first, its objectives, its rewards). Kept until the next /reload
--
--  Only the game's quest API (C_QuestLog, the game's quest link and share), never
--  the quest panels of the game's map: called from here they would taint its pins.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local QuestLog = {}
ns.QuestLog = QuestLog

QuestLog.WIDTH = 320      -- the panel's width
QuestLog.EDGE = 10        -- room inside its edges
QuestLog.HEADER, QuestLog.QUEST, QuestLog.OBJECTIVE = 24, 20, 16 -- the rows' heights
QuestLog.DETAILS = 0.42   -- the share of the panel's height the chosen quest's text takes
QuestLog.TEXT = {
    title = Core.Word("QUEST_LOG", "Quest Log"),
    count = "%d / %d",
    empty = "No quests. Quests you accept are listed here.",
    complete = Core.Word("COMPLETE", "Complete"),
    failed = Core.Word("FAILED", "Failed"),
    watch = Core.Word("TRACK_QUEST", "Track Quest"), unwatch = Core.Word("UNTRACK_QUEST", "Untrack Quest"),
    lead = "Lead the arrow here",
    share = Core.Word("SHARE_QUEST", "Share Quest"),
    abandon = Core.Word("ABANDON_QUEST", "Abandon Quest"),
    abandonAsk = Core.Word("ABANDON_QUEST_CONFIRM", "Abandon \"%s\"?"),
    showMap = Core.Word("SHOW_MAP", "Show Map"),
    objectives = Core.Word("QUEST_OBJECTIVES", "Quest Objectives"),
    description = Core.Word("QUEST_DESCRIPTION", "Description"),
    previews = "Not in your log",
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

local QUESTS, NPCS, OBJECTS = Core.Data.Set("Quests"), Core.Data.Set("NPCs"), Core.Data.Set("Objects")
local previews = {} -- quests shown from the map's pins (Preview), newest first

local panel, box, view, bar, details, story, words, buttons, header
local rows = {}    -- what the list shows: { kind = "header" | "quest" | "objective", ... }
local stale = true -- the log changed while out of sight
local chosen       -- the quest whose text shows below

local function Plain(value)
    return Core.Plain(value)
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
                                level = QUESTS:Get(quest, "level") }
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

-- The map at the quest's place: the full screen, the zone it is in whole around it, its text below.
function QuestLog.Show(quest)
    chosen = quest
    QuestLog.Details()
    local map, x, y = Where(quest)
    if map then ns.Window.OpenTo(map, x, y) end
end

-- A quest chosen (in the log, or by its pin): the game's arrow leads to it, the map shows where it is.
function QuestLog.Focus(quest)
    C_SuperTrack.SetSuperTrackedQuestID(quest)
    ns.Pins.Changed("quests") -- its pin on the arrow's disc at once, not only once the game tells
    QuestLog.Show(quest)
    QuestLog.Refresh()
end

local function Menu(owner, quest)
    if not rawget(_G, "MenuUtil") then return end
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        root:CreateTitle(Core.Ask(C_QuestLog.GetTitleForQuestID, quest) or "")
        local watched = (Core.Ask(C_QuestLog.GetQuestWatchType, quest)) ~= nil
        root:CreateButton(watched and QuestLog.TEXT.unwatch or QuestLog.TEXT.watch,
            ns.Guard(function() Watch(quest, not watched) end))
        root:CreateButton(QuestLog.TEXT.lead, ns.Guard(function() QuestLog.Focus(quest) end))
        root:CreateButton(QuestLog.TEXT.showMap, ns.Guard(function() QuestLog.Show(quest) end))
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
    if row.kind == "preview" then
        chosen = row.quest
        return QuestLog.Refresh()
    end
    local quest = row.quest
    if mouse == "RightButton" then return Menu(element, quest) end
    if IsModifiedClick("CHATLINK") then
        local link = rawget(_G, "GetQuestLink") and GetQuestLink(quest)
        local chat = rawget(_G, "ChatFrameUtil")
        if link and chat and chat.InsertLink then chat.InsertLink(link) end
        return
    end
    if IsShiftKeyDown() then return Watch(quest, not row.watched) end
    QuestLog.Focus(quest)
end

local function Entered(element)
    local row = element.row
    if row and row.quest then ns.Areas.Hover(row.quest) end
end

local function Left()
    ns.Areas.Hover(nil)
end

-- A row's frame, made the first time the list draws one (the list's elements are plain buttons).
local function Draw(element, row)
    if not element.text then
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
    state:SetText("")
    mark:Hide()
    element.remove:SetShown(row.kind == "preview")
    if row.kind == "header" then
        text:SetFontObject("GameFontNormal")
        text:SetPoint("LEFT", 16, 0)
        mark:SetAtlas(row.collapsed and "campaign_headericon_closed" or "campaign_headericon_open")
        mark:SetPoint("LEFT", 0, 0)
        mark:Show()
        text:SetText(row.text or "")
    elseif row.kind == "preview" then
        text:SetFontObject("GameFontHighlight")
        text:SetPoint("LEFT", 16, 0)
        text:SetPoint("RIGHT", element.remove, "LEFT", -4, 0)
        text:SetText(row.level and ("[%d] %s"):format(row.level, row.text) or row.text)
    elseif row.kind == "quest" then
        text:SetFontObject("GameFontHighlight")
        text:SetPoint("LEFT", 16, 0)
        text:SetPoint("RIGHT", state, "LEFT", -4, 0)
        text:SetText(("[%d] %s"):format(row.level or 0, row.text or ""))
        if row.complete then
            state:SetText(QuestLog.TEXT.complete)
            state:SetTextColor(0.2, 1, 0.2)
        elseif row.failed then
            state:SetText(QuestLog.TEXT.failed)
            state:SetTextColor(1, 0.2, 0.2)
        end
        if row.watched then
            mark:SetAtlas("checkmark-minimal")
            mark:SetPoint("LEFT", 2, 0)
            mark:Show()
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
-- The chosen quest's words below the list: its objectives and its story, as the game's log tells them.
local function Previewed(quest)
    for index, each in ipairs(previews) do if each == quest then return index end end
    return nil
end

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
    box:SetPoint("BOTTOMRIGHT", details, "TOPRIGHT", -14, 6)
end

function QuestLog.Details()
    if not details then return end
    if chosen and Previewed(chosen) then return Words(Preview(chosen), false) end
    local index = chosen and Core.Ask(C_QuestLog.GetLogIndexForQuestID, chosen)
    if not index or index <= 0 then
        chosen = nil
        details:Hide()
        box:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -QuestLog.EDGE - 14, QuestLog.EDGE)
        return
    end
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
    end
    chosen = quests[1]
    if not ns.TopBar.LogShown() then
        ns.store.questLog = true
        ns.Window.Lay()
    end
    ns.Window.OpenTo(map, x, y)
    QuestLog.Refresh()
end

-- A preview taken out of the log again (its red X).
function QuestLog.Unpreview(quest)
    local at = Previewed(quest)
    if not at then return end
    table.remove(previews, at)
    if chosen == quest then chosen = nil end
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

-- The panel in parent, at its left edge, as tall as it; hidden until the full screen shows it.
function QuestLog.Build(parent)
    panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT")
    panel:SetPoint("BOTTOMLEFT")
    panel:SetWidth(QuestLog.WIDTH)
    panel:EnableMouse(true) -- the map behind it is not clicked through it
    local back = panel:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0.03, 0.03, 0.04, 0.88)
    local line = panel:CreateTexture(nil, "BORDER")
    line:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.5)
    line:SetPoint("TOPRIGHT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetWidth(1)

    header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", QuestLog.EDGE, -QuestLog.EDGE)
    header:SetText(QuestLog.TEXT.title)
    panel.count = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.count:SetPoint("TOPRIGHT", -QuestLog.EDGE, -QuestLog.EDGE - 4)
    panel.empty = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    panel.empty:SetPoint("TOPLEFT", QuestLog.EDGE, -48)
    panel.empty:SetPoint("RIGHT", -QuestLog.EDGE, 0)
    panel.empty:SetJustifyH("LEFT")
    panel.empty:SetText(QuestLog.TEXT.empty)

    box = CreateFrame("Frame", nil, panel, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", QuestLog.EDGE, -40)
    box:SetPoint("BOTTOMRIGHT", -QuestLog.EDGE - 14, QuestLog.EDGE)
    bar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, 0)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 0)
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
    for _, button in pairs(buttons) do button:SetWidth((QuestLog.WIDTH - 2 * QuestLog.EDGE - 8) / 3) end
    local scroll = CreateFrame("ScrollFrame", nil, details)
    scroll:SetPoint("TOPLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", buttons.abandon, "TOPRIGHT", 0, 6)
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
    panel:SetScript("OnSizeChanged", ns.Guard(function()
        details:SetHeight(panel:GetHeight() * QuestLog.DETAILS)
    end))
    panel:Hide()
    return panel
end

-- The list drawn anew from the game's log, if it is in sight; else once it is.
function QuestLog.Refresh()
    if not panel or not panel:IsShown() then
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
end

-- In sight (the full screen with the log) or not.
function QuestLog.SetShown(on)
    if not panel then return end
    panel:SetShown(on)
    if on and stale then QuestLog.Refresh() end
    if not on then ns.Areas.Hover(nil) end
end

-- How far it has come in on the window's way to the full screen (0 to 1).
function QuestLog.Fade(share)
    if panel then panel:SetAlpha(share) end
end

function QuestLog.Shown()
    return panel and panel:IsShown() or false
end

ns.Listen("LIVE", function(what)
    if what == "quests" or what == "waypoint" then QuestLog.Refresh() end
end)

-- An item a preview names arrived from the game: its name in the words.
ns.On("ITEM_DATA_LOAD_RESULT", function()
    if chosen and Previewed(chosen) and QuestLog.Shown() then QuestLog.Details() end
end)
