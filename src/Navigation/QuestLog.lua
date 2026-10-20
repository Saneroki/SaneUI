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
}

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
-- the continents, then the game's next way to it. nil when the game tells none.
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
    for _, continent in ipairs(ns.Coords.Continents()) do
        for _, zone in ipairs(ns.Coords.Zones(continent)) do
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
    if row.kind == "quest" then return QuestLog.QUEST end
    return QuestLog.OBJECTIVE
end

local function Colour(row)
    if row.kind == "header" then return 1, 0.82, 0 end
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
        if row.collapsed then ExpandQuestHeader(row.index) else CollapseQuestHeader(row.index) end
        return
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
    if row.kind == "header" then
        text:SetFontObject("GameFontNormal")
        text:SetPoint("LEFT", 16, 0)
        mark:SetAtlas(row.collapsed and "campaign_headericon_closed" or "campaign_headericon_open")
        mark:SetPoint("LEFT", 0, 0)
        mark:Show()
        text:SetText(row.text or "")
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
    if row.quest and row.quest == chosen and row.kind == "quest" then
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
function QuestLog.Details()
    if not details then return end
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
    local width = math.max(details.scroll:GetWidth() - 4, 1)
    words:SetWidth(width)
    words:SetText(table.concat(parts, "\n\n"))
    story:SetSize(width, math.max(words:GetStringHeight(), 1))
    details.scroll:SetVerticalScroll(0)
    local watched = (Core.Ask(C_QuestLog.GetQuestWatchType, chosen)) ~= nil
    buttons.watch:SetText(watched and QuestLog.TEXT.unwatch or QuestLog.TEXT.watch)
    buttons.share:SetEnabled(Core.Ask(C_QuestLog.IsPushableQuest, chosen) and IsInGroup() or false)
    details:Show()
    box:SetPoint("BOTTOMRIGHT", details, "TOPRIGHT", -14, 6)
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
