local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Guild - Views - Overview
--  The guild at a glance, in three columns (Layout.Overview; narrow, the right
--  one folds under the left): at the left the quest requests over the planned
--  runs; in the middle the guild's news (who joined, left, went up or down a
--  rank, reached a level: Core's history of the roster) over the guild's chat
--  with a line to write in; at the right who is where (the members online by
--  zone, their class icons), what members offer the guild, and the race to the
--  highest level (the first three on a podium).
--
--  The quest requests, the runs and the offers come with their own views
--  (Doc/ideas/Guild.md, *Build order*); until then their panels say so.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Views, Layout, Kit, TEXT = ns.Views, ns.Layout, ns.Kit, ns.TEXT
local Overview = {}
Views.overview = Overview

local view, panels = nil, {}
local chat = {} -- the guild's chat since login: { name, class, text, time }, the last 100
local CHAT_MOST = 100

local function Guild() return Core.Data.Guild end

-------------------------------------------------------------------------------
--  What the panels show (no frames: tested)
-------------------------------------------------------------------------------
-- The members online by zone, the zones with most first: { { zone, members = { member, ... } }, ... }.
function Overview.Zones(members)
    local byZone, zones = {}, {}
    for _, member in ipairs(members) do
        if member.online then
            local zone = member.zone or "?"
            if not byZone[zone] then
                byZone[zone] = { zone = zone, members = {} }
                zones[#zones + 1] = byZone[zone]
            end
            table.insert(byZone[zone].members, member)
        end
    end
    table.sort(zones, function(a, b)
        if #a.members ~= #b.members then return #a.members > #b.members end
        return a.zone < b.zone
    end)
    return zones
end

-- The race to the highest level: the members by level, highest first (by name where equal).
function Overview.Race(members, most)
    local list = {}
    for _, member in ipairs(members) do list[#list + 1] = member end
    table.sort(list, function(a, b)
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
        return (a.name or "") < (b.name or "")
    end)
    local top = {}
    for index = 1, math.min(most or 10, #list) do top[index] = list[index] end
    return top
end

-------------------------------------------------------------------------------
--  Panels
-------------------------------------------------------------------------------
local function Later(panel, name)
    local text = Kit.Empty(panel.body)
    text:SetText(TEXT.later:format(name))
end

local function Zones()
    local panel = panels.where
    local rows = panel.rows
    local zones = Overview.Zones(Guild().Roster())
    local me = Core.PlayerKey("player")
    local shown = 0
    for index, entry in ipairs(zones) do
        local others = 0
        for _, member in ipairs(entry.members) do if member.key ~= me then others = others + 1 end end
        if others > 0 or #zones > 1 then
            shown = shown + 1
            local row = rows[shown]
            if not row then
                row = CreateFrame("Frame", nil, panel.body)
                row:SetHeight(Layout.ROW + 2)
                row:SetPoint("TOPLEFT", 4, -(shown - 1) * (Layout.ROW + 2))
                row:SetPoint("RIGHT", -4, 0)
                row.zone = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                row.zone:SetPoint("LEFT")
                row.zone:SetJustifyH("LEFT")
                row.zone:SetWordWrap(false)
                row.more = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
                row.more:SetPoint("RIGHT")
                row.icons = {}
                for i = 1, 6 do
                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(Layout.ICON, Layout.ICON)
                    icon:SetPoint("RIGHT", row.more, "LEFT", -2 - (i - 1) * (Layout.ICON + 1), 0)
                    row.icons[i] = icon
                end
                row.zone:SetPoint("RIGHT", row.icons[6], "LEFT", -4, 0)
                rows[shown] = row
            end
            row.zone:SetText(entry.zone)
            for i, icon in ipairs(row.icons) do
                local member = entry.members[i]
                icon:SetShown(member ~= nil)
                if member then Kit.ClassIcon(icon, member.class) end
            end
            row.more:SetText(#entry.members > 6 and ("+" .. (#entry.members - 6)) or "")
            row:Show()
        end
        if index >= 12 then break end
    end
    for index = shown + 1, #rows do rows[index]:Hide() end
    panel.empty:SetShown(shown == 0)
    panel.tag:SetText(TEXT.online:format(Guild().Info().online or 0))
end

local WHAT = { join = "newsJoin", leave = "newsLeave", up = "newsUp", down = "newsDown", level = "newsLevel" }

local function News()
    local today = math.floor((Core.Ask(GetServerTime) or 0) / 86400)
    local rows = {}
    for _, event in ipairs(Guild().History(nil, 60)) do
        local text = ns.Views.roster and ns.Views.roster.Event and ns.Views.roster.Event(event)
        if text and WHAT[event.what] then
            local member = Guild().Member(event.key)
            rows[#rows + 1] = { text = text, class = member and member.class, ago = Layout.AgoText(Layout.Ago(event.day, today)) }
        end
    end
    panels.news.list:Fill(rows, TEXT.noNews)
end

local function Chat()
    local rows = {}
    for index = #chat, 1, -1 do rows[#rows + 1] = chat[index] end
    panels.chat.list:Fill(rows, "")
end

local function Race()
    local panel = panels.race
    local top = Overview.Race(Guild().Roster(), 10)
    for place = 1, 3 do
        local step, member = panel.steps[place], top[place]
        step:SetShown(member ~= nil)
        if member then
            Kit.ClassIcon(step.icon, member.class)
            step.name:SetText(Kit.Colored(member.name, member.class))
            step.level:SetText(member.level)
        end
    end
    local lines = {}
    for place = 4, #top do
        lines[#lines + 1] = ("%d. %s  |cffb0b0b0%d|r"):format(place, Kit.Colored(top[place].name, top[place].class), top[place].level or 0)
    end
    panel.rest:SetText(table.concat(lines, "\n"))
    panel.empty:SetShown(#top == 0)
end

local function BuildWhere(parent)
    local panel = Kit.Panel(parent, TEXT.whoIsWhere)
    panel.rows = {}
    panel.empty = Kit.Empty(panel.body)
    panel.empty:SetText(TEXT.nobodyOnline)
    return panel
end

local function BuildNews(parent)
    local panel = Kit.Panel(parent, TEXT.news)
    panel.list = Kit.Table(panel.body, {
        columns = { { key = "text", text = "" }, { key = "ago", text = "", width = 80, justify = "RIGHT" } },
        row = Layout.ROW,
        init = function(row, element)
            row.icon:Hide()
            row.cells.text:SetText(element.text)
            row.cells.ago:SetText(element.ago or "")
            Kit.Stripe(row, 0)
        end,
    })
    panel.list:SetAllPoints()
    return panel
end

local function Send(box)
    local text = box:GetText()
    if not text or text == "" then return end
    local chatInfo = rawget(_G, "C_ChatInfo")
    if chatInfo and chatInfo.SendChatMessage then
        chatInfo.SendChatMessage(text, "GUILD")
    elseif rawget(_G, "SendChatMessage") then
        SendChatMessage(text, "GUILD")
    end
    box:SetText("")
    box:ClearFocus()
end

local function BuildChat(parent)
    local panel = Kit.Panel(parent, TEXT.guildChat)
    local box = CreateFrame("EditBox", nil, panel.body, "InputBoxTemplate")
    box:SetHeight(20)
    box:SetPoint("BOTTOMLEFT", 8, 4)
    box:SetPoint("BOTTOMRIGHT", -8, 4)
    box:SetAutoFocus(false)
    box:SetMaxLetters(255)
    box:SetScript("OnEnterPressed", ns.Guard(Send))
    box:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    panel.list = Kit.Table(panel.body, {
        columns = { { key = "time", text = "", width = 36 }, { key = "text", text = "" } },
        row = Layout.ROW,
        init = function(row, element)
            row.icon:Hide()
            row.cells.time:SetText(element.time or "")
            row.cells.text:SetText(Kit.Colored(element.name, element.class) .. ": " .. (element.text or ""))
            Kit.Stripe(row, 0)
        end,
    })
    panel.list:SetPoint("TOPLEFT")
    panel.list:SetPoint("BOTTOMRIGHT", box, "TOPRIGHT", 0, 4)
    return panel
end

local function BuildRace(parent)
    local panel = Kit.Panel(parent, TEXT.race)
    panel.steps = {}
    local medals = { "medalGold", "medalSilver", "medalBronze" }
    local x = { 0, -78, 78 }
    local y = { -6, -22, -30 }
    for place = 1, 3 do
        local step = CreateFrame("Frame", nil, panel.body)
        step:SetSize(76, 64)
        step:SetPoint("TOP", panel.body, "TOP", x[place], y[place])
        step.medal = step:CreateTexture(nil, "ARTWORK")
        step.medal:SetSize(16, 16)
        step.medal:SetPoint("TOP")
        ns.Art.Set(step.medal, medals[place])
        step.icon = step:CreateTexture(nil, "ARTWORK")
        step.icon:SetSize(24, 24)
        step.icon:SetPoint("TOP", step.medal, "BOTTOM", 0, -2)
        step.name = step:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        step.name:SetPoint("TOP", step.icon, "BOTTOM", 0, -2)
        step.name:SetWidth(76)
        step.name:SetWordWrap(false)
        step.level = step:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        step.level:SetPoint("TOP", step.name, "BOTTOM", 0, -1)
        panel.steps[place] = step
    end
    panel.rest = panel.body:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.rest:SetPoint("TOPLEFT", 8, -104)
    panel.rest:SetPoint("RIGHT", -8, 0)
    panel.rest:SetJustifyH("LEFT")
    panel.empty = Kit.Empty(panel.body)
    panel.empty:SetText(TEXT.noLevels)
    return panel
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
local function Lay()
    if not view then return end
    local width = view:GetWidth() or 0
    local height = view:GetHeight() or 0
    if width <= 0 or height <= 0 then return end
    local left, middle, right = Layout.Overview(width)
    local gap = Layout.GAP
    local function At(panel, x, y, w, h)
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", view, "TOPLEFT", x, -y)
        panel:SetSize(math.max(10, w), math.max(10, h))
    end
    local half = math.floor((height - gap) / 2)
    if right > 0 then
        At(panels.quests, 0, 0, left, half)
        At(panels.runs, 0, half + gap, left, height - half - gap)
        local newsHeight = math.floor(height * 0.38)
        At(panels.news, left + gap, 0, middle, newsHeight)
        At(panels.chat, left + gap, newsHeight + gap, middle, height - newsHeight - gap)
        local x = left + middle + 2 * gap
        local whereHeight, raceHeight = math.floor(height * 0.34), 190
        At(panels.where, x, 0, right, whereHeight)
        At(panels.offered, x, whereHeight + gap, right, height - whereHeight - raceHeight - 2 * gap)
        At(panels.race, x, height - raceHeight, right, raceHeight)
    else
        local third = math.floor((height - 2 * gap) / 3)
        At(panels.where, 0, 0, left, third)
        At(panels.race, 0, third + gap, left, third)
        At(panels.quests, 0, 2 * (third + gap), left, height - 2 * (third + gap))
        local newsHeight = math.floor(height * 0.38)
        At(panels.news, left + gap, 0, middle, newsHeight)
        At(panels.chat, left + gap, newsHeight + gap, middle, height - newsHeight - gap)
        panels.runs:Hide()
        panels.offered:Hide()
        return
    end
    panels.runs:Show()
    panels.offered:Show()
end

function Overview.Build(frame)
    view = frame
    panels.quests = Kit.Panel(frame, TEXT.questRequests)
    Later(panels.quests, TEXT.quests)
    panels.runs = Kit.Panel(frame, TEXT.plannedRuns)
    Later(panels.runs, TEXT.runs)
    panels.news = BuildNews(frame)
    panels.chat = BuildChat(frame)
    panels.where = BuildWhere(frame)
    panels.offered = Kit.Panel(frame, TEXT.offered)
    Later(panels.offered, TEXT.offered)
    panels.race = BuildRace(frame)
    frame:SetScript("OnSizeChanged", ns.Guard(Lay))
    Lay()
end

function Overview.Refresh()
    if not view then return end
    Lay()
    Zones()
    News()
    Chat()
    Race()
end

function Overview.Show(on)
    if on then Overview.Refresh() end
end

function Overview.Title()
    return Guild().Info().name or ""
end

-- The guild's chat, kept since login (the last 100 lines) for the panel.
local function Heard(text, name, ...)
    text, name = Core.Plain(text), Core.Plain(name)
    if type(text) ~= "string" or type(name) ~= "string" then return end
    local guid = Core.Plain(select(10, ...))
    local _, class = Core.Ask(GetPlayerInfoByGUID, guid)
    chat[#chat + 1] = { name = Core.PlayerKeyOf(name) or name, class = class, text = text, time = Core.Ask(date, "%H:%M") }
    if #chat > CHAT_MOST then table.remove(chat, 1) end
    if view and view:IsVisible() then Chat() end
end
ns.On("CHAT_MSG_GUILD", function(...) ns.Safe("guild chat", Heard, ...) end)
