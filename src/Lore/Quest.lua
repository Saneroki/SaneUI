local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Quest
--  Under the words, as wide as they are, on its own soft shade: the quest the
--  NPC talks about (Saneroki, 2026-10-28). Its title in the game's gold, then:
--    - offered: its objectives, the group it is for;
--    - in progress: what it asks for (items with how many, money);
--    - offered and handed in: its rewards, the ones to choose from first, then
--      what you get besides, then experience, money, honor and a title in one
--      line.
--  A reward's line says what it is without its tooltip (Rewards.lua): its icon
--  with the count, its name in its quality's colour; under the name what it is
--  (Leather · Chest), "Can't use" in red where you cannot; at the right what a
--  vendor pays for all of it, and under that what it changes against what you
--  wear: its item level and the one worn, the stats that go up (green) and down
--  (red), or that the slot is empty. The tooltip is there too, with the game's
--  comparison, in sight over the faded interface and without any key held
--  (Quiet.Tips). A click on a
--  reward to choose chooses it (its shade darker, a gold line at its left); a
--  double click hands the quest in with it; the right button on it does nothing.
--  Anywhere else here a click is the talk's, as on the words (Talk.Click).
--
--      Quest.Draw(talk)   the talk's quest under the box, or nothing for a talk without one
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Quest = {}
ns.Quest = Quest

Quest.PAD = 14
Quest.ICON = 32
Quest.ROW = 42    -- a reward's line, high
Quest.SPACE = 3   -- between two lines
Quest.HEAD = 10   -- above a heading

local frame, shade, title
local heads, texts, rows = {}, {}, {}
local used -- how many of each are drawn this time
local y    -- where the next part goes, from the top

local GREEN = { 0.1, 1, 0.1 }
local RED = { 1, 0.13, 0.13 }

local function Colour(name, fallback)
    local colour = rawget(_G, name)
    if type(colour) == "table" and colour.GetRGB then return { colour:GetRGB() } end
    return fallback
end

local Coins, Number = ns.Look.Coins, ns.Look.Number

-------------------------------------------------------------------------------
--  Parts, made when first needed and reused
-------------------------------------------------------------------------------
local function Head(words)
    used.heads = used.heads + 1
    local head = heads[used.heads]
    if not head then
        head = ns.Look.Text(frame, "head")
        head:SetTextColor(1, 0.82, 0)
        heads[used.heads] = head
    end
    y = y - Quest.HEAD
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, y)
    head:SetText(words)
    head:Show()
    y = y - (Core.Plain(head:GetStringHeight()) or 12) - 4
end

local function Words(words, colour)
    used.texts = used.texts + 1
    local text = texts[used.texts]
    if not text then
        text = ns.Look.Text(frame, "reward")
        text:SetWidth(ns.Box.WIDTH - Quest.PAD * 2)
        text:SetSpacing(2)
        texts[used.texts] = text
    end
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, y)
    text:SetText(words)
    text:SetTextColor(unpack(colour or { 1, 1, 1 }))
    text:Show()
    y = y - (Core.Plain(text:GetStringHeight()) or 12) - 4
end

-- What it changes against what you wear, in one line of colours.
local function Change(entry)
    if entry.cantUse then return "" end
    if entry.empty then return "|cff19ff19" .. ns.TEXT.emptySlot .. "|r" end
    local parts = {}
    if entry.level then
        local level = ("%s %d"):format(ns.TEXT.itemLevel, entry.level)
        if entry.worn and entry.worn ~= entry.level then
            local up = entry.level > entry.worn
            level = level .. (up and " |cff19ff19(+%d)|r" or " |cffff2020(%d)|r"):format(entry.level - entry.worn)
        end
        parts[#parts + 1] = level
    end
    for index, stat in ipairs(entry.changes or {}) do
        if index > ns.Rewards.STATS then break end
        local amount = stat.amount == math.floor(stat.amount) and ("%d"):format(stat.amount) or ("%.1f"):format(stat.amount)
        if stat.amount > 0 then amount = "+" .. amount end
        parts[#parts + 1] = (stat.amount > 0 and "|cff19ff19%s %s|r" or "|cffff2020%s %s|r"):format(amount, stat.name)
    end
    return table.concat(parts, "  ")
end

local function Enter(row)
    local entry = row.entry
    if not entry then return end
    ns.Quiet.Tips(true)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if entry.spell then
        GameTooltip:SetSpellByID(entry.spell)
    elseif entry.currency then
        GameTooltip:SetQuestCurrency(entry.kind, entry.index)
    else
        GameTooltip:SetQuestItem(entry.kind, entry.index)
        local compare = rawget(_G, "GameTooltip_ShowCompareItem")
        if compare then compare(GameTooltip) end
    end
    GameTooltip:Show()
end

local function Leave()
    GameTooltip:Hide()
    ns.Quiet.Tips(false)
end

local function Row()
    used.rows = used.rows + 1
    local row = rows[used.rows]
    if row then return row end
    row = CreateFrame("Button", nil, frame)
    row:SetSize(ns.Box.WIDTH - Quest.PAD * 2, Quest.ROW)
    row.shade = ns.Look.Shade(row)
    row.mark = row:CreateTexture(nil, "ARTWORK")
    row.mark:SetPoint("TOPLEFT", row, "TOPLEFT", -6, 0)
    row.mark:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", -6, 0)
    row.mark:SetWidth(3)
    row.mark:SetColorTexture(1, 0.82, 0, 0.9)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(Quest.ICON, Quest.ICON)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.count = ns.Look.Text(row, "detail")
    row.count:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 1, 0)
    row.count:SetJustifyH("RIGHT")
    row.name = ns.Look.Text(row, "reward")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)
    row.name:SetWordWrap(false)
    row.what = ns.Look.Text(row, "detail")
    row.what:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 0)
    row.what:SetWordWrap(false)
    row.value = ns.Look.Text(row, "detail")
    row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -4)
    row.value:SetJustifyH("RIGHT")
    row.change = ns.Look.Text(row, "detail")
    row.change:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 5)
    row.change:SetJustifyH("RIGHT")
    row.change:SetWordWrap(false)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", ns.Guard(function(self, button) ns.Talk.Click(button, self.entry) end))
    row:SetScript("OnDoubleClick", ns.Guard(function(self, button)
        if button == "LeftButton" and self.entry and self.entry.kind == "choice" then
            ns.Talk.Choose(self.entry.index, true)
        end
    end))
    row:SetScript("OnEnter", ns.Guard(Enter))
    row:SetScript("OnLeave", ns.Guard(Leave))
    rows[used.rows] = row
    return row
end

local function Reward(entry, chosen)
    local row = Row()
    row.entry = entry
    row.icon:SetTexture(entry.icon)
    row.icon:SetVertexColor(1, entry.cantUse and 0.35 or 1, entry.cantUse and 0.35 or 1)
    row.count:SetText((entry.count or 1) > 1 and Number(entry.count) or "")
    row.name:SetText(entry.name or "")
    local qualities = (C_Item and C_Item.GetItemQualityColor) or rawget(_G, "GetItemQualityColor")
    local r, g, b = Core.Ask(qualities, entry.quality or 1)
    row.name:SetTextColor(r or 1, g or 1, b or 1)
    local what = entry.what or ""
    if entry.cantUse then
        what = (what ~= "" and what .. "  " or "") .. "|cffff2020" .. ns.TEXT.cantUse .. "|r"
    end
    row.what:SetText(what)
    row.what:SetTextColor(unpack(ns.Look.GREY))
    row.value:SetText(entry.value and (entry.value > 0 and Coins(entry.value) or ns.TEXT.noValue) or "")
    row.value:SetTextColor(unpack(ns.Look.GREY))
    row.change:SetText(Change(entry))
    local width = row:GetWidth() - Quest.ICON - 24
    row.name:SetWidth(math.max(60, width - (Core.Plain(row.value:GetStringWidth()) or 0) - 12))
    row.what:SetWidth(math.max(60, width - (Core.Plain(row.change:GetStringWidth()) or 0) - 12))
    row.mark:SetShown(chosen == true)
    row.shade:SetStrength(chosen and 2.5 or 1)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, y)
    row:Show()
    y = y - Quest.ROW - Quest.SPACE
end

-------------------------------------------------------------------------------
--  The quest
-------------------------------------------------------------------------------
local function Build()
    frame = CreateFrame("Button", nil, ns.Look.Root())
    frame:SetWidth(ns.Box.WIDTH)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetScript("OnClick", ns.Guard(function(_, button) ns.Talk.Click(button) end))
    shade = ns.Look.Shade(frame)
    title = ns.Look.Text(frame, "name")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, -Quest.PAD)
    title:SetWidth(ns.Box.WIDTH - Quest.PAD * 2)
    local gold = Colour("NORMAL_FONT_COLOR", { 1, 0.82, 0 })
    title:SetTextColor(unpack(gold))
end

local function Summary(rewards)
    local parts = {}
    if rewards.xp > 0 then parts[#parts + 1] = ns.TEXT.experience:format(Number(rewards.xp)) end
    if rewards.money > 0 then parts[#parts + 1] = Coins(rewards.money) end
    if rewards.honor > 0 then parts[#parts + 1] = ns.TEXT.honor:format(rewards.honor) end
    if type(rewards.title) == "string" and rewards.title ~= "" then parts[#parts + 1] = ns.TEXT.title:format(rewards.title) end
    if #parts > 0 then Words(table.concat(parts, "     ")) end
end

local function Rewards(talk)
    local rewards = talk.quest.rewards
    if not rewards then return end
    local others = #rewards.items + #rewards.currencies + #rewards.spells
    local any = #rewards.choices + others > 0 or rewards.xp > 0 or rewards.money > 0 or rewards.honor > 0
        or (type(rewards.title) == "string" and rewards.title ~= "")
    if not any then return end
    Head(ns.TEXT.rewards)
    if #rewards.choices > 0 then
        if #rewards.choices > 1 then Words(ns.TEXT.chooseOne, ns.Look.GREY) end
        for _, entry in ipairs(rewards.choices) do Reward(entry, talk.choice == entry.index) end
    end
    if others > 0 then
        Words(#rewards.choices > 0 and ns.TEXT.youGet or ns.TEXT.youGetOnly, ns.Look.GREY)
        for _, entry in ipairs(rewards.items) do Reward(entry) end
        for _, entry in ipairs(rewards.currencies) do Reward(entry) end
        for _, entry in ipairs(rewards.spells) do Reward(entry) end
    end
    Summary(rewards)
end

function Quest.Draw(talk)
    if not frame then Build() end
    if not talk.quest then
        frame:Hide()
        ns.Box.Place(nil)
        return
    end
    used = { heads = 0, texts = 0, rows = 0 }
    local quest = talk.quest
    title:SetText(talk.title or "")
    y = -Quest.PAD - (Core.Plain(title:GetStringHeight()) or 18)
    if quest.objectives and quest.objectives ~= "" then
        Head(ns.TEXT.objectives)
        Words(quest.objectives)
    end
    if quest.group and quest.group > 0 then Words(ns.TEXT.group:format(quest.group), ns.Look.GREY) end
    local required = quest.required
    if required and (#required.items > 0 or required.money > 0) then
        Head(ns.TEXT.asks)
        for _, entry in ipairs(required.items) do Reward(entry) end
        if required.money > 0 then Words(Coins(required.money)) end
    end
    Rewards(talk)
    for index = used.heads + 1, #heads do heads[index]:Hide() end
    for index = used.texts + 1, #texts do texts[index]:Hide() end
    for index = used.rows + 1, #rows do rows[index]:Hide() end
    frame:SetHeight(-y + Quest.PAD)
    shade:SetStrength(1)
    frame:Show()
    ns.Box.Place(frame)
end
